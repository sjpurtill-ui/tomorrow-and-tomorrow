extends SceneTree

## Exercise actual Godot imports, skeleton binding and nonconstant clip playback.
func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var failures: Array[String] = []
	for id in ["levy", "line_infantry", "skirmisher", "cavalry", "siege_engineer", "field_artillery", "rifle_infantry", "machine_gun_company", "motorized_infantry", "slinger", "javelin_skirmisher", "crossbow_infantry", "chariot_archer", "horse_archer", "camel_cavalry", "pike_phalanx", "legionary_infantry", "war_elephant", "battering_ram", "siege_tower", "trireme", "armored_foot", "pavise_crossbowman", "longbowman", "counterweight_trebuchet", "hand_cannon_team", "bombard"]:
		var resource := load("res://assets/models/basic_units/%s.glb" % id) as PackedScene
		if resource == null:
			failures.append(id + " missing imported scene")
			continue
		var unit := resource.instantiate()
		root.add_child(unit)
		var player := unit.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var skeleton := unit.find_child("Skeleton3D", true, false) as Skeleton3D
		if player == null or skeleton == null:
			failures.append(id + " missing animation player or skeleton")
			unit.free()
			continue
		for clip in ["idle", "walk", "attack", "death"]:
			if not player.has_animation(clip):
				failures.append(id + " missing " + clip)
				continue
			player.play(clip)
			player.seek(0.0, true)
			var initial: Array[Transform3D] = []
			for bone in skeleton.get_bone_count(): initial.append(skeleton.get_bone_pose(bone))
			player.seek(player.get_animation(clip).length * 0.3, true)
			var changed := false
			for bone in skeleton.get_bone_count():
				if not initial[bone].is_equal_approx(skeleton.get_bone_pose(bone)): changed = true
			if not changed: failures.append(id + "/" + clip + " is static")
			if clip == "attack" and absf(player.get_animation(clip).length - 1.75) > 0.01:
				failures.append(id + " attack duration is stale")
			if clip == "death":
				if absf(player.get_animation(clip).length - 2.5) > 0.01:
					failures.append(id + " death duration is stale")
				player.seek(2.25, true)
				var settled: Array[Transform3D] = []
				for bone in skeleton.get_bone_count(): settled.append(skeleton.get_bone_pose(bone))
				player.seek(2.5, true)
				for bone in skeleton.get_bone_count():
					# Import compression introduces sub-millimetre/0.1-degree noise.
					var final_pose := skeleton.get_bone_pose(bone)
					var position_drift := settled[bone].origin.distance_to(final_pose.origin)
					var angle_drift := settled[bone].basis.get_rotation_quaternion().angle_to(final_pose.basis.get_rotation_quaternion())
					if position_drift > 0.0005 or angle_drift > 0.002:
						failures.append(id + " death does not hold its settled pose: " + skeleton.get_bone_name(bone))
		if id == "skirmisher":
			var arrow := skeleton.find_bone("arrow")
			var string_bone := skeleton.find_bone("bowstring")
			if arrow < 0 or string_bone < 0: failures.append("archer missing arrow/string controls")
			else:
				player.play("attack")
				player.seek(1.25, true)
				if skeleton.get_bone_pose_scale(arrow).length() > 0.01:
					failures.append("released arrow did not hide")
				player.play("idle")
				player.seek(0.0, true)
				if skeleton.get_bone_pose_scale(arrow).x < 0.99:
					failures.append("idle did not restore the arrow")
		if id in ["slinger", "javelin_skirmisher", "crossbow_infantry", "chariot_archer", "horse_archer", "camel_cavalry", "pavise_crossbowman", "longbowman", "counterweight_trebuchet"]:
			var projectile := skeleton.find_bone("projectile")
			if projectile < 0: failures.append(id + " missing projectile control")
			else:
				player.play("attack"); player.seek(1.2, true)
				if skeleton.get_bone_pose_scale(projectile).length() > 0.01:
					failures.append(id + " released projectile remains visible")
				player.play("idle"); player.seek(0, true)
				if skeleton.get_bone_pose_scale(projectile).x < 0.99:
					failures.append(id + " idle failed to restore projectile")
		if id == "siege_tower":
			var ramp := skeleton.find_bone("ramp")
			if ramp < 0: failures.append("siege tower missing boarding ramp")
			else:
				player.play("idle"); player.seek(0, true)
				var raised_tip := skeleton.get_bone_global_pose(ramp) * Vector3(0, 2, 0)
				player.play("attack"); player.seek(1.2, true)
				var lowered_tip := skeleton.get_bone_global_pose(ramp) * Vector3(0, 2, 0)
				if lowered_tip.z - raised_tip.z < 1.5:
					failures.append("siege boarding ramp opens inward instead of toward the target")
		if id in ["pike_phalanx", "legionary_infantry", "armored_foot", "longbowman", "hand_cannon_team"]:
			player.play("death"); player.seek(2.5, true)
			var head := skeleton.find_bone("head")
			if head >= 0 and skeleton.get_bone_global_pose(head).origin.y > 0.75:
				failures.append(id + " death is propped up above the ground")
		if id == "counterweight_trebuchet":
			var weight := skeleton.find_bone("weight")
			player.play("idle"); player.seek(0, true)
			var loaded_height := skeleton.get_bone_global_pose(weight).origin.y
			player.play("attack"); player.seek(0.95, true)
			if loaded_height - skeleton.get_bone_global_pose(weight).origin.y < 0.7:
				failures.append("trebuchet counterweight does not fall during launch")
		if id in ["hand_cannon_team", "bombard"]:
			var flash := skeleton.find_bone("flash")
			player.play("attack"); player.seek(0.66, true)
			if skeleton.get_bone_pose_scale(flash).x < 0.5: failures.append(id + " missing firing flash")
			player.play("idle"); player.seek(0, true)
			if skeleton.get_bone_pose_scale(flash).length() > 0.01: failures.append(id + " idle retains firing flash")
		print("UNIT_IMPORT_OK ", id, " bones=", skeleton.get_bone_count(), " clips=", player.get_animation_list())
		unit.free()
	if failures.is_empty(): print("UNITS_VERIFIED: 27 imports, 108 animated clips")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
