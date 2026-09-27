extends Node
## Newly charted ground bleeds onto the map like ink into parchment instead
## of switching on in one frame.
##
## The map paints the discovery mask (an L8 image) exactly as before and keeps
## it authoritative for everything that reads it. This node owns only what the
## GPU is shown: a copy that eases each newly revealed pixel toward the mask,
## each at its own irregular pace, so a new stretch of known ground spreads in
## over about a second with a ragged edge. Work is bounded to the rectangle
## that changed; a very large change (a loaded save, a whole-map repaint)
## is shown at once. Reduced motion shows every change at once.
const Motion:=preload("res://scripts/hud/motion.gd")
const NODE_NAME:="DiscoveryReveal"
const SECONDS:=1.1             ## typical time for a pixel to ink in fully
const MAX_ANIMATED_PIXELS:=6000
const UPLOAD_INTERVAL:=1.0/30.0

var texture:ImageTexture
var target:Image
var shown:Image
var rect:=Rect2i()
var upload_elapsed:=0.0
var frame_usec:=0.0

## Called by the map instead of updating the mask texture directly. Returns
## false when the caller should update the texture itself (first paint, a
## size change, reduced motion or too large a change).
static func present(host:Node,mask_texture:ImageTexture,image:Image,changed:Rect2i,force:bool=false)->bool:
	if host==null or mask_texture==null or image==null:return false
	var layer:=host.get_node_or_null(NODE_NAME)
	if layer==null:
		layer=(load("res://scripts/discovery_reveal.gd") as GDScript).new()
		layer.name=NODE_NAME
		host.add_child(layer)
	return bool(layer.call("_present",mask_texture,image,changed,force))

## The pixel rectangle a set of revealed areas touches, given the map's
## world-to-mask pixel function and the mask size.
static func areas_rect(areas:Array,to_pixel:Callable,size:Vector2i,pixels_per_km:float)->Rect2i:
	var result:=Rect2i()
	var first:=true
	for area in areas:
		if not area is Dictionary:continue
		var radius_px:=ceili(maxf(1.0,float((area as Dictionary).get("radius",1.0)))*pixels_per_km)+2
		var points:Array=(area as Dictionary).get("points",[])
		var centers:Array[Vector2]=[]
		if points.size()>=2:
			for point in points:
				if point is Dictionary:centers.append(Vector2(float(point.get("x",0.0)),float(point.get("z",0.0))))
		else:
			centers.append(Vector2(float((area as Dictionary).get("x",0.0)),float((area as Dictionary).get("z",0.0))))
		for center in centers:
			var pixel:Vector2=to_pixel.call(center,size.x,size.y)
			var box:=Rect2i(Vector2i(floori(pixel.x)-radius_px,floori(pixel.y)-radius_px),Vector2i(radius_px*2+1,radius_px*2+1))
			result=box if first else result.merge(box)
			first=false
	return result.intersection(Rect2i(Vector2i.ZERO,size))

func _present(mask_texture:ImageTexture,image:Image,changed:Rect2i,force:bool)->bool:
	var size:=image.get_size()
	var fresh:=shown==null or shown.get_size()!=size or texture!=mask_texture
	texture=mask_texture
	target=image
	if force or fresh or Motion.reduced() or changed.size.x<=0 or changed.size.y<=0:
		_snap()
		return false
	var merged:=changed if rect.size==Vector2i.ZERO else rect.merge(changed)
	if merged.size.x*merged.size.y>MAX_ANIMATED_PIXELS:
		_snap()
		return false
	rect=merged
	set_process(true)
	return true

func _snap()->void:
	if target!=null:shown=target.duplicate() as Image
	rect=Rect2i()
	set_process(false)

func _ready()->void:
	set_process(rect.size!=Vector2i.ZERO)

func _process(delta:float)->void:
	if target==null or texture==null or shown==null or rect.size==Vector2i.ZERO:
		set_process(false);return
	var began:=Time.get_ticks_usec()
	# Only the changed rectangle is stepped: small byte arrays, no full copies.
	var region:=shown.get_region(rect)
	var goal:=target.get_region(rect).get_data()
	var result:=step_bytes(region.get_data(),goal,rect.size.x,Rect2i(Vector2i.ZERO,rect.size),delta,rect.position)
	region.set_data(rect.size.x,rect.size.y,false,Image.FORMAT_L8,result[0])
	shown.blit_rect(region,Rect2i(Vector2i.ZERO,rect.size),rect.position)
	var moving:=bool(result[1])
	upload_elapsed+=delta
	if upload_elapsed>=UPLOAD_INTERVAL or not moving:
		upload_elapsed=0.0
		texture.update(shown)
	if not moving:
		rect=Rect2i()
		set_process(false)
	frame_usec=lerpf(frame_usec,float(Time.get_ticks_usec()-began),0.1)

## Ease every pixel of `area` in `shown` toward `goal`, each at a pace set by
## a fixed hash of its map position (0.55x-1.45x), so edges spread raggedly
## like ink. Never overshoots. Returns [stepped bytes, still moving].
static func step_bytes(shown:PackedByteArray,goal:PackedByteArray,width:int,area:Rect2i,dt:float,origin:=Vector2i.ZERO)->Array:
	var moving:=false
	var base:=255.0*maxf(dt,0.0)/SECONDS
	for y in range(area.position.y,area.end.y):
		var row:=y*width
		for x in range(area.position.x,area.end.x):
			var i:=row+x
			var have:=shown[i]
			var want:=goal[i]
			if have==want:continue
			var px:=x+origin.x;var py:=y+origin.y
			var pace:=0.55+0.9*float(((px*73856093)^(py*19349663))&1023)/1023.0
			var step:=maxi(1,roundi(base*pace))
			var next:=mini(want,have+step) if want>have else maxi(want,have-step)
			shown[i]=next
			if next!=want:moving=true
	return [shown,moving]
