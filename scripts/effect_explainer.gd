extends RefCounted
## EFFECT EXPLAINER: what each research effect does in the simulation, in plain
## words and in the engine's own numbers.
##
## A discovery's "effects" are small signed amounts ({"health_protection":0.012}).
## SocietyModel sums them over everything the people know, each counted by how
## widely it is practiced (adoption, times the goods or works it needs, times
## the research focus on its line), holds each sum under its era ceiling, then
## adds the upkeep of too many full-time lore keepers (society_model.gd
## _rebuild_effect_totals). Systems read the sums with DiscoverySystem.effect.
##
## KEYS records, per effect, every place the simulation reads it: the quantity
## it moves, the coefficient ("per": change in that quantity per 1.0 of the
## effect), its caps, and the source line. Each record's "guards" are exact
## substrings of the reading code; tests/test_effect_explainer.gd fails when
## one no longer appears, so a changed coefficient cannot silently leave this
## table stale. Capacity coefficients are not written down at all: they are
## measured on the one capacity formula (SocietyModel.capacity_value) at
## today's inputs. "inert" keys are read by nothing; they are listed, not fixed.
## On screen everything is plain words; sources stay in the data for designers.

const Society:=preload("res://scripts/society_model.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Research600:=preload("res://scripts/research_600_catalog.gd")
const Mechanics:=preload("res://scripts/research_mechanics.gd")

## Size of the probe step when measuring a capacity's response to an effect.
const SLOPE_STEP:=0.001
## Share of households a known practice is counted at when it has no record
## of its own (SocietyModel's default). A newly proven practice starts in
## Research600.PROOF_ADOPTION of them (SocietyModel.register_discovery).
const FIRST_ADOPTION:=0.025

## The twelve capacities (Culture > Society's strengths): their names and what
## else reads them. Every capacity also counts toward the people's next scale in
## its field (ProgressionSystem CAPACITY_FLOORS).
const CAPACITY_USES:={
	"demography":"it counts toward the next scale of people and homes; nothing else reads it yet",
	"nutrition":"it counts toward the next scale of food and farming; nothing else reads it yet",
	"health":"it counts toward the next scale of health and care; nothing else reads it yet",
	"labor":"it sets how much every hand gets done each day",
	"knowledge":"it speeds every discovery and the growth of learning",
	"production":"it feeds trade and what the workshops make for the army",
	"infrastructure":"it feeds shelter in wartime and the next building scale",
	"logistics":"it feeds trade between towns, army supply and the economy",
	"ecology":"it counts toward the next scale of land and seasons; nothing else reads it yet",
	"institutions":"it feeds research support, trust in the chiefs, the economy and land claims",
	"security":"it feeds the army's training and the watch",
	"culture":"it feeds what treasured works add to culture",
}

## Fields of research in plain words (the Research page's names).
const FIELD_WORDS:={"demography":"people and homes","nutrition":"food","health":"health","labor":"work","knowledge":"learning","production":"craft","infrastructure":"building","logistics":"transport","ecology":"land","institutions":"government","security":"defense","culture":"culture"}

## Where fuel economy and the fuel needed act: one factor on the fuel of every
## fire the people keep (research_mechanics.gd fuel_factor_of), used by the kept
## hearth, the smoking fires and the fuel of installed kilns and engines.
const FUEL_GUARDS:=[["research_mechanics.gd","const FUEL_ECONOMY_SAVING:=0.6"],["research_mechanics.gd","const FUEL_DEMAND_COST:=1.0"],
	["research_mechanics.gd","var saving:=1.0-FUEL_ECONOMY_SAVING*clampf(economy,FUEL_ECONOMY_LIMITS.x,FUEL_ECONOMY_LIMITS.y)"],
	["research_mechanics.gd","var need:=1.0+FUEL_DEMAND_COST*clampf(demand,FUEL_DEMAND_LIMITS.x,FUEL_DEMAND_LIMITS.y)"],
	["research_mechanics.gd","return clampf(saving*need,FUEL_FACTOR_LIMITS.x,FUEL_FACTOR_LIMITS.y)"],
	["research_mechanics.gd",'return fuel_factor_of(WorldSimulation.discovery.effect("fuel_efficiency"),WorldSimulation.discovery.effect("fuel_demand"))'],
	["fire_practice.gd","var fuel:float=MAINTENANCE_TIMBER*maintenance_factor()"],["fire_practice.gd",'return preload("res://scripts/research_mechanics.gd").fuel_factor()'],
	["food_system.gd","var fuel_per_ration:float=SMOKING_FUEL*Mechanics.fuel_factor()"],
	["technology_operations.gd","return amount+burned*(Mechanics.fuel_factor()-1.0)"],["technology_operations.gd","var amount:=units*input_rate(spec,item)"]]

## Every effect key. label: as a player would say it. what: what it changes.
## good: 1 when more is better, -1 when less is better, 0 when mixed.
## feeds: where the engine reads it (see _feed_line for the kinds).
const KEYS:={
	# --- people and homes -------------------------------------------------------
	"conception_support":{"label":"Ease of conceiving","good":1,
		"what":"Customs and care that help couples conceive and carry a child. More children are conceived each day.",
		"feeds":[
			{"to":"children conceived each day","per":1.0,"unit":"pct","cap":"added to decrees, founding customs and the people's scale; together held between -30% and +30%","src":"game_state.gd:843, consequence_engine.gd:798","guards":[["game_state.gd",'factor*=1.0+clampf(float(context.get("conception_support",0.0)),-0.30,0.30)'],["consequence_engine.gd",'"conception_support":WorldSimulation.discovery.effect("conception_support")']]},
			{"steer":["demography","Fertility conditions"],"per":0.20,"src":"society_model.gd:719","guards":[["society_model.gd",'effect("conception_support")*0.20']]}]},
	"maternal_safety":{"label":"Safer childbirth","good":1,
		"what":"Birth attendants, clean hands and rest after a birth. Fewer pregnancies are lost and fewer mothers die in childbirth.",
		"feeds":[
			{"to":"pregnancies lost","per":-1.0,"unit":"pct","cap":"counts up to 60 in 100","src":"game_state.gd:852","guards":[["game_state.gd",'multiplier*=1.0-clampf(float(context.get("maternal_safety",0.0)),0.0,0.60)'],["consequence_engine.gd",'"maternal_safety":WorldSimulation.discovery.effect("maternal_safety")']]},
			{"to":"mothers who die in childbirth","per":-1.0,"unit":"pct","cap":"counts up to 65 in 100","src":"game_state.gd:1165","guards":[["game_state.gd",'(1.0-clampf(float(context.get("maternal_safety",0.0)),0.0,0.65))']]},
			{"cover":"birth","src":"early_life_conditions.gd:39"},
			{"capacity":"demography"},
			{"steer":["demography","Maternal safety"],"per":0.38,"src":"society_model.gd:719","guards":[["society_model.gd",'effect("maternal_safety")*0.38']]}]},
	"neonatal_survival":{"label":"Newborn survival","good":1,
		"what":"Keeping newborns warm, fed and clean. Fewer babies die in their first days, and the child care that keeps toddlers alive is better covered.",
		"feeds":[
			{"to":"newborns who die in their first days","per":-1.0,"unit":"pct","cap":"with care decrees, counts from -50 to +60 in 100","src":"game_state.gd:1163, consequence_engine.gd:799","guards":[["game_state.gd",'(1.0-clampf(float(context.get("neonatal_survival",0.0)),-0.50,0.60))'],["consequence_engine.gd",'"neonatal_survival":WorldSimulation.discovery.effect("neonatal_survival")']]},
			{"cover":"childcare","src":"early_life_conditions.gd:43"},
			{"steer":["demography","Child survival"],"per":0.20,"src":"society_model.gd:719","guards":[["society_model.gd",'effect("neonatal_survival")*0.20']]}]},
	"fertility_transition":{"label":"Choosing smaller families","good":0,
		"what":"Schooling, pensions, paid work for women and contraception. Couples choose to have fewer children, so births fall.",
		"feeds":[
			{"to":"conceptions couples choose not to have","per":1.0,"unit":"pts","cap":"with towns and schooling, at most 80 in 100","src":"early_life_conditions.gd:153","guards":[["early_life_conditions.gd",'discovery.effect("fertility_transition")+TRANSITION_URBAN']]}]},
	"modern_survival":{"label":"Modern medicine","good":1,
		"what":"Vaccines, clean piped water, antisepsis and clinics. The old burden of disease is lifted first; past 15 in 100 the risk of death itself falls at every age, children most.",
		"feeds":[
			{"to":"the old burden of disease lifted","per":1.0/0.22,"unit":"pts","cap":"fully lifted at 22 in 100","src":"early_life_conditions.gd:165","guards":[["early_life_conditions.gd",'discovery.effect("modern_survival")/MODERN_BURDEN_LIFT']]},
			{"text":"Past 15 in 100 it also lowers the risk of death at every age, up to 92 in 100 less at 55 in 100 (children gain most, the old least).","src":"early_life_conditions.gd:157","guards":[["early_life_conditions.gd",'clampf(discovery.effect("modern_survival"),0.0,MODERN_SURVIVAL_LIMIT)']]}]},
	# --- food -------------------------------------------------------------------
	"food_output":{"label":"Wild food yield","good":1,
		"what":"Better ways of finding, taking and handling food from the wild. Every gatherer, hunter and fisher brings in more; the harvest from sown fields does not change.",
		"feeds":[
			{"to":"food from gathering, hunting and fishing","per":1.0,"unit":"pct","cap":"added to foraging skill, founding customs, decrees and the people's scale","src":"food_system.gd:406","guards":[["food_system.gd",'practice+=WorldSimulation.discovery.effect("food_output")']]},
			{"to":"people the settled land can carry","per":0.5,"unit":"pct","cap":"only gains count","src":"early_life_conditions.gd:182","guards":[["early_life_conditions.gd",'maxf(0.0,discovery.effect("food_output"))*0.5']]}]},
	"foraging_yield":{"label":"Foraging skill","good":1,
		"what":"Knowing where and when wild plants, game and fish are found. The engine adds it to the same multiplier as wild food yield, so gathering, hunting and fishing all rise.",
		"feeds":[
			{"to":"food from gathering, hunting and fishing","per":1.0,"unit":"pct","cap":"added to wild food yield, founding customs, decrees and the people's scale","src":"food_system.gd:405","guards":[["food_system.gd",'practice+=WorldSimulation.discovery.effect("foraging_yield")']]}]},
	"hunting_yield":{"label":"Hunting yield","good":1,
		"what":"Better weapons, traps and tracking. Hunters bring home more meat.",
		"feeds":[
			{"to":"meat from hunting","per":1.0,"unit":"pct","src":"food_system.gd:416","guards":[["food_system.gd",'(1.0+WorldSimulation.discovery.effect("hunting_yield"))']]}]},
	"cultivation_yield":{"label":"Field harvest","good":1,
		"what":"Better seed, timing and tending of sown fields. Each farm worker harvests more, and the settled land can feed more people.",
		"feeds":[
			{"to":"harvest from sown fields","per":1.0,"unit":"pct","cap":"added to soil fertility","src":"food_system.gd:421","guards":[["food_system.gd",'(1.0+WorldSimulation.discovery.effect("soil_productivity")+WorldSimulation.discovery.effect("cultivation_yield"))']]},
			{"to":"people the settled land can carry","per":1.0,"unit":"pct","cap":"only gains count","src":"early_life_conditions.gd:182","guards":[["early_life_conditions.gd",'1.0+maxf(0.0,discovery.effect("cultivation_yield"))']]}]},
	"soil_productivity":{"label":"Soil fertility","good":1,
		"what":"Keeping fields fertile with fallow, manure and rotation. Sown fields give more, and the settled land can feed more people.",
		"feeds":[
			{"to":"harvest from sown fields","per":1.0,"unit":"pct","cap":"added to field harvest","src":"food_system.gd:421","guards":[["food_system.gd",'(1.0+WorldSimulation.discovery.effect("soil_productivity")+WorldSimulation.discovery.effect("cultivation_yield"))']]},
			{"to":"people the settled land can carry","per":0.6,"unit":"pct","cap":"only gains count","src":"early_life_conditions.gd:182","guards":[["early_life_conditions.gd",'maxf(0.0,discovery.effect("soil_productivity"))*0.6']]},
			{"steer":["nutrition","Land productivity"],"per":0.45,"src":"society_model.gd:720","guards":[["society_model.gd",'effect("soil_productivity")*0.45']]}]},
	"farm_mechanization":{"label":"Farm machinery","good":1,
		"what":"Machines, fertilizer and bred seed. Each farm worker's harvest multiplies.",
		"feeds":[
			{"to":"harvest from sown fields","per":1.0,"unit":"pct","cap":"only gains count","src":"food_system.gd:421","guards":[["food_system.gd",'(1.0+maxf(0.0,WorldSimulation.discovery.effect("farm_mechanization")))']]}]},
	"food_storage":{"label":"Food preserving","good":1,
		"what":"Drying, smoking, pits and jars that turn a fresh surplus into stores. More of each day's fresh surplus is put by, and lean seasons fall less hard on children.",
		"feeds":[
			{"to":"fresh food put into store each day","per":1.0,"unit":"pct","cap":"of what the carriers and makers can preserve","src":"food_system.gd:526","guards":[["food_system.gd",'(1.0+WorldSimulation.discovery.effect("food_storage"))']]},
			{"cover":"stores","src":"early_life_conditions.gd:51"},
			{"to":"people the settled land can carry","per":0.25,"unit":"pct","cap":"only gains count","src":"early_life_conditions.gd:182","guards":[["early_life_conditions.gd",'maxf(0.0,discovery.effect("food_storage"))*0.25']]},
			{"steer":["nutrition","Stored reserve"],"per":0.12,"src":"society_model.gd:712","guards":[["society_model.gd",'effect("food_storage")*0.12']]},
			{"steer":["logistics","Storage system"],"per":0.22,"src":"society_model.gd:726","guards":[["society_model.gd",'effect("food_storage")*0.22']]}]},
	"food_spoilage":{"label":"Food spoilage","good":-1,
		"what":"How fast food rots. Less is better: stores and fresh food last longer.",
		"feeds":[
			{"to":"food rotting each day","per":1.0,"unit":"pct","cap":"never below 30 in 100 of the usual rate","src":"food_system.gd:571","guards":[["food_system.gd",'storage_multiplier*=maxf(0.30,1.0+WorldSimulation.discovery.effect("food_spoilage"))']]}]},
	"nutrition_quality":{"label":"Diet quality","good":1,
		"what":"Cooking, grinding and knowing what to eat together. Meals nourish better, which lifts food security, health, births and children's survival.",
		"feeds":[
			{"to":"the quality of the people's diet","per":1.0,"unit":"pts","src":"food_system.gd:638","guards":[["food_system.gd",'var bonus:=WorldSimulation.discovery.effect("nutrition_quality")+technique_lever("diet")']]},
			{"cover":"cooking","src":"early_life_conditions.gd:47"},
			{"capacity":"nutrition"},
			{"steer":["nutrition","Diet quality"],"per":0.25,"src":"society_model.gd:711","guards":[["society_model.gd",'effect("nutrition_quality")*0.25']]}]},
	# --- health -----------------------------------------------------------------
	"health_protection":{"label":"Protection from sickness","good":1,
		"what":"Washing, remedies and care of the sick. The health the people settle toward rises, epidemics strike less hard, and more of the old burden of disease is lifted.",
		"feeds":[
			{"to":"the health the people settle toward","per":1.0,"unit":"pts","src":"consequence_engine.gd:684","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("health_protection")+WorldSimulation.discovery.effect("water_safety")*0.25']]},
			{"cover":"remedies","src":"early_life_conditions.gd:35"},
			{"relief":true,"src":"early_life_conditions.gd:80"},
			{"epidemic":1.0/3.0,"src":"crisis_system.gd:484","guards":[["crisis_system.gd",'var hp:=_effect("health_protection")'],["crisis_system.gd",'var hk:=clampf(0.05+(hp+san+ws)/3.0-0.5*de,0.0,1.0)']]},
			{"capacity":"health"},
			{"steer":["health","Disease control"],"per":0.45,"src":"society_model.gd:721","guards":[["society_model.gd",'effect("health_protection")*0.45']]}]},
	"water_safety":{"label":"Safe drinking water","good":1,
		"what":"Choosing, settling and guarding drinking water. Fewer fall sick from water, children's summer fevers ease, and outbreaks find less to feed on.",
		"feeds":[
			{"to":"the health the people settle toward","per":0.25,"unit":"pts","src":"consequence_engine.gd:684","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("water_safety")*0.25']]},
			{"cover":"water","src":"early_life_conditions.gd:27"},
			{"relief":true,"src":"early_life_conditions.gd:80"},
			{"epidemic":1.0/3.0,"src":"crisis_system.gd:484","guards":[["crisis_system.gd",'var ws:=_effect("water_safety")']]},
			{"to":"drinking water quality when sickness spreads (even with plenty to drink, cleaner water keeps cutting outbreaks, by up to a quarter)","per":0.2,"unit":"pts","src":"crisis_system.gd:512","guards":[["crisis_system.gd",'"water_q":clampf(water-0.15*de+0.2*ws+0.2*san,0.0,WATER_Q_MAX)'],["crisis_system.gd",'return WATER_SHORT_BETA*(1.0-minf(1.0,q))-CLEAN_WATER_BETA*maxf(0.0,q-1.0)']]},
			{"steer":["health","Water & sanitation"],"per":0.65,"src":"society_model.gd:713","guards":[["society_model.gd",'effect("water_safety")*0.65']]}]},
	"sanitation":{"label":"Sanitation","good":1,
		"what":"Latrines, drains and clean streets. Sickness from the surroundings and deaths from illness fall, and children's summer fevers ease.",
		"feeds":[
			{"to":"sickness from heat, damp and filth","per":-1.0,"unit":"pct","cap":"never below 18 in 100 of it","src":"consequence_engine.gd:693","guards":[["consequence_engine.gd",'disease_pressure*maxf(0.18,1.0-WorldSimulation.discovery.effect("sanitation"))*0.045']]},
			{"to":"deaths from illness","per":-1.0,"unit":"pct","cap":"with exposure to disease; never below 35 in 100 of the usual toll","src":"consequence_engine.gd:762","guards":[["consequence_engine.gd",'maxf(0.35,1.0+WorldSimulation.discovery.effect("disease_exposure")-WorldSimulation.discovery.effect("sanitation"))']]},
			{"to":"deaths from disease in the surroundings","per":-1.0,"unit":"pct","cap":"never below 10 in 100 of it","src":"consequence_engine.gd:762","guards":[["consequence_engine.gd",'disease_pressure*maxf(0.10,1.0-WorldSimulation.discovery.effect("sanitation"))*0.005']]},
			{"cover":"water","src":"early_life_conditions.gd:27"},
			{"relief":true,"src":"early_life_conditions.gd:80"},
			{"epidemic":1.0/3.0,"src":"crisis_system.gd:484","guards":[["crisis_system.gd",'var san:=_effect("sanitation")']]},
			{"to":"drinking water quality when sickness spreads","per":0.2,"unit":"pts","src":"crisis_system.gd:498","guards":[["crisis_system.gd",'+0.2*ws+0.2*san']]},
			{"steer":["health","Water & sanitation"],"per":0.45,"src":"society_model.gd:713","guards":[["society_model.gd",'effect("sanitation")*0.45']]}]},
	"disease_exposure":{"label":"Exposure to disease","good":-1,
		"what":"How much sickness daily life exposes people to: crowding, waste and animals. Less is better: health rises and fewer die of illness.",
		"feeds":[
			{"to":"the health the people settle toward","per":-0.18,"unit":"pts","src":"consequence_engine.gd:684","guards":[["consequence_engine.gd",'-WorldSimulation.discovery.effect("disease_exposure")*0.18']]},
			{"to":"deaths from illness while health is poor","per":1.0,"unit":"pct","cap":"with sanitation; never below 35 in 100 of the usual toll","src":"consequence_engine.gd:762","guards":[["consequence_engine.gd",'maxf(0.35,1.0+WorldSimulation.discovery.effect("disease_exposure")-WorldSimulation.discovery.effect("sanitation"))']]},
			{"relief":true,"src":"early_life_conditions.gd:80"},
			{"epidemic":-0.5,"src":"crisis_system.gd:484","guards":[["crisis_system.gd",'var de:=_effect("disease_exposure")']]},
			{"to":"drinking water quality when sickness spreads","per":-0.15,"unit":"pts","src":"crisis_system.gd:498","guards":[["crisis_system.gd",'water-0.15*de']]},
			{"capacity":"health"},
			{"steer":["health","Disease control"],"per":-0.40,"src":"society_model.gd:721","guards":[["society_model.gd",'effect("disease_exposure")*0.40']]},
			{"steer":["health","Water & sanitation"],"per":-0.35,"src":"society_model.gd:713","guards":[["society_model.gd",'effect("disease_exposure")*0.35']]}]},
	"injury_risk":{"label":"Risk of injury","good":-1,
		"what":"How often work and daily life hurt people. Less is better: fewer die of festering wounds, falls and childbed fever. Accidents at work are a separate risk.",
		"feeds":[
			{"cover":"wounds","src":"early_life_conditions.gd:31"},
			{"steer":["health","Injury safety"],"per":-0.55,"src":"society_model.gd:721","guards":[["society_model.gd",'effect("injury_risk")*0.55']]}]},
	"health_risk":{"label":"Hazards of dangerous work","good":-1,
		"what":"Fumes, dust and dangerous processes in mines and workshops. Less is better; it wears down the people's health in proportion to how much they mine and quarry.",
		"feeds":[
			{"chain":"industry_health","per":-1.0,"src":"consequence_engine.gd:692","guards":[["consequence_engine.gd",'(WorldSimulation.discovery.effect("health_risk")+WorldSimulation.discovery.effect("pollution")*0.22+WorldSimulation.discovery.effect("water_pollution")*0.18)*industrial_activity']]},
			{"capacity":"health"}]},
	# --- work -------------------------------------------------------------------
	"labor_efficiency":{"label":"Working efficiency","good":1,
		"what":"Better ways of working. It raises the Labor capacity, which sets how much every hand gets done each day: food, building, making and carrying.",
		"feeds":[
			{"capacity":"labor"},
			{"chain":"labor","src":"consequence_engine.gd:639","guards":[["consequence_engine.gd",'labor_efficiency*=lerpf(0.82,1.08,clampf(float(dynamics.get("labor",0.5)),0.0,1.0))']]},
			{"capacity":"production"}]},
	"labor_demand":{"label":"Extra work required","good":-1,
		"what":"The extra tending, carrying and upkeep the people's ways demand. Less is better: it lowers the Labor capacity and so every hand's daily output.",
		"feeds":[
			{"capacity":"labor"},
			{"chain":"labor","src":"consequence_engine.gd:639","guards":[["consequence_engine.gd",'labor_efficiency*=lerpf(0.82,1.08,clampf(float(dynamics.get("labor",0.5)),0.0,1.0))']]},
			{"capacity":"production"},
			{"steer":["labor","Workload balance"],"per":-0.55,"src":"society_model.gd:722","guards":[["society_model.gd",'effect("labor_demand")*0.55']]}]},
	"fatigue":{"label":"Weariness","good":-1,
		"what":"How worn out people come home. Less is better: it lowers the Labor capacity and so every hand's daily output.",
		"feeds":[
			{"capacity":"labor"},
			{"chain":"labor","src":"consequence_engine.gd:639","guards":[["consequence_engine.gd",'labor_efficiency*=lerpf(0.82,1.08,clampf(float(dynamics.get("labor",0.5)),0.0,1.0))']]},
			{"capacity":"production"},
			{"steer":["labor","Workload balance"],"per":-0.35,"src":"society_model.gd:722","guards":[["society_model.gd",'effect("fatigue")*0.35']]}]},
	"task_coordination":{"label":"Working together","good":1,
		"what":"Rotas, signals and shared plans so work parties do not get in each other's way. It raises the Production capacity.",
		"feeds":[
			{"capacity":"production"},
			{"steer":["labor","Coordination"],"per":0.45,"src":"society_model.gd:722","guards":[["society_model.gd",'effect("task_coordination")*0.45']]}]},
	# --- learning ---------------------------------------------------------------
	"knowledge_rate":{"label":"Pace of learning","good":1,
		"what":"Better ways of teaching and remembering. What the people know grows faster each day, which in turn speeds discovery. Research questions themselves are not sped directly.",
		"feeds":[
			{"to":"daily growth of what the people remember","per":1.0,"unit":"pct","src":"consequence_engine.gd:716","guards":[["consequence_engine.gd",'*(1.0+WorldSimulation.discovery.effect("knowledge_rate"))']]}]},
	"observation_rate":{"label":"Keen observation","good":1,
		"what":"Habits of watching, comparing and recording. Every research question moves faster.",
		"feeds":[
			{"chain":"discovery","per":0.20,"src":"consequence_engine.gd:1032","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("observation_rate")*0.20,0.35,1.65']]}]},
	"knowledge_preservation":{"label":"Keeping knowledge","good":1,
		"what":"Tallies, records and teachers that keep what is known from being lost. Practices nobody uses fade more slowly, the Knowledge capacity rises, and learning is taught better, which speeds every research line.",
		"feeds":[
			{"chain":"forget","src":"society_model.gd:141","guards":[["society_model.gd",'effect("knowledge_preservation"),0.05,1.2)']]},
			{"capacity":"knowledge"},
			{"chain":"education","per":0.55*0.58,"src":"society_model.gd:714, civilization_indicators.gd:46","guards":[["society_model.gd",'effect("knowledge_preservation")*0.55,0.0,1.0)'],["civilization_indicators.gd",'preservation*0.58+communication*0.42']]}]},
	"adoption_rate":{"label":"Spread of new ways","good":1,
		"what":"Teaching, example and custom that carry a practice from household to household. Every known practice spreads faster, so its benefits arrive sooner.",
		"feeds":[
			{"chain":"spread","src":"society_model.gd:147","guards":[["society_model.gd",'clampf(effect("adoption_rate")+WorldSimulation.state.founding_effect("adoption_rate")+WorldSimulation.progression.effect("adoption_rate"),-0.35,0.80)']]}]},
	"literacy":{"label":"Reading and writing","good":1,
		"what":"The share of adults who read. Past 55 in 100 readers, schooling leads couples to choose smaller families. (Research comes from the people at learning, never from a people's size or reading alone.)",
		"feeds":[
			{"text":"Once more than 55 in 100 read, each point beyond adds 0.22 of a point to the births couples choose not to have.","src":"early_life_conditions.gd:152","guards":[["early_life_conditions.gd",'var literacy:=clampf(discovery.effect("literacy"),0.0,1.0)']]}]},
	"survey_speed":{"label":"Surveying speed","good":1,
		"what":"Knowing how to read the ground. Surveyors learn the extent of known deposits sooner.",
		"feeds":[
			{"to":"survey progress on deposits","per":1.0,"unit":"pct","src":"resource_system.gd:1040","guards":[["resource_system.gd",'"speed":1.0+WorldSimulation.discovery.effect("survey_speed")']]}]},
	"water_access":{"label":"Water access","good":1,
		"what":"Wells, cisterns, channels and pipes that bring water nearer. The walk to the nearest source counts as shorter than the ground: each 1 in 100 takes 0.75 in 100 off it. Households then fetch more of their own water, even from a source that was too far to walk to, and carriers bring in more each day.",
		"feeds":[
			{"to":"the walk to the water source","per":-0.75,"unit":"pct","cap":"households fetch all the water they need within about 2 km of walking, less farther out and none past 6 km; carriers lose less on a shorter carry","src":"research_mechanics.gd water_walk_factor_of, resource_system.gd _process_water_flow","guards":[["research_mechanics.gd","const WATER_WALK_CUT:=0.75"],["research_mechanics.gd","return 1.0-WATER_WALK_CUT*clampf(access,WATER_ACCESS_LIMITS.x,WATER_ACCESS_LIMITS.y)"],["research_mechanics.gd",'return water_walk_factor_of(WorldSimulation.discovery.effect("water_access"))'],["resource_system.gd",'var walk_km:float=nearest_source_km*preload("res://scripts/research_mechanics.gd").water_walk_factor()'],["resource_system.gd","var distance_factor:=1.0/maxf(1.0,1.0+walk_km*0.16)"],["resource_system.gd","_household_surface_water_access_ratio(walk_km)"]]},
			{"chain":"water_today","src":"resource_system.gd _household_surface_water_access_ratio","guards":[["resource_system.gd","return lerpf(1.18,0.38,clampf((distance_km-1.0)/5.0,0.0,1.0))"],["resource_system.gd","if distance_km<0.0 or distance_km==INF or distance_km>6.0: return 0.0"]]}]},
	# --- craft and materials ----------------------------------------------------
	"tool_quality":{"label":"Tool quality","good":1,
		"what":"Sharper, tougher tools. The workshops can make more, and the town can reach its last building eras.",
		"feeds":[
			{"to":"the making capacity the workshops settle toward","per":0.30,"unit":"pts","src":"consequence_engine.gd:729","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("tool_quality")*0.30']]},
			{"capacity":"production"},
			{"eras":"its 11th and 12th building eras","src":"settlement_model.gd:2495","guards":[["settlement_model.gd",'"tools":discovery.effect("tool_quality")']]},
			{"steer":["production","Tool quality"],"per":0.65,"src":"society_model.gd:724","guards":[["society_model.gd",'effect("tool_quality")*0.65']]}]},
	"craft_output":{"label":"Craft output","good":1,
		"what":"Skill and method in the workshops. They can make more, and the town can reach its later building eras.",
		"feeds":[
			{"to":"the making capacity the workshops settle toward","per":0.22,"unit":"pts","src":"consequence_engine.gd:729","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("craft_output")*0.22']]},
			{"eras":"its 7th to 12th building eras","src":"settlement_model.gd:2494","guards":[["settlement_model.gd",'"craft":discovery.effect("craft_output")']]},
			{"steer":["production","Craft capacity"],"per":0.45,"src":"society_model.gd:724","guards":[["society_model.gd",'effect("craft_output")*0.45']]}]},
	"extraction_yield":{"label":"Extraction yield","good":1,
		"what":"Better ways of digging, cutting and quarrying. Every worked deposit gives more each day.",
		"feeds":[
			{"to":"daily yield of every worked deposit","per":1.0,"unit":"pct","src":"resource_system.gd:636","guards":[["resource_system.gd",'var extraction_effect:=WorldSimulation.discovery.effect("extraction_yield")'],["resource_system.gd",'var knowledge_multiplier:=1.0+extraction_effect']]},
			{"steer":["production","Material supply"],"per":0.20,"src":"society_model.gd:716","guards":[["society_model.gd",'effect("extraction_yield")*0.20']]}]},
	"metal_yield":{"label":"Ore yield","good":1,
		"what":"Knowing good ore and how to work a seam. Every worked ore deposit gives more each day.",
		"feeds":[
			{"to":"daily yield of worked ore","per":1.0,"unit":"pct","src":"resource_system.gd:637","guards":[["resource_system.gd",'var metal_effect:=WorldSimulation.discovery.effect("metal_yield")'],["resource_system.gd",'if String(profile.family)=="metal": knowledge_multiplier+=metal_effect']]},
			{"steer":["production","Material supply"],"per":0.12,"src":"society_model.gd:716","guards":[["society_model.gd",'effect("metal_yield")*0.12']]}]},
	"timber_yield":{"label":"Timber yield","good":1,
		"what":"Felling and trimming skill. Worked woodland gives more timber each day.",
		"feeds":[
			{"to":"daily yield of worked timber","per":1.0,"unit":"pct","src":"resource_system.gd:649","guards":[["resource_system.gd",'WorldSimulation.discovery.effect(String(deposit.resource).to_lower().replace(" ","_")+"_yield")']]}]},
	"stone_yield":{"label":"Stone yield","good":1,
		"what":"Quarrying skill. Worked stone gives more each day.",
		"feeds":[
			{"to":"daily yield of worked stone","per":1.0,"unit":"pct","src":"resource_system.gd:649","guards":[["resource_system.gd",'WorldSimulation.discovery.effect(String(deposit.resource).to_lower().replace(" ","_")+"_yield")']]}]},
	"clay_yield":{"label":"Clay yield","good":1,
		"what":"Digging and sorting clay. Worked clay pits give more each day.",
		"feeds":[
			{"to":"daily yield of worked clay","per":1.0,"unit":"pct","src":"resource_system.gd:649","guards":[["resource_system.gd",'WorldSimulation.discovery.effect(String(deposit.resource).to_lower().replace(" ","_")+"_yield")']]}]},
	"fiber_yield":{"label":"Fibre yield","good":1,
		"what":"Gathering and retting skill. Worked fibre plants give more each day.",
		"feeds":[
			{"to":"daily yield of worked fibre plants","per":1.0,"unit":"pct","src":"resource_system.gd:653","guards":[["resource_system.gd",'if String(deposit.resource)=="Fiber Plants": knowledge_multiplier+=WorldSimulation.discovery.effect("fiber_yield")']]}]},
	"fuel_efficiency":{"label":"Fuel economy","good":1,
		"what":"Charcoal, bellows, closed ovens and kilns, chimneys and stoves, and later better engines: the same work from less fuel. Every fire the people keep burns less wood or coal: the kept hearth, the smoking fires that preserve food, and the kilns and engines they install. Each 1 in 100 saves 0.6 in 100 of the usual fuel. Workshop batches that burn charcoal or coal do not read it yet.",
		"feeds":[
			{"chain":"fuel","src":"research_mechanics.gd fuel_factor_of; fire_practice.gd advance, food_system.gd _preserve, technology_operations.gd input_rate","guards":FUEL_GUARDS}]},
	"repair_capacity":{"label":"Repair skill","good":1,
		"what":"Resharpening and re-hafting, sound joints and footings, repointing and patching. Household goods in use (tools, pots, baskets, cloth) wear out more slowly, and the builders' monthly mending of the town goes further with the same hands and materials, so fewer builders hold it. Army gear and great works do not read it yet.",
		"feeds":[
			{"to":"household goods worn out each day","per":-0.5,"unit":"pct","cap":"of the usual wear, 0.4 in 100 of the stock a day","src":"research_mechanics.gd goods_wear_factor_of, civilian_goods.gd daily_wear","guards":[["research_mechanics.gd","const REPAIR_WEAR_CUT:=0.5"],["research_mechanics.gd","return 1.0-REPAIR_WEAR_CUT*repair_skill_of(repair)"],["research_mechanics.gd",'return goods_wear_factor_of(WorldSimulation.discovery.effect("repair_capacity"))'],["civilian_goods.gd",'return DAILY_WEAR*preload("res://scripts/research_mechanics.gd").goods_wear_factor()'],["civilian_goods.gd","var worn:=stock()*(1.0-pow(1.0-daily_wear(),elapsed))"]]},
			{"to":"the town's mending each month from the same builders and materials","per":1.0,"unit":"pct","cap":"so fewer builders hold the town against its wear of 2 in 100 a month","src":"research_mechanics.gd mending_factor_of, settlement_model.gd _advance_city_form, upkeep_warnings.gd facts","guards":[["research_mechanics.gd","const REPAIR_MENDING_GAIN:=1.0"],["research_mechanics.gd","return 1.0+REPAIR_MENDING_GAIN*repair_skill_of(repair)"],["research_mechanics.gd",'return mending_factor_of(WorldSimulation.discovery.effect("repair_capacity"))'],["settlement_model.gd",'var mending:float=preload("res://scripts/research_mechanics.gd").mending_factor()'],["settlement_model.gd","form.condition=clampf(float(form.condition)+0.04*building_share*paid*mending-0.02,0.05,1.0)"],["upkeep_warnings.gd","var reach:=paid*mending"],["upkeep_warnings.gd","var change:=0.04*share*reach-0.02"]]},
			{"chain":"repair_today","src":"civilian_goods.gd DAILY_WEAR","guards":[["civilian_goods.gd","const DAILY_WEAR:=.004"]]}]},
	"standardization":{"label":"Shared measures","good":1,
		"what":"Common weights, lengths and ways of making. Markets open wider, trade loses less to error and haggling, learning is shared more easily, and the town's later building eras come within reach.",
		"feeds":[
			{"to":"market access","per":0.24,"unit":"pts","src":"economy_system.gd:232","guards":[["economy_system.gd",'WorldSimulation.discovery.effect("standardization")*0.24']]},
			{"to":"the share lost on each trade abroad","per":-0.10,"unit":"pts","cap":"the loss stays between 6 and 24 in 100","src":"economy_system.gd:346","guards":[["economy_system.gd",'-WorldSimulation.discovery.effect("standardization")*0.10,0.06,0.24)']]},
			{"capacity":"knowledge"},
			{"chain":"education","per":0.42*0.42,"src":"society_model.gd:715, civilization_indicators.gd:46","guards":[["society_model.gd",'effect("standardization")*0.42+effect("state_capacity")*0.22,0.0,1.0)']]},
			{"eras":"its 10th to 12th building eras","src":"settlement_model.gd:2495","guards":[["settlement_model.gd",'"standardization":discovery.effect("standardization")']]},
			{"steer":["production","Standardization"],"per":0.82,"src":"society_model.gd:724","guards":[["society_model.gd",'effect("standardization")*0.82']]}]},
	"chemical_control":{"label":"Control of chemicals","good":1,
		"what":"Knowing what fumes, acids and wastes do and how to hold them back. Part of the harm that smoke, slag and fouled water from the people's works do to their health and to the land is prevented: each 1 in 100 prevents 1.5 in 100 of it, up to 60 in 100. Only harm is cut, and that harm comes in proportion to mining and quarrying. It does not change what the workshops make.",
		"feeds":[
			{"to":"the share of the harm from smoke and fouled water that is prevented","per":1.5,"unit":"pts","cap":"at most 60 in 100","src":"research_mechanics.gd chemical_harm_cut_of, consequence_engine.gd","guards":[["research_mechanics.gd","const CHEMICAL_HARM_CUT:=1.5"],["research_mechanics.gd","const CHEMICAL_HARM_CUT_LIMIT:=0.60"],["research_mechanics.gd","return clampf(control*CHEMICAL_HARM_CUT,0.0,CHEMICAL_HARM_CUT_LIMIT)"],["research_mechanics.gd",'return chemical_harm_cut_of(WorldSimulation.discovery.effect("chemical_control"))'],["consequence_engine.gd",'var chemical_cut:float=preload("res://scripts/research_mechanics.gd").chemical_harm_cut()']]},
			{"chain":"chemical_health","src":"consequence_engine.gd process_day","guards":[["consequence_engine.gd",'process_health_cost-=maxf(0.0,WorldSimulation.discovery.effect("pollution")*0.22+WorldSimulation.discovery.effect("water_pollution")*0.18)*industrial_activity*chemical_cut']]},
			{"chain":"chemical_land","src":"consequence_engine.gd process_day","guards":[["consequence_engine.gd",'ecology_delta+=maxf(0.0,WorldSimulation.discovery.effect("pollution")+WorldSimulation.discovery.effect("water_pollution"))*industrial_activity*0.0009*chemical_cut']]}]},
	# --- building ---------------------------------------------------------------
	"construction_rate":{"label":"Building speed","good":1,
		"what":"Better methods and organisation on the building site. Every project goes up faster, the town scores as better built, and its later building eras come within reach.",
		"feeds":[
			{"to":"each day's building work","per":1.0,"unit":"pct","cap":"added to building decrees and the people's scale","src":"settlement_construction.gd:116","guards":[["settlement_construction.gd",'(1.0+WorldSimulation.discovery.effect("construction_rate")+WorldSimulation.progression.effect("construction_rate")']]},
			{"to":"the town's built-up score","per":0.20,"unit":"pts","src":"settlement_model.gd:3095","guards":[["settlement_model.gd",'WorldSimulation.discovery.effect("construction_rate")*0.20']]},
			{"text":"Once it reaches 2.5 in 100, durable homes rise to three storeys in the town's eighth building era.","src":"settlement_model.gd:2639","guards":[["settlement_model.gd",'WorldSimulation.discovery.effect("construction_rate")>=0.025: new_storeys=3']]},
			{"eras":"its 7th to 12th building eras","src":"settlement_model.gd:2494","guards":[["settlement_model.gd",'"construction":discovery.effect("construction_rate")']]},
			{"capacity":"infrastructure"},
			{"steer":["infrastructure","Construction"],"per":0.30,"src":"society_model.gd:725","guards":[["society_model.gd",'effect("construction_rate")*0.30']]}]},
	"housing_output":{"label":"Room in shelters","good":1,
		"what":"Better ways of pitching, roofing and dividing shelters. It sets how many people the Lean-to Shelters hold when they are finished, and every later batch of new homes holds as much more.",
		"feeds":[
			{"chain":"lean_to","src":"settlement_construction.gd","guards":[["settlement_construction.gd",'return maxf(0.0,WorldSimulation.discovery.effect("housing_output")+WorldSimulation.progression.effect("housing_output"))'],["settlement_construction.gd",'return roundi(LEAN_TO_PLACES*(1.0+housing_output()))'],["settlement_construction.gd",'return roundi(maxi(24,roundi(WorldSimulation.state.population_total*.12))*(1.0+housing_output()))']]}]},
	"disaster_resilience":{"label":"Resilience to disaster","good":1,
		"what":"Building and stores made to ride out floods, fires and storms. Today it only raises the Infrastructure capacity; no flood, fire or storm reads it directly.",
		"feeds":[
			{"capacity":"infrastructure"},
			{"steer":["infrastructure","Resilience"],"per":0.65,"src":"society_model.gd:725","guards":[["society_model.gd",'effect("disaster_resilience")*0.65']]},
			{"steer":["security","Crisis resilience"],"per":0.48,"src":"society_model.gd:729","guards":[["society_model.gd",'effect("disaster_resilience")*0.48']]}]},
	"mine_safety":{"label":"Mine safety","good":1,
		"what":"Props, air and drainage in pits and quarries. Fewer die in accidents at work, and access to new deposits is opened faster.",
		"feeds":[
			{"to":"deaths from accidents at work","per":-1.0,"unit":"pct","cap":"with the risk of accidents; never below 15 in 100 of the usual toll","src":"consequence_engine.gd:770","guards":[["consequence_engine.gd",'maxf(0.15,1.0+WorldSimulation.discovery.effect("disaster_risk")-WorldSimulation.discovery.effect("mine_safety"))']]},
			{"to":"the pace of opening access to deposits","per":0.5,"unit":"pct","src":"resource_system.gd:443","guards":[["resource_system.gd",'WorldSimulation.discovery.effect("mine_safety")*.5']]}]},
	"mining_output":{"label":"Mine output","good":1,
		"what":"Drainage, hoists, pumps and blasting that let mines go deeper and work faster. Every mined deposit gives more each day: ores, coal, sulfur, graphite, phosphate and oil, the things dug from pits and shafts. Stone, clay, sand, salt, peat, timber and plants are cut or gathered, and do not change.",
		"feeds":[
			{"to":"daily yield of every mined deposit","per":1.0,"unit":"pct","cap":"added to extraction yield and ore yield","src":"research_mechanics.gd is_mined, resource_system.gd _process_material_flow","guards":[["research_mechanics.gd",'return String(profile.get("family",""))=="metal" or "mine" in (definition.get("access",[]) as Array)'],["research_mechanics.gd",'return mining_bonus_of(WorldSimulation.discovery.effect("mining_output"))'],["resource_system.gd",'var mining_effect:float=preload("res://scripts/research_mechanics.gd").mining_bonus()'],["resource_system.gd",'if preload("res://scripts/research_mechanics.gd").is_mined(catalog.get(String(deposit.resource),{}),profile): knowledge_multiplier+=mining_effect']]},
			{"chain":"mines","src":"resource_system.gd catalog access, material profiles","guards":[["resource_system.gd",'"Coal":{"family":"Fuel","renewable":false,"recognition_year":55,"access":["mine"'],["resource_system.gd",'const ORE_PROFILE:={"family":"metal"']]}]},
	"disaster_risk":{"label":"Risk of accidents","good":-1,
		"what":"Dangerous works: deep pits, heavy lifting, fire. Less is better; it raises deaths from accidents at work in proportion to mining and quarrying.",
		"feeds":[
			{"to":"deaths from accidents at work","per":1.0,"unit":"pct","cap":"with mine safety; never below 15 in 100 of the usual toll","src":"consequence_engine.gd:770","guards":[["consequence_engine.gd",'maxf(0.15,1.0+WorldSimulation.discovery.effect("disaster_risk")-WorldSimulation.discovery.effect("mine_safety"))']]}]},
	"mobile_shelter":{"label":"Shelter on the move","good":1,
		"what":"Tents, hides and frames the people carry. While they travel, more of them sleep under cover, which protects health and lowers deaths from exposure.",
		"feeds":[
			{"to":"people under cover while travelling","per":1.0,"unit":"pts","cap":"between 18 and 86 in 100","src":"consequence_engine.gd:635","guards":[["consequence_engine.gd",'mobile_shelter_ratio+=WorldSimulation.discovery.effect("mobile_shelter")']]}]},
	# --- transport and stores ---------------------------------------------------
	"haul_capacity":{"label":"Carrying capacity","good":1,
		"what":"Baskets, frames, carts and pack animals. Carriers move more water, materials and trade goods, and the people's hauling strength grows.",
		"feeds":[
			{"to":"water brought in by organised carriers","per":1.0,"unit":"pct","cap":"counts from -40% to +150%","src":"resource_system.gd:357","guards":[["resource_system.gd",'(1.0+clampf(WorldSimulation.discovery.effect("haul_capacity"),-0.4,1.5))']]},
			{"to":"materials hauled home from worked deposits","per":1.0,"unit":"pct","src":"resource_system.gd:694","guards":[["resource_system.gd",'var haul_effect:=1.0+WorldSimulation.discovery.effect("haul_capacity")']]},
			{"to":"goods each carrier moves between towns","per":1.0,"unit":"pct","cap":"with the people's scale; only gains count","src":"settlement_model.gd:315","guards":[["settlement_model.gd",'var hauling:=maxf(0.0,WorldSimulation.discovery.effect("haul_capacity")+WorldSimulation.progression.effect("haul_capacity"))']]},
			{"to":"the hauling strength the carriers settle toward","per":0.18,"unit":"pts","src":"consequence_engine.gd:732","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("haul_capacity")*0.18']]},
			{"capacity":"logistics"},
			{"steer":["logistics","Carrying capacity"],"per":0.42,"src":"society_model.gd:726","guards":[["society_model.gd",'effect("haul_capacity")*0.42']]}]},
	"route_speed":{"label":"Known routes","good":1,
		"what":"Known paths, markers and roads. Scouts range farther and the known country grows faster, hauls from deposits go easier, trade between towns reaches farther, and learning travels better.",
		"feeds":[
			{"to":"how far scouting parties range, and how fast the known country grows","per":1.0,"unit":"pct","cap":"with the people's scale, counts up to 60 in 100; the known country grows one and a half times this","src":"civilization_system.gd:3200","guards":[["civilization_system.gd",'var travel_knowledge:=clampf(WorldSimulation.discovery.effect("route_speed")+WorldSimulation.progression.effect("route_speed"),0.0,0.60)']]},
			{"to":"the going on every haul from a deposit","per":1.0,"unit":"pts","cap":"a bare track counts 34 and a finished road 100","src":"resource_system.gd:693","guards":[["resource_system.gd",'var route_factor:=0.34+float(deposit.route)*0.66+route_speed_effect']]},
			{"to":"the pace of opening access to deposits","per":1.0,"unit":"pct","src":"resource_system.gd:443","guards":[["resource_system.gd",'"knowledge":1.0+WorldSimulation.discovery.effect("route_speed")']]},
			{"to":"the reach of trade between towns","per":180.0,"unit":"km","cap":"with the people's scale; only gains count","src":"settlement_model.gd:314","guards":[["settlement_model.gd",'"range_km":12.0+logistics*120.0+transport*180.0']]},
			{"to":"the hauling strength the carriers settle toward","per":0.12,"unit":"pts","src":"consequence_engine.gd:732","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("route_speed")*0.12']]},
			{"to":"how well the town is connected","per":0.30,"unit":"pts","src":"settlement_model.gd:3094","guards":[["settlement_model.gd",'WorldSimulation.discovery.effect("route_speed")*0.30']]},
			{"capacity":"logistics"},
			{"capacity":"knowledge"},
			{"chain":"education","per":0.30*0.42,"src":"society_model.gd:715, civilization_indicators.gd:46","guards":[["society_model.gd",'clampf(0.28+effect("route_speed")*0.30']]},
			{"eras":"its 6th and its 8th to 12th building eras","src":"settlement_model.gd:2494","guards":[["settlement_model.gd",'"route":discovery.effect("route_speed")']]},
			{"steer":["logistics","Route quality"],"per":0.35,"src":"society_model.gd:717","guards":[["society_model.gd",'effect("route_speed")*0.35']]}]},
	"travel_speed":{"label":"Travel speed","good":1,
		"what":"Faster going on the roads. Shipments from outlying deposits arrive in fewer days.",
		"feeds":[
			{"to":"the speed of shipments from deposits","per":1.0,"unit":"pct","src":"resource_system.gd:695","guards":[["resource_system.gd",'var travel_effect:=1.0+WorldSimulation.discovery.effect("travel_speed")']]}]},
	"storage_loss":{"label":"Losses from stores","good":-1,
		"what":"How much stored material rots, rusts or goes missing each day. Less is better. It is added to each material's own small daily loss, and a loss cannot fall below nothing, so a small total already stops all loss.",
		"feeds":[
			{"chain":"storage","src":"resource_system.gd:929","guards":[["resource_system.gd",'SPAN.rate(maxf(0.0,float(profile.loss)+WorldSimulation.discovery.effect("storage_loss")))']]},
			{"capacity":"logistics"},
			{"steer":["logistics","Storage system"],"per":-0.35,"src":"society_model.gd:726","guards":[["society_model.gd",'effect("storage_loss")*0.35']]}]},
	"dry_storage":{"label":"Dry storage space","good":1,
		"what":"Lofts, baskets and granaries that keep things dry. The stores hold more of what must stay dry.",
		"feeds":[
			{"to":"dry storage space","per":1.0,"unit":"pct","src":"resource_system.gd:904","guards":[["resource_system.gd",'result.dry*=1.0+WorldSimulation.discovery.effect("dry_storage")']]}]},
	"container_capacity":{"label":"Containers","good":1,
		"what":"Pots, jars and sealed vessels. Covered and sealed storage holds more, and once the Open Work Area stands, households keep more water.",
		"feeds":[
			{"to":"covered and sealed storage space","per":1.0,"unit":"pct","src":"resource_system.gd:905","guards":[["resource_system.gd",'result.covered*=1.0+WorldSimulation.discovery.effect("container_capacity")'],["resource_system.gd",'result.sealed*=1.0+WorldSimulation.discovery.effect("container_capacity")']]},
			{"to":"days of water each person can keep, once the Open Work Area stands","per":2.0,"unit":"days","src":"resource_system.gd:369","guards":[["resource_system.gd",'portable_days+=1.0+WorldSimulation.discovery.effect("container_capacity")*2.0']]}]},
	"logistics_endurance":{"label":"Supply endurance","good":1,
		"what":"Pack animals and saddles, waystations and food caches, relay carrying and food that keeps on the road. The carriers who take food to bands in the field eat less of each load on the way, so food reaches bands farther from home; and a band short of food holds out longer before hunger weakens it. Settler caravans and scouts do not read it yet.",
		"feeds":[
			{"to":"the share of each load the carriers eat for each day of hauling","per":-0.5,"unit":"pct","cap":"of the usual share: porters 8 in 100 a day, carts 5, lorries 3, after the first day and a half","src":"research_mechanics.gd haul_loss_factor_of, supply_state.gd carrier_loss","guards":[["research_mechanics.gd","const ENDURANCE_HAUL_CUT:=0.5"],["research_mechanics.gd","return 1.0-ENDURANCE_HAUL_CUT*endurance_of(endurance)"],["research_mechanics.gd",'return endurance_of(WorldSimulation.discovery.effect("logistics_endurance"))'],["supply_state.gd","return float(c.loss)*Mechanics.haul_loss_factor_of(endurance)"],["supply_state.gd","return clampf(1.0-carrier_loss(who,endurance)*maxf(0.0,days-FREE_DAYS),0.0,1.0)"],["supply_state.gd","who,float(land.cold)),who,endurance_today())"],["supply_state.gd",'"endurance":endurance_today()']]},
			{"to":"how fast a band short of food counts its hungry days","per":-0.5,"unit":"pct","cap":"after 3 such days it goes hungry and fights weaker","src":"research_mechanics.gd hunger_pace_of, field_rations.gd mark_day","guards":[["research_mechanics.gd","const ENDURANCE_HUNGER_SLOW:=0.5"],["research_mechanics.gd","return 1.0-ENDURANCE_HUNGER_SLOW*endurance_of(endurance)"],["field_rations.gd",'var pace:float=preload("res://scripts/research_mechanics.gd").hunger_pace()'],["field_rations.gd",'force["hungry_days"]=days+span*pace if ratio<HUNGRY_BELOW']]},
			{"chain":"supply_reach","src":"supply_state.gd reach_effort","guards":[["supply_state.gd","return (FREE_DAYS+(1.0-share)/carrier_loss(who,endurance))*float(c.pace)"]]}]},
	"trade_capacity":{"label":"Trade reach","good":1,
		"what":"Markets, agents and ways of dealing with strangers. Market access widens, which draws trade and eases the economy's growth.",
		"feeds":[
			{"to":"market access","per":0.32,"unit":"pts","src":"economy_system.gd:232","guards":[["economy_system.gd",'WorldSimulation.discovery.effect("trade_capacity")*0.32']]},
			{"to":"the town's exchange score, where no market reading exists yet","per":0.40,"unit":"pts","src":"settlement_model.gd:3092","guards":[["settlement_model.gd",'WorldSimulation.discovery.effect("trade_capacity")*0.40']]},
			{"steer":["logistics","Trade reach"],"per":0.70,"src":"society_model.gd:726","guards":[["society_model.gd",'effect("trade_capacity")*0.70']]}]},
	"naval_capacity":{"label":"Seafaring strength","good":1,
		"what":"Sealed and caulked hulls, masts and sails, rigging, pilots and sailing calendars: boats and sailors reach farther out. On a sea coast the fishing grounds hold more fish and each fisher reaches more of the sea, and scouting parties with river or coastal craft cross wider stretches of open water. War fleets do not read it yet.",
		"feeds":[
			{"to":"how far out the people's boats and sailors reach","per":1.0,"unit":"pct","cap":"on the sea coast's fishing grounds, each fisher's reach at sea, and the open water scouts can cross","src":"research_mechanics.gd sea_reach_of","guards":[["research_mechanics.gd","const SEA_REACH_GAIN:=1.0"],["research_mechanics.gd","return 1.0+SEA_REACH_GAIN*clampf(naval,NAVAL_LIMITS.x,NAVAL_LIMITS.y)"],["research_mechanics.gd",'return sea_reach_of(WorldSimulation.discovery.effect("naval_capacity"))']]},
			{"chain":"sea_fishing","src":"research_mechanics.gd fishing_ground_of, food_system.gd wild_food_capacity","guards":[["research_mechanics.gd","return 15.0+water*80.0+shoreline*40.0*reach"],["food_system.gd",'"Fishing":{"rations":Mechanics.fishing_ground_of(water,float(coastal.shoreline_access),sea_reach)*reach'],["food_system.gd","var sea_reach:float=Mechanics.sea_reach()"]]},
			{"chain":"sea_catch","src":"research_mechanics.gd fishing_access_of, food_system.gd _produce","guards":[["research_mechanics.gd","return maxf(freshwater,minf(1.0,marine*0.90*reach))"],["food_system.gd","var fishing_access:float=Mechanics.fishing_access_of(float(access.freshwater),float(coastal.marine_opportunity),Mechanics.sea_reach())"],["food_system.gd","*(0.76+fishing_access*0.34)*"]]},
			{"chain":"sea_crossing","src":"civilization_system.gd _scout_water_crossing_allowance_km","guards":[["civilization_system.gd",'var reach:float=preload("res://scripts/research_mechanics.gd").sea_reach()'],["civilization_system.gd","return roundf(craft*reach)"]]}]},
	# --- government -------------------------------------------------------------
	"state_capacity":{"label":"Capacity to organize","good":1,
		"what":"Offices, records and routines of rule. The people hold together better, the realm's administration reaches farther, and learning is shared more widely.",
		"feeds":[
			{"to":"the cohesion the people settle toward","per":0.08,"unit":"pts","src":"consequence_engine.gd:706","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("state_capacity")*0.08']]},
			{"to":"the reach of the realm's administration over land and towns","per":1.0,"unit":"pts","cap":"added to the Institutions capacity, at most 100","src":"settlement_model.gd:834","guards":[["settlement_model.gd",'clampf(float(WorldSimulation.state.society_capacities.get("institutions",0.25))+WorldSimulation.discovery.effect("state_capacity"),0.0,1.0)']]},
			{"capacity":"institutions"},
			{"capacity":"knowledge"},
			{"chain":"education","per":0.22*0.42,"src":"society_model.gd:715, civilization_indicators.gd:46","guards":[["society_model.gd",'effect("state_capacity")*0.22,0.0,1.0)']]},
			{"eras":"its 12th building era","src":"settlement_model.gd:2495","guards":[["settlement_model.gd",'"state_capacity":discovery.effect("state_capacity")']]},
			{"steer":["institutions","State capacity"],"per":0.70,"src":"society_model.gd:728","guards":[["society_model.gd",'effect("state_capacity")*0.70']]}]},
	"legitimacy":{"label":"Accepted authority","good":1,
		"what":"Customs that make rule rightful in the people's eyes. Trust in the chiefs rises.",
		"feeds":[
			{"to":"the trust in the chiefs the people settle toward","per":0.12,"unit":"pts","src":"consequence_engine.gd:743","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("legitimacy")*0.12']]},
			{"capacity":"institutions"}]},
	"cohesion":{"label":"Social cohesion","good":1,
		"what":"Feasts, kinship customs and shared rites. The people hold together better.",
		"feeds":[
			{"to":"the cohesion the people settle toward","per":0.10,"unit":"pts","src":"consequence_engine.gd:706","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("cohesion")*0.10']]},
			{"capacity":"culture"}]},
	"institutional_rigidity":{"label":"Rigid custom","good":-1,
		"what":"Rules and ranks that resist change. Less is better: rigid custom overloads the keepers of knowledge and lowers the Knowledge capacity.",
		"feeds":[
			{"capacity":"knowledge"},
			{"steer":["institutions","Institutional flexibility"],"per":-0.65,"src":"society_model.gd:728","guards":[["society_model.gd",'effect("institutional_rigidity")*0.65']]}]},
	# --- defense ----------------------------------------------------------------
	"warfare_readiness":{"label":"Readiness to fight","good":1,
		"what":"Drill, weapons and plans for war. The people's safety rises. The army's own training reads the people's scale instead of this.",
		"feeds":[
			{"to":"the safety the people settle toward","per":0.14,"unit":"pts","src":"consequence_engine.gd:734","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("warfare_readiness")*0.14']]},
			{"capacity":"security"},
			{"steer":["security","Military readiness"],"per":0.65,"src":"society_model.gd:729","guards":[["society_model.gd",'effect("warfare_readiness")*0.65']]}]},
	"security_efficiency":{"label":"Watch and guard","good":1,
		"what":"Sentries, signals and patrols. Today it only raises the Security capacity; the daily safety of the people reads the people's scale instead.",
		"feeds":[
			{"capacity":"security"},
			{"steer":["security","Organized defense"],"per":0.48,"src":"society_model.gd:729","guards":[["society_model.gd",'effect("security_efficiency")*0.48']]}]},
	# --- land -------------------------------------------------------------------
	"ecology_recovery":{"label":"Land recovery","good":1,
		"what":"Resting ground, replanting and protecting breeding seasons. Wild food grounds recover faster from use.",
		"feeds":[
			{"to":"the daily recovery of wild food grounds","per":1.0,"unit":"pct","src":"food_system.gd:663","guards":[["food_system.gd",'(0.0007 if traveling else 0.00035)*(1.0+WorldSimulation.discovery.effect("ecology_recovery"))']]},
			{"to":"regrowth of wild plants, game and fish","per":1.0,"unit":"pct","cap":"only gains count","src":"food_system.gd:694","guards":[["food_system.gd",'(1.0+maxf(0.0,WorldSimulation.discovery.effect("ecology_recovery")))']]},
			{"capacity":"ecology"},
			{"steer":["ecology","Natural recovery"],"per":0.38,"src":"society_model.gd:727","guards":[["society_model.gd",'effect("ecology_recovery")*0.38']]}]},
	"ecological_pressure":{"label":"Strain on the land","good":-1,
		"what":"How hard the people's ways press on wild grounds. Less is better: heavy gathering, hunting and fishing wear the grounds down less.",
		"feeds":[
			{"to":"wear on wild food grounds from heavy use","per":1.0,"unit":"pct","src":"food_system.gd:671","guards":[["food_system.gd",'*0.0018*(1.0+WorldSimulation.discovery.effect("ecological_pressure"))'],["food_system.gd",'current*(1.0+WorldSimulation.discovery.effect("ecological_pressure"))']]},
			{"capacity":"ecology"},
			{"steer":["ecology","Resource pressure"],"per":-0.62,"src":"society_model.gd:727","guards":[["society_model.gd",'effect("ecological_pressure")*0.62']]}]},
	"timber_pressure":{"label":"Demand for timber","good":-1,"steer_only":true,
		"what":"How much wood the people's ways use. It changes nothing the people live with yet: its only use is to guide which land questions the lore keepers take up next.",
		"feeds":[
			{"steer":["ecology","Resource pressure"],"per":-0.30,"src":"society_model.gd:727","guards":[["society_model.gd",'effect("timber_pressure")*0.30']]}]},
	"pollution":{"label":"Smoke and waste","good":-1,
		"what":"Smoke, slag and refuse from fires and works. Less is better; in proportion to mining and quarrying it wears down health and the land. Control of chemicals prevents part of that harm.",
		"feeds":[
			{"chain":"industry_health","per":-0.22,"src":"consequence_engine.gd:692","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("pollution")*0.22']]},
			{"chain":"industry_land","src":"consequence_engine.gd:741","guards":[["consequence_engine.gd",'ecology_delta-=(WorldSimulation.discovery.effect("pollution")+WorldSimulation.discovery.effect("water_pollution"))*industrial_activity*0.0009']]},
			{"capacity":"ecology"},
			{"steer":["ecology","Pollution control"],"per":-0.70,"src":"society_model.gd:727","guards":[["society_model.gd",'effect("pollution")*0.70']]}]},
	"water_pollution":{"label":"Fouled water","good":-1,
		"what":"Waste and runoff in streams and wells. Less is better; in proportion to mining and quarrying it wears down health and the land. Control of chemicals prevents part of that harm.",
		"feeds":[
			{"chain":"industry_health","per":-0.18,"src":"consequence_engine.gd:692","guards":[["consequence_engine.gd",'WorldSimulation.discovery.effect("water_pollution")*0.18']]},
			{"chain":"industry_land","src":"consequence_engine.gd:741","guards":[["consequence_engine.gd",'ecology_delta-=(WorldSimulation.discovery.effect("pollution")+WorldSimulation.discovery.effect("water_pollution"))*industrial_activity*0.0009']]},
			{"steer":["ecology","Pollution control"],"per":-0.45,"src":"society_model.gd:727","guards":[["society_model.gd",'effect("water_pollution")*0.45']]}]},
	"fuel_demand":{"label":"Fuel needed","good":-1,
		"what":"The fire-hungry ways the people take up: firing pots and bricks, smoking, boiling water, sweat baths and glass. Less is better: every fire the people keep burns more fuel, the kept hearth, the smoking fires that preserve food, and the kilns and engines they install. Each 1 in 100 adds 1 in 100 of the usual fuel; burning dung or managing fuelwood takes some off.",
		"feeds":[
			{"chain":"fuel","src":"research_mechanics.gd fuel_factor_of; fire_practice.gd advance, food_system.gd _preserve, technology_operations.gd input_rate","guards":FUEL_GUARDS}]},
}

# --- Reading the table ----------------------------------------------------------

## Every key the table explains.
static func keys()->Array[String]:
	var result:Array[String]=[]
	for key:String in KEYS: result.append(key)
	return result

static func entry(key:String)->Dictionary:
	return KEYS.get(key,{})

## The effect's name as a player would say it; an unknown key is still words.
static func label(key:String)->String:
	var known:Dictionary=KEYS.get(key,{})
	if not known.is_empty(): return String(known.label)
	var words:=key.replace("_"," ").strip_edges()
	return words.left(1).to_upper()+words.substr(1)

## 1 when more of it is better, -1 when less is, 0 when mixed.
static func good(key:String)->int:
	var known:Dictionary=KEYS.get(key,{})
	if known.has("good"): return int(known.good)
	return -1 if key in Society.LOWER_IS_BETTER else 1

## Whether an amount helps (1), costs (-1) or neither (0).
static func tone(key:String,amount:float)->int:
	if is_zero_approx(amount): return 0
	return good(key)*(1 if amount>0.0 else -1)

static func is_inert(key:String)->bool:
	return bool((KEYS.get(key,{}) as Dictionary).get("inert",false))

## Keys nothing in the simulation reads.
static func inert_keys()->Array[String]:
	var result:Array[String]=[]
	for key:String in KEYS:
		if is_inert(key): result.append(key)
	return result

## Keys read only to guide which questions the lore keepers take up next.
static func steer_only_keys()->Array[String]:
	var result:Array[String]=[]
	for key:String in KEYS:
		if bool((KEYS[key] as Dictionary).get("steer_only",false)): result.append(key)
	return result

## The research line an effect belongs to (SocietyModel.EFFECT_LINE).
static func line(key:String)->String:
	return String(Society.EFFECT_LINE.get(key,"production"))

## Where the engine reads the key, for designers: [{src, guards}].
static func trace(key:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for feed:Dictionary in (KEYS.get(key,{}) as Dictionary).get("feeds",[]):
		if feed.has("capacity"): result.append({"src":"society_model.gd capacity_value (%s)" % String(feed.capacity),"guards":[]})
		else: result.append({"src":String(feed.get("src","")),"guards":(feed.get("guards",[]) as Array).duplicate(true)})
	return result

# --- Words and numbers ------------------------------------------------------------

## A signed effect amount as the discovery announcement shows it: "+1.2%".
static func percent(value:float)->String:
	var size:=absf(value)*100.0
	if size<0.0000001: return "0%"
	var sign:="+" if value>0.0 else "-"
	if size>=0.05: return "%s%s%%" % [sign,_trim("%.1f" % size)]
	if size>=0.005: return "%s%s%%" % [sign,"%.2f" % size]
	return sign+"<0.01%"

## A size without its sign: "12", "1.2", "0.12", "0.012", "<0.01".
static func number(value:float)->String:
	var size:=absf(value)
	if size>=9.95: return str(roundi(size))
	if size>=0.995: return _trim("%.1f" % size)
	if size>=0.0995: return "%.2f" % size
	if size>=0.00995: return "%.3f" % size
	return "<0.01"

static func _trim(text:String)->String:
	return text.trim_suffix(".0") if text.ends_with(".0") else text

## A whole number with thousands marked: "4,000".
static func thousands(value:float)->String:
	var digits:=str(roundi(absf(value)))
	var result:=""
	while digits.length()>3:
		result=","+digits.right(3)+result
		digits=digits.left(digits.length()-3)
	return ("-" if value<0.0 else "")+digits+result

## How widely a practice is used, in words: "taken up by 51 in 100".
static func adoption_words(level:float)->String:
	var share:=clampf(level,0.0,1.0)*100.0
	if share<0.5: return "hardly taken up yet"
	return "taken up by %d in 100" % roundi(share)

## What a practice needs besides being known (CivilianGoods.factor): its
## effects count only for the share of it these cover.
const MEANS:={"wound_cleaning":"water carried for washing wounds","clean_water":"water carried for it","kiln_control":"kiln heat",
	"lime_burning":"lime in store","lime_mortar":"a town built of masonry, kept in repair","latrine_siting":"the water and waste works",
	"protected_wellheads":"the water and waste works","rainwater_cisterns":"the water and waste works","water_settling_basins":"the water and waste works",
	"seed_selection":"a seed reserve and fields tended with it","animal_taming":"a living herd","pack_animals":"a living herd of pack animals",
	"domesticated_mounts":"a living herd of mounts","mounted_scouts":"mounts for the scouts","public_stores":"a staffed Public Stores",
	"framed_construction":"a Framed Hall in use"}

## How fully a known practice is carried out, in words: how widely it is taken
## up and, for one that needs tools, works or supplies, how much of it they cover.
static func usage_words(id:String)->String:
	var adoption:=clampf(float(WorldSimulation.state.discovery_adoption.get(id,FIRST_ADOPTION)),0.0,1.0)
	var words:=adoption_words(adoption)
	if not (Goods.FACTOR_SPECIAL.has(id) or Goods.TECHNIQUES.has(id)): return words
	var means:=clampf(Goods.factor(id),0.0,1.0)
	if means>=0.995: return words
	var need:=String(MEANS.get(id,"household goods kept in use" if Goods.TECHNIQUES.has(id) else "its tools and works"))
	return "%s, but it needs %s, which covers only %d in 100 of them" % [words,need,roundi(means*100.0)]

static func _unit_words(value:float,unit:String)->String:
	match unit:
		"pts": return "%s points of 100" % number(value*100.0)
		"day": return "%s in 100 a day" % number(value*100.0)
		"km": return "%s km" % number(value)
		"places": return "%s places" % number(value)
		"days": return "%s days" % number(value)
	return "%s%%" % number(value*100.0)

## "<quantity>: up about 1.2%" / "down about ..." / "no change now".
static func quantity(to:String,value:float,unit:String,cap:String="")->String:
	var text:="%s: %s" % [_upper(to),"no change now" if absf(value)<0.0000000001 else "%s about %s" % ["up" if value>0.0 else "down",_unit_words(value,unit)]]
	return text+(" (%s)" % cap if cap!="" else "")

static func _upper(text:String)->String:
	return text.left(1).to_upper()+text.substr(1)

static func _lower(text:String)->String:
	return text.left(1).to_lower()+text.substr(1)

# --- The engine's state, read once per frame ------------------------------------

static var _cache:Dictionary={}
static var _cache_key:Array=[]

## Readings shared by every explanation made in one frame of one day.
static func _frame()->Dictionary:
	var state=WorldSimulation.state
	var key:Array=[Engine.get_process_frames(),int(state.elapsed_days),state.known_discoveries.size()]
	if key!=_cache_key:
		_cache_key=key
		_cache={}
	return _cache

## Forget cached readings (after changing adoption or state inside one frame).
static func invalidate()->void:
	_cache_key=[]
	_cache={}

## One engine reading per frame: made by `make` the first time it is asked for.
static func _once(name:String,make:Callable)->Variant:
	var cache:=_frame()
	if not cache.has(name): cache[name]=make.call()
	return cache[name]

static func _model()->Object:
	return WorldSimulation.discovery.society_model if WorldSimulation.discovery!=null else null

## The inputs today's capacities were made from (SocietyModel.capacity_ledger).
static func _inputs()->Dictionary:
	var cache:=_frame()
	if not cache.has("inputs"):
		var model=_model()
		var today:Dictionary={}
		if model!=null: today=model._today.inputs
		cache["inputs"]=(today if not today.is_empty() else (model.capacity_inputs() if model!=null else {})).duplicate()
	return cache.inputs

static var _readers:Dictionary={}

## The capacities whose formula reads `key`, found by probing the one capacity
## formula at neutral inputs (as the capacity pages do).
static func capacity_readers(key:String)->Array[String]:
	if _readers.is_empty():
		var inputs:Dictionary={"able":0.3,"health":0.3,"food":0.3,"housing":0.3,"cohesion":0.3,"ecology":0.3,"security":0.3,"legitimacy":0.3,
			"diet":0.3,"materials":0.3,"hauling":0.3,"learning":0.3,"keepers":0.3,"attention":0.6,"overwork":0.1,"fields":6.0,"stewards":0.3,"works":3.0,"treasures":0.0}
		for effect_id:String in Society.CAPACITY_EFFECTS: inputs["fx:"+effect_id]=0.1
		for effect_id:String in Society.CAPACITY_EFFECTS:
			var readers:Array[String]=[]
			for dynamic_id:String in Society.DYNAMICS:
				var base:=Society.capacity_value(dynamic_id,inputs)
				inputs["fx:"+effect_id]=0.12
				if absf(Society.capacity_value(dynamic_id,inputs)-base)>0.0000001: readers.append(dynamic_id)
				inputs["fx:"+effect_id]=0.1
			_readers[effect_id]=readers
	var found:Array[String]=[]
	found.assign(_readers.get(key,[]))
	return found

## How many points (0..1) one unit of `key` moves a capacity today: measured
## on SocietyModel.capacity_value at today's inputs, with its clamps.
static func capacity_slope(key:String,dynamic_id:String)->float:
	var cache:=_frame()
	var slopes:Dictionary=cache.get_or_add("slopes",{})
	var slot:="%s|%s" % [key,dynamic_id]
	if slopes.has(slot): return float(slopes[slot])
	var inputs:=_inputs()
	var fx:="fx:"+key
	var slope:=0.0
	if not inputs.is_empty():
		var before:=float(inputs.get(fx,0.0))
		var base:=Society.capacity_value(dynamic_id,inputs)
		inputs[fx]=before+SLOPE_STEP
		var raised:=Society.capacity_value(dynamic_id,inputs)
		inputs[fx]=before
		slope=(raised-base)/SLOPE_STEP
	slopes[slot]=slope
	return slope

# --- What one amount of an effect moves -----------------------------------------

## Everything the explanation of one effect needs. `amount` is the effect's own
## size, `adoption` how widely it is practiced (0..1), `scale` the research
## focus on its line (SocietyModel.practice_scale; costs are never scaled).
## Returns {key, label, amount_words, sentence, now, now_words, feeds, inert,
## steer_only, good, tone, held}.
static func describe(key:String,amount:float,adoption:float=1.0,scale:float=1.0)->Dictionary:
	var known:Dictionary=KEYS.get(key,{})
	var now:=Society.scaled_effect(key,amount,scale)*clampf(adoption,0.0,1.0)
	var inert:=is_inert(key) or known.is_empty()
	var feeds:Array[String]=[]
	if not inert:
		for feed:Dictionary in known.get("feeds",[]):
			var text:=_feed_line(key,feed,now)
			if text!="": feeds.append(text)
	var now_words:=""
	if inert: now_words="No effect in the simulation yet: nothing in the engine reads it."
	elif bool(known.get("steer_only",false)): now_words="%s now → changes nothing people live with; it only guides which %s questions are taken up next." % [percent(now),String(FIELD_WORDS.get(line(key),"land"))]
	elif feeds.is_empty(): now_words="%s now" % percent(now)
	else: now_words="%s now → %s" % [percent(now),_lower(feeds[0])]
	return {"key":key,"label":label(key),"amount_words":percent(amount),"sentence":String(known.get("what","Nothing in the simulation reads this effect yet.")),
		"now":now,"now_words":now_words,"feeds":feeds,"inert":inert,"steer_only":bool(known.get("steer_only",false)),
		"good":good(key),"tone":tone(key,now if not is_zero_approx(now) else amount),"held":held_words(key,amount)}

## Why an amount adds nothing more: the key's total already fills what the
## society's age allows (SocietyModel.era_ceiling), "" otherwise.
static func held_words(key:String,amount:float)->String:
	var model=_model()
	if model==null or is_inert(key) or is_zero_approx(amount): return ""
	var ceiling:Vector2=model.era_ceiling(key)
	var total:=float(model.effect(key))
	var lower:=key in Society.LOWER_IS_BETTER
	var pushing:=(amount<0.0) if lower else (amount>0.0)
	if not pushing: return ""
	var full:=(total<=ceiling.x+0.000001) if lower else (total>=ceiling.y-0.000001)
	if not full: return ""
	var limit:=ceiling.x if lower else ceiling.y
	if absf(limit)<0.0000001: return "Held back by our age: this age allows none of it yet, so it adds nothing until a later age opens room for it."
	return "Held back by our age: what the people know already fills all this age allows (%s), so this adds nothing more until a later age opens more room. Scale bonuses for the same thing share that limit." % percent(limit)

static func _feed_line(key:String,feed:Dictionary,now:float)->String:
	if feed.has("capacity"): return _capacity_line(key,String(feed.capacity),now)
	if feed.has("cover"): return _cover_line(key,String(feed.cover),now)
	if feed.has("relief"): return _relief_line(key)
	if feed.has("epidemic"): return _epidemic_line(float(feed.epidemic),now)
	if feed.has("steer"): return _steer_line(feed)
	if feed.has("eras"): return "Counts toward the building know-how the town needs to reach %s." % String(feed.eras)
	if feed.has("chain"): return _chain_line(key,feed,now)
	if feed.has("text"): return String(feed.text)
	return quantity(String(feed.get("to","")),now*float(feed.get("per",1.0)),String(feed.get("unit","pct")),String(feed.get("cap","")))

static func _capacity_line(key:String,dynamic_id:String,now:float)->String:
	var value:=float(WorldSimulation.state.society_capacities.get(dynamic_id,0.0))
	var slope:=capacity_slope(key,dynamic_id)
	var name:="The %s capacity (%d of 100 now)" % [dynamic_id.capitalize(),roundi(clampf(value,0.0,1.0)*100.0)]
	if is_zero_approx(slope) and not is_zero_approx(now): return "%s: held at its limit today, so no change; %s." % [name,String(CAPACITY_USES.get(dynamic_id,""))]
	return "%s; %s." % [quantity(name,now*slope,"pts"),String(CAPACITY_USES.get(dynamic_id,""))]

## The early care category a key counts toward (EarlyLifeConditions.CATEGORIES).
static func _care(category_id:String)->Dictionary:
	for category:Dictionary in EarlyCare.CATEGORIES:
		if String(category.id)==category_id: return category
	return {}

static func _cover_line(key:String,category_id:String,now:float)->String:
	var category:=_care(category_id)
	var channels:Dictionary=category.get("channels",{})
	if not channels.has(key): return ""
	var scale:=float(channels[key])
	var covered:=0.0
	for row:Variant in (WorldSimulation.state.early_care as Dictionary).get("categories",[]):
		if row is Dictionary and String((row as Dictionary).get("id",""))==category_id: covered=float((row as Dictionary).get("coverage",0.0))
	var name:="%s counted as covered (%d of 100 now)" % [String(category.get("label","Care")),roundi(clampf(covered,0.0,1.0)*100.0)]
	var full:="every %s in 100 of it covers this care fully" % number(absf(scale)*100.0)
	if scale<0.0: full="only cuts count; every %s in 100 cut covers it fully" % number(absf(scale)*100.0)
	return quantity(name,now/scale,"pts","%s, unless its named practices cover more; care that is missing costs the lives of infants, children and mothers" % full)

static func _relief_line(key:String)->String:
	var scale:=float(EarlyCare.RELIEF_CHANNELS.get(key,0.0))
	if is_zero_approx(scale): return ""
	var relief:=float((WorldSimulation.state.early_care as Dictionary).get("burden_relief",0.0))
	return "One of four measures (with the other health knowledge) that lift the old burden of disease no single practice removes; each counts up to %s in 100, and the lift grows slowly at first (lifted %d in 100 now)." % [number(absf(scale)*100.0),roundi(clampf(relief,0.0,1.0)*100.0)]

static func _epidemic_line(per:float,now:float)->String:
	var usable:float=_once("medicine",func()->float:
		var crisis=load("res://scripts/crisis_system.gd")
		return float(crisis._ramp(crisis.MEDICINE_CEILING,crisis.hist_year())) if crisis!=null else 0.35)
	return quantity("Health knowledge used against epidemics",now*per,"pts","outbreaks start less often and kill fewer; the medicine of this age can use %d in 100 of it" % roundi(usable*100.0))

static func _steer_line(feed:Dictionary)->String:
	var steer:Array=feed.steer
	var field:=String(steer[0])
	return "Guides research: counts %s of itself in the %s reading \"%s\", which only steers which %s questions the lore keepers take up next." % [number(absf(float(feed.get("per",1.0)))),field.capitalize(),String(steer[1]),String(FIELD_WORDS.get(field,field))]

## Readings that pass through another engine value before they reach people.
static func _chain_line(key:String,feed:Dictionary,now:float)->String:
	var state=WorldSimulation.state
	match String(feed.chain):
		"labor":
			# Labor capacity -> every hand's daily output (ConsequenceEngine).
			var labor:=clampf(float(state.society_capacities.get("labor",0.5)),0.0,1.0)
			var moved:=now*capacity_slope(key,"labor")
			var after:=clampf(labor+moved,0.0,1.0)
			return quantity("Every hand's daily output, through the Labor capacity",lerpf(0.82,1.08,after)/lerpf(0.82,1.08,labor)-1.0,"pct","the capacity sets output from 82 in 100 at nothing to 108 at full")
		"discovery":
			var multiplier:float=_once("discovery_pace",func()->float:
				var engine=WorldSimulation.consequences
				return float(engine.discovery_multiplier()) if engine!=null and bool(engine.get("initialized")) else 1.0)
			return quantity("The pace of every research question",now*float(feed.get("per",0.2))/maxf(0.35,multiplier),"pct","the research pace multiplier stays between 0.35 and 1.65")
		"spread":
			var factor:float=_once("spread",func()->float:
				var others:=float(state.founding_effect("adoption_rate"))+float(WorldSimulation.progression.effect("adoption_rate"))
				var total:=float(_model().effect("adoption_rate")) if _model()!=null else 0.0
				return 1.0+clampf(total+others,-0.35,0.80))
			return quantity("How fast every known practice spreads",now/maxf(0.1,factor),"pct","added to founding customs and the people's scale, held between -35% and +80%")
		"forget":
			var loss:float=_once("forgetting",func()->float:
				var remembered:=clampf(float(state.simulation_metrics.get("knowledge",0.18))+float(_model().effect("knowledge_preservation") if _model()!=null else 0.0),0.05,1.2)
				return maxf(0.0,0.00018-remembered*0.00015))
			if loss<=0.0: return "Practices nobody uses: nothing is being forgotten now, because what the people remember is already enough to keep them."
			return quantity("How fast practices nobody uses are forgotten",maxf(-1.0,-0.00015*now/loss),"pct","forgetting stops once remembered knowledge and this reach 1.2 together")
		"education":
			var education:float=_once("education",func()->float: return float(preload("res://scripts/civilization_indicators.gd").education_index()))
			var moved:=now*float(feed.get("per",0.0))
			var pace:=lerpf(0.55,1.45,clampf(education+moved,0.0,1.0))/lerpf(0.55,1.45,education)-1.0
			return "%s, so every research line moves %s." % [quantity("How well learning is taught",moved,"pts"),("about %s%% %s" % [number(absf(pace)*100.0),"faster" if pace>=0.0 else "slower"]) if absf(pace)>0.0000000001 else "at the same pace"]
		"industry_health":
			var industry:=_industry()
			if industry<=0.0: return "The health the people settle toward: no change while nothing is mined or quarried (it counts in proportion to mining and quarrying)."
			# Control of chemicals prevents part of the harm of smoke and fouled
			# water (consequence_engine.gd chemical_cut); dust and dangerous work are not cut.
			var kept:float=_chemical_kept(false) if key in ["pollution","water_pollution"] else 1.0
			return quantity("The health the people settle toward, at today's mining and quarrying",now*float(feed.get("per",-1.0))*industry*kept,"pts",_chemical_note(kept))
		"industry_land":
			var industry:=_industry()
			if industry<=0.0: return "The health of the land: no change while nothing is mined or quarried (it counts in proportion to mining and quarrying)."
			var kept:float=_chemical_kept(true)
			return quantity("The health of the land each year, at today's mining and quarrying",-now*industry*0.0009*365.0*kept,"pts",_chemical_note(kept))
		"chemical_health","chemical_land":
			# The harm control of chemicals prevents (consequence_engine.gd): smoke
			# and fouled water, in proportion to mining and quarrying, only when harmful.
			var land:=String(feed.chain)=="chemical_land"
			var name:="The health of the land each year" if land else "The health the people settle toward"
			var industry:=_industry()
			if industry<=0.0: return "%s: no change while nothing is mined or quarried (smoke and fouled water harm in proportion to mining and quarrying)." % name
			var harm:=_chemical_harm(land)
			if harm<=0.0: return "%s: no change now; on balance the people's ways foul nothing, so there is no harm to prevent." % name
			var cut:=_chemical_cut()
			if cut>=Mechanics.CHEMICAL_HARM_CUT_LIMIT-0.000001 and now>0.0: return "%s: no more is prevented; control of chemicals already prevents the most it can, %d in 100 of the harm." % [name,roundi(Mechanics.CHEMICAL_HARM_CUT_LIMIT*100.0)]
			var per:float=harm*industry*(0.0009*365.0 if land else 1.0)
			return quantity("%s, at today's mining and quarrying" % name,now*Mechanics.CHEMICAL_HARM_CUT*per,"pts","today %d in 100 of the harm from smoke and fouled water is prevented" % roundi(cut*100.0))
		"water_today":
			# Today's walk to water and what it buys (resource_system.gd _process_water_flow).
			var water:Dictionary=state.water_metrics
			var km:=float(water.get("source_distance_km",-1.0))
			if km<0.0 or not bool(water.get("source_accessible",false)): return "Today no water source is within reach, so a shorter walk changes nothing yet."
			var total:=float(_model().effect("water_access")) if _model()!=null else 0.0
			var walk:float=km*Mechanics.water_walk_factor_of(total)
			var resources=WorldSimulation.resources
			if resources==null: return ""
			var fetched:=float(resources._household_surface_water_access_ratio(walk))
			var bare:=float(resources._household_surface_water_access_ratio(km))
			var carried:=maxf(1.0,1.0+km*0.16)/maxf(1.0,1.0+walk*0.16)-1.0
			var carriers:="carriers bring in as much as at the full walk" if absf(carried)<0.0005 else "carriers bring in about %s%% %s a day than at the full walk" % [number(absf(carried)*100.0),"more" if carried>0.0 else "less"]
			return "Today the nearest source is %s km away and counts as %s km of walking: households can fetch %d in 100 of the water they need themselves (%d in 100 at the full walk), and %s." % [number(km),number(walk),roundi(fetched*100.0),roundi(bare*100.0),carriers]
		"fuel":
			# One factor on every fire (research_mechanics.gd fuel_factor_of),
			# counted against the usual fuel: exact for any amount.
			var model=_model()
			var economy:=float(model.effect("fuel_efficiency")) if model!=null else 0.0
			var demand:=float(model.effect("fuel_demand")) if model!=null else 0.0
			var e:=clampf(economy,Mechanics.FUEL_ECONOMY_LIMITS.x,Mechanics.FUEL_ECONOMY_LIMITS.y)
			var d:=clampf(demand,Mechanics.FUEL_DEMAND_LIMITS.x,Mechanics.FUEL_DEMAND_LIMITS.y)
			var moved:float=-Mechanics.FUEL_ECONOMY_SAVING*now*(1.0+Mechanics.FUEL_DEMAND_COST*d) if key=="fuel_efficiency" else Mechanics.FUEL_DEMAND_COST*now*(1.0-Mechanics.FUEL_ECONOMY_SAVING*e)
			var today:float=Mechanics.fuel_factor_of(economy,demand)
			return quantity("Fuel burned by every fire the people keep (the hearth, the smoking fires that preserve food, kilns and engines)",moved,"pct","counted against the usual amount; today every fire burns %d in 100 of it" % roundi(today*100.0))
		"repair_today":
			var total:=float(_model().effect("repair_capacity")) if _model()!=null else 0.0
			var wear:float=Goods.DAILY_WEAR*Mechanics.goods_wear_factor_of(total)
			var mending:float=Mechanics.mending_factor_of(total)
			var further:="as far as usual"
			if mending>1.0005: further="%s%% further than usual" % number((mending-1.0)*100.0)
			elif mending<0.9995: further="%s%% less far than usual" % number((1.0-mending)*100.0)
			return "Today household goods wear out at %s in 100 of the stock a day (%s without repair skill), and each month's mending of the town goes %s." % [number(wear*100.0),number(Goods.DAILY_WEAR*100.0),further]
		"mines":
			var names:Array=_once("mines",func()->Array:
				var found:Array[String]=[]
				var resources=WorldSimulation.resources
				if resources==null: return found
				for deposit_variant:Variant in state.resource_deposits:
					var deposit:Dictionary=deposit_variant
					var resource:=String(deposit.get("resource",""))
					if String(deposit.get("stage","")) not in ["accessible","developed"] or float(deposit.get("extracted_today",0.0))<=0.0: continue
					if not Mechanics.is_mined((resources.catalog as Dictionary).get(resource,{}),resources.material_profile(resource)): continue
					var label:=String(resources.display_name(resource))
					if not label in found: found.append(label)
				return found)
			if names.is_empty(): return "No mined deposit is worked now, so this changes nothing yet."
			return "Mined deposits worked now: %s." % ", ".join(PackedStringArray(names))
		"supply_reach":
			# How far half a load still gets today (supply_state.gd reach_effort).
			var supply=load("res://scripts/supply_state.gd")
			var who:=String(supply.carrier())
			var endurance:=float(supply.endurance_today())
			var carriers:=String((supply.CARRIERS.get(who,supply.CARRIERS.foot) as Dictionary).words)
			var reach:=float(supply.reach_effort(who,float(supply.REACH_HAUL),endurance))
			var bare:=float(supply.reach_effort(who,float(supply.REACH_HAUL),0.0))
			return "Today our %s eat %s in 100 of a load for each day of hauling, so half a load still reaches a band about %s km away over open, level ground in mild weather (%s km without supply endurance)." % [carriers,number(float(supply.carrier_loss(who,endurance))*100.0),str(roundi(reach)),str(roundi(bare))]
		"sea_fishing","sea_catch":
			var food=WorldSimulation.food
			var coastal:Dictionary=food._coastal_food_profile(false) if food!=null else {}
			var shoreline:=float(coastal.get("shoreline_access",0.0))
			var marine:=float(coastal.get("marine_opportunity",0.0))
			var catch_line:=String(feed.chain)=="sea_catch"
			if shoreline<=0.0 and marine<=0.0: return "%s: no change; the people's home is not on the sea coast." % ("Each fisher's catch" if catch_line else "The fishing grounds")
			var total:=float(_model().effect("naval_capacity")) if _model()!=null else 0.0
			var reach:float=Mechanics.sea_reach_of(total)
			var worked:="the sea coast is worked as far out as usual" if absf(reach-1.0)<0.0005 else "the sea coast is worked %s%% %s out than usual" % [number(absf(reach-1.0)*100.0),"farther" if reach>1.0 else "less far"]
			if catch_line:
				# food_system.gd _produce: each fisher lands (0.76 + access x 0.34) of
				# a full catch; the sea counts while it beats fresh water, up to 1.
				var fresh:=float((food._food_resource_access() as Dictionary).get("freshwater",0.0))
				var access:float=Mechanics.fishing_access_of(fresh,marine,reach)
				var sea:=marine*0.90*reach
				var slope:float=marine*0.90*Mechanics.SEA_REACH_GAIN*0.34/(0.76+access*0.34) if sea>fresh and sea<1.0 else 0.0
				return quantity("Each fisher's catch, at the people's coast",now*slope,"pct","the sea counts while it beats fresh water, up to full reach; "+worked)
			var environment:Dictionary=food.current_environment_profile()
			var water:=maxf(clampf(float(environment.get("water_access",0.0)),0.0,1.0),marine)
			var grounds:float=Mechanics.fishing_ground_of(water,shoreline,reach)
			return quantity("Fish the fishing grounds give each day, at the people's coast",shoreline*40.0*Mechanics.SEA_REACH_GAIN*now/maxf(1.0,grounds),"pct",worked)
		"sea_crossing":
			var world=WorldSimulation.world
			var today:=float(world._scout_water_crossing_allowance_km()) if world!=null else 0.0
			if today<=0.0: return "Open water a scouting party can cross: no change until the people have river or coastal craft in use."
			var total:=float(_model().effect("naval_capacity")) if _model()!=null else 0.0
			var craft:float=today/maxf(0.1,Mechanics.sea_reach_of(total))
			return quantity("Open water a scouting party's craft can cross in one stretch",craft*Mechanics.SEA_REACH_GAIN*now,"km","%s km today; coastal craft cross 40 km and river craft 10 before seafaring skill" % str(roundi(today)))
		"storage":
			# Added to each material's own daily loss (ResourceSystem profiles); a
			# loss never falls below none, so past the largest of them it stops all loss.
			var rates:Array=_once("storage_rates",func()->Array:
				var resources=load("res://scripts/resource_system.gd")
				var found:Array=[float(resources.ORE_PROFILE.loss),float(resources.MINERAL_PROFILE.loss)]
				for profile:Variant in (resources.MATERIAL_PROFILES as Dictionary).values(): found.append(float((profile as Dictionary).loss))
				return found)
			var total:=float(_model().effect("storage_loss")) if _model()!=null else 0.0
			var line:=quantity("Stored materials lost each day",now,"day","added to each material's own loss of %s to %s in 100 a day; a loss never falls below none" % [number(rates.min()*100.0),number(rates.max()*100.0)])
			if total<=-float(rates.max()): line+=". The people's total already cuts %s in 100 a day, which stops every material's loss, so more of it changes nothing now" % number(total*100.0)
			return line
		"lean_to":
			var places:float=_once("lean_to",func()->float: return float(load("res://scripts/settlement_construction.gd").LEAN_TO_PLACES))
			var built:bool="Lean-to Shelters" in state.settlement_completed
			# Every later batch of homes holds as much more (settlement_construction.gd housing_batch_places).
			var batch:=float(maxi(24,roundi(float(state.population_total)*0.12)))
			if built: return quantity("Places in each new batch of homes",now*batch,"places","%s places a batch before this; the Lean-to Shelters already stand" % str(roundi(batch)))
			return quantity("Places in the Lean-to Shelters and each later batch of homes",now*places,"places","%s places in the Lean-tos before this, counted when they are finished; each later batch of %s homes holds as much more" % [str(roundi(places)),str(roundi(batch))])
	return ""

## Today's mining and quarrying against the people's size, 0..2 (ConsequenceEngine).
static func _industry()->float:
	var state=WorldSimulation.state
	return clampf(float(state.material_metrics.get("extracted_today",0.0))/maxf(1.0,float(state.population_exact)*0.08),0.0,2.0)

## Today's share of the harm from smoke and fouled water that control of
## chemicals prevents (research_mechanics.gd chemical_harm_cut_of).
static func _chemical_cut()->float:
	var model=_model()
	var control:=float(model.effect("chemical_control")) if model!=null else 0.0
	return float(Mechanics.chemical_harm_cut_of(control))

## Today's harm from smoke and fouled water per unit of mining and quarrying,
## as ConsequenceEngine weighs it for health or for the land; 0 when the
## people's ways foul nothing on balance.
static func _chemical_harm(land:bool)->float:
	var model=_model()
	if model==null: return 0.0
	var smoke:=float(model.effect("pollution"))
	var fouled:=float(model.effect("water_pollution"))
	return maxf(0.0,smoke+fouled) if land else maxf(0.0,smoke*0.22+fouled*0.18)

## The share of that harm still suffered today.
static func _chemical_kept(land:bool)->float:
	return 1.0-_chemical_cut() if _chemical_harm(land)>0.0 else 1.0

static func _chemical_note(kept:float)->String:
	return "" if kept>0.9995 else "control of chemicals prevents %d in 100 of this harm today" % roundi((1.0-kept)*100.0)

# --- What the people's knowledge adds up to ---------------------------------------

## How fully a known practice is carried out: its adoption, times the goods or
## works it needs (the same level SocietyModel._practice_level uses).
static func practice_level(id:String)->float:
	var level:=clampf(float(WorldSimulation.state.discovery_adoption.get(id,FIRST_ADOPTION)),0.0,1.0)
	# A question in trial use before proof counts at its trial share.
	var trial:=Research600.trial_share(float(WorldSimulation.state.discovery_progress.get(id,0.0)))
	if trial>0.0 and not WorldSimulation.state.known_discoveries.has(id): level=trial
	if Goods.FACTOR_SPECIAL.has(id) or Goods.TECHNIQUES.has(id): level*=Goods.factor(id)
	return level

## The research-focus scale of a line (SocietyModel.practice_scale).
static func focus_scale(line_id:String)->float:
	var cache:=_frame()
	var scales:Dictionary=cache.get_or_add("scales",{})
	if scales.has(line_id): return float(scales[line_id])
	var model=_model()
	var scale:=1.0
	if model!=null: scale=Society.practice_scale(line_id,model.line_focus,Society.neglect_for(model.line_focus))
	scales[line_id]=scale
	return scale

## What one known practice adds to one total now, before the era's ceiling.
static func contribution(id:String,key:String)->float:
	var definition:Dictionary=WorldSimulation.discovery.discovery_definition(id)
	var effects:Dictionary=definition.get("effects",{})
	if not effects.has(key): return 0.0
	return Society.scaled_effect(key,float(effects[key]),focus_scale(String(definition.get("dynamic",""))))*practice_level(id)

## Every total as the engine sums it before the era's ceiling, with what each
## known practice adds: {key: {"sum": x, "by": {id: amount}}}.
static func raw_totals()->Dictionary:
	var cache:=_frame()
	if cache.has("raw"): return cache.raw
	var result:Dictionary={}
	var fields:Dictionary={}
	# Everything known, and the questions in trial use before proof.
	var practices:Array=WorldSimulation.state.known_discoveries.duplicate()
	practices.append_array(Research600.trial_levels(WorldSimulation.state.discovery_progress,WorldSimulation.state.known_discoveries).keys())
	for id_variant in practices:
		var id:=String(id_variant)
		var definition:Dictionary=WorldSimulation.discovery.discovery_definition(id)
		var effects:Dictionary=definition.get("effects",{})
		if effects.is_empty(): continue
		var level:=practice_level(id)
		var field:=String(definition.get("dynamic",""))
		var scale:=focus_scale(field)
		var by_field:Dictionary=fields.get_or_add(field,{})
		for key_variant in effects:
			var key:=String(key_variant)
			var amount:=Society.scaled_effect(key,float(effects[key_variant]),scale)*level
			var slot:Dictionary=result.get_or_add(key,{"sum":0.0,"by":{}})
			slot["sum"]=float(slot.sum)+amount
			(slot.by as Dictionary)[id]=float((slot.by as Dictionary).get(id,0.0))+amount
			by_field[key]=float(by_field.get(key,0.0))+amount
	cache["raw"]=result
	cache["fields"]=fields
	return result

## Each effect's current total from everything the people know, translated
## like describe(), with the era ceiling, what it holds back, the lore keepers'
## upkeep and the practices that add most. Sorted by research line, largest first.
static func totals()->Array[Dictionary]:
	var cache:=_frame()
	if cache.has("totals"): return cache.totals
	var model=_model()
	var raw:=raw_totals()
	var ids:Dictionary={}
	for key:String in raw: ids[key]=true
	if model!=null:
		for key:String in model.effect_totals: ids[key]=true
	var rows:Array[Dictionary]=[]
	for key:String in ids:
		var total:=float(model.effect(key)) if model!=null else float((raw.get(key,{}) as Dictionary).get("sum",0.0))
		var slot:Dictionary=raw.get(key,{"sum":0.0,"by":{}})
		var ceiling:Vector2=model.era_ceiling(key) if model!=null else Vector2(-INF,INF)
		var sum:=float(slot.sum)
		var capped:=clampf(sum,ceiling.x,ceiling.y)
		var upkeep:=float(model.upkeep_of(key)) if model!=null else 0.0
		var row:=describe(key,total,1.0)
		row["total"]=total
		row["raw"]=sum
		row["ceiling"]=ceiling
		row["held_back"]=sum-capped
		row["upkeep"]=upkeep
		row["line"]=line(key)
		row["contributors"]=_contributors(slot.by)
		row["notes"]=_total_notes(key,sum,capped,ceiling,upkeep)
		rows.append(row)
	var order:=Society.DYNAMICS
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var first:=order.find(String(a.line));var second:=order.find(String(b.line))
		if first!=second: return first<second
		return absf(float(a.total))>absf(float(b.total)))
	cache["totals"]=rows
	return rows

## Plain notes on a total: held back by the age, and the keepers' upkeep.
static func _total_notes(key:String,sum:float,capped:float,ceiling:Vector2,upkeep:float)->Array[String]:
	var notes:Array[String]=[]
	if absf(sum-capped)>0.000001:
		var limit:=ceiling.x if sum<ceiling.x else ceiling.y
		notes.append("Held back by our age: everything known adds up to %s, but this age allows %s; the rest (%s) counts only as later ages open. Scale bonuses for the same thing share this limit." % [percent(sum),percent(limit),percent(sum-capped)])
	if absf(upkeep)>0.000001:
		notes.append("Feeding more full-time lore keepers, or keeping more on watch, than this age can spare moves it by %s." % percent(upkeep))
	return notes

static func _contributors(by:Dictionary,limit:int=5)->Array[Dictionary]:
	var ids:Array=by.keys().filter(func(id:Variant)->bool: return absf(float(by[id]))>0.0000000001)
	ids.sort_custom(func(a:Variant,b:Variant)->bool: return absf(float(by[a]))>absf(float(by[b])))
	var result:Array[Dictionary]=[]
	for index in mini(limit,ids.size()):
		var id:=String(ids[index])
		result.append({"id":id,"name":String(WorldSimulation.discovery.discovery_definition(id).get("name",label(id))),"amount":float(by[ids[index]])})
	return result

## What one field's known practices add to each total now (before ceilings).
static func field_totals(domain:String)->Dictionary:
	raw_totals()
	return ((_frame().get("fields",{}) as Dictionary).get(domain,{}) as Dictionary).duplicate()

# --- Rows for the research pages --------------------------------------------------

## One ledger row (hud/impact_ledger.gd) for an effect: `amount` at full use,
## now at `level`, focus `scale`. mode "now" (a known practice), "would" (a
## question not yet answered, shown at full use) or "total" (everything known).
## `usage`, when given, says how widely the practice is carried out.
static func ledger_row(key:String,amount:float,level:float=1.0,scale:float=1.0,mode:String="now",usage_said:String="")->Dictionary:
	var said:=describe(key,amount,level if mode=="now" else 1.0,scale)
	var usage:=""
	match mode:
		"now": usage="%s now, %s" % [percent(float(said.now)),usage_said if usage_said!="" else adoption_words(level)]
		"would": usage="at full use; it starts with about %d in 100 households and spreads over years" % roundi(Research600.PROOF_ADOPTION*100.0)
		_: usage="in all, from everything known"
	var tone_name:String="inert" if bool(said.inert) else ("steer" if bool(said.steer_only) else String(["cost","neutral","good"][int(said.tone)+1]))
	var notes:Array[String]=[]
	if String(said.held)!="": notes.append(String(said.held))
	return {"id":key,"key":key,"label":String(said.label),"amount":String(said.amount_words),"usage":usage,
		"headline":_upper(meaning(said)),
		"sentence":String(said.sentence),"feeds":said.feeds,"notes":notes,"tone":tone_name,"inert":bool(said.inert),
		"direction":"More is better." if good(key)>0 else ("Less is better." if good(key)<0 else "Neither good nor bad in itself.")}

## Rows for one discovery's effects: now (known) or at full use (not yet).
static func discovery_rows(id:String,known:bool=true)->Array[Dictionary]:
	var definition:Dictionary=WorldSimulation.discovery.discovery_definition(id)
	var effects:Dictionary=definition.get("effects",{})
	var level:=practice_level(id) if known else 1.0
	var scale:=focus_scale(String(definition.get("dynamic",""))) if known else 1.0
	var usage:=usage_words(id) if known else ""
	var rows:Array[Dictionary]=[]
	for key_variant in effects:
		var row:=ledger_row(String(key_variant),float(effects[key_variant]),level,scale,"now" if known else "would",usage)
		row["id"]="%s:%s" % [id,String(key_variant)]
		rows.append(row)
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return absf(float((effects as Dictionary).get(a.key,0.0)))>absf(float((effects as Dictionary).get(b.key,0.0))))
	return rows

## The totals as ledger rows, with their notes and main sources.
static func total_rows()->Array[Dictionary]:
	var rows:Array[Dictionary]=[]
	for total:Dictionary in totals():
		if is_zero_approx(float(total.total)) and is_zero_approx(float(total.raw)): continue
		var row:=ledger_row(String(total.key),float(total.total),1.0,1.0,"total")
		(row.notes as Array).append_array(total.notes)
		var sources:Array[String]=[]
		for source:Dictionary in total.contributors: sources.append("%s %s" % [String(source.name),percent(float(source.amount))])
		if not sources.is_empty(): (row.notes as Array).append("Most of it comes from: %s." % ", ".join(sources))
		row["line"]=String(total.line)
		row["total"]=float(total.total)
		rows.append(row)
	return rows

## "Protection from sickness, safe drinking water and 2 more", for one-line summaries.
static func summary(effects:Dictionary,limit:int=3)->String:
	var keys_by_size:Array=effects.keys()
	keys_by_size.sort_custom(func(a:Variant,b:Variant)->bool: return absf(float(effects[a]))>absf(float(effects[b])))
	var names:Array[String]=[]
	for index in mini(limit,keys_by_size.size()): names.append(_lower(label(String(keys_by_size[index]))) if index>0 else label(String(keys_by_size[index])))
	if names.is_empty(): return ""
	var rest:=keys_by_size.size()-names.size()
	if rest>0: return "%s and %d more" % [", ".join(names),rest]
	if names.size()==1: return names[0]
	return "%s and %s" % [", ".join(names.slice(0,names.size()-1)),names[-1]]

## What an explained effect moves first, without its amount: the part of
## now_words after the arrow ("the health the people settle toward: up ...").
static func meaning(said:Dictionary)->String:
	var words:=String(said.get("now_words",""))
	return words.get_slice(" → ",1) if " → " in words else words

## Short lines for a long list's tooltip: each effect's name, size and what it
## adds now; the full account is one click away (ledger rows).
static func amount_lines(effects:Dictionary,level:float=1.0,scale:float=1.0,known:bool=true)->String:
	if effects.is_empty(): return "Changes nothing by itself; it opens the way to later knowledge."
	var lines:Array[String]=[]
	for key_variant in effects:
		var key:=String(key_variant)
		var amount:=float(effects[key_variant])
		var tail:=", now %s" % percent(Society.scaled_effect(key,amount,scale)*level) if known else " at full use"
		lines.append("%s %s%s%s" % [label(key),percent(amount),tail," (nothing reads it yet)" if is_inert(key) else ""])
	return "\n".join(lines)

## Plain lines for a text slot or tooltip: one per effect, with its first use;
## `usage` (usage_words) first when given.
static func effect_lines(effects:Dictionary,level:float=1.0,scale:float=1.0,known:bool=true,usage:String="")->String:
	if effects.is_empty(): return "Changes nothing by itself; it opens the way to later knowledge."
	var lines:Array[String]=[]
	if usage!="": lines.append("In use: %s." % usage)
	for key_variant in effects:
		var key:=String(key_variant)
		var said:=describe(key,float(effects[key_variant]),level if known else 1.0,scale)
		lines.append("%s %s%s → %s" % [String(said.label),String(said.amount_words),", now %s" % percent(float(said.now)) if known else " at full use",meaning(said)])
	return "\n".join(lines)
