extends Control
## THE WAR MAP: HOI4's map mode for war. While the War screen is open the map
## itself is the war, as HOI4's is:
##   - the camera pulls back to frame our towns, every enemy's known towns
##     and our bands out, and goes back where it was when the screen closes;
##   - every people we know is a patch of colour: the ground about its towns
##     it ranges over (a share of the way to its nearest neighbour), its name
##     lettered across it;
##   - the towns' paper cards give way to small dots and plain names, as on a
##     strategic map, so the war reads before the towns do;
##   - a front stands between us and each people at feud or war, inked in
##     both colours, solid with teeth toward them while it is hot, dashed
##     while it is quiet, with who is winning in a small bar;
##   - while a feud is hot, a dashed arrow from their nearest town toward ours
##     says their raiders may come;
##   - our army at home is a counter on our chief town (the men under arms,
##     those in drill on a tab, strength against the share kept, will), and
##     each enemy's host a counter on their nearest town, in their colour,
##     its size as the war leader reckons it ("~240"), faded when our word of
##     them is old.
## Bands out, battles, raids and garrisons stay the war chart's
## (war_front_overlay.gd). Observe-only: nothing here orders anything, and
## clicks reach the map.

const Counter:=preload("res://scripts/hud/army_counter.gd")
const ArmyBar:=preload("res://scripts/hud/army_bar.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const Borders:=preload("res://scripts/nation_borders.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

## How often the ledgers are read again (seconds of real time).
const COLLECT_EVERY:=0.5
## The camera eases to and from the war view over this long (seconds).
const FRAME_SECONDS:=0.6
## The war view never comes closer than this, nor goes wider (camera size, km).
const FRAME_MIN:=18.0
const FRAME_MAX:=1600.0
## Room left around what is framed.
const FRAME_MARGIN:=1.3
## Known towns this far from home are read (km).
const REACH_KM:=2400.0
## A people's ground: this share of the way to its nearest neighbour's town,
## within these bounds (km); alone, the middle of them.
const RANGE_SHARE:=0.38
const RANGE_MIN_KM:=12.0
const RANGE_MAX_KM:=180.0
## A people's ground is at least this wide about each town on screen (px).
const LAND_MIN_PX:=30.0
## A front with no drawn meeting line is this share of the distance long,
## within these bounds (km).
const FRONT_SHARE:=0.32
const FRONT_MIN_KM:=4.0
const FRONT_MAX_KM:=120.0
## Word of an enemy's host older than this is drawn faded (days).
const STALE_DAYS:=180
## Colours: our blue for our side of a front, ink, paper and war red.
const OURS:=Color("#3d7f9c")
const WAR_RED:=Color("#b5473a")
const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
const UNKNOWN:=Color("#9a9a8c")

var terrain:Node
var active:=false
var scene:={}
var clock:=0.0
var drawn_view:=0
## The camera as it was before the war view: {target, size}.
var saved:={}
## An easing camera move: {from_target, to_target, from_size, to_size, t}.
var easing:={}
## The towns' paper cards, set aside while the war map shows: their layer and
## whether it was showing.
var labels_layer:CanvasLayer
var labels_were:=true
## The counters' and towns' own canvas, above the lands and fronts.
var counters:Control


func _ready()->void:
	name="WarMapMode"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_counter_layer.call_deferred()


func _add_counter_layer()->void:
	if not is_instance_valid(terrain) or counters!=null: return
	var layer:=CanvasLayer.new(); layer.name="WarMapCounters"; layer.layer=0
	terrain.add_child(layer)
	counters=TopCanvas.new(); counters.host=self; layer.add_child(counters)


class TopCanvas extends Control:
	var host:Control
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	func _draw()->void:
		if is_instance_valid(host): host.draw_top(self)


func _process(delta:float)->void:
	var open:=ArmyBar.war_open()
	if open!=active:
		active=open
		if active:
			scene=collect()
			clock=0.0
			_set_aside_labels(true)
			_frame_war()
		else:
			_set_aside_labels(false)
			_restore()
			scene={}
		queue_redraw()
		if counters!=null: counters.queue_redraw()
	_ease(delta)
	if not active: return
	clock+=delta
	if clock>=COLLECT_EVERY:
		clock=0.0
		scene=collect()
	var camera:=_camera()
	var view:=hash([scene.get("signature",0),camera.global_transform if camera else Transform3D(),camera.size if camera else 0.0,size])
	if view!=drawn_view:
		drawn_view=view
		queue_redraw()
		if counters!=null: counters.queue_redraw()


## The towns' paper cards step aside while the war map shows, and come back.
func _set_aside_labels(aside:bool)->void:
	var cards:Variant=terrain.get("city_labels") if is_instance_valid(terrain) and "city_labels" in terrain else null
	if not cards is Control or not is_instance_valid(cards): return
	var layer:=(cards as Control).get_parent() as CanvasLayer
	if layer==null: return
	if aside:
		labels_layer=layer; labels_were=layer.visible; layer.visible=false
	elif is_instance_valid(labels_layer):
		labels_layer.visible=labels_were
		labels_layer=null


# --- What the war map shows ---------------------------------------------------

## Everything drawn, from the ledgers: {home, towns, lands, enemies, levy,
## frame, signature}.
func collect()->Dictionary:
	var out:={"home":Vector2.INF,"towns":[],"lands":[],"enemies":[],"levy":{},"frame":[],"signature":0}
	if WorldSimulation.world==null or not GameState.settlement_site_committed: return out
	var home:Vector2=CivilizationSystem.player_world_origin
	out.home=home
	var frame:Array=[home]
	var towns:Array=[]
	# Our towns (a town an enemy holds is theirs).
	for s:Dictionary in _settlements():
		var at:Variant=s.get("position",Vector2.INF)
		if not at is Vector2 or not (at as Vector2).is_finite(): continue
		var holder:=String(s.get("occupied_by",""))
		if holder=="" or holder=="human": holder="player"
		towns.append({"name":String(s.get("name","")),"at":at,"owner":holder,"chief":bool(s.get("primary",false))})
		frame.append(at)
	# Every town of another people our people know of.
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",true,home,REACH_KM):
		var at:=_v2(city.get("position",{}))
		if not at.is_finite(): continue
		var owner:=String(city.get("controller",""))
		if owner=="": owner=String(city.get("civ_id",""))
		if owner=="human": owner="player"
		if owner=="player" and _near_any(towns,at,0.5): continue
		# A town reported burned (the borders' own reading of the report).
		towns.append({"name":String(city.get("name","")),"at":at,"owner":owner,"chief":false,"ruin":Borders._report_damage(city)>=0.6})
	out.towns=towns
	# Each people's ground: a share of the way to its nearest neighbour.
	var ranges:=_ranges(towns)
	for t:Dictionary in towns:
		if String(t.owner)=="" or bool(t.get("ruin",false)): continue
		(out.lands as Array).append({"owner":String(t.owner),"center":t.at,"radius":float(ranges.get(String(t.owner),40.0))})
	# Our bands out (the chart draws them; the view frames them).
	for army in MilitaryCampaign.field_armies:
		if not army is Dictionary or int((army as Dictionary).get("troops",0))<=0: continue
		var pos:=_v2((army as Dictionary).get("position",{}))
		if pos.is_finite(): frame.append(pos)
	# Every people at feud or war with us: their front and their host.
	for e:Dictionary in Ledger.entries():
		if String(e.get("kind",""))=="ended": continue
		var civ_id:=String(e.civ_id)
		var theirs:Array=[]
		for t:Dictionary in towns:
			if String(t.owner)==civ_id and not bool(t.get("ruin",false)): theirs.append(t.at)
		var there:=_nearest(theirs,home)
		var guessed:=false
		if not there.is_finite():
			there=_where_met(civ_id)
			guessed=true
		if not there.is_finite(): continue
		frame.append_array(theirs if not theirs.is_empty() else [there])
		var raw:=float(Ledger.odds(e).raw)
		(out.enemies as Array).append({"civ_id":civ_id,"name":String(e.get("name","")),"there":there,"guessed":guessed,"front":_front(civ_id,home,there),
			"hot":bool(e.get("hot",false)),"war":String(e.get("kind",""))=="war","fighters":WarLoop._their_fighters(civ_id),"stale":_word_age(civ_id)>STALE_DAYS,
			"worn":clampf(float(e.get("their_worn",0.0)),0.0,1.0),"ours_share":clampf(raw/(1.0+raw),0.05,0.95),"color":_color(civ_id)})
	# Our army at home (army_bar.gd levy_card): on our chief town.
	var levy:=ArmyBar.levy_card(MilitaryCampaign)
	var reading:=Law.reading(MilitaryCampaign)
	var target:=int(reading.get("target",-1))
	out.levy={"side":"ours","troops":int(levy.get("ready",0))+int(levy.get("watch",0)),"strength":clampf(float(reading.get("now",0))/float(target),0.0,1.0) if target>0 else 1.0,
		"will":float(levy.get("will",0.6)),"glyph":String(levy.get("glyph","spear")),"accent":OURS,
		"tab":("%d in drill" % int(levy.get("drill",0))) if int(levy.get("drill",0))>0 else ""}
	out.frame=frame
	out.signature=hash([towns.size(),str(out.enemies.map(func(x:Dictionary)->Array:return [x.civ_id,x.hot,x.fighters,x.stale,snappedf(float(x.ours_share),0.02)])),levy.get("ready",0),levy.get("drill",0),levy.get("watch",0)])
	return out


## Our towns from the settlement network, as the borders read them.
func _settlements()->Array:
	if is_instance_valid(terrain) and terrain.has_method("_settlement_model"):
		var model:Variant=terrain.call("_settlement_model")
		if model!=null and model.has_method("settlement_network_snapshot"):
			var network:Variant=model.call("settlement_network_snapshot")
			if network is Dictionary and (network as Dictionary).get("settlements") is Array: return network.settlements
	return GameState.player_settlements


## Each people's reach (km): a share of the way from its towns to the
## nearest town of any other people we know, within bounds.
static func _ranges(towns:Array)->Dictionary:
	var nearest:={}
	for a:Dictionary in towns:
		var owner:=String(a.owner)
		if owner=="" or bool(a.get("ruin",false)): continue
		for b:Dictionary in towns:
			var other:=String(b.owner)
			if other==owner or other=="" or bool(b.get("ruin",false)): continue
			var d:=(a.at as Vector2).distance_to(b.at)
			if not nearest.has(owner) or d<float(nearest[owner]): nearest[owner]=d
	var out:={}
	for a:Dictionary in towns:
		var owner:=String(a.owner)
		if owner=="" or out.has(owner): continue
		out[owner]=clampf(float(nearest.get(owner,(RANGE_MIN_KM+RANGE_MAX_KM)*0.5/RANGE_SHARE))*RANGE_SHARE,RANGE_MIN_KM,RANGE_MAX_KM)
	return out


static func _near_any(towns:Array,at:Vector2,km:float)->bool:
	for t:Dictionary in towns:
		if (t.at as Vector2).distance_to(at)<=km: return true
	return false


## The nearest of `points` to `to`; INF when there are none.
static func _nearest(points:Array,to:Vector2)->Vector2:
	var best:=Vector2.INF
	for p:Vector2 in points:
		if not best.is_finite() or p.distance_squared_to(to)<best.distance_squared_to(to): best=p
	return best


## Where we know them from when none of their towns is known: their home as
## reported, else where we met them. INF when we know neither.
static func _where_met(civ_id:String)->Vector2:
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.get("id",""))!=civ_id: continue
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		if bool(relation.get("home_location_known",false)):
			var p:=_v2(relation.get("home_position",{}))
			if p.is_finite(): return p
		var met:=_v2(relation.get("encounter_position",{}))
		if met.is_finite(): return met
	return Vector2.INF


## Days since our last word of their towns (city intelligence).
static func _word_age(civ_id:String)->int:
	var today:=int(GameState.elapsed_days)
	var newest:=-1
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player",civ_id):
		newest=maxi(newest,int(city.get("observed_day",-1)))
	return 99999 if newest<0 else maxi(0,today-newest)


## The front with a people: the drawn line where our lands meet, else a
## stretch across the way between us, halfway.
static func _front(civ_id:String,home:Vector2,there:Vector2)->PackedVector2Array:
	for line:Dictionary in Borders.published:
		var owners:Array=line.owners
		if (owners[0]=="player" and owners[1]==civ_id) or (owners[1]=="player" and owners[0]==civ_id):
			var points:PackedVector2Array=line.points
			if points.size()>=2: return points
	var gap:=there-home
	var dist:=gap.length()
	if dist<=0.01: return PackedVector2Array()
	var mid:=home+gap*0.5
	var across:=Vector2(-gap.y,gap.x)/dist
	var half:=clampf(dist*FRONT_SHARE*0.5,FRONT_MIN_KM*0.5,FRONT_MAX_KM*0.5)
	# A hand-inked line, never a ruler's: a little wander, the same each time.
	var r:=RandomNumberGenerator.new(); r.seed=hash("front|"+civ_id)
	var out:=PackedVector2Array()
	var steps:=10
	for i in steps+1:
		var t:=-1.0+2.0*float(i)/float(steps)
		var wander:=(r.randf()-0.5)*half*0.22*(1.0-absf(t))
		out.append(mid+across*half*t+gap/dist*wander)
	return out


static func _color(owner:String)->Color:
	if owner=="": return UNKNOWN
	return Borders.nation_color(owner)


## A people's own name: ours as the realm calls itself, theirs as known.
static func _people_name(owner:String)->String:
	if owner=="player":
		var mine:=String(GameState.nation_name)
		if mine=="": mine=String(GameState.settlement_name)
		return mine
	return Borders.people_name(owner)


static func _v2(position:Variant)->Vector2:
	if position is Vector2: return position
	if position is Dictionary and (position as Dictionary).has("x"): return Vector2(float(position.x),float((position as Dictionary).get("z",position.get("y",0.0))))
	return Vector2.INF


# --- The camera ------------------------------------------------------------------

func _camera()->Camera3D:
	return terrain.get("camera") as Camera3D if is_instance_valid(terrain) else null


## The war view: everything collected in frame, in the part of the screen the
## War screen leaves open (left of its column, under its strip).
func _frame_war()->void:
	var camera:=_camera()
	if camera==null or not "camera_target" in terrain: return
	saved={"target":terrain.camera_target,"size":camera.size}
	var points:Array=scene.get("frame",[])
	if points.size()<2:
		var home:Vector2=scene.get("home",Vector2.INF)
		_ease_to(Vector3(home.x,terrain.camera_target.y,home.y) if home.is_finite() else terrain.camera_target,maxf(camera.size,FRAME_MIN*2.0))
		return
	var box:=Rect2(points[0],Vector2.ZERO)
	for p:Vector2 in points: box=box.expand(p)
	var view:=get_viewport_rect().size
	var free:=_free_rect(view)
	# Orthographic: size is the view's height in km; the free part's share of
	# the screen sets how much of it the box may take.
	var aspect:=free.size.x/maxf(1.0,free.size.y)
	var want:=maxf(box.size.y,box.size.x/maxf(0.2,aspect))*FRAME_MARGIN
	want*=view.y/maxf(1.0,free.size.y)
	want=clampf(want,FRAME_MIN,FRAME_MAX)
	# Centre the box in the free part: shift the camera by the free part's
	# offset from the screen's middle, in km along the camera's own axes.
	var km_per_px:=want/maxf(1.0,view.y)
	var shift_px:=(view*0.5)-(free.position+free.size*0.5)
	var basis:=camera.global_transform.basis
	var right:=Vector3(basis.x.x,0.0,basis.x.z).normalized()
	var down:=Vector3(-basis.y.x,0.0,-basis.y.z)
	if down.length()<0.001: down=Vector3(basis.z.x,0.0,basis.z.z)
	down=down.normalized()
	var centre:=box.get_center()
	var target:=Vector3(centre.x,terrain.camera_target.y,centre.y)+right*shift_px.x*km_per_px+down*shift_px.y*km_per_px
	_ease_to(target,want)


## The part of the screen the War screen leaves to the map.
func _free_rect(view:Vector2)->Rect2:
	var board:GDScript=load("res://scripts/hud/war_board.gd") as GDScript
	var consts:Dictionary=board.get_script_constant_map() if board!=null else {}
	var column:=float(consts.get("COLUMN_WIDTH",400.0))
	var strip:=float(consts.get("STRIP_HEIGHT",64.0))
	var left:=96.0
	var top:=64.0+strip+12.0
	var bottom:=view.y-150.0
	return Rect2(Vector2(left,top),Vector2(maxf(200.0,view.x-column-24.0-left),maxf(200.0,bottom-top)))


func _restore()->void:
	if saved.is_empty() or not is_instance_valid(terrain): return
	_ease_to(saved.target,float(saved.size))
	saved={}


func _ease_to(target:Vector3,to_size:float)->void:
	var camera:=_camera()
	if camera==null: return
	easing={"from_target":terrain.camera_target,"to_target":target,"from_size":camera.size,"to_size":to_size,"t":0.0}


func _ease(delta:float)->void:
	if easing.is_empty() or not is_instance_valid(terrain): return
	var camera:=_camera()
	if camera==null: easing={}; return
	# A screenshot is taken a few frames in: no easing then.
	var instant:=bool(terrain.get("capture_render_active")) if "capture_render_active" in terrain else false
	easing.t=1.0 if instant else minf(1.0,float(easing.t)+delta/FRAME_SECONDS)
	var k:=smoothstep(0.0,1.0,float(easing.t))
	terrain.camera_target=(easing.from_target as Vector3).lerp(easing.to_target,k)
	camera.size=lerpf(float(easing.from_size),float(easing.to_size),k)
	if terrain.has_method("_update_camera"): terrain.call("_update_camera")
	if terrain.has_method("_update_scale_lod"): terrain.call("_update_scale_lod")
	if float(easing.t)>=1.0: easing={}


# --- Drawing --------------------------------------------------------------------------

func _screen(p:Vector2)->Vector2:
	var camera:=_camera()
	if camera==null or not p.is_finite(): return Vector2.INF
	var h:=float(terrain._height_at(p.x,p.y)) if terrain.has_method("_height_at") else 0.0
	var world:=Vector3(p.x,h,p.y)
	if camera.is_position_behind(world): return Vector2.INF
	return camera.unproject_position(world)


func _px_per_km(at:Vector2)->float:
	var a:=_screen(at); var b:=_screen(at+Vector2(1.0,0.0))
	if not a.is_finite() or not b.is_finite(): return 1.0
	return maxf(0.0001,a.distance_to(b))


## Beneath the towns: the peoples' grounds, their names, the fronts and the
## raiders' threat.
func _draw()->void:
	if not active or scene.is_empty(): return
	var named:Array=[]
	for owner in _owners():
		var color:Color=_color(String(owner))
		for hull:PackedVector2Array in _land_of(String(owner)):
			if hull.size()<3: continue
			draw_colored_polygon(hull,Color(color,0.22 if String(owner)!="player" else 0.26))
			var ring:=hull.duplicate(); ring.append(hull[0])
			draw_polyline(ring,Color(color.darkened(0.35),0.8),3.0,true)
			named.append({"owner":String(owner),"hull":hull,"color":color})
	# Each people's name across its ground, as HOI4 letters a country.
	var font:=T.font("voice")
	var lettered:={}
	for n:Dictionary in named:
		var owner:=String(n.owner)
		if lettered.has(owner): continue
		lettered[owner]=true
		var hull:PackedVector2Array=n.hull
		var box:=Rect2(hull[0],Vector2.ZERO)
		for q in hull: box=box.expand(q)
		var words:=" ".join(Array(_people_name(owner).to_upper().split("")))
		if words.strip_edges()=="": continue
		var fs:=clampi(roundi(box.size.x/maxf(6.0,float(words.length()))*1.25),15,40)
		var w:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		# Low in its ground, under the towns and the hosts that stand by them.
		var at:=Vector2(box.get_center().x-w*0.5,box.end.y-box.size.y*0.12)
		draw_string_outline(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,5,Color(PAPER,0.7))
		draw_string(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color((n.color as Color).darkened(0.5),0.85))
	for e:Dictionary in scene.get("enemies",[]):
		_draw_front(e)
		if (bool(e.hot) or bool(e.war)) and not bool(e.guessed): _draw_threat(e)


func _owners()->Array:
	var seen:={}
	for land:Dictionary in scene.get("lands",[]): seen[String(land.owner)]=true
	return seen.keys()


## One people's ground on screen: its towns gathered into clusters (towns
## within reach of each other), each drawn as the convex hull of a ring about
## every town in it. Convex hulls only: always a simple polygon, whatever the
## towns' layout (merging polygons can bring the engine down).
func _land_of(owner:String)->Array:
	var towns:Array=[]
	for land:Dictionary in scene.get("lands",[]):
		if String(land.owner)!=owner: continue
		var c:=_screen(land.center)
		if not c.is_finite(): continue
		towns.append({"at":c,"r":clampf(float(land.radius)*_px_per_km(land.center),LAND_MIN_PX,420.0)})
	var group:=range(towns.size())
	for i in towns.size():
		for j in range(i+1,towns.size()):
			var a:Dictionary=towns[i]; var b:Dictionary=towns[j]
			if (a.at as Vector2).distance_to(b.at)<=(float(a.r)+float(b.r))*1.1:
				var gi:int=group[i]; var gj:int=group[j]
				if gi==gj: continue
				for k in towns.size():
					if group[k]==gj: group[k]=gi
	var clusters:={}
	for i in towns.size():
		var key:int=group[i]
		# Packed arrays are values: build the ring here, then store it back.
		var ring:PackedVector2Array=clusters.get(key,PackedVector2Array())
		var t:Dictionary=towns[i]
		for n in 20: ring.append((t.at as Vector2)+Vector2.RIGHT.rotated(TAU*float(n)/20.0)*float(t.r))
		clusters[key]=ring
	var out:Array=[]
	for key in clusters:
		var hull:=Geometry2D.convex_hull(clusters[key])
		if hull.size()>=2 and hull[0].is_equal_approx(hull[hull.size()-1]): hull.remove_at(hull.size()-1)
		if hull.size()>=3: out.append(hull)
	return out


## Above the grounds and fronts: the towns as dots and names, then the hosts'
## counters, each clear of every name.
func draw_top(canvas:Control)->void:
	if not active or scene.is_empty(): return
	var view:=Rect2(Vector2.ZERO,canvas.size)
	var taken:Array=[]
	var font:=T.font("voice")
	var fs:=14
	for t:Dictionary in scene.get("towns",[]):
		var at:=_screen(t.at)
		if not at.is_finite() or not view.grow(20).has_point(at): continue
		var color:Color=_color(String(t.owner))
		var r:=6.0 if bool(t.get("chief",false)) else 4.5
		if bool(t.get("ruin",false)):
			canvas.draw_line(at-Vector2(r,r),at+Vector2(r,r),Color(INK,0.7),2.0,true)
			canvas.draw_line(at-Vector2(r,-r),at+Vector2(r,-r),Color(INK,0.7),2.0,true)
		else:
			canvas.draw_circle(at,r+1.5,Color(PAPER,0.95))
			canvas.draw_circle(at,r,color.darkened(0.15))
			canvas.draw_arc(at,r+1.5,0.0,TAU,16,Color(INK,0.9),1.3,true)
		var words:=String(t.name)
		if words=="": continue
		var size:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs)
		var spot:=at+Vector2(r+5.0,fs*0.36)
		var rect:=Rect2(spot-Vector2(0,fs),Vector2(size.x,fs+4.0))
		# Crowded names give way rather than pile up.
		var clear:=true
		for q:Rect2 in taken:
			if q.intersects(rect): clear=false; break
		taken.append(Rect2(at-Vector2(r+2,r+2),Vector2(r+2,r+2)*2.0))
		if not clear: continue
		taken.append(rect)
		canvas.draw_string_outline(font,spot,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,4,Color(PAPER,0.9))
		canvas.draw_string(font,spot,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(INK,0.95))
	# The hosts.
	var k:=0.9
	var plate:=Counter.plate_size(k)
	var items:Array=[]
	var home:=_screen(scene.get("home",Vector2.INF))
	if home.is_finite() and not (scene.get("levy",{}) as Dictionary).is_empty(): items.append({"at":home,"data":scene.levy})
	for e:Dictionary in scene.get("enemies",[]):
		var at:=_screen(e.there)
		if not at.is_finite(): continue
		var fighters:=int(e.fighters)
		var low:=roundi(float(fighters)*(0.75 if bool(e.stale) else 0.85)); var high:=roundi(float(fighters)*(1.3 if bool(e.stale) else 1.15))
		items.append({"at":at,"data":{"side":"theirs","low":low,"high":high,"strength":1.0-float(e.worn),"accent":e.color,"glyph":"spear","stale":bool(e.stale) or bool(e.guessed)}})
	var free:=_free_rect(canvas.size)
	for item:Dictionary in items:
		var at:Vector2=item.at
		if not view.grow(80).has_point(at): continue
		var spot:=_clear_spot(at,plate,taken,free)
		var drawn:=Counter.draw(canvas,spot,item.data,k)
		taken.append(drawn.grow(4.0))
		# A short ink line back to the town it stands for, when set aside.
		if spot.distance_to(at)>plate.y*0.75:
			canvas.draw_line(at,spot+(at-spot).limit_length(plate.y*0.55),Color(INK,0.55),1.4,true)


## Where a counter for a town may stand: above its mark, then to either side,
## then below, then further out; the first place clear of every name and
## counter already placed (or right above, when none is).
static func _clear_spot(at:Vector2,plate:Vector2,taken:Array,bounds:Rect2=Rect2())->Vector2:
	var up:=plate.y*0.5+12.0
	var side:=plate.x*0.5+14.0
	var tries:=[Vector2(0,-up),Vector2(-side,-up*0.3),Vector2(side,-up*0.3),Vector2(0,up+12.0),Vector2(0,-up*2.1),Vector2(-side*1.5,0),Vector2(side*1.5,0),Vector2(0,up*2.3),Vector2(-side*1.5,up+12.0),Vector2(side*1.5,up+12.0)]
	var fallback:=Vector2.INF
	for offset:Vector2 in tries:
		var centre:=at+offset
		var rect:=Rect2(centre-plate*0.5,plate)
		if bounds.has_area() and not bounds.encloses(rect): continue
		if not fallback.is_finite(): fallback=centre
		var clear:=true
		for r:Rect2 in taken:
			if r.intersects(rect): clear=false; break
		if clear: return centre
	if fallback.is_finite(): return fallback
	# Nowhere inside: just inside the free part, nearest the town.
	if bounds.has_area():
		return Vector2(clampf(at.x,bounds.position.x+plate.x*0.5,bounds.end.x-plate.x*0.5),clampf(at.y,bounds.position.y+plate.y*0.5,bounds.end.y-plate.y*0.5))
	return at+Vector2(0,-up)


## A front as HOI4 inks one: a dark line along it, our colour on our side and
## theirs on theirs, small teeth toward them while the feud is hot, dashed
## while it is quiet; whose front it is and who is winning at its middle.
func _draw_front(e:Dictionary)->void:
	var line:PackedVector2Array=e.get("front",PackedVector2Array())
	if line.size()<2: return
	var pts:=PackedVector2Array()
	for p in line:
		var s:=_screen(p)
		if not s.is_finite(): return
		pts.append(s)
	var home:=_screen(scene.home)
	var there:=_screen(e.there)
	if not home.is_finite() or not there.is_finite(): return
	var toward:=(there-home).normalized()
	var hot:=bool(e.hot) or bool(e.war)
	var theirs:Color=e.color
	var mid_index:=pts.size()/2
	var seg:=pts[mini(mid_index+1,pts.size()-1)]-pts[maxi(mid_index-1,0)]
	var normal_sign:=1.0 if Vector2(-seg.y,seg.x).dot(toward)>=0.0 else -1.0
	var ours_side:=PackedVector2Array(); var their_side:=PackedVector2Array()
	for i in pts.size():
		var a:=pts[maxi(i-1,0)]; var b:=pts[mini(i+1,pts.size()-1)]
		var nn:=Vector2(-(b-a).y,(b-a).x).normalized()*normal_sign
		ours_side.append(pts[i]-nn*5.0)
		their_side.append(pts[i]+nn*5.0)
	if hot:
		draw_polyline(ours_side,Color(OURS,0.95),5.0,true)
		draw_polyline(their_side,Color(theirs.darkened(0.15),0.95),5.0,true)
		draw_polyline(pts,Color(INK,0.95),3.0,true)
		# Teeth toward them, every so often along the line.
		var step:=20.0
		var run:=0.0
		for i in range(1,pts.size()):
			var a:=pts[i-1]; var b:=pts[i]
			var length:=a.distance_to(b)
			var dir:=(b-a)/maxf(0.001,length)
			var nn:=Vector2(-dir.y,dir.x)*normal_sign
			while run<length:
				var p:=a+dir*run
				draw_colored_polygon(PackedVector2Array([p-dir*4.5+nn*7.0,p+nn*15.0,p+dir*4.5+nn*7.0]),Color(INK,0.9))
				run+=step
			run-=length
	else:
		_dashed(ours_side,Color(OURS,0.75),3.0)
		_dashed(their_side,Color(theirs.darkened(0.15),0.75),3.0)
		_dashed(pts,Color(INK,0.75),2.0)
	# Whose front, and who is winning, near one end on our side (the middle is
	# where marches cross it).
	var mid:=pts[maxi(0,pts.size()/5)]-toward*34.0
	var w:=70.0; var h:=8.0
	var r:=Rect2(mid-Vector2(w*0.5,h*0.5),Vector2(w,h))
	draw_rect(r.grow(2.0),Color(PAPER,0.95))
	draw_rect(Rect2(r.position,Vector2(w*float(e.ours_share),h)),OURS)
	draw_rect(Rect2(r.position+Vector2(w*float(e.ours_share),0),Vector2(w*(1.0-float(e.ours_share)),h)),theirs.darkened(0.1))
	draw_rect(r.grow(2.0),Color(INK,0.85),false,1.2)
	var font:=T.font("ui_strong")
	var words:=String(e.name).to_upper()+("  WAR" if bool(e.war) else ("  HOT" if bool(e.hot) else ""))
	var fs:=12
	var tw:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	var chip:=Rect2(Vector2(mid.x-tw*0.5-6.0,r.position.y-fs-9.0),Vector2(tw+12.0,fs+6.0))
	draw_rect(chip,Color(PAPER,0.95))
	draw_rect(chip,Color(WAR_RED if hot else INK,0.85),false,1.2)
	draw_string(font,Vector2(chip.position.x+6.0,chip.end.y-5.0),words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(WAR_RED.darkened(0.2) if hot else INK,1.0))


## "Their raiders may come": a dashed arrow from their nearest town toward our
## nearest, stopping short of both, in their colour.
func _draw_threat(e:Dictionary)->void:
	var from:=_screen(e.there)
	var ours:Array=[]
	for t:Dictionary in scene.get("towns",[]):
		if String(t.owner)=="player": ours.append(t.at)
	var target:=_nearest(ours,e.there)
	var to:=_screen(target if target.is_finite() else scene.home)
	if not from.is_finite() or not to.is_finite(): return
	var gap:=to-from
	if gap.length()<140.0: return
	var dir:=gap.normalized()
	var a:=from+dir*60.0
	var b:=to-dir*60.0
	var color:=Color((e.color as Color).darkened(0.3),0.85)
	_dashed(PackedVector2Array([a,b]),color,3.5)
	var side:=Vector2(-dir.y,dir.x)
	draw_colored_polygon(PackedVector2Array([b+dir*16.0,b-dir*4.0+side*9.0,b-dir*4.0-side*9.0]),color)


func _dashed(points:PackedVector2Array,color:Color,width:float)->void:
	var dash:=10.0; var gap:=7.0
	var on:=true; var left:=dash
	for i in range(1,points.size()):
		var a:=points[i-1]; var b:=points[i]
		var length:=a.distance_to(b)
		var dir:=(b-a)/maxf(0.001,length)
		var at:=0.0
		while at<length:
			var take:=minf(left,length-at)
			if on: draw_line(a+dir*at,a+dir*(at+take),color,width,true)
			at+=take; left-=take
			if left<=0.0:
				on=not on
				left=dash if on else gap
