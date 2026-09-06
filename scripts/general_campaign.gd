extends Node
## A bounded command campaign. MilitaryCampaign owns player personnel; the
## shared combat resolver owns losses. This node owns missions and commitments.
signal changed
var active:=false
var launch_requested:=false
var difficulty:="medium"
var state:Dictionary={}
var terrain:Node
var screen:Control
var budget:=0.0
var resolving:=false
var pending_step:Dictionary={}
var cells:Dictionary={}
const RATION:=1.12
const STEP:=2.0
const RADIUS:=18
const ACTIONS:=["discuss","attack","defend","withdraw","recover","besiege","approve","override","relieve"]

func reset_for_new_world()->void:
	active=false;state.clear();budget=0;resolving=false;pending_step.clear();cells.clear()
	if is_instance_valid(screen):screen.queue_free()
	screen=null
	if has_node("/root/GeneralDialogue"):GeneralDialogue.reset()

func bind_world(world:Node)->void:
	terrain=world
	if launch_requested:
		launch_requested=false
		start_scenario()
	elif active:
		_build_grid()
		open_screen()

func open_screen()->void:
	if not is_instance_valid(terrain):return
	terrain._set_game_speed(0)
	if is_instance_valid(screen):screen.show();return
	screen=preload("res://scripts/general_campaign_screen.gd").new()
	var layer:=CanvasLayer.new();layer.layer=110;layer.name="GeneralCampaignLayer"
	terrain.add_child(layer);layer.add_child(screen)
	screen.tree_exited.connect(layer.queue_free)

func launch()->void:
	# Preserve the world being left in a separate slot; quicksave is untouched.
	var saved:=SaveSystem.save_game("before_river_war")
	if saved.has("error"):return
	terrain._restart_world(551188)
	launch_requested=true

func start_scenario()->Dictionary:
	active=true
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_name="Alderford"
	GameState.settlement_founded_at=terrain.settler_marker.position
	GameState.settlement_completed=["Hearth Circle"]
	GameState.population_exact=1200;GameState.population_total=1200;GameState.population_cohorts.clear();GameState.initialize_population_model()
	GameState.synchronize_population_allocations()
	SettlementModel.ensure_founded()
	FoodSystem.receive_external_food(24000)
	var formations:Array[Dictionary]=[{"id":1,"unit":"line_infantry","weapon":"spear","count":180,"authorized_count":180,"equipment":180,"training":.65,"experience":.2},{"id":2,"unit":"skirmisher","weapon":"bow","count":60,"authorized_count":60,"equipment":60,"ammunition":360,"training":.6,"experience":.2}]
	MilitaryCampaign.military_inventory["spear"]=180;MilitaryCampaign.military_inventory["bow"]=60
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Alderford reserve",[],.9,.85)
	MilitaryCampaign._assemble_field_army(formations,"Alderford expedition")
	var army:Dictionary=MilitaryCampaign.field_armies[-1]
	army["general_managed"]=true;army["supply_level"]=1.0
	var leader:Dictionary=army.commander
	state={"seed":551188,"army_id":int(army.army_id),"origin":Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z),"cell":Vector2i.ZERO,"general_name":String(leader.name),"figure_id":String(leader.get("figure_id","")),"character":{"care":.8,"ambition":.48,"confidence":.65,"loyalty":.6,"fear":.25,"affection":.55,"competence":float(leader.get("tactics",.6)),"resentment":0.0},"treatment":[],"messages":[],"reports":[],"rivals":[],"mission":{},"proposal":{},"status":"deliberating","food":240.0*8.0*RATION,"initial":240,"losses":0,"turn":0,"battle":{},"battle_initial":[],"war":"The Alderford War","outcome":"","seen":{},"events":[],"exhaustion":0.0,"authority":"Personal oath; removal needs the captains' cooperation."}
	FoodSystem.issue_for_obligation(float(state.food),"military","Alderford carried rations",8,240)
	_build_grid()
	var candidates:Array=cells.keys();candidates.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return a.length_squared()>b.length_squared())
	var chosen:Array[Vector2i]=[]
	for c:Vector2i in candidates:
		if c.length()<9 or c.length()>16:continue
		if not chosen.is_empty() and c.distance_to(chosen[0])<12:continue
		if route(Vector2i.ZERO,c).is_empty():continue
		chosen.append(c)
		if chosen.size()==2:break
	if chosen.size()!=2:
		state.status="setup blocked";_report("This landscape cannot support the campaign's two land routes. Return to your world.");open_screen();return {"error":"No connected campaign sites"}
	CivilizationSystem.civilizations.resize(2);CivilizationSystem.foreign_formations.clear()
	for civ:Dictionary in CivilizationSystem.civilizations:civ.relations.clear()
	CivilizationSystem._initialize_relations(551188)
	for i in 2:
		var civ:Dictionary=CivilizationSystem.civilizations[i]
		var home:Vector2i=chosen[i];var pos:=world_position(home)
		civ.name=["Bracken Hold","Mere Council"][i];civ.world_position=pos
		civ.population=1000.0;civ.cohorts=CivilizationSystem._cohorts_for_population(1000.0);civ.military_population=160.0;civ.food_capacity=1100.0
		for region:Dictionary in civ.strategic_regions:region.population=1000.0*float(region.population_share)
		civ.player_relation.at_war=true;civ.player_relation.treaty="war";civ.player_relation.contact_level=2;civ.player_relation.home_location_known=true;civ.player_relation.home_position={"x":pos.x,"z":pos.y};civ.player_relation.war_id="alderford_war"
		civ["general_campaign_owned"]=true
		for region:Dictionary in civ.strategic_regions:
			region["world_position"]={"x":pos.x,"z":pos.y}
			if region.role=="capital":region.name=civ.name
		var force:Dictionary=MilitaryCampaign.simulator.create_formation_force(String(civ.name)+" guard",[{"unit":"line_infantry","weapon":"spear","count":160,"equipment":160,"training":.58,"experience":.18}],.88,.8)
		force["commander"]={"name":["Sera Venn","Oren Hale"][i],"command":.6,"tactics":.6,"logistics":.6,"resolve":.6}
		state.rivals.append({"id":String(civ.id),"name":String(civ.name),"leader":["Sera Venn","Oren Hale"][i],"home":home,"cell":home,"force":force,"food":160.0*8*RATION,"reserve_food":160.0*12*RATION,"plan":"hold","goal":["Keep the crossing and its tolls","Keep the coalition alive without losing the council's army"][i],"memory":[],"seen":{},"adaptations":0,"last_signature":"","model_events":0,"fortification":1.5,"control":"rival"})
		state.seen[String(civ.id)]={"name":civ.name,"home":home,"cell":home,"troops":160,"day":GameState.elapsed_days}
	CivilizationSystem.contender_dominance_turns={"player":0}
	for civ:Dictionary in CivilizationSystem.civilizations:CivilizationSystem.contender_dominance_turns[String(civ.id)]=0
	CivilizationSystem._initialize_foreign_formations(551188)
	# The standard bounded patrol slots remain in reserve while these same
	# polities' forces are committed to the authored command campaign.
	for formation:Dictionary in CivilizationSystem.foreign_formations:formation["disabled_until_day"]=2147483647
	CivilizationSystem._rebuild_competition()
	CivilizationSystem.city_intelligence.seed_known_homes()
	CivilizationSystem._add_revealed_area(state.origin,50,"River war: established local geography")
	_report("Bracken Hold and the Mere Council have joined one war against Alderford. We have 240 soldiers, equipped spears and bows, and eight days of carried food. I recommend defending our approach first, then advancing only if their coalition separates. Give me the objective; I will handle the march, camp and fighting.")
	state.proposal={"action":"defend","target":"home","override":false}
	terrain._refresh_settlement_footprint();open_screen();return {"ok":true}

func _build_grid()->void:
	cells.clear()
	if state.is_empty():return
	for x in range(-RADIUS,RADIUS+1):
		for y in range(-RADIUS,RADIUS+1):
			var c:=Vector2i(x,y)
			if CivilizationSystem._scout_land_at(world_position(c)):cells[c]=true

func world_position(c:Vector2i)->Vector2:return Vector2(state.get("origin",Vector2.ZERO))+Vector2(c)*STEP

func route(start:Vector2i,goal:Vector2i,avoid:Array[Vector2i]=[])->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	if not cells.has(start) or not cells.has(goal):return result
	var queue:Array[Vector2i]=[start];var parents:Dictionary={start:start};var cursor:=0
	while cursor<queue.size():
		var c:=queue[cursor];cursor+=1
		if c==goal:
			while c!=start:result.push_front(c);c=parents[c]
			return result
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:Vector2i=c+offset
			if cells.has(next) and (next==goal or next not in avoid) and not parents.has(next) and not MilitaryCampaign.field_route_availability(world_position(c),world_position(next)).has("error"):
				parents[next]=c;queue.append(next)
	return result

func army()->Dictionary:
	var index:=MilitaryCampaign._field_army_index(int(state.get("army_id",-1)))
	return MilitaryCampaign.field_armies[index] if index>=0 else {}

func rival(id:String)->Dictionary:
	for r:Dictionary in state.get("rivals",[]):
		if String(r.id)==id:return r
	return {}

func public_context()->Dictionary:
	if not active:return {}
	var a:=army()
	return {"general":state.general_name,"authority":state.authority,"day":GameState.elapsed_days,"mission":state.mission,"proposal":state.proposal,"war":state.war,"outcome":state.outcome,"army":{"personnel":int(a.get("troops",0)),"food_days":food_days(),"exhaustion":float(state.exhaustion),"cohesion":"shaken" if float(a.get("morale",1))<.4 else "steady","equipment":equipment_ratio(a),"position":str(state.cell)},"known_rivals":state.seen.values(),"reports":state.reports.slice(-6),"treatment":state.treatment.slice(-4),"supported_actions":ACTIONS,"rules":"Generals execute. Questions never order. Approve refers only to the current proposal. Override confirms an existing objective, but obedience is judged by the engine. Relieve replaces command if captains support it. No psychological ratings are public."}

func food_days()->float:return float(state.get("food",0))/maxf(1,float(army().get("troops",0))*RATION)
func equipment_ratio(a:Dictionary)->float:
	var equipped:=0.0;var count:=0.0
	for f:Dictionary in a.get("formations",[]):equipped+=float(f.get("equipment",0));count+=float(f.get("count",0))
	return clampf(equipped/maxf(1,count),0,1)

func validate_order(order:Dictionary)->Dictionary:
	if not active or state.get("outcome","")!="":return {"error":"This war has ended. You can review it or return to your world.","kind":"unavailable"}
	var action:=String(order.get("action",""));var target:=String(order.get("target",""))
	if action not in ACTIONS:return {"error":"That action is not implemented in this campaign.","kind":"unsupported"}
	if action in ["defend","withdraw","recover"] and target not in ["home",""]:return {"error":"That mission protects or returns to Alderford. Name an attack or siege if you intend to enter a rival city.","kind":"unsupported"}
	if action in ["attack","besiege"]:
		if not state.seen.has(target):return {"error":"We have no located destination for that order.","kind":"impossible"}
		var goal:Vector2i=state.seen[target].home
		if goal!=state.cell and route(state.cell,goal).is_empty():return {"error":"There is no passable land approach. I cannot march an army across water.","kind":"impossible"}
	if int(army().get("troops",0))<=0 and action not in ["discuss","relieve"]:return {"error":"No fit soldiers remain under this command.","kind":"impossible"}
	return {"ok":true}

func propose(order:Dictionary)->Dictionary:
	var gate:=validate_order(order)
	if gate.has("error"):return gate
	var action:=String(order.action)
	if action=="discuss":return {"ok":true,"message":"Discussion; no mission changed."}
	if action=="approve":return commit_proposal(false)
	if action=="override":return commit_proposal(true)
	state.proposal={"action":action,"target":String(order.get("target","home")),"override":false}
	changed.emit()
	return {"ok":true,"message":"Objective ready. Commit it when you are ready for time to advance."}

func judgment(order:Dictionary)->Dictionary:
	var action:=String(order.action)
	if action=="relieve":return {"ok":true}
	var danger:=action in ["attack","besiege"] and (food_days()<2 or equipment_ratio(army())<.5 or float(state.exhaustion)>.75 or float(army().get("morale",1))<.4)
	if danger:
		if not bool(order.get("override",false)):return {"error":"I object. With our present food, equipment, exhaustion or shaken cohesion, advancing risks losing the army. Let us recover first. You can insist, but the captains will hear my objection.","kind":"objection"}
		var c:Dictionary=state.character
		if float(c.care)+float(c.resentment)>float(c.loyalty)+float(c.ambition)*.4+float(c.get("fear",.2))*.15+float(c.get("affection",.5))*.1-float(c.get("competence",.65))*.12:
			return {"error":"I heard your explicit order. I refuse to take these soldiers forward in this condition. I will hold here and answer for it before the captains.","kind":"refusal"}
	return {"ok":true}

func commit_proposal(insist:=false)->Dictionary:
	if resolving and state.status=="executing":return {"error":"Orders are resolving. Pause to speak before changing the objective."}
	var order:Dictionary=state.get("proposal",{}).duplicate(true)
	if order.is_empty():return {"error":"There is no proposed objective to approve."}
	order["override"]=insist
	var valid:=validate_order(order)
	if valid.has("error"):return valid
	var decision:=judgment(order)
	if decision.has("error"):
		state.treatment.append({"day":GameState.elapsed_days,"event":decision.kind,"order":order.duplicate(true)})
		if decision.kind=="refusal":state.character.resentment=minf(1,float(state.character.resentment)+.1)
		_report(String(decision.error),false);return decision
	if order.action=="relieve":
		if float(state.character.resentment)>.5 and state.cell!=Vector2i.ZERO:
			_report("The captains will not replace their commander here in the field after this dispute. Bring the army home before trying again.");return {"error":"Removal lacks practical authority here.","kind":"refusal"}
		state.treatment.append({"day":GameState.elapsed_days,"event":"command replaced"})
		var replacement:=HistoricalFigures.commander(MilitaryCampaign._acting_field_commander(false),"campaign_replacement_%d"%state.treatment.size())
		army().commander=replacement;state.general_name=replacement.name;state.character={"care":.6,"ambition":.7,"confidence":.6,"loyalty":.6,"resentment":.0}
		_report("Command has passed to %s with the captains' cooperation. The army and its obligations remain."%state.general_name);state.proposal={};return {"ok":true}
	if resolving:
		state["next_mission"]=order;state.proposal={};state.status="executing";changed.emit()
		return {"ok":true,"message":"Changed objective accepted. The current short movement commitment finishes first; then I will execute the new objective."}
	state.mission=order;state.proposal={};state.status="executing"
	_start_step();return {"ok":true,"message":"Objective committed. Both sides act; the wider world advances."}

func pause_to_speak()->void:
	if resolving:state.status="paused during execution"
	changed.emit()
func resume()->void:
	if resolving:state.status="executing"
	elif not state.mission.is_empty():_start_step()
	changed.emit()

func _start_step()->void:
	if not active or state.mission.is_empty() or state.get("outcome","")!="":return
	var action:=String(state.mission.action);var dest:Vector2i=state.cell
	if action in ["attack","besiege"]:dest=state.seen[String(state.mission.target)].home
	elif action in ["withdraw","recover","defend"]:dest=Vector2i.ZERO
	if action in ["attack","besiege"]:
		var speed:=maxf(3,18*(1-float(state.exhaustion)*.6))
		var needed:=float(route(state.cell,dest).size()+route(dest,Vector2i.ZERO).size())*STEP/speed+1.5
		if food_days()<needed:
			if state.cell==Vector2i.ZERO and food_days()>=7.5:
				_report("That mission exceeds our carried-food range. I cannot promise the advance and a safe return without a nearer base. Choose a nearer objective or hold home.");return
			state.mission["resupply_stop"]=true
		if bool(state.mission.get("resupply_stop",false)):dest=Vector2i.ZERO
	var avoid:Array[Vector2i]=[]
	if action in ["withdraw","recover","defend"]:
		for report:Dictionary in state.seen.values():
			if report.get("control","rival")=="rival" and GameState.elapsed_days-float(report.day)<3:avoid.append(report.cell)
	var path:=route(state.cell,dest,avoid)
	if path.is_empty() and dest!=state.cell:path=route(state.cell,dest)
	state["route"]=path.duplicate()
	if dest!=state.cell and path.is_empty():_report("The route is blocked. I have halted on land; a new objective is needed.");return
	if action=="besiege" and Vector2i(state.cell).distance_to(dest)<=1:path.clear()
	var next:Vector2i=path[0] if not path.is_empty() else state.cell
	var duration:=STEP/maxf(3,18*(1-float(state.exhaustion)*.6)*minf(1,food_days()+.2)) if next!=state.cell else 1.0
	var kind:="march" if next!=state.cell else ("resupply" if bool(state.mission.get("resupply_stop",false)) else action)
	var enemy_id:=""
	for r:Dictionary in state.rivals:
		if action not in ["besiege","withdraw","recover"] and r.control=="rival" and int(r.force.troops)>0 and next==r.cell:
			enemy_id=r.id;kind="battle";duration=(duration if next!=state.cell else 0.0)+30.0/1440.0;break
	if kind=="besiege":duration=2.0
	state.turn+=1
	pending_step={"kind":kind,"next":next,"duration":duration,"enemy":enemy_id,"rival_moves":{},"rival_routes":{}}
	# Plans read last observations before any committed movement is applied.
	for r:Dictionary in state.rivals:
		pending_step.rival_moves[String(r.id)]=_rival_decision(r,duration)
		pending_step.rival_routes[String(r.id)]=r.get("committed_route",[]).duplicate()
	budget=duration;resolving=true;state.status="executing";changed.emit()

func consume_time(delta:float)->float:
	if not resolving or state.get("status","")!="executing":return 0
	var amount:=minf(budget,delta*float(pending_step.duration)/2.0)
	budget=maxf(0,budget-amount)
	return amount

func after_world_time()->void:
	if resolving and budget<=.0000001 and state.status=="executing":_finish_step()

func _advance_campaign_interval(days:float,engaged_id:String="")->void:
	if days<=0:return
	if is_instance_valid(terrain):terrain.advance_world_time(days)
	state.food=maxf(0,float(state.food)-int(army().get("troops",0))*RATION*days)
	for r:Dictionary in state.rivals:
		if String(r.id)!=engaged_id:r.cell=_rival_decision(r,days)
		r.food=maxf(0,float(r.food)-int(r.force.troops)*RATION*days)

func _rival_decision(r:Dictionary,duration:float)->Vector2i:
	r["committed_route"]=[]
	if r.control!="rival" or int(r.force.troops)<=0:return r.cell
	var seen:Dictionary=r.seen
	var signature:=str([floori(float(r.food)/maxf(1,int(r.force.troops)*RATION)/2),seen.get("cell","unknown"),int(r.force.troops)/40])
	var reconsider:=String(r.last_signature)!=signature and (difficulty!="easy" or int(state.turn)%3==0)
	if reconsider:
		r.last_signature=signature;r.adaptations+=1
		if not r.seen.is_empty() and difficulty!="easy":
			for ally:Dictionary in state.rivals:
				if ally.id!=r.id and int(state.turn)>2:ally["coalition_report"]=r.seen.duplicate(true)
		r.plan="resupply" if float(r.food)<int(r.force.troops)*RATION*2 or float(r.force.morale)<.3 else "hold"
		if r.plan!="resupply" and not seen.is_empty():
			var available:=int(r.force.troops)
			for ally:Dictionary in state.rivals:
				if ally.id!=r.id and ally.control=="rival" and float(ally.food)>int(ally.force.troops)*RATION:available+=int(ally.force.troops)
			r.plan="intercept" if int(seen.get("troops",999))<available*1.3 or difficulty=="hard" else "hold"
		elif r.plan!="resupply":r.plan="pressure"
		if difficulty=="hard" and r.has("coalition_report") and r.plan!="resupply":r.seen=r.coalition_report.duplicate(true);r.plan="intercept"
		# Consequential transitions only, once per signature, bounded over the war.
		if difficulty!="easy" and r.adaptations in ([2,5,9] if difficulty=="hard" else [3,8]):GeneralDialogue.request_opponent(r.id)
	var goal:Vector2i=r.home
	if r.plan=="intercept" and not seen.is_empty():goal=seen.cell
	elif r.plan=="pressure":goal=Vector2i.ZERO
	var path:=route(r.cell,goal)
	var travel_progress:=float(r.get("travel_progress",0.0))+duration*18.0*(1-float(r.get("exhaustion",0))*.6)*minf(1,float(r.food)/maxf(1,int(r.force.troops)*RATION)+.2)/STEP
	var travel:=floori(travel_progress);r["travel_progress"]=travel_progress-travel
	if path.is_empty() or travel==0:return r.cell
	r["committed_route"]=path.slice(0,mini(path.size(),travel))
	return path[mini(path.size(),travel)-1]

func _finish_step()->void:
	resolving=false
	var step:=pending_step.duplicate(true);pending_step.clear()
	if state.has("next_mission"):
		state.mission=state.next_mission;state.erase("next_mission")
	var before:Vector2i=state.cell
	state.cell=step.next
	var a:=army();var pos:=world_position(state.cell);a.position={"x":pos.x,"z":pos.y};a.location_id="player_home" if state.cell==Vector2i.ZERO else "field_position"
	state.food=maxf(0,float(state.food)-int(a.get("troops",0))*RATION*float(step.duration))
	state.exhaustion=clampf(float(state.exhaustion)+(0.045 if step.kind=="march" else -.06)*float(step.duration),0,1)
	for r:Dictionary in state.rivals:
		var old:Vector2i=r.cell
		r.cell=step.rival_moves[String(r.id)]
		if r.control=="rival" and int(r.force.troops)>0 and (String(step.enemy)==String(r.id) or state.cell in step.get("rival_routes",{}).get(String(r.id),[])):
			r.cell=state.cell;step.enemy=r.id;step.kind="battle"
		r["exhaustion"]=clampf(float(r.get("exhaustion",0))+(0.045 if r.cell!=old else -.06)*float(step.duration),0,1)
		r.food=maxf(0,float(r.food)-int(r.force.troops)*RATION*float(step.duration))
		if r.cell==r.home:
			var provision:=minf(float(r.reserve_food),maxf(0,int(r.force.troops)*RATION*8-float(r.food)))
			r.food+=provision;r.reserve_food-=provision
		if r.cell.distance_to(state.cell)<=3:
			state.seen[String(r.id)]={"name":r.name,"home":r.home,"cell":r.cell,"troops":int(r.force.troops),"day":GameState.elapsed_days,"control":r.control}
			r.seen={"cell":state.cell,"troops":int(a.get("troops",0)),"day":GameState.elapsed_days}
		if (r.cell==state.cell or (old==state.cell and r.cell==before)) and step.enemy=="" and r.control=="rival" and int(r.force.troops)>0:step.enemy=r.id;step.kind="battle"
		if r.cell==Vector2i.ZERO and Vector2i(state.cell).length()>1 and int(r.force.troops)>=90:
			r["home_pressure"]=float(r.get("home_pressure",0))+float(step.duration)
			if float(r.home_pressure)>=2:
				state.outcome="Alderford's undefended approaches force a ceasefire. The coalition wins this war."
				_report(String(state.outcome));return
			if not bool(r.get("home_warning",false)):
				r["home_warning"]=true
				if state.mission.action in ["withdraw","recover","defend"] or bool(state.mission.get("resupply_stop",false)):
					_report("The coalition has reached our undefended approaches. We are already returning; I will continue toward home before the council must concede.",false)
				else:
					state.proposal={"action":"withdraw","target":"home"}
					_report("The coalition has reached our undefended approaches with a substantial force. We have about two days before the council must concede. I propose returning immediately.");return
		else:
			r["home_pressure"]=0.0;r["home_warning"]=false
	a.supply_level=clampf(food_days()/3,0,1)
	for formation:Dictionary in a.get("formations",[]):formation["personnel_condition"]=clampf(1-float(state.exhaustion)*.5,0,1)
	if step.kind=="battle":_battle(String(step.enemy));return
	if step.kind=="attack":
		var target:=rival(String(state.mission.target))
		if not target.is_empty() and state.cell==target.home:
			target["occupation_pressure"]=float(target.get("occupation_pressure",0))+float(step.duration)
			if float(target.occupation_pressure)<2:_start_step();return
			var held:=_secure_home(target,{"remaining_troops":int(a.troops),"dead":0},{"dead":0})
			if held:_report("%s's field army was absent. After two days securing access, our surviving force has occupied the city and detached its required guard. Its leadership concedes this part of the war. %s"%[String(target.name),String(state.outcome)])
			else:_report("We reached %s, but our remaining supplied force cannot hold it. I propose returning home."%target.name);state.proposal={"action":"withdraw","target":"home"}
			return
	if step.kind in ["recover","resupply"] and state.cell==Vector2i.ZERO:
		var needed:=maxf(0,int(a.troops)*RATION*8-float(state.food))
		state.food+=FoodSystem.issue_for_obligation(needed,"military","General replenishes carried rations",8,int(a.troops))
		state.exhaustion=maxf(0,float(state.exhaustion)-.2);a.morale=minf(1,float(a.morale)+.12)
		for formation:Dictionary in a.get("formations",[]):
			var weapon:=String(formation.get("weapon","improvised"))
			var need:=maxi(0,int(formation.get("authorized_count",formation.count))-int(formation.get("equipment",0)))
			var issued:=mini(need,int(MilitaryCampaign.military_inventory.get(weapon,0)))
			formation.equipment=int(formation.get("equipment",0))+issued
			MilitaryCampaign.military_inventory[weapon]=int(MilitaryCampaign.military_inventory.get(weapon,0))-issued
		var prepared:Dictionary=MilitaryCampaign.simulator.advance_preparation_day(a,{"equipment_replacements":0,"manpower_replacements":0})
		MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(state.army_id))]=prepared.force
		a=army()
		if step.kind=="resupply":
			state.mission["resupply_stop"]=false
			if food_days()<7.5:_report("Home stores cannot fill the expedition's carried rations. I have halted before committing the army to an unsupplied route.");return
			_start_step();return
		_report("We have rested at home and replenished from actual stores: %.1f days of food. Survivors recover and replacement weapons come from our finite arsenal. What objective comes next?"%food_days());return
	if step.kind=="withdraw" and state.cell==Vector2i.ZERO:
		_report("The army is home. %d fit soldiers returned; %d have been lost from action in this war. I recommend rest and replenishment."%[int(a.troops),int(state.losses)]);state.proposal={"action":"recover","target":"home"};return
	if step.kind=="besiege":
		var r:=rival(String(state.mission.target));r.fortification=maxf(1,float(r.fortification)-.15)
		_report("Two days spent preparing the approach while the wider world continued. Enemy earthwork advantage is reduced; food remaining %.1f days. I propose the assault."%food_days());state.proposal={"action":"attack","target":r.id};return
	if state.cell==Vector2i.ZERO and state.mission.action=="defend" and food_days()<3:
		state.food+=FoodSystem.issue_for_obligation(maxf(0,int(a.troops)*RATION*8-float(state.food)),"military","General replenishes home defense",8,int(a.troops))
	if food_days()<1 and state.mission.action not in ["withdraw","recover"]:
		_report("Carried food is below one day. I have stopped the advance and propose returning home; soldiers on paper are no substitute for rations.");state.proposal={"action":"withdraw","target":"home"};return
	if step.kind in ["march","defend"]:_start_step();return
	_report("We held our position for a day. Both rivals had time to act. No battle reached us. I can continue holding, or you can give a new objective.");state.proposal={"action":"defend","target":"home"}

func _secure_home(r:Dictionary,home_result:Dictionary,enemy_result:Dictionary)->bool:
	for civ:Dictionary in CivilizationSystem.civilizations:
		if civ.id!=r.id:continue
		var region:Dictionary=civ.strategic_regions.filter(func(site:Dictionary)->bool:return site.role=="capital")[0]
		var survivors:=home_result.duplicate(true)
		survivors["supply_level"]=army().get("supply_level",1);survivors["readiness"]=army().get("readiness",.8)
		var captured:=CivilizationSystem._capture_region(civ,String(region.id),survivors,enemy_result)
		if bool(captured.outcome.get("region_captured",false)):
			MilitaryCampaign.establish_occupation_force(String(r.id),captured.outcome.region,float(captured.outcome.occupation_required),int(state.army_id))
			r.control="secured";state.seen[String(r.id)]["control"]="secured"
			if state.rivals.all(func(other:Dictionary)->bool:return other.control=="secured"):state.outcome="The coalition concedes. Alderford has won this war."
			return true
	return false

func _battle(id:String)->void:
	var r:=rival(id);var a:=army()
	if r.is_empty():return
	var our:Dictionary=a.duplicate(true);var enemy:Dictionary=r.force.duplicate(true)
	our.readiness=float(our.get("readiness",.8))*clampf(food_days()/2,.25,1)*(1-float(state.exhaustion)*.6)
	enemy.readiness=float(enemy.get("readiness",.8))*clampf(float(r.food)/maxf(1,int(enemy.troops)*RATION*2),.25,1)*(1-float(r.get("exhaustion",0))*.6)
	var ground:=float(r.fortification) if r.cell==r.home else 1.05
	var defensive:bool=state.mission.get("action","")=="defend"
	var result:Dictionary=MilitaryCampaign.simulator.simulate(our,enemy,{"seed":int(state.seed)+int(state.turn)*7919,"max_rounds":8,"terrain_defense":ground,"attacker_exposure_modifier":.65 if defensive else 1.0})
	# Every exchange consumes thirty in-world minutes, including during viewing.
	var extra:=maxf(0,(int(result.round_count)-1)*30.0/1440.0)
	_advance_campaign_interval(extra,id)
	MilitaryCampaign._apply_field_army_result(int(state.army_id),result.attacker,result.rounds,int(result.seed),"attacker")
	r.force=MilitaryCampaign.simulator.create_formation_force(enemy.name,result.defender.formations,float(result.defender.morale),float(enemy.readiness))
	var killed:=0
	for row:Dictionary in result.rounds:killed+=int(row.get("defender_casualties",{}).get("killed",0))
	for civ:Dictionary in CivilizationSystem.civilizations:
		if civ.id==r.id:
			CivilizationSystem._remove_foreign_scout_population(civ,killed,true);civ.military_population=int(r.force.troops)
	state.losses+=maxi(0,int(our.troops)-int(army().troops));state.exhaustion=minf(1,float(state.exhaustion)+.18)
	if int(result.round_count)>0:
		state.battle_initial=[our.duplicate(true),enemy.duplicate(true)]
		state.battle=result;state.battle["location"]=world_position(state.cell)
	HistoricalFigures.record_battle(result)
	if state.has("figure_id"):
		var person:=HistoricalFigures.by_id(String(state.figure_id))
		if not person.is_empty() and person.get("status","living")!="living":
			var replacement:=HistoricalFigures.commander(MilitaryCampaign._acting_field_commander(false),"army_%d"%int(state.army_id))
			army().commander=replacement;state.general_name=replacement.name;state.figure_id=replacement.get("figure_id","")
			state.treatment.append({"day":GameState.elapsed_days,"event":"command succeeded after battle","previous":person.name,"successor":replacement.name})
	MilitaryCampaign.battle_history.push_front(result.duplicate(true))
	if MilitaryCampaign.battle_history.size()>40:MilitaryCampaign.battle_history.resize(40)
	var won:=String(result.outcome)=="attacker_victory"
	if won:
		if r.cell==r.home:
			_secure_home(r,result.attacker,result.defender)
		else:
			var escape:=route(r.cell,r.home)
			if not escape.is_empty():
				r.cell=escape[0]
				_advance_campaign_interval(STEP/12.0,id)
	else:
		var fallback:=route(state.cell,Vector2i.ZERO)
		if not fallback.is_empty():
			state.cell=fallback[0]
			_advance_campaign_interval(STEP/12.0,id)
			var retreat:=world_position(state.cell);army().position={"x":retreat.x,"z":retreat.y}
	var seen:Dictionary=state.seen[String(r.id)];seen.troops=int(r.force.troops);seen.cell=r.cell;seen.day=GameState.elapsed_days;seen["control"]=r.control
	r.memory.append({"event":String(result.outcome),"day":GameState.elapsed_days,"losses":int(enemy.troops)-int(r.force.troops)})
	if r.memory.size()>12:r.memory.pop_front()
	state.events.append({"day":GameState.elapsed_days,"result":result.outcome,"our":int(army().troops),"enemy":int(r.force.troops)})
	if state.events.size()>40:state.events.pop_front()
	var text:="%s against %s. %d of our soldiers and %d of theirs are out of action. We have %d fit soldiers, %.1f days of food. %s"%[String({"attacker_victory":"Victory","defender_victory":"Defeat","inconclusive":"Neither army broke","mutual_collapse":"Both armies broke"}.get(String(result.outcome),String(result.outcome))),String(r.name),int(our.troops)-int(result.attacker.remaining_troops),int(enemy.troops)-int(r.force.troops),int(army().troops),food_days(),"The approach is secured; its guard is detached from our field army." if r.control=="secured" else "I have kept the army together and await your next objective."]
	if state.rivals.all(func(other:Dictionary)->bool:return other.control=="secured"):
		state.outcome="The coalition concedes the approaches. Alderford has won this war."
		text+=" "+String(state.outcome)
	elif int(army().troops)<30:
		state.outcome="The expedition can no longer sustain this war. The coalition holds the approaches."
		text+=" "+String(state.outcome)
	if won and r.control!="secured" and r.cell!=r.home and int(result.round_count)==0:
		state.status="executing";_start_step();return
	state.proposal={"action":"withdraw" if not won or food_days()<2 else "recover","target":"home"}
	_report(text)

func _report(text:String,halt:bool=true)->void:
	if halt:state.status="deliberating";budget=0;resolving=false
	if state.get("outcome","")!="":
		for civ:Dictionary in CivilizationSystem.civilizations:
			civ.player_relation.at_war=false;civ.player_relation.treaty="truce";civ.player_relation.truce_until_day=int(GameState.elapsed_days)+365
	state.reports.append({"day":GameState.elapsed_days,"text":text})
	if state.reports.size()>24:state.reports.pop_front()
	while state.treatment.size()>32:state.treatment.pop_front()
	state.messages.append({"role":"assistant","content":text})
	if state.messages.size()>40:state.messages.pop_front()
	changed.emit()

func export_state()->Dictionary:return {"active":active,"difficulty":difficulty,"state":state.duplicate(true),"dialogue":GeneralDialogue.export_state(),"budget":budget,"resolving":resolving,"pending_step":pending_step.duplicate(true)}
func import_state(data:Dictionary)->Dictionary:
	reset_for_new_world()
	if not bool(data.get("active",false)):return {"ok":true}
	var incoming:Variant=data.get("state",{})
	if not incoming is Dictionary or not incoming.has_all(["army_id","rivals","cell","origin","reports","character"]) or incoming.rivals.size()!=2:return {"error":"Invalid general campaign state"}
	active=true;state=incoming.duplicate(true);difficulty=String(data.get("difficulty","medium"));state.status="deliberating"
	budget=maxf(0,float(data.get("budget",0)));pending_step=data.get("pending_step",{}).duplicate(true);resolving=bool(data.get("resolving",false)) and not pending_step.is_empty()
	if resolving:state.status="paused during execution"
	GeneralDialogue.import_state(data.get("dialogue",{}))
	return {"ok":true}
