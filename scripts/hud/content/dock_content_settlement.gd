extends "res://scripts/hud/content/dock_content_base.gd"
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
## SETTLEMENT section: People & Labor / Works & Defense / History.
## Replaces the settlement dashboard, the settler side panel, and the
## population ledger summary.

const COHORT_LABELS:Array[Array]=[["children","0–13","Dependent cohort"],["youth","14–24","Productive-age cohort"],["early_adults","25–34","Productive-age cohort"],["established_adults","35–44","Productive-age cohort"],["mature_adults","45–59","Productive-age cohort"],["elders","60+","Dependent cohort; life expectancy is an average at birth, not a maximum age"]]
const ROLES:Array[Array]=[
	["Food","Sustenance","Produces food immediately. Heavy local gathering can exhaust the surrounding ecology."],
	["Survey","Survey","Creates clues, recognizes deposits, measures quality."],
	["Extraction","Gatherers","Works accessible timber, stone, clay, fiber, and later deposits."],
	["Construction","Builders","Causes needed communal works and access routes to emerge."],
	["Crafting","Makers","Improves tools and material capacity."],
	["Logistics","Carriers","Moves food and materials; determines whether distant resources are usable."],
	["Knowledge","Researchers","Aggregate research workforce; distribution across inquiry decides the path."],
	["Administration","Stewards","Coordinates labor and reserves; strengthens cohesion and legitimacy."],
	["Defense","Watch","Raises security and readiness; every watcher is absent from other work."],
]

func meta()->Dictionary:
	var settlement:=_selected_settlement()
	return {
		"eyebrow":"OWNED SETTLEMENT · %s" % String(settlement.get("classification","settlement")).to_upper(),
		"title":String(settlement.get("name",terrain._settlement_display_name())).capitalize(),
		"subtabs":["OVERVIEW","WORKS","HISTORY"],
	}

func tab(sub:int)->Dictionary:
	var settlement:=_selected_settlement()
	var settlement_id:=String(settlement.get("id",""))
	if settlement_id.is_empty() and sub==0:
		var committed:=GameState.settlement_site_committed
		var items:Array=[{"label":"FOOD & MATERIALS","sub":"Water access and current stores","on_press":jump("economy",0)}]
		if committed:items.append({"label":"FOUNDING WORK","sub":"Progress toward the Hearth Circle","on_press":jump("settlement",1)})
		else:items.push_front({"label":"FOUND SETTLEMENT","sub":"Commit the convoy’s present site","primary":true,"on_press":terrain._on_settlement_action_pressed})
		return {"brief":{"title":"A home is taking shape" if committed else "Choose a home for your people","why":"Unpause with the time controls above. The Hearth Circle emerges through ordinary work; local leadership and priorities become available once it is complete." if committed else "Move the convoy across known land and inspect nearby water. Founding commits its current location."},"blocks":[{"type":"actions","items":items}]}
	var local_population:=maxi(1,int(settlement.get("population",GameState.population_total)))
	var local_share:=float(local_population)/maxf(1.0,float(GameState.population_total))
	var management:=GovernmentPeopleSystem.settlement_management(settlement_id)
	var leader:Dictionary=management.get("leader",{})
	var metrics:Dictionary=GameState.simulation_metrics
	var profile:Dictionary=CivilizationSystem.player_population_function_profile()
	var health:=roundi(GameState.population_health*100.0)
	var productive:=maxi(0,roundi(float(profile.get("productive",terrain._able_population()))*local_share))
	var efficiency:=roundi(float(metrics.get("labor_efficiency",0.0))*100.0)
	var births:=roundi(float(metrics.get("births_expected_next_year",0.0))*local_share)
	var leader_name:=String(leader.get("name","vacant"))
	var leader_age:=int(leader.get("age",0))
	var focus_reason:=String(management.get("focus_reason","Local priorities have not yet been reassessed."))
	var focus_effect:=String(management.get("focus_effect","Labor remains spread across ordinary local needs."))
	var kpis:Array=[
		{"label":"LOCAL POP.","value":str(local_population),"delta":"+%d /yr" % births if births>0 else "—","delta_color":Tokens.GREEN if births>0 else Tokens.MUTED,"accent":Tokens.GREEN,"tip":"This settlement's bounded share of the civilization population"},
		{"label":"LOCAL LEADER","value":leader_name.substr(0,15),"delta":"age %d" % leader_age if not leader.is_empty() else "vacant","accent":Tokens.TEAL if not leader.is_empty() else Tokens.RED,"tip":"A named person who ages, gains experience, and manages local needs"},
		{"label":"FOCUS","value":String(management.get("focus_label","BALANCED")).replace(" THE PLACE","").substr(0,15),"delta":"delegated" if bool(management.get("auto_manage",true)) else "directed","accent":Tokens.BLUE,"tip":"%s %s" % [focus_reason,focus_effect]},
		{"label":"EFFICIENCY","value":"%d%%" % efficiency,"delta":"health %d%%" % health,"accent":Tokens.AMBER,"tip":"Civilization-wide labor efficiency; local leadership modifies access and support"},
	]
	var brief:Dictionary={"tone":"info" if not leader.is_empty() else "warn","title":"%s is managing %s" % [leader_name,String(settlement.get("name","this settlement"))] if not leader.is_empty() else "This settlement has no local leader","why":"WHY · %s\nEFFECT · %s" % [focus_reason,focus_effect] if not leader.is_empty() else "Appoint a person from the local governing pool so routine needs are handled without micromanagement."}
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":SettlementModel.with_city_resources(settlement_id,func()->Array: return _works_blocks(GameState.simulation_metrics,profile,settlement,management))}
		2: return {"kpis":kpis,"brief":brief,"blocks":_history_blocks(metrics,settlement)}
	return {"kpis":[kpis[0],kpis[2]],"brief":brief,"blocks":_overview_blocks(settlement)}


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
	var dependency:=float(dependents)/maxf(1.0,float(local_population-dependents))
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
			"color":Tokens.ROLE_COLORS[index],"tip":"Delegated local share. "+String(role[2]),
		})
	var settlement_id:=String(settlement.get("id",""))
	var blocks:Array=[
		Charts.population(settlement_id,true),
		{"type":"segments","heading":"AGE STRUCTURE","note":"dependency %.2f" % dependency,"items":segment_items,"legend":"Green = productive-age • warm/grey = dependent • life expectancy is not a maximum age"},
		{"type":"alloc","heading":"DELEGATED LOCAL LABOR","note":"about %d of %d productive" % [assigned,productive],"items":alloc_items},
		{"type":"actions","items":[
			{"label":"LOCAL LEADERSHIP","sub":"appoint from named people","primary":true,"on_press":func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_settlement_people.gd").new(terrain,hud,settlement_id)),"tip":"Review the real people available to lead this settlement."},
			{"label":"RENAME SETTLEMENT","sub":"change its map name","on_press":terrain._open_settlement_naming_panel.bind(settlement_id),"tip":"Give this place the name used on the map and in history."},
		]},
	]
	var auto_manage:=bool(management.get("auto_manage",true))
	var selected_focus:=String(management.get("focus","balanced"))
	blocks.append({"type":"actions","heading":"OVERRIDE LOCAL PRIORITY","items":[
		{"label":"AUTO","sub":"leader decides","primary":auto_manage,"on_press":_restore_local_delegation.bind(settlement_id),"tip":"Return routine priorities to the local leader."},
		{"label":"WATER","sub":"selected · directed" if not auto_manage and selected_focus=="water" else "access and carrying","primary":not auto_manage and selected_focus=="water","on_press":_set_local_focus.bind(settlement_id,"water"),"tip":"Direct extra labor toward finding water, improving access, and carrying it reliably."},
		{"label":"PROVISIONS","sub":"selected · directed" if not auto_manage and selected_focus=="provisions" else "food and carrying","primary":not auto_manage and selected_focus=="provisions","on_press":_set_local_focus.bind(settlement_id,"provisions"),"tip":"Temporarily direct this place toward provisions."},
		{"label":"SHELTER","sub":"selected · directed" if not auto_manage and selected_focus=="shelter" else "building and materials","primary":not auto_manage and selected_focus=="shelter","on_press":_set_local_focus.bind(settlement_id,"shelter"),"tip":"Temporarily direct this place toward housing and construction."},
		{"label":"DEVELOP","sub":"selected · directed" if not auto_manage and selected_focus=="development" else "craft and capacity","primary":not auto_manage and selected_focus=="development","on_press":_set_local_focus.bind(settlement_id,"development"),"tip":"Temporarily direct this place toward productive development."},
		{"label":"RESEARCH","sub":"selected · directed" if not auto_manage and selected_focus=="research" else "knowledge and survey","primary":not auto_manage and selected_focus=="research","on_press":_set_local_focus.bind(settlement_id,"research"),"tip":"Direct discretionary labor toward research and observation. The leader still protects essential food and water."},
		{"label":"DEFENSE","sub":"selected · directed" if not auto_manage and selected_focus=="defense" else "watch and readiness","primary":not auto_manage and selected_focus=="defense","on_press":_set_local_focus.bind(settlement_id,"defense"),"tip":"Temporarily direct this place toward defense."},
	]})
	return blocks


func _set_local_focus(settlement_id:String,focus:String)->void:
	GovernmentPeopleSystem.set_settlement_focus(settlement_id,focus)
	hud.request_immediate_dock_refresh()


func _restore_local_delegation(settlement_id:String)->void:
	GovernmentPeopleSystem.restore_delegation(settlement_id)
	hud.request_immediate_dock_refresh()

func _works_blocks(metrics:Dictionary,profile:Dictionary,settlement:Dictionary,management:Dictionary)->Array:
	GameState.ensure_building_ledger()
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	var housing:=roundi(float(GameState.housing_capacity)/maxf(1.0,float(settlement.get("population",1)))*100.0)
	var builders:=roundi(float((management.get("allocations",{}) as Dictionary).get("Construction",0.0))/100.0*float(profile.get("productive",terrain._able_population()))*float(settlement.get("population",1))/maxf(1.0,float(GameState.population_total)))
	var works:=GameState.settlement_completed.size()
	var local_share:=float(settlement.get("population",1))/maxf(1.0,float(GameState.population_total))
	var absent:=roundi(float(profile.get("absent",0))*local_share)
	var mobilized:=roundi(float(profile.get("mobilized",0))*local_share)
	var works_text:="No permanent works have emerged. Builders create shelter and access routes as need accumulates; nothing is placed by hand."
	if works>0:
		works_text="Completed works: %s." % ", ".join(GameState.settlement_completed)
	works_text+="\n\nSHELTER WORK · %s" % String(SettlementModel.with_local_population(terrain._shelter_work_status))
	var building_summary:=GameState.building_ledger_summary(String(settlement.get("id","")))
	var materials:Dictionary=building_summary.get("materials",{})
	if not materials.is_empty(): works_text+="\n\nMATERIALS USED ACROSS HISTORY · %s" % _material_totals_text(materials)
	return [
		{"type":"tiles","heading":"LOCAL CONDITION","items":[
			{"label":"HOUSING","value":"%d%%" % housing,"note":"Shelter covers everyone" if housing>=100 else "Shelter is short","note_color":Tokens.GREEN if housing>=100 else Tokens.RED,"tip":"Share of the population with shelter"},
			{"label":"DEFENSE","value":String(defense.get("short","Open ground")),"note":"integrity %d%% · lookout %.0f km" % [roundi(float(defense.get("integrity",0.0))*100.0),float(defense.get("observation_radius_km",0.0))],"note_color":Tokens.RED if float(defense.get("integrity",0.0))<0.4 else Tokens.MUTED,"tip":String(defense.get("description",""))},
			{"label":"CONSTRUCTION","value":"%d builders" % builders,"note":"%d works completed" % works,"note_color":Tokens.MUTED,"tip":"Assigned Builders and emerged communal works"},
			{"label":"COMMITMENTS","value":"%d away" % absent,"note":"%d mobilized" % mobilized,"note_color":Tokens.MUTED,"tip":"People physically away on missions or under arms"},
		]},
		{"type":"text","heading":"EMERGING WORKS","text":works_text},
		{"type":"text","heading":"LOCAL GOVERNANCE","text":"%s · %s. Leadership competence changes work, travel, water access, and administrative support; it does not create resources or ignore physical limits." % [String(management.get("leader_title","Local leader")),String(management.get("focus_label","balanced stewardship")).capitalize()]},
		{"type":"actions","items":[{
			"label":"BUILDING RECORD","sub":"materials, kinds, damage, rebuilding","primary":true,
			"on_press":func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,String(settlement.get("id","")))),
			"tip":"Inspect the complete architectural history of this settlement without losing older records.",
		}]},
	]


func _material_totals_text(materials:Dictionary)->String:
	var names:=materials.keys()
	names.sort_custom(func(a:Variant,b:Variant)->bool: return float(materials[a])>float(materials[b]))
	var parts:Array[String]=[]
	for material_name in names:
		parts.append("%s %.1f" % [String(material_name),float(materials[material_name])])
	return " · ".join(parts)

func _history_blocks(metrics:Dictionary,settlement:Dictionary)->Array:
	var pregnancy:Dictionary=GameState.pregnancy_summary()
	var births:=GameState.lifetime_births
	var deaths:=GameState.lifetime_deaths
	var net:=births-deaths
	var chronicle_items:Array=[]
	var log:Array=GameState.discovery_log
	for index in range(log.size()-1,maxi(-1,log.size()-4),-1):
		var event:Dictionary=log[index]
		chronicle_items.append({
			"name":String(event.get("name",event.get("title","Event"))),
			"sub":"Day %d" % int(event.get("day",0)),
			"value":"","accent":Tokens.AMBER,
			"tip":String(event.get("causal_mechanism","")),
		})
	var founded_day:=int(settlement.get("founded_day",0))
	var leader:Dictionary=GovernmentPeopleSystem.settlement_leader(String(settlement.get("id","")))
	var blocks:Array=[
		{"type":"tiles","heading":"SINCE FOUNDING","items":[
			{"label":"BIRTHS","value":str(births),"note":"%d pregnancies active" % int(pregnancy.get("active",0)),"note_color":Tokens.GREEN,"tip":"Total births since the expedition began"},
			{"label":"DEATHS","value":str(deaths),"note":"all causes","note_color":Tokens.RED if deaths>0 else Tokens.MUTED,"tip":"Total deaths since the expedition began"},
			{"label":"NET","value":"%+d" % net,"note":"births − deaths","note_color":Tokens.GREEN if net>=0 else Tokens.RED,"tip":"Natural change since founding"},
			{"label":"LIFE EXPECT.","value":"%.1f y" % GameState.projected_life_expectancy(),"note":"projected at birth","note_color":Tokens.MUTED,"tip":"Average years a newborn would live if current age-specific risks persisted; this is not a maximum age"},
		]},
		{"type":"text","heading":"PLACE RECORD","text":"%s was founded on day %d. Current local leader: %s, %s." % [String(settlement.get("name","This settlement")),founded_day,String(leader.get("name","vacant")),String(leader.get("title","no office assigned")).to_lower()]},
	]
	if not chronicle_items.is_empty():
		blocks.append({"type":"rows","heading":"CHRONICLE","items":chronicle_items})
	else:
		blocks.append({"type":"text","heading":"CHRONICLE","text":"Nothing notable has been recorded yet. Events accumulate here as the settlement lives."})
	blocks.append({"type":"actions","items":[{
		"label":"FULL LEDGER","sub":"births, deaths, causes, maternity","primary":true,
		"on_press":func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(terrain,hud)),
		"tip":"Open the complete population record beside this panel",
	}]})
	return blocks

func signature()->Array:
	return [GameState.strategic_history.get("last_day",-1),GameState.selected_player_settlement_id,GameState.settlement_network_revision,GovernmentPeopleSystem.revision,GameState.population_total,GameState.population_health,GameState.housing_capacity,float(GameState.simulation_metrics.get("housing_ratio",-1.0)),GameState.population_allocations.duplicate(),GameState.lifetime_births,GameState.lifetime_deaths,GameState.settlement_completed.size(),GameState.building_ledger.size()]

func _overview_blocks(settlement:Dictionary)->Array:
	var id:=String(settlement.get("id",""))
	return [
		{"type":"text","heading":"YOUR ROLE","text":"Choose this place’s direction. Its local leader assigns routine work; you do not need to distribute every worker. Buildings emerge from needs, labor and available materials."},
		{"type":"actions","heading":"SHAPE THIS PLACE","items":[
			{"label":"LOCAL LEADERSHIP","sub":"Choose who manages the settlement","primary":true,"on_press":func()->void:hud.open_detail(preload("res://scripts/hud/content/dock_detail_settlement_people.gd").new(terrain,hud,id))},
			focused_action("LOCAL PRIORITY","Let the leader decide, or give a direction",_people_report.bind("priority"))]},
		{"type":"actions","heading":"UNDERSTAND YOUR SETTLEMENT","items":[
			focused_action("POPULATION","Growth and age groups",_people_report.bind("population")),
			focused_action("DAILY WORK","Who works where, and why",_people_report.bind("work")),
			{"label":"FOOD & MATERIALS","sub":"Reserves, sources and constraints","on_press":jump("economy",0)},
			{"label":"RENAME","sub":"Change this place’s map name","on_press":terrain._open_settlement_naming_panel.bind(id)}]}]

func _people_report(kind:String)->Dictionary:
	var settlement:=_selected_settlement()
	var population:=maxi(1,int(settlement.get("population",GameState.population_total)))
	var share:=float(population)/maxf(1,GameState.population_total)
	var profile:Dictionary=CivilizationSystem.player_population_function_profile()
	var productive:=maxi(0,roundi(float(profile.get("productive",terrain._able_population()))*share))
	var management:=GovernmentPeopleSystem.settlement_management(String(settlement.get("id","")))
	var all:=_people_blocks(productive,population,share,settlement,management)
	match kind:
		"population":return {"blocks":[all[0],all[1]]}
		"work":return {"blocks":[{"type":"text","text":"These are the local leader’s current assignments. Change the settlement priority to influence the mix; essential needs still limit how much labor can move."},all[2]]}
	var auto:=bool(management.get("auto_manage",true))
	return {"brief":{"title":"Leader chooses priorities" if auto else "Current direction: "+String(management.get("focus_label","Balanced")),"why":String(management.get("focus_reason",""))+" "+String(management.get("focus_effect",""))},"blocks":[{"type":"text","text":"Choose a direction below. It takes effect through the leader’s labor allocation as the simulation advances. Auto returns the choice to the leader."},all[4]]}
