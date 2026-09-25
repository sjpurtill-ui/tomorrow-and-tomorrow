extends GdUnitTestSuite
## The real 2400-3000 research block (data/research/blocks/y2400_3000.json, built
## by tools/research/build_research_block.py from the design branch): the last
## era, about AD 1800-2030. The first stored-program computer waits for its
## window, weapons of mass destruction stay the ruler's decision, prerequisites
## reaching back into earlier blocks resolve, and all five blocks load.
const Catalog=preload("res://scripts/research_600_catalog.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Probe=preload("res://tools/research/research_600_probe.gd")
const Sovereign=preload("res://scripts/sovereign_weapons.gd")
const Commands=preload("res://scripts/court_commands.gd")

func before_test()->void:
	WorldSimulation.clear()
	Catalog.use_manifest("")
	GameState.reset_for_new_world(30030);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.military.sovereign_decisions.clear()

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.military.sovereign_decisions.clear()
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _day(year:float)->int:
	return int(ceil(year*365.0))

func _entry(id:String)->Dictionary:
	return DiscoverySystem.discovery_definition(id)

func _society(year:float)->Dictionary:
	var society:=Probe.permissive_society();society.year=year
	return society

func _eligible_at(entry:Dictionary,year:float)->bool:
	GameState.elapsed_days=_day(year)
	return DiscoverySystem._discovery_is_eligible(entry,_day(year))

func test_all_five_blocks_load_from_year_0_to_3000()->void:
	assert_array(Catalog.blocks()).is_equal(["y0_600","y600_1200","y1200_1800","y1800_2400","y2400_3000"])
	var lowest:=INF;var highest:=-INF
	for block:String in Catalog.blocks():
		var ids:=Catalog.block_ids(block)
		assert_int(ids.size()).override_failure_message(block).is_greater(0)
		for id:String in ids:
			lowest=minf(lowest,float(Catalog.item(id).proposed_year));highest=maxf(highest,float(Catalog.item(id).proposed_year))
	assert_float(lowest).is_less(600.0)
	assert_float(highest).is_less_equal(3000.0)
	assert_float(highest).is_greater(2950.0)
	assert_int(Catalog.block_ids("y2400_3000").size()).is_equal(1575)
	assert_str(Catalog.block_of("stored_program_computer")).is_equal("y2400_3000")

func test_stored_program_computer_is_locked_before_its_window()->void:
	var computer:=_entry("stored_program_computer")
	assert_bool(computer.is_empty()).is_false()
	var item:=Catalog.item("stored_program_computer")
	assert_array(item.requires_all).contains(["triode_valves","binary_adders","relay_registers","computability_theory"])
	var opens:=DiscoverySystem.research_600_earliest_year(computer)
	assert_float(opens).is_equal(float(item.band_low))
	assert_float(opens).is_greater(2750.0)
	GameState.known_discoveries.assign(item.requires_all)
	for year:float in [1200.0,2400.0,2700.0,opens-1.0]:
		assert_bool(DiscoverySystem.research_600_open(computer,_society(year))).override_failure_message("year %d" % int(year)).is_false()
		assert_bool(_eligible_at(computer,year)).override_failure_message("year %d" % int(year)).is_false()
	assert_bool(DiscoverySystem.research_600_open(computer,_society(opens))).is_true()
	# Weather forecasting on electronic machines needs the computer itself.
	assert_array(Catalog.item("numerical_weather_prediction").requires_all).contains(["stored_program_computer"])
	assert_array(Catalog.item("numerical_weather_prediction").requires_all).not_contains(["binary_adders"])

func test_cross_block_prerequisites_resolve()->void:
	var cross:=0
	var unknown:Array[String]=[]
	for id:String in Catalog.block_ids("y2400_3000"):
		var item:=Catalog.item(id)
		assert_bool(_entry(id).is_empty()).override_failure_message(id).is_false()
		var parents:Array=(item.requires_all as Array).duplicate()
		for group:Array in item.requires_any:parents.append_array(group)
		parents.append_array(item.precedents)
		for parent:String in parents:
			if not Catalog.has(parent) or _entry(parent).is_empty():unknown.append("%s <- %s" % [id,parent])
			elif Catalog.block_of(parent)!="y2400_3000":cross+=1
	assert_array(unknown).is_empty()
	assert_int(cross).is_equal(int(Catalog.block_meta("y2400_3000").get("cross_block_references",0)))
	assert_int(cross).is_greater(1000)
	# Oil wells build on the brine wells of 1200-1800.
	assert_str(Catalog.block_of("percussion_drilled_wells")).is_equal("y1200_1800")
	var wells:=_entry("rock_oil_well_drilling")
	GameState.known_discoveries.assign(["high_pressure_steam_engines"])
	assert_bool(P.ready(wells,_day(2600))).is_false()
	GameState.known_discoveries.assign(["high_pressure_steam_engines","percussion_drilled_wells"])
	assert_bool(P.ready(wells,_day(2600))).is_true()
	# Discharge tubes sit on the 1800-2400 air pump; bone imaging needs the tubes.
	assert_str(Catalog.block_of("vacuum_pumps")).is_equal("y1800_2400")
	assert_array(Catalog.item("bone_shadow_imaging").requires_all).contains(["cathode_ray_discharge_tubes"])
	assert_array(Catalog.item("transgenic_crops").requires_all).contains(["recombinant_dna"])

func test_general_cannot_use_a_fission_weapon_without_the_rulers_decision()->void:
	GameState.known_discoveries.assign(["nuclear_fission","reactor_engineering","fission_weapon"])
	# Knowing the bomb does not put it in a general's hands.
	var gate:=WorldSimulation.military.general_use_gate("fission_weapon",{"target":"field"})
	assert_bool(gate.has("error")).is_true()
	assert_str(String(gate.kind)).is_equal("sovereign")
	# No path other than the Court records a decision: an order, a general's
	# own insistence or a decision without spoken words is refused.
	assert_bool(WorldSimulation.military.record_sovereign_decision("fission_weapon",{"source":"general","spoken":"Use it."}).has("error")).is_true()
	assert_bool(WorldSimulation.military.record_sovereign_decision("fission_weapon",{"source":"court","spoken":""}).has("error")).is_true()
	assert_bool(WorldSimulation.military.general_use_gate("fission_weapon",{"target":"field","override":true}).has("error")).is_true()
	# Battle options that ask for it fight without it and record the refusal.
	var means:=WorldSimulation.military.filter_general_means(["fission_weapon","aerial_bombardment"],{"target":"field"})
	assert_array(means.allowed).is_equal(["aerial_bombardment"])
	assert_array(means.withheld).is_equal(["fission_weapon"])
	# The ruler's decision, spoken in the Court, is recorded and then allows it.
	var decree:=Sovereign.parse_decree("I command you: use the fission bomb against Bracken Hold.")
	assert_str(String(decree.decree)).is_equal("authorize")
	assert_array(decree.means).is_equal(["fission_weapon"])
	var heard:=Commands._sovereign_decree("court_test","I command you: use the fission bomb against Bracken Hold.",{"echoed":true})
	assert_bool(bool(heard.get("handled",false))).override_failure_message(str(heard)).is_true()
	assert_str(String(heard.stage)).is_equal("sovereign_decree")
	assert_str(String(WorldSimulation.military.sovereign_decisions.fission_weapon.source)).is_equal("court")
	# A weapon the realm does not know is ordinary speech, not a decree.
	assert_bool(Commands._sovereign_decree("court_test","Use the hydrogen bomb.",{"echoed":true}).is_empty()).is_true()
	assert_bool(WorldSimulation.military.general_use_gate("fission_weapon",{"target":"city"}).has("ok")).is_true()
	# Only that weapon: the thermonuclear weapon still needs its own decision.
	assert_str(String(WorldSimulation.military.general_use_gate("thermonuclear_weapon",{}).get("kind",""))).is_equal("sovereign")
	# Forbidding it again withdraws the authority.
	assert_str(String(Sovereign.parse_decree("Never use the fission bomb again.").decree)).is_equal("forbid")
	Commands._sovereign_decree("court_test","Never use the fission bomb again.",{"echoed":true})
	assert_bool(WorldSimulation.military.general_use_gate("fission_weapon",{}).has("error")).is_true()

func test_restricted_means_and_human_signoff()->void:
	for id:String in Sovereign.SOVEREIGN:assert_str(Sovereign.authority(id)).is_equal("sovereign")
	# Bombing armies in the field is the general's; bombing a city is not.
	assert_bool(WorldSimulation.military.general_use_gate("aerial_bombardment",{"target":"field"}).has("ok")).is_true()
	assert_str(String(WorldSimulation.military.general_use_gate("aerial_bombardment",{"target":"city"}).get("kind",""))).is_equal("restricted")
	assert_str(String(WorldSimulation.military.general_use_gate("armed_remote_strike",{"target":"city"}).get("kind",""))).is_equal("restricted")
	assert_str(Sovereign.means_of_equipment("strategic_bomber_equipment")).is_equal("aerial_bombardment")
	assert_str(Sovereign.means_of_equipment("strike_drone_equipment")).is_equal("armed_remote_strike")
	# The machine proposes; a named commander signs off.
	assert_str(String(WorldSimulation.military.general_use_gate("machine_assisted_targeting",{}).get("kind",""))).is_equal("signoff")
	assert_bool(WorldSimulation.military.general_use_gate("machine_assisted_targeting",{"signoff":true}).has("ok")).is_true()
	# Every gated means is a real research item of the last block.
	for id:String in Sovereign.SOVEREIGN.keys()+Sovereign.RESTRICTED.keys()+Sovereign.HUMAN_SIGNOFF.keys():
		assert_bool(Catalog.has(id)).override_failure_message(id).is_true()
	# A general holds bombers back from a city assault until the ruler speaks.
	var force:={"formations":[{"unit":"line_infantry","weapon":"service_rifle","count":100},{"unit":"bomber_wing","weapon":"strategic_bomber_equipment","count":20}]}
	var held:=WorldSimulation.military.formations_held_from_city(force)
	assert_int(held.size()).is_equal(1)
	assert_str(String(held[0].weapon)).is_equal("strategic_bomber_equipment")
	# Their use against armies in the field is the general's own call.
	assert_bool(WorldSimulation.military.filter_general_means(["aerial_bombardment"],{"target":"field"}).withheld.is_empty()).is_true()
	# The decision survives a save.
	WorldSimulation.military.sovereign_decisions["aerial_bombardment"]={"source":"court","spoken":"Bomb their capital.","day":3,"audience":"x"}
	assert_bool(WorldSimulation.military.formations_held_from_city(force).is_empty()).is_true()
	assert_bool((WorldSimulation.military.export_state().sovereign_decisions as Dictionary).has("aerial_bombardment")).is_true()
