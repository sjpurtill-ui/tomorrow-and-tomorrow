extends VBoxContainer
## PEOPLES WE KNOW, drawn: one ranked ledger of every people we have met, our
## own row among them, at the head of the Known World (the rows are made by
## hud/peoples_known_model.gd). Paper and ink. Every foreign figure is a range
## as we know it, with how old our word is (a mark: recent, aging, stale) and
## who brought it; under the headline figures, each people's rank, or "about
## level" where what we know cannot tell two peoples apart.
##
## A column's title sorts by it (again: the other way round). A row opens the
## towns we know of theirs; a town opens its report. Clicks inform; nothing
## here gives an order.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Model:=preload("res://scripts/hud/peoples_known_model.gd")

## Column widths (px). The name takes what is left, at least NAME_MIN.
const WIDTHS:={"towns":44,"people":72,"fighters":66,"stores":68,"crafts":60,"lore":56,"lives":74,"wealth":64,"walls":60,"between":88,"envoys":70}
const NAME_MIN:=118
const GAP:=3
## The sheet's paper margin, each side (px).
const PAD:=14
## On a narrow page these columns give way, first to last.
const SHED:=["crafts","walls","lore","lives","wealth","towns","envoys"]
## Figures right-aligned, as a ledger keeps them.
const FIGURES:=["towns","people","fighters","stores","crafts","lore","lives","wealth","walls"]
## The opened row's town table: [part, title, width].
const TOWN_COLUMNS:=[["people","How many",72],["fighters","Fighters",66],["stores","Stores",68],["walls","Walls",60]]

var model:Dictionary={}
## The page's own view, kept by the World page across its daily rebuilds:
## {sort: column, flip: the other way round, open: the people whose towns show}.
var view:Dictionary={}
var on_town:Callable
## Each column's nodes, to let them give way on a narrow page.
var parts:Dictionary={}
## The columns giving way at this width.
var _shape:Array=[]

func setup(block:Dictionary)->void:
	name="PeoplesKnownBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",0)
	_take(block)
	_build()
	resized.connect(_layout)

## The day's ledger, drawn in place (the World page's live refresh).
func update_block(block:Dictionary)->bool:
	_take(block)
	_build()
	return true

func _take(block:Dictionary)->void:
	model=block.get("model",{})
	var given:Variant=block.get("view")
	view=given if given is Dictionary else {}
	if not view.has("sort"):view["sort"]="people"
	if not view.has("flip"):view["flip"]=false
	if not view.has("open"):view["open"]=""
	on_town=block.get("on_town",Callable())

## Sorts by a column; the same column again sorts the other way round.
func sort_by(column:String)->void:
	if String(view.sort)==column:view["flip"]=not bool(view.flip)
	else:
		view["sort"]=column
		view["flip"]=false
	_build()

## Opens a people's towns, or closes them.
func toggle(civ_id:String)->void:
	view["open"]="" if String(view.open)==civ_id else civ_id
	_build()

func _titles()->Dictionary:
	return Model.titles(String(model.get("stage","hearth")))

func _build()->void:
	for child in get_children():
		remove_child(child);child.queue_free()
	parts.clear()
	# The page's width rules the ledger, not the other way round: this holder
	# does not pass the columns' width up, so the board takes the dock's width
	# and _layout lets columns give way to fit it (it scrolls sideways only if
	# even the fewest do not fit).
	var fit:=ScrollContainer.new();fit.name="Fit"
	fit.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;fit.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	fit.add_theme_stylebox_override("panel",StyleBoxEmpty.new());add_child(fit)
	var sheet:=PanelContainer.new();sheet.name="PeoplesSheet";sheet.add_theme_stylebox_override("panel",sheet_style())
	sheet.size_flags_horizontal=Control.SIZE_EXPAND_FILL;fit.add_child(sheet)
	var stack:=VBoxContainer.new();stack.name="Ledger";stack.add_theme_constant_override("separation",6);sheet.add_child(stack)
	stack.add_child(_heading())
	stack.add_child(_header_row())
	stack.add_child(_rule(T.RULE_STRONG))
	var rows:=VBoxContainer.new();rows.name="Rows";rows.add_theme_constant_override("separation",0);stack.add_child(rows)
	for row:Dictionary in Model.order(model.get("rows",[]),String(view.sort),bool(view.flip)):
		rows.add_child(_row(row))
		if String(view.open)==String(row.civ_id):rows.add_child(_towns(row))
		rows.add_child(_rule(T.RULE))
	var unplaced:Array=model.get("unplaced",[])
	if not unplaced.is_empty():
		var names:=PackedStringArray()
		for town:Dictionary in unplaced:names.append(String(town.name))
		var note:=_label("%d town%s seen whose people we do not know" % [unplaced.size(),"" if unplaced.size()==1 else "s"],12,T.INK_MUTED)
		note.name="Unplaced";note.tooltip_text=", ".join(names)+". Closer looks would tell whose they are."
		stack.add_child(note)
	_apply_shape()

# --- The heading and the column titles -------------------------------------

func _heading()->Control:
	var row:=HBoxContainer.new();row.name="Heading";row.add_theme_constant_override("separation",8)
	var title:=T.make_label("Peoples we know",12,T.GOLD_TEXT,0.06);title.name="Title";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(title)
	var sorted:=String(_titles().get(String(view.sort),"")).to_lower()
	var note:=_label("as we know it · by %s" % sorted,12,T.INK_MUTED);note.name="Sorted"
	note.add_theme_font_override("font",T.voice_font(true));note.add_theme_font_size_override("font_size",13)
	note.tooltip_text="Our estimates of them, from what came home; older word is less sure. Our own row is our own count."
	row.add_child(note)
	return row

func _header_row()->Control:
	var row:=HBoxContainer.new();row.name="Header";row.add_theme_constant_override("separation",GAP)
	var titles:=_titles()
	for column:Dictionary in Model.COLUMNS:
		var id:=String(column.id)
		var active:=String(view.sort)==id
		var button:=Button.new();button.name="Sort_"+id;button.focus_mode=Control.FOCUS_NONE
		button.text=String(titles.get(id,id))+((" ↑" if bool(view.flip) else " ↓") if active else "")
		button.clip_text=true;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.alignment=HORIZONTAL_ALIGNMENT_RIGHT if id in FIGURES else HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text="%s Click to sort by it." % String(Model.MEANINGS.get(id,""))
		button.add_theme_font_override("font",T.font("ui_strong"));button.add_theme_font_size_override("font_size",12)
		button.add_theme_color_override("font_color",T.INK if active else T.INK_MUTED)
		button.add_theme_color_override("font_hover_color",T.INK);button.add_theme_color_override("font_pressed_color",T.INK)
		for state:String in ["normal","pressed","disabled"]:button.add_theme_stylebox_override(state,_cell_style(Color(0,0,0,0)))
		button.add_theme_stylebox_override("hover",_cell_style(T.HOVER_BG))
		button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		if id=="name":
			button.custom_minimum_size.x=NAME_MIN;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		else:button.custom_minimum_size.x=float(WIDTHS.get(id,60))
		button.pressed.connect(sort_by.bind(id))
		row.add_child(button);_part(id,button)
	return row

static func _cell_style(bg:Color)->StyleBoxFlat:
	var style:=T.flat(bg,Color(0,0,0,0),0,2)
	style.content_margin_left=2;style.content_margin_right=2;style.content_margin_top=3;style.content_margin_bottom=3
	return style

# --- One people's row ------------------------------------------------------

func _row(row:Dictionary)->Control:
	var civ_id:=String(row.civ_id)
	var us:=bool(row.us)
	var open:=String(view.open)==civ_id
	var panel:=PanelContainer.new();panel.name="People_"+civ_id.validate_node_name()
	panel.add_theme_stylebox_override("panel",_row_style(us,open,false))
	panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	panel.tooltip_text=("Hide %s." if open else "Show %s.") % ("our towns" if us else "the towns we know of theirs")
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",_row_style(us,open,true)))
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",_row_style(us,open,false)))
	panel.gui_input.connect(func(event:InputEvent)->void:
		if _clicked(event):
			panel.accept_event()
			toggle(civ_id))
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",GAP);panel.add_child(line)
	line.add_child(_name_cell(row))
	for id:String in FIGURES:line.add_child(_figure_cell(row,id))
	line.add_child(_between_cell(row))
	line.add_child(_envoys_cell(row))
	return panel

static func _clicked(event:InputEvent)->bool:
	var click:=event as InputEventMouseButton
	return click!=null and click.pressed and click.button_index==MOUSE_BUTTON_LEFT

func _row_style(us:bool,open:bool,hover:bool)->StyleBoxFlat:
	# An opened row sits on the same sunk paper as the towns under it.
	var bg:=T.GOLD_WASH if us else (T.PAPER_SUNK if open else (T.HOVER_BG if hover else Color(0,0,0,0)))
	var style:=T.flat(bg,Color(0,0,0,0),0,3)
	style.content_margin_left=4;style.content_margin_right=4;style.content_margin_top=6;style.content_margin_bottom=6
	if us:
		style.border_color=T.GOLD;style.border_width_left=2
	return style

## The people's name; under it how old our newest word of them is (with its
## mark) and who brought it.
func _name_cell(row:Dictionary)->Control:
	var cell:=VBoxContainer.new();cell.name="Cell_name";cell.add_theme_constant_override("separation",0)
	cell.custom_minimum_size.x=NAME_MIN;cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);cell.add_child(top)
	var name_label:=_label(String(row.name),14,T.INK,true);name_label.name="Name"
	name_label.clip_text=true;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	name_label.tooltip_text=String(row.name)+("" if (row.get("contact",[]) as Array).is_empty() else ". "+_contact_line(row))
	top.add_child(name_label)
	if bool(row.us):top.add_child(_tag("us"))
	var fresh:Dictionary=row.get("fresh",{})
	var when:=HBoxContainer.new();when.name="Fresh";when.add_theme_constant_override("separation",4);cell.add_child(when)
	var mark:=FreshMark.new();mark.name="Mark";mark.level=String(fresh.get("level","none"));mark.tooltip_text=String(fresh.get("tip",""));when.add_child(mark)
	var age:=_label(String(fresh.get("text","")),12,T.INK_MUTED);age.name="Age";age.tooltip_text=String(fresh.get("tip",""))
	age.clip_text=true;age.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;age.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	when.add_child(age)
	if String(fresh.get("source",""))!="":
		var source:=_label(String(fresh.source),12,T.INK_MUTED);source.name="Source";source.tooltip_text="Who brought our newest word of them."
		cell.add_child(source)
	_part("name",cell)
	return cell

static func _contact_line(row:Dictionary)->String:
	var said:=" · ".join(PackedStringArray(row.get("contact",[])))
	return said.substr(0,1).to_upper()+said.substr(1)+"."

func _tag(text:String)->Control:
	var pill:=PanelContainer.new();pill.name="Tag"
	var style:=T.flat(Color(0,0,0,0),T.GOLD,1,8);style.content_margin_left=6;style.content_margin_right=6
	pill.add_theme_stylebox_override("panel",style);pill.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	pill.add_child(_label(text,12,T.GOLD_TEXT,true))
	return pill

## A figure: the range as we know it, and under the headline figures (and
## the one the page is sorted by) its rank among the peoples.
func _figure_cell(row:Dictionary,id:String)->Control:
	var c:Dictionary=row.cells.get(id,{})
	var cell:=VBoxContainer.new();cell.name="Cell_"+id;cell.add_theme_constant_override("separation",0)
	cell.custom_minimum_size.x=float(WIDTHS.get(id,60))
	var known:=bool(c.get("known",false))
	var value:=_label(String(c.get("text","?")),13,T.INK if known else T.INK_MUTED);value.name="Value"
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	value.clip_text=true;value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	value.tooltip_text="%s: %s. %s" % [String(_titles().get(id,id)),String(c.get("text","?")),String(c.get("tip",""))]
	cell.add_child(value)
	if c.has("rank") and (_headline(id) or String(view.sort)==id):
		var rank:=_label(String(c.rank),12,T.INK_MUTED);rank.name="Rank"
		rank.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;rank.tooltip_text=String(c.get("rank_tip",""))
		rank.clip_text=true;rank.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		cell.add_child(rank)
	_part(id,cell)
	return cell

static func _headline(id:String)->bool:
	for column:Dictionary in Model.COLUMNS:
		if String(column.id)==id:return bool(column.get("headline",false))
	return false

## Peace, feud or war; their ruler's trust; our stance on the War screen.
func _between_cell(row:Dictionary)->Control:
	var c:Dictionary=row.cells.get("between",{})
	var cell:=VBoxContainer.new();cell.name="Cell_between";cell.add_theme_constant_override("separation",0)
	cell.custom_minimum_size.x=float(WIDTHS.between)
	if String(c.get("text",""))!="":
		var word:=_label(String(c.text),13,_tone(String(c.get("tone","ink"))),true);word.name="Relation";word.tooltip_text=String(c.get("tip",""))
		word.clip_text=true;word.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;cell.add_child(word)
		var trust:=_label(String(c.get("sub","")),12,T.INK_MUTED);trust.name="Trust";trust.tooltip_text=String(c.get("tip",""))
		trust.clip_text=true;trust.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;cell.add_child(trust)
		if String(c.get("stance",""))!="":
			var stance:=_label("→ "+String(c.stance),12,T.GOLD_TEXT);stance.name="Stance";stance.tooltip_text="Our stance toward them on the War screen."
			stance.clip_text=true;stance.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;cell.add_child(stance)
	_part("between",cell)
	return cell

func _envoys_cell(row:Dictionary)->Control:
	var c:Dictionary=row.cells.get("envoys",{})
	var cell:=VBoxContainer.new();cell.name="Cell_envoys";cell.add_theme_constant_override("separation",0)
	cell.custom_minimum_size.x=float(WIDTHS.envoys)
	if String(c.get("text",""))!="":
		var word:=_label(String(c.text),13,_tone(String(c.get("tone","ink"))));word.name="Envoys";word.tooltip_text=String(c.get("tip",""))
		word.clip_text=true;word.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;cell.add_child(word)
	_part("envoys",cell)
	return cell

static func _tone(tone:String)->Color:
	match tone:
		"danger":return T.RED_TEXT
		"warn":return T.AMBER_TEXT
		"good":return T.GREEN_TEXT
		"info":return T.TEAL_TEXT
		"muted":return T.INK_MUTED
	return T.INK

# --- An opened row: the towns we know of theirs ----------------------------

func _towns(row:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name="Towns_"+String(row.civ_id).validate_node_name()
	var style:=T.flat(T.PAPER_SUNK,Color(0,0,0,0),0,4);style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=8;style.content_margin_bottom=8
	panel.add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",4);panel.add_child(stack)
	var facts:=HFlowContainer.new();facts.name="Facts";facts.add_theme_constant_override("h_separation",14);facts.add_theme_constant_override("v_separation",2);stack.add_child(facts)
	for said:String in row.get("contact",[]):facts.add_child(_label(said.substr(0,1).to_upper()+said.substr(1),12,T.INK_MUTED))
	var bands:Dictionary=row.get("bands",{})
	if not bands.is_empty():
		var seen:=_label("%d band%s seen in the field: %s" % [int(bands.count),"" if int(bands.count)==1 else "s",Model.count_text(float(bands.low),float(bands.high),false,false,String(model.get("stage","hearth")))],12,T.INK_MUTED)
		seen.name="Bands";seen.tooltip_text="Counted with their fighters; our lookouts can only guess their number."
		facts.add_child(seen)
	var towns:Array=row.get("towns",[])
	if towns.is_empty():
		stack.add_child(_label("No town of theirs has been seen yet.",12,T.INK_MUTED))
		return panel
	stack.add_child(_town_header(bool(row.us)))
	for town:Dictionary in towns:stack.add_child(_town_row(town))
	return panel

func _town_header(us:bool)->Control:
	var line:=HBoxContainer.new();line.name="TownHeader";line.add_theme_constant_override("separation",GAP)
	var first:=_label("Our towns" if us else "Town",12,T.INK_MUTED,true);first.custom_minimum_size.x=120;first.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(first)
	var titles:=_titles()
	for spec:Array in TOWN_COLUMNS:
		var title:=_label(String(titles.get(String(spec[0]),spec[1])),12,T.INK_MUTED,true);title.custom_minimum_size.x=float(spec[2]);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;line.add_child(title)
	for pair:Array in [["Seen",128],["Held by",84]]:
		var title:=_label(String(pair[0]),12,T.INK_MUTED,true);title.custom_minimum_size.x=float(pair[1]);line.add_child(title)
	return line

func _town_row(town:Dictionary)->Control:
	var city_id:=String(town.get("city_id",""))
	var panel:=PanelContainer.new();panel.name="Town_"+(city_id if city_id!="" else String(town.name)).validate_node_name()
	var openable:=bool(town.get("open",false)) and city_id!="" and on_town.is_valid()
	panel.add_theme_stylebox_override("panel",_cell_style(Color(0,0,0,0)))
	panel.mouse_filter=Control.MOUSE_FILTER_STOP if openable else Control.MOUSE_FILTER_PASS
	if openable:
		panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		panel.tooltip_text="Read our report of %s." % String(town.name)
		panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",_cell_style(T.HOVER_BG)))
		panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",_cell_style(Color(0,0,0,0))))
		panel.gui_input.connect(func(event:InputEvent)->void:
			if _clicked(event):
				panel.accept_event()
				on_town.call(city_id))
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",GAP);panel.add_child(line)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",6);head.custom_minimum_size.x=120;head.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(head)
	var name_label:=_label(String(town.name),13,T.INK,true);name_label.name="TownName";name_label.clip_text=true;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(name_label)
	if bool(town.get("home",false)):head.add_child(_tag("home"))
	var cells:Dictionary=town.get("cells",{})
	for spec:Array in TOWN_COLUMNS:
		var text:=String(cells.get(String(spec[0]),"?"))
		var value:=_label(text,13,T.INK if text not in ["?","—"] else T.INK_MUTED);value.custom_minimum_size.x=float(spec[2]);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		value.clip_text=true;value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;value.tooltip_text=text;line.add_child(value)
	var fresh:Dictionary=town.get("fresh",{})
	var seen:=HBoxContainer.new();seen.name="Seen";seen.custom_minimum_size.x=128;seen.add_theme_constant_override("separation",4);line.add_child(seen)
	var mark:=FreshMark.new();mark.level=String(fresh.get("level","none"));seen.add_child(mark)
	var said:=String(fresh.get("text",""))+(" · "+String(fresh.source) if String(fresh.get("source",""))!="" else "")
	var when:=_label(said,12,T.INK_MUTED);when.clip_text=true;when.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;when.size_flags_horizontal=Control.SIZE_EXPAND_FILL;when.tooltip_text=said;seen.add_child(when)
	var held:=_label(String(town.get("held","")),12,T.INK_MUTED);held.name="Held";held.custom_minimum_size.x=84;held.clip_text=true;held.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;held.tooltip_text="Who holds it, as we last heard.";line.add_child(held)
	return panel

# --- Pieces ------------------------------------------------------------------

static func sheet_style()->StyleBoxFlat:
	var style:=T.flat(T.PAPER_RAISED,T.BORDER_SOFT,1,6)
	style.content_margin_left=PAD;style.content_margin_right=PAD;style.content_margin_top=12;style.content_margin_bottom=12
	style.shadow_color=Color(0,0,0,.10 if T.is_light() else .3);style.shadow_size=5;style.shadow_offset=Vector2(0,2)
	return style

static func _rule(color:Color)->ColorRect:
	var rule:=ColorRect.new();rule.color=color;rule.custom_minimum_size=Vector2(0,1);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return rule

static func _label(text:String,size:int,color:Color,strong:=false)->Label:
	var label:=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_PASS
	label.add_theme_font_override("font",T.font("ui_strong" if strong else "ui"))
	label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size))
	label.add_theme_color_override("font_color",color)
	return label

func _part(column:String,node:Control)->void:
	if not parts.has(column):parts[column]=[]
	(parts[column] as Array).append(node)

## On a narrow page the least needed columns give way (SHED), so the ledger
## never runs past its paper.
func _layout()->void:
	if size.x<=0.0:return
	var room:=size.x-PAD*2.0-2.0
	var need:=float(NAME_MIN)
	for id:String in WIDTHS:need+=float(WIDTHS[id])+GAP
	var giving:Array=[]
	for id:String in SHED:
		if need<=room:break
		giving.append(id);need-=float(WIDTHS[id])+GAP
	if giving!=_shape:
		_shape=giving
		_apply_shape()

func _apply_shape()->void:
	for id:String in parts:
		for node:Variant in parts[id]:
			if is_instance_valid(node):(node as Control).visible=not id in _shape

## How old our word is, at a glance: a full ring of ink for recent word, half
## for aging, an empty ring for stale, a broken one for undated; a gold
## diamond for our own count.
class FreshMark extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var level:="none"
	func _init()->void:
		custom_minimum_size=Vector2(12,12);mouse_filter=Control.MOUSE_FILTER_PASS;size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		var c:=size*0.5
		var r:=4.5
		match level:
			"recent":draw_circle(c,r,T.GREEN)
			"aging":
				draw_arc(c,r,0.0,TAU,24,T.AMBER,1.5,true)
				var half:=PackedVector2Array()
				for i in 13:half.append(c+Vector2(cos(PI*float(i)/12.0),sin(PI*float(i)/12.0))*r)
				draw_colored_polygon(half,T.AMBER)
			"stale":draw_arc(c,r,0.0,TAU,24,T.RED,1.5,true)
			"ours":draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r,0),c+Vector2(0,r),c+Vector2(-r,0)]),T.GOLD)
			_:
				for i in 6:draw_arc(c,r,TAU*float(i)/6.0,TAU*(float(i)+0.5)/6.0,4,T.INK_MUTED,1.2,true)
