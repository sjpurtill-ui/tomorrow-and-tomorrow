extends RefCounted
var terrain:Node
func _init(value:Node)->void:terrain=value
func paint_reference(image:Image,start:Vector2,finish:Vector2,radius_km:float,width:int,height:int)->void:
	var a:Vector2=terrain._discovery_mask_pixel(start,width,height)
	var b:Vector2=terrain._discovery_mask_pixel(finish,width,height)
	var radius_pixels:=maxf(1.0,(radius_km/terrain.world_width*float(width)+radius_km/terrain.world_depth*float(height))*0.5)
	var padding:=radius_pixels*1.25
	for pixel_y in range(maxi(0,floori(minf(a.y,b.y)-padding)),mini(height,ceili(maxf(a.y,b.y)+padding)+1)):
		for pixel_x in range(maxi(0,floori(minf(a.x,b.x)-padding)),mini(width,ceili(maxf(a.x,b.x)+padding)+1)):
			var pixel:=Vector2(float(pixel_x),float(pixel_y))
			var distance:=pixel.distance_to(Geometry2D.get_closest_point_to_segment(pixel,a,b))/radius_pixels
			if distance>1.25: continue
			var reveal:=1.0-smoothstep(0.82,1.25,distance)
			if reveal>image.get_pixel(pixel_x,pixel_y).r: image.set_pixel(pixel_x,pixel_y,Color(reveal,reveal,reveal))
