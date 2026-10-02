extends RefCounted
## THE PATH A PEOPLE TAKES (docs/PEOPLE_FIRST.md, F): where its rulers lean
## the daily work. Five paths, and a balanced split for a ruler with no strong
## lean:
##   growth            food, and keeping and caring (more children live)
##   making            making and trade: making, carrying, cutting and digging
##   war               keeping watch (the watch is the people's fighters)
##   learning          learning; only a scholarly temper takes it
##   building          building, and the cutting and digging it needs
##
## One rule for every people (docs/STANDING_DESIGN.md section 9): a temper
## reads each path on the five axes of leader_personality.gd, as ambitions are
## read (AMBITION_TEMPER: weights add to one, a negative weight reads the
## other end of the axis), and the people's situation pulls a little (the
## neighbours pressing or war pull toward the watch; people without a roof
## toward building; peoples met toward making and trade; sickness toward
## caring). The best path is taken when it stands above BALANCED_BELOW, else
## the split stays balanced; a path held is kept while it is within STICK of
## the best, so a ruler does not flip month by month.
##
## Who chooses: a computer ruler at its monthly review, by its own temper
## (civilization_controller.gd work_path_orders: an ordinary order, kind
## "work_path"); the player's own leaders, and any people no computer rules,
## by the people's tendency (leader_personality.from_values: the values they
## live by), on the same rule every REVIEW_DAYS (current()). A people's values
## start near the middle, so the player's leaders start balanced.
##
## What it does: the path adds planning weight to its work in the leaders'
## split (GovernmentPeopleSystem._allocations_for_focus, through lean()); food
## still comes first, as the survival guard and the age's food floor are laid
## on after it. Growth also asks the planners for a deeper food reserve.
##
## Kept on PeopleDirection.work_path, saved with each people:
## {id, since, reviewed, why, score, by ("ruler" | "leaders")}.

const PERSONALITY:=preload("res://scripts/leader_personality.gd")

const PATHS:=["growth","making","war","learning","building"]
## How each path suits a temper (read as leader_personality.ambition_fit).
const PATH_TEMPER:={
	"growth":{"empathy":.55,"risk_tolerance":-.25,"assertiveness":-.20},
	"making":{"openness":.45,"discipline":.35,"risk_tolerance":.20},
	"war":{"assertiveness":.55,"empathy":-.25,"risk_tolerance":.20},
	"learning":{"openness":.55,"risk_tolerance":-.25,"discipline":.20},
	"building":{"discipline":.55,"openness":-.25,"risk_tolerance":-.20},
}
## Only a ruler at least this open is scholarly enough to take learning.
const SCHOLARLY:=.68
## Below this fit no path leads: the split stays balanced.
const BALANCED_BELOW:=.58
## A path held is kept while it is within this of the best.
const STICK:=.03
## Days between the leaders' reviews (a computer ruler reviews monthly too).
const REVIEW_DAYS:=30
## How hard the situation pulls: the neighbours' pressure (0..1) and open war
## toward the watch; a plain need (roofless, sick, peoples met) toward its path.
const THREAT_PULL:=.10
const WAR_PULL:=.05
const NEED_PULL:=.03
## Planning weight each path adds to its work in the leaders' split (the base
## split, GovernmentPeopleSystem.BASE_ALLOCATIONS, adds up to 100).
const WORK:={
	"growth":{"Administration":9.0,"Logistics":2.0},
	"making":{"Crafting":8.0,"Logistics":4.0,"Extraction":4.0},
	"war":{"Defense":12.0,"Crafting":2.0},
	"learning":{"Knowledge":9.0,"Survey":2.0},
	"building":{"Construction":10.0,"Extraction":4.0},
	"balanced":{},
}
## The deeper food reserve a path asks the planners for (reserve_lean, 0..1).
const FOOD_LEAN:={"growth":.5}
const NAMES:={"growth":"growth","making":"making and trade","war":"war","learning":"learning","building":"building","balanced":"a balanced split"}
## The work each path leans toward, in the People view's words.
const LEANS:={"growth":"more on getting food and on keeping and caring","making":"more on making, carrying, cutting and digging","war":"more on keeping watch",
	"learning":"more on learning","building":"more on building, cutting and digging","balanced":"no one task more than the rest"}
## The temper each path suits, in a few words.
const TEMPERS:={"growth":"caring and careful","making":"open and steady","war":"proud and hard","learning":"scholarly","building":"disciplined and careful","balanced":"even"}

# --------------------------------------------------------------------------
# The choice (pure)
# --------------------------------------------------------------------------

## How well a path suits a temper, 0..1.
static func fit(path:String,p:Dictionary)->float:
	var out:=0.0
	var weights:Dictionary=PATH_TEMPER.get(path,{})
	for axis:String in weights:
		var weight:=float(weights[axis])
		var value:=clampf(float(p.get(axis,.5)),0.0,1.0)
		out+=weight*value if weight>=0.0 else -weight*(1.0-value)
	return out

static func scholarly(p:Dictionary)->bool:
	return clampf(float(p.get("openness",.5)),0.0,1.0)>=SCHOLARLY

## Each path's score for this temper in this situation; learning only for a
## scholarly temper.
static func scores(p:Dictionary,s:Dictionary)->Dictionary:
	var out:={}
	for path:String in PATHS:
		if path=="learning" and not scholarly(p):continue
		out[path]=fit(path,p)
	out.war=float(out.war)+THREAT_PULL*clampf(float(s.get("threat",0.0)),0.0,1.0)+(WAR_PULL if bool(s.get("at_war",false)) else 0.0)
	if bool(s.get("roofless",false)):out.building=float(out.building)+NEED_PULL
	if int(s.get("met",0))>0:out.making=float(out.making)+NEED_PULL
	if bool(s.get("sick",false)):out.growth=float(out.growth)+NEED_PULL
	return out

## The path this temper takes in this situation: {id, score, why, scores}.
## `held` is the path already taken ("" for none), kept while near the best.
static func choose(p:Dictionary,s:Dictionary,held:String="")->Dictionary:
	var all:=scores(p,s)
	var best:="balanced"
	var top:=BALANCED_BELOW
	for path:String in PATHS:
		if all.has(path) and float(all[path])>top:top=float(all[path]);best=path
	if held!="" and held!=best and NAMES.has(held):
		var kept:=BALANCED_BELOW if held=="balanced" else float(all.get(held,-1.0))
		if kept>=top-STICK:best=held;top=kept
	return {"id":best,"score":top,"why":why(best,s),"scores":all}

## Why, in a few plain words: the temper, and what pulls.
static func why(path:String,s:Dictionary)->String:
	var out:=String(TEMPERS.get(path,"even"))
	if path=="balanced":return out+", with no strong lean"
	var pulls:PackedStringArray=[]
	if path=="war":
		if bool(s.get("at_war",false)):pulls.append("at war")
		elif float(s.get("threat",0.0))>=.3:pulls.append("the neighbours press")
	if path=="building" and bool(s.get("roofless",false)):pulls.append("some sleep without a roof")
	if path=="making" and int(s.get("met",0))>0:pulls.append("there are others to trade with")
	if path=="growth" and bool(s.get("sick",false)):pulls.append("the sick need tending")
	return out if pulls.is_empty() else "%s, and %s" % [out,", ".join(pulls)]

# --------------------------------------------------------------------------
# In the world (the current scope)
# --------------------------------------------------------------------------

## This people's situation as the path reads it, from its own state.
static func situation()->Dictionary:
	var out:={"threat":0.0,"at_war":false,"met":0,"roofless":false,"sick":false}
	var government:Variant=WorldSimulation.government
	if government!=null and government.has_method("neighbour_threat"):out.threat=float(government.neighbour_threat())
	if WorldSimulation.world!=null:
		for civ in WorldSimulation.world.civilizations:
			if not civ is Dictionary or not bool((civ as Dictionary).get("alive",true)):continue
			var relation:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
			if bool(relation.get("at_war",false)):out.at_war=true
			if int(relation.get("contact_level",0))>=1:out.met=int(out.met)+1
	var state=WorldSimulation.state
	out.roofless=float(state.simulation_metrics.get("housing_ratio",1.0))<.9
	out.sick=float(state.population_health)<.6
	return out

## Is this people's path its computer ruler's to choose (true), or its own
## leaders' (the player's people, or any people no computer rules)?
static func ruler_chooses()->bool:
	var id:=String(WorldSimulation.actor_id)
	if id=="player" or not WorldSimulation.actors.has(id):return false
	return String((WorldSimulation.actors[id] as Dictionary).get("controller",""))=="ai"

## The path this people holds, or "" when none has been chosen.
static func held()->String:
	var direction:Variant=WorldSimulation.direction
	if direction==null:return ""
	var path:Variant=direction.get("work_path")
	if path is Dictionary and NAMES.has(String((path as Dictionary).get("id",""))):return String(path.id)
	return ""

## The whole record: {id, since, reviewed, why, score, by}, {} when none.
static func record_of()->Dictionary:
	var direction:Variant=WorldSimulation.direction
	if direction==null or held()=="":return {}
	return (direction.work_path as Dictionary).duplicate(true)

## Keeps the path chosen today; `since` stays while the path does not change.
static func record(id:String,reason:String,score:float,by:String)->Dictionary:
	var direction:Variant=WorldSimulation.direction
	if direction==null or not NAMES.has(id):return {}
	var day:=int(WorldSimulation.state.elapsed_days)
	var was:Dictionary=direction.work_path if direction.work_path is Dictionary else {}
	var since:=int(was.get("since",day)) if String(was.get("id",""))==id else day
	direction.work_path={"id":id,"since":since,"reviewed":day,"why":reason,"score":snappedf(score,.001),"by":by}
	return direction.work_path

## The path the leaders' split leans toward today in this scope. A computer
## ruler's is the one it chose at its review (balanced until it has chosen);
## any other people's leaders review it on the same rule every REVIEW_DAYS,
## from the people's tendency.
static func current()->String:
	var direction:Variant=WorldSimulation.direction
	if direction==null:return "balanced"
	if not ruler_chooses():
		var path:Dictionary=direction.work_path if direction.work_path is Dictionary else {}
		var day:=int(WorldSimulation.state.elapsed_days)
		var reviewed:=int(path.get("reviewed",-REVIEW_DAYS))
		if held()=="" or day-reviewed>=REVIEW_DAYS or reviewed>day:
			var pick:=choose(PERSONALITY.from_values(WorldSimulation.state.societal_values),situation(),held())
			record(String(pick.id),String(pick.why),float(pick.score),"leaders")
	var id:=held()
	return id if id!="" else "balanced"

## Lays the path's lean on the leaders' planning weights (in place) and
## returns the food reserve lean the planners should keep with it.
static func lean(weights:Dictionary,reserve_lean:float)->float:
	var path:=current()
	var work:Dictionary=WORK.get(path,{})
	for role:String in work:weights[role]=float(weights.get(role,0.0))+float(work[role])
	return clampf(reserve_lean+float(FOOD_LEAN.get(path,0.0)),0.0,1.0)

## A computer ruler's order (civilization_orders.gd "work_path"):
## {kind, path, why, score}.
static func order(given:Dictionary)->Dictionary:
	var id:=String(given.get("path",""))
	if not NAMES.has(id):return {"error":"No such path for the people's work."}
	record(id,String(given.get("why","")),float(given.get("score",0.0)),"ruler")
	return {"ok":true,"path":id}

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

## The People view's line for our own leaders' path, and its tip: {text, tip}.
static func leaders_line()->Dictionary:
	var id:=held() if held()!="" else "balanced"
	var kept:=record_of()
	var tip:="The leaders lean the work by the people's ways (the values they live by), on the same rule as every ruler. They look again each month."
	if id=="balanced":
		return {"text":"Our leaders keep the work balanced, favouring no one task.","tip":tip}
	var since:=int(kept.get("since",int(WorldSimulation.state.elapsed_days)))
	return {"text":"Our leaders lean the work toward %s." % String(NAMES[id]),
		"tip":"%s They put %s. The people's ways are %s. Since year %d." % [tip,String(LEANS[id]),String(kept.get("why",TEMPERS[id])),since/365+1]}

## A people's path as the Standing page names it: "their work is set on war";
## "" for a people not simulated or still balanced.
static func people_words(civ_id:String)->String:
	if civ_id=="" or not WorldSimulation.actors.has(civ_id):return ""
	var id:String=WorldSimulation.scoped(civ_id,func()->String:return held())
	if id=="" or id=="balanced":return ""
	return "their work is set on %s" % String(NAMES[id])

## Every computer people's path across the world: {counts:{path:n}, rows:[{id,
## name, path, why, since}]}, "balanced" for one still undecided. The log and
## the tests read it.
static func world_spread()->Dictionary:
	var counts:={}
	var rows:Array=[]
	var ids:=WorldSimulation.actors.keys()
	ids.sort()
	for civ_id:String in ids:
		var row:Dictionary=WorldSimulation.scoped(civ_id,func()->Dictionary:
			var kept:=record_of()
			return {"id":civ_id,"name":String(WorldSimulation.state.settlement_name),"path":String(kept.get("id","balanced")),"why":String(kept.get("why","")),"since":int(kept.get("since",-1))})
		counts[row.path]=int(counts.get(row.path,0))+1
		rows.append(row)
	return {"counts":counts,"rows":rows}
