extends VBoxContainer
## THE STANDING BOARD: the heart of the game on one page, dense.
##
##   ┌ what we are: our seal and name, the words our shape makes of us, the
##   │ rose of nine strengths beside the nine as one-line rows (name, a bar
##   │ with the age's typical value ticked, the value, the year's change and
##   │ the biggest cause; the rest in each row's pointer), a one-line legend
##   │ and the peoples whose shape can be laid over ours
##   ├ dangers beyond the first (the page's brief): one line each, a verb
##   ├ how each people we know sees us: a table of six feelings, with a Talk
##   ├ who leads the four races, what our cunning and persuasion do
##   └ our own people: pride, love and dread of the god, trust in the chiefs
##
## Data: content/dock_content_standing.gd (standing.gd, the one ledger). The
## live refresh updates this widget in place (update_block): a part is drawn
## again only when what it is drawn from changed.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI:=preload("res://scripts/hud/world_ui.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Standing:=preload("res://scripts/standing.gd")

## Below this width the parts under the rose stand in one column.
const TWO_AT:=820.0
const VIEW_INK:={"allure":"teal","awe":"gold","fear":"danger","respect":"info","trust":"good","resentment":"danger"}

## The rose of our nine strengths, drawn like a chart's wind rose. Its rings
## are the age's yardstick (standing_scale.gd): the middle ring a typical
## people of our age, the rim the most the age has seen. Every people we know
## is laid beside ours as a fine inked line, dashed where it is our watchers'
## estimate; the one chosen is drawn stronger, its uncertainty a soft band.
class Rose extends Control:
	signal picked(id:String)
	var strengths:Array=[]
	var ghost:Dictionary={}
	var theirs:Dictionary={}
	var their_color:=Color.WHITE
	var their_name:=""
	## Every people we know: [{values, color, name, chosen}].
	var others:Array=[]
	var highlight:=-1
	func _init()->void:
		custom_minimum_size=Vector2(196,196)
		mouse_filter=Control.MOUSE_FILTER_STOP
		size_flags_horizontal=Control.SIZE_EXPAND_FILL
		mouse_exited.connect(func()->void: set_highlight(-1))
	func configure(items:Array,year_ago:Dictionary)->void:
		strengths=items;ghost=year_ago;queue_redraw()
	func compare(values:Dictionary,tint:Color,name:String)->void:
		theirs=values;their_color=tint;their_name=name;queue_redraw()
	func overlay(list:Array)->void:
		others=list;queue_redraw()
	func _value_of(values:Dictionary,id:String,key:String="value")->float:
		var entry:Variant=values.get(id,{})
		return clampf(float((entry as Dictionary).get(key,(entry as Dictionary).get("value",0.0))),0.0,1.0) if entry is Dictionary else 0.0
	func _estimated(values:Dictionary)->bool:
		for item:Dictionary in strengths:
			var entry:Variant=values.get(String(item.id),{})
			if entry is Dictionary and not bool((entry as Dictionary).get("exact",true)): return true
		return false
	func _outline(values:Dictionary,key:String="value")->PackedVector2Array:
		var shape:=PackedVector2Array()
		for i in strengths.size(): shape.append(_point(i,maxf(0.02,_value_of(values,String(strengths[i].id),key))))
		return shape
	func set_highlight(index:int)->void:
		if index==highlight: return
		highlight=index;queue_redraw()
	func _center()->Vector2:
		return size*0.5
	func _radius()->float:
		return maxf(40.0,minf(size.x,size.y)*0.5-40.0)
	func _angle(index:int)->float:
		return -PI*0.5+TAU*float(index)/float(maxi(1,strengths.size()))
	func _point(index:int,amount:float)->Vector2:
		return _center()+Vector2.from_angle(_angle(index))*_radius()*clampf(amount,0.0,1.0)
	func _draw()->void:
		var count:=strengths.size()
		if count<3: return
		var center:=_center()
		var radius:=_radius()
		# The chart: four rings and nine spokes, in the rule's ink.
		draw_circle(center,radius+10.0,Color(T.PAPER_RAISED,0.9))
		# The middle ring is a typical people of our age, the rim the most the
		# age has seen (standing_scale.gd): both drawn a little stronger.
		for ring in [0.25,0.5,0.75,1.0]:
			var outline:=PackedVector2Array()
			for i in count+1: outline.append(center+Vector2.from_angle(_angle(i%count))*radius*ring)
			draw_polyline(outline,T.RULE_STRONG if ring==1.0 or ring==0.5 else T.RULE,1.4 if ring==1.0 else (1.2 if ring==0.5 else 1.0),true)
		for i in count:
			draw_line(center,center+Vector2.from_angle(_angle(i))*radius,T.RULE_STRONG if i==highlight else T.RULE,2.0 if i==highlight else 1.0,true)
		# Last year's shape, faint, so the change shows.
		if not ghost.is_empty():
			var past:=PackedVector2Array()
			for i in count: past.append(_point(i,float(ghost.get(String(strengths[i].id),0.0))/100.0))
			past.append(past[0])
			for i in past.size()-1: _dashes(past[i],past[i+1],T.INK_MUTED,1.2,4.0)
		# Every people we know, fine and faint behind ours: dashed where it is
		# our watchers' estimate, a whole line where we know them well.
		for other:Dictionary in others:
			if bool(other.get("chosen",false)): continue
			var values:Dictionary=other.get("values",{})
			var tint:Color=other.get("color",T.INK_MUTED)
			var line:=_outline(values)
			line.append(line[0])
			if _estimated(values):
				for i in line.size()-1: _dashes(line[i],line[i+1],Color(tint.darkened(0.1),0.8),1.5,5.0)
			else: draw_polyline(line,Color(tint.darkened(0.1),0.8),1.5,true)
		# The people chosen beside ours: how unsure we are of them as a soft
		# band (between the low and the high of each estimate), a light wash
		# and a stronger line.
		if not theirs.is_empty():
			var shape:=_outline(theirs)
			var unsure:=_estimated(theirs)
			if unsure:
				var low:=_outline(theirs,"low")
				var high:=_outline(theirs,"high")
				for i in count:
					var j:=(i+1)%count
					var quad:=PackedVector2Array([low[i],low[j],high[j],high[i]])
					if Geometry2D.triangulate_polygon(quad).size()>=3: draw_colored_polygon(quad,Color(their_color.darkened(0.35),0.16))
			elif shape.size()>=3: draw_colored_polygon(shape,Color(their_color,0.10))
			shape.append(shape[0])
			if unsure:
				for i in shape.size()-1: _dashes(shape[i],shape[i+1],their_color.darkened(0.35),2.4,7.0)
			else: draw_polyline(shape,their_color.darkened(0.35),2.4,true)
		# Ours: a gold wash and a gold line.
		var ours:=PackedVector2Array()
		for i in count: ours.append(_point(i,maxf(0.02,float(strengths[i].value))))
		draw_colored_polygon(ours,Color(T.GOLD,0.20))
		var line:=ours.duplicate();line.append(ours[0])
		draw_polyline(line,T.GOLD,2.6,true)
		for i in count:
			draw_circle(ours[i],5.0 if i==highlight else 3.6,T.GOLD)
			draw_circle(ours[i],1.8,T.PAPER_RAISED)
		# The names round the rim, with the value under each.
		var strong:=T.font("ui_strong")
		var plain:=T.FONT_UI
		for i in count:
			var item:Dictionary=strengths[i]
			var direction:=Vector2.from_angle(_angle(i))
			var anchor:=center+direction*(radius+10.0)
			var name:=String(item.name)
			var value:="%d%%" % roundi(float(item.value)*100.0)
			var name_size:=strong.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
			var value_size:=plain.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
			var block_width:=maxf(name_size.x,value_size.x)
			var x:=anchor.x-block_width*0.5
			if direction.x>0.35: x=anchor.x
			elif direction.x<-0.35: x=anchor.x-block_width
			var y:=anchor.y-2.0
			if direction.y<-0.6: y=anchor.y-15.0
			elif direction.y>0.6: y=anchor.y+10.0
			draw_string(strong,Vector2(x+(block_width-name_size.x)*(0.0 if direction.x>0.35 else 1.0 if direction.x<-0.35 else 0.5),y),name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.GOLD_TEXT if i==highlight else T.INK)
			draw_string(plain,Vector2(x+(block_width-value_size.x)*(0.0 if direction.x>0.35 else 1.0 if direction.x<-0.35 else 0.5),y+13.0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)
	func _dashes(from:Vector2,to:Vector2,color:Color,width:float,dash:float)->void:
		var length:=from.distance_to(to)
		if length<0.5: return
		var step:=dash*2.0
		var along:=0.0
		while along<length:
			var start:=from.lerp(to,along/length)
			var end:=from.lerp(to,minf(length,along+dash)/length)
			draw_line(start,end,color,width,true)
			along+=step
	func _index_at(at:Vector2)->int:
		var offset:=at-_center()
		if offset.length()<12.0 or offset.length()>_radius()+72.0: return -1
		var count:=strengths.size()
		var best:=-1
		var best_gap:=INF
		for i in count:
			var gap:=absf(angle_difference(offset.angle(),_angle(i)))
			if gap<best_gap: best_gap=gap;best=i
		return best
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseMotion: set_highlight(_index_at((event as InputEventMouseMotion).position))
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			var index:=_index_at((event as InputEventMouseButton).position)
			if index>=0: picked.emit(String(strengths[index].id))
	func _get_tooltip(at_position:Vector2)->String:
		var index:=_index_at(at_position)
		if index<0: return ""
		var item:Dictionary=strengths[index]
		var text:="%s %d%%: %s.\n%s." % [String(item.name),roundi(float(item.value)*100.0),String(item.means),String(item.why).left(1).to_upper()+String(item.why).substr(1)]
		for other:Dictionary in others:
			var entry:Variant=(other.get("values",{}) as Dictionary).get(String(item.id),{})
			if entry is Dictionary: text+="\n%s: %s." % [String(other.get("name","")),Standing.estimate_words(entry as Dictionary)]
		text+="\n50% is a typical people of our age; 100% the most the age has seen."
		return text+"\nClick to open %s." % String(item.section_name)

var data:Dictionary={}
var prints:Dictionary={}
var rose:Rose
var seal:TextureRect
var name_label:Label
var posture_label:Label
var renown_label:Label
var strength_list:VBoxContainer
var compare_row:HFlowContainer
## The rose's one-line legend, at the head of the compare line.
var legend_label:Label
var dangers:VBoxContainer
var peoples:VBoxContainer
var lower:GridContainer
var races:VBoxContainer
var arts:VBoxContainer
var home:VBoxContainer

func setup(block:Dictionary)->void:
	name="StandingBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	_build_hero()
	dangers=VBoxContainer.new();dangers.name="Dangers";dangers.add_theme_constant_override("separation",2);add_child(dangers)
	peoples=UI.sheet(self,"Peoples")
	lower=UI.columns(self,"Lower")
	races=UI.sheet(lower,"WhoLeads")
	arts=UI.sheet(lower,"Arts")
	home=UI.sheet(lower,"Home")
	resized.connect(_layout)
	apply(block)
	_layout()

## The live refresh: same widget, new data.
func update_block(block:Dictionary)->bool:
	apply(block)
	return true

func apply(block:Dictionary)->void:
	data=block
	name_label.text=String(block.get("people_name","Our people"))
	posture_label.text=String((block.get("posture",{}) as Dictionary).get("words",""))
	var renown:Dictionary=block.get("renown",{})
	renown_label.text="awe %d%% · allure %d%%" % [roundi(float(renown.get("awe",0.0))*100.0),roundi(float(renown.get("allure",0.0))*100.0)] if not renown.is_empty() else ""
	seal.texture=Identity.emblem("player")
	_refill("strengths",[block.get("strengths",[]),block.get("year_ago",{})],_fill_strengths)
	_refill("compare",[_compare_print(),String((block.get("view_state",{}) as Dictionary).get("compare",""))],_fill_compare)
	_refill("dangers",block.get("warnings",[]),_fill_dangers)
	_refill("peoples",block.get("peoples",[]),_fill_peoples)
	_refill("races",_races_print(block.get("races",[])),_fill_races)
	_refill("arts",block.get("arts",{}),_fill_arts)
	_refill("home",block.get("home",{}),_fill_home)

func _refill(part:String,value:Variant,fill:Callable)->void:
	var print:=preload("res://scripts/hud/dock_panel.gd").fingerprint(value)
	if String(prints.get(part,""))==print: return
	prints[part]=print
	fill.call()

func _layout()->void:
	if lower!=null:lower.columns=3 if size.x>=600.0 else 1

func _compare_print()->Array:
	var out:Array=[]
	for p:Dictionary in data.get("peoples",[]): out.append([String(p.civ_id),not _comparable(p),p.get("theirs",{})])
	return out

## Whether a people's strengths can be laid over ours.
static func _comparable(p:Dictionary)->bool:
	return bool(p.get("comparable",not (p.get("theirs",{}) as Dictionary).is_empty()))

## A people's strengths for the rose: carried in the data for the people
## already chosen, otherwise asked of the provider when one is chosen.
func _theirs(p:Dictionary)->Dictionary:
	var theirs:Dictionary=p.get("theirs",{})
	if theirs.is_empty() and _comparable(p):
		var ask:Variant=data.get("their_strengths")
		if ask is Callable and (ask as Callable).is_valid():
			theirs=(ask as Callable).call(String(p.civ_id))
			p["theirs"]=theirs
	return theirs

static func _tone_color(tone:String)->Color:
	match tone:
		"danger": return T.RED
		"warning": return T.AMBER
		"good": return T.TEAL
	return T.INK_MUTED

# ----------------------------------------------------------------- the hero

func _build_hero()->void:
	var column:=UI.sheet(self,"WhatWeAre",14.0)
	column.add_theme_constant_override("separation",6)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);column.add_child(top)
	seal=TextureRect.new();seal.name="Seal"
	seal.custom_minimum_size=Vector2(34,34);seal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;seal.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	top.add_child(seal)
	name_label=Label.new();name_label.name="PeopleName"
	name_label.add_theme_font_override("font",T.voice_font(false));name_label.add_theme_font_size_override("font_size",22)
	name_label.add_theme_color_override("font_color",T.INK);name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	top.add_child(name_label)
	posture_label=Label.new();posture_label.name="Posture"
	posture_label.add_theme_font_override("font",T.voice_font(true));posture_label.add_theme_font_size_override("font_size",16)
	posture_label.add_theme_color_override("font_color",T.BODY);posture_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	posture_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;posture_label.clip_text=true;posture_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(posture_label)
	renown_label=UI.label(top,"",12,T.INK_MUTED);renown_label.name="Renown"
	renown_label.tooltip_text="What our name commands by what we are: awe from might, great works and a lead in learning; allure from our culture, plenty, learning and good order. Both make our own people proud; allure draws others to us, awe makes them wary."
	var body:=HBoxContainer.new();body.name="Strengths";body.add_theme_constant_override("separation",12);column.add_child(body)
	rose=Rose.new();rose.name="Rose"
	rose.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;rose.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	rose.picked.connect(_raise)
	body.add_child(rose)
	strength_list=VBoxContainer.new();strength_list.name="StrengthList"
	strength_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;strength_list.add_theme_constant_override("separation",0)
	body.add_child(strength_list)
	compare_row=HFlowContainer.new();compare_row.name="Compare"
	compare_row.add_theme_constant_override("h_separation",6);compare_row.add_theme_constant_override("v_separation",4)
	column.add_child(compare_row)
	var legend:=UI.label(null,"Gold: ours · dashes: a year ago · tick: typical of our age",12,T.INK_MUTED)
	legend.name="Legend"
	legend.tooltip_text="Each strength is set against the peoples of our age: 50% (the rose's middle ring, the tick on each bar) is a typical people, 80% what the best of them managed, 100% (the rim) the most the age has seen. Dashed lines are our watchers' estimates."
	legend_label=legend

## A strength's biggest cause in a few words: the first part of the engine's
## reason ("1 under arms or training", "food for 29 days").
static func cause(why:String)->String:
	var first:=why
	# A grouped number keeps its comma ("2,500 goods"): only ", " ends a part.
	for mark:String in ["; "," (",": ",", "]:
		var at:=first.find(mark)
		if at>0:first=first.substr(0,at)
	var words:=first.strip_edges().split(" ",false)
	if words.size()>6:return " ".join(words.slice(0,6))+"…"
	return " ".join(words)

func _fill_strengths()->void:
	var items:Array=data.get("strengths",[])
	var year_ago:Dictionary=data.get("year_ago",{})
	rose.configure(items,year_ago)
	UI.clear(strength_list)
	var head:=UI.line(strength_list,8);head.name="Header"
	UI.cell(head,"",72,12,T.INK_MUTED,true)
	UI.cell(head,"vs the age",70,12,T.INK_MUTED)
	UI.cell(head,"",34,12,T.INK_MUTED)
	UI.cell(head,"a year" if not year_ago.is_empty() else "",34,12,T.INK_MUTED,false,HORIZONTAL_ALIGNMENT_RIGHT)
	UI.label(head,"biggest cause",12,T.INK_MUTED,false,true)
	for index in items.size():
		var item:Dictionary=items[index]
		var id:=String(item.id)
		var tip:="%s %d%%: %s.\n%s.%s\nRaised through %s; it costs %s. Click to open it." % [String(item.name),roundi(float(item.value)*100.0),String(item.means),_sentence(String(item.why)),("\nAgainst the age: %s." % String(item.parts)) if String(item.get("parts",""))!="" else "",String(item.section_name),String(item.cost)]
		var row:=UI.hot_row(strength_list,"Strength_"+id,_raise.bind(id),tip)
		var panel:=row.get_parent() as Control
		panel.mouse_entered.connect(func()->void:rose.set_highlight(index))
		panel.mouse_exited.connect(func()->void:rose.set_highlight(-1))
		UI.cell(row,String(item.name),72,13,T.INK,true)
		var bar:=UI.bar(row,float(item.value),T.GOLD,70,0.5)
		if year_ago.has(id):bar.ghost=clampf(float(year_ago[id])/100.0,0.0,1.0)
		bar.tooltip_text=tip
		UI.cell(row,"%d%%" % roundi(float(item.value)*100.0),34,13,T.INK,true,HORIZONTAL_ALIGNMENT_RIGHT)
		var change_text:=""
		var change_ink:=T.INK_MUTED
		if item.has("change"):
			var change:=float(item.change)
			change_text="·" if absf(change)<1.0 else ("%s%d" % ["+" if change>0.0 else "−",roundi(absf(change))])
			change_ink=T.INK_MUTED if absf(change)<1.0 else (T.GREEN_TEXT if change>0.0 else T.RED_TEXT)
		UI.cell(row,change_text,34,12,change_ink,true,HORIZONTAL_ALIGNMENT_RIGHT)
		UI.label(row,cause(String(item.why)),12,T.BODY,false,true)

func _raise(id:String)->void:
	var raise:Variant=data.get("on_raise")
	if not raise is Callable or not (raise as Callable).is_valid(): return
	for item:Dictionary in data.get("strengths",[]):
		if String(item.id)==id:
			(raise as Callable).call(String(item.section),int(item.sub))
			return

func _fill_compare()->void:
	if legend_label!=null and legend_label.get_parent()==compare_row:compare_row.remove_child(legend_label)
	UI.clear(compare_row)
	if legend_label!=null:compare_row.add_child(legend_label)
	var list:Array=data.get("peoples",[])
	var state:Dictionary=data.get("view_state",{})
	var chosen:=String(state.get("compare",""))
	var shown:=false
	if list.is_empty():
		rose.compare({},Color.WHITE,"")
		rose.overlay([])
		return
	var overlays:Array=[]
	for p:Dictionary in list:
		if not _comparable(p): continue
		var values:=_theirs(p)
		if values.is_empty(): continue
		overlays.append({"values":values,"color":p.get("accent",T.RED),"name":String(p.name),"chosen":String(p.civ_id)==chosen})
	rose.overlay(overlays)
	UI.label(compare_row,"· over ours:",12,T.INK_MUTED)
	for p:Dictionary in list:
		var comparable:=_comparable(p)
		var civ_id:=String(p.civ_id)
		var toggle:=func()->void:
			state["compare"]="" if String(state.get("compare",""))==civ_id else civ_id
			prints.erase("compare")
			_fill_compare()
		var chip_tip:="We know too little of them yet: our watchers cannot say how strong they are." if not comparable else "Draw %s's strengths, as our watchers reckon them, stronger over ours. %s" % [String(p.name),String(p.get("known_words",""))]
		var chip:=UI.chip(compare_row,String(p.name),civ_id==chosen,toggle,chip_tip)
		chip.name="Compare_"+civ_id
		chip.icon=_dot(p.get("accent",T.RED)) if comparable else null
		chip.disabled=not comparable
		if civ_id==chosen and comparable:
			var theirs:=_theirs(p)
			if theirs.is_empty():continue
			rose.compare(theirs,p.get("accent",T.RED),String(p.name))
			shown=true
	if not shown: rose.compare({},Color.WHITE,"")

## A small inked dot in a people's colour, for its chip (the rose's legend).
static var _dots:Dictionary={}
static func _dot(tint:Color)->Texture2D:
	var key:=tint.to_html()
	if _dots.has(key): return _dots[key]
	var image:=Image.create(12,12,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	for y in 12:
		for x in 12:
			var d:=Vector2(x-5.5,y-5.5).length()
			if d<=5.0: image.set_pixel(x,y,Color(tint,clampf(5.5-d,0.0,1.0)))
	var texture:=ImageTexture.create_from_image(image)
	_dots[key]=texture
	return texture

# -------------------------------------------------------------- the dangers

## The dangers after the first (the page's brief already says that one).
func _fill_dangers()->void:
	UI.clear(dangers)
	var warnings:Array=data.get("warnings",[])
	dangers.visible=warnings.size()>1
	if warnings.size()<=1:return
	var raise:Variant=data.get("on_raise")
	# One button for each action: the brief above already carries the first's.
	var offered:={String((warnings[0] as Dictionary).get("action","")):true}
	for warning:Dictionary in warnings.slice(1,6):
		var row:=UI.line(dangers,8)
		row.tooltip_text=String(warning.words)
		var dot:=ColorRect.new();dot.custom_minimum_size=Vector2(8,8);dot.color=_tone_color(String(warning.tone));dot.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(dot)
		var title:=UI.label(row,String(warning.title),13,T.text_for(_tone_color(String(warning.tone))),true,true)
		title.tooltip_text=String(warning.words)
		if String(warning.get("section",""))!="" and raise is Callable and not offered.has(String(warning.get("action",""))):
			offered[String(warning.get("action",""))]=true
			var section:=String(warning.section)
			var sub:=int(warning.get("sub",0))
			UI.verb(row,String(warning.get("action","Open")),func()->void:(raise as Callable).call(section,sub),String(warning.words))

# -------------------------------------------------------------- the peoples

## How each people we know sees us: one row each, six feelings as bars.
func _fill_peoples()->void:
	UI.clear(peoples)
	var list:Array=data.get("peoples",[])
	UI.heading(peoples,"How the peoples we know see us")
	if list.is_empty():
		var row:=UI.line(peoples,8);row.name="NoPeoples"
		UI.label(row,"No other people has met us yet",12,T.INK_MUTED,false,true)
		var scouts:Variant=data.get("on_scouts")
		if scouts is Callable:UI.verb(row,"Send scouts",scouts as Callable,"Send scouts to find the peoples around us",true)
		return
	var head:=UI.line(peoples,6)
	var first:=UI.label(head,"",12,T.INK_MUTED,true,true);first.custom_minimum_size.x=110
	for view:Dictionary in (list[0] as Dictionary).get("views",[]):
		var title:=UI.cell(head,String(view.name).replace("Resentment","Resent"),62,12,T.INK_MUTED,true)
		title.tooltip_text=String(view.means)
	UI.cell(head,"",46,12,T.INK_MUTED)
	var on_court:Variant=data.get("on_court")
	for p:Dictionary in list:
		var row:=UI.hot_row(peoples,"People_"+String(p.civ_id),Callable(),_people_tip(p))
		var name_cell:=HBoxContainer.new();name_cell.add_theme_constant_override("separation",5);name_cell.custom_minimum_size.x=110;name_cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_cell.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(name_cell)
		var emblem:=TextureRect.new();emblem.texture=p.get("emblem") as Texture2D;emblem.custom_minimum_size=Vector2(18,18)
		emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		emblem.mouse_filter=Control.MOUSE_FILTER_PASS;name_cell.add_child(emblem)
		UI.label(name_cell,String(p.name),13,T.INK,true,true)
		for pair:Array in [["envy","envy",Standing.ENVY_RAID_FLOOR],["contempt","scorn",Standing.CONTEMPT_FLOOR]]:
			if float(p.get(String(pair[0]),0.0))>float(pair[2]):
				UI.tag(name_cell,String(pair[1]),"danger").tooltip_text="%s %d%%: %s" % [String(pair[0]).capitalize(),roundi(float(p.get(String(pair[0]),0.0))*100.0),String(p.get(String(pair[0])+"_why",""))]
		for view:Dictionary in p.get("views",[]):
			var cell:=HBoxContainer.new();cell.add_theme_constant_override("separation",3);cell.custom_minimum_size.x=62;row.add_child(cell)
			cell.tooltip_text="%s %d%%: %s.\nWhy: %s." % [String(view.name),roundi(float(view.value)*100.0),String(view.means),String(view.why)]
			cell.mouse_filter=Control.MOUSE_FILTER_PASS
			var b:=UI.bar(cell,float(view.value),UI.tone_color(String(VIEW_INK.get(String(view.id),"gold"))),30)
			b.tooltip_text=cell.tooltip_text
			UI.label(cell,"%d" % roundi(float(view.value)*100.0),12,T.INK).tooltip_text=cell.tooltip_text
		var talk:=HBoxContainer.new();talk.custom_minimum_size.x=46;row.add_child(talk)
		if on_court is Callable:
			var civ_id:=String(p.civ_id)
			UI.verb(talk,"Talk",func()->void:(on_court as Callable).call(civ_id),"Open the court to receive their envoy or send ours").name="Talk"

static func _people_tip(p:Dictionary)->String:
	var lines:PackedStringArray=[String(p.name)+": "+String(p.relation)]
	if String(p.get("ruler",""))!="":lines.append(String(p.ruler))
	if String(p.get("headline",""))!="":lines.append(String(p.headline))
	lines.append(String(p.get("strength",""))+".")
	var spies:Dictionary=p.get("spies",{})
	if not spies.is_empty():lines.append(String(spies.get("words",""))+".")
	for c:Dictionary in p.get("consequences",[]):lines.append("· "+String(c.words))
	for memory:Dictionary in p.get("memories",[]):lines.append(String(memory.text))
	if String(p.get("known_words",""))!="":lines.append(String(p.known_words))
	return "\n".join(lines)

# ------------------------------------------------- who leads, arts, our people

## What the races draw, so a day's small moves in a value redraw nothing.
static func _races_print(list:Array)->Array:
	var out:Array=[]
	for race:Dictionary in list:
		var rows:Array=[]
		for row:Dictionary in race.rows:rows.append([String(row.name),String(row.text),String(row.get("said","")),String(row.get("source","")),bool(row.unknown),roundi(float(row.value)*20.0) if float(row.value)<=1.0 else roundi(log(maxf(1.0,float(row.value)))*8.0)])
		out.append([String(race.id),String(race.standing),rows])
	return out

func _fill_races()->void:
	UI.clear(races)
	var list:Array=data.get("races",[])
	races.get_parent().visible=not list.is_empty()
	if list.is_empty(): return
	UI.heading(races,"Who leads")
	for race:Dictionary in list:
		var lines:PackedStringArray=[]
		for row:Dictionary in race.rows:lines.append("%s: %s%s" % [String(row.name),String(row.text),(" (%s)" % String(row.source)) if String(row.get("source",""))!="" else ""])
		lines.append("Asks: %s." % String(race.ask))
		var row:=UI.line(races,6);row.name="Race_"+String(race.id)
		row.tooltip_text="\n".join(lines)
		UI.cell(row,String(race.race),80,13,T.INK,true).tooltip_text=row.tooltip_text
		var words:=UI.label(row,String(race.standing),12,T.BODY,false,true)
		words.tooltip_text=row.tooltip_text

## What our cunning and persuasion do this month: one row each, every effect
## in its pointer (standing.gd arts_at_work).
func _fill_arts()->void:
	UI.clear(arts)
	var at_work:Dictionary=data.get("arts",{})
	arts.get_parent().visible=not at_work.is_empty()
	if at_work.is_empty():return
	UI.heading(arts,"Cunning and persuasion at work")
	for pair:Array in [["cunning","Cunning",float(at_work.get("cunning_value",0.5))],["persuasion","Persuasion",float(at_work.get("persuasion_value",0.5))]]:
		var effects:Array=at_work.get(String(pair[0]),[])
		var lines:PackedStringArray=[]
		for e:Dictionary in effects:lines.append("· %s%s" % [String(e.words),(" — "+String(e.detail)) if String(e.get("detail",""))!="" else ""])
		var row:=UI.line(arts,6);row.name="Arts_"+String(pair[0])
		row.tooltip_text="\n".join(lines)
		UI.cell(row,String(pair[1]),80,13,T.INK,true)
		UI.bar(row,float(pair[2]),T.TEAL if String(pair[0])=="cunning" else T.GOLD,44,0.5).tooltip_text=row.tooltip_text
		UI.cell(row,"%d%%" % roundi(float(pair[2])*100.0),36,12,T.INK,true,HORIZONTAL_ALIGNMENT_RIGHT)
		UI.label(row,String((effects[0] as Dictionary).words) if not effects.is_empty() else "",12,T.BODY,false,true).tooltip_text=row.tooltip_text

## Our own people: four short rows and what they tell.
func _fill_home()->void:
	UI.clear(home)
	var h:Dictionary=data.get("home",{})
	var words:=_home_words(h)
	var head:=UI.heading(home,"Our own people")
	head.tooltip_text=String(words.note)+("\n"+String(words.god) if words.has("god") else "")+("\n"+String(words.forgiving) if words.has("forgiving") else "")
	for medal:Array in _home_medals(h):
		var row:=UI.line(home,6);row.name="Home_"+String(medal[0]).replace(" ","")
		row.tooltip_text=String(medal[4])
		UI.cell(row,String(medal[0]),80,13,T.INK,true)
		UI.bar(row,float(medal[1]),medal[2],44).tooltip_text=String(medal[4])
		UI.cell(row,"%d%%" % roundi(float(medal[1])*100.0),36,12,T.INK,true,HORIZONTAL_ALIGNMENT_RIGHT)
		UI.label(row,String(medal[3]),12,T.INK_MUTED,false,true)
	if words.has("levy"):
		var heavy:=UI.label(home,"Heavy levy: %d%% under arms" % roundi(float((h.get("effects",{}) as Dictionary).get("under_arms",0.0))*100.0),12,T.RED_TEXT,true)
		heavy.tooltip_text=String(words.levy)
	if String(h.get("regard_words",""))!="":
		var said:=Label.new();said.text=String(words.regard);said.add_theme_font_override("font",T.voice_font(true));said.add_theme_font_size_override("font_size",15)
		said.add_theme_color_override("font_color",T.BODY);said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		said.tooltip_text=String(h.get("told",""));said.mouse_filter=Control.MOUSE_FILTER_PASS
		home.add_child(said)

## The four medallions: [title, value, ink, word, tip].
static func _home_medals(h:Dictionary)->Array:
	var pride:=float(h.get("pride",0.5))
	var trust:=float(h.get("trust",0.5))
	return [["Pride",pride,T.GREEN,"proud" if pride>=0.62 else ("ashamed" if pride<0.42 else "ordinary"),"How proud our people are of who they are: %s." % String(h.get("pride_why",""))],
		["Love of you",float(h.get("love",0.5)),T.GOLD,_band(float(h.get("love",0.5))),"How much our people love their god."],
		["Dread of you",float(h.get("dread",0.0)),T.RED,_band(float(h.get("dread",0.0))),"How much our people dread their god's wrath."],
		["Trust in chiefs",trust,T.TEAL,_band(trust),"How much our people trust those who lead them."]]

## The words about our own people: our regard, the month's effects, a heavy
## levy and forgiveness (the last two only when they apply).
static func _home_words(h:Dictionary)->Dictionary:
	var words:={"regard":_sentence(String(h.get("regard_words","")))+"."}
	var effects:Dictionary=h.get("effects",{})
	var parts:PackedStringArray=[]
	for pair:Array in [["attraction","how much families want to join us and stay"],["cohesion","how well we hold together"],["legitimacy","trust in the chiefs"],["menace","our warbands put off newcomers"]]:
		var amount:=float(effects.get(String(pair[0]),0.0))
		if absf(amount)<0.05: continue
		parts.append("%s %s%.1f" % [String(pair[1]),"+" if amount>0.0 else "−",absf(amount)])
	words["note"]=("This month, in points of 100: "+"; ".join(parts)+".") if not parts.is_empty() else "Pride is ordinary this month: it neither draws people to us nor holds them."
	var god:Dictionary=effects.get("god",{}) if effects.get("god") is Dictionary else {}
	var god_parts:PackedStringArray=[]
	for pair:Array in [["draw","their love draws families in"],["bind","love binds them"],["obey_love","love lends the chiefs' word weight"],["drive_off","dread drives families off"],["fray","dread frays them"],["obey_dread","dread makes them obey"]]:
		var amount:=float(god.get(String(pair[0]),0.0))
		if absf(amount)<0.05: continue
		god_parts.append("%s %s%.1f" % [String(pair[1]),"+" if amount>0.0 else "−",absf(amount)])
	if not god_parts.is_empty(): words["god"]="What they feel for you does this month, in points of 100: "+"; ".join(god_parts)+"."
	var levy:=float(effects.get("levy",0.0))
	if levy>0.0:
		words["levy"]="%d%% of the people are under arms: more than households carry without complaint. Holding together −%.1f and trust in the chiefs −%.1f, in points of 100." % [roundi(float(effects.get("under_arms",0.0))*100.0),float(effects.get("levy_cohesion",levy*60.0)),float(effects.get("levy_trust",levy*40.0))]
	var forgiving:=float(effects.get("forgiveness",0.0))
	if absf(forgiving)>=0.02:
		words["forgiving"]=("A proud people forgives: the blame its chiefs carry for hard orders, constant change and failed aims is %d%% lighter." % roundi(forgiving*100.0)) if forgiving>0.0 else ("A people ashamed of itself blames its chiefs %d%% more for hard orders, constant change and failed aims." % roundi(-forgiving*100.0))
	return words

## First letter up, the rest as written.
static func _sentence(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if text!="" else text

static func _band(value:float)->String:
	if value<0.15: return "none"
	if value<0.35: return "a little"
	if value<0.6: return "some"
	if value<0.8: return "much"
	return "great"
