extends RefCounted
## Contacts are evaluated after every civilization has completed the same day.
## Damage is then committed together, so controller order grants no first strike.
## Afterwards each civilization learns what other peoples' fleets are doing to
## it: blockades of its ports and raiders on its sea lanes (share_sea_pressure).
const R=preload("res://scripts/joint_regions.gd")
const B=preload("res://scripts/joint_battle.gd")
const AN=preload("res://scripts/air_naval_consequences.gd")
const Combat=preload("res://scripts/civilization_combat.gd")
const Tactics=preload("res://scripts/battle_tactics.gd")
const Blockade=preload("res://scripts/naval_blockade.gd")
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
				if not damage.has(key):damage[key]={"actor":other.owner,"force_id":target.id,"amount":0.0,"source":"","source_force":0,"source_domain":"","best":0.0}
				damage[key].amount+=amount
				# The strongest attacker today takes any prisoners and the credit.
				if amount>float(damage[key].best):
					damage[key].best=amount;damage[key].source=String(source.owner);damage[key].source_force=int(observer.id);damage[key].source_domain=String(observer.domain)
		)
	for entry in damage.values():
		var sunk:int=WorldSimulation.scoped(String(entry.actor),func()->int:
			var op=WorldSimulation.military.joint_operations
			var force:Dictionary=op.force(int(entry.force_id))
			if force.is_empty():return 0
			var before:int=op.hardware(force)
			op._losses(force,float(entry.amount),String(entry.source),String(entry.source_domain))
			return before-int(op.hardware(force))
		)
		if sunk>0 and String(entry.source)!="":
			WorldSimulation.scoped(String(entry.source),func()->void:WorldSimulation.military.joint_operations.commander_victory(int(entry.source_force),sunk))
	share_sea_pressure(day)

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

## Every civilization's own ledger holds the blockades its fleets keep; the
## blockaded people must feel them. Each day the blockaded ports are mirrored
## into the target's own ledger (entries marked "mirrored", keyed by its own
## city id), so its food, trade, supply and map read them. Commerce raiders
## likewise press on the sea trade of every people whose ports lie near their
## zone, against that people's own convoy escorts (air_naval_consequences.gd).
static func share_sea_pressure(day:int)->void:
	var ids:Array=WorldSimulation.actors.keys();ids.append("player");ids.sort()
	var incoming:Dictionary={}
	var raids:Dictionary={}
	var outgoing:Dictionary={}
	for owner:String in ids:
		WorldSimulation.scoped(owner,func()->void:
			var op=WorldSimulation.military.joint_operations
			var ledger:Dictionary=op.state.get("blockades",{})
			for city_id in ledger:
				var e:Dictionary=ledger[city_id]
				if bool(e.get("mirrored",false)) or String(e.get("owner",""))!="player":continue
				var view:=String(e.get("civ_id",""))
				var target:=Combat.owner(view)
				if view=="" or target==owner or (target!="player" and not WorldSimulation.actors.has(target)):continue
				var local:=Combat.local_city(view,String(city_id))
				if local=="":continue
				var bucket:Dictionary=incoming.get_or_add(target,{})
				if float((bucket.get(local,{}) as Dictionary).get("level",-1.0))>=float(e.get("level",0.0)):continue
				bucket[local]={"level":float(e.get("level",0.0)),"held":bool(e.get("held",false)),"since":int(e.get("since",day)),"day":day,"civ_id":"player","owner":AN.view_id(owner),"tactic":String(e.get("tactic","")),"name":"","mirrored":true}
			var cities:Array=[]
			for force:Dictionary in op.state.forces:
				if force.owner!="player" or force.domain!="navy" or force.mission!="convoy_raiding" or float(force.efficiency)<=0 or force.region.is_empty():continue
				if cities.is_empty():cities=WorldSimulation.world.city_intelligence.known_cities("player","",false)
				var center:Vector2=op.point(force.region)
				var power:float=op._power(force,"attack")*Tactics.zone_factor(String(force.get("tactic","")),"damage")
				var hit:Dictionary={}
				for city:Dictionary in cities:
					var view:=String(city.get("controller",city.get("civ_id","")))
					if not op._hostile("player",view):continue
					var at:Vector2=op.point(city)
					if at.distance_to(center)>250.0 and not R.contains(force.region,at):continue
					var target:=Combat.owner(view)
					if target==owner or hit.has(target) or (target!="player" and not WorldSimulation.actors.has(target)):continue
					hit[target]=true
					var pressure:Dictionary=raids.get_or_add(target,{"raid":0.0,"by":[]})
					pressure.raid=float(pressure.raid)+power
					if not (pressure.by as Array).has(AN.view_id(owner)) and (pressure.by as Array).size()<4:(pressure.by as Array).append(AN.view_id(owner))
		)
	for owner:String in ids:
		WorldSimulation.scoped(owner,func()->void:
			var op=WorldSimulation.military.joint_operations
			var ledger:Dictionary=op.state.get_or_add("blockades",{})
			var mine:Dictionary=incoming.get(owner,{})
			for key in ledger.keys():
				if bool((ledger[key] as Dictionary).get("mirrored",false)) and not mine.has(key):ledger.erase(key)
			for local in mine:
				var entry:Dictionary=mine[local]
				if not ledger.has(local) and ledger.size()>=Blockade.MAX_PORTS:continue
				var fresh:=not ledger.has(local)
				entry.name=String(WorldSimulation.settlements.settlement_record(String(local)).get("name","Our harbour"))
				ledger[local]=entry
				if fresh:op._event("Enemy ships are blockading %s." % String(entry.name),"navy")
			var pressure:Dictionary=raids.get(owner,{})
			var escort:=0.0
			for force:Dictionary in op.state.forces:
				if force.owner=="player" and force.mission=="convoy_escort" and float(force.efficiency)>0:escort+=op._power(force,"attack")+op._power(force,"detection")
			var level:=AN.raiding_level(float(pressure.get("raid",0.0)),escort)
			var previous:Dictionary=op.state.get("raiding",{})
			if level<=.001:
				op.state.erase("raiding")
				return
			var carry:=float(previous.get("carry",0.0))+WorldSimulation.state.population_exact*level*AN.MERCHANT_DEATH_RATE
			var dead:=floori(carry);carry-=float(dead)
			var by:Array=pressure.get("by",[])
			if dead>0:
				var count:=int(WorldSimulation.state.register_population_deaths(dead,"Lost at sea").get("count",0))
				AN.note_losses(owner,Combat.owner(String(by[0])) if not by.is_empty() else "",{"civilian_dead":count},{})
			op.state["raiding"]={"level":level,"by":by.duplicate(),"day":day,"since":int(previous.get("since",day)),"carry":carry}
			for raider in by:(outgoing.get_or_add(Combat.owner(String(raider)),{}) as Dictionary)[AN.view_id(owner)]=level
			if float(previous.get("level",0.0))<.05 and level>=.05:
				op._event("Enemy raiders are sinking our merchant ships: sea trade %d%% down." % roundi(level*100),"navy")
		)
	# What each raiding people knows of its own work: the other side's losses.
	for owner:String in ids:
		WorldSimulation.scoped(owner,func()->void:
			var op=WorldSimulation.military.joint_operations
			var mine:Dictionary=outgoing.get(owner,{})
			var before:Dictionary=op.state.get("raids_out",{})
			if mine.is_empty():
				op.state.erase("raids_out");return
			for view in mine:
				if float(before.get(view,0.0))<.05 and float(mine[view])>=.05:
					op._event("Our raiders are sinking merchant ships bound for %s: their sea trade is %d%% down." % [_people_name(String(view)),roundi(float(mine[view])*100)],"navy")
			op.state["raids_out"]=mine
		)

static func _people_name(view:String)->String:
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if String(civ.get("id",""))==view:return String(civ.get("name","the enemy"))
	return "the enemy"
