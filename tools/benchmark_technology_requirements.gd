extends SceneTree
## Headless synthetic diagnostic; these nodes never enter the game catalog.
const Requirements=preload("res://scripts/technology_requirements.gd")

func _initialize()->void:
	var graph:Array=[]
	for i in 5000:
		graph.append({"id":"synthetic%d"%i,"requires":[] if i==0 else ["synthetic%d"%(i-1)]})
	for order in ["forward","reverse"]:
		var started:=Time.get_ticks_usec()
		var errors:=Requirements.validate(graph)
		print("Synthetic 5000-node %s chain: %d microseconds; %d errors"%[order,Time.get_ticks_usec()-started,errors.size()])
		if not errors.is_empty():quit(1);return
		graph.reverse()
	quit()
