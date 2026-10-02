extends RefCounted
## LEAGUES OF THE FEARFUL (docs/STANDING_DESIGN.md section 3): when two or more
## peoples we know fear us at once, they bind themselves together against us.
## Might that frightens one neighbour into tribute turns all of them into one
## enemy: each weighs our strength against theirs together (so awe shrinks and
## contempt grows), their raids and demands come more often, and harm done to
## one is felt by all.
##
## Read once a month from the views others hold (standing.gd) and kept in the
## war block (saved with the court), with a little memory so a league does not
## flicker: a people is bound at JOIN_FEAR and lets go below LEAVE_FEAR.

const WAR_PATH:="res://scripts/war_loop.gd"
const Standing:=preload("res://scripts/standing.gd")
const RIVALS_PATH:="res://scripts/rival_rulers.gd"

const JOIN_FEAR:=0.45
const LEAVE_FEAR:=0.30
## They bow to us and hate it: awe held with resentment binds too.
const JOIN_AWE:=0.60
const JOIN_RESENTMENT:=0.30
const MIN_MEMBERS:=2
## Members back each other: their raids for our stores or old grudges, and
## their demands, come this much more often; their gifts less.
const RAID_BACKING:=1.5
const DEMAND_BACKING:=1.5
const GIFT_BACKING:=0.7
const SHARED_WORDS:="what was done to our friends"

static func _state()->Dictionary:
	# Loaded at run time: the war loop reads the league as it rolls its raids.
	var s:Dictionary=(load(WAR_PATH) as GDScript).call("state")
	if not s.get("league") is Dictionary: s["league"]={"members":[],"since":-1,"formed":0}
	return s.league

static func members()->Array:
	var members:Variant=_state().get("members",[])
	return (members as Array).duplicate() if members is Array else []

static func is_member(civ_id:String)->bool:
	return civ_id in members()

## The league's fighting strength on standing.gd's scale: every member's own.
static func combined_strength()->float:
	var total:=0.0
	for civ_id in members():
		var civ:=ForeignDiplomacy.civilization(String(civ_id))
		if not civ.is_empty(): total+=Standing.their_fighting_strength(civ)
	return maxf(1.0,total)

## Once a month (war_loop.daily): who fears us enough to stand together.
static func monthly(day:int)->void:
	if String(WorldSimulation.actor_id)!="player": return
	var league:=_state()
	var was:Array=members()
	var bound:Array=[]
	var answer:=load("res://scripts/world_answer.gd") as GDScript
	for v:Dictionary in Standing.views():
		var id:=String(v.civ_id)
		# A people that bows to us is under our protection, not against us.
		if answer!=null and bool(answer.call("is_tributary",id)): continue
		var fear:=float(v.fear)
		var holds:=fear>=JOIN_FEAR or (float(v.awe)>=JOIN_AWE and float(v.resentment)>=JOIN_RESENTMENT)
		if not holds and id in was and fear>=LEAVE_FEAR: holds=true
		if holds: bound.append(id)
	# Peoples fighting each other do not stand together.
	for id in bound.duplicate():
		for other in bound:
			if other!=id and _at_odds(String(id),String(other)): bound.erase(id); break
	if bound.size()<MIN_MEMBERS: bound=[]
	var formed:=was.is_empty() and not bound.is_empty()
	var ended:=not was.is_empty() and bound.is_empty()
	league["members"]=bound
	if formed:
		league["since"]=day
		league["formed"]=int(league.get("formed",0))+1
		_tell("A League Against Us","%s have bound themselves together for fear of us. Each now weighs our strength against all of theirs, and harm done to one will be felt by all." % _names(bound),day)
	elif ended:
		league["since"]=-1
		_tell("The League Breaks Up","Those who stood together for fear of us have gone their own ways.",day)
	# Harm done to one is felt by all: a fresh grudge against us is shared.
	var rivals:=load(RIVALS_PATH) as GDScript if ResourceLoader.exists(RIVALS_PATH) else null
	if rivals==null: return
	for id in bound:
		var character:Dictionary=rivals.call("rival_character",String(id))
		for g in character.get("grudges",[]):
			# Only a people's own fresh wrong is shared, never one shared with it.
			if not g is Dictionary or day-int(g.get("day",-99999))>30 or bool(g.get("inherited",false)) or String(g.get("text","")).begins_with(SHARED_WORDS): continue
			for other in bound:
				if other==id: continue
				rivals.call("grudge",String(other),"%s the %s" % [SHARED_WORDS,String(ForeignDiplomacy.civilization(String(id)).get("name",id))],float(g.get("weight",0.1))*0.4,"league:%s:%d" % [String(id),int(g.get("day",0))])

static func _at_odds(first:String,second:String)->bool:
	var civ:=ForeignDiplomacy.civilization(first)
	if civ.is_empty(): return false
	var relation:Dictionary=(civ.get("relations",{}) as Dictionary).get(second,{})
	if bool(relation.get("at_war",false)): return true
	var world=WorldSimulation.world
	return world!=null and world.has_method("rival_feud_hot") and bool(world.rival_feud_hot(relation,int(WorldSimulation.state.elapsed_days)))

static func _names(ids:Array)->String:
	var names:PackedStringArray=[]
	for id in ids: names.append(String(ForeignDiplomacy.civilization(String(id)).get("name",id)))
	if names.size()<=1: return "".join(names)
	return ", ".join(names.slice(0,names.size()-1))+" and "+names[names.size()-1]

static func _tell(title:String,text:String,day:int)->void:
	var chronicle:=load("res://scripts/chronicle.gd") as GDScript
	if chronicle!=null and bool(chronicle.call("active")):
		chronicle.call("record",{"key":"league:%d" % day,"title":title,"text":text,"tier":"moment","kind":"omen","domain":"security"})
