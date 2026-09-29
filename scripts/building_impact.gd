extends RefCounted
## WHAT EACH BUILDING DOES, IN NUMBERS: the Buildings page's explanations
## (hud/content/dock_content_construction.gd), computed from the rule the
## engine applies, named beside each line, so the page says what happens:
##   homes         consequence_engine.gd (work pace, health, cohesion,
##                 exposure), game_state.gd (deaths, births, childbirth),
##                 crisis_system.gd (how often sickness and fire break out),
##                 society_exchange.gd (room for newcomers)
##   stores        food_system.gd (spoilage, room), resource_system.gd (store
##                 room, water vessels), early_life_conditions.gd (children)
##   work area     consequence_engine.gd (tools and materials)
##   hall, shrines, yard   civic_building_effects.gd (one table the engine reads)
##   defences      military_campaign.gd settlement_defense_snapshot()
## A line: {label, value, words, tone ("good" | "bad" | "plain")}. value is
## short ("+12%", "×0.88"); words say what it means in this town today.

const CIVIC:=preload("res://scripts/civic_building_effects.gd")
const Construction:=preload("res://scripts/settlement_construction.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")

## Homes' reference points (the engine's own): the crowding at which sickness
## and fire are at their base rate (crisis_system.gd CROWD_REF).
const CROWD_REF:=0.55
## Storage Pits: spoilage multiplier and rations of room a person
## (food_system.gd _spoilage_rates, _food_storage_capacity).
const PITS_SPOILAGE:=0.72
const PITS_RATIONS:=84.0
const STORES_RATIONS:=120.0
## The Hearth Circle and Lean-to Shelters' health (consequence_engine.gd shelter_bonus).
const HEARTH_HEALTH:=0.05
const LEAN_TO_HEALTH:=0.12
## The Open Work Area's tools and materials (consequence_engine.gd material_target).
const WORK_AREA_MATERIALS:=0.08


# --- Homes ----------------------------------------------------------------------------

## The homes and what they do for the people today: {places, people, ratio,
## crowd, spare, lines}.
static func homes()->Dictionary:
	var state=WorldSimulation.state
	var people:=maxf(1.0,float(state.population_exact))
	var places:=float(state.housing_capacity)
	# consequence_engine.gd permanent_housing_ratio (0.15..1.12).
	var h:=clampf(places/people,0.15,1.12)
	var covered:=clampf(places/people,0.0,1.0)
	var crowd:=people/maxf(1.0,places)
	var lines:Array=[]
	var labor:=float(state.simulation_metrics.get("labor_efficiency",0.72))
	lines.append(_line("Work pace","+%d points" % roundi(h*12.0),
		"Roofs over heads add %d points to how fast the day's work goes (now %d of 100). With no shelter at all it would be %d." % [roundi(h*12.0),roundi(labor*100.0),roundi(0.15*12.0)],"good"))
	lines.append(_line("Health","+%d points" % roundi(h*16.0),"The health the people tend toward rises %d points because they sleep under cover." % roundi(h*16.0),"good"))
	lines.append(_line("Holding together","+%d points" % roundi(h*15.0),"People with a home of their own quarrel less: cohesion's target is %d points higher." % roundi(h*15.0),"good"))
	# game_state.gd _mortality_condition_factor shelter_factor.
	var death:=lerpf(1.65,0.88,covered)
	lines.append(_line("Deaths from age and weakness","×%s" % _two(death),
		("Everyone is housed: the lowest these deaths can go (×0.88; with no roofs ×1.65)." if covered>=1.0 else "%d of every 100 have a place: deaths run ×%s (×0.88 when all are housed, ×1.65 with none)." % [roundi(covered*100.0),_two(death)]),"good" if death<1.0 else "bad"))
	# game_state.gd conception factor: lerp(0.55, 1.03, housing).
	var births:=lerpf(0.55,1.03,covered)
	lines.append(_line("Births","×%s" % _two(births),"A child is conceived ×%s as often as if everyone were housed and well; homeless families have far fewer children (×0.55)." % _two(births),"good" if births>=1.0 else "bad"))
	if covered<0.55:
		lines.append(_line("Childbirth","+%d%% danger" % roundi((0.55-covered)*180.0),"With so many sleeping in the open, childbirth is more dangerous for mothers.","bad"))
	if h<0.68:
		var exposed:=(0.68-h)*0.04*people
		lines.append(_line("Deaths of exposure","about %s a year" % _one(exposed),"Those without a place die of cold, wet and heat: about %s a year at this crowding, more in hard weather." % _one(exposed),"bad"))
	# crisis_system.gd: sickness × exp(1.6(crowd − 0.55)); fire × exp(crowd − 0.55).
	var sick:=exp(1.6*(crowd-CROWD_REF))
	var fire:=exp(crowd-CROWD_REF)
	var full:=roundi(minf(crowd,9.99)*100.0)
	lines.append(_line("Sickness breaking out","×%s" % _two(sick),"Homes are %d%% full. Sickness breaks out ×%s as often as in a town with room to spare (55%% full); more homes would bring it down." % [full,_two(sick)],"bad" if sick>1.05 else "good"))
	lines.append(_line("Fire","×%s" % _two(fire),"Crowded hearths catch: a fire starts ×%s as often as in a roomy town." % _two(fire),"bad" if fire>1.05 else "good"))
	var spare:=maxi(0,int(places-people))
	lines.append(_line("Room for newcomers","%d places" % spare,("Newcomers and people brought home can move in only while two or more places stand empty (society_exchange)." if spare>=2 else "No room: newcomers and people brought home cannot move in until more homes go up."),"good" if spare>=2 else "bad"))
	return {"places":int(places),"people":int(people),"ratio":places/people,"crowd":crowd,"spare":spare,"lines":lines}


# --- Civic works ----------------------------------------------------------------------

## A civic work's effects: what it does now when it stands, else what it
## would do once built at the town's present repair. {built, factor, lines}.
static func work(title:String)->Dictionary:
	var built:=title in WorldSimulation.state.settlement_completed
	var condition:=clampf(float(WorldSimulation.settlements.city_form().condition),0.0,1.0)
	var lines:Array=[]
	match title:
		"Hearth Circle":
			lines.append(_line("Founds the town","every work","Every other work waits on it; it sets up the town's council and opens it to trade with other peoples.","good"))
			lines.append(_line("Health","+%d points" % roundi(HEARTH_HEALTH*100.0),"A shared fire and cooking place: the health the people tend toward is %d points higher." % roundi(HEARTH_HEALTH*100.0),"good"))
		"Lean-to Shelters":
			lines.append(_line("Places","+%d" % Construction.lean_to_places(),"Room for %d more people at once, with what the people know of building." % Construction.lean_to_places(),"good"))
			lines.append(_line("Health","+%d points" % roundi(LEAN_TO_HEALTH*100.0),"Dry, raised sleeping places: the health the people tend toward is %d points higher." % roundi(LEAN_TO_HEALTH*100.0),"good"))
			lines.append(_line("New homes","as the town fills","After them, builders put up %d more places each time the town is over %d%% full." % [Construction.housing_batch_places(),roundi(Construction.HOUSING_TRIGGER*100.0)],"plain"))
		"Storage Pits":
			lines.append_array(_pits_lines(built))
		"Public Stores":
			lines.append_array(_stores_lines(built))
		"Open Work Area":
			lines.append(_line("Tools and materials","+%d points" % roundi(WORK_AREA_MATERIALS*100.0),"A roofed place to work: the makers' tools and material work rise %d points toward their target." % roundi(WORK_AREA_MATERIALS*100.0),"good"))
			lines.append(_line("Store room","+235","Yard 160, covered 55 and secure 20 units of room for timber, stone, clay and fibre.","good"))
			lines.append(_line("Water vessels","+1 day","Room to keep a day more of drinking water in hand.","good"))
		"Gathering Yard":
			lines.append_array(_yard_lines(built,condition))
		"Framed Hall":
			lines.append_array(_hall_lines(built,condition))
		"Hearth Shrine","Shrine House":
			lines.append_array(_shrine_lines(title,built,condition))
	var f:float=CIVIC.factor(title) if built else condition
	if CIVIC.FULL.has(title) and f<0.995:
		var why:="the town's repair is %d%%" % roundi(condition*100.0)
		if title==CIVIC.SHRINE_HOUSE and CIVIC.keepers_ratio()<condition: why="only %d of the %d keepers it needs are at work" % [floori(CIVIC.keepers_ratio()*CIVIC.keepers_needed()),CIVIC.keepers_needed()]
		lines.append(_line("Acting at","%d%%" % roundi(f*100.0),"Its effects act at %d%% because %s." % [roundi(f*100.0),why],"bad" if f<0.75 else "plain"))
	return {"built":built,"factor":f,"lines":lines}


static func _pits_lines(built:bool)->Array:
	var lines:Array=[]
	var saved:=_spoilage_saved_a_month()
	lines.append(_line("Food spoiling","×%s" % _two(PITS_SPOILAGE),("Food keeps longer: about %s rations a month less rot at today's stores." % _one(saved)) if built and saved>0.0 else "Fresh and stored food rot 28% slower.","good"))
	var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var eaten:=maxf(0.1,float(WorldSimulation.state.simulation_metrics.get("food_consumption",people)))
	lines.append(_line("Room for food","+%s rations" % _grouped(roundi(people*PITS_RATIONS)),"%d rations of room a person: about %d more days of food can be kept before the rest is thrown away." % [roundi(PITS_RATIONS),roundi(people*PITS_RATIONS/eaten)],"good"))
	lines.append(_line("Water vessels","+2 days","Room to keep two more days of drinking water in hand.","good"))
	lines.append(_line("Children in lean months","+30%","Counts toward the stores that carry children through the lean season (early care).","good"))
	return lines


static func _stores_lines(built:bool)->Array:
	var lines:Array=[]
	var state=WorldSimulation.state
	var people:=maxf(1.0,float(state.population_exact))
	var carriers:=float(state.effective_workers("Logistics"))
	var stewards:=float(state.effective_workers("Administration"))
	var need_c:=ceili(people*0.04);var need_s:=ceili(people*0.02)
	var staffed:=clampf(minf(carriers/maxf(1.0,people*0.04),stewards/maxf(1.0,people*0.02)),0.0,1.0)
	var eaten:=maxf(0.1,float(state.simulation_metrics.get("food_consumption",people)))
	lines.append(_line("Room for food","+%s rations" % _grouped(roundi(people*STORES_RATIONS*staffed)),"Up to %d rations a person (%d days of food), as far as it is staffed: %d of %d carriers and %d of %d stewards, so %d%%." % [roundi(STORES_RATIONS),roundi(people*STORES_RATIONS/eaten),mini(need_c,floori(carriers)),need_c,mini(need_s,floori(stewards)),need_s,roundi(staffed*100.0)],"good" if staffed>=0.75 else "bad"))
	lines.append(_line("The common store's ways","×%d%%" % roundi(staffed*100.0),"What the people know of keeping a common store (keeping food, holding together, the council's reach) acts only as far as the store is staffed.","plain"))
	lines.append(_line("Children in lean months","+20%","Counts toward the stores that carry children through the lean season (early care).","good"))
	return lines


static func _yard_lines(built:bool,condition:float)->Array:
	var lines:Array=[]
	var full:=float((CIVIC.FULL[CIVIC.YARD] as Dictionary).extraction)
	var now:float=full*(CIVIC.factor(CIVIC.YARD) if built else condition)
	var dug:=float(WorldSimulation.state.material_metrics.get("extracted_today",0.0))
	var gained:=dug*now/(1.0+now) if built else dug*now
	lines.append(_line("Digging and cutting","+%d%%" % roundi(now*100.0),"Every deposit worked gives %d%% more (at full repair %d%%)%s." % [roundi(now*100.0),roundi(full*100.0),(": about %s more units a day at today's work" % _one(gained)) if dug>0.0 else ""],"good"))
	lines.append(_line("Yard room","+320","Room to stack 320 units of timber, stone and clay in the open.","good"))
	return lines


static func _hall_lines(built:bool,condition:float)->Array:
	var lines:Array=[]
	var f:float=CIVIC.factor(CIVIC.HALL) if built else condition
	var full:Dictionary=CIVIC.FULL[CIVIC.HALL]
	lines.append(_line("Legitimacy","+%s points" % _one(float(full.legitimacy)*f*100.0),"The council sits and feasts under one roof: the people heed their leaders more (legitimacy's target +%s)." % _one(float(full.legitimacy)*f*100.0),"good"))
	lines.append(_line("Holding together","+%s points" % _one(float(full.cohesion)*f*100.0),"Shared feasts and a place to settle quarrels: cohesion's target +%s." % _one(float(full.cohesion)*f*100.0),"good"))
	var stewards:=float(WorldSimulation.state.effective_workers("Administration"))
	var need:=maxf(1.0,float(WorldSimulation.state.population_exact)*0.035)
	var reach:=float(full.admin_reach)*f
	lines.append(_line("Stewards' reach","+%d%%" % roundi(reach*100.0),"Each steward counts for %d%% more in keeping order: %d stewards serve like %s of the %d the town needs." % [roundi(reach*100.0),roundi(stewards),_one(stewards*(1.0+reach)),ceili(need)],"good"))
	# The framing knowledge acts through the hall (civilian_goods.gd factor).
	var framing:Dictionary=(WorldSimulation.discovery.discovery_definition("framed_construction").get("effects",{}) as Dictionary)
	var acting:float=Goods.factor("framed_construction") if built else 0.0
	var words:PackedStringArray=[]
	for pair in [["construction_rate","building goes %s%% faster"],["housing_output","each new batch of homes holds %s%% more"],["dry_storage","dry stores keep %s%% better"]]:
		var amount:=float(framing.get(String(pair[0]),0.0))
		if amount>0.0: words.append(String(pair[1]) % _one(amount*100.0))
	if not words.is_empty():
		lines.append(_line("Timber framing",("%d%% in use" % roundi(acting*100.0)) if built else "once built","%s. It acts while the hall stands, is kept in repair and builders use it (at least 3 in 100 people building)." % _cap(", ".join(words)),"good" if acting>=0.75 or not built else "plain"))
	return lines


static func _shrine_lines(title:String,built:bool,condition:float)->Array:
	var lines:Array=[]
	var f:float=CIVIC.factor(title) if built else (minf(condition,CIVIC.keepers_ratio()) if title==CIVIC.SHRINE_HOUSE else condition)
	var full:Dictionary=CIVIC.FULL[title]
	lines.append(_line("Holding together","+%s points" % _one(float(full.cohesion)*f*100.0),"Offerings shared at the shrine draw the people together: cohesion's target +%s." % _one(float(full.cohesion)*f*100.0),"good"))
	if full.has("legitimacy"):
		lines.append(_line("Legitimacy","+%s points" % _one(float(full.legitimacy)*f*100.0),"Its keepers speak for the god, and the people heed their leaders more: legitimacy's target +%s." % _one(float(full.legitimacy)*f*100.0),"good"))
	lines.append(_line("Love of the god","+%s points" % _one(float(full.devotion)*f*100.0),"The people's love of the god rises %s points (of 100) while it is tended." % _one(float(full.devotion)*f*100.0),"good"))
	if full.has("dread_eased"):
		lines.append(_line("Dread of the god","−%s points" % _one(float(full.dread_eased)*f*100.0),"A house where the god can be approached: the people's dread of the god falls %s points." % _one(float(full.dread_eased)*f*100.0),"good"))
	var eaten:=maxf(0.1,float(WorldSimulation.state.simulation_metrics.get("food_consumption",WorldSimulation.state.population_exact)))
	var offered:=eaten*float(full.offerings)*f
	lines.append(_line("Offerings","%s food a day" % _one(offered),"The cost: %s%% of what the people eat is given at the shrine (%s rations a day now), and it is short from the stores in hard times too." % [_one(float(full.offerings)*100.0),_one(offered)],"bad"))
	if title==CIVIC.SHRINE_HOUSE:
		var have:=float(WorldSimulation.state.effective_workers("Knowledge"))
		lines.append(_line("Keepers","%d of %d" % [mini(CIVIC.keepers_needed(),floori(have)),CIVIC.keepers_needed()],"Lore keepers tend it (1 in 100 of the people). With fewer, its effects shrink in proportion.","good" if have>=float(CIVIC.keepers_needed()) else "bad"))
	return lines


# --- The town at a glance -----------------------------------------------------------

## What the buildings do for the people now, one line each: homes, food kept,
## hall, shrines, yard, workshops and stores, repair and defences.
static func summary()->Array:
	var state=WorldSimulation.state
	var lines:Array=[]
	if not bool(state.settlement_site_committed): return lines
	var h:=homes()
	var ratio:=float(h.ratio)
	lines.append(_line("Homes","%s places a person" % _two(ratio),"%d places for %d people. Deaths ×%s, births ×%s; sickness breaks out ×%s and fire ×%s as often as in a roomy town." % [int(h.places),int(h.people),_two(lerpf(1.65,0.88,clampf(ratio,0.0,1.0))),_two(lerpf(0.55,1.03,clampf(ratio,0.0,1.0))),_two(exp(1.6*(float(h.crowd)-CROWD_REF))),_two(exp(float(h.crowd)-CROWD_REF))],"good" if ratio>=1.0 else "bad"))
	var food:=WorldSimulation.food
	if food!=null and food.has_method("_food_storage_capacity"):
		var room:=float(food.call("_food_storage_capacity"))
		var eaten:=maxf(0.1,float(state.simulation_metrics.get("food_consumption",state.population_exact)))
		var kept:="Storage Pits cut spoilage to ×0.72. " if "Storage Pits" in state.settlement_completed else "No Storage Pits: food rots at the full rate. "
		lines.append(_line("Food kept","%d days" % roundi(room/eaten),"%sRoom for %s rations, %d days of food; more than that is thrown away. Days of food in store are the famine buffer." % [kept,_grouped(roundi(room)),roundi(room/eaten)],"plain"))
	for title in [CIVIC.HALL,CIVIC.HEARTH_SHRINE,CIVIC.SHRINE_HOUSE,CIVIC.YARD]:
		if title not in state.settlement_completed: continue
		var parts:PackedStringArray=[]
		var now:Dictionary=CIVIC.of(title).now
		for pair in [["legitimacy","legitimacy +%s"],["cohesion","cohesion +%s"],["devotion","love of the god +%s"],["dread_eased","dread of the god −%s"]]:
			if float(now.get(String(pair[0]),0.0))>0.0: parts.append(String(pair[1]) % _one(float(now[pair[0]])*100.0))
		if float(now.get("admin_reach",0.0))>0.0: parts.append("stewards reach +%d%%" % roundi(float(now.admin_reach)*100.0))
		if float(now.get("extraction",0.0))>0.0: parts.append("every deposit +%d%%" % roundi(float(now.extraction)*100.0))
		if float(now.get("offerings",0.0))>0.0: parts.append("offerings %s%% of food" % _one(float(now.offerings)*100.0))
		lines.append(_line(title,"%d%%" % roundi(CIVIC.factor(title)*100.0),_cap("; ".join(parts))+" (points of 100).","good"))
	var capacities:Dictionary=WorldSimulation.settlements.city_capacities()
	var workshop:=float(capacities.get("workshop_function",0.0));var storage:=float(capacities.get("storage_function",0.0))
	if workshop>0.0 or storage>0.0:
		lines.append(_line("Workshops and stores","%d / %d" % [roundi(workshop*100.0),roundi(storage*100.0)],"The buildings' workshops run at %d and stores at %d (of 100): tools and materials +%s points, building +%s%%, hauling and trade +%s points." % [roundi(workshop*100.0),roundi(storage*100.0),_one(workshop*12.0),_one(workshop*10.0),_one(storage*10.0)],"plain"))
	var condition:=clampf(float(WorldSimulation.settlements.city_form().condition),0.0,1.0)
	lines.append(_line("Repair","%d%%" % roundi(condition*100.0),"The hall, shrines, yard, workshops and stores act at the town's repair. Below 48%% the town's buildings are failing.","good" if condition>=0.75 else "bad"))
	var mc=WorldSimulation.military
	if mc!=null and mc.has_method("settlement_defense_snapshot"):
		var d:Dictionary=mc.settlement_defense_snapshot()
		if int(d.get("stage",0))>0:
			lines.append(_line("Defences",String(d.get("short","")),"Defenders fight %d%% better, raiders are seen %d km off, and %d%% of the stores cannot be carried off in a raid." % [roundi(float(d.get("defense_bonus",0.0))*100.0),roundi(float(d.get("observation_radius_km",0.0))),roundi(float(d.get("store_protection",0.0))*100.0)],"good"))
	return lines


## The defence works, stage by stage, with what each gives: [{stage, name,
## lines}] for the Infrastructure tab.
static func defences()->Array:
	var mc=WorldSimulation.military
	if mc==null: return []
	var d:Dictionary=mc.settlement_defense_snapshot()
	var out:Array=[]
	var integrity:=float(d.get("integrity",1.0))
	var here:=int(d.get("stage",0))
	for i in mc.SETTLEMENT_DEFENSE_STAGES.size():
		if i==0: continue
		var stage:Dictionary=mc.SETTLEMENT_DEFENSE_STAGES[i]
		var now:bool=i<=here
		var scale:=integrity if now else 1.0
		out.append({"stage":i,"name":String(stage.short),"built":now,"lines":[
			_line("Defenders","+%d%%" % roundi(float(stage.defense_bonus)*scale*100.0),"Our side fights at home as if the ground were %d%% more defensible; attackers need more men to ring the town in a siege." % roundi(float(stage.defense_bonus)*scale*100.0),"good"),
			_line("Lookout","%d km" % roundi(float(stage.observation_km)*(0.82+scale*0.18)),"How far off an approaching band is seen.","good"),
			_line("Stores safe from raids","%d%%" % roundi(float(stage.store_protection)*scale*100.0),"The share of the stores raiders cannot carry away.","good"),
			_line("Work","%s" % _grouped(roundi(float(stage.work))),"Defenders' work to raise it, with its timber, stone and clay.","plain")]})
	return out


## A water or waste work's effects: its coverage of the town and the listed
## effects of the practice it puts to use, scaled by that coverage
## (water_waste_works.gd factor, civilian_goods.gd). {name, lines}.
const WATER_WORDS:={"sanitation":["Filth kept from homes","illness deaths and the burden of disease fall"],"water_safety":["Cleaner drinking water","fewer fall sick from what they drink"],
	"disease_exposure":["Sickness passed on","fewer catch sickness from one another"],"health_protection":["Health","the people's health rises"]}
static func water_work(kind:String)->Dictionary:
	var works=preload("res://scripts/water_waste_works.gd")
	var spec:Dictionary=works.SPECS.get(kind,{})
	var record:Dictionary=works.work_for(kind)
	var coverage:=works.factor(String(spec.get("discovery","")))
	var lines:Array=[]
	lines.append(_line("Coverage","%d%%" % roundi(coverage*100.0),"How much of the town it serves, with its repair; its effects act in proportion.","good" if coverage>=0.75 else "plain"))
	var listed:Dictionary=(WorldSimulation.discovery.discovery_definition(String(spec.get("discovery",""))).get("effects",{}) as Dictionary)
	for key in listed:
		if not WATER_WORDS.has(String(key)): continue
		var amount:=float(listed[key])*coverage
		var words:Array=WATER_WORDS[String(key)]
		var better:=amount>0.0 if String(key)!="disease_exposure" else amount<0.0
		lines.append(_line(String(words[0]),"%s%s" % ["+" if amount>=0.0 else "−",_three(absf(amount))],"%s: %s (the practice's listed %s at %d%% coverage)." % [_cap(String(words[1])),"it helps" if better else "it harms",_three(absf(float(listed[key]))),roundi(coverage*100.0)],"good" if better else "bad"))
	# What the town's water, its water knowledge and these works do to how
	# often sickness breaks out (crisis_system.gd inputs water_q, water_term):
	# short water raises it, and clean water keeps lowering it past plenty.
	var crisis=preload("res://scripts/crisis_system.gd")
	var drink:=clampf(float(WorldSimulation.state.simulation_metrics.get("water_intake_ratio",1.0)),0.0,1.0)
	var quality:float=clampf(drink-0.15*crisis._effect("disease_exposure")+0.2*crisis._effect("water_safety")+0.2*crisis._effect("sanitation"),0.0,float(crisis.WATER_Q_MAX))
	var outbreaks:=exp(float(crisis.water_term(quality)))
	lines.append(_line("Sickness breaking out","×%s" % _two(outbreaks),"With the water drunk today and everything the people know and have built to keep it clean, sickness breaks out ×%s as often as with plain, plentiful water (it can fall to ×%s)." % [_two(outbreaks),_two(exp(float(crisis.water_term(float(crisis.WATER_Q_MAX)))))],"good" if outbreaks<1.0 else ("bad" if outbreaks>1.02 else "plain")))
	if kind=="cistern":
		var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
		var condition:=float(record.get("condition",1.0))
		lines.append(_line("Water kept","%s" % _one(people*2.5*condition),"It stores about %s units of water, two and a half a person, as long as it is kept in repair." % _one(people*2.5*condition),"good"))
	return {"name":String(spec.get("name",kind.capitalize())),"lines":lines}


# --- Words ---------------------------------------------------------------------------

static func _three(x:float)->String:
	return "%.3f" % x


## Rations a month the Storage Pits keep from rotting at today's stores.
static func _spoilage_saved_a_month()->float:
	var food:=WorldSimulation.food
	if food==null or not food.has_method("_spoilage_rates"): return 0.0
	var rates:Array=food.call("_spoilage_rates",false)
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var fresh:=float(stocks.get(preload("res://scripts/food_system.gd").FRESH,0.0))
	var stored:=float(stocks.get(preload("res://scripts/food_system.gd").STORED,0.0))
	# Without the pits each rate would be 1/0.72 of what it is.
	var extra:=(fresh*float(rates[0])+stored*float(rates[1]))*(1.0/PITS_SPOILAGE-1.0)
	return extra*30.0


static func _line(label:String,value:String,words:String,tone:String)->Dictionary:
	return {"label":label,"value":value,"words":words,"tone":tone}


static func _two(x:float)->String:
	return "%.2f" % x


static func _one(x:float)->String:
	return str(roundi(x)) if absf(x)>=10.0 else "%.1f" % x


static func _grouped(n:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(n)


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text
