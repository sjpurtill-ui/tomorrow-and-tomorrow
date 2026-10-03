extends RefCounted
## CRISES FOR EVERY PEOPLE. The god's own people meet their crises at court
## (crisis_system.gd). Every other people meets the same crises: the same
## hazards read from its own state (CrisisSystem.inputs and hazards, run in its
## own scope), the same death draws and the same floors, and the answers the
## court's official gives when the god stays silent (CrisisSystem.
## _default_choice), paid out of that people's own stores, roofs and labour.
## Nothing is told and no one is named: only what happens.
##
## A computer ruler answers at once, as an attentive ruler would; the timed
## effects run on that people's own policy channels (active_modifiers), and
## deaths come out of its own population through register_population_deaths.
## State lives in that people's own court block (CrisisSystem.state() in its
## scope), so it is saved and validated with it.

const CS:=preload("res://scripts/crisis_system.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")

## The god's people are handled by the court; this runs every other people's.
static func daily(day:int)->void:
	if WorldSimulation.actor_id=="player": return
	var people=WorldSimulation.state
	if not bool(people.settlement_site_committed) or int(people.settlement_founded_day)<0: return
	var s:=CS.state()
	var from:=int(s.last_day)
	if from>=day: return
	var first:=from<=0
	s.last_day=day
	# A calm people may be stepped several days at once (day_span.gd); the
	# drift and the onset rolls cover every day stepped.
	var span:=1 if first else clampi(day-from,1,30)
	var x:=CS.inputs(day)
	s.immunity=float(s.immunity)*pow(0.962,float(span)/365.0)
	var target_pool:=clampf(0.1+0.6*float(x.dens)+0.3*float(x.trade),0.0,1.0)
	if first and float(s.pool)<=0.0: s.pool=target_pool
	s.pool=float(s.pool)+(target_pool-float(s.pool))*0.01*float(span)/365.0
	for key in (s.active as Dictionary).keys():
		var c:Variant=(s.active as Dictionary).get(key)
		if c is Dictionary: _advance(s,c,day,x)
	if day-int(people.settlement_founded_day)<CS.QUIET_AFTER_FOUNDING: return
	if (s.active as Dictionary).size()>=CS.ACTIVE_MAX or day-int(s.last_onset)<CS.ONSET_GAP: return
	var h:=CS.hazards(day,x,s)
	for d in range(day-span+1,day+1):
		if _maybe_onset(s,d,x,h): break

static func _roll(key:String,annual:float)->bool:
	if annual<=0.0: return false
	var daily_p:=1.0-pow(maxf(0.0,1.0-minf(annual,0.999)),1.0/365.0)
	if annual>=1.0: daily_p=annual/365.0
	return CS._rng(key).randf()<daily_p

static func _ready_again(s:Dictionary,type:String,day:int,gap:int)->bool:
	return day-int((s.last as Dictionary).get(type,-99999))>=gap

## The court's _maybe_onset, for a people with no court.
static func _maybe_onset(s:Dictionary,day:int,x:Dictionary,h:Dictionary)->bool:
	for echo in (s.echoes as Array).duplicate():
		if echo is Dictionary and int(echo.get("day",0))<=day:
			(s.echoes as Array).erase(echo)
			if CS._active_in(s,"sickness").is_empty() and CS._active_in(s,"stranger").is_empty():
				var echoed:=_open_sickness(s,day,x,"sickness",float(echo.get("v",0.01)),String(echo.get("civ_id","")))
				echoed["echo_count"]=int(echo.get("count",1))
				return true
	var hungry_now:=(float(x.shortage_days)>=10.0 and float(x.intake)<0.94) or (int(x.first_shortage)>0 and int(x.first_shortage)<=45 and float(x.food_days)<CS.FoodCare.LEAN_DAYS)
	if CS._active_in(s,"hunger").is_empty() and _ready_again(s,"hunger",day,300) and (hungry_now or _roll("hunger:%d" % day,float(h.hunger))):
		_open_hunger(s,day,x,float(h.hunger_shortfall)); return true
	if CS._active_in(s,"drought").is_empty() and _ready_again(s,"drought",day,300) and float(x.weather_season)<0.88 and float(x.season)>-0.45:
		_open_drought(s,day,x); return true
	if _ready_again(s,"cold",day,730) and _roll("cold:%d" % day,float(h.cold)):
		_open_cold(s,day,x); return true
	if CS._active_in(s,"stranger").is_empty() and CS._active_in(s,"sickness").is_empty() and _ready_again(s,"stranger",day,240):
		for civ in CS._contacts():
			var civ_id:=String(civ.get("id",""))
			if (s.exchanged as Dictionary).has(civ_id): continue
			var rel:Dictionary=civ.get("player_relation",{})
			var met:=int((s.exchanged as Dictionary).get("met:"+civ_id,-1))
			if met<0:
				(s.exchanged as Dictionary)["met:"+civ_id]=day
				continue
			if day-met<60: continue
			var link:=clampf(float(rel.get("contact_level",1))/3.0,0.2,1.0)*(0.5+float(x.trade)+(0.3 if String(rel.get("treaty",""))!="" else 0.0))
			if _roll("stranger:%s:%d" % [civ_id,day],CS.BASE_STRANGER*link):
				(s.exchanged as Dictionary)[civ_id]=day
				_open_stranger(s,day,x,civ); return true
	if CS._active_in(s,"sickness").is_empty() and CS._active_in(s,"stranger").is_empty() and _ready_again(s,"sickness",day,150):
		if _roll("pest:%d" % day,float(h.pestilence_emerge)):
			_open_sickness(s,day,x,"sickness",CS._lognormal(CS._rng("pestv:%d" % day),0.06,0.85,0.005,0.35),""); return true
		if _roll("sick:%d" % day,float(h.sickness)):
			_open_sickness(s,day,x,"sickness",CS._lognormal(CS._rng("sickv:%d" % day),0.012,0.8,0.002,0.25),""); return true
	if CS._active_in(s,"flood").is_empty() and _ready_again(s,"flood",day,365) and _roll("flood:%d" % day,float(h.flood)):
		_open_flood(s,day,x); return true
	if CS._active_in(s,"fire").is_empty() and _ready_again(s,"fire",day,200) and _roll("fire:%d" % day,float(h.fire)):
		_open_fire(s,day,x); return true
	return false

# --------------------------------------------------------------------------
# Onsets: the court's magnitudes, and its official's answer at once
# --------------------------------------------------------------------------

static func _new(s:Dictionary,type:String,day:int,x:Dictionary,extra:Dictionary={})->Dictionary:
	s.serial=int(s.serial)+1
	var c:Dictionary={"id":"u%d" % int(s.serial),"type":type,"start":day,"phase":"open","pop0":int(float(x.pop)),"m":0.0,"mult":1.0,"deaths":0,
		"choice":"","mid_choice":"","mid_day":day+30,"end_day":day+75}
	c.merge(extra,true)
	(s.active as Dictionary)[String(c.id)]=c
	(s.last as Dictionary)[type]=day
	s.last_onset=day
	_stat(s,type,"onsets")
	return c

static func _plan_deaths(s:Dictionary,c:Dictionary,m:float)->void:
	c.m=clampf(m,0.0,0.6)
	c["severe"]=float(c.m)>=float(CS.SEVERE.get(String(c.type),1.0))
	if bool(c.severe): _stat(s,String(c.type),"severe")

static func _open_hunger(s:Dictionary,day:int,x:Dictionary,shortfall:float)->void:
	var rng:=CS._rng("hungerm:%d" % day)
	var modern:=clampf((float(x.H)-1850.0)/100.0,0.0,1.0)
	var m:=clampf((0.012+0.2*maxf(0.0,shortfall))*(1.0-0.4*float(x.inst))*(1.0-0.5*modern)*exp(0.5*rng.randfn(0.0,1.0)),0.002,0.25)
	var c:=_new(s,"hunger",day,x,{"mid_day":day+rng.randi_range(28,40),"end_day":day+rng.randi_range(80,120)})
	_plan_deaths(s,c,m)
	if bool(c.severe): (s.last as Dictionary)["famine"]=day
	_answer(s,c,"ration")

static func _open_sickness(s:Dictionary,day:int,x:Dictionary,type:String,v:float,civ_id:String)->Dictionary:
	var rng:=CS._rng("sick:%s:%d" % [type,day])
	var c:=_new(s,type,day,x,{"v":v,"civ_id":civ_id,"mid_day":day+rng.randi_range(14,24),"end_day":day+rng.randi_range(45,80),"hunger0":not CS._active_in(s,"hunger").is_empty()})
	_plan_deaths(s,c,CS._mortality(v,x,float(s.pool),rng))
	_sick_leave(c,x)
	_answer(s,c,"apart" if _apart(s) else "tend")
	return c

static func _open_stranger(s:Dictionary,day:int,x:Dictionary,civ:Dictionary)->void:
	var rng:=CS._rng("stranger:%d" % day)
	var pool:=CS._civ_pool(civ)
	var virgin:=pool-float(s.pool)>0.3
	var v:=0.2 if virgin else CS._lognormal(rng,0.02,0.8,0.004,0.2)
	var c:=_new(s,"stranger",day,x,{"v":v,"virgin":virgin,"civ_id":String(civ.get("id","")),"their_pool":pool,"mid_day":day+rng.randi_range(14,24),"end_day":day+rng.randi_range(50,90)})
	_plan_deaths(s,c,CS._mortality(v,x,pool,rng))
	_sick_leave(c,x)
	_answer(s,c,"apart" if _apart(s) else "tend")

## The sick do not work while they are down (the court's "sick" policy).
static func _sick_leave(c:Dictionary,x:Dictionary)->void:
	var sick:=clampi(roundi(float(x.pop)*(0.06+3.0*float(c.m))),3,maxi(3,int(float(x.pop)/2.0)))
	c["sick"]=sick
	_policy(c,"sick",{"labor_multiplier":-clampf(float(sick)/maxf(1.0,float(x.pop))*0.5,0.01,0.05)},21)

static func _open_drought(s:Dictionary,day:int,x:Dictionary)->void:
	var rng:=CS._rng("drought:%d" % day)
	var sev:=maxf(clampf(1.0-float(x.weather_season),0.0,0.6),CS.drought_depth(day))
	var c:=_new(s,"drought",day,x,{"sev":sev,"mid_day":day+rng.randi_range(30,45),"end_day":day+rng.randi_range(90,130)})
	# The same draw; it sets how deep the springs fail (dry_water.gd).
	CS.plan_drought(c,CS._lognormal(rng,0.002,1.0,0.0,0.05)*(1.0+4.0*sev))
	if sev>=CS.DROUGHT_COURT_DEPTH and not bool(c.severe): c.severe=true; _stat(s,"drought","severe")
	_answer(s,c,"carry")

static func _open_cold(s:Dictionary,day:int,x:Dictionary)->void:
	var rng:=CS._rng("cold:%d" % day)
	var loss:=clampf(rng.randf_range(0.04,0.12)*(1.0-0.5*float(x.divers))*1.3,0.02,0.2)
	var c:=_new(s,"cold",day,x,{"sev":loss,"severe":true,"mid_day":day+40,"end_day":day+rng.randi_range(200,300)})
	_stat(s,"cold","severe")
	_policy(c,"cold",{"food_yield":-loss},365)
	_answer(s,c,"ration")

static func _open_flood(s:Dictionary,day:int,x:Dictionary)->void:
	var rng:=CS._rng("flood:%d" % day)
	var lost:=_spoil_stores(rng.randf_range(0.10,0.35))
	var cap_before:=int(WorldSimulation.state.housing_capacity)
	WorldSimulation.state.housing_capacity=maxi(int(float(x.pop)*0.5),cap_before-maxi(1,roundi(float(cap_before)*rng.randf_range(0.08,0.30))))
	var c:=_new(s,"flood",day,x,{"food_lost":lost,"house_lost":cap_before-int(WorldSimulation.state.housing_capacity),"mid_day":day+rng.randi_range(20,30),"end_day":day+rng.randi_range(55,80)})
	_plan_deaths(s,c,CS._lognormal(rng,0.003,1.0,0.0,0.04))
	_answer(s,c,"wait")

static func _open_fire(s:Dictionary,day:int,x:Dictionary)->void:
	var rng:=CS._rng("fire:%d" % day)
	var lost:=_spoil_stores(rng.randf_range(0.04,0.22))
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	stocks["Timber"]=maxf(0.0,float(stocks.get("Timber",0.0))*(1.0-rng.randf_range(0.1,0.4)))
	var cap_before:=int(WorldSimulation.state.housing_capacity)
	WorldSimulation.state.housing_capacity=maxi(int(float(x.pop)*0.5),cap_before-maxi(1,roundi(float(cap_before)*rng.randf_range(0.08,0.25))))
	var c:=_new(s,"fire",day,x,{"food_lost":lost,"house_lost":cap_before-int(WorldSimulation.state.housing_capacity),"mid_day":day+rng.randi_range(12,20),"end_day":day+rng.randi_range(40,60)})
	_plan_deaths(s,c,CS._lognormal(rng,0.002,1.1,0.0,0.03))
	_health(-0.01)
	# The court's silent course (CrisisSystem._default_choice): a people that
	# has burned before rebuilds apart.
	_answer(s,c,"apart" if CS.burned_before(s) else "rebuild")

# --------------------------------------------------------------------------
# The official's answers (CrisisSystem._apply's default courses)
# --------------------------------------------------------------------------

static func _apart(s:Dictionary)->bool:
	return bool((s.flags as Dictionary).get("apart_custom",false))

static func _answer(s:Dictionary,c:Dictionary,choice:String)->void:
	c.choice=choice
	_stat(s,String(c.type),"silent")
	match choice:
		"ration":
			var cut:=0.25 if String(c.type)=="hunger" else 0.15
			_policy(c,"ration",{"food_demand":-cut,"health_target":-0.02},100 if String(c.type)!="cold" else 200)
			c.mult=float(c.mult)*float(CS.DEATH_FACTOR.ration)
			_metric("cohesion",-0.005)
		"apart":
			if String(c.type)=="fire":
				# The court's _rebuild_apart, from this people's own stores.
				var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
				var timber:=float(stocks.get("Timber",0.0))
				stocks["Timber"]=timber-minf(timber,float(c.get("house_lost",0))*0.8)
				(s.flags as Dictionary)["spaced"]=true
				_policy(c,"apart",CS.REBUILD_APART_EFFECTS,CS.REBUILD_APART_DAYS)
			else:
				c.mult=float(c.mult)*CS.APART_CUSTOM_FACTOR
				_policy(c,"apart",{"disease_risk":-0.3},45)
				_metric("cohesion",-0.01)
		"tend":
			c.mult=float(c.mult)*float(CS.DEATH_FACTOR.tend)
			_policy(c,"tend",{"labor_multiplier":-0.05},30)
			_metric("cohesion",0.01)
		"carry":
			# Through the water ledger: every strong back on the far pools.
			_policy(c,"carry",CS.CARRY_EFFECTS,90)
			c.mult=float(c.mult)*CS.death_factor(c,"carry")
		"wait":
			(s.until as Dictionary)["after_flood"]=CS._day()+75
		"rebuild":
			var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
			var timber:=float(stocks.get("Timber",0.0))
			var cost:=minf(timber,float(c.get("house_lost",0))*0.8)
			stocks["Timber"]=timber-cost
			WorldSimulation.state.housing_capacity=int(WorldSimulation.state.housing_capacity)+int(float(c.get("house_lost",0))*(0.8 if cost>0.0 else 0.4))
			_policy(c,"rebuild",{"labor_multiplier":-0.08},20)

static func _advance(s:Dictionary,c:Dictionary,day:int,x:Dictionary)->void:
	# A dry year counts who drank and the dead of thirst (the court's own rule).
	if String(c.phase) in ["open","mid"]: CS.dry_day(c)
	if String(c.phase)=="open" and day>=int(c.mid_day):
		c.phase="mid"
		var type:=String(c.type)
		if type in ["sickness","stranger"] and not bool(c.get("hunger0",true)) and not CS._active_in(s,"hunger").is_empty():
			c.m=clampf(float(c.m)*1.6,0.0,0.6)
			c.hunger0=true
		_due_deaths(s,c,0.4,"mid")
		# The turn's answer, when the trouble still holds (the court's second decision).
		match type:
			"sickness","stranger":
				if float(c.pop0)*float(c.m)*float(c.mult)*0.6>=1.5 or bool(c.get("virgin",false)):
					c.mid_choice="children_apart"; c.mult=float(c.mult)*float(CS.DEATH_FACTOR.children_apart); _metric("cohesion",-0.006)
			"hunger":
				if float(x.food_days)<CS.FoodCare.store_gate(25.0) or float(x.intake)<0.95:
					c.mid_choice="roots"; c.mult=float(c.mult)*float(CS.DEATH_FACTOR.roots)
					_policy(c,"roots",{"labor_multiplier":-0.08},30)
					EXCHANGE.receive(WorldSimulation.actor_id,"Food",float(x.pop)*0.25)
	elif String(c.phase)=="mid" and day>=int(c.end_day):
		_due_deaths(s,c,0.6,"end")
		if String(c.type) in ["sickness","stranger"]: _after_sickness(s,c,day)
		# The court's _end: huts rebuilt apart stand again when the fire's course ends.
		if String(c.type)=="fire" and String(c.choice)=="apart":WorldSimulation.state.housing_capacity=int(WorldSimulation.state.housing_capacity)+int(float(c.get("house_lost",0)))
		# The dead are remembered (the court's silent "cairn").
		if int(c.deaths)>0: _policy(c,"cairn",{"labor_multiplier":-0.03},20)
		_close(s,c)

## Survivors are harder to kill with the same sickness; a people that lived
## through a bad one learns to keep the sick apart; bad waves come back.
static func _after_sickness(s:Dictionary,c:Dictionary,day:int)->void:
	s.immunity=maxf(float(s.immunity),minf(0.85,0.35+4.0*float(c.m)))
	if String(c.type)=="stranger":
		var gap:=maxf(0.0,float(c.get("their_pool",0.0))-float(s.pool))
		s.pool=float(s.pool)+(0.35*gap if bool(c.get("virgin",false)) else maxf(0.0,0.9*float(c.get("their_pool",0.0))-float(s.pool)))
	_health(0.15*float(c.m))
	if float(c.m)>=0.02 or String(c.choice)=="apart": (s.flags as Dictionary)["apart_custom"]=true
	var v:=float(c.get("v",0.0))
	var echoes:=int(c.get("echo_count",0))
	if v>=0.03 and echoes<6 and CS._rng("echo:%s" % String(c.id)).randf()<minf(0.8,0.9 if bool(c.get("virgin",false)) else 2.0*v):
		var gap_years:=CS._rng("echoy:%s" % String(c.id)).randi_range(8,20)
		(s.echoes as Array).append({"count":echoes+1,"day":day+gap_years*365,"v":v*(0.75 if bool(c.get("virgin",false)) else CS._rng("echov:%s" % String(c.id)).randf_range(0.35,0.75)),"civ_id":String(c.get("civ_id",""))})
		while (s.echoes as Array).size()>24: (s.echoes as Array).pop_front()

static func _close(s:Dictionary,c:Dictionary)->void:
	(s.active as Dictionary).erase(String(c.id))
	var history:Array=s.history
	history.push_front({"id":String(c.id),"type":String(c.type),"start":int(c.start),"deaths":int(c.deaths),"m":float(c.m),"choice":String(c.choice)})
	while history.size()>CS.HISTORY_MAX: history.pop_back()

# --------------------------------------------------------------------------
# Effects on this people's own ledger
# --------------------------------------------------------------------------

static func _due_deaths(s:Dictionary,c:Dictionary,share:float,salt:String)->int:
	if String(c.get("type",""))=="drought": CS.dry_day(c)
	var planned:=CS.drought_toll(c) if String(c.get("type",""))=="drought" else float(c.m)
	var expected:=float(c.pop0)*planned*float(c.mult)*share
	return _kill(s,c,floori(expected+CS._rng("due:%s:%s" % [String(c.id),salt]).randf()))

## Deaths come out of the one aggregate population, never below the court's
## shock_widening floor (70% of the people before, never under 30).
static func _kill(s:Dictionary,c:Dictionary,count:int)->int:
	if count<=0: return 0
	var people=WorldSimulation.state
	var floor_count:=maxi(CS.FLOOR_PEOPLE,roundi(float(c.pop0)*CS.FLOOR_SHARE))
	var allowed:=mini(count,maxi(0,int(people.population_total)-floor_count))
	if allowed<=0: return 0
	var cause:=String((CS.TYPES[String(c.type)] as Dictionary).get("cause",""))
	var n:=int((people.register_population_deaths(allowed,cause if cause!="" else "Hardship") as Dictionary).get("count",0))
	c.deaths=int(c.deaths)+n
	if String(c.type)=="drought": c["toll_dead"]=int(c.get("toll_dead",0))+n
	_stat(s,String(c.type),"deaths",float(n))
	return n

static func _policy(c:Dictionary,tag:String,effects:Dictionary,days:int)->void:
	var magnitude:=0.2
	var coefficients:={}
	for channel in effects: coefficients[channel]=float(effects[channel])/magnitude
	var day:=float(CS._day())
	WorldSimulation.state.active_modifiers.append({"id":"crisis_%s_%s" % [String(c.id),tag],"kind":"policy","effects":coefficients,"magnitude":magnitude,
		"started_day":day,"until_day":day+float(days),"description":"%s: %s" % [String(c.type),tag.replace("_"," ")],"crisis":String(c.id)})

static func _metric(key:String,delta:float)->void:
	var m:Dictionary=WorldSimulation.state.simulation_metrics
	m[key]=clampf(float(m.get(key,0.5))+delta,0.01,0.99)

static func _health(delta:float)->void:
	var people=WorldSimulation.state
	people.population_health=clampf(float(people.population_health)+delta,0.02,0.97)
	people.simulation_metrics["health"]=people.population_health

## A share of the food in store spoiled or burned; returns the amount lost.
static func _spoil_stores(share:float)->float:
	var stocks:Dictionary=WorldSimulation.state.food_stocks
	var lost:=0.0
	for pool in stocks.keys():
		var held:=float(stocks.get(pool,0.0))
		var gone:=held*clampf(share,0.0,1.0)
		stocks[pool]=held-gone
		lost+=gone
	return lost

static func _stat(s:Dictionary,type:String,key:String,amount:float=1.0)->void:
	var stats:Dictionary=s.stats
	var row:Dictionary=stats.get(type,{}) if stats.get(type) is Dictionary else {}
	row[key]=float(row.get(key,0.0))+amount
	stats[type]=row
