extends RefCounted
## THE WATCHED BORDER ON THE CHART (fort_border.gd): our border inked along
## its own outline, each run as strongly as it is kept. A tight stretch is a
## heavy, unbroken plum line; a thin one a fine line; open ground, and forts
## with too few to man them, a faint dotted trace. Each fort stands on it in
## its kind's own chart mark (resource_icons.gd _fort_glyph), half pencilled
## while going up; the god places, moves and breaks them down in the map's
## Border mode (hud/border_map.gd). Built by local_terrain.gd (_refresh_border_watch) with
## its chart ink, so it keeps its width on screen at every zoom.

const Forts:=preload("res://scripts/fort_border.gd")
const Stroke:=preload("res://scripts/scout_chart_stroke.gd")
## Our colour (nation_borders.gd PLAYER_COLOR), the ink of our own line.
const PLUM:=Color("#7b2a7a")
## Strength runs drawn as one class (a run changes ink only between classes).
const CLASSES:=[0.15,0.4,0.7]
## A point of the outline over water: not inked.
const WATER:=-1.0

## What the chart needs, from the ledger: {points: PackedVector2Array along
## the outline, strengths: per point, forts: [{at, status, manned, kind}]}.
## Pure data; key() decides whether to rebuild.
static func data()->Dictionary:
	var shape:=Forts.outline()
	var kept:=Forts.watch()
	var strengths:=PackedFloat32Array()
	# Over water the border is not drawn (WATER), as the land wash is cut at the shore.
	var land:Callable=Callable(WorldSimulation.world,"_scout_land_at") if WorldSimulation.world!=null and WorldSimulation.world.scout_land_authority.is_valid() else Callable()
	for point:Vector2 in (shape.points as PackedVector2Array):
		if land.is_valid() and not bool(land.call(point)):strengths.append(WATER);continue
		strengths.append(float(Forts.at(point,null,kept).strength))
	var marks:=[]
	for f:Dictionary in Forts.forts():
		if String(f.get("status",""))=="abandoned":continue
		var need:=maxf(1.0,float(Forts.kind(String(f.kind)).get("garrison",1)))
		marks.append({"at":Forts._pos(f),"status":String(f.status),"manned":float(kept.garrisons.get(int(f.id),0))/need,"name":String(f.get("name","")),"kind":String(f.kind)})
	return {"points":shape.points,"strengths":strengths,"forts":marks}

## What the drawing depends on, coarsely: redraw only when it changes.
static func key(d:Dictionary,zoom_octave:int)->int:
	var classes:=PackedInt32Array()
	for value:float in (d.strengths as PackedFloat32Array):classes.append(_class(value))
	var rounded:=PackedVector2Array()
	for p:Vector2 in (d.points as PackedVector2Array):rounded.append(p.snapped(Vector2.ONE*0.5))
	return hash([rounded,classes,var_to_str(d.forts),zoom_octave])

static func _class(strength:float)->int:
	if strength<0.0:return -1
	var c:=0
	for edge:float in CLASSES:
		if strength>=edge:c+=1
	return c

## The chart node for `terrain` (local_terrain.gd), from data().
static func build(terrain:Node,d:Dictionary)->Node3D:
	var root:=Node3D.new();root.name="BorderWatch"
	var zoom:float=terrain.camera.size if terrain.camera else 320.0
	var profile:Dictionary=terrain._scout_route_visual_profile(zoom)
	var points:PackedVector2Array=d.points
	var strengths:PackedFloat32Array=d.strengths
	if points.size()>=3:
		# Runs of one strength class, closed round the outline.
		var n:=points.size()
		var start:=0
		for i in n:
			if _class(strengths[i])!=_class(strengths[(i-1+n)%n]):start=i;break
		var run:=PackedVector2Array();var run_class:=_class(strengths[start])
		var runs:=[]
		for j in n+1:
			var i:=(start+j)%n
			var c:=_class(strengths[i])
			run.append(points[i])
			if c!=run_class or j==n:
				runs.append([run,run_class]);run=PackedVector2Array([points[i]]);run_class=c
		var ink:=Stroke.Ink.new(zoom)
		for r:Array in runs:
			var line:PackedVector2Array=Stroke.smooth(r[0],float(profile.dot),zoom*0.0035)
			if line.size()<2:continue
			var heights:=PackedFloat32Array()
			for p in line:heights.append(maxf(float(terrain._rendered_ground_height_at(p)),0.0)+float(profile.clearance))
			var cls:int=r[1]
			if cls<0:continue
			var width:float=float(profile.width)*float([1.1,1.4,2.2,3.2][cls])
			var color:=Color(PLUM,float([0.62,0.75,0.88,0.97][cls]))
			# Open ground and thin watch dotted; a kept line unbroken.
			if cls==0:Stroke.ribbon(ink,line,heights,width,color,0.6,0.0,2,4)
			else:Stroke.ribbon(ink,line,heights,width,color,0.45,0.0)
		var mesh:=MeshInstance3D.new();mesh.name="BorderWatchLine";mesh.mesh=ink.commit();mesh.material_override=terrain._scout_chart_material(4);root.add_child(mesh)
	var size:=float(profile.mark)
	for f:Dictionary in d.forts:
		var kind:="fort:%s%s" % [String(f.get("kind","stone_fort")),"" if String(f.status)=="standing" else ":building"]
		var mark:Sprite3D=terrain._scout_chart_mark(kind,Color(PLUM,0.6+0.4*clampf(float(f.manned),0.0,1.0)),f.at,float(profile.clearance)*2.0,size*2.4)
		mark.name="BorderFort";root.add_child(mark)
	return root
