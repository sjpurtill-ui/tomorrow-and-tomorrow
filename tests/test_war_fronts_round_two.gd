extends GdUnitTestSuite
## Round two of war on the map: captions share the city labels' placement and
## drop rather than overlap; a click opens a note about the thing and whom to
## talk to (never an order); the command hierarchy's parallel battles are all
## drawn; fallback lines come from the generals' own withdrawal routes; corps
## and army groups are marked when fielded; blockades squeeze a port slowly
## and within bounds; and the fronts ease toward new positions without jumps.
const Model:=preload("res://scripts/war_front_model.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const CityLabels:=preload("res://scripts/hud/city_labels.gd")
const Blockade:=preload("res://scripts/naval_blockade.gd")


func _front_inputs(offset:float=0.0)->Dictionary:
	return {"mode":"front","stage":"lettered","home":Vector2(-10,0),
		"friendly":[{"id":"1","army_id":1,"pos":Vector2(0,-2),"strength":4000.0,"fallback":Vector2(-1.5,-2.2)},{"id":"2","army_id":2,"pos":Vector2(0,2),"strength":4000.0,"fallback":Vector2(-1.2,2.6)}],
		"enemy":[{"id":"a","pos":Vector2(6+offset,-2),"strength":4000.0,"age_days":0},{"id":"b","pos":Vector2(6+offset,2),"strength":4000.0,"age_days":0}]}


# --- Captions ---------------------------------------------------------------------

func test_captions_never_overlap_and_the_lesser_are_dropped()->void:
	var bounds:=Rect2(0,0,400,300)
	var city:=Rect2(180,130,90,24)
	var notes:Array=[]
	# Ten captions all wanting the same spot beside one anchor.
	for k in 10: notes.append({"id":"n%d" % k,"anchor":Vector2(200,150),"extent":Vector2(150,22),"priority":k%3,"clear":10.0})
	var result:=CityLabels.place_notes(notes,bounds,[city],[{"at":Vector2(200,150),"clear":8.0}])
	var placed:Array=result.notes
	assert_int(placed.size()).is_greater(0)
	assert_int(placed.size()+(result.dropped as Array).size()).is_equal(10)
	for i in placed.size():
		var a:Rect2=placed[i].rect
		assert_bool(bounds.encloses(a)).is_true()
		assert_bool(a.intersects(city)).is_false()
		for j in range(i+1,placed.size()): assert_bool(a.intersects(placed[j].rect)).is_false()
	# Every kept caption outranks or equals every dropped one.
	var lowest_kept:=99
	for note in placed: lowest_kept=mini(lowest_kept,int(note.priority))
	for id in result.dropped:
		assert_int(int(String(id).trim_prefix("n"))%3).is_less_equal(lowest_kept)
	# Stable: a second pass with the same memory keeps every caption in place.
	var again:=CityLabels.place_notes(notes,bounds,[city],[{"at":Vector2(200,150),"clear":8.0}],result.memory)
	for note in again.notes:
		for before in placed:
			if String(before.id)==String(note.id): assert_that(note.rect).is_equal(before.rect)


func test_works_and_captions_share_one_placement_test()->void:
	var bounds:=Rect2(0,0,500,400)
	var blocked:Array[Rect2]=[Rect2(100,100,60,20)]
	var spot:=CityLabels.free_spot([Vector2(100,100),Vector2(100,140)],Vector2(60,20),bounds,blocked,[])
	assert_that(spot).is_equal(Rect2(100,140,60,20))
	# Great works still place beside themselves through the shared test.
	var works:Array[Dictionary]=[{"id":"w","city_id":"c","anchor":Vector2(250,200),"extent":Vector2(80,24),"state":"standing","emblem_alpha":1.0,"radius_px":4.0,"compact":true}]
	var placed:=CityLabels.arrange_works(works,bounds,[],[])
	assert_bool((placed.works[0].rect as Rect2).has_area()).is_true()


# --- Notes and clicks ---------------------------------------------------------------

func test_a_click_on_a_front_names_its_holders_and_offers_talk_not_orders()->void:
	var overlay:Control=auto_free(Overlay.new())
	overlay.size=Vector2(1200,800)
	overlay.project=func(p:Vector2)->Vector2: return Vector2(600,400)+p*60.0
	overlay.band_override="local"
	add_child(overlay)
	overlay.set_scene(Overlay.compose(_front_inputs()),true)
	overlay.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	var front:Dictionary=overlay.scene.fronts[0]
	var on_line:Vector2=overlay.project.call((front.points as PackedVector2Array)[front.points.size()/2])
	var hit:Dictionary=overlay.hit_at(on_line)
	assert_str(String(hit.get("kind",""))).is_equal("front")
	assert_array(hit.armies).contains([1,2])
	var note:Dictionary=overlay.note_content(hit)
	assert_str(String(note.kicker)).contains("FRONT")
	assert_bool((note.lines as Array).size()>0).is_true()
	# The only action is a conversation: the court, a summons or the campaign.
	var action:Dictionary=note.action
	assert_array(["court","summon","campaign"]).contains([String(action.kind)])
	overlay.open_note(hit,on_line)
	assert_bool(overlay.note.visible).is_true()
	overlay.close_note()
	assert_bool(overlay.note.visible).is_false()


func test_a_general_with_a_name_is_sent_for_by_name()->void:
	var overlay:Control=auto_free(Overlay.new())
	MilitaryCampaign.field_armies.append({"army_id":987,"name":"Test Host","troops":900,"position":{"x":0,"z":0},"commander":{"name":"Hena Vall","figure_id":"fig_test"}})
	var action:Dictionary=overlay._general_action(987)
	MilitaryCampaign.field_armies.pop_back()
	assert_str(String(action.kind)).is_equal("summon")
	assert_str(String(action.target.figure_id)).is_equal("fig_test")
	assert_str(String(action.label)).is_equal("Send for Hena")


# --- Parallel battles ---------------------------------------------------------------

func test_every_commanded_battle_gets_its_own_clash_mark()->void:
	var watched:={"seed":1,"home_force_id":3}
	var commanded:=[{"seed":1,"home_force_id":3},{"seed":2,"home_force_id":4},{"seed":3,"home_force_id":5}]
	var battles:=Overlay.battles_to_draw(watched,commanded)
	assert_int(battles.size()).is_equal(3)
	var many:Array=[]
	for k in 40: many.append({"seed":100+k,"home_force_id":k})
	assert_int(Overlay.battles_to_draw({},many).size()).is_equal(Model.MAX_CLASHES)
	var inputs:=_front_inputs()
	inputs.engagements=[{"pos":Vector2(3,-2),"axis":Vector2.RIGHT,"ours":"flank_attack","theirs":"head_on","rounds":2,"army_id":1,"commanded":true},
		{"pos":Vector2(3,2),"axis":Vector2.RIGHT,"ours":"head_on","theirs":"shield_wall","rounds":1,"army_id":2,"commanded":true}]
	var built:=Overlay.compose(inputs)
	assert_int((built.clashes as Array).size()).is_equal(2)
	assert_bool(bool(built.clashes[0].commanded)).is_true()


# --- Fallback from the generals' withdrawal intent -----------------------------------

func test_fallback_follows_the_road_the_general_would_take()->void:
	# A road home that runs north first, then west: one day's march is on it.
	var road:=PackedVector2Array([Vector2(0,-4),Vector2(-10,-4)])
	var back:=Model.withdrawal_point(Vector2.ZERO,road,6.0)
	assert_float(back.distance_to(Vector2(-2,-4))).is_less(0.001)
	# The front's fallback line runs through each holder's own fallback point,
	# not a fixed offset of the front.
	var built:=Overlay.compose(_front_inputs())
	assert_int((built.fallbacks as Array).size()).is_equal(1)
	var line:PackedVector2Array=built.fallbacks[0].points
	for target in [Vector2(-1.5,-2.2),Vector2(-1.2,2.6)]:
		var nearest:=INF
		for p in line: nearest=minf(nearest,p.distance_to(target))
		assert_float(nearest).is_less(0.6)
	# One army alone: a short line across its road back.
	var single:=Model.fallback_from_intent({"points":PackedVector2Array([Vector2(3,-1),Vector2(3,1)])},[{"pos":Vector2(0,0),"fallback":Vector2(-2,0),"frontage":0.5}])
	assert_int(single.size()).is_equal(3)
	assert_float(absf((single[2]-single[0]).normalized().dot(Vector2.LEFT))).is_less(0.01)


func test_a_withdrawing_general_shows_his_road_not_an_attack_arrow()->void:
	var inputs:=_front_inputs()
	inputs.friendly[0]["withdrawing"]=true
	inputs.friendly[0]["objective"]=Vector2(-10,0)
	inputs.friendly[0]["route_home"]=PackedVector2Array([Vector2(-5,-2),Vector2(-10,0)])
	var built:=Overlay.compose(inputs)
	assert_int((built.withdrawals as Array).size()).is_equal(1)
	for arrow in built.arrows: assert_int(int(arrow.get("army_id",0))).is_not_equal(1)


# --- Corps and army groups ----------------------------------------------------------

class FakeCommand extends RefCounted:
	var data:={"nodes":{
		"army":{"id":"army","service":"army","parent":"","level":9,"force_id":-1},
		"c1":{"id":"c1","service":"army","parent":"g","level":7,"force_id":1,"name":"First Corps"},
		"c2":{"id":"c2","service":"army","parent":"g","level":7,"force_id":2,"name":"Second Corps"},
		"d3":{"id":"d3","service":"army","parent":"army","level":5,"force_id":3,"name":"Brigade"},
		"g":{"id":"g","service":"army","parent":"army","level":8,"force_id":-1,"name":"Northern Group"}}}
	func children(id:String)->Array[Dictionary]:
		var out:Array[Dictionary]=[]
		for n:Dictionary in data.nodes.values():
			if String(n.parent)==id: out.append(n)
		return out
	func leaves(id:String)->Array[Dictionary]:
		var n:Dictionary=data.nodes[id]
		if int(n.force_id)>=0: return [n]
		var out:Array[Dictionary]=[]
		for c in children(id): out.append_array(leaves(String(c.id)))
		return out
	func people(record:Dictionary)->int:
		return 65000 if int(record.force_id)>=0 else 130000


func test_corps_and_army_groups_are_marked_only_when_fielded()->void:
	var friendly:=[{"army_id":1,"pos":Vector2(0,0)},{"army_id":2,"pos":Vector2(10,0)},{"army_id":3,"pos":Vector2(20,0)}]
	var marks:=Overlay.echelons_from(FakeCommand.new(),friendly)
	var ids:=marks.map(func(m:Dictionary)->String: return String(m.id))
	assert_array(ids).contains_exactly(["g","c1","c2"])
	assert_bool(bool(marks[0].group)).is_true()
	assert_float((marks[0].pos as Vector2).x).is_equal_approx(5.0,0.001)
	# A people without corps shows none.
	var small:=FakeCommand.new()
	for key in ["c1","c2","g"]: small.data.nodes.erase(key)
	assert_array(Overlay.echelons_from(small,friendly)).is_empty()


# --- Naval and air zones -------------------------------------------------------------

func test_blockade_squeezes_slowly_and_within_bounds()->void:
	var ledger:={}
	var pressure:={"port":{"rate":Blockade.CLOSE_RATE,"cap":Blockade.CLOSE_CAP,"control":0.8,"civ_id":"rival","owner":"player","tactic":"close_blockade","name":"Port"}}
	var levels:Array=[]
	for day in 365:
		ledger=Blockade.step(ledger,pressure if day<240 else {},day)
		levels.append(float(ledger.get("port",{}).get("level",0.0)))
	# Slow: a month in it is still well short of its ceiling.
	assert_float(float(levels[29])).is_less(Blockade.CLOSE_CAP*0.7)
	# Bounded: never above the close-blockade ceiling, whatever the time.
	for level in levels: assert_float(float(level)).is_less_equal(Blockade.CLOSE_CAP+0.0001)
	assert_float(float(levels[239])).is_equal_approx(Blockade.CLOSE_CAP,0.001)
	# Lifted: it eases away within about a month and leaves the ledger.
	assert_bool(ledger.has("port")).is_false()
	# Trade loses at most about half at the ceiling; sea food less.
	assert_float(Blockade.trade_factor(Blockade.CLOSE_CAP)).is_equal_approx(0.52,0.001)
	assert_float(Blockade.sea_food_factor(Blockade.CLOSE_CAP)).is_equal_approx(0.7,0.001)
	# A whole people feels it only in proportion to the people at that port.
	var closure:=Blockade.closure({"port":{"level":0.6,"civ_id":"rival"}},"rival",func(_id:String)->float: return 0.25)
	assert_float(closure).is_equal_approx(0.15,0.0001)
	var distant:=Blockade.rate_and_cap("distant_blockade")
	assert_float(distant.y).is_less(Blockade.CLOSE_CAP)


func test_blockade_ledger_is_saved_and_validated()->void:
	var op:RefCounted=MilitaryCampaign.joint_operations
	var saved:Dictionary=op.export_state()
	assert_bool(saved.has("blockades")).is_true()
	var bad:=saved.duplicate(true); bad.blockades=[]
	assert_str(op.validate(bad)).is_not_empty()
	var old:=saved.duplicate(true); old.erase("blockades")
	assert_str(op.validate(old)).is_empty()


func test_interception_zones_are_air_defence_belts_and_lanes_are_bounded()->void:
	var inputs:=_front_inputs()
	inputs.zones=[{"domain":"air","vertices":PackedVector2Array([Vector2(0,0),Vector2(4,0),Vector2(4,4)]),"control":0.6,"mission":"interception","tactic":"directed_interception"},
		{"domain":"air","vertices":PackedVector2Array([Vector2(0,0),Vector2(4,0),Vector2(4,4)]),"control":0.6,"mission":"air_superiority","tactic":"fighter_sweep"}]
	var lanes:Array=[]
	for k in 20: lanes.append({"points":PackedVector2Array([Vector2(k,0),Vector2(k,9)]),"domain":"navy","escorted":k%2==0})
	inputs.lanes=lanes
	var built:=Overlay.compose(inputs)
	assert_bool(bool(built.zones[0].belt)).is_true()
	assert_bool(bool(built.zones[1].belt)).is_false()
	assert_int((built.lanes as Array).size()).is_equal(Overlay.MAX_LANES)


# --- Motion ----------------------------------------------------------------------------

func test_fronts_ease_toward_new_positions_without_jumps()->void:
	var overlay:Control=auto_free(Overlay.new())
	overlay.set_scene(Overlay.compose(_front_inputs()),true)
	var start:PackedVector2Array=(overlay.live_fronts[0].points as PackedVector2Array).duplicate()
	# Control shifts: their hosts are pushed back a long way.
	overlay.set_scene(Overlay.compose(_front_inputs(3.0)))
	var goal:PackedVector2Array=overlay.live_fronts[0].target
	var sigma:=float(overlay.scene.sigma)
	var largest_step:=0.0
	var last:=start
	var frames:=0
	while overlay.ease_fronts(1.0/60.0) and frames<600:
		frames+=1
		var now:PackedVector2Array=overlay.live_fronts[0].points
		for i in now.size(): largest_step=maxf(largest_step,now[i].distance_to(last[i]))
		last=now.duplicate()
		# Mid-way, the next report arrives: it continues from where it is drawn.
		if frames==20:
			var before:=last.duplicate()
			overlay.set_scene(Overlay.compose(_front_inputs(3.5)))
			var after:PackedVector2Array=overlay.live_fronts[0].points
			for i in after.size(): assert_float(after[i].distance_to(before[i])).is_less(0.0001)
	assert_int(frames).is_less(600)
	# No single frame moves a point by more than a small share of the change.
	assert_float(largest_step).is_less(3.5*0.1)
	var final:PackedVector2Array=overlay.live_fronts[0].points
	assert_float(final[0].distance_to(overlay.live_fronts[0].target[0])).is_less(sigma*0.01)


func test_a_pocket_is_found_and_its_closing_eases()->void:
	var ours:Array=[]
	# Eight hosts ringing one strong enemy host: locally it still holds its
	# ground, so the balance line closes round it.
	for k in 8: ours.append({"id":str(k),"army_id":k+1,"pos":Vector2.from_angle(TAU*float(k)/8.0)*8.0,"strength":5000.0})
	var inputs:={"mode":"front","stage":"reckoned","friendly":ours,"enemy":[{"id":"x","pos":Vector2.ZERO,"strength":40000.0,"age_days":0}]}
	var built:=Overlay.compose(inputs)
	assert_int((built.pockets as Array).size()).is_equal(1)
	assert_float(float(built.pockets[0].closure)).is_greater(0.9)
	var overlay:Control=auto_free(Overlay.new())
	overlay.set_scene(built,true)
	overlay.ease_fronts(1.0/60.0)
	var first:=float(overlay.live_closure[0])
	assert_float(first).is_less(float(built.pockets[0].closure))
	for k in 400: overlay.ease_fronts(1.0/60.0)
	assert_float(float(overlay.live_closure[0])).is_equal_approx(float(built.pockets[0].closure),0.01)


func test_compose_and_draw_stay_cheap_at_theatre_scale()->void:
	var ours:Array=[]; var theirs:Array=[]
	for k in 200: ours.append({"id":str(k),"army_id":k,"pos":Vector2(float(k%20),float(k/20))*3.0,"strength":20000.0,"fallback":Vector2(float(k%20),float(k/20))*3.0+Vector2(-2,0),"objective":Vector2(80,15)})
	for k in 400: theirs.append({"id":"e%d" % k,"pos":Vector2(70.0+float(k%20),float(k/20)*1.5),"strength":15000.0,"age_days":k%40,"moving":k%7==0})
	var start:=Time.get_ticks_usec()
	var built:=Overlay.compose({"mode":"theatre","stage":"reckoned","friendly":ours,"enemy":theirs,"home":Vector2(-40,15)})
	var ms:=float(Time.get_ticks_usec()-start)/1000.0
	assert_float(ms).is_less(60.0)
	assert_int(Overlay.primitive_count(built)).is_less(120)
