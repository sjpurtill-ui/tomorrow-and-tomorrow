extends "res://scripts/hud/home_ledger.gd"
## THE KNOWLEDGE TREE (Research › Explore knowledge), drawn in the dock:
## one field selector and chosen question, then one path per line of study in that
## field, read left to right the way the knowledge grows: how much of the
## line is known, the question under way with its evidence, the questions
## open to a team now (gold) and the next ones still waiting on something
## (grey), with a count of the deeper ones. Choosing a question shows, above
## the paths, what it does or would do, what it builds on and waits for and
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
var archive_grid:GridContainer

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="KnowledgeTree";add_theme_constant_override("separation",18)
	if bool(data.get("archive",false)):
		_archive(self)
		resized.connect(_arrange);_arrange()
		return
	_fields(self)
	body=BoxContainer.new();body.name="Body";body.vertical=true;body.add_theme_constant_override("separation",22);add_child(body)
	var lanes:=VBoxContainer.new();lanes.name="Lanes";lanes.size_flags_horizontal=Control.SIZE_EXPAND_FILL;lanes.add_theme_constant_override("separation",0);body.add_child(lanes)
	_lanes(lanes)
	detail=VBoxContainer.new();detail.name="Chosen";detail.add_theme_constant_override("separation",8);body.add_child(detail)
	_detail(detail)
	resized.connect(_arrange);_arrange()

func _arrange()->void:
	if archive_grid:archive_grid.columns=2 if size.x>=760 else 1
	if body==null:return
	body.vertical=true
	detail.custom_minimum_size.x=0
	body.move_child(detail,0)
	var spread:=detail.find_child("QuestionSpread",true,false) as BoxContainer
	if spread:
		spread.vertical=size.x<430.0
		spread.add_theme_constant_override("separation",14 if size.x<650 else 22)
		var painting:=spread.find_child("QuestionPainting",false,false) as Control
		if painting:painting.custom_minimum_size=Vector2(0 if spread.vertical else (112 if size.x<650 else 220),110 if size.x<650 else 160)
		var title:=spread.find_child("ChosenName",true,false) as Label
		if title:title.add_theme_font_size_override("font_size",25 if size.x<650 else 30)

# --- Fields ---------------------------------------------------------------------

## One chip per field: its mark, its name and how much of it is known; the
## chosen field is marked.
func _fields(parent:Node)->void:
	var row:=HFlowContainer.new();row.name="Fields";row.add_theme_constant_override("h_separation",16);row.add_theme_constant_override("v_separation",6);parent.add_child(row)
	var label:=T.make_label("Explore a field",20,T.INK);label.add_theme_font_override("font",T.voice_font());label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(label)
	var picker:=OptionButton.new();picker.name="FieldPicker";picker.custom_minimum_size=Vector2(260,36);picker.size_flags_vertical=Control.SIZE_SHRINK_CENTER;picker.add_theme_font_size_override("font_size",15);row.add_child(picker)
	var ids:Array[String]=[]
	for field:Dictionary in data.get("fields",[]):
		var id:=String(field.id)
		ids.append(id);picker.add_item(Visuals.name_for(id))
		if id==String(data.get("domain","")):
			picker.select(ids.size()-1)
			var summary:=T.make_label("%d known · %d under way" % [int(field.get("known",0)),int(field.get("active",0))],13,T.TEXT_SOFT);summary.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(summary)
	if data.get("on_field") is Callable:picker.item_selected.connect(func(index:int)->void:(data.on_field as Callable).call(ids[index]))

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
	var head:=VBoxContainer.new();head.name="PathsHeading";head.add_theme_constant_override("separation",4);parent.add_child(head)
	head.add_child(_voice("Paths of discovery",22))
	_line(head,"Choose a question to read its promise, foundations and next steps.",13,T.TEXT_SOFT)
	var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size.y=1;parent.add_child(rule)
	var lanes:=lanes_of(data.get("rows",[]),domain,data.get("next",{}))
	if lanes.is_empty():
		parent.add_child(T.make_label("Nothing is known or open in this field yet.",13,T.TEXT_SOFT))
		return
	for lane:Dictionary in lanes:_lane(parent,lane,accent)

func _lane(parent:Node,lane:Dictionary,accent:Color)->void:
	var row:=VBoxContainer.new();row.name="Line_"+String(lane.line).validate_node_name();row.add_theme_constant_override("separation",7);parent.add_child(row)
	var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_top",10);row.add_child(margin)
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",12);margin.add_child(heading)
	var name_label:=_voice(String(lane.line),18);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(name_label)
	# How much of the line is known: a count, its names on hover.
	var known:Array=lane.known
	var count:=T.make_label("%d known" % known.size(),12,T.GREEN_TEXT if not known.is_empty() else T.TEXT_SOFT);count.name="Known"
	count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;count.mouse_filter=Control.MOUSE_FILTER_PASS
	if not known.is_empty():
		var names:Array[String]=[]
		for item:Dictionary in known.slice(maxi(0,known.size()-12)):names.append(String(item.name))
		count.tooltip_text="Known in %s:\n%s%s" % [String(lane.line).to_lower(),"\n".join(names),"\n…and %d earlier" % (known.size()-12) if known.size()>12 else ""]
	heading.add_child(count)
	var flow:=HFlowContainer.new();flow.size_flags_horizontal=Control.SIZE_EXPAND_FILL;flow.add_theme_constant_override("h_separation",6);flow.add_theme_constant_override("v_separation",6);row.add_child(flow)
	for item:Dictionary in lane.active:_pill(flow,item,"active",accent)
	var ready:Array=lane.ready
	for item:Dictionary in ready.slice(0,READY_SHOWN):_pill(flow,item,"ready",accent)
	if ready.size()>READY_SHOWN:_more(flow,ready.slice(READY_SHOWN),"open to a team")
	var next:Array=lane.next
	for item:Dictionary in next.slice(0,NEXT_SHOWN):_pill(flow,item,"next",accent)
	if next.size()>NEXT_SHOWN:_more(flow,next.slice(NEXT_SHOWN),"waiting","next")
	var hidden:=int(lane.beyond)
	if hidden>0:
		var beyond:=T.make_label("+%d further" % hidden,12,T.TEXT_SOFT);beyond.size_flags_vertical=Control.SIZE_SHRINK_CENTER;beyond.mouse_filter=Control.MOUSE_FILTER_PASS
		beyond.tooltip_text="Questions further along this line; they open as the ones before them are answered."
		flow.add_child(beyond)
	var space:=Control.new();space.custom_minimum_size.y=10;row.add_child(space)
	var under:=ColorRect.new();under.color=Color(T.BORDER_SOFT,0.5);under.custom_minimum_size.y=1;parent.add_child(under)

## A question as a pill: under way (its evidence fills it), open to a team
## (gold edge) or waiting (grey). Choosing it shows its account beside the lanes.
func _pill(parent:Node,item:Dictionary,kind:String,accent:Color)->void:
	var id:=String(item.id)
	var chosen:=id==String(data.get("selected",""))
	var pill:=Button.new();pill.name="Pill_"+id.validate_node_name();pill.text=String(item.name)
	pill.custom_minimum_size.y=32;pill.add_theme_font_size_override("font_size",13)
	var ink:Color=T.INK if kind!="next" else T.TEXT_SOFT
	pill.add_theme_color_override("font_color",ink);pill.add_theme_color_override("font_hover_color",T.INK);pill.add_theme_color_override("font_pressed_color",T.INK)
	var fill:Color=Color(accent,0.22) if kind=="active" else (T.PAPER_RAISED if kind=="ready" else Color.TRANSPARENT)
	var edge:Color=T.GOLD if chosen else (accent if kind=="active" else (T.GOLD if kind=="ready" else T.BORDER_SOFT))
	var face:=T.flat(fill,edge,0,2,0);face.border_color=edge;face.border_width_bottom=2 if chosen else 1;face.content_margin_left=10;face.content_margin_right=10
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

func _more(parent:Node,items:Array,words:String,kind:String="ready")->void:
	var names:Array[String]=[]
	for item:Dictionary in items:names.append(String(item.name))
	var more:=Button.new();more.text="+%d %s" % [items.size(),words];more.add_theme_font_size_override("font_size",13);more.add_theme_color_override("font_color",T.GOLD_TEXT);more.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	more.add_theme_stylebox_override("normal",T.flat(Color.TRANSPARENT));more.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG));more.tooltip_text="Show these questions here:\n"+"\n".join(names);parent.add_child(more)
	more.pressed.connect(func()->void:
		var at:=more.get_index()
		for item:Dictionary in items:
			_pill(parent,item,kind,Visuals.color(String(data.get("domain",""))))
			parent.move_child(parent.get_child(parent.get_child_count()-1),at);at+=1
		parent.remove_child(more);more.queue_free())

static func _waits(item:Dictionary)->String:
	var missing:Array=item.get("missing",[])
	return DiscoverySystem.plain_wait_reason(missing) if not missing.is_empty() else "more evidence"

# --- The chosen question --------------------------------------------------------

func _detail(parent:Node)->void:
	var chosen:Dictionary=data.get("chosen",{})
	if chosen.is_empty():
		parent.add_child(_voice("Every discovery begins with a question.",24))
		_line(parent,"Choose one below to see what it could bring.",14,T.TEXT_SOFT)
		return
	var spread:=BoxContainer.new();spread.name="QuestionSpread";spread.add_theme_constant_override("separation",22);parent.add_child(spread)
	var art:Dictionary=chosen.get("art",{})
	if not Visuals.subject_art_key(art).is_empty():
		var painting:=Visuals.paint_discovery(spread,art,160);painting.name="QuestionPainting";painting.custom_minimum_size.x=220;painting.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",8);spread.add_child(text)
	text.add_child(T.make_label("THE QUESTION",12,T.GOLD_TEXT))
	var title:=_voice(String(chosen.name),30);title.name="ChosenName";text.add_child(title)
	var state:=T.make_label(String(chosen.state),14,tone_color(String(chosen.get("tone",""))) if String(chosen.get("tone",""))!="" else T.BODY);state.name="ChosenState";state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.add_child(state)
	if chosen.has("progress"):_bar(text,float(chosen.progress),Visuals.color(String(data.get("domain",""))))
	for fact:Array in chosen.get("facts",[]):
		var line:=_line(text,String(fact[0])+" · "+String(fact[1]),14,T.BODY);line.mouse_filter=Control.MOUSE_FILTER_PASS;line.tooltip_text=String(fact[2]) if fact.size()>2 else String(fact[1])
	var notes:=VBoxContainer.new();notes.name="DetailNotes";notes.add_theme_constant_override("separation",8);notes.visible=false
	for fact:Array in chosen.get("facts",[]):
		if fact.size()>2 and String(fact[2])!=String(fact[1]) and not String(fact[2]).is_empty():_line(notes,String(fact[0])+" · "+String(fact[2]),13,T.BODY)
	if notes.get_child_count()>0:
		var read:=_button(text,"More about this question",func()->void:notes.visible=not notes.visible,"Read the full effects, foundations and people behind this question.");read.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		text.add_child(notes)
	else:notes.queue_free()
	if chosen.has("on_research"):
		var go:=preload("res://scripts/hud/dense_blocks.gd").verb(String(chosen.get("research_label","Put a team on it")),chosen.on_research,"A team takes this question up; the work done on its old question is kept.")
		go.name="Research";go.custom_minimum_size.y=34;go.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;text.add_child(go)

## The accumulated benefits are a readable index with details expanded in
## place. A field never opens a second modal or loses its position in the book.
func _archive(parent:Node)->void:
	parent.add_child(_voice("Knowledge that stays with us",26))
	_line(parent,"Open a field to read its effects and the discoveries behind them.",14,T.TEXT_SOFT)
	archive_grid=GridContainer.new();archive_grid.add_theme_constant_override("h_separation",28);archive_grid.add_theme_constant_override("v_separation",14);parent.add_child(archive_grid)
	var fields:Array=data.get("archive_fields",[])
	var established:=fields.filter(func(field:Dictionary)->bool:return int(field.get("known",0))>0)
	var unexplored:=fields.filter(func(field:Dictionary)->bool:return int(field.get("known",0))==0)
	var visible_fields:Array=established+(unexplored if bool(data.get("show_unlearned",false)) else [])
	for field:Dictionary in visible_fields:
		var entry:=VBoxContainer.new();entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL;entry.add_theme_constant_override("separation",4);archive_grid.add_child(entry)
		_rule(entry)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);entry.add_child(row)
		var heading:=Button.new();heading.text=String(field.name);heading.alignment=HORIZONTAL_ALIGNMENT_LEFT;heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_theme_font_override("font",T.voice_font());heading.add_theme_font_size_override("font_size",20)
		heading.add_theme_stylebox_override("normal",T.flat(Color.TRANSPARENT));heading.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG));heading.add_theme_stylebox_override("pressed",T.flat(T.ACTIVE_BG));heading.custom_minimum_size.y=32
		heading.tooltip_text="Close this field" if bool(field.open) else "Read this field's effects and discoveries";heading.pressed.connect(field.on_toggle);row.add_child(heading)
		var count:=T.make_label("%s  %s" % [String(field.count),"−" if bool(field.open) else "+"],13,T.GOLD_TEXT);count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;count.tooltip_text="Questions known, of all questions in this field";row.add_child(count)
		_line(entry,String(field.summary),14,T.BODY)
		if not bool(field.open):continue
		for section:Dictionary in field.sections:
			var subtitle:=T.make_label(String(section.get("heading","")),12,T.GOLD_TEXT);entry.add_child(subtitle)
			for item:Dictionary in section.get("items",[]):
				var fact:=_line(entry,String(item.label)+" · "+String(item.value),14,tone_color(String(item.get("tone",""))) if String(item.get("tone",""))!="" else T.BODY);fact.tooltip_text=String(item.get("tip",""));fact.mouse_filter=Control.MOUSE_FILTER_PASS
	if not unexplored.is_empty():
		var show:=_button(parent,("Hide" if bool(data.get("show_unlearned",false)) else "Show")+" fields still to explore (%d)" % unexplored.size(),data.get("on_toggle_unlearned"),"Read every field, including those with no known discovery yet.");show.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
