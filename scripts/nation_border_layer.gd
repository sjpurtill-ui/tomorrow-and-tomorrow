extends Node3D
## THE NATION BORDERS ON THE MAP (nation_borders.gd): each people's land
## washed in its colour, and the inked lines where peoples meet, over a grid
## five views wide about the camera.
##
## Rebuilt on a worker thread only when what it draws changes: a claim (a
## town founded, or grown by about 2%), what a people knows, a war or hot
## feud, ground charted inside a stranger's land, or the view's zoom step or
## a pan past the grid's margin. Never per frame or per day. Between builds a
## frame costs two uniform writes and, while the pointer moves over the map,
## the hover test. local_terrain hands it our towns' claims each time the
## settlement network redraws; everything else it reads itself.
## Observe-only: nothing here changes the world.

const Borders:=preload("res://scripts/nation_borders.gd")
const Sampler:=preload("res://scripts/terrain_patch_sampler.gd")
const Stroke:=preload("res://scripts/scout_chart_stroke.gd")

const NODE_NAME:="NationBorders"
## Seconds between looks at the view, and at the world (claims, knowledge, wars).
const LOOK_EVERY:=0.1
const WORLD_EVERY:=0.5
## Over the chart and the fields, under the route ink (13+), labels and marks.
const WASH_PRIORITY:=1
const INK_PRIORITIES:=[6,7,8]
const INK_NAMES:=["NationBorderWar","NationBorderTint","NationBorderInk"]
## Strangers' towns this far past the grid's side are still read (their claim
## can reach into it), km.
const FOREIGN_MARGIN_KM:=900.0
## The height cache holds at most this many lattice nodes.
const HEIGHT_CACHE_LIMIT:=300000
## Hover: points kept per line, and how near the pointer must come (px).
const HOVER_POINTS:=40
const HOVER_PX:=7.0

var terrain:Node
var wash:MeshInstance3D
var wash_material:ShaderMaterial
var inks:Array[MeshInstance3D]=[]
var ink_materials:Array[ShaderMaterial]=[]
var hover_layer:CanvasLayer
var hover:Control
## Our towns' claims (set_own_claims) and others' as we know them.
var own:Array=[]
var own_key:=0
var foreign:Array=[]
var world_key:=0
var enemies:Dictionary={}
## The committed lines for hover: [{owners, kind, war, points3, box, words}].
var lines:Array=[]
var owners:=PackedStringArray()
var _job:Job=null
var _wanted:=0
var _look:=LOOK_EVERY
var _world_look:=WORLD_EVERY
var _sampler:RefCounted
var _sampler_key:=0
var _heights:Dictionary={}
var _heights_seed:=-1
var _fog_revision:=-1
var _fog_count:=0
var _fog_key:=0
var _wash_fade:=-1.0
var _ink_fade:=-1.0
var _ground_grid:=Vector4.ZERO
var _coast_key:=0
## Counters for probes and tests (never saved).
var builds:=0
var commits:=0
var last_ms:=0.0


## One build on a worker thread, from copies.
class Job extends RefCounted:
	var input:Dictionary
	var key:=0
	var owners:=PackedStringArray()
	var cancel:=[false]
	var result:Dictionary={}
	var task:=-1
	func run()->void:
		result=load("res://scripts/nation_borders.gd").compose(input,cancel)


func _ready()->void:
	name=NODE_NAME
	wash=MeshInstance3D.new()
	wash.name="NationWash"
	wash_material=ShaderMaterial.new()
	wash_material.shader=preload("res://scripts/nation_border_wash.gdshader")
	wash_material.render_priority=WASH_PRIORITY
	wash.material_override=wash_material
	wash.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wash)
	for k in 3:
		var ink:=MeshInstance3D.new()
		ink.name=INK_NAMES[k]
		var material:=ShaderMaterial.new()
		material.shader=preload("res://scripts/nation_border_ink.gdshader")
		material.render_priority=INK_PRIORITIES[k]
		ink.material_override=material
		ink.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ink)
		inks.append(ink)
		ink_materials.append(material)
	# Beneath the city cards' layer order like the war marks; the tip is small.
	hover_layer=CanvasLayer.new()
	hover_layer.name="NationBorderHover"
	hover_layer.layer=0
	add_child(hover_layer)
	hover=Hover.new()
	hover.name="NationBorderWords"
	hover.set("borders",self)
	hover_layer.add_child(hover)


func _exit_tree()->void:
	if _job!=null:
		_job.cancel[0]=true
		WorkerThreadPool.wait_for_task_completion(_job.task)
		_job=null


## Our towns' claims, each time the settlement network redraws (local_terrain).
func set_own_claims(settlements:Array)->void:
	var claims:=Borders.own_claims(settlements)
	own=claims
	own_key=Borders.claims_key(claims)


func _camera()->Camera3D:
	if not is_instance_valid(terrain): return null
	var camera:Variant=terrain.get("camera")
	return camera if is_instance_valid(camera) and camera is Camera3D and (camera as Camera3D).is_inside_tree() else null


func _target()->Vector2:
	var target:Variant=terrain.get("camera_target") if is_instance_valid(terrain) else null
	return Vector2((target as Vector3).x,(target as Vector3).z) if target is Vector3 else Vector2.ZERO


func _process(delta:float)->void:
	var camera:=_camera()
	# Under the world view nothing of the chart shows.
	var shown:=camera!=null and not is_instance_valid(terrain.get("world_globe"))
	visible=shown
	hover_layer.visible=shown
	if not shown: return
	_poll()
	_fade(camera.size)
	_look+=delta
	if _look<LOOK_EVERY: return
	_look=0.0
	_bind_ground()
	_world_look+=LOOK_EVERY
	if _world_look>=WORLD_EVERY:
		_world_look=0.0
		_read_world(camera.size)
	var grid:=Borders.grid_for(_target(),camera.size)
	var key:=hash([grid.key,own_key,world_key])
	if key!=_wanted and _job==null: _start(grid,key)


## Others' claims, what every people knows, wars and charted ground: the
## world's part of the rebuild key.
func _read_world(view_km:float)->void:
	var grid:=Borders.grid_for(_target(),view_km)
	var box:Rect2=grid.box
	foreign=Borders.foreign_claims(box.get_center(),box.size.x*0.75+FOREIGN_MARGIN_KM)
	var people:Array=["player"]
	for claim:Dictionary in foreign:
		if not people.has(String(claim.owner)): people.append(String(claim.owner))
	var looks:Array=[]
	for owner in people:
		var style:=Borders.style(String(owner))
		looks.append([owner,int(style.stage),bool(style.firm)])
	enemies=Borders.hot_enemies()
	_watch_charted_ground()
	world_key=hash([Borders.claims_key(foreign),looks,enemies,_fog_key,int(GameState.world_seed)])


## Charted ground changes the drawing only inside a stranger's land: a scout
## walking anywhere else, or our own ground, redraws nothing.
func _watch_charted_ground()->void:
	var world:Node=CivilizationSystem
	var revision:=int(world.fog_revision)
	if revision==_fog_revision: return
	var areas:Array=world.revealed_areas
	var touched:=areas.size()<_fog_count
	if not touched:
		var boxes:Array[Rect2]=[]
		for claim:Dictionary in foreign:
			var reach:=float(claim.radius)
			boxes.append(Rect2((claim.center as Vector2)-Vector2.ONE*reach,Vector2.ONE*reach*2.0))
		for index in range(maxi(0,_fog_count-1),areas.size()):
			if _record_touches(areas[index],boxes): touched=true;break
	if touched: _fog_key+=1
	_fog_revision=revision
	_fog_count=areas.size()


static func _record_box(record:Dictionary)->Rect2:
	var reach:=maxf(0.0,float(record.get("radius",0.0)))
	var box:=Rect2(Vector2(float(record.get("x",0.0)),float(record.get("z",0.0))),Vector2.ZERO)
	if String(record.get("kind","circle"))=="trail":
		for point_variant in record.get("points",[]):
			if point_variant is Dictionary: box=box.expand(Vector2(float(point_variant.get("x",0.0)),float(point_variant.get("z",0.0))))
	return box.grow(reach)


static func _record_touches(record_variant:Variant,boxes:Array[Rect2])->bool:
	if not record_variant is Dictionary or boxes.is_empty(): return false
	var box:=_record_box(record_variant)
	for claim_box in boxes:
		if claim_box.intersects(box): return true
	return false


func _start(grid:Dictionary,key:int)->void:
	var box:Rect2=grid.box
	var claims:Array=[]
	var people:=PackedStringArray(["player"])
	for claim:Dictionary in own+foreign:
		if not box.grow(float(claim.radius)).has_point(claim.center): continue
		var owner:=String(claim.owner)
		var index:=people.find(owner)
		if index<0:
			people.append(owner)
			index=people.size()-1
		var copy:=claim.duplicate()
		copy["owner_index"]=index
		claims.append(copy)
	_wanted=key
	if claims.is_empty():
		_clear(people)
		return
	var styles:Array=[]
	var any_foreign:=false
	for owner in people:
		styles.append(Borders.style(owner))
		any_foreign=any_foreign or owner!="player"
	var war:Dictionary={}
	for civ_id in enemies:
		var index:=people.find(String(civ_id))
		if index>=0: war[index]=String(enemies[civ_id])
	var seed_value:=int(GameState.world_seed)
	if seed_value!=_heights_seed or _heights.size()>HEIGHT_CACHE_LIMIT:
		_heights={}
		_heights_seed=seed_value
	var job:=Job.new()
	job.key=key
	job.owners=people
	job.input={"origin":grid.origin,"cell":grid.cell,"n":grid.n,"level":grid.level,"view_km":grid.view_km,
		"claims":claims,"styles":styles,"war":war,"player":0,
		"revealed":_charted_near(box) if any_foreign else [],
		"sampler":_terrain_sampler(),"height_cache":_heights,"lift":0.0,"known_fade":float(grid.cell)*0.6}
	job.task=WorkerThreadPool.add_task(job.run,false,"Nation borders")
	_job=job
	builds+=1


## Charted ground near the grid, deep-copied for the worker (a scout's trail
## grows in place on the main thread).
func _charted_near(box:Rect2)->Array:
	var out:Array=[]
	for record_variant in CivilizationSystem.revealed_areas:
		if record_variant is Dictionary and _record_box(record_variant).intersects(box): out.append((record_variant as Dictionary).duplicate(true))
	return out


## The terrain's own height chain, fused for any thread (terrain_patch_sampler).
func _terrain_sampler()->RefCounted:
	if not is_instance_valid(terrain) or terrain.get("continent_noise")==null or terrain.get("mountain_relief")==null: return null
	var key:=hash([terrain.get_instance_id(),int(GameState.world_seed)])
	if _sampler==null or key!=_sampler_key:
		_sampler=Sampler.from_terrain(terrain)
		_sampler_key=key
	return _sampler


func _poll()->void:
	if _job==null or not WorkerThreadPool.is_task_completed(_job.task): return
	WorkerThreadPool.wait_for_task_completion(_job.task)
	var done:=_job
	_job=null
	if done.result.is_empty():
		_wanted=0
		return
	_commit(done)


func _commit(done:Job)->void:
	var result:Dictionary=done.result
	wash.mesh=_wash_mesh(result.wash_vertices,result.wash_colors)
	var ink:Array=result.ink
	for k in inks.size(): inks[k].mesh=(ink[k] as Stroke.Ink).commit()
	owners=done.owners
	lines=[]
	for line:Dictionary in result.lines:
		if String(line.get("kind",""))=="" and String(line.get("war",""))=="": continue
		var points:PackedVector2Array=line.points
		var ground:PackedFloat32Array=line.heights
		var stride:=maxi(1,ceili(float(points.size())/float(HOVER_POINTS)))
		var points3:=PackedVector3Array()
		var box:=Rect2(points[0],Vector2.ZERO)
		for i in range(0,points.size(),stride):
			points3.append(Vector3(points[i].x,ground[i],points[i].y))
		points3.append(Vector3(points[points.size()-1].x,ground[ground.size()-1],points[points.size()-1].y))
		for point in points: box=box.expand(point)
		lines.append({"owners":[owners[int(line.a)],owners[int(line.b)]],"kind":String(line.kind),"war":String(line.war),"points3":points3,"box":box,"words":""})
	Borders.publish(result.lines,owners)
	commits+=1
	last_ms=float(result.get("ms",0.0))


func _clear(people:PackedStringArray)->void:
	wash.mesh=null
	for ink in inks: ink.mesh=null
	lines=[]
	owners=people
	Borders.publish([],people)
	commits+=1


static func _wash_mesh(vertices:PackedVector3Array,colors:PackedColorArray)->ArrayMesh:
	var mesh:=ArrayMesh.new()
	if vertices.is_empty(): return mesh
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh


## The zoom's strength, written only when it moves.
func _fade(view_km:float)->void:
	var wash_strength:=Borders.wash_fade(view_km)
	if absf(wash_strength-_wash_fade)>0.004:
		_wash_fade=wash_strength
		wash_material.set_shader_parameter("fade",wash_strength)
	var ink_strength:=Borders.ink_fade(view_km)
	if absf(ink_strength-_ink_fade)>0.004:
		_ink_fade=ink_strength
		for material in ink_materials: material.set_shader_parameter("fade",ink_strength)


## The wash reads the terrain's own shore: the streamed patch's heights and
## the macro rasters, bound again only when the terrain replaces them.
func _bind_ground()->void:
	var grid:Variant=terrain.get("river_terrain_grid")
	if grid is Vector4 and grid!=_ground_grid and terrain.has_method("_bind_river_terrain"):
		_ground_grid=grid
		terrain.call("_bind_river_terrain",wash_material)
	var coast:Variant=terrain.get("coast_mask_bindings")
	if coast is Dictionary and terrain.has_method("_bind_coast_mask"):
		var key:=hash([(coast as Dictionary).size(),(coast as Dictionary).get("coast_grid0"),(coast as Dictionary).get("coast_grid1")])
		if key!=_coast_key:
			_coast_key=key
			terrain.call("_bind_coast_mask",wash_material)


## The words for the border under `mouse`, or "".
func words_at(mouse:Vector2,camera:Camera3D)->String:
	var reach:=camera.size*4.0
	var view:=Rect2(_target()-Vector2.ONE*reach,Vector2.ONE*reach*2.0)
	var best:=HOVER_PX
	var found:Dictionary={}
	for line:Dictionary in lines:
		if not (line.box as Rect2).intersects(view): continue
		var previous:=Vector2.INF
		for point:Vector3 in (line.points3 as PackedVector3Array):
			if camera.is_position_behind(point):
				previous=Vector2.INF
				continue
			var screen:=camera.unproject_position(point)
			if previous.is_finite():
				var distance:=Geometry2D.get_closest_point_to_segment(mouse,previous,screen).distance_to(mouse)
				if distance<best:
					best=distance
					found=line
			previous=screen
	if found.is_empty(): return ""
	if String(found.words)=="": found.words=Borders.words_for(found.owners,String(found.kind),String(found.war))
	return String(found.words)


## Whose border is under the pointer, in a few words, in a small paper tip.
class Hover extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const SIZE:=13
	var borders:Node
	var shown:=""
	var at:=Vector2.ZERO
	var _tested:=0
	var _since:=0.0

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta:float)->void:
		_since+=delta
		if _since<0.05: return
		_since=0.0
		var camera:Camera3D=borders.call("_camera") if is_instance_valid(borders) else null
		if camera==null or not is_visible_in_tree():
			_show("")
			return
		var mouse:=get_local_mouse_position()
		var key:=hash([mouse.round(),camera.global_transform,camera.size,int(borders.get("commits"))])
		if key==_tested: return
		_tested=key
		var text:=""
		if get_viewport().gui_get_hovered_control()==null: text=String(borders.call("words_at",mouse,camera))
		at=mouse
		_show(text)

	func _show(text:String)->void:
		if text==shown and text=="": return
		shown=text
		queue_redraw()

	func _draw()->void:
		if shown=="": return
		var font:=ThemeDB.fallback_font
		var text_size:=font.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,SIZE)
		var box_size:=text_size+Vector2(20,14)
		var origin:=at+Vector2(14,18)
		origin.x=clampf(origin.x,8,maxf(8,size.x-box_size.x-8))
		origin.y=clampf(origin.y,8,maxf(8,size.y-box_size.y-8))
		draw_style_box(T.flat(T.MAP_LABEL_BG,T.BORDER_SOFT,1,4,0),Rect2(origin,box_size))
		draw_string(font,origin+Vector2(10,7+font.get_ascent(SIZE)),shown,HORIZONTAL_ALIGNMENT_LEFT,-1,SIZE,T.INK)
