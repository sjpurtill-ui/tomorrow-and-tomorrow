extends GdUnitTestSuite
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Wardrobe=preload("res://scripts/hud/court_wardrobe.gd")
var _saved_manifest:Dictionary
var _saved_cache:Dictionary

func before_test()->void:
	_saved_manifest=Wardrobe._legacy_manifest
	_saved_cache=Wardrobe._legacy_cache
	Wardrobe._legacy_manifest={"variants":{}}
	Wardrobe._legacy_cache={}

func after_test()->void:
	Wardrobe._legacy_manifest=_saved_manifest
	Wardrobe._legacy_cache=_saved_cache

func _part(f:Node,name:String)->MeshInstance3D:
	for node:MeshInstance3D in f._parts:
		if String(node.name)==name:return node
	return null

func _figure(lit:=false)->Figure:
	var f:=Figure.new();add_child(f)
	f.setup({"variant":"male_adult","outfit":"tunic","lit":lit,"stance":"stand"})
	return f

## Stand-in resources exercise loader ownership without depending on a particular
## garment shape. The real approved bundles have their own invariant/pose suite.
func _approve(f:Node3D,complete:=true)->Dictionary:
	var names:=["tunic_body","tunic_trim","tunic_belt","tunic_shoes"]
	Wardrobe._legacy_manifest={"revision":"provider-fixture","variants":{"male_adult":{
		"file":"court_legacy_male_adult.glb","sha256":"fixture","outfits":["tunic"],"parts":{"tunic":names}}}}
	var body:=_part(f,"Body")
	var bundle:Dictionary={"LegacyBody":body.mesh.duplicate(true)}
	for name:String in names:bundle[name]=_part(f,name).mesh.duplicate(true)
	if not complete:bundle.erase("tunic_trim")
	var binds:=PackedStringArray()
	for i in body.skin.get_bind_count():binds.append(String(Wardrobe._bind_name(body.skin,f.skeleton,i)))
	Wardrobe._legacy_cache["provider-fixture:court_legacy_male_adult.glb:fixture|"+",".join(binds)]=bundle
	return bundle

func test_missing_and_incomplete_replacements_keep_the_original_whole_outfit()->void:
	var f:=_figure();var body:=_part(f,"Body").mesh;var garment:=_part(f,"tunic_body").mesh
	assert_str(f._legacy_key).is_empty()
	_approve(f,false);f._legacy_outfit="";f._dress()
	assert_object(_part(f,"Body").mesh).is_same(body)
	assert_object(_part(f,"tunic_body").mesh).is_same(garment)
	assert_str(f._legacy_key).is_empty()
	assert_bool(Wardrobe.legacy_parts("child","tunic",_part(f,"Body").skin,f.skeleton).is_empty()).is_true()
	assert_bool(Wardrobe.legacy_parts("male_adult","robe",_part(f,"Body").skin,f.skeleton).is_empty()).is_true()
	_approve(f)
	Wardrobe._legacy_manifest.variants.male_adult.parts.tunic.erase("tunic_trim")
	f._legacy_outfit="";f._dress()
	assert_object(_part(f,"Body").mesh).is_same(body)
	assert_object(_part(f,"tunic_body").mesh).is_same(garment)
	f.free()

func test_legacy_redressing_reuses_nodes_and_preserves_source_body_and_animation()->void:
	var f:=_figure();var nodes:=f._parts.duplicate();var body:=_part(f,"Body");var original:=body.mesh
	var garment:=_part(f,"tunic_body").mesh;var rig:=f.skeleton;var player:=f.player
	var source_data:Array=original.get("_surfaces").duplicate(true)
	var bundle:=_approve(f)
	f.play("walk_in",0.0,.35);var at:=player.current_animation_position
	f._legacy_outfit="";f._dress()
	assert_object(body.mesh).is_same(bundle.LegacyBody)
	assert_object(_part(f,"tunic_body").mesh).is_same(bundle.tunic_body)
	assert_bool(f._parts==nodes).is_true()
	assert_object(f.skeleton).is_same(rig);assert_object(f.player).is_same(player)
	assert_str(player.current_animation).is_equal("walk_in")
	assert_float(player.current_animation_position).is_equal_approx(at,.000001)
	assert_int(body.mesh.get_blend_shape_count()).is_equal(original.get_blend_shape_count())
	for i in original.get_blend_shape_count():assert_str(String(body.mesh.get_blend_shape_name(i))).is_equal(String(original.get_blend_shape_name(i)))
	f.look.outfit="robe";f._dress()
	assert_object(body.mesh).is_same(original)
	assert_object(_part(f,"tunic_body").mesh).is_same(garment)
	f.look.outfit="business";f._dress();assert_object(body.mesh).is_same(f._wardrobe_skin)
	f.look.outfit="tunic";f._dress();assert_object(body.mesh).is_same(bundle.LegacyBody)
	assert_bool(original.get("_surfaces")==source_data).is_true()
	f.free()

func test_merged_replacement_has_distinct_cache_identity_without_extra_draw_instances()->void:
	var f:=_figure(true);var old_body:Mesh=f._merged.Body.mesh;var old_rest:Mesh=f._merged.Rest.mesh
	var count:=f._parts.size();_approve(f);f._legacy_outfit="";f._dress()
	assert_int(f._parts.size()).is_equal(count)
	assert_object(f._merged.Body.mesh).is_not_same(old_body)
	assert_object(f._merged.Rest.mesh).is_not_same(old_rest)
	var fitted_body:Mesh=f._merged.Body.mesh;var fitted_rest:Mesh=f._merged.Rest.mesh
	f._dress()
	assert_object(f._merged.Body.mesh).is_same(fitted_body)
	assert_object(f._merged.Rest.mesh).is_same(fitted_rest)
	for node:MeshInstance3D in f._parts:
		if String(node.name).begins_with("prop_"):continue
		assert_bool(node.visible).is_false()
		for surface in node.get_surface_override_material_count():assert_object(node.get_surface_override_material(surface)).is_null()
	f.free()

func test_installed_bundles_preserve_source_body_and_select_only_listed_outfits()->void:
	Wardrobe._legacy_manifest={}
	var catalog:=Wardrobe.legacy_manifest()
	for variant:String in Figure.BODIES:
		var f:=Figure.new();add_child(f)
		f.setup({"variant":variant,"outfit":"tunic","lit":false,"stance":"stand"})
		var body:=_part(f,"Body");var source:Mesh=f._plain_skin
		var original_data:Array=source.get("_surfaces").duplicate(true)
		var rig:=f.skeleton;var player:=f.player
		var entry:Dictionary=catalog.get("variants",{}).get(variant,{})
		var unchanged_channels:=[0]
		for channel in [["hide",1],["tunic",2],["robe",3]]:
			if not channel[0] in entry.get("outfits",[]):unchanged_channels.append(channel[1])
		for outfit:String in Wardrobe.LEGACY_OUTFITS:
			f.look.outfit=outfit;f._dress()
			assert_object(f.skeleton).is_same(rig);assert_object(f.player).is_same(player)
			if outfit in entry.get("outfits",[]):
				assert_str(f._legacy_key).is_not_empty()
				assert_object(body.mesh).is_same(f._legacy_skin)
				assert_object(body.mesh).is_not_same(source)
				assert_bool(_body_records(body.mesh,unchanged_channels)==_body_records(source,unchanged_channels)).is_true()
				for name:String in entry.parts[outfit]:
					assert_bool(_part(f,name).visible).is_true()
					assert_object(_part(f,name).skin).is_same(body.skin)
			else:
				assert_str(f._legacy_key).is_empty()
				assert_object(body.mesh).is_same(source)
		assert_bool(source.get("_surfaces")==original_data).is_true()
		f.free()

## Imported glTFs can reorder vertices. Compare the full data by value, including
## all face morphs and every coverage channel the bundle did not replace.
func _body_records(mesh:Mesh,colors:Array)->Dictionary:
	var records:Dictionary={}
	for surface in mesh.get_surface_count():
		var arrays:=mesh.surface_get_arrays(surface)
		var morphs:=mesh.surface_get_blend_shape_arrays(surface)
		for i in arrays[Mesh.ARRAY_VERTEX].size():
			var record:Array=[]
			for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:record.append(arrays[channel][i] if arrays[channel]!=null else null)
			for channel in [Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS]:
				for j in 4:record.append(arrays[channel][i*4+j])
			for channel:int in colors:record.append(arrays[Mesh.ARRAY_COLOR][i][channel])
			for morph:Array in morphs:
				for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL]:record.append(morph[channel][i] if morph[channel]!=null else null)
			var key:=hash(record);records[key]=int(records.get(key,0))+1
	return records
