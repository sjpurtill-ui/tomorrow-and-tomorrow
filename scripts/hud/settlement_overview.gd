extends "res://scripts/hud/production_queue.gd"
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Buildings:=preload("res://scripts/hud/construction_art.gd")
const Food:=preload("res://scripts/hud/provisions_art.gd")
var cards:GridContainer
func setup(block:Dictionary)->void:
	data=block;name="SettlementOverview";add_theme_constant_override("separation",16)
	var leader:Dictionary=data.leader
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",20);add_child(head)
	if not leader.is_empty():head.add_child(Portrait.picture(leader,112,140))
	var story:=VBoxContainer.new();story.size_flags_horizontal=Control.SIZE_EXPAND_FILL;story.add_theme_constant_override("separation",6);head.add_child(story)
	story.add_child(T.make_label("LOCAL LEADERSHIP",11,T.GOLD))
	story.add_child(_serif(String(leader.get("name","Awaiting a leader")),26))
	_note(story,"%s · age %d" % [String(leader.get("title","Local leader")),int(leader.get("age",0))] if not leader.is_empty() else "A successor will be appointed from the local governing pool.")
	_note(story,String(data.focus)+" · "+("Leader managed" if bool(data.managed) else "Your direction"))
	var actions:=HFlowContainer.new();story.add_child(actions)
	_button(actions,"Speak with leader",data.on_leader,"Open the local council")
	_button(actions,"Priorities",data.on_priority,"View or change the current direction")
	_rule(self)
	var headline:=HBoxContainer.new();headline.add_theme_constant_override("separation",18);add_child(headline)
	for metric:Dictionary in data.metrics:
		var stack:=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;headline.add_child(stack)
		stack.add_child(_serif(String(metric.value),30));stack.add_child(T.make_label(String(metric.label),11,T.MUTED))
	_rule(self)
	cards=GridContainer.new();cards.columns=3;cards.add_theme_constant_override("h_separation",16);cards.add_theme_constant_override("v_separation",16);add_child(cards)
	for item:Dictionary in data.cards:
		var panel:=VBoxContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cards.add_child(panel)
		var art:TextureRect=Food.picture(int(item.art),0,112) if item.kind=="food" else Buildings.picture(int(item.art),0,112)
		if item.kind!="food":
			var source:=art.texture as AtlasTexture
			var crop:=source.region;crop.position.y+=crop.size.y*.20;crop.size.y*=.70;source.region=crop
		art.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(art)
		panel.add_child(_serif(String(item.title),20));_note(panel,String(item.detail))
		_button(panel,String(item.action),item.on_press,String(item.detail))
	_rule(self)
	add_child(T.make_label("CURRENT DIRECTION",11,T.GOLD));_note(self,String(data.reason));_note(self,String(data.effect))
	var footer:=HFlowContainer.new();add_child(footer)
	_button(footer,"Population & age groups",data.on_population,"Population history and age structure")
	_button(footer,"Daily work",data.on_work,"Local labor assignments")
	_button(footer,"Rename settlement",data.on_rename,"Change this place’s map name")
	resized.connect(_layout);_layout()
func _layout()->void:
	if cards:cards.columns=3 if size.x>=650 else 2
func _serif(value:String,font_size:int)->Label:
	var label:=T.make_label(value,font_size,T.INK);var font:=SystemFont.new();font.font_names=PackedStringArray(["Georgia"]);label.add_theme_font_override("font",font);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label
func _note(parent:Node,value:String)->void:
	var label:=T.make_label(value,13,T.BODY);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label)
