extends Control
## WAR AS AN INKED CHART: living front lines, the generals' arrows and
## objectives, clashes and the shape of the tactic being fought, siege works,
## raid tracks, and the fleets' and air arms' drawn zones.
##
## Everything here is observation: clicks pass through to the map (a click
## on an army or battle already opens its general and the war planning
## card). Nothing is ordered from this layer.
##
## Pipeline: collect() reads the ledgers (bounded, dated, honest) into plain
## inputs; compose() (pure, static) turns them into world-space primitives
## via war_front_model.gd and battle_tactics.gd; _draw() projects and inks
## them. Inputs are re-read at most every COLLECT_EVERY seconds and only
## rebuilt when they changed; drawing happens only when the camera, the
## scene or a transition moves. A change of front morphs over MORPH_SECONDS.

const Model:=preload("res://scripts/war_front_model.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Marks:=preload("res://scripts/war_map_marks.gd")
const Presentation:=preload("res://scripts/warfare_map_presentation.gd")

const COLLECT_EVERY:=0.5
const MORPH_SECONDS:=0.9
const LABEL_SIZE:=13

## One ink family; owner colour only as a thin accent.
const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
const OURS:=Color("#2f5d6b")
const OURS_WASH:=Color("#67b4cf")
const THEIRS:=Color("#8e3b2e")
const SEA:=Color("#2f4a52")
const SKY:=Color("#5b6b3a")

var terrain:Node
## Injected by tests and the capture scene: func(Vector2 world)->Vector2 screen.
var project:Callable
## Injected zoom band (tests/captures); otherwise from the camera.
var band_override:=""
var scene:Dictionary={}
var previous:Dictionary={}
var blend:=1.0
var inputs_signature:=0
var drawn_signature:=0
var collect_elapsed:=COLLECT_EVERY
var height_cache:Dictionary={}
## Probe counters (never saved).
var composes:=0
var redraws:=0
var last_compose_usec:=0


func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta:float)->void:
	collect_elapsed+=delta
	if collect_elapsed>=COLLECT_EVERY and is_instance_valid(terrain):
		collect_elapsed=0.0
		var inputs:=collect()
		var signature:=hash(inputs)
		if signature!=inputs_signature:
			inputs_signature=signature
			set_scene(compose(inputs))
	if blend<1.0: blend=minf(1.0,blend+delta/MORPH_SECONDS)
	var view:Array=[inputs_signature,size,blend]
	var camera:=_camera()
	if camera!=null: view.append_array([camera.global_transform,camera.size])
	var signature:=hash(view)
	if signature==drawn_signature: return
	drawn_signature=signature
	redraws+=1
	queue_redraw()


func set_scene(next:Dictionary,immediate:bool=false)->void:
	var start:=Time.get_ticks_usec()
	previous=scene if not immediate else {}
	scene=next
	blend=1.0 if immediate or previous.is_empty() else 0.0
	composes+=1
	last_compose_usec=Time.get_ticks_usec()-start
	queue_redraw()


# --- Reading the world (bounded, dated) -----------------------------------------

func _camera()->Camera3D:
	return terrain.camera if is_instance_valid(terrain) and terrain.get("camera") is Camera3D else null


static func _v2(position:Variant)->Vector2:
	if position is Vector2: return position
	if position is Vector3: return Vector2(position.x,position.z)
	if position is Dictionary: return Vector2(float(position.get("x",0.0)),float(position.get("z",0.0)))
	return Vector2.INF


func collect()->Dictionary:
	var today:=int(GameState.elapsed_days)
	var known:=Tactics.known_for_player()
	var stage:=EraWords.stage()
	var home:Vector2=CivilizationSystem.player_world_origin
	var friendly:Array=[]
	var snapshot:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var live:=bool(snapshot.get("live_reports",true))
	var largest:=0
	var theatre:=0
	for army_variant in snapshot.get("armies",[]):
		var army:Dictionary=army_variant
		var troops:=int(army.get("troops",0))
		if troops<=0: continue
		var at_home:=String(army.get("status","stationed"))=="stationed" and String(army.get("location_id",""))=="player_home"
		var shown:=army
		# Before signals the map knows only what the last runner reported.
		if not live and not at_home:
			shown=army.get("last_report",{})
			if shown.is_empty(): continue
		var pos:=_v2(shown.get("position",army.get("position",{})))
		if not pos.is_finite(): continue
		var objective:=Vector2.INF
		var offensive:=false
		if String(shown.get("status",army.get("status","")))=="moving":
			objective=_v2(army.get("destination_position",{}))
			offensive=String(army.get("destination_id",""))!="player_home"
		elif not (army.get("command_route",[]) as Array).is_empty():
			objective=_v2((army.command_route as Array)[-1]); offensive=true
		largest=maxi(largest,int(shown.get("troops",troops))); theatre+=int(shown.get("troops",troops))
		friendly.append({"id":str(int(army.get("army_id",0))),"pos":pos,"strength":float(shown.get("troops",troops)),"objective":objective,"offensive":offensive,"name":String(army.get("name","")),"report_age":0 if live or at_home else maxi(0,today-int(shown.get("day",today)))})
	var enemy:Array=[]
	var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
	for list_name in ["visible","recent"]:
		for sighting_variant in observation.get(list_name,[]):
			var sighting:Dictionary=sighting_variant
			if not bool(sighting.get("hostile",false)) or bool(sighting.get("carries_report",false)): continue
			var low:=int(sighting.get("strength_estimate_low",0)); var high:=maxi(low,int(sighting.get("strength_estimate_high",low)))
			var seen:=int(sighting.get("last_seen_day",sighting.get("observed_day",today)))
			var pos:=_v2(sighting.get("position",{}))
			if not pos.is_finite(): continue
			enemy.append({"id":String(sighting.get("id","")),"pos":pos,"strength":float(low+high)*0.5,"age_days":maxi(0,today-seen),"moving":bool(sighting.get("moving",false)),"heading":float(sighting.get("heading",0.0)),"seen_day":seen})
	var engagements:Array=[]
	var engagement:Dictionary=MilitaryCampaign.engagement_snapshot()
	if not engagement.is_empty():
		engagements.append(_engagement_input(engagement,friendly,enemy,home))
	var sieges:Array=[]
	var siege:Dictionary=MilitaryCampaign.active_siege
	if not siege.is_empty():
		var offensive:=String(siege.get("mode",""))=="offensive"
		var works:="circumvallation" if (known.has("field_fortifications") or known.has("siege_engineering")) and offensive else ("circumvallation" if not offensive and float((siege.get("threat",{}) as Dictionary).get("technology",0.0))>=0.45 else "blockade_camp")
		sieges.append({"pos":_v2(siege.get("target_position",{})) if offensive else home,"pressure":float(siege.get("pressure",0.0)),"works":works,"ours":offensive,"days":int(siege.get("days",0))})
	var raids:=_raid_inputs(today,home)
	return {"stage":stage,"today":today,"home":home,"mode":Model.mode(stage,known,largest,friendly.size(),theatre),
		"friendly":friendly,"enemy":enemy,"engagements":engagements,"sieges":sieges,"raids":raids,"zones":_zone_inputs(today)}


func _engagement_input(engagement:Dictionary,friendly:Array,enemy:Array,home:Vector2)->Dictionary:
	var home_side:=String(engagement.get("home_side","attacker"))
	var pos:=home
	var force_id:=str(int(engagement.get("home_force_id",0)))
	for f in friendly:
		if String(f.id)==force_id: pos=f.pos
	var threat:Dictionary=engagement.get("threat",{})
	var target:=String(threat.get("target_region_id",""))
	if force_id=="0" and target!="":
		var city:Dictionary=CivilizationSystem.city_intelligence.known("player",target)
		if not city.is_empty(): pos=_v2(city.get("position",{}))
	var axis:=Vector2.RIGHT
	var nearest:=INF
	for e in enemy:
		var d:=(e.pos as Vector2).distance_to(pos)
		if d<nearest and d>0.0: nearest=d; axis=((e.pos as Vector2)-pos).normalized()
	if nearest==INF:
		var source:=String(threat.get("source_civ_id",""))
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
			if String(city.get("civ_id",""))==source:
				var at:=_v2(city.get("position",{}))
				if at.is_finite() and at.distance_to(pos)>0.0: axis=(at-pos).normalized(); break
	var rounds:Array=engagement.get("rounds",[])
	var last:Dictionary=rounds[-1] if not rounds.is_empty() else {}
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var plan:Dictionary=engagement.get("tactics",{})
	return {"pos":pos,"axis":axis,"ours":String((plan.get(home_side,{}) as Dictionary).get("id",Tactics.BASELINE)),"theirs":String((plan.get(enemy_side,{}) as Dictionary).get("id",Tactics.BASELINE)),
		"rounds":int(engagement.get("round",0)),"phase_ours":String(last.get(home_side+"_tactic_phase","hold")),"phase_theirs":String(last.get(enemy_side+"_tactic_phase","hold")),"event":String(last.get("tactic_event",""))}


func _raid_inputs(today:int,home:Vector2)->Array:
	var out:Array=[]
	var ledger_variant:Variant=preload("res://scripts/war_loop.gd").state().get("fronts",{})
	if not ledger_variant is Dictionary: return out
	for civ_id in (ledger_variant as Dictionary):
		var f:Dictionary=ledger_variant[civ_id] if ledger_variant[civ_id] is Dictionary else {}
		var there:=_enemy_home(String(civ_id),home)
		var war:Dictionary=f.get("war",{}) if f.get("war") is Dictionary else {}
		for source in [f.get("op",{}),war.get("op",{})]:
			if not source is Dictionary or (source as Dictionary).is_empty() or String(source.get("objective",""))=="war_parley": continue
			var at:=Marks.band_point(home,there,int(source.get("start",today)),int(source.get("due",today)),today)
			out.append({"ours":true,"from":home,"to":at,"toward":there,"day":int(source.get("start",today)),"fought":false})
		for raid in [f.get("last_raid",{}),war.get("last_attack",{})]:
			if not raid is Dictionary or (raid as Dictionary).is_empty(): continue
			var ago:=today-int(raid.get("day",-99999))
			if Marks.raid_alpha(ago)<=0.0: continue
			var key:="%s:%d" % [civ_id,int(raid.get("day",0))]
			var struck:=Marks.raid_point(home,there,String(raid.get("target","")),key)
			out.append({"ours":false,"from":struck.lerp(there,0.35),"to":struck,"toward":home,"day":int(raid.get("day",today)),"fought":true,"alpha":Marks.raid_alpha(ago)})
	return out.slice(0,Model.MAX_CLASHES)


func _enemy_home(civ_id:String,home:Vector2)->Vector2:
	var best:=Vector2.INF
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
		if String(city.get("civ_id",""))!=civ_id: continue
		var point:=_v2(city.get("position",{}))
		if best==Vector2.INF or point.distance_squared_to(home)<best.distance_squared_to(home): best=point
	return best if best!=Vector2.INF else home+Vector2(8.0,0.0)


func _zone_inputs(today:int)->Array:
	var out:Array=[]
	var op:Variant=MilitaryCampaign.get("joint_operations")
	if op==null: return out
	for force:Dictionary in op.state.forces:
		if String(force.get("owner",""))!="player" or String(force.get("mission","hold"))=="hold": continue
		var region:Dictionary=force.get("region",{})
		if region.is_empty(): continue
		var vertices:=PackedVector2Array()
		for vertex in region.get("vertices",[]): vertices.append(_v2(vertex))
		if vertices.size()<3: continue
		var base:Dictionary=op.base(int(force.get("base_id",0)))
		var contacts:Array=[]
		for contact:Dictionary in op.state.contacts.values():
			if String(contact.get("observer",""))!="player" or String(contact.get("domain",""))!=String(force.domain): continue
			var at:=_v2(contact.get("position",{}))
			if Geometry2D.is_point_in_polygon(at,vertices): contacts.append({"pos":at,"age":today-int(contact.get("day",today))})
		var port:=Vector2.INF
		if String(force.get("tactic","")) in ["close_blockade","distant_blockade"]:
			for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
				var at:=_v2(city.get("position",{}))
				if Geometry2D.is_point_in_polygon(at,vertices): port=at; break
		out.append({"domain":String(force.domain),"vertices":vertices,"control":float(op.effects.control("player",region)),"mission":String(force.mission),"tactic":String(force.get("tactic","")),
			"base":_v2(base.get("position",{})) if not base.is_empty() else Vector2.INF,"port":port,"contacts":contacts.slice(0,6),"name":String(force.get("name",""))})
		if out.size()>=16: break
	return out


# --- Composition (pure) -------------------------------------------------------------

## Plain inputs -> world-space primitives. Bounded by the model's limits.
static func compose(inputs:Dictionary)->Dictionary:
	var mode:=String(inputs.get("mode","front"))
	var stage:=String(inputs.get("stage","reckoned"))
	var friendly:Array=inputs.get("friendly",[])
	var enemy:Array=inputs.get("enemy",[])
	var home:Vector2=inputs.get("home",Vector2.ZERO)
	var out:={"mode":mode,"stage":stage,"fronts":[],"faceoffs":[],"fallbacks":[],"supply":[],"arrows":[],"objectives":[],"clashes":[],"sieges":[],"raids":[],"zones":[],"sigma":1.0}
	var fronts:Array=[]
	if mode in ["front","theatre"]:
		var derived:=Model.derive(friendly,enemy)
		fronts=derived.fronts; out.sigma=float(derived.sigma) if float(derived.sigma)>0.0 else 1.0
		out.fronts=fronts
	elif mode=="host":
		var reach:=6.0
		for f in friendly:
			for e in enemy: reach=minf(reach,maxf(0.6,(f.pos as Vector2).distance_to(e.pos)*1.01))
		out.faceoffs=Model.face_offs(friendly,enemy,maxf(reach,2.5))
		out.sigma=1.0
	if mode=="theatre":
		for front in fronts: out.fallbacks.append(Model.fallback_line(front,home,float(out.sigma)*0.8))
		for f in friendly.slice(0,Model.MAX_FRIENDLY):
			if (f.pos as Vector2).distance_to(home)>float(out.sigma)*0.5: out.supply.append(PackedVector2Array([home,f.pos]))
	# The generals' intent: arrows to their objectives (not in the raid age,
	# where a band's path is drawn as a raid track instead).
	if mode!="raid":
		var bias:=0.0
		for f in friendly:
			if out.arrows.size()>=Model.MAX_ARROWS: break
			var objective:Vector2=f.get("objective",Vector2.INF)
			if not objective.is_finite() or (f.pos as Vector2).distance_to(objective)<0.05: continue
			var spec:=Model.arrow(f.pos,objective,fronts,bias)
			bias=-bias+0.05 if bias<=0.0 else -bias
			out.arrows.append({"points":Model.arrow_points(spec),"ours":true,"offensive":bool(f.get("offensive",false)),"weight":clampf(log(maxf(10.0,float(f.strength)))/log(10.0)/5.0,0.25,1.0),"stale":int(f.get("report_age",0))>=Model.STALE_DAYS})
			out.objectives.append({"pos":objective,"ours":true,"offensive":bool(f.get("offensive",false))})
		# Enemy arrows only from observed movement, dated.
		for e in enemy:
			if out.arrows.size()>=Model.MAX_ARROWS: break
			if not bool(e.get("moving",false)): continue
			var heading:=float(e.get("heading",0.0))
			var direction:=Vector2(0,-1).rotated(-heading)
			var length:=float(out.sigma)*1.2
			var start:Vector2=e.pos
			var spec:=PackedVector2Array([start,start+direction*length*0.5,start+direction*length])
			out.arrows.append({"points":Model.arrow_points(spec,10),"ours":false,"offensive":true,"weight":clampf(log(maxf(10.0,float(e.strength)))/log(10.0)/5.0,0.25,0.8),"stale":float(e.get("age_days",0))>=Model.STALE_DAYS,"seen_day":int(e.get("seen_day",-1))})
	for engagement in (inputs.get("engagements",[]) as Array).slice(0,Model.MAX_CLASHES):
		var ours_id:=String(engagement.get("ours",Tactics.BASELINE))
		var theirs_id:=String(engagement.get("theirs",Tactics.BASELINE))
		var rounds:=int(engagement.get("rounds",0))
		out.clashes.append({"pos":engagement.pos,"axis":engagement.get("axis",Vector2.RIGHT),"ours":ours_id,"theirs":theirs_id,
			"shape_ours":Tactics.shape(ours_id,rounds,String(engagement.get("phase_ours","hold"))),"shape_theirs":Tactics.shape(theirs_id,rounds,String(engagement.get("phase_theirs","hold"))),
			"label":_cap(Tactics.name_of(ours_id,stage)) if ours_id!=Tactics.BASELINE else _cap(Tactics.name_of(theirs_id,stage)) if theirs_id!=Tactics.BASELINE else "","event":String(engagement.get("event",""))})
	for siege in (inputs.get("sieges",[]) as Array).slice(0,4):
		out.sieges.append({"pos":siege.pos,"pressure":clampf(float(siege.get("pressure",0.0)),0.0,1.0),"works":String(siege.get("works","blockade_camp")),"ours":bool(siege.get("ours",true)),"label":_cap(Tactics.name_of(String(siege.get("works","blockade_camp")),stage))})
	for raid in (inputs.get("raids",[]) as Array).slice(0,Model.MAX_CLASHES):
		var from:Vector2=raid.from; var to:Vector2=raid.to
		var delta:=to-from
		var spec:=PackedVector2Array([from,from+delta*0.5+delta.orthogonal()*0.18,to])
		out.raids.append({"points":Model.arrow_points(spec,14),"ours":bool(raid.get("ours",false)),"fought":bool(raid.get("fought",false)),"alpha":float(raid.get("alpha",1.0))})
	for zone in (inputs.get("zones",[]) as Array).slice(0,16):
		var entry:Dictionary=(zone as Dictionary).duplicate()
		entry["label"]=_cap(Tactics.name_of(String(zone.get("tactic","")),stage)) if String(zone.get("tactic",""))!="" else ""
		entry["shape"]=String((Tactics.ZONE_TACTICS.get(String(zone.get("tactic","")),{}) as Dictionary).get("shape",""))
		out.zones.append(entry)
	return out


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


## Primitive counts, for probes and tests (bounded regardless of armies).
static func primitive_count(built:Dictionary)->int:
	var total:=0
	for key in ["fronts","faceoffs","fallbacks","supply","arrows","objectives","clashes","sieges","raids","zones"]: total+=(built.get(key,[]) as Array).size()
	return total


# --- Projection -----------------------------------------------------------------------

func _screen(p:Vector2)->Vector2:
	if project.is_valid(): return project.call(p)
	var camera:=_camera()
	if camera==null: return Vector2.INF
	if not height_cache.has(p):
		if height_cache.size()>4096: height_cache.clear()
		height_cache[p]=float(terrain._height_at(p.x,p.y)) if terrain.has_method("_height_at") else 0.0
	var world:=Vector3(p.x,float(height_cache[p])+0.002,p.y)
	if camera.is_position_behind(world): return Vector2.INF
	return camera.unproject_position(world)


func _band()->String:
	if band_override!="": return band_override
	var camera:=_camera()
	return Presentation.scale_band(camera.size if camera else 190.0)


func _poly(points:PackedVector2Array)->PackedVector2Array:
	var out:=PackedVector2Array()
	for p in points:
		var s:=_screen(p)
		if not s.is_finite(): return PackedVector2Array()
		out.append(s)
	return out


# --- Drawing ------------------------------------------------------------------------------

func _draw()->void:
	if scene.is_empty(): return
	var band:=_band()
	if band=="ground": return
	var t:=smoothstep(0.0,1.0,blend)
	var font:=ThemeDB.fallback_font
	if band!="local":
		for zone in scene.get("zones",[]): _draw_zone(zone,font)
	for supply in scene.get("supply",[]):
		_dashed(_poly(supply),Color(INK,0.35),1.0,3.0,6.0)
	for index in (scene.get("fallbacks",[]) as Array).size():
		_dashed(_poly(scene.fallbacks[index]),Color(OURS,0.55),1.2,10.0,6.0)
	var old_fronts:Array=previous.get("fronts",[]) if blend<1.0 else []
	for index in (scene.get("fronts",[]) as Array).size():
		var front:Dictionary=scene.fronts[index]
		var points:PackedVector2Array=front.points
		if index<old_fronts.size():
			var before:=Model.resample(old_fronts[index].points,points.size())
			var morphed:=PackedVector2Array()
			for k in points.size(): morphed.append(before[k].lerp(points[k],t))
			points=morphed
		var drawn:=front.duplicate(); drawn["world"]=points
		_draw_front(_poly(points),drawn)
	for faceoff in scene.get("faceoffs",[]):
		_draw_front(_poly(faceoff.points),{"stale":bool(faceoff.get("stale",false)),"width":PackedFloat32Array(),"pressure":PackedFloat32Array()})
	for raid in scene.get("raids",[]): _draw_raid(raid)
	for arrow in scene.get("arrows",[]): _draw_arrow(arrow)
	for objective in scene.get("objectives",[]): _draw_objective(objective)
	for siege in scene.get("sieges",[]): _draw_siege(siege,font)
	for clash in scene.get("clashes",[]): _draw_clash(clash,font,band)
	if band=="world": return
	# One small dated caption per stale front: the map says how old it is.
	for front in scene.get("fronts",[]):
		if not bool(front.get("stale",false)): continue
		var ages:PackedFloat32Array=front.age
		var oldest:=0
		var where:=0
		for k in ages.size():
			if roundi(ages[k])>oldest: oldest=roundi(ages[k]); where=k
		var at:=_screen((front.points as PackedVector2Array)[where])
		if at.is_finite(): _caption(at+Vector2(14,10),"Their line here as last seen, %d days ago" % oldest,Color(THEIRS,0.9),font)


func _dashed(points:PackedVector2Array,color:Color,width:float,dash:float,gap:float)->void:
	if points.size()<2: return
	var carry:=0.0
	var drawing:=true
	for i in range(1,points.size()):
		var a:=points[i-1]; var b:=points[i]
		var length:=a.distance_to(b)
		var at:=0.0
		while at<length:
			var span:=minf((dash if drawing else gap)-carry,length-at)
			if drawing: draw_line(a.lerp(b,at/length),a.lerp(b,(at+span)/length),color,width,true)
			at+=span; carry+=span
			if carry>=(dash if drawing else gap)-0.001: carry=0.0; drawing=not drawing


## The front: a soft wash of each side's colour either side of the line (the
## ground each holds), a paper halo, an ink line whose weight follows how
## massed the two sides are, and oxblood teeth pointing into the enemy.
## Stretches derived from stale reports are dashed and paler.
func _draw_front(points:PackedVector2Array,front:Dictionary)->void:
	if points.size()<2: return
	var widths:PackedFloat32Array=front.get("width",PackedFloat32Array())
	var ages:PackedFloat32Array=front.get("age",PackedFloat32Array())
	var toward:PackedVector2Array=front.get("toward",PackedVector2Array())
	var world:PackedVector2Array=front.get("world",PackedVector2Array())
	var all_stale:=bool(front.get("stale",false)) and ages.is_empty()
	# Screen normals toward the enemy, one per vertex.
	var normals:=PackedVector2Array()
	for i in points.size():
		var a:=points[maxi(0,i-1)]; var b:=points[mini(points.size()-1,i+1)]
		var normal:=(b-a).normalized().orthogonal()
		if i<toward.size() and i<world.size():
			var ahead:=_screen(world[i]+toward[i]*maxf(0.0001,float(scene.get("sigma",1.0))*0.05))
			if ahead.is_finite() and normal.dot(ahead-points[i])<0.0: normal=-normal
		elif i>0 and normals[i-1].dot(normal)<0.0: normal=-normal
		normals.append(normal)
	var wash:=14.0
	for i in range(1,points.size()):
		var n0:=normals[i-1]; var n1:=normals[i]
		var theirs_quad:=PackedVector2Array([points[i-1],points[i],points[i]+n1*wash,points[i-1]+n0*wash])
		var ours_quad:=PackedVector2Array([points[i-1],points[i],points[i]-n1*wash,points[i-1]-n0*wash])
		draw_colored_polygon(theirs_quad,Color(THEIRS,0.13))
		draw_colored_polygon(ours_quad,Color(OURS_WASH,0.16))
	draw_polyline(points,Color(PAPER,0.6),8.0,true)
	for i in range(1,points.size()):
		var stale:=all_stale or (i<ages.size() and float(ages[i])>=float(Model.STALE_DAYS))
		var w:=2.4+3.0*(float(widths[i]) if i<widths.size() else 0.6)
		if stale: _dashed(PackedVector2Array([points[i-1],points[i]]),Color(INK,0.5),2.0,6.0,5.0)
		else: draw_line(points[i-1],points[i],Color(INK,0.92),w,true)
	var pressure:PackedFloat32Array=front.get("pressure",PackedFloat32Array())
	var stride:=maxi(2,points.size()/16)
	for i in range(stride/2,points.size()-1,stride):
		var a:=points[i]; var b:=points[i+1]
		var along:=(b-a).normalized()
		var tooth:=8.0+4.0*absf(float(pressure[i]) if i<pressure.size() else 0.0)
		var color:=Color(THEIRS,0.9)
		if all_stale or (i<ages.size() and float(ages[i])>=float(Model.STALE_DAYS)): color.a=0.45
		draw_colored_polygon(PackedVector2Array([a-along*4.5,a+along*4.5,a+normals[i]*tooth]),color)


func _draw_arrow(arrow:Dictionary)->void:
	var points:=_poly(arrow.points)
	if points.size()<3: return
	var ours:=bool(arrow.get("ours",true))
	var stale:=bool(arrow.get("stale",false))
	var base:=6.0+10.0*float(arrow.get("weight",0.5))
	# A tapered body (HOI4-style plan arrow) with an inked edge.
	var left:=PackedVector2Array(); var right:=PackedVector2Array()
	var shaft_end:=points.size()-3
	for k in shaft_end+1:
		var a:=points[maxi(0,k-1)]; var b:=points[mini(points.size()-1,k+1)]
		var normal:=(b-a).normalized().orthogonal()
		var half:=lerpf(base*0.45,base*0.28,float(k)/float(maxi(1,shaft_end)))
		left.append(points[k]+normal*half); right.append(points[k]-normal*half)
	var tip:=points[-1]
	var back:=points[shaft_end]
	var direction:=(tip-back).normalized()
	var wing:=direction.orthogonal()*base*0.75
	var body:=left.duplicate()
	body.append(back+wing); body.append(tip); body.append(back-wing)
	right.reverse(); body.append_array(right)
	var fill:=Color(OURS_WASH if ours else THEIRS,0.38 if ours and bool(arrow.get("offensive",false)) else 0.18)
	if stale: fill.a*=0.5
	if Geometry2D.triangulate_polygon(body).size()>0: draw_colored_polygon(body,fill)
	var outline:=body.duplicate(); outline.append(body[0])
	if stale or not ours: _dashed(outline,Color(OURS if ours else THEIRS,0.85),1.3,6.0,4.0)
	else: draw_polyline(outline,Color(INK,0.85),1.3,true)


func _draw_objective(objective:Dictionary)->void:
	var at:=_screen(objective.pos)
	if not at.is_finite(): return
	var color:=Color(INK,0.9)
	draw_arc(at,9.0,0.0,TAU,28,Color(PAPER,0.7),5.0,true)
	draw_arc(at,9.0,0.0,TAU,28,color,1.6,true)
	draw_line(at+Vector2(-5,-5),at+Vector2(5,5),color,1.6,true)
	draw_line(at+Vector2(-5,5),at+Vector2(5,-5),color,1.6,true)


func _draw_raid(raid:Dictionary)->void:
	var points:=_poly(raid.points)
	if points.size()<2: return
	var ours:=bool(raid.get("ours",false))
	var color:=Color(OURS if ours else THEIRS,0.85*float(raid.get("alpha",1.0)))
	# A footpath of dots, like the scout charts, with a small head at the end.
	for k in range(0,points.size(),1):
		draw_circle(points[k],4.0,Color(PAPER,0.5*color.a))
		draw_circle(points[k],2.6,color)
	var tip:=points[-1]; var back:=points[-2]
	var direction:=(tip-back).normalized()
	draw_line(tip,tip-direction.rotated(0.5)*11.0,color,2.2,true)
	draw_line(tip,tip-direction.rotated(-0.5)*11.0,color,2.2,true)
	if bool(raid.get("fought",false)): _crossed_strokes(tip,7.0,Color(THEIRS,color.a))


func _crossed_strokes(at:Vector2,size_px:float,color:Color)->void:
	draw_line(at+Vector2(-size_px,-size_px),at+Vector2(size_px,size_px),color,2.2,true)
	draw_line(at+Vector2(-size_px,size_px),at+Vector2(size_px,-size_px),color,2.2,true)


func _draw_siege(siege:Dictionary,font:Font)->void:
	var centre:=_screen(siege.pos)
	if not centre.is_finite(): return
	# The ring tightens as the siege bites.
	var radius:=lerpf(46.0,24.0,float(siege.pressure))
	var color:=Color(OURS if bool(siege.ours) else THEIRS,0.9)
	var segments:=48
	var ring:=PackedVector2Array()
	for k in segments+1: ring.append(centre+Vector2.from_angle(TAU*float(k)/float(segments))*radius)
	draw_polyline(ring,Color(PAPER,0.6),6.0,true)
	if String(siege.works)=="circumvallation":
		draw_polyline(ring,color,2.0,true)
		for k in 24:
			var direction:=Vector2.from_angle(TAU*float(k)/24.0)
			# Teeth facing the town (contravallation) and outward (circumvallation).
			draw_line(centre+direction*radius,centre+direction*(radius-5.0),color,1.4,true)
			if k%2==0: draw_line(centre+direction*radius,centre+direction*(radius+4.0),Color(color,0.6),1.2,true)
	else:
		_dashed(ring,color,1.8,7.0,6.0)
		for k in 6: draw_circle(centre+Vector2.from_angle(TAU*float(k)/6.0+0.3)*radius,3.0,color)
	_caption(centre+Vector2(-radius,radius+22.0),String(siege.label),color,font)


## A clash and the tactic being fought there, drawn in screen space around
## the contact so it reads at every zoom. Shapes follow battle_tactics.shape.
func _draw_clash(clash:Dictionary,font:Font,band:String)->void:
	var at:=_screen(clash.pos)
	if not at.is_finite(): return
	var ahead:=_screen((clash.pos as Vector2)+(clash.axis as Vector2)*0.01)
	var axis:=(ahead-at).normalized() if ahead.is_finite() and ahead.distance_to(at)>0.001 else Vector2.RIGHT
	var across:=axis.orthogonal()
	var r:=56.0 if band=="local" else 46.0
	var ours:Dictionary=clash.shape_ours
	var theirs:Dictionary=clash.shape_theirs
	var t:=smoothstep(0.0,1.0,blend)
	var before:Dictionary=_previous_clash(clash)
	var bulge:=lerpf(float(before.get("bulge",ours.bulge)),float(ours.bulge),t)
	var wings:=lerpf(float(before.get("wings",ours.wings)),float(ours.wings),t)
	var wing:=lerpf(float(before.get("wing",ours.wing)),float(ours.wing),t)
	var closure:=lerpf(float(before.get("closure",ours.closure)),float(ours.closure),t)
	# Our line: across the axis, behind the contact, bowed by the tactic.
	var line:=PackedVector2Array()
	for k in 13:
		var s:=float(k)/12.0*2.0-1.0
		var bow:=bulge*r*0.45*(1.0-s*s)
		var curl:=wings*r*0.6*s*s
		line.append(at-axis*r*0.18+across*s*r+axis*(bow+curl))
	draw_polyline(line,Color(PAPER,0.6),6.0,true)
	draw_polyline(line,Color(OURS,0.95),3.4,true)
	# Their line opposite, straight unless their own tactic bends it.
	var their_line:=PackedVector2Array()
	for k in 9:
		var s:=float(k)/8.0*2.0-1.0
		their_line.append(at+axis*r*0.22+across*s*r*0.85-axis*float(theirs.bulge)*r*0.4*(1.0-s*s))
	draw_polyline(their_line,Color(PAPER,0.6),6.0,true)
	draw_polyline(their_line,Color(THEIRS,0.9),3.0,true)
	if int(ours.depth)>0:
		for d in int(ours.depth): _dashed(PackedVector2Array([at-axis*r*(0.45+0.25*d)-across*r*0.8,at-axis*r*(0.45+0.25*d)+across*r*0.8]),Color(OURS,0.7),1.4,5.0,4.0)
	if String(ours.shape) in ["trenches","camp"] or int(theirs.depth)>0:
		# Works harden as the battle goes on: more hatching each round.
		var hatch:=int(3+float(ours.hardening)*9.0)
		for k in hatch:
			var s:=float(k)/float(maxi(1,hatch-1))*2.0-1.0
			var foot:=at-axis*r*0.18+across*s*r*0.9
			draw_line(foot,foot-axis*5.0+across*3.0,Color(OURS,0.7),1.2,true)
	if wing>0.01:
		_hook(at-axis*r*0.2+across*r,axis,across,r,wing,1.0)
	if wings>0.01 and String(ours.shape) in ["double_envelopment","converging"]:
		_hook(at-axis*r*0.2+across*r,axis,across,r,wings,1.0)
		_hook(at-axis*r*0.2-across*r,axis,-across,r,wings,1.0)
	if closure>0.01:
		# The pocket closing behind them.
		var centre:=at+axis*r*0.6
		draw_arc(centre,r*0.55,axis.angle()+PI-PI*closure,axis.angle()+PI+PI*closure,32,Color(OURS,0.9),2.0,true)
	match String(ours.shape):
		"screen":
			_dashed(PackedVector2Array([at+axis*r*0.02-across*r,at+axis*r*0.02+across*r]),Color(OURS,0.9),1.4,3.0,4.0)
		"strike","ambush":
			for k in 3:
				var from:=at-axis*r*0.1+across*r*(0.9+0.2*k)
				draw_line(from,from.lerp(at+axis*r*0.2,0.6+0.4*wing),Color(OURS,0.9),1.6,true)
		"column","breach","storm","infiltration":
			var count:=3 if String(ours.shape)=="infiltration" else 1
			for k in count:
				var off:=across*r*0.35*float(k-(count-1)/2.0)
				draw_line(at-axis*r*0.5+off,at+axis*r*(0.2+0.4*maxf(0.0,bulge))+off,Color(OURS,0.9),3.0 if count==1 else 1.4,true)
		"pike_square":
			for k in 3:
				var c:=at-axis*r*0.2+across*r*(float(k)-1.0)*0.7
				draw_rect(Rect2(c-Vector2(5,5),Vector2(10,10)),Color(OURS,0.9),false,1.6)
		"reserve":
			var c:=at-axis*r*(0.7-0.5*clampf(float(ours.hardening)*1.5-0.5,0.0,1.0))
			draw_rect(Rect2(c-Vector2(7,4),Vector2(14,8)),Color(OURS,0.85),false,1.6)
	_crossed_strokes(at,6.0,Color(THEIRS,0.95))
	if band in ["local","regional"] and String(clash.get("label",""))!="":
		_caption(at+across*(r+10.0)+Vector2(4,-8),String(clash.label),Color(INK,0.95),font)


func _previous_clash(clash:Dictionary)->Dictionary:
	if blend>=1.0: return {}
	for old in previous.get("clashes",[]):
		if (old.pos as Vector2).distance_to(clash.pos)<0.001: return old.shape_ours
	return {}


## A curved manoeuvre arrow swinging round a flank, growing with progress.
func _hook(start:Vector2,axis:Vector2,side:Vector2,r:float,progress:float,alpha:float)->void:
	var points:=PackedVector2Array()
	var steps:=12
	for k in steps+1:
		var u:=float(k)/float(steps)*clampf(progress,0.0,1.0)
		var angle:=u*PI*0.9
		points.append(start+side*r*0.25*sin(angle)+axis*r*(0.9*(1.0-cos(angle))))
	if points.size()<2: return
	draw_polyline(points,Color(PAPER,0.6),5.0,true)
	draw_polyline(points,Color(OURS,0.9*alpha),2.0,true)
	var tip:=points[-1]; var back:=points[-2]
	var direction:=(tip-back).normalized()
	draw_colored_polygon(PackedVector2Array([tip+direction*6.0,tip+direction.orthogonal()*4.0,tip-direction.orthogonal()*4.0]),Color(OURS,0.9*alpha))


func _draw_zone(zone:Dictionary,font:Font)->void:
	var polygon:=_poly(zone.vertices)
	if polygon.size()<3: return
	var navy:=String(zone.domain)=="navy"
	var own:=SEA if navy else SKY
	var control:=clampf(float(zone.get("control",0.0)),0.0,1.0)
	# Contested water or air: our wash where we hold it, theirs where we do not.
	if Geometry2D.triangulate_polygon(polygon).size()>0:
		draw_colored_polygon(polygon,Color(own,0.06+0.10*control))
		if control<0.95: draw_colored_polygon(polygon,Color(THEIRS,0.05*(1.0-control)))
	var outline:=polygon.duplicate(); outline.append(polygon[0])
	_dashed(outline,Color(own,0.75),1.4,8.0,5.0)
	# Hatching: air superiority and sea control shown as ink hatching whose
	# density follows how firmly it is held.
	if String(zone.get("shape","")) in ["hatch","interception","cordon","cordon_wide","pack","battle_line","convoy"] or not navy:
		var box:=Rect2(polygon[0],Vector2.ZERO)
		for p in polygon: box=box.expand(p)
		var spacing:=lerpf(22.0,9.0,control)
		var lines:=0
		var x:=box.position.x-box.size.y
		while x<box.end.x and lines<60:
			var clipped:=Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([Vector2(x,box.end.y),Vector2(x+box.size.y,box.position.y)]),polygon)
			for piece in clipped: draw_polyline(piece,Color(own,0.35),1.0,true)
			if String(zone.get("shape",""))=="interception" and not navy:
				var cross:=Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([Vector2(x,box.position.y),Vector2(x+box.size.y,box.end.y)]),polygon)
				for piece in cross: draw_polyline(piece,Color(own,0.25),1.0,true)
			x+=spacing; lines+=1
	var centre:=Vector2.ZERO
	for p in polygon: centre+=p
	centre/=float(polygon.size())
	var base:Vector2=zone.get("base",Vector2.INF)
	if base.is_finite() and String(zone.get("shape","")) in ["sortie_arc","bombing_route","support","interdiction","airlift","hatch","interception","watch"]:
		# Sortie arcs from the airfield to the zone.
		var from:=_screen(base)
		if from.is_finite():
			var delta:=centre-from
			var arc:=PackedVector2Array()
			for k in 17:
				var u:=float(k)/16.0
				arc.append(from.lerp(centre,u)+delta.orthogonal().normalized()*sin(u*PI)*minf(60.0,delta.length()*0.2))
			_dashed(arc,Color(own,0.8),1.4,6.0,5.0)
	var port:Vector2=zone.get("port",Vector2.INF)
	if port.is_finite():
		# A blockade cordon across the harbour mouth.
		var at:=_screen(port)
		if at.is_finite():
			var reach:=28.0 if String(zone.get("shape",""))=="cordon" else 52.0
			var facing:=(centre-at).angle()
			draw_arc(at,reach,facing-1.1,facing+1.1,24,Color(PAPER,0.6),5.0,true)
			for k in 9:
				var angle:=facing-1.1+2.2*float(k)/8.0
				draw_circle(at+Vector2.from_angle(angle)*reach,2.4,Color(own,0.95))
			draw_arc(at,reach,facing-1.1,facing+1.1,24,Color(own,0.9),1.4,true)
	for contact in zone.get("contacts",[]):
		var at:=_screen(contact.pos)
		if not at.is_finite(): continue
		var alpha:=clampf(1.0-float(contact.age)/6.0,0.35,1.0)
		draw_arc(at,6.0,0.0,TAU,16,Color(THEIRS,alpha),1.6,true)
	if String(zone.get("label",""))!="": _caption(centre+Vector2(-40,-6),String(zone.label),Color(own.darkened(0.3),0.95),font)


func _caption(at:Vector2,text:String,color:Color,font:Font)->void:
	if text=="" or not Rect2(Vector2.ZERO,size).grow(40).has_point(at): return
	var width:=minf(560.0,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,LABEL_SIZE).x)
	var box:=Rect2(at+Vector2(-4,-14),Vector2(width+10,19))
	draw_rect(box,Color(PAPER,0.82))
	draw_line(box.position+Vector2(0,box.size.y),box.end,Color(color,0.6),1.0)
	draw_string(font,at+Vector2(1,0),text,HORIZONTAL_ALIGNMENT_LEFT,width,LABEL_SIZE,color)
