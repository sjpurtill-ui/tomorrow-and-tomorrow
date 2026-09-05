extends Node
class ProgressView extends RefCounted:
	var renders:=0
	func meta()->Dictionary: return {"title":"Audit","subtabs":["Training"]}
	func tab(_sub:int)->Dictionary:
		renders+=1
		return {"blocks":[{"type":"text","text":str(MilitaryCampaign.training_queue[0].progress_days)}]}
	func signature()->Array: return [MilitaryCampaign.training_queue.duplicate(true)]
func _ready()->void:
	GameState.reset_for_new_world(741991); ProgressionSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world()
	GameState.ensure_population_total(10000)
	GameState.society_capacities["security"]=.38
	GameState.population_allocations["Defense"]=0
	GameState.population_health=1; GameState.food_security=1; GameState.housing_capacity=10000
	MilitaryCampaign.raise_recruits(2)
	MilitaryCampaign.start_training("levy","improvised",1)
	MilitaryCampaign.start_training("levy","improvised",1)
	MilitaryCampaign.military_inventory["improvised"]=0
	var logs:Array=[]
	for day in 4:
		GameState.elapsed_days=day+1
		MilitaryCampaign._process_training_day()
		logs.append({"calendar_day":day+1,"effective_days":MilitaryCampaign.training_queue[0].progress_days,"shown_integer":int(MilitaryCampaign.training_queue[0].progress_days),"required":MilitaryCampaign.training_queue[0].required_days})
	var without_equipment:=float(MilitaryCampaign.training_queue[0].progress_days)/4
	MilitaryCampaign.military_inventory["improvised"]=2
	var before:=float(MilitaryCampaign.training_queue[0].progress_days)
	GameState.elapsed_days+=1; MilitaryCampaign._process_training_day()
	var with_equipment:=float(MilitaryCampaign.training_queue[0].progress_days)-before
	assert(with_equipment>without_equipment and without_equipment>0)
	var crowded:=MilitaryCampaign._effective_training_rate(MilitaryCampaign.training_capacity()*4)
	assert(crowded<MilitaryCampaign._effective_training_rate(2))
	# Reproduce background refresh suppression using only the isolated viewport.
	var hud:=preload("res://scripts/hud/command_rail_hud.gd").new()
	var panel:=preload("res://scripts/hud/dock_panel.gd").new(); add_child(panel)
	panel.position=panel.get_global_mouse_position()-Vector2(10,10); panel.size=Vector2(540,800)
	hud.dock=panel
	var provider:=ProgressView.new(); panel.present(provider)
	hud._dock_signature=provider.signature()+[0]
	var rendered:=provider.renders
	MilitaryCampaign._process_training_day()
	assert(hud._dock_interaction_active(panel))
	hud.live_refresh_dock()
	assert(provider.renders==rendered)
	panel.position=panel.get_global_mouse_position()+Vector2(1000,1000)
	hud.live_refresh_dock()
	assert(provider.renders>rendered)
	print("MILITARY_CONSOLE_AUDIT_PASS ",JSON.stringify({"days":logs,"effective_per_calendar_day_without_equipment":without_equipment,"effective_per_calendar_day_with_equipment":with_equipment,"crowded_rate":crowded,"hover_freezes_display":true,"leaving_panel_refreshes":true,"broken_from_low_condition":preload("res://scripts/military_unit_catalog.gd").readiness_band({"training":.39,"personnel_condition":.2,"morale":1})}))
	hud.free()
	get_tree().quit()
