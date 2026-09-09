extends RefCounted
## Contacts are evaluated after every civilization has completed the same day.
## Damage is then committed together, so controller order grants no first strike.
const R=preload("res://scripts/joint_regions.gd")
const B=preload("res://scripts/joint_battle.gd")
static func advance(day:int)->void:
	var forces:Array[Dictionary]=[]
	var ids:Array=WorldSimulation.actors.keys();ids.append("player");ids.sort()
	for owner:String in ids:
		WorldSimulation.scoped(owner,func()->void:
			var op=WorldSimulation.military.joint_operations
			for force:Dictionary in op.state.forces:
				if force.owner!="player":continue
				forces.append({"owner":owner,"force":force,"position":op.force_position(force),"docked":op.docked(force)})
		)
	var damage:Dictionary={}
	for source in forces:
		WorldSimulation.scoped(String(source.owner),func()->void:
			var op=WorldSimulation.military.joint_operations
			var observer:Dictionary=source.force
			if float(observer.efficiency)<=0 or observer.region.is_empty():return
			for other in forces:
				if source.owner==other.owner:continue
				var target_id:="human" if String(other.owner)=="player" else String(other.owner)
				if not op._hostile("player",target_id):continue
				var target:Dictionary=other.force
				var target_position:Vector2=other.position
				if target.domain=="air" and float(target.efficiency)>0 and not target.region.is_empty():target_position=op.point(target.region)
				var overlap:float=R.overlap(observer.region,target.region) if target.domain=="air" and observer.domain=="air" and float(target.efficiency)>0 else (1.0 if R.contains(observer.region,target_position) else 0.0)
				if overlap<=0:continue
				if observer.domain=="navy" and (target.domain=="air" or (source.position as Vector2).distance_to(target_position)>maxf(20,minf(150,op.speed(observer)*.25))):continue
				var rng:=RandomNumberGenerator.new()
				rng.seed=WorldSimulation.state.world_seed^day*104729^hash("%s:%d" % [source.owner,observer.id])^hash("%s:%d" % [other.owner,target.id])
				var detected:float=op._power(observer,"detection")/(5.0+op._power(target,"defense"))*B.detection_multiplier(observer,target)*overlap
				if rng.randf()>clampf(detected,.08,.98):continue
				var key:="%s:%d" % [other.owner,target.id]
				op.state.contacts[key]={"observer":"player","target":target.id,"target_actor":other.owner,"region":observer.region.id,"day":day,"name":target.name,"position":{"x":target_position.x,"z":target_position.y},"owner":target_id,"domain":target.domain}
				if not op.can_attack_contact(observer,target,other.position,bool(other.docked)):continue
				var defense:float=maxf(1,op._power(target,"defense")/maxi(1,op.hardware(target)))
				var amount:float=op._power(observer,"attack")/defense*.12*rng.randf_range(.7,1.3)*overlap*B.damage_multiplier(observer,target)
				if not damage.has(key):damage[key]={"actor":other.owner,"force_id":target.id,"amount":0.0}
				damage[key].amount+=amount
		)
	for entry in damage.values():
		WorldSimulation.scoped(String(entry.actor),func()->void:
			var op=WorldSimulation.military.joint_operations
			var force:Dictionary=op.force(int(entry.force_id))
			if not force.is_empty():op._losses(force,float(entry.amount))
		)

static func mission_power(owner:String,region:Dictionary,mission:String,hostile:bool)->float:
	var observer:=WorldSimulation.actor_id
	var root_op=WorldSimulation.military.joint_operations
	var total:=0.0
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		var foreign_id:="human" if id=="player" else id
		if hostile:
			if id==observer or not root_op._hostile(owner,foreign_id):continue
		elif id!=observer:continue
		var value:float=WorldSimulation.scoped(id,func()->float:
			var power:=0.0;var op=WorldSimulation.military.joint_operations
			for force:Dictionary in op.state.forces:
				if force.owner!="player" or float(force.efficiency)<=0 or force.mission!=mission:continue
				power+=(op._power(force,"attack")+op._power(force,"detection"))*R.overlap(region,force.region)
			return power
		)
		total+=value
	return total
