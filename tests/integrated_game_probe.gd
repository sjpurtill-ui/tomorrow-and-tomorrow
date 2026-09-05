extends Node
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)
func _ready()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world()
	var terrain:Node3D=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_instance_valid(PeopleDirection.panel),"New ambitions absent from actual main scene")
	PeopleDirection.choose("makers")
	PeopleDirection.panel.queue_free()
	await get_tree().process_frame
	check(terrain.game_speed==1,"Opening did not resume current map")
	terrain._set_game_speed(0)
	var position:Vector3=terrain.world_start_position
	terrain.camera.size=2; terrain.camera_target=position
	var force:Dictionary={"army_id":111,"name":"Integration fixture","troops":1200,"position":{"x":position.x,"z":position.z},"formations":[{"unit":"line_infantry","count":1200}],"status":"stationary"}
	terrain._refresh_close_army_figures([force],111)
	check(terrain.close_army_figures.size()==1,"Current map did not display army figures")
	if not terrain.close_army_figures.is_empty(): check(terrain.close_army_figures["111"].figure_count<=256,"Unbounded map figures")
	CivilizationSystem.initialize()
	var civ:Dictionary=CivilizationSystem.civilizations[0]; civ.player_relation.contact_level=2
	ForeignDiplomacy.open(String(civ.id))
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_instance_valid(ForeignDiplomacy.panel),"Leader screen failed in current game")
	var screen:Control=ForeignDiplomacy.panel
	var bottom:float=screen.submit.global_position.y+screen.submit.size.y
	check(bottom<=get_viewport().get_visible_rect().size.y,"Leader controls overflow viewport")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--integration-capture="):
			await get_tree().create_timer(.4).timeout
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--integration-capture="))
	var saved_name:String=ForeignDiplomacy.leader(String(civ.id)).name
	var save:=SaveSystem.save_game("integration_probe")
	check(save.get("ok",false),"Integrated save failed")
	var load_result:=SaveSystem.load_game("integration_probe")
	check(load_result.get("ok",false),"Integrated load failed: "+str(load_result))
	check(PeopleDirection.ambition=="makers","Saved ambition lost")
	check(ForeignDiplomacy.leader(String(civ.id)).get("name","")==saved_name,"Saved foreign identity lost")
	check(not HistoricalFigures.people.is_empty(),"Saved chronicle lost")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.slot_path("integration_probe")))
	terrain.queue_free()
	await get_tree().process_frame
	print("INTEGRATED_GAME "+("PASS: actual opening, current map crowds, leader layout, combined save/load" if failures.is_empty() else "FAIL"))
	get_tree().quit(0 if failures.is_empty() else 1)
