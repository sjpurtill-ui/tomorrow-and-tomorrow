extends Control
## THE BATTLE FIELD, DRAWN: the battle screen's war map, inked like the war
## chart. The ground the battle is fought on (open country, broken hills, a
## forest edge, marsh, a pass, a ford or a bridge over a river, a breach or
## a gate in the walls); each side's ground washed in its colour up to where
## the lines meet; the engine's blocks drawn as their own kit, as wide as
## the men they started with and filled by the men left, the line in its
## slots, the reserve behind, the broken falling back and the fled at the
## edge; where the lines meet, in the age's manner (a melee of blows, musket
## smoke, a trench line, the armour front); and the day's attacks as arrows.
## Stepping to another day eases every block from where it stood to where
## it stands. Pointing at a block says what it is. Nothing here fights:
## hud/battle_field_model.gd lays out what the battle record holds, and this
## only draws it (on change and while easing; never every frame).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Model:=preload("res://scripts/hud/battle_field_model.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const Record:=preload("res://scripts/battle_record.gd")
const Account:=preload("res://scripts/battle_account.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const EASE_SECONDS:=0.6
## The kit glyphs' ink: the chart's own, on each glyph's paper halo.
const GLYPH_INK:=Color("2b2118")

var view:Dictionary={}
var record:Dictionary={}
var step:=0
var left_colour:=Color("356f66")
var right_colour:=Color("a34435")
## Each side's name as the field letters it ("Sirra's host", "the Esurai").
var names:={"left":"","right":""}
## What is drawn now, and what it eases from.
var layout:Dictionary={}
var before:Dictionary={}
var blend:=1.0:
	set(value):
		blend=value
		queue_redraw()
var _tween:Tween
## Times the field has been drawn (tests read it).
var drawn:=0


func _init()->void:
	mouse_filter=Control.MOUSE_FILTER_PASS
	clip_contents=true
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	custom_minimum_size=Vector2(480,260)


## Shows the field at `new_step`; eases from what was shown when `animate`.
func show_step(new_view:Dictionary,new_record:Dictionary,new_step:int,animate:bool)->void:
	view=new_view; record=new_record; step=new_step
	var next:=Model.build(view,record,step,_field_size())
	if is_instance_valid(_tween): _tween.kill()
	if animate and not layout.is_empty() and not Motion.reduced() and is_inside_tree():
		before=_blended(); layout=next
		blend=0.0
		_tween=create_tween(); _tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(self,"blend",1.0,EASE_SECONDS)
	else:
		layout=next; before={}; blend=1.0
	queue_redraw()


func _field_size()->Vector2:
	return size if size.x>=200.0 and size.y>=160.0 else Vector2(maxf(size.x,1200.0),maxf(size.y,420.0))


func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED and not view.is_empty():
		layout=Model.build(view,record,step,_field_size()); before={}
		queue_redraw()


## What a block is, pointed at: its kit, its men, its heart and where it is.
func _get_tooltip(at:Vector2)->String:
	var blocks:Array=layout.get("blocks",[])
	for i in range(blocks.size()-1,-1,-1):
		var block:Dictionary=blocks[i]
		if (block.rect as Rect2).grow(2.0).has_point(at): return block_words(block.get("data",{}),String(block.key),names)
	for arrow in layout.get("arrows",[]):
		var points:PackedVector2Array=arrow.points
		if points.size()>=2 and Geometry2D.get_closest_point_to_segment(at,points[0],points[-1]).distance_to(at)<=8.0: return arrow_words(arrow,names,bool(view.get("player",false)))
	return ""


static func block_words(plate:Dictionary,key:String,side_names:Dictionary)->String:
	var arm:=Record.arm_words(String(plate.get("arm","spear")),2)
	var state:=String(plate.get("state","front"))
	var whose:=String(side_names.get(key,""))
	var head:=_cap(arm) if whose=="" else "%s: %s" % [_cap(_strip(whose)),arm]
	var where:=String({"front":"in the line","reserve":"waiting behind the line","broken":"broke and ran","fled":"left the field"}.get(state,""))
	if state in ["broken","fled"] and int(plate.get("men",0))<=0: return "%s\n%s. It started with %s." % [head,_cap(where),EraWords.grouped(int(plate.get("men0",0)))]
	return "%s\n%s of %s still with it, %s.\n%s." % [head,EraWords.grouped(int(plate.get("men",0))),EraWords.grouped(int(plate.get("men0",0))),Account.morale_words(float(plate.get("cohesion",1.0))),_cap(where)]


static func arrow_words(arrow:Dictionary,side_names:Dictionary,player:bool)->String:
	var key:=String(arrow.get("key","left"))
	var who:=("We" if key=="left" else "They") if player else _cap(String(side_names.get(key,"")))
	match String(arrow.get("kind","")):
		"thrust": return "%s held at the line." % who if bool(arrow.get("blunt",false)) else "%s attack." % who
		"hook": return "%s come round the flank." % who
		"reserve": return "A fresh block goes into the line."
		"rout": return "A block broke and ran."
		"flight": return "They left the field." if key=="right" else ("We left the field." if player else "%s left the field." % who)
		"pursuit": return "%s ride down the fleeing." % who
		"fire": return "Guns fire over their own line."
	return ""


static func _strip(name:String)->String:
	return name.trim_prefix("the ").trim_prefix("The ")


# --- Easing between days -------------------------------------------------------------------

## The layout as drawn at this instant (blocks and the line part-way between
## two days), to ease on from when the day changes mid-way.
func _blended()->Dictionary:
	if before.is_empty() or blend>=1.0: return layout
	var out:=layout.duplicate()
	var blocks:Array=[]
	for block in layout.get("blocks",[]):
		var b:Dictionary=(block as Dictionary).duplicate()
		var from:=_match(before,b)
		if not from.is_empty(): b["rect"]=_lerp_rect(from.rect,b.rect,_eased())
		blocks.append(b)
	out["blocks"]=blocks
	out["contact"]=lerpf(float(before.get("contact",layout.contact)),float(layout.contact),_eased())
	return out


func _eased()->float:
	return clampf(blend,0.0,1.0)


static func _match(source:Dictionary,block:Dictionary)->Dictionary:
	for other in source.get("blocks",[]):
		if String(other.id)==String(block.id) and String(other.key)==String(block.key): return other
	return {}


static func _lerp_rect(a:Rect2,b:Rect2,t:float)->Rect2:
	return Rect2(a.position.lerp(b.position,t),a.size.lerp(b.size,t))


# --- Drawing --------------------------------------------------------------------------------

func _draw()->void:
	if layout.is_empty(): return
	drawn+=1
	var t:=_eased()
	var w:=size.x; var h:=size.y
	var contact:=lerpf(float(before.get("contact",layout.contact)),float(layout.contact),t) if not before.is_empty() else float(layout.contact)
	_draw_paper(w,h,contact)
	_draw_ground(w,h)
	_draw_marks(t)
	_draw_blocks(t)
	_draw_contact(w,h,contact,t)
	_draw_arrows(t)
	_draw_names(w,h)


func _side_colour(key:String)->Color:
	return left_colour if key=="left" else right_colour


func _wash(colour:Color,alpha:float)->Color:
	return Color(colour,alpha*(1.0 if T.is_light() else 0.8))


## The map's paper, each side's ground washed in its colour up to the line.
func _draw_paper(w:float,h:float,contact:float)->void:
	draw_rect(Rect2(0,0,w,h),T.PAPER_RAISED)
	draw_rect(Rect2(0,0,w,contact),_wash(right_colour,0.07))
	draw_rect(Rect2(0,contact,w,h-contact),_wash(left_colour,0.07))
	# A faint survey grid, as on a staff map.
	var grid:=Color(T.RULE,0.18)
	var step_px:=maxf(60.0,w/16.0)
	var x:=step_px
	while x<w:
		draw_line(Vector2(x,0),Vector2(x,h),grid,1.0)
		x+=step_px
	var y:=step_px
	while y<h:
		draw_line(Vector2(0,y),Vector2(w,y),grid,1.0)
		y+=step_px
	draw_rect(Rect2(0,0,w,h),T.RULE_STRONG,false,1.0)


func _ink(alpha:float)->Color:
	return Color(T.INK_MUTED,alpha)


func _draw_ground(w:float,h:float)->void:
	var kind:=String(layout.get("ground","open"))
	var opening:Array=layout.get("opening",[w*0.05,w*0.95])
	var x0:=float(opening[0]); var x1:=float(opening[1])
	var mid:=h*0.5
	var rng:=RandomNumberGenerator.new(); rng.seed=hash(kind)+int(record.get("seed",0))
	var mark:=_ink(0.42)
	match kind:
		"open":
			for i in 46: _tuft(Vector2(rng.randf_range(10,w-10),rng.randf_range(10,h-10)),mark)
		"rough":
			for i in 16:
				var at:=Vector2(rng.randf_range(20,w-20),rng.randf_range(16,h-16))
				if at.x>x0+20 and at.x<x1-20 and rng.randf()<0.6: at.x=x0-30 if rng.randf()<0.5 else x1+30
				_hill(at,rng.randf_range(16,30),mark)
			for i in 22: _tuft(Vector2(rng.randf_range(10,w-10),rng.randf_range(10,h-10)),_ink(0.3))
		"forest":
			for side in [[8.0,x0-6.0],[x1+6.0,w-8.0]]:
				var a:=float(side[0]); var b:=float(side[1])
				if b-a<12.0: continue
				var y:=10.0
				while y<h-6.0:
					var x:=a+rng.randf_range(0,10)
					while x<b:
						_tree(Vector2(x,y),rng.randf_range(7,11))
						x+=rng.randf_range(16,24)
					y+=rng.randf_range(16,22)
			for i in 6: _tree(Vector2(rng.randf_range(x0+10,x1-10),rng.randf_range(16,h-16)),rng.randf_range(6,9))
		"marsh":
			for side in [[8.0,x0-6.0],[x1+6.0,w-8.0]]:
				var a:=float(side[0]); var b:=float(side[1])
				if b-a<16.0: continue
				for i in 9:
					var c:=Vector2(rng.randf_range(a,b),rng.randf_range(20,h-20))
					_pool(c,rng.randf_range(18,34))
				for i in 26: _reeds(Vector2(rng.randf_range(a,b),rng.randf_range(10,h-10)),mark)
			for i in 8: _reeds(Vector2(rng.randf_range(x0,x1),rng.randf_range(10,h-10)),_ink(0.3))
		"pass":
			_cliff(Vector2(0,0),x0,h,1.0,rng)
			_cliff(Vector2(x1,0),w-x1,h,-1.0,rng)
			for i in 10: _tuft(Vector2(rng.randf_range(x0+8,x1-8),rng.randf_range(10,h-10)),_ink(0.3))
		"ford","bridge":
			_river(w,mid,x0,x1,kind=="bridge",rng)
			for i in 24: _tuft(Vector2(rng.randf_range(10,w-10),rng.randf_range(10,h-10)),_ink(0.3))
		"breach","gate":
			_walls(w,h,mid,x0,x1,kind=="gate",rng)
	_ground_label(kind,w,h,x0,x1,mid)


func _tuft(at:Vector2,colour:Color)->void:
	draw_line(at,at+Vector2(-2,-4),colour,1.0,true)
	draw_line(at,at+Vector2(2,-4),colour,1.0,true)


## A hill as the chart inks one: a brow with hachures falling from it.
func _hill(at:Vector2,r:float,colour:Color)->void:
	draw_arc(at,r,PI*1.08,PI*1.92,14,colour,1.2,true)
	for k in 7:
		var a:=PI*(1.14+0.72*float(k)/6.0)
		var p:=at+Vector2(cos(a),sin(a))*r
		draw_line(p,p+Vector2(cos(a),sin(a))*-4.0+Vector2(0,5),Color(colour,colour.a*0.8),1.0,true)


func _tree(at:Vector2,r:float)->void:
	draw_line(at+Vector2(0,r*0.6),at+Vector2(0,r*1.25),_ink(0.55),1.2,true)
	draw_circle(at,r,Color(T.GREEN,0.22 if T.is_light() else 0.3))
	draw_arc(at,r,0.0,TAU,14,_ink(0.6),1.1,true)


func _pool(at:Vector2,r:float)->void:
	var points:=PackedVector2Array()
	for k in 13:
		var a:=TAU*float(k)/12.0
		points.append(at+Vector2(cos(a)*r,sin(a)*r*0.45))
	draw_colored_polygon(points,Color(T.BLUE,0.14))
	draw_line(at+Vector2(-r*0.5,0),at+Vector2(r*0.3,0),Color(T.BLUE,0.45),1.0,true)


func _reeds(at:Vector2,colour:Color)->void:
	draw_line(at,at+Vector2(-2,-7),colour,1.0,true)
	draw_line(at+Vector2(2,0),at+Vector2(2,-8),colour,1.0,true)
	draw_line(at+Vector2(4,0),at+Vector2(6,-6),colour,1.0,true)


## A mountain side closing the field, hachured along its foot.
func _cliff(origin:Vector2,width:float,h:float,facing:float,rng:RandomNumberGenerator)->void:
	if width<6.0: return
	var edge:=PackedVector2Array()
	var foot:=origin.x+width if facing>0.0 else origin.x
	var y:=0.0
	while y<=h:
		edge.append(Vector2(foot-facing*rng.randf_range(0,12),y))
		y+=h/14.0
	edge.append(Vector2(foot,h))
	var body:=PackedVector2Array()
	var back:=origin.x if facing>0.0 else origin.x+width
	body.append(Vector2(back,0))
	body.append_array(edge)
	body.append(Vector2(back,h))
	draw_colored_polygon(body,Color(T.PAPER_SUNK,0.95))
	draw_colored_polygon(body,Color(T.INK_MUTED,0.08))
	draw_polyline(edge,_ink(0.75),1.6,true)
	for k in range(1,edge.size()-1):
		var p:=edge[k]
		for j in 3:
			var q:=p+Vector2(-facing*(6.0+float(j)*7.0),float(j)*3.0-3.0)
			draw_line(q,q+Vector2(-facing*9.0,4.0),_ink(0.4),1.0,true)


## A river across the field at its middle: a ford's shallows or a bridge
## where the fighting can cross.
func _river(w:float,mid:float,x0:float,x1:float,bridge:bool,rng:RandomNumberGenerator)->void:
	var half:=13.0
	var top:=PackedVector2Array(); var bottom:=PackedVector2Array()
	var steps:=24
	for k in steps+1:
		var x:=w*float(k)/float(steps)
		var wobble:=sin(float(k)*0.9)*3.0
		top.append(Vector2(x,mid-half+wobble)); bottom.append(Vector2(x,mid+half+wobble*0.6))
	var body:=top.duplicate()
	var rev:=bottom.duplicate(); rev.reverse(); body.append_array(rev)
	draw_colored_polygon(body,Color(T.BLUE,0.24 if T.is_light() else 0.3))
	draw_polyline(top,Color(T.BLUE,0.75),1.4,true)
	draw_polyline(bottom,Color(T.BLUE,0.75),1.4,true)
	for i in 14:
		var x:=rng.randf_range(10,w-30)
		if x>x0 and x<x1: continue
		var y:=mid+rng.randf_range(-5,5)
		draw_line(Vector2(x,y),Vector2(x+14,y+1),Color(T.BLUE,0.5),1.0,true)
	if bridge:
		var deck_top:=mid-half-6.0; var deck_bottom:=mid+half+6.0
		var bx0:=x0+(x1-x0)*0.18; var bx1:=x1-(x1-x0)*0.18
		draw_rect(Rect2(bx0,deck_top,bx1-bx0,deck_bottom-deck_top),Color(T.PAPER_SUNK,1.0))
		draw_line(Vector2(bx0,deck_top),Vector2(bx0,deck_bottom),_ink(0.85),2.0,true)
		draw_line(Vector2(bx1,deck_top),Vector2(bx1,deck_bottom),_ink(0.85),2.0,true)
		var y:=deck_top+3.0
		while y<deck_bottom:
			draw_line(Vector2(bx0+2,y),Vector2(bx1-2,y),_ink(0.3),1.0)
			y+=5.0
	else:
		# The ford: shallows, the water broken over stones.
		draw_rect(Rect2(x0,mid-half+2,x1-x0,half*2.0-4.0),Color(T.PAPER_RAISED,0.5))
		for i in 18:
			draw_circle(Vector2(rng.randf_range(x0+4,x1-4),mid+rng.randf_range(-half+4,half-4)),rng.randf_range(1.2,2.2),_ink(0.4))


## Walls across the field: the defender behind them, the fighting at a
## breach or a gate; the town's roofs behind the defenders.
func _walls(w:float,h:float,mid:float,x0:float,x1:float,gate:bool,rng:RandomNumberGenerator)->void:
	var defender:=String(layout.get("defender","right"))
	var outward:=1.0 if defender=="right" else -1.0
	var thick:=9.0
	var wall:=_ink(0.85)
	for run in [[0.0,x0],[x1,w]]:
		var a:=float(run[0]); var b:=float(run[1])
		if b-a<2.0: continue
		draw_rect(Rect2(a,mid-thick*0.5,b-a,thick),Color(T.PAPER_SUNK,1.0))
		draw_rect(Rect2(a,mid-thick*0.5,b-a,thick),wall,false,1.6)
		var x:=a+4.0
		while x<b-6.0:
			draw_rect(Rect2(x,mid+outward*thick*0.5-(4.0 if outward<0.0 else 0.0),5.0,4.0),wall)
			x+=11.0
	if gate:
		for x in [x0,x1]:
			var tower:=Rect2(x-12.0,mid-15.0,24.0,30.0)
			draw_rect(tower,Color(T.PAPER_SUNK,1.0)); draw_rect(tower,wall,false,1.8)
		# The gate's two leaves, standing open inward.
		var leaf:=minf(26.0,(x1-x0)*0.25)
		draw_line(Vector2(x0+12.0,mid),Vector2(x0+12.0+leaf*0.7,mid-outward*leaf*0.7),wall,2.4,true)
		draw_line(Vector2(x1-12.0,mid),Vector2(x1-12.0-leaf*0.7,mid-outward*leaf*0.7),wall,2.4,true)
	else:
		for i in 22:
			var p:=Vector2(rng.randf_range(x0+2,x1-2),mid+rng.randf_range(-8,8))
			var r:=rng.randf_range(2.0,4.5)
			draw_colored_polygon(PackedVector2Array([p+Vector2(-r,0),p+Vector2(0,-r*0.8),p+Vector2(r,0.2),p+Vector2(0.2,r*0.7)]),_ink(0.45))
	# Roofs of the town behind the defenders.
	var back:=2.0 if defender=="right" else h-2.0
	for i in 9:
		var x:=rng.randf_range(20,w-20)
		var y:=back+outward*-1.0*rng.randf_range(8,22)
		var p:=Vector2(x,y)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-7,0),p+Vector2(0,-7),p+Vector2(7,0)]),Color(T.PAPER_SUNK,1.0))
		draw_polyline(PackedVector2Array([p+Vector2(-7,0),p+Vector2(0,-7),p+Vector2(7,0)]),_ink(0.5),1.1,true)
		draw_rect(Rect2(p+Vector2(-5,0),Vector2(10,6)),_ink(0.5),false,1.0)


## The ground named where it lies ("a ford", "the gate"), in the voice face.
func _ground_label(kind:String,w:float,h:float,x0:float,x1:float,mid:float)->void:
	if kind=="open": return
	var words:=String((Blocks.GROUNDS.get(kind,{}) as Dictionary).get("words",""))
	if words=="": return
	var font:=T.font("voice_italic")
	var at:=Vector2(x1+10.0,mid-18.0) if kind in ["ford","bridge","breach","gate"] else Vector2(maxf(10.0,x0-150.0),h-12.0)
	if kind in ["forest","marsh","pass","rough"]: at=Vector2(w-12.0-font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x,h-10.0)
	draw_string_outline(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,15,4,Color(T.PAPER_RAISED,0.9))
	draw_string(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,15,T.INK_MUTED)


## The general's tactic where it shows on the ground: a second line held
## back, dug-in works, a screen of missiles, a pocket closing.
func _draw_marks(t:float)->void:
	for mark in layout.get("marks",[]):
		var colour:=_side_colour(String(mark.key))
		var points:PackedVector2Array=mark.get("points",PackedVector2Array())
		if points.size()<2: continue
		var a:=Color(colour,0.75*t)
		match String(mark.kind):
			"depth": _dashed(points,a,1.4,8.0,6.0)
			"screen":
				var x:=points[0].x
				while x<points[1].x:
					draw_circle(Vector2(x,points[0].y),1.6,a); x+=9.0
			"trenches","camp":
				var toward:=-1.0 if String(mark.key)=="left" else 1.0
				var y:=points[0].y+toward*5.0
				var zig:=PackedVector2Array()
				var x2:=points[0].x
				var up:=true
				while x2<=points[1].x:
					zig.append(Vector2(x2,y+(toward*3.0 if up else 0.0))); x2+=8.0; up=not up
				if zig.size()>=2: draw_polyline(zig,a,1.6,true)
			"shield_line","firing_line":
				var toward2:=-1.0 if String(mark.key)=="left" else 1.0
				draw_line(points[0]+Vector2(0,toward2*3.0),points[1]+Vector2(0,toward2*3.0),a,2.4,true)
			"pocket": _dashed(points,Color(colour,0.9*t),2.0,7.0,5.0)


func _draw_blocks(t:float)->void:
	for block in layout.get("blocks",[]):
		var b:Dictionary=block
		var rect:Rect2=b.rect
		var alpha:=float(b.get("alpha",1.0))
		if not before.is_empty():
			var from:=_match(before,b)
			if not from.is_empty():
				rect=_lerp_rect(from.rect,rect,t)
				alpha=lerpf(float(from.get("alpha",1.0)),alpha,t)
			else: alpha*=t
		_draw_block(b,rect,alpha)


func _draw_block(b:Dictionary,rect:Rect2,alpha:float)->void:
	var key:=String(b.key)
	var state:=String(b.state)
	var colour:=_side_colour(key)
	var tilt:=float(b.get("tilt",0.0))
	var local:=Rect2(-rect.size*0.5,rect.size)
	draw_set_transform(rect.get_center(),tilt,Vector2.ONE)
	var faces_up:=key=="left"
	var strength:=float(b.strength)
	var men:=int(b.men)
	# The ground it covered at the start, then the men still with it.
	var paper:=T.PAPER_RAISED if state=="front" else T.PAPER
	draw_rect(local,Color(paper,0.92*alpha))
	draw_rect(local,Color(T.RULE_STRONG,0.7*alpha),false,1.0)
	if state in ["front","reserve"] and men>0:
		var fill_h:=maxf(2.0,local.size.y*strength)
		var fill:=Rect2(local.position.x,local.position.y if faces_up else local.end.y-fill_h,local.size.x,fill_h)
		draw_rect(fill,Color(colour,(0.30 if state=="front" else 0.16)*alpha))
		draw_rect(fill,Color(T.INK,0.85*alpha),false,1.3)
	elif state=="broken":
		var hatch:=Color(T.RED,0.38*alpha)
		var x:=local.position.x-local.size.y
		while x<local.end.x:
			var a:=Vector2(maxf(x,local.position.x),local.end.y-maxf(0.0,local.position.x-x))
			var c:=Vector2(minf(x+local.size.y,local.end.x),local.position.y+maxf(0.0,x+local.size.y-local.end.x))
			draw_line(a,c,hatch,1.0,true)
			x+=6.0
		draw_rect(local,Color(T.RED,0.7*alpha),false,1.3)
	else:
		_dashed_rect(local,Color(T.INK_MUTED,0.8*alpha))
	# The edge it fights from, in its side's colour.
	if state=="front":
		var band:=Rect2(local.position.x,local.position.y if faces_up else local.end.y-3.0,local.size.x,3.0)
		draw_rect(band,Color(colour,alpha))
	# Its kit, and its men when there is room.
	var glyph_px:=clampf(minf(local.size.y-8.0,40.0),12.0,40.0)
	var number:=EraWords.grouped(men) if men>0 else ("broke" if state=="broken" else "")
	var font:=T.font("ui_strong")
	var font_size:=15 if local.size.y>=48.0 else (13 if local.size.y>=30.0 else 12)
	var number_w:=font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x if number!="" else 0.0
	var room:=local.size.x-glyph_px-10.0
	var show_number:=number!="" and room>=number_w and local.size.y>=18.0
	# Too narrow for the two side by side but tall enough: the kit above, the men below.
	var stacked:=not show_number and number!="" and local.size.y>=40.0 and local.size.x>=number_w+4.0
	if stacked: glyph_px=clampf(local.size.y-22.0,12.0,minf(34.0,local.size.x-6.0))
	var gx:=local.position.x+4.0 if show_number else local.get_center().x-glyph_px*0.5
	var gy:=local.get_center().y-glyph_px*0.5 if not stacked else local.position.y+(local.size.y-glyph_px-14.0)*0.5
	# The kit is inked on its own paper token, so it reads on either paper.
	var icon:=Icons.arm_texture(String(b.glyph),GLYPH_INK,colour)
	draw_texture_rect(icon,Rect2(gx,gy,glyph_px,glyph_px),false,Color(1,1,1,alpha*(0.55 if state in ["broken","fled"] else 1.0)))
	if stacked:
		var small:=12
		var sw:=font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,small).x
		draw_string(font,Vector2(local.get_center().x-sw*0.5,gy+glyph_px+12.0),number,HORIZONTAL_ALIGNMENT_LEFT,-1,small,Color(T.RED_TEXT if state=="broken" else T.INK,alpha))
	if show_number:
		var text_colour:=T.RED_TEXT if state=="broken" else T.INK
		var word:=Record.arm_words(String(b.arm),maxi(2,men))
		var word_w:=T.font("ui").get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		var with_word:=local.size.y>=46.0 and word_w<=room
		var ny:=local.get_center().y+float(font_size)*0.36-(7.0 if with_word else 0.0)
		draw_string(font,Vector2(local.end.x-4.0-number_w,ny),number,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(text_colour,alpha))
		if with_word: draw_string(T.font("ui"),Vector2(local.end.x-4.0-word_w,ny+15.0),word,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(T.INK_MUTED,alpha))
	# Heart: a thin bar along its back edge.
	if state in ["front","reserve"] and men>0 and local.size.y>=16.0:
		var heart:=float(b.cohesion)
		var heart_colour:=T.GREEN if heart>=0.5 else (T.AMBER if heart>=0.25 else T.RED)
		var y:=local.end.y-3.0 if faces_up else local.position.y
		draw_rect(Rect2(local.position.x+1.0,y,(local.size.x-2.0)*heart,2.0),Color(heart_colour,0.95*alpha))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)


func _dashed_rect(rect:Rect2,colour:Color)->void:
	var corners:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y),rect.position])
	_dashed(corners,colour,1.0,4.0,3.0)


## Where the lines meet, in the age's manner: a melee of blows (spears and
## swords), musket smoke, a trench line under shellfire (rifles), the armour
## front with its teeth into the side giving way (and drones over it).
func _draw_contact(w:float,h:float,contact:float,t:float)->void:
	var span:=_fighting_span(w)
	if span.x>=span.y: return
	var drawn_up:=int(layout.get("step",0))==0 or float(layout.get("apart",2.0))>4.0
	if drawn_up:
		_dashed(PackedVector2Array([Vector2(span.x,contact),Vector2(span.y,contact)]),Color(T.INK_MUTED,0.45),1.2,10.0,8.0)
		return
	var era:=int(layout.get("era",0))
	var progress:=float(layout.get("progress",0.0))
	var rng:=RandomNumberGenerator.new(); rng.seed=int(record.get("seed",0))+int(layout.get("step",0))*7919
	var ink:=Color(T.INK,0.9)
	if era<=1:
		var zig:=PackedVector2Array()
		var x:=span.x; var up:=true
		while x<=span.y:
			zig.append(Vector2(x,contact+(3.5 if up else -3.5))); x+=9.0; up=not up
		draw_polyline(zig,Color(T.PAPER_RAISED,0.8),5.0,true)
		draw_polyline(zig,ink,2.0,true)
		for i in int(clampf((span.y-span.x)/60.0,3.0,16.0)):
			var at:=Vector2(rng.randf_range(span.x+6,span.y-6),contact+rng.randf_range(-6,6))
			var r:=rng.randf_range(3.5,6.0)
			draw_line(at-Vector2(r,r),at+Vector2(r,r),Color(T.INK,0.6*t),1.3,true)
			draw_line(at+Vector2(r,-r),at-Vector2(r,-r),Color(T.INK,0.6*t),1.3,true)
	elif era==2:
		for i in int(clampf((span.y-span.x)/22.0,6.0,60.0)):
			var at:=Vector2(rng.randf_range(span.x,span.y),contact+rng.randf_range(-16,16))
			draw_circle(at,rng.randf_range(4.0,9.0),Color(T.INK_MUTED,0.12*t))
		draw_line(Vector2(span.x,contact),Vector2(span.y,contact),Color(T.PAPER_RAISED,0.8),5.0,true)
		draw_line(Vector2(span.x,contact),Vector2(span.y,contact),ink,2.0,true)
	else:
		if era==3:
			for i in int(clampf((span.y-span.x)/40.0,4.0,40.0)):
				var at:=Vector2(rng.randf_range(span.x,span.y),contact+rng.randf_range(-22,22))
				draw_arc(at,rng.randf_range(2.0,4.0),0.0,TAU,10,Color(T.INK_MUTED,0.5*t),1.0,true)
		var line:=PackedVector2Array()
		var x:=span.x; var k:=0
		while x<=span.y:
			line.append(Vector2(x,contact+(sin(float(k)*1.3)*2.0 if era==3 else 0.0))); x+=10.0; k+=1
		draw_polyline(line,Color(T.PAPER_RAISED,0.8),6.0,true)
		draw_polyline(line,ink,2.6 if era>=4 else 2.0,true)
		if era>=4:
			for i in int(clampf((span.y-span.x)/90.0,2.0,14.0)):
				_burst(Vector2(rng.randf_range(span.x+8,span.y-8),contact+rng.randf_range(-14,14)),rng.randf_range(4.0,7.0),Color(T.INK,0.55*t))
		if era>=5:
			var losing:=-1.0 if progress>=0.0 else 1.0
			for i in 4:
				var at:=Vector2(lerpf(span.x,span.y,0.2+0.2*float(i)),contact+losing*-36.0+rng.randf_range(-6,6))
				BattleMarks._draw_sign(self,at,6.0,5,Color(_side_colour("left" if progress>=0.0 else "right"),0.8*t),1.4,0.0)
	# Teeth into the side giving way.
	if absf(progress)>=0.06:
		var into:=-1.0 if progress>0.0 else 1.0
		var colour:=Color(_side_colour("left" if progress>0.0 else "right"),0.9)
		var x2:=span.x+12.0
		var tooth:=5.0+7.0*minf(1.0,absf(progress))
		while x2<span.y-6.0:
			draw_colored_polygon(PackedVector2Array([Vector2(x2-4.5,contact),Vector2(x2+4.5,contact),Vector2(x2,contact+into*tooth)]),colour)
			x2+=26.0


func _burst(at:Vector2,r:float,colour:Color)->void:
	for k in 6:
		var a:=TAU*float(k)/6.0+0.3
		draw_line(at+Vector2(cos(a),sin(a))*r*0.35,at+Vector2(cos(a),sin(a))*r,colour,1.1,true)


## Across the field, the stretch where the two lines are in the fight.
func _fighting_span(w:float)->Vector2:
	var x0:=INF; var x1:=-INF
	for block in layout.get("blocks",[]):
		if String(block.state)!="front": continue
		x0=minf(x0,(block.rect as Rect2).position.x); x1=maxf(x1,(block.rect as Rect2).end.x)
	if x0==INF:
		var opening:Array=layout.get("opening",[w*0.1,w*0.9])
		return Vector2(float(opening[0]),float(opening[1]))
	return Vector2(x0-8.0,x1+8.0)


func _draw_arrows(t:float)->void:
	for arrow in layout.get("arrows",[]):
		var a:Dictionary=arrow
		var points:PackedVector2Array=_resampled(a.points,12)
		if t<1.0: points=_cut(points,t)
		if points.size()<3: continue
		var colour:=_side_colour(String(a.key))
		match String(a.kind):
			"thrust","hook":
				var base:=14.0+20.0*float(a.weight)
				_ink_arrow(points,base,Color(colour,0.5),Color(T.INK,0.85),false,bool(a.get("blunt",false)))
			"reserve":
				_ink_arrow(points,8.0,Color(colour,0.4),Color(T.INK,0.7),false,false)
			"rout":
				_ink_arrow(points,9.0,Color(colour,0.12),Color(colour,0.9),true,false)
			"flight":
				_ink_arrow(points,14.0+18.0*float(a.weight),Color(colour,0.14),Color(colour,0.9),true,false)
			"pursuit":
				_ink_arrow(points,8.0,Color(colour,0.18),Color(colour,0.9),true,false)
				for u in [0.35,0.6]:
					var k:=clampi(roundi(float(points.size()-1)*u),1,points.size()-2)
					var ahead:=(points[k+1]-points[k-1]).normalized()
					var across:=ahead.orthogonal()*3.5
					draw_polyline(PackedVector2Array([points[k]-ahead*4.0+across,points[k]+ahead*2.0,points[k]-ahead*4.0-across]),Color(T.INK,0.8),1.3,true)
			"fire":
				_dashed(points,Color(T.INK_MUTED,0.7),1.1,3.0,4.0)
				if t>=1.0: _burst(points[-1],5.0,Color(T.INK_MUTED,0.8))


static func _resampled(points:PackedVector2Array,n:int)->PackedVector2Array:
	if points.size()<2: return points
	var total:=0.0
	for i in range(1,points.size()): total+=points[i-1].distance_to(points[i])
	if total<=0.0: return points
	var out:=PackedVector2Array()
	for k in n+1:
		var target:=total*float(k)/float(n)
		var walked:=0.0
		for i in range(1,points.size()):
			var seg:=points[i-1].distance_to(points[i])
			if walked+seg>=target or i==points.size()-1:
				var u:=clampf((target-walked)/maxf(0.0001,seg),0.0,1.0)
				out.append(points[i-1].lerp(points[i],u)); break
			walked+=seg
	return out


static func _cut(points:PackedVector2Array,share:float)->PackedVector2Array:
	var keep:=maxi(2,roundi(float(points.size()-1)*clampf(share,0.0,1.0))+1)
	return points.slice(0,keep)


## A tapered, inked arrow (as the war chart draws its plan arrows): a paper
## halo, a wash body and an ink edge; a blunt one ends on a bar (held).
func _ink_arrow(points:PackedVector2Array,base:float,fill:Color,edge:Color,dashed:bool,blunt:bool)->void:
	var left:=PackedVector2Array(); var right:=PackedVector2Array()
	var shaft_end:=points.size()-3 if not blunt else points.size()-1
	for k in shaft_end+1:
		var a:=points[maxi(0,k-1)]; var b:=points[mini(points.size()-1,k+1)]
		var normal:=(b-a).normalized().orthogonal()
		var half:=lerpf(base*0.42,base*0.28,float(k)/float(maxi(1,shaft_end)))
		left.append(points[k]+normal*half); right.append(points[k]-normal*half)
	var tip:=points[-1]
	var back:=points[shaft_end]
	var direction:=(tip-points[-2]).normalized()
	if direction==Vector2.ZERO: return
	var body:=left.duplicate()
	if not blunt:
		var wing:=direction.orthogonal()*base*0.72
		body.append(back+wing); body.append(tip); body.append(back-wing)
	right.reverse(); body.append_array(right)
	var outline:=body.duplicate(); outline.append(body[0])
	if not dashed: draw_polyline(outline,Color(T.PAPER_RAISED,0.6),4.0,true)
	if fill.a>0.0 and Geometry2D.triangulate_polygon(body).size()>0: draw_colored_polygon(body,fill)
	if dashed: _dashed(outline,edge,1.3,5.0,4.0)
	else: draw_polyline(outline,edge,1.4,true)
	if blunt:
		var bar:=direction.orthogonal()*base*0.8
		draw_line(tip+bar,tip-bar,Color(T.INK,0.9),3.0,true)


func _dashed(points:PackedVector2Array,colour:Color,width:float,dash:float,gap:float)->void:
	for i in range(1,points.size()):
		var a:=points[i-1]; var b:=points[i]
		var length:=a.distance_to(b)
		if length<=0.0: continue
		var along:=(b-a)/length
		var d:=0.0
		while d<length:
			draw_line(a+along*d,a+along*minf(length,d+dash),colour,width,true)
			d+=dash+gap


## Each side named at its own rear corner.
func _draw_names(w:float,h:float)->void:
	var font:=T.font("ui_strong")
	for key in ["right","left"]:
		var text:=String(names.get(key,"")).to_upper()
		if text=="": continue
		var colour:=T.text_for(_side_colour(key))
		var y:=18.0 if key=="right" else h-8.0
		draw_string_outline(font,Vector2(10,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,4,Color(T.PAPER_RAISED,0.9))
		draw_string(font,Vector2(10,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,colour)


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)
