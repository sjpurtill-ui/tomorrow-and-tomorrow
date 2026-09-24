extends Node
## Measures how far exact planet height strays outside the range of the four
## surrounding lattice samples. This calibrates the land-mask certainty margin
## used by PlanetEnvironment's macro bake. Headless, private userdata only.
const SEED:=184271

func _ready()->void:
	if DisplayServer.get_name()!="headless" or not OS.get_user_data_dir().ends_with("TomorrowTerrainBakeTests"):
		get_tree().quit(2);return
	call_deferred("run")

func run()->void:
	var seeds:Array[int]=[SEED,873421,17,99991]
	var count:=200000
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--samples="):count=int(arg.trim_prefix("--samples="))
	var dx:=40075.0/3840.0
	var dz:=20004.0/1920.0
	var alphas:Array[float]=[0.0,0.25,0.5,0.75,1.0]
	for seed_value in seeds:
		GameState.reset_for_new_world(seed_value)
		WorldSimulation.state.world_seed=seed_value
		PlanetEnvironment.reset_for_new_world()
		var rng:=RandomNumberGenerator.new();rng.seed=seed_value
		var worst:Array[float]=[];worst.resize(alphas.size());worst.fill(0.0)
		var worst_flat:=0.0
		var near_threshold:=0
		for i in count:
			var p:=Vector2(rng.randf_range(-20000.0,20000.0),rng.randf_range(-9990.0,9990.0))
			if i%2==0:p=Vector2(rng.randf_range(-3000.0,3000.0),rng.randf_range(-2500.0,2500.0))
			var cx:=floorf((p.x+20037.5)/dx);var cz:=floorf((p.y+10002.0)/dz)
			var x0:=-20037.5+cx*dx;var z0:=-10002.0+cz*dz
			var a:=PlanetEnvironment.world_height_at(Vector2(x0,z0))
			var b:=PlanetEnvironment.world_height_at(Vector2(x0+dx,z0))
			var c:=PlanetEnvironment.world_height_at(Vector2(x0,z0+dz))
			var d:=PlanetEnvironment.world_height_at(Vector2(x0+dx,z0+dz))
			var lo:=minf(minf(a,b),minf(c,d));var hi:=maxf(maxf(a,b),maxf(c,d))
			if hi<-1.0 or lo>3.0:continue
			near_threshold+=1
			var h:=PlanetEnvironment.world_height_at(p)
			var excess:=maxf(lo-h,h-hi)
			for k in alphas.size():worst[k]=maxf(worst[k],excess-alphas[k]*(hi-lo))
			if hi-lo<0.2:worst_flat=maxf(worst_flat,excess)
		print("CALIBRATION seed=",seed_value," relevant=",near_threshold," worst_by_alpha=",worst," worst_flat_cells=",worst_flat)
	get_tree().quit(0)
