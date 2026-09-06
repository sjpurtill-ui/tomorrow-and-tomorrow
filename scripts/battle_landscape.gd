class_name BattleLandscape
extends Node3D

## A bounded, metre-scale window onto the map's own ground query. No tactical
## modifiers or discoveries are created by presentation.
const GRID := 49
const SPAN := 320.0
var context:Dictionary={}
var heights:=PackedFloat32Array()
var reference_height:=0.0
var ground:MeshInstance3D
var live_height:Callable

static func encounter_position(engagement:Dictionary)->Vector2:
	var threat:Dictionary=engagement.get("threat",{})
	var target:Dictionary=threat.get("target_position",{})
	if target.has("x") and target.has("z"): return Vector2(target.x,target.z)
	var region_id:=String(threat.get("target_region_id",""))
	if not region_id.is_empty():
		for destination:Dictionary in CivilizationSystem.military_movement_destinations():
			if String(destination.id)==region_id:
				var p:Dictionary=destination.position
				return Vector2(float(p.x),float(p.z))
	var army_id:=int(engagement.get("home_force_id",0))
	if army_id>0:
		for army:Dictionary in MilitaryCampaign.field_armies_snapshot().get("armies",[]):
			if int(army.get("army_id",0))==army_id:
				var p:Variant=army.get("position",{})
				if p is Vector3: return Vector2(p.x,p.z)
				if p is Dictionary and p.has("x"): return Vector2(p.x,p.get("z",0))
	return Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)

func build(center:Vector2,query:Callable=Callable())->void:
	for child in get_children(): child.free()
	var source:Object=query.get_object() if query.is_valid() else null
	var exact:=is_instance_valid(source) and source.has_method("_height_at")
	var sample:Dictionary=query.call(center) if query.is_valid() else PlanetEnvironment.profile_at(center)
	reference_height=float(source.call("_height_at",center.x,center.y)) if exact else PlanetEnvironment.world_height_at(center)
	context={"center":center,"label":String(sample.get("label",sample.get("biome","landscape"))),"source":"map ground" if exact else "regional terrain estimate","woodland":float(sample.get("woodland",0)),"exact":exact}
	heights.resize(GRID*GRID)
	var vertices:=PackedVector3Array(); var colors:=PackedColorArray(); var indices:=PackedInt32Array()
	for z in GRID:
		for x in GRID:
			var local:=Vector2(float(x)/(GRID-1)-.5,float(z)/(GRID-1)-.5)*SPAN
			var world:=center+local*.001
			var h:=float(source.call("_height_at",world.x,world.y)) if exact else PlanetEnvironment.world_height_at(world)
			var y:float=(h-reference_height)*1000.0
			heights[z*GRID+x]=y
			vertices.append(Vector3(local.x,y,local.y))
			var color:=Color("859d51")
			if exact:
				var biome:Dictionary=source.call("_biome_at",world.x,world.y,h)
				color=biome.get("color",color)
			else:
				var id:=String(sample.get("biome",""))
				if id in ["desert","dryland","steppe"]: color=Color("b7a375")
				elif id in ["tundra","upland"]: color=Color("899080")
			colors.append(color)
	for z in GRID-1:
		for x in GRID-1:
			var a:=z*GRID+x
			indices.append_array(PackedInt32Array([a,a+1,a+GRID,a+1,a+GRID+1,a+GRID]))
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		st.set_color(colors[index]); st.add_vertex(vertices[index])
	st.generate_normals()
	ground=MeshInstance3D.new(); ground.mesh=st.commit(); add_child(ground)
	var material:=ShaderMaterial.new(); material.shader=preload("res://scripts/battle_ground.gdshader")
	material.set_shader_parameter("ground_texture",preload("res://assets/terrain/temperate_ground_albedo_v1.png"))
	ground.material_override=material
	# Trees and stones are bounded habitat representatives, not invented cover.
	var rng:=RandomNumberGenerator.new(); rng.seed=GameState.world_seed^int(center.x*1000)^int(center.y*7919)
	var tree_mesh:=SphereMesh.new(); tree_mesh.radius=2.8; tree_mesh.height=5; tree_mesh.radial_segments=10; tree_mesh.rings=5
	var rock_mesh:=SphereMesh.new(); rock_mesh.radius=1; rock_mesh.height=1.4; rock_mesh.radial_segments=7; rock_mesh.rings=3
	var trees:Array[Transform3D]=[]; var trunks:Array[Transform3D]=[]; var rocks:Array[Transform3D]=[]
	for i in 220:
		var p:=Vector2(rng.randf_range(-145,145),rng.randf_range(-145,145))
		if absf(p.x)<36 and absf(p.y)<48: continue
		var world:=center+p*.001
		var biome:Dictionary=source.call("_biome_at",world.x,world.y) if exact else sample
		if String(biome.get("id",biome.get("biome","")))=="water": continue
		var scale:=rng.randf_range(.7,1.6)
		if rng.randf()<float(biome.get("woodland",0)):
			trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale),Vector3(p.x,height_at(p)+2*scale,p.y)))
			for crown in 3:
				var shift:=Vector2(sin(crown*2.4),cos(crown*2.4))*scale
				trees.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(1,.85,1)*scale),Vector3(p.x+shift.x,height_at(p)+(4.4+crown*.45)*scale,p.y+shift.y)))
		elif rng.randf()<float(biome.get("stone",.12))*.45:
			rocks.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(1.6,.8,1.1)*scale),Vector3(p.x,height_at(p)+.4*scale,p.y)))
	var trunk_mesh:=CylinderMesh.new(); trunk_mesh.top_radius=.16; trunk_mesh.bottom_radius=.32; trunk_mesh.height=4; trunk_mesh.radial_segments=7
	_pool(trunk_mesh,trunks,Color("70533a"))
	_pool(tree_mesh,trees,Color("46633a")); _pool(rock_mesh,rocks,Color("84857a"))
	if exact and source is Node:
		_copy_water(source,center)
	if reference_height<0:
		var plane:=PlaneMesh.new(); plane.size=Vector2(SPAN,SPAN)
		var water:=MeshInstance3D.new(); water.mesh=plane; water.position.y=-reference_height*1000
		_water_material(water); add_child(water)

func height_at(point:Vector2)->float:
	if live_height.is_valid():return float(live_height.call(point))
	if heights.is_empty(): return 0.0
	var grid:Vector2=(point/SPAN+Vector2(.5,.5))*(GRID-1)
	grid=grid.clamp(Vector2.ZERO,Vector2.ONE*(GRID-1.001))
	var x:=int(grid.x); var z:=int(grid.y); var u:=grid.x-x; var v:=grid.y-z
	var a:=heights[z*GRID+x]; var b:=heights[z*GRID+x+1]; var c:=heights[(z+1)*GRID+x]; var d:=heights[(z+1)*GRID+x+1]
	return a+(b-a)*u+(c-a)*v if u+v<=1 else d+(c-d)*(1-u)+(b-d)*(1-v)

func _pool(mesh:Mesh,poses:Array[Transform3D],color:Color)->void:
	if poses.is_empty(): return
	var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=mesh; mm.instance_count=poses.size()
	for i in poses.size(): mm.set_instance_transform(i,poses[i])
	var node:=MultiMeshInstance3D.new(); node.multimesh=mm
	var mat:=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=.95; node.material_override=mat; add_child(node)

func _water_material(node:MeshInstance3D)->void:
	var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("397e8a"); mat.roughness=.24; mat.metallic=.18
	node.material_override=mat

func _clip_water(polygon:Array[Vector2],axis:int,bound:float,sign:float)->Array[Vector2]:
	var result:Array[Vector2]=[]
	if polygon.is_empty(): return result
	var previous:Vector2=polygon[-1]
	for current in polygon:
		var a:float=(previous[axis]-bound)*sign
		var b:float=(current[axis]-bound)*sign
		if (a<=0)!=(b<=0): result.append(previous.lerp(current,a/(a-b)))
		if b<=0: result.append(current)
		previous=current
	return result

func _copy_water(source:Node,center:Vector2)->void:
	# Clip the actual map river footprint to each battle ground triangle. Heights
	# come from the battle mesh, not the map's pre-shader ribbon vertices.
	var river:=source.get_node_or_null("RiverWater") as MeshInstance3D
	if river==null or river.mesh==null: return
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); var count:=0
	var cell:=SPAN/float(GRID-1)
	for surface in river.mesh.get_surface_count():
		var arrays:=river.mesh.surface_get_arrays(surface)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var ids:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if ids.is_empty():
			for i in points.size(): ids.append(i)
		for i in range(0,ids.size(),3):
			var polygon:Array[Vector2]=[]
			var low:=Vector2(INF,INF); var high:=Vector2(-INF,-INF)
			for j in 3:
				var p:=river.to_global(points[ids[i+j]])
				var local:=(Vector2(p.x,p.z)-center)*1000
				polygon.append(local); low=low.min(local); high=high.max(local)
			if low.x>SPAN*.5 or low.y>SPAN*.5 or high.x<-SPAN*.5 or high.y<-SPAN*.5: continue
			var begin:Vector2i=Vector2i(((low+Vector2.ONE*SPAN*.5)/cell).floor().clamp(Vector2.ZERO,Vector2.ONE*(GRID-2)))
			var end:Vector2i=Vector2i(((high+Vector2.ONE*SPAN*.5)/cell).floor().clamp(Vector2.ZERO,Vector2.ONE*(GRID-2)))
			for z in range(begin.y,end.y+1):
				for x in range(begin.x,end.x+1):
					var part:=polygon.duplicate()
					part=_clip_water(part,0,x*cell-SPAN*.5,-1)
					part=_clip_water(part,0,(x+1)*cell-SPAN*.5,1)
					part=_clip_water(part,1,z*cell-SPAN*.5,-1)
					part=_clip_water(part,1,(z+1)*cell-SPAN*.5,1)
					for j in range(1,part.size()-1):
						for p in [part[0],part[j],part[j+1]]: st.add_vertex(Vector3(p.x,height_at(p)+.08,p.y))
						count+=1
	if count>0:
		st.generate_normals(); var water:=MeshInstance3D.new(); water.mesh=st.commit(); _water_material(water); add_child(water)
	context["river_triangles"]=count
