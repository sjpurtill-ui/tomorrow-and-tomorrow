extends Control
## The court's setting, drawn in the game's paper-and-gouache manner. It grows
## with what the people know: an open-air ring of logs and hides around a fire
## (tier 0), a thatched longhouse (1), a timber and mudbrick hall with woven
## hangings (2), a stone hall of columns and banners (3), a high palace (4).
## Presentation only. A painted plate at assets/ui/court/court-tier-N.png, when
## present, replaces the drawing for that tier.

const Voice:=preload("res://scripts/character_voice.gd")
const OVERRIDE_PATH:="res://assets/ui/court/court-tier-%d.png"
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

static func place_name(t:int)->String:
	return String(PLACE_NAMES[clampi(t,0,MAX_TIER)])

static func place_line(t:int)->String:
	return String(PLACE_LINES[clampi(t,0,MAX_TIER)])

static func override_texture(t:int)->Texture2D:
	## A painted plate for this tier, if one has been added to the project.
	var path:=OVERRIDE_PATH % clampi(t,0,MAX_TIER)
	if ResourceLoader.exists(path):
		var loaded:Resource=load(path)
		if loaded is Texture2D: return loaded as Texture2D
	if FileAccess.file_exists(path):
		var image:=Image.load_from_file(ProjectSettings.globalize_path(path))
		if image!=null and not image.is_empty(): return ImageTexture.create_from_image(image)
	return null

func configure(t:int,dark_mode:bool)->void:
	tier=clampi(t,0,MAX_TIER)
	dark=dark_mode
	_texture=override_texture(tier)
	queue_redraw()

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
	match tier:
		0: _draw_fire_circle(w,eh)
		1: _draw_longhouse(w,eh)
		2: _draw_timber_hall(w,eh)
		3: _draw_stone_hall(w,eh,false)
		_: _draw_stone_hall(w,eh,true)
	if dark: _firelight(w,eh)
	draw_set_transform(Vector2.ZERO)
	_grain(w,h)
	_vignette(w,h)

func _top_colour()->Color:
	match tier:
		0: return _c("d8c6a2","151b28")
		1: return _c("8c7152","1b1511")
		2: return _c("4f3620","140e09")
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
	_fire(hearth_point(),h*.20)

func _bundle(at:Vector2,size_px:float,variant:int)->void:
	## A rolled hide tied with cord.
	var hide:=_c("b58e60","5a4430") if variant==0 else _c("a07a52","4e3a28")
	draw_colored_polygon(_ellipse(at,Vector2(size_px*1.4,size_px*.55),18),hide)
	draw_colored_polygon(_ellipse(at+Vector2(size_px*1.2,0),Vector2(size_px*.25,size_px*.5),12),hide.lightened(.15))
	draw_arc(at+Vector2(size_px*1.2,0),size_px*.14,0,TAU,12,hide.darkened(.3),1.2,true)
	for x in [-.5,.4]:draw_line(at+Vector2(size_px*x,-size_px*.55),at+Vector2(size_px*x,size_px*.55),_c("5d452d","2c2118"),1.5,true)

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
		for x in [lx,rx]:
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
		for x in [lx,rx]:
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
	# Braziers either side of the dais.
	for side in [-1.0,1.0]:
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
	rng.seed=hash("court:%d:%d" % [tier,salt])
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
