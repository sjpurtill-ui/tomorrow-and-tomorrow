extends RefCounted
## A paid embassy may send agreed records through paired operating radio stations.
## No remote negotiation, discovery grant, specimen delivery, or travel mutation.
const E=preload("res://scripts/society_exchange.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const RANGE_KM:=120.0
static func eligible(item:Dictionary)->bool:
	return item.get("kind","")=="knowledge" and (bool(item.get("research_purchase",false)) or bool(item.get("research_partnership",false)) or bool(item.get("partnership_protocol",false)))
static func valid_receipts(mission:Dictionary)->bool:
	var receipts:Variant=mission.get("transmitted_collections",[])
	if not E.text_list(receipts,256):return false
	var carried:Variant=mission.get("carried_collections",[])
	if not carried is Array:return false
	for item:Variant in carried:
		if not item is Dictionary:return false
	var seen:Array=[]
	for id:String in receipts:
		if id in seen:return false
		seen.append(id)
		var found:=false
		for item:Dictionary in mission.get("carried_collections",[]):
			if item.get("id","")==id and eligible(item):found=true;break
		if not found:return false
	return true
static func delivered(mission:Dictionary,id:String)->bool:
	return id in mission.get("transmitted_collections",[]) and E.data().collections.has(id)
static func capacity(state:Node,day:int)->float:
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return 0.0
	var ledger:Dictionary=state.technology_operations
	# Actors advance sequentially. Unspent previous-day station duty is a bounded
	# receive buffer; older duty expires and no new power or work is synthesized.
	if int(ledger.last_day)<day-1 or int(ledger.last_day)>day:return 0.0
	var station:Dictionary=ledger.plants.get("research_radio_station",{})
	if not bool(station.get("enabled",false)) or int(station.get("installed",0))<1:return 0.0
	return maxf(0,float(ledger.services.get("radio_records",0)))
static func transmit(mission:Dictionary,day:int)->int:
	if not bool(mission.get("accepted",false)) or bool(mission.get("research_refused",false)):return 0
	if day<int(mission.get("arrival_day",day+1)) or day>=int(mission.get("return_day",day)):return 0
	if mission.get("target_kind","")!="known settlement":return 0
	var peer:=E.owner_id(String(mission.get("civ_id","")))
	if peer==WorldSimulation.actor_id or String(mission.get("civ_id","")) not in mission.get("encountered_societies",[]):return 0
	var remote:=E.owner_state(peer)
	if remote==null or capacity(WorldSimulation.state,day)<1 or capacity(remote,day)<1:return 0
	var index:int=WorldSimulation.world._civilization_index(String(mission.civ_id))
	if index<0 or bool(WorldSimulation.world.civilizations[index].player_relation.get("at_war",false)):return 0
	var home:Vector2=WorldSimulation.world.player_world_origin
	var other:Vector2=WorldSimulation.scoped(peer,func()->Vector2:return WorldSimulation.world.player_world_origin)
	var target:Dictionary=mission.get("target_position",{})
	var origin:Dictionary=mission.get("origin_position",{})
	if not target.has_all(["x","z"]) or not origin.has_all(["x","z"]):return 0
	if home.distance_to(Vector2(float(origin.x),float(origin.z)))>E.CONTACT_RADIUS:return 0
	if other.distance_to(Vector2(float(target.x),float(target.z)))>E.CONTACT_RADIUS or home.distance_to(other)>RANGE_KM:return 0
	var count:=0
	for item:Dictionary in mission.get("carried_collections",[]):
		if not eligible(item) or E.owner_id(String(item.get("source_id","")))!=peer:continue
		if E.data().collections.has(item.id) or E.data().collections.size()>=E.COLLECTION_LIMIT:continue
		if capacity(WorldSimulation.state,day)<1 or capacity(remote,day)<1:break
		WorldSimulation.state.technology_operations.services.radio_records-=1.0
		remote.technology_operations.services.radio_records-=1.0
		var record:=item.duplicate(true);record.returned_day=day
		record.acquisition=String(record.get("acquisition",""))+"; transmitted through paired staffed radio stations"
		E.data().collections[item.id]=record
		if not mission.has("transmitted_collections"):mission.transmitted_collections=[]
		mission.transmitted_collections.append(item.id)
		count+=1
	if count>0:
		E.log_event("Radio delivered %d agreed research record(s); local study is still required. Envoys remain on their journey." % count)
		mission.outcome=String(mission.get("outcome",""))+" Research records were sent home by radio."
	return count
