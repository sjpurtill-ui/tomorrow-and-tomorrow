extends SceneTree


const ATLAS_COLUMNS:=4
const ATLAS_ROWS:=4
const CELL_GUTTER_PX:=8
const COMPONENT_ALPHA_FLOOR:=0.015


func _retain_largest_cell_component(image:Image,cell_origin:Vector2i,cell_size:Vector2i)->void:
	# Generated atlas plates occasionally spill a disconnected fragment across an exact
	# 256px cell boundary. Treat every cell as a separate authored plate: retain its one
	# connected settlement/ground silhouette and remove all disconnected contamination.
	var pixel_count:=cell_size.x*cell_size.y
	var visited:=PackedByteArray()
	visited.resize(pixel_count)
	var largest_component:Array[Vector2i]=[]
	for local_y in cell_size.y:
		for local_x in cell_size.x:
			var local_index:=local_y*cell_size.x+local_x
			if visited[local_index]!=0: continue
			visited[local_index]=1
			var source_point:=cell_origin+Vector2i(local_x,local_y)
			if image.get_pixelv(source_point).a<=COMPONENT_ALPHA_FLOOR: continue
			var component:Array[Vector2i]=[]
			var frontier:Array[Vector2i]=[Vector2i(local_x,local_y)]
			while not frontier.is_empty():
				var current:Vector2i=frontier.pop_back()
				component.append(current)
				for offset:Vector2i in [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1),Vector2i(-1,0),Vector2i(1,0),Vector2i(-1,1),Vector2i(0,1),Vector2i(1,1)]:
					var neighbor:Vector2i=current+offset
					if neighbor.x<0 or neighbor.y<0 or neighbor.x>=cell_size.x or neighbor.y>=cell_size.y: continue
					var neighbor_index:int=neighbor.y*cell_size.x+neighbor.x
					if visited[neighbor_index]!=0: continue
					visited[neighbor_index]=1
					if image.get_pixelv(cell_origin+neighbor).a>COMPONENT_ALPHA_FLOOR:
						frontier.append(neighbor)
			if component.size()>largest_component.size(): largest_component=component
	var retained:=PackedByteArray()
	retained.resize(pixel_count)
	for point in largest_component: retained[point.y*cell_size.x+point.x]=1
	for local_y in cell_size.y:
		for local_x in cell_size.x:
			var point:=cell_origin+Vector2i(local_x,local_y)
			var inside_gutter:=local_x<CELL_GUTTER_PX or local_y<CELL_GUTTER_PX or local_x>=cell_size.x-CELL_GUTTER_PX or local_y>=cell_size.y-CELL_GUTTER_PX
			var local_index:=local_y*cell_size.x+local_x
			if inside_gutter or retained[local_index]==0:
				var color:=image.get_pixelv(point)
				color.a=0.0
				image.set_pixelv(point,color)


func _initialize() -> void:
	var arguments:=OS.get_cmdline_user_args()
	if arguments.size()<2:
		push_error("Usage: -- <input png> <output png>")
		quit(2)
		return
	var image:=Image.new()
	var error:=image.load(String(arguments[0]))
	if error!=OK:
		push_error("Could not load source atlas: %s" % error_string(error))
		quit(3)
		return
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color:=image.get_pixel(x,y)
			# Image-generated atlases use vivid magenta only as a disposable matte.
			# Keep roof clay and warm earth: a keyed pixel must contain both strong
			# red and strong blue while green remains far below them.
			var magenta_floor:=minf(color.r,color.b)
			var magenta_separation:=magenta_floor-color.g
			if magenta_floor>0.30 and magenta_separation>0.08 and color.r>color.g*1.30 and color.b>color.g*1.24:
				# The generated matte is deliberately far outside the historical
				# palette, so a hard chroma decision is safer than retaining a pink
				# antialias fringe around every neighborhood.
				var matte:=1.0
				color.a*=1.0-matte
				# Suppress colored antialias contamination at the silhouette while
				# preserving a soft edge for mipmapping.
				color.r=lerpf(color.r,0.34,matte)
				color.g=lerpf(color.g,0.30,matte)
				color.b=lerpf(color.b,0.24,matte)
				image.set_pixel(x,y,color)
	# Four equal cells per axis must meet on exact texel boundaries; generated
	# source dimensions are not guaranteed to be divisible by four.
	image.resize(1024,1024,Image.INTERPOLATE_LANCZOS)
	var cell_size:=Vector2i(image.get_width()/ATLAS_COLUMNS,image.get_height()/ATLAS_ROWS)
	for cell_y in ATLAS_ROWS:
		for cell_x in ATLAS_COLUMNS:
			_retain_largest_cell_component(image,Vector2i(cell_x*cell_size.x,cell_y*cell_size.y),cell_size)
	error=image.save_png(String(arguments[1]))
	if error!=OK:
		push_error("Could not save keyed atlas: %s" % error_string(error))
		quit(4)
		return
	print("Saved keyed atlas: %s (%dx%d)" % [arguments[1],image.get_width(),image.get_height()])
	quit()
