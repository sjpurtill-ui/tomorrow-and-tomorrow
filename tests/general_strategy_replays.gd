extends Node
func _ready()->void:
	GameState.civic_api_enabled=false
	var sim:=MilitaryCampaign.simulator
	var report:Array=[]
	for cohort in ["development","held_out"]:
		for strategy in ["prepared_defense","prepared_assault","undersupplied_assault"]:
			var losses:=0;var enemy_losses:=0;var victories:=0
			for index in 12:
				var seed:=100+index if cohort=="development" else 9100+index*37
				var ours:Dictionary=sim.create_formation_force("Alderford",[{"unit":"line_infantry","weapon":"spear","count":180,"equipment":180,"training":.65,"experience":.2},{"unit":"skirmisher","weapon":"bow","count":60,"equipment":60,"ammunition":360,"training":.6,"experience":.2}],.9,.85)
				var theirs:Dictionary=sim.create_formation_force("Hold",[{"unit":"line_infantry","weapon":"spear","count":160,"equipment":160,"training":.58,"experience":.18}],.88,.8)
				ours.commander={"name":"General","command":.65,"tactics":.65,"logistics":.6,"resolve":.6}
				theirs.commander={"name":"Rival","command":.6,"tactics":.6,"logistics":.6,"resolve":.6}
				if strategy=="undersupplied_assault":ours.readiness*=.25
				var result:Dictionary=sim.simulate(ours,theirs,{"seed":seed,"max_rounds":8,"terrain_defense":1.05 if strategy=="prepared_defense" else 1.5,"attacker_exposure_modifier":.65 if strategy=="prepared_defense" else 1.0})
				losses+=240-int(result.attacker.remaining_troops);enemy_losses+=160-int(result.defender.remaining_troops)
				if result.outcome=="attacker_victory":victories+=1
				assert(int(result.attacker.remaining_troops)>=0 and int(result.defender.remaining_troops)>=0)
			report.append({"cohort":cohort,"strategy":strategy,"replays":12,"mean_own_casualties":float(losses)/12,"mean_enemy_casualties":float(enemy_losses)/12,"victories":victories})
	for base in [0,3]:
		assert(float(report[base].mean_own_casualties)<float(report[base+1].mean_own_casualties),"Defense should preserve more of the force")
		assert(float(report[base+1].mean_own_casualties)<float(report[base+2].mean_own_casualties),"Bad supply must have a real cost")
	var file:=FileAccess.open("res://artifacts/general-strategy-replays.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("GENERAL_STRATEGY_REPLAYS_PASS ",JSON.stringify(report))
	get_tree().quit()
