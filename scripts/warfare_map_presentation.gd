class_name WarfareMapPresentation
extends RefCounted

# Warfare is rendered from bounded aggregate records. Population changes the
# numbers written on a formation, never the number of map nodes.
const MAX_PLAYER_MARKERS:=12
const MAX_FOREIGN_MARKERS:=24
const MAX_FRONT_MARKERS:=8

const PLAYER_COLOR:="#67B4CF"
const PLAYER_SELECTED_COLOR:="#F3D77C"
const HOSTILE_COLOR:="#D76355"
const FOREIGN_COLOR:="#D6AD55"
const SCOUT_COLOR:="#91BDC4"
const FRONT_COLOR:="#D8B25E"
const ENGAGEMENT_COLOR:="#ED725F"


static func scale_band(camera_size:float)->String:
	if camera_size<8.0: return "ground"
	if camera_size<=80.0: return "local"
	if camera_size<=800.0: return "regional"
	if camera_size<=8000.0: return "continental"
	return "world"


static func marker_scale(camera_size:float)->float:
	return clampf(camera_size*0.016,0.45,32.0)


static func formation_echelon(personnel:int)->int:
	# Four visual bars communicate the order of magnitude of a formation without
	# making its map node count proportional to troop count. A billion-person force
	# still owns exactly the same fixed counter geometry as a small detachment.
	if personnel>=100_000: return 4
	if personnel>=10_000: return 3
	if personnel>=1_000: return 2
	return 1


static func formation_role(army:Dictionary)->String:
	# The counter glyph reflects the formation's real aggregate composition. Weighted
	# roles allow scarce high-impact armor or artillery to define how a combined force
	# is read without drawing a tank, gun, mount, or soldier for every cohort.
	var weights:Dictionary={"infantry":0.0,"mobile":0.0,"artillery":0.0,"armored":0.0}
	for formation_variant in (army.get("formations",[]) as Array):
		var formation:Dictionary=formation_variant
		var count:=maxf(0.0,float(formation.get("count",0)))
		var unit:=String(formation.get("unit","levy"))
		if unit=="armored_formation": weights.armored=float(weights.armored)+count*4.0
		elif unit in ["motorized_infantry","cavalry"]: weights.mobile=float(weights.mobile)+count*1.65
		elif unit in ["siege_engineer","field_artillery","modern_artillery"]: weights.artillery=float(weights.artillery)+count*3.25
		else: weights.infantry=float(weights.infantry)+count
	var role:="infantry"
	var highest:=float(weights.infantry)
	for candidate in ["mobile","artillery","armored"]:
		if float(weights[candidate])>highest:
			role=candidate
			highest=float(weights[candidate])
	return role


static func formation_era(army:Dictionary)->int:
	# A bounded capability band changes counter finish, never its scene complexity.
	# 0 pre-gunpowder, 1 gunpowder, 2 industrial, 3 mechanized/modern.
	var era:=0
	for formation_variant in (army.get("formations",[]) as Array):
		var unit:=String((formation_variant as Dictionary).get("unit","levy"))
		if unit in ["motorized_infantry","armored_formation","modern_artillery"]: era=maxi(era,3)
		elif unit in ["rifle_infantry","machine_gun_company"]: era=maxi(era,2)
		elif unit in ["siege_engineer","field_artillery"]: era=maxi(era,1)
	return era


static func build_snapshot(camera_size:float,armies:Array,foreign_sightings:Array,fronts:Array,destinations:Array,engagement:Dictionary={},selected_army_id:int=0)->Dictionary:
	var band:=scale_band(camera_size)
	var player:Array[Dictionary]=[]
	for index in mini(armies.size(),MAX_PLAYER_MARKERS):
		player.append(player_marker(armies[index],camera_size,int((armies[index] as Dictionary).get("army_id",0))==selected_army_id))
	var foreign:Array[Dictionary]=[]
	for index in mini(foreign_sightings.size(),MAX_FOREIGN_MARKERS):
		foreign.append(foreign_marker(foreign_sightings[index],camera_size))
	var destination_by_id:Dictionary={}
	for destination_variant in destinations:
		var destination:Dictionary=destination_variant
		destination_by_id[String(destination.get("id",""))]=destination
	var front_views:Array[Dictionary]=[]
	var engagement_target:=String((engagement.get("threat",{}) as Dictionary).get("target_region_id",""))
	if engagement_target=="": engagement_target="player_home"
	for index in mini(fronts.size(),MAX_FRONT_MARKERS):
		var front:Dictionary=fronts[index]
		var target_id:=String(front.get("target_region_id",""))
		if target_id=="": target_id="player_home"
		var destination:Dictionary=destination_by_id.get(target_id,{})
		# Never synthesize coordinates for an unknown objective. Defensive fronts may
		# legitimately fall back to the already-known home settlement.
		if destination.is_empty(): continue
		front_views.append(front_marker(front,destination,camera_size,not engagement.is_empty() and target_id==engagement_target))
	_apply_formation_label_budget(player,camera_size,true)
	_apply_formation_label_budget(foreign,camera_size,false)
	_apply_front_label_budget(front_views,camera_size)
	_suppress_player_labels_behind_fronts(player,front_views,camera_size)
	return {"band":band,"marker_scale":marker_scale(camera_size),"player":player,"foreign":foreign,"fronts":front_views,"bounded":true,"limits":{"player":MAX_PLAYER_MARKERS,"foreign":MAX_FOREIGN_MARKERS,"fronts":MAX_FRONT_MARKERS}}


static func _apply_formation_label_budget(views:Array[Dictionary],camera_size:float,player_owned:bool)->void:
	var band:=scale_band(camera_size)
	var budget:=0
	if player_owned:
		budget=6 if band=="local" else (5 if band=="regional" else (3 if band=="continental" else 0))
	else:
		budget=6 if band=="local" else (4 if band=="regional" else 0)
	for view in views: view["show_label"]=false
	if budget<=0: return
	var clusters:=_cluster_views(views,maxf(2.5,camera_size*(0.035 if band=="local" else 0.065)))
	var leaders:Array[Dictionary]=[]
	for cluster_variant in clusters:
		var cluster:Array=cluster_variant
		cluster.sort_custom(func(a:int,b:int)->bool: return _formation_priority(views[a],player_owned)>_formation_priority(views[b],player_owned))
		var leader_index:int=cluster[0]
		var leader:=views[leader_index]
		leader["label_priority"]=_formation_priority(leader,player_owned)
		leader["cluster_count"]=cluster.size()
		if cluster.size()>1:
			leader["label"]=_aggregate_formation_label(cluster,views,band,player_owned)
		leaders.append({"index":leader_index,"priority":int(leader.get("label_priority",0))})
	leaders.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.priority)>int(b.priority))
	for index in mini(budget,leaders.size()):
		views[int(leaders[index].index)]["show_label"]=true


static func _apply_front_label_budget(views:Array[Dictionary],camera_size:float)->void:
	var band:=scale_band(camera_size)
	var budget:=3 if band=="local" else (4 if band in ["regional","continental","world"] else 0)
	for view in views: view["show_label"]=false
	if budget<=0: return
	var clusters:=_cluster_views(views,maxf(3.0,camera_size*0.07))
	var leaders:Array[Dictionary]=[]
	for cluster_variant in clusters:
		var cluster:Array=cluster_variant
		cluster.sort_custom(func(a:int,b:int)->bool: return _front_priority(views[a])>_front_priority(views[b]))
		var leader_index:int=cluster[0]
		var leader:=views[leader_index]
		leader["label_priority"]=_front_priority(leader)
		leader["cluster_count"]=cluster.size()
		if cluster.size()>1:
			leader["label"]=_aggregate_front_label(cluster,views,band)
		leaders.append({"index":leader_index,"priority":int(leader.get("label_priority",0))})
	leaders.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.priority)>int(b.priority))
	for index in mini(budget,leaders.size()):
		views[int(leaders[index].index)]["show_label"]=true


static func _suppress_player_labels_behind_fronts(player:Array[Dictionary],fronts:Array[Dictionary],camera_size:float)->void:
	var band:=scale_band(camera_size)
	if band not in ["regional","continental"]: return
	var threshold:=maxf(4.0,camera_size*0.055)
	for player_view in player:
		if not bool(player_view.get("show_label",false)): continue
		if bool(player_view.get("selected",false)) or bool(player_view.get("moving",false)): continue
		for front_view in fronts:
			if bool(front_view.get("show_label",false)) and _view_distance(player_view,front_view)<=threshold:
				player_view["show_label"]=false
				break


static func _cluster_views(views:Array[Dictionary],threshold:float)->Array:
	var clusters:Array=[]
	var assigned:Dictionary={}
	for index in views.size():
		if assigned.has(index) or not bool(views[index].get("visible",false)): continue
		var cluster:Array=[index]; assigned[index]=true
		var changed:=true
		while changed:
			changed=false
			for candidate in views.size():
				if assigned.has(candidate) or not bool(views[candidate].get("visible",false)): continue
				for member in cluster:
					if _view_distance(views[candidate],views[member])<=threshold:
						cluster.append(candidate); assigned[candidate]=true; changed=true; break
		clusters.append(cluster)
	return clusters


static func _view_distance(a:Dictionary,b:Dictionary)->float:
	var a_position:Dictionary=a.get("position",{})
	var b_position:Dictionary=b.get("position",{})
	return Vector2(float(a_position.get("x",0.0)),float(a_position.get("z",0.0))).distance_to(Vector2(float(b_position.get("x",0.0)),float(b_position.get("z",0.0))))


static func _formation_priority(view:Dictionary,player_owned:bool)->int:
	var priority:=int(view.get("troops",view.get("strength_high",0)))
	if bool(view.get("selected",false)): priority+=1_000_000_000
	if bool(view.get("moving",false)): priority+=500_000_000
	if not player_owned and bool(view.get("hostile",false)): priority+=250_000_000
	if not player_owned and bool(view.get("scout",false)): priority+=125_000_000
	return priority


static func _front_priority(view:Dictionary)->int:
	return (1_000_000_000 if bool(view.get("engagement",false)) else 0)+int(view.get("field_personnel",0))+roundi(float(view.get("progress",0.0))*10_000.0)


static func _aggregate_formation_label(cluster:Array,views:Array[Dictionary],band:String,player_owned:bool)->String:
	var total_low:=0
	var total_high:=0
	var readiness_low:=1.25
	var readiness_high:=0.0
	var moving:=0
	for index in cluster:
		var view:=views[index]
		total_low+=int(view.get("troops",view.get("strength_low",0)))
		total_high+=int(view.get("troops",view.get("strength_high",0)))
		readiness_low=minf(readiness_low,float(view.get("readiness",view.get("readiness_low",0.0))))
		readiness_high=maxf(readiness_high,float(view.get("readiness",view.get("readiness_high",0.0))))
		if bool(view.get("moving",false)): moving+=1
	var owner:="YOU" if player_owned else "FOREIGN"
	var strength:=compact_count(total_low) if player_owned else "~%s–%s" % [compact_count(total_low),compact_count(total_high)]
	var movement:=" • %d MOVING" % moving if moving>0 else ""
	if band=="continental": return "%s • %d ARMIES • %s%s" % [owner,cluster.size(),strength,movement]
	return "%s • %d ARMIES • %s\nREADINESS %d–%d%%%s" % [owner,cluster.size(),strength,roundi(readiness_low*100.0),roundi(readiness_high*100.0),movement]


static func _aggregate_front_label(cluster:Array,views:Array[Dictionary],band:String)->String:
	var battles:=0
	var total_progress:=0.0
	for index in cluster:
		var view:=views[index]
		if bool(view.get("engagement",false)): battles+=1
		total_progress+=float(view.get("progress",0.0))
	var progress:=roundi(total_progress/maxf(1.0,float(cluster.size()))*100.0)
	if band=="world": return "%d ACTIVE WARS\n%d BATTLES • OBJECTIVES %d%%" % [cluster.size(),battles,progress]
	return "%d ACTIVE FRONTS\n%d BATTLES • OBJECTIVES %d%%" % [cluster.size(),battles,progress]


static func player_marker(army:Dictionary,camera_size:float,selected:bool=false)->Dictionary:
	var band:=scale_band(camera_size)
	var troops:=maxi(0,int(army.get("troops",0)))
	var readiness:=clampf(float(army.get("readiness",0.0)),0.0,1.25)
	var supply:=clampf(float(army.get("supply_level",0.0)),0.0,1.0)
	var moving:=String(army.get("status","stationed"))=="moving"
	var destination:=String(army.get("destination_name",army.get("location_name","HOME"))) if moving else String(army.get("location_name","HOME"))
	var readiness_text:=readiness_band(readiness)
	var label:=""
	if band=="local":
		label="%s • %s\n%s %d%% • SUPPLY %d%%\n%s" % [String(army.get("name","FIELD ARMY")).to_upper(),compact_count(troops),readiness_text,roundi(readiness*100.0),roundi(supply*100.0),("→ %s • D%d" % [destination.to_upper(),int(army.get("arrival_day",0))]) if moving else destination.to_upper()]
	elif band=="regional":
		label="YOU • %s • %s %d%%\n%s" % [compact_count(troops),readiness_text,roundi(readiness*100.0),("→ %s" % destination.to_upper()) if moving else destination.to_upper()]
	elif band=="continental":
		label="YOU %s • R%d%s" % [compact_count(troops),roundi(readiness*100.0)," →" if moving else ""]
	var position_data:Dictionary=(army.get("position",{}) as Dictionary).duplicate(true)
	var destination_data:Dictionary=(army.get("destination_position",{}) as Dictionary).duplicate(true)
	var heading:=0.0
	if moving and destination_data.has("x") and destination_data.has("z"):
		var heading_delta:=Vector2(float(destination_data.get("x",0.0))-float(position_data.get("x",0.0)),float(destination_data.get("z",0.0))-float(position_data.get("z",0.0)))
		if heading_delta.length_squared()>0.000001: heading=-heading_delta.angle()-PI*0.5
	return {
		"id":str(int(army.get("army_id",0))),"owner":"player","owner_label":"YOU","visible":band not in ["ground","world"],
		"show_label":band in ["local","regional"] or (band=="continental" and (selected or moving)),"label":label,
		"selected":selected,"moving":moving,"color":PLAYER_SELECTED_COLOR if selected else PLAYER_COLOR,
		"troops":troops,"echelon":formation_echelon(troops),"formation_role":formation_role(army),"formation_era":formation_era(army),"readiness":readiness,"readiness_band":readiness_text,"readiness_color":readiness_color(readiness),"supply":supply,"supply_color":supply_color(supply),
		"position":position_data,"destination_id":String(army.get("destination_id","")),"heading":heading,
		"destination_name":destination,
		"destination_position":destination_data,"distance_remaining_km":float(army.get("distance_remaining_km",0.0)),
		"arrival_day":int(army.get("arrival_day",-1)),"scale":marker_scale(camera_size),"show_path":moving and band in ["local","regional","continental"]
	}


static func foreign_marker(sighting:Dictionary,camera_size:float)->Dictionary:
	var band:=scale_band(camera_size)
	var hostile:=bool(sighting.get("hostile",false))
	var scout:=bool(sighting.get("carries_report",false))
	var identified:=bool(sighting.get("identified",false))
	var low:=maxi(0,int(sighting.get("strength_estimate_low",0)))
	var high:=maxi(low,int(sighting.get("strength_estimate_high",low)))
	var readiness_low:=clampf(float(sighting.get("readiness_estimate_low",0.0)),0.0,1.25)
	var readiness_high:=clampf(float(sighting.get("readiness_estimate_high",readiness_low)),readiness_low,1.25)
	var owner:=String(sighting.get("civilization","FOREIGN")) if identified else "UNIDENTIFIED"
	var label:=""
	if band=="local":
		label="%s\n~%s–%s OBSERVED\nR~%d–%d%% • %.0f KM%s" % [owner.to_upper(),compact_count(low),compact_count(high),roundi(readiness_low*100.0),roundi(readiness_high*100.0),float(sighting.get("distance_km",0.0))," • REPORT" if scout else ""]
	elif band=="regional":
		label="%s • ~%s–%s\nR~%d–%d%%" % [owner.to_upper(),compact_count(low),compact_count(high),roundi(readiness_low*100.0),roundi(readiness_high*100.0)]
	return {
		"id":String(sighting.get("id","")),"owner":String(sighting.get("civ_id","")),"owner_label":owner.to_upper(),"visible":band in ["local","regional"],
		"show_label":band in ["local","regional"],"label":label,"selected":false,"moving":true,
		"color":HOSTILE_COLOR if hostile else (SCOUT_COLOR if scout else FOREIGN_COLOR),"hostile":hostile,"scout":scout,"identified":identified,
		"strength_low":low,"strength_high":high,"echelon":formation_echelon(high),"readiness_low":readiness_low,"readiness_high":readiness_high,
		"readiness_color":readiness_color((readiness_low+readiness_high)*0.5),"position":(sighting.get("position",{}) as Dictionary).duplicate(true),"scale":marker_scale(camera_size)
	}


static func front_marker(front:Dictionary,destination:Dictionary,camera_size:float,engagement_active:bool=false)->Dictionary:
	var band:=scale_band(camera_size)
	var progress:=clampf(float(front.get("progress",0.0)),0.0,1.0)
	var readiness:=clampf(float(front.get("readiness",0.0)),0.0,1.25)
	var fielded:=maxi(0,int(front.get("field_personnel",0)))+maxi(0,int(front.get("inbound_personnel",0)))+maxi(0,int(front.get("occupation_personnel",0)))
	var label:=""
	if band=="world":
		label="%s\n%s • %d%%" % [String(front.get("war_name","ACTIVE WAR")).to_upper(),"BATTLE" if engagement_active else "OBJECTIVE",roundi(progress*100.0)]
	elif band=="continental":
		label="%s\n%s • %d%%" % [String(front.get("opponent","WAR FRONT")).to_upper(),String(front.get("objective","OBJECTIVE")).to_upper(),roundi(progress*100.0)]
	elif band=="regional":
		label="%s\n%s • %d%% • FIELD %s" % ["BATTLE IN PROGRESS" if engagement_active else String(front.get("war_name","ACTIVE FRONT")).to_upper(),String(front.get("objective","OBJECTIVE")).to_upper(),roundi(progress*100.0),compact_count(fielded)]
	elif band=="local":
		label="%s • %s %d%%\nFIELD %s\nREADY %d%% • SUPPLY %d%%" % ["BATTLE" if engagement_active else String(front.get("war_name","ACTIVE FRONT")).to_upper(),String(front.get("target","HOME TERRITORY")).to_upper(),roundi(progress*100.0),compact_count(fielded),roundi(readiness*100.0),roundi(clampf(float(front.get("supply",0.0)),0.0,1.0)*100.0)]
	return {
		"id":String(front.get("id","")),"visible":band!="ground","show_label":band!="ground","label":label,
		"engagement":engagement_active,"color":ENGAGEMENT_COLOR if engagement_active else FRONT_COLOR,
		"attacker_color":PLAYER_COLOR,"defender_color":HOSTILE_COLOR,"progress":progress,"field_personnel":fielded,
		"readiness":readiness,"readiness_color":readiness_color(readiness),"target_region_id":String(front.get("target_region_id","")),"position":(destination.get("position",{}) as Dictionary).duplicate(true),"scale":marker_scale(camera_size)*1.05
	}


static func readiness_band(value:float)->String:
	if value>=0.72: return "READY"
	if value>=0.45: return "FORMING"
	return "UNREADY"


static func readiness_color(value:float)->String:
	if value>=0.72: return "#75C18B"
	if value>=0.45: return "#D5AD58"
	return "#D86F62"


static func supply_color(value:float)->String:
	if value>=0.66: return "#76B99A"
	if value>=0.34: return "#D0A85B"
	return "#D76559"


static func compact_count(value:int)->String:
	if value>=1_000_000_000: return "%.2fB" % (float(value)/1_000_000_000.0)
	if value>=1_000_000: return "%.2fM" % (float(value)/1_000_000.0)
	if value>=1_000: return "%.1fK" % (float(value)/1_000.0)
	return str(value)
