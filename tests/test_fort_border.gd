extends GdUnitTestSuite
## Forts and the watched border (fort_border.gd): forts span the border, the
## watch between them sets each stretch's strength, crossings are caught at
## it, and the forts cost food lost on the road and upkeep.

const Forts:=preload("res://scripts/fort_border.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(424242)
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.player_settlements=[{"id":"seat","primary":true,"position":Vector2.ZERO,"claim_radius_km":5.0}]
	GameState.ensure_population_total(5000)
	GameState.population_allocations["Defense"]=600
	GameState.resource_stockpiles={"Timber":5000.0,"Stone":5000.0,"Fiber Plants":500.0,"Clay":500.0,"Food":50000.0}
	GameState.known_discoveries=["joinery"]
	# These tests place their own forts: no old posts counted.
	GameState.border_forts={"seeded":true}
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":400.0}]
	CivilizationSystem.fog_revision+=1

func after_test()->void:
	GameState.border_forts={}

func _standing(at:Vector2,kind:String="palisade_fort")->Dictionary:
	var d:=Forts.ledger(GameState)
	var fort:={"id":int(d.next_id),"kind":kind,"x":at.x,"z":at.y,"status":"standing","condition":1.0,"progress":0.0,"name":"test"}
	d.next_id=int(d.next_id)+1
	(d.forts as Array).append(fort)
	return fort

func test_without_forts_a_people_holds_only_its_home_country()->void:
	var shape:=Forts.outline(GameState)
	assert_float(float(shape.reach)).is_equal_approx(5.0+Forts.HOME_KM,0.01)
	assert_bool(Forts.inside(Vector2(29,0),GameState)).is_true()
	assert_bool(Forts.inside(Vector2(31,0),GameState)).is_false()

func test_a_fort_pushes_the_border_out_and_linked_forts_enclose_the_land_between()->void:
	_standing(Vector2(80,0))
	assert_bool(Forts.inside(Vector2(100,0),GameState)).is_true()
	assert_bool(Forts.inside(Vector2(0,80),GameState)).is_false()
	_standing(Vector2(0,80))
	assert_int(Forts.links(GameState).size()).is_equal(1)
	# Between them, 75 km out on the diagonal, is ours only once they are linked.
	assert_bool(Forts.inside(Vector2(53,53),GameState)).is_true()
	# Too far apart to link: the ground between stays open.
	GameState.border_forts={"seeded":true}
	_standing(Vector2(300,0));_standing(Vector2(0,300))
	assert_int(Forts.links(GameState).size()).is_equal(0)

func test_watchmen_per_km_set_each_stretchs_strength_and_open_ground_is_porous()->void:
	_standing(Vector2(80,0));_standing(Vector2(0,80))
	Forts.ledger(GameState).border_share=1.0
	var kept:=Forts.watch(GameState)
	# 600 out: 120 in the two garrisons, 480 along one 113 km stretch.
	assert_int(int(kept.garrisons.values()[0])).is_equal(60)
	var s:Dictionary=kept.stretches[0]
	assert_float(float(s.watchmen)).is_equal_approx(480.0,0.5)
	assert_float(float(s.strength)).is_equal_approx(1.0-exp(-480.0/113.137/Forts.WATCH_KM),0.001)
	var on_line:=Forts.at(Vector2(60,60),GameState,kept)
	assert_str(String(on_line.kind)).is_equal("line")
	var open:=Forts.at(Vector2(-60,-60),GameState,kept)
	assert_str(String(open.kind)).is_equal("open")
	assert_float(float(open.strength)).is_equal(Forts.OPEN_STRENGTH)
	# A thin line: a tenth of the watch out.
	Forts.ledger(GameState).border_share=0.3
	var thin:=Forts.watch(GameState)
	assert_float(float(thin.stretches[0].strength)).is_less(float(s.strength))

func test_food_carried_out_is_lost_more_the_farther_the_fort()->void:
	assert_float(Forts.transit_loss(0.0)).is_equal(0.0)
	assert_float(Forts.transit_loss(60.0)).is_between(0.3,0.36)
	assert_float(Forts.transit_loss(120.0)).is_greater(Forts.transit_loss(60.0))
	_standing(Vector2(40,0));var far:=_standing(Vector2(120,0))
	Forts.ledger(GameState).border_share=1.0
	var bill:=Forts.costs(GameState)
	var near_post:Dictionary=bill.posts[0];var far_post:Dictionary=bill.posts[1]
	assert_float(float(far_post.lost)).is_greater(float(near_post.lost)*2.0)
	assert_float(float(bill.upkeep.Timber)).is_equal_approx(1.6,0.001)

func test_raising_a_fort_takes_its_materials_and_its_garrisons_work()->void:
	var timber:=float(GameState.resource_stockpiles.Timber)
	var made:=Forts.build(Vector2(60,0))
	assert_bool(bool(made.get("ok",false))).override_failure_message(str(made)).is_true()
	assert_str(String(made.fort.kind)).is_equal("palisade_fort")
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(timber-220.0)
	assert_str(String(made.fort.status)).is_equal("building")
	# A fort going up holds no ground yet.
	assert_bool(Forts.inside(Vector2(70,0),GameState)).is_false()
	GameState.resource_stockpiles={"Timber":10.0}
	assert_str(String(Forts.build(Vector2(0,60)).get("error",""))).contains("Timber")

func test_the_crossing_is_caught_at_the_stretchs_strength_less_stealth()->void:
	_standing(Vector2(80,0));_standing(Vector2(0,80))
	Forts.ledger(GameState).border_share=1.0
	var strength:=float(Forts.at(Vector2(60,60),GameState).strength)
	assert_float(Forts.catch(Vector2(60,60),0.0,GameState)).is_equal_approx(strength,0.0001)
	assert_float(Forts.catch(Vector2(60,60),1.0,GameState)).is_equal_approx(strength*0.6,0.0001)
	assert_float(Forts.catch(Vector2(-60,-60),0.5,GameState)).is_less(0.05)

func test_an_older_people_counts_its_old_border_posts_once()->void:
	GameState.border_forts={}
	var Realm:=preload("res://scripts/realm_reach.gd")
	var old:=float(Realm.ours().get("reach",0.0))
	Forts.seed_old_posts()
	if old<Forts.home_km()*1.5:
		assert_array(Forts.forts()).is_empty()
		return
	assert_int(Forts.forts().size()).is_greater_equal(3)
	for f:Dictionary in Forts.forts():
		assert_str(String(f.status)).is_equal("standing")
		assert_bool(bool(f.old_post)).is_true()
	var count:=Forts.forts().size()
	Forts.seed_old_posts()
	assert_int(Forts.forts().size()).is_equal(count)

func test_the_quote_says_what_a_fort_there_costs_and_gains()->void:
	_standing(Vector2(80,0))
	var q:=Forts.quote(Vector2(0,80))
	assert_str(String(q.problem)).is_equal("")
	assert_str(String(q.kind)).is_equal("palisade_fort")
	assert_float(float(q.km)).is_equal_approx(80.0,0.01)
	assert_float(float(q.cost.Timber)).is_equal(220.0)
	assert_int(int(q.days)).is_equal(100)
	assert_float(float(q.food_lost)).is_greater(0.0)
	# It links to the fort at (80, 0) and encloses the ground between.
	assert_int((q.links as Array).size()).is_equal(1)
	assert_float(float(q.gain_km2)).is_greater(PI*32.0*32.0*0.5)
	# The quote changes nothing.
	assert_int(Forts.forts().size()).is_equal(1)
	# Home ground needs no fort; nor does a spot beside another fort.
	assert_str(String(Forts.quote(Vector2(5,0)).problem)).contains("home")
	assert_str(String(Forts.quote(Vector2(82,0)).problem)).contains("Too close")
	GameState.resource_stockpiles={"Timber":10.0}
	assert_str(Forts.short_words(Forts.quote(Vector2(0,80)))).contains("210 more timber")

func test_the_god_places_a_fort_and_breaks_it_down_for_part_of_its_materials()->void:
	var made:=Forts.place(Vector2(0,80))
	assert_bool(bool(made.get("ok",false))).override_failure_message(str(made)).is_true()
	var fort:Dictionary=made.fort
	fort.status="standing";fort.condition=1.0
	assert_bool(Forts.inside(Vector2(0,100),GameState)).is_true()
	var timber:=float(GameState.resource_stockpiles.Timber)
	var broken:=Forts.dismantle(int(fort.id))
	assert_float(float(broken.recovered.Timber)).is_equal_approx(220.0*Forts.RECOVER,0.01)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber+110.0,0.01)
	assert_array(Forts.forts()).is_empty()
	assert_bool(Forts.inside(Vector2(0,100),GameState)).is_false()
	assert_str(String(Forts.place(Vector2(3,0)).get("error",""))).contains("home")

func test_a_moved_fort_goes_up_again_where_it_is_set_down_keeping_part_of_its_work()->void:
	var fort:=_standing(Vector2(80,0))
	var timber:=float(GameState.resource_stockpiles.Timber)
	var moved:=Forts.move(int(fort.id),Vector2(0,120))
	assert_bool(bool(moved.get("ok",false))).override_failure_message(str(moved)).is_true()
	assert_float(float(fort.z)).is_equal(120.0)
	assert_str(String(fort.status)).is_equal("building")
	assert_float(float(fort.progress)).is_equal_approx(6000.0*Forts.MOVE_KEEP,0.01)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber-220.0*Forts.MOVE_COST,0.01)
	# Until it stands again the border is home ground only.
	assert_bool(Forts.inside(Vector2(100,0),GameState)).is_false()
	assert_str(String(Forts.move(999,Vector2(0,60)).get("error",""))).contains("No such")
	# Unknown land takes no fort.
	assert_str(String(Forts.quote(Vector2(0,450)).problem)).contains("do not know")

func test_the_border_mode_keys_the_border_and_a_forts_note_moves_or_breaks_it_down()->void:
	var fort:=_standing(Vector2(80,0))
	var host:=Node3D.new();add_child(host)
	var map:Node=load("res://scripts/hud/border_map.gd").new();map.set("terrain",host);host.add_child(map)
	map.call("set_enabled",true)
	map.call("_refresh_key")
	var key:PanelContainer=map.get("key_card")
	var words:=_texts(key)
	assert_str(words).contains("1 fort").contains("Click open land to raise a palisade fort")
	map.call("open_note",int(fort.id))
	var note:PanelContainer=map.get("note")
	assert_str(_texts(note)).contains("PALISADE FORT").contains("Move").contains("Break down").contains("gives back")
	map.call("start_move",int(fort.id))
	assert_int(int(map.get("moving"))).is_equal(int(fort.id))
	assert_bool(bool(map.call("_let_go"))).is_true()
	assert_int(int(map.get("moving"))).is_equal(-1)
	for b:Node in note.find_children("*","Button",true,false):
		if (b as Button).text=="Break down":(b as Button).pressed.emit()
	assert_array(Forts.forts()).is_empty()
	host.queue_free()

func _texts(root:Node)->String:
	var out:PackedStringArray=[]
	for n:Node in root.find_children("*","",true,false):
		if n is Label:out.append((n as Label).text)
		elif n is Button:out.append((n as Button).text)
	return " | ".join(out)

func test_every_kind_of_fort_has_its_own_chart_mark()->void:
	var Icons:=preload("res://scripts/resource_icons.gd")
	var seen:={}
	for k:Dictionary in Forts.KINDS:
		for building:String in ["",":building"]:
			var image:=Icons.chart_texture("fort:%s%s" % [String(k.id),building],Color("#7b2a7a"),40).get_image()
			assert_int(image.get_width()).is_equal(40)
			seen[image.get_data()]=true
	assert_int(seen.size()).is_equal(Forts.KINDS.size()*2)

func test_the_line_facing_a_people_is_what_stops_crossings_toward_it()->void:
	_standing(Vector2(80,0));_standing(Vector2(0,80))
	Forts.ledger(GameState).border_share=1.0
	# A point straight through the linked stretch, and one through open ground.
	var through:=Forts.at(Vector2(60,60),GameState)
	var open:=Forts.at(Vector2(-60,-60),GameState)
	assert_float(float(through.strength)).is_greater(float(open.strength)*5.0)
