extends RefCounted
## PROPOSAL STAKES: what the ruler stands to gain from what the court puts
## before them, what it costs, how likely it is to work and what saying no
## costs, read from the engine before the choice and never changing it.
##
## Decrees (a petition's "Issue their decree", a first task, a promise kept, a
## warning heeded, an aim pressed) go through the same local reading the civic
## council uses (PronouncementInterpreter._local_interpretation). Each policy
## is assessed as the leader who would carry it out would carry it
## (AdvisorSystem.execution_modifier_for_advisor with the settlement leader,
## ConsequenceEngine.directive_assessment), and every channel is put in the
## player's terms:
##   - a target (health, cohesion, legitimacy, security, materials, hauling):
##     the strengths list's own formula (SocietyModel.capacity_value), with the
##     measure moved as far as the engine moves it by the order's last day
##     (the target shift, closed at the engine's daily smoothing rate);
##   - the day's work: the policy's labour channel plus the upkeep every
##     standing order puts on the stewards (governance_metrics), as the work of
##     so many of the people able to work;
##   - food and materials the order draws from the stores at once;
##   - food brought in or eaten, conceptions, building, water, stone, learning
##     and newborn deaths: each in proportion to today's own numbers;
##   - how likely: the assessment's implementation rate and resistance, in the
##     words the engine uses when it reports the order underway.
## Legacy aims: what fulfilling, failing and letting go do (legacy_aims.gd's
## ending constants), what taking one up leans toward, and the pace the people
## are on against the aim's own target. Great works: what the work gives if it
## stands (wonder_concept.gd rewards at the outcome's condition), its costs and
## years, and its outcome odds (WonderConcept.odds).
##
## Returned stakes: {kind, subject, gains:[{what,text,points?}], costs:[...],
## notes:[String], odds:String, refusal:String, blocked:bool, blocker:String,
## days:int, short:String}. Static; reference with preload (no class_name).

const SocietyModelScript:=preload("res://scripts/society_model.gd")
const CapacityWords:=preload("res://scripts/hud/capacity_words.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const HALL_PATH:="res://scripts/audience_hall.gd"
const AIMS_PATH:="res://scripts/legacy_aims.gd"
const WORKS_PATH:="res://scripts/great_works_audience.gd"
const CONCEPT_PATH:="res://scripts/wonder_concept.gd"
const SURVIVAL_PATH:="res://scripts/scout_survival.gd"
const CHRONICLE_PATH:="res://scripts/chronicle.gd"

## The twelve capacities, in the strengths list's order.
const DYNAMICS:=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
## Policy channels that move a measure's target, and the capacity input it is.
const TARGET_INPUTS:={"health_target":"health","cohesion_target":"cohesion","legitimacy_target":"legitimacy","security_target":"security","material_target":"materials","logistics_target":"hauling"}
## Immediate shifts an order's contract makes, and the input each one moves.
const DIRECT_INPUTS:={"health_delta":"health","cohesion_delta":"cohesion","legitimacy_delta":"legitimacy","security_delta":"security","knowledge_delta":"learning","ecology_delta":"ecology"}
## Share of the gap to its target each measure closes in a day
## (ConsequenceEngine.process_day: lerpf toward the target at SPAN.rate(r)).
## A measure without an entry does not drift back (it accumulates).
const DAILY_APPROACH:={"health":0.022,"cohesion":0.014,"legitimacy":0.012,"security":0.016,"materials":0.012,"hauling":0.016}
## The engine's words for how many carry an order out and how openly they
## resist (ConsequenceEngine.apply_directive), said before the order.
const MOST_DO:=0.72
const SOME_DO:=0.36
const MANY_REFUSE:=0.60
const SOME_GRUMBLE:=0.35
## A decree petition's answers and the audiences that carry one.
const DECREE_OPTIONS:=["decree","decree_gather"]
const NO_STAKES_TOPICS:=["grievance","mourning","callback","omen","campaign","crisis","upkeep","summons"]
## Care a decree gives where a practice is missing (early_life_conditions.gd).
const CARE_WORDS:={"sick_care_coverage":"The sick and the small are tended where we lack remedies","water_care_coverage":"Clean water fetched and kept where we lack the practice","injury_care_coverage":"The hurt are tended where we lack the practice"}
## What the words of a crisis answer's cost tag mean (crisis_system.gd).
const COST_TAG_WORDS:={"health":"everyone weakens","labour":"hands taken from other work","next year":"next year's sowing","herd":"young animals lost","cohesion":"bad blood between families","housing":"shelter lost","timber":"timber from the stack","time":"slow going","clay":"clay and months of work","food":"food from the stores"}

static var _cache:Dictionary={}
static var _cache_day:=-1

# --------------------------------------------------------------------------
# The world, read only
# --------------------------------------------------------------------------

static func _day()->int:
	return int(WorldSimulation.state.elapsed_days)

static func clear_cache()->void:
	_cache.clear()
	_cache_day=-1

static func _cached(key:String,make:Callable)->Dictionary:
	## One reading per matter per day and state: the modal, its cards and the
	## voice all ask within the same moment; the stakes are the same answer.
	var state=WorldSimulation.state
	if _day()!=_cache_day:
		_cache.clear()
		_cache_day=_day()
	var full:="%s|%d|%d|%d|%d" % [key,state.active_modifiers.size(),roundi(float(state.population_exact)),roundi(float(state.resource_stockpiles.get("Food",0.0))),state.known_discoveries.size()]
	if _cache.has(full): return (_cache[full] as Dictionary).duplicate(true)
	var made:Dictionary=make.call()
	if _cache.size()>=96: _cache.clear()
	_cache[full]=made.duplicate(true)
	return made

static func _settlement()->Dictionary:
	## The town a court decree goes to: the selected one, else the first home
	## (local_terrain._civic_settlement), found without selecting anything.
	var state=WorldSimulation.state
	var selected:=String(state.selected_player_settlement_id)
	for s in state.player_settlements:
		if s is Dictionary and selected!="" and String((s as Dictionary).get("id",""))==selected: return s
	for s in state.player_settlements:
		if s is Dictionary and bool((s as Dictionary).get("primary",false)): return s
	return state.player_settlements[0] if not state.player_settlements.is_empty() and state.player_settlements[0] is Dictionary else {}

static func _given(name:String)->String:
	var clean:=name.strip_edges()
	return clean.get_slice(" ",0) if clean!="" else "They"

static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)

static func _lower(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_lower()+text.substr(1)

static func _count(n:int)->String:
	return EraWords.count_word(n) if n>=0 and n<=12 else str(n)

static func span_words(days:float)->String:
	## How long an order runs, as the people count time: days, then moons
	## (months once they write), then winters (years).
	var d:=maxi(1,roundi(days))
	var hearth:=EraWords.hearth()
	if d<25: return "%s day%s" % [_count(d),"" if d==1 else "s"]
	if d<330:
		var moons:=maxi(1,roundi(float(d)/(29.5 if hearth else 30.0)))
		if hearth: return "a moon" if moons==1 else "%s moons" % _count(moons)
		return "a month" if moons==1 else "%s months" % _count(moons)
	var years:=maxi(1,roundi(float(d)/365.0))
	if hearth: return "a winter" if years==1 else "%s winters" % _count(years)
	return "a year" if years==1 else "%s years" % _count(years)

static func points_words(points:float)->String:
	## "about 2 points", "about 0.6 points": a change in points of a strength.
	var size:=absf(points)
	if size>=0.95:
		var whole:=roundi(size)
		return "about %d point%s" % [whole,"" if whole==1 else "s"]
	if size>=0.05: return "about %.1f points" % snappedf(size,0.1)
	return "less than 0.1 points"

static func people_words(people:float)->String:
	var size:=absf(people)
	if size<0.5: return "less than one person's work"
	var whole:=roundi(size)
	return "the work of about %d %s" % [whole,"person" if whole==1 else "people"]

static func amount_words(amount:float)->String:
	return str(roundi(amount)) if amount>=9.5 else ("%.1f" % snappedf(amount,0.1)).trim_suffix(".0")

static func _capacity_name(dynamic:String)->String:
	return String(dynamic).capitalize()

# --------------------------------------------------------------------------
# Strengths: the capacity formula with measures moved
# --------------------------------------------------------------------------

static func _inputs()->Dictionary:
	var model:Variant=DiscoverySystem.get("society_model")
	if model==null or not (model as Object).has_method("capacity_inputs"): return {}
	return (model as Object).call("capacity_inputs")

static func _moved(base:Dictionary,moves:Dictionary)->Dictionary:
	var out:=base.duplicate()
	for key in moves:
		out[key]=clampf(float(base.get(key,0.0))+float(moves[key]),0.0,1.0)
	return out

static func capacity_shift(moves:Dictionary,base:Dictionary={})->Array[Dictionary]:
	## moves: {capacity input: change}. Every strength the moves change, largest
	## first: [{what, points, part}], "part" the input that moved it most.
	var result:Array[Dictionary]=[]
	if moves.is_empty(): return result
	var inputs:=base if not base.is_empty() else _inputs()
	if inputs.is_empty(): return result
	var after:=_moved(inputs,moves)
	for dynamic:String in DYNAMICS:
		var before:=SocietyModelScript.capacity_value(dynamic,inputs)
		var points:=(SocietyModelScript.capacity_value(dynamic,after)-before)*100.0
		if absf(points)<0.05: continue
		var best:=""
		var size:=0.0
		for key in moves:
			var one:=SocietyModelScript.capacity_value(dynamic,_moved(inputs,{key:moves[key]}))-before
			if absf(one)>size: size=absf(one); best=String(key)
		result.append({"what":dynamic,"points":points,"part":best})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return absf(float(a.points))>absf(float(b.points)))
	return result

static func _shift_text(entry:Dictionary)->String:
	var points:=float(entry.points)
	var text:="%s %s %s" % [_capacity_name(String(entry.what)),"up" if points>0.0 else "down",points_words(points)]
	var part:=String(entry.get("part",""))
	if part!="": text+=" (%s)" % _lower(CapacityWords.reason_words(part,points))
	return text

static func _approach(input:String,days:float)->float:
	if not DAILY_APPROACH.has(input): return 1.0
	return 1.0-pow(1.0-float(DAILY_APPROACH[input]),maxf(0.0,days))

# --------------------------------------------------------------------------
# Decrees
# --------------------------------------------------------------------------

static func _empty(kind:String,subject:String)->Dictionary:
	return {"kind":kind,"subject":subject,"gains":[],"costs":[],"notes":[],"rows":[],"odds":"","refusal":"","refusal_key":"If you say no","refusal_spoken":"","blocked":false,"blocker":"","days":0,"years":"","short":"","pace_short":"","numbers":{}}

static func for_decree(text:String)->Dictionary:
	## The stakes of issuing these words as a civic decree now. {} when the
	## words are empty or nobody rules here.
	var clean:=text.strip_edges()
	if clean.is_empty() or WorldSimulation.actor_id!="player": return {}
	var settlement:=_settlement()
	var sid:=String(settlement.get("id",""))
	var leader:Dictionary=GovernmentPeopleSystem.settlement_leader(sid) if sid!="" else {}
	return _cached("decree|%s|%s|%d" % [clean,sid,int(leader.get("person_id",0))],func()->Dictionary: return _decree(clean,settlement,leader))

static func _decree(text:String,settlement:Dictionary,leader:Dictionary)->Dictionary:
	var out:=_empty("decree",text)
	var place:=String(settlement.get("name","")).strip_edges()
	if place=="": place=String(WorldSimulation.state.settlement_name).strip_edges()
	if settlement.is_empty() or leader.is_empty():
		out.blocked=true
		out.blocker="no one leads %s to carry it out" % (place if place!="" else "our people")
		out.odds="It cannot be carried out: %s." % String(out.blocker)
		return _finish(out)
	out["leader"]=String(leader.get("name",""))
	var reading:Dictionary=PronouncementInterpreter._local_interpretation(text)
	var parts:Array[Dictionary]=[]
	var blocked:Array[Dictionary]=[]
	for policy_variant in reading.get("policies",[]):
		if not policy_variant is Dictionary: continue
		var policy:Dictionary=policy_variant
		if String(policy.get("action","enact"))!="enact": continue
		var id:=String(policy.get("id",""))
		var execution:=float(AdvisorSystem.execution_modifier_for_advisor(leader,"SettlementLeader",policy.get("skills",[])))
		var assessment:Dictionary=WorldSimulation.consequences.directive_assessment(id,float(policy.get("magnitude",0.0)),float(policy.get("days",30.0)),execution,policy.get("directive_parameters",{}))
		var entry:={"policy":policy,"assessment":assessment,"effects":GovernmentPolicyCatalog.definition(id).get("effects",{})}
		if bool(assessment.get("can_apply",false)): parts.append(entry)
		else: blocked.append(entry)
	out["policies"]=parts.map(func(e:Dictionary)->String: return String(e.policy.id))
	if parts.is_empty() and blocked.is_empty():
		out.blocked=true
		out.blocker="the council cannot say what these words would change"
		out.odds="%s." % _cap(String(out.blocker))
		return _finish(out)
	for entry in blocked:
		var why:=plain_blocker(entry.assessment)
		if parts.is_empty():
			if String(out.blocker)=="": out.blocker=why
		else:
			(out.notes as Array).append("%s must wait: %s." % [_cap(GovernmentPolicyCatalog.display_name(String(entry.policy.id))),why])
	if parts.is_empty():
		out.blocked=true
		out.odds="It cannot be done yet: %s." % String(out.blocker)
		(out.notes as Array).append("They would try anyway: effort spent, and little to show for it.")
		out.days=int(float((blocked[0].policy as Dictionary).get("days",30.0)))
		return _finish(out)
	_read_parts(out,parts,leader)
	return _finish(out)

static func _read_parts(out:Dictionary,parts:Array[Dictionary],leader:Dictionary)->void:
	var state=WorldSimulation.state
	var engine=WorldSimulation.consequences
	var metrics:Dictionary=state.simulation_metrics
	var moves:Dictionary={}
	var gains:Array=out.gains
	var costs:Array=out.costs
	var notes:Array=out.notes
	var numbers:Dictionary=out.numbers
	var labor_add:=0.0
	var food:=0.0
	var materials:=0.0
	var rate:=0.0
	var resistance:=0.0
	var days:=0.0
	var active:Array=engine.active_policies()
	for entry in parts:
		var policy:Dictionary=entry.policy
		var a:Dictionary=entry.assessment
		var effects:Dictionary=entry.effects
		var eff:=float(a.get("effective_magnitude",0.0))
		var d:=float(a.get("duration_days",policy.get("days",30.0)))
		days=maxf(days,d)
		rate+=float(a.get("implementation_rate",0.0))
		resistance=maxf(resistance,float(a.get("resistance",0.0)))
		food+=float((a.get("costs",{}) as Dictionary).get("food_planned",0.0))
		materials+=float((a.get("costs",{}) as Dictionary).get("materials_planned",0.0))
		var id:=String(policy.get("id",""))
		# The same order already standing is replaced, not doubled
		# (ConsequenceEngine.apply_policy): only the difference is new.
		var standing:=0.0
		for record in active:
			if String((record as Dictionary).get("id",""))!=id: continue
			standing+=float((record as Dictionary).get("magnitude",0.0))
			out["already"]=true
			if standing>0.0 and notes.filter(func(n:String)->bool: return n.begins_with(_cap(GovernmentPolicyCatalog.display_name(id)))).is_empty():
				notes.append("%s is already in force for %s more: ordering it again starts it over, and changing orders unsettles people." % [_cap(GovernmentPolicyCatalog.display_name(id)),span_words(float((record as Dictionary).get("remaining_days",0.0)))])
		var net:=eff-standing
		# Re-issued at about the same strength: nothing new to count.
		if standing>0.0 and absf(net)<eff*0.25: net=0.0
		entry["net_magnitude"]=net
		if String(a.get("operation",""))=="recruitment_scouts": _expedition(out,a)
		for channel_variant in effects:
			var channel:=String(channel_variant)
			# numbers: what the channel will stand at; v: what is new.
			numbers[channel]=float(numbers.get(channel,0.0))+float(effects[channel])*eff
			var v:=float(effects[channel])*net
			if absf(v)<0.000001: continue
			if TARGET_INPUTS.has(channel):
				var input:=String(TARGET_INPUTS[channel])
				moves[input]=float(moves.get(input,0.0))+v*_approach(input,d)
				continue
			match channel:
				"labor_multiplier": labor_add+=v
				"ecology_delta": moves["ecology"]=float(moves.get("ecology",0.0))+v*d
				"knowledge_gain":
					var base:=1.0+float(engine.policy_effect("knowledge_gain"))+float(state.founding_effect("knowledge_gain"))+float(WorldSimulation.progression.effect("knowledge_rate"))
					var pct:=v/maxf(0.2,base)*100.0
					(gains if v>0.0 else costs).append({"what":"learning","text":"What we remember grows about %d%% %s" % [roundi(absf(pct)),"faster" if v>0.0 else "slower"],"percent":pct})
				"food_yield":
					var practice:=1.0+float(WorldSimulation.discovery.effect("foraging_yield"))+float(WorldSimulation.discovery.effect("food_output"))+float(state.founding_effect("food_yield"))+float(WorldSimulation.progression.effect("food_output"))+float(engine.policy_effect("food_yield"))
					var share:=v/maxf(0.2,practice)
					var harvest:Dictionary=metrics.get("food_harvest",{}) if metrics.get("food_harvest") is Dictionary else {}
					var wild:=float(harvest.get("Fresh plants",0.0))+float(harvest.get("Fresh meat",0.0))+float(harvest.get("Fish",0.0))
					var line:={"what":"food_in","percent":share*100.0}
					if wild>=1.0:
						line["per_day"]=wild*share
						line["text"]="About %s %s food a day from gathering, hunting and fishing" % [amount_words(absf(wild*share)),"more" if share>0.0 else "less"]
					else: line["text"]="Gathering, hunting and fishing bring in about %d%% %s" % [roundi(absf(share)*100.0),"more" if share>0.0 else "less"]
					(gains if share>0.0 else costs).append(line)
				"food_demand":
					var ration:=1.0+float(engine.policy_effect("food_demand"))
					var share2:=v/maxf(0.2,ration)
					var use:=float(metrics.get("food_consumption",0.0))
					var line2:={"what":"food_eaten","percent":share2*100.0}
					if use>=1.0:
						line2["per_day"]=use*share2
						line2["text"]="About %s %s food eaten a day" % [amount_words(absf(use*share2)),"less" if share2<0.0 else "more"]
					else: line2["text"]="People eat about %d%% %s" % [roundi(absf(share2)*100.0),"less" if share2<0.0 else "more"]
					(gains if share2<0.0 else costs).append(line2)
				"conception_support":
					var support:=clampf(float(WorldSimulation.discovery.effect("conception_support"))+float(engine.policy_effect("conception_support"))+float(state.founding_effect("conception_support"))+float(WorldSimulation.progression.effect("conception_support")),-0.30,0.30)
					var share3:=v/maxf(0.5,1.0+support)
					var yearly:=float(metrics.get("annual_conceptions_expected",0.0))
					var line3:={"what":"children","percent":share3*100.0}
					if yearly*absf(share3)>=0.5:
						line3["per_year"]=yearly*share3
						line3["text"]="About %s %s children conceived a year" % [amount_words(absf(yearly*share3)),"more" if share3>0.0 else "fewer"]
					else: line3["text"]="About %d%% %s births" % [maxi(1,roundi(absf(share3)*100.0)),"more" if share3>0.0 else "fewer"]
					(gains if share3>0.0 else costs).append(line3)
				"construction_rate":
					var pace:=1.0+float(WorldSimulation.discovery.effect("construction_rate"))+float(WorldSimulation.progression.effect("construction_rate"))+float(engine.policy_effect("construction_rate"))
					var share4:=v/maxf(0.2,pace)
					(gains if share4>0.0 else costs).append({"what":"building","percent":share4*100.0,"text":"Building goes about %d%% %s" % [roundi(absf(share4)*100.0),"faster" if share4>0.0 else "slower"]})
				"water_collection":
					var carried:=1.0+maxf(0.0,float(engine.policy_effect("water_collection")))
					var share5:=v/carried
					(gains if share5>0.0 else costs).append({"what":"water","percent":share5*100.0,"text":"Water carriers bring in about %d%% %s" % [roundi(absf(share5)*100.0),"more" if share5>0.0 else "less"]})
				"water_storage":
					gains.append({"what":"water_kept","days":v,"text":"Vessels keep about %s more days of water" % amount_words(v)})
				"stone_priority":
					var now:=maxf(0.0,float(engine.policy_effect("stone_priority")))
					var share6:=(1.0+(now+v)*3.0)/(1.0+now*3.0)-1.0
					gains.append({"what":"stone","percent":share6*100.0,"text":"Gatherers put stone first: about %d%% more weight on it" % roundi(share6*100.0)})
				"neonatal_survival":
					var survival:=clampf(float(WorldSimulation.discovery.effect("neonatal_survival"))+float(engine.policy_effect("neonatal_survival")),-0.5,0.6)
					var share7:=v/maxf(0.2,1.0-survival)
					(gains if share7>0.0 else costs).append({"what":"newborns","percent":share7*100.0,"text":"Newborn deaths %s about %d%%" % ["down" if share7>0.0 else "up",maxi(1,roundi(absf(share7)*100.0))]})
				_:
					if CARE_WORDS.has(channel) and v>0.0: gains.append({"what":channel,"text":String(CARE_WORDS[channel])})
		for direct_variant in (a.get("direct_effects_planned",{}) as Dictionary):
			var direct:=String(direct_variant)
			if not DIRECT_INPUTS.has(direct): continue
			var input2:=String(DIRECT_INPUTS[direct])
			var shift:=float((a.direct_effects_planned as Dictionary)[direct])
			# An immediate shift drifts back toward the unchanged target.
			var kept:=pow(1.0-float(DAILY_APPROACH.get(input2,0.0)),maxf(0.0,d))
			moves[input2]=float(moves.get(input2,0.0))+shift*kept
	out.days=roundi(days)
	# The strengths, by the order's last day.
	for entry in capacity_shift(moves):
		var line:={"what":String(entry.what),"points":float(entry.points),"text":_shift_text(entry)}
		if float(entry.points)>0.0: gains.append(line)
		else: costs.append(line)
	gains.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return _weight(x)>_weight(y))
	# The day's work: the labour channel and the stewards' upkeep of the order.
	var people:=_work_people(parts,labor_add)
	numbers["people_work"]=people
	if people<=-0.05: costs.push_front({"what":"work","people":-people,"text":_cap(people_words(people))})
	elif people>=0.05: gains.push_front({"what":"work","people":people,"text":"The work of about %d more %s" % [maxi(1,roundi(people)),"person" if roundi(people)<=1 else "people"] if people>=0.5 else "A little more work done"})
	if food>=0.5:
		numbers["food"]=food
		costs.append({"what":"food","amount":food,"text":"%s food from the stores now" % amount_words(food)})
	if materials>=0.5:
		numbers["materials"]=materials
		costs.append({"what":"materials","amount":materials,"text":"%s from the stores now" % _materials_words(materials)})
	rate/=float(maxi(1,parts.size()))
	numbers["implementation"]=rate
	numbers["resistance"]=resistance
	out.odds=_odds_words(rate,resistance,String(leader.get("name","")))
	out["rate"]=rate

static func _weight(line:Dictionary)->float:
	## Strengths by their points; a counted quantity ranks with a point.
	if line.has("points"): return absf(float(line.points))
	return 0.9

static func _work_people(parts:Array[Dictionary],labor_add:float)->float:
	## People's work the order adds (+) or takes (-): the labour channel and
	## the upkeep every standing order puts on the stewards, as a share of the
	## day's labour (process_day: (1+labour effects)*(1-upkeep)).
	var state=WorldSimulation.state
	var engine=WorldSimulation.consequences
	var able:=float(state.able_population())
	if able<=0.0: return 0.0
	var labor_now:=float(engine.policy_effect("labor_multiplier"))+float(state.founding_effect("labor_multiplier"))+float(WorldSimulation.progression.effect("labor_efficiency"))
	var loads:=_upkeep(parts)
	var before:=(1.0+labor_now)*(1.0-loads.x)
	var after:=(1.0+labor_now+labor_add)*(1.0-loads.y)
	if before<=0.01: return 0.0
	return able*(after/before-1.0)

static func _upkeep(parts:Array[Dictionary])->Vector2:
	## The stewards' load before and after, from the engine's own reckoning:
	## the orders stand in the list for one reading and are taken out again.
	var engine=WorldSimulation.consequences
	var before:=float(engine.governance_metrics().get("administrative_load",0.0))
	var list:Array=WorldSimulation.state.active_modifiers
	var day:=float(WorldSimulation.state.elapsed_days)
	var probes:Array[Dictionary]=[]
	for entry in parts:
		var a:Dictionary=entry.assessment
		var added:=float(entry.get("net_magnitude",a.get("effective_magnitude",0.0)))
		if added<=0.0: continue
		var probe:={"id":"__stakes_probe","kind":"policy","magnitude":added,"started_day":day-1.0,"until_day":day+maxf(1.0,float(a.get("duration_days",30.0))),
			"resistance":float(a.get("resistance",0.0)),"compliance":float(a.get("compliance",1.0)),"effects":{},"office":"Council"}
		list.append(probe)
		probes.append(probe)
	var after:=float(engine.governance_metrics().get("administrative_load",0.0))
	for probe in probes:
		for i in range(list.size()-1,-1,-1):
			if is_same(list[i],probe):
				list.remove_at(i)
				break
	return Vector2(before,after)

static func _materials_words(amount:float)->String:
	## The stores an order's materials come out of, in the order the engine
	## draws them (ConsequenceEngine._withdraw_directive_materials).
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles
	var names:Array[String]=[]
	for resource_variant in stock:
		var resource:=String(resource_variant)
		if resource in ["Food","Freshwater"]: continue
		names.append(resource)
	names.sort()
	var left:=amount
	var parts:PackedStringArray=PackedStringArray()
	for resource in names:
		if left<=0.05: break
		var take:=minf(left,maxf(0.0,float(stock.get(resource,0.0))))
		if take<0.05: continue
		parts.append("%s %s" % [amount_words(take),resource.to_lower()])
		left-=take
	if parts.is_empty(): return "%s materials" % amount_words(amount)
	return ", ".join(parts)

static func _expedition(out:Dictionary,a:Dictionary)->void:
	var quote:Dictionary=a.get("operation_quote",{}) if a.get("operation_quote") is Dictionary else {}
	if quote.is_empty(): return
	var party:=int(quote.get("personnel",0))
	var days:=float(quote.get("duration_days",90))
	(out.gains as Array).append({"what":"expedition","text":"A party of %d walks out for %s to find people willing to join us; they may bring families back, or no one" % [party,span_words(days)]})
	(out.costs as Array).append({"what":"away","people":float(party),"text":"%d of our people away for %s, with %s food for the road" % [party,span_words(days),amount_words(float(quote.get("provisions",0.0)))]})
	var risk:Dictionary=quote.get("field_risk",{}) if quote.get("field_risk") is Dictionary else {}
	if not risk.is_empty() and ResourceLoader.exists(SURVIVAL_PATH):
		(out.notes as Array).append("On the road: %s." % String((load(SURVIVAL_PATH) as GDScript).call("odds_phrase",risk)))
	out.days=maxi(int(out.days),roundi(days))

static func _odds_words(rate:float,resistance:float,leader:String)->String:
	var doing:="most people will do it" if rate>=MOST_DO else ("some will do it, many will not" if rate>=SOME_DO else "only a few will do it")
	var against:="many will refuse openly" if resistance>=MANY_REFUSE else ("some will grumble openly" if resistance>=SOME_GRUMBLE else "few will complain")
	var who:=_given(leader) if leader.strip_edges()!="" else ""
	if who!="": return "With %s leading it, %s; %s." % [who,doing,against]
	return "%s; %s." % [_cap(doing),against]

static func plain_blocker(assessment:Dictionary)->String:
	## Why an order cannot be carried out, in plain words.
	var text:=String(assessment.get("blocker","")).strip_edges()
	var lower:=text.to_lower()
	var constraints:Dictionary=assessment.get("constraints",{}) if assessment.get("constraints") is Dictionary else {}
	var reasons:PackedStringArray=PackedStringArray()
	if "required practice" in lower:
		var names:PackedStringArray=PackedStringArray()
		for id in ((constraints.get("knowledge",{}) as Dictionary).get("missing",[]) as Array):
			names.append(String(DiscoverySystem.discovery_definition(String(id)).get("name",String(id).replace("_"," "))).to_lower())
		reasons.append("we do not know how yet (%s)" % (", ".join(names) if not names.is_empty() else "a practice we lack"))
	if "administrative coverage" in lower: reasons.append("there are too few stewards to run it")
	if "enforcement capacity" in lower: reasons.append("there are too few guards to enforce it")
	if "food stores cannot fund" in lower: reasons.append("the stores cannot feed the work and keep two days in hand")
	if "material stores cannot fund" in lower: reasons.append("there are not enough materials in the stores")
	if "more standing directives" in lower: reasons.append("too many orders already stand")
	if "no recognized" in lower:
		var resource:=String((constraints.get("recognized_resource",{}) as Dictionary).get("name","")).to_lower()
		reasons.append("we know of no %s to use" % (resource if resource!="" else "source"))
	if "too low to produce" in lower: reasons.append("too few would take it up to make any difference")
	if not reasons.is_empty(): return "; ".join(reasons)
	return _lower(text.trim_suffix(".")) if text!="" else "the settlement cannot carry it out"

# --------------------------------------------------------------------------
# Finishing: the short line and the rows
# --------------------------------------------------------------------------

static func _finish(out:Dictionary)->Dictionary:
	out.short=_short(out)
	return out

static func _short(out:Dictionary)->String:
	## The card's second line: the largest gain (for how long) and the first
	## cost, e.g. "Logistics up about 1 point for eight moons; takes the work of
	## about 1 person".
	if bool(out.get("blocked",false)):
		var why:=String(out.get("blocker",""))
		return ("Cannot be done yet: %s" % why) if why!="" else "Cannot be done yet"
	var gains:Array=out.get("gains",[])
	var costs:Array=out.get("costs",[])
	var parts:PackedStringArray=PackedStringArray()
	var span:=span_words(float(out.days)) if int(out.get("days",0))>0 and String(out.kind) in ["decree","press"] else ""
	if bool(out.get("already",false)):
		# Ordered again: what changes against the order already standing.
		var biggest:Dictionary={}
		for entry in gains+costs:
			if (entry as Dictionary).has("points") and (biggest.is_empty() or absf(float(entry.points))>absf(float(biggest.points))): biggest=entry
		return "Already in force; %s" % (String(biggest.text).get_slice(" (",0) if not biggest.is_empty() else "little or nothing new")
	if not gains.is_empty():
		# The reason in brackets lives in the tooltip; the card keeps the change.
		parts.append(String((gains[0] as Dictionary).text).get_slice(" (",0)+(" for "+span if span!="" else ""))
	elif String(out.kind)=="decree": parts.append("Little or nothing new")
	if not costs.is_empty():
		var cost:Dictionary=costs[0]
		var said:=_lower(String(cost.text).get_slice(" (",0))
		if String(cost.get("what","")) in ["work","food","materials","away"]: said="takes "+said
		parts.append(said if not parts.is_empty() else _cap(said))
	var line:="; ".join(parts)
	if line.length()>96 and span!="": line=line.replace(" for "+span,"")
	return line

## Strengths and other entries a block row shows (the tooltip shows them all).
const ROW_STRENGTHS:=2
const ROW_OTHERS:=3

static func lines(stakes:Dictionary,full:bool=false)->Array[Dictionary]:
	## The block's rows: [{key, text, tone}] in reading order. full: every
	## gain and cost (the tooltip), else the largest few, and strengths moved
	## by at least 0.2 points.
	var rows:Array[Dictionary]=[]
	if stakes.is_empty(): return rows
	var kind:=String(stakes.get("kind",""))
	var gains:=_row_entries(stakes.get("gains",[]),full)
	var costs:=_row_entries(stakes.get("costs",[]),full)
	var gain_key:String={"decree":"You gain","aim":"If it is done","work":"If it stands","press":"Pressing gives"}.get(kind,"You gain")
	var cost_key:String={"decree":"It costs","aim":"If it fails","work":"It needs","press":"It costs"}.get(kind,"It costs")
	var span:=span_words(float(stakes.days)) if int(stakes.get("days",0))>0 and kind in ["decree","press"] else ""
	if bool(stakes.get("blocked",false)):
		rows.append({"key":"You gain","text":"Nothing: %s." % String(stakes.get("blocker","it cannot be done yet")),"tone":"cost"})
	elif not gains.is_empty():
		rows.append({"key":gain_key,"text":"; ".join(gains)+"."+(" The order runs %s." % span if span!="" else ""),"tone":"gain"})
	if not costs.is_empty():
		rows.append({"key":cost_key,"text":"; ".join(costs)+".","tone":"cost"})
	for extra in stakes.get("rows",[]):
		if extra is Dictionary: rows.append(extra)
	if String(stakes.get("odds",""))!="": rows.append({"key":"How likely","text":String(stakes.odds),"tone":"odds"})
	for note in stakes.get("notes",[]): rows.append({"key":"Mind","text":String(note),"tone":"odds"})
	if String(stakes.get("refusal",""))!="": rows.append({"key":String(stakes.get("refusal_key","If you say no")),"text":String(stakes.refusal),"tone":"refusal"})
	return rows

static func _row_entries(entries:Array,full:bool)->PackedStringArray:
	## A row's entries: every one for the tooltip; for the block the largest
	## strengths (at least 0.2 points after the first) and the other entries.
	var out:PackedStringArray=PackedStringArray()
	var strengths:=0
	var others:=0
	for entry_variant in entries:
		var entry:Dictionary=entry_variant
		if not full:
			if entry.has("points"):
				if strengths>=ROW_STRENGTHS or (strengths>0 and absf(float(entry.points))<0.2): continue
				strengths+=1
			else:
				if others>=ROW_OTHERS: continue
				others+=1
		# A strength keeps its name's capital; anything else reads as a clause.
		var text:=String(entry.text)
		out.append(text if entry.has("points") else (_cap(text) if out.is_empty() else _lower(text)))
	return out

static func tip(stakes:Dictionary)->String:
	## The whole of it, for a card's tooltip.
	var out:PackedStringArray=PackedStringArray()
	for row in lines(stakes,true): out.append("%s: %s" % [String(row.key),String(row.text)])
	return "\n".join(out)

static func voice_facts(stakes:Dictionary)->Dictionary:
	## Short, true sentences for the voice (audience_hall.voice_context).
	if stakes.is_empty(): return {}
	var facts:={}
	for row in lines(stakes):
		var key:=String(row.key).to_lower().replace(" ","_")
		facts[key]=(String(facts[key])+" "+String(row.text)) if facts.has(key) else String(row.text)
	# Durations as numbers too, so a live line may say "8 months" (a number a
	# line says must be one the facts give: audience_voice.allowed_numbers).
	if int(stakes.get("days",0))>0:
		facts["lasts_days"]=int(stakes.days)
		facts["lasts_months"]=maxi(1,roundi(float(stakes.days)/30.0))
	facts["for"]=String(stakes.get("subject",""))
	return facts

static func spoken(stakes:Dictionary,question:String)->String:
	## The speaker's own answer, from the stakes: "gain" (what do we get),
	## "ifno" (and if we refuse), "howlong" (how long would it run). "" when
	## the stakes do not answer it.
	if stakes.is_empty(): return ""
	var kind:=String(stakes.get("kind",""))
	match question:
		"gain":
			if bool(stakes.get("blocked",false)): return "Nothing, as things stand: %s." % String(stakes.get("blocker",""))
			var gains:PackedStringArray=PackedStringArray()
			for g in _row_entries(stakes.get("gains",[]),false):
				gains.append(String(g).get_slice(" (",0))
				if gains.size()>=2: break
			if gains.is_empty(): return ""
			# "If you order it: Logistics up about 1 point": a strength's name keeps
			# its capital; a clause after the colon starts small.
			var first_entry:Dictionary=(stakes.get("gains",[]) as Array)[0]
			if not first_entry.has("points"): gains[0]=_lower(gains[0])
			var lead:String={"decree":"If you order it","aim":"If we do it","work":"If it stands","press":"If you press them"}.get(kind,"If you order it")
			var span:=" by the end of %s" % span_words(float(stakes.days)) if int(stakes.get("days",0))>0 and kind in ["decree","press"] else ""
			if kind=="aim": span=", a lift that fades over the year after"
			var line:="%s: %s%s." % [lead," and ".join(gains),span]
			# An aim's costs are what failing it does; a work's, what it needs.
			var costs:Array=stakes.get("costs",[])
			if not costs.is_empty():
				var cost_entry:Dictionary=costs[0]
				var cost_text:=String(cost_entry.text).get_slice(" (",0)
				if not cost_entry.has("points"): cost_text=_lower(cost_text)
				var cost_lead:String={"aim":"If we fail: %s.","work":"It needs %s."}.get(kind,"It costs %s.")
				line+=" "+(cost_lead % (_cap(cost_text) if kind=="aim" else cost_text))
			if String(stakes.get("odds",""))!="": line+=" "+String(stakes.odds)
			return line
		"ifno":
			var said:=String(stakes.get("refusal_spoken",""))
			return said if said!="" else String(stakes.get("refusal",""))
		"howlong":
			if kind in ["decree","press"] and int(stakes.get("days",0))>0: return "It would run %s from the day you order it." % span_words(float(stakes.days))
			if kind=="work" and String(stakes.get("years",""))!="": return "%s of building." % _cap(String(stakes.years))
			if kind=="aim" and String(stakes.get("years",""))!="": return "The people would have %s." % String(stakes.years)
	return ""

# --------------------------------------------------------------------------
# Refusing a petition
# --------------------------------------------------------------------------

static func _hall()->GDScript:
	return load(HALL_PATH) as GDScript

static func petition_refusal(audience:Dictionary)->Dictionary:
	## What saying no to a decree petition costs (audience_hall._resolve_petition
	## and _after_resolve): {key, text, spoken}.
	var petition:Dictionary=audience.get("petition",{}) if audience.get("petition") is Dictionary else {}
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	var topic:=String(petition.get("topic",""))
	var who:=_given(String(speaker.get("name","")))
	var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0))) if int(speaker.get("person_id",0))>0 else {}
	var proud:=float(person.get("pride",0.5))>0.55
	var still:=_condition_now(topic)
	if topic=="introduction":
		return {"key":"If you give no task","text":"%s begins with no order; nothing changes yet." % who,"spoken":"Then I begin with nothing to do, and nothing changes yet."}
	var grudge:=proud and topic in ["ambition","follow_up","introduction"]
	var text:=""
	var said:=""
	if topic=="follow_up":
		text="%s feels deceived: less trust, more resentment." % who
		said="Then I'll know your promise meant nothing, and I won't forget it."
	else:
		text="%s trusts you less and resents it." % who
		said="Then I'll trust your word a little less, and I'll remember it."
	if grudge:
		text+=" %s is proud and will come back with a grievance." % who
		said+=" I'd be back about it."
	if still!="":
		text+=" "+still
		said+=" "+still
	return {"key":"If you say no","text":text,"spoken":said}

static func _condition_now(topic:String)->String:
	## The condition a petition was about, as it stands today.
	if not topic in ["food","health","housing","security","people","war"]: return ""
	var c:Dictionary=_hall().call("conditions")
	match topic:
		"food": return "The stores still last about %d days." % maxi(0,roundi(float(c.get("food_days",0.0))))
		"health": return "Health stays at about %d%%." % roundi(float(c.get("health",0.0))*100.0)
		"housing":
			var homeless:=maxi(0,roundi(float(c.get("population",0.0))-float(WorldSimulation.state.housing_capacity)))
			return ("About %d people still sleep without proper shelter." % homeless) if homeless>0 else ""
		"people":
			var decline:Dictionary=c.get("decline",{}) if c.get("decline") is Dictionary else {}
			return String(decline.get("summary",""))
		"security","war": return "The watch stays as it is."
	return ""

# --------------------------------------------------------------------------
# Legacy aims
# --------------------------------------------------------------------------

static func _aims()->GDScript:
	return load(AIMS_PATH) as GDScript

static func aim_ending(which:String)->Dictionary:
	## What an aim's end does, from legacy_aims.gd's own constants: the
	## strengths it moves and the officials' bonds. which: god, other, fail,
	## release, press.
	var aims:=_aims()
	var map:Dictionary=aims.get_script_constant_map()
	var moves:={}
	var bonds:={}
	match which:
		"god","other":
			moves={"legitimacy":float((map.FULFIL_LEGITIMACY as Dictionary)[which]),"cohesion":float(map.FULFIL_COHESION)}
			bonds=(map.FULFIL_BONDS as Dictionary)[which]
		"fail":
			moves=(map.FAIL_METRICS as Dictionary).duplicate()
			# The people's pride lightens the blame, as legacy_aims.fail applies it.
			moves["legitimacy"]=float(moves.get("legitimacy",0.0))*preload("res://scripts/standing.gd").blame()
			bonds=map.FAIL_BONDS
		"release":
			moves={"cohesion":float(map.RELEASE_COHESION)}
			bonds=map.RELEASE_BONDS
		"press":
			moves={"cohesion":float(map.PRESS_COHESION)}
			bonds=map.PRESS_BONDS
	return {"moves":moves,"bonds":bonds}

static func _ending_entries(which:String)->Array[Dictionary]:
	## An aim's end as entries: the strengths it moves (with their points) and
	## what it does to the officials' bonds.
	var ending:=aim_ending(which)
	var out:Array[Dictionary]=[]
	for entry in capacity_shift(ending.moves as Dictionary): out.append({"what":String(entry.what),"points":float(entry.points),"text":_shift_text(entry)})
	var bonds:Dictionary=ending.bonds
	var love:=float(bonds.get("love",0.0))
	var fear:=float(bonds.get("fear",0.0))
	var words:=""
	if love>0.0: words="Every official loves and trusts you more"
	elif love<0.0 and fear>0.0: words="Officials love you less and fear you more"
	elif love<0.0: words="Officials love you a little less"
	elif fear>0.0: words="Officials fear your eye more"
	if words!="": out.append({"what":"bonds","text":words})
	return out

static func for_aim(cand:Dictionary,mode:String="propose")->Dictionary:
	## The stakes of taking up one proposed aim: what fulfilling it gives (the
	## god's choice), what failing costs, what taking it up leans toward, and
	## the pace the people are on against its target.
	if cand.is_empty(): return {}
	var out:=_empty("aim",String(cand.get("title","")))
	var aims:=_aims()
	var years:=int(cand.get("years",5))
	out["years"]=String(aims.call("winters",years))
	for entry in _ending_entries("god"): (out.gains as Array).append(entry)
	var legacy:=String(cand.get("legacy",""))
	if legacy!="": (out.gains as Array).append({"what":"legacy","text":"Remembered as %s" % legacy})
	# The lift is a jump in the measures, which then drift back toward what
	# the rest of the world holds them to (process_day's daily smoothing).
	(out.gains as Array).append({"what":"fades","text":"The lift fades over the year after"})
	for entry in _ending_entries("fail"): (out.costs as Array).append(entry)
	var pace:=aim_pace(cand)
	out.odds=String(pace.get("text",""))
	out["pace_short"]=String(pace.get("short",""))
	var taking:PackedStringArray=PackedStringArray(["Nothing is spent now"])
	var lean:=_aim_lean(cand)
	if lean!="": taking.append(lean)
	var active:Dictionary=(aims.call("state") as Dictionary).get("active",{})
	if mode in ["crisis","renew"] and not active.is_empty():
		var set_down:=_row_entries(_ending_entries("release"),true)
		taking.append("it sets down %s: %s" % [String(active.get("title","our aim")),"; ".join(set_down) if not set_down.is_empty() else "a small grief"])
	var said:PackedStringArray=PackedStringArray()
	for part in taking: said.append(_cap(part))
	out["rows"]=[{"key":"Taking it up","text":". ".join(said)+".","tone":"odds"}]
	out.refusal=aim_refusal()
	out.short=String(out.pace_short) if String(out.pace_short)!="" else "%s; %s" % [_cap(String(out.years)),"nothing spent now"]
	return out

static func aim_refusal()->String:
	## "Not yet": the people wait, and an aim they take up themselves pays less
	## (legacy_aims.gd FULFIL_LEGITIMACY and FULFIL_BONDS by who chose it).
	var god:=_institutions_points("god")
	var other:=_institutions_points("other")
	var lift:=""
	if god>0.05 and other>0.05: lift=": Institutions up %s instead of %s, and half the officials' love" % [points_words(other).trim_prefix("about "),points_words(god).trim_prefix("about ")]
	return "The people wait. Stay silent too long and they take up an aim themselves; done by their own choice, it pays you less%s." % lift

static func _institutions_points(which:String)->float:
	for entry in capacity_shift(aim_ending(which).moves as Dictionary):
		if String(entry.what)=="institutions": return float(entry.points)
	return 0.0

static func _aim_lean(cand:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	if String(cand.get("template",""))=="learn" and String(cand.get("first",""))!="":
		var name:=String(DiscoverySystem.discovery_definition(String(cand.first)).get("name",String(cand.first).replace("_"," ")))
		parts.append("our keepers turn to %s at once" % name.to_lower())
	var focus:=String(cand.get("focus",""))
	if bool(PeopleDirection.get("auto_research")) and PeopleDirection.AMBITIONS.has(focus):
		var names:PackedStringArray=PackedStringArray()
		var chronicle:=load(CHRONICLE_PATH) as GDScript
		var domain_names:Dictionary=chronicle.get_script_constant_map().get("DOMAIN_NAMES",{})
		for domain in (PeopleDirection.AMBITIONS[focus] as Dictionary).get("domains",[]): names.append(String(domain_names.get(String(domain),String(domain))))
		if not names.is_empty(): parts.append("our questions lean toward %s" % " and ".join(names))
	return ", and ".join(parts)

static func aim_pace(cand:Dictionary)->Dictionary:
	## Where the people stand against the aim's target, and the pace they are
	## on, from the same readings the aim is measured by (legacy_aims.gd).
	var aims:=_aims()
	var template:=String(cand.get("template",""))
	var years:=int(cand.get("years",5))
	var winters:=String(aims.call("winters",years))
	var pop:=int(WorldSimulation.state.population_total)
	match template:
		"grow":
			var target:=int(cand.get("target",pop))
			var samples:=((aims.call("state") as Dictionary).get("pop_samples",[]) as Array).size()
			if samples<2: return {"text":"We are %d; it asks %d within %s. There is no count of our growth yet to judge the pace." % [pop,target,winters],"short":"We are %d; it asks %d in %s" % [pop,target,winters]}
			var trend:=float(aims.call("observed_growth"))
			var projected:=roundi(float(pop)*pow(1.0+trend/100.0,float(years)))
			return {"text":"At the pace of recent years (%s%.1f%% a year) we would be about %d by then; it asks %d." % ["+" if trend>=0.0 else "",trend,projected,target],"short":"At our pace, about %d of the %d in %s" % [projected,target,winters]}
		"knowledge":
			var pace:=float(aims.call("learning_pace"))
			var expected:=roundi(pace*float(years))
			var target2:=int(cand.get("target",0))
			return {"text":"At our pace (about %s new ways a year) we would learn about %d in %s; it asks %d." % [amount_words(pace),expected,winters,target2],"short":"At our pace, about %d new ways of the %d asked" % [expected,target2]}
		"learn":
			var domain:=String(cand.get("subject",""))
			var learned:=maxi(0,WorldSimulation.state.known_discoveries.size()-10)
			var share:=float(int(aims.call("known_in",domain))+2)/float(learned+12)
			var rate:=float(aims.call("learning_pace"))*share*(1.15 if bool(aims.call("_focus_aligned","learn")) else 1.0)
			var expected2:=roundi(rate*float(years))
			var target3:=int(cand.get("target",0))
			return {"text":"At our pace in %s (about %s new ways a year) we would learn about %d in %s; it asks %d." % [String(cand.get("subject_name",domain)),amount_words(rate),expected2,winters,target3],"short":"At our pace, about %d new ways of the %d asked" % [expected2,target3]}
		"work":
			var builders:=float(pop)*float(WorldSimulation.state.population_allocation_percentages.get("Construction",8.0))/100.0
			var per_year:=builders*float(cand.get("share",aims.get_script_constant_map().get("WORK_SHARE",0.12)))*365.0
			var target4:=float(cand.get("target",1.0))
			if per_year<=0.0: return {"text":"No one builds now; it would not rise at all.","short":"No builders to raise it"}
			var need:=target4/per_year
			return {"text":"At our builders' pace (%d of them, part of their days) it takes about %s; it has %s." % [roundi(builders),span_words(need*365.0),winters],"short":"Our builders need about %s of the %s" % [span_words(need*365.0),winters]}
		"plenty":
			var days:=roundi(float(WorldSimulation.state.simulation_metrics.get("food_days",0.0)))
			var threshold:=roundi(float(cand.get("threshold",30.0)))
			return {"text":"The stores hold about %d days now; it needs %d days or more on four days in five for %s." % [days,threshold,winters],"short":"Stores hold %d days now; it needs %d" % [days,threshold]}
		"unity":
			var now:=roundi(float(WorldSimulation.state.simulation_metrics.get("cohesion",0.58))*100.0)
			if bool(cand.get("hold",false)):
				var floor_points:=roundi(float(cand.get("threshold",0.66))*100.0)
				return {"text":"Holding together stands at %d now; it must stay at %d or more most days for %s." % [now,floor_points,winters],"short":"Holding together %d; it must stay above %d" % [now,floor_points]}
			var target5:=roundi(float(cand.get("target",0.6))*100.0)
			return {"text":"Holding together stands at %d now; it asks %d within %s." % [now,target5,winters],"short":"Holding together %d now; it asks %d" % [now,target5]}
		"friend":
			var hall:=_hall()
			var relation:Dictionary=(ForeignDiplomacy.civilization(String(cand.get("subject",""))).get("player_relation",{}) as Dictionary)
			var bands:=[[-0.4,"hostile"],[-0.1,"cool"],[0.15,"wary but civil"],[0.4,"friendly"],[1e9,"warm"]]
			var now2:=String(hall.call("_words",float(relation.get("opinion",cand.get("baseline",0.0))),bands))
			var want:=String(hall.call("_words",float(cand.get("target",0.4)),bands))
			return {"text":"They think of us as %s now; it asks %s." % [now2,want],"short":"They are %s to us; it asks %s" % [now2,want]}
		"fear":
			var hall2:=_hall()
			var dread_now:=String(hall2.call("_band_word",float(preload("res://scripts/divine_regard.gd").civ_dread(String(cand.get("subject",""))))))
			var dread_want:=String(hall2.call("_band_word",float(cand.get("target",0.3))))
			return {"text":"Their dread of us is %s now; it asks %s." % [dread_now,dread_want],"short":"Their dread: %s now; it asks %s" % [dread_now,dread_want]}
		"reach":
			if String(cand.get("subject",""))!="":
				return {"text":"We have seen their smoke; their fires are not found yet. It asks us to find them and sit with them within %s." % winters,"short":"Their fires are not found yet"}
			if bool(cand.get("reports",false)):
				var told:=int(cand.get("baseline",0))
				var told_words:="no tellings yet" if told<=0 else ("%d telling%s" % [told,"" if told==1 else "s"])
				return {"text":"Our walkers have brought back %s; it asks %d within %s." % [told_words,int(cand.get("target",0)),winters],"short":"%s; it asks %d" % [_cap(told_words),int(cand.get("target",0))]}
			return {"text":"It asks us to know half again as much land as we know, within %s." % winters,"short":"Half again as much land within %s" % winters}
		"settle":
			var count:=int(cand.get("baseline",WorldSimulation.state.player_settlements.size()))
			return {"text":"We hold %d hearth%s; it asks %d within %s." % [count,"" if count==1 else "s",int(cand.get("target",count+1)),winters],"short":"%s hearth%s now; it asks %d" % [_cap(_count(count)),"" if count==1 else "s",int(cand.get("target",count+1))]}
	return {"text":"","short":""}

static func for_aim_audience(audience:Dictionary)->Dictionary:
	## The block for an aim audience: what any aim brings and costs (the same
	## for each), with each candidate's own pace on its card.
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var part:Dictionary=situation.get("aim",{}) if situation.get("aim") is Dictionary else {}
	var mode:=String(part.get("mode","propose"))
	var aims:=_aims()
	if mode=="course": return for_press(audience)
	if mode=="halfway": return {}
	var first:Dictionary={}
	for row in part.get("candidates",[]):
		var cand:Dictionary=((aims.call("state") as Dictionary).get("candidates",{}) as Dictionary).get(String((row as Dictionary).get("cid","")),{})
		if not cand.is_empty(): first=cand; break
	if first.is_empty(): return {}
	var out:=for_aim(first,mode)
	out["subject"]="an aim"
	out.odds=""
	# The block speaks for every aim on offer: each card keeps its own legacy,
	# leanings and pace.
	out.gains=(out.gains as Array).filter(func(e:Dictionary)->bool: return String(e.get("what",""))!="legacy")
	var taking:PackedStringArray=PackedStringArray(["Nothing is spent now"])
	if bool(PeopleDirection.get("auto_research")): taking.append("What we study leans toward the aim's own field")
	var active:Dictionary=(aims.call("state") as Dictionary).get("active",{})
	if mode in ["crisis","renew"] and not active.is_empty():
		var set_down:=_row_entries(_ending_entries("release"),true)
		taking.append("It sets down %s: %s" % [String(active.get("title","our aim")),"; ".join(set_down) if not set_down.is_empty() else "a small grief"])
	out.rows=[{"key":"Taking one up","text":". ".join(taking)+".","tone":"odds"}]
	out["refusal_key"]="Not yet"
	out["refusal_spoken"]="Then the people wait. If you stay silent too long they will choose one themselves."
	return out

static func for_press(audience:Dictionary)->Dictionary:
	## Pressing an aim harder (legacy_aims._press): the people strain, the court
	## fears the god's eye, and the aim's own decree goes to the council.
	var aims:=_aims()
	var aim:Dictionary=(aims.call("state") as Dictionary).get("active",{})
	if aim.is_empty(): return {}
	var template:=String(aim.get("template",""))
	var decrees:Dictionary=aims.get_script_constant_map().get("PRESS_DECREES",{})
	var out:=_empty("press",String(aim.get("title","")))
	if decrees.has(template) and template!="friend":
		var decree:=for_decree(String(decrees[template]))
		if not decree.is_empty():
			out.gains=(decree.gains as Array).duplicate(true)
			out.costs=(decree.costs as Array).duplicate(true)
			out.notes=(decree.notes as Array).duplicate(true)
			out.odds=String(decree.odds)
			out.days=int(decree.days)
			out.blocked=bool(decree.blocked)
			out.blocker=String(decree.blocker)
			out["subject"]="\"%s\"" % String(decrees[template])
			# Pressing sends the aim's own decree to the civic council.
			(out.rows as Array).append({"key":"It orders","text":"\"%s\", sent to the council as a decree." % String(decrees[template]),"tone":"odds"})
	for entry in _ending_entries("press"): (out.costs as Array).append(entry)
	var people:=String(aim.get("subject_name",""))
	match template:
		"work":
			var map:Dictionary=aims.get_script_constant_map()
			(out.gains as Array).push_front({"what":"builders","text":"Builders give the work %d%% of their days instead of %d%%" % [roundi(float(map.get("WORK_PRESSED_SHARE",0.2))*100.0),roundi(float(aim.get("share",map.get("WORK_SHARE",0.12)))*100.0)]})
		"friend":
			(out.gains as Array).push_front({"what":"regard","text":"%s think better of us" % _cap(people if people!="" else "they")})
			(out.costs as Array).push_front({"what":"food","amount":float(aims.call("press_gift_food")),"text":"%s food from the stores, sent to them as a gift" % amount_words(float(aims.call("press_gift_food")))})
		"fear":
			(out.gains as Array).push_front({"what":"dread","text":"%s dread us more" % _cap(people if people!="" else "they")})
			(out.costs as Array).append({"what":"border","text":"the border grows tenser"})
	var release:=_row_entries(_ending_entries("release"),true)
	out.refusal="Letting the aim go: %s." % "; ".join(release) if not release.is_empty() else ""
	out["refusal_key"]="Letting it go"
	out["refusal_spoken"]="Letting it go would grieve the people, but less than failing."
	return _finish(out)

# --------------------------------------------------------------------------
# Great works
# --------------------------------------------------------------------------

static func _works()->GDScript:
	return load(WORKS_PATH) as GDScript

static func for_wonder(audience:Dictionary)->Dictionary:
	## The stakes of commissioning the chosen work at the chosen ambition.
	var works:=_works()
	var concept:Dictionary=works.call("chosen_concept",audience)
	if concept.is_empty(): return {}
	var p:Dictionary=works.call("proposal",audience)
	var ambition:=String(p.get("ambition","grand"))
	var assess:Dictionary=works.call("assessment",audience)
	var city:Dictionary={}
	for c in WorldSimulation.state.player_settlements:
		if c is Dictionary and String((c as Dictionary).get("id",""))==String(p.get("city_id","")): city=c
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	return for_work(concept,ambition,assess,String(city.get("name","")),String(speaker.get("name","")))

static func for_work(concept:Dictionary,ambition:String,assess:Dictionary,place:String="",pitched_by:String="")->Dictionary:
	var script:=load(CONCEPT_PATH) as GDScript
	var works:=_works()
	var name:=String(works.call("concept_name",concept))
	var out:=_empty("work",name)
	var parsed:Dictionary=script.call("parse",String(concept.get("id","")))
	if parsed.is_empty(): return {}
	var map:Dictionary=script.get_script_constant_map()
	var purpose:=String(parsed.purpose)
	var here:=" in %s" % place if place!="" else ""
	# What it gives if it stands, at the condition a standing work keeps.
	var standing:=float((map.OUTCOME_CONDITION as Dictionary).get("success",0.9))
	var rewards:Dictionary=script.call("rewards_for",purpose,ambition,"success")
	for key in rewards:
		var value:=float(rewards[key])*standing
		match String(key):
			"research": (out.gains as Array).append({"what":"research","percent":value*100.0,"text":"Research about %d%% faster%s" % [maxi(1,roundi(value*100.0)),here]})
			"craft": (out.gains as Array).append({"what":"craft","percent":value*100.0,"text":"Crafting about %d%% more effective%s" % [maxi(1,roundi(value*100.0)),here]})
			"food_capacity": (out.gains as Array).append({"what":"food_store","amount":value,"text":"Room to store about %s more rations of food" % EraWords.grouped(roundi(value))})
			"water_capacity": (out.gains as Array).append({"what":"water_store","amount":value,"text":"Room to keep about %s more units of water" % EraWords.grouped(roundi(value))})
			"spoilage": (out.gains as Array).append({"what":"spoilage","percent":value*100.0,"text":"About %d%% less stored food spoils" % maxi(1,roundi(value*100.0))})
			"attraction": (out.gains as Array).append({"what":"attraction","text":"Households drawn to settle%s (they still have to make the journey)" % here})
			"reputation": (out.gains as Array).append({"what":"reputation","text":"Other peoples who hear of it receive us more warmly"})
	var family:=String((map.PURPOSES as Dictionary).get(purpose,{}).get("family",""))
	var family_words:={"civic":"it steadies cohesion and legitimacy","covenant":"it seals a famine reserve from real surplus","watching_sky":"its watchers forecast lean seasons and famine","long_song":"it keeps leaders' memories and lost knowledge","deterrence":"rivals weigh war against us more gravely","traffic":"it draws envoys, traders and refugees"}
	if family_words.has(family): (out.gains as Array).append({"what":"family","text":_cap(String(family_words[family]))})
	# What it needs.
	var cost_words:=String(works.call("costs_words",assess.get("costs",concept.get("cost",{}))))
	if cost_words!="": (out.costs as Array).append({"what":"materials","text":cost_words})
	var time:=String(works.call("duration_words",assess.get("duration_estimate","")))
	if time!="":
		(out.costs as Array).append({"what":"years","text":"%s of our builders' work" % time})
		out["years"]=time
	for factor in assess.get("factors",[]):
		if factor is Dictionary and String((factor as Dictionary).get("name",""))=="Materials": (out.notes as Array).append(String(factor.get("text","")))
	# The odds of each outcome (WonderConcept.odds of the feasibility score).
	var odds:Dictionary=assess.get("odds",{}) if assess.get("odds") is Dictionary else {}
	if not odds.is_empty():
		var stands:=float(odds.get("success",0.0))+float(odds.get("triumph",0.0))
		var parts:PackedStringArray=PackedStringArray()
		parts.append("It stands whole %s" % _in_ten(stands))
		if float(odds.get("triumph",0.0))>=0.05: parts.append("a triumph that gives more %s" % _in_ten(float(odds.triumph)))
		parts.append("stands flawed, giving half, %s" % _in_ten(float(odds.get("flawed",0.0))))
		parts.append("falls %s" % _in_ten(float(odds.get("collapse",0.0))))
		out.odds="; ".join(parts)+"."
		out.numbers=odds.duplicate()
	var who:=_given(pitched_by) if pitched_by.strip_edges()!="" else "the one who pitched it"
	out.refusal="Not yet: nothing is spent and they may ask again. Calling it folly: %s resents it." % who
	out["refusal_key"]="If you say no"
	out["refusal_spoken"]="Then nothing is spent, and I will ask again another year."
	out.short=_work_short(out)
	return out

static func _in_ten(chance:float)->String:
	if chance<0.05: return "rarely"
	if chance>0.95: return "almost always"
	return "about %d in 10" % clampi(roundi(chance*10.0),1,9)

static func _work_short(out:Dictionary)->String:
	## "If it stands: research about 7% faster here; falls about 6 in 10": the
	## first reward and the likeliest outcome.
	var gains:Array=out.gains
	var first:=String((gains[0] as Dictionary).text) if not gains.is_empty() else "a great work"
	var odds:Dictionary=out.get("numbers",{})
	var likeliest:=""
	if not odds.is_empty():
		var stands:=float(odds.get("success",0.0))+float(odds.get("triumph",0.0))
		var flawed:=float(odds.get("flawed",0.0))
		var falls:=float(odds.get("collapse",0.0))
		if stands>=flawed and stands>=falls: likeliest="stands whole %s" % _in_ten(stands)
		elif falls>=flawed: likeliest="falls %s" % _in_ten(falls)
		else: likeliest="stands flawed %s" % _in_ten(flawed)
	return ("If it stands: %s; %s" % [_lower(first),likeliest]) if likeliest!="" else "If it stands: %s" % _lower(first)

# --------------------------------------------------------------------------
# The audience and its cards
# --------------------------------------------------------------------------

static func for_audience(audience:Dictionary)->Dictionary:
	## The stakes of the audience's proposal (the block above the answers), {}
	## when it proposes nothing to weigh.
	if audience.is_empty() or String(audience.get("status",""))!="waiting": return {}
	# An envoy's request: the deal as each side counts it (envoy_deals.gd).
	if String(audience.get("origin",""))=="foreign": return (load("res://scripts/envoy_requests.gd") as GDScript).call("stakes",audience)
	if String(audience.get("origin",""))!="court": return {}
	match String(audience.get("kind","")):
		"wonder_proposal": return for_wonder(audience)
		"great_work":
			var decree:=String((audience.get("petition",{}) as Dictionary).get("suggested_decree","")) if audience.get("petition") is Dictionary else ""
			if decree=="" or String((audience.get("great_work",{}) as Dictionary).get("mode",""))!="forecast": return {}
			var heeded:=for_decree(decree)
			if heeded.is_empty(): return {}
			heeded.refusal="Noted: no order is given before the lean days."
			heeded["refusal_key"]="If you only note it"
			heeded["refusal_spoken"]="Then we meet the lean days as we are."
			return heeded
		"petition":
			var petition:Dictionary=audience.get("petition",{}) if audience.get("petition") is Dictionary else {}
			var topic:=String(petition.get("topic",""))
			if topic=="aim": return for_aim_audience(audience)
			if topic in NO_STAKES_TOPICS: return {}
			var decree2:=String(petition.get("suggested_decree",""))
			if decree2=="": return {}
			var stakes:=for_decree(decree2)
			if stakes.is_empty(): return {}
			var refusal:=petition_refusal(audience)
			stakes.refusal=String(refusal.text)
			stakes["refusal_key"]=String(refusal.key)
			stakes["refusal_spoken"]=String(refusal.spoken)
			return stakes
	return {}

static func for_option(audience:Dictionary,option:Dictionary)->Dictionary:
	## The stakes of one answer card, {} for answers that propose nothing.
	if audience.is_empty() or not bool(option.get("enabled",true)): return {}
	var id:=String(option.get("id",""))
	var kind:=String(audience.get("kind",""))
	if kind=="wonder_proposal": return for_wonder(audience) if id=="commission" else {}
	if kind=="great_work":
		if id=="decree": return for_audience(audience)
		if id=="decree_gather": return for_decree("Send gatherers to find food")
		return {}
	if kind!="petition": return {}
	var petition:Dictionary=audience.get("petition",{}) if audience.get("petition") is Dictionary else {}
	if String(petition.get("topic",""))=="aim":
		if id.begins_with("aim_adopt:"):
			var cand:Dictionary=((_aims().call("state") as Dictionary).get("candidates",{}) as Dictionary).get(id.trim_prefix("aim_adopt:"),{})
			var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
			return for_aim(cand,String((situation.get("aim",{}) as Dictionary).get("mode","propose")))
		if id=="aim_press": return for_press(audience)
		return {}
	if id in DECREE_OPTIONS: return for_audience(audience)
	return {}

static func annotate(audience:Dictionary,options:Array)->void:
	## The court's cards for a proposal carry its stakes: the second line is
	## the short gain and cost, the tooltip the whole of it. A crisis answer's
	## cost tag is said in plain words.
	for option_variant in options:
		if not option_variant is Dictionary: continue
		var option:Dictionary=option_variant
		var cost:=String(option.get("cost",""))
		if cost!="" and not option.has("cost_words"): option["cost_words"]=cost_tag_words(cost)
		var stakes:=for_option(audience,option)
		if stakes.is_empty(): continue
		var short:=String(stakes.get("pace_short","")) if String(stakes.get("kind",""))=="aim" else String(stakes.get("short",""))
		if short=="": continue
		option["stakes_short"]=short
		option["stakes_tip"]=tip(stakes)

static func cost_tag_words(cost:String)->String:
	## A crisis answer's cost tag ("labour", "String: their anger") in plain words.
	var clean:=cost.strip_edges()
	for prefix in ["String: ","Cost: ","Risk: "]: clean=clean.trim_prefix(prefix)
	clean=clean.strip_edges().trim_suffix(".")
	return String(COST_TAG_WORDS.get(clean.to_lower(),clean))
