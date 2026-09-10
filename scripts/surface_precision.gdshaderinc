// Work in a nearby coordinate frame, retaining the exact world phase of each
// repeating texture. Integer rational scales avoid losing the fractional UV
// when multiplying a 20,000 km origin by a metres-scale texture frequency.
vec2 periodic_surface_uv(vec2 point,vec2 origin,int numerator,int denominator,bool rotated,vec2 offset) {
	ivec2 remainder=(ivec2(origin)%ivec2(denominator))*ivec2(numerator%denominator)%ivec2(denominator);
	vec2 uv=point*(float(numerator)/float(denominator))+vec2(remainder)/float(denominator);
	return (rotated?vec2(-uv.y,uv.x):uv)+offset;
}

// Noise keeps its global cell identity while interpolating only a small local
// fraction. These material scales stay well within signed integer range.
float precise_surface_noise(vec2 point,vec2 origin,int numerator,int denominator,vec2 offset) {
	ivec2 product=ivec2(origin)*ivec2(numerator);
	ivec2 base=product/ivec2(denominator);
	vec2 p=point*(float(numerator)/float(denominator))+vec2(product%ivec2(denominator))/float(denominator)+offset;
	vec2 i=vec2(base)+floor(p);
	vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1.0,0.0)),f.x),mix(hash21(i+vec2(0.0,1.0)),hash21(i+vec2(1.0)),f.x),f.y);
}
