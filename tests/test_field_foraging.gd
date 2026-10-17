extends GdUnitTestSuite
const Forage:=preload("res://scripts/field_foraging.gd")
const Council:=preload("res://scripts/war_council.gd")
const Rations:=preload("res://scripts/field_rations.gd")
var processing:Dictionary={}

func before_test()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:
		processing[node]=node.is_processing();node.set_process(false)
	WorldSimulation.clear()
	MilitaryCampaign.field_armies.clear()

func after_test()->void:
	MilitaryCampaign.field_armies.clear()
	WorldSimulation.clear()
	for node:Node in processing:node.set_process(processing[node])

func test_capacity_is_absolute_and_large_armies_need_the_remainder()->void:
	for men in [10,20,40,80]:
		var fed:=minf(float(men),Forage.factor({},Vector2(100,100),100,0.42,0.0,men)*men)
		assert_float(fed).is_equal(minf(men,20.0))
	assert_float(Forage.capacity(0.63,0.0)).is_equal_approx(30.0,0.001)
	assert_float(Forage.capacity(0.42,1.0)).is_equal_approx(6.0,0.001)
	assert_float(Forage.capacity(0.126,0.0)).is_equal_approx(6.0,0.001)

func test_nearby_bands_share_and_splitting_does_not_create_food()->void:
	var p:=CivilizationSystem.player_world_origin+Vector2(100,100)
	var a:={"army_id":51,"troops":20,"status":"stationed","position":{"x":p.x,"z":p.y}}
	var b:=a.duplicate(true);b.army_id=52
	MilitaryCampaign.field_armies.assign([a,b])
	var first:=Forage.factor(Forage.snapshot(a),p,100,0.42,0.0,20)*20.0
	var second:=Forage.factor(Forage.snapshot(b),p,100,0.42,0.0,20)*20.0
	assert_float(first).is_equal(10.0)
	assert_float(second).is_equal(10.0)
	assert_float(first+second).is_equal(Forage.factor({},p,100,0.42,0.0,40)*40.0)
	assert_float(Forage.take(p,100,0.42,0.0,first,1.0)).is_equal(10.0)
	# The first band eating does not reduce the second band's opening allowance.
	assert_float(Forage.factor(Forage.snapshot(b),p,100,0.42,0.0,20)*20.0).is_equal(10.0)
	assert_float(Forage.take(p,100,0.42,0.0,second,1.0)).is_equal(10.0)
	assert_float(Forage.take(p,100,0.42,0.0,20.0,1.0)).is_equal(0.0)

func test_depleted_ground_survives_leaving_save_reload_and_recovers()->void:
	var p:=Vector2(102,102)
	for day in range(100,120):Forage.take(p,day,0.42,0.0,20.0,1.0)
	var key:=Forage.district(p)
	var before:=Forage.left(WorldSimulation.forage_land[key],120)
	assert_float(before).is_less(0.65)
	assert_float(Forage.factor(Forage.snapshot(),Vector2(200,200),120,0.42,0.0,20)).is_equal(1.0)
	var saved:=WorldSimulation.export_state()
	assert_bool(WorldSimulation.check_payload(saved).has("error")).is_false()
	assert_float(Forage.left(WorldSimulation.forage_land[key],120)).is_equal(before)
	WorldSimulation.clear()
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_false()
	assert_float(Forage.left(WorldSimulation.forage_land[key],120)).is_equal(before)
	assert_float(Forage.left(WorldSimulation.forage_land[key],180)).is_equal(1.0)
	var legacy:=saved.duplicate(true);legacy.erase("forage_land")
	assert_bool(WorldSimulation.import_state(legacy).has("error")).is_false()
	assert_dict(WorldSimulation.forage_land).is_empty()

func test_invalid_forage_save_is_rejected_without_changing_live_ground()->void:
	Forage.take(Vector2(100,100),100,.42,0.0,10.0,1.0)
	var saved:=WorldSimulation.export_state()
	var bad:=saved.duplicate(true)
	bad.forage_land.values()[0]["debt"]=-1.0
	assert_bool(WorldSimulation.import_state(bad).has("error")).is_true()
	assert_dict(WorldSimulation.forage_land).is_equal(saved.forage_land)

func test_raids_return_for_losses_hunger_or_deadline()->void:
	var a:={"troops":20,"train_days":3.0,"provision_ratio":1.0,"council":{"since":100,"starting_troops":20}}
	assert_str(Council.raid_return_reason(a,101)).is_empty()
	a.troops=15
	assert_str(Council.raid_return_reason(a,101)).contains("quarter")
	a.troops=20;a.train_days=0.5;a.provision_ratio=0.5;a["hungry_days"]=2.0
	assert_str(Council.raid_return_reason(a,101)).contains("food")
	a.provision_ratio=1.0
	assert_str(Council.raid_return_reason(a,114)).contains("deadline")

func test_carried_food_and_foraging_add_instead_of_multiplying_the_shortage()->void:
	# Ten rations carried plus twenty gathered can feed thirty soldiers.
	assert_bool(Rations.should_live_off_land(10.0/30.0,20.0/30.0)).is_true()
	assert_bool(Rations.should_live_off_land(0.9,1.0)).is_false()

func test_rival_and_player_bands_use_the_same_district_allowance()->void:
	var p:=CivilizationSystem.player_world_origin+Vector2(180,180)
	WorldSimulation.create_actor("forage_rival",9201,p+Vector2(60,60))
	var a:={"army_id":51,"troops":20,"status":"stationed","position":{"x":p.x,"z":p.y}}
	var b:=a.duplicate(true)
	MilitaryCampaign.field_armies.assign([a])
	WorldSimulation.scoped("forage_rival",func()->void:WorldSimulation.military.field_armies.assign([b]))
	assert_float(Forage.factor(Forage.snapshot(a),p,100,.42,0.0,20)).is_equal(0.5)
	WorldSimulation.scoped("forage_rival",func()->void:
		assert_float(Forage.factor(Forage.snapshot(b),p,100,.42,0.0,20)).is_equal(0.5)
	)
