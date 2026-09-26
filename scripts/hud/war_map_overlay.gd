extends Control
## War on the map: one small mark per war or feud near the contested border,
## a short tag beside it, a dashed stretch of border, the smoke of recent raids
## and the bands that are out. Every mark explains itself on hover (or stays
## open after a click). Tags use the city-label layout and never cover a city.
## Observe-only: clicks still reach the map.

const T=preload("res://scripts/hud/hud_tokens.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const Marks=preload("res://scripts/war_map_marks.gd")
const Icons=preload("res://scripts/resource_icons.gd")
const CityLabels=preload("res://scripts/hud/city_labels.gd")
const WarLoop=preload("res://scripts/war_loop.gd")
const EraNames=preload("res://scripts/era_names.gd")

const TAG_SIZE:=13
const TIP_SIZE:=13
const TIP_WIDTH:=300.0
const ICON:=26.0
const WAR_COLOR:=Color("#c9574a")
const OURS_COLOR:=Color("#67B4CF")
const THEIRS_COLOR:=Color("#d69a55")
## How often the war ledger is re-read (seconds of real time).
const COLLECT_EVERY:=0.25

var terrain:Node
## World marks: {id, kind: war|border|raid|band, points: Array[Vector3], tag, tip, color, alpha}
var marks:Array[Dictionary]=[]
var screen:Array[Dictionary]=[]
var tags:Array[Dictionary]=[]
var previous:Dictionary={}
var layout_signature:=""
var collect_elapsed:=COLLECT_EVERY
var hover_id:=""
var pinned_id:=""
## Inputs of the last collect(); the ledger is re-read only when they move.
var collect_key:=-1
## Hash of the last collected marks, and of everything the last drawing read.
var marks_signature:=-1
var drawn_signature:=-1
## Counters for probes (never saved).
var collects:=0
var redraw_requests:=0


func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta:float)->void:
	# Wars, feuds, raids and sightings move with the simulated day, contact and
	# charted ground; nothing between days changes them. Re-read the ledger only
	# when one of those inputs moved, and at most COLLECT_EVERY.
	collect_elapsed+=delta
	if collect_elapsed>=COLLECT_EVERY:
		collect_elapsed=0.0
		var key:=_collect_key()
		if key!=collect_key:
			collect_key=key
			collects+=1
			var fresh:=collect()
			var fresh_signature:=hash(fresh)
			if fresh_signature!=marks_signature:
				marks=fresh
				marks_signature=fresh_signature
	# Projection and drawing follow the camera, the marks and the pointer only.
	var signature:=_view_signature()
	if signature==drawn_signature: return
	drawn_signature=signature
	_project()
	redraw_requests+=1
	queue_redraw()


func _collect_key()->int:
	var ledger:Variant=WarLoop.state().get("fronts",{})
	var at_war:=0
	for civ:Dictionary in CivilizationSystem.civilizations:
		if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): at_war+=1
	var last_day:Variant=terrain.get("last_discovery_day") if is_instance_valid(terrain) else 0
	return hash([int(GameState.elapsed_days),last_day,GameState.settlement_site_committed,at_war,hash(ledger),
		CivilizationSystem.fog_revision,CivilizationSystem.observation_revision,GameState.known_discoveries.size()])


func _view_signature()->int:
	if marks.is_empty() and screen.is_empty() and tags.is_empty(): return 0
	var camera:=_camera()
	var view:Array=[marks_signature,get_viewport_rect().size,hover_id,pinned_id]
	if camera!=null: view.append_array([camera.global_transform,camera.size,camera.fov])
	var cities:Variant=terrain.get("city_labels") if is_instance_valid(terrain) else null
	if cities is Control and is_instance_valid(cities): view.append((cities as Control).get("cards").size())
	return hash(view)


# --- Reading the world --------------------------------------------------------

func _v3(point:Vector2)->Vector3:
	var height:=0.0
	if is_instance_valid(terrain) and terrain.has_method("_height_at"): height=float(terrain._height_at(point.x,point.y))
	return Vector3(point.x,height+0.01,point.y)


func _enemy_position(civ_id:String,home:Vector2)->Vector2:
	var best:=Vector2.INF
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
		if String(city.get("civ_id",""))!=civ_id: continue
		var position:Dictionary=city.get("position",{})
		var point:=Vector2(float(position.get("x",0.0)),float(position.get("z",0.0)))
		if best==Vector2.INF or point.distance_squared_to(home)<best.distance_squared_to(home): best=point
	if best!=Vector2.INF: return best
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.get("id",""))==civ_id: return CivilizationSystem._civilization_world_position(civ)
	return home+Vector2(8.0,0.0)


func _civ_name(civ_id:String)->String:
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.get("id",""))==civ_id: return String(civ.get("name","Strangers"))
	return "Strangers"


func collect()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if not GameState.settlement_site_committed: return out
	var stage:=EraWords.stage()
	var today:=int(GameState.elapsed_days)
	var home:Vector2=CivilizationSystem.player_world_origin
	var ledger_variant:Variant=WarLoop.state().get("fronts",{})
	var ledger:Dictionary=ledger_variant if ledger_variant is Dictionary else {}
	var general:Dictionary=WarLoop._general()
	var leader:=EraNames.given_of(String(general.get("name",""))) if not general.is_empty() else ""
	var at_war:Dictionary={}
	var field_by_civ:Dictionary={}
	for front:Dictionary in CivilizationSystem.military_fronts_snapshot().get("fronts",[]):
		at_war[String(front.get("opponent_id",""))]=true
		field_by_civ[String(front.get("opponent_id",""))]=int(front.get("field_personnel",0))+int(front.get("inbound_personnel",0))
	var civ_ids:Array=at_war.keys()
	for civ_id in ledger.keys():
		var f:Dictionary=ledger[civ_id]
		# A feud short of war: raids within the last year.
		if not civ_ids.has(civ_id) and int(f.get("level",0))>=1 and today-int(f.get("last_harm",-99999))<=365: civ_ids.append(civ_id)
	for civ_variant in civ_ids:
		var civ_id:=String(civ_variant)
		var f:Dictionary=ledger.get(civ_id,{}) if ledger.get(civ_id) is Dictionary else {}
		var war:Dictionary=f.get("war",{}) if f.get("war") is Dictionary else {}
		var enemy:=_civ_name(civ_id)
		var there:=_enemy_position(civ_id,home)
		var is_war:=bool(at_war.get(civ_id,false))
		var start:=int(war.get("start",today)) if is_war else int(f.get("feud_since",f.get("last_harm",today)))
		var days:=maxi(0,today-start)
		var harm:Dictionary={}
		var raids:Array[Dictionary]=[]
		var last_raid:Dictionary=f.get("last_raid",{}) if f.get("last_raid") is Dictionary else {}
		if not last_raid.is_empty(): raids.append(last_raid)
		var last_attack:Dictionary=war.get("last_attack",{}) if war.get("last_attack") is Dictionary else {}
		if not last_attack.is_empty(): raids.append(last_attack)
		for raid:Dictionary in raids:
			var ago:=today-int(raid.get("day",-99999))
			if harm.is_empty() or ago<int(harm.days_ago): harm={"target":String(raid.get("target","")),"days_ago":ago}
			var alpha:=Marks.raid_alpha(ago)
			if alpha<=0.0: continue
			var key:="%s:%d" % [civ_id,int(raid.get("day",0))]
			var info:={"enemy":enemy,"target":String(raid.get("target","")),"days_ago":ago,"our_dead":int(raid.get("our_dead",0)),"taken":int(raid.get("taken",0))}
			out.append({"id":"raid:"+key,"kind":"raid","points":[_v3(Marks.raid_point(home,there,String(raid.get("target","")),key))],"tip":Marks.raid_details(info),"color":WAR_COLOR,"alpha":alpha})
		var op_variant:Variant=war.get("op",{}) if is_war else f.get("op",{})
		var op:Dictionary=op_variant if op_variant is Dictionary else {}
		var op_info:Dictionary={}
		if not op.is_empty() and String(op.get("objective",""))!="war_parley":
			var left:=maxi(0,int(op.get("due",today))-today)
			op_info={"band":int(op.get("band",0)),"days_left":left,"leader":String(op.get("general",leader))}
			var band:={"ours":true,"count":int(op.get("band",0)),"leader":String(op.get("general",leader)),"enemy":enemy,"days_left":left}
			out.append({"id":"band:ours:"+civ_id,"kind":"band","points":[_v3(Marks.band_point(home,there,int(op.get("start",today)),int(op.get("due",today)),today))],"tip":Marks.band_details(band),"color":OURS_COLOR,"alpha":1.0})
		var last_fight:=int(war.get("last_fight",war.get("start",today)))
		var info:={"enemy":enemy,"days":days,"our_dead":int(war.get("our_dead",0)),"their_dead":int(war.get("their_dead",0)),"leader":leader,"harm":harm,"op":op_info,
			"quiet_days":today-last_fight if is_war and op_info.is_empty() else 0,"field":int(field_by_civ.get(civ_id,0))}
		var tag:=Marks.war_tag(enemy,stage,days) if is_war else "Feud with %s" % enemy
		var segment:=Marks.border_segment(home,there)
		out.append({"id":"border:"+civ_id,"kind":"border","points":[_v3(segment[0]),_v3(segment[1])],"tip":"The border with %s. Their men cross here." % enemy,"color":WAR_COLOR,"alpha":1.0})
		out.append({"id":"war:"+civ_id,"kind":"war","points":[_v3(Marks.border_point(home,there))],"tag":tag,"tip":Marks.details(info,stage),"color":WAR_COLOR,"alpha":1.0})
	# Before writing, strangers under arms are a handful of men, not a counter.
	if stage=="hearth":
		for sighting:Dictionary in CivilizationSystem.local_observation_snapshot().get("visible",[]):
			var position:Dictionary=sighting.get("position",{})
			var point:=Vector2(float(position.get("x",0.0)),float(position.get("z",0.0)))
			if is_instance_valid(terrain) and terrain.has_method("_world_position_is_revealed") and not terrain._world_position_is_revealed(Vector3(point.x,0.0,point.y)): continue
			var identified:=bool(sighting.get("identified",false))
			var band:={"ours":false,"enemy":String(sighting.get("civilization","")) if identified else "","low":int(sighting.get("strength_estimate_low",0)),"high":int(sighting.get("strength_estimate_high",0)),"seen_day":int(sighting.get("last_seen_day",sighting.get("observed_day",-1)))}
			out.append({"id":"band:"+String(sighting.get("id","")),"kind":"band","points":[_v3(point)],"tip":Marks.band_details(band),"color":WAR_COLOR if bool(sighting.get("hostile",false)) else THEIRS_COLOR,"alpha":1.0})
	return out


# --- Screen layout --------------------------------------------------------------

func _camera()->Camera3D:
	return terrain.camera if is_instance_valid(terrain) and terrain.get("camera") is Camera3D else null


func _project()->void:
	screen.clear()
	var camera:=_camera()
	if camera==null: tags.clear(); return
	var viewport:=Rect2(Vector2.ZERO,get_viewport_rect().size)
	for mark:Dictionary in marks:
		var points:PackedVector2Array=[]
		var ok:=true
		for world:Vector3 in mark.points:
			if camera.is_position_behind(world): ok=false; break
			points.append(camera.unproject_position(world))
		if not ok: continue
		if mark.kind!="border" and not viewport.grow(-4.0).has_point(points[0]): continue
		var entry:=mark.duplicate(); entry["screen"]=points
		screen.append(entry)
	_layout_tags(viewport)


func _reserved()->Array[Rect2]:
	## City tags and pins are never covered.
	var reserved:Array[Rect2]=[]
	var cities:Variant=terrain.get("city_labels") if is_instance_valid(terrain) else null
	if cities is Control and is_instance_valid(cities):
		for card:Dictionary in (cities as Control).get("cards"):
			reserved.append(card.rect)
			reserved.append(Rect2(Vector2(card.anchor)-Vector2(8,8),Vector2(16,16)))
	for entry:Dictionary in screen:
		if entry.kind in ["band","raid"]: reserved.append(Rect2(entry.screen[0]-Vector2(ICON,ICON)*0.5,Vector2(ICON,ICON)))
	return reserved


func _layout_tags(viewport:Rect2)->void:
	var font:=ThemeDB.fallback_font
	var entries:Array[Dictionary]=[]
	var reserved:=_reserved()
	var signature:=str(viewport.size)+str(reserved)
	for entry:Dictionary in screen:
		if entry.kind!="war": continue
		var extent:=Vector2(ceilf(font.get_string_size(String(entry.tag),HORIZONTAL_ALIGNMENT_LEFT,-1,TAG_SIZE).x)+18.0,22.0)
		var anchor:Vector2=entry.screen[0]
		entries.append({"id":String(entry.id),"anchor":anchor,"extent":extent,"foreign":false,"tag":String(entry.tag)})
		signature+=String(entry.id)+str(anchor.round())+String(entry.tag)
	if signature==layout_signature: return
	layout_signature=signature
	var bounds:=Rect2(Vector2(90,100),(viewport.size-Vector2(110,170)).max(Vector2(100,100)))
	var result:=arrange_tags(entries,bounds,previous,reserved)
	tags=result.cards
	previous=result.memory


## The shared no-overlap layout of city labels; tags that find no clear place
## are left off (their mark and hover still show).
static func arrange_tags(entries:Array[Dictionary],bounds:Rect2,old:Dictionary={},reserved:Array[Rect2]=[])->Dictionary:
	return CityLabels.arrange(entries,bounds,old,reserved)


# --- Hover and click ------------------------------------------------------------

func mark_at(point:Vector2)->Dictionary:
	for tag:Dictionary in tags:
		if (tag.rect as Rect2).has_point(point):
			for entry:Dictionary in screen:
				if String(entry.id)==String(tag.id): return entry
	var best:={}
	var best_distance:=INF
	for entry:Dictionary in screen:
		var distance:=INF
		if entry.kind=="border":
			distance=Geometry2D.get_closest_point_to_segment(point,entry.screen[0],entry.screen[1]).distance_to(point)
			if distance>7.0: continue
			distance+=6.0 # A mark on the line wins over the line itself.
		else:
			distance=(entry.screen[0] as Vector2).distance_to(point)
			if distance>ICON*0.6: continue
		if distance<best_distance: best_distance=distance; best=entry
	return best


func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		hover_id=String(mark_at(event.position).get("id","")) if get_viewport().gui_get_hovered_control()==null else ""
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		pinned_id=String(mark_at(event.position).get("id",""))


# --- Drawing ------------------------------------------------------------------

func _draw()->void:
	for entry:Dictionary in screen:
		if entry.kind=="border": draw_dashed_line(entry.screen[0],entry.screen[1],Color(entry.color,0.85),2.0,7.0,true)
	for kind:String in ["raid","band","war"]:
		for entry:Dictionary in screen:
			if entry.kind!=kind: continue
			var glyph:="feud" if kind=="war" else kind
			var texture:=Icons.war_texture(glyph,entry.color)
			var center:Vector2=entry.screen[0]
			draw_texture_rect(texture,Rect2(center-Vector2(ICON,ICON)*0.5,Vector2(ICON,ICON)),false,Color(1,1,1,float(entry.alpha)))
	var font:=ThemeDB.fallback_font
	for tag:Dictionary in tags:
		var box:Rect2=tag.rect
		var anchor:Vector2=tag.anchor
		var end:=Vector2(clampf(anchor.x,box.position.x,box.end.x),clampf(anchor.y,box.position.y,box.end.y))
		if end.distance_to(anchor)>ICON*0.5+2.0: draw_line(anchor,end,Color(WAR_COLOR,0.55),1.0,true)
		draw_style_box(T.flat(T.MAP_LABEL_BG,Color(WAR_COLOR,0.7),1,4,0),box)
		draw_rect(Rect2(box.position+Vector2(0,4),Vector2(3,box.size.y-8)),WAR_COLOR)
		draw_string(font,box.position+Vector2(10,15),String(tag.tag),HORIZONTAL_ALIGNMENT_LEFT,-1,TAG_SIZE,T.INK)
	var open:=pinned_id if pinned_id!="" else hover_id
	if open=="": return
	for entry:Dictionary in screen:
		if String(entry.id)==open: _draw_tip(entry); return


func _draw_tip(entry:Dictionary)->void:
	var font:=ThemeDB.fallback_font
	var text:=String(entry.get("tip",""))
	if text=="": return
	var text_size:=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,TIP_SIZE)
	var box_size:=text_size+Vector2(20,14)
	var origin:Vector2=(entry.screen[0] as Vector2)+Vector2(16,16)
	origin.x=clampf(origin.x,8,maxf(8,size.x-box_size.x-8))
	origin.y=clampf(origin.y,8,maxf(8,size.y-box_size.y-8))
	var style:=T.flat(T.PANEL_BG_SOLID,Color(entry.color,0.8),1,5,0)
	draw_style_box(style,Rect2(origin,box_size))
	draw_multiline_string(font,origin+Vector2(10,7+font.get_ascent(TIP_SIZE)),text,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,TIP_SIZE,-1,T.INK)
