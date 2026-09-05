shader_type spatial;
varying vec3 ground_position;
uniform sampler2D ground_texture : source_color, filter_linear_mipmap, repeat_enable;
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p){
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex(){ ground_position=VERTEX; }
void fragment(){
 vec3 grain=texture(ground_texture,ground_position.xz*.025).rgb;
 float luminance=dot(grain,vec3(.299,.587,.114));
 float patches=noise(ground_position.xz*.09)*.65+noise(ground_position.xz*.31)*.35;
 ALBEDO=mix(COLOR.rgb,COLOR.rgb*vec3(1.13,1.02,.77),patches*.32)*(.87+luminance*.32);
 ROUGHNESS=.96;
}
