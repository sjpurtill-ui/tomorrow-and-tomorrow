extends Node

const SIM_SCRIPT:=preload("res://scripts/combat_simulator.gd")
const RUNS:=200


func _ready()->void:
	var simulator=SIM_SCRIPT.new()
	var win_rates:Dictionary={}
	var scenarios:Array[Dictionary]=[
		{"name":"line_vs_levy","attacker":[{"unit":"line_infantry","weapon":"spear","count":100,"equipment":100}],"defender":[{"unit":"levy","weapon":"improvised","count":100,"equipment":100}]},
		{"name":"skirmishers_vs_levy","attacker":[{"unit":"skirmisher","weapon":"bow","count":100,"equipment":100,"ammunition":600}],"defender":[{"unit":"levy","weapon":"improvised","count":100,"equipment":100}]},
		{"name":"artillery_vs_line","attacker":[{"unit":"field_artillery","weapon":"field_gun","count":100,"equipment":20,"ammunition":160}],"defender":[{"unit":"line_infantry","weapon":"spear","count":100,"equipment":100}]},
		{"name":"mixed_vs_line","attacker":[{"unit":"line_infantry","weapon":"spear","count":70,"equipment":70},{"unit":"field_artillery","weapon":"field_gun","count":30,"equipment":6,"ammunition":48}],"defender":[{"unit":"line_infantry","weapon":"spear","count":100,"equipment":100}]},
		{"name":"empty_artillery_vs_line","attacker":[{"unit":"field_artillery","weapon":"field_gun","count":100,"equipment":20,"ammunition":0}],"defender":[{"unit":"line_infantry","weapon":"spear","count":100,"equipment":100}]}
	]
	for scenario in scenarios:
		var wins:=0; var attacker_losses:=0; var defender_losses:=0; var rounds:=0
		for seed in RUNS:
			var attacker:Dictionary=simulator.create_formation_force("A",scenario.attacker,1.0,1.0)
			var defender:Dictionary=simulator.create_formation_force("D",scenario.defender,1.0,1.0)
			var result:Dictionary=simulator.simulate(attacker,defender,{"seed":seed+1000})
			if String(result.get("winner",""))=="A": wins+=1
			attacker_losses+=int(result.attacker.casualties); defender_losses+=int(result.defender.casualties); rounds+=int(result.round_count)
		var win_rate:=float(wins)/RUNS; win_rates[scenario.name]=win_rate
		print("BALANCE %s win=%d%% losses=%.1f/%.1f rounds=%.1f" % [scenario.name,roundi(win_rate*100.0),float(attacker_losses)/RUNS,float(defender_losses)/RUNS,float(rounds)/RUNS])
	var failures:Array[String]=[]
	if float(win_rates.artillery_vs_line)<0.45 or float(win_rates.artillery_vs_line)>0.80: failures.append("Supplied artillery should be powerful but not certain against equal line infantry.")
	if float(win_rates.mixed_vs_line)<0.45: failures.append("Adding supplied artillery support should not weaken a line force.")
	if float(win_rates.empty_artillery_vs_line)>0.10: failures.append("Artillery without rounds should be combat ineffective.")
	if not failures.is_empty():
		for failure in failures: push_error(failure)
		get_tree().quit(1)
		return
	get_tree().quit(0)
