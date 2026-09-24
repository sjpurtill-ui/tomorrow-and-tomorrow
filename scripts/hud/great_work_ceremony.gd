extends Control
## The Dedication: a full-screen ceremony when a great work stands. The work is
## revealed, its lore read, foreign envoys attend with their flags and real
## gifts (from GreatWorks.pending_ceremonies), the master builder, a court
## official and each envoy speak (AudienceVoice.ceremony_speeches — live voice
## when configured, offline banks otherwise), the ruler names the work and
## GreatWorks.dedicate records it: chronicle line, gifts received, allure.
## Pauses the simulation while open. World state changes only via dedicate().

signal closed(work_id:String)

const Bridge:=preload("res://scripts/great_works_audience.gd")
const Plate:=preload("res://scripts/hud/great_work_plate.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const DISPLAY_FONT:=preload("res://assets/fonts/cinzel/Cinzel.ttf")
const OUTCOME_WORDS:={"triumph":"A TRIUMPH BEYOND THE DRAWINGS","success":"IT STANDS","flawed":"FLAWED, BUT STANDING"}
const LINE_GAP:=1.35

var terrain:Node
var voice:Node
var ceremony:Dictionary={}
var work_id:=""
var city_id:=""
var pause=preload("res://scripts/hud/simulation_pause.gd").new()
var record:Dictionary={}
var voice_ctx:Dictionary={}
var result:Dictionary={}
var allure_before:=0.0
var pending_lines:Array=[]
var lines_shown:=0
var reveal_clock:=0.0
var clock:=0.0
var follow:=0.0
var backdrop:Control
var stage:Control
var title_label:Label
var plate:Control
var assembly:VBoxContainer
var speech_scroll:ScrollContainer
var speeches:VBoxContainer
var name_input:LineEdit
var dedicate_button:Button
var naming_box:VBoxContainer
var result_box:VBoxContainer
var suggestion_row:HFlowContainer
var envoy_cards:Array[Control]=[]
var intro_tweens:Array[Tween]=[]
var _serif:SystemFont
var _italic:SystemFont

## Opens the ceremony on its own canvas layer; returns the ceremony control.
static func open(host:Node,terrain_node:Node,voice_node:Node,entry:Dictionary)->Control:
	var parent:Node=host if is_instance_valid(host) else (Engine.get_main_loop() as SceneTree).current_scene
	var canvas:=CanvasLayer.new();canvas.layer=88;canvas.name="GreatWorkCeremonyLayer";parent.add_child(canvas)
	var view:Control=load("res://scripts/hud/great_work_ceremony.gd").new()
	view.terrain=terrain_node;view.voice=voice_node;view.ceremony=entry.duplicate(true)
	canvas.add_child(view)
	return view

func _ready()->void:
	name="GreatWorkCeremony"
	theme=Tokens.control_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	pause.acquire(terrain if is_instance_valid(terrain) else get_tree().current_scene)
	_serif=SystemFont.new();_serif.font_names=PackedStringArray(["Georgia","Noto Serif","Times New Roman","serif"])
	_italic=SystemFont.new();_italic.font_names=_serif.font_names;_italic.font_italic=true
	work_id=String(ceremony.get("work_id",""))
	city_id=String(ceremony.get("city_id",""))
	record=Bridge.api_dict("site",[city_id,work_id])
	allure_before=float(Bridge.api_dict("allure_contribution",["player"]).get("value",0.0))
	backdrop=Backdrop.new();backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	backdrop.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed:skip_reveal())
	_build()
	get_viewport().size_changed.connect(_fit)
	_fit()
	_start_voice()
	_theatre()

func _exit_tree()->void:
	pause.release()

func _fit()->void:
	if not is_instance_valid(stage):return
	var view:=get_viewport().get_visible_rect().size
	stage.size=Vector2(minf(1500,view.x-40),minf(900,view.y-30))
	stage.position=((view-stage.size)*.5).round()

# ---------------------------------------------------------------- building

func _outcome()->String:
	var outcome:=String(record.get("outcome",ceremony.get("outcome","success")))
	return outcome if OUTCOME_WORDS.has(outcome) else "success"

func _concept()->Dictionary:
	return record.get("concept",{}) if record.get("concept") is Dictionary else {}

func _title()->String:
	var shown:=String(record.get("display_name",ceremony.get("title","")))
	return shown if not shown.is_empty() else String(ceremony.get("title","The Great Work"))

func _purpose_line()->String:
	var concept:=_concept()
	var id:=work_id.split(":")
	var designed:=id.size()==7 and id[0]=="wonder"
	var shape:=id[1] if designed else (Bridge.concept_form(concept) if concept.has("shape") else String(record.get("form","")))
	var purpose:=Bridge.purpose_label(id[2]) if designed else Bridge.concept_purpose(concept)
	var ambition:=id[3] if designed else String(concept.get("ambition",""))
	var words:="A %s" % (shape.replace("_"," ") if not shape.is_empty() else "great work")
	if not purpose.is_empty():words+=" raised to %s" % purpose
	if not ambition.is_empty():words+=" · %s ambition" % ambition.capitalize()
	return words

func _lore()->String:
	var concept:=_concept()
	var lore:=Bridge.concept_lore(concept) if not concept.is_empty() else ""
	if lore.is_empty():lore=String(record.get("lore",""))
	if lore.is_empty():
		var catalog:Variant=load("res://scripts/undertaking_catalog.gd").call("get_definition",work_id)
		if catalog is Dictionary:lore=String((catalog as Dictionary).get("lore",""))
	return lore

func _build()->void:
	stage=PanelContainer.new();stage.name="CeremonyStage"
	var style:=Tokens.flat(Color(0,0,0,0),Color(0,0,0,0),0,0,0)
	stage.add_theme_stylebox_override("panel",style);add_child(stage)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);stage.add_child(column)
	var cream:=Color("f6ecd6");var gold:=Color("e8c46a")
	var eyebrow:=_label("THE DEDICATION OF A GREAT WORK · %s" % String(ceremony.get("city_name",record.get("city_name",""))).to_upper(),13,Color("d9c79c"),.18)
	eyebrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(eyebrow)
	title_label=_label(_title(),50,cream);title_label.name="CeremonyTitle";title_label.add_theme_font_override("font",DISPLAY_FONT)
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(title_label)
	var sub:=HBoxContainer.new();sub.alignment=BoxContainer.ALIGNMENT_CENTER;sub.add_theme_constant_override("separation",14);column.add_child(sub)
	var purpose:=_label(_purpose_line(),17,Color("e2d3b4"));purpose.add_theme_font_override("font",_italic);sub.add_child(purpose)
	var badge:=PanelContainer.new();var badge_style:=Tokens.flat(Color(gold,.16),gold,1,12,0);badge_style.content_margin_left=12;badge_style.content_margin_right=12;badge_style.content_margin_top=2;badge_style.content_margin_bottom=3
	badge.add_theme_stylebox_override("panel",badge_style);badge.name="OutcomeBadge";sub.add_child(badge)
	badge.add_child(_label(String(OUTCOME_WORDS[_outcome()]),12,gold,.14))
	column.add_child(Flourish.new())
	var middle:=HBoxContainer.new();middle.size_flags_vertical=Control.SIZE_EXPAND_FILL;middle.add_theme_constant_override("separation",26);column.add_child(middle)
	# The work itself and its lore.
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=1.15;left.add_theme_constant_override("separation",10);middle.add_child(left)
	var frame:=PanelContainer.new();frame.name="PlateFrame";frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var frame_style:=Tokens.flat(Color("f3e7cc"),gold,2,6,6);frame_style.shadow_color=Color(1,.8,.35,.35);frame_style.shadow_size=26
	frame.add_theme_stylebox_override("panel",frame_style);left.add_child(frame)
	var work_view:=record.duplicate(true)
	work_view["work_id"]=work_id
	work_view["dedicated_day"]=0
	if not _concept().is_empty():work_view.merge(_concept(),false)
	plate=Plate.make(work_view,340);plate.set("night",true);plate.name="WorkPlate";plate.size_flags_vertical=Control.SIZE_EXPAND_FILL;frame.add_child(plate)
	var lore:=_label(_lore(),17,Color("eadfc6"));lore.name="Lore";lore.add_theme_font_override("font",_italic);lore.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;lore.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(lore)
	var architect:Dictionary=record.get("architect",{}) if record.get("architect") is Dictionary else {}
	if not String(architect.get("name","")).is_empty():
		var builder:=_label("Raised by the master builder %s%s" % [String(architect.name),(" · %s in style" % String(architect.get("style",""))) if not String(architect.get("style","")).is_empty() else ""],13,Color("cdbb92"),.04)
		builder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;left.add_child(builder)
	# The assembly: envoys with flags and gifts, then the speeches.
	var right:=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",10);middle.add_child(right)
	right.add_child(_label("THE ASSEMBLY",12,Color("d9c79c"),.18))
	assembly=VBoxContainer.new();assembly.name="Assembly";assembly.add_theme_constant_override("separation",6);right.add_child(assembly)
	var attendees:Array=ceremony.get("attendees",[])
	if attendees.is_empty():
		var alone:=_label("No foreign envoys came. Your own people crowd the square instead, and that is its own kind of praise.",14,Color("d8cbb0"));alone.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;alone.add_theme_font_override("font",_italic);assembly.add_child(alone)
	for attendee in attendees:
		if attendee is Dictionary:
			var card:=_envoy_card(attendee)
			assembly.add_child(card);envoy_cards.append(card)
	right.add_child(_label("SPOKEN BEFORE THE CROWD",12,Color("d9c79c"),.18))
	speech_scroll=ScrollContainer.new();speech_scroll.name="Speeches";speech_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;speech_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(speech_scroll)
	speeches=VBoxContainer.new();speeches.size_flags_horizontal=Control.SIZE_EXPAND_FILL;speeches.add_theme_constant_override("separation",9);speech_scroll.add_child(speeches)
	# Naming, then the record.
	naming_box=VBoxContainer.new();naming_box.name="Naming";naming_box.add_theme_constant_override("separation",8);column.add_child(naming_box)
	var name_row:=HBoxContainer.new();name_row.add_theme_constant_override("separation",12);naming_box.add_child(name_row)
	var ask:=_label("NAME IT FOR THE AGES",14,gold,.16);ask.size_flags_vertical=Control.SIZE_SHRINK_CENTER;name_row.add_child(ask)
	name_input=LineEdit.new();name_input.name="NameInput";name_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_input.max_length=60;name_input.custom_minimum_size.y=46
	name_input.add_theme_font_size_override("font_size",20);name_input.add_theme_font_override("font",_serif)
	var suggestions:Array=ceremony.get("name_suggestions",[])
	name_input.placeholder_text=String(suggestions[0]) if not suggestions.is_empty() else _title()
	name_input.text_submitted.connect(func(_t:String)->void:dedicate_with(name_input.text))
	name_row.add_child(name_input)
	dedicate_button=Button.new();dedicate_button.name="Dedicate";dedicate_button.text="DEDICATE";dedicate_button.custom_minimum_size=Vector2(190,46)
	dedicate_button.add_theme_font_size_override("font_size",18);dedicate_button.add_theme_font_override("font",DISPLAY_FONT)
	var gold_style:=Tokens.flat(Color("7a5412"),gold,2,6,0);var gold_hover:=Tokens.flat(Color("946818"),Color("ffe29a"),2,6,0)
	dedicate_button.add_theme_stylebox_override("normal",gold_style);dedicate_button.add_theme_stylebox_override("hover",gold_hover);dedicate_button.add_theme_stylebox_override("pressed",gold_hover)
	dedicate_button.add_theme_color_override("font_color",Color("fff3d2"));dedicate_button.add_theme_color_override("font_hover_color",Color("ffffff"))
	dedicate_button.pressed.connect(func()->void:dedicate_with(name_input.text))
	name_row.add_child(dedicate_button)
	suggestion_row=HFlowContainer.new();suggestion_row.add_theme_constant_override("h_separation",8);naming_box.add_child(suggestion_row)
	suggestion_row.add_child(_label("The court suggests:",13,Color("cdbb92")))
	for suggestion in suggestions:
		var chip:=Button.new();chip.text=String(suggestion);chip.focus_mode=Control.FOCUS_NONE
		chip.add_theme_stylebox_override("normal",Tokens.flat(Color(1,1,1,.08),Color(gold,.6),1,14,0));chip.add_theme_stylebox_override("hover",Tokens.flat(Color(1,1,1,.16),gold,1,14,0))
		chip.add_theme_color_override("font_color",Color("f3e6c7"));chip.add_theme_font_override("font",_italic);chip.add_theme_font_size_override("font_size",15)
		var chosen:=String(suggestion)
		chip.pressed.connect(func()->void:name_input.text=chosen)
		suggestion_row.add_child(chip)
	var later:=Button.new();later.name="Later";later.text="Let the council name it later";later.flat=true;later.add_theme_color_override("font_color",Color("bca982"));later.add_theme_font_size_override("font_size",13)
	later.tooltip_text="Close the ceremony. If you never name it, the council dedicates it under the first suggestion."
	later.pressed.connect(close);suggestion_row.add_child(later)
	result_box=VBoxContainer.new();result_box.name="Result";result_box.visible=false;result_box.add_theme_constant_override("separation",8);column.add_child(result_box)

func _envoy_card(attendee:Dictionary)->Control:
	var card:=PanelContainer.new();card.name="Envoy_"+String(attendee.get("civ_id",""))
	var colour:=Identity.banner_color(Identity.foreign(String(attendee.get("civ_id",""))).texture)
	var style:=Tokens.flat(Color(0,0,0,.28),Color(colour,.8),1,6,0);style.border_width_left=5;style.content_margin_left=10;style.content_margin_right=12;style.content_margin_top=6;style.content_margin_bottom=6
	card.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
	var flag:=TextureRect.new();flag.texture=Identity.foreign(String(attendee.get("civ_id",""))).texture;flag.custom_minimum_size=Vector2(42,48)
	flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(flag)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);row.add_child(words)
	var who:=_label(String(attendee.get("name","A foreign people")),17,Color("f6ecd6"));who.add_theme_font_override("font",_serif);words.add_child(who)
	var gift:Dictionary=attendee.get("gift",{}) if attendee.get("gift") is Dictionary else {}
	if gift.is_empty() or float(gift.get("amount",0))<=0:
		var plain:=_label("come in admiration, empty-handed",13,Color("cdbb92"));plain.add_theme_font_override("font",_italic);words.add_child(plain)
	else:
		words.add_child(_label("bearing a gift for the work",13,Color("cdbb92")))
		var chip:=PanelContainer.new();chip.name="Gift";chip.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		chip.add_theme_stylebox_override("panel",Tokens.flat(Color("f6ecd6"),Color("e8c46a"),1,6,4))
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",6);chip.add_child(line)
		var resource:=String(gift.get("resource",""))
		var icon:=TextureRect.new();icon.texture=Icons.domain_texture("nutrition",Color("5f7f35")) if resource=="Food" else Icons.texture_for(resource)
		icon.custom_minimum_size=Vector2(28,28);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(icon)
		var amount:=_label("%d %s" % [roundi(float(gift.get("amount",0))),resource],16,Color("2a2217"));amount.name="GiftAmount";line.add_child(amount)
		row.add_child(chip)
	return card

func _label(text:String,font_size:int,colour:Color,spacing:float=0.0)->Label:
	var node:=Tokens.make_label(text,font_size,colour,spacing)
	return node

# ---------------------------------------------------------------- theatre

func _theatre()->void:
	modulate.a=0.0
	var intro:=create_tween();intro_tweens.append(intro)
	intro.tween_property(self,"modulate:a",1.0,.6)
	title_label.pivot_offset=Vector2(title_label.size.x*.5,title_label.size.y*.5)
	title_label.scale=Vector2(.88,.88);title_label.modulate.a=0.0
	var title_tween:=create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);intro_tweens.append(title_tween)
	title_tween.tween_interval(.35)
	title_tween.tween_property(title_label,"modulate:a",1.0,.8)
	title_tween.parallel().tween_property(title_label,"scale",Vector2.ONE,1.0)
	plate.modulate.a=0.0
	var plate_tween:=create_tween();intro_tweens.append(plate_tween);plate_tween.tween_interval(.8);plate_tween.tween_property(plate,"modulate:a",1.0,1.2)
	var delay:=1.4
	for card in envoy_cards:
		card.modulate.a=0.0
		var card_tween:=create_tween();intro_tweens.append(card_tween);card_tween.tween_interval(delay);card_tween.tween_property(card,"modulate:a",1.0,.5)
		delay+=.35
	reveal_clock=-delay

func _start_voice()->void:
	var official:Dictionary=GovernmentPeopleSystem.officeholder("Steward")
	if official.is_empty():
		for key in ["Envoy","Scholar","Quartermaster"]:
			official=GovernmentPeopleSystem.officeholder(String(key))
			if not official.is_empty():break
	voice_ctx={"key":work_id,"title":_title(),"lore":_lore(),"city_name":String(ceremony.get("city_name",record.get("city_name",""))),"outcome":_outcome(),"purpose":_purpose_line(),
		"architect":(record.get("architect",{}) as Dictionary).duplicate() if record.get("architect") is Dictionary else {},"official":official,"attendees":(ceremony.get("attendees",[]) as Array).duplicate(true)}
	if is_instance_valid(voice) and voice.has_method("ceremony_speeches"):
		if not voice.is_connected("ceremony_ready",_on_voice):voice.connect("ceremony_ready",_on_voice)
		voice.call("ceremony_speeches",voice_ctx)

func _on_voice(key:String,lines:Array)->void:
	if key!=work_id and key!=work_id+":named":return
	var said:={}
	for line in pending_lines:said[String((line as Dictionary).get("text","")).strip_edges().to_lower()]=true
	for line in lines:
		if not line is Dictionary:continue
		var text:=String((line as Dictionary).get("text","")).strip_edges().to_lower()
		if said.has(text):continue
		said[text]=true
		pending_lines.append(line)

func _process(delta:float)->void:
	clock+=delta
	_fit()
	reveal_clock+=delta
	if follow>0.0 and is_instance_valid(speech_scroll):
		follow-=delta
		speech_scroll.scroll_vertical=int(speech_scroll.get_v_scroll_bar().max_value)
	if reveal_clock>=LINE_GAP and lines_shown<pending_lines.size():
		reveal_clock=0.0
		_add_speech(pending_lines[lines_shown],true)
		lines_shown+=1

func skip_reveal()->void:
	for tween in intro_tweens:
		if tween and tween.is_valid():tween.kill()
	intro_tweens.clear()
	while lines_shown<pending_lines.size():
		_add_speech(pending_lines[lines_shown],false)
		lines_shown+=1
	modulate.a=1.0
	if is_instance_valid(title_label):title_label.modulate.a=1.0;title_label.scale=Vector2.ONE
	if is_instance_valid(plate):plate.modulate.a=1.0
	for card in envoy_cards:card.modulate.a=1.0

func _add_speech(line:Dictionary,animate:bool)->void:
	var role:=String(line.get("role","narrator"))
	var text:=String(line.get("text",""))
	var row:Control
	if role=="narrator":
		var narration:=_label(text,16,Color("e8d9b8"));narration.add_theme_font_override("font",_italic);narration.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		narration.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;row=narration
	else:
		var box:=HBoxContainer.new();box.add_theme_constant_override("separation",10);row=box
		var face:=PanelContainer.new();face.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;face.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),Color("e8c46a"),1,5,2));box.add_child(face)
		if role=="envoy":
			var flag:=TextureRect.new();flag.texture=Identity.foreign(String(line.get("civ_id",""))).texture;flag.custom_minimum_size=Vector2(40,46)
			flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;face.add_child(flag)
		else:
			var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(line.get("person_id",0))) if int(line.get("person_id",0))>0 else {"name":String(line.get("speaker","")),"person_id":0}
			face.add_child(Portrait.picture(person,40,46))
		var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",1);box.add_child(words)
		var who:=_label("%s  ·  %s" % [String(line.get("speaker","")),String(line.get("title",""))],13,Color("e8c46a"),.04);words.add_child(who)
		var said:=_label(text,17,Color("f6ecd6"));said.add_theme_font_override("font",_serif);said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.name="SpeechText";words.add_child(said)
	speeches.add_child(row)
	if animate:
		row.modulate.a=0.0
		var tween:=create_tween();tween.tween_property(row,"modulate:a",1.0,.45)
	follow=.5

# ---------------------------------------------------------------- naming

## Names and dedicates the work through GreatWorks.dedicate. Empty text takes
## the first suggestion. Returns the engine result.
func dedicate_with(text:String)->Dictionary:
	if not result.is_empty():return result
	var chosen:=text.strip_edges()
	var suggestions:Array=ceremony.get("name_suggestions",[])
	if chosen.is_empty():chosen=String(suggestions[0]) if not suggestions.is_empty() else _title()
	var answer:=Bridge.api_dict("dedicate",[city_id,work_id,chosen])
	if answer.is_empty() or answer.has("error"):
		var warn:=_label(String(answer.get("error","The work cannot be dedicated now.")),14,Color("f0a090"));suggestion_row.add_child(warn)
		return answer
	result=answer
	skip_reveal()
	_show_result(chosen)
	if is_instance_valid(voice) and voice.has_method("ceremony_named"):voice.call("ceremony_named",voice_ctx,chosen)
	return result

func _show_result(chosen:String)->void:
	naming_box.visible=false
	title_label.text=chosen
	var pop:=create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_label.scale=Vector2(1.12,1.12);pop.tween_property(title_label,"scale",Vector2.ONE,.7)
	if plate.has_method("configure"):
		plate.set("glow",1.0);plate.queue_redraw()
	var after:=float(Bridge.api_dict("allure_contribution",["player"]).get("value",allure_before))
	var dedicated:=Bridge.api_dict("site",[city_id,work_id])
	var spike:=float((dedicated.get("ceremony",{}) as Dictionary).get("allure",after-allure_before)) if dedicated.get("ceremony") is Dictionary else after-allure_before
	result_box.visible=true
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",24);result_box.add_child(row)
	var seal:=AllureBurst.new();seal.name="AllureBurst";seal.value=spike;seal.custom_minimum_size=Vector2(150,110);row.add_child(seal)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",4);row.add_child(words)
	words.add_child(_label("SET DOWN IN THE CHRONICLE",12,Color("d9c79c"),.18))
	var chronicle:=_label(String(result.get("message","")),18,Color("f6ecd6"));chronicle.name="ChronicleLine";chronicle.add_theme_font_override("font",_serif);chronicle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(chronicle)
	var gifts:Array=result.get("gifts",[])
	if not gifts.is_empty():
		var received:=_label("Gifts received: "+"; ".join(PackedStringArray(gifts.map(func(g:Variant)->String:return String(g)))),14,Color("cdbb92"));received.name="GiftsReceived";received.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(received)
	words.add_child(_label("Our allure rises: +%.1f while the dedication is still talked about, fading over the years." % spike,14,Color("e8c46a")))
	var close_button:=Button.new();close_button.name="CloseCeremony";close_button.text="Let the feast begin";close_button.custom_minimum_size=Vector2(220,46)
	close_button.add_theme_font_override("font",DISPLAY_FONT);close_button.add_theme_font_size_override("font_size",16)
	close_button.add_theme_stylebox_override("normal",Tokens.flat(Color("7a5412"),Color("e8c46a"),2,6,0));close_button.add_theme_color_override("font_color",Color("fff3d2"))
	close_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER;close_button.pressed.connect(close);row.add_child(close_button)

func close()->void:
	if is_queued_for_deletion():return
	closed.emit(work_id)
	var layer:=get_parent()
	if layer is CanvasLayer:layer.queue_free()
	else:queue_free()

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

# ---------------------------------------------------------------- drawn pieces

class Backdrop extends Control:
	## Night sky over a crowd of torches: radial gold behind the stage.
	var clock:=0.0
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_STOP
	func _process(delta:float)->void:
		clock+=delta;queue_redraw()
	func _draw()->void:
		var r:=get_rect()
		draw_rect(r,Color("0b0d12") if not HudTokens.is_light() else Color("1c160e"))
		var c:=Vector2(r.size.x*.5,r.size.y*.42)
		for i in 14:
			var radius:=r.size.length()*(.62-.04*i)
			draw_circle(c,radius,Color(1,.72,.3,.018+.004*sin(clock*.8+i)))
		for i in 60:
			var x:=fposmod(float(i)*97.3,r.size.x)
			var flicker:=.5+.5*sin(clock*3.0+float(i))
			draw_circle(Vector2(x,r.size.y-6-float(i%5)*4),2.0+flicker,Color(1,.75,.35,.35*flicker))

class Flourish extends Control:
	func _init()->void:custom_minimum_size=Vector2(0,14)
	func _draw()->void:
		var y:=size.y*.5;var mid:=size.x*.5
		draw_line(Vector2(mid-320,y),Vector2(mid-18,y),Color("e8c46a",.6),1.2,true)
		draw_line(Vector2(mid+18,y),Vector2(mid+320,y),Color("e8c46a",.6),1.2,true)
		draw_colored_polygon(PackedVector2Array([Vector2(mid,y-6),Vector2(mid+8,y),Vector2(mid,y+6),Vector2(mid-8,y)]),Color("e8c46a"))

class AllureBurst extends Control:
	## The allure spike, shown as a radiant seal with its number.
	var value:=0.0
	var clock:=0.0
	func _process(delta:float)->void:
		clock+=delta;queue_redraw()
	func _draw()->void:
		var c:=size*.5;var r:=minf(size.x,size.y)*.42
		var grow:=clampf(clock/.8,0,1)
		for i in 16:
			var a:=TAU*float(i)/16.0+clock*.15
			draw_line(c+Vector2(cos(a),sin(a))*r*.7,c+Vector2(cos(a),sin(a))*r*(1.05+.12*sin(clock*2+i))*grow,Color(1,.82,.4,.55),2.0,true)
		draw_circle(c,r*.72*grow,Color("7a5412"))
		draw_arc(c,r*.72*grow,0,TAU,48,Color("ffe29a"),2.0,true)
		var font:=ThemeDB.fallback_font
		var text:="+%.1f" % value
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,-1,20).x
		draw_string(font,c+Vector2(-width*.5,5),text,HORIZONTAL_ALIGNMENT_CENTER,-1,20,Color("fff3d2"))
		var sub:="ALLURE"
		var sub_width:=font.get_string_size(sub,HORIZONTAL_ALIGNMENT_CENTER,-1,11).x
		draw_string(font,c+Vector2(-sub_width*.5,24),sub,HORIZONTAL_ALIGNMENT_CENTER,-1,11,Color("f3dfa8"))
