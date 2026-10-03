extends Node
## Learning pace per learner (docs/PEOPLE_FIRST.md A): runs the REAL daily
## engine headless on a disposable actor with the learners held at a fixed
## count, and writes the known discoveries by year and the day each of the
## first questions landed. Never launches or touches the player's game. The
## same file runs on an older checkout to compare engines.
## Usage:
##   Godot --headless --path <worktree> res://tools/sim/learning_pace_probe.tscn -- --learners=3 --seed=74119 --years=16 --out=<file.json>
const Day=preload("res://scripts/civilization_day.gd")
const Manual=preload("res://scripts/manual_work.gd")
const DOMAINS:Array[String]=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
const SENSIBLE:={"demography":2,"nutrition":3,"health":3,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":1,"culture":1}

func _arg(name:String,fallback:String)->String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % name):return arg.substr(name.length()+3)
	return fallback

func _ready()->void:
	var learners:=int(_arg("learners","3"))
	var seed_value:=int(_arg("seed","74119"))
	var years:=int(_arg("years","16"))
	var out:=_arg("out","user://learning_pace_%d_%d.json" % [learners,seed_value])
	var result:=await _run(learners,seed_value,years)
	var file:=FileAccess.open(out,FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	WorldSimulation.clear()
	print("LEARNING_PACE ",out," learners=",learners," known=",result.known_by_year," seconds=",result.seconds)
	get_tree().quit(0)

## The ruler's split with `learners` people at learning and the rest of the
## work in the shares it stood in.
func _hold(learners:int)->void:
	var state:=WorldSimulation.state
	var counts:=Manual.counts()
	var able:=0
	for role:String in Manual.ROLES:able+=int(counts[role])
	if able<=0:return
	var others:=0.0
	for role:String in Manual.ROLES:
		if role!="Knowledge":others+=float(counts[role])
	var shares:={}
	var knowledge:=clampf(float(learners)/float(able),0.0,0.9)*100.0
	for role:String in Manual.ROLES:
		if role=="Knowledge":shares[role]=knowledge
		else:shares[role]=(float(counts[role])/maxf(1.0,others))*(100.0-knowledge)
	var direction=WorldSimulation.direction
	direction.ensure()
	direction.automatic_work=false
	direction.work_baseline=shares
	for role:String in shares:state.population_allocation_percentages[role]=float(shares[role])
	state.synchronize_population_allocations()

func _run(learners:int,seed_value:int,years:int)->Dictionary:
	WorldSimulation.clear()
	# A good site with water half a kilometre off and its materials at hand
	# (truth_probe.gd's "good" site): a village that can feed and equip itself.
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
		var profile:Dictionary=PlanetEnvironment.profile_at(origin).duplicate(true)
		profile.merge({"forage":0.62,"game":0.52,"fertility":0.58,"growing_season":0.62,"water_access":0.62,"rainfall_variability":0.30,"precipitation":0.55},true)
		var wood:={"position":Vector3(origin.x,0,origin.y),"density":0.55,"area_km2":9.0}
		return {"environment_profile":profile,"surface_water_distance_km":0.5,"surface_water_recognized":true,"woodland_catchment":wood,
			"surface_material_catchments":{"Timber":wood,"Stone":{"position":Vector3(origin.x,0,origin.y),"density":0.35,"area_km2":9.0},"Fiber Plants":{"position":Vector3(origin.x,0,origin.y),"density":0.5,"area_km2":9.0}}}
	WorldSimulation.create_actor("lp",seed_value,Vector2.ZERO)
	WorldSimulation.enabled=true
	WorldSimulation.scoped("lp",func()->void:
		WorldSimulation.state.ensure_population_total(120)
		WorldSimulation.world.scout_land_authority=func(_p:Vector2)->bool:return true
	)
	WorldSimulation.submit("lp",{"kind":"ambition","id":"makers"})
	WorldSimulation.submit("lp",{"kind":"found"})
	for domain in DOMAINS:
		WorldSimulation.submit("lp",{"kind":"research_emphasis","domain":domain,"weight":int(SENSIBLE.get(domain,0))})
	var holder:={"starting":0,"known_by_year":{},"first_days":[],"learners_sum":0.0,"days":0,"population":{},"why":{}}
	var start:=Time.get_ticks_msec()
	WorldSimulation.scoped("lp",func()->void:holder.starting=WorldSimulation.state.known_discoveries.size())
	for day in range(1,years*365+1):
		WorldSimulation.scoped("lp",func()->void:
			var state:=WorldSimulation.state
			state.elapsed_days=day
			if day%30==1:
				for index in state.player_settlements.size():state.player_settlements[index]["environment_profile"]=Day.context(Vector2.ZERO).environment_profile
			_hold(learners)
			Day.advance(day,Day.context(Vector2.ZERO))
			holder.learners_sum=float(holder.learners_sum)+float(state.effective_workers("Knowledge"))
			holder.days=int(holder.days)+1
			var gained:=state.known_discoveries.size()-int(holder.starting)
			while (holder.first_days as Array).size()<gained and (holder.first_days as Array).size()<40:(holder.first_days as Array).append(day)
			if day%365==0:
				(holder.known_by_year as Dictionary)[str(day/365)]=gained
				(holder.population as Dictionary)[str(day/365)]=float(state.population_exact)
				(holder.why as Dictionary)[str(day/365)]=_why()
		)
		if day%60==0:await get_tree().process_frame
	return {"learners":learners,"seed":seed_value,"years":years,"starting":holder.starting,"known_by_year":holder.known_by_year,"first_days":holder.first_days,
		"mean_learners":float(holder.learners_sum)/maxf(1.0,float(holder.days)),"population":holder.population,"why":holder.why,"seconds":(Time.get_ticks_msec()-start)/1000.0}

## What sets the pace this year: the teams, their work and support, and the
## multipliers every question shares (read where the engine has them).
func _why()->Dictionary:
	var d=WorldSimulation.discovery
	var state:=WorldSimulation.state
	var teams:Dictionary=d.research_teams()
	var row:={"learners":float(state.effective_workers("Knowledge")),"teams":int(teams.get("count",0)),"placed":int(teams.get("placed",0)),"work":float(teams.get("work",0.0)),
		"knowledge":float(state.simulation_metrics.get("knowledge",0.0)),"food_security":float(state.food_security),"discovery_multiplier":float(WorldSimulation.consequences.discovery_multiplier()),
		"goods":float(state.resource_stockpiles.get("Civilian Goods",0.0)),"education":float(preload("res://scripts/civilization_indicators.gd").education_index(state))}
	for channel:Variant in state.active_investigations:
		var home:=String(channel).split("::")
		var cap:Dictionary=d.research_capacity_for(home[0],home[1],teams)
		row["support"]=float(cap.get("support_multiplier",0.0))
		row["progress_multiplier"]=float(cap.get("progress_multiplier",0.0))
		row["goods_factor"]=float(cap.get("goods_factor",1.0))
		break
	if d.has_method("learning_year"):row["lead"]=float(d.get("learning_lead"))
	return row
