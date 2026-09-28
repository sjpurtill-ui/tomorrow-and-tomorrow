extends Control
## WAR AS AN INKED CHART: living front lines, the generals' arrows and
## objectives, clashes and the shape of the tactic being fought, pockets,
## fallback lines from the generals' own withdrawal plans, siege works, raid
## tracks, corps and army-group marks at continental scale, and the fleets'
## and air arms' drawn zones (with blockade cordons, convoy lanes and
## air-defence belts).
##
## Observation and conversation only. A click on a front, an arrow, a clash,
## a zone, a lane or a formation mark opens a small note about it with one
## way to talk to the general or branch commander who runs it. Nothing is
## ordered from this layer; tactics are the commanders' own.
##
## Pipeline: collect() reads the ledgers (bounded, dated, honest) into plain
## inputs; compose() (pure, static) turns them into world-space primitives
## via war_front_model.gd and battle_tactics.gd; the motion state eases the
## drawn fronts toward each new composition; _draw() projects, drapes and
## inks them, and letters the captions around what the chart already shows
## (city_labels.gd placement). Inputs are re-read at most every
## COLLECT_EVERY seconds and only rebuilt when they changed; drawing happens
## only when the camera, the scene or the easing moves.
##
## Battles (hud/battle_marks.gd, from hud/battle_marker_source.gd): every
## fight going on now stands on the front at its contact point as a small
## crossed-weapons mark with a two-colour bar and its name and day; a
## pointer resting on it gets one plain line, a click opens the battle view.
## The stretch of front being fought over thickens and works (the worm),
## and when a battle is won or lost or a town changes hands the front surges
## there and settles where control now lies. Forces carry HOI4-style
## counters (strength, will to fight, one state glyph); far out, forces
## stand together per front sector and battles per place. The moving parts
## (the worm working, the battles' pulse) are drawn on one small child
## canvas behind this one, redrawn a few times a second only while battles
## are on screen.

const Model:=preload("res://scripts/war_front_model.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const BattleSource:=preload("res://scripts/hud/battle_marker_source.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Marks:=preload("res://scripts/war_map_marks.gd")
const Presentation:=preload("res://scripts/warfare_map_presentation.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const CityLabels:=preload("res://scripts/hud/city_labels.gd")
const Blockade:=preload("res://scripts/naval_blockade.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")

const COLLECT_EVERY:=0.5
## Clash shapes and arrows blend over this long after a change.
const MORPH_SECONDS:=0.9
## The fronts chase their newest derivation with this time constant: control
## shifting over days reads as a line that eases, never one that jumps.
const EASE_SECONDS:=0.5
## While only the easing moves, the chart is redrawn at most this often.
const EASE_REDRAW_SECONDS:=1.0/30.0
## A new clash rings once, briefly, like ink dropped on the chart (codex/map-motion).
const CLASH_PULSE_SECONDS:=1.3
const MAX_CLASH_PULSES:=6
## Every drawn front is carried on this many points, so any two can morph.
const FRONT_POINTS:=96
## Arrows are carried on this many points, so each eases as its army moves.
const ARROW_POINTS:=21
## A new arrow draws itself out this long; a finished one fades this long.
const ARROW_GROW_SECONDS:=0.7
const ARROW_FADE_SECONDS:=1.4
## A front giving way surges and settles over this long, this far (a share
## of the theatre's scale) and this wide.
const BULGE_SECONDS:=1.8
const BULGE_AMP_SIGMA:=0.35
const BULGE_RADIUS_SIGMA:=0.9
const MAX_BULGES:=8
## The fighting's own motion (the worm working, the battles' pulse).
const PULSE_FPS:=24.0
const PULSE_PERIOD:=2.6
## Far out, forces stand together per stretch of front this long on screen
## (as a province's stack of counters does); up close each stands alone.
const SECTOR_PX:={"regional":96.0,"continental":150.0}
const CAPTION_SIZE:=14
## The detail line of a force's card (the art direction's 12 px floor).
const CARD_DETAIL_SIZE:=12
const MAX_ECHELONS:=12
const MAX_LANES:=8
## Army-tree levels (command_hierarchy.gd LEVELS.army): 7 corps, 8 army.
const CORPS_LEVEL:=7

## One ink family; owner colour only as a thin accent.
const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
const OURS:=Color("#2f5d6b")
const OURS_WASH:=Color("#4f9bb8")
const THEIRS:=Color("#8e3b2e")
const THEIRS_WASH:=Color("#b5503c")
## Fleet ink reads on dark water; the air arm's is a cool slate that the
## olive and ochre ground never matches.
const SEA:=Color("#16475a")
const SEA_LIGHT:=Color("#cfe3e0")
const SKY:=Color("#3b4a78")

var terrain:Node
## Injected by tests and the capture scene: func(Vector2 world)->Vector2 screen.
var project:Callable
## Injected zoom band (tests/captures); otherwise from the camera.
var band_override:=""
## TEST HOOK (captures and tests only): extra inputs merged into collect():
## arrays are appended, other values replace.
var extra_inputs:Dictionary={}
var scene:Dictionary={}
var previous:Dictionary={}
var blend:=1.0
var inputs_signature:=0
var drawn_signature:=0
var collect_elapsed:=COLLECT_EVERY
var height_cache:Dictionary={}
## Motion: the fronts as drawn, easing toward the scene's fronts.
## [{points, target, alpha, target_alpha, data, centre}]
var live_fronts:Array=[]
## Pocket closure as drawn, keyed by the front it belongs to.
var live_closure:Dictionary={}
var settling:=false
## What the camera shows, for caching drawn geometry between redraws.
var view_key:=0
var zone_cache:Dictionary={}
var ease_elapsed:=0.0
var ease_frame:=0
## Screen hit shapes of the last drawing, for clicks.
var hits:Array=[]
## The force marks as last drawn (screen), for clicks and caption clearance.
var drawn_marks:Array=[]
## Captions requested by the last drawing, and their placement memory.
var caption_requests:Array=[]
var caption_memory:Dictionary={}
var caption_extent:Dictionary={}
var placed_captions:Array=[]
var dropped_captions:=0
## Per-army withdrawal routes, cached by where the army stands.
var withdrawal_cache:Dictionary={}
## The open note, and what it is about.
var note_layer:CanvasLayer
var note:PanelContainer
var note_about:Dictionary={}
## Probe counters (never saved).
var composes:=0
var redraws:=0
var last_compose_usec:=0
var last_draw_usec:=0
## Newly joined battles: [{pos, t}] (bounded, visual only).
var clash_pulses:Array[Dictionary]=[]
## Arrows as drawn, keyed by what they belong to: {points (world), target,
## grow 0..1, alpha, target_alpha, data}. New ones draw out; gone ones fade.
var live_arrows:Dictionary={}
## Fronts giving way: [{pos, dir, amp, radius, t, dur}] (visual only).
var bulges:Array=[]
## Rival battles as our watchers last saw them (never saved).
var rival_memory:Dictionary={}
## The fighting as last drawn, for the pulse canvas: hot stretches of front
## [{points, normals, heat, peak}] and battles [{at, radius, live, phase}].
var hot_cache:Array=[]
var battle_cache:Array=[]
var anim_clock:=0.0
var pulse_elapsed:=0.0
var pulse_layer:Control
## The one line shown while the pointer rests on a battle.
var tip:PanelContainer
var hover_id:=""
## TEST HOOK: when set, a click on one of our battles calls this with the
## view request ({method, args} or {siege}) instead of opening it.
var battle_opener:Callable


## The moving parts of the fighting, drawn behind the chart's own ink.
class PulseLayer extends Control:
	var host:Control
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		show_behind_parent=true
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	func _draw()->void:
		if host!=null and is_instance_valid(host): host.draw_animated(self)


func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pulse_layer=PulseLayer.new()
	pulse_layer.name="BattlePulse"
	pulse_layer.host=self
	add_child(pulse_layer)


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
	settling=ease_fronts(delta)
	var arrows_moving:=ease_arrows(delta)
	var surging:=advance_bulges(delta)
	var view:Array=[inputs_signature,size,blend,settling]
	if not clash_pulses.is_empty():
		var live:Array[Dictionary]=[]
		for pulse in clash_pulses:
			pulse["t"]=float(pulse.t)+delta
			if float(pulse.t)<CLASH_PULSE_SECONDS:live.append(pulse)
		clash_pulses=live
		view.append(roundi(Time.get_ticks_msec()/33.0))
	if settling or arrows_moving or surging:
		ease_elapsed+=delta
		if ease_elapsed>=EASE_REDRAW_SECONDS: ease_elapsed=0.0; ease_frame+=1
		view.append(ease_frame)
	# The fighting works on its own small canvas, only while it is on screen.
	anim_clock+=delta
	if pulse_layer!=null and (not hot_cache.is_empty() or not battle_cache.is_empty()) and not Motion.reduced():
		pulse_elapsed+=delta
		if pulse_elapsed>=1.0/PULSE_FPS:
			pulse_elapsed=0.0
			pulse_layer.queue_redraw()
	var camera:=_camera()
	if camera!=null: view.append_array([camera.global_transform,camera.size])
	var cities:=_city_labels()
	if cities!=null: view.append(cities.get("layout_signature"))
	var signature:=hash(view)
	if signature==drawn_signature: return
	drawn_signature=signature
	redraws+=1
	queue_redraw()


func set_scene(next:Dictionary,immediate:bool=false)->void:
	var start:=Time.get_ticks_usec()
	if not immediate and not scene.is_empty():
		_note_new_clashes(scene,next)
		_note_front_events(scene,next)
	previous=scene if not immediate else {}
	scene=next
	blend=1.0 if immediate or previous.is_empty() else 0.0
	retarget_fronts(scene.get("fronts",[]),immediate)
	retarget_arrows(scene.get("arrows",[]),immediate)
	if immediate: bulges.clear()
	composes+=1
	last_compose_usec=Time.get_ticks_usec()-start
	queue_redraw()


# --- Motion -------------------------------------------------------------------

static func _centre(points:PackedVector2Array)->Vector2:
	var total:=Vector2.ZERO
	for p in points: total+=p
	return total/float(maxi(1,points.size()))


## New fronts are matched to the drawn ones by where they lie; a matched
## front eases from its drawn line to the new one, a new front unrolls from
## its middle, and a front that is gone fades where it was.
func retarget_fronts(fronts:Array,immediate:bool=false)->void:
	var sigma:=maxf(0.001,float(scene.get("sigma",1.0)))
	var claimed:Dictionary={}
	var next_live:Array=[]
	for front in fronts:
		var target:=Model.resample(front.points,FRONT_POINTS)
		var centre:=_centre(target)
		var best:=-1
		var best_distance:=sigma*2.5
		for index in live_fronts.size():
			if claimed.has(index) or float(live_fronts[index].target_alpha)<=0.0: continue
			var d:=(live_fronts[index].centre as Vector2).distance_to(centre)
			if d<best_distance: best_distance=d; best=index
		var entry:Dictionary
		if best>=0:
			claimed[best]=true
			entry=live_fronts[best]
			var drawn:PackedVector2Array=entry.points
			# Keep the two lines running the same way round.
			if drawn[0].distance_squared_to(target[0])+drawn[-1].distance_squared_to(target[-1])>drawn[0].distance_squared_to(target[-1])+drawn[-1].distance_squared_to(target[0]):
				drawn.reverse(); entry.points=drawn
		else:
			var middle:=target[FRONT_POINTS/2]
			var start:=PackedVector2Array()
			for k in FRONT_POINTS: start.append(middle)
			entry={"points":start,"alpha":0.0}
		entry.target=target
		entry.target_alpha=1.0
		entry.centre=centre
		entry.data=front
		if immediate: entry.points=target.duplicate(); entry.alpha=1.0
		next_live.append(entry)
	for index in live_fronts.size():
		if claimed.has(index): continue
		var gone:Dictionary=live_fronts[index]
		gone.target_alpha=0.0
		if immediate: continue
		next_live.append(gone)
	live_fronts=next_live
	settling=true


## One easing step. Returns true while anything is still moving.
func ease_fronts(delta:float)->bool:
	if live_fronts.is_empty() and live_closure.is_empty(): return false
	var k:=1.0-exp(-maxf(0.0,delta)/EASE_SECONDS)
	var sigma:=maxf(0.001,float(scene.get("sigma",1.0)))
	var moving:=false
	var kept:Array=[]
	for entry in live_fronts:
		var points:PackedVector2Array=entry.points
		var target:PackedVector2Array=entry.target
		var worst:=0.0
		for i in points.size():
			var step:=(target[i]-points[i])*k
			worst=maxf(worst,step.length())
			points[i]+=step
		entry.points=points
		entry.alpha=lerpf(float(entry.alpha),float(entry.target_alpha),k)
		if worst<sigma*0.0015 and absf(float(entry.alpha)-float(entry.target_alpha))<0.01:
			entry.points=target.duplicate(); entry.alpha=float(entry.target_alpha)
		else: moving=true
		if float(entry.target_alpha)>0.0 or float(entry.alpha)>0.01: kept.append(entry)
	live_fronts=kept
	for pocket in scene.get("pockets",[]):
		var key:=int(pocket.front)
		var goal:=float(pocket.closure)
		var now:=float(live_closure.get(key,0.0))
		now=lerpf(now,goal,k)
		if absf(now-goal)<0.002: now=goal
		else: moving=true
		live_closure[key]=now
	return moving


## New arrows are matched to the drawn ones by what they belong to (an
## army's march, its chase, its siege, a host seen marching): a matched
## arrow eases to its new road, a new one draws itself out from its tail,
## and one whose work is done fades where it was.
func retarget_arrows(arrows:Array,immediate:bool=false)->void:
	var keep:Dictionary={}
	var still:=immediate or Motion.reduced()
	for arrow_variant in arrows:
		var arrow:Dictionary=arrow_variant
		var id:=String(arrow.get("id",""))
		if id=="": id="arrow:%d" % keep.size()
		if keep.has(id): continue
		var target:=Model.resample(arrow.get("points",PackedVector2Array()),ARROW_POINTS)
		if target.size()<3: continue
		keep[id]=true
		var entry:Dictionary=live_arrows.get(id,{})
		if entry.is_empty():
			entry={"points":target.duplicate(),"grow":1.0 if still else 0.0,"alpha":1.0}
			live_arrows[id]=entry
		entry["target"]=target
		entry["data"]=arrow
		entry["target_alpha"]=1.0
		if still: entry.points=target.duplicate(); entry.grow=1.0; entry.alpha=1.0
	for id in live_arrows.keys():
		if keep.has(id): continue
		if still: live_arrows.erase(id)
		else: live_arrows[id]["target_alpha"]=0.0


## One arrow step. Returns true while any arrow still grows, fades or moves.
func ease_arrows(delta:float)->bool:
	if live_arrows.is_empty(): return false
	var moving:=false
	var k:=1.0-exp(-maxf(0.0,delta)/EASE_SECONDS)
	var sigma:=maxf(0.001,float(scene.get("sigma",1.0)))
	for id in live_arrows.keys():
		var entry:Dictionary=live_arrows[id]
		if float(entry.grow)<1.0:
			entry.grow=minf(1.0,float(entry.grow)+maxf(0.0,delta)/ARROW_GROW_SECONDS); moving=true
		var goal:=float(entry.get("target_alpha",1.0))
		if not is_equal_approx(float(entry.alpha),goal):
			entry.alpha=move_toward(float(entry.alpha),goal,maxf(0.0,delta)/ARROW_FADE_SECONDS); moving=true
		if goal<=0.0 and float(entry.alpha)<=0.0:
			live_arrows.erase(id); continue
		var points:PackedVector2Array=entry.points
		var target:PackedVector2Array=entry.target
		if points.size()!=target.size(): entry.points=target.duplicate(); continue
		var worst:=0.0
		for i in points.size():
			var step:=(target[i]-points[i])*k
			worst=maxf(worst,step.length())
			points[i]+=step
		entry.points=points
		if worst>=sigma*0.0015: moving=true
	return moving


## One surge step. Returns true while any front is still giving way.
func advance_bulges(delta:float)->bool:
	if bulges.is_empty(): return false
	var running:Array=[]
	for bulge in bulges:
		bulge["t"]=float(bulge.t)+maxf(0.0,delta)
		if float(bulge.t)<float(bulge.dur): running.append(bulge)
	bulges=running
	return not bulges.is_empty()


## A front point as drawn: where it has eased to, plus any surge running.
func _bulged(points:PackedVector2Array)->PackedVector2Array:
	if bulges.is_empty(): return points
	var out:=points.duplicate()
	for i in out.size(): out[i]+=Model.bulge_offset(out[i],bulges)
	return out


## When a battle of ours ends, or a town we hold is taken or lost, the front
## surges there: forward (toward them) when we won or took it, back when we
## lost it. Only near a drawn front, and never with reduced motion.
func _note_front_events(before:Dictionary,after:Dictionary)->void:
	if Motion.reduced(): return
	var sigma:=maxf(0.001,float(after.get("sigma",1.0)))
	var lines:Array=(after.get("fronts",[]) as Array)+(after.get("faceoffs",[]) as Array)
	if lines.is_empty(): return
	var events:Array=[]
	var ended_before:Dictionary={}
	for clash in before.get("clashes",[]):
		if bool(clash.get("finished",false)): ended_before[int(clash.get("seed",0))]=true
	for clash in after.get("clashes",[]):
		if not bool(clash.get("finished",false)) or ended_before.has(int(clash.get("seed",0))) or int(clash.get("age",0))>1: continue
		if bool(clash.get("won",false)): events.append({"pos":clash.pos,"forward":true})
		elif bool(clash.get("lost",false)): events.append({"pos":clash.pos,"forward":false})
	var held_before:Dictionary={}; var held_after:Dictionary={}
	for mark in before.get("marks",[]):
		if bool(mark.get("garrison",false)): held_before[String(mark.id)]=mark.pos
	for mark in after.get("marks",[]):
		if bool(mark.get("garrison",false)): held_after[String(mark.id)]=mark.pos
	for id in held_after:
		if not held_before.has(id): events.append({"pos":held_after[id],"forward":true})
	for id in held_before:
		if not held_after.has(id): events.append({"pos":held_before[id],"forward":false})
	for event in events.slice(0,MAX_BULGES):
		var at:=Model.front_at(lines,event.pos,sigma*1.6)
		if at.is_empty(): continue
		var toward:Vector2=at.toward
		if toward.length_squared()<0.000001: continue
		bulges.append({"pos":at.point,"dir":(toward if bool(event.forward) else -toward).normalized(),"amp":sigma*BULGE_AMP_SIGMA,"radius":sigma*BULGE_RADIUS_SIGMA,"t":0.0,"dur":BULGE_SECONDS})
	while bulges.size()>MAX_BULGES: bulges.pop_front()


# --- Reading the world (bounded, dated) -----------------------------------------

func _camera()->Camera3D:
	if not is_instance_valid(terrain): return null
	# The terrain may outlive its camera (teardown, tests); never test a freed one.
	var camera:Variant=terrain.get("camera")
	return camera if is_instance_valid(camera) and camera is Camera3D else null


func _city_labels()->Control:
	var cities:Variant=terrain.get("city_labels") if is_instance_valid(terrain) else null
	return cities as Control if cities is Control and is_instance_valid(cities) else null


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
	var campaign_army:=int(GeneralCampaign.state.get("army_id",-1)) if GeneralCampaign.active else -1
	var selected:=int(terrain.get("selected_army_id")) if is_instance_valid(terrain) and terrain.get("selected_army_id")!=null else -1
	for army_variant in snapshot.get("armies",[]):
		var army:Dictionary=army_variant
		var troops:=int(army.get("troops",0))
		if troops<=0: continue
		var at_home:=ArmyMarks.at_home(army,home)
		var shown:=army
		# A band at a town we hold, or a detachment out of its garrison, is
		# known: the garrison is ours and word comes in every day.
		var near_hold:=army.get("pursuit") is Dictionary or (String(army.get("status",""))=="stationed" and not MilitaryCampaign.occupation_force_for_region(_region_civ(String(army.get("location_id",""))),String(army.get("location_id",""))).is_empty())
		# Before signals the map knows only what the last runner reported.
		if not live and not at_home and not near_hold:
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
		var id:=int(army.get("army_id",0))
		var strength:=int(shown.get("troops",troops))
		largest=maxi(largest,strength); theatre+=strength
		var entry:={"id":str(id),"army_id":id,"pos":pos,"strength":float(strength),"objective":objective,"offensive":offensive,"name":String(army.get("name","")),
			"report_age":0 if live or at_home or near_hold else maxi(0,today-int(shown.get("day",today))),"campaign":id==campaign_army}
		# The general's chosen land road (round bays and inlets), not a straight line.
		if objective.is_finite() and String(shown.get("status",army.get("status","")))=="moving":
			var road:=_road_ahead(army,pos)
			if road.size()>=2: entry["road"]=road
			var days_left:=int(army.get("arrival_day",-1))-today
			if days_left>0: entry["days_left"]=days_left
		if not at_home: entry.merge(_withdrawal(army,pos,home,id==campaign_army))
		if bool(entry.get("withdrawing",false)): entry.offensive=false
		# What its mark and card need: its arm, its era, its general, what it is doing.
		var role:=Presentation.formation_role(army)
		var condition:=String(Presentation.formation_visual_state(army).damage_state)
		var morale:=clampf(float(shown.get("morale",army.get("morale",0.6))),0.0,1.0)
		entry.merge({"era":Presentation.formation_era(army),"branch":ArmyMarks.branch(role,Presentation.dominant_unit(army) if not (army.get("formations",[]) as Array).is_empty() else ""),
			"general":String((army.get("commander",{}) as Dictionary).get("name","")),"selected":id==selected,"condition":condition,
			"full":ArmyMarks.full_strength(army),"morale":morale,
			"doing_context":{"status":String(shown.get("status",army.get("status",""))),"destination_name":String(army.get("destination_name","")),"destination_id":String(army.get("destination_id","")),
				"location_name":String(army.get("location_name","")),"command_status":String(army.get("command_status","")),"at_home":at_home,
				"home_km":ArmyMarks.home_km(shown if shown.has("position") else army,home),
				"delta":(objective-pos) if objective.is_finite() else Vector2.ZERO,"days_left":int(entry.get("days_left",0)),"pursuit":Pursuit.doing_words(army),
				"hungry":preload("res://scripts/field_rations.gd").is_hungry(army),"broken":morale<ArmyMarks.BROKEN_MORALE or condition=="shattered"}})
		if army.get("pursuit") is Dictionary:
			entry["detachment_of"]=String((army.pursuit as Dictionary).get("town",""))
			entry["chasing"]=String((army.pursuit as Dictionary).get("state",""))=="chasing"
		friendly.append(entry)
	var enemy:Array=[]
	# Strangers in sight who are not at war with us (scouts, passing hosts):
	# marked only while seen, never from memory.
	var strangers:Array=[]
	var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
	var listed:Dictionary={}
	for list_name in ["visible","recent"]:
		for sighting_variant in observation.get(list_name,[]):
			var sighting:Dictionary=sighting_variant
			var sighting_id:=String(sighting.get("id",""))
			if listed.has(sighting_id): continue
			var low:=int(sighting.get("strength_estimate_low",0)); var high:=maxi(low,int(sighting.get("strength_estimate_high",low)))
			var seen:=int(sighting.get("last_seen_day",sighting.get("observed_day",today)))
			var pos:=_v2(sighting.get("position",{}))
			if not pos.is_finite(): continue
			var identified:=bool(sighting.get("identified",false))
			var entry:={"id":sighting_id,"pos":pos,"strength":float(low+high)*0.5,"low":low,"high":high,"age_days":maxi(0,today-seen),"moving":bool(sighting.get("moving",false)),"heading":float(sighting.get("heading",0.0)),"seen_day":seen,
				"observed":list_name=="visible","owner":String(sighting.get("civilization","")) if identified else "","era":clampi(int(sighting.get("formation_era",0)),0,3) if identified else 0,
				"branch":ArmyMarks.branch(String(sighting.get("formation_role","")),String(sighting.get("formation_unit",""))) if identified else "foot","scout":bool(sighting.get("carries_report",false)),"road":_road_of(sighting.get("road_ahead",[])),
				"will_low":float(sighting.get("readiness_estimate_low",-1.0)) if identified else -1.0,"will_high":float(sighting.get("readiness_estimate_high",-1.0)) if identified else -1.0}
			var hostile:=bool(sighting.get("hostile",false)) and not bool(entry.scout)
			if hostile: enemy.append(entry); listed[sighting_id]=true
			elif list_name=="visible": strangers.append(entry); listed[sighting_id]=true
	enemy.append_array(_campaign_sightings(today))
	var engagements:Array=[]
	# Every battle of ours being fought now: the watched one, the battle
	# model's registry and the command staff's parallel battles, each once.
	for entry in BattleSource.engagements_of(MilitaryCampaign):
		if engagements.size()>=Model.MAX_CLASHES: break
		var input:=_engagement_input(entry.engagement,friendly,enemy,home)
		input["battle_id"]=String(entry.id)
		engagements.append(input)
	# Fights of the last days stay on the chart where they were fought, with
	# how they went; a click reads the report or watches it again.
	for record in recent_battles(MilitaryCampaign.battle_history,today):
		if engagements.size()>=Model.MAX_CLASHES: break
		engagements.append(_finished_input(record,friendly,enemy,home,today))
	var sieges:Array=[]
	var siege:Dictionary=MilitaryCampaign.active_siege
	if not siege.is_empty():
		var offensive:=String(siege.get("mode",""))=="offensive"
		var works:="circumvallation" if (known.has("field_fortifications") or known.has("siege_engineering")) and offensive else ("circumvallation" if not offensive and float((siege.get("threat",{}) as Dictionary).get("technology",0.0))>=0.45 else "blockade_camp")
		sieges.append({"pos":_v2(siege.get("target_position",{})) if offensive else home,"pressure":float(siege.get("pressure",0.0)),"works":works,"ours":offensive,"days":int(siege.get("days",0)),"army_id":int(siege.get("army_id",0))})
	var raids:=_raid_inputs(today,home)
	var garrisons:=_garrison_inputs()
	var battles:=BattleSource.collect(MilitaryCampaign,_rival_militaries(),_battle_context(today,home,friendly,garrisons),rival_memory)
	var inputs:={"garrisons":garrisons,"stage":stage,"today":today,"home":home,"mode":Model.mode(stage,known,largest,friendly.size(),theatre),
		"corps_known":known.has("professional_corps") or known.has("military_staffs"),"staffs_known":known.has("military_staffs"),"strangers":strangers,
		"friendly":friendly,"enemy":enemy,"engagements":engagements,"sieges":sieges,"raids":raids,"zones":_zone_inputs(today),
		"lanes":_lane_inputs(today),"echelons":_echelon_inputs(friendly),"harbours":_our_blockaded_ports(today),"battles":battles}
	for key in extra_inputs:
		var value:Variant=extra_inputs[key]
		inputs[key]=(inputs.get(key,[]) as Array)+(value as Array) if value is Array and inputs.get(key) is Array else value
	return inputs


## The rival peoples' campaigns (each owner's own MilitaryCampaign), read
## directly: the battle source keeps only what our watchers can see.
static func _rival_militaries()->Dictionary:
	var out:Dictionary={}
	if not WorldSimulation.enabled: return out
	for id in WorldSimulation.actors:
		var systems:Variant=(WorldSimulation.actors[id] as Dictionary).get("systems",{})
		var military:Variant=(systems as Dictionary).get("MilitaryCampaign") if systems is Dictionary else null
		if military!=null and is_instance_valid(military): out[String(id)]=military
	return out


## What the battle source needs to know of our side of the map: where our
## armies and held towns stand (our watchers too), the towns we know by
## name, and which peoples we know well enough to name and colour.
func _battle_context(today:int,home:Vector2,friendly:Array,garrisons:Array)->Dictionary:
	var armies:Dictionary={}; var troops:Dictionary={}
	for army in MilitaryCampaign.field_armies:
		var count:=int((army as Dictionary).get("troops",0))
		if count<=0: continue
		var at:=_v2(army.get("position",{}))
		if at.is_finite(): armies[int(army.get("army_id",0))]=at; troops[int(army.get("army_id",0))]=count
	var towns:Dictionary={}
	for g in garrisons: towns[String(g.region_id)]=g.pos
	var cities:Array=[]
	var civ_names:Dictionary={}
	var at_war:Dictionary={}
	if CivilizationSystem!=null and CivilizationSystem.city_intelligence!=null:
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false,home,1200.0):
			cities.append({"id":String(city.get("city_id",city.get("id",""))),"name":String(city.get("name","")),"pos":_v2(city.get("position",{})),"civ_id":String(city.get("civ_id",""))})
			if cities.size()>=48: break
		for civ:Dictionary in CivilizationSystem.civilizations:
			var relation:Dictionary=civ.get("player_relation",{})
			if int(relation.get("contact_level",0))>=2: civ_names[String(civ.id)]=String(civ.get("name",""))
			at_war[String(civ.id)]=bool(relation.get("at_war",false))
	var observers:={"home":home,"radius":float(CivilizationSystem._local_observation_radius()) if CivilizationSystem.has_method("_local_observation_radius") else BattleSource.HOME_SIGHT_KM,
		"armies":armies.values(),"garrisons":towns.values()}
	return {"today":today,"home":home,"armies":armies,"armies_troops":troops,"towns":towns,"cities":cities,"civ_names":civ_names,"at_war_with":at_war,"observers":observers,
		"identity":func(civ_id:String)->Color: return preload("res://scripts/city_map_identity.gd").foreign(civ_id).accent,
		"player_name":String(CivilizationSystem._player_civilization_name()) if CivilizationSystem.has_method("_player_civilization_name") else "","home_name":String(GameState.settlement_name)}


## Towns we hold, and who holds them: a small mark on the town with a card
## ("Held by us · 17").
static func _region_civ(region_id:String)->String:
	## Whose town a region is, for a force stationed there ("" when none).
	if region_id=="" or region_id=="player_home" or MilitaryCampaign==null: return ""
	for f in MilitaryCampaign.occupation_forces:
		if String((f as Dictionary).get("region_id",""))==region_id: return String(f.get("civ_id",""))
	return ""


static func _garrison_inputs()->Array:
	var out:Array=[]
	var mc:Variant=WorldSimulation.military
	var world:Variant=WorldSimulation.world
	if mc==null or world==null: return out
	for f in mc.occupation_forces:
		var force:Dictionary=f
		var troops:=int(force.get("troops",0))
		if troops<=0: continue
		var rid:=String(force.get("region_id",""))
		# On the town as our chart draws it (its label, and where our bands
		# marched), not at a point the chart does not show.
		var pos:=Pursuit.town_position(rid) if world.city_intelligence!=null else Vector2.INF
		if not pos.is_finite(): continue
		out.append({"region_id":rid,"pos":pos,"troops":troops,"town":String(force.get("region_name","")),"general":String((force.get("commander",{}) as Dictionary).get("name","")),
			"fate_note":String(force.get("fate_note","")),"away":Pursuit.away_from(rid),
			"required":ceili(float(force.get("required",0.0))),"morale":clampf(float(force.get("morale",0.6)),0.0,1.0),"hungry":preload("res://scripts/field_rations.gd").is_hungry(force)})
		if out.size()>=6: break
	return out


## The battles on the map: the one being watched, and the command
## hierarchy's own battles fought at the same time (bounded, each once).
static func battles_to_draw(active:Dictionary,commanded:Array)->Array:
	var out:Array=[]
	var seen:Dictionary={}
	for battle in [active]+commanded:
		if not battle is Dictionary or (battle as Dictionary).is_empty(): continue
		var key:=str(battle.get("seed",""))+":"+str(battle.get("home_force_id",""))
		if seen.has(key): continue
		seen[key]=true
		out.append(battle)
		if out.size()>=Model.MAX_CLASHES: break
	return out


## The land road still ahead of a marching army, from where it was last
## known: its march_route legs (military_campaign.gd) after the leg it is on.
static func _road_ahead(army:Dictionary,pos:Vector2)->PackedVector2Array:
	var legs:Array=army.get("march_route",[]) if army.get("march_route") is Array else []
	if legs.is_empty(): return PackedVector2Array()
	var origin:=_v2(army.get("origin_position",{}))
	var points:=PackedVector2Array([origin if origin.is_finite() else pos])
	for leg in legs: points.append(_v2(leg))
	var best:=0; var best_d:=INF
	for k in points.size()-1:
		var d:=pos.distance_to(Geometry2D.get_closest_point_to_segment(pos,points[k],points[k+1]))
		if d<best_d: best_d=d; best=k
	var road:=PackedVector2Array([pos])
	for k in range(best+1,points.size()): road.append(points[k])
	return road

static func _road_of(points:Variant)->PackedVector2Array:
	var out:=PackedVector2Array()
	if points is Array:
		for p in (points as Array).slice(0,12): out.append(_v2(p))
	return out

static func _length(line:PackedVector2Array)->float:
	var total:=0.0
	for k in line.size()-1: total+=line[k].distance_to(line[k+1])
	return total

## The road from `start`, no longer than `reach`.
static func _clip(line:PackedVector2Array,start:Vector2,reach:float)->PackedVector2Array:
	if line.size()<2: return PackedVector2Array()
	var out:=PackedVector2Array([start])
	var left:=reach
	for k in range(1,line.size()):
		var d:=out[-1].distance_to(line[k])
		if d>=left: out.append(out[-1].move_toward(line[k],left)); break
		out.append(line[k]); left-=d
	return out

## A polyline resampled to n+1 evenly spaced points (bounded), so the plan
## arrow's tapered body follows the road and its head sits on the goal.
static func _resample(line:PackedVector2Array,n:int)->PackedVector2Array:
	var out:=PackedVector2Array()
	if line.size()<2: return out
	var total:=0.0
	for k in line.size()-1: total+=line[k].distance_to(line[k+1])
	if total<=0.0: return out
	var seg:=0; var into:=0.0
	for i in n+1:
		var want:=total*float(i)/float(n)
		var walked:=0.0
		seg=0
		while seg<line.size()-2 and walked+line[seg].distance_to(line[seg+1])<want:
			walked+=line[seg].distance_to(line[seg+1]); seg+=1
		into=want-walked
		out.append(line[seg].move_toward(line[seg+1],into))
	return out

## The general's withdrawal intent: where he would fall back to, one day's
## march along the road he would take. Campaign generals use the board's road
## home; commanded armies their commanded route when already withdrawing, or
## the land route home; any other army the road home, as the engine retreats.
func _withdrawal(army:Dictionary,pos:Vector2,home:Vector2,campaign:bool)->Dictionary:
	var status:=String(army.get("command_status",""))
	var withdrawing:="withdraw" in status.to_lower()
	var route:=PackedVector2Array()
	var how:="home"
	if campaign and GeneralCampaign.active:
		var cell:Vector2i=GeneralCampaign.state.get("cell",Vector2i.ZERO)
		for c in GeneralCampaign.route(cell,Vector2i.ZERO): route.append(GeneralCampaign.world_position(c))
		how="road"
		withdrawing=withdrawing or String((GeneralCampaign.state.get("mission",{}) as Dictionary).get("action","")) in ["withdraw","recover"]
	elif withdrawing and not (army.get("command_route",[]) as Array).is_empty():
		for waypoint in army.command_route: route.append(_v2(waypoint))
		how="road"
	else:
		var command:Variant=MilitaryCampaign.get("command_hierarchy")
		if command!=null and command.controls_army(int(army.get("army_id",0))):
			var key:="%d:%s" % [int(army.get("army_id",0)),str(pos.snapped(Vector2.ONE*0.5))]
			if not withdrawal_cache.has(key):
				if withdrawal_cache.size()>64: withdrawal_cache.clear()
				var path:=PackedVector2Array()
				for waypoint in command.land.route(pos,home): path.append(_v2(waypoint))
				withdrawal_cache[key]=path
			route=withdrawal_cache[key]
			if not route.is_empty(): how="road"
	if route.is_empty(): route=PackedVector2Array([home])
	var day_march:=clampf(float(MilitaryCampaign._field_army_speed(army)) if MilitaryCampaign.has_method("_field_army_speed") else 12.0,1.0,60.0)
	var depth:=minf(day_march,pos.distance_to(home)*0.5)
	var troops:=int(army.get("troops",0))
	return {"fallback":Model.withdrawal_point(pos,route,depth),"withdrawing":withdrawing,"fallback_how":how,"route_home":route.slice(0,24),
		"frontage":clampf(sqrt(maxf(0,troops))*0.085,0.12,10.0),"day_march":day_march}


## The Alderford war's rival hosts, as the general last saw them (dated).
func _campaign_sightings(today:int)->Array:
	var out:Array=[]
	if not GeneralCampaign.active: return out
	var seen:Dictionary=GeneralCampaign.state.get("seen",{})
	for id in seen:
		var s:Dictionary=seen[id]
		if not s.get("cell") is Vector2i: continue
		var troops:=int(s.get("troops",0))
		if troops<=0: continue
		out.append({"id":"campaign:"+String(id),"pos":GeneralCampaign.world_position(s.cell),"strength":float(troops),"low":troops,"high":troops,"age_days":maxi(0,today-int(s.get("day",today))),"moving":false,"heading":0.0,"seen_day":int(s.get("day",today)),"name":String(s.get("name","")),"marked":true})
	return out


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
		"rounds":int(engagement.get("round",0)),"phase_ours":String(last.get(home_side+"_tactic_phase","hold")),"phase_theirs":String(last.get(enemy_side+"_tactic_phase","hold")),"event":String(last.get("tactic_event","")),
		"army_id":int(force_id),"commanded":bool(engagement.get("commander_managed",false)),"objective":String(engagement.get("command_objective","")),
		"our_troops":_side_troops(engagement.get(home_side,{})),"their_troops":_side_troops(engagement.get(enemy_side,{})),"seed":int(engagement.get("seed",0))}


static func _side_troops(side:Variant)->int:
	if not side is Dictionary: return 0
	return int((side as Dictionary).get("troops",(side as Dictionary).get("initial_troops",0)))


## Our finished fights from the last RECENT_BATTLE_DAYS, newest first.
const RECENT_BATTLE_DAYS:=12
static func recent_battles(history:Array,today:int)->Array:
	var out:Array=[]
	for record_variant in history:
		if not record_variant is Dictionary: continue
		var record:Dictionary=record_variant
		if today-int(record.get("day",-9999))>RECENT_BATTLE_DAYS: continue
		if String(record.get("home_force_kind",""))=="occupation" and (record.get("rounds",[]) as Array).is_empty(): continue
		out.append(record)
		if out.size()>=4: break
	return out


func _finished_input(record:Dictionary,friendly:Array,enemy:Array,home:Vector2,today:int)->Dictionary:
	var entry:=_engagement_input(record,friendly,enemy,home)
	var threat:Dictionary=record.get("threat",{})
	var at:=_v2(threat.get("target_position",{}))
	var target:=String(record.get("target_region_id",threat.get("target_region_id","")))
	if target!="":
		var city:Dictionary=CivilizationSystem.city_intelligence.known("player",target)
		if not city.is_empty(): at=_v2(city.get("position",{}))
	if at.is_finite(): entry["pos"]=at
	var BattleAccount:=preload("res://scripts/battle_account.gd")
	var account:=BattleAccount.build(record,{"stage":EraWords.stage()})
	var word:=String({"won":"Won","taken":"Taken","lost":"Beaten back","withdrew":"Pulled back","held":"Undecided","mutual":"Both drew off","uncontested":"They fled","nobody":"Nobody fought"}.get(String(account.kind),"Fought"))
	var hurt:=int(account.ours.killed)+int(account.ours.wounded)
	entry["finished"]=true
	entry["seed"]=int(record.get("seed",0))
	entry["age"]=maxi(0,today-int(record.get("day",today)))
	entry["rounds"]=(record.get("rounds",[]) as Array).size()
	entry["result"]="%s · %s" % [word,("%s hurt or killed" % BattleAccount.count_words(hurt)) if hurt>0 else "none of ours hurt"]
	entry["headline"]=String(account.headline)
	# How it went decides which way the front gives (a surge when it ends).
	entry["won"]=String(account.kind) in ["won","taken","uncontested"]
	entry["lost"]=String(account.kind) in ["lost","withdrew"]
	return entry


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
	var ledger:Dictionary=op.state.get("blockades",{})
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
		var blockade:Dictionary={}
		if String(force.get("tactic","")) in ["close_blockade","distant_blockade"]:
			for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
				var at:=_v2(city.get("position",{}))
				if not Geometry2D.is_point_in_polygon(at,vertices): continue
				var entry:Dictionary=ledger.get(String(city.get("city_id",city.get("id",""))),{})
				if port.is_finite() and entry.is_empty(): continue
				port=at; blockade=entry.duplicate()
				if not blockade.is_empty(): blockade["text"]=Blockade.describe(entry,today)
				if not entry.is_empty(): break
		out.append({"domain":String(force.domain),"vertices":vertices,"control":float(op.effects.control("player",region)),"mission":String(force.mission),"tactic":String(force.get("tactic","")),
			"base":_v2(base.get("position",{})) if not base.is_empty() else Vector2.INF,"port":port,"blockade":blockade,"contacts":contacts.slice(0,6),"name":String(force.get("name","")),"force_id":int(force.get("id",0)),"status":String(force.get("status",""))})
		if out.size()>=16: break
	return out


## Convoys at sea or in the air: the lane still to run, whether escorts work
## the water it crosses, and whether raiders do.
func _lane_inputs(_today:int)->Array:
	var out:Array=[]
	var op:Variant=MilitaryCampaign.get("joint_operations")
	if op==null: return out
	for convoy:Dictionary in op.state.get("convoys",[]):
		if String(convoy.get("owner",""))!="player" or not String(convoy.get("status","")) in ["preparing","outbound","returning"]: continue
		var points:=PackedVector2Array([_v2(convoy.get("position",{}))])
		for waypoint in convoy.get("route",[]): points.append(_v2(waypoint))
		if points.size()<2: continue
		var force:Dictionary=op.force(int(convoy.get("force_id",0)))
		var domain:=String(force.get("domain","navy"))
		var region:Dictionary=op.region_at(points[0],domain) if op.has_method("region_at") else {}
		var escorted:=float(op.effects.mission_power("player",region,"convoy_escort",false))>0.0 if not region.is_empty() else false
		var raided:=float(op.effects.mission_power("player",region,"convoy_raiding",true))>0.0 if not region.is_empty() else false
		out.append({"points":points,"domain":domain,"escorted":escorted,"raided":raided,"status":String(convoy.status),"invasion":bool(convoy.get("invasion",false)),"convoy_id":int(convoy.get("id",0)),"name":String(force.get("name",""))})
		if out.size()>=MAX_LANES: break
	return out


## Our own harbours a rival fleet is blockading: we feel it, so we know it.
func _our_blockaded_ports(today:int)->Array:
	var out:Array=[]
	var op:Variant=MilitaryCampaign.get("joint_operations")
	if op==null: return out
	var ledger:Dictionary=op.state.get("blockades",{})
	for city_id in ledger:
		var entry:Dictionary=ledger[city_id]
		if String(entry.get("civ_id",""))!="player": continue
		var site:Dictionary=CivilizationSystem.city_intelligence.site(String(city_id))
		if site.is_empty(): continue
		out.append({"pos":_v2(site.get("position",{})),"level":float(entry.get("level",0.0)),"text":"Our harbour: "+Blockade.describe(entry,today).to_lower(),"held":bool(entry.get("held",false))})
	return out.slice(0,4)


## Corps, armies and army groups the civilisation actually fields, placed
## where their armies were last reported.
func _echelon_inputs(friendly:Array)->Array:
	return echelons_from(MilitaryCampaign.get("command_hierarchy"),friendly)


## From the command tree (anything with data.nodes, children(), leaves(),
## people()): corps and armies with troops, and organised groups of them.
static func echelons_from(command:Variant,friendly:Array)->Array:
	var out:Array=[]
	if command==null: return out
	var at:Dictionary={}
	for f in friendly: at[int(f.get("army_id",0))]=f.pos
	for record:Dictionary in command.data.get("nodes",{}).values():
		if String(record.get("service",""))!="army" or String(record.get("parent",""))=="" or bool(record.get("retired",false)): continue
		var level:=int(record.get("level",0))
		var children:Array=command.children(String(record.id))
		var group:=int(record.get("force_id",-1))<0 and children.size()>=2 and children.all(func(c:Dictionary)->bool: return int(c.get("level",0))>=CORPS_LEVEL)
		if level<CORPS_LEVEL and not group: continue
		var centre:=Vector2.ZERO
		var count:=0
		var armies:Array=[]
		for leaf:Dictionary in command.leaves(String(record.id)):
			var id:=int(leaf.get("force_id",-1))
			if at.has(id): centre+=at[id]; count+=1; armies.append(id)
		if count==0: continue
		out.append({"id":String(record.id),"name":String(record.get("name","")),"level":level,"group":group,"pos":centre/float(count),"armies":armies,"troops":int(command.people(record))})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return (int(a.level)+(3 if a.group else 0))>(int(b.level)+(3 if b.group else 0)) or ((int(a.level)+(3 if a.group else 0))==(int(b.level)+(3 if b.group else 0)) and String(a.id)<String(b.id)))
	return out.slice(0,MAX_ECHELONS)


# --- Composition (pure) -------------------------------------------------------------

## Plain inputs -> world-space primitives. Bounded by the model's limits.
static func compose(inputs:Dictionary)->Dictionary:
	var mode:=String(inputs.get("mode","front"))
	var stage:=String(inputs.get("stage","reckoned"))
	var friendly:Array=(inputs.get("friendly",[]) as Array).slice(0,Model.MAX_FRIENDLY)
	var enemy:Array=(inputs.get("enemy",[]) as Array).slice(0,Model.MAX_ENEMY)
	var home:Vector2=inputs.get("home",Vector2.ZERO)
	var today:=int(inputs.get("today",0))
	var out:={"mode":mode,"stage":stage,"today":today,"home":home,"friendly_seen":friendly,"enemy_seen":enemy,"fronts":[],"faceoffs":[],"fallbacks":[],"supply":[],"arrows":[],"objectives":[],"clashes":[],"pockets":[],"sieges":[],"raids":[],"zones":[],"lanes":[],"echelons":[],"harbours":[],"withdrawals":[],"sightings":[],"battles":[],"fought":{},"era":1,"sigma":1.0}
	var fronts:Array=[]
	# The ground we hold is ours to the front as well as the hosts in the
	# field: a garrison in a taken town pushes the line past the town.
	var held:Array=[]
	for g in (inputs.get("garrisons",[]) as Array):
		var at:Vector2=g.get("pos",Vector2.INF)
		if int(g.get("troops",0))>0 and at.is_finite(): held.append({"id":"held:%s" % String(g.get("region_id","")),"pos":at,"strength":float(g.troops),"garrison":true})
	# Only forces that can hold a line meet on one; a party of a handful keeps
	# its own small mark (tests/test_battle_scale.gd).
	var holding:=Model.substantial(friendly+held,enemy)
	var facing:=Model.substantial(enemy,friendly+held)
	if mode in ["front","theatre"]:
		var derived:=Model.derive(holding,facing)
		fronts=derived.fronts; out.sigma=float(derived.sigma) if float(derived.sigma)>0.0 else 1.0
		# Who holds each front: the armies nearest its line.
		var reach:=float(out.sigma)*1.6
		for front in fronts:
			var points:PackedVector2Array=front.points
			var box:=Rect2(points[0],Vector2.ZERO)
			for p in points: box=box.expand(p)
			box=box.grow(reach)
			var holders:Array=[]
			for f in holding:
				if bool(f.get("garrison",false)) or not box.has_point(f.pos): continue
				var nearest:=INF
				for p in points: nearest=minf(nearest,p.distance_to(f.pos))
				if nearest<=reach: holders.append(f)
			front["armies"]=holders.map(func(f:Dictionary)->int: return int(f.get("army_id",0)))
			front["holders"]=holders
		out.fronts=fronts
		out.pockets=Model.pockets(fronts,holding,facing)
	elif mode=="host":
		var reach:=6.0
		for f in holding:
			for e in facing: reach=minf(reach,maxf(0.6,(f.pos as Vector2).distance_to(e.pos)*1.01))
		out.faceoffs=Model.face_offs(holding,facing,maxf(reach,2.5))
		out.sigma=1.0
	# The generals' own fallback lines: from where each would withdraw to.
	if mode in ["front","theatre"]:
		for front in fronts:
			var holders:Array=(front.get("holders",[]) as Array).filter(func(f:Dictionary)->bool: return f.has("fallback"))
			if holders.is_empty(): continue
			var line:=Model.fallback_from_intent(front,holders)
			if line.size()>=2: out.fallbacks.append({"points":line,"armies":front.armies,"how":String(holders[0].get("fallback_how","home"))})
	if mode=="theatre":
		# Supply lines from home to the farthest hosts only (bounded).
		var far:Array=[]
		for f in friendly:
			var d:=(f.pos as Vector2).distance_to(home)
			if d>float(out.sigma)*0.5: far.append([d,f.pos])
		far.sort_custom(func(a:Array,b:Array)->bool: return float(a[0])>float(b[0]))
		for pair in far.slice(0,Model.MAX_SUPPLY): out.supply.append(PackedVector2Array([home,pair[1]]))
	# A general who is withdrawing: his road back, dashed, in any age.
	for f in friendly:
		if bool(f.get("withdrawing",false)) and (f.get("route_home",PackedVector2Array()) as PackedVector2Array).size()>=1:
			var road:=PackedVector2Array([f.pos]); road.append_array(f.route_home)
			out.withdrawals.append({"points":road,"army_id":int(f.get("army_id",0))})
	# Which of our armies is laying which siege.
	var besieging:Dictionary={}
	for siege in (inputs.get("sieges",[]) as Array):
		if bool(siege.get("ours",true)) and int(siege.get("army_id",0))!=0: besieging[int(siege.army_id)]=siege.pos
	# The generals' intent: arrows to their objectives (in the raid age, a
	# band's path is a dotted raid track instead). A chase after men who fled
	# and a siege being laid are arrows in any age.
	var bias:=0.0
	var marked:Dictionary={}
	for f in friendly:
		if out.arrows.size()>=Model.MAX_ARROWS: break
		var id:=int(f.get("army_id",0))
		var objective:Vector2=f.get("objective",Vector2.INF)
		if besieging.has(id):
			# The camp stands on the town: the arrow is lettered at the siege
			# ring, pointing in from the side our road comes from.
			var town:Vector2=besieging[id]
			var from:=(home-town).normalized() if home.distance_to(town)>0.0001 else Vector2.LEFT
			out.arrows.append({"id":"siege:%d" % id,"kind":"siege","points":PackedVector2Array([town+from,town+from*0.5,town]),"town":town,"from":from,"ours":true,"offensive":true,"weight":0.8,"stale":false,"army_id":id})
			continue
		if not objective.is_finite() or (f.pos as Vector2).distance_to(objective)<0.05 or bool(f.get("withdrawing",false)): continue
		var road:PackedVector2Array=f.get("road",PackedVector2Array())
		if bool(f.get("chasing",false)):
			var chase:=Model.arrow(f.pos,objective,[],0.1)
			out.arrows.append({"id":"chase:%d" % id,"kind":"pursuit","points":_resample(road,20) if road.size()>=3 else Model.arrow_points(chase,20),"ours":true,"offensive":true,"weight":0.3,"stale":false,"army_id":id})
			continue
		if mode=="raid" and road.size()>=3:
			out.raids.append({"points":_resample(f.road,20),"ours":true,"fought":false,"alpha":1.0,"army_id":id})
			continue
		if mode=="raid":
			var delta:=objective-(f.pos as Vector2)
			var spec:=PackedVector2Array([f.pos,(f.pos as Vector2)+delta*0.5+delta.orthogonal()*0.12,objective])
			out.raids.append({"points":Model.arrow_points(spec,14),"ours":true,"fought":false,"alpha":1.0,"army_id":id})
			continue
		var spec:=Model.arrow(f.pos,objective,fronts,bias)
		bias=-bias+0.05 if bias<=0.0 else -bias
		var offensive:=bool(f.get("offensive",false))
		out.arrows.append({"id":"army:%d" % id,"kind":"offensive" if offensive else "march","points":_resample(road,20) if road.size()>=3 else Model.arrow_points(spec,20),"ours":true,"offensive":offensive,"weight":clampf(log(maxf(10.0,float(f.strength)))/log(10.0)/5.0,0.25,1.0),"stale":int(f.get("report_age",0))>=Model.STALE_DAYS,"army_id":id})
		# Many hosts sent to one place share one objective mark.
		var key:=Vector2i((objective/maxf(0.001,float(out.sigma)*0.05)).round())
		if not marked.has(key):
			marked[key]=true
			out.objectives.append({"pos":objective,"ours":true,"offensive":offensive})
	if mode!="raid":
		# Enemy arrows only from observed movement, dated.
		for e in enemy:
			if out.arrows.size()>=Model.MAX_ARROWS: break
			if not bool(e.get("moving",false)): continue
			var heading:=float(e.get("heading",0.0))
			var direction:=Vector2(0,-1).rotated(-heading)
			var length:=float(out.sigma)*1.2
			var start:Vector2=e.pos
			var spec:=PackedVector2Array([start,start+direction*length*0.5,start+direction*length])
			# The road they were seen on (round the water), cut to the arrow's reach.
			var seen_road:=_clip(e.get("road",PackedVector2Array()) as PackedVector2Array,start,length)
			out.arrows.append({"id":"enemy:%s" % String(e.get("id","")),"kind":"enemy","points":_resample(seen_road,10) if seen_road.size()>=2 and _length(seen_road)>length*0.3 else Model.arrow_points(spec,10),"ours":false,"offensive":true,"weight":clampf(log(maxf(10.0,float(e.strength)))/log(10.0)/5.0,0.25,0.8),"stale":float(e.get("age_days",0))>=Model.STALE_DAYS,"seen_day":int(e.get("seen_day",-1)),"enemy_id":String(e.get("id",""))})
	for engagement in (inputs.get("engagements",[]) as Array).slice(0,Model.MAX_CLASHES):
		var ours_id:=String(engagement.get("ours",Tactics.BASELINE))
		var theirs_id:=String(engagement.get("theirs",Tactics.BASELINE))
		var rounds:=int(engagement.get("rounds",0))
		var skirmish:=Model.skirmish(int(engagement.get("our_troops",0)),int(engagement.get("their_troops",0)))
		out.clashes.append({"skirmish":skirmish,"pos":engagement.pos,"axis":engagement.get("axis",Vector2.RIGHT),"ours":ours_id,"theirs":theirs_id,
			"shape_ours":Tactics.shape(ours_id,rounds,String(engagement.get("phase_ours","hold"))),"shape_theirs":Tactics.shape(theirs_id,rounds,String(engagement.get("phase_theirs","hold"))),
			"label":_cap(Tactics.name_of(ours_id,stage)) if ours_id!=Tactics.BASELINE else _cap(Tactics.name_of(theirs_id,stage)) if theirs_id!=Tactics.BASELINE else "","event":String(engagement.get("event","")),
			"army_id":int(engagement.get("army_id",0)),"rounds":rounds,"commanded":bool(engagement.get("commanded",false)),
			"finished":bool(engagement.get("finished",false)),"seed":int(engagement.get("seed",0)),"age":int(engagement.get("age",0)),"result":String(engagement.get("result","")),"headline":String(engagement.get("headline","")),
			"won":bool(engagement.get("won",false)),"lost":bool(engagement.get("lost",false)),"battle_id":String(engagement.get("battle_id",""))})
	for siege in (inputs.get("sieges",[]) as Array).slice(0,4):
		out.sieges.append({"pos":siege.pos,"pressure":clampf(float(siege.get("pressure",0.0)),0.0,1.0),"works":String(siege.get("works","blockade_camp")),"ours":bool(siege.get("ours",true)),"label":_cap(Tactics.name_of(String(siege.get("works","blockade_camp")),stage)),"days":int(siege.get("days",0)),"army_id":int(siege.get("army_id",0))})
	# Battles being fought now: ours on the front at their contact point, the
	# stretch of front being fought over heated (the worm); rivals' where our
	# watchers saw them. A siege's battle stands on its ring.
	var lines:Array=(out.fronts as Array)+(out.faceoffs as Array)
	out.battles=BattleMarks.place((inputs.get("battles",[]) as Array).slice(0,Model.MAX_BATTLES),lines,float(out.sigma))
	for index in lines.size():
		var line:Dictionary=lines[index]
		line["heat"]=BattleMarks.heat(line.points,out.battles,index,float(out.sigma))
	var fought:Dictionary={}
	for battle in out.battles:
		if not bool(battle.get("ours",false)): continue
		if String(battle.get("kind",""))=="siege":
			for siege in out.sieges:
				if (siege.pos as Vector2).distance_to(battle.pos)<float(out.sigma)*0.2+0.01: siege["marked"]=true
		else: fought[int(battle.get("army_id",0))]=battle.pos
	out.fought=fought
	# The tactic's diagram is drawn round the battle's own mark.
	for clash in out.clashes:
		if not bool(clash.get("finished",false)) and fought.has(int(clash.get("army_id",0))): clash["pos"]=fought[int(clash.army_id)]
	# Spears before the lettered ages, swords after.
	out.era=0 if stage=="hearth" else 1
	for raid in (inputs.get("raids",[]) as Array).slice(0,Model.MAX_CLASHES):
		var from:Vector2=raid.from; var to:Vector2=raid.to
		var delta:=to-from
		var spec:=PackedVector2Array([from,from+delta*0.5+delta.orthogonal()*0.18,to])
		out.raids.append({"points":Model.arrow_points(spec,14),"ours":bool(raid.get("ours",false)),"fought":bool(raid.get("fought",false)),"alpha":float(raid.get("alpha",1.0))})
	for zone in (inputs.get("zones",[]) as Array).slice(0,16):
		var entry:Dictionary=(zone as Dictionary).duplicate()
		entry["label"]=_cap(Tactics.name_of(String(zone.get("tactic","")),stage)) if String(zone.get("tactic",""))!="" else ""
		entry["shape"]=String((Tactics.ZONE_TACTICS.get(String(zone.get("tactic","")),{}) as Dictionary).get("shape",""))
		# Interception zones are the air arm's defence: drawn as a belt.
		entry["belt"]=String(zone.get("domain",""))=="air" and String(zone.get("mission",""))=="interception"
		out.zones.append(entry)
	# Hosts the map has no counter for (the Alderford war's coalition): a
	# dated mark where they were last seen.
	for e in enemy:
		if bool(e.get("marked",false)): out.sightings.append(e)
	out.lanes=(inputs.get("lanes",[]) as Array).slice(0,MAX_LANES)
	out.harbours=(inputs.get("harbours",[]) as Array).slice(0,4)
	out.echelons=(inputs.get("echelons",[]) as Array).slice(0,MAX_ECHELONS)
	out.marks=_marks(inputs,friendly,enemy,out)
	return out


## The forces themselves: ours from the generals' own reports, theirs only
## from what was seen (dated). Each carries its noun, its mark and what it
## is doing, in the era's words (hud/army_marks.gd).
static func _marks(inputs:Dictionary,friendly:Array,enemy:Array,built:Dictionary)->Array:
	var stage:=String(inputs.get("stage","reckoned"))
	var corps_known:=bool(inputs.get("corps_known",false))
	var staffs_known:=bool(inputs.get("staffs_known",false))
	# In battle: a fight being fought now (a finished one is only history).
	var fighting:Dictionary=(built.get("fought",{}) as Dictionary).duplicate()
	for clash in built.get("clashes",[]):
		if not bool(clash.get("finished",false)): fighting[int(clash.get("army_id",0))]=true
	var besieging:Dictionary={}
	for siege in built.get("sieges",[]):
		if bool(siege.get("ours",true)): besieging[int(siege.get("army_id",0))]=String(siege.get("place",""))
	var out:Array=[]
	for f in friendly.slice(0,ArmyMarks.MAX_OURS):
		var troops:=roundi(float(f.get("strength",0.0)))
		if troops<=0: continue
		var era:=int(f.get("era",0))
		var context:Dictionary=(f.get("doing_context",{}) as Dictionary).duplicate()
		var id:=int(f.get("army_id",0))
		context["fighting"]=fighting.has(id) and id!=0
		context["withdrawing"]=bool(f.get("withdrawing",false))
		if besieging.has(id) and id!=0: context["besieging"]=String(besieging[id]) if String(besieging[id])!="" else "the town"
		var detached:=String(f.get("detachment_of",""))
		var full:=maxi(troops,int(f.get("full",troops)))
		out.append({"id":"ours:%d" % id,"side":"ours","army_id":id,"pos":f.pos,"troops":troops,"era":era,"branch":String(f.get("branch","foot")),
			"noun":ArmyMarks.noun(troops,stage,era,corps_known),"kind":ArmyMarks.kind(troops,stage,era,staffs_known),"detachment_of":detached,
			"name":String(f.get("name","")),"general":"" if detached!="" else String(f.get("general","")),"doing":String(context.get("pursuit","")) if String(context.get("pursuit",""))!="" else ArmyMarks.doing(context),
			"report_age":int(f.get("report_age",0)),"selected":bool(f.get("selected",false)),"condition":String(f.get("condition","intact")),"moving":String(context.get("status",""))=="moving",
			"full":full,"will":clampf(float(f.get("morale",0.6)),0.0,1.0),"state":BattleMarks.state_of(context),"heading":context.get("delta",Vector2.ZERO)})
	# Towns we hold: the garrison's mark stands on the town.
	for g in (inputs.get("garrisons",[]) as Array):
		var held:=int(g.get("troops",0))
		if held<=0: continue
		out.append({"id":"held:%s" % String(g.get("region_id","")),"side":"ours","army_id":0,"garrison":true,"pos":g.pos,"troops":held,"era":0,"branch":"foot",
			"noun":"garrison","kind":ArmyMarks.kind(held,stage,0,staffs_known),"name":"","town":String(g.get("town","")),"general":String(g.get("general","")),
			"doing":"holding %s" % ArmyMarks.place(String(g.get("town","the town"))),"report_age":0,"selected":false,"condition":"intact","moving":false,"fate_note":String(g.get("fate_note","")),"away":int(g.get("away",0)),
			"full":maxi(held,int(g.get("required",held))),"will":clampf(float(g.get("morale",0.6)),0.0,1.0),"state":"hungry" if bool(g.get("hungry",false)) else "holding"})
	# Before writing, a stranger's host is told as a feud (war_map_overlay.gd);
	# only a general's own dated sightings (an authored campaign) are marked.
	var strangers:Array=[] if stage=="hearth" else inputs.get("strangers",[])
	var theirs:Array=enemy.slice(0,ArmyMarks.MAX_THEIRS)
	if stage=="hearth": theirs=theirs.filter(func(e:Dictionary)->bool: return bool(e.get("marked",false)))
	for s in strangers:
		if theirs.size()>=ArmyMarks.MAX_THEIRS: break
		theirs.append(s)
	var near_battle:=maxf(4.0,float(built.get("sigma",1.0))*0.6)
	for e in theirs:
		var low:=int(e.get("low",roundi(float(e.get("strength",0.0)))))
		var high:=maxi(low,int(e.get("high",roundi(float(e.get("strength",0.0))))))
		if high<=0: continue
		var mid:=roundi(float(low+high)*0.5)
		var era:=int(e.get("era",0))
		var scout:=bool(e.get("scout",false))
		var mark:={"id":"theirs:%s" % String(e.get("id","")),"side":"theirs","enemy_id":String(e.get("id","")),"pos":e.pos,"troops":mid,"low":low,"high":high,
			"era":era,"branch":String(e.get("branch","foot")),"noun":"scouts" if scout else ArmyMarks.noun(mid,stage,era,false),
			"kind":"band:2" if scout else ArmyMarks.kind(mid,stage,era,false),"owner":String(e.get("owner",e.get("name",""))),"moving":bool(e.get("moving",false)),
			"age_days":int(e.get("age_days",0)),"hostile":not strangers.has(e),"observed":bool(e.get("observed",false)),"scout":scout,
			"marked":bool(e.get("marked",false)),"sighting":e}
		# What was seen of them, and no more: their state as last seen, and
		# their will only as the watchers' range, while the sighting is fresh.
		var fighting_now:=false
		if int(e.get("age_days",0))<ArmyMarks.FRESH_DAYS:
			for battle in built.get("battles",[]):
				if int(battle.get("age_days",0))==0 and (battle.pos as Vector2).distance_to(e.pos)<=near_battle: fighting_now=true; break
		mark["state"]="fighting" if fighting_now else ("marching" if bool(e.get("moving",false)) else "holding")
		if float(e.get("will_low",-1.0))>=0.0 and int(e.get("age_days",0))<ArmyMarks.FRESH_DAYS:
			mark["will_low"]=float(e.will_low); mark["will_high"]=maxf(float(e.will_low),float(e.get("will_high",e.will_low)))
		out.append(mark)
	return out


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


## Primitive counts, for probes and tests (bounded regardless of armies).
static func primitive_count(built:Dictionary)->int:
	var total:=0
	for key in ["fronts","faceoffs","fallbacks","supply","arrows","objectives","clashes","pockets","sieges","raids","zones","lanes","echelons","harbours","withdrawals","sightings","battles"]: total+=(built.get(key,[]) as Array).size()
	return total


# --- Projection -----------------------------------------------------------------------

func _screen(p:Vector2)->Vector2:
	if project.is_valid(): return project.call(p)
	var camera:=_camera()
	if camera==null: return Vector2.INF
	var key:=p.snapped(Vector2.ONE*0.05)
	if not height_cache.has(key):
		if height_cache.size()>8192: height_cache.clear()
		height_cache[key]=float(terrain._height_at(p.x,p.y)) if terrain.has_method("_height_at") else 0.0
	var world:=Vector3(p.x,float(height_cache[key])+0.002,p.y)
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


## A world line draped over the ground: subdivided so long legs follow the
## relief, and split where it passes behind the camera.
func _drape(points:PackedVector2Array,step:float)->Array:
	var runs:Array=[]
	var current:=PackedVector2Array()
	for p in Model.densify(points,step,96):
		var s:=_screen(p)
		if s.is_finite(): current.append(s)
		elif current.size()>=2: runs.append(current); current=PackedVector2Array()
		else: current=PackedVector2Array()
	if current.size()>=2: runs.append(current)
	return runs


## World units per screen pixel near a point (for sizing marks per band).
func _world_per_px(at:Vector2)->float:
	var a:=_screen(at); var b:=_screen(at+Vector2(1.0,0.0))
	if not a.is_finite() or not b.is_finite() or a.distance_to(b)<=0.0001: return 1.0
	return 1.0/a.distance_to(b)


# --- Drawing ------------------------------------------------------------------------------

func _draw()->void:
	var started:=Time.get_ticks_usec()
	hits.clear()
	drawn_marks.clear()
	caption_requests.clear()
	hot_cache.clear()
	battle_cache.clear()
	if pulse_layer!=null: pulse_layer.queue_redraw()
	if scene.is_empty(): placed_captions.clear(); return
	var band:=_band()
	if band=="ground":
		# Up close only the forces' small paper cards stay, placed clear of
		# the town cards; the front and its ink stand aside for the ground.
		_draw_marks(band,[],[])
		_letter_captions(T.voice_font(true))
		last_draw_usec=Time.get_ticks_usec()-started
		return
	var wide:=band in ["continental","world"]
	var t:=smoothstep(0.0,1.0,blend)
	var font:=T.voice_font(true)
	var camera:=_camera()
	view_key=hash([size,band,camera.global_transform if camera!=null else Transform3D(),camera.size if camera!=null else 0.0,project.is_valid()])
	# How finely to drape: a few pixels per leg at any zoom.
	var step:=_world_per_px(_centre_of_scene())*14.0
	if band!="local":
		for zone in scene.get("zones",[]): _draw_zone(zone,band)
	for lane in scene.get("lanes",[]): _draw_lane(lane,step)
	for harbour in scene.get("harbours",[]): _draw_harbour(harbour,wide)
	if not wide:
		for supply in scene.get("supply",[]):
			for run in _drape(supply,step): _dashed(run,Color(INK,0.35),1.0,3.0,6.0)
		for fallback in scene.get("fallbacks",[]):
			for run in _drape(fallback.points,step):
				_dashed(run,Color(PAPER,0.55),3.4,10.0,6.0)
				_dashed(run,Color(OURS,0.8),1.6,10.0,6.0)
				hits.append({"kind":"fallback","line":run,"armies":fallback.get("armies",[])})
		for road in scene.get("withdrawals",[]):
			for run in _drape(road.points,step):
				_dashed(run,Color(OURS,0.75),2.0,5.0,5.0)
				hits.append({"kind":"army","line":run,"army_id":int(road.army_id)})
	for index in live_fronts.size():
		var entry:Dictionary=live_fronts[index]
		if float(entry.alpha)<=0.01: continue
		_draw_front(entry,band,step)
	for pocket in scene.get("pockets",[]): _draw_pocket(pocket,band)
	for faceoff in scene.get("faceoffs",[]):
		_draw_front({"points":faceoff.points,"alpha":1.0,"data":faceoff},band,step)
	for raid in scene.get("raids",[]): _draw_raid(raid)
	for id in live_arrows: _draw_arrow(live_arrows[id],t,wide)
	if not wide:
		for objective in scene.get("objectives",[]): _draw_objective(objective)
	for siege in scene.get("sieges",[]): _draw_siege(siege,wide)
	for clash in scene.get("clashes",[]): _draw_clash(clash,band)
	for pulse in clash_pulses: _draw_clash_pulse(pulse,wide)
	# Battles stand where the sides touch; forces step clear of them.
	var battles:=_battle_entries(band)
	# Highest echelon first; a group's own corps give way to its mark where
	# they would crowd it, and the armies under a drawn mark give way to it.
	var echelons_drawn:Array=[]
	if wide:
		for echelon in scene.get("echelons",[]):
			var at:=_screen(echelon.pos)
			if not at.is_finite(): continue
			var crowded:=false
			for other in echelons_drawn:
				if (other.at as Vector2).distance_to(at)<44.0: crowded=true; break
			if crowded: continue
			echelons_drawn.append({"at":at,"armies":echelon.get("armies",[]),"echelon":echelon})
	_draw_marks(band,echelons_drawn,battles)
	for entry in echelons_drawn: _draw_echelon(entry.echelon,band)
	_draw_battles(battles,band)
	# One small dated caption per stale front: the map says how old it is.
	if not wide:
		for entry in live_fronts:
			var data:Dictionary=entry.data
			if not bool(data.get("stale",false)) or float(entry.target_alpha)<=0.0: continue
			var ages:PackedFloat32Array=data.age
			var oldest:=0; var where:=0
			for k in ages.size():
				if roundi(ages[k])>oldest: oldest=roundi(ages[k]); where=k
			_request_caption("stale:%d" % where,(data.points as PackedVector2Array)[where],"Their line as last seen, %d days ago" % oldest,THEIRS,2)
	_letter_captions(font)
	last_draw_usec=Time.get_ticks_usec()-started


# --- Battles ---------------------------------------------------------------------------

## Where each battle stands on screen now: ours on the front, a siege's on
## its ring clear of the town's own pin; far out, battles close together
## stand as one. Kept for the forces' clearance, the lettering and the
## pulse canvas. [{at, battle, radius, rect, live, phase, group?}]
func _battle_entries(band:String)->Array:
	var entries:Array=[]
	var battles:Array=scene.get("battles",[])
	if battles.is_empty(): return entries
	var wide:=band in ["continental","world"]
	var view:=Rect2(Vector2.ZERO,size).grow(40.0)
	for battle in battles:
		var at:=_screen(battle.pos)
		if not at.is_finite() or not view.has_point(at): continue
		if String(battle.get("kind",""))=="siege":
			var ring:=36.0
			for siege in scene.get("sieges",[]):
				if (siege.pos as Vector2).distance_to(battle.pos)<=_world_per_px(battle.pos)*4.0: ring=lerpf(46.0,26.0,float(siege.pressure))*(0.55 if wide else 1.0)
			at+=Vector2(0.72,-0.72)*ring
		entries.append({"at":at,"battle":battle})
	# Ours first, then the larger fights, then a stable order.
	entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var oa:=bool(a.battle.get("ours",false)); var ob:=bool(b.battle.get("ours",false))
		if oa!=ob: return oa
		var ma:=_battle_men(a.battle); var mb:=_battle_men(b.battle)
		if ma!=mb: return ma>mb
		return String(a.battle.get("id",""))<String(b.battle.get("id","")))
	if wide:
		var grouped:Array=[]
		for group in BattleMarks.cluster(entries,float(BattleMarks.CLUSTER_PX.get(band,56.0))):
			if (group.members as Array).size()==1: grouped.append(group.members[0])
			else: grouped.append({"at":group.at,"battle":(group.members[0] as Dictionary).battle,"group":group})
		entries=grouped
	var r:=BattleMarks.MARK_RADIUS*(0.9 if wide else 1.0)
	for entry in entries:
		var battle:Dictionary=entry.battle
		entry["radius"]=r+3.0
		entry["rect"]=Rect2((entry.at as Vector2)-Vector2(BattleMarks.BAR_WIDTH*0.5+2.0,r+3.0),Vector2(BattleMarks.BAR_WIDTH+4.0,r*2.0+11.0+BattleMarks.BAR_HEIGHT))
		entry["live"]=int(battle.get("age_days",0))==0
		entry["phase"]=float(absi(hash(String(battle.get("id",""))))%1000)/1000.0
	battle_cache=entries
	return entries


static func _battle_men(battle:Dictionary)->int:
	var sides:Dictionary=battle.get("sides",{})
	return int((sides.get("a",{}) as Dictionary).get("troops",0))+int((sides.get("b",{}) as Dictionary).get("troops",0))


## The battle marks, their names and days, and what a click or a resting
## pointer finds there.
func _draw_battles(entries:Array,band:String)->void:
	var wide:=band in ["continental","world"]
	var era:=int(scene.get("era",1))
	for entry in entries:
		var at:Vector2=entry.at
		if entry.has("group"):
			var group:Dictionary=entry.group
			var members:Array=[]
			for member in group.members: members.append(member.battle)
			BattleMarks.draw_cluster(self,at,group,era,T.voice_font(false))
			var places:=PackedStringArray()
			for battle in members.slice(0,3): places.append(String(battle.get("place_name","")))
			var line:="%s: %s" % [BattleMarks.aggregate_label(members.size()),", ".join(places)]
			_request_caption("battles:%s" % String((members[0] as Dictionary).get("id","")),Vector2.INF,BattleMarks.aggregate_label(members.size()),INK,5,float(entry.radius)+14.0,at,"letter")
			hits.append({"kind":"battles","centre":at,"radius":float(entry.radius)+4.0,"battles":members,"line":line})
			continue
		var battle:Dictionary=entry.battle
		var scale:=(0.85 if wide else 1.0)*(0.8 if bool(battle.get("skirmish",false)) else 1.0)
		BattleMarks.draw_battle(self,at,battle,era,scale)
		if band!="world": _request_caption("battle:%s" % String(battle.get("id","")),Vector2.INF,String(battle.get("label","")),INK,5 if bool(battle.get("ours",false)) else 4,float(entry.radius)+4.0,at,"letter")
		hits.append({"kind":"battle","centre":at,"radius":float(entry.radius)+4.0,"battle":battle,"line":String(battle.get("hover",""))})


## The fighting's own motion, on the pulse canvas behind the chart's ink:
## the worm's warm body under each stretch of front being fought over, its
## teeth biting in a slow wave, and each battle's gentle pulse. No day and
## night; with reduced motion it all stands still.
func draw_animated(canvas:CanvasItem)->void:
	var still:=Motion.reduced()
	var t:=anim_clock
	var breath:=0.6 if still else 0.5+0.5*sin(t*TAU/PULSE_PERIOD)
	for run in hot_cache:
		var points:PackedVector2Array=run.points
		var normals:PackedVector2Array=run.normals
		var heat:PackedFloat32Array=run.heat
		var alpha:=float(run.alpha)*float(run.peak)
		var wide:=bool(run.wide)
		canvas.draw_polyline(points,Color(THEIRS_WASH,(0.20+0.10*breath)*alpha),14.0 if wide else 24.0,true)
		canvas.draw_polyline(points,Color(THEIRS,(0.30+0.16*breath)*alpha),8.0 if wide else 14.0,true)
		var n:=points.size()
		for i in range(0,n-1,2 if n>8 else 1):
			var h:=heat[i]
			if h<0.3: continue
			var a:=points[i]; var b:=points[i+1]
			var along:=(b-a).normalized()
			var wave:=1.0 if still else 0.72+0.38*sin(float(i)*0.9-t*3.2)
			var tooth:=((6.0 if wide else 9.0)+7.0*h)*wave
			var tri:=PackedVector2Array([a-along*4.5,a+along*4.5,a+normals[i]*tooth])
			if _fillable(tri): canvas.draw_colored_polygon(tri,Color(THEIRS,0.92*float(run.alpha)))
	if still: return
	for entry in battle_cache:
		if not bool(entry.get("live",false)): continue
		var at:Vector2=entry.at
		var r:=float(entry.radius)
		var u:=fposmod(t/PULSE_PERIOD+float(entry.phase),1.0)
		var spread:=1.0-(1.0-u)*(1.0-u)
		var fade:=(1.0-u)*(1.0-u)
		canvas.draw_circle(at,r+2.0,Color(THEIRS_WASH,0.10+0.10*(0.5+0.5*sin((t/PULSE_PERIOD+float(entry.phase))*TAU))))
		canvas.draw_arc(at,r+2.0+16.0*spread,0.0,TAU,32,Color(PAPER,0.45*fade),3.0,true)
		canvas.draw_arc(at,r+2.0+16.0*spread,0.0,TAU,32,Color(THEIRS,0.55*fade),1.3,true)


## The battle mark under a screen point: {kind:"battle", battle} or
## {kind:"battles", battles} (far out), or {}.
func battle_at(point:Vector2)->Dictionary:
	var best:={}; var best_distance:=INF
	for hit in hits:
		if not String(hit.get("kind","")) in ["battle","battles"]: continue
		var d:=(hit.centre as Vector2).distance_to(point)
		if d<=float(hit.radius) and d<best_distance: best_distance=d; best=hit
	return best


## How a battle is opened: our battles in the battle view (the game's own
## entry point, MilitaryCommandUI._open_battle_graphics, told which army's
## fight), a siege in its siege screen. {} for a rival's (a note instead).
static func battle_view_request(battle:Dictionary)->Dictionary:
	if not bool(battle.get("ours",false)): return {}
	if String(battle.get("kind",""))=="siege": return {"siege":String(battle.get("siege_id",""))}
	return {"method":"_open_battle_graphics","args":[int(battle.get("army_id",0)),-1],"engagement":String(battle.get("id",""))}


## A click on a battle: ours open in the battle view; far out, a group of
## battles, or a rival's fight our watchers saw, opens a note about it.
func open_battle(hit:Dictionary,at:Vector2)->void:
	close_tip()
	if String(hit.get("kind",""))=="battles":
		open_note(hit,at); return
	var battle:Dictionary=hit.get("battle",{})
	var request:=battle_view_request(battle)
	if request.is_empty():
		open_note(hit,at); return
	if battle_opener.is_valid():
		battle_opener.call(request); return
	close_note()
	if request.has("siege"):
		preload("res://scripts/hud/siege_screen.gd").open(String(request.siege))
		return
	var ui:Node=get_tree().root.get_node_or_null("MilitaryCommandUI") if is_inside_tree() else null
	if ui==null: return
	# The battle model's own opener, when it offers one by engagement.
	if ui.has_method("open_engagement"): ui.call_deferred("open_engagement",String(request.engagement))
	else: ui.call_deferred(String(request.method),int(request.args[0]),int(request.args[1]))


## A pointer resting on a battle: one plain line beside it.
func _hover(point:Vector2)->void:
	var over:Dictionary={}
	if get_viewport()!=null and get_viewport().gui_get_hovered_control()==null: over=battle_at(point)
	var line:=String(over.get("line",""))
	if line=="":
		close_tip(); return
	if tip==null: _build_tip()
	var label:=tip.get_child(0) as Label
	if label.text!=line: label.text=line; tip.reset_size()
	tip.show()
	var extent:=tip.get_combined_minimum_size()
	var view:=get_viewport_rect().size
	tip.position=Vector2(clampf(point.x+16.0,8.0,maxf(8.0,view.x-extent.x-8.0)),clampf(point.y+18.0,8.0,maxf(8.0,view.y-extent.y-8.0)))
	hover_id=String((over.get("battle",{}) as Dictionary).get("id",over.get("kind","")))


func close_tip()->void:
	if tip!=null: tip.hide()
	hover_id=""


func _build_tip()->void:
	if note_layer==null:
		note_layer=CanvasLayer.new(); note_layer.name="WarNoteLayer"; note_layer.layer=2
		add_child(note_layer)
	tip=PanelContainer.new(); tip.name="BattleTip"
	tip.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CONTROL,8.0))
	tip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	note_layer.add_child(tip)
	var label:=Label.new(); label.name="Line"; label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	T.text(label,"small",T.INK)
	tip.add_child(label)
	tip.hide()


func _centre_of_scene()->Vector2:
	for key in ["fronts","clashes","sieges","zones"]:
		for item in scene.get(key,[]):
			if item.has("pos"): return item.pos
			if item.has("points"): return (item.points as PackedVector2Array)[0]
			if item.has("vertices"): return (item.vertices as PackedVector2Array)[0]
	return Vector2.ZERO


func _dashed(points:PackedVector2Array,color:Color,width:float,dash:float,gap:float)->void:
	if points.size()<2: return
	var carry:=0.0
	var drawing:=true
	var segments:=PackedVector2Array()
	for i in range(1,points.size()):
		var a:=points[i-1]; var b:=points[i]
		var length:=a.distance_to(b)
		if length<=0.0001: continue
		var at:=0.0
		while at<length and segments.size()<4096:
			var span:=minf((dash if drawing else gap)-carry,length-at)
			if drawing: segments.append(a.lerp(b,at/length)); segments.append(a.lerp(b,(at+span)/length))
			at+=span; carry+=span
			if carry>=(dash if drawing else gap)-0.001: carry=0.0; drawing=not drawing
	# One draw call for the whole dashed line.
	if segments.size()>=2: draw_multiline(segments,color,width,true)


static func _offset(points:PackedVector2Array,normals:PackedVector2Array,by:float)->PackedVector2Array:
	var out:=PackedVector2Array()
	for i in points.size(): out.append(points[i]+normals[i]*by)
	return out


## A polygon that the canvas can fill (non-degenerate, triangulable).
static func _fillable(polygon:PackedVector2Array)->bool:
	if polygon.size()<3: return false
	var area:=0.0
	for i in polygon.size(): area+=polygon[i].cross(polygon[(i+1)%polygon.size()])
	return absf(area)>4.0 and Geometry2D.triangulate_polygon(polygon).size()>0


## The front: a soft band of each side's colour either side of the line (the
## ground each holds), a paper halo, an ink line whose weight follows how
## massed the two sides are, and oxblood teeth pointing into the enemy.
## Stretches derived from stale reports are dashed and paler.
func _draw_front(entry:Dictionary,band:String,_step:float)->void:
	var data:Dictionary=entry.get("data",{})
	# Where it has eased to, plus any surge running where a battle ended or a
	# town changed hands.
	var world:=_bulged(entry.points)
	var points:=_poly(world)
	if points.size()<2: return
	var alpha:=clampf(float(entry.get("alpha",1.0)),0.0,1.0)
	var wide:=band in ["continental","world"]
	var n:=points.size()
	var source:PackedVector2Array=data.get("points",PackedVector2Array())
	var last_source:=maxi(0,source.size()-1)
	var to_source:=float(last_source)/float(maxi(1,n-1))
	var widths:PackedFloat32Array=data.get("width",PackedFloat32Array())
	var ages:PackedFloat32Array=data.get("age",PackedFloat32Array())
	var toward:PackedVector2Array=data.get("toward",PackedVector2Array())
	var pressure:PackedFloat32Array=data.get("pressure",PackedFloat32Array())
	var heat:PackedFloat32Array=data.get("heat",PackedFloat32Array())
	var all_stale:=bool(data.get("stale",false)) and ages.is_empty()
	# Screen normals toward the enemy, one per vertex. The world "toward" is
	# carried to the screen by the local projection (two samples per front).
	var eps:=maxf(0.0001,float(scene.get("sigma",1.0))*0.05)
	var mid:=world[n/2]
	var origin:=_screen(mid)
	var ex:=(_screen(mid+Vector2(eps,0.0))-origin)/eps
	var ey:=(_screen(mid+Vector2(0.0,eps))-origin)/eps
	var projectable:=origin.is_finite() and ex.is_finite() and ey.is_finite()
	var normals:=PackedVector2Array()
	for i in n:
		var a:=points[maxi(0,i-1)]; var b:=points[mini(n-1,i+1)]
		var normal:=(b-a).normalized().orthogonal()
		var j:=clampi(roundi(float(i)*to_source),0,last_source)
		if j<toward.size() and projectable:
			if normal.dot(ex*toward[j].x+ey*toward[j].y)<0.0: normal=-normal
		elif i>0 and normals[i-1].dot(normal)<0.0: normal=-normal
		normals.append(normal)
	# Each side's ground, as two soft bands (drawn as wide strokes: no
	# polygon to fail when the line folds on screen).
	var wash:=22.0 if band=="local" else (16.0 if band=="regional" else 8.0)
	draw_polyline(_offset(points,normals,wash*0.5),Color(THEIRS_WASH,0.20*alpha),wash,true)
	draw_polyline(_offset(points,normals,wash*0.25),Color(THEIRS_WASH,0.18*alpha),wash*0.5,true)
	draw_polyline(_offset(points,normals,-wash*0.5),Color(OURS_WASH,0.26*alpha),wash,true)
	draw_polyline(_offset(points,normals,-wash*0.25),Color(OURS_WASH,0.20*alpha),wash*0.5,true)
	var base:=2.6 if wide else (3.4 if band=="regional" else 3.8)
	draw_polyline(points,Color(PAPER,0.7*alpha),base+5.0,true)
	# The line itself in runs (one polyline each, dashed where it is known
	# only from old reports), then its weight where the sides are massed or
	# fighting, batched by width.
	var heat_at:=PackedFloat32Array(); heat_at.resize(n)
	var stale_at:=PackedByteArray(); stale_at.resize(n)
	for i in n:
		var j:=clampi(roundi(float(i)*to_source),0,last_source)
		heat_at[i]=float(heat[j]) if j<heat.size() else 0.0
		stale_at[i]=1 if all_stale or (j<ages.size() and float(ages[j])>=float(Model.STALE_DAYS)) else 0
	var run:=PackedVector2Array([points[0]])
	var run_stale:=stale_at[0]==1
	for i in range(1,n):
		var stale:=stale_at[i]==1
		if stale!=run_stale:
			_front_run(run,run_stale,base,alpha)
			run=PackedVector2Array([points[i-1]]); run_stale=stale
		run.append(points[i])
	_front_run(run,run_stale,base,alpha)
	var buckets:Dictionary={}
	for i in range(1,n):
		if stale_at[i]==1: continue
		var j:=clampi(roundi(float(i)*to_source),0,last_source)
		var extra:=(2.6 if not wide else 1.0)*(float(widths[j]) if j<widths.size() else 0.6)+(3.4 if not wide else 2.0)*maxf(heat_at[i-1],heat_at[i])
		var key:=roundi(extra*2.0)
		if key<=0: continue
		if not buckets.has(key): buckets[key]=PackedVector2Array()
		var segments:PackedVector2Array=buckets[key]
		segments.append(points[i-1]); segments.append(points[i])
		buckets[key]=segments
	for key in buckets: draw_multiline(buckets[key],Color(INK,0.92*alpha),base+float(key)*0.5,true)
	# Where a battle is fought the worm works (drawn on the pulse canvas);
	# elsewhere the teeth stand still.
	var animated:=pulse_layer!=null and not Motion.reduced()
	var hot_points:=PackedVector2Array(); var hot_normals:=PackedVector2Array(); var hot_heat:=PackedFloat32Array()
	for i in n:
		if heat_at[i]>0.06 and stale_at[i]==0:
			hot_points.append(points[i]); hot_normals.append(normals[i]); hot_heat.append(heat_at[i])
		elif hot_points.size()>=2:
			_keep_hot(hot_points,hot_normals,hot_heat,alpha,wide); hot_points=PackedVector2Array(); hot_normals=PackedVector2Array(); hot_heat=PackedFloat32Array()
		else:
			hot_points.clear(); hot_normals.clear(); hot_heat.clear()
	if hot_points.size()>=2: _keep_hot(hot_points,hot_normals,hot_heat,alpha,wide)
	# Teeth into their side, spaced along the line on screen.
	var length_px:=0.0
	for i in range(1,n): length_px+=points[i-1].distance_to(points[i])
	var stride:=clampi(roundi(float(n-1)*(26.0 if wide else 22.0)/maxf(1.0,length_px)),1,maxi(1,n/4))
	for i in range(stride/2,n-1,stride):
		if animated and heat_at[i]>0.3: continue
		var a:=points[i]; var b:=points[i+1]
		var along:=(b-a).normalized()
		var j:=clampi(roundi(float(i)*to_source),0,last_source)
		var tooth:=(6.0 if wide else 9.0)+4.0*absf(float(pressure[j]) if j<pressure.size() else 0.0)+6.0*heat_at[i]
		var color:=Color(THEIRS,0.92*alpha)
		if stale_at[i]==1: color.a=0.45*alpha
		var tri:=PackedVector2Array([a-along*5.0,a+along*5.0,a+normals[i]*tooth])
		if _fillable(tri): draw_colored_polygon(tri,color)
	hits.append({"kind":"front","line":points,"armies":data.get("armies",[]),"stale":bool(data.get("stale",false))})


func _front_run(run:PackedVector2Array,stale:bool,base:float,alpha:float)->void:
	if run.size()<2: return
	if stale: _dashed(run,Color(INK,0.5*alpha),2.0,6.0,5.0)
	else: draw_polyline(run,Color(INK,0.92*alpha),base,true)


## A stretch of front being fought over, kept for the pulse canvas.
func _keep_hot(points:PackedVector2Array,normals:PackedVector2Array,heat:PackedFloat32Array,alpha:float,wide:bool)->void:
	var peak:=0.0
	for h in heat: peak=maxf(peak,h)
	hot_cache.append({"points":points,"normals":normals,"heat":heat,"peak":peak,"alpha":alpha,"wide":wide})


## A pocket: the ring closing on them, hatched inside, the gap still open
## shown as a bracket; closure eases as the ring closes over days.
func _draw_pocket(pocket:Dictionary,band:String)->void:
	var index:=int(pocket.front)
	if index>=live_fronts.size(): return
	var ring:=_poly(live_fronts[index].points)
	if ring.size()<3: return
	var closure:=float(live_closure.get(index,pocket.closure))
	if _fillable(ring): draw_colored_polygon(ring,Color(THEIRS,0.07+0.08*closure))
	_hatch(ring,Color(THEIRS,0.28),lerpf(18.0,8.0,closure),false)
	var gap_at:=_screen(pocket.gap_at)
	if closure<0.97 and gap_at.is_finite():
		draw_arc(gap_at,10.0,0.0,TAU,20,Color(PAPER,0.7),4.0,true)
		draw_arc(gap_at,10.0,0.0,TAU,20,Color(THEIRS,0.9),1.6,true)
	var centre:=_screen(pocket.centre)
	if centre.is_finite() and band!="world":
		var thousands:=roundi(float(pocket.strength)/1000.0)
		var who:=("about %s thousand" % EraWords.grouped(thousands)) if thousands>=1 else ("about %s" % EraWords.grouped(roundi(float(pocket.strength))))
		var text:=("Pocket: %s cut off" % who) if closure>=0.97 else ("Pocket closing: %s, %s km gap" % [who,EraWords.grouped(maxi(1,roundi(float(pocket.gap))))])
		_request_caption("pocket:%d" % index,pocket.centre,text,THEIRS,5)
	hits.append({"kind":"pocket","poly":ring,"armies":(scene.fronts[index] as Dictionary).get("armies",[]) if index<(scene.get("fronts",[]) as Array).size() else []})


## An arrow as drawn now: a new one draws itself out from its tail, a
## finished one fades where it was (live_arrows).
func _draw_arrow(entry:Dictionary,_t:float,wide:bool)->void:
	var arrow:Dictionary=entry.get("data",entry)
	var alpha:=clampf(float(entry.get("alpha",1.0)),0.0,1.0)
	if alpha<=0.01: return
	var grow:=clampf(float(entry.get("grow",1.0)),0.0,1.0)
	var kind:=String(arrow.get("kind","offensive" if bool(arrow.get("ours",true)) else "enemy"))
	var ours:=bool(arrow.get("ours",true))
	if kind=="siege":
		_draw_siege_arrow(arrow,alpha,grow,wide)
		return
	var world:PackedVector2Array=entry.get("points",arrow.get("points",PackedVector2Array()))
	if grow<1.0: world=_grown(world,grow)
	var points:=_poly(world)
	if points.size()<3: return
	var stale:=bool(arrow.get("stale",false))
	var base:=(5.0 if wide else 7.0)+(6.0 if wide else 11.0)*float(arrow.get("weight",0.5))
	var fill:=Color(OURS_WASH if ours else THEIRS_WASH,0.5 if ours and bool(arrow.get("offensive",false)) else 0.26)
	if kind=="pursuit": fill.a=0.36
	if stale: fill.a*=0.5
	var dashed:=stale or not ours or kind=="pursuit"
	var body:=_ink_arrow(points,base,fill,Color(OURS if ours else THEIRS,0.9) if dashed else Color(INK,0.85),dashed,alpha)
	if kind=="pursuit":
		# A chase: small chevrons running along the shaft toward the quarry.
		for u in [0.3,0.55]:
			var k:=clampi(roundi(float(points.size()-1)*u),1,points.size()-2)
			var ahead:=(points[k+1]-points[k-1]).normalized()
			var side:=ahead.orthogonal()*base*0.34
			draw_polyline(PackedVector2Array([points[k]-ahead*4.0+side,points[k]+ahead*2.0,points[k]-ahead*4.0-side]),Color(INK,0.8*alpha),1.4,true)
	if body.size()>=3:
		hits.append({"kind":"arrow" if ours else "enemy_arrow","poly":body,"line":points,"army_id":int(arrow.get("army_id",0)),"enemy_id":String(arrow.get("enemy_id","")),"seen_day":int(arrow.get("seen_day",-1))})


## A polyline cut to the first `share` of its length (at least three points).
static func _grown(points:PackedVector2Array,share:float)->PackedVector2Array:
	if points.size()<2: return points
	var total:=Model._length(points)
	var cut:=_clip(points,points[0],total*clampf(share,0.0,1.0))
	if cut.size()<2 or Model._length(cut)<=0.0: return PackedVector2Array()
	return Model.resample(cut,maxi(3,roundi(float(points.size()-1)*share)+1))


## A tapered, inked arrow along screen points (HOI4-style plan arrow): a
## paper halo, a wash body and an ink edge (dashed for the uncertain, the
## enemy's and the chase). Returns the body polygon.
func _ink_arrow(points:PackedVector2Array,base:float,fill:Color,edge:Color,dashed:bool,alpha:float)->PackedVector2Array:
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
	if direction==Vector2.ZERO: return PackedVector2Array()
	var wing:=direction.orthogonal()*base*0.75
	var body:=left.duplicate()
	body.append(back+wing); body.append(tip); body.append(back-wing)
	right.reverse(); body.append_array(right)
	var outline:=body.duplicate(); outline.append(body[0])
	draw_polyline(outline,Color(PAPER,0.55*alpha),4.0,true)
	if _fillable(body): draw_colored_polygon(body,Color(fill,fill.a*alpha))
	if dashed: _dashed(outline,Color(edge,edge.a*alpha),1.4,6.0,4.0)
	else: draw_polyline(outline,Color(edge,edge.a*alpha),1.4,true)
	return body


## A siege being laid: a short heavy arrow into the siege ring from the side
## our road comes from (the camp itself stands on the town).
func _draw_siege_arrow(arrow:Dictionary,alpha:float,grow:float,wide:bool)->void:
	var town:Vector2=arrow.get("town",Vector2.INF)
	var from:Vector2=arrow.get("from",Vector2.LEFT)
	if not town.is_finite(): return
	var centre:=_screen(town)
	var probe:=_screen(town+from*_world_per_px(town)*40.0)
	if not centre.is_finite() or not probe.is_finite() or probe.distance_to(centre)<0.5: return
	var out_dir:=(probe-centre).normalized()
	var ring:=36.0
	for siege in scene.get("sieges",[]):
		if (siege.pos as Vector2).distance_to(town)<=_world_per_px(town)*4.0: ring=lerpf(46.0,26.0,float(siege.pressure))*(0.55 if wide else 1.0)
	var reach:=(52.0 if not wide else 30.0)*clampf(grow,0.0,1.0)
	if reach<6.0: return
	var tip:=centre+out_dir*(ring-2.0)
	var tail:=tip+out_dir*reach
	var bend:=out_dir.orthogonal()*reach*0.18
	var points:=PackedVector2Array()
	for k in 13:
		var u:=float(k)/12.0
		points.append(tail.lerp(tail.lerp(tip,0.5)+bend,u).lerp((tail.lerp(tip,0.5)+bend).lerp(tip,u),u))
	var body:=_ink_arrow(points,(9.0 if wide else 14.0),Color(OURS_WASH,0.55),Color(INK,0.85),false,alpha)
	if body.size()>=3: hits.append({"kind":"siege","poly":body,"army_id":int(arrow.get("army_id",0))})


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
	if raid.has("army_id"): hits.append({"kind":"arrow","line":points,"army_id":int(raid.army_id)})


## The forces: inked marks sized for the zoom band, ours from the generals'
## reports and theirs from dated sightings (faded and ringed with dashes
## once the sighting is old, as the front's stale stretches are dashed).
## Crowded marks stack under one, step off the front, and give way to the
## corps and army-group marks that stand for them (hud/army_marks.gd).
func _draw_marks(band:String,echelons_drawn:Array,battles:Array)->void:
	drawn_marks.clear()
	var marks:Array=scene.get("marks",[])
	if marks.is_empty(): return
	var candidates:Array=[]
	for mark in marks:
		var entry:Dictionary=mark.duplicate()
		entry.at=_screen(mark.pos)
		var kind:=String(mark.kind)
		entry.size=ArmyMarks.size_px(band,"band" if kind.begins_with("band") else kind)
		var priority:=int(mark.get("troops",0))
		if bool(mark.get("selected",false)): priority+=1_000_000_000
		if String(mark.side)=="ours": priority+=200_000_000
		if bool(mark.get("moving",false)): priority+=100_000_000
		# A garrison is drawn on its town first; bands beside it give way.
		if bool(mark.get("garrison",false)): priority+=150_000_000
		priority-=int(mark.get("age_days",0))*1_000_000
		entry.priority=priority
		candidates.append(entry)
	var fronts:Array=[]
	for entry in live_fronts:
		if float(entry.alpha)<=0.3: continue
		var line:=_poly(_bulged(entry.points))
		if line.size()>=2: fronts.append(line)
	var clear:Array=[]
	for battle in battles: clear.append({"at":battle.at,"clear":float(battle.get("radius",14.0))+4.0})
	var laid:=ArmyMarks.layout(candidates,{"band":band,"bounds":Rect2(Vector2.ZERO,size),"fronts":fronts,"echelons":echelons_drawn,"home":_screen(scene.get("home",Vector2.ZERO)),
		"battles":clear,"sector_px":float(SECTOR_PX.get(band,0.0))})
	for entry in laid.drawn:
		_draw_mark(entry,band)
		drawn_marks.append(entry)


func _draw_mark(entry:Dictionary,band:String)->void:
	var ours:=String(entry.side)=="ours"
	var at:Vector2=entry.at
	var px:=float(entry.size)
	var age:=int(entry.get("report_age",0)) if ours else int(entry.get("age_days",0))
	var stale:=age>=ArmyMarks.STALE_DAYS
	var alpha:=1.0 if ours else ArmyMarks.fade(age)
	if ours and stale: alpha=0.8
	var ink:=INK if ours else THEIRS.darkened(0.25)
	var accent:=OURS_WASH if ours else THEIRS_WASH
	if not ours and not bool(entry.get("hostile",true)): accent=Color("#b89a5a")
	# A known people's force wears their own colour, as their emblem does.
	elif not ours and CivilizationSystem._civilization_index(String(entry.get("owner","")))>=0: accent=preload("res://scripts/city_map_identity.gd").foreign(String(entry.owner)).accent
	var kind:=String(entry.kind)
	if kind=="band": kind="band:%d" % ArmyMarks.tally(int(entry.get("troops",0)))
	# Where it stepped off the front, a hairline back to where it stands.
	if bool(entry.get("moved",false)) and (entry.anchor as Vector2).distance_to(at)>3.0:
		draw_line(entry.anchor,at,Color(PAPER,0.55*alpha),2.6,true)
		draw_line(entry.anchor,at,Color(ink,0.5*alpha),1.0,true)
		draw_circle(entry.anchor,1.8,Color(ink,0.7*alpha))
	var icon:=Icons.army_texture(kind,String(entry.get("branch","foot")),ink,accent)
	var rect:=Rect2(at-Vector2(px,px)*0.5,Vector2(px,px))
	draw_texture_rect(icon,rect,false,Color(1,1,1,alpha))
	# Staff-map echelon strokes above a formation's box.
	if kind=="formation" and band!="continental":
		# X brigade, XX division, XXX corps, XXXX army: crossed strokes on
		# a paper ground above the box, as a staff map letters them.
		var marks:=ArmyMarks.echelon_marks(int(entry.get("members_troops",entry.get("troops",0))))
		var w:=maxf(4.0,px*0.2)
		var step:=w*1.3
		var left:=at.x-(float(marks-1)*step+w)*0.5
		var bottom:=rect.position.y+px*0.24
		draw_rect(Rect2(left-2.0,bottom-w-2.0,float(marks-1)*step+w+4.0,w+3.0),Color(PAPER,0.75*alpha))
		for k in marks:
			var x:=left+float(k)*step
			draw_line(Vector2(x,bottom-w),Vector2(x+w,bottom),Color(ink,0.95*alpha),1.5,true)
			draw_line(Vector2(x+w,bottom-w),Vector2(x,bottom),Color(ink,0.95*alpha),1.5,true)
	if stale: _dashed(_ring_points(at,px*0.62,20),Color(ink,0.7*alpha),1.2,3.0,3.0)
	if bool(entry.get("selected",false)):
		draw_arc(at,px*0.66,0.0,TAU,28,Color(PAPER,0.8),3.4,true)
		draw_arc(at,px*0.66,0.0,TAU,28,T.GOLD,1.6,true)
	# The counter (HOI4-style, inked): strength and will to fight under the
	# mark, one state glyph at its shoulder.
	var counter:=ArmyMarks.counter(entry)
	var bar_width:=maxf(22.0,px*1.05)
	if not counter.is_empty(): BattleMarks.draw_counter(self,Vector2(at.x-bar_width*0.5,rect.end.y+2.0),bar_width,counter,accent,alpha)
	var state:=String(entry.get("state",""))
	if state!="":
		var heading:Vector2=entry.get("heading",Vector2.ZERO)
		var ahead:=Vector2.RIGHT
		if heading.length_squared()>0.0:
			var probe:=_screen((entry.pos as Vector2)+heading.normalized()*_world_per_px(entry.pos)*20.0)
			if probe.is_finite() and _screen(entry.pos).is_finite(): ahead=(probe-_screen(entry.pos)).normalized()
		BattleMarks.draw_state(self,at+Vector2(-px*0.5-2.0,-px*0.2),state,maxf(5.0,px*0.22),alpha,ahead)
	var members:=(entry.get("members",[]) as Array).size()
	if members>1:
		var badge:=at+Vector2(px*0.5+2.0,-px*0.2)
		draw_circle(badge,7.0,Color(PAPER,0.95))
		draw_arc(badge,7.0,0.0,TAU,16,Color(ink,0.8),1.0,true)
		var font:=T.voice_font(false)
		var text:=str(members)
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		draw_string(font,badge+Vector2(-width*0.5,4.5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(ink,0.95))
		# Far out, the stretch of front's forces are lettered in one line.
		if bool(entry.get("sector",false)) and not bool(entry.get("card",false)): _request_caption("sector:%s" % String(entry.id),Vector2.INF,ArmyMarks.sector_words(entry),OURS if ours else THEIRS,3 if ours else 2,px*0.62+6.0,at,"letter")
	if bool(entry.get("card",false)): _request_caption("mark:%s" % String(entry.id),Vector2.INF,"\n".join(_card_lines(entry)),OURS if ours else THEIRS,5 if bool(entry.get("selected",false)) else (3 if ours else 2),px*0.62+4.0,at)
	if bool(entry.get("garrison",false)): pass
	elif ours: hits.append({"kind":"army","centre":at,"radius":maxf(12.0,px*0.6),"army_id":int(entry.army_id),"mark":true})
	else:
		var sighting:Dictionary=(entry.get("sighting",{}) as Dictionary).duplicate()
		sighting["noun"]=String(entry.get("noun","host"))
		hits.append({"kind":"sighting","centre":at,"radius":maxf(12.0,px*0.6),"sighting":sighting,"observed":bool(entry.get("observed",false)),"enemy_id":String(entry.get("enemy_id","")),"mark":true})


func _card_lines(entry:Dictionary)->PackedStringArray:
	var members:=(entry.get("members",[]) as Array).size()
	var data:=entry.duplicate()
	data.members=members
	if bool(entry.get("garrison",false)) and members<=1: return ArmyMarks.card_garrison(data)
	if String(entry.side)=="ours": return ArmyMarks.card_ours(data)
	if members>1:
		data.low=int(entry.get("members_low",entry.get("low",0))); data.high=int(entry.get("members_high",entry.get("high",0)))
	return ArmyMarks.card_theirs(data)


static func _ring_points(at:Vector2,radius:float,count:int)->PackedVector2Array:
	var out:=PackedVector2Array()
	for k in count+1: out.append(at+Vector2.from_angle(TAU*float(k)/float(count))*radius)
	return out


## The army or sighting mark drawn under a screen point (for the map's own
## selection and contact clicks): {kind:"army", army_id} or {kind:"sighting",
## enemy_id, observed}, or {} when there is none.
func mark_at(point:Vector2)->Dictionary:
	var best:={}; var best_distance:=INF
	for hit in hits:
		if not bool(hit.get("mark",false)): continue
		var d:=(hit.centre as Vector2).distance_to(point)
		if d<=float(hit.radius) and d<best_distance: best_distance=d; best=hit
	return best


## Where a force's mark is drawn now (screen), or Vector2.INF.
func mark_screen_position(side:String,id:String)->Vector2:
	for entry in drawn_marks:
		if String(entry.side)!=side: continue
		if side=="ours" and str(int(entry.army_id))==id: return entry.at
		if side=="theirs" and String(entry.get("enemy_id",""))==id: return entry.at
	return Vector2.INF


## Remember battles that were not in the last scene, to ring them once.
func _note_new_clashes(before:Dictionary,after:Dictionary)->void:
	if preload("res://scripts/hud/motion.gd").reduced():return
	var known:={}
	for clash in before.get("clashes",[]):known[_clash_key(clash.pos)]=true
	for clash in after.get("clashes",[]):
		if known.has(_clash_key(clash.pos)):continue
		clash_pulses.append({"pos":clash.pos,"t":0.0})
	while clash_pulses.size()>MAX_CLASH_PULSES:clash_pulses.pop_front()

static func _clash_key(pos:Vector2)->Vector2i:
	# Contacts drift a little day to day; the same battle keeps its key.
	return Vector2i(roundi(pos.x/2.0),roundi(pos.y/2.0))

## Two fine rings spreading from the contact and fading: brief and quiet.
func _draw_clash_pulse(pulse:Dictionary,wide:bool)->void:
	var at:=_screen(pulse.pos)
	if not at.is_finite():return
	var reach:=26.0 if wide else 44.0
	for ring in 2:
		var k:=clampf((float(pulse.t)-0.28*float(ring))/(CLASH_PULSE_SECONDS-0.28),0.0,1.0)
		if k<=0.0 or k>=1.0:continue
		var spread:=1.0-pow(1.0-k,3.0)
		var fade:=(1.0-k)*(1.0-k)
		draw_arc(at,lerpf(6.0,reach,spread),0.0,TAU,40,Color(PAPER,0.5*fade),3.2,true)
		draw_arc(at,lerpf(6.0,reach,spread),0.0,TAU,40,Color(THEIRS,0.85*fade),1.4,true)

func _crossed_strokes(at:Vector2,size_px:float,color:Color)->void:
	draw_line(at+Vector2(-size_px,-size_px),at+Vector2(size_px,size_px),Color(PAPER,0.6*color.a),4.0,true)
	draw_line(at+Vector2(-size_px,size_px),at+Vector2(size_px,-size_px),Color(PAPER,0.6*color.a),4.0,true)
	draw_line(at+Vector2(-size_px,-size_px),at+Vector2(size_px,size_px),color,2.2,true)
	draw_line(at+Vector2(-size_px,size_px),at+Vector2(size_px,-size_px),color,2.2,true)


func _draw_siege(siege:Dictionary,wide:bool)->void:
	var centre:=_screen(siege.pos)
	if not centre.is_finite(): return
	# The ring tightens as the siege bites; it stays clear of the town's own
	# pin (the city card owns the middle).
	var radius:=lerpf(46.0,26.0,float(siege.pressure))*(0.55 if wide else 1.0)
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
	# A siege with its own battle mark is lettered there ("Siege of Tsaren ·
	# day 12"); the ring alone names its works.
	if not wide and not bool(siege.get("marked",false)): _request_caption("siege:%s" % str(siege.pos),siege.pos,"%s · day %d" % [String(siege.label),int(siege.get("days",0))] if int(siege.get("days",0))>0 else String(siege.label),color,4,radius+6.0)
	hits.append({"kind":"siege","centre":centre,"radius":radius+6.0,"army_id":int(siege.get("army_id",0))})


## A clash and the tactic being fought there, drawn in screen space around
## the contact so it reads at every zoom. Shapes follow battle_tactics.shape.
func _draw_clash(clash:Dictionary,band:String)->void:
	var at:=_screen(clash.pos)
	if not at.is_finite(): return
	if bool(clash.get("finished",false)):
		# A fight already over: a quiet mark fading with the days, and how it went.
		var fade:=clampf(1.0-float(clash.get("age",0))/float(RECENT_BATTLE_DAYS+1),0.35,1.0)
		_crossed_strokes(at,5.0,Color(THEIRS,0.85*fade))
		draw_arc(at,9.0,0.0,TAU,24,Color(INK,0.55*fade),1.2,true)
		if band!="world": _request_caption("battle:%d" % int(clash.get("seed",0)),clash.pos,String(clash.get("result","")),INK,5,14.0)
		hits.append({"kind":"clash","centre":at,"radius":14.0,"army_id":int(clash.get("army_id",0)),"clash":clash})
		return
	# The diagram is sized to the fighting it shows: about half the gap
	# between the two sides on screen, never larger than a local close-up.
	var sigma:=float(scene.get("sigma",1.0))
	var reach:=_screen((clash.pos as Vector2)+(clash.axis as Vector2)*sigma)
	var sigma_px:=reach.distance_to(at) if reach.is_finite() else 80.0
	var r:=clampf(sigma_px*0.45,12.0,56.0 if band=="local" else 40.0)
	# A battle mark (hud/battle_marks.gd) stands for this fight: it carries
	# the crossed weapons, the name and the day; the diagram only shows the
	# shape of the tactic around it, up close.
	var marked:=(scene.get("fought",{}) as Dictionary).has(int(clash.get("army_id",0)))
	if bool(clash.get("skirmish",false)):
		if marked: return
		# A handful caught by a band: a skirmish mark between the two inked
		# marks, not two opposed battle lines.
		_crossed_strokes(at,5.0,Color(THEIRS,0.95))
		draw_arc(at,8.0,0.0,TAU,20,Color(INK,0.6),1.1,true)
		hits.append({"kind":"clash","centre":at,"radius":12.0,"army_id":int(clash.get("army_id",0)),"clash":clash})
		return
	if band in ["continental","world"] or r<20.0:
		if marked: return
		# Far out, a battle is a mark on the line, not a diagram.
		_crossed_strokes(at,6.0,Color(THEIRS,0.95))
		if band!="world" and String(clash.get("label",""))!="": _request_caption("clash:%s" % str(clash.pos),clash.pos,String(clash.label),INK,5,12.0)
		hits.append({"kind":"clash","centre":at,"radius":12.0,"army_id":int(clash.get("army_id",0)),"clash":clash})
		return
	var ahead:=_screen((clash.pos as Vector2)+(clash.axis as Vector2)*0.01)
	var axis:=(ahead-at).normalized() if ahead.is_finite() and ahead.distance_to(at)>0.001 else Vector2.RIGHT
	var across:=axis.orthogonal()
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
	if not marked: _crossed_strokes(at,6.0,Color(THEIRS,0.95))
	if String(clash.get("label",""))!="": _request_caption("clash:%s" % str(clash.pos),clash.pos,String(clash.label),INK,4 if marked else 5,r+8.0)
	hits.append({"kind":"clash","centre":at,"radius":r*0.8,"army_id":int(clash.get("army_id",0)),"clash":clash})


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
	var head:=PackedVector2Array([tip+direction*6.0,tip+direction.orthogonal()*4.0,tip-direction.orthogonal()*4.0])
	if _fillable(head): draw_colored_polygon(head,Color(OURS,0.9*alpha))


## Hatching as one batch of segments (drawn with a single call).
static func _hatch_segments(polygon:PackedVector2Array,spacing:float,cross:bool)->Array:
	var main:=PackedVector2Array(); var other:=PackedVector2Array()
	var box:=Rect2(polygon[0],Vector2.ZERO)
	for p in polygon: box=box.expand(p)
	var lines:=0
	var x:=box.position.x-box.size.y
	while x<box.end.x and lines<60:
		for piece in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([Vector2(x,box.end.y),Vector2(x+box.size.y,box.position.y)]),polygon):
			for i in range(1,piece.size()): main.append(piece[i-1]); main.append(piece[i])
		if cross:
			for piece in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([Vector2(x,box.position.y),Vector2(x+box.size.y,box.end.y)]),polygon):
				for i in range(1,piece.size()): other.append(piece[i-1]); other.append(piece[i])
		x+=spacing; lines+=1
	return [main,other]


func _hatch(polygon:PackedVector2Array,color:Color,spacing:float,cross:bool)->void:
	var segments:=_hatch_segments(polygon,spacing,cross)
	if (segments[0] as PackedVector2Array).size()>=2: draw_multiline(segments[0],color,1.1)
	if (segments[1] as PackedVector2Array).size()>=2: draw_multiline(segments[1],Color(color,color.a*0.7),1.0)


func _draw_zone(zone:Dictionary,band:String)->void:
	var vertices:PackedVector2Array=zone.vertices
	var navy:=String(zone.domain)=="navy"
	var own:=SEA if navy else SKY
	var hatch_ink:=SEA_LIGHT if navy else SKY
	var control:=clampf(float(zone.get("control",0.0)),0.0,1.0)
	var shape:=String(zone.get("shape",""))
	# The zone's draped outline and hatching change only with the camera or
	# the zone; while a front eases they are drawn from this cache.
	var key:=hash([view_key,vertices,snappedf(control,0.02),shape])
	if not zone_cache.has(key):
		if zone_cache.size()>32: zone_cache.clear()
		var draped:=PackedVector2Array()
		var closed:=vertices.duplicate(); closed.append(vertices[0])
		for run in _drape(closed,_world_per_px(vertices[0])*14.0): draped.append_array(run)
		var cached:={"polygon":draped,"hatch":[]}
		if draped.size()>=3 and (shape in ["hatch","interception","cordon","cordon_wide","pack","battle_line","convoy","crossing"] or not navy):
			cached.hatch=_hatch_segments(draped,lerpf(22.0,9.0,control),shape=="interception")
		zone_cache[key]=cached
	var polygon:PackedVector2Array=zone_cache[key].polygon
	if polygon.size()<3: return
	# Contested water or air: our wash where we hold it, theirs where we do not.
	if _fillable(polygon):
		draw_colored_polygon(polygon,Color(own,0.08+0.12*control))
		if control<0.95: draw_colored_polygon(polygon,Color(THEIRS,0.06*(1.0-control)))
	var outline:=polygon.duplicate(); outline.append(polygon[0])
	draw_polyline(outline,Color(PAPER,0.45),3.6,true)
	_dashed(outline,Color(own,0.95),1.6,8.0,5.0)
	# Hatching whose density follows how firmly the zone is held.
	var hatch:Array=zone_cache[key].hatch
	if not hatch.is_empty():
		var ink:=Color(hatch_ink,0.42 if navy else 0.38)
		if (hatch[0] as PackedVector2Array).size()>=2: draw_multiline(hatch[0],ink,1.1)
		if (hatch[1] as PackedVector2Array).size()>=2: draw_multiline(hatch[1],Color(ink,ink.a*0.7),1.0)
	if bool(zone.get("belt",false)):
		# The air-defence belt: a double rim with ticks facing out, where
		# fighters meet raiders before they reach what lies inside.
		var centre:=_centre(polygon)
		var inner:=PackedVector2Array()
		for p in outline: inner.append(p.lerp(centre,0.1))
		draw_polyline(inner,Color(SKY,0.8),1.4,true)
		var ticks:=0
		for i in range(1,outline.size(),2):
			var a:=outline[i-1]; var b:=outline[i]
			var out_dir:=((a+b)*0.5-centre).normalized()
			draw_line((a+b)*0.5,(a+b)*0.5+out_dir*7.0,Color(SKY,0.9),1.6,true)
			ticks+=1
			if ticks>=48: break
	var centre:=_centre(polygon)
	var base:Vector2=zone.get("base",Vector2.INF)
	if base.is_finite() and shape in ["sortie_arc","bombing_route","support","interdiction","airlift","hatch","interception","watch"]:
		# Sortie arcs from the airfield to the zone.
		var from:=_screen(base)
		if from.is_finite():
			var delta:=centre-from
			var arc:=PackedVector2Array()
			for k in 17:
				var u:=float(k)/16.0
				arc.append(from.lerp(centre,u)+delta.orthogonal().normalized()*sin(u*PI)*minf(60.0,delta.length()*0.2))
			_dashed(arc,Color(own,0.85),1.4,6.0,5.0)
			if shape=="interception":
				# Watchers on the ground directing the fighters: rings at the base.
				for k in 3: draw_arc(from,8.0+6.0*k,-0.9,0.9,10,Color(SKY,0.7-0.2*k),1.2,true)
	var port:Vector2=zone.get("port",Vector2.INF)
	var blockade:Dictionary=zone.get("blockade",{})
	if port.is_finite():
		# A blockade cordon across the harbour mouth, closing as it bites.
		var at:=_screen(port)
		if at.is_finite():
			var level:=float(blockade.get("level",0.0))
			var reach:=(26.0 if shape=="cordon" else 48.0)*(0.7 if band!="regional" else 1.0)
			var facing:=(centre-at).angle()
			var span:=1.1+0.9*clampf(level/Blockade.CLOSE_CAP,0.0,1.0)
			draw_arc(at,reach,facing-span,facing+span,24,Color(PAPER,0.6),5.0,true)
			var pickets:=9+int(8.0*clampf(level/Blockade.CLOSE_CAP,0.0,1.0))
			for k in pickets:
				var angle:=facing-span+2.0*span*float(k)/float(maxi(1,pickets-1))
				draw_circle(at+Vector2.from_angle(angle)*reach,2.6,Color(PAPER,0.8))
				draw_circle(at+Vector2.from_angle(angle)*reach,2.0,Color(own,0.95))
			draw_arc(at,reach,facing-span,facing+span,24,Color(own,0.9),1.4,true)
			if not blockade.is_empty() and band=="regional": _request_caption("blockade:%d" % int(zone.get("force_id",0)),port,String(blockade.get("text","")),own,3,reach+6.0)
	for contact in zone.get("contacts",[]):
		var at:=_screen(contact.pos)
		if not at.is_finite(): continue
		var alpha:=clampf(1.0-float(contact.age)/6.0,0.35,1.0)
		draw_arc(at,6.0,0.0,TAU,16,Color(PAPER,0.5*alpha),3.0,true)
		draw_arc(at,6.0,0.0,TAU,16,Color(THEIRS,alpha),1.6,true)
	if String(zone.get("label",""))!="" and band!="world": _request_caption("zone:%d" % int(zone.get("force_id",0)),_unscreen_centre(vertices),String(zone.label),own.darkened(0.2),3,6.0)
	hits.append({"kind":"zone","poly":polygon,"force_id":int(zone.get("force_id",0)),"zone":zone})


static func _unscreen_centre(vertices:PackedVector2Array)->Vector2:
	var total:=Vector2.ZERO
	for p in vertices: total+=p
	return total/float(maxi(1,vertices.size()))


## A convoy lane: the water (or air) still to cross, with escort ticks where
## escorts work it and a raider's warning where raiders do.
func _draw_lane(lane:Dictionary,step:float)->void:
	var navy:=String(lane.get("domain","navy"))=="navy"
	var color:=Color(SEA if navy else SKY,0.9)
	for run in _drape(lane.points,step):
		draw_polyline(run,Color(PAPER,0.55),4.0,true)
		_dashed(run,color,1.6,9.0,4.0)
		if bool(lane.get("escorted",false)):
			var walked:=0.0
			for i in range(1,run.size()):
				var a:Vector2=run[i-1]; var b:Vector2=run[i]
				walked+=a.distance_to(b)
				if walked>=26.0:
					walked=0.0
					var across:Vector2=(b-a).normalized().orthogonal()
					draw_line(b-across*5.0,b+across*5.0,color,1.6,true)
		var head:Vector2=run[0]
		draw_circle(head,4.5,Color(PAPER,0.9)); draw_circle(head,3.2,color)
		if bool(lane.get("raided",false)): _crossed_strokes(head+Vector2(10,-10),4.0,Color(THEIRS,0.9))
		hits.append({"kind":"lane","line":run,"lane":lane})


## Our own harbour under a rival's blockade: their cordon, in their ink.
func _draw_harbour(harbour:Dictionary,wide:bool=false)->void:
	var at:=_screen(harbour.pos)
	if not at.is_finite(): return
	var level:=float(harbour.get("level",0.0))
	var reach:=34.0
	var span:=0.9+1.2*clampf(level/Blockade.CLOSE_CAP,0.0,1.0)
	draw_arc(at,reach,-PI*0.5-span,-PI*0.5+span,24,Color(PAPER,0.6),5.0,true)
	_dashed(PackedVector2Array(range(25).map(func(k:int)->Vector2: return at+Vector2.from_angle(-PI*0.5-span+2.0*span*float(k)/24.0)*reach)),Color(THEIRS,0.9),1.6,5.0,4.0)
	if not wide: _request_caption("harbour:%s" % str(harbour.pos),harbour.pos,String(harbour.get("text","")),THEIRS,4,reach+6.0)
	hits.append({"kind":"harbour","centre":at,"radius":reach,"harbour":harbour})


## A corps, army or army group at continental scale: a small inked plate
## with its echelon marks above, as on a staff map.
func _draw_echelon(echelon:Dictionary,band:String)->void:
	var at:=_screen(echelon.pos)
	if not at.is_finite(): return
	var plate:=Rect2(at-Vector2(15,10),Vector2(30,20))
	draw_rect(plate.grow(2.0),Color(PAPER,0.85))
	draw_rect(plate,Color(OURS_WASH,0.35))
	draw_rect(plate,Color(INK,0.9),false,1.4)
	draw_line(plate.position,plate.end,Color(INK,0.85),1.2,true)
	draw_line(Vector2(plate.position.x,plate.end.y),Vector2(plate.end.x,plate.position.y),Color(INK,0.85),1.2,true)
	var marks:=5 if bool(echelon.get("group",false)) else clampi(int(echelon.level)-4,2,4)
	var mark_width:=6.0
	var left:=at.x-float(marks)*mark_width*0.5
	for k in marks:
		var x:=left+float(k)*mark_width
		draw_line(Vector2(x,plate.position.y-10),Vector2(x+4,plate.position.y-4),Color(INK,0.9),1.3,true)
		draw_line(Vector2(x+4,plate.position.y-10),Vector2(x,plate.position.y-4),Color(INK,0.9),1.3,true)
	if band!="world": _request_caption("echelon:%s" % String(echelon.id),echelon.pos,"%s · %s" % [String(echelon.name),EraWords.grouped(int(echelon.get("troops",0)))],INK,4,22.0)
	hits.append({"kind":"echelon","centre":at,"radius":20.0,"echelon":echelon})


# --- Captions: lettered around what the chart already shows -----------------------

## style: "card" (a small paper card) or "letter" (ink lettered straight on
## the chart with a paper halo, as a battle's name and day are).
func _request_caption(id:String,world:Vector2,text:String,color:Color,priority:int,clear:float=10.0,screen_anchor:=Vector2.INF,style:="card")->void:
	if text=="": return
	var at:=screen_anchor if screen_anchor.is_finite() else _screen(world)
	if not at.is_finite(): return
	caption_requests.append({"id":id,"anchor":at,"text":text,"color":color,"priority":priority,"clear":clear,"style":style})


func _caption_size(text:String,font:Font,style:="card")->Vector2:
	var key:=style+"|"+text
	if not caption_extent.has(key):
		if caption_extent.size()>256: caption_extent.clear()
		if style=="letter":
			caption_extent[key]=Vector2(ceilf(T.font("ui").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,BattleMarks.LABEL_SIZE).x)+10.0,20.0)
			return caption_extent[key]
		# A card has a title line and a smaller detail line beneath it.
		var lines:=text.split("\n")
		var width:=font.get_string_size(lines[0],HORIZONTAL_ALIGNMENT_LEFT,-1,CAPTION_SIZE).x
		for k in range(1,lines.size()): width=maxf(width,font.get_string_size(lines[k],HORIZONTAL_ALIGNMENT_LEFT,-1,CARD_DETAIL_SIZE).x)
		caption_extent[key]=Vector2(ceilf(minf(420.0,width))+14.0,22.0+16.0*float(lines.size()-1))
	return caption_extent[key]


## Everything the captions must keep clear of: city cards and pins, great
## works, the war tags, army and contact counters, and the open note.
func _caption_obstacles()->Dictionary:
	var rects:Array[Rect2]=[]
	var pins:Array=[]
	var bounds:=Rect2(Vector2(90,100),(size-Vector2(110,170)).max(Vector2(100,100)))
	var cities:=_city_labels()
	if cities!=null and cities.has_method("chart_obstacles"):
		var chart:Dictionary=cities.chart_obstacles()
		rects.append_array(chart.rects); pins.append_array(chart.pins)
		if (chart.bounds as Rect2).has_area(): bounds=chart.bounds
	var tags:Variant=get_parent().get_node_or_null("WarMapOverlay") if get_parent()!=null else null
	if tags!=null:
		for tag:Dictionary in tags.get("tags"): rects.append(tag.rect)
	for entry in drawn_marks: pins.append({"at":entry.at,"clear":float(entry.size)*0.62+2.0})
	# Battle marks, and the bar hanging beneath each.
	for entry in battle_cache:
		rects.append(entry.rect)
		pins.append({"at":entry.at,"clear":float(entry.radius)+2.0})
	if note!=null and note.visible: rects.append(note.get_global_rect())
	return {"rects":rects,"pins":pins,"bounds":bounds}


func _letter_captions(font:Font)->void:
	placed_captions.clear()
	dropped_captions=0
	if caption_requests.is_empty(): return
	var notes:Array=[]
	for request in caption_requests:
		var entry:Dictionary=request.duplicate()
		entry.extent=_caption_size(String(request.text),font,String(request.get("style","card")))
		notes.append(entry)
	var obstacles:=_caption_obstacles()
	var result:=CityLabels.place_notes(notes,obstacles.bounds,obstacles.rects,obstacles.pins,caption_memory)
	caption_memory=result.memory
	placed_captions=result.notes
	dropped_captions=(result.dropped as Array).size()
	for caption in placed_captions:
		var box:Rect2=caption.rect
		var anchor:Vector2=caption.anchor
		if String(caption.get("style","card"))=="letter":
			# Lettered straight on the chart, beside its mark.
			BattleMarks.letter(self,T.font("ui"),box.position+Vector2(5.0,15.0),String(caption.text),BattleMarks.LABEL_SIZE,INK)
			continue
		var end:=Vector2(clampf(anchor.x,box.position.x,box.end.x),clampf(anchor.y,box.position.y,box.end.y))
		if end.distance_to(anchor)>float(caption.clear)+4.0:
			var start:=anchor+(end-anchor).normalized()*float(caption.clear)*0.6
			draw_line(start,end,Color(PAPER,0.6),3.0,true)
			draw_line(start,end,Color(INK,0.5),1.0,true)
		draw_style_box(_caption_style(),box)
		var color:Color=caption.color
		draw_rect(Rect2(box.position+Vector2(0,3),Vector2(2,box.size.y-6)),Color(color,0.85))
		var lines:=String(caption.text).split("\n")
		draw_string(font,box.position+Vector2(7,16),lines[0],HORIZONTAL_ALIGNMENT_LEFT,box.size.x-10,CAPTION_SIZE,Color(INK,0.95))
		for k in range(1,lines.size()):
			draw_string(font,box.position+Vector2(7,16+16*k),lines[k],HORIZONTAL_ALIGNMENT_LEFT,box.size.x-10,CARD_DETAIL_SIZE,Color(INK,0.7))


var _style:StyleBoxFlat
func _caption_style()->StyleBoxFlat:
	if _style==null:
		_style=StyleBoxFlat.new(); _style.bg_color=Color(T.PAPER_RAISED,0.92); _style.border_color=Color(T.RULE,0.9)
		_style.set_border_width_all(1); _style.set_corner_radius_all(T.RADIUS_CONTROL)
		_style.shadow_color=Color(0,0,0,0.08); _style.shadow_size=2; _style.shadow_offset=Vector2(0,1)
	return _style


# --- Clicks: a note about the thing, and who to talk to -----------------------------

static func _distance_to_line(point:Vector2,line:PackedVector2Array)->float:
	var best:=INF
	for i in range(1,line.size()): best=minf(best,Geometry2D.get_closest_point_to_segment(point,line[i-1],line[i]).distance_to(point))
	return best


## What the last drawing shows under a screen point (nearest wins).
func hit_at(point:Vector2)->Dictionary:
	var best:={}
	var best_score:=INF
	for hit in hits:
		var score:=INF
		if hit.has("centre"):
			var d:=(hit.centre as Vector2).distance_to(point)
			if d<=float(hit.radius): score=d*0.5
		if hit.has("poly") and score==INF and Geometry2D.is_point_in_polygon(point,hit.poly): score=12.0 if String(hit.kind) in ["zone","pocket"] else 2.0
		if hit.has("line") and score==INF:
			var d:=_distance_to_line(point,hit.line)
			if d<=9.0: score=d+(0.0 if String(hit.kind) in ["front","arrow"] else 3.0)
		if score<best_score: best_score=score; best=hit
	return best


func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		if not battle_cache.is_empty() or (tip!=null and tip.visible): _hover((event as InputEventMouseMotion).position)
		return
	var press:bool=event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT
	if not press:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and note!=null and note.visible: close_note()
		return
	if note!=null and note.visible and note.get_global_rect().has_point(event.position): return
	if get_viewport().gui_get_hovered_control()!=null: return
	# A battle's mark stands over the forces fighting it: it opens the battle.
	var battle:=battle_at(event.position)
	if not battle.is_empty():
		open_battle(battle,event.position)
		get_viewport().set_input_as_handled()
		return
	# An army mark keeps its own click (selection); its general's note opens too.
	var army_id:=_army_counter_at(event.position)
	if army_id>0:
		open_note({"kind":"army","army_id":army_id},event.position)
		return
	# A host in sight right now opens its contact card on the map instead.
	var mark:=mark_at(event.position)
	if String(mark.get("kind",""))=="sighting" and bool(mark.get("observed",false)): return
	var hit:=hit_at(event.position)
	if hit.is_empty():
		if note!=null and note.visible: close_note()
		return
	open_note(hit,event.position)
	get_viewport().set_input_as_handled()


func _army_counter_at(point:Vector2)->int:
	var mark:=mark_at(point)
	return int(mark.get("army_id",0)) if String(mark.get("kind",""))=="army" else 0


func close_note()->void:
	if note!=null: note.hide()
	note_about={}


## Plain words about what was clicked, and whom to send for. Pure over the
## live ledgers: {kicker, title, lines:[String], action:{label, kind, target}}.
func note_content(hit:Dictionary)->Dictionary:
	var stage:=String(scene.get("stage",EraWords.stage()))
	match String(hit.get("kind","")):
		"zone":
			var zone:Dictionary=hit.get("zone",{})
			var navy:=String(zone.get("domain",""))=="navy"
			var lines:Array=[]
			if String(zone.get("status",""))!="": lines.append(String(zone.status)+".")
			lines.append("Holds about %d%% of this %s." % [roundi(float(zone.get("control",0.0))*100.0),"water" if navy else "sky"])
			if String(zone.get("tactic",""))!="": lines.append("The commander's way of working it: %s." % Tactics.name_of(String(zone.tactic),stage))
			var blockade:Dictionary=zone.get("blockade",{})
			if not blockade.is_empty(): lines.append(String(blockade.get("text","")))
			var contacts:=(zone.get("contacts",[]) as Array).size()
			if contacts>0: lines.append("%s sighted there in the last six days." % ("One contact" if contacts==1 else "%d contacts" % contacts))
			return {"kicker":("FLEET" if navy else "AIR ARM")+" · "+String(zone.get("mission","")).replace("_"," ").to_upper(),"title":String(zone.get("name","")),"lines":lines,"action":_branch_leader("navy" if navy else "air")}
		"lane":
			var lane:Dictionary=hit.get("lane",{})
			var lines:=["%s, %s." % ["An invasion convoy" if bool(lane.get("invasion",false)) else "A supply convoy",String(lane.get("status","")).replace("_"," ")]]
			lines.append("Escorts work these waters." if bool(lane.get("escorted",false)) else "No escort works these waters.")
			if bool(lane.get("raided",false)): lines.append("Raiders have been reported on its lane.")
			return {"kicker":"CONVOY","title":String(lane.get("name","Convoy")),"lines":lines,"action":_branch_leader(String(lane.get("domain","navy")))}
		"harbour":
			var harbour:Dictionary=hit.get("harbour",{})
			return {"kicker":"OUR HARBOUR","title":"Blockaded","lines":[String(harbour.get("text",""))],"action":_branch_leader("navy")}
		"echelon":
			var echelon:Dictionary=hit.get("echelon",{})
			var what:String="Army group" if bool(echelon.get("group",false)) else ["Corps","Army"][clampi(int(echelon.level)-CORPS_LEVEL,0,1)]
			var armies:Array=echelon.get("armies",[])
			var lines:=["%s under one command: %s hosts, about %s under arms." % [what,EraWords.grouped(armies.size()),EraWords.grouped(int(echelon.get("troops",0)))]]
			return {"kicker":what.to_upper(),"title":String(echelon.name),"lines":lines,"action":_general_action(int(armies[0]) if not armies.is_empty() else 0)}
		"sighting":
			var seen:Dictionary=hit.get("sighting",{})
			var ago:=int(seen.get("age_days",0))
			var word:=String(seen.get("noun","host"))
			var low:=int(seen.get("low",roundi(float(seen.get("strength",0.0))))); var high:=int(seen.get("high",low))
			var when:="today" if ago==0 else ("yesterday" if ago==1 else "%s days ago" % (EraWords.count_word(ago) if ago<=12 else str(ago)))
			var lines:=["%s under arms when last seen, %s." % [_cap(ArmyMarks.about_range(low,high)),when]]
			lines.append("Seen on the move." if bool(seen.get("moving",false)) else "Seen encamped.")
			lines.append("Where they are now, no one here knows." if ago>=ArmyMarks.FRESH_DAYS else "Our watchers still have them in sight.")
			var title:=String(seen.get("name",seen.get("owner","")))
			return {"kicker":"THEIR %s" % word.to_upper(),"title":title if title!="" else "Their %s" % word,"lines":lines,"action":_general_action(int(GeneralCampaign.state.get("army_id",-1)) if GeneralCampaign.active else 0)}
		"enemy_arrow":
			var ago:=maxi(0,int(scene.get("today",0))-int(hit.get("seen_day",0)))
			return {"kicker":"THEIR MOVEMENT","title":"Seen marching","lines":["Seen on the move %s." % ("today" if ago==0 else ("%d days ago" % ago)),"Nothing newer has reached us."],"action":{}}
		"front","fallback","pocket":
			var armies:Array=hit.get("armies",[])
			var lines:Array=[]
			if String(hit.kind)=="front":
				lines.append("Where our hosts and theirs meet, drawn from where each was last reported.")
				if bool(hit.get("stale",false)): lines.append("Part of their line is known only from old reports.")
			elif String(hit.kind)=="fallback":
				lines.append("Where the generals would fall back if the line gives: a day's march along their road home.")
			else:
				lines.append("Their host is almost ringed by ours; the gap is what they can still escape through.")
			var content:=_army_content(int(armies[0]) if not armies.is_empty() else 0,stage)
			content.lines=lines+(content.lines as Array)
			if armies.size()>1: content.kicker="FRONT · %d HOSTS" % armies.size()
			return content
		"battle":
			var battle:Dictionary=hit.get("battle",{})
			var lines:Array=[String(battle.get("hover",BattleMarks.hover_line(battle)))+"."]
			if bool(battle.get("ours",false)):
				var content:=_army_content(int(battle.get("army_id",0)),stage)
				content.lines=lines+(content.lines as Array)
				content.kicker="BATTLE"
				content["second"]={"label":"Watch the battle","kind":"battle","battle":battle}
				return content
			var age:=int(battle.get("age_days",0))
			lines.append("Our watchers saw it %s. Nothing newer has reached us." % ("today" if age==0 else ("yesterday" if age==1 else "%s days ago" % EraWords.count_word(age))))
			return {"kicker":"THEIR BATTLE","title":String(battle.get("place_name","A battle")),"lines":lines,"action":_marshal_action()}
		"battles":
			var battles:Array=hit.get("battles",[])
			var lines:Array=[]
			var largest:Dictionary={}
			for battle in battles.slice(0,6):
				var push:=BattleMarks.push_words(battle)
				lines.append("%s: %s." % [String(battle.get("place_name","")),push.substr(0,1).to_lower()+push.substr(1)])
				if bool(battle.get("ours",false)) and (largest.is_empty() or _battle_men(battle)>_battle_men(largest)): largest=battle
			var action:Dictionary={"label":"Watch the largest battle","kind":"battle","battle":largest} if not largest.is_empty() else _marshal_action()
			return {"kicker":"BATTLES","title":BattleMarks.aggregate_label(battles.size()),"lines":lines,"action":action}
		"clash":
			var clash:Dictionary=hit.get("clash",{})
			if bool(clash.get("finished",false)): return _finished_note(clash)
			var content:=_army_content(int(clash.get("army_id",0)),stage)
			var lines:Array=[]
			var ours:=String(clash.get("ours",Tactics.BASELINE)); var theirs:=String(clash.get("theirs",Tactics.BASELINE))
			lines.append(Tactics.report_sentence({"attacker":{"id":ours},"defender":{"id":theirs}},"attacker",stage))
			if int(clash.get("rounds",0))>0: lines.append("%d exchanges fought so far." % int(clash.rounds))
			if bool(clash.get("commanded",false)): lines.append("Fought under the command staff's plan, alongside the other battles.")
			content.lines=lines+(content.lines as Array)
			content.kicker="BATTLE"
			return content
		"siege":
			var content:=_army_content(int(hit.get("army_id",0)),stage)
			content.kicker="SIEGE"
			var siege:Dictionary=MilitaryCampaign.siege_public_snapshot()
			if not siege.is_empty():
				content.lines=["Day %d of the siege of %s." % [maxi(1,int(siege.get("days",0))),String(siege.get("target_name","the town"))]]+(content.lines as Array)
				content["second"]={"label":"Watch the siege","kind":"siege","id":String(siege.get("id",""))}
			return content
		_:
			return _army_content(int(hit.get("army_id",0)),stage)


## The note on a fight already over: what happened, and two plain actions.
func _finished_note(clash:Dictionary)->Dictionary:
	var seed:=int(clash.get("seed",0))
	var record:Dictionary={}
	for past_variant in MilitaryCampaign.battle_history:
		if past_variant is Dictionary and int((past_variant as Dictionary).get("seed",-1))==seed: record=past_variant; break
	var BattleAccount:=preload("res://scripts/battle_account.gd")
	var account:=BattleAccount.build(record,BattleAccount.gather(record)) if not record.is_empty() else {}
	var age:=int(clash.get("age",0))
	var lines:Array=[]
	if not account.is_empty():
		lines.append(BattleAccount.ledger_line(account.ours))
		lines.append(String(account.now))
	var watch:={"label":"Watch the battle","kind":"watch","seed":seed} if int(clash.get("rounds",0))>0 else {}
	return {"kicker":"BATTLE · %s" % ("TODAY" if age==0 else ("YESTERDAY" if age==1 else "%d DAYS AGO" % age)),"title":String(clash.get("headline","A fight")),"lines":lines,
		"action":{"label":"Read the report","kind":"report","seed":seed},"second":watch}


func _army_record(army_id:int)->Dictionary:
	for army in MilitaryCampaign.field_armies:
		if int((army as Dictionary).get("army_id",0))==army_id: return army
	return {}


func _army_content(army_id:int,stage:String)->Dictionary:
	var army:=_army_record(army_id)
	if army.is_empty(): return {"kicker":"WAR","title":"Our hosts","lines":[],"action":_general_action(0)}
	var commander:Dictionary=army.get("commander",{})
	var name:=String(commander.get("name",""))
	# A placeholder staff is not a person: the note is titled with the army.
	if ArmyMarks._named(name)=="": name=String(army.get("name","Our host"))
	var lines:Array=[]
	var mark:Dictionary={}
	for m in (scene.get("marks",[]) as Array):
		if String(m.get("side",""))=="ours" and int(m.get("army_id",0))==army_id: mark=m
	var word:=String(mark.get("noun","host"))
	var doing:=String(mark.get("doing",""))
	lines.append("Leads %s %s of %s%s." % [ArmyMarks._article(word),word,ArmyMarks.about(int(army.get("troops",0))),(", "+doing) if doing!="" else ""])
	# What it is doing now, from the campaign itself (fighting, besieging,
	# marching to attack, waiting after a fight).
	var now:=preload("res://scripts/battle_account.gd").doing(army)
	if now!="": lines.append(_cap(now)+".")
	for f in (scene.get("friendly_seen",[]) as Array):
		if int(f.get("army_id",0))!=army_id: continue
		if f.has("fallback"):
			var how:=String(f.get("fallback_how","home"))
			lines.append(("Withdrawing along the road home." if bool(f.get("withdrawing",false)) else "If pressed, falls back a day's march (%s km) along %s." % [EraWords.grouped(roundi(float(f.get("day_march",0)))),"the road home" if how=="road" else "the way home"]))
		var objective:Vector2=f.get("objective",Vector2.INF)
		if objective.is_finite() and not bool(f.get("withdrawing",false)): lines.append("Marching on the marked ground, %s km off." % EraWords.grouped(roundi((f.pos as Vector2).distance_to(objective))))
		var age:=ArmyMarks.age_words(int(f.get("report_age",0)),"the last runner came")
		if age!="": lines.append(_cap(age)+".")
	var nearest:Dictionary={}
	var here:=_v2(army.get("position",{}))
	for e in (scene.get("enemy_seen",[]) as Array):
		if nearest.is_empty() or (e.pos as Vector2).distance_to(here)<(nearest.pos as Vector2).distance_to(here): nearest=e
	if not nearest.is_empty():
		var ago:=int(nearest.get("age_days",0))
		lines.append("Their nearest host: %s, seen %s." % [ArmyMarks.about(roundi(float(nearest.strength))),"today" if ago==0 else ("yesterday" if ago==1 else "%d days ago" % ago)])
	return {"kicker":"WAR LEADER · "+String(army.get("name","")).to_upper(),"title":name,"lines":lines,"action":_general_action(army_id)}


## Who answers for an army: the Alderford general in his own campaign screen,
## a named war leader summoned into the court, or the Marshal's office.
func _general_action(army_id:int)->Dictionary:
	if GeneralCampaign.active and army_id==int(GeneralCampaign.state.get("army_id",-1)):
		return {"label":"Talk with %s" % String(GeneralCampaign.state.get("general_name","the general")),"kind":"campaign"}
	var army:=_army_record(army_id)
	var commander:Dictionary=army.get("commander",{}) if not army.is_empty() else {}
	if String(commander.get("figure_id",""))!="":
		return {"label":"Send for %s" % String(commander.get("name","the general")).get_slice(" ",0),"kind":"summon","target":{"figure_id":String(commander.figure_id)}}
	return _marshal_action()


## The branch commander of the fleet or air arm: the Marshal's office holds
## command of every branch until a people names its own admirals.
func _branch_leader(_domain:String)->Dictionary:
	return _marshal_action()


func _marshal_action()->Dictionary:
	var holder:Dictionary=GovernmentPeopleSystem.officeholder("Marshal") if GovernmentPeopleSystem.has_method("officeholder") else {}
	if int(holder.get("person_id",0))>0:
		return {"label":"Send for %s" % String(holder.get("name","the Marshal")).get_slice(" ",0),"kind":"summon","target":{"person_id":int(holder.person_id)}}
	return {"label":"Call the war council","kind":"court"}


func open_note(hit:Dictionary,at:Vector2)->void:
	note_about=hit
	var content:=note_content(hit)
	if note==null: _build_note()
	var box:VBoxContainer=note.get_child(0)
	(box.get_node("Kicker") as Label).text=String(content.get("kicker",""))
	(box.get_node("Title") as Label).text=String(content.get("title",""))
	var body:=box.get_node("Body") as VBoxContainer
	for child in body.get_children(): body.remove_child(child); child.queue_free()
	for line in content.get("lines",[]):
		if String(line).strip_edges()=="": continue
		var label:=Label.new(); label.text=String(line); label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size.x=300
		T.text(label,"small",T.INK); body.add_child(label)
	var action:Dictionary=content.get("action",{})
	var button:=box.get_node("Actions/Speak") as Button
	button.visible=not action.is_empty()
	button.text=String(action.get("label",""))
	button.set_meta("action",action)
	var second:Dictionary=content.get("second",{})
	var other:=box.get_node("Actions/Second") as Button
	other.visible=not second.is_empty()
	other.text=String(second.get("label",""))
	other.set_meta("action",second)
	note.reset_size()
	note.show()
	var extent:=note.get_combined_minimum_size()
	var view:=get_viewport_rect().size
	note.position=Vector2(clampf(at.x+18.0,96.0,maxf(96.0,view.x-extent.x-12.0)),clampf(at.y-extent.y*0.3,78.0,maxf(78.0,view.y-extent.y-80.0)))
	queue_redraw()


func _build_note()->void:
	if note_layer==null:
		note_layer=CanvasLayer.new(); note_layer.name="WarNoteLayer"; note_layer.layer=2
		add_child(note_layer)
	note=PanelContainer.new(); note.name="WarNote"
	note.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,14.0))
	note.mouse_filter=Control.MOUSE_FILTER_STOP
	note_layer.add_child(note)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",6); note.add_child(box)
	var kicker:=Label.new(); kicker.name="Kicker"; T.text(kicker,"kicker",T.INK_MUTED); box.add_child(kicker)
	var title:=Label.new(); title.name="Title"; T.text(title,"voice_small",T.INK); box.add_child(title)
	var body:=VBoxContainer.new(); body.name="Body"; body.add_theme_constant_override("separation",3); box.add_child(body)
	var actions:=HBoxContainer.new(); actions.name="Actions"; actions.add_theme_constant_override("separation",8); box.add_child(actions)
	var speak:=Button.new(); speak.name="Speak"; T.text(speak,"small",T.INK); actions.add_child(speak)
	speak.pressed.connect(func(): _act(speak.get_meta("action",{})))
	var second:=Button.new(); second.name="Second"; T.text(second,"small",T.INK); second.visible=false; actions.add_child(second)
	second.pressed.connect(func(): _act(second.get_meta("action",{})))
	var close:=Button.new(); close.name="Close"; close.text="Close"; T.text(close,"small",T.INK_MUTED); close.flat=true; actions.add_child(close)
	close.pressed.connect(close_note)


func _act(action:Dictionary)->void:
	close_note()
	match String(action.get("kind","")):
		"battle": open_battle({"kind":"battle","battle":action.get("battle",{})},Vector2.ZERO)
		"campaign": GeneralCampaign.open_screen()
		"report": preload("res://scripts/hud/battle_report_panel.gd").open(get_tree().current_scene,int(action.get("seed",0)))
		"watch":
			var ui:Node=get_tree().root.get_node_or_null("MilitaryCommandUI")
			if ui!=null: ui.call_deferred("_open_battle_graphics",0,int(action.get("seed",0)))
		"siege": preload("res://scripts/hud/siege_screen.gd").open(String(action.get("id","")))
		"summon":
			var director:Node=preload("res://scripts/audience_director.gd").court_node()
			if director!=null and director.has_method("summon"): director.call("summon",action.get("target",{}))
		_: preload("res://scripts/audience_director.gd").open_court_for({})
