extends Control
var siege_id:=""
var status:Label

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg:=ColorRect.new(); bg.color=Color("0b181e"); bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(bg)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(margin)
	for edge:String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,30)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",16); margin.add_child(box)
	var title:=Label.new(); title.text="CALL UPON OUR PROMISES"; title.add_theme_font_size_override("font_size",26); title.add_theme_color_override("font_color",Color("dbc38d")); box.add_child(title)
	var explanation:=Label.new(); explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; explanation.text="Only promises made before this defensive siege apply. Envoys must carry the request; available troops and supplies are checked again when their answer returns. The relief force then makes its own journey."; box.add_child(explanation)
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=SIZE_EXPAND_FILL; box.add_child(scroll)
	var list:=VBoxContainer.new(); list.size_flags_horizontal=SIZE_EXPAND_FILL; list.add_theme_constant_override("separation",14); scroll.add_child(list)
	var count:=0
	for obligation:Dictionary in ForeignDiplomacy.commitments.state.obligations:
		if obligation.siege_id!=siege_id or obligation.beneficiary!="player": continue
		count+=1
		var donor:=String(obligation.donor)
		var row:=VBoxContainer.new(); list.add_child(row)
		var label:=Label.new(); label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label.text="%s · %s\n%s" % [String(ForeignDiplomacy.civilization(donor).get("name",donor)),String(ForeignDiplomacy.leader(donor).get("name","")),String(obligation.status)]
		row.add_child(label)
		var request:=Button.new(); request.text="SEND A REQUEST FOR RELIEF"; request.disabled=not ForeignDiplomacy.commitments.covered(donor,"player",siege_id); row.add_child(request)
		request.pressed.connect(func():
			var result:Dictionary=ForeignDiplomacy.commitments.send(donor,ForeignDiplomacy.commitments.terms("request_relief","defense","",siege_id))
			status.text=String(result.get("error","Envoys carry the request. Aid has not arrived yet.")))
	if count==0:
		var empty:=Label.new(); empty.text="No eligible protection or league promise covers this siege."; list.add_child(empty)
	status=Label.new(); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(status)
	var close:=Button.new(); close.text="RETURN TO THE SIEGE"; close.pressed.connect(queue_free); box.add_child(close)
