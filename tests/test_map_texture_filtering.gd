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
