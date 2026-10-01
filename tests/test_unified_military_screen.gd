extends GdUnitTestSuite
const Screen=preload("res://scripts/hud/military_roster_screen.gd")
const Provider=preload("res://scripts/hud/content/dock_content_military.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(4242);MilitaryCampaign.reset_for_new_world()
func after_test()->void:
	if is_instance_valid(MilitaryCampaign.roster_screen):MilitaryCampaign.roster_screen.free()
	await get_tree().process_frame
func test_every_way_in_opens_the_war_screen()->void:
	# The army is grand strategy on one page: no tabs, whatever the way in.
	var provider:=Provider.new(null,null)
	for sub in 6:
		assert_bool(provider.open_expanded_tab(sub)).is_true()
		var screen=MilitaryCampaign.roster_screen
		assert_str(screen.page).is_equal("war")
		assert_bool(screen.nav_row.visible).is_false()
		assert_object(screen.body.get_node_or_null("WarBoard")).is_not_null()
		screen.free()

func test_the_army_stays_on_one_page_and_one_panel()->void:
	# However the army is asked for (an alert's page, the training flag), it
	# is the War screen, with no tabs to leave it by.
	for way in [["army",false,""],["army",true,""],["army",false,"support"],["army",false,"recruitment"],["army",false,"leaders"]]:
		MilitaryCampaign.open_roster(String(way[0]),bool(way[1]),String(way[2]))
		var screen=MilitaryCampaign.roster_screen
		assert_object(screen.body.get_node_or_null("WarBoard")).override_failure_message(str(way)).is_not_null()
		assert_bool(screen.nav_row.visible).is_false()
		screen.free()

func test_supply_numbers_refresh_in_place()->void:
	# The readiness strip as a component: its numbers refresh in place.
	MilitaryCampaign.damaged_equipment={"improvised":3}
	var board:VBoxContainer=auto_free(preload("res://scripts/hud/readiness_board.gd").new());add_child(board)
	board.setup({"width":1400.0})
	assert_str(board.chips.repair.value.text).is_equal("3")
	var value:Label=board.chips.repair.value
	MilitaryCampaign.damaged_equipment.improvised=1
	board._process(.5)
	assert_object(board.chips.repair.value).is_same(value)
	assert_str(board.chips.repair.value.text).is_equal("1")
	assert_str(board.chips.repair.chip.tooltip_text).contains("Staff")
	MilitaryCampaign.equipment_queue=[{"item":"improvised","job_type":"repair","count":4,"completed":1}]
	board.refresh()
	assert_str(board.chips.repair.value.text).is_equal("4")
	assert_str(board.chips.repair.chip.tooltip_text).contains("underway")

func test_service_changes_keep_the_shared_shell_and_do_not_show_army_totals()->void:
	# Navy and air are offered only once the people have boats and flight.
	GameState.known_discoveries.append_array(["river_craft","powered_flight"])
	MilitaryCampaign.open_roster("navy",false,"support")
	var screen=MilitaryCampaign.roster_screen
	assert_str(screen.service).is_equal("navy")
	var panel_id:int=screen.panel.get_instance_id()
	assert_bool(screen.support_labels.has("gear")).is_false()
	screen.service="air";screen._build_body()
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
	assert_bool(screen.support_labels.has("gear")).is_false()
	screen._show_page("forces")
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
