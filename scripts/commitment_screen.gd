extends Control
var civ_id:=""
var draft:Dictionary={}
var actions:OptionButton
var goals:OptionButton
var targets:OptionButton
var summary:RichTextLabel
var preview:Label
var outcome:Label
var send_button:Button
var aid_button:Button
var timer:=0.0

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var backdrop:=ColorRect.new(); backdrop.color=Color("091419"); backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(backdrop)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(margin)
	for edge:String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",14); margin.add_child(root)
	var header:=HBoxContainer.new(); root.add_child(header)
	var title:=Label.new(); title.text="THE COUNCIL OF NATIONS"; title.add_theme_font_size_override("font_size",25); title.add_theme_color_override("font_color",Color("dbc38d")); title.size_flags_horizontal=SIZE_EXPAND_FILL; header.add_child(title)
	var close:=Button.new(); close.text="RETURN TO THE CONVERSATION"; close.pressed.connect(queue_free); header.add_child(close)
	var sub:=Label.new(); sub.text="Promises, independent voices, and the cost of standing together"; sub.add_theme_color_override("font_color",Color("9caeae")); root.add_child(sub)
	summary=RichTextLabel.new(); summary.bbcode_enabled=false; summary.size_flags_vertical=SIZE_EXPAND_FILL; summary.add_theme_font_size_override("normal_font_size",17); root.add_child(summary)
	var row:=HBoxContainer.new(); root.add_child(row)
	actions=OptionButton.new(); actions.size_flags_horizontal=SIZE_EXPAND_FILL; row.add_child(actions)
	for key:String in ForeignDiplomacy.commitments.ACTIONS: actions.add_item(ForeignDiplomacy.commitments.ACTIONS[key]); actions.set_item_metadata(actions.item_count-1,key)
	goals=OptionButton.new(); row.add_child(goals)
	for key:String in ForeignDiplomacy.commitments.GOALS: goals.add_item(ForeignDiplomacy.commitments.GOALS[key]); goals.set_item_metadata(goals.item_count-1,key)
	targets=OptionButton.new(); row.add_child(targets); targets.add_item("Choose a war discussion target"); targets.set_item_metadata(0,"")
	for value:Dictionary in CivilizationSystem.civilizations:
		if int(value.player_relation.get("contact_level",0))>=2: targets.add_item(String(value.name)); targets.set_item_metadata(targets.item_count-1,String(value.id))
	for choice:OptionButton in [actions,goals,targets]: choice.item_selected.connect(func(_index:int): refresh())
	preview=Label.new(); preview.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; preview.add_theme_color_override("font_color",Color("dbc38d")); root.add_child(preview)
	var footer:=HBoxContainer.new(); root.add_child(footer)
	aid_button=Button.new(); aid_button.text="SEND PHYSICAL FOOD AID"; footer.add_child(aid_button)
	aid_button.pressed.connect(func():
		var result:=CivilizationSystem.dispatch_diplomat(civ_id,"Food","send_aid")
		outcome.text=String(result.get("error","Food aid departed with a physical delegation. It reaches the ally after travel.")); refresh())
	outcome=Label.new(); outcome.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; outcome.size_flags_horizontal=SIZE_EXPAND_FILL; footer.add_child(outcome)
	send_button=Button.new(); send_button.text="SEND TERMS BY ENVOY"; send_button.custom_minimum_size.y=42; footer.add_child(send_button)
	send_button.pressed.connect(func():
		var result:Dictionary=ForeignDiplomacy.commitments.send(civ_id,selected_terms())
		outcome.text=String(result.get("error","Envoys departed. Their return will settle the proposal.")); refresh())
	if not draft.is_empty():
		select_value(actions,String(draft.action)); select_value(goals,String(draft.goal)); select_value(targets,String(draft.target_id))
	refresh()

func select_value(choice:OptionButton,value:String)->void:
	for index:int in choice.item_count:
		if String(choice.get_item_metadata(index))==value: choice.select(index); return

func selected_terms()->Dictionary:
	var siege:Dictionary=ForeignDiplomacy.commitments.siege_info("current")
	var siege_id:=String(draft.get("siege_id",siege.get("id","")))
	return ForeignDiplomacy.commitments.terms(String(actions.get_selected_metadata()),String(goals.get_selected_metadata()),String(targets.get_selected_metadata()),siege_id)

func name_of(id:String)->String:
	if id=="player": return "Your civilization"
	return String(ForeignDiplomacy.civilization(id).get("name",id))

func refresh()->void:
	var model=ForeignDiplomacy.commitments
	var state:Dictionary=model.public_snapshot(civ_id)
	var lines:Array[String]=["MUTUAL PROTECTION · %s" % name_of(civ_id)]
	lines.append("No separate protection treaty." if state.protection.is_empty() else "Ratified day %d · future defensive sieges only.\n%s" % [int(state.protection.since),String(state.protection.obligation)])
	if state.league.is_empty(): lines.append("\nYOUR LEAGUE\nYou do not belong to a league.")
	else:
		lines.append("\n%s · %s" % [String(state.league.name).to_upper(),String(model.GOALS[state.league.goal])])
		for member:String in state.league.members:
			var leader_name:="You" if member=="player" else String(ForeignDiplomacy.leader(member).get("name","Independent leadership"))
			lines.append("  %s — %s" % [name_of(member),leader_name])
		lines.append(String(state.league.obligation))
		for member:String in state.league.votes: lines.append("%s: %s. %s" % [name_of(member),"CONSENTS" if bool(state.league.votes[member].accept) else "DISAGREES",String(state.league.votes[member].reason)])
	lines.append("\nPROMISES CALLED UPON")
	lines.append("Send food by delegation or direct your existing army from the military council. A promise alone sends neither supplies nor soldiers.")
	if state.obligations.is_empty(): lines.append("No defensive relief requests.")
	for obligation:Dictionary in state.obligations: lines.append("%s → %s · %s · day %d" % [name_of(obligation.donor),name_of(obligation.beneficiary),String(obligation.status),int(obligation.day)])
	for receipt:Dictionary in state.relief: lines.append("%s · %d relief troops · %s · expected day %d" % [name_of(receipt.donor),int(receipt.troops),String(receipt.status),int(receipt.due_day)])
	lines.append("\nRECENT DEALINGS")
	for item:Dictionary in state.history.slice(0,6): lines.append("Day %d · %s" % [int(item.day),String(item.text)])
	var text:="\n\n".join(lines)
	if summary.text!=text: summary.text=text
	var terms:=selected_terms()
	var aid_quote:=CivilizationSystem.diplomatic_mission_quote(civ_id,"Food","send_aid")
	aid_button.disabled=aid_quote.has("error")
	aid_button.tooltip_text=String(aid_quote.get("error","")) if aid_quote.has("error") else "%.1f Food delivered, plus %.1f travel rations; %d days round trip." % [float(aid_quote.gift.amount),float(aid_quote.provisions),int(aid_quote.total_days)]
	goals.visible=terms.action in ["found_faction","set_goal"]
	targets.visible=terms.action=="debate_war"
	var assessment:Dictionary=model.assessment(civ_id,terms)
	var quote:Dictionary=model.mission_quote(civ_id,terms)
	var blocker:=String(assessment.blocker)
	if blocker=="" and quote.has("error"): blocker=String(quote.error)
	send_button.disabled=blocker!=""
	preview.text=blocker if blocker!="" else "%s\n%s\nActual envoy provisions and consultation time are charged at departure. No Timber payment or automatic war.\nCurrent reception: %s; circumstances may change before the answer returns." % [String(model.ACTIONS[terms.action]),String(assessment.rule),"receptive" if bool(assessment.accepted) else "disagreement"]
	if not quote.has("error"): preview.text+="\n%d envoys · %.1f Food · %d days including league consultations" % [int(quote.personnel),float(quote.provisions)+float(quote.consultation_food),int(quote.total_days)+int(quote.consultation_days)]

func _process(delta:float)->void:
	timer+=delta
	if timer>=1: timer=0; refresh()
