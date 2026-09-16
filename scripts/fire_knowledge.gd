extends RefCounted
## Opening fire knowledge. These entries describe learned practice only; every
## downstream operation must still obtain fuel, materials, labor, and adoption.

static func entries()->Array[Dictionary]:
	return ENTRIES

const ENTRIES:Array[Dictionary]=[
	{
		"id":"ember_tending", "name":"Ember Tending", "direction":"Sustenance", "day":0, "chance":0.006,
		"requires":[], "requires_all":[], "requires_any":[], "signals":["fire","timber","crafting"],
		"observation":"Maintain a living ember bed through fuel placement, shelter, and controlled air.",
		"causal_mechanism":"Fuel placement, shelter, and controlled air can keep a living ember bed between uses.",
		"operating_capability":"Preserve an existing natural or transferred fire while dry fuel and repeated attention remain available.",
		"effects":{}, "learning_routes":[{"id":"local","label":"Tending a found or transferred fire","requires_all":[]}],
		"production_contract":"Knowledge does not create flame or fuel. A usable fire still begins with a natural or transferred source, consumes combustible stock, and dies when fuel or attention fails."
	},
	{
		"id":"friction_fire_ignition", "name":"Friction Fire Ignition", "direction":"Sustenance", "day":0, "chance":0.004,
		"requires":["ember_tending"], "requires_all":["ember_tending"], "requires_any":[], "signals":["fire","timber","crafting"],
		"observation":"Concentrate rubbing work into an ember and transfer it into prepared tinder.",
		"causal_mechanism":"Sustained friction in suitable dry wood concentrates enough heat to light prepared tinder.",
		"operating_capability":"Recreate fire without a surviving flame when dry wood, tinder, effort, and practiced handling are available.",
		"effects":{}, "learning_routes":[{"id":"local","label":"Repeated bow, drill, and tinder trials","requires_all":[]}],
		"production_contract":"Ignition requires suitable dry wood and tinder at the place of use. Wet material, poor preparation, or insufficient effort can defeat the attempt."
	},
	{
		"id":"percussion_fire_ignition", "name":"Percussion Fire Ignition", "direction":"Sustenance", "day":0, "chance":0.003,
		"requires":["ember_tending","stone_sorting"], "requires_all":["ember_tending","stone_sorting"], "requires_any":[], "signals":["fire","stone","crafting"],
		"observation":"Strike compatible materials to produce hot particles that ignite receptive tinder.",
		"causal_mechanism":"Compatible stone or qualified metal pairs shed hot particles when struck sharply against one another.",
		"operating_capability":"Use a material-dependent alternative to friction ignition when a qualified striker and prepared tinder are present.",
		"effects":{}, "learning_routes":[{"id":"local","label":"Spark-stone and tinder trials","requires_all":[]}],
		"production_contract":"Knowing the method does not provide a striker or tinder. Local trials must identify a compatible pair, and each operating attempt uses physically available material."
	},
	{
		"id":"hearth_heat_retention", "name":"Hearth Heat Retention", "direction":"Sustenance", "day":0, "chance":0.004,
		"requires":[], "requires_all":[], "requires_any":[["ember_tending","friction_fire_ignition","percussion_fire_ignition"]], "signals":["fire","stone","crafting"],
		"observation":"Arrange a contained hearth and refractory surrounding mass to reduce unwanted heat loss.",
		"causal_mechanism":"A contained hearth and suitable surrounding mass retain and direct more of a fire's heat.",
		"operating_capability":"Apply controlled local heat for cooking and material work while fuel, airflow, safe hearth material, and smoke escape remain available.",
		"effects":{}, "learning_routes":[{"id":"local","label":"Contained-hearth comparisons","requires_all":[]}],
		"production_contract":"A hearth changes heat transfer but does not create heat. Operations still consume fuel and must have a safe site, adequate air, and smoke escape."
	},
	{
		"id":"fuel_air_drying", "name":"Fuel Air Drying", "direction":"Materials", "day":0, "chance":0.005,
		"requires":["ember_tending"], "requires_all":["ember_tending"], "requires_any":[], "signals":["timber","storage","crafting"],
		"observation":"Expose split or loose fuel to moving air while excluding rain and ground moisture.",
		"causal_mechanism":"Air circulation and protection from new moisture reduce the water carried into a fire with harvested fuel.",
		"operating_capability":"Prepare more reliable fuel when harvested stock, sheltered space, handling, drying time, and suitable weather are available.",
		"effects":{}, "learning_routes":[{"id":"local","label":"Sheltered fuel-stack comparisons","requires_all":[]}],
		"production_contract":"The method neither creates fuel nor dries it instantly. Weather, stock thickness, shelter, handling, and elapsed drying time limit usable output."
	}
]
