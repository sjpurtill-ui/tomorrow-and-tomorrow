extends GdUnitTestSuite
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Wardrobe=preload("res://scripts/hud/court_wardrobe.gd")

func _body(figure:Node)->MeshInstance3D:
	for part:MeshInstance3D in figure._parts:
		if part.name==&"Body":return part
	return null

func test_every_body_has_four_real_outfits_and_preserves_its_face_and_rig()->void:
	for variant:String in Figure.BODIES:
		var figure:=Figure.new();add_child(figure)
		assert_bool(figure.setup({"variant":variant,"outfit":"tunic","lit":false})).is_true()
		var original:=_body(figure).mesh
		var rig:=figure.skeleton;var player:=figure.player
		var arrays:=original.surface_get_arrays(0)
		var morphs:=original.surface_get_blend_shape_arrays(0)
		var fingerprints:Dictionary={}
		for outfit:String in Wardrobe.OUTFITS:
			figure.setup({"variant":variant,"outfit":outfit,"lit":false})
			assert_bool(figure._wardrobe_loaded).is_true()
			assert_object(figure.skeleton).is_same(rig)
			assert_object(figure.player).is_same(player)
			var clothed:=_body(figure).mesh
			var next:=clothed.surface_get_arrays(0)
			# glTF vertex-cache optimization may reorder the two imports. Compare
			# each vertex's full attributes and morphs independently of that order.
			assert_bool(_vertex_records(next,clothed.surface_get_blend_shape_arrays(0))==_vertex_records(arrays,morphs)).is_true()
			assert_bool(_triangles(next)==_triangles(arrays)).is_true()
			var count:=0;var geometry:=PackedVector3Array()
			for part:MeshInstance3D in figure._parts:
				if part.visible and String(part.name).begins_with(outfit+"_"):
					count+=1
					geometry.append_array(part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
					assert_object(part.skin).is_same(_body(figure).skin)
			assert_int(count).is_greater_equal(8)
			fingerprints[hash(geometry)]=true
		assert_int(fingerprints.size()).is_equal(4)
		figure.setup({"variant":variant,"outfit":"robe","lit":false})
		assert_object(_body(figure).mesh).is_same(original)
		for part:MeshInstance3D in figure._parts:
			for outfit:String in Wardrobe.OUTFITS:
				if String(part.name).begins_with(outfit+"_"):assert_bool(part.visible).is_false()
		figure.free()

func test_new_clothes_merge_and_redress_without_changing_the_animation_player()->void:
	for variant:String in Figure.BODIES:
		var figure:=Figure.new();add_child(figure)
		figure.setup({"variant":variant,"outfit":"business","lit":true})
		var player:=figure.player
		figure.play("walk_in",0.0,0.0)
		player.advance(.4)
		for outfit:String in ["medieval","courtcoat","formal","business","tunic","business"]:
			figure.look.outfit=outfit;figure._dress()
			assert_object(figure.player).is_same(player)
			assert_str(figure.player.current_animation).is_equal("walk_in")
			assert_bool(figure._merged.has("Body") and figure._merged.has("Rest")).is_true()
			assert_int(figure._merged.Rest.mesh.surface_get_array_len(0)).is_greater(500)
		figure.free()

func _vertex_records(arrays:Array,morphs:Array)->Dictionary:
	var records:Dictionary={}
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		var record:Array=[]
		for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:record.append(arrays[channel][i] if arrays[channel]!=null else null)
		for channel in [Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS]:
			for j in 4:record.append(arrays[channel][i*4+j])
		for morph:Array in morphs:
			for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL]:record.append(morph[channel][i] if morph[channel]!=null else null)
		var key:=hash(record);records[key]=int(records.get(key,0))+1
	return records

func _triangles(arrays:Array)->Dictionary:
	var result:Dictionary={};var ids:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in range(0,ids.size(),3):
		var points:Array=[hash(arrays[Mesh.ARRAY_VERTEX][ids[i]]),hash(arrays[Mesh.ARRAY_VERTEX][ids[i+1]]),hash(arrays[Mesh.ARRAY_VERTEX][ids[i+2]])]
		points.sort();var key:=hash(points);result[key]=int(result.get(key,0))+1
	return result
