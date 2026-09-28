extends GdUnitTestSuite
## The HOI4-style Production screen: the numbers on screen match the model,
## line order is priority, deficits and levy badges show, and the main surface
## carries numbers and icons rather than paragraphs.
const Logistics=preload("res://scripts/equipment_logistics.gd")
const P=preload("res://scripts/persistent_production.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.resource_stockpiles={"Timber":100.0,"Stone":50.0}
	GameState.population_allocations.Crafting=10;GameState.population_allocations.Logistics=10;GameState.population_allocations.Defense=0
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.settlement_plots=[{"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}}]
	GameState.settlement_name="Workshop Town";GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	for id:String in ["hafted_weapons"]:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0
	MilitaryCampaign.army_templates=[]
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[],.8,.7)
func after_test()->void:WorldSimulation.clear()

static func _formation(unit:String,weapon:String,count:int,equipment:int)->Dictionary:
	return {"id":MilitaryCampaign.next_formation_id,"unit":unit,"weapon":weapon,"count":count,"authorized_count":count,"equipment":equipment,"equipment_required":count,"ammunition":0,"ammunition_required":0,"training":.6,"experience":0.0}

func _levy_at_home(count:int,equipment:int)->void:
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[_formation("levy","improvised",count,equipment)],.8,.7)

# --- Shared logistics numbers ------------------------------------------------------

func test_needs_split_fielded_training_and_called_up()->void:
	_levy_at_home(20,12)
	MilitaryCampaign.training_queue=[{"id":1,"mode":"new","unit":"spearman","weapon":"spear","count":6,"initial_count":6,"progress_days":1.0,"required_days":14.0,"reserved_equipment":2}]
	MilitaryCampaign.military_inventory["improvised"]=3
	MilitaryCampaign.military_inventory["spear"]=1
	var levy:=Logistics.row("improvised")
	assert_int(int(levy.stock)).is_equal(3)
	assert_int(int(levy.fielded)).is_equal(8)
	assert_int(int(levy.needed)).is_equal(8)
	assert_int(int(levy.deficit)).is_equal(5)
	assert_str(String(levy["for"][0].who)).ends_with("levy")
	var spears:=Logistics.row("spear")
	assert_int(int(spears.training)).is_equal(4)
	assert_int(int(spears.deficit)).is_equal(3)
	assert_int(Logistics.deficit("spear")).is_equal(3)
	# Called-up watch: the Defense allocation not yet in drill wants clubs.
	GameState.population_allocations.Defense=25
	var called:=Logistics.row("improvised")
	assert_int(int(called.requisitioned)).is_greater(0)
	assert_int(int(called.needed)).is_equal(int(called.fielded)+int(called.training)+int(called.requisitioned))

static func _room_for_lines(tier:int)->void:
	for domain:String in ["security","production","logistics","institutions"]:ProgressionSystem.domain_levels[domain]=tier

func test_rows_follow_lines_damage_and_stable_order()->void:
	_room_for_lines(2)
	MilitaryCampaign.start_production_line("spear",10)
	MilitaryCampaign.start_production_line("improvised",10)
	MilitaryCampaign.damaged_equipment={"spear":2}
	var rows:=Logistics.rows()
	var names:Array=rows.map(func(row:Dictionary)->String:return String(row.item))
	assert_array(names).contains(["spear","improvised"])
	assert_int(names.find("improvised")).is_less(names.find("spear"))
	var spear:Dictionary=rows[names.find("spear")]
	assert_int(int(spear.damaged)).is_equal(2)
	assert_array(spear.lines).has_size(1)
	assert_str(String(spear.category)).is_equal("weapons")

func test_line_badge_names_the_levy_and_needs_by_force_lists_it()->void:
	_levy_at_home(20,12)
	MilitaryCampaign.start_production_line("improvised",10)
	var line:Dictionary=MilitaryCampaign.production_lines_snapshot().lines[0]
	var badge:=Logistics.line_badge(line)
	assert_str(String(badge.text)).starts_with("for ").ends_with("levy")
	assert_int(int(badge.count)).is_equal(8)
	assert_str(String(badge.tip)).contains("8 at home")
	MilitaryCampaign.military_inventory["improvised"]=8
	assert_dict(Logistics.line_badge(line)).is_empty()
	var forces:=Logistics.needs_by_force()
	assert_int(forces.size()).is_equal(1)
	assert_int(int(forces[0].force_id)).is_equal(0)
	assert_int(int(forces[0].items.improvised)).is_equal(8)

func test_material_trend_reads_the_last_week()->void:
	GameState.elapsed_days=100
	Logistics.note_stores({"Timber":86.0},93)
	var trend:=Logistics.material_trend("Timber")
	assert_int(int(trend.days)).is_equal(7)
	assert_float(float(trend.per_day)).is_equal_approx(2.0,.0001)
	assert_dict(Logistics.material_trend("Clay")).is_empty()
