extends GdUnitTestSuite
## The year's telling (scripts/chronicle_annals.gd): routine lines step back,
## callbacks connect the years, and every year ends in one entry of its own.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	ForeignDiplomacy.ensure();ForeignDiplomacy.audiences.erase("lives")
	Chronicle.pending_cards.clear()
	GameState.chronicle={}


func _at(day:int)->void:
	GameState.elapsed_days=float(day)
	Chronicle.ingest_day({"discoveries":[],"progression":[]})


func _crisis(id:String,day:int,onset:String,name:String,end_text:String,silent:bool)->void:
	_at(day)
	Chronicle.record({"key":"crisis:%s:onset" % id,"title":onset,"text":"Seven are down with a deep cough. Tomaq waits to be summoned.","tier":"moment","kind":"omen","priority":true})
	if silent:
		_at(day+10)
		Chronicle.record({"key":"crisis:%s:silent:open" % id,"title":"Tomaq Acts Alone","text":"The god was silent. Tomaq acted alone. Everyone tends the sick.","tier":"notice","kind":"court"})
	_at(day+30)
	Chronicle.record({"key":"crisis:%s:mid" % id,"title":name,"text":"%s still has hold of the camp." % name,"tier":"notice","kind":"omen"})
	_at(day+60)
	Chronicle.record({"key":"crisis:%s:end" % id,"title":"After "+name,"text":end_text+(" The god was silent. Tomaq acted alone." if silent else ""),"tier":"moment","kind":"ceremony"})


func _told(key:String)->Dictionary:
	for e in GameState.chronicle.get("entries",[]):
		if String(e.get("key",""))==key:return e
	return {}


func test_crisis_chatter_folds_and_the_end_calls_back()->void:
	_at(0)
	_crisis("c1",400,"Sickness at the Fires","The Coughing Winter of year 2","The Coughing Winter of year 2 has passed. No one died of it.",true)
	# The holder acting alone and the plain middle are tally lines now.
	assert_str(String(_told("crisis:c1:silent:open").tier)).is_equal("whisper")
	assert_str(String(_told("crisis:c1:mid").tier)).is_equal("whisper")
	var first_end:=_told("crisis:c1:end")
	assert_str(String(first_end.text)).not_contains("acted alone")
	assert_str(String(first_end.text)).contains("The god said nothing, and Tomaq decided.")
	_crisis("c2",1100,"Sickness at the Fires","The Coughing Winter of year 4","The Coughing Winter of year 4 has passed. It took two: Ama, a girl; and Tesk, an old man.",true)
	var onset:=_told("crisis:c2:onset")
	assert_bool(String(onset.title).ends_with(" Again") or String(onset.title).ends_with(" Once More")).is_true()
	assert_str(String(onset.text)).contains("Coughing Winter")
	var end:=_told("crisis:c2:end")
	assert_str(String(end.text)).contains("No sickness before it had killed so many.")
	assert_bool("said nothing" in String(end.text) or "kept silent" in String(end.text)).is_true()


func test_a_repeated_notice_steps_back_until_it_is_news_again()->void:
	_at(10)
	var first:=Chronicle.record({"title":"City Reconnaissance","text":"Reconnaissance of Tsaren: 4 scouts returned after 30 days away.","tier":"notice","kind":"scout"})
	_at(70)
	var second:=Chronicle.record({"title":"City Reconnaissance","text":"Reconnaissance of Tsaren: 4 scouts returned after 31 days away.","tier":"notice","kind":"scout"})
	_at(400)
	var third:=Chronicle.record({"title":"City Reconnaissance","text":"Reconnaissance of Tsaren: the watchers saw new walls.","tier":"notice","kind":"scout"})
	assert_str(String(first.tier)).is_equal("notice")
	assert_str(String(second.tier)).is_equal("whisper")
	assert_bool(bool(second.get("folded",false))).is_true()
	assert_str(String(third.tier)).is_equal("notice")


func test_a_scout_site_is_told_once_and_road_news_is_counted()->void:
	_at(10)
	var site:="The scout party returns after 97 days and charts roughly 1148 km of land travel. The red-stone uplands — Its use is not yet understood."
	GameState.simulation_events.push_front({"day":10,"title":"SCOUTS RETURN","description":site,"domain":"diplomacy","severity":"major","mission_id":3})
	_at(11)
	var news:=Chronicle.entries("moment")
	assert_int(news.size()).is_equal(1)
	assert_str(String(news[0].title)).is_equal("The scouts found the red-stone uplands")
	assert_str(String(news[0].text)).contains("walked some 1,148 km")
	GameState.simulation_events.push_front({"day":120,"title":"SCOUTS RETURN","description":site.replace("97 days","95 days")+" One scout was hurt on the road and carried home by the others; all came back alive.","domain":"diplomacy","severity":"major","mission_id":4})
	_at(120)
	assert_int(Chronicle.entries("moment").size()).is_equal(1)
	var scouts:Dictionary=Annals.acc(Chronicle.data()).scouts
	assert_int(int(scouts.n)).is_equal(2)
	assert_int(int(scouts.hurt)).is_equal(1)


func test_the_year_ends_in_one_entry_named_for_its_worst_trouble()->void:
	_at(0)
	GameState.population_total=120
	_at(1)
	(Annals.acc(Chronicle.data()) as Dictionary).pop0=120
	_crisis("c9",100,"Sickness at the Fires","The Coughing Winter of year 1","The Coughing Winter of year 1 has passed. It took three: Ama; Tesk; and Oru.",true)
	Annals.note_learned(Chronicle.data(),"Thorn barriers",150)
	Annals.note_learned(Chronicle.data(),"Load backframes",200)
	Chronicle.record({"key":"court:death:person:7","title":"Hadra of Fernside Is Dead","text":"Hadra of Fernside died aged 68. They brought strangers to our fire without blood.","tier":"notice","kind":"death"})
	GameState.population_total=114
	_at(366)
	var annal:=_told("annal:0")
	assert_bool(annal.is_empty()).is_false()
	assert_str(String(annal.kind)).is_equal("annal")
	assert_int(int(annal.day)/365).is_equal(0)
	assert_str(String(annal.title)).is_equal("The Coughing Winter")
	var text:=String(annal.text)
	# Told by what happened, in wordings that change from year to year.
	assert_str(text).contains("three")
	assert_str(text).contains("Ama")
	assert_str(text).contains("Hadra of Fernside")
	assert_str(text).contains("68")
	assert_str(text).contains("thorn barriers and load backframes")
	assert_str(text).contains("6 fewer than a year before")
	# One entry per year, never twice.
	_at(367)
	var annals:Array=GameState.chronicle.entries.filter(func(e:Dictionary)->bool:return String(e.get("kind",""))=="annal")
	assert_int(annals.size()).is_equal(1)


func test_an_older_save_begins_its_annals_without_backfilling()->void:
	GameState.elapsed_days=float(40*365+100)
	GameState.chronicle={"version":1,"entries":[],"firsts":{},"keys":{},"moment_days":[],"moment_ids":{},"scan_day":40*365+100}
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	assert_int(GameState.chronicle.entries.filter(func(e:Dictionary)->bool:return String(e.get("kind",""))=="annal").size()).is_equal(0)
	_at(41*365+2)
	assert_int(GameState.chronicle.entries.filter(func(e:Dictionary)->bool:return String(e.get("kind",""))=="annal").size()).is_equal(1)


## Forty simulated years of the kinds of news a campaign produces. Budgets:
## one entry per year, a bounded story per year, no repeated routine notices,
## and year entries that do not read alike.
func test_forty_years_read_without_repeating()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=4242
	var names:=["Ama","Tesk","Oru","Lisa","Brann","Kel","Mora","Idu","Sefa","Toma"]
	var types:=[["Sickness at the Fires","The Coughing Winter"],["The Rain Does Not Come","The Dry Year"],["Fire in the Camp","The Burning"],["The Land Is Worn Out","The Worn Land"]]
	var serial:=0
	GameState.population_total=100
	_at(0)
	for year in 40:
		var base:=year*365
		for n in rng.randi_range(0,2):
			serial+=1
			var t:Array=types[rng.randi_range(0,types.size()-1)]
			var deaths:=rng.randi_range(0,3) if rng.randf()<0.4 else 0
			var name:="%s of year %d" % [t[1],year+1]
			var end_text:="%s has passed. %s" % [name,"It took %s." % Annals.NUMBER_WORDS[deaths] if deaths>0 else "No one died of it."]
			_crisis("c%d" % serial,base+5+n*100,String(t[0]),name,end_text,rng.randf()<0.8)
		for k in rng.randi_range(0,4):Annals.note_learned(Chronicle.data(),"way %d-%d" % [year,k],base+100)
		for k in rng.randi_range(0,2):
			var day:=base+210+k*20
			GameState.simulation_events.push_front({"day":day,"title":"SCOUTS RETURN","description":"The scout party returns after %d days and charts roughly %d km of land travel. %s" % [rng.randi_range(60,200),rng.randi_range(300,1600),["One scout was hurt on the road and carried home by the others; all came back alive.","Sickness and hard going turned the party back before it reached the end of its route.","They passed a large wandering band who kept moving."][rng.randi_range(0,2)]],"domain":"diplomacy","severity":"major","mission_id":serial*10+k})
			_at(day)
		for k in 6:
			_at(base+260+k*15)
			Chronicle.record({"title":"City Reconnaissance","text":"Reconnaissance of Tsaren: 4 scouts returned after %d days away." % rng.randi_range(27,35),"tier":"notice","kind":"scout"})
		if rng.randf()<0.3:
			Chronicle.record({"key":"court:death:person:%d" % (1000+year),"title":"%s of Reedwater Is Dead" % names[year%names.size()],"text":"%s of Reedwater died aged %d." % [names[year%names.size()],rng.randi_range(40,80)],"tier":"notice","kind":"death"})
		GameState.population_total=maxi(40,GameState.population_total+rng.randi_range(-6,8))
	_at(40*365+1)
	var entries:Array=GameState.chronicle.entries
	var annals:=entries.filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("annal:"))
	assert_int(annals.size()).is_equal(40)
	# And a generation's account after each twentieth year.
	assert_int(entries.filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("age:")).size()).is_equal(2)
	# The story told per year stays readable.
	var per_year:={}
	for e in entries:
		if String(e.get("tier",""))=="whisper":continue
		var y:=int(e.day)/365
		per_year[y]=int(per_year.get(y,0))+1
	for y in per_year:assert_int(int(per_year[y])).is_less_equal(14)
	# Six watch reports a year: at most two are told.
	var watches:=entries.filter(func(e:Dictionary)->bool:return String(e.get("title",""))=="City Reconnaissance" and String(e.get("tier",""))!="whisper")
	assert_int(watches.size()).is_less_equal(40*2)
	# No routine scout return is a card.
	assert_int(entries.filter(func(e:Dictionary)->bool:return String(e.get("kind",""))=="scout" and String(e.get("tier",""))=="moment").size()).is_equal(0)
	# Year entries do not read alike.
	var texts:={}
	var sentences:={}
	var total:=0
	for e in annals:
		texts[String(e.text)]=true
		for s in String(e.text).split(". "):
			var key:=s.strip_edges()
			if key.length()<16:continue
			sentences[key]=int(sentences.get(key,0))+1;total+=1
	assert_int(texts.size()).is_equal(40)
	var repeated:=0
	for k in sentences:
		if int(sentences[k])>1:repeated+=int(sentences[k])
	assert_float(float(repeated)/maxf(1.0,float(total))).is_less(0.35)
