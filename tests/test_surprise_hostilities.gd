extends "res://tests/test_siege_progression.gd"
func _peace_fixture()->Dictionary:
	var fixture:=_offensive_fixture()
	var relation:Dictionary=CivilizationSystem.civilizations[0].player_relation
	relation.at_war=false;relation.treaty="none";relation.trade=0.0;relation.war_id=""
	CivilizationSystem.war_history.clear()
	return fixture
func test_attack_at_peace_starts_one_war_only_after_success()->void:
	var f:=_peace_fixture()
	assert_bool(MilitaryCampaign.offensive_campaign_availability(f.civ,f.region).has("ok")).is_true()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_false()
	assert_array(CivilizationSystem.war_history).is_empty()
	var result:=MilitaryCampaign.launch_offensive(f.civ,f.region)
	assert_bool(result.has("error")).is_false()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_true()
	assert_int(CivilizationSystem.war_history.size()).is_equal(1)
	assert_str(String(MilitaryCampaign.active_engagement.threat.war_id)).is_equal(String(CivilizationSystem.war_history[0].id))
func test_siege_at_peace_starts_war_without_instant_assault()->void:
	var f:=_peace_fixture()
	assert_bool(MilitaryCampaign.start_offensive_siege(f.civ,f.region).has("ok")).is_true()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_true()
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	assert_str(String(MilitaryCampaign.active_siege.threat.war_id)).is_equal(String(CivilizationSystem.war_history[0].id))
func test_rejected_remote_attack_and_siege_preserve_peace()->void:
	var f:=_peace_fixture();MilitaryCampaign.field_armies[0].location_id="player_home"
	assert_bool(MilitaryCampaign.launch_offensive(f.civ,f.region).has("error")).is_true()
	assert_bool(MilitaryCampaign.start_offensive_siege(f.civ,f.region).has("error")).is_true()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_false()
	assert_array(CivilizationSystem.war_history).is_empty()
func test_failed_siege_with_missing_physical_position_does_not_start_war()->void:
	var f:=_peace_fixture();MilitaryCampaign.field_armies[0].position={}
	assert_bool(MilitaryCampaign.start_offensive_siege(f.civ,f.region).has("error")).is_true()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_false()
	assert_dict(MilitaryCampaign.active_threat).is_empty()
func test_existing_war_reuses_its_ledger()->void:
	var f:=_peace_fixture()
	var war:=CivilizationSystem.record_player_hostile_order(f.civ,f.region,"Earlier battle")
	assert_bool(MilitaryCampaign.launch_offensive(f.civ,f.region).has("error")).is_false()
	assert_int(CivilizationSystem.war_history.size()).is_equal(1)
	assert_str(String(MilitaryCampaign.active_engagement.threat.war_id)).is_equal(war)
