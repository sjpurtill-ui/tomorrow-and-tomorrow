extends GdUnitTestSuite
## The real 1200-1800 research block (data/research/blocks/y1200_1800.json, built
## by tools/research/build_research_block.py from the design branch): era
## windows hold even with every foundation known, the chemistry-only black
## powder of this window hands generals no guns, ocean sailing left the 0-600
## block for its own window, and prerequisites reaching back into both earlier
## blocks resolve.
const Catalog=preload("res://scripts/research_600_catalog.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Probe=preload("res://tools/research/research_600_probe.gd")
const Land=preload("res://scripts/military_unit_catalog.gd")
const Extension=preload("res://scripts/military_equipment_extension.gd")
const Joint=preload("res://scripts/joint_force_catalog.gd")

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

func test_printing_process_cannot_open_before_its_window()->void:
	var printing:=_entry("printing_process")
	assert_str(Catalog.block_of("printing_process")).is_equal("y1200_1800")
	assert_array(printing.requires_all).is_equal(["relief_block_cutting","paper_making"])
	var opens:=DiscoverySystem.research_600_earliest_year(printing)
	assert_float(opens).is_equal(float(Catalog.item("printing_process").band_low))
	assert_float(opens).is_greater(1300.0)
	# Every foundation known still does not open it early.
	GameState.known_discoveries.assign(["relief_block_cutting","paper_making"])
	assert_bool(P.ready(printing,_day(1000))).is_true()
	for year:float in [600.0,1082.0,1200.0,opens-1.0]:
		assert_bool(DiscoverySystem.research_600_open(printing,_society(year))).override_failure_message("year %d" % int(year)).is_false()
		assert_bool(_eligible_at(printing,year)).override_failure_message("year %d" % int(year)).is_false()
	# At its band the era gate and design conditions let it through.
	assert_bool(DiscoverySystem.research_600_open(printing,_society(opens))).is_true()
	assert_array(DiscoverySystem.research_600_missing(printing,_society(opens))).is_empty()

func test_blast_furnace_is_closed_at_year_1200()->void:
	var furnace:=_entry("blast_furnace")
	assert_str(Catalog.block_of("blast_furnace")).is_equal("y1200_1800")
	var opens:=DiscoverySystem.research_600_earliest_year(furnace)
	assert_float(opens).is_equal(float(Catalog.item("blast_furnace").band_low))
	assert_float(opens).is_greater(1700.0)
	GameState.known_discoveries.assign(furnace.requires_all)
	assert_bool(P.ready(furnace,_day(1200))).is_true()
	assert_bool(DiscoverySystem.research_600_open(furnace,_society(1200.0))).is_false()
	assert_bool(_eligible_at(furnace,1200.0)).is_false()
	assert_bool(_eligible_at(furnace,opens-1.0)).is_false()
	assert_bool(DiscoverySystem.research_600_open(furnace,_society(opens))).is_true()

func test_black_powder_does_not_unlock_hand_cannons()->void:
	assert_str(Catalog.block_of("black_powder")).is_equal("y1200_1800")
	assert_float(DiscoverySystem.research_600_earliest_year(_entry("black_powder"))).is_greater(1750.0)
	# Hand cannons wait for a gunpowder weapon (the 1800-2400 design's hand-gun
	# tubes), not the chemistry.
	assert_str(Land.gate_for("hand_cannoneer")).is_equal("hand_gun_tubes")
	assert_str(String(Land.EQUIPMENT_GATES.hand_cannon)).is_equal("hand_gun_tubes")
	assert_str(String(Extension.ITEMS.hand_cannon.gate)).is_equal("hand_gun_tubes")
	for unit:String in Land.ARCHETYPES:
		assert_str(Land.gate_for(unit)).override_failure_message(unit).is_not_equal("black_powder")
	for item:String in Land.EQUIPMENT_GATES:
		assert_str(String(Land.EQUIPMENT_GATES[item])).override_failure_message(item).is_not_equal("black_powder")
	for item:String in Extension.ITEMS:
		assert_str(String(Extension.ITEMS[item].get("gate",""))).override_failure_message(item).is_not_equal("black_powder")
	# Knowing black powder at the end of the window leaves the guns locked.
	GameState.elapsed_days=_day(1799.0)
	GameState.known_discoveries.assign(["black_powder"])
	GameState.discovery_adoption["black_powder"]=1.0
	assert_bool(bool(MilitaryCampaign._knowledge_gate(Land.gate_for("hand_cannoneer"),0.10).unlocked)).is_false()
	assert_bool(bool(MilitaryCampaign._knowledge_gate(String(Land.EQUIPMENT_GATES.hand_cannon),0.08).unlocked)).is_false()
	# powder_artillery itself stays outside this window: the 1800-2400 design
	# places it (1848, band from 1818), which replaced the old redate floor.
	var artillery:=_entry("powder_artillery")
	assert_str(Catalog.block_of("powder_artillery")).is_equal("y1800_2400")
	assert_float(DiscoverySystem.research_600_earliest_year(artillery)).is_greater_equal(1800.0)
	GameState.known_discoveries.assign(artillery.get("requires_all",artillery.get("requires",[])))
	assert_bool(_eligible_at(artillery,1799.0)).is_false()
	# No land unit or equipment that fires powder opens before black powder's
	# design year. The earliest, hand-gun tubes, has band 1792-1852.
	var powder:=float(Catalog.item("black_powder").proposed_year)
	for unit:String in Land.ARCHETYPES:
		if String(Land.archetype(unit).get("era",""))!="gunpowder":continue
		var gate:=Land.gate_for(unit)
		assert_float(DiscoverySystem.research_600_earliest_year(_entry(gate))).override_failure_message("%s <- %s" % [unit,gate]).is_greater(powder)

func test_ocean_sailing_is_not_available_at_year_560()->void:
	var sailing:=_entry("ocean_sailing")
	assert_str(Catalog.block_of("ocean_sailing")).is_equal("y1200_1800")
	assert_bool(Catalog.block_ids("y0_600").has("ocean_sailing")).is_false()
	assert_array(sailing.requires_all).is_equal(["open_sea_cargo_ships","floating_needle_compass"])
	var opens:=DiscoverySystem.research_600_earliest_year(sailing)
	assert_float(opens).is_equal(float(Catalog.item("ocean_sailing").band_low))
	assert_float(opens).is_greater(1600.0)
	# Its old 0-600 foundations no longer open it at 560.
	GameState.known_discoveries.assign(["coastal_watercraft","rope_rigging","regional_maps","island_hopping_sailing"])
	assert_bool(P.ready(sailing,_day(560))).is_false()
	GameState.known_discoveries.assign(["open_sea_cargo_ships","floating_needle_compass"])
	assert_bool(DiscoverySystem.research_600_open(sailing,_society(560.0))).is_false()
	assert_bool(_eligible_at(sailing,560.0)).is_false()
	assert_bool(_eligible_at(sailing,opens-1.0)).is_false()
	assert_bool(_eligible_at(sailing,opens)).is_true()
	# Sailing warships and convoys move with it.
	assert_str(String(Land.EQUIPMENT_GATES.sailing_warship_equipment)).is_equal("ocean_sailing")
	assert_str(String(Land.EQUIPMENT_GATES.convoy_transport_equipment)).is_equal("ocean_sailing")
	assert_str(String(Joint.UNITS.sailing_warship.gate)).is_equal("ocean_sailing")
	# Its effects now come from this block's effect files.
	assert_float(float(Catalog.effect_row("ocean_sailing").get("effects",{}).get("warfare_readiness",0.0))).is_greater(0.0)

func test_cross_block_prerequisites_resolve()->void:
	var cross:={"y0_600":0,"y600_1200":0}
	var unknown:Array[String]=[]
	var forward:Array[String]=[]
	for id:String in Catalog.block_ids("y1200_1800"):
		var entry:=_entry(id)
		assert_bool(entry.is_empty()).override_failure_message(id).is_false()
		var item:=Catalog.item(id)
		var parents:Array=(item.requires_all as Array).duplicate()
		for group:Array in item.requires_any:parents.append_array(group)
		parents.append_array(item.precedents)
		for parent:String in parents:
			if not Catalog.has(parent) or _entry(parent).is_empty():unknown.append("%s <- %s" % [id,parent])
			elif cross.has(Catalog.block_of(parent)):cross[Catalog.block_of(parent)]+=1
		for parent:String in item.requires_all:
			if Catalog.has(parent) and float(Catalog.item(parent).proposed_year)>float(item.proposed_year):forward.append("%s <- %s" % [id,parent])
	assert_array(unknown).is_empty()
	assert_array(forward).is_empty()
	assert_int(int(cross.y0_600)).is_greater(0)
	assert_int(int(cross.y600_1200)).is_greater(0)
	assert_int(int(cross.y0_600)+int(cross.y600_1200)).is_equal(int(Catalog.block_meta("y1200_1800").get("cross_block_references",0)))
	# Earlier blocks never lean on a later one.
	for block:String in ["y0_600","y600_1200"]:
		for id:String in Catalog.block_ids(block):
			var item:=Catalog.item(id)
			var parents:Array=(item.requires_all as Array).duplicate()
			for group:Array in item.requires_any:parents.append_array(group)
			parents.append_array(item.precedents)
			for parent:String in parents:
				assert_str(Catalog.block_of(parent)).override_failure_message("%s <- %s" % [id,parent]).is_not_equal("y1200_1800")
	# A 1200-1800 item waits on its 600-1200 foundations.
	var printing:=_entry("printing_process")
	assert_str(Catalog.block_of("paper_making")).is_equal("y600_1200")
	GameState.known_discoveries.assign(["relief_block_cutting"])
	assert_bool(P.ready(printing,_day(1400))).is_false()
	GameState.known_discoveries.assign(["relief_block_cutting","paper_making"])
	assert_bool(P.ready(printing,_day(1400))).is_true()
