extends RefCounted
## Restrained UI motion from the ART_DIRECTION.md motion tokens.
## FAST 120 ms (hover/press), BASE 200 ms (dock slide, tab change),
## SLOW 360 ms (modal fade with an 8 px rise), SCENE 900 ms (stage change,
## discovery reveal). Cubic ease-out on entry, ease-in on exit.
## Every helper is a one-shot Tween: nothing runs once a transition ends.
## (These values mirror the HudTokens.MOTION token; keep them equal.)
const FAST:=0.12
const BASE:=0.20
const SLOW:=0.36
const SCENE:=0.90
const RISE:=8.0

## Honour a reduce_motion preference (a GameState field or project setting)
## by capping every duration at FAST.
static func duration(value:float)->float:
	var reduced:=bool(ProjectSettings.get_setting("application/config/reduce_motion",false))
	var main_loop:=Engine.get_main_loop()
	if main_loop is SceneTree:
		var state:Node=(main_loop as SceneTree).root.get_node_or_null("GameState")
		if state!=null and "reduce_motion" in state:reduced=reduced or bool(state.get("reduce_motion"))
	return minf(value,FAST) if reduced else value

static func _tween(node:Node)->Tween:
	if node==null or not node.is_inside_tree():return null
	# Replace any earlier transition on this node so two never fight.
	var previous:Variant=node.get_meta("_motion_tween") if node.has_meta("_motion_tween") else null
	if previous is Tween and (previous as Tween).is_valid():(previous as Tween).kill()
	var tween:=node.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	node.set_meta("_motion_tween",tween)
	return tween

## Fade a whole overlay (scrim and card) in from transparent.
static func fade_in(item:CanvasItem,time:float=SLOW)->void:
	var tween:=_tween(item)
	if tween==null:return
	item.modulate.a=0.0
	tween.tween_property(item,"modulate:a",1.0,duration(time))

## A free-positioned card: fade in while rising `rise` px into place.
## Only for Controls that are not placed by a Container.
static func rise_in(card:Control,time:float=SLOW,rise:float=RISE,delay:float=0.0)->void:
	var tween:=_tween(card)
	if tween==null:return
	var home:=card.position
	card.modulate.a=0.0;card.position=home+Vector2(0,rise)
	if delay>0:tween.tween_interval(duration(delay))
	tween.set_parallel(true)
	tween.tween_property(card,"modulate:a",1.0,duration(time))
	tween.tween_property(card,"position:y",home.y,duration(time))

## Tab or content change: the new content cross-fades up from transparent.
static func cross_fade(item:CanvasItem,time:float=BASE)->void:
	fade_in(item,time)

## Ease a notice out, then run `done` (e.g. queue_free).
static func fade_out(item:CanvasItem,done:Callable=Callable(),time:float=BASE)->void:
	var tween:=_tween(item)
	if tween==null:
		if done.is_valid():done.call()
		return
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(item,"modulate:a",0.0,duration(time))
	if done.is_valid():tween.tween_callback(done)
