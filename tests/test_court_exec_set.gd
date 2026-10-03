extends GdUnitTestSuite
## THE COURT'S EXECUTIONS, THE SET'S PART (EXECUTIONS.md; scripts/hud/
## court_exec_props.gd, court_blood.gd, court_set_3d.gd, court_animal_3d.gd):
## - the props are made in the set's own paint and ink, each only where the
##   people can have it (no clay pot before pottery: a paunch on a tripod; no
##   bronze axe before metal);
## - a prop goes in a figure's hand and rides it; a lid sits on its pot; the
##   axe bites into the block;
## - blood lands where it falls, stains the front row, and runs nothing idle;
## - the hall remembers: skulls on stakes by the door for the ledger's dead,
##   stains on the floor that fade over a few days;
## - the camp dogs come as a pack of different coats, and a dog carries the
##   thighbone in its jaws and drops it.
## Headless: nothing is drawn; nothing reads or writes the game's state.

const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Props:=preload("res://scripts/hud/court_exec_props.gd")
const Blood:=preload("res://scripts/hud/court_blood.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")


func _built(era:String,facts:Dictionary={})->Node3D:
	var made:Node3D=CourtSet.build(era,facts)
	add_child(made)
	return auto_free(made)


func _figure(court:Node3D,stance:="stand")->Node3D:
	var fig:Node3D=Figure3D.new()
	court.add_child(fig)
	fig.call("setup",{"variant":"male_adult","stance":stance})
	return fig


func test_every_prop_is_made_in_the_set_s_paint()->void:
	var court:=_built("chiefs_hall",{"tier":1,"era_tags":["pottery","metal"]})
	assert_array(Props.names()).contains(["cook_pot","cook_pot_lid","cook_ladle","cook_bag","cook_bag_lid","club","block","axe_bronze","thighbone","skull","skull_stake","boulder"])
	for prop_name in Props.names():
		var prop:Node3D=court.call("exec_prop",prop_name)
		assert_object(prop).override_failure_message("no %s" % prop_name).is_not_null()
		court.add_child(prop)
		var meshes:=prop.find_children("*","MeshInstance3D",true,false)
		if prop is MeshInstance3D:meshes.append(prop)
		assert_bool(meshes.is_empty()).override_failure_message("%s has no mesh" % prop_name).is_false()
		for node in meshes:
			var m:=node as MeshInstance3D
			for surface in m.mesh.get_surface_count():
				assert_object(m.get_surface_override_material(surface)).override_failure_message("%s not dressed" % prop_name).is_instanceof(ShaderMaterial)
		# modest: a handful of these on a set costs little
		assert_int(int(Props.info(prop_name).get("triangles",0))).is_less(2000)


func test_props_only_where_the_people_can_have_them()->void:
	assert_str(Props.pick("cook",[])).is_equal("cook_bag")
	assert_str(Props.pick("cook",["pottery"])).is_equal("cook_pot")
	assert_str(Props.lid_for(Props.pick("cook",[]))).is_equal("cook_bag_lid")
	assert_str(Props.lid_for("cook_pot")).is_equal("cook_pot_lid")
	assert_str(Props.pick("axe",["pottery"])).is_equal("")
	assert_str(Props.pick("axe",["metal"])).is_equal("axe_bronze")
	assert_str(Props.pick("club",[])).is_equal("club")
	assert_bool(Props.available("cook_pot",[])).is_false()


func test_a_prop_goes_in_the_hand_and_on_its_seat()->void:
	var court:=_built("chiefs_hall",{"tier":1,"era_tags":["pottery","metal"]})
	var fig:=_figure(court,"staff")
	var club:Node3D=court.call("exec_prop","club")
	assert_bool(Props.hold(club,fig)).is_true()
	assert_str(String(club.get_parent().name)).is_equal("Hold_hand_R")
	assert_bool(club.get_parent() is BoneAttachment3D).is_true()
	for node in fig.find_children("prop_staff","MeshInstance3D",true,false):assert_bool((node as Node3D).visible).is_false()
	# the lid sits on the pot's mouth
	var pot:Node3D=court.call("exec_prop","cook_pot")
	court.add_child(pot)
	var lid:Node3D=court.call("exec_prop","cook_pot_lid")
	assert_bool(Props.seat(lid,pot,"lid_seat")).is_true()
	assert_object(lid.get_parent()).is_same(pot)
	assert_float(lid.position.y).is_equal_approx(float(Props.info("cook_pot").lid_seat[1]),0.001)
	# the axe bites into the block: its edge at the top, the haft standing up out of it
	var block:Node3D=court.call("exec_prop","block")
	court.add_child(block)
	var axe:Node3D=court.call("exec_prop","axe_bronze")
	Props.seat(axe,block,"axe_bite")
	var edge:Array=Props.info("axe_bronze").edge
	var edge_at:=axe.transform*Vector3(float(edge[0]),float(edge[1]),float(edge[2]))
	assert_float(edge_at.y).is_between(0.35,0.45)
	assert_float((axe.transform*Vector3.ZERO).y).is_greater(0.6)


func test_blood_lands_where_it_falls()->void:
	var blood:Blood=auto_free(Blood.new())
	# out of the tree the drops land at once (in the court they land on time)
	blood.geyser(Vector3(0.0,0.6,0.0),Vector3(0.2,1.0,0.0),2.0,1.0)
	assert_int(blood.landed).is_greater_equal(6)
	var far:=0
	for i in blood.landed:
		var at:=blood.spots[i]
		assert_float(at.y).is_less(0.05)
		if Vector2(at.x,at.z).length()>0.5:far+=1
	# a fountain carries: most of it comes down away from the neck
	assert_int(far).is_greater(blood.landed/2)
	blood.clear()
	assert_int(blood.landed).is_equal(0)


func test_blood_stains_the_front_row_and_rests_when_idle()->void:
	var court:=_built("chiefs_hall",{"tier":1,"era_tags":["pottery","metal"]})
	var blood:Node3D=court.call("blood")
	assert_object(blood).is_same(court.call("blood"))
	var fig:=_figure(court)
	blood.call("stain_figure",fig,2)
	assert_int(int(blood.call("stickers_on"))).is_equal(2)
	var skel:Skeleton3D=fig.get("skeleton")
	assert_object(skel.get_node_or_null("Blood_chest")).is_not_null()
	assert_object(skel.get_node_or_null("Blood_head")).is_not_null()
	# the geyser's jet squirts, then everything is wiped and rests
	blood.call("geyser",Vector3(0.0,0.6,2.0),Vector3.UP,1.0,1.0)
	assert_int(int(blood.call("jets_on"))).is_equal(1)
	blood.call("clear")
	assert_int(int(blood.call("jets_on"))).is_equal(0)
	blood.call("stain_figure",fig,2)
	# nothing runs when idle
	assert_bool(blood.is_processing()).is_false()
	for e in blood.find_children("*","GPUParticles3D",true,false):assert_bool((e as GPUParticles3D).emitting).is_false()
	blood.call("clear")
	assert_int(int(blood.call("stickers_on"))).is_equal(0)


func test_the_hall_remembers_its_dead()->void:
	var none:=_built("chiefs_hall",{"tier":1})
	assert_int(int((none.get("trophies") as Dictionary).stakes)).is_equal(0)
	var few:=_built("chiefs_hall",{"tier":1,"executions":4,"execution_days":[0.0,1.0,7.0,30.0]})
	assert_int(int((few.get("trophies") as Dictionary).stakes)).is_equal(4)
	assert_int(int((few.get("trophies") as Dictionary).heap)).is_equal(0)
	# the stains of the last few days, not of a week ago
	assert_int(int((few.get("trophies") as Dictionary).stains)).is_equal(2)
	assert_int(int((few.call("blood") as Node3D).call("stains_shown"))).is_equal(2)
	var shown:=0
	for node in few.find_children("*","Node3D",true,false):
		if String(node.get_meta("prop",""))=="skull_stake" and (node as Node3D).visible:shown+=1
	assert_int(shown).is_equal(4)
	# the stakes stand by the door
	var door:Vector3=(few.call("mark","door") as Marker3D).global_position
	for node in few.find_children("*","Node3D",true,false):
		if String(node.get_meta("prop",""))!="skull_stake":continue
		var at:=(node as Node3D).global_position
		assert_float(Vector2(at.x-door.x,at.z-door.z).length()).is_less(3.2)
	var many:=_built("chiefs_hall",{"tier":1,"executions":30,"execution_days":[2.0]})
	assert_int(int((many.get("trophies") as Dictionary).stakes)).is_equal(CourtSet.SKULL_STAKES)
	assert_int(int((many.get("trophies") as Dictionary).heap)).is_equal(CourtSet.SKULL_HEAP)
	assert_int(int((many.get("trophies") as Dictionary).stains)).is_equal(1)


func test_the_ledger_s_executions_are_read()->void:
	var causes:=[
		{"day":90,"cause":"Executed at the god's word","count":2},
		{"day":95,"cause":"Hardship","count":5},
		{"day":99,"cause":"Executed at the god's word","count":1},
	]
	var dead:=CourtSet.executions_from(causes,100)
	assert_int(int(dead.executions)).is_equal(3)
	assert_array(dead.execution_days).is_equal([1.0,10.0,10.0])
	assert_int(int(CourtSet.executions_from([],100).executions)).is_equal(0)


func test_the_camp_dogs_come_as_a_pack()->void:
	var court:=_built("hearth_council",{"tier":0})
	var pack:Array=court.call("dog_pack",3)
	assert_int(pack.size()).is_equal(4)
	var coats:={}
	for dog in pack:coats[String(dog.get("coat"))]=true
	assert_int(coats.size()).is_equal(4)
	for clip_name in ["tug","crunch","carry"]:
		assert_float(float(pack[0].call("clip_length",clip_name))).override_failure_message("no %s clip" % clip_name).is_greater(0.2)


func test_a_dog_carries_the_thighbone_and_drops_it()->void:
	var court:=_built("hearth_council",{"tier":0})
	var dog:Node3D=court.call("animal","dog")
	var bone:Node3D=court.call("exec_prop","thighbone")
	assert_bool(dog.call("carry",bone)).is_true()
	assert_str(String(bone.get_parent().name)).is_equal("Mouth")
	assert_object(dog.get("carried")).is_same(bone)
	var dropped:Node3D=dog.call("drop_carried")
	assert_object(dropped).is_same(bone)
	assert_object(bone.get_parent()).is_same(court)
	assert_float(bone.global_position.y).is_less(0.1)
	assert_object(dog.get("carried")).is_null()
