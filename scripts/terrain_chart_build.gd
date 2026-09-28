extends RefCounted
## The terrain shader in two builds (codex/map-beauty): the painted land
## alone, and the painted land with its chart (map_chart.gdshaderinc). A view
## with no ground at chart scale draws with the lighter build: the chart's
## code, even never run, takes register space the close views need (about
## 0.4-0.8 ms a frame on a fast GPU, and more on a slower one). Every terrain
## material shares the two builds and keeps its parameters when it moves
## from one to the other. Both are compiled in the first frames (the terrain
## starts on the chart build and moves to the painted one if the view is
## close), so the first zoom out never waits for a compile.

## The switch in the terrain shader's code (local_terrain.gd).
const CHART_ON:="const bool MC_CHART_ON = true;"
const CHART_OFF:="const bool MC_CHART_ON = false;"
const INCLUDE:="res://scripts/map_chart.gdshaderinc"
## Beyond the view's own edge rays: the chart starts this much short of where
## the ground reaches it, and ends a little further, so a view never flips
## back and forth at the edge.
const ON_MARGIN:=0.85
const OFF_MARGIN:=0.75

## code hash -> [painted build, chart build]
static var _builds:Dictionary={}
static var _chart_from:=-1.0

## The shared build of this terrain shader code.
static func shader_for(code:String,chart:bool)->Shader:
	var key:=code.hash()
	if not _builds.has(key):
		var painted:=Shader.new()
		painted.code=code.replace(CHART_ON,CHART_OFF)
		var charted:=Shader.new()
		charted.code=code
		_builds[key]=[painted,charted]
	return (_builds[key] as Array)[1 if chart else 0]

## Where the chart starts, in km per design pixel (the include's MC_CHART_FROM).
static func chart_from()->float:
	if _chart_from<0.0:
		var found:=RegEx.create_from_string("const float MC_CHART_FROM = ([0-9.]+);").search(FileAccess.get_file_as_string(INCLUDE))
		_chart_from=float(found.get_string(1)) if found else 0.0102
	return _chart_from

## Km per design pixel (1/1080 of the view's height) at `distance` km from a
## camera with this vertical field of view: the shader's mc_design_km.
static func design_km(distance:float,fov_degrees:float)->float:
	return distance*2.0*tan(deg_to_rad(fov_degrees)*0.5)/1080.0

## Whether any ground in the view is drawn at chart scale: the farthest ground
## the view's edges reach, or the far plane where they miss it. `showing` is
## whether the chart build is in use now.
static func view_needs_chart(camera:Camera3D,viewport_size:Vector2,ground_y:float,showing:bool)->bool:
	var farthest:=0.0
	for corner:Vector2 in [Vector2.ZERO,Vector2(viewport_size.x,0.0),viewport_size,Vector2(0.0,viewport_size.y),Vector2(viewport_size.x*0.5,0.0)]:
		var direction:=camera.project_ray_normal(corner)
		var origin:=camera.project_ray_origin(corner)
		var distance:=camera.far
		if direction.y<-0.0001:distance=minf(camera.far,(ground_y-origin.y)/direction.y)
		farthest=maxf(farthest,distance)
	return design_km(farthest,camera.fov)>chart_from()*(OFF_MARGIN if showing else ON_MARGIN)

## Moves every terrain material among `materials` onto the build a view with
## (or without) chart needs. Materials of other shaders are left alone.
static func apply(materials:Array,chart:bool)->int:
	var moved:=0
	for material in materials:
		if not material is ShaderMaterial or (material as ShaderMaterial).shader==null:continue
		var current:Shader=(material as ShaderMaterial).shader
		for pair:Array in _builds.values():
			if current==pair[0] or current==pair[1]:
				var want:Shader=pair[1 if chart else 0]
				if current!=want:
					(material as ShaderMaterial).shader=want
					moved+=1
				break
	return moved
