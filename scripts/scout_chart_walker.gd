extends Sprite3D
## The small walker glyph on a scout party's route. It stands where the plan
## reckons the party to be (outbound, then home along the same chart), not
## where it truly is: the road keeps that secret until the party returns.
## Moving along the prebuilt chart costs one lookup per frame; no geometry
## is rebuilt.

var chart:=PackedVector2Array()
var heights:=PackedFloat32Array()
var arcs:=PackedFloat32Array()
var start_day:=0.0
var return_day:=1.0
var lift:=0.0
var base_pixel_size:=0.01
var _clock:=0.0

func _process(delta:float)->void:
	if chart.size()<2 or arcs.size()!=chart.size(): return
	_clock+=delta
	var today:=float(GameState.elapsed_days)
	var progress:=clampf((today-start_day)/maxf(1.0,return_day-start_day),0.0,1.0)
	var reach:=1.0-absf(progress*2.0-1.0)
	var target:=arcs[arcs.size()-1]*reach
	var i:=1
	while i<chart.size()-1 and arcs[i]<target: i+=1
	var span:=maxf(arcs[i]-arcs[i-1],0.0000001)
	var u:=clampf((target-arcs[i-1])/span,0.0,1.0)
	var p:=chart[i-1].lerp(chart[i],u)
	position=Vector3(p.x,lerpf(heights[i-1],heights[i],u)+lift,p.y)
	# A gentle stride: the figure breathes a little, never flashes.
	pixel_size=base_pixel_size*(1.0+0.07*sin(_clock*4.2))
