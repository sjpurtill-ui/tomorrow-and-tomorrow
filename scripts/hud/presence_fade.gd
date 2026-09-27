extends RefCounted
## Things lettered on the map (city names, great-work cards and emblems) ease
## in when they appear and ease out when they leave, instead of popping at a
## zoom threshold or a layout change. A card that shifts to a new side of its
## pin slides there over a moment.
##
## Pure bookkeeping over a Dictionary of id -> {a, offset, shown, card}:
##   a      presence 0..1 (drawn alpha, eased)
##   offset where the layout wants the card, relative to its anchor
##   shown  where it is drawn, relative to its anchor (eases to offset)
##   card   the last laid-out card (kept to draw it while it fades out)
## No allocation happens once every entry is settled.
const Motion:=preload("res://scripts/hud/motion.gd")
const FADE_IN:=0.22
const FADE_OUT:=0.16
const SLIDE:=0.07          ## slide time constant; about 0.2 s to settle
const SLIDE_MAX_PX:=160.0  ## farther jumps (a card placed far off) cut instead

## Advance every entry one frame. `present` maps id -> card (with rect and
## anchor). Returns true while anything is still moving or fading.
static func advance(fades:Dictionary,present:Dictionary,dt:float)->bool:
	var reduced:=Motion.reduced()
	var busy:=false
	for id in present:
		var card:Dictionary=present[id]
		var rect:Rect2=card.get("rect",Rect2())
		var anchor:Vector2=card.get("anchor",rect.position)
		var offset:=rect.position-anchor
		var entry:Dictionary=fades.get(id,{})
		if entry.is_empty():
			entry={"a":1.0 if reduced else 0.0,"offset":offset,"shown":offset}
			fades[id]=entry
		entry["card"]=card
		var jump:=(offset-Vector2(entry.offset)).length()
		entry["offset"]=offset
		if reduced or jump>SLIDE_MAX_PX:entry["shown"]=offset
		var shown:Vector2=entry.shown
		if shown!=offset:
			shown=shown.lerp(offset,1.0-exp(-maxf(dt,0.0)/SLIDE))
			if shown.distance_to(offset)<0.4:shown=offset
			entry["shown"]=shown
			busy=true
		var a:=float(entry.a)
		if a<1.0:
			a=1.0 if reduced else minf(1.0,a+dt/FADE_IN)
			entry["a"]=a
			busy=busy or a<1.0
	for id in fades.keys():
		if present.has(id):continue
		var entry:Dictionary=fades[id]
		var a:=0.0 if reduced else float(entry.a)-dt/FADE_OUT
		if a<=0.0:fades.erase(id);continue
		entry["a"]=a
		busy=true
	return busy

## The drawn alpha for an entry: eased, so it never reads as a linear ramp.
static func alpha(fades:Dictionary,id:Variant)->float:
	var entry:Dictionary=fades.get(id,{})
	if entry.is_empty():return 1.0
	var a:=clampf(float(entry.a),0.0,1.0)
	return a*a*(3.0-2.0*a)

## Where to draw a card this frame, for its current anchor.
static func drawn_rect(fades:Dictionary,id:Variant,rect:Rect2,anchor:Vector2)->Rect2:
	var entry:Dictionary=fades.get(id,{})
	if entry.is_empty():return rect
	return Rect2(anchor+Vector2(entry.shown),rect.size)

## Entries fading out (no longer laid out): [{id, card, a}].
static func leaving(fades:Dictionary,present:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id in fades:
		if not present.has(id):result.append({"id":id,"card":fades[id].get("card",{}),"a":alpha(fades,id)})
	return result
