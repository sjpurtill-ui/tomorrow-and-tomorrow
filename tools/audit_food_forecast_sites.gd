extends SceneTree
## Isolated overlapping-forecast diagnostic, not a full-campaign benchmark.
func _initialize()->void:call_deferred("run")
func run()->void:
	for id:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(id).set_process(false)
	var world:=root.get_node("WorldSimulation")
	world.clear();world.create_actor("forecast_sites",4242)
	world.scoped("forecast_sites",func()->void:
		var state:Node=world.state;var food:Node=world.food
		var site_count:=17;var day_count:=30
		var harvest:={"Fresh plants":30.0,"Fresh meat":10.0,"Fish":5.0,"Dry staples":12.0}
		var demand:={"total":55.0,"climate":2.0,"rationing":0.0}
		var summaries:Array=[];var warm_sites:=0
		var start:=Time.get_ticks_usec()
		for day in day_count:
			state.elapsed_days=day
			for site in site_count:
				var profile:={"position":Vector2(site*10,-80),"seasonality_c":18.0,"growing_season":.6,"rainfall_variability":.7,"precipitation":.6}
				state.player_settlements.clear();state.player_settlements.append({"id":"home","primary":true,"environment_profile":profile})
				state.food_stocks={"Fresh plants":10.0,"Fresh meat":5.0,"Fish":3.0,"Dry staples":100.0,"Preserved food":20.0}
				for key:Array in food._forecast_climate_cache:
					if key[1]==profile.position:warm_sites+=1;break
				summaries.append(food._forecast(90,harvest,demand,false))
		var result:={"sites":site_count,"days":day_count,"forecasts":summaries.size(),"warm_site_visits":warm_sites,"cache_sites":food._forecast_climate_cache.size(),"summary_hash":JSON.stringify(summaries).sha256_text(),"microseconds":Time.get_ticks_usec()-start,"full_campaign_verified":false}
		print(JSON.stringify(result))
	)
	world.clear();quit()
