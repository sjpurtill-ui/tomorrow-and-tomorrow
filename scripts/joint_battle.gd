extends RefCounted
## Aggregate fleet composition and aircraft performance in an operating area.
const C=preload("res://scripts/joint_force_catalog.gd")
const SCREENS=["torpedo_boat","destroyer","light_cruiser","missile_patrol","missile_destroyer"]
const CAPITALS=["heavy_cruiser","battleship","aircraft_carrier"]
const SUBMARINES=["submarine","nuclear_submarine"]
static func count(force:Dictionary,types:Array)->int:
	var total:=0
	for id:String in types:total+=int(force.units.get(id,0))
	return total
static func screening(force:Dictionary)->float:
	return clampf(float(count(force,SCREENS))/maxf(1,count(force,CAPITALS)*3.0),0,1)
static func mean_stat(force:Dictionary,stat:String)->float:
	var total:=0.0;var count:=0
	for id:String in force.units:
		total+=float(C.UNITS[id].get(stat,0))*int(force.units[id]);count+=int(force.units[id])
	return total/maxi(1,count)
static func damage_multiplier(attacker:Dictionary,defender:Dictionary)->float:
	if attacker.domain=="air" and defender.domain=="air":
		# A fast interceptor can bring guns to bear and break contact more readily.
		var speed_ratio:=mean_stat(attacker,"speed_km_day")/maxf(1,mean_stat(defender,"speed_km_day"))
		return clampf(sqrt(speed_ratio),.65,1.5)
	if defender.domain=="navy":
		var protected:=screening(defender) if count(defender,CAPITALS)>0 else 0.0
		if count(attacker,SUBMARINES)>0:return 1.5-protected
		if attacker.domain=="air":return 1.0-protected*.35
	return 1.0
static func detection_multiplier(observer:Dictionary,target:Dictionary)->float:
	if target.domain=="navy" and count(target,SUBMARINES)>0:
		return .65 if count(observer,SCREENS)>0 or observer.domain=="air" else .15
	return 1.0
