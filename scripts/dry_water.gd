extends RefCounted
## DRY YEARS IN THE WATER LEDGER. A dry year (crisis_system.gd "drought", the
## same onset odds, timing and draw for every people) now dries the springs:
## each town's water day (resource_system.gd _process_water_flow) loses a share
## of what its near sources give, the store falls, and when it runs out the
## people go thirsty and the thirst kills on the engine's own rate
## (thirst_rate, consequence_engine.gd "Dehydration"). What water cannot fix
## (the heat, the failed forage, the sickness of foul water) is the dry year's
## own smaller toll, "Drought" (toll_share).
##
## The user lost eleven to "thirst" while every store was full: the toll was
## fixed at the start and never touched the water. Now the WATER tile moves
## day by day with the store, and the card's forecast (forecast) runs the same
## arithmetic forward.
##
## One rule for every people (the god's at court, every other through
## crisis_unattended.gd) and the fast sim (tools/sim/crisis.py mirrors it).
##
## How deep: at its worst a dry year takes depth() of the near water: the
## season's dryness (the crisis's sev) plus DEPTH_LUCK for each standard
## deviation of its own draw above the median (the draw crisis_system.gd has
## always made). It comes over RISE_DAYS and goes over the last FALL_DAYS.
##
## What holds: groundwater (a developed deep aquifer or a confirmed well,
## water_waste_works.gd; the builders' wells, built_fabric.gd works cover
## "water") keeps part of the loss away (held); a water line's distant intake
## loses only CONVEY_FAIL of it, up to the line's own throughput; a cistern
## holds 2.5 days more for everyone (water_waste_works.gd) though its rain
## fails; the far pools give up to FAR_POOLS of the day's need, a long walk
## away. Families reach FAR_SELF of them on their own; the answer "carry"
## (policy channel water_far) sends every strong back and reaches them all.

## The springs fail over the first days of a dry year and come back over its last.
const RISE_DAYS:=30.0
const FALL_DAYS:=30.0
## The worst share of the near water lost: sev + DEPTH_LUCK x the draw's luck.
const DEPTH_LUCK:=0.18
const DEPTH_MAX:=0.95
## The draw's median and its dryness scale (crisis_system.gd _open_drought:
## lognormal(DRAW_MEDIAN) x (1 + DRAW_SEV x sev)).
const DRAW_MEDIAN:=0.002
const DRAW_SEV:=4.0
## Groundwater: a developed deep aquifer or confirmed well keeps this share of
## the loss away; the builders' wells this share at full cover.
const DEEP_WELL_HOLD:=0.7
const WELLS_HOLD:=0.5
## A water line's intake is a distant source: it loses this share of the loss.
const CONVEY_FAIL:=0.5
## The far pools: at most this share of a town's daily need, failing at
## FAR_FAIL of the near loss, FAR_KM more to walk for the carriers.
const FAR_POOLS:=0.40
const FAR_FAIL:=0.5
const FAR_KM:=10.0
## The share of the far pools the families reach without an order.
const FAR_SELF:=0.5
## The answers that send people to the far water (policy channel water_far).
const CARRY_REACH:=0.5
const RIVER_CAMP_REACH:=0.75
## The dry year's own toll, a share of the people: TOLL_K x the draw's median
## for this dryness, less TOLL_HELD_CUT of it for the share that drank.
const TOLL_K:=2.0
const TOLL_HELD_CUT:=0.5
## The thirst death rate (a year's share of the people) at a drinking deficit:
## deficit^3 x (THIRST_BASE + THIRST_RAMP once short THIRST_RAMP_DAYS + 1 days).
const THIRST_BASE:=0.35
const THIRST_RAMP:=5.0
const THIRST_RAMP_DAYS:=4.0
## The most a town draws in a day: this many times its need (resource_system.gd).
const DRAW_CAP:=1.35
## Each cistern holds this many days for every person (water_waste_works.gd).
const CISTERN_DAYS:=2.5

# --------------------------------------------------------------------------
# The rules (pure: tests, the forecast and tools/sim/crisis.py use them)
# --------------------------------------------------------------------------

## The year's thirst death rate at a day's drinking `intake` (0..1) after
## `shortage_days` short (consequence_engine.gd "Dehydration"). A small miss is
## lost resilience; a sustained total loss of water is quickly catastrophic.
static func thirst_rate(intake:float,shortage_days:float)->float:
	var deficit:=clampf(1.0-intake,0.0,1.0)
	var ramp:=clampf((shortage_days-1.0)/THIRST_RAMP_DAYS,0.0,1.0)
	return pow(deficit,3.0)*(THIRST_BASE+ramp*THIRST_RAMP)

## How deep a dry year goes at its worst (0..DEPTH_MAX), from its dryness and
## its own draw.
static func depth(sev:float,draw:float)->float:
	return clampf(sev+DEPTH_LUCK*luck(sev,draw),0.0,DEPTH_MAX)

## The draw in standard deviations above its median for this dryness.
static func luck(sev:float,draw:float)->float:
	var median:=DRAW_MEDIAN*(1.0+DRAW_SEV*sev)
	return log(maxf(draw,1e-9)/median)

## The share of the near water a dry year takes on `day`.
static func loss(c:Dictionary,day:float)->float:
	return depth_of(c)*ramp(c,day)

static func depth_of(c:Dictionary)->float:
	if c.has("depth"):return float(c.depth)
	return depth(float(c.get("sev",0.0)),float(c.get("draw",c.get("m",0.0))))

## 0 at the dry year's start, 1 after RISE_DAYS, back to 0 at its end.
static func ramp(c:Dictionary,day:float)->float:
	var start:=float(c.get("start",day))
	var end:=float(c.get("end_day",day))
	return clampf((day-start)/RISE_DAYS,0.0,1.0)*clampf((end-day)/FALL_DAYS,0.0,1.0)

## The share of a dry year's loss a town's groundwater keeps away.
static func held_by(deep_well:bool,wells_cover:float)->float:
	return 1.0-(1.0-(DEEP_WELL_HOLD if deep_well else 0.0))*(1.0-WELLS_HOLD*clampf(wells_cover,0.0,1.0))

## One day of a town's drawn water (resource_system.gd _process_water_flow,
## every day, dry year or not, and forecast). `parts`: need (the day's whole
## need), cap (DRAW_CAP x need), near (what households and carriers would
## bring from the near sources, before the cap), household (the households'
## own part of it), flow, organized (the carriers' own capacity at the near
## walk), line (the water lines' throughput today), rain, cistern (capacity),
## accessible (a source within reach). `loss_today` the dry year's loss,
## `held` the share the groundwater keeps away, `reach` the share of the far
## pools reached. With no loss it is the ordinary day exactly.
## {collected, near, far, conveyed, rain, lost (the near share lost)}.
static func collect(parts:Dictionary,loss_today:float,held:float,reach_share:float)->Dictionary:
	var accessible:=bool(parts.get("accessible",true))
	var need:=float(parts.get("need",0.0))
	var cap:=float(parts.get("cap",need*DRAW_CAP))
	var lost:=clampf(loss_today*(1.0-clampf(held,0.0,1.0)),0.0,1.0)
	var flow:=float(parts.get("flow",1.0))
	var near:=(1.0-lost)*minf(cap,float(parts.get("near",0.0)))*flow if accessible else 0.0
	var far:=0.0
	if loss_today>0.0 and accessible:
		far=minf(FAR_POOLS*need*clampf(reach_share,0.0,2.0)*(1.0-FAR_FAIL*loss_today),float(parts.get("organized",0.0))/(1.0+FAR_KM*0.16))*flow
	# A line delivers what it can past the households' own fetching, its
	# distant intake failing at CONVEY_FAIL of the loss.
	var household:=(1.0-lost)*float(parts.get("household",0.0))*flow if accessible else 0.0
	var conveyed:=minf(float(parts.get("line",0.0))*(1.0-CONVEY_FAIL*loss_today),maxf(0.0,cap-household))
	var rain:=float(parts.get("rain",0.0))*(1.0-loss_today)
	return {"collected":minf(cap+float(parts.get("cistern",0.0)),near+far+conveyed+rain),"near":near,"far":far,"conveyed":conveyed,"rain":rain,"lost":lost}

## The dry year's own share of the people (the heat, the failed forage, the
## sickness of foul water), from its dryness and the share that drank.
static func toll_share(sev:float,held_intake:float)->float:
	return DRAW_MEDIAN*(1.0+DRAW_SEV*sev)*TOLL_K*(1.0-TOLL_HELD_CUT*clampf(held_intake,0.0,1.0))

## The share of the far pools reached under `water_far` (the answers' policy).
static func reach(water_far:float)->float:
	return FAR_SELF+maxf(0.0,water_far)

# --------------------------------------------------------------------------
# The people in scope
# --------------------------------------------------------------------------

## The running dry year of the people in scope ({} when none).
static func running()->Dictionary:
	var audiences:Variant=WorldSimulation.diplomacy.audiences if WorldSimulation.diplomacy!=null else {}
	var s:Variant=(audiences as Dictionary).get("crises",{}) if audiences is Dictionary else {}
	if not s is Dictionary or not (s as Dictionary).get("active") is Dictionary:return {}
	for c:Variant in (s.active as Dictionary).values():
		if c is Dictionary and String(c.get("type",""))=="drought" and String(c.get("phase","")) in ["open","mid"]:return c
	return {}

## Today's loss for the town in scope (0 with no dry year).
static func loss_now()->float:
	var c:=running()
	return 0.0 if c.is_empty() else loss(c,float(WorldSimulation.state.elapsed_days))

## Every lived-in town of the people in scope: [{name, water (its last water
## day), shortage_days, population}], the capital first.
static func towns()->Array:
	var out:Array=[]
	var state=WorldSimulation.state
	out.append({"name":String(state.settlement_name),"water":(state.water_metrics as Dictionary),"shortage_days":float(state.consecutive_water_shortage_days)})
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)) or String(city.get("occupied_by","")) not in ["","player"]:continue
		var local:Variant=city.get("local_resources",{})
		if not local is Dictionary:continue
		var water:Variant=(local as Dictionary).get("water_metrics",{})
		if not water is Dictionary or (water as Dictionary).is_empty():continue
		out.append({"name":String(city.get("name","")),"water":water,"shortage_days":float((local as Dictionary).get("consecutive_water_shortage_days",0.0))})
	for town:Dictionary in out:town["population"]=float((town.water as Dictionary).get("required_today",0.0))
	return out.filter(func(t:Dictionary)->bool:return float(t.population)>0.0)

## Today's drinking across the people's towns, people-weighted (1 = all drank).
static func intake_now()->float:
	var people:=0.0;var drank:=0.0
	for town:Dictionary in towns():
		people+=float(town.population)
		drank+=float(town.population)*clampf(float((town.water as Dictionary).get("intake_ratio",1.0)),0.0,1.0)
	return drank/people if people>0.0 else 1.0

## The water_far reach the answers give on `day` (from the people's own
## policy records, as consequence_engine.policy_effect reads them).
static func far_policy_on(day:float)->float:
	var total:=0.0
	for modifier:Variant in WorldSimulation.state.active_modifiers:
		if not modifier is Dictionary or String(modifier.get("kind",""))!="policy":continue
		if day>float(modifier.get("until_day",-INF)) or float(modifier.get("started_day",-INF))>day:continue
		var effects:Dictionary=modifier.get("effects",{}) if modifier.get("effects") is Dictionary else {}
		if effects.has("water_far"):total+=clampf(float(modifier.get("magnitude",0.0)),-0.35,0.35)*float(effects.water_far)
	return clampf(total,-1.0,1.0)

## The people's days of water held: every town's store over its drinking.
static func store_days()->float:
	var stored:=0.0;var drinking:=0.0
	for town:Dictionary in towns():
		stored+=float((town.water as Dictionary).get("stored",0.0))
		drinking+=float((town.water as Dictionary).get("required_today",0.0))
	return stored/drinking if drinking>0.0 else -1.0

## "The near springs give about 4 in 10 of what they did; the water stores
## hold 2.1 days." from the ledger.
static func springs_words(c:Dictionary,day:float)->String:
	var left:=clampi(roundi((1.0-loss(c,day))*10.0),0,10)
	var days:=store_days()
	var held:="" if days<0.0 else ("; the water stores are empty" if days<0.05 else "; the water stores hold %s days" % (str(roundi(days)) if days>=10.0 else "%.1f" % days))
	return "The near springs give about %d in 10 of what they did%s." % [left,held]

# --------------------------------------------------------------------------
# The forecast: the same arithmetic run forward to the dry year's end
# --------------------------------------------------------------------------

## What the rest of dry year `c` will take, as things stand, from each town's
## last water day. As things stand includes the holder's own course when the
## god stays silent (carrying from the decision day). `change`: {choice: an
## answer given today ("carry", "river_camp", or any other, which carries
## nothing), far: an explicit reach of the far pools for far_days from
## far_from days ahead, carriers: share of each town's people more on the
## water path, cistern: true (a lined cistern in every town), toll_factor: on
## the dry year's own toll}.
## {thirst, toll, total, held (the people's mean drinking ahead), dry_day (the
## first day a store runs dry, -1 when none), towns: [{name, thirst, dry_day,
## low_days}]}.
static func forecast(c:Dictionary,town_list:Array,today:float,change:Dictionary={})->Dictionary:
	var end:=float(c.get("end_day",today))
	var out:={"thirst":0.0,"toll":0.0,"total":0.0,"held":1.0,"dry_day":-1,"towns":[]}
	var people_days:=0.0;var drank_days:=0.0
	# The far water ordered ahead: an explicit change, an answer chosen today,
	# or, while the god is silent, the holder's own course at the decision
	# day (crisis_system.gd _default_choice: carry, for 90 days).
	var extra:=0.0;var extra_from:=today;var extra_until:=today
	var choice:=String(change.get("choice",""))
	if change.has("far"):
		extra=float(change.far);extra_from=today+float(change.get("far_from",0.0));extra_until=extra_from+float(change.get("far_days",1e9))
	elif choice=="carry":
		extra=CARRY_REACH;extra_until=today+90.0
	elif choice=="river_camp":
		extra=RIVER_CAMP_REACH;extra_until=today+60.0
	elif choice=="" and String(c.get("phase","open"))=="open" and String(c.get("choice",""))=="":
		extra=CARRY_REACH;extra_from=maxf(today,float(c.get("decide_by",c.get("start",today))));extra_until=extra_from+90.0
	for town:Dictionary in town_list:
		var w:Dictionary=town.water
		var people:=float(town.population)
		if people<=0.0:continue
		var parts:Dictionary=(w.get("dry_parts",{}) as Dictionary).duplicate() if w.get("dry_parts") is Dictionary else {}
		if parts.is_empty():parts=_parts_from(w)
		var added:=float(change.get("carriers",0.0))*people
		if added>0.0:
			# More on the water path: each brings what today's carriers bring.
			var per:=float(parts.get("organized",0.0))/maxf(0.5,float(w.get("collection_workers",1.0)))
			parts.organized=float(parts.get("organized",0.0))+per*added
			parts.near=float(parts.get("near",0.0))+per*added
		var capacity:=float(w.get("capacity",0.0))
		var store:=float(w.get("stored",0.0))
		if bool(change.get("cistern",false)):
			capacity+=people*CISTERN_DAYS
			parts.cistern=float(parts.get("cistern",0.0))+people*CISTERN_DAYS
		var held:=float(parts.get("held",0.0))
		var shortage:=float(town.get("shortage_days",0.0))
		var drinking0:=float(w.get("required_today",people))
		var dead:=0.0
		var low:=0
		var dry_day:=-1
		var day:=today+1.0
		while day<=end:
			var scale:=maxf(0.0,people-dead)/people
			var day_parts:=parts.duplicate()
			for key in ["need","cap","near","household","organized","rain","cistern"]:day_parts[key]=float(parts.get(key,0.0))*scale
			var water_far:=far_policy_on(day)+(extra if day>extra_from and day<=extra_until else 0.0)
			var got:=collect(day_parts,loss(c,day),held,reach(water_far))
			var drinking:=drinking0*scale
			var available:=minf(capacity*scale,store+float(got.collected))
			var drunk:=minf(drinking,available)
			var rest:=maxf(0.0,available-drunk)
			store=maxf(0.0,rest-minf(rest,float(day_parts.need)-drinking))
			var intake:=drunk/maxf(0.001,drinking)
			if intake<0.98:
				shortage+=1.0;low+=1
				if dry_day<0:dry_day=int(day)
			else:shortage=maxf(0.0,shortage-2.0)
			dead+=(people-dead)*thirst_rate(intake,shortage)/365.0
			people_days+=drinking;drank_days+=drunk
			day+=1.0
		out.thirst=float(out.thirst)+dead
		if dry_day>=0 and (int(out.dry_day)<0 or dry_day<int(out.dry_day)):out.dry_day=dry_day
		(out.towns as Array).append({"name":String(town.get("name","")),"thirst":dead,"dry_day":dry_day,"low_days":low})
	out.held=drank_days/people_days if people_days>0.0 else 1.0
	# The dry year's own toll still to come: the turn takes 0.4 of it, the end 0.6.
	var share:=0.6 if String(c.get("phase","open"))=="mid" else 1.0
	var mult:=float(c.get("mult",1.0))*float(change.get("toll_factor",1.0))
	var held_mean:=(float(c.get("held_sum",0.0))+float(out.held)*maxf(1.0,end-today))/maxf(1.0,float(c.get("held_days",0.0))+maxf(1.0,end-today))
	out.toll=float(c.get("pop0",0))*toll_share(float(c.get("sev",0.0)),held_mean)*mult*share
	out.total=float(out.thirst)+float(out.toll)
	return out

## The parts of an older water day that kept none (before dry years drained it).
static func _parts_from(w:Dictionary)->Dictionary:
	var need:=float(w.get("total_required_today",w.get("required_today",0.0)))
	return {"need":need,"cap":need*DRAW_CAP,"near":float(w.get("household_collected_today",0.0))+float(w.get("organized_collection_capacity",0.0)),"household":float(w.get("household_collected_today",0.0)),
		"flow":1.0,"organized":float(w.get("organized_collection_capacity",0.0)),"line":float(w.get("conveyed_today",0.0)),"rain":float(w.get("rain_collected_today",0.0)),
		"cistern":float(w.get("cistern_capacity",0.0)),"accessible":bool(w.get("source_accessible",true)),
		# The builders' wells of the people in scope (built_fabric.gd), as the town's own day would hold.
		"held":held_by(false,float((load("res://scripts/built_fabric.gd") as GDScript).call("works_cover","water")))}
