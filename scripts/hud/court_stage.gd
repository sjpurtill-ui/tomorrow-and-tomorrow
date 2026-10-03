extends Control
## The court as a stage: the people present stand in the hall as painted
## figures, and what is said pops up above the one who says it.
## Presentation only. Nothing here decides anything: the hall
## (audience_hall.gd) and the court's engines decide, and the Court
## (audience_modal.gd) hands each line that was said to this stage.
##  - Figures: each person's painting (person_portrait.gd art, read through
##    figure_picture() alone) in a soft arched vignette, standing on the hall
##    floor. They breathe, turn a little toward whoever speaks, step forward
##    to speak, walk in when summoned and walk out when they take their leave.
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
## A figure's width for its height: a standing person, not the whole painting.
const FIGURE_ASPECT:=0.60

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

## A small picture of a person (rosters, the history, the envoy channel),
## read through the same seam as the figures.
static func picture_rect(person:Dictionary,screen_registry:Dictionary,width:float,height:float)->TextureRect:
	var picture:=figure_picture(person,screen_registry)
	var image:=TextureRect.new();image.name="Portrait";image.texture=picture.texture;image.flip_h=bool(picture.flip)
	image.custom_minimum_size=Vector2(width,height);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.tooltip_text=String(person.get("name",""));image.set_meta("person_id",int(person.get("person_id",0)))
	image.set_meta("figure_slot",picture.slot)
	return image

## A standing figure on its own (the court at rest seats them about the fire).
static func make_figure(person:Dictionary,screen_registry:Dictionary,name_text:String="",title_text:String="",big:=false)->Figure:
	var made:=Figure.new()
	made.person=person
	var picture:=figure_picture(person,screen_registry)
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
	figure_layer=_layer("Figures");god_layer=_layer("FromAbove");bubble_layer=_layer("Bubbles");caption_layer=_layer("Captions")
	resized.connect(_on_resized)

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
	var tip:=name_text if title_text.is_empty() else "%s · %s" % [name_text,title_text]
	f.tooltip_text=tip if not tip.is_empty() else String(person.get("name",""))
	figure_layer.add_child(f)
	figures[key]=f;cast_order.append(key)
	if enter:_arrivals.append(key)
	if _laid_out:
		layout(true)
		_run_arrivals()
	return f

## They walk in from the side (the threshold) once the stage has a size.
func arrive(keys:Array)->void:
	for key in keys:
		if has_figure(String(key)) and not String(key) in _arrivals:_arrivals.append(String(key))
	if _laid_out:_run_arrivals()

func _run_arrivals()->void:
	var index:=0
	for key in _arrivals:
		var f:=figure(key)
		if f==null:continue
		var side:=-1.0 if f.home.x<size.x*.6 else 1.0
		f.enter_from(side,maxf(size.x*.35,f.size.x*1.6),index*0.18)
		index+=1
	_arrivals.clear()

## The one before the god takes their leave (the audience is concluded);
## those who came with them follow. style says how they go:
##  "bow"   a small bow, then out the way they came;
##  "storm" no bow, out briskly (an insulted guest);
##  "led"   no bow, darkened, taken out quickly (cast out, seized, maimed);
##  "fall"  put to death: they sink and are gone where they stood;
##  "stay"  nobody leaves.
func conclude(delay:float=1.4,style:="bow")->void:
	if style=="stay":return
	var index:=0
	for key in cast_order.duplicate():
		var f:=figure(key)
		if f==null or f.leaving or not f.role in [MAIN,"attendant"]:continue
		# Their company is not struck down with them: they are sent away.
		var own:=style if f.role==MAIN or style!="fall" else "led"
		f.leave(-1.0,maxf(size.x*.4,f.size.x*2.0),delay+index*0.2,own)
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
	var room:=maxf(h-top_inset,60.0)
	var main_h:=clampf(room*(.78 if layout_kind=="home" else .74),70.0,600.0)
	var court_h:=main_h*.74
	var front:=h-6.0
	var back:=h-room*.07
	var usable:=_usable_width()
	var slots:Array=HOME_COURT_X if layout_kind=="home" else ENVOY_COURT_X
	var court_index:=0;var attendant_index:=0
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
			_:
				var row:=court_index/slots.size()
				x=float(slots[court_index%slots.size()])*(w if layout_kind=="home" else usable)
				# A court too large for the slots stands further back, between
				# the ones in front.
				if row>0:
					fh*=pow(.86,row);foot-=room*.04*row
					x+=(.06 if layout_kind=="home" else .05)*usable*(1.0 if row%2==1 else -1.0)
				court_index+=1
		var fw:=fh*FIGURE_ASPECT
		x=clampf(x,fw*.5+4.0,maxf(fw*.5+4.0,usable-fw*.5-4.0))
		f.place(Vector2(x,foot),Vector2(fw,fh),animate)
	# The nearer stand in front of the further.
	var ordered:Array=figure_layer.get_children()
	ordered.sort_custom(func(a:Node,b:Node)->bool:return (a as Figure).home.y<(b as Figure).home.y if absf((a as Figure).home.y-(b as Figure).home.y)>.5 else (a as Figure).size.y<(b as Figure).size.y)
	for index in ordered.size():figure_layer.move_child(ordered[index],index)

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
	_turn_to(key)
	if animate:bubble.pop_in()
	return bubble.label

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
	if animate:
		_god.descend()
		_rays.modulate.a=0.0
		_rays.create_tween().tween_property(_rays,"modulate:a",1.0,Motion.duration(Motion.SLOW))
	return _god.label

## What the engine decided, or what happens in the hall: a caption at the
## foot of the stage. kind: "narration", "direction", "receipt" or "warn".
func caption(text:String,kind:="narration",animate:=true,ref:=-1,kicker:="")->Label:
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
	if animate:_caption.rise_in()
	return _caption.label

## Everything shown at once (a test, or the player skipping ahead): no tween
## left half-way, nothing fading still on the stage.
func settle()->void:
	for key in cast_order:
		var f:=figure(key)
		if f!=null:f.finish_moves()
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

func _turn_to(key:String)->void:
	var speaker:=figure(key)
	if speaker==null:return
	for other_key in cast_order:
		var f:=figure(other_key)
		if f==null or f.leaving:continue
		if other_key==key:f.speak()
		else:f.listen_toward(speaker.home.x)

func _age_bubbles(fresh:Bubble,animate:bool)->void:
	## The line before stays faintly; the one before that goes, and so does
	## anything the new bubble would cover.
	var rect:=fresh.get_rect()
	for child in bubble_layer.get_children():
		var old:=child as Bubble
		if old==null or old==fresh or old.dropping:continue
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
	## Just over the head: the paintings put faces in their upper part.
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
		# No room above: beside the head, toward the middle of the stage.
		var face:=Vector2(head.x,f.home.y-f.size.y*.80)
		var to_right:=face.x<right*.5
		var reach:=f.size.x*.30
		var x:=face.x+reach+TAIL if to_right else face.x-reach-TAIL-bs.x
		x=clampf(x,8.0,maxf(8.0,right-bs.x-8.0))
		var y:=clampf(face.y-bs.y*.5,top_min,maxf(top_min,h-bs.y-8.0))
		bubble.position=Vector2(x,y)
		bubble.tail_side="left" if to_right else "right"
		bubble.tip=Vector2(face.x+reach-x,face.y-y) if to_right else Vector2(face.x-reach-x,face.y-y)
		# A bubble pushed back over its speaker has no side to point from.
		if (to_right and bubble.tip.x>-4.0) or (not to_right and bubble.tip.x<bs.x+4.0):bubble.tail_side="none"
	bubble.pivot_offset=bubble.tip.clamp(Vector2.ZERO,bs)
	bubble.home_y=0.0
	bubble.queue_redraw()

func _place_god()->void:
	if not is_instance_valid(_god):return
	_god.position=Vector2(((_usable_width()-_god.size.x)*.5),top_inset+10.0).round()
	_god.home_y=_god.position.y
	if is_instance_valid(_rays):
		_rays.target=Rect2(_god.position,_god.size);_rays.queue_redraw()

func _place_caption()->void:
	## Low on the stage like a line under a picture, but above the name plates.
	if not is_instance_valid(_caption):return
	_caption.position=Vector2((_usable_width()-_caption.size.x)*.5,maxf(top_inset+6.0,size.y-_caption.size.y-PLATE_ROOM)).round()
	_caption.home_y=_caption.position.y

func _place_thinking()->void:
	if not is_instance_valid(thinking) or not thinking.visible:return
	var f:=figure(MAIN)
	if f==null or f.leaving:
		thinking.position=Vector2((_usable_width()-thinking.size.x)*.5,size.y-thinking.size.y-12.0).round();return
	# Beside their face, so it never sits on the words they just said.
	var face:=Vector2(f.home.x+f.size.x*.36,f.home.y-f.size.y*.80)
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
		set(value):base_pos=value;position=base_pos+Vector2(walk,0.0)
	var walk:=0.0:
		set(value):walk=value;position=base_pos+Vector2(walk,0.0)
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
		plate.position=Vector2((size.x-plate.size.x)*.5,size.y-plate.size.y-2.0).round()

	func _draw()->void:
		if _shadow.size()>2:draw_colored_polygon(_shadow,Color(0,0,0,.30))

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

	func start_idle()->void:
		## Breathing and a slow sway, a little different for each.
		if Motion.reduced() or not is_inside_tree():return
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
	## gesture on the first words.
	func speak()->void:
		if leaving:return
		_pose(0.0,0.0,1.035,Color(1.07,1.05,1.0))
		if not is_inside_tree() or Motion.reduced():return
		if _bob and _bob.is_valid():_bob.kill()
		_bob=create_tween().set_trans(Tween.TRANS_SINE)
		_bob.tween_property(rig,"position:y",-7.0,.16).set_ease(Tween.EASE_OUT)
		_bob.tween_property(rig,"position:y",0.0,.22).set_ease(Tween.EASE_IN_OUT)
		_bob.tween_property(rig,"position:y",-3.0,.14).set_ease(Tween.EASE_OUT)
		_bob.tween_property(rig,"position:y",0.0,.18).set_ease(Tween.EASE_IN_OUT)

	## Someone else speaks: they turn a little toward them and listen.
	func listen_toward(x:float)->void:
		if leaving:return
		var side:=signf(x-home.x)
		_pose(deg_to_rad(1.6)*side,4.0*side,1.0,Color(.90,.89,.87))

	## The god speaks: every face lifts toward the voice.
	func look_up()->void:
		if leaving:return
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
		if not is_inside_tree():return
		if _move and _move.is_valid():_move.kill()
		if _lean and _lean.is_valid():_lean.kill()
		if _bob and _bob.is_valid():_bob.kill()
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
