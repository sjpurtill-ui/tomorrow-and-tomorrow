extends GdUnitTestSuite
const Stores:=preload("res://scripts/storage_works.gd")
const Build:=preload("res://scripts/settlement_construction.gd")
const Grid:=preload("res://scripts/hud/storage_capacity_grid.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(6409)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"]
	GameState.population_allocations.merge({"Construction":20,"Logistics":20,"Crafting":10},true)
	GameState.resource_stockpiles={}
	GameState.food_stocks={"Fresh food":0.0,"Stored food":0.0}
	GameState.storage_works={}

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func project(kind:String)->Dictionary:
	for candidate:Dictionary in Stores.projects():
		if candidate.storage_kind==kind:return candidate
	return {}

func test_each_type_builds_repeatedly_pays_once_and_increases_only_its_own_capacity()->void:
	for kind:String in Stores.KINDS:
		for batch:int in 2:
			var p:=project(kind)
			GameState.resource_stockpiles=p.materials.duplicate(true)
			var before:=Stores.capacities()
			assert_bool(Stores.queue(kind).has("ok")).is_true()
			GameState.settlement_projects[p.name]=float(p.days)
			var events:=Build.process_day()
			assert_int(events.size()).override_failure_message(kind).is_equal(1)
			assert_float(Stores.added(kind)).is_equal(float(p.capacity_added)*(batch+1))
			var after:=Stores.capacities()
			assert_float(float(after[kind])).is_greater(float(before[kind]))
			for other:String in Stores.KINDS:
				if other!=kind:assert_float(float(after[other])).is_equal_approx(float(before[other]),.00001)
			for item:String in p.materials:assert_float(float(GameState.resource_stockpiles.get(item,0))).is_zero()
			assert_bool(Stores.requested(kind)).is_false()
			assert_bool(GameState.settlement_completed.has(p.name)).is_false()
			assert_bool(GameState.settlement_projects.has(p.name)).is_false()

func test_full_bucket_auto_builds_even_when_other_storage_is_empty()->void:
	var cap:=Stores.capacities()
	GameState.resource_stockpiles={"Fiber Plants":float(cap.dry)/.45*.9,"Timber":20.0,"Clay":20.0,"Stone":20.0}
	assert_bool(Stores.needed("dry",Stores.used(),Stores.capacities())).is_true()
	assert_bool(Stores.needed("sealed",Stores.used(),Stores.capacities())).is_false()
	var chosen:=Build._current_settlement_project()
	assert_str(String(chosen.get("storage_kind",""))).is_equal("dry")
	GameState.settlement_projects[chosen.name]=float(chosen.days)
	Build.process_day()
	assert_bool(Stores.needed("dry",Stores.used(),Stores.capacities())).is_false()

func test_no_materials_or_builders_blocks_work_and_says_why()->void:
	Stores.queue("secure")
	GameState.population_allocations.Construction=0
	assert_str(String(Stores.rows(["secure"])[0].status)).is_equal("Needs builders")
	assert_bool(Build._settlement_project_available(project("secure"))).is_false()
	GameState.population_allocations.Construction=20
	assert_str(String(Stores.rows(["secure"])[0].status)).contains("Needs").contains("timber")
	Build.process_day()
	assert_float(Stores.added("secure")).is_zero()
	assert_bool(Stores.requested("secure")).is_true()

func test_real_food_and_material_loss_limits_use_new_capacity()->void:
	GameState.founding_manifest.food_storage_rations=0.0
	GameState.settlement_completed=["Hearth Circle"]
	GameState.food_stocks={"Fresh food":0.0,"Stored food":500.0}
	assert_float(float(FoodSystem._apply_storage_capacity().get("Stored food",0))).is_equal(500.0)
	Stores.complete(project("food"))
	GameState.food_stocks["Stored food"]=500.0
	assert_dict(FoodSystem._apply_storage_capacity()).is_empty()
	GameState.resource_stockpiles={"Bitumen":25.0}
	var before:=ResourceSystem._apply_material_storage_losses([])
	GameState.resource_stockpiles={"Bitumen":25.0}
	Stores.complete(project("sealed"))
	var after:=ResourceSystem._apply_material_storage_losses([])
	assert_float(float(after.total)).is_less(float(before.total))

func test_jobs_lock_their_bill_and_capacity_as_population_changes()->void:
	var p:=project("water")
	Stores.begin(p)
	GameState.population_exact=20000
	assert_dict(project("water")).is_equal(p)

func test_capacity_queue_and_progress_survive_reflected_save_round_trip()->void:
	Stores.complete(project("yard"));Stores.queue("dry");Stores.begin(project("dry"))
	GameState.settlement_projects[Stores.title("dry")]=1.25
	var before:Dictionary=GameState.storage_works.duplicate(true)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(SaveSystem._capture_reflected(GameState,[])))
	GameState.storage_works=saved.storage_works
	assert_float(Stores.added("yard")).is_equal(float(before.capacity.yard))
	assert_bool(Stores.requested("dry")).is_true()
	assert_float(float(project("dry").capacity_added)).is_equal(float(before.jobs.dry.capacity_added))
	assert_float(float(saved.settlement_projects[Stores.title("dry")])).is_equal(1.25)

func test_rivals_keep_separate_storage_ledgers()->void:
	WorldSimulation.create_actor("storage_a",11);WorldSimulation.create_actor("storage_b",12)
	WorldSimulation.scoped("storage_a",func():Stores.complete(project("dry")))
	WorldSimulation.scoped("storage_b",func():assert_float(Stores.added("dry")).is_zero())
	assert_float(Stores.added("dry")).is_zero()
	WorldSimulation.scoped("storage_a",func():assert_float(Stores.added("dry")).is_greater(0))

func test_all_seven_tiles_remain_visible_and_dispatch_correct_expansion()->void:
	var panel=auto_free(Grid.new())
	var chosen:Array=[]
	panel.fill(Stores.rows(),func(kind:String):chosen.append(kind))
	assert_int(panel.tiles.size()).is_equal(7)
	panel.tiles.sealed.button.pressed.emit()
	assert_array(chosen).contains_exactly(["sealed"])
	Stores.queue("sealed")
	panel.fill(Stores.rows(),func(kind:String):chosen.append(kind))
	assert_bool(panel.tiles.sealed.button.disabled).is_true()
	assert_str(panel.tiles.sealed.status.text).contains("Needs")

func test_secondary_town_expansion_never_adds_to_capital()->void:
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"store_town","name":"Rivermeet","position":Vector2(9,4),"primary":false,"population_share":0.2,"founded_day":0})
	SettlementModel.with_city_resources("store_town",func():Stores.queue("water");Stores.complete(project("water")))
	assert_float(Stores.added("water")).is_zero()
	var local_capacity:float=SettlementModel.with_city_resources("store_town",Stores.added.bind("water"))
	assert_float(local_capacity).is_greater(0.0)

func test_construction_page_priority_queues_a_repeat_job_and_tracker_observes_completion()->void:
	SettlementModel.ensure_founded()
	var id:=GameState.selected_player_settlement_id
	var p:=project("yard")
	var result:=Build.set_priority(id,String(p.name))
	assert_bool(result.has("ok")).is_true()
	assert_bool(Stores.requested("yard")).is_true()
	var refs:={"kind":"yard","before":Stores.added("yard"),"settlement_id":id}
	Stores.complete(p)
	assert_str(String(preload("res://scripts/order_probes.gd").read({"kind":"storage","refs":refs}).state)).is_equal("done")

func test_storage_tiles_fit_a_narrow_panel_without_a_dropdown()->void:
	var host:Control=auto_free(Control.new())
	host.size=Vector2(360,1000);add_child(host)
	var panel:=Grid.new();host.add_child(panel);panel.size=Vector2(360,900)
	panel.fill(Stores.rows(),func(_kind:String):pass)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(panel.grid.columns).is_equal(1)
	assert_float(panel.get_combined_minimum_size().x).is_less_equal(360.0)
	assert_int(panel.tiles.size()).is_equal(7)

func test_daily_builders_expand_all_full_store_types_without_changing_allocations()->void:
	GameState.population_allocations.merge({"Construction":80,"Logistics":20,"Crafting":20},true)
	GameState.housing_capacity=1000
	var room:=Stores.capacities()
	GameState.food_stocks={"Fresh food":0.0,"Stored food":float(room.food)*.9}
	GameState.resource_stockpiles={"Freshwater":float(room.water)*.9,"Timber":float(room.yard)*.9/1.35,"Fiber Plants":float(room.dry)*.9/.45,"Clay":float(room.covered)*.9/1.25,"Bitumen":float(room.sealed)*.9/.85,"Coin":float(room.secure)*.9/.05,"Stone":40.0}
	var allocation:Dictionary=GameState.population_allocations.duplicate(true)
	var delivered:Dictionary=GameState.resource_stockpiles.duplicate(true)
	for day:int in 90:
		# Continuing deliveries replace building inputs. Without them, using
		# clay/fiber itself frees storage and correctly cancels automatic demand.
		for item:String in delivered:GameState.resource_stockpiles[item]=maxf(float(GameState.resource_stockpiles.get(item,0)),float(delivered[item]))
		GameState.elapsed_days=day+1
		Build.process_day()
	for kind:String in Stores.KINDS:
		assert_float(Stores.added(kind)).override_failure_message(kind).is_greater(0)
	assert_dict(GameState.population_allocations).is_equal(allocation)

func test_expansion_reading_exposes_exact_bill_and_capacity_without_mutation()->void:
	var before:=GameState.storage_works.duplicate(true)
	var panel=auto_free(Grid.new());var rows:=Stores.rows();panel.fill(rows,func(_kind:String):pass)
	for row:Dictionary in rows:
		assert_float(float(row.capacity_after)).is_equal(float(row.capacity)+float(row.added))
		assert_int(row.costs.size()).is_greater(0)
		for cost:Dictionary in row.costs:
			assert_float(float(cost.have)).is_equal(float(GameState.resource_stockpiles.get(cost.resource,0)))
		assert_int(panel.tiles[row.kind].bill.get_child_count()).is_equal(row.costs.size())
	assert_dict(GameState.storage_works).is_equal(before)
