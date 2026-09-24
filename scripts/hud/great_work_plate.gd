extends Control
## A drawn elevation of a great work: sky, ground and the work's silhouette by
## its conceived form (tower, stair, dam, colossus, garden…), in its material.
## Presentation only. It shows planned-but-unbuilt height as a ghost outline
## with scaffolding, ruins broken and low, and dedicated works with a halo.
## Legacy founding works use their painted design study when one exists.

const Art:=preload("res://scripts/hud/undertaking_art.gd")
const MATERIAL_COLORS:={"stone":Color("a89a80"),"brick":Color("a8674a"),"timber":Color("8a6a46"),"earth":Color("b08a5a"),"iron":Color("5d6266"),"concrete":Color("b9b6ac")}
const ALIASES:={"terrace":"stair","basin":"cistern","orchard":"garden","library":"archive","statue":"colossus","arch":"gate","amphitheater":"amphitheatre","kilns":"kilns"}

var shape:="hall"
var building_material:="stone"
var progress:=1.0          ## 0..1 of the planned height raised
var state:="standing"      ## "building" | "standing" | "flawed" | "triumph" | "ruined" | "abandoned"
var glow:=0.0              ## 0..1 halo for dedicated works
var legacy_id:=""          ## legacy catalog id with a painted plate
var variant:=0
var night:=false
var _clock:=0.0
var _plate:TextureRect

static func make(work:Dictionary,height:float=160.0)->Control:
	## work: a works() summary, site record or concept (shape/form/visual/material/status/outcome/progress).
	var plate:Control=load("res://scripts/hud/great_work_plate.gd").new()
	plate.configure(work)
	plate.custom_minimum_size=Vector2(height*1.5,height)
	return plate

func configure(work:Dictionary)->void:
	var id:=String(work.get("work_id",work.get("id","")))
	var parsed:=id.split(":")
	shape=String(work.get("shape",""))
	if shape.is_empty() and parsed.size()==7 and parsed[0]=="wonder":shape=parsed[1]
	if shape.is_empty():shape=String(work.get("form",work.get("visual","hall")))
	shape=String(ALIASES.get(shape,shape))
	building_material=String(work.get("material",""))
	if building_material.is_empty() and parsed.size()==7:building_material=parsed[4]
	if building_material.is_empty():building_material="stone"
	var status:=String(work.get("status",""))
	var outcome:=String(work.get("outcome",""))
	if status in ["ruined","collapse","collapsed","folly"] or outcome=="collapse":state="ruined"
	elif status=="abandoned" or outcome=="abandoned":state="abandoned"
	elif status in ["building","stalled"]:state="building"
	elif outcome in ["flawed","triumph"]:state=outcome
	else:state="standing"
	progress=clampf(float(work.get("progress",work.get("fraction",1.0 if state in ["standing","flawed","triumph","ruined"] else 0.0))),0,1)
	if state in ["standing","flawed","triumph","ruined"]:progress=1.0
	legacy_id=id if parsed.size()!=7 else ""
	variant=absi(hash(id))%7
	glow=1.0 if int(work.get("dedicated_day",-1))>=0 and state in ["standing","flawed","triumph"] else 0.0
	queue_redraw()

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	if not legacy_id.is_empty() and state!="ruined":
		var texture:=Art.texture(legacy_id)
		if texture!=null:
			_plate=TextureRect.new();_plate.texture=texture;_plate.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_plate.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
			_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(_plate)

func _process(delta:float)->void:
	if glow>0.0 and is_visible_in_tree():
		_clock+=delta
		queue_redraw()

# ---------------------------------------------------------------- drawing

func _draw()->void:
	if is_instance_valid(_plate):
		if glow>0:_draw_frame_glow()
		return
	var w:=size.x;var h:=size.y
	if w<4 or h<4:return
	var ground:=h*.80
	# Sky: warm dawn, dusk for ruins.
	var top:=Color("e9dcc0") if not night else Color("211c33")
	var low:=Color("f6ecd6") if not night else Color("d38a4e")
	if state=="ruined":top=Color("c9bba4");low=Color("e2d6c0")
	_gradient(Rect2(0,0,w,ground),top,low)
	var sun:=Vector2(w*(.72 if variant%2==0 else .28),ground*.38)
	var pulse:=.5+.5*sin(_clock*1.6)
	if glow>0:
		for i in 7:
			var r:=h*(.62-.07*i)
			draw_circle(Vector2(w*.5,ground-h*.26),r,Color(1,.86,.52,(.05+.03*pulse)*glow))
		for i in 12:
			var a:=-PI*.5+(float(i)-5.5)*.19+sin(_clock*.4)*.02
			var p0:=Vector2(w*.5,ground-h*.3)
			draw_line(p0,p0+Vector2(cos(a),sin(a))*h*.9,Color(1,.9,.6,.10*glow*(.6+.4*pulse)),3.0,true)
	else:
		draw_circle(sun,h*.09,Color(1,.93,.78,.55 if state!="ruined" else .25))
	# Distant hills.
	var hills:=PackedVector2Array([Vector2(0,ground)])
	for i in 9:
		var x:=w*float(i)/8.0
		hills.append(Vector2(x,ground-h*(.05+.04*sin(float(i)*1.7+float(variant)))))
	hills.append(Vector2(w,ground))
	draw_colored_polygon(hills,Color("c7b894") if not night else Color("4a3a48"))
	# Ground.
	_gradient(Rect2(0,ground,w,h-ground),Color("a99870") if not night else Color("3a2e2a"),Color("8a7a58") if not night else Color("1e1816"))
	var base:Color=MATERIAL_COLORS.get(building_material,MATERIAL_COLORS.stone)
	if state=="abandoned" or state=="ruined":base=base.lerp(Color("8a8272"),.35)
	if night:base=base.lerp(Color("e8b070"),.25*glow).darkened(.15)
	var parts:=_parts(Vector2(w*.5,ground),h*.62)
	var cut:=ground-(ground-_top(parts))*progress
	for part:Array in parts:
		var poly:PackedVector2Array=part[0]
		var shade:float=float(part[1])
		var colour:=base.darkened(shade) if shade>=0 else base.lightened(-shade)
		if part.size()>2 and part[2] is Color:colour=part[2]
		if state=="ruined":poly=_ruin(poly,ground)
		if poly.size()>=3:draw_colored_polygon(poly,colour)
	if state=="building" and progress<.999:
		# Unraised height: sky over it, the plan as a ghost, scaffolds at the cut.
		_gradient(Rect2(0,0,w,cut),top,top.lerp(low,cut/maxf(1,ground)))
		for part:Array in parts:
			var outline:PackedVector2Array=(part[0] as PackedVector2Array).duplicate()
			outline.append(outline[0])
			draw_polyline(outline,Color(.35,.28,.18,.28),1.2,true)
		var span:=_span(parts)
		for i in range(0,6):
			var x:=lerpf(span.x-6,span.y+6,float(i)/5.0)
			draw_line(Vector2(x,ground),Vector2(x,cut-10),Color("6b5132"),2.0)
		draw_line(Vector2(span.x-10,cut-2),Vector2(span.y+10,cut-2),Color("6b5132"),2.5)
		draw_line(Vector2(span.x-10,cut+(ground-cut)*.5),Vector2(span.y+10,cut+(ground-cut)*.5),Color("6b5132",.8),2.0)
	if state=="ruined":
		for i in 18:
			var rx:=w*.5+(float((i*37+variant*11)%100)/100.0-.5)*w*.55
			draw_circle(Vector2(rx,ground+2+float(i%3)),2.0+float(i%4),base.darkened(.25))
	# Tiny people for scale.
	for i in 3:
		var px:=w*(.12+.08*float(i))+float(variant)
		draw_line(Vector2(px,ground+1),Vector2(px,ground-h*.045),Color("3a3026"),2.0)
		draw_circle(Vector2(px,ground-h*.05),1.8,Color("3a3026"))
	if glow>0:_draw_frame_glow()

func _draw_frame_glow()->void:
	var pulse:=.5+.5*sin(_clock*1.6)
	draw_rect(Rect2(Vector2.ZERO,size),Color(1,.82,.4,(.35+.25*pulse)*glow),false,2.0)

func _gradient(rect:Rect2,from:Color,to:Color)->void:
	draw_polygon(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),PackedColorArray([from,from,to,to]))

func _top(parts:Array)->float:
	var y:=INF
	for part:Array in parts:
		for p:Vector2 in part[0]:y=minf(y,p.y)
	return y

func _span(parts:Array)->Vector2:
	var lo:=INF;var hi:=-INF
	for part:Array in parts:
		for p:Vector2 in part[0]:lo=minf(lo,p.x);hi=maxf(hi,p.x)
	return Vector2(lo,hi)

func _ruin(poly:PackedVector2Array,ground:float)->PackedVector2Array:
	var out:=PackedVector2Array()
	var index:=0
	for p:Vector2 in poly:
		var height:=ground-p.y
		var keep:=.25+.35*float((index*7+variant)%5)/4.0
		out.append(Vector2(p.x+(ground-p.y)*.08,ground-height*keep))
		index+=1
	return out

func _box(cx:float,ground:float,bw:float,bh:float,lift:float=0.0)->PackedVector2Array:
	return PackedVector2Array([Vector2(cx-bw*.5,ground-lift),Vector2(cx+bw*.5,ground-lift),Vector2(cx+bw*.5,ground-lift-bh),Vector2(cx-bw*.5,ground-lift-bh)])

func _tri(cx:float,base_y:float,bw:float,bh:float)->PackedVector2Array:
	return PackedVector2Array([Vector2(cx-bw*.5,base_y),Vector2(cx+bw*.5,base_y),Vector2(cx,base_y-bh)])

## [[polygon, shade, colour?], …] around a ground anchor; H is the tallest reach.
func _parts(anchor:Vector2,H:float)->Array:
	var cx:=anchor.x;var g:=anchor.y
	var out:Array=[]
	match shape:
		"tower","lighthouse":
			out.append([_box(cx,g,H*.34,H*.12),.1])
			out.append([PackedVector2Array([Vector2(cx-H*.13,g-H*.12),Vector2(cx+H*.13,g-H*.12),Vector2(cx+H*.08,g-H*.88),Vector2(cx-H*.08,g-H*.88)]),0.0])
			for i in 4:out.append([_box(cx,g,H*.05,H*.06,H*(.25+.16*i)),.35])
			if shape=="lighthouse":
				out.append([_box(cx,g,H*.2,H*.08,H*.88),-.2,Color("f4d27a")])
				out.append([_tri(cx,g-H*.96,H*.24,H*.08),.2])
			else:
				out.append([_tri(cx,g-H*.88,H*.22,H*.14),.25])
		"stair","observatory":
			for i in 5:out.append([_box(cx,g,H*(1.25-.22*i),H*.12,H*.12*i),.05*i])
			if shape=="observatory":
				out.append([_box(cx,g,H*.2,H*.12,H*.6),.15])
				out.append([PackedVector2Array([Vector2(cx-H*.1,g-H*.72),Vector2(cx+H*.1,g-H*.72),Vector2(cx+H*.07,g-H*.8),Vector2(cx,g-H*.83),Vector2(cx-H*.07,g-H*.8)]),-.15])
		"ring","gate":
			if shape=="gate":
				out.append([_box(cx-H*.3,g,H*.2,H*.72),0.0])
				out.append([_box(cx+H*.3,g,H*.2,H*.72),0.0])
				out.append([_box(cx,g,H*.8,H*.16,H*.62),.12])
				out.append([_box(cx,g,H*.9,H*.06,H*.78),.2])
			else:
				for i in 9:
					var t:=float(i)/8.0
					var x:=cx+(t-.5)*H*1.5
					var depth:=absf(t-.5)
					out.append([_box(x,g-H*.03*(1-depth*2),H*.08,H*(.34-.1*depth)),.05+.2*depth])
				out.append([_box(cx,g,H*1.3,H*.05,H*.36),.15])
		"mound":
			var mound:=PackedVector2Array()
			for i in 17:
				var t:=float(i)/16.0
				mound.append(Vector2(cx+(t-.5)*H*1.6,g-sin(t*PI)*H*.5))
			out.append([mound,.05])
			out.append([_box(cx,g,H*.14,H*.12,H*.46),.2])
		"hall","archive","kilns":
			out.append([_box(cx,g,H*1.3,H*.36),0.0])
			out.append([_tri(cx,g-H*.36,H*1.45,H*.3),.25])
			for i in 7:out.append([_box(cx+(float(i)-3.0)*H*.18,g,H*.05,H*.34),.3])
			if shape=="archive":out.append([_box(cx,g,H*.32,H*.06,H*.66),.1])
			if shape=="kilns":
				for i in 4:out.append([_tri(cx+(float(i)-1.5)*H*.36,g-H*.36,H*.2,H*.28),.4])
		"cistern","canal","causeway":
			out.append([_box(cx,g,H*1.7,H*.16),.05])
			out.append([_box(cx,g,H*1.5,H*.04,H*.12),-.2,Color("6f9aa6") if shape!="causeway" else Color("9a8a66")])
			for i in 5:out.append([_box(cx+(float(i)-2.0)*H*.36,g,H*.08,H*.24),.2])
		"dam":
			out.append([PackedVector2Array([Vector2(cx-H*.9,g),Vector2(cx+H*.9,g),Vector2(cx+H*.75,g-H*.62),Vector2(cx-H*.75,g-H*.62)]),0.0])
			for i in 5:out.append([_box(cx+(float(i)-2.0)*H*.28,g,H*.07,H*.5,H*.04),-.12,Color("d7e6ea",.7)])
		"bridge":
			out.append([_box(cx,g,H*1.9,H*.08,H*.42),.05])
			for i in 3:
				var x:=cx+(float(i)-1.0)*H*.62
				out.append([_box(x,g,H*.12,H*.42),.12])
		"colossus":
			out.append([_box(cx,g,H*.5,H*.14),.1])
			out.append([PackedVector2Array([Vector2(cx-H*.14,g-H*.14),Vector2(cx+H*.14,g-H*.14),Vector2(cx+H*.1,g-H*.5),Vector2(cx+H*.16,g-H*.72),Vector2(cx-H*.16,g-H*.72),Vector2(cx-H*.1,g-H*.5)]),0.0])
			out.append([_box(cx+H*.2,g,H*.06,H*.34,H*.5),.05])
			out.append([_box(cx+H*.2,g,H*.03,H*.2,H*.82),.3])
			var head:=PackedVector2Array()
			for i in 12:
				var a3:=TAU*float(i)/12.0
				head.append(Vector2(cx+cos(a3)*H*.08,g-H*.8+sin(a3)*H*.08))
			out.append([head,-.05])
		"garden":
			for i in 6:
				var x3:=cx+(float(i)-2.5)*H*.28
				out.append([_box(x3,g,H*.04,H*.2),.3,Color("6b5132")])
				var crown:=PackedVector2Array()
				for j in 10:
					var a4:=TAU*float(j)/10.0
					crown.append(Vector2(x3+cos(a4)*H*.13,g-H*.3+sin(a4)*H*.11))
				out.append([crown,0.0,Color("6f8a4a").darkened(.08*float(i%3))])
			out.append([_box(cx,g,H*1.8,H*.04),.1])
		"amphitheatre":
			for i in 5:
				var bowl:=PackedVector2Array()
				var r:=H*(.95-.12*float(i))
				for j in 17:
					var a5:=PI+PI*float(j)/16.0
					bowl.append(Vector2(cx+cos(a5)*r,g-H*.08*float(5-i)+sin(a5)*r*.12))
				bowl.append(Vector2(cx+r,g));bowl.append(Vector2(cx-r,g))
				out.append([bowl,.06*float(i)])
		"granary":
			for i in 3:
				var x4:=cx+(float(i)-1.0)*H*.48
				out.append([_box(x4,g,H*.36,H*.3,H*.06),.05])
				out.append([_tri(x4,g-H*.36,H*.44,H*.22),.3])
		_:
			out.append([_box(cx,g,H*1.2,H*.36),0.0])
			out.append([_tri(cx,g-H*.36,H*1.3,H*.26),.25])
	return out
