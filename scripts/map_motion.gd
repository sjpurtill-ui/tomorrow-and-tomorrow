extends RefCounted
## Camera feel for the map: pure, testable motion math.
##
## - Zoom glides on a critically damped spring in log(size): it starts from
##   rest, accelerates, and settles without overshooting. A speed cap keeps a
##   continent-sized jump legible instead of a blur.
## - A released pan keeps a little of its momentum and coasts to a stop.
## - Keyboard panning eases in and out instead of starting and stopping dead.
##
## Nothing here allocates or rebuilds; every helper is a few float operations.
## Reduced motion (DisplayPreferences) shortens the glide and removes coasting.
const Motion:=preload("res://scripts/hud/motion.gd")

const ZOOM_OMEGA:=10.0           ## spring stiffness (rad/s); most of a step in ~0.4 s
const ZOOM_OMEGA_REDUCED:=18.0
const ZOOM_MAX_LOG_SPEED:=4.2    ## log-size units per second (a 5x step peaks near this)
const ZOOM_SNAP:=0.002           ## |log error| (0.2%) below which the glide lands exactly
const COAST_SECONDS:=0.32        ## pan momentum time constant after release
const COAST_STOP:=0.02           ## stop coasting below 2% of view height per second
const COAST_MAX_VIEWS:=2.6       ## release speed cap, in view heights per second
const KEY_PAN_RESPONSE:=11.0     ## 1/s; ~90% of full speed in 0.2 s

static func reduced()->bool:
	return Motion.reduced()

## One critically damped spring step toward `target`, exact for any dt.
## Returns Vector2(new_value, new_velocity). Never crosses the target: if a
## stale velocity would carry it past, it lands on the target at rest.
## `max_speed` <= 0 means uncapped.
static func spring_step(value:float,velocity:float,target:float,omega:float,dt:float,max_speed:float=0.0)->Vector2:
	if dt<=0.0:return Vector2(value,velocity)
	var d:=value-target
	var decay:=exp(-omega*dt)
	var k:=velocity+omega*d
	var next_d:=(d+k*dt)*decay
	var next_v:=(velocity-omega*k*dt)*decay
	if max_speed>0.0:
		var step:=clampf(next_d-d,-max_speed*dt,max_speed*dt)
		if not is_equal_approx(step,next_d-d):
			next_d=d+step
			next_v=clampf(next_v,-max_speed,max_speed)
	if d!=0.0 and signf(next_d)!=signf(d):
		return Vector2(target,0.0)
	return Vector2(target+next_d,next_v)

## Zoom glide in log(size). Returns Vector3(next_size, next_log_velocity, landed).
static func zoom_step(size:float,log_velocity:float,target_size:float,dt:float)->Vector3:
	if size<=0.0 or target_size<=0.0:return Vector3(target_size,0.0,1.0)
	var omega:=ZOOM_OMEGA_REDUCED if reduced() else ZOOM_OMEGA
	var target:=log(target_size)
	var result:=spring_step(log(size),log_velocity,target,omega,dt,ZOOM_MAX_LOG_SPEED*(2.0 if reduced() else 1.0))
	if absf(result.x-target)<ZOOM_SNAP and absf(result.y)<0.05:
		return Vector3(target_size,0.0,1.0)
	return Vector3(exp(result.x),result.y,0.0)

## Momentum after a released drag, decaying exponentially. Reduced motion
## drops it at once. Velocity and view are in the same world units.
static func coast_step(velocity:Vector3,dt:float,view_height:float)->Vector3:
	if reduced() or dt<=0.0:return Vector3.ZERO if reduced() else velocity
	var next:=velocity*exp(-dt/COAST_SECONDS)
	if next.length()<COAST_STOP*maxf(view_height,0.0001):return Vector3.ZERO
	return next

## The launch velocity for a released drag, capped so a flick never throws
## the camera across a region.
static func release_velocity(velocity:Vector3,view_height:float)->Vector3:
	if reduced():return Vector3.ZERO
	var cap:=COAST_MAX_VIEWS*maxf(view_height,0.0001)
	return velocity.limit_length(cap)

## Keyboard pan speed eases toward the held direction and back to rest.
static func key_pan_step(current:Vector2,wanted:Vector2,dt:float)->Vector2:
	if reduced():return wanted
	var blend:=1.0-exp(-KEY_PAN_RESPONSE*maxf(dt,0.0))
	var next:=current.lerp(wanted,blend)
	if wanted==Vector2.ZERO and next.length()<0.01:return Vector2.ZERO
	return next

## Exponential approach used by ambient fades: frame-rate independent.
static func approach(current:float,target:float,dt:float,seconds:float)->float:
	if seconds<=0.0:return target
	return lerpf(current,target,1.0-exp(-maxf(dt,0.0)/seconds))

## Ease-out cubic on [0,1]; monotonic, never overshoots.
static func ease_out(t:float)->float:
	var u:=1.0-clampf(t,0.0,1.0)
	return 1.0-u*u*u

## Smooth in-out (smootherstep) on [0,1]; monotonic, zero slope at both ends.
static func ease_in_out(t:float)->float:
	var x:=clampf(t,0.0,1.0)
	return x*x*x*(x*(x*6.0-15.0)+10.0)
