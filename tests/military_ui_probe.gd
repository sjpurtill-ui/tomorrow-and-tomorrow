extends Node


func _ready()->void:
	await get_tree().process_frame
	var panel:PanelContainer=MilitaryCommandUI.modal
	MilitaryCommandUI._toggle()
	await get_tree().process_frame
	var failures:Array[String]=[]
	if panel==null: failures.append("Military modal was not created.")
	elif panel.size.x>get_viewport().get_visible_rect().size.x-80.0 or panel.size.y>get_viewport().get_visible_rect().size.y-60.0: failures.append("Military modal exceeds the safe viewport: %s." % panel.size)
	if not _descendants_of_type(panel,"ScrollContainer").is_empty(): failures.append("Military modal must not require scrolling.")
	if MilitaryCommandUI.unit_choice.item_count<6: failures.append("Unit catalog is incomplete.")
	if MilitaryCommandUI.weapon_choice.item_count<7: failures.append("Weapon catalog is incomplete.")
	if MilitaryCommandUI.equipment_choice.item_count<10: failures.append("Production catalog is incomplete.")
	if not panel.visible: failures.append("Military modal did not open.")
	MilitaryCommandUI._toggle()
	if panel.visible: failures.append("Military modal did not close.")
	if not failures.is_empty():
		for failure in failures: push_error(failure)
		get_tree().quit(1)
		return
	print("MILITARY_UI_PROBE size=%s units=%d production=%d no_scroll=true" % [panel.size,MilitaryCommandUI.unit_choice.item_count,MilitaryCommandUI.equipment_choice.item_count])
	get_tree().quit(0)


func _descendants_of_type(root:Node,type_name:String)->Array[Node]:
	var matches:Array[Node]=[]
	for child in root.get_children():
		if child.is_class(type_name): matches.append(child)
		matches.append_array(_descendants_of_type(child,type_name))
	return matches
