extends CanvasLayer
## A city we hold, as its garrison commander would brief it: how firmly we
## hold it, how its people are faring and how we rule it. Every decision about
## the city and its people is spoken in court, to the commander or the war
## leader; this sheet gives no orders of its own.
const MODEL=preload("res://scripts/occupation_governance.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const P=preload("res://scripts/hud/paper_sheet.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
var civ_id:=""
var region_id:=""
var canvas:Control
var panel:PanelContainer
var summary:Label
var alert:Label
var detail:Label
var feedback:Label
var rows:VBoxContainer
var talk:Button
var current:Dictionary={}
var timer:=0.0
var signature:=""

static func open(civ:String,region:String)->void:
	var view=load("res://scripts/hud/occupation_view.gd").new();view.civ_id=civ;view.region_id=region
	Engine.get_main_loop().root.add_child(view)

func _ready()->void:
	layer=79
	canvas=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.theme=T.control_theme();add_child(canvas)
	panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",P.sheet_style(18));canvas.add_child(panel)
	panel.minimum_size_changed.connect(_layout.call_deferred)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);panel.add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);column.add_child(top)
	var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;names.add_theme_constant_override("separation",0);top.add_child(names)
	P.kicker(names,"Garrison briefing")
	summary=P.label(names,"A city we hold","title",T.INK)
	var close:=P.button(top,"Close",queue_free);close.name="Close";close.size_flags_horizontal=Control.SIZE_SHRINK_END;close.custom_minimum_size=Vector2(96,38);close.tooltip_text="Close (Esc)"
	alert=P.label(column,"","body",T.BODY)
	P.rule(column)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=260;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",10);scroll.add_child(rows)
	detail=P.label(column,"","small",T.BODY)
	P.rule(column)
	P.kicker(column,"Talk it over in court")
	P.label(column,"How we rule this city, who is moved and what becomes of it are said in court. The commander carries out what you decide.","small",T.BODY)
	talk=P.button(column,"Talk to the commander",_talk,true);talk.name="TalkGeneral"
	feedback=P.label(column,"","small",T.BODY)
	var world:=CityEncounterWorld.terrain(get_tree().root)
	if world!=null:CityEncounterWorld.focus(world,region_id)
	canvas.resized.connect(_layout);_refresh();_layout()

func _layout()->void:
	if panel==null:return
	var screen:=get_viewport().get_visible_rect().size
	var width:=minf(560,screen.x-24);panel.position=Vector2(screen.x-width-12,12);panel.size=Vector2(width,minf(panel.get_combined_minimum_size().y,screen.y-24))
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	timer+=delta
	if timer>=.5:timer=0;_refresh()

func _commander()->Dictionary:
	for force:Dictionary in MilitaryCampaign.field_armies:
		if String(force.get("location_id",""))==region_id:return P.general_for(force)
	return P.war_leader()

func _talk()->void:
	var leader:=_commander()
	queue_free();P.summon(leader.get("target",{}))

static func _level(value:float,words:Array)->String:
	return String(words[clampi(int(value*words.size()),0,words.size()-1)])

func _row(title:String,text:String,value:float,accent:Color)->void:
	var card:=P.card(rows,accent)
	var head:=HBoxContainer.new();card.add_child(head)
	var name:=P.label(head,title,"value",T.INK,false);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(120,8);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.value=clampf(value,0,1)*100
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK,Color(0,0,0,0),0,2));bar.add_theme_stylebox_override("fill",T.flat(accent,Color(0,0,0,0),0,2));head.add_child(bar)
	P.label(card,text,"small",T.BODY)

func _refresh()->void:
	current=CivilizationSystem.occupation_governance_snapshot(civ_id,region_id)
	if current.is_empty():
		summary.text="We no longer hold this city";alert.text="Its control has changed. The map shows how things stand now.";rows.hide();talk.hide();return
	var data:=current
	var leader:=_commander()
	talk.text=P.talk_label(leader,"Talk to our war leader")
	summary.text=String(data.name)
	var next:=JSON.stringify([data.garrison,data.required_garrison,data.policy,roundi(float(data.get("resistance",0))*20),roundi(float(data.get("welfare",0))*20),roundi(float(data.get("trust",0))*20),roundi(float(data.get("damage",0))*20),roundi(float(data.get("grievance",0))*20),data.get("control",{}),leader.get("name","")])
	if next==signature:return
	signature=next
	var control:Dictionary=data.get("control",{})
	var soldiers:=int(control.get("troops",data.garrison))
	var needed:=ceili(float(data.required_garrison))
	var hold:="enough to keep order" if not control.has("error") else "too few, or too hungry, to keep order"
	alert.text="%s people live here. %s of our soldiers hold it; %s needs about %s, and they are %s." % [EraWords.grouped(roundi(float(data.population))),EraWords.grouped(soldiers),String(data.name),EraWords.grouped(needed),hold]
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	var rules:Dictionary=MODEL.POLICIES.get(String(data.policy),{})
	_row("How we rule it","%s. %s" % [String(rules.get("label","Our own way")),String(rules.get("description",""))],float(rules.get("rights",.5)),T.GOLD)
	_row("Resistance","%s. Hunger, a weak garrison and harm done to them feed it; order and fair rule calm it over time." % _level(float(data.get("resistance",0)),["They accept us","A few grumble","Many resent us","They resist openly","They are close to rising"]),float(data.get("resistance",0)),T.RED)
	_row("How its people fare","%s. They %s us." % [_level(float(data.get("welfare",0)),["They suffer badly","They go without","They get by","They live well"]),_level(float(data.get("trust",0)),["do not trust","barely trust","somewhat trust","trust"])],float(data.get("welfare",0)),T.TEAL)
	_row("Old wrongs","%s. Old wrongs fade slowly, over lifetimes." % _level(float(data.get("grievance",0)),["Few grudges are held","Some grudges are held","Deep grudges are held","Bitter hatred runs deep"]),float(data.get("grievance",0)),T.AMBER)
	_row("Damage","%s. %s" % [_level(float(data.get("damage",0)),["The city stands whole","Some of it is damaged","Much of it lies broken","Most of it is in ruins"]),"Repairs are under way." if bool(data.get("reconstruction",false)) else "No one is rebuilding it."],float(data.get("damage",0)),T.BLUE)
	detail.text="%s of its people want to be free of us." % _level(float(data.get("support",0)),["Almost none","Some","Many","Most"])
	_layout()
