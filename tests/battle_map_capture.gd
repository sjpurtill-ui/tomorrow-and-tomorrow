extends Control
## TEST CAPTURE (not the game): battles on the war map (codex/battle-map).
## Deterministic plates of hud/war_front_overlay.gd over a painted stand-in
## for the ground, with the overlay's own composition, battle marks,
## counters, worms and arrows:
##   a_early_battles      the first ages: two battles by a taken town and a
##                        chase after the men who fled (medium zoom);
##   b_long_front         a later front, about 40 hosts and 15 battles (medium);
##   c_long_front_far     the same front far out: forces per stretch of
##                        front, battles per place;
##   d_won_battle_surge   a front just after a won battle, mid-surge.
## Run only through tools/run_isolated_gpu_probe.ps1 with
## -- --capture-dir=<absolute dir>. Quits by itself.

const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

var plates:Array=[]
var index:=-1
var current:Dictionary={}
var overlay:Control
var directory:=""
var frames:=0


func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Motion.reduce_motion=false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
	if directory=="": directory=ProjectSettings.globalize_path("res://artifacts/battle_map")
	DirAccess.make_dir_recursive_absolute(directory)
	overlay=Overlay.new()
	add_child(overlay)
	overlay.set_process(false)
	overlay.project=func(p:Vector2)->Vector2: return _to_screen(p)
	var long_front:=_long_front()
	plates=[_early(),long_front,_far(long_front),_surge()]
	_next()


func _next()->void:
	index+=1
	if index>=plates.size():
		print("BATTLE MAP CAPTURE PASS %d plates in %s" % [plates.size(),directory])
		get_tree().quit(0); return
	current=plates[index]
	overlay.band_override=String(current.band)
	var start:=Time.get_ticks_usec()
	var built:=Overlay.compose(current.inputs)
	var compose_ms:=float(Time.get_ticks_usec()-start)/1000.0
	overlay.set_scene(built,true)
	overlay.anim_clock=float(current.get("clock",0.9))
	if current.has("after"):
		# A battle won: the new scene arrives, and the front is caught mid-surge.
		overlay.set_scene(Overlay.compose(current.after))
		var steps:=int(current.get("steps",14))
		for _k in steps:
			overlay.ease_fronts(1.0/30.0); overlay.ease_arrows(1.0/30.0); overlay.advance_bulges(1.0/30.0)
	print("COMPOSE %s %.2f ms primitives=%d battles=%d marks=%d bulges=%d" % [current.name,compose_ms,Overlay.primitive_count(overlay.scene),(overlay.scene.battles as Array).size(),(overlay.scene.marks as Array).size(),(overlay.bulges as Array).size()])
	frames=0
	queue_redraw(); overlay.queue_redraw()


func _process(_delta:float)->void:
	if index<0 or index>=plates.size(): return
	frames+=1
	if frames==3: print("DRAW %s %.2f ms battles_drawn=%d marks_drawn=%d captions=%d dropped=%d" % [current.name,float(overlay.last_draw_usec)/1000.0,(overlay.battle_cache as Array).size(),(overlay.drawn_marks as Array).size(),(overlay.placed_captions as Array).size(),overlay.dropped_captions])
	if frames==5:
		var image:=get_viewport().get_texture().get_image()
		image.save_png(directory.path_join("%s.png" % current.name))
		_next()


func _to_screen(p:Vector2)->Vector2:
	var view:Dictionary=current.get("view",{"centre":Vector2.ZERO,"scale":40.0})
	return size*0.5+((p-(view.centre as Vector2))*float(view.scale))


# --- Fixtures (world km) ------------------------------------------------------------

static func _side(name:String,colour:Color,troops:int)->Dictionary:
	return {"civ_id":name.to_lower(),"name":name,"colour":colour,"troops":troops,"initial":troops}


static func _battle(id:String,pos:Vector2,progress:float,day:int,place:String,army:int,ours:int,theirs:int,extra:Dictionary={})->Dictionary:
	var b:={"id":id,"kind":"battle","pos":pos,"x":pos.x,"z":pos.y,"ours":true,"army_id":army,"seed":army*7,"progress":progress,"day":day,"place_name":place,"status":"fighting","age_days":0,"skirmish":false,
		"sides":{"a":_side("",Color("#4f9bb8"),ours),"b":_side("Esurai",Color("#b5503c"),theirs)}}
	b.merge(extra,true)
	return b


func _early()->Dictionary:
	var home:=Vector2(0,0); var town:=Vector2(22,4)
	var friendly:=[
		{"id":"1","army_id":1,"pos":Vector2(19.2,7.6),"strength":46.0,"full":52,"morale":0.62,"name":"Rovik's band","general":"Rovik Tamm","doing_context":{"status":"stationed"}},
		{"id":"2","army_id":2,"pos":Vector2(24.6,0.6),"strength":52.0,"full":60,"morale":0.45,"general":"Ysa Morn","doing_context":{"status":"stationed"}},
		{"id":"3","army_id":3,"pos":Vector2(24.3,5.8),"strength":12.0,"full":12,"morale":0.7,"objective":Vector2(29.5,9.6),"chasing":true,"detachment_of":"TSAREN","doing_context":{"status":"moving","pursuit":"chasing the Tsaren men who fled"}},
		{"id":"4","army_id":4,"pos":Vector2(9.0,1.2),"strength":30.0,"full":30,"morale":0.7,"objective":Vector2(21.0,3.6),"offensive":false,"doing_context":{"status":"moving","destination_name":"Tsaren","hungry":true}}]
	var enemy:=[{"id":"e1","pos":Vector2(20.6,8.7),"strength":38.0,"low":30,"high":44,"age_days":0,"observed":true,"owner":"Esurai"},
		{"id":"e2","pos":Vector2(26.0,0.0),"strength":60.0,"low":50,"high":70,"age_days":0,"observed":true,"owner":"Esurai"},
		{"id":"e3","pos":Vector2(27.2,8.4),"strength":9.0,"low":7,"high":12,"age_days":0,"moving":true,"heading":-PI*0.3,"observed":true}]
	var battles:=[_battle("b1",Vector2(19.9,8.1),0.28,2,"Near Tsaren",1,46,38),_battle("b2",Vector2(25.3,0.3),-0.18,1,"Tsaren ford",2,52,60)]
	return {"name":"a_early_battles","band":"local","title":"First ages: two battles by a taken town, and a chase after the men who fled",
		"view":{"centre":Vector2(17.5,4.0),"scale":62.0},"towns":[[home,"Seanstone"],[town,"Tsaren"],[Vector2(33,12),"Osk"]],"river":[Vector2(18,-6),Vector2(22.5,0.4),Vector2(26,1.5),Vector2(34,-2)],
		"inputs":{"mode":"raid","stage":"hearth","home":home,"today":400,"friendly":friendly,"enemy":enemy,"battles":battles,
			"garrisons":[{"region_id":"tsaren","pos":town,"troops":34,"required":40,"town":"TSAREN","general":"Hena Vall","morale":0.66}],
			"engagements":[{"pos":Vector2(21.8,4.2),"axis":Vector2.RIGHT,"finished":true,"won":true,"seed":91,"age":1,"army_id":1,"result":"Taken · three hurt or killed","headline":"We took Tsaren"}]}}


func _long_front()->Dictionary:
	var names:=["Varn ford","Hollin","Near Osk","Brevik","Tallow bridge","Kesh","Near Mardun","Oda","Selk crossing","Rimmen","Near Ask","Tor","Fen gate","Ludd","Near Parro"]
	var friendly:=[]; var enemy:=[]; var battles:=[]
	var ours_count:=22
	for k in ours_count:
		var y:=-150.0+float(k)*14.0
		var x:=-14.0+sin(float(k)*0.7)*3.0+(8.0 if k in [5,6,8] else 0.0)
		if k==7: y=-116.0
		var troops:=1500+(k*1370)%7500
		var objective:=Vector2(x+34.0,y+(6.0 if k%2==0 else -6.0)) if k in [4,7,15] else Vector2.INF
		friendly.append({"id":str(k),"army_id":k+1,"pos":Vector2(x,y) if k!=7 else Vector2(44,-117),"strength":float(troops),"full":troops+(k*211)%2400,"morale":0.3+float((k*37)%60)/100.0,
			"era":2,"branch":["foot","foot","guns","horse","foot"][k%5],"objective":objective,"offensive":objective.is_finite(),"general":["Arno Kell","","Ysa Morn","","Tamm Vey"][k%5],
			"doing_context":{"status":"moving" if objective.is_finite() else "stationed","hungry":k%9==4,"broken":k==19}})
	for k in 20:
		var y:=-146.0+float(k)*15.0
		var x:=12.0+cos(float(k)*0.9)*3.0+(8.0 if k in [5,6] else 0.0)
		var troops:=1800+(k*1570)%7000
		enemy.append({"id":"e%d" % k,"pos":Vector2(x,y),"strength":float(troops),"low":int(troops*0.8),"high":int(troops*1.2),"age_days":[0,0,1,0,2,0,0,1,0,0,0,3,0,0,1,0,25,30,28,0][k],
			"moving":k in [3,12],"heading":PI*0.5,"observed":true,"owner":"Esurai","era":2,"will_low":0.35,"will_high":0.6})
	for k in 15:
		var y:=-138.0+float(k)*19.0
		battles.append(_battle("b%d" % k,Vector2(-1.0+sin(float(k))*2.0,y),[0.4,-0.2,0.1,0.6,-0.5,0.0,0.3,-0.1,0.2,0.5,-0.3,0.05,0.35,-0.6,0.15][k],1+(k*3)%9,names[k],k+1,
			2400+(k*530)%4000,2100+(k*710)%3800))
	battles.append(_battle("siege:s1",Vector2(46,-120),0.55,11,"Mardun",8,6200,1400,{"kind":"siege","status":"besieging","siege_id":"s1"}))
	return {"name":"b_long_front","band":"regional","title":"A later front: about forty hosts and fifteen battles, medium zoom",
		"view":{"centre":Vector2(8,0),"scale":2.55},"towns":[[Vector2(-60,20),"Seanstone"],[Vector2(46,-120),"Mardun"],[Vector2(-20,-40),"Brevik"],[Vector2(52,60),"Ask"],[Vector2(20,110),"Parro"]],
		"river":[Vector2(-80,-170),Vector2(-10,-60),Vector2(6,10),Vector2(-4,90),Vector2(-40,190)],
		"inputs":{"mode":"front","stage":"reckoned","home":Vector2(-60,20),"today":4000,"friendly":friendly,"enemy":enemy,"battles":battles,"corps_known":true,
			"garrisons":[{"region_id":"brevik","pos":Vector2(-20,-40),"troops":900,"required":800,"town":"BREVIK","morale":0.7}],
			"sieges":[{"pos":Vector2(46,-120),"pressure":0.55,"works":"circumvallation","ours":true,"army_id":8,"days":11}],
			"engagements":[]}}


func _far(near:Dictionary)->Dictionary:
	var far:=near.duplicate(true)
	far.name="c_long_front_far"; far.band="continental"; far.title="The same front far out: forces stand together per stretch of front, battles per place"
	far.view={"centre":Vector2(8,0),"scale":1.05}
	return far


func _surge()->Dictionary:
	var home:=Vector2(-40,0)
	var friendly:=[]; var enemy:=[]
	for k in 4:
		friendly.append({"id":str(k),"army_id":k+1,"pos":Vector2(-2.0,-30.0+float(k)*20.0),"strength":6000.0,"full":6500,"morale":0.7,"era":1,"doing_context":{"status":"stationed"}})
		enemy.append({"id":"e%d" % k,"pos":Vector2(10.0,-30.0+float(k)*20.0),"strength":5500.0,"low":5000,"high":6000,"age_days":0,"observed":true,"owner":"Esurai","era":1})
	var before:={"mode":"front","stage":"lettered","home":home,"today":900,"friendly":friendly,"enemy":enemy,
		"battles":[_battle("won",Vector2(4.0,-0.5),0.55,3,"Hollin",2,5200,3100)],"engagements":[]}
	# The day after: their host at Hollin broke and fell back; ours holds the field.
	var after:=before.duplicate(true)
	after.friendly[1]["pos"]=Vector2(4.5,-10.0)
	after.enemy[1]["pos"]=Vector2(17.0,-11.0)
	after.enemy[1]["strength"]=2600.0; after.enemy[1]["low"]=2200; after.enemy[1]["high"]=3000
	after.battles=[]
	after.engagements=[{"pos":Vector2(4.0,-0.5),"axis":Vector2.RIGHT,"finished":true,"won":true,"seed":14,"age":0,"army_id":2,"result":"Won · 40 hurt or killed","headline":"We broke them at Hollin"}]
	return {"name":"d_won_battle_surge","band":"regional","title":"Just after a won battle: the front surges forward and settles where control now lies",
		"view":{"centre":Vector2(4,-6),"scale":18.0},"towns":[[Vector2(-30,-30),"Seanstone"],[Vector2(4.5,-2.0),"Hollin"],[Vector2(24,-8),"Kesh"]],
		"river":[Vector2(-20,-60),Vector2(1,-20),Vector2(3,10),Vector2(-8,40)],"inputs":before,"after":after,"steps":24}


# --- The painted stand-in for the ground ----------------------------------------------------

func _draw()->void:
	if current.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),Color("#8a8a4a"))
	var rng:=RandomNumberGenerator.new(); rng.seed=hash(String(current.name))
	for k in 90:
		var c:=Vector2(rng.randf()*size.x,rng.randf()*size.y)
		draw_circle(c,rng.randf_range(24,110),Color("#6e7f3e") if k%3 else Color("#3e4a2c",0.85),true)
	for k in 40:
		var c:=Vector2(rng.randf()*size.x,rng.randf()*size.y)
		draw_circle(c,rng.randf_range(10,60),Color("#a89468",0.45))
	var river:=PackedVector2Array()
	for p in current.get("river",[]): river.append(_to_screen(p))
	if river.size()>=2:
		draw_polyline(river,Color("#5e7f7a"),9.0,true)
		draw_polyline(river,Color("#2f4a52",0.5),3.0,true)
	var font:=T.voice_font(true)
	for town in current.get("towns",[]):
		var at:=_to_screen(town[0])
		draw_circle(at,6.5,Color("#efe3c2")); draw_arc(at,6.5,0,TAU,20,Color("#2b2118"),1.6,true)
		draw_circle(at,2.2,Color("#2b2118"))
		draw_string_outline(font,at+Vector2(10,-9),String(town[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,16,4,Color("#efe3c2",0.9))
		draw_string(font,at+Vector2(10,-9),String(town[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#1f1a14"))
	# Plate caption (TEST capture).
	draw_rect(Rect2(16,16,size.x-32,34),Color("#efe6d4",0.94))
	draw_string(T.font("ui"),Vector2(28,39),"TEST CAPTURE · %s" % String(current.title),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#1f1a14"))
