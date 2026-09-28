extends RefCounted
## BATTLE MARKS: how a battle, a force's counter and its state are inked on
## the war chart.
##
## A battle is a small crossed-weapons mark standing on the front where the
## two sides touch (spears before the lettered ages, swords after), with a
## two-colour bar in the sides' colours: the split sits at the middle when
## neither side gives ground and moves toward whoever is being pushed back.
## Beneath it the chart letters where and how long ("Tsaren · day 2"). A
## pointer resting on it gets one plain line ("We are pushing them back ·
## 340 against 280"). Far out, battles close together stand as one mark
## ("2 battles").
##
## A force's counter (hud/army_marks.gd) gains two thin bars under its mark,
## strength (men against its full strength) and will to fight (morale), and
## one state glyph at its shoulder: marching, holding, besieging, fighting,
## broken or hungry.
##
## Words and layout are pure and static; the drawing helpers take the canvas
## item that is drawing (the war-front overlay), so everything stays on the
## overlay's one canvas path.

const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
const OXBLOOD:=Color("#8e3b2e")
const OCHRE:=Color("#a8782a")
const VERDIGRIS:=Color("#3f6f63")
## Battle marks and bars, in screen pixels.
const MARK_RADIUS:=11.0
const BAR_WIDTH:=40.0
const BAR_HEIGHT:=6.0
const LABEL_SIZE:=14
## Battles closer than this on screen stand as one mark far out.
const CLUSTER_PX:={"continental":52.0,"world":64.0}
## A battle within this share of the front's own scale stands on the front.
const SNAP_SIGMA:=0.9
## How far along the front a battle heats the worm (share of sigma).
const HEAT_SIGMA:=0.45
const STATES:=["marching","holding","besieging","fighting","broken","hungry"]


# --- Words ------------------------------------------------------------------------------

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


## A people as a sentence names them ("the Esurai", or "strangers").
static func people(name:String)->String:
	var clean:=name.strip_edges()
	if clean=="" or clean.to_lower() in ["strangers","their","they"]: return "strangers"
	return clean if clean.to_lower().begins_with("the ") else "the %s" % clean


## Ours exactly (we count our own), theirs the way a watcher would guess.
static func count(n:int,exact:bool)->String:
	if n<=0: return "none"
	if exact: return EraWords.grouped(n)
	return ArmyMarks.about(n).trim_prefix("about ")


## Who is getting the better of it, in plain words.
static func push_words(battle:Dictionary)->String:
	var progress:=clampf(float(battle.get("progress",0.0)),-1.0,1.0)
	var sides:Dictionary=battle.get("sides",{})
	if String(battle.get("kind",""))=="siege":
		if String(battle.get("status",""))=="besieged": return "They have us shut in" if progress>-0.5 else "They have us close to giving in"
		if progress>=0.6: return "They are close to giving in"
		if progress>=0.25: return "The siege is biting"
		return "The walls still hold"
	if bool(battle.get("ours",false)):
		if progress>=0.5: return "We are driving them back"
		if progress>=0.15: return "We are pushing them back"
		if progress>-0.15: return "Neither side gives ground"
		if progress>-0.5: return "They are pushing us back"
		return "They are driving us back"
	var a:=people(String((sides.get("a",{}) as Dictionary).get("name","")))
	var b:=people(String((sides.get("b",{}) as Dictionary).get("name","")))
	if a==b: return "Strangers are fighting each other"
	if progress>=0.15: return "%s are pushing %s back" % [_cap(a),b]
	if progress<=-0.15: return "%s are pushing %s back" % [_cap(b),a]
	return "%s and %s: neither gives ground" % [_cap(a),b]


## The one line shown while the pointer rests on a battle.
static func hover_line(battle:Dictionary)->String:
	var sides:Dictionary=battle.get("sides",{})
	var a:Dictionary=sides.get("a",{}); var b:Dictionary=sides.get("b",{})
	var ours:=bool(battle.get("ours",false))
	var push:=push_words(battle)
	var age:=int(battle.get("age_days",0))
	if String(battle.get("kind",""))=="siege":
		var here:=int(a.get("troops",0))
		if String(battle.get("status",""))=="besieged": return push
		return "%s · %s of ours outside the walls" % [push,count(here,true)] if here>0 else push
	var numbers:=""
	if int(a.get("troops",0))>0 and int(b.get("troops",0))>0:
		numbers=" · %s against %s" % [count(int(a.troops),ours),count(int(b.troops),false)]
	if age>0: return "%s%s · seen %s" % [push,numbers,"yesterday" if age==1 else "%s days ago" % EraWords.count_word(age)]
	return push+numbers


## What the chart letters under a battle ("Tsaren · day 2").
static func label(battle:Dictionary)->String:
	var place:=String(battle.get("place_name",""))
	var age:=int(battle.get("age_days",0))
	var day:=maxi(1,int(battle.get("day",1)))
	if String(battle.get("kind",""))=="siege":
		if String(battle.get("status",""))=="besieged": return "%s besieged · day %d" % [place,day]
		return "Siege of %s · day %d" % [place.trim_prefix("Near "),day]
	if age>0: return "%s · seen %s" % [place,"yesterday" if age==1 else "%s days ago" % EraWords.count_word(age)]
	return "%s · day %d" % [place,day] if place!="" else "Day %d" % day


static func aggregate_label(n:int)->String:
	return "%s battles" % EraWords.grouped(n) if n!=1 else "1 battle"


## Where the bar splits, as a share of its width from the left (side a's
## end): the middle when neither gives ground, toward b as a pushes.
static func bar_split(progress:float)->float:
	return clampf(0.5+0.5*progress,0.0,1.0)


# --- Where each battle stands -----------------------------------------------------------

## The nearest point of any front to `at`: {front, index (segment), t, point,
## distance}, or {} when there is no front.
static func nearest_on_fronts(at:Vector2,fronts:Array)->Dictionary:
	var best:={}
	var best_d:=INF
	for f in fronts.size():
		var points:PackedVector2Array=(fronts[f] as Dictionary).get("points",PackedVector2Array())
		for i in range(1,points.size()):
			var p:=Geometry2D.get_closest_point_to_segment(at,points[i-1],points[i])
			var d:=p.distance_to(at)
			if d<best_d:
				best_d=d
				var span:=points[i-1].distance_to(points[i])
				best={"front":f,"index":i-1,"t":points[i-1].distance_to(p)/span if span>0.0 else 0.0,"point":p,"distance":d}
	return best


## Our battles stand on the front at their contact point when a front runs
## close by (a rival's battle stands where it is fought). Adds pos (world),
## front (index or -1), vertex, words.
static func place(battles:Array,fronts:Array,sigma:float)->Array:
	var out:Array=[]
	for battle_variant in battles:
		var battle:Dictionary=(battle_variant as Dictionary).duplicate()
		var at:Vector2=battle.get("pos",Vector2(float(battle.get("x",0.0)),float(battle.get("z",0.0))))
		battle["pos"]=at
		battle["front"]=-1
		if bool(battle.get("ours",false)) and String(battle.get("kind",""))!="siege":
			var near:=nearest_on_fronts(at,fronts)
			if not near.is_empty() and float(near.distance)<=sigma*SNAP_SIGMA:
				battle["pos"]=near.point
				battle["front"]=int(near.front)
				battle["vertex"]=int(near.index)+(1 if float(near.t)>0.5 else 0)
		battle["label"]=label(battle)
		battle["hover"]=hover_line(battle)
		out.append(battle)
	return out


## How hard each vertex of a front is being fought for (0..1): our battles
## standing on it heat it, fading along the line. Skirmishes do not.
static func heat(points:PackedVector2Array,battles:Array,front_index:int,sigma:float)->PackedFloat32Array:
	var out:=PackedFloat32Array()
	out.resize(points.size())
	var reach:=maxf(0.0001,sigma*HEAT_SIGMA)
	for battle in battles:
		if int(battle.get("front",-1))!=front_index or bool(battle.get("skirmish",false)) or int(battle.get("age_days",0))>0: continue
		var at:Vector2=battle.pos
		for i in points.size():
			var d:=points[i].distance_to(at)/reach
			if d>3.0: continue
			out[i]=maxf(out[i],exp(-d*d))
	return out


## Battles near one another on screen stand as one mark far out. entries:
## [{at, battle}] in priority order. Returns [{at, members:[entries],
## progress, ours, troops}]; ours and rivals' are never joined.
static func cluster(entries:Array,radius:float)->Array:
	var groups:Array=[]
	for entry in entries:
		var ours:=bool((entry.battle as Dictionary).get("ours",false))
		var joined:=false
		for group in groups:
			if bool(group.ours)==ours and (group.at as Vector2).distance_to(entry.at)<=radius:
				(group.members as Array).append(entry); joined=true; break
		if not joined: groups.append({"at":entry.at,"members":[entry],"ours":ours})
	for group in groups:
		var weight:=0.0; var sum:=0.0; var troops:=0
		for entry in group.members:
			var battle:Dictionary=entry.battle
			var sides:Dictionary=battle.get("sides",{})
			var men:=int((sides.get("a",{}) as Dictionary).get("troops",0))+int((sides.get("b",{}) as Dictionary).get("troops",0))
			troops+=men
			var w:=maxf(1.0,float(men))
			sum+=float(battle.get("progress",0.0))*w; weight+=w
		group["progress"]=sum/weight if weight>0.0 else 0.0
		group["troops"]=troops
	return groups


# --- Counters and states -----------------------------------------------------------------

## One state for a force's glyph, the most pressing first.
static func state_of(context:Dictionary)->String:
	if bool(context.get("broken",false)): return "broken"
	if bool(context.get("fighting",false)): return "fighting"
	if bool(context.get("hungry",false)): return "hungry"
	if String(context.get("besieging",""))!="": return "besieging"
	if String(context.get("status",""))=="moving" or bool(context.get("withdrawing",false)): return "marching"
	return "holding"


static func state_words(state:String)->String:
	return String({"marching":"on the march","holding":"holding","besieging":"besieging","fighting":"in battle","broken":"broken","hungry":"short of food"}.get(state,""))


# --- Drawing (on the overlay's own canvas) -------------------------------------------------

## Crossed spears (before the lettered ages) or crossed swords, r = half size.
## Both weapons' paper halos are laid first, then both in ink, so the
## crossing reads as one inked mark.
static func draw_weapons(canvas:CanvasItem,at:Vector2,r:float,era:int,ink:Color,halo:Color)->void:
	var w:=maxf(1.8,r*0.2)
	for pass_index in (2 if halo.a>0.0 else 1):
		var inking:=pass_index==1 or halo.a<=0.0
		var colour:=ink if inking else halo
		var grow:=0.0 if inking else 3.0
		for side in [-1.0,1.0]:
			var hilt:=at+Vector2(-0.86*side,0.86)*r
			var tip:=at+Vector2(0.86*side,-0.86)*r
			var along:=(tip-hilt).normalized()
			var across:=along.orthogonal()
			if era<=0:
				# A spear: a long shaft and a leaf-shaped head.
				var neck:=tip-along*r*0.46
				canvas.draw_line(hilt-along*r*0.12,neck,colour,w*0.9+grow,true)
				var head:=PackedVector2Array([tip+along*r*(0.1+grow*0.05),neck+across*(r*0.24+grow*0.5),neck-along*(r*0.06+grow*0.5),neck-across*(r*0.24+grow*0.5)])
				canvas.draw_colored_polygon(head,colour)
			else:
				# A sword: blade, cross-guard, grip and pommel.
				var guard:=hilt+along*r*0.38
				canvas.draw_line(guard,tip,colour,w+grow,true)
				canvas.draw_line(guard-across*r*0.34,guard+across*r*0.34,colour,w*0.95+grow,true)
				canvas.draw_line(hilt+along*r*0.06,guard,colour,w*0.85+grow,true)
				canvas.draw_circle(hilt,w*0.9+grow*0.5,colour)


## The two-colour bar: side a from the left, side b from the right, the
## split moved from the middle by progress; a fine tick marks where it began.
static func draw_bar(canvas:CanvasItem,rect:Rect2,progress:float,a:Color,b:Color,alpha:float=1.0)->void:
	canvas.draw_rect(rect.grow(1.5),Color(PAPER,0.92*alpha))
	var split:=rect.position.x+rect.size.x*bar_split(progress)
	if split>rect.position.x: canvas.draw_rect(Rect2(rect.position,Vector2(split-rect.position.x,rect.size.y)),Color(a,alpha))
	if split<rect.end.x: canvas.draw_rect(Rect2(Vector2(split,rect.position.y),Vector2(rect.end.x-split,rect.size.y)),Color(b,alpha))
	var mid:=rect.position.x+rect.size.x*0.5
	canvas.draw_line(Vector2(mid,rect.position.y-2.0),Vector2(mid,rect.end.y+2.0),Color(INK,0.75*alpha),1.0,true)
	canvas.draw_rect(rect,Color(INK,0.85*alpha),false,1.0)


## Lettering straight on the chart: ink with a solid paper halo.
static func letter(canvas:CanvasItem,font:Font,at:Vector2,text:String,size:int,color:Color,alpha:float=1.0)->void:
	canvas.draw_string_outline(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,6,Color(PAPER,0.96*alpha))
	canvas.draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(color,alpha))


## A battle mark at `at`: the crossed weapons over a soft paper ground, the
## bar below. Returns the rect it covers (for hits and lettering clearance).
static func draw_battle(canvas:CanvasItem,at:Vector2,battle:Dictionary,era:int,scale:float=1.0,alpha:float=1.0)->Rect2:
	var sides:Dictionary=battle.get("sides",{})
	var r:=MARK_RADIUS*scale
	var seen_before:=int(battle.get("age_days",0))>0
	var fade:=alpha*(0.6 if seen_before else 1.0)
	canvas.draw_circle(at,r+2.0,Color(PAPER,0.7*fade))
	var ink:=Color(INK,fade) if bool(battle.get("ours",false)) else Color(INK.lerp(OXBLOOD,0.4),fade)
	draw_weapons(canvas,at,r,era,ink,Color(PAPER,0.95*fade))
	var width:=BAR_WIDTH*maxf(0.75,scale)
	var bar:=Rect2(at+Vector2(-width*0.5,r+5.0),Vector2(width,BAR_HEIGHT))
	draw_bar(canvas,bar,float(battle.get("progress",0.0)),(sides.get("a",{}) as Dictionary).get("colour",PAPER),(sides.get("b",{}) as Dictionary).get("colour",OXBLOOD),fade)
	return Rect2(at-Vector2(maxf(r+3.0,width*0.5),r+3.0),Vector2(maxf(r+3.0,width*0.5)*2.0,r*2.0+9.0+BAR_HEIGHT))


## Many battles in one place, far out: the weapons with a count beside them.
static func draw_cluster(canvas:CanvasItem,at:Vector2,group:Dictionary,era:int,font:Font)->Rect2:
	var members:Array=group.members
	var first:Dictionary=(members[0] as Dictionary).battle
	var shown:=first.duplicate()
	shown["progress"]=float(group.get("progress",0.0))
	var rect:=draw_battle(canvas,at,shown,era,0.9)
	var badge:=at+Vector2(MARK_RADIUS+6.0,-MARK_RADIUS)
	canvas.draw_circle(badge,8.0,Color(PAPER,0.96))
	canvas.draw_arc(badge,8.0,0.0,TAU,18,Color(INK,0.8),1.0,true)
	var text:=str(members.size())
	var w:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	canvas.draw_string(font,badge+Vector2(-w*0.5,4.5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)
	return rect.merge(Rect2(badge-Vector2(8,8),Vector2(16,16)))


## Two thin bars under a force's mark: strength (men against full strength)
## and will to fight. A will range (low..high) is drawn for a force known
## only by sight: an uncertain band, never a false figure.
static func draw_counter(canvas:CanvasItem,top_left:Vector2,width:float,counter:Dictionary,side:Color,alpha:float=1.0)->void:
	var h:=3.0
	var has_strength:=counter.has("strength")
	var has_will:=counter.has("will") or counter.has("will_low")
	if not has_strength and not has_will: return
	var rows:=int(has_strength)+int(has_will)
	var plate:=Rect2(top_left-Vector2(1.5,1.5),Vector2(width+3.0,float(rows)*(h+1.5)+1.5))
	canvas.draw_rect(plate,Color(PAPER,0.9*alpha))
	var y:=top_left.y
	if has_strength:
		var share:=clampf(float(counter.strength),0.0,1.0)
		canvas.draw_rect(Rect2(Vector2(top_left.x,y),Vector2(width,h)),Color(INK,0.18*alpha))
		if share>0.0: canvas.draw_rect(Rect2(Vector2(top_left.x,y),Vector2(width*share,h)),Color(side.darkened(0.15),alpha))
		y+=h+1.5
	if has_will:
		canvas.draw_rect(Rect2(Vector2(top_left.x,y),Vector2(width,h)),Color(INK,0.18*alpha))
		if counter.has("will"):
			var will:=clampf(float(counter.will),0.0,1.0)
			var tone:=OXBLOOD if will<0.3 else OCHRE
			if will>0.0: canvas.draw_rect(Rect2(Vector2(top_left.x,y),Vector2(width*will,h)),Color(tone,alpha))
		else:
			var low:=clampf(float(counter.get("will_low",0.0)),0.0,1.0); var high:=clampf(float(counter.get("will_high",low)),low,1.0)
			if low>0.0: canvas.draw_rect(Rect2(Vector2(top_left.x,y),Vector2(width*low,h)),Color(OCHRE,alpha))
			if high>low: canvas.draw_rect(Rect2(Vector2(top_left.x+width*low,y),Vector2(width*(high-low),h)),Color(OCHRE,0.4*alpha))
	canvas.draw_rect(plate,Color(INK,0.55*alpha),false,1.0)


## The state glyph on a paper disc at a mark's shoulder. heading: the
## direction of march on screen (for "marching").
static func draw_state(canvas:CanvasItem,at:Vector2,state:String,r:float,alpha:float=1.0,heading:Vector2=Vector2.RIGHT)->void:
	canvas.draw_circle(at,r+1.5,Color(PAPER,0.95*alpha))
	canvas.draw_arc(at,r+1.5,0.0,TAU,16,Color(INK,0.5*alpha),1.0,true)
	var ink:=Color(INK,alpha)
	var red:=Color(OXBLOOD,alpha)
	var w:=maxf(1.2,r*0.24)
	match state:
		"marching":
			var ahead:=heading.normalized() if heading.length()>0.001 else Vector2.RIGHT
			var side:=ahead.orthogonal()
			for k in 2:
				var tip:=at+ahead*r*(0.15+0.45*float(k))-ahead*r*0.25
				canvas.draw_polyline(PackedVector2Array([tip-ahead*r*0.4+side*r*0.45,tip,tip-ahead*r*0.4-side*r*0.45]),ink,w,true)
		"holding":
			canvas.draw_line(at+Vector2(-r*0.62,r*0.25),at+Vector2(r*0.62,r*0.25),ink,w,true)
			for x in [-0.4,0.0,0.4]: canvas.draw_line(at+Vector2(r*x,r*0.25),at+Vector2(r*x,-r*0.45),ink,w*0.8,true)
		"besieging":
			canvas.draw_arc(at,r*0.42,0.0,TAU,14,ink,w*0.9,true)
			for k in 4:
				var d:=Vector2.from_angle(TAU*float(k)/4.0+PI*0.25)
				canvas.draw_line(at+d*r*0.42,at+d*r*0.8,ink,w*0.8,true)
		"fighting":
			canvas.draw_line(at+Vector2(-r*0.55,-r*0.55),at+Vector2(r*0.55,r*0.55),red,w,true)
			canvas.draw_line(at+Vector2(-r*0.55,r*0.55),at+Vector2(r*0.55,-r*0.55),red,w,true)
		"broken":
			canvas.draw_polyline(PackedVector2Array([at+Vector2(-r*0.7,-r*0.1),at+Vector2(-r*0.2,r*0.35),at+Vector2(-r*0.05,-r*0.35)]),red,w,true)
			canvas.draw_polyline(PackedVector2Array([at+Vector2(r*0.15,r*0.3),at+Vector2(r*0.3,-r*0.2),at+Vector2(r*0.7,r*0.15)]),red,w,true)
		"hungry":
			canvas.draw_arc(at+Vector2(0,-r*0.15),r*0.55,0.0,PI,12,Color(OCHRE.darkened(0.25),alpha),w,true)
			canvas.draw_line(at+Vector2(-r*0.62,-r*0.15),at+Vector2(r*0.62,-r*0.15),Color(OCHRE.darkened(0.25),alpha),w,true)
