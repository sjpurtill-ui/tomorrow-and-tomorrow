extends RefCounted
## Benefits require a functioning local site. Capacity never creates supplies.
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const REWARDS={
	"ancestor_ring":{"path":"Influence","reputation":.06},
	"great_hall":{"path":"Influence","reputation":.08,"attraction":.03},
	"rain_court":{"path":"Abundance","water_capacity":7200.0},
	"flood_terraces":{"path":"Abundance","food_capacity":9000.0,"spoilage":.10},
	"star_steps":{"path":"Knowledge","research":.12},
	"kiln_court":{"path":"Mastery","craft":.12},
	"long_song":{"path":"Knowledge","research":.08,"attraction":.03},
	"common_stores":{"path":"Abundance","food_capacity":18000.0,"spoilage":.25},
	"safe_passage":{"path":"Attraction","attraction":.08,"reputation":.04},
	"living_orchard":{"path":"Abundance","food_capacity":4500.0,"spoilage":.15},
	"stone_crown":{"path":"Influence","reputation":.10},
	"measures_house":{"path":"Mastery","craft":.10,"reputation":.03},
}
## The kind of achievement each conceived purpose represents (for history).
const PURPOSE_PATH:={"honor_dead":"Memory","bind_tribes":"Influence","tame_flood":"Abundance","feed_people":"Abundance","give_thanks":"Abundance","watch_heavens":"Knowledge","remember_knowledge":"Knowledge","awe_rivals":"Influence","mark_triumph":"Influence","defy_gods":"Aspiration","master_craft":"Mastery","welcome_strangers":"Attraction"}
## Lesser monuments and follies give no rewards; only standing works do.
static func rewarding(r:Dictionary)->bool:
	return r.status=="functioning" and not bool(r.get("lesser",false)) and String(r.get("outcome",""))!="collapse"
## Practical rewards: a conceived work stores what its outcome earned; legacy
## founding works use the fixed table.
static func reward_table(r:Dictionary)->Dictionary:
	if r.get("rewards") is Dictionary:return r.rewards
	return REWARDS.get(String(r.id),{})
static func path_of(r:Dictionary)->String:
	if REWARDS.has(String(r.id)):return String(REWARDS[String(r.id)].get("path",""))
	return String(PURPOSE_PATH.get(String(Catalog.get_definition(String(r.id)).get("purpose","")),""))
static func _finished(r:Dictionary)->bool:
	var d:=Catalog.get_definition(String(r.id))
	return not bool(r.get("lesser",false)) and String(r.get("status","")) in ["functioning","ruined"] and float(r.get("progress",0))+.00001>=float(d.get("work",1))*float(r.get("work_scale",1.0))
static func local_bonus(state:Node,key:String)->float:
	var value:=0.0
	for city:Dictionary in state.player_settlements:
		if not (String(city.id)==String(state.resource_settlement_id) or (state.resource_settlement_id.is_empty() and bool(city.get("primary",false)))):continue
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):
			if rewarding(r):value+=float(reward_table(r).get(key,0))*float(r.condition)
	return minf(.4,value) if key=="spoilage" else (minf(.20,value) if key in ["craft","research","attraction"] else value)

static func share_accounts(state:Node,listener:String,day:int)->void:
	# Called only when travelers physically encounter another society.
	if listener.is_empty():return
	for city:Dictionary in state.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):
			if not rewarding(r) or int(r.operating_days)<365:continue
			if not r.has("heard_by"):r.heard_by={}
			r.heard_by[listener]={"day":day,"condition":float(r.condition),"strain":int(r.strain)}

static func diplomatic_bonus(state:Node,listener:String,day:int)->float:
	var total:=0.0
	for city:Dictionary in state.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):
			var account:Dictionary=r.get("heard_by",{}).get(listener,{})
			if account.is_empty() or bool(r.get("lesser",false)) or String(r.get("outcome",""))=="collapse":continue
			var freshness:=clampf(1.0-float(maxi(0,day-int(account.day)))/(365.0*30.0),0,1)
			# Human cost complicates recognition without erasing accomplishment.
			total+=maxf(.015,float(reward_table(r).get("reputation",.015)))*float(account.condition)*freshness*(.5 if int(account.strain)>=180 else 1.0)
	return minf(.20,total)

## A people's record of wonders — history, never a win condition. Counts every
## work attempted (including earlier layers of a site), how many stood and how
## many fell, those still standing, those that endured twenty years, the kinds
## of purpose among the enduring ones, and how many foreign peoples know them.
static func history(state:Node)->Dictionary:
	var attempted:=0;var succeeded:=0;var follies:=0;var standing:=0;var enduring:=0;var costly:=0
	var kinds:Array=[];var known_by:Array=[]
	for city:Dictionary in state.player_settlements:
		for r:Dictionary in city.get("undertakings",[]):
			attempted+=1+r.get("layers",[]).size()
			for layer in r.get("layers",[]):
				if layer is Dictionary and String(layer.get("outcome","success")) in ["success","triumph"]:succeeded+=1
				elif layer is Dictionary and String(layer.get("outcome",""))=="collapse":follies+=1
			var outcome:=String(r.get("outcome",""))
			if outcome=="collapse":follies+=1
			elif _finished(r) and outcome in ["","success","triumph"]:succeeded+=1
			if String(city.get("occupied_by","")) not in ["","player"] or not rewarding(r):continue
			standing+=1
			if int(r.operating_days)>=365*20 and float(r.condition)>=.6:
				enduring+=1
				if int(r.strain)>=180:costly+=1
				var kind:=path_of(r)
				if kind not in kinds:kinds.append(kind)
			for contact:String in r.get("heard_by",{}):
				var account:Dictionary=r.heard_by[contact]
				if int(state.elapsed_days)-int(account.day)<=365*30 and contact not in known_by:known_by.append(contact)
	return {"attempted":attempted,"succeeded":succeeded,"follies":follies,"standing":standing,"enduring":enduring,"kinds":kinds.size(),"known_by":known_by.size(),"costly":costly}

static func description(id:String,condition:float=1.0)->String:
	var d:Dictionary=REWARDS.get(id,{})
	var definition:=Catalog.get_definition(id)
	if bool(definition.get("concept",false)):
		d=load("res://scripts/wonder_concept.gd").rewards_for(String(definition.purpose),String(definition.ambition),"success")
		d["path"]=String(PURPOSE_PATH.get(String(definition.purpose),"Legacy"))
	var parts:Array[String]=[]
	if d.has("food_capacity"):parts.append("+%s rations of local storage" % str(roundi(float(d.food_capacity)*condition)))
	if d.has("water_capacity"):parts.append("+%s water units of local storage" % str(roundi(float(d.water_capacity)*condition)))
	if d.has("spoilage"):parts.append("%.0f%% less local food spoilage" % (float(d.spoilage)*condition*100))
	if d.has("craft"):parts.append("+%.0f%% crafting effectiveness" % (float(d.craft)*condition*100))
	if d.has("research"):parts.append("+%.0f%% research effectiveness" % (float(d.research)*condition*100))
	if d.has("attraction"):parts.append("+%.0f points household attraction; arrivals still require a journey" % (float(d.attraction)*condition*100))
	if d.has("reputation"):parts.append("Stronger diplomatic reception once travelers share its reputation")
	var special:String=load("res://scripts/undertaking_effects.gd").describe(id,condition)
	if not special.is_empty() and not String(definition.get("effect","")).is_empty():parts.append(special.trim_suffix("."))
	return String(d.get("path","Legacy"))+" · "+"; ".join(parts)+"."

static func valid(city:Dictionary)->bool:
	# Older saves may carry a retired victory award; tolerate it, never write it.
	var award=city.get("wonder_victory",{})
	if not award is Dictionary:return false
	if not award.is_empty():
		for key in ["day","costly"]:
			if not award.get(key) is int or award[key]<0:return false
	for r:Dictionary in city.get("undertakings",[]):
		var accounts=r.get("heard_by",{})
		if not accounts is Dictionary:return false
		for id in accounts:
			if not id is String or id.is_empty() or not accounts[id] is Dictionary:return false
			var a:Dictionary=accounts[id]
			if not a.get("day") is int or a.day<0 or not a.get("strain") is int or a.strain<0:return false
			if not (a.get("condition") is int or a.get("condition") is float):return false
			if not is_finite(float(a.condition)) or a.condition<0 or a.condition>1:return false
	return true
