extends RefCounted
## WHO SETS THE DAILY WORK: our leaders, or the ruler by hand.
##
## One switch and one split, both on PeopleDirection (people_direction.gd,
## saved with the world): automatic_work (true: each town's leader shares out
## the work, as GovernmentPeopleSystem has always done) and work_baseline (the
## ruler's own split, as shares of the people who can work, in percent). The
## People view's "Who sets the daily work" row and its −/+ on each task, the
## town page's hands chips and the court ("I will set the work myself", "put
## 10 more on building", "let the headman decide the work again":
## home_orders.gd) all read and set it here, so they always agree.
##
## GovernmentPeopleSystem stays the owner of daily labour: in the ruler's
## hands its daily delegation lays this split on every town as it is
## (applied_percentages), with no hidden survival guard or food floor. The
## split keeps its shares as the people grow or shrink; a task the ruler
## gave anyone keeps at least one person while there are people enough. When
## the split will leave people short, outlook() says so in plain words from
## the food and water counts.
##
## Everything reads population_allocations, the one ledger of who works at
## what: the People view's rows, the court's "At work" and the economy.
## Static helpers; preload.

const Plain:=preload("res://scripts/hud/production_plain.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

## GameState.POPULATION_ROLES, in the order the People view shows them.
const ROLES:=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
## Each task in plain words: [the row, a person doing it, the doing].
const TASKS:={
	"Food":["getting food","gets food","getting food"],
	"Survey":["searching the land","searches the land","searching the land"],
	"Extraction":["cutting and digging","cuts and digs","cutting and digging"],
	"Construction":["building","builds","building"],
	"Crafting":["making tools","makes tools","making tools"],
	"Logistics":["carrying","carries","carrying"],
	"Knowledge":["learning","keeps the lore","learning"],
	"Administration":["keeping the stores","keeps the stores","keeping the stores"],
	"Defense":["keeping watch","keeps watch","keeping watch"],
}
## What the leader is putting extra hands on, short (the leader's line).
const FOCUS_FIRST:={"water":"water first","provisions":"food first","shelter":"shelter first","defense":"the watch first","research":"learning first","logistics":"carrying first",
	"development":"building up the place","establishment":"setting the place up","balanced":"everyday needs"}

const LEADERS_TIP:="Each town's leader shares out the work every day, food and water first."
const RULER_TIP:="You set how many do each task. Nothing changes it until you do."

static func _state()->Variant:
	return WorldSimulation.state

static func _direction()->Variant:
	var direction=WorldSimulation.direction
	direction.ensure()
	return direction

# --------------------------------------------------------------------------
# The switch
# --------------------------------------------------------------------------

## Does the ruler set the daily work (true), or our leaders (false)?
static func manual()->bool:
	return not bool(_direction().automatic_work)

## Hands the daily work to the ruler (true) or back to our leaders (false).
## Taking it keeps the work as it stands, person for person; giving it back
## lets the leaders share it out again at once. Returns true when it changed.
static func set_manual(on:bool)->bool:
	var direction=_direction()
	if manual()==on:return false
	if on:
		direction.work_baseline=_shares_of(counts())
		direction.automatic_work=false
	else:
		direction.automatic_work=true
	apply()
	return true

## Lays the split on our towns now, through the owner of daily labour.
static func apply()->void:
	var government=WorldSimulation.government
	if government!=null and government.has_method("delegate_now"):government.delegate_now()

# --------------------------------------------------------------------------
# The split
# --------------------------------------------------------------------------

## Who works at what now: population_allocations, in whole people.
static func counts()->Dictionary:
	var out:={}
	var allocations:Dictionary=_state().population_allocations
	for role:String in ROLES:out[role]=maxi(0,roundi(float(allocations.get(role,0))))
	return out

## The people who can work (every one of them has a task).
static func able()->int:
	var total:=0
	var now:=counts()
	for role:String in ROLES:total+=int(now[role])
	return total

## The ruler's split as shares in percent, every task, adding to 100. Empty
## or unreadable, it is the work as it stands.
static func split()->Dictionary:
	var saved:Variant=_direction().work_baseline
	var shares:={}
	var total:=0.0
	for role:String in ROLES:
		var value:=0.0
		if saved is Dictionary and ((saved as Dictionary).get(role) is float or (saved as Dictionary).get(role) is int):value=float(saved[role])
		if not is_finite(value) or value<0.0:value=0.0
		shares[role]=value;total+=value
	if total<=0.001:return _shares_of(counts())
	for role:String in ROLES:shares[role]=float(shares[role])/total*100.0
	return shares

static func _shares_of(people:Dictionary)->Dictionary:
	var total:=0
	for role:String in ROLES:total+=maxi(0,int(people.get(role,0)))
	var shares:={}
	for role:String in ROLES:shares[role]=(float(maxi(0,int(people.get(role,0))))/float(total)*100.0) if total>0 else (100.0 if role=="Food" else 0.0)
	return shares

## The split in whole people for `workers` who can work: the largest
## remainders, as the ledger counts (GameState.synchronize_population_allocations),
## then at least one on every task the ruler gave anyone, while there are
## people enough, taken from the task with the most.
static func whole_people(shares:Dictionary,workers:int)->Dictionary:
	var out:={}
	var remainders:={}
	var total:=0.0
	for role:String in ROLES:total+=maxf(0.0,float(shares.get(role,0.0)))
	var assigned:=0
	for role:String in ROLES:
		var exact:=float(maxi(0,workers))*maxf(0.0,float(shares.get(role,0.0)))/total if total>0.0 else 0.0
		out[role]=floori(exact);remainders[role]=exact-floorf(exact);assigned+=int(out[role])
	while assigned<workers and total>0.0:
		var best:="";var most:=-INF
		for role:String in ROLES:
			if float(remainders[role])>most:most=float(remainders[role]);best=role
		out[best]=int(out[best])+1;remainders[best]=-1.0;assigned+=1
	var wanting:=ROLES.filter(func(role:String)->bool:return float(shares.get(role,0.0))>0.0 and int(out[role])==0)
	wanting.sort_custom(func(a:String,b:String)->bool:return float(shares.get(a,0.0))>float(shares.get(b,0.0)))
	for role:String in wanting:
		var donor:=_most(out,role,2)
		if donor=="":break
		out[donor]=int(out[donor])-1;out[role]=1
	return out

## The task (not `except`) with the most people, at least `least` of them;
## "" when none. Ties go to the first in ROLES.
static func _most(people:Dictionary,except:String,least:int=1)->String:
	var best:="";var most:=least-1
	for role:String in ROLES:
		if role==except:continue
		if int(people.get(role,0))>most:most=int(people[role]);best=role
	return best

## The shares the ledger is given today: the ruler's split in whole people
## for the people who can work now, as percentages the ledger reads back to
## exactly those people.
static func applied_percentages()->Dictionary:
	var workers:=int(_state().able_population())
	var people:=whole_people(split(),workers)
	var out:={}
	for role:String in ROLES:out[role]=float(people[role])/float(maxi(1,workers))*100.0
	return out

## Moves whole people onto (people>0) or off (people<0) a task, one at a
## time: each one comes from, or goes to, the task with the most people
## (`other` names that task instead). Takes the work into the ruler's hands
## first. {ok, role, moved, from:{task:n}, to:{task:n}, before, after}.
static func move(role:String,people:int,other:String="")->Dictionary:
	if not role in ROLES or people==0:return {"ok":false,"role":role,"moved":0,"from":{},"to":{},"reason":"No such work."}
	var was_manual:=manual()
	if not was_manual:set_manual(true)
	var before:=counts()
	var now:=before.duplicate()
	var gave:={};var took:={}
	for step in absi(people):
		if people>0:
			var donor:=other if other!="" and other!=role and int(now.get(other,0))>0 else _most(now,role)
			if donor=="":break
			now[donor]=int(now[donor])-1;now[role]=int(now[role])+1
			gave[donor]=int(gave.get(donor,0))+1
		else:
			if int(now[role])<=0:break
			var taker:=other if other!="" and other!=role else _most(now,role,0)
			if taker=="":break
			now[role]=int(now[role])-1;now[taker]=int(now[taker])+1
			took[taker]=int(took.get(taker,0))+1
	var moved:=0
	for n in gave.values():moved+=int(n)
	for n in took.values():moved+=int(n)
	if moved>0:
		_direction().work_baseline=_shares_of(now)
		apply()
	return {"ok":moved>0,"role":role,"moved":moved,"from":gave,"to":took,"before":before,"after":counts(),"took_charge":not was_manual}

# --------------------------------------------------------------------------
# What the split will do: the food and water counts, read for this split
# --------------------------------------------------------------------------

## For each town of ours, from its own count: how long its stores last at
## this split, how many drink enough, and the warning words.
## {food_days (-1: the stores hold), shortage_day, water_ratio, town, lines:[{text, tone}]}.
static func outlook()->Dictionary:
	var state=_state()
	var rows:Array=[]
	if state.player_settlements.is_empty():rows.append(_town_outlook())
	for city:Dictionary in state.player_settlements:
		if not String(city.get("occupied_by","")).is_empty():continue
		var id:=String(city.get("id",""))
		var row:Dictionary=WorldSimulation.settlements.with_city_resources(id,func()->Dictionary:
			return WorldSimulation.settlements.with_local_population(func()->Dictionary:return _town_outlook()))
		row["town"]=String(city.get("name",""))
		rows.append(row)
	var worst_food:={}
	var worst_water:={}
	for row:Dictionary in rows:
		if float(row.food_days)>=0.0 and (worst_food.is_empty() or float(row.food_days)<float(worst_food.food_days)):worst_food=row
		if float(row.water_ratio)>=0.0 and (worst_water.is_empty() or float(row.water_ratio)<float(worst_water.water_ratio)):worst_water=row
	var lines:Array=[]
	var towns:=rows.size()>1
	if not worst_food.is_empty():
		var days:=float(worst_food.food_days)
		var where:=(" in %s" % String(worst_food.town)) if towns and String(worst_food.get("town",""))!="" else ""
		lines.append({"text":"At this split the stores%s last %s." % [where,Plain.duration_text(days)],"tone":"bad" if days<60.0 else "warn"})
	elif not rows.is_empty() and bool(rows[0].get("counted",false)):
		lines.append({"text":"At this split the stores hold.","tone":"good"})
	if not worst_water.is_empty() and float(worst_water.water_ratio)<0.98:
		var where:=(" in %s" % String(worst_water.town)) if towns and String(worst_water.get("town",""))!="" else ""
		var ratio:=float(worst_water.water_ratio)
		var said:="%d in 10 drink enough" % roundi(ratio*10.0) if ratio>=0.1 else "almost none drink enough"
		lines.append({"text":"Water%s: %s." % [where,said],"tone":"bad"})
	elif not worst_water.is_empty():
		lines.append({"text":"Water: enough for all.","tone":"good"})
	return {"food_days":float(worst_food.get("food_days",-1.0)) if not worst_food.is_empty() else -1.0,"shortage_day":int(worst_food.get("shortage_day",-1)) if not worst_food.is_empty() else -1,
		"water_ratio":float(worst_water.get("water_ratio",-1.0)) if not worst_water.is_empty() else -1.0,"lines":lines}

## One town, inside its own scope: the day's count with today's split. Food
## comes in as the hands getting it (the count's own food_workers), less what
## spoils and is eaten; water as the carriers and food getters fetch it
## (resource_system.gd), beside what households fetch for themselves.
static func _town_outlook()->Dictionary:
	var state=_state()
	var m:Dictionary=state.simulation_metrics
	var out:={"food_days":-1.0,"shortage_day":-1,"water_ratio":-1.0,"counted":m.has("food_production")}
	if m.has("food_production"):
		var measured:=float(m.get("food_workers",-1.0))
		var ratio:float=float(state.effective_workers("Food"))/measured if measured>0.01 else 1.0
		var produced:float=float(m.get("food_production",0.0))*ratio
		var loss:float=float(m.get("food_consumption",0.0))+float(m.get("food_spoilage",0.0))-produced
		var stock:=float(m.get("food_total_stock",state.resource_stockpiles.get("Food",0.0)))
		var days:float=stock/loss if loss>0.01 else -1.0
		# A lean season the count already sees comes no later with fewer on food.
		var forecast:Dictionary=m.get("food_forecast_90",{}) if m.get("food_forecast_90") is Dictionary else {}
		var lean:=int(forecast.get("first_shortage_day",-1))
		if lean>0 and ratio<=1.02:
			days=float(lean) if days<0.0 else minf(days,float(lean))
			out["shortage_day"]=lean
		out["food_days"]=days
	var water:Dictionary=state.water_metrics
	var need:=float(water.get("required_today",0.0))
	if need>0.0:
		var measured_hands:=float(water.get("collection_workers",-1.0))
		var hands:float=float(state.effective_workers("Logistics"))+float(state.effective_workers("Food"))*0.22
		var organized:=float(water.get("organized_collection_capacity",-1.0))
		var fetched:=float(water.get("collected_today",0.0))
		if measured_hands>0.01 and organized>=0.0:
			var household:=float(water.get("household_collected_today",0.0))
			var other:=float(water.get("conveyed_today",0.0))+float(water.get("rain_collected_today",0.0))
			fetched=minf(float(water.get("total_required_today",need))*1.35+float(water.get("cistern_capacity",0.0)),household+organized*hands/measured_hands+other)
		out["water_ratio"]=clampf(fetched/need,0.0,1.0)
	return out

# --------------------------------------------------------------------------
# Words for the People view, the town page and the court
# --------------------------------------------------------------------------

static func task_words(role:String)->String:
	return String((TASKS.get(role,[role.to_lower()]) as Array)[0])

## "getting food", or "getting food (3) and carrying (2)": the tasks people
## came from or went to, most first.
static func moved_words(moved:Dictionary)->String:
	var keys:=moved.keys()
	keys.sort_custom(func(a:String,b:String)->bool:return int(moved[a])>int(moved[b]))
	if keys.size()==1:return task_words(String(keys[0]))
	var parts:PackedStringArray=[]
	for role:String in keys:parts.append("%s (%d)" % [task_words(role),int(moved[role])])
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[parts.size()-1]

## The leader's line in the People view, from settlement_management():
## "Cendra: food first, the stores are shrinking." One per town, the first
## few; [{text, tip}].
static func leaders_lines(limit:int=3)->Array:
	var out:Array=[]
	var state=_state()
	var many:bool=state.player_settlements.size()>1
	for city:Dictionary in state.player_settlements:
		if out.size()>=limit:break
		if not String(city.get("occupied_by","")).is_empty():continue
		var management:Dictionary=WorldSimulation.government.settlement_management(String(city.get("id","")))
		if management.is_empty():continue
		var who:=String((management.get("leader",{}) as Dictionary).get("name","")).get_slice(" ",0)
		if who=="":who="The leader"
		var focus:=String(management.get("focus","balanced"))
		var first:=String(FOCUS_FIRST.get(focus,"everyday needs"))
		var why:=short_reason(String(management.get("focus_reason","")),bool(management.get("auto_manage",true)))
		var text:="%s%s: %s%s." % [who,(" of %s" % String(city.get("name",""))) if many else "",first,(", "+why) if why!="" else ""]
		var tip:=String(management.get("focus_reason",""))
		if String(management.get("focus_effect",""))!="":tip+="\n"+String(management.focus_effect)
		out.append({"text":text,"tip":tip.strip_edges()})
	return out

## The leader's reason, a few plain words.
static func short_reason(reason:String,delegated:bool)->String:
	if not delegated:return "as you asked"
	var lower:=reason.to_lower()
	if "drinking-water need" in lower or "collection replaced" in lower:return "not all drink enough"
	if "freshwater" in lower:return "no fresh water near"
	if "food requirement" in lower:return "not all ate enough"
	if "shortage in about" in lower:return "a lean season is coming"
	if "shrinking" in lower:return "the stores are shrinking"
	if "shelter currently covers" in lower:return "some sleep out"
	if "stable enough" in lower or "proven strength" in lower:return "all is steady"
	if "security capacity" in lower:return "our towns lie open"
	if "less than a year old" in lower:return "the place is new"
	return ""

## What the court knows of it (court_facts.gd): {ruler, people:{task:n}}.
static func court_facts()->Dictionary:
	return {"ruler":manual(),"people":counts()}

## Those facts in words: the fact sheet's line, or spoken.
static func court_words(facts:Dictionary,spoken:bool)->String:
	var ruler:=bool(facts.get("ruler",false))
	if spoken:return "You set the daily work yourself; our leaders do not change it." if ruler else "Our leaders share out the daily work in each town, food and water first."
	return "you set it yourself; the leaders do not change it" if ruler else "our leaders share it out in each town, food and water first"

## The people at each task, in words: "26 getting food, 3 searching the land, ...".
static func split_words(people:Dictionary)->String:
	var parts:PackedStringArray=[]
	for role:String in ROLES:
		if int(people.get(role,0))>0:parts.append("%d %s" % [int(people[role]),task_words(role)])
	return ", ".join(parts)

## The god's word in court (home_orders.gd work_reading): who sets the work,
## and people moved. says is the official's own plain answer with the real
## numbers, outcome the same account for the voice. {ok, kind, count, says, outcome}.
static func court_order(reading:Dictionary)->Dictionary:
	var mode:=String(reading.get("mode",""))
	var role:=String(reading.get("role",""))
	var out:={"ok":true,"kind":"work","count":0,"says":"","outcome":""}
	if mode=="leaders":
		var changed:=set_manual(false)
		out.count=1 if changed else 0
		var lead:=leaders_lines(1)
		var line:=String((lead[0] as Dictionary).text) if not lead.is_empty() else ""
		out.says=("Our leaders share out the daily work again from today. %s At work now: %s." if changed else "That is already so: our leaders share out the daily work. %s At work now: %s.") % [line,split_words(counts())]
		out.says=out.says.replace("  "," ")
		out.outcome=out.says
		return out
	if role=="":
		var changed:=set_manual(true)
		out.count=1 if changed else 0
		out.says=("From today you set the daily work, and our leaders will not change it. It stands as it was: %s. Tell me how many to move, or change it in The People." if changed else "That is already so: you set the daily work. At work now: %s.") % split_words(counts())
		out.outcome=out.says
		return out
	var asked:=int(reading.get("count",0))
	var named:=asked>0
	var people:=asked if named else maxi(1,roundi(float(able())/20.0))
	var sign:=-1 if bool(reading.get("fewer",false)) else 1
	var other:=String(reading.get("other",""))
	var moved:=move(role,sign*people,other)
	out.count=int(moved.get("moved",0))
	var now:=counts()
	var task:=task_words(role)
	if int(moved.moved)<=0:
		out.ok=false
		out.says=("Nobody is %s now, so nobody can be taken off it. At work now: %s." if sign<0 else "There is nobody to move onto %s: every hand is already there. At work now: %s.") % [task,split_words(now)]
		out.outcome="Nothing is set in motion: "+out.says
		return out
	var short:=(" Only %d could be moved." % int(moved.moved)) if int(moved.moved)<people else ""
	var unnamed:=(" You named no number, so I moved %d." % int(moved.moved)) if not named else ""
	var took:=" From today you set the daily work, and our leaders will not change it." if bool(moved.get("took_charge",false)) else ""
	if sign>0:
		out.says="%d more %s: %d now, up from %d. They come from %s.%s%s%s" % [int(moved.moved),_doing(role,int(moved.moved)),int(now[role]),int((moved.before as Dictionary)[role]),moved_words(moved.from),short,unnamed,took]
	else:
		out.says="%d fewer %s: %d now, down from %d. They go to %s.%s%s%s" % [int(moved.moved),_doing(role,int(moved.moved)),int(now[role]),int((moved.before as Dictionary)[role]),moved_words(moved.to),short,unnamed,took]
	var warn:=outlook()
	for line:Dictionary in warn.lines:
		if String(line.tone)=="bad":out.says+=" "+String(line.text)
	out.outcome=out.says
	return out

## "build", "get food" after "3 more": the task as a verb for people.
static func _doing(role:String,n:int)->String:
	match role:
		"Food":return "get food"
		"Survey":return "search the land"
		"Extraction":return "cut and dig"
		"Construction":return "build"
		"Crafting":return "make tools"
		"Logistics":return "carry"
		"Knowledge":return "keep the lore"
		"Administration":return "keep the stores"
		"Defense":return "keep watch"
	return task_words(role)
