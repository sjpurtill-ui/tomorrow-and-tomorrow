extends GdUnitTestSuite
const Screen=preload("res://scripts/hud/military_roster_screen.gd")
const Provider=preload("res://scripts/hud/content/dock_content_military.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(4242);MilitaryCampaign.reset_for_new_world()
func after_test()->void:
	if is_instance_valid(MilitaryCampaign.roster_screen):MilitaryCampaign.roster_screen.free()
	await get_tree().process_frame
func test_all_legacy_tabs_open_the_same_military_shell()->void:
	var provider:=Provider.new(null,null)
	for sub in 5:
		assert_bool(provider.open_expanded_tab(sub)).is_true()
		var screen=MilitaryCampaign.roster_screen
		assert_str(screen.page).is_equal(["forces","recruitment","training","support","wars"][sub])
		assert_int(screen.page_buttons.size()).is_equal(5)
		screen.free()
func test_navigation_keeps_one_panel_and_embeds_recruitment_and_editor()->void:
	MilitaryCampaign.open_roster()
	var screen=MilitaryCampaign.roster_screen
	var panel_id:int=screen.panel.get_instance_id()
	screen._show_page("recruitment")
	assert_object(screen.body.get_node_or_null("RecruitDeployBoard")).is_not_null()
	var template:Dictionary=MilitaryCampaign.create_army_template()
	screen.editor_id=int(template.template.template_id);screen._build_body()
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
	screen._show_page("support")
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
	# The army's Readiness & supply is HOI4's logistics view: its strip of
	# carriers, share carried, hubs, depots, rations and gear being mended.
	assert_object(screen.body.get_node_or_null("ReadinessBoard")).is_not_null()
	assert_bool(screen.support_labels.has_all(["carriers","carried","hubs","depots","rations","repair"])).is_true()
	screen._show_page("training")
	assert_bool(screen.training_view).is_true()
	screen._show_page("forces")
	assert_bool(screen.training_view).is_false()
	assert_object(screen.body.get_node_or_null("ForcesBoard")).is_not_null()
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
func test_supply_numbers_refresh_without_reopening_the_view()->void:
	MilitaryCampaign.damaged_equipment={"improvised":3}
	MilitaryCampaign.open_roster("army",false,"support")
	var screen=MilitaryCampaign.roster_screen
	assert_str(screen.support_labels.repair.value.text).is_equal("3")
	var value:Label=screen.support_labels.repair.value
	MilitaryCampaign.damaged_equipment.improvised=1
	screen.readiness_board._process(.5)
	# The same label, refreshed in place; the staff's words are its tooltip.
	assert_object(screen.support_labels.repair.value).is_same(value)
	assert_str(screen.support_labels.repair.value.text).is_equal("1")
	assert_str(screen.support_labels.repair.chip.tooltip_text).contains("Staff")
	MilitaryCampaign.equipment_queue=[{"item":"improvised","job_type":"repair","count":4,"completed":1}]
	screen.readiness_board.refresh()
	assert_str(screen.support_labels.repair.value.text).is_equal("4")
	assert_str(screen.support_labels.repair.chip.tooltip_text).contains("underway")

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
