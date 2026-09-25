// Calendar-driven vegetation dormancy, not a snowpack or rainfall simulation.
// Mean temperature and seasonal amplitude come from PlanetEnvironment. Latitude
// reverses the same annual phase as food production. No wall-clock TIME is used.
uniform float season_phase=0.0;
// living_map.gd sets these from the same calendar: season_turn is the year's
// direction (warming > 0 in spring, cooling < 0 in autumn) and season_contrast
// turns on the visible seasonal cues below. At zero the look is unchanged.
uniform float season_turn=0.0;
uniform float season_contrast=0.0;
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
	vec3 ground=mix(base,mix(dry_stems,woodland_litter,woodland),strength);
	if (season_contrast<=0.0) { return ground; }
	float hemisphere=latitude_z>0.0?-1.0:1.0;
	float warm_half=season_phase*hemisphere;      // +summer, -winter
	float turn=season_turn*hemisphere;            // +spring, -autumn
	// The cool half-year even where winters are mild: broadleaf crowns thin
	// to bare grey-brown and open grass goes tawny.
	float cool=clamp(-warm_half*1.5,0.0,1.0);
	float canopy_rest=woodland*cover*(1.0-smoothstep(7.0,16.0,temperature))*cool*0.45;
	float grass_rest=(1.0-woodland)*cover*(1.0-smoothstep(8.0,17.0,temperature))*cool*0.32;
	ground=mix(ground,vec3(1.06,0.93,0.78)*luma*1.08,canopy_rest*season_contrast);
	ground=mix(ground,dry_stems*1.04,grass_rest*season_contrast);
	// Autumn: cooling woodland turns russet before it rests.
	float autumn=woodland*cover*smoothstep(0.2,0.8,-turn)*smoothstep(3.0,9.0,temperature)*(1.0-smoothstep(17.0,23.0,temperature))*0.45;
	ground=mix(ground,vec3(1.50,0.95,0.50)*luma*1.12,autumn*season_contrast);
	// Spring flush: warming, mild country greens before full summer.
	float mild=smoothstep(4.0,10.0,temperature)*(1.0-smoothstep(20.0,27.0,temperature));
	float flush=smoothstep(0.2,0.8,turn)*mild*cover*0.50;
	ground=mix(ground,ground*vec3(0.84,1.26,0.70),flush*season_contrast);
	// High summer on open, drier ground: grass cures to straw. Deep woodland
	// and wet country stay green.
	float heat=smoothstep(15.0,24.0,temperature)*clamp(warm_half*1.5,0.0,1.0);
	float dryness=1.0-smoothstep(0.40,0.80,rain);
	float cured=heat*dryness*(1.0-woodland*0.75)*smoothstep(0.08,0.30,rain)*0.60;
	float g_luma=dot(ground,vec3(0.28,0.57,0.15));
	ground=mix(ground,vec3(1.30,1.10,0.66)*g_luma,cured*season_contrast);
	return ground;
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
	// A thin dusting also reaches open, sheltered ground between the drifts,
	// so a snowy winter reads at settlement scale, not only on the uplands.
	float dusting=cold*snow_supply*sheltered*(1.0-woodland*0.6)*0.36*season_contrast;
	float cover=clamp(max(snow*0.72,dusting)+hard_frost*0.20*mix(0.45,1.0,drift),0.0,0.76);
	vec3 snow_colour=mix(vec3(0.66,0.69,0.68),vec3(0.82,0.84,0.82),drift);
	return mix(dormant_ground,snow_colour,cover);
}
