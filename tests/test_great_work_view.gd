extends GdUnitTestSuite
const View:=preload("res://scripts/hud/great_work_view.gd")
const Concept:=preload("res://scripts/wonder_concept.gd")

func work(fraction:float=.5)->Dictionary:
	return {"work_id":Concept.make_id("tower","honor_dead","grand","stone",1,"viewtest"),"status":"building","progress":fraction,"condition":1.0,"last_work":10.0}

func view()->Control:
	var node:Control=auto_free(View.make(work(),320));add_child(node);node.size=Vector2(650,340)
	return node

func test_same_course_keeps_geometry_while_actual_progress_reading_updates()->void:
	var node:=view();var id:int=node.model_root.get_instance_id()
	node.configure(work(.524))
	assert_int(node.model_root.get_instance_id()).is_equal(id)
	assert_int(node.model_rebuilds).is_equal(1)
	assert_float(node.report().progress).is_equal(.524)
	node.configure(work(.526))
	assert_int(node.model_rebuilds).is_equal(2)
	assert_int(node.model_root.get_instance_id()).is_not_equal(id)
	await await_idle_frame()

func test_orbit_zoom_and_plan_keep_mesh_and_do_not_change_progress()->void:
	var node:=view();var id:int=node.model_root.get_instance_id()
	node.orbit_by(Vector2(80,25));node.zoom_by(2);node.set_plan_visible(true);node.set_scaffolds_visible(false)
	assert_int(node.model_root.get_instance_id()).is_equal(id)
	assert_int(node.model_rebuilds).is_equal(1)
	assert_float(node.report().progress).is_equal(.5)
	assert_bool(node.model_root.get_node("UnbuiltPlan").visible).is_true()
	assert_bool(node.model_root.get_node("Scaffolding").visible).is_false()
	assert_float(node.zoom).is_less(1.0)
	node.reset_view()
	assert_float(node.yaw).is_equal(View.DEFAULT_YAW)
	assert_float(node.pitch).is_equal(View.DEFAULT_PITCH)
	assert_float(node.zoom).is_equal(1.0)

func test_camera_stays_finite_and_bounded_at_extreme_inputs_and_narrow_size()->void:
	var node:=view();node.size=Vector2(240,320)
	node.orbit_by(Vector2(1e6,-1e6));node.zoom_by(1e6)
	assert_float(node.pitch).is_between(.15,1.3)
	assert_float(node.zoom).is_between(.38,2.4)
	assert_bool(node.camera.position.is_finite()).is_true()
	node.zoom_by(-1e6)
	assert_float(node.zoom).is_between(.38,2.4)
	assert_float(node.camera.size).is_greater(0.0)

func test_idle_and_hidden_views_have_no_continuous_render_process()->void:
	var node:=view()
	await await_idle_frame();await await_idle_frame()
	var before:=int(node.report().viewport_updates)
	for i in 4:await await_idle_frame()
	assert_int(node.report().viewport_updates).is_equal(before)
	assert_bool(node.is_processing()).is_false()
	node.hide();node.orbit_by(Vector2(30,20));node.configure(work(.75))
	await await_idle_frame()
	assert_int(node.report().viewport_updates).is_equal(before)
	assert_int(node.viewport.render_target_update_mode).is_equal(SubViewport.UPDATE_DISABLED)
	node.show();await await_idle_frame();await await_idle_frame()
	assert_int(node.report().viewport_updates).is_greater(before)

func test_stalling_removes_workers_without_claiming_new_construction()->void:
	var node:=view();var stalled:=work();stalled.status="stalled";stalled.idle="No stone in store"
	node.configure(stalled)
	assert_int(node.report().worker_count).is_equal(0)
	assert_float(node.report().progress).is_equal(.5)
	assert_str(node._reading.text).contains("No stone in store")
