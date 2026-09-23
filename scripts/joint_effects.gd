extends RefCounted
const R=preload("res://scripts/joint_regions.gd")
const G=preload("res://scripts/joint_geography.gd")
var _owner:WeakRef
var op:RefCounted:
	get:return _owner.get_ref()
func _init(operations:RefCounted)->void:_owner=weakref(operations)

func same_region(first:Dictionary,second:Dictionary)->bool:
	return R.overlap(first,second)>0
func mission_power(owner:String,region:Dictionary,mission:String,hostile:bool=false)->float:
	if WorldSimulation.enabled:return preload("res://scripts/civilization_joint_contact.gd").mission_power(owner,region,mission,hostile)
	var total=0.0
	for force:Dictionary in op.state.forces:
		if float(force.efficiency)<=0 or force.mission!=mission or not same_region(force.region,region):continue
		if (hostile and op._hostile(owner,String(force.owner))) or (not hostile and force.owner==owner):total+=(op._power(force,"attack")+op._power(force,"detection"))*R.overlap(region,force.region)
	return total
func control(owner:String,region:Dictionary)->float:
	var own=0.0;var hostile=0.0
	var missions:Array=["air_superiority"] if region.get("domain","")=="air" else ["patrol","strike_force","convoy_raiding"]
	for mission:String in missions:
		own+=mission_power(owner,region,mission);hostile+=mission_power(owner,region,mission,true)
	return own/maxf(.001,own+hostile) if own>0 else 0.0

func advance(day:int)->void:
	for army:Dictionary in [op.host.home_army]+op.host.field_armies:
		var location=G.unpack(army.get("position",{}))
		if army==op.host.home_army:
			var city=WorldSimulation.world.city_intelligence.site(WorldSimulation.world.city_intelligence.primary_id("player"))
			if not city.is_empty():location=G.unpack(city.position)
		var region:Dictionary=op.region_at(location,"air")
		army.joint_air_support=clampf(mission_power("player",region,"close_air_support")/maxf(10,float(army.get("troops",0))),0,.3)
		army.joint_air_pressure=clampf(mission_power("player",region,"air_superiority",true)/maxf(10,float(army.get("troops",0))),0,.25)
		var disruption=mission_power("player",region,"logistics_strike",true)
		army.supply_level=maxf(0,float(army.get("supply_level",1))-minf(.1,disruption*.001))
	var engagement:Dictionary=op.host.active_engagement
	if not engagement.is_empty():
		var own_side=String(op.host._engagement_home_side(engagement))
		var enemy_side=String(op.host._engagement_enemy_side(engagement))
		var friendly:Dictionary=engagement.get(own_side,{})
		var enemy:Dictionary=engagement.get(enemy_side,{})
		var supporting:Dictionary=op.host.home_army
		var field_index:int=op.host._field_army_index(int(engagement.get("home_force_id",0)))
		if field_index>=0:supporting=op.host.field_armies[field_index]
		friendly.joint_air_support=float(supporting.get("joint_air_support",0))
		friendly.joint_air_pressure=float(supporting.get("joint_air_pressure",0))
		enemy.joint_air_pressure=friendly.joint_air_support*.6
	for force:Dictionary in op.state.forces:
		if float(force.efficiency)<=0:continue
		if force.mission=="air_supply":_supply(force);continue
		if force.mission=="reconnaissance":
			for city:Dictionary in WorldSimulation.world.city_intelligence.sites():
				if same_region(op.region_at(G.unpack(city.position),"air"),force.region):WorldSimulation.world.city_intelligence.publish(String(force.owner),WorldSimulation.world.city_intelligence.capture(String(force.owner),String(city.city_id),.65,day,"air reconnaissance",str(force.id)),day)
		if force.mission not in ["strategic_bombing","logistics_strike","invasion_support"]:continue
		var targets:Array=WorldSimulation.world.city_intelligence.known_cities(String(force.owner),"",false)
		for city:Dictionary in targets:
			if not op._hostile(String(force.owner),String(city.get("controller",city.civ_id))) or not same_region(op.region_at(G.unpack(city.position),String(force.domain)),force.region):continue
			var damage=minf(.025,op._power(force,"attack")*.00025)
			if WorldSimulation.enabled:
				preload("res://scripts/civilization_combat.gd").damage_city(String(city.civ_id),String(city.city_id),damage)
				continue
			if String(city.civ_id)=="player":
				WorldSimulation.settlements.with_city_resources(String(city.city_id),func():
					for plot:Dictionary in WorldSimulation.state.settlement_plots:
						if String(plot.get("land_use","")) in ["workshop","mixed_household","storehouse"]:plot.condition=maxf(.05,float(plot.get("condition",1))-damage)
					WorldSimulation.state.morphology_revision+=1
					WorldSimulation.settlements.rebuild_summary())
			else:
				var location:Dictionary=WorldSimulation.world._region_location(String(city.city_id))
				if location.is_empty():continue
				var civ:Dictionary=WorldSimulation.world.civilizations[int(location.owner_index)]
				var region:Dictionary=civ.strategic_regions[int(location.region_index)]
				if force.mission=="invasion_support":region.fortification=maxf(0,float(region.fortification)-damage)
				else:region.damage=minf(1,float(region.damage)+damage)
				if force.mission=="logistics_strike":civ.logistics=maxf(.02,float(civ.logistics)-damage*.2)
			for base:Dictionary in op.state.bases:
				if base.city_id==city.city_id:base.condition=maxf(0,float(base.condition)-damage)

func _supply(force:Dictionary)->void:
	if force.owner!="player":return
	var origin:Dictionary=op.base(int(force.base_id))
	var capacity=float(op.logistics.capacity(force))*float(force.efficiency)
	if capacity<=0:return
	for army:Dictionary in op.host.field_armies:
		if bool(army.get("embarked",false)) or not same_region(op.region_at(G.unpack(army.get("position",{})),"air"),force.region):continue
		var need=maxf(0,float(army.get("troops",0))*3.5-float(army.get("delivered_field_food",0)))
		var amount:float=WorldSimulation.settlements.with_city_resources(String(origin.city_id),func():return WorldSimulation.food.issue_for_obligation(minf(need,capacity),"military","Air-dropped field supplies",0,0))
		army.delivered_field_food=float(army.get("delivered_field_food",0))+amount
		capacity-=amount
		if capacity<=0:return
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if city.id==origin.city_id or not same_region(op.region_at(Vector2(city.get("position",Vector2.ZERO)),"air"),force.region):continue
		var amount:float=WorldSimulation.settlements.with_city_resources(String(origin.city_id),func():return WorldSimulation.food.issue_for_obligation(capacity,"military","Air supply to "+String(city.name),0,0))
		WorldSimulation.settlements.with_city_resources(String(city.id),func():WorldSimulation.food.receive_external_food(amount))
		return
