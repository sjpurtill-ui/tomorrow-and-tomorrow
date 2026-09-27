extends RefCounted
## Paper-and-ink building blocks for the outward and war briefings (city
## report, siege, recovery, occupation, naval and air, figures, direction).
## Everything is drawn through HudTokens: opaque paper, ink text, 12 px floor,
## sentence case, words instead of glyphs.
##
## It also answers "who do I talk to about this?" Every such conversation
## happens in the court (one-court-screen); these screens only open it.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Director:=preload("res://scripts/audience_director.gd")

## The whole-screen sheet: opaque paper with a rule and even padding.
static func sheet_style(pad:float=20.0)->StyleBoxFlat:
	var style:=T.paper_panel_style(false,T.RADIUS_CARD,pad)
	style.shadow_color=Color(0,0,0,0.18 if T.is_light() else 0.45)
	style.shadow_size=18
	style.shadow_offset=Vector2(0,6)
	return style

static func card_style(accent:Color=Color(0,0,0,0),pad:float=12.0)->StyleBoxFlat:
	var style:=T.paper_panel_style(true,T.RADIUS_CARD,pad)
	if accent.a>0.0:
		style.border_color=accent
		style.border_width_left=3
	return style

static func label(parent:Node,text:String,role:String="body",color:Color=Color(0,0,0,0),wrap:bool=true)->Label:
	var result:=Label.new()
	result.text=text
	T.text(result,role,color if color.a>0.0 else (T.INK if role in ["title","display","value","voice","voice_small"] else T.INK_MUTED if role=="kicker" else T.BODY))
	if wrap:result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if parent!=null:parent.add_child(result)
	return result

## A 12 px caps kicker: the only all-caps text allowed (ART_DIRECTION).
static func kicker(parent:Node,text:String)->Label:
	return label(parent,text.to_upper(),"kicker",T.INK_MUTED,false)

static func card(parent:Node,accent:Color=Color(0,0,0,0))->VBoxContainer:
	var panel:=PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",card_style(accent))
	parent.add_child(panel)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",4)
	panel.add_child(box)
	return box

static func button(parent:Node,text:String,callback:Callable,primary:bool=false)->Button:
	var result:=Button.new()
	result.text=text
	result.custom_minimum_size.y=38
	result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	# Wrapped text has no minimum width, so in a flowing row it would squeeze
	# to a sliver; there the button keeps its words on one line.
	result.autowrap_mode=TextServer.AUTOWRAP_OFF if parent is FlowContainer else TextServer.AUTOWRAP_WORD_SMART
	T.text(result,"small",T.INK)
	result.add_theme_color_override("font_hover_color",T.INK)
	result.add_theme_color_override("font_pressed_color",T.INK)
	result.add_theme_color_override("font_disabled_color",T.DISABLED)
	result.add_theme_stylebox_override("normal",T.action_button_style(primary))
	result.add_theme_stylebox_override("hover",T.action_button_style(primary,true))
	result.add_theme_stylebox_override("pressed",T.button_pressed_style())
	result.add_theme_stylebox_override("disabled",T.button_disabled_style())
	result.add_theme_stylebox_override("focus",T.gold_outline_style())
	if callback.is_valid():result.pressed.connect(callback)
	if parent!=null:parent.add_child(result)
	return result

static func rule(parent:Node)->void:
	var line:=ColorRect.new()
	line.color=T.RULE
	line.custom_minimum_size.y=1
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

## A full-screen modal root: the scrim behind, one centred sheet in front.
## Returns [root, sheet_box]. Escape and the close button call close_callback.
static func modal(owner:Control,title:String,kicker_text:String,max_size:Vector2,close_callback:Callable)->VBoxContainer:
	owner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	owner.mouse_filter=Control.MOUSE_FILTER_STOP
	owner.theme=T.control_theme()
	var scrim:=ColorRect.new()
	scrim.name="Scrim"
	scrim.color=T.SCRIM
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	owner.add_child(scrim)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	owner.add_child(center)
	var panel:=PanelContainer.new()
	panel.name="Sheet"
	panel.add_theme_stylebox_override("panel",sheet_style())
	var viewport:=owner.get_viewport_rect().size if owner.is_inside_tree() else Vector2(1600,900)
	panel.custom_minimum_size=Vector2(minf(max_size.x,viewport.x-32),minf(max_size.y,viewport.y-32))
	center.add_child(panel)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	panel.add_child(root)
	var head:=HBoxContainer.new()
	head.add_theme_constant_override("separation",12)
	root.add_child(head)
	var titles:=VBoxContainer.new()
	titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation",2)
	head.add_child(titles)
	if kicker_text!="":kicker(titles,kicker_text)
	var heading:=label(titles,title,"title",T.INK)
	heading.name="Title"
	var close:=button(head,"Close",close_callback)
	close.name="Close"
	close.size_flags_horizontal=Control.SIZE_SHRINK_END
	close.custom_minimum_size=Vector2(96,38)
	close.tooltip_text="Close (Esc)"
	rule(root)
	return root

## A scrolling body that fills the rest of a sheet.
static func scroll_body(parent:Node,separation:int=12)->VBoxContainer:
	var scroll:=ScrollContainer.new()
	scroll.name="Body"
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var box:=VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",separation)
	scroll.add_child(box)
	return box

# --- Who to talk to -------------------------------------------------------

## Our war leader: {name, target} where target is what the court summons.
## Empty when no one leads our fighters yet.
static func war_leader()->Dictionary:
	var found:Dictionary=preload("res://scripts/court_war_orders.gd").war_leader()
	if found.is_empty():return {}
	var target:={}
	if int(found.get("person_id",0))>0:target={"person_id":int(found.person_id)}
	elif String(found.get("figure_id",""))!="":target={"figure_id":String(found.figure_id)}
	else:return {}
	return {"name":String(found.get("name","our war leader")),"target":target}

## The general who leads a given army, else the war leader.
static func general_for(army:Dictionary)->Dictionary:
	var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
	if String(commander.get("figure_id",""))!="":
		return {"name":String(commander.get("name","the general")),"target":{"figure_id":String(commander.figure_id)}}
	return war_leader()

## "their defences are worn" -> "Their defences are worn": only the first letter.
static func first_up(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if text!="" else text

static func first_name(name:String)->String:
	return name.get_slice(" ",0) if name.strip_edges()!="" else name

## Summons someone into the court. Returns false when no court is running.
static func summon(target:Dictionary)->bool:
	var director:=Director.court_node()
	if director==null:return false
	if target.is_empty():
		director.call("open_court",{})
		return true
	if director.has_method("summon"):
		director.call("summon",target)
		return true
	return Director.open_court_for(target)

## Opens the court on a foreign ruler (their people's id).
static func talk_to_ruler(civ_id:String)->bool:
	return Director.open_court_for({"civ_id":civ_id} if civ_id!="" else {})

static func ruler_name(civ_id:String)->String:
	if civ_id=="" or Engine.get_main_loop()==null:return ""
	var leader:Dictionary=ForeignDiplomacy.leader(civ_id)
	return String(leader.get("name",""))

## "Talk to Oren" for the war leader, or a plain fallback when there is none.
static func talk_label(person:Dictionary,fallback:String="Go to the court")->String:
	var name:=String(person.get("name",""))
	return "Talk to %s" % first_name(name) if name!="" else fallback
