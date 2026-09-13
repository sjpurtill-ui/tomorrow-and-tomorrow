extends GdUnitTestSuite
const B=preload("res://scripts/field_botany.gd")
const K=preload("res://scripts/field_botany_knowledge.gd")
func knowledge()->Array:
	var result:Array=[]
	for entry:Dictionary in K.entries():result.append(entry.id)
	return result
func test_two_generations_require_paid_observation_days()->void:
	var ledger:=B.empty_state()
	assert_float(B.retain_seed(ledger,100.0,"home",0)).is_equal(1.0)
	assert_bool(B.sow_trial(ledger,0,"home",0)).is_true()
	var used_water:=0.0
	var used_work:=0.0
	for day:int in range(1,91):
		var report:=B.observe(ledger,day,"home",knowledge(),1.0,1.0,.5)
		used_water+=float(report.water);used_work+=float(report.work)
		assert_int(int(B.observe(ledger,day,"home",knowledge(),1.0,1.0,.5).completed)).is_equal(0)
	assert_float(used_water).is_equal_approx(27.0,.001)
	assert_float(used_work).is_equal_approx(9.0,.001)
	assert_int(ledger.lines.size()).is_equal(2)
	assert_bool(ledger.vouchers[0].qualified).is_false()
	assert_bool(B.sow_trial(ledger,1,"home",90)).is_true()
	for day:int in range(91,181):B.observe(ledger,day,"home",knowledge(),1.0,1.0,.5)
	assert_bool(ledger.vouchers[1].qualified).is_true()
	assert_int(ledger.lines[2].generation).is_equal(2)
	assert_bool(B.valid(ledger)).is_true()
func test_missing_resources_and_wrong_site_do_not_advance_cohort()->void:
	var ledger:=B.empty_state()
	B.retain_seed(ledger,100.0,"home",0)
	B.sow_trial(ledger,0,"home",0)
	B.observe(ledger,1,"away",knowledge(),1.0,1.0,.5)
	B.observe(ledger,2,"home",knowledge(),0.0,1.0,.5)
	B.observe(ledger,3,"home",knowledge(),1.0,0.0,.5)
	assert_int(ledger.trials[0].age).is_equal(0)
	B.observe(ledger,181,"home",knowledge(),1.0,1.0,.5)
	assert_int(ledger.trials.size()).is_equal(0)
	assert_int(ledger.lines.size()).is_equal(1)
func test_quote_expires_and_never_mutates_or_awards_future_success()->void:
	var ledger:=B.empty_state()
	ledger.applications.append({"site":"home","until":30,"area":.1,"response":.5})
	var before:=ledger.duplicate(true)
	assert_float(B.application_quote(ledger,"home",29,100,.5)).is_greater(0)
	assert_float(B.application_quote(ledger,"home",30,100,.5)).is_equal(0.0)
	assert_float(B.application_quote(ledger,"away",29,100,.5)).is_equal(0.0)
	assert_dict(ledger).is_equal(before)
