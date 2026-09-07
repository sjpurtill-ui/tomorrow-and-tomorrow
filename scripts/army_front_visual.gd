class_name ArmyFrontVisual
extends Node3D
## Aggregate occupied ground, in metres locally. Map callers use scale .001.
## No combat, random movement, casualty authority or extrapolated intelligence.
const MAX_SECTIONS := 24
const SAMPLES := 24
const TRANSITION_SECONDS := 0.35
var sections: Array[Dictionary] = []
var previous: Array[Dictionary] = []
var elapsed := TRANSITION_SECONDS
var tint := Color("67b4cf")
var surface_node: MeshInstance3D
var ground: Callable
var land: Callable
var signature := PackedByteArray()

static func area_of(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for i in polygon.size(): area += polygon[i].cross(polygon[(i+1)%polygon.size()])
	return absf(area)*0.5

static func active_count(force: Dictionary) -> int:
	if force.has("remaining_troops"): return maxi(0, int(force.remaining_troops))
	if force.has("troops"): return maxi(0, int(force.troops))
	var total := 0
	for formation in force.get("formations", []): total += maxi(0, int(formation.get("count", 0)))
	return total

static func combat_force(force: Dictionary, termination: Dictionary) -> Dictionary:
	var result:=force.duplicate(true)
	if not termination.is_empty() and String(termination.get("defeated",""))==String(force.get("name","?")):
		result["remaining_troops"]=maxi(0,active_count(force)-int(termination.get("prisoners",0)))
	return result

static func occupied_area(form: Dictionary) -> float:
	var count:=maxf(0,float(form.get("count",0)))
	var unit:=String(form.get("unit","unknown"))
	var extra:=20.0 if unit in ["armored_formation","field_artillery","modern_artillery","siege_engineer"] else (6.0 if unit in ["cavalry","motorized_infantry","mobile"] else 0.0)
	return count*4.0+minf(count,maxf(0,float(form.get("equipment",0))))*extra

static func layout(force: Dictionary, deployment: float = 1.0, facing: float = 0.0) -> Array[Dictionary]:
	var total := active_count(force)
	if total <= 0 or String(force.get("status", "")) in ["captured", "surrendered", "destroyed"]: return []
	var forms: Array = force.get("formations", []).duplicate(true)
	if forms.is_empty(): forms = [{"id": 0, "count": total, "unit": force.get("formation_role", "unknown")}]
	# Collapse overflow into one factual remainder instead of discarding personnel.
	if forms.size() > MAX_SECTIONS:
		var remainder := 0
		var remainder_area:=0.0
		for i in range(MAX_SECTIONS-1, forms.size()):
			remainder += maxi(0, int(forms[i].get("count",0)))
			remainder_area += occupied_area(forms[i])
		forms.resize(MAX_SECTIONS); forms[-1] = {"id": -2, "count": remainder, "unit": "mixed", "aggregate_area":remainder_area}
	var recorded_total := 0
	for form in forms: recorded_total += maxi(0, int(form.get("count",0)))
	if recorded_total <= 0: return []
	var strength_ratio := minf(1.0, float(total)/recorded_total)
	var result: Array[Dictionary] = []
	var cursor := 0.0
	var aspect := lerpf(0.45, 10.0, clampf(deployment,0,1))
	for index in forms.size():
		var form: Dictionary = forms[index]
		var count := float(maxi(0,int(form.get("count",0))))*strength_ratio
		if count <= 0: continue
		var unit := String(form.get("unit", "unknown"))
		var area := float(form.get("aggregate_area",occupied_area(form)))*strength_ratio
		var width := sqrt(area*aspect)
		var depth := area/width
		var center := Vector2(cursor+width*0.5, 0)
		# Exact spatial records are optional. Never manufacture flanks or POW sites.
		var spatial: Variant = form.get("deployment_position_m", Vector2.INF)
		var located: bool = spatial is Vector2 and spatial.is_finite()
		if located: center = spatial
		var angle := float(form.get("facing",facing))
		var curve := clampf(float(form.get("front_bend_m",0)), -width*0.3, width*0.3)
		var polygon := PackedVector2Array()
		for side in [1.0,-1.0]:
			for sample in SAMPLES+1:
				var t := float(sample if side>0 else SAMPLES-sample)/SAMPLES
				var half_depth := depth*0.5*sqrt(maxf(0,1-pow(2*t-1,2)))
				polygon.append(Vector2((t-0.5)*width, curve*(1-pow(2*t-1,2))+side*half_depth))
		var unique := PackedVector2Array()
		for point in polygon:
			if unique.is_empty() or not point.is_equal_approx(unique[-1]): unique.append(point)
		if unique.size()>1 and unique[0].is_equal_approx(unique[-1]): unique.remove_at(unique.size()-1)
		polygon = unique
		# Elliptical ends must not change the strength-to-area calibration.
		var correction := area/maxf(0.000001,area_of(polygon))
		for i in polygon.size():
			polygon[i].y *= correction
			polygon[i] = polygon[i].rotated(-angle) + center
		result.append({"id":str(form.get("id",index))+":"+str(index), "index":index, "center":center, "polygon":polygon, "area_m2":area, "count":count, "unit":unit, "located":located, "status":String(form.get("status",force.get("status","active")))})
		cursor += width + 0.5
	for section in result:
		if section.located: continue
		var offset := Vector2(-cursor*0.5,0).rotated(-facing)
		# Rotate the schematic row as one formation, including its centers.
		var shift: Vector2 = Vector2(section.center).rotated(-facing)-Vector2(section.center)+offset
		section.center += shift
		for i in section.polygon.size(): section.polygon[i] += shift
	return result

func configure(force: Dictionary, color: Color, deployment: float = 1.0, facing: float = 0.0, immediate: bool = false) -> void:
	var state := var_to_bytes([force,color,deployment,facing])
	if state == signature: return
	signature = state; tint = color
	previous = displayed_sections()
	sections = layout(force,deployment,facing)
	elapsed = TRANSITION_SECONDS if immediate or previous.is_empty() else 0.0
	redraw()

func displayed_sections() -> Array[Dictionary]:
	if elapsed >= TRANSITION_SECONDS: return sections.duplicate(true)
	var result := sections.duplicate(true)
	var weight := smoothstep(0,TRANSITION_SECONDS,elapsed)
	for target in result:
		for old in previous:
			if target.id != old.id or target.polygon.size() != old.polygon.size(): continue
			target.center = Vector2(old.center).lerp(target.center,weight)
			for i in target.polygon.size(): target.polygon[i] = Vector2(old.polygon[i]).lerp(target.polygon[i],weight)
			break
	return result

func advance(delta: float, paused: bool = false) -> void:
	if paused or elapsed >= TRANSITION_SECONDS: return
	elapsed = minf(TRANSITION_SECONDS,elapsed+maxf(0,delta)); redraw()

func redraw() -> void:
	if surface_node == null:
		surface_node = MeshInstance3D.new(); surface_node.name = "PhysicalFront"
		var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		surface_node.material_override = mat; add_child(surface_node)
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := 0
	for section in displayed_sections():
		var polygon: PackedVector2Array = section.polygon
		var indices := Geometry2D.triangulate_polygon(polygon)
		for i in range(0,indices.size(),3):
			var a := polygon[indices[i]]; var b := polygon[indices[i+1]]; var c := polygon[indices[i+2]]
			if land.is_valid() and (not land.call(a) or not land.call(b) or not land.call(c) or not land.call((a+b+c)/3.0)): continue
			for point in [a,b,c]:
				surface.set_color(tint.darkened(0.20) if section.status in ["withdrawing","retreating","reserve","regrouping"] else tint)
				surface.add_vertex(Vector3(point.x,float(ground.call(point)) if ground.is_valid() else 0.05,point.y))
			triangles += 1
	surface_node.mesh = surface.commit() if triangles > 0 else null
	surface_node.set_meta("triangle_count",triangles)
