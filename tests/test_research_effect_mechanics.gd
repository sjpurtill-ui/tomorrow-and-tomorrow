extends GdUnitTestSuite
## The eight research effects that act through research_mechanics.gd: raised,
## each moves its quantity the right way, stays inside its bounds, and every
## people reads its own totals through the same code (WorldSimulation scopes).

const Mechanics:=preload("res://scripts/research_mechanics.gd")
const Fire:=preload("res://scripts/fire_practice.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Ops:=preload("res://scripts/technology_operations.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const Upkeep:=preload("res://scripts/upkeep_warnings.gd")
const Explainer:=preload("res://scripts/effect_explainer.gd")
const KEYS:=["water_access","fuel_efficiency","fuel_demand","repair_capacity","chemical_control","mining_output","logistics_endurance","naval_capacity"]

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	_fresh(424242)

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _fresh(seed:int)->void:
	GameState.reset_for_new_world(seed)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	ResourceSystem.reset_for_new_world();ResourceSystem.initialize()
	GameState.resource_deposits=[]
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.resource_settlement_id=""
	GameState.elapsed_days=400

## Sets one research total directly on the society ledger the engine reads.
func _total(key:String,value:float)->void:
	DiscoverySystem.society_model.effect_totals[key]=value

func _know(id:String,adoption:float=1.0)->void:
	if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=adoption

# --- water access --------------------------------------------------------------

func test_water_access_shortens_the_walk_and_brings_in_more_water()->void:
	assert_float(Mechanics.water_walk_factor_of(0.0)).is_equal(1.0)
	assert_float(Mechanics.water_walk_factor_of(0.4)).is_equal_approx(0.7,0.000001)
	assert_float(Mechanics.water_walk_factor_of(0.1)).is_less(Mechanics.water_walk_factor_of(0.05))
	# Bounded: never under 40 in 100 of the walk, never over one and a quarter.
	assert_float(Mechanics.water_walk_factor_of(9.0)).is_equal_approx(0.40,0.000001)
	assert_float(Mechanics.water_walk_factor_of(-9.0)).is_equal_approx(1.2625,0.000001)
	# A river 3 km off (ResourceSystem._process_water_flow): households fetch
	# more themselves and carriers bring in more; the ground does not move.
	GameState.ensure_population_total(160)
	GameState.population_allocations["Logistics"]=6;GameState.population_allocations["Food"]=20
	var context:={"origin":Vector3.ZERO,"surface_water_distance_km":3.0,"surface_water_recognized":true}
	var seen:Array[Dictionary]=[]
	for access:float in [0.0,0.4]:
		GameState.resource_stockpiles["Freshwater"]=0.0
		_total("water_access",access)
		ResourceSystem._process_water_flow(context)
		seen.append(GameState.water_metrics.duplicate())
	assert_float(float(seen[1].household_collected_today)).is_greater(float(seen[0].household_collected_today))
	assert_float(float(seen[1].organized_collection_capacity)).is_greater(float(seen[0].organized_collection_capacity))
	assert_float(float(seen[1].source_distance_km)).is_equal_approx(3.0,0.000001)
	# The river 3 km off counts as 2.1 km: the household share follows that walk.
	var walked:float=ResourceSystem._household_surface_water_access_ratio(2.1)
	var full:float=ResourceSystem._household_surface_water_access_ratio(3.0)
	assert_float(float(seen[1].household_collected_today)/float(seen[0].household_collected_today)).is_equal_approx(walked/full,0.0001)

# --- fuel economy and fuel needed ------------------------------------------------

func test_fuel_economy_and_fuel_needed_scale_every_fire()->void:
	assert_float(Mechanics.fuel_factor_of(0.0,0.0)).is_equal(1.0)
	assert_float(Mechanics.fuel_factor_of(0.5,0.0)).is_equal_approx(0.7,0.000001)
	assert_float(Mechanics.fuel_factor_of(0.0,0.3)).is_equal_approx(1.3,0.000001)
	assert_float(Mechanics.fuel_factor_of(0.2,0.0)).is_less(Mechanics.fuel_factor_of(0.1,0.0))
	assert_float(Mechanics.fuel_factor_of(0.0,0.2)).is_greater(Mechanics.fuel_factor_of(0.0,0.1))
	# Late: the whole catalogue's economy outweighs what its ways need.
	assert_float(Mechanics.fuel_factor_of(0.80,0.48)).is_between(0.70,0.80)
	# Bounded at the extremes.
	assert_float(Mechanics.fuel_factor_of(99.0,-99.0)).is_greater_equal(0.30)
	assert_float(Mechanics.fuel_factor_of(-99.0,99.0)).is_less_equal(2.20)
	# The kept hearth (fire_practice.gd) burns its daily fuel through the factor.
	_know("ember_tending")
	for pair:Array in [[0.0,0.0],[0.5,0.0],[0.0,0.3]]:
		GameState.fire_practice={"initialized":true,"embers":.8,"last_day":-1,"source":"test","last_event":"","fuel_today":0.0,"ignitions":0,"extinctions":0}
		GameState.resource_stockpiles["Timber"]=1.0
		_total("fuel_efficiency",float(pair[0]));_total("fuel_demand",float(pair[1]))
		var report:=Fire.advance(10,true)
		var expected:=Fire.MAINTENANCE_TIMBER*Mechanics.fuel_factor_of(float(pair[0]),float(pair[1]))
		assert_float(float(report.maintenance_timber)).is_equal_approx(expected,0.0000001)
		assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(1.0-expected,0.0000001)
	# Installed plants burn their listed fuel through the same factor; wood that
	# only comes from parts flattened into raw stuff is not fuel.
	_total("fuel_efficiency",0.5);_total("fuel_demand",0.0)
	assert_float(Ops.input_rate(Ops.PLANTS.controlled_kiln,"Timber")).is_equal_approx(0.5*0.7,0.000001)
	assert_float(Ops.input_rate(Ops.PLANTS.steam_generator,"Coal")).is_equal_approx(0.5*0.7,0.000001)
	assert_float(Ops.input_rate(Ops.PLANTS.steam_generator,"Freshwater")).is_equal_approx(1.0,0.000001)
	for id:String in Ops.PLANTS:
		var spec:Dictionary=Ops.PLANTS[id]
		for item:String in spec.inputs:
			var listed:=float(((Ops.PLANTS_SOURCE[id] as Dictionary).get("inputs",{}) as Dictionary).get(item,0.0)) if item in Mechanics.FUEL_ITEMS else 0.0
			assert_float(Ops.input_rate(spec,item)).override_failure_message("%s %s" % [id,item]).is_equal_approx(float(spec.inputs[item])-listed*0.3,0.000001)

func test_smoking_fires_burn_fuel_through_the_same_factor()->void:
	FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(100)
	_know("smoking");_know("ember_tending")
	GameState.fire_practice={"initialized":true,"embers":.8,"last_day":-1,"source":"test","last_event":"","fuel_today":0.0,"ignitions":0,"extinctions":0}
	GameState.resource_stockpiles[Goods.GOODS]=1000.0
	var burned:Array[float]=[]
	for economy:float in [0.0,0.5]:
		GameState.food_stocks={FoodSystem.FRESH:500.0,FoodSystem.STORED:0.0}
		GameState.resource_stockpiles["Timber"]=100.0
		_total("fuel_efficiency",economy);_total("fuel_demand",0.0)
		var inputs:Dictionary={}
		var preserved:Dictionary=FoodSystem._preserve(20.0,20.0,false,inputs)
		assert_float(float(preserved.smoked)).is_greater(0.0)
		burned.append(float(inputs.get("Timber",0.0))/float(preserved.smoked))
	assert_float(burned[0]).is_equal_approx(FoodSystem.SMOKING_FUEL,0.0000001)
	assert_float(burned[1]).is_equal_approx(FoodSystem.SMOKING_FUEL*0.7,0.0000001)

# --- repair skill ------------------------------------------------------------------

func test_repair_skill_slows_goods_wear_and_stretches_the_mending()->void:
	assert_float(Mechanics.goods_wear_factor_of(0.5)).is_equal_approx(0.75,0.000001)
	assert_float(Mechanics.mending_factor_of(0.5)).is_equal_approx(1.5,0.000001)
	assert_float(Mechanics.goods_wear_factor_of(9.0)).is_equal_approx(0.625,0.000001)
	assert_float(Mechanics.goods_wear_factor_of(-9.0)).is_equal_approx(1.15,0.000001)
	assert_float(Mechanics.mending_factor_of(9.0)).is_equal_approx(1.75,0.000001)
	assert_float(Mechanics.mending_factor_of(-9.0)).is_equal_approx(0.70,0.000001)
	# Household goods (civilian_goods.gd): one day's wear, no making.
	GameState.settlement_site_committed=false
	GameState.civilian_goods=Goods.empty_state()
	GameState.resource_stockpiles={Goods.GOODS:100.0}
	GameState.civilian_goods.last_day=int(GameState.elapsed_days)-1
	_total("repair_capacity",0.5)
	assert_float(Goods.daily_wear()).is_equal_approx(Goods.DAILY_WEAR*0.75,0.0000001)
	Goods.advance()
	assert_float(Goods.stock()).is_equal_approx(100.0*(1.0-Goods.DAILY_WEAR*0.75),0.00001)
	# The town's monthly mending (SettlementModel._advance_city_form) and the
	# upkeep official's numbers (upkeep_warnings.gd facts) use one factor.
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.reset_for_new_world();SettlementModel.ensure_founded()
	GameState.ensure_population_total(1000)
	GameState.population_allocations["Construction"]=100
	var mended:Array[float]=[]
	var change:Array[float]=[]
	for repair:float in [0.0,0.5]:
		GameState.resource_stockpiles={"Timber":1000.0,"Fiber Plants":1000.0,"Clay":1000.0,"Stone":1000.0}
		GameState.city_form={"tier":0.0,"condition":.5}
		_total("repair_capacity",repair)
		SettlementModel._advance_city_form(int(GameState.elapsed_days))
		mended.append(float(GameState.city_form.condition))
		change.append(float(Upkeep.facts().monthly_change))
	assert_float(mended[1]).is_greater(mended[0])
	# The mending (condition gained against the month's wear of 0.02) goes half as far again.
	assert_float((mended[1]-0.5+0.02)/(mended[0]-0.5+0.02)).is_equal_approx(1.5,0.0001)
	assert_float(change[1]).is_greater(change[0])

# --- control of chemicals ------------------------------------------------------------

func _consequence_day(control:float,pollution:float=0.10,fouled:float=0.05)->Dictionary:
	_fresh(5151)
	FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(157)
	GameState.settlement_completed=["Hearth Circle"];GameState.housing_capacity=200
	GameState.food_stocks={FoodSystem.FRESH:400.0,FoodSystem.STORED:30000.0}
	GameState.water_metrics["intake_ratio"]=1.0;GameState.water_metrics["source_accessible"]=true
	ConsequenceEngine.initialize()
	# Heavy mining and quarrying with smoky, fouling ways, and no other hazard.
	GameState.material_metrics={"extracted_today":1000.0}
	for key:String in ["health_risk","pollution","water_pollution","chemical_control"]:_total(key,0.0)
	_total("pollution",pollution);_total("water_pollution",fouled);_total("chemical_control",control)
	var health:=GameState.population_health
	var ecology:=float(GameState.simulation_metrics.get("ecology",0.88))
	ConsequenceEngine.process_day({"traveling":false})
	return {"health":GameState.population_health-health,"ecology":float(GameState.simulation_metrics.get("ecology",0.88))-ecology}

func test_control_of_chemicals_prevents_part_of_the_harm_of_smoke_and_fouled_water()->void:
	assert_float(Mechanics.chemical_harm_cut_of(0.0)).is_equal(0.0)
	assert_float(Mechanics.chemical_harm_cut_of(0.2)).is_equal_approx(0.3,0.000001)
	assert_float(Mechanics.chemical_harm_cut_of(9.0)).is_equal_approx(0.60,0.000001)
	assert_float(Mechanics.chemical_harm_cut_of(-9.0)).is_equal(0.0)
	var bare:=_consequence_day(0.0)
	var controlled:=_consequence_day(0.4)
	assert_float(float(controlled.health)).is_greater(float(bare.health))
	assert_float(float(controlled.ecology)).is_greater(float(bare.ecology))
	# Nothing to cut when the people's ways foul nothing: control changes nothing.
	var clean:=_consequence_day(0.0,-0.05,0.0)
	var clean_controlled:=_consequence_day(0.4,-0.05,0.0)
	assert_float(float(clean_controlled.health)).is_equal_approx(float(clean.health),0.0000001)
	assert_float(float(clean_controlled.ecology)).is_equal_approx(float(clean.ecology),0.0000001)

# --- mine output ------------------------------------------------------------------------

func _yields(output:float)->Dictionary:
	_fresh(864209)
	GameState.resource_stockpiles={"Timber":0.0,"Stone":0.0,"Copper Ore":0.0}
	GameState.founding_manifest={}
	GameState.population_allocations.Extraction=10
	GameState.population_allocations.Logistics=10
	var copper:=ResourceSystem._deposit("Copper Ore",Vector3.ZERO,.7,1000.0,0)
	var stone:=ResourceSystem._deposit("Stone",Vector3.ZERO,.7,1000.0,1)
	for deposit:Dictionary in [copper,stone]:
		deposit.stage="accessible";deposit.access=1.0;deposit.route=1.0
	GameState.resource_deposits=[copper,stone]
	for key:String in ["extraction_yield","metal_yield","copper_ore_yield","stone_yield"]:_total(key,0.0)
	_total("mining_output",output)
	ResourceSystem._process_material_flow({"settled":false,"origin":Vector3.ZERO,"tools":1.0})
	return {"copper":float(copper.daily_yield),"stone":float(stone.daily_yield)}

func test_mine_output_raises_only_mined_deposits()->void:
	for resource:String in ["Copper Ore","Iron Ore","Coal","Sulfur","Graphite","Phosphate Rock","Crude Oil"]:
		assert_bool(Mechanics.is_mined(ResourceSystem.catalog[resource],ResourceSystem.material_profile(resource))).override_failure_message(resource).is_true()
	for resource:String in ["Stone","Clay","Fine Sand","Salt","Peat","Timber","Fiber Plants","Limestone","Flint"]:
		assert_bool(Mechanics.is_mined(ResourceSystem.catalog[resource],ResourceSystem.material_profile(resource))).override_failure_message(resource).is_false()
	assert_float(Mechanics.mining_bonus_of(9.0)).is_equal_approx(0.80,0.000001)
	assert_float(Mechanics.mining_bonus_of(-9.0)).is_equal_approx(-0.35,0.000001)
	var bare:=_yields(0.0)
	var worked:=_yields(0.3)
	assert_float(float(bare.copper)).is_greater(0.0)
	assert_float(float(worked.copper)/float(bare.copper)).is_equal_approx(1.3,0.0001)
	assert_float(float(worked.stone)).is_equal_approx(float(bare.stone),0.0000001)

# --- supply endurance ----------------------------------------------------------------

func test_supply_endurance_carries_food_farther_and_holds_off_hunger()->void:
	assert_float(Mechanics.haul_loss_factor_of(0.4)).is_equal_approx(0.8,0.000001)
	assert_float(Mechanics.hunger_pace_of(0.4)).is_equal_approx(0.8,0.000001)
	assert_float(Mechanics.haul_loss_factor_of(9.0)).is_equal_approx(0.65,0.000001)
	assert_float(Mechanics.haul_loss_factor_of(-9.0)).is_equal_approx(1.175,0.000001)
	# The haul (supply_state.gd): porters lose 8 in 100 a day after a day and a half.
	assert_float(Supply.haul_share(10.0,"foot",0.0)).is_equal_approx(1.0-0.08*8.5,0.000001)
	assert_float(Supply.haul_share(10.0,"foot",0.4)).is_equal_approx(1.0-0.08*0.8*8.5,0.000001)
	assert_float(Supply.reach_effort("foot",0.5,0.4)).is_greater(Supply.reach_effort("foot",0.5,0.0))
	# The engine and the screens read the people's own endurance.
	_total("logistics_endurance",0.4)
	assert_float(Supply.endurance_today()).is_equal_approx(0.4,0.000001)
	assert_float(float(Supply.day_inputs().endurance)).is_equal_approx(0.4,0.000001)
	# The hunger clock (field_rations.gd): short days count slower, fed days as before.
	var band:={"hungry_days":0.0,"troops":20}
	Rations.mark_day(band,0.5,1.0)
	assert_float(float(band.hungry_days)).is_equal_approx(0.8,0.000001)
	Rations.mark_day(band,1.0,1.0)
	assert_float(float(band.hungry_days)).is_equal(0.0)
	_total("logistics_endurance",0.0)
	Rations.mark_day(band,0.5,1.0)
	assert_float(float(band.hungry_days)).is_equal_approx(1.0,0.000001)

# --- seafaring strength ----------------------------------------------------------------

func test_seafaring_widens_sea_fishing_and_open_water_crossings()->void:
	assert_float(Mechanics.sea_reach_of(0.5)).is_equal_approx(1.5,0.000001)
	assert_float(Mechanics.sea_reach_of(9.0)).is_equal_approx(1.9,0.000001)
	assert_float(Mechanics.sea_reach_of(-9.0)).is_equal_approx(0.7,0.000001)
	assert_float(Mechanics.fishing_ground_of(0.5,1.0,1.5)).is_equal_approx(115.0,0.000001)
	assert_float(Mechanics.fishing_access_of(0.2,0.8,1.5)).is_equal(1.0)
	assert_float(Mechanics.fishing_access_of(0.9,0.5,1.0)).is_equal_approx(0.9,0.000001)
	# A sea coast home (FoodSystem.wild_food_capacity): the grounds hold more.
	FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(120)
	GameState.player_settlements=[{"id":"home","primary":true,"territory_context":{"shoreline_access":1.0,"marine_opportunity":0.8}}]
	var grounds:Array[float]=[]
	for naval:float in [0.0,0.5]:
		_total("naval_capacity",naval)
		grounds.append(float(FoodSystem.wild_food_capacity().Fishing.rations))
	var reach:=sqrt(maxf(1.0,GameState.population_exact)/120.0)
	assert_float(grounds[1]-grounds[0]).is_equal_approx(40.0*0.5*reach,0.0001)
	# An inland home gains nothing from boats.
	GameState.player_settlements=[{"id":"home","primary":true,"territory_context":{}}]
	var inland:Array[float]=[]
	for naval:float in [0.0,0.5]:
		_total("naval_capacity",naval)
		inland.append(float(FoodSystem.wild_food_capacity().Fishing.rations))
	assert_float(inland[1]).is_equal_approx(inland[0],0.0000001)
	# Scouts' craft cross wider open water (civilization_system.gd); none without craft.
	_total("naval_capacity",0.5)
	assert_float(CivilizationSystem._scout_water_crossing_allowance_km()).is_equal(0.0)
	_know("coastal_watercraft",0.5)
	_total("naval_capacity",0.0)
	assert_float(CivilizationSystem._scout_water_crossing_allowance_km()).is_equal(40.0)
	_total("naval_capacity",0.5)
	assert_float(CivilizationSystem._scout_water_crossing_allowance_km()).is_equal(60.0)

# --- every people, and the explainer ------------------------------------------------------

func test_a_computer_run_people_reads_its_own_totals()->void:
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	var values:={"water_access":0.4,"fuel_efficiency":0.5,"fuel_demand":0.2,"repair_capacity":0.3,"chemical_control":0.2,"mining_output":0.1,"logistics_endurance":0.4,"naval_capacity":0.6}
	for key:String in KEYS:_total(key,0.0)
	var theirs:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:
		WorldSimulation.discovery.effect("water_access")
		for key:String in values:WorldSimulation.discovery.society_model.effect_totals[key]=float(values[key])
		return {"walk":Mechanics.water_walk_factor(),"fuel":Mechanics.fuel_factor(),"wear":Mechanics.goods_wear_factor(),"mending":Mechanics.mending_factor(),
			"chemical":Mechanics.chemical_harm_cut(),"mining":Mechanics.mining_bonus(),"endurance":Mechanics.supply_endurance(),"sea":Mechanics.sea_reach()})
	assert_float(float(theirs.walk)).is_equal_approx(0.7,0.000001)
	assert_float(float(theirs.fuel)).is_equal_approx(0.7*1.2,0.000001)
	assert_float(float(theirs.wear)).is_equal_approx(0.85,0.000001)
	assert_float(float(theirs.mending)).is_equal_approx(1.3,0.000001)
	assert_float(float(theirs.chemical)).is_equal_approx(0.3,0.000001)
	assert_float(float(theirs.mining)).is_equal_approx(0.1,0.000001)
	assert_float(float(theirs.endurance)).is_equal_approx(0.4,0.000001)
	assert_float(float(theirs.sea)).is_equal_approx(1.6,0.000001)
	# The player's own totals are untouched by the other people's.
	assert_float(Mechanics.fuel_factor()).is_equal(1.0)
	assert_float(Mechanics.sea_reach()).is_equal(1.0)

func test_explainer_says_what_each_one_does_in_plain_words()->void:
	var snake:=RegEx.create_from_string("[a-z0-9]+_[a-z0-9]+")
	for key:String in KEYS:
		assert_bool(Explainer.is_inert(key)).override_failure_message(key).is_false()
		var said:=Explainer.describe(key,0.02,1.0)
		assert_array(said.feeds).override_failure_message(key).is_not_empty()
		for line:Variant in [said.sentence,said.now_words]+(said.feeds as Array):
			assert_bool(String(line).contains("_") or snake.search(String(line))!=null).override_failure_message("%s: %s" % [key,line]).is_false()
			assert_bool(String(line).contains("Nothing in the simulation reads")).override_failure_message(key).is_false()
	# Exact first lines at a quiet start (no other totals in play).
	for key:String in KEYS:_total(key,0.0)
	Explainer.invalidate()
	assert_str(String(Explainer.describe("water_access",0.04).feeds[0])).starts_with("The walk to the water source: down about 3%")
	assert_str(String(Explainer.describe("fuel_efficiency",0.05).feeds[0])).starts_with("Fuel burned by every fire the people keep").contains("down about 3%")
	assert_str(String(Explainer.describe("fuel_demand",0.05).feeds[0])).contains("up about 5%")
	assert_str(String(Explainer.describe("repair_capacity",0.04).feeds[0])).starts_with("Household goods worn out each day: down about 2%")
	assert_str(String(Explainer.describe("chemical_control",0.04).feeds[0])).contains("up about 6 points of 100")
	assert_str(String(Explainer.describe("mining_output",0.03).feeds[0])).starts_with("Daily yield of every mined deposit: up about 3%")
	assert_str(String(Explainer.describe("logistics_endurance",0.04).feeds[0])).contains("down about 2%")
	assert_str(String(Explainer.describe("naval_capacity",0.05).feeds[0])).contains("up about 5%")
