extends GdUnitTestSuite
## WHAT THE COURT'S EXECUTIONS MAKE OF A PERSON (scripts/hud/court_figure_gore.gd).
## The engine decides who dies; this makes the body, out of the person's own
## figure (their skin, hair, clothes and face):
## - it comes apart at the blow: the head, the limbs, all, or sawn in half,
##   each piece at its own middle with red stumps and a bone end, red inside;
##   a loose head (and each half) still blinks;
## - a clean skeleton, charred and crumbling, pressed flat and rolled, bronze;
## - a child never comes apart, burns, flattens or turns to bronze.
## Presentation only. Offline.

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Gore:=preload("res://scripts/hud/court_figure_gore.gd")
const Merge:=preload("res://scripts/hud/court_figure_merge.gd")

var _holder:Node3D

func before_test()->void:
	_holder=auto_free(Node3D.new())
	add_child(_holder)

func _adult()->Node3D:
	var fig:=Figure3D.new()
	_holder.add_child(fig)
	fig.setup({"variant":"male_adult","outfit":"tunic","hair":"long","beard":"beard_short","stance":"stand","lit":true,"keep_stance":true,
		"skin":Color("9f6a43"),"hair_colour":Color("2b2018"),"cloth":[Color("a8432f"),Color("6e5541"),Color("c9a43c")],"face":{"jaw":0.3},"years":34})
	fig.play("stand",0.0,0.3)
	return fig

func _ok()->bool:
	if not Figure3D.available():
		push_warning("figures not imported; gore tests skipped")
		return false
	return true

func _meshes(node:Node)->Array:
	return node.find_children("*","MeshInstance3D",true,false)

## A shader parameter as a number (one never set reads as 0).
func _p(mat:ShaderMaterial,name:String)->float:
	var v:Variant=mat.get_shader_parameter(name)
	return 0.0 if v==null else float(v)

func _has_morph(node:Node,name:String)->bool:
	for mi in _meshes(node):
		if (mi as MeshInstance3D).mesh!=null and (mi as MeshInstance3D).find_blend_shape_by_name(StringName(name))>=0:return true
	return false


func test_a_head_comes_off_with_stumps_and_still_blinks()->void:
	if not _ok():return
	var fig:=_adult()
	fig.gore_prepare()
	for i in 3:await await_idle_frame()
	var pieces:Dictionary=fig.gore_split("head")
	assert_array(pieces.keys()).contains_exactly_in_any_order(["head","torso_limbs"])
	assert_bool(fig.visible).is_false()
	var head:Node3D=pieces.head
	assert_bool(_has_morph(head,"blink")).is_true()
	assert_bool(head.has_method("blink")).is_true()
	head.call("blink",1)
	# a red stump and a bone end on both sides of the cut
	for p in [head,pieces.torso_limbs]:
		assert_object((p as Node).find_child("Stump",true,false)).is_not_null()
		assert_object((p as Node).find_child("BoneEnd",true,false)).is_not_null()
	# red inside where it is open
	var body:MeshInstance3D=(pieces.torso_limbs as Node).find_child("Body",true,false)
	assert_float(float((body.get_surface_override_material(0) as ShaderMaterial).get_shader_parameter("gore_inside"))).is_equal(1.0)
	# the head's pivot is the head, not the feet
	assert_float((head.global_position-fig.global_position).y).is_greater(1.3)


func test_it_comes_apart_limb_by_limb_or_in_halves()->void:
	if not _ok():return
	var a:=_adult()
	a.gore_prepare()
	await await_idle_frame()
	var all:Dictionary=a.gore_split("all")
	assert_array(all.keys()).contains_exactly_in_any_order(["head","torso","arm.L","arm.R","leg.L","leg.R"])
	for key in all:assert_int(_meshes(all[key]).size()).override_failure_message("nothing in "+String(key)).is_greater(1)
	var b:=_adult()
	b.gore_prepare()
	await await_idle_frame()
	var halves:Dictionary=b.gore_split("halves")
	assert_array(halves.keys()).contains_exactly_in_any_order(["left","right"])
	for key in halves:assert_bool(_has_morph(halves[key],"blink")).override_failure_message(String(key)+" cannot blink").is_true()


func test_bones_charred_flat_and_bronze()->void:
	if not _ok():return
	var fig:=_adult()
	var merged:Dictionary=fig._merged
	var bones:=Gore.bones(fig,true) as MeshInstance3D
	assert_object(bones).is_not_null()
	assert_bool(bones.visible).is_true()
	assert_bool((merged.Body as MeshInstance3D).visible).is_false()
	Gore.bones(fig,false)
	assert_bool((merged.Body as MeshInstance3D).visible).is_true()
	Gore.char(fig,true)
	var mat:ShaderMaterial=(merged.Body as MeshInstance3D).get_surface_override_material(0)
	assert_float(float(mat.get_shader_parameter("charred"))).is_equal(1.0)
	Gore.crumble(fig,0.5)
	assert_float(float(mat.get_shader_parameter("crumble"))).is_equal(0.5)
	var flat:=_adult()
	Gore.rug(flat,true)
	Gore.rug_roll(flat,0.4)
	var rug_mat:ShaderMaterial=(flat._merged.Body as MeshInstance3D).get_surface_override_material(0)
	assert_float(float(rug_mat.get_shader_parameter("rug"))).is_equal(1.0)
	assert_float(float(rug_mat.get_shader_parameter("rug_roll"))).is_equal(0.4)
	var statue:=_adult()
	await await_idle_frame()
	Gore.bronze(statue,true)
	assert_bool(statue.player.is_playing()).is_false()
	assert_bool((statue._merged.Eyes as MeshInstance3D).visible).is_false()
	assert_float(float(((statue._merged.Body as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial).get_shader_parameter("bronze"))).is_equal(1.0)
	# the living keep their own materials: nobody else is touched
	var other:=_adult()
	assert_float(_p((other._merged.Body as MeshInstance3D).get_surface_override_material(0),"charred")).is_equal(0.0)


func test_a_child_never_comes_apart()->void:
	if not _ok():return
	var child:=Figure3D.new();_holder.add_child(child)
	child.setup({"variant":"child","outfit":"hide","hair":"cropped","stance":"stand","lit":true,"years":8})
	assert_bool(child.gore_allowed()).is_false()
	assert_bool(Gore.split(child,"head").is_empty()).is_true()
	assert_object(Gore.bones(child)).is_null()
	Gore.char(child,true);Gore.rug(child,true);Gore.bronze(child,true)
	for mi in _meshes(child):
		var m:=(mi as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
		if m!=null and m.shader!=null and m.shader.code.contains("uniform float charred"):
			assert_float(_p(m,"charred")).is_equal(0.0)
			assert_float(_p(m,"rug")).is_equal(0.0)
	assert_bool(child.visible).is_true()
