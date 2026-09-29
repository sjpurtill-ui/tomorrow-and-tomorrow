extends RefCounted
## NEW TOWNS: may our leaders found them without the god's word?
##
## One switch and one flag, PeopleDirection.auto_settlement (people_direction.gd,
## saved with the world). The Settlement dock's "New towns" row, the "Our
## course" page and the court ("stop founding new towns", "our leaders may
## settle new land again": home_orders.gd) all read and set it here, so they
## always agree. The leaders act on it at their council (civilization_day.gd),
## only while the switch is on, by the same rule every computer ruler uses
## (civilization_strategy.expansion_months): a people with an expansionist
## tradition looks for land at every monthly council, a bold one every second
## month, an even-tempered one every third, the most cautious every fifth. A
## town the ruler founds by hand never changes it. When the leaders found a
## town themselves, the Chronicle says so once, with how to stop them.
## Static helpers; preload.

const Culture:=preload("res://scripts/cultural_inheritance.gd")
const Strategy:=preload("res://scripts/civilization_strategy.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
## A caravan's day on the road (caravan_system.gd SPEED_KM_DAY).
const WALK_KM_PER_DAY:=16.0
## An expansionist tradition this strong looks for land at every council
## (civilization_strategy.gd EXPANSIONIST_DRIVE).
const EXPANSIONIST_DRIVE:=0.35
## The longest any council waits between searches for land, in months
## (civilization_strategy.gd LONGEST_LOOK_MONTHS).
const LOOK_EVERY_MONTHS:=6
## The way one place lies from another (+x east, +z south; court_facts.compass).
const COMPASS:=["east","southeast","south","southwest","west","northwest","north","northeast"]

const LEADERS_TIP:="Our leaders look for good free land at their council and send settlers when the stores can spare them."
const RULER_TIP:="No settlers leave unless you press Found a new settlement on the map or order it in the court."

static func _controller()->GDScript:
	return load("res://scripts/civilization_controller.gd")

# --------------------------------------------------------------------------
# The switch
# --------------------------------------------------------------------------

## Do our leaders found new towns without being told?
static func on()->bool:
	WorldSimulation.direction.ensure()
	return bool(WorldSimulation.direction.auto_settlement)

## Sets the leaders' leave to found towns. Returns true when it changed; an
## unchanged word touches nothing.
static func set_on(enabled:bool)->bool:
	var direction=WorldSimulation.direction
	direction.ensure()
	if bool(direction.auto_settlement)==enabled:return false
	direction.set_delegated("settlement",enabled)
	return true

# --------------------------------------------------------------------------
# When the leaders look for land
# --------------------------------------------------------------------------

## How strongly the people's own tradition leans to founding new homes.
static func drive(day:int)->float:
	var direction=WorldSimulation.direction
	direction._ensure_cultural_memory()
	return Culture.weight(direction.cultural_memory,"ambition","expansion",day)

## How many months apart our leaders look for land: the people's temper and
## its expansionist tradition, by the rule every council shares.
static func look_months(day:int)->int:
	return Strategy.expansion_months(Strategy.PERSONALITY.of_owner("player"),drive(day))

## Does the leaders' council on this day look for land? Only while the switch
## is on, and as often as the shared rule gives (look_months). The caller
## holds the council on the leaders' review day
## (civilization_controller.review_due).
static func looks_for_land(day:int)->bool:
	if not on():return false
	return Strategy.looks_for_land(day,look_months(day))

## The next council, after today, that looks for land; -1 when none falls
## within about a year.
static func next_look(today:int)->int:
	var months:=look_months(today)
	var controller:=_controller()
	for day in range(today+1,today+400):
		if controller.review_due("player",day) and Strategy.looks_for_land(day,months):return day
	return -1

## What keeps our leaders from sending settlers now, in plain words, or ""
## when nothing does. The same checks as their search for land
## (civilization_controller.expansion_order_steps).
static func holdup()->String:
	var state=WorldSimulation.state
	if not bool(state.settlement_site_committed) or not "Hearth Circle" in state.settlement_completed:return "our first home is not yet standing"
	var convoy:Dictionary=state.settlement_convoy
	if bool(convoy.get("active",false)):return "settlers are already on the road to %s" % String(convoy.get("settlement_name","a new town"))
	var plan:Dictionary=_controller().current_plan("player")
	if bool(plan.get("at_war",false)):return "we are at war"
	if bool(plan.get("hungry",false)):return "our people are going hungry"
	var want:=float(plan.get("expansion_food",0.0))
	var have:=float((state.simulation_metrics as Dictionary).get("food_days",0.0))
	if have<want:
		# In the same words as the Food card ("about 45 days").
		if have>=want*0.9 or Plain.span_text(have)==Plain.span_text(want):return "our leaders want a little more food in store before anyone leaves"
		var now:="almost no food" if have<1.0 else "about %s of food" % Plain.span_text(have)
		return "the stores hold %s, and our leaders want about %s before anyone leaves" % [now,_worth(Plain.span_text(want))]
	return ""

## "2 months' worth", "a day's worth".
static func _worth(span:String)->String:
	return span+("' worth" if span.ends_with("s") else "'s worth")

## How long until their next council that looks for land: "about 4 months".
static func _next_look_words()->String:
	var today:=int(WorldSimulation.state.elapsed_days)
	var day:=next_look(today)
	if day<0:return ""
	return Plain.duration_text(float(day-today))

## A settler caravan on the road now, and that it goes on.
static func _on_the_road()->String:
	var convoy:Dictionary=WorldSimulation.state.settlement_convoy
	if not bool(convoy.get("active",false)):return ""
	return "The settlers already on the road to %s go on unless you call them home." % String(convoy.get("settlement_name","the new ground"))

# --------------------------------------------------------------------------
# Words for the dock and the court
# --------------------------------------------------------------------------

## The Settlement dock's "New towns" row: {on, words, leaders_tip, ruler_tip}.
static func dock()->Dictionary:
	var leaders:=on()
	var words:=""
	if leaders:
		words="Our leaders found a new town on their own when good land is free and the stores can spare the settlers."
		var held:=holdup()
		var look:=_next_look_words()
		if held!="":words+=" Not now: %s." % held
		elif look!="":words+=" They next look for land in %s." % look
	else:
		words="No new town is founded unless you order it. Press Found a new settlement on the map when you want one."
		var road:=_on_the_road()
		if road!="":words+=" "+road
	return {"on":leaders,"words":words,"leaders_tip":LEADERS_TIP,"ruler_tip":RULER_TIP}

## What an official at court knows of it (court_facts.gd): {leaders, why}.
## leaders: the switch, as everyone at court knows it. why (the headman's,
## with detail): what keeps the leaders home or when they next look, or the
## settlers still on the road when the switch is off; "" when nothing.
static func court_facts(detail:bool)->Dictionary:
	var leaders:=on()
	var why:=""
	if detail and leaders:
		var held:=holdup()
		var look:=_next_look_words()
		if held!="":why="not now: "+held
		elif look!="":why="they next look for land in "+look
	elif detail:
		var convoy:Dictionary=WorldSimulation.state.settlement_convoy
		if bool(convoy.get("active",false)):why="the settlers already on the road to %s go on unless you call them home" % String(convoy.get("settlement_name","the new ground"))
	return {"leaders":leaders,"why":why}

## Those facts in words: the fact sheet's line ("our leaders found them on
## their own ...; not now: ...") or, spoken, the official's own answer.
static func court_words(facts:Dictionary,spoken:bool)->String:
	var why:=String(facts.get("why",""))
	var leaders:=bool(facts.get("leaders",false))
	if spoken:
		var said:="Our leaders found new towns on their own when good land is free and the stores can spare the settlers." if leaders else "No new town is founded unless you order it."
		return said+((" %s." % (why.substr(0,1).to_upper()+why.substr(1))) if why!="" else "")
	var line:="our leaders found them on their own when good land is free and the stores can spare the settlers" if leaders else "none is founded unless you order it"
	return line+(("; "+why) if why!="" else "")

## The god's word in court (home_orders.gd): our leaders may found new towns,
## or none without the god's order. Sets the switch; says is the official's
## own plain answer, and the engine's note (outcome) is the same account, so
## the live voice is told exactly what the one who answers says. Never more
## than the switch does: what keeps the leaders at home is said with its
## numbers. {ok, kind, allow, changed, count, says, outcome}.
static func court_order(allow:bool)->Dictionary:
	var changed:=set_on(allow)
	var out:={"ok":true,"kind":"found_towns","allow":allow,"changed":changed,"count":1 if changed else 0}
	var says:=""
	if allow:
		var look:=_next_look_words()
		var when:=("At their next council, in %s, they look for good free land and send settlers if the stores can spare them." % look) if look!="" else "They look for good free land at their council and send settlers if the stores can spare them."
		var held:=holdup()
		var wait:=(" Nobody goes yet: %s." % held) if held!="" else ""
		says=("Our leaders may found new towns again. %s%s" if changed else "That is already so: our leaders may found new towns when good land is free. %s%s") % [when,wait]
	else:
		var road:=_on_the_road()
		var going:=(" "+road) if road!="" else ""
		says=("No new town will be founded unless you order it. Our leaders will not send settlers out on their own.%s" if changed else "That is already so: no new town is founded unless you order it.%s") % going
	out["says"]=says
	out["outcome"]=says
	return out

# --------------------------------------------------------------------------
# The Chronicle
# --------------------------------------------------------------------------

## A town our leaders founded themselves (their convoy carried by_leaders):
## the Chronicle tells it once, where it stands and how to stop them, and
## opens the Settlement dock. Returns the entry told, or {} when it was not
## theirs, is a rival's, or was told before.
static func tell_founded(record:Dictionary,convoy:Dictionary)->Dictionary:
	if not bool(convoy.get("by_leaders",false)):return {}
	var origin:=_vector(convoy.get("origin",Vector2.ZERO))
	var here:=_vector(record.get("position",origin))
	var where:=where_words(origin,here,String(convoy.get("origin_name","")))
	return preload("res://scripts/chronicle.gd").record({"key":"leaders_founded:%s" % String(record.get("id","")),
		"title":"Our leaders founded %s" % String(record.get("name","a new town")),
		"text":"%s — you can stop this in the Settlement panel or tell %s." % [where.substr(0,1).to_upper()+where.substr(1),steward_words()],
		# Told each time, never folded into a tally: the ruler must hear it.
		"tier":"notice","kind":"settlement","domain":"settlement","priority":true,"ledger":false,
		"action":{"kind":"section","section":"settlement","sub":0}})

## "two days' walk northeast of Seanstone": a caravan's days on the road.
static func where_words(from:Vector2,to:Vector2,origin_name:String)->String:
	var days:=from.distance_to(to)/WALK_KM_PER_DAY
	var walk:="less than a day's walk" if days<0.75 else ("a day's walk" if days<1.5 else "%s days' walk" % EraWords.count_word(roundi(days)))
	var place:=origin_name if origin_name!="" else "home"
	var way:=compass(from,to)
	return "%s %s of %s" % [walk,way,place] if way!="" else "%s from %s" % [walk,place]

static func compass(from:Vector2,to:Vector2)->String:
	if from.distance_to(to)<0.01:return ""
	return COMPASS[posmod(roundi(rad_to_deg((to-from).angle())/45.0),8)]

## Whom to tell: the one who holds the headman's office, by its title in
## this age ("the hearth chief"), else the court.
static func steward_words()->String:
	var holder:Dictionary=WorldSimulation.government.officeholder("Steward") if WorldSimulation.government!=null else {}
	var title:=String(holder.get("office_title",""))
	return "the %s" % title.to_lower() if title!="" else "the court"

static func _vector(value:Variant)->Vector2:
	if value is Vector2:return value
	if value is Vector3:return Vector2((value as Vector3).x,(value as Vector3).z)
	if value is Dictionary:return Vector2(float((value as Dictionary).get("x",0.0)),float((value as Dictionary).get("y",(value as Dictionary).get("z",0.0))))
	return Vector2.ZERO
