extends Node3D
## Render-only settlement fabric. Identity/location come from returned evidence;
## unknown demographics and architecture never query a hidden civilization.
const MAX_BUILDINGS:=128
var building_count:=0
var footprint_radius:=.065
var ground:Callable
var origin:=Vector2.ZERO
var surfaces:Dictionary={}
var _country_visual:Node3D
var _country_style:Dictionary={}
static func display_population(report:Dictionary)->int:
	var estimate:Dictionary=report.get("fields",{}).get("population",{})
	return roundi((float(estimate.low)+float(estimate.high))*.5) if not estimate.is_empty() else -1
static func stable_population(report:Dictionary,previous:int)->int:
	var estimate:Dictionary=report.get("fields",{}).get("population",{})
	# Repeated lookout estimates vary. Keep the existing visual representation
	# while the new evidence still supports it; this is not a demographic census.
	if previous>=0 and not estimate.is_empty() and previous>=float(estimate.low) and previous<=float(estimate.high):return previous
	return display_population(report)
static func framing_size(report:Dictionary)->float:
	var population:=display_population(report)
	return clampf(.22+sqrt(maxf(0,population))*.0015,.22,.8)
func build(report:Dictionary,height_at:Callable,country_snapshot:Dictionary={})->void:
	ground=height_at;origin=Vector2(float(report.position.x),float(report.position.z))
	position=Vector3(origin.x,0,origin.y)
	set_meta("city_id",String(report.city_id));set_meta("details_confirmed",not report.get("fields",{}).is_empty())
	var population:=display_population(report)
	building_count=clampi(roundi(sqrt(float(population))*1.6),12,MAX_BUILDINGS) if population>=0 else 28
	footprint_radius=framing_size(report)*.27
	set_meta("representative_layout",true)
	var rng:=RandomNumberGenerator.new();rng.seed=hash(String(report.city_id))^WorldSimulation.state.world_seed
	# Round five (codex/beauty-5): a stranger's town grows the way a place
	# does, not on a grid. Lanes wander out from a meeting ground, houses
	# stand along them facing the lane and gather in kin yards off them, and
	# every people builds in its own way (style_for: round thatch, long
	# houses, packed mud brick, or a camp of painted hides), in its own
	# colours. Representative households only: nothing here is a census.
	var style:=style_for(report)
	_country_style=style
	people_style=String(style.name)
	var heading:=rng.randf_range(-PI,PI)
	var plan:Dictionary={"buildings":[],"replaced":{}}
	var lanes_drawn:Array[PackedVector2Array]=[]
	var spacing:=float(style.spacing)
	var lane_count:=clampi(2+building_count/24,2,5) if String(style.name)!="hide_camp" else 0
	# Lanes only as long as the houses along them need (a hamlet is a knot of
	# houses round its yard, not a spider of empty tracks).
	var lane_length:=spacing*(1.6+float(building_count)/float(maxi(lane_count,1))*0.26*float(style.frontage))
	var lane_paths:Array[PackedVector2Array]=[]
	for lane in lane_count:
		# Each lane leaves the meeting ground on its own bearing and bends as
		# the ground and the old footpaths had it.
		var bearing:=heading+TAU*float(lane)/float(lane_count)+rng.randf_range(-0.35,0.35)
		var bend:=rng.randf_range(-0.9,0.9)
		var path:=PackedVector2Array([Vector2.from_angle(bearing)*spacing*0.9])
		var steps:=6
		for k in range(1,steps+1):
			var t:=float(k)/float(steps)
			var angle:=bearing+bend*t*t*0.8+sin(t*5.0+float(lane))*0.08
			path.append(path[path.size()-1]+Vector2.from_angle(angle)*lane_length/float(steps)*rng.randf_range(0.85,1.15))
		lane_paths.append(path)
		lanes_drawn.append(path)
	var placed:Array[Vector2]=[]
	var clear:=spacing*0.78
	if String(style.name)=="hide_camp":
		# Tents in loose rings round the meeting ground, doors inward.
		var ring:=0
		while plan.buildings.size()<building_count and ring<14:
			var radius:=spacing*(1.4+float(ring)*1.05)
			var around:=maxi(5,int(TAU*radius/(spacing*1.05)))
			for k in around:
				if plan.buildings.size()>=building_count:break
				var angle:=heading+TAU*(float(k)+rng.randf_range(-0.25,0.25))/float(around)+float(ring)*0.4
				var at:=Vector2.from_angle(angle)*radius*rng.randf_range(0.93,1.07)
				if _free(at,placed,spacing,clear):_add(plan,placed,at,Vector2.ZERO,spacing)
			ring+=1
	else:
		# Houses along the lanes, alternate sides, facing the lane; then kin
		# yards (a few houses round a shared yard) set back behind them.
		var along:=spacing*float(style.frontage)
		var reach:=0
		while plan.buildings.size()<building_count and reach<40:
			for lane in lane_paths:
				var distance:=spacing*1.2+float(reach)*along
				var point:=_along(lane,distance)
				if point==Vector2.INF:continue
				var ahead:=_along(lane,distance+0.002)
				if ahead==Vector2.INF:ahead=point+(point-_along(lane,distance-0.002))
				var across:=(ahead-point).normalized().orthogonal()
				var side:=across*(1.0 if reach%2==0 else -1.0)
				# A house on each side of the lane, facing it, a little staggered.
				for flip in [1.0,-1.0]:
					var at:Vector2=point+side*float(flip)*spacing*rng.randf_range(0.62,0.80)+(ahead-point).normalized()*spacing*rng.randf_range(-0.2,0.2)
					if plan.buildings.size()<building_count and _free(at,placed,spacing,clear):_add(plan,placed,at,point,spacing,lane_paths.find(lane)+1)
				if bool(style.yards) and reach%3==1 and plan.buildings.size()<building_count:
					# A kin yard behind the frontage house.
					var yard:=point+side*spacing*2.1
					for k in 3:
						var around:=yard+Vector2.from_angle(TAU*float(k)/3.0+rng.randf())*spacing*0.72
						if plan.buildings.size()<building_count and _free(around,placed,spacing,clear):_add(plan,placed,around,yard,spacing,lane_paths.find(lane)+1)
			reach+=1
	# Any left over fill in near the meeting ground, facing it.
	var tries:=0
	while plan.buildings.size()<building_count and tries<building_count*16:
		tries+=1
		var at:=Vector2.from_angle(rng.randf()*TAU)*spacing*sqrt(rng.randf())*(2.5+sqrt(float(building_count))*1.2)
		if _free(at,placed,spacing,clear):_add(plan,placed,at,Vector2.ZERO,spacing)
	# Everything placed is drawn (the batches hold exactly building_count).
	building_count=plan.buildings.size()
	for record in plan.buildings:footprint_radius=maxf(footprint_radius,Vector2(record.position).length()+spacing*0.5)
	_render_people(plan,style)
	# Their worn ground: yards round the houses, the meeting ground and the
	# lanes, painted into the land when the camera comes near
	# (settlement_grounds.gd). Visual only.
	var ground_routes:Array[Dictionary]=[]
	for index in lanes_drawn.size():
		ground_routes.append({"id":index+1,"active":true,"points":lanes_drawn[index],"width_m":1.6,"traffic":0.55,"hierarchy":"path","kind":"street"})
	var ground_plots:Array[Dictionary]=[{"id":1,"form":"maintained_gathering_ground","land_use":"communal","status":"active","centroid":Vector2.ZERO,"area_ha":0.05}]
	preload("res://scripts/settlement_grounds.gd").request("foreign:"+String(report.city_id),plan,ground_plots,ground_routes,Vector3(origin.x,0.0,origin.y))
	# Buildings and earth are batched, with no per-resident nodes or gameplay state.
	for key:String in surfaces:
		var surface:SurfaceTool=surfaces[key];surface.generate_normals()
		var instance:=MeshInstance3D.new();instance.name=key;instance.mesh=surface.commit()
		var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness=.94;material.cull_mode=BaseMaterial3D.CULL_DISABLED
		instance.material_override=material;add_child(instance)
	set_meta("building_count",building_count)
	if not country_snapshot.is_empty():update_country(country_snapshot)

## The map supplies a read-only snapshot of revealed country. This renderer
## never looks up a hidden census, a rival's stores or unreported work sites.
## The shared layer retains its patches between snapshots and draws the same
## fields, farmsteads and worked-ground history in this people's house forms.
func update_country(snapshot:Dictionary,land_at:Callable=Callable())->void:
	if snapshot.is_empty():
		if is_instance_valid(_country_visual):_country_visual.hide()
		set_process(false)
		return
	if not is_instance_valid(_country_visual):
		_country_visual=preload("res://scripts/settlement_country_visual.gd").new()
		_country_visual.name="ForeignWorkedCountry"
		# Country patches use world coordinates; the town is already anchored
		# at its reported origin, either directly or by its containing marker.
		_country_visual.position=Vector3(-origin.x,0.0,-origin.y)
		add_child(_country_visual)
	_country_visual.configure(func(at:Vector2)->float:return float(ground.call(at.x,at.y)),land_at)
	_country_visual.request(snapshot,_country_style)
	_country_visual.show()
	set_process(true)

func country_stats()->Dictionary:
	return _country_visual.stats() if is_instance_valid(_country_visual) else {}

func _ready()->void:
	set_process(is_instance_valid(_country_visual))

func _process(_delta:float)->void:
	if not is_instance_valid(_country_visual):
		set_process(false)
		return
	if not is_visible_in_tree():return
	# One bounded retained patch per frame, only while a changed snapshot
	# has work queued. An unchanged foreign town has no frame/day rebuild.
	_country_visual.process_jobs(1000,1)
	if int(_country_visual.stats().get("pending",0))==0:set_process(false)
## How a people builds, from who they are (their identity is what the report
## gives; nothing hidden is read): house form, colours, how closely they
## build and whether kin share yards. Era-true for the early world.
const STYLES:=[
	{"name":"round_thatch","kinds":["round_household","round_household","round_household","raised_store"],"tint":Color(1.04,0.98,0.86),"spacing":0.0105,"frontage":1.25,"yards":true},
	{"name":"long_house","kinds":["house_narrow","house_compact","house_narrow","house_medium","raised_store"],"tint":Color(0.86,0.84,0.80),"spacing":0.0135,"frontage":1.35,"yards":false},
	{"name":"mud_brick","kinds":["earthen_household","earthen_household","earthen_household","covered_workshop"],"tint":Color(1.08,1.0,0.90),"spacing":0.0082,"frontage":1.0,"yards":true},
	{"name":"hide_camp","kinds":["carried_round","carried_round","carried_ridge"],"tint":Color(1.02,0.84,0.70),"spacing":0.0090,"frontage":1.0,"yards":false}]
var people_style:=""
static func style_for(report:Dictionary)->Dictionary:
	var who:=String(report.get("civ_id",""))
	if who=="":who=String(report.get("city_id",""))
	return STYLES[absi(hash(who+":builds"))%STYLES.size()]

static func _free(at:Vector2,placed:Array[Vector2],spacing:float,clear:float)->bool:
	if at.length()<spacing*1.05:return false
	for other in placed:
		if other.distance_to(at)<clear:return false
	return true

static func _add(plan:Dictionary,placed:Array[Vector2],at:Vector2,facing:Vector2,spacing:float,lane:=-1)->void:
	var forward:=(facing-at).normalized() if facing.distance_to(at)>0.0001 else Vector2(0,1)
	placed.append(at)
	# The door's own path runs to the lane it fronts (the ground painter).
	plan.buildings.append({"position":at,"angle":atan2(forward.x,forward.y),"variant":0,"radius":spacing*0.32,"plot":{"frontage_route_id":lane}})

## The point `distance` km along a path, or INF past its end.
static func _along(path:PackedVector2Array,distance:float)->Vector2:
	if distance<0.0:return Vector2.INF
	var left:=distance
	for i in range(1,path.size()):
		var step:=path[i-1].distance_to(path[i])
		if left<=step:return path[i-1].lerp(path[i],left/maxf(step,0.000001))
		left-=step
	return Vector2.INF

## The houses in the people's own form and colours, batched per form, each
## a little its own size and lean, standing on their soft ground shadows.
func _render_people(plan:Dictionary,style:Dictionary)->void:
	var early:=preload("res://scripts/early_settlement_visual.gd")
	var town:=preload("res://scripts/organic_town_visual.gd")
	var shapes:=preload("res://scripts/settlement_kit_shapes.gd")
	var ink:=preload("res://scripts/settlement_ink.gd")
	var kinds:Array=style.kinds
	var groups:Dictionary={}
	for record:Dictionary in plan.buildings:
		var name:String=kinds[absi(hash(Vector2(record.position)))%kinds.size()]
		record["early_kind"]=name
		if not groups.has(name):groups[name]=[]
		groups[name].append(record)
	var names:=groups.keys();names.sort()
	for name:String in names:
		var records:Array=groups[name]
		var mesh:Mesh=town.kit_mesh(town.KIT.find(name)) if name.begins_with("house_") else early.kit_mesh(name)
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
		batch.mesh=mesh;batch.instance_count=records.size()
		var transforms:Array[Transform3D]=[]
		for i in records.size():
			var record:Dictionary=records[i]
			var at:Vector2=record.position
			var transform:=Transform3D(shapes.lived_basis(float(record.angle),hash(at)),Vector3(at.x,_height(at)+0.0002,at.y))
			transforms.append(transform);batch.set_instance_transform(i,transform)
			# The people's colours, each house a little weathered its own way.
			var weather:=float(absi(hash(at+Vector2(3,7)))%100)/100.0
			batch.set_instance_color(i,(style.tint as Color).lerp(Color(0.80,0.76,0.70),weather*0.18))
		var node:=MultiMeshInstance3D.new();node.name="ForeignHouses_"+name
		node.multimesh=batch;node.material_override=ink.material()
		node.set_meta("source_transforms",transforms);add_child(node)
		ink.add_ground_shadows(self,"GroundShadow_"+name,transforms,mesh.get_aabb())

func _height(p:Vector2)->float:return float(ground.call(origin.x+p.x,origin.y+p.y))
func _tri(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,color:Color)->void:
	for v in [a,b,c]:surface.set_color(color);surface.add_vertex(v)
func _quad(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,color:Color)->void:
	_tri(surface,a,b,c,color);_tri(surface,a,c,d,color)
func _lane(a:Vector2,b:Vector2,width:float,color:Color)->void:
	var side:=(b-a).normalized().orthogonal()*width*.5
	var points:Array[Vector2]=[a-side,a+side,b+side,b-side]
	var corners:Array[Vector3]=[]
	for p in points:corners.append(Vector3(p.x,_height(p)+.0016,p.y))
	_quad(surfaces.EarthAndLanes,corners[0],corners[1],corners[2],corners[3],color)
	for edge:int in [-1,1]:
		var inner_a:=a+side*edge;var inner_b:=b+side*edge
		var outer_a:=a+side*edge*1.8;var outer_b:=b+side*edge*1.8
		var points_fade:Array[Vector2]=[inner_a,inner_b,outer_b,inner_a,outer_b,outer_a]
		for index in 6:
			var p:=points_fade[index]
			var tint:=color;tint.a=0.0 if index in [2,4,5] else color.a
			surfaces.EarthAndLanes.set_color(tint);surfaces.EarthAndLanes.add_vertex(Vector3(p.x,_height(p)+.0016,p.y))
