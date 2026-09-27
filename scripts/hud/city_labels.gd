extends Control
## A shared screen-space label layer. World positions and city reports stay authoritative.
## Place names are set in the book serif, as on an engraved chart; figures
## and status lines stay in the quiet UI face.
const NAME_SIZE:=17
const POP_SIZE:=13
## The inked settlement glyph sits on the anchor; leader lines start clear of it.
const GLYPH_CLEARANCE:=8.0
const GAP:=7.0
const REPORT=preload("res://scripts/hud/city_report_visuals.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const RESOURCE_ICONS=preload("res://scripts/resource_icons.gd")
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
## Per-city measured card text, keyed by what the text depends on.
var measured:Dictionary={}
## Great works (undertaking_map_visual map marks): an inked emblem while the
## monument is too small to read, and a smaller paper name card beside it.
## They give way to the cities: a work whose mark would sit on a city's pin
## is not drawn, and its card only takes room the city cards left free.
const WORK_NAME_SIZE:=14
const WORK_STATUS_SIZE:=12
const WORK_EMBLEM_PX:=22.0
const WORK_CARD_WIDTH:=190.0
## On the chart a card is the name alone, and a city lends room to only a few.
const WORK_CHART_WIDTH:=250.0
const WORK_CHART_CARDS:=2
var works:Array[Dictionary]=[]
var work_marks:Array[Dictionary]=[]
var work_root_id:=0
var work_memory:Dictionary={}
var work_measured:Dictionary={}

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
		# While the map pans or zooms every label keeps its place beside its pin
		# if it still fits. Test that first; only a blocked label searches.
		if old.has(entry.id):
			var kept:=_fit(anchor+Vector2(old[entry.id]),extent,bounds,reserved,placed,entries)
			if kept.size!=Vector2.ZERO:
				var kept_card:=entry.duplicate();kept_card.rect=kept;placed.append(kept_card)
				memory[entry.id]=kept.position-anchor
				continue
		var candidates:Array[Vector2]=[]
		# A larger mark (the people's own, ringed in gold) keeps its card clear.
		var clear:=maxf(0.0,float(entry.get("clearance",GLYPH_CLEARANCE))-GLYPH_CLEARANCE)
		for row in range(12):
			var step:=float(row)*(extent.y+GAP)
			candidates.append(anchor+Vector2(-extent.x*.5,-extent.y-14-clear-step))
			candidates.append(anchor+Vector2(-extent.x*.5,14+clear+step))
			candidates.append(anchor+Vector2(18+clear,-extent.y*.5+step))
			candidates.append(anchor+Vector2(-extent.x-18-clear,-extent.y*.5-step))
		# Dense clusters can use free space elsewhere on the map, with leader lines.
		for y in range(int(bounds.position.y),int(bounds.end.y-extent.y)+1,int(extent.y+GAP)):
			for x in range(int(bounds.position.x),int(bounds.end.x-extent.x)+1,int(extent.x+GAP)):
				candidates.append(Vector2(x,y))
		var chosen:=Rect2();var best:=INF
		for index in candidates.size():
			var pos:Vector2=candidates[index]
			pos.x=clampf(pos.x,bounds.position.x,maxf(bounds.position.x,bounds.end.x-extent.x))
			pos.y=clampf(pos.y,bounds.position.y,maxf(bounds.position.y,bounds.end.y-extent.y))
			var score:=anchor.distance_squared_to(Rect2(pos,extent).get_center())
			# A candidate farther than the best so far cannot win; skip its tests.
			if score>=best:continue
			var rect:=_fit(pos,extent,bounds,reserved,placed,entries)
			if rect.size==Vector2.ZERO:continue
			best=score;chosen=rect
		if chosen.size==Vector2.ZERO:hidden.append(entry);continue
		var card:=entry.duplicate();card.rect=chosen;placed.append(card)
		memory[entry.id]=chosen.position-anchor
	return {"cards":placed,"overflow":hidden,"memory":memory}

## `pos` clamped into bounds, or an empty rect when it would cover another
## label, a reserved panel or any city pin.
static func _fit(pos:Vector2,extent:Vector2,bounds:Rect2,reserved:Array[Rect2],placed:Array[Dictionary],entries:Array[Dictionary])->Rect2:
	pos.x=clampf(pos.x,bounds.position.x,maxf(bounds.position.x,bounds.end.x-extent.x))
	pos.y=clampf(pos.y,bounds.position.y,maxf(bounds.position.y,bounds.end.y-extent.y))
	var rect:=Rect2(pos,extent)
	if not bounds.encloses(rect):return Rect2()
	var grown:=rect.grow(GAP)
	for obstacle:Rect2 in reserved:
		if grown.intersects(obstacle):return Rect2()
	var half:=rect.grow(GAP*.5)
	for other:Dictionary in placed:
		if half.intersects((other.rect as Rect2).grow(GAP*.5)):return Rect2()
	# Protect the city pins as well as the other labels.
	for other:Dictionary in entries:
		if rect.grow(maxf(8.0,float(other.get("clearance",GLYPH_CLEARANCE))-2.0)).has_point(other.anchor):return Rect2()
	return rect

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
	var font:=T.voice_font()
	var signature:=str(viewport_size)+str(reserved)
	for id in sources.keys():
		var source:Dictionary=sources[id]
		var label:Label3D=source.label.get_ref()
		if not is_instance_valid(label) or label.is_queued_for_deletion():sources.erase(id);measured.erase(id);continue
		var kind:=String(label.get_meta("map_annotation_kind","city"))
		if kind=="founding_convoy" and is_instance_valid(terrain.get("settler_marker")):
			source.anchor=terrain.settler_marker.global_position
		if not label.is_visible_in_tree() or camera.is_position_behind(source.anchor):continue
		var anchor:=camera.unproject_position(source.anchor)
		if not Rect2(Vector2.ZERO,viewport_size).has_point(anchor):continue
		var record:Dictionary={}
		if bool(source.foreign):record=CivilizationSystem.city_intelligence.records.get("player",{}).get(String(id),{})
		var affiliation:=CivilizationSystem.city_intelligence.controller_label(String(label.get_meta("city_civilization_id",""))) if bool(source.foreign) else ""
		var flag:=label.get_node_or_null("CivilizationFlag") as Sprite3D
		# The card's text and measured size change only with its label, report,
		# day or era; the anchor moves every frame the camera does. Measure once.
		var text_key:=hash([label.text,String(label.get_meta("map_status","")),affiliation,bool(source.foreign),flag!=null,bounds.size.x,int(GameState.elapsed_days),hash(record),EraWords.stage()])
		var text:Dictionary=measured.get(id,{})
		if int(text.get("key",0))!=text_key:
			text=_measure_card(label,record,bool(source.foreign),affiliation,flag!=null,font,bounds)
			text["key"]=text_key
			measured[id]=text
		# The founding convoy is a prompt, not a city: it keeps its readout open.
		var compact:=kind!="founding_convoy"
		var detail:Vector2=text.detail
		entries.append({"id":String(id),"kind":kind,"status":text.status,"foreign":source.foreign,"anchor":anchor,"title":text.title,"lines":text.lines,"population":text.count,"affiliation":affiliation,"color":label.modulate,"flag":flag.texture if flag else null,"compact":compact,"detail_extent":detail,"extent":Vector2(text.name_width,float(text.lines.size())*20+10) if compact else detail,"clearance":float(label.get_meta("glyph_clearance",GLYPH_CLEARANCE))})
		if not (text.summary as Dictionary).is_empty():entries.back()["summary"]=text.summary
		signature+=str(text_key)+String(id)+str(anchor)+str(label.modulate)+str(flag.texture.get_instance_id() if flag and flag.texture else 0)
	var work_entries:=_work_entries(camera,viewport_size)
	for work:Dictionary in work_entries:signature+=String(work.id)+str(work.anchor)+str(snappedf(float(work.emblem_alpha),.05))+String(work.status)
	if signature==layout_signature:return
	layout_signature=signature
	last_bounds=bounds
	var result:=arrange(entries,bounds,previous,reserved)
	cards=result.cards;overflow=result.overflow;previous=result.memory
	var placed_works:=arrange_works(work_entries,bounds,cards,entries,reserved,work_memory)
	works=placed_works.works;work_memory=placed_works.memory
	_update_overflow(viewport_size)
	queue_redraw()

## Text, wrapped lines and sizes of one city's card (see refresh's cache key).
static func _measure_card(label:Label3D,record:Dictionary,foreign:bool,affiliation:String,has_flag:bool,font:Font,bounds:Rect2)->Dictionary:
	var parts:=label.text.split("  •  ",true,1)
	var title:=chart_name(String(parts[0]));var count:=String(parts[1]) if parts.size()>1 else "Population unknown"
	if not count.begins_with("est.") and count!="Population unknown":count="Population "+count
	var status:=String(label.get_meta("map_status",""))
	var summary:Dictionary={}
	if foreign:
		summary=report_summary(record,int(GameState.elapsed_days))
		status=summary.status
	var lines:=wrap_name(title,font,minf(260,bounds.size.x-56))
	var ui:=T.font("ui")
	var width:=maxf(ui.get_string_size(count,HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE).x,ui.get_string_size(affiliation,HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE).x)+20
	for line:String in lines:width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE).x+54)
	width=maxf(width,ui.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,POP_SIZE).x+20)
	var name_width:=54.0
	for line:String in lines:name_width=maxf(name_width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE).x+(56 if has_flag else 22))
	var detail:=Vector2(ceilf(maxf(135,width)),float(lines.size())*20+25+(18 if not affiliation.is_empty() else 0)+(20 if not status.is_empty() else 0))
	if not summary.is_empty():detail=Vector2(maxf(260,width),float(lines.size())*20+130)
	return {"title":title,"count":count,"status":status,"summary":summary,"lines":lines,"name_width":ceilf(name_width),"detail":detail}

## A place name as the chart letters it: names kept in capitals elsewhere
## ("SEANSTONE", "FOUNDING CAMP") are set in title case here.
static func chart_name(title:String)->String:
	if title!=title.to_upper() or title==title.to_lower():return title
	var words:=PackedStringArray()
	for word:String in title.split(" "):
		var pieces:=PackedStringArray()
		for piece:String in word.split("-"):pieces.append(piece.substr(0,1)+piece.substr(1).to_lower())
		words.append("-".join(pieces))
	return " ".join(words)

static func wrap_name(title:String,font:Font,width:float)->Array[String]:
	var lines:Array[String]=[];var line:=""
	for word:String in title.split(" "):
		var next:=word if line.is_empty() else line+" "+word
		if not line.is_empty() and font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE).x>width:lines.append(line);line=word
		else:line=next
	if not line.is_empty():lines.append(line)
	return lines

## How strongly a work's chart emblem shows, from the monument's own radius on
## screen: full while it is a speck, gone once the model itself reads.
static func work_emblem_alpha(radius_px:float)->float:
	return 1.0-smoothstep(9.0,18.0,radius_px)

## The rendered works' map marks, re-read only when the map rebuilds them.
func _current_work_marks()->Array[Dictionary]:
	var root:Variant=terrain.get("undertaking_visual_root") if is_instance_valid(terrain) else null
	if not (root is Node3D) or not is_instance_valid(root):
		work_marks.clear();work_root_id=0
		return work_marks
	var node:Node3D=root
	if node.get_instance_id()==work_root_id and not node.is_queued_for_deletion():return work_marks
	work_root_id=node.get_instance_id()
	work_marks.clear()
	for child in node.get_children():
		if child.has_meta("map_mark"):
			var mark:Dictionary=(child.get_meta("map_mark") as Dictionary).duplicate()
			mark.node=weakref(child)
			work_marks.append(mark)
	return work_marks

func _work_entries(camera:Camera3D,viewport_size:Vector2)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var screen:=Rect2(Vector2.ZERO,viewport_size)
	var voice:=T.voice_font();var ui:=T.font("ui")
	for mark:Dictionary in _current_work_marks():
		var node:Node3D=mark.node.get_ref()
		if node==null or not node.is_visible_in_tree():continue
		var world:Vector3=mark.anchor
		if camera.is_position_behind(world):continue
		var anchor:=camera.unproject_position(world)
		if not screen.has_point(anchor):continue
		var edge:=camera.unproject_position(world+camera.global_basis.x*float(mark.radius))
		var radius_px:=anchor.distance_to(edge)
		var key:=hash([mark.title,mark.status,mark.state])
		var text:Dictionary=work_measured.get(mark.id,{})
		if int(text.get("key",0))!=key:
			text=measure_work(String(mark.title),String(mark.status),voice,ui)
			text.key=key
			work_measured[mark.id]=text
		var alpha:=work_emblem_alpha(radius_px)
		# On the chart (the emblem showing) a card is just the name: the emblem's
		# edge already tells how the work stands.
		var chart:=alpha>=.5
		result.append({"id":String(mark.id),"city_id":String(mark.get("city_id","")),"title":String(mark.title),"status":"" if chart else String(mark.status),
			"lines":text.chart_lines if chart else text.lines,"extent":text.chart_extent if chart else text.extent,"compact":chart,
			"state":String(mark.state),"shape":String(mark.shape),"progress":float(mark.progress),"anchor":anchor,"radius_px":radius_px,"emblem_alpha":alpha})
	return result

## A work card's wrapped name and size: icon, name in the book serif, and a
## short status line in the UI face; and its chart form, the name alone.
static func measure_work(title:String,status:String,voice:Font,ui:Font)->Dictionary:
	var name:=chart_name(title)
	var lines:=_wrap_work(name,voice,WORK_CARD_WIDTH-36)
	var width:=0.0
	for text:String in lines:width=maxf(width,voice.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,WORK_NAME_SIZE).x)
	if not status.is_empty():width=maxf(width,ui.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,WORK_STATUS_SIZE).x)
	var height:=float(lines.size())*17.0+9.0+(15.0 if not status.is_empty() else 0.0)
	var chart_lines:=_wrap_work(name,voice,WORK_CHART_WIDTH-16)
	var chart_width:=0.0
	for text:String in chart_lines:chart_width=maxf(chart_width,voice.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,WORK_NAME_SIZE).x)
	return {"lines":lines,"extent":Vector2(ceilf(width)+36.0,ceilf(maxf(height,26.0))),
		"chart_lines":chart_lines,"chart_extent":Vector2(ceilf(chart_width)+16.0,float(chart_lines.size())*17.0+7.0)}

static func _wrap_work(name:String,voice:Font,width:float)->Array[String]:
	var lines:Array[String]=[];var line:=""
	for word:String in name.split(" "):
		var next:=word if line.is_empty() else line+" "+word
		if not line.is_empty() and voice.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,WORK_NAME_SIZE).x>width:lines.append(line);line=word
		else:line=next
	if not line.is_empty():lines.append(line)
	return lines

## Places the works around the already placed city cards, in two passes.
## Emblems first: a work sitting on a city pin is dropped (its city speaks
## for it at that scale) and emblems never overlap. Then cards, dedicated
## works first: a card goes only right beside its own work, covering no city
## card, pin, emblem or other card, else the work keeps only its emblem. On
## the chart a city lends its free room to at most WORK_CHART_CARDS names.
static func arrange_works(entries:Array[Dictionary],bounds:Rect2,city_cards:Array,city_entries:Array,reserved:Array[Rect2]=[],old:Dictionary={})->Dictionary:
	var order:={"dedicated":0,"standing":1,"building":2,"abandoned":3,"ruined":4}
	var ordered:=entries.duplicate()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ra:=int(order.get(a.state,5));var rb:=int(order.get(b.state,5))
		if ra!=rb:return ra<rb
		return String(a.id)<String(b.id))
	var pins:Array[Dictionary]=[]
	for city:Dictionary in city_entries:pins.append({"at":city.anchor,"clear":float(city.get("clearance",GLYPH_CLEARANCE))})
	var placed:Array[Dictionary]=[]
	var marks:Array[Rect2]=[]
	for entry:Dictionary in ordered:
		var anchor:Vector2=entry.anchor
		var merged:=false
		for pin:Dictionary in pins:
			if anchor.distance_to(pin.at)<float(pin.clear)+WORK_EMBLEM_PX*.5+6.0:merged=true;break
		if merged:continue
		var mark:=Rect2(anchor-Vector2.ONE*WORK_EMBLEM_PX*.5,Vector2.ONE*WORK_EMBLEM_PX)
		var clash:=false
		for other:Rect2 in marks:
			if other.grow(2).intersects(mark):clash=true;break
		if clash:continue
		var work:=entry.duplicate();work.mark=mark;work.rect=Rect2()
		# The card keeps clear of the work itself: its emblem, or the model.
		work.clear=maxf(WORK_EMBLEM_PX*.5 if float(entry.emblem_alpha)>.05 else 0.0,minf(float(entry.radius_px)*.8,70.0))+6.0
		placed.append(work);marks.append(mark)
	var blocked:Array[Rect2]=reserved.duplicate()
	for card:Dictionary in city_cards:blocked.append((card.rect as Rect2).grow(GAP*.5))
	for mark:Rect2 in marks:blocked.append(mark.grow(2))
	var memory:Dictionary={};var chart_cards:Dictionary={}
	for work:Dictionary in placed:
		var city:=String(work.get("city_id",""))
		if bool(work.get("compact",false)) and int(chart_cards.get(city,0))>=WORK_CHART_CARDS:continue
		var anchor:Vector2=work.anchor;var extent:Vector2=work.extent;var clear:=float(work.clear)
		var candidates:Array[Vector2]=[]
		if old.has(work.id):candidates.append(anchor+Vector2(old[work.id]))
		candidates.append_array([anchor+Vector2(clear,-extent.y*.5),anchor+Vector2(-extent.x-clear,-extent.y*.5),
			anchor+Vector2(-extent.x*.5,clear),anchor+Vector2(-extent.x*.5,-extent.y-clear),
			anchor+Vector2(clear*.7,clear*.7),anchor+Vector2(-extent.x-clear*.7,clear*.7),
			anchor+Vector2(clear*.7,-extent.y-clear*.7),anchor+Vector2(-extent.x-clear*.7,-extent.y-clear*.7)])
		for pos:Vector2 in candidates:
			var rect:=Rect2(pos,extent)
			if not bounds.encloses(rect):continue
			var grown:=rect.grow(GAP*.5)
			var free:=true
			# Every emblem, its own included, is in `blocked`.
			for obstacle:Rect2 in blocked:
				if grown.intersects(obstacle):free=false;break
			if free:
				for pin:Dictionary in pins:
					if rect.grow(maxf(8.0,float(pin.clear)-2.0)).has_point(pin.at):free=false;break
			if not free:continue
			work.rect=rect
			blocked.append(grown)
			memory[work.id]=rect.position-anchor
			if bool(work.get("compact",false)):chart_cards[city]=int(chart_cards.get(city,0))+1
			break
	return {"works":placed,"memory":memory}

func _draw_works()->void:
	var voice:=T.voice_font();var ui:=T.font("ui")
	for work:Dictionary in works:
		var anchor:Vector2=work.anchor
		var alpha:=float(work.emblem_alpha)
		if alpha>.02:
			var emblem:=RESOURCE_ICONS.great_work_texture(String(work.shape),String(work.state),48)
			draw_texture_rect(emblem,work.mark,false,Color(1,1,1,alpha))
		var box:Rect2=work.rect
		if not box.has_area():continue
		var end:=Vector2(clampf(anchor.x,box.position.x,box.end.x),clampf(anchor.y,box.position.y,box.end.y))
		var reach:=end-anchor
		var clear:=float(work.clear)-4.0
		if reach.length()>clear+3.0:
			var start:=anchor+reach.normalized()*clear
			draw_line(start,end,Color(T.PAPER_RAISED,.5),2.5,true)
			draw_line(start,end,Color(T.INK,.45),1,true)
		_draw_work_card(work,box,voice,ui)

## A work's name card: the chart's paper in a quieter weight than a city's,
## its emblem at the left, the name in the book serif, and while it rises a
## fine rule that fills with the work done.
func _draw_work_card(work:Dictionary,box:Rect2,voice:Font,ui:Font)->void:
	var key:="work"+str(T.PAPER_RAISED)
	if not styles.has(key):
		var style:=StyleBoxFlat.new();style.bg_color=Color(T.PAPER_RAISED,.9);style.border_color=Color(T.RULE,.9)
		style.set_border_width_all(1);style.set_corner_radius_all(T.RADIUS_CONTROL)
		style.shadow_color=Color(0,0,0,.08);style.shadow_size=2;style.shadow_offset=Vector2(0,1)
		styles[key]=style
	draw_style_box(styles[key],box)
	var state:=String(work.state)
	if state=="dedicated":draw_rect(Rect2(box.position+Vector2(3,0),Vector2(box.size.x-6,2)),T.GOLD)
	var x:=box.position.x+8;var y:=box.position.y+17
	if not bool(work.get("compact",false)):
		# Close in, the emblem is off the map and the card carries it instead.
		var icon:=RESOURCE_ICONS.great_work_texture(String(work.shape),state,48)
		draw_texture_rect(icon,Rect2(box.position+Vector2(5,5),Vector2(20,20)),false)
		x=box.position.x+29
	var ink:=T.INK if state!="ruined" else T.INK_MUTED
	for line:String in work.lines:
		draw_string(voice,Vector2(x,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,WORK_NAME_SIZE,ink);y+=17
	var status:=String(work.status)
	if status.is_empty():return
	var tone:=T.GOLD if state=="dedicated" else T.INK_MUTED
	draw_string(ui,Vector2(x,y-1),status,HORIZONTAL_ALIGNMENT_LEFT,-1,WORK_STATUS_SIZE,tone)
	if state in ["building","abandoned"]:
		var track:=Rect2(Vector2(x,box.end.y-5),Vector2(box.end.x-x-8,2))
		draw_rect(track,Color(T.RULE,.6))
		draw_rect(Rect2(track.position,Vector2(track.size.x*clampf(float(work.progress),0,1),2)),Color(T.INK,.6))

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
	# Works first: the cities' own cards and leaders always sit above them.
	_draw_works()
	for card:Dictionary in cards:
		var box:Rect2=card.rect;var anchor:Vector2=card.anchor
		var end:=Vector2(clampf(anchor.x,box.position.x,box.end.x),clampf(anchor.y,box.position.y,box.end.y))
		# A fine ink leader from just outside the place's glyph to its name.
		var reach:=end-anchor
		var clearance:=float(card.get("clearance",GLYPH_CLEARANCE))
		if reach.length()>clearance+2.0:
			var start:=anchor+reach.normalized()*clearance
			draw_line(start,end,Color(T.PAPER_RAISED,.55),3,true)
			draw_line(start,end,Color(T.INK,.55),1,true)
	var open:=expanded_id();var opened:={}
	for card:Dictionary in cards:
		if bool(card.get("compact",false)):
			_draw_frame(card,card.rect,false)
			if String(card.id)==open:opened=card
		else:_draw_card(card,card.rect)
	# The open card draws last, over its neighbours, on a solid ground.
	if not opened.is_empty():_draw_card(opened,detail_rect(opened),true)

## A name tag in the chart's paper: raised paper, a hairline rule, and the
## owner's colour only as a fine rule along the top (never a fill).
func _draw_frame(card:Dictionary,box:Rect2,solid:bool)->void:
	var font:=T.voice_font();var color:Color=card.color
	var key:=str(solid)+str(T.PAPER_RAISED)
	if not styles.has(key):
		var style:=StyleBoxFlat.new();style.bg_color=Color(T.PAPER_RAISED,1.0 if solid else .93);style.border_color=T.RULE
		style.set_border_width_all(1);style.set_corner_radius_all(T.RADIUS_CONTROL)
		style.shadow_color=Color(0,0,0,.22 if solid else .10);style.shadow_size=4 if solid else 2;style.shadow_offset=Vector2(0,1)
		styles[key]=style
	draw_style_box(styles[key],box)
	draw_rect(Rect2(box.position+Vector2(3,0),Vector2(box.size.x-6,2)),Color(color,.85))
	var x:=box.position.x+11
	if card.flag!=null:
		var flag_size:Vector2=card.flag.get_size()
		flag_size*=minf(30.0/flag_size.x,20.0/flag_size.y)
		draw_texture_rect(card.flag,Rect2(box.position+Vector2(9,3)+(Vector2(30,20)-flag_size)*.5,flag_size),false)
		x=box.position.x+46
	var y:=box.position.y+20
	for line:String in card.lines:
		draw_string(font,Vector2(x,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,NAME_SIZE,T.INK);y+=20

func _draw_card(card:Dictionary,box:Rect2,solid:bool=false)->void:
	var font:=T.font("ui");var color:Color=card.color
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
