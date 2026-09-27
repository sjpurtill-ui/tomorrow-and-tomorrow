extends "res://scripts/hud/content/dock_content_base.gd"
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Works:=preload("res://scripts/hud/water_conveyance_controls.gd")
## SETTLEMENT section: People & Labor / Works & Defense / History.
## Replaces the settlement dashboard, the settler side panel, and the
## population ledger summary.

const COHORT_LABELS:Array[Array]=[["children","0–13","Children, not yet working"],["youth","14–24","Young people of working age"],["early_adults","25–34","Adults of working age"],["established_adults","35–44","Adults of working age"],["mature_adults","45–59","Older adults, still working"],["elders","60+","Elders, mostly past heavy work. How long people live is an average from birth, not a limit."]]
const ROLES:Array[Array]=[
	["Food","Food gatherers","Gather, hunt and fish. Taking too much thins the land nearby."],
	["Survey","Searchers","Look for wood, stone, clay and water, and judge how good they are."],
	["Extraction","Cutters and diggers","Cut wood, dig stone and clay, and gather fibre from known places."],
	["Construction","Builders","Put up shelters, stores and paths as the place needs them."],
	["Crafting","Makers","Make and mend tools, baskets, pots and cloth."],
	["Logistics","Carriers","Carry food and materials home; far sources are only useful if someone carries."],
	["Knowledge","Lore keepers","Watch, remember and work out new ways. Where their attention goes decides what the people learn next."],
	["Administration","Stewards","Keep track of work and stores; settle quarrels so people pull together."],
	["Defense","Watch","Keep watch and stand ready; every watcher is away from other work."],
]

func meta()->Dictionary:
	var settlement:=_selected_settlement()
	return {
		"eyebrow":"Your %s" % String(settlement.get("classification","settlement")).to_lower(),
		"title":String(settlement.get("name",terrain._settlement_display_name())).capitalize(),
		"subtabs":["Overview","History"],
	}

func tab(sub:int)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _city_tab(sub)))

func _city_tab(sub:int)->Dictionary:
	var settlement:=_selected_settlement()
	var settlement_id:=String(settlement.get("id",""))
	if settlement_id.is_empty() and sub==0:
		var committed:=GameState.settlement_site_committed
		var traveling:=bool(GameState.founding_journey.get("active",false))
		var travel_advice:Dictionary=preload("res://scripts/civilization_travel.gd").advice()
		var items:Array=[{"label":"Food and water","sub":"How long the stores last","on_press":jump("economy",0)}]
		if committed:items.append({"label":"The first building work","sub":"How far the Hearth Circle has come","on_press":jump("construction",0)})
		else:
			items.push_front({"label":"Settle here","sub":"Make this place our home","primary":not traveling,"on_press":terrain._on_settlement_action_pressed})
			var led_mode:=String(travel_advice.get("caravan_mode",""))
			if traveling:items.push_front({"label":"Stop here","sub":"Hold the party where it stands","primary":false,"on_press":terrain._halt_founding_convoy_to_forage,"tip":"The caravan leader usually decides when to camp. This makes the party stop and wait (going to water first if there is none here) until you tell it to go on."})
			elif led_mode in ["held","watering","foraging","resting","provisioning"]:items.push_front({"label":"Go on","sub":"Break camp and keep travelling","primary":led_mode=="held","on_press":func()->void:terrain._on_caravan_override("founding","resume"),"tip":"The caravan leader moves on by themself once water, food and health allow. This tells them to go on now."})
		return {"brief":{"tone":String(travel_advice.get("tone","info")),"title":"A home is taking shape" if committed else String(travel_advice.get("status","Choose a home")).capitalize(),"why":"Let time run with the controls above. The people build the Hearth Circle as they go about their work; once it stands, the local leader takes charge of daily work." if committed else String(travel_advice.get("reason","The party can walk into unknown land and camp to forage on the way."))+" Settling makes the place where the party stands our home."},"blocks":[{"type":"actions","items":items}]}
	if sub==1:return {"blocks":_history_blocks(GameState.simulation_metrics,settlement)}
	return {"blocks":_overview_blocks(settlement)}


func _selected_settlement()->Dictionary:
	var settlement:Dictionary=SettlementModel.selected_settlement_snapshot()
	if settlement.is_empty():
		return {"id":"","name":terrain._settlement_display_name(),"classification":"settlement","population":GameState.population_total,"primary":true}
	return settlement

func _people_blocks(productive:int,local_population:int,local_share:float,settlement:Dictionary,management:Dictionary)->Array:
	var cohorts:Dictionary=GameState._integer_age_cohorts()
	var segment_items:Array=[]
	var dependents:=0
	for entry in COHORT_LABELS:
		var count:=roundi(float(cohorts.get(String(entry[0]),0))*local_share)
		if String(entry[0]) in ["children","elders"]: dependents+=count
		segment_items.append({"label":String(entry[1]),"value":str(count),"share":maxf(0.5,float(count)),"color":Tokens.COHORT_COLORS[COHORT_LABELS.find(entry)],"tip":String(entry[2])})
	var local_allocations:Dictionary=management.get("allocations",GameState.population_allocation_percentages)
	var alloc_items:Array=[]
	var assigned:=0
	for index in ROLES.size():
		var role:Array=ROLES[index]
		var key:=String(role[0])
		var count:=roundi(float(local_allocations.get(key,0.0))/100.0*float(maxi(1,productive)))
		assigned+=count
		alloc_items.append({
			"name":String(role[1]),"count":count,
			"pct":"%d%%" % roundi(float(count)/maxf(1.0,float(productive))*100.0),
			"color":Tokens.ROLE_COLORS[index],"tip":String(role[2]),
		})
	var settlement_id:=String(settlement.get("id",""))
	var blocks:Array=[
		Charts.population(settlement_id,true),
		{"type":"segments","heading":"Ages","note":preload("res://scripts/hud/home_plain.gd").dependency(dependents,local_population-dependents),"items":segment_items,"legend":"Green bands are people of working age; the others are children and elders."},
		{"type":"alloc","heading":"Who does what each day","note":"%s sets this; about %d of the %d who can work" % [String(management.get("leader",{}).get("name","The local leader")).get_slice(" ",0),assigned,productive],"items":alloc_items},
		{"type":"actions","items":[
			{"label":"Talk with the leader","sub":"In the court: ask, order or replace","primary":true,"on_press":court({"settlement_id":settlement_id}),"tip":"The government appoints local leaders. Call this one to the court to talk, give orders or replace them."},
			{"label":"Rename this place","sub":"The name on the map","on_press":terrain._open_settlement_naming_panel.bind(settlement_id),"tip":"Give this place the name used on the map and in history."},
		]},
	]
	return blocks


func _history_blocks(_metrics:Dictionary,settlement:Dictionary)->Array:
	var id:=String(settlement.get("id",""))
	return [
		{"type":"chronicle","heading":"The years remembered","events":preload("res://scripts/hud/settlement_history_data.gd").events(settlement,GameState.discovery_log,GameState.building_ledger)},
		Charts.population(id,true),
		Charts.reserves(id),
		{"type":"actions","heading":"More of the record","items":[
			{"label":"Births and deaths","sub":"Across all our people","on_press":func():hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(terrain,hud))},
			{"label":"What was built here","sub":"Building, damage and rebuilding","on_press":func():hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,id))}]}]


func signature()->Array:
	return [GameState.discovery_log.hash(),GameState.strategic_history.get("last_day",-1),GameState.selected_player_settlement_id,GameState.settlement_network_revision,GovernmentPeopleSystem.revision,GameState.population_total,GameState.population_health,GameState.housing_capacity,float(GameState.simulation_metrics.get("housing_ratio",-1.0)),GameState.population_allocations.duplicate(),GameState.lifetime_births,GameState.lifetime_deaths,GameState.settlement_completed.size(),GameState.building_ledger.size(),snappedf(float(GameState.simulation_metrics.get("food_days",-1.0)),0.5),GameState.water_waste_works.get("works",[]).hash(),GameState.water_conveyance.get("lines",[]).size(),snappedf(ResourceSystem.stored_bulk(),1.0)]

## What the local leader is putting extra hands on, as a short phrase.
const FOCUS_WORDS:={"water":"water","provisions":"food","shelter":"shelter","research":"learning","defense":"the watch","logistics":"carrying and paths","development":"building up the place","establishment":"setting the place up","balanced":"everyday needs"}
## The choices offered on the Settlement dock, in the order shown.
const ASKABLE:=["water","provisions","shelter","research","defense"]

func _overview_blocks(settlement:Dictionary)->Array:
	var id:=String(settlement.get("id",""))
	var management:=GovernmentPeopleSystem.settlement_management(id)
	var population:=int(settlement.get("population",GameState.population_total))
	var metrics:Dictionary=GameState.simulation_metrics
	var flow:={"produced":float(metrics.get("food_production",0.0)),"eaten":float(metrics.get("food_eaten",0.0)),"spoiled":float(metrics.get("food_spoilage",0.0)),"missions":FoodSystem.issued_on_day(int(GameState.elapsed_days)),"net":float(metrics.get("food_net",0.0))}
	var food_reading:=Words.food(float(metrics.get("food_days",-1.0)),flow,metrics.has("food_days"))
	var shelter:=preload("res://scripts/hud/shelter_status.gd").describe(GameState.settlement_completed,GameState.housing_capacity,population)
	var age:=maxi(0,int(GameState.elapsed_days)-int(settlement.get("founded_day",0)))
	var leader:Dictionary=management.get("leader",{})
	var leader_name:=String(leader.get("name","")).get_slice(" ",0)
	var focus:=String(management.get("focus","balanced"))
	var managed:=bool(management.get("auto_manage",true))
	var occupied:=not String(SettlementModel.settlement_record(id).get("occupied_by","")).is_empty()
	var direction:=""
	if management.is_empty():direction="No one runs this place's daily work yet."
	elif managed:direction="%s chooses the daily work and is putting extra hands on %s. %s" % [leader_name if not leader_name.is_empty() else "The local leader",String(FOCUS_WORDS.get(focus,"everyday needs")),String(management.get("focus_reason",""))]
	else:direction="You asked %s for more hands on %s. %s" % [leader_name if not leader_name.is_empty() else "the local leader",String(FOCUS_WORDS.get(focus,focus)),String(management.get("focus_effect",""))]
	var choices:Array=[]
	for key:String in ASKABLE:
		choices.append({"id":key,"label":String(FOCUS_WORDS[key]).capitalize(),"tip":String(GovernmentPeopleSystem.FOCUS_EFFECTS.get(key,""))+" Other work slows.","on_press":_ask_for_hands.bind(id,key)})
	choices.append({"id":"","label":"Let %s decide" % (leader_name if not leader_name.is_empty() else "the leader"),"tip":"The leader spreads the work across what the place needs.","on_press":_ask_for_hands.bind(id,"")})
	var works_context:=_works_context(settlement)
	var works_city:="" if bool(settlement.get("primary",false)) else id
	return [{"type":"settlement_overview","leader":leader,"managed":managed,"direction":direction,
		"can_direct":not management.is_empty() and not occupied,"choices":choices,"current":"" if managed else focus,
		"metrics":[{"label":"People living here","value":EraWords.people(population)},{"label":"Settled","value":_since(age)},{"label":EraWords.life_title().capitalize() if not EraWords.reckoned() else "Life expectancy","value":"%.1f years" % GameState.projected_life_expectancy() if EraWords.reckoned() else EraWords.life(GameState.projected_life_expectancy())}],
		"cards":[
			{"kind":"building","art":1,"title":"Homes and shelter","show_art":shelter.built,"empty_label":shelter.empty_label,"detail":shelter.detail,"action":"Buildings","on_press":jump("construction",0)},
			{"kind":"food","art":0,"title":"Food and water","detail":String(food_reading.sentence),"action":"Food","on_press":jump("economy",0)},
			{"kind":"building","art":3,"title":"Work and making","detail":"What the workshops are making and how fast.","action":"Production","on_press":jump("production",0)}],
		"works":_works_data(works_context,works_city) if not works_context.is_empty() else {},
		"on_leader":court({"settlement_id":String(id)}),
		"on_population":focused_action("Ages and families","",_people_report.bind("population")).on_press,"on_work":focused_action("Who does what","",_people_report.bind("work")).on_press,
		"on_rename":terrain._open_settlement_naming_panel.bind(id)}]

static func _since(days:int)->String:
	if days<30:return "this season"
	return Plain.span_text(float(days))+" ago"

func _ask_for_hands(settlement_id:String,focus:String)->void:
	var result:=GovernmentPeopleSystem.restore_delegation(settlement_id) if focus.is_empty() else GovernmentPeopleSystem.set_settlement_focus(settlement_id,focus)
	if not bool(result.get("ok",false)) and is_instance_valid(terrain) and terrain.has_method("_report_military_action"):terrain._report_military_action({"message":String(result.get("reason","That cannot be asked just now."))})
	hud.request_immediate_dock_refresh()

## Water and waste works need the place's own terrain reading (water sources,
## ground heights). The first settlement reads it from the map; later ones
## from their position.
func _works_context(settlement:Dictionary)->Dictionary:
	if not Works.relevant():return {}
	if bool(settlement.get("primary",false)) or String(settlement.get("id","")).is_empty():
		return terrain._discovery_context() if is_instance_valid(terrain) and terrain.has_method("_discovery_context") else {}
	return preload("res://scripts/civilization_day.gd").context(WorldSimulation.settlements._record_position(SettlementModel.settlement_record(String(settlement.id))))

func _works_data(context:Dictionary,city_id:String)->Dictionary:
	var offers:=Works.offers(context,city_id)
	var items:Array=[]
	for offer:Dictionary in offers:
		var press:Callable=offer.on_press
		var item:=offer.duplicate()
		if press.is_valid():
			item.on_press=func()->void:
				var result:Dictionary=press.call()
				var message:=String(result.get("message",result.get("error","")))
				if is_instance_valid(terrain) and terrain.has_method("_report_military_action") and not message.is_empty():terrain._report_military_action({"message":message})
				hud.request_immediate_dock_refresh()
		items.append(item)
	return {"progress":Works.progress_lines(),"offers":items}

func _people_report(kind:String)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _city_people_report(kind)))

func _city_people_report(kind:String)->Dictionary:
	var settlement:=_selected_settlement()
	var population:=maxi(1,int(settlement.get("population",GameState.population_total)))
	var share:=float(population)/maxf(1,GameState.population_total)
	var profile:Dictionary=CivilizationSystem.player_population_function_profile()
	var productive:=maxi(0,roundi(float(profile.get("productive",terrain._able_population()))*share))
	var management:=GovernmentPeopleSystem.settlement_management(String(settlement.get("id","")))
	var all:=_people_blocks(productive,population,share,settlement,management)
	if kind=="population":return {"blocks":[all[0],all[1]]}
	return {"blocks":[{"type":"text","text":"The local leader sets who does what each day. Asking for more hands on something moves some people to it; food and water still come first."},all[2]]}
