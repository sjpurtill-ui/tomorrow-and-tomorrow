extends GdUnitTestSuite
const Military=preload("res://scripts/hud/content/dock_content_military.gd")
const Production=preload("res://scripts/hud/content/dock_content_production.gd")
const Rail=preload("res://scripts/hud/command_rail_hud.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world()
func test_government_has_correct_sidebar_name()->void:
	for section in Rail.SECTIONS:
		if section.id=="government":assert_str(section.label).is_equal("Government")
func test_logistics_has_no_production_board_or_order_actions()->void:
	var provider=Military.new(null,null)
	var blocks:=provider._supply_overview()
	assert_bool(blocks.is_empty()).is_false()
	for block in blocks:
		assert_bool(String(block.type) in ["production_board","production_queue"]).is_false()
		for item in block.get("items",[]):
			assert_bool(String(item.get("label","")) in ["ADD ORDER","MANAGEMENT","BUILD CARTS"]).is_false()
	assert_str(provider.meta().title).is_equal("Military")
	assert_str(provider.meta().subtabs[3]).is_equal("LOGISTICS")
func test_production_reports_staff_managed_repairs()->void:
	MilitaryCampaign.damaged_equipment={"improvised":3}
	var provider=Production.new(null,null)
	var report:=provider._repairs()
	assert_int(report.blocks[0].items.size()).is_equal(1)
	assert_str(report.blocks[0].heading).is_equal("STAFF-MANAGED REPAIRS")
	assert_str(report.blocks[0].items[0].value).is_equal("3 sets in upkeep")
func test_logistics_reports_actual_reserve_and_damage()->void:
	var provider=Military.new(null,null)
	var blocks:=provider._supply_blocks({"military_inventory":{"improvised":7},"damaged_equipment":{"improvised":3}}, {})
	var found:=false
	for block in blocks:
		if block.get("heading","")=="EQUIPMENT IN RESERVE":
			found=true;assert_str(block.items[0].value).is_equal("7")
	assert_bool(found).is_true()
