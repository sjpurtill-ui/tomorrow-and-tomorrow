extends "res://tests/court_set_capture.gd"
## GPU captures of the set's part in the court's executions (EXECUTIONS.md):
## the props, act 2 (the club and the cooking pot), act 10 (the block, the
## bronze axe, the geyser on the front row), act 4 (the camp dogs and the
## thighbone), and the hall that remembers (skulls on stakes, stains). The
## figures stand in J's present clips: the acting is K's, the bodies J's.
## Windowed only, on a private desktop (as court_set_capture.gd):
##   ... -Scene res://tests/court_exec_capture.tscn [-UserArguments "--only=exec-pot"]
##   --only=execclip with --fixed-fps 24: the geyser and the dog's fetch, frame by frame

const Props:=preload("res://scripts/hud/court_exec_props.gd")

const EXEC:=[
	{"tag":"exec-props","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal","weaving"]},"cast":"none"},
	{"tag":"exec-pot","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band"},
	{"tag":"exec-pot-strip","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","size":STRIP,"insets":[40,40]},
	{"tag":"exec-clay-pot","era":"elders_circle","facts":{"food":0.75,"tier":1,"era_tags":["pottery","farming"]},"cast":"band"},
	{"tag":"exec-block","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal","weaving"]},"cast":"hall"},
	{"tag":"exec-geyser","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal","weaving"]},"cast":"hall"},
	{"tag":"exec-geyser-strip","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal","weaving"]},"cast":"hall","size":STRIP,"insets":[40,40]},
	{"tag":"exec-dogs","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band"},
	{"tag":"exec-dogs-strip","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","size":STRIP,"insets":[40,40]},
	{"tag":"exec-trophies-hall","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal"],"executions":17,"execution_days":[0.0,1.0,1.0,3.0,4.0,9.0]},"cast":"hall"},
	{"tag":"exec-grip","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band"},
	{"tag":"exec-trophies-fire","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[],"executions":5,"execution_days":[0.0,2.0]},"cast":"band"},
]

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
	out_dir=ProjectSettings.globalize_path("res://reports/court_exec/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	if capture:get_window().size=Vector2i(W,H)
	await _frames(2)
	if only=="execclip":
		# saving every frame is slow: keep the hall at high quality throughout
		CourtSet.quality="high"
		if capture:
			await _geyser_clip()
			await _fetch_clip()
	else:
		for spec:Dictionary in EXEC:
			if not only.is_empty() and not String(spec.tag).contains(only):continue
			await _exec_shot(spec)
	if failures.is_empty():
		print("COURT_EXEC_CAPTURE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("COURT_EXEC_CAPTURE FAIL: ",failure)
		get_tree().quit(1)

func _prop(court:Node3D,prop_name:String,at:Vector3,yaw_deg:=0.0)->Node3D:
	var prop:Node3D=court.call("exec_prop",prop_name)
	if prop==null:
		_fail("no prop %s" % prop_name);return Node3D.new()
	court.add_child(prop)
	prop.position=at;prop.rotation.y=deg_to_rad(yaw_deg)
	return prop

func _quiet(court:Node3D)->void:
	for beast in court.get("animals"):
		if is_instance_valid(beast):(beast as Node3D).call("hold",60.0)

func _exec_shot(spec:Dictionary)->void:
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var rig:Node=court.get("rig")
	var tags:Array=(spec.facts as Dictionary).get("era_tags",[])
	var tag:=String(spec.tag)
	var wait:=40
	if tag=="exec-props":
		var dog:Node3D=court.call("animal","dog")
		if dog!=null:dog.visible=false
		var rows:=[[2.3,["cook_pot","cook_pot_lid","cook_bag","cook_bag_lid","block","boulder","skull_stake"]],[3.7,["cook_ladle","club","axe_bronze","thighbone","skull"]]]
		for row:Array in rows:
			var names:Array=row[1]
			var laid:=["club","axe_bronze","cook_ladle"]
			var total:=0.0
			for prop_name:String in names:
				var size:Array=Props.info(prop_name).get("size",[0.5,0.5,0.5])
				total+=(float(size[1]) if prop_name in laid else float(size[0]))+0.3
			var x:=-total*0.5
			for prop_name:String in names:
				var size2:Array=Props.info(prop_name).get("size",[0.5,0.5,0.5])
				if prop_name in laid:
					# laid down on the floor, heads to the right, edges to the god
					var p:=_prop(court,prop_name,Vector3(x,0.035,float(row[0])))
					p.rotation=Vector3(0.0,0.0,deg_to_rad(-90.0))
					x+=float(size2[1])+0.3
				else:
					_prop(court,prop_name,Vector3(x+float(size2[0])*0.5,0.0,float(row[0])),-15.0 if prop_name.begins_with("skull") else 0.0)
					x+=float(size2[0])+0.3
		rig.call("frame_points",PackedVector3Array([Vector3(-3.7,0,3.9),Vector3(3.7,0,3.9),Vector3(-3.7,1.75,2.2),Vector3(3.7,1.75,2.2)]),0.0,-12.0)
	elif tag.begins_with("exec-pot") or tag=="exec-clay-pot":
		# act 2: the wind-up, the cook waiting by the pot with the paddle, the lid off
		var cook_name:=Props.pick("cook",tags)
		var fire:=(court.call("mark","fire") as Marker3D).position
		var pot:=_prop(court,cook_name,fire+Vector3(1.05,0.0,1.25),-20.0)
		var lid:=_prop(court,Props.lid_for(cook_name),fire+Vector3(1.75,0.02,1.85),0.0)
		lid.rotation.z=deg_to_rad(8.0)
		var ladle:=_prop(court,"cook_ladle",Vector3.ZERO)
		var dog0:Node3D=court.call("animal","dog")
		if dog0!=null:
			dog0.position=Vector3(-0.2,0.0,0.95);dog0.rotation.y=deg_to_rad(-70.0)
			dog0.call("play","lie_idle",0.0,0.4)
		var cook:Node3D=bodies.get("officials_1")
		if cook!=null:
			cook.position=pot.position+Vector3(0.62,0.0,-0.35)
			cook.rotation.y=atan2(pot.position.x-cook.position.x,pot.position.z-cook.position.z)+0.5
			cook.call("play","staff",0.0,0.4)
			Props.hold(ladle,cook)
		var bat:Node3D=bodies.get("officials_0")
		var victim:Node3D=bodies.get("petitioner")
		if bat!=null and victim!=null:
			bat.position=victim.position+Vector3(-0.95,0.0,0.1)
			bat.rotation.y=atan2(victim.position.x-bat.position.x,victim.position.z-bat.position.z)
			bat.call("play","staff",0.0,0.9)
			var club:=_prop(court,"club",Vector3.ZERO)
			Props.hold(club,bat)
			victim.call("play","stand",0.0,0.2)
		_quiet(court)
		if tag=="exec-pot-strip":rig.call("wide",[victim,bat,cook],0.0,victim)
		else:rig.call("wide",[victim,bat,cook,bodies.get("officials_2")],0.0,victim)
	elif tag=="exec-block" or tag.begins_with("exec-geyser"):
		# act 10: the block before the god, the bronze axe stuck in it (the first swing)
		var victim:Node3D=bodies.get("petitioner")
		var block:=_prop(court,"block",victim.position+Vector3(0.0,0.0,0.75),0.0)
		var axe:=_prop(court,"axe_bronze",Vector3.ZERO)
		var heads:Node3D=bodies.get("officials_3")
		if heads!=null:
			heads.position=block.position+Vector3(0.75,0.0,-0.1)
			heads.rotation.y=deg_to_rad(-90.0)
		if tag=="exec-block":
			Props.seat(axe,block,"axe_bite")
			victim.call("play","kneel",0.0,5.0)
			if heads!=null:heads.call("play","stand",0.0,0.3)
		else:
			# the third swing has gone home: the axe is in the block, the geyser goes up
			Props.seat(axe,block,"axe_bite")
			if heads!=null:heads.call("play","stand",0.0,0.3)
			victim.call("play","kneel",0.0,5.0)
			# the third swing: a geyser from the neck at the block, over the front row
			var blood:Node3D=court.call("blood")
			var neck:=block.global_position+Vector3(0.0,0.62,0.05)
			blood.call("geyser",neck,Vector3(0.12,1.0,0.2),2.5,1.15)
			var front:Array=[]
			for key in ["officials_0","officials_1","officials_2"]:
				if bodies.has(key):front.append(bodies[key])
			blood.call("spray",neck,front,1.0)
			blood.call("pool",block.global_position+Vector3(0.0,0.0,0.3),0.55,1.2)
			for key in ["officials_0","officials_2"]:
				var o:Node3D=bodies.get(key)
				if o!=null:o.call("play","bow",0.2,0.3)
			wait=50
		_quiet(court)
		if tag=="exec-geyser-strip":rig.call("wide",[victim,heads],0.0,victim)
		else:
			var pts:=PackedVector3Array([block.position,block.position+Vector3(0,2.2,0)])
			for f in [victim,heads,bodies.get("officials_0"),bodies.get("officials_1")]:
				if f!=null:pts.append((f as Node3D).position);pts.append((f as Node3D).position+Vector3(0,1.8,0))
			rig.call("frame_points",pts,-1000.0,-10.0)
	elif tag.begins_with("exec-dogs"):
		# act 4: the camp dogs at something behind the windbreak; one comes back with a thighbone
		var pack:Array=court.call("dog_pack",3)
		var tug_at:=Vector3(1.7,0.0,-1.5)
		for i in pack.size():
			var dog:Node3D=pack[i]
			dog.call("set_active",false)
			if i==0:
				dog.position=Vector3(0.4,0.0,2.3);dog.rotation.y=deg_to_rad(-25.0)
				dog.call("carry",_prop(court,"thighbone",Vector3.ZERO))
				dog.call("play","carry",0.0,0.2)
			else:
				var a:=float(i)*2.1
				dog.position=tug_at+Vector3(cos(a)*0.55,0.0,sin(a)*0.4)
				dog.rotation.y=atan2(tug_at.x-dog.position.x,tug_at.z-dog.position.z)+PI
				dog.call("play","tug" if i!=2 else "crunch",0.0,float(i)*0.31)
		var victim:Node3D=bodies.get("petitioner")
		rig.call("wide",[victim,pack[0],bodies.get("officials_0"),bodies.get("officials_2")] if not tag.ends_with("strip") else [victim,pack[0]],0.0,victim)
	elif tag=="exec-grip":
		# how a held thing sits in the hand: the staff (J's), the club, the axe, the paddle
		var who:=["officials_0","officials_1","officials_2","officials_3"]
		var what:=["","club","axe_bronze","cook_ladle"]
		var clips:=["staff","staff","raise_hand","stand"]
		var pts:=PackedVector3Array()
		for i in 4:
			var f:Node3D=bodies.get(who[i])
			if f==null:continue
			f.position=Vector3(-1.8+float(i)*1.2,0.0,2.4);f.rotation.y=deg_to_rad(-20.0)
			f.call("play",clips[i],0.0,0.5)
			if not String(what[i]).is_empty():Props.hold(_prop(court,what[i],Vector3.ZERO),f)
			pts.append(f.position);pts.append(f.position+Vector3(0,2.1,0))
		for key in ["petitioner","crowd_0","crowd_2","crowd_5"]:
			if bodies.has(key):(bodies[key] as Node3D).visible=false
		_quiet(court)
		rig.call("frame_points",pts,-1000.0,-6.0)
	elif tag.begins_with("exec-trophies"):
		var door:Vector3=(court.call("mark","door") as Marker3D).position
		var fire2:Vector3=(court.call("mark","fire") as Marker3D).position
		var inward:=(fire2-door).normalized()
		var pts:=PackedVector3Array()
		for k in [0.0,3.4]:
			for side in [-1.4,1.4]:
				var right:=inward.cross(Vector3.UP).normalized()
				pts.append(door+inward*k+right*side)
				pts.append(door+inward*k+right*side+Vector3(0,1.9,0))
		var petitioner:Vector3=(court.call("mark","petitioner") as Marker3D).position
		pts.append(petitioner+Vector3(-1.0,0,-0.7));pts.append(petitioner+Vector3(1.0,0,0.7))
		rig.call("frame_points",pts,-1000.0,-18.0)
	for i in wait:await get_tree().process_frame
	if capture:
		var image:=view.get_texture().get_image()
		var path:=out_dir+"court-%s.png" % tag
		image.save_png(path)
		print("CAPTURE ",path)
	view.queue_free()
	await _frames(2)

## Act 10's end in the strip, frame by frame (5 s at 24 fps): the kneeling
## man at the block; the jolt; the geyser goes up and comes down on the front
## row, splats spreading on the floor and on them, the pool; the room bows.
func _geyser_clip()->void:
	var spec:={"tag":"geyserclip","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal","weaving"]},"cast":"hall","size":STRIP,"insets":[40,40]}
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var rig:Node=court.get("rig")
	var victim:Node3D=bodies.get("petitioner")
	var block:=_prop(court,"block",victim.position+Vector3(0.0,0.0,0.75),0.0)
	var axe:=_prop(court,"axe_bronze",Vector3.ZERO)
	var heads:Node3D=bodies.get("officials_3")
	if heads!=null:
		heads.position=block.position+Vector3(0.75,0.0,-0.1);heads.rotation.y=deg_to_rad(-90.0)
		heads.call("play","raise_hand",0.0,0.9)
		Props.hold(axe,heads)
	victim.call("play","kneel",0.0,5.0)
	_quiet(court)
	rig.call("wide",[victim,heads,bodies.get("officials_0"),bodies.get("officials_1")],0.0,victim)
	var dir:=out_dir+"geyserclip/"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):DirAccess.remove_absolute(dir+f)
	var blood:Node3D=court.call("blood")
	for frame in 120:
		if frame==18:
			# the third swing goes home: the axe in the block, the geyser
			Props.seat(axe,block,"axe_bite")
			if heads!=null:heads.call("play","stand",0.1)
			rig.call("shake",0.6)
			var neck:=block.global_position+Vector3(0.0,0.62,0.05)
			blood.call("geyser",neck,Vector3(0.12,1.0,0.2),2.4,1.15)
			var front:Array=[]
			for key in ["officials_0","officials_1","officials_2"]:
				if bodies.has(key):front.append(bodies[key])
			blood.call("spray",neck,front,1.0)
			blood.call("pool",block.global_position+Vector3(0.0,0.0,0.3),0.6,2.0)
		if frame==30:
			for key in ["officials_0","officials_2"]:
				var o:Node3D=bodies.get(key)
				if o!=null:o.call("play","bow",0.2)
		await get_tree().process_frame
		view.get_texture().get_image().save_png(dir+"frame_%03d.png" % frame)
	print("CLIP ",dir)
	view.queue_free()
	await _frames(2)

## Act 4's end (6 s): the dog trots back from behind the windbreak with the
## thighbone, drops it at the god's feet and wags; the pack crunches on.
func _fetch_clip()->void:
	var spec:={"tag":"fetchclip","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band","size":STRIP,"insets":[40,40]}
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var rig:Node=court.get("rig")
	var pack:Array=court.call("dog_pack",2)
	var tug_at:=Vector3(1.7,0.0,-1.5)
	for i in range(1,pack.size()):
		var d:Node3D=pack[i]
		var a:=float(i)*2.1
		d.position=tug_at+Vector3(cos(a)*0.55,0.0,sin(a)*0.4)
		d.rotation.y=atan2(tug_at.x-d.position.x,tug_at.z-d.position.z)+PI
		d.call("hold",60.0)
		d.call("play","tug" if i==1 else "crunch",0.0,float(i)*0.31)
	var dog:Node3D=pack[0]
	var bone:=_prop(court,"thighbone",tug_at+Vector3(0.3,0.04,0.2),40.0)
	dog.position=tug_at+Vector3(0.9,0.0,0.5)
	dog.call("hold",1.0)
	var victim:Node3D=bodies.get("petitioner")
	var god_feet:=Vector3(0.2,0.0,2.0)
	# the strip keeps the pack, the dog's run and the god's feet in view
	var pts:=PackedVector3Array([tug_at,tug_at+Vector3(0,0.9,0),god_feet,god_feet+Vector3(0,0.7,0)])
	for f in [victim,bodies.get("officials_0")]:
		if f!=null:pts.append((f as Node3D).position);pts.append((f as Node3D).position+Vector3(0,1.75,0))
	rig.call("frame_points",pts,-1000.0,-12.0)
	var dir:=out_dir+"fetchclip/"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):DirAccess.remove_absolute(dir+f)
	for frame in 168:
		if frame==6:dog.call("fetch",bone,god_feet)
		await get_tree().process_frame
		view.get_texture().get_image().save_png(dir+"frame_%03d.png" % frame)
	print("CLIP ",dir)
	view.queue_free()
	await _frames(2)
