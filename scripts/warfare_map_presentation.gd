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
	# Orthographic scale should keep a marker near one stable screen footprint.
	# The former 0.45 floor made counters enormous when zoomed in, immediately
	# before the presentation layer hid them altogether.
	return clampf(camera_size*0.016,0.0005,32.0)


static func marker_ground_clearance(camera_size:float)->float:
	# Coordinates are kilometres: a fixed .18 lift floats a close counter 180m
	# above its formation. Retain regional clearance, scale it down for inspection.
	return clampf(camera_size*0.0008,0.0005,0.18)


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


static func dominant_unit(army:Dictionary)->String:
	var dominant:="levy"
	var highest:=-1
	for formation_variant in (army.get("formations",[]) as Array):
		var formation:Dictionary=formation_variant
		var count:=maxi(0,int(formation.get("count",0)))
		if count>highest:
			highest=count
			dominant=String(formation.get("unit","levy"))
	return dominant


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


static func formation_damage_ratio(army:Dictionary)->float:
	# One aggregate wear signal drives the counter. Casualties never create corpses or
	# individual damaged-unit nodes; wounded, scattered, captured, recent losses and
	# equipment condition are summarized into a bounded visual state.
	var active:=maxf(0.0,float(army.get("troops",0)))
	var disrupted:=maxf(0.0,float(army.get("wounded_pool",0)))+maxf(0.0,float(army.get("scattered_pool",0)))+maxf(0.0,float(army.get("captured_pool",0)))
	var ratio:=disrupted/maxf(1.0,active+disrupted)
	var formation_weight:=0.0
	var condition_total:=0.0
	for formation_variant in (army.get("formations",[]) as Array):
		var formation:Dictionary=formation_variant
		var weight:=maxf(1.0,float(formation.get("count",0)))
		var condition:=clampf(float(formation.get("equipment_condition",formation.get("condition",1.0))),0.0,1.0)
		formation_weight+=weight
		condition_total+=condition*weight
	if formation_weight>0.0: ratio=maxf(ratio,(1.0-condition_total/formation_weight)*0.72)
	if int(army.get("recent_combat_days",0))>0: ratio=maxf(ratio,0.12)
	return clampf(ratio,0.0,1.0)


static func formation_visual_state(army:Dictionary)->Dictionary:
	var readiness:=clampf(float(army.get("readiness",0.0)),0.0,1.25)
	var damage:=formation_damage_ratio(army)
	var order_state:="ordered" if readiness>=0.72 else ("steady" if readiness>=0.52 else ("ragged" if readiness>=0.30 else "broken"))
	var damage_state:="intact" if damage<0.10 else ("worn" if damage<0.30 else ("damaged" if damage<0.62 else "shattered"))
	return {"order_state":order_state,"damage_state":damage_state,"damage_ratio":damage,"scatter":clampf(1.0-readiness,0.0,0.78),"missing_elements":clampi(floori(damage*4.0),0,3),"element_budget":7}


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
	_apply_counter_stack_offsets(player,camera_size,true)
	_apply_counter_stack_offsets(foreign,camera_size,false)
	_apply_cross_faction_counter_lanes(player,foreign,camera_size)
	_apply_front_label_budget(front_views,camera_size)
	_suppress_formation_labels_behind_fronts(player,front_views,camera_size,true)
	_suppress_formation_labels_behind_fronts(foreign,front_views,camera_size,false)
	return {"band":band,"marker_scale":marker_scale(camera_size),"player":player,"foreign":foreign,"fronts":front_views,"bounded":true,"limits":{"player":MAX_PLAYER_MARKERS,"foreign":MAX_FOREIGN_MARKERS,"fronts":MAX_FRONT_MARKERS}}


static func _apply_counter_stack_offsets(views:Array[Dictionary],camera_size:float,player_owned:bool)->void:
	# Counters remain aggregate and fixed in number, but formations occupying the same
	# reported map point must not z-fight into an unclickable pile. A bounded four-column
	# fan separates the symbols around their true position; the lead label still reports
	# the aggregate cluster.
	for view in views: view["display_offset"]={"x":0.0,"z":0.0}
	if views.size()<2: return
	var counter_scale:=marker_scale(camera_size)
	var clusters:=_cluster_views(views,maxf(minf(0.8,camera_size*0.08),counter_scale*5.4))
	for cluster_variant in clusters:
		var cluster:Array=cluster_variant
		if cluster.size()<2: continue
		cluster.sort_custom(func(a:int,b:int)->bool: return _formation_priority(views[a],player_owned)>_formation_priority(views[b],player_owned))
		var columns:=mini(4,cluster.size())
		# One slot is wider/deeper than the complete counter backing plate. Stacked
		# formations fan into genuinely separate click targets instead of merely avoiding
		# exact z-fighting while their symbols still overlap.
		var spacing:=counter_scale*6.75
		for stack_index in cluster.size():
			var column:=stack_index%columns
			var row:=stack_index/columns
			var x_offset:=(float(column)-float(columns-1)*0.5)*spacing
			var z_offset:=(float(row)-0.25)*spacing*0.78
			views[int(cluster[stack_index])]["display_offset"]={"x":x_offset,"z":z_offset}


static func _apply_cross_faction_counter_lanes(player:Array[Dictionary],foreign:Array[Dictionary],camera_size:float)->void:
	# Friendly and foreign stacks are laid out separately above. A contested point still
	# needs two faction lanes or the two independently valid layouts can land on top of
	# one another. The displacement is screen-scale bounded and never changes simulation
	# coordinates, movement distance, or combat membership.
	if player.is_empty() or foreign.is_empty(): return
	var proximity:=maxf(minf(2.5,camera_size*0.10),marker_scale(camera_size)*6.4)
	var player_contested:Dictionary={}
	var foreign_contested:Dictionary={}
	for player_index in player.size():
		if not bool(player[player_index].get("visible",false)): continue
		for foreign_index in foreign.size():
			if not bool(foreign[foreign_index].get("visible",false)): continue
			if _raw_view_distance(player[player_index],foreign[foreign_index])<=proximity:
				player_contested[player_index]=true
				foreign_contested[foreign_index]=true
				if bool(player[player_index].get("show_label",false)) and bool(foreign[foreign_index].get("show_label",false)):
					if bool(player[player_index].get("selected",false)) or not bool(foreign[foreign_index].get("hostile",false)):
						foreign[foreign_index]["show_label"]=false
						foreign[foreign_index]["label_suppressed_by_contact"]=true
					else:
						player[player_index]["show_label"]=false
						player[player_index]["label_suppressed_by_contact"]=true
	var lane_shift:=marker_scale(camera_size)*3.75
	for player_index_variant in player_contested.keys():
		var player_index:=int(player_index_variant)
		var offset:Dictionary=player[player_index].get("display_offset",{})
		offset["x"]=float(offset.get("x",0.0))-lane_shift
		player[player_index]["display_offset"]=offset
		player[player_index]["contested_location"]=true
	for foreign_index_variant in foreign_contested.keys():
		var foreign_index:=int(foreign_index_variant)
		var offset:Dictionary=foreign[foreign_index].get("display_offset",{})
		offset["x"]=float(offset.get("x",0.0))+lane_shift
		foreign[foreign_index]["display_offset"]=offset
		foreign[foreign_index]["contested_location"]=true


static func _apply_formation_label_budget(views:Array[Dictionary],camera_size:float,player_owned:bool)->void:
	var band:=scale_band(camera_size)
	var budget:=0
	if player_owned:
		budget=6 if band in ["ground","local"] else (5 if band=="regional" else (3 if band=="continental" else 0))
	else:
		budget=6 if band in ["ground","local"] else (4 if band=="regional" else 0)
	for view in views: view["show_label"]=false
	if budget<=0: return
	var clusters:=_cluster_views(views,maxf(minf(0.5,camera_size*0.035),camera_size*(0.035 if band in ["ground","local"] else 0.065)))
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


static func _suppress_formation_labels_behind_fronts(formations:Array[Dictionary],fronts:Array[Dictionary],camera_size:float,player_owned:bool)->void:
	var band:=scale_band(camera_size)
	if band not in ["local","regional","continental"]: return
	var threshold:=maxf(4.0,camera_size*0.055)
	for formation_view in formations:
		if not bool(formation_view.get("show_label",false)): continue
		for front_view in fronts:
			if not bool(front_view.get("show_label",false)) or _view_distance(formation_view,front_view)>threshold: continue
			# The formation the player is actively commanding wins the local label slot.
			# Otherwise the named battle/front summarizes the armies already represented by
			# their counters and owns that patch of screen.
			if player_owned and bool(formation_view.get("selected",false)):
				front_view["show_label"]=false
			else:
				formation_view["show_label"]=false
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
	var a_offset:Dictionary=a.get("display_offset",{})
	var b_offset:Dictionary=b.get("display_offset",{})
	return Vector2(float(a_position.get("x",0.0))+float(a_offset.get("x",0.0)),float(a_position.get("z",0.0))+float(a_offset.get("z",0.0))).distance_to(Vector2(float(b_position.get("x",0.0))+float(b_offset.get("x",0.0)),float(b_position.get("z",0.0))+float(b_offset.get("z",0.0))))


static func _raw_view_distance(a:Dictionary,b:Dictionary)->float:
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
	var visual_state:=formation_visual_state(army)
	var damage_text:="" if String(visual_state.damage_state)=="intact" else " • %s" % String(visual_state.damage_state).to_upper()
	var strength_text:="%s SOLDIERS" % compact_count(troops)
	var label:=""
	if band in ["ground","local"]:
		label="YOU · %s · %s\n%s %d%% · SUPPLY %d%%%s%s" % [String(army.get("name","FIELD ARMY")).to_upper(),strength_text,readiness_text,roundi(readiness*100.0),roundi(supply*100.0),damage_text,(" · → %s" % destination.to_upper()) if moving else ""]
	elif band=="regional":
		label="YOU • %s • %s %d%%%s\n%s" % [strength_text,readiness_text,roundi(readiness*100.0),damage_text,("→ %s" % destination.to_upper()) if moving else destination.to_upper()]
	elif band=="continental":
		label="YOU • %s • %d%% READY%s%s" % [strength_text,roundi(readiness*100.0),damage_text," →" if moving else ""]
	var position_data:Dictionary=(army.get("position",{}) as Dictionary).duplicate(true)
	var destination_data:Dictionary=(army.get("destination_position",{}) as Dictionary).duplicate(true)
	var heading:=0.0
	if moving and destination_data.has("x") and destination_data.has("z"):
		var heading_delta:=Vector2(float(destination_data.get("x",0.0))-float(position_data.get("x",0.0)),float(destination_data.get("z",0.0))-float(position_data.get("z",0.0)))
		if heading_delta.length_squared()>0.000001: heading=-heading_delta.angle()-PI*0.5
	return {
		"id":str(int(army.get("army_id",0))),"owner":"player","owner_label":"YOU","visible":band!="world",
		"show_label":band in ["ground","local","regional"] or (band=="continental" and (selected or moving)),"label":label,
		# Selection is the gold outer ring, never a temporary change of faction color.
		# Keeping the counter blue makes ownership stable while orders are being issued.
		"selected":selected,"moving":moving,"color":PLAYER_COLOR,"selection_color":PLAYER_SELECTED_COLOR,
		"troops":troops,"echelon":formation_echelon(troops),"formation_role":formation_role(army),"formation_unit":dominant_unit(army),"formation_era":formation_era(army),"readiness":readiness,"readiness_band":readiness_text,"readiness_color":readiness_color(readiness),"supply":supply,"supply_color":supply_color(supply),
		"order_state":visual_state.order_state,"damage_state":visual_state.damage_state,"damage_ratio":visual_state.damage_ratio,"scatter":visual_state.scatter,"missing_elements":visual_state.missing_elements,"visual_element_budget":visual_state.element_budget,
		"position":position_data,"destination_id":String(army.get("destination_id","")),"heading":heading,
		"destination_name":destination,
		"destination_position":destination_data,"distance_remaining_km":float(army.get("distance_remaining_km",0.0)),
		"arrival_day":int(army.get("arrival_day",-1)),"scale":marker_scale(camera_size),"show_path":moving and band in ["local","regional","continental"],
		# The selected formation label already names its destination and arrival day. A
		# second label at the path endpoint competes with battle/front text and turns one
		# order into two overlapping paragraphs. The ring and chevrons carry the endpoint.
		"show_objective_label":false
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
	var readiness_mid:=(readiness_low+readiness_high)*0.5
	var damage_ratio:=clampf(float(sighting.get("damage_estimate",sighting.get("damage_ratio",0.0))),0.0,1.0)
	var order_state:="ordered" if readiness_mid>=0.72 else ("steady" if readiness_mid>=0.52 else ("ragged" if readiness_mid>=0.30 else "broken"))
	var damage_state:="intact" if damage_ratio<0.10 else ("worn" if damage_ratio<0.30 else ("damaged" if damage_ratio<0.62 else "shattered"))
	var observed_role:=String(sighting.get("formation_role","unknown")) if identified else "unknown"
	var observed_era:=clampi(int(sighting.get("formation_era",0)),0,3) if identified else 0
	var owner:=String(sighting.get("civilization","FOREIGN")) if identified else "UNIDENTIFIED"
	var moving:=bool(sighting.get("moving",sighting.get("movement_observed",false)))
	var damage_text:="" if damage_state=="intact" else " • %s" % damage_state.to_upper()
	var label:=""
	if band in ["ground","local"]:
		label="%s · ~%s–%s SOLDIERS%s\n%s" % ["FOREIGN SCOUTS" if scout and not identified else owner.to_upper(),compact_count(low),compact_count(high),damage_text,"CLICK TO INTERCEPT" if scout else ("ENEMY · CLICK TO ENGAGE" if hostile else "CLICK FOR CONTACT")]
	elif band=="regional":
		label="%s · ~%s–%s SOLDIERS%s\n%s" % ["FOREIGN SCOUTS" if scout and not identified else owner.to_upper(),compact_count(low),compact_count(high),damage_text,"CLICK TO INTERCEPT" if scout else ("ENEMY · CLICK TO ENGAGE" if hostile else "CLICK FOR CONTACT")]
	return {
		"id":String(sighting.get("id","")),"owner":String(sighting.get("civ_id","")),"owner_label":owner.to_upper(),"visible":band in ["ground","local","regional"],
		"show_label":band in ["ground","local","regional"],"label":label,"selected":false,"moving":moving,"heading":float(sighting.get("heading",0.0)),
		"color":HOSTILE_COLOR if hostile else (SCOUT_COLOR if scout else FOREIGN_COLOR),"hostile":hostile,"scout":scout,"identified":identified,
		"strength_low":low,"strength_high":high,"echelon":formation_echelon(high),"readiness_low":readiness_low,"readiness_high":readiness_high,
		"formation_role":observed_role,"formation_unit":String(sighting.get("formation_unit",observed_role)),"formation_era":observed_era,
		"order_state":order_state,"damage_state":damage_state,"damage_ratio":damage_ratio,"scatter":clampf(1.0-readiness_mid,0.0,0.78),"missing_elements":clampi(floori(damage_ratio*4.0),0,3),"visual_element_budget":7,
		"readiness_color":readiness_color(readiness_mid),"position":(sighting.get("position",{}) as Dictionary).duplicate(true),"scale":marker_scale(camera_size)
	}


static func front_marker(front:Dictionary,destination:Dictionary,camera_size:float,engagement_active:bool=false)->Dictionary:
	var band:=scale_band(camera_size)
	var progress:=clampf(float(front.get("progress",0.0)),0.0,1.0)
	var readiness:=clampf(float(front.get("readiness",0.0)),0.0,1.25)
	var occupation_personnel:=maxi(0,int(front.get("occupation_personnel",0)))
	var fielded:=maxi(0,int(front.get("field_personnel",0)))+maxi(0,int(front.get("inbound_personnel",0)))+occupation_personnel
	var phase:="BATTLE" if engagement_active else ("OCCUPATION" if occupation_personnel>0 else "OBJECTIVE")
	var label:=""
	if band=="world":
		label="%s\n%s • %d%%" % [String(front.get("war_name","ACTIVE WAR")).to_upper(),phase,roundi(progress*100.0)]
	elif band=="continental":
		label="%s\n%s • %s • %d%%" % [String(front.get("opponent","WAR FRONT")).to_upper(),phase,String(front.get("objective","OBJECTIVE")).to_upper(),roundi(progress*100.0)]
	elif band=="regional":
		label="%s\n%s • %d%% • FIELD %s" % ["BATTLE IN PROGRESS" if engagement_active else ("OCCUPATION FRONT" if occupation_personnel>0 else String(front.get("war_name","ACTIVE FRONT")).to_upper()),String(front.get("objective","OBJECTIVE")).to_upper(),roundi(progress*100.0),compact_count(fielded)]
	elif band=="local":
		label="%s • %s %d%%\nFIELD %s\nREADY %d%% • SUPPLY %d%%" % [phase if phase!="OBJECTIVE" else String(front.get("war_name","ACTIVE FRONT")).to_upper(),String(front.get("target","HOME TERRITORY")).to_upper(),roundi(progress*100.0),compact_count(fielded),roundi(readiness*100.0),roundi(clampf(float(front.get("supply",0.0)),0.0,1.0)*100.0)]
	return {
		"id":String(front.get("id","")),"visible":band!="ground","show_label":band!="ground","label":label,
		"engagement":engagement_active,"color":ENGAGEMENT_COLOR if engagement_active else FRONT_COLOR,
		"attacker_color":PLAYER_COLOR,"defender_color":HOSTILE_COLOR,"progress":progress,"field_personnel":fielded,
		"readiness":readiness,"readiness_color":readiness_color(readiness),"occupation_active":occupation_personnel>0,"occupation_personnel":occupation_personnel,"phase":phase,"target_region_id":String(front.get("target_region_id","")),"position":(destination.get("position",{}) as Dictionary).duplicate(true),"scale":marker_scale(camera_size)*1.05
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
