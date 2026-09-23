extends RefCounted
## Multi-day steps for calm rival civilizations.
##
## The human civilization always advances one day at a time. A rival that is at
## peace, fed, stationary, and not fighting may instead advance its whole
## calendar every few days, covering the elapsed interval in one pass. Systems
## read `WorldSimulation.span` (1 outside such a step) and scale daily flows,
## per-day smoothing, and per-day chances accordingly. Every helper is exactly
## the daily formula when the span is 1, so ordinary days are unchanged.

## Longest interval a calm rival may cover in one step.
const MAX_SPAN:=3
## Longest interval for a calm rival the player has not yet met.
const UNCONTACTED_SPAN:=5
## A step never runs a town below this much stored food.
const MIN_FOOD_DAYS:=15.0

## Scales a per-day smoothing rate to the current span.
static func rate(daily:float)->float:
	var span:int=WorldSimulation.span
	return daily if span==1 else 1.0-pow(1.0-clampf(daily,0.0,1.0),span)

## Scales a per-day probability to the current span.
static func chance(daily:float)->float:
	var span:int=WorldSimulation.span
	return daily if span==1 else 1.0-pow(1.0-clampf(daily,0.0,1.0),span)

## Runs `op` once for each day the current step covers, with the calendar
## set to that day, for work that must stay strictly daily. Returns the last
## day's result.
static func each_day(op:Callable)->Variant:
	var span:int=WorldSimulation.span
	if span==1:return op.call()
	var state=WorldSimulation.state
	var today:float=state.elapsed_days
	for back in range(span-1,0,-1):
		state.elapsed_days=today-back
		op.call()
	state.elapsed_days=today
	return op.call()

## Days covered by the current step.
static func days()->int:
	return WorldSimulation.span

## Runs in the rival's own scope. True when the rival can wait until a later
## day and cover the interval in one step.
static func calm()->bool:
	if WorldSimulation.state.convoy_traveling or bool(WorldSimulation.state.settlement_convoy.get("active",false)):return false
	var military=WorldSimulation.military
	if not military.active_engagement.is_empty() or not military.active_threat.is_empty() or not military.active_siege.is_empty() or not military.pending_aftermath.is_empty():return false
	for army:Dictionary in military.field_armies:
		if String(army.get("status","stationed"))!="stationed":return false
	if int(WorldSimulation.world.player_effects().get("war_count",0))>0:return false
	if float(WorldSimulation.state.simulation_metrics.get("food_days",0.0))<MIN_FOOD_DAYS:return false
	if float(WorldSimulation.state.simulation_metrics.get("water_intake_ratio",0.0))<.98:return false
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		var metrics:Dictionary=city.get("resource_metrics",{})
		if float(metrics.get("food_days",0.0))<MIN_FOOD_DAYS or float(metrics.get("water_intake_ratio",0.0))<.98:return false
	return true

## Owner steps a calm secondary town may sit out before covering them at once.
const TOWN_STRIDE:=2
## A town with less stored food than this many days runs every owner step.
const TOWN_MIN_FOOD_DAYS:=25.0
## Longest interval a secondary town covers in one pass.
const TOWN_MAX_SPAN:=10

## Days a secondary town covers today, or 0 when it sits out this owner step.
## Runs in the owner's scope. Towns stagger by id so they do not all run on the
## same step; a hungry, thirsty, threatened or selected town runs every step.
static func town_span(city:Dictionary)->int:
	var day:=int(WorldSimulation.state.elapsed_days)
	var last:=int(city.get("last_resource_day",-1))
	if last<0 or last>=day:return 1
	var gap:=day-last
	if gap>=TOWN_MAX_SPAN or not _town_calm(city):return gap
	var step:=maxi(1,int(WorldSimulation.span))
	var stride:=TOWN_STRIDE if WorldSimulation.actor_id!="player" else TOWN_STRIDE+1
	if posmod(day/step+posmod(hash("town:"+String(city.get("id",""))),stride),stride)!=0:return 0
	return gap

static func _town_calm(city:Dictionary)->bool:
	if WorldSimulation.actor_id=="player" and String(city.get("id",""))==String(WorldSimulation.state.selected_player_settlement_id):return false
	var military=WorldSimulation.military
	if not military.active_engagement.is_empty() or not military.active_threat.is_empty() or not military.active_siege.is_empty():return false
	var metrics:Dictionary=city.get("resource_metrics",{})
	return float(metrics.get("food_days",0.0))>=TOWN_MIN_FOOD_DAYS and float(metrics.get("water_intake_ratio",0.0))>=.98
