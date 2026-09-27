extends Node
## Isolated capture of the send-envoys sheet (scripts/hud/envoy_dispatch_screen.gd)
## over the Council fixture: an ultimatum being drafted, a goodwill gift, and
## the sheet while the envoys are away. Saves artifacts/envoy-dispatch-*.png,
## checks the sheet fits the window, and exits.

const Screen:=preload("res://scripts/hud/envoy_dispatch_screen.gd")

func _snap(file:String)->void:
	for frame in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+file)

func _ready()->void:
	DisplayServer.window_set_title("TEST CAPTURE · Send envoys · closes automatically")
	GameState.civic_api_enabled=false
	var id:=preload("res://tests/commitment_ui_probe.gd").build_fixture()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var sheet=Screen.new(); sheet.civ_id=String(CivilizationSystem.civilizations[2].id); add_child(sheet)
	await _snap("envoy-dispatch-open.png")
	sheet.choose("ultimatum"); sheet.pick_demand("tribute"); sheet.pick_token("broken_spear")
	await _snap("envoy-dispatch-ultimatum.png")
	var scroll:ScrollContainer=sheet.find_child("Message",true,false)
	scroll.scroll_vertical=100000
	await _snap("envoy-dispatch-ultimatum-words.png")
	var view:=get_viewport().get_visible_rect()
	var valid:bool=view.encloses(sheet.card.get_global_rect()) and view.encloses(sheet.send_button.get_global_rect()) and view.encloses(sheet.close_button.get_global_rect())
	sheet.address(id); sheet.choose("goodwill")
	await _snap("envoy-dispatch-goodwill.png")
	valid=valid and not sheet.send().has("error")
	await _snap("envoy-dispatch-away.png")
	print("ENVOY_DISPATCH ","PASS" if valid else "FAIL")
	get_tree().quit(0 if valid else 1)
