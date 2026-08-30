extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var traveling:="--travel" in OS.get_cmdline_user_args()
	GameState.world_seed=74119
	GameState.province_terrain="Plains"
	GameState.initialize_citizen_registry()
	ConsequenceEngine.initialize()
	var checkpoints:Dictionary={}
	for day in 365:
		GameState.elapsed_days=float(day)
		ConsequenceEngine.process_day({"traveling":traveling})
		if day in [0,29,89,179,274,364]:
			checkpoints[day+1]={
				"stored_days":float(GameState.simulation_metrics.get("food_days",0.0)),
				"intake":float(GameState.simulation_metrics.get("food_intake_ratio",0.0)),
				"deaths":GameState.lifetime_deaths
			}
			print("FOOD_PROBE ",JSON.stringify({
				"day":day+1,"traveling":traveling,"population":GameState.population_total,
				"stored_days":GameState.simulation_metrics.get("food_days",0.0),
				"production":GameState.simulation_metrics.get("food_production",0.0),
				"need":GameState.simulation_metrics.get("food_consumption",0.0),
				"net":GameState.simulation_metrics.get("food_net",0.0),
				"intake":GameState.simulation_metrics.get("food_intake_ratio",0.0),
				"malnutrition":GameState.simulation_metrics.get("malnutrition_burden",0.0),
				"forecast_30":GameState.simulation_metrics.get("food_forecast_30",{}),
				"forecast_90":GameState.simulation_metrics.get("food_forecast_90",{}),
				"deaths":GameState.lifetime_deaths
			}))
	var passed:=true
	if traveling:
		passed=passed and float(checkpoints[30].stored_days)>=8.0 and float(checkpoints[30].stored_days)<=22.0
		passed=passed and float(checkpoints[90].intake)<0.90
		passed=passed and int(checkpoints[365].deaths)>=20 and int(checkpoints[365].deaths)<=75
	else:
		passed=passed and float(checkpoints[365].stored_days)>=5.0 and float(checkpoints[365].stored_days)<=45.0
		passed=passed and float(checkpoints[365].intake)>=0.98
		passed=passed and int(checkpoints[365].deaths)<=5
	if not passed:
		push_error("Food balance regression: %s" % JSON.stringify(checkpoints))
		get_tree().quit(1)
		return
	print("FOOD_BALANCE_PASS ","traveling" if traveling else "halted")
	get_tree().quit(0)
