// Calendar-driven vegetation dormancy, not a snowpack or rainfall simulation.
// Mean temperature and seasonal amplitude come from PlanetEnvironment. Latitude
// reverses the same annual phase as food production. No wall-clock TIME is used.
uniform float season_phase=0.0;
float landscape_temperature(float warmth,float amplitude,float latitude_z) {
	return mix(-6.0,28.0,warmth)+amplitude*season_phase*(latitude_z>0.0?-1.0:1.0);
}
vec3 seasonal_ground(vec3 base,float warmth,float rain,float amplitude,float latitude_z,float woodland) {
	if (amplitude<=0.0) { return base; }
	float temperature=landscape_temperature(warmth,amplitude,latitude_z);
	float dormant=1.0-smoothstep(2.0,13.0,temperature);
	// Bare desert stays bare, and humid tropical cover stays green year-round.
	float cover=smoothstep(0.20,0.55,rain);
	// Keep a green component in the woodland: species/deciduous share is not
	// simulated, so this is restrained seasonal cover rather than invented trees.
	float strength=dormant*cover*mix(0.82,0.60,woodland);
	float luma=dot(base,vec3(0.28,0.57,0.15));
	vec3 dry_stems=vec3(1.19,1.01,0.72)*luma;
	vec3 woodland_litter=vec3(1.25,0.99,0.70)*luma;
	return mix(base,mix(dry_stems,woodland_litter,woodland),strength);
}

// Terrain gets the same calendar authority as vegetation, plus a restrained
// cryosphere layer. This is visual snow/frost only: it does not invent water,
// alter fertility, or feed back into the simulation. Existing broad terrain
// fields supply the breakup so there is no extra unresolved noise cost.
vec3 seasonal_terrain(vec3 base,float warmth,float rain,float amplitude,float latitude_z,float woodland,float slope,float terrain_pattern) {
	vec3 dormant_ground=seasonal_ground(base,warmth,rain,amplitude,latitude_z,woodland);
	float temperature=landscape_temperature(warmth,amplitude,latitude_z);
	float cold=1.0-smoothstep(-1.5,3.5,temperature);
	float snow_supply=smoothstep(0.045,0.38,rain);
	float sheltered=1.0-smoothstep(0.18,0.58,slope);
	float drift=smoothstep(0.34,0.72,terrain_pattern);
	float snow=cold*snow_supply*sheltered*drift;
	// Very cold arid ground acquires pale frost, never a fictitious deep snowpack.
	float hard_frost=(1.0-smoothstep(-16.0,-8.0,temperature))*(1.0-snow_supply)*sheltered;
	float cover=clamp(snow*0.72+hard_frost*0.20*mix(0.45,1.0,drift),0.0,0.76);
	vec3 snow_colour=mix(vec3(0.66,0.69,0.68),vec3(0.82,0.84,0.82),drift);
	return mix(dormant_ground,snow_colour,cover);
}
