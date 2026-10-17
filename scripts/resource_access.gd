extends RefCounted
## Negotiated use of a neighbour's existing deposit. Contracts refer to its
## authoritative record; they never copy reserves or manufacture workers.
const Hall=preload("res://scripts/audience_hall.gd")
const Society=preload("res://scripts/society_exchange.gd")
const Exchange=preload("res://scripts/civilization_exchange.gd")
const Ledger=preload("res://scripts/trade_ledger.gd")
const Reserves=preload("res://scripts/civilization_resources.gd")
const SHARE=0.25

static func contracts()->Array:
	var s:=Hall.state()
	if not s.get("resource_access") is Array:s.resource_access=[]
	return s.resource_access

static func find(id:String)->Dictionary:
	for c:Dictionary in contracts():
		if c.id==id:return c
	return {}

static func deposit(civ:String,id:String)->Dictionary:
	var owner:=Society.owner_state(civ)
	if owner==null:return {}
	for d:Dictionary in owner.resource_deposits:
		if String(d.get("id",""))==id:return d
	return {}

static func offer(civ:String)->Dictionary:
	if not bool(ForeignDiplomacy.civilization(civ).get("alive",false)) or Society.owner_state(civ)==null or Ledger.blocked("player",civ)!="":return {}
	for c:Dictionary in contracts():
		if c.status=="active":return {} # One crew commitment at a time.
	for d:Dictionary in Society.owner_state(civ).resource_deposits:
		if not String(d.get("resource","")) in ["Stone","Clay"] or not String(d.get("stage","")) in ["accessible","developed"]:continue
		if float(d.get("remaining",0))<=1 or not ResourceSystem.recognition_ready(String(d.resource)):continue
		var position:Vector3=d.get("position",Vector3.ZERO)
		var distance:=CivilizationSystem.player_world_origin.distance_to(Vector2(position.x,position.z))
		if distance>360:continue
		return {"deposit":String(d.id),"resource":String(d.resource),"travel":maxi(1,ceili(distance/12)),"duration":365,"royalty":0.25}
	return {}

static func sign(civ:String,terms:Dictionary)->Dictionary:
	var live:=offer(civ)
	if live.is_empty() or live!=terms:return {"error":"The deposit or access terms have changed. No agreement was made."}
	var day:=int(GameState.elapsed_days)
	var c:={"id":"access:"+str(day)+":"+str(Hall.state().serial)+":"+civ,"civ":civ,"deposit":String(terms.deposit),"resource":String(terms.resource),"travel":int(terms.travel),"royalty":float(terms.royalty),"start":day,"until":day+int(terms.duration),"status":"active","last":day,"delivered":0.0,"extracted":0.0,"paid":0.0,"workers":0.0,"carriers":0.0,"reason":"Crew travelling to the deposit","cargo":[]}
	for old:Dictionary in contracts().duplicate():
		if old.status!="active" and old.cargo.is_empty():contracts().erase(old)
	contracts().append(c)
	return {"ok":true,"contract":c}

static func stop(id:String,reason:String="Ended by your order")->void:
	var c:=find(id)
	if c.is_empty():return
	c.status="ended";c.reason=reason;c.workers=0.0;c.carriers=0.0

static func daily(day:int)->void:
	for c:Dictionary in contracts():
		if c.status=="active":
			var reason:=Ledger.blocked("player",String(c.civ),day)
			if reason!="":stop(String(c.id),"Access revoked: "+reason)
			elif day>=int(c.until):stop(String(c.id),"Agreement expired")
		# Loads already extracted belong to us and are already on the road.
		for parcel:Dictionary in c.cargo.duplicate():
			if int(parcel.due)>day:continue
			Exchange.receive("player",String(c.resource),float(parcel.amount))
			Ledger.note_flow(String(c.civ),"player",String(c.resource),float(parcel.amount),"resource_access")
			c.delivered+=float(parcel.amount);c.cargo.erase(parcel)

static func work(extractors:float,carriers:float,context:Dictionary)->Vector2:
	var available:=Vector2(extractors,carriers)
	if WorldSimulation.actor_id!="player":return available
	var town:=SettlementModel.settlement_record(String(GameState.resource_settlement_id))
	if not town.is_empty() and not bool(town.get("primary",false)):return available
	var day:=int(GameState.elapsed_days)
	daily(day)
	for c:Dictionary in contracts():
		if c.status!="active":continue
		var reserved:=Vector2(extractors*SHARE,carriers*SHARE)
		available-=reserved
		c.workers=reserved.x;c.carriers=reserved.y
		if int(c.last)>=day:continue
		var days:=mini(maxi(1,int(WorldSimulation.span)),day-int(c.last));c.last=day
		var productive_days:=mini(days,maxi(0,day-int(c.start)-int(c.travel)))
		if productive_days<=0:c.reason="Crew travelling to the deposit";continue
		var d:=deposit(String(c.civ),String(c.deposit))
		if d.is_empty() or not String(d.get("stage","")) in ["accessible","developed"]:stop(String(c.id),"The host can no longer provide this deposit");available+=reserved;continue
		if reserved.x<=0 or reserved.y<=0:c.reason="Needs people allocated to Extraction and Logistics";continue
		var profile:Dictionary=ResourceSystem._material_profile(String(c.resource))
		var pace:=reserved.x*float(profile.base_yield)*float(d.get("quality",1))*(0.55+float(context.get("tools",0))*0.75)*float(GameState.simulation_metrics.get("labor_efficiency",0.72))*ResourceSystem.depth_yield(d)
		pace=minf(pace,reserved.y/(float(c.travel)*float(profile.bulk)))
		var amount:=Reserves.withdraw(d,pace*productive_days) if WorldSimulation.enabled else minf(float(d.get("remaining",0)),pace*productive_days)
		d.remaining=maxf(0,float(d.get("remaining",0))-amount)
		d.lifetime_extracted=float(d.get("lifetime_extracted",0))+amount
		if amount<=0:stop(String(c.id),"The deposit is exhausted");available+=reserved;continue
		var royalty:=amount*float(c.royalty)
		Exchange.receive(String(c.civ),String(c.resource),royalty)
		c.extracted+=amount;c.paid+=royalty
		c.cargo.append({"due":day+int(c.travel),"amount":amount-royalty})
		c.reason=""
	return available

static func card(id:String)->Dictionary:
	var c:=find(id)
	if c.is_empty():return {"state":"done","line":"Agreement archived","progress":1.0,"moved":true}
	var ended:bool=c.status!="active" and c.cargo.is_empty()
	return {"state":"done" if ended else ("stalled" if c.reason!="" and day_ready(c) else "under_way"),"line":"%.1f %s delivered; %.1f paid to host. %s" % [float(c.delivered),String(c.resource),float(c.paid),String(c.reason)],"reason":String(c.reason),"progress":float(c.delivered)+float(c.extracted),"moved":float(c.extracted)>0 or not day_ready(c),"standing":c.status=="active"}

static func day_ready(c:Dictionary)->bool:
	return int(GameState.elapsed_days)>int(c.start)+int(c.travel)

static func valid(value:Variant)->bool:
	if not value is Array or value.size()>16:return false
	for c in value:
		if not c is Dictionary:return false
		for key in ["id","civ","deposit","resource","status","reason"]:
			if not c.get(key) is String or String(c[key]).length()>200:return false
		if not c.status in ["active","ended"] or not c.resource in ["Stone","Clay"]:return false
		for key in ["travel","royalty","start","until","last","delivered","extracted","paid","workers","carriers"]:
			if not Hall._num(c.get(key)) or float(c[key])<0:return false
		if float(c.royalty)>1 or float(c.travel)>30 or not c.get("cargo") is Array or c.cargo.size()>64:return false
		for p in c.cargo:
			if not p is Dictionary or not Hall._num(p.get("due")) or not Hall._num(p.get("amount")) or float(p.amount)<0:return false
	return true
