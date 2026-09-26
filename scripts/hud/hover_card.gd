extends CanvasLayer
## TOP-BAR HOVER CARDS: the one small card that opens when the pointer rests on
## a top-bar chip or control (PEOPLE, STORES, WATER, LIVES, LORE, the day and
## the pace buttons).
##
## A card is a glance, not a ledger: a kicker, the value, one plain sentence
## saying what it means and why, at most four short facts (each with a trend
## arrow when the trend is known), an optional sparkline or bar, and one line
## saying where to act. Full city-by-city tallies stay in the Tallies drawer.
##
## Behaviour: opens after OPEN_DELAY, switches at once between neighbouring
## chips, closes CLOSE_GRACE after the pointer leaves, never takes the mouse
## (so it cannot flicker by covering its own anchor), is anchored under the
## hovered control and flips/clamps to stay fully on screen. Only one card
## exists, drawn above the Chronicle card layer, so two never stack.
##
## Spec keys (all optional but kicker/value/headline):
##   kicker, value, unit, headline, tone ("good"|"warning"|"neutral"),
##   facts:[{text, trend:-1|0|1 (omit for none), good:bool}],
##   spark:Array[float], meter:float (0..1, <0 none), meter_label, action
const T:=preload("res://scripts/hud/hud_tokens.gd")
const OPEN_DELAY:=0.25
const CLOSE_GRACE:=0.12
const REFRESH_SECONDS:=0.75
const WIDTH:=300.0
## Text width inside the card's 14 px side padding.
const INNER:=WIDTH-28.0
const GAP:=8.0
const MARGIN:=8.0
const MAX_FACTS:=4
## Above chronicle_card.gd (72): a card the player asked for is never hidden.
const LAYER:=90

var card:PanelContainer
var anchor:Control
var provider:Callable
var _pending:Control
var _pending_provider:Callable
var _open_timer:Timer
var _close_timer:Timer
var _signature:=""
var _refresh_elapsed:=0.0

func _init()->void:
	name="HoverCards"
	layer=LAYER
	process_mode=Node.PROCESS_MODE_ALWAYS
	card=PanelContainer.new()
	card.name="HoverCard"
	card.visible=false
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size.x=WIDTH
	add_child(card)
	_open_timer=Timer.new();_open_timer.one_shot=true;_open_timer.timeout.connect(_on_open_timeout);add_child(_open_timer)
	_close_timer=Timer.new();_close_timer.one_shot=true;_close_timer.timeout.connect(hide_card);add_child(_close_timer)

## Gives `control` a hover card built from `source.call()` (a spec Dictionary).
## Clears the control's built-in tooltip so Godot never opens a second popup.
func attach(control:Control,source:Callable)->void:
	control.tooltip_text=""
	if control.mouse_filter==Control.MOUSE_FILTER_IGNORE:control.mouse_filter=Control.MOUSE_FILTER_PASS
	control.mouse_entered.connect(_on_enter.bind(control,source))
	control.mouse_exited.connect(_on_exit.bind(control))
	control.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:hide_card())

func is_open()->bool:
	return card.visible and is_instance_valid(anchor)

func _on_enter(control:Control,source:Callable)->void:
	_close_timer.stop()
	if is_open():
		# Already reading a card: move straight to the neighbour, no second wait.
		if anchor!=control:show_for(control,source)
		return
	_pending=control;_pending_provider=source
	_open_timer.start(OPEN_DELAY)

func _on_exit(control:Control)->void:
	if _pending==control:
		_open_timer.stop();_pending=null
	if anchor==control:_close_timer.start(CLOSE_GRACE)

func _on_open_timeout()->void:
	if is_instance_valid(_pending) and _pending.is_visible_in_tree():show_for(_pending,_pending_provider)
	_pending=null

func show_for(control:Control,source:Callable)->void:
	anchor=control;provider=source;_signature="";_refresh_elapsed=0.0
	_rebuild()

func hide_card()->void:
	_open_timer.stop();_close_timer.stop()
	card.visible=false
	anchor=null;_pending=null;_signature=""

func _process(delta:float)->void:
	if not card.visible:return
	if not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		hide_card();return
	# A modal or dock can open under a resting pointer without a mouse_exited.
	# Ask the GUI what it hovers (the same source as mouse_entered/exited).
	var hovered:=anchor.get_viewport().gui_get_hovered_control()
	if hovered!=anchor and not (hovered!=null and anchor.is_ancestor_of(hovered)) and _close_timer.is_stopped():
		_close_timer.start(CLOSE_GRACE)
	_refresh_elapsed+=delta
	if _refresh_elapsed>=REFRESH_SECONDS:
		_refresh_elapsed=0.0
		_rebuild()

func _rebuild()->void:
	if not is_instance_valid(anchor) or not provider.is_valid():return
	var spec:Dictionary=provider.call()
	if spec.is_empty():
		hide_card();return
	var signature:=var_to_str(spec)
	if signature==_signature and card.visible:return
	_signature=signature
	card.theme=T.control_theme()
	card.add_theme_stylebox_override("panel",panel_style())
	for child in card.get_children():
		card.remove_child(child);child.queue_free()
	card.add_child(content(spec))
	# Wrapped labels report a tall minimum until they have a width, so sort
	# the card at its fixed width first and measure afterwards.
	card.size=Vector2(WIDTH,0)
	for sort_pass in 3:
		card.propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)
		card.size=Vector2(WIDTH,card.get_combined_minimum_size().y)
	card.position=place(anchor.get_global_rect(),card.size,get_viewport().get_visible_rect().size)
	card.visible=true

## Under the anchor, left edges aligned; flipped to right-align near the right
## edge, above the anchor when there is no room below, then clamped on screen.
## The anchor itself is never covered unless the screen is too small for both.
static func place(anchor_rect:Rect2,card_size:Vector2,view:Vector2)->Vector2:
	var x:=anchor_rect.position.x
	if x+card_size.x>view.x-MARGIN:x=anchor_rect.end.x-card_size.x
	x=clampf(x,MARGIN,maxf(MARGIN,view.x-MARGIN-card_size.x))
	var y:=anchor_rect.end.y+GAP
	if y+card_size.y>view.y-MARGIN:
		var above:=anchor_rect.position.y-GAP-card_size.y
		if above>=MARGIN:y=above
		else:y=clampf(y,MARGIN,maxf(MARGIN,view.y-MARGIN-card_size.y))
	return Vector2(roundf(x),roundf(y))

## Solid paper in light mode, solid slate in dark: never see-through, never
## dark ink on a dark panel.
static func panel_style()->StyleBoxFlat:
	var style:=T.tooltip_panel_style()
	style.bg_color.a=1.0
	style.content_margin_left=14.0;style.content_margin_right=14.0
	style.content_margin_top=10.0;style.content_margin_bottom=10.0
	style.set_corner_radius_all(6)
	style.shadow_size=10;style.shadow_offset=Vector2(0,4)
	return style

static func tone_color(tone:String)->Color:
	return T.RED if tone=="warning" else T.GREEN if tone=="good" else T.GOLD

static func trend_glyph(trend:int)->String:
	return "↑" if trend>0 else "↓" if trend<0 else "→"

static func content(spec:Dictionary)->VBoxContainer:
	var accent:=tone_color(String(spec.get("tone","neutral")))
	var column:=VBoxContainer.new()
	column.name="HoverCardContent"
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation",6)
	var kicker:=_label(String(spec.get("kicker","")).to_upper(),10,accent,0.12)
	column.add_child(kicker)
	var hero:=HBoxContainer.new();hero.mouse_filter=Control.MOUSE_FILTER_IGNORE;hero.add_theme_constant_override("separation",8);column.add_child(hero)
	hero.add_child(_label(String(spec.get("value","")),20,T.INK))
	var unit:=String(spec.get("unit",""))
	if unit!="":
		var unit_label:=_label(unit,12,T.MUTED);unit_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		unit_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;unit_label.clip_text=true;unit_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		hero.add_child(unit_label)
	var headline:=_label(String(spec.get("headline","")),13,T.BODY)
	headline.name="Headline";headline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;headline.custom_minimum_size.x=INNER
	column.add_child(headline)
	var facts:Array=spec.get("facts",[])
	if not facts.is_empty():
		var list:=VBoxContainer.new();list.name="Facts";list.mouse_filter=Control.MOUSE_FILTER_IGNORE;list.add_theme_constant_override("separation",3);column.add_child(list)
		for fact:Dictionary in facts.slice(0,MAX_FACTS):
			var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",6);list.add_child(row)
			var glyph:=_label("•",12,T.MUTED);glyph.custom_minimum_size.x=12;glyph.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			if fact.has("trend"):
				var trend:=int(fact.trend)
				glyph.text=trend_glyph(trend)
				glyph.add_theme_color_override("font_color",T.MUTED if trend==0 else (T.GREEN if bool(fact.get("good",true)) else T.RED))
			row.add_child(glyph)
			var text:=_label(String(fact.get("text","")),12,T.BODY);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.custom_minimum_size.x=INNER-18.0
			row.add_child(text)
	var spark:Array=spec.get("spark",[])
	if spark.size()>=3:
		var line:=Spark.new();line.values=spark;line.color=accent;line.custom_minimum_size=Vector2(0,26);column.add_child(line)
		if String(spec.get("spark_label",""))!="":column.add_child(_label(String(spec.spark_label),10,T.MUTED))
	elif float(spec.get("meter",-1.0))>=0.0:
		var bar:=ProgressBar.new();bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;bar.custom_minimum_size.y=6;bar.show_percentage=false;bar.value=clampf(float(spec.meter),0.0,1.0)*100.0
		bar.add_theme_stylebox_override("background",T.flat(T.TRACK,Color(0,0,0,0),0,3));bar.add_theme_stylebox_override("fill",T.flat(accent,Color(0,0,0,0),0,3))
		column.add_child(bar)
		if String(spec.get("meter_label",""))!="":column.add_child(_label(String(spec.meter_label),10,T.MUTED))
	var action:=String(spec.get("action",""))
	if action!="":
		var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size.y=1;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(rule)
		var act:=_label(action,11,T.GOLD_BRIGHT if T.is_light() else T.GOLD);act.name="Action";act.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;act.custom_minimum_size.x=INNER
		column.add_child(act)
	return column

static func _label(text:String,size:int,color:Color,spacing:float=0.0)->Label:
	var label:=T.make_label(text,size,color,spacing)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

## A tiny line of recent values: shape, not numbers.
class Spark extends Control:
	var values:Array=[]
	var color:Color=Color.WHITE
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		if values.size()<2:return
		var low:=INF;var high:=-INF
		for v in values:low=minf(low,float(v));high=maxf(high,float(v))
		var span:=maxf(high-low,absf(high)*0.05+0.0001)
		var points:=PackedVector2Array()
		for i in values.size():
			var x:=size.x*float(i)/float(values.size()-1)
			var y:=size.y-2.0-(size.y-4.0)*(float(values[i])-low)/span
			points.append(Vector2(x,y))
		draw_line(Vector2(0,size.y-0.5),Vector2(size.x,size.y-0.5),Color(color,0.25),1.0)
		draw_polyline(points,color,1.6,true)
		draw_circle(points[-1],2.5,color)
