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
static func local_bonus(state:Node,key:String)->float:
	var value:=0.0
	for city:Dictionary in state.player_settlements:
		if not (String(city.id)==String(state.resource_settlement_id) or (state.resource_settlement_id.is_empty() and bool(city.get("primary",false)))):continue
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):
			if r.status=="functioning":value+=float(REWARDS.get(r.id,{}).get(key,0))*float(r.condition)
	return minf(.4,value) if key=="spoilage" else (minf(.20,value) if key in ["craft","research","attraction"] else value)

static func share_accounts(state:Node,listener:String,day:int)->void:
	# Called only when travelers physically encounter another society.
	if listener.is_empty():return
	for city:Dictionary in state.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):
			if r.status!="functioning" or int(r.operating_days)<365:continue
			if not r.has("heard_by"):r.heard_by={}
			r.heard_by[listener]={"day":day,"condition":float(r.condition),"strain":int(r.strain)}

static func diplomatic_bonus(state:Node,listener:String,day:int)->float:
	var total:=0.0
	for city:Dictionary in state.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):
			var account:Dictionary=r.get("heard_by",{}).get(listener,{})
			if account.is_empty():continue
			var freshness:=clampf(1.0-float(maxi(0,day-int(account.day)))/(365.0*30.0),0,1)
			# Human cost complicates recognition without erasing accomplishment.
			total+=float(REWARDS.get(r.id,{}).get("reputation",.015))*float(account.condition)*freshness*(.5 if int(account.strain)>=180 else 1.0)
	return minf(.20,total)

static func legacy(state:Node)->Dictionary:
	var sites:=0;var paths:Array=[];var contacts:Array=[];var award:Dictionary={};var costly:=0
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)):award=city.get("wonder_victory",{})
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):
			if r.status!="functioning" or float(r.condition)<.6 or int(r.operating_days)<365*20:continue
			sites+=1
			if int(r.strain)>=180:costly+=1
			var path:String=REWARDS.get(r.id,{}).get("path","")
			if path not in paths:paths.append(path)
			for contact:String in r.get("heard_by",{}):
				var account:Dictionary=r.heard_by[contact]
				if int(state.elapsed_days)-int(account.day)<=365*30 and contact not in contacts:contacts.append(contact)
	return {"sites":sites,"paths":paths.size(),"contacts":contacts.size(),"ready":sites>=3 and paths.size()>=3 and contacts.size()>=2,"award":award,"costly":costly}

static func record_victory(state:Node,day:int)->void:
	var progress:=legacy(state)
	if not progress.ready or not progress.award.is_empty():return
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)):
			city.wonder_victory={"day":day,"costly":int(progress.costly)}
			state.settlement_network_revision+=1
			return

static func victory_block(state:Node)->Dictionary:
	var p:=legacy(state)
	if not p.award.is_empty():
		return {"type":"text","heading":"VICTORY · ENDURING CIVILIZATION","text":"Earned in Year %d. Three kinds of achievement served your people for twenty years and became known abroad. Continue shaping what follows.%s" % [int(p.award.day)/365+1," Its history also records hardship imposed during construction." if int(p.award.costly)>0 else ""]}
	return {"type":"rows","heading":"ENDURING CIVILIZATION · VICTORY PATH","items":[
		{"name":"%d / 3 enduring landmarks" % p.sites,"detail":"Each: twenty years of maintained operation, condition at least 60%."},
		{"name":"%d / 3 kinds of achievement" % p.paths,"detail":"Abundance, mastery, knowledge, influence or attraction."},
		{"name":"%d / 2 foreign societies reached" % p.contacts,"detail":"Travelers must share accounts of these landmarks; accounts remain current for thirty years."}]}

static func description(id:String,condition:float=1.0)->String:
	var d:Dictionary=REWARDS.get(id,{})
	var parts:Array[String]=[]
	if d.has("food_capacity"):parts.append("+%s rations of local storage" % str(roundi(float(d.food_capacity)*condition)))
	if d.has("water_capacity"):parts.append("+%s water units of local storage" % str(roundi(float(d.water_capacity)*condition)))
	if d.has("spoilage"):parts.append("%.0f%% less local food spoilage" % (float(d.spoilage)*condition*100))
	if d.has("craft"):parts.append("+%.0f%% crafting effectiveness" % (float(d.craft)*condition*100))
	if d.has("research"):parts.append("+%.0f%% research effectiveness" % (float(d.research)*condition*100))
	if d.has("attraction"):parts.append("+%.0f points household attraction; arrivals still require a journey" % (float(d.attraction)*condition*100))
	if d.has("reputation"):parts.append("Stronger diplomatic reception once travelers share its reputation")
	return String(d.get("path","Legacy"))+" · "+"; ".join(parts)+"."

static func valid(city:Dictionary)->bool:
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
