extends "res://scripts/hud/content/dock_content_base.gd"
const Construction:=preload("res://scripts/settlement_construction.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Shelter:=preload("res://scripts/hud/shelter_status.gd")
const Upkeep:=preload("res://scripts/upkeep_warnings.gd")
const Tasks:=preload("res://scripts/manual_work.gd")
## What each building does, in the engine's numbers.
const Impact:=preload("res://scripts/building_impact.gd")
var selected_project:=""
var history_filter:=""
var history:RefCounted

## Individual buildings are drawn from each city's population and construction
## era; this dock shows what builders actually work on: the city's capacity and
## condition, its civic works, its infrastructure and its landmarks.
func meta()->Dictionary:
	return {"eyebrow":"CITIES & INFRASTRUCTURE","title":"Buildings","serif":true,"subtabs":["THE TOWN","CIVIC WORKS","INFRASTRUCTURE","LANDMARKS"]}
func tab(sub:int)->Dictionary:
	if sub==3:return preload("res://scripts/hud/content/dock_content_undertakings.gd").new(terrain,hud).tab(0)
	if sub==2:return _infrastructure_tab()
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _city_tab() if sub==0 else _civic_tab()))

const ERAS:=["Founding","Foothold","Hamlet","Village","Local centre","Town","Mature town","Urban system","City","Historic city","Regional system","Industrial age","Metropolitan age"]

# --------------------------------------------------------------------------
# City: what the builders are doing, the homes, the town's repair
# --------------------------------------------------------------------------

## The selected city's building work in plain words: what the builders are
## doing now and what holds them up, the homes and when more go up, and the
## town's repair, era and workshops. Every figure is the engine's own: the
## work and housing rules (settlement_construction.gd), the repair facts the
## town's official reads (upkeep_warnings.gd) and the city's form, era checks
## and capacities (SettlementModel), each with what it means for the town.
func _city_tab()->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var town:=String(city.get("name","Founding camp"))
	var housing:=Construction.housing()
	var crews:=_crews()
	if not GameState.settlement_site_committed or GameState.convoy_traveling:
		return {"brief":_now_brief(city,{},housing,crews),"blocks":[{"type":"rows","heading":town,"items":[_home_row(housing)]}]}
	var project:=_now_project(city)
	var homes:=Impact.homes()
	return {"brief":_now_brief(city,project,housing,crews),"blocks":[
		{"type":"rows","heading":town,"note":_count(int(crews.heads),"builder"),"items":_work_rows(city,project,crews)},
		{"type":"impact_lines","heading":"What the buildings do for the people now","lead":"Every figure below is the rule the game applies today, worked out for %s as it stands." % town,"lines":Impact.summary()},
		{"type":"rows","heading":"Homes","note":_count(int(housing.people),"person","people"),"items":[_home_row(housing),_new_homes_row(housing,crews)]},
		{"type":"impact_lines","heading":"What the homes do","note":"%s places a person" % Impact._two(float(homes.ratio)),"lines":homes.lines},
		{"type":"rows","heading":"The town's buildings","items":[_condition_row(),_era_row(crews),_workshops_row()]},
		{"type":"actions","items":[
			{"label":"Choose what to build","sub":"Civic works: each work, what it needs, your priority","on_press":jump("construction",1)},
			{"label":"Change who builds","sub":"The People: how many build, make and carry","on_press":jump("overview",0)}]}]}

## Who builds: the builders set to it, those on the town's own works, and the
## share a landmark or military works take (GameState.effective_workers).
func _crews()->Dictionary:
	var heads:=maxi(0,int(GameState.population_allocations.get("Construction",0)))
	var town:=maxf(0.0,GameState.effective_workers("Construction"))
	var with_military:=maxf(town,GameState.effective_workers("Construction",true))
	var landmark_share:=clampf(preload("res://scripts/undertaking_system.gd").share(GameState),0.0,0.95)
	return {"heads":heads,"town":town,"military":with_military-town,"landmark":with_military*landmark_share/(1.0-landmark_share)}

## The work the builders are on now; else the one they wait to start (your
## priority first, then the next known work whose earlier works stand), read
## as the Civic works list reads it. Empty when every known work is built.
func _now_project(city:Dictionary)->Dictionary:
	var current:=Construction._current_settlement_project()
	if not current.is_empty():return _project(current,current,false)
	var priority:=String(city.get("construction_priority",""))
	var waiting:Dictionary={}
	for definition:Dictionary in Construction._settlement_definitions():
		var title:=String(definition.name)
		if title in GameState.settlement_completed:continue
		var discovery:=String(definition.get("discovery",""))
		if not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
		if title==priority:return _project(definition,current,false)
		var ready:=true
		for required in definition.requires:
			if String(required) not in GameState.settlement_completed:ready=false
		if ready and waiting.is_empty():waiting=definition
	return {} if waiting.is_empty() else _project(waiting,current,false)

## The dock's lead: what the builders are doing now, how long it takes at
## today's pace, what it gets the town, or what holds them up.
func _now_brief(city:Dictionary,project:Dictionary,housing:Dictionary,crews:Dictionary)->Dictionary:
	if not GameState.settlement_site_committed:return {"tone":"info","title":"No town yet","why":"Building starts once the people choose where to settle."}
	if GameState.convoy_traveling:return {"tone":"info","title":"The people are on the move","why":"Building starts again when they settle."}
	if not String(city.get("occupied_by","")).is_empty():return {"tone":"danger","title":"Held by an enemy","why":"No one builds here until the town is free again."}
	if int(crews.heads)<=0:return {"tone":"danger","title":"No one is building","why":"Works, repairs and new homes all stop until people are set to building on The People."}
	var homes:=" They are also putting up homes." if bool(housing.building) else ""
	if project.is_empty():return {"tone":"info","title":"Every work the people know is built","why":"The builders keep the town in repair and put up homes as it fills. New works come as the people learn new ways to build."+homes}
	var title:=String(project.name)
	if bool(project.active):
		var pace:=_time_left(float(project.days_left)) if float(project.days_left)>=0.0 else "but "+_time_left(-1.0)
		return {"tone":"info","title":"Building the %s" % title,"why":"%d%% done, %s. When done it %s.%s" % [roundi(float(project.progress)*100.0),pace,_gain(project),homes]}
	return {"tone":"warn","title":"The builders are waiting","why":"Next is the %s, which %s. Meanwhile they keep the town in repair.%s" % [title,_lower_first(_first_blocker(project)),homes]}

## What the builders are doing: the work in hand (or the one they wait on),
## your priority if it waits, and who builds.
func _work_rows(city:Dictionary,project:Dictionary,crews:Dictionary)->Array:
	var rows:Array=[]
	var priority:=String(city.get("construction_priority",""))
	if project.is_empty():
		rows.append({"name":"Civic works","value":"All built","value_color":Tokens.GREEN,"sub":"Every work the people know how to build stands here","detail":"New works come as the people learn new ways to build.","accent":Tokens.GREEN})
	elif bool(project.active):
		var inputs:PackedStringArray=[]
		for input:Dictionary in project.inputs:inputs.append("%s %s" % [Plain.number(float(input.required)),ResourceSystem.display_name(String(input.resource)).to_lower()])
		var stores:=(" The %s it takes %s in the stores." % [_and_list(Array(inputs)),"is" if inputs.size()==1 else "are"]) if not inputs.is_empty() else ""
		rows.append({"name":String(project.name),"value":"%d%%" % roundi(float(project.progress)*100.0),"value_color":Tokens.GREEN,
			"sub":("Your priority · " if String(project.name)==priority else "")+_upper_first(_time_left(float(project.days_left))),
			"detail":"When done it %s.%s" % [_gain(project),stores],"accent":Tokens.GREEN})
	else:
		var more:PackedStringArray=[]
		for index in range(1,(project.blockers as Array).size()):more.append(_lower_first(String(project.blockers[index])))
		var also:=(" It also %s." % _and_list(Array(more))) if not more.is_empty() else ""
		rows.append({"name":String(project.name),"value":"Waiting","value_color":Tokens.AMBER,"sub":("Your priority · " if String(project.name)==priority else "")+_first_blocker(project),
			"detail":"When built it %s.%s" % [_gain(project),also],"accent":Tokens.AMBER})
	if not priority.is_empty() and not project.is_empty() and priority!=String(project.name) and priority not in GameState.settlement_completed:
		for definition:Dictionary in Construction._settlement_definitions():
			if String(definition.name)!=priority:continue
			var wanted:=_project(definition,{},false)
			rows.append({"name":"Your priority: %s" % priority,"value":"Waiting","value_color":Tokens.AMBER,"sub":_first_blocker(wanted),"detail":"The builders work on what they can until it is ready.","accent":Tokens.AMBER})
	rows.append(_builders_row(crews))
	return rows

func _builders_row(crews:Dictionary)->Dictionary:
	var heads:=int(crews.heads)
	if heads<=0 or float(crews.town)<0.5:
		return {"name":"Builders","value":"None" if heads<=0 else str(heads),"value_color":Tokens.RED,"sub":"No one is building: works, repairs and new homes all stop" if heads<=0 else "None are free for the town's own works",
			"detail":"Set people to building on The People.","accent":Tokens.RED}
	var town:=roundi(float(crews.town));var landmark:=roundi(float(crews.landmark));var military:=roundi(float(crews.military))
	var away:=heads-town-landmark-military
	var parts:PackedStringArray=["%d on the town's works" % town]
	if landmark>0:parts.append("%d raising a landmark" % landmark)
	if military>0:parts.append("%d on military works" % military)
	if away>0:parts.append("%d away or hurt" % away)
	# The water and rail works the same builders serve each month (SettlementModel.process_month).
	var sites:=preload("res://scripts/water_waste_works.gd").construction_sites()+preload("res://scripts/rail_freight.gd").construction_sites()
	for line:Dictionary in GameState.water_conveyance.get("lines",[]):
		if String(line.get("status",""))=="under_construction":sites+=1
	var infrastructure:=(" Each month they also work on %s: see Infrastructure." % _count(sites,"water or rail work","water or rail works")) if sites>0 else ""
	return {"name":"Builders","value":str(heads),"sub":"All on the town's works" if parts.size()==1 and town>=heads else _upper_first(", ".join(parts)),
		"detail":"More builders finish works sooner, keep the town in better repair and put up homes faster."+infrastructure,"accent":Tokens.MUTED}

## Where the town's places are and what they mean: the carried tents and the
## shelters and homes built here (settlement_construction.gd housing()). On
## the road the tents are pitched for only part of the band each night: the
## share the simulation shelters (simulation_metrics.housing_ratio).
func _home_row(h:Dictionary)->Dictionary:
	var places:=int(h.places);var people:=int(h.people);var carried:=int(h.carried);var built:=int(h.built)
	var short:=int(h.short);var spare:=int(h.spare)
	if GameState.convoy_traveling:
		var covered:=clampf(float(GameState.simulation_metrics.get("housing_ratio",0.0)),0.0,1.0)
		return {"name":"Housing","value":"%s places" % _n(carried),"sub":"On the road about %d in 10 sleep under cover each night" % roundi(covered*10.0),
			"detail":"The tents carried on the journey hold %s once pitched. More carriers and builders pitch more of them each night." % _n(carried),"accent":Tokens.AMBER}
	var status:="Everyone has a roof, with room for %s more" % _n(spare) if spare>0 else "Everyone has a roof, with no room to spare"
	if short>0:status="%s of the %s sleep in the open" % [_n(short),_count(people,"person","people")]
	var where:="All %s were built here." % _n(places)
	if carried>0 and built>0:where="%s are in the tents carried on the journey and %s in shelters built here." % [_n(carried),_n(built)]
	elif carried>0:where="No homes built yet: all %s are in the tents carried on the journey." % _n(places)
	elif places<=0:where="No shelter at all."
	var meaning:=" Spare places let newcomers and people brought home move in." if spare>0 else (" Sleeping in the open makes people sicker and slower at work." if short>0 else "")
	return {"name":"Housing","value":"%s places" % _n(places),"value_color":Tokens.RED if short>0 else Tokens.GREEN,"sub":status,"detail":where+meaning,"accent":Tokens.RED if short>0 else Tokens.GREEN}

## When the builders put up more homes, from the rule they follow.
func _new_homes_row(h:Dictionary,crews:Dictionary)->Dictionary:
	var trigger:=int(h.trigger);var batch:=int(h.batch)
	var rule:="Builders put up homes whenever more than %s people live here, %d%% of the places." % [_n(trigger),roundi(Construction.HOUSING_TRIGGER*100.0)]
	if not bool(h.shelters_built):
		return {"name":"New homes","value":"Lean-tos first","value_color":Tokens.AMBER,"sub":"The Lean-to Shelters come first: room for %s more" % _n(int(h.lean_to_places)),
			"detail":"After them, builders put up homes whenever the town fills.","accent":Tokens.MUTED}
	if bool(h.building):
		var left:="stopped: no one is building" if float(h.days_left)<0.0 else ("finished within a day" if float(h.days_left)<1.0 else "about %s left" % Plain.span_text(float(h.days_left)))
		return {"name":"New homes","value":"%d%%" % roundi(float(h.progress)*100.0),"value_color":Tokens.GREEN,"sub":"%s more places going up, %s" % [_n(batch),left],"detail":rule,"accent":Tokens.GREEN}
	var pace:="Then %s add about %s places every %s." % [_count(roundi(float(crews.town)),"builder"),_n(batch),Plain.span_text(float(h.days_per_batch))] if float(h.days_per_batch)>0.0 else "No one is building now, so none would go up."
	return {"name":"New homes","value":"Not needed yet","sub":"Builders start more once over %s people live here" % _n(trigger),"detail":pace,"accent":Tokens.MUTED}

## The town's repair, from the same facts its official reads (upkeep_warnings).
func _condition_row()->Dictionary:
	var f:=Upkeep.facts()
	var condition:=float(f.condition);var change:=float(f.monthly_change);var hold:=int(f.builders_to_hold)
	var sub:="Wearing out: down %s%% a month" % Plain.number(-change*100.0)
	if change>0.0005:sub="Sound: the builders mend faster than it wears" if condition>=0.995 else "Mending: up %s%% a month" % Plain.number(change*100.0)
	elif change>=-0.0005:sub="Holding: the builders just keep up with the wear"
	var detail:="Makers work only as fast as their workshops are kept, and worn buildings hold less in store."
	if change<-0.0005:detail=("%s would hold it. " % _count(hold,"builder") if hold>0 else "Too few materials to hold it, however many build. ")+detail
	elif hold>0 and int(f.builders)>hold:detail="%s would be enough to hold it. " % _count(hold,"builder")+detail
	if not String(f.short_material).is_empty():detail+=" Short of %s: only %d%% of the mending is paid for." % [Upkeep._material_words(String(f.short_material)),roundi(float(f.materials_paid)*100.0)]
	if change<-0.0005 and float(f.months_until_failing)>0.0:detail+=" At this rate it is badly worn in %s." % Plain.span_text(float(f.months_until_failing)*30.4)
	var color:=Tokens.GREEN if condition>=0.75 else (Tokens.AMBER if condition>=Upkeep.FAILING_BELOW else Tokens.RED)
	return {"name":"Condition","value":"%d%%" % roundi(condition*100.0),"value_color":color,"sub":sub,"detail":detail,"accent":color}

## The era the town builds in, whether it is rising, and what the next era
## still needs (SettlementModel.fabric_era_checks and the age thresholds).
func _era_row(crews:Dictionary)->Dictionary:
	var form:Dictionary=SettlementModel.city_form()
	var level:=float(form.get("tier",0.0))
	var tier:=clampi(floori(level),0,ERAS.size()-1)
	var day:=int(GameState.elapsed_days)
	var supported:=int(SettlementModel._supported_fabric_tier(day))
	var meaning:="Later eras give the buildings more store room and better workshops, and cost more to keep up."
	if tier>=ERAS.size()-1:return {"name":"Building era","value":ERAS[tier],"sub":"The last era there is","detail":meaning,"accent":Tokens.GOLD}
	var sub:="Stays %s for now" % ERAS[tier]
	var wanted:=_era_needs(tier+1,day)
	var needs:="%s needs %s. " % [ERAS[tier+1],_and_list(wanted)] if not wanted.is_empty() else ""
	if float(supported)>level:
		if float(form.get("materials_paid",1.0))>=0.5 and float(crews.town)>0.0:
			sub="Rising toward %s" % ERAS[mini(supported,ERAS.size()-1)];needs=""
		else:sub="Held back: too few builders or materials to rise"
	return {"name":"Building era","value":ERAS[tier],"sub":sub,"detail":needs+meaning,"accent":Tokens.GOLD}

## What an era still needs, in plain words: the town's age, its crews and
## works, and building knowledge.
func _era_needs(next:int,day:int)->Array:
	var needs:Array=[]
	var age:=float(SettlementModel._settlement_age_years(day))
	var need_age:=float(SettlementModel.FABRIC_ERA_AGE_YEARS[next])
	if age<need_age:needs.append("the town to be %s old (%s to go)" % [_years_words(need_age),Plain.span_text((need_age-age)*365.0)])
	for check:Dictionary in SettlementModel.fabric_era_checks(next):
		if bool(check.met):continue
		var have:=int(check.have);var need:=int(check.need)
		match String(check.what):
			"lean_to_shelters":needs.append("the Lean-to Shelters built")
			"builders":needs.append("%d builders (%d now)" % [need,have])
			"works":needs.append("%d finished works (%d now)" % [need,have])
			"makers":needs.append("%d makers (%d now)" % [need,have])
			"carriers":needs.append("%d carriers (%d now)" % [need,have])
			"stewards":needs.append("%d store keepers (%d now)" % [need,have])
			"districts":needs.append("a second district")
			"labor":needs.append("work going at %d%% (%d%% now)" % [roundi(float(check.need)*100.0),roundi(float(check.have)*100.0)])
			_:needs.append("more knowledge of building, roads and crafts")
	if next>preload("res://scripts/settlement_architecture_knowledge.gd").ceiling():needs.append("new building knowledge")
	return needs

## The workshops and stores the town's buildings hold, how fully staffed they
## are (SettlementModel._built_capacities) and the store room they add.
func _workshops_row()->Dictionary:
	var capacities:Dictionary=SettlementModel.city_capacities()
	var people:=maxf(1.0,float(GameState.population_total))
	var need:=ceili(people*0.1)
	var makers:=GameState.effective_workers("Crafting");var carriers:=GameState.effective_workers("Logistics")
	var staffed:=minf(makers,carriers)/maxf(1.0,people*0.1)
	var storage:Dictionary=capacities.get("storage_bulk",{})
	var room:=0.0
	for kind in storage:room+=float(storage[kind])
	var total:=float(GameState.material_metrics.get("storage_capacity",0.0))
	var added:="less than a unit" if room<1.0 else Plain.number(roundf(room))
	var holds:=("The buildings add %s to the town's %s units of store room." % [added,Plain.number(roundf(total))]) if total>=room and total>0.0 else ("The buildings add %s of store room." % (added if room<1.0 else added+" units"))
	return {"name":"Workshops and stores","value":"Fully staffed" if staffed>=1.0 else "Short-handed","value_color":Tokens.GREEN if staffed>=1.0 else Tokens.AMBER,
		"sub":"%d of the %d makers and %d of the %d carriers they need" % [mini(need,floori(makers)),need,mini(need,floori(carriers)),need],
		"detail":"Staffed and kept up, workshops help the makers, and stores speed hauling and trade. "+holds,"accent":Tokens.MUTED}

# --- Words ------------------------------------------------------------------

## What a work gets the town, in its own words (the Lean-to Shelters with the
## places they add).
static func _gain(project:Dictionary)->String:
	if String(project.get("name",""))=="Lean-to Shelters":return "protects health and adds room for %s people" % _n(Construction.lean_to_places())
	return String(project.get("effect","serves the town"))

static func _first_blocker(project:Dictionary)->String:
	return String(project.blockers[0]) if not (project.get("blockers",[]) as Array).is_empty() else "Waits its turn"

static func _time_left(days:float)->String:
	if days<0.0:return "no one is at work on it"
	if days<1.0:return "finished within a day at today's pace"
	return "about %s left at today's pace" % Plain.span_text(days)

static func _lower_first(text:String)->String:
	return text.left(1).to_lower()+text.substr(1) if not text.is_empty() else text

static func _upper_first(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if not text.is_empty() else text

static func _and_list(items:Array)->String:
	if items.size()<=1:return "" if items.is_empty() else String(items[0])
	return ", ".join(PackedStringArray(items.slice(0,items.size()-1)))+" and "+String(items.back())

static func _n(value:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(value)

static func _count(value:int,one:String,many:String="")->String:
	return "%s %s" % [_n(value),one if value==1 else (many if not many.is_empty() else one+"s")]

static func _years_words(years:float)->String:
	if years<1.0:return "%d months" % roundi(years*12.0)
	if is_equal_approx(years,1.0):return "a year"
	return "%s years" % Plain.number(years)

## Civic works: the named early works, in progress and completed.
func _civic_tab()->Dictionary:
	var civic:=_local_tab(0)
	var completed:Array=[]
	for project:Dictionary in Construction._settlement_definitions():
		if String(project.name) in GameState.settlement_completed:completed.append({"name":String(project.name),"value":"Complete","sub":_upper_first(_gain(project)),"accent":Tokens.GREEN})
	if not completed.is_empty():civic.blocks.append({"type":"rows","heading":"COMPLETED CIVIC WORKS","items":completed})
	return civic

## Infrastructure in every city: water works, conduits, rail, docks and plants.
func _infrastructure_tab()->Dictionary:
	var blocks:Array=[]
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.get("id",""))
		var rows:Array=SettlementModel.with_city_resources(id,func()->Array:return _infrastructure_rows(id))
		if not rows.is_empty():blocks.append({"type":"rows","heading":String(city.get("name","Settlement")).to_upper(),"items":rows})
	if blocks.is_empty():blocks.append({"type":"text","heading":"INFRASTRUCTURE","text":"No water works, conduits, rail lines, docks or plants yet. Builders raise them once their practices are adopted and materials arrive."})
	# The defence works, stage by stage: what each gives, and which stand.
	for stage:Dictionary in Impact.defences():
		blocks.append({"type":"impact_lines","heading":("%s · built" if bool(stage.built) else "%s · not yet built") % String(stage.name),"lines":stage.lines,"columns":2})
	return {"blocks":blocks}

static func _infrastructure_rows(city_id:String)->Array:
	var rows:Array=[]
	var works=preload("res://scripts/water_waste_works.gd")
	for work:Dictionary in works.data().get("works",[]):
		# What it does, from its practice and its coverage (building_impact.gd).
		var told:PackedStringArray=[]
		for line:Dictionary in Impact.water_work(String(work.kind)).lines:told.append("%s %s: %s" % [String(line.label),String(line.value),String(line.words)])
		rows.append({"name":String(works.SPECS.get(String(work.kind),{}).get("name",String(work.kind).capitalize())),"value":String(work.get("status","")).replace("_"," ").capitalize(),"sub":"Condition %d%%" % roundi(float(work.get("condition",1.0))*100.0),"detail":String.chr(10).join(told),"accent":Tokens.TEAL})
	for line:Dictionary in preload("res://scripts/water_conveyance.gd").data().get("lines",[]):
		rows.append({"name":"Water conduit","value":String(line.get("status","")).replace("_"," ").capitalize(),"sub":"Condition %d%%" % roundi(float(line.get("condition",1.0))*100.0),"accent":Tokens.TEAL})
	for line:Dictionary in preload("res://scripts/rail_freight.gd").data().get("lines",[]):
		rows.append({"name":"Rail line","value":String(line.get("status","")).replace("_"," ").capitalize(),"sub":"%d wagons" % int(line.get("wagons",0)),"accent":Tokens.BLUE})
	for base:Dictionary in MilitaryCampaign.joint_operations.state.get("bases",[]):
		if String(base.get("city_id",""))==city_id:rows.append({"name":"Naval dock","value":"Condition %d%%" % roundi(float(base.get("condition",1.0))*100.0),"accent":Tokens.BLUE})
	var ops=preload("res://scripts/technology_operations.gd")
	if GameState.resource_settlement_id.is_empty():
		for plant:String in ops.data().get("plants",{}):
			var record:Dictionary=ops.data().plants[plant]
			if int(record.get("installed",0))+int(record.get("building",0))<=0:continue
			rows.append({"name":String(ops.PLANTS.get(plant,{}).get("name",plant.capitalize())),"value":"%d installed" % int(record.get("installed",0)),"sub":ops.status(plant),"accent":Tokens.GOLD})
	return rows

func _local_tab(sub:int)->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var priority:=String(city.get("construction_priority",""))
	var current:=Construction._current_settlement_project()
	var projects:Array=[]
	for project:Dictionary in Construction._settlement_definitions():
		var done:=String(project.name) in GameState.settlement_completed
		if done!=(sub==1):continue
		var discovery:=String(project.get("discovery",""))
		if not done and not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
		projects.append(_project(project,current,done))
	var stocks:Dictionary={}
	for resource in ["Timber","Stone","Clay","Fiber Plants"]:stocks[resource]=float(GameState.resource_stockpiles.get(resource,0))
	return {"blocks":[{"type":"construction_queue","shelter":Shelter.describe(GameState.settlement_completed,GameState.housing_capacity,GameState.population_total,Construction.carried_places()),"projects":projects,"selected":selected_project,"priority":priority,"stocks":stocks,"city":String(city.get("name","Founding camp")),"builders":int(GameState.population_allocations.get("Construction",0)),"carriers":int(GameState.population_allocations.get("Logistics",0)),"can_prioritize":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"committed":GameState.settlement_site_committed,"completed":GameState.settlement_completed.size(),"on_select":_select,"on_priority":_priority,"on_site":terrain._on_settlement_action_pressed,"on_record":func():hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,GameState.selected_player_settlement_id))}]}
## One civic work as both tabs read it: progress, the material bill (the mix
## the builders will use, or the closest known one), what holds it up in plain
## words, and the days left at today's pace (Construction.daily_work) while it
## is the work in hand.
func _project(project:Dictionary,current:Dictionary,done:bool)->Dictionary:
	var title:=String(project.name)
	var materials:Dictionary=Construction._settlement_project_material_plan(project)
	var feasible:=not materials.is_empty()
	if not feasible:
		var least_missing:=INF
		for option:Dictionary in Construction.material_options(project):
			if not String(option.get("requires","")).is_empty() and String(option.requires) not in GameState.known_discoveries:continue
			var missing:=0.0
			for resource:String in option.cost:missing+=maxf(0,float(option.cost[resource])-float(GameState.resource_stockpiles.get(resource,0)))/maxf(1,float(option.cost[resource]))
			if missing<least_missing:least_missing=missing;materials=option.cost
	var inputs:Array=[]
	var blockers:Array[String]=[]
	for resource:String in materials:
		var stored:=float(GameState.resource_stockpiles.get(resource,0));var required:=float(materials[resource])
		inputs.append({"resource":resource,"stored":stored,"required":required})
		if stored+.0001<required:blockers.append("Needs %s more %s" % [Plain.number(required-stored),ResourceSystem.display_name(resource).to_lower()])
	for required in project.requires:
		if String(required) not in GameState.settlement_completed:blockers.push_front("Needs the %s first" % String(required))
	for role:String in project.minimum:
		var available:=int(GameState.population_allocations.get(role,0))
		if available<=0:blockers.append("Needs people %s" % String((Tasks.TASKS.get(role,[role.to_lower(),"",role.to_lower()]) as Array)[2]))
	var discovery:=String(project.get("discovery",""))
	if not discovery.is_empty() and DiscoverySystem.adoption(discovery)<.10:blockers.push_front("Needs the people to take up the practice")
	if bool(project.get("requires_water",false)) and not bool(GameState.water_metrics.get("source_accessible",false)):blockers.push_front("Needs water within reach")
	if bool(project.get("known_resource",false)) and ResourceSystem.visible_deposits().is_empty():blockers.push_front("Needs a known place to dig or cut: send scouts")
	if GameState.convoy_traveling:blockers.push_front("Needs the people to settle")
	if not GameState.settlement_site_committed:blockers.push_front("Needs a place to settle")
	var active:=title==String(current.get("name","")) and blockers.is_empty()
	var worked:=float(GameState.settlement_projects.get(title,0))
	var rate:=Construction.daily_work() if active else 0.0
	return {"name":title,"done":done,"active":active,"impact":Impact.work(title),"progress":1.0 if done else clampf(worked/float(project.days),0,1),"state":"Complete" if done else ("Building" if active else (blockers[0] if not blockers.is_empty() else "Waits its turn")),"blockers":blockers,"inputs":inputs,"bill_note":"Selected material mix" if feasible else "Closest known mix · alternatives considered","effect":String(project.get("effect","")),
		"days_left":maxf(0.0,float(project.days)-worked)/rate if rate>0.0 else -1.0}
func _select(title:String)->void:
	selected_project="" if selected_project==title else title;hud.request_immediate_dock_refresh()
func _priority(title:String)->void:
	terrain._report_military_action(Construction.set_priority(GameState.selected_player_settlement_id,title));hud.request_immediate_dock_refresh()
func signature()->Array:
	return [GameState.selected_player_settlement_id,GameState.settlement_site_committed,GameState.settlement_projects.duplicate(true),GameState.settlement_completed.duplicate(),GameState.resource_stockpiles.duplicate(),GameState.population_allocations.duplicate(),GameState.elapsed_days,GameState.settlement_network_revision,selected_project,GameState.building_ledger.size(),GameState.next_building_record_id,history_filter,history.signature() if history!=null else []]

func _settlements_tab()->Dictionary:
	var blocks:Array=[{"type":"text","heading":"CONSTRUCTION BY SETTLEMENT","text":"Completed works count finished projects. A shelter project can provide several structures. History records later building changes, repairs and losses."}]
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.get("id",""))
		var report:Dictionary=SettlementModel.with_city_resources(id,func()->Dictionary:
			return _settlement_report(GameState.settlement_completed,GameState.settlement_projects))
		blocks.append({"type":"text","heading":String(city.get("name","Settlement")),"text":"%d completed works · %d underway" % [report.completed,report.underway]})
		if not report.items.is_empty():blocks.append({"type":"rows","items":report.items})
		blocks.append({"type":"actions","items":[{"label":"CONSTRUCTION HISTORY","sub":String(city.get("name","Settlement")),"on_press":_open_city_record.bind(id)}]})
	if GameState.player_settlements.is_empty():blocks.append({"type":"text","heading":"SETTLEMENTS","text":"Choose a settlement site to begin construction."})
	return {"blocks":blocks}

static func _settlement_report(completed:Array,progress:Dictionary)->Dictionary:
	var items:Array=[]
	var underway:=0
	for title in completed:
		items.append({"name":String(title),"value":"1 completed work","accent":Tokens.GREEN})
	for project:Dictionary in Construction._settlement_definitions():
		var title:=String(project.name)
		if title in completed or float(progress.get(title,0))<=0:continue
		underway+=1
		items.append({"name":title,"value":"%.1f%%" % (100.0*clampf(float(progress[title])/float(project.days),0,1)),"sub":"Work in progress","accent":Tokens.AMBER})
	return {"completed":completed.size(),"underway":underway,"items":items}

func _open_city_record(id:String)->void:
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,id))

func _history_tab()->Dictionary:
	if history==null:history=preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud)
	history.settlement_id=history_filter
	var result:Dictionary=history.tab(0)
	var filters:Array=[{"label":"ALL SETTLEMENTS","on_press":_filter_history.bind("")}]
	for city:Dictionary in GameState.player_settlements:
		filters.append({"label":String(city.get("name","Settlement")),"on_press":_filter_history.bind(String(city.get("id","")))})
	result.blocks.push_front({"type":"actions","items":filters})
	return result

func _filter_history(id:String)->void:
	history_filter=id
	if history!=null:history.pages[0]=0
	hud.request_immediate_dock_refresh()
