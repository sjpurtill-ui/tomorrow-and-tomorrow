extends "res://tests/test_siege_progression.gd"
func test_maintain_is_idempotent_and_never_changes_time_or_enters_battle()->void:
	_begin_home()
	var snapshot:Dictionary=MilitaryCampaign.export_state().duplicate(true)
	var day:=GameState.elapsed_days
	for attempt in 100:assert_bool(MilitaryCampaign.siege_order(String(MilitaryCampaign.active_siege.id),"continue").get("ok",false)).is_true()
	assert_dict(MilitaryCampaign.export_state()).is_equal(snapshot)
	assert_float(GameState.elapsed_days).is_equal(day)
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
func test_archived_siege_finds_its_own_battle_and_not_unrelated_active_battle()->void:
	_begin_home()
	var identity:=String(MilitaryCampaign.active_siege.id)
	var seed_value:=int(MilitaryCampaign.active_siege.threat.seed)
	MilitaryCampaign._end_siege("Test archived",false)
	MilitaryCampaign.battle_history=[{"seed":seed_value+1,"outcome":"attacker_victory"},{"seed":seed_value,"outcome":"defender_victory"}]
	MilitaryCampaign.active_engagement={"seed":seed_value+2}
	var snapshot:Dictionary=MilitaryCampaign.siege_visual_snapshot(identity)
	assert_bool(snapshot.battle_active).is_false()
	assert_int(int(snapshot.battle.seed)).is_equal(seed_value)
	assert_str(String(snapshot.battle.outcome)).is_equal("defender_victory")
