extends Node
## Compiles every script this branch touched with autoloads present.
func _ready()->void:
	var bad:=0
	for path in ["res://scripts/audience_voice.gd","res://scripts/foreign_dialogue.gd","res://scripts/general_dialogue.gd","res://scripts/hud/ai_connection_panel.gd","res://scripts/hud/dock_blocks.gd","res://scripts/hud/content/dock_content_civilization.gd","res://scripts/settlement_construction.gd","res://scripts/custom_directive.gd","res://scripts/village_notables.gd"]:
		var script:=load(path) as Script
		if script==null or not script.can_instantiate():
			bad+=1
			push_error("LOAD FAIL %s" % path)
	var panel:Node=load("res://scripts/hud/ai_connection_panel.gd").new()
	add_child(panel)
	await get_tree().process_frame
	if panel.find_child("AiModeSelector",true,false)==null or panel.find_child("ExportInteractions",true,false)==null:
		bad+=1
		push_error("AI mode selector or export button missing")
	panel.queue_free()
	print("RESPONSIVE_LOAD_CHECK %s" % ("PASS" if bad==0 else "FAIL"))
	get_tree().quit(0 if bad==0 else 1)
