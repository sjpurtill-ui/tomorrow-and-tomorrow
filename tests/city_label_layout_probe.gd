extends Node
## City label layout cost: arrange() once cold and then per frame while the map
## pans (every anchor moves a few pixels, the previous layout is remembered).
## Prints CITY_LABEL_LAYOUT with milliseconds for 1-24 cities.
const L=preload("res://scripts/hud/city_labels.gd")

func _ready()->void:
	var bounds:=Rect2(Vector2(90,100),Vector2(1810,910))
	var report:={}
	for n in [1,5,12,24]:
		var rng:=RandomNumberGenerator.new();rng.seed=7
		var entries:Array[Dictionary]=[]
		for i in n:
			entries.append({"id":"c%d"%i,"foreign":i>0,"anchor":Vector2(rng.randf_range(200,1700),rng.randf_range(200,900)),"extent":Vector2(rng.randf_range(90,190),30)})
		var first:=Time.get_ticks_usec()
		var result:Dictionary=L.arrange(entries,bounds,{},[])
		var cold:=Time.get_ticks_usec()-first
		var memory:Dictionary=result.memory
		var start:=Time.get_ticks_usec()
		for f in 30:
			for e in entries:e.anchor+=Vector2(3,1)
			result=L.arrange(entries,bounds,memory,[])
			memory=result.memory
		var pan_ms:=(Time.get_ticks_usec()-start)/30000.0
		# Zooming out: anchors converge on the screen centre 1.5% a frame.
		var worst:=0
		start=Time.get_ticks_usec()
		for f in 30:
			for e in entries:e.anchor=Vector2(1000,550)+(e.anchor-Vector2(1000,550))*0.985
			var frame:=Time.get_ticks_usec()
			result=L.arrange(entries,bounds,memory,[])
			worst=maxi(worst,Time.get_ticks_usec()-frame)
			memory=result.memory
		report["n%d" % n]={"cold_ms":snappedf(cold/1000.0,0.01),"pan_frame_ms":snappedf(pan_ms,0.001),"zoom_frame_ms":snappedf((Time.get_ticks_usec()-start)/30000.0,0.001),"zoom_worst_ms":snappedf(worst/1000.0,0.01),"placed":result.cards.size()}
	print("CITY_LABEL_LAYOUT: ",JSON.stringify(report))
	get_tree().quit(0)
