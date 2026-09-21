extends GdUnitTestSuite
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(41);MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3.ZERO
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	MilitaryCampaign.home_army.troops=10
	GameState.population_allocations.Logistics=0
func after_test()->void:WorldSimulation.clear()
func force(id:int,x:float)->Dictionary:
	return {"army_id":id,"troops":10,"status":"stationed","location_id":"player_home","position":{"x":x,"z":0.0},"formations":[]}
func test_home_food_has_no_cart_or_field_organization_requirement()->void:
	MilitaryCampaign.field_armies.assign([force(1,0)])
	assert_float(MilitaryCampaign.field_provision_delivery_ratio()).is_equal(1.0)
	MilitaryCampaign.record_daily_provisions(20,20)
	assert_float(float(MilitaryCampaign.home_army.provisions_delivered_today)).is_equal(10.0)
	assert_float(float(MilitaryCampaign.field_armies[0].provisions_delivered_today)).is_equal(10.0)
func test_mixed_home_and_remote_preserve_transport_cost_and_conserve_food()->void:
	MilitaryCampaign.field_armies.assign([force(1,20)])
	var transport:=MilitaryCampaign._field_transport_delivery_ratio()
	assert_float(transport).is_less(1.0)
	var amount:=20*MilitaryCampaign.field_provision_delivery_ratio()
	MilitaryCampaign.record_daily_provisions(20,amount)
	assert_float(float(MilitaryCampaign.home_army.provisions_delivered_today)).is_equal_approx(10.0,.00001)
	assert_float(float(MilitaryCampaign.field_armies[0].provisions_delivered_today)).is_equal_approx(10*transport,.00001)
	assert_float(float(MilitaryCampaign.home_army.provisions_delivered_today)+float(MilitaryCampaign.field_armies[0].provisions_delivered_today)).is_equal_approx(amount,.00001)
func test_scarcity_still_reaches_home_troops_and_moving_forces_need_transport()->void:
	MilitaryCampaign.record_daily_provisions(10,3)
	assert_float(float(MilitaryCampaign.home_army.provision_ratio)).is_equal_approx(.3,.00001)
	var moving:=force(1,0);moving.status="moving"
	MilitaryCampaign.field_armies.assign([moving])
	assert_float(MilitaryCampaign.field_provision_delivery_ratio()).is_less(1.0)
	GameState.convoy_traveling=true
	assert_float(MilitaryCampaign.field_provision_delivery_ratio()).is_equal_approx(MilitaryCampaign._field_transport_delivery_ratio(),.00001)
func test_delivered_credit_only_removes_its_recipient_from_transport_bill()->void:
	MilitaryCampaign.field_armies.assign([force(1,20)])
	var credit:={"total":10.0,"by_army":{1:10.0}}
	assert_float(MilitaryCampaign.field_provision_delivery_ratio(20,credit)).is_equal(1.0)
	MilitaryCampaign.record_daily_provisions(20,10,credit)
	assert_float(float(MilitaryCampaign.home_army.provisions_delivered_today)).is_equal(10.0)
	assert_float(float(MilitaryCampaign.field_armies[0].provisions_delivered_today)).is_equal(10.0)
