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
	{"tag":"exec-skulls","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal"],"executions":21,"execution_days":[]},"cast":"none"},
	{"tag":"exec-sheet2","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"none"},
	{"tag":"exec-flare","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band"},
	{"tag":"exec-spears","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band"},
	{"tag":"exec-stones","era":"elders_circle","facts":{"food":0.75,"tier":1,"era_tags":["pottery","farming"]},"cast":"band"},
	{"tag":"exec-boulder","era":"hearth_council","facts":{"food":0.75,"tier":0,"era_tags":[]},"cast":"band"},
	{"tag":"exec-cauldron","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal","weaving"]},"cast":"hall"},
	{"tag":"exec-cauldron-clay","era":"elders_circle","facts":{"food":0.75,"tier":1,"era_tags":["pottery","farming"]},"cast":"band"},
	{"tag":"exec-stake","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","weaving"]},"cast":"hall"},
	{"tag":"exec-herd","era":"elders_circle","facts":{"food":0.75,"tier":1,"era_tags":["pottery","farming","dairy"]},"cast":"band"},
	{"tag":"exec-big","era":"imperial_court","facts":{"food":0.8,"tier":3,"era_tags":["pottery","metal","writing","wheel","masonry"]},"cast":"none"},
	{"tag":"exec-statues","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal"],"executions":6,
		"statues":[{"look":{"variant":"male_adult","outfit":"tunic","hair":"long","beard":"beard_full","stance":"stand"},"clip":"raise_hand","at":0.5},
			{"look":{"variant":"female_adult","outfit":"tunic","hair":"braids","stance":"stand"},"clip":"point","at":0.6}]},"cast":"hall"},
	{"tag":"exec-arrows","era":"elders_circle","facts":{"food":0.75,"tier":1,"era_tags":["pottery","farming"]},"cast":"band"},
]

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
	out_dir=ProjectSettings.globalize_path("res://reports/court_exec/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	if capture:get_window().size=Vector2i(W,H)
	await _frames(2)
	if only=="execperf":
		CourtSet.quality="high"
		if capture:await _geyser_perf()
	elif only=="execclip":
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
	elif tag=="exec-skulls":
		# close on the trophies by the door: do the skulls read as skulls?
		var door2:Vector3=(court.call("mark","door") as Marker3D).position
		var fire3:Vector3=(court.call("mark","fire") as Marker3D).position
		var inward2:=(fire3-door2).normalized()
		var right2:=inward2.cross(Vector3.UP).normalized()
		rig.call("frame_points",PackedVector3Array([door2+inward2*0.2+right2*1.3,door2+inward2*0.2-right2*1.3,door2+inward2*2.0+right2*1.3+Vector3(0,1.8,0),door2+inward2*2.0-right2*1.3]),-1000.0,-12.0)
	elif tag=="exec-sheet2":
		var dog2:Node3D=court.call("animal","dog")
		if dog2!=null:dog2.visible=false
		var rows2:=[[1.6,["cauldron_clay","cauldron_bronze","boulder_ledge","impaling_stake"]],[3.3,["cook_pot","cook_pot_lid","ash_pile","skull","stone_a","stone_b","stone_c"]],[4.3,["spear_flint","spear_bronze","bow","arrow"]]]
		var laid2:=["spear_flint","spear_bronze","bow","arrow"]
		for row:Array in rows2:
			var names:Array=row[1]
			var total:=0.0
			for prop_name:String in names:
				var size:Array=Props.info(prop_name).get("size",[0.5,0.5,0.5])
				total+=(float(size[1]) if prop_name in laid2 else float(size[0]))+0.35
			var x:=-total*0.5
			for prop_name:String in names:
				var size2:Array=Props.info(prop_name).get("size",[0.5,0.5,0.5])
				if prop_name in laid2:
					var p2:=_prop(court,prop_name,Vector3(x,0.04,float(row[0])))
					p2.rotation=Vector3(0.0,0.0,deg_to_rad(-90.0))
					x+=float(size2[1])+0.35
				else:
					_prop(court,prop_name,Vector3(x+float(size2[0])*0.5,0.0,float(row[0])),-20.0 if prop_name=="skull" else 0.0)
					x+=float(size2[0])+0.35
		rig.call("frame_points",PackedVector3Array([Vector3(-3.4,0,4.6),Vector3(3.4,0,4.6),Vector3(-3.4,2.7,1.3),Vector3(3.4,2.7,1.3)]),0.0,-16.0)
	elif tag=="exec-flare":
		# act 3: WHOOMPH, the hearth roars up; the ash of the last one smoulders by it
		_prop(court,"ash_pile",Vector3(0.95,0.0,1.05),0.0)
		court.call("fire_flare",3.0,1.0)
		var elder:Node3D=bodies.get("officials_0")
		if elder!=null:
			elder.position=Vector3(1.2,0.0,1.75);elder.rotation.y=deg_to_rad(200.0)
			elder.call("play","crouch",0.0,0.5)
		_quiet(court)
		rig.call("wide",[bodies.get("petitioner"),elder,bodies.get("officials_1")],0.0,bodies.get("petitioner"))
		wait=20
	elif tag=="exec-spears":
		# act 5: the pincushion, a spear in the air, one in the hide wall
		var victim2:Node3D=bodies.get("petitioner")
		victim2.call("play","stand",0.0,0.3)
		var chest:=victim2.global_position+Vector3(0.0,1.2,0.0)
		# each flew in from a side: its butt sticks out toward the one who threw it
		# they came down on him from their arcs: the butts stand up and out
		var hits:=[[Vector3(0.12,0.15,0.08),Vector3(-0.7,-0.6,-0.35)],[Vector3(-0.12,0.0,0.08),Vector3(0.75,-0.55,-0.3)],[Vector3(0.1,-0.3,0.08),Vector3(-0.5,-0.75,-0.4)],[Vector3(-0.08,0.35,0.06),Vector3(0.45,-0.8,-0.35)],[Vector3(0.1,-0.55,0.06),Vector3(-0.8,-0.45,-0.4)]]
		for h:Array in hits:
			var sp:=_prop(court,"spear_flint",Vector3.ZERO)
			Props.stick(sp,victim2,chest+h[0],(h[1] as Vector3).normalized(),0.3)
		var wall_sp:=_prop(court,"spear_flint",Vector3.ZERO)
		Props.stick(wall_sp,court,Vector3(-2.6,1.1,-4.6),Vector3(-0.2,-0.15,-1.0),0.25)
		var flying:=_prop(court,"spear_flint",Vector3.ZERO)
		var from2:=Vector3(2.6,1.6,1.0);var to2:=chest
		var k2:=0.6
		var at2:=from2.lerp(to2,k2)+Vector3(0.0,4.0*0.5*k2*(1.0-k2),0.0)
		var d2:=((to2-from2)+Vector3(0.0,4.0*0.5*(1.0-2.0*k2),0.0)).normalized()
		flying.global_transform=Transform3D(Props._along(d2),at2-Props._along(d2)*Vector3(0,1.0,0))
		for key in ["officials_1","officials_3"]:
			var thrower:Node3D=bodies.get(key)
			if thrower!=null:
				thrower.rotation.y=atan2(victim2.position.x-thrower.position.x,victim2.position.z-thrower.position.z)
				thrower.call("play","staff",0.0,0.4)
				Props.hold(_prop(court,"spear_flint",Vector3.ZERO),thrower)
		_quiet(court)
		rig.call("wide",[victim2,bodies.get("officials_1"),bodies.get("officials_0")],0.0,victim2)
	elif tag=="exec-stones":
		# act 6: everyone throws; stones in the air, the first ones on the ground
		var victim3:Node3D=bodies.get("petitioner")
		victim3.call("play","kneel",0.0,5.0)
		var head:=victim3.global_position+Vector3(0.0,0.9,0.0)
		var k3:=0
		for key in ["officials_0","officials_1","officials_2","officials_3","crowd_5"]:
			var thrower2:Node3D=bodies.get(key)
			if thrower2==null:continue
			var from3:=thrower2.global_position+Vector3(0.0,1.6,0.0)
			var kk:=0.35+0.12*float(k3%4)
			var st:=_prop(court,["stone_a","stone_b","stone_c"][k3%3],from3.lerp(head,kk)+Vector3(0.0,4.0*0.6*kk*(1.0-kk),0.0))
			st.rotation=Vector3(float(k3)*1.3,float(k3)*0.7,0.4)
			thrower2.call("play","raise_hand" if k3%2==0 else "point",0.0,0.6)
			k3+=1
		for i in 9:
			var a:=float(i)*0.9
			_prop(court,["stone_b","stone_a","stone_c"][i%3],victim3.position+Vector3(cos(a)*0.5,0.0,sin(a)*0.4),float(i)*40.0)
		_quiet(court)
		rig.call("wide",[victim3,bodies.get("officials_0"),bodies.get("officials_1")],0.0,victim3)
	elif tag=="exec-boulder":
		# act 1: the ledge, the boulder on it, two men at the lever
		var victim4:Node3D=bodies.get("petitioner")
		var ledge:=_prop(court,"boulder_ledge",victim4.position+Vector3(-0.2,0.0,-0.9),0.0)
		var boulder:=_prop(court,"boulder",Vector3.ZERO)
		Props.seat(boulder,ledge,"boulder_seat")
		boulder.position+=Vector3(0.0,0.0,0.25)
		victim4.call("play","stand",0.0,0.3)
		for pair in [["officials_1",Vector3(-0.9,0.0,-1.0)],["officials_3",Vector3(0.7,0.0,-1.15)]]:
			var man:Node3D=bodies.get(pair[0])
			if man!=null:
				man.position=ledge.position+(pair[1] as Vector3);man.rotation.y=atan2(ledge.position.x-man.position.x,ledge.position.z-man.position.z)
				man.call("play","raise_hand",0.0,0.5)
		_quiet(court)
		rig.call("wide",[victim4,bodies.get("officials_1"),bodies.get("officials_3")],0.0,victim4)
	elif tag.begins_with("exec-cauldron"):
		# act 14: the great cauldron on the boil over its coals; a skull bobs up
		var tags2:Array=(spec.facts as Dictionary).get("era_tags",[])
		var name2:=Props.pick("cauldron",tags2)
		var victim5:Node3D=bodies.get("petitioner")
		var pot2:=_prop(court,name2,victim5.position+Vector3(1.3,0.0,0.2),0.0)
		court.call("boil",pot2,1.0)
		var fire_seat:Array=Props.info(name2).fire_seat
		court.call("small_fire",pot2.global_position+Vector3(float(fire_seat[0]),float(fire_seat[1]),float(fire_seat[2])),0.32)
		var bob:=_prop(court,"skull",Vector3.ZERO)
		var broth:Array=Props.info(name2).broth
		court.remove_child(bob)
		pot2.add_child(bob);bob.position=Vector3(0.12,float(broth[1])-0.1,0.08);bob.rotation=Vector3(-0.5,0.4,0.2)
		var cook2:Node3D=bodies.get("officials_1")
		if cook2!=null:
			cook2.position=pot2.position+Vector3(0.75,0.0,-0.45)
			cook2.rotation.y=atan2(pot2.position.x-cook2.position.x,pot2.position.z-cook2.position.z)
			cook2.call("play","staff",0.0,0.3)
			Props.hold(_prop(court,"cook_ladle",Vector3.ZERO),cook2)
		victim5.call("play","stand",0.0,0.3)
		_quiet(court)
		rig.call("wide",[victim5,cook2,bodies.get("officials_0")],0.0,victim5)
		wait=50
	elif tag=="exec-stake":
		var victim6:Node3D=bodies.get("petitioner")
		_prop(court,"impaling_stake",victim6.position+Vector3(0.9,0.0,-0.2),0.0)
		victim6.call("play","stand",0.0,0.3)
		_quiet(court)
		rig.call("wide",[victim6,bodies.get("officials_1"),bodies.get("officials_0")],0.0,victim6)
	elif tag=="exec-arrows":
		# act 16: the archers at their bows; the porcupine
		var victim7:Node3D=bodies.get("petitioner")
		victim7.call("play","stand",0.0,0.3)
		var body7:=victim7.global_position+Vector3(0.0,1.1,0.0)
		# a porcupine: in all over, from the right and from above, every angle
		for i in 14:
			var a2:=float(i)*2.4
			var arrow:=_prop(court,"arrow",Vector3.ZERO)
			var off:=Vector3(sin(a2)*0.14,-0.5+float(i)/13.0*1.05,0.1+0.03*cos(a2*1.7))
			var d3:=Vector3(-1.0+0.5*cos(a2),-0.6*sin(a2*0.7)-0.2,-0.8+0.5*sin(a2*1.3)).normalized()
			Props.stick(arrow,victim7,body7+off,d3,0.12)
		for key in ["officials_1","officials_3"]:
			var archer:Node3D=bodies.get(key)
			if archer!=null:
				archer.rotation.y=atan2(victim7.position.x-archer.position.x,victim7.position.z-archer.position.z)
				archer.call("play","staff",0.0,0.4)
				Props.hold(_prop(court,"bow",Vector3.ZERO),archer)
		_quiet(court)
		rig.call("wide",[victim7,bodies.get("officials_1"),bodies.get("officials_0")],0.0,victim7)
	elif tag=="exec-herd":
		# the pigs at their dinner (act 9), the cattle come in (act 8)
		var victim8:Node3D=bodies.get("petitioner")
		victim8.call("play","kneel",0.0,5.0)
		var pigs:Array=court.call("beasts","pig",5,["pink","spotted","black","bristly","pink"])
		for i in pigs.size():
			var pig:Node3D=pigs[i]
			pig.call("set_active",false)
			var a3:=float(i)/float(pigs.size())*TAU+0.4
			pig.position=victim8.position+Vector3(cos(a3)*0.75,0.0,sin(a3)*0.55)
			pig.rotation.y=atan2(victim8.position.x-pig.position.x,victim8.position.z-pig.position.z)
			pig.call("play","eat" if i%3!=2 else "squeal",0.0,float(i)*0.29)
		var herd2:Array=court.call("beasts","cattle",3,["red","pied","dun"])
		for i in herd2.size():
			var cow:Node3D=herd2[i]
			cow.call("set_active",false)
			cow.position=Vector3(2.2+float(i)*1.4,0.0,-1.4+float(i%2)*0.9)
			cow.rotation.y=deg_to_rad(-120.0+float(i)*15.0)
			cow.call("play",["gallop","shake_hoof","idle"][i],0.0,0.2+float(i)*0.31)
		_quiet(court)
		rig.call("wide",[victim8,bodies.get("officials_0"),bodies.get("officials_1"),herd2[0]],0.0,victim8)
	elif tag=="exec-big":
		# the bear up on its hind legs (act 17), the elephant's foot coming down (act 18)
		var bear2:Node3D=(court.call("beasts","bear",1,[]) as Array)[0]
		bear2.call("set_active",false)
		bear2.position=Vector3(-2.2,0.0,2.2);bear2.rotation.y=deg_to_rad(30.0)
		bear2.call("play","rear",0.0,1.2)
		var ele2:Node3D=(court.call("beasts","elephant",1,[]) as Array)[0]
		ele2.call("set_active",false)
		ele2.position=Vector3(2.0,0.0,0.4);ele2.rotation.y=deg_to_rad(-60.0)
		ele2.call("play","stomp",0.0,0.85)
		var pig2:Node3D=(court.call("beasts","pig",1,["spotted"]) as Array)[0]
		pig2.call("set_active",false)
		pig2.position=Vector3(-0.4,0.0,3.2);pig2.rotation.y=deg_to_rad(10.0)
		pig2.call("play","squeal",0.0,0.4)
		var ox:Node3D=(court.call("beasts","cattle",1,["black"]) as Array)[0]
		ox.call("set_active",false)
		ox.position=Vector3(0.2,0.0,1.6);ox.rotation.y=deg_to_rad(80.0)
		ox.call("play","pull",0.0,0.5)
		rig.call("frame_points",PackedVector3Array([Vector3(-3.2,0,3.6),Vector3(4.2,0,3.6),Vector3(-3.2,3.6,0.0),Vector3(4.2,3.6,0.0)]),0.0,-8.0)
	elif tag=="exec-statues":
		var door4:Vector3=(court.call("mark","door") as Marker3D).position
		var fire4:Vector3=(court.call("mark","fire") as Marker3D).position
		var inward4:=(fire4-door4).normalized()
		var right4:=inward4.cross(Vector3.UP).normalized()
		_quiet(court)
		rig.call("frame_points",PackedVector3Array([door4+right4*2.4,door4-right4*2.4,door4+inward4*3.2+right4*2.4+Vector3(0,2.6,0),door4+inward4*3.2-right4*2.4]),-1000.0,-10.0)
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

## The frame cost of the blood: the hall in the court's strip with its people,
## measured idle, mid-geyser (jet, drops, spray, pool, stickers) and after.
func _geyser_perf()->void:
	var spec:={"tag":"geyserperf","era":"chiefs_hall","facts":{"food":0.8,"tier":1,"era_tags":["pottery","metal","weaving"]},"cast":"hall","size":STRIP,"insets":[40,40]}
	var made:=await _stage(spec)
	var view:SubViewport=made[0];var court:Node3D=made[1];var bodies:Dictionary=made[2]
	var victim:Node3D=bodies.get("petitioner")
	var block:=_prop(court,"block",victim.position+Vector3(0.0,0.0,0.75),0.0)
	_quiet(court)
	RenderingServer.viewport_set_measure_render_time(view.get_viewport_rid(),true)
	for i in 30:await get_tree().process_frame
	for phase in ["idle","geyser","after"]:
		if phase=="geyser":
			var blood:Node3D=court.call("blood")
			var neck:=block.global_position+Vector3(0.0,0.62,0.05)
			blood.call("geyser",neck,Vector3(0.12,1.0,0.2),3.0,1.15)
			var front:Array=[]
			for key in ["officials_0","officials_1","officials_2"]:
				if bodies.has(key):front.append(bodies[key])
			blood.call("spray",neck,front,1.0)
			blood.call("pool",block.global_position+Vector3(0.0,0.0,0.3),0.6,2.0)
			for i in 8:await get_tree().process_frame
		if phase=="after":
			for i in 150:await get_tree().process_frame
		var gpu:=0.0;var cpu:=0.0;var n:=0;var draws:=0;var prims:=0
		for i in 60:
			await get_tree().process_frame
			gpu+=RenderingServer.viewport_get_measured_render_time_gpu(view.get_viewport_rid())
			cpu+=RenderingServer.viewport_get_measured_render_time_cpu(view.get_viewport_rid())
			draws=maxi(draws,view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
			prims=maxi(prims,view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
			n+=1
		var blood2:Node3D=court.call("blood") if phase!="idle" else null
		print("PERF blood %s draws=%d primitives=%d gpu_ms=%.2f cpu_ms=%.2f fps=%d splats=%d stickers=%d jets=%d" % [phase,draws,prims,gpu/float(n),cpu/float(n),Engine.get_frames_per_second(),
			int(blood2.get("landed")) if blood2!=null else 0,int(blood2.call("stickers_on")) if blood2!=null else 0,int(blood2.call("jets_on")) if blood2!=null else 0])
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
