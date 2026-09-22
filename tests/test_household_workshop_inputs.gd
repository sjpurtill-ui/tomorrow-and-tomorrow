extends GdUnitTestSuite
const Craft=preload("res://scripts/opening_craft_practice.gd")

func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("input_share",442)
func after_test()->void:WorldSimulation.clear()

func setup_order()->void:
	WorldSimulation.military.production_labor_share=.18
	WorldSimulation.military.military_inventory.improvised=0
	WorldSimulation.military.equipment_queue.assign([{"persistent":true,"paused":false,"item":"improvised","job_type":"production","target_stock":1,"work_per_item":1.0,"progress_days":0.0,"materials":{"Timber":1.0}}])
	WorldSimulation.state.resource_stockpiles.Timber=.2

func test_households_share_scarce_inputs_with_ordered_work()->void:
	WorldSimulation.scoped("input_share",func()->void:
		setup_order()
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.known_discoveries.assign(["smoking"]);state.discovery_adoption={"smoking":1.0}
		state.resource_stockpiles["Smoke Frames"]=0.0;state.resource_stockpiles.Stone=10.0
		state.opening_craft_practice=Craft.empty_state()
		var report:Dictionary=Craft.advance()
		assert_float(float(report.made.get("Smoke Frames",0))).is_greater(0)
		assert_float(float(state.resource_stockpiles.Timber)).is_equal_approx(.1,.000001)
		assert_float(float(report.inputs.Timber)+float(state.resource_stockpiles.Timber)).is_equal_approx(.2,.000001)
	)

func test_finished_paused_and_remote_orders_do_not_reserve_inputs()->void:
	WorldSimulation.scoped("input_share",func()->void:
		setup_order();WorldSimulation.military.equipment_queue[0].paused=true
		assert_dict(Craft.workshop_input_reserve()).is_empty()
		WorldSimulation.military.equipment_queue[0].paused=false
		WorldSimulation.military.military_inventory.improvised=1
		assert_dict(Craft.workshop_input_reserve()).is_empty()
		WorldSimulation.military.military_inventory.improvised=0
		WorldSimulation.state.resource_settlement_id="secondary"
		assert_dict(Craft.workshop_input_reserve()).is_empty()
	)

func test_reserve_covers_only_unpaid_work_and_releases_surplus()->void:
	WorldSimulation.scoped("input_share",func()->void:
		setup_order();WorldSimulation.state.resource_stockpiles.Timber=10.0
		WorldSimulation.military.equipment_queue[0].progress_days=.75
		assert_float(float(Craft.workshop_input_reserve().Timber)).is_equal_approx(.25,.000001)
		WorldSimulation.military.production_labor_share=0
		assert_dict(Craft.workshop_input_reserve()).is_empty()
	)

