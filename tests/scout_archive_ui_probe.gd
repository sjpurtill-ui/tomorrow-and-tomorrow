extends Node
const Fixture:=preload("res://tests/test_scout_archive.gd")
const Archive:=preload("res://scripts/hud/content/dock_detail_scout_archive.gd")
const Widget:=preload("res://scripts/hud/scout_archive_widget.gd")
func _ready()->void:
	GameState.reset_for_new_world(741991)
	CivilizationSystem.reset_for_new_world()
	var fixture:=Fixture.new()
	for index in 256:
		var report:=fixture.record(index)
		if index%9==0: report.discoveries.append({"kind":"deposit","title":"Copper seam above the river","description":"Returning scouts identified workable copper."})
		if index==251: report["lost_personnel"]=2; report["returned_personnel"]=6
		if index==254: report["contacts"]=["The Alder Council"]
		CivilizationSystem.scout_reports.append(report)
	fixture.free()
	get_window().size=Vector2i(640,900); get_window().content_scale_size=Vector2i(640,900)
	var dock:=preload("res://scripts/hud/dock_panel.gd").new()
	dock.position=Vector2(20,12); dock.size=Vector2(540,876); add_child(dock)
	dock.present(Archive.new(null,null))
	await get_tree().process_frame; await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/scout-archive.png")
	var widget:Control=dock.body.get_child(0).get_child(0)
	assert(widget is Widget)
	assert(widget.visible_items.size()==5)
	assert(get_viewport().get_visible_rect().encloses(widget.next.get_global_rect()))
	widget.search.text="copper"; widget.search.text_changed.emit("copper")
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/scout-search.png")
	assert(widget.counter.text.begins_with("29 reports"))
	widget.search.text_changed.emit("never-recorded-place")
	assert(widget.visible_items.is_empty())
	print("SCOUT_ARCHIVE_UI_PASS retained=256 page_size=5 search=29 empty_filter=true")
	get_tree().quit()
