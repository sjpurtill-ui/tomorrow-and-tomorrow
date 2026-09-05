extends Node
func _ready()->void:
	var result:=SaveSystem.load_game();assert(result.has("ok"))
	print("RECRUITMENT_EVIDENCE=",JSON.stringify({"meta":SaveSystem.save_metadata(),"ledger":MilitaryCampaign.personnel_ledger(),"builds":MilitaryCampaign.army_template_snapshot(),"training_capacity":MilitaryCampaign.training_capacity(),"defense_workers":GameState.population_allocations.get("Defense",0),"health":GameState.population_health,"food_security":GameState.food_security,"strain":MilitaryCampaign.home_army.get("service_strain"),"desertions_total":MilitaryCampaign.home_army.get("desertions_total"),"condition":MilitaryCampaign._force_personnel_condition(MilitaryCampaign.home_army),"equipment":MilitaryCampaign.military_inventory,"training_queue":MilitaryCampaign.training_queue}))
	var before:=MilitaryCampaign._force_personnel_condition(MilitaryCampaign.home_army)
	MilitaryCampaign.home_army.formations[0].personnel_condition=.8
	for i in 20:MilitaryCampaign._refresh_readiness()
	print("REFRESH_ONLY_CONDITION=",MilitaryCampaign.home_army.formations[0].personnel_condition," original=",before)
	get_tree().quit()
