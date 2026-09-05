extends GdUnitTestSuite
const MODEL=preload("res://scripts/occupation_governance.gd")
func region()->Dictionary:
	return {"population":1000.0,"damage":.2,"resistance":.5,"integration":.1}
func months(value:Dictionary,count:int)->Dictionary:
	var result:=value.duplicate(true)
	for _month in count: result=MODEL.advance(result,1.0,.9,true)
	return result
func test_coercion_has_lasting_costs_and_reform_does_not_erase_them()->void:
	var harsh:Dictionary=MODEL.change(region(),"forced_labor",0).region
	harsh=months(harsh,300)
	var fair:Dictionary=MODEL.change(region(),"equal_citizenship",0).region
	fair=months(fair,300)
	assert_float(float(harsh.governance.grievance)).is_greater(float(fair.governance.grievance))
	assert_float(float(harsh.governance.welfare)).is_less(float(fair.governance.welfare))
	assert_float(float(harsh.governance.inherited_grievance)).is_greater(.3)
	var reformed:Dictionary=MODEL.change(harsh,"equal_citizenship",9000).region
	assert_float(float(reformed.governance.inherited_grievance)).is_equal(float(harsh.governance.inherited_grievance))
	assert_float(float(reformed.population)).is_equal(1000.0)
	assert_array(MODEL.validate(months(reformed,300))).is_empty()
func test_razing_does_not_remove_people_or_magically_repair()->void:
	var ruins:Dictionary=MODEL.change(region(),"raze",0).region
	ruins=months(ruins,100)
	assert_float(float(ruins.damage)).is_equal(1.0)
	assert_float(float(ruins.population)).is_equal(1000.0)
	var repair:Dictionary=MODEL.change(ruins,"reconstruct",3000).region
	repair=months(repair,10)
	assert_float(float(repair.damage)).is_less(1)
	assert_float(float(repair.population)).is_equal(1000.0)
func test_cooldown_invalid_orders_and_bounded_history()->void:
	var value:Dictionary=MODEL.change(region(),"self_rule",0).region
	assert_bool(MODEL.change(value,"raze",29).has("error")).is_true()
	assert_bool(MODEL.change(value,"unknown",30).has("error")).is_true()
	for step in 30: value=MODEL.change(value,"self_rule",(step+1)*30).region
	assert_int(value.governance.history.size()).is_equal(16)
	assert_array(MODEL.validate(value)).is_empty()
func test_json_preserves_all_social_conditions()->void:
	var value:=months(region(),20)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(value))
	for field:String in MODEL.FIELDS: assert_float(float(saved.governance[field])).is_equal_approx(float(value.governance[field]),.00000001)
	assert_str(String(saved.governance.policy)).is_equal(String(value.governance.policy))
	assert_int(int(saved.governance.months)).is_equal(int(value.governance.months))
	assert_array(MODEL.validate(saved)).is_empty()
func test_missing_supply_blocks_recovery()->void:
	var value:Dictionary=MODEL.change(region(),"equal_citizenship",0).region
	var supplied:=months(value,100)
	for _month in 100: value=MODEL.advance(value,0,0,true)
	assert_float(float(value.integration)).is_less(float(supplied.integration))
	assert_float(float(value.resistance)).is_greater(float(supplied.resistance))
