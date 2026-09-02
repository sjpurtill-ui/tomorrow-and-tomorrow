extends Node
## Probes terrain-derived landmark naming: the catalog is well-formed, the
## ground survey classifies every sampled land point into a real class, the
## classes actually occur across the world (thresholds are live-calibrated
## against this output), and scout landmark resolution names real features.

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const LandmarkFeatureCatalog:=preload("res://scripts/landmark_feature_catalog.gd")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(917331)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame

	# Catalog integrity: unique ids, every class populated, myths present.
	var seen_ids:Dictionary={}
	var total_entries:=0
	for feature_class in LandmarkFeatureCatalog.FEATURES:
		var entries:Array=LandmarkFeatureCatalog.FEATURES[feature_class]
		_expect(entries.size()>=12,"class %s has only %d entries" % [feature_class,entries.size()])
		for entry_variant in entries:
			var entry:Dictionary=entry_variant
			total_entries+=1
			var id:=String(entry.get("id",""))
			_expect(id!="" and not seen_ids.has(id),"duplicate or empty feature id '%s'" % id)
			seen_ids[id]=true
			_expect(String(entry.get("name",""))!="","feature %s has no name" % id)
			_expect(String(entry.get("myth",""))!="","feature %s has no myth" % id)
	_expect(total_entries>=180,"catalog holds only %d features" % total_entries)

	# Classification: sample the world; every land point classifies, and the
	# terrain genuinely produces a spread of classes.
	var class_counts:Dictionary={}
	var rng:=RandomNumberGenerator.new()
	rng.seed=42
	var land_samples:=0
	var slopes:Array[float]=[]
	var reliefs:Array[float]=[]
	var origin:=Vector2(terrain.world_start_position.x,terrain.world_start_position.z)
	for _sample in 900:
		var position:=origin+Vector2(rng.randf_range(-260.0,260.0),rng.randf_range(-260.0,260.0))
		var survey:Dictionary=terrain._survey_ground_at(position)
		var feature_class:String=LandmarkFeatureCatalog.classify(survey)
		if String(survey.get("biome",""))=="water":
			_expect(feature_class=="","open water classified as '%s'" % feature_class)
			continue
		land_samples+=1
		slopes.append(float(survey.get("slope",0.0)))
		reliefs.append(float(survey.get("relief",0.0)))
		_expect(feature_class!="","land point %s failed to classify (survey %s)" % [position,survey])
		class_counts[feature_class]=int(class_counts.get(feature_class,0))+1
	slopes.sort()
	reliefs.sort()
	if land_samples>10:
		print("LANDMARK_SLOPE p50=%.3f p90=%.3f p97=%.3f max=%.3f" % [slopes[land_samples/2],slopes[land_samples*9/10],slopes[land_samples*97/100],slopes[land_samples-1]])
		print("LANDMARK_RELIEF p3=%.3f p10=%.3f p90=%.3f p97=%.3f" % [reliefs[land_samples*3/100],reliefs[land_samples/10],reliefs[land_samples*9/10],reliefs[land_samples*97/100]])
	print("LANDMARK_CLASS_DISTRIBUTION land=%d %s" % [land_samples,class_counts])
	_expect(land_samples>200,"world sample found almost no land")
	_expect(class_counts.size()>=5,"only %d landmark classes occur; thresholds need recalibration: %s" % [class_counts.size(),class_counts])

	# pick(): names a feature for a real surveyed point, avoids taken names.
	var named:=0
	for _attempt in 60:
		var position:=origin+Vector2(rng.randf_range(-260.0,260.0),rng.randf_range(-260.0,260.0))
		var survey:Dictionary=terrain._survey_ground_at(position)
		if String(survey.get("biome",""))=="water": continue
		var feature:Dictionary=LandmarkFeatureCatalog.pick(survey,rng,"Grey",[])
		if feature.is_empty(): continue
		named+=1
		_expect(String(feature.get("myth",""))!="","picked feature %s lacks a myth" % feature.get("feature_id"))
		_expect(String(feature.get("name","")).find("%s")==-1,"adjective was not substituted in '%s'" % feature.get("name"))
	_expect(named>20,"pick() produced almost no named features (%d)" % named)
	_finish()


func _expect(condition:bool,message:String)->void:
	if not condition:
		failures.append(message)
		push_error("LANDMARK_CLASSIFICATION_PROBE %s" % message)


func _finish()->void:
	if failures.is_empty():
		print("LANDMARK_CLASSIFICATION_PROBE PASS")
		get_tree().quit(0)
	else:
		print("LANDMARK_CLASSIFICATION_PROBE FAIL (%d)" % failures.size())
		get_tree().quit(1)
