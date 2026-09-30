extends GdUnitTestSuite
## How a party was received (chief_scout.gd _reception). A recruitment party's
## account keeps the answer's words and severity side by side; reading it as
## one dictionary failed at every return ("Trying to assign value of type
## 'String' to a variable of type 'Dictionary'") and a hostile answer never
## reached the report.
const Scout:=preload("res://scripts/chief_scout.gd")

func _reception(account:Dictionary)->Dictionary:
	var event:={"source":"scouts","mission_id":"m1","day":10,"recruitment_account":account}
	return Scout._reception(event,"scouts","")

func test_a_hostile_answer_is_reported_in_its_own_words()->void:
	var fact:=_reception({"diplomatic_response":"They set their dogs on us.","diplomatic_severity":"hostile"})
	assert_str(String(fact.get("label",""))).is_equal("hostile")
	assert_str(String(fact.get("text",""))).is_equal("They set their dogs on us.")
	# Words left blank still say what happened.
	assert_str(String(_reception({"diplomatic_response":"","diplomatic_severity":"hostile"}).get("text",""))).is_equal("They answered the visit with open hostility.")

func test_older_records_and_quiet_answers_read_cleanly()->void:
	var old:=_reception({"diplomatic_response":{"severity":"hostile","message":"Spears at the ford."}})
	assert_str(String(old.get("text",""))).is_equal("Spears at the ford.")
	assert_bool(_reception({"diplomatic_response":"","diplomatic_severity":""}).is_empty()).is_true()
	assert_bool(_reception({}).is_empty()).is_true()
