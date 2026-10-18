extends Node
## Disposable collection/offer fixtures on private TEST userdata; never loads a save.
const Sheet=preload("res://scripts/hud/exchange_collection_panel.gd")
const E=preload("res://scripts/society_exchange.gd")
const A=preload("res://scripts/artifact_collection.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Fixture=preload("res://tests/test_society_exchange.gd")
var failures:Array[String]=[]
var output:=""
var tag:="capture"
func check(value:bool,message:String)->void:
	if not value:failures.append(message);push_error(message)
func arg(key:String,fallback:String)->String:
	for value:String in OS.get_cmdline_user_args():
		if value.begins_with("--"+key+"="):return value.trim_prefix("--"+key+"=")
	return fallback
func _ready()->void:call_deferred("run")
func settle()->void:
	for frame in 8:await get_tree().process_frame
func run()->void:
	if not OS.get_user_data_dir().to_lower().contains("test"):
		push_error("Exchange capture requires isolated TEST userdata");get_tree().quit(2);return
	var fixture:=Fixture.new();fixture.before_test();fixture.free()
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	GameState.elapsed_days=3650;GameState.economy_stage="currency"
	GameState.known_discoveries.append_array(["public_libraries","comparative_chronicles"])
	E.connection("neighbor");E.owner_state("neighbor").settlement_name="People of the Cedar River"
	E.data().integration=[{"origin":"neighbor","count":12.0,"remaining":9.0}]
	var selected_id:=""
	for index in 85:
		var item:=A.find_at(777,Vector2(index*24,100),1)
		item.returned_day=3400+index;item.study=1.0 if index%2==0 else 0.25;item.held_days=365.0
		E.data().collections[item.id]=item
		if index==0:selected_id=item.id
	for index in 50:
		var item:=A.find_at(777,Vector2(index*24,900),1)
		item.name="Cedar piece %02d" % index;item.rarity=0
		E.owner_state("neighbor").society_exchange.collections[item.id]=item
	E.data().collections[selected_id].erase("insight")
	E.data().collections[selected_id].merge(preload("res://scripts/prehistoric_artifacts.gd").definition(0),true)
	E.data().collections[selected_id].rarity=4
	output=arg("out","res://artifacts/knowledge-exchange");tag=arg("tag","capture")
	DirAccess.make_dir_recursive_absolute(output)
	var canvases:Array[Vector2i]=[]
	for shape:String in arg("canvases","1600x900,2869x1337,1024x768,340x640").split(","):
		canvases.append(Vector2i(int(shape.get_slice("x",0)),int(shape.get_slice("x",1))))
	for canvas:Vector2i in canvases:
		for palette:String in ["dark","light"]:
			T.set_color_mode(palette)
			var viewport:=SubViewport.new();viewport.size=canvas;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.gui_embed_subwindows=true;add_child(viewport)
			var layer:=CanvasLayer.new();viewport.add_child(layer);var sheet:=Sheet.new();sheet.selected_id=selected_id;layer.add_child(sheet)
			await settle()
			await capture(viewport,sheet,"selected",palette)
			sheet.select_piece.pressed.emit();await settle()
			check(sheet.choices.get_child_count()==6,"Chooser is six records")
			check(sheet.select_piece.size.y<=48,"Chooser control remains a compact button")
			await capture(viewport,sheet,"chooser",palette)
			sheet.page=14;sheet.refresh(true);await settle()
			check(sheet.choices.get_child_count()==1,"Oldest piece is reachable")
			await capture(viewport,sheet,"last-page",palette)
			sheet.search.text="no such piece";sheet.search.text_changed.emit(sheet.search.text);await settle()
			await capture(viewport,sheet,"no-match",palette)
			sheet.select_piece.pressed.emit();sheet.home_toggle.pressed.emit();sheet.outer.scroll_vertical=9999;await settle()
			await capture(viewport,sheet,"policies",palette)
			check(not sheet.cards.visible and sheet.home_box.visible,"Policies replace object reader")
			sheet.reader_back.pressed.emit();sheet.study_toggle.pressed.emit();await settle()
			await capture(viewport,sheet,"study-help",palette)
			check(sheet.cards.visible and sheet.study_help.visible,"Short study explanation stays beside selected piece")
			sheet.study_toggle.pressed.emit()
			sheet.offer_id=selected_id;sheet.offer_to="neighbor";sheet.offer_mode="gift";sheet._build_offer();sheet.outer.scroll_vertical=0;await settle()
			await capture(viewport,sheet,"give",palette)
			sheet.offer_mode="trade";sheet.offer_query="Cedar piece 49";sheet.offer_want="";sheet._build_offer();await settle()
			var wanted:Sheet.VisibleChoice=sheet.offer_box.find_child("Wanted",true,false)
			check(wanted.item_count==2,"Swap search reaches record50")
			wanted.select(1);wanted.item_selected.emit(1);await settle()
			await capture(viewport,sheet,"swap",palette)
			var confirm:Button=sheet.offer_box.find_child("ConfirmOffer",true,false)
			check(not confirm.disabled,"Real swap passes original exchange check")
			sheet._cancel_offer();await settle()
			if canvas.x==1024:
				sheet.home_open=false;sheet.selected_id=selected_id
				E.data().collections[selected_id].study=0.25;GameState.elapsed_days+=1;sheet.refresh(false);sheet.outer.scroll_vertical=0;await settle()
				await capture(viewport,sheet,"live-study",palette)
				for button:Node in sheet.cards.find_children("*","Button",true,false):
					if button.text=="Put it on show":button.pressed.emit();break
				check(bool(E.data().collections[selected_id].exhibited),"Existing exhibit action works")
				var saved:Dictionary=E.data().collections.duplicate(true)
				E.data().collections.clear();sheet.refresh(true);await settle()
				await capture(viewport,sheet,"empty",palette)
				check(not sheet.select_piece.visible,"Empty collection has no inactive chooser")
				var item:={"id":"knowledge:oral_epics","kind":"knowledge","name":"The Cedar River telling","source_id":"neighbor","source_name":"People of the Cedar River","position":{"x":30.0,"z":0.0},"observed_day":3420,"returned_day":3470,"discovery_id":"oral_epics","study":0.25,"work":10.0,"signals":["research"]}
				E.data().collections[item.id]=item;sheet.refresh(true);await settle()
				await capture(viewport,sheet,"knowledge",palette)
				E.data().collections=saved;E.data().collections[selected_id].study=1.0;E.data().collections[selected_id].exhibited=false
				sheet.selected_id=selected_id;sheet.refresh(true);await settle()
				viewport.size=Vector2i(340,640);await settle()
				await capture(viewport,sheet,"resized",palette)
				viewport.size=canvas;await settle()
				await capture(viewport,sheet,"restored",palette)
			if canvas.x>700:
				var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2(40,180);viewport.push_input(click,true)
			else:
				var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;viewport.push_input(escape,true)
			await settle();check(not is_instance_valid(sheet),"Backdrop / Escape closes collection")
			viewport.queue_free();await get_tree().process_frame
	print("EXCHANGE_VISUAL ","PASS" if failures.is_empty() else failures)
	get_tree().quit(0 if failures.is_empty() else 1)
func capture(viewport:SubViewport,sheet:Control,screen:String,palette:String)->void:
	var name:="exchange-%s-%s-%s-%d" % [tag,screen,palette,viewport.size.x]
	var bounds:Rect2=sheet.panel.get_global_rect()
	check(Rect2(Vector2.ZERO,viewport.size).encloses(bounds),name+": panel bounds")
	for child:Node in sheet.panel.find_children("*","Control",true,false):
		if not child.is_visible_in_tree():continue
		if child is Label or child is BaseButton or child is LineEdit:
			var rect:Rect2=child.get_global_rect()
			check(rect.position.x>=bounds.position.x-1 and rect.end.x<=bounds.end.x+1,name+": horizontal bounds "+String(child.name))
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output.path_join(name+".png"))
