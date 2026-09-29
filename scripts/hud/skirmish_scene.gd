extends Control
## A SKIRMISH, DRAWN: the few who fought, as ink figures on a strip of the
## ground they fought on, sketched the way the war chart sketches a fight.
## Both bands come on and meet in the middle, and the fight resolves as the
## record says: the fallen lie where they fell, the hurt kneel, those who ran
## go off their own edge, the taken sit bound behind the winners, and the
## winners hold the ground. A fight still being fought jostles at the line
## with its fallen so far. Nothing here fights: it reads battle_record.gd
## view() as it stands (hud/battle_panel.gd builds the card around it).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
## Figures drawn a side at most; with more, each mark stands for several.
const MAX_MARKS:=24
const PLAY_SECONDS:=3.8
## Where the timeline turns: the bands close, they fight, it is decided.
const CLOSE_END:=0.34
const CLASH_END:=0.62
const HEIGHT:=176.0
const STATUSES:=["killed","wounded","captured","fled"]

var sides:Dictionary={"left":{},"right":{}}
var ink:={"left":Color.BLACK,"right":Color.BLACK}
var ground:="open"
var live:=false
## The town behind the right-hand band (the one ours went against), or "".
var town:=""
## "left", "right" or "" (neither held the field).
var winner:=""
var per_mark:={"left":1,"right":1}
var marks:={"left":[],"right":[]}
var t:=1.0
var playing:=false
## Times the scene has been drawn (tests read it).
var drawn:=0


func _init()->void:
	custom_minimum_size=Vector2(360,HEIGHT)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true


## view: battle_record.gd view(); inks: the two sides' colours; town: the
## town the right-hand side stood before, when there was one.
func configure(view:Dictionary,left_ink:Color,right_ink:Color,town_name:String="")->void:
	ink={"left":left_ink,"right":right_ink}
	ground=String((view.get("ground",{}) as Dictionary).get("kind","open"))
	live=bool(view.get("live",false))
	town=town_name
	var outcome:=String(view.get("outcome",""))
	winner="left" if outcome=="won" else ("right" if outcome in ["lost","withdrew"] else "")
	if live: winner=""
	for key in ["left","right"]:
		var side:Dictionary=(view.get("sides",{}) as Dictionary).get(key,{})
		sides[key]=(side.get("totals",{}) as Dictionary).duplicate()
		marks[key]=_assign(key)
	t=1.0 if Motion.reduced() else 0.0
	playing=not Motion.reduced()
	set_process(playing or live)
	queue_redraw()


## Already seen coming on (a live fight redrawn as it goes on): start at the
## line, not with the march in.
func skip_approach()->void:
	t=maxf(t,CLOSE_END)


## Plays the fight again from the two bands drawn up.
func replay()->void:
	if Motion.reduced(): return
	t=0.0;playing=true;set_process(true)


func _process(delta:float)->void:
	if playing:
		t=minf(1.0,t+delta/PLAY_SECONDS)
		if t>=1.0:
			playing=false
			if not live: set_process(false)
	queue_redraw()


## Each figure's fate, front file first: the fallen, the hurt, the taken and
## those who ran, in that order, the rest still standing. With more men than
## marks, each mark stands for several and the counts are shared out.
func _assign(key:String)->Array:
	var totals:Dictionary=sides[key]
	var went:=maxi(0,int(totals.get("went_in",0)))
	if went<=0: return []
	per_mark[key]=ceili(float(went)/float(MAX_MARKS))
	var shown:=ceili(float(went)/float(per_mark[key]))
	var out:Array=[]
	for status in STATUSES:
		var n:=roundi(float(int(totals.get(status,0)))/float(per_mark[key]))
		# A single one lost still shows, even when each mark is several.
		if n==0 and int(totals.get(status,0))>0: n=1
		for i in n:
			if out.size()<shown: out.append(status)
	while out.size()<shown: out.append("standing")
	# The fallen and the hurt are at the front; the rest are shared along.
	return out


# --- Drawing ------------------------------------------------------------------------

func _draw()->void:
	drawn+=1
	var w:=size.x
	var h:=size.y
	if w<=0.0: return
	_draw_ground(w,h)
	if town!="": _draw_town(Vector2(w-34.0,h*0.56))
	for key in ["left","right"]: _draw_band(key,w,h)
	if t>CLOSE_END-0.04 and (t<CLASH_END or (live and not playing)) and not marks.left.is_empty() and not marks.right.is_empty():
		_draw_blows(w,h)
	_draw_scale(w,h)


func _ground_wash()->Color:
	var wash:Color={"open":Color("c9c38f"),"rough":Color("c2ad84"),"forest":Color("9fb07e"),"marsh":Color("a9b99b"),"pass":Color("b8a88c"),
		"ford":Color("c9c38f"),"bridge":Color("c9c38f"),"breach":Color("bfae8e"),"gate":Color("bfae8e")}.get(ground,Color("c9c38f"))
	return Color(wash,0.30) if T.is_light() else Color(wash.darkened(0.55),0.55)


func _draw_ground(w:float,h:float)->void:
	var top:=h*0.34
	draw_rect(Rect2(Vector2.ZERO,Vector2(w,h)),Color(T.PAPER_RAISED,0.9))
	draw_rect(Rect2(Vector2(0,top),Vector2(w,h-top)),_ground_wash())
	# The skyline of the ground, a hand-drawn rule.
	var line:=PackedVector2Array()
	for i in 25:
		var x:=w*float(i)/24.0
		line.append(Vector2(x,top+sin(float(i)*1.7)*1.6))
	draw_polyline(line,T.RULE,1.2,true)
	var rng:=RandomNumberGenerator.new();rng.seed=hash(ground)
	var mark:=Color(T.INK_MUTED,0.55)
	match ground:
		"forest":
			for i in 11:
				var x:=w*(0.04+0.092*float(i))+rng.randf_range(-6,6)
				var y:=top-2.0
				draw_colored_polygon(PackedVector2Array([Vector2(x,y-18),Vector2(x-7,y),Vector2(x+7,y)]),Color(T.GREEN,0.55))
				draw_line(Vector2(x,y),Vector2(x,y+4),mark,1.2)
		"rough","pass":
			for i in 7:
				var x:=w*(0.06+0.14*float(i))+rng.randf_range(-10,10)
				draw_arc(Vector2(x,top+6.0),16.0,PI*1.1,PI*1.9,12,mark,1.1,true)
			for i in 14:
				draw_circle(Vector2(rng.randf_range(0,w),rng.randf_range(top+12,h-8)),rng.randf_range(1.2,2.4),mark)
			if ground=="pass":
				draw_colored_polygon(PackedVector2Array([Vector2(0,top),Vector2(w,top),Vector2(w,top+10),Vector2(0,top+18)]),Color(T.INK_MUTED,0.18))
		"marsh":
			for i in 18:
				var x:=rng.randf_range(0,w);var y:=rng.randf_range(top+10,h-6)
				draw_line(Vector2(x,y),Vector2(x-2,y-7),mark,1.0);draw_line(Vector2(x+3,y),Vector2(x+4,y-6),mark,1.0)
			for i in 6:
				var x2:=rng.randf_range(0,w-30);var y2:=rng.randf_range(top+16,h-10)
				draw_line(Vector2(x2,y2),Vector2(x2+22,y2),Color(T.BLUE,0.35),1.2)
		"ford","bridge":
			var river:=PackedVector2Array([Vector2(w*0.47,top),Vector2(w*0.53,top),Vector2(w*0.56,h),Vector2(w*0.44,h)])
			draw_colored_polygon(river,Color(T.BLUE,0.22))
			for i in 5:
				var y3:=top+12.0+float(i)*22.0
				draw_line(Vector2(w*0.47,y3),Vector2(w*0.53,y3+3),Color(T.BLUE,0.45),1.0)
			if ground=="bridge": draw_line(Vector2(w*0.42,h*0.66),Vector2(w*0.58,h*0.66),T.INK_MUTED,3.0)
		"breach","gate":
			var x4:=w*0.6
			draw_line(Vector2(x4,top+4),Vector2(x4,h*0.5),T.INK_MUTED,4.0)
			draw_line(Vector2(x4,h*0.72),Vector2(x4,h-4),T.INK_MUTED,4.0)
		_:
			for i in 16:
				var x5:=rng.randf_range(0,w);var y5:=rng.randf_range(top+10,h-6)
				draw_line(Vector2(x5,y5),Vector2(x5-2,y5-4),mark,1.0);draw_line(Vector2(x5,y5),Vector2(x5+2,y5-4),mark,1.0)


func _draw_town(at:Vector2)->void:
	var col:=Color(T.INK_MUTED,0.8)
	for offset in [Vector2(-14,6),Vector2(2,0),Vector2(16,8)]:
		var p:Vector2=at+offset
		draw_colored_polygon(PackedVector2Array([p+Vector2(-8,0),p+Vector2(0,-9),p+Vector2(8,0)]),Color(T.PAPER_SUNK,1.0))
		draw_polyline(PackedVector2Array([p+Vector2(-8,0),p+Vector2(0,-9),p+Vector2(8,0)]),col,1.3,true)
		draw_rect(Rect2(p+Vector2(-6,0),Vector2(12,8)),col,false,1.2)
	var font:=T.font("ui")
	var width:=font.get_string_size(town,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_string(font,Vector2(at.x-width*0.5+2.0,at.y+26.0),town,HORIZONTAL_ALIGNMENT_LEFT,-1,11,T.INK_MUTED)


## One band: drawn up in files of up to three, the front file nearest the
## middle; marching in, fighting, and each figure's fate played out.
func _draw_band(key:String,w:float,h:float)->void:
	var figures:Array=marks[key]
	if figures.is_empty(): return
	var dir:=1.0 if key=="left" else -1.0
	var ranks:=mini(3,maxi(1,ceili(float(figures.size())/6.0)))
	var files:=ceili(float(figures.size())/float(ranks))
	var gap_x:=clampf((w*0.30)/maxf(1.0,float(files)),9.0,20.0)
	var gap_y:=15.0
	var base_y:=h*0.52
	var middle:=w*0.5
	var start_front:=middle-dir*w*0.36
	var met_front:=middle-dir*10.0
	var close:=_ease(clampf(t/CLOSE_END,0.0,1.0))
	var front:=lerpf(start_front,met_front,close)
	var settle:=clampf((t-CLASH_END)/(1.0-CLASH_END),0.0,1.0)
	var won:=winner==key
	var lost:=winner!="" and not won
	# The side that held the ground steps into it; a beaten one gives way.
	if won: front+=dir*18.0*_ease(settle)
	elif lost: front-=dir*26.0*_ease(settle)
	for i in figures.size():
		var file:=i/ranks
		var rank:=i%ranks
		var status:=String(figures[i])
		var p:=Vector2(front-dir*float(file)*gap_x-dir*float(rank)*3.0,base_y+float(rank)*gap_y-float(ranks-1)*gap_y*0.5+float(file%2)*2.0)
		var col:Color=ink[key]
		var angle:=0.0
		var height:=16.0
		var alpha:=1.0
		var stride:=0.0
		if t<CLOSE_END: stride=sin(t*48.0+float(i))*2.2
		elif t<CLASH_END or (live and status=="standing"):
			if file==0: p.x+=sin(t*70.0+float(i)*1.3)*1.8
		# Each fate is played out after the clash; a live fight shows only
		# the fallen and hurt so far.
		var fate:=settle if not live else (1.0 if t>=CLOSE_END else 0.0)
		match status:
			"killed":
				angle=-dir*PI*0.5*_ease(clampf(fate*2.0,0.0,1.0))
				col=col.darkened(0.25);alpha=0.9
			"wounded":
				height=lerpf(16.0,10.0,_ease(clampf(fate*2.0,0.0,1.0)))
			"fled":
				if not live:
					p.x-=dir*w*0.55*_ease(fate)
					alpha=1.0-0.8*fate
					stride=sin(t*60.0+float(i))*2.4*fate
			"captured":
				if not live:
					var to:=Vector2(middle+dir*(24.0+float(i%4)*9.0),base_y+26.0+float(i/4)*6.0)
					p=p.lerp(to,_ease(fate))
					height=lerpf(16.0,9.0,_ease(fate))
		_figure(p,dir,height,angle,Color(col,alpha),stride,status=="captured" and fate>0.6 and not live,ink["left" if key=="right" else "right"])


## An ink figure standing at p (its feet), facing dir, height h, turned by
## angle about its feet (the fallen lie down). A captive has a loop of cord
## in its captor's ink.
func _figure(p:Vector2,dir:float,h:float,angle:float,col:Color,stride:float,bound:=false,captor:=Color.BLACK)->void:
	var rot:=Transform2D(angle,p)
	var head:=rot*Vector2(0,-h)
	var neck:=rot*Vector2(0,-h+3.0)
	var hip:=rot*Vector2(0,-h*0.42)
	var foot_a:=rot*Vector2(-2.6+stride,0)
	var foot_b:=rot*Vector2(2.6-stride,0)
	var hand:=rot*Vector2(dir*4.5,-h*0.62)
	var spear_back:=rot*Vector2(-dir*3.0,-h*0.36)
	var spear_tip:=rot*Vector2(dir*9.0,-h*1.2)
	draw_line(spear_back,spear_tip,Color(col,col.a*0.9),1.2,true)
	draw_line(neck,hip,col,1.9,true)
	draw_line(hip,foot_a,col,1.6,true)
	draw_line(hip,foot_b,col,1.6,true)
	draw_line(rot*Vector2(0,-h*0.78),hand,col,1.4,true)
	draw_circle(head,2.7,col)
	if bound: draw_arc(rot*Vector2(0,-h*0.6),3.2,0.0,TAU,10,captor,1.2,true)


## Blows struck along the line where the bands meet.
func _draw_blows(w:float,h:float)->void:
	var rng:=RandomNumberGenerator.new();rng.seed=int(t*18.0)
	var middle:=w*0.5
	for i in 5:
		var y:=h*0.52+rng.randf_range(-20,20)
		var x:=middle+rng.randf_range(-7,7)
		var len:=rng.randf_range(4,8)
		draw_line(Vector2(x-len,y-len),Vector2(x+len,y+len),Color(T.INK,0.55),1.3,true)
		draw_line(Vector2(x+len*0.6,y-len*0.8),Vector2(x-len*0.4,y+len*0.9),Color(T.INK,0.35),1.0,true)


## "Each mark is five" when a band is larger than its marks.
func _draw_scale(w:float,h:float)->void:
	var parts:PackedStringArray=[]
	for key in ["left","right"]:
		if int(per_mark[key])>1: parts.append("each %s mark is about %d" % ["left-hand" if key=="left" else "right-hand",int(per_mark[key])])
	if parts.is_empty(): return
	var said:="; ".join(parts)
	draw_string(T.font("ui"),Vector2(8,h-8),said.substr(0,1).to_upper()+said.substr(1)+".",HORIZONTAL_ALIGNMENT_LEFT,w-16,11,T.INK_MUTED)


static func _ease(x:float)->float:
	return 1.0-pow(1.0-clampf(x,0.0,1.0),3.0)
