extends RefCounted
## Only decisions live here. All population, equipment and technology changes
## must be accepted and paid for by the ordinary commands and simulation.
const STRATEGY=preload("res://scripts/civilization_strategy.gd")
const GREAT_WORKS=preload("res://scripts/great_works_rivalry.gd")
const UNDERTAKINGS=preload("res://scripts/undertaking_system.gd")

static func current_plan(id:String)->Dictionary:
	var state:=WorldSimulation.state
	var situation:={"food_days":float(state.simulation_metrics.get("food_days",30)),"food_intake_ratio":float(state.simulation_metrics.get("food_intake_ratio",1)),"at_war":false}
	for metric:String in ["food_consumption","army_provisions_required","army_provision_delivery_ratio"]:
		if state.simulation_metrics.has(metric):situation[metric]=state.simulation_metrics[metric]
	for civ:Dictionary in WorldSimulation.world.civilizations:
		situation.at_war=bool(situation.at_war) or bool(civ.player_relation.get("at_war",false))
	# The same sovereign personality supplies the foreign leader's dialogue.
	situation["integration_pressure"]=float(preload("res://scripts/society_exchange.gd").pressure().unsettled_share)
	var exchange_value:=0.0
	for ties:Dictionary in state.society_exchange.connections.values():exchange_value=maxf(exchange_value,float(ties.get("respect",0)))
	situation["cultural_exchange"]=exchange_value
	situation["reception_capacity"]=preload("res://scripts/society_exchange.gd").reception_capacity()
	var plan:=STRATEGY.preferences(STRATEGY.PERSONALITY.foreign(state.world_seed,id),situation)
	WorldSimulation.direction._ensure_cultural_memory()
	var drive:=preload("res://scripts/cultural_inheritance.gd").weight(WorldSimulation.direction.cultural_memory,"ambition","expansion",int(state.elapsed_days))
	plan.expansion_food=maxf(45,float(plan.expansion_food)*(1.0-drive*.35))
	var choices:=preload("res://scripts/cultural_inheritance.gd").choice_weights(WorldSimulation.direction.cultural_memory,int(state.elapsed_days))
	var total:=0.0
	for weight in choices.values():total+=float(weight)
	if total>0:
		for choice in choices:
			for domain in WorldSimulation.direction.AMBITIONS[choice].domains:plan.research_weights[domain]=float(plan.research_weights.get(domain,1))+float(choices[choice])/total*4.0
		plan.scout_days=90 if drive>=.35 else plan.scout_days
	return plan

static func review_due(id:String,day:int)->bool:
	# Same monthly decision frequency, distributed across the calendar so all
	# twelve rulers do not cause a single synchronized computation spike.
	return posmod(day,30)==posmod(hash(id+":strategy_review"),30)

static func research_orders(id:String,plan:Dictionary)->void:
	var budget:=0
	for value in WorldSimulation.state.research_allocations.values():budget+=int(value)
	var priorities:Dictionary=plan.research_weights.duplicate()
	var viable:Dictionary={}
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if WorldSimulation.discovery._discovery_is_eligible(entry,int(WorldSimulation.state.elapsed_days)):viable[String(entry.dynamic)]=true
	# This ruler chooses its own emphasis through ordinary orders. Do not spend
	# every point on blocked fields while their cross-field foundations await work.
	# Player emphasis remains authoritative and is never changed by this controller.
	if not viable.is_empty():
		for domain:String in STRATEGY.DOMAINS:
			if not viable.has(domain):priorities[domain]=0.0
	var support:Dictionary=preload("res://scripts/research_supply_planner.gd").recommendation() if budget>0 else {}
	if support.is_empty() and budget>0:
		support=preload("res://scripts/research_foundations.gd").recommendation()
	var weights:=STRATEGY.research_plan(priorities,budget)
	if not support.is_empty() and int(weights.get(support.domain,0))==0:
		var donor:=""
		for domain:String in weights:
			if int(weights[domain])>int(weights.get(donor,0)):donor=domain
		if donor!="":weights[donor]=int(weights[donor])-1;weights[support.domain]=1
	for domain:String in weights:
		if int(WorldSimulation.state.research_allocations.get(domain,0))!=int(weights[domain]):
			WorldSimulation.submit(id,{"kind":"research_emphasis","domain":domain,"weight":weights[domain],"reason":String(plan.goals[0].title)})

	if not support.is_empty():WorldSimulation.submit(id,{"kind":"research_target","id":support.id,"reason":String(support.get("reason","Investigate foundations for working "+String(support.get("resource","local materials"))))})

static func choose_orders(id:String)->void:
	preload("res://scripts/day_job.gd").run_parts(order_steps(id))

## The daily decision as ordered [label, callable] parts; later parts run only
## when the first finds a plan review due. Nothing else runs between parts.
static func order_steps(id:String)->Array:
	var shared:Dictionary={}
	var review:Array=[]
	var first:=[["controller",func()->Variant:
		if String(WorldSimulation.actors[id].controller)!="ai":return null
		var day:=int(WorldSimulation.state.elapsed_days)
		if WorldSimulation.direction.needs_century_choice():
			var century_plan:=current_plan(id)
			WorldSimulation.submit(id,{"kind":"ambition","id":century_plan.ambition})
			research_orders(id,century_plan)
		if not WorldSimulation.state.settlement_site_committed:
			if WorldSimulation.state.convoy_traveling:return null
			var founded:=WorldSimulation.submit(id,{"kind":"found"})
			if founded.has("error"):
				var home:=WorldSimulation.world.player_world_origin
				for distance:float in [2,5,10,20,40]:
					for spoke in 12:
						var destination:=home+Vector2.from_angle(TAU*float(spoke)/12)*distance
						if not WorldSimulation.world._position_is_revealed(destination):continue
						var known:=preload("res://scripts/civilization_day.gd").context(destination)
						if not bool(WorldSimulation.resources.water_access_snapshot(known).accessible):continue
						if not WorldSimulation.submit(id,{"kind":"move","destination":destination}).has("error"):return null
			return null
		preload("res://scripts/ai_workshop_turnover.gd").advance(id,WorldSimulation.military)
		if not review_due(id,day):return null
		shared.plan=current_plan(id)
		return review
	]]
	var parts:Array=review
	for kind:String in ["research","military","civilian","foreign","great_works","expansion"]:
		if kind in ["civilian","expansion"]:
			var kind_parts:=civilian_order_steps(id,func()->Dictionary:return shared.plan) if kind=="civilian" else expansion_order_steps(id,func()->Dictionary:return shared.plan)
			for part:Array in kind_parts:
				parts.append(["controller_"+String(part[0]),func()->Variant:
					return (part[1] as Callable).call() if shared.has("plan") else null
				])
			continue
		parts.append(["controller_"+kind,func()->void:
			if not shared.has("plan"):return
			match kind:
				"research":research_orders(id,shared.plan)
				"military":military_orders(id,shared.plan)
				"foreign":foreign_orders(id,shared.plan)
				"great_works":great_work_orders(id,shared.plan)
		])
	return first

static func expansion_orders(id:String,plan:Dictionary)->void:
	preload("res://scripts/day_job.gd").run_parts(expansion_order_steps(id,func()->Dictionary:return plan))

## expansion_orders as ordered parts: eligibility, one part per candidate site,
## then the founding order for the best site found.
static func expansion_order_steps(id:String,plan_source:Callable)->Array:
	var shared:Dictionary={"best":{},"best_value":-INF,"quote_cache":{}}
	var sites:Array=[]
	var parts:Array=[["expansion_review",func()->Variant:
		var plan:Dictionary=plan_source.call()
		shared.plan=plan
		shared.eligible=false
		if bool(plan.hungry) or bool(plan.at_war) or float(WorldSimulation.state.simulation_metrics.get("food_days",0))<float(plan.expansion_food):return null
		if bool(WorldSimulation.state.settlement_convoy.get("active",false)):return null
		if "Hearth Circle" not in WorldSimulation.state.settlement_completed:return null
		shared.eligible=true
		# Evaluate candidates only inside returned knowledge. Duration, founders,
		# supplies, and land/water checks belong to the same founding transaction.
		shared.points=expansion_candidates(WorldSimulation.world.player_world_origin,float(plan.settle_distance))
		return sites
	]]
	for index in 48:
		sites.append(["expansion_site",func()->void:
			if not bool(shared.get("eligible",false)) or index>=(shared.points as Array).size():return
			var point:Vector2=shared.points[index]
			if not bool(WorldSimulation.settlements.known_land_assessment(point).known):return
			var quote:=WorldSimulation.settlements.settlement_convoy_quote(point,0,shared.quote_cache)
			if not bool(quote.get("ok",false)):return
			var context:=preload("res://scripts/civilization_day.gd").context(point)
			if not bool(WorldSimulation.resources.water_access_snapshot(context).accessible):return
			var value:=expansion_site_value(context,shared.plan)
			if value>float(shared.best_value):shared.best={"kind":"settle","destination":point};shared.best_value=value
		])
	sites.append(["expansion_order",func()->void:
		if bool(shared.get("eligible",false)) and not (shared.best as Dictionary).is_empty():WorldSimulation.submit(id,shared.best)
	])
	return parts

static func expansion_candidates(home:Vector2,distance:float)->Array[Vector2]:
	var points:Array[Vector2]=[]
	# A single ring can miss known resources closer to home and eventually fill
	# all of its sites. Keep the search bounded while considering nearby options.
	for scale:float in [.5,1.0,1.5]:
		for index in 16:points.append(home+Vector2.from_angle(TAU*float(index)/16.0)*distance*scale)
	return points

static func expansion_site_value(context:Dictionary,plan:Dictionary)->float:
	var environment:Dictionary=context.environment_profile
	var p:Dictionary=plan.personality
	var value:=float(environment.get("food_potential",0))*(.6+float(p.empathy))
	value+=float(environment.get("water_access",0))*(.4+float(p.openness))
	# Use measured local cover, not the nonexistent profile "forest" key.
	# A material-starved capital has a reason to found a supplying settlement;
	# ordinary convoy costs, known routes and finite city trade still apply.
	var fields:Dictionary=context.get("surface_material_catchments",{}).duplicate()
	if context.has("woodland_catchment"):fields["Timber"]=context.woodland_catchment
	else:fields["Timber"]={"density":environment.get("woodland",0)}
	var target:=maxf(6.0,WorldSimulation.state.population_exact*.06)
	for material:String in ["Timber","Stone","Fiber Plants","Clay"]:
		var density:=float(fields.get(material,{}).get("density",0))
		if density<(.03 if material=="Stone" else .08):density=0.0
		var shortage:=clampf(1.0-float(WorldSimulation.state.resource_stockpiles.get(material,0))/target,0.0,1.0)
		value+=density*((.2+float(p.discipline)) if material=="Timber" else .1)
		value+=density*shortage*3.0
	return value

## Transport exclusion is hunger, but does not mean home stores cannot feed
## craftspeople. Keep making the carts and goods needed to recover delivery.
## Legacy/minimal plans without this distinction retain the conservative guard.
static func production_food_blocked(plan:Dictionary)->bool:
	return bool(plan.get("food_shortage",plan.get("hungry",false)))

static func civilian_arrival_review_due(id:String,day:int)->bool:
	# Plant and infrastructure investment is reviewed monthly against that day's
	# delivered inputs. There are no civilian lines waiting to start daily:
	# civilian manufactures are Civilian Goods made by households.
	return review_due(id,day)

static func civilian_orders(id:String,plan:Dictionary)->void:
	preload("res://scripts/day_job.gd").run_parts(civilian_order_steps(id,func()->Dictionary:return plan))

## civilian_orders as ordered parts: the plan check, each investment planner,
## then the resulting order. `plan_source` is evaluated in the first part.
static func civilian_order_steps(id:String,plan_source:Callable)->Array:
	var shared:Dictionary={}
	var planners:=preload("res://scripts/civilian_investment_planner.gd").recommendation_steps(shared)
	var follow:Array=planners.duplicate()
	follow.append(["civilian_order",func()->void:
		var recommendation:Dictionary=shared.recommendation
		if String(recommendation.get("kind",""))=="plant_install":
			WorldSimulation.submit(id,recommendation);return
		production_order(id,recommendation)
	])
	return [["civilian_review",func()->Variant:
		var plan:Dictionary=plan_source.call()
		return null if production_food_blocked(plan) or bool(plan.get("at_war",false)) else follow
	]]

static func production_order(id:String,recommendation:Dictionary)->void:
	if recommendation.is_empty():return
	var campaign:=WorldSimulation.military
	var item:=String(recommendation.item)
	var exists:=false;var managed:=true
	for job:Dictionary in campaign.equipment_queue:
		if String(job.get("item",""))==item:
			exists=true;managed=bool(job.get("planner_managed",false));break
	if not exists and (campaign.equipment_queue.size()>=campaign.production_line_capacity() or not campaign.PersistentProduction.startup_blockers(campaign,item,{}).is_empty()):
		var reusable:=finished_ai_line(id,campaign)
		if reusable<0:
			preload("res://scripts/ai_workshop_turnover.gd").request(id,campaign,item,int(recommendation.target))
			return
		if WorldSimulation.submit(id,{"kind":"production_retool","job":reusable,"item":item}).has("error"):return
	ensure_line(id,item,int(recommendation.target))
	if managed:
		for job:Dictionary in campaign.equipment_queue:
			if String(job.get("item",""))==item and preload("res://scripts/armor_equipment.gd").KITS.has(item) and bool(job.get("persistent",false)):
				job.planner_managed=true;break

static func finished_ai_line(id:String,campaign:Node)->int:
	if String(WorldSimulation.actors.get(id,{}).get("controller",""))!="ai":return -1
	for job:Dictionary in campaign.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):continue
		if float(job.get("progress_days",0))>0 or not (job.get("reserved_materials",{}) as Dictionary).is_empty():continue
		var pending:=false
		for key:String in job:
			if key.ends_with("pending") or key.ends_with("trial") or key=="formed_piece":pending=true
		if pending:continue
		if campaign.PersistentProduction.state(campaign,job)=="Target met":return int(job.id)
	return -1

static func military_orders(id:String,plan:Dictionary={})->void:
	if plan.is_empty():plan=current_plan(id)
	var campaign:=WorldSimulation.military
	if not production_food_blocked(plan):
		production_order(id,preload("res://scripts/cart_supply_planner.gd").recommendation())
	var policy:=String(plan.training)
	for service in ["army","navy","air"]:WorldSimulation.submit(id,{"kind":"training_policy","service":service,"policy":policy})
	for demand:Dictionary in campaign.workshop.army_demands():production_order(id,demand)
	var capacity:=campaign.recruitment_capacity()
	var target:=mini(roundi(float(capacity)*float(plan.capacity_share)),roundi(WorldSimulation.state.population_exact*float(plan.recruit_share)))
	if bool(plan.hungry) and not bool(plan.at_war):target=campaign._mobilized_count()
	var chosen:="";var weapon:="";var score:=-1.0
	for unit:String in campaign.UnitCatalog.ARCHETYPES:
		var definition:Dictionary=campaign.UnitCatalog.ARCHETYPES[unit]
		var item:=preload("res://scripts/armor_equipment.gd").selection(campaign,unit,plan)
		if item.is_empty():continue
		var value:=STRATEGY.unit_score(definition,plan)
		if value>score:chosen=unit;weapon=item;score=value
	var intake:=preload("res://scripts/military_intake_supply.gd").places(campaign,chosen,weapon)
	var vacancies:=mini(maxi(0,target-campaign._mobilized_count()),maxi(0,intake-campaign.aggregate_recruits))
	if String(plan.training)!="suspended" and vacancies>0:WorldSimulation.submit(id,{"kind":"recruit","count":vacancies})
	land_training_orders(id,chosen,weapon,target,plan)
	# Release an inherited waiting backlog; keep only one feasible intake in reserve.
	# This count cannot stand down a serving formation.
	var surplus:=maxi(0,campaign.aggregate_recruits-intake)
	if surplus>0:WorldSimulation.submit(id,{"kind":"demobilize","count":surplus})
	if campaign.field_armies.is_empty() and int(campaign.home_army.get("troops",0))>=4:
		WorldSimulation.submit(id,{"kind":"deploy","count":maxi(4,roundi(float(campaign.home_army.troops)*float(plan.deploy_share)))})
	var reinforcement:=preload("res://scripts/home_army_reinforcement.gd").recommendation(campaign)
	if not reinforcement.is_empty():WorldSimulation.submit(id,reinforcement)
	campaign.command_hierarchy.sync()
	if campaign.command_hierarchy.data.zones.is_empty() and not campaign.field_armies.is_empty():
		var zone:=WorldSimulation.submit(id,{"kind":"area","service":"army","name":"Home defense","vertices":campaign.command_hierarchy.R.rectangle(WorldSimulation.world.player_world_origin,8.0)})
		if zone.has("region"):WorldSimulation.submit(id,{"kind":"objective","command":"army","region":zone.region,"mission":"defend","vision":"Protect the settlement and its approaches."})
	for service in ["navy","air"]:
		if WorldSimulation.state.player_settlements.is_empty():continue
		var city:=String(WorldSimulation.state.player_settlements[0].id)
		if not campaign.joint_operations.available_base(service):WorldSimulation.submit(id,{"kind":"base","city":city,"service":service})
		for base:Dictionary in campaign.joint_operations.state.bases:
			if base.domain!=service or not campaign.joint_operations.base_ready(base):continue
			var candidate:="";var work:=-1.0;var manufacturing:Dictionary={}
			var desired:=STRATEGY.preferred_mission(service,campaign.joint_operations.MISSIONS[service].keys(),plan)
			for unit:String in campaign.joint_operations.C.UNITS:
				var definition:Dictionary=campaign.joint_operations.C.UNITS[unit]
				if definition.domain!=service or not bool(campaign._knowledge_gate(String(definition.gate),.10).unlocked):continue
				if int(definition.crew)>maxi(0,capacity-campaign._mobilized_count()):continue
				var equipment:=String(definition.equipment)
				var supply:=preload("res://scripts/joint_manufacturing_planner.gd").plan(campaign,equipment)
				if supply.is_empty():continue
				var fit:=log(1+float(definition.work_days))*.25+(3.0 if String(definition.mission)==desired else 0.0)
				if fit>work:candidate=unit;work=fit;manufacturing=supply
			if candidate=="":continue
			if not bool(manufacturing.ready):
				production_order(id,manufacturing.upstream);continue
			var equipment:=String(campaign.joint_operations.C.UNITS[candidate].equipment)
			production_order(id,{"item":equipment,"target":1})
			WorldSimulation.submit(id,{"kind":"commission","base":int(base.id),"unit":candidate,"count":1})
	service_orders(id,plan)

static func land_training_orders(id:String,chosen:String,weapon:String,target:int,plan:Dictionary)->void:
	if chosen.is_empty():return
	var campaign=WorldSimulation.military
	var count:=int(campaign.aggregate_recruits)
	var equipment_target:=maxi(4,target)
	production_order(id,preload("res://scripts/armor_equipment.gd").investment(campaign,chosen,weapon,equipment_target,plan))
	var support:=preload("res://scripts/combined_arms_recruitment.gd").recommendation(chosen,plan,func(item:String)->bool:return can_supply_equipment(campaign,item))
	if not support.is_empty():
		chosen=String(support.unit);weapon=String(support.weapon);count=int(support.count);equipment_target=maxi(4,count)
	production_order(id,{"item":weapon,"target":equipment_target})
	count=mini(count,preload("res://scripts/military_intake_supply.gd").places(campaign,chosen,weapon))
	if String(plan.get("training",""))=="suspended":return
	if count>0:WorldSimulation.submit(id,{"kind":"train","unit":chosen,"weapon":weapon,"count":count})

static func can_supply_equipment(campaign:Node,item:String)->bool:
	if int(campaign.military_inventory.get(item,0))>0:return true
	# The persistent-line adapter includes land, naval and air recipes and the
	# same material, workforce and operational-base checks as the player UI.
	return campaign.PersistentProduction.startup_blockers(campaign,item).is_empty()

static func ensure_line(id:String,item:String,target:int)->void:
	for job in WorldSimulation.military.equipment_queue:
		if String(job.get("item",""))==item:
			if job.has("ai_turnover"):return
			if bool(job.get("persistent",false)) and int(job.get("target_stock",0))!=target:
				WorldSimulation.submit(id,{"kind":"production_target","job":int(job.id),"target":target,"paused":bool(job.get("paused",false))})
			return
	WorldSimulation.submit(id,{"kind":"production","item":item,"target":target})

static func license_acquisition_orders(id:String,plan:Dictionary)->bool:
	var order:=preload("res://scripts/license_acquisition_planner.gd").recommendation(plan)
	return not order.is_empty() and not WorldSimulation.submit(id,order).has("error")

static func research_acquisition_orders(id:String,plan:Dictionary)->bool:
	var order:=preload("res://scripts/research_acquisition_planner.gd").recommendation(plan)
	return not order.is_empty() and not WorldSimulation.submit(id,order).has("error")

static func foreign_orders(id:String,plan:Dictionary={})->void:
	if plan.is_empty():plan=current_plan(id)
	var world:=WorldSimulation.world
	var food_days:=float(WorldSimulation.state.simulation_metrics.get("food_days",0))
	var scout_share:=.02 if int(plan.scout_days)==30 else .05 if int(plan.scout_days)==90 else .08
	var reception:=preload("res://scripts/society_exchange.gd").reception_capacity()
	var strain:=float(preload("res://scripts/society_exchange.gd").pressure().unsettled_share)
	var migration:="consolidate" if bool(plan.hungry) or strain>.15 else "welcome" if float(plan.personality.empathy)>.65 else "balanced"
	var sharing:="open" if float(plan.personality.openness)>.65 else "guarded" if float(plan.personality.assertiveness)>.7 and float(plan.personality.openness)<.4 else "selective"
	WorldSimulation.submit(id,{"kind":"society_policy","migration":migration,"sharing":sharing})
	if bool(plan.hungry) or strain>.2:scout_share=0
	var scout_focus:="recruitment" if reception>=2 and float(plan.personality.empathy)>.65 else "exploration"
	WorldSimulation.submit(id,{"kind":"scouting_policy","share":scout_share,"focus":scout_focus})
	if not world.diplomatic_mission.is_empty():return
	if license_acquisition_orders(id,plan):return
	if research_acquisition_orders(id,plan):return
	var candidates:Array[Dictionary]=[]
	var campaign_enemy:="";var campaign_urgency:=-INF
	for civ:Dictionary in world.civilizations:
		if int(civ.player_relation.get("contact_level",0))<2:continue
		var relationship:Dictionary=civ.player_relation.duplicate(true)
		relationship.opinion=clampf(float(relationship.get("opinion",0))+preload("res://scripts/society_exchange.gd").diplomatic_value(String(civ.id),plan.personality),-1,1)
		var other:=GREAT_WORKS.global_owner(String(civ.id),id)
		# Lasting grievances over seized, looted or sabotaged works; known deterrence.
		relationship.opinion=clampf(float(relationship.opinion)-GREAT_WORKS.grievance(id,other),-1,1)
		var action:=STRATEGY.diplomatic_action(relationship,plan,food_days,GREAT_WORKS.known_deterrence(id,other))
		if bool(civ.player_relation.get("at_war",false)) and action!="seek_peace":
			var urgency:=-float(civ.player_relation.get("opinion",0))
			if urgency>campaign_urgency:campaign_urgency=urgency;campaign_enemy=String(civ.id)
		if action=="":continue
		var opinion:=float(civ.player_relation.get("opinion",0))
		var score:=3.0 if action=="seek_peace" else (2.0-opinion if action=="declare_war" else 1.0+opinion)
		candidates.append({"order":{"kind":"diplomacy","target":String(civ.id),"action":action},"score":score})
	if campaign_enemy!="":campaign_objective(id,campaign_enemy,plan)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.score)>float(b.score))
	for candidate in candidates:
		if not WorldSimulation.submit(id,candidate.order).has("error"):break

static func campaign_objective(id:String,enemy:String,plan:Dictionary)->void:
	var campaign:=WorldSimulation.military
	var world:=WorldSimulation.world
	var target:="";var point:Vector2=world.player_world_origin
	var mission:="defend";var vision:="Hold the home approaches. Preserve our people and avoid an unsupported advance."
	if bool(plan.offensive):
		var best:=-INF
		# Dated known city reports only: no omniscient target lookup.
		for report:Dictionary in world.city_intelligence.known_cities("player",enemy,false):
			var position:=world.city_intelligence.vector(report.position)
			var score:=-position.distance_to(world.player_world_origin)
			# A reported standing Great Work is a prize to bold rulers (a few km of reach).
			for sighting:Dictionary in report.get("works",[]):
				if String(sighting.get("status",""))=="functioning":score+=12.0*float(plan.personality.assertiveness)
			if score>best:best=score;target=String(report.city_id);point=position
		if target!="":
			mission="occupy" if float(plan.personality.assertiveness)>.6 else "encircle"
			vision="Isolate the enemy and cut its supply before advancing. Protect civilians and preserve the army." if float(plan.personality.empathy)>.5 else "Seize the initiative, isolate opposing forces, and take the objective when supply permits."
	var current:Dictionary=campaign.command_hierarchy.order_for("army")
	if String(current.get("target",""))==target and String(current.get("mission",""))==mission:return
	var region:=WorldSimulation.submit(id,{"kind":"area","service":"army","name":"Homeland defense" if target=="" else "Campaign objective","vertices":campaign.command_hierarchy.R.rectangle(point,8)})
	if region.has("region"):WorldSimulation.submit(id,{"kind":"objective","command":"army","region":region.region,"mission":mission,"target":target,"vision":vision})

static func service_orders(id:String,plan:Dictionary={})->void:
	if plan.is_empty():plan=current_plan(id)
	var op=WorldSimulation.military.joint_operations
	for force:Dictionary in op.state.forces:
		if force.owner!="player":continue
		var base:Dictionary=op.base(int(force.base_id))
		if base.is_empty():continue
		var at:Vector2=op.point(base)
		var missions:Array=op.missions_for(force)
		var mission:=STRATEGY.preferred_mission(String(force.domain),missions,plan)
		if not force.region.is_empty():
			if String(force.mission)!=mission:WorldSimulation.submit(id,{"kind":"service_mission","force":int(force.id),"region":force.region,"mission":mission})
			continue
		if mission=="hold":continue
		for spoke in 8:
			var center:=at+Vector2.from_angle(TAU*spoke/8.0)*20
			if force.domain=="navy" and op.geography.is_land(center):continue
			var created:Dictionary=op.create_region(String(force.domain),op.R.rectangle(center,20),"Home approaches")
			if created.has("error"):continue
			var response:=WorldSimulation.submit(id,{"kind":"service_mission","force":int(force.id),"region":created.region,"mission":mission})
			if not response.has("error"):break
			op.remove_region(String(created.region.id))

## Monthly Great Works review: pace, race reactions (press, sabotage, abandon),
## restoration, returning loot, and choosing a new work. Every mutation is a
## validated order paid by the ordinary undertaking and rivalry rules.
static func great_work_orders(id:String,plan:Dictionary)->void:
	var state:=WorldSimulation.state
	var food_days:=float(state.simulation_metrics.get("food_days",0))
	var news:=GREAT_WORKS.rival_news_for(id)
	var active:=false
	for city:Dictionary in state.player_settlements:
		if not String(city.get("occupied_by","")).is_empty():continue
		for r:Dictionary in city.get("undertakings",[]):
			var status:=String(r.get("status",""))
			if status=="functioning" and float(r.get("condition",1))<.6:
				WorldSimulation.submit(id,{"kind":"great_work_restore","city":String(city.id),"id":String(r.id)})
			# A lost race: disciplined rulers reclaim the stone, others keep a lesser monument.
			if status=="rival":
				WorldSimulation.submit(id,{"kind":"great_work_quarry" if float(plan.personality.discipline)>.55 or bool(plan.get("hungry",false)) else "great_work_repurpose","city":String(city.id),"id":String(r.id)})
			if status not in ["building","stalled"]:continue
			active=true
			var race:=GREAT_WORKS.race_for(id,String(r.id),GREAT_WORKS.fraction(r),news)
			var ready:=not race.is_empty() and int(state.elapsed_days)>=int(preload("res://scripts/society_exchange.gd").known_relation(String(race.owner)).get("great_work_sabotage_day",-GREAT_WORKS.SABOTAGE_COOLDOWN))+GREAT_WORKS.SABOTAGE_COOLDOWN
			var reaction:=STRATEGY.great_work_reaction(plan,race,GREAT_WORKS.fraction(r),food_days,ready)
			if reaction=="sabotage":
				# The attempt is paid and risky whether or not it succeeds; the work goes on.
				WorldSimulation.submit(id,{"kind":"great_work_sabotage","target":String(race.owner),"city":String(race.local_city_id),"id":String(r.id)})
				reaction="press" if food_days>45 else "careful"
			if reaction=="abandon" or String(r.get("policy",""))!=reaction:
				WorldSimulation.submit(id,{"kind":"great_work_policy","city":String(city.id),"id":String(r.id),"policy":reaction})
			if reaction=="abandon":active=false
	# Merciful rulers give back treasures their armies carried off, once at peace.
	if float(plan.personality.empathy)>.7:
		for owner:String in GREAT_WORKS.owners():
			if owner==id:continue
			for city:Dictionary in GREAT_WORKS.cities(owner):
				for r:Dictionary in city.get("undertakings",[]):
					for entry:Dictionary in r.get("rivalry",{}).get("looted",[]):
						if String(entry.by)==id and not bool(entry.returned):
							WorldSimulation.submit(id,{"kind":"great_work_return_loot","owner":owner,"id":String(r.id)});break
	if active or bool(plan.get("hungry",false)) or bool(plan.get("at_war",false)) or food_days<60:return
	var best:={};var best_value:=-INF
	for city:Dictionary in state.player_settlements:
		if not String(city.get("occupied_by","")).is_empty():continue
		var choices:Array=WorldSimulation.settlements.with_city_resources(String(city.id),func()->Array:
			var found:Array=[]
			for d:Dictionary in UNDERTAKINGS.possibilities(city):
				var coverage:=1.0
				for material:String in d.get("cost",{}):coverage=minf(coverage,float(WorldSimulation.state.resource_stockpiles.get(material,0))/maxf(1,float(d.cost[material])))
				found.append([d,coverage])
			return found)
		for pair:Array in choices:
			var d:Dictionary=pair[0]
			# Real stores must cover a first stage; ambition does not conjure stone.
			if float(pair[1])<.2:continue
			var race:=GREAT_WORKS.race_for(id,String(d.id),0.0,news)
			var value:=STRATEGY.great_work_score(d,plan,{"coverage":pair[1],"claimed":bool(race.get("claimed",false)),"rival_ahead":bool(race.get("rival_ahead",false))})
			if value>best_value:best_value=value;best={"kind":"great_work_start","city":String(city.id),"id":String(d.id)}
	if not best.is_empty():WorldSimulation.submit(id,best)
