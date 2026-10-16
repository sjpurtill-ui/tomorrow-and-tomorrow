extends "res://scripts/hud/content/dock_content_base.gd"
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Works:=preload("res://scripts/hud/water_conveyance_controls.gd")
const Model:=preload("res://scripts/hud/own_town_model.gd")
const Lives:=preload("res://scripts/hud/home_lives_model.gd")
## SETTLEMENT section: our town's own page (Overview) and its History.
## The active overview reads guarded local living conditions and civilization
## context through HomeLives. Existing leadership and work commands remain
## explicit actions. Archived folio/model helpers below have no production call.

const COHORT_LABELS:Array[Array]=[["children","0–13","Children, not yet working"],["youth","14–24","Young people of working age"],["early_adults","25–34","Adults of working age"],["established_adults","35–44","Adults of working age"],["mature_adults","45–59","Older adults, still working"],["elders","60+","Elders, mostly past heavy work. How long people live is an average from birth, not a limit."]]
## Who sets the daily work (manual_work.gd). Who does what is The People's
## to show and set; this page says who sets it and hands it back.
const Manual:=preload("res://scripts/manual_work.gd")
const Memo:=preload("res://scripts/hud/content/dock_memo.gd")
## Costly parts of the page, kept while what they are made from holds.
var memo:=Memo.new()

func meta()->Dictionary:
	var settlement:=_selected_settlement()
	return {
		"eyebrow":"Your %s" % String(settlement.get("classification","settlement")).to_lower(),
		"title":String(settlement.get("name",GameState.settlement_name)).capitalize(),
		"subtabs":["Overview"],
		"spatial_view":not String(settlement.get("id","")).is_empty(),
	}

func tab(sub:int)->Dictionary:
	# The illustrated overview consumes Lives' guarded local/realm readings.
	# Do not also compute the superseded comparison tables and KPI dashboard.
	var page:Dictionary=_city_tab(sub)
	# The new overview owns its scopes: local living conditions alongside
	# civilization-wide learning, values and standing. Read after restoring the
	# outer town scope so national measures cannot accidentally use local people.
	for block:Dictionary in page.get("blocks",[]):
		if String(block.get("type",""))!="settlement_overview":continue
		var city_id:=String(GameState.selected_player_settlement_id)
		block["lives"]=Lives.snapshot(city_id)
		block["compare_care"]=Lives.compare_care.bind(city_id,5)
		block["on_health"]=func()->void:hud.open_detail(preload("res://scripts/hud/content/dock_detail_health.gd").new(terrain,hud),0)
		block["on_assign_care"]=assign_workers("Administration")
		block["on_research"]=jump("inquiry",0)
		block["on_culture"]=jump("civ",0)
		block["on_food"]=jump("economy",0)
		block["on_works"]=jump("construction",0)
	return page

var _founding:Dictionary={}
var _strength:Dictionary={}
var _towns:Array=[]

## How the seat grows (one_seat.gd): one seat that spreads outward into
## districts, then a county, a state and a country, with the numbers that
## take it to its next stage; and the places its families have settled
## (settlement_places.gd), each with its people and its water.
func founding_block()->Dictionary:
	var OneSeat:=preload("res://scripts/one_seat.gd")
	var Places:=preload("res://scripts/settlement_places.gd")
	# One table: the seat's stage toward the next (people and districts, with
	# a bar), then the seat and every place its families settled, one line each.
	var s:=OneSeat.stage()
	var next:Dictionary=s.next
	var stage_cells:={"place":String(s.name),"where":"%d %s" % [int(s.districts),"district" if int(s.districts)==1 else "districts"],"people":EraWords.grouped(int(s.people))}
	var stage_row:={"icon":preload("res://scripts/resource_icons.gd").domain_texture("demography",Tokens.GOLD),"cells":stage_cells,
		"tip":OneSeat.stage_words()+" "+OneSeat.NO_NEW_TOWNS}
	if not next.is_empty():
		stage_row["bar"]={"value":minf(float(s.people)/maxf(1.0,float(next.people)),float(s.districts)/maxf(1.0,float(next.districts)))}
		stage_row["tag"]={"text":"%s at %s" % [String(next.name).to_lower(),EraWords.grouped(int(next.people))],"tone":""}
	var rows:Array=[stage_row,{"icon":preload("res://scripts/resource_icons.gd").domain_texture("infrastructure",Tokens.INK),"cells":{"place":"The seat","where":"","people":EraWords.grouped(Places.seat_people())}}]
	var today:=int(GameState.elapsed_days)
	# Places alike (the same site, the same number of people, the same way)
	# are one line: "10 villages · on the sea shore · 1,606 each", their names
	# in its pointer. A place that differs keeps its own line.
	var alike:={}
	var order:Array=[]
	for place:Dictionary in Places.list():
		var trend:=float(place.get("target",0.0))-float(place.get("share",0.0))
		var way:="growing" if trend>0.0005 else ("shrinking" if trend<-0.0005 else "steady")
		if today<int(place.get("setback_until",-1)):way="rebuilding"
		var key:=[String(place.get("kind","")),Places.people(place),way]
		var id:=str(key)
		if not alike.has(id):alike[id]={"key":key,"names":[]};order.append(id)
		(alike[id].names as Array).append(String(place.get("name","")))
	for id in order:
		var group:Dictionary=alike[id]
		var names:Array=group.names
		var way:=String(group.key[2])
		var tone:="good" if way=="growing" else ("warn" if way=="shrinking" else ("bad" if way=="rebuilding" else ""))
		var one:=names.size()==1
		var where:=Places.site_words(String(group.key[0]))
		var people:=EraWords.grouped(int(group.key[1]))
		rows.append({"icon":preload("res://scripts/resource_icons.gd").domain_texture("ecology",Tokens.TEAL),
			"cells":{"place":String(names[0]) if one else "%d villages" % names.size(),"where":where,"people":people if one else "%s each" % people},
			"tag":{"text":way,"tone":tone},"tip":"" if one else ", ".join(PackedStringArray(names))+"."})
	return {"type":"table","heading":"Where our people live","columns":[{"key":"place","label":"Place"},{"key":"where","label":"Where","width":150},{"key":"people","label":"People","width":96,"align":"right"}],"rows":rows}

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
	var blocks:=_overview_blocks(settlement)
	return {"blocks":blocks}


## Home at a glance, right under the tabs: four numbers with bars, each from
## the figure's own source (the town's rows in own_town_model.gd, the top
## bar's words in era_words.gd, the War screen's army), each a click to its page.
## Home's strip: only figures the top bar does not carry (it has the head
## count, food, water and life span): the year's growth, homes, the people's
## mood and the army.
func _glance_tiles(settlement:Dictionary)->Array:
	var facts:=Model.facts(settlement,_strength)
	var people:=int(facts.population)
	var tiles:Array=[]
	# Growth: the year's change so far (the Chronicle's own figure:
	# chronicle_annals.gd people_this_year), amber when falling; pressed, the
	# town's ages and families.
	var year:Dictionary=preload("res://scripts/chronicle_annals.gd").people_this_year(GameState.chronicle,int(GameState.population_total))
	var growth:={"label":"GROWTH","value":"no change","glance":true,"delta":"this year","tip":"The change in our numbers this year so far. Pressed: ages and families.","on_press":focused_action("Ages and families","",_people_report.bind("population")).on_press}
	if not year.is_empty():
		var change:=int(year.change)
		growth["value"]="no change" if change==0 else "%s%s" % ["+" if change>0 else "−",EraWords.grouped(absi(change))]
		growth["delta"]="%s born · %s buried" % [EraWords.grouped(int(year.born)),EraWords.grouped(int(year.buried))]
		growth["delta_color"]=Tokens.AMBER if change<0 else Tokens.MUTED
		growth["tip"]="Population change compares today's count with the year-start count. Births and burials use completed seasonal reports and do not reconcile that change. Pressed: ages and families."
	tiles.append(growth)
	# Homes: how full the houses are.
	var places:=int(facts.places)
	var outside:=maxi(0,people-places)
	tiles.append({"label":"HOMES","value":EraWords.grouped(places),"glance":true,"meter":float(people)/float(maxi(1,places)),"meter_color":Tokens.RED if outside>0 else (Tokens.AMBER if people>=places*0.95 else Tokens.GREEN),
		"delta":"%s sleep out" % EraWords.grouped(outside) if outside>0 else "%d%% full" % roundi(float(people)/float(maxi(1,places))*100.0),"delta_color":Tokens.RED if outside>0 else Tokens.MUTED,
		"tip":"Room under a roof for %s; %s live here. The bar is how full the houses are." % [EraWords.grouped(places),EraWords.grouped(people)],"on_press":jump("construction",0)})
	# Mood: the people's spirit, the People page's own reading (people_model.gd).
	var Overview:=preload("res://scripts/hud/civilization_overview_model.gd")
	for vital:Dictionary in preload("res://scripts/hud/people_model.gd").vitals(Overview.snapshot(),preload("res://scripts/hud/civilization_kpi_model.gd").snapshot()):
		if String(vital.get("id",""))!="spirit":continue
		var fill:=float(vital.get("fill",0.0))
		var cause:=String(vital.get("cause",""))
		tiles.append({"label":"MOOD","value":String(vital.value),"glance":true,"meter":fill,"meter_color":Tokens.GREEN if fill>=0.6 else (Tokens.AMBER if fill>=0.35 else Tokens.RED),
			"delta":("trust: "+cause.get_slice(": ",1).trim_suffix(".")) if cause.contains(": ") else "","tip":cause,"on_press":jump("overview",0)})
	# The army: the War screen's own count and its gear in hand.
	var WarBoard:GDScript=load("res://scripts/hud/war_board.gd")
	var serving:=int(preload("res://scripts/army_levy_law.gd").reading(MilitaryCampaign).now)
	var armed:=float((WarBoard.call("strength",MilitaryCampaign) as Dictionary).get("armed",0.0))
	tiles.append({"label":"ARMY","value":EraWords.grouped(serving),"glance":true,"meter":armed if serving>0 else 0.0,"meter_color":Tokens.GREEN if armed>=0.999 else Tokens.AMBER,
		"delta":"%d%% armed" % roundi(armed*100.0) if serving>0 else "no one serves","tip":"Everyone in the army. The bar is the share of their gear in hand.","on_press":jump("military",0)})
	return tiles


func _selected_settlement()->Dictionary:
	# selected_settlement_snapshot() seeds records and changes the selection.
	# A screen only reads the existing selection, with a local primary fallback.
	var record:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	if record.is_empty():
		for city:Dictionary in GameState.player_settlements:
			if bool(city.get("primary",false)):record=city;break
	if record.is_empty():return {"id":"","name":GameState.settlement_name,"classification":"settlement","population":GameState.population_total,"primary":true}
	var out:=record.duplicate(true)
	out["population"]=roundi(SettlementModel._settlement_population(record))
	out["classification"]=String(record.get("classification",GameState.settlement_morphology.get("classification","settlement") if bool(record.get("primary",false)) else "settlement"))
	return out

func _people_blocks(_productive:int,local_population:int,local_share:float,settlement:Dictionary,_management:Dictionary)->Array:
	var cohorts:Dictionary=GameState._integer_age_cohorts()
	var segment_items:Array=[]
	var dependents:=0
	for entry in COHORT_LABELS:
		var count:=roundi(float(cohorts.get(String(entry[0]),0))*local_share)
		if String(entry[0]) in ["children","elders"]: dependents+=count
		segment_items.append({"label":String(entry[1]),"value":str(count),"share":maxf(0.5,float(count)),"color":Tokens.COHORT_COLORS[COHORT_LABELS.find(entry)],"tip":String(entry[2])})
	var settlement_id:=String(settlement.get("id",""))
	var blocks:Array=[
		Charts.population(settlement_id,true),
		{"type":"segments","heading":"Ages","note":preload("res://scripts/hud/home_plain.gd").dependency(dependents,local_population-dependents),"items":segment_items,"legend":"Green bands are people of working age; the others are children and elders."},
		{"type":"actions","items":[
			{"label":"Talk with the leader","sub":"In the court: ask, order or replace","primary":true,"on_press":court({"settlement_id":settlement_id}),"tip":"The government appoints local leaders. Call this one to the court to talk, give orders or replace them."},
			{"label":"Rename this place","sub":"The name on the map","on_press":terrain._open_settlement_naming_panel.bind(settlement_id),"tip":"Give this place the name used on the map and in history."},
		]},
	]
	return blocks


func signature()->Array:
	# Raw receipts only: no city-form seeding, health recalculation, government
	# initialization or scope swaps merely to decide whether a view must refresh.
	# Exact hashes retain same-day paused edits to research, culture and standing.
	return [int(GameState.elapsed_days),GameState.world_seed,GameState.selected_player_settlement_id,GameState.player_settlements.hash(),GameState.population_total,
		GameState.population_health,GameState.housing_capacity,GameState.population_allocations.hash(),GameState.simulation_metrics.hash(),GameState.water_metrics.hash(),GameState.food_stocks.hash(),
		GameState.resource_stockpiles.hash(),GameState.early_care.hash(),GameState.built_fabric.hash(),GameState.city_form.hash(),GameState.strategic_history.hash(),GameState.vital_statistics_history.hash(),
		GameState.active_investigations.hash(),GameState.discovery_progress.hash(),GameState.discovery_adoption.hash(),GameState.known_discoveries.hash(),GameState.societal_values.hash(),
		PeopleDirection.ambition,PeopleDirection.cultural_memory.hash(),PeopleDirection.automatic_work,PeopleDirection.work_baseline.hash(),GovernmentPeopleSystem.revision,
		MilitaryCampaign.home_army.hash(),MilitaryCampaign.settlement_defense.hash(),GameState.water_waste_works.hash(),GameState.water_conveyance.hash(),GameState.settlement_projects.hash(),GameState.settlement_completed.hash()]

func _city_signature()->Array:
	var metrics:Dictionary=GameState.simulation_metrics
	return [GameState.population_total,GameState.population_health,GameState.housing_capacity,float(metrics.get("housing_ratio",-1.0)),GameState.population_allocations.duplicate(),GameState.lifetime_births,GameState.lifetime_deaths,
		GameState.settlement_completed.size(),GameState.settlement_projects.hash(),GameState.building_ledger.size(),snappedf(float(metrics.get("food_days",-1.0)),0.5),signf(float(metrics.get("food_net",0.0))),
		roundi(float(GameState.water_metrics.get("intake_ratio",-1.0))*100.0),GameState.water_waste_works.get("works",[]).hash(),GameState.water_conveyance.get("lines",[]).size(),snappedf(ResourceSystem.stored_bulk(),1.0),
		roundi(float(SettlementModel.city_form().get("condition",1.0))*100.0),roundi(float(metrics.get("material_capacity",0.0))*100.0),roundi(float(metrics.get("logistics",0.0))*100.0),
		roundi(GameState.projected_life_expectancy()*10.0),roundi(Indicators.infant_mortality_per_1000()),roundi(Indicators.science().minds),GameState.settlement_plots.size(),GameState.morphology_revision]

## The foreign towns our scouts have brought home, and when.
static func _known_signature()->int:
	var intel=CivilizationSystem.city_intelligence
	if intel==null:return 0
	var book:Dictionary=intel.records.get("player",{})
	var total:=book.size()
	for id in book:total=(total*31+int((book[id] as Dictionary).get("reported_day",0)))%2147483647
	return total

## What the local leader is putting extra hands on, as a short phrase.
const FOCUS_WORDS:={"water":"water","provisions":"food","shelter":"shelter","research":"learning","defense":"the watch","logistics":"carrying and paths","development":"building up the place","establishment":"setting the place up","balanced":"everyday needs"}
## The choices offered on the Settlement dock, in the order shown.
const ASKABLE:=["water","provisions","shelter","research","defense"]
## The town's figures that stand as tiles under the tabs (_glance_tiles),
## and the scholars, which the top bar counts: no row restates them.
const IN_TILES:=["population","life_expectancy","supply","water","roofs","learning"]

func _overview_blocks(settlement:Dictionary)->Array:
	var id:=String(settlement.get("id",""))
	var management:=_management_reading(settlement)
	var leader:Dictionary=management.get("leader",{})
	var leader_name:=String(leader.get("name","")).get_slice(" ",0)
	var focus:=String(management.get("focus","balanced"))
	var managed:=bool(management.get("auto_manage",true))
	var holder:=String(SettlementModel.settlement_record(id).get("occupied_by",""))
	var occupied:=not holder.is_empty()
	# What the leader is doing, short; the reason is in the tooltip.
	var direction:=""
	var direction_tip:=""
	var ruler:=not PeopleDirection.automatic_work
	if management.is_empty():direction="No one runs this place's daily work yet."
	elif ruler:
		direction="You set the daily work for all our towns."
		direction_tip=Manual.RULER_TIP
	elif managed:
		direction="%s chooses the daily work: more hands on %s." % [leader_name if not leader_name.is_empty() else "The local leader",String(FOCUS_WORDS.get(focus,"everyday needs"))]
		direction_tip=String(management.get("focus_reason",""))
	else:
		direction="You asked %s for more hands on %s." % [leader_name if not leader_name.is_empty() else "the local leader",String(FOCUS_WORDS.get(focus,focus))]
		direction_tip=String(management.get("focus_effect",""))
	# The leader's own hand on the town's work, in the engine's numbers
	# (office_levers.gd town_labour: the labour lever, x0.95 to x1.06).
	if not leader.is_empty() and not occupied:
		var hand:=preload("res://scripts/office_levers.gd").town_labour(leader)
		var size:=roundi(absf(hand-1.0)*100.0)
		direction_tip=(direction_tip+"\n" if direction_tip!="" else "")+("Under %s this town gets %d%% %s work done than under an ordinary leader." % [leader_name,size,"more" if hand>=1.0 else "less"] if size>0 else "%s runs the town's work as an ordinary leader would." % leader_name)
	var choices:Array=[]
	for key:String in ASKABLE:
		choices.append({"id":key,"label":String(FOCUS_WORDS[key]).capitalize(),"tip":String(GovernmentPeopleSystem.FOCUS_EFFECTS.get(key,""))+" Other work slows.","on_press":_ask_for_hands.bind(id,key)})
	choices.append({"id":"","label":"Let %s decide" % (leader_name if not leader_name.is_empty() else "the leader"),"tip":"The leader spreads the work across what the place needs.","on_press":_ask_for_hands.bind(id,"")})
	var local:=_local_metadata(settlement,ruler and not management.is_empty() and not occupied)
	var on_population:Callable=focused_action("Ages and families","",_people_report.bind("population")).on_press
	# The ruler's split, read for this town: what it does to the stores here,
	# early and plainly, with the one click that mends it (manual_work.gd).
	var warning:Dictionary=local.warning
	var on_rename:Callable=terrain._open_settlement_naming_panel.bind(id) if is_instance_valid(terrain) and terrain.has_method("_open_settlement_naming_panel") else Callable()
	# The verbs stand on the lines they change: rename on the place's own
	# line, visit on the seat's.
	return [{"type":"settlement_overview","leader":leader,"managed":managed,"direction":direction,"direction_tip":direction_tip,
		"can_direct":not management.is_empty() and not occupied,"choices":choices,"current":"" if managed else focus,
		"ruler_sets_work":ruler and not management.is_empty() and not occupied,"on_leaders":_work_to_leaders,"on_people":jump("overview",0),
		"work_warning":warning,"on_food_fix":_put_on_food.bind(int(warning.get("fix",0))) if int(warning.get("fix",0))>0 else Callable(),
		# Compatibility metadata; the active Lives renderer owns its illustration.
		"town_name":String(settlement.get("name","")),"sketch":{},"on_visit":_visit_village,"lead":"",
		"groups":[],"tile_rows":{},"legend":[],
		"works":local.works,
		"founding":{},
		"places":{},
		"on_leader":court({"settlement_id":String(id)}),
		"on_population":on_population,
		"on_rename":on_rename}]

func _management_reading(settlement:Dictionary)->Dictionary:
	# The old accessor initializes/reconciles the government, including new
	# people and offices. Read only the official who is already in the ledger.
	if String(settlement.get("id",""))=="":return {}
	var person:=GovernmentPeopleSystem._person_record(int(settlement.get("leader_person_id",0))).duplicate(true)
	if not person.is_empty():
		person["age"]=GovernmentPeopleSystem.age_years(person)
		person["title"]=GovernmentPeopleSystem.settlement_leader_title()
		person["appearance_civ_id"]=WorldSimulation.actor_id
		person["appearance_world_seed"]=GameState.world_seed
	return {"leader":person,"focus":String(settlement.get("management_focus","balanced")),"auto_manage":bool(settlement.get("auto_manage",true)),
		"focus_reason":String(settlement.get("management_focus_reason","Local priorities have not yet been reassessed.")),"focus_effect":String(settlement.get("management_focus_effect",""))}

func _local_metadata(settlement:Dictionary,read_warning:bool)->Dictionary:
	var empty:={"works":{},"warning":{}}
	if not PeopleDirection.initialized or PeopleDirection.seed_value!=GameState.world_seed or not DiscoverySystem.initialized:return empty
	# Scope helpers seed older city defaults; geographic context expires old
	# observations. Both are useful simulation behavior, but not a view write.
	var saved:={}
	for field:String in ["player_settlements","population_cohorts","pregnancy_cohorts","population_total","population_exact","built_fabric","fabric_realm","city_form","early_care","early_care_blend","society_exchange","border_forts","simulation_events","field_observation_signals"]:
		var value:Variant=GameState.get(field);saved[field]=value
		if value is Dictionary or value is Array:GameState.set(field,value.duplicate(true))
	var national:=SettlementModel._national_population_in_scope
	var fraction:=SettlementModel._national_civilian_workforce_fraction
	var id:=String(settlement.get("id",""))
	var result:Dictionary=SettlementModel.with_city_resources(id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:
		var context:=_works_context(settlement)
		return {"works":_works_data(context,"" if bool(settlement.get("primary",false)) else id) if not context.is_empty() else {},"warning":Manual.town_warning(id) if read_warning else {}}))
	for field:String in saved:GameState.set(field,saved[field])
	SettlementModel._national_population_in_scope=national
	SettlementModel._national_civilian_workforce_fraction=fraction
	return result

func _visit_village()->void:
	if is_instance_valid(hud) and hud.has_method("close_dock"):hud.close_dock()

static func _since(days:int)->String:
	return Model.since(days)

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

## The town's own ages and families. Who does what is The People's to show
## and set (manual_work.gd), not a second screen here.
func _people_report(kind:String)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _city_people_report(kind)))

func _city_people_report(_kind:String)->Dictionary:
	var settlement:=_selected_settlement()
	var population:=maxi(1,int(settlement.get("population",GameState.population_total)))
	var share:=float(population)/maxf(1,GameState.population_total)
	var all:=_people_blocks(0,population,share,settlement,{})
	return {"blocks":[all[0],all[1]]}

## The warning's one click: that many more people on getting food, each
## from the task with the most (manual_work.move), in every town.
func _put_on_food(people:int)->void:
	var moved:=Manual.move("Food",people)
	if is_instance_valid(terrain) and terrain.has_method("_report_military_action") and bool(moved.get("ok",false)):
		terrain._report_military_action({"message":"%d more now get food in every town, from %s." % [int(moved.moved),Manual.moved_words(moved.from)]})
	if is_instance_valid(hud) and hud.has_method("request_immediate_dock_refresh"):hud.request_immediate_dock_refresh()

## "Back to our leaders": each town's leader shares out the work again.
func _work_to_leaders()->void:
	Manual.set_manual(false)
	if is_instance_valid(hud) and hud.has_method("request_immediate_dock_refresh"):hud.request_immediate_dock_refresh()
