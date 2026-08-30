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
	if MilitaryCommandUI.weapon_choice.item_count!=2: failures.append("Levy training should expose exactly its two compatible weapon families.")
	if MilitaryCommandUI.equipment_choice.item_count<10: failures.append("Production catalog is incomplete.")
	if MilitaryCommandUI.commander_portrait.texture==null or "CMD" not in MilitaryCommandUI.commander_details.text: failures.append("Commander portrait or command statistics are missing.")
	if MilitaryCommandUI.readiness_meters.size()!=6 or "▼" not in MilitaryCommandUI.readiness_bottleneck.text: failures.append("Readiness components or bottleneck display are missing.")
	if MilitaryCommandUI.prisoner_policy.item_count!=7 or MilitaryCommandUI.spoils_policy.item_count!=5 or MilitaryCommandUI.general_policy.item_count!=4: failures.append("Battle aftermath choices are incomplete.")
	MilitaryCampaign.pending_aftermath={"type":"rout","prisoners":4}
	MilitaryCommandUI._refresh()
	await get_tree().process_frame
	if not MilitaryCommandUI.aftermath_row.visible: failures.append("Pending battle aftermath is not exposed.")
	if panel.size.y>get_viewport().get_visible_rect().size.y-60.0: failures.append("Aftermath controls make the modal clip: %s." % panel.size)
	MilitaryCampaign.pending_aftermath.clear()
	MilitaryCampaign.active_threat={"title":"Probe raiders","estimated_strength":12,"deadline_day":9}
	MilitaryCommandUI._refresh()
	await get_tree().process_frame
	if not MilitaryCommandUI.threat_row.visible: failures.append("An approaching threat is not exposed in military command.")
	if panel.size.y>get_viewport().get_visible_rect().size.y-60.0: failures.append("Threat controls make the modal clip: %s." % panel.size)
	MilitaryCampaign.active_threat.clear()
	MilitaryCampaign.active_engagement={"round":2,"last_order":"push","attacker":{"name":"River Host","troops":18},"defender":{"name":"Raiders","troops":11}}
	MilitaryCommandUI._refresh()
	await get_tree().process_frame
	if not MilitaryCommandUI.engagement_row.visible: failures.append("A live campaign engagement does not expose round orders.")
	if panel.size.y>get_viewport().get_visible_rect().size.y-60.0: failures.append("Live battle controls make the modal clip: %s." % panel.size)
	MilitaryCampaign.active_engagement.clear()
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
