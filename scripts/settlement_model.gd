extends Node

const VALID_STATUSES:= ["active","under_construction","stressed","damaged","vacant","ruin","reclaimed"]
const VALID_REPAIR_STATES:= ["maintained","emergency_stabilization","awaiting_assessment","awaiting_materials","repairing","rebuilding","salvaging","unrepairable"]
const VALID_REOCCUPATION_STATES:= ["occupied","evacuating","displaced","unsafe_return","temporary_use","returning","partially_reoccupied","reoccupied","contested_claim","permanently_abandoned"]
const VALID_LAND_USES:= ["residential_compound","mixed_household","communal","civic","sacred","market","workshop","dirty_industry","storage","hospitality","defense","water","waste","transport","field","pasture","vacant","ruin"]
const FOUNDING_NONRESIDENTIAL:= ["communal","storage","workshop","water","waste"]

func reset_for_new_world()->void:
	# All authoritative data lives in GameState and is reset atomically there.
	pass

func ensure_founded()->void:
	if not GameState.settlement_plots.is_empty():
		if GameState.settlement_morphology.is_empty(): rebuild_summary()
		return
	if "Hearth Circle" not in GameState.settlement_completed: return
	if GameState.settlement_founded_day<0: GameState.settlement_founded_day=int(floor(GameState.elapsed_days))
	_create_founding_nucleus()
	_create_founding_plots()
	_create_founding_routes()
	GameState.last_morphology_day=int(floor(GameState.elapsed_days/30.0))*30
	GameState.morphology_revision+=1
	rebuild_summary()

func _create_founding_nucleus()->void:
	var nucleus_id:=GameState.next_settlement_nucleus_id
	GameState.next_settlement_nucleus_id+=1
	GameState.settlement_nuclei.append({"id":nucleus_id,"kind":"founding_hearth","position":Vector2.ZERO,"pull":1.0,"active":true,"created_day":GameState.settlement_founded_day,"absorbed_day":-1})

func _create_founding_plots()->void:
	GameState.initialize_citizen_registry()
	var household_ids:Dictionary={}
	for person in GameState.living_citizens(): household_ids[int(person.get("household_id",-1))]=true
	var residential_count:=clampi(roundi(float(maxi(1,household_ids.size()))/1.55),14,22)
	var total_count:=residential_count+FOUNDING_NONRESIDENTIAL.size()
	var residents_remaining:=GameState.population_total
	var accepted_centers:Array[Vector2]=[]
	var accepted_radii:Array[float]=[]
	for index in total_count:
		var plot_id:=GameState.next_settlement_plot_id
		GameState.next_settlement_plot_id+=1
		var plot_seed:=hash("%d:settlement_plot:%d" % [GameState.world_seed,plot_id])
		var rng:=RandomNumberGenerator.new()
		rng.seed=plot_seed
		var land_use:="residential_compound"
		if index<residential_count:
			land_use="mixed_household" if index%4==1 else "residential_compound"
		else:
			land_use=String(FOUNDING_NONRESIDENTIAL[index-residential_count])
		var radius:=rng.randf_range(0.0065,0.0105) if index<residential_count else rng.randf_range(0.008,0.013)
		var center:=Vector2.ZERO
		for attempt in 32:
			center=_founding_plot_center(index,total_count,land_use,rng,attempt)
			var clear:=true
			for prior_index in accepted_centers.size():
				if center.distance_to(accepted_centers[prior_index])<(radius+accepted_radii[prior_index])*1.16:
					clear=false
					break
			if clear: break
		accepted_centers.append(center)
		accepted_radii.append(radius)
		var polygon:=_irregular_polygon(center,radius,plot_seed)
		var resident_count:=0
		var resident_capacity:=0
		if index<residential_count:
			var plots_left:=residential_count-index
			resident_count=ceili(float(residents_remaining)/float(plots_left))
			residents_remaining-=resident_count
			resident_capacity=maxi(resident_count+2,8)
		var material_family:="organic"
		var material_mix:Dictionary={"Timber":0.38,"Fiber Plants":0.42,"Clay":0.08}
		if land_use in ["water","waste"]:
			material_family="earth"
			material_mix={"Clay":0.35,"Stone":0.12,"Fiber Plants":0.08}
		var created_day:=GameState.settlement_founded_day
		var plot:Dictionary={
			"id":plot_id,"seed":plot_seed,"nucleus_id":1,"parent_plot_id":-1,"lineage_ids":[],
			"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
			"land_use":land_use,"secondary_use":"craft" if land_use=="mixed_household" else "",
			"form":"portable_shelter_cluster" if index<residential_count else _founding_function_form(land_use),
			"material_family":material_family,"material_mix":material_mix,"construction_recipe":"founding_salvage_and_local_materials",
			"supply_provenance":{},"replacement_debt":{},"roof_coverage":rng.randf_range(0.20,0.34) if index<residential_count else rng.randf_range(0.08,0.24),"storeys":1,
			"resident_capacity":resident_capacity,"resident_count":resident_count,"worker_capacity":2 if land_use in ["mixed_household","workshop","storage"] else 0,
			"worker_count":1 if land_use in ["mixed_household","workshop","storage"] else 0,"storage_capacity":4.0 if land_use=="storage" else (0.8 if index<residential_count else 0.0),
			"condition":rng.randf_range(0.72,0.88),"maintenance_debt":rng.randf_range(0.02,0.08),"service_access":clampf(1.0-center.length()/0.11,0.18,1.0),
			"hazard_exposure":rng.randf_range(0.06,0.18),"prosperity":rng.randf_range(0.28,0.48),"status":"active","pre_damage_use":"",
			"damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":rng.randf_range(0.0,0.04)},
			"habitability":0.84 if index<residential_count else 0.70,"repair_state":"maintained","reoccupation_state":"occupied",
			"displaced_households":0,"returning_households":0,"claim_pressure":0.0,
			"created_day":created_day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":created_day
		}
		GameState.settlement_plots.append(plot)
		GameState.settlement_plot_history.append({"day":created_day,"plot_id":plot_id,"event":"founded","new_state":"active","cause":"Hearth Circle established"})

func _founding_plot_center(index:int,total_count:int,land_use:String,rng:RandomNumberGenerator,attempt:int)->Vector2:
	var seed_angle:=float(abs(GameState.world_seed)%6283)*0.001
	if land_use=="communal":
		return Vector2(rng.randf_range(-0.004,0.004),rng.randf_range(-0.004,0.004)) if attempt==0 else Vector2.from_angle(seed_angle+attempt*1.77)*float(attempt)*0.0028
	if land_use=="water":
		return Vector2.from_angle(seed_angle+PI*0.82+attempt*0.17)*rng.randf_range(0.066,0.084)
	if land_use=="waste":
		return Vector2.from_angle(seed_angle-PI*0.32+attempt*0.19)*rng.randf_range(0.080,0.105)
	var cluster_count:=4
	var cluster_index:int=(index*7+absi(GameState.world_seed))%cluster_count
	var cluster_angle:=seed_angle+float(cluster_index)*TAU/float(cluster_count)+sin(float(cluster_index*19+GameState.world_seed))*0.34
	var cluster_distance:=0.020+float(cluster_index%2)*0.012+rng.randf_range(-0.003,0.006)
	var cluster_center:=Vector2.from_angle(cluster_angle)*cluster_distance
	var local_angle:=seed_angle+float(index)*2.399963229728653+float(attempt)*1.37
	var local_radius:=rng.randf_range(0.008,0.027)+float(attempt)*0.0012
	if land_use=="storage":
		cluster_center*=0.45
		local_radius*=0.48
	elif land_use=="workshop":
		cluster_center*=0.74
		local_radius*=0.72
	var position:=cluster_center+Vector2.from_angle(local_angle)*local_radius
	# Preserve the founding hearth as a real nucleus. Household claims begin beyond
	# its shared working/meeting clearance instead of accidentally occupying it first.
	if land_use in ["residential_compound","mixed_household"] and position.length()<0.025:
		position=position.normalized()*0.025 if position.length()>0.0001 else Vector2.from_angle(local_angle)*0.025
	return position

func _irregular_polygon(center:Vector2,radius:float,plot_seed:int)->PackedVector2Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed^0x5f3759df
	var vertices:=rng.randi_range(5,8)
	var rotation:=rng.randf_range(0.0,TAU)
	var polygon:=PackedVector2Array()
	for vertex_index in vertices:
		var angle:=rotation+TAU*float(vertex_index)/float(vertices)+rng.randf_range(-0.11,0.11)
		var vertex_radius:=radius*rng.randf_range(0.72,1.18)
		polygon.append(center+Vector2(cos(angle),sin(angle))*vertex_radius)
	return polygon

func _founding_function_form(land_use:String)->String:
	return {"communal":"open_hearth_yard","storage":"guarded_cache","workshop":"open_work_yard","water":"carried_water_point","waste":"refuse_and_latrine_ground"}.get(land_use,"open_ground")

func _create_founding_routes()->void:
	var route_id:=1
	var connected_centers:Array[Vector2]=[Vector2.ZERO]
	var plots_by_distance:=GameState.settlement_plots.duplicate(false)
	plots_by_distance.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return Vector2(a.centroid).length()<Vector2(b.centroid).length())
	for plot in plots_by_distance:
		var plot_center:=Vector2(plot.centroid)
		var nearest:=connected_centers[0]
		var nearest_distance:=plot_center.distance_to(nearest)
		for candidate in connected_centers:
			var distance:=plot_center.distance_to(candidate)
			if distance<nearest_distance:
				nearest=candidate
				nearest_distance=distance
		var direction:=nearest-plot_center
		var side:=Vector2(-direction.y,direction.x).normalized()
		var bend_strength:=minf(0.005,nearest_distance*0.16)
		var bend_a:=plot_center.lerp(nearest,0.34)+side*sin(float(int(plot.id)*37+GameState.world_seed))*bend_strength
		var bend_b:=plot_center.lerp(nearest,0.69)-side*sin(float(int(plot.id)*19+GameState.world_seed)*0.73)*bend_strength*0.68
		var route:Dictionary={"id":route_id,"kind":"desire_path","points":PackedVector2Array([plot_center,bend_a,bend_b,nearest]),"condition":0.38+float(int(plot.id)%5)*0.025,"width_m":0.62+float(int(plot.id)%4)*0.11,"created_day":GameState.settlement_founded_day,"active":true}
		GameState.settlement_routes.append(route)
		plot["frontage_route_id"]=route_id
		connected_centers.append(plot_center)
		route_id+=1

func process_month(context:Dictionary={})->Array[Dictionary]:
	ensure_founded()
	if GameState.settlement_plots.is_empty(): return []
	var month_day:=int(floor(GameState.elapsed_days/30.0))*30
	if month_day<=GameState.last_morphology_day: return []
	GameState.last_morphology_day=month_day
	var events:Array[Dictionary]=[]
	for plot in GameState.settlement_plots:
		plot["last_update_day"]=month_day
		if String(plot.get("status",""))=="under_construction":
			var builders:=float(GameState.population_allocations.get("Construction",0))
			var labor_efficiency:=float(GameState.simulation_metrics.get("labor_efficiency",0.72))
			var previous_progress:=float(plot.get("construction_progress",0.0))
			plot["construction_progress"]=clampf(previous_progress+builders*labor_efficiency*0.10,0.0,1.0)
			if not is_equal_approx(previous_progress,float(plot.construction_progress)):
				GameState.morphology_revision+=1
			if float(plot.construction_progress)>=1.0:
				plot["status"]="active"
				plot["condition"]=0.92
				plot["repair_state"]="maintained"
				GameState.settlement_plot_history.append({"day":month_day,"plot_id":int(plot.id),"event":"construction_completed","new_state":"active","cause":String(plot.get("growth_cause","household pressure"))})
				GameState.morphology_revision+=1
				events.append({"type":"morphology","title":_completion_title(String(plot.get("land_use","residential_compound"))),"plot_id":int(plot.id)})
	_synchronize_early_works(month_day,events)
	_update_plot_workforce(month_day,events)
	_update_field_seasons(month_day)
	_process_occupancy_and_maintenance(month_day,events)
	_attempt_functional_growth(month_day,events,context)
	if not _has_active_construction(): _attempt_household_growth(month_day,events,context)
	_attempt_field_growth(month_day,events,context)
	rebuild_summary()
	return events

func _completion_title(land_use:String)->String:
	return {
		"workshop":"New Working Ground Entered Use",
		"storage":"New Stores Entered Use",
		"residential_compound":"New Household Ground Occupied",
		"mixed_household":"New Household Ground Occupied"
	}.get(land_use,"New Ground Entered Use")

func _has_active_construction()->bool:
	for plot in GameState.settlement_plots:
		if String(plot.get("status",""))=="under_construction": return true
	return false

func _recognized_fertile_ground()->Dictionary:
	for deposit in GameState.resource_deposits:
		if String(deposit.get("resource",""))=="Fertile Soil" and String(deposit.get("stage","unknown")) in ["surveyed","accessible","developed"]:
			return deposit
	return {}

func _update_field_seasons(day:int)->void:
	var visual_state_changed:=false
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))!="field": continue
		var previous_phase:=String(plot.get("cultivation_phase","prepared"))
		var previous_cover:=float(plot.get("crop_cover",0.0))
		var phase:="fallow"
		var cover:=0.08
		if int(plot.get("worker_count",0))>0 and String(plot.get("status","active"))=="active":
			var local_day:=fposmod(float(day+(absi(int(plot.get("seed",1)))%29)-14),365.0)
			if local_day<48.0:
				phase="fallow"; cover=0.10
			elif local_day<82.0:
				phase="prepared"; cover=0.16
			elif local_day<205.0:
				phase="growing"; cover=lerpf(0.32,0.88,(local_day-82.0)/123.0)
			elif local_day<258.0:
				phase="mature"; cover=0.94
			elif local_day<310.0:
				phase="harvested"; cover=0.22
			else:
				phase="fallow"; cover=0.09
			if float(plot.get("condition",1.0))<0.46:
				phase="stressed"
				cover*=0.46
		plot["cultivation_phase"]=phase
		plot["crop_cover"]=clampf(cover,0.0,1.0)
		if phase!=previous_phase or absf(cover-previous_cover)>=0.03: visual_state_changed=true
	if visual_state_changed: GameState.morphology_revision+=1

func _update_plot_workforce(day:int,events:Array[Dictionary])->void:
	var role_by_use:Dictionary={"field":"Food","workshop":"Crafting","storage":"Logistics"}
	for land_use in role_by_use:
		var role:=String(role_by_use[land_use])
		var available:=maxi(0,int(GameState.population_allocations.get(role,0)))
		var candidates:Array[Dictionary]=[]
		for plot in GameState.settlement_plots:
			if String(plot.get("land_use",""))!=land_use: continue
			if String(plot.get("status","")) in ["under_construction","ruin","reclaimed"]: continue
			candidates.append(plot)
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			return float(a.get("service_access",0.0))+float(a.get("condition",0.0))*0.25>float(b.get("service_access",0.0))+float(b.get("condition",0.0))*0.25)
		for plot in candidates:
			var capacity:=maxi(0,int(plot.get("worker_capacity",0)))
			var assigned:=mini(capacity,available)
			available-=assigned
			plot["worker_count"]=assigned
			var idle_months:=int(plot.get("idle_months",0))
			var previous_status:=String(plot.get("status","active"))
			if assigned<=0:
				idle_months+=1
				plot["idle_months"]=idle_months
				if idle_months>=6 and previous_status not in ["damaged","ruin"]:
					plot["status"]="vacant"
					plot["reoccupation_state"]="temporary_use" if idle_months<36 else "permanently_abandoned"
			else:
				plot["idle_months"]=0
				if previous_status=="vacant" and float(plot.get("condition",0.0))>=0.28:
					plot["status"]="active"
					plot["reoccupation_state"]="reoccupied"
			if String(plot.get("status",""))!=previous_status:
				GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"work_ground_idled" if assigned<=0 else "work_ground_reoccupied","new_state":String(plot.status),"cause":"%s labor allocation changed" % role})
				GameState.morphology_revision+=1
				events.append({"type":"morphology","title":"%s %s" % [land_use.capitalize(),"Fell Idle" if assigned<=0 else "Returned to Use"],"plot_id":int(plot.id)})

func _attempt_field_growth(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	if "seed_selection" not in GameState.known_discoveries: return
	var food_workers:=int(GameState.population_allocations.get("Food",0))
	if food_workers<10: return
	var fertile_ground:=_recognized_fertile_ground()
	if fertile_ground.is_empty(): return
	var field_count:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))=="field" and String(plot.get("status","")) not in ["ruin","reclaimed"]: field_count+=1
	# One field plot is an aggregate worked by at most twelve assigned people.
	# Keep enough persistent plots to represent the labor that actually exists;
	# the old cap of eighteen visually erased hundreds of food workers.
	var target_fields:=clampi(ceili(float(food_workers)/12.0),1,72)
	if field_count>=target_fields: return
	var plot:=_create_field_plot(day,fertile_ground,field_count,context)
	if plot.is_empty(): return
	_create_growth_route(plot,day,"field_track")
	GameState.settlement_plots.append(plot)
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"field_opened","new_state":"active","cause":"seed selection, assigned food labor, and surveyed fertile soil"})
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"Cultivation Opened at the Settlement Fringe","plot_id":int(plot.id)})

func _create_field_plot(day:int,fertile_ground:Dictionary,field_index:int,context:Dictionary={})->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	var plot_seed:=hash("%d:settlement_field:%d" % [GameState.world_seed,plot_id])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var settlement_world:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var deposit_position:Vector3=fertile_ground.get("position",GameState.settlement_founded_at)
	var direction:=Vector2(deposit_position.x,deposit_position.z)-settlement_world
	if direction.length()<0.01: direction=Vector2.from_angle(rng.randf()*TAU)
	direction=direction.normalized()
	var radius:=rng.randf_range(0.014,0.026)
	var center:=Vector2.ZERO
	var found:=false
	var existing_fields:Array[Dictionary]=[]
	for existing in GameState.settlement_plots:
		if String(existing.get("land_use",""))=="field" and String(existing.get("status","")) not in ["ruin","reclaimed"]: existing_fields.append(existing)
	for attempt in 80:
		if not existing_fields.is_empty() and rng.randf()<0.78:
			var anchor:Dictionary=existing_fields[rng.randi_range(0,existing_fields.size()-1)]
			var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
			var anchor_radius:=sqrt(_polygon_area_km2(anchor.get("polygon",PackedVector2Array()))/PI)
			var seam_angle:=direction.angle()+PI*0.5*rng.randi_range(-1,1)+rng.randf_range(-0.42,0.42)
			center=anchor_center+Vector2.from_angle(seam_angle)*(anchor_radius+radius+rng.randf_range(0.0015,0.0040))
		else:
			var angle:=direction.angle()+rng.randf_range(-0.88,0.88)+float(field_index)*0.17
			center=Vector2.from_angle(angle)*rng.randf_range(0.11,0.24)
		var clear:=true
		for existing in GameState.settlement_plots:
			var existing_polygon:PackedVector2Array=existing.get("polygon",PackedVector2Array())
			var existing_radius:=sqrt(_polygon_area_km2(existing_polygon)/PI)
			var clearance_factor:=1.045 if String(existing.get("land_use",""))=="field" else 1.12
			if center.distance_to(Vector2(existing.get("centroid",Vector2.ZERO)))<(radius+existing_radius)*clearance_factor:
				clear=false
				break
		if clear:
			found=true
			break
	if not found: return {}
	GameState.next_settlement_plot_id+=1
	var origin:Vector3=context.get("settlement_origin",GameState.settlement_founded_at)
	var world_x:=origin.x+center.x
	var world_z:=origin.z+center.y
	var river_distance:=INF
	var river_callable:Callable=context.get("river_distance_at",Callable())
	if river_callable.is_valid(): river_distance=float(river_callable.call(world_x,world_z))
	var moisture:=0.0
	var moisture_callable:Callable=context.get("moisture_at",Callable())
	if moisture_callable.is_valid(): moisture=float(moisture_callable.call(world_x,world_z))
	var field_pattern:="dryland_patchwork"
	if river_distance<0.42: field_pattern="irrigated_beds"
	elif moisture>0.04: field_pattern="smallholder_mosaic"
	# Crop identity is authoritative simulation state, not a renderer tint. Early
	# cultivation is heterogeneous even before formal botany: households favor
	# different gathered grains, pulses, roots, fibres, and mixed garden staples.
	var crop_families:=["mixed_staples","grain","pulses","roots","fibre_crop"]
	var crop_family:String=crop_families[absi(plot_seed)%crop_families.size()]
	if field_pattern=="irrigated_beds" and absi(plot_seed)%3==0: crop_family="garden_beds"
	var field_rotation:=direction.angle()+rng.randf_range(-0.68,0.68)+sin(float(field_index)*1.73)*0.22
	var height_callable:Callable=context.get("terrain_height_at",Callable())
	if height_callable.is_valid():
		var sample_radius:=0.045
		var gradient:=Vector2(
			float(height_callable.call(world_x+sample_radius,world_z))-float(height_callable.call(world_x-sample_radius,world_z)),
			float(height_callable.call(world_x,world_z+sample_radius))-float(height_callable.call(world_x,world_z-sample_radius))
		)/(sample_radius*2.0)
		if gradient.length()>0.002:
			var contour_angle:=Vector2(-gradient.y,gradient.x).angle()
			field_rotation=lerp_angle(field_rotation,contour_angle,clampf(gradient.length()*7.5,0.18,0.82))
	var polygon:=_irregular_field_polygon(center,radius,plot_seed,field_rotation,field_pattern)
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":1,"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":"field","secondary_use":"seasonal_grazing","form":"hand_cultivated_clearance","field_pattern":field_pattern,"crop_family":crop_family,"cultivation_phase":"prepared","crop_cover":0.16,"material_family":"earth","material_mix":{"Soil":0.86,"Fiber Plants":0.04},"construction_recipe":"clearing_and_hand_cultivation","supply_provenance":{"Fertile Soil":String(fertile_ground.get("id","local occurrence"))},"replacement_debt":{},"roof_coverage":0.0,"storeys":0,
		"resident_capacity":0,"resident_count":0,"worker_capacity":12,"worker_count":mini(12,int(GameState.population_allocations.get("Food",0))),"storage_capacity":0.0,"condition":0.82,"maintenance_debt":0.02,"service_access":0.28,"hazard_exposure":rng.randf_range(0.08,0.22),"prosperity":0.30,
		"status":"active","reclamation":0.0,"pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.0},"habitability":0.0,"repair_state":"maintained","reoccupation_state":"occupied","displaced_households":0,"returning_households":0,"claim_pressure":0.0,
		"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func _irregular_field_polygon(center:Vector2,radius:float,plot_seed:int,rotation:float,field_pattern:String="smallholder_mosaic")->PackedVector2Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed^0x7f4a7c15
	var right:=Vector2.from_angle(rotation)
	var forward:=Vector2(-right.y,right.x)
	var half_length:=radius*rng.randf_range(1.08,1.62)
	var half_width:=radius*rng.randf_range(0.60,0.94)
	if field_pattern=="irrigated_beds":
		half_length*=rng.randf_range(1.12,1.42)
		half_width*=rng.randf_range(0.58,0.78)
	elif field_pattern=="dryland_patchwork":
		half_length*=rng.randf_range(0.82,1.08)
		half_width*=rng.randf_range(0.90,1.22)
	var skew:=right*rng.randf_range(-radius*0.20,radius*0.20)
	# Agricultural ground is usually inherited as strips and trapezoids following
	# ploughing direction, drainage and neighbours—not radial leaf-shaped islands.
	return PackedVector2Array([
		center-right*half_length-forward*half_width,
		center+skew-forward*half_width*rng.randf_range(0.92,1.08),
		center+right*half_length-forward*half_width*rng.randf_range(0.76,1.12),
		center+right*half_length+forward*half_width*rng.randf_range(0.82,1.10),
		center-skew+forward*half_width*rng.randf_range(0.90,1.12),
		center-right*half_length+forward*half_width*rng.randf_range(0.78,1.08)
	])

func _process_occupancy_and_maintenance(day:int,events:Array[Dictionary])->void:
	var residential:Array[Dictionary]=[]
	var total_capacity:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]: continue
		if String(plot.get("status","")) in ["ruin","reclaimed","under_construction"]: continue
		residential.append(plot)
		total_capacity+=int(plot.get("resident_capacity",0))
	residential.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var score_a:=float(a.get("service_access",0.0))+float(a.get("condition",0.0))*0.35-float(a.get("hazard_exposure",0.0))*0.20
		var score_b:=float(b.get("service_access",0.0))+float(b.get("condition",0.0))*0.35-float(b.get("hazard_exposure",0.0))*0.20
		return score_a>score_b)
	var occupancy_ratio:=clampf(float(GameState.population_total)/maxf(1.0,float(total_capacity)),0.0,1.0)
	var assigned:=0
	for index in residential.size():
		var plot:=residential[index]
		var desired:=mini(int(plot.get("resident_capacity",0)),roundi(float(plot.get("resident_capacity",0))*occupancy_ratio))
		if index==residential.size()-1: desired=mini(int(plot.get("resident_capacity",0)),maxi(0,GameState.population_total-assigned))
		plot["resident_count"]=desired
		assigned+=desired
		var previous_status:=String(plot.get("status","active"))
		var vacant_months:=int(plot.get("vacant_months",0))
		if desired<=0:
			vacant_months+=1
			plot["vacant_months"]=vacant_months
			if vacant_months>=6 and previous_status not in ["damaged","ruin"]:
				plot["status"]="vacant"
				plot["abandoned_day"]=day if int(plot.get("abandoned_day",-1))<0 else int(plot.abandoned_day)
				plot["reoccupation_state"]="permanently_abandoned" if vacant_months>=60 else "displaced"
		else:
			plot["vacant_months"]=0
			if previous_status=="vacant" and float(plot.get("condition",0.0))>=0.32:
				plot["status"]="active"
				plot["reoccupation_state"]="reoccupied"
				plot["abandoned_day"]=-1
		if String(plot.get("status",""))!=previous_status:
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"vacated" if String(plot.status)=="vacant" else "reoccupied","new_state":plot.status,"cause":"population redistribution across usable household ground"})
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"Household Ground %s" % ("Vacated" if String(plot.status)=="vacant" else "Reoccupied"),"plot_id":int(plot.id)})
	var builders:=float(GameState.population_allocations.get("Construction",0))
	var labor_efficiency:=float(GameState.simulation_metrics.get("labor_efficiency",0.72))
	var maintained_plots:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("status","")) in ["ruin","reclaimed","under_construction"]: continue
		maintained_plots+=1
	var maintenance_per_plot:=builders*labor_efficiency/maxf(1.0,float(maintained_plots))*0.0032
	var hardship:=clampf(1.0-float(GameState.simulation_metrics.get("health",GameState.population_health)),0.0,1.0)
	var rng:=RandomNumberGenerator.new()
	rng.seed=GameState.world_seed^day^0x27d4eb2d
	for plot in GameState.settlement_plots:
		var status:=String(plot.get("status","active"))
		if status=="under_construction": continue
		var previous_condition:=float(plot.get("condition",1.0))
		var exposure:=float(plot.get("hazard_exposure",0.1))
		var decay:=0.00065+exposure*0.00055+hardship*0.0012
		if status=="vacant": decay+=0.0018
		var maintenance:=maintenance_per_plot if status in ["active","stressed","damaged"] else 0.0
		plot["condition"]=clampf(previous_condition-decay+maintenance,0.0,1.0)
		plot["maintenance_debt"]=clampf(float(plot.get("maintenance_debt",0.0))+decay-maintenance,0.0,1.0)
		if status=="vacant":
			plot["reclamation"]=clampf(float(plot.get("reclamation",0.0))+0.012+float(plot.get("vacant_months",0))*0.00012,0.0,1.0)
		elif status=="active": plot["reclamation"]=maxf(0.0,float(plot.get("reclamation",0.0))-0.03)
		if status in ["active","stressed"] and rng.randf()<exposure*0.0015:
			var severity:=rng.randf_range(0.06,0.22)
			plot["condition"]=maxf(0.0,float(plot.condition)-severity)
			plot["status"]="damaged" if float(plot.condition)>=0.16 else "ruin"
			plot["pre_damage_use"]=String(plot.get("land_use",""))
			plot["damaged_day"]=day
			plot["repair_state"]="awaiting_assessment" if String(plot.status)=="damaged" else "unrepairable"
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"damage","new_state":plot.status,"cause":"localized fire, weather, or structural failure"})
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"Household Ground Damaged","plot_id":int(plot.id)})
		elif status=="active" and float(plot.condition)<0.48:
			plot["status"]="stressed"
			GameState.morphology_revision+=1
		elif status=="stressed" and float(plot.condition)>=0.58:
			plot["status"]="active"
			GameState.morphology_revision+=1
		elif status=="damaged" and float(plot.condition)<0.14:
			plot["status"]="ruin"
			plot["repair_state"]="unrepairable"
			GameState.morphology_revision+=1
		if absf(float(plot.condition)-previous_condition)>0.018:
			GameState.morphology_revision+=1
	# A route's importance comes from its own frontage and every occupied branch
	# feeding into it. Propagate demand through the inherited route tree so a
	# heavily used approach can emerge organically instead of every segment being
	# assessed as an isolated household path.
	var route_direct_users:Dictionary={}
	var route_frontage_plots:Dictionary={}
	var route_parent:Dictionary={}
	var route_by_id:Dictionary={}
	for route in GameState.settlement_routes:
		if bool(route.get("active",true)): route_by_id[int(route.id)]=route
	for route_id in route_by_id:
		route_direct_users[route_id]=0
		route_frontage_plots[route_id]=0
	for plot in GameState.settlement_plots:
		var frontage_id:=int(plot.get("frontage_route_id",-1))
		if not route_by_id.has(frontage_id): continue
		route_frontage_plots[frontage_id]=int(route_frontage_plots.get(frontage_id,0))+1
		route_direct_users[frontage_id]=int(route_direct_users.get(frontage_id,0))+int(plot.get("resident_count",0))+int(plot.get("worker_count",0))
	for route_id in route_by_id:
		var route:Dictionary=route_by_id[route_id]
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		var parent_id:=-1
		if points.size()>=2:
			var terminal:=points[points.size()-1]
			var nearest_parent_distance:=0.0022
			for candidate_id in route_by_id:
				if int(candidate_id)==int(route_id): continue
				var candidate:Dictionary=route_by_id[candidate_id]
				var candidate_points:PackedVector2Array=candidate.get("points",PackedVector2Array())
				if candidate_points.is_empty(): continue
				var distance:=terminal.distance_to(candidate_points[0])
				if distance<nearest_parent_distance:
					nearest_parent_distance=distance
					parent_id=int(candidate_id)
		route_parent[route_id]=parent_id
	var route_total_users:Dictionary={}
	for route_id in route_by_id: route_total_users[route_id]=0
	for source_id in route_by_id:
		var carried_users:=int(route_direct_users.get(source_id,0))
		var current_id:=int(source_id)
		var visited:Dictionary={}
		for depth in 24:
			if current_id<0 or visited.has(current_id): break
			visited[current_id]=true
			route_total_users[current_id]=int(route_total_users.get(current_id,0))+carried_users
			current_id=int(route_parent.get(current_id,-1))
	for route_id in route_by_id:
		var route:Dictionary=route_by_id[route_id]
		var frontage_users:=int(route_total_users.get(route_id,0))
		var direct_users:=int(route_direct_users.get(route_id,0))
		var frontage_plots:=int(route_frontage_plots.get(route_id,0))
		var frontage_occupied:=direct_users>0
		route["condition"]=clampf(float(route.get("condition",0.3))+(0.008 if frontage_occupied else -0.005),0.02,1.0)
		var observed_traffic:=clampf(float(frontage_users)/42.0+float(maxi(0,frontage_plots-1))*0.045,0.0,1.0)
		route["traffic"]=lerpf(float(route.get("traffic",0.0)),observed_traffic,0.16)
		var traffic:=float(route.traffic)
		var route_kind:=String(route.get("kind","desire_path"))
		var hierarchy:="field_track" if route_kind=="field_track" else "path"
		if route_kind=="field_track":
			if traffic>=0.34 and float(route.condition)>=0.42: hierarchy="farm_lane"
		else:
			if traffic>=0.30 and float(route.condition)>=0.48: hierarchy="lane"
			if traffic>=0.90 and frontage_users>=120 and float(route.condition)>=0.72 and day-int(route.get("created_day",day))>=720: hierarchy="main_approach"
		route["hierarchy"]=hierarchy
		var target_width:=0.72 if route_kind=="field_track" else 0.62
		if hierarchy=="farm_lane": target_width=1.35+traffic*0.55
		elif hierarchy=="lane": target_width=1.25+traffic*1.15
		elif hierarchy=="main_approach": target_width=2.25+traffic*1.55
		var widening_capacity:=clampf(builders*labor_efficiency/18.0,0.04,0.46)
		route["width_m"]=move_toward(float(route.get("width_m",target_width)),target_width,0.035+widening_capacity*0.09)
	if day%90==0:
		GameState.morphology_revision+=1

func _synchronize_early_works(day:int,events:Array[Dictionary])->void:
	if "Lean-to Shelters" in GameState.settlement_completed:
		for plot in GameState.settlement_plots:
			if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"] or String(plot.get("form","")) not in ["portable_shelter_cluster","light_shelter_cluster"]: continue
			plot["form"]="lean_to_household_cluster"
			plot["converted_day"]=day
			plot["roof_coverage"]=maxf(float(plot.get("roof_coverage",0.0)),0.22)
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"converted","new_state":"lean_to_household_cluster","cause":"Lean-to Shelters"})
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"Household Shelters Took Root","plot_id":int(plot.id)})
	var work_forms:Dictionary={"Storage Pits":{"use":"storage","from":"guarded_cache","to":"lined_storage_pits"},"Open Work Area":{"use":"workshop","from":"open_work_yard","to":"sheltered_work_area"}}
	for work_name in work_forms:
		if work_name not in GameState.settlement_completed: continue
		var definition:Dictionary=work_forms[work_name]
		for plot in GameState.settlement_plots:
			if String(plot.get("land_use",""))!=String(definition.use) or String(plot.get("form",""))!=String(definition.from): continue
			plot["form"]=definition.to
			plot["converted_day"]=day
			plot["roof_coverage"]=maxf(float(plot.get("roof_coverage",0.0)),0.28)
			GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"converted","new_state":definition.to,"cause":work_name})
			GameState.morphology_revision+=1
			events.append({"type":"morphology","title":"%s Changed the Ground" % work_name,"plot_id":int(plot.id)})

func _functional_plot_count(land_use:String)->int:
	var count:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))==land_use and String(plot.get("status","")) not in ["ruin","reclaimed"]: count+=1
	return count

func _available_functional_recipe(land_use:String)->Dictionary:
	var stocks:=GameState.resource_stockpiles
	var recipes:Array[Dictionary]=[]
	if land_use=="workshop":
		recipes=[
			{"family":"organic","form":"timber_work_shelter","cost":{"Timber":2.6,"Fiber Plants":1.0},"mix":{"Timber":0.58,"Fiber Plants":0.28,"Clay":0.04}},
			{"family":"earth","form":"earthen_work_shelter","requires":"clay_shaping","cost":{"Clay":4.0,"Timber":0.8},"mix":{"Clay":0.66,"Timber":0.18,"Fiber Plants":0.06}},
			{"family":"stone","form":"stone_work_shelter","requires":"stone_selection","cost":{"Stone":5.2,"Timber":1.2},"mix":{"Stone":0.70,"Timber":0.17,"Fiber Plants":0.03}}
		]
	else:
		recipes=[
			{"family":"organic","form":"raised_timber_store","cost":{"Timber":2.2,"Fiber Plants":1.1},"mix":{"Timber":0.50,"Fiber Plants":0.32,"Clay":0.06}},
			{"family":"earth","form":"sealed_earthen_store","requires":"clay_shaping","cost":{"Clay":4.4,"Fiber Plants":0.8},"mix":{"Clay":0.72,"Fiber Plants":0.14,"Timber":0.05}},
			{"family":"stone","form":"dry_stone_store","requires":"stone_selection","cost":{"Stone":5.8,"Timber":0.8},"mix":{"Stone":0.75,"Timber":0.12,"Fiber Plants":0.03}}
		]
	for recipe in recipes:
		var discovery:=String(recipe.get("requires",""))
		if not discovery.is_empty() and discovery not in GameState.known_discoveries: continue
		var available:=true
		for resource_name in recipe.cost:
			if float(stocks.get(resource_name,0.0))<float(recipe.cost[resource_name]):
				available=false
				break
		if available: return recipe
	return {}

func _attempt_functional_growth(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	if _has_active_construction() or int(GameState.population_allocations.get("Construction",0))<4: return
	var candidates:Array[Dictionary]=[]
	if "Open Work Area" in GameState.settlement_completed:
		var crafting:=int(GameState.population_allocations.get("Crafting",0))
		var desired_workshops:=clampi(floori(float(crafting)/6.0),1,14)
		var existing_workshops:=_functional_plot_count("workshop")
		if existing_workshops<desired_workshops:
			candidates.append({"use":"workshop","pressure":float(desired_workshops-existing_workshops)+float(crafting)/20.0})
	if "Storage Pits" in GameState.settlement_completed:
		var logistics:=int(GameState.population_allocations.get("Logistics",0))
		var desired_storage:=clampi(floori(float(logistics)/5.0),1,14)
		var stored_bulk:=float(GameState.simulation_metrics.get("material_stored_bulk",0.0))
		var capacity:=float(GameState.simulation_metrics.get("material_storage_capacity",1.0))
		if stored_bulk>capacity*0.72: desired_storage+=1
		var existing_storage:=_functional_plot_count("storage")
		if existing_storage<desired_storage:
			candidates.append({"use":"storage","pressure":float(desired_storage-existing_storage)+stored_bulk/maxf(1.0,capacity)})
	if candidates.is_empty(): return
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.pressure)>float(b.pressure))
	for candidate in candidates:
		var land_use:=String(candidate.use)
		var recipe:=_available_functional_recipe(land_use)
		if recipe.is_empty(): continue
		var plot:=_create_functional_growth_plot(day,land_use,recipe,context)
		if plot.is_empty(): continue
		for resource_name in recipe.cost:
			GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float(recipe.cost[resource_name]))
		_create_growth_route(plot,day)
		GameState.settlement_plots.append(plot)
		GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"construction_started","new_state":"under_construction","cause":String(plot.growth_cause)})
		GameState.morphology_revision+=1
		events.append({"type":"morphology","title":"%s Claimed" % ("New Working Ground" if land_use=="workshop" else "New Storage Ground"),"plot_id":int(plot.id)})
		return

func _growth_site_score(candidate:Vector2,radius:float,land_use:String,context:Dictionary)->float:
	# Reject occupied ground first. The remaining terms make settlement growth
	# follow inherited lanes, useful nuclei, water and buildable terrain instead of
	# adding rings around an abstract population centre.
	for existing in GameState.settlement_plots:
		var existing_radius:=sqrt(_polygon_area_km2(existing.get("polygon",PackedVector2Array()))/PI)
		if candidate.distance_to(Vector2(existing.get("centroid",Vector2.ZERO)))<(radius+existing_radius)*1.18:
			return -10000.0
	var nearest_route:=INF
	for route in GameState.settlement_routes:
		if not bool(route.get("active",true)): continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		for point_index in points.size()-1:
			nearest_route=minf(nearest_route,Geometry2D.get_closest_point_to_segment(candidate,points[point_index],points[point_index+1]).distance_to(candidate))
	var route_access:=exp(-nearest_route/0.018) if nearest_route<INF else 0.0
	var nucleus_pull:=0.0
	for nucleus in GameState.settlement_nuclei:
		if not bool(nucleus.get("active",true)): continue
		var distance:=candidate.distance_to(Vector2(nucleus.get("position",Vector2.ZERO)))
		nucleus_pull=maxf(nucleus_pull,float(nucleus.get("pull",1.0))*exp(-distance/0.14))
	var core_distance:=candidate.length()
	var compactness:=exp(-core_distance/0.22)
	var edge_preference:=exp(-absf(core_distance-0.095)/0.065)
	var score:=route_access*2.8+nucleus_pull*0.72
	if land_use=="storage": score+=compactness*1.25
	elif land_use in ["workshop","dirty_industry"]: score+=edge_preference*1.12-route_access*0.10
	else: score+=compactness*0.86
	var origin:Vector3=context.get("settlement_origin",GameState.settlement_founded_at)
	var world_x:=origin.x+candidate.x
	var world_z:=origin.z+candidate.y
	var height_callable:Callable=context.get("terrain_height_at",Callable())
	if height_callable.is_valid():
		var sample:=0.012
		var east_west:=absf(float(height_callable.call(world_x+sample,world_z))-float(height_callable.call(world_x-sample,world_z)))
		var north_south:=absf(float(height_callable.call(world_x,world_z+sample))-float(height_callable.call(world_x,world_z-sample)))
		var slope:=maxf(east_west,north_south)/(sample*2.0)
		if slope>0.34: return -10000.0
		score-=slope*3.2
	var river_callable:Callable=context.get("river_distance_at",Callable())
	if river_callable.is_valid():
		var river_distance:=float(river_callable.call(world_x,world_z))
		if river_distance<0.025: return -10000.0
		score+=exp(-absf(river_distance-0.16)/0.20)*0.24
	return score

func _create_functional_growth_plot(day:int,land_use:String,recipe:Dictionary,context:Dictionary={})->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	var plot_seed:=hash("%d:settlement_%s:%d" % [GameState.world_seed,land_use,plot_id])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var radius:=rng.randf_range(0.009,0.014) if land_use=="workshop" else rng.randf_range(0.008,0.012)
	var anchors:Array[Dictionary]=[]
	for existing in GameState.settlement_plots:
		if String(existing.get("status","")) in ["ruin","reclaimed"]: continue
		var existing_use:=String(existing.get("land_use",""))
		if existing_use==land_use or existing_use in ["communal","mixed_household"]: anchors.append(existing)
	if anchors.is_empty(): return {}
	var center:=Vector2.ZERO
	var best_center:=Vector2.ZERO
	var best_score:=-INF
	for attempt in 80:
		var anchor:Dictionary=anchors[rng.randi_range(0,anchors.size()-1)]
		var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
		var anchor_radius:=sqrt(_polygon_area_km2(anchor.get("polygon",PackedVector2Array()))/PI)
		var outward:=anchor_center.normalized() if anchor_center.length()>0.005 else Vector2.from_angle(rng.randf()*TAU)
		var direction:=outward.rotated(rng.randf_range(-1.20,1.20))
		center=anchor_center+direction*(anchor_radius+radius+rng.randf_range(0.003,0.009))
		var score:=_growth_site_score(center,radius,land_use,context)
		if score>best_score:
			best_score=score
			best_center=center
	if best_score<=-9000.0: return {}
	center=best_center
	GameState.next_settlement_plot_id+=1
	var polygon:=_irregular_polygon(center,radius,plot_seed)
	var workers:=int(GameState.population_allocations.get("Crafting" if land_use=="workshop" else "Logistics",0))
	var worker_capacity:=rng.randi_range(5,8)
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":1,"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":land_use,"secondary_use":"craft" if land_use=="workshop" else "provisions","form":recipe.form,"material_family":recipe.family,"material_mix":recipe.mix,"construction_recipe":"specialized_%s_expansion" % land_use,"supply_provenance":recipe.cost.duplicate(true),"replacement_debt":{},"roof_coverage":0.42 if land_use=="workshop" else 0.54,"storeys":1,
		"resident_capacity":0,"resident_count":0,"worker_capacity":worker_capacity,"worker_count":mini(workers,worker_capacity),"storage_capacity":rng.randf_range(10.0,18.0) if land_use=="storage" else 1.4,"condition":0.58,"maintenance_debt":0.0,"service_access":0.38,"hazard_exposure":rng.randf_range(0.10,0.24),"prosperity":0.34,
		"status":"under_construction","construction_progress":0.0,"growth_cause":"assigned %s labor, construction labor, and delivered materials" % ("craft" if land_use=="workshop" else "logistics"),"pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.0},"habitability":0.0,"repair_state":"maintained","reoccupation_state":"occupied",
		"displaced_households":0,"returning_households":0,"claim_pressure":0.0,"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func _resident_capacity_for_growth()->int:
	var capacity:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("status","")) in ["active","stressed","under_construction"]:
			capacity+=int(plot.get("resident_capacity",0))
	return capacity

func _available_household_recipe()->Dictionary:
	var stocks:=GameState.resource_stockpiles
	if float(stocks.get("Timber",0.0))>=1.8 and float(stocks.get("Fiber Plants",0.0))>=1.2:
		return {"family":"organic","form":"timber_and_fibre_household","cost":{"Timber":1.8,"Fiber Plants":1.2},"mix":{"Timber":0.52,"Fiber Plants":0.34,"Clay":0.05}}
	if "clay_shaping" in GameState.known_discoveries and float(stocks.get("Clay",0.0))>=3.2 and float(stocks.get("Fiber Plants",0.0))>=0.6:
		return {"family":"earth","form":"earthen_household","cost":{"Clay":3.2,"Fiber Plants":0.6},"mix":{"Clay":0.68,"Fiber Plants":0.16,"Timber":0.08}}
	if "stone_selection" in GameState.known_discoveries and float(stocks.get("Stone",0.0))>=4.2 and float(stocks.get("Timber",0.0))>=0.8:
		return {"family":"stone","form":"dry_stone_household","cost":{"Stone":4.2,"Timber":0.8},"mix":{"Stone":0.72,"Timber":0.12,"Fiber Plants":0.06}}
	return {}

func _attempt_household_growth(day:int,events:Array[Dictionary],context:Dictionary={})->void:
	for plot in GameState.settlement_plots:
		if String(plot.get("status",""))=="under_construction": return
	var capacity:=_resident_capacity_for_growth()
	if GameState.population_total<=roundi(float(capacity)*0.88): return
	if int(GameState.population_allocations.get("Construction",0))<4: return
	var recipe:=_available_household_recipe()
	if recipe.is_empty(): return
	var plot:=_create_household_growth_plot(day,recipe,context)
	if plot.is_empty(): return
	for resource_name in recipe.cost:
		GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float(recipe.cost[resource_name]))
	_create_growth_route(plot,day)
	GameState.settlement_plots.append(plot)
	GameState.settlement_plot_history.append({"day":day,"plot_id":int(plot.id),"event":"construction_started","new_state":"under_construction","cause":"household crowding, available labor, and delivered materials"})
	GameState.morphology_revision+=1
	events.append({"type":"morphology","title":"New Household Ground Claimed","plot_id":int(plot.id)})

func _create_growth_route(plot:Dictionary,day:int,route_kind:String="desire_path")->void:
	var plot_center:=Vector2(plot.get("centroid",Vector2.ZERO))
	var nearest:=Vector2.ZERO
	var nearest_distance:=INF
	for existing in GameState.settlement_plots:
		var candidate:=Vector2(existing.get("centroid",Vector2.ZERO))
		var distance:=plot_center.distance_to(candidate)
		if distance<nearest_distance:
			nearest=candidate
			nearest_distance=distance
	var route_id:=1
	for route in GameState.settlement_routes: route_id=maxi(route_id,int(route.get("id",0))+1)
	var direction:=nearest-plot_center
	var side:=Vector2(-direction.y,direction.x).normalized()
	var bend_strength:=minf(0.004,nearest_distance*0.16)
	var bend_a:=plot_center.lerp(nearest,0.36)+side*sin(float(int(plot.id)*29+GameState.world_seed))*bend_strength
	var bend_b:=plot_center.lerp(nearest,0.72)-side*sin(float(int(plot.id)*17+GameState.world_seed)*0.67)*bend_strength*0.62
	GameState.settlement_routes.append({"id":route_id,"kind":route_kind,"points":PackedVector2Array([plot_center,bend_a,bend_b,nearest]),"condition":0.16 if route_kind=="field_track" else 0.22,"width_m":0.72 if route_kind=="field_track" else 0.58,"created_day":day,"active":true})
	plot["frontage_route_id"]=route_id

func _create_household_growth_plot(day:int,recipe:Dictionary,context:Dictionary={})->Dictionary:
	var plot_id:=GameState.next_settlement_plot_id
	var plot_seed:=hash("%d:settlement_growth:%d" % [GameState.world_seed,plot_id])
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed
	var radius:=rng.randf_range(0.007,0.010)
	var center:=Vector2.ZERO
	var best_center:=Vector2.ZERO
	var best_score:=-INF
	var anchors:Array[Dictionary]=[]
	for existing in GameState.settlement_plots:
		if String(existing.get("land_use","")) in ["residential_compound","mixed_household","communal","workshop"] and String(existing.get("status","")) not in ["ruin","reclaimed"]:
			anchors.append(existing)
	if anchors.is_empty(): return {}
	anchors.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return Vector2(a.get("centroid",Vector2.ZERO)).length()<Vector2(b.get("centroid",Vector2.ZERO)).length())
	var cluster_growth:=anchors.size()>=34 and plot_id%10 in [0,1,2]
	var cluster_phase:=floori(float(plot_id)/10.0)
	var cluster_angle:=fmod(float(hash("%d:outer_cluster:%d" % [GameState.world_seed,cluster_phase]))*0.000001,TAU)
	var cluster_target:=Vector2.from_angle(cluster_angle)*((0.145+float(cluster_phase%4)*0.016) if cluster_growth else 0.0)
	for attempt in 72:
		var anchor_index:=mini(anchors.size()-1,floori(pow(rng.randf(),2.15)*float(anchors.size())))
		if cluster_growth:
			var outer_start:=clampi(floori(float(anchors.size())*0.62),0,anchors.size()-1)
			anchor_index=rng.randi_range(outer_start,anchors.size()-1)
		var anchor:Dictionary=anchors[anchor_index]
		var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
		var anchor_polygon:PackedVector2Array=anchor.get("polygon",PackedVector2Array())
		var anchor_radius:=sqrt(_polygon_area_km2(anchor_polygon)/PI)
		var outward:=anchor_center.normalized() if anchor_center.length()>0.004 else Vector2.from_angle(rng.randf()*TAU)
		var angle:=rng.randf()*TAU
		if rng.randf()<0.28:
			angle=outward.angle()+rng.randf_range(-0.92,0.92)
		center=anchor_center+Vector2.from_angle(angle)*(anchor_radius+radius+rng.randf_range(0.0022,0.0065))
		var score:=_growth_site_score(center,radius,"residential_compound",context)
		# Most households infill, but a stable seeded minority follows the outer
		# frontage so a settlement develops irregular arms rather than a disk.
		if (plot_id+GameState.world_seed)%5==0: score+=exp(-absf(center.length()-0.14)/0.08)*0.82
		if cluster_growth: score+=exp(-center.distance_to(cluster_target)/0.075)*1.48
		if score>best_score:
			best_score=score
			best_center=center
	if best_score<=-9000.0: return {}
	center=best_center
	GameState.next_settlement_plot_id+=1
	var polygon:=_irregular_polygon(center,radius,plot_seed)
	return {
		"id":plot_id,"seed":plot_seed,"nucleus_id":1,"parent_plot_id":-1,"lineage_ids":[],"polygon":polygon,"centroid":_polygon_centroid(polygon),"area_ha":_polygon_area_km2(polygon)*100.0,"frontage_route_id":-1,
		"land_use":"residential_compound","secondary_use":"","form":recipe.form,"material_family":recipe.family,"material_mix":recipe.mix,"construction_recipe":"household_expansion","supply_provenance":recipe.cost.duplicate(true),"replacement_debt":{},"roof_coverage":0.30,"storeys":1,
		"resident_capacity":rng.randi_range(7,10),"resident_count":0,"worker_capacity":1,"worker_count":0,"storage_capacity":0.8,"condition":0.58,"maintenance_debt":0.0,"service_access":0.34,"hazard_exposure":rng.randf_range(0.08,0.20),"prosperity":0.31,
		"status":"under_construction","construction_progress":0.0,"growth_cause":"household crowding, available labor, and delivered materials","pre_damage_use":"","damage":{"structural":0.0,"fire":0.0,"contamination":0.0,"looting":0.0,"neglect":0.0},"habitability":0.0,"repair_state":"maintained","reoccupation_state":"occupied",
		"displaced_households":0,"returning_households":0,"claim_pressure":0.0,"created_day":day,"converted_day":-1,"damaged_day":-1,"abandoned_day":-1,"last_update_day":day
	}

func rebuild_summary()->Dictionary:
	var active_plots:=0
	var occupied_area:=0.0
	var built_area:=0.0
	var condition_total:=0.0
	var vacant:=0
	var ruins:=0
	var uses:Dictionary={}
	var occupied_capacity:=0
	for plot in GameState.settlement_plots:
		var area:=float(plot.get("area_ha",0.0))
		built_area+=area
		condition_total+=float(plot.get("condition",0.0))
		var status:=String(plot.get("status","active"))
		if status in ["active","stressed","damaged","under_construction"]:
			active_plots+=1
			occupied_area+=area
		if status=="vacant": vacant+=1
		if status=="ruin": ruins+=1
		if status in ["active","stressed"]: occupied_capacity+=int(plot.get("resident_capacity",0))
		if status not in ["vacant","ruin","reclaimed"]: uses[String(plot.get("land_use","vacant"))]=true
	var count:=GameState.settlement_plots.size()
	var population:=GameState.population_total
	var permanence:=clampf(0.16+float(active_plots)/maxf(1.0,float(count))*0.15+float(GameState.settlement_completed.size())*0.035,0.0,1.0)
	var specialization:=clampf(float(GameState.population_allocations.get("Crafting",0)+GameState.population_allocations.get("Extraction",0)+GameState.population_allocations.get("Knowledge",0)+GameState.population_allocations.get("Administration",0)+GameState.population_allocations.get("Logistics",0))/maxf(1.0,float(GameState.able_population())),0.0,1.0)
	var exchange:=clampf(float(GameState.simulation_metrics.get("logistics",0.16))*0.35+DiscoverySystem.effect("trade_capacity")*0.40,0.0,1.0)
	var institutions:=clampf(float(GameState.simulation_metrics.get("legitimacy",0.62))*0.35+float(GameState.population_allocations.get("Administration",0))/maxf(1.0,float(population)*0.06)*0.25,0.0,1.0)
	var connectivity:=clampf(float(GameState.simulation_metrics.get("logistics",0.16))*0.55+DiscoverySystem.effect("route_speed")*0.30,0.0,1.0)
	var infrastructure:=clampf(float(GameState.settlement_completed.size())/10.0+DiscoverySystem.effect("construction_rate")*0.20,0.0,1.0)
	var service_population:=roundi(float(population)*(1.0+exchange*0.55+connectivity*0.35))
	var food_import_share:=clampf(float(GameState.simulation_metrics.get("food_import_share",0.0)),0.0,1.0)
	var summary:Dictionary={
		"classification":"founding camp","classification_confidence":0.80,"resident_population":population,"service_population":service_population,
		"built_area_ha":built_area,"occupied_area_ha":occupied_area,"vacancy_ratio":float(vacant)/maxf(1.0,float(count)),"ruin_ratio":float(ruins)/maxf(1.0,float(count)),
		"mean_condition":condition_total/maxf(1.0,float(count)),"density_people_ha":float(population)/maxf(0.01,occupied_area),"permanence":permanence,
		"specialization":specialization,"exchange":exchange,"institutions":institutions,"connectivity":connectivity,"infrastructure":infrastructure,
		"diversity":clampf(float(uses.size())/12.0,0.0,1.0),"food_import_share":food_import_share,"active_nuclei":_active_nuclei(),"district_count":1,
		"usable_resident_capacity":occupied_capacity,"limiting_factors":[]
	}
	var classification_result:=_classify(summary)
	summary["classification"]=classification_result.classification
	summary["classification_confidence"]=classification_result.confidence
	summary["limiting_factors"]=classification_result.limits
	GameState.settlement_morphology=summary
	return summary

func _classify(summary:Dictionary)->Dictionary:
	var limits:Array[String]=[]
	if float(summary.permanence)<0.35: return {"classification":"founding camp","confidence":0.90,"limits":["permanent household fabric has not yet stabilized"]}
	if float(summary.permanence)<0.50:
		return {"classification":"hamlet","confidence":0.78,"limits":["permanence remains below village level"]}
	var communal_functions:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) in ["communal","storage","water","civic","sacred"] and String(plot.get("status",""))=="active": communal_functions+=1
	if float(summary.exchange)>=0.55 and float(summary.institutions)>=0.50 and float(summary.infrastructure)>=0.50 and float(summary.food_import_share)>=0.15 and int(summary.district_count)>=3 and float(summary.service_population)>=float(summary.resident_population)*1.5:
		return {"classification":"city","confidence":0.72,"limits":[]}
	if float(summary.exchange)>=0.35 and float(summary.specialization)>=0.30 and float(summary.connectivity)>=0.30 and int(summary.service_population)>int(summary.resident_population):
		return {"classification":"town","confidence":0.74,"limits":[]}
	if float(summary.permanence)>=0.50 and communal_functions>=2:
		if float(summary.exchange)<0.35: limits.append("exchange remains local or periodic")
		if float(summary.connectivity)<0.30: limits.append("regional travel remains costly")
		return {"classification":"village","confidence":0.76,"limits":limits}
	limits.append("shared permanent functions remain insufficient")
	return {"classification":"hamlet","confidence":0.70,"limits":limits}

func classification()->String:
	if GameState.settlement_morphology.is_empty(): rebuild_summary()
	return String(GameState.settlement_morphology.get("classification","founding camp"))

func classification_reason()->String:
	if GameState.settlement_morphology.is_empty(): rebuild_summary()
	var limits:Array=GameState.settlement_morphology.get("limiting_factors",[])
	return "Functional gates satisfied." if limits.is_empty() else "; ".join(limits)

func plots_for_lod(lod:int)->Array[Dictionary]:
	ensure_founded()
	return GameState.settlement_plots.duplicate(true)

func apply_plot_damage(plot_id:int,severity:float,cause:String)->Dictionary:
	for plot in GameState.settlement_plots:
		if int(plot.get("id",-1))!=plot_id: continue
		var bounded:=clampf(severity,0.0,1.0)
		plot["pre_damage_use"]=String(plot.get("land_use",""))
		plot["condition"]=clampf(float(plot.get("condition",1.0))-bounded,0.0,1.0)
		plot["damaged_day"]=int(floor(GameState.elapsed_days))
		var damage:Dictionary=plot.get("damage",{}).duplicate(true)
		var channel:="fire" if "fire" in cause.to_lower() else "structural"
		damage[channel]=clampf(float(damage.get(channel,0.0))+bounded,0.0,1.0)
		plot["damage"]=damage
		plot["status"]="ruin" if float(plot.condition)<0.20 else "damaged"
		plot["repair_state"]="unrepairable" if String(plot.status)=="ruin" else "awaiting_assessment"
		GameState.settlement_plot_history.append({"day":int(floor(GameState.elapsed_days)),"plot_id":plot_id,"event":"damage","new_state":plot.status,"cause":cause})
		GameState.morphology_revision+=1
		rebuild_summary()
		return plot
	return {}

func apply_area_damage(center_km:Vector2,radius_km:float,severity:float,cause:String)->Array[int]:
	var affected:Array[int]=[]
	for plot in GameState.settlement_plots:
		var distance:=Vector2(plot.get("centroid",Vector2.ZERO)).distance_to(center_km)
		if distance>radius_km: continue
		var falloff:=1.0-distance/maxf(0.001,radius_km)
		apply_plot_damage(int(plot.id),severity*falloff,cause)
		affected.append(int(plot.id))
	return affected

func abandon_plot(plot_id:int,cause:String)->Dictionary:
	for plot in GameState.settlement_plots:
		if int(plot.get("id",-1))!=plot_id: continue
		plot["status"]="vacant"
		plot["reoccupation_state"]="displaced"
		plot["abandoned_day"]=int(floor(GameState.elapsed_days))
		plot["resident_count"]=0
		GameState.settlement_plot_history.append({"day":int(floor(GameState.elapsed_days)),"plot_id":plot_id,"event":"abandoned","new_state":"vacant","cause":cause})
		GameState.morphology_revision+=1
		rebuild_summary()
		return plot
	return {}

func validate_state()->PackedStringArray:
	var errors:=PackedStringArray()
	var ids:Dictionary={}
	for plot in GameState.settlement_plots:
		var id:=int(plot.get("id",-1))
		if id<1: errors.append("plot has invalid id")
		elif ids.has(id): errors.append("duplicate plot id %d" % id)
		ids[id]=true
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		if polygon.size()<3: errors.append("plot %d has fewer than three vertices" % id)
		if _polygon_area_km2(polygon)<=0.0: errors.append("plot %d has non-positive area" % id)
		if String(plot.get("status","")) not in VALID_STATUSES: errors.append("plot %d has invalid status" % id)
		if String(plot.get("repair_state","")) not in VALID_REPAIR_STATES: errors.append("plot %d has invalid repair state" % id)
		if String(plot.get("reoccupation_state","")) not in VALID_REOCCUPATION_STATES: errors.append("plot %d has invalid reoccupation state" % id)
		if String(plot.get("land_use","")) not in VALID_LAND_USES: errors.append("plot %d has invalid land use" % id)
	return errors

func _polygon_area_km2(polygon:PackedVector2Array)->float:
	if polygon.size()<3: return 0.0
	var twice_area:=0.0
	for index in polygon.size():
		var next:=(index+1)%polygon.size()
		twice_area+=polygon[index].x*polygon[next].y-polygon[next].x*polygon[index].y
	return absf(twice_area)*0.5

func _polygon_centroid(polygon:PackedVector2Array)->Vector2:
	if polygon.is_empty(): return Vector2.ZERO
	var sum:=Vector2.ZERO
	for point in polygon: sum+=point
	return sum/float(polygon.size())

func _active_nuclei()->int:
	var count:=0
	for nucleus in GameState.settlement_nuclei:
		if bool(nucleus.get("active",true)): count+=1
	return count
