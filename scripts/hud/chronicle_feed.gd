extends VBoxContainer
## The Chronicle feed: moments and notices as the story of the people, newest
## first, grouped by year. Seasonal tallies (whispers) appear only when asked.
## Wording follows the era: hearth-tales and tally-marks, later the annals.

const Chronicle:=preload("res://scripts/chronicle.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const PAGE:=40

var data:Dictionary={}
var shown:=PAGE
var list:VBoxContainer


func setup(block:Dictionary)->void:
	data=block;name="ChronicleFeed";add_theme_constant_override("separation",10)
	var voice:Dictionary=block.get("voice",Chronicle.voice())
	var intro:=T.make_label(String(voice.get("subtitle","")),12,T.MUTED);intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(intro)
	list=VBoxContainer.new();list.add_theme_constant_override("separation",8);add_child(list)
	_fill()


## Kept across a live refresh (see view_state.gd): how far back the reader has
## opened the feed.
func view_state()->Dictionary:return {"shown":shown}
func restore_view_state(state:Dictionary)->void:
	var wanted:=int(state.get("shown",PAGE))
	if wanted!=shown:shown=wanted;_fill()


func _fill()->void:
	for child in list.get_children():list.remove_child(child);child.queue_free()
	var entries:Array=data.get("entries",[])
	var voice:Dictionary=data.get("voice",Chronicle.voice())
	if entries.is_empty():
		var quiet:=T.make_label("Nothing has been told yet. The story of the people begins at the first fire.",13,T.TEXT_SOFT)
		quiet.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(quiet);return
	var year:=-1
	for i in mini(shown,entries.size()):
		var entry:Dictionary=entries[i]
		var entry_year:=int(entry.get("day",0))/365+1
		if entry_year!=year:
			year=entry_year
			var heading:=T.make_label("YEAR %d" % year,11,T.GOLD,0.12);list.add_child(heading)
			var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size=Vector2(0,1);list.add_child(rule)
		match String(entry.get("tier","notice")):
			"moment":_moment(entry,voice)
			"whisper":_whisper(entry)
			_:_notice(entry)
	if entries.size()>shown:
		var more:=Button.new();more.text="Older tales" if String(voice.get("era",""))=="tally" else "Earlier annals"
		more.pressed.connect(func()->void:shown+=PAGE;_fill());list.add_child(more)


func _serif(text:String,size:int,color:Color)->Label:
	var label:=T.make_label(text,size,color)
	var serif:=SystemFont.new();serif.font_names=PackedStringArray(["Georgia","Noto Serif","serif"])
	label.add_theme_font_override("font",serif);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


func _moment(entry:Dictionary,voice:Dictionary)->void:
	var frame:=PanelContainer.new()
	frame.add_theme_stylebox_override("panel",T.flat(T.GOLD_WASH,T.GOLD,1,8,12))
	list.add_child(frame)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);frame.add_child(row)
	var picture:=TextureRect.new();picture.custom_minimum_size=Vector2(128,104);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;picture.texture=Card.texture_for(entry);row.add_child(picture)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",4);row.add_child(copy)
	copy.add_child(T.make_label("%s · %s" % [String(voice.get("moment","")),Chronicle.date_label(int(entry.get("day",0))).to_upper()],10,T.GOLD,0.08))
	copy.add_child(_serif(String(entry.get("title","")),20,T.INK))
	if String(entry.get("text",""))!="":
		var text:=T.make_label(String(entry.text),13,T.BODY);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;copy.add_child(text)


func _notice(entry:Dictionary)->void:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);list.add_child(row)
	var kind:=String(entry.get("kind","story"))
	var mark:=TextureRect.new();mark.custom_minimum_size=Vector2(40,40);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;mark.texture=Icons.moment_texture(kind,Card.ACCENTS.get(kind,Color("e1c27a")),56)
	row.add_child(mark)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",2);row.add_child(copy)
	var head:=HBoxContainer.new();copy.add_child(head)
	var title:=_serif(String(entry.get("title","")),15,T.INK);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(title)
	head.add_child(T.make_label(Chronicle.date_label(int(entry.get("day",0))).get_slice(" · ",1),10,T.MUTED))
	if String(entry.get("text",""))!="":
		var text:=T.make_label(String(entry.text),12,T.TEXT_SOFT);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;copy.add_child(text)


func _whisper(entry:Dictionary)->void:
	var text:=T.make_label("%s — %s" % [String(entry.get("title","")),String(entry.get("text",""))],11,T.MUTED)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	list.add_child(text)
