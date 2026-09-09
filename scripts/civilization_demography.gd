extends RefCounted
## Each civilization owns its state; the existing player rules own the math.
## This adapter never swaps the live GameState or depends on city selection.
const FIELDS:=["population_exact","population_total","population_cohorts","pregnancy_cohorts","demographic_remainders","mortality_by_age_cohort","observed_death_age_sum","death_progress","lifetime_births","lifetime_deaths","lifetime_conceptions","lifetime_pregnancy_losses","lifetime_stillbirths","lifetime_maternal_deaths","lifetime_neonatal_deaths"]

static func capture(model:Node)->Dictionary:
	var result:Dictionary={}
	for field:String in FIELDS:
		var value:Variant=model.get(field)
		result[field]=value.duplicate(true) if value is Dictionary else value
	return result

static func initial(population:float=GameState.FOUNDING_POPULATION)->Dictionary:
	var model:Node=GameState.get_script().new()
	model.population_exact=population;model.initialize_population_model()
	var result:=capture(model);model.free();return result

static func advance(state:Dictionary,context:Dictionary,rates:Dictionary,first_day:int,days:int=1)->Dictionary:
	var model:Node=GameState.get_script().new()
	for field:String in FIELDS:
		if state.has(field):
			var value:Variant=state[field]
			model.set(field,value.duplicate(true) if value is Dictionary else value)
	model.population_health=float(context.get("health",.72));model.food_security=float(context.get("food_security",.82))
	var births_before:=int(model.lifetime_births);var deaths_before:=int(model.lifetime_deaths)
	var result:Dictionary={}
	for offset in maxi(0,days):
		model.elapsed_days=float(first_day+offset)
		var daily_rates:=rates.duplicate(true)
		daily_rates["Natural causes"]=model.current_natural_mortality_rate(float(context.get("housing_ratio",.5)))
		result=model.process_demographic_day(context,daily_rates)
	result["births"]=int(model.lifetime_births)-births_before;result["deaths"]=int(model.lifetime_deaths)-deaths_before
	result["state"]=capture(model);model.free();return result

static func valid(state:Variant)->bool:
	if not state is Dictionary or state.size()!=FIELDS.size():return false
	for key:String in FIELDS:
		if not state.has(key):return false
		var value:Variant=state[key]
		var expects_dictionary:=key in ["population_cohorts","pregnancy_cohorts","demographic_remainders","mortality_by_age_cohort"]
		if expects_dictionary!=(value is Dictionary):return false
		if value is Dictionary:
			if value.size()>12:return false
			for amount in value.values():
				if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount)<0:return false
		elif not (value is int or value is float) or not is_finite(float(value)) or float(value)<0:return false
	var total:=0.0
	for age:String in ["children","youth","early_adults","established_adults","mature_adults","elders"]:
		if not state.population_cohorts.has(age):return false
		total+=float(state.population_cohorts[age])
	for phase:String in ["first_trimester","second_trimester","third_trimester","postpartum"]:
		if not state.pregnancy_cohorts.has(phase):return false
	return float(state.population_exact)>=1 and int(state.population_total)==roundi(state.population_exact) and is_equal_approx(total,float(state.population_exact))
