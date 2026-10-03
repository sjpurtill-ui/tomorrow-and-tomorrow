extends RefCounted
## THE WAR COUNCIL: one planner for every people, the god's own included.
##
## The ruler decides three things on the War screen (hud/war_board.gd): how
## many serve (army_levy_law.gd), who leads, and a STANCE toward each people.
## The war leader and the generals do the rest with the real army
## (MilitaryCampaign: field armies, their land roads, the combat simulator,
## sieges and garrisons): one war engine, the same for every people.
##   leave    Leave them be. Our bands come home; their raids are met at home.
##   defend   Hold home and the towns we hold of theirs. Bands come home, a
##            short garrison gets men from home, and when the watch sees their
##            band coming a band of ours goes out to meet it.
##   punish   A real band, sized by the odds, raids their nearest known town
##            and comes home, then rests before the next. Trackers go first
##            when nobody knows where they live.
##   take     A town of theirs (the ruler's pick, else the council's by the
##            odds). The war leader gathers until the odds are 3 to 2
##            (war_odds.TAKE_ODDS), feeds the march or waits, marches by the
##            land road, lays siege or storms, and leaves a garrison.
##   peace    Bands come home, no raid goes out, messengers ask for an end.
## The god can insist past an objection ("go anyway"). A computer ruler's
## stance comes from its own plan (civilization_strategy: offensive,
## peace_food) and its feuds: only the tendencies differ, never the acts.
##
## Cadence: monthly in peace (staggered by people), every LIVE_DAYS while a
## band of ours is out or their band is in sight, WAIT_DAYS while the war
## leader waits for the odds. Nothing loops per soldier; a sitting weighs a
## handful of peoples, bands and towns.
## State: the people's own ForeignDiplomacy.audiences["council"] (saved with
## it, every people its own); a band's errand on the band itself ("council").
## Static helpers; preload.

const Odds:=preload("res://scripts/war_odds.gd")
const Scale:=preload("res://scripts/conflict_scale.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"
const ORDERS_PATH:="res://scripts/court_war_orders.gd"
const SUPPLY_PATH:="res://scripts/supply_state.gd"
const LEDGER_PATH:="res://scripts/town_ledger.gd"
const CONTROLLER_PATH:="res://scripts/civilization_controller.gd"
const TRACKER_PATH:="res://scripts/order_tracker.gd"
const COMMANDS_PATH:="res://scripts/leader_commands.gd"
const LAW:=preload("res://scripts/army_levy_law.gd")
const Lines:=preload("res://scripts/army_lines.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Logistics:=preload("res://scripts/equipment_logistics.gd")
const DEPOTS:=preload("res://scripts/field_depots.gd")

const VERSION:=1
const STANCES:=["leave","defend","punish","take","peace"]
## How often the council sits (days): at peace, while waiting for the odds,
## while a band is out or their band is in sight.
const PEACE_DAYS:=30
const WAIT_DAYS:=10
const LIVE_DAYS:=3
## The watch the war leader keeps at home when he sends a band out.
const WATCH_SHARE:=0.2
## Fewer than this is no band at all.
const MIN_BAND:=3
## A raiding party is at least this many when the men are there.
const RAID_FLOOR:=10
## Between raids while punishing (days).
const RAID_REST_DAYS:=90
## A raid their feud called waits at most this long for the band to be sent.
const RAID_CALL_DAYS:=30
## Messengers for peace go again after this many days while refused.
const PARLEY_GAP:=120
## A march the carriers would feed worse than this waits (supply_state.gd).
## A march that would leave the band going hungry (below the supply model's
## own starving line, supply_state.gd STARVING_BELOW) does not set out.
## Their band seen this close to a town of ours is met by ours (km).
const INTERCEPT_KM:=45.0
## At most this many of their towns are weighed when the council picks one.
const PICKS:=3
## Odds at which a band storms at once instead of laying siege.
const STORM_ODDS:=2.0
## A siege needs at least this many to ring a town (court_war_orders MIN_FORCE x3).
const SIEGE_MIN:=15
## Men to hold a town after the fight, over what holding it takes
## (civilization_system.occupation_requirement): the fight's losses, and the
## band's readiness and food on arrival, take their share.
const HOLD_MARGIN:=1.5
## After a band could not take or hold a town, the next try waits this long.
const TAKE_REST_DAYS:=30
## A band this near the ground the ruler sent it to (army_orders "Go to…")
## is still waiting there.
const POST_KM:=2.0
## A band the ruler formed at home and has not yet sent anywhere waits this
## long for his word before it goes back into the army at home.
const FORMED_GRACE_DAYS:=30
const WORDS_MAX:=260
const FRONTS_MAX:=64

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	var fd:Variant=WorldSimulation.diplomacy
	if fd==null: return _fresh(0)
	fd.ensure()
	var holder:Dictionary=fd.audiences
	var s:Variant=holder.get("council")
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION:
		s=_fresh(int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0)
		holder["council"]=s
	var d:Dictionary=s
	if not d.get("fronts") is Dictionary: d["fronts"]={}
	if (d.fronts as Dictionary).size()>FRONTS_MAX: (d.fronts as Dictionary).clear()
	return d

## A new council: its monthly sitting staggered by people, so twelve rulers
## do not all sit on one day.
static func _fresh(today:int)->Dictionary:
	var phase:=posmod(hash("council:"+String(WorldSimulation.actor_id)),PEACE_DAYS)
	return {"version":VERSION,"last":today-PEACE_DAYS+phase,"live":false,"waiting":false,"fronts":{}}

## A saved council (audience_hall validate_state): its fronts are records
## of short words and day numbers, at most FRONTS_MAX of them.
static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.is_empty(): return true
	if not d.get("fronts",{}) is Dictionary or (d.get("fronts",{}) as Dictionary).size()>FRONTS_MAX: return false
	for front in (d.get("fronts",{}) as Dictionary).values():
		if not front is Dictionary: return false
	return JSON.stringify(d).length()<=FRONTS_MAX*2500

static func _front(civ_id:String)->Dictionary:
	var fronts:Dictionary=state().fronts
	if not fronts.get(civ_id) is Dictionary: fronts[civ_id]={}
	return fronts[civ_id]

## The council's front for a people, read only (never made by asking).
static func peek(civ_id:String)->Dictionary:
	var fd:Variant=WorldSimulation.diplomacy
	if fd==null: return {}
	var s:Variant=(fd.audiences as Dictionary).get("council")
	if not s is Dictionary: return {}
	var fronts:Variant=(s as Dictionary).get("fronts")
	var f:Variant=(fronts as Dictionary).get(civ_id) if fronts is Dictionary else null
	return f if f is Dictionary else {}

# --------------------------------------------------------------------------
# Scope
# --------------------------------------------------------------------------

static func _player()->bool:
	return WorldSimulation.actor_id=="player"

static func _mc()->Node:
	return WorldSimulation.military

static func _today()->int:
	return int(WorldSimulation.state.elapsed_days)

static func _war_loop()->GDScript:
	return load(WAR_LOOP_PATH) as GDScript

static func _orders()->GDScript:
	return load(ORDERS_PATH) as GDScript

static func _civ(civ_id:String)->Dictionary:
	var world:Variant=WorldSimulation.world
	if world==null: return {}
	var index:int=world._civilization_index(civ_id)
	return world.civilizations[index] if index>=0 else {}

## The god's people as other peoples see it (world_simulation human_projection)
## carries a relation without the opinion and border tension the battle's
## reckoning reads (civilization_system resolve_player_battle): give it the
## same neutral values a missing field means everywhere else before a band
## of theirs can fight ours.
static func _battle_fields(civ_id:String)->void:
	var civ:=_civ(civ_id)
	if civ.is_empty() or not civ.get("player_relation") is Dictionary: return
	var relation:Dictionary=civ.player_relation
	for field in ["opinion","border_tension"]:
		if not relation.has(field): relation[field]=0.0

static func _name(civ_id:String)->String:
	var name:=String(_civ(civ_id).get("name",""))
	return name if name!="" else "them"

## The war leader's given name in this people's own court ("" for a
## computer ruler's staff, which speaks of itself as "the war leader").
static func _leader_name(band:Dictionary={})->String:
	var c:Dictionary=band.get("commander",{}) if band.get("commander") is Dictionary else {}
	var name:=String(c.get("name","")).strip_edges()
	if name!="" and name!=name.to_upper() and not "staff" in name.to_lower(): return EraNames.given_of(name)
	if _player():
		var leader:Dictionary=_orders().call("war_leader")
		if not leader.is_empty(): return EraNames.given_of(String(leader.get("name","")))
	return ""

static func _who(band:Dictionary={})->String:
	var name:=_leader_name(band)
	return name if name!="" else "The war leader"

# --------------------------------------------------------------------------
# Sitting
# --------------------------------------------------------------------------

## The day's look (civilization_day.gd, every people, every day): the council
## sits when it is due, else nothing is done.
static func day(today:int)->void:
	if WorldSimulation.state==null or not WorldSimulation.state.settlement_site_committed: return
	if WorldSimulation.military==null or WorldSimulation.world==null: return
	if WorldSimulation.military.recovery.home_unavailable(): return
	# The god lowered the watch: bands with nothing to do come home to be sent
	# back to work (on the levy law's own days, army_levy_law.gd KEEP_EVERY).
	if _player() and today%int(LAW.KEEP_EVERY)==0: fold_idle_bands()
	var s:=state()
	var every:=LIVE_DAYS if bool(s.get("live",false)) else (WAIT_DAYS if bool(s.get("waiting",false)) else PEACE_DAYS)
	if today-int(s.get("last",-99999))<every: return
	sit(today)

## One sitting: every people we fight or hold a stance toward, and every band
## of ours out on the council's errand.
static func sit(today:int)->void:
	var s:=state()
	s["last"]=today
	_old_orders_once(s)
	var live:=false
	var waiting:=false
	var seen:={}
	var plan:={}
	var stances:={}
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary: continue
		var id:=String((civ as Dictionary).get("id",""))
		if id=="" or id=="player": continue
		seen[id]=true
		var bands:=bands_against(id)
		if not bool((civ as Dictionary).get("alive",true)):
			for band in bands: _send_home(band)
			continue
		var stance:=_stance_now(id,civ,today,plan)
		if stance=="" and bands.is_empty(): continue
		stances[id]=stance
	# Bands left in the field (old orders, a court order carried out): the
	# stance's work takes them up where it fits, the rest come home. Before
	# the acts, so those already home are free to go with the next band.
	_gather_strays(stances,today)
	for id in stances:
		var done:=_act(String(id),String(stances[id]),today,{})
		live=live or bool(done.get("live",false))
		waiting=waiting or String(done.get("verdict","")) in ["wait","object"]
	# Bands sent against a people no longer in our world come home.
	for band in _council_bands():
		if not seen.has(String((band.council as Dictionary).get("civ",""))): _send_home(band)
	# A band with nobody left standing never stays on the field (after the
	# acts: the council has read how its errand ended).
	_strike_off_empty()
	for band in _council_bands(): _free_of_chain(int(band.get("army_id",0)))
	_tidy_home()
	s["live"]=live or _any_out()
	s["waiting"]=waiting

## The ruler's word (the War screen, the court): the stance toward a people,
## acted on at once. options: place (a town for take or punish), insist (go
## past the war leader's objection), words (the order as said, for its card).
## {verdict:"act"|"wait"|"rest"|"hold"|"impossible"|"noted", says, outcome,
##  army_id, stance}. The god's own people only.
static func order(civ_id:String,stance:String,options:Dictionary={})->Dictionary:
	if not stance in STANCES: return {"verdict":"impossible","says":"There is no such stance.","stance":stance}
	if not _player(): return {"verdict":"impossible","says":"Only the god's own people take the god's word.","stance":stance}
	var wl:=_war_loop()
	var f:Dictionary=wl.call("front",civ_id)
	var before:=String(f.get("stance",""))
	f["stance"]=stance
	var place:Dictionary=options.get("place",{}) if options.get("place") is Dictionary else {}
	if stance=="take":
		if not place.is_empty(): f["take"]={"city_id":String(place.get("city_id","")),"name":String(place.get("name",""))}
	else: f.erase("take")
	if stance=="punish" and not place.is_empty(): f["punish_at"]={"city_id":String(place.get("city_id","")),"name":String(place.get("name",""))}
	elif stance!="punish": f.erase("punish_at")
	var council:=_front(civ_id)
	council["changed"]=_today()
	var s:=state(); s["live"]=true
	var opts:=options.duplicate()
	opts["now"]=true
	opts["new"]=before!=stance
	var done:=_act(civ_id,stance,_today(),opts)
	done["stance"]=stance
	if String(done.get("outcome",""))=="": done["outcome"]=String(done.get("says",""))
	if bool(options.get("card",false)): _card(civ_id,stance,done,String(options.get("words","")))
	return done

## The order's card at the bottom right (order_tracker.gd): a band sent is
## followed on its road; a stance held is done; a wait is the war leader's
## objection, waiting on the god's word; a refusal says why.
static func _card(civ_id:String,stance:String,done:Dictionary,words:String)->void:
	var tracker:=load(TRACKER_PATH) as GDScript
	if tracker==null: return
	var said:=words if words!="" else "%s: %s" % [_name(civ_id),String({"leave":"leave them be","defend":"defend","punish":"punish","take":"take a town","peace":"seek peace"}.get(stance,stance))]
	var id:int=tracker.call("register",said,"war")
	# One stance toward a people stands: the later word replaces the earlier card.
	tracker.call("supersede",id,"stance:%s" % civ_id)
	var verdict:=String(done.get("verdict",""))
	var decision:=done.duplicate()
	decision["general"]=_who()
	match verdict:
		"act":
			if int((done.get("objective",{}) as Dictionary).get("army_id",done.get("army_id",0)))>0:
				if not done.has("objective"): decision["objective"]={"army_id":int(done.get("army_id",0)),"kind":stance}
				tracker.call("from_war",id,decision)
			else: tracker.call("done",id,String(done.get("says","")),_who())
		"object","wait":
			decision["verdict"]="object"
			tracker.call("from_war",id,decision)
		"impossible":
			tracker.call("from_war",id,decision)
		_:
			tracker.call("done",id,String(done.get("says","")),_who())

# --------------------------------------------------------------------------
# The stance toward a people
# --------------------------------------------------------------------------

## The stance the council acts on now: the god's (or, with no word given while
## we fight them, "defend"); a computer ruler's from its own plan.
static func stance_of(civ_id:String)->String:
	if _player():
		var f:Dictionary=_war_loop().call("_peek",civ_id)
		var chosen:=String(f.get("stance",""))
		if chosen in STANCES: return chosen
		return "defend" if fighting(civ_id) else ""
	return String(peek(civ_id).get("stance",""))

## Is this people fighting ours: at war, or in a feud not yet cold?
static func fighting(civ_id:String)->bool:
	var rel:Dictionary=_civ(civ_id).get("player_relation",{}) if _civ(civ_id).get("player_relation") is Dictionary else {}
	if bool(rel.get("at_war",false)): return true
	if _player():
		var wl:=_war_loop()
		return bool(wl.call("feuding",civ_id)) or bool(wl.call("hot",civ_id))
	return _feud_hot(civ_id,_civ(civ_id))

## The god's stance word for the screens: "" when none was given.
static func chosen(civ_id:String)->String:
	if not _player(): return ""
	var chosen_word:=String((_war_loop().call("_peek",civ_id) as Dictionary).get("stance",""))
	return chosen_word if chosen_word in STANCES else ""

static func _stance_now(civ_id:String,civ:Dictionary,today:int,plan:Dictionary)->String:
	if _player(): return stance_of(civ_id)
	var f:=_front(civ_id)
	# A called raid the war leader could not send in a month (too few, the
	# odds, the road's food, or a war came first) is let go.
	if _raid_called(civ_id) and today-int(f.get("raid_call",today))>RAID_CALL_DAYS: _raid_sent(f)
	# Raiders already out finish their raid before the stance moves on.
	var raiding:=_raid_called(civ_id) or not _band_on(civ_id,["punish"]).is_empty()
	var rel:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	var hostile:=bool(rel.get("at_war",false)) or raiding or _feud_hot(civ_id,civ)
	if not hostile:
		f["stance"]=""
		return ""
	if plan.is_empty(): plan.merge(_plan_bits(today),true)
	var stance:=rival_stance(rel,plan,raiding,_feud_hot(civ_id,civ),float(WorldSimulation.state.simulation_metrics.get("food_days",0.0)))
	f["stance"]=stance
	return stance

## A computer ruler's stance from its own plan, the same five words the god
## chooses from: at war, hungry rulers seek peace and bold ones take a town;
## a raid its feud has called punishes; a hot feud is defended.
static func rival_stance(relation:Dictionary,plan:Dictionary,raid_called:bool,feud_hot:bool,food_days:float)->String:
	if bool(relation.get("at_war",false)):
		if food_days<float(plan.get("peace_food",20.0)): return "peace"
		return "take" if bool(plan.get("offensive",false)) else "defend"
	if raid_called: return "punish"
	if feud_hot: return "defend"
	return ""

## The parts of a ruler's plan the council reads, worked out at most monthly.
static func _plan_bits(today:int)->Dictionary:
	var s:=state()
	var cached:Dictionary=s.get("plan",{}) if s.get("plan") is Dictionary else {}
	if not cached.is_empty() and today-int(cached.get("day",-99999))<PEACE_DAYS: return cached
	var plan:Dictionary=(load(CONTROLLER_PATH) as GDScript).call("current_plan",String(WorldSimulation.actor_id))
	var bits:={"day":today,"offensive":bool(plan.get("offensive",false)),"peace_food":float(plan.get("peace_food",20.0))}
	s["plan"]=bits
	return bits

## A raid their feud has called on this people (war_loop for the god's
## people, rival_feuds between two others), not yet sent.
static func _raid_called(civ_id:String)->bool:
	return int(peek(civ_id).get("raid_call",-1))>=0

## The called raid is sent (or let go): the call is answered.
static func _raid_sent(f:Dictionary)->void:
	for key in ["raid_call","raid_cause","raid_ref"]: f.erase(key)

## A feud with this people hot in this people's own world.
static func _feud_hot(civ_id:String,civ:Dictionary)->bool:
	if civ_id=="human" or civ_id=="player":
		var me:=String(WorldSimulation.actor_id)
		return bool(WorldSimulation.scoped("player",func()->bool:return bool(_war_loop().call("hot",me))))
	var relations:Dictionary=civ.get("relations",{}) if civ.get("relations") is Dictionary else {}
	var pair:Dictionary=relations.get(String(WorldSimulation.actor_id),{}) if relations.get(String(WorldSimulation.actor_id)) is Dictionary else {}
	if int(pair.get("feud_since",-1))<0: return false
	return _today()-int(pair.get("feud_last",-99999))<int(CivilizationSystem.RIVAL_FEUD_HOT_DAYS)

## Their raid on us, called by their feud (war_loop for the god's people):
## the council sends a real band at its next sitting, or says why it cannot.
static func call_raid(civ_id:String,cause:String,ref:String)->void:
	var f:=_front(civ_id)
	f["raid_call"]=_today()
	f["raid_cause"]=cause.substr(0,60)
	f["raid_ref"]=ref.substr(0,80)
	state()["live"]=true

# --------------------------------------------------------------------------
# Acting on a stance
# --------------------------------------------------------------------------

static func _act(civ_id:String,stance:String,today:int,options:Dictionary)->Dictionary:
	_see_them_coming(civ_id,today)
	var done:Dictionary
	match stance:
		"take": done=_take(civ_id,today,options)
		"punish": done=_punish(civ_id,today,options)
		"defend": done=_defend(civ_id,today,options)
		"peace": done=_peace(civ_id,today,options)
		_: done=_leave(civ_id,today,options)
	var f:=_front(civ_id)
	f["verdict"]=String(done.get("verdict",""))
	f["says"]=String(done.get("says","")).substr(0,WORDS_MAX)
	f["sat"]=today
	return done

## Their band in sight near a town of ours, in words for the screens, worked
## out at the sitting ("Their band of 40 is 30 km from Ashford, here in about
## 2 days"): the screens read it, never the sightings themselves.
static func _see_them_coming(civ_id:String,today:int)->void:
	if not _player(): return
	var f:=_front(civ_id)
	var coming:=their_bands(civ_id)
	if coming.is_empty():
		f.erase("coming"); f.erase("coming_band")
		return
	var c:Dictionary=coming[0]
	var town:=_nearest_town_name(c.position)
	f["coming"]=("%s of %d is %s from %s, here in about %s" % ["Their band" if String(c.label)=="Their band" else String(c.label),int(c.strength),_km_words(float(c.km)),town,_span(int(c.days))]).substr(0,WORDS_MAX)
	f["coming_day"]=today
	f["coming_band"]={"strength":int(c.strength),"town":town,"days":int(c.days),"km":snappedf(float(c.km),0.1)}

static func _record(civ_id:String,verdict:String,says:String,extra:Dictionary={})->Dictionary:
	var out:={"verdict":verdict,"says":says,"live":false}
	out.merge(extra,true)
	return out

# --- Take a town ------------------------------------------------------------

static func _take(civ_id:String,today:int,options:Dictionary)->Dictionary:
	var band:=_band_on(civ_id,["take"])
	if not band.is_empty(): return _follow(civ_id,band,today)
	# A punishing band out against them comes home first: one errand at a time.
	for other in bands_against(civ_id): _send_home(other)
	var insist:=bool(options.get("insist",false))
	var town:=_take_target(civ_id,options)
	if town.is_empty():
		return _record(civ_id,"wait","%s knows no town of %s to march on. Scouts must find one first." % [_who(),_name(civ_id)])
	if _ours(civ_id,String(town.city_id)):
		if _player(): (_war_loop().call("front",civ_id) as Dictionary).erase("take")
		return _record(civ_id,"hold","%s is ours already; %s holds it." % [String(town.name),_who()])
	var f:=_front(civ_id)
	var rest:=TAKE_REST_DAYS-(today-int(f.get("take_failed",-99999)))
	if rest>0 and not insist and not bool(options.get("now",false)):
		return _record(civ_id,"rest","%s mends the band after %s; it goes again in about %s." % [_who(),String(town.name),_span(rest)])
	# With nobody to send the war leader says so plainly (court_war_orders:
	# nobody under arms, or too few for a band).
	var free:=_free_men()
	if not insist and free>=MIN_BAND:
		# Enough to hold it after the fight, or nobody goes (no tiny-force
		# capture: docs/GENERAL_CAMPAIGN_DESIGN.md).
		var need:=_hold_need(town)
		if need>0 and free<need:
			return _record(civ_id,"wait","%s waits: holding %s after the fight would take about %d of ours, by our scouts' count of its people, and we can send %d. About %d more would do it." % [_who(),String(town.name),need,free,need-free],{"need":need})
		var fed:=_fed_at(town,free)
		if not fed.is_empty() and float(fed.ratio)<Supply.STARVING_BELOW:
			return _record(civ_id,"wait",_hungry_road_words(town,fed),{"fed":float(fed.ratio)})
	return _launch(civ_id,town,"take",insist,options)

## About how many of ours holding this town would take after the fight: the
## world's own rule for holding a town (civilization_system
## occupation_requirement) on our scouts' count of its people, with
## HOLD_MARGIN for the fight's losses. -1 when nobody counted its people.
static func _hold_need(town:Dictionary)->int:
	var world:Variant=WorldSimulation.world
	var report:Dictionary=world.city_intelligence.known("player",String(town.city_id))
	var field:Dictionary=((report.get("fields",{}) as Dictionary).get("population",{}) as Dictionary)
	if field.is_empty(): return -1
	var civ:=_civ(String(town.civ_id))
	var region:Dictionary=world.region_snapshot(String(town.civ_id),String(town.city_id))
	if civ.is_empty() or region.is_empty(): return -1
	region["population"]=(float(field.get("low",0.0))+float(field.get("high",0.0)))*0.5
	return ceili(float(world.occupation_requirement(civ,region))*HOLD_MARGIN)

## The town to take: the god's pick while it is still theirs, else the
## council's by the odds.
static func _take_target(civ_id:String,options:Dictionary)->Dictionary:
	var place:Dictionary=options.get("place",{}) if options.get("place") is Dictionary else {}
	if not place.is_empty() and String(place.get("city_id",""))!="": return _town(civ_id,String(place.city_id),String(place.get("name","")))
	if _player():
		var chosen_town:Dictionary=(_war_loop().call("_peek",civ_id) as Dictionary).get("take",{})
		if chosen_town is Dictionary and String((chosen_town as Dictionary).get("city_id",""))!="":
			var found:=_town(civ_id,String(chosen_town.city_id),String(chosen_town.get("name","")))
			if not found.is_empty(): return found
	return pick_town(civ_id)

## The council's pick among their towns we know: the best odds for the road,
## nearest first among the few weighed (PICKS).
static func pick_town(civ_id:String)->Dictionary:
	var towns:=known_towns(civ_id)
	if towns.is_empty(): return {}
	var home:Vector2=WorldSimulation.world.player_world_origin
	towns.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return home.distance_squared_to(_v2(a.position))<home.distance_squared_to(_v2(b.position)))
	var forces:=_forces()
	var best:={}
	var best_score:=-INF
	for town:Dictionary in towns.slice(0,PICKS):
		var odds:=_odds_at(town,int(forces.free),"take")
		var raw:=float(odds.get("raw",1.0)) if not odds.is_empty() else 1.0
		var km:=home.distance_to(_v2(town.position))
		var score:=minf(raw,4.0)/(1.0+km/120.0)
		if score>best_score: best_score=score; best=town
	return best

# --- Punish -----------------------------------------------------------------

static func _punish(civ_id:String,today:int,options:Dictionary)->Dictionary:
	var band:=_band_on(civ_id,["punish"])
	if not band.is_empty(): return _follow(civ_id,band,today)
	for other in bands_against(civ_id): _send_home(other)
	var f:=_front(civ_id)
	var insist:=bool(options.get("insist",false))
	var called:=_raid_called(civ_id)
	var rest:=RAID_REST_DAYS-(today-int(f.get("raided",-99999)))
	# The council's own next raid waits out the rest; the god's fresh word does not.
	if rest>0 and not insist and not called and not bool(options.get("now",false)):
		return _record(civ_id,"rest","%s's raiders rest after the last raid on %s; the next goes in about %s." % [_who(),_name(civ_id),_span(rest)])
	var town:=_punish_target(civ_id,options)
	if town.is_empty():
		if called: _raid_sent(f)
		return _find_them(civ_id,today,String(options.get("asked","")))
	if not insist:
		var fed:=_fed_at(town,_raid_size(town))
		if not fed.is_empty() and float(fed.ratio)<Supply.STARVING_BELOW:
			if called: _raid_sent(f)
			return _record(civ_id,"wait",_hungry_road_words(town,fed),{"fed":float(fed.ratio)})
	var done:=_launch(civ_id,town,"punish",insist,options)
	if String(done.get("verdict",""))!="wait" and called: _raid_sent(f)
	return done

## Their nearest town we know (the god's pick while it stands).
static func _punish_target(civ_id:String,options:Dictionary)->Dictionary:
	var place:Dictionary=options.get("place",{}) if options.get("place") is Dictionary else {}
	if not place.is_empty() and String(place.get("city_id",""))!="": return _town(civ_id,String(place.city_id),String(place.get("name","")))
	if _player():
		var at:Variant=(_war_loop().call("_peek",civ_id) as Dictionary).get("punish_at",{})
		if at is Dictionary and String((at as Dictionary).get("city_id",""))!="":
			var found:=_town(civ_id,String(at.city_id),String(at.get("name","")))
			if not found.is_empty(): return found
	var towns:=known_towns(civ_id)
	if towns.is_empty(): return {}
	var home:Vector2=WorldSimulation.world.player_world_origin
	towns.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return home.distance_squared_to(_v2(a.position))<home.distance_squared_to(_v2(b.position)))
	return towns[0]

## Nobody knows where they live: the god's war leader sends trackers after
## their raiders' trail (war_loop.gd war_track); a computer ruler waits for
## its scouts.
static func _find_them(civ_id:String,_today_day:int,asked:String="")->Dictionary:
	if not _player():
		return _record(civ_id,"wait","The war leader does not know where %s live." % _name(civ_id))
	var wl:=_war_loop()
	var f:Dictionary=wl.call("front",civ_id)
	var op:Dictionary=f.get("op",{}) if f.get("op") is Dictionary else {}
	if String(op.get("objective",""))=="war_track":
		var left:=maxi(0,int(op.get("due",_today()))-_today())
		return _record(civ_id,"act","%s's trackers follow %s's trail home; they should be back in about %s." % [String(op.get("general",_who())),_name(civ_id),_span(left)],{"live":true})
	if bool(wl.call("home_known",civ_id)):
		return _record(civ_id,"wait","We know where %s live, but no town of theirs is on our charts yet. Scouts must count it first." % _name(civ_id))
	if not op.is_empty():
		return _record(civ_id,"wait","%s is already out against %s; the raid waits until they are back." % [String(op.get("general",_who())),_name(civ_id)])
	var said:=String(wl.call("send_trackers",civ_id,asked))
	return _record(civ_id,"act",said,{"live":true})

## The band a raid needs: a raiding party (RAID_FLOOR at least, the
## record's 5 to 30 men of a raid at small scale), larger as their fighters
## are many, until the odds are 3 to 2; else all the war leader can spare.
static func _raid_size(town:Dictionary)->int:
	var forces:=_forces()
	var free:=int(forces.free)
	if free<=0: return 0
	var least:=mini(free,RAID_FLOOR)
	var enemy:=_estimate(String(town.city_id))
	if not bool(enemy.get("known",false)): return free
	# A raid meets the part of their fighters out at the fields and stores.
	var mid:=float(enemy.get("mid",0.0))*0.72
	var walls:=float(enemy.get("fortification",0.25))
	var formations:Array=forces.formations
	if Odds.heads(formations)<=0: return free
	var arms:=Odds.their_arms(String(town.civ_id),int(enemy.get("age",-1)))
	for n in [least,maxi(least,ceili(mid)),maxi(least,ceili(mid*1.5)),maxi(least,ceili(mid*2.0)),maxi(least,ceili(mid*3.0))]:
		if n>=free: break
		var o:=Odds.of(forces.force,formations,n,mid,walls,arms,String(town.civ_id),false,-1.0,float(enemy.get("untrained",0.0)))
		if not o.is_empty() and float(o.raw)>=Odds.TAKE_ODDS: return n
	return free

# --- Defend -----------------------------------------------------------------

static func _defend(civ_id:String,today:int,options:Dictionary)->Dictionary:
	var live:=false
	# Bands out on an errand against them come home to hold.
	for band in bands_against(civ_id):
		var act:=String((band.council as Dictionary).get("act",""))
		if act in ["take","punish"]: _send_home(band)
		else:
			var followed:=_follow(civ_id,band,today)
			live=live or bool(followed.get("live",false))
	if _player():
		var f:Dictionary=_war_loop().call("front",civ_id)
		f["guard_until"]=maxi(int(f.get("guard_until",-1)),today+int(_war_loop().get("GUARD_DAYS")))
	var parts:=PackedStringArray()
	# A short garrison in a town we hold of theirs gets men from home.
	var reinforced:=_man_garrisons(civ_id)
	if reinforced!="": parts.append(reinforced)
	# Their band seen coming: a band of ours goes out to meet it.
	var met:=_meet_their_band(civ_id,options)
	if met!="": parts.append(met)
	# Live while a band of ours is out, or theirs is in sight.
	live=live or not _band_on(civ_id,["reinforce","intercept"]).is_empty() or not their_bands(civ_id).is_empty()
	var home:=int(_mc().home_army.get("troops",0))
	var held:=_held_words(civ_id)
	if parts.is_empty():
		var watch:="%s keeps %s at home on the approaches" % [_who(),_fighters(home)] if home>0 else "%s has nobody trained to put on the watch; the village keeps its own" % _who()
		parts.append(watch+(("; "+held) if held!="" else "")+".")
	return _record(civ_id,"hold"," ".join(parts),{"live":live})

## Towns we hold of theirs whose garrisons are short: men march from home.
static func _man_garrisons(civ_id:String)->String:
	var mc:=_mc()
	if _band_on(civ_id,["reinforce"]).size()>0: return ""
	for force in mc.occupation_forces:
		if not force is Dictionary or String((force as Dictionary).get("civ_id",""))!=civ_id: continue
		var region_id:=String((force as Dictionary).get("region_id",""))
		var control:Dictionary=WorldSimulation.world.occupation_control(civ_id,region_id)
		if control.has("error") or bool(control.get("controlled",true)): continue
		var short:=maxi(0,int(control.get("required",0))-int(control.get("troops",0)))
		var send:=mini(short,int(_forces().free))
		if send<MIN_BAND: continue
		var made:Dictionary=mc.create_field_army(send,"Men for %s" % _town_name(civ_id,region_id))
		if made.has("error"): continue
		var army_id:=int((made.army as Dictionary).army_id)
		var moved:Dictionary=mc.move_field_army(army_id,region_id)
		if moved.has("error"):
			mc.disband_field_army(army_id)
			continue
		_tag(army_id,civ_id,"reinforce",{"city_id":region_id,"name":_town_name(civ_id,region_id)},{},true)
		return "%d march from home to hold %s, about %s on the road." % [send,_town_name(civ_id,region_id),_span(int(moved.get("days",0)))]
	return ""

## Their band in sight near a town of ours: the council sends a band to meet
## it in the field (MilitaryCampaign intercept), at even odds or better.
static func _meet_their_band(civ_id:String,options:Dictionary)->String:
	if not _band_on(civ_id,["intercept"]).is_empty(): return ""
	var coming:=their_bands(civ_id)
	if coming.is_empty(): return ""
	var target:Dictionary=coming[0]
	var forces:=_forces()
	var free:=int(forces.free)
	if free<MIN_BAND: return "%s are coming, about %d strong, and nobody at home is free to go out; the watch meets them at home." % [String(target.label),int(target.strength)]
	var insist:=bool(options.get("insist",false))
	var odds:=Odds.of(forces.force,forces.formations,free,float(target.strength),0.0,Odds.their_arms(civ_id,0),civ_id,true,float(target.get("readiness",-1.0)))
	if not insist and not odds.is_empty() and float(odds.raw)<Odds.RAID_ODDS:
		return "%s are coming, about %d strong; the odds in the open are %s, so %s keeps the watch at home behind the works." % [String(target.label),int(target.strength),Odds.said(odds),_who()]
	var mc:=_mc()
	var made:Dictionary=mc.create_field_army(free,"Band against %s" % _name(civ_id))
	if made.has("error"): return "%s cannot go out after them: %s" % [_who(),String(made.error)]
	var army_id:=int((made.army as Dictionary).army_id)
	var result:Dictionary=mc.order_field_army_intercept(army_id,String(target.id))
	if result.has("error"):
		mc.disband_field_army(army_id)
		return "%s cannot go out after them: %s" % [_who(),String(result.error)]
	_tag(army_id,civ_id,"intercept",{"city_id":"","name":String(target.label),"formation_id":String(target.id)},odds,true)
	var said:="%s takes %d out after %s, about %d strong%s." % [_who(),free,String(target.label),int(target.strength),(": the odds in the open are "+Odds.said(odds)) if not odds.is_empty() else ""]
	if _player(): _chronicle("meet:%s:%d" % [civ_id,_today()],"%s Goes Out to Meet Them" % _who(),said,civ_id)
	return said

## Their bands in sight, nearest to a town of ours first: {id, label,
## strength, readiness, position, km (to the nearest town of ours), days}.
static func their_bands(civ_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var world:Variant=WorldSimulation.world
	if world==null: return out
	var ours:=_our_points()
	for formation in world.foreign_formations:
		if not formation is Dictionary: continue
		var rec:Dictionary=formation
		if String(rec.get("kind",""))=="scout" or String(rec.get("civ_id",""))!=civ_id: continue
		var seen:Dictionary=world.visible_formation_sighting(String(rec.get("id","")))
		if seen.is_empty(): continue
		var at:=_v2(seen.get("position",{}))
		if not at.is_finite(): continue
		var km:=INF
		for p:Vector2 in ours: km=minf(km,p.distance_to(at))
		if km>INTERCEPT_KM: continue
		var strength:=(float(seen.get("strength_estimate_low",0))+float(seen.get("strength_estimate_high",0)))*0.5
		if strength<1.0: strength=float(rec.get("actual_troops",0))
		out.append({"id":String(rec.get("id","")),"label":"Their band" if String(seen.get("label",""))=="" else String(seen.label),"strength":maxi(1,roundi(strength)),
			"readiness":(float(seen.get("readiness_estimate_low",0.5))+float(seen.get("readiness_estimate_high",0.5)))*0.5,"position":at,"km":km,"days":maxi(1,ceili(km/18.0))})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.km)<float(b.km))
	return out

static func _our_points()->Array[Vector2]:
	var out:Array[Vector2]=[WorldSimulation.world.player_world_origin]
	for city in WorldSimulation.state.player_settlements:
		if not city is Dictionary: continue
		var p:Variant=(city as Dictionary).get("position",null)
		if p is Vector2: out.append(p)
		elif p is Dictionary: out.append(_v2(p))
	return out

# --- Leave them be, seek peace ----------------------------------------------

static func _leave(civ_id:String,today:int,options:Dictionary)->Dictionary:
	var home:=_recall(civ_id,today)
	if not _player(): return _record(civ_id,"noted","Our bands stay home.",{"live":home>0})
	var said:=""
	if bool(options.get("now",false)) and bool(options.get("new",false)): said=String(_war_loop().call("let_be",civ_id))
	var tail:=" %d of ours are on their way home." % home if home>0 else ""
	return _record(civ_id,"noted",(said if said!="" else "No one goes after %s; their raids are met at home." % _name(civ_id))+tail,{"live":home>0})

static func _peace(civ_id:String,today:int,options:Dictionary)->Dictionary:
	var home:=_recall(civ_id,today)
	if not _player(): return _record(civ_id,"noted","The war leader keeps the bands home and waits for word of peace.",{"live":home>0})
	var wl:=_war_loop()
	var f:Dictionary=wl.call("front",civ_id)
	var op:Dictionary=f.get("op",{}) if f.get("op") is Dictionary else {}
	var war:Dictionary=f.get("war",{}) if f.get("war") is Dictionary else {}
	if op.is_empty() and war.get("op") is Dictionary: op=war.op
	var tail:=" %d of ours are on their way home." % home if home>0 else ""
	if String(op.get("objective",""))=="war_parley":
		var left:=maxi(0,int(op.get("due",today))-today)
		return _record(civ_id,"act","Our messengers are on their way to %s; they should be back in about %s.%s" % [_name(civ_id),_span(left),tail],{"live":true})
	if not bool(wl.call("feuding",civ_id)) and (war.is_empty()) and not fighting(civ_id):
		# Peace holds: the stance has done its work and is set down, so no
		# messengers go again to settle what is settled.
		if String(f.get("stance",""))=="peace": f.erase("stance")
		return _record(civ_id,"noted","There is no fight with %s to end.%s" % [_name(civ_id),tail],{"live":home>0})
	var last:=int(_front(civ_id).get("parleyed",-99999))
	if not op.is_empty() or (today-last<PARLEY_GAP and not bool(options.get("now",false))):
		return _record(civ_id,"noted","No raid goes out against %s while we seek peace. Messengers go again in about %s.%s" % [_name(civ_id),_span(maxi(1,PARLEY_GAP-(today-last))),tail],{"live":home>0})
	_front(civ_id)["parleyed"]=today
	var said:=String(wl.call("send_messengers",civ_id))
	return _record(civ_id,"act",said+tail,{"live":true})

## Every band of ours out against this people turns for home.
static func _recall(civ_id:String,_today_day:int)->int:
	var men:=0
	for band in bands_against(civ_id):
		if _at_home(band): continue
		if String((band.council as Dictionary).get("phase",""))=="home" and String(band.get("destination_id",""))=="player_home": continue
		if _send_home(band): men+=int(band.get("troops",0))
	return men

# --------------------------------------------------------------------------
# Bands on the council's errand
# --------------------------------------------------------------------------

## Our bands out on the council's errand against a people.
static func bands_against(civ_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var mc:=_mc()
	if mc==null: return out
	for army in mc.field_armies:
		if not army is Dictionary or int((army as Dictionary).get("troops",0))<=0: continue
		var c:Variant=(army as Dictionary).get("council")
		if c is Dictionary and String((c as Dictionary).get("civ",""))==civ_id: out.append(army)
	return out

static func _council_bands()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var mc:=_mc()
	if mc==null: return out
	for army in mc.field_armies:
		if army is Dictionary and _errand(army)!=null: out.append(army)
	return out

## The band's errand ({civ, act, phase, ...}), or null when it has none (an
## empty record left on an old save is none).
static func _errand(army:Dictionary)->Variant:
	var c:Variant=army.get("council")
	return c if c is Dictionary and not (c as Dictionary).is_empty() else null

static func _band_on(civ_id:String,acts:Array)->Dictionary:
	for band in bands_against(civ_id):
		if String((band.council as Dictionary).get("act","")) in acts and String((band.council as Dictionary).get("phase",""))!="home": return band
	return {}

static func _any_out()->bool:
	for band in _council_bands():
		if int(band.get("troops",0))>0 and not _at_home(band): return true
	return false

static func _at_home(band:Dictionary)->bool:
	return String(band.get("status",""))=="stationed" and String(band.get("location_id",""))=="player_home"

## The band's errand, written on the band (saved with it).
static func _tag(army_id:int,civ_id:String,act:String,town:Dictionary,odds:Dictionary,formed:bool)->void:
	var mc:=_mc()
	var index:int=mc._field_army_index(army_id)
	if index<0: return
	var tag:={"civ":civ_id,"act":act,"city":String(town.get("city_id","")),"name":String(town.get("name","")).substr(0,60),"since":_today(),"phase":"out","formed":formed}
	if not odds.is_empty(): tag["odds"]=snappedf(float(odds.get("raw",1.0)),0.01)
	if String(town.get("formation_id",""))!="": tag["formation"]=String(town.formation_id)
	mc.field_armies[index]["council"]=tag
	_free_of_chain(army_id)
	var lead:=_leader_for(civ_id)
	if lead!="": (load(COMMANDS_PATH) as GDScript).call("assign",mc,army_id,lead)

## The general the god chose to lead against this people (the War screen's
## "Led by": WarLoop.front(civ_id).general, a figure id), while they live and
## are not in a fight; "" for the war leader's own choice.
static func _leader_for(civ_id:String)->String:
	if not _player(): return ""
	var figure_id:=String((_war_loop().call("_peek",civ_id) as Dictionary).get("general",""))
	if figure_id=="": return ""
	var figures:Variant=WorldSimulation.figures
	if figures==null: return ""
	var person:Dictionary=figures.by_id(figure_id)
	if person.is_empty() or String(person.get("role",""))!="General" or String(person.get("status",""))!="living": return ""
	var mc:=_mc()
	for army in mc.field_armies:
		if not army is Dictionary: continue
		var c:Dictionary=(army as Dictionary).get("commander",{}) if (army as Dictionary).get("commander") is Dictionary else {}
		if String(c.get("figure_id",""))!=figure_id: continue
		var army_id:=int((army as Dictionary).get("army_id",0))
		if mc.command_hierarchy.battle.engaged(army_id) or mc._army_in_battle(army_id): return ""
	return figure_id

## The general's record for the war leader's spoken core, so the march is
## said in their name ({} for the war leader's own choice).
static func _leader_ref(civ_id:String)->Dictionary:
	var figure_id:=_leader_for(civ_id)
	if figure_id=="": return {}
	var person:Dictionary=WorldSimulation.figures.by_id(figure_id)
	return {"name":String(person.get("name","")),"person_id":0,"figure_id":figure_id}

## A band on an errand, followed: siege, fight, the town taken, the raid
## done, the way home.
static func _follow(civ_id:String,band:Dictionary,today:int)->Dictionary:
	var mc:=_mc()
	var c:Dictionary=band.council
	var act:=String(c.get("act",""))
	var army_id:=int(band.get("army_id",0))
	var town_id:=String(c.get("city",""))
	var name:=String(c.get("name",""))
	var who:=_who(band)
	var ids:={"live":true,"army_id":army_id,"following":true}
	if mc.command_hierarchy.battle.engaged(army_id) or mc._army_in_battle(army_id):
		return _record(civ_id,"act","%s is fighting at %s with %s." % [who,name if name!="" else "them",_fighters(int(band.troops))],ids)
	if bool(band.get("resting",false)):
		# The war leader took it out of the fighting to rest and refill
		# (band_upkeep.gd: broken, under strength or hungry). Its errand ends
		# here; upkeep brings it to its rest, and the stance sends fresh men
		# after the usual rest.
		c["phase"]="home"
		match act:
			"take": _front(civ_id)["take_failed"]=today
			"punish": _front(civ_id)["raided"]=today
		return _record(civ_id,"rest","%s is out of the fighting to rest and refill (%s)." % [who,_unfit_words(band)],ids)
	if mc._besieging(army_id):
		# The general storms when the walls are worn (military_campaign:
		# a commander's siege assaults at pressure 0.72).
		mc.active_siege["commander_managed"]=true
		return _record(civ_id,"act","%s besieges %s, day %d." % [who,name,maxi(1,int(mc.active_siege.get("days",0)))],ids)
	if String(band.get("status",""))=="moving":
		return _record(civ_id,"act","%s is on the road%s." % [who,(" to "+name) if name!="" else ""],ids)
	match act:
		"take":
			if town_id!="" and _ours(civ_id,town_id):
				c["phase"]="done"
				var held:=int(mc.occupation_force_for_region(civ_id,town_id).get("troops",0))
				if _player():
					var f:Dictionary=_war_loop().call("front",civ_id)
					f.erase("take")
					# The town is held now: the stance is to hold what we took.
					if String(f.get("stance",""))=="take": f["stance"]="defend"
				_send_home(band)
				return _record(civ_id,"hold","%s is ours. %s leaves %s to hold it and brings the rest home." % [name,who,_fighters(held)],ids.merged({"taken":town_id},true))
			# Beaten at the walls or too few to hold: home to mend, then the
			# council weighs it again after a rest.
			_front(civ_id)["take_failed"]=today
			_send_home(band)
			return _record(civ_id,"rest","%s could not take %s and brings the band home to mend." % [who,name],ids)
		"punish":
			_front(civ_id)["raided"]=today
			_send_home(band)
			return _record(civ_id,"act","%s's raiders are done at %s and turn for home." % [who,name],ids)
		"reinforce":
			if town_id!="" and String(band.get("location_id",""))==town_id:
				mc.reinforce_occupation(civ_id,town_id,false)
				var left:=_army(army_id)
				if not left.is_empty() and int(left.get("troops",0))>0: _send_home(left)
				return _record(civ_id,"hold","Our men reached %s and joined its garrison." % name,ids)
			_send_home(band)
			return _record(civ_id,"hold","The men for %s turn for home." % name,ids)
		"intercept":
			_send_home(band)
			return _record(civ_id,"hold","%s's band is done with them and turns for home." % who,ids)
	_send_home(band)
	return _record(civ_id,"hold","%s turns for home." % who,ids)

## A band turns for home by the land road (or, already home, is ready to be
## folded back into the levy). False when it cannot move now.
static func _send_home(band:Dictionary)->bool:
	var mc:=_mc()
	var army_id:=int(band.get("army_id",0))
	var index:int=mc._field_army_index(army_id)
	if index<0: return false
	var live:Dictionary=mc.field_armies[index]
	if live.get("council") is Dictionary: (live.council as Dictionary)["phase"]="home"
	# Resting: the war leader's upkeep brings it to its rest (band_upkeep.gd).
	if bool(live.get("resting",false)): return true
	if _at_home(live): return true
	if String(live.get("status",""))=="moving" and String(live.get("destination_id",""))=="player_home": return true
	if mc.command_hierarchy.battle.engaged(army_id) or mc._army_in_battle(army_id) or mc._besieging(army_id): return false
	var r:Dictionary=mc.return_field_army(army_id)
	if r.has("error"): return false
	index=mc._field_army_index(army_id)
	if index>=0: mc.field_armies[index].erase("court_order")
	return true

## The army stands above the watch the god keeps (watch_military.gd): the
## bands with no errand (no stance needs them, no march, siege, chase or
## fight under way) come home and fold back into the levy at home, where the
## law's next look sends the surplus back to work. Bands on an errand stay
## out until it ends. Returns the bands called in.
static func fold_idle_bands()->int:
	var mc:=_mc()
	var reading:=LAW.reading(mc)
	# Above the watch by more than the war leader's slack (watch_military.gd
	# keep sends the rest at home back to work).
	var slack:=maxi(1,ceili(float(reading.get("target",0))*float(preload("res://scripts/watch_military.gd").SLACK)))
	if -int(reading.get("gap",0))<=slack: return 0
	var called:=0
	for army in (mc.field_armies as Array).duplicate():
		if not army is Dictionary: continue
		var army_id:=int((army as Dictionary).get("army_id",0))
		# At home with nothing under way, resting or not: home is where a band
		# rests and refills, and the army at home is that.
		if LAW.home_band(mc,army):
			if not mc.disband_field_army(army_id).has("error"): called+=1
			continue
		if not _idle(army): continue
		if _at_home(army):
			if not mc.disband_field_army(army_id).has("error"): called+=1
		elif _send_home(army): called+=1
	return called

## A band with nothing to do: no errand of the council's under way, no march
## ordered elsewhere, no siege, chase, fight, voyage or zone order.
static func _idle(army:Dictionary)->bool:
	var mc:=_mc()
	var army_id:=int(army.get("army_id",0))
	if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)): return false
	if army.get("pursuit") is Dictionary or bool(army.get("relief_assignment",false)): return false
	# Broken, under strength or resting: the war leader's upkeep has it.
	if not _fit(army): return false
	var c:Variant=_errand(army)
	if c!=null and not String((c as Dictionary).get("phase","")) in ["home","done"]: return false
	if String(army.get("status",""))=="moving" and String(army.get("destination_id",""))!="player_home": return false
	if mc.command_hierarchy.battle.engaged(army_id) or mc._army_in_battle(army_id) or mc._besieging(army_id): return false
	if mc.command_hierarchy.controls_army(army_id): return false
	if WorldSimulation.campaign!=null and bool(WorldSimulation.campaign.active) and army_id==int(WorldSimulation.campaign.state.get("army_id",-1)): return false
	if _at_post(army): return false
	return true

## A band at work or on watch where the ruler put it: waiting on the ground
## he sent it to (army_orders "Go to…"), laying a depot, or standing by a
## depot of ours (field_depots: bands near it keep it from the torch).
static func _at_post(army:Dictionary)->bool:
	var site:Variant=army.get("depot_site")
	if site is Dictionary and not (site as Dictionary).is_empty(): return true
	var here:=_v2(army.get("position",{}))
	if not here.is_finite(): return false
	var post:Variant=army.get("post")
	if post is Dictionary and here.distance_to(_v2(post))<=POST_KM: return true
	var mc:=_mc()
	for depot in mc.field_depots:
		if depot is Dictionary and here.distance_to(Vector2(float((depot as Dictionary).get("x",0.0)),float((depot as Dictionary).get("z",0.0))))<=float(DEPOTS.RAID_KM): return true
	return false

# --- Bands left in the field -----------------------------------------------

## Every sitting: our bands with no errand of the council's, not guarding a
## town we hold, not fighting and not on a live order (on the road, under a
## standing command, pursuing, aboard ship). Those at home go back into the
## army at home at once. One out in the field takes up the stance's work
## where it fits (_take_up); the rest come home, and go back into the army
## when they arrive (_tidy_home). The Chronicle tells it once.
static func _gather_strays(stances:Dictionary,today:int)->void:
	var mc:=_mc()
	if mc==null: return
	var called:Array[String]=[]
	var taken:Array[String]=[]
	for army in (mc.field_armies as Array).duplicate():
		if not army is Dictionary: continue
		var band:Dictionary=army
		if _errand(band)!=null or not _idle(band) or _guards_ours(band): continue
		var army_id:=int(band.get("army_id",0))
		var name:="%s (%s)" % [Logistics.force_name(band),EraWords.grouped(int(band.get("troops",0)))]
		if _at_home(band):
			# Formed at home and never sent anywhere: it waits a while for
			# the ruler's word (realm_orders "form a band").
			if int(band.get("arrival_day",-1))<0 and int(band.get("departure_day",-1))<0:
				if not band.has("idle_since"): band["idle_since"]=today
				if today-int(band.get("idle_since",today))<FORMED_GRACE_DAYS: continue
			if not mc.disband_field_army(army_id).has("error"): called.append(name)
			continue
		var errand:=_take_up(band,stances,today) if _fit(band) else ""
		if errand!="":
			taken.append(errand)
			continue
		if not _send_home(band): continue
		var index:int=mc._field_army_index(army_id)
		if index>=0: mc.field_armies[index]["council"]={"civ":"","act":"home","city":"","name":"","since":today,"phase":"home","formed":true}
		called.append(name)
	if called.is_empty() and taken.is_empty(): return
	var s:=state()
	if not _player() or bool(s.get("strays_told",false)): return
	s["strays_told"]=true
	var parts:=PackedStringArray()
	if not called.is_empty(): parts.append("The war leader called home the bands left in the field: %s. Their men go back to the army at home." % _and_list(called))
	for errand in taken: parts.append(errand+".")
	preload("res://scripts/chronicle.gd").record({"key":"council:strays:%d" % today,"title":"The Bands Come Home","text":" ".join(parts),"tier":"notice","kind":"war","domain":"security"})

## A band left out in the field takes up the stance's work where it fits:
## punish or take against a people with no band of the council's out on it
## and no rest due, at the town the council would choose, when the band
## stands nearer that town than the home does and its own men make the
## odds there (and, to take it, are enough to hold it). The words for the
## Chronicle, or "" when it does not fit.
static func _take_up(band:Dictionary,stances:Dictionary,today:int)->String:
	var here:=_v2(band.get("position",{}))
	if not here.is_finite(): return ""
	var home:Vector2=WorldSimulation.world.player_world_origin
	for key in stances:
		var civ_id:=String(key)
		var stance:=String(stances[key])
		if not stance in ["punish","take"] or not _band_on(civ_id,[stance]).is_empty(): continue
		var f:=_front(civ_id)
		if stance=="punish" and today-int(f.get("raided",-99999))<RAID_REST_DAYS and not _raid_called(civ_id): continue
		if stance=="take" and today-int(f.get("take_failed",-99999))<TAKE_REST_DAYS: continue
		var town:=_punish_target(civ_id,{}) if stance=="punish" else _take_target(civ_id,{})
		if town.is_empty() or _ours(civ_id,String(town.city_id)): continue
		var at:=_v2(town.get("position",{}))
		if not at.is_finite() or here.distance_to(at)>home.distance_to(at): continue
		var kind:="raid" if stance=="punish" else "take"
		var reading:=_band_odds(band,town,kind)
		if reading.is_empty() or float(reading.raw)<Odds.wanted(kind): continue
		if stance=="take" and _hold_need(town)>int(band.get("troops",0)): continue
		var army_id:=int(band.get("army_id",0))
		var name:=Logistics.force_name(band)
		var order:Dictionary=_mc().order_city_operation(army_id,civ_id,String(town.city_id),stance=="take",stance=="punish")
		if order.has("error"): continue
		var index:int=_mc()._field_army_index(army_id)
		if index>=0: (_mc().field_armies[index] as Dictionary).erase("court_order")
		_tag(army_id,civ_id,stance,town,reading,true)
		if stance=="punish" and _raid_called(civ_id): _raid_sent(f)
		return "%s, out in the field, takes up the %s %s" % [name,"raid on" if stance=="punish" else "march on",String(town.name)]
	return ""

## The odds this band, as it stands, would face at the town.
static func _band_odds(band:Dictionary,town:Dictionary,kind:String)->Dictionary:
	var going:=int(band.get("troops",0))
	var formations:Array=band.get("formations",[]) if band.get("formations") is Array else []
	if going<=0 or Odds.heads(formations)<=0: return {}
	var enemy:=_estimate(String(town.city_id))
	if not bool(enemy.get("known",false)): return {}
	var mid:=float(enemy.get("mid",0.0))*(0.72 if kind=="raid" else 1.0)
	return Odds.of(band,formations,going,mid,float(enemy.get("fortification",0.25)),Odds.their_arms(String(town.civ_id),int(enemy.get("age",-1))),String(town.civ_id),false,-1.0,float(enemy.get("untrained",0.0)))

## Fit to be sent: not resting, nor broken or under strength (army_lines.gd,
## band_upkeep.gd).
static func _fit(band:Dictionary)->bool:
	return not bool(band.get("resting",false)) and not Lines.unfit(band)

## Why a band is out of the fighting, in plain words.
static func _unfit_words(band:Dictionary)->String:
	var why:=Lines.why_unfit(band)
	if why!="": return why
	return String({"hungry":"hungry too long","broken":"its will broken","weak":"too few men"}.get(String(band.get("rest_reason","")),"resting and refilling"))

## A band on the council's errand answers to the council, not to a standing
## order up the chain of command (a whole-army or a general's objective):
## its own place in the chain is marked free of it (the order itself is not
## cancelled, and the band keeps its march), so the war leader's upkeep sees
## to it (band_upkeep.gd free_to_see_to) and the zone staff leave it be
## (land_command.gd).
static func _free_of_chain(army_id:int)->void:
	var command:RefCounted=_mc().command_hierarchy
	if not command.controls_army(army_id): return
	command.sync()
	for entry in command.data.nodes.values():
		var node:Dictionary=entry
		if String(node.get("service",""))=="army" and int(node.get("force_id",-1))==army_id:
			node["order"]={"mission":"cancelled","by":"war council"}
			return

## A band standing in a town of ours other than the home (one of our own
## settlements, or a town of another people we hold): it is its guard.
static func _guards_ours(band:Dictionary)->bool:
	if String(band.get("status",""))!="stationed": return false
	var at:=String(band.get("location_id",""))
	if at=="" or at=="player_home": return false
	for city in WorldSimulation.state.player_settlements:
		if city is Dictionary and String((city as Dictionary).get("id",""))==at: return String((city as Dictionary).get("occupied_by","")) in ["","player"]
	var world:Variant=WorldSimulation.world
	if world==null or not world.has_method("_region_location"): return false
	var where:Dictionary=world._region_location(at)
	if where.is_empty(): return false
	var region:Dictionary=world.civilizations[int(where.owner_index)].strategic_regions[int(where.region_index)]
	return String(region.get("controller",""))=="player"

## Bands with nobody left standing, not in a fight, are struck off where
## they are: at home dissolved as any band is; out in the field their wounded,
## scattered and taken are counted with the army at home, and the gear of the
## fallen is lost with them.
static func _strike_off_empty()->void:
	var mc:=_mc()
	if mc==null: return
	for army in (mc.field_armies as Array).duplicate():
		if not army is Dictionary or int((army as Dictionary).get("troops",0))>0: continue
		var band:Dictionary=army
		var army_id:=int(band.get("army_id",0))
		if bool(band.get("embarked",false)) or band.get("pursuit") is Dictionary: continue
		if mc.command_hierarchy.battle.engaged(army_id) or mc._army_in_battle(army_id) or mc._besieging(army_id): continue
		if _at_home(band) and not mc.disband_field_army(army_id).has("error"): continue
		var index:int=mc._field_army_index(army_id)
		if index<0: continue
		mc.field_armies.remove_at(index)
		for pool in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","captured_pool"]:
			mc.home_army[pool]=int(mc.home_army.get(pool,0))+int(band.get(pool,0))
		mc._refresh_readiness()
		mc.army_changed.emit(mc.home_army.duplicate(true))

static func _and_list(items:Array)->String:
	if items.size()<=1: return "".join(PackedStringArray(items))
	return "%s and %s" % [", ".join(PackedStringArray(items.slice(0,items.size()-1))),String(items[-1])]

## Bands the council formed, home again, go back into the levy at home.
static func _tidy_home()->void:
	var mc:=_mc()
	for band in _council_bands():
		var c:Dictionary=band.council
		if String(c.get("phase",""))!="home" or bool(band.get("resting",false)): continue
		if not _at_home(band):
			# Rested and ready somewhere else (a town we hold): home now.
			var id:=int(band.get("army_id",0))
			if String(band.get("status",""))!="moving" and not mc.command_hierarchy.battle.engaged(id) and not mc._army_in_battle(id) and not mc._besieging(id): _send_home(band)
			continue
		var army_id:=int(band.get("army_id",0))
		if bool(c.get("formed",false)) and int(band.get("troops",0))>0:
			if not mc.disband_field_army(army_id).has("error"): continue
		var index:int=mc._field_army_index(army_id)
		if index>=0: mc.field_armies[index].erase("council")

## Once per people, on a save from before the council: a computer ruler's
## standing objective for its whole army (the old staff loop's home zone or
## campaign target) is lifted, so its bands answer to the council, and the
## bands it left idle at home rejoin the levy.
static func _old_orders_once(s:Dictionary)->void:
	if bool(s.get("lifted",false)): return
	s["lifted"]=true
	if _player(): return
	var mc:=_mc()
	var command:RefCounted=mc.command_hierarchy
	var order:Dictionary=command.order_for("army")
	if not order.is_empty() and String(order.get("mission",""))!="cancelled": command.cancel("army")
	for army in (mc.field_armies as Array).duplicate():
		if not army is Dictionary or (army as Dictionary).has("council"): continue
		if _at_home(army) and not bool((army as Dictionary).get("embarked",false)): mc.disband_field_army(int((army as Dictionary).get("army_id",0)))

static func _army(army_id:int)->Dictionary:
	var mc:=_mc()
	var index:int=mc._field_army_index(army_id)
	return {} if index<0 else mc.field_armies[index]

# --------------------------------------------------------------------------
# Forces, towns, odds, supply
# --------------------------------------------------------------------------

## Who can go: those at home, less the home guard (watch_military.gd).
static func _forces()->Dictionary:
	var mc:=_mc()
	var home:=maxi(0,int(mc.home_army.get("troops",0)))
	# The home guard stays (watch_military.gd): the ruler's split of the
	# watch guards home and the towns; the rest are for the bands.
	var keep:=mini(home,int(LAW.watch(mc).home))
	return {"home":home,"keep":keep,"free":maxi(0,home-keep),"formations":mc.home_army.get("formations",[]),"force":mc.home_army}

static func _free_men()->int:
	return int(_forces().free)

## Their towns we know and do not hold: {city_id, civ_id, name, position}.
static func known_towns(civ_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var world:Variant=WorldSimulation.world
	if world==null or not "city_intelligence" in world or world.city_intelligence==null: return out
	var ledger:GDScript=load(LEDGER_PATH) as GDScript if _player() else null
	for city:Dictionary in world.city_intelligence.known_cities("player",civ_id,false):
		var controller:=String(city.get("controller",city.get("civ_id","")))
		if controller in ["","player"] or controller!=civ_id: continue
		if ledger!=null and not (ledger.call("our_ruin",String(city.city_id)) as Dictionary).is_empty(): continue
		var name:=String(city.get("name","")).trim_prefix("Reported home of ")
		out.append({"city_id":String(city.city_id),"civ_id":civ_id,"name":name if name!="" else "their town","position":(city.get("position",{}) as Dictionary).duplicate(true)})
	return out

static func _town(civ_id:String,city_id:String,fallback_name:String="")->Dictionary:
	for town in known_towns(civ_id):
		if String(town.city_id)==city_id: return town
	var known:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	if known.is_empty(): return {}
	if _ours(civ_id,city_id): return {"city_id":city_id,"civ_id":civ_id,"name":fallback_name if fallback_name!="" else String(known.get("name","")),"position":(known.get("position",{}) as Dictionary).duplicate(true),"ours":true}
	return {}

static func _town_name(civ_id:String,city_id:String)->String:
	var known:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	var name:=String(known.get("name","")).trim_prefix("Reported home of ")
	if name=="": name=String(WorldSimulation.world.region_snapshot(civ_id,city_id).get("name",""))
	return name if name!="" else "the town"

## Is this town of theirs ours now (held by a garrison of ours, or ours on
## the world's own record)?
static func _ours(civ_id:String,city_id:String)->bool:
	var region:Dictionary=WorldSimulation.world.region_snapshot(civ_id,city_id)
	return String(region.get("controller",""))=="player"

## Their fighters as our scouts counted them (court_war_orders' reading,
## scoped to whoever asks).
static func _estimate(city_id:String)->Dictionary:
	return _orders().call("enemy_estimate",city_id)

## The odds a band of `going` from home would face at this town.
static func _odds_at(town:Dictionary,going:int,kind:String)->Dictionary:
	if going<=0: return {}
	var enemy:=_estimate(String(town.city_id))
	if not bool(enemy.get("known",false)): return {}
	var forces:=_forces()
	if Odds.heads(forces.formations)<=0: return {}
	var mid:=float(enemy.get("mid",0.0))*(0.72 if kind=="raid" else 1.0)
	return Odds.of(forces.force,forces.formations,going,mid,float(enemy.get("fortification",0.25)),Odds.their_arms(String(town.civ_id),int(enemy.get("age",-1))),String(town.civ_id),false,-1.0,float(enemy.get("untrained",0.0)))

## How the carriers would feed a band of `troops` at the town ({ratio,
## season, km, days} or {} when nobody can say). The god's people read the
## carriers' own reckoning (supply_state.gd); a computer ruler, the road's
## length against the food it has at home.
static func _fed_at(town:Dictionary,troops:int)->Dictionary:
	var at:=_v2(town.get("position",{}))
	if not at.is_finite() or troops<=0: return {}
	if _player():
		# The march's own reckoning (military_campaign march_supply): its
		# days, the share of the road lived off the land at half pace, and how
		# the band would be fed on the road and camped at the end, with the
		# carriers as they are today. The leaner of the two decides.
		var mc:=_mc()
		var home:Vector2=WorldSimulation.world.player_world_origin
		var probe:Dictionary=(mc.home_army as Dictionary).duplicate(false)
		probe["troops"]=troops
		probe["position"]={"x":home.x,"z":home.y}
		probe["status"]="moving"
		var route:Dictionary=mc.field_route(home,at,probe)
		if route.has("error"): return {}
		var march:Dictionary=mc.march_supply(probe,route)
		var road:=float(march.get("fed_on_road",1.0))
		var there:=float(march.get("fed_there",1.0))
		var land:Dictionary=Supply.land_at(Supply.rations_field(),at,_today())
		return {"ratio":minf(road,there),"on_road":road,"there":there,"days":float(march.get("days",0)),"half_pace":float(march.get("half_pace",0.0)),"km":float(route.get("length_km",0.0)),"season":"winter" if float(land.get("cold",0.0))>=0.3 else ""}
	var km:float=WorldSimulation.world.player_world_origin.distance_to(at)
	var food_days:=float(WorldSimulation.state.simulation_metrics.get("food_days",0.0))
	var road_days:=km/18.0
	var ratio:=clampf(food_days/maxf(1.0,road_days*4.0),0.0,1.0)*clampf(1.15-km/400.0,0.2,1.0)
	return {"ratio":ratio,"season":"","km":km,"days":road_days}

static func _hungry_road_words(town:Dictionary,fed:Dictionary)->String:
	var share:=roundi(float(fed.ratio)*100.0)
	var winter:=" in this cold" if String(fed.get("season",""))=="winter" else ""
	var where:=("camped at %s" if float(fed.get("there",1.0))<float(fed.get("on_road",1.0)) else "on the road to %s") % String(town.name)
	var how:=PackedStringArray()
	if float(fed.get("days",0.0))>=1.0: how.append("about %s on the road" % _span(roundi(float(fed.days))))
	if float(fed.get("half_pace",0.0))>=0.2: how.append("%s of it living off the land at half pace" % ("most" if float(fed.half_pace)>=0.6 else "part"))
	return "%s waits: %s the band would eat about %d%% of a ration%s%s. He will not march them out to go hungry." % [_who(),where,share,winter,(" ("+", ".join(how)+")") if not how.is_empty() else ""]

# --------------------------------------------------------------------------
# Sending a band
# --------------------------------------------------------------------------

## Sends a band on an errand at a town: the god's own through the war
## leader's spoken core (court_war_orders.strike: the same objections,
## numbers, Chronicle and report); every other people's straight through
## the engine. Both end in MilitaryCampaign.order_city_operation.
static func _launch(civ_id:String,town:Dictionary,act:String,insist:bool,options:Dictionary)->Dictionary:
	var raid:=act=="punish"
	var free:=_free_men()
	var odds:=_odds_at(town,free,"raid" if raid else "take")
	var besiege:bool=not raid and free>=SIEGE_MIN and (_mc().active_siege as Dictionary).is_empty() and (odds.is_empty() or float(odds.raw)<STORM_ODDS)
	# Everything they have (world_answer.gd): every free fighter goes as one band.
	var count:=(free if bool(options.get("all",false)) else _raid_size(town)) if raid else 0
	if _player(): return _launch_ours(civ_id,town,act,besiege,count,insist,options)
	return _launch_theirs(civ_id,town,act,besiege,count,insist,odds)

static func _launch_ours(civ_id:String,town:Dictionary,act:String,besiege:bool,count:int,insist:bool,options:Dictionary)->Dictionary:
	var wo:=_orders()
	var mc:=_mc()
	var before:={}
	for army in mc.field_armies: before[int((army as Dictionary).get("army_id",0))]=true
	var kind:="raid" if act=="punish" else ("siege" if besiege else "attack")
	var place:={"city_id":String(town.city_id),"civ_id":civ_id,"name":String(town.name),"civ_name":_name(civ_id),"controller":civ_id,"position":(town.get("position",{}) as Dictionary).duplicate(true)}
	# The god's own words in court, as read (a siege asked for, "with 17
	# troops", by night): the war leader goes as he was told.
	var given:Dictionary=options.get("reading",{}) if options.get("reading") is Dictionary else {}
	var reading:={"kind":kind,"target":place,"full":false,"insist":insist,"place":"","army_words":true,"text":String(options.get("words","")).substr(0,300)}
	if not given.is_empty():
		reading=given.duplicate(true)
		if not (reading.get("target",{}) as Dictionary).has("city_id"): reading["target"]=place
		reading["insist"]=insist or bool(given.get("insist",false))
	if count>0 and int(reading.get("count",0))<=0 and String(reading.get("kind",""))=="raid": reading["count"]=count
	var context:Dictionary=(options.get("context",{}) as Dictionary).duplicate() if options.get("context") is Dictionary else {}
	# A band the god picked that is broken, under strength or resting is not
	# sent: the war leader is resting and refilling it (band_upkeep.gd).
	var picked:=_army(int(context.get("army_id",0))) if int(context.get("army_id",0))>0 else {}
	if not picked.is_empty() and not _fit(picked):
		return _record(civ_id,"impossible","%s is not fit to go: %s. It rests and refills first." % [Logistics.force_name(picked),_unfit_words(picked)])
	# The general the god named to lead against them speaks and leads.
	if not context.has("general"):
		var lead:=_leader_ref(civ_id)
		if not lead.is_empty(): context["general"]=lead
	var answer:Dictionary=wo.call("strike",reading,insist,context)
	var verdict:=String(answer.get("verdict",""))
	var objective:Dictionary=answer.get("objective",{}) if answer.get("objective") is Dictionary else {}
	if verdict=="act" and int(objective.get("army_id",0))>0:
		var army_id:=int(objective.army_id)
		_tag(army_id,civ_id,act,town,answer.get("odds",{}) if answer.get("odds") is Dictionary else {},not before.has(army_id))
		answer["live"]=true
		return answer
	# The war leader's objection is his reason to wait, said in his words
	# (the court hears it as an objection the god can insist past).
	answer["live"]=false
	return answer

static func _launch_theirs(civ_id:String,town:Dictionary,act:String,besiege:bool,count:int,insist:bool,odds:Dictionary)->Dictionary:
	var mc:=_mc()
	var free:=_free_men()
	var going:=mini(free,count) if count>0 else free
	if going<MIN_BAND: return _record(civ_id,"wait","The war leader has too few free to send.")
	_battle_fields(civ_id)
	var want:=Odds.wanted("raid" if act=="punish" else "take")
	var reading:=_odds_at(town,going,"raid" if act=="punish" else "take") if count>0 else odds
	if not insist and not reading.is_empty() and float(reading.raw)<want:
		return _record(civ_id,"wait","The war leader waits for the odds: %s." % Odds.said(reading),{"odds":float(reading.raw)})
	var made:Dictionary=mc.create_field_army(going,("Raiders for %s" if act=="punish" else "Host for %s") % String(town.name))
	if made.has("error"): return _record(civ_id,"impossible",String(made.error))
	var army_id:=int((made.army as Dictionary).army_id)
	var order:Dictionary=mc.order_city_operation(army_id,civ_id,String(town.city_id),besiege,act=="punish")
	if order.has("error"):
		mc.disband_field_army(army_id)
		return _record(civ_id,"impossible",String(order.error))
	_tag(army_id,civ_id,act,town,reading,true)
	return _record(civ_id,"act","%d set out for %s." % [going,String(town.name)],{"live":true,"army_id":army_id,"days":int(order.get("days",0))})

# --------------------------------------------------------------------------
# Words for the War screen
# --------------------------------------------------------------------------

## What is happening with this people now, in one plain line: our band out
## ("Rovik besieges Oakford, day 12: odds 3 to 2, fed 80%"), their band
## coming ("Their band of 40 marches on Ashford, here in about 6 days"), the
## trackers or messengers out, or why the war leader waits.
static func operation_words(civ_id:String)->String:
	for band in bands_against(civ_id):
		var said:=band_words(band)
		if said!="": return said
	var f:=peek(civ_id)
	var coming:String=String(f.get("coming","")) if _today()-int(f.get("coming_day",-99999))<=LIVE_DAYS else ""
	if coming!="": return coming
	var op:=_loop_op(civ_id)
	if not op.is_empty():
		var left:=maxi(0,int(op.get("due",_today()))-_today())
		match String(op.get("objective","")):
			"war_track": return "%s's trackers follow their trail home, back in about %s" % [String(op.get("general",_who())),_span(left)]
			"war_parley": return "Our messengers are on their way to them, back in about %s" % _span(left)
	var says:=String(f.get("says",""))
	if says!="": return says.trim_suffix(".")
	return ""

## The longer account for the pointer: the band's numbers, the odds stated
## when it set out, how it is fed, and the stance in force.
static func operation_details(civ_id:String)->String:
	var parts:=PackedStringArray()
	for band in bands_against(civ_id):
		var c:Dictionary=band.council
		var line:=band_words(band)
		if line!="": parts.append(line)
		if c.has("odds") and not line.contains("odds"): parts.append("the odds when it set out were %s" % Odds.words(maxf(float(c.odds),1.0/maxf(0.01,float(c.odds))),float(c.odds)>=1.0))
	var f:=peek(civ_id)
	if String(f.get("says",""))!="" and parts.is_empty(): parts.append(String(f.says).trim_suffix("."))
	var stance:=stance_of(civ_id)
	if stance!="":
		var given:=chosen(civ_id)!=""
		parts.append(("stance: %s" if given else "no word from you, so: %s") % String({"leave":"leave them be","defend":"defend","punish":"punish","take":"take a town","peace":"seek peace"}.get(stance,stance)))
	return "; ".join(parts)+("." if not parts.is_empty() else "")

## One band on the council's errand in words.
static func band_words(band:Dictionary)->String:
	var mc:=_mc()
	var c:Dictionary=band.council
	var who:=_who(band)
	if bool(band.get("resting",false)):
		return "%s's band, %d of %d men, %s" % [who,int(band.get("troops",0)),Lines.full_strength(band),"pulls back to rest and refill" if String(band.get("status",""))=="moving" else "rests and refills"]
	var army_id:=int(band.get("army_id",0))
	var name:=String(c.get("name",""))
	var men:=int(band.get("troops",0))
	var odds_said:=""
	if c.has("odds"):
		var raw:=float(c.odds)
		odds_said="odds %s" % _odds_short(raw)
	var fed:=_fed_words(band)
	var told:=PackedStringArray()
	for part in [odds_said,fed]:
		if String(part)!="": told.append(String(part))
	var tail:=", ".join(told)
	if mc._besieging(army_id):
		return "%s besieges %s, day %d%s" % [who,name,maxi(1,int(mc.active_siege.get("days",0))),(": "+tail) if tail!="" else ""]
	if mc.command_hierarchy.battle.engaged(army_id) or mc._army_in_battle(army_id):
		return "%s is fighting %s with %s" % [who,("at "+name) if name!="" else "them",_fighters(men)]
	var days:=maxi(0,int(band.get("arrival_day",_today()))-_today())
	var moving:=String(band.get("status",""))=="moving"
	var homeward:=moving and String(band.get("destination_id",""))=="player_home"
	if homeward: return "%s's band comes home%s, %s" % [who,(" from "+name) if name!="" else "",("about %s out" % _span(days)) if days>0 else "nearly home"]
	match String(c.get("act","")):
		"take":
			if moving: return "%s marches on %s with %d, there in about %s%s" % [who,name,men,_span(days),(": "+tail) if tail!="" else ""]
			return "%s stands before %s with %d%s" % [who,name,men,(": "+tail) if tail!="" else ""]
		"punish":
			if moving: return "%s's raiders, %d of them, head for %s's fields and stores, there in about %s" % [who,men,name,_span(days)]
			return "%s's raiders are at %s" % [who,name]
		"intercept": return "%s goes out after %s with %d" % [who,name if name!="" else "their band",men]
		"reinforce": return "%d march to hold %s%s" % [men,name,(", there in about %s" % _span(days)) if moving and days>0 else ""]
	return ""

## How the band was fed on its last day, as the engine recorded its rations
## (military_campaign provision_ratio; cheap: no supply reckoning here).
static func _fed_words(band:Dictionary)->String:
	if not band.has("provision_ratio") and not band.has("supply_level"): return ""
	return "fed %d%%" % roundi(clampf(float(band.get("provision_ratio",band.get("supply_level",1.0))),0.0,1.0)*100.0)

## "3 to 2", "even", "2 to 3": ours over theirs in the screen's short form.
static func _odds_short(raw:float)->String:
	var ours:=raw>=1.0
	var odds:=raw if ours else 1.0/maxf(0.0001,raw)
	var s:=Odds.short(odds,ours)
	return s.replace(":"," to ").replace(">","more than ").replace("<","less than ")

static func _loop_op(civ_id:String)->Dictionary:
	if not _player(): return {}
	var f:Dictionary=_war_loop().call("_peek",civ_id)
	var op:Variant=f.get("op",{})
	if op is Dictionary and not (op as Dictionary).is_empty(): return op
	var war:Variant=f.get("war",{})
	if war is Dictionary and (war as Dictionary).get("op") is Dictionary: return (war as Dictionary).op
	return {}

static func _held_words(civ_id:String)->String:
	var parts:=PackedStringArray()
	for force in _mc().occupation_forces:
		if force is Dictionary and String((force as Dictionary).get("civ_id",""))==civ_id and int((force as Dictionary).get("troops",0))>0:
			parts.append("%d hold %s" % [int(force.troops),_town_name(civ_id,String(force.get("region_id","")))])
	return ", ".join(parts)

static func _nearest_town_name(at:Vector2)->String:
	var best:=String(WorldSimulation.state.settlement_name)
	var best_d:float=WorldSimulation.world.player_world_origin.distance_to(at)
	for city in WorldSimulation.state.player_settlements:
		if not city is Dictionary: continue
		var p:Variant=(city as Dictionary).get("position",null)
		var point:=(p as Vector2) if p is Vector2 else (_v2(p) if p is Dictionary else Vector2.INF)
		if point.is_finite() and point.distance_to(at)<best_d: best_d=point.distance_to(at); best=String((city as Dictionary).get("name",best))
	return best if best!="" else "home"

## Bands of theirs in sight coming at a town of ours, for the alerts:
## [{civ_id, source_name, target_region_name, estimated_strength, days}].
## As the council last saw them (at its sitting; nothing is reckoned here,
## so the screens may ask every second).
static func incoming()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if WorldSimulation.world==null: return out
	var today:=_today()
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary or not bool((civ as Dictionary).get("alive",true)): continue
		var id:=String((civ as Dictionary).get("id",""))
		if id=="" or id=="player": continue
		var f:=peek(id)
		if not f.get("coming_band") is Dictionary or today-int(f.get("coming_day",-99999))>LIVE_DAYS: continue
		var c:Dictionary=f.coming_band
		var days:=maxi(0,int(c.get("days",0))-(today-int(f.coming_day)))
		out.append({"civ_id":id,"source_name":"The %s band" % _name(id),"target_region_name":String(c.get("town","")),"estimated_strength":int(c.get("strength",0)),"days":days,"deadline_day":today+days})
	return out

# --------------------------------------------------------------------------
# Small words
# --------------------------------------------------------------------------

static func _fighters(n:int)->String:
	return "%s %s" % [EraWords.grouped(n),"fighter" if n==1 else "fighters"]

static func _span(days:int)->String:
	if days<=1: return "a day"
	if days<60: return "%d days" % days
	return "%d months" % roundi(float(days)/30.0)

static func _km_words(km:float)->String:
	if km<2.0: return "at the edge of"
	return "%s km" % EraWords.grouped(roundi(km))

static func _v2(p:Variant)->Vector2:
	if p is Vector2: return p
	if p is Dictionary and (p as Dictionary).has_all(["x","z"]): return Vector2(float(p.x),float(p.z))
	return Vector2.INF

static func _chronicle(key:String,title:String,text:String,civ_id:String)->void:
	preload("res://scripts/chronicle.gd").record({"key":"council:"+key,"title":title.substr(0,70),"text":text,"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
