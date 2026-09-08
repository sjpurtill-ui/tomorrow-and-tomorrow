extends "res://tests/test_siege_progression.gd"
func before_test()->void:
	super.before_test()
	GameState.set_process(false);MilitaryCampaign.set_process(false);CivilizationSystem.set_process(false)
	CivilizationSystem.set_scout_geography_authority(func(_at:Vector2)->bool:return true)
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":100000.0}]
func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.set_process(true);MilitaryCampaign.set_process(true);CivilizationSystem.set_process(true)
func _command_fixture(mission:String)->Dictionary:
	var f:=_offensive_fixture()
	var command=MilitaryCampaign.command_hierarchy;command.sync()
	var report:Dictionary=CivilizationSystem.city_intelligence.known("player",f.region)
	MilitaryCampaign.field_armies[0].position=report.position.duplicate(true)
	var region:Dictionary=command.create_region("army",command.R.rectangle(command.G.unpack(report.position),15),"City approaches").region
	var id:=""
	for record:Dictionary in command.children("army"):
		if int(record.force_id)==int(f.army):id=String(record.id)
	var result:Dictionary=command.assign(id,[],region,mission,String(f.region))
	assert_bool(result.has("ok")).override_failure_message(str(result)).is_true()
	f["command_id"]=id;f["zone"]=region;return f
func test_commanded_city_attack_runs_without_mandatory_battle_or_aftermath_screen()->void:
	var f:=_command_fixture("capture");var command=MilitaryCampaign.command_hierarchy
	CivilizationSystem.civilizations[0].player_relation.at_war=false
	var day:=int(GameState.elapsed_days)+1;GameState.elapsed_days=day;command.advance(day)
	assert_bool((command.data.battles[0] if not command.data.battles.is_empty() else {}).get("commander_managed",false)).is_true()
	assert_bool(MilitaryCampaign.active_engagement.get("awaiting_player_view",false)).is_false()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_true()
	for _round in 60:
		if command.data.battles.is_empty():break
		GameState.elapsed_days+=1;command.advance(int(GameState.elapsed_days))
	assert_array(command.data.battles).is_empty()
	assert_dict(MilitaryCampaign.pending_aftermath).is_empty()
	assert_int(MilitaryCampaign.battle_history.size()).is_greater(0)
	assert_int(int(MilitaryCampaign.battle_history[0].home_force_id)).is_equal(int(f.army))
func test_occupation_objective_enters_siege_and_staff_launch_assault_when_ready()->void:
	var f:=_command_fixture("occupy");var command=MilitaryCampaign.command_hierarchy
	GameState.elapsed_days+=1;command.advance(int(GameState.elapsed_days))
	assert_bool(MilitaryCampaign.active_siege.get("commander_managed",false)).is_true()
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	MilitaryCampaign.active_siege.pressure=.8;MilitaryCampaign.active_siege.fatigue=.2
	GameState.elapsed_days+=1;MilitaryCampaign.last_processed_day=int(GameState.elapsed_days);MilitaryCampaign._process_siege_day()
	assert_dict(MilitaryCampaign.active_siege).is_empty()
	assert_bool((command.data.battles[0] if not command.data.battles.is_empty() else {}).get("commander_managed",false)).is_true()
func test_razing_objective_requires_occupation_and_uses_existing_infrastructure_policy()->void:
	var f:=_command_fixture("raze");var command=MilitaryCampaign.command_hierarchy
	var location:Dictionary=CivilizationSystem._region_location(String(f.region))
	var city:Dictionary=CivilizationSystem.civilizations[int(location.owner_index)].strategic_regions[int(location.region_index)]
	city.controller="player";city.damage=.2
	var population:=float(city.population)
	var report:Dictionary=CivilizationSystem.city_intelligence.known("player",String(f.region))
	command.land._city(MilitaryCampaign.field_armies[0],report,{"mission":"raze"},1)
	var changed:Dictionary=CivilizationSystem.civilizations[int(location.owner_index)].strategic_regions[int(location.region_index)]
	assert_bool(changed.get("governance",{}).get("ruined",false)).is_true()
	assert_float(float(changed.damage)).is_equal(1.0)
	assert_float(float(changed.population)).is_equal(population)
