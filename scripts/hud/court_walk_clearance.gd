extends RefCounted
## Only the walking upper arms are fitted; source animations remain immutable.
## No extra per-frame skeleton modifier, lower-body key or clock is involved.
const CLIPS:=["walk_in","walk_out"]
const CACHE_LIMIT:=64
static var _cache:Dictionary={}

static func degrees_for(variant:String,outfit:String)->float:
	# Calibrated against all hand and garment triangles at 32 phases of each
	# walk. The narrow-shouldered old/child bodies need more hip clearance;
	# older loose shells need more ease than fitted skirts or trousers.
	var base:=8.0 if variant in ["female_old","child"] else 6.0
	if outfit in ["hide","tunic","robe"]:
		if variant=="female_old" or (variant=="child" and outfit=="tunic"):return 16.0
		return 14.0 if variant=="child" else 12.0
	if outfit=="business":return base+(3.0 if variant=="female_old" else 2.0)
	if outfit in ["medieval","courtcoat","formal"]:
		if variant=="female_old" and outfit=="formal":return 15.0
		if variant in ["male_adult","male_young"]:return 8.0
		return 14.0 if variant in ["female_old","child"] else 12.0
	return base

static func configure(player:AnimationPlayer,skeleton:Skeleton3D,variant:String,outfit:String,override_degrees:=-1.0)->void:
	if player==null or skeleton==null or not player.has_animation_library(&""):return
	if not player.has_meta(&"walk_clearance_originals"):
		# Figure._dress first runs in setup, before any clip starts. Own the two
		# walks once; subsequent redressing never replaces a playing resource.
		var original:=player.get_animation_library(&"")
		var owned:=AnimationLibrary.new();var originals:Dictionary={}
		for name:StringName in original.get_animation_list():
			var clip:=original.get_animation(name)
			if String(name) in CLIPS:
				originals[String(name)]=clip
				owned.add_animation(name,clip.duplicate(true))
			else:owned.add_animation(name,clip)
		player.remove_animation_library(&"");player.add_animation_library(&"",owned)
		player.set_meta(&"walk_clearance_originals",originals)
	var amount:=override_degrees if override_degrees>=0 else degrees_for(variant,outfit)
	if player.get_meta(&"walk_clearance_degrees",-1.0)==amount:return
	var originals:Dictionary=player.get_meta(&"walk_clearance_originals")
	var library:=player.get_animation_library(&"")
	for name:String in CLIPS:
		if not originals.has(name):continue
		var source:=originals[name] as Animation
		var key:="%d|%s|%.3f" % [source.get_instance_id(),variant,amount]
		var fitted:Animation=source
		if amount>0:
			if not _cache.has(key):
				if _cache.size()>=CACHE_LIMIT:_cache.erase(_cache.keys()[0])
				_cache[key]=_fit(source,skeleton,amount)
			fitted=_cache[key]
		var target:=library.get_animation(name)
		for track in fitted.get_track_count():
			if not _arm_track(fitted,track):continue
			for frame in fitted.track_get_key_count(track):target.track_set_key_value(track,frame,fitted.track_get_key_value(track,frame))
	player.set_meta(&"walk_clearance_degrees",amount)
	# A paused stride still needs to fit clothes immediately, at the same time.
	if String(player.assigned_animation) in CLIPS:player.seek(player.current_animation_position,true)

static func _arm_track(animation:Animation,track:int)->bool:
	if animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D:return false
	var path:=String(animation.track_get_path(track))
	return path.ends_with(":upper_arm.L") or path.ends_with(":upper_arm.R")

static func _fit(source:Animation,skeleton:Skeleton3D,degrees:float)->Animation:
	var made:=source.duplicate(true) as Animation
	for track in made.get_track_count():
		if made.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
		var path:=String(made.track_get_path(track))
		for side:String in ["L","R"]:
			if not path.ends_with(":upper_arm."+side):continue
			var bone:=skeleton.find_bone("upper_arm."+side)
			if bone<0:continue
			var parent:=skeleton.get_bone_parent(bone)
			var parent_basis:=skeleton.get_bone_global_rest(parent).basis if parent>=0 else Basis.IDENTITY
			var axis:=(parent_basis.inverse()*Vector3.BACK).normalized()
			var turn:=Quaternion(axis,deg_to_rad(degrees)*(1.0 if side=="L" else -1.0))
			for key in made.track_get_key_count(track):
				var rotation:Quaternion=source.track_get_key_value(track,key)
				made.track_set_key_value(track,key,(turn*rotation).normalized())
	return made
