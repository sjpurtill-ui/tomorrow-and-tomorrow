extends CanvasLayer
## Announce only newly completed player discoveries supplied by the daily loop.
## Existing knowledge stays in the research archive and is not replayed on load.
const Art=preload("res://scripts/hud/research_visuals.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Motion=preload("res://scripts/hud/motion.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
## The hero moment of the research loop: the painting rises from the dark and
## wipes in left to right like ink drying (SCENE), then the carved title, a gold
## hairline drawn beneath it, and one line of story.
const HERO_HEIGHT:=300.0
const COSTS=["food_spoilage","labor_demand","fuel_demand","pollution","timber_pressure","ecological_pressure","disease_exposure","injury_risk","disaster_risk","health_risk","institutional_rigidity","fatigue"]
var terrain:Node
var hud:Node
var pending:Array[Dictionary]=[]
var received:Dictionary={}
var current:Dictionary={}
var surface:Control
var panel:PanelContainer
var body:VBoxContainer
var scroll:ScrollContainer
var footer:BoxContainer
var introduction:BoxContainer
var discovery_summary:VBoxContainer
var benefits:GridContainer
var counter:Label
var next_button:Button
var dismiss_button:Button
var effect_cards:Dictionary={}
var heading:Label
var hero:Control
var closing:=false
var shade:ColorRect
var veil:Control
var title_rule:ColorRect
var story:Label
var kicker:Label
var reveal:Tween
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
	shade=ColorRect.new();shade.color=Color(0.03,.025,.02,.82);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);surface.add_child(shade)
	shade.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close())
	panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",T.flat(Color("101e25"),T.GOLD,1,4,24));surface.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	var top:=HBoxContainer.new();column.add_child(top)
	counter=Art.label(top,"SOMETHING NEW IS KNOWN",12,T.GOLD);counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Art.button(top,"×",close).tooltip_text="Dismiss all · Escape or click outside"
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
	footer=BoxContainer.new();footer.add_theme_constant_override("separation",8);column.add_child(footer)
	Art.button(footer,"View in research",open_research).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	dismiss_button=Art.button(footer,"Dismiss all",close)
	next_button=Art.button(footer,"Continue",advance)
	surface.resized.connect(layout);layout()
	Motion.fade_in(surface,Motion.SLOW)
func layout()->void:
	var extent:=get_viewport().get_visible_rect().size
	var target:=Vector2(minf(740,extent.x-48),minf(730,extent.y-48))
	var narrow:=target.x<580
	footer.vertical=narrow
	# The painting always leads, full width, above the words.
	if is_instance_valid(introduction):introduction.vertical=true
	if is_instance_valid(discovery_summary):discovery_summary.custom_minimum_size.x=0
	if is_instance_valid(hero):
		hero.custom_minimum_size=Vector2(0,minf(HERO_HEIGHT,maxf(150.0,(target.x-48)*.46)) if not narrow else minf(200,(target.x-48)*.62))
	if is_instance_valid(benefits):benefits.columns=1 if narrow else 2
	panel.size=target;panel.position=(extent-target)*.5
func enqueue(events:Array[Dictionary])->void:
	for event:Dictionary in events:
		var id:=String(event.get("id",""))
		if id=="" or id not in GameState.known_discoveries or received.has(id):continue
		received[id]=true;pending.append(DiscoverySystem.player_facing_discovery_event(event))
	if current.is_empty() and not pending.is_empty():advance()
	elif not current.is_empty():_queue_labels()
	elif pending.is_empty():close()
func _queue_labels()->void:
	counter.text="SOMETHING NEW IS KNOWN"+("  ·  %s MORE" % String(EraWords.count_word(pending.size())).to_upper() if not pending.is_empty() else "")
	next_button.text="Next discovery →" if not pending.is_empty() else "Continue"
	dismiss_button.visible=not pending.is_empty()
func advance()->void:
	if pending.is_empty():close();return
	current=pending.pop_front();_queue_labels();render()
func render()->void:
	for child in body.get_children():body.remove_child(child);child.queue_free()
	effect_cards.clear()
	benefits=null
	var domain:=String(current.get("dynamic","knowledge"))
	introduction=BoxContainer.new();introduction.vertical=true;introduction.add_theme_constant_override("separation",16);body.add_child(introduction)
	hero=Art.paint_discovery(introduction,current,HERO_HEIGHT);hero.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hero.clip_contents=true
	# The ink veil: dark paper over the painting that draws back to the right.
	veil=Control.new();veil.name="InkVeil";veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hero.add_child(veil)
	var dark:=ColorRect.new();dark.color=Color("101e25") if not T.is_light() else T.PANEL_BG;dark.color.a=1.0;dark.mouse_filter=Control.MOUSE_FILTER_IGNORE;dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dark.offset_left=64;veil.add_child(dark)
	var edge:=TextureRect.new();edge.mouse_filter=Control.MOUSE_FILTER_IGNORE;edge.stretch_mode=TextureRect.STRETCH_SCALE;edge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	var fade:=Gradient.new();fade.set_color(0,Color(dark.color,0.0));fade.set_color(1,dark.color)
	var ramp:=GradientTexture2D.new();ramp.gradient=fade;ramp.width=64;ramp.height=4;edge.texture=ramp
	edge.anchor_bottom=1.0;edge.offset_right=64;veil.add_child(edge)
	discovery_summary=VBoxContainer.new();discovery_summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL;discovery_summary.add_theme_constant_override("separation",8);introduction.add_child(discovery_summary)
	var day:=int(current.get("day",0))
	var known_since:=("Known since the %s winter" % _ordinal(day/365+1)) if EraWords.hearth() else ("Known since Year %d" % (day/365+1))
	kicker=Art.label(discovery_summary,(Art.name_for(domain)+"  ·  "+known_since).to_upper(),12,Art.color(domain),true)
	heading=Art.label(discovery_summary,String(current.get("name","New discovery")),34,T.INK,true)
	heading.add_theme_font_override("font",Art.display_font())
	title_rule=ColorRect.new();title_rule.color=T.GOLD;title_rule.custom_minimum_size=Vector2(0,1);title_rule.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;title_rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;discovery_summary.add_child(title_rule)
	# One line of story: as the people saw it when the Opening Arc tells it,
	# otherwise the first sentence of what was found.
	story=Art.label(discovery_summary,_story_line(),19,T.BODY,true)
	story.add_theme_font_override("font",Art.voice_font(true))
	var rest:=String(current.get("description",""))
	if String(current.get("scene",""))!="" and rest!="":Art.label(discovery_summary,rest,14,T.TEXT_SOFT,true)
	var effects:Dictionary=current.get("effects",{})
	if not effects.is_empty():
		Art.label(body,"WHAT CHANGES",12,T.GOLD)
		var cards:=GridContainer.new();benefits=cards;cards.columns=2;cards.add_theme_constant_override("h_separation",8);cards.add_theme_constant_override("v_separation",8);body.add_child(cards)
		for key:String in effects:
			var value:=float(effects[key]);var beneficial:bool=(value<0) if key in COSTS else (value>0)
			var ink:=T.GREEN if beneficial else T.AMBER
			var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",T.flat(Color("172830"),ink.darkened(.35),1,4,12));cards.add_child(card)
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
			var amount:=Art.label(row,percent(value),24,ink);amount.custom_minimum_size.x=72
			var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(names)
			Art.label(names,DiscoverySystem.EFFECT_DISPLAY_NAMES.get(key,key.replace("_"," ")).capitalize(),13,T.INK,true)
			Art.label(names,"Benefit" if beneficial else "Trade-off",12,ink)
			effect_cards[key]={"value":amount,"beneficial":beneficial}
		Art.label(body,"These are the discovery’s effects at full adoption. Their contribution grows as people put the new practice to use.",12,T.TEXT_SOFT,true)
	else:Art.label(body,"This finding adds to your civilization’s established knowledge. Its practical uses depend on the resources and earlier discoveries your people can combine with it.",13,T.TEXT_SOFT,true)
	var consequence:=String(current.get("social_consequence",""))
	if consequence!="":Art.label(body,consequence,13,T.TEXT_SOFT,true)
	scroll.scroll_vertical=0
	call_deferred("layout")
	_reveal.call_deferred()
func _story_line()->String:
	var scene:=String(current.get("scene",""))
	if scene!="":return scene
	var text:=String(current.get("description","")).strip_edges()
	var stop:=text.find(". ")
	return text.substr(0,stop+1) if stop>0 else text
static func _ordinal(value:int)->String:
	var words:=["first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth"]
	if value>=1 and value<=words.size():return words[value-1]
	var suffix:String="th" if value%100 in [11,12,13] else ["th","st","nd","rd","th","th","th","th","th","th"][value%10]
	return "%d%s" % [value,suffix]
## The soft reveal. One tween per discovery; nothing runs once it ends.
func _reveal()->void:
	if not is_instance_valid(hero) or not is_inside_tree():return
	if reveal!=null and reveal.is_valid():reveal.kill()
	var scene_time:=Motion.duration(Motion.SCENE)
	for item:CanvasItem in [heading,title_rule,story,kicker]:if is_instance_valid(item):item.modulate.a=0.0
	panel.modulate.a=0.0
	var home:=panel.position
	panel.position=home+Vector2(0,Motion.RISE)
	veil.anchor_left=0.0;veil.offset_left=0.0
	reveal=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_parallel(true)
	reveal.tween_property(panel,"modulate:a",1.0,Motion.duration(Motion.SLOW))
	reveal.tween_property(panel,"position:y",home.y,Motion.duration(Motion.SLOW))
	# Ink drying: the veil draws back left to right across the painting.
	reveal.tween_property(veil,"anchor_left",1.0,scene_time).set_ease(Tween.EASE_IN_OUT).set_delay(Motion.duration(.12))
	reveal.tween_property(kicker,"modulate:a",1.0,Motion.duration(Motion.BASE)).set_delay(scene_time*.35)
	reveal.tween_property(heading,"modulate:a",1.0,Motion.duration(Motion.SLOW)).set_delay(scene_time*.45)
	title_rule.custom_minimum_size.x=0.0;title_rule.modulate.a=1.0
	reveal.tween_property(title_rule,"custom_minimum_size:x",minf(220.0,maxf(80.0,heading.size.x*.5)),scene_time*.6).set_delay(scene_time*.6)
	reveal.tween_property(story,"modulate:a",1.0,Motion.duration(Motion.SLOW)).set_delay(scene_time*.8)
	reveal.chain().tween_callback(func()->void:if is_instance_valid(veil):veil.visible=false)
static func percent(value:float)->String:
	var magnitude:=absf(value)*100
	var text:="<0.1" if magnitude>0 and magnitude<.05 else "%.1f" % magnitude
	if text.ends_with(".0"):text=text.trim_suffix(".0")
	return ("+" if value>0 else "−" if value<0 else "")+text+"%"
func close()->void:
	if closing:return
	closing=true
	# Eases out (BASE), then leaves; input is already released.
	if is_instance_valid(surface) and is_inside_tree():
		surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
		Motion.fade_out(surface,queue_free)
	else:queue_free()
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
