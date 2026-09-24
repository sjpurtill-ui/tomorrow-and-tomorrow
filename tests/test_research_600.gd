extends GdUnitTestSuite
## The data-driven 600-year research layer: loader, design overrides, era gate,
## design conditions, legacy saves and rival parity.
const Catalog=preload("res://scripts/research_600_catalog.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const R=preload("res://scripts/technology_requirements.gd")
const Probe=preload("res://tools/research/research_600_probe.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(60060);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _day(year:float)->int:
	return int(ceil(year*365.0))

func _entry(id:String)->Dictionary:
	return DiscoverySystem.discovery_definition(id)

func _society(year:float)->Dictionary:
	var society:=Probe.permissive_society();society.year=year
	return society

func test_loader_registers_all_1101_design_discoveries()->void:
	# The approved design has 1,101 items; Phase 3 adopts the in-window catalog
	# entries it never listed (tools/research/design_amendments_600.json).
	assert_int(int(Catalog.meta().get("design_node_count",0))).is_equal(1101)
	assert_int(Catalog.ids().size()).is_equal(1101+int(Catalog.meta().get("adopted_count",0)))
	assert_int(int(Catalog.meta().get("node_count",0))).is_equal(Catalog.ids().size())
	var live:Dictionary={}
	for entry:Dictionary in DiscoverySystem.technology_catalog:live[String(entry.id)]=true
	var missing:Array[String]=[]
	for id:String in Catalog.ids():
		if not live.has(id):missing.append(id)
	assert_array(missing).is_empty()
	var lines:Dictionary={}
	for id:String in Catalog.ids():lines[String(Catalog.item(id).line)]=true
	assert_int(lines.size()).is_equal(12)

func test_new_design_items_use_the_catalog_format_and_a_valid_channel()->void:
	var channels:Dictionary=preload("res://scripts/discovery_frontier_catalog.gd").SUBCATEGORIES
	var count:=0
	for id:String in Catalog.ids():
		if String(Catalog.item(id).status)!="new":continue
		count+=1
		var entry:=_entry(id)
		assert_bool(entry.is_empty()).override_failure_message(id).is_false()
		assert_str(String(entry.dynamic)).is_equal(String(Catalog.item(id).line))
		assert_bool(String(entry.subcategory) in channels[String(entry.dynamic)]).override_failure_message(id).is_true()
		assert_str(String(entry.name)).is_not_empty()
		assert_str(String(entry.observation)).is_not_empty()
		assert_array(entry.signals).is_not_empty()
		assert_dict(entry.effects).is_not_empty()
		assert_float(float(entry.chance)).is_equal_approx(Catalog.chance_for(float(Catalog.item(id).research_years)),0.0000001)
		assert_bool(bool(entry.get("frontier",false))).is_false()
		# A dedicated research_600 painting (data/research/art_600.json) wins; otherwise the line's default art.
		var visuals:=preload("res://scripts/hud/research_visuals.gd")
		var expected:=String(visuals.art600_manifest()[id].path) if visuals.art600_manifest().has(id) else "%s-v1.png" % String(entry.dynamic)
		assert_str(visuals.subject_art_key(entry)).ends_with(expected)
	assert_int(count).is_equal(543)

func test_existing_items_take_design_foundations_era_and_pace()->void:
	var rigid:=_entry("rigid_pipe_bedding")
	assert_array(rigid.requires_all).is_equal(["ceramic_pipe_firing_qualification","runoff_grade_reading"])
	assert_array(rigid.requires_any).is_empty()
	GameState.known_discoveries.assign(["drainage","joinery","clay_tempering"])
	assert_bool(P.ready(rigid,0)).override_failure_message("authored foundations must no longer suffice").is_false()
	GameState.known_discoveries.assign(["ceramic_pipe_firing_qualification","runoff_grade_reading"])
	assert_bool(P.ready(rigid,0)).is_true()
	assert_float(DiscoverySystem.discovery_era("rigid_pipe_bedding")).is_equal(425.0)
	assert_float(DiscoverySystem.research_600_earliest_year(rigid)).is_equal(385.0)
	assert_int(int(rigid.day)).is_equal(425*365)
	assert_float(float(rigid.chance)).is_equal_approx(Catalog.chance_for(float(Catalog.item("rigid_pipe_bedding").research_years)),0.0000001)
	# Authored production contract and recipe outputs are kept.
	assert_str(String(rigid.get("production_contract",""))).is_not_empty()
	assert_array(rigid.get("production_items",[])).is_not_empty()

func test_place_value_requires_its_whole_recording_chain()->void:
	var place:=_entry("place_value")
	assert_array(place.requires_all).is_equal(["reciprocal_tables"])
	GameState.known_discoveries.assign(["standard_measures","pictographic_records"])
	assert_bool(P.ready(place,0)).is_false()
	# Every link of the design chain is a transitive foundation.
	var ancestors:Dictionary={}
	var frontier:Array=["place_value"]
	while not frontier.is_empty():
		var id:String=frontier.pop_back()
		var entry:=_entry(id)
		var parents:Array=entry.get("requires_all",[]).duplicate()
		for group:Array in entry.get("requires_any",[]):parents.append_array(group)
		for parent:String in parents:
			if not ancestors.has(parent):ancestors[parent]=true;frontier.append(parent)
	for link:String in ["reciprocal_tables","public_schools","scribal_apprenticeship","standard_sign_lists","clay_record_tablets","pictographic_records","impressed_number_tablets","token_envelopes","stamp_seals","owner_marks","clay_shaping","clay_testing"]:
		assert_bool(ancestors.has(link)).override_failure_message("place_value chain lacks "+link).is_true()
	assert_float(DiscoverySystem.research_600_earliest_year(place)).is_equal(470.0)

func test_bookbinding_waits_for_its_era_even_with_cordage()->void:
	var book:=_entry("bookbinding_assemblies")
	assert_bool(Catalog.has("bookbinding_assemblies")).is_false()
	GameState.known_discoveries.assign(["cordage","fiber_grading"])
	assert_bool(P.ready(book,_day(16))).is_true()
	var opens:=DiscoverySystem.research_600_earliest_year(book)
	assert_float(opens).is_greater(1000.0)
	for year:float in [16.0,75.0,180.0,600.0,opens-1.0]:
		GameState.elapsed_days=_day(year)
		assert_bool(DiscoverySystem._discovery_is_eligible(book,_day(year))).override_failure_message("year %d" % int(year)).is_false()
	GameState.elapsed_days=_day(opens)
	assert_bool(DiscoverySystem._discovery_is_eligible(book,_day(opens))).is_true()

func test_items_outside_the_registry_hold_to_their_era_or_the_window_end()->void:
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		var id:=String(entry.id)
		if Catalog.has(id):continue
		var earliest:=DiscoverySystem.research_600_earliest_year(entry)
		var era:=DiscoverySystem.discovery_era(id)
		if Catalog.redate(id)>=0.0:
			# Phase 3 re-dates (tools/research/design_amendments_600.json).
			assert_float(earliest).override_failure_message(id).is_equal(Catalog.redate(id))
		elif preload("res://scripts/technology_eras.gd").HISTORICAL_YEAR.has(id):
			var expected:=era*Catalog.ERA_BAND_FRACTION
			# Entries dated after the window never open inside it.
			if era>Catalog.WINDOW_END_YEAR:expected=maxf(Catalog.WINDOW_END_YEAR,expected)
			assert_float(earliest).override_failure_message(id).is_equal_approx(expected,0.001)
		else:
			assert_float(earliest).override_failure_message(id).is_greater_equal(Catalog.WINDOW_END_YEAR)
	for id:String in ["differential_calculus","integral_calculus","public_libraries"]:
		assert_float(DiscoverySystem.research_600_earliest_year(_entry(id))).override_failure_message(id).is_greater(500.0)
	# Iron must not open before about year 660 (1000 BCE).
	for id:String in ["bloomery_smelting","iron_assaying","forge_welding","bloomery_charge_control"]:
		assert_float(DiscoverySystem.research_600_earliest_year(_entry(id))).override_failure_message(id).is_greater_equal(660.0)

func test_conditions_gate_availability_for_any_society()->void:
	var cases:={"part_time_specialists":["population",29.0,30.0],"village_marriage_alliances":["settlements",1,2],
		"temple_common_storehouse":["institutions",0.19,0.2],"salt_shell_routes":["contact",false,true]}
	for id:String in cases:
		var entry:=_entry(id)
		var society:=_society(600.0)
		society[cases[id][0]]=cases[id][1]
		assert_bool(DiscoverySystem.research_600_open(entry,society)).override_failure_message(id).is_false()
		assert_array(DiscoverySystem.research_600_missing(entry,society)).override_failure_message(id).is_not_empty()
		society[cases[id][0]]=cases[id][2]
		assert_bool(DiscoverySystem.research_600_open(entry,society)).override_failure_message(id).is_true()
	var clay:=_entry("clay_shaping")
	var society:=_society(600.0);society.resources={}
	assert_bool(DiscoverySystem.research_600_open(clay,society)).is_false()
	society.resources={"Clay":true}
	assert_bool(DiscoverySystem.research_600_open(clay,society)).is_true()
	var river:=_entry("river_craft")
	society.environment={"coast":true,"dry":true}
	assert_bool(DiscoverySystem.research_600_open(river,society)).is_false()
	society.environment={"dry":true,"river":true}
	assert_bool(DiscoverySystem.research_600_open(river,society)).is_true()
	# Unmapped design resources are never enforced.
	assert_array(Catalog.item("gypsum_mortar").conditions.get("resources_unmapped",[])).is_not_empty()
	assert_bool(Catalog.conditions_met("gypsum_mortar",_society(600.0))).is_true()

func test_player_conditions_read_the_live_society()->void:
	GameState.elapsed_days=_day(100)
	var entry:=_entry("clay_shaping")
	GameState.known_discoveries.assign(entry.requires_all)
	GameState.resource_deposits=[];GameState.resource_stockpiles.clear()
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,_day(100))).is_false()
	var reasons:=DiscoverySystem.research_600_missing(entry)
	assert_bool("; ".join(PackedStringArray(reasons)).contains("Clay")).is_true()
	GameState.resource_deposits=[{"resource":"Clay","stage":"recognized"}]
	assert_bool(DiscoverySystem.research_600_open(entry)).is_true()
	var specialists:=_entry("part_time_specialists")
	GameState.population_total=20
	assert_bool(DiscoverySystem.research_600_open(specialists)).is_false()
	GameState.population_total=40
	assert_bool(DiscoverySystem.research_600_open(specialists)).is_true()

func test_design_graph_is_acyclic()->void:
	var state:Dictionary={}
	var cycles:Array[String]=[]
	for root:String in Catalog.ids():
		if state.has(root):continue
		var stack:Array=[[root,0]]
		state[root]=1
		while not stack.is_empty():
			var top:Array=stack.back()
			var parents:Array=Catalog.item(String(top[0])).requires_all.duplicate()
			for group:Array in Catalog.item(String(top[0])).requires_any:parents.append_array(group)
			if int(top[1])>=parents.size():
				state[top[0]]=2;stack.pop_back();continue
			var child:=String(parents[int(top[1])]);top[1]=int(top[1])+1
			if int(state.get(child,0))==1:cycles.append(String(top[0])+"->"+child)
			elif not state.has(child):state[child]=1;stack.append([child,0])
	assert_array(cycles).is_empty()

func test_every_design_item_is_reachable_by_year_600_and_the_live_graph_validates()->void:
	var first:=Probe.earliest_years(DiscoverySystem,600.0,5.0)
	var unreachable:Array[String]=[]
	for id:String in Catalog.ids():
		if not first.has(id):unreachable.append(id)
	assert_array(unreachable).is_empty()
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(P.graph_entry(entry))
	var dormant=preload("res://tools/technology-review/dormant_or_audit.gd")
	graph=dormant.factor_common(graph,DiscoverySystem.technology_catalog)
	assert_array(R.validate(graph,dormant.pending(graph))).is_empty()

func test_first_century_probe_opens_nothing_before_its_band()->void:
	var step:=0.5
	var first:=Probe.earliest_years(DiscoverySystem,100.0,step)
	var early:Array[String]=[]
	for id:String in first:
		var year:=float(first[id])
		var gate:=DiscoverySystem.research_600_earliest_year(_entry(id))
		if year<gate-0.000001:early.append("%s@%.1f<gate %.1f" % [id,year,gate])
		if Catalog.has(id) and year+step<float(Catalog.item(id).band_low):early.append("%s@%.1f<band %.1f" % [id,year,float(Catalog.item(id).band_low)])
	assert_array(early).is_empty()
	# The gate does not starve the early game: every design item whose band
	# opens in the first century is reachable within it.
	for id:String in Catalog.ids():
		if float(Catalog.item(id).min_year)<=99.5:assert_bool(first.has(id)).override_failure_message(id).is_true()
	for id:String in ["bookbinding_assemblies","bloomery_smelting","differential_calculus","place_value","rigid_pipe_bedding"]:
		assert_bool(first.has(id)).override_failure_message(id).is_false()

func test_known_discoveries_in_a_legacy_save_stay_known()->void:
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.elapsed_days=30
	var gated:Array[String]=["place_value","bookbinding_assemblies","differential_calculus","rigid_pipe_bedding"]
	GameState.known_discoveries.assign(gated+["cordage","tallies"])
	for id:String in gated:GameState.discovery_adoption[id]=0.5
	var channel:=DiscoverySystem._channel_key(String(_entry("bloomery_smelting").dynamic),String(_entry("bloomery_smelting").subcategory))
	GameState.active_investigations[channel]="bloomery_smelting"
	GameState.discovery_progress["bloomery_smelting"]=0.4
	GameState.scholarship_level=-1.0
	var slot:="codex_research_600_%d" % Time.get_ticks_usec()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	var restored:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	DiscoverySystem.refresh_investigations()
	for id:String in gated:assert_bool(id in GameState.known_discoveries).override_failure_message(id).is_true()
	# An investigation that opened under the old rules pauses; its progress is kept.
	assert_str(String(GameState.active_investigations.get(channel,""))).is_not_equal("bloomery_smelting")
	assert_float(float(GameState.discovery_progress.get("bloomery_smelting",0.0))).is_equal(0.4)
	# Known entries keep contributing their effects.
	assert_float(DiscoverySystem.adoption("place_value")).is_greater(0.0)

func test_rival_civilizations_use_the_same_gate_and_conditions()->void:
	var civ:={"production":1.0,"logistics":1.0,"population":500.0,"institutions":0.6,"settlement_count":3,
		"environment_profile":{"resource_potentials":{"Copper Ore":0.9,"Clay":0.9},"coastal":true,"biome":"floodplain"},
		"relations":{},"player_relation":{"rival_contact_level":0},
		"discovery_profile":{"seed":7,"technologies":["cordage","fiber_grading","ore_assaying","kiln_control","charcoal","native_copper_working"]}}
	GameState.elapsed_days=_day(16)
	var ids:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"knowledge"):ids.append(String(entry.id))
	assert_bool("bookbinding_assemblies" in ids).is_false()
	GameState.elapsed_days=_day(DiscoverySystem.research_600_earliest_year(_entry("copper_smelting")))
	ids.clear()
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"production"):ids.append(String(entry.id))
	assert_bool("copper_smelting" in ids).is_true()
	civ.environment_profile.resource_potentials.erase("Copper Ore")
	ids.clear()
	for entry:Dictionary in DiscoverySystem.rival_research_candidates(civ,"production"):ids.append(String(entry.id))
	assert_bool("copper_smelting" in ids).is_false()
	# A player society in the same circumstances gets the same answers.
	civ.environment_profile.resource_potentials["Copper Ore"]=0.9
	var rival:=DiscoverySystem.research_600_rival_society(civ)
	GameState.population_total=500;GameState.society_capacities["institutions"]=0.6
	GameState.resource_deposits=[{"resource":"Copper Ore","stage":"recognized"},{"resource":"Clay","stage":"recognized"}]
	GameState.resource_stockpiles.clear()
	for id:String in ["copper_smelting","clay_shaping","salt_shell_routes","part_time_specialists","temple_common_storehouse","megalith_raising"]:
		assert_bool(DiscoverySystem.research_600_open(_entry(id))).override_failure_message(id).is_equal(DiscoverySystem.research_600_open(_entry(id),rival))
	assert_bool(bool(rival.contact)).is_false()
	civ.relations={"civ_b":{"trade":0.2}}
	assert_bool(bool(DiscoverySystem.research_600_rival_society(civ).contact)).is_true()

func test_known_precedents_make_research_quicker_but_are_not_required()->void:
	var id:=""
	for candidate:String in Catalog.ids():
		if not (Catalog.item(candidate).precedents as Array).is_empty():id=candidate;break
	var entry:=_entry(id)
	var precedent:=String(Catalog.item(id).precedents[0])
	assert_bool(precedent in entry.requires_all).is_false()
	GameState.known_discoveries.clear()
	var slow:=DiscoverySystem.research_difficulty(entry,11)
	GameState.known_discoveries.append(precedent)
	assert_float(DiscoverySystem.research_difficulty(entry,11)).is_less(slow)
	assert_float(DiscoverySystem.research_difficulty(entry,11,NAN,[])).is_equal(slow)
