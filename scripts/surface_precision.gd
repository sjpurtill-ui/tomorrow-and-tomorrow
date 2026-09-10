extends RefCounted
## Reduce world wave phases in GDScript's double precision before uploading
## small angles. Vector2.dot would round the large product to single precision.
static func water_parameters(point:Vector2)->Dictionary:
	var origin:=(point/64.0).floor()*64.0
	var x:=float(origin.x);var z:=float(origin.y)
	return {
		"surface_origin":origin,
		"wave_phase":Vector4(fposmod(x*76.0+z*42.0,TAU),fposmod(x*-53.0+z*86.0,TAU),fposmod(x*9.7-z*11.1,TAU),fposmod(x*-7.3+z*5.1,TAU)),
		"ripple_phase":Vector2(fposmod(x*780.0+z*390.0,TAU),fposmod(x*631.8+z*315.9,TAU))
	}
static func configure_water(material:ShaderMaterial,point:Vector2)->void:
	var parameters:=water_parameters(point)
	for key:String in parameters:material.set_shader_parameter(key,parameters[key])
