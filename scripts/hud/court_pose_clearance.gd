extends RefCounted
## Cached fitting of ordinary arm poses. The source clips, clocks and every
## non-arm track stay unchanged; executions and prop-specific acts never enter.
const CLIPS:=["stand","sit_cross","stance_cross"]
const CACHE_LIMIT:=96
const PROFILES:={}
## Private diagnostic fixtures may supply calibration profiles before setup.
## Values are degrees, or [seconds,degrees] pairs sampled at original key times;
## an L/R dictionary can fit asymmetric arm poses without overcorrecting a hand.
static var overrides:Dictionary={}
static var _cache:Dictionary={}

static func profile_for(variant:String)->Dictionary:
	return overrides.get(variant,PROFILES.get(variant,{}))

static func degrees_at(value:Variant,time:float)->float:
	if value is float or value is int:return float(value)
	if not value is Array or value.is_empty():return 0.0
	if time<=float(value[0][0]):return float(value[0][1])
	for i in range(1,value.size()):
		if time<=float(value[i][0]):
			var a:Array=value[i-1];var b:Array=value[i]
			return lerpf(float(a[1]),float(b[1]),clampf((time-float(a[0]))/maxf(.00001,float(b[0])-float(a[0])),0.0,1.0))
	return float(value[-1][1])

static func fitted(source:Animation,skeleton:Skeleton3D,variant:String,clip:String)->Animation:
	if source==null or skeleton==null or not clip in CLIPS:return source
	var profile:=profile_for(variant)
	if not profile.has(clip):return source
	var value:Variant=profile[clip]
	var key:="%d|%s|%s|%s" % [source.get_instance_id(),variant,clip,JSON.stringify(value)]
	if _cache.has(key):return _cache[key]
	var made:=_copy_exact(source)
	for track in made.get_track_count():
		if not _arm_track(made,track,clip!="stand"):continue
		var path:=String(made.track_get_path(track))
		var side:="L" if path.ends_with(".L") else "R"
		var forearm:=path.ends_with(":forearm."+side)
		var bone:=skeleton.find_bone(("forearm." if forearm else "upper_arm.")+side)
		if bone<0:continue
		var parent:=skeleton.get_bone_parent(bone)
		var rest:=skeleton.get_bone_global_rest(parent).basis if parent>=0 else Basis.IDENTITY
		var axis:=(rest.inverse()*Vector3.BACK).normalized()
		var curve:Variant=value
		if value is Dictionary and (value.has("spread") or value.has("flex")):curve=value.get("flex" if forearm else "spread",0.0)
		elif forearm:continue
		for frame in made.track_get_key_count(track):
			var amount:=degrees_at(curve.get(side,0.0) if curve is Dictionary else curve,made.track_get_key_time(track,frame))
			if is_zero_approx(amount):continue
			var rotation:Quaternion=source.track_get_key_value(track,frame)
			if forearm:
				var hand:=skeleton.find_bone("hand."+side)
				if hand<0:continue
				# Flex in this key's actual elbow plane, toward the shoulder.
				# Both vectors are in upper-arm coordinates, so this works for
				# either side and does not twist the wrist around the forearm.
				axis=(rotation*skeleton.get_bone_rest(hand).origin).cross(-skeleton.get_bone_rest(bone).origin)
				if axis.length_squared()<.00000001:continue
				axis=axis.normalized()
			var turn:=Quaternion(axis,deg_to_rad(amount)*(1.0 if forearm or side=="L" else -1.0))
			made.track_set_key_value(track,frame,(turn*rotation).normalized())
	if _cache.size()>=CACHE_LIMIT:_cache.erase(_cache.keys()[0])
	_cache[key]=made
	return made

static func _copy_exact(source:Animation)->Animation:
	var made:=source.duplicate(true) as Animation
	# Resource duplication serializes glTF's double key times through packed
	# float arrays. Restore their original values before fitting any arm key.
	for track in source.get_track_count():
		for frame in source.track_get_key_count(track):
			made.track_set_key_time(track,frame,source.track_get_key_time(track,frame))
			made.track_set_key_transition(track,frame,source.track_get_key_transition(track,frame))
			made.track_set_key_value(track,frame,source.track_get_key_value(track,frame))
	return made

static func _arm_track(animation:Animation,track:int,include_forearm:=false)->bool:
	if animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D:return false
	var path:=String(animation.track_get_path(track))
	return path.ends_with(":upper_arm.L") or path.ends_with(":upper_arm.R") or (include_forearm and (path.ends_with(":forearm.L") or path.ends_with(":forearm.R")))

static func configure(player:AnimationPlayer,skeleton:Skeleton3D,variant:String)->void:
	if player==null or skeleton==null or not player.has_animation(&"stand"):return
	if not player.has_meta(&"pose_clearance_original_stand"):
		# Walking already gives each figure an owned library during _dress.
		# Keep one owned stand resource as well, without replacing it mid-play.
		var library:=player.get_animation_library(&"")
		var original:=library.get_animation(&"stand")
		player.set_meta(&"pose_clearance_original_stand",original)
		library.remove_animation(&"stand")
		library.add_animation(&"stand",_copy_exact(original))
	var source:Animation=player.get_meta(&"pose_clearance_original_stand")
	var fit:=fitted(source,skeleton,variant,"stand")
	if player.get_meta(&"pose_clearance_stand_id",0)==fit.get_instance_id():return
	var target:=player.get_animation(&"stand")
	for track in fit.get_track_count():
		if not _arm_track(fit,track):continue
		for frame in fit.track_get_key_count(track):target.track_set_key_value(track,frame,fit.track_get_key_value(track,frame))
	player.set_meta(&"pose_clearance_stand_id",fit.get_instance_id())
	if String(player.assigned_animation)=="stand":player.seek(player.current_animation_position,true)
