extends Node
func _ready()->void:
	if DisplayServer.get_name()!="headless":get_tree().quit(2);return
	var world=load("res://scripts/civilization_system.gd").new()
	var samples:Array=[]
	for count in [1,64,256,1024]:
		world.revealed_areas.clear()
		for index in count:
			var points:Array=[]
			for point in 64:points.append({"x":float((index%32)*800+point),"z":float((index/32)*400+point)})
			world.revealed_areas.append({"kind":"trail","radius":4.0,"points":points})
		world.fog_revision+=1
		var queries:Array[Vector2]=[Vector2(-100,-100),Vector2(100,100),Vector2(24862,12462),Vector2(0,0)]
		var start:=Time.get_ticks_usec()
		var expected:Array[bool]=[]
		for query in queries:
			var found:=false
			for area in world.revealed_areas:
				if world._revealed_record_contains(area,query):found=true;break
			expected.append(found)
		var linear_us:=float(Time.get_ticks_usec()-start)/queries.size()
		start=Time.get_ticks_usec()
		world._position_is_revealed(queries[0])
		var build_us:=Time.get_ticks_usec()-start
		start=Time.get_ticks_usec()
		for repeat in 100:
			for i in queries.size():assert(world._position_is_revealed(queries[i])==expected[i])
		samples.append({"trails":count,"points_per_trail":64,"linear_query_us":linear_us,"indexed_query_us":float(Time.get_ticks_usec()-start)/400.0,"first_query_build_us":build_us,"bucket_references":world._revealed_chart_index.bucket_references})
	print("CHART_QUERY_COST ",JSON.stringify(samples))
	world.free()
	WorldSimulation.create_actor("research_cost",318)
	var research:Array=[]
	WorldSimulation.scoped("research_cost",func()->void:
		var discovery=WorldSimulation.discovery
		var ids:Array=[]
		for entry in discovery.technology_catalog:ids.append(String(entry.id))
		for count in [0,ids.size()/2,ids.size()]:
			WorldSimulation.state.known_discoveries.assign(ids.slice(0,count))
			var expected:Dictionary={}
			var start:=Time.get_ticks_usec()
			for channel in discovery.catalog_by_channel:
				var known:=preload("res://scripts/technology_requirements.gd").index_known(WorldSimulation.state.known_discoveries)
				var found:=false
				for entry in discovery.catalog_by_channel[channel]:
					if discovery._discovery_is_eligible(entry,100000,known):found=true;break
				expected[channel]=found
			var linear_us:=Time.get_ticks_usec()-start
			for channel in expected:assert(discovery._channel_has_candidate(channel,100000)==expected[channel])
			start=Time.get_ticks_usec()
			for repeat in 5:
				for channel in expected:assert(discovery._channel_has_candidate(channel,100000)==expected[channel])
			research.append({"known":count,"channels":expected.size(),"linear_all_channels_us":linear_us,"indexed_all_channels_us":float(Time.get_ticks_usec()-start)/5.0})
	)
	WorldSimulation.clear()
	print("RESEARCH_CANDIDATE_COST ",JSON.stringify(research))
	get_tree().quit()
