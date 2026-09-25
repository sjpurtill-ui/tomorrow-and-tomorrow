extends CanvasLayer
## A moment from the Chronicle, shown as a short illustrated card with a sound
## sting. It never pauses the world and never takes input focus; it fades on
## its own, waits while the pointer rests on it, and queues behind the last.
##
## ChronicleCard.flush(terrain, hud) presents every waiting moment
## (Chronicle.pending_cards). The card layer also drains the queue itself, so
## moments recorded outside the daily loop (the Court) appear too.
##
## This is the game's one card queue: discoveries, returned parties and every
## other moment arrive here, in one place. A card never covers an open dock
## sheet: it stands beside the sheet when there is room, and otherwise waits
## (its time does not run) until the sheet closes.

const Chronicle:=preload("res://scripts/chronicle.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Art:=preload("res://scripts/hud/research_visuals.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI_FONT:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
const HOLD_SECONDS:=9.0
const FADE_SECONDS:=0.45
const CARD_WIDTH:=430.0
const TOP:=70.0
const ACCENTS:={"discovery":Color("9db9d7"),"birth":Color("e0b88a"),"death":Color("b9ada0"),"contact":Color("d8a56a"),"settlement":Color("c7b27a"),"founding":Color("f0b25a"),"ceremony":Color("e8c35a"),"milestone":Color("f0c96a"),"war":Color("d0735f"),"omen":Color("a9b7e0"),"court":Color("e1b765")}

var terrain:Node
var hud:Node
var queue:Array[Dictionary]=[]
var current:Dictionary={}
var panel:PanelContainer
var picture:TextureRect
var eyebrow:Label
var title_label:Label
var caption:Label
var action_button:Button
var hold:=0.0
var fade:=0.0
var showing:=false
var player:AudioStreamPlayer
## True while an open dock sheet leaves no room: the card is held back.
var held:=false
static var _stings:Dictionary={}


static func flush(terrain_node:Node,hud_node:Node)->CanvasLayer:
	if Chronicle.pending_cards.is_empty() or not is_instance_valid(hud_node):return null
	var card:=ensure(terrain_node,hud_node)
	card.drain()
	return card


static func ensure(terrain_node:Node,hud_node:Node)->CanvasLayer:
	var existing:Variant=hud_node.get_meta("chronicle_card") if hud_node.has_meta("chronicle_card") else null
	if is_instance_valid(existing):return existing
	var card:=new()
	card.terrain=terrain_node;card.hud=hud_node
	hud_node.set_meta("chronicle_card",card);hud_node.add_child(card)
	return card


func _ready()->void:
	layer=72
	panel=PanelContainer.new();panel.name="ChronicleMoment";panel.mouse_filter=Control.MOUSE_FILTER_PASS
	# Near-black surfaces follow the light/dark HUD palette (HudTokens.flat).
	panel.add_theme_stylebox_override("panel",T.flat(Color("0d1a1ef6"),T.GOLD,2,9,12))
	add_child(panel)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);panel.add_child(row)
	picture=TextureRect.new();picture.custom_minimum_size=Vector2(112,112);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(picture)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",4);row.add_child(copy)
	eyebrow=_label(copy,"",11,T.GOLD)
	title_label=_label(copy,"",21,T.INK,true)
	var serif:=SystemFont.new();serif.font_names=PackedStringArray(["Georgia","Noto Serif","serif"])
	title_label.add_theme_font_override("font",serif)
	caption=_label(copy,"",13,T.BODY,true);caption.max_lines_visible=3;caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",6);copy.add_child(actions)
	action_button=_button(actions,"",_act,true);action_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var close_button:=_button(actions,"×",dismiss);close_button.custom_minimum_size.x=32;close_button.tooltip_text="Set this aside · it stays in the Chronicle"
	player=AudioStreamPlayer.new();player.volume_db=-9.0
	if AudioServer.get_bus_index("Music")>=0:player.bus="Music"
	add_child(player)
	panel.modulate.a=0.0;panel.visible=false
	get_viewport().size_changed.connect(layout)
	layout()


func _label(parent:Node,value:String,font_size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new();label.text=value;label.add_theme_font_override("font",UI_FONT)
	label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label);return label


func _button(parent:Node,value:String,callback:Callable,primary:=false)->Button:
	var button:=Button.new();button.text=value;button.clip_text=true;button.custom_minimum_size.y=28;button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_override("font",UI_FONT);button.add_theme_font_size_override("font_size",12)
	button.add_theme_stylebox_override("normal",T.action_button_style(primary));button.add_theme_stylebox_override("hover",T.action_button_style(true,true))
	button.pressed.connect(callback);parent.add_child(button);return button


func layout()->void:
	if not is_instance_valid(panel):return
	var extent:=get_viewport().get_visible_rect().size
	var width:=minf(CARD_WIDTH,extent.x-32.0)
	panel.custom_minimum_size.x=width;panel.size.x=width
	panel.size.y=panel.get_combined_minimum_size().y
	# Top right, below the time and status bar, clear of the rail.
	panel.position=Vector2(roundf(maxf(16.0,extent.x-width-16.0)),TOP)
	held=false
	var sheet:=sheet_rect()
	if sheet.has_area() and Rect2(panel.position,panel.size).intersects(sheet):
		# Beside the open sheet when it fits; otherwise wait for it to close.
		var beside:=sheet.end.x+12.0
		if beside+width<=extent.x-8.0:panel.position.x=roundf(beside)
		else:held=true


## The open dock sheets (the section dock and its detail), in screen space.
func sheet_rect()->Rect2:
	var covered:=Rect2()
	if not is_instance_valid(hud):return covered
	for sheet_name in ["dock","detail_dock"]:
		var sheet:Variant=hud.get(sheet_name) if sheet_name in hud else null
		if sheet is Control and (sheet as Control).is_visible_in_tree():
			var rect:=(sheet as Control).get_global_rect()
			covered=rect if not covered.has_area() else covered.merge(rect)
	return covered


func drain()->void:
	while not Chronicle.pending_cards.is_empty():
		queue.append(Chronicle.pending_cards.pop_front())
	if queue.size()>4:queue=queue.slice(queue.size()-4)
	if not showing:_next()


func _process(delta:float)->void:
	if not Chronicle.pending_cards.is_empty():drain()
	if not showing:return
	layout()
	if held:
		# A sheet is open over the card's place: keep the card, stop its clock.
		panel.visible=false
		return
	panel.visible=true
	var hovered:=panel.get_global_rect().has_point(panel.get_global_mouse_position())
	if fade>=0.0:
		panel.modulate.a=minf(1.0,panel.modulate.a+delta/FADE_SECONDS)
		if not hovered:hold-=delta
		if hold<=0.0:fade=-1.0
	else:
		panel.modulate.a=maxf(0.0,panel.modulate.a-delta/FADE_SECONDS)
		if panel.modulate.a<=0.0:_next()


func _next()->void:
	if queue.is_empty():
		showing=false;current={};panel.visible=false;return
	current=queue.pop_front()
	_render(current)
	showing=true;hold=HOLD_SECONDS;fade=1.0
	panel.modulate.a=0.0;panel.visible=true
	call_deferred("layout")
	_sting()


func _render(entry:Dictionary)->void:
	var voice:=Chronicle.voice()
	var kind:=String(entry.get("kind","story"))
	var field:=""
	var art:Dictionary=entry.get("art",{})
	if bool(entry.get("first",false)) and kind=="discovery":
		field=" · FIRST IN %s" % String(Chronicle.DOMAIN_NAMES.get(String(art.get("domain","")),"A NEW FIELD")).to_upper()
	eyebrow.text="%s · %s%s" % [String(voice.moment),Chronicle.date_label(int(entry.get("day",0))).to_upper(),field]
	title_label.text=String(entry.get("title",""))
	caption.text=String(entry.get("text",""))
	caption.visible=caption.text!=""
	picture.texture=texture_for(entry)
	var action:Dictionary=entry.get("action",{})
	action_button.text={"ceremony":"Attend the dedication","court":"Go to the court","scout_report":"Hear the scouts' tale","section":"See what we learned" if kind=="discovery" else "Look closer"}.get(String(action.get("kind","")),"Open %s" % String(voice.feed))


static func texture_for(entry:Dictionary)->Texture2D:
	var art:Dictionary=entry.get("art",{})
	var kind:=String(entry.get("kind","story"))
	if String(art.get("discovery_id",""))!="":
		var painted:=Art.for_discovery({"id":String(art.discovery_id)})
		if painted:return painted
		var field:=Art.art(String(art.get("domain","")))
		if field:return field
	elif String(art.get("domain",""))!="":
		var field_art:=Art.art(String(art.domain))
		if field_art:return field_art
	return Icons.moment_texture(kind,ACCENTS.get(kind,Color("e1c27a")))


func _act()->void:
	var action:Dictionary=current.get("action",{})
	match String(action.get("kind","")):
		"ceremony":
			var director:Node=get_tree().get_first_node_in_group("court_director")
			if director and director.has_method("open_ceremony"):director.call("open_ceremony",String(action.get("work_id","")))
		"court":
			preload("res://scripts/audience_director.gd").open_court_for(action.get("focus",{}))
		"scout_report":
			open_scout_report(int(action.get("mission_id",0)))
		"section":
			if is_instance_valid(hud) and hud.has_signal("section_requested"):hud.emit_signal("section_requested",String(action.get("section","chronicle")),int(action.get("sub",0)))
		_:
			if is_instance_valid(hud) and hud.has_signal("section_requested"):hud.emit_signal("section_requested","chronicle",0)
	dismiss()


## Opens a returned party's illustrated report (the Chronicle card's action).
func open_scout_report(mission_id:int)->bool:
	if not is_instance_valid(hud) or not hud.has_method("open_detail"):return false
	for report in CivilizationSystem.scout_reports:
		if report is Dictionary and int((report as Dictionary).get("mission_id",-1))==mission_id:
			hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,report,preload("res://scripts/hud/content/dock_detail_scout_archive.gd").new(terrain,hud)))
			return true
	if hud.has_signal("section_requested"):hud.emit_signal("section_requested","world",0)
	return false


func dismiss()->void:
	if showing:fade=-1.0;hold=0.0


func _sting()->void:
	if not is_instance_valid(player) or DisplayServer.get_name()=="headless":return
	player.stream=sting(String(Chronicle.voice().get("era","tally")))
	player.play()


## A short procedural sting: a hollow drum and two soft bone-flute notes in the
## tally-mark age; a struck bell once the people write. No audio file needed.
static func sting(era:String)->AudioStreamWAV:
	if _stings.has(era):return _stings[era]
	var rate:=22050
	var seconds:=1.6
	var count:=int(rate*seconds)
	var data:=PackedByteArray();data.resize(count*2)
	var noise:=RandomNumberGenerator.new();noise.seed=7
	for i in count:
		var t:=float(i)/float(rate)
		var v:=0.0
		if era=="annals":
			for partial:Vector3 in [Vector3(392.0,1.0,1.4),Vector3(392.0*2.76,0.42,2.6),Vector3(392.0*5.40,0.20,4.2),Vector3(196.0,0.35,1.0)]:
				v+=sin(TAU*partial.x*t)*partial.y*exp(-t*partial.z)
			v*=minf(1.0,t*400.0)*0.42
		else:
			var drum:=sin(TAU*(78.0+40.0*exp(-t*18.0))*t)*exp(-t*7.0)*0.8+noise.randf_range(-1.0,1.0)*exp(-t*60.0)*0.18
			var flute:=0.0
			for note:Vector3 in [Vector3(0.28,587.3,0.55),Vector3(0.72,784.0,0.8)]:
				var local:=t-note.x
				if local>0.0:
					var envelope:=minf(1.0,local*14.0)*exp(-local*(1.0/maxf(0.1,note.z))*2.2)
					flute+=(sin(TAU*note.y*local+sin(TAU*5.0*local)*0.6)+0.18*sin(TAU*note.y*2.0*local))*envelope*0.30
			v=drum*0.55+flute
		var sample:=clampi(int(clampf(v,-1.0,1.0)*28000.0),-32768,32767)
		data.encode_s16(i*2,sample)
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.stereo=false;stream.data=data
	_stings[era]=stream
	return stream
