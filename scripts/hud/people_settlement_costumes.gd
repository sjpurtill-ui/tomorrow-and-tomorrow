extends RefCounted
## Private People-view garments. The map's material and visibility policy stay
## unchanged. Billboard placement is shared; painted poses have their own motion.
## These are bounded illustrations of known methods, not individual issued stock.
## No date, population size, building tier or research-in-progress unlocks attire.
const Ink = preload("res://scripts/map_life_ink.gd")
const HIDE_PALETTE: Array[Color] = [Color("967651"), Color("796047"), Color("b49b73"), Color("69523e"), Color("aa8860")]
const WOVEN_PALETTE: Array[Color] = [Color("c3b38c"), Color("a5936e"), Color("8b795e"), Color("d0c3a2"), Color("75634d")]
const RELEVANT := ["cordage", "fiber_grading", "bone_needle_sewing", "plain_weaving", "garment_pattern_cutting", "layered_clothing_design"]
const PEOPLE_ATLAS := "res://assets/ui/people/settlement-people-v1.png"
const ATLAS_COLUMNS := 6
const ATLAS_ROWS := 4
const WALK_ATLAS := "res://assets/ui/people/settle-people-walk-v1.png"
const CARRY_ATLAS := "res://assets/ui/people/settle-people-carry-v1.png"
const MALE_WALK_ATLAS := "res://assets/ui/people/settle-people-male-walk-v1.png"
const MALE_CARRY_ATLAS := "res://assets/ui/people/settle-people-male-carry-v1.png"
const ROLE_ATLAS := "res://assets/ui/people/settle-people-roles-v1.png"
const ROLES := ["Food", "Survey", "Extraction", "Construction", "Crafting", "Logistics", "Knowledge", "Administration", "Defense"]
const WORK_POSE := 20
# Complete crouches remain shorter than standing people; the artwork is never
# stretched into a standing silhouette. These are presentation proportions only.
const ROLE_HEIGHTS := [.76,.82,.94,.65,.62,.63,.64,.65,.66,.82,.94,.94,.64,.65,.60,.61,1.02,1.02]
const WALK_COLUMNS := 4
static var _atlas_texture: Texture2D
static var _walk_texture: Texture2D
static var _carry_texture: Texture2D
static var _motion_data: Dictionary = {}

## Private representative fields: x stays stable identity, y is the pose and w
## is distance phase. Legacy z=0/1/2 remains untouched. All encoded roles are adults.
static func instance_code(role_index: int, sex: int, carrying: bool = false) -> float:
	return float(4*(clampi(role_index,0,ROLES.size()-1)+1)+2*posmod(sex,2)+(1 if carrying else 0))

static func instance_fields(code: float) -> Dictionary:
	var value := maxi(0,roundi(code))
	return {"role":clampi(value/4-1,-1,ROLES.size()-1),"sex":(value/2)%2 if value>=4 else 0,"carrying":value%2==1,"encoded":value>=4}

## `known` is the actual known_discoveries ledger (IDs). Optional context may
## contain an already-read adoption map and household goods coverage. Without
## measured coverage everyone retains basic wraps; knowledge is only a ceiling.
## Do not pass discovery_log: a record of a question is not acquired knowledge.
static func appearance(known: Array, recorded: Dictionary = {}) -> Dictionary:
	var methods: Dictionary = {}
	var evidence: Array[String] = []
	var adoption: Dictionary = recorded.get("adoption", {}) if recorded.get("adoption", {}) is Dictionary else {}
	for id: String in RELEVANT:
		if id not in known: continue
		var spread := float(adoption.get(id, 0.0))
		if recorded.has("adoption") and (not is_finite(spread) or spread < 0.1): continue
		methods[id] = true
		evidence.append(id)
	var sewn: bool = methods.has("bone_needle_sewing")
	var woven: bool = methods.has("plain_weaving")
	var fitted: bool = woven and sewn and methods.has("garment_pattern_cutting")
	var stage := 3 if fitted else (2 if woven else (1 if sewn else 0))
	var supplied := clampf(float(recorded.get("coverage", 0.0)), 0.0, 1.0)
	if not is_finite(supplied): supplied = 0.0
	var palette := WOVEN_PALETTE.duplicate() if woven else HIDE_PALETTE.duplicate()
	var uniforms := {"garment_stage": float(stage), "garment_supply": supplied,
		"garment_tied": methods.has("cordage"), "garment_sewn": sewn, "garment_layers": methods.has("layered_clothing_design"),
		"garment_light": palette[3] if woven else palette[0], "garment_dark": palette[4] if woven else palette[3]}
	return {"style": ["hide and fiber wraps", "joined hide wraps", "woven drapes", "cut woven tunics"][stage],
		"evidence": evidence, "palette": palette, "uniforms": uniforms, "key": hash([evidence, uniforms])}

## Only the painting between the shared pose calculation and tool strokes is
## replaced. The shared source remains untouched, including children/carrying,
## crouching, walking, gathering, chopping, fishing, learning and watch poses.
static func shader_code() -> String:
	var paint_start := Ink.PERSON.find("\tvec3 skin =")
	var tools_start := Ink.PERSON.find("\tif (tool_len > 0.0) {")
	assert(paint_start >= 0 and tools_start > paint_start, "Shared People pose boundary changed")
	return Ink.HEAD + GARMENT_HELPERS + Ink.PERSON.substr(0, paint_start) + GARMENT_PAINT + Ink.PERSON.substr(tools_start)

## The private illustrated view opts into this shader. The original map and
## procedural fallback remain unchanged. A complete cell keeps all poses on the
## same foot baseline; cropping each pose separately would stretch a crouch.
static func atlas_texture() -> Texture2D:
	if _atlas_texture != null: return _atlas_texture
	if not FileAccess.file_exists(PEOPLE_ATLAS): return null
	var source := Image.load_from_file(PEOPLE_ATLAS)
	if source == null or source.is_empty(): return null
	if source.get_width() % ATLAS_COLUMNS != 0 or source.get_height() % ATLAS_ROWS != 0: return null
	_atlas_texture = ImageTexture.create_from_image(source)
	return _atlas_texture

static func atlas_layout() -> PackedVector4Array:
	return _grid_layout(atlas_texture(), ATLAS_COLUMNS)

## An unvalidated/missing motion sheet keeps the neutral pose. The old two
## extended-leg paintings turn the torso; they are not a walking cycle.
static func walking_texture() -> Texture2D:
	if _walk_texture != null: return _walk_texture
	_walk_texture = _motion_texture(WALK_ATLAS)
	return _walk_texture

static func carrying_texture() -> Texture2D:
	if _carry_texture == null: _carry_texture = _motion_texture(CARRY_ATLAS)
	return _carry_texture

static func _motion_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path): return null
	var source := Image.load_from_file(path)
	if source == null or source.is_empty() or source.get_width() < 16 or source.get_height() < 16: return null
	return ImageTexture.create_from_image(source)

static func motion_uniforms() -> Dictionary:
	if not _motion_data.is_empty(): return _motion_data.duplicate(false)
	var texture := walking_texture()
	var carry := carrying_texture()
	var result := {"walk_atlas": texture, "walk_frames": _grid_layout(texture, WALK_COLUMNS), "walk_registration": _motion_registration(texture), "walk_atlas_ready": texture != null,
		"carry_atlas": carry, "carry_frames": _grid_layout(carry, WALK_COLUMNS), "carry_registration": _motion_registration(carry), "carry_atlas_ready": carry != null}
	for prefix: String in ["male_walk", "male_carry"]:
		var male_texture := _motion_texture(MALE_WALK_ATLAS if prefix=="male_walk" else MALE_CARRY_ATLAS)
		var frames := _male_layout(male_texture)
		result[prefix+"_atlas"] = male_texture
		result[prefix+"_frames"] = frames
		result[prefix+"_registration"] = _motion_registration(male_texture,frames)
		result[prefix+"_atlas_ready"] = male_texture!=null
	var roles := _motion_texture(ROLE_ATLAS)
	result.merge({"role_atlas":roles,"role_frames":_grid_layout(roles,6,3),"role_registration":_activity_registration(roles),"role_atlas_ready":roles!=null})
	if texture != null and carry != null and roles!=null: _motion_data = result
	return result.duplicate(false)

static func cast_uniforms() -> Dictionary:
	return motion_uniforms()

static func _activity_registration(texture: Texture2D) -> PackedVector4Array:
	var registrations := PackedVector4Array()
	if texture==null:return registrations
	var source:=texture.get_image()
	for index in 18:
		var start:=Vector2i(roundi(float(index%6)*source.get_width()/6),roundi(float(index/6)*source.get_height()/3))
		var end:=Vector2i(roundi(float(index%6+1)*source.get_width()/6),roundi(float(index/6+1)*source.get_height()/3))
		var extent:=end-start;var left:=extent.x;var right:=0;var top:=extent.y;var bottom:=0
		for y in extent.y:
			for x in extent.x:
				if source.get_pixel(start.x+x,start.y+y).a<.5:continue
				left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
		var height:=float(bottom-top)/extent.y
		registrations.append(Vector4(float(left+right)*.5/extent.x,float(bottom)/extent.y,float(ROLE_HEIGHTS[index])/maxf(.1,height),0))
	return registrations

## Registration aligns the fixed head/torso anchor and ground contact of each
## painted phase. It never splices limbs from separate paintings or stretches
## a crouch. Fractional source cells (for example 1254/4) are measured exactly.
static func _motion_registration(texture: Texture2D, measured_frames: PackedVector4Array = PackedVector4Array()) -> PackedVector4Array:
	var registrations := PackedVector4Array()
	if texture == null: return registrations
	var source := texture.get_image()
	for row in ATLAS_ROWS:
		for column in WALK_COLUMNS:
			var origin := Vector2i(roundi(float(column)*source.get_width()/WALK_COLUMNS), roundi(float(row)*source.get_height()/ATLAS_ROWS))
			var end := Vector2i(roundi(float(column+1)*source.get_width()/WALK_COLUMNS), roundi(float(row+1)*source.get_height()/ATLAS_ROWS))
			if not measured_frames.is_empty():
				var region:=measured_frames[row*WALK_COLUMNS+column]
				origin=Vector2i(roundi(region.x*source.get_width()-.5),roundi(region.y*source.get_height()-.5))
				end=origin+Vector2i(roundi(region.z*source.get_width()+1),roundi(region.w*source.get_height()+1))
			var extent := end-origin
			var head_x := 0.0; var head_samples := 0; var top := extent.y; var feet := 0
			for y in extent.y:
				for x in extent.x:
					if source.get_pixel(origin.x+x, origin.y+y).a < .5: continue
					top = mini(top,y); feet = maxi(feet,y)
					if y < extent.y*.25: head_x += float(x); head_samples += 1
			if not measured_frames.is_empty():
				head_x=0;head_samples=0
				for y in range(top,mini(feet+1,ceili(top+(feet-top)*.25))):
					for x in extent.x:
						if source.get_pixel(origin.x+x,origin.y+y).a<.5:continue
						head_x+=float(x);head_samples+=1
			var anchor := head_x/maxi(1,head_samples)/extent.x
			var height := float(feet-top)/extent.y
			registrations.append(Vector4(anchor,float(feet)/extent.y,.94/maxf(.1,height),0))
	return registrations

static func _male_layout(texture: Texture2D) -> PackedVector4Array:
	# The returned artwork has generous but slightly uneven gutters. These cuts
	# sit in inspected transparent gaps, preserving complete feet/head silhouettes.
	# Image files stay unchanged; only texture regions select the actual cells.
	var result:=PackedVector4Array()
	if texture==null:return result
	var x_edges:=[0,344,617,963,1254]
	var y_edges:=[0,354,637,920,1254]
	var dimensions:=Vector2(texture.get_width(),texture.get_height())
	for row in 4:
		for column in 4:
			var start:=(Vector2(x_edges[column],y_edges[row])*dimensions/1254.0).round()
			var end:=(Vector2(x_edges[column+1],y_edges[row+1])*dimensions/1254.0).round()
			var origin:=(start+Vector2.ONE*.5)/dimensions
			var extent:=(end-start-Vector2.ONE)/dimensions
			result.append(Vector4(origin.x,origin.y,extent.x,extent.y))
	return result

static func _grid_layout(texture: Texture2D, columns: int, rows: int = ATLAS_ROWS) -> PackedVector4Array:
	var frames := PackedVector4Array()
	if texture == null: return frames
	var dimensions := Vector2(texture.get_width(), texture.get_height())
	for row in rows:
		for column in columns:
			# Sample texel centres to prevent neighbouring cells bleeding through
			# minified alpha edges. Transparent RGB is never drawn as a backdrop.
			var start := (Vector2(column,row)*dimensions/Vector2(columns,rows)).round()
			var end := (Vector2(column+1,row+1)*dimensions/Vector2(columns,rows)).round()
			var origin := (start+Vector2.ONE*.5)/dimensions
			var extent := (end-start-Vector2.ONE)/dimensions
			frames.append(Vector4(origin.x, origin.y, extent.x, extent.y))
	return frames

static func painterly_shader_code() -> String:
	var fragment := Ink.PERSON.find("void fragment()")
	assert(fragment > 0, "Shared People vertex boundary changed")
	var vertex := Ink.PERSON.substr(0, fragment)
	# The private route renderer points local +Z along its actual travel. The
	# shared map uses -Z. Project +Z onto camera-right before mirroring the art;
	# all atlas figures face right, independent of gait phase or garment stage.
	assert(vertex.contains("vec4(0.0, 0.0, -1.0, 0.0)"), "Shared People facing boundary changed")
	vertex = vertex.replace("vec4(0.0, 0.0, -1.0, 0.0)", "vec4(0.0, 0.0, 1.0, 0.0)")
	vertex = vertex.replace("float child = step(1.5, INSTANCE_CUSTOM.z);", "float child = step(1.5, INSTANCE_CUSTOM.z)*(1.0-step(3.5, INSTANCE_CUSTOM.z));")
	vertex = vertex.replace("v_time = anim_clock*max(INSTANCE_CUSTOM.w, 0.2)+INSTANCE_CUSTOM.x*6.2831;", "v_time = motion_phase_supplied ? INSTANCE_CUSTOM.w+INSTANCE_CUSTOM.x : anim_clock*max(INSTANCE_CUSTOM.w, 0.2)+INSTANCE_CUSTOM.x*6.2831;")
	return Ink.HEAD.replace("depth_draw_never", "depth_prepass_alpha") + GARMENT_HELPERS + PAINTERLY_UNIFORMS + vertex + PAINTERLY_PAINT

const PAINTERLY_UNIFORMS := """
uniform sampler2D people_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 people_frames[24];
// The view may provide cumulative traveled distance / stride length in w.
// Pausing then keeps the feet still; x stays the stable clothing-supply sample.
uniform bool motion_phase_supplied = false;
uniform sampler2D walk_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 walk_frames[16];
uniform vec4 walk_registration[16];
uniform bool walk_atlas_ready = false;
uniform sampler2D carry_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 carry_frames[16];
uniform vec4 carry_registration[16];
uniform bool carry_atlas_ready = false;
uniform sampler2D male_walk_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 male_walk_frames[16];
uniform vec4 male_walk_registration[16];
uniform bool male_walk_atlas_ready = false;
uniform sampler2D male_carry_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 male_carry_frames[16];
uniform vec4 male_carry_registration[16];
uniform bool male_carry_atlas_ready = false;
uniform sampler2D role_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 role_frames[18];
uniform vec4 role_registration[18];
uniform bool role_atlas_ready = false;
"""

const PAINTERLY_PAINT := """
void fragment() {
    if (!map_people_visible) { discard; }
    vec2 p = vec2(v_p.x*v_flip, v_p.y);
    float pose = floor(mod(v_custom.y,100.0)+0.5);
    bool still = v_custom.y > 99.5;
    bool encoded = v_custom.z >= 3.5;
    int role = encoded ? clamp(int(floor(v_custom.z/4.0))-1,0,8) : -1;
    bool male = encoded && mod(floor(v_custom.z/2.0),2.0)>0.5;
    bool child = !encoded && v_custom.z > 1.5;
    bool carrying = mod(v_custom.z,2.0)>0.5 && !child;
    // The same stable per-person supply sample as the wrap shader: knowing a
    // method never outfits everybody, and missing issue records keep row zero.
    float sample_id = fract(v_custom.x*11.971+0.07);
    int row = sample_id < garment_supply ? int(clamp(garment_stage,0.0,3.0)+0.5) : 0;
    // Percentage representatives share a conservative material identity across
    // travel and work. They do not claim individual issued clothing inventory.
    if (encoded) { row = 0; }
    int frame = 0;
    bool walking = (pose < 0.5 || pose == 6.0) && !still;
    if (carrying) { frame = 3; }
    else if (pose == 4.0 || pose >= 8.0) { frame = 5; }
    // Without a recorded task target, standing is more truthful than air
    // punching. Crouching is a calm posture; no floating tool is synthesized.
    vec2 local_uv = vec2(p.x/1.85+0.5,1.0-p.y/1.85);
    vec4 paint = vec4(0.0);
    if (all(greaterThanEqual(local_uv,vec2(0.0))) && all(lessThanEqual(local_uv,vec2(1.0)))) {
        vec4 region = people_frames[row*6+frame];
        paint = texture(people_atlas,region.xy+local_uv*region.zw);
    }
    if (encoded && pose==20.0 && role_atlas_ready) {
            int activity = role*2+(male ? 1 : 0);
            vec4 region = role_frames[activity];
            vec4 registration = role_registration[activity];
            vec2 activity_uv = (local_uv-vec2(0.5,0.985))/registration.z+registration.xy;
            paint = texture(role_atlas,region.xy+clamp(activity_uv,vec2(0.0),vec2(1.0))*region.zw);
            if (any(lessThan(activity_uv,vec2(0.0))) || any(greaterThan(activity_uv,vec2(1.0)))) { paint = vec4(0.0); }
    } else if (male && carrying && male_carry_atlas_ready) {
            int stride_frame = int(mod(floor(v_time*4.0),4.0));
            if (!walking) { stride_frame = int(mod(floor(v_time*2.0+0.5)*2.0,4.0)); }
            vec4 region = male_carry_frames[row*4+stride_frame];
            vec4 registration = male_carry_registration[row*4+stride_frame];
            vec2 motion_uv = (local_uv-vec2(0.60,0.985))/registration.z+registration.xy;
            paint = texture(male_carry_atlas,region.xy+clamp(motion_uv,vec2(0.0),vec2(1.0))*region.zw);
            if (any(lessThan(motion_uv,vec2(0.0))) || any(greaterThan(motion_uv,vec2(1.0)))) { paint = vec4(0.0); }
    } else if (male && male_walk_atlas_ready) {
            int stride_frame = int(mod(floor(v_time*4.0),4.0));
            if (!walking) { stride_frame = int(mod(floor(v_time*2.0+0.5)*2.0,4.0)); }
            vec4 region = male_walk_frames[row*4+stride_frame];
            vec4 registration = male_walk_registration[row*4+stride_frame];
            vec2 motion_uv = (local_uv-vec2(0.60,0.985))/registration.z+registration.xy;
            paint = texture(male_walk_atlas,region.xy+clamp(motion_uv,vec2(0.0),vec2(1.0))*region.zw);
            if (any(lessThan(motion_uv,vec2(0.0))) || any(greaterThan(motion_uv,vec2(1.0)))) { paint = vec4(0.0); }
    } else if ((walking || encoded) && !carrying && walk_atlas_ready) {
            int stride_frame = int(mod(floor(v_time*4.0),4.0));
            if (!walking) { stride_frame = int(mod(floor(v_time*2.0+0.5)*2.0,4.0)); }
            vec4 stride_region = walk_frames[row*4+stride_frame];
            vec4 registration = walk_registration[row*4+stride_frame];
            vec2 motion_uv = (local_uv-vec2(0.60,0.985))/registration.z+registration.xy;
            paint = texture(walk_atlas,stride_region.xy+clamp(motion_uv,vec2(0.0),vec2(1.0))*stride_region.zw);
            if (any(lessThan(motion_uv,vec2(0.0))) || any(greaterThan(motion_uv,vec2(1.0)))) { paint = vec4(0.0); }
        } else if (carrying && carry_atlas_ready) {
            // A delivery pause freezes supplied distance phase. Settle into the
            // nearest planted-foot contact without changing body, clothes or load.
            int stride_frame = int(mod(floor(v_time*4.0),4.0));
            if (still) { stride_frame = int(mod(floor(v_time*2.0+0.5)*2.0,4.0)); }
            vec4 stride_region = carry_frames[row*4+stride_frame];
            vec4 registration = carry_registration[row*4+stride_frame];
            vec2 motion_uv = (local_uv-vec2(0.60,0.985))/registration.z+registration.xy;
            paint = texture(carry_atlas,stride_region.xy+clamp(motion_uv,vec2(0.0),vec2(1.0))*stride_region.zw);
            if (any(lessThan(motion_uv,vec2(0.0))) || any(greaterThan(motion_uv,vec2(1.0)))) { paint = vec4(0.0); }
    }
    float variation = mix(0.94,1.04,fract(v_custom.x*17.731+0.21));
    vec3 color = paint.rgb*variation;
    float alpha = paint.a;
    if (alpha < 0.03) { discard; }
    ALBEDO = color;
    ALPHA = alpha;
    ALPHA_SCISSOR_THRESHOLD = 0.03;
}
"""

const GARMENT_HELPERS := """
uniform float garment_stage = 0.0;
uniform float garment_supply = 1.0;
uniform bool garment_tied = false;
uniform bool garment_sewn = false;
uniform bool garment_layers = false;
uniform vec4 garment_light : source_color = vec4(0.59, 0.46, 0.32, 1.0);
uniform vec4 garment_dark : source_color = vec4(0.41, 0.32, 0.24, 1.0);

float cloth_side(vec2 a, vec2 b, vec2 p) {
    vec2 edge = b-a; vec2 q = p-a;
    return edge.x*q.y-edge.y*q.x;
}
// Clockwise convex cloth outline: an angular drape, not a rounded shirt body.
float cloth_panel(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d, vec2 e) {
    float edge = min(min(sd_seg(p,a,b,0.0),sd_seg(p,b,c,0.0)),
        min(sd_seg(p,c,d,0.0),min(sd_seg(p,d,e,0.0),sd_seg(p,e,a,0.0))));
    float side = max(max(cloth_side(a,b,p),cloth_side(b,c,p)),
        max(cloth_side(c,d,p),max(cloth_side(d,e,p),cloth_side(e,a,p))));
    return side <= 0.0 ? -edge : edge;
}
"""

const GARMENT_PAINT := """
    float variation = fract(v_custom.x*17.731+0.21);
    float supplied = step(fract(v_custom.x*11.971+0.07), garment_supply);
    float stage = garment_stage*supplied;
    bool woven = stage >= 1.5;
    bool fitted = stage >= 2.5;
    // Natural skin variation is independent of discovery and occupation.
    vec3 skin = mix(vec3(0.43,0.29,0.20),vec3(0.69,0.51,0.36),fract(v_custom.x*7.317+0.31));
    vec3 hide = mix(vec3(0.44,0.33,0.22),vec3(0.68,0.54,0.36),variation);
    vec3 cloth = woven ? mix(garment_dark.rgb,garment_light.rgb,variation) : hide;
    vec3 hair = mix(vec3(0.15,0.11,0.075),vec3(0.28,0.20,0.12),variation);
    vec2 q = rot2(p-hip,-bend);
    // Irregular lower edges and diagonal folds keep the early silhouette a
    // shoulder wrap; even later tunics cover the upper legs instead of pants.
    float hem = -0.32-0.09*variation;
    float rough = woven ? 0.0 : sin(q.x*41.0+variation*13.0)*0.012;
    vec2 cloth_p = q+vec2(0.0,rough);
    float cloth_shape = cloth_panel(cloth_p,vec2(-0.18,0.55),
        vec2(fitted ? 0.18 : 0.05,fitted ? 0.55 : 0.45),vec2(0.20,0.16),
        vec2(0.29,hem),vec2(-0.29,hem+(fitted ? 0.0 : 0.14)));
    vec4 acc = vec4(0.0);
    ground_shadow(acc,p,vec2(0.10,0.0),vec2(0.62,0.13),0.30);
    // Bare lower legs and forearms are visible. The footwrap stops at the
    // ankle; there is no full brown leg capsule that reads as trousers.
    ink_layer(acc,min(sd_seg(p,hip,knee_b,0.080),sd_seg(p,knee_b,foot_b,0.066)),skin*0.78,px);
    ink_layer(acc,sd_seg2(p,foot_b+vec2(-0.02,0.07),foot_b+vec2(0.085,0.005),0.07,0.08),hide*0.68,px);
    ink_layer(acc,sd_seg(p,shoulder,hand_b,0.065),skin*0.83,px);
    if (garment_layers && supplied > 0.5) {
        float cape = cloth_panel(q,vec2(-0.20,0.55),vec2(0.02,0.50),vec2(0.09,0.14),vec2(-0.27,-0.19),vec2(-0.36,-0.08));
        ink_layer(acc,cape,cloth*0.76,px);
    }
    ink_layer(acc,sd_seg(p,shoulder,mix(shoulder,hand_b,0.27),0.10),cloth*0.80,px);
    if (carry > 0.5) { ink_layer(acc,sd_circle(p,shoulder+up*(-0.08)+vec2(-0.26,0.0),0.24),vec3(0.51,0.40,0.25),px); }
    ink_layer(acc,min(sd_seg(p,hip,knee_f,0.085),sd_seg(p,knee_f,foot_f,0.071)),skin,px);
    ink_layer(acc,sd_seg2(p,foot_f+vec2(-0.02,0.07),foot_f+vec2(0.10,0.005),0.075,0.085),hide*0.76,px);
    ink_layer(acc,sd_seg(p,shoulder+up*0.06,head,0.060),skin,px);
    float fold = smoothstep(-0.10,0.10,q.x+q.y*0.28);
    ink_layer(acc,cloth_shape,cloth*(0.87+0.15*fold),px);
    // One diagonal overlap is visible on the wrap. A narrow cord is only
    // drawn after the actual binding method is known.
    if (cloth_shape < -px) {
        ink_layer(acc,sd_seg(q,vec2(-0.11,0.48),vec2(0.13,hem+0.08),0.008),cloth*0.69,px*0.65);
        if (garment_tied) { ink_layer(acc,sd_seg(q,vec2(-0.24,0.02),vec2(0.24,0.00),0.015),hide*0.61,px*0.65); }
        if (garment_sewn && supplied > 0.5) {
            float stitch = step(0.54,fract((q.y-hem)*17.0));
            if (stitch > 0.5) { ink_layer(acc,sd_seg(q,vec2(-0.20,hem+0.06),vec2(-0.14,0.35),0.006),cloth*0.58,px*0.55); }
        }
    }
    float head_r = 0.14*(1.0+0.28*child);
    ink_layer(acc,sd_circle(p,head,head_r),skin,px);
    ink_layer(acc,sd_circle(p,head+vec2(-0.05,0.05)*(1.0+0.28*child),0.105*(1.0+0.28*child)),hair,px);
    ink_layer(acc,sd_seg(p,shoulder,hand_f,0.065),skin,px);
    // The near shoulder is bare in the earliest wrap. Woven/structured
    // garments have a short draped sleeve, never a modern cuffed shirt.
    if (woven) { ink_layer(acc,sd_seg(p,shoulder,mix(shoulder,hand_f,fitted ? 0.34 : 0.21),0.096),cloth*0.93,px); }
"""
