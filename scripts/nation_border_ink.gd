extends RefCounted
## THE INK OF THE NATION BORDERS (nation_borders.gd): the meeting lines the
## partition finds, drawn as an inked chart draws them. Every width is held in
## screen pixels at any zoom (nation_border_ink.gdshader, like the scouts'
## chart ink), so a zoom within the view's step never redraws a line.
##   Frontier: a fine ink spine edged on each side in that people's colour
##   (a little ink in it), over a soft band of the same colour; all of it
##   thins and fades where the two claims grow weak and tapers away at the
##   line's open ends, so a frontier dissolves into open land.
##   State: one crisp line of ink with a narrow edge and a band of each
##   side's colour, unbroken and even from end to end; only the bands soften
##   over a few pixels where the line ends.
##   War: a soft red underlay along the whole meeting line with the enemy.
## Pure: builds ink arrays from data, so it runs on the worker with the
## partition.

const Stroke:=preload("res://scripts/scout_chart_stroke.gd")

## Widths below are design pixels of a view this many pixels high.
const VIEW_PX:=900.0
const INK:=Color("#2b2118")
const WAR:=Color("#c9574a")
## A frontier is fully drawn where both claims score at least this at the line.
const STRENGTH_FULL:=0.30
## Open ends taper over this many pixels, and never over more than a third of
## the line.
const TAPER_PX:=46.0
## A state line's colour bands soften over these few pixels where it ends, so
## they do not stop as a cut rectangle; its ink stays crisp to the end.
const STATE_FEATHER_PX:=6.0
## How far the ink sits above the ground, as a share of the view.
const CLEARANCE:=0.0008


## Opacity at each point of a line. A frontier follows the claims' strength
## (its line fades where the claims thin out) and tapers at its open ends; a
## state line is even throughout; `strength_matters` false gives the taper only.
static func profile(line:Dictionary,px:float,strength_matters:=true,taper_px:=TAPER_PX)->PackedFloat32Array:
	var points:PackedVector2Array=line.points
	var strength:PackedFloat32Array=line.get("strength",PackedFloat32Array())
	var out:=PackedFloat32Array()
	out.resize(points.size())
	out.fill(1.0)
	if String(line.get("kind",""))=="state" and strength_matters: return out
	var arcs:=Stroke.arc_lengths(points)
	var total:=arcs[arcs.size()-1]
	var taper:=minf(taper_px*px,total/3.0)
	for i in points.size():
		var alpha:=1.0
		if strength_matters and i<strength.size(): alpha=smoothstep(0.0,STRENGTH_FULL,strength[i])
		if taper>0.0:
			if bool(line.get("open_start",false)): alpha*=smoothstep(0.0,taper,arcs[i])
			if bool(line.get("open_end",false)): alpha*=smoothstep(0.0,taper,total-arcs[i])
		out[i]=alpha
	return out


## Unit normals pointing to each point's left (the lower-numbered people's side).
static func normals(points:PackedVector2Array,closed:=false)->PackedVector2Array:
	var out:=PackedVector2Array()
	var count:=points.size()
	for i in count:
		var before:=points[i-1] if i>0 else (points[count-2] if closed and count>2 else points[i])
		var after:=points[i+1] if i<count-1 else (points[1] if closed and count>2 else points[i])
		var direction:=(after-before).normalized()
		out.append(Vector2(-direction.y,direction.x))
	return out


## A strip along a line across `offsets` (design pixels, positive on the
## left) in `colors`, one column between each pair; each point's opacity is
## scaled by alphas[i] and its offsets by widths[i].
static func strip(ink:Stroke.Ink,points:PackedVector2Array,ground:PackedFloat32Array,sides:PackedVector2Array,arcs:PackedFloat32Array,alphas:PackedFloat32Array,widths:PackedFloat32Array,offsets:PackedFloat32Array,colors:PackedColorArray,px:float)->void:
	for i in points.size()-1:
		var a0:=alphas[i]
		var a1:=alphas[i+1]
		if a0<=0.003 and a1<=0.003: continue
		var p0:=Vector3(points[i].x,ground[i],points[i].y)
		var p1:=Vector3(points[i+1].x,ground[i+1],points[i+1].y)
		var w0:=widths[i]*px
		var w1:=widths[i+1]*px
		for c in offsets.size()-1:
			var o00:=sides[i]*offsets[c]*w0
			var o01:=sides[i]*offsets[c+1]*w0
			var o10:=sides[i+1]*offsets[c]*w1
			var o11:=sides[i+1]*offsets[c+1]*w1
			var k00:=Color(colors[c],colors[c].a*a0)
			var k01:=Color(colors[c+1],colors[c+1].a*a0)
			var k10:=Color(colors[c],colors[c].a*a1)
			var k11:=Color(colors[c+1],colors[c+1].a*a1)
			ink.add(p0,o00,k00,arcs[i]);ink.add(p1,o10,k10,arcs[i+1]);ink.add(p1,o11,k11,arcs[i+1])
			ink.add(p0,o00,k00,arcs[i]);ink.add(p1,o11,k11,arcs[i+1]);ink.add(p0,o01,k01,arcs[i])


## The ink of every line for a view `view_km` high: [war, colour, line] Ink.
## lines: the partition's, each with "kind" ("frontier", "state" or "" for
## none) and "war" ("" or "war"/"feud" for a line with our enemy);
## colors: each people's colour by owner index.
static func build(lines:Array,colors:Array,view_km:float)->Array:
	var px:=maxf(view_km,0.000001)/VIEW_PX
	var war_ink:=Stroke.Ink.new(view_km)
	var colour_ink:=Stroke.Ink.new(view_km)
	var line_ink:=Stroke.Ink.new(view_km)
	var lift:=view_km*CLEARANCE
	for line:Dictionary in lines:
		var points:PackedVector2Array=line.points
		if points.size()<2: continue
		var kind:=String(line.get("kind",""))
		var war:=String(line.get("war",""))
		if kind=="" and war=="": continue
		var ground:=PackedFloat32Array()
		for h in (line.heights as PackedFloat32Array): ground.append(h+lift)
		var sides:=normals(points,bool(line.get("closed",false)))
		var arcs:=Stroke.arc_lengths(points)
		var color_a:Color=colors[int(line.a)] if int(line.a)<colors.size() else INK
		var color_b:Color=colors[int(line.b)] if int(line.b)<colors.size() else INK
		var ones:=PackedFloat32Array()
		ones.resize(points.size())
		ones.fill(1.0)
		if war!="":
			# The whole meeting line with the enemy, tapering only where it ends in open land.
			var lit:=profile(line,px,false)
			strip(war_ink,points,ground,sides,arcs,lit,ones,PackedFloat32Array([0.0,2.0,6.5]),PackedColorArray([Color(WAR,0.50 if war=="war" else 0.40),Color(WAR,0.32 if war=="war" else 0.25),Color(WAR,0.0)]),px)
			strip(war_ink,points,ground,sides,arcs,lit,ones,PackedFloat32Array([0.0,-2.0,-6.5]),PackedColorArray([Color(WAR,0.50 if war=="war" else 0.40),Color(WAR,0.32 if war=="war" else 0.25),Color(WAR,0.0)]),px)
		if kind=="state":
			# Crisp and even: each side's colour as a band within its own land,
			# a narrow inked edge of it, and one line of ink between them.
			var feather:=profile(line,px,false,STATE_FEATHER_PX)
			for side in [[color_a,1.0],[color_b,-1.0]]:
				var tint:Color=side[0]
				var facing:float=side[1]
				strip(colour_ink,points,ground,sides,arcs,feather,ones,PackedFloat32Array([0.9*facing,2.2*facing,8.5*facing]),PackedColorArray([Color(tint,0.62),Color(tint,0.42),Color(tint,0.0)]),px)
				strip(line_ink,points,ground,sides,arcs,feather,ones,PackedFloat32Array([0.7*facing,1.25*facing,1.8*facing]),PackedColorArray([Color(tint.lerp(INK,0.25),0.25),Color(tint.lerp(INK,0.25),0.85),Color(tint.lerp(INK,0.25),0.2)]),px)
			strip(line_ink,points,ground,sides,arcs,ones,ones,PackedFloat32Array([-0.95,0.0,0.95]),PackedColorArray([Color(INK,0.3),Color(INK,0.95),Color(INK,0.3)]),px)
		elif kind=="frontier":
			# Fine, in each people's own colour on its own side, fading with the claims.
			var alphas:=profile(line,px)
			var widths:=PackedFloat32Array()
			for alpha in alphas: widths.append(lerpf(0.45,1.0,alpha))
			for side in [[color_a,1.0],[color_b,-1.0]]:
				var tint:Color=side[0]
				var facing:float=side[1]
				var inked:=tint.lerp(INK,0.32)
				# A soft band of the people's colour along its own side.
				strip(colour_ink,points,ground,sides,arcs,alphas,widths,PackedFloat32Array([0.5*facing,1.6*facing,6.5*facing]),PackedColorArray([Color(tint,0.42),Color(tint,0.30),Color(tint,0.0)]),px)
				# A fine ink spine shared down the middle, edged on each side in
				# that people's colour: legible on olive, ochre and forest alike.
				strip(line_ink,points,ground,sides,arcs,alphas,widths,PackedFloat32Array([0.0,0.45*facing,1.15*facing,1.75*facing]),PackedColorArray([Color(INK,0.5),Color(inked,0.95),Color(inked,0.75),Color(inked,0.0)]),px)
	return [war_ink,colour_ink,line_ink]
