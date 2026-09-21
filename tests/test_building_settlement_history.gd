extends GdUnitTestSuite
const Buildings=preload("res://scripts/hud/content/dock_content_construction.gd")
const Ledger=preload("res://scripts/hud/content/dock_detail_building_ledger.gd")
func test_work_counts_and_live_progress()->void:
	var definition:Dictionary=Buildings.Construction._settlement_definitions()[1]
	var progress:Dictionary={String(definition.name):float(definition.days)*0.25}
	var report:=Buildings._settlement_report(["Hearth Circle"],progress)
	assert_int(report.completed).is_equal(1)
	assert_int(report.underway).is_equal(1)
	assert_str(report.items[1].value).is_equal("25.0%")
	progress[String(definition.name)]=float(definition.days)*0.75
	report=Buildings._settlement_report(["Hearth Circle"],progress)
	assert_str(report.items[1].value).is_equal("75.0%")
	assert_int(Buildings._settlement_report([String(definition.name)],progress).underway).is_equal(0)
func test_history_filters_settlement_and_keeps_unassigned_only_in_all()->void:
	GameState.reset_for_new_world(123)
	GameState.building_ledger.assign([
		{"id":1,"day":1,"settlement_id":"a","settlement_name":"Alder","kind":"Hut","event":"completed","plot_id":-1,"counts_materials":true,"materials":{"Timber":2.0}},
		{"id":2,"day":2,"settlement_id":"b","settlement_name":"Birch","kind":"Hut","event":"completed","plot_id":-1,"counts_materials":true,"materials":{"Timber":5.0}},
		{"id":3,"day":3,"settlement_id":"","kind":"Legacy","event":"legacy_completed"}])
	var ledger=Ledger.new(null,null,"a")
	var result:Dictionary=ledger.tab(0)
	assert_str(result.kpis[0].value).is_equal("1")
	assert_str(result.kpis[2].value).is_equal("2.0")
	assert_str(result.blocks[0].items[0].sub).contains("Alder")
	ledger.settlement_id=""
	assert_str(ledger.tab(0).kpis[0].value).is_equal("3")
func test_buildings_exposes_settlements_and_history()->void:
	var provider=Buildings.new(null,null)
	assert_array(provider.meta().subtabs).contains(["SETTLEMENTS","HISTORY"])
