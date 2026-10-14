extends VBoxContainer
## THE CHRONICLE PAGE: the people's history, the one place it is kept.
##
##   ┌ the count: every year a mark on a small spiral from the founding (a
##   │ picture for a year the people named, a bead for a year of trouble or
##   │ learning, a notch for a quiet one, a gold ring for the year in
##   │ progress), its key beneath it; choose a mark to open that year
##   ├ beside it the chosen year: its one label, its change in people with
##   │ the born, the buried and the rest as tokens, and the people's count
##   │ across the years with the year marked
##   ├ one row of chips filtering what is told by kind, each with its count
##   └ what is told, newest first, grouped under each year's line: a mark,
##     the telling's title and its season, one line each; a line opens in
##     place to its telling and its links (the report, the battle, the court)
##
## Data: content/dock_content_chronicle.gd, whose years come from
## hud/chronicle_year_model.gd (the same yearly change Home shows). The view
## (the chosen year, the filter, an opened line, how far back the list goes)
## survives a live refresh (view_state.gd).

const Chronicle:=preload("res://scripts/chronicle.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Model:=preload("res://scripts/hud/chronicle_year_model.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")
## Lines of the list before "Earlier years" (each press shows this many more).
const PAGE:=40
## The count's side.
const COUNT_SIDE:=176.0
const Dense:=preload("res://scripts/hud/dense_blocks.gd")
## A telling's line: its title (wrapping, never cut) and its season.
const LINE_COLUMNS:=[{"key":"title","wrap":true},{"key":"season","width":60,"align":"right"}]
## The kinds the list can be filtered to, each with its mark: [id, words, glyph].
const FILTERS:=[["all","Everything","hearth_count"],["loss","Deaths & troubles","death"],["war","War","war"],["learning","Learning","discovery"],
	["contact","Meetings & travel","contact"],["works","Works & customs","work"],["court","Court","court"]]

## The count of years: a spiral of marks from the founding outward.
class YearCount extends Control:
	signal picked(index:int)
	signal hovered(index:int)
	## The newest this many years are drawn; older ones fold into the centre.
	const MAX_MARKS:=400
	var years:Array=[]
	var chosen:=-1
	var hover:=-1
	var points:=PackedVector2Array()
	var step:=24.0
	var first:=0
	func _init()->void:
		custom_minimum_size=Vector2(210,210)
		mouse_filter=Control.MOUSE_FILTER_STOP
		mouse_exited.connect(func()->void: _set_hover(-1))
		resized.connect(func()->void: _place();queue_redraw())
	func configure(items:Array,chosen_index:int)->void:
		years=items;chosen=chosen_index;_place();queue_redraw()
	func choose(index:int)->void:
		if index==chosen: return
		chosen=index;queue_redraw()
	func _place()->void:
		points=PackedVector2Array()
		var center:=size*0.5
		var r_max:=minf(size.x,size.y)*0.5-12.0
		var r0:=16.0
		# As many of the newest years as the plate holds at a readable size;
		# older ones fold into the centre, where the founding mark stands.
		var fit:=maxi(12,floori(PI*(r_max*r_max-r0*r0)/(1.2*81.0))-3)
		first=maxi(0,years.size()-mini(MAX_MARKS,fit))
		var n:=years.size()-first
		if n<=0 or size.x<=0.0 or size.y<=0.0: return
		# Marks as large as the plate allows: an Archimedean spiral whose marks
		# are `step` apart along the curve and whose turns are 1.2 steps apart.
		step=clampf(sqrt(PI*(r_max*r_max-r0*r0)/(1.2*float(n)+3.0)),9.0,30.0)
		var b:=step*1.2/TAU
		var theta:=r0/b
		for i in n:
			var r:=b*theta
			points.append(center+Vector2(cos(theta-PI*0.5),sin(theta-PI*0.5))*r)
			theta+=step/sqrt(r*r+b*b)
	func index_at(at:Vector2)->int:
		var best:=-1
		var best_d:=step*0.62
		for i in points.size():
			var d:=points[i].distance_to(at)
			if d<best_d: best_d=d;best=first+i
		return best
	func _set_hover(index:int)->void:
		if index==hover: return
		hover=index;queue_redraw();hovered.emit(index)
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseMotion:
			_set_hover(index_at((event as InputEventMouseMotion).position))
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			var index:=index_at((event as InputEventMouseButton).position)
			if index>=0:
				picked.emit(index)
				accept_event()
	func _get_tooltip(at:Vector2)->String:
		var index:=index_at(at)
		if index<0: return ""
		return Page.mark_caption(years[index])
	func _draw()->void:
		var center:=size*0.5
		var radius:=minf(size.x,size.y)*0.5-4.0
		# The plate: raised paper and a ruled rim, like the Standing rose.
		draw_circle(center,radius,Color(T.PAPER_RAISED,0.96))
		draw_arc(center,radius,0.0,TAU,120,T.RULE_STRONG,1.4,true)
		draw_arc(center,radius-5.0,0.0,TAU,120,T.RULE,1.0,true)
		if points.is_empty(): return
		# The thread from the founding to now.
		var thread:=PackedVector2Array([center])
		thread.append_array(points)
		draw_polyline(thread,T.RULE,1.3,true)
		var founding:=Page.mark_texture("founding",64)
		var fs:=step*1.15
		draw_texture_rect(founding,Rect2(center-Vector2(fs,fs)*0.5,Vector2(fs,fs)),false)
		for i in points.size():
			var index:=first+i
			var p:=points[i]
			var year:Dictionary=years[index]
			var along:=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
			if along==Vector2.ZERO: along=Vector2.RIGHT
			var across:=Vector2(-along.y,along.x)
			var lifted:=1.3 if index==hover else 1.0
			var glyph:=String(year.get("glyph","quiet"))
			if not bool(year.get("closed",true)):
				# The year in progress: an open ring, with what it holds so far.
				draw_arc(p,step*0.5,0.0,TAU,36,T.GOLD,1.6,true)
				if glyph!="quiet":
					var s_now:=step*0.72*lifted
					draw_texture_rect(Page.mark_texture(glyph,64),Rect2(p-Vector2(s_now,s_now)*0.5,Vector2(s_now,s_now)),false,Color(1,1,1,0.85))
			elif String(year.get("name",""))!="":
				var s:=step*0.96*lifted
				draw_texture_rect(Page.mark_texture(glyph,64),Rect2(p-Vector2(s,s)*0.5,Vector2(s,s)),false)
			elif glyph!="quiet":
				# A lesser trouble or a year of learning: a small bead of its colour.
				draw_circle(p,step*0.2*lifted,Page.accent(glyph))
				draw_arc(p,step*0.2*lifted,0.0,TAU,16,T.INK_MUTED,1.0,true)
			else:
				# A quiet year: a tally notch across the thread; every tenth longer.
				var tenth:=int(year.get("n",0))%10==0
				var half:=step*(0.36 if tenth else 0.22)*lifted
				draw_line(p-across*half,p+across*half,T.INK if tenth else T.INK_MUTED,2.0 if tenth else 1.4,true)
			if index==chosen:
				draw_arc(p,step*0.64,0.0,TAU,40,T.GOLD,2.2,true)
			elif index==hover:
				draw_arc(p,step*0.6,0.0,TAU,40,T.RULE_STRONG,1.2,true)


## The people's count across the years, with the chosen year marked.
class PeopleLine extends Control:
	var values:=PackedFloat32Array()
	var chosen:=-1
	func _init()->void:
		custom_minimum_size=Vector2(160,40)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal=Control.SIZE_EXPAND_FILL
	func configure(counts:PackedFloat32Array,chosen_index:int)->void:
		values=counts;chosen=chosen_index;queue_redraw()
	func _draw()->void:
		var n:=values.size()
		draw_line(Vector2(0,size.y-1.0),Vector2(size.x,size.y-1.0),T.RULE,1.0)
		if n<2: return
		var low:=INF;var high:=-INF
		for v in values:
			if v>0.0: low=minf(low,v);high=maxf(high,v)
		if low==INF: return
		var span:=maxf(high-low,maxf(4.0,high*0.08))
		var mid:=(high+low)*0.5
		low=mid-span*0.5;high=mid+span*0.5
		var pad:=4.0
		var line:=PackedVector2Array()
		var area:=PackedVector2Array([Vector2(0,size.y-1.0)])
		for i in n:
			var v:=values[i]
			if v<=0.0: continue
			var at:=Vector2(float(i)/float(n-1)*size.x,pad+(1.0-(v-low)/(high-low))*(size.y-pad*2.0-2.0))
			line.append(at);area.append(at)
		if line.size()<2: return
		area.append(Vector2(line[line.size()-1].x,size.y-1.0))
		draw_colored_polygon(area,Color(T.GOLD,0.10))
		draw_polyline(line,T.GOLD,1.6,true)
		if chosen>=0 and chosen<n and values[chosen]>0.0:
			var x:=float(chosen)/float(n-1)*size.x
			var y:=pad+(1.0-(values[chosen]-low)/(high-low))*(size.y-pad*2.0-2.0)
			draw_line(Vector2(x,0),Vector2(x,size.y),Color(T.INK,0.25),1.0)
			draw_circle(Vector2(x,y),3.6,T.GOLD)
			draw_arc(Vector2(x,y),3.6,0.0,TAU,16,T.INK,1.0,true)


## Words and pictures shared by the count and the page.
class Page:
	static func accent(glyph:String)->Color:
		return Card.ACCENTS.get(glyph,Color("e1c27a"))
	static func mark_texture(glyph:String,px:int=64)->Texture2D:
		var kind:="hearth_count" if glyph=="quiet" else glyph
		return Icons.moment_texture(kind,accent(kind),px)
	## "Year 41 · the Hungry Winter" or "Year 41 · a dry spell · three new ways".
	static func mark_caption(year:Dictionary)->String:
		var n:=int(year.get("n",0))
		if not bool(year.get("closed",true)): return "Year %d · so far this year" % n
		var name:=String(year.get("name",""))
		return "Year %d · %s" % [n,_cap(name) if name!="" else Model.unnamed_words(year)]
	static func _cap(text:String)->String:
		return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text



## The key to the count's marks, drawn the way the count draws them.
class LegendMark extends Control:
	var kind:=""
	func _init(mark_kind:String)->void:
		kind=mark_kind;custom_minimum_size=Vector2(16,16);mouse_filter=Control.MOUSE_FILTER_IGNORE;size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		var c:=size*0.5
		match kind:
			"named":draw_texture_rect(Page.mark_texture("milestone",32),Rect2(Vector2.ZERO,size),false)
			"bead":
				draw_circle(c,4.0,Page.accent("sickness"));draw_arc(c,4.0,0.0,TAU,16,T.INK_MUTED,1.0,true)
			"quiet":draw_line(c-Vector2(0,5),c+Vector2(0,5),T.INK_MUTED,1.6,true)
			"now":draw_arc(c,6.0,0.0,TAU,24,T.GOLD,1.6,true)


var data:Dictionary={}
var years:Array=[]
## The chosen year's number; -1 follows the newest year.
var selected:=-1
## The key of the line opened in the list.
var open_key:=""
## The kind the list is filtered to.
var filter:="all"
var show_tallies:=false
## Lines listed (PAGE more each "Earlier years").
var shown:=PAGE
var hero:BoxContainer
var count:YearCount
var count_caption:Label
var folio:VBoxContainer
## The chosen year's figures, under the count.
var facts:VBoxContainer
var chips:HFlowContainer
var list:VBoxContainer
var tallies_check:CheckBox
var intro:Label
## What the chosen year, the chips and the list were last drawn from, so a
## live refresh redraws only what changed (see update_block).
var _folio_print:Array=[]
var _list_print:Array=[]


func setup(block:Dictionary)->void:
	data=block;name="ChronicleFeed";add_theme_constant_override("separation",10)
	years=block.get("years",[]) if block.get("years") is Array else []
	# The caption's words are kept for the page's voice (tests, the tallies' wording) but not shown: the title says what this is.
	intro=T.make_label(_intro_text(),12,T.MUTED);intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;intro.visible=false;add_child(intro)
	# Two columns: the count, its key and the chosen year's figures on the
	# left; the year's label, the filters and what is told on the right.
	hero=HBoxContainer.new();hero.name="Hero";hero.add_theme_constant_override("separation",18);add_child(hero)
	var left:=VBoxContainer.new();left.name="Count";left.add_theme_constant_override("separation",6);left.custom_minimum_size.x=COUNT_SIDE;left.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;hero.add_child(left)
	count=YearCount.new();count.name="YearCount";count.custom_minimum_size=Vector2(COUNT_SIDE,COUNT_SIDE);count.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;count.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;left.add_child(count)
	count.picked.connect(func(index:int)->void:_choose(int((years[index] as Dictionary).get("n",-1))))
	count.hovered.connect(_on_count_hover)
	count_caption=T.make_label("",12,T.INK);count_caption.name="CountCaption";count_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	count_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;count_caption.custom_minimum_size.x=COUNT_SIDE;left.add_child(count_caption)
	_legend(left)
	facts=VBoxContainer.new();facts.name="YearFigures";facts.add_theme_constant_override("separation",6);left.add_child(facts)
	var right:=VBoxContainer.new();right.name="Told";right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",8);hero.add_child(right)
	folio=facts
	var bar:=HBoxContainer.new();bar.name="Filters";bar.add_theme_constant_override("separation",8);right.add_child(bar)
	chips=HFlowContainer.new();chips.size_flags_horizontal=Control.SIZE_EXPAND_FILL;chips.add_theme_constant_override("h_separation",4);chips.add_theme_constant_override("v_separation",4);bar.add_child(chips)
	tallies_check=CheckBox.new();tallies_check.name="ShowTallies"
	tallies_check.text=_tallies_text();tallies_check.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	tallies_check.add_theme_font_size_override("font_size",12);tallies_check.add_theme_color_override("font_color",T.TEXT_SOFT)
	tallies_check.button_pressed=show_tallies
	tallies_check.toggled.connect(func(on:bool)->void:show_tallies=on;_render_list())
	chips.add_child(tallies_check)
	list=VBoxContainer.new();list.name="Years";list.add_theme_constant_override("separation",0);right.add_child(list)
	# Capture only: "--capture-telling" opens the chosen year's newest telling.
	if "--capture-telling" in OS.get_cmdline_user_args() and _chosen_index()>=0:
		var told:=_year_lines(years[_chosen_index()])
		if not told.is_empty():open_key=String((told[0] as Dictionary).get("key",""))
	_fill()


## The count's key: a picture for a named year, a bead for trouble or
## learning, a notch for a quiet year, the ring for this year.
func _legend(parent:Node)->void:
	var grid:=GridContainer.new();grid.name="Legend";grid.columns=1;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",2);parent.add_child(grid)
	for spec:Array in [["named","named year"],["bead","trouble, learning"],["quiet","quiet year"],["now","this year"]]:
		var item:=HBoxContainer.new();item.add_theme_constant_override("separation",4);grid.add_child(item)
		item.add_child(LegendMark.new(String(spec[0])))
		var words:=T.make_label(String(spec[1]),11,T.TEXT_SOFT);words.size_flags_vertical=Control.SIZE_SHRINK_CENTER;item.add_child(words)


func _voice()->Dictionary:
	return data.get("voice",Chronicle.voice()) if data.get("voice") is Dictionary else Chronicle.voice()


func _intro_text()->String:
	return EraWords.word("chronicle.caption",String(_voice().get("subtitle","")))


func _tallies_text()->String:
	return EraWords.word("chronicle.tallies",String(_voice().get("show_whispers","Show every season's tally")))


## The live refresh: the same page takes the new years; the chosen year and
## the list are drawn again only when what they are drawn from changed. Page
## state (the chosen year, the filter, an opened line, how far back) stays.
func update_block(block:Dictionary)->bool:
	if count==null:return false
	data=block
	years=block.get("years",[]) if block.get("years") is Array else []
	var words:=_intro_text()
	if intro.text!=words:intro.text=words
	words=_tallies_text()
	if tallies_check.text!=words:tallies_check.text=words
	count.configure(years,_chosen_index())
	count._set_hover(-1)
	_on_count_hover(-1)
	if _make_folio_print()!=_folio_print:_render_folio()
	if _make_list_print()!=_list_print:_render_list()
	return true


## Everything the chosen year's folio is drawn from.
func _make_folio_print()->Array:
	var index:=_chosen_index()
	var pops:=PackedInt32Array()
	for y in years:pops.append(int((y as Dictionary).get("pop",-1)))
	var record:Dictionary=(years[index] as Dictionary).duplicate() if index>=0 else {}
	for heavy in ["story","tallies","text","age"]:record.erase(heavy)
	return [index,years.size(),record,pops,_voice().duplicate(true)]


## Everything the list is drawn from: each year's lines (keys) and change.
func _make_list_print()->Array:
	var keys:Array=[]
	for y:Dictionary in years:keys.append([int(y.get("n",0)),y.get("dpop"),String(y.get("name","")),(y.get("story",[]) as Array).size(),(y.get("tallies",[]) as Array).size()])
	return [keys,_chosen_index(),filter,open_key,shown,show_tallies]


## Kept across a live refresh (see view_state.gd).
func view_state()->Dictionary:
	return {"selected":selected,"open":open_key,"filter":filter,"tallies":show_tallies,"shown":shown}


func restore_view_state(state:Dictionary)->void:
	var wanted:={"selected":int(state.get("selected",-1)),"open":String(state.get("open","")),"filter":String(state.get("filter","all")),
		"tallies":bool(state.get("tallies",false)),"shown":int(state.get("shown",PAGE))}
	if wanted==view_state():return
	selected=int(wanted.selected);open_key=String(wanted.open);filter=String(wanted.filter)
	show_tallies=bool(wanted.tallies);shown=int(wanted.shown)
	if tallies_check!=null:tallies_check.set_pressed_no_signal(show_tallies)
	_fill()


## The entries this page can show: the story, and the season tallies when
## asked for.
func visible_entries()->Array:
	var all:Array=data.get("entries",[])
	if show_tallies:return all
	var story:Array=[]
	for e in all:
		if String((e as Dictionary).get("tier","notice"))!="whisper":story.append(e)
	return story


func _fill()->void:
	if count==null:return
	count.configure(years,_chosen_index())
	_on_count_hover(-1)
	_render_folio()
	_render_list()


## The chosen year's place in `years`: the chosen number, or the newest year
## (the one in progress when it holds anything yet, else the last closed).
func _chosen_index()->int:
	if years.is_empty():return -1
	if selected>=0:
		for i in years.size():
			if int((years[i] as Dictionary).get("n",-1))==selected:return i
	var newest:Dictionary=years.back()
	if not bool(newest.get("closed",true)) and (newest.get("story",[]) as Array).is_empty() and years.size()>=2 and int(newest.get("deaths",0))==0 and (newest.get("troubles",[]) as Array).is_empty():
		return years.size()-2
	return years.size()-1


func _choose(n:int)->void:
	if n<0:return
	selected=n;open_key=""
	count.choose(_chosen_index())
	_render_folio()
	_render_list()


func _on_count_hover(index:int)->void:
	if count_caption==null:return
	# The caption names only a year pointed at; the chosen year is named once, beside the count.
	count_caption.text=Page.mark_caption(years[index]) if index>=0 and index<years.size() else ""
	count_caption.visible=count_caption.text!=""


# --- The chosen year ------------------------------------------------------------

func _render_folio()->void:
	for child in facts.get_children():facts.remove_child(child);child.queue_free()
	var index:=_chosen_index()
	if index<0:
		var quiet:=T.make_label("Nothing has been told yet. The story of the people begins at the first fire.",13,T.TEXT_SOFT)
		quiet.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;facts.add_child(quiet)
	else:
		var year:Dictionary=years[index]
		_folio_facts(year)
		_folio_people(index)
	_folio_print=_make_folio_print()


## The year's one label ("YEAR 460 · SO FAR", or "YEAR 459" and its name) and
## the steps to the years either side.
func _folio_head(parent:Node,year:Dictionary,index:int)->void:
	var head:=HBoxContainer.new();head.name="FolioHead";head.add_theme_constant_override("separation",12);parent.add_child(head)
	var medal:=TextureRect.new();medal.name="Mark";medal.custom_minimum_size=Vector2(30,30);medal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;medal.texture=Page.mark_texture(String(year.get("glyph","quiet")),96);head.add_child(medal)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);head.add_child(words)
	var kicker:=T.make_label(("YEAR %d" % int(year.get("n",0)))+("" if bool(year.get("closed",true)) else " · SO FAR"),15,T.GOLD,0.12)
	kicker.add_theme_font_override("font",T.font("display"));kicker.name="Kicker";words.add_child(kicker)
	var name:=String(year.get("name",""))
	if name!="" or bool(year.get("closed",true)):
		var title:=_serif(Page._cap(name) if name!="" else Page._cap(Model.unnamed_words(year)),20 if name!="" else 15,T.INK if name!="" else T.TEXT_SOFT,name=="")
		title.name="YearName";words.add_child(title)
	var nav:=HBoxContainer.new();nav.add_theme_constant_override("separation",2);nav.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;head.add_child(nav)
	for step in [[-1,"‹","The year before"],[1,"›","The year after"]]:
		var go:=Button.new();go.text=String(step[1]);go.flat=true;go.tooltip_text=String(step[2]);go.name="Older" if int(step[0])<0 else "Newer"
		go.add_theme_font_size_override("font_size",22);go.add_theme_color_override("font_color",T.GOLD);go.custom_minimum_size=Vector2(30,30)
		var target:=index+int(step[0])
		go.disabled=target<0 or target>=years.size()
		if not go.disabled:go.pressed.connect(_choose.bind(int((years[target] as Dictionary).get("n",-1))))
		nav.add_child(go)


## The year's change in people and its plain facts as small tokens, each
## with its mark (the people's count itself is on the top bar).
func _folio_facts(year:Dictionary)->void:
	var row:=VBoxContainer.new();row.name="Facts";row.add_theme_constant_override("separation",4)
	var change:Variant=year.get("dpop")
	if change!=null:
		var d:=int(change)
		var span:="this year" if not bool(year.get("closed",true)) else "that year"
		var said:="no change %s" % span if d==0 else "%s%s %s" % ["+" if d>0 else "−",EraWords.grouped(absi(d)),span]
		var label:=T.make_label(said,14,T.GREEN_TEXT if d>0 else (T.RED_TEXT if d<0 else T.BODY));label.name="PeopleWords";label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		label.tooltip_text="The change in the people's count over the year, from the same reckoning Home shows."
		row.add_child(label)
	var born:=int(year.get("born",-1));var buried:=int(year.get("buried",-1))
	if born>0:_chip(row,"birth","%s born" % EraWords.grouped(born))
	if buried>0:_chip(row,"death","%s buried" % EraWords.grouped(buried))
	# The rest of the year's change: neither born nor buried.
	var other:=int(year.get("other",0))
	if other!=0 and born>=0 and buried>=0:_chip(row,"contact","%s left or lost" % EraWords.grouped(-other) if other<0 else "%s arrived" % EraWords.grouped(other))
	var learned:=int(year.get("learned",0))
	if learned>0:_chip(row,"discovery","one new way" if learned==1 else "%s new ways" % EraWords.grouped(learned))
	var troubles:Array=year.get("troubles",[])
	if not troubles.is_empty():
		var type:=String((troubles[0] as Dictionary).get("type",""))
		_chip(row,Annals.trouble_glyph(type,String((troubles[0] as Dictionary).get("name",""))),Model._trouble_words(troubles,int(year.get("deaths",0))))
	if int(year.get("dry",0))>0:_chip(row,"drought","a dry spell" if int(year.dry)==1 else "%d dry spells" % int(year.dry))
	if int(year.get("mild",0))>0:_chip(row,"sickness","a small fever" if int(year.mild)==1 else "%d small fevers" % int(year.mild))
	for who in (year.get("heads",[]) as Array).slice(0,1):_chip(row,"court","%s keeps the fire" % String(who))
	for aim in (year.get("kept",[]) as Array).slice(0,1):_chip(row,"milestone","aim kept: %s" % String(aim))
	for aim in (year.get("unmet",[]) as Array).slice(0,1):_chip(row,"omen","aim unmet")
	for people in (year.get("met",[]) as Array).slice(0,2):_chip(row,"contact","met the %s" % String(people))
	if int(year.get("km",0))>=100:_chip(row,"scout","%s km walked" % EraWords.grouped(int(year.km)))
	if row.get_child_count()>0:facts.add_child(row)
	else:row.free()


func _chip(row:Node,glyph:String,text:String)->void:
	var chip:=PanelContainer.new();chip.name="Fact";chip.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,10,0))
	var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_left",3);margin.add_theme_constant_override("margin_right",9)
	margin.add_theme_constant_override("margin_top",2);margin.add_theme_constant_override("margin_bottom",2);chip.add_child(margin)
	var inner:=HBoxContainer.new();inner.add_theme_constant_override("separation",5);margin.add_child(inner)
	var mark:=TextureRect.new();mark.custom_minimum_size=Vector2(20,20);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.texture=Page.mark_texture(glyph,40);inner.add_child(mark)
	var label:=T.make_label(text,12,T.BODY);label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;inner.add_child(label)
	row.add_child(chip)


## The people's count across the years, the chosen year marked.
func _folio_people(index:int)->void:
	var counts:=PackedFloat32Array()
	for y in years:counts.append(float(int((y as Dictionary).get("pop",-1))))
	var line:=PeopleLine.new();line.name="PeopleLine";line.custom_minimum_size=Vector2(COUNT_SIDE,48);line.configure(counts,index);facts.add_child(line)
	line.tooltip_text="The people's count, year by year, from the founding; the dot is the chosen year.";line.mouse_filter=Control.MOUSE_FILTER_PASS


## The year's own entry and, at a generation's end, its account: folded.
func _folio_telling(parent:Node,year:Dictionary)->void:
	var text:=String(year.get("text",""))
	var age:Dictionary=year.get("age",{}) if year.get("age") is Dictionary else {}
	if text=="" and age.is_empty():return
	var era:=String(_voice().get("era","tally"))
	var key:="telling:%d" % int(year.get("n",0))
	var toggle:=Button.new();toggle.name="Telling";toggle.flat=true;toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT
	toggle.text=("▾ " if open_key==key else "▸ ")+("The year as it is told at the fire" if era=="tally" else "The year as the keepers wrote it")
	toggle.add_theme_color_override("font_color",T.GOLD);toggle.add_theme_font_size_override("font_size",13)
	toggle.pressed.connect(func()->void:open_key="" if open_key==key else key;_render_list())
	parent.add_child(toggle)
	if open_key==key:
		if text!="":parent.add_child(_serif(text,15,T.BODY))
		if not age.is_empty():
			parent.add_child(_serif(String(age.get("title","")),17,T.GOLD))
			parent.add_child(_serif(String(age.get("text","")),14,T.BODY))


func _serif(text:String,size:int,color:Color,italic:=false)->Label:
	var label:=T.make_label(text,size,color)
	label.add_theme_font_override("font",T.voice_font(italic));label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


# --- What is told ---------------------------------------------------------------

## The kind of filter a telling belongs to, from its mark.
static func filter_of(entry:Dictionary)->String:
	match glyph_for(entry):
		"death","sickness","drought","flood","fire","cold","hunger","thinning","omen","stranger":return "loss"
		"war":return "war"
		"discovery":return "learning"
		"contact","scout":return "contact"
		"work","settlement","milestone","ceremony","founding","birth":return "works"
		"court":return "court"
	return "works"


## A telling's mark: a trouble's own mark, else its kind's.
static func glyph_for(entry:Dictionary)->String:
	var key:=String(entry.get("key",""))
	if key.begins_with("crisis:"):
		var title:=String(entry.get("title",""))
		var type:=String(Annals.CRISIS_TYPES.get(title,""))
		if type=="":
			for onset in Annals.CRISIS_TYPES:
				if title.begins_with(String(onset)):type=String(Annals.CRISIS_TYPES[onset])
		return "death" if String(entry.get("kind",""))=="death" else Annals.trouble_glyph(type,title)
	var kind:=String(entry.get("kind",""))
	if Card.ACCENTS.has(kind):return kind
	match kind:
		"knowledge","known","training":return "discovery"
		"fate","figure":return "death" if "dead" in String(entry.get("title","")).to_lower() or "died" in String(entry.get("title","")).to_lower() else "birth"
		"threat","levy","arm","watch":return "war"
		"news","business","trail","river","scouting":return "contact" if kind!="scouting" else "scout"
		"build","great_work","plant_install","work_pace":return "work"
		"request","proposal","official","petition","policy","measure","ration","held","section","line":return "court"
		"society":return "ceremony"
		"misfortune":return "omen"
	return "hearth_count"


## The tellings of a year the list shows, newest first.
func _year_lines(year:Dictionary)->Array:
	var lines:Array=(year.get("story",[]) as Array).duplicate()
	if show_tallies:lines.append_array(year.get("tallies",[]))
	if filter!="all":lines=lines.filter(func(e:Dictionary)->bool:return filter_of(e)==filter)
	lines.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.get("day",0))>int(b.get("day",0)))
	return lines


## The filter chips, each with how many tellings it holds.
func _render_chips()->void:
	if tallies_check.get_parent()==chips:chips.remove_child(tallies_check)
	for child in chips.get_children():chips.remove_child(child);child.queue_free()
	var counts:Dictionary={}
	for year:Dictionary in years:
		var lines:Array=(year.get("story",[]) as Array)+((year.get("tallies",[]) as Array) if show_tallies else [])
		for e:Dictionary in lines:
			counts["all"]=int(counts.get("all",0))+1
			counts[filter_of(e)]=int(counts.get(filter_of(e),0))+1
	for spec:Array in FILTERS:
		var id:=String(spec[0])
		var n:=int(counts.get(id,0))
		if n==0 and id!="all":continue
		var on:=id==filter
		var chip:=Button.new();chip.name="Filter_"+id;chip.focus_mode=Control.FOCUS_NONE;chip.text="%s  %s" % [String(spec[1]),EraWords.grouped(n)]
		chip.add_theme_constant_override("icon_max_width",16);chip.icon=Page.mark_texture(String(spec[2]),32)
		chip.add_theme_font_size_override("font_size",12);chip.custom_minimum_size.y=26
		chip.add_theme_color_override("font_color",T.INK if on else T.BODY);chip.add_theme_color_override("font_hover_color",T.INK)
		var face:=T.flat(T.ACTIVE_BG if on else Color.TRANSPARENT,T.GOLD if on else T.BORDER_SOFT,1,2,6)
		if on:face.border_width_bottom=3
		chip.add_theme_stylebox_override("normal",face);chip.add_theme_stylebox_override("pressed",face);chip.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,2,6))
		chip.pressed.connect(func()->void:filter=id;open_key="";shown=PAGE;_render_list())
		chips.add_child(chip)
	chips.add_child(tallies_check)


## What is told, from the chosen year back: each year's line, then its
## tellings one line each, until the page is full.
func _render_list()->void:
	_render_chips()
	for child in list.get_children():list.remove_child(child);child.queue_free()
	var chosen:=_chosen_index()
	var listed:=0
	var start:=chosen if chosen>=0 else years.size()-1
	var more:=false
	for i in range(start,-1,-1):
		var year:Dictionary=years[i]
		var lines:=_year_lines(year)
		if lines.is_empty() and i!=chosen:continue
		if listed>=shown:more=true;break
		if i==chosen:
			# The chosen year's one label, its steps either side and its telling.
			var head:=PanelContainer.new();head.name="Year%d" % int(year.get("n",0));head.add_theme_stylebox_override("panel",T.flat(T.GOLD_WASH,T.GOLD,1,3,6));list.add_child(head)
			var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",2);head.add_child(stack)
			_folio_head(stack,year,i)
			_folio_telling(stack,year)
		else:list.add_child(_year_row(year,false,lines.size()))
		for e:Dictionary in lines:
			list.add_child(_line(e))
			listed+=1
		if lines.is_empty():
			var none:=T.make_label("Nothing of this kind told this year." if filter!="all" else "Nothing told yet this year.",12,T.TEXT_SOFT);none.custom_minimum_size.y=24;list.add_child(none)
	if more:
		var earlier:=Button.new();earlier.name="EarlierYears";earlier.flat=true;earlier.text="Earlier years";earlier.alignment=HORIZONTAL_ALIGNMENT_LEFT
		earlier.add_theme_color_override("font_color",T.GOLD)
		earlier.pressed.connect(func()->void:shown+=PAGE;_render_list())
		list.add_child(earlier)
	_list_print=_make_list_print()


## A year's line in the list: its number, its name (or its plain words) and
## its change in people; choosing it opens the year above.
func _year_row(year:Dictionary,chosen:bool,told:int)->Button:
	var row:=Button.new();row.name="Year%d" % int(year.get("n",0));row.custom_minimum_size=Vector2(0,26);row.flat=true;row.focus_mode=Control.FOCUS_NONE
	row.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,Color(0,0,0,0),0,2,0))
	var line:=HBoxContainer.new();line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);line.offset_left=2;line.offset_right=-4
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_theme_constant_override("separation",10)
	# The shared table's group line: the year and its name in small gold capitals.
	var name:=String(year.get("name",""))
	var words:=("YEAR %d · " % int(year.get("n",0)))+(Page._cap(name) if name!="" else Page._cap(Model.unnamed_words(year))).to_upper()
	var label:=T.make_label(words,11,T.GOLD_TEXT,0.06);label.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_FILL;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(label)
	var change:Variant=year.get("dpop")
	if change!=null and int(change)!=0:
		var d:=int(change)
		var delta:=T.make_label("%s%s" % ["+" if d>0 else "−",EraWords.grouped(absi(d))],12,T.GREEN_TEXT if d>0 else T.RED_TEXT);delta.mouse_filter=Control.MOUSE_FILTER_IGNORE;delta.size_flags_vertical=Control.SIZE_SHRINK_END
		line.add_child(delta)
	row.add_child(line)
	row.tooltip_text=Page.mark_caption(year)+(" · %d told" % told if told>0 else "")+". Choose it to open the year."
	row.pressed.connect(func()->void:_choose(int(year.get("n",-1)));_reveal_hero())
	return row


## A telling as one line: its mark, its title and its season; it opens in
## place to its telling and its links.
func _line(entry:Dictionary)->Control:
	var key:=String(entry.get("key",""))
	var open:=key==open_key
	var box:=VBoxContainer.new();box.name="Moment";box.add_theme_constant_override("separation",0)
	# The game's one table line (dense_blocks.gd): mark, title (a long one
	# wraps), season; choosing it opens its telling beneath.
	var whisper:=String(entry.get("tier",""))=="whisper"
	var toggle:=func()->void:
		open_key="" if open_key==key else key
		_render_list()
	var row:=Dense._row({"icon":Page.mark_texture(glyph_for(entry),36),"cells":{"title":tile_caption(entry),"season":Chronicle.date_label(int(entry.get("day",0))).get_slice(" · ",1)},
		"tip":String(entry.get("title","")),"on_click":toggle},LINE_COLUMNS)
	row.name="Line"
	if whisper:(row.find_child("Cell_title",true,false) as Label).add_theme_color_override("font_color",T.TEXT_SOFT)
	if open:
		var lit:=T.flat(T.GOLD_WASH,Color(0,0,0,0),0,2);lit.content_margin_left=2;lit.content_margin_right=2;row.add_theme_stylebox_override("panel",lit)
	box.add_child(row)
	if open:_reading(box,entry)
	return box


## A telling's short title: "After the Coughing Winter of year 58" is told
## as "The Coughing Winter ends"; the year is already on its line.
static func tile_caption(entry:Dictionary)->String:
	var title:=String(entry.get("title",""))
	if title.begins_with("After "):return Page._cap(Annals.short_name(title))+" ends"
	return Page._cap(Annals.short_name(title))


func _reading(parent:Node,entry:Dictionary)->void:
	var pane:=MarginContainer.new();pane.name="Reading";pane.add_theme_constant_override("margin_left",80);pane.add_theme_constant_override("margin_right",8);pane.add_theme_constant_override("margin_bottom",6);parent.add_child(pane)
	var copy:=VBoxContainer.new();copy.add_theme_constant_override("separation",4);pane.add_child(copy)
	if String(entry.get("text",""))!="":
		var text:=T.make_label(String(entry.text),13,T.BODY);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.add_theme_font_override("font",T.voice_font());text.add_theme_font_size_override("font_size",15);copy.add_child(text)
	_battle_links(copy,entry)
	_court_link(copy,entry)


## After choosing from the list, bring the chosen year into view.
func _reveal_hero()->void:
	var scroll:ScrollContainer=null
	var node:Node=get_parent()
	while node!=null:
		if node is ScrollContainer:scroll=node;break
		node=node.get_parent()
	if scroll==null or hero==null:return
	var offset:=hero.get_global_rect().position.y-scroll.get_global_rect().position.y+float(scroll.scroll_vertical)
	scroll.scroll_vertical=maxi(0,int(offset)-8)


# --- Links ----------------------------------------------------------------------

## A battle's entry offers its report and the battle panel (battle_account.gd,
## hud/battle_panel.gd); a war leader's clash (war_loop.gd) offers the panel.
## Watching never fights it again.
func _battle_links(copy:VBoxContainer,entry:Dictionary)->void:
	var action:Dictionary=entry.get("action",{}) if entry.get("action") is Dictionary else {}
	var reported:=String(action.get("kind",""))=="battle"
	var seed:=int(action.get("seed",0)) if reported else int(action.get("battle_seed",-1))
	if not reported and seed<0: return
	var row:=HBoxContainer.new();row.name="BattleLinks";row.add_theme_constant_override("separation",12);copy.add_child(row)
	for link in ([["Read the report","report"],["Watch the battle","watch"]] if reported else [["Watch the battle","watch"]]):
		var button:=Button.new();button.text=String(link[0]);button.flat=true;button.name=String(link[1]).capitalize()
		button.add_theme_color_override("font_color",T.GOLD);button.add_theme_font_size_override("font_size",13)
		button.pressed.connect(_open_battle.bind(String(link[1]),seed))
		row.add_child(button)


## A moment about a person or a people at court offers the court.
func _court_link(copy:VBoxContainer,entry:Dictionary)->void:
	var action:Dictionary=entry.get("action",{}) if entry.get("action") is Dictionary else {}
	# One held under guard (captured_agents.gd): "Bring them before you".
	if String(action.get("kind",""))=="prisoner":
		var id:=String(action.get("prisoner_id",""))
		if not preload("res://scripts/captured_agents.gd").is_held(id):return
		var bring:=Button.new();bring.name="BringPrisoner";bring.text="Bring them before you";bring.flat=true;bring.alignment=HORIZONTAL_ALIGNMENT_LEFT
		bring.add_theme_color_override("font_color",T.GOLD);bring.add_theme_font_size_override("font_size",13)
		bring.pressed.connect(func()->void:preload("res://scripts/audience_director.gd").open_court_for({"prisoner_id":id}))
		copy.add_child(bring)
		return
	if String(action.get("kind",""))!="court":return
	var go:=Button.new();go.name="ToCourt";go.text="Go to the court";go.flat=true;go.alignment=HORIZONTAL_ALIGNMENT_LEFT
	go.add_theme_color_override("font_color",T.GOLD);go.add_theme_font_size_override("font_size",13)
	var focus:Dictionary=action.get("focus",{}) if action.get("focus") is Dictionary else {}
	go.pressed.connect(func()->void:preload("res://scripts/audience_director.gd").open_court_for(focus))
	copy.add_child(go)


func _open_battle(what:String,seed:int)->void:
	var host:Node=get_tree().current_scene
	if what=="watch":
		var ui:Node=get_tree().root.get_node_or_null("MilitaryCommandUI")
		if ui!=null:ui.call_deferred("_open_battle_graphics",0,seed)
	else:preload("res://scripts/hud/battle_report_panel.gd").open(host,seed)
