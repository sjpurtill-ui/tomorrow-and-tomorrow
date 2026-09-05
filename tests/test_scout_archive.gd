extends GdUnitTestSuite
const Archive:=preload("res://scripts/scout_archive.gd")
const Widget:=preload("res://scripts/hud/scout_archive_widget.gd")
const Detail:=preload("res://scripts/hud/content/dock_detail_scout_report.gd")

func before_test()->void:
	GameState.reset_for_new_world(741991)
	CivilizationSystem.reset_for_new_world()

func record(index:int)->Dictionary:
	return {"mission_id":index+1,"day":index*7,"personnel":8,"returned_personnel":8,"target_id":"open_world","target_label":"Open exploration","route":[{"x":0,"z":0},{"x":index+10,"z":-index-10}],"distance_km":index*2+28,"archive_reviewed":false,"discoveries":[{"kind":"knowledge","title":"A wider world, carried home","description":"Routine observations","duration_days":90}],"journal":["They walked across woodland."]}

func test_full_retained_archive_is_paged_and_every_report_remains_retrievable()->void:
	var widget:Variant=auto_free(Widget.new())
	for index in 256: widget.records.append(record(index))
	add_child(widget)
	assert_int(widget.visible_items.size()).is_equal(5)
	assert_int(widget.results.get_child_count()).is_equal(5)
	var seen:Dictionary={}
	for page in 52:
		for item:Dictionary in widget.visible_items: seen[item.id]=true
		if not widget.next.disabled: widget.next.pressed.emit()
	assert_int(seen.size()).is_equal(256)
	assert_int(widget.visible_items.size()).is_equal(1)
	assert_bool(widget.next.disabled).is_true()
	widget.search.text_changed.emit("Party 173")
	assert_int(widget.visible_items.size()).is_equal(1)
	assert_int(int(widget.visible_items[0].report.mission_id)).is_equal(173)
	assert_int(int(widget.view_state.page)).is_equal(0)

func test_search_reaches_saved_detail_text_and_filters_routine_losses_and_unread()->void:
	var routine:=record(0); routine.erase("archive_reviewed")
	var copper:=record(1); copper.discoveries.append({"kind":"deposit","title":"Copper seam","description":"Red ore above the river"})
	var loss:=record(2); loss["lost_personnel"]=2
	var records:Array=[routine,copper,loss]
	assert_int(Archive.select(records,"red river").size()).is_equal(1)
	assert_int(Archive.select(records,"",1).size()).is_equal(1)
	assert_int(Archive.select(records,"",2).size()).is_equal(1)
	assert_int(Archive.select(records,"",3).size()).is_equal(1)
	assert_int(Archive.select(records,"",4).size()).is_equal(2)
	assert_int(int(Archive.select(records)[0].losses)).is_equal(2)
	assert_bool(Archive.summary(routine).meaningful).is_false()

func test_review_state_changes_only_explicitly_and_survives_curated_save_with_full_records()->void:
	for index in 256: CivilizationSystem.scout_reports.append(record(index))
	var original:=CivilizationSystem.scout_reports.duplicate(true)
	Archive.select(CivilizationSystem.scout_reports,"copper",1)
	assert_array(CivilizationSystem.scout_reports).is_equal(original)
	Archive.mark_reviewed(CivilizationSystem.scout_reports[172])
	assert_bool(CivilizationSystem.scout_reports[172].archive_reviewed).is_true()
	var saved:Dictionary=JSON.parse_string(JSON.stringify(CivilizationSystem.export_state()))
	var loaded:=CivilizationSystem.import_state(saved)
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	assert_int(CivilizationSystem.scout_reports.size()).is_equal(256)
	assert_bool(CivilizationSystem.scout_reports[172].archive_reviewed).is_true()
	assert_int((CivilizationSystem.scout_reports[172].route as Array).size()).is_equal(2)

func test_detail_has_no_repeated_hero_and_art_matches_saved_terrain_only()->void:
	var forest:=record(1)
	assert_str(Archive.artwork(forest)).contains("forest")
	var river:=record(2); river.journal=["They forded running water twice."]
	assert_str(Archive.artwork(river)).contains("river")
	var desert:=record(3); desert.journal=["Three days across dunes."]
	assert_str(Archive.artwork(desert)).contains("desert")
	var mountain:=record(4); mountain.journal=["Bare summit above treeline."]
	assert_str(Archive.artwork(mountain)).contains("mountains")
	var unknown:=record(5); unknown.journal=[]
	assert_str(Archive.artwork(unknown)).is_empty()
	var detail:=Detail.new(null,null,forest)
	for block:Dictionary in detail.tab(0).blocks: assert_str(String(block.get("type",""))).is_not_equal("image")
	assert_str(JSON.stringify(detail.tab(0))).not_contains("Their route sketches")
	assert_str(JSON.stringify(detail.tab(1))).contains("Routine observations")
	assert_str(JSON.stringify(detail.tab(1))).contains("chronicle-forest")

func test_open_and_return_preserves_archive_search_filter_page_and_speed()->void:
	var widget:Variant=auto_free(Widget.new())
	for index in 12: widget.records.append(record(index))
	CivilizationSystem.scout_reports.assign(widget.records)
	widget.view_state={"query":"","filter":0,"order":1,"page":1}
	var opened:Array=[]
	widget.open_report=func(value:Dictionary)->void: opened.append(value)
	add_child(widget)
	var terrain:Variant=auto_free(preload("res://scripts/local_terrain.gd").new())
	terrain.game_speed=5.0
	(widget.results.get_child(0) as Button).pressed.emit()
	assert_int(opened.size()).is_equal(1)
	assert_bool(opened[0].archive_reviewed).is_true()
	assert_int(int(widget.view_state.page)).is_equal(1)
	assert_float(terrain.game_speed).is_equal(5.0)

func test_legacy_findings_are_searchable_without_inventing_review_history()->void:
	var old:={"day":13,"windfalls":["A workable copper deposit was recognized."],"journal":[]}
	var summary:=Archive.summary(old)
	assert_bool(summary.meaningful).is_true()
	assert_str(String(summary.review)).is_empty()
	assert_int(Archive.select([old],"copper").size()).is_equal(1)
