extends VBoxContainer
## IMPACT LEDGER: what research does, one effect to a row. A closed row gives
## the effect's name, its size and what it moves now; a click opens the plain
## account and every place the engine reads it (scripts/effect_explainer.gd
## builds the rows). Groups fold rows by field. Rows, groups and details are
## built only when opened, so hundreds of them stay light, and which ones are
## open lives in the page's `state` dictionary, so a rebuilt page keeps them.
##
## Block: {"type":"impact", "state":Dictionary, "intro":String,
##   "rows":[row...] or "groups":[{"id","title","summary","count","accent","rows"}],
##   "empty":String}. Row: EffectExplainer.ledger_row().

const T:=preload("res://scripts/hud/hud_tokens.gd")

var data:Dictionary={}
## Open rows and groups ("r:<id>", "g:<id>" -> true), shared with the page.
var state:Dictionary={}
var _print:=""

func setup(block:Dictionary)->void:
	name="ImpactLedger"
	add_theme_constant_override("separation",4)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_apply(block)

## New data in place (DockPanel keeps the widget): unchanged rows keep their
## nodes and open details; changed ones are drawn again with the same state.
func update_block(block:Dictionary)->bool:
	var next:=fingerprint(block)
	state=block.get("state",state)
	if next==_print: return true
	for child in get_children():
		remove_child(child);child.queue_free()
	_apply(block)
	return true

static func fingerprint(block:Dictionary)->String:
	return str(hash([block.get("intro",""),block.get("rows",[]),block.get("groups",[]),block.get("empty","")]))

func _apply(block:Dictionary)->void:
	data=block
	state=block.get("state",state)
	_print=fingerprint(block)
	if String(block.get("intro",""))!="": _text(self,String(block.intro),12,T.TEXT_SOFT)
	var groups:Array=block.get("groups",[])
	var rows:Array=block.get("rows",[])
	if groups.is_empty() and rows.is_empty():
		if String(block.get("empty",""))!="": _text(self,String(block.empty),12,T.MUTED)
		return
	for group:Dictionary in groups: _group(group)
	for row:Dictionary in rows: _row(self,row)

# --- groups -------------------------------------------------------------------

func _group(group:Dictionary)->void:
	var key:="g:"+String(group.get("id",""))
	var accent:Color=group.get("accent",T.GOLD)
	var holder:=VBoxContainer.new();holder.add_theme_constant_override("separation",4);add_child(holder)
	var header:=PanelContainer.new();header.name="Group_"+String(group.get("id","")).validate_node_name()
	header.add_theme_stylebox_override("panel",T.tile_style(accent));holder.add_child(header)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);header.add_child(line)
	var chevron:=T.make_label("▾" if state.has(key) else "▸",13,T.GOLD_TEXT);chevron.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;line.add_child(chevron)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",1);line.add_child(words)
	var title:=T.make_label(String(group.get("title","")),15,T.INK);title.add_theme_font_override("font",T.voice_font());words.add_child(title)
	if String(group.get("summary",""))!="": _text(words,String(group.summary),12,T.TEXT_SOFT)
	if String(group.get("count",""))!="":
		var count:=T.make_label(String(group.count),12,T.MUTED);count.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;line.add_child(count)
	var body:=VBoxContainer.new();body.name="GroupRows";body.add_theme_constant_override("separation",4)
	var indent:=MarginContainer.new();indent.add_theme_constant_override("margin_left",12);indent.add_child(body);holder.add_child(indent)
	indent.visible=state.has(key)
	if indent.visible:
		for row:Dictionary in group.get("rows",[]): _row(body,row)
	_clickable(header,func()->void:
		if state.has(key): state.erase(key)
		else: state[key]=true
		indent.visible=state.has(key)
		chevron.text="▾" if indent.visible else "▸"
		if indent.visible and body.get_child_count()==0:
			for row:Dictionary in group.get("rows",[]): _row(body,row))
	header.tooltip_text="Click to %s this group." % ("close" if state.has(key) else "open")

# --- rows ---------------------------------------------------------------------

## The ink for a row's amount: gains green, costs amber, inert or neutral muted.
static func tone_ink(tone:String)->Color:
	match tone:
		"good": return T.GREEN_TEXT
		"cost": return T.AMBER_TEXT
		"neutral": return T.BODY
	return T.MUTED

static func tone_accent(tone:String)->Color:
	match tone:
		"good": return T.GREEN
		"cost": return T.AMBER
		"neutral": return T.BORDER
	return T.BORDER_SOFT

func _row(parent:Node,row:Dictionary)->void:
	var key:="r:"+String(row.get("id",row.get("key","")))
	var panel:=PanelContainer.new();panel.name="Effect_"+String(row.get("id","")).validate_node_name()
	panel.add_theme_stylebox_override("panel",T.row_style(tone_accent(String(row.get("tone","")))))
	parent.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",2);panel.add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",8);column.add_child(top)
	var chevron:=T.make_label("▾" if state.has(key) else "▸",12,T.MUTED);top.add_child(chevron)
	var name_label:=T.make_label(String(row.get("label","")),13,T.INK);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;top.add_child(name_label)
	var amount:=T.make_label(String(row.get("amount","")),13,tone_ink(String(row.get("tone",""))));amount.name="Amount";top.add_child(amount)
	if String(row.get("usage",""))!="":
		var usage:=_text(column,String(row.usage),12,T.MUTED);usage.name="Usage"
	var headline:=_text(column,String(row.get("headline","")),12,T.TEXT_SOFT);headline.name="Headline"
	var detail:=VBoxContainer.new();detail.name="Detail";detail.add_theme_constant_override("separation",3);column.add_child(detail)
	detail.visible=state.has(key)
	if detail.visible: _detail(detail,row)
	_clickable(panel,func()->void:
		if state.has(key): state.erase(key)
		else: state[key]=true
		detail.visible=state.has(key)
		chevron.text="▾" if detail.visible else "▸"
		if detail.visible and detail.get_child_count()==0: _detail(detail,row))
	panel.tooltip_text=String(row.get("sentence",""))+"\n\nClick to see everywhere it acts."

## The full account: what it is, which way is better, every place it acts, and
## why it may add nothing (held back by the age, or read by nothing yet).
func _detail(box:VBoxContainer,row:Dictionary)->void:
	var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size.y=1;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(rule)
	_text(box,String(row.get("sentence","")),12,T.BODY)
	if String(row.get("direction",""))!="": _text(box,String(row.direction),12,T.MUTED)
	var feeds:Array=row.get("feeds",[])
	if bool(row.get("inert",false)):
		_text(box,"No effect in the simulation yet: nothing in the engine reads it, so it changes nothing however much of it the people know.",12,T.AMBER_TEXT)
	elif not feeds.is_empty():
		box.add_child(T.make_label("Where it acts",12,T.GOLD_TEXT,0.04))
		for feed:Variant in feeds: _text(box,"·  "+String(feed),12,T.TEXT_SOFT)
	for note:Variant in row.get("notes",[]): _text(box,String(note),12,T.AMBER_TEXT if String(note).begins_with("Held back") else T.MUTED)
	for child:Node in box.find_children("*","Control",true,false): (child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE

# --- helpers --------------------------------------------------------------------

func _text(parent:Node,value:String,size:int,ink:Color)->Label:
	var label:=T.make_label(value,size,ink)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x=80
	parent.add_child(label)
	return label

## The whole panel is one hit target (mouse and keyboard), lit under the pointer.
func _clickable(panel:PanelContainer,action:Callable)->void:
	for child:Node in panel.find_children("*","Control",true,false): (child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	panel.focus_mode=Control.FOCUS_ALL
	panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var rest:StyleBox=panel.get_theme_stylebox("panel")
	var lit:StyleBox=rest.duplicate()
	if lit is StyleBoxFlat: (lit as StyleBoxFlat).bg_color=T.HOVER_BG
	panel.mouse_entered.connect(func()->void: panel.add_theme_stylebox_override("panel",lit))
	panel.mouse_exited.connect(func()->void: panel.add_theme_stylebox_override("panel",rest))
	panel.gui_input.connect(func(event:InputEvent)->void:
		var mouse:=event as InputEventMouseButton
		if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
			panel.accept_event();action.call()
		elif event.is_action_pressed("ui_accept"):
			panel.accept_event();action.call())
