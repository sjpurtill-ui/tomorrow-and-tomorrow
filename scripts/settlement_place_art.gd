extends RefCounted
## A bounded, read-only interpretation of a named place. All positions are km;
## these marks never become construction, people, routes or a second ledger.
const SHAPES=preload("res://scripts/settlement_kit_shapes.gd")
const EARLY=preload("res://scripts/early_settlement_visual.gd")
const LATE=preload("res://scripts/settlement_architecture_kit.gd")
const TOWN=preload("res://scripts/organic_town_visual.gd")
const WALLS=preload("res://scripts/settlement_construction_mesh.gd")
const INK=preload("res://scripts/settlement_ink.gd")
const MAX_DETAILS:=12
const MAX_TRACK_POINTS:=129
const MAX_SHORE_SAMPLES:=320

static func ruin_fade(place:Dictionary)->float:
	if String(place.get("status","living"))!="ruin":return 1.0
	var elapsed:=maxi(0,int(place.get("day",0))-int(place.get("left_day",0)))
	return clampf(1.0-float(elapsed)/(365.0*80.0),0.12,1.0)

static func facing(place:Dictionary)->Vector2:
	var toward:Vector2=place.get("facing",Vector2.ZERO)
	return toward.normalized() if toward.length_squared()>0.001 else Vector2.ZERO

static func extent(plots:Array)->float:
	var radius:=0.022
	for plot:Dictionary in plots:
		for point:Vector2 in plot.get("polygon",PackedVector2Array()):radius=maxf(radius,point.length())
	return minf(radius,0.22)

## Find an actual dry bank within 640 metres of the inherited anchor. A broad
## founding water survey is not permission to place a jetty on a dry hillside.
static func shore(at:Vector2,toward:Vector2,land:Callable,water:Callable=Callable())->Dictionary:
	var state:=begin_shore(at,toward)
	while not advance_shore(state,land,water):pass
	return state.result

static func begin_shore(at:Vector2,toward:Vector2)->Dictionary:
	return {"origin":at,"facing":toward,"dry":at,"next":1,"result":{"position":at,"found":false}}

## One two-metre probe per preparation step preserves narrow channels without
## concentrating hundreds of actual terrain reads in a single renderer slice.
static func advance_shore(state:Dictionary,land:Callable,water:Callable)->bool:
	if not water.is_valid() or Vector2(state.facing).length_squared()<0.5 or int(state.next)>MAX_SHORE_SAMPLES:return true
	var test:=Vector2(state.origin)+Vector2(state.facing)*float(state.next)*0.002
	state.next=int(state.next)+1
	if not bool(water.call(test)):
		state.dry=test
		return false
	var dry:Vector2=state.dry;var wet:=test
	for refinement in 5:
		var middle:=(dry+wet)*0.5
		if bool(water.call(middle)):wet=middle
		else:dry=middle
	state.result={"position":dry,"found":not land.is_valid() or bool(land.call(dry))}
	return true

static func details(work:Dictionary,land:Callable,water:Callable=Callable(),shore_land:Callable=Callable(),edge_hint:Dictionary={})->Dictionary:
	var place:Dictionary=work.get("place",{})
	if place.is_empty():return {}
	var origin:Vector2=work.origin
	var toward:=facing(place);var along:=toward.orthogonal()
	var radius:=extent(work.plots)
	var edge:=edge_hint if not edge_hint.is_empty() else shore(origin,toward,shore_land if shore_land.is_valid() else land,water)
	var bank:Vector2=edge.position-toward*0.006 if bool(edge.found) else origin+toward*(radius+0.016)
	var out:={"props":[],"washes":[],"fields":[],"lines":[],"bank":edge.position,"shore_found":edge.found}
	var ruin:=String(place.get("status","living"))=="ruin"
	var fade:=ruin_fade(place)
	if ruin:
		for index in mini(work.plots.size(),12):
			var plot:Dictionary=work.plots[index]
			out.washes.append({"position":origin+Vector2(plot.get("centroid",Vector2.ZERO)),"radius":0.008,"color":Color(0.37,0.43,0.24,0.22+0.32*(1.0-fade)),"kind":"overgrowth"})
		return out
	if bool(edge.found):out.lines.append({"start":origin,"finish":bank,"width":0.0012,"kind":"shore_access","shoreline":true})
	var kind:=String(place.get("kind","inland"))
	if kind!="inland" and toward==Vector2.ZERO:kind="unknown_bearing"
	if kind in ["coast","lake","river"] and not bool(edge.found):kind="unverified_shore"
	match kind:
		"coast":
			for index in 2:
				out.props.append({"kind":"dugout","position":bank+along*(0.007+float(index)*0.009),"angle":atan2(toward.x,toward.y)+float(index)*0.12,"shoreline":true})
			out.props.append({"kind":"drying_rack","position":bank-along*0.011-toward*0.004,"angle":atan2(toward.x,toward.y),"shoreline":true})
			if float(place.get("open_water",0.0))>=0.40:
				for index in 2:
					out.fields.append({"center":bank-along*(0.022+float(index)*0.007)-toward*0.007,"angle":along.angle(),"half_length_km":0.005,"half_width_km":0.0025,"color":Color(0.78,0.76,0.62,0.72),"kind":"salt_pan","shoreline":true})
		"lake":
			for index in 5:
				out.props.append({"kind":"reeds","position":bank+along*(float(index)-2.0)*0.006+toward*0.003,"angle":float(index),"shoreline":true})
			var reach:=jetty_reach(edge.position,toward,water)
			if reach>0.0005:out.props.append({"kind":"jetty","position":Vector2(edge.position)-toward*0.001,"angle":atan2(toward.x,toward.y),"over_water":true,"shoreline":true,"length_scale":(reach+0.001)/0.0082})
		"river":
			out.lines.append({"start":bank-along*0.038,"finish":bank+along*0.038,"width":0.0014,"kind":"bank_track"})
			out.lines.append({"start":bank-toward*0.018,"finish":bank+toward*0.008,"width":0.0020,"kind":"crossing_track"})
		"inland":
			for index in 2:
				out.fields.append({"center":origin+Vector2.from_angle(0.7+float(index)*2.1)*(radius+0.015),"angle":0.3+float(index)*0.6,"half_length_km":0.012,"half_width_km":0.005,"color":Color(0.57,0.55,0.33,0.58),"kind":"field_plot"})
	if bool(place.get("flooded",false)):
		# The damaged side follows the recorded water bearing, never the camera.
		for index in (1 if toward==Vector2.ZERO else 3):
			out.washes.append({"position":origin+toward*radius*0.45+along*(float(index)-1.0)*radius*0.35,"radius":radius*0.52,"color":Color(0.40,0.42,0.34,0.66),"kind":"flood_wash"})
	if int(place.get("trend",0))>0:
		# New work belongs at the edge. Existing house sites are not transformed
		# into frames when shares fluctuate, so their roofs remain stationary.
		for index in 16:
			var point:=origin+Vector2.from_angle(2.4+float(index)*0.41)*(radius+0.007)
			if land.is_valid() and not bool(land.call(point)):continue
			out.props.append({"kind":"frame","position":point,"angle":float(index)*0.41})
			out.washes.append({"position":point,"radius":0.004,"color":Color(0.63,0.52,0.37,0.50),"kind":"building_site"})
			break
	return out

## Measure only the short landing itself. Sub-metre samples stop the landing
## before the opposite bank of a narrow channel instead of drawing a bridge.
static func jetty_reach(bank:Vector2,toward:Vector2,water:Callable)->float:
	if not water.is_valid():return 0.0
	var reach:=0.0
	for index in range(1,17):
		var distance:=float(index)*0.0005
		var point:=bank+toward*distance
		if not bool(water.call(point)):
			if reach>0.0:break
			continue
		reach=distance
	return maxf(0.0,reach-0.0004)

## Fixed work budget; a local dry detour keeps bends inland. Impossible long
## crossings remain clipped rather than depicting a fictitious bridge.
static func begin_track(start:Vector2,finish:Vector2,place:Dictionary)->Dictionary:
	var distance:=start.distance_to(finish)
	return {"points":PackedVector2Array([start]),"start":start,"finish":finish,"next":1,
		"segments":clampi(ceili(distance/0.10),4,MAX_TRACK_POINTS-1),"distance":distance,
		"cross":(finish-start).normalized().orthogonal(),"facing":facing(place)}

static func advance_track(state:Dictionary,land:Callable)->bool:
	var points:PackedVector2Array=state.points
	if int(state.next)>=int(state.segments):
		points.append(state.finish);state.points=points
		return true
	var fraction:=float(state.next)/float(state.segments)
	var intended:=Vector2(state.start).lerp(state.finish,fraction)
	var selected:=intended;var score:=INF
	var step:=minf(0.6,maxf(0.015,float(state.distance)/float(state.segments)))
	var cross:Vector2=state.cross;var toward:Vector2=state.facing
	for offset:Vector2 in [Vector2.ZERO,cross*step,-cross*step,cross*step*2.0,-cross*step*2.0,-toward*step,-toward*step*2.0]:
		var candidate:=intended+offset
		if land.is_valid() and (not bool(land.call(candidate)) or not bool(land.call(points[-1].lerp(candidate,0.5)))):continue
		var cost:=candidate.distance_to(points[-1])+candidate.distance_to(state.finish)*0.2+offset.length()*0.4
		if cost<score:selected=candidate;score=cost
	points.append(selected);state.points=points;state.next=int(state.next)+1
	return false

static func track_points(start:Vector2,finish:Vector2,place:Dictionary,land:Callable)->PackedVector2Array:
	var state:=begin_track(start,finish,place)
	while not advance_track(state,land):pass
	return state.points

static func label(place:Dictionary,origin:Vector2,height:Callable)->Label3D:
	var node:=Label3D.new();node.name="PlaceChartName"
	node.text=String(place.get("name",""));node.font=preload("res://assets/fonts/serif/EBGaramond-Italic.ttf")
	# Match the root label's base pixel scale. Its shared aerial normalizer
	# multiplies font resolution by four and divides this scale by sixteen.
	node.font_size=9;node.outline_size=2;node.pixel_size=0.005
	node.modulate=Color(0.31,0.25,0.16,0.82*ruin_fade(place))
	node.outline_modulate=Color(0.88,0.83,0.70,0.64)
	node.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.fixed_size=true;node.no_depth_test=true
	node.render_priority=10;node.offset=Vector2(0,-20)
	node.position=Vector3(origin.x,float(height.call(origin))+0.008,origin.y)
	return node

static func render_props(parent:Node3D,detail:Dictionary,height:Callable,valid:Callable,revealed:Callable=Callable(),shore_valid:Callable=Callable())->void:
	var kinds:Array[String]=[];var positions:Array[Vector2]=[]
	for entry:Dictionary in (detail.get("props",[]) as Array).slice(0,MAX_DETAILS):
		var point:Vector2=entry.position
		var mesh:Mesh=_reed_mesh() if String(entry.kind)=="reeds" else SHAPES.prop(String(entry.kind))
		if mesh==null:continue
		var basis:=Basis(Vector3.UP,float(entry.angle))*Basis.from_scale(Vector3(0.001,0.001,0.001*float(entry.get("length_scale",1.0))))
		var ground:Callable=shore_valid if bool(entry.get("shoreline",false)) and shore_valid.is_valid() else valid
		var clear:=bool(ground.call(point))
		var bounds:=mesh.get_aabb()
		for x:float in [bounds.position.x,bounds.end.x]:
			for z:float in [bounds.position.z,bounds.end.z]:
				var offset:=basis*Vector3(x,0,z)
				var corner:=point+Vector2(offset.x,offset.z)
				if revealed.is_valid() and not bool(revealed.call(corner)):clear=false
				if not bool(entry.get("over_water",false)) and not bool(ground.call(corner)):clear=false
		if not clear:continue
		var node:=MeshInstance3D.new();node.name="Place_"+String(entry.kind)
		node.mesh=mesh;node.material_override=INK.architecture_material()
		node.transform=Transform3D(basis,Vector3(point.x,float(height.call(point))+0.0001,point.y))
		node.set_meta("place_detail",entry.kind);parent.add_child(node)
		kinds.append(String(entry.kind));positions.append(point)
	for group:String in ["fields","washes","lines"]:
		for entry:Dictionary in detail.get(group,[]):kinds.append(String(entry.kind))
	parent.set_meta("place_detail_kinds",kinds);parent.set_meta("place_detail_positions",positions)
	parent.set_meta("place_shore_found",detail.get("shore_found",false))

static var _reeds:Mesh
static func _reed_mesh()->Mesh:
	if _reeds!=null:return _reeds
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 7:
		var at:=Vector3(sin(float(index)*2.4)*0.6,0,cos(float(index)*2.4)*0.6)
		var top:=at+Vector3(0.2,0.8+float(index%3)*0.20,0.1)
		SHAPES._beam(surface,at,top,0.024,Color(0.37,0.42,0.22))
		SHAPES._beam(surface,top-Vector3(0,0.14,0),top+Vector3(0,0.10,0),0.05,Color(0.43,0.32,0.19))
	_reeds=surface.commit();return _reeds

## Return the occupied display subset; damaged houses keep their original
## foundation and use the original completed kit's roofless wall geometry.
static func render_damage(parent:Node3D,shown:Dictionary,place:Dictionary,origin:Vector2,height:Callable)->Dictionary:
	if place.is_empty():return shown
	var ruin:=String(place.get("status","living"))=="ruin"
	var count:=mini(3,maxi(1,(shown.buildings as Array).size()/8)) if int(place.get("trend",0))<0 else 0
	if ruin:count=(shown.buildings as Array).size()
	var ranked:Array=(shown.buildings as Array).duplicate(false)
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return hash(String(a.id)+":decline")<hash(String(b.id)+":decline"))
	var damaged:Dictionary={}
	for entry:Dictionary in ranked.slice(0,count):damaged[entry.id]=true
	var occupied:Array=[]
	var fade:=ruin_fade(place)
	var groups:Dictionary={}
	for building:Dictionary in shown.buildings:
		if not damaged.has(building.id):occupied.append(building);continue
		var plot:Dictionary=building.plot
		var source:Mesh
		if LATE.kind(plot)!="":source=LATE.mesh_for_plot(plot)
		elif String(building.get("early_kind","")) in EARLY.KIT:source=EARLY.kit_mesh(String(building.early_kind))
		elif TOWN.supports(plot):source=TOWN.kit_mesh(clampi(int(building.get("variant",0)),0,TOWN.KIT.size()-1))
		if source==null:continue
		var mesh:Mesh=WALLS.mesh(source,plot,2)
		if mesh==null:continue
		var point:=origin+Vector2(building.position)
		var basis:=EARLY.site_basis(building)
		basis=Basis.from_scale(Vector3(1.0,lerpf(0.15,0.74,fade),1.0))*basis
		var key:=mesh.get_instance_id()
		if not groups.has(key):groups[key]={"mesh":mesh,"transforms":[],"ids":[]}
		groups[key].transforms.append(Transform3D(basis,Vector3(point.x,float(height.call(point))+0.0001,point.y)))
		groups[key].ids.append(building.id)
		if not ruin:
			var debris:=MeshInstance3D.new();debris.name="PlaceFallenRoof"
			debris.mesh=SHAPES.prop("timber_stack");debris.material_override=INK.architecture_material()
			debris.transform=Transform3D(EARLY.site_basis(building),Vector3(point.x,float(height.call(point))+0.0001,point.y))
			debris.set_meta("place_detail","fallen_roof");parent.add_child(debris)
	for group:Dictionary in groups.values():
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
		batch.mesh=group.mesh;batch.instance_count=group.transforms.size()
		for index in group.transforms.size():
			batch.set_instance_transform(index,group.transforms[index])
			batch.set_instance_color(index,Color.WHITE.lerp(Color(0.50,0.52,0.39),1.0-fade*0.55))
		var node:=MultiMeshInstance3D.new();node.name="PlaceRooflessWalls";node.multimesh=batch;node.material_override=INK.architecture_material()
		node.set_meta("place_ruin",ruin);node.set_meta("place_roofless_ids",group.ids);node.set_meta("place_fade",fade)
		parent.add_child(node)
	parent.set_meta("place_damaged_roofs",damaged.size())
	return {"buildings":occupied,"replaced":shown.replaced}
