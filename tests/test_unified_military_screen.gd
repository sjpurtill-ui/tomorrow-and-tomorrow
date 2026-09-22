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
	for sub in 4:
		assert_bool(provider.open_expanded_tab(sub)).is_true()
		var screen=MilitaryCampaign.roster_screen
		assert_str(screen.page).is_equal(["forces","recruitment","training","support"][sub])
		assert_int(screen.page_buttons.size()).is_equal(4)
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
	assert_int(screen.support_labels.size()).is_equal(4)
	screen._show_page("training")
	assert_bool(screen.training_view).is_true()
	screen._show_page("forces")
	assert_bool(screen.training_view).is_false()
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
func test_supply_numbers_refresh_without_reopening_the_view()->void:
	MilitaryCampaign.damaged_equipment={"improvised":3}
	MilitaryCampaign.open_roster("army",false,"support")
	var screen=MilitaryCampaign.roster_screen
	assert_str(screen.support_labels.repair.value.text).is_equal("3")
	MilitaryCampaign.damaged_equipment.improvised=1
	screen._process(.5)
	assert_str(screen.support_labels.repair.value.text).is_equal("1")
	assert_str(screen.support_labels.repair.note.text).contains("Staff")
	MilitaryCampaign.equipment_queue=[{"item":"improvised","job_type":"repair","count":4,"completed":1}]
	screen._update_support()
	assert_str(screen.support_labels.repair.value.text).is_equal("4")
	assert_str(screen.support_labels.repair.note.text).contains("underway")

func test_service_changes_keep_the_shared_shell_and_do_not_show_army_totals()->void:
	MilitaryCampaign.open_roster("navy",false,"support")
	var screen=MilitaryCampaign.roster_screen
	var panel_id:int=screen.panel.get_instance_id()
	assert_bool(screen.support_labels.has("gear")).is_false()
	screen.service="air";screen._build_body()
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
	assert_bool(screen.support_labels.has("gear")).is_false()
	screen._show_page("forces")
	assert_int(screen.panel.get_instance_id()).is_equal(panel_id)
