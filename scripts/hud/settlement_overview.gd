extends "res://scripts/hud/home_ledger.gd"
## The Settlement dock's first page: who runs the place and what they are
## putting extra hands on, one plain way to ask for more hands elsewhere, the
## place at a glance, whether our leaders found new towns on their own, and
## the water and waste works it can start.
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Buildings:=preload("res://scripts/hud/construction_art.gd")
const Food:=preload("res://scripts/hud/provisions_art.gd")
var cards:GridContainer
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="SettlementOverview";add_theme_constant_override("separation",16)
	var leader:Dictionary=data.leader
	var first:=String(leader.get("name","")).get_slice(" ",0)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",20);add_child(head)
	if not leader.is_empty():head.add_child(Portrait.picture(leader,156,156))
	var story:=VBoxContainer.new();story.size_flags_horizontal=Control.SIZE_EXPAND_FILL;story.add_theme_constant_override("separation",6);head.add_child(story)
	story.add_child(T.make_label("LOCAL LEADER",12,T.GOLD))
	story.add_child(_serif(String(leader.get("name","No leader yet")),26))
	_note(story,"%s, age %d" % [String(leader.get("title","Local leader")),int(leader.get("age",0))] if not leader.is_empty() else "The government will appoint someone from among the people.")
	_line(story,String(data.get("direction","")),13,T.BODY).name="Direction"
	var actions:=HFlowContainer.new();story.add_child(actions)
	_button(actions,"Talk with %s in court" % first if not first.is_empty() else "Open the court",data.on_leader,"Call the leader to the court to talk, give orders or replace them")
	if bool(data.get("can_direct",false)):
		_choices(self,"Ask %s for more hands on" % (first if not first.is_empty() else "the leader"),data.get("choices",[]),String(data.get("current",""))).name="AskForHands"
	_rule(self)
	var headline:=HBoxContainer.new();headline.add_theme_constant_override("separation",18);add_child(headline)
	for metric:Dictionary in data.metrics:
		var stack:=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;headline.add_child(stack)
		stack.add_child(_serif(String(metric.value),26));stack.add_child(T.make_label(String(metric.label),13,T.MUTED))
	var founding:Dictionary=data.get("founding",{})
	if not founding.is_empty():_new_towns(founding)
	_rule(self)
	cards=GridContainer.new();cards.columns=3;cards.add_theme_constant_override("h_separation",16);cards.add_theme_constant_override("v_separation",16);add_child(cards)
	for item:Dictionary in data.cards:
		var panel:=VBoxContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cards.add_child(panel)
		if bool(item.get("show_art",true)):
			var art:TextureRect=Food.picture(int(item.art),0,112) if item.kind=="food" else Buildings.picture(int(item.art),0,112)
			if item.kind!="food" and not Portrait.Early.active():
				var source:=art.texture as AtlasTexture
				var crop:=source.region;crop.position.y+=crop.size.y*.20;crop.size.y*=.70;source.region=crop
			art.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(art)
		else:
			var empty:=T.make_label(String(item.get("empty_label","Nothing built yet")),13,T.MUTED)
			empty.custom_minimum_size.y=112
			empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			panel.add_child(empty)
		panel.add_child(_serif(String(item.title),20));_note(panel,String(item.detail))
		_button(panel,String(item.action),item.on_press,String(item.detail))
	var works:Dictionary=data.get("works",{})
	if not works.is_empty():_works(works)
	_rule(self)
	var footer:=HFlowContainer.new();footer.add_theme_constant_override("h_separation",8);add_child(footer)
	_button(footer,"Ages and families",data.on_population,"How many children, workers and elders live here")
	_button(footer,"Who does what",data.on_work,"How the leader shares out the daily work")
	_button(footer,"Rename this place",data.on_rename,"Change the name on the map")
	resized.connect(_layout);_layout()

## New towns (auto_founding.gd): whether our leaders found them on their own,
## said in plain words, and the one click that changes it. The same switch as
## the court's word and the "Our course" page.
func _new_towns(founding:Dictionary)->void:
	_rule(self)
	var box:=VBoxContainer.new();box.name="NewTowns";box.add_theme_constant_override("separation",6);add_child(box)
	box.add_child(_voice("New towns",20))
	_line(box,String(founding.get("words","")),13,T.BODY).name="NewTownsWords"
	_choices(box,"",founding.get("options",[]),"leaders" if bool(founding.get("on",true)) else "ruler").name="NewTownsChoice"

## Water and waste works: what is built, and what can be started, each with
## its cost and time and one verb.
func _works(works:Dictionary)->void:
	_rule(self)
	var box:=VBoxContainer.new();box.name="WaterWorks";box.add_theme_constant_override("separation",8);add_child(box)
	box.add_child(T.make_label("WATER AND WASTE WORKS",12,T.GOLD))
	for line:String in works.get("progress",[]):_line(box,line,13,T.BODY)
	if (works.get("progress",[]) as Array).is_empty():_line(box,"Nothing is built yet. Clean water and waste kept apart from it mean fewer sick.",13,T.MUTED)
	for offer:Dictionary in works.get("offers",[]):
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);box.add_child(row)
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
		text.add_child(_serif(String(offer.title),18))
		_line(text,String(offer.sentence),13,T.BODY)
		var ready:=String(offer.get("blocked","")).is_empty()
		_line(text,String(offer.cost) if ready else String(offer.blocked),13,T.MUTED if ready else tone_color("warn"))
		var start:=_button(row,String(offer.action),offer.get("on_press"),String(offer.cost) if ready else String(offer.blocked))
		start.name="Start_"+String(offer.id).replace(":","_");start.size_flags_vertical=Control.SIZE_SHRINK_CENTER

func _layout()->void:
	if cards:cards.columns=3 if size.x>=650 else 2
func _serif(value:String,font_size:int)->Label:
	return _voice(value,font_size)
func _note(parent:Node,value:String)->void:
	_line(parent,value,13,T.BODY)
