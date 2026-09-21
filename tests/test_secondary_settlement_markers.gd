extends GdUnitTestSuite

const RENDERER:=preload("res://scripts/local_terrain.gd")
const VALUES:=preload("res://scripts/societal_values_model.gd")

# Give root-dependent helpers a tree without running the terrain startup flow.
class IsolatedRenderer extends RENDERER:
	func _ready()->void:pass

var renderer:Node3D


func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(741991)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	renderer=auto_free(IsolatedRenderer.new())
	renderer.set_process(false);add_child(renderer)


func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)


func test_secondary_city_dots_retire_at_close_zoom_and_return_without_rebuild()->void:
	renderer.camera=Camera3D.new()
	renderer.add_child(renderer.camera)
	renderer.settlement_network_marker_root=Node3D.new()
	renderer.add_child(renderer.settlement_network_marker_root)
	var blips:=MultiMeshInstance3D.new()
	blips.name="SecondarySettlementBlips"
	blips.multimesh=MultiMesh.new()
	blips.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	blips.multimesh.mesh=CylinderMesh.new()
	blips.multimesh.instance_count=2
	blips.set_meta("marker_profiles",[{"stage":0,"marker_scale":1.0},{"stage":6,"marker_scale":2.0}])
	var anchor:=Vector3(12,0.1,9)
	for index in 2:blips.multimesh.set_instance_transform(index,Transform3D(Basis(),anchor))
	renderer.settlement_network_marker_root.add_child(blips)
	var label:=Label3D.new()
	renderer.settlement_network_marker_root.add_child(label)
	renderer.camera.size=3.0
	renderer._update_secondary_settlement_blips()
	assert_bool(blips.visible).is_false()
	assert_bool(label.visible).is_true()
	renderer.camera.size=60.0
	renderer._update_secondary_settlement_blips()
	assert_bool(blips.visible).is_true()
	renderer.camera.size=3.0
	renderer._update_secondary_settlement_blips()
	assert_bool(blips.visible).is_false()
