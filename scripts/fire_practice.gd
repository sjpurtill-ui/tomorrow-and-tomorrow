extends RefCounted
## Bounded settlement fire continuity. Knowledge permits actions; this record
## tracks whether a usable ember bed physically survives at the current site.

const MAINTENANCE_TIMBER:=0.015
const FRICTION_TIMBER:=0.030
const PERCUSSION_TIMBER:=0.012
const PERCUSSION_STONE:=0.001

static func empty_state()->Dictionary:
	return {"initialized":false,"embers":0.0,"last_day":-1,"source":"none","last_event":"No maintained fire","fuel_today":0.0,"ignitions":0,"extinctions":0}

static func data()->Dictionary:
	var state:Dictionary=WorldSimulation.state.fire_practice
	for key in empty_state():
		if not state.has(key):state[key]=empty_state()[key]
	return state

static func available()->bool:
	return float(data().embers)>0.05

static func ensure_initialized()->void:
	_bootstrap(data())

static func _knows(id:String)->bool:
	return id in WorldSimulation.state.known_discoveries

static func _has_legacy_fire_knowledge()->bool:
	for id:String in ["hearth_roasting_control","charcoal","smoking","pit_firing"]:
		if _knows(id):return true
	return false

static func _consume(resource:String,amount:float)->bool:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	if float(stocks.get(resource,0.0))+0.0000001<amount:return false
	stocks[resource]=maxf(0.0,float(stocks.get(resource,0.0))-amount)
	return true

static func _bootstrap(state:Dictionary)->void:
	if bool(state.initialized):return
	state.initialized=true
	# Establishing Ember Tending means a found or transferred fire was actually
	# present during the repeated observations. Old saves with a downstream fire
	# practice receive the same one-time continuity migration.
	var old_fire_knowledge:=_has_legacy_fire_knowledge()
	if _knows("ember_tending") or old_fire_knowledge:
		state.embers=0.60
		state.source="found_or_transferred"
		state.last_event="A found or transferred fire supplied the first maintained embers"

static func _ignite(state:Dictionary)->bool:
	if _knows("percussion_fire_ignition") and _consume("Timber",PERCUSSION_TIMBER):
		if _consume("Stone",PERCUSSION_STONE):
			state.embers=0.62;state.source="percussion";state.ignitions=int(state.ignitions)+1
			state.fuel_today=float(state.fuel_today)+PERCUSSION_TIMBER
			state.last_event="Percussion ignition restored the fire"
			return true
		# Return tinder when the striker material is absent.
		WorldSimulation.state.resource_stockpiles.Timber=float(WorldSimulation.state.resource_stockpiles.get("Timber",0.0))+PERCUSSION_TIMBER
	if _knows("friction_fire_ignition") and _consume("Timber",FRICTION_TIMBER):
		state.embers=0.58;state.source="friction";state.ignitions=int(state.ignitions)+1
		state.fuel_today=float(state.fuel_today)+FRICTION_TIMBER
		state.last_event="Friction ignition restored the fire"
		return true
	return false

static func advance(day:int,wants_fire:bool,traveling:bool=false)->Dictionary:
	var state:=data()
	if int(state.last_day)==day:return report()
	state.last_day=day;state.fuel_today=0.0
	_bootstrap(state)
	if traveling or not WorldSimulation.state.settlement_site_committed:
		state.embers=maxf(0.0,float(state.embers)-0.20)
		if not available():state.last_event="No maintained settlement fire while traveling"
		return report()
	if available():
		if (_knows("ember_tending") or _has_legacy_fire_knowledge()) and _consume("Timber",MAINTENANCE_TIMBER):
			state.fuel_today=MAINTENANCE_TIMBER
			var adoption:=clampf(WorldSimulation.discovery.adoption("ember_tending"),0.0,1.0)
			state.embers=minf(1.0,float(state.embers)+0.05+adoption*0.10)
			state.last_event="Embers were sheltered and fed"
		else:
			state.embers=maxf(0.0,float(state.embers)-0.55)
			state.last_event="The ember bed weakened without tending fuel"
			if not available():state.extinctions=int(state.extinctions)+1;state.source="none"
	if not available() and wants_fire:_ignite(state)
	return report()

static func report()->Dictionary:
	var state:=data()
	return {"available":available(),"embers":float(state.embers),"source":String(state.source),"status":String(state.last_event),"maintenance_timber":float(state.fuel_today),"ignitions":int(state.ignitions),"extinctions":int(state.extinctions)}

static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	var state:Dictionary=value
	for key:String in ["initialized","embers","last_day","source","last_event","fuel_today","ignitions","extinctions"]:
		if not state.has(key):return false
	if not state.initialized is bool or not state.last_day is int:return false
	if not state.source is String or not state.last_event is String:return false
	for key:String in ["embers","fuel_today","ignitions","extinctions"]:
		var number:Variant=state[key]
		if not (number is int or number is float) or not is_finite(float(number)) or float(number)<0.0:return false
	return float(state.embers)<=1.000001
