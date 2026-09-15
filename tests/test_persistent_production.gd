extends GdUnitTestSuite
class DockHud extends Control:
	func request_immediate_dock_refresh()->void:pass
class DockTerrain extends Node:
	var result:Dictionary={}
	func _report_military_action(value:Dictionary)->void:result=value

const Production=preload("res://scripts/persistent_production.gd")

func before_test()->void:
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world()
	GameState.resource_stockpiles["Timber"]=100.0
	GameState.population_allocations["Crafting"]=100
	GameState.population_allocations["Logistics"]=100
	GameState.population_health=1.0
	GameState.simulation_metrics["labor_efficiency"]=1.0
	GameState.settlement_plots.clear()
	GameState.settlement_plots.append({"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}})
	MilitaryCampaign.military_inventory["improvised"]=0

func start(target:int=0)->Dictionary:
	var result:=MilitaryCampaign.start_production_line("improvised",target)
	assert_bool(result.has("ok")).is_true()
	return MilitaryCampaign.equipment_queue.back()

func test_shortage_waits_then_consumes_only_actual_fractional_work()->void:
	var job:=start()
	GameState.resource_stockpiles.Timber=0.0
	Production.advance(MilitaryCampaign,job,100)
	assert_float(float(job.progress_days)).is_equal(0.0)
	assert_int(int(job.completed)).is_equal(0)
	GameState.resource_stockpiles.Timber=.175
	Production.advance(MilitaryCampaign,job,100)
	assert_float(float(job.progress_days)/float(job.work_per_item)).is_equal_approx(.5,.000001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(0,.000001)
	GameState.resource_stockpiles.Timber=.175
	Production.advance(MilitaryCampaign,job,100)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(1)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)

func test_target_persists_and_resumes_after_goods_are_issued()->void:
	var job:=start(5)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(100.0)
	Production.advance(MilitaryCampaign,job,100000)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(5)
	assert_str(Production.state(MilitaryCampaign,job)).is_equal("Target met")
	assert_float(MilitaryCampaign.civilian_crafting_fraction()).is_equal(1.0)
	MilitaryCampaign.military_inventory.improvised=3
	Production.advance(MilitaryCampaign,job,100000)
	assert_int(int(job.completed)).is_equal(7)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(5)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(100-7*.35,.000001)

func test_pause_zero_share_and_zero_workers_do_not_make_goods()->void:
	var job:=start()
	MilitaryCampaign.configure_production_line(int(job.id),0,true)
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(job.last_work)).is_equal(0.0)
	assert_float(MilitaryCampaign.civilian_crafting_fraction()).is_equal(1.0)
	MilitaryCampaign.configure_production_line(int(job.id),0,false)
	MilitaryCampaign.set_production_labor_share(0)
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(job.last_work)).is_equal(0.0)
	MilitaryCampaign.set_production_labor_share(.5)
	GameState.population_allocations.Crafting=0
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(job.last_work)).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(100.0)

func test_priority_shares_one_workforce_and_scarce_inputs()->void:
	var low:=start()
	# An established second line isolates allocation from era capacity gates.
	var high:=low.duplicate(true);high.id=int(low.id)+1;high.allocation=4.0
	MilitaryCampaign.equipment_queue.append(high)
	MilitaryCampaign.set_production_labor_share(.5)
	var budget:=MilitaryCampaign._production_rate()
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(high.last_work)/float(low.last_work)).is_equal_approx(4,.00001)
	assert_float(float(high.last_work)+float(low.last_work)).is_equal_approx(budget*.2,.00001)
	assert_float(MilitaryCampaign.civilian_crafting_fraction()).is_equal(.5)
	GameState.resource_stockpiles.Timber=.0001
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(high.last_work)).is_greater(0)
	assert_float(float(low.last_work)).is_equal(0.0)

func test_health_and_destroyed_workplaces_reduce_real_output()->void:
	start()
	var healthy:=MilitaryCampaign._production_rate()
	GameState.population_health=.5
	assert_float(MilitaryCampaign._production_rate()).is_equal_approx(healthy*.5,.000001)
	GameState.population_health=1
	GameState.settlement_plots[0].damage={"structural":1.0}
	assert_float(MilitaryCampaign._production_rate()).is_equal(0.0)
	GameState.settlement_plots[0].damage={}
	GameState.population_allocations.Logistics=0
	assert_float(MilitaryCampaign._production_rate()).is_less(healthy)

func test_retool_and_close_do_not_refund_consumed_materials()->void:
	var job:=start()
	Production.advance(MilitaryCampaign,job,float(job.work_per_item)*1.5)
	job.efficiency=.8
	var timber:=float(GameState.resource_stockpiles.Timber)
	assert_bool(MilitaryCampaign.retool_production_line(int(job.id),"arrows").has("error")).is_true()
	assert_float(float(job.efficiency)).is_equal(.8)
	GameState.known_discoveries.append("bow_craft");GameState.discovery_adoption.bow_craft=1.0
	assert_bool(MilitaryCampaign.retool_production_line(int(job.id),"arrows").has("ok")).is_true()
	assert_float(float(job.efficiency)).is_equal_approx(.28,.000001)
	assert_float(float(job.progress_days)).is_equal(0.0)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(1)
	MilitaryCampaign.cancel_equipment_job(int(job.id))
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(timber)

func test_save_round_trip_preserves_partial_work_and_future_output()->void:
	var job:=start(20)
	Production.advance(MilitaryCampaign,job,float(job.work_per_item)*.4)
	MilitaryCampaign.set_production_labor_share(.75)
	var saved:=MilitaryCampaign.export_state().duplicate(true)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	MilitaryCampaign._process_equipment_production_day()
	var expected:=MilitaryCampaign.equipment_queue.duplicate(true)
	var expected_stocks:=GameState.resource_stockpiles.duplicate(true)
	assert_bool(MilitaryCampaign.import_state(saved).has("error")).is_false()
	GameState.resource_stockpiles=stocks
	MilitaryCampaign._process_equipment_production_day()
	assert_array(MilitaryCampaign.equipment_queue).is_equal(expected)
	assert_dict(GameState.resource_stockpiles).is_equal(expected_stocks)
	assert_float(MilitaryCampaign.production_labor_share).is_equal(.75)

func test_invalid_save_and_priority_leave_live_state_untouched()->void:
	var job:=start()
	var saved:=MilitaryCampaign.export_state().duplicate(true)
	var bad:=saved.duplicate(true);bad.equipment_queue[0].allocation=NAN
	assert_bool(MilitaryCampaign.import_state(bad).has("error")).is_true()
	assert_dict(MilitaryCampaign.export_state()).is_equal(saved)
	assert_bool(MilitaryCampaign.set_production_line_allocation(int(job.id),NAN).has("error")).is_true()
	assert_str(Production.validate_saved({"equipment_queue":42})).is_not_empty()

func test_ammunition_and_transport_feed_existing_stores()->void:
	GameState.resource_stockpiles["Cart Assembly Kits"]=2.0
	for item:String in ["arrows","transport_cart"]:
		MilitaryCampaign.equipment_queue.clear()
		for discovery:String in ["bow_craft","joinery"]:
			if discovery not in GameState.known_discoveries:GameState.known_discoveries.append(discovery)
			GameState.discovery_adoption[discovery]=1.0
		GameState.resource_stockpiles["Fiber Plants"]=100.0;GameState.resource_stockpiles.Stone=100.0
		assert_bool(MilitaryCampaign.start_production_line(item,0).has("ok")).is_true()
		var job:Dictionary=MilitaryCampaign.equipment_queue.back()
		var prior:=Production.stock(MilitaryCampaign,job)
		Production.advance(MilitaryCampaign,job,float(job.work_per_item)*2)
		assert_int(Production.stock(MilitaryCampaign,job)).is_equal(prior+2)

func test_main_supply_dock_defaults_to_persistent_controls()->void:
	var terrain:=DockTerrain.new();var hud:=DockHud.new()
	var provider:=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
	var report:Dictionary=provider._supply_order_report("equipment","improvised")
	assert_str(str(report)).contains("START PRODUCTION LINE")
	report.blocks.back().items[0].on_press.call()
	assert_bool(terrain.result.has("ok")).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	assert_bool(bool(job.persistent)).is_true()
	assert_int(int(job.target_stock)).is_equal(5)
	var controls:Dictionary=provider._workshop_job_report(int(job.id))
	assert_str(str(controls)).contains("RETOOL LINE")
	controls.blocks.back().items[0].on_press.call()
	assert_bool(bool(job.paused)).is_true()
	MilitaryCampaign.configure_production_line(int(job.id),0,false)
	provider=null;terrain.free();hud.free()
	var panel:=preload("res://scripts/production_lines_panel.gd").new()
	add_child(panel);panel.refresh(true)
	assert_str(panel.details.text).contains("forecast")
	panel.free()
	await get_tree().process_frame # Board rebuild retires controls after input delivery.
	assert_object(load("res://scripts/military_command_ui.gd")).is_not_null()

func test_paused_lines_keep_practice_and_batch_share_respects_player_setting()->void:
	var job:=start()
	job.efficiency=.8
	MilitaryCampaign.configure_production_line(int(job.id),0,true)
	for day in 100:MilitaryCampaign._process_equipment_production_day()
	assert_float(float(job.efficiency)).is_equal(.8)
	MilitaryCampaign.cancel_equipment_job(int(job.id))
	MilitaryCampaign.queue_equipment_production("improvised",5)
	MilitaryCampaign.set_production_labor_share(0)
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(MilitaryCampaign.equipment_queue[0].progress_days)).is_equal(0.0)

func test_injuries_reduce_output_without_removing_citizens()->void:
	start()
	var healthy:=MilitaryCampaign._production_rate()
	var allocations:=GameState.population_allocations.duplicate(true)
	GameState.civilian_injuries={"limited":20.0,"severe":40.0}
	assert_float(MilitaryCampaign._production_rate()).is_less(healthy)
	assert_dict(GameState.population_allocations).is_equal(allocations)

func test_completed_stockpile_line_saves_and_large_output_stays_aggregate()->void:
	GameState.resource_stockpiles.Timber=1e12
	var job:=start(1000000000)
	Production.advance(MilitaryCampaign,job,1e12)
	assert_int(int(job.completed)).is_equal(1000000000)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
	MilitaryCampaign.configure_production_line(int(job.id),1000000000,true)
	var saved:=MilitaryCampaign.export_state().duplicate(true)
	assert_bool(MilitaryCampaign.import_state(saved).has("error")).is_false()
	assert_int(int(MilitaryCampaign.equipment_queue[0].completed)).is_equal(1000000000)
	assert_bool(bool(MilitaryCampaign.equipment_queue[0].paused)).is_true()

func test_supply_controls_fit_the_main_dock_width()->void:
	var terrain:=DockTerrain.new();var hud:=DockHud.new()
	var provider:=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
	var job:=start()
	for report:Dictionary in [provider._supply_order_report("equipment","improvised"),provider._workshop_job_report(int(job.id)),provider._production_labor_report(),provider._retool_report(int(job.id))]:
		var container:=VBoxContainer.new();container.size=Vector2(500,800);add_child(container)
		preload("res://scripts/hud/dock_blocks.gd").render(container,report.blocks)
		await get_tree().process_frame
		assert_float(container.get_combined_minimum_size().x).is_less_equal(500.0)
		container.free()
	provider=null;terrain.free();hud.free()

func test_unknown_products_are_hidden_and_cannot_start()->void:
	assert_bool("service_rifle" in Production.available_products(MilitaryCampaign)).is_false()
	assert_bool(MilitaryCampaign.start_production_line("service_rifle",5).has("error")).is_true()
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(0)

func test_new_line_requires_materials_and_workforce_with_actionable_reason()->void:
	GameState.resource_stockpiles.Timber=0.0
	assert_str(String(MilitaryCampaign.start_production_line("improvised",5).error)).contains("Timber")
	GameState.resource_stockpiles.Timber=100.0
	MilitaryCampaign.production_labor_share=0
	assert_str(String(MilitaryCampaign.start_production_line("improvised",5).error)).contains("crafting share")
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(0)

func test_material_limited_forecast_and_default_finite_target()->void:
	assert_bool(MilitaryCampaign.start_production_line("improvised").has("ok")).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	assert_int(job.target_stock).is_equal(5)
	GameState.resource_stockpiles.Timber=.175
	var view:=Production.snapshot(MilitaryCampaign,job,100,1)
	assert_float(float(view.forecast_output_per_day)).is_equal_approx(.5,.000001)
	GameState.resource_stockpiles.Timber=0
	view=Production.snapshot(MilitaryCampaign,job,100,1)
	assert_float(float(view.forecast_output_per_day)).is_equal(0.0)
	assert_str(String(view.state)).contains("Missing")

func test_existing_line_rechecks_research_before_consuming_materials()->void:
	GameState.known_discoveries.append("hafted_weapons");GameState.discovery_adoption.hafted_weapons=1.0
	GameState.resource_stockpiles.Stone=100.0
	assert_bool(MilitaryCampaign.start_production_line("spear",5).has("ok")).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	GameState.known_discoveries.erase("hafted_weapons")
	var stores:=GameState.resource_stockpiles.duplicate(true)
	Production.advance(MilitaryCampaign,job,100)
	assert_str(Production.state(MilitaryCampaign,job)).contains("Research unavailable")
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	assert_int(job.completed).is_equal(0)

func test_army_composition_offers_newly_known_equipment_for_existing_unit()->void:
	GameState.known_discoveries.append("hafted_weapons");GameState.discovery_adoption.hafted_weapons=1.0
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Levy band","entries":[{"unit":"levy","weapon":"improvised","count":1}]}]
	var terrain:=DockTerrain.new();var hud:=DockHud.new()
	var provider:=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
	var blocks:Array=provider._builds_blocks(MilitaryCampaign.military_capabilities(),1,0)
	assert_str(str(blocks)).contains("Spears")
	assert_str(str(provider._equipment_catalog())).not_contains("Service rifle")
	provider=null;terrain.free();hud.free()
