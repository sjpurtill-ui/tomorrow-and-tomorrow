extends RefCounted
## One siege advances once, with a defensive view in the other owner's command.
## Both views refer to the same physical city and investing army.
static func available(target:Dictionary)->bool:
	if target.is_empty():return true
	return WorldSimulation.scoped(String(target.actor),func()->bool:return WorldSimulation.military.active_siege.is_empty())
static func publish()->void:
	var siege:=WorldSimulation.military.active_siege
	if siege.is_empty() or siege.has("shared_source_actor"):return
	var target:Dictionary=siege.get("threat",{}).get("owned_target",{})
	if target.is_empty():return
	var source:=WorldSimulation.actor_id
	var mirror:=siege.duplicate(true)
	mirror.shared_source_actor=source
	mirror.mode="defensive";mirror.attacker_id="human" if source=="player" else source;mirror.defender_id="player";mirror.army_id=0
	var troops:Dictionary={}
	var index:=WorldSimulation.military._field_army_index(int(siege.army_id))
	if index>=0:troops=WorldSimulation.military.field_armies[index].duplicate(true)
	mirror.threat.merge({"campaign_mode":"defensive","source_civ_id":mirror.attacker_id,"field_army_id":0,"enemy_force":troops,"owned_target":{"actor":source,"field_id":int(siege.army_id),"city_id":""}},true)
	WorldSimulation.scoped(String(target.actor),func()->void:
		var current:=WorldSimulation.military.active_siege
		if not current.is_empty() and String(current.id)!=String(siege.id):return
		var city_id:=String(target.get("city_id",""))
		if city_id.is_empty():city_id=WorldSimulation.settlements._primary_settlement_id()
		var city:=WorldSimulation.settlements.settlement_record(city_id)
		mirror.home_city={"id":city_id,"name":city.get("name",WorldSimulation.state.settlement_name),"population":WorldSimulation.settlements._settlement_population(city),"defense_stage":int(WorldSimulation.military.settlement_defense.get("stage",0))}
		mirror.threat.target_region_id="";mirror.region_id=city_id
		if current.is_empty():WorldSimulation.diplomacy.notify_defensive_siege(String(mirror.attacker_id),"player",String(siege.id),int(siege.start_day))
		# Supplies already delivered to either approach remain attached to this siege.
		mirror.relief=siege.get("relief",[]).duplicate(true)
		for camp:Dictionary in mirror.relief:camp.beneficiary_id="player" if String(camp.beneficiary_id)==String(siege.defender_id) else mirror.attacker_id
		WorldSimulation.military.active_siege=mirror
		WorldSimulation.military.army_changed.emit(WorldSimulation.military.home_army.duplicate(true))
	)
static func target_status(threat:Dictionary)->Dictionary:
	var target:Dictionary=threat.get("owned_target",{})
	if target.is_empty():return {}
	return WorldSimulation.scoped(String(target.actor),func()->Dictionary:
		var city_id:=String(target.get("city_id",""))
		if city_id.is_empty():city_id=WorldSimulation.settlements._primary_settlement_id()
		var local:=WorldSimulation.settlements.city_resource_snapshot(city_id,false)
		return {"population":local.get("population",0),"food_days":local.get("metrics",{}).get("food_days",0)}
	)
static func order(siege:Dictionary,action:String)->Dictionary:
	var source:=String(siege.shared_source_actor)
	if action=="withdraw":
		var force:Dictionary=siege.threat.get("enemy_force",{})
		var result:=WorldSimulation.military.recovery.capture_city(String(siege.home_city.id),String(siege.attacker_id),force)
		if result.has("error"):return result
		WorldSimulation.scoped(source,func()->void:
			var active:=WorldSimulation.military.active_siege
			var region:=WorldSimulation.world.region_snapshot(String(active.defender_id),String(active.region_id))
			WorldSimulation.military.establish_occupation_force(String(active.defender_id),region,float(result.get("occupation_required",0)),int(active.army_id))
			WorldSimulation.military._end_siege("The defending city yields; occupation requires the investing army's personnel.",false)
		)
		return result
	return WorldSimulation.scoped(source,func()->Dictionary:
		var result:=WorldSimulation.military.siege_order(String(siege.id),action)
		# A defender's sortie meets the actual investing force. Its commander
		# resolves that battle through the ordinary campaign rounds.
		if action=="assault" and not result.has("error") and not WorldSimulation.military.active_engagement.is_empty():
			WorldSimulation.military.active_engagement.commander_managed=true
			WorldSimulation.military.command_hierarchy.battle.archive_active()
		return result
	)
static func ended(siege:Dictionary,reason:String)->void:
	if siege.has("shared_source_actor"):
		WorldSimulation.scoped(String(siege.shared_source_actor),func()->void:
			if String(WorldSimulation.military.active_siege.get("id",""))==String(siege.id):WorldSimulation.military._end_siege(reason)
		)
		return
	var target:Dictionary=siege.get("threat",{}).get("owned_target",{})
	if target.is_empty():return
	WorldSimulation.scoped(String(target.actor),func()->void:
		if String(WorldSimulation.military.active_siege.get("id",""))==String(siege.id):WorldSimulation.military._end_siege(reason,false,false)
	)
static func add_camp(camp:Dictionary)->void:
	var siege:=WorldSimulation.military.active_siege
	if not siege.has("shared_source_actor"):return
	var copied:=camp.duplicate(true)
	WorldSimulation.scoped(String(siege.shared_source_actor),func()->void:
		var active:=WorldSimulation.military.active_siege
		copied.beneficiary_id=active.defender_id
		active.relief.append(copied)
	)
static func camp_strength(camp:Dictionary)->int:
	if not camp.has("receipt_owner"):return int(camp.troops)
	return WorldSimulation.scoped(String(camp.receipt_owner),func()->int:
		for receipt:Dictionary in WorldSimulation.diplomacy.commitments.state.relief:
			if String(receipt.id)==String(camp.receipt_id) and receipt.has("owned_actor"):return preload("res://scripts/civilization_relief.gd").strength(receipt)
		return int(camp.troops)
	)
