extends RefCounted
## Inked pictures for the Production screen, each drawn in _draw from the
## engine's numbers and redrawn only when they change:
##   MakersRow  the makers as little figures, coloured by what they make
##   TownJar    one town's household store as a jar that fills
##   BarterPile goods to spare as a pile of bundles, with their worth
##   ArmsRack   the watch's arms: sets carried, sets in store, sets wanted
##   TargetRow  a workshop line's store against its target, one mark an item
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const GOODS_TINT:=Color("#a8784a")

static func _text(item:CanvasItem,text:String,at:Vector2,font_size:int,color:Color,center:bool=false,strong:bool=false)->void:
	var font:=T.font("ui_strong" if strong else "ui")
	var x:=at.x
	if center:x-=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5
	item.draw_string(font,Vector2(x,at.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

## One standing figure, feet at `foot`, `h` tall.
static func figure(item:CanvasItem,foot:Vector2,h:float,color:Color)->void:
	var head:=h*.17
	item.draw_circle(foot+Vector2(0,-h+head),head,color)
	var body:=Rect2(foot+Vector2(-h*.15,-h+head*2.2),Vector2(h*.30,h*.42))
	item.draw_rect(body,color)
	item.draw_line(foot+Vector2(-h*.08,-h*.36),foot+Vector2(-h*.12,0),color,maxf(1.4,h*.09),true)
	item.draw_line(foot+Vector2(h*.08,-h*.36),foot+Vector2(h*.12,0),color,maxf(1.4,h*.09),true)


## The makers as a crowd of little figures: [[words, count, colour], ...].
## Up to MAX figures; beyond that each figure stands for several makers.
class MakersRow extends Control:
	const MAX:=60
	var parts:Array=[]
	var each:=1
	func _init()->void:custom_minimum_size=Vector2(0,34);mouse_filter=Control.MOUSE_FILTER_PASS
	func set_parts(next:Array)->void:
		parts=next
		var total:=0.0
		for part:Array in parts:total+=maxf(0.0,float(part[1]))
		each=maxi(1,ceili(total/float(MAX)))
		queue_redraw()
	func _draw()->void:
		var x:=6.0
		var step:=14.0
		for part:Array in parts:
			var count:=roundi(maxf(0.0,float(part[1]))/float(each))
			for i in count:
				if x>size.x-8.0:return
				preload("res://scripts/hud/production_pictures.gd").figure(self,Vector2(x,size.y-3.0),26.0,part[2])
				x+=step
			if count>0:x+=10.0


## One town's household store: a jar, filled to how stocked the homes are.
class TownJar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var fill:=0.0
	var tone:="good"
	func _init()->void:custom_minimum_size=Vector2(46,52);mouse_filter=Control.MOUSE_FILTER_IGNORE
	func set_fill(value:float,look:String)->void:
		fill=clampf(value,0.0,1.0);tone=look;queue_redraw()
	func _shape()->PackedVector2Array:
		var w:=size.x;var h:=size.y
		var c:=w*.5
		var points:=PackedVector2Array()
		# A rounded jar: neck, shoulder, belly, foot; sampled once per draw.
		var profile:=[[.18,.04],[.20,.14],[.40,.30],[.46,.55],[.40,.82],[.28,.96]]
		for p:Array in profile:points.append(Vector2(c-w*float(p[0]),h*float(p[1])))
		for i in range(profile.size()-1,-1,-1):points.append(Vector2(c+w*float(profile[i][0]),h*float(profile[i][1])))
		return points
	func _draw()->void:
		var shape:=_shape()
		draw_colored_polygon(shape,T.PAPER)
		# Goods inside, from the foot up to the fill line.
		var level:=size.y*(.96-.86*fill)
		var inside:=PackedVector2Array()
		for p in shape:inside.append(Vector2(p.x,maxf(p.y,level)))
		if fill>0.01:
			var colour:Color=preload("res://scripts/hud/production_pictures.gd").GOODS_TINT
			if tone=="bad":colour=T.RED
			elif tone=="warn":colour=T.AMBER
			draw_colored_polygon(inside,Color(colour,.55))
			draw_line(Vector2(size.x*.12,level),Vector2(size.x*.88,level),Color(colour.darkened(.3),.9),1.2,true)
		var outline:=shape.duplicate();outline.append(shape[0])
		draw_polyline(outline,T.INK,1.6,true)
		draw_line(Vector2(size.x*.26,size.y*.04),Vector2(size.x*.74,size.y*.04),T.INK,2.4,true)


## Goods to spare as a pile of tied bundles (one bundle for each `per`
## goods, at most MAX), drawn like a chart's vignette.
class BarterPile extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const MAX:=28
	var spare:=0.0
	var per:=1.0
	func _init()->void:custom_minimum_size=Vector2(170,70);mouse_filter=Control.MOUSE_FILTER_PASS
	func set_spare(value:float)->void:
		spare=maxf(0.0,value)
		per=maxf(1.0,pow(10.0,ceilf(log(maxf(1.0,spare/float(MAX)))/log(10.0))))
		queue_redraw()
	func bundles()->int:return mini(MAX,ceili(spare/per)) if spare>0.0 else 0
	func _draw()->void:
		var count:=bundles()
		var base:=size.y-6.0
		var w:=20.0;var h:=12.0
		var row:=0;var placed:=0
		var tint:Color=preload("res://scripts/hud/production_pictures.gd").GOODS_TINT
		while placed<count:
			var in_row:=maxi(1,7-row)
			var start:=size.x*.5-float(in_row)*w*.5+float(row)*0.0
			for i in in_row:
				if placed>=count:break
				var r:=Rect2(Vector2(start+float(i)*w,base-float(row+1)*h+2.0),Vector2(w-2.0,h-1.0))
				draw_rect(r,Color(tint,.85))
				draw_rect(r,T.INK,false,1.0)
				draw_line(Vector2(r.position.x+r.size.x*.5,r.position.y),Vector2(r.position.x+r.size.x*.5,r.end.y),Color(T.INK,.7),1.0)
				placed+=1
			row+=1
		draw_line(Vector2(8,base+1),Vector2(size.x-8,base+1),T.RULE_STRONG,1.4)


## The watch's arms on a rack: a slot for each fighter the watch has, and
## sets in store beyond them. Gold: carried. Ink: in store. Red outline:
## wanted and not yet made. When there are many, each mark stands for several.
class ArmsRack extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const MAX:=40
	var carried:=0
	var stored:=0
	var wanted:=0
	var item:="spear"
	var each:=1
	func _init()->void:custom_minimum_size=Vector2(0,64);mouse_filter=Control.MOUSE_FILTER_PASS
	func set_rack(carried_sets:int,stored_sets:int,wanted_sets:int,kit:String)->void:
		carried=maxi(0,carried_sets);stored=maxi(0,stored_sets);wanted=maxi(0,wanted_sets)
		if kit!="":item=kit
		each=maxi(1,ceili(float(carried+stored+wanted)/float(MAX)))
		queue_redraw()
	func _draw()->void:
		var marks:Array=[]
		for i in ceili(float(carried)/float(each)):marks.append("carried")
		for i in ceili(float(stored)/float(each)):marks.append("stored")
		for i in ceili(float(wanted)/float(each)):marks.append("wanted")
		var step:=clampf((size.x-24.0)/maxf(1.0,float(marks.size())),12.0,22.0)
		# The rack: two rails and the posts at the ends.
		var top:=10.0;var bottom:=size.y-8.0
		var width:=minf(size.x-8.0,step*float(marks.size())+20.0)
		draw_line(Vector2(4,top+6),Vector2(4+width,top+6),T.RULE_STRONG,3.0)
		draw_line(Vector2(4,bottom-8),Vector2(4+width,bottom-8),T.RULE_STRONG,3.0)
		draw_line(Vector2(6,top),Vector2(6,bottom),T.INK,2.4)
		draw_line(Vector2(2+width,top),Vector2(2+width,bottom),T.INK,2.4)
		var gold:=Icons.arm_texture(_arm(),T.GOLD,Color("#c9962e"),48)
		var ink:=Icons.arm_texture(_arm(),T.INK,T.INK_MUTED,48)
		# Washes behind the carried (gold) and the wanted (red).
		var carried_marks:=marks.count("carried");var wanted_marks:=marks.count("wanted")
		if carried_marks>0:draw_rect(Rect2(Vector2(10,top-2),Vector2(step*float(carried_marks)+6.0,bottom-top+4)),Color(T.GOLD,.16))
		if wanted_marks>0:draw_rect(Rect2(Vector2(10+step*float(marks.size()-wanted_marks)+2.0,top-2),Vector2(step*float(wanted_marks)+4.0,bottom-top+4)),Color(T.RED,.08))
		for i in marks.size():
			var x:=14.0+float(i)*step
			var r:=Rect2(Vector2(x-2.0,top-2.0),Vector2(step+4.0,bottom-top+4.0))
			match String(marks[i]):
				"carried":draw_texture_rect(gold,r,false)
				"stored":draw_texture_rect(ink,r,false)
				"wanted":
					var slot:=Rect2(Vector2(x+step*.2,top+2),Vector2(step*.6,bottom-top-4))
					draw_rect(slot,Color(T.RED,.10))
					draw_rect(slot,T.RED,false,1.4)
	func _arm()->String:
		var arm:=Icons.equipment_arm(item)
		return arm if arm!="" else "spear"


## A line's store against its target: one mark an item (filled: in store;
## open: still to make), at most MAX; then each mark stands for several.
class TargetRow extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const MAX:=20
	var stock:=0
	var target:=0
	var progress:=0.0
	var tone:=Color(0,0,0,0)
	func _init()->void:custom_minimum_size=Vector2(0,16);mouse_filter=Control.MOUSE_FILTER_PASS
	func set_row(have:int,keep:int,next:float,colour:Color)->void:
		stock=maxi(0,have);target=maxi(0,keep);progress=clampf(next,0.0,1.0);tone=colour;queue_redraw()
	func _draw()->void:
		var total:=maxi(target,stock)
		if total<=0:return
		var each:=maxi(1,ceili(float(total)/float(MAX)))
		var marks:=ceili(float(total)/float(each))
		var filled:=marks if stock>=total else floori(float(stock)/float(each))
		var step:=minf(14.0,(size.x-4.0)/maxf(1.0,float(marks)))
		var r:=minf(5.0,step*.38)
		for i in marks:
			var c:=Vector2(4.0+r+float(i)*step,size.y*.5)
			if i<filled:
				draw_circle(c,r,T.INK)
			else:
				draw_arc(c,r,0,TAU,16,Color(T.INK,.55),1.2,true)
				# The next one being made, as an arc of its progress.
				if i==filled and progress>0.0:draw_arc(c,r,-PI*.5,-PI*.5+TAU*progress,16,tone,2.2,true)
