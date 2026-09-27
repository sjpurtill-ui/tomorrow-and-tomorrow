extends RefCounted
## SETTLEMENT IN INK (codex/beauty-2): huts, stores, workshops and hearth
## furniture painted in the map's art direction instead of flat plastic.
##
## One shared material for the settlement kits (early_settlement_visual.gd,
## organic_town_visual.gd, settlement_architecture_kit.gd and the communal
## objects of early_settlement_ground.gd). It keeps each kit's vertex and
## instance colours (wear, fire damage), and paints them:
## - warm light and cool shade from the same low north-west sun as the land,
##   never black on the shaded side;
## - thatch and timber texture laid along each roof's slope;
## - one clean ink line round each form's silhouette, about a screen pixel
##   wide at every zoom (an outline pass: the form drawn again, a pixel larger,
##   in ink, behind itself), the way an illustrated plan draws its buildings.
##   It replaced a line taken from faces turned edge-on, which broke into dots;
## - firelight: faces near the hearth glow warm and flicker (the hearth is
##   placed by living_map.gd with set_hearth());
## - the land's drifting cloud shadows (map_cloud.gdshaderinc).
## Visual only; one material, no per-frame rebuilds.

static var _material:ShaderMaterial
static var _srgb_material:ShaderMaterial
static var _shadow_material:ShaderMaterial
static var _shadow_quad:QuadMesh
## Away from the low north-west sun, in the ground plane (world x, z).
const SHADOW_FALL:=Vector2(0.7385,0.6743)

static func material()->ShaderMaterial:
	if _material and is_instance_valid(_material):return _material
	var shader:=Shader.new()
	shader.code=SHADER
	_material=ShaderMaterial.new()
	_material.shader=shader
	_material.next_pass=outline_material()
	# Cloud shadows and the live wind reach it like any other map material.
	(load("res://scripts/map_ambience.gd") as GDScript).call("bind_wind_material",_material)
	return _material

static var _ground_material:ShaderMaterial
## The same paint without the silhouette pass, for flat worked ground laid
## on the land (kitchen beds): an outline would print it as a dark slab.
static func ground_material()->ShaderMaterial:
	if _ground_material and is_instance_valid(_ground_material):return _ground_material
	_ground_material=material().duplicate() as ShaderMaterial
	_ground_material.next_pass=null
	_ground_material.set_shader_parameter("ink_strength",0.0)
	(load("res://scripts/map_ambience.gd") as GDScript).call("bind_wind_material",_ground_material)
	return _ground_material

static var _outline_material:ShaderMaterial
static var _pixel_km:=0.0
## One screen pixel in world km at the current zoom (the map sets it when
## the zoom changes; the outline is held at about a pixel).
static func set_pixel(km:float)->void:
	if absf(km-_pixel_km)<=_pixel_km*0.01:return
	_pixel_km=km
	outline_material().set_shader_parameter("pixel_km",km)
## The outline pass shared by every inked form.
static func outline_material()->ShaderMaterial:
	if _outline_material and is_instance_valid(_outline_material):return _outline_material
	var shader:=Shader.new()
	shader.code=OUTLINE_SHADER
	_outline_material=ShaderMaterial.new()
	_outline_material.shader=shader
	return _outline_material

## The same ink for meshes whose vertex colours are authored in sRGB (the
## great works' landmarks): converted to linear before painting.
static func material_srgb()->ShaderMaterial:
	if _srgb_material and is_instance_valid(_srgb_material):return _srgb_material
	_srgb_material=material().duplicate() as ShaderMaterial
	_srgb_material.set_shader_parameter("vertex_srgb",true)
	# Large walls seen edge-on must not all turn to ink.
	_srgb_material.set_shader_parameter("ink_strength",0.3)
	(load("res://scripts/map_ambience.gd") as GDScript).call("bind_wind_material",_srgb_material)
	return _srgb_material

## Where the home hearth burns (world position) and how strongly (0-1).
static func set_hearth(at:Vector3,power:float)->void:
	var m:=material()
	m.set_shader_parameter("hearth",Vector4(at.x,at.y,at.z,clampf(power,0.0,1.0)))
	if _srgb_material:_srgb_material.set_shader_parameter("hearth",Vector4(at.x,at.y,at.z,clampf(power,0.0,1.0)))
	if _ground_material:_ground_material.set_shader_parameter("hearth",Vector4(at.x,at.y,at.z,clampf(power,0.0,1.0)))

## Soft cool shadows on the ground under a batch of buildings, cast a little
## away from the sun: each building sits on the land instead of floating on
## it. One draw call per batch, built with the batch (never per frame).
## `transforms` are the batch's instance transforms, `bounds` its mesh AABB.
static func add_ground_shadows(parent:Node3D,name:String,transforms:Array[Transform3D],bounds:AABB)->MultiMeshInstance3D:
	if transforms.is_empty() or parent==null:return null
	if _shadow_quad==null:
		_shadow_quad=QuadMesh.new();_shadow_quad.size=Vector2.ONE
		_shadow_quad.orientation=PlaneMesh.FACE_Y
	if _shadow_material==null:
		var shader:=Shader.new();shader.code=SHADOW_SHADER
		_shadow_material=ShaderMaterial.new();_shadow_material.shader=shader
	var extent:=Vector2(maxf(absf(bounds.position.x),absf(bounds.end.x)),maxf(absf(bounds.position.z),absf(bounds.end.z)))
	var height:=maxf(bounds.end.y,0.5)
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.mesh=_shadow_quad;batch.instance_count=transforms.size()
	for i in transforms.size():
		var source:=transforms[i]
		var unit:=source.basis.x.length()
		# Cast about half the building's height away from the sun.
		var fall:=SHADOW_FALL*height*unit*0.55
		var basis:=source.basis*Basis.from_scale(Vector3(extent.x*2.0+height*0.7,1.0,extent.y*2.0+height*0.7))
		batch.set_instance_transform(i,Transform3D(basis,source.origin+Vector3(fall.x,0.0005,fall.y)))
	var node:=MultiMeshInstance3D.new();node.name=name
	node.multimesh=batch;node.material_override=_shadow_material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Kept in their own group, apart from the buildings' own batches.
	var group:=parent.get_node_or_null("SettlementGroundShadows") as Node3D
	if group==null:
		group=Node3D.new();group.name="SettlementGroundShadows"
		parent.add_child(group)
	group.add_child(node)
	return node

## The flicker clock (seconds); living_map.gd advances it with the fire.
static func set_clock(seconds:float)->void:
	if _material:_material.set_shader_parameter("anim_clock",seconds)
	if _srgb_material:_srgb_material.set_shader_parameter("anim_clock",seconds)
	for i in range(_timed.size()-1,-1,-1):
		var timed:=_timed[i].get_ref() as ShaderMaterial
		if timed==null:_timed.remove_at(i)
		else:timed.set_shader_parameter("clock",seconds)

static var _timed:Array[WeakRef]=[]
## Settlement life drawn in ink (penned animals) runs on the same clock.
static func keep_time(material:ShaderMaterial)->void:
	if material:_timed.append(weakref(material))

const SHADER:="""
shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;
#include "res://scripts/map_palette.gdshaderinc"
#include "res://scripts/map_cloud.gdshaderinc"
uniform vec4 hearth = vec4(0.0);
uniform float anim_clock = 0.0;
uniform bool vertex_srgb = false;
uniform float ink_strength = 1.0;
uniform vec4 map_wind = vec4(1.0, 0.0, 0.0, 0.0);
varying vec3 world_position;
varying vec3 world_normal;
varying vec3 kit_vertex;
varying vec3 kit_normal;
const vec3 SUN = vec3(-0.573, 0.515, -0.637);

void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX*vec4(NORMAL, 0.0)).xyz);
	// The kit's own mesh space (metres), precise at any world position.
	kit_vertex = VERTEX;
	kit_normal = NORMAL;
}

void fragment() {
	vec3 n = normalize(world_normal);
	if (!FRONT_FACING) { n = -n; }
	vec3 base = COLOR.rgb;
	if (vertex_srgb) { base = mix(base/12.92, pow((base+0.055)/1.055, vec3(2.4)), step(0.04045, base)); }
	float roof = smoothstep(0.25, 0.60, n.y)*(1.0-smoothstep(0.93, 0.99, n.y));
	// Thatch and hide roofs read as warm straw from above, not dark wood.
	vec3 straw = vec3(0.62, 0.52, 0.34);
	float luma = dot(base, vec3(0.2126, 0.7152, 0.0722));
	// Only dark timber-coloured roofs take the straw (authored thatch is
	// already straw; fired tile, red and far redder than it is green, keeps
	// its colour).
	float tile = smoothstep(1.45, 1.85, base.r/max(base.g, 0.01));
	// Roofs the later kit marks by vertex alpha (settlement_architecture_kit:
	// 0.98 tile, 0.96 shingle, 0.94 packed earth, 0.92 slate) keep their own
	// colour and get their own laid texture below instead of straw strokes.
	float laid = step(COLOR.a, 0.985)*step(0.90, COLOR.a);
	base = mix(base, straw*clamp(luma/0.20, 0.55, 1.35), roof*0.45*(1.0-tile)*(1.0-laid)*(1.0-smoothstep(0.30, 0.45, luma)));
	// Thatch, bark and hide: fine strokes running down each roof's slope,
	// broken so they read as laid material rather than stripes.
	vec2 fall = normalize(kit_normal.xz+vec2(1e-5));
	// In the kit's own metres: kilometre world coordinates are too coarse
	// for strokes a hand's breadth apart.
	vec2 local = kit_vertex.xz;
	float along = dot(local, vec2(-fall.y, fall.x))*9.0;
	float down = dot(local, fall)*2.2;
	float strand = map_paper_noise(vec2(along, down*0.15));
	// Strokes only where the screen can hold them: finer than a pixel they
	// would shimmer into swirls.
	float stroke_px = fwidth(along);
	base *= 1.0+(strand-0.5)*0.22*roof*(1.0-laid)*(1.0-smoothstep(0.35, 0.9, stroke_px));
	if (laid > 0.5 && roof > 0.0) {
		// Tile and shingle: courses a hand apart down the slope, each piece
		// butting the next, alternate courses offset; packed earth is only
		// mottled. Faded before a course is under two pixels.
		float course_m = COLOR.a > 0.97 ? 0.34 : (COLOR.a > 0.95 ? 0.26 : 0.30);
		float down_m = dot(local, fall);
		float across_m = dot(local, vec2(-fall.y, fall.x));
		float row = down_m/course_m;
		float piece = across_m/(course_m*(COLOR.a > 0.97 ? 0.75 : 1.1))+0.5*floor(row);
		float course_px = fwidth(row);
		float visible = 1.0-smoothstep(0.25, 0.5, course_px);
		float lap = smoothstep(0.70, 0.98, fract(row));
		float joint = 1.0-smoothstep(0.0, 0.10, abs(fract(piece)-0.5)*2.0-0.8);
		float piece_tone = map_paper_hash(vec2(floor(piece), floor(row)));
		if (COLOR.a < 0.95 && COLOR.a > 0.93) {
			base *= 1.0+(map_paper_noise(local*1.7)-0.5)*0.18;
		} else {
			base *= mix(1.0, (1.0-lap*0.28)*(1.0-joint*0.20)*(0.92+0.16*piece_tone), visible*roof);
		}
	}
	// Warm light, cool shade: the painted key light shared with the land.
	float ndl = dot(n, SUN);
	base *= mix(vec3(0.90, 0.89, 0.94), vec3(1.06, 1.02, 0.94), smoothstep(-0.2, 0.6, ndl));
	base = map_palette_grade(base);
	base *= map_cloud_shadow(world_position.xz, world_position.y, map_cloud, map_cloud_scale);
	// Faces seen nearly edge-on darken a little (the silhouette line itself
	// is the outline pass, clean at any zoom).
	float facing = abs(dot(NORMAL, VIEW));
	float ink = (1.0-smoothstep(0.02, 0.22, facing))*0.22*ink_strength;
	base = mix(base, vec3(0.105, 0.080, 0.055), ink);
	ALBEDO = base;
	ROUGHNESS = 0.95;
	// Sky fill on the shaded side, then firelight near the hearth.
	// A painter's shade stays warm and open: never a grey hole.
	// Light bounced up from the sunlit ground, warm, fills the shaded side.
	vec3 glow = base*vec3(1.0, 0.90, 0.78)*0.55*(1.0-smoothstep(-0.05, 0.55, ndl));
	if (hearth.w > 0.0) {
		vec3 to_fire = hearth.xyz-world_position;
		float d = length(to_fire)*1000.0;
		// The fire reaches the nearer roofs round the hearth (codex/beauty-5).
		float reach = 1.0-smoothstep(3.0, 40.0, d);
		if (reach > 0.0) {
			float turned = 0.45+0.55*max(dot(n, to_fire/max(length(to_fire), 1e-6)), 0.0);
			float flicker = 0.86+0.09*sin(anim_clock*11.0)+0.05*sin(anim_clock*29.0+1.3);
			glow += base*vec3(1.0, 0.56, 0.24)*hearth.w*pow(reach, 1.6)*turned*flicker*0.75;
		}
	}
	EMISSION = glow;
}
"""

## The silhouette line: the form again, grown outward in the ground plane by
## about `outline_px` screen pixels from its own vertical axis (low forms read
## from above as near-convex), back faces only, in iron-gall ink. The map's
## pixel's size in world km comes from the map (set_pixel).
const OUTLINE_SHADER:="""
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;
uniform float outline_px = 1.15;
uniform float pixel_km = 0.0002;
void vertex() {
	float model_scale = max(length(MODEL_MATRIX[0].xyz), 1e-9);
	float grow = min(pixel_km*outline_px, 0.004)/model_scale;
	vec2 radial = VERTEX.xz;
	float reach = length(radial);
	// A form only a few pixels across keeps its colour: the line thins away
	// before it could turn a distant hut into an ink speck.
	float reach_px = reach*model_scale/max(pixel_km, 1e-9);
	grow *= clamp((reach_px-2.5)/5.0, 0.0, 1.0);
	if (reach > 1e-6) { VERTEX.xz += radial/reach*grow; }
	// A touch of height as well, so a flat roof edge seen from above keeps it.
	VERTEX.y += grow*0.5*step(0.05, VERTEX.y);
}
void fragment() {
	ALBEDO = vec3(0.105, 0.080, 0.055);
}
"""

const SHADOW_SHADER:="""
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
void fragment() {
	vec2 q = (UV-vec2(0.5))*2.0;
	float d = length(q);
	// A soft cool pool, deepest just under the eaves.
	float a = (1.0-smoothstep(0.15, 1.0, d))*0.78;
	// A pool only a few pixels wide would print a dark speck: it fades out.
	float quad_px = 1.0/max(max(fwidth(UV.x), fwidth(UV.y)), 1e-5);
	a *= smoothstep(5.0, 16.0, quad_px);
	ALBEDO = mix(vec3(1.0), vec3(0.55, 0.59, 0.68), a);
}
"""
