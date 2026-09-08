extends RefCounted
## Distance-scaled settlement grievances. Preview uses returned player reports;
## reactions use the offended civilization's own cities and observations.
const NEIGHBOR_RADIUS_KM:=30.0
const MAX_OPINION_LOSS:=.70
var system:Node

func _init(owner:Node)->void:system=owner

static func penalty_at(distance_km:float)->float:
	return MAX_OPINION_LOSS*pow(clampf(1.0-distance_km/NEIGHBOR_RADIUS_KM,0,1),2.0)

func preview(position:Vector2)->Dictionary:
	var affected:Dictionary={}
	for city:Dictionary in system.city_intelligence.known_cities("player","",false):
		var owner:=String(city.get("controller",""))
		if owner=="":owner=String(city.get("civ_id",""))
		if owner=="player":continue
		var distance:=position.distance_to(system.city_intelligence.vector(city.position))
		var penalty:=penalty_at(distance)
		if penalty<=0:continue
		var key:=owner if owner!="" else String(city.city_id)
		if affected.has(key) and float(affected[key].penalty)>=penalty:continue
		affected[key]={"civ_id":owner,"city_id":String(city.city_id),"city_name":String(city.name),"distance_km":distance,"penalty":penalty,"observed_day":int(city.observed_day)}
	var entries:Array[Dictionary]=[]
	entries.assign(affected.values())
	entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.penalty)>float(b.penalty))
	if entries.is_empty():
		return {"penalty":0.0,"title":"NO KNOWN NEARBY FOREIGN CITY","text":"Based on returned city reports; unlocated cities remain unknown.","affected":entries}
	var worst:Dictionary=entries[0]
	var severity:="SEVERE" if float(worst.penalty)>=.35 else ("HIGH" if float(worst.penalty)>=.15 else "MILD")
	var text:="%.1f km from %s · estimated relations −%d when they learn. Closer means more resentment." % [float(worst.distance_km),String(worst.city_name),maxi(1,roundi(float(worst.penalty)*100))]
	if entries.size()>1:text+=" %d civilizations may object." % entries.size()
	return {"penalty":float(worst.penalty),"title":"BORDER PROVOCATION · %s" % severity,"text":text,"affected":entries}

func founded(city_id:String,name:String,position:Vector2,day:int)->void:
	# A settlement within a city's established sight radius is locally visible.
	# More distant settlements require an ordinary returned scout/envoy report.
	var place:={"city_id":city_id,"civ_id":"player","name":name,"position":system.city_intelligence.point(position)}
	for civ:Dictionary in system.civilizations:
		var civ_id:=String(civ.id)
		var locally_seen:=false
		for own:Dictionary in _owned_sites(civ_id):
			if position.distance_to(system.city_intelligence.vector(own.position))<=system.city_intelligence.SIGHT_RADIUS:
				locally_seen=true;break
		if locally_seen:
			var observation:Dictionary=system.city_intelligence.location_record(place,day,"nearby settlement observed","founding:"+city_id)
			system.city_intelligence.publish(civ_id,observation,day)
			civ.player_relation["rival_contact_level"]=2
			civ.player_relation["rival_player_intelligence"]=maxf(.15,float(civ.player_relation.get("rival_player_intelligence",0)))
			civ.player_relation["rival_player_trace_center"]=place.position.duplicate(true)
			civ.player_relation["rival_player_trace_day"]=day
			civ.player_relation["rival_player_trace_confidence"]=maxf(.25,float(civ.player_relation.get("rival_player_trace_confidence",0)))
		civ.player_relation=apply_observed(civ,civ.player_relation,day)

func apply_observed(civ:Dictionary,relation:Dictionary,day:int)->Dictionary:
	var civ_id:=String(civ.id)
	var observed:Array[Dictionary]=system.city_intelligence.known_cities(civ_id,"player",false)
	if observed.is_empty():return relation
	var own_sites:=_owned_sites(civ_id)
	var grievances:Dictionary=relation.get("settlement_encroachment",{}).duplicate(true)
	for city:Dictionary in observed:
		# Only a reported player-owned city is grounds for blaming this player.
		if String(city.get("controller","")) not in ["","player"]:continue
		var position:Vector2=system.city_intelligence.vector(city.position)
		var closest:Dictionary={}
		var distance:=INF
		for own:Dictionary in own_sites:
			var candidate:=position.distance_to(system.city_intelligence.vector(own.position))
			if candidate<distance:distance=candidate;closest=own
		var penalty:=penalty_at(distance)
		var previous:float=float((grievances.get(String(city.city_id),{}) as Dictionary).get("penalty",0))
		var increase:=penalty-previous
		if increase<=.000001:continue
		# One grievance per player city and civilization, not per nearby district,
		# UI hover, turn or repeated report. Existing relation dictionaries save it.
		grievances[String(city.city_id)]={"penalty":penalty,"day":day,"foreign_city_id":String(closest.city_id),"distance_km":distance}
		relation["opinion"]=clampf(float(relation.get("opinion",0))-increase,-1,1)
		relation["border_tension"]=clampf(float(relation.get("border_tension",0))+increase,0,1)
		relation["last_incident_day"]=day
		if int(relation.get("contact_level",0))>=2:
			system._record_world_event("Settlement provokes a neighbor","%s resents the nearby settlement of %s. Relations fell by %d; building closer causes greater resentment." % [String(civ.name),String(city.name),roundi(increase*100)],"diplomacy",day)
	relation["settlement_encroachment"]=grievances
	return relation

func _owned_sites(civ_id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for site:Dictionary in system.city_intelligence.sites(false):
		var location:Dictionary=system._region_location(String(site.city_id))
		if location.is_empty():continue
		var region:Dictionary=system.civilizations[int(location.owner_index)].strategic_regions[int(location.region_index)]
		if String(region.get("controller",site.civ_id))==civ_id:result.append(site)
	return result
