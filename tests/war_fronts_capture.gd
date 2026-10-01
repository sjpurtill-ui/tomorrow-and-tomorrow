extends Control
## TEST CAPTURE (not the game): deterministic before/after plates of war on
## the map at three stages. The "before" plates place today's marks by the
## same rules as war_map_overlay.gd (border stub, feud mark, band, raid
## smoke) and today's straight march ribbons; the "after" plates run the new
## war_front_overlay.gd composition on the same positions.
## Run only through tools/run_isolated_gpu_probe.ps1 with
## -- --capture-dir=<absolute dir>. Quits by itself.

const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Marks:=preload("res://scripts/war_map_marks.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

var plates:Array=[]
var index:=-1
var current:Dictionary={}
var overlay:Control
var directory:=""
var frames:=0


func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
	if directory=="": directory=ProjectSettings.globalize_path("res://artifacts/war_fronts")
	DirAccess.make_dir_recursive_absolute(directory)
	overlay=Overlay.new()
	add_child(overlay)
	overlay.project=func(p:Vector2)->Vector2: return _to_screen(p)
	overlay.band_override="regional"
	for scenario in [_early(),_mid(),_late()]:
		plates.append({"name":"%s_before" % scenario.name,"scenario":scenario,"after":false})
		plates.append({"name":"%s_after" % scenario.name,"scenario":scenario,"after":true})
	_next()


func _next()->void:
	index+=1
	if index>=plates.size():
		print("WAR FRONTS CAPTURE PASS %d plates in %s" % [plates.size(),directory])
		get_tree().quit(0); return
	current=plates[index]
	var scenario:Dictionary=current.scenario
	overlay.visible=bool(current.after)
	var start:=Time.get_ticks_usec()
	overlay.set_scene(Overlay.compose(scenario.inputs) if bool(current.after) else {},true)
	if bool(current.after): print("COMPOSE %s %.2f ms primitives=%d" % [scenario.name,float(Time.get_ticks_usec()-start)/1000.0,Overlay.primitive_count(overlay.scene)])
	frames=0
	queue_redraw()


func _process(_delta:float)->void:
	if index<0 or index>=plates.size(): return
	frames+=1
	if frames==4:
		var image:=get_viewport().get_texture().get_image()
		image.save_png(directory.path_join("%s.png" % current.name))
		_next()


func _to_screen(p:Vector2)->Vector2:
	var view:Dictionary=current.get("scenario",{}).get("view",{"centre":Vector2.ZERO,"scale":40.0})
	return size*0.5+((p-(view.centre as Vector2))*float(view.scale))


# --- Scenarios (world km) -----------------------------------------------------

func _early()->Dictionary:
	var home:=Vector2(0,0); var enemy_home:=Vector2(9,3)
	return {"name":"early_raid","home":home,"enemy_home":enemy_home,"title":"Before writing: a feud. Raids and a clash, no fronts.","coast":[],
		"view":{"centre":Vector2(4.5,1.2),"scale":130.0},
		"before":{"band":Marks.band_point(home,enemy_home,0,20,11),"raid_day_ago":6,"raid_target":"fields","sighting":Vector2(4.2,-0.9)},
		"inputs":{"mode":"raid","stage":"hearth","home":home,
			"friendly":[{"id":"1","pos":Marks.band_point(home,enemy_home,0,20,11),"strength":14.0}],
			"enemy":[{"id":"e1","pos":Vector2(4.2,-0.9),"strength":11.0,"age_days":2}],
			"raids":[{"ours":true,"from":home,"to":Marks.band_point(home,enemy_home,0,20,11),"fought":false},
				{"ours":false,"from":Marks.raid_point(home,enemy_home,"fields","c:6").lerp(enemy_home,0.35),"to":Marks.raid_point(home,enemy_home,"fields","c:6"),"fought":true,"alpha":0.75}],
			"engagements":[{"pos":Vector2(6.0,2.0),"axis":Vector2(1,0.3).normalized(),"ours":"dawn_raid","theirs":"head_on","rounds":1,"phase_ours":"hold","phase_theirs":"hold"}]}}


func _mid()->Dictionary:
	var home:=Vector2(-6,0)
	var city:=Vector2(13,1)
	var friendly:=[{"id":"1","pos":Vector2(0,-3),"strength":3000.0,"objective":Vector2(5.5,-2.2),"offensive":true},{"id":"2","pos":Vector2(1,4),"strength":2500.0,"objective":city,"offensive":true}]
	var enemy:=[{"id":"a","pos":Vector2(6,-2),"strength":3500.0,"age_days":1},{"id":"b","pos":Vector2(6.5,5),"strength":2000.0,"age_days":25},{"id":"c","pos":Vector2(9,0.5),"strength":1500.0,"age_days":0,"moving":true,"heading":PI*0.5}]
	return {"name":"mid_campaign","home":home,"enemy_home":city,"title":"Lettered age: two field armies, a battle and a siege.","coast":[],
		"view":{"centre":Vector2(4,1),"scale":58.0},
		"before":{"armies":friendly,"sightings":enemy,"city":city},
		"inputs":{"mode":"front","stage":"lettered","home":home,"friendly":friendly,"enemy":enemy,
			"engagements":[{"pos":Vector2(3.1,-2.5),"axis":Vector2(1,0.1).normalized(),"ours":"hammer_and_anvil","theirs":"dense_line","rounds":4,"phase_ours":"hold","phase_theirs":"hold"}],
			"sieges":[{"pos":city,"pressure":0.45,"works":"circumvallation","ours":true}]}}


func _late()->Dictionary:
	var home:=Vector2(-40,0)
	var friendly:=[]; var enemy:=[]
	var ys:=[-22.0,-13.0,-5.0,3.0,11.0,20.0]
	for k in ys.size():
		friendly.append({"id":str(k),"pos":Vector2(-4.0+float(k%2)*1.5,ys[k]),"strength":[40000.0,60000.0,90000.0,55000.0,30000.0,45000.0][k],"objective":Vector2(14,-4) if k==2 else Vector2.INF,"offensive":k==2})
	var ey:=[-24.0,-16.0,-9.0,-2.0,4.0,9.0,15.0,22.0]
	for k in ey.size():
		enemy.append({"id":"e%d" % k,"pos":Vector2(5.0+float(k%3),ey[k]),"strength":[30000.0,40000.0,25000.0,20000.0,50000.0,45000.0,30000.0,20000.0][k],"age_days":[0,1,0,3,30,2,1,40][k]})
	var air:=PackedVector2Array([Vector2(-6,-12),Vector2(10,-12),Vector2(10,8),Vector2(-6,8)])
	var sea:=PackedVector2Array([Vector2(8,26),Vector2(30,26),Vector2(30,36),Vector2(8,36)])
	return {"name":"late_theatre","home":home,"enemy_home":Vector2(30,0),"title":"Reckoned age: a theatre. Fronts, arrows, fallback and supply lines, air and sea zones.","coast":[Vector2(-60,29),Vector2(60,29)],
		"view":{"centre":Vector2(2,4),"scale":14.5},
		"before":{"armies":friendly,"sightings":enemy},
		"inputs":{"mode":"theatre","stage":"reckoned","home":home,"friendly":friendly,"enemy":enemy,
			"engagements":[{"pos":Vector2(0.6,-5.2),"axis":Vector2.RIGHT,"ours":"armoured_breakthrough","theirs":"entrenched_defence","rounds":4,"phase_ours":"closing","phase_theirs":"hold"},
				{"pos":Vector2(1.0,11.5),"axis":Vector2.RIGHT,"ours":"head_on","theirs":"defence_in_depth","rounds":3,"phase_ours":"hold","phase_theirs":"hold"}],
			"zones":[{"domain":"air","vertices":air,"control":0.65,"mission":"air_superiority","tactic":"fighter_sweep","base":Vector2(-24,-10),"port":Vector2.INF,"contacts":[{"pos":Vector2(7,-6),"age":1}],"shape":"hatch","name":"First Air Wing"},
				{"domain":"navy","vertices":sea,"control":0.8,"mission":"patrol","tactic":"distant_blockade","base":Vector2.INF,"port":Vector2(22,29.5),"contacts":[{"pos":Vector2(20,31),"age":2}],"shape":"cordon_wide","name":"Home Fleet"}]}}


# --- Painted ground and today's marks ----------------------------------------------

func _draw()->void:
	if current.is_empty(): return
	var scenario:Dictionary=current.scenario
	draw_rect(Rect2(Vector2.ZERO,size),Color("#8a8a4a"))
	# A few painted fields and woods (deterministic) in the map palette.
	var rng:=RandomNumberGenerator.new(); rng.seed=hash(scenario.name)
	for k in 70:
		var c:=Vector2(rng.randf()*size.x,rng.randf()*size.y)
		draw_circle(c,rng.randf_range(20,90),Color("#6e7f3e") if k%3 else Color("#3e4a2c"),true)
	for k in 40:
		var c:=Vector2(rng.randf()*size.x,rng.randf()*size.y)
		draw_circle(c,rng.randf_range(10,50),Color("#a89468",0.5))
	if not (scenario.coast as Array).is_empty():
		var y:=_to_screen(scenario.coast[0]).y
		draw_rect(Rect2(0,y,size.x,size.y-y),Color("#5e7f7a"))
		draw_rect(Rect2(0,y+40,size.x,size.y-y),Color("#2f4a52",0.6))
	# Home and the enemy's town.
	for place in [[scenario.home,"Our home"],[scenario.enemy_home,"Their town"]]:
		var at:=_to_screen(place[0])
		draw_circle(at,7,Color("#efe3c2")); draw_arc(at,7,0,TAU,20,Color("#2b2118"),1.5,true)
		draw_string(ThemeDB.fallback_font,at+Vector2(10,-8),place[1],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#1f1a14"))
	_draw_counters(scenario)
	if not bool(current.after): _draw_before(scenario)
	# Plate caption (TEST capture).
	draw_rect(Rect2(16,16,size.x-32,34),Color("#efe6d4",0.92))
	draw_string(ThemeDB.fallback_font,Vector2(28,39),"TEST CAPTURE · %s · %s" % ["BEFORE (today's marks)" if not bool(current.after) else "AFTER (war fronts)",String(scenario.title)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#1f1a14"))


func _draw_before(scenario:Dictionary)->void:
	var home:Vector2=scenario.home; var there:Vector2=scenario.enemy_home
	var war:=Color("#c9574a")
	# The contested line is the nation borders' real meeting line now (lit
	# red on the map); this sketch has no claims, so it draws the mark alone.
	var mark:=_to_screen(Marks.border_point(home,there))
	draw_texture_rect(Icons.war_texture("feud",war),Rect2(mark-Vector2(13,13),Vector2(26,26)),false)
	var before:Dictionary=scenario.before
	if before.has("band"):
		draw_texture_rect(Icons.war_texture("band",Color("#67B4CF")),Rect2(_to_screen(before.band)-Vector2(13,13),Vector2(26,26)),false)
		draw_texture_rect(Icons.war_texture("raid",war),Rect2(_to_screen(Marks.raid_point(home,there,"fields","c:6"))-Vector2(13,13),Vector2(26,26)),false,Color(1,1,1,0.75))
		draw_texture_rect(Icons.war_texture("band",war),Rect2(_to_screen(before.sighting)-Vector2(13,13),Vector2(26,26)),false)
	for army in before.get("armies",[]):
		var at:=_to_screen(army.pos)
		var objective:Vector2=army.get("objective",Vector2.INF)
		if objective.is_finite():
			draw_line(at,_to_screen(objective),Color("#101718",0.72),7.0,true)
			draw_line(at,_to_screen(objective),Color("#67B4CF",0.92),3.0,true)
			draw_arc(_to_screen(objective),12,0,TAU,24,Color("#67B4CF"),3.0,true)


## Formation counters are drawn by the 3D map in both states; a flat stand-in here.
func _draw_counters(scenario:Dictionary)->void:
	var before:Dictionary=scenario.before
	for army in before.get("armies",[]):
		var at:=_to_screen(army.pos)
		draw_rect(Rect2(at-Vector2(14,9),Vector2(28,18)),Color("#202526"))
		draw_rect(Rect2(at-Vector2(14,9),Vector2(28,18)),Color("#67B4CF"),false,2.0)
	for sighting in before.get("sightings",[]):
		var at:=_to_screen(sighting.pos)
		draw_rect(Rect2(at-Vector2(14,9),Vector2(28,18)),Color("#202526"))
		draw_rect(Rect2(at-Vector2(14,9),Vector2(28,18)),Color("#D76355"),false,2.0)
