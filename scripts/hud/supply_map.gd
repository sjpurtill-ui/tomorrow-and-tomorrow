extends Node
## THE SUPPLY MAP: HOI4's supply view, drawn as an inked campaign chart.
## A toggle beside World on the map toolbar. When on, at the regional and
## continental views:
##   - the known land is washed by how well a band would be fed there (the
##     supply model's own numbers, supply_state.grid): sap green fed, ochre
##     short of food, oxblood hatched starving, with fine ink where one
##     gives way to the next (hud/supply_wash.gdshader);
##   - our roads in heavy ink; home, our towns and the towns we hold ringed
##     as hubs; the carts' reach dotted round them; each band's supply line
##     back to its hub, heavy on roads and dashed across country;
##   - every band and garrison carries a sack and a bar: its share of a
##     day's food, in the colour of its state; a pointer on it, a hub or
##     the land gives the numbers in plain words (hud/supply_chart.gd).
## Known land only. The work (the supply field, the day's grid, the wash's
## mesh, the lines) runs on worker threads, once a day or when the world
## changes. With the map off, this node only keeps the supply field ready
## for the day's rations while forces are out. Observe-only.

const Supply:=preload("res://scripts/supply_state.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const Chart:=preload("res://scripts/hud/supply_chart.gd")
const Stroke:=preload("res://scripts/scout_chart_stroke.gd")
const Index:=preload("res://scripts/scout_chart_index.gd")
const March:=preload("res://scripts/march_terrain.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

const NODE_NAME:="SupplyMap"
## Seconds between looks at the world (the field, the day, the forces).
const LOOK_EVERY:=0.4
## The wash shows from this view width (km) and is full from this one.
const WASH_FROM_KM:=30.0
const WASH_FULL_KM:=100.0
## Turned on closer in than this, the view pulls out to the region.
const CLOSE_KM:=40.0
const REGION_LEVEL:=2
## The wash sits this far above the ground's own height (km).
const LIFT:=0.002

var terrain:Node
var enabled:=false
var wash:MeshInstance3D
var wash_material:ShaderMaterial
var chart:Control
var key_card:Control
var _layers:Array[CanvasLayer]=[]
var _look:=LOOK_EVERY
var _job:PaintJob=null
var _painted_key:=0
## Counters for probes (never saved).
var paints:=0
var paint_ms:=0.0


# --- The toolbar's toggle ----------------------------------------------------

static func find(t:Node)->Node:
	return t.get_node_or_null(NODE_NAME) if is_instance_valid(t) else null

static func ensure(t:Node)->Node:
	var node:=find(t)
	if node==null and is_instance_valid(t) and t.is_inside_tree():
		node=load("res://scripts/hud/supply_map.gd").new()
		node.name=NODE_NAME
		node.set("terrain",t)
		t.add_child(node)
	return node

## THE ONE WAY to show or hide the supply map from anywhere (a screen's
## "Show supply on the map", a test): the toolbar's Supply button follows.
##   preload("res://scripts/hud/supply_map.gd").set_shown(terrain,true)
static func set_shown(t:Node,on:=true)->void:
	if not is_instance_valid(t): return
	var hud:Variant=t.get("hud")
	var button:Button=(hud as Node).find_child("ToolbarSupply",true,false) as Button if hud is Node and is_instance_valid(hud) else null
	if button!=null:
		if button.button_pressed!=on: button.button_pressed=on
		return
	var node:=ensure(t)
	if node!=null: node.call("set_enabled",on)

## Whether the supply map is showing.
static func is_shown(t:Node)->bool:
	var node:=find(t)
	return node!=null and bool(node.get("enabled"))

## The Supply toggle for the map toolbar (command_rail_hud._build_toolbar).
static func toggle_button(t:Node)->Button:
	var button:=Button.new()
	button.name="ToolbarSupply"
	button.text="Supply"
	button.toggle_mode=true
	button.icon=Chart.sack_texture("",40)
	button.add_theme_constant_override("icon_max_width",20)
	button.add_theme_constant_override("h_separation",6)
	button.custom_minimum_size=Vector2(0,32)
	button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",Tokens.BODY)
	button.add_theme_color_override("font_pressed_color",Tokens.GOLD_TEXT)
	button.add_theme_color_override("font_hover_pressed_color",Tokens.GOLD_TEXT)
	button.add_theme_stylebox_override("normal",Tokens.action_button_style(false))
	button.add_theme_stylebox_override("hover",Tokens.action_button_style(false,true))
	button.add_theme_stylebox_override("pressed",Tokens.action_button_style(true))
	button.add_theme_stylebox_override("hover_pressed",Tokens.action_button_style(true,true))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.tooltip_text="Where our fighters can be fed: green fed, ochre short of food, red starving. Our supply lines, and how far the carts reach."
	button.toggled.connect(func(on:bool)->void:
		var node:=ensure(t)
		if node!=null: node.call("set_enabled",on))
	# Keeps the supply field ready for the day's rations from the start.
	if is_instance_valid(t): (func()->void: ensure(t)).call_deferred()
	return button


# --- Life ------------------------------------------------------------------------

func _exit_tree()->void:
	_discard_paint()
	Supply.shutdown()

func set_enabled(on:bool)->void:
	enabled=on
	if on:
		_build_visuals()
		var camera:Variant=terrain.get("camera")
		if is_instance_valid(camera) and float(camera.size)<CLOSE_KM and terrain.has_method("set_camera_distance_level"): terrain.set_camera_distance_level(REGION_LEVEL)
		_painted_key=0
		_look=LOOK_EVERY
	for layer in _layers: layer.visible=on
	if is_instance_valid(wash): wash.visible=on
	# Off, the chart neither watches the pointer nor redraws.
	if is_instance_valid(chart): chart.set_process(on)
	if is_instance_valid(key_card) and not on: key_card.call("show_tip",{},Vector2.ZERO)

func _build_visuals()->void:
	if is_instance_valid(wash): return
	wash=MeshInstance3D.new(); wash.name="SupplyWash"
	wash_material=ShaderMaterial.new()
	wash_material.shader=preload("res://scripts/hud/supply_wash.gdshader")
	# Over the chart and the fields' drapes, under the scouts' ink and marks.
	wash_material.render_priority=6
	wash.material_override=wash_material
	wash.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wash)
	# Ink beneath the city labels (layer 0), with the war's own marks.
	var ink_layer:=CanvasLayer.new(); ink_layer.name="SupplyInk"; ink_layer.layer=-1; add_child(ink_layer)
	chart=Chart.new(); chart.name="SupplyChart"; chart.set("terrain",terrain); ink_layer.add_child(chart)
	var key_layer:=CanvasLayer.new(); key_layer.name="SupplyKey"; key_layer.layer=4; add_child(key_layer)
	key_card=Chart.KeyCard.new(); key_card.name="SupplyKeyCard"; key_layer.add_child(key_card)
	chart.set("key_card",key_card)
	_layers=[ink_layer,key_layer]

func _process(delta:float)->void:
	_look+=delta
	if _look>=LOOK_EVERY:
		_look=0.0
		_look_at_world()
	if not enabled: return
	# Under the world view nothing of the chart shows.
	var covered:=is_instance_valid(terrain.get("world_globe")) if is_instance_valid(terrain) else false
	for layer in _layers: layer.visible=not covered
	_poll_paint()
	var camera:Variant=terrain.get("camera") if is_instance_valid(terrain) else null
	if is_instance_valid(camera) and wash_material!=null:
		wash_material.set_shader_parameter("fade",smoothstep(WASH_FROM_KM,WASH_FULL_KM,float(camera.size)))

func _look_at_world()->void:
	var mc:Variant=WorldSimulation.military
	var busy:=mc!=null and (not (mc.field_armies as Array).is_empty() or not (mc.occupation_forces as Array).is_empty())
	if not enabled and not busy: return
	# Keeps a worker building the field the world wants (the rations read it).
	var f:=Supply.field()
	if not enabled or f.is_empty() or _job!=null: return
	var forces:=_forces()
	var key:=_paint_key(f,forces)
	if key!=_painted_key: _start_paint(f,forces,key)


# --- The day's paint (worker) -------------------------------------------------

## Our bands out and garrisons: {id, pos, report} with the day's report.
func _forces()->Array:
	var out:Array=[]
	var mc:Variant=WorldSimulation.military
	if mc==null: return out
	for a in mc.field_armies:
		if not a is Dictionary or int((a as Dictionary).get("troops",0))<=0 or bool(mc._army_is_home(a)): continue
		# The army bar's one supply rule: a band away before signals stands
		# where its last runner left it, as fed as he said (no mark until one
		# has come); the army bar and the Military screen read the same.
		var known:=BarModel.known_supply(mc,a)
		var p:Vector2=known.get("position",Vector2.INF) if not known.is_empty() else Vector2.INF
		if p.is_finite(): out.append({"id":"army:%d" % int(a.get("army_id",0)),"pos":p,"report":known,"route":Supply.route_to(Supply.field(),p)})
	for g in mc.occupation_forces:
		if not g is Dictionary or int((g as Dictionary).get("troops",0))<=0: continue
		var p:=Supply.force_pos(g)
		if p.is_finite(): out.append({"id":"held:"+String(g.get("region_id","")),"pos":p,"report":Supply.of_force(g),"route":Supply.route_to(Supply.field(),p)})
	return out

func _paint_key(f:Dictionary,forces:Array)->int:
	var world:Variant=WorldSimulation.world
	var d:=Supply.day_inputs()
	var rows:Array=[]
	for force:Dictionary in forces: rows.append([String(force.id),(force.pos as Vector2).snapped(Vector2.ONE*0.5),snappedf(float((force.report as Dictionary).get("ratio",0.0)),0.01)])
	return hash([int(f.get("key",0)),int(d.day),Supply.typical_troops(),snappedf(float(d.transport),0.01),snappedf(float(d.stores),0.01),snappedf(float(d.siege),0.01),snappedf(float(d.get("endurance",0.0)),0.001),
		int(world.fog_revision) if world!=null else 0,(world.revealed_areas as Array).size() if world!=null else 0,rows,hash(March.roads().map(func(r:Dictionary)->Array: return [r.a,r.b,r.tier]))])

func _start_paint(f:Dictionary,forces:Array,key:int)->void:
	var job:=PaintJob.new()
	job.field=f; job.key=key; job.forces=forces
	job.troops=Supply.typical_troops()
	job.inputs=Supply.day_inputs()
	job.areas=(WorldSimulation.world.revealed_areas as Array).duplicate(true) if WorldSimulation.world!=null else []
	job.roads=March.roads().duplicate(true)
	job.model=load("res://scripts/supply_state.gd")
	job.reach_level=Supply.REACH_HAUL
	job.task=WorkerThreadPool.add_task(job.run,false,"Supply map")
	_job=job

func _poll_paint()->void:
	if _job==null or not WorkerThreadPool.is_task_completed(_job.task): return
	WorkerThreadPool.wait_for_task_completion(_job.task)
	var done:=_job
	_job=null
	if done.result.is_empty(): return
	_commit(done)

func _discard_paint()->void:
	if _job==null: return
	_job.cancel[0]=true
	WorkerThreadPool.wait_for_task_completion(_job.task)
	_job=null

func _commit(done:PaintJob)->void:
	var r:Dictionary=done.result
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=r.vertices; arrays[Mesh.ARRAY_TEX_UV]=r.uvs; arrays[Mesh.ARRAY_INDEX]=r.indices
	var mesh:=ArrayMesh.new()
	if (r.indices as PackedInt32Array).size()>0: mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.custom_aabb=AABB(Vector3((r.aabb as Rect2).position.x,-2.0,(r.aabb as Rect2).position.y),Vector3((r.aabb as Rect2).size.x,20.0,(r.aabb as Rect2).size.y))
	wash.mesh=mesh
	var texels:=int(r.texels)
	var grid:=Image.create_from_data(texels,texels,false,Image.FORMAT_RGBA8,r.grid_bytes)
	wash_material.set_shader_parameter("supply_grid",ImageTexture.create_from_image(grid))
	wash_material.set_shader_parameter("grid_texels",float(texels))
	chart.call("set_data",{"routes":r.routes,"reach":r.reach,"hubs":r.hubs,"marks":r.marks,"roads":r.roads,"troops":done.troops})
	key_card.call("set_troops",done.troops)
	_painted_key=done.key
	paints+=1
	paint_ms=float(r.get("ms",0.0))


## One day's chart, built on a worker thread from copies and the field
## (which nothing changes once built): the known land, the grid, the wash's
## mesh, the carts' reach and the supply lines.
class PaintJob:
	var field:Dictionary
	var key:=0
	var troops:=30
	var inputs:Dictionary
	var areas:Array
	var roads:Array
	var forces:Array
	var model:GDScript
	var reach_level:=0.5
	var cancel:=[false]
	var result:Dictionary={}
	var task:=-1
	const DX:=[1,-1,0,0,1,-1,1,-1]
	const DY:=[0,0,1,-1,1,1,-1,-1]

	func run()->void:
		var began:=Time.get_ticks_usec()
		var f:=field
		var nx:=int(f.nx); var ny:=int(f.ny); var n:=nx*ny
		var cell:=float(f.cell); var origin:Vector2=f.origin
		var ground:Dictionary=f.ground
		var land:PackedByteArray=ground.land
		var h:PackedFloat32Array=ground.h
		# The land our people know (the same chart CivilizationSystem keeps).
		var index_script=load("res://scripts/scout_chart_index.gd")
		var stroke=load("res://scripts/scout_chart_stroke.gd")
		var index=index_script.new(areas)
		var known:=PackedByteArray(); known.resize(n)
		for i in n:
			if land[i]==1 and index.contains(origin+Vector2(float(i%nx),float(i/nx))*cell): known[i]=1
		if bool(cancel[0]): return
		var grid:Dictionary=model.call("grid",f,troops,inputs,known,cancel)
		if grid.is_empty(): return
		var ratio:PackedFloat32Array=grid.ratio
		var haul:PackedFloat32Array=grid.haul
		# Beyond the known edge and over water the values carry on from the
		# known land, so the wash's lines never follow the fog's edge.
		var fill_r:=ratio.duplicate(); var fill_h:=haul.duplicate()
		var have:=known.duplicate()
		for pass_index in 3:
			var next_have:=have.duplicate()
			for y in ny:
				for x in nx:
					var i:=y*nx+x
					if have[i]==1: continue
					var sr:=0.0; var sh:=0.0; var c:=0
					for k in 8:
						var xx:=x+int(DX[k]); var yy:=y+int(DY[k])
						if xx<0 or yy<0 or xx>=nx or yy>=ny: continue
						var j:=yy*nx+xx
						if have[j]==1: sr+=fill_r[j]; sh+=fill_h[j]; c+=1
					if c>0: fill_r[i]=sr/float(c); fill_h[i]=sh/float(c); next_have[i]=1
			have=next_have
		for i in n:
			if have[i]==0: fill_r[i]=0.6; fill_h[i]=0.5
		# The grid for the wash's shader: a texel a node (ratio, haul, known).
		var grid_bytes:=PackedByteArray(); grid_bytes.resize(n*4)
		for i in n:
			grid_bytes[i*4]=clampi(roundi(clampf(fill_r[i],0.0,1.0)*255.0),0,255)
			grid_bytes[i*4+1]=clampi(roundi(clampf(fill_h[i],0.0,1.0)*255.0),0,255)
			grid_bytes[i*4+2]=255 if known[i]==1 else 0
			grid_bytes[i*4+3]=255
		# The wash's mesh, draped: every node, and the cells near known land.
		var vertices:=PackedVector3Array(); vertices.resize(n)
		var uvs:=PackedVector2Array(); uvs.resize(n)
		for i in n:
			var p:=origin+Vector2(float(i%nx),float(i/nx))*cell
			vertices[i]=Vector3(p.x,maxf(0.0,h[i])+0.002,p.y)
			uvs[i]=Vector2((float(i%nx)+0.5)/float(nx),(float(i/nx)+0.5)/float(ny))
		var near:=known.duplicate()
		for y in ny:
			for x in nx:
				if known[y*nx+x]==0: continue
				for oy in range(-1,2):
					for ox in range(-1,2):
						var xx:=x+ox; var yy:=y+oy
						if xx>=0 and yy>=0 and xx<nx and yy<ny: near[yy*nx+xx]=1
		var indices:=PackedInt32Array()
		for y in ny-1:
			for x in nx-1:
				var a:=y*nx+x; var b:=a+1; var c2:=a+nx; var d:=c2+1
				if near[a]+near[b]+near[c2]+near[d]==0: continue
				indices.append_array([a,c2,b,b,c2,d])
		if bool(cancel[0]): return
		# The carts' reach: where half a carried load still arrives.
		var reach:=_contours(haul,known,nx,ny,origin,cell,reach_level)
		var reach_lines:Array=[]
		for line:PackedVector2Array in reach:
			var smooth:PackedVector2Array=stroke.smooth(line,cell*0.35,cell*0.2)
			reach_lines.append({"points":smooth,"heights":_heights(f,smooth)})
		# Each force's supply line, along the field.
		var routes:Array=[]
		var marks:Array=[]
		for force:Dictionary in forces:
			var report:Dictionary=force.report
			marks.append({"id":String(force.id),"pos":force.pos,"h":_height_at(f,force.pos),"report":report})
			var raw:PackedVector2Array=force.get("route",PackedVector2Array())
			if raw.size()<2: continue
			var smooth:PackedVector2Array=stroke.smooth(raw,cell*0.4,cell*0.25)
			var road:=PackedByteArray(); road.resize(smooth.size())
			var tiers:PackedInt32Array=f.road
			for k in smooth.size():
				var q:=smooth[k]
				var qx:=clampi(roundi((q.x-origin.x)/cell),0,nx-1); var qy:=clampi(roundi((q.y-origin.y)/cell),0,ny-1)
				road[k]=1 if tiers[qy*nx+qx]>=0 else 0
			routes.append({"id":String(force.id),"points":smooth,"heights":_heights(f,smooth),"road":road,"state":String(report.get("state","well"))})
		var hubs:Array=[]
		for s:Dictionary in f.sources: hubs.append({"pos":s.pos,"h":_height_at(f,s.pos),"kind":String(s.kind),"name":String(s.name)})
		var road_rows:Array=[]
		for r:Dictionary in roads: road_rows.append({"a":r.a,"b":r.b,"tier":int(r.tier),"ha":_height_at(f,r.a),"hb":_height_at(f,r.b)})
		result={"vertices":vertices,"uvs":uvs,"indices":indices,"grid_bytes":grid_bytes,"texels":nx,"aabb":Rect2(origin,Vector2(float(nx-1),float(ny-1))*cell),
			"reach":reach_lines,"routes":routes,"marks":marks,"hubs":hubs,"roads":road_rows,"ms":float(Time.get_ticks_usec()-began)/1000.0}

	func _height_at(f:Dictionary,p:Vector2)->float:
		var v:float=model.call("_bilinear_any",f,(f.ground as Dictionary).h,p)
		return maxf(0.0,v) if is_finite(v) else 0.0

	func _heights(f:Dictionary,points:PackedVector2Array)->PackedFloat32Array:
		var out:=PackedFloat32Array()
		for p in points: out.append(_height_at(f,p))
		return out

	## Marching squares for `level` over the known land, joined into lines.
	func _contours(values:PackedFloat32Array,known:PackedByteArray,nx:int,ny:int,origin:Vector2,cell:float,level:float)->Array:
		var segments:Array=[]
		for y in ny-1:
			for x in nx-1:
				var ids:=[y*nx+x,y*nx+x+1,(y+1)*nx+x+1,(y+1)*nx+x]
				if known[ids[0]]==0 or known[ids[1]]==0 or known[ids[2]]==0 or known[ids[3]]==0: continue
				var v:=[values[ids[0]],values[ids[1]],values[ids[2]],values[ids[3]]]
				var corners:=[Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]
				var crossings:Array=[]
				for e in 4:
					var a:float=v[e]; var b:float=v[(e+1)%4]
					if (a>=level)!=(b>=level):
						var t:=(level-a)/(b-a)
						crossings.append(origin+(corners[e] as Vector2).lerp(corners[(e+1)%4],t)*cell)
				if crossings.size()==2: segments.append([crossings[0],crossings[1]])
				elif crossings.size()==4: segments.append([crossings[0],crossings[1]]); segments.append([crossings[2],crossings[3]])
		# Join the pieces end to end.
		var ends:={}
		for k in segments.size():
			for side in 2:
				var q:Vector2=(segments[k][side] as Vector2).snapped(Vector2.ONE*0.001)
				if not ends.has(q): ends[q]=[]
				(ends[q] as Array).append(k)
		var used:=PackedByteArray(); used.resize(segments.size())
		var lines:Array=[]
		for k in segments.size():
			if used[k]==1: continue
			used[k]=1
			var line:=PackedVector2Array([segments[k][0],segments[k][1]])
			for direction in 2:
				var guard:=0
				while guard<100000:
					guard+=1
					var tail:=(line[line.size()-1] if direction==0 else line[0]).snapped(Vector2.ONE*0.001)
					var next:=-1
					for m in ends.get(tail,[]):
						if used[m]==0: next=m; break
					if next<0: break
					used[next]=1
					var a:Vector2=segments[next][0]; var b:Vector2=segments[next][1]
					var far:=b if a.snapped(Vector2.ONE*0.001)==tail else a
					if direction==0: line.append(far)
					else: line.insert(0,far)
			if line.size()>=3: lines.append(line)
		return lines
