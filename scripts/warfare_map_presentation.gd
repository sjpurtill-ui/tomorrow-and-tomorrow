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

# A formation marker is a heraldic aggregate, not a collection of soldiers.
# Every recipe stays inside this primitive budget regardless of personnel count.
const MAX_FORMATION_VISUAL_ELEMENTS:=7

const ROLE_RECIPES:={
	"infantry":{"label":"INFANTRY","symbol_family":"rank_block","arrangement":"ordered_mass","body_primitive":"block","accent_primitive":"standard","element_budget":5},
	"mobile":{"label":"MOBILE","symbol_family":"maneuver_wedge","arrangement":"forward_wedge","body_primitive":"chevron","accent_primitive":"speed_bar","element_budget":5},
	"artillery":{"label":"ARTILLERY","symbol_family":"battery_line","arrangement":"rear_battery","body_primitive":"barrel","accent_primitive":"range_arc","element_budget":6},
	"armored":{"label":"ARMORED","symbol_family":"armored_wedge","arrangement":"heavy_wedge","body_primitive":"hull","accent_primitive":"turret","element_budget":6},
	"combined":{"label":"COMBINED ARMS","symbol_family":"combined_arms_group","arrangement":"layered_group","body_primitive":"block","accent_primitive":"role_notches","element_budget":7},
	"scout":{"label":"SCOUT","symbol_family":"scout_screen","arrangement":"open_screen","body_primitive":"chevron","accent_primitive":"report_pennant","element_budget":3},
	"unknown":{"label":"UNRESOLVED","symbol_family":"unresolved_column","arrangement":"uncertain_column","body_primitive":"diamond","accent_primitive":"question_notch","element_budget":3}
}

const ERA_RECIPES:={
	"ancient":{"label":"ANCIENT","material_family":"wood_cloth","massing":"host_cluster","height_scale":1.08,"spacing_scale":0.84,"standard_scale":1.18},
	"medieval":{"label":"MEDIEVAL","material_family":"wood_iron_cloth","massing":"shielded_column","height_scale":1.04,"spacing_scale":0.88,"standard_scale":1.12},
	"early_modern":{"label":"EARLY MODERN","material_family":"iron_cloth","massing":"ordered_blocks","height_scale":1.0,"spacing_scale":0.94,"standard_scale":1.02},
	"industrial":{"label":"INDUSTRIAL","material_family":"steel_canvas","massing":"low_mass_line","height_scale":0.92,"spacing_scale":1.04,"standard_scale":0.84},
	"mechanized":{"label":"MECHANIZED","material_family":"steel_rubber","massing":"vehicle_column","height_scale":0.86,"spacing_scale":1.12,"standard_scale":0.62},
	"modern":{"label":"MODERN","material_family":"composite_steel","massing":"dispersed_network","height_scale":0.8,"spacing_scale":1.22,"standard_scale":0.42},
	"unknown":{"label":"ERA UNKNOWN","material_family":"neutral_silhouette","massing":"unresolved","height_scale":1.0,"spacing_scale":1.0,"standard_scale":0.0}
}

const UNIT_ROLES:={
	"levy":"infantry","line_infantry":"infantry","skirmisher":"infantry","rifle_infantry":"infantry",
	"machine_gun_company":"artillery","cavalry":"mobile","motorized_infantry":"mobile",
	"siege_engineer":"artillery","field_artillery":"artillery","modern_artillery":"artillery",
	"armored_formation":"armored"
}

const UNIT_VISUAL_ERAS:={
	"levy":0,"skirmisher":0,"line_infantry":1,"cavalry":1,"siege_engineer":1,
	"field_artillery":2,"rifle_infantry":3,"machine_gun_company":3,
	"motorized_infantry":4,"armored_formation":5,"modern_artillery":5
}

const EQUIPMENT_VISUAL_ERAS:={
	"improvised":0,"spear":0,"bow":0,"sword_shield":1,"lance":1,"siege_kit":1,
	"field_gun":2,"service_rifle":3,"machine_gun":3,"motorized_kit":4,
	"armored_vehicle":5,"modern_field_gun":5
}


static func formation_visual_profile(force:Dictionary)->Dictionary:
	var formations:Array=force.get("formations",[])
	var role_weights:Dictionary=(force.get("role_weights",{}) as Dictionary).duplicate(true)
	var personnel:=0
	var authorized:=0
	var condition_weight:=0.0
	var visual_era_tier:=-1
	for formation_variant in formations:
		var formation:Dictionary=formation_variant
		var count:=maxi(0,int(formation.get("count",0)))
		var authorized_count:=maxi(count,int(formation.get("authorized_count",count)))
		var unit:=String(formation.get("unit",formation.get("unit_id","")))
		var equipment:=String(formation.get("weapon",formation.get("equipment_id","")))
		var role:=String(UNIT_ROLES.get(unit,"unknown"))
		role_weights[role]=int(role_weights.get(role,0))+count
		personnel+=count
		authorized+=authorized_count
		condition_weight+=float(count)*clampf(float(formation.get("personnel_condition",1.0)),0.0,1.0)
		visual_era_tier=maxi(visual_era_tier,maxi(int(UNIT_VISUAL_ERAS.get(unit,-1)),int(EQUIPMENT_VISUAL_ERAS.get(equipment,-1))))
	var hint:=String(force.get("role_hint",force.get("role_estimate",""))).to_lower()
	var role:=hint if ROLE_RECIPES.has(hint) and hint!="unknown" else _dominant_role(role_weights)
	if role=="" or not ROLE_RECIPES.has(role): role="unknown"
	if force.has("visual_era_tier"):
		visual_era_tier=maxi(visual_era_tier,clampi(int(force.get("visual_era_tier",-1)),-1,5))
	elif force.has("military_era_tier"):
		visual_era_tier=maxi(visual_era_tier,_development_to_visual_era(int(force.get("military_era_tier",-1))))
	var era:=_visual_era_id(visual_era_tier)
	var role_recipe:Dictionary=(ROLE_RECIPES.get(role,ROLE_RECIPES.unknown) as Dictionary).duplicate(true)
	var era_recipe:Dictionary=(ERA_RECIPES.get(era,ERA_RECIPES.unknown) as Dictionary).duplicate(true)
	var readiness:=clampf(float(force.get("readiness",force.get("readiness_estimate",0.0))),0.0,1.25)
	var condition:=condition_weight/maxf(1.0,float(personnel)) if personnel>0 else clampf(float(force.get("personnel_condition",1.0)),0.0,1.0)
	if personnel<=0:
		personnel=maxi(0,int(force.get("troops",force.get("strength",0))))
		authorized=maxi(personnel,int(force.get("authorized_troops",personnel)))
	var loss_ratio:=1.0-float(personnel)/maxf(1.0,float(authorized)) if authorized>0 else 0.0
	var explicit_damage:=0.0
	var damage_variant:Variant=force.get("damage_ratio",force.get("damage",0.0))
	if damage_variant is int or damage_variant is float: explicit_damage=clampf(float(damage_variant),0.0,1.0)
	var damage_ratio:=clampf(maxf(explicit_damage,maxf(loss_ratio,(1.0-condition)*0.82)),0.0,1.0)
	var readiness_state:=_readiness_state(readiness)
	var damage_state:=_damage_state(damage_ratio)
	var element_budget:=mini(MAX_FORMATION_VISUAL_ELEMENTS,int(role_recipe.get("element_budget",3)))
	var missing_elements:=mini(maxi(0,element_budget-1),floori(damage_ratio*float(element_budget)*0.78))
	return {
		"role":role,"role_label":String(role_recipe.label),"era":era,"era_label":String(era_recipe.label),
		"era_tier":visual_era_tier,"era_known":visual_era_tier>=0,"symbol_family":String(role_recipe.symbol_family),
		"arrangement":String(role_recipe.arrangement),"body_primitive":String(role_recipe.body_primitive),"accent_primitive":String(role_recipe.accent_primitive),
		"material_family":String(era_recipe.material_family),"massing":String(era_recipe.massing),
		"height_scale":float(era_recipe.height_scale),"spacing_scale":float(era_recipe.spacing_scale),"standard_scale":float(era_recipe.standard_scale),
		"readiness":readiness,"readiness_state":readiness_state,"scatter":_readiness_scatter(readiness_state),
		"damage_ratio":damage_ratio,"damage_state":damage_state,"missing_elements":missing_elements,
		"darkening":damage_ratio*0.38,"desaturation":damage_ratio*0.55,"fractured":damage_state in ["battered","broken"],
		"element_budget":element_budget,"visible_elements":maxi(1,element_budget-missing_elements),"bounded":true
	}


static func _dominant_role(weights:Dictionary)->String:
	var ranked:Array[Dictionary]=[]
	var total:=0
	for role_variant in weights:
		var role:=String(role_variant)
		var weight:=maxi(0,int(weights[role_variant]))
		if weight<=0: continue
		total+=weight
		ranked.append({"role":role if ROLE_RECIPES.has(role) else "unknown","weight":weight})
	if ranked.is_empty(): return "unknown"
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.weight)>int(b.weight))
	var first:Dictionary=ranked[0]
	if String(first.role)=="unknown": return "unknown"
	if ranked.size()>1 and float(first.weight)/maxf(1.0,float(total))<0.72 and int((ranked[1] as Dictionary).weight)>=maxi(1,roundi(float(total)*0.18)):
		return "combined"
	return String(first.role)


static func _development_to_visual_era(tier:int)->int:
	if tier<0: return -1
	if tier<=1: return 0
	if tier==2: return 1
	if tier<=4: return 2
	if tier==5: return 3
	if tier==6: return 4
	return 5


static func _visual_era_id(tier:int)->String:
	match tier:
		0: return "ancient"
		1: return "medieval"
		2: return "early_modern"
		3: return "industrial"
		4: return "mechanized"
		5: return "modern"
	return "unknown"


static func _readiness_state(value:float)->String:
	if value>=0.72: return "ordered"
	if value>=0.45: return "uneven"
	return "disordered"


static func _readiness_scatter(state:String)->float:
	if state=="ordered": return 0.08
	if state=="uneven": return 0.22
	return 0.42


static func _damage_state(value:float)->String:
	if value>=0.72: return "broken"
	if value>=0.42: return "battered"
	if value>=0.16: return "worn"
	return "intact"


static func scale_band(camera_size:float)->String:
	if camera_size<8.0: return "ground"
	if camera_size<=80.0: return "local"
	if camera_size<=800.0: return "regional"
	if camera_size<=8000.0: return "continental"
	return "world"


static func marker_scale(camera_size:float)->float:
	return clampf(camera_size*0.016,0.45,32.0)


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
			var aggregate_profile:=_aggregate_formation_visual_profile(cluster,views)
			leader["visual_profile"]=aggregate_profile
			leader["role"]=String(aggregate_profile.role)
			leader["era"]=String(aggregate_profile.era)
			leader["symbol_family"]=String(aggregate_profile.symbol_family)
			leader["damage_state"]=String(aggregate_profile.damage_state)
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


static func _aggregate_formation_visual_profile(cluster:Array,views:Array[Dictionary])->Dictionary:
	var role_weights:Dictionary={}
	var total_weight:=0
	var weighted_readiness:=0.0
	var weighted_damage:=0.0
	var era_tier:=-1
	for index in cluster:
		var view:=views[index]
		var profile:Dictionary=view.get("visual_profile",{})
		var weight:=maxi(1,int(view.get("troops",roundi((float(view.get("strength_low",0))+float(view.get("strength_high",0)))*0.5))))
		var role:=String(profile.get("role","unknown"))
		role_weights[role]=int(role_weights.get(role,0))+weight
		total_weight+=weight
		weighted_readiness+=float(profile.get("readiness",0.0))*float(weight)
		weighted_damage+=float(profile.get("damage_ratio",0.0))*float(weight)
		if bool(profile.get("era_known",false)): era_tier=maxi(era_tier,int(profile.get("era_tier",-1)))
	var source:Dictionary={
		"role_weights":role_weights,"readiness":weighted_readiness/maxf(1.0,float(total_weight)),
		"damage_ratio":weighted_damage/maxf(1.0,float(total_weight)),"troops":total_weight
	}
	if era_tier>=0: source["visual_era_tier"]=era_tier
	return formation_visual_profile(source)


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
		label="%s • %s\n%s %d%% • SUPPLY %d%%%s" % [String(army.get("name","FIELD ARMY")).to_upper(),compact_count(troops),readiness_text,roundi(readiness*100.0),roundi(supply*100.0),(" • → %s D%d" % [destination.to_upper(),int(army.get("arrival_day",0))]) if moving else " • %s" % destination.to_upper()]
	elif band=="regional":
		label="YOU • %s\n%s %d%% • %s" % [compact_count(troops),readiness_text,roundi(readiness*100.0),("→ %s" % destination.to_upper()) if moving else destination.to_upper()]
	elif band=="continental":
		label="YOU %s • R%d%s" % [compact_count(troops),roundi(readiness*100.0)," →" if moving else ""]
	var visual_source:Dictionary=army.duplicate(true)
	if not visual_source.has("formations") or (visual_source.get("formations",[]) as Array).is_empty(): visual_source["role_hint"]="infantry"
	if not visual_source.has("military_era_tier") and not visual_source.has("visual_era_tier"): visual_source["military_era_tier"]=0
	var visual_profile:=formation_visual_profile(visual_source)
	return {
		"id":str(int(army.get("army_id",0))),"owner":"player","owner_label":"YOU","visible":band not in ["ground","world"],
		"show_label":band in ["local","regional"] or (band=="continental" and (selected or moving)),"label":label,
		"selected":selected,"moving":moving,"color":PLAYER_SELECTED_COLOR if selected else PLAYER_COLOR,
		"troops":troops,"readiness":readiness,"readiness_band":readiness_text,"readiness_color":readiness_color(readiness),"supply":supply,"supply_color":supply_color(supply),
		"visual_profile":visual_profile,"role":String(visual_profile.role),"era":String(visual_profile.era),"symbol_family":String(visual_profile.symbol_family),"damage_state":String(visual_profile.damage_state),
		"position":(army.get("position",{}) as Dictionary).duplicate(true),"destination_id":String(army.get("destination_id","")),
		"destination_name":destination,
		"destination_position":(army.get("destination_position",{}) as Dictionary).duplicate(true),"distance_remaining_km":float(army.get("distance_remaining_km",0.0)),
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
		label="%s • ~%s–%s\nR~%d–%d%% • %.0f KM%s" % [owner.to_upper(),compact_count(low),compact_count(high),roundi(readiness_low*100.0),roundi(readiness_high*100.0),float(sighting.get("distance_km",0.0))," • REPORT" if scout else ""]
	elif band=="regional":
		label="%s • ~%s–%s\nR~%d–%d%%" % [owner.to_upper(),compact_count(low),compact_count(high),roundi(readiness_low*100.0),roundi(readiness_high*100.0)]
	var visual_source:Dictionary=sighting.duplicate(true)
	visual_source["readiness"]=(readiness_low+readiness_high)*0.5
	visual_source["troops"]=roundi((float(low)+float(high))*0.5)
	if scout:
		visual_source["role_hint"]="scout"
	elif identified and not visual_source.has("role_hint") and not visual_source.has("role_estimate"):
		match String(sighting.get("kind","")):
			"scout": visual_source["role_hint"]="scout"
			"patrol": visual_source["role_hint"]="infantry"
			"expedition": visual_source["role_hint"]="combined"
	var visual_profile:=formation_visual_profile(visual_source)
	return {
		"id":String(sighting.get("id","")),"owner":String(sighting.get("civ_id","")),"owner_label":owner.to_upper(),"visible":band in ["local","regional"],
		"show_label":band in ["local","regional"],"label":label,"selected":false,"moving":true,
		"color":HOSTILE_COLOR if hostile else (SCOUT_COLOR if scout else FOREIGN_COLOR),"hostile":hostile,"scout":scout,"identified":identified,
		"strength_low":low,"strength_high":high,"readiness_low":readiness_low,"readiness_high":readiness_high,
		"visual_profile":visual_profile,"role":String(visual_profile.role),"era":String(visual_profile.era),"symbol_family":String(visual_profile.symbol_family),"damage_state":String(visual_profile.damage_state),
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
		label="%s • %s %d%%\nFIELD %s • READY %d%% • SUPPLY %d%%" % ["BATTLE" if engagement_active else String(front.get("war_name","ACTIVE FRONT")).to_upper(),String(front.get("target","HOME TERRITORY")).to_upper(),roundi(progress*100.0),compact_count(fielded),roundi(readiness*100.0),roundi(clampf(float(front.get("supply",0.0)),0.0,1.0)*100.0)]
	return {
		"id":String(front.get("id","")),"visible":band!="ground","show_label":band!="ground","label":label,
		"engagement":engagement_active,"color":ENGAGEMENT_COLOR if engagement_active else FRONT_COLOR,"progress":progress,"field_personnel":fielded,
		"readiness":readiness,"readiness_color":readiness_color(readiness),"target_region_id":String(front.get("target_region_id","")),"position":(destination.get("position",{}) as Dictionary).duplicate(true),"scale":marker_scale(camera_size)*1.16
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
