class_name BattleContact
extends RefCounted

## Choreography for at most 192 representatives, never combat authority.
## Paired opponents share a cycle: wind-up, contact, recoil, recovery.
var pairs:Array[Dictionary]=[]
var strike_count:=0
var last_beats:Dictionary={}

func configure(view:Node3D)->void:
	pairs.clear(); last_beats.clear(); strike_count=0
	for group:Dictionary in view.groups:
		var material:ShaderMaterial=group.batch.material_override
		material.shader=preload("res://scripts/battle_contact.gdshader")
		var clips:Dictionary=ArmyFigureFormation._asset(group.id).data.clips
		for clip:String in ["idle","walk","attack"]:
			material.set_shader_parameter("battle_"+clip,Vector2(clips[clip].start,clips[clip].count))
		group["contact_slots"]={}
	for role:String in ["melee","mobile"]:
		var sides:Array=[[],[]]
		for group:Dictionary in view.groups:
			if String(group.role)!=role: continue
			for i in group.poses.size(): sides[group.side].append({"group":group,"index":i})
		for slot in mini(sides[0].size(),sides[1].size()):
			var a:Dictionary=sides[0][slot]; var b:Dictionary=sides[1][slot]
			var mounted:=role=="mobile"
			var gap:=3.3 if mounted else (2.5 if a.group.id in ["line_infantry","pike_phalanx"] or b.group.id in ["line_infantry","pike_phalanx"] else 1.25)
			var columns:=3 if mounted else 9
			var center:=Vector2((slot%columns-(columns-1)*.5)*(4.6 if mounted else 2.6)+(28 if mounted else 0),floorf(float(slot)/columns)*4.4-5)
			pairs.append({"a":a,"b":b,"center":center,"gap":gap,"slot":slot,"mounted":mounted})

static func attack_state(clock:float,slot:int,side:int)->Dictionary:
	var period:=4.3+fposmod(float(slot)*.317,1.1)
	var duration:=1.05+fposmod(float(slot)*.137,.25)
	var start:=.12 if side==0 else period*.53
	var elapsed:=fposmod(clock+float(slot)*.731,period)-start
	var progress:=clampf(elapsed/duration,0,1)
	var striking:=elapsed>=0 and elapsed<duration
	return {"striking":striking,"progress":progress,"impact":exp(-pow((progress-.48)/.065,2)) if striking else 0.0,"beat":floori((clock+float(slot)*.731)/period)}

func advance(view:Node3D)->void:
	var active:bool=not view.record.is_empty() and view.outcome in ["","continued","inconclusive"]
	# Non-contact ranks/ranged equipment remain on their proper ground too.
	for group:Dictionary in view.groups:
		for i in group.poses.size():
			if group.dead[i]: continue
			var pose:Transform3D=group.batch.multimesh.get_instance_transform(i)
			var world:Vector3=view.armies[group.side].to_global(pose.origin)
			world.y=view.landscape.height_at(Vector2(world.x,world.z))
			pose.origin=view.armies[group.side].to_local(world)
			group.batch.multimesh.set_instance_transform(i,pose)
			var ranged_attack:bool=active and group.role in ["ranged","siege"] and view._can_attack(group)
			group.batch.multimesh.set_instance_custom_data(i,Color(fposmod(view.clock/1.75+float(i%7)*.11,1),0,0,1 if ranged_attack else 0))
	for pair in pairs:
		var a:Dictionary=pair.a; var b:Dictionary=pair.b
		var connected:bool=not a.group.dead[a.index] and not b.group.dead[b.index]
		for side in 2:
			var entry:Dictionary=a if side==0 else b
			var group:Dictionary=entry.group; var index:int=entry.index
			if group.dead[index] or view._routed(side): continue
			var action:=attack_state(view.clock,int(pair.slot),side)
			var opponent:=attack_state(view.clock-.06,int(pair.slot),1-side)
			var striking:bool=bool(action.striking)
			var progress:float=action.progress
			var contact:float=action.impact if connected and active else 0.0
			var reaction:float=opponent.impact if connected and active else 0.0
			var sign:=1.0 if side==0 else -1.0
			# Roots stay planted after approach. Existing weapon/arm VAT poses carry
			# the strike; no reciprocal whole-body translation or leaning.
			var destination:=Vector3(pair.center.x+sin(pair.slot*1.9)*.12,0,pair.center.y-sign*float(pair.gap)*.5)
			var start:Vector3=view.armies[side].to_global(group.poses[index].origin)
			var world:Vector3=start.lerp(destination,smoothstep(0,2.5,view.clock))
			world.y=view.landscape.height_at(Vector2(world.x,world.z))
			var pose:=Transform3D(Basis.IDENTITY,view.armies[side].to_local(world))
			group.batch.multimesh.set_instance_transform(index,pose)
			var state:=4.0 if striking and active and connected else (2.0 if view.clock<2.5 else (3.0 if active and connected else 0.0))
			group.batch.multimesh.set_instance_custom_data(index,Color(progress,reaction,0,state))
			if striking and contact>.7:
				var key:="%s/%d/%d" % [group.role,pair.slot,side]
				var number:=int(action.beat)
				if int(last_beats.get(key,-999))!=number:
					last_beats[key]=number; strike_count+=1
					view.contact_flash(Vector3(world.x,world.y+1.25,pair.center.y),pair.slot)
	for group:Dictionary in view.groups:
		var middle:=Vector3.ZERO; var alive:=0
		for i in group.poses.size():
			if group.dead[i]: continue
			middle+=group.batch.multimesh.get_instance_transform(i).origin; alive+=1
		if alive>0:
			group.center=middle/float(alive)
			group.banner.position=group.center+Vector3(0,3.5,0)
			group.flag.position=group.center+Vector3(0,2.8,0)
