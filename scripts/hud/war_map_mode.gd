extends Control
## THE WAR MAP: HOI4's map mode for war. While the War screen is open the map
## itself is the war, as HOI4's is:
##   - the camera pulls back to frame our towns, every enemy's known towns
##     and our bands out, and goes back where it was when the screen closes;
##   - every people we know is a patch of colour: the land its towns
##     actually claim (nation_borders.gd claims, the same ones the borders
##     are cut from), cut where another people's claim is stronger, its name
##     lettered across it. Early on a people's land is a speck in open
##     country; it grows with its towns until lands meet;
##   - the towns' paper cards give way to small dots and plain names, as on a
##     strategic map, so the war reads before the towns do;
##   - a front stands only where our land meets theirs: the war chart
##     (war_front_overlay.gd) works it while the war or feud is hot; here it
##     is dashed in both colours while quiet. Where open land lies between
##     us there is no front: the chip says how many days' march lies between
##     (the general's own road), with who is winning in a small bar;
##   - while a feud is hot, a dashed arrow from their nearest town toward ours
##     says their raiders may come;
##   - every town of a people at feud or war is an objective, as HOI4 marks
##     victory points: a star in their colour, one to three by what it is
##     worth (its people as our scouts counted them; a chief town more), and
##     the town the ruler bid the war leader take ringed, with the general's
##     planned thrust drawn to it from our front (from home while open land
##     lies between) until a band is on the road there;
##   - our army at home is a counter on our chief town (the men under arms,
##     those in drill on a tab, strength against the share kept, will), and
##     each enemy's host a counter on their nearest town, in their colour,
##     its size as the war leader reckons it ("~240"), faded when our word of
##     them is old.
## The pointer resting on a counter, a front, a town or a people's ground
## gets a few plain lines with the engine's own numbers (who, how many, the
## dead, the odds, how old our word is). A click on an enemy's ground,
## counter, front or town brings its card on the War screen into view.
## Bands out, battles, raids and garrisons stay the war chart's
## (war_front_overlay.gd). Observe-only: nothing here orders anything, and
## clicks reach the map.

const Counter:=preload("res://scripts/hud/army_counter.gd")
const ArmyBar:=preload("res://scripts/hud/army_bar.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const Borders:=preload("res://scripts/nation_borders.gd")
const Partition:=preload("res://scripts/nation_border_partition.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

## How often the ledgers are read again (seconds of real time).
const COLLECT_EVERY:=0.5
## The camera eases to and from the war view over this long (seconds).
const FRAME_SECONDS:=0.6
## The war view never comes closer than this, nor goes wider (camera size, km).
const FRAME_MIN:=5.0
const FRAME_MAX:=1600.0
## Room left around what is framed.
const FRAME_MARGIN:=1.3
## Known towns this far from home are read (km).
const REACH_KM:=2400.0
## A people's ground is at least this wide about each town on screen (px).
const LAND_MIN_PX:=30.0
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
## What the pointer can rest on, as last drawn: [{rect | poly | line, lines}],
## topmost first; and the one it rests on now (its index, -1 for none).
var hits:Array=[]
## Strangers' claims kept between reads (nation_borders foreign_claims cache).
var _claim_cache:={}
var hovered:=-1


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
	# The pointer: what it rests on, if anything, in the open part of the map.
	var mouse:=_pointer()
	var now:=hit_at(mouse) if _free_rect(size).has_point(mouse) else -1
	if now!=hovered:
		hovered=now
		if counters!=null: counters.queue_redraw()


## A click on an enemy's ground, counter, front or town: its card on the War
## screen comes into view and shines a moment. Any other click is the map's.
func _unhandled_input(event:InputEvent)->void:
	if not active or not event is InputEventMouseButton: return
	var press:=event as InputEventMouseButton
	if not press.pressed or press.button_index!=MOUSE_BUTTON_LEFT: return
	if not _free_rect(size).has_point(press.position): return
	var i:=hit_at(press.position)
	if i<0: return
	var civ_id:=String((hits[i] as Dictionary).get("civ_id",""))
	if civ_id=="" or civ_id=="player": return
	if show_card(civ_id): get_viewport().set_input_as_handled()


## Brings an enemy's card on the War screen into view and lights it a
## moment. False when the War screen has no card for them.
func show_card(civ_id:String)->bool:
	var screen:Variant=MilitaryCampaign.roster_screen
	if not is_instance_valid(screen): return false
	var card:=(screen as Node).find_child("Enemy_%s" % civ_id,true,false) as Control
	if card==null: return false
	var scroll:Variant=(screen as Node).get("scroll")
	if scroll is ScrollContainer: (scroll as ScrollContainer).ensure_control_visible(card)
	card.modulate=Color(1.18,1.1,0.86)
	var tween:=card.create_tween()
	tween.tween_property(card,"modulate",Color.WHITE,0.9)
	return true


## Where the pointer is (a capture may set it: --capture-war-hover=x,y).
func _pointer()->Vector2:
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--capture-war-hover="):
			var xy:=String(arg).trim_prefix("--capture-war-hover=").split(",")
			if xy.size()==2: return Vector2(float(xy[0]),float(xy[1]))
	return get_viewport().get_mouse_position()


## The topmost thing drawn under `point`, as an index into hits; -1 for none.
func hit_at(point:Vector2)->int:
	for i in hits.size():
		var h:Dictionary=hits[i]
		if h.has("rect") and (h.rect as Rect2).has_point(point): return i
		if h.has("line"):
			var line:PackedVector2Array=h.line
			for j in range(1,line.size()):
				if Geometry2D.get_closest_point_to_segment(point,line[j-1],line[j]).distance_to(point)<=10.0: return i
		if h.has("poly") and Geometry2D.is_point_in_polygon(point,h.poly): return i
	return -1


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
	# Every people's chief town (the world's regions), for the objectives' worth.
	var capitals:={}
	for civ:Dictionary in CivilizationSystem.civilizations:
		for region:Dictionary in civ.get("strategic_regions",[]):
			if String(region.get("role",""))=="capital": capitals[String(region.get("id",""))]=true
	# Every town of another people our people know of.
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",true,home,REACH_KM):
		var at:=_v2(city.get("position",{}))
		if not at.is_finite(): continue
		var owner:=String(city.get("controller",""))
		if owner=="": owner=String(city.get("civ_id",""))
		if owner=="human": owner="player"
		if owner=="player" and _near_any(towns,at,0.5): continue
		# A town reported burned (the borders' own reading of the report).
		var fields:Dictionary=city.get("fields",{}) if city.get("fields") is Dictionary else {}
		var people:Dictionary=fields.get("population",{}) if fields.get("population") is Dictionary else {}
		var garrison:Dictionary=fields.get("garrison",{}) if fields.get("garrison") is Dictionary else {}
		var chief:=capitals.has(String(city.get("city_id","")))
		var counted:=roundi((float(people.get("low",0.0))+float(people.get("high",0.0)))*0.5)
		towns.append({"name":String(city.get("name","")).trim_prefix("Reported home of "),"at":at,"owner":owner,"chief":chief,"ruin":Borders._report_damage(city)>=0.6,
			"city_id":String(city.get("city_id","")),"vp":victory_value(counted,chief),"people":counted,
			"garrison":[roundi(float(garrison.get("low",-1.0))),roundi(float(garrison.get("high",-1.0)))] if not garrison.is_empty() else [],
			"age":int(city.get("age_days",-1))})
	out.towns=towns
	# Each people's land: its towns' real claims, each cut where another
	# people's claim is stronger (nation_border_partition's own score).
	out.lands=lands(Borders.own_claims(_settlements())+Borders.foreign_claims(home,REACH_KM,_claim_cache))
	# Our bands out (the chart draws them; the view frames them).
	for army in MilitaryCampaign.field_armies:
		if not army is Dictionary or int((army as Dictionary).get("troops",0))<=0: continue
		var pos:=_v2((army as Dictionary).get("position",{}))
		if pos.is_finite(): frame.append(pos)
	# Our land, whole, in the frame.
	for land:Dictionary in out.lands:
		if String(land.owner)=="player": frame.append_array(_extent(land.center,float(land.radius)))
	# Lands that meet ours: the lines drawn where they meet.
	var meets:={}
	for line:Dictionary in Borders.published:
		var owners:Array=line.owners
		if owners[0]=="player": meets[String(owners[1])]=true
		elif owners[1]=="player": meets[String(owners[0])]=true
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
		var age:=_word_age(civ_id)
		var fighters:=WarLoop._their_fighters(civ_id)
		var people:=String(e.get("name",""))
		var front_tip:=PackedStringArray([Ledger.subtitle(e),"Dead: %s of ours, %s of theirs" % [EraWords.grouped(int(e.get("our_dead",0))),EraWords.grouped(int(e.get("their_dead",0)))],
			"Odds: %s" % Ledger.odds_words(e)])
		if bool(e.get("hot",false)) and String(e.get("kind",""))!="war": front_tip.append("Hot: their raiders may come")
		var spread:=_spread(age>STALE_DAYS)
		var host_tip:=PackedStringArray([("%s under arms: about %s" % [people,EraWords.grouped(fighters)]+((", maybe %s to %s" % [EraWords.grouped(roundi(fighters*(1.0-spread))),EraWords.grouped(roundi(fighters*(1.0+spread)))]) if age>STALE_DAYS else "")) if fighters>0 else "%s under arms: not known" % people,
			"As the war leader reckons it" if age<99999 else "We have no word of their towns",
			("Our word of them is %s old" % Ledger.span_words(age)) if age<99999 else "",
			("Worn by the fighting: %d%%" % roundi(float(e.get("their_worn",0.0))*100.0)) if float(e.get("their_worn",0.0))>0.0 else ""])
		var aim:Dictionary=WarLoop.front(civ_id).get("take",{}) if WarLoop.front(civ_id).get("take") is Dictionary and String(WarLoop.front(civ_id).get("stance",""))=="take" else {}
		var objective:=Vector2.INF
		for t:Dictionary in towns:
			if String(t.get("city_id",""))!="" and String(t.city_id)==String(aim.get("city_id","")): objective=t.at
		var marching:=false
		for army in MilitaryCampaign.field_armies:
			if army is Dictionary and String((army as Dictionary).get("destination_id",""))==String(aim.get("city_id","~")) and String((army as Dictionary).get("status",""))=="moving": marching=true
		var front:=_front(civ_id,home,there)
		var apart:=_apart_days(civ_id,home,there) if front.is_empty() else 0
		if front.is_empty():front_tip.insert(1,"No front: open land lies between us%s" % ((", about %s on the road" % Ledger.span_words(apart)) if apart>0 else ""))
		(out.enemies as Array).append({"tip_front":_lines(front_tip),"tip_host":_lines(host_tip),"civ_id":civ_id,"name":people,"there":there,"guessed":guessed,"front":front,"apart":apart,"meets":meets.has(civ_id),"objective":objective,"objective_id":String(aim.get("city_id","")),"marching":marching,
			"hot":bool(e.get("hot",false)),"war":String(e.get("kind",""))=="war","fighters":fighters,"stale":age>STALE_DAYS,
			"worn":clampf(float(e.get("their_worn",0.0)),0.0,1.0),"ours_share":clampf(raw/(1.0+raw),0.05,0.95),"color":_color(civ_id)})
	# Our army at home (army_bar.gd levy_card): on our chief town.
	var levy:=ArmyBar.levy_card(MilitaryCampaign)
	var reading:=Law.reading(MilitaryCampaign)
	var target:=int(reading.get("target",-1))
	var people:=maxi(1,int(reading.get("population",GameState.population_total)))
	# The watch at home (watch_military.gd): the home guard and those free
	# for the bands, in a drill course or joining.
	var army_home:=int(levy.get("men",0))
	out["levy_tip"]=_lines(PackedStringArray(["The watch at home: %s" % EraWords.grouped(army_home),
		"%s free for the bands%s" % [EraWords.grouped(int(levy.get("ready",0))),(" · %s in a drill course" % EraWords.grouped(int(levy.get("drill",0)))) if int(levy.get("drill",0))>0 else ""],
		("%s guard home and the towns" % EraWords.grouped(int(levy.get("watch",0)))) if int(levy.get("watch",0))>0 else "",
		("Keeping watch: %s of %s, %s" % [Law.level_name(String(reading.get("level",""))),EraWords.grouped(people),EraWords.grouped(target)]) if target>0 else "Nobody keeps watch"]))
	out.levy={"side":"ours","troops":army_home,"strength":clampf(float(reading.get("now",0))/float(target),0.0,1.0) if target>0 else 1.0,
		"will":float(levy.get("will",0.6)),"glyph":String(levy.get("glyph","spear")),"accent":OURS,
		"tab":("%d in drill" % int(levy.get("drill",0))) if int(levy.get("drill",0))>0 else ""}
	out.frame=frame
	out.signature=hash([Borders.published_revision,str(out.enemies.map(func(x:Dictionary)->int:return (x.front as PackedVector2Array).size())),towns.size(),str((out.lands as Array).map(func(l:Dictionary)->Array:return [l.owner,(l.center as Vector2).snapped(Vector2.ONE*0.01),snappedf(float(l.radius),0.01),(l.outline as PackedVector2Array)[0].snapped(Vector2.ONE*0.01) if not (l.outline as PackedVector2Array).is_empty() else Vector2.ZERO])),str(out.enemies.map(func(x:Dictionary)->Array:return [x.civ_id,x.hot,x.fighters,x.stale,snappedf(float(x.ours_share),0.02)])),levy.get("ready",0),levy.get("drill",0),levy.get("watch",0)])
	return out


## What a town is worth as an objective, as HOI4 counts victory points:
## 1 a village, 2 a town, 3 a city (its people as our scouts counted them,
## 0 when not counted); a chief town is worth one more, at most 3.
static func victory_value(people:int,chief:bool)->int:
	var value:=1 if people<1500 else (2 if people<15000 else 3)
	if chief: value+=1
	return clampi(value,1,3)


## Our towns from the settlement network, as the borders read them.
func _settlements()->Array:
	if is_instance_valid(terrain) and terrain.has_method("_settlement_model"):
		var model:Variant=terrain.call("_settlement_model")
		if model!=null and model.has_method("settlement_network_snapshot"):
			var network:Variant=model.call("settlement_network_snapshot")
			if network is Dictionary and (network as Dictionary).get("settlements") is Array: return network.settlements
	return GameState.player_settlements


## A ground's four furthest points, to frame it whole.
static func _extent(center:Vector2,radius:float)->Array:
	return [center+Vector2(radius,0.0),center-Vector2(radius,0.0),center+Vector2(0.0,radius),center-Vector2(0.0,radius)]


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


## The front with a people: the drawn line where our lands meet (the
## longest when they meet in several places); none while open land lies
## between us. A front is ground held against ground, never a line drawn
## across open country.
static func _front(civ_id:String,_home:Vector2,_there:Vector2)->PackedVector2Array:
	var best:=PackedVector2Array()
	for line:Dictionary in Borders.published:
		var owners:Array=line.owners
		if (owners[0]=="player" and owners[1]==civ_id) or (owners[1]=="player" and owners[0]==civ_id):
			var points:PackedVector2Array=line.points
			if points.size()>=2 and points.size()>best.size(): best=points
	return best


## Days of road between our home and their nearest town, by the general's
## own reckoning (war_allocation_model enemy), kept while their town stands
## where it stood.
static var _apart_cache:={}
static func _apart_days(civ_id:String,home:Vector2,there:Vector2)->int:
	var key:=hash([civ_id,home.snapped(Vector2.ONE),there.snapped(Vector2.ONE)])
	if _apart_cache.has(key): return int(_apart_cache[key])
	var e:Dictionary=preload("res://scripts/hud/war_allocation_model.gd").enemy(civ_id,0)
	var days:=int((e.get("nearest",{}) as Dictionary).get("days",0))
	if days<=0 and there.is_finite(): days=ceili(home.distance_to(there)/16.0)
	if _apart_cache.size()>64: _apart_cache.clear()
	_apart_cache[key]=days
	return days


## Every people's land from the claims: [{owner, center, radius, outline
## (world points, one per bearing)}], each claim cut back along each bearing
## to where another people's claim scores higher (the partition's rule: a
## place goes to the claim that scores highest there).
static func lands(claims:Array)->Array:
	var out:Array=[]
	var samples:=Partition.SHAPE_SAMPLES
	for claim:Dictionary in claims:
		var rivals:=claims.filter(func(c:Dictionary)->bool: return String(c.owner)!=String(claim.owner) and (c.center as Vector2).distance_to(claim.center)<float(c.radius)+float(claim.radius))
		var table:PackedFloat32Array=claim.table
		var outline:=PackedVector2Array()
		var center:Vector2=claim.center
		for k in samples:
			var dir:=Vector2.RIGHT.rotated(TAU*float(k)/float(samples))
			var reach:=float(table[k])
			if not rivals.is_empty() and _wins(claim,rivals,center+dir*reach)==false:
				var lo:=0.0;var hi:=reach
				for step in 12:
					var mid:=(lo+hi)*0.5
					if _wins(claim,rivals,center+dir*mid): lo=mid
					else: hi=mid
				reach=lo
			outline.append(center+dir*reach)
		out.append({"owner":String(claim.owner),"center":center,"radius":float(claim.radius),"outline":outline})
	return out


static func _wins(claim:Dictionary,rivals:Array,point:Vector2)->bool:
	var mine:=Partition.claim_score(claim,point)
	for rival:Dictionary in rivals:
		if Partition.claim_score(rival,point)>mine: return false
	return true


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
	var left:=HudTokens.DOCK_X+8.0
	var top:=HudTokens.CONTENT_TOP+strip+12.0
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
		if owner=="player" and String(GameState.nation_name)=="": continue
		var hull:PackedVector2Array=n.hull
		var box:=Rect2(hull[0],Vector2.ZERO)
		for q in hull: box=box.expand(q)
		var words:=" ".join(Array(_people_name(owner).to_upper().split("")))
		if words.strip_edges()=="": continue
		var fs:=clampi(roundi(box.size.x/maxf(6.0,float(words.length()))*1.25),15,40)
		var w:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		# Low in its ground, under the towns and the hosts that stand by them;
		# higher when the War screen's bar or strip would cover it.
		var free:=_free_rect(size)
		var at:=Vector2(box.get_center().x-w*0.5,box.end.y-box.size.y*0.12)
		for share:float in [0.12,0.3,0.5,0.75]:
			var y:=box.end.y-box.size.y*share
			if free.encloses(Rect2(Vector2(box.get_center().x-w*0.5,y-fs),Vector2(w,fs+4.0))):
				at=Vector2(box.get_center().x-w*0.5,y); break
		draw_string_outline(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,5,Color(PAPER,0.7))
		draw_string(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color((n.color as Color).darkened(0.5),0.85))
	for e:Dictionary in scene.get("enemies",[]):
		if (e.get("objective",Vector2.INF) as Vector2).is_finite() and not bool(e.get("marching",false)): _draw_plan(e)
		# A hot front is the war chart's to work (war_front_overlay border
		# fronts); a quiet one is dashed here.
		if not (bool(e.hot) or bool(e.war)): _draw_front(e)
		if (bool(e.hot) or bool(e.war)) and not bool(e.guessed) and (e.front as PackedVector2Array).is_empty(): _draw_threat(e)


## How far the war leader's count of a host may be off: wider when our word
## of them is old.
static func _spread(stale:bool)->float:
	return 0.25 if stale else 0.12


## Lines for the pointer, the empty ones left out.
static func _lines(parts:PackedStringArray)->PackedStringArray:
	var out:=PackedStringArray()
	for p in parts:
		if String(p).strip_edges()!="": out.append(p)
	return out


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
		# The land as claimed, on screen; a speck at least, so a village far
		# off still shows where it lies.
		var ring:=PackedVector2Array()
		for q:Vector2 in (land.get("outline",PackedVector2Array()) as PackedVector2Array):
			var on:=_screen(q)
			if on.is_finite(): ring.append(on)
		var r:=float(land.radius)*_px_per_km(land.center)
		if r<LAND_MIN_PX or ring.size()<3:
			ring=PackedVector2Array()
			for n in 20: ring.append(c+Vector2.RIGHT.rotated(TAU*float(n)/20.0)*maxf(r,LAND_MIN_PX))
		towns.append({"at":c,"r":maxf(r,LAND_MIN_PX),"ring":ring})
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
		ring.append_array(t.ring)
		clusters[key]=ring
	var out:Array=[]
	for key in clusters:
		var members:=0
		for i in towns.size():
			if group[i]==key: members+=1
		# A lone town keeps its own cut outline (concave where a rival's
		# land bites into it); a cluster is drawn as its hull.
		var shape:PackedVector2Array=clusters[key] if members==1 else Geometry2D.convex_hull(clusters[key])
		if shape.size()>=2 and shape[0].is_equal_approx(shape[shape.size()-1]): shape.remove_at(shape.size()-1)
		if shape.size()>=3 and (members>1 or not Geometry2D.triangulate_polygon(shape).is_empty()): out.append(shape)
		elif shape.size()>=3: out.append(Geometry2D.convex_hull(shape))
	return out


## Above the grounds and fronts: the towns as dots and names, then the hosts'
## counters, each clear of every name.
func draw_top(canvas:Control)->void:
	if not active or scene.is_empty():
		hits=[]
		return
	var view:=Rect2(Vector2.ZERO,canvas.size)
	# What the war chart drew (bands' counters, battles) is never covered.
	var taken:Array=_chart_rects()
	var found:Array=[]
	var font:=T.font("voice")
	var fs:=14
	for t:Dictionary in scene.get("towns",[]):
		var at:=_screen(t.at)
		if not at.is_finite() or not view.grow(20).has_point(at): continue
		var color:Color=_color(String(t.owner))
		var r:=6.0 if bool(t.get("chief",false)) else 4.5
		var enemy:=_enemy_of(String(t.owner))
		var aimed:=not enemy.is_empty() and String(t.get("city_id",""))!="" and String(t.city_id)==String(enemy.get("objective_id",""))
		if bool(t.get("ruin",false)):
			canvas.draw_line(at-Vector2(r,r),at+Vector2(r,r),Color(INK,0.7),2.0,true)
			canvas.draw_line(at-Vector2(r,-r),at+Vector2(r,-r),Color(INK,0.7),2.0,true)
		elif not enemy.is_empty():
			# An objective: its worth in stars, the one bid taken ringed.
			r=_draw_victory(canvas,at,int(t.get("vp",1)),color,aimed)
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
		var whose:=_people_name(String(t.owner)) if String(t.owner)!="" else "strangers"
		var tip:=PackedStringArray([words,"Ours" if String(t.owner)=="player" else "A town of %s" % whose,"Burned" if bool(t.get("ruin",false)) else ""])
		if not enemy.is_empty() and not bool(t.get("ruin",false)): tip.append_array(objective_lines(t,aimed))
		found.append({"civ_id":String(t.owner),"rect":Rect2(at-Vector2(r+3,r+3),Vector2(r+3,r+3)*2.0).merge(rect if clear else Rect2(at,Vector2.ZERO)),"lines":tip})
		if not clear: continue
		taken.append(rect)
		canvas.draw_string_outline(font,spot,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,4,Color(PAPER,0.9))
		canvas.draw_string(font,spot,words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(INK,0.95))
	# The hosts.
	var k:=0.9
	var plate:=Counter.plate_size(k)
	var items:Array=[]
	var home:=_screen(scene.get("home",Vector2.INF))
	if home.is_finite() and not (scene.get("levy",{}) as Dictionary).is_empty(): items.append({"at":home,"data":scene.levy,"tip":scene.get("levy_tip",PackedStringArray())})
	for e:Dictionary in scene.get("enemies",[]):
		var at:=_screen(e.there)
		if not at.is_finite(): continue
		var fighters:=int(e.fighters)
		var low:=roundi(float(fighters)*(1.0-_spread(bool(e.stale)))); var high:=roundi(float(fighters)*(1.0+_spread(bool(e.stale))))
		items.append({"at":at,"civ_id":String(e.civ_id),"tip":e.get("tip_host",PackedStringArray()),"data":{"side":"theirs","low":low,"high":high,"strength":1.0-float(e.worn),"accent":e.color,"glyph":"spear","stale":bool(e.stale) or bool(e.guessed)}})
	var free:=_free_rect(canvas.size)
	for item:Dictionary in items:
		var at:Vector2=item.at
		if not view.grow(80).has_point(at): continue
		var spot:=_clear_spot(at,plate,taken,free)
		var drawn:=Counter.draw(canvas,spot,item.data,k)
		taken.append(drawn.grow(4.0))
		found.push_front({"rect":drawn,"civ_id":String(item.get("civ_id","")),"lines":item.get("tip",PackedStringArray())})
		# A short ink line back to the town it stands for, when set aside.
		if spot.distance_to(at)>plate.y*0.75:
			canvas.draw_line(at,spot+(at-spot).limit_length(plate.y*0.55),Color(INK,0.55),1.4,true)
	# Each front's name and who is winning, on our side of it, where it is
	# clear of every counter and name.
	for e:Dictionary in scene.get("enemies",[]):
		var chip:=_draw_front_chip(canvas,e,taken,free)
		if chip.has_area(): found.push_front({"rect":chip,"civ_id":String(e.civ_id),"lines":e.get("tip_front",PackedStringArray())})
		var line:=PackedVector2Array()
		for p in (e.get("front",PackedVector2Array()) as PackedVector2Array):
			var q:=_screen(p)
			if q.is_finite(): line.append(q)
		if line.size()>=2: found.append({"line":line,"civ_id":String(e.civ_id),"lines":e.get("tip_front",PackedStringArray())})
	# The peoples' grounds, last (beneath everything else).
	for owner in _owners():
		for hull:PackedVector2Array in _land_of(String(owner)):
			var count:=0
			for t:Dictionary in scene.get("towns",[]):
				if String(t.owner)==String(owner): count+=1
			var at_war:=""
			for e:Dictionary in scene.get("enemies",[]):
				if String(e.civ_id)==String(owner): at_war="At war with us" if bool(e.war) else "In feud with us"
			found.append({"poly":hull,"civ_id":String(owner),"lines":PackedStringArray([_people_name(String(owner)) if String(owner)!="player" else "Our people's ground","%d %s we know" % [count,"town" if count==1 else "towns"],at_war])})
	hits=found
	# The pointer's tip, over everything.
	if hovered>=0 and hovered<hits.size():
		_draw_tip(canvas,(hits[hovered] as Dictionary).get("lines",PackedStringArray()))


## A few plain lines by the pointer, on paper.
func _draw_tip(canvas:Control,lines:PackedStringArray)->void:
	var shown:=_lines(lines)
	if shown.is_empty(): return
	var font:=T.font("ui")
	var bold:=T.font("ui_strong")
	var fs:=13
	var w:=0.0
	for i in shown.size():
		w=maxf(w,(bold if i==0 else font).get_string_size(shown[i],HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)
	var size:=Vector2(w+20.0,shown.size()*(fs+5.0)+12.0)
	var at:=_pointer()+Vector2(18,18)
	var free:=_free_rect(canvas.size)
	if at.x+size.x>free.end.x: at.x=at.x-size.x-30.0
	if at.y+size.y>free.end.y: at.y=at.y-size.y-30.0
	var box:=Rect2(at,size)
	canvas.draw_rect(Rect2(box.position+Vector2(2,3),box.size),Color(0,0,0,0.2))
	canvas.draw_rect(box,Color(PAPER,0.98))
	canvas.draw_rect(box,Color(INK,0.85),false,1.2)
	for i in shown.size():
		canvas.draw_string(bold if i==0 else font,box.position+Vector2(10.0,12.0+fs+i*(fs+5.0)-3.0),shown[i],HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(INK,1.0 if i==0 else 0.85))


## A front's chip: its people's name (HOT or WAR), and a bar of who is
## winning, on our side of the front, at the first place along it that is
## clear of everything already placed.
func _draw_front_chip(canvas:Control,e:Dictionary,taken:Array,free:Rect2)->Rect2:
	var line:PackedVector2Array=e.get("front",PackedVector2Array())
	var home:=_screen(scene.home)
	var there:=_screen(e.there)
	if not home.is_finite() or not there.is_finite(): return Rect2()
	var pts:=PackedVector2Array()
	for p in line:
		var q:=_screen(p)
		if not q.is_finite(): return Rect2()
		pts.append(q)
	# No front: the chip stands on the way between us, a third of the way
	# from their town, and says how far.
	if pts.size()<2:
		var mid:=there.lerp(home,0.33)
		pts=PackedVector2Array([mid,mid])
	var toward:=(there-home).normalized()
	var hot:=bool(e.hot) or bool(e.war)
	var font:=T.font("ui_strong")
	var words:=String(e.name).to_upper()+("  WAR" if bool(e.war) else ("  HOT" if bool(e.hot) else ""))
	if line.size()<2 and int(e.get("apart",0))>0: words+="  · %s off" % Ledger.span_words(int(e.apart))
	var fs:=12
	var tw:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	var w:=maxf(70.0,tw+12.0)
	var size:=Vector2(w,fs+6.0+12.0)
	var n:=pts.size()
	var tries:=[n/2,n/5,(n*4)/5,0,n-1]
	# The first place clear of everything; else the one that covers least
	# (our side first, then theirs, further out each time).
	var place:=Vector2.INF
	var least:=INF
	for reach:float in [34.0,70.0,110.0,-40.0,-80.0]:
		for i:int in tries:
			var centre:Vector2=pts[clampi(i,0,n-1)]-toward*reach
			var rect:=Rect2(centre-size*0.5,size)
			if free.has_area() and not free.encloses(rect): continue
			var cover:=0.0
			for r:Rect2 in taken:
				if r.intersects(rect): cover+=r.intersection(rect).get_area()
			if cover<least: least=cover; place=centre
			if cover<=0.0: break
		if least<=0.0: break
	if not place.is_finite(): place=pts[n/2]-toward*34.0
	var box:=Rect2(place-size*0.5,size)
	taken.append(box.grow(3.0))
	var chip:=Rect2(box.position,Vector2(w,fs+6.0))
	canvas.draw_rect(chip,Color(PAPER,0.95))
	canvas.draw_rect(chip,Color(WAR_RED if hot else INK,0.85),false,1.2)
	canvas.draw_string(font,Vector2(chip.position.x+(w-tw)*0.5,chip.end.y-5.0),words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(WAR_RED.darkened(0.2) if hot else INK,1.0))
	var bar:=Rect2(Vector2(box.position.x,chip.end.y+3.0),Vector2(w,8.0))
	var theirs:Color=e.color
	canvas.draw_rect(bar.grow(1.5),Color(PAPER,0.95))
	canvas.draw_rect(Rect2(bar.position,Vector2(w*float(e.ours_share),bar.size.y)),OURS)
	canvas.draw_rect(Rect2(bar.position+Vector2(w*float(e.ours_share),0),Vector2(w*(1.0-float(e.ours_share)),bar.size.y)),theirs.darkened(0.1))
	canvas.draw_rect(bar.grow(1.5),Color(INK,0.85),false,1.2)
	return box


## The war chart's own marks on screen (war_front_overlay.gd): its counters
## and its battles.
func _chart_rects()->Array:
	var out:Array=[]
	# Every band of ours where it stands: its counter and, in a fight, its
	# battle are drawn there, whatever the chart has drawn so far this frame.
	for army in MilitaryCampaign.field_armies:
		if not army is Dictionary or int((army as Dictionary).get("troops",0))<=0: continue
		var at:=_screen(_v2((army as Dictionary).get("position",{})))
		if at.is_finite(): out.append(Rect2(at-Vector2(70,50),Vector2(140,100)))
	var chart:Node=terrain.get_node_or_null("WarMapMarks/WarFrontOverlay") if is_instance_valid(terrain) else null
	if chart==null: return out
	var counted:Variant=chart.get("counter_rects")
	if counted is Array:
		for r in counted: if r is Rect2: out.append((r as Rect2).grow(4.0))
	var drawn:Variant=chart.get("hits")
	if drawn is Array:
		for h in drawn:
			if h is Dictionary and String((h as Dictionary).get("kind","")) in ["battle","battles"]:
				var c:Vector2=(h as Dictionary).get("centre",Vector2.INF)
				var radius:=float((h as Dictionary).get("radius",20.0))+10.0
				if c.is_finite(): out.append(Rect2(c-Vector2(radius,radius),Vector2(radius,radius)*2.0))
	return out


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


## The people at feud or war with us this owner is, or {}.
func _enemy_of(owner:String)->Dictionary:
	for e:Dictionary in scene.get("enemies",[]):
		if String(e.civ_id)==owner: return e
	return {}


## A town as an objective on the pointer: its worth, its people and its
## fighters as our scouts counted them, and whether it is the one bid taken.
static func objective_lines(t:Dictionary,aimed:bool)->PackedStringArray:
	var out:=PackedStringArray()
	var vp:=int(t.get("vp",1))
	out.append("Objective worth %d of 3%s" % [vp,", their chief town" if bool(t.get("chief",false)) else ""])
	if int(t.get("people",0))>0: out.append("About %s people, as last counted" % EraWords.grouped(int(t.people)))
	var garrison:Array=t.get("garrison",[])
	if garrison.size()==2 and int(garrison[1])>=0: out.append("Under arms there: %s to %s" % [EraWords.grouped(int(garrison[0])),EraWords.grouped(int(garrison[1]))])
	else: out.append("Nobody has counted their fighters there")
	if aimed: out.append("You bid the war leader take it")
	return out


## A victory star (or two, or three) on a town, in its people's colour;
## ringed in war red when it is the town bid taken. Returns its half-size.
func _draw_victory(canvas:Control,at:Vector2,vp:int,color:Color,aimed:bool)->float:
	var r:=6.0+1.5*float(vp)
	if aimed:
		canvas.draw_circle(at,r+7.0,Color(WAR_RED,0.16))
		canvas.draw_arc(at,r+7.0,0.0,TAU,28,Color(WAR_RED,0.95),2.4,true)
	var star:=PackedVector2Array()
	for k in 10:
		var radius:=r if k%2==0 else r*0.45
		star.append(at+Vector2.UP.rotated(TAU*float(k)/10.0)*radius)
	canvas.draw_colored_polygon(star,Color(PAPER,0.95))
	var inner:=PackedVector2Array()
	for q in star: inner.append(at+(q-at)*0.78)
	canvas.draw_colored_polygon(inner,color.darkened(0.2))
	var ring:=star.duplicate(); ring.append(star[0])
	canvas.draw_polyline(ring,Color(INK,0.9),1.3,true)
	if vp>1:
		var font:=T.font("ui_strong")
		var words:=str(vp)
		var fs:=11
		var w:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		var tag:=Rect2(at+Vector2(r*0.55,-r-6.0),Vector2(w+6.0,fs+3.0))
		canvas.draw_rect(tag,Color(PAPER,0.97))
		canvas.draw_rect(tag,Color(INK,0.85),false,1.0)
		canvas.draw_string(font,tag.position+Vector2(3.0,fs),words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,INK)
	return r


## The general's planned thrust to the town bid taken, as HOI4 draws a
## planned offensive: a broad arrow in war red from our side of the front
## (from home while open land lies between us) to the objective, bowed a
## little, pale until a band is on the road (then the war chart draws the
## march itself).
func _draw_plan(e:Dictionary)->void:
	var to:=_screen(e.objective)
	var line:PackedVector2Array=e.get("front",PackedVector2Array())
	var from_world:Vector2=scene.home
	if line.size()>=2:
		# The point of our front nearest the objective, a little on our side.
		var best:=line[0]
		for q in line:
			if q.distance_squared_to(e.objective)<best.distance_squared_to(e.objective): best=q
		from_world=best.lerp(scene.home,0.15)
	var from:=_screen(from_world)
	if not from.is_finite() or not to.is_finite(): return
	var gap:=to-from
	var length:=gap.length()
	if length<30.0: return
	var dir:=gap/length
	var side:=Vector2(-dir.y,dir.x)
	var tip_len:=minf(26.0,length*0.3)
	var spine:=PackedVector2Array()
	var steps:=16
	for i in steps+1:
		var t:=float(i)/float(steps)
		var bow:=sin(t*PI)*length*0.08
		spine.append(from.lerp(to-dir*(tip_len+10.0),t)+side*bow)
	var left:=PackedVector2Array(); var right:=PackedVector2Array()
	for i in spine.size():
		var t:=float(i)/float(spine.size()-1)
		var width:=lerpf(5.0,10.0,t)
		var a:=spine[maxi(0,i-1)]; var b:=spine[mini(spine.size()-1,i+1)]
		var n:=Vector2(-(b-a).normalized().y,(b-a).normalized().x)
		left.append(spine[i]+n*width); right.append(spine[i]-n*width)
	var end:=spine[spine.size()-1]
	var head_dir:=(to-dir*10.0-end).normalized()
	var head_side:=Vector2(-head_dir.y,head_dir.x)
	var body:=left.duplicate()
	body.append(end+head_side*17.0)
	body.append(to-dir*8.0)
	body.append(end-head_side*17.0)
	right.reverse()
	body.append_array(right)
	if Geometry2D.triangulate_polygon(body).is_empty(): return
	canvas_fill(body)


func canvas_fill(body:PackedVector2Array)->void:
	draw_colored_polygon(body,Color(WAR_RED,0.42))
	var ring:=body.duplicate(); ring.append(body[0])
	draw_polyline(ring,Color(WAR_RED.darkened(0.35),0.9),2.0,true)


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
