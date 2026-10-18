extends "res://scripts/hud/home_ledger.gd"
const VisibleChoice=preload("res://scripts/hud/visible_choices.gd")
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
const SIDE_AT:=760.0
const LINE_W:=130.0
const PILL_H:=24.0
## Questions shown in a lane before "+N more".
const READY_SHOWN:=3
const NEXT_SHOWN:=3
var body:BoxContainer
var detail:VBoxContainer
var overview:BoxContainer
var overview_totals:GridContainer
var recent_grid:GridContainer
var effect_groups:Array[Control]=[]
var effect_column_count:=0
var archive_open:=false
var archive_toggle:Button
var archive_body:HBoxContainer
var archive_list:VBoxContainer
var archive_picker:VisibleChoice
var archive_reader:ScrollContainer
var archive_detail:VBoxContainer
var archive_selected:String=""
var archive_buttons:Dictionary={}
var archive_browse:=false
var archive_query:=""
var archive_page:=0
var archive_findings:Array=[]
var archive_results:VBoxContainer
var archive_result_heading:Label
var archive_page_label:Label
var archive_previous:Button
var archive_next:Button
const FINDINGS_PER_PAGE:=6
var question_query:=""
var question_filter:="open"
var question_page:=0
var question_grid:GridContainer
var question_count:Label
var question_previous:Button
var question_next:Button
var question_search:LineEdit
var question_status:VisibleChoice
var question_choices:Array=[]

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="KnowledgeTree";add_theme_constant_override("separation",24)
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
	if archive_body:
		var wide:=size.x>=760.0
		archive_list.visible=wide;archive_picker.visible=not wide and (archive_open or overview==null)
		if overview:
			overview.vertical=true
			if recent_grid:recent_grid.columns=3 if size.x>=700 else 1
			_arrange_effect_groups(3 if size.x>=1150 else 2 if size.x>=440 else 1)
		for grid:GridContainer in archive_detail.find_children("EffectCategories","GridContainer",true,false):grid.columns=2 if size.x>=1000 else 1
		archive_body.custom_minimum_size.x=0
		_fit_archive_reader.call_deferred()
		return
	if body==null:return
	var side:=size.x>=SIDE_AT
	if question_grid:question_grid.columns=2 if size.x>=1000 else 1
	body.vertical=not side
	detail.custom_minimum_size.x=340 if side else 0
	detail.size_flags_horizontal=Control.SIZE_FILL if side else Control.SIZE_EXPAND_FILL
	body.move_child(detail,1 if side else 0)
	var spread:=detail.find_child("QuestionSpread",true,false) as BoxContainer
	if spread:
		spread.vertical=side or size.x<430.0
		spread.add_theme_constant_override("separation",14 if size.x<650 else 22)
		var painting:=spread.find_child("QuestionPainting",false,false) as Control
		if painting:painting.custom_minimum_size=Vector2(0 if spread.vertical else 112,120 if side else 110)
		var title:=spread.find_child("ChosenName",true,false) as Label
		if title:title.add_theme_font_size_override("font_size",26 if side else 28)

func _fit_archive_reader()->void:
	if is_instance_valid(archive_reader):archive_reader.custom_minimum_size.y=clampf(get_viewport_rect().size.y-archive_body.global_position.y-24.0,280.0,1000.0)

# --- Fields ---------------------------------------------------------------------

## One chip per field: its mark, its name and how much of it is known; the
## chosen field is marked.
func _fields(parent:Node)->void:
	var row:=HFlowContainer.new();row.name="Fields";row.add_theme_constant_override("h_separation",16);row.add_theme_constant_override("v_separation",6);parent.add_child(row)
	var label:=T.make_label("Explore a field",24,T.INK);label.add_theme_font_override("font",T.font("ui_strong"));label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(label)
	var picker:=VisibleChoice.new();picker.name="FieldPicker";picker.custom_minimum_size=Vector2(260,40);picker.size_flags_vertical=Control.SIZE_SHRINK_CENTER;picker.add_theme_font_size_override("font_size",16);row.add_child(picker)
	var ids:Array[String]=[]
	for field:Dictionary in data.get("fields",[]):
		var id:=String(field.id)
		ids.append(id);picker.add_icon_item(Icons.domain_texture(id,Visuals.color(id)),Visuals.name_for(id))
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
	parent.add_child(_voice("Choose a question",22))
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",8);parent.add_child(controls)
	question_search=LineEdit.new();question_search.size_flags_vertical=Control.SIZE_SHRINK_CENTER;question_search.placeholder_text="Search this field";question_search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;question_search.custom_minimum_size.y=40;controls.add_child(question_search)
	question_search.text_changed.connect(func(value:String)->void:question_query=value;question_page=0;_render_questions())
	question_status=VisibleChoice.new();question_status.custom_minimum_size.y=40;controls.add_child(question_status)
	for words:String in ["Open & under way","Known","Waiting","All questions"]:question_status.add_item(words)
	question_status.item_selected.connect(func(index:int)->void:question_filter=["open","known","waiting","all"][index];question_page=0;_render_questions())
	question_grid=GridContainer.new();question_grid.name="QuestionChoices";question_grid.columns=2;question_grid.add_theme_constant_override("h_separation",8);question_grid.add_theme_constant_override("v_separation",8);parent.add_child(question_grid)
	var pager:=HBoxContainer.new();pager.add_theme_constant_override("separation",10);parent.add_child(pager)
	question_previous=_button(pager,"Previous",func()->void:question_page-=1;_render_questions(),"Previous questions");T.apply_button_style(question_previous)
	question_count=T.make_label("",14,T.TEXT_SOFT);question_count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pager.add_child(question_count)
	question_next=_button(pager,"Next",func()->void:question_page+=1;_render_questions(),"Next questions");T.apply_button_style(question_next)
	_render_questions()

func _render_questions()->void:
	for child:Node in question_grid.get_children():question_grid.remove_child(child);child.queue_free()
	question_choices=[]
	for row:Dictionary in data.get("rows",[]):
		var status:=String(row.get("status",""))
		if question_filter=="open" and status not in ["AVAILABLE","RESEARCHING"]:continue
		if question_filter=="known" and status!="DISCOVERED":continue
		if question_filter=="waiting" and status in ["AVAILABLE","RESEARCHING","DISCOVERED"]:continue
		if not question_query.is_empty() and not question_query.to_lower() in (String(row.name)+" "+String(row.get("subcategory",""))).to_lower():continue
		question_choices.append(row)
	var pages:=maxi(1,ceili(question_choices.size()/6.0));question_page=clampi(question_page,0,pages-1)
	for item:Dictionary in question_choices.slice(question_page*6,(question_page+1)*6):
		var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",T.flat(Color.TRANSPARENT));question_grid.add_child(card)
		var button:=Button.new();button.name="Pill_"+String(item.id).validate_node_name();button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size.y=60;T.apply_button_style(button);card.add_child(button)
		var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_left",10);margin.add_theme_constant_override("margin_right",10);margin.add_theme_constant_override("margin_top",6);margin.add_theme_constant_override("margin_bottom",6);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(margin)
		var words:=VBoxContainer.new();words.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(words)
		var title:=_line(words,String(item.name),16,T.INK);title.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var state:=String({"DISCOVERED":"Known","RESEARCHING":"Under way · %d%%" % roundi(float(item.get("progress",0))*100),"AVAILABLE":"Open to a team"}.get(String(item.status),"Waiting"))
		button.accessibility_name=String(item.name)+". "+state
		var caption:=_line(words,state,14,T.TEXT_SOFT);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.tooltip_text=String(item.get("subcategory",""))+" · "+_waits(item) if String(item.status) not in ["AVAILABLE","RESEARCHING","DISCOVERED"] else String(item.get("subcategory",""))
		if String(item.id)==String(data.get("selected","")):button.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG,T.GOLD,1,4,8))
		if data.get("on_select") is Callable:button.pressed.connect((data.on_select as Callable).bind(String(item.id)))
	question_count.text="%d questions · %d / %d" % [question_choices.size(),question_page+1,pages];question_previous.disabled=question_page==0;question_next.disabled=question_page>=pages-1
	if question_choices.is_empty():_line(question_grid,"No questions match this view.",16,T.TEXT_SOFT)

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
	T.apply_button_style(pill)
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
	T.apply_button_style(more)
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
		var read:=_button(text,"More about this question",func()->void:notes.visible=not notes.visible,"Read the full effects, foundations and people behind this question.");read.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;T.apply_button_style(read)
		text.add_child(notes)
	else:notes.queue_free()
	if chosen.has("on_research"):
		var go:=preload("res://scripts/hud/dense_blocks.gd").verb(String(chosen.get("research_label","Put a team on it")),chosen.on_research,"A team takes this question up; the work done on its old question is kept.")
		go.name="Research";T.apply_button_style(go,true);go.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;text.add_child(go)

## A stable field index and one continuous account. The selected account owns
## its reading space; a long field never stretches unrelated fields into rows.
func _archive(parent:Node)->void:
	add_theme_constant_override("separation",12)
	var summary:=_line(parent,String(data.get("summary","")),16,T.TEXT_SOFT)
	summary.tooltip_text=String(data.get("summary_tip",""));summary.mouse_filter=Control.MOUSE_FILTER_PASS
	if data.has("totals"):_build_overview(parent)
	var fields:Array=data.get("archive_fields",[])
	archive_picker=VisibleChoice.new();archive_picker.name="ArchiveFieldPicker";archive_picker.custom_minimum_size.y=40;archive_picker.add_theme_font_size_override("font_size",16);parent.add_child(archive_picker)
	archive_body=HBoxContainer.new();archive_body.name="ArchiveBody";archive_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;archive_body.add_theme_constant_override("separation",24);parent.add_child(archive_body)
	archive_list=VBoxContainer.new();archive_list.name="ArchiveFields";archive_list.custom_minimum_size.x=232;archive_list.add_theme_constant_override("separation",2);archive_list.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;archive_body.add_child(archive_list)
	archive_reader=ScrollContainer.new();archive_reader.name="FieldReader";archive_reader.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;archive_reader.size_flags_horizontal=Control.SIZE_EXPAND_FILL;archive_body.add_child(archive_reader)
	archive_detail=VBoxContainer.new();archive_detail.name="FieldAccount";archive_detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;archive_detail.add_theme_constant_override("separation",6);archive_reader.add_child(archive_detail)
	for field:Dictionary in fields:
		var id:=String(field.id)
		var words:="%s · %d" % [String(field.name),int(field.known)]
		archive_picker.add_item(words)
		var button:=Button.new();button.name="Field_"+id;button.text=words;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.toggle_mode=true;T.apply_button_style(button);button.add_theme_font_size_override("font_size",14)
		button.add_theme_stylebox_override("normal",T.flat(Color.TRANSPARENT));button.add_theme_stylebox_override("pressed",T.flat(T.ACTIVE_BG,T.GOLD,0,4,10));button.add_theme_color_override("font_pressed_color",T.INK)
		button.tooltip_text="%s known · %s" % [String(field.count),String(field.summary)];button.pressed.connect(select_archive.bind(id));archive_list.add_child(button);archive_buttons[id]=button
	archive_picker.item_selected.connect(func(index:int)->void:select_archive(String(fields[index].id)))
	select_archive(String(data.get("selected",fields[0].id if not fields.is_empty() else "")),false)
	if overview:_show_archive(false)

func select_archive(id:String,notify:bool=true)->void:
	var fields:Array=data.get("archive_fields",[])
	var chosen:Dictionary={}
	for index:int in fields.size():
		var field:Dictionary=fields[index]
		if String(field.id)==id:chosen=field;archive_picker.select(index)
	if chosen.is_empty():return
	var changed:=archive_selected!=id
	if changed:archive_browse=false;archive_query="";archive_page=0
	archive_selected=id
	for field_id:String in archive_buttons:(archive_buttons[field_id] as Button).set_pressed_no_signal(field_id==id)
	for child:Node in archive_detail.get_children():archive_detail.remove_child(child);child.queue_free()
	archive_detail.add_child(_voice(String(chosen.name),28))
	_line(archive_detail,"%s known" % String(chosen.count),14,T.TEXT_SOFT)
	for section:Dictionary in chosen.get("sections",[]):
		if String(section.get("heading","")).begins_with("Findings"):
			archive_findings=section.get("items",[])
			_archive_findings(archive_detail)
			continue
		var effects:=VBoxContainer.new();effects.add_theme_constant_override("separation",6);effects.visible=not archive_browse
		if archive_browse:
			var show:=_button(archive_detail,"Show current effects",func()->void:effects.visible=not effects.visible,"Read this field's current benefits beside the archive.");show.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;T.apply_button_style(show)
		archive_detail.add_child(effects)
		var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_top",12);effects.add_child(margin)
		margin.add_child(_voice(String(section.get("heading","")),20))
		var grid:=GridContainer.new();grid.name="EffectCategories";grid.columns=2 if size.x>=1000 else 1;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",10);effects.add_child(grid)
		for item:Dictionary in section.get("items",[]):
			var tile:=VBoxContainer.new();tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(tile)
			_line(tile,String(item.label),13,T.TEXT_SOFT)
			var fact:=_line(tile,String(item.value),22,tone_color(String(item.get("tone",""))) if String(item.get("tone",""))!="" else T.BODY)
			tile.tooltip_text=String(item.get("tip",""));fact.mouse_filter=Control.MOUSE_FILTER_PASS
	if data.has("unapplied"):
		var note:Dictionary=data.unapplied
		var hint:=_line(archive_detail,String(note.label),14,T.TEXT_SOFT);hint.tooltip_text=String(note.tip);hint.mouse_filter=Control.MOUSE_FILTER_PASS
	if changed:archive_reader.scroll_vertical=0
	if notify and data.get("on_select") is Callable:(data.on_select as Callable).call(id)

func _archive_findings(parent:Node)->void:
	var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_top",12);parent.add_child(margin)
	archive_result_heading=_voice("",20);margin.add_child(archive_result_heading)
	if archive_browse:
		var search:=LineEdit.new();search.name="FindingSearch";search.placeholder_text="Search this field's findings";search.text=archive_query;search.custom_minimum_size.y=40;parent.add_child(search)
		search.text_changed.connect(func(value:String)->void:archive_query=value;archive_page=0;_render_findings())
	archive_results=VBoxContainer.new();archive_results.name="Findings";archive_results.add_theme_constant_override("separation",6);parent.add_child(archive_results)
	archive_page_label=null
	if archive_browse:
		var pager:=HBoxContainer.new();pager.add_theme_constant_override("separation",8);parent.add_child(pager)
		archive_previous=_button(pager,"Previous",func()->void:archive_page-=1;_render_findings(),"Previous six findings");T.apply_button_style(archive_previous)
		archive_page_label=T.make_label("",14,T.TEXT_SOFT);archive_page_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pager.add_child(archive_page_label)
		archive_next=_button(pager,"Next",func()->void:archive_page+=1;_render_findings(),"Next six findings");T.apply_button_style(archive_next)
	var toggle:=_button(parent,"Back to overview" if archive_browse else "Browse all %d findings" % archive_findings.size(),func()->void:archive_browse=not archive_browse;select_archive(archive_selected,false),"Search every finding without leaving this field.");toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;T.apply_button_style(toggle)
	_render_findings()

func _render_findings()->void:
	for child:Node in archive_results.get_children():archive_results.remove_child(child);child.queue_free()
	var matches:Array=archive_findings.filter(func(item:Dictionary)->bool:return archive_query.is_empty() or archive_query.to_lower() in (String(item.label)+" "+String(item.get("value",""))+" "+String(item.get("tip",""))).to_lower()) if archive_browse else archive_findings
	var pages:=maxi(1,ceili(float(matches.size())/FINDINGS_PER_PAGE));archive_page=clampi(archive_page,0,pages-1)
	archive_result_heading.text="Findings · %d matches" % matches.size() if archive_browse else "Recent findings · %d in all" % archive_findings.size()
	var shown:Array=matches.slice(archive_page*FINDINGS_PER_PAGE,(archive_page+1)*FINDINGS_PER_PAGE) if archive_browse else matches.slice(0,3)
	for item:Dictionary in shown:
		var fact:=_line(archive_results,String(item.label)+" · "+String(item.value),16,T.BODY);fact.tooltip_text=String(item.get("tip",""));fact.mouse_filter=Control.MOUSE_FILTER_PASS
	if shown.is_empty():_line(archive_results,"No findings match this search.",16,T.TEXT_SOFT)
	if archive_page_label:
		archive_page_label.text="%d / %d" % [archive_page+1,pages];archive_previous.disabled=archive_page==0;archive_next.disabled=archive_page>=pages-1

func view_state()->Dictionary:
	return {"archive_open":archive_open,"archive_selected":archive_selected,"archive_browse":archive_browse,"archive_query":archive_query,"archive_page":archive_page} if archive_body else {"domain":String(data.get("domain","")),"question_query":question_query,"question_filter":question_filter,"question_page":question_page}

func restore_view_state(state:Dictionary)->void:
	if archive_body and state.has("archive_selected"):
		if overview:_show_archive(bool(state.get("archive_open",false)))
		archive_selected=String(state.archive_selected);archive_browse=bool(state.get("archive_browse",false));archive_query=String(state.get("archive_query",""));archive_page=int(state.get("archive_page",0));select_archive(archive_selected,false)
	elif question_grid and String(state.get("domain",""))==String(data.get("domain","")):
		question_query=String(state.get("question_query",""));question_filter=String(state.get("question_filter","open"));question_page=int(state.get("question_page",0));question_search.text=question_query;question_status.select(["open","known","waiting","all"].find(question_filter));_render_questions()

func _voice(text:String,font_size:int)->Label:
	var label:=super._voice(text,font_size)
	label.add_theme_font_override("font",T.font("ui_strong"))
	return label

func _build_overview(parent:Node)->void:
	var heading:=_line(parent,"What research changes",20,T.INK);heading.name="ResearchComparisonHeading"
	var legend:=_line(parent,"Unlocked = from discoveries   ·   Active now = applying today",13,T.TEXT_SOFT);legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	legend.tooltip_text="Effect points are modifiers, not research progress or a direct percentage of final output. 1 point means 0.01 of the named modifier. Adoption, supplies, focus and limits affect what applies today."
	overview=BoxContainer.new();overview.vertical=true;overview.name="ResearchOverview";overview.add_theme_constant_override("separation",18);parent.add_child(overview)
	overview_totals=GridContainer.new();overview_totals.name="AllEffectTotals";overview_totals.size_flags_horizontal=Control.SIZE_EXPAND_FILL;overview_totals.add_theme_constant_override("h_separation",18);overview_totals.add_theme_constant_override("v_separation",18);overview.add_child(overview_totals)
	var groups:={}
	var names:={"nutrition":"Food & farming","health":"Health & care","labor":"Work","production":"Craft & materials","infrastructure":"Buildings","logistics":"Storage & transport","institutions":"Organization","knowledge":"Learning","security":"Military","ecology":"Land & resources","demography":"People & homes","culture":"Culture"}
	var explainer=preload("res://scripts/effect_explainer.gd")
	for row:Dictionary in data.get("totals",[]):
		var group:=String(explainer.line(String(row.id)))
		if not groups.has(group):groups[group]=[]
		groups[group].append(row)
	for group:String in names:
		if not groups.has(group):continue
		var panel:=PanelContainer.new();panel.name="EffectGroup_"+group;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;panel.add_theme_stylebox_override("panel",T.paper_panel_style(false,T.RADIUS_CARD,12));overview_totals.add_child(panel);effect_groups.append(panel);panel.set_meta("weight",groups[group].size()+1)
		var list:=VBoxContainer.new();list.add_theme_constant_override("separation",14);panel.add_child(list)
		_line(list,String(names[group]),18,T.INK)
		for row:Dictionary in groups[group]:
			var meter:=preload("res://scripts/hud/research_effect_meter.gd").new();list.add_child(meter);meter.setup(row)
	if data.get("totals",[]).is_empty():_line(overview_totals,"No additive effects unlocked yet.",16,T.TEXT_SOFT)
	var recent:=VBoxContainer.new();recent.name="LatestThree";recent.size_flags_horizontal=Control.SIZE_EXPAND_FILL;recent.size_flags_stretch_ratio=.65;recent.add_theme_constant_override("separation",10);overview.add_child(recent)
	_line(recent,"Last three discoveries",20,T.INK)
	recent_grid=GridContainer.new();recent_grid.add_theme_constant_override("h_separation",18);recent_grid.add_theme_constant_override("v_separation",10);recent.add_child(recent_grid)
	for row:Dictionary in data.get("recent",[]).slice(0,3):
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;recent_grid.add_child(cell)
		_line(cell,String(row.label),17,T.INK).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_line(cell,preload("res://scripts/hud/era_words.gd").ago(int(row.day)) if int(row.day)>=0 else "Date not recorded",12,T.TEXT_SOFT)
		_line(cell,String(row.get("effect","")).replace(" pp"," points") if not String(row.get("effect","")).is_empty() else "Opens later knowledge",14,T.TEAL).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if data.get("recent",[]).is_empty():_line(recent,"Discoveries will appear here after they are proven.",14,T.TEXT_SOFT)
	archive_toggle=_button(parent,"Open full archive",func()->void:_show_archive(not archive_open),"Browse every field and finding");T.apply_button_style(archive_toggle);archive_toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN

func _arrange_effect_groups(wanted:int)->void:
	if effect_groups.is_empty():return
	var count:=mini(wanted,effect_groups.size())
	if effect_column_count==count:return
	effect_column_count=count
	# Retain meters while reflowing groups into the shortest column. A short
	# category must not reserve a whole row beside a much longer category.
	for panel:Control in effect_groups:panel.get_parent().remove_child(panel)
	for child:Node in overview_totals.get_children():overview_totals.remove_child(child);child.queue_free()
	overview_totals.columns=count
	var heights:Array[int]=[]
	for i in count:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;column.add_theme_constant_override("separation",18);overview_totals.add_child(column);heights.append(0)
	for panel:Control in effect_groups:
		var index:=heights.find(heights.min())
		overview_totals.get_child(index).add_child(panel)
		heights[index]+=int(panel.get_meta("weight",1))

func _show_archive(open:bool)->void:
	archive_open=open;overview.visible=not open;archive_body.visible=open
	archive_toggle.text="Back to totals & last three" if open else "Open full archive"
	_arrange()
