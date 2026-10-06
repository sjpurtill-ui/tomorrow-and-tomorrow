extends GdUnitTestSuite
const ERA=preload("res://scripts/settlement_country_era.gd")

func _plot(generation:int=10)->Dictionary:
	return {"id":17,"land_use":"residential_compound","status":"active","construction_progress":1.0,"fabric_generation":generation,"storeys":8,"material_family":"stone","polygon":PackedVector2Array([Vector2(0.1,0),Vector2(0,0.2),Vector2(-0.1,0)])}

func test_knowledge_and_calendar_do_not_create_completed_modern_homes()->void:
	var plot:=_plot(0)
	plot["founded_day"]=0;plot["elapsed_days"]=3000*365
	var before:=ERA.capture([],{},[plot])
	var after:=ERA.capture(["structural_steel","reinforced_concrete","safety_lifts"],{},[plot])
	assert_int(ERA.signature(after)).is_equal(ERA.signature(before))
	assert_float(after.late_share).is_equal(0.0)
	assert_str(ERA.home(after,"same_farm").kind).is_equal("rooted_lean_to")

func test_completed_mix_retains_older_homes_and_stable_appearance()->void:
	var profile:=ERA.capture([],{"homes":[0.0,0.0,0.0,0.0,1.0]},[_plot(0),_plot(12)])
	assert_float(profile.late_share).is_equal(0.5)
	var modern:=0;var inherited:=0
	for index in 100:
		var id:="farm_%d" % index
		var descriptor:=ERA.home(profile,id)
		assert_dict(ERA.home(profile,id)).is_equal(descriptor)
		if descriptor.kind=="modern_villa":modern+=1
		if descriptor.kind=="rubble_household":inherited+=1
	assert_int(modern).is_greater(20)
	assert_int(inherited).is_greater(20)

func test_paid_roof_and_completed_status_are_preserved()->void:
	var plain:=_plot()
	var tiled:=_plot();tiled.roof_plan="fired_tile_roof"
	assert_str(ERA.home(ERA.capture([],{},[plain]),"farm").material).is_equal("stone|timber")
	assert_str(ERA.home(ERA.capture([],{},[tiled]),"farm").material).is_equal("stone|tile")
	for status in ["under_construction","ruin","reclaimed","vacant"]:
		var unavailable:=_plot(12);unavailable.status=status
		assert_float(ERA.capture([],{},[unavailable]).late_share).is_equal(0.0)
	var unfinished:=_plot(12);unfinished.construction_progress=0.4
	assert_float(ERA.capture([],{},[unfinished]).late_share).is_equal(0.0)

func test_known_or_unverified_methods_are_not_installed_features()->void:
	var plot:=_plot()
	plot.fabric_components={"timber_post_beam_connections":{"state":"accepted"}}
	var descriptor:=ERA.home(ERA.capture(["timber_post_beam_connections","building_shading_design"],{},[plot]),"farm")
	assert_int(descriptor.features).is_equal(0)
	assert_str(descriptor.kind).is_equal("masonry_villa")
	var learned:=ERA.home(ERA.capture(["wall_chimneys"],{},[plot]),"farm")
	assert_str(learned.material).is_equal("stone|timber")
	plot.building_materials={"applied":["wall_chimneys"]}
	var installed:=ERA.home(ERA.capture([],{},[plot]),"farm")
	assert_str(installed.material).is_equal("stone|timber_chimney")

func test_existing_kits_are_small_low_rise_and_props_are_bounded()->void:
	for generation in [4,10,11,12]:
		var descriptor:=ERA.home(ERA.capture([],{},[_plot(generation)]),"farm")
		assert_int(descriptor.storeys).is_equal(2)
		var bounds:=ERA.mesh(descriptor).get_aabb()
		assert_float(bounds.size.x).is_less(12.0)
		assert_float(bounds.size.y).is_less(10.0)
		assert_float(bounds.size.z).is_less(12.0)
		assert_int(descriptor.props.size()).is_less_equal(ERA.MAX_PROPS)
		for prop:String in descriptor.props:assert_bool(prop in ["woodpile","timber_stack","baskets"]).is_true()

func test_craft_props_require_their_real_knowledge()->void:
	var basic:=ERA.capture([],{},[])
	assert_array(basic.props).is_equal(["woodpile"])
	var learned:=ERA.capture(["spoked_wheel_assembly","grain_grinding","lined_well_shafts"],{},[])
	assert_bool("cart" in learned.props and "quern" in learned.props and "well" in learned.props).is_true()
	assert_bool("cart" in ERA.capture(["solid_wheel_assembly"],{},[]).props).is_false()
	for index in 30:assert_int(ERA.home(learned,str(index)).props.size()).is_less_equal(3)

func test_snapshot_is_bounded_pure_and_shares_the_town_polygon_extent()->void:
	var plots:Array=[]
	for index in ERA.MAX_PLOTS+20:plots.append(_plot(12))
	plots[0].polygon=PackedVector2Array([Vector2(3,4)])
	plots[ERA.MAX_PLOTS].polygon=PackedVector2Array([Vector2(90,90)])
	var fabric:={"homes":[0.1,0.2,0.3,0.2,0.2],"effects":{"roads":0.61}}
	var before_plots:=plots.duplicate(true);var before_fabric:=fabric.duplicate(true)
	var profile:=ERA.capture([],fabric,plots)
	assert_array(plots).is_equal(before_plots)
	assert_dict(fabric).is_equal(before_fabric)
	assert_int(profile.sampled_plots).is_equal(ERA.MAX_PLOTS)
	assert_float(profile.plot_radius_km).is_equal(5.0)
	assert_float(profile.road_quality).is_equal(0.6)
	assert_int(profile.variants.size()).is_less_equal(ERA.MAX_VARIANTS)
	var sig:=ERA.signature(profile)
	profile.plot_radius_km=8.0;profile.completed_residential=999
	assert_int(ERA.signature(profile)).is_equal(sig)
	var draw:=ERA.render_profile(profile);draw.variants[0].material="changed"
	assert_int(ERA.signature(profile)).is_equal(sig)

func test_presentation_signature_changes_for_real_completed_fabric()->void:
	var before:=ERA.capture([],{},[_plot(10)])
	var after:=ERA.capture([],{},[_plot(12)])
	assert_bool(ERA.signature(before)!=ERA.signature(after)).is_true()
	assert_int(ERA.signature(ERA.capture(["alphabetic_writing"],{},[_plot(10)]))).is_equal(ERA.signature(before))

func test_small_completed_share_changes_keep_the_same_palette_order()->void:
	var plots:Array=[]
	for index in 100:plots.append(_plot(10 if index<49 else 12))
	var before:=ERA.capture([],{},plots)
	plots[49]=_plot(10);plots[50]=_plot(10)
	var after:=ERA.capture([],{},plots)
	assert_int(ERA.signature(after)).is_equal(ERA.signature(before))
	for index in 20:assert_dict(ERA.home(after,str(index))).is_equal(ERA.home(before,str(index)))
