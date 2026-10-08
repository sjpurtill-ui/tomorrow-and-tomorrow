extends RefCounted
## Placement excludes economics and weathering. Appearance reads recorded facts;
## neither key changes the simulation. All samples use stable recorded identity.
const CELL_KM:=0.256
const ID_SHARD:=16
const PLACEMENT_FIELDS:=["id","seed","centroid","polygon","frontage_route_id","water_facing","area_ha","roof_coverage","land_use","form","material_family","roof_plan","storeys","fabric_generation","fabric_components","visual_building_sites","visual_sites_form"]
const APPEARANCE_FIELDS:=["id","seed","centroid","polygon","frontage_route_id","area_ha","roof_coverage","land_use","form","material_family","roof_plan","storeys","fabric_generation","fabric_components","status","damage","field_pattern","crop_family","visual_material_mix","material_mix","building_materials","field_rotation","created_day","converted_day","infill_units","crop_cover","cultivation_phase","supply_provenance"]
const TONE_FIELDS:=["condition","prosperity","service_access","maintenance_debt","reclamation"]
const ROUTE_FIELDS:=["id","points","active","kind","hierarchy","width_m","surface_tier","status"]

static func project(record:Dictionary,fields:Array)->Array:
	var out:Array=[]
	for field:String in fields:out.append(record.get(field))
	return out

static func placement(plots:Array[Dictionary],routes:Array[Dictionary])->int:
	var records:Array=[]
	for plot:Dictionary in plots:
		var values:=project(plot,PLACEMENT_FIELDS)
		# Installed annexes can widen the mesh envelope, unlike supply history.
		values.append(preload("res://scripts/settlement_architecture_kit.gd").installed_features(plot))
		records.append(values)
	for route:Dictionary in routes:records.append(project(route,ROUTE_FIELDS))
	return hash(records)

static func layout_inputs(plots:Array[Dictionary],routes:Array[Dictionary])->Dictionary:
	var early:=preload("res://scripts/early_settlement_visual.gd")
	var frontage:Dictionary={}
	for road:Dictionary in routes:frontage[int(road.get("id",-1))]=project(road,ROUTE_FIELDS)
	var obstacles:Array=[]
	for plot:Dictionary in plots:
		if not early.supports(plot) and String(plot.get("land_use","")) not in ["field","pasture","water","waste","vacant"]:
			obstacles.append([plot.get("id"),plot.get("polygon")])
	var obstacle_key:=hash(obstacles)
	var out:Dictionary={}
	for plot:Dictionary in plots:
		if int(plot.get("id",0))>preload("res://scripts/organic_town_visual.gd").MAX_PLOTS or not early.supports(plot):continue
		out[int(plot.id)]=hash([project(plot,PLACEMENT_FIELDS),frontage.get(int(plot.get("frontage_route_id",-1)),[]),obstacle_key])
	return out

static func appearance(plot:Dictionary)->int:
	var values:=project(plot,APPEARANCE_FIELDS)
	values.append(preload("res://scripts/settlement_construction_state.gd").signature(plot))
	values.append(preload("res://scripts/settlement_culture_visual.gd").signature(preload("res://scripts/settlement_culture_visual.gd").for_plot(plot)))
	for field:String in TONE_FIELDS:values.append(roundi(float(plot.get(field,1.0 if field=="condition" else 0.0))*5.0))
	# Occupied pressure only changes the legacy roof count in broad steps.
	values.append(roundi(float(plot.get("resident_count",0.0))/4.0))
	return hash(values)

static func route(route_record:Dictionary)->int:
	return hash([project(route_record,ROUTE_FIELDS),roundi(float(route_record.get("condition",0.5))*5.0)])

static func age(plot:Dictionary,day:float,uses_kit:bool)->int:
	# Kit weathering reads condition/fire, not the calendar. Fields have recorded
	# crop phases. Legacy roof/ground tones age for at most ninety years.
	if uses_kit or String(plot.get("land_use","")) in ["field","pasture","water","waste","vacant"]:return 0
	var years:=maxf(0.0,(day-float(plot.get("created_day",day)))/365.0)
	return mini(90,floori(years))

static func knowledge(plot:Dictionary,uses_kit:bool)->int:
	if uses_kit:return int(preload("res://scripts/settlement_architecture_kit.gd").chimney_for(plot))
	var use:=String(plot.get("land_use",""));var family:=String(plot.get("material_family",""))
	return hash([
		"blast_furnace" in GameState.known_discoveries and use in ["dirty_industry","workshop","storage"],
		"covered_sewers" in GameState.known_discoveries and use in ["civic","market","hospitality"],
		"stone_selection" in GameState.known_discoveries and family=="stone",
		"pit_firing" in GameState.known_discoveries and family=="earth"])

static func patch_key(plot:Dictionary,center:Vector3)->String:
	var point:Vector2=Vector2(plot.get("centroid",Vector2.ZERO))+Vector2(center.x,center.z)
	return "plots:%d:%d:%d" % [floori(point.x/CELL_KM),floori(point.y/CELL_KM),maxi(0,int(plot.get("id",1))-1)/ID_SHARD]

static func refresh_plan(plan:Dictionary,plots:Array[Dictionary])->Dictionary:
	var by_id:Dictionary={}
	for plot:Dictionary in plots:by_id[int(plot.id)]=plot
	var records:Array=[]
	for old:Dictionary in plan.get("buildings",[]):
		if not by_id.has(int(old.plot_id)):continue
		var record:=old.duplicate(false)
		record.plot=by_id[int(old.plot_id)]
		record["early_kind"]=preload("res://scripts/early_settlement_visual.gd").kind(record.plot)
		records.append(record)
	return {"buildings":records,"replaced":plan.get("replaced",{})}

static func plan_for(plan:Dictionary,plots:Array[Dictionary])->Dictionary:
	var ids:Dictionary={}
	for plot:Dictionary in plots:ids[int(plot.id)]=true
	var records:Array=[]
	var replaced:Dictionary={}
	for record:Dictionary in plan.get("buildings",[]):
		if ids.has(int(record.plot_id)):records.append(record)
	for id in plan.get("replaced",{}):
		if ids.has(id):replaced[id]=true
	return {"buildings":records,"replaced":replaced}
