extends Node
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_GeneralCampaign_Test"))
	var before:=SaveSystem.save_metadata("pre_general_release")
	var result:=SaveSystem.load_game("pre_general_release")
	assert(result.has("ok"),str(result))
	assert(not GeneralCampaign.active)
	assert(int(GameState.elapsed_days)==int(before.elapsed_days))
	assert(GameState.population_total==int(before.population))
	print("GENERAL_OLD_SAVE_PASS ",result.message)
	get_tree().quit()
