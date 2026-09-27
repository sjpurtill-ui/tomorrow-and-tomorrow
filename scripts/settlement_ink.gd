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
## - a fine ink line where a form turns away from the eye, the way an
##   illustrated plan draws its buildings;
## - firelight: faces near the hearth glow warm and flicker (the hearth is
##   placed by living_map.gd with set_hearth());
## - the land's drifting cloud shadows (map_cloud.gdshaderinc).
## Visual only; one material, no per-frame rebuilds.

static var _material:ShaderMaterial
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
	# Cloud shadows and the live wind reach it like any other map material.
	(load("res://scripts/map_ambience.gd") as GDScript).call("bind_wind_material",_material)
	return _material

## Where the home hearth burns (world position) and how strongly (0-1).
static func set_hearth(at:Vector3,power:float)->void:
	var m:=material()
	m.set_shader_parameter("hearth",Vector4(at.x,at.y,at.z,clampf(power,0.0,1.0)))

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
	float roof = smoothstep(0.25, 0.60, n.y)*(1.0-smoothstep(0.93, 0.99, n.y));
	// Thatch and hide roofs read as warm straw from above, not dark wood.
	vec3 straw = vec3(0.62, 0.52, 0.34);
	float luma = dot(base, vec3(0.2126, 0.7152, 0.0722));
	// Only dark timber-coloured roofs take the straw (authored thatch is
	// already straw; fired tile, red and far redder than it is green, keeps
	// its colour).
	float tile = smoothstep(1.45, 1.85, base.r/max(base.g, 0.01));
	base = mix(base, straw*clamp(luma/0.20, 0.55, 1.35), roof*0.45*(1.0-tile)*(1.0-smoothstep(0.30, 0.45, luma)));
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
	base *= 1.0+(strand-0.5)*0.22*roof*(1.0-smoothstep(0.35, 0.9, stroke_px));
	// Warm light, cool shade: the painted key light shared with the land.
	float ndl = dot(n, SUN);
	base *= mix(vec3(0.84, 0.88, 0.98), vec3(1.06, 1.02, 0.94), smoothstep(-0.2, 0.6, ndl));
	base = map_palette_grade(base);
	base *= map_cloud_shadow(world_position.xz, world_position.y, map_cloud, map_cloud_scale);
	// A fine ink line where the form turns away from the eye.
	float facing = abs(dot(NORMAL, VIEW));
	float ink = (1.0-smoothstep(0.10, 0.34, facing))*0.55;
	base = mix(base, vec3(0.105, 0.080, 0.055), ink);
	ALBEDO = base;
	ROUGHNESS = 0.95;
	// Sky fill on the shaded side, then firelight near the hearth.
	// A painter's shade stays warm and open: never a grey hole.
	vec3 glow = base*vec3(0.86, 0.88, 0.98)*0.52*(1.0-smoothstep(-0.05, 0.55, ndl));
	if (hearth.w > 0.0) {
		vec3 to_fire = hearth.xyz-world_position;
		float d = length(to_fire)*1000.0;
		float reach = 1.0-smoothstep(3.0, 26.0, d);
		if (reach > 0.0) {
			float turned = 0.45+0.55*max(dot(n, to_fire/max(length(to_fire), 1e-6)), 0.0);
			float flicker = 0.86+0.09*sin(anim_clock*11.0)+0.05*sin(anim_clock*29.0+1.3);
			glow += base*vec3(1.0, 0.56, 0.24)*hearth.w*reach*reach*turned*flicker*0.9;
		}
	}
	EMISSION = glow;
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
	ALBEDO = mix(vec3(1.0), vec3(0.55, 0.59, 0.68), a);
}
"""
