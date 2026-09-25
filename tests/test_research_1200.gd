extends GdUnitTestSuite
## The real 600-1200 research block (data/research/blocks/y600_1200.json, built
## by tools/research/build_research_block.py from the design branch): era
## windows hold even with every foundation known, iron stays out of the early
## game, and prerequisites that reach back into the 0-600 block resolve.
const Catalog=preload("res://scripts/research_600_catalog.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Probe=preload("res://tools/research/research_600_probe.gd")

func before_test()->void:
	WorldSimulation.clear()
	Catalog.use_manifest("")
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

func _eligible_at(entry:Dictionary,year:float)->bool:
	GameState.elapsed_days=_day(year)
	return DiscoverySystem._discovery_is_eligible(entry,_day(year))

func test_glass_blowing_cannot_unlock_before_its_era_window()->void:
	var glass:=_entry("glass_blowing")
	assert_str(Catalog.block_of("glass_blowing")).is_equal("y600_1200")
	assert_array(glass.requires_all).is_equal(["mandrel_wound_beads","decolorized_clear_glass"])
	var opens:=DiscoverySystem.research_600_earliest_year(glass)
	assert_float(opens).is_equal(float(Catalog.item("glass_blowing").band_low))
	assert_float(opens).is_greater(900.0)
	# Every foundation known still does not open it early.
	GameState.known_discoveries.assign(["mandrel_wound_beads","decolorized_clear_glass"])
	assert_bool(P.ready(glass,_day(700))).is_true()
	for year:float in [100.0,600.0,700.0,opens-1.0]:
		assert_bool(DiscoverySystem.research_600_open(glass,_society(year))).override_failure_message("year %d" % int(year)).is_false()
		assert_bool(_eligible_at(glass,year)).override_failure_message("year %d" % int(year)).is_false()
	assert_bool(DiscoverySystem.research_600_open(glass,_society(opens))).is_true()
	assert_bool(_eligible_at(glass,opens)).is_true()

func test_bloomery_smelting_is_not_available_at_year_100()->void:
	var bloomery:=_entry("bloomery_smelting")
	assert_str(Catalog.block_of("bloomery_smelting")).is_equal("y600_1200")
	assert_float(DiscoverySystem.research_600_earliest_year(bloomery)).is_greater_equal(660.0)
	GameState.known_discoveries.assign(["shaft_furnaces","clay_tuyere_draft"])
	assert_bool(DiscoverySystem.research_600_open(bloomery,_society(100.0))).is_false()
	assert_bool(_eligible_at(bloomery,100.0)).is_false()
	assert_bool(_eligible_at(bloomery,659.0)).is_false()
	# Iron needs its ore as well as its year.
	var society:=_society(660.0)
	assert_bool(DiscoverySystem.research_600_open(bloomery,society)).is_true()
	society.resources={}
	assert_bool(DiscoverySystem.research_600_open(bloomery,society)).is_false()
	# Every 600-1200 design item opens at its own band_low; the earliest band in
	# the block starts at 560, so nothing from it opens in the early game.
	for id:String in Catalog.block_ids("y600_1200"):
		var earliest:=DiscoverySystem.research_600_earliest_year(_entry(id))
		assert_float(earliest).override_failure_message(id).is_equal(float(Catalog.item(id).band_low))
		assert_float(earliest).override_failure_message(id).is_greater_equal(560.0)

func test_cross_block_prerequisites_resolve()->void:
	var cross:=0
	var unknown:Array[String]=[]
	for id:String in Catalog.block_ids("y600_1200"):
		var entry:=_entry(id)
		assert_bool(entry.is_empty()).override_failure_message(id).is_false()
		var item:=Catalog.item(id)
		var parents:Array=(item.requires_all as Array).duplicate()
		for group:Array in item.requires_any:parents.append_array(group)
		parents.append_array(item.precedents)
		for parent:String in parents:
			if not Catalog.has(parent) or _entry(parent).is_empty():unknown.append("%s <- %s" % [id,parent])
			elif Catalog.block_of(parent)=="y0_600":cross+=1
	assert_array(unknown).is_empty()
	assert_int(cross).is_equal(int(Catalog.block_meta("y600_1200").get("cross_block_references",0)))
	assert_int(cross).is_greater(0)
	# A 600-1200 item waits on its 0-600 foundations.
	var bloomery:=_entry("bloomery_smelting")
	assert_str(Catalog.block_of("shaft_furnaces")).is_equal("y0_600")
	GameState.known_discoveries.assign(["clay_tuyere_draft"])
	assert_bool(P.ready(bloomery,_day(700))).is_false()
	GameState.known_discoveries.assign(["clay_tuyere_draft","shaft_furnaces"])
	assert_bool(P.ready(bloomery,_day(700))).is_true()
	# sail_seaming is the 0-600 block's adopted item; the 600-1200 rig builds on it.
	assert_str(Catalog.block_of("sail_seaming")).is_equal("y0_600")
	assert_bool((_entry("brailed_square_sail").requires_all as Array).has("sail_seaming")).is_true()
