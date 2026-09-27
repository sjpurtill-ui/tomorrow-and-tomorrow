extends GdUnitTestSuite
## Great works on the map: sound geometry on any slope, a card that never
## covers a city's card or pin, and an emblem only while the model is a speck.
const Visual=preload("res://scripts/undertaking_map_visual.gd")
const Labels=preload("res://scripts/hud/city_labels.gd")
const Icons=preload("res://scripts/resource_icons.gd")
const Concept=preload("res://scripts/wonder_concept.gd")
const Catalog=preload("res://scripts/undertaking_catalog.gd")

func _record(form:String,material:String,status:String,fraction:float)->Dictionary:
	var id:String=Concept.make_id(form,"honor_dead","grand",material,1,"t"+form)
	return {"id":id,"status":status,"progress":float(Catalog.get_definition(id).work)*fraction,"condition":1.0,"site":{"position":Vector2(1,1),"angle":.7}}

## Every triangle is wound clockwise-front (Godot's convention, checked
## against the engine's own BoxMesh normals), carries its face normal, and
## faces away from the landmark's centre line.
func test_box_winding_convention_matches_engine()->void:
	var arrays:=BoxMesh.new().surface_get_arrays(0)
	var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var n:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var idx:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in range(0,idx.size(),3):
		var face:=(v[idx[i+2]]-v[idx[i]]).cross(v[idx[i+1]]-v[idx[i]]).normalized()
		assert_float(face.dot(n[idx[i]])).is_greater(.99)

func test_every_form_is_sound_flat_shaded_and_outward()->void:
	var slope:=func(x:float,z:float)->float:return .2+x*.35+z*.12
	for form:String in Concept.FORMS.keys():
		for state:String in ["building","functioning","ruined"]:
			var r:=_record(form,"stone",state,.4 if state=="building" else 1.0)
			var d:=Catalog.get_definition(String(r.id))
			var origin:=Vector3(1,slope.call(1.0,1.0),1)
			var built:=Visual.build(Visual.forms(String(r.id),Visual.shape_of(r,d),"stone"),Visual.state_of(r),Visual.U.fraction(r),.7,origin,slope)
			var mesh:ArrayMesh=built.mesh
			var arrays:=mesh.surface_get_arrays(0)
			var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			assert_int(verts.size()%3).is_equal(0)
			assert_int(verts.size()).is_greater(36)
			var flipped:=0
			for i in range(0,verts.size(),3):
				var face:=(verts[i+2]-verts[i]).cross(verts[i+1]-verts[i])
				assert_float(face.length()).is_greater(0.0)
				face=face.normalized()
				for k in 3:assert_float(face.dot(normals[i+k])).is_greater(.999)
				# Roughly outward from the vertical axis through the work, or up/down.
				var centroid:=(verts[i]+verts[i+1]+verts[i+2])/3.0
				if absf(face.y)<.5 and face.dot(Vector3(centroid.x,0,centroid.z))< -0.0005:flipped+=1
			# Inner faces of rings/arches may face the axis; most faces cannot.
			assert_float(float(flipped)/float(verts.size()/3)).is_less(.45)

## On a slope the plinth reaches below the lowest ground under it and its top
## clears the highest, so no sliver of the work pokes out of the hill.
func test_plinth_levels_the_work_over_a_slope()->void:
	var slope:=func(x:float,z:float)->float:return x*.4
	var r:=_record("hall","timber","functioning",1.0)
	var d:=Catalog.get_definition(String(r.id))
	var origin:=Vector3(1,.4,1)
	var built:=Visual.build(Visual.forms(String(r.id),Visual.shape_of(r,d),"timber"),"standing",1.0,0.0,origin,slope)
	var plinth:Rect2=built.plinth
	var aabb:AABB=(built.mesh as ArrayMesh).get_aabb()
	var low:=float(slope.call(origin.x+plinth.position.x,0.0))-origin.y
	var high:=float(slope.call(origin.x+plinth.end.x,0.0))-origin.y
	assert_float(aabb.position.y).is_less(low)
	assert_float(float(built.top)).is_greater(high)
	assert_float(aabb.size.x).is_less(.14)

func test_building_rises_in_courses_with_scaffold_and_ruins_fall()->void:
	var flat:=func(_x:float,_z:float)->float:return 0.0
	var r:=_record("tower","stone","functioning",1.0)
	var d:=Catalog.get_definition(String(r.id))
	var pieces:=Visual.forms(String(r.id),"tower","stone")
	var whole:AABB=(Visual.build(pieces,"standing",1.0,0.0,Vector3.ZERO,flat).mesh as ArrayMesh).get_aabb()
	var rising:AABB=(Visual.build(pieces,"building",.3,0.0,Vector3.ZERO,flat).mesh as ArrayMesh).get_aabb()
	var ruin:AABB=(Visual.build(pieces,"ruined",1.0,0.0,Vector3.ZERO,flat).mesh as ArrayMesh).get_aabb()
	assert_float(rising.end.y).is_less(whole.end.y)
	# Scaffold poles stand outside the finished work's footprint.
	assert_float(rising.size.x).is_greater_equal(whole.size.x-.0001)
	assert_float(ruin.end.y).is_less(whole.end.y*.8)
	assert_str(Visual.status_line("building",.46)).is_equal("Rising · 40%")
	assert_str(Visual.status_line("standing",1.0)).is_empty()
	assert_str(Visual.state_of({"status":"functioning","dedicated_day":3})).is_equal("dedicated")

func test_render_publishes_a_map_mark_and_no_3d_text()->void:
	var r:=_record("colossus","brick","building",.5)
	var parent:=Node3D.new();add_child(parent)
	Visual.render([{"id":"home","position":Vector2(1,1),"undertakings":[r]}],parent,func(_x:float,_z:float)->float:return .1)
	var root:=parent.get_child(0)
	var mark:=Visual.map_mark(root)
	assert_str(String(mark.state)).is_equal("building")
	assert_str(String(mark.shape)).is_equal("colossus")
	assert_str(String(mark.city_id)).is_equal("home")
	assert_float(float(mark.radius)).is_greater(.01)
	assert_float((mark.anchor as Vector3).y).is_greater(.1)
	assert_bool(root.find_children("*","Label3D",true,false).is_empty()).is_true()
	parent.free()

func test_emblems_exist_for_every_form_and_state()->void:
	for form:String in ["tower","lighthouse","colossus","ring","mound","terrace","basin","orchard","kilns","bridge","dam","canal","causeway","gate","observatory","amphitheatre","granary","hall"]:
		for state:String in ["standing","dedicated","building","abandoned","ruined"]:
			var image:=Icons.great_work_texture(form,state,48).get_image()
			assert_int(image.get_width()).is_equal(48)
			# Opaque ink at the centre region, transparent at the corners.
			assert_float(image.get_pixel(0,0).a).is_less(.05)
	assert_object(Icons.great_work_texture("tower","standing",48)).is_same(Icons.great_work_texture("tower","standing",48))

func test_emblem_fades_as_the_model_becomes_readable()->void:
	assert_float(Labels.work_emblem_alpha(3.0)).is_equal(1.0)
	assert_float(Labels.work_emblem_alpha(30.0)).is_equal(0.0)
	assert_float(Labels.work_emblem_alpha(13.0)).is_between(.1,.9)

func _work(id:String,at:Vector2,state:String="standing",radius:float=4.0)->Dictionary:
	return {"id":id,"anchor":at,"state":state,"shape":"tower","emblem_alpha":Labels.work_emblem_alpha(radius),"radius_px":radius,"extent":Vector2(150,41),"status":"","lines":["A Work"],"progress":1.0}

func test_work_cards_give_way_to_city_cards_and_pins()->void:
	var bounds:=Rect2(0,0,1600,900)
	var city:={"id":"home","anchor":Vector2(800,450),"extent":Vector2(160,30),"foreign":false}
	var cities:=Labels.arrange([city],bounds)
	var entries:Array[Dictionary]=[_work("near",Vector2(812,452)),_work("east",Vector2(900,460),"dedicated"),_work("west",Vector2(700,440),"building"),_work("twin",Vector2(903,462))]
	var result:=Labels.arrange_works(entries,bounds,cities.cards,[city])
	var ids:=(result.works as Array).map(func(w):return String(w.id))
	# A work on the city's own pin is left to the city; a work on another
	# work's emblem is dropped rather than stacked.
	assert_bool("near" in ids).is_false()
	assert_bool("twin" in ids).is_false()
	assert_bool("east" in ids and "west" in ids).is_true()
	var city_rect:Rect2=cities.cards[0].rect
	for work:Dictionary in result.works:
		var rect:Rect2=work.rect
		assert_bool(rect.has_area()).is_true()
		assert_bool(rect.intersects(city_rect)).is_false()
		assert_bool(rect.grow(4).has_point(city.anchor)).is_false()
		assert_bool(rect.intersects(work.mark)).is_false()
		assert_bool(bounds.encloses(rect)).is_true()
		for other:Dictionary in result.works:
			if other!=work:assert_bool(rect.intersects(other.rect) or rect.intersects(other.mark)).is_false()
	# Kept in place while the map pans a little.
	var moved:Array[Dictionary]=[_work("east",Vector2(905,461),"dedicated")]
	var again:=Labels.arrange_works(moved,bounds,cities.cards,[city],[],result.memory)
	assert_vector(again.works[0].rect.position-Vector2(905,461)).is_equal(result.memory["east"])

func test_chart_view_names_only_a_few_works_per_city()->void:
	var bounds:=Rect2(0,0,1600,900)
	var entries:Array[Dictionary]=[]
	for i in 5:
		var work:=_work("w%d" % i,Vector2(500+i*160,300+(i%2)*200),"standing",3.0)
		work.compact=true;work.city_id="home";work.extent=Vector2(120,24)
		entries.append(work)
	var result:=Labels.arrange_works(entries,bounds,[],[])
	assert_int(result.works.size()).is_equal(5)
	assert_int((result.works as Array).filter(func(w):return (w.rect as Rect2).has_area()).size()).is_equal(Labels.WORK_CHART_CARDS)

func test_card_measure_wraps_long_names_and_keeps_status()->void:
	var voice:=preload("res://scripts/hud/hud_tokens.gd").voice_font();var ui:=preload("res://scripts/hud/hud_tokens.gd").font("ui")
	var short:=Labels.measure_work("The Ring","",voice,ui)
	var long:=Labels.measure_work("Audacious Colossus to Honor the Remembering Dead","Rising · 50%",voice,ui)
	assert_int((short.lines as Array).size()).is_equal(1)
	assert_int((long.lines as Array).size()).is_greater(1)
	assert_float((long.extent as Vector2).x).is_less_equal(Labels.WORK_CARD_WIDTH+1)
	assert_float((long.extent as Vector2).y).is_greater((short.extent as Vector2).y)
	# The chart form is the name alone, on as few lines as fit.
	assert_float((long.chart_extent as Vector2).y).is_less((long.extent as Vector2).y)
	assert_float((long.chart_extent as Vector2).x).is_less_equal(Labels.WORK_CHART_WIDTH+1)
