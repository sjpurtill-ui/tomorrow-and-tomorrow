extends GdUnitTestSuite
const Culture:=preload("res://scripts/settlement_culture_visual.gd")
const Values:=preload("res://scripts/societal_values_model.gd")

func _values(order:float,openness:float)->Dictionary:
	var values:=Values.initial_state("",1301,"builders")
	for axis:String in Values.VALUE_ORDER:values.lived[axis]=.5
	values.lived.centralization=order;values.lived.hierarchy=order
	for axis:String in ["openness","experimentation","pluralism"]:values.lived[axis]=openness
	return values

func test_actual_lived_values_and_crafts_produce_distinct_bounded_finishes()->void:
	var known:=["clay_shaping","lime_mortar","mineral_pigment_preparation","pictographic_records"]
	var ordered:=Culture.capture(_values(.8,.3),known)
	var open:=Culture.capture(_values(.3,.8),known)
	assert_int(int(ordered.roof)).is_equal(3)
	assert_int(int(open.roof)).is_equal(2)
	assert_int(int(ordered.plaster)).is_equal(2)
	assert_int(int(open.plaster)).is_equal(4)
	assert_int(int(ordered.door)).is_equal(1)
	assert_int(int(open.door)).is_equal(2)
	assert_str(Culture.signature(ordered)).is_not_equal(Culture.signature(open))
	for profile:Dictionary in [ordered,open]:
		for key:String in Culture.LIMITS:assert_int(int(profile[key])).is_between(0,int(Culture.LIMITS[key]))

func test_culture_capture_is_read_only_and_ignores_immaterial_daily_drift()->void:
	var values:=_values(.71,.31);var before:=values.duplicate(true)
	var knowledge:=["clay_shaping","pictographic_records"]
	var profile:=Culture.capture(values,knowledge)
	assert_dict(values).is_equal(before)
	assert_array(knowledge).is_equal(["clay_shaping","pictographic_records"])
	values.lived.centralization+=.001;values.lived.hierarchy+=.001
	values["last_update_day"]=100000;values["history"]=[{"unrelated":42}]
	assert_dict(Culture.capture(values,knowledge)).is_equal(profile)
	knowledge.append("unrelated_discovery")
	assert_dict(Culture.capture(values,knowledge)).is_equal(profile)

func test_recorded_finish_survives_save_and_takes_precedence_over_current_culture()->void:
	var old:=Culture.capture(_values(.8,.3),["clay_shaping","lime_mortar","pictographic_records"])
	var current:=Culture.capture(_values(.3,.8),["clay_shaping","mineral_pigment_preparation","pictographic_records"])
	var plot:Dictionary={"material_family":"earth","form":"earthen_household","cultural_appearance":old,"seed":13,"created_day":30}
	var before:=plot.duplicate(true)
	var restored:Dictionary=JSON.parse_string(JSON.stringify(plot))
	assert_dict(Culture.for_plot(restored,current)).is_equal(old)
	assert_dict(plot).is_equal(before)
	assert_str(Culture.signature(Culture.for_plot(restored))).is_equal(Culture.signature(old))
	assert_dict(Culture.for_plot({"material_family":"earth"})).is_equal(Culture.neutral())
	assert_dict(Culture.for_plot({"material_family":"earth"},current)).is_equal(current)

func test_material_and_craft_gates_do_not_invent_plaster_or_painted_trim()->void:
	var no_crafts:=Culture.capture(_values(.8,.3),[])
	assert_int(int(no_crafts.plaster)).is_zero()
	assert_int(int(no_crafts.door)).is_equal(1) # sober founding timber/earth bands
	assert_int(int(no_crafts.decor)).is_zero()
	var finish:=Culture.capture(_values(.8,.3),["lime_mortar","mineral_pigment_preparation","pictographic_records"])
	var timber:=Culture.for_plot({"material_family":"timber","cultural_appearance":finish})
	assert_int(int(timber.plaster)).is_zero()
	assert_int(int(timber.roof)).is_equal(int(finish.roof))
	var tent:=Culture.for_plot({"material_family":"organic","form":"ridge_light_shelter","cultural_appearance":finish})
	assert_int(int(tent.decor)).is_zero()
	assert_dict(Culture.capture({},["lime_mortar"])).is_equal(Culture.neutral())

func test_actual_emblem_palette_is_stable_without_seed_or_date_style_randomness()->void:
	var values:=_values(.5,.5)
	var known:=["mineral_pigment_preparation"]
	var identity:={"field":"a96349","pattern":4,"symbol":8,"name":"Recorded people"}
	var profile:=Culture.capture(values,known,identity)
	assert_int(int(profile.roof)).is_equal(2)
	assert_int(int(profile.door)).is_equal(2)
	identity.name="Same people renamed";identity.symbol=2
	assert_dict(Culture.capture(values,known,identity)).is_equal(profile)
	var data:=Culture.custom_data({"material_family":"earth","cultural_appearance":profile})
	assert_float(data.r).is_equal(float(profile.roof))
	assert_float(data.g).is_equal(float(profile.plaster))
	assert_float(data.b).is_equal(float(profile.door))
	assert_float(data.a).is_equal(float(profile.decor))

func test_malformed_or_future_stamps_are_neutral_without_mutating_them()->void:
	var current:=Culture.capture(_values(.8,.3),["lime_mortar"])
	for invalid:Variant in [{"version":2,"roof":1},{"version":1,"roof":INF},{"version":1,"roof":-1},{"version":1,"door":1.5},{"version":1,"decor":"2"},"invalid"]:
		var plot:={"material_family":"earth","cultural_appearance":invalid}
		var before:=plot.duplicate(true)
		assert_dict(Culture.for_plot(plot,current)).is_equal(Culture.neutral())
		assert_dict(plot).is_equal(before)

func test_actual_founding_crests_use_all_four_roofs_independent_of_ink_brightness()->void:
	var fields:Array=preload("res://scripts/city_map_identity.gd").CREST_FIELDS
	var expected:=[2,3,1,3,2,3,4,3,4,3]
	var seen:Dictionary={}
	var values:=_values(.5,.5)
	for index in fields.size():
		var color:=Color(String(fields[index]))
		var identity:={"field":color,"pattern":index}
		var profile:=Culture.capture(values,[],identity)
		assert_int(int(profile.roof)).is_equal(int(expected[index]))
		seen[int(profile.roof)]=true
		identity.field=color.darkened(.7)
		assert_dict(Culture.capture(values,[],identity)).is_equal(profile)
		identity.field=Color.from_hsv(color.h,color.s,.95)
		assert_dict(Culture.capture(values,[],identity)).is_equal(profile)
	assert_int(seen.size()).is_equal(4)
