extends RefCounted
## WHAT A PEOPLE'S CHOSEN COURSE DOES (the user, 2026-10-05: "make each one
## actually matter"). Every century a people chooses a course
## (PeopleDirection.AMBITIONS); besides its research lean and the value it
## draws its people toward, each course now works on the people's life
## through the engine's own levers (GameState.founding_effect, read by the
## food, health, cohesion, knowledge, building, survey, trade, drill and
## command systems), and a few through levers of their own (how far scouts
## know the land, how wide our country reaches). Each gives a felt gain and
## pays a real cost, about the size of the old founding presets, so an
## all-in course goes "a little extra" beyond a balanced people.
##
## A course's strength is its share of the people's cultural memory
## (cultural_inheritance choice_weights): the course of this century counts
## most and earlier ones fade with a sixty-year half-life, as the research
## lean already did. The same rule for every people: rival peoples' courses
## work on them in their own scope. Static; preload.

const Culture:=preload("res://scripts/cultural_inheritance.gd")

## Course -> {lever: amount at full strength}. Levers are founding_effect
## ids (fractions of their own targets), plus "scout_reach" (how much
## faster our known country grows) and "realm_reach" (how much wider our
## country reaches, realm_reach.gd).
const EFFECTS:={
	"horizons":{"survey_output":0.20,"scout_reach":0.35,"realm_reach":0.10,"adoption_rate":0.06,"food_yield":-0.03},
	"makers":{"construction_output":0.15,"resource_output":0.10,"material_target":0.05,"ecology_delta":-0.00005,"health_target":-0.01},
	"gathering":{"cohesion_target":0.05,"adoption_rate":0.10,"conception_support":0.05,"security_target":-0.03},
	"inquiry":{"knowledge_gain":0.15,"adoption_rate":0.06,"survey_output":0.05,"training_rate":-0.06,"food_yield":-0.02},
	"military":{"training_rate":0.20,"training_capacity":0.15,"command_development":0.15,"security_target":0.08,"food_yield":-0.03,"knowledge_gain":-0.05},
	"sustenance":{"food_yield":0.12,"health_target":0.015,"ecology_delta":0.00006,"knowledge_gain":-0.05,"construction_output":-0.04},
	"wellbeing":{"health_target":0.04,"conception_support":0.15,"cohesion_target":0.02,"labor_multiplier":-0.03},
	"commerce":{"trade_access":0.15,"logistics_target":0.08,"resource_output":0.05,"security_target":-0.03,"cohesion_target":-0.01},
	"expansion":{"realm_reach":0.30,"scout_reach":0.25,"survey_output":0.10,"logistics_target":0.05,"cohesion_target":-0.02},
	"dominion":{"command_development":0.12,"security_target":0.08,"labor_multiplier":0.03,"cohesion_target":-0.04,"adoption_rate":-0.04},
	"purity":{"cohesion_target":0.06,"security_target":0.05,"adoption_rate":-0.10,"trade_access":-0.10},
	"dynasty":{"cohesion_target":0.04,"construction_output":0.08,"adoption_rate":-0.06,"knowledge_gain":-0.03},
	"retribution":{"security_target":0.08,"training_rate":0.10,"cohesion_target":-0.02,"trade_access":-0.05},
	"orthodoxy":{"cohesion_target":0.07,"security_target":0.03,"knowledge_gain":-0.08,"adoption_rate":-0.06},
}

## What each lever is, in plain words for the course's card.
const WORDS:={"survey_output":"surveying","scout_reach":"how fast our scouts' known country grows","realm_reach":"how far our land reaches",
	"adoption_rate":"how fast new ways spread","food_yield":"food from every field and hunt","construction_output":"building",
	"resource_output":"stone, ore and timber won","material_target":"the quality of what we make","ecology_delta":"the health of the land",
	"health_target":"health","cohesion_target":"how close our people hold","conception_support":"births","security_target":"safety at home",
	"knowledge_gain":"learning","training_rate":"drill","training_capacity":"how many can drill at once","command_development":"our leaders' command",
	"labor_multiplier":"work done","trade_access":"trade","logistics_target":"carrying and roads"}


## Each course's share of the people's cultural memory now (0..1, adding
## to 1 over the courses chosen; {} before any).
static func shares(direction:Variant=null,day:int=-1)->Dictionary:
	if direction==null: direction=WorldSimulation.direction if Engine.get_main_loop()!=null else null
	if direction==null: return {}
	if direction.has_method("_ensure_cultural_memory"): direction._ensure_cultural_memory()
	if day<0: day=int(WorldSimulation.state.elapsed_days)
	var weights:Dictionary=Culture.choice_weights(direction.cultural_memory,day)
	var total:=0.0
	for value in weights.values(): total+=float(value)
	var out:={}
	if total<=0.0: return out
	for choice in weights: out[String(choice)]=float(weights[choice])/total
	return out


## The shares for the people in scope today, kept for the day (the levers
## are read many times a day).
static var _cache_key:=[]
static var _cache:Dictionary={}
static func shares_today()->Dictionary:
	if Engine.get_main_loop()==null or WorldSimulation.direction==null: return {}
	var key:=[WorldSimulation.direction.get_instance_id(),int(WorldSimulation.state.elapsed_days),int((WorldSimulation.direction.cultural_memory.get("events",[]) as Array).size()) if WorldSimulation.direction.cultural_memory is Dictionary else 0]
	if key!=_cache_key:
		_cache_key=key
		_cache=shares()
	return _cache


## A lever's amount for the people now: each course's amount by its share.
static func effect(lever:String,given_shares:Variant=null)->float:
	var s:Dictionary=given_shares if given_shares is Dictionary else shares_today()
	var out:=0.0
	for choice in s:
		out+=float(s[choice])*float((EFFECTS.get(choice,{}) as Dictionary).get(lever,0.0))
	return out


## A course's card in plain words: "Building +15% · stone, ore and timber
## won +10% · … Costs: the health of the land, health −1%."
static func describe(id:String)->String:
	var table:Dictionary=EFFECTS.get(id,{})
	var gains:=PackedStringArray(); var costs:=PackedStringArray()
	for lever in table:
		var amount:=float(table[lever])
		var words:=String(WORDS.get(lever,lever))
		var text:=words.substr(0,1).to_upper()+words.substr(1)
		if lever=="ecology_delta": text+=" better" if amount>0.0 else " worse"
		else: text+=" %s%d%%" % ["+" if amount>0.0 else "−",roundi(absf(amount)*100.0)]
		if amount>0.0: gains.append(text)
		else: costs.append(text)
	var out:=" · ".join(gains)+"."
	if not costs.is_empty(): out+=" Costs: "+" · ".join(costs).to_lower()+"."
	return out
