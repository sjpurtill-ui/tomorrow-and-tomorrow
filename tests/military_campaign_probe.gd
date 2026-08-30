extends Node


func _ready()->void:
	call_deferred("_run")


func _run()->void:
	GameState.reset_for_new_world(90210)
	GameState.initialize_citizen_registry()
	GameState.resource_stockpiles={"Timber":100.0,"Stone":100.0,"Fiber Plants":100.0,"Iron Ore":100.0,"Food":1000.0}
	MilitaryCampaign.reset_for_new_world()
	var raised:Dictionary=MilitaryCampaign.raise_recruits(12)
	assert(int(raised.raised)==12)
	var production:Dictionary=MilitaryCampaign.queue_equipment_production("improvised",12)
	assert(not production.has("error"))
	var training:Dictionary=MilitaryCampaign.start_training("levy","improvised",12)
	assert(int(training.accepted)==12)
	for day in 14: MilitaryCampaign._process_military_day()
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	assert(int(army.troops)==12)
	assert(int(army.formations[0].equipment)==12)
	assert(int(army.recruits)==0)
	assert((army.training_queue as Array).is_empty())
	assert((army.equipment_queue as Array).is_empty())
	var enemy:Dictionary=MilitaryCampaign.simulator.create_formation_force("Raiders",[{"unit":"levy","weapon":"improvised","count":8,"equipment":8}],0.7,0.8)
	var battle:Dictionary=MilitaryCampaign.resolve_campaign_battle(enemy,{"seed":77,"max_rounds":2})
	assert(not battle.has("error"))
	print("MILITARY_CAMPAIGN_PROBE raised=%d trained=%d equipped=%d battle=%s" % [raised.raised,army.troops,army.formations[0].equipment,battle.outcome])
	get_tree().quit()
