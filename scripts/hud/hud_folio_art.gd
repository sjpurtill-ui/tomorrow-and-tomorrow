extends RefCounted
## Approved engraved folio artwork. Regions reference the unchanged source PNGs.
const ROOT:="res://assets/ui/hud_folio/"
const ALIASES:={"population":"overview","economy":"food","science":"inquiry"}
static var _regions:Dictionary={}
static var _atlases:Dictionary={}
static var _textures:Dictionary={}
static var _night:ShaderMaterial

static func texture(id:String)->AtlasTexture:
	id=String(ALIASES.get(id,id))
	if _textures.has(id):return _textures[id]
	if _regions.is_empty():
		var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"regions.json"))
		if data is Dictionary:_regions=data
	if not _regions.has(id):return null
	var spec:Dictionary=_regions[id]
	var path:String=ROOT+String(spec.atlas)
	if not _atlases.has(path):
		if not ResourceLoader.exists(path):return null
		_atlases[path]=load(path) as Texture2D
	var result:=AtlasTexture.new()
	result.atlas=_atlases[path]
	var r:Array=spec.rect
	result.region=Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
	result.filter_clip=true
	_textures[id]=result
	return result

static func night_material()->ShaderMaterial:
	if _night:return _night
	var shader:=Shader.new()
	# Reverse the neutral ink/paper in night mode; retain the original gold.
	# Texture alpha and the original engraved lines remain intact.
	shader.code="""shader_type canvas_item;
varying vec4 modulation;
void vertex() { modulation = COLOR; }
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float lightness = dot(sample_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	float gold = smoothstep(0.05, 0.18, sample_color.r - sample_color.b)
		* (1.0 - smoothstep(0.66, 0.88, lightness));
	vec3 reversed = mix(vec3(0.87, 0.80, 0.65), vec3(0.08, 0.11, 0.11),
		smoothstep(0.10, 0.86, lightness));
	COLOR = modulation * vec4(mix(reversed, sample_color.rgb, gold), sample_color.a);
}"""
	_night=ShaderMaterial.new()
	_night.shader=shader
	return _night
