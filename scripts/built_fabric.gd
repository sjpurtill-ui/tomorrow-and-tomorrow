extends RefCounted
## THE BUILT FABRIC (docs/BUILT_FABRIC.md): what a people's builders have
## made of their towns, kept by their builders' hands and the timber, clay and
## stone the cutters and diggers bring, and lost again without upkeep.
##
## Each town keeps its own fabric (GameState.built_fabric, swapped per town:
## settlement_model.gd CITY_RESOURCE_DEFAULTS):
##   homes   the share of the town's places in each grade of dwelling, from
##           windbreaks and lean-tos to stone houses (GRADES);
##   roads   builder-days of paths, graded roads and paved roads, a person;
##   beauty  fine-work points: carved posts, plazas, painted halls, monuments;
##   works   builder-days of workshops, granaries, kilns, storehouses and water
##           works, a person.
## The whole people keeps one record (GameState.fabric_realm, never swapped):
## the builders' craft (living experience, CRAFT_*), each town's last reading
## (towns) for the realm's readings, and the builders on the walls.
##
## Once a town's people are housed, its builders raise quality, not count:
## every TICK_DAYS the town's free builder-days (builders not on a civic work,
## new homes, a great work or the walls) first pay the upkeep of everything
## that stands, then go to improvements by SPLIT; what one account cannot use
## (homes all at the best grade the people can build, roads at the best the
## people know, works fully covering the town) goes to fine works. Unpaid
## upkeep wears every account down: homes fall a grade (GRADE_WEAR), roads
## roughen (ROAD_WEAR), works decay (WORKS_WEAR) and fine works weather
## (BEAUTY_WEAR). A people that stops building visibly declines.
##
## Every people runs these rules in its own scope; only tendencies (how many
## build) differ. The day's cost is a few comparisons; the reckoning runs once
## every TICK_DAYS per town. tools/sim/model.py mirrors it (FabricModel).

const Construction:=preload("res://scripts/settlement_construction.gd")

## Days between a town's reckonings.
const TICK_DAYS:=10

# --- Homes ---------------------------------------------------------------------------

## Dwellings, worst to best: their grade index is their place in the lists.
const GRADES:=["lean_to","hut","timber","mudbrick","stone"]
const GRADE_WORDS:=["windbreaks and lean-tos","huts","timber houses","mudbrick houses","stone houses"]
const GRADE_SHORT:=["lean-tos","huts","timber","mudbrick","stone"]
## How good each grade is to live in (0 a windbreak, 1 a stone house).
const GRADE_Q:=[0.0,0.3,0.55,0.75,1.0]
## Builder-days to raise one place into each grade from the grade below.
const GRADE_BUILD:=[0.0,3.0,8.0,14.0,30.0]
## Materials one place takes to raise into each grade (loads).
const GRADE_MATERIALS:=[{},{"Timber":0.5,"Fiber Plants":0.5},{"Timber":2.5},{"Clay":4.0,"Timber":0.5},{"Stone":7.0,"Clay":1.0}]
## Builder-days a place of each grade needs a year to stay as it is.
const GRADE_UPKEEP:=[0.0,0.35,0.6,0.8,0.4]
## Share of a grade's places that fall one grade a year when nobody keeps them.
const GRADE_WEAR:=[0.0,0.30,0.15,0.10,0.03]
## What the people must know (any one) to build each grade.
const GRADE_KNOW:=[[],["joinery","thatched_roofing"],["framed_construction","timber_post_beam_connections"],["adobe_wall_construction","mould_made_mudbricks"],["dry_stone_walls","dressed_stone_masonry","kiln_fired_bricks"]]
## Builders' craft at which a grade can first be built, and at which every
## place may be built to it: between them, the share that may be is in
## proportion.
const GRADE_CRAFT:=[0.0,0.0,1.0,2.0,3.0]
const GRADE_CRAFT_FULL:=[0.0,1.0,3.0,5.5,9.0]

## What the homes' quality (0..1, the places' mean GRADE_Q) does in full:
##   health        added to the health the people tend toward
##   weather       added to it again for each unit of the season's cold and
##                 heat (the toll of the weather on those who have a roof:
##                 the shortfall's own exposure deaths are the homes' count)
##   cohesion      added to cohesion's target (contentment under a good roof)
##   illness       illness deaths x (1 - this x quality)
##   sickness      outbreaks of sickness x exp(-this x quality) (crisis_system.gd)
##   fire          fires x exp(-this x quality) (crisis_system.gd)
const HOME_HEALTH:=0.03
const HOME_COHESION:=0.04
const HOME_WEATHER:=0.03
const HOME_ILLNESS:=0.2
const HOME_SICKNESS:=0.3
const HOME_FIRE:=1.0

# --- Roads ---------------------------------------------------------------------------

## Builder-days of road work a person for the best roads the people know.
const ROAD_FULL:=300.0
## Share of the roads' work lost a year without upkeep (ruts, washouts, weeds).
const ROAD_WEAR:=0.08
## Road kinds: [what the people must know (any one), the most the road index
## can reach]. The kinds the map draws (settlement_roads.gd) read the same.
const ROAD_KINDS:=[[[],0.35],[["graded_roads","drained_intertown_roads","road_stations"],0.7],[["paved_haul_roads","aggregate_road_foundations","turnpike_trust_roads"],1.0]]
const ROAD_WORDS:=["paths and tracks","graded roads","paved roads"]
## Stone a builder-day on graded and paved roads (loads).
const ROAD_STONE:=0.12
## What the road index (0..1) does in full:
const ROAD_LOGISTICS:=0.10   # added to the carriers' hauling target (consequence_engine.gd)
const ROAD_HAUL:=0.35        # hauls from the deposits x (1 + this x roads) (resource_system.gd)
const ROAD_SPEED:=0.6        # goods, caravans and founding parties between towns x (1 + this x roads)
const ROAD_REACH:=0.5        # trade reach x (1 + this x roads) (trade_ledger.gd, settlement_model.gd)
const ROAD_RISE:=0.3         # townsfolk who reach the fight x (1 + this x roads) (civilization_combat.gd)
## The road index at which the map draws each kind (settlement_roads.gd).
const ROAD_DRAW:=[0.0,0.32,0.62]
## An older save's roads start this far past the kind the map drew.
const ROAD_SEED_MARGIN:=0.03

# --- Beauty --------------------------------------------------------------------------

## Fine-work points a person at which beauty reads 63% of its most.
const BEAUTY_SCALE:=600.0
## Share of the fine works' points lost a year without upkeep (weathering).
const BEAUTY_WEAR:=0.04
## Practices of fine work; each known makes a builder-day of fine work worth
## ARTISTRY_EACH more.
const ARTISTRY:=["shrine_wall_painting","megalith_raising","shrine_terraces","stone_relief_carving","niched_brick_facades","stepped_stone_tombs","stepped_temple_towers","palace_wall_painting","royal_stone_portraits"]
const ARTISTRY_EACH:=0.2
## Loads of stone, timber or clay a builder-day of fine work takes.
const BEAUTY_MATERIALS:=0.2
## What beauty (0..1) does in full:
const BEAUTY_COHESION:=0.03  # cohesion's target (civic_building_effects.gd)
const BEAUTY_DEVOTION:=0.05  # the people's love of the god (divine_regard.gd)
const BEAUTY_SPLENDOR:=0.4   # Splendor (standing.gd): pride and awe
const BEAUTY_CULTURE:=0.5   # the allure of our culture abroad (standing.gd)
const BEAUTY_RESPECT:=0.10   # what others' envoys and travellers respect (standing.gd)

# --- Works ---------------------------------------------------------------------------

## Builder-days a person of work buildings for full cover of the town.
const WORKS_FULL:=600.0
## Share lost a year without upkeep.
const WORKS_WEAR:=0.05
## Loads of timber, clay or stone (whichever is most in store) a builder-day
## of work buildings takes.
const WORKS_LOADS:=0.25
## The work buildings and what each needs known first ("" none).
const WORKS:=["workshops","granaries","kilns","storehouses","water"]
const WORKS_KNOW:={"workshops":"","granaries":"","kilns":"kiln_control","storehouses":"","water":"well_siting"}
const WORKS_WORDS:={"workshops":"workshops","granaries":"granaries","kilns":"kilns","storehouses":"storehouses and yards","water":"wells and water works"}
const WORKS_ROLE:={"workshops":"Crafting","granaries":"Food","kilns":"Construction","storehouses":"Logistics","water":"Logistics"}
## What full cover does:
const WORKSHOP_MAKING:=0.20      # makers' goods x (1 + this) (civilian_goods.gd)
const GRANARY_ROT:=0.25          # stored food rots x (1 - this) (food_system.gd)
const KILN_BUILDING:=0.10        # the builders' own work x (1 + this): fired brick and lime
const STOREHOUSE_LOGISTICS:=0.06 # added to the carriers' hauling target
const STOREHOUSE_EXTRACTION:=0.15 # every deposit worked gives this much more (resource_system.gd)
const WATERWORKS_WATER:=0.30     # water each carrier brings x (1 + this) (resource_system.gd)

# --- Splitting the builders' work ----------------------------------------------------

## Improvements' shares of the builder-days left after upkeep; what an
## account cannot use goes to the others in proportion, fine works last.
const SPLIT:={"homes":0.35,"roads":0.15,"works":0.20,"beauty":0.30}
## Who is kept first when there are too few builders for all the upkeep.
const UPKEEP_ORDER:=["homes","walls","works","roads","beauty"]
## THE TOWN'S BUILDERS, EACH ON ONE THING (crews): every builder the town
## counts (a great work's crew and military works are already out,
## game_state.gd effective_workers) is on one of these, in this order:
##   homes   all of them while some sleep without a roof; HOMES_AHEAD of them
##           while new homes go up ahead of need (settlement_construction.gd)
##   civic   CIVIC_SHARE of the rest while a civic work is in hand
##   repair  what the town's civic works need to be kept in repair: REPAIR_SHARE
##           of the people at most (half that once in full repair), as
##           settlement_model.gd _advance_city_form counts its builders
##   walls   at home, WALL_SHARE of the rest while a defence stage goes up or
##           the walls are being mended (military_campaign.gd settlement_defense)
##   fabric  the rest: the upkeep and improvement of the town's fabric
const HOMES_AHEAD:=0.3
const CIVIC_SHARE:=0.5
const REPAIR_SHARE:=0.05
const WALL_SHARE:=0.4
## The walls' upkeep a year, as a share of their stage's work; unkept, they
## wear WALL_WEAR of their integrity a year.
const WALL_UPKEEP:=0.01

# --- Craft -----------------------------------------------------------------------------

## Living experience fades e-fold over this many years (a working life and a half).
const CRAFT_YEARS:=36.0
## Builder-days of living experience a person of the people for each level.
const CRAFT_PER_LEVEL:=275.0
const CRAFT_MAX:=10.0
## Each level of craft: the builders' work x (1 + CRAFT_WORK), building
## knowledge (the infrastructure line) x (1 + CRAFT_RESEARCH), the
## construction signal every building question reads + CRAFT_SIGNAL
## (civilization_day.gd context), a builder's work on walls x (1 +
## CRAFT_WALLS), walls hold CRAFT_WALL_QUALITY better.
const CRAFT_WORK:=0.03
const CRAFT_RESEARCH:=0.04
const CRAFT_SIGNAL:=0.12
const CRAFT_WALLS:=0.05
const CRAFT_WALL_QUALITY:=0.02

# --- Might -----------------------------------------------------------------------------

## The home town's stone: defence and stores raiders cannot reach, + this x
## the share of its places that are stone (immovability).
const STONE_DEFENSE:=0.15
const STONE_STORES:=0.10
## A builder on the walls works this many times a watchman's share; on stone
## stages (STONE_STAGE and above) a watchman without builders works at
## STONE_WATCH of his usual pace.
const BUILDER_WALL_WEIGHT:=1.5
const STONE_STAGE:=4
const STONE_WATCH:=0.35
## Walls wear WALL_WEAR of their integrity a year while their upkeep goes
## undone (the town's fabric keeps them, after its homes: UPKEEP_ORDER).
const WALL_WEAR:=0.03
## Might (standing.gd): + FORT_MIGHT x the defences (bonus over BASTION_BONUS);
## our fighting strength as others weigh it x (1 + FORT_STRENGTH x bonus).
const FORT_MIGHT:=0.4
const FORT_STRENGTH:=0.8
const BASTION_BONUS:=0.62
## Builders who want walls: the people's council weighs danger plus this a
## level of craft past WALL_WISH_FROM (civilization_controller.gd
## defense_decision), at most WALL_WISH_MAX.
const WALL_WISH:=0.14
const WALL_WISH_FROM:=2.0
const WALL_WISH_MAX:=0.6

# --- Great works -------------------------------------------------------------------------

## Capability a great work's builders bring (wonder_concept.gd assess): this a
## level of craft, and up to GREAT_BUILDERS with the crew on the work (full at
## GREAT_CREW builders on it) and GREAT_MATERIALS x (cover - 0.5) of the bill
## in store. A work not yet begun counts the crew it would get
## (GREAT_CREW_SHARE of the builders, undertaking_system.gd advance_record).
const GREAT_CRAFT:=0.025
const GREAT_BUILDERS:=0.05
const GREAT_CREW:=15.0
const GREAT_CREW_SHARE:=0.20
const GREAT_MATERIALS:=0.06
## The payoff (strength, rewards and allure of a work that stands) x (1 +
## GREAT_PAYOFF a level of craft).
const GREAT_PAYOFF:=0.05


# ===========================================================================================
# The ledger
# ===========================================================================================

## This town's fabric (the one in scope), made on first use.
static func data()->Dictionary:
	var f:Dictionary=WorldSimulation.state.built_fabric
	if int(f.get("v",0))<1:_found(f)
	return f

## This town's fabric for a reading (screens, the court): the stored one, or
## before the first reckoning, the one it would begin with, not stored (a
## reading never changes the ledger it reads).
static func peek()->Dictionary:
	var f:Dictionary=WorldSimulation.state.built_fabric
	if int(f.get("v",0))>=1:return f
	# The people's craft is seeded as any first reading of an older save seeds
	# it (realm_data); the town's own record waits for its first day.
	realm_data()
	var fresh:={}
	_found(fresh,false)
	return fresh

## The whole people's record.
static func realm_data()->Dictionary:
	var r:Dictionary=WorldSimulation.state.fabric_realm
	if int(r.get("v",0))<1:
		r.merge({"v":1,"xp":0.0,"decay_day":int(WorldSimulation.state.elapsed_days),"towns":{},"wall_builders":0.0,"wall_ready":0.0,"walls_kept":1.0},true)
		# An older save: the builders already have the experience their
		# present work would have given them, without the founding years
		# (this town's builders read for the whole people).
		var builders:=_all_builders()*_national()/maxf(1.0,float(WorldSimulation.state.population_exact))
		var years:=minf(CRAFT_YEARS,maxf(0.0,float(WorldSimulation.state.elapsed_days)/365.0))
		r.xp=builders*_labor()*365.0*CRAFT_YEARS*(1.0-exp(-years/CRAFT_YEARS))
	return r

## A town's fabric begins as it stands: the founders' carried shelters are
## lean-tos; an older save's places stand at the grades the people could
## build at their present craft (no sudden fall), with roads, works and fine
## works at what the town's age would have given.
static func _found(f:Dictionary,store:bool=true)->void:
	if store:realm_data()
	var homes:=[1.0,0.0,0.0,0.0,0.0]
	var settled:=float(WorldSimulation.state.elapsed_days)-float(maxi(0,int(WorldSimulation.state.settlement_founded_day)))
	if settled>365.0*3.0:
		var caps:=grade_caps()
		for g in range(GRADES.size()-1,0,-1):
			var above:=0.0
			for k in range(g+1,GRADES.size()):above+=float(homes[k])
			homes[g]=maxf(0.0,float(caps[g])*0.7-above)
		var placed:=0.0
		for g in range(1,GRADES.size()):placed+=float(homes[g])
		homes[0]=maxf(0.0,1.0-placed)
	# An older save's roads stand at the kind the map already drew for what
	# the people know (settlement_roads.gd known_tier), so its map and its
	# marches lose nothing.
	var roads:=0.0
	if settled>365.0*3.0:
		var drawn:=int((load("res://scripts/settlement_roads.gd") as GDScript).call("known_tier",WorldSimulation.state))
		if drawn>0:roads=minf(road_cap(),float(ROAD_DRAW[mini(drawn,ROAD_DRAW.size()-1)])+ROAD_SEED_MARGIN)*ROAD_FULL*maxf(1.0,float(WorldSimulation.state.population_exact))
	f.merge({"v":1,"day":int(WorldSimulation.state.elapsed_days),"homes":homes,"places":maxi(0,int(WorldSimulation.state.housing_capacity)),
		"roads":roads,"beauty":0.0,"works":0.0,"spent":{},"paid":1.0,"effects":{}},true)
	_cache(f)
	# The realm reads every town's fabric from its first day, not its first
	# reckoning (built_fabric realm readings: roads, beauty, stone).
	if store:_report_town(f,realm_data())

## The day: nothing until TICK_DAYS have passed, then the town's reckoning.
## settlement_construction.gd process_day calls it in every town's scope.
static func process_day()->void:
	var f:=data()
	var days:=int(WorldSimulation.state.elapsed_days)-int(f.get("day",0))
	if days<TICK_DAYS:return
	reckon(f,float(days))
	f.day=int(WorldSimulation.state.elapsed_days)

## One reckoning over `days`: the craft, the places come and gone, upkeep,
## improvements and the effects every reader uses until the next one.
static func reckon(f:Dictionary,days:float)->void:
	var realm:=realm_data()
	var years:=days/365.0
	_grow_craft(realm,days)
	_follow_places(f)
	var crew:=crews()
	if _is_home():
		realm.wall_builders=float(crew.walls)
		realm.wall_ready=float(crew.walls_ready)
	var budget:=float(crew.fabric)*_labor()*days*(1.0+CRAFT_WORK*craft())*(1.0+KILN_BUILDING*works_cover("kilns",f))
	var pop:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var places:=maxf(1.0,float(f.places))
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var avail:=_spare(pop,stocks)
	# Upkeep first, of everything that stands.
	var homes:Array=f.homes
	var home_need:=0.0
	for g in GRADES.size():home_need+=float(homes[g])*places*float(GRADE_UPKEEP[g])*years
	var road_need:=float(f.roads)*ROAD_WEAR*years
	var works_need:=float(f.works)*WORKS_WEAR*years
	var beauty_need:=float(f.beauty)*BEAUTY_WEAR*years/maxf(1.0,artistry())
	var walls_need:=_walls_upkeep()*years
	var need:=home_need+walls_need+road_need+works_need+beauty_need
	# Upkeep in UPKEEP_ORDER: homes, the walls, then work buildings, roads,
	# and fine works last; what is not kept wears.
	var kept:={}
	var upkeep:=0.0
	var wants:={"homes":home_need,"walls":walls_need,"works":works_need,"roads":road_need,"beauty":beauty_need}
	for key:String in UPKEEP_ORDER:
		var want:=float(wants[key])
		var pay:=minf(budget,want)
		budget-=pay;upkeep+=pay
		kept[key]=clampf(pay/want,0.0,1.0) if want>0.0 else 1.0
	f.paid=clampf(upkeep/need,0.0,1.0) if need>0.0 else 1.0
	f.kept=kept
	if _is_home():realm.walls_kept=float(kept.walls)
	for g in range(GRADES.size()-1,0,-1):
		var fall:=float(homes[g])*minf(1.0,float(GRADE_WEAR[g])*years*(1.0-float(kept.homes)))
		homes[g]=float(homes[g])-fall;homes[g-1]=float(homes[g-1])+fall
	f.roads=float(f.roads)*(1.0-minf(1.0,ROAD_WEAR*years*(1.0-float(kept.roads))))
	f.works=float(f.works)*(1.0-minf(1.0,WORKS_WEAR*years*(1.0-float(kept.works))))
	f.beauty=float(f.beauty)*(1.0-minf(1.0,BEAUTY_WEAR*years*(1.0-float(kept.beauty))))
	# Then the improvements.
	var spent:={"upkeep":upkeep,"homes":0.0,"roads":0.0,"works":0.0,"beauty":0.0,"walls":float(crew.walls)*_labor()*days}
	var shares:Dictionary=SPLIT.duplicate()
	for round_index in 3:
		if budget<=0.001:break
		var total:=0.0
		for key in shares:total+=float(shares[key])
		if total<=0.0:break
		var left:=0.0
		for key:String in shares.keys():
			var offer:=budget*float(shares[key])/total
			var used:=0.0
			match key:
				"homes":used=_raise_homes(f,offer,places,avail,stocks)
				"roads":used=_lay_roads(f,offer,pop,avail,stocks)
				"works":used=_raise_works(f,offer,pop,avail,stocks)
				"beauty":used=_raise_beauty(f,offer,avail,stocks)
			spent[key]=float(spent[key])+used
			left+=offer-used
			if used<offer*0.999 and key!="beauty":shares.erase(key)
		budget=left
	f.spent=spent
	f.budget=float(spent.upkeep)+float(spent.homes)+float(spent.roads)+float(spent.works)+float(spent.beauty)
	f.idle=budget
	_cache(f)
	_report_town(f,realm)

## The places a town has now: new places (a new batch of homes) are put up
## at the plainest grade the people build; places lost to fire, flood or war
## are lost from every grade alike.
static func _follow_places(f:Dictionary)->void:
	var now:=maxi(0,int(WorldSimulation.state.housing_capacity))
	var before:=maxi(0,int(f.get("places",now)))
	var homes:Array=f.homes
	if now>before and now>0:
		var base:=1 if float(grade_caps()[1])>=0.5 else 0
		for g in GRADES.size():homes[g]=float(homes[g])*float(before)/float(now)
		homes[base]=float(homes[base])+float(now-before)/float(now)
	f.places=now

## Raise places, plainest first, toward the best grade the people can build;
## returns the builder-days used.
static func _raise_homes(f:Dictionary,offer:float,places:float,avail:Dictionary,stocks:Dictionary)->float:
	var homes:Array=f.homes
	var caps:=grade_caps()
	var used:=0.0
	for g in range(1,GRADES.size()):
		# Places already at this grade or better, against what may be.
		var at_or_above:=0.0
		for k in range(g,GRADES.size()):at_or_above+=float(homes[k])
		var room:=maxf(0.0,float(caps[g])-at_or_above)
		var below:=float(homes[g-1])
		var move:=minf(room,below)
		if move<=0.0:continue
		var cost:=float(GRADE_BUILD[g])
		var by_work:=(offer-used)/maxf(0.001,cost*places)
		var by_stuff:=_affordable(GRADE_MATERIALS[g],places,avail)
		move=minf(move,minf(by_work,by_stuff))
		if move<=0.0:continue
		homes[g-1]=below-move;homes[g]=float(homes[g])+move
		_take(GRADE_MATERIALS[g],move*places,avail,stocks)
		used+=move*places*cost
		if used>=offer*0.999:break
	return used

static func _lay_roads(f:Dictionary,offer:float,pop:float,avail:Dictionary,stocks:Dictionary)->float:
	var room:=maxf(0.0,road_cap()*ROAD_FULL*pop-float(f.roads))
	var work:=minf(offer,room)
	var bill:={"Stone":ROAD_STONE} if road_kind()>0 else {}
	work=minf(work,_affordable(bill,1.0,avail))
	if work<=0.0:return 0.0
	f.roads=float(f.roads)+work
	_take(bill,work,avail,stocks)
	return work

static func _raise_works(f:Dictionary,offer:float,pop:float,avail:Dictionary,stocks:Dictionary)->float:
	var room:=maxf(0.0,WORKS_FULL*pop-float(f.works))
	var work:=_take_any(minf(offer,room),WORKS_LOADS,avail,stocks)
	f.works=float(f.works)+work
	return work

## Fine works take any of stone, timber or clay, whichever is most in store.
static func _raise_beauty(f:Dictionary,offer:float,avail:Dictionary,stocks:Dictionary)->float:
	var work:=_take_any(offer,BEAUTY_MATERIALS,avail,stocks)
	f.beauty=float(f.beauty)+work*artistry()
	return work

## Up to `work` builder-days of a work that takes `loads` a builder-day of
## stone, timber or clay, drawn in proportion to what is spare of each;
## returns the builder-days the materials allow.
static func _take_any(work:float,loads:float,avail:Dictionary,stocks:Dictionary)->float:
	var held:=0.0
	for item in ["Stone","Timber","Clay"]:held+=float(avail.get(item,0.0))
	work=minf(work,held/maxf(0.001,loads))
	if work<=0.0:return 0.0
	var bill:={}
	for item in ["Stone","Timber","Clay"]:bill[item]=loads*float(avail.get(item,0.0))/maxf(0.001,held)
	_take(bill,work,avail,stocks)
	return work

## Materials above what the town keeps back for its other works: RESERVE a
## person of each, or the bills of the civic works, arms and plants it is
## gathering for (local_material_reserves.gd), what its great works under way
## have still to use (great_bills) and, at home, the next defence stage's
## (home_defense.gd material_targets), whichever is more.
const RESERVE:=1.0
const MATERIALS:=["Timber","Clay","Stone","Fiber Plants"]
static func _spare(pop:float,stocks:Dictionary)->Dictionary:
	var kept:Dictionary=preload("res://scripts/local_material_reserves.gd").calculate()
	var walls:Dictionary=preload("res://scripts/home_defense.gd").material_targets() if _is_home() and WorldSimulation.military!=null else {}
	var works:=great_bills()
	var out:={}
	for item:String in MATERIALS:
		var reserve:=maxf(RESERVE*pop,float(kept.get(item,0.0))+float(walls.get(item,0.0))+float(works.get(item,0.0)))
		out[item]=maxf(0.0,float(stocks.get(item,0.0))-reserve)
	return out

## What the great works under way in this town have still to use, {material:
## loads}: each one's bill for the work not yet done (undertaking_system.gd
## _spend draws it as the work goes).
static func great_bills()->Dictionary:
	var U=preload("res://scripts/undertaking_system.gd")
	var out:={}
	for r:Dictionary in U.current_city(WorldSimulation.state).get("undertakings",[]):
		if String(r.get("status","")) not in ["building","stalled"]:continue
		var cost:Dictionary=preload("res://scripts/undertaking_catalog.gd").get_definition(String(r.id)).get("cost",{})
		var left:=1.0-U.fraction(r)
		for item:String in cost:out[item]=float(out.get(item,0.0))+float(cost[item])*left
	return out

static func _affordable(bill:Dictionary,per:float,avail:Dictionary)->float:
	var most:=INF
	for item:String in bill:
		var each:=float(bill[item])*per
		if each>0.0:most=minf(most,float(avail.get(item,0.0))/each)
	return most

static func _take(bill:Dictionary,amount:float,avail:Dictionary,stocks:Dictionary)->void:
	for item:String in bill:
		var used:=float(bill[item])*amount
		avail[item]=maxf(0.0,float(avail.get(item,0.0))-used)
		stocks[item]=maxf(0.0,float(stocks.get(item,0.0))-used)


# ===========================================================================================
# Builders and craft
# ===========================================================================================

## The town's builders, each on one thing (see HOMES_AHEAD ... WALL_SHARE):
## {builders, homes, homes_if (the homes' crew were new homes going up),
## civic, civic_if, repair, repair_want, walls, walls_ready (the walls' crew
## were a stage going up), fabric}. Every consumer reads its own crew here,
## so no builder works two jobs in a day. `extra`: that many more builders
## (what more builders would do, for the screens).
static func crews(extra:float=0.0)->Dictionary:
	var state=WorldSimulation.state
	var builders:=maxf(0.0,float(state.effective_workers("Construction"))+extra)
	var short:=int(state.population_total)>int(state.housing_capacity)
	var homes_if:=builders if short else builders*HOMES_AHEAD
	var homes:=homes_if if Construction.housing_under_way() else 0.0
	var rest:=builders-homes
	var civic_if:=rest*CIVIC_SHARE
	var civic:=civic_if if not Construction._current_settlement_project().is_empty() else 0.0
	rest-=civic
	var want:=repair_want()
	var repair:=minf(rest,want)
	rest-=repair
	var walls_ready:=rest*WALL_SHARE if _is_home() else 0.0
	var walls:=walls_ready if _walls_at_work() else 0.0
	rest-=walls
	return {"builders":builders,"homes":homes,"homes_if":homes_if,"civic":civic,"civic_if":civic_if,"repair":repair,"repair_want":want,"walls":walls,"walls_ready":walls_ready,"fabric":maxf(0.0,rest)}

## Builders the town's civic works need to be kept in repair: REPAIR_SHARE of
## its people while its repair is short, half that once full (the monthly
## wear, settlement_model.gd _advance_city_form), less with repair skill.
static func repair_want()->float:
	if WorldSimulation.settlements==null or not WorldSimulation.settlements.has_method("city_form"):return 0.0
	var condition:=float(WorldSimulation.settlements.city_form().get("condition",1.0))
	var people:=maxf(1.0,float(WorldSimulation.state.population_total))
	var mending:float=maxf(0.5,float(preload("res://scripts/research_mechanics.gd").mending_factor()))
	return people*REPAIR_SHARE*(1.0 if condition<0.995 else 0.5/mending)

## settlement_model.gd _advance_city_form: the repair crew's share of the
## builders the town's repair can use (1 = REPAIR_SHARE of its people).
static func repair_share()->float:
	var people:=maxf(1.0,float(WorldSimulation.state.population_total))
	return clampf(float(crews().repair)/(people*REPAIR_SHARE),0.0,1.0)

## Whether the home town's builders are on the walls: a stage going up, or
## walls being mended after a fight.
static func _walls_at_work()->bool:
	if not _is_home() or WorldSimulation.military==null:return false
	var ledger:Dictionary=WorldSimulation.military.settlement_defense
	if int(ledger.get("project_stage",-1))>=0:return true
	return int(ledger.get("stage",0))>0 and float(ledger.get("integrity",1.0))<0.999

## The home town's builders on the walls now (military_campaign.gd reads it):
## its walls crew at the last reckoning.
static func wall_builders()->float:
	return float(WorldSimulation.state.fabric_realm.get("wall_builders",0.0))

## The builders who would go to the walls were a stage begun (the council
## and the screens judge the next stage with them).
static func wall_builders_ready()->float:
	return float(WorldSimulation.state.fabric_realm.get("wall_ready",0.0))

## The walls' upkeep a year in builder-days: WALL_UPKEEP of the standing
## stage's work, at home only.
static func _walls_upkeep()->float:
	if not _is_home() or WorldSimulation.military==null:return 0.0
	var mc=WorldSimulation.military
	var stage:=int(mc.settlement_defense.get("stage",0))
	if stage<=0:return 0.0
	return float((mc.SETTLEMENT_DEFENSE_STAGES[clampi(stage,0,mc.SETTLEMENT_DEFENSE_STAGES.size()-1)] as Dictionary).work)*WALL_UPKEEP

static func _is_home()->bool:
	var id:=String(WorldSimulation.state.resource_settlement_id)
	if id.is_empty():return true
	return bool(WorldSimulation.settlements.settlement_record(id).get("primary",false))

static func _labor()->float:
	return clampf(float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",0.72)),0.2,1.2)

static func _all_builders()->float:
	return maxf(0.0,float(WorldSimulation.state.population_allocations.get("Construction",0)))

## The whole people's number, inside a town's count too.
static func _national()->float:
	if WorldSimulation.settlements!=null and WorldSimulation.settlements.has_method("national_population"):return maxf(1.0,float(WorldSimulation.settlements.national_population()))
	return maxf(1.0,float(WorldSimulation.state.population_exact))

## Experience: every builder of the town adds a builder-day a day; the
## people's experience fades e-fold over CRAFT_YEARS (once for the realm,
## whichever town reckons first).
static func _grow_craft(realm:Dictionary,days:float)->void:
	var today:=int(WorldSimulation.state.elapsed_days)
	var since:=float(today-int(realm.get("decay_day",today)))
	if since>0.0:
		realm.xp=float(realm.xp)*exp(-since/(CRAFT_YEARS*365.0))
		realm.decay_day=today
	realm.xp=float(realm.xp)+_all_builders()*_labor()*days

## The builders' craft, 0..CRAFT_MAX: living experience a person of the people.
static func craft()->float:
	var realm:Dictionary=WorldSimulation.state.fabric_realm
	return clampf(float(realm.get("xp",0.0))/_national()/CRAFT_PER_LEVEL,0.0,CRAFT_MAX)

## Where the craft is heading at today's builders: the level it settles at.
## Every town's builders count (their builder-days a day at each town's last
## reckoning), against the whole people.
static func craft_settles()->float:
	var towns:Dictionary=WorldSimulation.state.fabric_realm.get("towns",{})
	var rate:=0.0
	for town:Dictionary in towns.values():rate+=float(town.get("builder_days",0.0))
	if towns.is_empty():rate=_all_builders()*_labor()*_national()/maxf(1.0,float(WorldSimulation.state.population_exact))
	return clampf(rate*365.0*CRAFT_YEARS/_national()/CRAFT_PER_LEVEL,0.0,CRAFT_MAX)


# ===========================================================================================
# What the people can build
# ===========================================================================================

static func _knows(ids:Array)->bool:
	if ids.is_empty():return true
	var known:Array=WorldSimulation.state.known_discoveries
	for id in ids:
		if String(id) in known:return true
	return false

## The most of the places that may be at each grade or better (0..1), by
## what the people know and their builders' craft.
static func grade_caps()->Array:
	var level:=craft()
	var caps:=[1.0,0.0,0.0,0.0,0.0]
	for g in range(1,GRADES.size()):
		if not _knows(GRADE_KNOW[g]):break
		var span:=maxf(0.01,float(GRADE_CRAFT_FULL[g])-float(GRADE_CRAFT[g]))
		caps[g]=minf(float(caps[g-1]),clampf((level-float(GRADE_CRAFT[g]))/span,0.0,1.0))
	return caps

## The best road the people know how to make: 0 paths, 1 graded, 2 paved.
static func road_kind()->int:
	var kind:=0
	for k in range(1,ROAD_KINDS.size()):
		if _knows(ROAD_KINDS[k][0]):kind=k
	return kind

static func road_cap()->float:
	return float(ROAD_KINDS[road_kind()][1])

## A builder-day of fine work is worth this many points.
static func artistry()->float:
	var n:=0
	var known:Array=WorldSimulation.state.known_discoveries
	for id in ARTISTRY:
		if String(id) in known:n+=1
	return 1.0+ARTISTRY_EACH*float(n)


# ===========================================================================================
# Readings (cached at each reckoning; the daily readers only look them up)
# ===========================================================================================

static func _cache(f:Dictionary)->void:
	var homes:Array=f.homes
	var q:=0.0
	for g in GRADES.size():q+=float(homes[g])*float(GRADE_Q[g])
	var pop:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var roads:=clampf(float(f.roads)/(ROAD_FULL*pop),0.0,road_cap())
	var beauty:=1.0-exp(-float(f.beauty)/pop/BEAUTY_SCALE)
	var cover:=clampf(float(f.works)/(WORKS_FULL*pop),0.0,1.0)
	f.effects={"quality":q,"roads":roads,"beauty":beauty,"cover":cover,"stone":float(homes[GRADES.size()-1])}

static func _effects()->Dictionary:
	var f:Dictionary=WorldSimulation.state.built_fabric
	if int(f.get("v",0))<1:
		# A loaded older save's first day: the town as it stands, founded now.
		if not bool(WorldSimulation.state.settlement_site_committed):return {}
		f=data()
	var e:Variant=f.get("effects",{})
	return e if e is Dictionary else {}

## The town's homes' quality, 0..1.
static func quality()->float:return float(_effects().get("quality",0.0))
## The town's road index, 0..1.
static func roads()->float:return float(_effects().get("roads",0.0))
## The town's beauty, 0..1.
static func beauty()->float:return float(_effects().get("beauty",0.0))
## The share of the town's places that are stone.
static func stone()->float:return float(_effects().get("stone",0.0))

## How fully one work building serves the town (0..1): the works' cover,
## once the people know what it needs.
static func works_cover(kind:String,f:Dictionary={})->float:
	var e:Dictionary=_effects() if f.is_empty() else (f.get("effects",{}) as Dictionary)
	var need:=String(WORKS_KNOW.get(kind,""))
	if not need.is_empty() and not _knows([need]):return 0.0
	return float(e.get("cover",0.0))

# --- What the engine reads ------------------------------------------------------------------

## consequence_engine.gd: health target.
static func health_bonus()->float:return HOME_HEALTH*quality()
## consequence_engine.gd: the toll of the season's cold and heat on those who
## have a roof, lifted by good homes (0 in windbreaks).
static func weather_bonus(cold:float,heat:float)->float:return HOME_WEATHER*clampf(cold+heat*0.75,0.0,2.0)*quality()
## consequence_engine.gd: Illness deaths x this.
static func illness_factor()->float:return 1.0-HOME_ILLNESS*quality()
## consequence_engine.gd: added to the carriers' hauling target.
static func logistics_bonus()->float:return ROAD_LOGISTICS*roads()+STOREHOUSE_LOGISTICS*works_cover("storehouses")
## resource_system.gd: hauls x this.
static func haul_factor()->float:return 1.0+ROAD_HAUL*roads()
## resource_system.gd: water each carrier brings x this.
static func water_factor()->float:return 1.0+WATERWORKS_WATER*works_cover("water")
## resource_system.gd: added to the output of every deposit worked (yards
## where cut timber and stone are stacked, sorted and kept dry).
static func extraction_bonus()->float:return STOREHOUSE_EXTRACTION*works_cover("storehouses")
## civilian_goods.gd: makers' goods x this.
static func making_factor()->float:return 1.0+WORKSHOP_MAKING*works_cover("workshops")
## food_system.gd: stored food rots x this.
static func granary_factor()->float:return 1.0-GRANARY_ROT*works_cover("granaries")

## civic_building_effects.gd effect(key): the fabric's share of the town's
## civic effects (cohesion from good homes and fine works, the people's love
## of the god from works raised to it).
static func civic(key:String)->float:
	match key:
		"cohesion":return HOME_COHESION*quality()+BEAUTY_COHESION*beauty()
	return 0.0

## divine_regard.gd: the people's love of the god from the works raised to it,
## in every town.
static func devotion()->float:return BEAUTY_DEVOTION*realm_beauty()

## settlement_model.gd city_trade_capacity and every caravan: speed x this.
static func speed_factor()->float:return 1.0+ROAD_SPEED*realm_roads()
## trade_ledger.gd, settlement_model.gd: reach x this.
static func reach_factor()->float:return 1.0+ROAD_REACH*realm_roads()
## civilization_combat.gd: townsfolk who reach the fight x this.
static func rise_factor()->float:return 1.0+ROAD_RISE*realm_roads()

## discovery_system.gd leader factor: building knowledge comes faster with craft.
static func research_multiplier(direction:String)->float:
	return 1.0+CRAFT_RESEARCH*craft() if direction=="infrastructure" else 1.0

## civilization_day.gd context: the construction signal (1 at the Hearth Circle).
static func construction_signal()->float:return 1.0+CRAFT_SIGNAL*craft()

# --- Might ------------------------------------------------------------------------------------

## The home town's stone share (the defences read the home town).
static func home_stone()->float:
	var town:Dictionary=(realm_data().towns as Dictionary).get("home",{})
	return float(town.get("stone",stone() if _is_home() else 0.0))

## military_campaign.gd settlement_defense_snapshot: the defence works'
## bonus x this (walls kept by skilled builders hold better).
static func wall_quality()->float:return 1.0+CRAFT_WALL_QUALITY*craft()
## ... plus this, the home town's stone.
static func stone_defense()->float:return STONE_DEFENSE*home_stone()
static func stone_stores()->float:return STONE_STORES*home_stone()

## military_campaign.gd settlement_defense_daily_work: the hands on the
## walls, in a watchman's share: the watch (at STONE_WATCH on stone stages)
## and the builders on the walls (BUILDER_WALL_WEIGHT, more with craft).
## The builders' share is the walls crew at work on that stage, else the crew
## that would go to it were it begun (wall_builders_ready). `builders`
## false: the watch's hands alone (a watchman's rate, home_defense.gd).
static func wall_hands(watch:float,stage_index:int,builders:bool=true)->float:
	var hands:=watch*(STONE_WATCH if stage_index>=STONE_STAGE else 1.0)
	if builders:hands+=wall_builder_hands(stage_index)
	return hands

## The builders' hands on stage `stage_index`, in a watchman's share.
static func wall_builder_hands(stage_index:int)->float:
	var working:=false
	if WorldSimulation.military!=null:working=int(WorldSimulation.military.settlement_defense.get("project_stage",-1))==stage_index
	var crew:=wall_builders() if working else wall_builders_ready()
	return crew*BUILDER_WALL_WEIGHT*(1.0+CRAFT_WALLS*craft())

## military_campaign.gd: integrity lost today to wear (span days), less as
## builders keep the walls.
static func wall_wear(span:float)->float:
	var kept:=clampf(float(WorldSimulation.state.fabric_realm.get("walls_kept",1.0)),0.0,1.0)
	return WALL_WEAR*span/365.0*(1.0-kept)

## civilization_controller.gd defense_decision: how much the builders want
## the next stage, added to the danger the council weighs.
static func wall_wish()->float:
	return clampf(WALL_WISH*(craft()-WALL_WISH_FROM),0.0,WALL_WISH_MAX)

## Standing's reading of the defences, 0..1 (the defences' bonus over the
## strongest works').
static func fort_reading()->float:
	return clampf(defense_bonus_now()/BASTION_BONUS,0.0,1.0)

## The defences' bonus as settlement_defense_snapshot gives it (the stage's
## bonus x integrity x wall_quality + stone_defense), read straight from the
## ledger without the snapshot's guard reckoning (standing.gd reads it often).
static func defense_bonus_now()->float:
	var mc=WorldSimulation.military
	if mc==null or not "settlement_defense" in mc:return 0.0
	var ledger:Dictionary=mc.settlement_defense
	var stages:Array=mc.SETTLEMENT_DEFENSE_STAGES
	var stage:=clampi(int(ledger.get("stage",0)),0,stages.size()-1)
	return float((stages[stage] as Dictionary).defense_bonus)*clampf(float(ledger.get("integrity",1.0)),0.0,1.0)*wall_quality()+stone_defense()


# ===========================================================================================
# Great works (wonder_concept.gd assess, undertaking_system.gd apply_outcome)
# ===========================================================================================

## The builders on the town's great work: the crew of the works under way
## (undertaking_system.gd share), else the crew a new work would get
## (GREAT_CREW_SHARE), of every builder the town counts.
static func great_crew(s:Object)->float:
	if s==null or not s.has_method("effective_workers"):return 0.0
	var U=preload("res://scripts/undertaking_system.gd")
	var on_works:=clampf(float(U.share(s)),0.0,0.95)
	var free:=maxf(0.0,float(s.effective_workers("Construction")))
	var all:=free/(1.0-on_works)
	var building:=false
	for r:Dictionary in U.current_city(s).get("undertakings",[]):
		if String(r.get("status","")) in ["building","stalled"]:building=true
	return all*(on_works if building else GREAT_CREW_SHARE)

## A people's craft read from its own state (assess may be asked about any owner).
## The live state reads craft() (the whole people's number, even while one
## town's count is in scope, as when a great work is resolved); another
## people's state, read from outside its scope, holds its whole number.
static func craft_of(s:Object)->float:
	if s==null:return 0.0
	if s==WorldSimulation.state:return craft()
	var realm:Variant=s.get("fabric_realm")
	var xp:=float((realm as Dictionary).get("xp",0.0)) if realm is Dictionary else 0.0
	return clampf(xp/maxf(1.0,float(s.get("population_exact")))/CRAFT_PER_LEVEL,0.0,CRAFT_MAX)

## What the builders bring to a great work's odds: {craft, builders, cover,
## from_craft, from_crews, from_materials, total, words}. `cost` is the work's
## bill.
static func great_capability(s:Object,cost:Dictionary)->Dictionary:
	var level:=craft_of(s)
	var builders:=great_crew(s)
	var stocks:Dictionary=s.get("resource_stockpiles") if s!=null and s.get("resource_stockpiles") is Dictionary else {}
	var cover:=1.0
	var stone:=0.0
	for item:String in cost:
		cover=minf(cover,clampf(float(stocks.get(item,0.0))/maxf(1.0,float(cost[item])),0.0,1.0))
	stone=float(stocks.get("Stone",0.0))
	var from_craft:=GREAT_CRAFT*level
	var from_crews:=GREAT_BUILDERS*clampf(builders/GREAT_CREW,0.0,1.0)
	var from_materials:=GREAT_MATERIALS*(cover-0.5)
	var total:=from_craft+from_crews+from_materials
	var words:="Builders' craft %.1f of %d (%+d), %d builders on the work (%+d), %d in 100 of the materials in store (%+d)" % [level,roundi(CRAFT_MAX),roundi(from_craft*140.0),roundi(builders),roundi(from_crews*140.0),roundi(cover*100.0),roundi(from_materials*140.0)]
	return {"craft":level,"builders":builders,"cover":cover,"stone":stone,"from_craft":from_craft,"from_crews":from_crews,"from_materials":from_materials,"total":total,"words":words+"."}

## What a work that stands is worth for the builders who raised it:
## x (1 + GREAT_PAYOFF a level of craft), and x 1.15 more under a gifted
## master builder.
const GIFTED_PAYOFF:=0.15
static func great_payoff(s:Object,gifted:bool)->float:
	return 1.0+GREAT_PAYOFF*craft_of(s)+(GIFTED_PAYOFF if gifted else 0.0)

## The stated odds and payoff in plain words, for the order and the screen.
static func great_words(built:Dictionary,payoff:float,odds:Dictionary,architect:String)->String:
	var stands:=roundi((1.0-float(odds.get("collapse",0.0)))*100.0)
	var text:="With %d builders on the work at craft %.1f and %d stone in store (%d in 100 of the materials), the odds it stands are %d in 100 (a triumph %d, flawed %d, it falls %d)" % [roundi(float(built.builders)),float(built.craft),roundi(float(built.get("stone",0.0))),roundi(float(built.cover)*100.0),stands,roundi(float(odds.get("triumph",0.0))*100.0),roundi(float(odds.get("flawed",0.0))*100.0),roundi(float(odds.get("collapse",0.0))*100.0)]
	text+="; if it stands, its strength, rewards and renown count x%.2f for the builders' craft" % payoff
	if not architect.is_empty():text+=" and %s, a gifted master builder" % architect
	return text+"."

# ===========================================================================================
# The realm's readings (each town's last reckoning, kept with the whole people)
# ===========================================================================================

static func _town_key()->String:
	var id:=String(WorldSimulation.state.resource_settlement_id)
	return "home" if id.is_empty() or _is_home() else id

static func _report_town(f:Dictionary,realm:Dictionary)->void:
	var e:Dictionary=f.effects
	var towns:Dictionary=realm.towns
	towns[_town_key()]={"day":int(WorldSimulation.state.elapsed_days),"pop":float(WorldSimulation.state.population_exact),"places":int(f.places),"builder_days":_all_builders()*_labor(),
		"quality":float(e.quality),"roads":float(e.roads),"beauty_points":float(f.beauty),"beauty":float(e.beauty),"cover":float(e.cover),"stone":float(e.stone)}
	# A town not reckoned for two months is gone (left, lost or taken).
	for key:String in towns.keys():
		if int(WorldSimulation.state.elapsed_days)-int((towns[key] as Dictionary).get("day",0))>60:towns.erase(key)

## The whole people's readings: homes' quality and roads by people, beauty
## from every town's fine works, the home town's stone.
static func realm()->Dictionary:
	var towns:Dictionary=WorldSimulation.state.fabric_realm.get("towns",{})
	var pop:=0.0;var q:=0.0;var roads_sum:=0.0;var points:=0.0;var cover:=0.0;var stone_sum:=0.0
	for town:Dictionary in towns.values():
		var p:=maxf(0.0,float(town.pop))
		pop+=p;q+=float(town.quality)*p;roads_sum+=float(town.roads)*p;points+=float(town.beauty_points);cover+=float(town.cover)*p;stone_sum+=float(town.stone)*p
	if pop<=0.0:return {"quality":quality(),"roads":roads(),"beauty":beauty(),"cover":float(_effects().get("cover",0.0)),"stone":stone(),"towns":0}
	return {"quality":q/pop,"roads":roads_sum/pop,"beauty":1.0-exp(-points/pop/BEAUTY_SCALE),"cover":cover/pop,"stone":stone_sum/pop,"towns":towns.size()}

static func realm_roads()->float:return float(realm().roads)

## The road index of a people's state (people-weighted over its towns).
static func roads_of(state:Object)->float:
	var towns:Variant=(state.get("fabric_realm") as Dictionary).get("towns",{}) if state!=null and state.get("fabric_realm") is Dictionary else {}
	var pop:=0.0;var sum:=0.0
	for town:Variant in (towns as Dictionary).values():
		if not town is Dictionary:continue
		pop+=maxf(0.0,float(town.get("pop",0.0)));sum+=float(town.get("roads",0.0))*maxf(0.0,float(town.get("pop",0.0)))
	return sum/pop if pop>0.0 else 0.0

## The kind of road the map draws (0 footpath, 1 cart track, 2 made road)
## for the roads a people has laid (ROAD_DRAW).
static func drawn_road_tier(state:Object)->int:
	var r:=roads_of(state)
	var tier:=0
	for k in ROAD_DRAW.size():
		if r>=float(ROAD_DRAW[k]):tier=k
	return tier
## standing.gd: Splendor, culture and respect read the realm's beauty.
static func realm_beauty()->float:return float(realm().beauty)


# ===========================================================================================
# What the screens show (People view, Buildings page, town page): every number
# the engine's own, from the readings above.
# ===========================================================================================

## The best grade the people can build now (by knowledge and craft), and the
## plainest grade with room to rise: {best, next, caps} (next -1 when none).
static func grade_reach(f:Dictionary={})->Dictionary:
	if f.is_empty():f=peek()
	var caps:=grade_caps()
	var homes:Array=f.homes
	var best:=0
	for g in range(1,GRADES.size()):
		if float(caps[g])>0.0:best=g
	var next:=-1
	for g in range(1,GRADES.size()):
		var above:=0.0
		for k in range(g,GRADES.size()):above+=float(homes[k])
		if float(caps[g])-above>0.005 and float(homes[g-1])>0.005:
			next=g
			break
	return {"best":best,"next":next,"caps":caps}

## Everything the town's fabric is now, for the screens.
static func report()->Dictionary:
	var f:=peek()
	var e:Dictionary=f.get("effects",{})
	var pop:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var reach:=grade_reach(f)
	var all_kept:={"homes":1.0,"works":1.0,"roads":1.0,"beauty":1.0}
	var kept:Dictionary=f.get("kept") if f.get("kept") is Dictionary else all_kept
	var spent:Dictionary=f.get("spent") if f.get("spent") is Dictionary else {}
	var defense:Dictionary={}
	if WorldSimulation.military!=null and _is_home():defense=WorldSimulation.military.settlement_defense_snapshot()
	var crew:=crews()
	return {"homes":(f.homes as Array).duplicate(),"places":int(f.get("places",0)),"quality":float(e.get("quality",0.0)),"best":int(reach.best),"next":int(reach.next),"caps":reach.caps,
		"roads":float(e.get("roads",0.0)),"road_cap":road_cap(),"road_kind":road_kind(),"beauty":float(e.get("beauty",0.0)),"beauty_points":float(f.beauty)/pop,"artistry":artistry(),
		"cover":float(e.get("cover",0.0)),"stone":float(e.get("stone",0.0)),"craft":craft(),"craft_settles":craft_settles(),"kept":kept,"paid":float(f.get("paid",1.0)),
		"spent":spent,"idle":float(f.get("idle",0.0)),"budget":float(f.get("budget",0.0)),"days":TICK_DAYS,"free_builders":float(crew.fabric),"crews":crew,"defense":defense,"home":_is_home()}

## What wears now for want of hands, in plain words ([] when all is kept).
static func decline_words(r:Dictionary={})->PackedStringArray:
	if r.is_empty():r=report()
	var out:PackedStringArray=[]
	var kept:Dictionary=r.kept
	if float(kept.get("homes",1.0))<0.99:out.append("homes fall a grade (%d in 100 of their upkeep is done)" % roundi(float(kept.homes)*100.0))
	if float(kept.get("works",1.0))<0.99:out.append("workshops and stores decay")
	if float(kept.get("roads",1.0))<0.99:out.append("roads roughen")
	if float(kept.get("beauty",1.0))<0.99:out.append("fine works weather")
	return out

## Builder-days a year that `more` builders add to the fabric now, at today's
## pace: the part of them the homes, civic works, repair and walls leave it
## (crews).
static func _more_days(more:float)->float:
	var added:=maxf(0.0,float(crews(more).fabric)-float(crews().fabric))
	return added*_labor()*365.0*(1.0+CRAFT_WORK*craft())*(1.0+KILN_BUILDING*works_cover("kilns"))

## What `more` builders would buy now, in the engine's numbers: {days,
## upkeep, places, grade, roads, cover, beauty, craft_settles, craft_then,
## short}.
static func plus_builders(more:float=10.0)->Dictionary:
	var r:=report()
	var pop:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var days:=_more_days(more)
	var out:={"days":days,"short":float(r.idle)>1.0,"craft_now":float(r.craft)}
	# Upkeep left undone takes them first.
	var budget_year:=float(r.budget)*365.0/float(TICK_DAYS)
	var gap:=budget_year*(1.0/maxf(0.05,float(r.paid))-1.0) if float(r.paid)<0.99 else 0.0
	var to_upkeep:=minf(days,gap)
	out["upkeep"]=to_upkeep
	days-=to_upkeep
	var shares:Dictionary=SPLIT.duplicate()
	if int(r.next)<0:shares.erase("homes")
	if float(r.roads)>=float(r.road_cap)-0.001:shares.erase("roads")
	if float(r.cover)>=0.999:shares.erase("works")
	var total:=0.0
	for key in shares:total+=float(shares[key])
	var each:={}
	for key in ["homes","roads","works","beauty"]:each[key]=days*float(shares.get(key,0.0))/total if total>0.0 else 0.0
	out["places"]=float(each.homes)/maxf(1.0,float(GRADE_BUILD[int(r.next)])) if int(r.next)>0 else 0.0
	out["grade"]=int(r.next)
	out["roads"]=float(each.roads)/(ROAD_FULL*pop)
	out["cover"]=float(each.works)/(WORKS_FULL*pop)
	var points:=float(r.beauty_points)*pop+float(each.beauty)*artistry()
	out["beauty"]=(1.0-exp(-points/pop/BEAUTY_SCALE))-float(r.beauty)
	var people:=pop
	if WorldSimulation.settlements!=null:people=maxf(1.0,float(WorldSimulation.settlements.national_population()))
	var settles_now:=float(r.craft_settles)
	out["craft_settles"]=settles_now
	out["craft_then"]=clampf(settles_now+more*_labor()*365.0*CRAFT_YEARS/people/CRAFT_PER_LEVEL,0.0,CRAFT_MAX)
	return out

## The People view's building line: {now, plus_ten}, twelve words or fewer each.
static func role_line(more:float=10.0)->Dictionary:
	var r:=report()
	var declining:=decline_words(r)
	var now:="Homes %d/100, roads %d, beauty %d; craft %s." % [roundi(float(r.quality)*100.0),roundi(float(r.roads)*100.0),roundi(float(r.beauty)*100.0),_one(float(r.craft))]
	if not declining.is_empty():now="Too few to keep it all: %s." % String(declining[0]).get_slice(" (",0)
	var plus:=plus_builders(more)
	var parts:PackedStringArray=[]
	if float(plus.upkeep)>1.0:parts.append("keep what wears")
	if float(plus.places)>=1.0:parts.append("%d places a year to %s" % [roundi(float(plus.places)),GRADE_SHORT[int(plus.grade)]])
	elif float(plus.beauty)>0.0005:parts.append("beauty +%s" % _one(float(plus.beauty)*100.0))
	parts.append("craft toward %s" % _one(float(plus.craft_then)))
	var ten:="Ten more: "+", ".join(parts)+"."
	if bool(plus.short):ten="Ten more: little, materials are short; more cutters and diggers."
	return {"now":now,"plus_ten":ten}

static func _one(x:float)->String:
	return str(roundi(x)) if absf(x)>=10.0 else "%.1f" % x

## One line for the screens: {label, value, words, tone, src}. The words are
## plain; `src` names the rule (file and constant) for designers and tests,
## never shown to the player.
static func _add_line(lines:Array,label:String,value:String,words:String,tone:String="good",src:String="")->void:
	lines.append({"label":label,"value":value,"words":words,"tone":tone,"src":src})

## What the fabric does now, line by line, with the engine's numbers:
## [{label, value, words, tone, src}].
static func effect_lines(r:Dictionary={})->Array:
	if r.is_empty():r=report()
	var q:=float(r.quality)
	var roads_now:=float(r.roads)
	var beauty_now:=float(r.beauty)
	var lines:Array=[]
	var weather:=float(WorldSimulation.state.simulation_metrics.get("fabric_weather",0.0))
	_add_line(lines,"Health","+%s points" % _one((health_bonus()+weather)*100.0),"Homes %d of 100 good: the health the people tend toward rises %s points under good roofs, %s of them against this season's cold and heat." % [roundi(q*100.0),_one((health_bonus()+weather)*100.0),_one(weather*100.0)],"good","consequence_engine.gd HOME_HEALTH, HOME_WEATHER")
	_add_line(lines,"Illness deaths","x%.2f" % illness_factor(),"Dry floors and walls: illness deaths x%.2f (x%.2f if every place were stone)." % [illness_factor(),1.0-HOME_ILLNESS],"good","consequence_engine.gd HOME_ILLNESS")
	_add_line(lines,"Sickness breaking out","x%.2f" % exp(-HOME_SICKNESS*q),"Outbreaks of sickness come x%.2f as often as among windbreaks." % exp(-HOME_SICKNESS*q),"good","crisis_system.gd HOME_SICKNESS")
	_add_line(lines,"Fire","x%.2f" % exp(-HOME_FIRE*q),"Mudbrick and stone do not catch as thatch does: fires x%.2f." % exp(-HOME_FIRE*q),"good","crisis_system.gd HOME_FIRE")
	_add_line(lines,"Holding together","+%s points" % _one(civic("cohesion")*100.0),"Good homes (+%s) and fine works (+%s) raise how well the people hold together." % [_one(HOME_COHESION*q*100.0),_one(BEAUTY_COHESION*beauty_now*100.0)],"good","consequence_engine.gd HOME_COHESION, BEAUTY_COHESION")
	_add_line(lines,"Love of the god","+%s points" % _one(devotion()*100.0),"Works raised to the god in every town draw the people's love.","good","divine_regard.gd BEAUTY_DEVOTION")
	_add_line(lines,"Hauling","+%s points" % _one(logistics_bonus()*100.0),"Roads %d of 100, and storehouses: the carriers haul more." % roundi(roads_now*100.0),"good","consequence_engine.gd ROAD_LOGISTICS, STOREHOUSE_LOGISTICS")
	_add_line(lines,"Hauls from deposits","x%.2f" % haul_factor(),"Each carrier brings x%.2f from the cutting grounds." % haul_factor(),"good","resource_system.gd ROAD_HAUL")
	_add_line(lines,"Between towns","x%.2f speed" % speed_factor(),"Goods, caravans and founding parties go x%.2f as fast; trade reaches x%.2f as far; x%.2f of the townsfolk reach a fight in time." % [speed_factor(),reach_factor(),rise_factor()],"good","settlement_model.gd, trade_ledger.gd, caravan_system.gd, civilization_combat.gd ROAD_SPEED, ROAD_REACH, ROAD_RISE")
	_add_line(lines,"Makers' goods","x%.2f" % making_factor(),"Workshops cover %d of 100 of the town: each maker makes x%.2f." % [roundi(works_cover("workshops")*100.0),making_factor()],"good" if works_cover("workshops")>0.0 else "plain","civilian_goods.gd WORKSHOP_MAKING")
	_add_line(lines,"Stored food rots","x%.2f" % granary_factor(),"Granaries: stored food rots x%.2f." % granary_factor(),"good" if works_cover("granaries")>0.0 else "plain","food_system.gd GRANARY_ROT")
	_add_line(lines,"Cutting and digging","+%d%%" % roundi(extraction_bonus()*100.0),"Storehouses and yards: every deposit worked gives %d%% more." % roundi(extraction_bonus()*100.0),"good" if extraction_bonus()>0.0 else "plain","resource_system.gd STOREHOUSE_EXTRACTION")
	_add_line(lines,"Water carried","x%.2f" % water_factor(),"Wells and water works: each water carrier brings x%.2f.%s" % [water_factor(),"" if works_cover("water")>0.0 else " The people must first learn to site wells."],"good" if works_cover("water")>0.0 else "plain","resource_system.gd WATERWORKS_WATER")
	_add_line(lines,"Kilns","x%.2f builders" % (1.0+KILN_BUILDING*works_cover("kilns")),"Fired brick and lime: the builders' own work x%.2f.%s" % [1.0+KILN_BUILDING*works_cover("kilns"),"" if works_cover("kilns")>0.0 else " The people must first learn to fire a kiln."],"good" if works_cover("kilns")>0.0 else "plain","built_fabric.gd KILN_BUILDING")
	_add_line(lines,"Splendor","+%d" % roundi(BEAUTY_SPLENDOR*realm_beauty()*100.0),"Fine works in every town add to Splendor, and through it to pride and awe.","good","standing.gd BEAUTY_SPLENDOR")
	_add_line(lines,"Allure abroad","+%d" % roundi(BEAUTY_CULTURE*realm_beauty()*100.0),"What others hear of our fine works draws families, traders and envoys; their respect +%d." % roundi(BEAUTY_RESPECT*realm_beauty()*100.0),"good","standing.gd BEAUTY_CULTURE, BEAUTY_RESPECT")
	if bool(r.home):
		var d:Dictionary=r.defense
		_add_line(lines,"Defences","+%d%%" % roundi(float(d.get("defense_bonus",0.0))*100.0),"Walls %d%% (x%.2f for the builders' craft) and the town's stone houses +%d%%: defenders fight better and a siege needs more men." % [roundi(float(d.get("works_bonus",0.0))*100.0),wall_quality(),roundi(stone_defense()*100.0)],"good","military_campaign.gd settlement_defense_snapshot CRAFT_WALL_QUALITY, STONE_DEFENSE")
		_add_line(lines,"Might","+%d" % roundi(FORT_MIGHT*fort_reading()*100.0),"Walls and stone count toward Might, and others weigh our fighting strength x%.2f." % (1.0+FORT_STRENGTH*float(d.get("defense_bonus",0.0))),"good","standing.gd FORT_MIGHT, FORT_STRENGTH")
	_add_line(lines,"Building knowledge","x%.2f" % research_multiplier("infrastructure"),"Skilled builders learn new ways of building faster (x%.2f), and learn some by doing." % research_multiplier("infrastructure"),"good","discovery_system.gd CRAFT_RESEARCH; civilization_day.gd CRAFT_SIGNAL")
	_add_line(lines,"Great works","+%d odds" % roundi(GREAT_CRAFT*craft()*140.0),"The builders' craft adds %d points to a great work's odds, and a work that stands is worth x%.2f." % [roundi(GREAT_CRAFT*craft()*140.0),1.0+GREAT_PAYOFF*craft()],"good","wonder_concept.gd, undertaking_system.gd GREAT_CRAFT, GREAT_PAYOFF")
	return lines

## What `more` builders would buy now, as lines for the Buildings page.
static func plus_lines(more:float=10.0)->Array:
	var p:=plus_builders(more)
	var lines:Array=[]
	_add_line(lines,"Their work","%d days a year" % roundi(float(p.days)),"%d more builders give the town's fabric about %d builder-days a year at today's pace and craft, after their share of new homes, civic works, repair and walls." % [roundi(more),roundi(float(p.days))],"plain","built_fabric.gd plus_builders, crews")
	if float(p.upkeep)>1.0:_add_line(lines,"Upkeep","%d days" % roundi(float(p.upkeep)),"First they keep what now wears for want of hands.","good","built_fabric.gd UPKEEP_ORDER")
	if int(p.grade)>0:_add_line(lines,"Better homes","%d places a year" % roundi(float(p.places)),"Places raised to %s each year." % GRADE_WORDS[int(p.grade)],"good","built_fabric.gd GRADE_BUILD")
	if float(p.roads)>0.0:_add_line(lines,"Roads","+%s a decade" % _one(float(p.roads)*1000.0),"Points of road (of 100) each ten years, before wear.","good","built_fabric.gd ROAD_FULL")
	if float(p.cover)>0.0:_add_line(lines,"Work buildings","+%s a decade" % _one(float(p.cover)*1000.0),"Points of cover (of 100) each ten years.","good","built_fabric.gd WORKS_FULL")
	if float(p.beauty)>0.0:_add_line(lines,"Beauty","+%s in a year" % _one(float(p.beauty)*100.0),"Fine works: points of beauty (of 100) in the first year.","good","built_fabric.gd BEAUTY_SCALE")
	_add_line(lines,"Craft","%s to %s" % [_one(float(p.craft_settles)),_one(float(p.craft_then))],"Where the builders' craft settles over a working life, now and with them.","good","built_fabric.gd CRAFT_YEARS, CRAFT_PER_LEVEL")
	if bool(p.short):_add_line(lines,"Materials","short","Some builders stand idle for want of timber, clay and stone: more cutters and diggers, or carriers bringing them from our other towns.","bad","built_fabric.gd _spare")
	return lines


## The headman's line of fact on building (court_facts.gd): the homes by
## grade, the roads, beauty and work buildings, the builders' craft and
## whether it is all kept.
static func court_line()->String:
	if not bool(WorldSimulation.state.settlement_site_committed):return ""
	var r:=report()
	var homes:Array=r.homes
	var parts:PackedStringArray=[]
	for g in range(GRADES.size()-1,-1,-1):
		if float(homes[g])>=0.005:parts.append("%d in 100 %s" % [roundi(float(homes[g])*100.0),String(GRADE_WORDS[g])])
	var kept:=decline_words(r)
	return "Building: homes %d of 100 good (%s); roads %d of 100 (%s known); fine works %d of 100; work buildings %d of 100; builders' craft %s of %d, settling at %s; %s." % [
		roundi(float(r.quality)*100.0),", ".join(parts),roundi(float(r.roads)*100.0),String(ROAD_WORDS[int(r.road_kind)]),roundi(float(r.beauty)*100.0),roundi(float(r.cover)*100.0),
		_one(float(r.craft)),roundi(CRAFT_MAX),_one(float(r.craft_settles)),"all of it is kept" if kept.is_empty() else "too few builders: "+", ".join(kept)]
