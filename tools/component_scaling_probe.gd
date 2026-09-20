extends SceneTree
const REPEATS:=50
func _initialize()->void:call_deferred("run")
func run()->void:
	var world=root.get_node("WorldSimulation");world.clear();world.create_actor("component_benchmark",318)
	world.scoped("component_benchmark",func()->void:
		var state=world.state;var discovery=world.discovery
		state.settlement_site_committed=true;state.population_allocations.Logistics=20;state.population_allocations.Crafting=20
		var types:Array=["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"]
		var counts:Array=[32,128,512,2048,discovery.catalog.size()]
		var results:Array=[]
		for count:int in counts:
			count=mini(count,discovery.catalog.size());state.known_discoveries.clear()
			for entry in discovery.catalog.slice(0,count):state.known_discoveries.append(String(entry.id));state.discovery_adoption[entry.id]=.75
			var before:=Time.get_ticks_usec();var scalar:Dictionary={}
			for iteration in REPEATS:
				for food:String in types:scalar[food]=discovery.food_storage_multiplier(food,false)
			var scalar_us:=Time.get_ticks_usec()-before
			before=Time.get_ticks_usec();var bulk:Dictionary={}
			for iteration in REPEATS:bulk=discovery.food_storage_multipliers(types,false)
			var bulk_us:=Time.get_ticks_usec()-before
			assert(scalar==bulk)
			results.append({"known_entries":count,"scalar_us_per_call":float(scalar_us)/REPEATS,"bulk_us_per_call":float(bulk_us)/REPEATS,"identical":scalar==bulk})
		print("FOOD_COMPONENT_SCALING ",JSON.stringify(results))
	)
	world.clear();quit()
