extends GdUnitTestSuite
## Round three of the year's telling (scripts/chronicle_years.gd): each year
## leads with what made it different, drops what only repeats last year,
## rotates its wordings, names the people involved, brings in word of other
## peoples and envoys, and every twenty years tells the generation.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")
const Years:=preload("res://scripts/chronicle_years.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	ForeignDiplomacy.ensure();ForeignDiplomacy.audiences.erase("lives")
	Chronicle.pending_cards.clear()
	GameState.chronicle={}


func _at(day:int)->void:
	GameState.elapsed_days=float(day)
	Chronicle.ingest_day({"discoveries":[],"progression":[]})


func _told(key:String)->Dictionary:
	for e in GameState.chronicle.get("entries",[]):
		if String(e.get("key",""))==key:return e
	return {}


func _crisis(id:String,day:int,name:String,end_text:String)->void:
	_at(day)
	Chronicle.record({"key":"crisis:%s:onset" % id,"title":"Sickness at the Fires","text":"Seven are down with a deep cough.","tier":"moment","kind":"omen","priority":true})
	_at(day+10)
	Chronicle.record({"key":"crisis:%s:silent:open" % id,"title":"Tomaq Acts Alone","text":"The god was silent. Tomaq acted alone.","tier":"notice","kind":"court"})
	_at(day+40)
	Chronicle.record({"key":"crisis:%s:end" % id,"title":"After "+name,"text":end_text+" The god was silent. Tomaq acted alone.","tier":"moment","kind":"ceremony"})


func _ctx(seed:int=1)->Dictionary:
	return {"seed":seed,"era":"tally","recent":{},"used":[],"regard":"","divine":[],"pop":0,"change":{}}


func test_the_year_leads_with_what_made_it_different()->void:
	var a:={"year":5,"pop0":0,"crises":[{"id":"c1","type":"sickness","short":"the Coughing Winter","deaths":0,"ended":true,"silent":true,"holder":"Tomaq"}],
		"deaths":[{"name":"Namar Wolf-Scarer","age":65,"great":true,"role":"pathfinder"}],"heads":["Zeva"],"learned":[],"scouts":{"n":0},"aims":[],"works":[],"contacts":[],"wars":[]}
	var annals:=[{"y":3,"crises":1,"deaths":0,"silent":1,"answered":0,"learned":2},{"y":4,"crises":1,"deaths":0,"silent":1,"answered":0,"learned":2}]
	var picked:=Years.entry(Years.items(a,annals,_ctx()))
	var lines:PackedStringArray=picked.lines
	assert_bool(lines.size()>=2).is_true()
	# A great death leads, not the routine deathless trouble.
	assert_str(lines[0]).contains("Namar Wolf-Scarer")
	assert_str(lines[0]).contains("65")
	assert_str(" ".join(lines)).contains("Zeva")


func test_a_line_that_only_repeats_last_year_is_dropped()->void:
	var calm:={"year":10,"pop0":0,"crises":[],"deaths":[],"heads":[],"learned":[],"scouts":{"n":0},"aims":[],"works":[],"contacts":[],"wars":[]}
	var annals:=[{"y":8,"crises":1,"deaths":0,"learned":1},{"y":9,"crises":0,"deaths":0,"learned":1,"sig":{"troubles":"calm"}}]
	var text:=" ".join(Years.entry(Years.items(calm,annals,_ctx())).lines)
	# Second calm year in a row: not a round count, not a record, not news.
	assert_str(text.to_lower()).not_contains("without sickness")
	assert_str(text.to_lower()).not_contains("no sickness")
	# A first calm year after deadly troubles is news, and says so.
	var after:=[{"y":8,"crises":0,"deaths":0},{"y":9,"crises":2,"deaths":3,"worst":"the Summer Flux"}]
	var told:=" ".join(Years.entry(Years.items(calm,after,_ctx())).lines)
	assert_bool("graves" in told or "cost three lives" in told).is_true()


func test_a_record_and_a_first_since_are_told_against_the_long_span()->void:
	var annals:Array=[]
	for y in 14:annals.append({"y":y,"crises":1,"deaths":1 if y!=2 else 3,"learned":1})
	var a:={"year":14,"pop0":0,"crises":[{"id":"c9","short":"the Shaking Fever","deaths":3,"ended":true,"dead":["Anzu, a grandfather","Ulim, a grandmother"]}],"deaths":[],"heads":[],"learned":[],"scouts":{"n":0},"aims":[],"works":[],"contacts":[],"wars":[]}
	var text:=" ".join(Years.entry(Years.items(a,annals,_ctx())).lines)
	assert_str(text).contains("Anzu, a grandfather")
	assert_str(text).contains("year 3")


func test_wordings_rotate_so_alike_years_read_differently()->void:
	var c:={}
	var texts:Array=[]
	var recent:={}
	var annals:Array=[]
	for y in 12:
		var a:={"year":y,"pop0":0,"crises":[{"id":"c%d" % y,"short":"the Coughing Winter","deaths":0,"ended":true,"silent":true,"holder":"Imeri","helper":"Sadu of the Ford"}],"deaths":[],"heads":[],
			"learned":[],"scouts":{"n":1,"km":400,"hurt":1,"back":0},"aims":[],"works":[],"contacts":[],"wars":[]}
		var ctx:=_ctx(y*7919)
		for m in annals.slice(maxi(0,annals.size()-Years.FRESH_YEARS)):
			for u in (m as Dictionary).get("used",[]):ctx.recent[String(u)]=true
		var picked:=Years.entry(Years.items(a,annals,ctx))
		texts.append(" ".join(picked.lines))
		annals.append({"y":y,"crises":1,"deaths":0,"silent":1,"answered":0,"learned":0,"used":ctx.used,"sig":picked.sig})
	var repeats:=0
	for i in range(1,texts.size()):
		assert_str(String(texts[i])).is_not_equal(String(texts[i-1]))
		if texts.slice(0,i).has(texts[i]):repeats+=1
	assert_int(repeats).is_less_equal(2)


func test_crisis_victims_and_the_helper_are_named_in_the_year()->void:
	_at(0)
	_crisis("c1",100,"The Summer Flux of year 1","The Summer Flux of year 1 has passed. It took two: Ulim, an old man; and Adu, a grandmother. Liora of the Red Cliff sat with the sick every night and never fell ill; the people remember it.")
	_at(366)
	var annal:=_told("annal:0")
	var text:=String(annal.text)
	assert_str(text).contains("Ulim, an old man")
	assert_str(text).contains("Liora of the Red Cliff")


func test_word_of_other_peoples_is_told_once_and_by_its_furthest_step()->void:
	_at(0)
	_at(30)
	Chronicle.record({"key":"aim:rival:known:civ_02:30","title":"What Hoya of Windgap Has Sworn","text":"Their messenger let it slip: Hoya of Windgap of the Ildor has sworn to bind us to them in friendship. They hold to the marriage.","tier":"notice","kind":"contact"})
	_at(200)
	Chronicle.record({"key":"aim:rival:warn:civ_02:30","title":"Hoya Is Close to the Vow","text":"Their vow is nearly kept: Hoya of Windgap of the Ildor is close to what they swore: to bind us to them in friendship. Every gift binds us closer.","tier":"notice","kind":"contact"})
	Chronicle.record({"key":"stale:famine:civ_01:200","title":"Word of the Esurai","text":"Travellers told of it: Esurai's granaries are failing. No envoy came to speak of it.","tier":"whisper","kind":"contact"})
	_at(366)
	var first:=String(_told("annal:0").text)
	assert_str(first).contains("close to what they swore")
	assert_str(first).not_contains("had sworn to bind")
	assert_str(first).contains("granaries are failing")
	# The same word a year later is not told again.
	Chronicle.record({"key":"stale:famine:civ_01:500","title":"Word of the Esurai","text":"Travellers told of it: Esurai's granaries are failing. No envoy came to speak of it.","tier":"whisper","kind":"contact"})
	_at(2*365+1)
	assert_str(String(_told("annal:1").text)).not_contains("granaries")


func test_a_turning_is_told_as_what_changed_daily_life()->void:
	_at(0)
	_at(40)
	Chronicle.record({"key":"turning:boats","title":"The First Boats","text":"Hides stretched over frames, and hollowed logs: the people go out on the water now. What changes: in a flood you can order the stores taken out by boat.","tier":"moment","kind":"discovery"})
	_at(366)
	var text:=String(_told("annal:0").text)
	assert_str(text).contains("the people go out on the water now")
	assert_str(text).not_contains("What changes")


func test_envoy_answers_are_told_in_the_third_person()->void:
	var loan:=Years.envoy_line("Esurai",{"t":"food_loan","o":"accept","x":{"sent":40,"back":48,"bres":"Food","repaid":"full"}})
	assert_str(loan).is_equal("The Esurai came hungry and borrowed 40 food from the stores, and paid it back.")
	var cairn:=Years.envoy_line("the Ildor",{"t":"boundary_cairn","o":"accept","x":{"place":"old ford"}})
	assert_str(cairn).contains("the Ildor")
	assert_str(cairn).contains("old ford")
	var captives:=Years.envoy_line("Esurai",{"t":"captive_scouts","o":"refuse","x":{"count":2}})
	assert_str(captives).contains("stayed captive")
	# Missing facts: nothing rather than a hole in the sentence.
	assert_str(Years.envoy_line("Esurai",{"t":"fugitive_return","o":"accept","x":{}})).is_equal("")
	assert_str(Years.envoy_line("Esurai",{"t":"no_such","o":"accept","x":{}})).is_equal("")


func test_every_twenty_years_the_generation_is_told()->void:
	var annals:Array=[]
	for y in 20:
		var m:={"y":y,"crises":1 if y%3!=0 else 0,"deaths":2 if y==7 else 0,"silent":1 if y%3!=0 else 0,"answered":0,"learned":3,"pop":100+y}
		if y==7:m["worst"]="the Coughing Winter"
		if y==4:m["heads"]=["Zeva"];m["turns"]=["The Sick Kept Apart"]
		if y==11:m["heads"]=["Esru"];m["kept"]=["The Mastery of Healing"]
		if y==16:m["met"]=["Ildor"];m["lost"]=["Liora Sky-Reader"]
		annals.append(m)
	assert_bool(Years.age_due(18,annals)).is_false()
	assert_bool(Years.age_due(19,annals)).is_true()
	var told:=Years.age(19,annals,1)
	var text:=String(told.text)
	assert_str(text).contains("Zeva")
	assert_str(text).contains("Esru")
	assert_str(text).contains("the Coughing Winter, in year 8")
	assert_str(text).contains("the Sick Kept Apart")
	assert_str(text).contains("the Mastery of Healing")
	assert_str(text).contains("Ildor")
	assert_str(text).contains("The hearths went from 100 souls to 119")
	assert_str(text).contains("The god did not answer once")


func test_a_generation_entry_follows_the_twentieth_year_and_is_not_polished()->void:
	var sent:=[]
	var Polish:=preload("res://scripts/chronicle_polish.gd")
	Polish.config_override={"endpoint":"http://mock.invalid","api_key":"test","model":"gpt-6-luna"}
	Polish.send_hook=func(year:String,_p:Dictionary)->void:sent.append(year)
	_at(0)
	for y in 20:
		_crisis("g%d" % y,y*365+30,"The Coughing Winter of year %d" % (y+1),"The Coughing Winter of year %d has passed. No one died of it." % (y+1))
		Annals.note_learned(Chronicle.data(),"way %d" % y,y*365+200)
	_at(20*365+1)
	Polish.send_hook=Callable();Polish.config_override={}
	var age:=_told("age:19")
	assert_bool(age.is_empty()).is_false()
	assert_str(String(age.kind)).is_equal("annal")
	assert_str(String(age.text)).contains("troubles came in these years")
	# One live request per year entry; the generation's account is not sent.
	assert_int(sent.size()).is_equal(20)


func test_older_annals_without_the_new_fields_still_compose()->void:
	var c:=GameState.chronicle
	c["annals"]=[{"y":0,"crises":1,"deaths":0,"learned":2,"pop":0,"km":0,"silent":1,"answered":0,"regard":"","name":""}]
	c["annal_year"]=0
	var a:=Annals.acc(c,365)
	a.year=1
	var told:=Annals.compose(c,a)
	assert_bool(told.is_empty()).is_false()
	assert_str(String(told.text)).is_not_empty()


func test_a_new_way_is_told_in_plain_words_never_the_research_text()->void:
	_at(0)
	GameState.discovery_log.append({"day":100,"id":"controlled_fermentation","name":"Controlled Fermentation","description":"Temperature, vessels, and starter cultures are managed to reproduce fermentation.","effects":{"food_storage":0.02,"nutrition_quality":0.01}})
	GameState.discovery_log.append({"day":120,"id":"controlled_kilns","name":"Controlled Kilns","description":"Enclosed firing chambers make heat repeatable enough to reproduce strong ceramics.","effects":{"craft_output":0.005}})
	Annals.note_learned(Chronicle.data(),"Controlled Fermentation",100)
	Annals.note_learned(Chronicle.data(),"Controlled Kilns",120)
	_at(366)
	var text:=String(_told("annal:0").text)
	assert_str(text).contains("controlled fermentation")
	assert_str(text).contains("food kept longer")
	assert_str(text).not_contains("starter cultures")
	assert_str(Years.technical(text)).is_equal("")


func test_technical_vocabulary_never_reaches_a_year_entry()->void:
	for word in ["reproduce","managed","cultures","temperature","repeatable","systematic","efficiency","process"]:
		assert_str(Years.technical("Food kept by the %s of the elders." % word)).is_equal(word)
	# A line in research words is left out of the year, not told.
	var picked:=Years.entry([{"t":"x","w":9.0,"text":"Temperature, vessels, and starter cultures are managed to reproduce fermentation."},{"t":"y","w":3.0,"text":"The hunters brought home more meat."}])
	assert_int((picked.lines as PackedStringArray).size()).is_equal(1)
	assert_str(String(picked.lines[0])).is_equal("The hunters brought home more meat.")
	# Forty years of the cadence test's news, plus research text: none of it.
	_at(0)
	for y in 10:
		GameState.discovery_log.append({"day":y*365+50,"id":"w%d" % y,"name":"Way %d" % y,"description":"A systematic process of managed temperature.","effects":{"labor_efficiency":0.01}})
		Annals.note_learned(Chronicle.data(),"Way %d" % y,y*365+50)
	_at(10*365+1)
	for e in GameState.chronicle.entries:
		if String(e.get("kind",""))=="annal":assert_str(Years.technical(String(e.text))).is_equal("")


func test_aims_read_as_sentences_with_their_own_words()->void:
	_at(0)
	_at(20)
	Chronicle.record({"key":"aim:start:a1","title":"An Aim for a Generation: Master Making Things","text":"Learn nine new ways of making things. The god said nothing, so the people took it up themselves.","tier":"moment","kind":"milestone"})
	_at(366)
	var first:=String(_told("annal:0").text)
	assert_bool("set themselves to learn nine new ways of making things" in first or "A new aim was taken up: to learn nine new ways of making things" in first).is_true()
	assert_str(first).not_contains("Master Making Things")
	_at(400)
	Chronicle.record({"key":"aim:fail:a1","title":"An Aim Unmet: Master Making Things","text":"Master Making Things was not done, and the people grieve it.","tier":"moment","kind":"milestone"})
	_at(2*365+1)
	var second:=String(_told("annal:1").text)
	assert_bool("aim to learn nine new ways of making things ran out of winters unmet" in second or "before the people could learn nine new ways of making things" in second).is_true()
	# Without its beginning, the title still reads as words, names kept.
	assert_str(Years.aim_words("Master The Sky and the Counting of Days")).is_equal("master the sky and the counting of days")
	assert_str(Years.aim_words("Raise a Cairn for Liora")).is_equal("raise a cairn for Liora")
	assert_str(Years.aim_words("Let Our Hearths Hold 121 Souls")).is_equal("let their hearths hold 121 souls")


func test_a_ruler_of_a_place_of_a_people_reads_without_a_double_of()->void:
	assert_str(Years.one_people("Word came that Hoya of Windgap of the Ildor had sworn to bind us to them.")).is_equal("Word came that the Ildor's Hoya of Windgap had sworn to bind us to them.")
	assert_str(Years.one_people("Tendo of Crowfield of Esurai had died.")).is_equal("the Esurai's Tendo of Crowfield had died.")
	assert_str(Years.one_people("Liora of the Red Cliff sat with the sick.")).is_equal("Liora of the Red Cliff sat with the sick.")
	var picked:=Years.entry([{"t":"x","w":5.0,"text":"Hoya of Windgap of the Ildor was said to be close to what they swore."}])
	assert_str(String(picked.lines[0])).is_equal("The Ildor's Hoya of Windgap was said to be close to what they swore.")
