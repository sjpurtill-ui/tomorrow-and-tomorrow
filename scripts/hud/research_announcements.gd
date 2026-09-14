extends CanvasLayer
## A compact research digest. It never pauses simulation and is deliberately
## bounded so UI scaling cannot turn its clickable text into an offscreen strip.
const DiscoveryNotice=preload("res://scripts/hud/discovery_popup.gd")
const Art=preload("res://scripts/hud/research_visuals.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const UI_FONT:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
const MILESTONES=["seed_selection","public_schools","printing_process","steam_propulsion","powered_flight","reactor_engineering"]
const MODES=["milestones","all","quiet"]
const CARD_MAX_WIDTH:=370.0
const EDGE:=16.0
const LOWER_UI_CLEARANCE:=86.0
var terrain:Node
var hud:Node
var unread:=0
var latest:=""
var latest_event:Dictionary={}
var seen:Dictionary={}
var notice:PanelContainer
var icon:TextureRect
var count_label:Label
var latest_label:Label
var date_label:Label
var open_button:Button

static func important(event:Dictionary,mode:String,first_batch:bool=false)->bool:
	return mode=="all" or (mode=="milestones" and (first_batch or String(event.get("id","")) in MILESTONES))
static func announce(terrain_node:Node,hud_node:Node,events:Array[Dictionary])->CanvasLayer:
	if events.is_empty() or not is_instance_valid(hud_node):return null
	var digest:Variant=hud_node.get_meta("research_digest") if hud_node.has_meta("research_digest") else null
	if not is_instance_valid(digest):
		digest=new();digest.terrain=terrain_node;digest.hud=hud_node;hud_node.set_meta("research_digest",digest);hud_node.add_child(digest)
	digest.receive(events)
	return digest

func _ready()->void:
	layer=70
	notice=PanelContainer.new();notice.add_theme_stylebox_override("panel",T.flat(Color("0b1519f7"),T.TEAL,1,7,11));add_child(notice)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);notice.add_child(row)
	icon=TextureRect.new();icon.custom_minimum_size=Vector2(54,54);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",2);row.add_child(copy)
	var top:=HBoxContainer.new();copy.add_child(top)
	count_label=_label(top,"",11,T.TEAL);count_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	date_label=_label(top,"",10,T.MUTED)
	latest_label=_label(copy,"",13,T.INK,true);latest_label.max_lines_visible=2;latest_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",6);copy.add_child(actions)
	open_button=_button(actions,"Review findings  →",open_archive,true);open_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var dismiss:=_button(actions,"×",clear);dismiss.custom_minimum_size.x=34;dismiss.tooltip_text="Clear research digest"
	get_viewport().size_changed.connect(layout);layout();notice.hide()

func _label(parent:Node,text_value:String,size_value:int,color:Color,wrap:=false)->Label:
	var value:=Label.new();value.text=text_value;value.add_theme_font_override("font",UI_FONT)
	value.add_theme_font_size_override("font_size",size_value);value.add_theme_color_override("font_color",color)
	value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	parent.add_child(value);return value

func _button(parent:Node,text_value:String,callback:Callable,primary:=false)->Button:
	var value:=Button.new();value.text=text_value;value.clip_text=true;value.custom_minimum_size.y=28
	value.add_theme_font_override("font",UI_FONT);value.add_theme_font_size_override("font_size",12)
	value.add_theme_stylebox_override("normal",T.action_button_style(primary));value.add_theme_stylebox_override("hover",T.action_button_style(true,true))
	value.pressed.connect(callback);parent.add_child(value);return value

func layout()->void:
	if not is_instance_valid(notice):return
	var extent:=get_viewport().get_visible_rect().size
	var width:=maxf(250.0,minf(CARD_MAX_WIDTH,extent.x-EDGE*2.0))
	notice.custom_minimum_size.x=width;notice.size.x=width
	var height:=notice.get_combined_minimum_size().y;notice.size.y=height
	notice.position=Vector2(maxf(EDGE,extent.x-width-EDGE),maxf(EDGE,extent.y-height-LOWER_UI_CLEARANCE))

func receive(events:Array[Dictionary])->void:
	var interruptions:Array[Dictionary]=[]
	var first_batch:=GameState.known_discoveries.size()<=events.size()
	for event:Dictionary in events:
		var id:=String(event.get("id",""))
		if id.is_empty() or id not in GameState.known_discoveries or seen.has(id):continue
		seen[id]=true
		if seen.size()>8192:seen.erase(seen.keys()[0])
		if important(event,GameState.research_notification_mode,first_batch):interruptions.append(event)
		else:
			unread+=1;latest=id;latest_event=DiscoverySystem.player_facing_discovery_event(event)
	refresh()
	if not interruptions.is_empty():DiscoveryNotice.announce(terrain,hud,interruptions)

func refresh()->void:
	if unread<=0:notice.hide();return
	count_label.text="RESEARCH · %d NEW FINDING%s" % [unread,"" if unread==1 else "S"]
	latest_label.text=String(latest_event.get("name",latest.replace("_"," ").capitalize()))
	var day:=int(latest_event.get("day",0));date_label.text="Y%d · D%d" % [day/365+1,day%365+1]
	icon.texture=Art.for_discovery(latest_event)
	notice.show();call_deferred("layout")

func clear()->void:
	unread=0;latest_event={};notice.hide()
func open_archive()->void:
	preload("res://scripts/hud/knowledge_atlas.gd").open(terrain,hud,"inquiry")
	var atlas=hud.get_meta("knowledge_atlas").get_child(0)
	atlas.set_view("known");atlas.select(latest)
	clear()
