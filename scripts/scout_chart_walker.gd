extends Sprite3D
## The small walker glyph on a scout party's route. It stands where the plan
## reckons the party to be (scout_progress.gd: a circuit is walked once round;
## any other route goes out, may wait at its goal, and comes home the same way), not
## where it truly is: the road keeps that secret until the party returns.
## Moving along the prebuilt chart costs one lookup per frame; no geometry
## is rebuilt.

var chart:=PackedVector2Array()
var heights:=PackedFloat32Array()
var arcs:=PackedFloat32Array()
var start_day:=0.0
var return_day:=1.0
## The live mission (a shared reference), so a party that turns back or comes
## home early is followed without rebuilding the chart.
var mission:Dictionary={}
var lift:=0.0
var base_pixel_size:=0.01
var _clock:=0.0

func _process(delta:float)->void:
	if chart.size()<2 or arcs.size()!=chart.size(): return
	_clock+=delta
	var today:=float(GameState.elapsed_days)
	var target:=arcs[arcs.size()-1]*reach_at(today)
	var i:=1
	while i<chart.size()-1 and arcs[i]<target: i+=1
	var span:=maxf(arcs[i]-arcs[i-1],0.0000001)
	var u:=clampf((target-arcs[i-1])/span,0.0,1.0)
	var p:=chart[i-1].lerp(chart[i],u)
	position=Vector3(p.x,lerpf(heights[i-1],heights[i],u)+lift,p.y)
	# A gentle stride: the figure breathes a little, never flashes.
	pixel_size=base_pixel_size*(1.0+0.07*sin(_clock*4.2))

func reach_at(day:float)->float:
	## How far along the chart the plan reckons the party to be (0..1).
	var plan:Dictionary=mission if not mission.is_empty() else {"start_day":start_day,"return_day":return_day}
	return clampf(preload("res://scripts/scout_progress.gd").fraction(plan,day),0.0,1.0)
