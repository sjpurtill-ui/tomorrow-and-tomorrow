extends GdUnitTestSuite
const Rituals=preload("res://scripts/hud/great_work_rituals.gd")
const Design=preload("res://scripts/hud/great_work_design.gd")
const Concept=preload("res://scripts/wonder_concept.gd")
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const Stage=preload("res://scripts/hud/great_work_ceremony_stage.gd")
const EARLY={"period":"early","outfit":"hide"}

func records()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for form:String in Concept.FORMS:
		var id:=Concept.make_id(form,"give_thanks","grand",String(Concept.FORMS[form].materials[0]),0,"ritualtest")
		result.append({"work_id":id,"status":"functioning","fraction":1.0,"condition":1.0})
	for definition:Dictionary in Catalog.all():result.append({"id":definition.id,"status":"functioning","fraction":1.0,"condition":1.0})
	return result

func _geometry(root:Node)->String:
	var parts:Array=[]
	for child:Node in root.get_children():
		if child is Node3D:parts.append((child as Node3D).transform)
		if child is MeshInstance3D:
			var mesh:MeshInstance3D=child
			parts.append([mesh.mesh.get_class(),mesh.mesh.get_aabb(),(mesh.material_override as StandardMaterial3D).albedo_color])
		parts.append(_geometry(child))
	return var_to_str(parts)

func test_all_thirty_have_distinct_named_rituals_and_real_distinct_props()->void:
	assert_dict(Rituals.describe({"id":"missing_fixture_record"},[],EARLY)).is_empty()
	var ritual_ids:={};var prop_ids:={};var geometry:={};var designs:={}
	for record:Dictionary in records():
		var before:=var_to_str(record)
		var profile:=Rituals.describe(record,[],EARLY)
		assert_bool(profile.is_empty()).is_false()
		assert_bool(profile.symbolic).is_true()
		assert_bool(ritual_ids.has(profile.ritual_id)).is_false()
		assert_bool(prop_ids.has(profile.prop)).is_false()
		ritual_ids[profile.ritual_id]=true;prop_ids[profile.prop]=true;designs[profile.design_id]=true
		var built:=Rituals.build(profile)
		var root:Node3D=built.root
		var signature:=_geometry(root)
		assert_bool(geometry.has(signature)).is_false()
		geometry[signature]=true
		var meshes:=root.find_children("*","MeshInstance3D",true,false)
		assert_int(meshes.size()).is_greater(3)
		assert_int(meshes.size()).is_less(100)
		assert_array(built.motions).is_not_empty()
		assert_bool((built.after as Node3D).visible).is_false()
		for mesh:MeshInstance3D in meshes:assert_bool(mesh.mesh.get_aabb().size.is_finite()).is_true()
		assert_str(var_to_str(record)).is_equal(before)
		root.free()
	assert_int(designs.size()).is_equal(30)
	assert_int(geometry.size()).is_equal(30)
	assert_array(designs.keys()).contains_exactly(Design.catalog_ids())

func test_all_twelve_purposes_have_physical_emblems_and_different_context()->void:
	var shapes:={};var captions:={}
	for purpose:String in Concept.PURPOSES:
		var id:=Concept.make_id("tower",purpose,"grand","stone",1,"purpose_test")
		var profile:=Rituals.describe({"work_id":id},[],EARLY)
		var built:=Rituals.build(profile)
		var root:Node3D=built.root
		shapes[_geometry(root.get_node("Purpose_"+String(profile.purpose_emblem)))]=true
		captions[profile.purpose_caption]=true
		if purpose=="defy_gods":
			assert_str(profile.gesture).is_equal("raise_hand")
			assert_str(profile.purpose_caption).contains("defying")
		if purpose=="honor_dead":assert_str(profile.gesture).is_equal("bow_shallow")
		root.free()
	assert_int(shapes.size()).is_equal(12)
	assert_int(captions.size()).is_equal(12)

func test_all_profiles_keep_their_identity_across_the_four_era_protocols()->void:
	var eras:Array=[EARLY,{"period":"medieval","outfit":"medieval"},{"period":"industrial","outfit":"formal"},{"period":"modern","outfit":"business"}]
	for record:Dictionary in records():
		var key:=""
		for index in eras.size():
			var profile:=Rituals.describe(record,["solid_state_lighting"] if index==3 else [],eras[index])
			assert_str(profile.mode).is_equal(["offering","unveiling","ribbon","illumination"][index])
			if key.is_empty():key=profile.ritual_id
			assert_str(profile.ritual_id).is_equal(key)
			var voice:=Rituals.voice_facts(profile)
			assert_bool(voice.dedicated).is_false()
			assert_str(voice.scene).is_equal(profile.before)
			assert_bool(Rituals.voice_facts(profile,true).dedicated).is_true()

func test_every_ritual_moves_only_after_dedication_and_retains_its_scene()->void:
	for record:Dictionary in records():
		var scene:Control=Stage.make(record,{"key":"coverage","architect":{},"official":{"person_id":23,"name":"Recorded keeper","age":40,"sex":"male"},"attendees":[]})
		scene.size=Vector2(760,360);add_child(scene)
		await get_tree().process_frame
		scene.settle()
		var before:Dictionary=scene.diagnostics()
		assert_bool(before.committed).is_false()
		assert_int(before.ritual_mesh_count).is_greater(3)
		assert_bool(scene._specific.after.visible).is_false()
		var initial:=_geometry(scene._specific.root)
		scene.dedication();scene.settle()
		assert_bool(scene.diagnostics().committed).is_true()
		assert_str(_geometry(scene._specific.root)).is_not_equal(initial)
		assert_int(scene.diagnostics().model_node_id).is_equal(before.model_node_id)
		assert_int(scene.diagnostics().ritual_node_id).is_equal(before.ritual_node_id)
		var committed:=_geometry(scene._specific.root)
		scene.dedication();scene.settle()
		assert_str(_geometry(scene._specific.root)).is_equal(committed)
		assert_bool(scene.diagnostics().viewport_active).is_false()
		scene.show_work();scene.settle()
		assert_str(scene._whole_button.text).is_equal("Return to the assembly")
		scene._whole_button.pressed.emit();scene.settle()
		assert_str(scene.diagnostics().camera_shot).is_equal("gathering")
		assert_str(scene._whole_button.text).is_equal("See the whole work")
		scene.queue_free();await get_tree().process_frame

func test_crossing_uses_an_actual_bounded_figure_and_finishes_its_walk()->void:
	for form:String in ["gate","bridge"]:
		var id:=Concept.make_id(form,"welcome_strangers","grand","stone",1,"crossing")
		var scene:Control=Stage.make({"work_id":id,"status":"functioning","fraction":1.0},{"key":"crossing","architect":{},"official":{"person_id":23,"name":"Recorded keeper","age":40,"sex":"male"},"attendees":[]})
		scene.size=Vector2(760,360);add_child(scene)
		await get_tree().process_frame
		var body:Node3D=scene.bodies.official
		var origin:=body.position
		scene.dedication();scene.settle()
		assert_float(body.position.distance_to(origin)).is_greater(3.0)
		assert_int(scene.diagnostics().body_count).is_equal(1)
		assert_str(String(body.clip)).is_equal("stand")
		scene.queue_free();await get_tree().process_frame
