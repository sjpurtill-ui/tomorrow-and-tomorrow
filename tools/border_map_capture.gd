extends RefCounted
## Capture staging for the map's Border mode (local_terrain.gd capture hooks):
## turns it on and, by the arguments, holds the pointer's ghost at a bearing
## and distance from the seat, carries the first fort, or opens its note.

static func stage(terrain:Node)->String:
	var Map:=preload("res://scripts/hud/border_map.gd")
	var Forts:=preload("res://scripts/fort_border.gd")
	# "--capture-fort-close=<n>": the view over our n-th fort (with --capture-zoom), the map mode off.
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-fort-close="):
			var list:=Forts.forts().filter(func(f:Dictionary)->bool:return String(f.get("status",""))!="abandoned")
			var n:=clampi(int(argument.get_slice("=",1)),0,maxi(0,list.size()-1))
			if list.is_empty():return "no forts"
			var at:=Forts._pos(list[n])
			terrain.call("_set_camera_target",Vector3(at.x,0.0,at.y))
			terrain.set("_border_watch_day",-1)
			return "close over %s (%s)" % [String(list[n].name),String(list[n].kind)]
	Map.set_shown(terrain,true)
	var map:Node=Map.find(terrain)
	if map==null: return "no border map"
	var first:={}
	for f:Dictionary in Forts.forts():
		if String(f.get("status",""))!="abandoned": first=f; break
	var said:="on, %d forts" % Forts.forts().size()
	for argument:String in OS.get_cmdline_user_args():
		if argument=="--capture-border-note" and not first.is_empty():
			map.call("open_note",int(first.id)); said+=", note of "+String(first.name)
		if argument=="--capture-border-move" and not first.is_empty():
			map.call("start_move",int(first.id)); said+=", carrying "+String(first.name)
		if argument.begins_with("--capture-border-ghost="):
			var parts:=argument.get_slice("=",1).split(",")
			var at:=Forts.seat()+Vector2.RIGHT.rotated(deg_to_rad(float(parts[0])))*float(parts[1])
			var screen:Vector2=map.call("screen_of",at)
			(map.get("chart") as Control).set("pointer_override",screen)
			said+=", ghost at %s (%s px): %s" % [str(at.round()),str(screen.round()),str(Forts.quote(at,int(map.get("moving"))).get("problem",""))]
	return said
