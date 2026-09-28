extends GdUnitTestSuite
## Battles on the war map (codex/battle-map): every fight going on now stands
## on the front where the sides touch, with a two-colour bar and its name and
## day; rivals' fights only where our watchers see them, dated; the stretch
## of front being fought over works like a worm and surges when a battle is
## won; forces carry HOI4-style counters; far out, forces stand together per
## stretch of front and battles per place; arrows draw out and fade; a click
## opens the battle view; and it all stays cheap at scale.
const Source:=preload("res://scripts/hud/battle_marker_source.gd")
const Marks:=preload("res://scripts/hud/battle_marks.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Model:=preload("res://scripts/war_front_model.gd")
const Motion:=preload("res://scripts/hud/motion.gd")


func after_test()->void:
	Motion.reduce_motion=false


## The overlay fills its viewport when it enters the tree; the suites that
## draw on it want a known page size whatever the window was left at by
## other suites (a headless window's canvas can be 640 x 640 or 1920 x 1080).
static func _fix_size(overlay:Control,page:Vector2)->void:
	overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	overlay.position=Vector2.ZERO
	overlay.size=page


# --- Fixtures ----------------------------------------------------------------------------

static func _engagement(seed:int,force:int,ours:int,ours_initial:int,ours_morale:float,theirs:int,theirs_initial:int,theirs_morale:float,extra:Dictionary={})->Dictionary:
	var e:={"seed":seed,"home_force_id":force,"home_force_kind":"field_army","home_side":"attacker","status":"active",
		"attacker":{"name":"Ours","troops":ours,"morale":ours_morale},"defender":{"name":"Theirs","troops":theirs,"morale":theirs_morale},
		"attacker_initial":ours_initial,"defender_initial":theirs_initial,"round":2,"rounds":[{},{}],
		"threat":{"source_civ_id":"civ_a","source_name":"Esurai","target_region_name":""}}
	e.merge(extra,true)
	return e


static func _context(today:int=100)->Dictionary:
	return {"today":today,"home":Vector2.ZERO,"armies":{1:Vector2(10,0),2:Vector2(10,6),3:Vector2(15,-30)},"armies_troops":{1:340,2:500,3:800},
		"towns":{},"cities":[{"id":"tsaren","name":"TSAREN","pos":Vector2(11,0.5),"civ_id":"civ_a"}],"civ_names":{"civ_a":"Esurai","civ_b":"Cedar League","civ_c":"Varn"},
		"colours":{"civ_a":Color("#8e3b2e"),"civ_b":Color("#3b5a8e"),"civ_c":Color("#8e7a2e")},"observers":{"home":Vector2.ZERO,"radius":28.0,"armies":[Vector2(10,0)],"garrisons":[]}}


static func _battle(id:String,pos:Vector2,progress:float,extra:Dictionary={})->Dictionary:
	var b:={"id":id,"kind":"battle","pos":pos,"x":pos.x,"z":pos.y,"ours":true,"army_id":1,"seed":7,"progress":progress,"day":2,"place_name":"Tsaren","status":"fighting","age_days":0,"skirmish":false,
		"sides":{"a":{"civ_id":"player","name":"","colour":Color("#4f9bb8"),"troops":340,"initial":400},"b":{"civ_id":"civ_a","name":"Esurai","colour":Color("#8e3b2e"),"troops":280,"initial":400}}}
	b.merge(extra,true)
	return b


static func _front_inputs(offset:float=0.0)->Dictionary:
	return {"mode":"front","stage":"lettered","home":Vector2(-10,0),"today":100,
		"friendly":[{"id":"1","army_id":1,"pos":Vector2(0,-2),"strength":4000.0},{"id":"2","army_id":2,"pos":Vector2(0,2),"strength":4000.0}],
		"enemy":[{"id":"a","pos":Vector2(6+offset,-2),"strength":4000.0,"age_days":0},{"id":"b","pos":Vector2(6+offset,2),"strength":4000.0,"age_days":0}]}


# --- The source: what is being fought now --------------------------------------------------

func test_the_source_reads_the_watched_battle_the_registry_and_the_command_battles()->void:
	var watched:=_engagement(5,1,300,340,0.7,200,280,0.4,{"threat":{"source_civ_id":"civ_a","source_name":"Esurai","target_region_name":"TSAREN"}})
	var military:={"active_engagement":watched,
		# The battle model's registry: its own progress, and the watched one again (kept once).
		"engagements":{"e2":_engagement(6,2,500,500,0.6,700,700,0.6,{"progress":0.4}),"e5":watched.duplicate(true)},
		"command_hierarchy":{"data":{"battles":[_engagement(8,3,800,900,0.5,900,900,0.7)]}}}
	var battles:=Source.collect(military,{},_context(),{})
	assert_int(battles.size()).is_equal(3)
	var first:Dictionary=battles[0]
	assert_str(String(first.kind)).is_equal("battle")
	assert_bool(bool(first.ours)).is_true()
	assert_int(int(first.army_id)).is_equal(1)
	# Named for the town fought for; where our army stands.
	assert_str(String(first.place_name)).is_equal("Tsaren")
	assert_float((first.pos as Vector2).distance_to(Vector2(10,0))).is_less(0.001)
	assert_int(int(first.day)).is_equal(2)
	assert_int(int((first.sides.a as Dictionary).troops)).is_equal(300)
	assert_str(String((first.sides.b as Dictionary).name)).is_equal("Esurai")
	# We still have most of ours and they are near breaking: we are winning it.
	assert_float(float(first.progress)).is_greater(0.2)
	# The registry's own progress wins over the estimate.
	var registered:Dictionary=battles.filter(func(b:Dictionary)->bool: return int(b.army_id)==2)[0]
	assert_float(float(registered.progress)).is_equal_approx(0.4,0.0001)
	# A command battle with no town nearby is named by its distance and bearing.
	var commanded:Dictionary=battles.filter(func(b:Dictionary)->bool: return int(b.army_id)==3)[0]
	assert_str(String(commanded.place_name)).is_equal("35 km north-east")


func test_without_a_registry_or_progress_the_source_estimates_who_is_winning()->void:
	var losing:={"active_engagement":_engagement(9,1,120,400,0.3,380,400,0.7)}
	var battles:=Source.collect(losing,{},_context(),{})
	assert_int(battles.size()).is_equal(1)
	assert_float(float(battles[0].progress)).is_less(-0.3)
	var even:=Source.estimate({"troops":400,"morale":0.7},400,{"troops":400,"morale":0.7},400)
	assert_float(even).is_equal_approx(0.0,0.0001)
	# A defending home side: progress is still ours positive.
	var held:={"active_engagement":_engagement(10,1,50,400,0.2,390,400,0.7,{"home_side":"defender","attacker":{"troops":390,"morale":0.7},"defender":{"troops":50,"morale":0.2},"attacker_initial":400,"defender_initial":400})}
	assert_float(float(Source.collect(held,{},_context(),{})[0].progress)).is_less(-0.5)
	# Nothing being fought: nothing on the map.
	assert_array(Source.collect({"active_engagement":{}},{},_context(),{})).is_empty()


func test_a_siege_is_a_battle_at_the_town()->void:
	var military:={"active_siege":{"id":"s1","active":true,"mode":"offensive","target_position":{"x":11.0,"z":0.5},"army_id":1,"days":12,"pressure":0.45,"defender_id":"civ_a",
		"threat":{"target_region_name":"TSAREN","strength":300,"source_name":"Esurai"}}}
	var battles:=Source.collect(military,{},_context(),{})
	assert_int(battles.size()).is_equal(1)
	assert_str(String(battles[0].kind)).is_equal("siege")
	assert_float(float(battles[0].progress)).is_equal_approx(0.45,0.0001)
	assert_str(Marks.label(battles[0])).is_equal("Siege of Tsaren · day 12")
	assert_str(String(Overlay.battle_view_request(battles[0]).siege)).is_equal("s1")


func test_the_bar_leans_toward_whoever_is_pushed_back_and_the_words_say_so()->void:
	assert_float(Marks.bar_split(0.0)).is_equal(0.5)
	# We push: our colour takes more of the bar.
	assert_float(Marks.bar_split(0.5)).is_equal(0.75)
	assert_float(Marks.bar_split(-1.0)).is_equal(0.0)
	assert_float(Marks.bar_split(3.0)).is_equal(1.0)
	var pushing:=_battle("b",Vector2.ZERO,0.3)
	assert_str(Marks.hover_line(pushing)).is_equal("We are pushing them back · 340 against 280")
	assert_str(Marks.hover_line(_battle("b",Vector2.ZERO,-0.3))).starts_with("They are pushing us back")
	assert_str(Marks.hover_line(_battle("b",Vector2.ZERO,0.0))).starts_with("Neither side gives ground")
	assert_str(Marks.label(pushing)).is_equal("Tsaren · day 2")
	# A rival fight is told by who is pushing whom.
	var rival:=_battle("r",Vector2.ZERO,-0.4,{"ours":false,"sides":{"a":{"name":"Cedar League","troops":900},"b":{"name":"Esurai","troops":1200}}})
	assert_str(Marks.hover_line(rival)).starts_with("The Esurai are pushing the Cedar League back")


# --- Observation: rival battles only where our watchers are ---------------------------------------

func test_rival_battles_are_shown_only_where_seen_and_are_dated()->void:
	var rival:=_engagement(21,4,600,700,0.6,500,600,0.5,{"threat":{"source_civ_id":"civ_c","target_position":{"x":40.0,"z":0.0}}})
	var fights_us:=_engagement(22,5,600,700,0.6,500,600,0.5,{"threat":{"source_civ_id":"human","target_position":{"x":41.0,"z":0.0}}})
	var actors:={"civ_b":{"active_engagement":rival,"engagements":{"x":fights_us},"field_armies":[{"army_id":4,"position":{"x":40.0,"z":0.0}}]}}
	var memory:={}
	# Nobody of ours near: nothing is known of it.
	var blind:=_context(10)
	assert_array(Source.collect({},actors,blind,memory)).is_empty()
	assert_dict(memory).is_empty()
	# A host of ours camped close by sees it (and their fight with us is ours to show, not theirs).
	var watching:=_context(10)
	watching.observers.armies=[Vector2(34,2)]
	var seen:=Source.collect({},actors,watching,memory)
	assert_int(seen.size()).is_equal(1)
	assert_bool(bool(seen[0].ours)).is_false()
	assert_str(String(seen[0].sides.a.name)).is_equal("Cedar League")
	assert_str(String(seen[0].sides.b.name)).is_equal("Varn")
	# Our host marches off: the fight stays as last seen, dated, and is never updated.
	(actors.civ_b.active_engagement as Dictionary).attacker.troops=100
	var later:=_context(12)
	var dated:=Source.collect({},actors,later,memory)
	assert_int(dated.size()).is_equal(1)
	assert_int(int(dated[0].age_days)).is_equal(2)
	assert_int(int(dated[0].sides.a.troops)).is_equal(600)
	assert_str(Marks.label(dated[0])).contains("seen two days ago")
	# Too old to matter: gone.
	assert_array(Source.collect({},actors,_context(10+Source.RIVAL_MEMORY_DAYS+1),memory)).is_empty()


# --- Fronts: the worm, and tiny parties --------------------------------------------------------------

func test_battles_stand_on_the_front_and_heat_the_worm_but_tiny_parties_get_none()->void:
	var inputs:=_front_inputs()
	inputs.battles=[_battle("b1",Vector2(3.3,-1.6),0.3)]
	var built:=Overlay.compose(inputs)
	assert_int((built.fronts as Array).size()).is_equal(1)
	var battle:Dictionary=built.battles[0]
	assert_int(int(battle.front)).is_equal(0)
	# Snapped onto the line where the sides touch.
	var near:=Marks.nearest_on_fronts(battle.pos,built.fronts)
	assert_float(float(near.distance)).is_less(0.0001)
	var heat:PackedFloat32Array=built.fronts[0].heat
	var peak:=0.0; var cold:=1.0
	for h in heat: peak=maxf(peak,h); cold=minf(cold,h)
	assert_float(peak).is_greater(0.8)
	assert_float(cold).is_less(0.1)
	# A skirmish (a handful caught by a band) heats nothing.
	inputs.battles=[_battle("b2",Vector2(3.3,-1.6),0.3,{"skirmish":true})]
	var calm:PackedFloat32Array=Overlay.compose(inputs).fronts[0].heat
	for h in calm: assert_float(h).is_equal(0.0)
	# A party of three facing a host: no front, no worm; only its own small mark.
	var tiny:=Overlay.compose({"mode":"front","stage":"lettered","home":Vector2(-6,0),"friendly":[{"id":"1","army_id":1,"pos":Vector2.ZERO,"strength":3000.0}],
		"enemy":[{"id":"p","pos":Vector2(2.0,0.2),"strength":3.0,"low":3,"high":3,"age_days":0}],"battles":[_battle("b3",Vector2(1.0,0.1),0.9,{"skirmish":true})]})
	assert_array(tiny.fronts).is_empty()
	assert_int(int(tiny.battles[0].front)).is_equal(-1)
	# Held ground counts: a garrison in a taken town pushes the line past it.
	var with_town:=_front_inputs()
	var bare_x:=_mean_x(Overlay.compose(with_town).fronts[0].points)
	with_town.garrisons=[{"region_id":"tsaren","pos":Vector2(3.0,0.0),"troops":2500}]
	assert_float(_mean_x(Overlay.compose(with_town).fronts[0].points)).is_greater(bare_x+0.3)


static func _mean_x(points:PackedVector2Array)->float:
	var total:=0.0
	for p in points: total+=p.x
	return total/float(maxi(1,points.size()))


func test_a_won_battle_surges_the_front_forward_and_it_settles()->void:
	var overlay:Control=auto_free(Overlay.new())
	var before:=_front_inputs()
	overlay.set_scene(Overlay.compose(before),true)
	var after:=_front_inputs(1.0)
	after.engagements=[{"pos":Vector2(3.0,0.0),"axis":Vector2.RIGHT,"finished":true,"won":true,"seed":77,"age":0,"army_id":1}]
	overlay.set_scene(Overlay.compose(after))
	assert_int((overlay.bulges as Array).size()).is_equal(1)
	var bulge:Dictionary=overlay.bulges[0]
	# Forward is toward them.
	assert_float((bulge.dir as Vector2).x).is_greater(0.9)
	var sigma:=float(overlay.scene.sigma)
	overlay.advance_bulges(Overlay.BULGE_SECONDS*0.5)
	var push:=Model.bulge_offset(bulge.pos,overlay.bulges)
	assert_float(push.x).is_greater(sigma*0.2)
	overlay.advance_bulges(Overlay.BULGE_SECONDS)
	assert_array(overlay.bulges).is_empty()
	# A lost battle gives ground; reduced motion never surges.
	var lost:=_front_inputs(1.0)
	lost.engagements=[{"pos":Vector2(3.0,0.0),"axis":Vector2.RIGHT,"finished":true,"lost":true,"seed":78,"age":0,"army_id":1}]
	overlay.set_scene(Overlay.compose(before),true)
	overlay.set_scene(Overlay.compose(lost))
	assert_float((overlay.bulges[0].dir as Vector2).x).is_less(-0.9)
	Motion.reduce_motion=true
	overlay.set_scene(Overlay.compose(before),true)
	overlay.set_scene(Overlay.compose(after))
	assert_array(overlay.bulges).is_empty()


# --- Counters --------------------------------------------------------------------------------------

func test_counters_carry_strength_will_and_one_state()->void:
	var friendly:=[{"id":"1","army_id":1,"pos":Vector2.ZERO,"strength":600.0,"full":1000,"morale":0.3,"doing_context":{"status":"moving","hungry":true}},
		{"id":"2","army_id":2,"pos":Vector2(5,5),"strength":800.0,"full":800,"morale":0.9,"doing_context":{"status":"stationed"}}]
	var enemy:=[{"id":"e","pos":Vector2(9,0),"strength":500.0,"low":400,"high":600,"age_days":0,"will_low":0.4,"will_high":0.6},
		{"id":"old","pos":Vector2(9,9),"strength":500.0,"low":400,"high":600,"age_days":6,"will_low":0.4,"will_high":0.6}]
	var marks:=Overlay._marks({"stage":"lettered"},friendly,enemy,{"clashes":[],"sieges":[],"battles":[],"fought":{}})
	var hungry:Dictionary=marks.filter(func(m:Dictionary)->bool: return String(m.id)=="ours:1")[0]
	assert_str(String(hungry.state)).is_equal("hungry")
	var counter:=ArmyMarks.counter(hungry)
	assert_float(float(counter.strength)).is_equal_approx(0.6,0.0001)
	assert_float(float(counter.will)).is_equal_approx(0.3,0.0001)
	assert_str(String(marks.filter(func(m:Dictionary)->bool: return String(m.id)=="ours:2")[0].state)).is_equal("holding")
	# In battle overrides hunger; broken overrides both.
	var fighting:=Overlay._marks({"stage":"lettered"},friendly,[],{"clashes":[],"sieges":[],"battles":[],"fought":{1:Vector2.ZERO}})
	assert_str(String(fighting[0].state)).is_equal("fighting")
	assert_str(Marks.state_of({"broken":true,"fighting":true})).is_equal("broken")
	# Theirs: never a strength share, and their will only as the watchers' range while fresh.
	var theirs:Dictionary=marks.filter(func(m:Dictionary)->bool: return String(m.id)=="theirs:e")[0]
	var seen:=ArmyMarks.counter(theirs)
	assert_bool(seen.has("strength")).is_false()
	assert_float(float(seen.will_low)).is_equal(0.4)
	assert_dict(ArmyMarks.counter(marks.filter(func(m:Dictionary)->bool: return String(m.id)=="theirs:old")[0])).is_empty()
	# Full strength counts every formation at its authorised count.
	assert_int(ArmyMarks.full_strength({"troops":70,"formations":[{"count":40,"authorized_count":60},{"count":30}]})).is_equal(90)


# --- Far zoom: sectors and battle groups ------------------------------------------------------

func test_far_out_forces_stand_per_front_sector_and_battles_per_place()->void:
	var front:=PackedVector2Array([Vector2(100,300),Vector2(1100,300)])
	var marks:Array=[]
	var troops:=[400,420,420,300,300,300]
	var xs:=[110.0,150.0,190.0,270.0,310.0,350.0]
	for k in 6: marks.append({"id":"ours:%d" % k,"side":"ours","at":Vector2(xs[k],320),"priority":troops[k],"kind":"band","size":14.0,"troops":troops[k],"noun":"band","army_id":k+1})
	var laid:=ArmyMarks.layout(marks,{"band":"continental","bounds":Rect2(0,0,1200,800),"fronts":[front],"sector_px":150.0})
	assert_int((laid.drawn as Array).size()).is_equal(2)
	var first:Dictionary=laid.drawn[0]
	assert_int((first.members as Array).size()).is_equal(3)
	assert_str(ArmyMarks.sector_words(first)).is_equal("3 bands · 1,240")
	assert_str(String(laid.hidden.get("ours:0",""))).is_equal("sector")
	# Up close nothing is merged that does not overlap.
	assert_int((ArmyMarks.layout(marks,{"band":"local","bounds":Rect2(0,0,1200,800),"fronts":[front]}).drawn as Array).size()).is_equal(6)
	# Battles close together far out stand as one mark; ours and rivals' never join.
	var entries:=[{"at":Vector2(400,300),"battle":_battle("a",Vector2.ZERO,0.6)},{"at":Vector2(430,310),"battle":_battle("b",Vector2.ZERO,-0.2)},
		{"at":Vector2(900,300),"battle":_battle("c",Vector2.ZERO,0.1)},{"at":Vector2(410,300),"battle":_battle("r",Vector2.ZERO,0.0,{"ours":false})}]
	var groups:=Marks.cluster(entries,52.0)
	assert_int(groups.size()).is_equal(3)
	assert_int((groups[0].members as Array).size()).is_equal(2)
	assert_str(Marks.aggregate_label(2)).is_equal("2 battles")
	assert_float(float(groups[0].progress)).is_equal_approx(0.2,0.0001)


# --- Arrows ------------------------------------------------------------------------------------------

func test_arrows_draw_out_ease_and_finished_ones_fade()->void:
	var overlay:Control=auto_free(Overlay.new())
	var marching:=_front_inputs()
	marching.friendly[0]["objective"]=Vector2(9,-2)
	marching.friendly[0]["offensive"]=true
	overlay.set_scene(Overlay.compose(marching))
	assert_bool(overlay.live_arrows.has("army:1")).is_true()
	assert_float(float(overlay.live_arrows["army:1"].grow)).is_equal(0.0)
	overlay.ease_arrows(Overlay.ARROW_GROW_SECONDS*0.5)
	assert_float(float(overlay.live_arrows["army:1"].grow)).is_between(0.4,0.6)
	overlay.ease_arrows(Overlay.ARROW_GROW_SECONDS)
	assert_float(float(overlay.live_arrows["army:1"].grow)).is_equal(1.0)
	# It arrived: the arrow fades where it was, then is gone.
	overlay.set_scene(Overlay.compose(_front_inputs()))
	assert_float(float(overlay.live_arrows["army:1"].target_alpha)).is_equal(0.0)
	overlay.ease_arrows(Overlay.ARROW_FADE_SECONDS*0.5)
	assert_float(float(overlay.live_arrows["army:1"].alpha)).is_between(0.4,0.6)
	overlay.ease_arrows(Overlay.ARROW_FADE_SECONDS)
	assert_bool(overlay.live_arrows.has("army:1")).is_false()
	# A chase after men who fled is an arrow in any age; a siege is one too.
	var early:={"mode":"raid","stage":"hearth","home":Vector2.ZERO,"friendly":[{"id":"9","army_id":9,"pos":Vector2(4,0),"strength":12.0,"objective":Vector2(7,1),"chasing":true},
		{"id":"8","army_id":8,"pos":Vector2(3,3),"strength":40.0}],"enemy":[],"sieges":[{"pos":Vector2(3,3),"pressure":0.3,"ours":true,"army_id":8}]}
	var built:=Overlay.compose(early)
	var kinds:=(built.arrows as Array).map(func(a:Dictionary)->String: return String(a.kind))
	assert_array(kinds).contains(["pursuit","siege"])


# --- Clicks and the pointer ------------------------------------------------------------------------

func test_a_click_on_our_battle_opens_the_battle_view_and_the_pointer_gets_one_line()->void:
	# The game's own entry point exists.
	var ui:=get_tree().root.get_node_or_null("MilitaryCommandUI")
	assert_object(ui).is_not_null()
	assert_bool(ui.has_method("_open_battle_graphics")).is_true()
	var overlay:Control=auto_free(Overlay.new())
	overlay.project=func(p:Vector2)->Vector2: return Vector2(600,400)+p*60.0
	overlay.band_override="local"
	add_child(overlay)
	_fix_size(overlay,Vector2(1200,800))
	var inputs:=_front_inputs()
	inputs.battles=[_battle("ours:1",Vector2(3.0,-2.0),0.3,{"army_id":1}),_battle("rival:x",Vector2(-4,-5),0.1,{"ours":false,"army_id":0})]
	overlay.set_scene(Overlay.compose(inputs),true)
	overlay.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	assert_int((overlay.battle_cache as Array).size()).is_equal(2)
	var ours:Dictionary=(overlay.battle_cache as Array).filter(func(e:Dictionary)->bool: return bool(e.battle.ours))[0]
	var opened:Array=[]
	overlay.battle_opener=func(request:Dictionary)->void: opened.append(request)
	var click:=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT; click.pressed=true; click.position=ours.at
	overlay._input(click)
	assert_int(opened.size()).is_equal(1)
	assert_str(String(opened[0].method)).is_equal("_open_battle_graphics")
	assert_array(opened[0].args).is_equal([1,-1])
	# Resting on it: one plain line.
	overlay._hover(ours.at)
	assert_bool(overlay.tip.visible).is_true()
	assert_str((overlay.tip.get_child(0) as Label).text).is_equal("We are pushing them back · 340 against 280")
	overlay._hover(Vector2(5,5))
	assert_bool(overlay.tip.visible).is_false()
	# A rival's fight is not ours to open: a note about what was seen.
	var rival:Dictionary=(overlay.battle_cache as Array).filter(func(e:Dictionary)->bool: return not bool(e.battle.ours))[0]
	click.position=rival.at
	overlay._input(click)
	assert_int(opened.size()).is_equal(1)
	assert_bool(overlay.note.visible).is_true()
	assert_str(String(overlay.note_content(overlay.note_about).kicker)).is_equal("THEIR BATTLE")
	# The battle labels are lettered on the chart: its name and day.
	var labels:=(overlay.placed_captions as Array).filter(func(c:Dictionary)->bool: return String(c.id).begins_with("battle:"))
	assert_bool(labels.any(func(c:Dictionary)->bool: return String(c.text)=="Tsaren · day 2")).is_true()


# --- Scale ---------------------------------------------------------------------------------------------

static func _long_front(bands:int,battles:int)->Dictionary:
	var friendly:=[]; var enemy:=[]; var fights:=[]
	for k in bands:
		friendly.append({"id":str(k),"army_id":k+1,"pos":Vector2(float(k%3)*0.6,float(k)*4.0),"strength":300.0+float((k*37)%900),"full":1200,"morale":0.6,"doing_context":{"status":"stationed"},
			"objective":Vector2(9.0,float(k)*4.0) if k%5==0 else Vector2.INF,"offensive":k%5==0})
		enemy.append({"id":"e%d" % k,"pos":Vector2(7.0+float(k%2)*0.5,float(k)*4.0+1.0),"strength":350.0+float((k*53)%800),"low":300,"high":900,"age_days":k%30,"moving":k%7==0})
	for k in battles:
		fights.append(_battle("b%d" % k,Vector2(3.5,float(k)*9.0+2.0),float((k%5)-2)*0.3,{"army_id":k+1,"place_name":"Ford %d" % k}))
	return {"mode":"front","stage":"lettered","home":Vector2(-40,100),"today":400,"friendly":friendly,"enemy":enemy,"battles":fights,
		"garrisons":[{"region_id":"t1","pos":Vector2(-3,60),"troops":400,"town":"Tsaren"}]}


func test_compose_and_draw_stay_fast_with_fifty_bands_and_twenty_battles()->void:
	var inputs:=_long_front(50,20)
	Overlay.compose(inputs)
	var start:=Time.get_ticks_usec()
	var built:={}
	for _k in 3: built=Overlay.compose(inputs)
	var compose_ms:=float(Time.get_ticks_usec()-start)/3000.0
	assert_int((built.battles as Array).size()).is_equal(20)
	assert_int((built.marks as Array).size()).is_greater_equal(100)
	var overlay:Control=auto_free(Overlay.new())
	overlay.project=func(p:Vector2)->Vector2: return Vector2(700,40)+p*4.0
	overlay.band_override="regional"
	add_child(overlay)
	_fix_size(overlay,Vector2(1600,900))
	overlay.set_scene(built,true)
	overlay.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	var draw_ms:=float(overlay.last_draw_usec)/1000.0
	print("TIMING compose %.1f ms, draw %.1f ms, battles on screen %d, marks drawn %d" % [compose_ms,draw_ms,(overlay.battle_cache as Array).size(),(overlay.drawn_marks as Array).size()])
	assert_float(compose_ms).is_less(60.0)
	assert_float(draw_ms).is_less(60.0)
	assert_int((overlay.battle_cache as Array).size()).is_greater(10)
