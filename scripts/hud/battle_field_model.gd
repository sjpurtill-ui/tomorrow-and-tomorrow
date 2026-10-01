extends RefCounted
## THE BATTLE FIELD, LAID OUT: where every block of both sides stands on the
## battle screen's war map at one step of a battle, and the arrows of that
## day's fighting. Pure and static: hud/battle_field.gd draws what this lays
## out, and the battle evaluation (tests/battle_eval/harness.gd) checks it
## against the engine. Everything comes from battle_record.gd view() and the
## record itself; nothing here fights or invents:
##   blocks   the engine's own blocks (battle_blocks.gd) at that step: the
##            line in its slots, the reserve in rows behind it, the broken
##            falling back, the fled at the field's edge. Each block is as
##            wide as its men at the start (one scale for both sides) and
##            filled by the share of them still with it.
##   contact  where the lines meet, moved toward the side being pushed back
##            by the engine's measure of who is winning (progress).
##   arrows   the attacker's thrusts and any side that is pushing; the
##            general's tactic (battle_tactics.gd shape, as the war chart
##            draws it): a hook round a flank, both flanks, a column, a
##            pocket; reserves going in; blocks breaking and running; the
##            pursuit; guns firing over their own line.
##   marks    a second line held back, dug-in works, a missile screen.
## Steps: 0 is the two sides drawn up, k the end of day k (one phase of the
## block battle a day, as the war chart counts the days).
## Field space is pixels: x across, y down. "right" (theirs when we fought,
## else the defender) stands at the top, "left" at the bottom.

const Record:=preload("res://scripts/battle_record.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const Account:=preload("res://scripts/battle_account.gd")

## Share of the field's width the fighting can use, by ground: open country
## is wide; a forest edge, a pass, a ford, a bridge or a gap in the walls is
## narrow (drawn, not to scale: battle_blocks.GROUNDS has the real widths).
const OPENING:={"open":0.9,"rough":0.8,"forest":0.64,"marsh":0.58,"pass":0.38,"ford":0.4,"bridge":0.24,"breach":0.3,"gate":0.22}
## How far the line moves from the middle (share of the field's height) when
## one side is driving the other from the field.
const SWING:=0.11
const PAD:=14.0
const SPACING:=6.0
const MIN_W:=34.0
const MAX_W:=180.0
const MAX_H:=64.0
## Rows behind the line, as shares of a block in the line: the reserve, the
## broken and the fled are drawn smaller, and each row keeps a little room.
const ROWS:={"reserve":[0.84,0.16],"broken":[0.72,0.14],"fled":[0.6,0.12]}
## A side is pushing (and draws its thrusts) from this progress.
const PUSHING:=0.15


# --- One step -------------------------------------------------------------------------------

## The field at `step`: {step, size, ground, river, walls, flank, opening:
## [x0, x1], contact (y), apart (half the gap between the lines), era (the
## battle mark's weapons era), progress (left-positive), scale (pixels a
## man), block_h, blocks, arrows, marks, defender ("left"|"right")}. Each
## block: {id, key, state, rect, men, men0, strength, cohesion, glyph, arm,
## unit, slot, tilt, alpha, data (the plate)}. Each arrow: {kind, key,
## points, weight, dashed, blunt}. Each mark: {kind, key, points}.
static func build(view:Dictionary,record:Dictionary,step:int,size:Vector2,with_arrows:=true)->Dictionary:
	var count:=(view.get("phases",[]) as Array).size()
	step=clampi(step,0,count)
	var ground:=String((view.get("ground",{}) as Dictionary).get("kind","open"))
	var spec:Dictionary=Blocks.GROUNDS.get(ground,Blocks.GROUNDS.open)
	var w:=maxf(200.0,size.x); var h:=maxf(160.0,size.y)
	var phase:=phase_at(view,step)
	var progress:=float(phase.get("progress",0.0)) if step>0 else 0.0
	var out:={"step":step,"size":Vector2(w,h),"ground":ground,"river":bool(spec.get("river",false)),"walls":bool(spec.get("walls",false)),"flank":bool(spec.get("flank",true)),
		"era":era_of(record,String(view.get("stage","hearth"))),"progress":progress,"blocks":[],"arrows":[],"marks":[],
		"defender":"left" if String(view.get("left",""))=="defender" else "right"}
	var mid:=h*0.5
	var contact:=mid-clampf(progress,-1.0,1.0)*h*SWING
	var drawn_up:=step==0 or (bool(phase.get("current",false)) and int(phase.get("to",0))<int(phase.get("from",1)))
	var apart:=h*0.07 if drawn_up else 6.0
	out["contact"]=contact; out["apart"]=apart; out["drawn_up"]=drawn_up
	var plates:=plates_at(view,step)
	# One scale for both sides: the fuller line fills the opening.
	var opening:=w*float(OPENING.get(ground,0.9))
	var most:=1
	for key in ["left","right"]: most=maxi(most,((plates.get(key,{}) as Dictionary).get("front",[]) as Array).size())
	opening=clampf(maxf(opening,float(most)*(MIN_W+SPACING)),0.0,w-PAD*2.0)
	var scale:=INF
	for key in ["left","right"]:
		var front:Array=(plates.get(key,{}) as Dictionary).get("front",[])
		var men:=0
		for plate in front: men+=maxi(1,int(plate.men0))
		if men>0: scale=minf(scale,(opening-SPACING*float(front.size()-1))/float(men))
	if scale==INF:
		# Nobody in the line: size by the biggest block there is.
		var biggest:=1
		for key in ["left","right"]:
			for row in ["front","rear"]:
				for plate in ((plates.get(key,{}) as Dictionary).get(row,[]) as Array): biggest=maxi(biggest,int(plate.men0))
		scale=MAX_W*0.6/float(biggest)
	out["opening"]=[(w-opening)*0.5,(w+opening)*0.5]
	out["scale"]=scale
	# As tall as the deepest side lets every row fit in the narrowest half.
	var room:=h*(0.5-SWING)-apart-6.0
	var need:=1.0
	for key in ["left","right"]: need=maxf(need,_depth_units(plates.get(key,{}),scale,w))
	var block_h:=clampf(room/need,16.0,MAX_H)
	out["block_h"]=block_h
	for key in ["left","right"]:
		_lay_side(out,(plates.get(key,{}) as Dictionary),key,contact,apart,block_h,scale,w,h)
	if with_arrows and step>0 and not drawn_up:
		var previous:=build(view,record,step-1,size,false)
		_arrows(out,previous,view,record,step)
	return out


## A side's depth in blocks: the line, a gap, then its rows behind.
static func _depth_units(side:Dictionary,scale:float,w:float)->float:
	var groups:=_rear_groups(side)
	var units:=1.3
	for state in ["reserve","broken","fled"]:
		var rows:=_rows(groups[state],scale,_factor(state),w-PAD*2.0).size()
		if rows>0: units+=float(rows)*(float(ROWS[state][0])+float(ROWS[state][1]))+0.1
	return units


static func _rear_groups(side:Dictionary)->Dictionary:
	var out:={"reserve":[],"broken":[],"fled":[]}
	for plate in side.get("rear",[]):
		var state:=String(plate.state)
		(out[state if out.has(state) else "fled"] as Array).append(plate)
	return out


static func _factor(state:String)->float:
	return float((ROWS.get(state,[1.0,0.0]) as Array)[0]) if state!="front" else 1.0


## A block's width: its men at the start, on the field's scale.
static func _width(plate:Dictionary,scale:float,factor:float)->float:
	return clampf(float(maxi(1,int(plate.men0)))*scale*factor,MIN_W*factor,MAX_W*factor)


## Blocks of one side: the line by slot, then behind it the reserve in rows,
## the broken fallen back, and the fled at the field's edge.
static func _lay_side(out:Dictionary,side:Dictionary,key:String,contact:float,apart:float,block_h:float,scale:float,w:float,h:float)->void:
	var blocks:Array=out.blocks
	var front:Array=side.get("front",[])
	var widths:Array=[]
	var total:=0.0
	for plate in front:
		var bw:=_width(plate,scale,1.0)
		widths.append(bw); total+=bw
	total+=SPACING*float(maxi(0,front.size()-1))
	var x:=(w-total)*0.5
	var front_y:=contact+apart if key=="left" else contact-apart-block_h
	for i in front.size():
		blocks.append(_block(front[i],key,Rect2(x,front_y,widths[i],block_h)))
		x+=float(widths[i])+SPACING
	var groups:=_rear_groups(side)
	var d:=apart+block_h*1.3
	for state in ["reserve","broken"]:
		var factor:=_factor(state)
		var row_h:=block_h*factor
		for row in _rows(groups[state],scale,factor,w-PAD*2.0):
			_lay_row(blocks,row,key,contact,d,row_h,scale,factor,w,state=="broken")
			d+=row_h+block_h*float(ROWS[state][1])
		d+=block_h*0.1
	# The fled, at the rear edge of the field.
	var fled_rows:=_rows(groups.fled,scale,_factor("fled"),w-PAD*2.0)
	var fled_h:=block_h*_factor("fled")
	var edge:=absf((h-4.0 if key=="left" else 4.0)-contact)
	var start:=maxf(d,edge-float(fled_rows.size())*(fled_h+block_h*0.12))
	for row in fled_rows:
		_lay_row(blocks,row,key,contact,start,fled_h,scale,_factor("fled"),w,false)
		start+=fled_h+block_h*0.12


## One row of blocks behind the line, centred, `d` from the contact.
static func _lay_row(blocks:Array,row:Array,key:String,contact:float,d:float,row_h:float,scale:float,factor:float,w:float,tilted:bool)->void:
	var width:=0.0
	for plate in row: width+=_width(plate,scale,factor)
	width+=SPACING*float(maxi(0,row.size()-1))
	var x:=(w-width)*0.5
	var y:=contact+d if key=="left" else contact-d-row_h
	for i in row.size():
		var bw:=_width(row[i],scale,factor)
		var block:=_block(row[i],key,Rect2(x,y,bw,row_h))
		if tilted: block["tilt"]=(0.07 if i%2==0 else -0.07)
		blocks.append(block)
		x+=bw+SPACING


## Blocks gathered into rows that fit the width.
static func _rows(plates:Array,scale:float,factor:float,width:float)->Array:
	var rows:Array=[]
	var row:Array=[]
	var used:=0.0
	for plate in plates:
		var bw:=_width(plate,scale,factor)
		if not row.is_empty() and used+bw>width:
			rows.append(row); row=[]; used=0.0
		row.append(plate); used+=bw+SPACING
	if not row.is_empty(): rows.append(row)
	return rows


static func _block(plate:Dictionary,key:String,rect:Rect2)->Dictionary:
	var state:=String(plate.get("state","front"))
	return {"id":String(plate.get("id","")),"key":key,"state":state,"rect":rect,"men":int(plate.get("men",0)),"men0":int(plate.get("men0",0)),
		"strength":clampf(float(plate.get("strength",1.0)),0.0,1.0),"cohesion":clampf(float(plate.get("cohesion",1.0)),0.0,1.0),
		"glyph":String(plate.get("glyph",plate.get("arm","spear"))),"arm":String(plate.get("arm","spear")),"unit":String(plate.get("unit","")),
		"slot":int(plate.get("slot",-1)),"tilt":0.0,"alpha":0.42 if state=="fled" else 1.0,"data":plate}


# --- Arrows ----------------------------------------------------------------------------------

static func _arrows(out:Dictionary,previous:Dictionary,view:Dictionary,record:Dictionary,step:int)->void:
	var arrows:Array=out.arrows
	var marks:Array=out.marks
	var contact:=float(out.contact)
	var w:=(out.size as Vector2).x
	var phase:=phase_at(view,step)
	var roles:={"left":String(view.get("left","attacker")),"right":String(view.get("right","defender"))}
	var by_id:={}
	for block in previous.get("blocks",[]): by_id[String(block.key)+"|"+String(block.id)]=block
	var shapes:=shapes_at(view,record,step)
	out["shapes"]=shapes
	for key in ["left","right"]:
		var toward:=-1.0 if key=="left" else 1.0
		var other:="right" if key=="left" else "left"
		var mine:=_span(out,key,"front")
		var theirs:=_span(out,other,"front")
		var shape:Dictionary=shapes.get(key,{})
		var mine_p:=float(out.progress)*(1.0 if key=="left" else -1.0)
		var attacker:=String(roles[key])=="attacker"
		# Thrusts: the attacker always, and a side pushing the other back.
		if not mine.is_empty() and (attacker or mine_p>=PUSHING):
			var bulge:=maxf(0.0,float(shape.get("bulge",0.0)))
			var block_h:=float(out.get("block_h",40.0))
			var reach:=float(out.apart)+block_h*0.5+44.0*maxf(0.0,mine_p)+20.0*bulge
			var blunt:=attacker and mine_p<=-PUSHING
			var weight:=clampf(0.35+0.5*maxf(0.0,mine_p)+0.25*bulge,0.25,1.0)
			var lanes:=[0.5] if bulge>=0.3 or float(mine.x1-mine.x0)<380.0 else [0.2,0.5,0.8]
			# From inside its own line into theirs: the push, not the men.
			var from_y:=float(mine.y_face)-toward*block_h*0.3
			for u in lanes:
				var x:=lerpf(float(mine.x0),float(mine.x1),float(u))
				var tip:=contact+toward*(reach if not blunt else -2.0)
				var points:=PackedVector2Array([Vector2(x,from_y),Vector2(x,lerpf(from_y,tip,0.55)),Vector2(x,tip)])
				arrows.append({"kind":"thrust","key":key,"points":points,"weight":weight*(1.25 if lanes.size()==1 and bulge>=0.3 else 1.0),"dashed":false,"blunt":blunt})
		# Round a flank (or both): only where the ground leaves room.
		if bool(out.flank) and not mine.is_empty() and not theirs.is_empty():
			var wing:=float(shape.get("wing",0.0)); var wings:=float(shape.get("wings",0.0))
			var ends:Array=[]
			if wings>0.01 and String(shape.get("shape","")) in ["double_envelopment","converging"]: ends=[[1.0,wings],[-1.0,wings]]
			elif wing>0.01: ends=[[1.0,wing]]
			for end in ends:
				var dir:=float(end[0]); var grow:=clampf(float(end[1]),0.0,1.0)
				var start:=Vector2(float(mine.x1) if dir>0.0 else float(mine.x0),float(mine.y_mid))
				var outside:=(float(theirs.x1) if dir>0.0 else float(theirs.x0))+dir*34.0
				var behind:=float(theirs.y_back)+toward*14.0
				var points:=PackedVector2Array()
				for k in 9:
					var u:=float(k)/8.0*grow
					var angle:=u*PI*0.95
					points.append(Vector2(lerpf(start.x,outside,sin(angle*0.5)*1.05),lerpf(start.y,behind,(1.0-cos(angle))*0.5)))
				arrows.append({"kind":"hook","key":key,"points":points,"weight":0.55,"dashed":false,"blunt":false})
		# A pocket closing behind them.
		var closure:=float(shape.get("closure",0.0))
		if closure>0.01 and not theirs.is_empty():
			var centre:=Vector2((float(theirs.x0)+float(theirs.x1))*0.5,float(theirs.y_back)+toward*10.0)
			var radius:=maxf(30.0,(float(theirs.x1)-float(theirs.x0))*0.32)
			var points:=PackedVector2Array()
			var facing:=-PI*0.5 if key=="left" else PI*0.5
			for k in 17:
				var a:=facing+PI+(float(k)/16.0*2.0-1.0)*PI*0.5*closure
				points.append(centre+Vector2(cos(a),sin(a))*Vector2(radius,radius*0.45))
			marks.append({"kind":"pocket","key":key,"points":points})
		# A second line held back, works dug in front, a screen of missiles.
		if int(shape.get("depth",0))>0 and not mine.is_empty():
			for d in int(shape.get("depth",0)):
				var y:=float(mine.y_back)-toward*(10.0+10.0*float(d))
				marks.append({"kind":"depth","key":key,"points":PackedVector2Array([Vector2(float(mine.x0),y),Vector2(float(mine.x1),y)])})
		if String(shape.get("shape","")) in ["trenches","camp","shield_line","firing_line","pike_square"] and not mine.is_empty():
			marks.append({"kind":String(shape.shape),"key":key,"points":PackedVector2Array([Vector2(float(mine.x0),float(mine.y_face)),Vector2(float(mine.x1),float(mine.y_face))]),"hardening":float(shape.get("hardening",0.0))})
		if String(shape.get("shape",""))=="screen" and not mine.is_empty():
			marks.append({"kind":"screen","key":key,"points":PackedVector2Array([Vector2(float(mine.x0),contact+toward*2.0),Vector2(float(mine.x1),contact+toward*2.0)])})
	# Guns firing over their own line from the reserve (battle_blocks SUPPORT).
	for block in out.blocks:
		if String(block.state)!="reserve" or String(block.arm)!="guns": continue
		var other:="right" if String(block.key)=="left" else "left"
		var target:=_span(out,other,"front")
		if target.is_empty(): continue
		var from:=(block.rect as Rect2).get_center()
		var to:=Vector2(clampf(from.x,float(target.x0)+8.0,float(target.x1)-8.0),float(target.y_mid))
		var along:=to-from
		var bow:=along.orthogonal().normalized()*along.length()*0.16
		var points:=PackedVector2Array()
		for k in 9:
			var u:=float(k)/8.0
			points.append(from.lerp(to,u)+bow*4.0*u*(1.0-u))
		arrows.append({"kind":"fire","key":String(block.key),"points":points,"weight":0.2,"dashed":true,"blunt":false})
	# Reserves going in, where the record says (reserve_in slots).
	for event in raw_events(record,step):
		var e:Dictionary=event
		var key:="left" if String(e.get("side",""))==String(roles.left) else ("right" if String(e.get("side",""))==String(roles.right) else "")
		if key=="": continue
		var toward:=-1.0 if key=="left" else 1.0
		match String(e.get("k","")):
			"reserve_in":
				for slot in e.get("slots",[]):
					var block:=_front_at(out,key,int(slot))
					if block.is_empty(): continue
					var rect:Rect2=block.rect
					var tip:=Vector2(rect.get_center().x,rect.end.y+3.0 if key=="left" else rect.position.y-3.0)
					var tail:=tip+Vector2(0,-toward*34.0)
					arrows.append({"kind":"reserve","key":key,"points":PackedVector2Array([tail,tail.lerp(tip,0.5),tip]),"weight":0.25,"dashed":false,"blunt":false})
	# Blocks that broke this day: the way each ran (a few a side), the
	# victors' riders after them when they took captives in the chase; a
	# side that left the field: one arrow back from where its line stood.
	var chased:={}
	for event in raw_events(record,step):
		var e:Dictionary=event
		if String(e.get("k",""))=="broke" and int(e.get("cap",0))>0: chased[String(e.get("side",""))]=true
	var routs:={"left":0,"right":0}
	var left_field:={"left":[],"right":[]}
	for block in out.blocks:
		var state:=String(block.state)
		if state not in ["broken","fled"]: continue
		var key:=String(block.key)
		var before:Dictionary=by_id.get(key+"|"+String(block.id),{})
		if before.is_empty() or String(before.state)==state or String(before.state) in ["broken","fled"]: continue
		if state=="fled":
			(left_field[key] as Array).append(before)
			continue
		if int(routs[key])>=6: continue
		routs[key]=int(routs[key])+1
		var from:=(before.rect as Rect2).get_center()
		var to:=(block.rect as Rect2).get_center()
		arrows.append({"kind":"rout","key":key,"points":PackedVector2Array([from,from.lerp(to,0.5),to]),"weight":0.3,"dashed":true,"blunt":false})
		if chased.has(String(roles[key])):
			var hunter:="right" if key=="left" else "left"
			var span:=_span(out,hunter,"front")
			if span.is_empty(): continue
			var start:=Vector2(clampf(to.x,float(span.x0),float(span.x1)),float(span.y_mid))
			arrows.append({"kind":"pursuit","key":hunter,"points":PackedVector2Array([start,start.lerp(to,0.5),start.lerp(to,0.86)]),"weight":0.3,"dashed":true,"blunt":false})
	for key in left_field:
		var gone:Array=left_field[key]
		if gone.is_empty(): continue
		var box:Rect2=gone[0].rect
		for b in gone: box=box.merge(b.rect)
		var toward:=-1.0 if key=="left" else 1.0
		var from:=Vector2(box.get_center().x,box.get_center().y)
		var rear:=(out.size as Vector2).y-6.0 if key=="left" else 6.0
		var to:=Vector2(from.x,rear)
		if absf(to.y-from.y)<20.0: continue
		arrows.append({"kind":"flight","key":key,"points":PackedVector2Array([from,from.lerp(to,0.5),to]),"weight":clampf(box.size.x/((out.size as Vector2).x*0.6),0.4,1.0),"dashed":true,"blunt":false})
		var other:="right" if key=="left" else "left"
		# The side that held the field steps into it.
		var holder:=_span(out,other,"front")
		var pushing:=false
		for arrow in arrows:
			if String(arrow.kind)=="thrust" and String(arrow.key)==other: pushing=true
		if not holder.is_empty() and not pushing:
			var hx:=(float(holder.x0)+float(holder.x1))*0.5
			var hy:=float(holder.y_mid)
			arrows.append({"kind":"thrust","key":other,"points":PackedVector2Array([Vector2(hx,hy),Vector2(hx,lerpf(hy,from.y,0.5)),Vector2(hx,from.y+toward*-4.0)]),"weight":0.8,"dashed":false,"blunt":false})


## The extent of one side's blocks in a state: {x0, x1, y_face (the edge
## facing the enemy), y_back, y_mid}, or {} when it has none.
static func _span(out:Dictionary,key:String,state:String)->Dictionary:
	var box:=Rect2(); var any:=false
	for block in out.blocks:
		if String(block.key)!=key or String(block.state)!=state: continue
		box=(block.rect as Rect2) if not any else box.merge(block.rect)
		any=true
	if not any: return {}
	var face:=box.position.y if key=="left" else box.end.y
	var back:=box.end.y if key=="left" else box.position.y
	return {"x0":box.position.x,"x1":box.end.x,"y_face":face,"y_back":back,"y_mid":box.get_center().y}


static func _front_at(out:Dictionary,key:String,slot:int)->Dictionary:
	for block in out.blocks:
		if String(block.key)==key and String(block.state)=="front" and int(block.slot)==slot: return block
	return {}


# --- Reading the view and the record ----------------------------------------------------------

## The view's phase shown at `step` (step 0: {}).
static func phase_at(view:Dictionary,step:int)->Dictionary:
	var phases:Array=view.get("phases",[])
	if step<=0 or step>phases.size(): return {}
	return phases[step-1]


## Both sides' blocks at `step`: {left:{front, rear}, right:{...}}.
static func plates_at(view:Dictionary,step:int)->Dictionary:
	if step<=0: return view.get("start",{})
	return (phase_at(view,step) as Dictionary).get("plates",{})


## The engine's own events of the day shown (battle_blocks events: k, side
## as a role, slots, cap ...).
static func raw_events(record:Dictionary,step:int)->Array:
	var battle:=battle_of(record)
	var phases:Array=battle.get("phases",[])
	if step>=1 and step<=phases.size(): return ((phases[step-1] as Dictionary).get("events",[]) as Array)
	if step==phases.size()+1: return ((battle.get("cur",{}) as Dictionary).get("events",[]) as Array)
	return []


static func battle_of(record:Dictionary)->Dictionary:
	var battle:Variant=record.get("battle",{})
	if battle is Dictionary and (battle as Dictionary).has("sides"): return battle
	return Record.derive(record)


## Each side's tactic drawn as the war chart draws it (battle_tactics.gd
## shape) at the end of the day shown: {left:{shape, bulge, wings, wing,
## closure, depth, hardening, id}, right:{...}}.
static func shapes_at(view:Dictionary,record:Dictionary,step:int)->Dictionary:
	var phase:=phase_at(view,step)
	var out:={}
	var rounds:Array=record.get("rounds",[])
	var to:=int(phase.get("to",0))
	for key in ["left","right"]:
		var id:=String(((phase.get("tactics",{}) as Dictionary).get(key,{}) as Dictionary).get("id",""))
		if id=="": id=Tactics.BASELINE
		var role:=String(view.get(key,"attacker"))
		var stage:="hold"
		if to>=1 and to<=rounds.size(): stage=String((rounds[to-1] as Dictionary).get(role+"_tactic_phase","hold"))
		if stage=="": stage="hold"
		var shape:=Tactics.shape(id,to,stage)
		shape["id"]=id
		out[key]=shape
	return out


## The battle's weapons era, as the war chart marks it (battle_marks.gd):
## crossed spears, swords, muskets or rifles, the armour sign, the lattice.
## A battle being fought reads the kits its armies carry now, as the chart
## does; a finished one reads the kits its blocks went in with.
static func era_of(record:Dictionary,stage:String)->int:
	var year:=-1.0
	var finished:=record.has("termination")
	var battle:Dictionary=record.get("battle",{}) if record.get("battle") is Dictionary else {}
	for role in ["attacker","defender"]:
		var formations:Array=[]
		if finished and battle.has("sides"):
			for block in ((battle.sides as Dictionary).get(role,{}) as Dictionary).get("blocks",[]):
				formations.append({"unit":String(block.get("unit","")),"weapon":String(block.get("weapon","")),"count":int(block.get("men0",0))})
		else:
			var force:Variant=record.get(role,{})
			if force is Dictionary and (force as Dictionary).get("formations") is Array: formations=(force as Dictionary).formations
		year=maxf(year,ArmyMarks.force_year(formations))
	if year>=0.0: return BattleMarks.weapons_era(year)
	return BattleMarks.chart_era([],stage)


## What a side had lost by the end of `step`; at the end of the battle its
## own totals (captives taken when it was beaten included).
static func totals_at(view:Dictionary,step:int,key:String)->Dictionary:
	var side:Dictionary=(view.get("sides",{}) as Dictionary).get(key,{})
	var totals:Dictionary=side.get("totals",{})
	var count:=(view.get("phases",[]) as Array).size()
	if step>=count: return totals.duplicate()
	var out:={"went_in":int(totals.get("went_in",0)),"killed":0,"wounded":0,"fled":0,"captured":0}
	for index in range(1,step+1):
		var losses:Dictionary=((phase_at(view,index).get("losses",{}) as Dictionary).get(key,{}) as Dictionary)
		for kind in ["killed","wounded","fled","captured"]: out[kind]=int(out[kind])+int(losses.get(kind,0))
	out["standing"]=maxi(0,int(out.went_in)-int(out.killed)-int(out.wounded)-int(out.fled)-int(out.captured))
	return out


## A side's heart at `step`: its standing blocks' will to fight, weighed by
## their men (0..1); -1 when nobody of it stands.
static func heart_at(view:Dictionary,step:int,key:String)->float:
	var side:Dictionary=plates_at(view,step).get(key,{})
	var men:=0.0; var weighed:=0.0
	for row in ["front","rear"]:
		for plate in (side.get(row,[]) as Array):
			if String(plate.state) not in ["front","reserve"]: continue
			men+=float(plate.men); weighed+=float(plate.men)*float(plate.cohesion)
	return weighed/men if men>0.0 else -1.0


## Men standing (in the line or waiting) on the field at `step`.
static func standing_at(view:Dictionary,step:int,key:String)->int:
	var side:Dictionary=plates_at(view,step).get(key,{})
	var men:=0
	for row in ["front","rear"]:
		for plate in (side.get(row,[]) as Array):
			if String(plate.state) in ["front","reserve"]: men+=int(plate.men)
	return men


## The stop under the timeline: "Drawn up", "Day 2".
static func day_label(view:Dictionary,step:int)->String:
	if step<=0: return "Drawn up"
	var phase:=phase_at(view,step)
	if bool(phase.get("current",false)) and int(phase.get("to",0))<int(phase.get("from",1)): return "About to fight"
	return "Day %d" % step


## The balance as odds, from the engine's measure of who is winning (the
## bar): "about 3 to 2 for us", "about even". "" before the first blow.
static func odds_words(progress:float,player:bool,left_name:String,right_name:String)->String:
	var p:=clampf(progress,-1.0,1.0)
	if absf(p)>=0.999: return ""
	var ratio:=(1.0+absf(p))/maxf(0.001,1.0-absf(p))
	var Odds:=preload("res://scripts/war_odds.gd")
	var said:=Odds.words(ratio,p>=0.0)
	if player: return said
	return said.replace("for us","for %s" % left_name).replace("against us","for %s" % right_name)


## The same, short: "3:2", "even", ">5:1".
static func odds_short(progress:float)->String:
	var p:=clampf(progress,-1.0,1.0)
	if absf(p)>=0.999: return ""
	var ratio:=(1.0+absf(p))/maxf(0.001,1.0-absf(p))
	return preload("res://scripts/war_odds.gd").short(ratio,p>=0.0)
