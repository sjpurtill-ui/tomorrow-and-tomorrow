extends GdUnitTestSuite
## ORDERS BY OFFICE (court_office_orders.gd, hud/audience_modal.gd): the
## official before the god offers their own business as a few plain choices,
## each at most one blank, and a choice goes to the court as if spoken.
## - every choice of every office reaches a real mechanic (home_orders.gd,
##   realm_orders.gd, court_war_orders.gd, an embassy or a party), never a
##   vague standing order;
## - an office's business falls to the Headman while the office is vacant;
## - on the court screen the war chief's orders are there, and "Raise a levy:
##   5 fighters" really calls up five and puts them to drill.
## Offline; never calls a real API.

const Harness:=preload("res://tests/court_eval/harness.gd")
const OfficeOrders:=preload("res://scripts/court_office_orders.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const CC:=preload("res://scripts/court_commands.gd")

var h:Harness


func before()->void:
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)
	h=Harness.new(self)


func after()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0


## The words of every choice in every family, as the Headman of a court with
## every office vacant would see them.
func _all_choices()->Array:
	var out:Array=[]
	for family in [OfficeOrders._war(),OfficeOrders._stores(),OfficeOrders._town(),OfficeOrders._scouting(),OfficeOrders._learning()]:
		for menu:Dictionary in family:
			if menu.has("items"):
				for item:Dictionary in menu.items: out.append(String(item.text))
			else: out.append(String(menu.text))
	return out


func test_every_choice_reaches_a_real_mechanic()->void:
	var w:=h.fx.use("home_peace")
	assert_bool(w.has("error")).is_false()
	var choices:=_all_choices()
	assert_int(choices.size()).is_greater(40)
	for text in choices:
		var home:=HomeOrders.read(String(text))
		var war:=WarOrders.read(String(text),"")
		var covert:=preload("res://scripts/covert_orders.gd").read(String(text),"")
		var heard:=CC.classify(String(text))
		var engine:=not home.is_empty() or not war.is_empty() or not covert.is_empty() or String(heard.get("verb","")) in ["send","war"]
		assert_bool(engine).override_failure_message("'%s' reaches no mechanic: home %s, war %s, covert %s, verb %s" % [text,str(home),str(war),str(covert),String(heard.get("verb",""))]).is_true()


func test_a_vacant_office_falls_to_the_headman()->void:
	var w:=h.fx.use("home_peace")
	assert_bool(w.has("error")).is_false()
	var families:=OfficeOrders.families("Steward")
	assert_bool(families.has("town")).is_true()
	# This early court has no Scholar: the Headman answers for learning.
	if (GovernmentPeopleSystem.officeholder("Scholar") as Dictionary).is_empty(): assert_bool(families.has("learning")).is_true()
	# The war chief holds office: war is theirs, not the Headman's.
	if not (GovernmentPeopleSystem.officeholder("Marshal") as Dictionary).is_empty(): assert_bool(families.has("war")).is_false()
	assert_array(OfficeOrders.families("Marshal")).is_equal(["war"])


func test_the_war_chiefs_orders_on_the_court_screen_raise_a_levy()->void:
	var w:=h.fx.use("home_peace")
	assert_bool(w.has("error")).is_false()
	GameState.civic_api_enabled=false
	var voice:=Harness.RecordingVoice.new()
	voice.force_offline=true
	add_child(voice)
	var id:=h.fx.audience_for(w,"suri")
	assert_str(id).is_not_empty()
	var modal:Control=Harness.Modal.new()
	modal.voice=voice; modal.audience_id=id
	add_child(modal)
	await await_idle_frame()
	voice.drain(id)
	modal._build_options()
	var row:Control=modal.find_child("OrdersRow",true,false)
	assert_object(row).is_not_null()
	assert_bool(row.visible).is_true()
	assert_object(row.find_child("Order_RaiseLevy",true,false)).is_not_null()
	assert_object(row.find_child("Order_Drill",true,false)).is_not_null()
	var drilling:=MilitaryCampaign.training_queue.size()
	var heard:Dictionary=modal.office_order("Recruit 5 levies, train them and arm them")
	assert_bool(bool(heard.get("handled",false))).is_true()
	assert_int(MilitaryCampaign.training_queue.size()).is_equal(drilling+1)
	assert_int(int((MilitaryCampaign.training_queue.back() as Dictionary).count)).is_equal(5)
	modal.queue_free(); voice.queue_free()


func test_words_the_court_cannot_carry_out_offer_the_closest_orders()->void:
	var w:=h.fx.use("home_peace")
	assert_bool(w.has("error")).is_false()
	var near:=OfficeOrders.closest("gather some fighters and give them spears",3)
	assert_bool(near.is_empty()).is_false()
	var texts:=near.map(func(c:Dictionary)->String: return String(c.text))
	assert_bool(texts.any(func(t:String)->bool: return t.begins_with("Recruit") or "spears" in t)).override_failure_message(str(texts)).is_true()
	# Talk, and a feast (a real order with no office button), offer nothing.
	assert_array(OfficeOrders.closest("I am pleased with you",3)).is_empty()
	assert_array(OfficeOrders.closest("Hold a feast for everyone",3)).is_empty()
