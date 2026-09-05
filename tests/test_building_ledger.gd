class_name BuildingLedgerTest
extends GdUnitTestSuite

const BUILDING_LEDGER_DETAIL:=preload("res://scripts/hud/content/dock_detail_building_ledger.gd")

func before_test()->void:
	GameState.reset_for_new_world(91823)

func test_keeps_exact_materials_and_lifecycle_for_the_complete_run()->void:
	GameState.record_building_event({"day":30,"event":"started","kind":"Timber hall","materials":{"Timber":8.0,"Fiber Plants":3.0},"counts_materials":true})
	GameState.record_building_event({"day":60,"event":"rebuilt","kind":"Earthen hall","materials":{"Clay":5.5,"Timber":1.0},"counts_materials":true})
	GameState.record_building_event({"day":90,"event":"damaged","kind":"Earthen hall","materials":{},"counts_materials":false})
	var summary:=GameState.building_ledger_summary()
	assert_int(GameState.building_ledger.size()).is_equal(3)
	assert_float(float((summary.materials as Dictionary).get("Timber",0.0))).is_equal_approx(9.0,0.001)
	assert_float(float((summary.materials as Dictionary).get("Fiber Plants",0.0))).is_equal_approx(3.0,0.001)
	assert_float(float((summary.materials as Dictionary).get("Clay",0.0))).is_equal_approx(5.5,0.001)
	assert_int(int((summary.events as Dictionary).get("damaged",0))).is_equal(1)

func test_older_save_fabric_is_reconstructed_without_inventing_materials()->void:
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_plots=[{"id":44,"form":"dry_stone_household","land_use":"residential_compound","roof_plan":"timber_span","material_family":"stone","supply_provenance":{"Stone":4.2,"Timber":0.8},"created_day":365,"condition":0.7,"status":"active"}]
	GameState.ensure_building_ledger()
	var summary:=GameState.building_ledger_summary()
	assert_int(GameState.building_ledger.size()).is_equal(2)
	assert_bool(bool(GameState.building_ledger[0].reconstructed)).is_true()
	assert_dict(GameState.building_ledger[0].materials).is_empty()
	assert_float(float((summary.materials as Dictionary).get("Stone",0.0))).is_equal_approx(4.2,0.001)

func test_reflected_save_payload_contains_the_permanent_ledger()->void:
	GameState.record_building_event({"day":12,"event":"completed","kind":"Hearth Circle","materials":{"Timber":6.0},"counts_materials":true})
	var payload:=SaveSystem._capture_reflected(GameState,[])
	assert_bool(payload.has("building_ledger")).is_true()
	assert_int((payload.building_ledger as Array).size()).is_equal(1)
	assert_int(int(payload.next_building_record_id)).is_equal(2)

func test_player_record_pages_centuries_instead_of_dumping_a_scrolling_list()->void:
	for index in 17:
		GameState.record_building_event({"day":index*365,"event":"started","kind":"Household %d" % index,"materials":{"Timber":1.0},"counts_materials":true})
	var provider:=BUILDING_LEDGER_DETAIL.new(null,null)
	var chronicle:Dictionary=provider.tab(0)
	var rows:Dictionary={}
	for block in (chronicle.blocks as Array):
		if String((block as Dictionary).get("heading",""))=="CONSTRUCTION CHRONICLE": rows=block
	assert_int((rows.items as Array).size()).is_equal(6)
	var material_tab:Dictionary=provider.tab(1)
	assert_str(String(((material_tab.blocks as Array)[0] as Dictionary).get("heading",""))).is_equal("ALL RECORDED CONSTRUCTION MATERIAL")
