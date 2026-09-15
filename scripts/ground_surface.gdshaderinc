// Surface appearance follows the physical climate and geological family carried
// by the mesh. Fine grain is cosmetic; it never adds relief or resource deposits.
vec3 geological_rock(vec2 point,vec2 origin,float height,float pixel_world,vec2 geology) {
	float sediment = geology.x;
	float igneous = geology.y;
	float metamorphic = max(0.0,1.0-sediment-igneous);
	vec3 rock = vec3(0.43,0.375,0.29)*sediment + vec3(0.235,0.255,0.25)*igneous + vec3(0.34,0.35,0.335)*metamorphic;
	float regional_grain = 1.0-smoothstep(0.03,0.45,pixel_world);
	if (regional_grain>0.0) {
		rock *= 0.98+(precise_surface_noise(point,origin,17,10,vec2(0.0))-0.5)*0.13*regional_grain;
	} else {
		rock *= 0.98;
	}
	float resolved = 1.0-smoothstep(0.0008,0.004,pixel_world);
	float grain = 0.0;
	if (resolved>0.0) {
		grain = precise_surface_noise(point,origin,180,1,vec2(0.0))*0.09 + precise_surface_noise(point,origin,67,1,vec2(0.0))*0.10;
	}
	// Broad bedding on an exposed face responds to actual elevation. It is a
	// material pattern, not a claim that bedding orientation is simulated.
	float band_detail = 1.0-smoothstep(0.0007,0.0035,pixel_world);
	float bedding = 0.0;
	if (band_detail>0.0 && sediment>0.0) {
		bedding = sin(height*280.0+precise_surface_noise(point,origin,34,1,vec2(0.0))*4.0);
	}
	return rock*(0.93+grain*resolved+bedding*sediment*0.05*band_detail);
}

vec3 apply_climate_surface(vec3 earth,vec2 point,vec2 origin,float pixel_world,float forest_mask,vec4 fields) {
	if (fields.x<0.999) { return earth; }
	float rain = clamp(fields.x-1.0,0.0,1.0);
	float warm = clamp(fields.y,0.0,1.0);
	float dry = 1.0-smoothstep(0.22,0.48,rain);
	float cold = 1.0-smoothstep(0.13,0.27,warm);
	float fine = 1.0-smoothstep(0.0008,0.0025,pixel_world);
	float grain = 0.0;
	if (fine>0.0) {
		grain = (precise_surface_noise(point,origin,110,1,vec2(0.0))-0.5)*0.11*fine;
	}
	float soil_detail = 1.0-smoothstep(0.02,0.10,pixel_world);
	float soil_mass = 0.5;
	if (soil_detail>0.0) {
		soil_mass = precise_surface_noise(point,origin,5,1,vec2(0.0))*0.5+precise_surface_noise(point,origin,17,1,vec2(0.0))*0.5;
	}
	vec3 soil = mix(vec3(0.365,0.29,0.18),vec3(0.51,0.445,0.32),fields.z);
	soil = mix(soil,vec3(0.31,0.32,0.30),cold*0.72);
	soil *= 0.96+(soil_mass-0.5)*0.22*soil_detail+grain;
	// Do not turn wet grassland or existing woodland into a decorative desert.
	earth = mix(earth,soil,dry*(1.0-forest_mask)*0.62);
	float damp = smoothstep(0.62,0.88,rain)*(1.0-forest_mask);
	earth *= 1.0-damp*0.10;
	return earth;
}
