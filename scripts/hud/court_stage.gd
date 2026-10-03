extends Control
## The court as a stage: the people present stand in the hall as modelled,
## animated figures, and what is said pops up above the one who says it.
## Presentation only. Nothing here decides anything: the hall
## (audience_hall.gd) and the court's engines decide, and the Court
## (audience_modal.gd) hands each line that was said to this stage.
##  - Figures: each person as a modelled figure (court_figure_3d.gd, made in
##    Blender by tools/blender/court_figures.py) in their people's colours and
##    their age's dress, all in one SubViewport behind the stage's plates and
##    bubbles. How a person looks is read through figure_look() alone (their
##    people's appearance profile, their sex and age, their people's era).
##    They breathe, turn to whoever speaks and listen, talk with their hands,
##    lift their faces when the god speaks, walk in when summoned, kneel in
##    dread, bow in reverence, and walk out when they take their leave. Where
##    the models cannot be shown the painted figures of before stand instead.
##  - Speech: a paper bubble above the speaker with its tail on them. The
##    words come at a reading pace; a click finishes them, a second moves on.
##    The bubble before it fades and the one before that goes.
##  - The god's own words come from above: a gold-ruled band, light falling.
##  - What the engine decided is a caption at the foot of the stage, never a
##    character's line.
## Per frame it does nothing: every movement is a tween made once.

signal advance_requested
## "more" was pressed on words cut short: show that entry of the history.
signal history_requested(ref:int)

const Self:=preload("res://scripts/hud/court_stage.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Studio:=preload("res://scripts/hud/court_figure_studio.gd")
const Looks:=preload("res://scripts/people_appearance.gd")
const EarlyArt:=preload("res://scripts/hud/early_civ_art.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const DivineRegard:=preload("res://scripts/divine_regard.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const FigureLook:=preload("res://scripts/hud/court_figure_look.gd")
const Paths:=preload("res://scripts/hud/court_paths.gd")

const MAIN:="main"
const BUBBLE_PAPER:=Color("fbf4e4")
const ASIDE_PAPER:=Color("efe5cf")
const BUBBLE_INK:=Color("2a2217")
const BUBBLE_RULE:=Color("6b5638")
const KICKER_INK:=Color("6b5638")
const CAPTION_PAPER:=Color(0.93,0.88,0.77,0.96)
const CAPTION_INK:=Color("3b2f22")
const CAPTION_RULE:=Color("8a6d45")
const GOD_PAPER:=Color("f8eed4")
const GOD_INK:=Color("54380a")
const GOD_GOLD:=Color("b8862a")
const WARN_INK:=Color("84372b")
const PLATE_BG:=Color(.07,.055,.04,.80)
const CREAM:=Color("f6ecd6")
const CREAM_DIM:=Color("e2d3b4")
## Reading pace: about forty letters a second, then a pause to read them.
const REVEAL_PER_CHAR:=0.025
const TAIL:=16.0
## The strip at the foot of the stage where the name plates stand.
const PLATE_ROOM:=54.0
## Where the court stands, as fractions of the stage's width.
const HOME_MAIN_X:=0.40
const HOME_COURT_X:=[0.66,0.14,0.80,0.93,0.27,0.53]
const ENVOY_MAIN_X:=0.26
const ENVOY_ATTENDANT_X:=[0.09,0.42]
const ENVOY_COURT_X:=[0.88,0.70,0.54,0.96]
## How far back each slot stands when the figures are modelled (0 nearest).
const ARC_DEPTH_HOME:=[1,1,0,2,2,3]
const ARC_DEPTH_ENVOY:=[1,2,0,2]
## Bystanders stand at the back and the sides, behind the court.
const CROWD_X:=[0.07,0.95,0.20,0.82,0.50]
## A figure's width for its height: a standing person, not the whole painting.
const FIGURE_ASPECT:=0.60
## The modelled figures: a stage pixel is this many metres of the 3D world,
## the camera looks a little down, and a figure's box holds a person of
## Figure3D.REFERENCE_HEIGHT (shorter people stand shorter in it).
const PX_M:=0.01
const CAMERA_PITCH:=-12.0
const FIGURE_FILL:=0.95
## Room under the feet for the name plate when the figures are modelled.
const FOOT_ROOM:=40.0
## The dress of each age of a people (Voice.era_tier): hides, then woven
## tunics, then robes for those of rank and later for all.
const ERA_DRESS:=["hide","tunic","tunic","robe"]
const HIGH_TITLES:=["chief","king","queen","ruler","lord","lady","elder","priest","speaker","steward","envoy","high","prince","headman","headwoman"]

const FIGURE_SHADER:="""
shader_type canvas_item;
// A painted person in an arched niche of light: the painting's own ground
// melts away at the sides, over the head and into the floor.
uniform vec2 box=vec2(100.0,200.0);
uniform float feather=0.40;
uniform float floor_fade=0.18;
varying vec2 local;
void vertex(){local=VERTEX;}
void fragment(){
	vec2 p=clamp(local/max(box,vec2(1.0)),vec2(0.0),vec2(1.0));
	float dx=abs(p.x-0.5)*2.0;
	float arch=clamp(0.5*box.x/max(box.y,1.0),0.05,0.6);
	float r=dx;
	if(p.y<arch){float ey=(arch-p.y)/arch;r=length(vec2(dx,ey));}
	float m=1.0-smoothstep(1.0-feather,1.0,r);
	m*=smoothstep(0.0,floor_fade,1.0-p.y);
	COLOR.a*=m;
}
"""
static var _shader:Shader

## "home" (someone of ours before the god) or "envoy" (a foreign envoy and
## their attendants, with our officials looking on).
var layout_kind:="home"
## Pixels covered at the top (a herald band) and kept free at the right (the
## offered object on its plinth).
var top_inset:=0.0
var right_reserve:=0.0
var compact:=false
## The screen's portrait registry: nobody shares a painting with another.
var registry:Dictionary={}
var figures:Dictionary={}      # key -> Figure
var cast_order:Array[String]=[]
var figure_layer:Control
var god_layer:Control
var bubble_layer:Control
var caption_layer:Control
var thinking:Label
var speaking_key:=""
var _god:Bubble
var _rays:Rays
var _god_age:=0
var _caption:Bubble
var _caption_age:=0
var _laid_out:=false
var _arrivals:Array[String]=[]
## The seams others plug into (docs/COURT_STAGE_3D.md §5). While a hook is
## null the stage's own behaviour stands in. Presentation only.
static var set_builder:Object     # M: build(era, facts) -> Node3D with marks
static var camera_rig:Object      # M: attach(stage, camera, set_root); shot(name, args)
static var acting:Object          # K: play / look_at / set_mood / speak / idle
static var director:Object        # L: beats / ambient / asides
static var sound:GDScript         # N: court_sound.gd (attach(stage) -> Node; on_event; on_beat); null: a silent court
## The bystanders' muttered lines, a setting (the director reads it here).
static var mutters_enabled:=true
## Head-and-shoulders close-ups (push_in with close): off until the faces
## hold up that near; the strongest push is then the camera's own push-in
## (chest-up). Turn on with the camera's close_up (M).
static var close_ups_enabled:=false
## The Court installs L's director while this is on (tests may turn it off).
static var directing:=true
## Off for a run (tests): no modelled court, the figures stand before the
## painted backdrop under the stage's own camera.
static var use_sets:=true
## The court's modelled place (court_set_3d.gd, M) when there is one: the
## people stand on its marks, its camera frames them, its lights fall on them.
var court_set:Node3D
## The set's camera rig (M): shots, insets, the view's changes.
var rig:Node
## Which mark each person holds (mark name -> cast key).
var _marks:Dictionary={}
var _hush_tween:Tween
var _bearer_chosen:=false
## The court's sound (N), once the stage stands in the tree.
var _sound:Node
## The beats the director gave for the last event (an exit or an arrival
## reads them: backing out bowing, coming back, the wrong side).
var _last_beats:Array=[]
## The camera's current claim: a shot holds until its event's beats are
## done, unless a weightier event comes (wrath, the god > an arrival, a
## decision > speech > the room's own life).
var _shot_until:=0.0
var _shot_weight:=0
var _event_weight:=1
var _event_end:=0.0
## Whose face the camera has gone in on (bubbles keep off it).
var _focus_key:=""
var _beat_sets:Array=[]
## What the engine says about the hall now (the Court fills it): era, season,
## stores_days, hungry, sick, at_war, love, dread, mood, offer.
var facts:Dictionary={}
## Which audience this is (seeds the director: the same audience plays the same).
var audience_key:=""
var _event_index:=0
var _beats:Tween
## The room's own life (L's ambient loops), paused while the room is hushed.
var _hush_until:=0.0
var _ambient:Array=[]
var _ambient_timer:Timer
var _ambient_rng:=RandomNumberGenerator.new()
## Bystanders and animals the director brings (no game person behind them).
var extras:Dictionary={}
## The modelled figures' layer: one SubViewport for the whole stage.
var three_d:=false
var view_container:SubViewportContainer
var view3d:SubViewport
var camera:Camera3D
var _talks:=0

static func figure_shader()->Shader:
	if _shader==null:
		_shader=Shader.new();_shader.code=FIGURE_SHADER
	return _shader

## The one place the court's figures read a person's picture. A people's
## appearance (early_art_profile, read by person_portrait.gd) drives it, and
## the screen's registry keeps two people from sharing one painting.
static func figure_picture(person:Dictionary,screen_registry:Dictionary)->Dictionary:
	var slot:Array=Portrait.claim(screen_registry,person)
	return {"texture":Portrait.slot_texture(person,slot),"flip":slot.size()>1 and bool(slot[1]),"slot":slot}

## The one place the court reads how a person looks as a modelled figure:
## their people's appearance profile (people_appearance.gd: skin range, hair
## colours, three dyes), their sex and age, and their people's era for their
## dress. The same person always looks the same; on one screen (the
## registry) no two people are dressed and coloured alike.
static var _era_cache:Dictionary={}
static func figure_look(person:Dictionary,screen_registry:Dictionary={})->Dictionary:
	var owner:=EarlyArt.owner(person)
	var seed_value:=int(person.get("appearance_world_seed",GameState.world_seed if GameState!=null else 0))
	var people:Dictionary=Looks.profile(owner,seed_value)
	var identity:="%s|%d|%s" % [owner,int(person.get("person_id",0)),String(person.get("name","someone"))]
	var h:=absi(identity.hash())
	var sex:=String(person.get("sex",""))
	if not sex in ["male","female"]:sex="female" if (h>>2)%2==1 else "male"
	var years:=_age_years(person,h)
	var band:="young" if years<24 else ("old" if years>=56 else "adult")
	var title:=String(person.get("office_title",person.get("title",""))).to_lower()
	var high:=false
	for word:String in HIGH_TITLES:
		if title.contains(word):high=true;break
	var tier:=_era_tier(owner)
	var outfit:=String(ERA_DRESS[clampi(tier,0,ERA_DRESS.size()-1)])
	if tier==2 and (high or band=="old"):outfit="robe"
	# Skin within the people's range, hair of their colours, greying with age.
	var skins:Array=people.get("skin",["bd8659","9f6a43","7d4e2f"])
	var t:=float((h>>3)%97)/96.0
	var skin:=Color(String(skins[0])).lerp(Color(String(skins[2])),t) if skins.size()>=3 else Color("bd8659")
	var hairs:Array=people.get("hair",["2b2018"])
	var hair_colour:=Color(String(hairs[(h>>5)%maxi(1,hairs.size())]))
	# Grey comes in with age, iron before it is white.
	if years>=56:hair_colour=hair_colour.lerp(Color("a8a299"),clampf(float(years-50)/24.0,0.40,0.82))
	elif years>=44:hair_colour=hair_colour.lerp(Color("8f8a82"),0.22)
	var words:=String(people.get("hair_words","")).to_lower()
	var coiled:=words.contains("coil") or words.contains("curl") or words.contains("spring")
	var styles:Array
	if sex=="female":styles=["curls","bun","braids","long_framed"] if coiled else ["long_framed","braids","bun","long","tail"]
	else:styles=["curls","cropped","topknot"] if coiled else ["cropped","long","tail","topknot","cropped"]
	# Old men: many have lost the crown, some keep it short or long.
	if band=="old" and sex=="male":styles=["balding","balding","cropped","long","balding"] if not coiled else ["curls","balding","cropped"]
	elif sex=="male" and years>=40 and (h>>17)%4==0:styles=["balding"]
	if sex=="male" and not coiled and (h>>15)%7==0:styles=["shaved"]
	# Most men are shaven or stubbled; a few wear one of the beards of their age.
	var beard:=""
	if sex=="male":
		var roll:=(h>>9)%100
		if band=="old":beard="beard_long" if roll<28 else ("beard_short" if roll<50 else ("beard_full" if roll<62 else ("beard_moustache" if roll<70 else "")))
		elif band=="adult":beard="beard_stubble" if roll<22 else ("beard_short" if roll<34 else ("beard_chin" if roll<42 else ("beard_moustache" if roll<48 else ("beard_full" if roll<52 else ""))))
		elif roll<18:beard="beard_stubble"
	# Each person wears the people's three dyes in their own order.
	var dyes:Array=people.get("cloth",["a8432f","2f4a6e","c9a43c"])
	var order:Array=[[0,1,2],[1,2,0],[2,0,1],[0,2,1],[1,0,2],[2,1,0]][(h>>11)%6]
	var cloth:Array=[]
	for i in 3:cloth.append(Color(String(dyes[int(order[i])%dyes.size()])))
	var without:Array=[]
	if outfit=="hide":
		# Hides are hides: the dye shows as a stain and in the cord.
		cloth[0]=Color("9c7a52").lerp(cloth[0],0.28);cloth[1]=Color("6e5541").lerp(cloth[1],0.12)
		if not (high or band=="old" or (h>>13)%3==0):without.append("hide_cape")
	# A stance kept for life: the old sit or lean on a staff, the young crouch
	# or stand easy, those of rank stand clasped, folded or with a staff.
	var stances:Array=["stand","hip","folded","clasped","belt","bowl"]
	if band=="old":stances=["sit","staff","clasped","folded","sit"]
	elif band=="young":stances=["stand","hip","crouch","belt","stand"]
	if high:stances=["staff","clasped","folded","stand"]
	# A family face: the people share a look, and each person differs within it.
	var face:={}
	var family_seed:=absi(String(people.get("family","stoneweft")).hash())
	for index in Figure3D.FACE_SHAPES.size():
		var shape:String=Figure3D.FACE_SHAPES[index]
		if shape=="aged":continue
		var family:=float((family_seed>>(index%20))%101)/50.0-1.0
		var own:=float(absi(("%s|%s" % [identity,shape]).hash())%101)/50.0-1.0
		face[shape]=clampf(family*0.55+own*0.45,-1.0,1.0)
	if years>=46:face["aged"]=clampf(float(years-46)/24.0,0.0,1.0)
	var look:={"variant":"%s_%s" % [sex,band],"outfit":outfit,"hair":String(styles[(h>>7)%styles.size()]),"beard":beard,
		"skin":skin,"hair_colour":hair_colour,"cloth":cloth,"leather":Color("5b3b24").lerp(cloth[1],0.15),"without":without,
		"stance":String(stances[(h>>19)%stances.size()]),"face":face,"mood":"neutral","seed":h}
	# Their years when the game knows them (a child gets a child's body, J's
	# FigureLook; without them the figure reads its age from the face).
	var known:Variant=person.get("age",null)
	if known is int or known is float:look["years"]=int(known)
	elif String(known if known!=null else "").to_lower()=="child":look["years"]=9
	# Two people on one screen are never dressed and coloured alike.
	if screen_registry!=null:
		var taken:Dictionary=screen_registry.get("_look_of",{})
		if taken.has(identity):return taken[identity]
		var used:Dictionary=screen_registry.get("_looks",{})
		var turn:=0
		while used.has(_look_key(look)) and turn<6:
			turn+=1
			look.hair=String(styles[((h>>7)+turn)%styles.size()])
			look.cloth=[cloth[turn%3],cloth[(turn+1)%3],cloth[(turn+2)%3]]
		used[_look_key(look)]=true;taken[identity]=look
		screen_registry["_looks"]=used;screen_registry["_look_of"]=taken
	return look

static func _look_key(look:Dictionary)->String:
	return "%s|%s|%s|%s" % [look.variant,look.hair,look.outfit,(look.cloth[0] as Color).to_html(false)]

static func _age_years(person:Dictionary,h:int)->int:
	var raw:Variant=person.get("age",null)
	if raw is int or raw is float:return int(raw)
	match String(raw if raw!=null else "").to_lower():
		"child","young","youth":return 18
		"old","oldest","elder","aged":return 66
		"adult","grown":return 35
	return 24+(h>>17)%30

static func _era_tier(owner:String)->int:
	var day:=int(GameState.elapsed_days) if GameState!=null else 0
	var key:="%s|%d" % [owner,day]
	if not _era_cache.has(key):
		if _era_cache.size()>32:_era_cache.clear()
		_era_cache[key]=Voice.era_tier(Voice.era_tags(owner))
	return int(_era_cache[key])

## A small picture of a person (rosters, the history, the envoy channel),
## read through the same seam as the figures: a still of their modelled
## figure where it can be drawn, their painting where it cannot.
static func picture_rect(person:Dictionary,screen_registry:Dictionary,width:float,height:float)->TextureRect:
	var picture:=figure_picture(person,screen_registry)
	var image:=TextureRect.new();image.name="Portrait";image.flip_h=bool(picture.flip)
	if Studio.available():
		image.texture=Studio.still(figure_look(person,screen_registry),"bust",picture.texture);image.flip_h=false
	else:image.texture=picture.texture
	image.custom_minimum_size=Vector2(width,height);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.tooltip_text=String(person.get("name",""));image.set_meta("person_id",int(person.get("person_id",0)))
	image.set_meta("figure_slot",picture.slot)
	return image

## A standing figure on its own (the court at rest seats them about the fire):
## a still of their modelled figure where it can be drawn, else their painting.
static func make_figure(person:Dictionary,screen_registry:Dictionary,name_text:String="",title_text:String="",big:=false)->Figure:
	var made:=Figure.new()
	made.person=person
	var picture:=figure_picture(person,screen_registry)
	if Studio.available():
		made.painting.cutout=true
		made.painting.texture=Studio.still(figure_look(person,screen_registry),"full",picture.texture)
	else:
		made.painting.texture=picture.texture;made.painting.flip=bool(picture.flip)
	made.set_names(name_text,title_text,big)
	return made

static func reveal_time(text:String)->float:
	return clampf(text.length()*REVEAL_PER_CHAR,0.35,4.0)

## How long a line stays before the next one comes, once it is all shown.
static func hold_time(text:String)->float:
	return clampf(0.8+text.length()*0.018,1.0,3.2)

static func node_key(key:String)->String:
	return key.replace(":","_").replace("/","_").replace(" ","_").replace(".","_").replace("@","_")

func _init()->void:
	name="CourtStage"
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true
	three_d=Figure3D.available()
	if three_d:_make_view()
	figure_layer=_layer("Figures");god_layer=_layer("FromAbove");bubble_layer=_layer("Bubbles");caption_layer=_layer("Captions")
	resized.connect(_on_resized)

func _ready()->void:
	if sound!=null and _sound==null:
		var made:Variant=sound.call("attach",self)
		if made is Node:_sound=made
	if _sound!=null and _sound.has_signal("music_changed") and not _sound.is_connected("music_changed",_on_music):_sound.connect("music_changed",_on_music)
	_ambience()
	_attach_rig()

## A visible musician (N's music, K's playing clips): seated by the fire when
## the people know an instrument and the acting can play it; otherwise the
## music plays off to one side and nobody is stood up for it.
func add_musician()->void:
	if _sound==null or not _sound.has_method("music_state") or extras.has("musician") or court_set==null:return
	var key:=String((_sound.call("music_state") as Dictionary).get("key",""))
	if key.is_empty() or sound==null:return
	var band:Dictionary=(sound.call("music_spec",key) as Dictionary).get("ensemble",{})
	var lead:=String(band.get("lead","hum"))
	if lead=="hum" or acting==null or not Acting.has_clip("play_"+lead):return
	add_extra({"key":"musician","role":"crowd","kind":"musician","stance":"sit","name":"the musician","age":34,
		"instrument":lead,"drum":String(band.get("drum",""))})

func _on_music(state:String)->void:
	var f:=figure("musician")
	if f==null or f.body3d==null or f.leaving or acting==null:return
	var lead:=String((extras.get("musician",{}) as Dictionary).get("instrument",""))
	match state:
		"play":Acting.play(f.body3d,"play_"+lead,{"loop":true})
		"stop_dead":
			Acting.play(f.body3d,"freeze_mid_note",{"hold":true})
			f.body3d.look_at_point(god_point(true),0.35)
		"tentative":
			Acting.play(f.body3d,"glance_up")
			Acting.play(f.body3d,"play_"+lead,{"loop":true,"speed":0.7})
		"flourish":Acting.play(f.body3d,"flourish_"+lead)
		"rest":Acting.stop(f.body3d,0.4)

## The set's rig takes the stage's lens once everyone stands in the tree.
var _rig_attached:=false
func _attach_rig()->void:
	if _rig_attached or rig==null or rig==camera or court_set==null or not court_set.is_inside_tree():return
	if rig.has_method("attach"):rig.call("attach",self,camera,court_set)
	_rig_attached=true

## The room's own sound for this place and season (N): the beds and the
## room's life, from the facts.
func _ambience()->void:
	if _sound==null or not is_instance_valid(_sound):return
	var kind:="fire_ring"
	if court_set!=null and court_set.get("kind")!=null:kind=String(court_set.get("kind"))
	_sound.call("ambience",kind,String(facts.get("season","summer")),facts)

## One transparent SubViewport under the plates and bubbles: every modelled
## figure on this stage stands in it, seen by one camera that maps the
## stage's pixels onto the hall (layout() still decides where people stand).
func _make_view()->void:
	view_container=SubViewportContainer.new();view_container.name="Figures3D";view_container.stretch=true
	view_container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(view_container);view_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view3d=SubViewport.new();view3d.name="Hall3D";view3d.transparent_bg=true;view3d.own_world_3d=true
	view3d.msaa_3d=Viewport.MSAA_2X;view3d.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	view3d.size=Vector2i(64,64)
	view_container.add_child(view3d)
	camera=Camera3D.new();camera.name="Camera";camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.near=0.5;camera.far=200.0;camera.current=true
	view3d.add_child(camera)
	_frame_camera()

## The court's modelled place for this era (court_set_3d.gd): built into the
## hall's view, its camera in place of the flat one, its key light on every
## figure. Call before anyone is added. false (nothing changes) without sets.
func use_set(era_id:String,set_facts:Dictionary={})->bool:
	if not three_d or not use_sets or court_set!=null or view3d==null or not CourtSet.available():return false
	court_set=CourtSet.build(era_id,set_facts)
	if court_set==null:return false
	view3d.add_child(court_set)
	view3d.transparent_bg=false
	view3d.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	var lens:Camera3D=court_set.get("camera")
	if is_instance_valid(camera) and camera!=lens:camera.queue_free()
	camera=lens
	camera.current=true
	# M's camera rig drives the set's lens (round 2); the round-1 camera was
	# the lens itself. Shots, insets and the view's changes go through it.
	var made_rig:Variant=court_set.get("rig")
	rig=made_rig if made_rig is Node else camera
	if rig.has_signal("view_changed"):rig.connect("view_changed",_on_view_changed)
	if is_inside_tree():_attach_rig()
	# The set's light is known once it stands in the tree.
	court_set.ready.connect(func()->void:
		if is_instance_valid(court_set):Figure3D.set_key_light(court_set.call("key_dir")))
	visibility_changed.connect(func()->void:
		if not is_instance_valid(court_set):return
		# Hidden: the god's light goes out at once (M).
		if not is_visible_in_tree() and court_set.has_method("god_light"):court_set.call("god_light",null,"off",0.0,0.0)
		court_set.call("set_active",is_visible_in_tree()))
	return true

## A mark of the set in the world (the door, the fire), or the origin.
func set_point(mark_name:String)->Vector3:
	if court_set==null or not court_set.call("has_mark",mark_name):return Vector3.ZERO
	return (court_set.call("mark",mark_name) as Marker3D).global_position

func _on_view_changed()->void:
	_track_all()
	_replace_all()

func _track_all()->void:
	for key in cast_order:
		var f:=figure(key)
		if f!=null:f._track()

## The camera takes in everyone standing before the god (the seated
## onlookers are seen over their shoulders), clear of the UI laid over it.
func frame_cast(time:=0.0)->void:
	if court_set==null or camera==null or not camera.is_inside_tree():return
	# A shot still holding (a push-in on the one before the god) is not cut
	# back to everyone by a newcomer or a resize.
	if _now()<_shot_until and _shot_weight>=2 and time>0.0:return
	_focus_key=""
	if rig==null:return
	rig.call("set_insets",top_inset,FOOT_ROOM*.6,0.0,right_reserve)
	var subjects:=[]
	var lead:Variant=null
	for key in cast_order:
		var f:=figure(key)
		if f==null or f.leaving or f.spot==null or f.role=="crowd":continue
		subjects.append(f.spot)
		if f.role==MAIN:lead=f.spot
	if subjects.is_empty():subjects.append(set_point("petitioner"))
	# The one before the god leads the frame (the rest are kept around them).
	if lead!=null:rig.call("wide",subjects,time,lead)
	else:rig.call("wide",subjects,time)

## Where a newcomer stands in the set: the one before the god on the
## petitioner's mark (an envoy on the envoy's), their company on the marks
## behind, our officials in the arc about the fire, onlookers on the logs
## and at the back. "" when every mark is taken.
func _take_mark(f:Figure)->String:
	# M's assignment for the whole cast as it stands (main first, then the
	# company, officials, the seated and the standing), kept for everyone
	# already placed; the old search below when it cannot place them.
	if court_set.has_method("assign_marks"):
		var entries:=[]
		for key in cast_order:
			var other:=figure(key)
			if other==null or other==f:continue
			entries.append({"key":key,"role":other.role,"stance":String(other.body3d.stance) if other.body3d!=null else ""})
		entries.append({"key":f.key,"role":f.role,"stance":String(f.body3d.stance) if f.body3d!=null else ""})
		var assigned:Dictionary=court_set.call("assign_marks",entries,layout_kind)
		var name_out:=String(assigned.get(f.key,""))
		if not name_out.is_empty():
			var holder:=figure(String(_marks.get(name_out,"")))
			if holder==null or holder.leaving or holder==f:
				_marks[name_out]=f.key
				return name_out
	var wanted:Array=[]
	var crowd_marks:Array=[]
	for m:Marker3D in court_set.call("marks_for","crowd_"):crowd_marks.append(String(m.name))
	match f.role:
		MAIN:wanted=["petitioner","envoy_0"] if layout_kind=="home" else ["envoy_0","petitioner"]
		"attendant":wanted=["envoy_1","envoy_2"]
		"crowd":wanted=crowd_marks
		_:
			for m:Marker3D in court_set.call("marks_for","officials_"):wanted.append(String(m.name))
			for name in crowd_marks:
				var m:Marker3D=court_set.call("mark",name)
				if not bool(m.get_meta("sit",false)):wanted.append(name)
	for name in wanted:
		if not court_set.call("has_mark",String(name)):continue
		var holder:=figure(String(_marks.get(name,"")))
		if holder!=null and not holder.leaving and holder!=f:continue
		_marks[name]=f.key
		return String(name)
	return ""

func _frame_camera()->void:
	if camera==null or court_set!=null:return
	var w:=maxf(size.x,64.0);var h:=maxf(size.y,64.0)
	camera.size=h*PX_M
	camera.rotation_degrees=Vector3(CAMERA_PITCH,0.0,0.0)
	camera.position=Vector3(w*.5*PX_M,-h*.5*PX_M,0.0)+camera.basis.z*80.0

## Where a stage pixel lies in the hall, this far from the camera.
func stage_to_world(px:Vector2,depth:float)->Vector3:
	if camera==null or not camera.is_inside_tree():
		return Vector3(px.x*PX_M,-px.y*PX_M,80.0-depth)
	return camera.project_position(px,depth)

## Where the god is, for those who answer or look up: before the hall,
## a little above the eye.
func god_point(up:=false)->Vector3:
	if court_set!=null:return (court_set.call("god_point") as Vector3)+Vector3(0.0,0.6 if up else 0.0,0.0)
	if camera==null:return Vector3.ZERO
	var at:=stage_to_world(Vector2(size.x*.5,size.y*(.05 if up else .30)),60.0)
	return at

## Where a point of the hall shows on the stage.
func world_to_stage(point:Vector3)->Vector2:
	if camera==null or not camera.is_inside_tree():return Vector2(point.x/PX_M,-point.y/PX_M)
	return camera.unproject_position(point)

func _layer(layer_name:String)->Control:
	var layer:=Control.new();layer.name=layer_name;layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(layer);layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer

func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		advance_requested.emit()
		accept_event()

# --- The cast -------------------------------------------------------------------

func has_figure(key:String)->bool:
	return figures.has(key) and is_instance_valid(figures[key])

func figure(key:String)->Figure:
	return figures.get(key) as Figure if has_figure(key) else null

## Finds a figure by the person's name ("" when nobody of that name stands here).
func key_for_name(person_name:String)->String:
	if person_name.strip_edges().is_empty():return ""
	for key in cast_order:
		var f:=figure(key)
		if f!=null and not f.leaving and String(f.person.get("name",""))==person_name:return key
	return ""

## Someone joins the stage. role: "main" (the one before the god), "court"
## (our officials looking on) or "attendant" (who came with an envoy).
## enter: they walk in rather than already standing there.
func add_figure(key:String,person:Dictionary,role:String,name_text:String="",title_text:String="",enter:=false,accent:=BUBBLE_RULE)->Figure:
	if has_figure(key):return figure(key)
	var f:=Figure.new();f.key=key;f.person=person;f.role=role;f.name="Figure_"+node_key(key);f.accent=accent
	var picture:=figure_picture(person,registry)
	f.painting.texture=picture.texture;f.painting.flip=bool(picture.flip)
	f.set_names(name_text,title_text,role==MAIN)
	f.plate.visible=role!="attendant" and not name_text.is_empty()
	f.named=f.plate.visible
	# In the modelled court a crowd of plates would hide the people: the one
	# before the god keeps theirs; the others show theirs while they speak,
	# and when the pointer is over them.
	if court_set!=null:
		f.plate.visible=f.named and role==MAIN
		f.mouse_entered.connect(func()->void:if f.named and not f.leaving:f.plate.visible=true)
		f.mouse_exited.connect(func()->void:_show_plates())
	var tip:=name_text if title_text.is_empty() else "%s · %s" % [name_text,title_text]
	f.tooltip_text=tip if not tip.is_empty() else String(person.get("name",""))
	figure_layer.add_child(f)
	if three_d:_embody(f)
	# An envoy's gift of food is carried in by the first of their company.
	if f.role=="attendant" and f.body3d!=null and not _bearer_chosen and String((facts.get("gift",{}) as Dictionary).get("resource","")).to_lower()=="food":
		_bearer_chosen=true
		# (once the body stands in the hall: the bundle rides between its hands)
		var bearer:=f.body3d
		if bearer.is_inside_tree():bearer.carry("bundle",true)
		else:bearer.ready.connect(func()->void:if is_instance_valid(bearer):bearer.carry("bundle",true),CONNECT_ONE_SHOT)
	figures[key]=f;cast_order.append(key)
	if enter:_arrivals.append(key)
	if _laid_out:
		layout(true)
		_run_arrivals()
	return f

## The stances already standing in this room (FigureLook.room_stance).
var _room_stances:Dictionary={}

## Each person keeps their own stance for life; the room is spread so it never
## looks like a line of hostages: at most one pair of clasped hands in the
## hall. The one before the god stands as they feel: the frightened with
## their hands clasped before them, the proud with arms folded, the warm
## easy; an envoy as their temper is.
const EASY_STANCES:=["hip","belt","stand","folded","hip","stand"]
func _spread_stance(f:Figure,own:String)->String:
	var h:=absi(("%s|%d|stance" % [String(f.person.get("name",f.key)),int(f.person.get("person_id",0))]).hash())
	var stance:=own
	if f.role==MAIN:
		if String(f.person.get("role",""))=="envoy" or layout_kind=="envoy":
			var temper:=String(f.person.get("temper",""))
			if temper.is_empty() and director!=null and director.has_method("envoy_temper") and facts.get("envoy") is Dictionary:temper=String(director.call("envoy_temper",facts.envoy))
			stance=String({"haughty":"folded","nervous":"clasped","greedy":"belt","calm":"stand"}.get(temper,own if own!="clasped" else "stand"))
		else:
			var dread:=float(DivineRegard.dread_of(f.person)) if f.person.has("relationships") else 0.0
			var love:=float(DivineRegard.love_of(f.person)) if f.person.has("relationships") else 0.4
			if dread>=0.45:stance="clasped"
			elif float(f.person.get("pride",0.5))>=0.7:stance="folded"
			elif love>=0.6:stance="stand" if own!="hip" else "hip"
			elif own=="clasped":stance=String(EASY_STANCES[h%EASY_STANCES.size()])
	if stance!="clasped":return stance
	# Someone already has their hands clasped: this one stands otherwise.
	for key in cast_order:
		var other:=figure(key)
		if other!=null and other!=f and other.body3d!=null and String(other.body3d.stance)=="clasped":
			return String(EASY_STANCES[h%EASY_STANCES.size()])
	return stance

## Gives a figure its modelled body in the hall (and its shade on the floor).
func _embody(f:Figure)->void:
	var body:=Figure3D.new();body.name="Body_"+node_key(f.key)
	var look:=figure_look(f.person,registry).duplicate()
	# The one before the god, and an envoy's company, stand.
	if f.role in [MAIN,"attendant"] and String(look.get("stance","")) in ["sit","crouch"]:look.stance="clasped"
	if f.role==MAIN and String(look.get("stance",""))=="bowl" and layout_kind=="home":look.stance="clasped"
	look.stance=_spread_stance(f,String(look.get("stance","stand")))
	var mark:=""
	var seat:=-1.0
	if court_set!=null:
		look["lit"]=true
		mark=_take_mark(f)
		var m:Marker3D=court_set.call("mark",mark) if not mark.is_empty() else null
		# Onlookers on a log sit on it; nobody sits on a standing mark's air.
		if m!=null and bool(m.get_meta("sit",false)) and f.role=="crowd":look.stance="sit"
		if m!=null and bool(m.get_meta("sit",false)) and String(look.get("stance",""))=="sit":seat=float(m.get_meta("seat",0.47))
	# The one before the god stands as they feel (kept); everyone else is
	# spread within their people (J) and, for the room, at most one keeps
	# their hands clasped before them.
	if f.role==MAIN:look["keep_stance"]=true
	look=FigureLook.vary(look)
	if seat<0.0 or String(look.get("stance",""))!="sit":look["stance"]=FigureLook.room_stance(look,_room_stances)
	if not body.setup(look):
		body.free();return
	if court_set!=null:
		var spot:=Node3D.new();spot.name="Spot_"+node_key(f.key)
		court_set.add_child(spot)
		# (the stage may not be in the tree yet: the mark's place within the set)
		if not mark.is_empty():
			var m:Marker3D=court_set.call("mark",mark)
			var holder:=m.get_parent() as Node3D
			# A mark's -Z is the way a person there faces; a figure's front is +Z
			# (M's place() turns them the same way).
			spot.transform=(holder.transform if holder!=null else Transform3D.IDENTITY)*m.transform*Transform3D(Basis(Vector3.UP,PI),Vector3.ZERO)
		else:
			# every mark is taken: at the back, along the far side
			var extra:=_marks.size()+cast_order.size()
			spot.position=set_point("crowd_8")+Vector3(-1.2+0.65*float(extra%5),0.0,-0.5*float(extra/5))
			var toward:=set_point("fire")-spot.position;toward.y=0.0
			if toward.length()>0.01:spot.basis=Basis.looking_at(-toward.normalized(),Vector3.UP)
		spot.add_child(body)
		if seat>=0.0:
			body.seat_height=seat
			f.lift=seat-0.47
		body.add_child(CourtSet.contact_shadow(0.85,0.6,0.5))
		f.spot=spot;f.mark_name=mark
		if seat<0.0:_space_spot(f)
		f.attach_body(body,null,self)
		_acting_stance(f,seat)
		# Winter: their breath shows (M).
		if String(facts.get("season",""))=="winter" and court_set.has_method("add_breath"):court_set.call("add_breath",body)
		return
	view3d.add_child(body)
	var shade:=MeshInstance3D.new();shade.name="Shade_"+node_key(f.key)
	shade.mesh=_shade_mesh();shade.material_override=_shade_material()
	shade.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view3d.add_child(shade)
	f.attach_body(body,shade,self)

## Nobody stands on another, in a thing, or hidden behind another as the
## hall is watched: a newcomer whose mark lies in line with someone already
## standing (as the camera looks), too close to them, or on a log, a rack or a
## post steps a little aside, onto open floor (never onto the fire). The one
## before the god and the seated keep their places.
const APART:=0.62
const IN_LINE:=0.7
func _space_spot(f:Figure)->void:
	if court_set==null or f.spot==null or f.role==MAIN:return
	var yaw:=22.0
	if court_set.get("rig")!=null and (court_set.get("rig") as Object).get("base_yaw")!=null:yaw=float((court_set.get("rig") as Object).get("base_yaw"))
	var right:=Vector2(cos(deg_to_rad(yaw)),-sin(deg_to_rad(yaw)))
	var toward:=Vector2(sin(deg_to_rad(yaw)),cos(deg_to_rad(yaw)))
	var room:Variant=Paths.room_of(court_set)
	var fire:Variant=Paths._mark_xz(court_set,"fire")
	var home:=Vector2(f.spot.position.x,f.spot.position.z)
	var others:Array[Vector2]=[]
	for key in cast_order:
		var o:=figure(key)
		if o==null or o==f or o.spot==null or o.leaving:continue
		others.append(Vector2(o.spot.position.x,o.spot.position.z))
	var crowded:=func(at:Vector2)->float:
		# how far into someone's room, in line with them, or in a thing a place is
		var worst:=0.0
		if room!=null and Paths.solid_at(room,at):worst=1.0
		for them in others:
			var d:=at-them
			worst=maxf(worst,APART-d.length())
			if absf(d.dot(toward))<3.5:worst=maxf(worst,IN_LINE-absf(d.dot(right)))
		return worst
	if float(crowded.call(home))<=0.0:return
	var best:=home;var best_cost:=float(crowded.call(home))+0.001
	for step:float in [0.15,0.3,0.45,0.6,0.75]:
		for way:Vector2 in [right,-right,toward,-toward]:
			var at:Vector2=home+way*step
			if room!=null and Paths.solid_at(room,at):continue
			if fire!=null and at.distance_to(fire as Vector2)<1.5:continue
			var cost:float=maxf(float(crowded.call(at)),0.0)+step*0.05
			if cost<best_cost:best=at;best_cost=cost
		if best_cost<=0.05:break
	f.spot.position=Vector3(best.x,f.spot.position.y,best.y)

## A child of the hall stands beside a grown-up standing near them (to hide
## behind when the god speaks): on open floor at their side, not in line
## with anyone, else where they are.
func _beside_a_grown_up(f:Figure)->void:
	if court_set==null or f.spot==null:return
	var me:=Vector2(f.spot.position.x,f.spot.position.z)
	var room:Variant=Paths.room_of(court_set)
	var fire:Variant=Paths._mark_xz(court_set,"fire")
	var yaw:=22.0
	if court_set.get("rig")!=null and (court_set.get("rig") as Object).get("base_yaw")!=null:yaw=float((court_set.get("rig") as Object).get("base_yaw"))
	var right:=Vector2(cos(deg_to_rad(yaw)),-sin(deg_to_rad(yaw)))
	var grown:Array=[]
	for key in cast_order:
		var o:=figure(key)
		if o==null or o==f or o.spot==null or o.leaving or o.role==MAIN or o.body3d==null or String(o.body3d.stance)=="sit":continue
		if String(o.body3d.look.get("variant",""))=="child":continue
		grown.append(o)
	grown.sort_custom(func(a:Figure,b:Figure)->bool:return Vector2(a.spot.position.x,a.spot.position.z).distance_to(me)<Vector2(b.spot.position.x,b.spot.position.z).distance_to(me))
	for o:Figure in grown:
		var at0:=Vector2(o.spot.position.x,o.spot.position.z)
		if at0.distance_to(me)<=1.0:return
		for side:float in [1.0,-1.0]:
			var at:Vector2=at0+right*side*0.62
			if room!=null and Paths.solid_at(room,at):continue
			if fire!=null and at.distance_to(fire as Vector2)<1.5:continue
			var clear:=true
			for key in cast_order:
				var p:=figure(key)
				if p==null or p==f or p==o or p.spot==null or p.leaving:continue
				if Vector2(p.spot.position.x,p.spot.position.z).distance_to(at)<APART:clear=false;break
			if not clear:continue
			f.spot.position=Vector3(at.x,f.spot.position.y,at.y)
			return

## A walk in the hall (spot-local points, from their mark to far) that goes
## round the set's things and everyone standing (court_paths.gd); empty: the
## old way (round the fire only).
func plan_walk(f:Figure,far:Vector3)->PackedVector3Array:
	if court_set==null or f==null or f.spot==null:return PackedVector3Array()
	var room:Variant=Paths.room_of(court_set)
	if room==null:return PackedVector3Array()
	var from3:=f.spot.position
	var to3:=f.spot.transform*far
	var people:=[]
	for key in cast_order:
		var other:=figure(key)
		if other==null or other==f or other.leaving or other.spot==null:continue
		people.append(Vector3(other.spot.position.x,other.spot.position.z,0.3))
	var way:=Paths.route(room,Vector2(from3.x,from3.z),Vector2(to3.x,to3.z),people)
	if way.size()<2:return PackedVector3Array()
	var back:=f.spot.transform.affine_inverse()
	var out:=PackedVector3Array()
	for point in way:
		var local:=back*Vector3(point.x,from3.y,point.y)
		local.y=0.0
		out.append(local)
	out[0]=Vector3.ZERO;out[out.size()-1]=far
	return out

## The acting's own stances (K) where the hall calls for them: an envoy's
## guard leans on the staff; in winter one onlooker standing near the fire
## crouches to warm their hands at it. Seated onlookers keep the figure's
## own seat (the set's height), and nobody else changes how they stand.
var _warming:=false
func _acting_stance(f:Figure,seat:float)->void:
	if acting==null or f.body3d==null:return
	var want:=""
	if f.role=="attendant" and String(f.body3d.stance)=="staff" and Acting.has_clip("stance_guard"):want="guard"
	elif f.role=="crowd" and not _warming and seat<0.0 and String(facts.get("season",""))=="winter" and Acting.has_clip("stance_fire") and _near_fire(f):want="fire"
	if want.is_empty() and f.role=="crowd" and String(f.body3d.look.get("variant",""))=="child" and seat<0.0 and Acting.has_clip("stance_fidget"):want="fidget"
	if want.is_empty():return
	if want=="fire":_warming=true
	f.acting_stance=want
	var body:=f.body3d
	var go:=func()->void:
		if is_instance_valid(body) and not f.leaving:Acting.idle(body,want)
	if body.is_inside_tree():go.call()
	else:body.ready.connect(go,CONNECT_ONE_SHOT)

## Whether someone's mark is close enough to the fire to warm their hands.
func _near_fire(f:Figure)->bool:
	if court_set==null or f.spot==null or not court_set.call("has_mark","fire"):return false
	var m:Marker3D=court_set.call("mark","fire")
	var holder:=m.get_parent() as Node3D
	var at:=((holder.transform if holder!=null and holder!=court_set else Transform3D.IDENTITY)*m.transform).origin
	return Vector2(at.x-f.spot.position.x,at.z-f.spot.position.z).length()<=2.4

static var _shade_quad:QuadMesh
static var _shade_mat:ShaderMaterial
static func _shade_mesh()->QuadMesh:
	if _shade_quad==null:
		_shade_quad=QuadMesh.new();_shade_quad.size=Vector2(0.95,0.26)
	return _shade_quad

static func _shade_material()->ShaderMaterial:
	## A soft pool of shade where a figure stands, under it on the floor.
	if _shade_mat==null:
		_shade_mat=ShaderMaterial.new();_shade_mat.shader=Shader.new()
		_shade_mat.shader.code="shader_type spatial;render_mode unshaded,blend_mix,depth_draw_never,cull_disabled;void fragment(){vec2 p=(UV-0.5)*2.0;float d=length(p);ALBEDO=vec3(0.16,0.11,0.07);ALPHA=0.40*(1.0-smoothstep(0.2,1.0,d));}"
	return _shade_mat

## The one before the god (or anyone here) shows what they feel at once:
## "dread" they go down on one knee and stay there; "reverence" they bow;
## "point" and "order" a gesture. The engine decided what happened; this is
## only how it looks.
func react(key:String,mood:String)->void:
	var f:=figure(key)
	if f==null or f.leaving:return
	match mood:
		"dread":
			f.gesture("kneel",true)
			if f.body3d!=null:f.body3d.set_mood("afraid")
		"defy":
			# They stand their ground: no bow, chin up, a hard set to the brows.
			if f.body3d!=null:
				f.body3d.set_mood("defiant")
				f.body3d.face(f.rest_yaw*.3,0.35)
			else:f.gesture("stand")
		"endure":
			if f.body3d!=null:f.body3d.set_mood("grieved")
		"reverence":
			f.gesture("bow")
			if f.body3d!=null:f.body3d.set_mood("warm")
		"point":f.gesture("point")
		"order":f.gesture("raise_hand")

## How the one before the god feels, from the engine's regard (Hall.regard_of)
## or an envoy's mood: "warm", "neutral", "afraid", "defiant".
static func mood_of(regard:Dictionary,envoy_mood:=0.0)->String:
	var id:=String(regard.get("id",""))
	if id in ["war","defiant","hates"]:return "defiant"
	if id in ["terror","fear","hates_dread"] or float(regard.get("dread",0.0))>=0.62:return "afraid"
	if envoy_mood<=-0.45:return "defiant"
	if float(regard.get("love",0.0))>=0.62 or envoy_mood>=0.45:return "warm"
	return "neutral"

# --- Events: the one door for what happens in the hall ---------------------------

## Every happening on the stage passes here (docs/COURT_STAGE_3D.md §5): the
## stage's own acting has already run; a director, when installed, adds its
## beats on top.
func event(kind:String,data:Dictionary={})->void:
	_event_index+=1
	_last_beats=[]
	if _sound!=null and is_instance_valid(_sound):_sound.call("on_event",kind,data)
	if court_set!=null:_set_answers(kind,data)
	if director==null or not director.has_method("beats"):return
	var happened:=data.duplicate();happened["kind"]=kind
	var cast:=cast_list()
	var seed_value:=hash("%s|%d" % [audience_key,_event_index])
	var beats:Variant=director.call("beats",happened,cast,facts,seed_value)
	var lines:Variant=director.call("asides",happened,facts,cast,seed_value) if director.has_method("asides") else []
	var all:Array=[]
	if beats is Array:all.append_array(beats)
	if lines is Array:all.append_array(lines)
	# Those the scene is about finish walking in before it plays on them (a
	# gift accepted while the bearer is still on the way in is set down at
	# their mark, not in the doorway).
	if not kind in ["enter","exit","open","close"]:
		var wait:=_still_arriving(all)
		if wait>0.0:
			var later:Array=[]
			for beat in all:
				if beat is Dictionary:
					var moved:Dictionary=(beat as Dictionary).duplicate()
					moved["t"]=float(moved.get("t",0.0))+wait
					later.append(moved)
			all=later
	_last_beats=all
	_event_weight=_weight_of(kind,data)
	var span:=0.0
	for beat in all:
		if beat is Dictionary:span=maxf(span,float((beat as Dictionary).get("t",0.0))+float(((beat as Dictionary).get("args",{}) as Dictionary).get("dur",0.8)))
	_event_end=_now()+span
	if not all.is_empty():run_beats(all)

## How long until everyone the beats name has finished walking in (0: all here).
func _still_arriving(beats:Array)->float:
	var wait:=0.0
	for beat in beats:
		if not beat is Dictionary:continue
		var f:=figure(String((beat as Dictionary).get("who","")))
		if f==null or f.leaving or f.spot==null or f.stroll<=0.0:continue
		wait=maxf(wait,f.arriving_in())
	return clampf(wait+(0.3 if wait>0.0 else 0.0),0.0,7.0)

## How weighty an event is for the camera.
static func _weight_of(kind:String,data:Dictionary)->int:
	match kind:
		"divine","terrify_envoy","command":return 4
		"god":return 3
		"enter","exit","gift","decree","promise","dismiss","defer":return 2
		"line","direction":return 1
	return 0

## Did the director just give this person this act (by its own name)?
func _directed(who:String,act:String)->Dictionary:
	for beat in _last_beats:
		if not beat is Dictionary or String((beat as Dictionary).get("who",""))!=who:continue
		var args:Dictionary=(beat as Dictionary).get("args",{}) if (beat as Dictionary).get("args") is Dictionary else {}
		if String((beat as Dictionary).get("act",""))=="play" and String(args.get("beat",""))==act:return args
	return {}

## The god's acts that are wrath, and those that are favour (the frame
## jolts at wrath and the dog cowers; at favour the dog wags).
const WRATH_ACTS:=["terrify","penance","rebuke","threaten","smite","curse","envoy_flog","envoy_maim","envoy_detain","envoy_kill","envoy_expel"]
const FAVOUR_ACTS:=["bless","boon","raise_up","honour","honor","reward","envoy_feast","envoy_gift"]

## The place answers the god: wrath jolts the frame and sends the dog
## cowering; favour sets it wagging; at the god's voice it looks up.
func _set_answers(kind:String,data:Dictionary)->void:
	var beasts:Array=[]
	for kind_of in ["dog","goat"]:
		var beast:Node3D=court_set.call("animal",kind_of)
		if beast!=null and beast.has_method("on_god"):beasts.append(beast)
	match kind:
		"divine":
			var action:=String(data.get("action",""))
			var target:=_addressed(data)
			if action in WRATH_ACTS:
				# (the director's beats carry the jolt; without them, the stage's)
				if director==null and rig!=null and rig.has_method("shake"):rig.call("shake",0.6)
				for beast:Node3D in beasts:beast.call("on_god","wrath")
				_god_light(target,"wrath",3.0)
			elif action in FAVOUR_ACTS:
				for beast:Node3D in beasts:beast.call("on_god","favour")
				_god_light(target,"favour",3.0)
		"god":
			for beast:Node3D in beasts:beast.call("on_god","voice")
			# The god turns to the one before them: the light falls there with
			# N's swell, in, held and out on the same envelope (M's god_moment).
			if court_set.has_method("god_moment"):court_set.call("god_moment",_addressed(data),String(data.get("tone","")),float(data.get("seconds",2.0)))
			else:
				var tone:=String(data.get("tone",""))
				_god_light(_addressed(data),tone if tone in ["wrath","favour"] else "speaks",float(data.get("seconds",2.0))+1.8)
		"close":
			if court_set.has_method("god_light"):court_set.call("god_light",null,"off",0.0,0.0)

## The body the god's words or act fall on: the one named, else the one
## before the god.
func _addressed(data:Dictionary)->Node3D:
	var f:=figure(String(data.get("target",data.get("who",MAIN))))
	if f==null or f.body3d==null or f.leaving:f=figure(MAIN)
	return f.body3d if f!=null and f.body3d!=null and not f.leaving else null

## The god's presence in light on the set (M's god_light): held, then eased back.
func _god_light(body:Node3D,tone:String,hold:float)->void:
	if court_set==null or not court_set.has_method("god_light"):return
	court_set.call("god_light",body,tone,maxf(hold,0.5))

## An animal's beat (the director's dog or goat) on the set's own beast.
func _animal_beat(key:String,beat:Dictionary)->void:
	var entry:Dictionary=extras.get(key,{})
	var beast:Node3D=court_set.call("animal",String(entry.get("kind",key)))
	if beast==null:return
	var args:Dictionary=beat.get("args",{}) if beat.get("args") is Dictionary else {}
	var at:=String(args.get("at",""))
	var other:=figure(at)
	var near:Variant=other.body3d if other!=null and other.body3d!=null else null
	if at=="gift":
		var main:=figure(MAIN)
		if main!=null and main.body3d!=null:near=main.body3d.global_position+main.body3d.global_transform.basis.z*0.45
	match String(args.get("clip",args.get("beat",""))):
		"perk_up","look_up":beast.call("look_up")
		"whimper":beast.call("cower",2.5)
		"hide_under":
			if near is Node3D:beast.call("go_to",(near as Node3D).global_position+Vector3(0.35,0.0,0.25),"trot",Callable(beast,"cower").bind(3.0))
			else:beast.call("cower",3.0)
		"sniff":
			if near!=null:beast.call("sniff_at",near,2.5)
		"tail_wag","wag":beast.call("wag",2.5)
		"lie_down":beast.call("lie")
		"scratch":beast.call("scratch",1.8)
		"bark":beast.call("bark",2)
		"sit":beast.call("sit")
		"tilt":beast.call("tilt")

## Who stands here, as the director and the acting see them.
func cast_list()->Array:
	var out:=[]
	for key in cast_order:
		var f:=figure(key)
		if f==null or f.leaving:continue
		if extras.has(key):
			var entry:Dictionary=(extras[key] as Dictionary).duplicate();entry["figure"]=f.body3d
			out.append(entry)
		else:
			out.append({"key":key,"role":f.role,"person":f.person,"figure":f.body3d,"mood":String(f.body3d.mood) if f.body3d!=null else "neutral"})
	# Animals are the set's own beasts (or wait for one, still in the room for the director).
	for key in extras:
		if has_figure(key):continue
		var entry:Dictionary=(extras[key] as Dictionary).duplicate()
		if court_set!=null and String(entry.get("role",""))=="animal":entry["figure"]=court_set.call("animal",String(entry.get("kind",key)))
		out.append(entry)
	return out

## A bystander the director brings (an elder, a child, someone with a bowl):
## a figure of our people with no plate. Animals wait for the set's beasts.
func add_extra(entry:Dictionary)->void:
	var key:=String(entry.get("key",""))
	if key.is_empty() or extras.has(key):return
	extras[key]=entry.duplicate()
	if String(entry.get("role",""))!="crowd":return
	var person:={"name":String(entry.get("name","someone")),"person_id":0,"sex":String(entry.get("sex","")),"age":int(entry.get("age",30))}
	var f:=add_figure(key,person,"crowd")
	# Given a seat (a log, a bench), they sit on it, whatever they hold:
	# nobody stands in a bench. The director hears they sit.
	if f!=null and f.body3d!=null and String(f.body3d.stance)=="sit" and court_set!=null and not f.mark_name.is_empty() and court_set.call("has_mark",f.mark_name) and bool((court_set.call("mark",f.mark_name) as Marker3D).get_meta("sit",false)):
		(extras[key] as Dictionary)["stance"]="sit"
		return
	if f!=null and String(entry.get("kind",""))=="child":_beside_a_grown_up(f)
	if f!=null and f.body3d!=null and String(entry.get("stance",""))!="":
		var look:Dictionary=f.body3d.look.duplicate();look["stance"]=String(entry.stance)
		f.body3d.setup(look);f.rest_clip=f.body3d.rest_clip();f.body3d.play(f.rest_clip,0.0)

## A bystander's muttered line: a small, quiet bubble beside them that goes on
## its own, never ages the main bubbles and never enters the history.
func mutter(who:String,text:String)->void:
	var f:=figure(who)
	if f==null or f.leaving or text.strip_edges().is_empty():return
	# One at a time: a newer mutter takes the place of an older one.
	for child in bubble_layer.get_children():
		if child is Bubble and (child as Bubble).kind=="mutter":(child as Bubble).queue_free()
	var bubble:=Bubble.new();bubble.name="Mutter";bubble.kind="mutter";bubble.speaker=who
	bubble_layer.add_child(bubble)
	# Small and sidelong: 0.8 of a speech bubble's letter, a paler paper, no
	# kicker, the tail from the side toward their mouth.
	bubble.setup(text,HudTokens.voice_font(true),13 if compact else 15,Color("4a3d2c"),Color(ASIDE_PAPER,0.85),Color("9a8566"),minf(240.0,size.x*.22),false,"",12)
	var head:=head_point(f)
	var mouth:=Vector2(head.x,head.y+f.size.y*.10)
	# Beside the head, away from the middle of the hall.
	var outward:=head.x>size.x*.5
	var x:=mouth.x+22.0 if outward else mouth.x-22.0-bubble.size.x
	x=clampf(x,6.0,maxf(6.0,size.x-bubble.size.x-6.0))
	var y:=clampf(mouth.y-bubble.size.y*.7,top_inset+4.0,maxf(top_inset+4.0,size.y-bubble.size.y-6.0))
	bubble.position=Vector2(x,y).round()
	bubble.tail_side="left" if x>mouth.x else "right"
	bubble.tip=mouth-bubble.position
	if (bubble.tail_side=="left" and bubble.tip.x>-4.0) or (bubble.tail_side=="right" and bubble.tip.x<bubble.size.x+4.0):bubble.tail_side="none"
	_clear_focus(bubble)
	_clear_of_others(bubble)
	bubble.queue_redraw()
	bubble.modulate.a=0.0
	var tw:=bubble.create_tween()
	tw.tween_property(bubble,"modulate:a",1.0,0.2)
	tw.tween_interval(hold_time(text))
	tw.tween_property(bubble,"modulate:a",0.0,0.6)
	tw.tween_callback(bubble.queue_free)

## A noise made visible: a tiny wordless bubble by the head (or at the feet
## for a thump, a clatter or a fall), drawn in ink, gone in a moment.
const GLYPHS_LOW:=["thump","clatter"]
func glyph(who:String,glyph_name:String)->void:
	var f:=figure(who)
	if f==null or glyph_name.is_empty():return
	var mark:=Glyph.new();mark.name="Glyph";mark.glyph=glyph_name
	bubble_layer.add_child(mark)
	var head:=head_point(f)
	var at:=Vector2(f.home.x+f.size.x*.18,f.home.y-24.0) if glyph_name in GLYPHS_LOW else Vector2(head.x+f.size.x*.22,head.y+4.0)
	mark.position=(at-mark.size*.5).clamp(Vector2(4.0,top_inset+2.0),Vector2(maxf(4.0,size.x-mark.size.x-4.0),maxf(top_inset+2.0,size.y-mark.size.y-4.0))).round()
	mark.pivot_offset=mark.size*.5
	if who!=_focus_key:_clear_focus(mark)
	_clear_of_others(mark)
	if Motion.reduced():
		get_tree().create_timer(1.2).timeout.connect(mark.queue_free);return
	mark.scale=Vector2(.4,.4);mark.modulate.a=0.0
	var tw:=mark.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mark,"scale",Vector2.ONE,0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mark,"modulate:a",1.0,0.12)
	tw.set_parallel(false)
	tw.tween_interval(1.0)
	tw.tween_property(mark,"modulate:a",0.0,0.25)
	tw.tween_callback(mark.queue_free)

## How the bubble of a line is performed (never what it says): it trembles
## for the terrified; a child's is smaller.
func _style_bubble(who:String,args:Dictionary)->void:
	var newest:Bubble=null
	for child in bubble_layer.get_children():
		if child is Bubble and (child as Bubble).speaker==who and not (child as Bubble).dropping and (child as Bubble).kind in ["speech","aside"]:newest=child
	if newest==null:return
	match String(args.get("style","")):
		"tremble":newest.tremble(float(args.get("amount",0.5)),reveal_time(newest.text)+1.5)
		"small":
			newest.pivot_offset=newest.tip.clamp(Vector2.ZERO,newest.size)
			newest.scale=Vector2(.86,.86)

## The room's own life: the director's loops of idle business, each seeded,
## driven by one quarter-second timer (nothing per frame), paused while hushed.
func start_ambient()->void:
	if is_inside_tree():_glances()
	if director==null or not director.has_method("ambient") or not is_inside_tree():return
	var specs:Variant=director.call("ambient",cast_list(),facts,hash("%s|ambient" % audience_key))
	_ambient.clear()
	_ambient_rng.seed=hash("%s|room" % audience_key)
	var now:=_now()
	if specs is Array:
		for spec in specs:
			if not spec is Dictionary:continue
			var item:=(spec as Dictionary).duplicate()
			if bool(item.get("hold",false)):_ambient_beat(item)
			else:
				item["next"]=now+float(item.get("start",0.0))+1.0
				_ambient.append(item)
	if _ambient_timer==null:
		_ambient_timer=Timer.new();_ambient_timer.name="RoomLife";_ambient_timer.wait_time=0.25
		add_child(_ambient_timer);_ambient_timer.timeout.connect(_ambient_tick)
	if not _ambient.is_empty():_ambient_timer.start()

## Where an idle glance may fall (K's acting): the nearest neighbours, the
## fire, and the one before the god (and what they carry).
func _glances()->void:
	if acting==null or not three_d:return
	var heads:Array=[]
	for key in cast_order:
		var f:=figure(key)
		if f!=null and f.body3d!=null and not f.leaving and f.body3d.is_inside_tree():heads.append([key,f.body3d.head_top()])
	var fire:=set_point("fire") if court_set!=null and court_set.is_inside_tree() else Vector3.ZERO
	for row:Array in heads:
		var f:=figure(String(row[0]))
		var near:=heads.filter(func(o:Array)->bool:return String(o[0])!=String(row[0]))
		near.sort_custom(func(a:Array,b:Array)->bool:return (a[1] as Vector3).distance_to(row[1])<(b[1] as Vector3).distance_to(row[1]))
		var points:=PackedVector3Array()
		for o:Array in near.slice(0,3):points.append(o[1])
		if court_set!=null:points.append(fire+Vector3(0.0,0.4,0.0))
		var main:=figure(MAIN)
		if main!=null and main.body3d!=null and String(row[0])!=MAIN:points.append(main.body3d.global_position+Vector3(0.0,1.0,0.0))
		Acting.set_glance_points(f.body3d,points)

func _now()->float:
	return float(Time.get_ticks_msec())/1000.0

func _ambient_tick()->void:
	if not is_visible_in_tree():return
	var now:=_now()
	if now<_hush_until:return
	for item:Dictionary in _ambient:
		if now<float(item.next):continue
		_ambient_beat(item)
		var every:Array=item.get("every",[8.0,14.0])
		item["next"]=now+_ambient_rng.randf_range(float(every[0]),float(every[1] if every.size()>1 else every[0]))

func _ambient_beat(item:Dictionary)->void:
	if not has_figure(String(item.get("who",""))) or director==null:return
	var lowered:Variant=director.call("lower",[{"t":0.0,"who":String(item.who),"act":String(item.act),"args":item.get("args",{})}]) if director.has_method("lower") else []
	if lowered is Array:
		for beat in lowered:_beat(beat)

## Plays a set of beats [{t, who, act, args}] on one tween, in time order.
func run_beats(beats:Array)->void:
	if not is_inside_tree() or beats.is_empty():return
	# Each event's beats play out on their own: the caption that follows the
	# god's wrath in the same moment must not cut the wrath short.
	_beat_sets=_beat_sets.filter(func(t:Variant)->bool:return t is Tween and (t as Tween).is_valid())
	var ordered:=beats.duplicate()
	ordered.sort_custom(func(a:Variant,b:Variant)->bool:return float((a as Dictionary).get("t",0.0))<float((b as Dictionary).get("t",0.0)))
	_beats=create_tween()
	_beat_sets.append(_beats)
	var at:=0.0
	for beat in ordered:
		var t:=maxf(float((beat as Dictionary).get("t",0.0)),at)
		if t>at:_beats.tween_interval(t-at)
		at=t
		_beats.tween_callback(_beat.bind(beat))

## One beat of the director's, as the stage plays it (K's acting first where
## it has the act; else the figures' own clips, moods and gaze).
func _beat(beat:Dictionary)->void:
	var who:=String(beat.get("who",""))
	var f:=figure(who)
	var body:Node3D=f.body3d if f!=null and not f.leaving else null
	var args:Dictionary=beat.get("args",{}) if beat.get("args") is Dictionary else {}
	var act:=String(beat.get("act",""))
	if _sound!=null and is_instance_valid(_sound):_sound.call("on_beat",beat,body)
	if f==null and court_set!=null and String((extras.get(who,{}) as Dictionary).get("role",""))=="animal":
		if act=="play":_animal_beat(who,beat)
		return
	match act:
		"shot":
			shot(String(args.get("name","wide")),args)
		"hush":
			hush(float(args.get("dur",2.0)),String(args.get("bubbles",""))=="dim")
		"aside":
			mutter(who,String(args.get("text","")))
		"bubble":
			_style_bubble(who,args)
		"sound":
			if String(args.get("glyph",""))!="":glyph(who,String(args.glyph))
		"play":
			if body==null:return
			if _moved(f,args):return
			_props_after(f,String(args.get("beat",args.get("clip",""))))
			if acting!=null and acting.has_method("play"):
				acting.call("play",body,args,self);return
			f.perform(String(args.get("clip","")),String(args.get("fallback","")),bool(args.get("hold",false)),float(args.get("dur",0.8)),float(args.get("speed",1.0)))
		"mood":
			if body==null:return
			if bool(args.get("hold",false)) and not String(args.get("name","")).is_empty():f.own_mood=String(args.name)
			if acting!=null and acting.has_method("mood"):
				acting.call("mood",body,args,self);return
			f.feel(String(args.get("name","")),args.get("face",{}) as Dictionary,bool(args.get("hold",false)),float(args.get("dur",0.8)))
		"look_at":
			if body==null:return
			if acting!=null and acting.has_method("look_at"):
				acting.call("look_at",body,args,self);return
			var target:=String(args.get("target",""))
			var weight:=float(args.get("weight",0.8))
			match target:
				"god":body.look_at_point(god_point(),0.35,weight)
				"god_up":body.look_at_point(god_point(true),0.35,weight)
				"away":
					body.look_at_point(null,0.3);body.face(f.rest_yaw+(40.0 if _ambient_rng.randf()<0.5 else -40.0),0.4)
				_:
					var other:=figure(target)
					if other!=null and other.body3d!=null:body.look_at_point(other.body3d.head_top(),0.35,weight)
		"gesture":
			if body!=null and acting!=null and acting.has_method("gesture"):
				acting.call("gesture",body,args,self);return
			if f!=null:f.gesture(String(args.get("clip","bow")),bool(args.get("hold",false)))
		_:
			# anything else the acting layer knows by name (speak, idle, stop...)
			if body!=null and acting!=null and acting.has_method(act):acting.call(act,body,args,self)

## Acts that move someone through the hall. The walks in and out (the wrong
## side, backing out bowing, storming back for what was left) are the
## arrival's and the exit's own (arrive, conclude); here, the small steps.
const WALKED_ACTS:=["enter_wrong","hurry_round","back_out_bowing","bump_post","bow_to_post","storm_off","stop_short","come_back","come_back_for","snatch_up","hurry_after","bolt"]
func _moved(f:Figure,args:Dictionary)->bool:
	var act:=String(args.get("beat",""))
	if act in WALKED_ACTS:return f.spot!=null or f.leaving
	var other:=figure(String(args.get("at","")))
	match act:
		"bow_wrong":
			# They bow, deeply, to the grandest official instead of the god.
			if other==null or other.body3d==null:return false
			f.bow_toward(other.body3d.global_position)
			return true
		"hide_behind":
			if f.spot==null or other==null or other.body3d==null or camera==null:return false
			var away:=(other.body3d.global_position-camera.global_position)
			away.y=0.0
			f.step_to(other.body3d.global_position+away.normalized()*0.35+Vector3(0.18,0.0,0.0),0.5,3.6)
			return false
		"edge_forward":
			if f.spot==null:return false
			var front:=god_point()-f.body3d.global_position;front.y=0.0
			f.step_to(f.body3d.global_position+front.normalized()*_clip_move(f,"edge_forward",0.35),_clip_time("edge_forward",0.9),7.0)
			return false
		"step_back":
			if f.spot==null:return false
			var back:=f.body3d.global_position-god_point();back.y=0.0
			f.step_to(f.body3d.global_position+back.normalized()*0.3,0.35,3.0)
			return false
		"make_room":
			if f.spot==null or other==null or other.body3d==null:return false
			var aside:=f.body3d.global_position-other.body3d.global_position;aside.y=0.0
			f.step_to(f.body3d.global_position+aside.normalized()*_clip_move(f,"make_room_l",0.3),_clip_time("make_room_l",0.6),4.0)
			return false
	return false

## How far one of the acting's clips carries the body (K's move_m, for a
## 1.72 m body; scaled to this one), else the given metres.
func _clip_move(f:Figure,clip:String,otherwise:float)->float:
	if acting==null or not Acting.has_clip(clip):return otherwise
	var metres:=float(Acting.clip_meta(clip).get("move_m",0.0))
	if metres<=0.0:return otherwise
	return metres*(float(f.body3d.body_height)/1.72 if f.body3d!=null else 1.0)

## How long the step of one of the acting's clips takes (most of the clip).
func _clip_time(clip:String,otherwise:float)->float:
	if acting==null or not Acting.has_clip(clip):return otherwise
	return maxf(0.2,float(Acting.clip_length(clip))*0.6)

## A held thing follows the act: a dropped bowl falls and stays on the floor
## (they stand empty-handed after); a bundle rides between the hands while it
## is lifted or struggled with, and stays where it is set down.
func _props_after(f:Figure,act:String)->void:
	if f==null or f.body3d==null:return
	match act:
		"drop_bowl":
			var body:=f.body3d
			get_tree().create_timer(0.45).timeout.connect(func()->void:
				if is_instance_valid(f) and is_instance_valid(body) and body.drop_held("clasped")!=null:f.rest_clip=body.rest_clip())
		"lift_bundle","struggle_bundle","carry_bundle","offer_bundle":
			f.body3d.carry("bundle",true)
		"set_down_bundle":
			f.body3d.carry("bundle",true)
			var body:=f.body3d
			var length:=1.6
			if acting!=null and acting.has_method("clip_length"):length=maxf(float(acting.call("clip_length","set_down_bundle")),0.6)
			get_tree().create_timer(length*0.85).timeout.connect(func()->void:if is_instance_valid(body):body.set_down())

## The room goes still for a while (the god speaks, a sentence falls): the
## acting holds everyone's idle business; the room's own loops wait too.
func hush(seconds:float,dim:=false)->void:
	_hush_until=maxf(_hush_until,_now()+seconds)
	if dim and is_inside_tree() and not Motion.reduced():
		for child in bubble_layer.get_children():
			var old:=child as Control
			if old==null or (old is Bubble and (old as Bubble).dropping):continue
			var was:=old.modulate.a
			var tw:=old.create_tween()
			tw.tween_property(old,"modulate:a",minf(was,0.45),0.25)
			tw.tween_interval(maxf(seconds-0.5,0.2))
			tw.tween_property(old,"modulate:a",was,0.4)
	if acting==null or not acting.has_method("hush"):return
	for key in cast_order:
		var f:=figure(key)
		if f!=null and f.body3d!=null and not f.leaving:acting.call("hush",f.body3d,true)
	if _hush_tween and _hush_tween.is_valid():_hush_tween.kill()
	if not is_inside_tree():return
	_hush_tween=create_tween();_hush_tween.tween_interval(maxf(seconds,0.2))
	_hush_tween.tween_callback(func()->void:
		for key in cast_order:
			var other:=figure(key)
			if other!=null and other.body3d!=null and is_instance_valid(other.body3d):acting.call("hush",other.body3d,false))

## A shot of the director's on the set's camera: wide, two_shot (a, b),
## push_in (target), reaction (target), shake (strength), home.
func shot(name:String,args:Dictionary={})->void:
	if court_set==null or rig==null:
		if camera_rig!=null and camera_rig.has_method("shot"):camera_rig.call("shot",name,args)
		return
	# A lighter event does not cut a weightier event's shot short (a shake
	# never takes the camera's claim).
	var weight:=int(args.get("weight",_event_weight))
	if name!="shake":
		if _now()<_shot_until and weight<_shot_weight:return
		_shot_weight=weight
		_shot_until=maxf(_event_end,_now()+1.0)
		_focus_key=String(args.get("target","")) if name in ["push_in","reaction"] else ""
	var target:=figure(String(args.get("target","")))
	var body:Node3D=target.body3d if target!=null and target.body3d!=null else null
	match name:
		"wide","home":rig.call("wide",[],float(args.get("time",0.9)))
		"two_shot":
			var a:=figure(String(args.get("a","")));var b:=figure(String(args.get("b","")))
			if a!=null and b!=null and a.body3d!=null and b.body3d!=null:
				# An envoy and their company: all of them, from the hall's own
				# side (the camera does not swing round behind our people), the
				# envoy leading; nobody between them and the lens.
				if a.role in [MAIN,"attendant"] and b.role in [MAIN,"attendant"] and a.spot!=null and b.spot!=null:
					var party:=[]
					for key in cast_order:
						var p:=figure(key)
						if p!=null and not p.leaving and p.spot!=null and p.role in [MAIN,"attendant"]:party.append(p.spot)
					rig.call("wide",party,float(args.get("time",0.8)),a.spot)
				else:rig.call("two_shot",a.body3d,b.body3d,float(args.get("time",0.7)))
		"push_in":
			# A close-up (head and shoulders) for the god's wrath on them and
			# the big reactions: M's close_up, else the push-in.
			if body!=null and bool(args.get("close",false)) and close_ups_enabled and rig.has_method("close_up"):rig.call("close_up",body,float(args.get("seconds",1.6)))
			elif body!=null:rig.call("push_in",body,float(args.get("seconds",2.4)))
		"reaction":
			if body!=null:rig.call("reaction",body,float(args.get("time",0.0)))
		"shake":rig.call("shake",float(args.get("strength",0.35)))
	# The caption goes up out of a shot that has gone in on someone, and
	# back down for the room; the bubbles step clear of it.
	if name!="shake":
		_place_caption()
		_reclear_bubbles()

## Someone's mood shows on their face and in the set of their head.
func set_mood(key:String,mood:String)->void:
	var f:=figure(key)
	if f!=null:f.own_mood=mood
	if f!=null and f.body3d!=null:f.body3d.set_mood(mood)

## What the god's wrath or favour looks like on the one before the god, as
## the engine adjudicated it (divine_regard.gd response_to): the cowed go
## down, the defiant stand with their chin up, the enduring bow their head,
## the blessed and the relieved bow.
static func divine_mood(action:String,response:="")->String:
	match response:
		"defy","defiant","refuse":return "defy"
		"cower","shaken","break":return "dread"
		"endure":return "endure"
		"relief","blessed":return "reverence"
	if action in ["terrify","penance","rebuke","threaten","envoy_flog","envoy_maim","envoy_detain"]:return "dread"
	if action in ["bless","boon","raise_up","honour","honor","reward"]:return "reverence"
	return ""

## What a direction in the hall shows its subject doing: "dread" (kneels,
## falls to their knees, prostrates), "reverence" (bows), "point", "order",
## or "" — whole words only, and nothing where the clause says it is not done
## ("nobody kneels", "will not bow", "refuses to kneel").
static var _gesture_res:Array=[]
static var _negation_re:RegEx
static func gesture_in(words:String)->String:
	if _gesture_res.is_empty():
		for pair:Array in [["\\b(kneels?|kneeling|knelt)\\b","dread"],["\\b(falls?|sinks?|sank|drops?) to (their|his|her) knees\\b","dread"],
				["\\bon (their|his|her) knees\\b","dread"],["\\b(prostrates?|prostrated)\\b","dread"],["\\bfalls? on (their|his|her|its) face\\b","dread"],
				["\\b(bows?|bowed|bowing)\\b(?! and arrows?)(?!string)","reverence"],["\\bpoints? (at|to|toward)\\b","point"],["\\b(raises|lifts) a hand\\b","order"]]:
			var re:=RegEx.new();re.compile(String(pair[0]))
			_gesture_res.append([re,String(pair[1])])
		_negation_re=RegEx.new()
		_negation_re.compile("\\b(nobody|no one|none|not|never|neither|nor|won't|will not|does not|doesn't|did not|didn't|refuses? to|without|instead of)\\b")
	for clause:String in words.to_lower().replace(";",".").replace(",",".").split("."):
		for pair:Array in _gesture_res:
			var hit:=(pair[0] as RegEx).search(clause)
			if hit==null:continue
			# A refusal or a "nobody" before the verb in the same clause: not done.
			if _negation_re.search(clause.substr(0,hit.get_start()))!=null:continue
			return String(pair[1])
	return ""

## Who a direction is about: the person the engine named (about), else the
## figure whose name opens the line. "" when it is about nobody standing here.
func subject_of(words:String,about:="")->String:
	var named:=about.strip_edges()
	if not named.is_empty():
		var key:=key_for_name(named)
		if not key.is_empty():return key
		for other in cast_order:
			var f:=figure(other)
			if f!=null and not f.leaving and String(f.person.get("name","")).get_slice(" ",0)==named.get_slice(" ",0):return other
		return ""
	var opening:=words.strip_edges().trim_prefix("[")
	for other in cast_order:
		var f:=figure(other)
		if f==null or f.leaving:continue
		var full:=String(f.person.get("name",""))
		var given:=full.get_slice(" ",0)
		if not full.is_empty() and (opening.begins_with(full+" ") or opening.begins_with(given+" ") or opening.begins_with(given+"'")):return other
	return ""

## They walk in from the side (the threshold) once the stage has a size.
func arrive(keys:Array)->void:
	for key in keys:
		event("enter",{"who":String(key)})
		# The director sent them in by the wrong side.
		var f:=figure(String(key))
		if f!=null and not _directed(String(key),"enter_wrong").is_empty():f.wrong_side=true
	for key in keys:
		if has_figure(String(key)) and not String(key) in _arrivals:_arrivals.append(String(key))
	if _laid_out:_run_arrivals()

func _run_arrivals()->void:
	var index:=0
	# In the modelled hall, one after another, even when they are sent in
	# separately (a late official behind an envoy's company).
	var now:=_now()
	var next:=maxf(now,_next_arrival_at)
	for key in _arrivals:
		var f:=figure(key)
		if f==null:continue
		var side:=-1.0 if f.home.x<size.x*.6 else 1.0
		# A modelled figure walks in from beyond the edge of the stage.
		var distance:=maxf(size.x*.35,f.size.x*1.6)
		if f.body3d!=null:distance=(f.home.x+f.size.x) if side<0.0 else (size.x-f.home.x+f.size.x)
		# In the modelled hall they come in single file, a body's length or
		# so apart (never walking into each other).
		if f.spot!=null:
			f.enter_from(side,distance,next-now)
			next+=FILE_GAP
		else:f.enter_from(side,distance,index*0.18)
		index+=1
	_next_arrival_at=next
	_arrivals.clear()

## Seconds between people walking in or out one behind another in the hall.
const FILE_GAP:=0.9
## When the next to walk in may start (single file).
var _next_arrival_at:=0.0

## The one before the god takes their leave (the audience is concluded);
## those who came with them follow. style says how they go:
##  "bow"   a small bow, then out the way they came;
##  "storm" no bow, out briskly (an insulted guest);
##  "led"   no bow, darkened, taken out quickly (cast out, seized, maimed);
##  "fall"  put to death: they sink and are gone where they stood;
##  "stay"  nobody leaves.
func conclude(delay:float=1.4,style:="bow",reaction:="")->void:
	if style=="stay":return
	event("exit",{"who":MAIN,"style":style,"reaction":reaction})
	# How the director has them go: backing out bowing (into the door post),
	# or storming off and coming back for what they left (the bearer, who
	# stays put until then).
	var main_style:=style
	var left_behind:=""
	if not _directed(MAIN,"back_out_bowing").is_empty():main_style="backward_bump" if not _directed(MAIN,"bump_post").is_empty() else "backward"
	var back_for:=_directed(MAIN,"come_back_for")
	if not back_for.is_empty() or not _directed(MAIN,"come_back").is_empty():
		main_style="storm_back"
		left_behind=String(back_for.get("at",""))
	var index:=0
	for key in cast_order.duplicate():
		var f:=figure(key)
		if f==null or f.leaving or not f.role in [MAIN,"attendant"]:continue
		# Their company is not struck down with them: they are sent away.
		var own:=style if f.role==MAIN or style!="fall" else "led"
		if f.role==MAIN:own=main_style
		elif key==left_behind:
			f.leave(-1.0,maxf(size.x*.4,f.size.x*2.0) if f.body3d==null else f.home.x+f.size.x,delay+5.2,"storm")
			index+=1
			continue
		var distance:=maxf(size.x*.4,f.size.x*2.0)
		if f.body3d!=null:distance=f.home.x+f.size.x
		f.leave(-1.0,distance,delay+index*(FILE_GAP if f.spot!=null else 0.2),own)
		index+=1
	var thought:=thinking
	if is_instance_valid(thought):thought.visible=false

## A band laid over the top (or a plinth at the right) changed size.
func set_insets(top:float,right:float)->void:
	if is_equal_approx(top,top_inset) and is_equal_approx(right,right_reserve):return
	top_inset=top;right_reserve=right
	if _laid_out:
		layout(false)
		_replace_all()

func _on_resized()->void:
	if size.x<40 or size.y<40:return
	_frame_camera()
	# The set's lens frames by the view's own size, which follows a frame later
	# (a push-in or a reaction shot keeps going: the next wide takes the new size).
	if court_set!=null and _wide_now():call_deferred("frame_cast",0.0)
	layout(false)
	var first:=not _laid_out
	_laid_out=true
	if first:_run_arrivals()
	_replace_all()

## Where everyone stands: the one before the god in front, larger; the court
## further back at the sides; an envoy's attendants just behind them. Nobody
## stands in the strip kept for the offered object.
func layout(animate:bool)->void:
	var w:=size.x;var h:=size.y
	if w<40 or h<40:return
	if court_set!=null:
		_layout_set(animate);return
	# Modelled figures stand above their name plates, not behind them.
	var foot_room:=FOOT_ROOM if three_d else 0.0
	var room:=maxf(h-top_inset-foot_room,60.0)
	# A modelled figure has no painted ground about it: it may fill more.
	var fill:=(.88 if layout_kind=="home" else .84) if three_d else (.78 if layout_kind=="home" else .74)
	var main_h:=clampf(room*fill,70.0,600.0)
	var court_h:=main_h*.74
	var front:=h-6.0-foot_room
	var back:=h-foot_room-room*.07
	var usable:=_usable_width()
	var slots:Array=HOME_COURT_X if layout_kind=="home" else ENVOY_COURT_X
	var court_index:=0;var attendant_index:=0;var crowd_index:=0
	for key in cast_order:
		var f:=figure(key)
		if f==null or f.leaving:continue
		var x:=0.5;var fh:=court_h;var foot:=back
		match f.role:
			MAIN:
				x=(HOME_MAIN_X if layout_kind=="home" else ENVOY_MAIN_X)*w;fh=main_h;foot=front
			"attendant":
				x=float(ENVOY_ATTENDANT_X[attendant_index%ENVOY_ATTENDANT_X.size()])*w;fh=main_h*.78;foot=back-room*.03
				attendant_index+=1
			"crowd":
				var index:=crowd_index
				crowd_index+=1
				x=float(CROWD_X[index%CROWD_X.size()])*usable
				fh=court_h*.86;foot=back-room*.10
				# a child stands about two-thirds as tall
				if int((extras.get(f.key,{}) as Dictionary).get("age",30))<13:fh*=.64
			_:
				var row:=court_index/slots.size()
				x=float(slots[court_index%slots.size()])*(w if layout_kind=="home" else usable)
				if three_d:
					# A loose arc about the fire: some nearer, some further back.
					var depth:=int((ARC_DEPTH_HOME if layout_kind=="home" else ARC_DEPTH_ENVOY)[court_index%slots.size()])
					fh*=pow(.93,depth);foot-=room*.055*depth
				# A court too large for the slots stands further back, between
				# the ones in front.
				if row>0:
					fh*=pow(.86,row);foot-=room*.04*row
					x+=(.06 if layout_kind=="home" else .05)*usable*(1.0 if row%2==1 else -1.0)
				court_index+=1
		var fw:=fh*FIGURE_ASPECT
		x=clampf(x,fw*.5+4.0,maxf(fw*.5+4.0,usable-fw*.5-4.0))
		# The one before the god turns three-quarter to the god; the others
		# turn toward them, some in three-quarter, those at the edges in profile.
		var focus:=(HOME_MAIN_X if layout_kind=="home" else ENVOY_MAIN_X)*w
		if f.role==MAIN:f.rest_yaw=clampf((usable*.5-x)/maxf(usable,1.0)*60.0,-22.0,22.0)
		else:f.rest_yaw=clampf((focus-x)/maxf(usable,1.0)*150.0,-72.0,72.0)
		f.place(Vector2(x,foot),Vector2(fw,fh),animate)
	# The nearer stand in front of the further.
	var ordered:Array=figure_layer.get_children()
	ordered.sort_custom(func(a:Node,b:Node)->bool:return (a as Figure).home.y<(b as Figure).home.y if absf((a as Figure).home.y-(b as Figure).home.y)>.5 else (a as Figure).size.y<(b as Figure).size.y)
	for index in ordered.size():figure_layer.move_child(ordered[index],index)

## In the set everyone already has a mark: they turn toward the one before
## the god (officials about half way, onlookers a little), and the camera
## takes them in.
func _layout_set(animate:bool)->void:
	var main:=figure(MAIN)
	var focus:Node3D=main.spot if main!=null and main.spot!=null else null
	for key in cast_order:
		var f:=figure(key)
		if f==null or f.leaving or f.spot==null or f.body3d==null:continue
		var yaw:=0.0
		if f.acting_stance=="fire" and f.spot.is_inside_tree():
			var to_fire:=f.spot.to_local(set_point("fire"))
			yaw=clampf(rad_to_deg(atan2(to_fire.x,to_fire.z)),-150.0,150.0)
		elif focus!=null and f!=main and f.role in ["court","crowd"]:
			var to:=f.spot.to_local(focus.global_position)
			yaw=clampf(rad_to_deg(atan2(to.x,to.z))*(0.45 if f.role=="court" else 0.3),-70.0,70.0)
		f.rest_yaw=yaw
		if f.stroll==0.0 and not f.leaving:f.body3d.face(yaw,0.3 if animate else 0.0)
		# The light where they stand: the fire warms the near, the shaft lights its own.
		if f.spot.is_inside_tree():
			f.light_base=float(court_set.call("light_at",f.spot.global_position))
			f._light(1.0)
	if not _laid_out or _wide_now():frame_cast(0.9 if animate and _laid_out else 0.0)
	_track_all()

## Is the set's camera on everyone (not pushed in on someone)?
func _wide_now()->bool:
	if rig==null:return true
	var now:Variant=rig.get("current_shot") if rig.get("current_shot")!=null else rig.get("shot")
	return now==null or String(now) in ["wide","still",""]

## Which name plates show in the modelled court: the one before the god's,
## and the one speaking now.
func _show_plates()->void:
	if court_set==null:return
	for key in cast_order:
		var f:=figure(key)
		if f!=null:f.plate.visible=f.named and not f.leaving and (f.role==MAIN or key==speaking_key)

## The stage's width left of the offered object's strip.
func _usable_width()->float:
	return maxf(size.x-right_reserve,size.x*.4)

# --- What is said -----------------------------------------------------------------

## A character speaks: a bubble above them, and the room turns to them.
## Returns the label whose words are revealed. ref: their history entry.
## Words from someone already on their way out are told as a caption, not a
## bubble over the place where they stood.
func say(key:String,text:String,aside:=false,animate:=true,ref:=-1)->Label:
	var f:=figure(key)
	if f==null or f.leaving:
		var who:=String(f.person.get("name","")).get_slice(" ",0) if f!=null else ""
		return caption("“%s”" % text.strip_edges(),"narration",animate,ref,("%s, going out" % who) if not who.is_empty() else "")
	speaking_key=key
	var bubble:=Bubble.new();bubble.name="Speech";bubble.kind="aside" if aside else "speech";bubble.speaker=key;bubble.ref=ref
	# In the tree first: its words are measured with the theme they will use.
	bubble_layer.add_child(bubble)
	bubble.setup(text,HudTokens.voice_font(aside),17 if compact else 19,BUBBLE_INK,ASIDE_PAPER if aside else BUBBLE_PAPER,f.accent,_bubble_widths(bubble)[0],false,"aside to you" if aside else "",14)
	bubble.more_pressed.connect(_on_more.bind(bubble))
	_fit_bubble(bubble)
	_place_bubble(bubble)
	_age_bubbles(bubble,animate)
	_age_god(animate);_age_caption(animate)
	# The newest words are never under older ones.
	if is_instance_valid(_god) and _god.get_rect().intersects(bubble.get_rect()):
		_drop(_god,animate);_drop(_rays,animate);_god=null;_rays=null
	if is_instance_valid(_caption) and _caption.get_rect().intersects(bubble.get_rect()):
		_drop(_caption,animate);_caption=null
	_talks+=1
	# An aside is said quietly to the god: the room does not turn for it.
	if aside:f.speak(reveal_time(text)+0.5 if animate else 0.9,false)
	else:_turn_to(key,reveal_time(text)+0.5 if animate else 0.9)
	# The mouth shapes the words as the bubble shows them.
	if f.body3d!=null and acting!=null and acting.has_method("speak"):acting.call("speak",f.body3d,text,reveal_time(text))
	event("line",{"who":key,"text":text,"seconds":reveal_time(text),"aside":aside})
	if animate:bubble.pop_in()
	return bubble.label

## Whether the god's words are wrath or favour (the swell under them), read
## the way the hall reads a spoken act (divine_regard.gd intent).
static func _tone_of(text:String)->String:
	var act:=String(DivineRegard.intent(text))
	if act in ["terrify","penance"]:return "wrath"
	if act in ["bless","raise_up"]:return "favour"
	return ""

## The god's own words, from above.
func god_says(text:String,animate:=true,ref:=-1)->Label:
	if is_instance_valid(_god):_drop(_god,false)
	if is_instance_valid(_rays):_drop(_rays,false)
	speaking_key="god"
	_rays=Rays.new();_rays.name="Light";god_layer.add_child(_rays);_rays.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_god=Bubble.new();_god.name="VoiceFromAbove";_god.kind="god";_god.ref=ref
	god_layer.add_child(_god)
	_god.setup(text,HudTokens.voice_font(true),18 if compact else 20,GOD_INK,GOD_PAPER,GOD_GOLD,_god_widths()[0],true,"",14)
	_god.more_pressed.connect(_on_more.bind(_god))
	_god_age=0
	_fit_bubble(_god)
	_place_god()
	# Older words give way: none of them covers the god's.
	var band:=_god.get_rect().grow(4.0)
	for child in bubble_layer.get_children():
		var old:=child as Bubble
		if old==null or old.dropping:continue
		old.age+=1
		if old.age>=2 or old.get_rect().intersects(band):_drop(old,animate)
		else:old.fade_to(.4,animate)
	for key in cast_order:
		var f:=figure(key)
		if f!=null and not f.leaving:f.look_up()
	event("god",{"text":text,"seconds":reveal_time(text),"tone":_tone_of(text)})
	if animate:
		_god.descend()
		_rays.modulate.a=0.0
		_rays.create_tween().tween_property(_rays,"modulate:a",1.0,Motion.duration(Motion.SLOW))
	return _god.label

## What the engine decided, or what happens in the hall: a caption at the
## foot of the stage. kind: "narration", "direction", "receipt" or "warn".
func caption(text:String,kind:="narration",animate:=true,ref:=-1,kicker:="",about:="")->Label:
	if is_instance_valid(_caption):_drop(_caption,animate)
	var words:=text.strip_edges()
	if kind=="direction" or (words.begins_with("[") and words.ends_with("]")):
		words=words.trim_prefix("[").trim_suffix("]").strip_edges();kind="direction"
	if words.begins_with("RECEIPT · "):
		words=words.trim_prefix("RECEIPT · ");kicker="RECEIPT";kind="receipt"
	_caption=Bubble.new();_caption.name="Caption";_caption.kind="caption";_caption.ref=ref
	_caption.set_meta("caption_kind",kind)
	caption_layer.add_child(_caption)
	_caption.setup(words,HudTokens.voice_font(kind!="receipt"),15 if compact else 17,WARN_INK if kind=="warn" else CAPTION_INK,CAPTION_PAPER,CAPTION_RULE,_caption_widths()[0],true,kicker,13)
	_caption.more_pressed.connect(_on_more.bind(_caption))
	_caption_age=0
	_fit_bubble(_caption)
	_place_caption()
	_reclear_bubbles()
	if animate:_caption.rise_in()
	# What the hall shows ("Hena kneels", "Tuk bows") the one it is about does;
	# when nobody here is named as its subject, nobody moves.
	if kind=="direction":
		var mood:=gesture_in(words)
		var who:=subject_of(words,about)
		if not mood.is_empty() and not who.is_empty():react(who,mood)
		event("direction",{"who":who,"mood":mood,"text":words})
	return _caption.label

## Everything shown at once (a test, or the player skipping ahead): no tween
## left half-way, nothing fading still on the stage.
func settle()->void:
	for key in cast_order:
		var f:=figure(key)
		if f!=null:f.finish_moves()
	if court_set!=null and rig!=null and rig.has_method("settle"):rig.call("settle")
	for layer in [bubble_layer,god_layer,caption_layer]:
		for child in (layer as Control).get_children():
			var item:=child as Control
			if item==null:continue
			if item.has_method("finish"):item.call("finish")
			if bool(item.get_meta("dropping",false)) or (item is Bubble and (item as Bubble).dropping):
				layer.remove_child(item);item.queue_free()

func attach_thinking(label:Label)->void:
	thinking=label
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.visibility_changed.connect(_place_thinking)
	label.resized.connect(_place_thinking)

func _on_more(bubble:Bubble)->void:
	history_requested.emit(bubble.ref)

## The room a speech bubble may take: its usual width, then a wide one.
func _bubble_widths(bubble:Bubble)->Array:
	var f:=figure(bubble.speaker)
	var across:=_usable_width() if f==null or f.home.x<_usable_width() else size.x
	var usual:=minf(clampf(across*.40,220.0,460.0),across-16.0)
	var wide:=maxf(usual,minf(minf(760.0,across*.72),across-16.0))
	return [usual,wide]

func _god_widths()->Array:
	var across:=_usable_width()
	var usual:=minf(minf(640.0,across*.62),across-16.0)
	return [usual,maxf(usual,minf(880.0,across-16.0))]

func _caption_widths()->Array:
	var across:=_usable_width()
	var usual:=minf(minf(720.0,across*.66),across-16.0)
	return [usual,maxf(usual,minf(900.0,across-16.0))]

## Fits a bubble's words to the free height of the stage now.
func _fit_bubble(bubble:Bubble)->void:
	if not is_instance_valid(bubble):return
	var free:=maxf(size.y-top_inset-14.0,40.0)
	match bubble.kind:
		"god":bubble.fit(_god_widths(),maxf(free*.46,60.0))
		"caption":bubble.fit(_caption_widths(),maxf(free*.38,48.0))
		_:bubble.fit(_bubble_widths(bubble),free)

func _turn_to(key:String,talk_time:=1.5)->void:
	var speaker:=figure(key)
	if speaker==null:return
	_show_plates()
	for other_key in cast_order:
		var f:=figure(other_key)
		if f==null or f.leaving:continue
		# Long words come with both hands now and then.
		if other_key==key:f.speak(talk_time,_talks%3==0 and talk_time>2.2)
		else:f.listen_to(speaker)

func _age_bubbles(fresh:Bubble,animate:bool)->void:
	## The line before stays faintly; the one before that goes, and so does
	## anything the new bubble would cover.
	var rect:=fresh.get_rect()
	for child in bubble_layer.get_children():
		var old:=child as Bubble
		if old==null or old==fresh or old.dropping or old.kind=="mutter":continue
		old.age+=1
		if old.age>=2 or old.speaker==fresh.speaker or old.get_rect().intersects(rect.grow(-4.0)):_drop(old,animate)
		else:old.fade_to(.42,animate)

func _age_god(animate:bool)->void:
	if not is_instance_valid(_god):return
	_god_age+=1
	if _god_age>=2:
		_drop(_god,animate);_drop(_rays,animate);_god=null;_rays=null
	else:
		_god.fade_to(.5,animate)
		if is_instance_valid(_rays):_rays.modulate.a=.4

func _age_caption(animate:bool)->void:
	if not is_instance_valid(_caption):return
	_caption_age+=1
	if _caption_age>=3:
		_drop(_caption,animate);_caption=null
	elif _caption_age==1:_caption.fade_to(.75,animate)

func _drop(item:Control,animate:bool)->void:
	if not is_instance_valid(item):return
	if item is Bubble:(item as Bubble).dropping=true
	item.set_meta("dropping",true)
	if animate and item.is_inside_tree() and not Motion.reduced():
		var tween:=item.create_tween()
		tween.tween_property(item,"modulate:a",0.0,Motion.duration(Motion.BASE))
		tween.tween_callback(item.queue_free)
	else:
		if item.get_parent()!=null:item.get_parent().remove_child(item)
		item.queue_free()

# --- Placement ------------------------------------------------------------------

func head_point(f:Figure)->Vector2:
	## Just over the head: a modelled figure's own head as it stands now; the
	## paintings put faces in their upper part.
	if f.body3d!=null and is_instance_valid(f.body3d) and f.body3d.is_inside_tree():
		# Where they will stand: words said while walking in hang over their place.
		return world_to_stage(f.body3d.head_top())+Vector2(-f.walk,-4.0)
	return Vector2(f.home.x,f.home.y-f.size.y*.94)

func _place_bubble(bubble:Bubble)->void:
	var f:=figure(bubble.speaker)
	if f==null:return
	var head:=head_point(f)
	var top_min:=top_inset+6.0
	var bs:=bubble.size
	var h:=size.y
	# Clear of the offered object's strip, unless the speaker stands in it.
	var right:=_usable_width() if f.home.x<_usable_width() and bs.x<_usable_width()-16.0 else size.x
	var above:=head.y-TAIL-bs.y
	if above>=top_min:
		var x:=clampf(head.x-bs.x*.5,8.0,maxf(8.0,right-bs.x-8.0))
		bubble.position=Vector2(x,above)
		bubble.tail_side="down";bubble.tip=Vector2(head.x-x,bs.y+TAIL)
	else:
		# No room above: beside the head, toward the middle of the stage, or
		# the other way if that side would hide someone else's face.
		var face:=Vector2(head.x,head.y+f.size.y*.14)
		var to_right:=face.x<right*.5
		var reach:=f.size.x*.30
		var x:=0.0;var y:=0.0
		var best:=INF
		for side_right:bool in [to_right,not to_right]:
			var cx:=face.x+reach+TAIL if side_right else face.x-reach-TAIL-bs.x
			cx=clampf(cx,8.0,maxf(8.0,right-bs.x-8.0))
			var cy:=clampf(face.y-bs.y*.5,top_min,maxf(top_min,h-bs.y-8.0))
			# Lift it clear of faces it would cover, as far as the room allows.
			for face_rect:Rect2 in _faces_except(bubble.speaker):
				if Rect2(Vector2(cx,cy),bs).intersects(face_rect):cy=maxf(top_min,minf(cy,face_rect.position.y-bs.y-4.0))
			var hidden:=0.0
			for face_rect:Rect2 in _faces_except(bubble.speaker):hidden+=Rect2(Vector2(cx,cy),bs).intersection(face_rect).get_area()
			if hidden<best-1.0:
				best=hidden;x=cx;y=cy;to_right=side_right
		bubble.position=Vector2(x,y)
		bubble.tail_side="left" if to_right else "right"
		bubble.tip=Vector2(face.x+reach-x,face.y-y) if to_right else Vector2(face.x-reach-x,face.y-y)
		# A bubble pushed back over its speaker has no side to point from.
		if (to_right and bubble.tip.x>-4.0) or (not to_right and bubble.tip.x<bs.x+4.0):bubble.tail_side="none"
	bubble.pivot_offset=bubble.tip.clamp(Vector2.ZERO,bs)
	bubble.home_y=0.0
	if bubble.speaker!=_focus_key:_clear_focus(bubble)
	_clear_of_others(bubble)
	bubble.queue_redraw()

## The faces of everyone standing here but one, as stage rectangles.
func _faces_except(key:String)->Array[Rect2]:
	var out:Array[Rect2]=[]
	for other in cast_order:
		var o:=figure(other)
		if o==null or o.leaving or other==key:continue
		var top:=head_point(o)
		out.append(Rect2(top.x-o.size.x*.22,top.y,o.size.x*.44,o.size.y*.24))
	return out

func _place_god()->void:
	if not is_instance_valid(_god):return
	_god.position=Vector2(((_usable_width()-_god.size.x)*.5),top_inset+10.0).round()
	_god.home_y=_god.position.y
	if is_instance_valid(_rays):
		_rays.target=Rect2(_god.position,_god.size);_rays.queue_redraw()

func _place_caption()->void:
	## A line under the picture. In the modelled hall it sits in a band at the
	## very foot of the stage, and goes to the top, under the god's band,
	## rather than lie over the face the camera is on.
	if not is_instance_valid(_caption):return
	var foot:=size.y-_caption.size.y-(8.0 if court_set!=null else PLATE_ROOM)
	_caption.position=Vector2((_usable_width()-_caption.size.x)*.5,maxf(top_inset+6.0,foot)).round()
	# When the camera has gone in on someone (a push-in, a two-shot, a
	# reaction), they fill the lower frame: the caption goes to the top band,
	# under the god's line, never over the one in the shot.
	var face:=_focus_face()
	var gone_in:=court_set!=null and not _wide_now()
	if gone_in or (face.size.x>0.0 and Rect2(_caption.position,_caption.size).intersects(face)):
		var high:=top_inset+6.0+(_god.size.y+6.0 if is_instance_valid(_god) and _god.visible else 0.0)
		_caption.position.y=round(high)
	_caption.home_y=_caption.position.y

## Bubbles never lie over one another: the god's line keeps the top centre
## and the caption its band; a speech bubble, a mutter or a noise steps down
## below whatever it would cover (toward its speaker's side if going down
## would cover the face the camera is on), its tail still to the speaker.
func _clear_of_others(bubble:Control)->void:
	if not is_instance_valid(bubble) or bubble==_god or bubble==_caption:return
	var others:Array[Rect2]=[]
	if is_instance_valid(_god) and _god.visible and _god.modulate.a>0.01:others.append(Rect2(_god.position,_god.size).grow(6.0))
	if is_instance_valid(_caption) and _caption.visible and _caption.modulate.a>0.01:others.append(Rect2(_caption.position,_caption.size).grow(6.0))
	for child in bubble_layer.get_children():
		var other:=child as Control
		if other==null or other==bubble or not other.visible or other.is_queued_for_deletion():continue
		if other is Bubble and ((other as Bubble).dropping or (other as Bubble).kind=="mutter" and bubble is Bubble and (bubble as Bubble).kind!="mutter"):continue
		others.append(Rect2(other.position,other.size).grow(4.0))
	var start:=bubble.position
	var rect:=Rect2(bubble.position,bubble.size)
	var face:=_focus_face()
	for turn in 12:
		var hit:=Rect2()
		for r in others:
			if r.intersects(rect):hit=r;break
		if hit.size.x<=0.0:break
		var down:=Rect2(Vector2(rect.position.x,hit.end.y+2.0),rect.size)
		if down.end.y<=size.y-4.0 and (face.size.x<=0.0 or not down.intersects(face)):
			rect=down
		else:
			# beside it instead, on the side with more room
			var left:=hit.position.x-rect.size.x-4.0
			var right:=hit.end.x+4.0
			rect.position.x=left if left>=4.0 and (hit.position.x>size.x-hit.end.x or right+rect.size.x>size.x-4.0) else minf(right,size.x-rect.size.x-4.0)
	if rect.position.is_equal_approx(start):return
	var moved:=rect.position-start
	bubble.position=rect.position.round()
	if bubble is Bubble:
		var b:=bubble as Bubble
		b.tip-=moved
		var bs:=b.size
		if (b.tail_side=="down" and b.tip.y<bs.y+2.0) or (b.tail_side=="left" and b.tip.x>-4.0) or (b.tail_side=="right" and b.tip.x<bs.x+4.0):b.tail_side="none"
		b.pivot_offset=b.tip.clamp(Vector2.ZERO,bs)
		b.queue_redraw()

## Everything said steps clear again (the god's line or the caption came or moved).
func _reclear_bubbles()->void:
	for child in bubble_layer.get_children():
		var c:=child as Control
		if c!=null and c.visible and not (c is Bubble and (c as Bubble).dropping):_clear_of_others(c)

## The face the camera is pushed in on, as a stage rectangle (empty: none).
func _focus_face()->Rect2:
	var f:=figure(_focus_key)
	if f==null or f.leaving:return Rect2()
	var top:=head_point(f)
	return Rect2(top.x-f.size.x*.30,top.y,f.size.x*.60,f.size.y*.28)

## A bubble never lies over the face the camera has gone in on: above it if
## there is room, else to the side with more room.
func _clear_focus(bubble:Control)->void:
	var face:=_focus_face()
	if face.size.x<=0.0 or not is_instance_valid(bubble):return
	var rect:=Rect2(bubble.position,bubble.size)
	if not rect.intersects(face.grow(4.0)):return
	if face.position.y-bubble.size.y-8.0>=top_inset+4.0:
		bubble.position.y=face.position.y-bubble.size.y-8.0
	elif face.position.x>size.x-face.end.x:
		bubble.position.x=maxf(6.0,face.position.x-bubble.size.x-10.0)
	else:
		bubble.position.x=minf(size.x-bubble.size.x-6.0,face.end.x+10.0)
	if bubble is Bubble:
		var b:=bubble as Bubble
		b.tail_side="none";b.queue_redraw()

func _place_thinking()->void:
	if not is_instance_valid(thinking) or not thinking.visible:return
	var f:=figure(MAIN)
	if f==null or f.leaving:
		thinking.position=Vector2((_usable_width()-thinking.size.x)*.5,size.y-thinking.size.y-12.0).round();return
	# Beside their face, so it never sits on the words they just said.
	var head:=head_point(f)
	var face:=Vector2(head.x+f.size.x*.36,head.y+f.size.y*.14)
	thinking.position=Vector2(clampf(face.x,8.0,maxf(8.0,_usable_width()-thinking.size.x-8.0)),clampf(face.y-thinking.size.y*.5,top_inset+6.0,maxf(top_inset+6.0,size.y-thinking.size.y-8.0))).round()

## The stage changed size: every bubble is fitted again to the new room and
## put back over its speaker.
func _replace_all()->void:
	for child in bubble_layer.get_children():
		var bubble:=child as Bubble
		if bubble!=null and not bubble.dropping:
			_fit_bubble(bubble);_place_bubble(bubble)
	if is_instance_valid(_god):_fit_bubble(_god)
	if is_instance_valid(_caption):_fit_bubble(_caption)
	_place_god();_place_caption();_place_thinking()
	_reclear_bubbles()

# =================================================================================
# A person standing on the stage.

class Figure extends Control:
	var key:=""
	var person:Dictionary={}
	var role:="court"
	var accent:=Color("6b5638")
	var rig:Control
	var painting:Painting
	var plate:PanelContainer
	var plate_box:VBoxContainer
	## Where their feet are, in the stage's pixels.
	var home:=Vector2.ZERO
	var leaving:=false
	var idle:=true
	## Where layout puts them, and how far off it they are while walking in or
	## out: a relayout and a walk never fight over the position.
	var base_pos:=Vector2.ZERO:
		set(value):base_pos=value;position=base_pos+Vector2(walk,0.0);_sync()
	var walk:=0.0:
		set(value):walk=value;position=base_pos+Vector2(walk,0.0);_sync()
	## The modelled body this figure moves (null: the painting stands instead),
	## its shade on the floor and the stage that maps pixels to the hall.
	var body3d:Node3D
	var shade3d:MeshInstance3D
	var _stage:WeakRef
	## What they do when nothing is asked of them, and which way they face.
	var rest_clip:="stand"
	## The mood the engine gives them (a beat's mood returns to it).
	var own_mood:="neutral"
	var rest_yaw:=0.0
	## How long their walk in takes, waiting at the door included (seconds).
	var walk_total:=0.0
	## Seconds until they stand on their mark (0: there, or not walking in).
	func arriving_in()->float:
		if leaving or stroll<=0.0 or _move==null or not _move.is_valid():return 0.0
		return maxf(walk_total-_move.get_total_elapsed_time(),0.0)
	## One of the acting's own stances they keep (K: "guard", "fire"), or "".
	var acting_stance:=""
	## How far they have sunk (put to death where they stood), in metres.
	var sink:=0.0:
		set(value):sink=value;_sync()
	## In a modelled court: the place they stand (on their mark), the mark's
	## name, how far a seat lifts them, and how far along the way in or out
	## they are (0 on their mark, 1 at the door).
	var spot:Node3D
	var mark_name:=""
	var lift:=0.0
	var stroll:=0.0:
		set(value):stroll=value;_sync()
	## A small step off their mark (spot-local metres): hiding behind someone,
	## edging forward, making room. Tweened out and back.
	var nudge:=Vector3.ZERO:
		set(value):nudge=value;_sync()
	## The director sent them in by the wrong side (they stop, lost, then
	## hurry round to their mark).
	var wrong_side:=false
	var _step:Tween
	var _path:=PackedVector3Array()
	var _act:Tween
	var _shift:Tween
	var _idle:Tween
	var _sway:Tween
	var _lean:Tween
	var _bob:Tween
	var _move:Tween
	var _shadow:=PackedVector2Array()

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		rig=Control.new();rig.name="Rig";rig.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(rig)
		painting=Painting.new();painting.name="Painting";rig.add_child(painting)
		plate=PanelContainer.new();plate.name="NamePlate";plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var style:=StyleBoxFlat.new();style.bg_color=Self.PLATE_BG;style.set_corner_radius_all(3)
		style.content_margin_left=9;style.content_margin_right=9;style.content_margin_top=3;style.content_margin_bottom=4
		plate.add_theme_stylebox_override("panel",style)
		plate_box=VBoxContainer.new();plate_box.add_theme_constant_override("separation",0);plate_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
		plate.add_child(plate_box);add_child(plate)
		plate.resized.connect(_place_plate)
		resized.connect(_fit)

	func _ready()->void:
		_fit()
		if idle:start_idle()

	## The figure moves a modelled body from now on; the painting steps aside.
	func attach_body(body:Node3D,shade:MeshInstance3D,stage:Control)->void:
		body3d=body;shade3d=shade;_stage=weakref(stage)
		painting.visible=false
		var h:=absi(String(person.get("name",key)).hash())
		rest_clip=body3d.rest_clip()
		body3d.play(rest_clip,0.0,float(h%600)/100.0)
		_sync();queue_redraw()

	func _sync()->void:
		## Puts the body where the layout puts this figure: feet on the foot
		## point, as tall as the box holds a person, nearer when lower.
		if body3d==null or not is_instance_valid(body3d) or _stage==null:return
		if spot!=null:
			var at:=_path_at(stroll)
			body3d.position=Vector3(at.x,lift-sink,at.z)+nudge
			_track()
			return
		var stage:=_stage.get_ref() as Control
		if stage==null or size.y<2.0:return
		var foot:=position+Vector2(size.x*.5,size.y)
		var depth:=80.0+(stage.size.y*.5-foot.y)*0.06
		var at:Vector3=stage.stage_to_world(foot,depth)
		var fill:=size.y*Self.FIGURE_FILL*Self.PX_M/(Self.Figure3D.REFERENCE_HEIGHT*cos(deg_to_rad(Self.CAMERA_PITCH)))
		body3d.position=at+Vector3(0.0,-sink*fill,0.0)
		body3d.scale=Vector3.ONE*fill
		if is_instance_valid(shade3d):
			shade3d.position=at+Vector3(0.0,0.02*fill,-0.35*fill)
			shade3d.rotation_degrees.x=Self.CAMERA_PITCH
			shade3d.scale=Vector3.ONE*fill

	## In a set this control follows the body on the screen: its box stands
	## over their feet, as tall as they are (the plate under it, the tooltip).
	func _track()->void:
		if spot==null or body3d==null or not is_instance_valid(body3d) or not body3d.is_inside_tree() or _stage==null:return
		var stage:=_stage.get_ref() as Control
		if stage==null:return
		var cam:=stage.get("camera") as Camera3D
		if cam==null or not cam.is_inside_tree() or cam.is_position_behind(body3d.global_position):return
		var foot:Vector2=stage.world_to_stage(body3d.global_position)
		var top:Vector2=stage.world_to_stage(body3d.global_position+Vector3.UP*body3d.body_height)
		var tall:=clampf(foot.y-top.y,8.0,4000.0)
		var box:=Vector2(tall*Self.FIGURE_ASPECT,tall)
		home=foot
		if size!=box:size=box
		position=(foot-Vector2(box.x*.5,box.y)).round()

	## The way between their mark and a point (spot-local), around the fire.
	func _route(far:Vector3)->PackedVector3Array:
		var out:=PackedVector3Array([Vector3.ZERO])
		var stage:=_stage.get_ref() as Control if _stage!=null else null
		# Round the set's things and the people standing (court_paths.gd).
		if stage!=null and stage.get("court_set")!=null and spot!=null:
			var planned:PackedVector3Array=stage.call("plan_walk",self,far)
			if planned.size()>=2:return planned
		if stage!=null and stage.get("court_set")!=null:
			var fire:=spot.to_local(stage.set_point("fire"))
			var a:=Vector2.ZERO;var b:=Vector2(far.x,far.z);var c:=Vector2(fire.x,fire.z)
			var ab:=b-a
			var t:=clampf((c-a).dot(ab)/maxf(ab.length_squared(),0.001),0.0,1.0)
			var near:=a+ab*t
			if near.distance_to(c)<1.5 and t>0.05 and t<0.95:
				var away:=(near-c).normalized() if near.distance_to(c)>0.01 else Vector2(-ab.y,ab.x).normalized()
				var bend:=c+away*1.9
				out.append(Vector3(bend.x,0.0,bend.y))
		out.append(far)
		return out

	func _path_at(along:float)->Vector3:
		if _path.size()<2 or along<=0.0:return Vector3.ZERO
		var total:=0.0
		for i in _path.size()-1:total+=_path[i].distance_to(_path[i+1])
		var want:=clampf(along,0.0,1.0)*total
		for i in _path.size()-1:
			var piece:=_path[i].distance_to(_path[i+1])
			if want<=piece or i==_path.size()-2:return _path[i].lerp(_path[i+1],clampf(want/maxf(piece,0.001),0.0,1.0))
			want-=piece
		return _path[_path.size()-1]

	func _path_length()->float:
		var total:=0.0
		for i in _path.size()-1:total+=_path[i].distance_to(_path[i+1])
		return total

	## Walking: turned the way they go along the path.
	func _stroll_step(value:float,inward:bool)->void:
		var ahead:=_path_at(clampf(value+(-0.02 if inward else 0.02),0.0,1.0))
		var here:=_path_at(value)
		var way:=ahead-here
		if Vector2(way.x,way.z).length()>0.002:
			body3d.rotation.y=lerp_angle(body3d.rotation.y,atan2(way.x,way.z),0.25)
		stroll=value

	func _stroll_in(delay:float)->void:
		var stage:=_stage.get_ref() as Control
		if wrong_side and not Motion.reduced():
			_stroll_in_wrong(delay);return
		_path=_route(spot.to_local(_door(stage,0)))
		stroll=1.0
		modulate.a=1.0
		if Motion.reduced():
			stroll=0.0;_settle_in();return
		var pace:float=float(Self.Figure3D.WALK_SPEED.walk_in)*float(body3d.body_height)/Self.Figure3D.REFERENCE_HEIGHT
		var time:=clampf(_path_length()/maxf(pace,0.1),1.0,6.5)
		walk_total=maxf(delay,0.0)+time
		var first:=_path_at(0.98)-_path_at(1.0)
		body3d.rotation.y=atan2(first.x,first.z)
		_clip("walk_in",0.0,0.0)
		_move=create_tween()
		if delay>0.0:
			# Not yet through the door: unseen until their turn.
			body3d.visible=false
			_move.tween_interval(delay)
			_move.tween_callback(func()->void:if is_instance_valid(body3d):body3d.visible=true)
		_move.tween_method(_stroll_step.bind(true),1.0,0.0,time)
		_move.tween_callback(_settle_in)

	## The set's door (0) and the way out beyond it (1) (M's door_points).
	func _door(stage:Control,which:int)->Vector3:
		var court:Variant=stage.get("court_set")
		if court is Node3D and (court as Node3D).has_method("door_points"):
			var points:Array=(court as Node3D).call("door_points")
			if points.size()>which:return points[which]
		return stage.set_point("door" if which==0 else "door_out")

	## In by the wrong side: from the far side of the hall, a few steps in,
	## a stop and a look about (someone points), then round to their mark.
	func _stroll_in_wrong(delay:float)->void:
		var stage:=_stage.get_ref() as Control
		var door:=_door(stage,0)
		var mine:=spot.global_position
		var wrong:=Vector3(2.0*mine.x-door.x,door.y,door.z)
		_path=_route(spot.to_local(wrong))
		stroll=1.0
		var pace:float=float(Self.Figure3D.WALK_SPEED.walk_in)*float(body3d.body_height)/Self.Figure3D.REFERENCE_HEIGHT
		var first:=_path_at(0.98)-_path_at(1.0)
		body3d.rotation.y=atan2(first.x,first.z)
		_clip("walk_in",0.0,0.0)
		walk_total=maxf(delay,0.0)+clampf(_path_length()*0.4/maxf(pace,0.1),0.6,3.0)+3.0
		_move=create_tween()
		if delay>0.0:_move.tween_interval(delay)
		var lost:=0.6
		_move.tween_method(_stroll_step.bind(true),1.0,lost,clampf(_path_length()*(1.0-lost)/maxf(pace,0.1),0.6,3.0))
		_move.tween_callback(func()->void:_clip(rest_clip,0.3);body3d.face(rest_yaw+60.0,0.4))
		_move.tween_interval(0.7)
		_move.tween_callback(func()->void:body3d.face(rest_yaw-50.0,0.5))
		_move.tween_interval(0.9)
		# Round to their mark, hurrying.
		_move.tween_callback(func()->void:
			var here:=_path_at(stroll)
			_path=_route(here)
			stroll=1.0
			_clip("walk_in",0.25,0.0))
		_move.tween_method(_stroll_step.bind(true),1.0,0.0,1.4)
		_move.tween_callback(func()->void:wrong_side=false;_settle_in())

	func _stroll_out(delay:float,style:String)->void:
		if _act and _act.is_valid():_act.kill()
		var stage:=_stage.get_ref() as Control
		_path=_route(spot.to_local(_door(stage,1)))
		if style in ["backward","backward_bump","storm_back"] and not Motion.reduced():
			_stroll_out_acted(delay,style);return
		_move=create_tween()
		if delay>0.0:_move.tween_interval(delay)
		if Motion.reduced():
			_move.tween_callback(_vanish);return
		var pace:float=float(Self.Figure3D.WALK_SPEED.walk_out)*float(body3d.body_height)/Self.Figure3D.REFERENCE_HEIGHT
		match style:
			"fall":
				_move.tween_callback(func()->void:body3d.face(rest_yaw*.3,0.3);_clip("kneel",0.3,0.0))
				_move.tween_interval(1.3)
				_move.tween_callback(func()->void:_light(0.55))
				_move.tween_property(self,"sink",0.9,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				_move.tween_callback(_vanish)
				return
			"led":
				_move.tween_callback(func()->void:_clip("kneel",0.3,0.0);_light(0.78))
				_move.tween_interval(1.1)
				_move.tween_callback(func()->void:_acted("walk_led","walk_out",0.3,{"loop":true});_light(0.66))
				pace=_pace_of("walk_led",pace*1.25)
			"storm":
				_move.tween_callback(func()->void:_acted("storm_walk","walk_in",0.25,{"loop":true}))
				pace=_pace_of("storm_walk",float(Self.Figure3D.WALK_SPEED.walk_in)*1.2*float(body3d.body_height)/Self.Figure3D.REFERENCE_HEIGHT)
			_:
				_move.tween_callback(func()->void:body3d.face(rest_yaw*.2,0.25);_clip("bow",0.3,0.0))
				_move.tween_interval(2.35)
				_move.tween_callback(func()->void:_clip("walk_out",0.35,0.0))
		var time:=clampf(_path_length()/maxf(pace,0.1),1.2,7.0)
		_move.tween_method(_stroll_step.bind(false),0.0,1.0,time)
		_move.tween_callback(_vanish)

	## Walking backward: they keep facing the hall (no turn with the path).
	func _back_step(value:float)->void:
		stroll=value

	## The exits the director acts out:
	##  "backward"       backing away bowing, a couple of metres, then out;
	##  "backward_bump"  the same, into the door post: a jolt, a bow to the
	##                   post, then out;
	##  "storm_back"     storming off, stopping short at the door, coming back
	##                   to their mark for what they left, and out again.
	func _stroll_out_acted(delay:float,style:String)->void:
		var whole:=maxf(_path_length(),0.5)
		var walk_pace:float=float(Self.Figure3D.WALK_SPEED.walk_out)*float(body3d.body_height)/Self.Figure3D.REFERENCE_HEIGHT
		_move=create_tween()
		if delay>0.0:_move.tween_interval(delay)
		if style.begins_with("backward"):
			var back:=clampf(2.2/whole,0.15,0.6)
			_move.tween_callback(func()->void:body3d.face(rest_yaw*.3,0.25);_clip("bow",0.3,0.0))
			if Self.acting!=null and Self.Acting.has_clip("back_out"):
				# The acting's own backing-away bow (K), a step at a time at its pace.
				_move.tween_interval(0.5)
				_move.tween_callback(func()->void:_acted("back_out","",0.25,{"loop":true}))
				_move.tween_method(_back_step,0.0,back,clampf(whole*back/maxf(_pace_of("back_out",0.42),0.1),1.2,5.0))
			else:
				# Bowing all the way, a bow and a half-step, and another.
				var bows:=3
				for i in bows:
					_move.tween_method(_back_step,back*float(i)/float(bows),back*float(i+1)/float(bows),0.8)
					_move.tween_callback(func()->void:_clip("bow",0.2,0.25))
			if style=="backward_bump":
				# Into the post: a jolt forward, a look round, a bow to the post.
				_move.tween_callback(func()->void:_acted("bump_post","",0.05))
				_move.tween_property(self,"nudge",Vector3(0.0,0.0,0.12),0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_move.tween_property(self,"nudge",Vector3.ZERO,0.2)
				_move.tween_callback(func()->void:
					var ahead:=_path_at(minf(back+0.05,1.0))-_path_at(back)
					body3d.rotation.y=atan2(ahead.x,ahead.z)
					_clip("bow",0.2,0.0))
				_move.tween_interval(maxf(1.1,_length_of("bump_post",1.1)-0.28))
			_move.tween_callback(func()->void:_let_go(0.3);_clip("walk_out",0.35,0.0))
			_move.tween_method(_stroll_step.bind(false),back,1.0,clampf(whole*(1.0-back)/maxf(walk_pace,0.1),0.8,6.0))
			_move.tween_callback(_vanish)
			return
		# Storming off, then back for what they left.
		var stride:=_pace_of("storm_walk",float(Self.Figure3D.WALK_SPEED.walk_in)*1.2*float(body3d.body_height)/Self.Figure3D.REFERENCE_HEIGHT)
		var door:=0.82
		_move.tween_callback(func()->void:_acted("storm_walk","walk_in",0.25,{"loop":true}))
		_move.tween_method(_stroll_step.bind(false),0.0,door,clampf(whole*door/maxf(stride,0.1),0.8,4.0))
		# Stopped short at the door: they remember.
		_move.tween_callback(func()->void:_clip(rest_clip,0.25);_acted("storm_stop","",0.06))
		_move.tween_interval(maxf(0.6,_length_of("storm_stop",0.6)-0.2))
		_move.tween_callback(func()->void:_acted("storm_walk","walk_in",0.25,{"loop":true}))
		_move.tween_method(_stroll_step.bind(true),door,0.0,clampf(whole*door/maxf(stride,0.1),0.8,4.0))
		# Snatched up: their stance (and its prop) for a moment.
		_move.tween_callback(func()->void:body3d.face(rest_yaw,0.2);_clip(rest_clip,0.2);_acted("snatch_up","",0.08))
		_move.tween_interval(maxf(0.7,_length_of("snatch_up",0.7)-0.1))
		_move.tween_callback(func()->void:_acted("storm_walk","walk_in",0.25,{"loop":true}))
		_move.tween_method(_stroll_step.bind(false),0.0,1.0,clampf(whole/maxf(stride,0.1),0.8,5.0))
		_move.tween_callback(_vanish)

	## A small step to a point in the hall (world), and back after a while.
	func step_to(world:Vector3,time:float,back_after:float)->void:
		if spot==null or body3d==null or leaving or not is_inside_tree():return
		if _step and _step.is_valid():_step.kill()
		var local:=spot.to_local(world)-_path_at(stroll)
		local.y=0.0
		if local.length()>1.2:local=local.normalized()*1.2
		_step=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_step.tween_property(self,"nudge",local,maxf(time,0.15))
		if back_after>0.0:
			_step.tween_interval(back_after)
			_step.tween_property(self,"nudge",Vector3.ZERO,0.6)

	## They turn to someone and bow to them, deeply (the wrong one); turned
	## back to the god after.
	func bow_toward(world:Vector3)->void:
		if body3d==null or leaving:return
		if _act and _act.is_valid():_act.kill()
		var way:=world-body3d.global_position
		var yaw:=rad_to_deg(atan2(way.x,way.z))
		if body3d.get_parent() is Node3D:yaw-=rad_to_deg((body3d.get_parent() as Node3D).global_rotation.y)
		body3d.face(yaw,0.3)
		_clip("bow",0.3,0.0)
		_later(2.2,func()->void:body3d.face(rest_yaw,0.4);_clip(rest_clip,0.4))

	func _clip(name:String,blend:=0.3,at:=-1.0)->void:
		if body3d!=null and is_instance_valid(body3d):body3d.play(name,blend,at)

	## One of the acting's clips (K: back_out, bump_post, storm_walk,
	## storm_stop, snatch_up, walk_led...) over the figure's own, when the
	## acting is plugged in and its library has it; the figure's own clip
	## (fallback) underneath either way.
	func _acted(name:String,fallback:String,blend:=0.25,opts:={})->void:
		if body3d==null or not is_instance_valid(body3d):return
		if not fallback.is_empty():_clip(fallback,blend,0.0)
		if Self.acting!=null and Self.Acting.has_clip(name) and body3d.is_inside_tree():
			var o:Dictionary=opts.duplicate();o["blend"]=blend
			Self.Acting.play(body3d,name,o)

	## The acting lets go of a looping walk (back to the figure's own clip).
	func _let_go(blend:=0.3)->void:
		if Self.acting!=null and body3d!=null and is_instance_valid(body3d) and body3d.is_inside_tree():Self.Acting.stop(body3d,blend)

	## How fast this body covers the hall in one of the acting's walks (its
	## own metres a second, for a 1.72 m body), else the given pace.
	func _pace_of(name:String,otherwise:float)->float:
		if Self.acting==null or not Self.Acting.has_clip(name):return otherwise
		var mps:=float(Self.Acting.clip_meta(name).get("speed_mps",0.0))
		if mps<=0.0:return otherwise
		return mps*float(body3d.body_height)/1.72

	## How long one of the acting's clips runs, else the given seconds.
	func _length_of(name:String,otherwise:float)->float:
		if Self.acting==null or not Self.Acting.has_clip(name):return otherwise
		return maxf(float(Self.Acting.clip_length(name)),0.2)

	## How much light falls where they stand (the set's), times the speaker's lift.
	var light_base:=1.0
	## Whether they have a name plate at all (attendants and onlookers do not).
	var named:=false
	func _light(amount:float)->void:
		if body3d!=null and is_instance_valid(body3d):body3d.set_light(amount*light_base)

	func _settle_in()->void:
		## Back to standing at rest, facing the hall.
		if body3d==null or leaving:return
		body3d.face(rest_yaw,0.35)
		_clip(rest_clip,0.45)

	func _later(seconds:float,what:Callable)->void:
		## One thing after a while (it replaces whatever was waiting).
		if _act and _act.is_valid():_act.kill()
		if not is_inside_tree():return
		_act=create_tween();_act.tween_interval(maxf(seconds,0.0));_act.tween_callback(what)

	## A director's act: its clip if the figure has it, else the fallback
	## clip, else nothing; back to their stance after dur unless held.
	func perform(clip:String,fallback:String,hold:bool,dur:float,speed:=1.0)->void:
		if body3d==null or leaving:return
		var name:=clip if body3d.player!=null and body3d.player.has_animation(clip) else fallback
		if name.is_empty() or body3d.player==null or not body3d.player.has_animation(name):return
		if _act and _act.is_valid():_act.kill()
		_clip(name,0.25,0.0)
		body3d.player.speed_scale=clampf(speed,0.25,3.0)
		if not hold:_later(maxf(dur,0.3),func()->void:
			body3d.player.speed_scale=1.0;_clip(rest_clip,0.4))

	## A director's mood beat: the face and bearing for a while, then their own.
	func feel(mood_name:String,face:Dictionary,hold:bool,dur:float)->void:
		if body3d==null or leaving:return
		if not mood_name.is_empty():body3d.set_mood(mood_name)
		if not face.is_empty():body3d.set_expression(face)
		if hold:return
		var cleared:={}
		for key in face:cleared[key]=0.0
		var back:=create_tween();back.tween_interval(maxf(dur,0.3))
		back.tween_callback(func()->void:
			if not is_instance_valid(body3d):return
			body3d.set_mood(own_mood)
			if not cleared.is_empty():body3d.set_expression(cleared))

	## A gesture now: "bow", "point", "raise_hand" (then back to rest), or
	## "kneel" (hold: they stay down until something else is asked of them).
	func gesture(clip:String,hold:=false)->void:
		if leaving:return
		if body3d==null:
			# The painting dips: down for dread, a nod for reverence.
			_pose(0.0,0.0,0.92 if clip=="kneel" else 0.98,Color(.95,.93,.9))
			return
		if _act and _act.is_valid():_act.kill()
		body3d.face(rest_yaw*.5,0.25)
		_clip(clip,0.3,0.0)
		if not hold:_later(body3d.clip_length(clip)+0.1,_settle_in)

	func set_names(name_text:String,title_text:String,big:=false)->void:
		for child in plate_box.get_children():plate_box.remove_child(child);child.queue_free()
		if not name_text.is_empty():
			var who:=HudTokens.make_label(name_text,16 if big else 13,Self.CREAM);who.name="FigureName"
			who.add_theme_font_override("font",HudTokens.font("ui_strong"));who.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;who.mouse_filter=Control.MOUSE_FILTER_IGNORE
			plate_box.add_child(who)
		if not title_text.is_empty():
			var what:=HudTokens.make_label(title_text,13 if big else 12,Self.CREAM_DIM);what.name="FigureTitle"
			what.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;what.mouse_filter=Control.MOUSE_FILTER_IGNORE
			plate_box.add_child(what)
		plate.visible=plate_box.get_child_count()>0

	## Something more on their plate (love and dread, a flag, a badge).
	func add_to_plate(item:Control)->void:
		plate_box.add_child(item);plate.visible=true

	func _fit()->void:
		rig.size=size;rig.pivot_offset=Vector2(size.x*.5,size.y)
		painting.size=size;painting.pivot_offset=Vector2(size.x*.5,size.y)
		painting.set_box(size)
		_shadow=PackedVector2Array()
		var centre:=Vector2(size.x*.5,size.y-3.0);var radii:=Vector2(size.x*.40,maxf(3.0,size.y*.03))
		for i in 20:
			var a:=TAU*float(i)/20.0
			_shadow.append(centre+Vector2(cos(a)*radii.x,sin(a)*radii.y))
		_place_plate();queue_redraw()

	func _place_plate()->void:
		plate.size=plate.get_combined_minimum_size()
		# A still of a modelled figure stands above its plate, not behind it.
		if painting.cutout and plate.visible:
			painting.size=Vector2(size.x,maxf(size.y-plate.size.y-4.0,size.y*.5))
			painting.pivot_offset=Vector2(painting.size.x*.5,painting.size.y)
		# Under a modelled figure's feet; over a painting's lower edge.
		var y:=size.y+4.0 if body3d!=null else size.y-plate.size.y-2.0
		plate.position=Vector2((size.x-plate.size.x)*.5,y).round()

	func _draw()->void:
		# A modelled figure has its own shade on the floor of the hall.
		if body3d==null and _shadow.size()>2:draw_colored_polygon(_shadow,Color(0,0,0,.30))

	## Stand at a place: feet at `foot` (the parent's pixels), this tall.
	func place(foot:Vector2,box:Vector2,animate:bool)->void:
		var moved:=home!=foot or size!=box
		home=foot
		size=box
		var target:=(foot-Vector2(box.x*.5,box.y)).round()
		if _shift and _shift.is_valid():_shift.kill()
		if animate and moved and is_inside_tree() and base_pos!=Vector2.ZERO:
			_shift=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_shift.tween_property(self,"base_pos",target,Motion.duration(Motion.SLOW))
		else:base_pos=target
		if body3d!=null and not leaving and walk==0.0:body3d.face(rest_yaw,0.3 if animate else 0.0)
		_sync()

	func start_idle()->void:
		## Breathing and a slow sway, a little different for each (a modelled
		## figure breathes in its own clip).
		if body3d!=null or Motion.reduced() or not is_inside_tree():return
		var seed_value:=float(absi(String(person.get("name",key)).hash())%997)/997.0
		var breath:=1.8+seed_value*.7
		_idle=create_tween().set_loops()
		_idle.tween_property(painting,"scale",Vector2(1.0,1.014),breath).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_idle.tween_property(painting,"scale",Vector2.ONE,breath).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var sway:=deg_to_rad(.5+seed_value*.3)
		painting.rotation=-sway*seed_value
		_sway=create_tween().set_loops()
		_sway.tween_property(painting,"rotation",sway,2.8+seed_value*1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_sway.tween_property(painting,"rotation",-sway,2.8+seed_value*1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	func _pose(angle:float,step:float,grow:float,light:Color)->void:
		if not is_inside_tree():return
		if _lean and _lean.is_valid():_lean.kill()
		var time:=Motion.duration(Motion.SLOW)
		_lean=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_lean.tween_property(rig,"rotation",angle,time)
		_lean.tween_property(rig,"position:x",step,time)
		_lean.tween_property(rig,"scale",Vector2(grow,grow),time)
		_lean.tween_property(rig,"modulate",light,time)

	## They speak: a step forward into the light and a small lift, as with a
	## gesture on the first words. A modelled figure talks with its hands and
	## mouth for as long as the words take, then stands at rest again.
	func speak(seconds:=1.5,both_hands:=false)->void:
		if leaving:return
		if body3d!=null:
			if _act and _act.is_valid():_act.kill()
			# They turn a little to the god they answer and speak with their hands.
			body3d.face(rest_yaw*.55,0.35)
			var stage:=_stage.get_ref() as Control if _stage!=null else null
			if stage!=null:body3d.look_at_point(stage.god_point(),0.5)
			_clip(body3d.talk_clip(both_hands),0.35)
			_light(1.06)
			_later(seconds,func()->void:
				_clip(rest_clip,0.5);_light(1.0);body3d.face(rest_yaw,0.5))
			return
		_pose(0.0,0.0,1.035,Color(1.07,1.05,1.0))
		if not is_inside_tree() or Motion.reduced():return
		if _bob and _bob.is_valid():_bob.kill()
		_bob=create_tween().set_trans(Tween.TRANS_SINE)
		_bob.tween_property(rig,"position:y",-7.0,.16).set_ease(Tween.EASE_OUT)
		_bob.tween_property(rig,"position:y",0.0,.22).set_ease(Tween.EASE_IN_OUT)
		_bob.tween_property(rig,"position:y",-3.0,.14).set_ease(Tween.EASE_OUT)
		_bob.tween_property(rig,"position:y",0.0,.18).set_ease(Tween.EASE_IN_OUT)

	## Someone else speaks: they look at them, half turned toward them,
	## still in their own stance.
	func listen_to(speaker:Figure)->void:
		if leaving:return
		if body3d==null or speaker==null or speaker.body3d==null:
			listen_toward(speaker.home.x if speaker!=null else home.x);return
		if _act and _act.is_valid():_act.kill()
		var toward:=clampf((speaker.home.x-home.x)/maxf(size.x*3.0,1.0)*90.0,-55.0,55.0)
		if spot!=null:
			var to:=spot.to_local(speaker.body3d.global_position)
			toward=clampf(rad_to_deg(atan2(to.x,to.z)),-75.0,75.0)
		body3d.face(lerpf(rest_yaw,toward,.45),0.5)
		body3d.look_at_point(speaker.body3d.head_top()+Vector3(0.0,-0.10*speaker.body3d.scale.y,0.0),0.45)
		_clip(rest_clip,0.45)
		_light(0.95)

	## Someone else speaks: they turn a little toward them and listen.
	func listen_toward(x:float)->void:
		if leaving:return
		if body3d!=null:
			if _act and _act.is_valid():_act.kill()
			# Facing the hall, the speaker on the right is on their left.
			body3d.face(rest_yaw,0.3)
			_clip(rest_clip,0.4)
			_light(0.93)
			return
		var side:=signf(x-home.x)
		_pose(deg_to_rad(1.6)*side,4.0*side,1.0,Color(.90,.89,.87))

	## The god speaks: every face lifts toward the voice.
	func look_up()->void:
		if leaving:return
		if body3d!=null:
			if _act and _act.is_valid():_act.kill()
			# Every face lifts to the god's voice, from where they stand.
			body3d.face(rest_yaw*.5,0.45)
			var stage:=_stage.get_ref() as Control if _stage!=null else null
			if stage!=null:body3d.look_at_point(stage.god_point(true),0.5)
			_clip(rest_clip,0.5)
			_light(1.03)
			return
		_pose(0.0,0.0,1.0,Color(1.03,1.02,.98))
		if not is_inside_tree() or Motion.reduced():return
		if _bob and _bob.is_valid():_bob.kill()
		_bob=create_tween().set_trans(Tween.TRANS_SINE)
		_bob.tween_property(rig,"position:y",-4.0,.3).set_ease(Tween.EASE_OUT)
		_bob.tween_property(rig,"position:y",0.0,.5).set_ease(Tween.EASE_IN_OUT)

	## Walk in from the side: a few steps, into place.
	func enter_from(side:float,distance:float,delay:float=0.0)->void:
		if not is_inside_tree():return
		if _move and _move.is_valid():_move.kill()
		if body3d!=null and spot!=null:
			_stroll_in(delay);return
		if body3d!=null:
			_walk_in(side,distance,delay);return
		modulate.a=0.0
		if Motion.reduced():
			walk=0.0
			_move=create_tween();_move.tween_property(self,"modulate:a",1.0,Motion.duration(Motion.BASE))
			return
		walk=side*distance
		var time:=Motion.SCENE*1.2
		_move=create_tween()
		if delay>0.0:_move.tween_interval(delay)
		_move.set_parallel(true)
		_move.tween_property(self,"walk",0.0,time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_move.tween_property(self,"modulate:a",1.0,Motion.SLOW)
		_steps(delay,time)

	## Take their leave. "bow": a small bow, then out the way they came;
	## "storm": out briskly, no bow; "led": darkened and taken out quickly;
	## "fall": put to death, they sink and are gone where they stood.
	var exit_style:=""
	func leave(side:float,distance:float,delay:float=0.0,style:="bow")->void:
		leaving=true;exit_style=style
		# Sent away before their turn through the door: they simply do not come.
		if body3d!=null and spot!=null and not body3d.visible and _move!=null and _move.is_valid():
			_move.kill();_vanish();return
		# Off the staff (or up from the fire) before they walk.
		if not acting_stance.is_empty() and Self.acting!=null and body3d!=null and is_instance_valid(body3d) and body3d.is_inside_tree():
			Self.Acting.idle(body3d,String(body3d.stance))
			acting_stance=""
		if spot==null:
			if style.begins_with("backward"):style="bow"
			elif style=="storm_back":style="storm"
		if not is_inside_tree():return
		if _move and _move.is_valid():_move.kill()
		if _lean and _lean.is_valid():_lean.kill()
		if _bob and _bob.is_valid():_bob.kill()
		if body3d!=null and spot!=null:
			_stroll_out(delay,style);return
		if body3d!=null:
			_walk_out(side,distance,delay,style);return
		_move=create_tween()
		if delay>0.0:_move.tween_interval(delay)
		if Motion.reduced():
			_move.tween_property(self,"modulate:a",0.0,Motion.duration(Motion.BASE))
			return
		match style:
			"fall":
				# No walk: they sink, darken and are gone.
				_move.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				_move.tween_property(rig,"scale",Vector2(1.0,.86),.9)
				_move.tween_property(rig,"rotation",deg_to_rad(-4.0 if side<0.0 else 4.0),.9)
				_move.tween_property(rig,"modulate",Color(.45,.40,.38),.7)
				_move.tween_property(self,"modulate:a",0.0,.8).set_delay(.5)
			"led":
				# Taken out: no bow, darkened, hurried off.
				_move.tween_property(rig,"modulate",Color(.62,.58,.55),.25)
				var quick:=Motion.SCENE*.8
				_move.tween_property(self,"walk",side*distance,quick).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				_move.parallel().tween_property(self,"modulate:a",0.0,quick*.8).set_delay(quick*.2)
				_steps(delay+.25,quick)
			"storm":
				var brisk:=Motion.SCENE
				_move.tween_property(self,"walk",side*distance,brisk).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				_move.parallel().tween_property(self,"modulate:a",0.0,brisk*.9).set_delay(brisk*.1)
				_steps(delay,brisk)
			_:
				_move.tween_property(rig,"scale",Vector2(1.0,.965),.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				_move.tween_property(rig,"scale",Vector2.ONE,.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				var time:=Motion.SCENE*1.3
				_move.tween_property(self,"walk",side*distance,time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				_move.parallel().tween_property(self,"modulate:a",0.0,time*.9).set_delay(time*.1)
				_steps(delay+.58,time)

	func finish_moves()->void:
		for tween in [_shift,_move,_bob,_lean]:
			if tween!=null and (tween as Tween).is_valid():(tween as Tween).custom_step(30.0)
		if body3d!=null and is_instance_valid(body3d):
			if leaving:
				if spot==null and exit_style!="fall":walk=-maxf(home.x+size.x,1.0)
				nudge=Vector3.ZERO
				_vanish()
			elif spot!=null and stroll!=0.0:
				stroll=0.0;_settle_in()
			elif walk!=0.0:
				walk=0.0;_settle_in()

	func _vanish()->void:
		## Gone from the hall: hidden, and their clip no longer runs.
		if body3d!=null and is_instance_valid(body3d):
			body3d.visible=false
			if body3d.player!=null:body3d.player.stop()
			body3d.process_mode=Node.PROCESS_MODE_DISABLED
		if is_instance_valid(shade3d):shade3d.visible=false

	## A modelled figure walks in from beyond the edge, turned the way it
	## goes, at its walking pace; then turns to the hall and stands at rest.
	func _walk_in(side:float,distance:float,delay:float)->void:
		modulate.a=0.0
		walk=side*distance
		if Motion.reduced():
			walk=0.0;_settle_in()
			_move=create_tween();_move.tween_property(self,"modulate:a",1.0,Motion.duration(Motion.BASE))
			return
		var pace:=maxf(size.y*Self.FIGURE_FILL/Self.Figure3D.REFERENCE_HEIGHT*float(Self.Figure3D.WALK_SPEED.walk_in),1.0)
		var time:=clampf(distance/pace,0.8,3.6)
		body3d.face(-82.0*side,0.0)
		_clip("walk_in",0.0,0.0)
		_move=create_tween()
		if delay>0.0:_move.tween_interval(delay)
		_move.tween_property(self,"walk",0.0,time)
		_move.parallel().tween_property(self,"modulate:a",1.0,Motion.SLOW)
		_move.tween_callback(_settle_in)

	## How each leaves: "bow" bows, then turns and walks out; "storm" turns on
	## the spot and strides off; "led" goes down on one knee, then is taken out
	## head bowed and in shadow; "fall" goes down where they stand and sinks.
	func _walk_out(side:float,distance:float,delay:float,style:String)->void:
		if _act and _act.is_valid():_act.kill()
		_move=create_tween()
		if delay>0.0:_move.tween_interval(delay)
		if Motion.reduced():
			_move.tween_property(self,"modulate:a",0.0,Motion.duration(Motion.BASE))
			_move.tween_callback(_vanish)
			return
		var pace:=maxf(size.y*Self.FIGURE_FILL/Self.Figure3D.REFERENCE_HEIGHT,1.0)
		match style:
			"fall":
				_move.tween_callback(func()->void:body3d.face(rest_yaw*.3,0.3);_clip("kneel",0.3,0.0))
				_move.tween_interval(1.3)
				_move.tween_callback(func()->void:_light(0.55))
				_move.tween_property(self,"sink",0.55,1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				_move.parallel().tween_property(self,"modulate:a",0.0,0.8)
				_move.tween_callback(_vanish)
				return
			"led":
				_move.tween_callback(func()->void:_clip("kneel",0.3,0.0);_light(0.78))
				_move.tween_interval(1.1)
				_move.tween_callback(func()->void:body3d.face(82.0*side,0.25);_clip("walk_out",0.3,0.0);_light(0.66))
				pace*=float(Self.Figure3D.WALK_SPEED.walk_out)*1.25
			"storm":
				_move.tween_callback(func()->void:body3d.face(82.0*side,0.2);_clip("walk_in",0.25,0.0))
				pace*=float(Self.Figure3D.WALK_SPEED.walk_in)*1.2
			_:
				_move.tween_callback(func()->void:body3d.face(rest_yaw*.2,0.25);_clip("bow",0.3,0.0))
				_move.tween_interval(2.35)
				_move.tween_callback(func()->void:body3d.face(82.0*side,0.35);_clip("walk_out",0.35,0.0))
				pace*=float(Self.Figure3D.WALK_SPEED.walk_out)
		var time:=clampf(distance/maxf(pace,1.0),0.9,4.0)
		_move.tween_property(self,"walk",side*distance,time)
		_move.parallel().tween_property(self,"modulate:a",0.0,0.4).set_delay(maxf(time-0.4,0.0))
		_move.tween_callback(_vanish)

	func _steps(delay:float,time:float)->void:
		## The small rise and fall of walking.
		if _bob and _bob.is_valid():_bob.kill()
		_bob=create_tween().set_trans(Tween.TRANS_SINE)
		if delay>0.0:_bob.tween_interval(delay)
		var step:=time/8.0
		for i in 4:
			_bob.tween_property(rig,"position:y",-5.0,step).set_ease(Tween.EASE_OUT)
			_bob.tween_property(rig,"position:y",0.0,step).set_ease(Tween.EASE_IN)

# =================================================================================

class Painting extends Control:
	## The person's painting, cropped to stand upright, its ground feathered
	## away by the figure shader.
	var texture:Texture2D:
		set(value):texture=value;queue_redraw()
	var flip:=false:
		set(value):flip=value;queue_redraw()
	## Which part of the picture to keep when it must be cropped.
	var focus:=Vector2(.5,.16)
	## A still of a modelled figure: drawn whole, feet on the floor, no vignette.
	var cutout:=false:
		set(value):cutout=value;material=null if cutout else _material;queue_redraw()
	var _material:ShaderMaterial

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_material=ShaderMaterial.new();_material.shader=Self.figure_shader();material=_material

	func set_box(box:Vector2)->void:
		_material.set_shader_parameter("box",box)
		queue_redraw()

	func _draw()->void:
		if texture==null or size.x<2.0 or size.y<2.0:return
		var tex:=texture.get_size()
		if tex.x<=0.0 or tex.y<=0.0:return
		if cutout:
			var fit:=minf(size.x/tex.x,size.y/tex.y)
			var shown:=tex*fit
			draw_texture_rect(texture,Rect2(Vector2((size.x-shown.x)*.5,size.y-shown.y),shown),false)
			return
		var aspect:=size.x/size.y
		var source:=Rect2(Vector2.ZERO,tex)
		if tex.x/tex.y>aspect:
			var cut:=tex.y*aspect;source=Rect2(Vector2((tex.x-cut)*focus.x,0.0),Vector2(cut,tex.y))
		else:
			var cut:=tex.x/aspect;source=Rect2(Vector2(0.0,(tex.y-cut)*focus.y),Vector2(tex.x,cut))
		if flip:draw_set_transform(Vector2(size.x,0.0),0.0,Vector2(-1.0,1.0))
		draw_texture_rect_region(texture,Rect2(Vector2.ZERO,size),source)
		if flip:draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

# =================================================================================

class Bubble extends Control:
	## A paper bubble with its tail on the speaker; also the god's band and
	## the caption slip (no tail). It keeps its words and fits them to the room
	## the stage gives it: wider first, then a smaller letter, and only at the
	## last the words that fit, with "more" leading to the rest in Earlier.
	signal more_pressed
	var label:Label
	var kind:="speech"
	var speaker:=""
	var tail_side:="none"
	var tip:=Vector2.ZERO
	var age:=0
	var dropping:=false
	var home_y:=0.0
	var fill:=Color.WHITE
	var rule:=Color.BLACK
	## The history entry these words belong to (-1: none).
	var ref:=-1
	## The whole of what was said; label.text may hold only the start of it.
	var text:=""
	var truncated:=false
	var sizes:Array[int]=[19]
	var _font:Font
	var _pad:=Vector2(16.0,10.0)
	var _top:=10.0
	var _more:Button
	var _style:StyleBoxFlat
	var _tween:Tween

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE

	func setup(words:String,font:Font,font_size:int,ink:Color,paper:Color,rule_color:Color,max_width:float,centred:=false,kicker:="",smallest:int=-1)->void:
		text=words;fill=paper;rule=rule_color;_font=font
		sizes=[font_size]
		var floor_size:=smallest if smallest>0 else font_size-4
		for step in range(font_size-2,floor_size-1,-2):sizes.append(step)
		if sizes[-1]!=floor_size and floor_size<font_size:sizes.append(floor_size)
		_style=StyleBoxFlat.new();_style.bg_color=paper;_style.border_color=rule_color
		_style.shadow_color=Color(0,0,0,.28);_style.shadow_size=6;_style.shadow_offset=Vector2(0,2)
		match kind:
			"god":
				_style.set_corner_radius_all(3);_style.border_width_top=2;_style.border_width_bottom=2;_style.border_width_left=1;_style.border_width_right=1
				_pad=Vector2(22.0,10.0)
			"caption":
				_style.set_corner_radius_all(3);_style.border_width_top=1;_style.border_width_bottom=1
				_style.shadow_size=4;_pad=Vector2(16.0,7.0)
			_:
				_style.set_corner_radius_all(12);_style.set_border_width_all(2)
		_top=_pad.y
		if not kicker.is_empty():
			var note:=HudTokens.make_label(kicker.to_upper() if kind!="aside" else kicker,12,Self.KICKER_INK,.1 if kind!="aside" else 0.0)
			note.name="Kicker";note.mouse_filter=Control.MOUSE_FILTER_IGNORE
			if kind=="aside":note.add_theme_font_override("font",HudTokens.voice_font(true))
			add_child(note);note.position=Vector2(_pad.x,_pad.y-2.0)
			_top+=note.get_combined_minimum_size().y-2.0
		label=Label.new();label.name="Said";label.text=words;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",font_size)
		label.add_theme_color_override("font_color",ink)
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label.visible_characters_behavior=TextServer.VC_CHARS_AFTER_SHAPING
		if centred:label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		label.position=Vector2(_pad.x,_top)
		fit([max_width],1.0e6)

	## Fits the words to the room: each width in turn at each letter size,
	## largest letter first; failing all, the words that fit and "more".
	func fit(widths:Array,max_height:float)->void:
		for font_size in sizes:
			for width in widths:
				if _try(float(width),font_size,max_height,false):return
		_try(float(widths[-1]),sizes[-1],max_height,true)

	func _measure(words:String,inner:float)->float:
		label.text=words
		label.size=Vector2(inner,1.0)
		return label.get_minimum_size().y

	func _try(width:float,font_size:int,max_height:float,cut:bool)->bool:
		label.add_theme_font_size_override("font_size",font_size)
		var room_w:=width-_pad.x*2.0
		var natural:=_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+4.0
		var inner:=clampf(natural,minf(110.0,room_w),maxf(60.0,room_w))
		var room_h:=max_height-_top-_pad.y
		var tall:=_measure(text,inner)
		if tall<=room_h:
			_settle(inner,tall,false);return true
		if not cut:return false
		# The words that fit, then "more": the rest is in Earlier.
		var more_h:=24.0
		var words:=text.split(" ",false)
		var lo:=1;var hi:=maxi(1,words.size()-1);var best:=1
		while lo<=hi:
			var mid:=(lo+hi)/2
			if _measure(" ".join(words.slice(0,mid))+"…",inner)<=room_h-more_h:
				best=mid;lo=mid+1
			else:hi=mid-1
		tall=_measure(" ".join(words.slice(0,best))+"…",inner)
		_settle(inner,tall,true)
		return true

	func _settle(inner:float,tall:float,cut:bool)->void:
		truncated=cut
		if not cut and label.text!=text:label.text=text
		label.size=Vector2(inner,tall)
		var more_h:=0.0
		if cut:
			if _more==null:
				_more=Button.new();_more.name="More";_more.text="more in Earlier ›";_more.flat=true;_more.focus_mode=Control.FOCUS_NONE
				_more.mouse_filter=Control.MOUSE_FILTER_STOP;_more.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
				_more.add_theme_font_size_override("font_size",12)
				for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:_more.add_theme_color_override(state,Self.KICKER_INK)
				_more.tooltip_text="Read all of it in Earlier."
				_more.pressed.connect(func()->void:more_pressed.emit())
				add_child(_more)
			_more.visible=true
			_more.size=_more.get_combined_minimum_size()
			more_h=_more.size.y
		elif _more!=null:_more.visible=false
		size=Vector2(inner+_pad.x*2.0,_top+tall+_pad.y+more_h)
		if cut:_more.position=Vector2(size.x-_pad.x-_more.size.x+6.0,_top+tall+_pad.y*.4).round()
		queue_redraw()

	func _draw()->void:
		if _style==null:return
		_style.draw(get_canvas_item(),Rect2(Vector2.ZERO,size))
		if tail_side=="none":return
		var line:=2.0
		var half:=9.0
		var points:PackedVector2Array
		match tail_side:
			"down":
				var bx:=clampf(tip.x,18.0,maxf(18.0,size.x-18.0))
				points=PackedVector2Array([Vector2(bx-half,size.y-line),Vector2(bx+half,size.y-line),tip])
			"left":
				var by:=clampf(tip.y,16.0,maxf(16.0,size.y-16.0))
				points=PackedVector2Array([Vector2(line,by-half),Vector2(line,by+half),tip])
			"right":
				var by:=clampf(tip.y,16.0,maxf(16.0,size.y-16.0))
				points=PackedVector2Array([Vector2(size.x-line,by-half),Vector2(size.x-line,by+half),tip])
			_:return
		if kind=="aside":
			# A whisper: small rounds instead of a pointed tail.
			var base:=(points[0]+points[1])*.5
			for i in 3:
				var t:=(float(i)+1.0)/3.6
				var at:=base.lerp(tip,t)
				var r:=5.0-float(i)*1.4
				draw_circle(at,r,fill);draw_arc(at,r,0.0,TAU,16,rule,1.5,true)
			return
		draw_colored_polygon(points,fill)
		draw_line(points[0],tip,rule,line,true)
		draw_line(points[1],tip,rule,line,true)

	func pop_in()->void:
		if not is_inside_tree() or Motion.reduced():return
		scale=Vector2(.86,.86);modulate.a=0.0
		_tween=create_tween().set_parallel(true)
		_tween.tween_property(self,"scale",Vector2.ONE,Motion.duration(.24)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self,"modulate:a",1.0,Motion.duration(Motion.FAST))

	func descend()->void:
		## The god's words come down a little as they appear.
		if not is_inside_tree() or Motion.reduced():return
		position.y=home_y-14.0;modulate.a=0.0
		_tween=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self,"position:y",home_y,Motion.duration(Motion.SLOW))
		_tween.tween_property(self,"modulate:a",1.0,Motion.duration(Motion.SLOW))

	func rise_in()->void:
		if not is_inside_tree() or Motion.reduced():return
		position.y=home_y+6.0;modulate.a=0.0
		_tween=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self,"position:y",home_y,Motion.duration(Motion.BASE))
		_tween.tween_property(self,"modulate:a",1.0,Motion.duration(Motion.BASE))

	func fade_to(alpha:float,animate:bool)->void:
		if _tween and _tween.is_valid():_tween.kill()
		scale=Vector2.ONE
		if home_y!=0.0:position.y=home_y
		if not animate or not is_inside_tree() or Motion.reduced():modulate.a=alpha;return
		_tween=create_tween()
		_tween.tween_property(self,"modulate:a",alpha,Motion.duration(Motion.SLOW))

	func finish()->void:
		## Ends any entrance at once (used when everything is shown at once).
		if _tween and _tween.is_valid():_tween.custom_step(10.0)

	## The words of the terrified shake a little (never what they say): each
	## letter's line jitters about a pixel at about eleven times a second for
	## a while, then settles.
	var _shake:Tween
	func tremble(amount:float,seconds:float)->void:
		if label==null or not is_inside_tree() or Motion.reduced():return
		if _shake and _shake.is_valid():_shake.kill()
		var base:=label.position
		var reach:=0.6+1.2*clampf(amount,0.0,1.0)
		var rng:=RandomNumberGenerator.new();rng.seed=hash(text)
		_shake=create_tween()
		for i in clampi(int(seconds*11.0),4,80):
			_shake.tween_property(label,"position",base+Vector2(rng.randf_range(-reach,reach),rng.randf_range(-reach,reach)*0.7),1.0/11.0)
		_shake.tween_property(label,"position",base,0.12)

# =================================================================================

class Rays extends Control:
	## Light falling from above onto the god's words.
	var target:=Rect2()

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE

	func _draw()->void:
		if target.size.x<4.0:return
		var apex:=Vector2(target.get_center().x,-40.0)
		var low:=target.end.y+maxf(30.0,target.size.y*.8)
		var gold:=Self.GOD_GOLD
		for i in 7:
			var t:=(float(i)-3.0)/3.0
			var spread:=target.size.x*.62
			var cx:=target.get_center().x+t*spread
			var width:=target.size.x*(.07+.03*(1.0-absf(t)))
			var points:=PackedVector2Array([apex+Vector2(t*12.0,0),Vector2(cx-width,low),Vector2(cx+width,low)])
			var colours:=PackedColorArray([Color(gold,.20),Color(gold,0.0),Color(gold,0.0)])
			draw_polygon(points,colours)
		var glow:=Rect2(target.position-Vector2(18,10),target.size+Vector2(36,20))
		draw_rect(glow,Color(gold,.10))

# =================================================================================

class Glyph extends Control:
	## A noise made visible: a tiny wordless bubble, ink on paper (the icon
	## engine's manner: a disc and a few strokes). glyph: zzz, cough, growl,
	## creak, gulp, snort, clatter, thump, clap, yawn, gasp, bleat, whimper,
	## slap; anything else is three dots.
	var glyph:="dots"

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size=Vector2(34.0,30.0)

	func _draw()->void:
		var c:=size*0.5
		var ink:=Color("3b2f22")
		draw_circle(c,13.0,Color(Self.ASIDE_PAPER,0.94))
		draw_arc(c,13.0,0.0,TAU,28,Color(ink,0.75),1.5,true)
		var w:=1.8
		match glyph:
			"zzz":
				for i in 3:
					var o:=c+Vector2(-6.0+i*4.5,4.0-i*4.5)
					var k:=2.2+i*0.6
					draw_polyline(PackedVector2Array([o+Vector2(-k,-k),o+Vector2(k,-k),o+Vector2(-k,k),o+Vector2(k,k)]),ink,w,true)
			"cough":
				draw_circle(c+Vector2(-2,1),3.5,ink)
				for i in 6:
					var a:=TAU*float(i)/6.0-0.4
					draw_line(c+Vector2(-2,1)+Vector2(cos(a),sin(a))*5.5,c+Vector2(-2,1)+Vector2(cos(a),sin(a))*9.0,ink,w,true)
			"growl":
				for row in 2:
					var pts:=PackedVector2Array()
					for i in 9:pts.append(c+Vector2(-8.0+i*2.0,-3.0+row*6.0+(1.6 if i%2==0 else -1.6)))
					draw_polyline(pts,ink,w,true)
			"creak":
				draw_polyline(PackedVector2Array([c+Vector2(-8,2),c+Vector2(-4,-4),c+Vector2(0,3),c+Vector2(4,-4),c+Vector2(8,2)]),ink,w,true)
			"gulp":
				draw_circle(c+Vector2(0,3),4.5,ink)
				draw_colored_polygon(PackedVector2Array([c+Vector2(-3.8,1.5),c+Vector2(3.8,1.5),c+Vector2(0,-8)]),ink)
			"snort":
				draw_line(c+Vector2(-7,-2),c+Vector2(-2,-2),ink,w+0.4,true)
				draw_line(c+Vector2(2,-2),c+Vector2(7,-2),ink,w+0.4,true)
				draw_arc(c+Vector2(0,3),5.0,0.2,PI-0.2,10,ink,w,true)
			"clatter":
				for i in 3:draw_line(c+Vector2(-6+i*6,-8),c+Vector2(-4+i*6,-3),ink,w,true)
				draw_arc(c+Vector2(0,4),6.0,0.0,PI,12,ink,w,true)
			"thump":
				for i in 8:
					var a:=TAU*float(i)/8.0
					draw_line(c+Vector2(cos(a),sin(a))*3.0,c+Vector2(cos(a),sin(a))*(9.0 if i%2==0 else 6.0),ink,w,true)
			"clap":
				draw_arc(c+Vector2(-3,0),6.0,-1.2,1.2,10,ink,w,true)
				draw_arc(c+Vector2(3,0),6.0,PI-1.2,PI+1.2,10,ink,w,true)
			"yawn":
				var pts:=PackedVector2Array()
				for i in 17:
					var a:=TAU*float(i)/16.0
					pts.append(c+Vector2(cos(a)*4.5,sin(a)*7.5))
				draw_polyline(pts,ink,w,true)
			"gasp":
				draw_arc(c+Vector2(-1,1),5.5,0.0,TAU,18,ink,w+0.4,true)
				draw_arc(c+Vector2(7,-6),1.8,0.0,TAU,8,ink,w,true)
			"bleat":
				var pts:=PackedVector2Array()
				for i in 9:pts.append(c+Vector2(-8.0+i*2.0,sin(float(i)*1.4)*3.0))
				draw_polyline(pts,ink,w,true)
				draw_circle(c+Vector2(8,-5),1.8,ink)
			"whimper":
				draw_arc(c+Vector2(0,-2),7.0,0.3,PI-0.3,12,ink,w,true)
				draw_line(c+Vector2(-5,4),c+Vector2(-3,8),ink,w,true)
			"slap":
				for i in 5:
					var a:=TAU*float(i)/5.0-PI*0.5
					draw_line(c,c+Vector2(cos(a),sin(a))*8.5,ink,w,true)
			_:
				for i in 3:draw_circle(c+Vector2(-6.0+i*6.0,1.0),1.9,ink)
