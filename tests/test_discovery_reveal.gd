extends GdUnitTestSuite
## Newly charted ground inks in (codex/map-motion): the shown mask eases to
## the real mask without overshoot, only inside the changed rectangle, and
## large or reduced-motion changes show at once. The real mask is untouched.
const Reveal:=preload("res://scripts/discovery_reveal.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

func after_test()->void:
	Motion.reduce_motion=false

func test_pixels_ease_to_the_mask_without_overshoot()->void:
	var width:=8
	var shown:=PackedByteArray();shown.resize(64)
	var goal:=PackedByteArray();goal.resize(64)
	for i in 64:goal[i]=255 if i%3!=0 else 0
	var area:=Rect2i(0,0,8,8)
	var frames:=0
	var moving:=true
	while moving and frames<200:
		var before:=shown.duplicate()
		var result:=Reveal.step_bytes(shown,goal,width,area,1.0/60.0)
		shown=result[0];moving=result[1]
		for i in 64:
			assert_bool(shown[i]>=before[i] and shown[i]<=goal[i]).is_true()
		frames+=1
	assert_bool(moving).is_false()
	assert_array(Array(shown)).is_equal(Array(goal))
	# About a second at the fastest, two at the slowest pace.
	assert_int(frames).is_greater(30)
	assert_int(frames).is_less(140)

func test_edges_spread_raggedly()->void:
	var shown:=PackedByteArray();shown.resize(64)
	var goal:=PackedByteArray();goal.resize(64);goal.fill(255)
	var result:=Reveal.step_bytes(shown,goal,8,Rect2i(0,0,8,8),0.3)
	var values:={}
	for value in (result[0] as PackedByteArray):values[value]=true
	assert_int(values.size()).is_greater(4)

func test_only_the_changed_rectangle_moves()->void:
	var shown:=PackedByteArray();shown.resize(64)
	var goal:=PackedByteArray();goal.resize(64);goal.fill(200)
	var result:=Reveal.step_bytes(shown,goal,8,Rect2i(2,2,3,3),0.5)
	var stepped:PackedByteArray=result[0]
	for y in 8:
		for x in 8:
			var inside:=x>=2 and x<5 and y>=2 and y<5
			assert_bool(stepped[y*8+x]>0).is_equal(inside)

func test_areas_rect_covers_discs_and_trails()->void:
	var to_pixel:=func(p:Vector2,w:int,h:int)->Vector2:return Vector2(p.x+float(w)*0.5,p.y+float(h)*0.5)
	var rect:=Reveal.areas_rect([{"x":0.0,"z":0.0,"radius":2.0},{"kind":"trail","radius":1.0,"points":[{"x":10.0,"z":0.0},{"x":20.0,"z":5.0}]}],to_pixel,Vector2i(100,100),1.0)
	assert_bool(rect.has_point(Vector2i(50,50))).is_true()
	assert_bool(rect.has_point(Vector2i(70,55))).is_true()
	assert_bool(rect.size.x<40).is_true()

func _mask(value:int)->Image:
	var image:=Image.create(32,16,false,Image.FORMAT_L8)
	image.fill(Color(float(value)/255.0,0,0))
	return image

func test_present_animates_small_changes_and_leaves_the_mask_alone()->void:
	var host:Node=auto_free(Node.new())
	add_child(host)
	var mask:=_mask(0)
	var texture:=ImageTexture.create_from_image(mask)
	# The first paint is shown at once.
	assert_bool(Reveal.present(host,texture,mask,Rect2i(0,0,4,4))).is_false()
	var layer:Node=host.get_node(Reveal.NODE_NAME)
	for y in range(4,8):
		for x in range(4,8):mask.set_pixel(x,y,Color.WHITE)
	assert_bool(Reveal.present(host,texture,mask,Rect2i(4,4,4,4))).is_true()
	layer._process(0.2)
	var partial:float=(layer.shown as Image).get_pixel(5,5).r
	assert_float(partial).is_greater(0.0)
	assert_float(partial).is_less(1.0)
	assert_float(mask.get_pixel(5,5).r).is_equal(1.0)  # the real mask is authoritative
	for i in 200:layer._process(1.0/30.0)
	assert_float(layer.shown.get_pixel(5,5).r).is_equal(1.0)
	assert_bool(layer.is_processing()).is_false()

func test_large_or_reduced_motion_changes_show_at_once()->void:
	var host:Node=auto_free(Node.new())
	add_child(host)
	var mask:=_mask(0)
	var texture:=ImageTexture.create_from_image(mask)
	Reveal.present(host,texture,mask,Rect2i())
	assert_bool(Reveal.present(host,texture,mask,Rect2i(0,0,200,200))).is_false()
	Motion.reduce_motion=true
	assert_bool(Reveal.present(host,texture,mask,Rect2i(1,1,2,2))).is_false()
