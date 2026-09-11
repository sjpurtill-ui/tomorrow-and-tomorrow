extends GdUnitTestSuite
const View=preload("res://scripts/hud/research_atlas.gd")
const Art=preload("res://scripts/hud/research_visuals.gd")
const Data=preload("res://scripts/hud/atlas_data.gd")
func before_test()->void:
	GameState.reset_for_new_world(424242);DiscoverySystem.reset_for_new_world();SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.population_allocations["Knowledge"]=24
	GameState.elapsed_days=100
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.leadership_positions["Steward"]={"name":"Mira Vale","person_id":41,"skills":{"Knowledge":.8,"Administration":.7,"Construction":.6,"Provisioning":.5,"Diplomacy":.5,"Logistics":.5,"Defense":.5}}
	DiscoverySystem.initialize();DiscoverySystem._refresh_active_investigations()
func fixture(width:int=1440,height:int=900)->Control:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(width,height);add_child(viewport)
	var view:=View.new();viewport.add_child(view);return view
func test_atlas_reports_current_leader_and_real_fractional_workforce_without_reallocating()->void:
	var before:=GameState.active_investigations.duplicate(true)
	var weights:=GameState.research_subcategory_allocations.duplicate(true)
	var progress:=GameState.discovery_progress.duplicate(true)
	var view:=fixture()
	assert_str(view.view_mode).is_equal("active")
	assert_int(view.records.size()).is_greater(0)
	for item:Dictionary in view.records:
		assert_bool(item.assignment.active).is_true()
		assert_float(Art.team(item)).is_equal_approx(DiscoverySystem.research_capacity_for(item.domain,item.subcategory).researchers,.00001)
		assert_bool(view.bindings.has(item.id)).is_true()
		assert_str(view.bindings[item.id].lead.text).contains(item.assignment.leader.name)
	assert_dict(GameState.active_investigations).is_equal(before)
	assert_dict(GameState.research_subcategory_allocations).is_equal(weights)
	assert_dict(GameState.discovery_progress).is_equal(progress)
func test_daily_update_keeps_card_selection_and_tree_camera()->void:
	var view:=fixture();var id:=String(view.records[0].id);view.select(id)
	var card:PanelContainer=view.bindings[id].frame
	GameState.discovery_progress[id]=.44;view.refresh(false)
	assert_object(view.bindings[id].frame).is_same(card)
	assert_str(view.selected_id).is_equal(id)
	assert_float(view.bindings[id].meter.value).is_equal(44.0)
	view.set_view("tree");view.plot.center=Vector2(333,211);view.plot.zoom_level=.9
	GameState.discovery_progress[id]=.45;view.refresh(false)
	assert_vector(view.plot.center).is_equal(Vector2(333,211))
	assert_float(view.plot.zoom_level).is_equal(.9)
func test_unstaffed_investigations_are_explicit_and_do_not_invent_people()->void:
	GameState.population_allocations["Knowledge"]=0
	var view:=fixture()
	for item:Dictionary in view.records:
		assert_str(Art.status(item)).is_equal("Waiting for workers")
		assert_str(view.bindings[item.id].team.text).contains("No researchers")
	assert_str(view.stats.text).contains("0 researchers")
func test_office_vacancy_and_acting_lead_agree_with_execution_authority()->void:
	var assignment:=DiscoverySystem.research_leadership("knowledge")
	assert_str(assignment.office).is_equal(GovernmentPeopleSystem.executing_office("Scholar"))
	GameState.leadership_positions.erase(assignment.office)
	assert_bool(DiscoverySystem.research_leadership("knowledge").vacant).is_true()
func test_leader_and_known_subject_filters_do_not_expose_locked_outcomes()->void:
	var view:=fixture()
	view.leader_filter=Art.lead(view.records[0]);view.refresh(true)
	for item:Dictionary in view.records:assert_str(Art.lead(item)).is_equal(view.leader_filter)
	view.leader_filter="";view.set_view("tree")
	for item:Dictionary in view.records:assert_bool(item.exposed).is_true()
	view.show_locked=true;view.refresh(true)
	var locked:=0
	for item:Dictionary in view.records:
		if item.exposed:continue
		locked+=1;assert_str(item.name).is_equal("Unexplored question");assert_dict(item.assignment).is_empty()
	assert_int(locked).is_greater(0)
func test_focus_redirects_only_selected_channel_and_live_view_reports_it()->void:
	var view:=fixture();view.set_view("tree")
	var candidate:Dictionary={}
	for item:Dictionary in view.records:
		if item.ready and not item.assignment.active:candidate=item;break
	assert_bool(candidate.is_empty()).is_false()
	if candidate.is_empty():return
	var before:=GameState.active_investigations.duplicate(true)
	view.select(candidate.id);view._act()
	assert_str(GameState.active_investigations[candidate.assignment.channel]).is_equal(candidate.id)
	for channel in before:
		if channel!=candidate.assignment.channel:assert_str(GameState.active_investigations[channel]).is_equal(before[channel])
	assert_bool(view.action.disabled).is_true()
func test_layout_stays_inside_small_and_large_windows_with_scrollable_details()->void:
	for width:int in [800,1024,1440,1600]:
		var view:=fixture(width,640 if width<1120 else 900)
		for i in 5:await get_tree().process_frame
		assert_float(view.panel.position.x+view.panel.size.x).is_less_equal(float(width))
		assert_float(view.panel.position.y+view.panel.size.y).is_less_equal(640.0 if width<1120 else 900.0)
		assert_float(view.grid.get_combined_minimum_size().x).is_less_equal(view.scroll.size.x)
		if width<1120:
			view.select(view.selected_id,true)
			for frame in 5:await get_tree().process_frame
			assert_bool(view.detail_scroll.visible).is_true()
		assert_float(view.detail_body.get_combined_minimum_size().x).is_less_equal(view.detail_scroll.size.x)
		view.set_view("tree")
		for i in 3:await get_tree().process_frame
		assert_float(view.plot.size.y).is_greater(100)
func test_every_research_field_has_a_distinct_painted_asset()->void:
	var paths:Dictionary={}
	for id:String in Art.NAMES:
		var texture:=Art.art(id);assert_object(texture).is_not_null()
		if texture:paths[texture.resource_path]=true
	assert_int(paths.size()).is_equal(12)
func test_stone_art_is_consistent_in_research_card_and_inspector()->void:
	GameState.known_discoveries.append("stone_sorting")
	var view:=fixture();view.set_view("known");view.select("stone_sorting")
	assert_str(view.bindings.stone_sorting.painting.texture.resource_path).is_equal("res://assets/ui/research/paper/stone_sorting.png")
	assert_str(view.detail_body.get_child(0).texture.resource_path).is_equal("res://assets/ui/research/paper/stone_sorting.png")

func test_reviewed_paper_images_are_specific_and_preserve_the_full_square()->void:
	var parent:VBoxContainer=auto_free(VBoxContainer.new());add_child(parent)
	for id:String in ["stone_sorting","apprentice_contracts","oral_epics","festival_calendar","wayfinding_stars","photovoltaic_power","public_schools"]:
		var item:Dictionary={"id":id,"domain":"knowledge","exposed":true}
		var picture:=Art.paint_discovery(parent,item,104)
		assert_str(picture.texture.resource_path).is_equal("res://assets/ui/research/paper/"+id+".png")
		assert_int(picture.stretch_mode).is_equal(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		assert_bool(picture.has_node("PaperMat")).is_true()
		assert_bool(picture.has_node("FieldIllustrationCaption")).is_false()
		item.exposed=false
		assert_str(Art.subject_art_key(item)).is_empty()

func test_missing_subject_art_retains_an_explicit_field_fallback()->void:
	var parent:VBoxContainer=auto_free(VBoxContainer.new());add_child(parent)
	var picture:=Art.paint_discovery(parent,{"id":"single_crystal_growth","domain":"production","exposed":true},104)
	assert_bool(picture.has_node("FieldIllustrationCaption")).is_true()
	assert_str(picture.texture.resource_path).is_equal("res://assets/ui/research/production-v1.png")
