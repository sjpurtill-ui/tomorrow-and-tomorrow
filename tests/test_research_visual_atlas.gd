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
func test_selected_discovery_keeps_its_operating_controls_without_refresh_duplicates()->void:
	GameState.known_discoveries.append_array(["mechanical_refrigeration","steam_engine"])
	var view:=fixture();view.set_view("known");view.select("mechanical_refrigeration")
	for refresh in range(3):
		view.refresh(false)
		var panels:=0
		for child:Node in view.detail_body.get_children():
			if child.get_script()!=preload("res://scripts/hud/technology_operations_panel.gd"):continue
			panels+=1
			assert_str(child.subject).is_equal("mechanical_refrigeration")
			assert_bool(child.rows.has("cold_store")).is_true()
		assert_int(panels).is_equal(1)
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
	# Before printing the header counts keepers of lore, not "SCIENCE".
	assert_str(view.stats.text).contains("0 keeping the lore").not_contains("SCIENCE")
func test_office_vacancy_and_acting_lead_agree_with_execution_authority()->void:
	var assignment:=DiscoverySystem.research_leadership("knowledge")
	assert_str(assignment.office).is_equal(GovernmentPeopleSystem.executing_office("Scholar"))
	GameState.leadership_positions.erase(assignment.office)
	assert_bool(DiscoverySystem.research_leadership("knowledge").vacant).is_true()
func test_leader_and_known_subject_filters_do_not_expose_locked_outcomes()->void:
	var view:=fixture()
	view.leader_filter=Art.lead(view.records[0]);view.refresh(true)
	for item:Dictionary in view.records:assert_str(Art.lead(item)).is_equal(view.leader_filter)
	view.leader_filter="";view.show_locked=false;view.set_view("tree")
	for item:Dictionary in view.records:assert_bool(item.exposed).is_true()
	view.show_locked=true;view.refresh(true)
	var locked:=0
	for item:Dictionary in view.records:
		if item.exposed:continue
		# Only next reachable questions are drawn, named with what they wait on;
		# deeper locked questions collapse into the legend's count.
		locked+=1;assert_bool(item.next).is_true();assert_bool(item.beyond).is_false();assert_dict(item.assignment).is_empty()
	assert_int(locked).is_greater(0)
	assert_str(view.legend.text).contains("further questions beyond")
func test_focus_redirects_only_selected_channel_and_live_view_reports_it()->void:
	var view:=fixture();view.tree_scope="all";view.set_view("tree")
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
func test_cards_stay_compact_and_use_the_available_row_for_more_discoveries()->void:
	var view:=fixture(1440,900)
	for frame in 5:await get_tree().process_frame
	assert_int(view.grid.size_flags_horizontal).is_equal(Control.SIZE_SHRINK_BEGIN)
	assert_int(view.grid.columns).is_greater_equal(4)
	for card:Dictionary in view.bindings.values():
		assert_float(card.frame.size.x).is_equal_approx(view.CARD_WIDTH,0.5)
		assert_float(card.painting.custom_minimum_size.y).is_equal(view.CARD_IMAGE_HEIGHT)
		assert_int(card.frame.mouse_filter).is_equal(Control.MOUSE_FILTER_PASS)
func test_established_cards_show_the_recorded_discovery_year_and_day()->void:
	# Only the recorded discovery, so the inherited founding practices (which have
	# no discovery date) do not come first in the established view.
	GameState.known_discoveries.assign(["stone_sorting"])
	GameState.discovery_log.push_front({"id":"stone_sorting","day":730})
	var view:=fixture();view.set_view("known")
	assert_int(view.records[0].discovered_day).is_equal(730)
	assert_str(view.bindings.stone_sorting.date.text).is_equal("DISCOVERED · YEAR 3, DAY 1")
	assert_str(view.detail_body.get_child(4).text).is_equal("Discovered · Year 3, Day 1")
func test_established_grid_scrolls_through_a_long_catalogue()->void:
	var ids:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_tree():
		ids.append(String(entry.id))
		if ids.size()>=60:break
	GameState.known_discoveries.assign(ids)
	var view:=fixture(800,600);view.set_view("known")
	for frame in 5:await get_tree().process_frame
	assert_bool(view.scroll.get_v_scroll_bar().visible).is_true()
	assert_float(view.scroll.get_v_scroll_bar().max_value).is_greater(view.scroll.size.y)
	view.scroll.scroll_vertical=1000
	for frame in 2:await get_tree().process_frame
	assert_int(view.scroll.scroll_vertical).is_greater(0)
func test_every_research_field_has_a_distinct_painted_asset()->void:
	# Past the early-civilization art window (EarlyCivArt.active) each field shows its own painting.
	GameState.elapsed_days=400*365
	var paths:Dictionary={}
	for id:String in Art.NAMES:
		var texture:=Art.art(id);assert_object(texture).is_not_null()
		if texture:paths[texture.resource_path]=true
	assert_int(paths.size()).is_equal(12)
func test_stone_art_is_consistent_in_research_card_and_inspector()->void:
	GameState.known_discoveries.append("stone_sorting")
	var view:=fixture();view.set_view("known");view.select("stone_sorting")
	for frame in 8:await get_tree().process_frame
	# The card and the inspector show the same painting: the early-civilization
	# paper painting inside that art window (EarlyCivArt.active), else the subject art.
	var expected:=Art.source_texture(Art.for_discovery({"id":"stone_sorting"})).resource_path
	if not preload("res://scripts/hud/early_civ_art.gd").active():expected="res://assets/ui/research/stone-selection-v1.png"
	assert_str(Art.source_texture(view.bindings.stone_sorting.painting.texture).resource_path).is_equal(expected)
	assert_str(Art.source_texture(view.detail_body.get_child(0).texture).resource_path).is_equal(expected)

func test_reviewed_images_resolve_their_explicit_assignments()->void:
	var parent:VBoxContainer=auto_free(VBoxContainer.new());add_child(parent)
	for id:String in Art.manifest():
		var item:Dictionary={"id":id,"domain":"knowledge","exposed":true}
		var picture:=Art.paint_discovery(parent,item,104)
		assert_object(picture.texture).is_not_null()
		# research_600 paintings (data/research/art_600.json) take precedence over reviewed subject art;
		# in the early-civilization window the early paper paintings do too.
		assert_str(picture.texture.resource_path).is_equal(_expected_art(id))
		assert_int(Art.textures.size()).is_less_equal(Art.CACHE_LIMIT)
		item.exposed=false
		assert_str(Art.subject_art_key(item)).is_empty()
		picture.free()

func test_missing_subject_does_not_claim_an_unrelated_field_painting()->void:
	var parent:VBoxContainer=auto_free(VBoxContainer.new());add_child(parent)
	var picture:=Art.paint_discovery(parent,{"id":"unassigned_test_subject","domain":"production","exposed":true},104)
	assert_object(picture.texture).is_null()

func test_known_microscopy_has_one_live_panel_and_locked_method_has_none()->void:
	GameState.known_discoveries.append("laboratory_notebooks")
	var view:=fixture();view.set_view("known");view.select("laboratory_notebooks")
	for cycle in range(3):
		view.refresh(false)
		var panels:=0
		for child:Node in view.detail_body.get_children():
			if child.get_script()==preload("res://scripts/hud/microscopy_panel.gd"):panels+=1
		assert_int(panels).is_equal(1)
	view.set_view("tree");view.show_locked=true;view.refresh(true);view.select("microscopic_cell_observation")
	for child:Node in view.detail_body.get_children():assert_bool(child.get_script()==preload("res://scripts/hud/microscopy_panel.gd")).is_false()

func _expected_art(id:String)->String:
	if Art.art600_manifest().has(id):return String(Art.art600_manifest()[id].path)
	var early:=preload("res://scripts/hud/early_civ_art.gd").active()
	if early and Art.first300_manifest().has(id):return String(Art.first300_manifest()[id])
	if early and Art.EARLY_SUBJECTS.has(id):return "res://assets/ui/research/paper/%s.png" % Art.EARLY_SUBJECT_FILES.get(id,id)
	return String(Art.manifest()[id].path)
