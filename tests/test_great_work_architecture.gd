extends GdUnitTestSuite
const Architecture:=preload("res://scripts/hud/great_work_architecture.gd")
const Design:=preload("res://scripts/hud/great_work_design.gd")
const Model:=preload("res://scripts/hud/great_work_model.gd")
const Concept:=preload("res://scripts/wonder_concept.gd")
const Catalog:=preload("res://scripts/undertaking_catalog.gd")

func work(form:String="bridge",tier:int=2,ambition:String="grand",purpose:String="welcome_strangers",material:String="stone",token:String="architecture")->Dictionary:
	return {"work_id":Concept.make_id(form,purpose,ambition,material,tier,token),"status":"functioning","progress":1.0,"condition":1.0}

func test_all_thirty_designs_have_distinct_authored_geometry_without_fallbacks()->void:
	var signatures:={}
	var records:Array=[]
	for form:String in Concept.FORMS:records.append(work(form))
	for definition:Dictionary in Catalog.all():records.append({"work_id":definition.id,"progress":1.0,"status":"functioning"})
	for record:Dictionary in records:
		var description:=Model.describe(record)
		var pieces:=Architecture.pieces(description.design)
		assert_str(description.design_id).is_not_empty()
		assert_int(pieces.size()).is_greater(12)
		assert_int(pieces.size()).is_less(700)
		var key:=str(hash(pieces))
		assert_bool(signatures.has(key)).is_false()
		signatures[key]=description.design_id
		var built:=Model.build(record)
		assert_str(built.design_id).is_equal(description.design_id)
		assert_str((built.root as Node3D).get_meta("design_id")).is_equal(description.design_id)
		(built.root as Node3D).free()
	assert_int(signatures.size()).is_equal(30)
	assert_array(Architecture.pieces({"form":"unknown","design_id":"form:unknown"})).is_empty()

func test_arch_is_a_real_opening_and_partial_courses_clip_its_triangles()->void:
	var piece:={"position":Vector3.ZERO,"size":Vector3(20,10,4),"kind":"arch","color":Color.WHITE}
	for height:float in [3.0,7.0,10.0]:
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		Architecture.append_piece(surface,piece,height)
		var mesh:=surface.commit();var vertices:PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		assert_int(vertices.size()).is_greater(0)
		for vertex:Vector3 in vertices:assert_float(vertex.y).is_less_equal(height+.00001)
		for i in range(0,vertices.size(),3):
			var polygon:=PackedVector2Array([Vector2(vertices[i].x,vertices[i].y),Vector2(vertices[i+1].x,vertices[i+1].y),Vector2(vertices[i+2].x,vertices[i+2].y)])
			assert_bool(Geometry2D.is_point_in_polygon(Vector2(0,2),polygon)).is_false()

func test_all_supported_material_tier_and_ambition_combinations_stay_bounded(_timeout:=300000)->void:
	var largest:=0
	for form:String in Concept.FORMS:
		for material:String in Concept.FORMS[form].materials:
			for tier in 6:
				for ambition:String in Concept.AMBITIONS:
					var record:=work(form,tier,ambition,"honor_dead",material)
					var before:=var_to_str(record)
					var built:=Model.build(record,{"ground":true})
					var root:Node3D=built.root
					var vertices:=0
					for child:MeshInstance3D in root.get_children():vertices+=(child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
					largest=maxi(largest,vertices)
					assert_int(vertices).is_less(50000)
					assert_int(root.get_child_count()).is_less_equal(7)
					assert_bool((built.bounds as AABB).size.is_finite()).is_true()
					assert_float(built.bounds.size.length()).is_less(230.0)
					assert_str(var_to_str(record)).is_equal(before)
					root.free()
	print("ARCHITECTURE_MAX_VERTICES=",largest)

func test_unknown_record_stays_an_empty_safe_site_not_a_catalog_hall()->void:
	var built:=Model.build({}, {"ground":true,"plan":true})
	assert_bool(built.description.valid).is_false()
	assert_str(built.design_id).is_empty()
	assert_bool((built.bounds as AABB).size.is_finite()).is_true()
	assert_int((built.root as Node3D).get_child_count()).is_equal(2)
	(built.root as Node3D).free()

func test_recorded_tier_purpose_material_ambition_and_token_are_visible_and_stable()->void:
	var base:=work("archive",0)
	var reference:=Architecture.pieces(Design.describe(base))
	assert_array(Architecture.pieces(Design.describe(base))).is_equal(reference)
	for changed:Dictionary in [work("archive",3),work("archive",0,"audacious"),work("archive",0,"grand","honor_dead"),work("archive",0,"grand","welcome_strangers","brick"),work("archive",0,"grand","welcome_strangers","stone","other")]:
		assert_str(str(hash(Architecture.pieces(Design.describe(changed))))).is_not_equal(str(hash(reference)))
	var early:=Architecture.pieces(Design.describe(work("observatory",0)))
	var late:=Architecture.pieces(Design.describe(work("observatory",5)))
	assert_bool(early.any(func(piece:Dictionary)->bool:return piece.kind=="dome")).is_false()
	assert_bool(late.any(func(piece:Dictionary)->bool:return piece.kind=="dome")).is_true()

func test_zero_progress_and_every_partial_course_stay_below_recorded_plane()->void:
	for form:String in ["bridge","archive","colossus","garden","observatory"]:
		for fraction:float in [0.0,.3,.7]:
			var record:=work(form);record.status="building";record.progress=fraction
			var built:=Model.build(record,{"plan":true})
			var root:Node3D=built.root
			var vertices:PackedVector3Array=(root.get_node("Masonry") as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var pieces:=Architecture.pieces(built.description.design)
			var top:=Architecture.extent(pieces).end.y*float(built.course)/Model.COURSES+.0012 if fraction>0 else 0.0
			for point:Vector3 in vertices:assert_float(point.y).is_less_equal(top+.000001)
			assert_float(built.progress).is_equal(fraction)
			root.free()

func test_purpose_ornament_covers_all_twelve_purposes_without_claiming_production()->void:
	var signatures:={}
	for purpose:String in Concept.PURPOSES:
		var design:=Design.describe(work("hall",1,"grand",purpose,"timber"))
		var geometry:=Architecture.pieces(design)
		signatures[hash(geometry)]=purpose
	assert_int(signatures.size()).is_equal(12)
	var kilns:=Architecture.pieces(Design.describe({"id":"kiln_court"}))
	assert_bool(kilns.any(func(piece:Dictionary)->bool:return piece.get("emission",false))).is_false()

func test_colossus_shoulders_start_inside_the_actual_tapered_torso()->void:
	for ambition:String in Concept.AMBITIONS:
		var parts:=Architecture.pieces(Design.describe(work("colossus",2,ambition)))
		var torso:Dictionary=parts.filter(func(piece:Dictionary)->bool:return piece.get("feature","")=="torso")[0]
		for arm:Dictionary in parts.filter(func(piece:Dictionary)->bool:return piece.get("feature","") in ["left_arm","right_arm"]):
			var local:Vector3=arm.position-torso.position
			var taper:=lerpf(1.0,.68,local.y/torso.size.y)
			var section:=PackedVector2Array()
			for i in 12:section.append(Vector2(cos(TAU*i/12)*torso.size.x*.5*taper,sin(TAU*i/12)*torso.size.z*.5*taper))
			assert_bool(Geometry2D.is_point_in_polygon(Vector2(local.x,local.z),section)).is_true()

func test_canal_water_waits_for_standing_and_is_absent_from_ruins()->void:
	for status:String in ["building","stalled","ruined","abandoned","functioning"]:
		var record:=work("canal");record.status=status
		if status in ["building","stalled"]:record.progress=.7
		var built:=Model.build(record)
		var root:Node3D=built.root
		var colors:PackedColorArray=(root.get_node("Masonry") as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		var water:=false
		for color:Color in colors:
			if color.is_equal_approx(Color("697d7a")):water=true;break
		assert_bool(water).is_equal(status=="functioning")
		root.free()

func test_cone_roofs_have_real_peaks_and_outward_sloping_faces()->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	Architecture.append_piece(surface,{"position":Vector3.ZERO,"size":Vector3(13,3,11),"kind":"cone","color":Color.WHITE})
	var arrays:=surface.commit().surface_get_arrays(0)
	var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var apex:=false;var upward_faces:=0
	for i in points.size():
		if points[i].is_equal_approx(Vector3(0,3,0)):apex=true
		if normals[i].y>0.1 and Vector2(normals[i].x,normals[i].z).length()>.1:upward_faces+=1
	assert_bool(apex).is_true()
	assert_int(upward_faces).is_greater_equal(36)
