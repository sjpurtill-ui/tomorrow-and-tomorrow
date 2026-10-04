extends RefCounted
## Detailed, neutral building families for completed, recorded settlement fabric.
## Metres in cached meshes; existing parcel placement remains authoritative.
## Round four of map beauty (codex/beauty-4): every house has a real roof
## (pitched with overhanging eaves, courses of tile or shingle, a ridge cap,
## gable ends in the wall's material; flat packed-earth roofs behind a parapet
## over mud brick), walls in the recorded material, a plank door, chimneys once
## towns consolidate, and courtyards with a paved yard and a basin.
const FAMILIES := ["masonry", "industrial", "modern"]
const TYPES := ["terrace", "courtyard", "corner", "villa", "arcade", "hall", "workshop", "warehouse"]
static var cache:Dictionary={}
static var material:Material

static func kind(plot:Dictionary)->String:
	var generation:=int(plot.get("fabric_generation",0))
	if generation<4:return ""
	var use:=String(plot.get("land_use",""))
	if use not in ["residential_compound","mixed_household","market","civic","communal","sacred","workshop","storage","dirty_industry","hospitality"]:return ""
	var family:="modern" if generation>=12 else ("industrial" if generation>=11 else "masonry")
	if installed_features(plot)&1:family="timber"
	var type:=posmod(int(plot.get("seed",plot.get("id",1))),4)
	if use=="market":type=4
	elif use in ["civic","communal","sacred"]:type=5
	elif use in ["workshop","dirty_industry"]:type=6
	elif use=="storage":type=7
	return family+"_"+TYPES[type]

static func floors(plot:Dictionary)->int:
	return clampi(int(plot.get("storeys",1)),1,18)

## Vertex alpha tells the ink (settlement_ink.gd) what a roof is laid with, so
## fired tile keeps its colour and courses and is never repainted as straw.
const ROOF_TILE:=0.98
const ROOF_SHINGLE:=0.96
const ROOF_EARTH:=0.94
const ROOF_SLATE:=0.92

## Roof construction follows the recorded plan, not the settlement's age or
## its wall material. Old records without a plan use a modest timber/earth
## covering; they do not acquire fired tiles merely for having stone walls.
static func roof_for(plot:Dictionary)->String:
	var plan:=String(plot.get("roof_plan",""))
	if plan.is_empty():
		plan=preload("res://scripts/building_material_operations.gd").roof_plan(plot.get("building_materials",{}),"")
		if plan.is_empty() and float((plot.get("supply_provenance",{}) as Dictionary).get("Roof Tiles",0.0))>0.0:plan="fired_tile_roof"
	if plan=="fired_tile_roof":return "tile"
	if plan in ["masonry_roof","concrete_roof","rubble_slab"]:return "slab"
	if plan in ["irregular_flat","courtyard_flat","mixed_earthen_span"]:return "earth"
	if plan in ["thatched_ridge","round_thatch","tapered_thatch","long_thatch"]:return "thatch"
	if plan in ["timber_ridge","timber_span_on_rubble","ridge_light_shelter"]:return "timber"
	return "earth" if String(plot.get("material_family",""))=="earth" else "timber"

static func chimney_for(plot:Dictionary)->bool:
	# A completed material profile can retain its applied practice in an older
	# save. Otherwise actual local knowledge supplies the capability, never age.
	var applied:Array=(plot.get("building_materials",{}) as Dictionary).get("applied",[])
	for id in ["wall_chimneys","multi_flue_chimney_stacks","narrow_throat_fireplace"]:
		if id in applied:return true
		if int(plot.get("fabric_generation",0))>=7 and id in WorldSimulation.state.known_discoveries:return true
	return false

static func style_for(plot:Dictionary)->String:
	var family:=String(plot.get("material_family",""))
	var material_key:="earth" if family=="earth" else ("brick" if family=="brick" else "stone")
	return material_key+"|"+roof_for(plot)+("_chimney" if chimney_for(plot) else "")

static func mesh_for(name:String,storeys:int=3,features:int=0,style:="stone")->ArrayMesh:
	var key:=name+":"+str(storeys)+":"+str(features)+":"+style
	if cache.has(key):return cache[key]
	var modern:=name.begins_with("modern_")
	var industrial:=name.begins_with("industrial_")
	var timber:=name.begins_with("timber_")
	var type:=name.get_slice("_",1)
	var earth:=style.begins_with("earth")
	var brick:=style.begins_with("brick")
	var chimney:=style.ends_with("_chimney") and not modern
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Walls in their material: dressed limestone, lime-washed mud brick,
	# fired brick, or a timber frame; windows are small dark openings under
	# pale lintels until the industrial age.
	var wall:Color=Color("c9bb9c")
	if earth:wall=Color("d0b284")
	if brick:wall=Color("a8674c")
	if industrial:wall=Color("a46650")
	if modern:wall=Color("d9d9d0")
	if timber:wall=Color("d8c7a4")
	var trim:=Color("e6d9bd") if not modern else Color("eef1e9")
	var glass:=Color("3a3129") if not (modern or industrial) else (Color("365058") if industrial else Color("658f9b"))
	var roof_kind:=style.get_slice("|",1).trim_suffix("_chimney")
	if roof_kind.is_empty():roof_kind="slate" if industrial else ("earth" if earth else "timber")
	var roof:=Color("7c5c40");var roof_code:=ROOF_SHINGLE
	match roof_kind:
		"tile":roof=Color("a4583a");roof_code=ROOF_TILE
		"slate":roof=Color("5f6266");roof_code=ROOF_SLATE
		"thatch":roof=Color("9b895e");roof_code=1.0
		"earth":roof=Color(.58,.47,.35);roof_code=ROOF_EARTH
		"slab":roof=Color("a49b82");roof_code=ROOF_EARTH
	if modern:roof=Color("6d7b77");roof_code=ROOF_SLATE
	roof.a=roof_code
	var flat:=roof_kind in ["earth","slab"] and not modern
	var height:=3.1*storeys
	var frame:=Color("5a4430")
	if modern:
		_modern_building(surface,type,storeys,features,wall,glass,trim,roof)
		surface.generate_normals()
		var modern_mesh:=surface.commit();cache[key]=modern_mesh;return modern_mesh
	match type:
		"courtyard":
			# Rooms round an open yard: two wings and a back range, each under
			# its own roof, the yard paved, a basin in its middle, the street
			# side open through a gate.
			_block(surface,Vector3(-3,0,0),Vector3(2,height,10),wall,glass,trim,features,1 if industrial else 0)
			_block(surface,Vector3(3,0,0),Vector3(2,height,10),wall,glass,trim,features,1 if industrial else 0)
			_block(surface,Vector3(0,0,-4),Vector3(4,height,2),wall,glass,trim,features,1 if industrial else 0)
			_box(surface,Vector3(0,.06,.6),Vector3(4.0,.12,7.6),Color("b3a489"))
			_box(surface,Vector3(0,.2,.8),Vector3(1.1,.4,1.1),Color("8e8a80"))
			_box(surface,Vector3(0,.41,.8),Vector3(.8,.02,.8),Color("4d6670"))
			if flat:
				for x in [-3,3]:_flat_roof(surface,Vector3(x,height,0),Vector2(1.0,5.0),wall,roof)
				_flat_roof(surface,Vector3(0,height,-4),Vector2(2.0,1.0),wall,roof)
			else:
				for x in [-3.0,3.0]:_gable(surface,Vector3(x,height,0),Vector2(1.0,5.0),1.0,.45,roof.darkened(.03 if x<0.0 else 0.0),wall,false)
				_gable(surface,Vector3(0,height,-4),Vector2(2.9,1.0),1.1,.45,roof,wall,true)
			if chimney:_chimney(surface,Vector3(3.2,height+.6,-3.4),wall)
		"corner":
			_block(surface,Vector3(-1.5,0,0),Vector3(5,height,10),wall,glass,trim,features,1 if industrial else 0)
			_block(surface,Vector3(2.5,0,2.7),Vector3(3,height*.78,4.6),wall,glass,trim,features,1 if industrial else 0)
			if flat:
				_flat_roof(surface,Vector3(-1.5,height,0),Vector2(2.5,5.0),wall,roof)
				_flat_roof(surface,Vector3(2.5,height*.78,2.7),Vector2(1.5,2.3),wall,roof)
			else:
				_gable(surface,Vector3(-1.5,height,0),Vector2(2.5,5.0),1.8,.5,roof,wall,false)
				_gable(surface,Vector3(2.5,height*.78,2.7),Vector2(1.5,2.3),1.2,.45,roof.darkened(.04),wall,true)
			if chimney:_chimney(surface,Vector3(-2.6,height+(.6 if flat else 1.0),-2.8),wall)
		"villa":
			# A house behind a porch: posts carry the porch roof over the door.
			_block(surface,Vector3(0,0,-1),Vector3(7,height*.75,7),wall,glass,trim,features,1 if industrial else 0)
			_box(surface,Vector3(0,.12,3.1),Vector3(7,.24,2.5),Color("a89a80"))
			for x in [-2.6,-.9,.9,2.6]:_box(surface,Vector3(x,1.3,4.1),Vector3(.24,2.6,.24),trim if not timber else frame)
			if flat:
				_flat_roof(surface,Vector3(0,height*.75,-1),Vector2(3.5,3.5),wall,roof)
				_box(surface,Vector3(0,2.66,3.1),Vector3(7.2,.14,2.6),Color("8a6a4a"))
			else:
				_hip(surface,Vector3(0,height*.75,-1),Vector2(3.5,3.5),2.0,.55,roof,.6)
				_lean_roof(surface,Vector3(0,2.6,3.2),Vector2(3.6,1.25),.5,.2,roof.darkened(.05),wall,0.0)
			if chimney:_chimney(surface,Vector3(2.0,height*.75+(.6 if flat else 1.2),-2.4),wall)
		"arcade":
			# Shops behind an arcade: a row of piers carries a lean-to roof.
			_block(surface,Vector3(0,0,-1),Vector3(8,height,7),wall,glass,trim,features,1 if industrial else 0)
			for x in [-3.5,-1.2,1.2,3.5]:_box(surface,Vector3(x,1.6,3.7),Vector3(.36,3.2,.36),trim)
			_lean_roof(surface,Vector3(0,3.2,3.5),Vector2(4.1,1.4),.6,.2,roof.darkened(.06),wall,0.0)
			_gable(surface,Vector3(0,height,-1),Vector2(4.0,3.5),2.0,.5,roof,wall,true)
			if chimney:_chimney(surface,Vector3(-2.8,height+(.6 if flat else 1.1),-2.6),wall)
		"hall":
			# A hall with two wings and a forecourt; a lantern louvre on its ridge.
			_block(surface,Vector3(0,0,-1.5),Vector3(8,height,6.5),wall,glass,trim,features,1 if industrial else 0)
			for x in [-3,3]:
				_block(surface,Vector3(x,0,2.5),Vector3(2,height*.6,5),wall,glass,trim,features,1 if industrial else 0)
				_gable(surface,Vector3(x,height*.6,2.5),Vector2(1.0,2.5),.9,.35,roof.darkened(.04),wall,false)
			_box(surface,Vector3(0,.12,3),Vector3(4,.24,4),Color("a89a80"))
			_gable(surface,Vector3(0,height,-1.5),Vector2(4.0,3.25),2.4,.55,roof,wall,true)
			if not flat:
				_box(surface,Vector3(0,height+2.5,-1.5),Vector3(.9,.7,.9),wall.darkened(.08))
				_pyramid(surface,Vector3(0,height+2.85,-1.5),.6,.5,roof.darkened(.1))
		"workshop", "warehouse":
			height=maxf(4,minf(height,9))
			_block(surface,Vector3.ZERO,Vector3(8,height,10),wall,glass,trim,features,1 if industrial else 0)
			if type=="workshop":
				for z in [-3.4,0,3.4]:_gable(surface,Vector3(0,height,z),Vector2(4.0,1.6),1.1,.3,roof.darkened(.03*absf(z)/3.4),wall,true)
				if industrial:_box(surface,Vector3(3,height*.9,-3.5),Vector3(.8,height*1.8,.8),wall.darkened(.18))
				elif chimney:_chimney(surface,Vector3(2.6,height+(.6 if flat else 1.1),-3.8),wall)
			else:
				_gable(surface,Vector3(0,height,0),Vector2(4.0,5.0),1.6,.45,roof,wall,false)
				# Loading doors in the gable and a hoist beam.
				_box(surface,Vector3(0,height*.72,5.06),Vector3(1.4,1.6,.1),Color("4a3526"))
				_box(surface,Vector3(0,height+.35,5.5),Vector3(.2,.2,1.2),frame)
			_box(surface,Vector3(0,1.6,5.05),Vector3(3.8,3.2,.18),Color("4f4034") if not (industrial or modern) else Color("505859"))
		_:
			_block(surface,Vector3.ZERO,Vector3(8,height,10),wall,glass,trim,features,1 if industrial else 0)
			if flat:_flat_roof(surface,Vector3(0,height,0),Vector2(4.0,5.0),wall,roof)
			else:
				# A row house: the ridge runs along the street (x), eaves front and back.
				_gable(surface,Vector3(0,height,0),Vector2(4.0,5.0),2.2,.5,roof,wall,true)
				if chimney:
					_chimney(surface,Vector3(-3.4,height+1.4,-.6),wall)
					_chimney(surface,Vector3(3.4,height+1.4,-.6),wall)
	if timber:_frame_walls(surface,name,height,frame)
	surface.generate_normals()
	var mesh:=surface.commit();cache[key]=mesh;return mesh

## Modern construction keeps the recorded land use and floor count, with real
## flat roof slabs/parapets on every wing. The former shared medieval branches
## put pitched gables on modern courtyards and roof gardens above empty space.
static func _modern_building(s:SurfaceTool,type:String,storeys:int,features:int,wall:Color,glass:Color,trim:Color,roof:Color)->void:
	var height:=3.1*storeys
	var blocks:Array=[]
	match type:
		"courtyard":blocks=[[Vector3(-3,0,0),Vector3(2,height,10)],[Vector3(3,0,0),Vector3(2,height,10)],[Vector3(0,0,-4),Vector3(4,height,2)]]
		"corner":blocks=[[Vector3(-1.5,0,0),Vector3(5,height,10)],[Vector3(2.5,0,2.7),Vector3(3,3.1*maxi(1,storeys-2),4.6)]]
		"villa":blocks=[[Vector3(0,0,-1),Vector3(7,height,7)]]
		"arcade":blocks=[[Vector3(0,0,-1),Vector3(8,height,7)]]
		"hall":blocks=[[Vector3(0,0,-1.5),Vector3(8,height,6.5)],[Vector3(-3,0,2.5),Vector3(2,3.1*maxi(1,storeys-1),5)],[Vector3(3,0,2.5),Vector3(2,3.1*maxi(1,storeys-1),5)]]
		"workshop","warehouse":blocks=[[Vector3.ZERO,Vector3(8,maxf(4.0,minf(height,9.0)),10)]]
		_:
			if storeys>=5:
				# The setback replaces the top floors; it does not add a fictional
				# nineteenth floor to a parcel recorded as eighteen storeys.
				var lower:=3.1*(storeys-2)
				blocks=[[Vector3.ZERO,Vector3(8,lower,10)],[Vector3(0,lower,0),Vector3(5,6.2,7)]]
			else:blocks=[[Vector3.ZERO,Vector3(8,height,10)]]
	for block:Array in blocks:
		var base:Vector3=block[0];var size:Vector3=block[1]
		_block(s,base,size,wall,glass,trim,features,2)
		var top:=base+Vector3(0,size.y,0)
		_box(s,top+Vector3(0,.06,0),Vector3(size.x,.12,size.z),roof)
		for side in [-1,1]:
			_box(s,top+Vector3(side*(size.x*.5-.1),.25,0),Vector3(.2,.38,size.z),trim)
			_box(s,top+Vector3(0,.25,side*(size.z*.5-.1)),Vector3(size.x,.38,.2),trim)
		# Compact vents sit on a supported roof and remain below its parapet.
		if size.x>=3.0:_box(s,top+Vector3(-size.x*.22,.24,-size.z*.22),Vector3(.65,.36,.8),Color("899391"))
	if type in ["villa","arcade","hall"]:
		var front:=4.1 if type=="villa" else (3.5 if type=="arcade" else 4.1)
		_box(s,Vector3(0,2.65,front),Vector3(5.6,.18,1.7),trim)
		for side in [-1,1]:_box(s,Vector3(side*2.5,1.3,front+.65),Vector3(.16,2.6,.16),Color("647371"))
	if type in ["workshop","warehouse"]:
		_box(s,Vector3(0,1.7,5.06),Vector3(3.6,3.4,.13),Color("536569"))
		for y in [1.0,1.8,2.6]:_box(s,Vector3(0,y,5.14),Vector3(3.5,.06,.04),trim.darkened(.2))
		if type=="workshop":
			for z in [-2.4,0,2.4]:_box(s,Vector3(0,maxf(4.0,minf(height,9.0))+.15,z),Vector3(4.6,.18,1.2),glass)

static func _block(s:SurfaceTool,base:Vector3,size:Vector3,wall:Color,glass:Color,trim:Color,features:int=0,period:int=0)->void:
	_box(s,base+Vector3(0,size.y*.5,0),size,wall)
	# A plinth course a shade darker, where the wall meets the ground.
	_box(s,base+Vector3(0,.2,0),Vector3(size.x+.08,.4,size.z+.08),wall.darkened(.14))
	var floors:=maxi(1,floori(size.y/3.1))
	var window_width:=1.5 if period>=1 else .7
	var window_height:=1.65 if period>=1 else 1.1
	for floor in floors:
		var y:=base.y+1.7+floor*3.1
		for side in [-1,1]:
			var across:=maxi(1,floori(size.x/2.6))
			for x in range(across):
				var offset:=-size.x*.5+(x+.5)*size.x/across
				var width:=minf(window_width,size.x/across*.72)
				_box(s,Vector3(base.x+offset,y,base.z+side*(size.z*.5+.025)),Vector3(width,window_height,.06),glass)
				_box(s,Vector3(base.x+offset,y+window_height*.5+.09,base.z+side*(size.z*.5+.04)),Vector3(width+.2,.16,.08),trim)
				if period>=1:_box(s,Vector3(base.x+offset,y,base.z+side*(size.z*.5+.065)),Vector3(.06,window_height,.05),trim)
			var deep:=maxi(1,floori(size.z/3.2))
			for z in range(deep):
				var offset:=-size.z*.5+(z+.5)*size.z/deep
				var width:=minf(window_width,size.z/deep*.72)
				_box(s,Vector3(base.x+side*(size.x*.5+.025),y,base.z+offset),Vector3(.06,window_height,width),glass)
				_box(s,Vector3(base.x+side*(size.x*.5+.04),y+window_height*.5+.09,base.z+offset),Vector3(.08,.16,width+.2),trim)
				if period>=1:_box(s,Vector3(base.x+side*(size.x*.5+.065),y,base.z+offset),Vector3(.05,window_height,.06),trim)
		if floor<floors-1:_box(s,base+Vector3(0,(floor+1)*3.1-.08,0),Vector3(size.x+.12,.16,size.z+.12),trim)
	# A plank door under a lintel.
	_box(s,base+Vector3(0,1.0,size.z*.5+.05),Vector3(1.0,2.0,.1),Color("4a3526"))
	_box(s,base+Vector3(0,2.08,size.z*.5+.07),Vector3(1.3,.18,.12),trim)
	if features:
		var bounds:=AABB(base-Vector3(size.x*.5,0,size.z*.5),size)
		s.append_from(detail_mesh(bounds,features,1.0),0,Transform3D.IDENTITY)

static func _box(s:SurfaceTool,center:Vector3,size:Vector3,color:Color)->void:
	var box:=BoxMesh.new();box.size=size
	var arrays:=box.get_mesh_arrays();var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in indices:s.set_color(color);s.add_vertex(vertices[i]+center)

static func _tri(s:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,color:Color)->void:
	# Wound so the face looks away from the building's middle and upward.
	var n:=(b-a).cross(c-a)
	var out:=(a+b+c)/3.0;out.y=maxf(out.y,.01)*2.0
	if n.dot(out)>0.0:
		var t:=b;b=c;c=t
	for v in [a,b,c]:s.set_color(color);s.add_vertex(v)

static func _quad(s:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,color:Color)->void:
	_tri(s,a,b,c,color);_tri(s,a,c,d,color)

## A pitched roof over walls of half extents `half` (x, z) whose tops are at
## `base.y`: eaves overhang by `overhang`, the ridge `rise` above the wall
## top, along x when `along_x` (else along z). Gable ends in the wall's
## material, a dark eave soffit, a ridge cap, and courses along each slope.
static func _gable(s:SurfaceTool,base:Vector3,half:Vector2,rise:float,overhang:float,roof:Color,wall:Color,along_x:bool)->void:
	if is_equal_approx(roof.a,ROOF_EARTH):
		_flat_roof(s,base,half,wall,roof);return
	var a:=half.y if along_x else half.x   # half span across the ridge
	var l:=(half.x if along_x else half.y)+overhang*.8   # half length along it
	var span:=a+overhang
	var drop:=overhang*rise/maxf(a,.1)
	var y0:=base.y-drop;var y1:=base.y+rise
	var P:=func(u:float,v:float,y:float)->Vector3:
		return base+(Vector3(v,0,u) if along_x else Vector3(u,0,v))+Vector3(0,y-base.y,0)
	for side in [-1.0,1.0]:
		var e0:Vector3=P.call(side*span,-l,y0);var e1:Vector3=P.call(side*span,l,y0)
		var r0:Vector3=P.call(0.0,-l,y1);var r1:Vector3=P.call(0.0,l,y1)
		_quad(s,e0,e1,r1,r0,roof if side<0 else roof.darkened(.06))
		# Courses of tile or shingle: fine darker lines along the slope.
		for t in [.22,.44,.66,.84]:
			var c0:Vector3=e0.lerp(r0,t)+Vector3(0,.035,0);var c1:Vector3=e1.lerp(r1,t)+Vector3(0,.035,0)
			var d0:Vector3=e0.lerp(r0,t+.035)+Vector3(0,.035,0);var d1:Vector3=e1.lerp(r1,t+.035)+Vector3(0,.035,0)
			_quad(s,c0,c1,d1,d0,roof.darkened(.2))
		# The soffit under the overhang, in shade.
		var w0:Vector3=P.call(side*a,-l,base.y);var w1:Vector3=P.call(side*a,l,base.y)
		_quad(s,e0,e1,w1,w0,Color(.22,.17,.13,roof.a))
	# Gable ends in the wall's material, set back under the verge.
	for end in [-1.0,1.0]:
		var g0:Vector3=P.call(-a,end*(l-overhang*.8),base.y);var g1:Vector3=P.call(a,end*(l-overhang*.8),base.y)
		var g2:Vector3=P.call(0.0,end*(l-overhang*.8),y1-.05)
		_tri(s,g0,g1,g2,wall.darkened(.05))
	# The ridge cap.
	var ridge_len:=l*2.0+.1
	_box(s,P.call(0.0,0.0,y1+.05),Vector3(ridge_len,.14,.3) if along_x else Vector3(.3,.14,ridge_len),roof.darkened(.25))

## A single slope from a high wall side down to the eave (a lean-to, a porch,
## a courtyard wing); `fall` is the x direction it drains toward (0 = +z).
static func _lean_roof(s:SurfaceTool,base:Vector3,half:Vector2,rise:float,overhang:float,roof:Color,wall:Color,fall:float)->void:
	if is_equal_approx(roof.a,ROOF_EARTH):
		_flat_roof(s,base,half,wall,roof);return
	var hx:=half.x+overhang;var hz:=half.y+overhang
	var hi:=base.y+rise;var lo:=base.y-overhang*.3
	var a:Vector3;var b:Vector3;var c:Vector3;var d:Vector3
	if fall!=0.0:
		# High along the yard side (x toward the middle), low toward the outside.
		var inner:=base.x-signf(fall)*hx;var outer:=base.x+signf(fall)*hx
		a=Vector3(inner,hi,base.z-hz);b=Vector3(inner,hi,base.z+hz);c=Vector3(outer,lo,base.z+hz);d=Vector3(outer,lo,base.z-hz)
	else:
		a=Vector3(base.x-hx,hi,base.z-hz);b=Vector3(base.x+hx,hi,base.z-hz);c=Vector3(base.x+hx,lo,base.z+hz);d=Vector3(base.x-hx,lo,base.z+hz)
	_quad(s,a,b,c,d,roof)
	for t in [.3,.6]:
		var p0:=a.lerp(d,t) if fall==0.0 else a.lerp(d,t);var p1:=b.lerp(c,t)
		_quad(s,p0+Vector3(0,.03,0),p1+Vector3(0,.03,0),p1+Vector3(0,.03,0)+(c-b)*.04,p0+Vector3(0,.03,0)+(d-a)*.04,roof.darkened(.2))
	# The raised wall head it leans against.
	if fall!=0.0:_box(s,Vector3(base.x-signf(fall)*half.x,base.y+rise*.5,base.z),Vector3(.3,rise,half.y*2.0),wall)

## A hipped roof: slopes on all four sides to a short ridge along x.
static func _hip(s:SurfaceTool,base:Vector3,half:Vector2,rise:float,overhang:float,roof:Color,ridge_share:float)->void:
	if is_equal_approx(roof.a,ROOF_EARTH):
		_flat_roof(s,base,half,roof,roof);return
	var hx:=half.x+overhang;var hz:=half.y+overhang
	var y0:=base.y-overhang*rise/maxf(half.y,.1);var y1:=base.y+rise
	var rh:=hx*ridge_share*.5
	var e0:=Vector3(base.x-hx,y0,base.z-hz);var e1:=Vector3(base.x+hx,y0,base.z-hz)
	var e2:=Vector3(base.x+hx,y0,base.z+hz);var e3:=Vector3(base.x-hx,y0,base.z+hz)
	var r0:=Vector3(base.x-rh,y1,base.z);var r1:=Vector3(base.x+rh,y1,base.z)
	_quad(s,e0,e1,r1,r0,roof.darkened(.05))
	_quad(s,e2,e3,r0,r1,roof)
	_tri(s,e3,e0,r0,roof.darkened(.02))
	_tri(s,e1,e2,r1,roof.darkened(.08))
	for t in [.3,.6]:
		var a:=e3.lerp(r0,t);var b:=e2.lerp(r1,t)
		_quad(s,a+Vector3(0,.03,0),b+Vector3(0,.03,0),b+Vector3(0,.03,0)+(r1-e2)*.04,a+Vector3(0,.03,0)+(r0-e3)*.04,roof.darkened(.2))
		var c:=e0.lerp(r0,t);var d:=e1.lerp(r1,t)
		_quad(s,c+Vector3(0,.03,0),d+Vector3(0,.03,0),d+Vector3(0,.03,0)+(r1-e1)*.04,c+Vector3(0,.03,0)+(r0-e0)*.04,roof.darkened(.2))
	_quad(s,e0,e3,Vector3(base.x-half.x,base.y,base.z+half.y),Vector3(base.x-half.x,base.y,base.z-half.y),Color(.22,.17,.13,roof.a))
	_quad(s,e1,e2,Vector3(base.x+half.x,base.y,base.z+half.y),Vector3(base.x+half.x,base.y,base.z-half.y),Color(.22,.17,.13,roof.a))
	_box(s,Vector3(base.x,y1+.05,base.z),Vector3(rh*2.0+.3,.14,.3),roof.darkened(.25))

## A flat roof of beams and packed earth behind a low parapet, with a hatch.
static func _flat_roof(s:SurfaceTool,base:Vector3,half:Vector2,wall:Color,roof:Color)->void:
	_box(s,Vector3(base.x,base.y+.06,base.z),Vector3(half.x*2.0,.12,half.y*2.0),roof)
	for side in [-1,1]:
		_box(s,Vector3(base.x+side*(half.x-.1),base.y+.28,base.z),Vector3(.2,.44,half.y*2.0),wall)
		_box(s,Vector3(base.x,base.y+.28,base.z+side*(half.y-.1)),Vector3(half.x*2.0,.44,.2),wall)
	_box(s,Vector3(base.x-half.x*.35,base.y+.13,base.z-half.y*.35),Vector3(.7,.04,.7),Color(.16,.12,.09,roof.a))
	# Beam ends through the wall head.
	for k in 4:
		var z:=base.z+lerpf(-half.y*.75,half.y*.75,float(k)/3.0)
		_box(s,Vector3(base.x+half.x+.1,base.y-.25,z),Vector3(.25,.14,.14),Color("5a4430"))

static func _chimney(s:SurfaceTool,at:Vector3,wall:Color)->void:
	_box(s,at,Vector3(.7,1.6,.7),wall.darkened(.12))
	_box(s,at+Vector3(0,.85,0),Vector3(.85,.12,.85),wall.darkened(.22))
	_box(s,at+Vector3(0,.92,0),Vector3(.4,.04,.4),Color(.10,.08,.06))

static func _pyramid(s:SurfaceTool,at:Vector3,half:float,rise:float,color:Color)->void:
	var c:=[at+Vector3(-half,0,-half),at+Vector3(half,0,-half),at+Vector3(half,0,half),at+Vector3(-half,0,half)]
	var top:=at+Vector3(0,rise,0)
	for k in 4:_tri(s,c[k],c[(k+1)%4],top,color.darkened(.04*float(k)))

## Timber framing on the walls: corner posts, a sill and a head beam, and
## studs and braces showing dark against pale infill.
static func _frame_walls(s:SurfaceTool,name:String,height:float,frame:Color)->void:
	var blocks:Array=[[Vector3.ZERO,Vector3(8,height,10)]]
	match name.get_slice("_",1):
		"courtyard":blocks=[[Vector3(-3,0,0),Vector3(2,height,10)],[Vector3(3,0,0),Vector3(2,height,10)],[Vector3(0,0,-4),Vector3(4,height,2)]]
		"corner":blocks=[[Vector3(-1.5,0,0),Vector3(5,height,10)],[Vector3(2.5,0,2.7),Vector3(3,height*.78,4.6)]]
		"villa":blocks=[[Vector3(0,0,-1),Vector3(7,height*.75,7)]]
		"arcade":blocks=[[Vector3(0,0,-1),Vector3(8,height,7)]]
		"hall":blocks=[[Vector3(0,0,-1.5),Vector3(8,height,6.5)]]
	for block in blocks:
		var base:Vector3=block[0];var size:Vector3=block[1]
		for side in [-1.0,1.0]:
			var z:float=base.z+side*(size.z*.5+.05)
			var x:float=base.x+side*(size.x*.5+.05)
			var studs:=maxi(2,floori(size.x/1.6))
			for k in studs+1:
				var sx:=base.x-size.x*.5+size.x*float(k)/float(studs)
				_box(s,Vector3(sx,size.y*.5,z),Vector3(.16,size.y,.06),frame)
			var ribs:=maxi(2,floori(size.z/1.6))
			for k in ribs+1:
				var sz:=base.z-size.z*.5+size.z*float(k)/float(ribs)
				_box(s,Vector3(x,size.y*.5,sz),Vector3(.06,size.y,.16),frame)
			_box(s,Vector3(base.x,size.y-.1,z),Vector3(size.x,.18,.07),frame)
			_box(s,Vector3(base.x,size.y*.5,z),Vector3(size.x,.12,.07),frame)
			_box(s,Vector3(x,size.y-.1,base.z),Vector3(.07,.18,size.z),frame)

static func render(plan:Dictionary,center:Vector3,height:Callable,parent:Node3D)->void:
	if material==null:
		material=preload("res://scripts/settlement_ink.gd").architecture_material()
	var groups:Dictionary={}
	for record:Dictionary in plan.buildings:
		var name:=kind(record.plot)
		if name=="" or String(record.plot.get("status","active")) in ["ruin","reclaimed","under_construction"]:continue
		if float(record.plot.get("damage",{}).get("structural",0))>.65:continue
		var key:=name+":"+str(floors(record.plot))+":"+str(installed_features(record.plot))+":"+style_for(record.plot)
		if not groups.has(key):groups[key]=[]
		groups[key].append(record)
	for key:String in groups:
		var group:Array=groups[key];var first:Dictionary=group[0]
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
		batch.mesh=mesh_for_plot(first.plot);batch.instance_count=group.size()
		var placed:Array[Transform3D]=[]
		for i in group.size():
			var record:Dictionary=group[i];var point:Vector2=record.position+Vector2(center.x,center.z)
			var placement:=Transform3D(Basis(Vector3.UP,float(record.angle)).scaled(Vector3.ONE*.001),Vector3(point.x,float(height.call(point.x,point.y))+.0001,point.y))
			placed.append(placement)
			batch.set_instance_transform(i,placement)
			var wear:=1-clampf(float(record.plot.get("condition",1)),0,1)
			var tint:Color=[Color("fff7e8"),Color("e8eee6"),Color("e7e1d9"),Color("eedbd0")][posmod(int(record.plot.get("seed",1)),4)]
			batch.set_instance_color(i,tint.lerp(Color("554b40"),wear*.6))
		var node:=MultiMeshInstance3D.new();node.name="SettlementArchitecture_"+key;node.multimesh=batch;node.material_override=material;parent.add_child(node)
		# Soft shadows where each building stands (settlement_ink.gd).
		preload("res://scripts/settlement_ink.gd").add_ground_shadows(parent,"GroundShadow_"+key.replace(":","_"),placed,batch.mesh.get_aabb())

static func installed_features(plot:Dictionary)->int:
	var installed:Variant=plot.get("fabric_components",{})
	if not installed is Dictionary:return 0
	var flags:=0
	var mapping:Dictionary={"timber_post_beam_connections":1,"timber_splice_connections":1,"timber_lateral_bracing":2,"timber_moisture_movement_design":4,"building_drainage_coordination":8,"roof_flashing_interfaces":16,"rainscreen_wall_assemblies":32,"building_shading_design":64,"building_capillary_breaks":128}
	for method:String in mapping:
		if not installed.has(method):continue
		var record:Variant=installed[method]
		if preload("res://scripts/settlement_fabric_operations.gd").valid_record(record,int(plot.get("id",0)),true) and record.job.method==method:
			flags|=int(mapping[method])
	return flags

static func mesh_for_plot(plot:Dictionary)->ArrayMesh:
	return mesh_for(kind(plot),floors(plot),installed_features(plot),style_for(plot))

static func _add_installed_details(surface:SurfaceTool,height:float,flags:int)->void:
	var wood:=Color("624831")
	if flags&1:
		for x in [-3.8,-1.2,1.2,3.8]:_box(surface,Vector3(x,height*.5,5.12),Vector3(.18,height,.18),wood)
		_box(surface,Vector3(0,height-.12,5.12),Vector3(8,.22,.18),wood)
	if flags&2:
		var bottom:=Vector3(-3.5,.35,5.15)
		var top:=Vector3(-.5,minf(height-.3,2.7),5.15)
		var delta:=top-bottom
		var brace:=BoxMesh.new();brace.size=Vector3(.18,delta.length(),.18)
		var arrays:=brace.get_mesh_arrays()
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var rotation:=Basis(Vector3.BACK,atan2(-delta.x,delta.y))
		for index in indices:
			surface.set_color(wood);surface.add_vertex(rotation*vertices[index]+(bottom+top)*.5)
	if flags&4:_box(surface,Vector3(0,height*.5,5.14),Vector3(.06,height,.08),Color("302e29"))
	if flags&8:
		_box(surface,Vector3(4.3,.1,0),Vector3(.35,.2,10.8),Color("827969"))
		_box(surface,Vector3(4.3,height*.5,4.8),Vector3(.16,height,.16),Color("827969"))
	if flags&16:_box(surface,Vector3(0,height+.04,5.12),Vector3(8.4,.08,.28),Color("977251"))
	if flags&32:
		for x in 16:
			if x in [6,7,8,9]:continue # Retain the central entrance.
			_box(surface,Vector3(-3.75+float(x)*.5,height*.5,5.2),Vector3(.34,height,.12),Color("a28b6c"))
	if flags&64:
		var shade_height:=minf(2.5,height*.85)
		for x in 9:_box(surface,Vector3(-3.6+float(x)*.9,shade_height,5.65),Vector3(.18,.12,1.3),wood)
		_box(surface,Vector3(0,shade_height,6.22),Vector3(8,.12,.12),wood)
	if flags&128:_box(surface,Vector3(0,.18,0),Vector3(8.2,.12,10.2),Color("524e46"))

static func detail_mesh(bounds:AABB,features:int,wall_ratio:float=.8)->ArrayMesh:
	var key:="details:"+str(bounds)+":"+str(features)+":"+str(wall_ratio)
	if cache.has(key):return cache[key]
	var raw:=SurfaceTool.new();raw.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_installed_details(raw,maxf(.5,bounds.size.y*wall_ratio),features)
	raw.generate_normals()
	var source:=raw.commit()
	var baked:=SurfaceTool.new()
	var scale:=Vector3(maxf(.1,bounds.size.x)/8.0,1.0,maxf(.1,bounds.size.z)/10.0)
	var origin:=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	baked.append_from(source,0,Transform3D(Basis.from_scale(scale),origin))
	var result:=baked.commit();cache[key]=result;return result

static func early_detail_mesh(bounds:AABB,name:String,features:int)->ArrayMesh:
	# Finite authored asset profiles: roof envelopes are not wall dimensions.
	var round_wall:=name=="round_household"
	var ratio:=.58 if round_wall else (.9 if name in ["earthen_household","rubble_household","covered_workshop","raised_store"] else .55)
	var width_ratio:=.88 if round_wall else .9
	var size:=Vector3(bounds.size.x*width_ratio,bounds.size.y*ratio,bounds.size.z*width_ratio)
	var center:=bounds.get_center()
	var walls:=AABB(Vector3(center.x-size.x*.5,bounds.position.y,center.z-size.z*.5),size)
	var source:=detail_mesh(walls,features,1.0)
	if not round_wall:return source
	var key:="round_details:"+str(bounds)+":"+str(features)
	if cache.has(key):return cache[key]
	var arrays:=source.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	if indices.is_empty():
		for i in vertices.size():indices.append(i)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		var v:=vertices[index]
		var relative_x:float=(v.x-center.x)/maxf(.1,size.x*.5)
		if v.z>center.z+size.z*.4 and absf(relative_x)<=1.0:
			v.z+=size.z*.5*(sqrt(maxf(0,1-relative_x*relative_x))-1.0)
		surface.set_color(colors[index]);surface.add_vertex(v)
	surface.generate_normals()
	var mesh:=surface.commit();cache[key]=mesh;return mesh
