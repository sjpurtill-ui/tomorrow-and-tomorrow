extends RefCounted
## A later-era market town fabric for reviewing settlement art as it grows
## (map_art_capture.gd --town, and the settlement art tests). A fixture only:
## nothing is simulated. Masonry and timber houses along streets round a
## market plaza, halls, workshops and stores, a well, and fields in their
## season all round. Plot positions are settlement-local kilometres.

static func build()->Dictionary:
	var plots:Array[Dictionary]=[]
	var routes:Array[Dictionary]=[]
	var rng:=RandomNumberGenerator.new();rng.seed=4417
	var next_route:=[1]
	var add_route:=func(points:PackedVector2Array,hierarchy:String,width:float,tier:int,traffic:float)->int:
		var id:int=next_route[0];next_route[0]+=1
		routes.append({"id":id,"active":true,"points":points,"hierarchy":hierarchy,"kind":"street" if tier>=2 else "desire_path","width_m":width,"surface_tier":tier,"traffic":traffic,"condition":0.9,"surface":"packed_earth"})
		return id
	# Two main streets crossing at the plaza, a ring lane, and side lanes.
	var main_ew:int=add_route.call(PackedVector2Array([Vector2(-0.16,0.004),Vector2(-0.07,-0.004),Vector2(0.0,0.0),Vector2(0.07,0.006),Vector2(0.16,-0.002)]),"main_approach",4.5,3,1.0)
	var main_ns:int=add_route.call(PackedVector2Array([Vector2(0.003,-0.16),Vector2(-0.005,-0.07),Vector2(0.0,0.0),Vector2(0.006,0.07),Vector2(-0.002,0.16)]),"main_approach",4.2,3,0.9)
	# The ring lane as four open arcs between the main streets (a closed
	# polyline would read to the placement solver as one filled envelope).
	var ring_id:=0
	for quarter in 4:
		var ring:=PackedVector2Array()
		for k in 6:
			var a:=TAU*(float(quarter)+0.08+float(k)*0.168)/4.0
			ring.append(Vector2(cos(a),sin(a))*(0.085+0.006*sin(a*3.0)))
		var arc:int=add_route.call(ring,"lane",2.8,2,0.6)
		if quarter==0:ring_id=arc
	var id:=[1]
	var add_plot:=func(center:Vector2,angle:float,size:Vector2,use:String,form:String,family:String,roof:String,generation:int,route:int,extra:Dictionary={})->void:
		var forward:=Vector2(sin(angle),cos(angle));var side:=forward.orthogonal()
		var polygon:=PackedVector2Array([center-side*size.x-forward*size.y,center+side*size.x-forward*size.y,center+side*size.x+forward*size.y,center-side*size.x+forward*size.y])
		# The same winding as the recorded parcels (the placement solver clips with it).
		if Geometry2D.is_polygon_clockwise(polygon)!=Geometry2D.is_polygon_clockwise(PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)])):polygon.reverse()
		var plot:={"id":id[0],"seed":rng.randi(),"centroid":center,"polygon":polygon,"frontage_route_id":route,"area_ha":size.x*size.y*4.0*100.0,
			"land_use":use,"form":form,"material_family":family,"roof_plan":roof,"status":"active","condition":0.9,"storeys":1,
			"fabric_generation":generation,"resident_count":8 if use in ["residential_compound","mixed_household"] else 0,"worker_count":6,
			"damage":{},"roof_coverage":0.5}
		plot.merge(extra,true)
		plots.append(plot);id[0]+=1
	# The market plaza and the public buildings round it.
	add_plot.call(Vector2(0.0,0.0),0.0,Vector2(0.012,0.012),"communal","maintained_gathering_ground","earth","courtyard_flat",1,main_ew)
	add_plot.call(Vector2(0.034,-0.030),0.3,Vector2(0.016,0.016),"market","periodic_market_court","stone","timber_ridge",5,main_ew)
	add_plot.call(Vector2(-0.036,0.032),PI+0.2,Vector2(0.016,0.016),"civic","durable_assembly_compound","stone","timber_ridge",5,main_ns)
	add_plot.call(Vector2(-0.034,-0.036),0.9,Vector2(0.015,0.015),"sacred","customary_precinct","stone","timber_ridge",5,main_ns)
	# Houses along the streets: masonry toward the centre, timber further out.
	for street in [[Vector2(1,0),main_ew],[Vector2(-1,0),main_ew],[Vector2(0,1),main_ns],[Vector2(0,-1),main_ns]]:
		var dir:Vector2=street[0]
		for k in 7:
			for side_sign in [-1.0,1.0]:
				var along:=0.040+float(k)*0.018
				var at:Vector2=dir*along+dir.orthogonal()*float(side_sign)*(0.021 if along<0.075 else 0.016)+Vector2(rng.randf_range(-0.002,0.002),rng.randf_range(-0.002,0.002))
				var toward:Vector2=-dir.orthogonal()*float(side_sign)
				var angle:=atan2(toward.x,toward.y)
				if along<0.075:
					var use:="mixed_household" if k%3==1 else "residential_compound"
					add_plot.call(at,angle,Vector2(0.0085,0.010),use,"durable_household_cluster","stone","timber_ridge",4+k%2,street[1])
				elif k%4==3:
					add_plot.call(at,angle,Vector2(0.0085,0.010),"workshop","workshop_frontage","timber","timber_ridge",4,street[1])
				else:
					add_plot.call(at,angle,Vector2(0.006,0.0075),"residential_compound","durable_household_cluster","organic","timber_ridge",2,street[1])
	# Stores and a well by the ring lane.
	for k in 4:
		var a:=TAU*(float(k)+0.5)/4.0
		add_plot.call(Vector2(cos(a),sin(a))*0.108,a,Vector2(0.009,0.010),"storage","granary_compound","stone","timber_ridge",4,ring_id)
	add_plot.call(Vector2(0.045,0.040),0.0,Vector2(0.004,0.004),"water","carried_water_point","earth","courtyard_flat",2,ring_id)
	# Fields all round, in their season.
	var phases:=["growing","mature","growing","harvested","prepared","mature","growing","fallow"]
	var crops:=["grain","grain","pulses","grain","roots","fibre_crop","grain","pulses"]
	for k in 8:
		var a:=TAU*float(k)/8.0+0.2
		var c:=Vector2(cos(a),sin(a))*0.19
		var track:int=add_route.call(PackedVector2Array([Vector2(cos(a),sin(a))*0.09,c*0.85]),"farm_lane",1.6,1,0.5)
		add_plot.call(c,a,Vector2(0.030,0.045),"field","hand_cultivated_clearance","earth","",1,track,{"cultivation_phase":phases[k],"crop_family":crops[k],"crop_cover":0.7,"field_pattern":"consolidated_field_strips" if k%2==0 else "smallholder_mosaic","storeys":0,"worker_count":12})
	return {"plots":plots,"routes":routes}
