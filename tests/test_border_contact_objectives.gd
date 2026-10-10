extends GdUnitTestSuite
## Staff objectives and interception must survive incidental front contact.
const Fixture:=preload("res://tests/test_border_defense_campaign.gd")
const Defense:=preload("res://scripts/border_defense.gd")
var fixture:Node
func before_test()->void:
	fixture=Fixture.new();add_child(fixture)
func after_test()->void:
	fixture.after_test();fixture.free()
func test_commanded_neutral_invasion_can_begin_contact_before_city_claim()->void:
	fixture._start_world()
	CivilizationSystem.civilizations[0].player_relation.at_war=false
	var made:Dictionary=MilitaryCampaign.create_field_army(200)
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(made.army.army_id))]
	var land=MilitaryCampaign.command_hierarchy.land
	land.refresh_claims()
	var order:={"mission":"capture","target":String(fixture.city_id)}
	land._move(army,fixture.capital,order,int(GameState.elapsed_days))
	var at:Dictionary=army.position.duplicate(true)
	land._move(army,fixture.capital,order,int(GameState.elapsed_days)+1)
	print("REVIEW_NEUTRAL ",{"position":army.position,"same_place":army.position==at,"battles":MilitaryCampaign.own_engagements.size(),"status":army.get("command_status",""),"war":CivilizationSystem.civilizations[0].player_relation.at_war,"known_city":order.target})
	assert_int(MilitaryCampaign.own_engagements.size()).is_greater(0)
func test_contacting_intervening_front_preserves_intercept_target()->void:
	fixture._start_world();CivilizationSystem.civilizations[0].player_relation.at_war=true
	var quarry:Dictionary=CivilizationSystem.foreign_formations[0].duplicate(true)
	quarry.id="quarry";quarry.command_position={"x":fixture.capital.x,"z":fixture.capital.y};quarry.erase("border_sector")
	CivilizationSystem.foreign_formations.append(quarry)
	var made:Dictionary=MilitaryCampaign.create_field_army(200)
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(made.army.army_id))]
	army.position={"x":fixture.origin.x+2.7,"z":fixture.origin.y};army.target_formation_id="quarry";army.order_kind="intercept"
	army.destination_position=quarry.command_position.duplicate(true);army.status="moving"
	var p:=Defense.point(army.position)
	var contact:=Defense.first_contact(p,p,MilitaryCampaign.command_hierarchy.land.enemies(int(GameState.elapsed_days)),army)
	assert_dict(contact).is_not_empty()
	if contact.is_empty():return
	var result:Dictionary=MilitaryCampaign.launch_front_contact(int(army.army_id),contact)
	print("REVIEW_INTERCEPT ",{"result_error":result.get("error",""),"met":contact.formation_id,"retained":army.get("target_formation_id",""),"battles":MilitaryCampaign.own_engagements.size()})
	assert_str(String(army.get("target_formation_id",""))).is_equal("quarry")
