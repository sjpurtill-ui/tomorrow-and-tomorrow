extends GdUnitTestSuite
## The early court deliberately omits hide_cape for some speakers. Its optional
## shoulders must not be part of the always-on hide body mask.
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Wardrobe=preload("res://scripts/hud/court_wardrobe.gd")
const Merge=preload("res://scripts/hud/court_figure_merge.gd")
var _was_merged:bool

func before_test()->void:
	_was_merged=Merge.enabled;Merge.enabled=true

func after_test()->void:Merge.enabled=_was_merged

func _figure(variant:String,lit:bool,without:Array)->Figure:
	var f:=Figure.new();add_child(f)
	f.setup({"variant":variant,"outfit":"hide","lit":lit,"without":without,"stance":"sit"})
	return f

func _part(f:Figure,name:String)->MeshInstance3D:
	for node:MeshInstance3D in f._parts:
		if String(node.name)==name:return node
	return null

func _vertices(mesh:Mesh)->int:
	var count:=0
	for surface in mesh.get_surface_count():count+=mesh.surface_get_array_len(surface)
	return count

## A sleeveless wrap cannot hide the arm-dominant shoulder band. Select that
## anatomical band from actual rig joints, not the garment generator's masks.
func _shoulders(mesh:Mesh,skin:Skin,rig:Skeleton3D,height:float)->Dictionary:
	var upper_binds:={"L":[],"R":[]};var shoulder_y:={}
	for side:String in ["L","R"]:
		shoulder_y[side]=rig.get_bone_global_rest(rig.find_bone("upper_arm."+side)).origin.y
		for bind in skin.get_bind_count():
			if String(Wardrobe._bind_name(skin,rig,bind))=="upper_arm."+side:upper_binds[side].append(bind)
	var result:={"L":0,"R":0,"masked":0,"wrap_masked":0}
	for surface in mesh.get_surface_count():
		var a:=mesh.surface_get_arrays(surface)
		for i in a[Mesh.ARRAY_VERTEX].size():
			var p:Vector3=a[Mesh.ARRAY_VERTEX][i];var color:Color=a[Mesh.ARRAY_COLOR][i]
			if color.g>.5 and p.y>height*.5 and p.y<height*.65:result.wrap_masked+=1
			for side:String in ["L","R"]:
				if p.y<float(shoulder_y[side])-.10*height or p.y>float(shoulder_y[side])+.035*height:continue
				var weight:=0.0
				for k in 4:
					if a[Mesh.ARRAY_BONES][i*4+k] in upper_binds[side]:weight+=a[Mesh.ARRAY_WEIGHTS][i*4+k]
				if weight<.5:continue
				result[side]+=1
				if color.g>.5:result.masked+=1
	return result

func test_omitted_hide_cape_keeps_both_shoulders_visible_in_parts_and_merged_body()->void:
	for variant:String in Figure.BODIES:
		for lit:bool in [false,true]:
			var f:=_figure(variant,lit,["hide_cape"])
			var body:=_part(f,"Body")
			assert_str(f._legacy_key).is_not_empty()
			assert_bool(_part(f,"hide_cape").visible).is_false()
			var drawn:MeshInstance3D=f._merged.Body if lit else body
			var counts:=_shoulders(drawn.mesh,body.skin,f.skeleton,f._base_height)
			assert_int(counts.L).override_failure_message(variant+" left shoulder fixture is empty").is_greater(5)
			assert_int(counts.R).override_failure_message(variant+" right shoulder fixture is empty").is_greater(5)
			assert_int(counts.masked).override_failure_message("%s lit=%s hides %d uncovered shoulder vertices"%[variant,lit,counts.masked]).is_equal(0)
			assert_int(counts.wrap_masked).is_greater(100)
			assert_int(drawn.get_surface_override_material(0).get_shader_parameter("cover_channel")).is_equal(1)
			f.free()

func test_optional_cape_redress_reuses_parts_and_shared_skin_without_mutating_other_figures()->void:
	for variant:String in Figure.BODIES:
		var f:=_figure(variant,true,[]);var other:=_figure(variant,true,[])
		var body:=_part(f,"Body");var cape:=_part(f,"hide_cape")
		var skin_mesh:=body.mesh;var original_data:Array=skin_mesh.get("_surfaces").duplicate(true)
		var source_data:Array=f._plain_skin.get("_surfaces").duplicate(true)
		var nodes:=f._parts.duplicate();var rig:=f.skeleton;var player:=f.player
		var full_rest:Mesh=f._merged.Rest.mesh;var full_body:Mesh=f._merged.Body.mesh
		var other_rest:Mesh=other._merged.Rest.mesh
		assert_object(_part(other,"Body").mesh).is_same(skin_mesh)
		f.play("sit",0.0,.2);player.pause();var at:=player.current_animation_position
		f.look.without=["hide_cape"];f._dress()
		var bare_rest:Mesh=f._merged.Rest.mesh
		assert_int(_vertices(full_rest)-_vertices(bare_rest)).is_equal(_vertices(cape.mesh))
		assert_bool(_part(f,"hide_cape").visible).is_false()
		for lit:bool in [false,true]:
			f.look.lit=lit;f._dress()
			assert_object(body.mesh).is_same(skin_mesh)
			assert_bool(f._parts==nodes).is_true()
			assert_object(f.skeleton).is_same(rig);assert_object(f.player).is_same(player)
			assert_bool(player.is_playing()).is_false()
			assert_float(player.current_animation_position).is_equal_approx(at,.000001)
			assert_bool(cape.visible).is_false()
			if lit:
				assert_object(f._merged.Rest.mesh).is_same(bare_rest)
				for node:MeshInstance3D in f._parts:
					if String(node.name).begins_with("prop_"):continue
					assert_bool(node.visible).is_false()
					for surface in node.get_surface_override_material_count():assert_object(node.get_surface_override_material(surface)).is_null()
			else:
				assert_bool(body.visible).is_true();assert_bool(_part(f,"hide_wrap").visible).is_true()
				for node:MeshInstance3D in f._merged.values():assert_bool(node.visible).is_false()
		f.look.without=[];f._dress()
		assert_object(f._merged.Rest.mesh).is_same(full_rest)
		assert_object(f._merged.Body.mesh).is_same(full_body)
		assert_object(other._merged.Rest.mesh).is_same(other_rest)
		assert_bool(skin_mesh.get("_surfaces")==original_data).is_true()
		assert_bool(f._plain_skin.get("_surfaces")==source_data).is_true()
		f.free();other.free()
