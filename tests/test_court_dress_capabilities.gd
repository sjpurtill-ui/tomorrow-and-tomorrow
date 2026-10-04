extends GdUnitTestSuite
const Presentation:=preload("res://scripts/hud/court_presentation.gd")
const Look:=preload("res://scripts/hud/court_figure_look.gd")

func _look(seed_value:=27)->Dictionary:
	return {"seed":seed_value,"variant":"female_adult","outfit":"robe","hair":"braids","skin":Color("9f6a43"),
		"face":{"jaw":0.2},"cloth":[Color("a8432f"),Color("2f4a6e"),Color("c9a43c")],"without":[]}

func test_administrative_knowledge_does_not_invent_textiles_or_fitted_cuts()->void:
	var offices:=["national_income_accounts","labor_ministry"]
	var administrative:=Presentation.from_knowledge(offices)
	assert_str(String(administrative.period)).is_equal("modern")
	assert_str(String(administrative.outfit)).is_equal("hide")
	assert_str(String(administrative.routine_greeting)).is_equal("nod")
	var woven:=Presentation.from_knowledge(offices+["plain_weaving"])
	assert_array(woven.dress_options).contains_exactly_in_any_order(["tunic","robe"])
	var fitted:=Presentation.from_knowledge(offices+["fitted_tailoring"])
	assert_array(fitted.dress_options).contains_exactly(["business"])

func test_early_medieval_institutions_use_layered_cloth_before_the_fitted_cut()->void:
	var practices:=["homage_commendation","household_great_offices","plain_weaving"]
	var before:=Presentation.from_knowledge(practices)
	assert_str(String(before.period)).is_equal("medieval")
	assert_str(String(before.outfit)).is_equal("tunic")
	assert_str(String(before.dress_code)).is_equal("layered")
	var after:=Presentation.from_knowledge(practices+["fitted_tailoring"])
	assert_str(String(after.outfit)).is_equal("medieval")
	assert_str(String(after.routine_greeting)).is_equal(String(before.routine_greeting))

func test_simple_and_formal_roles_share_an_era_without_identical_robes()->void:
	var profile:=Presentation.from_knowledge(["temple_high_steward","pictographic_records","plain_weaving"])
	var source:=_look();var before:=source.duplicate(true)
	var clerk:=Look.dress(source,profile,false)
	var officer:=Look.dress(source,profile,true)
	assert_str(String(clerk.outfit)).is_equal("tunic")
	assert_str(String(officer.outfit)).is_equal("robe")
	assert_dict(source).is_equal(before)
	for key in ["face","hair","skin","seed","variant"]:assert_that(clerk[key]).is_equal(source[key])

func test_colour_needs_actual_dye_practice_and_keeps_the_peoples_palette()->void:
	var source:=_look()
	var raw:=Presentation.from_knowledge(["plain_weaving"])
	var simple:=Presentation.from_knowledge(["plain_weaving","textile_dye_extraction"])
	var established:=Presentation.from_knowledge(["plain_weaving","alum_mordant_dyeing"])
	assert_int(int(raw.dye_level)).is_equal(0)
	assert_int(int(simple.dye_level)).is_equal(1)
	assert_int(int(established.dye_level)).is_equal(2)
	assert_array(Look.dress(source,raw).cloth).is_not_equal(source.cloth)
	assert_array(Look.dress(source,established).cloth).is_equal(source.cloth)

func test_business_variation_is_stable_supported_and_preserves_identity()->void:
	var profile:=Presentation.from_knowledge(["national_income_accounts","labor_ministry","fitted_tailoring","alum_mordant_dyeing"])
	var coats:Dictionary={};var details:Dictionary={}
	for seed_value in [128,144,256,272,384,400]:
		var source:=_look(seed_value)
		var dressed:=Look.dress(source,profile,true)
		assert_dict(Look.dress(source,profile,true)).is_equal(dressed)
		assert_str(String(dressed.outfit)).is_equal("business")
		assert_dict(dressed.face).is_equal(source.face)
		assert_that(dressed.cloth[2]).is_equal(source.cloth[2])
		coats[str(dressed.cloth[0])]=true;details[str(dressed.without)]=true
	assert_int(coats.size()).is_greater(1)
	assert_int(details.size()).is_equal(2)
