extends RefCounted
## THE BUSINESS SECTOR (docs/BUSINESS_ARC.md, stage 1): one record per people,
## from household crafts to corporations, shaped by the god with one stance.
##
## The ladder: each rung is reached when its knowledge is held and the
## people's money allows it (RUNGS, RUNG_KNOWLEDGE). Knowledge once held is
## never lost to the ladder (`reached`); money can suspend rungs (coin lost:
## the rungs that need coin wait).
##
## Size: `share` is the share of the working people in private business. Each
## month it moves toward its target, rung_cap x stance reach x form reach x
## market x credit, a twelfth of the gap a year while growing and a quarter
## a year while shrinking (failures are fast, building is slow).
##
## What it does, each through an existing ledger (factor() is cached monthly,
## so a day costs one dictionary read):
##   work    the working efficiency (consequence_engine.gd) x factor(), its
##           1.12 ceiling raised by the same factor;
##   goods   civilian goods (civilian_goods.gd) and the making capacity
##           target (material_target) x factor();
##   reach   market access + share x TRADE_REACH (economy_system.gd);
##   wealth  where custom pulls the richest fifth back to rises toward the
##           age's ceiling by share x stance x form (economy_system.gd
##           _update_wealth_distribution, wealth_lift);
##   purse   charter fees (Chartered) or the state works' surplus (State
##           works): a share of the sector's output taken with the levy
##           (realm_purse.gd accrue), out of each town's own stores.
##
## Booms and busts: a seeded monthly roll (step()) against the odds stated
## on every screen at that moment (the boom included); a bust cuts the sector
## by a third, slows all work for 6 to 12 months, writes off debts through the
## credit ledger, takes 2 points from the richest fifth and 0.04 from holding
## together, and the Chronicle tells it once.
##
## The stance is Guarded until the god (or a computer ruler, by temperament)
## chooses another: no fee starts without a word. Each new rung is told once,
## with what each stance would do there.
##
## Every people keeps its own record in its own scope (WorldSimulation.state
## .enterprise) and steps it monthly from civilization_day.gd; computer
## rulers set the stance by temperament (civilization_controller.gd
## business_orders). Static; preload.

const Purse:=preload("res://scripts/realm_purse.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

const VERSION:=1
const MONTH_DAYS:=30
## The ladder: the words follow the age; cap is the most of the working
## people the rung can hold, gain what each worker in it adds to the work.
const RUNGS:=[
	{"name":"Household crafts","short":"Household","cap":0.0,"gain":0.0},
	{"name":"Stalls and hired workshops","short":"Stalls","cap":0.04,"gain":0.15},
	{"name":"Merchant houses and guilds","short":"Merchant houses","cap":0.10,"gain":0.25},
	{"name":"Banking houses and long-distance partnerships","short":"Banking houses","cap":0.16,"gain":0.32},
	{"name":"Chartered companies","short":"Companies","cap":0.28,"gain":0.42},
	{"name":"Corporations","short":"Corporations","cap":0.55,"gain":0.55},
]
## Knowledge a rung needs beyond the one below (any one of the list).
const RUNG_KNOWLEDGE:={
	2:["licensed_merchant_houses","large_owner_workshops","licensed_guilds","craft_guilds"],
	3:["bills_of_exchange","branch_banking_houses","voyage_partnerships","district_royal_banks"],
	4:["joint_stock_company"],
	5:["limited_liability_registration"],
}
## From this rung on, the sector needs coin; below it, weighed metal or coin.
const COIN_RUNG:=3
## Short plain names of the knowledge a rung needs (the research titles are long).
const KNOWLEDGE_WORDS:={
	"licensed_merchant_houses":"licensed merchant houses","large_owner_workshops":"large owner workshops",
	"licensed_guilds":"licensed craft associations","craft_guilds":"craft guilds",
	"bills_of_exchange":"bills of exchange","branch_banking_houses":"banking houses with branches",
	"voyage_partnerships":"voyage partnerships","district_royal_banks":"district royal banks",
	"joint_stock_company":"joint-stock companies","limited_liability_registration":"limited liability",
	"nationalized_core_industries":"core industries in state hands",
}
## Busts a month by rung, before the stance, the form and banking. At
## corporations: Open on heavy credit about 1 in 23 years, Open about 1 in 35,
## Guarded about 1 in 74 on heavy credit and 1 in 110 without (the design's
## benchmark: open commercial economies roughly 1 in 20-40, guarded rarely).
const BUST_BASE:=[0.0,0.0003,0.0006,0.0009,0.0012,0.0015]
## Knowledge that keeps honest books cuts the odds of a bust, at most this much.
const BANKING:=["double_entry_ledgers","audited_company_accounts","chartered_central_bank"]
const BANKING_CUT:=0.4
## The god's lever, one at a time, set like the levy.
const STANCES:=["guarded","chartered","open","state"]
const STANCE:={
	"guarded":{"name":"Guarded","reach":0.75,"gain":0.95,"wealth":0.5,"bust":0.5,"purse":0.0},
	"chartered":{"name":"Chartered","reach":0.9,"gain":1.0,"wealth":1.3,"bust":1.0,"purse":1.0/20.0},
	"open":{"name":"Open","reach":1.0,"gain":1.15,"wealth":1.5,"bust":1.6,"purse":0.0},
	"state":{"name":"State works","reach":0.8,"gain":0.85,"wealth":0.3,"bust":0.2,"purse":1.0/10.0,"needs":"nationalized_core_industries"},
}
## The form of organized production the people's values chose
## (societal_values_model.gd "craft_guilds" variants).
const FORMS:={
	"mutual_associations":{"name":"Mutual craft associations","reach":1.0,"gain":0.95,"wealth":0.6,"bust":0.8},
	"licensed_guilds":{"name":"Licensed guilds","reach":0.85,"gain":1.0,"wealth":1.0,"bust":1.0},
	"open_professions":{"name":"Open professions","reach":1.1,"gain":1.08,"wealth":1.2,"bust":1.15},
}
const NO_FORM:={"name":"","reach":1.0,"gain":1.0,"wealth":1.0,"bust":1.0}
## Growth a year as a share of the gap to the target; shrinking a year.
const GROW_YEAR:=1.0/12.0
const SHRINK_YEAR:=0.25
## Older saves start at this share of their rung's target.
const OLDER_SAVE_START:=0.4
## Market access added per share of the workers in business.
const TRADE_REACH:=0.3
## Before credit is kept the credit term is this; after, 0.7 + 0.3 x free credit.
const NO_CREDIT:=0.85
## A boom: the sector well short of its target (target above share x
## BOOM_GAP) while more than half the credit is used; work +2%. The months
## of a boom raise the odds of a bust, counted up to BOOM_MONTHS_MAX (at most
## half again). A bust ends the boom: none comes again until the share has
## regrown to within BOOM_GAP of where it stood (BOOM_HOLD_DAYS at most), so
## a sector that keeps failing is not forever booming.
const BOOM_CREDIT:=0.5
const BOOM_GAP:=1.05
const BOOM_GAIN:=0.02
const BOOM_ODDS_MONTHS:=24.0
const BOOM_MONTHS_MAX:=12
const BOOM_HOLD_DAYS:=365
## A computer ruler weighs the stance again at most once a year.
const RULER_REVIEW_DAYS:=365
## A bust: a third of the sector fails at once; all work -4% for 6 to 12
## months, easing; the failed third's debts are written off (the sector holds
## recorded credit at twice its share of the workers, at most 90 in 100); the
## richest fifth lose 2 points; holding together -0.04.
const BUST_CUT:=1.0/3.0
const BUST_HIT:=0.04
const BUST_MONTHS_MIN:=6
const BUST_MONTHS_MAX:=12
const BUST_CREDIT_SHARE:=2.0
const BUST_CREDIT_MAX:=0.9
const BUST_RICH:=0.02
const BUST_COHESION:=0.04
## Changing the stance costs trust in the chiefs (legitimacy), told once.
const CHANGE_TRUST:=0.02
const HISTORY_LIMIT:=12


# --- The record ------------------------------------------------------------------

static func _fresh()->Dictionary:
	return {"version":VERSION,"share":0.0,"target":0.0,"reached":0,"stance":"","chosen":false,"factor":1.0,"wealth":0.0,
		"last_day":-1,"boom_months":0,"bust":{},"busts":0,"last_roll":{},"history":[],"told_rung":0,"ruler_day":-1,"boom_hold":{}}

## This people's record, made whole. An older save (or a new world) starts at
## the rung its knowledge allows, with share at OLDER_SAVE_START of that
## rung's target: it grows into it, with no sudden jump. Read at the realm's
## own level; inside a town's day the record is returned as it stands.
static func state()->Dictionary:
	var s=WorldSimulation.state
	var e:Dictionary=s.enterprise
	if String(s.resource_settlement_id)!="":return e
	if int(e.get("version",0))!=VERSION:
		var first:=not e.has("share")
		var fresh:=_fresh()
		for key in fresh:
			if not e.has(key):e[key]=fresh[key]
		e["version"]=VERSION
		if first:
			e.reached=knowledge_rung()
			e.target=target()
			e.share=float(e.target)*OLDER_SAVE_START
			_refresh(e)
	return e

## The raw record (never made whole), for the daily readers.
static func _raw()->Dictionary:
	return WorldSimulation.state.enterprise

static func share()->float:
	return clampf(float(_raw().get("share",0.0)),0.0,1.0)


# --- The ladder ------------------------------------------------------------------

static func held(id:String)->bool:
	return id in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption(id)>=0.25

static func _any_held(ids:Array)->bool:
	for id in ids:
		if held(String(id)):return true
	return false

## The highest rung the people's knowledge reaches (money aside).
static func knowledge_rung()->int:
	var r:=1
	for rung in [2,3,4,5]:
		if not _any_held(RUNG_KNOWLEDGE[rung]):break
		r=rung
	return r

## Prices kept: the people trade at recorded comparison values.
static func prices_kept()->bool:
	return int(WorldSimulation.state.economy_metrics.get("price_observations",0))>0

## The highest rung the people's money allows: none without weighed metal or
## coin and kept prices; below COIN_RUNG with weighed metal only.
static func money_cap()->int:
	var stage:=String(WorldSimulation.state.economy_stage)
	if not prices_kept():return 0
	if stage=="currency":return RUNGS.size()-1
	if stage=="weighed_metal":return COIN_RUNG-1
	return 0

## The rung the people stand on now.
static func rung()->int:
	var e:=_raw()
	var known:=maxi(int(e.get("reached",0)),knowledge_rung())
	return clampi(mini(known,money_cap()),0,RUNGS.size()-1)

static func rung_name(r:int)->String:
	return String((RUNGS[clampi(r,0,RUNGS.size()-1)] as Dictionary).name)

## What the next rung needs, in plain words ("" at the top). Short: one
## piece of knowledge named "or the like", for a screen's label.
static func next_needs(short:=false)->String:
	var r:=rung()
	if r>=RUNGS.size()-1:return ""
	var next:=r+1
	var parts:PackedStringArray=[]
	if next==1 or money_cap()<next:
		if next>=COIN_RUNG and String(WorldSimulation.state.economy_stage)!="currency":parts.append("coin")
		elif next<COIN_RUNG and not String(WorldSimulation.state.economy_stage) in ["weighed_metal","currency"]:parts.append("weighed metal or coin")
		if not prices_kept():parts.append("prices kept")
	var known:=maxi(int(_raw().get("reached",0)),knowledge_rung())
	if known<next and RUNG_KNOWLEDGE.has(next):
		var words:PackedStringArray=[]
		for id in RUNG_KNOWLEDGE[next]:words.append(String(KNOWLEDGE_WORDS.get(String(id),String(id))))
		if short:parts.append(words[0]+(" or the like" if words.size()>1 else ""))
		else:parts.append(("one of " if words.size()>1 else "")+_or_list(words))
	return " and ".join(parts)

static func _or_list(words:PackedStringArray)->String:
	if words.size()<=1:return "".join(words)
	return ", ".join(words.slice(0,words.size()-1))+" or "+words[words.size()-1]


# --- The form and the stance ------------------------------------------------------

## The values-chosen form of organized production ("" before craft guilds).
static func form()->String:
	var values:Variant=WorldSimulation.state.societal_values
	if not values is Dictionary:return ""
	var institutions:Variant=(values as Dictionary).get("institutions",{})
	if not institutions is Dictionary:return ""
	var record:Variant=(institutions as Dictionary).get("craft_guilds",{})
	if not record is Dictionary:return ""
	var variant:=String((record as Dictionary).get("variant",""))
	return variant if FORMS.has(variant) else ""

static func _form_numbers()->Dictionary:
	return FORMS.get(form(),NO_FORM)

## Guarded at every rung until a stance is chosen: fees never start unasked.
static func default_stance(_r:int)->String:
	return "guarded"

## The stance in force: the god's (or the ruler's) word, else the default.
static func stance()->String:
	var e:=_raw()
	var chosen:=String(e.get("stance",""))
	if bool(e.get("chosen",false)) and STANCE.has(chosen):return chosen
	return default_stance(rung())

static func stance_name(id:String)->String:
	return String((STANCE.get(id,{}) as Dictionary).get("name",id))

## Whether the stance can be set now (State works needs its knowledge).
static func available(id:String)->bool:
	if not STANCE.has(id):return false
	var needs:=String((STANCE[id] as Dictionary).get("needs",""))
	return needs=="" or held(needs)

## The stances the god can choose now, in order.
static func choices()->Array:
	return STANCES.filter(func(id:String)->bool:return available(id))

## The stance in plain words, by what the people know.
static func stance_words(id:String)->String:
	var tags:=_tags()
	match id:
		"guarded":return ("Guilds and rules: steady and fair, slower" if tags.has("institutions") else "Old custom and rules: steady and fair, slower")
		"chartered":return ("You grant charters for a fee: favoured trades grow fast, wealth gathers" if tags.has("writing") else "You sell the right to trade: favoured trades grow fast, wealth gathers")
		"open":return "Free trade and enterprise: fastest growth, more inequality, booms and busts"
		"state":return "The state runs the great works"
	return ""

## The people's era tags (character_voice.gd), read once a day per people.
static var _tags_key:=""
static var _tags_value:Array=[]
static func _tags()->Array:
	var owner:=WorldSimulation.actor_id if WorldSimulation.actor_id!="" else "player"
	var key:="%s|%d|%d" % [owner,int(WorldSimulation.state.elapsed_days),(WorldSimulation.state.known_discoveries as Array).size()]
	if key==_tags_key:return _tags_value
	var voice:=load("res://scripts/character_voice.gd") as GDScript
	_tags_value=voice.call("era_tags",owner) if voice!=null else []
	_tags_key=key
	return _tags_value


# --- Size ---------------------------------------------------------------------------

## The market term of the target: market access, held between 0.3 and 1.
static func market_term()->float:
	return clampf(float(WorldSimulation.state.economy_metrics.get("market_access",0.0)),0.3,1.0)

## The share of recorded credit in use (0 before credit is kept).
static func credit_used()->float:
	var m:Dictionary=WorldSimulation.state.economy_metrics
	if float(m.get("credit_limit",0.0))<=0.0:return 0.0
	return clampf(float(m.get("credit_utilization",0.0)),0.0,1.0)

## The credit term: 0.7 + 0.3 x the credit still free under its ceiling;
## NO_CREDIT before credit is kept.
static func credit_term()->float:
	var m:Dictionary=WorldSimulation.state.economy_metrics
	if float(m.get("credit_limit",0.0))<=0.0:return NO_CREDIT
	return 0.7+0.3*(1.0-credit_used())

## The share the sector heads for under a stance (the one in force by
## default): rung_cap x stance reach x form reach x market x credit, never
## past what the rung can hold.
static func target(with_stance:String="")->float:
	var r:=rung()
	if r<=0:return 0.0
	var id:=with_stance if STANCE.has(with_stance) else stance()
	var cap:=float((RUNGS[r] as Dictionary).cap)
	var reach:=float((STANCE[id] as Dictionary).reach)*float(_form_numbers().reach)
	return clampf(cap*reach*market_term()*credit_term(),0.0,cap)


# --- What it does -----------------------------------------------------------------

## The work factor at a share under a stance, before a boom or a bust:
## 1 + share x gain x form x stance gain.
static func productivity(at_share:float,with_stance:String="",at_rung:int=-1)->float:
	var r:=rung() if at_rung<0 else at_rung
	var id:=with_stance if STANCE.has(with_stance) else stance()
	return 1.0+maxf(0.0,at_share)*float((RUNGS[clampi(r,0,RUNGS.size()-1)] as Dictionary).gain)*float(_form_numbers().gain)*float((STANCE[id] as Dictionary).gain)

## Today's factor on all work and goods (cached at the monthly step and when
## the stance changes): the sector's gain, a boom's +2%, a bust's easing cut.
static func factor()->float:
	return float(_raw().get("factor",1.0))

## Market access the sector adds (economy_system.gd _market_access).
static func market_bonus()->float:
	return share()*TRADE_REACH

## Where custom pulls the richest fifth back to rises toward the age's
## ceiling, by share x stance x form of the room between (economy_system.gd
## _update_wealth_distribution). `bounds` is [floor, ceiling, ordinary].
static func wealth_lift(bounds:Array)->float:
	var pull:=float(_raw().get("wealth",0.0))
	if pull<=0.0 or bounds.size()<3:return 0.0
	return maxf(0.0,float(bounds[1])-float(bounds[2]))*clampf(pull,0.0,1.0)

static func _wealth_pull(at_share:float,id:String)->float:
	return maxf(0.0,at_share)*float((STANCE[id] as Dictionary).wealth)*float(_form_numbers().wealth)

static var _bounds_cache:Dictionary={}
static func _bounds()->Array:
	if _bounds_cache.is_empty():
		var economy:=load("res://scripts/economy_system.gd") as GDScript
		_bounds_cache=economy.get_script_constant_map().get("WEALTH_BOUNDS",{}) if economy!=null else {}
	return _bounds_cache.get(String(WorldSimulation.state.economy_stage),[0.28,0.55,0.38])

## The share of the sector's output the purse takes with the levy now:
## charter fees (Chartered), the state works' surplus (State works), else 0.
static func purse_rate()->float:
	var e:=_raw()
	if float(e.get("share",0.0))<=0.0:return 0.0
	return float((STANCE.get(String(e.get("in_force","")),{}) as Dictionary).get("purse",0.0))

## What the purse takes from the sector's output by the stance, in words.
static func purse_name(id:String="")->String:
	var at:=id if id!="" else stance()
	return "The state works" if at=="state" else "Charter fees"

static func _refresh(e:Dictionary)->void:
	var r:=rung()
	var id:=stance()
	var f:=productivity(float(e.get("share",0.0)),id,r)
	if int(e.get("boom_months",0))>0:f*=1.0+BOOM_GAIN
	var bust:Dictionary=e.get("bust",{}) if e.get("bust") is Dictionary else {}
	if int(bust.get("left",0))>0:f*=1.0-BUST_HIT*float(bust.left)/maxf(1.0,float(bust.get("months",1)))
	e["factor"]=f
	e["wealth"]=_wealth_pull(float(e.get("share",0.0)),id)
	# The stance in force, for the daily readers (the levy's charter fees).
	e["in_force"]=id


# --- Booms and busts -----------------------------------------------------------------

## The banking cut on bust odds: 0.4 x the best adoption of honest books.
static func banking()->float:
	var best:=0.0
	for id in BANKING:
		if String(id) in WorldSimulation.state.known_discoveries:best=maxf(best,WorldSimulation.discovery.adoption(String(id)))
	return BANKING_CUT*clampf(best,0.0,1.0)

## A month's odds of a bust: base x stance x form x (1 - banking) x (1 +
## boom months / 24).
static func bust_month(with_stance:String="",boom_months:int=-1)->float:
	var r:=rung()
	if r<=0:return 0.0
	var id:=with_stance if STANCE.has(with_stance) else stance()
	var months:=clampi(int(_raw().get("boom_months",0)) if boom_months<0 else boom_months,0,BOOM_MONTHS_MAX)
	return float(BUST_BASE[r])*float((STANCE[id] as Dictionary).bust)*float(_form_numbers().bust)*(1.0-banking())*(1.0+float(months)/BOOM_ODDS_MONTHS)

## A year's odds: 1 - (1 - p)^12.
static func bust_year(with_stance:String="",boom_months:int=-1)->float:
	return 1.0-pow(1.0-clampf(bust_month(with_stance,boom_months),0.0,1.0),12.0)

## "About 1 in 40 years".
static func odds_words(year:float)->String:
	if year<=0.0:return "No busts"
	var n:=roundi(1.0/year)
	if n<=1:return "Most years"
	return "About 1 in %s years" % EraWords.grouped(n)

static func booming()->bool:
	return int(_raw().get("boom_months",0))>0

static func bust_left()->int:
	var bust:Variant=_raw().get("bust",{})
	return int((bust as Dictionary).get("left",0)) if bust is Dictionary else 0

## Test seam: when 0 or more, stands in for the month's seeded roll
## (tests/test_enterprise.gd). Never set by the game.
static var forced_roll:=-1.0

static func _rng(day:int)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:enterprise:%s:%d" % [int(WorldSimulation.state.world_seed),WorldSimulation.actor_id,floori(float(day)/MONTH_DAYS)])
	return rng


# --- The month ------------------------------------------------------------------------

## Once a month (civilization_day.gd "enterprise" step; at once on other days
## and inside a town's day): the rung is read again (a new one told once), a
## bust eases, one seeded roll is made against the odds stated all month (the
## boom as it stood), the share moves toward its target and a boom is
## counted. A step over part of a month (the first after a load) rolls only
## that part. Returns the month's report, or {}.
static func step(day:int)->Dictionary:
	var s=WorldSimulation.state
	if String(s.resource_settlement_id)!="":return {}
	var e:=state()
	var last:=int(e.get("last_day",-1))
	if last<0 or last>day:
		e.last_day=day
		_refresh(e)
		return {}
	if floori(float(day)/MONTH_DAYS)<=floori(float(last)/MONTH_DAYS):return {}
	var elapsed:=float(clampi(day-last,1,365))
	var months_part:=minf(12.0,elapsed/MONTH_DAYS)
	var months:=maxi(1,roundi(months_part))
	var years:=elapsed/365.0
	e.last_day=day
	e.reached=maxi(int(e.get("reached",0)),knowledge_rung())
	var r:=rung()
	if r>=1 and r>int(e.get("told_rung",0)):
		e.told_rung=r
		_tell_rung(r)
	# A bust under way eases with the months gone by.
	var bust:Dictionary=e.get("bust",{}) if e.get("bust") is Dictionary else {}
	if int(bust.get("left",0))>0:
		bust.left=maxi(0,int(bust.left)-months)
		if int(bust.left)<=0:e.bust={}
	# The month's roll, against the odds the screens stated all month.
	var before:=float(e.share)
	var report:={"day":day,"rung":r}
	var busted:=false
	if r>=1 and before>0.0:
		var p:=1.0-pow(1.0-clampf(bust_month(),0.0,1.0),months_part)
		var roll:=_rng(day).randf() if forced_roll<0.0 else forced_roll
		e.last_roll={"day":day,"p":p,"roll":roll,"months":months_part}
		report["p"]=p;report["roll"]=roll
		busted=roll<p
	# The share moves toward its target over the time gone by.
	var goal:=target()
	e.target=goal
	var now:=before
	if goal>before:now+=(goal-before)*(1.0-pow(1.0-GROW_YEAR,years))
	else:now-=(before-goal)*(1.0-pow(1.0-SHRINK_YEAR,years))
	e.share=clampf(now,0.0,1.0)
	# A boom: well short of its target, on credit more than half used; never
	# while a bust's hold lasts (until the share has regrown to within
	# BOOM_GAP of where it stood, or BOOM_HOLD_DAYS have passed).
	var hold:Dictionary=e.get("boom_hold",{}) if e.get("boom_hold") is Dictionary else {}
	if not hold.is_empty() and (float(e.share)*BOOM_GAP>=float(hold.get("share",0.0)) or day-int(hold.get("day",day))>=BOOM_HOLD_DAYS):
		hold={}
		e.boom_hold={}
	var booming_now:=hold.is_empty() and r>=1 and goal>before*BOOM_GAP and goal>0.0 and credit_used()>BOOM_CREDIT
	e.boom_months=mini(BOOM_MONTHS_MAX,int(e.get("boom_months",0))+months) if booming_now else 0
	if busted:report["bust"]=bust_now(day)
	report.merge({"share":float(e.share),"target":goal,"boom_months":int(e.boom_months)},true)
	_refresh(e)
	return report

## A bust, now (the month's roll, or a test). Each effect goes through its
## own ledger, once: the sector shrinks by a third; all work is slowed for 6
## to 12 months (seeded), easing; the failed third's debts are written off
## in each town's credit ledger; the richest fifth lose BUST_RICH of the
## wealth; holding together falls BUST_COHESION in every town. The Chronicle
## tells it once. Returns what was done.
static func bust_now(day:int)->Dictionary:
	var s=WorldSimulation.state
	var e:=state()
	var r:=rung()
	var before:=float(e.share)
	var cut:=before*BUST_CUT
	e.share=before-cut
	var months:=_rng(day+7).randi_range(BUST_MONTHS_MIN,BUST_MONTHS_MAX)
	e.bust={"day":day,"months":months,"left":months,"rung":r}
	# A bust ends the boom, and holds off the next until the sector regrows.
	e.boom_months=0
	e.boom_hold={"day":day,"share":before}
	e.busts=int(e.get("busts",0))+1
	# The failed third's debts, through each town's own credit ledger.
	var fraction:=minf(BUST_CREDIT_MAX,before*BUST_CREDIT_SHARE)*BUST_CUT
	var defaulted:=0.0
	for id in _places():
		defaulted+=float(WorldSimulation.settlements.with_city_resources(String(id),func()->float:return _write_off(fraction)) if String(id)!="" else _write_off(fraction))
	# The richest fifth lose what their houses held; the rest is shared out.
	var shares:Array=s.wealth_shares
	var rich_lost:=0.0
	if shares.size()==5:
		var bounds:=_bounds()
		var floor_share:=float(bounds[0]) if bounds.size()>0 else 0.28
		rich_lost=clampf(float(shares[4])-floor_share,0.0,BUST_RICH)
		if rich_lost>0.0:
			var others:=0.0
			for i in 4:others+=float(shares[i])
			for i in 4:shares[i]=float(shares[i])+rich_lost*float(shares[i])/maxf(0.0001,others)
			shares[4]=float(shares[4])-rich_lost
	_hearts(-BUST_COHESION,0.0)
	e.bust["defaulted"]=defaulted
	e.bust["cut"]=cut
	e.bust["rich"]=rich_lost
	var history:Array=e.history
	history.push_front({"day":day,"kind":"bust","rung":r,"cut":cut,"months":months,"defaulted":defaulted})
	if history.size()>HISTORY_LIMIT:history.resize(HISTORY_LIMIT)
	_refresh(e)
	var said:={"day":day,"rung":r,"cut":cut,"share_before":before,"share":float(e.share),"months":months,"defaulted":defaulted,"rich":rich_lost,"cohesion":BUST_COHESION}
	_tell_bust(said)
	return said

## Our towns' ids for a realm-wide act ("" is the capital), live ones only.
static func _places()->Array:
	var out:Array=[""]
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty() or String(city.get("status",""))=="abandoned":continue
		if not city.get("local_resources") is Dictionary or (city.local_resources as Dictionary).is_empty():continue
		out.append(String(city.get("id","")))
	return out

## Writes off `fraction` of this place's recorded credit through its ledger.
static func _write_off(fraction:float)->float:
	var s=WorldSimulation.state
	var lost:=maxf(0.0,float(s.credit_outstanding))*clampf(fraction,0.0,1.0)
	if lost<=0.0:return 0.0
	s.credit_outstanding=float(s.credit_outstanding)-lost
	s.credit_defaulted=float(s.credit_defaulted)+lost
	if WorldSimulation.economy!=null and WorldSimulation.economy.has_method("_ledger"):
		WorldSimulation.economy._ledger("credit_default",lost,"debtors","creditors","Business failures")
	return lost

## Holding together (cohesion) and trust in the chiefs (legitimacy) moved in
## every town of ours, through each town's own reading.
static func _hearts(cohesion:float,legitimacy:float)->void:
	for id in _places():
		var apply:=func()->void:
			var m:Dictionary=WorldSimulation.state.simulation_metrics
			if cohesion!=0.0:m["cohesion"]=clampf(float(m.get("cohesion",0.58))+cohesion,0.01,0.99)
			if legitimacy!=0.0:m["legitimacy"]=clampf(float(m.get("legitimacy",0.62))+legitimacy,0.01,0.99)
		if String(id)=="":apply.call()
		else:WorldSimulation.settlements.with_city_resources(String(id),apply)

## The Chronicle tells a bust once, for the god's own people only.
static func _tell_bust(b:Dictionary)->void:
	if WorldSimulation.actor_id!="player":return
	var chronicle:=load("res://scripts/chronicle.gd") as GDScript
	if chronicle==null:return
	var who:=_failed_words(int(b.rung))
	var home:=String(WorldSimulation.state.settlement_name)
	var text:="%s of %s failed one after another. A third of those in business lost their work; all work goes about %d%% slower for %d months, easing." % [_cap(who),home if home!="" else "our towns",roundi(BUST_HIT*100.0),int(b.months)]
	if float(b.defaulted)>=0.5:text+=" Debts of %s were written off." % Purse.number(float(b.defaulted))
	if float(b.rich)>0.0005:text+=" The richest fifth lost %d parts in 100 of the wealth." % maxi(1,roundi(float(b.rich)*100.0))
	text+=" The people hold together less."
	chronicle.call("record",{"title":"The %s fail" % _plain_failed(int(b.rung)),"text":text,"tier":"notice","kind":"economy","key":"business_bust_%d" % int(b.day),"action":{"kind":"section","section":"economy","sub":2}})
	Purse._note(Purse.state(),0.0,"Business failures: a third of the sector failed","bust")

## A new rung, told once to the god's own people, with what each stance
## would do there (the Chronicle, and a line in the purse's record).
static func _tell_rung(r:int)->void:
	if WorldSimulation.actor_id!="player":return
	var chronicle:=load("res://scripts/chronicle.gd") as GDScript
	var home:=String(WorldSimulation.state.settlement_name)
	var now:=stance()
	var parts:PackedStringArray=[]
	for id in choices():
		var q:=quote(String(id))
		var fee:=(", %s about %s a season once grown" % [String(q.purse_name).to_lower(),Purse.amount_text(float(q.purse_season))]) if float(q.purse_season)>=0.5 else ""
		parts.append("%s: up to %s of the workers, work %s%s, busts %s" % [stance_name(String(id)),in_100(float(q.target)),percent(float(q.work)),fee,String(q.odds).to_lower()])
	var opening:="%s now trade in %s." % [_cap(_who_words(r)),home if home!="" else "our towns"]
	if r==2:opening+=" Charters are now possible; nothing is charged until you choose."
	var text:="%s %s. The stance stays %s until you choose another." % [opening,"; ".join(parts),stance_name(now).to_lower()]
	if chronicle!=null:chronicle.call("record",{"title":rung_name(r),"text":text,"tier":"notice","kind":"economy","key":"business_rung_%d" % r,"action":{"kind":"section","section":"economy","sub":2}})
	Purse._note(Purse.state(),0.0,"%s now trade among us" % _cap(_who_words(r)),"business_rung")

static func _who_words(r:int)->String:
	match r:
		1:return "stalls and hired workshops"
		2:return "merchant houses and guilds"
		3:return "banking houses and long-distance partnerships"
		4:return "chartered companies"
		5:return "corporations"
	return "traders"

static func _failed_words(r:int)->String:
	match r:
		1:return "the stalls and hired workshops"
		2:return "the great merchant houses"
		3:return "the banking houses"
		4:return "the chartered companies"
		5:return "the great corporations"
	return "the traders"

static func _plain_failed(r:int)->String:
	match r:
		1:return "stalls and workshops"
		2:return "merchant houses"
		3:return "banking houses"
		4:return "companies"
		5:return "corporations"
	return "traders"

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)


# --- The ruler's lever ------------------------------------------------------------------

## Sets the stance: {ok, changed, stance, before, trust, quote}, or {ok:false,
## error}. A change costs CHANGE_TRUST of trust in the chiefs in every town,
## once business exists; the purse's record says it once.
static func set_stance(id:String)->Dictionary:
	var key:=id.strip_edges().to_lower()
	if not STANCE.has(key):return {"ok":false,"error":"The stance is Guarded, Chartered, Open or State works."}
	if not available(key):return {"ok":false,"error":"The state cannot run the works until %s are known." % String(KNOWLEDGE_WORDS.nationalized_core_industries)}
	var e:=state()
	var before:=stance()
	var changed:=before!=key
	e.stance=key
	e.chosen=true
	var trust:=0.0
	if changed:
		if rung()>=1:
			trust=CHANGE_TRUST
			_hearts(0.0,-CHANGE_TRUST)
		Purse._note(Purse.state(),0.0,"Business is %s now%s" % [stance_name(key).to_lower(),(": trust %d points lower for the change" % roundi(trust*100.0)) if trust>0.0 else ""],"business")
	e.target=target()
	_refresh(e)
	return {"ok":true,"changed":changed,"stance":key,"before":before,"trust":trust,"quote":quote(key)}

## A computer ruler's or a screen's order: {kind:"business", stance}.
static func order(o:Dictionary)->Dictionary:
	var result:=set_stance(String(o.get("stance","")))
	if not bool(result.get("ok",false)):return {"error":String(result.get("error",""))}
	return result

## Whether a computer ruler weighs the stance again today: once a year, so
## a war's start or end does not flip it month by month.
static func ruler_due(day:int)->bool:
	var at:=int(_raw().get("ruler_day",-1))
	return at<0 or day<at or day-at>=RULER_REVIEW_DAYS

static func ruler_reviewed(day:int)->void:
	state()["ruler_day"]=day

## A computer ruler's stance by temperament: assertive and disciplined →
## Chartered, open-minded → Open, empathetic → Guarded. A ruler at war never
## chooses Open.
static func ruler_stance(personality:Dictionary,at_war:bool)->String:
	var assertive:=float(personality.get("assertiveness",0.5))
	var discipline:=float(personality.get("discipline",0.5))
	var empathy:=float(personality.get("empathy",0.5))
	var open:=float(personality.get("openness",0.5))
	var scores:={"chartered":(assertive+discipline)*0.5,"open":open,"guarded":empathy}
	if at_war:scores.erase("open")
	var best:="guarded"
	var high:=-INF
	for id in ["guarded","chartered","open"]:
		if scores.has(id) and float(scores[id])>high:high=float(scores[id]);best=id
	return best


# --- Reading it -----------------------------------------------------------------------

## A stance as the engine would run it now, at the share it heads for:
## {stance, name, words, target, work, goods, trade, rich, bust_year, odds,
## purse, purse_name, purse_now, purse_season}. work and goods are factors - 1;
## the bust odds are this month's (a boom included), as the roll takes them;
## purse_now is a season's fee at today's size, purse_season once grown.
static func quote(id:String)->Dictionary:
	var key:=id if STANCE.has(id) else stance()
	var goal:=target(key)
	var r:=rung()
	var work:=productivity(goal,key,r)-1.0
	var bounds:=_bounds()
	var rich:=maxf(0.0,float(bounds[1])-float(bounds[2]))*clampf(_wealth_pull(goal,key),0.0,1.0) if bounds.size()>=3 else 0.0
	# The odds as the month's roll takes them now, a boom under way included.
	var year:=bust_year(key)
	var purse:=float((STANCE[key] as Dictionary).get("purse",0.0))
	var per_share:=Purse.output_per_day()*purse*Purse.reach()*Purse.SEASON_DAYS if purse>0.0 else 0.0
	return {"stance":key,"name":stance_name(key),"words":stance_words(key),"target":goal,"work":work,"goods":work,"trade":goal*TRADE_REACH,"rich":rich,
		"bust_year":year,"odds":odds_words(year),"purse":purse,"purse_name":purse_name(key),"purse_now":per_share*share(),"purse_season":per_share*goal}

## What the sector does now, at its share today: {work, goods, trade, rich}
## (work and goods as factors - 1, trade in market-access points, rich in
## the richest fifth's share).
static func effects()->Dictionary:
	var e:=_raw()
	var work:=factor()-1.0
	return {"work":work,"goods":work,"trade":market_bonus(),"rich":wealth_lift(_bounds()),"share":share(),"target":float(e.get("target",0.0))}

## "+6%", "+0.6%", "−4%".
static func percent(value:float)->String:
	var pct:=value*100.0
	var sign:="+" if pct>=0.0 else "−"
	if absf(pct)<0.05:return "+0%"
	if absf(pct)<9.95:return sign+("%.1f" % absf(pct)).trim_suffix(".0")+"%"
	return sign+str(roundi(absf(pct)))+"%"

## The effects line: "+6% to all work · +6% goods · trade +3 · the rich +2 points".
static func effects_words()->String:
	var x:=effects()
	return "%s to all work · %s goods · trade +%d · the rich +%d %s" % [percent(float(x.work)),percent(float(x.goods)),roundi(float(x.trade)*100.0),roundi(float(x.rich)*100.0),"point" if roundi(float(x.rich)*100.0)==1 else "points"]

## The share as "3 in 100".
static func in_100(value:float)->String:
	var n:=value*100.0
	if n>0.0 and n<0.95:return "%.1f in 100" % n
	return "%d in 100" % roundi(n)

## Whether the next yearly reading moves the share: "growing", "shrinking", "steady".
static func trend()->String:
	var goal:=target()
	var now:=share()
	if goal>now+0.0005:return "growing"
	if goal<now-0.0005:return "shrinking"
	return "steady"
