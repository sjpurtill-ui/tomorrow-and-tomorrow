extends RefCounted
## Painterly objects are placed on the existing recorded fabric. This adapter
## chooses an appearance; it never creates a building, upgrade or resource.
const BUILDINGS="res://assets/ui/people/settlement-buildings-v1.png"
const DETAILS="res://assets/ui/people/settlement-details-v1.png"
const STATES="res://assets/ui/people/settlement-states-v1.png"
const VARIANTS="res://assets/ui/people/settlement-timber-variants-v2.png"
const WORKSHOP="res://assets/ui/people/settlement-workshop-v1.png"
const ROOFS="res://assets/ui/people/settlement-roofs-v1.png"
const MATURE="res://assets/ui/people/settlement-mature-v1.png"
const Early=preload("res://scripts/early_settlement_visual.gd")
const Late=preload("res://scripts/settlement_architecture_kit.gd")
const Construction=preload("res://scripts/settlement_construction_state.gd")
static var _atlases:Dictionary={}
static var _regions:Dictionary={}

static func available()->bool:return _exists(BUILDINGS) and _exists(DETAILS)

static func _exists(path:String)->bool:return ResourceLoader.exists(path) or FileAccess.file_exists(path)

static func atlas(path:String)->Texture2D:
	if _atlases.has(path):return _atlases[path]
	if ResourceLoader.exists(path):
		var imported:=load(path) as Texture2D
		if imported!=null:_atlases[path]=imported;return imported
	if not FileAccess.file_exists(path):return null
	var image:=Image.load_from_file(path)
	if image==null or image.is_empty():return null
	image.generate_mipmaps()
	var texture:=ImageTexture.create_from_image(image)
	_atlases[path]=texture
	return texture

static func region(path:String,cell:int,rows:int=3,columns:int=4)->Rect2i:
	var key:=path+":"+str(cell)+":"+str(rows)+":"+str(columns)
	if _regions.has(key):return _regions[key]
	var texture:=atlas(path)
	if texture==null:return Rect2i()
	var image:=texture.get_image()
	if image.is_compressed():image.decompress()
	var column:=cell%columns;var row:=cell/columns
	var origin:=Vector2i(roundi(float(column)*image.get_width()/columns),roundi(float(row)*image.get_height()/rows))
	var end:=Vector2i(roundi(float(column+1)*image.get_width()/columns),roundi(float(row+1)*image.get_height()/rows))
	var dimensions:=end-origin
	var left:=dimensions.x;var right:=0;var top:=dimensions.y;var bottom:=0
	# Alpha gutters differ between painted objects. Crop only in the private
	# texture region, so the visible ground contact is stable at the anchor.
	for y in dimensions.y:
		for x in dimensions.x:
			if image.get_pixel(origin.x+x,origin.y+y).a<.15:continue
			left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
	var result:=Rect2i(origin+Vector2i(left,top),Vector2i(maxi(1,right-left+1),maxi(1,bottom-top+1)))
	_regions[key]=result
	return result

static func building_style(record:Dictionary)->Dictionary:
	var plot:Dictionary=record.get("plot",{})
	var status:=String(plot.get("status","active"))
	if status in ["vacant","reclaimed"]:return {}
	var state:=Construction.state(plot)
	var cell:=-1
	var kind:=Early.kind(plot)
	var family:=String(plot.get("material_family",""))
	var use:=String(plot.get("land_use",""))
	var form:=String(plot.get("form",""))
	if state.mode=="retrofit":return {} # Preserve the original actual scaffold.
	var active_frame:=_construction_style(plot,state)
	if not active_frame.is_empty():return active_frame
	var matching_roof:=_recorded_roof_style(plot,state)
	if not matching_roof.is_empty():return matching_roof
	var workshop:=_workshop_style(plot,state)
	if not workshop.is_empty():return workshop
	if int(plot.get("storeys",1))>1 or int(plot.get("fabric_generation",0))>=4:
		return _mature_style(plot,state)
	var roof:=Late.roof_for(plot)
	match kind:
		"carried_ridge":cell=0
		"carried_round":cell=1
		"rooted_lean_to":cell=2
		"round_household","timber_household":cell=3
		"earthen_household":cell=4
		"rubble_household":cell=5
		"covered_workshop":cell=6
		"raised_store":cell=7
	if cell<0 and form in Early.HOUSEHOLD_FORMS:
		cell=4 if family=="earth" else (5 if family=="stone" else 3)
	if cell<0 and use in ["civic","communal"] and form not in ["open_hearth_yard","maintained_gathering_ground"]:cell=8
	if cell<0:return {}
	if cell in [3,4,5] and roof!="thatch":return {}
	var progress:=1.0
	if state.mode=="new":
		if family!="stone" or cell<3:return {}
		cell=9;progress=[.22,.45,.70,1.0][int(state.stage)]
	elif status=="ruin":
		if family!="stone":return {}
		cell=11
	elif float((plot.get("damage",{}) as Dictionary).get("fire",0))>.25 and cell==4:
		cell=10
	return {"atlas":BUILDINGS,"cell":cell,"rows":3,"condition":clampf(float(plot.get("condition",1.0)),0,1),"progress":progress,"repair":state.mode=="retrofit"}

static func _construction_style(plot:Dictionary,state:Dictionary)->Dictionary:
	if not _exists(STATES) or state.mode!="new" or int(plot.get("storeys",1))!=1:return {}
	if int(plot.get("fabric_generation",0))>=11:return {}
	if String(plot.get("land_use","")) not in ["residential_compound","mixed_household","workshop","storage"]:return {}
	var form:=String(plot.get("form",""))
	if form in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment","lean_to_household_cluster"]:return {}
	var family:=String(plot.get("material_family",""));var cell:=-1
	if family in ["organic","timber"]:cell=0
	elif family=="earth":cell=1
	elif family=="stone":cell=2
	if cell<0:return {}
	return {"atlas":STATES,"cell":cell,"rows":2,"columns":3,"condition":clampf(float(plot.get("condition",1.0)),0,1),"progress":[.20,.43,.72,1.0][int(state.stage)]}

static func _recorded_roof_style(plot:Dictionary,state:Dictionary)->Dictionary:
	if not _exists(ROOFS) or not String(state.mode).is_empty():return {}
	if String(plot.get("status",""))=="ruin":return {}
	if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]:return {}
	var form:=String(plot.get("form",""))
	if form in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment","lean_to_household_cluster"]:return {}
	var floors:=int(plot.get("storeys",1));var family:=String(plot.get("material_family",""));var roof:=Late.roof_for(plot);var cell:=-1
	if floors not in [1,2] or int(plot.get("fabric_generation",0))>=11:return {}
	if family=="earth" and roof=="earth":cell=0
	elif family=="stone" and roof=="slab":cell=1
	elif family in ["organic","timber"] and roof=="timber":cell=2
	if cell<0:return {}
	var path:=ROOFS
	# Damage art is restricted to the same installed wall/roof family and
	# floor count. A fire never swaps a hide shelter for a masonry ruin.
	if floors==1 and _exists(STATES) and float((plot.get("damage",{}) as Dictionary).get("fire",0))>.25:
		return {"atlas":STATES,"cell":3+([1,2,0][cell]),"rows":2,"columns":3,"condition":clampf(float(plot.get("condition",1.0)),0,1),"progress":1.0}
	if cell==2 and _exists(VARIANTS):path=VARIANTS;cell=posmod(int(plot.get("seed",plot.get("id",0))),3)
	return {"atlas":path,"cell":cell+(3 if floors==2 else 0),"rows":2,"columns":3,"condition":clampf(float(plot.get("condition",1.0)),0,1),"progress":1.0}

static func _workshop_style(plot:Dictionary,state:Dictionary)->Dictionary:
	if not _exists(WORKSHOP) or not String(state.mode).is_empty():return {}
	if String(plot.get("status",""))=="ruin" or int(plot.get("storeys",1))!=1:return {}
	if String(plot.get("land_use",""))!="workshop" or String(plot.get("material_family","")) not in ["organic","timber"]:return {}
	if Late.roof_for(plot)!="timber" or int(plot.get("fabric_generation",0))>=11:return {}
	return {"atlas":WORKSHOP,"cell":0,"rows":1,"columns":1,"condition":clampf(float(plot.get("condition",1.0)),0,1),"progress":1.0}

static func _mature_style(plot:Dictionary,state:Dictionary)->Dictionary:
	if not _exists(MATURE):return {}
	var floors:=int(plot.get("storeys",1));var generation:=int(plot.get("fabric_generation",0))
	var use:=String(plot.get("land_use",""));var family:=String(plot.get("material_family",""))
	var roof:=Late.roof_for(plot);var cell:=-1
	if generation>=11 or floors>3 or String(plot.get("status",""))=="ruin":return {}
	var applied:Array=(plot.get("building_materials",{}) as Dictionary).get("applied",[])
	var chimney:=false
	for method:String in ["wall_chimneys","multi_flue_chimney_stacks","narrow_throat_fireplace"]:
		if method in applied:chimney=true
	if floors==2 and use in ["residential_compound","mixed_household"] and roof=="thatch":
		if family in ["organic","timber"]:cell=0
		elif family=="earth":cell=1
		elif family=="stone" and chimney:cell=2
	elif floors==3 and use in ["residential_compound","mixed_household"] and family in ["stone","brick"] and roof=="tile" and chimney:cell=3
	elif floors==1 and roof=="thatch" and family in ["organic","timber"]:
		if use=="workshop":cell=4
		elif use=="storage":cell=5
		elif use in ["communal","civic"]:cell=6
	if cell<0:return {}
	if state.mode=="new":return {} # Render actual partial frame, never a finished painting.
	return {"atlas":MATURE,"cell":cell,"rows":2,"condition":clampf(float(plot.get("condition",1.0)),0,1),"progress":1.0}

static func sprite(parent:Node3D,path:String,cell:int,at:Vector3,width:float,options:Dictionary={})->MeshInstance3D:
	var texture:=atlas(path)
	if texture==null:return null
	var crop:=region(path,cell,int(options.get("rows",3)),int(options.get("columns",4)))
	var node:=MeshInstance3D.new();node.name=String(options.get("name","PaintedObject"))
	var mesh:=QuadMesh.new();mesh.size=Vector2.ONE;node.mesh=mesh;node.position=at
	var paint:=ShaderMaterial.new();var shader:=Shader.new();shader.code=SPRITE_SHADER;paint.shader=shader
	paint.set_shader_parameter("art",texture)
	paint.set_shader_parameter("region",Vector4(float(crop.position.x)/texture.get_width(),float(crop.position.y)/texture.get_height(),float(crop.size.x)/texture.get_width(),float(crop.size.y)/texture.get_height()))
	var height:=width*float(crop.size.y)/maxf(1,crop.size.x)
	paint.set_shader_parameter("world_size",Vector2(width,height))
	paint.set_shader_parameter("mirror",bool(options.get("mirror",false)))
	paint.set_shader_parameter("art_tint",options.get("tint",Color.WHITE))
	paint.set_shader_parameter("fire_damage",float(options.get("fire",0.0)))
	paint.set_shader_parameter("wear",1.0-float(options.get("condition",1.0)))
	paint.set_shader_parameter("build_progress",float(options.get("progress",1.0)))
	paint.set_shader_parameter("sway",float(options.get("sway",0.0)))
	paint.set_shader_parameter("phase",float(options.get("phase",0.0)))
	paint.set_shader_parameter("tree_cutaway",bool(options.get("foliage",false)))
	paint.set_shader_parameter("crown_height",height*.60)
	paint.set_shader_parameter("crown_radius",width*.45)
	node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb=AABB(Vector3(-width,-height,-width),Vector3(width*2,height*2,width*2))
	node.set_meta("painted",true);node.set_meta("foliage",bool(options.get("foliage",false)))
	node.set_meta("illustrated_size",Vector2(width,height))
	parent.add_child(node);return node

static func buildings(plan:Dictionary,parent:Node3D,point:Callable)->Dictionary:
	var fallback:Dictionary=plan.duplicate(false);var remaining:Array[Dictionary]=[]
	for record:Dictionary in plan.get("buildings",[]):
		var style:=building_style(record)
		if style.is_empty():remaining.append(record);continue
		var plot:Dictionary=record.plot
		style["fire"]=clampf(float((plot.get("damage",{}) as Dictionary).get("fire",0)),0,1)
		style["phase"]=float(posmod(hash([plot.get("seed",0),record.get("id",0)]),53))*.17
		var palettes:=[Color(.94,.98,1.0),Color(1.0,.96,.92),Color(.96,.94,.92),Color.WHITE]
		style["tint"]=palettes[posmod(hash([plot.get("seed",0),record.get("id",0)]),palettes.size())]
		var radius:=maxf(.0015,float(record.get("radius",.003)))
		var node:=sprite(parent,style.atlas,style.cell,point.call(Vector2(record.position),.00008),radius*2.0,style.merged({"name":"PaintedBuilding_"+str(record.get("id","")),"mirror":sin(float(record.get("angle",0)))<0}))
		if node==null:remaining.append(record)
		else:
			node.set_meta("plot_id",int(record.plot_id));node.set_meta("recorded_form",String(record.plot.get("form","")))
	fallback["buildings"]=remaining
	return fallback

static func hide_replaced_frames(plan:Dictionary,parent:Node3D)->void:
	var node:=parent.get_node_or_null("EarlyCommunalObjects/Prop_frame") as MultiMeshInstance3D
	if node==null:return
	var replaced:Array[Vector2]=[]
	for record:Dictionary in plan.get("buildings",[]):
		if Construction.state(record.plot).mode=="new" and not building_style(record).is_empty():replaced.append(Vector2(record.position))
	var retained:=0
	for index in node.multimesh.instance_count:
		var placement:=node.multimesh.get_instance_transform(index)
		var matching:=false
		for at:Vector2 in replaced:
			if at.distance_squared_to(Vector2(placement.origin.x,placement.origin.z))<.000000000001:matching=true;break
		if matching:
			placement.basis=Basis().scaled(Vector3.ZERO)
			node.multimesh.set_instance_transform(index,placement)
		else:retained+=1
	if retained==0:
		node.visible=false
		var shadow:=parent.get_node_or_null("EarlyCommunalObjects/PropShadow_frame") as Node3D
		if shadow!=null:shadow.visible=false

static func smoke(parent:Node3D,at:Vector3,width:float)->void:
	var node:=MeshInstance3D.new();node.name="RecordedHearthSmoke"
	var mesh:=QuadMesh.new();mesh.size=Vector2.ONE;node.mesh=mesh;node.position=at
	var paint:=ShaderMaterial.new();var shader:=Shader.new();shader.code=SMOKE_SHADER;paint.shader=shader
	paint.set_shader_parameter("world_size",Vector2(width,width*1.5))
	node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb=AABB(Vector3(-width,0,-width),Vector3(width*2,width*2,width*2))
	node.set_meta("painted",true);parent.add_child(node)

const SMOKE_SHADER:="""shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_never,cull_disabled,shadows_disabled,skip_vertex_transform;
uniform vec2 world_size=vec2(.0045,.007);
uniform float anim_clock=0.0;
varying vec2 uv;
void vertex(){
vec4 anchor=MODELVIEW_MATRIX*vec4(0,0,0,1);
VERTEX=anchor.xyz+vec3((UV.x-.5)*world_size.x,(1.0-UV.y)*world_size.y,0);
uv=UV;
}
void fragment(){
float y=1.0-uv.y;
float bend=sin(y*5.0-anim_clock*.45)*.09*y;
float center=.5+bend+y*.1;
float shape=1.0-smoothstep(.05+y*.12,.10+y*.28,abs(uv.x-center));
float pulse=.7+.3*sin(y*15.0-anim_clock*1.2);
ALBEDO=vec3(.57,.57,.51);ALPHA=shape*pulse*smoothstep(0.0,.15,y)*(1.0-y)*.18;
}
"""

const SPRITE_SHADER:="""shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_disabled, shadows_disabled, skip_vertex_transform;
uniform sampler2D art : source_color, filter_linear_mipmap;
uniform vec4 region=vec4(0,0,1,1);
uniform vec2 world_size=vec2(.006,.006);
uniform vec4 art_tint : source_color=vec4(1.0);
uniform float fire_damage=0.0;
uniform float wear=0.0;
uniform bool mirror=false;
uniform float build_progress=1.0;
uniform float sway=0.0;
uniform float phase=0.0;
uniform float anim_clock=0.0;
uniform bool tree_cutaway=false;
uniform float crown_height=.005;
uniform float crown_radius=.003;
uniform vec3 focus_world=vec3(0);
uniform float focus_radius=.003;
uniform float focus_cutaway=0.0;
varying vec3 crown;
void vertex(){
vec4 anchor=MODELVIEW_MATRIX*vec4(0,0,0,1);
float wind=sin(anim_clock*.7+phase+UV.y*2.0)*sway*pow(1.0-UV.y,2.0);
VERTEX=anchor.xyz+vec3((UV.x-.5)*world_size.x+wind,(1.0-UV.y)*world_size.y,0);
NORMAL=vec3(0,0,1);
crown=(MODEL_MATRIX*vec4(0,crown_height,0,1)).xyz;
}
float paint_noise(vec2 p){
vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
vec3 k=vec3(127.1,311.7,43758.5453);
float a=fract(sin(dot(i,k.xy))*k.z);float b=fract(sin(dot(i+vec2(1,0),k.xy))*k.z);
float c=fract(sin(dot(i+vec2(0,1),k.xy))*k.z);float d=fract(sin(dot(i+vec2(1),k.xy))*k.z);
return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
void fragment(){
vec2 sample_uv=vec2(mirror ? 1.0-UV.x : UV.x,UV.y);
vec4 color=texture(art,region.xy+sample_uv*region.zw);
float grey=dot(color.rgb,vec3(.25,.55,.2));
ALBEDO=mix(color.rgb,mix(color.rgb,vec3(grey)*vec3(.78,.72,.64),.5),wear*.5)*art_tint.rgb;
float roof=1.0-smoothstep(.12,.66,UV.y);
float soot=fire_damage*(.35+.8*paint_noise(UV*7.0+phase))*(.35+roof*.9);
ALBEDO=mix(ALBEDO,vec3(.035,.027,.018),clamp(soot,0.0,.88));
float hole=smoothstep(.63,.83,paint_noise(UV*12.0+phase))*roof*clamp((fire_damage-.30)*1.4,0.0,.9);
float cut=0.0;
if(tree_cutaway){
 vec3 eye=INV_VIEW_MATRIX[3].xyz;vec3 ray=focus_world-eye;float reach=max(length(ray),.0001);vec3 axis=ray/reach;
 float depth=dot(crown-eye,axis);float radial=length(crown-eye-axis*depth);
 float aperture=focus_radius*clamp(depth/reach,.05,1.0)+crown_radius*.8;
 cut=(1.0-smoothstep(aperture*.65,aperture,radial))*step(0.0,depth)*(1.0-step(reach-.0003,depth))*focus_cutaway;
}
ALPHA=color.a*(1.0-cut*.985)*(1.0-hole)*smoothstep(1.0-build_progress-.025,1.0-build_progress+.025,UV.y);
ALPHA_SCISSOR_THRESHOLD=.035;
}
"""
