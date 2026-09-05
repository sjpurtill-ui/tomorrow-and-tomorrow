shader_type spatial;
render_mode cull_disabled;

uniform sampler2D position_frames : filter_nearest, repeat_disable;
uniform sampler2D normal_frames : filter_nearest, repeat_disable;
uniform float texture_height;
uniform float rows_per_frame;
uniform float frame_start;
uniform float frame_count;
uniform float clip_duration = 2.0;
uniform float animation_clock = 0.0;
uniform bool looping = true;
uniform float death_frame_start = 31.0;
uniform float death_frame_count = 21.0;
uniform float casualty_clock = 0.0;
uniform vec4 faction_color : source_color = vec4(0.25, 0.65, 0.8, 1.0);

uniform vec2 battle_idle;
uniform vec2 battle_walk;
uniform vec2 battle_attack;

void vertex() {
	bool fallen = INSTANCE_CUSTOM.z > 0.5;
	float active_start = fallen ? death_frame_start : frame_start;
	float active_count = fallen ? death_frame_count : frame_count;
	float progress = animation_clock / max(clip_duration, 0.01);
	if (fallen) progress = clamp((casualty_clock - INSTANCE_CUSTOM.y) / 2.5, 0.0, 1.0);
	else if (looping) progress = fract(progress + INSTANCE_CUSTOM.x);
	else progress = clamp(progress - INSTANCE_CUSTOM.x * 0.06, 0.0, 1.0);
	if (!fallen) {
        vec2 clip = INSTANCE_CUSTOM.w > 2.5 ? battle_attack : (INSTANCE_CUSTOM.w > 1.5 ? battle_walk : (INSTANCE_CUSTOM.w > .5 ? battle_attack : battle_idle));
        active_start = clip.x; active_count = clip.y;
        progress = INSTANCE_CUSTOM.w > 2.5 ? .22 : INSTANCE_CUSTOM.x;
    }
    bool active_loop = false;
	float frame = progress * (active_loop ? active_count : active_count - 1.0);
	float first = floor(frame);
	float second = active_loop ? mod(first + 1.0, active_count) : min(first + 1.0, active_count - 1.0);
	vec2 a = vec2(UV2.x, (UV2.y + (active_start + first) * rows_per_frame) / texture_height);
	vec2 b = vec2(UV2.x, (UV2.y + (active_start + second) * rows_per_frame) / texture_height);
	VERTEX = mix(texture(position_frames, a).xyz, texture(position_frames, b).xyz, fract(frame));
	NORMAL = normalize(mix(texture(normal_frames, a).xyz, texture(normal_frames, b).xyz, fract(frame)));
}

void fragment() {
	ALBEDO = mix(COLOR.rgb, faction_color.rgb, UV.x);
	ROUGHNESS = 0.85;
}
