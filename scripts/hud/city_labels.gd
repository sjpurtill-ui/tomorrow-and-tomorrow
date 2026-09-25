extends Control
## A shared screen-space label layer. World positions and city reports stay authoritative.
const NAME_SIZE:=16
const POP_SIZE:=13
const GAP:=7.0
const REPORT=preload("res://scripts/hud/city_report_visuals.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const MODERN_LABELS:={"population":"POP · PEOPLE","science_capacity":"SCIENCE · MIND-EQ.","gdp":"GDP · WORK-DAYS/D","life_expectancy":"HEALTH · LIFE EXP."}
## What scouts can say of a stranger town before anyone keeps statistics.
const EARLY_LABELS:={"population":"PEOPLE","science_capacity":"LORE-KEEPERS","gdp":"HANDS AT WORK","life_expectancy":"LIVES · WINTERS"}
## Once the people write, reports read like a register, still without statistics.
const LETTERED_LABELS:={"population":"PEOPLE","science_capacity":"LEARNED","gdp":"DAILY LABOUR","life_expectancy":"LIVES · YEARS"}
## How long the pointer rests on a name before the full report opens.
const HOVER_DELAY:=0.35

static func report_summary(record:Dictionary,today:int)->Dictionary:
	var fields:Dictionary=record.get("fields",{})
	var stats:Array[Dictionary]=[]
	var stage:=EraWords.stage()
	var labels:Dictionary=MODERN_LABELS if stage=="reckoned" else LETTERED_LABELS if stage=="lettered" else EARLY_LABELS
	for key:String in ["population","science_capacity","gdp","life_expectancy"]:
		var field:Dictionary=fields.get(key,{})
		stats.append({"key":key,"label":String(labels[key]),"value":stat_value(key,field,stage),"detail":stat_detail(key,fields,stage)})
	var fresh:=REPORT.freshness(record,today)
	return {"stats":stats,"level":fresh.level,"status":fresh.status,"heading":"REPORT" if stage=="reckoned" else "WORD" if stage=="hearth" else "ACCOUNT"}

## A scout's figure: whole, rounded numbers before the statistical age.
static func stat_value(key:String,field:Dictionary,stage:String)->String:
	if field.is_empty():return "Unknown"
	if stage=="reckoned":return REPORT.estimate(key,field)
	var range:=REPORT.bounds(field)
	var text:=round_range(range.x,range.y)
	if key=="life_expectancy":text+=" winters" if stage=="hearth" else " years"
	return text

static func stat_detail(key:String,fields:Dictionary,stage:String)->String:
	var extra:=String({"science_capacity":"education","life_expectancy":"infant_mortality"}.get(key,""))
	if extra.is_empty() or fields.get(extra,{}).is_empty():return ""
	var field:Dictionary=fields[extra]
	if stage=="reckoned":return ("Edu " if key=="science_capacity" else "IMR ")+REPORT.estimate(extra,field)
	var range:=REPORT.bounds(field)
	if key=="science_capacity":
		var taught:=(range.x+range.y)*.5
		return "most are taught" if taught>=.8 else "many are taught" if taught>=.6 else "some are taught" if taught>=.4 else "few are taught" if taught>=.2 else "almost none taught"
	if stage=="hearth":return "Babes lost: "+round_range(range.x/10.0,range.y/10.0)+" in 100"
	return "Infants lost: "+round_range(range.x,range.y)+" in 1,000"

## "90–140": two significant figures at most, as a scout would guess.
static func round_range(low:float,high:float)->String:
	var a:=nice_round(low);var b:=maxi(a,nice_round(high))
	return "about "+EraWords.grouped(a) if a==b else EraWords.grouped(a)+"–"+EraWords.grouped(b)

static func nice_round(value:float)->int:
	if value<20.0:return maxi(0,roundi(value))
	if value<100.0:return roundi(value/5.0)*5
	var step:=pow(10.0,floorf(log(value)/log(10.0))-1.0)
	return roundi(value/step)*roundi(step)

var terrain:Node
var sources:Dictionary={}
var cards:Array[Dictionary]=[]
var previous:Dictionary={}
var overflow:Array[Dictionary]=[]
var more:Button
var list_panel:PanelContainer
var list_rows:VBoxContainer
var list_signature:=""
var layout_signature:=""
var styles:Dictionary={}
## At rest each city shows only its name; the full card opens on hover, or stays
## open after a click or tap until the player clicks elsewhere.
var hover_id:=""
var hover_elapsed:=0.0
var pinned_id:=""
var last_bounds:=Rect2()

func _ready()->void:
	theme=T.control_theme()
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	more=Button.new();more.text="More cities";more.hide();add_child(more)
	more.pressed.connect(func():list_panel.visible=not list_panel.visible)
	list_panel=PanelContainer.new();list_panel.add_theme_stylebox_override("panel",T.flat(T.PANEL_BG_SOLID,T.BORDER_SOFT,1,5,8));list_panel.hide();add_child(list_panel)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;list_panel.add_child(scroll)
	list_rows=VBoxContainer.new();list_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list_rows)

func register_label(label:Label3D,id:String,foreign:bool,anchor:Vector3)->void:
	sources[id]={"label":weakref(label),"foreign":foreign,"anchor":anchor}
	# Keep legacy label data for existing update paths; draw the text and flag once.
	label.layers=0
	var flag:=label.get_node_or_null("CivilizationFlag") as Sprite3D
	if flag:flag.layers=0

static func arrange(entries:Array[Dictionary],bounds:Rect2,old:Dictionary={},reserved:Array[Rect2]=[])->Dictionary:
	var placed:Array[Dictionary]=[];var hidden:Array[Dictionary]=[];var memory:Dictionary={}
	var ordered:=entries.duplicate()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if bool(a.foreign)!=bool(b.foreign):return not bool(a.foreign)
		return String(a.id)<String(b.id))
	for entry:Dictionary in ordered:
		var anchor:Vector2=entry.anchor;var extent:Vector2=entry.extent
		var candidates:Array[Vector2]=[]
		if old.has(entry.id):candidates.append(anchor+Vector2(old[entry.id]))
		for row in range(12):
			var step:=float(row)*(extent.y+GAP)
			candidates.append(anchor+Vector2(-extent.x*.5,-extent.y-14-step))
			candidates.append(anchor+Vector2(-extent.x*.5,14+step))
			candidates.append(anchor+Vector2(18,-extent.y*.5+step))
			candidates.append(anchor+Vector2(-extent.x-18,-extent.y*.5-step))
		# Dense clusters can use free space elsewhere on the map, with leader lines.
		for y in range(int(bounds.position.y),int(bounds.end.y-extent.y)+1,int(extent.y+GAP)):
			for x in range(int(bounds.position.x),int(bounds.end.x-extent.x)+1,int(extent.x+GAP)):
				candidates.append(Vector2(x,y))
		var chosen:=Rect2();var best:=INF
		for index in candidates.size():
			var pos:Vector2=candidates[index]
			pos.x=clampf(pos.x,bounds.position.x,maxf(bounds.position.x,bounds.end.x-extent.x))
			pos.y=clampf(pos.y,bounds.position.y,maxf(bounds.position.y,bounds.end.y-extent.y))
			var rect:=Rect2(pos,extent)
			if not bounds.encloses(rect):continue
			var blocked:=false
			for obstacle:Rect2 in reserved:
				if rect.grow(GAP).intersects(obstacle):blocked=true;break
			for other:Dictionary in placed:
				if rect.grow(GAP*.5).intersects(other.rect.grow(GAP*.5)):blocked=true;break
			if blocked:continue
			# Protect the city pins as well as the other labels.
			for other:Dictionary in entries:
				if rect.grow(8).has_point(other.anchor):blocked=true;break
			if blocked:continue
			var score:=anchor.distance_squared_to(rect.get_center())
			if index==0 and old.has(entry.id):chosen=rect;break
			if score<best:best=score;chosen=rect
		if chosen.size==Vector2.ZERO:hidden.append(entry);continue
		var card:=entry.duplicate();card.rect=chosen;placed.append(card)
		memory[entry.id]=chosen.position-anchor
	return {"cards":placed,"overflow":hidden,"memory":memory}

func refresh()->void:
	if not is_instance_valid(terrain) or terrain.camera==null:return
	var camera:Camera3D=terrain.camera
	var viewport_size:=get_viewport().get_visible_rect().size
	var bounds:=Rect2(Vector2(90,100),(viewport_size-Vector2(110,170)).max(Vector2(100,100)))
	var reserved:Array[Rect2]=[]
	if is_instance_valid(terrain.get("founding_site_guide")):
		var guide:Control=terrain.get("founding_site_guide")
		if guide.is_visible_in_tree():reserved.append(guide.panel.get_global_rect())
	var entries:Array[Dictionary]=[]
	var font:=ThemeDB.fallback_font
	var signature:=str(viewport_size)+str(reserved)
	for id in sources.keys():
		var source:Dictionary=sources[id]
		var label:Label3D=source.label.get_ref()
		if not is_instance_valid(label) or label.is_queued_for_deletion():sources.erase(id);continue
		var kind:=String(label.get_meta("map_annotation_kind","city"))
		if kind=="founding_convoy" and is_instance_valid(terrain.get("settler_marker")):
			source.anchor=terrain.settler_marker.global_position
		if not label.is_visible_in_tree() or camera.is_position_behind(source.anchor):continue
		var anchor:=camera.unproject_position(source.anchor)
		if not Rect2(Vector2.ZERO,viewport_size).has_point(anchor):continue
		var parts:=label.text.split("  •  ",true,1)
		var title:=String(parts[0]);var count:=String(parts[1]) if parts.size()>1 else "Population unknown"
		if not count.begins_with("est.") and count!="Population unknown":count="Population "+count
		var status:=String(label.get_meta("map_status",""))
		var summary:Dictionary={}
		if bool(source.foreign):
			var record:Dictionary=CivilizationSystem.city_intelligence.records.get("player",{}).get(String(id),{})
			summary=report_summary(record,int(GameState.elapsed_days))
			status=summary.status
		var affiliation:=CivilizationSystem.city_intelligence.controller_label(String(label.get_meta("city_civilization_id",""))) if bool(source.foreign) else ""
		var lines:=wrap_name(title,font,minf(260,bounds.size.x-56))
		var width:=maxf(font.get_string_size(count,HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE).x,font.get_string_size(affiliation,HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE).x)+20
		for line:String in lines:width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE).x+54)
		width=maxf(width,font.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE).x+20)
		var flag:=label.get_node_or_null("CivilizationFlag") as Sprite3D
		var name_width:=54.0
		for line:String in lines:name_width=maxf(name_width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE).x+(56 if flag else 22))
		var detail:=Vector2(ceilf(maxf(135,width)),float(lines.size())*20+25+(18 if not affiliation.is_empty() else 0)+(20 if not status.is_empty() else 0))
		if not summary.is_empty():detail=Vector2(maxf(260,width),float(lines.size())*20+130)
		# The founding convoy is a prompt, not a city: it keeps its readout open.
		var compact:=kind!="founding_convoy"
		entries.append({"id":String(id),"kind":kind,"status":status,"foreign":source.foreign,"anchor":anchor,"title":title,"lines":lines,"population":count,"affiliation":affiliation,"color":label.modulate,"flag":flag.texture if flag else null,"compact":compact,"detail_extent":detail,"extent":Vector2(ceilf(name_width),float(lines.size())*20+10) if compact else detail})
		if not summary.is_empty():
			entries.back()["summary"]=summary
			signature+=str(summary)
		signature+=String(id)+str(anchor)+affiliation+status+label.text+str(label.modulate)+str(flag.texture.get_instance_id() if flag and flag.texture else 0)
	if signature==layout_signature:return
	layout_signature=signature
	last_bounds=bounds
	var result:=arrange(entries,bounds,previous,reserved)
	cards=result.cards;overflow=result.overflow;previous=result.memory
	_update_overflow(viewport_size)
	queue_redraw()

static func wrap_name(title:String,font:Font,width:float)->Array[String]:
	var lines:Array[String]=[];var line:=""
	for word:String in title.split(" "):
		var next:=word if line.is_empty() else line+" "+word
		if not line.is_empty() and font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE).x>width:lines.append(line);line=word
		else:line=next
	if not line.is_empty():lines.append(line)
	return lines

func _process(delta:float)->void:
	var waiting:=not hover_id.is_empty() and hover_elapsed<HOVER_DELAY
	hover_elapsed+=delta
	if waiting and hover_elapsed>=HOVER_DELAY:queue_redraw()
	refresh()

## The city whose full card is showing: a pinned (clicked/tapped) city, else the hovered one.
func expanded_id()->String:
	if not pinned_id.is_empty():return pinned_id
	return hover_id if hover_elapsed>=HOVER_DELAY else ""

func hover_at(point:Vector2)->void:
	var id:=String(city_at(point).get("id",""))
	if id==hover_id:return
	if not hover_id.is_empty() and expanded_id()==hover_id:queue_redraw()
	hover_id=id;hover_elapsed=0.0

func press_at(point:Vector2)->void:
	var id:=String(city_at(point).get("id",""))
	if id!=pinned_id:pinned_id=id;queue_redraw()

## Where the full card opens: over its name tag, kept on screen.
func detail_rect(card:Dictionary)->Rect2:
	var extent:Vector2=card.get("detail_extent",card.rect.size)
	var box:Rect2=card.rect
	var bounds:=last_bounds if last_bounds.has_area() else Rect2(Vector2.ZERO,get_viewport_rect().size)
	var pos:=box.position
	if pos.y+extent.y>bounds.end.y:pos.y=box.end.y-extent.y
	pos.x=clampf(pos.x,bounds.position.x,maxf(bounds.position.x,bounds.end.x-extent.x))
	pos.y=clampf(pos.y,bounds.position.y,maxf(bounds.position.y,bounds.end.y-extent.y))
	return Rect2(pos,extent)

func _input(event:InputEvent)->void:
	# Observe only; the map keeps handling clicks on cities as before.
	if event is InputEventMouseMotion:hover_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:press_at(event.position)
	elif event is InputEventScreenTouch and event.pressed:press_at(event.position)

func _unhandled_input(event:InputEvent)->void:
	if list_panel==null or not list_panel.visible:return
	if (event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT):
		list_panel.hide();get_viewport().set_input_as_handled()

func city_at(point:Vector2)->Dictionary:
	var open:=expanded_id()
	for card:Dictionary in cards:
		if String(card.id)==open and bool(card.get("compact",false)) and detail_rect(card).has_point(point):return card
	for card:Dictionary in cards:
		if card.rect.has_point(point):return card
	return {}

func _update_overflow(viewport_size:Vector2)->void:
	if more==null:return
	more.visible=not overflow.is_empty()
	more.text="%d more cities · list" % overflow.size()
	more.position=Vector2(viewport_size.x-230,viewport_size.y-56);more.size=Vector2(210,36)
	list_panel.position=Vector2(viewport_size.x-340,120);list_panel.size=Vector2(320,maxf(100,viewport_size.y-190))
	if overflow.is_empty():list_panel.hide()
	var signature:=""
	for entry:Dictionary in overflow:signature+=String(entry.id)+String(entry.title)+String(entry.population)+str(entry.get("summary",{}))+String(entry.get("status",""))+String(entry.get("affiliation",""))+str(entry.color)+str(entry.flag.get_instance_id() if entry.flag else 0)
	if signature==list_signature:return
	list_signature=signature
	for child in list_rows.get_children():list_rows.remove_child(child);child.queue_free()
	var close:=Button.new();close.text="Close city list";close.pressed.connect(func():list_panel.hide());list_rows.add_child(close)
	for entry:Dictionary in overflow:
		var button:=Button.new();button.text=String(entry.title)+( "\n"+String(entry.affiliation) if not String(entry.get("affiliation","")).is_empty() else "")+"\n"+String(entry.population)+( "\n"+String(entry.get("status","")) if not String(entry.get("status","")).is_empty() else "")
		if entry.has("summary"):
			button.text=String(entry.title)+" · "+String(entry.affiliation)
			for stat:Dictionary in entry.summary.stats:button.text+="\n"+String(stat.label)+"  "+String(stat.value)
			button.text+="\nIntel · "+String(entry.status)
		button.icon=entry.flag;button.expand_icon=true;button.add_theme_constant_override("icon_max_width",28)
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_color_override("font_color",entry.color);button.custom_minimum_size.y=54
		button.pressed.connect(func():
			list_panel.hide()
			if String(entry.get("kind",""))=="founding_convoy":terrain._on_settlement_action_pressed()
			elif entry.foreign:terrain._show_city_intel_summary(String(entry.id))
			else:terrain._focus_settlement_from_screen(entry.anchor,false,String(entry.id)))
		list_rows.add_child(button)

func _draw()->void:
	for card:Dictionary in cards:
		var box:Rect2=card.rect;var anchor:Vector2=card.anchor;var color:Color=card.color
		var end:=Vector2(clampf(anchor.x,box.position.x,box.end.x),clampf(anchor.y,box.position.y,box.end.y))
		draw_line(anchor,end,T.MAP_LABEL_BG,3,true)
		draw_line(anchor,end,Color(color,.65),1,true)
		draw_circle(anchor,3,T.MAP_LABEL_BG);draw_circle(anchor,2,color)
	var open:=expanded_id();var opened:={}
	for card:Dictionary in cards:
		if bool(card.get("compact",false)):
			_draw_frame(card,card.rect,false)
			if String(card.id)==open:opened=card
		else:_draw_card(card,card.rect)
	# The open card draws last, over its neighbours, on a solid ground.
	if not opened.is_empty():_draw_card(opened,detail_rect(opened),true)

func _draw_frame(card:Dictionary,box:Rect2,solid:bool)->void:
	var font:=ThemeDB.fallback_font;var color:Color=card.color
	var key:=str(color)+str(solid)
	if not styles.has(key):
		var style:=StyleBoxFlat.new();style.bg_color=T.PANEL_BG_SOLID if solid else T.MAP_LABEL_BG;style.border_color=Color(color,.65)
		style.set_border_width_all(1);style.set_corner_radius_all(4)
		if solid:style.shadow_color=Color(0,0,0,.25);style.shadow_size=4
		styles[key]=style
	draw_style_box(styles[key],box)
	draw_rect(Rect2(box.position+Vector2(0,5),Vector2(3,box.size.y-10)),color)
	var x:=box.position.x+12
	if card.flag!=null:
		var flag_size:Vector2=card.flag.get_size()
		flag_size*=minf(30.0/flag_size.x,20.0/flag_size.y)
		draw_texture_rect(card.flag,Rect2(box.position+Vector2(9,2)+(Vector2(30,20)-flag_size)*.5,flag_size),false)
		x=box.position.x+46
	var y:=box.position.y+19
	for line:String in card.lines:
		draw_string(font,Vector2(x,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE,T.INK);y+=20

func _draw_card(card:Dictionary,box:Rect2,solid:bool=false)->void:
	var font:=ThemeDB.fallback_font;var color:Color=card.color
	_draw_frame(card,box,solid)
	var y:=box.position.y+19+float(card.lines.size())*20
	if card.has("summary"):
		# Affiliation in body ink so it stays legible on the parchment ground.
		draw_string(font,Vector2(box.position.x+10,y-3),String(card.affiliation),HORIZONTAL_ALIGNMENT_LEFT,box.size.x-20,12,T.TEXT_SOFT)
		draw_line(Vector2(box.position.x+10,y+3),Vector2(box.end.x-10,y+3),Color(color,.18))
		var stats:Array=card.summary.stats
		for i in stats.size():
			var cell:=Vector2(box.position.x+10+float(i%2)*(box.size.x-20)*.5,y+16+float(i/2)*42)
			draw_string(font,cell,String(stats[i].label),HORIZONTAL_ALIGNMENT_LEFT,-1,9,T.MUTED)
			draw_string(font,cell+Vector2(0,15),String(stats[i].value),HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE,T.INK if stats[i].value!="Unknown" else T.DISABLED)
			draw_string(font,cell+Vector2(0,27),String(stats[i].detail),HORIZONTAL_ALIGNMENT_LEFT,-1,9,T.TEXT_SOFT)
		var level:=int(card.summary.level)
		var freshness_color:=Color("78bba4") if level>=4 else Color("d4ae68") if level>=2 else Color("b88270")
		draw_string(font,Vector2(box.position.x+10,box.end.y-7),String(card.summary.get("heading","REPORT"))+" · "+String(card.status),HORIZONTAL_ALIGNMENT_LEFT,-1,10,freshness_color)
		for i in 5:draw_rect(Rect2(Vector2(box.end.x-67+i*11,box.end.y-14),Vector2(8,5)),freshness_color if i<level else T.TRACK)
		return
	var status_height:=20.0 if not String(card.get("status","")).is_empty() else 0.0
	if status_height>0:draw_string(font,Vector2(box.position.x+10,box.end.y-9),String(card.status),HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE,T.GOLD_BRIGHT)
	if not String(card.get("affiliation","")).is_empty():draw_string(font,Vector2(box.position.x+10,box.end.y-27-status_height),String(card.affiliation),HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE,T.TEXT_SOFT)
	draw_string(font,Vector2(box.position.x+10,box.end.y-9-status_height),card.population,HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE,T.INK)
