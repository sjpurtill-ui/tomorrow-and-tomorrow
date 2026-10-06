extends RefCounted
## A few surveyor's strokes where a retained country record already stands.
## Physical roofs keep their metre scale; this is the chart's field/wood/cut ink.
## Like scout_chart_ink, vertices hold a draped world anchor and UV2 holds the
## stroke offsets. The shader sizes those offsets without rebuilding any mesh.
const TARGET_PIXELS:=14.0
const MAX_DIAMETER_KM:=4.0
const MAX_STROKES:=18
const INK:=Color("#78613e")
const WOOD_INK:=Color("#626647")
const STONE_INK:=Color("#706957")
const PAPER:=Color(0.87,0.82,0.69,0.30)
static var _material:ShaderMaterial

static func create(record:Dictionary,height:Callable)->Node3D:
	var motif:=motif_for(record)
	var point:Variant=record.get("position")
	if motif.is_empty() or not (point is Vector2 or point is Vector3) or not height.is_valid():return null
	var at:=Vector2(point.x,point.z) if point is Vector3 else Vector2(point)
	if not at.is_finite():return null
	var anchor:=Vector3(at.x,float(height.call(at))+0.0002,at.y)
	var lines:=_lines(motif)
	var ink:=WOOD_INK if motif in ["wood","cut_wood","young_wood"] else (STONE_INK if motif in ["quarry","mineral"] else INK)
	ink.a=0.76 if String(record.get("category",""))=="depleted" else 0.92
	var angle:=float(record.get("rotation",0.0))
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A thin paper keyline, as on existing chart ink; never a backing disc.
	for line:Array in lines:_stroke(surface,anchor,line[0].rotated(angle),line[1].rotated(angle),0.11,PAPER)
	for line:Array in lines:_stroke(surface,anchor,line[0].rotated(angle),line[1].rotated(angle),0.07,ink)
	var node:=MeshInstance3D.new()
	node.name="CountryChart_"+motif
	node.mesh=surface.commit()
	if _material==null:
		_material=ShaderMaterial.new()
		_material.shader=preload("res://scripts/shaders/settlement_country_chart.gdshader")
	node.material_override=_material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Shader expansion must not be culled as the degenerate anchor mesh. Every
	# rotated stroke fits in a disc of radius2km, including its thin keyline.
	node.custom_aabb=AABB(anchor-Vector3(2.0,0.01,2.0),Vector3(4.0,0.02,4.0))
	# Match the existing scout stroke's mesh bounds as well as the instance;
	# its unexpanded vertices all share the anchor before the vertex shader.
	node.mesh.custom_aabb=node.custom_aabb
	node.set_meta("country_chart_motif",motif)
	node.set_meta("country_chart_record",String(record.get("id","")))
	node.set_meta("country_chart_strokes",lines.size())
	return node

## Mirrors the shader's screen-size bound for probes; the 4km world cap wins
## when the view is too wide to keep fourteen pixels without enlarging the mark.
static func diameter_for(span:float,viewport_height:float=1080.0)->float:
	return minf(MAX_DIAMETER_KM,maxf(0.0,span)/maxf(1.0,viewport_height)*TARGET_PIXELS)

static func motif_for(record:Dictionary)->String:
	var group:=String(record.get("group",record.get("kind","")))
	if group in ["homesteads","homestead"]:return "field"
	if group in ["herders","herder"]:return "pasture"
	if group not in ["sites","site"]:return ""
	var source:=String(record.get("landscape_source",""))
	var resource:=String(record.get("resource",""))
	var age:=String(record.get("age",""))
	var category:=String(record.get("category",""))
	if source=="woodland_catchment" or resource=="Timber" or "wood" in age:
		if category=="depleted":return "cut_wood"
		return "young_wood" if category=="regrowing" else "wood"
	if source=="surface_stone_catchment" or resource in ["Stone","Limestone"] or "quarry" in age:return "quarry"
	if source=="plant_fiber_catchment" or resource in ["Fiber Plants","Plant Fiber"]:return "fiber"
	return "mineral"

static func _lines(motif:String)->Array:
	var lines:Array=[]
	match motif:
		"field","fiber":
			# Unequal field strips, open at their ends, with a single worn headland.
			for i in 4:
				var y:=-0.27+float(i)*0.18
				lines.append([Vector2(-0.36+float(i%2)*0.03,y),Vector2(0.32-float(i%3)*0.04,y+0.045)])
			if motif=="field":lines.append([Vector2(-0.43,-0.34),Vector2(-0.40,0.34)])
			else:
				for i in 3:
					var x:=-0.23+float(i)*0.22
					lines.append([Vector2(x,0.29),Vector2(x+0.055,0.39)])
		"pasture":
			for point in [Vector2(-0.25,0.13),Vector2(0.02,-0.18),Vector2(0.28,0.16)]:
				lines.append([point+Vector2(-0.11,-0.07),point])
				lines.append([point,point+Vector2(0.07,-0.12)])
			lines.append([Vector2(-0.38,0.34),Vector2(0.26,0.31)])
		"wood","young_wood":
			for point in [Vector2(-0.24,0.17),Vector2(0.04,-0.17),Vector2(0.28,0.20)]:
				lines.append([point+Vector2(0,0.13),point+Vector2(0,-0.14)])
				lines.append([point+Vector2(-0.105,-0.015),point+Vector2(0,-0.14)])
				lines.append([point+Vector2(0,-0.14),point+Vector2(0.105,-0.015)])
				if motif=="wood":lines.append([point+Vector2(-0.12,0.055),point+Vector2(0.12,0.055)])
		"cut_wood":
			for i in 3:
				var y:=-0.25+float(i)*0.24
				lines.append([Vector2(-0.30,y),Vector2(0.30,y+0.08)])
				lines.append([Vector2(-0.23,y-0.07),Vector2(-0.26,y+0.07)])
		"quarry":
			for i in 3:
				var inset:=float(i)*0.14
				lines.append([Vector2(-0.38+inset,0.29),Vector2(-0.34+inset,-0.28+inset)])
				lines.append([Vector2(-0.34+inset,-0.28+inset),Vector2(0.25,-0.34+inset)])
				lines.append([Vector2(0.25,-0.34+inset),Vector2(0.38,-0.15+inset)])
		"mineral":
			lines.append_array([
				[Vector2(-0.38,0.27),Vector2(-0.29,-0.23)],
				[Vector2(-0.29,-0.23),Vector2(0.15,-0.34)],
				[Vector2(0.15,-0.34),Vector2(0.37,0.10)],
				[Vector2(0.37,0.10),Vector2(0.09,0.29)],
				[Vector2(-0.18,0.01),Vector2(0.14,0.08)],
				[Vector2(-0.11,0.15),Vector2(0.12,0.19)]])
	assert(lines.size()<=MAX_STROKES)
	return lines

static func _stroke(surface:SurfaceTool,anchor:Vector3,a:Vector2,b:Vector2,half_width:float,color:Color)->void:
	var direction:=(b-a).normalized()
	var side:=direction.orthogonal()*half_width
	var corners:=[a-side,a+side,b+side,b-side]
	# The palette above is authored in sRGB; spatial ALBEDO is linear, like
	# the existing resource glyph atlas's source_color texture.
	var linear_ink:=color.srgb_to_linear()
	for i in [0,1,2,0,2,3]:
		surface.set_color(linear_ink)
		surface.set_normal(Vector3.UP)
		surface.set_uv(Vector2(0.0 if i<2 else 1.0,-1.0 if i in [0,3] else 1.0))
		# Includes the keyline and every rotation within the shader's diameter.
		surface.set_uv2(corners[i]*0.78)
		surface.add_vertex(anchor)
