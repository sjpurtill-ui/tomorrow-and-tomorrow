extends GdUnitTestSuite
const Model:=preload("res://scripts/hud/great_work_model.gd")
const Concept:=preload("res://scripts/wonder_concept.gd")
const Catalog:=preload("res://scripts/undertaking_catalog.gd")

func record(form:String="tower",fraction:float=.5,status:String="building",material:String="stone",tier:int=1)->Dictionary:
	var id:=Concept.make_id(form,"honor_dead","grand",material,tier,"modeltest")
	return {"id":id,"progress":float(Catalog.get_definition(id).work)*fraction,"status":status,"condition":1.0,"last_work":10.0}

func test_raw_records_and_fraction_summaries_have_identical_geometry_keys()->void:
	var raw:=record();var summary:={"work_id":raw.id,"progress":.5,"status":"building","condition":1.0,"last_work":10.0}
	assert_str(Model.signature(raw)).is_equal(Model.signature(summary))
	var site:=raw.duplicate();site.fraction=.5;site.total_work=Catalog.get_definition(raw.id).work
	assert_str(Model.signature(site)).is_equal(Model.signature(raw))
	# Atlas merges the summary over the site: fraction still disambiguates it.
	site.progress=.5
	assert_float(Model.describe(site).progress).is_equal(.5)

func test_zero_site_has_clearing_but_no_invented_first_courses()->void:
	var built:=Model.build(record("tower",0.0),{"plan":true,"scaffolds":true})
	var root:Node3D=auto_free(built.root)
	assert_int(built.course).is_equal(0)
	var mesh:=root.get_node("Masonry") as MeshInstance3D
	assert_float(mesh.mesh.get_aabb().end.y).is_less_equal(0.0)
	assert_object(root.get_node_or_null("Scaffolding")).is_null()
	assert_object(root.get_node_or_null("UnbuiltPlan")).is_not_null()

func test_incomplete_record_never_becomes_complete_from_status_alone()->void:
	var d:=Model.describe(record("hall",.4,"functioning"))
	assert_str(d.state).is_equal("building")
	assert_float(d.progress).is_equal_approx(.4,.000001)
	assert_int(d.course).is_equal(16)

func test_every_conceived_and_legacy_form_builds_finite_bounded_geometry()->void:
	var records:Array=[]
	for form:String in Concept.FORMS:records.append(record(form))
	for definition:Dictionary in Catalog.all():records.append({"id":definition.id,"status":"functioning","progress":definition.work,"condition":1.0})
	for r:Dictionary in records:
		for status:String in ["building","functioning","ruined","abandoned"]:
			r.status=status
			var built:=Model.build(r,{"plan":true,"ground":true,"workers":true})
			var root:Node3D=built.root
			assert_bool((built.bounds as AABB).position.is_finite()).is_true()
			assert_bool((built.bounds as AABB).size.is_finite()).is_true()
			assert_int(root.get_child_count()).is_less_equal(7)
			var vertices:=0
			for node:MeshInstance3D in root.get_children():
				assert_object(node.mesh).is_not_null()
				var arrays:=node.mesh.surface_get_arrays(0)
				for point:Vector3 in arrays[Mesh.ARRAY_VERTEX]:assert_bool(point.is_finite()).is_true()
				vertices+=(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			assert_int(vertices).is_less(50000)
			root.free()

func test_courses_only_change_key_after_actual_progress_crosses_boundary()->void:
	assert_str(Model.signature(record("tower",.501))).is_equal(Model.signature(record("tower",.524)))
	assert_str(Model.signature(record("tower",.524))).is_not_equal(Model.signature(record("tower",.526)))
	var progress:float=Model.describe(record("tower",.524)).progress
	assert_float(progress).is_equal_approx(.524,.000001)

func test_stalled_sites_have_no_working_representatives_and_cast_is_bounded()->void:
	var working:=Model.build(record(),{"workers":true})
	var idle:=Model.build(record("tower",.5,"stalled"),{"workers":true})
	assert_int(working.worker_count).is_equal(Model.MAX_WORKERS)
	assert_int(idle.worker_count).is_equal(0)
	assert_object((idle.root as Node3D).get_node_or_null("Builders")).is_null()
	(working.root as Node3D).free();(idle.root as Node3D).free()

func test_presentation_never_mutates_record_or_requires_current_technology()->void:
	for spec:Array in [["ring","stone",0],["hall","brick",2],["tower","iron",4],["dam","concrete",5]]:
		var r:=record(spec[0],1.0,"functioning",spec[1],spec[2]);r.concept={"lore":"Kept history"};r.events=[{"kind":"test"}]
		var before:=var_to_str(r)
		var built:=Model.build(r)
		assert_str(built.description.material).is_equal(spec[1])
		assert_int(built.description.tier).is_equal(spec[2])
		assert_str(var_to_str(r)).is_equal(before)
		(built.root as Node3D).free()

func test_concepts_are_plans_with_no_completed_geometry()->void:
	var concept:=record();concept.erase("status");concept.erase("progress");concept.erase("last_work")
	var d:=Model.describe(concept)
	assert_str(d.state).is_equal("plan")
	assert_float(d.progress).is_equal(0.0)
	var built:=Model.build(concept,{"plan":true})
	assert_object((built.root as Node3D).get_node_or_null("UnbuiltPlan")).is_not_null()
	(built.root as Node3D).free()

func test_completed_work_has_no_unbuilt_plan_or_scaffolding()->void:
	var built:=Model.build(record("tower",1,"functioning"),{"plan":true,"scaffolds":true,"workers":true})
	var root:Node3D=auto_free(built.root)
	assert_object(root.get_node_or_null("UnbuiltPlan")).is_null()
	assert_object(root.get_node_or_null("Scaffolding")).is_null()
	assert_int(built.worker_count).is_equal(0)
	assert_float(built.bounds.size.y).is_greater(30.0)
