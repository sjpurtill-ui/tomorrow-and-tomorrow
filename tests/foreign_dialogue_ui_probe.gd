extends Node
func _ready()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	var civ:Dictionary=CivilizationSystem.civilizations[0]; var id:String=civ.id
	civ.player_relation.contact_level=2
	var p:=ForeignDiplomacy.leader(id); p["audience_day"]=0
	ForeignDialogue._append(id,"user","I disagree with the cost. Why should our people bear it?")
	ForeignDialogue.accept(id,{"reply":"We can disagree about the burden and still find common ground. Let us discuss shared routes before committing either people. What matters most to you: safer travel or access to teachers?","accord":"routes","tone":"equals","generous":false})
	ForeignDiplomacy.open(id)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/foreign-dialogue-ui.png")
	ForeignDiplomacy.panel.show_section(1)
	await get_tree().process_frame;await get_tree().process_frame
	var bounds:=get_viewport().get_visible_rect()
	if not bounds.encloses(ForeignDiplomacy.panel.submit.get_global_rect()):
		push_error("Foreign dialogue submit control escaped viewport")
		get_tree().quit(1); return
	print("FOREIGN_DIALOGUE_UI PASS")
	get_tree().quit()
