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
## Closer in than this view width (km) each fort stands on the ground as built
## (the settlements' own wall kit: local_terrain.gd _append_settlement_defense_ring).
const MODEL_ZOOM_KM:=28.0
## Each kind as the town walls' stages: watch posts, ditch and bank, palisade,
## stone wall with towers, and the bastion fort's star of stone.
const STAGES:={"watch_camp":1,"earthwork_fort":2,"palisade_fort":3,"stone_fort":4,"bastion_fort":5}
## Ring radius, km.
const RADII:={"watch_camp":0.035,"earthwork_fort":0.055,"palisade_fort":0.065,"stone_fort":0.085,"bastion_fort":0.11}
const TIMBER:=Color("#76583a")
const EARTH:=Color("#86704c")
const STONE:=Color("#a39d92")

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
		var work:=maxf(1.0,float(Forts.kind(String(f.kind)).get("work",1.0)))
		marks.append({"at":Forts._pos(f),"status":String(f.status),"manned":float(kept.garrisons.get(int(f.id),0))/need,"name":String(f.get("name","")),"kind":String(f.kind),
			"id":int(f.id),"condition":clampf(float(f.get("condition",1.0)),0.0,1.0),"completion":clampf(float(f.get("progress",0.0))/work,0.0,1.0)})
	var foreign:=[]
	for f:Dictionary in Forts.known_foreign_forts():foreign.append({"at":f.at,"kind":String(f.kind),"status":String(f.status),"owner":String(f.owner)})
	return {"points":shape.points,"strengths":strengths,"forts":marks,"foreign":foreign}

## What the drawing depends on, coarsely: redraw only when it changes.
static func key(d:Dictionary,zoom_octave:int)->int:
	var classes:=PackedInt32Array()
	for value:float in (d.strengths as PackedFloat32Array):classes.append(_class(value))
	var rounded:=PackedVector2Array()
	for p:Vector2 in (d.points as PackedVector2Array):rounded.append(p.snapped(Vector2.ONE*0.5))
	return hash([rounded,classes,var_to_str(d.forts),var_to_str(d.get("foreign",[])),zoom_octave])

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
	# Close in, the fort itself stands there (_models); its chart mark would hide it.
	for f:Dictionary in (d.forts if zoom>MODEL_ZOOM_KM*0.12 else []):
		var kind:="fort:%s%s" % [String(f.get("kind","stone_fort")),"" if String(f.status)=="standing" else ":building"]
		var mark:Sprite3D=terrain._scout_chart_mark(kind,Color(PLUM,0.6+0.4*clampf(float(f.manned),0.0,1.0)),f.at,float(profile.clearance)*2.0,size*2.4)
		mark.name="BorderFort";root.add_child(mark)
	if zoom<=MODEL_ZOOM_KM:root.add_child(_models(terrain,d))
	# Forts of peoples we know, in their own colour (nation_borders.gd).
	for f:Dictionary in d.get("foreign",[]):
		var kind:="fort:%s%s" % [String(f.kind),"" if String(f.status)=="standing" else ":building"]
		var colour:Color=preload("res://scripts/nation_borders.gd").nation_color(String(f.owner)).darkened(0.35)
		var mark:Sprite3D=terrain._scout_chart_mark(kind,Color(colour,0.9),f.at,float(profile.clearance)*2.0,size*2.0)
		mark.name="ForeignFort";root.add_child(mark)
	return root


## Our forts as built, for the close views: each kind's ring of wall (going up
## only as far as its work), its gate toward home, and what stands within: a
## watch tower in a camp, a hall in a palisade, a keep in stone.
static func _models(terrain:Node,d:Dictionary)->Node3D:
	var root:=Node3D.new();root.name="FortModels"
	var home:=Forts.seat()
	for f:Dictionary in d.forts:
		var kind:=String(f.get("kind","stone_fort"))
		var stage:int=int(STAGES.get(kind,4))
		var radius:float=float(RADII.get(kind,0.08))
		var at:Vector2=f.at
		var center:=Vector3(at.x,0.0,at.y)
		var flat:=SurfaceTool.new();var mass:=SurfaceTool.new()
		flat.begin(Mesh.PRIMITIVE_TRIANGLES);mass.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segments:=40 if kind=="bastion_fort" else 28
		var envelope:=PackedFloat32Array()
		if kind=="bastion_fort":
			# Five arrowhead bastions: a point every eighth bearing, the curtain between.
			for i in segments:
				var phase:=i%8
				envelope.append(radius*(1.34 if phase==0 else (1.0 if phase==1 or phase==7 else 0.8)))
		var colour:=STONE if stage>=4 else (EARTH if stage<=2 else TIMBER)
		var building:=String(f.get("status",""))!="standing"
		var axis:=float(int(f.get("id",0))%7)*0.37
		var gates:Array[float]=[fposmod((home-at).angle()-axis,TAU)]
		var built:Dictionary=terrain._append_settlement_defense_ring(flat,mass,center,Vector2.ZERO,radius,axis,stage,float(f.get("condition",1.0)),float(f.get("completion",1.0)) if building else 1.0,building,colour,int(f.get("id",0))*131+7,segments,gates,kind=="bastion_fort",envelope)
		var within:=not building or float(f.get("completion",0.0))>0.6
		if within:
			match kind:
				"watch_camp":terrain._append_settlement_defense_wall_segment(mass,center,Vector2(-0.0022,0.0),Vector2(0.0022,0.0),0.0022,0.012,TIMBER)
				"palisade_fort":terrain._append_settlement_urban_mass(mass,center,Vector2.ZERO,0.011,0.006,0.005,axis,TIMBER.darkened(0.1))
				"earthwork_fort":terrain._append_settlement_urban_mass(mass,center,Vector2.ZERO,0.008,0.005,0.004,axis,TIMBER)
				_:terrain._append_settlement_urban_mass(mass,center,Vector2.ZERO,0.013,0.013,0.016 if kind=="stone_fort" else 0.012,axis,STONE.lightened(0.05))
			# The garrison's long barracks along the inner wall, the gate side kept open.
			if stage>=3:
				var rows:=4 if stage>=4 else 2
				for k in rows:
					var bearing:=float(gates[0])+axis+PI*(0.55+0.9*float(k)/float(maxi(1,rows-1)))
					var spot:=Vector2.from_angle(bearing)*radius*0.62
					terrain._append_settlement_urban_mass(mass,center,spot,0.016,0.005,0.0045,bearing+PI*0.5,(TIMBER if stage==3 else STONE).darkened(0.12))
			# A dry ditch outside stone walls.
			if stage>=4 and envelope.is_empty():
				# Following the wall's own line, a few metres out.
				var ring:=PackedVector2Array()
				for seg:Dictionary in built.get("segments",[]):
					var a:Vector2=seg.a
					ring.append(a+a.normalized()*0.012)
				if not ring.is_empty():ring.append(ring[0])
				var ditch:=EARTH.darkened(0.35);ditch.a=0.7
				built["flat"]=int(built.get("flat",0))+int(terrain._append_settlement_system_ribbon(flat,center,ring,0.006,ditch,0.00008,48))
		var node:=Node3D.new();node.name="Fort_%d" % int(f.get("id",0));root.add_child(node)
		if int(built.get("flat",0))>0:terrain._commit_settlement_surface(flat,"PersistentSettlementDefenseGround",node,true)
		if int(built.get("mass",0))>0 or within:terrain._commit_settlement_surface(mass,"PersistentSettlementDefenseMassing",node,false)
	return root
