extends Node
## Synthetic history-size stress: actual map refresh and completed-work code.
## No save IO and no player window. Counts are workloads, not simulated ages.
func _ready()->void:call_deferred("run")
func run()->void:
	if DisplayServer.get_name()!="headless":get_tree().quit(2);return
	var terrain=load("res://scripts/local_terrain.gd").new()
	var rows:Array=[]
	for count:int in [0,64,256,1024]:
		CivilizationSystem.revealed_areas.clear()
		for index in count:
			var points:Array=[]
			for point in 64:points.append({"x":float(index+point),"z":float(index-point)})
			CivilizationSystem.revealed_areas.append({"kind":"trail","x":float(index),"z":float(index),"radius":4.0,"points":points,"day":index,"source":"returned scouts"})
		CivilizationSystem.fog_revision=count+1
		terrain.rendered_fog_revision=CivilizationSystem.fog_revision
		var begin:=Time.get_ticks_usec()
		for frame in 120:terrain._refresh_discovery_mask()
		rows.append({"areas":count,"points_per_trail":64,"unchanged_frame_us":float(Time.get_ticks_usec()-begin)/120.0})
	terrain.free()
	WorldSimulation.create_actor("history_stress",432)
	var building_rows:Array=[]
	WorldSimulation.scoped("history_stress",func()->void:
		var state=WorldSimulation.state
		state.settlement_completed.assign(["Lean-to Shelters","Framed Hall"])
		state.settlement_plots.clear()
		var events:Array[Dictionary]=[]
		for count:int in [0,1000,10000,100000]:
			state.building_ledger.clear()
			for index in count:state.building_ledger.append({"kind":"unrelated construction","counts_materials":true,"settlement_id":"other","day":index,"materials":{"Timber":12.0}})
			var begin:=Time.get_ticks_usec()
			for day in 30:WorldSimulation.settlements._synchronize_early_works(day,events)
			building_rows.append({"records":count,"finished_early_works_us":float(Time.get_ticks_usec()-begin)/30.0})
	)
	WorldSimulation.clear()
	print("ACCUMULATION_COST ",JSON.stringify({"map":rows,"buildings":building_rows}))
	get_tree().quit()
