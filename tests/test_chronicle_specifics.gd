extends GdUnitTestSuite
## Round two of the Chronicle: recurring lines told from real facts
## (chronicle_specifics.gd), one finding told once across sources
## (chronicle_annals.gd), and the optional live rewrite of a finished year
## (chronicle_polish.gd), which never invents and never blocks.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")
const Specifics:=preload("res://scripts/chronicle_specifics.gd")
const Polish:=preload("res://scripts/chronicle_polish.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	ForeignDiplomacy.ensure();ForeignDiplomacy.audiences.erase("lives")
	Chronicle.pending_cards.clear()
	GameState.chronicle={}
	Polish.send_hook=Callable();Polish.config_override={};Polish.force_offline=false


func after_test()->void:
	Polish.send_hook=Callable();Polish.config_override={};Polish.force_offline=false


func _at(day:int)->void:
	GameState.elapsed_days=float(day)
	Chronicle.ingest_day({"discoveries":[],"progression":[]})


func _told(key:String)->Dictionary:
	for e in GameState.chronicle.get("entries",[]):
		if String(e.get("key",""))==key:return e
	return {}


# --- Crises ---------------------------------------------------------------------

func test_a_sickness_ending_tells_who_where_what_was_tried_and_how_it_compares()->void:
	var text:=Specifics.crisis_end({"type":"sickness","name":"the Coughing Winter of year 47","days":55,"sick":9,"where":"at the east fire","deaths":1,
		"dead":["Ashti, an old woman"],"choice":"tend","mid_choice":"children_apart","helper":"Oru of the Ford","prior":{"year":46,"deaths":0,"choice":"tend"},"seed":7})
	assert_str(text).contains("nine")
	assert_str(text).contains("at the east fire")
	assert_str(text).contains("Ashti, an old woman")
	assert_str(text).contains("took one")
	# The same answer as last time is told against last time's cost.
	assert_str(text).contains("Everyone tended the sick, as in year 46, when no one died; this time it went worse.")
	assert_str(text).contains("children were kept away")
	assert_str(text).contains("Oru of the Ford")
	# A different sickness reads differently because it was different.
	var other:=Specifics.crisis_end({"type":"sickness","name":"the Summer Flux of year 48","days":30,"sick":5,"where":"at the fires by the water","deaths":0,
		"choice":"apart","prior":{"year":47,"deaths":1,"choice":"tend"},"seed":8})
	assert_str(other).contains("no one died")
	assert_str(other).contains("In year 47 everyone tended the sick and one died; this time the sick were kept apart")
	assert_str(other).is_not_equal(text)


func test_the_same_answer_sickness_after_sickness_is_counted_not_retold()->void:
	var text:=Specifics.crisis_end({"type":"sickness","name":"the Summer Flux of year 59","days":60,"sick":9,"where":"at the east fire","deaths":1,"dead":["Ulim, an old man"],
		"choice":"tend","prior":{"year":59,"deaths":0,"choice":"tend"},"year":59,"run":11,"run_deaths":4,"since":46,"seed":3})
	assert_str(text).not_contains("took turns sitting")
	assert_str(text).contains("year 46")
	assert_bool("eleven" in text or "eleventh" in text or "last ten" in text).is_true()
	assert_str(text).contains("four have died of them")


func test_twenty_seven_mild_sicknesses_do_not_read_alike()->void:
	var places:=["at the east fire","at the fires by the water","in the huts nearest the midden","among the families at the edge of camp","at the hearths by the drying racks","among the old ones' hearths"]
	var sentences:={}
	var total:=0
	var prior:={}
	for i in 27:
		var deaths:=1 if i%5==0 else 0
		var f:={"type":"sickness","name":"the %s of year %d" % [["Coughing Winter","Summer Flux","Shaking Fever"][i%3],30+i],"days":42+(i*7)%40,"sick":4+(i*5)%9,
			"where":places[(i*7)%places.size()],"deaths":deaths,"dead":["Ama, a girl"] if deaths>0 else [],"choice":"tend","prior":prior,"seed":hash("c%d" % i),"helper":"Helper%d of the Ford" % i,"year":30+i,"run":i+1,"run_deaths":(i+4)/5,"since":30}
		for s in Specifics.crisis_end(f).split(". "):
			var key:=s.strip_edges()
			if key.length()<16:continue
			sentences[key]=int(sentences.get(key,0))+1;total+=1
		prior={"year":30+i,"deaths":deaths,"choice":"tend"}
	var repeated:=0
	for k in sentences:
		if int(sentences[k])>1:repeated+=int(sentences[k])
	assert_float(float(repeated)/float(total)).is_less(0.35)


# --- Aims -----------------------------------------------------------------------

func test_an_aim_milestone_says_how_far_in_what_against_its_winters_and_who_counts()->void:
	var behind:Array=Specifics.aim_mark({"title":"Learn 95 New Ways in Eight Winters","template":"knowledge","mark":25,"value":"24 new ways of 95","keeper":"Esru",
		"used":3,"left":5,"pace":"behind","latest":["Relay calls between camps","Clean-water practice"],"seed":1})
	assert_bool("Late" in String(behind[0]) or "Behind" in String(behind[0])).is_true()
	assert_str(String(behind[1])).contains("24 new ways of 95")
	assert_str(String(behind[1])).contains("three winters")
	assert_str(String(behind[1])).contains("relay calls between camps and clean-water practice")
	assert_str(String(behind[1])).contains("Esru")
	var ahead:Array=Specifics.aim_mark({"title":"Master Healing","template":"learn","mark":50,"value":"two new ways of four","keeper":"Liora","used":1,"left":6,"pace":"ahead","seed":2})
	assert_str(String(ahead[0])).is_not_equal("Master Healing: Halfway")
	assert_str(String(ahead[1])).contains("two new ways of four")
	assert_str(String(ahead[1])).not_contains("People point at it")


# --- Successions ----------------------------------------------------------------

func test_a_succession_names_the_kin_ages_and_counts_the_gods_silence()->void:
	var first:Array=Specifics.succession({"dead":"Namar","successor":"Zeva the Quiet","given":"Zeva","kin":"child","office":"Pathfinder","age":31,"dead_age":65,"served":7,"skill":"talked down angry men","unnamed":0,"seed":0})
	assert_str(String(first[1])).contains("Zeva the Quiet, Namar's child,")
	assert_str(String(first[1])).contains("young for it")
	assert_str(String(first[1])).contains("The god has named no one")
	var fourth:Array=Specifics.succession({"dead":"Tomaq","successor":"Imeri of Windgap","given":"Imeri","office":"First Elder","age":45,"dead_age":60,"served":11,"skill":"kept the young spears ready","unnamed":3,"seed":5})
	assert_str(String(fourth[1])).not_contains("The god has named no one; the people take this as the god's leave.")
	assert_bool("fourth" in String(fourth[1]) or "four deaths" in String(fourth[1])).is_true()
	assert_str(String(fourth[1])).contains("eleven winters")


# --- One finding, told once -----------------------------------------------------

func test_a_beat_replaces_the_scout_report_of_the_same_find()->void:
	_at(3812)
	var scout:=Chronicle.record({"key":"ev|3812|SCOUTS RETURN","title":"The scouts met strangers","text":"We found a butchered carcass and a cache of dried meat, hidden with care by people who are not ours. Their trail runs west. They were gone 180 days and walked some 520 km.","tier":"notice","kind":"scout"})
	assert_str(String(scout.tier)).is_equal("notice")
	_at(3813)
	var beat:=Chronicle.record({"key":"beat:opening_first_signs_3813","title":"A strangers' camp","text":"We found a butchered carcass and a cache of dried meat, hidden with care by people who are not ours. Their trail runs west.","tier":"moment","kind":"story","priority":true})
	assert_str(String(beat.tier)).is_equal("moment")
	assert_str(String(_told("ev|3812|SCOUTS RETURN").tier)).is_equal("whisper")


func test_a_second_source_keeps_only_what_is_new()->void:
	_at(5354)
	Chronicle.record({"key":"ev|5354|Directive Issued","title":"Directive Issued","text":"Health improves while care duties reduce effective labor.","tier":"notice","kind":"court"})
	var done:=Chronicle.record({"key":"ev|5354|Directive Implemented","title":"Directive Implemented","text":"Health improves while care duties reduce effective labor. Implementation is narrow; little open resistance is yet visible.","tier":"notice","kind":"court"})
	assert_str(String(done.text)).is_equal("Implementation is narrow; little open resistance is yet visible.")


func test_the_same_words_years_later_step_back()->void:
	_at(3544)
	var first:=Chronicle.record({"key":"ev|3544|The Land Is Thinning","title":"The Land Is Thinning","text":"Gatherers report longer journeys and diminishing returns near the settlement.","tier":"notice","kind":"omen"})
	_at(8507)
	var again:=Chronicle.record({"key":"ev|8507|The Land Is Thinning","title":"The Land Is Thinning","text":"Gatherers report longer journeys and diminishing returns near the settlement.","tier":"notice","kind":"omen"})
	assert_str(String(first.tier)).is_equal("notice")
	assert_str(String(again.tier)).is_equal("whisper")


# --- The live rewrite -----------------------------------------------------------

func _year_with_news()->void:
	GameState.population_total=120
	_at(0)
	_at(1)
	(Annals.acc(Chronicle.data()) as Dictionary).pop0=120
	Chronicle.record({"key":"court:death:person:7","title":"Hadra of Fernside Is Dead","text":"Hadra of Fernside died aged 68. They brought strangers to our fire without blood.","tier":"notice","kind":"death"})
	Annals.note_learned(Chronicle.data(),"Thorn barriers",150)
	GameState.population_total=114


func _body(text:String)->String:
	return JSON.stringify({"choices":[{"message":{"content":JSON.stringify({"text":text})},"finish_reason":"stop"}]})


func test_offline_the_year_stays_as_written_and_nothing_is_sent()->void:
	var sent:=[]
	Polish.force_offline=true
	Polish.send_hook=func(year:String,_p:Dictionary)->void:sent.append(year)
	_year_with_news()
	_at(366)
	assert_int(sent.size()).is_equal(0)
	assert_bool(bool(_told("annal:0").get("polished",false))).is_false()


func test_online_a_year_is_rewritten_once_and_only_from_its_facts()->void:
	var sent:=[]
	Polish.config_override={"endpoint":"http://mock.invalid","api_key":"test","model":"gpt-6-luna"}
	Polish.send_hook=func(year:String,payload:Dictionary)->void:sent.append([year,payload])
	_year_with_news()
	_at(366)
	assert_int(sent.size()).is_equal(1)
	assert_str(String(sent[0][0])).is_equal("1")
	var draft:=String(_told("annal:0").text)
	# The game did not wait: the entry is already told in its own words.
	assert_str(draft).contains("Hadra of Fernside, at 68")
	var good:="Hadra of Fernside died this year, at 68. The people learned thorn barriers, and there were 114 people in the registers, 6 fewer than a year before."
	assert_bool(Polish.receive("1",_body(good))).is_true()
	assert_str(String(_told("annal:0").text)).is_equal(good)
	assert_str(String(_told("annal:0").draft_text)).is_equal(draft)
	# Asked once: later days never send it again.
	_at(400)
	assert_int(sent.size()).is_equal(1)
	assert_bool(Polish.receive("1",_body(good))).is_false()


func test_an_answer_that_invents_a_name_or_a_number_is_refused()->void:
	Polish.config_override={"endpoint":"http://mock.invalid","api_key":"test","model":"gpt-6-luna"}
	Polish.send_hook=func(_y:String,_p:Dictionary)->void:pass
	_year_with_news()
	_at(366)
	var draft:=String(_told("annal:0").text)
	var invented:="Hadra of Fernside died this year, at 68, mourned by Bralla. The people learned thorn barriers, and there were 114 people in the registers."
	assert_bool(Polish.receive("1",_body(invented))).is_false()
	assert_str(String(_told("annal:0").text)).is_equal(draft)
	assert_str(String((GameState.chronicle.polish as Dictionary)["1"].status)).is_equal("fallback")
	assert_str(Polish.validate(draft,"",{},"Hadra of Fernside died at 71. The people learned thorn barriers and there were 114 people in the registers.")).contains("number")
	assert_str(Polish.validate(draft,"",{},"Hadra of Fernside died at 68; a great plague of bronze swords and iron ploughs followed across the seven kingdoms of the east.")).is_not_empty()


func test_tests_and_probes_never_reach_the_live_service()->void:
	# Outside the player's game (tests, probes, headless simulations) the live
	# rewrite stays off even when a key is configured on this machine.
	var sent:=[]
	Polish.send_hook=func(year:String,_p:Dictionary)->void:sent.append(year)
	_year_with_news()
	_at(366)
	assert_int(sent.size()).is_equal(0)
