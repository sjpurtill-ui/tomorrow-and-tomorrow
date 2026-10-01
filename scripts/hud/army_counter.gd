extends RefCounted
## THE ARMY COUNTER: a force on the map as HOI4 draws a division, in ink.
##
## A paper plate with the owner's colour down its left edge; the glyph of the
## kit most of its men carry (the equipment ledger's glyphs through
## battle_blocks.glyph_of, so a spear band shows a spearman and a tank army a
## tank); the men in bold ("20", "1,240"; theirs "~120"); two bars under the
## number, strength (men against full) and will to fight; a supply dot at the
## plate's corner (fed, short, starving) that becomes a green sprig when the
## band lives off the land (field_rations.should_live_off_land); a badge with
## the number of bands when several march as one; and the force's state chip
## at its shoulder (marching, holding, besieging, fighting, broken, hungry:
## battle_marks.gd draws it). Selected: a gold edge. A stale report: faded,
## with a broken edge.
##
## Static; the war chart passes plain values (war_front_overlay._draw_mark):
## {side, glyph, troops, low?, high?, strength?, will?, will_low?, will_high?,
##  supply?, foraging?, state?, heading?, accent, selected?, stale?, members?}

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")

const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
const OXBLOOD:=Color("#8e3b2e")
const OCHRE:=Color("#a8782a")
const OLIVE:=Color("#4f6b2a")
const GOLD:=Color("#c9a14e")
## The march: the chart's blue for our own movement.
const MARCH:=Color("#3d7f9c")
## The plate at full size (the close and regional charts scale it).
const BASE:=Vector2(104,40)

static func plate_size(scale:float=1.0)->Vector2:
	return BASE*scale

## The kit most of a force's men carry, as a glyph name ("spear", "musket",
## "tank"...): its largest formation's kit.
static func main_glyph(formations:Array,fallback:String="spear")->String:
	var best:={}
	for f in formations:
		if not f is Dictionary: continue
		if best.is_empty() or int((f as Dictionary).get("count",0))>int(best.get("count",0)): best=f
	if best.is_empty(): return fallback
	return Blocks.glyph_of(String(best.get("unit","levy")),String(best.get("weapon","")))

## The glyph for a force known only by its arm and age (a stranger's host,
## a garrison): what such a force carried in each age.
static func glyph_for(branch:String,era:int)->String:
	var e:=clampi(era,0,3)
	match branch:
		"mounted","horse","cavalry": return ["horse","dragoon","horse","light_tank"][e]
		"guns","artillery","fires": return ["catapult","bombard","field_gun","howitzer"][e]
		"armour","armor": return "tank"
		"autonomous": return "combat_frame"
	return ["spear","musket","rifle","assault_rifle"][e]

## What the plate says of the men: ours exactly, theirs as the watchers'
## middle ("~120"), or "?" when nobody counted.
static func men_words(data:Dictionary)->String:
	if String(data.get("side","ours"))=="ours": return EraWords.grouped(maxi(0,int(data.get("troops",0))))
	var low:=int(data.get("low",data.get("troops",0))); var high:=maxi(low,int(data.get("high",low)))
	if high<=0: return "?"
	return "~"+EraWords.grouped(roundi(float(low+high)*0.5))

## The supply dot's colour for a supply state (supply_state.state_of).
static func supply_color(state:String)->Color:
	match state:
		"well": return OLIVE
		"strained": return OCHRE
		"starving": return OXBLOOD
	return Color(INK,0.35)

## Draws the counter centred at `center`; returns the ground it covers (the
## plate and any tab at its side).
static func draw(canvas:CanvasItem,center:Vector2,data:Dictionary,scale:float=1.0,alpha:float=1.0)->Rect2:
	var size:=BASE*scale
	var rect:=Rect2((center-size*0.5).round(),size.round())
	var ours:=String(data.get("side","ours"))=="ours"
	var stale:=bool(data.get("stale",false))
	var a:=alpha*(0.75 if stale else 1.0)
	var accent:Color=data.get("accent",OLIVE)
	# The plate: a soft shadow, paper, the owner's colour down the left edge.
	canvas.draw_rect(Rect2(rect.position+Vector2(1.5,2.0)*scale,rect.size),Color(0,0,0,0.22*a))
	canvas.draw_rect(rect,Color(PAPER,0.97*a))
	var edge:=maxf(4.0,5.0*scale)
	canvas.draw_rect(Rect2(rect.position,Vector2(edge,rect.size.y)),Color(accent,a))
	# The kit's glyph.
	var g:=rect.size.y-6.0*scale
	var glyph_rect:=Rect2(rect.position+Vector2(edge+2.0*scale,3.0*scale),Vector2(g,g))
	canvas.draw_texture_rect(Icons.arm_texture(String(data.get("glyph","spear")),INK,accent,64),glyph_rect,false,Color(1,1,1,a))
	# The men, in bold.
	var left:=glyph_rect.end.x+4.0*scale
	var right:=rect.end.x-12.0*scale
	var font:=T.font("ui_strong")
	var size_pt:=maxi(11,roundi(18.0*scale))
	canvas.draw_string(font,Vector2(left,rect.position.y+18.0*scale),men_words(data),HORIZONTAL_ALIGNMENT_LEFT,maxf(10.0,right-left),size_pt,Color(INK,a))
	# Strength and will, as two bars under the number.
	var bar_w:=rect.end.x-left-5.0*scale
	var bar_h:=maxf(3.0,4.2*scale)
	var y:=rect.position.y+24.0*scale
	if data.has("strength"):
		var share:=clampf(float(data.strength),0.0,1.0)
		canvas.draw_rect(Rect2(Vector2(left,y),Vector2(bar_w,bar_h)),Color(INK,0.16*a))
		if share>0.0: canvas.draw_rect(Rect2(Vector2(left,y),Vector2(bar_w*share,bar_h)),Color(OLIVE if ours else accent.darkened(0.2),a))
	y+=bar_h+2.0*scale
	if data.has("will") or data.has("will_low"):
		canvas.draw_rect(Rect2(Vector2(left,y),Vector2(bar_w,bar_h)),Color(INK,0.16*a))
		if data.has("will"):
			var will:=clampf(float(data.will),0.0,1.0)
			if will>0.0: canvas.draw_rect(Rect2(Vector2(left,y),Vector2(bar_w*will,bar_h)),Color(OXBLOOD if will<0.3 else OCHRE,a))
		else:
			var low:=clampf(float(data.get("will_low",0.0)),0.0,1.0); var high:=clampf(float(data.get("will_high",low)),low,1.0)
			if low>0.0: canvas.draw_rect(Rect2(Vector2(left,y),Vector2(bar_w*low,bar_h)),Color(OCHRE,a))
			if high>low: canvas.draw_rect(Rect2(Vector2(left+bar_w*low,y),Vector2(bar_w*(high-low),bar_h)),Color(OCHRE,0.4*a))
	# Supply: a dot at the corner, or a sprig when living off the land.
	var supply:=String(data.get("supply",""))
	var dot:=Vector2(rect.end.x-6.5*scale,rect.position.y+7.0*scale)
	if bool(data.get("foraging",false)): _sprig(canvas,dot,4.6*scale,a)
	elif supply!="":
		canvas.draw_circle(dot,3.6*scale,Color(supply_color(supply),a))
		canvas.draw_arc(dot,3.6*scale,0.0,TAU,14,Color(INK,0.6*a),1.0,true)
	var footprint:=rect
	# On the march: how far along, as a strip along the plate's foot, and
	# the days still to go on a tab at its side.
	if data.has("march_done"):
		var done:=clampf(float(data.march_done),0.0,1.0)
		var foot:=Rect2(Vector2(rect.position.x+edge,rect.end.y-3.0*scale),Vector2(rect.size.x-edge,3.0*scale))
		canvas.draw_rect(foot,Color(INK,0.12*a))
		if done>0.0: canvas.draw_rect(Rect2(foot.position,Vector2(foot.size.x*done,foot.size.y)),Color(MARCH,a))
		var days:=int(data.get("days_left",0))
		if days>0:
			footprint=footprint.merge(_tab(canvas,rect,"%d %s" % [days,"day" if days==1 else "days"],font,scale,a,true))
	# A word on a tab at the side (those in drill behind the levy at home).
	if String(data.get("tab",""))!="" and not data.has("march_done"):
		footprint=footprint.merge(_tab(canvas,rect,String(data.tab),font,scale,a,false))
	# The edge: ink, gold when selected, broken when the report is stale.
	if stale:
		var step:=6.0*scale
		var x:=rect.position.x
		while x<rect.end.x:
			canvas.draw_line(Vector2(x,rect.position.y),Vector2(minf(x+step*0.6,rect.end.x),rect.position.y),Color(INK,0.7*a),1.2)
			canvas.draw_line(Vector2(x,rect.end.y),Vector2(minf(x+step*0.6,rect.end.x),rect.end.y),Color(INK,0.7*a),1.2)
			x+=step
	else: canvas.draw_rect(rect,Color(INK,0.85*a),false,maxf(1.0,1.3*scale))
	if bool(data.get("selected",false)):
		canvas.draw_rect(rect.grow(2.5*scale),Color(PAPER,0.85*a),false,3.0*scale)
		canvas.draw_rect(rect.grow(2.5*scale),Color(GOLD,a),false,1.6*scale)
	# Several bands as one: their number on a badge at the top edge.
	var members:=int(data.get("members",0))
	if members>1:
		var badge:=Vector2(rect.end.x-2.0*scale,rect.position.y-1.0*scale)
		canvas.draw_circle(badge,7.5*scale,Color(PAPER,a))
		canvas.draw_arc(badge,7.5*scale,0.0,TAU,18,Color(INK,0.85*a),1.2,true)
		var t:=str(members)
		var bfs:=maxi(9,roundi(11.0*scale))
		var w:=font.get_string_size(t,HORIZONTAL_ALIGNMENT_LEFT,-1,bfs).x
		canvas.draw_string(font,badge+Vector2(-w*0.5,bfs*0.36),t,HORIZONTAL_ALIGNMENT_LEFT,-1,bfs,Color(INK,a))
	# What the force is doing, at its shoulder.
	var state:=String(data.get("state",""))
	if state!="":
		var heading:Vector2=data.get("heading",Vector2.RIGHT)
		BattleMarks.draw_state(canvas,Vector2(rect.position.x-1.0*scale,rect.position.y+1.0*scale),state,maxf(5.0,6.0*scale),a,heading)
	return footprint

## A paper tab on the plate's right side: the days to go (with the march's
## arrow) or a word.
static func _tab(canvas:CanvasItem,rect:Rect2,tab_text:String,font:Font,scale:float,a:float,arrow:bool)->Rect2:
	var tfs:=maxi(9,roundi(12.0*scale))
	var tw:=font.get_string_size(tab_text,HORIZONTAL_ALIGNMENT_LEFT,-1,tfs).x
	var tab:=Rect2(Vector2(rect.end.x-1.0,rect.position.y+rect.size.y*0.5-9.0*scale),Vector2(tw+(18.0 if arrow else 10.0)*scale,18.0*scale))
	canvas.draw_rect(tab,Color(PAPER,0.96*a))
	canvas.draw_rect(tab,Color(INK,0.75*a),false,1.0)
	canvas.draw_string(font,Vector2(tab.position.x+5.0*scale,tab.position.y+13.0*scale),tab_text,HORIZONTAL_ALIGNMENT_LEFT,-1,tfs,Color(INK,a))
	if arrow:
		var tip:=Vector2(tab.end.x-4.0*scale,tab.get_center().y)
		canvas.draw_colored_polygon(PackedVector2Array([tip,tip+Vector2(-5.0,-4.0)*scale,tip+Vector2(-5.0,4.0)*scale]),Color(MARCH,a))
	return tab

## A small green sprig: the band forages and hunts as it goes.
static func _sprig(canvas:CanvasItem,at:Vector2,r:float,a:float)->void:
	var green:=Color(OLIVE,a)
	canvas.draw_circle(at,r+1.2,Color(PAPER,a))
	canvas.draw_line(at+Vector2(-r*0.6,r*0.8),at+Vector2(r*0.5,-r*0.8),Color(INK,0.8*a),1.2,true)
	for k in 2:
		var c:=at+Vector2(-r*0.15+float(k)*r*0.45,r*0.2-float(k)*r*0.7)
		var side:=Vector2(r*0.42,-r*0.18) if k==0 else Vector2(-r*0.42,-r*0.1)
		canvas.draw_colored_polygon(PackedVector2Array([c,c+side+Vector2(0,-r*0.35),c+side*1.6,c+side+Vector2(0,r*0.25)]),green)
