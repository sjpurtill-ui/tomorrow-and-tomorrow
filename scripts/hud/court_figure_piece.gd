extends Node3D
## A piece of someone the court has put to death (court_figure_gore.gd): it
## stands at its own middle, so it can be thrown, spun and dropped. A head
## (or half a head) still has its eyes and mouth:
##   blink(times)     the lids close and open (a loose head blinks at the god)
##   look(way)        "up", "down", "left", "right" or "" (straight)
##   mouth(open)      0 shut .. 1 agape
## Nothing runs per frame: a blink is a short tween on the morphs.

var _tween:Tween

func _morphs(name:String)->Array:
	var out:=[]
	for node in find_children("*","MeshInstance3D",true,false):
		var mi:=node as MeshInstance3D
		if mi.mesh==null:continue
		var i:=mi.find_blend_shape_by_name(StringName(name))
		if i>=0:out.append([mi,i])
	return out

func _morph_set(name:String,value:float)->void:
	for pair in _morphs(name):(pair[0] as MeshInstance3D).set_blend_shape_value(int(pair[1]),value)

## Has it eyes to blink with?
func has_eyes()->bool:
	return not _morphs("blink").is_empty()

func blink(times:=1)->void:
	if not has_eyes() or not is_inside_tree():return
	if _tween and _tween.is_valid():_tween.kill()
	_tween=create_tween()
	for t in maxi(times,1):
		_tween.tween_method(func(v:float)->void:_morph_set("blink",v),0.0,1.0,0.07)
		_tween.tween_method(func(v:float)->void:_morph_set("blink",v),1.0,0.0,0.12)
		_tween.tween_interval(0.12)

func look(way:="")->void:
	for w in ["up","down","left","right"]:_morph_set("eyes_"+w,1.0 if w==way else 0.0)

func mouth(open:float)->void:
	var value:=clampf(open,0.0,1.0)
	if not _morphs("jaw_open").is_empty():_morph_set("jaw_open",value)
	else:_morph_set("v_aa",value)
