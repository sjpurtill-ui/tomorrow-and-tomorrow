extends Node
const Preferences=preload("res://scripts/display_preferences.gd")
class TestMap:
	extends "res://scripts/local_terrain.gd"
	var quit_called:=false
	var saves_attempted:=0
	var save_result:Dictionary={"error":"Simulated disk full"}
	func _save_before_quit()->Dictionary:
		saves_attempted+=1
		return save_result
	func _finish_quit()->void:quit_called=true

var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)

func _ready()->void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	AudioServer.set_bus_mute(0,true)
	GameState.reset_for_new_world(184271)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	var terrain:=TestMap.new()
	var score:=AudioStreamPlayer.new();score.name="Score";terrain.add_child(score)
	add_child(terrain)
	terrain.game_speed=0;terrain.set_process(false)
	var prefs:Node=terrain.display_preferences
	var window:=get_window()
	for pixels in [Vector2i(1280,720),Vector2i(1440,900)]:
		window.size=pixels
		for scale in [1.0,1.25,1.5,1.75]:
			prefs.ui_scale=scale;prefs.apply()
			terrain._open_world_menu()
			for i in 4:await get_tree().process_frame
			var view:=window.get_visible_rect().size
			var modal:Control=terrain.world_menu_panel.get_node("PauseMenuBody")
			check(Rect2(Vector2.ZERO,view).encloses(modal.get_rect()),"pause menu fits "+str(pixels)+" scale "+str(scale))
			var scroll:=modal.get_node_or_null("PauseMenuScroll") as ScrollContainer
			if scroll==null:
				print("MENU_CHILDREN: ",modal.get_children())
				get_tree().quit(1);return
			var content:=scroll.get_children().filter(func(child:Node):return child is VBoxContainer)[0] as Control
			check(scroll.size.y<content.size.y,"long menu remains scrollable")
			check(content.size.x<=scroll.size.x,"menu does not overflow horizontally")
			var pan_slider:=content.get_node("MapScrollSpeed") as HSlider
			check(scroll.get_global_rect().encloses(pan_slider.get_global_rect()),"map speed slider is visible immediately on opening menu")
			if "--capture-display" in OS.get_cmdline_user_args() and scale==1.75:
				await RenderingServer.frame_post_draw
				window.get_texture().get_image().save_png("res://artifacts/display-%dx%d.png"%[pixels.x,pixels.y])
				scroll.scroll_vertical=10000
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				window.get_texture().get_image().save_png("res://artifacts/display-bottom-%dx%d.png"%[pixels.x,pixels.y])
			terrain._close_world_menu()
			for i in 2:await get_tree().process_frame
			var hud:Control=terrain.hud
			check(Rect2(Vector2.ZERO,view).encloses(hud.rail_panel.get_rect()),"rail fits enlarged canvas")
			check(Rect2(Vector2.ZERO,view).encloses(hud.time_pill.get_rect()),"time controls fit enlarged canvas")
			terrain._on_hud_section_requested("military",0)
			for i in 4:await get_tree().process_frame
			check(Rect2(Vector2.ZERO,view).encloses(hud.dock.get_rect()),"military dock fits enlarged canvas")
			hud.handle_escape()
	prefs.render_scale=0.5;prefs.apply()
	check(is_equal_approx(window.scaling_3d_scale,0.5),"3D resolution applies")
	check(window.content_scale_mode==Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,"UI retains canvas output resolution")
	prefs.shadows=false;prefs.frame_limit=30;prefs.apply()
	for child in terrain.get_children():
		if child is DirectionalLight3D:check(not child.shadow_enabled,"shadow cost disabled")
	check(Engine.max_fps==30,"frame ceiling applies")
	var master_db:=AudioServer.get_bus_volume_db(0)
	prefs.music_volume=0.4;prefs.apply_music()
	var music_bus:=AudioServer.get_bus_index("Music")
	check(score.bus=="Music" and is_equal_approx(AudioServer.get_bus_volume_db(music_bus),linear_to_db(0.4)),"music routing and gain apply")
	check(AudioServer.get_bus_volume_db(0)==master_db,"other audio routing unchanged")
	prefs.music_volume=0;prefs.apply_music()
	check(AudioServer.is_bus_mute(music_bus),"zero mutes music")
	prefs.config_path="res://artifacts/test-display.cfg";prefs.persist()
	var restored:=Preferences.new();restored.config_path=prefs.config_path;terrain.add_child(restored)
	check(restored.music_volume==0 and restored.ui_scale==prefs.ui_scale and restored.render_scale==prefs.render_scale,"preferences survive new settings instance")
	restored.free()
	var save_path:="res://artifacts/atomic-save-test.save"
	check(SaveSystem._write_payload(save_path,{"test":1}).get("ok",false),"temporary save writes successfully")
	check(SaveSystem._write_payload(save_path,{"test":2}).get("ok",false),"atomic replacement succeeds")
	check(str_to_var(FileAccess.get_file_as_string(save_path))=={"test":2} and not FileAccess.file_exists(save_path+".tmp"),"completed save replaces prior data")
	DirAccess.make_dir_absolute(save_path+".tmp")
	check(SaveSystem._write_payload(save_path,{"test":3}).has("error"),"blocked temporary write reports failure")
	check(str_to_var(FileAccess.get_file_as_string(save_path))=={"test":2},"failed replacement preserves previous save")
	DirAccess.remove_absolute(save_path+".tmp")
	check(SaveSystem._write_payload("res://artifacts/missing-dir/failure.save",{"test":3}).has("error"),"failed write is reported")
	terrain._request_quit()
	check(is_instance_valid(terrain.quit_dialog),"Quit confirmation available")
	terrain._save_and_quit()
	check(not terrain.quit_called and terrain.saves_attempted==1,"save failure prevents exit")
	check("Simulated disk full" in terrain.quit_dialog.dialog_text,"save failure shown")
	terrain.save_result={"ok":true};terrain._save_and_quit()
	check(terrain.quit_called and terrain.saves_attempted==2,"successful save precedes exit")
	terrain.quit_called=false;terrain.quit_dialog.custom_action.emit("discard")
	check(terrain.quit_called and terrain.saves_attempted==2,"explicit discard skips save")
	terrain.quit_called=false;terrain.quit_dialog.hide();terrain.quit_dialog.canceled.emit()
	check(not terrain.quit_called and not is_instance_valid(terrain.world_menu_panel),"cancel leaves world open")
	var key:=InputEventKey.new();key.keycode=KEY_Q;key.meta_pressed=true;key.pressed=true
	window.push_input(key,true)
	check(terrain.quit_dialog.visible and not terrain.quit_called,"Command Q opens confirmation")
	terrain.quit_dialog.hide()
	print("MAC_DISPLAY_CHECKS: ",checks,"; FAILURES: ",failures)
	terrain.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
