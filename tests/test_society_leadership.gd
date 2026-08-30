class_name SocietyLeadershipTest
extends GdUnitTestSuite

const SOCIETY_MODEL_SCRIPT:=preload("res://scripts/society_model.gd")

var model:RefCounted

func before_test()->void:
	GameState.reset_for_new_world(918273)
	model=auto_free(SOCIETY_MODEL_SCRIPT.new())

func _advisor(value:float)->Dictionary:
	var dynamics:Dictionary={}
	var subcategories:Dictionary={}
	for dynamic_id in SOCIETY_MODEL_SCRIPT.DYNAMICS:
		dynamics[dynamic_id]=value
		subcategories[dynamic_id]={}
	return {"name":"Test Advisor","dynamic_profile":dynamics,"subcategory_profile":subcategories}

func test_leadership_uses_exactly_the_twelve_canonical_dynamics()->void:
	assert_int(SOCIETY_MODEL_SCRIPT.DYNAMICS.size()).is_equal(12)
	assert_array(SOCIETY_MODEL_SCRIPT.DYNAMICS).contains_exactly([
		"demography","nutrition","health","labor","knowledge","production",
		"infrastructure","logistics","ecology","institutions","security","culture"
	])

func test_office_holder_only_influences_the_office_portfolio()->void:
	GameState.leadership_positions={"Steward":_advisor(0.90)}
	assert_float(model.leadership_effect("demography")).is_greater(0.0)
	assert_float(model.leadership_effect("health")).is_greater(0.0)
	assert_float(model.leadership_effect("security")).is_equal(0.0)
	assert_float(model.leadership_effect("production")).is_equal(0.0)

func test_subcategory_strength_changes_that_real_subcategory()->void:
	var advisor:=_advisor(0.50)
	advisor.subcategory_profile.health={"General health":0.92,"Water & sanitation":0.21}
	GameState.leadership_positions={"Steward":advisor}
	assert_float(model.leadership_subcategory_effect("health","General health")).is_greater(0.0)
	assert_float(model.leadership_subcategory_effect("health","Water & sanitation")).is_less(0.0)


func test_catalog_validation_rejects_dependency_cycles()->void:
	var cyclic_catalog:Array[Dictionary]=[
		{"id":"watch","requires":["drill"],"effects":{"warfare_readiness":0.01}},
		{"id":"drill","requires":["watch"],"effects":{"warfare_readiness":0.01}}
	]
	var errors:Array[String]=model.validate_catalog(cyclic_catalog)
	assert_bool(errors.any(func(message:String)->bool: return message.contains("dependency cycle"))).is_true()
