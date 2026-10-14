extends "res://scripts/hud/home_ledger.gd"
## THE KNOWLEDGE TREE (Research › Knowledge tree), drawn in the dock as lanes:
## one chip per field to choose it, then one lane per line of study in that
## field, read left to right the way the knowledge grows: how much of the
## line is known, the question under way with its evidence, the questions
## open to a team now (gold) and the next ones still waiting on something
## (grey), with a count of the deeper ones. Choosing a question shows, beside
## the lanes, what it does or would do, what it builds on and waits for and
## what it opens, with the one order that puts a team on it.
## Data: dock_content_inquiry.gd _tree_block (DiscoverySystem.technology_tree,
## technology_frontier and the effect explainer); nothing here reads the engine.
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const LINES:=preload("res://scripts/discovery_frontier_catalog.gd").SUBCATEGORIES
## The lanes and the chosen question side by side from this width.
const SIDE_AT:=820.0
const LINE_W:=130.0
const PILL_H:=24.0
## Questions shown in a lane before "+N more".
const READY_SHOWN:=3
const NEXT_SHOWN:=3
var body:BoxContainer
var detail:VBoxContainer

func setup(block:Dictionary)->void:
	data=block;name="KnowledgeTree";add_theme_constant_override("separation",8)
	_fields(self)
	body=BoxContainer.new();body.name="Body";body.add_theme_constant_override("separation",14);add_child(body)
	var lanes:=VBoxContainer.new();lanes.name="Lanes";lanes.size_flags_horizontal=Control.SIZE_EXPAND_FILL;lanes.add_theme_constant_override("separation",0);body.add_child(lanes)
	_lanes(lanes)
	detail=VBoxContainer.new();detail.name="Chosen";detail.add_theme_constant_override("separation",4);body.add_child(detail)
	_detail(detail)
	resized.connect(_arrange);_arrange()

func _arrange()->void:
	if body==null:return
	var side:=size.x>=SIDE_AT
	body.vertical=not side
	detail.custom_minimum_size.x=260.0 if side else 0.0
	# Narrow, the chosen question heads the lanes so it is always in view.
	body.move_child(detail,0 if not side else body.get_child_count()-1)

# --- Fields ---------------------------------------------------------------------

## One chip per field: its mark, its name and how much of it is known; the
## chosen field is marked.
func _fields(parent:Node)->void:
	var row:=HFlowContainer.new();row.name="Fields";row.add_theme_constant_override("h_separation",4);row.add_theme_constant_override("v_separation",4);parent.add_child(row)
	for field:Dictionary in data.get("fields",[]):
		var id:=String(field.id)
		var chosen:=id==String(data.get("domain",""))
		var chip:=Button.new();chip.name="Field_"+id;chip.focus_mode=Control.FOCUS_NONE
		chip.text="%s  %d" % [Visuals.name_for(id),int(field.get("known",0))]
		chip.add_theme_constant_override("icon_max_width",16);chip.icon=Icons.domain_texture(id,Visuals.color(id))
		chip.add_theme_font_size_override("font_size",12);chip.custom_minimum_size.y=26
		chip.add_theme_color_override("font_color",T.INK if chosen else T.BODY);chip.add_theme_color_override("font_hover_color",T.INK)
		var face:=T.flat(T.ACTIVE_BG if chosen else Color.TRANSPARENT,T.GOLD if chosen else T.BORDER_SOFT,1,2,6)
		if chosen:face.border_width_bottom=3
		chip.add_theme_stylebox_override("normal",face);chip.add_theme_stylebox_override("pressed",face);chip.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,2,6))
		var active:=int(field.get("active",0))
		chip.tooltip_text="%s: %d known%s." % [Visuals.name_for(id),int(field.get("known",0)),(", %d under way" % active) if active>0 else ""]
		if data.get("on_field") is Callable:chip.pressed.connect((data.on_field as Callable).bind(id))
		row.add_child(chip)

# --- Lanes ----------------------------------------------------------------------

## The field's rows grouped by line of study, in the catalog's order.
static func lanes_of(rows:Array,domain:String,next:Dictionary)->Array:
	var by_line:Dictionary={}
	for row:Dictionary in rows:
		var line:=String(row.get("subcategory","")).strip_edges()
		if line.is_empty():line="Other questions"
		var lane:Dictionary=by_line.get_or_add(line,{"line":line,"known":[],"active":[],"ready":[],"next":[],"beyond":0})
		match String(row.get("status","")):
			"DISCOVERED":(lane.known as Array).append(row)
			"RESEARCHING":(lane.active as Array).append(row)
			"AVAILABLE":(lane.ready as Array).append(row)
			_:
				if next.has(String(row.id)):(lane.next as Array).append(row)
				else:lane.beyond=int(lane.beyond)+1
	var order:Array=(LINES.get(domain,[]) as Array).duplicate()
	for line:String in by_line:
		if not order.has(line):order.append(line)
	var lanes:Array=[]
	for line:String in order:
		if not by_line.has(line):continue
		var lane:Dictionary=by_line[line]
		var soonest:=func(a:Dictionary,b:Dictionary)->bool:return float(a.get("earliest_year",0.0))<float(b.get("earliest_year",0.0))
		(lane.ready as Array).sort_custom(soonest);(lane.next as Array).sort_custom(soonest)
		lanes.append(lane)
	return lanes

func _lanes(parent:Node)->void:
	var domain:=String(data.get("domain",""))
	var accent:=Visuals.color(domain)
	var head:=HBoxContainer.new();head.name="TableHead";head.add_theme_constant_override("separation",8);parent.add_child(head)
	for spec:Array in [["LINE OF STUDY",LINE_W],["KNOWN",48.0],["UNDER WAY, THEN WHAT COMES NEXT",0.0]]:
		var label:=T.make_label(String(spec[0]),11,T.GOLD_TEXT,0.06)
		if float(spec[1])>0.0:label.custom_minimum_size.x=float(spec[1])
		else:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		head.add_child(label)
	var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size.y=1;parent.add_child(rule)
	var lanes:=lanes_of(data.get("rows",[]),domain,data.get("next",{}))
	if lanes.is_empty():
		parent.add_child(T.make_label("Nothing is known or open in this field yet.",13,T.TEXT_SOFT))
		return
	for lane:Dictionary in lanes:_lane(parent,lane,accent)

func _lane(parent:Node,lane:Dictionary,accent:Color)->void:
	var row:=HBoxContainer.new();row.name="Line_"+String(lane.line).validate_node_name();row.add_theme_constant_override("separation",8);row.custom_minimum_size.y=PILL_H+6.0;parent.add_child(row)
	var name_label:=T.make_label(String(lane.line),13,T.INK);name_label.custom_minimum_size.x=LINE_W;name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(name_label)
	# How much of the line is known: a count, its names on hover.
	var known:Array=lane.known
	var count:=T.make_label(str(known.size()) if not known.is_empty() else "—",13,T.GREEN_TEXT if not known.is_empty() else T.TEXT_SOFT);count.name="Known"
	count.custom_minimum_size.x=48;count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;count.mouse_filter=Control.MOUSE_FILTER_PASS
	if not known.is_empty():
		var names:Array[String]=[]
		for item:Dictionary in known.slice(maxi(0,known.size()-12)):names.append(String(item.name))
		count.tooltip_text="Known in %s:\n%s%s" % [String(lane.line).to_lower(),"\n".join(names),"\n…and %d earlier" % (known.size()-12) if known.size()>12 else ""]
	row.add_child(count)
	var flow:=HFlowContainer.new();flow.size_flags_horizontal=Control.SIZE_EXPAND_FILL;flow.add_theme_constant_override("h_separation",4);flow.add_theme_constant_override("v_separation",4);flow.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(flow)
	for item:Dictionary in lane.active:_pill(flow,item,"active",accent)
	var ready:Array=lane.ready
	for item:Dictionary in ready.slice(0,READY_SHOWN):_pill(flow,item,"ready",accent)
	if ready.size()>READY_SHOWN:_more(flow,ready.slice(READY_SHOWN),"open to a team")
	var next:Array=lane.next
	for item:Dictionary in next.slice(0,NEXT_SHOWN):_pill(flow,item,"next",accent)
	var hidden:=maxi(0,next.size()-NEXT_SHOWN)+int(lane.beyond)
	if hidden>0:
		var beyond:=T.make_label("+%d further" % hidden,12,T.TEXT_SOFT);beyond.size_flags_vertical=Control.SIZE_SHRINK_CENTER;beyond.mouse_filter=Control.MOUSE_FILTER_PASS
		beyond.tooltip_text="Questions further along this line; they open as the ones before them are answered."
		flow.add_child(beyond)
	var under:=ColorRect.new();under.color=Color(T.BORDER_SOFT,0.5);under.custom_minimum_size.y=1;parent.add_child(under)

## A question as a pill: under way (its evidence fills it), open to a team
## (gold edge) or waiting (grey). Choosing it shows its account beside the lanes.
func _pill(parent:Node,item:Dictionary,kind:String,accent:Color)->void:
	var id:=String(item.id)
	var chosen:=id==String(data.get("selected",""))
	var pill:=Button.new();pill.name="Pill_"+id.validate_node_name();pill.focus_mode=Control.FOCUS_NONE;pill.text=String(item.name)
	pill.custom_minimum_size.y=PILL_H;pill.add_theme_font_size_override("font_size",12)
	var ink:Color=T.INK if kind!="next" else T.TEXT_SOFT
	pill.add_theme_color_override("font_color",ink);pill.add_theme_color_override("font_hover_color",T.INK);pill.add_theme_color_override("font_pressed_color",T.INK)
	var fill:Color=Color(accent,0.22) if kind=="active" else (T.PAPER_RAISED if kind=="ready" else Color.TRANSPARENT)
	var edge:Color=T.GOLD if chosen else (accent if kind=="active" else (T.GOLD if kind=="ready" else T.BORDER_SOFT))
	var face:=T.flat(fill,edge,2 if chosen else 1,PILL_H*0.5,0);face.content_margin_left=10;face.content_margin_right=10
	pill.add_theme_stylebox_override("normal",face);pill.add_theme_stylebox_override("pressed",face)
	var hover:=face.duplicate();hover.border_color=T.GOLD;pill.add_theme_stylebox_override("hover",hover)
	if kind=="active":
		# The evidence gathered, drawn as a bar along the pill's foot.
		var progress:=clampf(float(item.get("progress",0.0)),0.0,1.0)
		pill.draw.connect(func()->void:pill.draw_rect(Rect2(Vector2(PILL_H*0.4,pill.size.y-4.0),Vector2((pill.size.x-PILL_H*0.8)*progress,2.5)),accent))
		pill.text="%s · %d%%" % [String(item.name),roundi(progress*100.0)]
	pill.tooltip_text="%s · %s" % [String(item.name),{"active":"under way","ready":"open to a team now","next":"waiting: "+_waits(item)}.get(kind,"")]
	if data.get("on_select") is Callable:pill.pressed.connect((data.on_select as Callable).bind(id))
	parent.add_child(pill)

func _more(parent:Node,items:Array,words:String)->void:
	var names:Array[String]=[]
	for item:Dictionary in items:names.append(String(item.name))
	var more:=T.make_label("+%d %s" % [items.size(),words],12,T.GOLD_TEXT);more.size_flags_vertical=Control.SIZE_SHRINK_CENTER;more.mouse_filter=Control.MOUSE_FILTER_PASS
	more.tooltip_text="\n".join(names);parent.add_child(more)

static func _waits(item:Dictionary)->String:
	var missing:Array=item.get("missing",[])
	return DiscoverySystem.plain_wait_reason(missing) if not missing.is_empty() else "more evidence"

# --- The chosen question --------------------------------------------------------

func _detail(parent:Node)->void:
	var chosen:Dictionary=data.get("chosen",{})
	parent.add_child(T.make_label("CHOSEN QUESTION",11,T.GOLD_TEXT,0.06))
	if chosen.is_empty():
		parent.add_child(T.make_label("Choose a question in the lanes.",13,T.TEXT_SOFT))
		return
	var title:=_voice(String(chosen.name),20);title.name="ChosenName";parent.add_child(title)
	var state:=T.make_label(String(chosen.state),12,tone_color(String(chosen.get("tone",""))) if String(chosen.get("tone",""))!="" else T.BODY);state.name="ChosenState";state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(state)
	if chosen.has("progress"):_bar(parent,float(chosen.progress),Visuals.color(String(data.get("domain",""))))
	# One line per fact, in the game's shared fact grid; the whole of each on hover.
	var items:Array=[]
	for fact:Array in chosen.get("facts",[]):items.append({"label":String(fact[0]),"value":String(fact[1]),"tip":String(fact[2]) if fact.size()>2 else String(fact[1])})
	if not items.is_empty():preload("res://scripts/hud/dense_blocks.gd").render_fact_grid(parent,{"items":items,"min_column":220})
	if chosen.has("on_research"):
		var go:=preload("res://scripts/hud/dense_blocks.gd").verb(String(chosen.get("research_label","Put a team on it")),chosen.on_research,"A team takes this question up; the work done on its old question is kept.")
		go.name="Research";go.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;parent.add_child(go)
