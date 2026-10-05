extends RefCounted
## ONE SEAT FOR EVERY PEOPLE, growing where it began.
##
## A people does not send settlers off to found separate towns. Its one seat
## grows outward from the spot it was founded on: new neighbourhood centres
## and quarters form as its households fill out (settlement_model.gd
## _attempt_secondary_nucleus, _attempt_mature_district_expansion), and its
## carriers reach farther ground for timber, stone and fibre as it grows
## (reach_rings). Over the centuries the seat becomes a town of districts,
## then a county, a state, and a country (stage).
##
## One rule for every people. A town already standing apart from its seat
## (an older world) is folded into it, people, stores and named people
## together (fold_towns), by the paths a town left for want of water takes
## (dry_towns.gd). A people that has lost its seat to a siege keeps its
## refuge towns until it has a seat again (siege_recovery.gd).
## Static helpers; preload.

const DryTowns:=preload("res://scripts/dry_towns.gd")

## Why no caravan leaves to found a separate town (the court's and the map's
## answer).
const NO_NEW_TOWNS:="Our people do not leave to found separate towns: the seat grows outward, district by district, as its people grow."

## The ground the carriers search for timber, stone and fibre: rings of new
## ground 3 km apart (resource_system.gd SURFACE_FRONT_SPACING_KM). A seat
## reaches BASE_REACH_RINGS rings, one more for every REACH_PEOPLE_STEP
## people under the square root (1,000 people: 4; 10,000: 6; 100,000: 13;
## 1,000,000: 34), never past MAX_REACH_RINGS (about 120 km).
const BASE_REACH_RINGS:=3
const REACH_PEOPLE_STEP:=1000.0
const MAX_REACH_RINGS:=40

## The seat's stages, by its people and its districts (active local
## centres: settlement_model.gd settlement_nuclei). A stage is reached when
## both are met.
const STAGES:=[
	{"id":"settlement","name":"Settlement","people":0,"districts":0},
	{"id":"town","name":"Town of districts","people":400,"districts":2},
	{"id":"county","name":"County","people":10000,"districts":4},
	{"id":"state","name":"State","people":150000,"districts":6},
	{"id":"country","name":"Country","people":2000000,"districts":8},
]

## The land the seat works grows outward with it. When its people press on
## the land they have (past early_life_conditions.gd CROWDING_ONSET of what it
## carries) and they are fed and at peace, the seat claims the next ring of
## land around it, at most once every LAND_CLAIM_DAYS. A claim widens the
## land as a daughter town once did (early_life_conditions.carrying_capacity),
## so crowding holds a people only while hunger or war keep it from reaching
## out, as it did when towns were founded.
const LAND_CLAIM_DAYS:=180
## Days of food in store below which the people does not reach for new land.
const LAND_CLAIM_FOOD_DAYS:=30.0
const EarlyLife:=preload("res://scripts/early_life_conditions.gd")

## Claims the next ring of land for the people in scope when it is due.
## Returns true when land was claimed.
static func claim_land(day:int)->bool:
	if not has_seat():return false
	var seat:=seat_record()
	var last:=int(seat.get("land_claim_day",-LAND_CLAIM_DAYS))
	if day-last<LAND_CLAIM_DAYS:return false
	var state=WorldSimulation.state
	if float(state.simulation_metrics.get("food_days",0.0))<LAND_CLAIM_FOOD_DAYS:return false
	if int(WorldSimulation.world.player_effects().get("war_count",0))>0:return false
	var capacity:=EarlyLife.carrying_capacity(state,WorldSimulation.discovery)
	if EarlyLife.people_on_the_land(state)<EarlyLife.CROWDING_ONSET*capacity:return false
	seat["land_claims"]=int(seat.get("land_claims",0))+1
	seat["land_claim_day"]=day
	return true

## Whether the people in scope has a seat of its own to grow (not lost to a
## siege).
static func has_seat()->bool:
	var military=WorldSimulation.military
	if military!=null and military.recovery!=null and military.recovery.home_unavailable():return false
	return not seat_record().is_empty()

static func seat_record()->Dictionary:
	for city:Variant in WorldSimulation.state.player_settlements:
		if city is Dictionary and bool((city as Dictionary).get("primary",false)):return city
	return {}

## A town standing apart from the seat that would be folded into it.
static func apart(city:Dictionary)->bool:
	if bool(city.get("primary",false)):return false
	if not String(city.get("occupied_by","")).is_empty():return false
	return not WorldSimulation.settlements.abandoned(city)

## Folds every town standing apart into the seat, for the people in scope.
## Returns [{city_id, name, people}] for what was folded.
static func fold_towns(day:int)->Array[Dictionary]:
	var folded:Array[Dictionary]=[]
	if not has_seat():return folded
	var seat:=seat_record()
	var state=WorldSimulation.state
	for city:Dictionary in state.player_settlements:
		if not apart(city):continue
		var share:=maxf(0.0,float(city.get("population_share",0.0)))
		var people:=roundi(share*maxf(0.0,float(state.population_exact)))
		# The same people, now in the seat: the seat's count is what the other
		# towns do not hold, so the realm's count does not change.
		city["population_share"]=0.0
		DryTowns.carry_stores(city,seat)
		DryTowns.redirect_shipments(String(city.get("id","")),seat)
		DryTowns.rehome(String(city.get("id","")),seat)
		folded.append({"city_id":String(city.get("id","")),"name":String(city.get("name","the town")),"people":people})
	if folded.is_empty():return folded
	# The place itself is no longer a town of theirs: it leaves the register,
	# its map mark and its claim on the land with it (the seat's claim is no
	# longer clipped by it). Anything still bound for it goes to the seat
	# (settlement_model.gd lived_in_town_for).
	var gone:={}
	for entry:Dictionary in folded:gone[String(entry.city_id)]=true
	for index in range(state.player_settlements.size()-1,-1,-1):
		if gone.has(String((state.player_settlements[index] as Dictionary).get("id",""))):state.player_settlements.remove_at(index)
	if gone.has(String(state.selected_player_settlement_id)):state.selected_player_settlement_id=String(seat.get("id",""))
	# The land those towns worked stays the people's, as the seat's own.
	seat["land_claims"]=int(seat.get("land_claims",0))+folded.size()
	state.settlement_network_revision+=1
	if WorldSimulation.state==GameState:_tell(folded)
	return folded

## Rings of ground the seat's carriers may search (see BASE_REACH_RINGS).
static func reach_rings()->int:
	var people:=maxf(0.0,float(WorldSimulation.state.population_exact))
	return clampi(BASE_REACH_RINGS+floori(sqrt(people/REACH_PEOPLE_STEP)),BASE_REACH_RINGS,MAX_REACH_RINGS)

## Districts of the seat: its active local centres.
static func districts()->int:
	var count:=0
	for nucleus:Variant in WorldSimulation.state.settlement_nuclei:
		if nucleus is Dictionary and bool((nucleus as Dictionary).get("active",true)):count+=1
	return maxi(1,count)

## {id, name, people, districts, next: {id, name, people, districts} or {}}.
static func stage()->Dictionary:
	var people:=roundi(maxf(0.0,float(WorldSimulation.state.population_exact)))
	var count:=districts()
	var reached:Dictionary=STAGES[0]
	var next:Dictionary={}
	for entry:Dictionary in STAGES:
		if people>=int(entry.people) and count>=int(entry.districts):reached=entry
		else:
			next=entry
			break
	return {"id":String(reached.id),"name":String(reached.name),"people":people,"districts":count,"next":next.duplicate()}

## "County: 12,400 people in 5 districts. A state at 150,000 people and 6
## districts."
static func stage_words()->String:
	var s:=stage()
	var count:=int(s.districts)
	var text:="%s: %s %s in %d %s." % [String(s.name),_thousands(int(s.people)),"person" if int(s.people)==1 else "people",count,"district" if count==1 else "districts"]
	var next:Dictionary=s.next
	if not next.is_empty():
		text+=" %s at %s people and %d districts." % [_article(String(next.name)),_thousands(int(next.people)),int(next.districts)]
	return text

static func _article(name:String)->String:
	return ("An " if name.substr(0,1).to_lower() in ["a","e","i","o","u"] else "A ")+name.to_lower()

static func _thousands(value:int)->String:
	var digits:=str(absi(value))
	var out:=""
	while digits.length()>3:
		out=","+digits.substr(digits.length()-3)+out
		digits=digits.substr(0,digits.length()-3)
	return ("-" if value<0 else "")+digits+out

## One Chronicle line for the god's people.
static func _tell(folded:Array[Dictionary])->void:
	var names:PackedStringArray=[]
	var people:=0
	for entry:Dictionary in folded:
		names.append(String(entry.name))
		people+=int(entry.people)
	var seat:=String(WorldSimulation.state.settlement_name)
	var listed:=", ".join(names) if names.size()<=4 else "%s and %d more" % [", ".join(names.slice(0,3)),names.size()-3]
	preload("res://scripts/chronicle.gd").record({"key":"one_seat:%d" % int(WorldSimulation.state.elapsed_days),
		"title":"Our towns have come home to %s" % seat,
		"text":"The people of %s (%d in all) have moved into %s, with their stores. From now on %s grows outward, district by district." % [listed,people,seat,seat],
		"tier":"notice","kind":"settlement","domain":"settlement",
		"action":{"kind":"section","section":"settlement","sub":0}})
