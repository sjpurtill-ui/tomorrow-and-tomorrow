extends GdUnitTestSuite
const Registry=preload("res://scripts/fog_material_registry.gd")
const Intelligence=preload("res://scripts/city_intelligence.gd")
func material()->ShaderMaterial:
	var shader:=Shader.new()
	shader.code="shader_type spatial; uniform sampler2D discovery_mask; uniform vec2 fog_world_size; uniform vec2 fog_current_origin;"
	var result:=ShaderMaterial.new();result.shader=shader;return result
func test_discarded_patches_do_not_accumulate_materials()->void:
	var registry:=Registry.new()
	var retained:=material()
	registry.register(retained,null,Vector2(100,50),Vector2.ZERO)
	var retired:WeakRef
	for i in 2000:
		var transient:=material();retired=weakref(transient)
		registry.register(transient,null,Vector2(100,50),Vector2.ZERO)
		transient=null
	assert_object(retired.get_ref()).is_null()
	assert_int(registry.live_materials().size()).is_equal(1)
	assert_int(registry.references.size()).is_equal(1)
	registry.register(retained,null,Vector2(100,50),Vector2.ZERO)
	assert_int(registry.references.size()).is_equal(1)
func test_stationary_origin_performs_no_repeated_uniform_writes()->void:
	var registry:=Registry.new();var visible:=material()
	registry.register(visible,null,Vector2(100,50),Vector2.ZERO)
	registry.update(null,Vector2.ZERO)
	var writes:=0
	for frame in 600:writes+=registry.update(null,Vector2.ZERO)
	assert_int(writes).is_equal(0)
	assert_int(registry.update(null,Vector2(3,4))).is_equal(1)
	assert_vector(visible.get_shader_parameter("fog_current_origin")).is_equal(Vector2(3,4))
	var image:=Image.create(2,2,false,Image.FORMAT_L8)
	var texture:=ImageTexture.create_from_image(image)
	assert_int(registry.update(texture,Vector2(3,4))).is_equal(1)
	var fresh:=material();registry.register(fresh,texture,Vector2(100,50),Vector2(3,4))
	assert_vector(fresh.get_shader_parameter("fog_current_origin")).is_equal(Vector2(3,4))
	assert_int(registry.update(texture,Vector2(3,4))).is_equal(0)
func test_map_query_preserves_nearby_reports_without_copying_distant_ones()->void:
	var knowledge:=Intelligence.new();knowledge.records={"player":{}}
	for i in 512:
		knowledge.records.player[str(i)]={"city_id":str(i),"civ_id":"other","controller":"other","position":{"x":float(i)*10,"z":0.0},"fields":{"population":{"value":123,"history":[1,2,3]}}}
	var nearby:=knowledge.known_cities("player","",false,Vector2.ZERO,10.0)
	assert_int(nearby.size()).is_equal(2)
	assert_str(nearby[1].city_id).is_equal("1")
	nearby[0].fields.population.history.append(99)
	assert_int(knowledge.records.player["0"].fields.population.history.size()).is_equal(3)
	assert_int(knowledge.known_cities("player","",false).size()).is_equal(512)
	assert_int(knowledge.known_cities("player","unseen",false,Vector2.ZERO,10).size()).is_equal(0)

