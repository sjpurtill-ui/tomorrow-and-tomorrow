extends CanvasLayer
## Announce only newly completed player discoveries supplied by the daily loop.
## Existing knowledge stays in the research archive and is not replayed on load.
const Art=preload("res://scripts/hud/research_visuals.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Pause=preload("res://scripts/hud/simulation_pause.gd")
const COSTS=["food_spoilage","labor_demand","fuel_demand","pollution","timber_pressure","ecological_pressure","disease_exposure","injury_risk","disaster_risk","health_risk","institutional_rigidity","fatigue"]
var terrain:Node
var hud:Node
var pending:Array[Dictionary]=[]
var received:Dictionary={}
var current:Dictionary={}
var pause=Pause.new()
var surface:Control
var panel:PanelContainer
var body:VBoxContainer
var scroll:ScrollContainer
var footer:HBoxContainer
var counter:Label
var next_button:Button
var dismiss_button:Button
var effect_cards:Dictionary={}
var heading:Label
var hero:TextureRect
var closing:=false
static func announce(terrain_node:Node,hud_node:Node,events:Array[Dictionary])->CanvasLayer:
	if events.is_empty() or not is_instance_valid(hud_node):return null
	var popup:Variant=hud_node.get_meta("discovery_popup") if hud_node.has_meta("discovery_popup") else null
	if not is_instance_valid(popup) or popup.closing:
		popup=new();popup.terrain=terrain_node;popup.hud=hud_node
		hud_node.set_meta("discovery_popup",popup);hud_node.add_child(popup)
	popup.enqueue(events)
	return popup
func _ready()->void:
	layer=110
	surface=Control.new();surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(surface)
	var shade:=ColorRect.new();shade.color=Color(0.015,.03,.04,.78);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);surface.add_child(shade)
	shade.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close())
	panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",T.flat(Color("101e25"),T.GOLD,1,10,16));surface.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	var top:=HBoxContainer.new();column.add_child(top)
	counter=Art.label(top,"A NEW DISCOVERY",12,T.GOLD);counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Art.button(top,"×",close).tooltip_text="Dismiss all · Escape or click outside"
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
	footer=HBoxContainer.new();footer.add_theme_constant_override("separation",8);column.add_child(footer)
	Art.button(footer,"View in research",open_research).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	dismiss_button=Art.button(footer,"Dismiss all",close)
	next_button=Art.button(footer,"Continue",advance)
	surface.resized.connect(layout);layout()
func layout()->void:
	var extent:=get_viewport().get_visible_rect().size
	panel.size=Vector2(minf(740,extent.x-48),minf(730,extent.y-48));panel.position=(extent-panel.size)*.5
	if is_instance_valid(hero):hero.custom_minimum_size.y=210 if extent.y>=750 else 142
func enqueue(events:Array[Dictionary])->void:
	for event:Dictionary in events:
		var id:=String(event.get("id",""))
		if id=="" or id not in GameState.known_discoveries or received.has(id):continue
		received[id]=true;pending.append(DiscoverySystem.player_facing_discovery_event(event))
	if current.is_empty() and not pending.is_empty():pause.acquire(terrain);advance()
	elif not current.is_empty():_queue_labels()
	elif pending.is_empty():close()
func _queue_labels()->void:
	counter.text="A NEW DISCOVERY"+("  ·  %d more" % pending.size() if not pending.is_empty() else "")
	next_button.text="Next discovery →" if not pending.is_empty() else "Continue"
	dismiss_button.visible=not pending.is_empty()
func advance()->void:
	if pending.is_empty():close();return
	current=pending.pop_front();_queue_labels();render()
func render()->void:
	for child in body.get_children():body.remove_child(child);child.queue_free()
	effect_cards.clear()
	var domain:=String(current.get("dynamic","knowledge"))
	hero=Art.paint(body,domain,210 if get_viewport().get_visible_rect().size.y>=750 else 142)
	var label_row:=HBoxContainer.new();body.add_child(label_row)
	Art.label(label_row,Art.name_for(domain).to_upper(),11,Art.color(domain)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Art.label(label_row,"Year %d · Day %d" % [int(current.get("day",0))/365+1,int(current.get("day",0))%365+1],11,T.MUTED).custom_minimum_size.x=112
	heading=Art.label(body,String(current.get("name","New discovery")),32,T.INK,true)
	Art.label(body,String(current.get("description","")),17,T.BODY,true)
	var effects:Dictionary=current.get("effects",{})
	if not effects.is_empty():
		Art.label(body,"WHAT CHANGES",11,T.GOLD)
		var cards:=GridContainer.new();cards.columns=2;cards.add_theme_constant_override("h_separation",8);cards.add_theme_constant_override("v_separation",8);body.add_child(cards)
		for key:String in effects:
			var value:=float(effects[key]);var beneficial:bool=(value<0) if key in COSTS else (value>0)
			var ink:=T.GREEN if beneficial else T.AMBER
			var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",T.flat(Color("1b2e34"),ink.darkened(.55),1,5,10));cards.add_child(card)
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
			var amount:=Art.label(row,percent(value),24,ink);amount.custom_minimum_size.x=96
			var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(names)
			Art.label(names,DiscoverySystem.EFFECT_DISPLAY_NAMES.get(key,key.replace("_"," ")).capitalize(),13,T.INK,true)
			Art.label(names,"Benefit" if beneficial else "Trade-off",10,ink)
			effect_cards[key]={"value":amount,"beneficial":beneficial}
		Art.label(body,"These are the discovery’s effects at full adoption. Their contribution grows as people put the new practice to use.",12,T.TEXT_SOFT,true)
	else:Art.label(body,"This finding adds to your civilization’s established knowledge. Its practical uses depend on the resources and earlier discoveries your people can combine with it.",13,T.TEXT_SOFT,true)
	var consequence:=String(current.get("social_consequence",""))
	if consequence!="":Art.label(body,consequence,13,T.TEXT_SOFT,true)
	scroll.scroll_vertical=0
	call_deferred("layout")
static func percent(value:float)->String:
	var magnitude:=absf(value)*100
	var text:="<0.1" if magnitude>0 and magnitude<.05 else "%.1f" % magnitude
	if text.ends_with(".0"):text=text.trim_suffix(".0")
	return ("+" if value>0 else "−" if value<0 else "")+text+"%"
func close()->void:
	if closing:return
	closing=true;pause.release();queue_free()
func _exit_tree()->void:pause.release()
func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		close();get_viewport().set_input_as_handled()
func open_research()->void:
	if not is_instance_valid(hud):close();return
	var id:=String(current.get("id",""))
	close()
	preload("res://scripts/hud/knowledge_atlas.gd").open(terrain,hud,"inquiry")
	var atlas=hud.get_meta("knowledge_atlas").get_child(0)
	atlas.set_view("known");atlas.select(id)
