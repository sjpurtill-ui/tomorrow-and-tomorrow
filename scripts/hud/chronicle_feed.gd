extends VBoxContainer
## THE CHRONICLE PAGE: the story of the people as a count of years.
##
##   ┌ the count: every year a mark on a spiral that winds out from the
##   │ founding, the way a count of winters is painted: a picture for a year
##   │ the people named (a great death, a trouble that filled graves, a kept
##   │ aim, a work finished, a first meeting, a new custom), a small coloured
##   │ bead for a year of a lesser trouble or of learning, a plain notch for a
##   │ quiet one. The year in progress is the open ring at its end. Point at a
##   │ mark for its name; choose it to open that year.
##   ├ the chosen year: its mark, number and name; the people's count across
##   │ the years with this one marked; its plain facts as small tokens; its
##   │ moments as pictures, each opening to its telling; and the year's own
##   │ entry, folded until asked for
##   └ the years, one line each (mark, number, name), newest first
##
## Words stay short: every telling is one choice away and never on the page
## by default. Data: content/dock_content_chronicle.gd, whose years come from
## hud/chronicle_year_model.gd; each year's name and mark from
## chronicle_annals.gd. The view (the chosen year, the opened moment, how far
## back the years are listed) survives a live refresh (view_state.gd).

const Chronicle:=preload("res://scripts/chronicle.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Model:=preload("res://scripts/hud/chronicle_year_model.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")
## Years listed before "Earlier years".
const PAGE:=16
## A year's moments shown before "more".
const TILES:=12
## Narrower than this, the chosen year sits under the count.
const WIDE_AT:=700.0
const TILE_SIZE:=Vector2(104,118)


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
		custom_minimum_size=Vector2(320,320)
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
		first=maxi(0,years.size()-MAX_MARKS)
		var n:=years.size()-first
		if n<=0 or size.x<=0.0 or size.y<=0.0: return
		var center:=size*0.5
		var r_max:=minf(size.x,size.y)*0.5-18.0
		var r0:=24.0
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


var data:Dictionary={}
var years:Array=[]
## The chosen year's number; -1 follows the newest year.
var selected:=-1
## The key of the moment opened in the chosen year.
var open_key:=""
## The year's own entry unfolded.
var telling:=false
var show_tallies:=false
var shown:=PAGE
var more_tiles:=false
var hero:BoxContainer
var count:YearCount
var count_caption:Label
var folio:VBoxContainer
var list:VBoxContainer
var tallies_check:CheckBox
var intro:Label
## What the chosen year and each listed year were last drawn from, so a live
## refresh redraws only what changed (see update_block).
var _folio_print:Array=[]
var _row_prints:Array=[]
var _list_shape:Array=[]


func setup(block:Dictionary)->void:
	data=block;name="ChronicleFeed";add_theme_constant_override("separation",14)
	years=block.get("years",[]) if block.get("years") is Array else []
	intro=T.make_label(_intro_text(),12,T.MUTED);intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(intro)
	hero=BoxContainer.new();hero.name="Hero";hero.add_theme_constant_override("separation",18);add_child(hero)
	var left:=VBoxContainer.new();left.add_theme_constant_override("separation",6);left.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;hero.add_child(left)
	count=YearCount.new();count.name="YearCount";left.add_child(count)
	count.picked.connect(func(index:int)->void:_choose(int((years[index] as Dictionary).get("n",-1))))
	count.hovered.connect(_on_count_hover)
	count_caption=T.make_label("",12,T.TEXT_SOFT);count_caption.name="CountCaption";count_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	count_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;count_caption.custom_minimum_size.x=300;left.add_child(count_caption)
	folio=VBoxContainer.new();folio.name="Folio";folio.size_flags_horizontal=Control.SIZE_EXPAND_FILL;folio.add_theme_constant_override("separation",10);hero.add_child(folio)
	tallies_check=CheckBox.new();tallies_check.name="ShowTallies"
	tallies_check.text=_tallies_text()
	tallies_check.add_theme_font_size_override("font_size",12);tallies_check.add_theme_color_override("font_color",T.TEXT_SOFT)
	tallies_check.button_pressed=show_tallies
	tallies_check.toggled.connect(func(on:bool)->void:show_tallies=on;_render_folio())
	list=VBoxContainer.new();list.name="Years";list.add_theme_constant_override("separation",2);add_child(list)
	resized.connect(_arrange)
	_fill()


func _voice()->Dictionary:
	return data.get("voice",Chronicle.voice()) if data.get("voice") is Dictionary else Chronicle.voice()


func _intro_text()->String:
	return EraWords.word("chronicle.caption",String(_voice().get("subtitle","")))


func _tallies_text()->String:
	return EraWords.word("chronicle.tallies",String(_voice().get("show_whispers","Show every season's tally")))


## The live refresh: the same page takes the new years. The count is placed
## again; the chosen year is drawn again only when what it is drawn from
## changed, and of the listed years only the lines that changed are replaced.
## Page state (the chosen year, an opened moment, how far back the list goes)
## simply stays.
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
	_update_list()
	_arrange()
	return true


## Everything the chosen year's folio is drawn from.
func _make_folio_print()->Array:
	var index:=_chosen_index()
	var pops:=PackedInt32Array()
	for y in years:pops.append(int((y as Dictionary).get("pop",-1)))
	return [index,years.size(),(years[index] as Dictionary).duplicate(true) if index>=0 else {},pops,_voice().duplicate(true),open_key,telling,more_tiles,show_tallies]


## Kept across a live refresh (see view_state.gd).
func view_state()->Dictionary:
	return {"selected":selected,"open":open_key,"telling":telling,"tallies":show_tallies,"shown":shown,"more":more_tiles}


func restore_view_state(state:Dictionary)->void:
	var wanted:={"selected":int(state.get("selected",-1)),"open":String(state.get("open","")),"telling":bool(state.get("telling",false)),
		"tallies":bool(state.get("tallies",false)),"shown":int(state.get("shown",PAGE)),"more":bool(state.get("more",false))}
	if wanted==view_state():return
	selected=int(wanted.selected);open_key=String(wanted.open);telling=bool(wanted.telling)
	show_tallies=bool(wanted.tallies);shown=int(wanted.shown);more_tiles=bool(wanted.more)
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
	_arrange()


func _arrange()->void:
	if hero==null:return
	var stacked:=size.x>0.0 and size.x<WIDE_AT
	if hero.vertical!=stacked:hero.vertical=stacked


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
	selected=n;open_key="";telling=false;more_tiles=false
	count.choose(_chosen_index())
	_render_folio()
	_render_list()


func _on_count_hover(index:int)->void:
	if count_caption==null:return
	var shown_index:=index if index>=0 else _chosen_index()
	count_caption.text=Page.mark_caption(years[shown_index]) if shown_index>=0 and shown_index<years.size() else ""
	count_caption.add_theme_color_override("font_color",T.INK if index>=0 else T.TEXT_SOFT)


# --- The chosen year ------------------------------------------------------------

func _render_folio()->void:
	if tallies_check.get_parent()==folio:folio.remove_child(tallies_check)
	for child in folio.get_children():folio.remove_child(child);child.queue_free()
	_render_folio_body()
	folio.add_child(tallies_check)
	var index:=_chosen_index()
	var tallies:Array=(years[index] as Dictionary).get("tallies",[]) if index>=0 else []
	tallies_check.visible=not tallies.is_empty() or show_tallies
	if show_tallies and not tallies.is_empty():
		var lines:=VBoxContainer.new();lines.name="Tallies";lines.add_theme_constant_override("separation",2);folio.add_child(lines)
		for e in tallies:_whisper(lines,e)
	_folio_print=_make_folio_print()


func _render_folio_body()->void:
	var index:=_chosen_index()
	if index<0:
		var quiet:=T.make_label("Nothing has been told yet. The story of the people begins at the first fire.",13,T.TEXT_SOFT)
		quiet.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;folio.add_child(quiet)
		return
	var year:Dictionary=years[index]
	_folio_head(year,index)
	_folio_people(year,index)
	_folio_facts(year)
	_folio_moments(year)
	_folio_telling(year)


func _folio_head(year:Dictionary,index:int)->void:
	var head:=HBoxContainer.new();head.name="FolioHead";head.add_theme_constant_override("separation",14);folio.add_child(head)
	var medal:=TextureRect.new();medal.name="Mark";medal.custom_minimum_size=Vector2(64,64);medal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;medal.texture=Page.mark_texture(String(year.get("glyph","quiet")),128);head.add_child(medal)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);head.add_child(words)
	var kicker:=T.make_label(("YEAR %d" % int(year.get("n",0)))+("" if bool(year.get("closed",true)) else " · SO FAR"),13,T.GOLD,0.14)
	kicker.add_theme_font_override("font",T.font("display"));kicker.name="Kicker";words.add_child(kicker)
	var name:=String(year.get("name",""))
	var title:Label
	if name!="":title=_serif(Page._cap(name),24,T.INK)
	elif not bool(year.get("closed",true)):title=_serif(_so_far(year),18,T.TEXT_SOFT,true)
	else:title=_serif(Page._cap(Model.unnamed_words(year)),18,T.TEXT_SOFT,true)
	title.name="YearName";words.add_child(title)
	var nav:=HBoxContainer.new();nav.add_theme_constant_override("separation",2);nav.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;head.add_child(nav)
	for step in [[-1,"‹","The year before"],[1,"›","The year after"]]:
		var go:=Button.new();go.text=String(step[1]);go.flat=true;go.tooltip_text=String(step[2]);go.name="Older" if int(step[0])<0 else "Newer"
		go.add_theme_font_size_override("font_size",22);go.add_theme_color_override("font_color",T.GOLD);go.custom_minimum_size=Vector2(30,30)
		var target:=index+int(step[0])
		go.disabled=target<0 or target>=years.size()
		if not go.disabled:go.pressed.connect(_choose.bind(int((years[target] as Dictionary).get("n",-1))))
		nav.add_child(go)


func _so_far(year:Dictionary)->String:
	var story:=(year.get("story",[]) as Array).size()
	if story==0:return "Nothing told yet this year"
	return "One thing told so far" if story==1 else "%s things told so far" % Annals._number(story)


func _folio_people(year:Dictionary,index:int)->void:
	var counts:=PackedFloat32Array()
	for y in years:counts.append(float(int((y as Dictionary).get("pop",-1))))
	var line:=PeopleLine.new();line.name="PeopleLine";line.configure(counts,index);folio.add_child(line)
	var pop:=int(year.get("pop",-1))
	if pop<=0:return
	var voice:=_voice()
	var said:="%d %s" % [pop,String(voice.get("people","people"))]
	var change:Variant=year.get("dpop")
	if change!=null:
		var d:=int(change)
		said+=" · the same as a year before" if d==0 else (" · %d more than a year before" % d if d>0 else " · %d fewer than a year before" % -d)
	var label:=T.make_label(said,12,T.TEXT_SOFT);label.name="PeopleWords";folio.add_child(label)


## The year's plain facts as small tokens, each with its mark.
func _folio_facts(year:Dictionary)->void:
	var row:=HFlowContainer.new();row.name="Facts";row.add_theme_constant_override("h_separation",6);row.add_theme_constant_override("v_separation",6)
	var born:=int(year.get("born",-1));var buried:=int(year.get("buried",-1))
	if born>0:_chip(row,"birth","%d born" % born)
	if buried>0:_chip(row,"death","%d buried" % buried)
	var learned:=int(year.get("learned",0))
	if learned>0:_chip(row,"discovery","one new way" if learned==1 else "%d new ways" % learned)
	var troubles:Array=year.get("troubles",[])
	if not troubles.is_empty():
		var type:=String((troubles[0] as Dictionary).get("type",""))
		_chip(row,Annals.trouble_glyph(type,String((troubles[0] as Dictionary).get("name",""))),Model._trouble_words(troubles,int(year.get("deaths",0))))
	if int(year.get("dry",0))>0:_chip(row,"drought","a dry spell" if int(year.dry)==1 else "%d dry spells" % int(year.dry))
	if int(year.get("mild",0))>0:_chip(row,"sickness","a small fever" if int(year.mild)==1 else "%d small fevers" % int(year.mild))
	for who in (year.get("lost",[]) as Array).slice(0,2):_chip(row,"death","%s died" % String(who).get_slice(" of ",0))
	for who in (year.get("heads",[]) as Array).slice(0,1):_chip(row,"court","%s keeps the fire" % String(who))
	for aim in (year.get("kept",[]) as Array).slice(0,1):_chip(row,"milestone","aim kept: %s" % String(aim))
	for aim in (year.get("unmet",[]) as Array).slice(0,1):_chip(row,"omen","aim unmet")
	for people in (year.get("met",[]) as Array).slice(0,2):_chip(row,"contact","met the %s" % String(people))
	for work in (year.get("works",[]) as Array).slice(0,1):_chip(row,"work",String(work))
	for turn in (year.get("turns",[]) as Array).slice(0,1):_chip(row,"ceremony",String(turn))
	if int(year.get("km",0))>=100:_chip(row,"scout","%s km walked" % Annals._grouped(int(year.km)))
	if row.get_child_count()>0:folio.add_child(row)
	else:row.free()


func _chip(row:Node,glyph:String,text:String)->void:
	var chip:=PanelContainer.new();chip.name="Fact";chip.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,10,0))
	var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_left",3);margin.add_theme_constant_override("margin_right",9)
	margin.add_theme_constant_override("margin_top",2);margin.add_theme_constant_override("margin_bottom",2);chip.add_child(margin)
	var inner:=HBoxContainer.new();inner.add_theme_constant_override("separation",5);margin.add_child(inner)
	var mark:=TextureRect.new();mark.custom_minimum_size=Vector2(20,20);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.texture=Page.mark_texture(glyph,40);inner.add_child(mark)
	var label:=T.make_label(text,12,T.BODY);label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;inner.add_child(label)
	row.add_child(chip)


## The year's moments as pictures; one opens to its telling below them.
func _folio_moments(year:Dictionary)->void:
	var story:Array=year.get("story",[])
	if story.is_empty():return
	var grid:=HFlowContainer.new();grid.name="Moments";grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);folio.add_child(grid)
	var limit:=story.size() if more_tiles else mini(story.size(),TILES)
	var opened:Dictionary={}
	for i in limit:
		var entry:Dictionary=story[i]
		grid.add_child(_tile(entry))
		if String(entry.get("key",""))==open_key:opened=entry
	if story.size()>limit:
		var more:=Button.new();more.name="MoreMoments";more.text="%d more" % (story.size()-limit);more.custom_minimum_size=TILE_SIZE
		more.add_theme_stylebox_override("normal",T.flat(T.PAPER_SUNK,T.RULE,1,4,0));more.add_theme_color_override("font_color",T.GOLD)
		more.pressed.connect(func()->void:more_tiles=true;_render_folio())
		grid.add_child(more)
	if not opened.is_empty():_reading(opened)


func _tile(entry:Dictionary)->Button:
	var key:=String(entry.get("key",""))
	var tile:=Button.new();tile.name="Moment";tile.custom_minimum_size=TILE_SIZE
	tile.tooltip_text=String(entry.get("title",""))
	var open:=key==open_key
	tile.add_theme_stylebox_override("normal",T.flat(T.GOLD_WASH if open else T.PAPER_RAISED,T.GOLD if open else T.RULE,2 if open else 1,4,0))
	tile.add_theme_stylebox_override("hover",T.flat(T.PAPER_RAISED,T.RULE_STRONG,1,4,0))
	tile.add_theme_stylebox_override("pressed",T.flat(T.GOLD_WASH,T.GOLD,2,4,0))
	tile.add_theme_stylebox_override("hover_pressed",T.flat(T.GOLD_WASH,T.GOLD,2,4,0))
	var stack:=VBoxContainer.new();stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation",3)
	var picture:=TextureRect.new();picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;picture.custom_minimum_size=Vector2(TILE_SIZE.x-8,72)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if _painted(entry) else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture=_entry_texture(entry)
	var pad:=MarginContainer.new();pad.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for side in ["left","right","top"]:pad.add_theme_constant_override("margin_"+side,4)
	pad.add_child(picture);stack.add_child(pad)
	var caption:=T.make_label(tile_caption(entry),11,T.INK);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.max_lines_visible=2;caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.custom_minimum_size.x=TILE_SIZE.x-8
	var cap_pad:=MarginContainer.new();cap_pad.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for side in ["left","right"]:cap_pad.add_theme_constant_override("margin_"+side,4)
	cap_pad.add_child(caption);stack.add_child(cap_pad)
	tile.add_child(stack)
	tile.pressed.connect(func()->void:open_key="" if open_key==key else key;_render_folio())
	return tile


## A moment's short caption: "After the Coughing Winter of year 58" is told
## as "The Coughing Winter ends"; the year is already on the page.
static func tile_caption(entry:Dictionary)->String:
	var title:=String(entry.get("title",""))
	if title.begins_with("After "):return Page._cap(Annals.short_name(title))+" ends"
	var short:=Annals.short_name(title)
	return Page._cap(short)


static func _painted(entry:Dictionary)->bool:
	var art:Dictionary=entry.get("art",{}) if entry.get("art") is Dictionary else {}
	return String(art.get("discovery_id",""))!="" or String(art.get("domain",""))!=""


## A trouble's own mark for its entries; any other moment's picture.
static func _entry_texture(entry:Dictionary)->Texture2D:
	var key:=String(entry.get("key",""))
	if key.begins_with("crisis:"):
		var title:=String(entry.get("title",""))
		var type:=String(Annals.CRISIS_TYPES.get(title,""))
		if type=="":
			for onset in Annals.CRISIS_TYPES:
				if title.begins_with(String(onset)):type=String(Annals.CRISIS_TYPES[onset])
		var glyph:=Annals.trouble_glyph(type,title)
		if String(entry.get("kind",""))=="death":glyph="death"
		return Page.mark_texture(glyph,128)
	return Card.texture_for(entry)


func _reading(entry:Dictionary)->void:
	var pane:=PanelContainer.new();pane.name="Reading";pane.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.GOLD,1,6,12));folio.add_child(pane)
	var copy:=VBoxContainer.new();copy.add_theme_constant_override("separation",4);pane.add_child(copy)
	var season:=Chronicle.date_label(int(entry.get("day",0))).get_slice(" · ",1).to_upper()
	copy.add_child(T.make_label(season,10,T.GOLD,0.1))
	copy.add_child(_serif(String(entry.get("title","")),18,T.INK))
	if String(entry.get("text",""))!="":
		var text:=T.make_label(String(entry.text),13,T.BODY);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;copy.add_child(text)
	_battle_links(copy,entry)
	_court_link(copy,entry)


## The year's own entry and, at a generation's end, its account: folded.
func _folio_telling(year:Dictionary)->void:
	var text:=String(year.get("text",""))
	var age:Dictionary=year.get("age",{}) if year.get("age") is Dictionary else {}
	var era:=String(_voice().get("era","tally"))
	if text!="" or not age.is_empty():
		var toggle:=Button.new();toggle.name="Telling";toggle.flat=true;toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT
		toggle.text=("▾ " if telling else "▸ ")+("The year as it is told at the fire" if era=="tally" else "The year as the keepers wrote it")
		toggle.add_theme_color_override("font_color",T.GOLD);toggle.add_theme_font_size_override("font_size",13)
		toggle.pressed.connect(func()->void:telling=not telling;_render_folio())
		folio.add_child(toggle)
		if telling:
			if text!="":folio.add_child(_serif(text,15,T.BODY))
			if not age.is_empty():
				folio.add_child(_serif(String(age.get("title","")),17,T.GOLD))
				folio.add_child(_serif(String(age.get("text","")),14,T.BODY))


func _serif(text:String,size:int,color:Color,italic:=false)->Label:
	var label:=T.make_label(text,size,color)
	label.add_theme_font_override("font",T.voice_font(italic));label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


func _whisper(parent:Node,entry:Dictionary)->void:
	var text:=T.make_label("%s — %s" % [String(entry.get("title","")),String(entry.get("text",""))],11,T.MUTED)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(text)


# --- The years ------------------------------------------------------------------

func _render_list()->void:
	for child in list.get_children():list.remove_child(child);child.queue_free()
	_row_prints.clear()
	_list_shape=_list_shape_now()
	if years.size()<2:return
	var heading:=T.make_label("THE YEARS",11,T.GOLD,0.12);list.add_child(heading)
	var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size=Vector2(0,1);list.add_child(rule)
	var chosen:=_chosen_index()
	var listed:=0
	for i in range(years.size()-1,-1,-1):
		if listed>=shown:break
		list.add_child(_year_row(years[i],i==chosen))
		_row_prints.append(_row_print(years[i],i==chosen))
		listed+=1
	if years.size()>shown:
		var more:=Button.new();more.name="EarlierYears";more.flat=true;more.text="Earlier years"
		more.add_theme_color_override("font_color",T.GOLD)
		more.pressed.connect(func()->void:shown+=PAGE;_render_list())
		list.add_child(more)


## How many lines the list holds and whether "Earlier years" follows them.
func _list_shape_now()->Array:
	return [years.size()<2,mini(years.size(),shown),years.size()>shown]


## What a year's line is drawn from: its record without the year's entries
## and account (a line shows only how many things were told), and whether it
## is the chosen year.
func _row_print(year:Dictionary,chosen:bool)->Array:
	var record:=year.duplicate()
	for heavy in ["story","tallies","text","age"]:record.erase(heavy)
	return [record.duplicate(true),(year.get("story",[]) as Array).size(),chosen]


## A live refresh of the list: the same lines, with only those whose year
## changed drawn again in place.
func _update_list()->void:
	if _list_shape_now()!=_list_shape or list.get_child_count()<2+_row_prints.size():
		_render_list()
		return
	var chosen:=_chosen_index()
	var listed:=0
	for i in range(years.size()-1,-1,-1):
		if listed>=shown or listed>=_row_prints.size():break
		var row_print:=_row_print(years[i],i==chosen)
		if row_print!=_row_prints[listed]:
			# The old line goes first, so the new one keeps its name.
			var stale:=list.get_child(2+listed)
			list.remove_child(stale);stale.queue_free()
			var fresh:=_year_row(years[i],i==chosen)
			list.add_child(fresh);list.move_child(fresh,2+listed)
			_row_prints[listed]=row_print
		listed+=1


func _year_row(year:Dictionary,chosen:bool)->Button:
	var row:=Button.new();row.name="Year%d" % int(year.get("n",0));row.custom_minimum_size=Vector2(0,34);row.flat=not chosen
	if chosen:row.add_theme_stylebox_override("normal",T.flat(T.GOLD_WASH,T.GOLD,1,4,0))
	row.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.RULE,1,4,0))
	var line:=HBoxContainer.new();line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);line.offset_left=6;line.offset_right=-8
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_theme_constant_override("separation",10)
	var mark:=TextureRect.new();mark.custom_minimum_size=Vector2(24,24);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var glyph:=String(year.get("glyph","quiet"))
	mark.texture=Page.mark_texture(glyph,48)
	mark.modulate=Color(1,1,1,1.0 if String(year.get("name",""))!="" or not bool(year.get("closed",true)) else 0.55)
	line.add_child(mark)
	var number:=T.make_label(str(int(year.get("n",0))),13,T.GOLD);number.add_theme_font_override("font",T.font("display"));number.custom_minimum_size.x=36
	number.mouse_filter=Control.MOUSE_FILTER_IGNORE;number.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(number)
	var name:=String(year.get("name",""))
	var words:Label
	if not bool(year.get("closed",true)):words=_serif(_so_far(year),14,T.TEXT_SOFT,true)
	elif name!="":words=_serif(Page._cap(name),15,T.INK)
	else:words=T.make_label(Page._cap(Model.unnamed_words(year)),12,T.MUTED)
	words.autowrap_mode=TextServer.AUTOWRAP_OFF;words.clip_text=true;words.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.size_flags_vertical=Control.SIZE_SHRINK_CENTER;words.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(words)
	var pop:=int(year.get("pop",-1))
	if pop>0:
		var change:Variant=year.get("dpop")
		var tail:=""
		if change!=null and int(change)!=0:tail=" (%s%d)" % ["+" if int(change)>0 else "−",absi(int(change))]
		var people:=T.make_label("%d%s" % [pop,tail],11,T.MUTED);people.mouse_filter=Control.MOUSE_FILTER_IGNORE;people.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		line.add_child(people)
	row.add_child(line)
	row.tooltip_text=Page.mark_caption(year)
	row.pressed.connect(func()->void:_choose(int(year.get("n",-1)));_reveal_hero())
	return row


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
