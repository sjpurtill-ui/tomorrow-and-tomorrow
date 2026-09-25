extends RefCounted
## Signs of people. A returning party that passed through a neighbouring
## people's range without meeting them brings home what it actually saw there:
## smoke at dusk, a cold hearth, cut saplings, many feet on a game trail. The
## sign names no one and reveals no homeland. It gives a bearing and a rough
## distance, which the scouting staff can follow on a later departure.
##
## Every sign is anchored to a real home within reach of a real returned route.
## Nothing here grants contact; contact still needs a party within the ordinary
## encounter distance of the people themselves.

const ENCOUNTER_KM:=58.0
const WALK_KM_PER_DAY:=25.0

static func range_km(civ:Dictionary)->float:
	## How far a people's traces carry: their hunting and gathering range, their
	## seasonal camps and the smoke of their fires, growing slowly with their
	## numbers. Signs reach well beyond the distance at which people are met,
	## so a people is usually heard of years before it is met.
	return clampf(120.0+sqrt(maxf(1.0,float(civ.get("population",120.0))))*4.0,150.0,240.0)

static func read_route(world:Node,route:Array,day:int)->Array[Dictionary]:
	var signs:Array[Dictionary]=[]
	if route.size()<2: return signs
	for civ_variant in world.civilizations:
		var civ:Dictionary=civ_variant
		if not bool(civ.get("alive",true)): continue
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))>=2: continue
		var home:Vector2=world._civilization_world_position(civ)
		var encounter:Dictionary=world._closest_route_encounter(route,home)
		var distance:=float(encounter.get("distance",INF))
		if distance<=ENCOUNTER_KM or distance>range_km(civ) or not encounter.position is Vector2: continue
		signs.append(_card(world,civ,encounter.position,home,distance,day))
	return signs

static func _card(world:Node,civ:Dictionary,seen_at:Vector2,home:Vector2,distance:float,day:int)->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|sign|%s|%d" % [int(world.last_world_seed),String(civ.get("id","")),day])
	# The party judged the distance by eye; they are rarely more than a fifth out.
	var judged:=maxf(30.0,distance*rng.randf_range(0.82,1.18))
	var toward:=(home-seen_at).normalized()
	var estimate:=seen_at+toward*judged
	var bearing:String=world._compass_phrase(seen_at,estimate)
	var days:=maxi(1,roundi(judged/WALK_KM_PER_DAY))
	var walk:="a day's walk" if days==1 else "%s days' walk" % _number_word(days)
	var text:=""
	if distance<90.0:
		text=String(["Fresh tracks of many feet crossed our trail, and saplings had been cut with stone, not teeth. They lead %s. Whoever made them lives perhaps %s beyond." % [bearing,walk],
			"We found a cold hearth ringed with stones, the ash still soft, and bones cracked for marrow. The trail from it runs %s, perhaps %s." % [bearing,walk]][rng.randi_range(0,1)])
	elif distance>=150.0:
		text=String(["Far out in the %s country we came on a hunting camp of strangers, lately left: shelters of bent poles, a drying rack, a spear point of a make we do not know. Their home must lie beyond, perhaps %s." % [bearing,walk],
			"We found a butchered carcass and a cache of dried meat, hidden with care by people who are not ours. Their trail runs %s; their fires must be %s off." % [bearing,walk]][rng.randi_range(0,1)])
	else:
		text=String(["Smoke rose at dusk far off to the %s, more than one fire. It is someone's home, perhaps %s from where we stood." % [bearing,walk],
			"From a rise we saw smoke hanging over the %s country, too steady for a wildfire. Perhaps %s off." % [bearing,walk]][rng.randi_range(0,1)])
	return {"kind":"sign","title":"Signs of people","description":text,
		"consequence":"No one was met. The staff can follow the sign; contact still needs a party to reach these people.",
		"civ_id":String(civ.get("id","")),"day":day,"bearing":bearing,"walk_days":days,
		"position":{"x":seen_at.x,"z":seen_at.y},"estimate":{"x":estimate.x,"z":estimate.y}}

static func _number_word(value:int)->String:
	var words:=["no","one","two","three","four","five","six","seven","eight","nine","ten"]
	return words[value] if value>=0 and value<words.size() else str(value)

static func open_signs(world:Node)->Array[Dictionary]:
	## The newest returned sign for each people not yet met, newest first.
	var result:Array[Dictionary]=[]
	var seen:Dictionary={}
	for report_variant in world.scout_reports:
		var report:Dictionary=report_variant
		for card_variant in report.get("discoveries",[]):
			if not card_variant is Dictionary or String((card_variant as Dictionary).get("kind",""))!="sign": continue
			var card:Dictionary=card_variant
			var civ_id:=String(card.get("civ_id",""))
			if civ_id=="" or seen.has(civ_id): continue
			seen[civ_id]=true
			var index:int=world._civilization_index(civ_id)
			if index<0: continue
			var civ:Dictionary=world.civilizations[index]
			if not bool(civ.get("alive",true)) or int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: continue
			result.append(card)
	return result

static func target_options(world:Node)->Array[Dictionary]:
	var options:Array[Dictionary]=[]
	for card in open_signs(world):
		options.append({"id":"sign:%s" % String(card.civ_id),"kind":"follow_sign","civ_id":String(card.civ_id),
			"label":"FOLLOW THE SIGNS %s" % String(card.get("bearing","")).to_upper(),
			"description":"Walk toward what the last party saw (%s). The people who made the signs are not yet met." % String(card.get("description","")).get_slice(".",0).to_lower(),
			"position":(card.get("estimate",{}) as Dictionary).duplicate(true)})
	return options

static func sign_to_follow(world:Node,skips:Dictionary={},day:int=0)->String:
	## A sign no party is already following, for the standing scouting staff.
	## Signs the staff could not reach recently are left alone for a season.
	var following:Dictionary={}
	for mission_variant in world.scout_missions:
		following[String((mission_variant as Dictionary).get("target_id",""))]=true
	for option in target_options(world):
		if following.has(String(option.id)) or int(skips.get(String(option.id),-1))>day: continue
		return String(option.id)
	return ""
