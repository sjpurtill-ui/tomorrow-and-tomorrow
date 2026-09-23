extends GdUnitTestSuite
const Goods=preload("res://scripts/civilian_goods.gd")
const Provider=preload("res://scripts/hud/content/dock_content_production.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(321)
	MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true
	GameState.population_exact=100
	GameState.population_allocations.Crafting=20
	GameState.known_discoveries=["cordage","basketry"]
	GameState.discovery_adoption={"cordage":1.0,"basketry":1.0}
	GameState.resource_stockpiles={"Fiber Plants":100.0}
	GameState.civilian_goods=Goods.empty_state()
	GameState.resource_settlement_id="a"
	GameState.settlement_name="Alder"
func after_test()->void:WorldSimulation.clear()
func test_household_output_is_recorded_once_and_separated_by_settlement()->void:
	var report:=Goods.advance()
	assert_float(float(report.made)).is_greater(0)
	var totals:Dictionary=MilitaryCampaign.workshop.data.totals.duplicate(true)
	assert_int(totals.size()).is_equal(1)
	assert_str(String(totals.values()[0].resource)).is_equal(Goods.GOODS)
	Goods.advance()
	assert_dict(MilitaryCampaign.workshop.data.totals).is_equal(totals)
	GameState.resource_settlement_id="b";GameState.settlement_name="Birch"
	MilitaryCampaign.workshop.record_household({Goods.GOODS:2.0})
	assert_int(MilitaryCampaign.workshop.data.totals.size()).is_equal(totals.size()+1)
	var saved:Dictionary=MilitaryCampaign.workshop.data.duplicate(true)
	MilitaryCampaign.workshop.restore(saved)
	assert_dict(MilitaryCampaign.workshop.data.totals).is_equal(saved.totals)
	assert_str(MilitaryCampaign.workshop.validate(saved)).is_empty()
func test_household_view_reports_output_and_missing_material()->void:
	Goods.advance()
	var rows:=Provider._household_rows()
	assert_str(rows[0].name).is_equal(Goods.GOODS)
	assert_str(rows[0].value).contains("today")
	var techniques:=Provider._technique_rows()
	assert_int(techniques.size()).is_equal(2)
	assert_str(techniques[0].value).contains("100% adopted")
	GameState.resource_stockpiles={}
	GameState.civilian_goods=Goods.empty_state()
	Goods.advance()
	rows=Provider._household_rows()
	assert_str(rows[0].sub).contains("Needs timber, fiber, clay, stone or flint")
func test_manager_and_status_visible_without_hover()->void:
	var panel:Control=auto_free(preload("res://scripts/hud/production_queue.gd").new());add_child(panel)
	panel.setup({"owner":"Kaia Almasi · Quartermaster","status":"Line paused under your control","lines":[]})
	var text:=""
	for label in panel.find_children("*","Label",true,false):text+=label.text+"\n"
	assert_str(text).contains("Kaia Almasi")
	assert_str(text).contains("Line paused under your control")
