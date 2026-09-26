extends Control
## The court's setting, drawn in the game's paper-and-gouache manner. It follows
## the form of court the people's discoveries support (scripts/civic_stages.gd,
## data/civic/civic_stages.json): the fire circle under the sky, the elders'
## ring of standing stones, the chief's timber hall, the house of the god with
## its scribes, the palace hall, the open-air assembly place, the imperial
## throne hall, the council house, the great hall, the chamber of the seal and
## the hall of the estates. Each is lit, built and peopled differently: its
## attendants (heralds, scribes, priests, ministers, guards, petitioners, the
## citizens on the tiers) stand in the scene.
## Presentation only. A painted plate at assets/ui/court/<stage_id>.png, when
## present, replaces the drawing for that stage (docs/art/COURT_STAGE_ART_BRIEF.md);
## an older assets/ui/court/court-tier-N.png still covers its era tier.

const Voice:=preload("res://scripts/character_voice.gd")
const Stages:=preload("res://scripts/civic_stages.gd")
const OVERRIDE_PATH:="res://assets/ui/court/court-tier-%d.png"
## Captures that pin an era tier see the stage that tier used to draw.
const TIER_STAGES:=["hearth_council","chiefs_hall","temple_palace","palace_bureaucracy","imperial_court"]
const MAX_TIER:=4
const PLACE_NAMES:=["The fire circle","The longhouse","The great hall","The stone hall","The high palace"]
const PLACE_LINES:=[
	"logs and hides about the fire, under the open sky",
	"a thatched longhouse, posts and a long hearth",
	"timber and mudbrick, woven hangings and the first bright metal",
	"a hall of stone, columns and banners",
	"a high palace of arches, light and long carpets",
]

## Tests and captures may pin the tier; -1 follows the people's knowledge.
static var tier_override:=-1

var tier:=0
var stage_id:="hearth_council"
var scene:="fire_circle"
var attendants:Array=[]
var dark:=false
var banner:=Color("8e3b2e")
var _texture:Texture2D
var _clock:=0.0
var animate:=true
## Pixels at the top covered by a header; the scene is composed below it.
var content_top:=0.0

static func current_tier()->int:
	if tier_override>=0: return clampi(tier_override,0,MAX_TIER)
	var tags:=Voice.era_tags("player")
	var base:=Voice.era_tier(tags)
	if base>=3 and (tags.has("gunpowder") or (tags.has("glass") and tags.has("institutions"))): return 4
	return base

static func current_stage()->String:
	## The form of court now: pinned by a capture's tier, else from discoveries.
	if tier_override>=0 and Stages.stage_override=="":
		return String(TIER_STAGES[clampi(tier_override,0,MAX_TIER)])
	return Stages.current_id()

static func place_name(t:int)->String:
	return String(PLACE_NAMES[clampi(t,0,MAX_TIER)])

static func place_line(t:int)->String:
	return String(PLACE_LINES[clampi(t,0,MAX_TIER)])

static func stage_place_name(id:String="")->String:
	return String(Stages.stage(id if id!="" else current_stage()).get("place_name",PLACE_NAMES[0]))

static func stage_place_line(id:String="")->String:
	return String(Stages.stage(id if id!="" else current_stage()).get("place_line",PLACE_LINES[0]))

static func stage_texture(id:String)->Texture2D:
	## A painted plate for this stage, dropped in at assets/ui/court/<id>.png.
	return _texture_at(Stages.art_path(id))

static func override_texture(t:int)->Texture2D:
	## A painted plate for this tier, if one has been added to the project.
	return _texture_at(OVERRIDE_PATH % clampi(t,0,MAX_TIER))

static func _texture_at(path:String)->Texture2D:
	if ResourceLoader.exists(path):
		var loaded:Resource=load(path)
		if loaded is Texture2D: return loaded as Texture2D
	if FileAccess.file_exists(path):
		var image:=Image.load_from_file(ProjectSettings.globalize_path(path))
		if image!=null and not image.is_empty(): return ImageTexture.create_from_image(image)
	return null

func configure(t:int,dark_mode:bool,stage:String="")->void:
	tier=clampi(t,0,MAX_TIER)
	dark=dark_mode
	stage_id=stage if stage!="" else current_stage()
	var record:=Stages.stage(stage_id)
	stage_id=String(record.get("id","hearth_council"))
	scene=String(record.get("scene","fire_circle"))
	attendants=record.get("attendants",[])
	banner=Color(String(record.get("banner","8e3b2e")))
	_texture=stage_texture(stage_id)
	# An era plate painted for the old tiers still dresses the matching stage.
	if _texture==null and TIER_STAGES.find(stage_id)==tier: _texture=override_texture(tier)
	queue_redraw()

## The court stage last shown in the Court, so a stage change can dissolve.
static var _last_court_stage:=""
static var _last_court_tier:=0
const STAGE_DISSOLVE:=1.5

## Called by the Court after configure(): if the stage differs from the one
## last shown there, lay the old stage over this one and dissolve it (one tween).
func cross_fade_from_last()->void:
	var old:=_last_court_stage;var old_tier:=_last_court_tier
	_last_court_stage=stage_id;_last_court_tier=tier
	if old=="" or old==stage_id or not is_inside_tree():return
	var ghost:Control=(get_script() as GDScript).new()
	ghost.name="StageBefore";ghost.animate=false
	add_child(ghost);ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost.configure(old_tier,dark,old)
	var tween:=ghost.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost,"modulate:a",0.0,preload("res://scripts/hud/motion.gd").duration(STAGE_DISSOLVE))
	tween.tween_callback(ghost.queue_free)

func has_painting()->bool:
	return _texture!=null

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	resized.connect(queue_redraw)

func _process(delta:float)->void:
	if not animate or not is_visible_in_tree(): return
	var before:=int(_clock*6.0)
	_clock+=delta
	# A slow flicker for the fire; redrawn a few times a second only.
	if int(_clock*6.0)!=before: queue_redraw()

## Where seated people are placed in the scene: an arc before the hearth or
## dais, back row first. Returned as the foot point of each seat in local
## pixels, ordered centre-out so the first seats sit nearest the fire.
func seat_points(count:int,center_frac:float=.5)->Array[Vector2]:
	var result:Array[Vector2]=[]
	if count<=0: return result
	var eff:=size.y-content_top
	var center:=Vector2(size.x*center_frac,content_top+eff*.86)
	var radii:=Vector2(size.x*clampf(.30+.015*float(count),.32,.40),eff*.20)
	# A few people sit close about the fire; a full court fills the ring.
	var span:=PI*clampf(.13*float(count)+.12,.34,.80)
	var slots:Array[float]=[]
	for i in count:
		var t:=0.5 if count==1 else float(i)/float(count-1)
		slots.append(PI*1.5-span*.5+span*t)
	for angle in slots:
		result.append(center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
	result.sort_custom(func(a:Vector2,b:Vector2)->bool:return absf(a.x-center.x)<absf(b.x-center.x))
	return result

func hearth_point()->Vector2:
	## In drawing space (below content_top).
	return Vector2(size.x*.5,(size.y-content_top)*.80)

# ---------------------------------------------------------------- palette

func _c(light_hex:String,dark_hex:String)->Color:
	return Color(dark_hex) if dark else Color(light_hex)

# ---------------------------------------------------------------- drawing

func _draw()->void:
	var w:=size.x;var h:=size.y
	if w<8 or h<8: return
	if _texture!=null:
		_draw_cover(_texture)
		_vignette(w,h)
		return
	# Above the composed scene: the sky or the roof, in its top colour.
	draw_rect(Rect2(0,0,w,content_top+2),_top_colour())
	draw_set_transform(Vector2(0,content_top))
	var eh:=h-content_top
	match scene:
		"fire_circle","elders_ring": _draw_fire_circle(w,eh)
		"chiefs_hall": _draw_longhouse(w,eh)
		"temple_palace": _draw_timber_hall(w,eh)
		"palace_hall": _draw_stone_hall(w,eh,false)
		"assembly_tiers": _draw_assembly(w,eh)
		"council_house": _draw_council_house(w,eh)
		"great_hall","estates_hall","commune_hall": _draw_great_hall(w,eh)
		_: _draw_stone_hall(w,eh,true)
	if dark: _firelight(w,eh)
	draw_set_transform(Vector2.ZERO)
	_grain(w,h)
	_vignette(w,h)

func _top_colour()->Color:
	match scene:
		"fire_circle": return _c("d8c6a2","151b28")
		"elders_ring": return _c("e0b98a","1d1a2a")
		"chiefs_hall": return _c("8c7152","1b1511")
		"temple_palace": return _c("4f3620","140e09")
		"assembly_tiers": return _c("bcd0d8","18223a")
		"council_house": return _c("e4dccb","2a2622")
		"great_hall": return _c("5a4a38","141110")
		"estates_hall": return _c("6a5a48","17140f")
		"imperial_hall": return _c("b9a27a","1c1714")
		"basilica": return _c("6a6458","101014")
		"commune_hall": return _c("6a4e34","17110c")
		_: return _c("c9c0ae","1d1f22")

func _radial(center:Vector2,radius:Vector2,inner:Color,outer:Color,segments:int=40)->void:
	## A soft radial wash: a fan from a centre colour to a clear rim.
	var points:=PackedVector2Array([center]);var colours:=PackedColorArray([inner])
	for i in segments+1:
		var a:=TAU*float(i)/float(segments)
		points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y));colours.append(outer)
	for i in segments:
		draw_polygon(PackedVector2Array([points[0],points[i+1],points[i+2]]),PackedColorArray([colours[0],colours[i+1],colours[i+2]]))

func _firelight(w:float,h:float)->void:
	## At night the fire lights the faces and the near ground.
	var flicker:=.5+.5*sin(_clock*5.1)
	_radial(hearth_point()+Vector2(0,-h*.12),Vector2(w*.42,h*.62),Color(1,.58,.22,.20+.03*flicker),Color(1,.58,.22,0))

func _draw_cover(texture:Texture2D)->void:
	var tex_size:=texture.get_size()
	if tex_size.x<=0 or tex_size.y<=0: return
	var scale_factor:=maxf(size.x/tex_size.x,size.y/tex_size.y)
	var shown:=size/scale_factor
	var source:=Rect2((tex_size-shown)*.5,shown)
	draw_texture_rect_region(texture,Rect2(Vector2.ZERO,size),source)

# --- Tier 0: the fire circle under the sky ---------------------------------

func _draw_fire_circle(w:float,h:float)->void:
	var horizon:=h*.50
	_gradient(Rect2(0,0,w,horizon+2),_c("d8c6a2","151b28"),_c("f2e4c4","4a3a33"))
	if dark:
		var rng:=_rng(11)
		for i in 70:
			var p:=Vector2(rng.randf()*w,rng.randf()*horizon*.8)
			draw_circle(p,rng.randf_range(.6,1.5),Color(1,.96,.86,rng.randf_range(.25,.7)))
		_radial(Vector2(w*.78,h*.18),Vector2(h*.16,h*.16),Color(.95,.9,.75,.18),Color(.95,.9,.75,0))
		draw_circle(Vector2(w*.78,h*.18),h*.055,Color("e9dfc4"))
		draw_circle(Vector2(w*.78+h*.022,h*.165),h*.05,Color("1d2230"))
	else:
		for i in 4:draw_circle(Vector2(w*.22,horizon*.66),h*(.16-.03*i),Color(1,.95,.8,.10))
		# Brushed cloud washes.
		var rng2:=_rng(12)
		for i in 6:
			var y:=rng2.randf_range(.10,.34)*h
			var x:=rng2.randf_range(-.1,.9)*w
			_band(Vector2(x,y),w*rng2.randf_range(.18,.34),h*.022,Color(1,.98,.92,.35))
	# Far hills and a line of trees.
	_hills(w,horizon,h*.10,_c("bba98a","2c2f38"),3.1)
	_hills(w,horizon+h*.02,h*.06,_c("a6946f","252629"),1.7)
	var trees:=_rng(13)
	for i in 26:
		var x:=trees.randf()*w
		if absf(x-w*.5)<w*.12: continue
		var th:=h*trees.randf_range(.05,.11)
		var base_y:=horizon+h*.03
		draw_colored_polygon(PackedVector2Array([Vector2(x-th*.28,base_y),Vector2(x,base_y-th),Vector2(x+th*.28,base_y)]),_c("7f7a5a","1d2221").lerp(_c("a6946f","252629"),trees.randf()*.4))
	# Ground: trodden earth, darker toward us.
	_gradient(Rect2(0,horizon+h*.03,w,h-horizon),_c("bca47c","2d2521"),_c("9d8460","1c1714"))
	var tufts:=_rng(14)
	for i in 60:
		var p:=Vector2(tufts.randf()*w,horizon+h*.05+tufts.randf()*(h*.45))
		draw_line(p,p+Vector2(tufts.randf_range(-3,3),-tufts.randf_range(3,8)),_c("8c7a52","3a3326"),1.2,true)
	# The windbreak: stakes and stitched hides curving behind the circle.
	_windbreak(Vector2(w*.05,horizon+h*.12),Vector2(w*.40,horizon+h*.06),h*.17,0)
	_windbreak(Vector2(w*.60,horizon+h*.06),Vector2(w*.95,horizon+h*.13),h*.15,1)
	# A drying rack with a stretched hide, spears leaning at the left.
	_rack(Vector2(w*.86,horizon+h*.20),h*.20)
	for i in 3:
		var foot:=Vector2(w*(.10+.018*i),horizon+h*.30)
		draw_line(foot,foot+Vector2(h*.10+i*3,-h*.30),_c("5a4630","b09a78"),2.0,true)
		draw_colored_polygon(PackedVector2Array([foot+Vector2(h*.10+i*3,-h*.30),foot+Vector2(h*.10+i*3-3,-h*.30+9),foot+Vector2(h*.10+i*3+4,-h*.30+7)]),_c("6d6a64","c9c2b4"))
	# The trodden floor of the circle, darker where feet have worn it.
	var center:=Vector2(w*.5,h*.86)
	var radii:=Vector2(w*.40,h*.20)
	_radial(center+Vector2(0,-h*.02),radii*1.22,Color(_c("8a6f4c","1a1410"),.55),Color(_c("8a6f4c","1a1410"),0))
	# Bundles of hides and a heap of knapped stone by the seats.
	_bundle(Vector2(w*.24,h*.80),h*.07,0);_bundle(Vector2(w*.73,h*.82),h*.06,1)
	for i in 5:draw_circle(Vector2(w*.62+i*h*.018,h*.93-(i%2)*h*.01),h*.012,_c("7e776a","4a4640"))
	# The ring of logs and hides round the fire.
	for i in 11:
		var a:=PI*1.5-PI*.9+PI*1.8*float(i)/10.0
		if i==5: continue
		var p:=center+Vector2(cos(a)*radii.x,sin(a)*radii.y)
		var along:=Vector2(-sin(a)*radii.x,cos(a)*radii.y).normalized()
		_log(p,along,w*.075,h*.07,i)
	_before_fire(w,h)
	_fire(hearth_point(),h*.20)

func _bundle(at:Vector2,size_px:float,variant:int)->void:
	## A rolled hide tied with cord.
	var hide:=_c("b58e60","5a4430") if variant==0 else _c("a07a52","4e3a28")
	draw_colored_polygon(_ellipse(at,Vector2(size_px*1.4,size_px*.55),18),hide)
	draw_colored_polygon(_ellipse(at+Vector2(size_px*1.2,0),Vector2(size_px*.25,size_px*.5),12),hide.lightened(.15))
	draw_arc(at+Vector2(size_px*1.2,0),size_px*.14,0,TAU,12,hide.darkened(.3),1.2,true)
	for x:float in [-.5,.4]:draw_line(at+Vector2(size_px*x,-size_px*.55),at+Vector2(size_px*x,size_px*.55),_c("5d452d","2c2118"),1.5,true)

func _windbreak(from:Vector2,to:Vector2,height:float,variant:int)->void:
	var stakes:=7
	var hides:=[_c("b08556","5d4430"),_c("9c7248","4f3a2a"),_c("c09a68","66503a")]
	var rng:=_rng(20+variant)
	for i in stakes-1:
		var t0:=float(i)/float(stakes-1);var t1:=float(i+1)/float(stakes-1)
		var a:=from.lerp(to,t0)+Vector2(0,sin(t0*PI)*-height*.08)
		var b:=from.lerp(to,t1)+Vector2(0,sin(t1*PI)*-height*.08)
		var top_a:=a-Vector2(0,height*rng.randf_range(.82,.95))
		var top_b:=b-Vector2(0,height*rng.randf_range(.80,.95))
		var hide:Color=hides[(i+variant)%hides.size()]
		var poly:=PackedVector2Array([a+Vector2(0,-height*.06),top_a+Vector2(2,height*.06),top_a.lerp(top_b,.5)+Vector2(0,height*.10),top_b+Vector2(-2,height*.07),b+Vector2(0,-height*.05)])
		draw_colored_polygon(poly,hide)
		# Stitching and a lighter belly on each hide.
		draw_colored_polygon(PackedVector2Array([a.lerp(top_a,.3)+Vector2(6,0),top_a.lerp(top_b,.5)+Vector2(0,height*.22),b.lerp(top_b,.3)+Vector2(-6,0),a.lerp(b,.5)+Vector2(0,-height*.16)]),Color(hide.lightened(.12),.55))
		for s in 5:
			var p:=top_a.lerp(a,.18+.16*s)+Vector2(3,0)
			draw_line(p,p+Vector2(4,1),_c("5d452d","2c2118"),1.0,true)
	for i in stakes:
		var t:=float(i)/float(stakes-1)
		var p:=from.lerp(to,t)+Vector2(0,sin(t*PI)*-height*.08)
		draw_line(p,p-Vector2(rng.randf_range(-2,2),height*1.05),_c("4f3b27","cdb68c"),3.0,true)

func _rack(foot:Vector2,height:float)->void:
	var ink:=_c("54402a","b8a07a")
	draw_line(foot+Vector2(-height*.36,0),foot+Vector2(-height*.30,-height),ink,3.0,true)
	draw_line(foot+Vector2(height*.36,0),foot+Vector2(height*.30,-height),ink,3.0,true)
	draw_line(foot+Vector2(-height*.40,-height*.94),foot+Vector2(height*.40,-height*.94),ink,3.0,true)
	var hide:=PackedVector2Array([foot+Vector2(-height*.26,-height*.92),foot+Vector2(height*.26,-height*.92),foot+Vector2(height*.22,-height*.34),foot+Vector2(height*.06,-height*.24),foot+Vector2(-height*.10,-height*.30),foot+Vector2(-height*.24,-height*.40)])
	draw_colored_polygon(hide,_c("c9a878","6d5237"))
	for i in 5:
		var p:=foot+Vector2(-height*.22+height*.11*i,-height*.92)
		draw_line(p,p+Vector2(0,height*.05),ink,1.2,true)

func _log(center:Vector2,along:Vector2,length:float,thick:float,index:int)->void:
	var across:=Vector2(-along.y,along.x)
	var a:=center-along*length*.5;var b:=center+along*length*.5
	draw_colored_polygon(_ellipse(center+Vector2(0,thick*.45),Vector2(length*.55,thick*.35),16),Color(0,0,0,.14 if not dark else .3))
	var bark:=_c("6e4f33","3f2e20").lerp(_c("866246","4c3827"),float(index%3)/3.0)
	draw_colored_polygon(PackedVector2Array([a+across*thick*.5,b+across*thick*.5,b-across*thick*.5,a-across*thick*.5]),bark)
	draw_line(a-across*thick*.2,b-across*thick*.2,Color(bark.lightened(.18),.8),1.4,true)
	draw_circle(b,thick*.5,_c("c9a878","7c6448"))
	draw_arc(b,thick*.3,0,TAU,14,_c("9c7a52","54412c"),1.0,true)
	if index%2==0:
		# A fur thrown over the log.
		var fur:=PackedVector2Array([center-along*length*.28+across*thick*.62,center+along*length*.22+across*thick*.66,center+along*length*.26-across*thick*.8,center-along*length*.04-across*thick*1.05,center-along*length*.30-across*thick*.7])
		draw_colored_polygon(fur,_c("d8c09a","8a7050") if index%4==0 else _c("a78a66","5f4a35"))

func _fire(base:Vector2,height:float)->void:
	var flicker:=.5+.5*sin(_clock*7.3)*sin(_clock*3.1+1.0)
	_radial(base+Vector2(0,-height*.25),Vector2(height*1.4,height*1.1)*(1.0+.03*flicker),Color(1,.62,.25,.30 if not dark else .45),Color(1,.62,.25,0))
	# Stones and embers.
	for i in 9:
		var a:=TAU*float(i)/9.0
		var p:=base+Vector2(cos(a)*height*.42,sin(a)*height*.14)
		draw_circle(p,height*.07,_c("8a8272","4a4640"))
		draw_circle(p+Vector2(-1,-1),height*.045,_c("a39a8a","5f5a52"))
	draw_colored_polygon(_ellipse(base,Vector2(height*.34,height*.10),16),_c("3b2a1d","1a120c"))
	for i in 3:
		var a:=base+Vector2(-height*.28+height*.28*i,0)
		draw_line(a+Vector2(-height*.12,height*.02),a+Vector2(height*.14,-height*.04),_c("4a3322","24180f"),4.0,true)
	var tongues:=[[0.0,1.0,Color("d8642c")],[-.16,.72,Color("e98a36")],[.15,.78,Color("e98a36")],[0.0,.62,Color("f3b34c")],[.02,.36,Color("f8dc86")]]
	for tongue:Array in tongues:
		var off:=float(tongue[0])*height;var tall:=float(tongue[1])*height*(1.0+.06*sin(_clock*9.0+off))
		var col:Color=tongue[2]
		var tip:=base+Vector2(off+sin(_clock*5.0+off)*height*.03,-tall)
		draw_colored_polygon(PackedVector2Array([base+Vector2(off-height*.16,0),base+Vector2(off-height*.10,-tall*.45),tip,base+Vector2(off+height*.10,-tall*.45),base+Vector2(off+height*.16,0)]),col)
	for i in 4:
		var p:=base+Vector2(sin(float(i)*1.7)*height*.2,-height*(1.2+.35*i))
		draw_circle(p,height*(.12+.05*i),Color(_c("8d8478","9b9488"),.10-.02*i))

# --- Tier 1: the longhouse -------------------------------------------------

func _draw_longhouse(w:float,h:float)->void:
	var back:=Rect2(w*.40,h*.30,w*.20,h*.34)
	_gradient(Rect2(0,0,w,h),_c("8c7152","1b1511"),_c("b89c74","2a211a"))
	# Side walls of wattle and hide.
	_quad(Vector2(0,h*.18),back.position,Vector2(back.position.x,back.end.y),Vector2(0,h),_c("9d8360","2c231b"))
	_quad(Vector2(w,h*.18),Vector2(back.end.x,back.position.y),back.end,Vector2(w,h),_c("97805e","29211a"))
	var wattle:=_rng(31)
	for i in 36:
		var t:=wattle.randf()
		var side:=-1.0 if i%2==0 else 1.0
		var x0:=0.0 if side<0 else w
		var xb:=back.position.x if side<0 else back.end.x
		var x:=lerpf(x0,xb,t)
		var y0:=lerpf(h*.30,back.position.y+h*.02,t);var y1:=lerpf(h*.95,back.end.y,t)
		draw_line(Vector2(x,y0),Vector2(x,y1),Color(_c("7d6446","3a2e22"),.35),1.0,true)
	# Back wall with a bright doorway.
	draw_rect(back,_c("a88d68","30261d"))
	var door:=Rect2(back.position.x+back.size.x*.40,back.position.y+back.size.y*.36,back.size.x*.20,back.size.y*.64)
	draw_rect(door,_c("e9d6ae","6e5234"))
	draw_colored_polygon(_ellipse(Vector2(door.get_center().x,door.position.y),Vector2(door.size.x*.5,door.size.x*.35),16),_c("e9d6ae","6e5234"))
	_radial(door.get_center(),door.size*1.2,Color(1,.92,.75,.25 if not dark else .12),Color(1,.92,.75,0))
	# Thatched roof: the inside of a long gable, rafters to the ridge.
	var ridge:=Vector2(w*.5,h*.08)
	_tri(Vector2(0,0),Vector2(w,0),ridge,_c("6f5638","140f0b"))
	_quad(Vector2(0,0),ridge,back.position,Vector2(0,h*.20),_c("7d6242","1c1510"))
	_quad(Vector2(w,0),ridge,Vector2(back.end.x,back.position.y),Vector2(w,h*.20),_c("785f40","1a140f"))
	var straw:=_rng(32)
	for i in 180:
		var t:=straw.randf();var s:=straw.randf()
		var left:=i%2==0
		var p:=Vector2(0,0).lerp(Vector2(0,h*.2),s).lerp(back.position.lerp(ridge,s),t) if left else Vector2(w,0).lerp(Vector2(w,h*.2),s).lerp(Vector2(back.end.x,back.position.y).lerp(ridge,s),t)
		draw_line(p,p+Vector2(6 if left else -6,4),Color(_c("c9a86a","6e5634"),.45),1.2,true)
	for i in 6:
		var t:=float(i+1)/7.0
		draw_line(Vector2(0,h*.20).lerp(Vector2(0,0),t*.2).lerp(ridge,t*.0),back.position.lerp(ridge,t),_c("4f3b26","0e0b08"),2.0,true)
		draw_line(Vector2(w,h*.20).lerp(Vector2(w,0),t*.2),Vector2(back.end.x,back.position.y).lerp(ridge,t),_c("4f3b26","0e0b08"),2.0,true)
	# Two rows of posts receding to the back wall.
	for k in 4:
		var d:=pow(float(k)/4.0,1.3)
		var lx:=lerpf(w*.10,back.position.x+back.size.x*.08,d);var rx:=lerpf(w*.90,back.end.x-back.size.x*.08,d)
		var bottom:=lerpf(h*1.02,back.end.y,d);var top:=lerpf(h*.02,back.position.y,d)
		var thick:=lerpf(w*.026,w*.008,d)
		for x:float in [lx,rx]:
			draw_rect(Rect2(x-thick*.5,top,thick,bottom-top),_c("5c4430","22190f"))
			draw_rect(Rect2(x-thick*.5,top,thick*.35,bottom-top),_c("735840","2e2216"))
		# Hides hung between the posts.
		if k<3:
			var nd:=pow(float(k+1)/4.0,1.3)
			var nlx:=lerpf(w*.10,back.position.x+back.size.x*.08,nd)
			var ntop:=lerpf(h*.02,back.position.y,nd);var nbottom:=lerpf(h*1.02,back.end.y,nd)
			var y0:=lerpf(top,bottom,.30);var y1:=lerpf(ntop,nbottom,.30)
			_quad(Vector2(lx+thick,y0),Vector2(nlx,y1),Vector2(nlx,y1+(nbottom-ntop)*.24),Vector2(lx+thick,y0+(bottom-top)*.24),_c("b89066","4d3a28"))
	# Floor, rush mats and the long hearth.
	_quad(Vector2(0,h),Vector2(back.position.x,back.end.y),back.end,Vector2(w,h),_c("a58c66","2b221a"))
	for i in 3:
		var c:=Vector2(w*(.28+.22*i),h*(.92-.02*(i%2)))
		var mat:=_ellipse(c,Vector2(w*.09,h*.05),18)
		draw_colored_polygon(mat,_c("c8b07c","4f4230"))
		for s in 6:draw_line(c+Vector2(-w*.07,-h*.03+h*.012*s),c+Vector2(w*.07,-h*.03+h*.012*s),Color(_c("9b8558","3b3224"),.6),1.0,true)
	draw_colored_polygon(_ellipse(Vector2(w*.5,h*.80),Vector2(w*.16,h*.045),20),_c("4a3727","17100b"))
	_light_shaft(Vector2(w*.47,h*.10),Vector2(w*.53,h*.10),Vector2(w*.58,h*.78),Vector2(w*.42,h*.78))
	_before_fire(w,h)
	_fire(hearth_point(),h*.15)

# --- Tier 2: the timber and mudbrick hall ------------------------------------

func _draw_timber_hall(w:float,h:float)->void:
	var back:=Rect2(w*.26,h*.14,w*.48,h*.52)
	_gradient(Rect2(0,0,w,h),_c("b79a70","241c16"),_c("cfb68c","30261d"))
	# Mudbrick side walls.
	_quad(Vector2(0,0),back.position,Vector2(back.position.x,back.end.y),Vector2(0,h),_c("c19c6a","3a2c20"))
	_quad(Vector2(w,0),Vector2(back.end.x,back.position.y),back.end,Vector2(w,h),_c("b99464","35281d"))
	draw_rect(back,_c("c9a674","3f3023"))
	_bricks(back,_c("a9855a","2e2218"),9,12)
	# Timber frame: lintel, posts, crossbeams.
	var timber:=_c("5e4127","1f160e")
	draw_rect(Rect2(back.position.x-4,back.position.y,back.size.x+8,h*.035),timber)
	for i in 5:
		var x:=back.position.x+back.size.x*float(i)/4.0
		draw_rect(Rect2(x-4,back.position.y,8,back.size.y),timber)
	draw_rect(Rect2(0,0,w,h*.06),_c("4f3620","140e09"))
	for i in 7:
		var x:=w*float(i)/6.0
		draw_line(Vector2(x,h*.06),Vector2(lerpf(x,w*.5,.5),back.position.y),Color(timber,.9),5.0,true)
	# Woven hangings with zigzag and lozenge bands.
	var weaves:=[_c("a4604a","6a3024"),_c("62707e","2f3a48"),_c("c3a064","80662e")]
	for i in 3:
		var r:=Rect2(back.position.x+back.size.x*(.06+.33*i),back.position.y+back.size.y*.10,back.size.x*.22,back.size.y*.56)
		if i==1: r=Rect2(back.position.x+back.size.x*.36,back.position.y+back.size.y*.08,back.size.x*.28,back.size.y*.62)
		_hanging(r,weaves[i%3],weaves[(i+1)%3],i)
	# Side-wall hangings in perspective.
	_quad(Vector2(w*.05,h*.16),Vector2(w*.18,h*.20),Vector2(w*.18,h*.56),Vector2(w*.05,h*.64),Color(weaves[0],.9))
	_quad(Vector2(w*.95,h*.16),Vector2(w*.82,h*.20),Vector2(w*.82,h*.56),Vector2(w*.95,h*.64),Color(weaves[1],.9))
	for i in 5:
		var y:=lerpf(h*.22,h*.56,float(i)/4.0)
		_zigzag(Vector2(w*.06,y),Vector2(w*.17,y+h*.02),_c("eadcc0","a8936c"),6)
		_zigzag(Vector2(w*.83,y+h*.02),Vector2(w*.94,y),_c("eadcc0","a8936c"),6)
	# A raised dais with a carved seat, and bronze vessels catching the light.
	var dais:=Rect2(w*.40,back.end.y-h*.06,w*.20,h*.06)
	draw_rect(dais,_c("8a6a44","2d2117"))
	draw_rect(Rect2(dais.position.x,dais.position.y,dais.size.x,4),_c("a8845a","3c2c1e"))
	var seat:=Rect2(w*.47,dais.position.y-h*.14,w*.06,h*.14)
	draw_rect(seat,_c("5a3e25","1e150d"))
	draw_rect(Rect2(seat.position.x-6,seat.position.y+seat.size.y*.55,seat.size.x+12,seat.size.y*.14),_c("6c4c2e","281c12"))
	for i in 4:
		var p:=Vector2(back.position.x+back.size.x*(.10+.26*i),back.end.y-h*.02)
		if absf(p.x-w*.5)<w*.08: continue
		draw_colored_polygon(_ellipse(p+Vector2(0,-h*.035),Vector2(h*.03,h*.04),14),_c("a0683a","8a5a30"))
		draw_rect(Rect2(p.x-h*.018,p.y-h*.08,h*.036,h*.012),_c("b77a44","9a6634"))
		draw_circle(p+Vector2(-h*.012,-h*.045),h*.008,Color(1,.9,.6,.8))
	# Packed floor, reed mats, hearth.
	_quad(Vector2(0,h),Vector2(back.position.x,back.end.y),back.end,Vector2(w,h),_c("b39a72","2a2119"))
	for i in 8:
		var y:=lerpf(back.end.y,h,float(i)/7.0)
		draw_line(Vector2(lerpf(back.position.x,0,float(i)/7.0),y),Vector2(lerpf(back.end.x,w,float(i)/7.0),y),Color(_c("9b8460","3a2e22"),.35),1.0,true)
	_before_fire(w,h)
	_fire(hearth_point(),h*.15)

# --- Tiers 3 and 4: stone hall and high palace --------------------------------

func _draw_stone_hall(w:float,h:float,palace:bool)->void:
	var back:=Rect2(w*.30,h*.10,w*.40,h*.56)
	_gradient(Rect2(0,0,w,h),_c("c9c0ae","1d1f22"),_c("ddd4c2","2a2a2b"))
	var stone_side:=_c("b8ae9a","2c2c2d");var stone_back:=_c("c7bda9","333234");var mortar:=_c("a2977f","232324")
	_quad(Vector2(0,0),back.position,Vector2(back.position.x,back.end.y),Vector2(0,h),stone_side)
	_quad(Vector2(w,0),Vector2(back.end.x,back.position.y),back.end,Vector2(w,h),stone_side.darkened(.04))
	draw_rect(back,stone_back)
	_bricks(back,mortar,8,6)
	if palace:
		# Vaults overhead.
		for i in 5:
			var t:=float(i)/4.0
			var cx:=w*.5;var rx:=lerpf(w*.50,back.size.x*.5,t);var cy:=lerpf(h*.30,back.position.y+back.size.y*.18,t)
			draw_arc(Vector2(cx,cy),rx,PI,TAU,40,Color(_c("9d9380","141415"),.9),lerpf(6,2,t),true)
		# Tall windows with light falling across the hall.
		for i in 2:
			var r:=Rect2(back.position.x+back.size.x*(.14+.56*i),back.position.y+back.size.y*.10,back.size.x*.16,back.size.y*.46)
			draw_rect(r,_c("f6efd9","cdb27a"))
			draw_circle(Vector2(r.get_center().x,r.position.y),r.size.x*.5,_c("f6efd9","cdb27a"))
			draw_line(Vector2(r.get_center().x,r.position.y-r.size.x*.5),Vector2(r.get_center().x,r.end.y),_c("8d8474","3a3530"),2.0)
			_light_shaft(Vector2(r.position.x,r.position.y),Vector2(r.end.x,r.position.y),Vector2(r.end.x+w*.10,h*.96),Vector2(r.position.x+w*.02,h*.96))
	else:
		# A great arch at the back.
		var arch:=Rect2(back.position.x+back.size.x*.34,back.position.y+back.size.y*.30,back.size.x*.32,back.size.y*.70)
		draw_rect(arch,_c("8e8472","141416"))
		draw_circle(Vector2(arch.get_center().x,arch.position.y),arch.size.x*.5,_c("8e8472","141416"))
	# Floor slabs in perspective.
	_quad(Vector2(0,h),Vector2(back.position.x,back.end.y),back.end,Vector2(w,h),_c("bdb3a0","262627"))
	for i in 9:
		var t:=float(i)/8.0
		draw_line(Vector2(lerpf(back.position.x,back.end.x,t),back.end.y),Vector2(lerpf(-w*.2,w*1.2,t),h),Color(mortar,.7),1.0,true)
	for i in 7:
		var t:=pow(float(i)/6.0,1.6)
		var y:=lerpf(back.end.y,h,t)
		draw_line(Vector2(lerpf(back.position.x,0,t),y),Vector2(lerpf(back.end.x,w,t),y),Color(mortar,.7),1.0,true)
	if palace:
		# A long carpet to the throne.
		_quad(Vector2(w*.47,back.end.y),Vector2(w*.53,back.end.y),Vector2(w*.62,h),Vector2(w*.38,h),Color(banner.darkened(.1),.85))
		_quad(Vector2(w*.475,back.end.y),Vector2(w*.525,back.end.y),Vector2(w*.60,h),Vector2(w*.40,h),Color(banner,.0))
		for i in 2:
			var x0:=w*(.475+.05*i);var x1:=w*(.395+.21*i)
			draw_line(Vector2(x0,back.end.y),Vector2(x1,h),_c("c9a24a","a88a3c"),2.0,true)
	# Throne dais with steps.
	for i in 3:
		var r:=Rect2(w*(.40-.02*i),back.end.y-h*.02+h*.018*i,w*(.20+.04*i),h*.02)
		draw_rect(r,_c("aaa08c","3a393a").darkened(.05*i))
	var throne:=Rect2(w*.465,back.end.y-h*.20,w*.07,h*.18)
	draw_rect(throne,_c("6c5a44","241e18"))
	draw_rect(Rect2(throne.position.x-4,throne.position.y-6,throne.size.x+8,10),_c("c9a24a","9c7c34"))
	# Columns receding in two rows, banners hung between them.
	for k in 4:
		var d:=pow(float(k)/4.0,1.25)
		var lx:=lerpf(w*.07,back.position.x+back.size.x*.06,d);var rx:=lerpf(w*.93,back.end.x-back.size.x*.06,d)
		var bottom:=lerpf(h*1.02,back.end.y,d);var top:=lerpf(-h*.02,back.position.y,d)
		var thick:=lerpf(w*.045,w*.014,d)
		for x:float in [lx,rx]:
			_column(Rect2(x-thick*.5,top,thick,bottom-top),palace)
		if k<3:
			var nd:=pow(float(k+1)/4.0,1.25)
			for side in 2:
				var x0:=lx if side==0 else rx
				var x1:=lerpf(w*.07,back.position.x+back.size.x*.06,nd) if side==0 else lerpf(w*.93,back.end.x-back.size.x*.06,nd)
				var ntop:=lerpf(-h*.02,back.position.y,nd)
				var mid:=(x0+x1)*.5
				var bw:=absf(x1-x0)*.42
				var by:=lerpf(top,ntop,.5)+h*.10*(1.0-d)
				var bh:=lerpf(h*.34,h*.14,d)
				_banner(Rect2(mid-bw*.5,by,bw,bh))
	_before_fire(w,h)
	# Braziers either side of the dais.
	for side:float in [-1.0,1.0]:
		var foot:=Vector2(w*.5+side*w*.17,back.end.y+h*.12)
		draw_line(foot,foot+Vector2(0,-h*.12),_c("4a4036","7a6e5c"),3.0)
		draw_colored_polygon(PackedVector2Array([foot+Vector2(-h*.05,-h*.12),foot+Vector2(h*.05,-h*.12),foot+Vector2(h*.03,-h*.15),foot+Vector2(-h*.03,-h*.15)]),_c("5a4c3c","8a7a64"))
		_fire(foot+Vector2(0,-h*.15),h*.07)
	if not palace: _fire(hearth_point()+Vector2(0,h*.06),h*.11)

func _column(r:Rect2,palace:bool)->void:
	var shaft:=_c("d6cdb9","3d3c3d") if not palace else _c("e2dccd","48474a")
	draw_rect(r,shaft)
	draw_rect(Rect2(r.position.x,r.position.y,r.size.x*.25,r.size.y),Color(_c("b3a992","2b2a2b"),.8))
	for i in 3:
		var x:=r.position.x+r.size.x*(.35+.2*i)
		draw_line(Vector2(x,r.position.y+r.size.x),Vector2(x,r.end.y-r.size.x*.6),Color(_c("a89e88","2c2b2c"),.8),1.0)
	draw_rect(Rect2(r.position.x-r.size.x*.18,r.end.y-r.size.x*.5,r.size.x*1.36,r.size.x*.5),_c("c2b8a3","353435"))
	draw_rect(Rect2(r.position.x-r.size.x*.22,r.position.y+maxf(0,r.size.x*.1),r.size.x*1.44,r.size.x*.45),_c("c2b8a3","353435"))

func _banner(r:Rect2)->void:
	if r.size.x<4: return
	var body:=Color(banner,.92)
	var poly:=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),Vector2(r.end.x,r.end.y),Vector2(r.get_center().x,r.end.y-r.size.y*.14),Vector2(r.position.x,r.end.y)])
	draw_colored_polygon(poly,body)
	draw_rect(Rect2(r.position.x-2,r.position.y-3,r.size.x+4,4),_c("5a4630","8a7658"))
	var c:=r.get_center()+Vector2(0,-r.size.y*.08)
	var s:=minf(r.size.x,r.size.y)*.22
	draw_colored_polygon(PackedVector2Array([c+Vector2(0,-s),c+Vector2(s*.8,0),c+Vector2(0,s),c+Vector2(-s*.8,0)]),_c("e2c46a","c9a54e"))
	draw_line(Vector2(r.position.x+r.size.x*.12,r.position.y+2),Vector2(r.position.x+r.size.x*.12,r.end.y-r.size.y*.1),Color(1,1,1,.12),2.0)

# ---------------------------------------------------------------- helpers

func _hanging(r:Rect2,a:Color,b:Color,variant:int)->void:
	draw_rect(r,a)
	draw_rect(Rect2(r.position.x-3,r.position.y-4,r.size.x+6,5),_c("5e4127","1f160e"))
	var bands:=5
	for i in bands:
		var y:=r.position.y+r.size.y*(float(i)+.5)/float(bands)
		if (i+variant)%2==0:
			_zigzag(Vector2(r.position.x+3,y),Vector2(r.end.x-3,y),b,7)
		else:
			var steps:=4
			for s in steps:
				var cx:=r.position.x+r.size.x*(float(s)+.5)/float(steps)
				var d:=r.size.x/float(steps)*.32
				draw_colored_polygon(PackedVector2Array([Vector2(cx,y-d),Vector2(cx+d,y),Vector2(cx,y+d),Vector2(cx-d,y)]),b)
	for i in 7:
		var x:=r.position.x+r.size.x*float(i)/6.0
		draw_line(Vector2(x,r.end.y),Vector2(x,r.end.y+6),a.darkened(.2),1.5)

func _zigzag(from:Vector2,to:Vector2,colour:Color,teeth:int)->void:
	var points:=PackedVector2Array()
	for i in teeth*2+1:
		var t:=float(i)/float(teeth*2)
		points.append(from.lerp(to,t)+Vector2(0,-4.0 if i%2==0 else 4.0))
	draw_polyline(points,colour,2.0,true)

func _bricks(r:Rect2,mortar:Color,rows:int,per_row:int)->void:
	var rh:=r.size.y/float(rows)
	for i in rows+1:
		draw_line(Vector2(r.position.x,r.position.y+rh*i),Vector2(r.end.x,r.position.y+rh*i),Color(mortar,.8),1.0)
	for i in rows:
		var offset:=.5 if i%2==1 else 0.0
		for j in per_row:
			var x:=r.position.x+r.size.x*(float(j)+offset)/float(per_row)
			if x<=r.position.x or x>=r.end.x: continue
			draw_line(Vector2(x,r.position.y+rh*i),Vector2(x,r.position.y+rh*(i+1)),Color(mortar,.8),1.0)

func _light_shaft(a:Vector2,b:Vector2,c:Vector2,d:Vector2)->void:
	var bright:=Color(1,.95,.8,.16 if not dark else .10)
	var fade:=Color(1,.95,.8,0)
	draw_polygon(PackedVector2Array([a,b,c,d]),PackedColorArray([bright,bright,fade,fade]))

func _hills(w:float,base:float,height:float,colour:Color,phase:float)->void:
	var points:=PackedVector2Array([Vector2(0,base+height)])
	for i in 25:
		var x:=w*float(i)/24.0
		points.append(Vector2(x,base-height*(.5+.3*sin(float(i)*.7+phase)+.2*sin(float(i)*1.9+phase*2.0))))
	points.append(Vector2(w,base+height))
	draw_colored_polygon(points,colour)

func _band(center:Vector2,width:float,height:float,colour:Color)->void:
	draw_colored_polygon(_ellipse(center,Vector2(width*.5,height*.5),20),colour)

func _gradient(r:Rect2,top:Color,bottom:Color)->void:
	draw_polygon(PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]),PackedColorArray([top,top,bottom,bottom]))

func _quad(a:Vector2,b:Vector2,c:Vector2,d:Vector2,colour:Color)->void:
	draw_colored_polygon(PackedVector2Array([a,b,c,d]),colour)

func _tri(a:Vector2,b:Vector2,c:Vector2,colour:Color)->void:
	draw_colored_polygon(PackedVector2Array([a,b,c]),colour)

func _ellipse(center:Vector2,radii:Vector2,segments:int)->PackedVector2Array:
	var points:=PackedVector2Array()
	for i in segments:
		var a:=TAU*float(i)/float(segments)
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	return points

func _rng(salt:int)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("court:%s:%d" % [scene if scene!="fire_circle" else str(tier),salt])
	return rng

func _grain(w:float,h:float)->void:
	## Paper tooth and gouache unevenness: faint blotches and flecks.
	var rng:=_rng(99)
	for i in 70:
		var p:=Vector2(rng.randf()*w,rng.randf()*h)
		draw_circle(p,rng.randf_range(h*.04,h*.12),Color(_c("fff6e2","000000"),rng.randf_range(.02,.05)))
	for i in 420:
		var p:=Vector2(rng.randf()*w,rng.randf()*h)
		draw_circle(p,rng.randf_range(.5,1.3),Color(_c("4a3b2a","f0e2c4"),rng.randf_range(.03,.09)))

func _vignette(w:float,h:float)->void:
	var edge:=Color(_c("3a2c1c","000000"),.22 if not dark else .45)
	var clear:=Color(edge,0.0)
	var band:=minf(w,h)*.22
	draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(w,0),Vector2(w,band),Vector2(0,band)]),PackedColorArray([edge,edge,clear,clear]))
	draw_polygon(PackedVector2Array([Vector2(0,h-band),Vector2(w,h-band),Vector2(w,h),Vector2(0,h)]),PackedColorArray([clear,clear,edge,edge]))
	draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(band,0),Vector2(band,h),Vector2(0,h)]),PackedColorArray([edge,clear,clear,edge]))
	draw_polygon(PackedVector2Array([Vector2(w-band,0),Vector2(w,0),Vector2(w,h),Vector2(w-band,h)]),PackedColorArray([clear,edge,edge,clear]))

# ---------------------------------------------------------------- forms of court

func _before_fire(w:float,h:float)->void:
	## Each form of court dresses its setting and its attendants take their
	## places; the fire or braziers are drawn last, in front of them.
	match scene:
		"elders_ring": _dress_elders(w,h)
		"chiefs_hall": _dress_chiefs(w,h)
		"temple_palace": _dress_temple(w,h)
		"palace_hall": _dress_palace(w,h)
		"imperial_hall": _dress_imperial(w,h,false)
		"basilica": _dress_imperial(w,h,true)
		"chancery": _dress_chancery(w,h)
		"commune_hall": _dress_commune(w,h)
		"great_hall": _dress_great_hall(w,h)
		"estates_hall": _dress_estates(w,h)
	_draw_attendants(w,h)

# --- The elders' ring: standing stones, carved seats, the speaking staff ----

func _dress_elders(w:float,h:float)->void:
	var horizon:=h*.50
	# Dusk: the elders meet as the day's work ends.
	draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(w,0),Vector2(w,horizon),Vector2(0,horizon)]),
		PackedColorArray([Color(_c("f0a860","3a2a4a"),0.0),Color(_c("f0a860","3a2a4a"),0.0),Color(_c("e8904a","6a3a3a"),.30),Color(_c("e8904a","6a3a3a"),.30)]))
	var rng:=_rng(41)
	for i in 11:
		var t:=float(i)/10.0
		var x:=w*(.06+.88*t)
		if absf(x-w*.5)<w*.06: continue
		var lift:=sin(t*PI)
		var foot:=Vector2(x,horizon+h*.17-lift*h*.07)
		var tall:=h*rng.randf_range(.15,.22)*(1.0-.35*lift)
		var wide:=tall*rng.randf_range(.30,.42)
		var lean:=rng.randf_range(-.08,.08)*tall
		var stone:=_c("a39c8c","423f3b").lerp(_c("8d8676","35332f"),rng.randf())
		draw_colored_polygon(_ellipse(foot+Vector2(0,2),Vector2(wide*.7,wide*.16),12),Color(0,0,0,.16 if not dark else .3))
		var slab:=PackedVector2Array([foot+Vector2(-wide*.5,0),foot+Vector2(-wide*.44+lean,-tall*.86),foot+Vector2(-wide*.18+lean,-tall),foot+Vector2(wide*.24+lean,-tall*.96),foot+Vector2(wide*.48+lean*.6,-tall*.70),foot+Vector2(wide*.5,0)])
		draw_colored_polygon(slab,stone)
		draw_colored_polygon(PackedVector2Array([foot+Vector2(-wide*.5,0),foot+Vector2(-wide*.44+lean,-tall*.86),foot+Vector2(-wide*.20+lean,-tall*.9),foot+Vector2(-wide*.22,0)]),Color(stone.lightened(.14),.9))
		for k in 3:
			draw_circle(foot+Vector2(rng.randf_range(-.3,.3)*wide+lean*.5,-tall*rng.randf_range(.2,.8)),wide*.07,Color(_c("8f9a62","4a5234"),.55))
	# Two carved seats with high backs for the eldest.
	for side:float in [-1.0,1.0]:
		var base:=Vector2(w*.5+side*w*.15,h*.70)
		var ink:=_c("5a4128","3a2a1a")
		draw_rect(Rect2(base.x-h*.035,base.y-h*.035,h*.07,h*.035),ink)
		for post:float in [-1.0,1.0]:
			var px:=base.x+post*h*.03
			draw_line(Vector2(px,base.y),Vector2(px,base.y-h*.13),ink,3.0,true)
			draw_circle(Vector2(px,base.y-h*.135),h*.012,_c("7a5a38","5a4028"))
		draw_rect(Rect2(base.x-h*.03,base.y-h*.12,h*.06,h*.05),_c("8a6844","4a3522"))
		_zigzag(Vector2(base.x-h*.028,base.y-h*.095),Vector2(base.x+h*.028,base.y-h*.095),_c("e2cfa4","a08a64"),3)
	# The speaking staff, planted beside the fire.
	var foot:=hearth_point()+Vector2(h*.30,h*.01)
	draw_line(foot,foot+Vector2(-h*.02,-h*.34),_c("4f3a24","c8a878"),3.0,true)
	draw_circle(foot+Vector2(-h*.02,-h*.35),h*.018,_c("c9a878","a08058"))
	for k in 3:
		var tip:=foot+Vector2(-h*.02,-h*.33)
		draw_line(tip,tip+Vector2(h*(.02+.012*k),h*(.05+.02*k)),[_c("b0463a","8a3a2e"),_c("e2cfa4","b8a078"),_c("3c5a6a","32505e")][k],1.5,true)

# --- The chief's hall: the high seat, shields on the posts, the feast board ---

func _dress_chiefs(w:float,h:float)->void:
	var back:=Rect2(w*.40,h*.30,w*.20,h*.34)
	var wood:=_c("4f3824","1d150d")
	# The raised high seat at the back, under the smoke-hole's light.
	var platform:=Rect2(back.position.x+back.size.x*.05,back.end.y-h*.05,back.size.x*.9,h*.05)
	draw_rect(platform,_c("6d5236","2b2015"))
	draw_rect(Rect2(platform.position.x,platform.position.y,platform.size.x,3),_c("8c6c48","3a2c1c"))
	var seat:=Rect2(w*.47,platform.position.y-h*.12,w*.06,h*.12)
	draw_rect(seat,wood)
	for post:float in [seat.position.x-2.0,seat.end.x-4.0]:
		draw_rect(Rect2(post,seat.position.y-h*.08,6,seat.size.y+h*.08),_c("6a4a2c","2a1d12"))
		draw_circle(Vector2(post+3,seat.position.y-h*.085),6,_c("c9a24a","8a6a30"))
	draw_colored_polygon(PackedVector2Array([seat.position+Vector2(-4,seat.size.y*.45),seat.position+Vector2(seat.size.x+4,seat.size.y*.45),seat.end+Vector2(6,0),Vector2(seat.position.x-6,seat.end.y)]),_c("d9c29a","7c6446"))
	# Painted round shields hung on the near posts.
	var colours:=[banner,_c("d8b25a","9a7a34"),_c("e8dcc0","8c8068"),_c("3c5a6a","2a4250")]
	for k in 3:
		var d:=pow(float(k)/4.0,1.3)
		var bottom:=lerpf(h*1.02,back.end.y,d);var top:=lerpf(h*.02,back.position.y,d)
		var radius:=lerpf(w*.030,w*.012,d)
		for side in 2:
			var x:=lerpf(w*.10,back.position.x+back.size.x*.08,d) if side==0 else lerpf(w*.90,back.end.x-back.size.x*.08,d)
			var c:=Vector2(x,lerpf(top,bottom,.40))
			var paint:Color=colours[(k+side*2)%colours.size()]
			draw_circle(c,radius,paint)
			draw_arc(c,radius,0,TAU,20,_c("3a2a1a","1a120a"),2.0,true)
			draw_line(c-Vector2(radius,0),c+Vector2(radius,0),Color(paint.darkened(.3),.8),2.0)
			draw_circle(c,radius*.28,_c("8a7a64","b0a08a"))
	# The feast board down the right side, with bowls and horns.
	var board:=PackedVector2Array([Vector2(w*.60,h*.66),Vector2(w*.645,h*.66),Vector2(w*.90,h*.97),Vector2(w*.77,h*.97)])
	draw_colored_polygon(board,_c("8a6a44","3a2a1a"))
	draw_line(board[0],board[3],_c("5a4028","20160c"),2.0,true)
	for i in 6:
		var t:=float(i)/5.0
		var p:=Vector2(lerpf(w*.622,w*.835,t),lerpf(h*.665,h*.955,t))
		draw_colored_polygon(_ellipse(p,Vector2(h*(.012+.012*t),h*(.006+.006*t)),10),_c("c9a26a","6e5434"))

# --- The house of the god: niches, the offering table, tablets and smoke ----

func _dress_temple(w:float,h:float)->void:
	var back:=Rect2(w*.26,h*.14,w*.48,h*.52)
	# A lamp-lit niche above the seat, stepped like the shrine terrace.
	var niche:=Rect2(w*.465,back.position.y+back.size.y*.04,w*.07,back.size.y*.30)
	for step in 3:
		var grow:=float(3-step)*h*.012
		draw_rect(Rect2(niche.position.x-grow,niche.position.y+float(step)*h*.012,niche.size.x+grow*2.0,niche.size.y-float(step)*h*.012),_c("8a6440","2e2016").darkened(.08*step))
	_radial(niche.get_center(),Vector2(niche.size.x,niche.size.y*.7),Color(1,.8,.45,.35 if dark else .25),Color(1,.8,.45,0))
	draw_circle(niche.get_center()+Vector2(0,niche.size.y*.2),h*.012,_c("f3c060","f8d880"))
	# The offering table before the dais: jars, a heap of grain, a lamp.
	var top:=back.end.y+h*.07
	var table:=Rect2(w*.42,top,w*.16,h*.025)
	draw_rect(Rect2(table.position.x+6,top,4,h*.07),_c("5a3e25","1e150d"))
	draw_rect(Rect2(table.end.x-10,top,4,h*.07),_c("5a3e25","1e150d"))
	draw_rect(table,_c("7a5634","2e2116"))
	draw_colored_polygon(_ellipse(Vector2(w*.47,top-h*.01),Vector2(h*.035,h*.018),14),_c("d8b460","8a7034"))
	for k in 3:
		var jar:=Vector2(w*(.505+.025*k),top-h*.028)
		draw_colored_polygon(_ellipse(jar,Vector2(h*.014,h*.024),12),_c("b0643a","8a4a2a").lightened(.08*k))
		draw_rect(Rect2(jar.x-h*.007,jar.y-h*.03,h*.014,h*.008),_c("8a4a2a","6a3a20"))
	# Incense rising from two burners.
	for side:float in [-1.0,1.0]:
		var foot:=Vector2(w*.5+side*w*.12,top+h*.06)
		draw_rect(Rect2(foot.x-h*.012,foot.y-h*.05,h*.024,h*.05),_c("a0683a","7a5030"))
		for k in 4:
			var y:=foot.y-h*(.07+.07*k)
			var x:=foot.x+sin(float(k)*1.3+_clock*.8+side)*h*.03
			draw_circle(Vector2(x,y),h*(.018+.01*k),Color(_c("f0e6d4","8a8478"),.20-.04*k))
	# Stacks of clay tablets by the scribes' mats.
	for k in 4:
		var base:=Vector2(w*(.10+.035*k),h*(.86+.012*(k%2)))
		for layer in 3:
			draw_rect(Rect2(base.x,base.y-float(layer)*h*.012,h*.035,h*.011),_c("c49a6a","6e5436").darkened(.06*layer))

# --- The palace hall: archive shelves, the law stele ------------------------

func _dress_palace(w:float,h:float)->void:
	var back:=Rect2(w*.30,h*.10,w*.40,h*.56)
	for side in 2:
		var shelf:=Rect2(back.position.x+back.size.x*(.03 if side==0 else .71),back.position.y+back.size.y*.34,back.size.x*.26,back.size.y*.52)
		draw_rect(shelf,_c("6a5a44","231e18"))
		var cols:=4;var rows:=5
		for r in rows:
			for c in cols:
				var cell:=Rect2(shelf.position.x+shelf.size.x*float(c)/float(cols)+2,shelf.position.y+shelf.size.y*float(r)/float(rows)+2,shelf.size.x/float(cols)-4,shelf.size.y/float(rows)-4)
				draw_rect(cell,_c("3e3428","120f0c"))
				var fill:=(r*3+c+side)%4
				for k in fill:
					draw_rect(Rect2(cell.position.x+2+float(k)*cell.size.x*.26,cell.end.y-cell.size.y*.7,cell.size.x*.2,cell.size.y*.66),_c("c7a676","7a6446"))
	# A law stele beside the dais, its face cut in close lines.
	var stele:=Rect2(w*.335,back.end.y-h*.02,w*.045,h*.20)
	draw_rect(Rect2(stele.position.x-4,stele.end.y,stele.size.x+8,h*.015),_c("9a907c","2e2d2c"))
	draw_rect(stele,_c("5a5650","3a3834"))
	draw_circle(Vector2(stele.get_center().x,stele.position.y),stele.size.x*.5,_c("5a5650","3a3834"))
	for k in 9:
		var y:=stele.position.y+stele.size.y*(.18+.085*k)
		draw_line(Vector2(stele.position.x+4,y),Vector2(stele.end.x-4,y),Color(_c("c9c2b0","8a8478"),.7),1.0)

# --- The imperial throne hall: a gold-ground apse, curtains, lamps ----------

func _dress_imperial(w:float,h:float,basilica:bool)->void:
	## The throne hall: gold apse and purple curtains. The consistory: the same
	## stones in lamp-lit gloom, a blue mosaic apse strewn with gold stars.
	var back:=Rect2(w*.30,h*.10,w*.40,h*.56)
	if basilica:
		draw_rect(Rect2(0,0,w,h),Color(_c("1a1a2a","000000"),.45))
	var centre:=Vector2(w*.5,back.end.y-h*.18)
	var radius:=back.size.x*.30
	var dome:=PackedVector2Array([centre+Vector2(-radius,h*.16)])
	for i in 25:
		var a:=PI+PI*float(i)/24.0
		dome.append(centre+Vector2(cos(a)*radius,sin(a)*radius))
	dome.append(centre+Vector2(radius,h*.16))
	if basilica:
		draw_colored_polygon(dome,_c("223a6a","142448"))
		var stars:=_rng(51)
		for i in 26:
			var a:=PI+stars.randf()*PI
			var p:=centre+Vector2(cos(a),sin(a))*radius*stars.randf_range(.2,.92)
			draw_circle(p,stars.randf_range(1.2,2.6),_c("e8c35a","f0d070"))
		_radial(centre+Vector2(0,-radius*.35),Vector2(radius*.35,radius*.35),Color(_c("f6e39a","e8c35a"),.8),Color(_c("f6e39a","e8c35a"),0))
		draw_arc(centre,radius,PI,TAU,32,_c("c9a24a","8a6a24"),5.0,true)
	else:
		draw_colored_polygon(dome,_c("c9a24a","8a6a24"))
		_radial(centre,Vector2(radius,radius),Color(_c("f6e39a","e8c35a"),.9),Color(_c("c9a24a","8a6a24"),0))
		for i in 17:
			var a:=PI+PI*float(i)/16.0
			draw_line(centre,centre+Vector2(cos(a),sin(a))*radius*.96,Color(_c("fff4c8","f0d88a"),.35),1.5,true)
		draw_arc(centre,radius,PI,TAU,32,_c("2a3a6a","1a2448"),4.0,true)
		draw_arc(centre,radius*.9,PI,TAU,32,Color(_c("2a3a6a","1a2448"),.5),1.5,true)
	# Purple curtains drawn back either side of the apse.
	for side:float in ([] if basilica else [-1.0,1.0]):
		var x:=centre.x+side*radius
		var drape:=PackedVector2Array([Vector2(x,centre.y-radius*1.05),Vector2(x+side*w*.05,centre.y-radius*1.05),Vector2(x+side*w*.03,centre.y+h*.16),Vector2(x+side*w*.005,centre.y+h*.02)])
		draw_colored_polygon(drape,Color(banner,.95))
		draw_line(drape[0],drape[3],Color(banner.lightened(.25),.8),2.0,true)
		draw_line(Vector2(x+side*w*.02,centre.y+h*.06),Vector2(x+side*w*.035,centre.y+h*.06),_c("e8c35a","c9a24a"),3.0)
	# Lamps of many lights hang down the hall.
	for k in 3:
		var d:=float(k)/3.0
		var x:=lerpf(w*.18,w*.40,d)
		for side:float in [-1.0,1.0]:
			var lx:=w*.5+side*(w*.5-x)
			var ly:=lerpf(h*.34,h*.22,d)
			draw_line(Vector2(lx,0),Vector2(lx,ly),Color(_c("5a4a30","8a7a5a"),.8),1.0)
			draw_arc(Vector2(lx,ly),lerpf(h*.05,h*.025,d),0,TAU,18,_c("b08a3a","c9a24a"),2.0,true)
			for f in 5:
				var a:=TAU*float(f)/5.0
				draw_circle(Vector2(lx,ly)+Vector2(cos(a)*lerpf(h*.05,h*.025,d),sin(a)*lerpf(h*.012,h*.006,d)),lerpf(3.0,1.6,d),Color(1,.8,.4,.9))

# --- The chamber of the seal: the clerks' long table, chests and rolls -------

func _dress_chancery(w:float,h:float)->void:
	# Tracery in the tall windows: a mullion and a round light above.
	var back:=Rect2(w*.30,h*.10,w*.40,h*.56)
	for i in 2:
		var r:=Rect2(back.position.x+back.size.x*(.14+.56*i),back.position.y+back.size.y*.10,back.size.x*.16,back.size.y*.46)
		draw_arc(Vector2(r.get_center().x,r.position.y+r.size.y*.12),r.size.x*.22,0,TAU,16,_c("6a6254","3a3530"),2.0,true)
		for k in 5:
			var y:=r.position.y+r.size.y*(.3+.14*k)
			draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y),Color(_c("8d8474","3a3530"),.6),1.0)
	# The long table across the chamber, covered in green cloth.
	var top:=h*.70
	var cloth:=_c("3f6a4a","1f3a28")
	draw_colored_polygon(PackedVector2Array([Vector2(w*.26,top),Vector2(w*.74,top),Vector2(w*.77,top+h*.05),Vector2(w*.23,top+h*.05)]),cloth)
	draw_rect(Rect2(w*.23,top+h*.05,w*.54,h*.035),cloth.darkened(.2))
	for k in 12:
		var x:=w*(.25+.043*k)
		draw_line(Vector2(x,top+h*.05),Vector2(x,top+h*.085),Color(cloth.darkened(.4),.6),1.0)
	# Rolls, bound books, candles and the great seal.
	var rng:=_rng(61)
	for k in 9:
		var x:=w*(.28+.05*k)
		if absf(x-w*.5)<w*.03: continue
		var y:=top+h*rng.randf_range(.008,.03)
		if k%3==0:
			draw_rect(Rect2(x,y-h*.02,h*.035,h*.022),_c("6a3a24","4a2818"))
			draw_rect(Rect2(x+2,y-h*.02,h*.031,h*.005),_c("e8dcc0","b8a888"))
		else:
			draw_rect(Rect2(x,y-h*.012,h*.05,h*.012),_c("efe2c2","c8b890"))
			draw_circle(Vector2(x,y-h*.006),h*.006,_c("d8c8a0","a89870"))
			draw_circle(Vector2(x+h*.05,y-h*.006),h*.006,_c("d8c8a0","a89870"))
	draw_circle(Vector2(w*.5,top+h*.022),h*.022,_c("a82a22","8a2018"))
	draw_arc(Vector2(w*.5,top+h*.022),h*.015,0,TAU,16,_c("e89a8a","c86a5a"),1.2,true)
	for x:float in [w*.34,w*.66]:
		draw_rect(Rect2(x-2,top-h*.05,4,h*.05),_c("f2ead6","e8dcc0"))
		draw_circle(Vector2(x,top-h*.056),3.0,Color(1,.8,.4,.95))
	# Iron-bound chests of rolls at either side.
	for side:float in [-1.0,1.0]:
		var chest:=Rect2(w*.5+side*w*.34-w*.04,h*.80,w*.08,h*.07)
		draw_rect(chest,_c("6a4a2c","2e2016"))
		draw_rect(Rect2(chest.position.x,chest.position.y,chest.size.x,chest.size.y*.3),_c("7a5a38","3a2a1c"))
		for k in 3:
			draw_line(Vector2(chest.position.x+chest.size.x*(.2+.3*k),chest.position.y),Vector2(chest.position.x+chest.size.x*(.2+.3*k),chest.end.y),_c("3a3a3a","7a7a7a"),2.0)

# --- The great hall: timber trusses over stone, lamps, the high table --------

func _draw_great_hall(w:float,h:float)->void:
	var back:=Rect2(w*.28,h*.18,w*.44,h*.48)
	var estates:=scene=="estates_hall" or scene=="commune_hall"
	_gradient(Rect2(0,0,w,h),_c("5a4a38","141110"),_c("8a7860","2a241c"))
	var stone:=_c("9a8c74","2e2a24") if not estates else _c("b0a48c","35302a")
	_quad(Vector2(0,h*.10),back.position,Vector2(back.position.x,back.end.y),Vector2(0,h),stone)
	_quad(Vector2(w,h*.10),Vector2(back.end.x,back.position.y),back.end,Vector2(w,h),stone.darkened(.05))
	draw_rect(back,stone.lightened(.06))
	_bricks(back,_c("7a6c56","221e1a"),7,5)
	# The roof: timber trusses receding to the back wall.
	var timber:=_c("4a3420","120d08")
	draw_rect(Rect2(0,0,w,h*.10),_c("3a2a1a","0c0906"))
	for k in 5:
		var d:=pow(float(k)/5.0,1.2)
		var lx:=lerpf(0,back.position.x,d);var rx:=lerpf(w,back.end.x,d)
		var wall:=lerpf(h*.10,back.position.y,d)
		var apex:=Vector2(w*.5,lerpf(-h*.20,back.position.y-back.size.y*.18,d))
		var thick:=lerpf(9.0,2.5,d)
		draw_line(Vector2(lx,wall),Vector2(rx,wall),timber,thick)
		draw_line(Vector2(lx,wall),apex,timber,thick)
		draw_line(Vector2(rx,wall),apex,timber,thick)
		draw_line(Vector2(w*.5,wall),apex,timber,thick*.8)
		draw_line(Vector2(lerpf(lx,w*.5,.45),wall),Vector2(lerpf(lx,apex.x,.55),lerpf(wall,apex.y,.55)),timber,thick*.6)
		draw_line(Vector2(lerpf(rx,w*.5,.45),wall),Vector2(lerpf(rx,apex.x,.55),lerpf(wall,apex.y,.55)),timber,thick*.6)
	# A hanging on the back wall: rows of lozenges in the house colour.
	if not estates:
		var hang:=Rect2(back.position.x+back.size.x*.14,back.position.y+back.size.y*.10,back.size.x*.72,back.size.y*.56)
		_hanging(hang,Color(banner.darkened(.1),1.0),_c("d8b25a","9a7a34"),1)
	# The floor of flagstones.
	_quad(Vector2(0,h),Vector2(back.position.x,back.end.y),back.end,Vector2(w,h),_c("8a7c66","24201b"))
	for i in 7:
		var t:=pow(float(i)/6.0,1.5)
		var y:=lerpf(back.end.y,h,t)
		draw_line(Vector2(lerpf(back.position.x,0,t),y),Vector2(lerpf(back.end.x,w,t),y),Color(_c("6a5e4c","1a1714"),.7),1.0,true)
	# The high table on its dais across the back.
	var dais:=Rect2(back.position.x+back.size.x*.06,back.end.y-h*.035,back.size.x*.88,h*.035)
	draw_rect(dais,_c("6a5038","231a12"))
	draw_rect(Rect2(dais.position.x+dais.size.x*.08,dais.position.y-h*.04,dais.size.x*.84,h*.03),_c("eee4cc","8a8068"))
	draw_rect(Rect2(dais.position.x+dais.size.x*.08,dais.position.y-h*.01,dais.size.x*.84,h*.012),_c("d8ccb0","6a624e"))
	var chair:=Rect2(w*.48,dais.position.y-h*.15,w*.04,h*.12)
	draw_rect(chair,_c("4a3220","1a120a"))
	draw_colored_polygon(PackedVector2Array([chair.position+Vector2(0,0),chair.position+Vector2(chair.size.x*.5,-h*.03),chair.position+Vector2(chair.size.x,0)]),_c("4a3220","1a120a"))
	# Long trestle tables down both sides.
	for side:float in [-1.0,1.0]:
		var near:=w*.5+side*w*.36;var far:=w*.5+side*back.size.x*.36
		var poly:=PackedVector2Array([Vector2(far,back.end.y+h*.02),Vector2(far+side*w*.02,back.end.y+h*.02),Vector2(near+side*w*.08,h*.98),Vector2(near,h*.98)])
		draw_colored_polygon(poly,_c("7a5a3a","2e2216"))
		draw_line(poly[0],poly[3],_c("4a3420","160f09"),2.0,true)
	# Lamps hung from the tie-beams.
	for k in 3:
		var d:=float(k+1)/4.0
		var y:=lerpf(h*.34,back.position.y+h*.06,d)
		for side:float in [-1.0,1.0]:
			var x:=w*.5+side*lerpf(w*.26,back.size.x*.28,d)
			draw_line(Vector2(x,lerpf(h*.10,back.position.y,d)),Vector2(x,y),Color(timber,.9),1.2)
			var r:=lerpf(h*.04,h*.02,d)
			draw_arc(Vector2(x,y),r,0,TAU,16,_c("6a5a3a","8a7a5a"),2.0,true)
			for f in 4:
				var a:=TAU*float(f)/4.0
				draw_circle(Vector2(x,y)+Vector2(cos(a)*r,sin(a)*r*.3),lerpf(3.0,1.6,d),Color(1,.78,.38,.95))
			_radial(Vector2(x,y),Vector2(r*3.0,r*3.0),Color(1,.75,.35,.12),Color(1,.75,.35,0))
	_before_fire(w,h)
	_fire(hearth_point(),h*.13)

func _dress_great_hall(w:float,h:float)->void:
	## Shields of sworn households on the side walls; a gold sunburst above.
	var colours:=[banner.lightened(.1),_c("a8342a","8a2a22"),_c("d8b25a","9a7a34"),_c("2e4a6a","2a4058")]
	for k in 4:
		var d:=float(k)/4.0
		for side:float in [-1.0,1.0]:
			var x:=w*.5+side*lerpf(w*.46,w*.24,d)
			var y:=lerpf(h*.40,h*.30,d)
			var s:=lerpf(h*.06,h*.03,d)
			var paint:Color=colours[(k+int(side>0.0))%colours.size()]
			draw_colored_polygon(PackedVector2Array([Vector2(x-s,y-s),Vector2(x+s,y-s),Vector2(x+s,y+s*.3),Vector2(x,y+s*1.2),Vector2(x-s,y+s*.3)]),paint)
			draw_line(Vector2(x,y-s),Vector2(x,y+s*1.1),Color(_c("f0e6d0","c8bca0"),.8),2.0)

func _dress_commune(w:float,h:float)->void:
	## The commune's council chamber: the square and its bell tower through the
	## great window, a horseshoe table in red cloth, guild banners, the charter.
	var back:=Rect2(w*.28,h*.18,w*.44,h*.48)
	var win:=Rect2(w*.38,back.position.y+back.size.y*.08,w*.24,back.size.y*.46)
	draw_rect(Rect2(win.position.x-6,win.position.y-6,win.size.x+12,win.size.y+12),_c("5a4028","1e150d"))
	_gradient(win,_c("b8d0e0","1a2440"),_c("efe8d4","4a4a58"))
	# House fronts with stepped gables across the square.
	var fronts:=_rng(53)
	var x:=win.position.x
	while x<win.end.x-4:
		var bw:=win.size.x*fronts.randf_range(.12,.2)
		var bh:=win.size.y*fronts.randf_range(.30,.46)
		var tone:=_c("e0cfb0","5a5046").lerp(_c("c08a64","6a4a38"),fronts.randf())
		var right:=minf(x+bw,win.end.x)
		draw_rect(Rect2(x,win.end.y-bh,right-x,bh),tone)
		for step in 3:
			var inset:=(right-x)*.16*float(step+1)
			draw_rect(Rect2(x+inset,win.end.y-bh-float(step+1)*win.size.y*.03,maxf(1.0,right-x-inset*2.0),win.size.y*.03),tone)
		x=right+2
	# The bell tower rising above them.
	var tower:=Rect2(win.get_center().x-win.size.x*.06,win.position.y+win.size.y*.08,win.size.x*.12,win.size.y*.92)
	draw_rect(tower,_c("d8c8a8","5a5248"))
	draw_rect(Rect2(tower.position.x+tower.size.x*.25,tower.position.y+tower.size.y*.12,tower.size.x*.5,tower.size.y*.14),_c("3a3028","14100c"))
	draw_circle(Vector2(tower.get_center().x,tower.position.y+tower.size.y*.22),tower.size.x*.14,_c("c9a24a","b08a3a"))
	draw_colored_polygon(PackedVector2Array([tower.position,Vector2(tower.get_center().x,tower.position.y-win.size.y*.12),Vector2(tower.end.x,tower.position.y)]),_c("5a6a6a","3a4448"))
	for k in 3:
		draw_line(Vector2(win.position.x+win.size.x*float(k+1)/4.0,win.position.y),Vector2(win.position.x+win.size.x*float(k+1)/4.0,win.end.y),_c("5a4028","1e150d"),2.0)
	draw_line(Vector2(win.position.x,win.get_center().y),Vector2(win.end.x,win.get_center().y),_c("5a4028","1e150d"),2.0)
	# Guild banners down both walls.
	var guilds:=[_c("2e5a8a","24466a"),_c("c9a24a","9a7a34"),_c("3a6a3a","2a502a"),_c("e8dcc0","a89878"),banner]
	for k in 4:
		var d:=float(k)/4.0
		for side:float in [-1.0,1.0]:
			var bx:=w*.5+side*lerpf(w*.44,back.size.x*.52,d)
			var by:=lerpf(h*.22,back.position.y+h*.03,d)
			var bw:=lerpf(w*.035,w*.015,d);var bh:=lerpf(h*.20,h*.09,d)
			var paint:Color=guilds[(k+int(side>0.0)*2)%guilds.size()]
			draw_colored_polygon(PackedVector2Array([Vector2(bx-bw*.5,by),Vector2(bx+bw*.5,by),Vector2(bx+bw*.5,by+bh*.8),Vector2(bx,by+bh),Vector2(bx-bw*.5,by+bh*.8)]),paint)
			draw_circle(Vector2(bx,by+bh*.4),bw*.22,Color(_c("f6efdc","d8ccb0"),.9))
	# The bell rope hanging from the tie-beam.
	draw_line(Vector2(w*.70,h*.12),Vector2(w*.70,h*.62),_c("b89a6a","8a7250"),2.0,true)
	draw_circle(Vector2(w*.70,h*.63),4.0,_c("b8342a","8a2a22"))
	# The horseshoe council table in red cloth, the charter on its lectern.
	var cloth:=_c("8a2a2a","5a1c1c")
	draw_rect(Rect2(w*.30,h*.66,w*.40,h*.03),cloth)
	_quad(Vector2(w*.30,h*.66),Vector2(w*.33,h*.66),Vector2(w*.24,h*.84),Vector2(w*.19,h*.84),cloth.darkened(.1))
	_quad(Vector2(w*.70,h*.66),Vector2(w*.67,h*.66),Vector2(w*.76,h*.84),Vector2(w*.81,h*.84),cloth.darkened(.1))
	var lectern:=Vector2(w*.5,h*.70)
	draw_line(lectern,lectern+Vector2(0,h*.06),_c("5a4028","8a6a44"),3.0)
	draw_colored_polygon(PackedVector2Array([lectern+Vector2(-h*.05,-h*.01),lectern+Vector2(h*.05,-h*.01),lectern+Vector2(h*.04,h*.02),lectern+Vector2(-h*.04,h*.02)]),_c("efe2c2","c8b890"))
	draw_circle(lectern+Vector2(0,h*.03),h*.01,_c("a82a22","8a2018"))
	_crowd_on_benches(w,h)

func _dress_estates(w:float,h:float)->void:
	var back:=Rect2(w*.28,h*.18,w*.44,h*.48)
	# The rose window: coloured light through stone tracery.
	var centre:=Vector2(w*.5,back.position.y+back.size.y*.26)
	var r:=back.size.x*.11
	var glass:=[_c("3a5aa8","24407a"),_c("b8342a","8a2a22"),_c("e0b848","a8862a"),_c("3a7a5a","285a40")]
	for i in 16:
		var a0:=TAU*float(i)/16.0;var a1:=TAU*float(i+1)/16.0
		draw_colored_polygon(PackedVector2Array([centre,centre+Vector2(cos(a0),sin(a0))*r,centre+Vector2(cos(a1),sin(a1))*r]),Color(glass[i%4],.72))
	draw_arc(centre,r*.62,0,TAU,32,_c("5a5246","2a2620"),2.0,true)
	draw_circle(centre,r*.3,_c("f2e6b8","d8c07a"))
	for i in 16:
		var a:=TAU*float(i)/16.0
		draw_line(centre,centre+Vector2(cos(a),sin(a))*r,_c("5a5246","2a2620"),2.0,true)
	draw_arc(centre,r,0,TAU,36,_c("5a5246","2a2620"),4.0,true)
	_light_shaft(centre+Vector2(-r*.6,0),centre+Vector2(r*.6,0),Vector2(w*.62,h*.96),Vector2(w*.40,h*.96))
	# A canopy of state over the high seat.
	var canopy:=Rect2(w*.44,back.end.y-h*.26,w*.12,h*.05)
	draw_rect(canopy,Color(banner,.95))
	for k in 7:
		var x:=canopy.position.x+canopy.size.x*float(k)/6.0
		draw_line(Vector2(x,canopy.end.y),Vector2(x,canopy.end.y+h*.012),_c("e8c35a","c9a24a"),2.0)
	draw_colored_polygon(PackedVector2Array([canopy.position+Vector2(0,canopy.size.y),canopy.position+Vector2(canopy.size.x,canopy.size.y),Vector2(canopy.end.x-w*.01,back.end.y-h*.04),Vector2(canopy.position.x+w*.01,back.end.y-h*.04)]),Color(banner.darkened(.25),.55))
	# The banners of chartered towns along both walls.
	var towns:=[_c("2e5a8a","24466a"),_c("c9a24a","9a7a34"),_c("8a2a2a","6a2020"),_c("3a6a3a","2a502a"),_c("e8dcc0","a89878")]
	for k in 5:
		var d:=float(k)/5.0
		for side:float in [-1.0,1.0]:
			var x:=w*.5+side*lerpf(w*.44,back.size.x*.52,d)
			var y:=lerpf(h*.20,back.position.y+h*.02,d)
			var bw:=lerpf(w*.035,w*.014,d);var bh:=lerpf(h*.22,h*.10,d)
			var paint:Color=towns[(k+int(side>0.0)*2)%towns.size()]
			draw_colored_polygon(PackedVector2Array([Vector2(x-bw*.5,y),Vector2(x+bw*.5,y),Vector2(x+bw*.5,y+bh),Vector2(x,y+bh*.82),Vector2(x-bw*.5,y+bh)]),paint)
	# Three banks of benches for the three estates.
	for bank in 3:
		var seat:=_c("6a4a2c","2a1e14")
		if bank==0:
			_quad(Vector2(w*.06,h*.74),Vector2(w*.24,h*.66),Vector2(w*.26,h*.69),Vector2(w*.08,h*.79),seat)
		elif bank==1:
			_quad(Vector2(w*.94,h*.74),Vector2(w*.76,h*.66),Vector2(w*.74,h*.69),Vector2(w*.92,h*.79),seat)
		else:
			draw_rect(Rect2(w*.34,h*.665,w*.32,h*.02),seat)
	_crowd_on_benches(w,h)

# --- The assembly place: stepped tiers under the sky --------------------------

func _draw_assembly(w:float,h:float)->void:
	_gradient(Rect2(0,0,w,h*.40),_c("a9c4d6","141c30"),_c("ece6d4","3a3a4c"))
	if dark:
		var stars:=_rng(81)
		for i in 50:
			draw_circle(Vector2(stars.randf()*w,stars.randf()*h*.30),stars.randf_range(.6,1.3),Color(1,.96,.86,stars.randf_range(.3,.7)))
	else:
		draw_circle(Vector2(w*.16,h*.12),h*.05,Color(1,.97,.86,.8))
		for i in 3:draw_circle(Vector2(w*.16,h*.12),h*(.09+.04*i),Color(1,.95,.8,.08))
	# Hills, and the town climbing to its shrine on the height.
	_hills(w,h*.36,h*.08,_c("a8b08e","2a3034"),2.3)
	var hill:=PackedVector2Array([Vector2(w*.62,h*.40),Vector2(w*.74,h*.20),Vector2(w*.86,h*.18),Vector2(w*.98,h*.40)])
	draw_colored_polygon(hill,_c("b8a47e","35302a"))
	var town:=_rng(82)
	for i in 12:
		var x:=w*town.randf_range(.66,.95);var y:=h*town.randf_range(.26,.37)
		var bw:=h*town.randf_range(.025,.045)
		draw_rect(Rect2(x,y,bw,bw*.7),_c("ebe0c8","5a544a"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-2,y),Vector2(x+bw*.5,y-bw*.3),Vector2(x+bw+2,y)]),_c("b0603a","6a3a24"))
	var shrine:=Rect2(w*.76,h*.13,w*.08,h*.05)
	draw_rect(Rect2(shrine.position.x-4,shrine.end.y,shrine.size.x+8,4),_c("f2ead6","7a746a"))
	for k in 6:
		var x:=shrine.position.x+shrine.size.x*float(k)/5.0
		draw_line(Vector2(x,shrine.position.y),Vector2(x,shrine.end.y),_c("f6f0e0","8a847a"),2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(shrine.position.x-4,shrine.position.y),Vector2(shrine.get_center().x,shrine.position.y-h*.03),Vector2(shrine.end.x+4,shrine.position.y)]),_c("f2ead6","7a746a"))
	# A colonnade at the left edge of the square.
	draw_rect(Rect2(0,h*.30,w*.20,h*.02),_c("e8dcc4","4a4640"))
	for k in 7:
		var x:=w*(.01+.03*k)
		draw_rect(Rect2(x,h*.32,w*.008,h*.12),_c("f2e8d2","56524a"))
	# The tiers, from the highest and farthest row down to the floor.
	var centre:=Vector2(w*.5,h*.80)
	var rows:=7
	for i in range(rows,-1,-1):
		var radii:=Vector2(w*(.30+.055*float(i)),h*(.12+.052*float(i)))
		var tone:=_c("d8ccb0","4a453c") if i%2==0 else _c("c2b494","3c3830")
		if i==0: tone=_c("b8a078","2e2820")
		draw_colored_polygon(_half_ellipse(centre,radii,40),tone)
		draw_polyline(_arc_points(centre,radii,40),Color(_c("9a8c70","24211c"),.8),1.2,true)
	# Citizens on the tiers, fewer and smaller toward the top.
	var crowd:=_rng(83)
	var citizens:=_role_count("citizen")*2
	for n in citizens:
		var row:=1+n%(rows-1)
		var radii:=Vector2(w*(.30+.055*float(row)),h*(.12+.052*float(row)))
		var a:=PI+crowd.randf_range(.12,.88)*PI
		var foot:=centre+Vector2(cos(a)*radii.x,sin(a)*radii.y)+Vector2(0,h*.035)
		_figure(foot,h*(.075-.004*float(row)),_robe(crowd.randi()%5,"citizen"),"sit","")
	# The speakers' platform, the water-clock and the voting urns.
	var bema:=Rect2(w*.45,h*.60,w*.10,h*.06)
	draw_rect(bema,_c("e6dcc4","4e4a42"))
	draw_rect(Rect2(bema.position.x,bema.position.y,bema.size.x,3),_c("f6efdc","6a665c"))
	for k in 2:
		draw_rect(Rect2(bema.position.x-w*.01*(k+1),bema.end.y+h*.012*k,bema.size.x+w*.02*(k+1),h*.012),_c("d8ccb0","454038").darkened(.05*k))
	var clock:=Vector2(w*.585,h*.63)
	draw_line(clock,clock+Vector2(0,h*.05),_c("6a5a44","8a7a60"),2.0)
	draw_colored_polygon(_ellipse(clock,Vector2(h*.02,h*.015),12),_c("b0643a","8a4a2a"))
	for x:float in [w*.36,w*.64]:
		var urn:=Vector2(x,h*.70)
		draw_colored_polygon(_ellipse(urn,Vector2(h*.022,h*.032),14),_c("a8542e","8a4424"))
		draw_rect(Rect2(urn.x-h*.01,urn.y-h*.045,h*.02,h*.014),_c("8a4424","6a3418"))
		draw_line(urn+Vector2(-h*.022,-h*.01),urn+Vector2(h*.022,-h*.01),_c("1a1410","e8dcc0"),1.5)
	_before_fire(w,h)
	# An altar at the opening of the session, its small fire for the god.
	draw_rect(Rect2(hearth_point().x-h*.06,hearth_point().y-h*.01,h*.12,h*.05),_c("e6dcc4","4e4a42"))
	_fire(hearth_point()+Vector2(0,-h*.01),h*.08)

# --- The council house: tiered benches, the magistrates' chairs, bronze doors -

func _draw_council_house(w:float,h:float)->void:
	var back:=Rect2(w*.32,h*.14,w*.36,h*.50)
	var marble:=_c("e6dcc8","3a3530")
	_gradient(Rect2(0,0,w,h),_c("e4dccb","2a2622"),_c("f0e8d8","3a342e"))
	_quad(Vector2(0,0),back.position,Vector2(back.position.x,back.end.y),Vector2(0,h),marble.darkened(.04))
	_quad(Vector2(w,0),Vector2(back.end.x,back.position.y),back.end,Vector2(w,h),marble.darkened(.08))
	draw_rect(back,marble)
	# Coffered ceiling.
	draw_rect(Rect2(0,0,w,h*.08),_c("c9bca2","241f1a"))
	for k in 9:
		var x:=w*float(k)/8.0
		draw_line(Vector2(x,0),Vector2(lerpf(x,w*.5,.35),h*.08),Color(_c("a89c82","14110e"),.9),2.0)
	# Pilasters on the back wall.
	for k in 5:
		var x:=back.position.x+back.size.x*float(k)/4.0
		draw_rect(Rect2(x-3,back.position.y,6,back.size.y),_c("d6cab2","2e2a26"))
	# The bronze doors open to the daylight of the square.
	var door:=Rect2(w*.45,back.position.y+back.size.y*.30,w*.10,back.size.y*.70)
	draw_rect(door,_c("fbf3dc","d8c48a"))
	_radial(door.get_center(),door.size,Color(1,.97,.85,.30),Color(1,.97,.85,0))
	for side:float in [-1.0,1.0]:
		var hinge:=door.position.x if side<0.0 else door.end.x
		draw_colored_polygon(PackedVector2Array([Vector2(hinge,door.position.y),Vector2(hinge+side*w*.035,door.position.y+h*.02),Vector2(hinge+side*w*.035,door.end.y+h*.01),Vector2(hinge,door.end.y)]),_c("8a6a3a","6a4a24"))
		for k in 3:
			var y:=lerpf(door.position.y,door.end.y,.2+.3*k)
			draw_circle(Vector2(hinge+side*w*.018,y+h*.01),2.5,_c("c9a24a","b08a3a"))
	# The inlaid marble floor, a porphyry disc at the centre.
	_quad(Vector2(0,h),Vector2(back.position.x,back.end.y),back.end,Vector2(w,h),_c("d8ccb4","2e2a24"))
	for i in 6:
		var t0:=pow(float(i)/6.0,1.4);var t1:=pow(float(i+1)/6.0,1.4)
		for j in 8:
			if (i+j)%2==1: continue
			var u0:=float(j)/8.0;var u1:=float(j+1)/8.0
			var y0:=lerpf(back.end.y,h,t0);var y1:=lerpf(back.end.y,h,t1)
			var a:=Vector2(lerpf(lerpf(back.position.x,0,t0),lerpf(back.end.x,w,t0),u0),y0)
			var b:=Vector2(lerpf(lerpf(back.position.x,0,t0),lerpf(back.end.x,w,t0),u1),y0)
			var c:=Vector2(lerpf(lerpf(back.position.x,0,t1),lerpf(back.end.x,w,t1),u1),y1)
			var d:=Vector2(lerpf(lerpf(back.position.x,0,t1),lerpf(back.end.x,w,t1),u0),y1)
			_quad(a,b,c,d,_c("b89a78","4a3a2c"))
	draw_colored_polygon(_ellipse(Vector2(w*.5,h*.80),Vector2(w*.09,h*.035),24),Color(banner,.8))
	# Tiered benches down both sides, councillors seated on them.
	for side:float in [-1.0,1.0]:
		for tier_index in range(2,-1,-1):
			var lift:=float(tier_index)*h*.07
			var near_x:=w*.5+side*(w*.50-float(tier_index)*w*.035)
			var far_x:=w*.5+side*(back.size.x*.5-float(tier_index)*w*.004)
			var near_y:=h*.86-lift;var far_y:=back.end.y-lift*.35
			var inner:=w*.13
			var top:=PackedVector2Array([Vector2(near_x,near_y),Vector2(far_x,far_y),Vector2(far_x-side*w*.02,far_y+h*.012),Vector2(near_x-side*inner,near_y+h*.03)])
			draw_colored_polygon(top,_c("e8dcc4","6a6254").darkened(.06*tier_index))
			var riser:=PackedVector2Array([top[3],top[2],top[2]+Vector2(0,h*.03),top[3]+Vector2(0,h*.06)])
			draw_colored_polygon(riser,_c("9a8a6c","2a2620"))
			draw_line(top[3],top[2],_c("7a6c54","1a1714"),1.5,true)
	_crowd_on_benches(w,h)
	# The presiding magistrates' folding chairs on a low platform.
	var dais:=Rect2(w*.42,back.end.y-h*.03,w*.16,h*.03)
	draw_rect(dais,_c("cfc2a6","3e3832"))
	for x:float in [w*.465,w*.535]:
		var seat_y:=dais.position.y-h*.05
		draw_line(Vector2(x-h*.025,dais.position.y),Vector2(x+h*.025,seat_y),_c("c9a24a","9a7a34"),2.5,true)
		draw_line(Vector2(x+h*.025,dais.position.y),Vector2(x-h*.025,seat_y),_c("c9a24a","9a7a34"),2.5,true)
		draw_rect(Rect2(x-h*.03,seat_y-h*.008,h*.06,h*.01),_c("e8dcc0","8a8068"))
	_before_fire(w,h)
	draw_rect(Rect2(hearth_point().x-h*.05,hearth_point().y-h*.01,h*.10,h*.045),_c("efe6d2","4e4a42"))
	_fire(hearth_point()+Vector2(0,-h*.01),h*.07)

# ---------------------------------------------------------------- people

const SKIN:=["d9ad84","b98560","8d5a3c","e6c4a2","a6734e","6e4630"]

func _role_count(role:String)->int:
	var total:=0
	for entry_variant in attendants:
		var entry:Dictionary=entry_variant
		if String(entry.get("role",""))==role: total+=int(entry.get("count",0))
	return total

func _robe(index:int,role:String)->Color:
	match role:
		"guard": return _c("5a4a3a","3a3026").lerp(banner,.25)
		"herald": return banner.lightened(.1)
		"scribe": return _c("e8dcc0","8a806a")
		"priest": return _c("f2ead6","a89e88") if index%2==0 else _c("d8a040","9a7430")
		"minister": return banner.lerp(_c("2a2a4a","1a1a30"),.35) if index%2==0 else _c("c9a24a","8a6a30")
		"elder": return _c("9a7a58","5a4632")
		"petitioner": return _c("b8a484","6a5c48").lerp(_c("8a7a5a","4a4032"),float(index%3)/3.0)
		"senator": return _c("f2ead8","9a9280")
		"delegate":
			return [_c("3a3a44","24242c"),_c("8a2a2a","5a1c1c"),_c("2e4a7a","1e3456")][index%3]
	var palette:=[_c("c9b28a","6a5c46"),_c("a8603a","6a3c24"),_c("6a8aa0","3a4a58"),_c("e2d6bc","8a806c"),_c("8a9a5a","4a5432")]
	return palette[index%palette.size()]

func _figure(foot:Vector2,height:float,robe:Color,pose:String="stand",prop:String="",skin_index:int=0)->void:
	## One painted person: a robe, a head, what they carry.
	var kneel:=pose=="kneel"
	var sit:=pose=="sit"
	var body:=height*(.52 if kneel else .56 if sit else .80)
	var head_r:=height*.085
	var lean:=height*.12 if kneel else 0.0
	var shoulder:=foot+Vector2(lean,-body)
	var half_base:=height*(.24 if kneel else .19 if sit else .17)
	var half_top:=height*.10
	draw_colored_polygon(_ellipse(foot+Vector2(0,1),Vector2(half_base*1.2,height*.04),10),Color(0,0,0,.14 if not dark else .3))
	draw_colored_polygon(PackedVector2Array([foot+Vector2(-half_base,0),shoulder+Vector2(-half_top,0),shoulder+Vector2(half_top,0),foot+Vector2(half_base,0)]),robe)
	draw_line(shoulder+Vector2(-half_top*.4,height*.02),foot+Vector2(-half_base*.45,0),Color(robe.lightened(.18),.7),maxf(1.0,height*.02),true)
	var head:=shoulder+Vector2(lean*.4,-head_r*.95)
	draw_circle(head,head_r,Color(String(SKIN[skin_index%SKIN.size()])).darkened(.25 if dark else 0.0))
	match prop:
		"spear":
			var x:=foot.x+half_base*1.15
			draw_line(Vector2(x,foot.y),Vector2(x,foot.y-height*1.28),_c("4a3a28","b8a07a"),maxf(1.0,height*.025),true)
			draw_colored_polygon(PackedVector2Array([Vector2(x-height*.03,foot.y-height*1.26),Vector2(x,foot.y-height*1.42),Vector2(x+height*.03,foot.y-height*1.26)]),_c("8a8a88","c8c8c4"))
		"staff","rod":
			var x:=foot.x-half_base*1.1
			var top:=height*(1.12 if prop=="staff" else .9)
			draw_line(Vector2(x,foot.y),Vector2(x,foot.y-top),_c("5a4228","c8a878"),maxf(1.0,height*.025),true)
			draw_circle(Vector2(x,foot.y-top),height*.035,_c("c9a24a","e8c35a") if prop=="staff" else _c("5a4228","c8a878"))
		"tablet":
			draw_rect(Rect2(shoulder.x-half_top*.2,shoulder.y+body*.30,height*.16,height*.11),_c("c49a6a","8a6a46"))
		"scroll":
			draw_rect(Rect2(shoulder.x-half_top*.3,shoulder.y+body*.32,height*.20,height*.06),_c("efe2c2","c8b890"))
		"tall_hat":
			draw_colored_polygon(PackedVector2Array([head+Vector2(-head_r*.8,-head_r*.6),head+Vector2(-head_r*.5,-head_r*2.4),head+Vector2(head_r*.5,-head_r*2.4),head+Vector2(head_r*.8,-head_r*.6)]),Color(robe.lightened(.1),1.0))
		"stole":
			draw_line(shoulder+Vector2(half_top*.3,0),foot+Vector2(half_base*.25,0),_c("e8c35a","c9a24a"),maxf(1.5,height*.035),true)
		"bough":
			var hand:=shoulder+Vector2(half_top*1.4,body*.3)
			draw_line(hand,hand+Vector2(height*.12,-height*.16),_c("5a6a32","7a8a4a"),1.5,true)
			for k in 3:draw_circle(hand+Vector2(height*.04*float(k+1),-height*.055*float(k+1)),height*.025,_c("7a8a42","8a9a52"))
		"gift":
			draw_colored_polygon(_ellipse(shoulder+Vector2(half_top*1.6,body*.45),Vector2(height*.08,height*.05),10),_c("c9a26a","8a6e44"))

func _attendant_spot(role:String,index:int)->Vector3:
	## (x fraction, y fraction, pose code) for one attendant; pose 0 stand,
	## 1 kneel, 2 sit.
	var rank:=float(floori(index/2.0))
	var side:=-1.0 if index%2==0 else 1.0
	match role:
		"guard": return Vector3(.5+side*(.15+.07*rank),.64+.02*rank,0)
		"herald": return Vector3(.37-.05*float(index),.69,0)
		"scribe": return Vector3(.11+.055*float(index),.77+.012*float(index%2),2)
		"priest": return Vector3(.66+.05*float(index),.68,0)
		"minister": return Vector3(.5+side*(.21+.06*rank),.66,0)
		"elder": return Vector3(.5+side*(.27+.05*rank),.67,0)
		"petitioner": return Vector3(minf(.95,.79+.045*float(index)),.85-.01*float(index%2),1)
	return Vector3(.5,.7,0)

func _draw_attendants(w:float,h:float)->void:
	## Everyone the form of court places here besides those summoned.
	var rank:=int(Stages.stage(stage_id).get("rank",0))
	var skin:=_rng(71)
	for entry_variant in attendants:
		var entry:Dictionary=entry_variant
		var role:=String(entry.get("role",""))
		if role in ["citizen","senator","delegate"]: continue
		for index in int(entry.get("count",0)):
			var spot:=_attendant_spot(role,index)
			var pose:="kneel" if int(spot.z)==1 else "sit" if int(spot.z)==2 else "stand"
			var prop:=""
			match role:
				"guard": prop="spear"
				"herald": prop="staff" if rank<8 else "rod"
				"scribe": prop="tablet" if rank<5 else "scroll"
				"priest": prop="tall_hat"
				"minister": prop="stole"
				"elder": prop="staff"
				"petitioner": prop="bough" if rank in [5,7] else "scroll" if rank>=4 else "gift"
			_figure(Vector2(w*spot.x,h*spot.y),h*.17,_robe(index,role),pose,prop,skin.randi())

func _crowd_on_benches(w:float,h:float)->void:
	## Councillors and deputies seated along the benches of their scene.
	var rng:=_rng(91)
	if scene=="council_house":
		var count:=_role_count("senator")
		for n in count:
			var side:=-1.0 if n%2==0 else 1.0
			var tier_index:=floori(n/2.0)%3
			var t:=rng.randf_range(.15,.85)
			var lift:=float(tier_index)*h*.07
			var near:=Vector2(w*.5+side*(w*.50-float(tier_index)*w*.035)-side*w*.07,h*.86-lift)
			var far:=Vector2(w*.5+side*(w*.18-float(tier_index)*w*.004),h*.64-lift*.35)
			var foot:=near.lerp(far,t)
			_figure(foot,h*lerpf(.16,.09,t),_robe(n,"senator"),"sit","stole" if n%4==0 else "",rng.randi())
	elif scene=="commune_hall":
		var count:=_role_count("delegate")
		for n in count:
			var t:=float(n)/float(maxi(1,count-1))
			var foot:=Vector2.ZERO
			if t<.3: foot=Vector2(w*.19,h*.85).lerp(Vector2(w*.29,h*.665),t/.3)
			elif t>.7: foot=Vector2(w*.71,h*.665).lerp(Vector2(w*.81,h*.85),(t-.7)/.3)
			else: foot=Vector2(lerpf(w*.32,w*.68,(t-.3)/.4),h*.655)
			if absf(foot.x-w*.5)<w*.04 and foot.y<h*.7: foot.x+=w*.06
			_figure(foot,h*lerpf(.08,.12,absf(t-.5)*2.0),_robe(n,"delegate") if n%3!=0 else _robe(n,"citizen"),"sit","",rng.randi())
	elif scene=="estates_hall":
		var count:=_role_count("delegate")
		for n in count:
			var bank:=n%3
			var t:=rng.randf_range(.1,.9)
			var foot:=Vector2.ZERO
			match bank:
				0: foot=Vector2(w*.07,h*.765).lerp(Vector2(w*.25,h*.675),t)
				1: foot=Vector2(w*.93,h*.765).lerp(Vector2(w*.75,h*.675),t)
				_: foot=Vector2(lerpf(w*.35,w*.65,t),h*.67)
			_figure(foot,h*(.12 if bank<2 else .09),_robe(bank,"delegate"),"sit","",rng.randi())

func _half_ellipse(centre:Vector2,radii:Vector2,segments:int)->PackedVector2Array:
	## The upper half of an ellipse, closed along its diameter.
	var points:=_arc_points(centre,radii,segments)
	points.append(centre+Vector2(radii.x,radii.y*.6))
	points.append(centre+Vector2(-radii.x,radii.y*.6))
	return points

func _arc_points(centre:Vector2,radii:Vector2,segments:int)->PackedVector2Array:
	var points:=PackedVector2Array()
	for i in segments+1:
		var a:=PI+PI*float(i)/float(segments)
		points.append(centre+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	return points
