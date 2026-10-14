extends Node
## In-memory totals only, captured on the private test desktop.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Dock=preload("res://scripts/hud/dock_panel.gd")
const Folio=preload("res://scripts/hud/reference_folio.gd")
const Fixture=preload("res://tests/test_live_progress_history.gd")
const Board=preload("res://scripts/hud/production_board.gd")
var failures:Array[String]=[]
class Provider extends RefCounted:
	var totals:Dictionary={}
	func meta()->Dictionary:return {"title":"Output history","eyebrow":"Production","subtabs":[]}
	func tab(_sub:int)->Dictionary:return {"blocks":[{"type":"production_board","history_only":true,"totals":totals,"view_state":{"mode":1}}]}
	func signature()->Array:return [totals]
func arg(key:String,fallback:String)->String:
	for value:String in OS.get_cmdline_user_args():
		if value.begins_with("--"+key+"="):return value.trim_prefix("--"+key+"=")
	return fallback
func check(ok:bool,reason:String)->void:
	if not ok:failures.append(reason);push_error(reason)
func _ready()->void:call_deferred("run")
func settle()->void:
	for frame in 8:await get_tree().process_frame
func run()->void:
	if not OS.get_user_data_dir().to_lower().contains("test"):get_tree().quit(2);return
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	var output:=arg("out","res://artifacts/density");var tag:=arg("tag","first")
	DirAccess.make_dir_recursive_absolute(output)
	var canvases:Array[Vector2i]=[]
	for shape:String in arg("canvases","1600x900,2869x1337,1024x768").split(","):canvases.append(Vector2i(int(shape.get_slice("x",0)),int(shape.get_slice("x",1))))
	for canvas:Vector2i in canvases:
		for palette:String in ["dark","light"]:
			T.set_color_mode(palette)
			var viewport:=SubViewport.new();viewport.size=canvas;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
			var provider:=Provider.new();provider.totals=Fixture.many_history_totals()
			var dock:=Dock.new();dock.theme=T.control_theme();dock.position=Vector2(24,20);dock.size=Vector2(Folio.page_width(canvas.x),canvas.y-40);viewport.add_child(dock)
			dock.present(provider,0);await settle()
			var board:Control=null
			for node:Node in dock.find_children("*","VBoxContainer",true,false):
				if node.get_script()==Board:board=node;break
			check(board!=null,"History board rendered")
			await capture(viewport,dock,output,"history-%s-initial-%s-%d" % [tag,palette,canvas.x])
			board.history_back.pressed.emit();await settle()
			check(board.history_choices.get_child_count()==6,"Six visible history choices")
			await capture(viewport,dock,output,"history-%s-chooser-%s-%d" % [tag,palette,canvas.x])
			board.history_next.pressed.emit();board.history_next.pressed.emit();await settle()
			check(board.history_choices.get_child_count()==1,"Last cumulative total reachable")
			await capture(viewport,dock,output,"history-%s-last-page-%s-%d" % [tag,palette,canvas.x])
			board.history_choices.get_child(0).pressed.emit();await settle()
			await capture(viewport,dock,output,"history-%s-repair-%s-%d" % [tag,palette,canvas.x])
			var selected:=String(board.history_state.selected);provider.totals[selected].quantity=99.125
			board.update_block(provider.tab(0).blocks[0]);await settle()
			check(String(board.history_state.selected)==selected,"Live refresh retains selected total")
			await capture(viewport,dock,output,"history-%s-live-%s-%d" % [tag,palette,canvas.x])
			board.history_back.pressed.emit();board.history_search.text="absent";board.history_search.text_changed.emit("absent");await settle()
			await capture(viewport,dock,output,"history-%s-no-match-%s-%d" % [tag,palette,canvas.x])
			provider.totals={};board.history_search.text="";board.history_state.query="";board.update_block(provider.tab(0).blocks[0]);await settle()
			await capture(viewport,dock,output,"history-%s-empty-%s-%d" % [tag,palette,canvas.x])
			viewport.queue_free();await get_tree().process_frame
	print("PRODUCTION_HISTORY_CAPTURE ","PASS" if failures.is_empty() else failures)
	get_tree().quit(0 if failures.is_empty() else 1)
func capture(viewport:SubViewport,dock:Control,folder:String,title:String)->void:
	var bounds:=dock.get_global_rect()
	check(Rect2(Vector2.ZERO,viewport.size).encloses(bounds),title+": dock bounds")
	for node:Node in dock.find_children("*","Control",true,false):
		if not node.is_visible_in_tree():continue
		if node is Label or node is BaseButton or node is LineEdit:
			var rect:Rect2=node.get_global_rect()
			check(rect.position.x>=bounds.position.x-1 and rect.end.x<=bounds.end.x+1,title+": horizontal bounds "+String(node.name))
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(folder.path_join(title+".png"))
