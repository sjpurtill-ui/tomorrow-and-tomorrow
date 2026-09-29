extends RefCounted
## CAPACITY HISTORY: how each of the twelve capacities moved, month by month,
## and why.
##
## Recorded once a month for the player's people (society_model.process_day,
## right after the month's practices are counted) into
## GameState.capacity_history, which saves with the world; an older save
## starts empty and fills from its next month. A month is its mean: every day
## counts its reading into the month (observe_day) and the month is read at
## that mean, so one odd day never shows as a change. Every number here comes
## from the one capacity formula (SocietyModel.capacity_value) applied to
## that reading (capacity_inputs); nothing is estimated for the report.
##
## Why a capacity moved between two months is answered exactly:
##   1. each input's share of the change, by putting that one input back to
##      its old reading and taking the mean of the change seen from the old
##      month and from the new one (the little that inputs make only together
##      goes to the input that moved it most);
##   2. a practice total's share goes to the practices that make it up, by the
##      change in what each one adds, to the era's ceiling on that total, and
##      to the upkeep of too many full-time lore keepers;
##   3. the events of the interval that feed an input that moved it: works
##      finished, office holders changed, decrees begun or ended, hard times,
##      food taken by raiders or war, and our dead in battle. An event is never
##      given a share it cannot be shown to have.
## Small changes are gathered until they come to a point, then told as one;
## a season that comes round as it did last year is drawn, not told. A told
## change that carries on the one before it (the same main cause, moving the
## same way, with no event in either) is folded into it: one line with its
## total and span, marked once on the chart where the run stands now.
##
## Storage stays small (about 60 KB at most): one two-byte word per capacity
## and month holding the value, the chart's mark and whether a practice feeding
## it was learned that month, the last KEEP_WHY told
## changes per capacity, what is still gathering, and one reading of the
## inputs and practices. A practice is named by its place in
## known_discoveries, which only grows; events are stored as short codes and
## worded when shown (hud/capacity_words.gd).

const Society:=preload("res://scripts/society_model.gd")

const VERSION:=1
## Months kept (40 years), as the life-expectancy history keeps.
const MONTHS:=480
## Told changes kept per capacity; the page shows the latest six.
const KEEP_WHY:=6
## Reasons (with the rest summed) and events kept in each told change.
const KEEP_REASONS:=3
const KEEP_EVENTS:=2
## What a capacity gathers between told changes.
const PENDING_REASONS:=8
const PENDING_EVENTS:=3
## A change this large (one point) since the last told change is told.
const TELL_AT:=0.01
## Reasons smaller than this (a twentieth of a point) are folded into the rest.
const SMALLEST:=0.0005
## The chart's mark for a month, kept in the top bits of its value word.
const MARK_NONE:=0
const MARK_DISCOVERY:=1
const MARK_UP:=2
const MARK_DOWN:=3
const MARK_BUILDING:=4
const MARK_DECREE:=5
const MARK_CRISIS:=6
const MARK_NAMES:=["","discovery","up","down","building","decree","crisis"]
## A month's word: the value in tenths of a point (bits 0-9), the mark of the
## change told that month (bits 10-12), and whether a practice feeding the
## capacity was learned that month (bit 13), which shows when nothing is told.
const _VALUE_BITS:=1023
const _MARK_BITS:=7<<10
const _LEARNED_BIT:=1<<13

## Policy channels (ConsequenceEngine.policy_effect) and the capacity inputs
## they move, as consequence_engine.gd reads them into the daily metrics.
const POLICY_FEEDS:={"health_target":["health"],"disease_risk":["health"],"cohesion_target":["cohesion"],"violence":["cohesion","security"],
	"legitimacy_target":["legitimacy"],"security_target":["security"],"logistics_target":["hauling"],"material_target":["materials"],
	"knowledge_gain":["learning"],"ecology_delta":["ecology"],"food_yield":["food"],"food_demand":["food"]}
## Hard times (crisis_system.gd) and the input each one strikes.
const CRISIS_FEEDS:={"hunger":"food","drought":"food","cold":"food","sickness":"health","stranger":"health","flood":"housing","fire":"housing","thinning":"ecology"}
## Food taken from the stores (FoodSystem.issue_for_obligation categories).
const FOOD_LOSSES:={"raid_loss":"raid","war_loss":"war_food","sabotage":"sabotage","tribute":"tribute"}
## Deaths in the demographic ledger that are war losses.
const WAR_DEATHS:=["Killed in battle"]
## Event kinds that are hard times, most grave first; then the rest.
const EVENT_ORDER:=["crisis","raid","war_food","fallen","sabotage","tribute","decree","built","official"]
const HARD_TIMES:=["crisis","raid","war_food","fallen","sabotage","tribute"]


# --- Recording ----------------------------------------------------------------

static func empty()->Dictionary:
	var values:Dictionary={}
	var why:Dictionary={}
	for dynamic_id:String in Society.DYNAMICS:
		values[dynamic_id]=PackedByteArray()
		why[dynamic_id]=[]
	return {"version":VERSION,"days":PackedInt32Array(),"values":values,"why":why,"pending":{},"last":{},"month":{}}

static func _ensure(history:Dictionary)->void:
	if int(history.get("version",0))==VERSION and history.get("days") is PackedInt32Array: return
	history.clear()
	history.merge(empty())

## Counts one day (or a step of `span` days) into the month's mean reading.
## The practice totals (fx:) change only when the month's practices are
## counted, so the month reads them at its turn instead.
static func observe_day(inputs:Dictionary,span:float=1.0)->void:
	var history:Dictionary=WorldSimulation.state.capacity_history
	_ensure(history)
	var month:Dictionary=history.get("month",{})
	var sums:Dictionary=month.get("sum",{})
	var weight:=maxf(0.0,span)
	for key in inputs:
		if String(key).begins_with("fx:"): continue
		sums[key]=float(sums.get(key,0.0))+float(inputs[key])*weight
	history.month={"days":float(month.get("days",0.0))+weight,"sum":sums}

## The month's reading: each daily input at its mean over the days counted
## since the last record, the practice totals as counted today. A month is
## never one day's luck: one wet day, one storm, one hard day at the pits
## moves it by a day's share only. With no day counted yet, today's reading.
static func month_reading(history:Dictionary,inputs:Dictionary)->Dictionary:
	var reading:Dictionary=inputs.duplicate()
	var month:Dictionary=history.get("month",{})
	var days:=float(month.get("days",0.0))
	if days<=0.0: return reading
	var sums:Dictionary=month.get("sum",{})
	for key in sums:
		if reading.has(key): reading[key]=float(sums[key])/days
	return reading

## Records the month just ended for the people in scope: its mean values, what
## moved each capacity since the last month, and the reading the next month
## compares to. Every part comes from the one formula on that reading.
static func record(model:Object,inputs:Dictionary,day:int)->void:
	var history:Dictionary=WorldSimulation.state.capacity_history
	_ensure(history)
	var last:Dictionary=history.last
	if not last.is_empty() and day<=int(last.get("day",-1)): return
	var reading:=month_reading(history,inputs)
	history.month={}
	var values:Dictionary={}
	for dynamic_id:String in Society.DYNAMICS: values[dynamic_id]=Society.capacity_value(dynamic_id,reading)
	var index:=append_month(history,day,values)
	var basis:Dictionary=model.practice_basis()
	if (last.get("inputs",{}) as Dictionary).is_empty():
		for dynamic_id:String in Society.DYNAMICS: history.pending[dynamic_id]=_fresh(day,float(values[dynamic_id]))
	else:
		var month:=attribute(model,last,reading,basis,day)
		var events:=gather_events(model,last,day)
		for dynamic_id:String in Society.DYNAMICS:
			accumulate(history,dynamic_id,month[dynamic_id],events,index,day,float(values[dynamic_id]))
	history.last={"day":day,"inputs":reading,"basis":basis,"works":WorldSimulation.state.settlement_completed.size(),"offices":_offices()}

static func _fresh(day:int,value:float)->Dictionary:
	return {"since":day,"from":_tenths(value),"d":0.0,"r":{},"e":[]}

static func _tenths(value:float)->int:
	return clampi(roundi(value*1000.0),0,1000)

## Adds one month's values; returns its row. Keeps MONTHS rows.
static func append_month(history:Dictionary,day:int,values:Dictionary)->int:
	var days:PackedInt32Array=history.days
	days.append(day)
	var drop:=maxi(0,days.size()-MONTHS)
	if drop>0: days=days.slice(drop)
	history.days=days
	for dynamic_id:String in Society.DYNAMICS:
		var series:PackedByteArray=history.values.get(dynamic_id,PackedByteArray())
		series.resize(series.size()+2)
		series.encode_u16(series.size()-2,_tenths(float(values.get(dynamic_id,0.0))))
		if drop>0: series=series.slice(drop*2)
		history.values[dynamic_id]=series
	return days.size()-1

static func _set_mark(history:Dictionary,dynamic_id:String,index:int,mark:int)->void:
	var series:PackedByteArray=history.values[dynamic_id]
	if index<0 or index*2+2>series.size(): return
	series.encode_u16(index*2,(series.decode_u16(index*2)&~_MARK_BITS)|((mark&7)<<10))
	history.values[dynamic_id]=series

static func _set_learned(history:Dictionary,dynamic_id:String,index:int)->void:
	var series:PackedByteArray=history.values[dynamic_id]
	if index<0 or index*2+2>series.size(): return
	series.encode_u16(index*2,series.decode_u16(index*2)|_LEARNED_BIT)
	history.values[dynamic_id]=series

## The row of a recorded day, or -1.
static func _row_of(history:Dictionary,day:int)->int:
	var days:PackedInt32Array=history.get("days",PackedInt32Array())
	for index in range(days.size()-1,-1,-1):
		if days[index]==day: return index
		if days[index]<day: break
	return -1

## What moved each capacity between the last month and this one:
## {dynamic: {"d": change, "r": {reason: share}}}. The shares add up to d.
static func attribute(model:Object,last:Dictionary,inputs:Dictionary,basis:Dictionary,day:int)->Dictionary:
	var now:Dictionary=inputs.duplicate()
	var before:Dictionary=inputs.duplicate()
	var old_inputs:Dictionary=last.get("inputs",{})
	for key in old_inputs:
		if before.has(key): before[key]=old_inputs[key]
	var changed:Array=[]
	for key in now:
		if float(before[key])!=float(now[key]): changed.append(key)
	var sources:=_effect_changes(model,last,basis,before,now,_learned(int(last.get("day",-1)),day))
	var result:Dictionary={}
	for dynamic_id:String in Society.DYNAMICS:
		var start:=Society.capacity_value(dynamic_id,before)
		var finish:=Society.capacity_value(dynamic_id,now)
		var shares:Dictionary={}
		var told:=0.0
		var read:=_reads(dynamic_id,now)
		for key in changed:
			if not read.has(key): continue
			var old_value:Variant=before[key]
			var new_value:Variant=now[key]
			before[key]=new_value
			var forward:=Society.capacity_value(dynamic_id,before)-start
			before[key]=old_value
			now[key]=old_value
			var backward:=finish-Society.capacity_value(dynamic_id,now)
			now[key]=new_value
			var share:=(forward+backward)*0.5
			if absf(share)>0.000000001:
				shares[key]=share
				told+=share
		# What inputs do only together goes to the one that moved it most.
		var together:=(finish-start)-told
		if absf(together)>0.000000001:
			var largest:=""
			for key in shares:
				if largest=="" or absf(float(shares[key]))>absf(float(shares[largest])): largest=String(key)
			if largest!="": shares[largest]=float(shares[largest])+together
			else: shares["~"]=together
		var reasons:Dictionary={}
		for key in shares:
			var name:=String(key)
			if name.begins_with("fx:") and sources.has(name.substr(3)): continue
			var reason:=_reason_key(name,dynamic_id)
			reasons[reason]=float(reasons.get(reason,0.0))+float(shares[key])
		# A practice total's share, split among what makes it up.
		for effect_id:String in sources:
			var key:="fx:"+effect_id
			if not read.has(key): continue
			var change:=float(now[key])-float(before[key])
			var slope:=0.0
			if absf(change)>0.000000001:
				if not shares.has(key): continue
				slope=float(shares[key])/change
			else:
				slope=_slope(dynamic_id,now,key)
				if absf(slope)<=0.000000001: continue
			for source in sources[effect_id]:
				var amount:=slope*float(sources[effect_id][source])
				if absf(amount)<=0.000000001: continue
				reasons[source]=float(reasons.get(source,0.0))+amount
		result[dynamic_id]={"d":finish-start,"r":reasons}
	return result

## The inputs one capacity reads, found once from the formula itself: each is
## moved on a middling reading, where no limit holds, and kept if it moves the
## capacity. An input it does not read has no share of its change.
static var _read_cache:Dictionary={}

static func _reads(dynamic_id:String,inputs:Dictionary)->Dictionary:
	if _read_cache.has(dynamic_id) and (_read_cache[dynamic_id] as Dictionary).get("_count",-1)==inputs.size(): return _read_cache[dynamic_id]
	var middling:Dictionary={}
	for key in inputs:
		var name:=String(key)
		middling[key]=0.0 if name.begins_with("officials:") or name.begins_with("values:") else 0.3
	middling["fields"]=6.0
	middling["works"]=3.0
	var base:=Society.capacity_value(dynamic_id,middling)
	var read:Dictionary={"_count":inputs.size()}
	for key in middling:
		var held:Variant=middling[key]
		middling[key]=float(held)+0.05
		if absf(Society.capacity_value(dynamic_id,middling)-base)>0.000000000001: read[key]=true
		middling[key]=held
	_read_cache[dynamic_id]=read
	return read

static func _reason_key(input:String,dynamic_id:String)->String:
	if input=="officials:"+dynamic_id: return "officials"
	if input=="values:"+dynamic_id: return "values"
	return input

## How much one capacity moves per unit of one input, here and now.
static func _slope(dynamic_id:String,inputs:Dictionary,key:String)->float:
	var step:=0.001
	var original:Variant=inputs[key]
	inputs[key]=float(original)+step
	var high:=Society.capacity_value(dynamic_id,inputs)
	inputs[key]=float(original)-step
	var low:=Society.capacity_value(dynamic_id,inputs)
	inputs[key]=original
	return (high-low)/(2.0*step)

## Places in known_discoveries of the practices learned in (from_day, to_day].
static func _learned(from_day:int,to_day:int)->Dictionary:
	var known:Array=WorldSimulation.state.known_discoveries
	var learned:Dictionary={}
	for entry:Variant in WorldSimulation.state.discovery_log:
		if not entry is Dictionary: continue
		var day:=int((entry as Dictionary).get("day",-1))
		if day<=from_day or day>to_day: continue
		var index:=known.rfind(String((entry as Dictionary).get("id","")))
		if index>=0: learned[index]=true
	return learned

## How each capacity practice total changed, by what makes it up:
## {effect: {source: change}}. A practice is named by its place in
## known_discoveries after what happened to it: "n:" learned in the interval,
## "d:" taken up by more, "l:" practiced less, "f:" worked harder or less as
## the research focus moved; then "limit" (the era's ceiling on the total) and
## "upkeep" (full-time lore keepers beyond what the age can feed). The changes
## add up to the total's change. Empty when the older reading does not match
## this people's known practices.
static func _effect_changes(model:Object,last:Dictionary,basis:Dictionary,before:Dictionary,now:Dictionary,learned:Dictionary={})->Dictionary:
	var old_basis:Dictionary=last.get("basis",{})
	if old_basis.is_empty(): return {}
	var levels_then:Dictionary={}
	var levels_now:Dictionary={}
	var earlier:Dictionary=model.effect_sources(old_basis,Society.CAPACITY_EFFECTS,levels_then)
	var current:Dictionary=model.effect_sources(basis,Society.CAPACITY_EFFECTS,levels_now)
	if earlier.is_empty() or current.is_empty(): return {}
	var names:Dictionary={}
	for place in levels_now:
		var moved:=float(levels_now[place])-float(levels_then.get(place,0.0))
		var prefix:="n:" if learned.has(place) or not levels_then.has(place) else ("d:" if moved>0.000001 else ("l:" if moved<-0.000001 else "f:"))
		names[place]="%s%d" % [prefix,int(place)]
	var result:Dictionary={}
	for effect_id:String in Society.CAPACITY_EFFECTS:
		var now_by:Dictionary=current.get(effect_id,{})
		var then_by:Dictionary=earlier.get(effect_id,{})
		var changes:Dictionary={}
		var raw_now:=0.0
		var raw_then:=0.0
		for place in now_by:
			raw_now+=float(now_by[place])
			var change:=float(now_by[place])-float(then_by.get(place,0.0))
			if absf(change)>0.000000000001: changes[names.get(place,"l:%d" % int(place))]=change
		for place in then_by:
			raw_then+=float(then_by[place])
			if not now_by.has(place) and absf(float(then_by[place]))>0.000000000001: changes[names.get(place,"l:%d" % int(place))]=-float(then_by[place])
		var rate:=float(Society.SPECIALIST_UPKEEP.get(effect_id,0.0))
		var upkeep_now:=rate*float(basis.get("excess",0.0))
		var upkeep_then:=rate*float(old_basis.get("excess",0.0))
		if absf(upkeep_now-upkeep_then)>0.000000000001: changes["upkeep"]=upkeep_now-upkeep_then
		var total_now:=float(now.get("fx:"+effect_id,0.0))
		var total_then:=float(before.get("fx:"+effect_id,0.0))
		var limit_change:=(total_now-raw_now-upkeep_now)-(total_then-raw_then-upkeep_then)
		if absf(limit_change)>0.000000001: changes["limit"]=limit_change
		if not changes.is_empty(): result[effect_id]=changes
	return result

## Adds a month to what a capacity has gathered, and tells it once it comes to
## a point: a new line, or the run before it carried on. Marks the month on the
## chart (a run is marked once, where it stands now).
static func accumulate(history:Dictionary,dynamic_id:String,month:Dictionary,events:Array,index:int,day:int,value:float)->void:
	var pending:Dictionary=history.pending.get(dynamic_id,{})
	if pending.is_empty(): pending=_fresh(day,value)
	pending.d=float(pending.get("d",0.0))+float(month.get("d",0.0))
	var reasons:Dictionary=pending.get("r",{})
	var shares:Dictionary=month.get("r",{})
	var learned:=false
	for key in shares:
		reasons[key]=float(reasons.get(key,0.0))+float(shares[key])
		if String(key).begins_with("n:") and float(shares[key])!=0.0: learned=true
	_trim(reasons)
	pending.r=reasons
	# An event is kept only for a capacity that one of the inputs it feeds moved.
	var gathered:Array=pending.get("e",[])
	for event:Dictionary in events:
		var moved:=false
		for input:String in event.inputs:
			if absf(float(shares.get(_reason_key(input,dynamic_id),0.0)))>0.000000001: moved=true
		if not moved: continue
		var code:Array=event.code
		var held:=false
		for at in range(0,gathered.size(),3):
			if gathered.slice(at,at+3)==code: held=true
		if not held: gathered.append_array(code)
	while gathered.size()>PENDING_EVENTS*3: gathered=gathered.slice(3)
	pending.e=gathered
	if learned: _set_learned(history,dynamic_id,index)
	if absf(float(pending.d))>=TELL_AT and _seasonal(history,dynamic_id,pending,day,value):
		# Only the season coming round: drawn on the line, not told, and not
		# carried into the next change either, which is gathered from here.
		pending=_fresh(day,value)
	elif absf(float(pending.d))>=TELL_AT:
		var entry:=_entry(pending,day,value)
		var told:Array=history.why.get(dynamic_id,[])
		if not told.is_empty() and _can_fold(told[-1],entry):
			# The run carries on: one line, marked where it stands now.
			var earlier:Array=told[-1]
			_set_mark(history,dynamic_id,_row_of(history,int(earlier[0])),MARK_NONE)
			entry=_folded(earlier,entry)
			told[-1]=entry
		else:
			told.append(entry)
			while told.size()>KEEP_WHY: told.pop_front()
		history.why[dynamic_id]=told
		_set_mark(history,dynamic_id,index,int(entry[4]))
		pending=_fresh(day,value)
	history.pending[dynamic_id]=pending

## Whether a gathered change is only the year's own round: no event in it,
## led by how we live rather than by a practice, a work, an office or the age,
## and standing within a point of the same season in one of the last two
## years, where it is now and where it began. The seasons are drawn on the
## line; they are not told as causes. A departure from the seasons, or the way
## back from one, is told; two years keep one hard year from echoing.
static func _seasonal(history:Dictionary,dynamic_id:String,pending:Dictionary,day:int,value:float)->bool:
	if not (pending.get("e",[]) as Array).is_empty(): return false
	var reasons:Dictionary=pending.get("r",{})
	var top:=""
	for key in reasons:
		if String(key)!="~" and (top=="" or absf(float(reasons[key]))>absf(float(reasons[top]))): top=String(key)
	if top=="" or _is_practice(top) or top in ["works","officials","values","limit","upkeep"]: return false
	if _in_season(history,dynamic_id,day,value)!=1: return false
	# The way back from a departure is told: it began away from its season.
	return _in_season(history,dynamic_id,int(pending.get("since",day)),float(pending.get("from",0))/1000.0)!=0

## 1 when a value stands within a point of the same season one or two years
## before, 0 when it does not, -1 when the record does not reach back a year.
static func _in_season(history:Dictionary,dynamic_id:String,day:int,value:float)->int:
	var known:=false
	for years in [1,2]:
		var before:=_value_near(history,dynamic_id,day-365*years)
		if before<0.0: continue
		known=true
		if absf(value-before)<TELL_AT: return 1
	return 0 if known else -1

## The recorded value (0-1) of the month nearest `day`, within 20 days; -1
## when the record does not reach it.
static func _value_near(history:Dictionary,dynamic_id:String,day:int)->float:
	var days:PackedInt32Array=history.get("days",PackedInt32Array())
	var series:PackedByteArray=(history.get("values",{}) as Dictionary).get(dynamic_id,PackedByteArray())
	var best:=-1
	for index in mini(days.size(),series.size()/2):
		if absi(days[index]-day)<=20 and (best<0 or absi(days[index]-day)<absi(days[best]-day)): best=index
	return float(series.decode_u16(best*2)&_VALUE_BITS)/1000.0 if best>=0 else -1.0

## Keeps the largest gathered reasons; the rest are summed as "~".
static func _trim(reasons:Dictionary)->void:
	if reasons.size()<=PENDING_REASONS: return
	var keys:Array=reasons.keys()
	keys.erase("~")
	keys.sort_custom(func(a,b)->bool:return absf(float(reasons[a]))>absf(float(reasons[b])))
	var rest:=float(reasons.get("~",0.0))
	for position in range(PENDING_REASONS-1,keys.size()):
		rest+=float(reasons[keys[position]])
		reasons.erase(keys[position])
	reasons["~"]=rest

## A told change: [day, since, from, to, mark, reasons, events]. Values are in
## tenths of a point; reasons are [key, hundredths of a point, ...] and add up
## to the change; events are [kind, a, b, ...] (capacity_words.gd words them).
static func _entry(pending:Dictionary,day:int,value:float)->Array:
	var reasons:Dictionary=pending.get("r",{})
	var keys:Array=reasons.keys()
	keys.erase("~")
	keys.sort_custom(func(a,b)->bool:return absf(float(reasons[a]))>absf(float(reasons[b])))
	var kept:Array=[]
	var listed:=0.0
	for key in keys:
		if kept.size()>=KEEP_REASONS*2 or absf(float(reasons[key]))<SMALLEST: break
		kept.append_array([String(key),roundi(float(reasons[key])*10000.0)])
		listed+=float(reasons[key])
	var rest:=float(pending.get("d",0.0))-listed
	if absf(rest)>=SMALLEST: kept.append_array(["~",roundi(rest*10000.0)])
	var gathered:Array=pending.get("e",[])
	var codes:Array=[]
	for at in range(0,gathered.size(),3): codes.append(gathered.slice(at,at+3))
	codes.sort_custom(func(a,b)->bool:return _event_rank(String(a[0]))<_event_rank(String(b[0])))
	var events:Array=[]
	for code:Array in codes.slice(0,KEEP_EVENTS): events.append_array(code)
	return [day,int(pending.get("since",day)),int(pending.get("from",_tenths(value))),_tenths(value),_mark(kept,codes,float(pending.get("d",0.0))),kept,events]

static func _event_rank(kind:String)->int:
	var rank:=EVENT_ORDER.find(kind)
	return rank if rank>=0 else EVENT_ORDER.size()

static func _mark(reasons:Array,codes:Array,change:float)->int:
	if change<0.0:
		for code:Array in codes:
			if String(code[0]) in HARD_TIMES: return MARK_CRISIS
	var top:=String(reasons[0]) if not reasons.is_empty() else ""
	if _is_practice(top): return MARK_DISCOVERY
	if top=="works": return MARK_BUILDING
	if top=="officials": return MARK_DECREE
	for code:Array in codes:
		if String(code[0])=="decree" and top in ["health","cohesion","security","legitimacy","hauling","materials","learning","ecology","food"]: return MARK_DECREE
	return MARK_UP if change>0.0 else MARK_DOWN

## Whether a told change carries on the one before it: straight after it, the
## same main cause moving the same way, and no event in either. An event (a
## raid, a work built, a decree) or a turn keeps its own line.
static func _can_fold(earlier:Array,later:Array)->bool:
	if earlier.size()<7 or later.size()<7: return false
	if not (earlier[6] as Array).is_empty() or not (later[6] as Array).is_empty(): return false
	if int(later[1])!=int(earlier[0]): return false
	var first:=_main_reason(earlier[5] as Array)
	var second:=_main_reason(later[5] as Array)
	if first.is_empty() or second.is_empty() or String(first[0])!=String(second[0]): return false
	if signi(int(first[1]))!=signi(int(second[1])): return false
	return signi(_flat_sum(earlier[5] as Array))==signi(_flat_sum(later[5] as Array))

## One told change made of two in a row: from where the first began to where
## the second ends, their reasons summed (the largest kept, the rest together).
static func _folded(earlier:Array,later:Array)->Array:
	var totals:Dictionary={}
	for entry:Array in [earlier,later]:
		var flat:Array=entry[5]
		for at in range(0,flat.size(),2): totals[String(flat[at])]=int(totals.get(String(flat[at]),0))+int(flat[at+1])
	var keys:Array=totals.keys()
	keys.erase("~")
	keys.sort_custom(func(a,b)->bool:return absi(int(totals[a]))>absi(int(totals[b])))
	var kept:Array=[]
	var rest:=int(totals.get("~",0))
	for key in keys:
		if kept.size()<KEEP_REASONS*2 and absi(int(totals[key]))>=roundi(SMALLEST*10000.0): kept.append_array([key,int(totals[key])])
		else: rest+=int(totals[key])
	if rest!=0: kept.append_array(["~",rest])
	return [int(later[0]),int(earlier[1]),int(earlier[2]),int(later[3]),_mark(kept,[],float(_flat_sum(kept))/10000.0),kept,[]]

## The largest named reason of a told change as [key, amount], or [] when
## only the small ones together are left.
static func _main_reason(flat:Array)->Array:
	for at in range(0,flat.size(),2):
		if String(flat[at])!="~": return [String(flat[at]),int(flat[at+1])]
	return []

static func _flat_sum(flat:Array)->int:
	var total:=0
	for at in range(1,flat.size(),2): total+=int(flat[at])
	return total


# --- Events of the interval -------------------------------------------------

## What happened between the last month and this one, as short codes, with
## the inputs each event feeds: [{"code":[kind, a, b], "inputs":[keys]}].
static func gather_events(model:Object,last:Dictionary,day:int)->Array:
	var from_day:=int(last.get("day",-1))
	var state=WorldSimulation.state
	var events:Array=[]
	# Works finished (or lost) feed the count of public works.
	var completed:Array=state.settlement_completed
	var before:=int(last.get("works",completed.size()))
	if completed.size()>before:
		var first:=String(completed[before])
		events.append({"code":["built",first,completed.size()-before],"inputs":["works"]})
	elif completed.size()<before:
		events.append({"code":["built","",completed.size()-before],"inputs":["works"]})
	# A new holder in an office feeds the capacities that office carries.
	var offices_then:Dictionary=last.get("offices",{})
	var offices_now:=_offices()
	var seen_offices:Dictionary={}
	for office in offices_now.keys()+offices_then.keys():
		if seen_offices.has(office) or String(offices_now.get(office,""))==String(offices_then.get(office,"")): continue
		seen_offices[office]=true
		var fed:Array=[]
		for dynamic_id in Society.OFFICE_DYNAMICS.get(String(office),[]): fed.append("officials:"+String(dynamic_id))
		for doctrine in [_doctrine(offices_now.get(office,"")),_doctrine(offices_then.get(office,""))]:
			if doctrine=="": continue
			for dynamic_id:String in Society.DYNAMICS:
				if model._doctrine_side_effect(doctrine,dynamic_id)!=0.0 and not fed.has("officials:"+dynamic_id): fed.append("officials:"+dynamic_id)
		events.append({"code":["official",String(office),_holder_name(offices_now.get(office,""))],"inputs":fed})
	# Decrees begun or ended feed the daily readings their channels move.
	for modifier_variant in state.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("kind",""))!="policy" or String(modifier.get("custom_role",""))=="side_effect": continue
		var effects:Dictionary=modifier.get("effects",{})
		if effects.is_empty() and GovernmentPolicyCatalog.has_policy(String(modifier.get("id",""))): effects=GovernmentPolicyCatalog.definition(String(modifier.id)).get("effects",{})
		var fed:Array=[]
		for channel in effects:
			for input in POLICY_FEEDS.get(String(channel),[]):
				if not fed.has(input): fed.append(input)
		if fed.is_empty(): continue
		var started:=float(modifier.get("started_day",-INF))
		var ended:=float(modifier.get("ended_day",INF)) if modifier.has("ended_day") else INF
		if started>float(from_day) and started<=float(day): events.append({"code":["decree",String(modifier.get("id","")),1],"inputs":fed})
		elif ended>float(from_day) and ended<=float(day): events.append({"code":["decree",String(modifier.get("id","")),0],"inputs":fed})
	# Hard times: hunger, sickness, floods and fires, a thinning land.
	var audiences:Variant=WorldSimulation.diplomacy.get("audiences") if WorldSimulation.diplomacy!=null else null
	var crises:Dictionary=(audiences as Dictionary).get("crises",{}) if audiences is Dictionary else {}
	var seen:Dictionary={}
	for list_name in ["history","mild_log"]:
		for record:Variant in crises.get(list_name,[]):
			if record is Dictionary: _crisis_event(events,seen,record as Dictionary,from_day,day,int((record as Dictionary).get("end",day)))
	var active:Variant=crises.get("active",{})
	if active is Dictionary:
		for record:Variant in (active as Dictionary).values():
			if record is Dictionary: _crisis_event(events,seen,record as Dictionary,from_day,day,day)
	# Food carried off by raiders or war, spoiled by saboteurs, paid as tribute.
	var taken:Dictionary={}
	for issue:Variant in state.food_issue_history:
		if not issue is Dictionary: continue
		var category:=String((issue as Dictionary).get("category",""))
		var issue_day:=int((issue as Dictionary).get("day",-1))
		if not FOOD_LOSSES.has(category) or issue_day<=from_day or issue_day>day: continue
		taken[category]=float(taken.get(category,0.0))+float((issue as Dictionary).get("settlement_days",0.0))
	for category in taken:
		events.append({"code":[String(FOOD_LOSSES[category]),roundi(float(taken[category])),0],"inputs":["food"]})
	# Our dead in battle were working hands.
	var fallen:=0
	for record:Variant in state.demographic_ledger:
		if not record is Dictionary: continue
		var record_day:=int((record as Dictionary).get("day",-1))
		if record_day<=from_day or record_day>day or String((record as Dictionary).get("kind",""))!="death": continue
		if String((record as Dictionary).get("cause","")) in WAR_DEATHS: fallen+=int((record as Dictionary).get("count",0))
	if fallen>0: events.append({"code":["fallen",fallen,0],"inputs":["able"]})
	return events

static func _crisis_event(events:Array,seen:Dictionary,record:Dictionary,from_day:int,day:int,end_day:int)->void:
	var type:=String(record.get("type","sickness" if record.has("sick") else ""))
	if not CRISIS_FEEDS.has(type): return
	var start:=int(record.get("start",day))
	if start>day or end_day<=from_day: return
	var id:=String(record.get("id",record.get("name","")))
	if seen.has(id): return
	seen[id]=true
	var name:=String(record.get("name","")).strip_edges()
	events.append({"code":["crisis",name if name!="" else type,int(record.get("deaths",0))],"inputs":[String(CRISIS_FEEDS[type])]})

## Who holds each office now, as "name|doctrine".
static func _offices()->Dictionary:
	var result:Dictionary={}
	for office in WorldSimulation.state.leadership_positions:
		var advisor:Variant=WorldSimulation.state.leadership_positions[office]
		if not advisor is Dictionary: continue
		result[String(office)]="%s|%s" % [String((advisor as Dictionary).get("name","")),String((advisor as Dictionary).get("doctrine",""))]
	return result

static func _holder_name(holder:Variant)->String:
	return String(holder).get_slice("|",0)

static func _doctrine(holder:Variant)->String:
	var text:=String(holder)
	return text.get_slice("|",1) if "|" in text else ""


# --- Reading ------------------------------------------------------------------

static func _history()->Dictionary:
	var history:Variant=GameState.capacity_history
	return history if history is Dictionary and int((history as Dictionary).get("version",0))==VERSION else {}

## The recorded months of one capacity, oldest first: [{day, value (0-100),
## mark}]. Before the first month is recorded, today's value alone.
static func months(dynamic_id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var history:=_history()
	var days:PackedInt32Array=history.get("days",PackedInt32Array())
	var series:PackedByteArray=(history.get("values",{}) as Dictionary).get(dynamic_id,PackedByteArray())
	for index in mini(days.size(),series.size()/2):
		var word:=series.decode_u16(index*2)
		# A month with no told change still shows a practice learned in it.
		var mark:=(word&_MARK_BITS)>>10
		if mark==MARK_NONE and word&_LEARNED_BIT: mark=MARK_DISCOVERY
		result.append({"day":days[index],"value":float(word&_VALUE_BITS)/10.0,"mark":mark})
	if result.is_empty():
		result.append({"day":int(GameState.elapsed_days),"value":clampf(float(GameState.society_capacities.get(dynamic_id,0.0)),0.0,1.0)*100.0,"mark":MARK_NONE})
	return result

## Up to `count` of the latest monthly values (0-100), oldest first.
static func sparkline(dynamic_id:String,count:int=120)->PackedFloat32Array:
	var points:=PackedFloat32Array()
	var recorded:=months(dynamic_id)
	for index in range(maxi(0,recorded.size()-count),recorded.size()): points.append(float(recorded[index].value))
	return points

## The change in points over about the last `span` days, to today's value:
## {"points", "from" (the value then), "since" (the day counted from), "full"
## (the record reaches back the whole span)}.
static func change_over(dynamic_id:String,span:int=365)->Dictionary:
	var recorded:=months(dynamic_id)
	var now:=clampf(float(GameState.society_capacities.get(dynamic_id,float(recorded[-1].value)/100.0)),0.0,1.0)*100.0
	var reference:Dictionary=recorded[0]
	for entry:Dictionary in recorded:
		if int(entry.day)<=int(GameState.elapsed_days)-span: reference=entry
	return {"points":now-float(reference.value),"from":float(reference.value),"since":int(reference.day),"full":int(reference.day)<=int(GameState.elapsed_days)-span}

## The latest told changes, newest first: [{day, since, from, to (0-100),
## change (points), reasons:[[key, points]], events:[[kind, a, b]], mark,
## folded_days}]. The reasons, with the rest too small to name, add up to the
## change. A run stored line by line (before runs were folded as they came) is
## folded here too; folded_days are the days its earlier lines were told.
static func changes(dynamic_id:String,limit:int=KEEP_WHY)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var stored:Array=(_history().get("why",{}) as Dictionary).get(dynamic_id,[])
	var told:Array=[]
	var folded_days:Array=[]
	for entry_variant in stored:
		var entry:Array=entry_variant
		if not told.is_empty() and _can_fold(told[-1],entry):
			(folded_days[-1] as Array).append(int((told[-1] as Array)[0]))
			told[-1]=_folded(told[-1],entry)
		else:
			told.append(entry)
			folded_days.append([])
	for index in range(told.size()-1,-1,-1):
		var entry:Array=told[index]
		var reasons:Array=[]
		var change:=0.0
		var flat:Array=entry[5]
		for at in range(0,flat.size(),2):
			reasons.append([String(flat[at]),float(flat[at+1])/100.0])
			change+=float(flat[at+1])/100.0
		var events:Array=[]
		var codes:Array=entry[6]
		for at in range(0,codes.size(),3): events.append(codes.slice(at,at+3))
		result.append({"day":int(entry[0]),"since":int(entry[1]),"from":float(entry[2])/10.0,"to":float(entry[3])/10.0,"change":change,"mark":int(entry[4]),"reasons":reasons,"events":events,"folded_days":folded_days[index]})
		if result.size()>=limit: break
	return result

## What is still gathering toward the next told change.
static func gathering(dynamic_id:String)->Dictionary:
	return ((_history().get("pending",{}) as Dictionary).get(dynamic_id,{}) as Dictionary).duplicate(true)

## Whether a reason key names a practice ("n:", "d:", "l:" or "f:" and its
## place in known_discoveries).
static func _is_practice(reason:String)->bool:
	return reason.length()>2 and reason[1]==":" and reason[0] in ["n","d","l","f"]

## The practice a reason key names, or "".
static func practice_id(reason:String)->String:
	if not _is_practice(reason): return ""
	var place:=int(reason.substr(2))
	var known:Array=GameState.known_discoveries
	return String(known[place]) if place>=0 and place<known.size() else ""
