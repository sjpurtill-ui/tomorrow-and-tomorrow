extends GdUnitTestSuite
## THE EQUIPMENT LEDGER (scripts/equipment_ledger.gd): one row per land kit.
## Battle stats, recipes, crews, rounds and supply burdens all come from it;
## the gate each kit needs stays in military_unit_catalog.EQUIPMENT_GATES and
## the ledger's year sits at that gate's research year.

const Ledger:=preload("res://scripts/equipment_ledger.gd")
const Combat:=preload("res://scripts/combat_simulator.gd")
const Extension:=preload("res://scripts/military_equipment_extension.gd")
const Catalog:=preload("res://scripts/military_unit_catalog.gd")
const Armor:=preload("res://scripts/armor_equipment.gd")
const Goods:=preload("res://scripts/goods_bills.gd")
const Production:=preload("res://scripts/persistent_production.gd")

func _research_years()->Dictionary:
	var years:={}
	for file:String in DirAccess.get_files_at("res://data/research/blocks"):
		if not file.ends_with(".json"): continue
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/research/blocks/"+file))
		for item:Dictionary in (parsed as Dictionary).get("items",[]): years[String(item.id)]=float(item.target_year)
	return years

func test_every_land_kit_the_simulator_knows_has_one_row()->void:
	for id:String in Combat.WEAPONS:
		assert_bool(Ledger.has(id)).override_failure_message(id).is_true()
		var row:=Ledger.row(id)
		assert_str(String(row.get("family",""))).override_failure_message(id).is_not_empty()
		assert_bool(Ledger.FAMILIES.has(String(row.family))).override_failure_message(id).is_true()
	for id:String in Ledger.KITS:
		assert_bool(Combat.WEAPONS.has(id)).override_failure_message(id).is_true()
		assert_bool(Extension.ITEMS.has(id)).override_failure_message(id).is_true()

func test_the_simulator_and_production_read_the_same_row()->void:
	for id:String in Ledger.KITS:
		var row:Dictionary=Ledger.KITS[id]
		assert_float(float(Combat.WEAPONS[id].attack)).is_equal(float(row.attack))
		assert_float(float(Combat.WEAPONS[id].penetration)).is_equal(float(row.penetration))
		assert_dict(Extension.ITEMS[id].materials as Dictionary).is_equal(row.materials)
		assert_str(String(Extension.ITEMS[id].gate)).is_equal(String(Catalog.EQUIPMENT_GATES.get(id,"")))

func test_rows_are_sane()->void:
	for id:String in Ledger.KITS:
		var row:Dictionary=Ledger.KITS[id]
		assert_float(float(row.crew)).override_failure_message(id).is_greater(0.0)
		assert_float(float(row.crewless)).override_failure_message(id).is_between(0.0,1.0)
		assert_float(float(row.supply)).override_failure_message(id).is_greater_equal(0.0)
		assert_float(float(row.days)).override_failure_message(id).is_greater(0.0)
		assert_float(float(row.defense)).override_failure_message(id).is_greater(0.0)
		if String(row.ammo)!="": assert_int(int(row.ammo_per)).override_failure_message(id).is_greater(0)
		# No bill is so deep that a whole late army could never be made.
		var flat:Dictionary=Goods.flatten(row.materials)
		assert_float(float(flat.get("Civilian Goods",0.0))).override_failure_message(id).is_less_equal(100.0)

func test_each_kit_appears_when_its_gate_is_researched()->void:
	var years:=_research_years()
	for id:String in Ledger.KITS:
		var gate:=String(Catalog.EQUIPMENT_GATES.get(id,""))
		if gate=="" or not years.has(gate): continue
		assert_float(Ledger.year(id)).override_failure_message("%s: ledger %d, gate %s %d" % [id,Ledger.year(id),gate,years[gate]]).is_between(float(years[gate])-40.0,float(years[gate])+40.0)

func test_late_kits_hang_on_real_late_research()->void:
	var years:=_research_years()
	for id in ["main_battle_tank","networked_rifle","precision_launcher","drone_team","laser_point_defence","robotic_vehicle","exosuit","combat_frame"]:
		var gate:=String(Catalog.EQUIPMENT_GATES.get(id,""))
		assert_bool(years.has(gate)).override_failure_message("%s gate %s" % [id,gate]).is_true()
		assert_float(float(years[gate])).is_greater(2800.0)

func _per_set(id:String)->float:
	var row:=Ledger.row(id)
	return sqrt(float(row.attack)*float(row.defense))*float(row.crew)

func test_ladders_climb_where_history_does()->void:
	# Early firearms were not deadlier per man than bows; their edge was pierce.
	assert_float(float(Ledger.row("musket").attack)).is_less(float(Ledger.row("bow").attack)+0.01)
	assert_float(float(Ledger.row("musket").penetration)).is_greater(float(Ledger.row("crossbow").penetration))
	assert_float(float(Ledger.row("hand_cannon").attack)).is_less(float(Ledger.row("musket").attack))
	assert_float(float(Ledger.row("musket").attack)).is_less(float(Ledger.row("service_rifle").attack))
	assert_float(float(Ledger.row("service_rifle").attack)).is_less(float(Ledger.row("networked_rifle").attack))
	for pair in [["light_tank_kit","armored_vehicle"],["armored_vehicle","heavy_tank_kit"],["heavy_tank_kit","main_battle_tank"]]:
		assert_float(_per_set(pair[0])).override_failure_message(str(pair)).is_less(_per_set(pair[1]))
		assert_float(float(Ledger.row(pair[0]).armor)).is_less(float(Ledger.row(pair[1]).armor))
	# Plate is the armour scale the armor kits already use.
	assert_float(float(Armor.KITS.plate_spear.armor)).is_less(float(Ledger.row("light_tank_kit").armor))

func test_supply_burden_grows_by_age()->void:
	# Loads a man a day beyond his bread: bows almost nothing, rifles a little,
	# tank crews a great deal, main battle tanks the most.
	var per_man:=func(id:String)->float: return Ledger.supply(id)/Ledger.crew(id)
	assert_float(per_man.call("bow")).is_less(0.1)
	assert_float(per_man.call("service_rifle")).is_between(1.0,3.0)
	assert_float(per_man.call("armored_vehicle")).is_greater(20.0)
	assert_float(per_man.call("main_battle_tank")).is_greater(per_man.call("heavy_tank_kit"))

func test_crews_below_one_man_run_several_machines()->void:
	var sim=Combat.new()
	assert_int(sim.equipment_required_for_weapon("machine_gun",16)).is_equal(2)
	assert_int(sim.equipment_required_for_weapon("machine_gun",17)).is_equal(3)
	assert_int(sim.equipment_required_for_weapon("spear",100)).is_equal(100)
	assert_int(sim.equipment_required_for_weapon("combat_frame",1)).is_equal(8)
	assert_int(sim.equipment_required_for_weapon("robotic_vehicle",3)).is_equal(9)
	assert_int(sim.equipment_required_for_weapon("robotic_vehicle",0)).is_equal(0)
	assert_str(Combat.ammo_type("musket")).is_equal("artillery_rounds")
	assert_str(Combat.ammo_type("service_rifle")).is_equal("small_arms_ammunition")
	assert_int(Combat.ammo_per("spear")).is_equal(0)

func test_retooling_keeps_skill_by_family()->void:
	assert_float(Ledger.retention("musket","musket")).is_equal(1.0)
	assert_float(Ledger.retention("musket","service_rifle")).is_equal(Ledger.KEEP_FAMILY)
	assert_float(Ledger.retention("spear","armored_vehicle")).is_equal(Ledger.KEEP_LAND)
	assert_float(Production.retool_retention("spear","arrows","production","consumable")).is_equal(.35)
	assert_float(Production.retool_retention("service_rifle","assault_kit","production","production")).is_equal(Ledger.KEEP_FAMILY)
