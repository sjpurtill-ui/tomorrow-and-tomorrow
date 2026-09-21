extends GdUnitTestSuite
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(41);MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3.ZERO
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	MilitaryCampaign.military_inventory.improvised=10
func after_test()->void:WorldSimulation.clear()
func army(id:int,x:float=0)->Dictionary:
	return {"army_id":id,"name":"Army","status":"stationed","location_id":"player_home","position":{"x":x,"z":0.0},"formations":[{"id":id,"unit":"levy","weapon":"improvised","count":4,"authorized_count":4,"equipment":0,"equipment_required":4,"ammunition":0,"ammunition_required":0,"training":.4,"experience":0.0,"personnel_condition":1.0}]}
func test_stationed_armies_share_finite_delivery_budget_and_inventory()->void:
	MilitaryCampaign.field_armies.assign([army(1),army(2)])
	var reserve:=MilitaryCampaign.home_army
	var used:=MilitaryCampaign._deliver_stationed_field_equipment(4.0)
	assert_float(used).is_equal_approx(4.0,.00001)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(5)
	assert_int(int(MilitaryCampaign.field_armies[0].formations[0].equipment)).is_equal(4)
	assert_int(int(MilitaryCampaign.field_armies[1].formations[0].equipment)).is_equal(1)
	assert_bool(is_same(reserve,MilitaryCampaign.home_army)).is_true()
	MilitaryCampaign._deliver_stationed_field_equipment(100)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(2)
func test_no_remote_or_moving_equipment_teleportation()->void:
	var moving:=army(2);moving.status="moving"
	MilitaryCampaign.field_armies.assign([army(1,20),moving])
	assert_float(MilitaryCampaign._deliver_stationed_field_equipment(100)).is_equal(0.0)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(10)
func test_sub_item_budget_and_convoy_do_not_issue_equipment()->void:
	MilitaryCampaign.field_armies.assign([army(1)])
	assert_float(MilitaryCampaign._deliver_stationed_field_equipment(.1)).is_equal(0.0)
	GameState.convoy_traveling=true
	assert_float(MilitaryCampaign._deliver_stationed_field_equipment(100)).is_equal(0.0)
