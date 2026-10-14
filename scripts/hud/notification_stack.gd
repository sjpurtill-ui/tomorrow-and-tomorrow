extends CanvasLayer
## THE NOTICE STACK: the one place the game tells the player something, at
## the top right, like an ordinary notification list.
##
##   [ Notices · 12 ]                  the log button (opens the session's log)
##   ┌ the Chronicle's moment card ┐   (hud/chronicle_card.gd, when one shows)
##   ├ who waits on your answer ───┤   an envoy: stays until answered
##   ├ urgent notices ─────────────┤   stay until dismissed, highlighted
##   ├ what stands now ────────────┤   short rows: gear short, men hungry, a
##   │                             │   hot feud, trade turned against us; each
##   │                             │   stays while it is true
##   └ notable notices ────────────┘   NOTABLE_SECONDS each, newest first
##
## Each notice: its category's icon and coloured label, the date, a headline
## and one plain sentence. A click opens what it is about (the court on a
## person, a report, a page of the dock, a place on the map); × sets it aside.
## What stands (hud/standing_notices.gd) is one line with a count: a click
## opens the screen that deals with it, and it leaves by itself when it ends.
## Minor notices never pop up; the log keeps them. Repeats merge into the
## notice still showing ("3 times"). The column stops above whatever stands at
## the bottom right (your orders) and stands aside for an open dock sheet that
## reaches it or the War screen's column: when there is no room it waits, and
## its clocks do not run. The red count on the rail's War button still shows.
##
## Data: hud/notification_model.gd (categories, tiers, merging) fed by the
## Chronicle (Chronicle.pending_notes) and by NotificationModel.push().

const Model:=preload("res://scripts/hud/notification_model.gd")
const Standing:=preload("res://scripts/hud/standing_notices.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

const WIDTH:=preload("res://scripts/hud/order_stack.gd").WIDTH
const MAX_ROWS:=4
const GAP:=6.0
const RIGHT:=T.EDGE_MARGIN
const STANDING_SECONDS:=1.0
## Every row is this tall: a headline and one fact line.
const ROW_HEIGHT:=52.0
const TOP:=T.CONTENT_TOP
const PILL_HEIGHT:=28.0
const LOG_ROWS:=40

var terrain:Node
var hud:Node
## Notices on screen (dicts from the model), urgent first, then newest first.
var rows:Array[Dictionary]=[]
## Notices waiting for room, oldest first.
var waiting:Array[Dictionary]=[]
## What stands now (hud/standing_notices.gd rows), in the source's order.
var standing:Array[Dictionary]=[]
var _standing_clock:=STANDING_SECONDS
var _standing_signature:=""
var _needing:=""
## Capture only ("--capture-standing"): sample rows shown beside the live ones.
var _seeded:Array[Dictionary]=[]
var column:Control
var pill:Button
var log_panel:PanelContainer
var log_list:VBoxContainer
var held:=false
var _views:Dictionary={}
var _signature:=""


static func ensure(terrain_node:Node,hud_node:Node)->CanvasLayer:
	if not is_instance_valid(hud_node):return null
	var existing:Variant=hud_node.get_meta("notification_stack") if hud_node.has_meta("notification_stack") else null
	if is_instance_valid(existing):return existing
	var stack:=new()
	stack.terrain=terrain_node;stack.hud=hud_node
	hud_node.set_meta("notification_stack",stack);hud_node.add_child(stack)
	return stack


## The stack of `hud_node`, if it has one.
static func of(hud_node:Node)->CanvasLayer:
	if not is_instance_valid(hud_node) or not hud_node.has_meta("notification_stack"):return null
	var existing:Variant=hud_node.get_meta("notification_stack")
	return existing if is_instance_valid(existing) else null


func _ready()->void:
	layer=72
	column=Control.new();column.name="NoticeColumn";column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	pill=Button.new();pill.name="NoticeLog";pill.focus_mode=Control.FOCUS_ALL
	pill.add_theme_font_override("font",T.FONT_UI);pill.add_theme_font_size_override("font_size",14)
	pill.add_theme_color_override("font_color",T.INK);pill.add_theme_color_override("font_hover_color",T.INK)
	var pill_style:=T.paper_panel_style(true,T.RADIUS_CARD);pill_style.content_margin_left=10;pill_style.content_margin_right=10;pill_style.content_margin_top=3;pill_style.content_margin_bottom=3
	var pill_hover:=pill_style.duplicate() as StyleBoxFlat;pill_hover.border_color=T.GOLD
	pill.add_theme_stylebox_override("normal",pill_style);pill.add_theme_stylebox_override("hover",pill_hover);pill.add_theme_stylebox_override("pressed",pill_hover);pill.add_theme_stylebox_override("focus",pill_style)
	pill.icon=Model.icon("story",32);pill.expand_icon=false;pill.add_theme_constant_override("icon_max_width",18)
	pill.tooltip_text="Everything you were told this session, newest first."
	pill.pressed.connect(toggle_log)
	pill.visible=false
	column.add_child(pill)
	get_viewport().size_changed.connect(func()->void:_signature="")
	if "--capture-notices" in OS.get_cmdline_user_args():_capture_replay()
	if "--capture-standing" in OS.get_cmdline_user_args():_capture_standing()


## Capture only ("--capture-notices", with "--resume-saved"): shows what the
## loaded save last told, as the stack would have shown it, and has the court
## bring word of the newest finished order (its new wording), so a capture of
## the player's own campaign shows several notices stacking.
func _capture_replay()->void:
	var told:Array=[]
	for e in Chronicle.entries("notice",40):
		if String((e as Dictionary).get("tier",""))=="notice":told.append(e)
		if told.size()>=2:break
	told.reverse()
	# And the newest line the stack would hold as urgent, if the save has one.
	for e in Chronicle.entries("whisper"):
		var urgent:=Model.from_chronicle(e,String(GameState.research_notification_mode))
		if String(urgent.get("tier",""))=="urgent":told.push_front(e);break
	for e in told:add(Model.from_chronicle(e,String(GameState.research_notification_mode)))
	var Lives:=preload("res://scripts/court_lives.gd")
	for order_variant in Lives.state().get("orders",[]):
		var order:Dictionary=(order_variant as Dictionary).duplicate(true)
		order["id"]=String(order.get("id",""))+"_capture"
		Lives._file_callback(order,int(GameState.elapsed_days))
		break
	_intake()
	_layout(0.0)
	if "--capture-notices-log" in OS.get_cmdline_user_args():toggle_log();_layout(0.0)


## Capture only ("--capture-standing"): sample conditions in the sources' own
## shapes (hud/army_alerts.gd, hud/trade_alerts.gd), so a capture of a quiet
## campaign shows how standing rows read. Never part of play.
func _capture_standing()->void:
	var samples:Array[Dictionary]=[
		{"id":"attack","war":"band","tone":"red","count":1,"title":"Coming at us","lines":PackedStringArray(["The Reedbank raiders toward the town · about 400 · here in 6 days"]),"page":"wars","fact":"The Reedbank raiders · ~400 · 6 days","days":6},
		{"id":"hungry","logistics":"hungry","tone":"red","count":2,"title":"Hungry in the field","lines":PackedStringArray(["First host · 40% fed","River guard · 55% fed"]),"page":"support"},
		{"id":"trade_against","war":"raid","tone":"red","count":1,"title":"Trade turned against us","lines":PackedStringArray(["The Saltmarsh folk sell us no copper"]),"page":"trade","dock":["economy",3]},
		{"id":"gear","glyph":"gear","tone":"amber","count":3,"title":"Short of gear","lines":PackedStringArray(["First host · 310 of 400 armed","River guard · 90 of 120 armed","Hill watch · 20 of 60 armed"]),"page":"support"},
	]
	_seeded.append({"key":"standing:envoy:sample","standing":true,"kind":"waiting","tone":"gold","category":"neighbours","title":"Envoy of the Saltmarsh folk","text":"Ilen Varo waits · leaves in 9 days","verb":"Answer","days":9,"count":1,"lines":PackedStringArray(["Ilen Varo waits · leaves in 9 days"]),"action":{"kind":"court","focus":{},"label":"the court"}})
	for alert in samples:_seeded.append(Standing.from_alert(alert))
	Model.push({"category":"food","tier":"notable","title":"The east wells are cleared","text":"Water for 300 more each day."})
	_sync_standing()
	_intake()
	_layout(0.0)


func _process(delta:float)->void:
	_intake()
	_standing_clock+=delta
	if _standing_clock>=STANDING_SECONDS:
		_standing_clock=0.0
		_sync_standing()
	_layout(delta)


## Reads what stands now and keeps one row for each: a row that is still true
## is updated where it stands, one that ended leaves.
func _sync_standing()->void:
	var next:Array[Dictionary]=_seeded.duplicate()
	if WorldSimulation.state!=null:next.append_array(Standing.rows())
	var words:=str(next.map(func(r:Dictionary)->Array:return [r.key,r.tone,r.title,r.text,r.count]))
	if words==_standing_signature:return
	_standing_signature=words
	var keep:Dictionary={}
	for row in next:keep[String(row.key)]=true
	for old in standing:
		if not keep.has(String(old.key)):_drop_view(String(old.key))
	standing=Standing.sorted(next)
	for row in standing:_render_standing(row)
	_refresh_pill()
	_signature=""


## Takes what the Chronicle told and what other systems pushed.
func _intake()->void:
	var mode:=String(GameState.research_notification_mode) if Engine.get_main_loop()!=null else "milestones"
	while not Chronicle.pending_notes.is_empty():
		var entry:Dictionary=Chronicle.pending_notes.pop_front()
		var n:=Model.from_chronicle(entry,mode)
		if not n.is_empty():add(n)
	while not Model.pending.is_empty():
		add(Model.pending.pop_front())


## Shows (or logs) one notice from the model.
func add(n:Dictionary)->void:
	Model.remember(n)
	_refresh_pill()
	var tier:=String(n.get("tier","notable"))
	# A repeat of something still showing (or waiting) counts on it.
	for list in [rows,waiting]:
		for shown in list:
			if Model.same(shown,n):
				Model.merge(shown,n)
				shown["left"]=Model.NOTABLE_SECONDS
				_render_row(shown)
				if String(shown.tier)=="urgent":_sort()
				return
	if tier in ["minor","card"]:return
	n["left"]=Model.NOTABLE_SECONDS
	waiting.append(n)
	_fill()
	_refresh_pill()


func _fill()->void:
	while not waiting.is_empty() and rows.size()<MAX_ROWS:
		var n:Dictionary=waiting.pop_front()
		rows.append(n)
		_render_row(n)
	# Urgent notices never queue behind routine ones: a notable gives way.
	while not waiting.is_empty() and waiting.any(func(w:Dictionary)->bool:return String(w.tier)=="urgent"):
		var victim:=-1
		for i in range(rows.size()-1,-1,-1):
			if String(rows[i].tier)!="urgent":victim=i;break
		if victim<0:break
		_drop(rows[victim],false)
		var index:=-1
		for i in waiting.size():
			if String(waiting[i].tier)=="urgent":index=i;break
		var urgent:Dictionary=waiting.pop_at(index)
		rows.append(urgent);_render_row(urgent)
	_sort()


func _sort()->void:
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ua:=String(a.tier)=="urgent";var ub:=String(b.tier)=="urgent"
		if ua!=ub:return ua
		return int(a.id)>int(b.id))
	_signature=""


func _drop(n:Dictionary,_remove:=true)->void:
	rows.erase(n)
	_drop_view(int(n.id))


func _drop_view(key:Variant)->void:
	var view:Variant=_views.get(key)
	_views.erase(key)
	if view is Control and is_instance_valid(view):
		var control:Control=view
		control.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if not control.is_inside_tree() or Motion.reduced():control.queue_free()
		else:
			var tween:=control.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_property(control,"modulate:a",0.0,Motion.duration(Motion.BASE))
			tween.tween_callback(control.queue_free)
	_signature=""


func dismiss(n:Dictionary)->void:
	_drop(n)
	_fill()
	_refresh_pill()


## ONE ROW STYLE for everything in the column: a glyph, a headline with its
## count, one fact line, and at the right either the one word of what to do
## about it (a row that stands) or the × that sets news aside. A count is
## said in the fact line ("· +1 more"), never as a bare number. Two lines,
## the same height; the pointer has the rest.
func _render_row(n:Dictionary)->void:
	var view:Variant=_views.get(int(n.id))
	var row:PanelContainer
	if view is PanelContainer and is_instance_valid(view):
		row=view
	else:
		row=_build_row(n,"Notice%d" % int(n.id))
		_views[int(n.id)]=row
		column.add_child(row)
		row.modulate.a=0.0
		if "--capture-notices" in OS.get_cmdline_user_args() or "--capture-standing" in OS.get_cmdline_user_args():row.modulate.a=1.0
		var tween:=row.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(row,"modulate:a",1.0,Motion.duration(Motion.BASE))
	row.set_meta("notice",n)
	var category:=String(n.get("category","story"))
	var urgent:=String(n.get("tier",""))=="urgent"
	row.add_theme_stylebox_override("panel",_row_style(Model.color(category),urgent))
	(row.get_meta("icon") as TextureRect).texture=Model.icon(category,48)
	var fact:=String(n.get("text",""))
	if Model.count_words(n)!="":fact=(fact+" · " if fact!="" else "")+Model.count_words(n)
	_fill_row(row,Model.headline(n),fact,Model.color(category),"")
	row.tooltip_text=_tooltip(n)
	_signature=""


## Builds or refreshes a row that stands (hud/standing_notices.gd).
func _render_standing(n:Dictionary)->void:
	var key:=String(n.key)
	var view:Variant=_views.get(key)
	var row:PanelContainer
	if view is PanelContainer and is_instance_valid(view):row=view
	else:
		row=_build_row(n,"Standing_%s" % key.trim_prefix("standing:").replace(":","_"))
		_views[key]=row
		column.add_child(row)
	row.set_meta("notice",n)
	var tone:=Standing.tone_color(String(n.get("tone","amber")))
	row.add_theme_stylebox_override("panel",_row_style(tone,String(n.get("kind",""))=="waiting"))
	(row.get_meta("icon") as TextureRect).texture=Standing.icon(n)
	_fill_row(row,String(n.get("title","")),String(n.get("text","")),tone,String(n.get("verb","See")))
	row.tooltip_text=Standing.tip(n)


## Writes a row's words; `verb` is the button's word ("" for news, which has the ×).
func _fill_row(row:PanelContainer,headline:String,fact:String,tone:Color,verb:String)->void:
	(row.get_meta("title") as Label).text=headline
	var detail:=row.get_meta("detail") as Label
	detail.text=fact
	var act_button:=row.get_meta("verb") as Button
	act_button.visible=verb!=""
	act_button.text=verb
	T.apply_button_style(act_button,false)
	(row.get_meta("close") as Button).visible=verb==""


func _tooltip(n:Dictionary)->String:
	var action:Dictionary=n.get("action",{}) if n.get("action") is Dictionary else {}
	var head:PackedStringArray=[Model.label(String(n.get("category","story"))),Model.date_words(int(n.get("day",0)))]
	if Model.count_words(n)!="":head.append(Model.count_words(n))
	return "%s\n%s\n%s\nClick: %s.  × sets it aside; the log keeps it." % [" · ".join(head),Model.headline(n),String(n.get("text","")),action_words(action)]


static func action_words(action:Dictionary)->String:
	match String(action.get("kind","")):
		"court":
			var focus:Dictionary=action.get("focus",{}) if action.get("focus") is Dictionary else {}
			return "summon them in the court" if focus.has("person_id") else "open the court"
		"prisoner":return "have them brought before you"
		"scout_report":return "read the scouts' report"
		"battle":return "read the battle report"
		"ceremony":return "attend the dedication"
		"map":return "show the place on the map"
		"section":return "open %s" % String(action.get("label","the page it is about"))
		"call":return String(action.get("label","open it"))
	return "open the Chronicle"


## A row's paper: its tone on the left edge; one that needs the god now has
## a gold rule all round and a warm wash.
func _row_style(tone:Color,lit:bool)->StyleBoxFlat:
	var style:=T.paper_panel_style(true,T.RADIUS_CARD)
	style.content_margin_left=10;style.content_margin_right=8;style.content_margin_top=6;style.content_margin_bottom=6
	style.border_width_left=5;style.border_color=tone
	style.shadow_color=Color(0.12,0.09,0.05,0.18);style.shadow_size=6;style.shadow_offset=Vector2(0,2)
	if lit:
		style.border_color=T.GOLD;style.set_border_width_all(2);style.border_width_left=5
		style.bg_color=T.PAPER_RAISED.lerp(Color(T.GOLD,1.0),0.10)
	return style


func _build_row(n:Dictionary,row_name:String)->PanelContainer:
	var row:=PanelContainer.new();row.name=row_name
	row.mouse_filter=Control.MOUSE_FILTER_STOP;row.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	row.custom_minimum_size=Vector2(WIDTH,ROW_HEIGHT)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(line)
	var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(28,28);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(icon)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",-1);copy.alignment=BoxContainer.ALIGNMENT_CENTER;copy.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(copy)
	var title:=_label(copy,16,T.INK,false);title.add_theme_font_override("font",T.font("ui_strong"));title.add_theme_font_size_override("font_size",18)
	title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var detail:=_label(copy,13,T.BODY,false);detail.clip_text=true;detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var verb:=Button.new();verb.name="Verb";verb.focus_mode=Control.FOCUS_ALL;verb.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	verb.add_theme_font_override("font",T.font("ui_strong"));verb.add_theme_font_size_override("font_size",14)
	for state:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:verb.add_theme_color_override(state,Color("fbf6ea"))
	T.apply_button_style(verb,false)
	verb.pressed.connect(func()->void:_press(row))
	line.add_child(verb)
	var close:=Button.new();close.name="Close";close.text="×";close.flat=true;close.focus_mode=Control.FOCUS_ALL;close.custom_minimum_size=Vector2(24,24)
	close.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	close.add_theme_font_override("font",T.FONT_UI);close.add_theme_font_size_override("font_size",17)
	close.add_theme_color_override("font_color",T.INK_MUTED);close.add_theme_color_override("font_hover_color",T.INK)
	close.tooltip_text="Set this aside. The log keeps it."
	close.pressed.connect(func()->void:dismiss(row.get_meta("notice")))
	line.add_child(close)
	row.set_meta("icon",icon);row.set_meta("title",title);row.set_meta("detail",detail);row.set_meta("verb",verb);row.set_meta("close",close)
	row.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			row.accept_event()
			_press(row))
	return row


## A click on a row or its button: a row that stands opens its screen and
## stays; news opens what it is about and is set aside.
func _press(row:PanelContainer)->void:
	var n:Dictionary=row.get_meta("notice")
	if bool(n.get("standing",false)):act(n.get("action",{}) if n.get("action") is Dictionary else {})
	else:open(n)


func _label(parent:Node,font_size:int,color:Color,wrap:bool)->Label:
	var label:=Label.new();label.add_theme_font_override("font",T.FONT_UI)
	label.add_theme_font_size_override("font_size",maxi(14,font_size));label.add_theme_color_override("font_color",color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label);return label


## Opens what the notice is about, and sets it aside.
func open(n:Dictionary)->void:
	act(n.get("action",{}) if n.get("action") is Dictionary else {})
	if rows.has(n):dismiss(n)


func act(action:Dictionary)->void:
	match String(action.get("kind","")):
		"ceremony":
			var director:Node=get_tree().get_first_node_in_group("court_director")
			if director and director.has_method("open_ceremony"):director.call("open_ceremony",String(action.get("work_id","")))
		"court":
			var focus:Dictionary=action.get("focus",{}) if action.get("focus") is Dictionary else {}
			if not preload("res://scripts/audience_director.gd").open_court_for(focus) and is_instance_valid(hud) and hud.has_method("open_court"):hud.call("open_court")
		"war":
			MilitaryCampaign.open_roster("army",false,String(action.get("page","forces")))
		"prisoner":
			preload("res://scripts/audience_director.gd").open_court_for({"prisoner_id":String(action.get("prisoner_id",""))})
		"scout_report":
			var card:=preload("res://scripts/hud/chronicle_card.gd").ensure(terrain,hud)
			card.open_scout_report(int(action.get("mission_id",0)))
		"battle":
			preload("res://scripts/hud/battle_report_panel.gd").open(terrain if is_instance_valid(terrain) else get_tree().current_scene,int(action.get("seed",0)))
		"section":
			if is_instance_valid(hud) and hud.has_signal("section_requested"):hud.emit_signal("section_requested",String(action.get("section","chronicle")),int(action.get("sub",0)))
		"map":
			if is_instance_valid(terrain) and terrain.has_method("_set_camera_target"):
				terrain.call("_set_camera_target",Vector3(float(action.get("x",0.0)),0.0,float(action.get("z",0.0))))
		"call":
			var callable:Variant=action.get("callable")
			if callable is Callable and (callable as Callable).is_valid():(callable as Callable).call()
		_:
			if is_instance_valid(hud) and hud.has_signal("section_requested"):hud.emit_signal("section_requested","chronicle",0)


# --- Layout and clocks ----------------------------------------------------------

func _layout(delta:float)->void:
	var view:=get_viewport().get_visible_rect().size
	var right:=view.x-RIGHT
	var y:=TOP
	var width:=minf(WIDTH,view.x-T.RAIL_WIDTH-32.0)
	var blocked:=_blocked_rects(view)
	# The log button: at the top of the column, under the status strip.
	pill.visible=not Model.history.is_empty() or not standing.is_empty()
	if pill.visible:
		pill.reset_size()
		pill.position=Vector2(roundf(right-pill.size.x),y)
		var pill_rect:=Rect2(pill.position,pill.size)
		pill.visible=not blocked.any(func(r:Rect2)->bool:return r.intersects(pill_rect))
		if pill.visible:y+=PILL_HEIGHT+GAP
	if is_instance_valid(log_panel) and log_panel.visible:
		log_panel.size=log_panel.get_combined_minimum_size()
		log_panel.position=Vector2(roundf(right-log_panel.size.x),y)
		log_panel.visible=pill.visible
	# Below the Chronicle's moment card while it shows.
	var card:Variant=hud.get_meta("chronicle_card") if is_instance_valid(hud) and hud.has_meta("chronicle_card") else null
	if is_instance_valid(card) and "panel" in card and is_instance_valid(card.panel):
		if card.has_method("set_top"):card.set_top(y)
		if bool(card.showing) and not bool(card.held) and (card.panel as Control).visible:
			y=(card.panel as Control).position.y+(card.panel as Control).size.y+GAP
	var bottom:=view.y-12.0
	if is_instance_valid(hud) and hud.has_method("right_stack_top"):bottom=minf(bottom,float(hud.right_stack_top())-GAP)
	var x:=right-width
	var column_rect:=Rect2(x,y,width,maxf(0.0,bottom-y))
	held=blocked.any(func(r:Rect2)->bool:return r.intersects(column_rect))
	var hovered_any:=false
	var log_open:=is_instance_valid(log_panel) and log_panel.visible
	for n in _ordered():
		var is_standing:=bool(n.get("standing",false))
		var view_node:Variant=_views.get(String(n.key) if is_standing else int(n.id))
		if not view_node is Control or not is_instance_valid(view_node):continue
		var row:Control=view_node
		row.custom_minimum_size.x=width;row.size.x=width
		row.size.y=maxf(ROW_HEIGHT,row.get_combined_minimum_size().y)
		var fits:=not held and not log_open and y+row.size.y<=bottom
		row.visible=fits
		if fits:
			row.position=Vector2(roundf(x),roundf(y))
			y+=row.size.y+GAP
			var hovered:=row.get_global_rect().has_point(row.get_global_mouse_position())
			hovered_any=hovered_any or hovered
			# A notable notice's clock runs only while it is seen and not pointed at.
			if not is_standing and String(n.tier)!="urgent" and not hovered:
				n["left"]=float(n.get("left",Model.NOTABLE_SECONDS))-delta
				if float(n.left)<=0.0:dismiss(n)


## The column from the top: what needs the god (threats first, then by days
## left: standing_notices.gd sorted), urgent news, what only wants seeing
## to, then the day's news.
func _ordered()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for n in standing:
		if Standing.urgent(n):out.append(n)
	for n in rows:
		if String(n.tier)=="urgent":out.append(n)
	for n in standing:
		if not Standing.urgent(n):out.append(n)
	for n in rows:
		if String(n.tier)!="urgent":out.append(n)
	return out


## Everything in the column that needs the god: every row that stands (each
## has its button). The header's count is their number and each rail
## button's badge is its own share of them (the HUD's set_notice_counts),
## so header = rows with a button = the sum of the rail's badges.
func needing()->Array[Dictionary]:
	return standing.duplicate()


func _blocked_rects(view:Vector2)->Array[Rect2]:
	var out:Array[Rect2]=[]
	if not is_instance_valid(hud):return out
	for sheet_name in ["dock","detail_dock"]:
		var sheet:Variant=hud.get(sheet_name) if sheet_name in hud else null
		if sheet is Control and (sheet as Control).is_visible_in_tree():out.append((sheet as Control).get_global_rect())
	# The War screen is the page for what is wrong with the fighters (its
	# column's own bars say it), and its map must stay clear: the notices wait.
	if hud.has_method("war_open") and bool(hud.call("war_open")) and hud.has_method("_war_layout"):
		var column_width:=float(hud.call("_war_layout","COLUMN_WIDTH"))
		out.append(Rect2(view.x-T.EDGE_MARGIN-column_width,56.0,column_width,view.y))
	return out


func _refresh_pill()->void:
	var need:=needing()
	var urgent:=need.size()
	var counts:Dictionary={}
	for n in need:
		var rail:=Standing.rail_of(n)
		if rail!="":counts[rail]=int(counts.get(rail,0))+1
	if str(counts)!=_needing:
		_needing=str(counts)
		if is_instance_valid(hud) and hud.has_method("set_notice_counts"):hud.call("set_notice_counts",counts)
	pill.text=("Notices · %d" % Model.history.size() if not Model.history.is_empty() else "Notices") if urgent==0 else "Notices · %d need%s you" % [urgent,"s" if urgent==1 else ""]
	if is_instance_valid(log_panel) and log_panel.visible:_fill_log()


# --- The log ------------------------------------------------------------------

func toggle_log()->void:
	if not is_instance_valid(log_panel):_build_log()
	log_panel.visible=not log_panel.visible
	if log_panel.visible:_fill_log()
	_signature=""


func _build_log()->void:
	log_panel=PanelContainer.new();log_panel.name="NoticeLogPanel";log_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=T.paper_panel_style(true,T.RADIUS_CARD,12.0);style.border_color=T.GOLD
	style.shadow_color=Color(0.12,0.09,0.05,0.22);style.shadow_size=10;style.shadow_offset=Vector2(0,3)
	log_panel.add_theme_stylebox_override("panel",style)
	log_panel.custom_minimum_size=Vector2(WIDTH+40.0,0)
	column.add_child(log_panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);log_panel.add_child(box)
	var head:=HBoxContainer.new();box.add_child(head)
	var title:=_label(head,24,T.INK,false);title.text="What you were told";title.add_theme_font_override("font",T.font("ui_strong"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var close:=Button.new();close.text="×";close.flat=true;close.focus_mode=Control.FOCUS_ALL;close.custom_minimum_size=Vector2(40,40)
	close.add_theme_font_size_override("font_size",17);close.add_theme_color_override("font_color",T.INK_MUTED)
	close.pressed.connect(toggle_log);head.add_child(close)
	var hint:=_label(box,12,T.TEXT_SOFT,true);hint.text="This session, newest first. Quieter news is kept here without popping up. Click a line to open it."
	var scroll:=ScrollContainer.new();scroll.follow_focus=true;scroll.custom_minimum_size=Vector2(0,320);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;box.add_child(scroll)
	log_list=VBoxContainer.new();log_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;log_list.add_theme_constant_override("separation",2);scroll.add_child(log_list)
	var whole:=Button.new();whole.text="Open the whole Chronicle";whole.focus_mode=Control.FOCUS_ALL
	whole.add_theme_font_override("font",T.FONT_UI);whole.add_theme_font_size_override("font_size",14)
	T.apply_button_style(whole,true);whole.add_theme_stylebox_override("hover",T.action_button_style(true,true))
	whole.pressed.connect(func()->void:
		toggle_log()
		act({}))
	box.add_child(whole)
	log_panel.visible=false


func _fill_log()->void:
	if not is_instance_valid(log_list):return
	for child in log_list.get_children():child.queue_free()
	# Never down over the toolbar or your orders at the bottom right.
	var bottom:=get_viewport().get_visible_rect().size.y-12.0
	if is_instance_valid(hud) and hud.has_method("right_stack_top"):bottom=minf(bottom,float(hud.right_stack_top())-GAP)
	var room:=clampf(bottom-TOP-PILL_HEIGHT-GAP-150.0,80.0,420.0)
	(log_list.get_parent() as Control).custom_minimum_size.y=minf(room,maxf(64.0,float(mini(Model.history.size(),LOG_ROWS))*50.0))
	for n in Model.history.slice(0,LOG_ROWS):
		var line:=Button.new();line.flat=false;line.focus_mode=Control.FOCUS_ALL;line.alignment=HORIZONTAL_ALIGNMENT_LEFT
		line.clip_text=true;line.custom_minimum_size=Vector2(0,48)
		line.text="%s · %s\n%s" % [Model.label(String(n.category)),Model.date_words(int(n.get("day",0))),Model.headline(n)+("  (%s)" % Model.count_words(n) if Model.count_words(n)!="" else "")]
		line.tooltip_text="%s\n%s" % [Model.headline(n),String(n.get("text",""))]
		line.icon=Model.icon(String(n.category),40);line.add_theme_constant_override("icon_max_width",22)
		line.add_theme_font_override("font",T.FONT_UI);line.add_theme_font_size_override("font_size",14)
		line.add_theme_color_override("font_color",T.INK);line.add_theme_color_override("font_hover_color",T.INK)
		var normal:=T.flat(Color(0,0,0,0));normal.content_margin_left=6;normal.content_margin_right=6
		normal.border_width_left=3;normal.border_color=Model.color(String(n.category))
		var hover:=normal.duplicate() as StyleBoxFlat;hover.bg_color=T.HOVER_BG
		line.add_theme_stylebox_override("normal",normal);line.add_theme_stylebox_override("hover",hover);line.add_theme_stylebox_override("pressed",hover);line.add_theme_stylebox_override("focus",T.gold_outline_style())
		var action:Dictionary=n.get("action",{}) if n.get("action") is Dictionary else {}
		line.pressed.connect(func()->void:
			toggle_log()
			act(action))
		log_list.add_child(line)


## For tests: the notices on screen, in order.
func shown()->Array[Dictionary]:
	return rows.duplicate()


## For tests: the whole column from the top, standing rows included.
func column_rows()->Array[Dictionary]:
	return _ordered()
