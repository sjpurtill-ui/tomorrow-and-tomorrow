extends "res://scripts/hud/home_ledger.gd"
## OUR TOWN'S PAGE, the Settlement dock's first tab. The town drawn in ink
## from its own figures with our banner at the gate; one plain line in the
## local leader's voice beside their face, with the one way to ask for more
## hands; then every figure in four groups as a stranger's town is told,
## exact because it is ours, each laid against the bands of the foreign towns
## our scouts have seen. Hovering a row lights its part of the drawing;
## clicking it opens the page that owns the figure. The New towns switch, the
## water and waste works and the town's own reports follow.
## The rows come from own_town_model.gd; nothing here reads the ledger.
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
## The painted plates the culture, inquiry and chronicle boards draw from
## (they extend this page for its shared pieces).
const Buildings:=preload("res://scripts/hud/construction_art.gd")
const Food:=preload("res://scripts/hud/provisions_art.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const Held:=preload("res://scripts/hud/held_town_dossier.gd")
## The drawing inks itself in once per town, not on every daily refresh.
static var last_revealed:=""
var sketch:OwnSketch
var grid:GridContainer
## The drawing and the leader, side by side on a wide page, stacked on a narrow one.
var spread:BoxContainer
## The daily refresh (update_block) keeps every node while the page keeps its
## shape (the same leader, choices, figures, works) and writes the day's
## figures, words and drawing into them.
var _page_shape:Array=[]
var _page_refs:Dictionary={}

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="SettlementOverview";add_theme_constant_override("separation",14)
	_page_shape=shape_of(block)
	_page_refs={"rows":[],"progress":[],"offers":[]}
	spread=BoxContainer.new();spread.name="Spread";spread.add_theme_constant_override("separation",22);add_child(spread)
	var drawing:Dictionary=block.get("sketch",{})
	if not drawing.is_empty():_sketch(drawing,spread)
	_leader(block,spread)
	var leader:Dictionary=block.get("leader",{})
	var first:=String(leader.get("name","")).get_slice(" ",0)
	if bool(block.get("ruler_sets_work",false)):
		# The ruler sets the daily work (manual_work.gd): no leader can shift
		# hands; one click hands it back, and The People is where it is set.
		# What the ruler's split does to this town's food, early and plainly
		# (manual_work.town_warning), with the click that mends it.
		var warning:Dictionary=block.get("work_warning",{})
		if not warning.is_empty():
			var warned:=T.make_label(String(warning.get("text","")),13,tone_color(String(warning.get("tone","warn"))))
			warned.name="SplitWarning";warned.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(warned)
			_page_refs["warning"]=warned
		var yours:=HFlowContainer.new();yours.name="RulerSetsWork";yours.add_theme_constant_override("h_separation",6);yours.add_theme_constant_override("v_separation",6);add_child(yours)
		var said:=T.make_label("You set the daily work yourself.",13,T.BODY);said.size_flags_vertical=Control.SIZE_SHRINK_CENTER;yours.add_child(said)
		var fix:Variant=block.get("on_food_fix")
		if fix is Callable and (fix as Callable).is_valid() and String(warning.get("fix_text",""))!="":
			var mend:=_button(yours,String(warning.fix_text),fix,"Every town gets as many more on getting food, each taken from the task with the most people.");mend.name="FoodFix"
			_page_refs["fix"]=mend
		_button(yours,"Back to our leaders",block.get("on_leaders"),"Each town's leader shares out the work again, food and water first.").name="BackToLeaders"
		_button(yours,"Set the work",block.get("on_people"),"Move people between tasks in The People.").name="SetTheWork"
		for chip in yours.get_children():
			if chip is Button:
				(chip as Button).custom_minimum_size.y=26
				(chip as Button).add_theme_font_size_override("font_size",12)
	elif bool(block.get("can_direct",false)):
		var ask:=_choices(self,"Ask %s for more hands on" % (first if not first.is_empty() else "the leader"),block.get("choices",[]),String(block.get("current","")))
		ask.name="AskForHands"
		# One compact row under the leader's word.
		for chip in ask.get_children():
			if chip is Button:
				(chip as Button).custom_minimum_size.y=26
				(chip as Button).add_theme_font_size_override("font_size",12)
	var groups:Array=block.get("groups",[])
	if not groups.is_empty():_groups(groups,block.get("legend",[]),String(block.get("town_name","")))
	var founding:Dictionary=block.get("founding",{})
	if not founding.is_empty():_new_towns(founding)
	var works:Dictionary=block.get("works",{})
	if not works.is_empty():_works(works)
	_rule(self)
	var footer:=HFlowContainer.new();footer.name="Reports";footer.add_theme_constant_override("h_separation",8);add_child(footer)
	_button(footer,"Ages and families",block.get("on_population"),"How many children, workers and elders live here")
	_button(footer,"Rename this place",block.get("on_rename"),"Change the name on the map")
	resized.connect(_layout);_layout()

## The live refresh: while the page keeps its shape, the drawing, the
## leader's words, every figure and the works take the day's values in place;
## a page of another shape is drawn afresh.
func update_block(block:Dictionary)->bool:
	if name!="SettlementOverview" or _page_refs.is_empty() or shape_of(block)!=_page_shape:return false
	data=block
	if sketch!=null:
		sketch.data=block.get("sketch",{});sketch.queue_redraw()
	var leader:Dictionary=block.get("leader",{})
	if _page_refs.has("office"):_put(_page_refs.office,_office_words(leader))
	if _page_refs.has("lead"):_put(_page_refs.lead,String(block.get("lead","")))
	if _page_refs.has("direction"):
		_put(_page_refs.direction,String(block.get("direction","")))
		(_page_refs.direction as Control).tooltip_text=String(block.get("direction_tip",""))
	var warning:Dictionary=block.get("work_warning",{})
	if _page_refs.has("warning"):_put(_page_refs.warning,String(warning.get("text","")),tone_color(String(warning.get("tone","warn"))))
	var rows:Array=[]
	for group:Dictionary in block.get("groups",[]):rows.append_array(group.rows)
	for index in mini(rows.size(),(_page_refs.rows as Array).size()):_fill_row(_page_refs.rows[index],rows[index])
	var founding:Dictionary=block.get("founding",{})
	if _page_refs.has("founding"):_put(_page_refs.founding,String(founding.get("words","")))
	var works:Dictionary=block.get("works",{})
	var progress:Array=works.get("progress",[])
	for index in mini(progress.size(),(_page_refs.progress as Array).size()):_put(_page_refs.progress[index],String(progress[index]))
	var offers:Array=works.get("offers",[])
	for index in mini(offers.size(),(_page_refs.offers as Array).size()):
		var offer:Dictionary=offers[index];var refs:Dictionary=_page_refs.offers[index]
		var ready:=String(offer.get("blocked","")).is_empty()
		_put(refs.title,String(offer.title));_put(refs.sentence,String(offer.sentence))
		_put(refs.cost,String(offer.cost) if ready else String(offer.blocked),T.MUTED if ready else tone_color("warn"))
		(refs.start as Button).tooltip_text=String(offer.cost) if ready else String(offer.blocked)
	return true

## What the page's nodes are: the drawing's town, the leader's picture and
## name, the work switch and choices, each figure's key and parts, the
## legend, the New towns switch, the works on offer and the footer's actions.
static func shape_of(block:Dictionary)->Array:
	var leader:Dictionary=block.get("leader",{})
	var drawing:Dictionary=block.get("sketch",{})
	var choices:Array=[]
	for choice:Dictionary in block.get("choices",[]):choices.append([String(choice.get("id","")),String(choice.get("label","")),String(choice.get("tip","")),callable_key(choice.get("on_press"))])
	var rows:Array=[]
	for group:Dictionary in block.get("groups",[]):
		var keys:Array=[String(group.title)]
		for row:Dictionary in group.rows:keys.append([String(row.key),bool(row.get("bar",true)),String(row.get("note",""))!="",String(row.get("note_tone","muted")),callable_key(row.get("on_open")),row.get("section",""),row.get("sub",0)])
		rows.append(keys)
	var founding:Dictionary=block.get("founding",{})
	var founding_shape:Array=[] if founding.is_empty() else [founding.get("options",[]),bool(founding.get("on",true))]
	var works:Dictionary=block.get("works",{})
	var works_shape:Array=[]
	if not works.is_empty():
		works_shape=[(works.get("progress",[]) as Array).size()]
		for offer:Dictionary in works.get("offers",[]):works_shape.append([String(offer.get("id","")),String(offer.get("action","")),String(offer.get("blocked","")).is_empty(),callable_key(offer.get("on_press"))])
	return [not drawing.is_empty(),String(drawing.get("city_id","")),leader.is_empty(),Portrait.picture_key(leader) if not leader.is_empty() else [],String(leader.get("name","No leader yet")),
		String(block.get("lead",""))!="",bool(block.get("ruler_sets_work",false)),bool(block.get("can_direct",false)),choices,String(block.get("current","")),
		callable_key(block.get("on_leaders")),callable_key(block.get("on_people")),callable_key(block.get("on_leader")),callable_key(block.get("on_population")),callable_key(block.get("on_rename")),
		# A split warning appearing or going, or its fix changing, redraws the
		# page; the warning's words update in place.
		not (block.get("work_warning",{}) as Dictionary).is_empty(),callable_key(block.get("on_food_fix")),String((block.get("work_warning",{}) as Dictionary).get("fix_text","")),
		rows,block.get("legend",[]),String(block.get("town_name","")),founding_shape,works_shape]

# --------------------------------------------------------------------------
# The drawing
# --------------------------------------------------------------------------

func _sketch(drawing:Dictionary,parent:Node)->void:
	sketch=OwnSketch.new();sketch.name="TownSketch";sketch.data=drawing;sketch.custom_minimum_size=Vector2(300,212)
	sketch.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sketch.size_flags_stretch_ratio=1.55;parent.add_child(sketch)
	var id:=String(drawing.get("city_id",""))
	if id!=last_revealed:
		last_revealed=id
		sketch.reveal=0.0
		if sketch.is_inside_tree():sketch.ink_in()
		else:sketch.ready.connect(sketch.ink_in,CONNECT_ONE_SHOT)

## Lights the row's part of the drawing (key "" puts it out).
func light(key:String)->void:
	if sketch==null:return
	sketch.highlight=String(OwnSketch.LIGHTS.get(key,key))
	sketch.queue_redraw()

# --------------------------------------------------------------------------
# The local leader: their face and their word on the town
# --------------------------------------------------------------------------

func _leader(block:Dictionary,parent:Node)->void:
	var leader:Dictionary=block.get("leader",{})
	var first:=String(leader.get("name","")).get_slice(" ",0)
	var column:=VBoxContainer.new();column.name="Leader";column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.size_flags_stretch_ratio=1.0;column.add_theme_constant_override("separation",10);parent.add_child(column)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);column.add_child(head)
	if not leader.is_empty():
		var face:=Portrait.picture(leader,84,96);face.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;head.add_child(face)
	var named:=VBoxContainer.new();named.size_flags_horizontal=Control.SIZE_EXPAND_FILL;named.add_theme_constant_override("separation",2);head.add_child(named)
	named.add_child(T.make_label("LOCAL LEADER",12,T.GOLD_TEXT))
	named.add_child(_voice(String(leader.get("name","No leader yet")),22))
	var office:=T.text(Label.new(),"small",T.INK_MUTED) as Label
	office.text=_office_words(leader)
	office.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;named.add_child(office)
	if not _page_refs.is_empty():_page_refs["office"]=office
	var talk:=_button(named,"Talk with %s in court" % first if not first.is_empty() else "Open the court",block.get("on_leader"),"Call the leader to the court to talk, give orders or replace them")
	talk.name="TalkWithLeader";talk.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var lead:=String(block.get("lead",""))
	if lead!="":
		var quote:=PanelContainer.new();quote.name="Lead"
		var rule:=StyleBoxFlat.new();rule.bg_color=Color.TRANSPARENT;rule.border_color=T.GOLD;rule.border_width_left=2;rule.content_margin_left=14;rule.content_margin_top=1;rule.content_margin_bottom=1
		quote.add_theme_stylebox_override("panel",rule);column.add_child(quote)
		var words:=Label.new();words.name="LeadWords";words.text=lead;words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		T.text(words,"voice_small",T.BODY);words.add_theme_font_override("font",T.voice_font(true));quote.add_child(words)
		if not _page_refs.is_empty():_page_refs["lead"]=words
	var direction:=_line(column,String(block.get("direction","")),13,T.BODY)
	direction.name="Direction";direction.tooltip_text=String(block.get("direction_tip",""));direction.mouse_filter=Control.MOUSE_FILTER_PASS
	if not _page_refs.is_empty():_page_refs["direction"]=direction

static func _office_words(leader:Dictionary)->String:
	return ("%s, age %d" % [String(leader.get("title","Local leader")),int(leader.get("age",0))]) if not leader.is_empty() else "The government appoints one of the people."

# --------------------------------------------------------------------------
# The figures, in four groups
# --------------------------------------------------------------------------

func _groups(groups:Array,legend:Array,own_name:String)->void:
	_rule(self)
	if not legend.is_empty():
		var key:=HFlowContainer.new();key.name="Legend";key.add_theme_constant_override("h_separation",14);key.add_theme_constant_override("v_separation",4);add_child(key)
		var lead:=T.text(Label.new(),"small",T.INK_MUTED) as Label;lead.text="Compared with the towns our scouts have seen:";key.add_child(lead)
		key.add_child(_swatch(own_name if own_name!="" else "Ours",T.GOLD,"Our own figure, exact."))
		for town:Dictionary in legend:key.add_child(_swatch(String(town.name),Color(town.color),"%s, seen %s. Its band runs from the least to the most our scouts reckoned." % [String(town.name),String(town.seen)]))
	grid=GridContainer.new();grid.name="Figures";grid.columns=2;grid.add_theme_constant_override("h_separation",30);grid.add_theme_constant_override("v_separation",16);add_child(grid)
	for group:Dictionary in groups:
		var box:=VBoxContainer.new();box.name="Group_"+String(group.title).to_pascal_case();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",0);grid.add_child(box)
		var kicker:=T.text(Label.new(),"kicker",T.INK_MUTED) as Label;kicker.text=String(group.title);box.add_child(kicker)
		var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size.y=1;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(rule)
		for row:Dictionary in group.rows:box.add_child(_row(row))

func _swatch(label:String,color:Color,tip:String)->Control:
	var item:=HBoxContainer.new();item.add_theme_constant_override("separation",6);item.tooltip_text=tip;item.mouse_filter=Control.MOUSE_FILTER_PASS
	var mark:=ColorRect.new();mark.color=color;mark.custom_minimum_size=Vector2(16,4);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(mark)
	var name_label:=T.text(Label.new(),"small",T.BODY) as Label;name_label.text=label;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(name_label)
	return item

func _row(row:Dictionary)->Control:
	var key:=String(row.key)
	var panel:=PanelContainer.new();panel.name="Row_"+key;panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.tooltip_text=String(row.get("tip",""))
	var idle:=StyleBoxFlat.new();idle.bg_color=Color.TRANSPARENT;idle.set_content_margin_all(7);idle.content_margin_left=4;idle.content_margin_right=4
	var lit:StyleBoxFlat=idle.duplicate();lit.bg_color=T.GOLD_WASH
	panel.add_theme_stylebox_override("panel",idle)
	var action:Variant=row.get("on_open")
	if action is Callable and (action as Callable).is_valid():
		panel.focus_mode=Control.FOCUS_ALL;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event:InputEvent)->void:
			var mouse:=event as InputEventMouseButton
			if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
				panel.accept_event();(action as Callable).call()
			elif event.is_action_pressed("ui_accept"):
				panel.accept_event();(action as Callable).call())
	var on:=func()->void:
		panel.add_theme_stylebox_override("panel",lit)
		light(key)
	var off:=func()->void:
		panel.add_theme_stylebox_override("panel",idle)
		if sketch!=null and sketch.highlight==String(OwnSketch.LIGHTS.get(key,key)):light("")
	panel.mouse_entered.connect(on);panel.focus_entered.connect(on)
	panel.mouse_exited.connect(off);panel.focus_exited.connect(off)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(line)
	var icon:=TextureRect.new();icon.texture=V.tinted(key,V.accent(key));icon.custom_minimum_size=Vector2(22,22);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(icon)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",4);body.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(body)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",8);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(top)
	var label:=T.text(Label.new(),"body",T.INK) as Label;label.name="Name";label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.clip_text=true;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(label)
	var value:=T.text(Label.new(),"body",T.INK) as Label;value.name="Value";value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(value)
	var refs:={"panel":panel,"name":label,"value":value,"bar":null,"note":null}
	if bool(row.get("bar",true)):
		var bar:=OwnScale.new();bar.name="Scale";body.add_child(bar);refs.bar=bar
	if String(row.get("note",""))!="":
		var note:=T.text(Label.new(),"small",tone_color(String(row.get("note_tone","muted")))) as Label;note.name="Note";note.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(note);refs.note=note
	_fill_row(refs,row)
	if not _page_refs.is_empty():(_page_refs.rows as Array).append(refs)
	return panel

## A figure's words and scale, for the first drawing and every refresh.
func _fill_row(refs:Dictionary,row:Dictionary)->void:
	(refs.panel as Control).tooltip_text=String(row.get("tip",""))
	_put(refs.name,String(row.name))
	_put(refs.value,String(row.value))
	if refs.bar!=null:
		var bar:OwnScale=refs.bar
		var marks:Array=row.get("marks",[]) if bool(row.get("bands",true)) else []
		if bar.own!=float(row.get("own",0.0)) or bar.top!=maxf(0.0001,float(row.get("top",1.0))) or bar.marks!=marks:
			bar.own=float(row.get("own",0.0));bar.top=maxf(0.0001,float(row.get("top",1.0)));bar.marks=marks
	if refs.note!=null:_put(refs.note,String(row.note))

func _layout()->void:
	if spread:spread.vertical=size.x<760
	if grid:grid.columns=2 if size.x>=720 else 1

## Shared with the boards that extend this page.
func _serif(value:String,font_size:int)->Label:
	return _voice(value,font_size)
func _note(parent:Node,value:String)->void:
	_line(parent,value,13,T.BODY)

# --------------------------------------------------------------------------
# New towns, and the water and waste works
# --------------------------------------------------------------------------

## New towns (auto_founding.gd): whether our leaders found them on their own,
## said in plain words, and the one click that changes it. The same switch as
## the court's word and the "Our course" page.
func _new_towns(founding:Dictionary)->void:
	_rule(self)
	var box:=VBoxContainer.new();box.name="NewTowns";box.add_theme_constant_override("separation",6);add_child(box)
	box.add_child(_voice(String(founding.get("title","New towns")),20))
	var words:=_line(box,String(founding.get("words","")),13,T.BODY);words.name="NewTownsWords"
	if not _page_refs.is_empty():_page_refs["founding"]=words
	if not (founding.get("options",[]) as Array).is_empty():
		_choices(box,"",founding.get("options",[]),"leaders" if bool(founding.get("on",true)) else "ruler").name="NewTownsChoice"

## Water and waste works: what is built, and what can be started, each with
## its cost and time and one verb.
func _works(works:Dictionary)->void:
	_rule(self)
	var box:=VBoxContainer.new();box.name="WaterWorks";box.add_theme_constant_override("separation",8);add_child(box)
	box.add_child(T.make_label("WATER AND WASTE WORKS",12,T.GOLD_TEXT))
	for line:String in works.get("progress",[]):
		var said:=_line(box,line,13,T.BODY)
		if not _page_refs.is_empty():(_page_refs.progress as Array).append(said)
	if (works.get("progress",[]) as Array).is_empty():
		var none:=_line(box,"Nothing is built yet.",13,T.MUTED)
		none.tooltip_text="Clean water, and waste kept apart from it, mean fewer sick.";none.mouse_filter=Control.MOUSE_FILTER_PASS
	for offer:Dictionary in works.get("offers",[]):
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);box.add_child(row)
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
		var title:=_voice(String(offer.title),18);text.add_child(title)
		var sentence:=_line(text,String(offer.sentence),13,T.BODY)
		var ready:=String(offer.get("blocked","")).is_empty()
		var cost:=_line(text,String(offer.cost) if ready else String(offer.blocked),13,T.MUTED if ready else tone_color("warn"))
		var start:=_button(row,String(offer.action),offer.get("on_press"),String(offer.cost) if ready else String(offer.blocked))
		start.name="Start_"+String(offer.id).replace(":","_");start.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		if not _page_refs.is_empty():(_page_refs.offers as Array).append({"title":title,"sentence":sentence,"cost":cost,"start":start})

# --------------------------------------------------------------------------
# Drawing classes
# --------------------------------------------------------------------------

## A figure against its scale: our own exact figure as a gold rule from
## nothing, and each foreign town's estimate as a thin band in its people's
## colour below it (the reverse of the gold home mark on their pages).
class OwnScale extends Control:
	var own:=0.0
	var top:=1.0
	var marks:Array=[]:
		set(value):marks=value;custom_minimum_size.y=10.0+5.0*marks.size();queue_redraw()
	func _init()->void:
		custom_minimum_size.y=10;mouse_filter=MOUSE_FILTER_IGNORE
	## Inset so the ends of a full or empty bar are never cut by the edge.
	const PAD:=3.0
	func _at(value:float)->float:
		return PAD+clampf(value/top,0.0,1.0)*maxf(1.0,size.x-PAD*2.0)
	func _draw()->void:
		var mid:=4.0
		draw_line(Vector2(PAD,mid),Vector2(size.x-PAD,mid),T.RULE,1.0)
		for tick in 5:
			var tx:=_at(top*tick/4.0)
			draw_line(Vector2(tx,mid-2),Vector2(tx,mid+2),T.RULE,1.0)
		var x:=_at(own)
		if x>PAD+0.5:draw_rect(Rect2(PAD,mid-2,x-PAD,4),Color(T.GOLD,.82))
		draw_line(Vector2(x,mid-4),Vector2(x,mid+4),T.GOLD,2.0)
		for index in marks.size():
			var mark:Dictionary=marks[index]
			var y:=mid+7.0+index*5.0
			var a:=_at(float(mark.low));var b:=_at(float(mark.high))
			var ink:=Color(Color(mark.color),.85)
			if b-a<3.0:draw_circle(Vector2((a+b)*.5,y),2.2,ink)
			else:
				draw_rect(Rect2(a,y-1.5,b-a,3),ink)
				draw_circle(Vector2(a,y),1.8,ink);draw_circle(Vector2(b,y),1.8,ink)

## Our own town as the held-town sketch draws it, with our banner at the
## gate, plus what only we can see: the roofs still needed in pencil, the
## walls by what stands, the well, the shared works and the stores.
class OwnSketch extends Held.HeldSketch:
	## The part of the drawing each row lights.
	const LIGHTS:={"roofs":"roofs","works":"works","building":"works","water":"water","damage":"damage","fortification":"fortification","garrison":"garrison","supply":"supply","production":"production","logistics":"logistics","population":"population"}
	## Roofs lit: the ones still needed when some sleep out, else every roof.
	func _house(house:Dictionary)->void:
		if highlight!="roofs":
			super(house)
			return
		var people:=V.bounds(_field("population"))
		var needed:=people.y>people.x+0.5
		if not bool(house.sure):
			var x:=float(house.x);var y:=float(house.y);var s:=float(house.s)
			draw_rect(Rect2(x-s,y-s*.9,s*2,s*.9),Color(T.GOLD,.9),false,1.3)
			draw_polyline(PackedVector2Array([Vector2(x-s*1.25,y-s*.9),Vector2(x,y-s*2.0),Vector2(x+s*1.25,y-s*.9),Vector2(x-s*1.25,y-s*.9)]),Color(T.GOLD,.9),1.3,true)
			return
		if needed:
			highlight="";super(house);highlight="roofs"
		else:
			highlight="population";super(house);highlight="roofs"
	func _before_houses(w:float,h:float,ground:float,cx:float,spread:float)->void:
		var works:Array=data.get("works",[])
		var ink:=_stroke("works",Color(T.INK,.85*reveal))
		var strip:=ground+1.0
		# The hearth, ringed with stones, where the people gather.
		if works.has("Hearth Circle"):
			var at:=Vector2(cx-spread*0.15,strip)
			for i in 9:
				var angle:=TAU*i/9.0
				draw_circle(at+Vector2(cos(angle)*7.0,sin(angle)*2.6),1.3,ink)
			draw_polyline(PackedVector2Array([at+Vector2(-2,0),at+Vector2(-1,-5),at+Vector2(0,-2),at+Vector2(1.5,-7),at+Vector2(2.5,0)]),_stroke("works",Color(T.AMBER,.9*reveal)),1.2,true)
		# Pits dug for keeping food.
		if works.has("Storage Pits"):
			for i in 3:draw_arc(Vector2(cx+spread*0.85+i*9.0,strip+1.0),3.4,0.0,TAU,12,ink,1.1,true)
		# A yard for working stone and wood.
		if works.has("Open Work Area") or works.has("Gathering Yard"):
			var yard:=Rect2(cx-spread*1.35,strip-4.0,20,6)
			draw_rect(yard,ink,false,1.0)
			for i in 4:draw_line(Vector2(yard.position.x+i*6.5,yard.position.y),Vector2(yard.position.x+i*6.5,yard.position.y-3),ink,1.0,true)
		# The long hall and the counted stores stand behind the houses.
		if works.has("Framed Hall") or works.has("Public Stores"):
			var base:=Vector2(cx+spread*1.35,ground-h*.16)
			var body:=Rect2(base.x-22,base.y-10,44,10)
			draw_rect(body,Color(T.PAPER_RAISED,reveal));draw_rect(body,ink,false,1.2)
			draw_colored_polygon(PackedVector2Array([Vector2(body.position.x-5,body.position.y),Vector2(base.x,base.y-24),Vector2(body.end.x+5,body.position.y)]),Color(T.AMBER,.32*reveal))
			draw_polyline(PackedVector2Array([Vector2(body.position.x-5,body.position.y),Vector2(base.x,base.y-24),Vector2(body.end.x+5,body.position.y)]),ink,1.2,true)
		# The well: full when every one drinks enough.
		var water:=float(data.get("water",-1.0))
		if water>=0.0:
			var well:=Vector2(cx-spread*0.75,strip+1.0)
			var line:=_stroke("water",Color(T.INK,.85*reveal))
			draw_arc(well,6.0,0.0,TAU,18,line,1.2,true)
			draw_line(well+Vector2(-6,0),well+Vector2(-5,-12),line,1.1,true);draw_line(well+Vector2(6,0),well+Vector2(5,-12),line,1.1,true)
			draw_line(well+Vector2(-6,-12),well+Vector2(6,-12),line,1.1,true)
			var ripples:=clampi(roundi(water*3.0),0,3)
			for i in ripples:draw_arc(well,1.4+i*1.5,PI*1.1,PI*1.9,6,_stroke("water",Color(T.TEAL,.8*reveal)),1.0,true)
	func _draw()->void:
		super()
		var w:=size.x;var h:=size.y;var ground:=h*.70;var cx:=w*.56;var spread:=w*.13
		# Granaries for the months put by: a second and a third for long stores.
		var days:=float(data.get("food_days",-1.0))
		if days>=90.0:
			var more:=1 if days<240.0 else 2
			for i in more:
				var gx:=cx+spread*2.1+(i+1)*22.0;var r:=7.0
				draw_circle(Vector2(gx,ground-r),r,T.PAPER_RAISED);draw_arc(Vector2(gx,ground-r),r,0,TAU,24,_stroke("supply",T.INK),1.2,true)
				draw_colored_polygon(PackedVector2Array([Vector2(gx-r-2,ground-r),Vector2(gx,ground-r*2.8),Vector2(gx+r+2,ground-r)]),Color(T.AMBER,.45))
				draw_polyline(PackedVector2Array([Vector2(gx-r-2,ground-r),Vector2(gx,ground-r*2.8),Vector2(gx+r+2,ground-r)]),_stroke("supply",T.INK),1.2,true)
		# The levy, lit: a wash behind the spears at the gate.
		if highlight=="garrison" and not _field("garrison").is_empty():
			draw_circle(Vector2(cx-spread*2.9-18.0,ground+2.0),30.0,T.GOLD_WASH)
		_caption(w,h)
