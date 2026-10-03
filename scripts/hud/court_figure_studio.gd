extends Node
## Stills of the modelled court figures, for the places that show a person
## as a picture rather than on the live stage: the court at rest (each
## official standing about the fire) and the small portraits beside the
## history, the rosters and the envoy channel.
## One hidden SubViewport renders one still a frame, on request, into an
## ImageTexture handed out at once (it fills in a frame or two later); the
## same person in the same framing is rendered once. When the models cannot
## be drawn (a headless run, or they fail) the caller's painting is kept.
## Presentation only.

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
## "full": standing, head to foot; "bust": head and shoulders.
const FRAMINGS:={"full":Vector2i(208,340),"bust":Vector2i(112,128)}
const CACHE_LIMIT:=160

static var _instance:Node
static var _cache:Dictionary={}

var view:SubViewport
var camera:Camera3D
var figures:Dictionary={}      # variant -> Figure3D (one each, dressed per still)
var queue:Array=[]
var busy:=false

static func available()->bool:
	return DisplayServer.get_name()!="headless" and Figure3D.available()

## A still of a look in a framing. fallback: the painting to show if the
## model cannot be drawn. Returns a texture at once.
static func still(look:Dictionary,framing:String,fallback:Texture2D=null,pose:="idle_clasped")->Texture2D:
	if not available():return fallback
	var key:="%s|%s|%s" % [framing,pose,var_to_str(look).hash()]
	if _cache.has(key):return _cache[key]
	if _cache.size()>=CACHE_LIMIT:_cache.erase(_cache.keys()[0])
	var dims:Vector2i=FRAMINGS.get(framing,FRAMINGS.full)
	var blank:=Image.create_empty(dims.x,dims.y,false,Image.FORMAT_RGBA8)
	var made:=ImageTexture.create_from_image(blank)
	_cache[key]=made
	var studio:=_studio()
	if studio==null:return fallback
	studio.queue.append({"texture":made,"look":look,"framing":framing,"pose":pose,"fallback":fallback})
	studio.call_deferred("_work")
	return made

static func _studio()->Node:
	if is_instance_valid(_instance):return _instance
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null or tree.root==null:return null
	_instance=(load("res://scripts/hud/court_figure_studio.gd") as GDScript).new()
	_instance.name="CourtFigureStudio"
	tree.root.add_child.call_deferred(_instance)
	return _instance

func _ready()->void:
	view=SubViewport.new();view.name="Stills";view.transparent_bg=true;view.own_world_3d=true
	view.msaa_3d=Viewport.MSAA_4X;view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	view.size=FRAMINGS.full
	add_child(view)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true
	view.add_child(camera)
	if not queue.is_empty():_work()

func _work()->void:
	if busy or not is_inside_tree() or view==null:return
	busy=true
	while not queue.is_empty():
		var job:Dictionary=queue.pop_front()
		var made:ImageTexture=job.texture
		var image:Image=await _render(job)
		if image!=null and not image.is_empty():
			image.convert(Image.FORMAT_RGBA8)
			if image.get_size()==Vector2i(made.get_size()):made.update(image)
			else:made.set_image(image)
		elif job.fallback is Texture2D:
			var painted:=(job.fallback as Texture2D).get_image()
			if painted!=null and not painted.is_empty():
				painted.convert(Image.FORMAT_RGBA8);painted.resize(made.get_width(),made.get_height())
				made.update(painted)
	busy=false

func _render(job:Dictionary)->Image:
	var look:Dictionary=job.look
	var variant:=String(look.get("variant","male_adult"))
	var fig:Node3D=figures.get(variant)
	if fig==null:
		fig=Figure3D.new();fig.name="Sitter_"+variant
		view.add_child(fig)
		figures[variant]=fig
	for other:Node3D in figures.values():other.visible=other==fig
	if not fig.setup(look):return null
	fig.rotation_degrees.y=10.0
	fig.play(String(job.pose),0.0,1.2)
	if fig.player!=null:fig.player.advance(0.0)
	var dims:Vector2i=FRAMINGS.get(String(job.framing),FRAMINGS.full)
	view.size=dims
	var height:float=fig.body_height
	if String(job.framing)=="bust":
		camera.size=height*0.30
		camera.position=Vector3(0.0,height*0.86,6.0)
	else:
		camera.size=Figure3D.REFERENCE_HEIGHT*1.05
		camera.position=Vector3(0.0,Figure3D.REFERENCE_HEIGHT*1.05*0.5-0.01,6.0)
	camera.rotation=Vector3.ZERO
	view.render_target_update_mode=SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var texture:=view.get_texture()
	return texture.get_image() if texture!=null else null
