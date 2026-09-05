extends GdUnitTestSuite

# Custom shader samplers do not trigger Godot's automatic 3D texture detection.
# Keep import settings under source control so a clean checkout has the same
# filtered aerial terrain as the graphics worker's machine.
const MAP_TEXTURES:Array[String]=[
	"res://assets/terrain/temperate_ground_albedo_v1.png",
	"res://assets/terrain/temperate_forest_albedo_v1.png",
	"res://assets/terrain/temperate_regional_satellite_v2.png",
	"res://assets/textures/settlement_material_atlas_v2.png",
	"res://assets/textures/settlement_roof_material_atlas_v1.png",
	"res://assets/textures/settlement_roof_material_atlas_late_v1.png",
]

func test_aerial_materials_have_real_mip_chains()->void:
	for path in MAP_TEXTURES:
		var texture:=load(path) as Texture2D
		assert_object(texture).is_not_null()
		if texture==null: continue
		var pixels:=texture.get_image()
		assert_object(pixels).is_not_null()
		if pixels==null: continue
		assert_bool(pixels.has_mipmaps()).is_true()
		assert_int(pixels.get_mipmap_count()).is_greater(0)


func test_both_roof_eras_actually_sample_their_mip_chains()->void:
	var renderer:Node3D=auto_free(preload("res://scripts/local_terrain.gd").new())
	var material:ShaderMaterial=renderer._settlement_fabric_material(3,0.62)
	for sampler in ["roof_material_atlas","late_roof_material_atlas"]:
		assert_str(material.shader.code).contains("uniform sampler2D %s : source_color, filter_linear_mipmap, repeat_disable;" % sampler)
		var texture:=material.get_shader_parameter(sampler) as Texture2D
		assert_object(texture).is_not_null()
		if texture: assert_bool(texture.get_image().has_mipmaps()).is_true()


func test_field_phase_colors_survive_without_changing_opacity()->void:
	var renderer:Node3D=auto_free(preload("res://scripts/local_terrain.gd").new())
	var plot:={"land_use":"field","crop_family":"grain","id":4,"seed":13,"status":"active","condition":1.0}
	plot.cultivation_phase="growing"
	var growing:Color=renderer._settlement_plot_color(plot)
	plot.cultivation_phase="mature"
	var mature:Color=renderer._settlement_plot_color(plot)
	plot.cultivation_phase="prepared"
	var prepared:Color=renderer._settlement_plot_color(plot)
	assert_float(growing.g-growing.r).is_greater(0.0)
	assert_float(mature.r-mature.g).is_greater(0.0)
	assert_float(prepared.r-prepared.g).is_greater(0.0)
	for tint:Color in [growing,mature,prepared]: assert_bool(is_equal_approx(tint.a,0.18)).is_true()
	var material:ShaderMaterial=renderer._settlement_fabric_material(1,0.74)
	assert_str(material.shader.code).contains("fabric=COLOR.rgb*field_surface_value;")
