extends VBoxContainer
## YOUR ORDERS: the fail-safe indicator at the bottom right of the screen.
##
## Every order the god gives gets a card here (order_tracker.gd): the order in
## plain words, who carries it out, and how it stands in the engine's ledger,
## with a small bar where there is a count. Newest on top, at most
## MAX_VISIBLE; "All" shows every recent order. A card the ledger has not
## moved by the end of the next game day turns red: NOTHING HAS HAPPENED.
## A click opens the screen where the order lives.
##
## Paper and ink (hud_tokens.gd); icons drawn by resource_icons.gd. Cheap: it
## rebuilds only when the tracker says a card changed, and asks the tracker to
## read the ledger once a game day (a single integer compare twice a second).
## The HUD places it (place()) beside the rail, the docks and the court:
## bottom right normally, and a single line at the top right while a dock
## covers the bottom right.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

signal open_requested(screen:String)
## The stack's height settled after its labels wrapped: the HUD places it again.
signal relayout

const WIDTH:=300.0
const MAX_VISIBLE:=4
## A finished order's card stays this long on screen, then fades.
const DONE_SHOW_MS:=9000
const FADE_SECONDS:=1.2
const CHECK_SECONDS:=0.5
## The words each state leads with on a card.
const STATE_WORDS:={"accepted":"Given","under_way":"Under way","done":"Done","stalled":"Stalled","refused":"Not done","nothing":"NOTHING HAS HAPPENED","called_off":"Called off"}
## The words' column on a card: the card's width less its stripe, glyph and
## margins, so a wrapped line knows its height from the first frame.
const TEXT_WIDTH:=WIDTH-10.0-4.0-8.0-22.0-8.0
## States whose card shows a few seconds, then fades.
const FADING:=["done","called_off"]

var plate:PanelContainer
var header:HBoxContainer
var caption:Label
var all_button:Button
var cards:VBoxContainer
var all_panel:PanelContainer
var all_rows:VBoxContainer
var compact:=false
## Hidden while the court's card fills the screen (the court tells it).
var suppressed:=false
var showing_all:=false
var _dirty:=true
var _clock:=0.0
var _last_day:=-1
var _signature:=""
## id -> msec when its card was first shown done.
var _done_seen:Dictionary={}
## What the cards on the face show: [id, state, has bar, has who] each. When
## only their words and bars move, the cards are updated where they stand
## (no rebuild, no jump); id -> {status, bar, card} for that.
var _shape:=[]
var _parts:Dictionary={}
## The stack's size when it last asked to be placed.
var _placed_size:=Vector2(-1,-1)


func _ready()->void:
	name="OrderStack"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation",5)
	custom_minimum_size=Vector2(WIDTH,0)
	all_panel=PanelContainer.new();all_panel.name="AllOrders";all_panel.visible=false
	all_panel.add_theme_stylebox_override("panel",_paper(Tokens.BORDER_SOFT))
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(WIDTH-16,0);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;all_panel.add_child(scroll)
	all_rows=VBoxContainer.new();all_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;all_rows.add_theme_constant_override("separation",3);scroll.add_child(all_rows)
	add_child(all_panel)
	plate=PanelContainer.new();plate.name="OrdersPlate";plate.size_flags_horizontal=Control.SIZE_SHRINK_END
	plate.add_theme_stylebox_override("panel",_chip(false))
	add_child(plate)
	header=HBoxContainer.new();header.name="OrdersHeader";header.add_theme_constant_override("separation",8);header.alignment=BoxContainer.ALIGNMENT_END
	plate.add_child(header)
	caption=Tokens.make_label("YOUR ORDERS",11,Tokens.GOLD_TEXT,0.1);caption.name="OrdersCaption";caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header.add_child(caption)
	all_button=Button.new();all_button.name="AllOrdersButton";all_button.focus_mode=Control.FOCUS_NONE
	all_button.add_theme_font_size_override("font_size",12)
	all_button.add_theme_color_override("font_color",Tokens.text_for(Tokens.GOLD))
	all_button.add_theme_stylebox_override("normal",_chip(false));all_button.add_theme_stylebox_override("hover",_chip(true));all_button.add_theme_stylebox_override("pressed",_chip(true))
	all_button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	all_button.tooltip_text="Every order you gave lately, and how each stands."
	all_button.pressed.connect(toggle_all)
	header.add_child(all_button)
	cards=VBoxContainer.new();cards.name="OrderCards";cards.add_theme_constant_override("separation",5)
	add_child(cards)
	Tracker.hub().changed.connect(_on_changed)
	_last_day=int(GameState.elapsed_days)
	rebuild()


func _exit_tree()->void:
	if Tracker.hub().changed.is_connected(_on_changed):Tracker.hub().changed.disconnect(_on_changed)


func _on_changed()->void:
	if _dirty:return
	_dirty=true
	rebuild.call_deferred()


## Twice a second: a new game day reads the ledger once (the tracker emits a
## change only when a card moved), and finished cards fade on time.
func _process(delta:float)->void:
	_clock+=delta
	if _clock<CHECK_SECONDS:return
	_clock=0.0
	var day:=int(GameState.elapsed_days)
	if day!=_last_day:
		_last_day=day
		Tracker.update(day)
	var orders:=Tracker.orders()
	var signature:="%d|%d" % [orders.size(),int((orders[0] as Dictionary).get("id",0)) if not orders.is_empty() else 0]
	if signature!=_signature:_on_changed()
	elif _expired():_on_changed()


func _expired()->bool:
	var now:=Time.get_ticks_msec()
	for card in cards.get_children():
		var id:=int(card.get_meta("order_id",0))
		if _done_seen.has(id) and now-int(_done_seen[id])>DONE_SHOW_MS+int(FADE_SECONDS*1000.0):return true
	return false


## Orders on the face of the stack, newest first: finished ones only while
## their few seconds last, a refusal for a day, the red ones until newer
## orders push them into "All".
func shown()->Array:
	var now:=Time.get_ticks_msec()
	var out:=[]
	for o in Tracker.current(1):
		var order:Dictionary=o
		var id:=int(order.id)
		if String(order.state) in FADING:
			if not _done_seen.has(id):_done_seen[id]=now
			if now-int(_done_seen[id])>DONE_SHOW_MS+int(FADE_SECONDS*1000.0):continue
		out.append(order)
		if out.size()>=MAX_VISIBLE:break
	return out


## The cards' make-up: what decides which nodes a card has.
static func card_shape(o:Dictionary)->Array:
	var state:=String(o.get("state","accepted"))
	return [int(o.get("id",0)),state,int(o.get("total",0))>0 and state!="refused",String(o.get("who",""))!=""]


func rebuild()->void:
	_dirty=false
	var orders:=Tracker.orders()
	_signature="%d|%d" % [orders.size(),int((orders[0] as Dictionary).get("id",0)) if not orders.is_empty() else 0]
	var list:=shown()
	var shape:=list.map(func(o)->Array:return card_shape(o as Dictionary))
	# Only words and bars moved (a day's progress): change them where they
	# stand. Rebuilding every card each game day shook the stack at speed.
	if shape==_shape and not compact and cards.get_child_count()==list.size() and not showing_all:
		for o in list:_update_card(o as Dictionary)
		_header(orders)
		_settle.call_deferred()
		return
	_shape=shape
	_parts.clear()
	for child in cards.get_children():
		cards.remove_child(child);child.queue_free()
	_header(orders)
	if not compact:
		for o in list:cards.add_child(_card(o as Dictionary))
	cards.visible=not compact
	if showing_all:_fill_all()
	all_panel.visible=showing_all
	visible=not orders.is_empty() and not suppressed
	reset_size()
	_settle.call_deferred()


## The caption and the All button: red while orders of the last month were
## not carried out.
func _header(orders:Array)->void:
	var red:=0
	var today:=int(GameState.elapsed_days)
	for o in orders:
		if String((o as Dictionary).state)=="nothing" and today-int((o as Dictionary).get("day",today))<=30:red+=1
	all_button.text=("All %d" % orders.size()) if not showing_all else "Hide"
	all_button.visible=not orders.is_empty()
	caption.text="YOUR ORDERS" if red==0 else "YOUR ORDERS · %d NOT CARRIED OUT" % red
	caption.add_theme_color_override("font_color",Tokens.RED_TEXT if red>0 else Tokens.GOLD_TEXT)
	plate.visible=not orders.is_empty()


## A card's words, bar and colour, changed where it stands.
func _update_card(o:Dictionary)->void:
	var parts:Dictionary=_parts.get(int(o.id),{})
	if parts.is_empty():return
	var state:=String(o.get("state","accepted"))
	(parts.status as Label).text=status_words(o)
	(parts.card as Control).tooltip_text=_tooltip(o)
	if parts.has("bar") and is_instance_valid(parts.bar):
		var bar:Bar=parts.bar
		var share:=clampf(float(o.get("value",0))/float(maxi(1,int(o.get("total",0)))),0.0,1.0)
		if not is_equal_approx(bar.share,share):bar.share=share;bar.queue_redraw()


## Wrapped labels report their true height only after the first sort: the
## stack shrinks to it a frame later and asks the HUD to place it again, only
## when its size really changed (so a day's new words never shake it).
func _settle()->void:
	if not is_inside_tree():return
	if not get_tree().process_frame.is_connected(_settled):get_tree().process_frame.connect(_settled,CONNECT_ONE_SHOT)

func _settled()->void:
	reset_size()
	var now:=get_combined_minimum_size()
	if now.is_equal_approx(_placed_size):return
	_placed_size=now
	relayout.emit()


func toggle_all()->void:
	showing_all=not showing_all
	rebuild()


func set_suppressed(value:bool)->void:
	if suppressed==value:return
	suppressed=value
	visible=not Tracker.orders().is_empty() and not suppressed

## The single top-right line used while a dock covers the bottom right.
func set_compact(value:bool)->void:
	if compact==value:return
	compact=value
	rebuild()


# --- One card ---------------------------------------------------------------

static func state_colour(state:String)->Color:
	match state:
		"under_way":return Tokens.TEAL
		"done":return Tokens.GREEN
		"stalled":return Tokens.AMBER
		"refused","nothing":return Tokens.RED
	return Tokens.BORDER_2

static func icon_kind(o:Dictionary)->String:
	match String(o.get("kind","")):
		"levy","recruit_line":return "drilling"
		"workshop","line":return "gear"
		"march":
			match String((o.get("refs",{}) as Dictionary).get("kind","")):
				"attack","siege","storm":return "attack"
				"raid":return "raid"
				"guard","defend":return "guard"
				"front":return "front"
				"recall":return "recall"
				"depot":return "depot"
			return "goto"
		"band":return "deploy"
		"defences":return "defend"
		"waiting","civic","directive","settled":return "will"
	return "date" if not bool(o.get("claimed",false)) else "will"

## The status words as the card shows them: the state first.
static func status_words(o:Dictionary)->String:
	var state:=String(o.get("state","accepted"))
	var line:=String(o.get("line",""))
	if state=="nothing":
		var rest:=line.trim_prefix("Nothing has happened yet: ").trim_prefix("Not carried out: ")
		return rest.substr(0,1).to_upper()+rest.substr(1)
	if state in ["done","refused","called_off"] and not line.begins_with(String(STATE_WORDS[state])):return Tracker.short("%s · %s" % [STATE_WORDS[state],line])
	return line

func _card(o:Dictionary)->PanelContainer:
	var state:=String(o.get("state","accepted"))
	var colour:=state_colour(state)
	var card:=PanelContainer.new();card.name="OrderCard%d" % int(o.id)
	card.set_meta("order_id",int(o.id))
	card.mouse_filter=Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("panel",_paper(colour if state in ["nothing","refused"] else Tokens.BORDER_SOFT,state=="nothing"))
	card.tooltip_text=_tooltip(o)
	var screen:=String(o.get("screen",""))
	card.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			open_requested.emit(screen))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
	var stripe:=ColorRect.new();stripe.color=colour;stripe.custom_minimum_size=Vector2(4,0);stripe.size_flags_vertical=Control.SIZE_EXPAND_FILL;stripe.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(stripe)
	var icon:=TextureRect.new();icon.texture=Icons.command_texture(icon_kind(o),Tokens.text_for(colour) if state!="accepted" else Tokens.MUTED,32)
	icon.custom_minimum_size=Vector2(22,22);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",1);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(column)
	var title:=_line(String(o.get("words","Order")),13,Tokens.INK);title.name="OrderTitle";column.add_child(title)
	var who:=String(o.get("who",""))
	if who!="":
		var by:=_line("By "+who,12,Tokens.MUTED);by.name="OrderWho";column.add_child(by)
	if state=="nothing":
		var alarm:=_line(String(STATE_WORDS.nothing),12,Tokens.RED_TEXT,0.06);alarm.name="OrderAlarm";alarm.add_theme_font_override("font",Tokens.font("ui_strong"));column.add_child(alarm)
	var status:=Label.new();status.name="OrderStatus";status.text=status_words(o)
	Tokens.style_label(status,12,Tokens.text_for(colour) if state!="accepted" else Tokens.BODY_2)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.max_lines_visible=2;status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# A set width: the wrapped words know their height before the first sort.
	status.custom_minimum_size=Vector2(TEXT_WIDTH,0)
	column.add_child(status)
	var parts:={"card":card,"status":status}
	var total:=int(o.get("total",0))
	if total>0 and state!="refused":
		var bar:=Bar.new();bar.name="OrderBar";bar.share=clampf(float(o.get("value",0))/float(total),0.0,1.0);bar.fill=colour;bar.track=Tokens.TRACK
		bar.custom_minimum_size=Vector2(0,4);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(bar)
		parts["bar"]=bar
	_parts[int(o.id)]=parts
	if state in FADING:
		var id:=int(o.id)
		var left:=float(DONE_SHOW_MS-(Time.get_ticks_msec()-int(_done_seen.get(id,Time.get_ticks_msec()))))/1000.0
		var tween:=card.create_tween()
		tween.tween_interval(maxf(0.0,left))
		tween.tween_property(card,"modulate:a",0.0,FADE_SECONDS)
		tween.tween_callback(_on_changed)
	return card

func _tooltip(o:Dictionary)->String:
	var parts:=PackedStringArray()
	parts.append(String(o.get("words","")))
	if String(o.get("said",""))!="" and String(o.get("said",""))!=String(o.get("words","")):parts.append("You said: “%s”" % String(o.said))
	if String(o.get("who",""))!="":parts.append("Carried out by "+String(o.who))
	parts.append("%s: %s" % [String(STATE_WORDS.get(String(o.get("state","")),"")),String(o.get("line",""))])
	parts.append("Given %s." % preload("res://scripts/hud/era_words.gd").when(int(o.get("day",0))).to_lower())
	if String(o.get("screen",""))!="":parts.append("Click to open where it is carried out.")
	return "\n".join(parts)

func _line(text:String,size:int,colour:Color,spacing:float=0.0)->Label:
	var label:=Tokens.make_label(text,size,colour,spacing)
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.max_lines_visible=1;label.clip_text=true
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

# --- Every recent order ---------------------------------------------------------

func _fill_all()->void:
	for child in all_rows.get_children():
		all_rows.remove_child(child);child.queue_free()
	var scroll:=all_panel.get_child(0) as ScrollContainer
	for o in Tracker.orders():
		var order:Dictionary=o
		var state:=String(order.state)
		var row:=Button.new();row.name="AllOrder%d" % int(order.id);row.flat=true;row.focus_mode=Control.FOCUS_NONE
		row.alignment=HORIZONTAL_ALIGNMENT_LEFT;row.clip_text=true;row.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		row.text="%s — %s" % [String(order.words),status_words(order) if state!="nothing" else "NOTHING HAS HAPPENED: "+status_words(order)]
		row.tooltip_text=_tooltip(order)
		row.add_theme_font_size_override("font_size",12)
		row.add_theme_color_override("font_color",Tokens.text_for(state_colour(state)) if state!="accepted" else Tokens.BODY_2)
		row.add_theme_color_override("font_hover_color",Tokens.INK)
		var screen:=String(order.get("screen",""))
		row.pressed.connect(func()->void:open_requested.emit(screen))
		all_rows.add_child(row)
	scroll.custom_minimum_size.y=minf(all_rows.get_combined_minimum_size().y,360.0)

# --- Paper ---------------------------------------------------------------------

static func _paper(border:Color,alarm:bool=false)->StyleBoxFlat:
	var style:=Tokens.flat(Tokens.PANEL_BG_SOLID.lerp(Tokens.RED,0.10) if alarm else Tokens.PANEL_BG_SOLID,border,2 if alarm else 1,3)
	style.content_margin_left=0.0;style.content_margin_right=10.0;style.content_margin_top=7.0;style.content_margin_bottom=7.0
	style.shadow_color=Color(0,0,0,0.18);style.shadow_size=4
	return style

static func _chip(hover:bool)->StyleBoxFlat:
	var style:=Tokens.flat(Tokens.HOVER_BG if hover else Tokens.PANEL_BG_SOLID,Tokens.BORDER_SOFT,1,3)
	style.content_margin_left=8.0;style.content_margin_right=8.0;style.content_margin_top=1.0;style.content_margin_bottom=1.0
	return style

## A thin bar: share of the work done.
class Bar extends Control:
	var share:=0.0
	var fill:=Color.WHITE
	var track:=Color.GRAY
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),track)
		draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*share,size.y)),fill)
