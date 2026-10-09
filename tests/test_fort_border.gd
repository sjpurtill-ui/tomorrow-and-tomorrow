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

func test_the_border_panel_shows_each_stretch_the_forts_and_the_sites()->void:
	WorldSimulation.military=MilitaryCampaign
	_standing(Vector2(80,0));_standing(Vector2(0,80))
	Forts.ledger(GameState).border_share=1.0
	var blocks:Array=preload("res://scripts/hud/content/border_blocks.gd").blocks(null)
	var headings:PackedStringArray=[]
	for b:Dictionary in blocks:headings.append(String(b.get("heading","")))
	var text:=" | ".join(headings)
	print("BORDER PANEL: ",text)
	assert_str(text).contains("THE BORDER").contains("THE WATCH ON THE BORDER").contains("OUR FORTS").contains("LEAVE A FORT")
	var bars:Array=blocks[0].items
	assert_int(bars.size()).is_equal(2)
	assert_str(String(bars[0].value)).contains("a km")
	var box:=VBoxContainer.new();add_child(box)
	preload("res://scripts/hud/dock_blocks.gd").render(box,blocks)
	assert_int(box.get_child_count()).is_greater(0)
	box.queue_free()

func test_the_line_facing_a_people_is_what_stops_crossings_toward_it()->void:
	_standing(Vector2(80,0));_standing(Vector2(0,80))
	Forts.ledger(GameState).border_share=1.0
	# A point straight through the linked stretch, and one through open ground.
	var through:=Forts.at(Vector2(60,60),GameState)
	var open:=Forts.at(Vector2(-60,-60),GameState)
	assert_float(float(through.strength)).is_greater(float(open.strength)*5.0)
