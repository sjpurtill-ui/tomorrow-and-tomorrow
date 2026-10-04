extends GdUnitTestSuite
## Actual body heights and room-side silhouettes must survive framing.
const Camera:=preload("res://scripts/hud/court_camera.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")

class Person extends Node3D:
	var height:=1.7
	func head_top()->Vector3:return global_position+Vector3.UP*height

func _person(view:SubViewport,at:Vector3,height:float)->Person:
	var person:=Person.new();view.add_child(person);person.position=at;person.height=height
	return person

func test_room_shot_keeps_side_chair_shoulders_inside_the_image()->void:
	for dimensions:Vector2i in [Vector2i(1536,864),Vector2i(1280,960)]:
		var view:=SubViewport.new();view.size=dimensions;view.own_world_3d=true
		add_child(view);auto_free(view)
		var camera:=Camera.new();view.add_child(camera)
		var main:=_person(view,Vector3(0,0,2.4),1.72)
		var left:=_person(view,Vector3(-4.35,0,0.45),1.25)
		var right:=_person(view,Vector3(4.35,0,0.45),1.25)
		camera.set_insets(18,24,0,0)
		camera.wide([main,left,right],0.0,main)
		for person in [main,left,right]:
			var centre:Vector3=person.global_position+Vector3.UP*person.height*.65
			for sign_value:float in [-1.0,1.0]:
				var point:=centre+camera.global_basis.x*.40*sign_value
				var pixel:=camera.unproject_position(point)
				assert_float(pixel.x).is_between(0.0,float(dimensions.x))
				assert_float(pixel.y).is_between(0.0,float(dimensions.y))

func test_seated_heads_are_framed_at_their_real_height()->void:
	var view:=SubViewport.new();view.size=Vector2i(1536,864);view.own_world_3d=true
	add_child(view);auto_free(view)
	var camera:=Camera.new();view.add_child(camera)
	var seated:=_person(view,Vector3.ZERO,1.18)
	assert_float(camera._head_of(seated).y).is_equal_approx(1.18,0.001)
	var stage:=Stage.new();auto_free(stage)
	var figure:=Stage.Figure.new();auto_free(figure)
	figure.spot=Node3D.new();auto_free(figure.spot)
	figure.body3d=seated
	assert_object(stage._where_now(figure)).is_same(seated)
	figure.stroll=0.8
	assert_object(stage._where_now(figure)).is_same(figure.spot)
