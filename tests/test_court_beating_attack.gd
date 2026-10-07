extends GdUnitTestSuite
const Attack:=preload("res://scripts/hud/court_beating_attack.gd")
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Beating:=preload("res://scripts/hud/court_beating_stage.gd")
const Director:=preload("res://scripts/hud/court_director.gd")
const Blood:=preload("res://scripts/hud/court_blood.gd")

func _body(parent:Node3D,variant:String)->Node3D:
	var body:=Figure.new();parent.add_child(body)
	assert_bool(body.setup({"variant":variant,"outfit":"tunic","stance":"stand"})).is_true()
	body.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	Acting.of(body).active=false
	return body

func _fixture(rotated:=false,actor_variant:="female_adult",victim_variant:="male_adult")->Dictionary:
	var court:Node3D=auto_free(Node3D.new());add_child(court)
	if rotated:court.transform=Transform3D(Basis(Vector3.UP,1.13),Vector3(7,1.2,-4))
	var victim:=_body(court,victim_variant)
	var actor:=_body(court,actor_variant);actor.position=Vector3(0.62,0,0);actor.rotation.y=-PI*0.5
	var attack:=Attack.new();attack.configure(actor,victim,0);actor.skeleton.add_child(attack);attack.active=false
	var reaction:=Attack.new();reaction.configure(victim,victim,0,true);victim.skeleton.add_child(reaction);reaction.active=false
	return {"court":court,"victim":victim,"actor":actor,"attack":attack,"reaction":reaction}

func _pose(f:Dictionary,time:float,recoil:=0.65)->void:
	var victim:Node3D=f.victim;var actor:Node3D=f.actor
	victim.skeleton.reset_bone_poses();victim.player.advance(0.0)
	Acting.play(victim,"kneel_bound",{"blend":0.0,"hold":true})
	Acting.of(victim)._a.t=2.35;Acting.of(victim).step(0.0)
	f.reaction.clock=time;f.reaction.recoil=recoil;f.reaction.apply_pose(0.0)
	actor.skeleton.reset_bone_poses();actor.player.advance(0.0)
	f.attack.clock=time;f.attack.apply_pose(0.0)

func test_actual_mirrored_fists_contact_kneeling_victim_after_every_new_pose()->void:
	for rotated:bool in [false,true]:
		var f:=_fixture(rotated)
		for strike in 4:
			_pose(f,float(strike)*Attack.PERIOD+0.44)
			assert_float(float(f.attack.get_meta("contact_gap",INF))).is_less_equal(0.05)
			assert_int(int(f.attack.get_meta("side",-1))).is_equal(1 if strike%2==0 else 0)
		assert_int(f.attack.contacts).is_equal(4)
		print("BEATING_RIG_CONTACT rotated=",rotated," max_gap_m=",f.attack.max_gap," impacts=",f.attack.contacts)

func test_held_contact_only_registers_one_impact_per_stroke()->void:
	var f:=_fixture()
	for time:float in [0.40,0.42,0.45,0.49,0.51]:_pose(f,time)
	assert_int(f.attack.contacts).is_equal(1)
	_pose(f,Attack.PERIOD+0.43)
	assert_int(f.attack.contacts).is_equal(2)

func test_cancel_stops_contact_and_does_not_hide_or_split_victim()->void:
	var f:=_fixture();_pose(f,0.43)
	var count:int=f.attack.contacts
	f.attack.cancel();_pose(f,Attack.PERIOD+0.43)
	assert_int(f.attack.contacts).is_equal(count)
	assert_bool(f.victim.visible).is_true()
	assert_bool(f.attack.active).is_false()
	assert_object(f.victim.skeleton).is_not_null()

func test_reaction_is_bounded_and_cancellable()->void:
	var f:=_fixture()
	var reaction:=Attack.new();reaction.configure(f.victim,f.victim,0,true);f.victim.skeleton.add_child(reaction)
	reaction.active=false;reaction.clock=4.0;reaction.hit();reaction.apply_pose(0.02)
	assert_float(float(reaction.get_meta("recoil"))).is_between(0.0,1.0)
	assert_float(float(reaction.get_meta("collapse"))).is_between(0.0,1.0)
	reaction.cancel();var value:float=reaction.recoil;reaction.apply_pose(1.0)
	assert_float(reaction.recoil).is_equal(value)

func test_actual_court_official_ancestry_does_not_replace_membership()->void:
	var cast:=Director.normal_cast([
		{"key":"official","role":"court","person":{"age":38,"appearance_civ_id":"civ_10","office_title":"Treasurer"}},
		{"key":"retinue","role":"attendant","person":{"age":35,"appearance_civ_id":"player"}},
		{"key":"young","role":"court","person":{"age":17}},
		{"key":"elder","role":"court","person":{"age":"old"}}
	],{"envoy":{"civ_id":"civ_10"}})
	assert_bool(Beating.eligible_attacker(cast[0])).is_true()
	assert_bool(Beating.eligible_attacker(cast[1])).is_false()
	assert_bool(Beating.eligible_attacker(cast[2])).is_false()
	assert_bool(Beating.eligible_attacker(cast[3])).is_true()
	assert_bool(Beating.eligible_attacker({"kind":"guard","age":35,"people":"civ_10"})).is_false()

func test_mirrored_imported_fingers_close_like_authored_fist_at_contact()->void:
	var f:=_fixture()
	for strike in 2:
		_pose(f,float(strike)*Attack.PERIOD+0.44)
		var suffix:=".R" if strike==0 else ".L"
		var sign_value:=-1.0 if strike==0 else 1.0
		var sk:Skeleton3D=f.actor.skeleton
		for row:Array in [["fingers",96.0],["index",88.0],["thumb",46.0]]:
			var bone:=sk.find_bone(String(row[0])+suffix)
			assert_int(bone).is_greater_equal(0)
			var global_rest:=sk.get_bone_global_rest(bone).basis.get_rotation_quaternion()
			var delta:=sk.get_bone_rest(bone).basis.get_rotation_quaternion().inverse()*sk.get_bone_pose_rotation(bone)
			var figure_curl:=global_rest*delta*global_rest.inverse()
			assert_float(figure_curl.angle_to(Quaternion(Vector3.FORWARD,deg_to_rad(float(row[1])*sign_value)))).is_less(0.002)

func test_first_blood_holder_uses_posed_bone_before_another_frame()->void:
	var f:=_fixture(true);_pose(f,4.0)
	var blood:=Blood.new();f.court.add_child(blood)
	blood.stain_figure(f.victim,2)
	var sk:Skeleton3D=f.victim.skeleton
	for bone_name:String in ["chest","head"]:
		var holder:=sk.get_node("Blood_"+bone_name) as BoneAttachment3D
		var expected:=sk.global_transform*sk.get_bone_global_pose(sk.find_bone(bone_name))
		assert_float(holder.global_position.distance_to(expected.origin)).is_less(0.0001)
		assert_float(holder.global_basis.get_rotation_quaternion().angle_to(expected.basis.get_rotation_quaternion())).is_less(0.002)
		assert_int(holder.get_child_count()).is_equal(1)
	# Reusing the pooled attachment must also start on a changed pose immediately.
	_pose(f,6.0);blood.stain_figure(f.victim,2)
	for bone_name:String in ["chest","head"]:
		var holder:=sk.get_node("Blood_"+bone_name) as BoneAttachment3D
		var expected:=sk.global_transform*sk.get_bone_global_pose(sk.find_bone(bone_name))
		assert_float(holder.global_position.distance_to(expected.origin)).is_less(0.0001)

func test_other_skeleton_contact_and_blood_use_rendered_pose_after_victim_restore()->void:
	for rotated:bool in [false,true]:
		var f:=_fixture(rotated);_pose(f,0.44)
		var target:Vector3=f.attack.target_point()
		var frames:Dictionary=f.victim.get_meta("beating_rendered_bone_frames")
		var sk:Skeleton3D=f.victim.skeleton
		# Model the engine restoring this skeleton before another one's modifier.
		sk.reset_bone_poses();f.victim.player.advance(0.0)
		var restored:=sk.global_transform*sk.get_bone_global_pose(sk.find_bone("chest"))
		assert_float(restored.origin.distance_to((frames.chest as Transform3D).origin)).is_greater(0.1)
		f.actor.skeleton.reset_bone_poses();f.actor.player.advance(0.0)
		f.attack.clock=0.45;f.attack.apply_pose(0.0)
		assert_float(f.attack.target_point().distance_to(target)).is_less(0.0001)
		assert_float(float(f.attack.get_meta("contact_gap"))).is_less_equal(0.05)
		var blood:=Blood.new();f.court.add_child(blood)
		blood.stain_figure(f.victim,2,frames)
		for bone_name:String in ["chest","head"]:
			var holder:=sk.get_node("Blood_"+bone_name) as BoneAttachment3D
			var expected:Transform3D=frames[bone_name]
			assert_float(holder.global_position.distance_to(expected.origin)).is_less(0.0001)
			assert_float(holder.global_basis.get_rotation_quaternion().angle_to(expected.basis.get_rotation_quaternion())).is_less(0.002)

func test_late_slump_contact_at_all_three_approaches_with_adult_body_heights()->void:
	var maximum:=0.0
	for victim_variant:String in ["male_adult","female_adult"]:
		for actor_variant:String in ["male_adult","female_adult","male_old"]:
			for slot in 3:
				var f:=_fixture(true,actor_variant,victim_variant)
				var position:=Vector3.BACK.rotated(Vector3.UP,deg_to_rad([78.0,180.0,282.0][slot]))*Beating.APPROACH_RADIUS
				f.actor.position=position;f.actor.rotation.y=atan2(-position.x,-position.z)
				f.attack.index=slot
				for recoil:float in [0.0,1.0]:
					for phase:float in [0.40,0.45,0.50]:
						_pose(f,Attack.PERIOD*3.0+float(slot)*0.48+phase,recoil)
						var gap:=float(f.attack.get_meta("contact_gap",INF))
						maximum=maxf(maximum,gap)
						assert_float(gap).override_failure_message("%s vs %s slot %d phase %.2f recoil %.1f gap %.5f" % [actor_variant,victim_variant,slot,phase,recoil,gap]).is_less_equal(0.05)
						assert_float(float(f.attack.get_meta("strike_lean",INF))).is_less_equal(0.830001)
	print("BEATING_LATE_CONTACT max_gap_m=",maximum)
