extends GdUnitTestSuite
## The real 1800-2400 research block (data/research/blocks/y1800_2400.json, built
## by tools/research/build_research_block.py from the design branch): hand
## cannons wait for hand-gun tubes, the later firearms and staff work open at
## their design bands, the four-course rotation waits for its window, maize
## needs contact across the ocean, and prerequisites reaching back into all
## three earlier blocks resolve.
const Catalog=preload("res://scripts/research_600_catalog.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Probe=preload("res://tools/research/research_600_probe.gd")
const Land=preload("res://scripts/military_unit_catalog.gd")
const Extension=preload("res://scripts/military_equipment_extension.gd")
const Voice=preload("res://scripts/character_voice.gd")
const EARLIER:=["y0_600","y600_1200","y1200_1800"]

func before_test()->void:
	WorldSimulation.clear()
	Catalog.use_manifest("")
	GameState.reset_for_new_world(60060);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	Voice.knowledge_override.clear()
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

func _know(ids:Array)->void:
	GameState.known_discoveries.assign(ids)
	for id:Variant in ids:GameState.discovery_adoption[String(id)]=1.0

func _unlocked(gate:String)->bool:
	return bool(MilitaryCampaign._knowledge_gate(gate,0.08).unlocked)

func test_hand_cannons_stay_locked_until_hand_gun_tubes()->void:
	assert_str(Catalog.block_of("hand_gun_tubes")).is_equal("y1800_2400")
	assert_str(Land.gate_for("hand_cannoneer")).is_equal("hand_gun_tubes")
	assert_str(String(Land.EQUIPMENT_GATES.hand_cannon)).is_equal("hand_gun_tubes")
	assert_str(String(Extension.ITEMS.hand_cannon.gate)).is_equal("hand_gun_tubes")
	var tubes:=_entry("hand_gun_tubes")
	assert_array(tubes.requires_all).is_equal(["gun_barrel_founding","pot_bolt_guns"])
	# Gunpowder chemistry, cast barrels and bolt pots are not yet a hand gun.
	GameState.elapsed_days=_day(1830.0)
	_know(["black_powder","gun_barrel_founding","pot_bolt_guns"])
	assert_bool(_unlocked(Land.gate_for("hand_cannoneer"))).is_false()
	assert_bool(_unlocked(String(Land.EQUIPMENT_GATES.hand_cannon))).is_false()
	# Every foundation known still waits for the tubes' band.
	var opens:=DiscoverySystem.research_600_earliest_year(tubes)
	assert_float(opens).is_equal(float(Catalog.item("hand_gun_tubes").band_low))
	assert_bool(_eligible_at(tubes,opens-1.0)).is_false()
	assert_bool(_eligible_at(tubes,opens)).is_true()
	_know(["black_powder","gun_barrel_founding","pot_bolt_guns","hand_gun_tubes"])
	assert_bool(_unlocked(Land.gate_for("hand_cannoneer"))).is_true()
	assert_bool(_unlocked(String(Land.EQUIPMENT_GATES.hand_cannon))).is_true()
	# Bombards need the artillery itself, which the design builds on the tubes
	# without the catalog's staff officers and precision machinery.
	assert_bool(_unlocked(Land.gate_for("bombard_crew"))).is_false()
	var artillery:=Catalog.item("powder_artillery")
	assert_str(Catalog.block_of("powder_artillery")).is_equal("y1800_2400")
	assert_array(artillery.requires_all).is_equal(["hand_gun_tubes","gun_barrel_founding"])
	assert_float(Catalog.redate("powder_artillery")).is_equal(-1.0)
	for dropped:String in ["military_staffs","precision_machinery"]:
		assert_bool((_entry("powder_artillery").requires_all as Array).has(dropped)).is_false()

func test_later_firearms_and_staff_work_open_at_their_design_bands()->void:
	var expected:={"powder_artillery":1848,"matchlock_drill":1920,"naval_gunnery":1936,"mounted_firearms":1976,
		"rifled_barrels":2290,"military_staffs":2320,"precision_machinery":2371,
		"regimental_light_guns":2062,"grenadier_companies":2138,"galloping_horse_artillery":2326,
		"steel_refining":2282,"preventive_inoculation":2302}
	for id:String in expected:
		assert_str(Catalog.block_of(id)).override_failure_message(id).is_equal("y1800_2400")
		assert_float(float(Catalog.item(id).proposed_year)).override_failure_message(id).is_equal(float(expected[id]))
		assert_float(DiscoverySystem.research_600_earliest_year(_entry(id))).override_failure_message(id).is_equal(float(Catalog.item(id).band_low))
		assert_float(DiscoverySystem.research_600_earliest_year(_entry(id))).override_failure_message(id).is_greater(1800.0)
	assert_str(Land.gate_for("field_artillery")).is_equal("regimental_light_guns")
	assert_str(Land.gate_for("grenadier")).is_equal("grenadier_companies")
	assert_str(Land.gate_for("horse_artillery")).is_equal("galloping_horse_artillery")
	assert_str(Land.gate_for("bombard_crew")).is_equal("powder_artillery")
	assert_str(String(Land.EQUIPMENT_GATES.field_gun)).is_equal("regimental_light_guns")
	assert_str(String(Land.EQUIPMENT_GATES.grenadier_kit)).is_equal("grenadier_companies")
	assert_str(String(Land.EQUIPMENT_GATES.horse_gun)).is_equal("galloping_horse_artillery")
	assert_str(String(Extension.ITEMS.grenadier_kit.gate)).is_equal("grenadier_companies")
	assert_str(String(Extension.ITEMS.horse_gun.gate)).is_equal("galloping_horse_artillery")
	# Inoculation follows variolation trials, not germ mapping.
	assert_array(_entry("preventive_inoculation").requires_all).is_equal(["variolation_trials","experimental_controls"])
	# No gunpowder-era unit opens before hand-gun tubes' band.
	var tubes:=float(Catalog.item("hand_gun_tubes").band_low)
	for unit:String in Land.ARCHETYPES:
		if String(Land.archetype(unit).get("era",""))!="gunpowder":continue
		var gate:=Land.gate_for(unit)
		assert_float(DiscoverySystem.research_600_earliest_year(_entry(gate))).override_failure_message("%s <- %s" % [unit,gate]).is_greater_equal(tubes)

func test_gun_words_wait_for_the_guns()->void:
	Voice.knowledge_override["player"]=["black_powder"]
	var tags:=Voice.era_tags("player")
	assert_bool(tags.has("gunpowder")).is_true()
	assert_array(Voice.lexicon_hits("the gun and the cannon",tags)).is_not_empty()
	assert_array(Voice.lexicon_hits("a musket",tags)).is_not_empty()
	Voice.knowledge_override["player"]=["black_powder","hand_gun_tubes"]
	tags=Voice.era_tags("player")
	assert_array(Voice.lexicon_hits("the gun and the cannon",tags)).is_empty()
	assert_array(Voice.lexicon_hits("a musket",tags)).is_not_empty()
	Voice.knowledge_override["player"]=["black_powder","hand_gun_tubes","matchlock_drill"]
	assert_array(Voice.lexicon_hits("a musket",Voice.era_tags("player"))).is_empty()

func test_four_course_rotation_is_locked_before_its_window()->void:
	var rotation:=_entry("four_course_rotation")
	assert_str(Catalog.block_of("four_course_rotation")).is_equal("y1800_2400")
	assert_array(rotation.requires_all).is_equal(["three_field_rotation","clover_ley_fodder","field_turnips"])
	var opens:=DiscoverySystem.research_600_earliest_year(rotation)
	assert_float(opens).is_equal(float(Catalog.item("four_course_rotation").band_low))
	assert_float(opens).is_greater(2200.0)
	GameState.known_discoveries.assign(rotation.requires_all)
	assert_bool(P.ready(rotation,_day(1800))).is_true()
	for year:float in [1800.0,2000.0,2200.0,opens-1.0]:
		assert_bool(DiscoverySystem.research_600_open(rotation,_society(year))).override_failure_message("year %d" % int(year)).is_false()
		assert_bool(_eligible_at(rotation,year)).override_failure_message("year %d" % int(year)).is_false()
	assert_bool(DiscoverySystem.research_600_open(rotation,_society(opens))).is_true()
	assert_array(DiscoverySystem.research_600_missing(rotation,_society(opens))).is_empty()

func test_maize_requires_contact_across_the_ocean()->void:
	for id:String in ["maize_garden_trials","maize_field_crop"]:
		assert_str(Catalog.block_of(id)).override_failure_message(id).is_equal("y1800_2400")
		assert_bool(bool(Catalog.item(id).conditions.get("contact_required",false))).override_failure_message(id).is_true()
	var trials:=_entry("maize_garden_trials")
	assert_array(trials.requires_all).is_equal(["transoceanic_contact_voyages"])
	assert_array(_entry("maize_field_crop").requires_all).is_equal(["maize_garden_trials"])
	var opens:=DiscoverySystem.research_600_earliest_year(trials)
	var alone:=_society(opens);alone.contact=false
	assert_bool(DiscoverySystem.research_600_open(trials,alone)).is_false()
	assert_array(Catalog.unmet_conditions("maize_garden_trials",alone)).is_equal(["Contact with another people"])
	assert_bool(DiscoverySystem.research_600_open(trials,_society(opens))).is_true()
	# Without the ocean voyages the garden trials never become ready.
	GameState.known_discoveries.assign([])
	assert_bool(P.ready(trials,_day(opens))).is_false()
	GameState.known_discoveries.assign(["transoceanic_contact_voyages"])
	assert_bool(P.ready(trials,_day(opens))).is_true()

func test_cross_block_prerequisites_resolve()->void:
	var cross:={"y0_600":0,"y600_1200":0,"y1200_1800":0}
	var unknown:Array[String]=[]
	var forward:Array[String]=[]
	for id:String in Catalog.block_ids("y1800_2400"):
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
	var total:=0
	for block:String in EARLIER:
		assert_int(int(cross[block])).override_failure_message(block).is_greater(0)
		total+=int(cross[block])
	assert_int(total).is_equal(int(Catalog.block_meta("y1800_2400").get("cross_block_references",0)))
	# Earlier blocks never lean on a later one.
	for block:String in EARLIER:
		for id:String in Catalog.block_ids(block):
			var item:=Catalog.item(id)
			var parents:Array=(item.requires_all as Array).duplicate()
			for group:Array in item.requires_any:parents.append_array(group)
			parents.append_array(item.precedents)
			for parent:String in parents:
				assert_str(Catalog.block_of(parent)).override_failure_message("%s <- %s" % [id,parent]).is_not_equal("y1800_2400")
	# A 1800-2400 item waits on its 1200-1800 foundation.
	var tubes:=_entry("hand_gun_tubes")
	assert_str(Catalog.block_of("gun_barrel_founding")).is_equal("y1800_2400")
	assert_str(Catalog.block_of("black_powder")).is_equal("y1200_1800")
	var barrels:=_entry("gun_barrel_founding")
	assert_bool((barrels.requires_all as Array).has("black_powder")).is_true()
	GameState.known_discoveries.assign(["pit_cast_bells"])
	assert_bool(P.ready(barrels,_day(1850))).is_false()
	GameState.known_discoveries.assign(["pit_cast_bells","black_powder"])
	assert_bool(P.ready(barrels,_day(1850))).is_true()
	GameState.known_discoveries.assign(["gun_barrel_founding"])
	assert_bool(P.ready(tubes,_day(1850))).is_false()
