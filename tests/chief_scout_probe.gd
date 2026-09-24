extends Node
## Headless probe for the Chief Scout office and debrief: the office exists in
## every government form, can be appointed and succeeded; returned records
## become supported facts; offline debriefs speak only about those facts; and a
## real scout return requests an audience in the hall.
const SCOUT=preload("res://scripts/chief_scout.gd")
const HALL=preload("res://scripts/audience_hall.gd")
const SEED:=424242
var failures:Array[String]=[]

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _setup()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world(); CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(200); GameState.housing_capacity=260
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":45.0,"food_intake_ratio":1.0,"material_capacity":0.30},true)
	GameState.elapsed_days=120.0
	GovernmentPeopleSystem.initialize()

func _field(low:float,high:float,day:int,quality:float,days:int=1)->Dictionary:
	return {"low":low,"high":high,"observed_low":low,"observed_high":high,"observed_day":day,"reported_day":day+4,"quality":quality,"source":"physical reconnaissance","reference":"scout:7","observation_days":days,"age_days":4,"stale":false}

func _city(civ_id:String,name:String,day:int,quality:float,fields:Dictionary,days:int=1)->Dictionary:
	return {"city_id":"%s_r0" % civ_id,"civ_id":civ_id,"name":name,"position":{"x":40.0,"z":-12.0},"controller":civ_id,"observed_day":day,"reported_day":day+4,"quality":quality,"source":"physical reconnaissance","reference":"scout:7","observation_days":days,"fields":fields,"age_days":4,"freshness":"recent"}

func _report(extra:Dictionary)->Dictionary:
	var base:={"mission_id":7,"day":120,"duration_days":24,"personnel":6,"distance_km":180,"mission_kind":"explore","target_id":"open_world","target_label":"OPEN EXPLORATION","target_finding":"","recruitment_account":{},"contacts":[],"contact_records":[],"route":[],"travel_mode":"land","route_status":"returned","turnback_reason":"","new_contact_count":0,"recruits":0,"returned_personnel":6,"lost_personnel":0,"stayed_personnel":0,"journal":[],"windfalls":[],"discoveries":[],"city_observations":[]}
	base.merge(extra,true)
	return base

func _ready()->void:
	_setup()
	_office_checks()
	_setup()
	var scenarios:=_scenarios()
	# Rotate the office so each debrief is voiced by a different person.
	var people:=GovernmentPeopleSystem.candidates_for_office("ChiefScout","",12,true)
	for index in scenarios.size():
		if not people.is_empty(): GovernmentPeopleSystem.mark_central_appointment(int(people[index%people.size()].person_id),"ChiefScout")
		_debrief_check(scenarios[index])
	_real_capture_check()
	_enqueue_check()
	_live_return_check()
	if failures.is_empty(): print("CHIEF_SCOUT PASS")
	else:
		for failure in failures: print("FAIL: ",failure)
	get_tree().quit(0 if failures.is_empty() else 1)

# ---------------------------------------------------------------------------

func _office_checks()->void:
	var state:=WorldSimulation.state
	for pair in [["centralized",0.82],["federated",0.52],["localist",0.18]]:
		var values:Dictionary=state.societal_values
		if values.has("lived"): (values.lived as Dictionary)["centralization"]=float(pair[1])
		check(GovernmentPeopleSystem.government_form()==String(pair[0]),"form %s not produced (got %s)" % [pair[0],GovernmentPeopleSystem.government_form()])
		var office:=GovernmentPeopleSystem.office_definition("ChiefScout")
		check(int(office.get("unlock_stage",99))==0,"ChiefScout not active at founding in %s" % pair[0])
		print("  ChiefScout title (%s, stage %d): %s" % [pair[0],GovernmentPeopleSystem.government_stage,String(office.get("title",""))])
		check(String(office.get("title","ChiefScout"))!="ChiefScout","ChiefScout has no evolved title in %s" % pair[0])
	for stage in 5:
		GovernmentPeopleSystem.government_stage=stage
		check(GovernmentPeopleSystem.office_is_active("ChiefScout"),"ChiefScout missing at stage %d" % stage)
	GovernmentPeopleSystem.government_stage=0
	GovernmentPeopleSystem.initialize()
	GovernmentPeopleSystem.process_day(int(GameState.elapsed_days))
	var holder:=GovernmentPeopleSystem.officeholder("ChiefScout")
	check(not holder.is_empty(),"ChiefScout not automatically staffed")
	check(int(holder.get("person_id",0))!=int(GovernmentPeopleSystem.officeholder("Steward").get("person_id",-1)),"ChiefScout doubled up with the Steward despite free candidates")
	var ranked:=GovernmentPeopleSystem.candidates_for_office("ChiefScout","",6,true)
	check(ranked.size()>=2,"no ChiefScout candidates")
	if ranked.size()>=2: check(float(ranked[0].office_fit)>=float(ranked[1].office_fit),"candidates not ranked by fit")
	var assessment:=GovernmentPeopleSystem.appointment_assessment(ranked[0],"ChiefScout")
	check(String(assessment.get("strongest_skill","")) in ["Logistics","Knowledge","Defense","Diplomacy"],"assessment skill outside scout weights: %s" % assessment.get("strongest_skill",""))
	var pick:Dictionary={}
	for candidate in ranked:
		if int(candidate.person_id)!=int(holder.get("person_id",0)) and String(candidate.get("office_key",""))=="": pick=candidate; break
	if not pick.is_empty():
		var result:=AdvisorSystem.appoint_person(int(pick.person_id),"ChiefScout")
		check(bool(result.get("ok",false)),"appoint_person failed: %s" % result.get("error",""))
		check(int(GovernmentPeopleSystem.officeholder("ChiefScout").person_id)==int(pick.person_id),"appointment not recorded")
		print("  appointed: %s" % String(result.get("message","")))
	var removed:=GovernmentPeopleSystem.remove_central_officeholder("ChiefScout","dismiss")
	check(bool(removed.get("ok",false)) and not (removed.get("successor",{}) as Dictionary).is_empty(),"no automatic ChiefScout successor")
	print("  succession: %s" % String(removed.get("message","")))
	var fit_scout:=GovernmentPeopleSystem.office_competency(ranked[0],"ChiefScout")
	check(fit_scout>0.0 and fit_scout<=1.0,"ChiefScout competency out of range")

# ---------------------------------------------------------------------------

func _scenarios()->Array[Dictionary]:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var civ2:Dictionary=CivilizationSystem.civilizations[1] if CivilizationSystem.civilizations.size()>1 else civ
	var id:=String(civ.id)
	var home:={"population":200.0,"makers":0.30,"food_days":45.0,"walls":0.2,"troops":20.0}
	var list:Array[Dictionary]=[]
	list.append({"name":"poor but beautiful","expect":["poor","beautiful"],"event":_report({
		"civ_name":"Veshari","home":home,
		"city_observations":[_city(id,"Low Ashet",116,0.72,{"population":_field(320,360,116,0.72,3),"production":_field(0.05,0.10,116,0.72),"gdp":_field(40,60,116,0.66),"fortification":_field(0.02,0.07,116,0.72),"supply":_field(32,48,116,0.8)},3)],
		"architecture":{"civic_space":0.82,"terrain_conformity":0.74,"monumentality":0.3,"permeability":0.5},
		"discoveries":[{"kind":"artifact","title":"Clay ceremonial bowl · etched river","description":"Veshari · encountered day 115","consequence":"Your knowledge workers will examine this.","collection_id":"x1"}],
		"journal":["The outward road: 3 days across open grassland; then 2 days across broadleaf woodland.","They forded running water twice."]})})
	list.append({"name":"rich and walled","expect":["rich","walled","armed"],"event":_report({
		"civ_name":"Orrun Hold","home":home,"mission_kind":"observe_city","target_id":"city:%s_r0" % String(civ2.id),"target_city_id":"%s_r0" % String(civ2.id),
		"city_observations":[_city(String(civ2.id),"Orrun Gate",110,0.86,{"population":_field(2300,2500,110,0.86,6),"production":_field(0.66,0.74,110,0.86),"fortification":_field(0.68,0.78,110,0.86),"garrison":_field(160,200,110,0.86),"logistics":_field(0.6,0.7,110,0.86),"supply":_field(85,110,110,0.86),"life_expectancy":_field(54,60,110,0.86)},6)],
		"architecture":{"civic_space":0.4,"terrain_conformity":0.3,"monumentality":0.8,"permeability":0.2}})})
	list.append({"name":"starving","expect":["starving"],"event":_report({
		"civ_name":"Tamsk","home":home,
		"city_observations":[_city(id,"Tamsk Ford",100,0.62,{"population":_field(820,980,100,0.55),"production":_field(0.25,0.35,100,0.62),"supply":_field(4,9,100,0.8),"health":_field(0.30,0.42,100,0.62),"life_expectancy":_field(26,31,100,0.62),"infant_mortality":_field(240,300,100,0.62)})]})})
	list.append({"name":"hostile reception","expect":["hostile","armed"],"event":_report({
		"civ_name":"Kalveth","home":home,"lost_personnel":2,"returned_personnel":4,
		"relation":{"opinion":-0.6,"border_tension":0.7,"at_war":true},
		"city_observations":[_city(id,"Kalveth Crag",114,0.58,{"population":_field(500,640,114,0.45),"fortification":_field(0.40,0.52,114,0.58),"garrison":_field(50,75,114,0.58)})],
		"discoveries":[{"kind":"intelligence","title":"Armed strangers on the road","description":"Returning scouts report a warband of Kalveth — roughly 45 under arms — moving near the marked point on their charted route.","consequence":"A dated sighting has been added to the map."}]})})
	list.append({"name":"empty wilderness","expect":["empty"],"event":_report({
		"home":home,
		"journal":["The outward road: 4 days across dry steppe; then 3 days across bare upland.","They forded running water once.","The route climbed above the treeline into bare summit country.","At their farthest they stood roughly 92 km to the northwest of Hearth."],
		"discoveries":[{"kind":"resource","title":"The copper-bearing hills","description":"The scouts marked an occurrence of copper ore in the high country.","consequence":"A potential metalworking supply.","resource":"Copper Ore","distance_km":64,"quality":0.8},
			{"kind":"hearsay","title":"A name beyond the horizon","description":"Wanderers spoke of a people called the Sarn who winter by a great lake. Nobody we met had been there.","consequence":"A lead."}]})})
	list.append({"name":"envoys turned away","expect":["hostile"],"event":{"source":"envoys","day":118,"civ_id":id,"civ_name":"Veshari","purpose":"trade_pact","accepted":false,"outcome":"The Veshari council refused a trade pact.","home":home,
		"city_observations":[_city(id,"Low Ashet",112,0.5,{"population":_field(300,380,112,0.5),"supply":_field(18,26,112,0.8)})],
		"brought_home":[{"kind":"artifact","title":"Wood painted panel · etched river","description":"Veshari","consequence":"Study it."}]}})
	return list

# Words that assert a fact; a line may use one only if the fact is present.
const CLAIMS:={
	"wall":["walls"],"defens":["walls"],"under arms":["garrison","armed"],"weapons":["garrison","armed"],
	"hungry":["food"],"stores":["food"],"storehouse":["food"],"food":["food"],
	"workshop":["makers","busyness"],"hammer":["makers"],"craft":["makers","ornament"],"idle":["makers","busyness"],
	"lovely":["beauty","ornament"],"beautiful":["beauty","ornament"],"handsome":["beauty"],"build well":["beauty"],
	"lost":["losses"],"didn't come home":["losses"],"sickly":["health"],"coughs":["health"],"grey head":["old_age"],"babies":["infants"],"little ones":["infants"],
	"copper":["resource"],"forded":["terrain"],"hearsay":["rumor"],"no people":["terrain"],"not a soul":["terrain"],
	"said no":["reception"],"a no,":["reception"],"polite no":["reception"],"don't like it":["reception"],
}

func _debrief_check(scenario:Dictionary)->void:
	var event:Dictionary=scenario.event
	var found:Dictionary=SCOUT.findings(event)
	var record:Dictionary=SCOUT.report_record(event,found)
	var flags:Dictionary=found.flags
	for flag in scenario.expect: check(bool(flags.get(flag,false)),"%s: expected flag %s (flags %s)" % [scenario.name,flag,str(flags)])
	check(bool(found.significant),"%s: not significant" % scenario.name)
	var lines:Array=record.lines
	var spoken:=lines.filter(func(l:Dictionary)->bool:return not bool(l.aside))
	check(spoken.size()>=3 and lines.size()<=6,"%s: %d lines (%d spoken)" % [scenario.name,lines.size(),spoken.size()])
	var keys:={}
	var numbers:=""
	for fact in found.facts:
		keys[String(fact.key)]=true
		numbers+=" "+JSON.stringify(fact)
	numbers+=" "+JSON.stringify(found.home)
	print("\n=== %s — %s (%s) ===" % [scenario.name.to_upper(),String(found.subject_name),String(found.source)])
	var chips:=PackedStringArray()
	for fact in found.facts: chips.append("[%s]" % String(fact.label))
	print("  chips: "+" ".join(chips))
	for line in lines:
		var text:=String(line.text)
		print("  %s%s: %s" % ["(aside) " if bool(line.aside) else "",String(line.speaker),text])
		var lower:=text.to_lower()
		for word in CLAIMS:
			if String(word) in lower:
				var ok:=false
				for key in CLAIMS[word]:
					if keys.has(key): ok=true
				check(ok,"%s: line claims '%s' without fact %s: %s" % [scenario.name,word,str(CLAIMS[word]),text])
		var regex:=RegEx.new(); regex.compile("\\d[\\d,]*")
		for m in regex.search_all(text):
			var digits:=m.get_string().replace(",","")
			check(digits in numbers.replace(",",""),"%s: number %s not in facts: %s" % [scenario.name,digits,text])
		check(line.role=="official" and line.has_all(["speaker","role","person_id","civ_id","text","day","aside"]),"%s: bad line shape" % scenario.name)
	var brief:Dictionary=SCOUT.voice_brief({"speaker":record.speaker,"report":record.report})
	check((brief.facts as Array).size()==found.facts.size() and String(brief.instructions).contains("ONLY"),"%s: voice brief incomplete" % scenario.name)
	# Determinism: same audience, same lines.
	var again:Dictionary=SCOUT.report_record(event,found)
	check(JSON.stringify(again.lines)==JSON.stringify(record.lines),"%s: debrief not deterministic" % scenario.name)

func _real_capture_check()->void:
	# Real observation shapes: capture a foreign city's truth through the same
	# path a scouting party uses, publish it, and read it back as known().
	var intel=CivilizationSystem.city_intelligence
	var sites:Array=intel.sites(false)
	check(not sites.is_empty(),"no foreign sites to observe")
	if sites.is_empty(): return
	var site:Dictionary=sites[0]
	var day:=int(GameState.elapsed_days)
	var observation:Dictionary=intel.capture("player",String(site.city_id),0.86,day-3,"physical reconnaissance","scout:probe",5)
	check(not observation.is_empty() and not (observation.fields as Dictionary).is_empty(),"capture produced no fields")
	var mission:={"city_observations":{String(site.city_id):observation},"route":[]}
	var delivered:Array=intel.deliver(mission,"player",day)
	var report:=_report({"day":day,"mission_kind":"observe_city","target_id":"city:"+String(site.city_id),"target_city_id":String(site.city_id),"city_observations":delivered,"contacts":[String(site.name)]})
	var found:Dictionary=SCOUT.findings(report)
	var keys:=PackedStringArray()
	for fact in found.facts: keys.append(String(fact.key))
	print("\n=== REAL CAPTURE — %s ===\n  facts: %s" % [String(found.subject_name),", ".join(keys)])
	check("population" in keys,"real capture: no population fact")
	check(String(found.subject_civ_id)==String(site.civ_id),"real capture: wrong subject civ")
	var record:Dictionary=SCOUT.report_record(report,found)
	for line in record.lines: print("  %s: %s" % [String(line.speaker),String(line.text)])

func _enqueue_check()->void:
	var holder:=GovernmentPeopleSystem.officeholder("ChiefScout")
	check(not holder.is_empty(),"no ChiefScout for enqueue")
	var before:=HALL.waiting().size()
	var held_before:=HALL.matters().size()
	var event:Dictionary=_scenarios()[1].event
	var matter:Dictionary=SCOUT.report_returned(event,"scouts")
	# The Chief Scout never comes uninvited: the report waits as a matter.
	var stored:Dictionary=matter.get("audience",{}) if matter.get("audience") is Dictionary else {}
	var hall_ready:=false
	for method in (HALL as Script).get_script_method_list():
		if String(method.name)=="enqueue": hall_ready=true
	if hall_ready:
		check(not stored.is_empty(),"report_returned did not file a matter")
		check(HALL.waiting().size()==before,"the Chief Scout came in uninvited")
		check(HALL.matters().size()==held_before+1 and String(matter.get("holder_key",""))=="person:%d" % int(holder.get("person_id",0)),"report matter not held by the Chief Scout")
		check(int(stored.get("speaker",{}).get("person_id",0))==int(holder.get("person_id",0)),"speaker is not the ChiefScout")
		check(String(stored.get("kind",""))=="report" and String(stored.get("origin",""))=="court","wrong kind/origin")
		check((matter.get("lines",[]) as Array).size()>=3,"prefilled lines missing")
		check(String(stored.get("report",{}).get("source",""))=="scouts","report source wrong")
		var duplicate:Dictionary=SCOUT.report_returned(event,"scouts")
		check(duplicate.is_empty(),"duplicate report for same subject enqueued")
		var routine:Dictionary=SCOUT.report_returned(_report({"journal":["The outward road: 2 days across open grassland."]}),"scouts")
		check(routine.is_empty(),"routine survey requested an audience")
		# Summoned, the Chief Scout delivers the debrief with its prefilled lines.
		var opened:Dictionary=HALL.open_matter(String(matter.get("id","")))
		check(not opened.is_empty() and String(opened.kind)=="report" and (HALL.find(String(opened.id)).lines as Array).size()>=3,"summoned Chief Scout did not deliver the report")
	# The simulation hook (guarded load, not preload) reaches the hall too.
	var hook_before:=HALL.matters().size()
	CivilizationSystem._chief_scout_report(_scenarios()[2].event,"scouts")
	if hall_ready: check(HALL.matters().size()==hook_before+1,"CivilizationSystem hook did not file a matter")
	print("\n  enqueue: %s (hall supports enqueue: %s)" % ["ok" if not stored.is_empty() else "none",str(hall_ready)])
	# Vacant office: the party lead speaks.
	var speaker:Dictionary=SCOUT.fallback_speaker(_report({}))
	check(String(speaker.get("name",""))!="" and int(speaker.person_id)==0,"vacant office has no fallback speaker")

func _live_return_check()->void:
	# End to end: a real dispatched party returns through CivilizationSystem and
	# the hook runs without errors (whether it is significant depends on the map).
	GameState.resource_stockpiles["Food"]=maxf(2000.0,float(GameState.resource_stockpiles.get("Food",0.0)))
	var dispatched:Dictionary=CivilizationSystem.dispatch_scouts(30)
	if not bool(dispatched.get("ok",false)):
		print("  live return skipped: %s" % String(dispatched.get("error","dispatch refused")))
		return
	var start:=int(GameState.elapsed_days)
	var before:=CivilizationSystem.scout_reports.size()
	for day in range(start+1,start+60):
		GameState.elapsed_days=float(day)
		CivilizationSystem.advance_to_day(day)
	check(CivilizationSystem.scout_reports.size()>before or CivilizationSystem.scout_missions.is_empty(),"live party never returned")
	var reports:Array=HALL.matters().filter(func(m:Dictionary)->bool:return String(m.kind)=="report").map(func(m:Dictionary)->Dictionary:
		var copy:Dictionary=(m.audience as Dictionary).duplicate(true); copy["lines"]=m.lines; return copy)
	check(HALL.waiting().filter(func(a:Dictionary)->bool:return String(a.kind)=="report").is_empty(),"a live report came in uninvited")
	print("  live return: %d scout reports archived, %d report matters held" % [CivilizationSystem.scout_reports.size(),reports.size()])
	for audience in reports:
		if int(audience.arrived_day)>start:
			print("  live debrief on %s:" % String(audience.report.subject_name))
			for line in audience.lines: print("    %s: %s" % [String(line.speaker),String(line.text)])
