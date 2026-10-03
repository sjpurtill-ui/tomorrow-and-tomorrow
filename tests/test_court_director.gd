extends GdUnitTestSuite
## THE COURT'S DIRECTOR (scripts/hud/court_director.gd, court_asides.gd).
## The whole room acts out what the engine decided, with comic timing, and
## never contradicts it:
## - one the engine says defied the god never kneels, bows or shakes;
## - nobody is hungry on stage while the stores are full; no cough without a
##   sickness, no spears without a war, no stamping in summer, no fly in winter,
##   no scribe where nobody writes;
## - a muttered line answers something visible, comes only from someone bold
##   enough, never in a terrified or grieving room, is eight words or fewer,
##   sidelong (never to the god), and cites only what the facts and the event
##   hold, in plain speech of the people's own age; it can be turned off;
## - the same seed gives the same beats; over a long campaign no bit is more
##   than about one event in twelve and no muttered line comes back within
##   three game years.
## Pure: no game state is read or written.

const Director:=preload("res://scripts/hud/court_director.gd")
const Asides:=preload("res://scripts/hud/court_asides.gd")
const CV:=preload("res://scripts/character_voice.gd")
const Plain:=preload("res://scripts/plain_speech.gd")

const NUMBER_WORDS:={"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12}
const SEASONS:=["spring","summer","autumn","winter"]

static func home_cast()->Array:
	return [
		{"key":"main","role":"main","kind":"petitioner","name":"Hena Tuvasi","age":38,"courage":0.5,"pride":0.5,"love":0.45,"dread":0.3,"voice":"grant","x":0.40},
		{"key":"p1","role":"court","kind":"official","name":"Orrin Vael","age":47,"courage":0.75,"pride":0.8,"love":0.35,"dread":0.15,"voice":"achilles","office":"War leader","x":0.66},
		{"key":"p2","role":"court","kind":"official","name":"Suri Danek","age":33,"courage":0.3,"pride":0.3,"love":0.6,"dread":0.55,"voice":"falstaff","office":"Headman","x":0.14},
		{"key":"p3","role":"court","kind":"hearth_chief","name":"Kavu Mbeli","age":41,"courage":0.35,"pride":0.2,"love":0.7,"dread":0.4,"voice":"polonius","office":"Hearth chief of Reedmouth","x":0.80},
		{"key":"p4","role":"court","kind":"official","name":"Tamsin Oru","age":29,"courage":0.6,"pride":0.45,"love":0.5,"dread":0.2,"empathy":0.8,"voice":"atticus","office":"Keeper of Tribute","x":0.27},
		{"key":"c1","role":"crowd","kind":"elder","name":"Ama Seld","age":71,"courage":0.5,"pride":0.4,"love":0.5,"dread":0.2,"x":0.93},
		{"key":"c2","role":"crowd","kind":"child","name":"Lio","age":7,"courage":0.3,"pride":0.1,"love":0.5,"dread":0.3,"x":0.88},
		{"key":"c3","role":"crowd","kind":"commoner","name":"Brann Ute","age":30,"courage":0.35,"pride":0.3,"love":0.4,"dread":0.5,"stance":"bowl","x":0.53},
		{"key":"dog","role":"animal","kind":"dog","name":"the dog","x":0.47},
		{"key":"goat","role":"animal","kind":"goat","name":"the goat","x":0.98},
	]

static func envoy_cast(temper:="nervous")->Array:
	var out:Array=[
		{"key":"main","role":"main","kind":"envoy","name":"Ishkar Velu","age":44,"courage":0.6,"pride":0.6,"temper":temper,"x":0.26},
		{"key":"att0","role":"attendant","kind":"guard","name":"Dov","age":26,"x":0.09},
		{"key":"att1","role":"attendant","kind":"bearer","name":"Nel","age":22,"x":0.42},
	]
	for entry:Dictionary in home_cast():
		if String(entry.key)!="main" and String(entry.key)!="goat":out.append(entry)
	return out

static func hungry_facts()->Dictionary:
	return {"day":4000,"food_days":9,"population":214,"season":"winter","era_tags":[],"era_tier":0,"people_dread":0.35,"people_love":0.5,
		"sickness":{"name":"the Marsh Cough","deaths":3},"war":{"enemy":"Kelvar","kind":"feud"},
		"envoy":{"civ":"Ashwen","days_waiting":4,"their_food_days":25},"gift":{"resource":"Food","amount":40}}

static func full_facts(days:int)->Dictionary:
	return {"day":4000,"food_days":days,"population":214,"season":"summer","era_tags":["farming","pottery"],"era_tier":1,"people_dread":0.2,"people_love":0.55}

## A spread of every kind of event, for the sweeps.
static func events()->Array:
	return [
		{"kind":"god_speaks","text":"Why have you come?"},
		{"kind":"god_speaks","text":"Speak plainly.","tone":"favor"},
		{"kind":"line","who":"main","text":"We have 40 hides drying and the snow is coming early this year, Great One."},
		{"kind":"line","who":"p2","text":"The stores hold nine days."},
		{"kind":"divine","action":"terrify","target":"main","response":"cower","witnesses":{"p1":"unbowed","p2":"shaken","p3":"shaken","p4":"shaken"}},
		{"kind":"divine","action":"terrify","target":"main","response":"defy","witnesses":{"p1":"unbowed","p2":"shaken"}},
		{"kind":"divine","action":"terrify","target":"p1","response":"defy"},
		{"kind":"divine","action":"penance","target":"main","response":"endure"},
		{"kind":"divine","action":"penance","target":"p3","response":"defy"},
		{"kind":"divine","action":"boon","target":"p4","response":"blessed","terms":{"resource":"Food","amount":12}},
		{"kind":"divine","action":"bless","target":"main","response":"relief","witnesses":{"p1":"envy","p4":"glad"}},
		{"kind":"divine","action":"raise_up","target":"p3","response":"blessed"},
		{"kind":"divine","action":"strike_down","target":"main","terminal":true},
		{"kind":"divine","action":"cast_out","target":"p2"},
		{"kind":"command","verb":"order","stage":"none","actor":"p2","target":"","obedience":"obey","executed":false},
		{"kind":"command","verb":"kill","stage":"kill","actor":"p1","target":"main","obedience":"reluctant","executed":true,"removed":true},
		{"kind":"command","verb":"detain","stage":"refuse_seized","actor":"p1","target":"main","obedience":"refuse"},
		{"kind":"command","verb":"exile","stage":"refuse_flee","actor":"p1","target":"main","obedience":"refuse","removed":true},
		{"kind":"command","verb":"send","stage":"send","actor":"p4","target":"","obedience":"obey","manner":"trembling"},
		{"kind":"command","verb":"kill","stage":"prostrate","actor":"p1","target":"god"},
		{"kind":"decree","who":"main","accepted":true,"reaction":"delighted"},
		{"kind":"decree","who":"main","accepted":true,"reaction":"pleased","cost":{"resource":"Food","amount":30}},
		{"kind":"decree","who":"main","accepted":false,"reaction":"offended"},
		{"kind":"decree","issued":true,"accepted":true,"who":"main"},
		{"kind":"promise","who":"main"},
		{"kind":"dismiss","who":"main","reaction":"offended"},
		{"kind":"wait","who":"main"},
		{"kind":"summon","who":"main"},
		{"kind":"exit","who":"main","style":"storm"},
		{"kind":"exit","who":"main","style":"bow","reaction":"pleased"},
	]

static func envoy_events()->Array:
	return [
		{"kind":"summon","who":"main"},
		{"kind":"gift","accepted":true,"resource":"Food","amount":40,"who":"main"},
		{"kind":"gift","accepted":false,"resource":"Food","amount":40,"who":"main"},
		{"kind":"gift","accepted":true,"resource":"Timber","amount":25,"who":"main"},
		{"kind":"terrify_envoy","response":"defy","target":"main"},
		{"kind":"terrify_envoy","response":"cower","target":"main"},
		{"kind":"envoy_insulted","who":"main"},
		{"kind":"line","who":"main","text":"My ruler sends greetings and asks that you remember the river crossing, where our hunters and yours met last summer, and the 12 days it took us to come here."},
		{"kind":"decree","who":"main","accepted":true,"reaction":"pleased","cost":{"resource":"Food","amount":30}},
		{"kind":"exit","who":"main","style":"storm"},
	]

# --- The engine's word stands ---------------------------------------------------

func test_one_who_defied_never_kneels_or_bows()->void:
	var memory:={}
	for seed_value in 160:
		for event:Dictionary in [
				{"kind":"divine","action":"terrify","target":"main","response":"defy","witnesses":{"p1":"unbowed","p2":"shaken"}},
				{"kind":"divine","action":"penance","target":"main","response":"defy"},
				{"kind":"divine","action":"terrify","target":"p3","response":"defy"},   # the eager hearth chief, of all people
				{"kind":"divine","action":"terrify","target":"c3","response":"defy"}]:   # the one holding the bowl
			for beat:Dictionary in Director.beats_for(event,home_cast(),hungry_facts(),seed_value,memory):
				if String(beat.who)==String(event.target):
					assert_bool(String(beat.act) in Director.KNEEL_LIKE or String(beat.act)=="kneel_bound").override_failure_message(
						"%s defied the god but was shown to %s (seed %d)" % [event.target,beat.act,seed_value]).is_false()
		for temper in ["haughty","nervous","greedy","calm"]:
			for beat:Dictionary in Director.beats_for({"kind":"terrify_envoy","response":"defy","target":"main"},envoy_cast(temper),hungry_facts(),seed_value,memory):
				if String(beat.who)=="main":assert_bool(String(beat.act) in Director.KNEEL_LIKE).override_failure_message("the %s envoy defied but %s" % [temper,beat.act]).is_false()

func test_defiance_stands_firm_and_cowering_goes_down()->void:
	var firm:=Director.beats_for({"kind":"divine","action":"terrify","target":"main","response":"defy"},home_cast(),full_facts(60),3)
	var cowed:=Director.beats_for({"kind":"divine","action":"terrify","target":"main","response":"cower"},home_cast(),full_facts(60),3)
	assert_bool(_did(firm,"main","stand_firm")).is_true()
	assert_bool(_did(cowed,"main","kneel")).is_true()
	assert_bool(_did(cowed,"main","stand_firm")).is_false()

func test_a_refusal_never_bows_and_seized_is_forced_down_bound()->void:
	for seed_value in 60:
		var seized:=Director.beats_for({"kind":"command","verb":"detain","stage":"refuse_seized","actor":"p1","target":"main","obedience":"refuse"},home_cast(),hungry_facts(),seed_value)
		var fled:=Director.beats_for({"kind":"command","verb":"exile","stage":"refuse_flee","actor":"p1","target":"main","obedience":"refuse"},home_cast(),hungry_facts(),seed_value)
		for beat:Dictionary in seized+fled:
			if String(beat.who)=="p1":assert_bool(String(beat.act) in Director.KNEEL_LIKE).override_failure_message("p1 refused but %s" % beat.act).is_false()
		assert_bool(_did(seized,"p1","kneel_bound")).is_true()
		assert_bool(_did(fled,"p1","kneel_bound")).is_false()
		assert_bool(_did(fled,"p1","bolt")).is_true()

func test_death_and_exile_stay_sober()->void:
	var memory:={}
	for seed_value in 80:
		for event:Dictionary in [{"kind":"divine","action":"strike_down","target":"main","terminal":true},{"kind":"divine","action":"cast_out","target":"p2"},
				{"kind":"exit","who":"main","style":"led"},{"kind":"exit","who":"main","style":"fall"},
				{"kind":"command","verb":"exile","stage":"exile","actor":"p1","target":"main","obedience":"obey","executed":true,"removed":true}]:
			var list:=Director.beats_for(event,home_cast(),hungry_facts(),seed_value,memory)
			for beat:Dictionary in list:
				assert_bool(String(beat.act) in Director.COMIC_ACTS).override_failure_message("comedy at %s: %s %s" % [event,beat.who,beat.act]).is_false()
			assert_array(Director.asides_for(event,hungry_facts(),home_cast(),seed_value,memory)).is_empty()
		var death:=Director.beats_for({"kind":"divine","action":"strike_down","target":"main","terminal":true},home_cast(),hungry_facts(),seed_value,{})
		for beat:Dictionary in death:
			if String(beat.who)=="main":assert_str(String(beat.act)).is_equal("stricken")
		assert_bool(_did(death,"c1","cover_eyes") or _did(death,"p4","cover_eyes") or _did(death,"c3","cover_eyes")).override_failure_message("nobody covered the child's eyes").is_true()

# --- Only what the facts hold -------------------------------------------------------

func test_nobody_is_hungry_while_the_stores_are_full()->void:
	for days in [16,35,120,400]:
		for seed_value in 60:
			var facts:=full_facts(days)
			facts["gift"]={"resource":"Food","amount":40}
			for cast in [home_cast(),envoy_cast()]:
				for loop:Dictionary in Director.ambient(cast,facts,seed_value):
					assert_bool(String(loop.act) in Director.HUNGER_ACTS).override_failure_message("hunger shown with %d days of food: %s" % [days,loop.act]).is_false()
			var memory:={}
			for event:Dictionary in events():
				for beat:Dictionary in Director.beats_for(event,home_cast(),facts,seed_value,memory):
					assert_bool(String(beat.act) in Director.HUNGER_ACTS).override_failure_message("hungry beat with %d days: %s in %s" % [days,beat.act,event.kind]).is_false()
			for beat:Dictionary in Director.beats_for({"kind":"gift","accepted":true,"resource":"Food","amount":40,"who":"main"},envoy_cast(),facts,seed_value):
				assert_bool(String(beat.act) in Director.HUNGER_ACTS).is_false()
	# No food figure in the sheet at all: nothing shows hunger either.
	for loop:Dictionary in Director.ambient(home_cast(),{"season":"spring"},7):
		assert_bool(String(loop.act) in Director.HUNGER_ACTS).is_false()

func test_short_stores_show_on_the_faces()->void:
	var hungry_loops:=0
	for seed_value in 20:
		for loop:Dictionary in Director.ambient(home_cast(),hungry_facts(),seed_value):
			if String(loop.act) in Director.HUNGER_ACTS:
				hungry_loops+=1
				assert_str(String(loop.because)).is_equal("food_days")
	assert_int(hungry_loops).is_greater_equal(20)

func test_no_cough_without_sickness_no_spears_without_war()->void:
	for seed_value in 40:
		var calm:=full_facts(60)
		for loop:Dictionary in Director.ambient(home_cast(),calm,seed_value):
			assert_bool(String(loop.act) in Director.SICK_ACTS+Director.WAR_ACTS).override_failure_message("%s with no sickness or war" % loop.act).is_false()
		var memory:={}
		for event:Dictionary in events():
			for beat:Dictionary in Director.beats_for(event,home_cast(),calm,seed_value,memory):
				assert_bool(String(beat.act) in Director.SICK_ACTS+Director.WAR_ACTS).override_failure_message("%s in %s with no sickness or war" % [beat.act,event.kind]).is_false()
	var acts:={}
	for loop:Dictionary in Director.ambient(home_cast(),hungry_facts(),4):acts[String(loop.act)]=String(loop.because)
	assert_bool(acts.has("cough")).is_true()
	assert_bool(acts.has("sharpen_spear")).is_true()
	assert_str(String(acts.get("cough",""))).is_equal("sickness")

func test_the_season_shows_only_in_its_season()->void:
	for season in SEASONS:
		var facts:=full_facts(60);facts["season"]=season
		var memory:={}
		for seed_value in 30:
			for event:Dictionary in events():
				for beat:Dictionary in Director.beats_for(event,home_cast(),facts,seed_value,memory):
					if season!="winter":assert_bool(String(beat.act) in Director.WINTER_ACTS).override_failure_message("%s in %s" % [beat.act,season]).is_false()
					if season!="summer":assert_bool(String(beat.act) in Director.SUMMER_ACTS).override_failure_message("%s in %s" % [beat.act,season]).is_false()
			for loop:Dictionary in Director.ambient(home_cast(),facts,seed_value):
				if season!="winter":assert_bool(String(loop.act) in Director.WINTER_ACTS).is_false()
				if season!="summer":assert_bool(String(loop.act) in Director.SUMMER_ACTS).is_false()
	var winter:={};var summer:={}
	for seed_value in 20:
		var w:=full_facts(60);w["season"]="winter"
		var s:=full_facts(60);s["season"]="summer"
		for loop:Dictionary in Director.ambient(home_cast(),w,seed_value):winter[String(loop.act)]=true
		for loop:Dictionary in Director.ambient(home_cast(),s,seed_value):summer[String(loop.act)]=true
	assert_bool(winter.has("stamp_feet") or winter.has("breath")).is_true()
	assert_bool(summer.has("swat_fly")).is_true()

func test_the_hall_grows_with_the_age()->void:
	var stone:=Director.extras({"era_tags":[],"era_tier":0,"people_dread":0.7,"people_love":0.2},3)
	var villages:=Director.extras({"era_tags":["dairy","farming"],"era_tier":1,"people_dread":0.1,"people_love":0.8},3)
	var letters:=Director.extras({"era_tags":["dairy","farming","writing","metal"],"era_tier":2},3)
	var grand:=Director.extras({"era_tags":["dairy","farming","writing","metal","coin","ships"],"era_tier":3},3)
	var kinds:=func(list:Array)->Array:return list.map(func(e:Dictionary)->String:return String(e.kind))
	var people:=func(list:Array)->int:return list.filter(func(e:Dictionary)->bool:return String(e.role)=="crowd").size()
	assert_bool("goat" in kinds.call(stone)).override_failure_message("a goat before anyone pens a herd").is_false()
	assert_bool("goat" in kinds.call(villages)).is_true()
	assert_bool("scribe" in kinds.call(villages)).override_failure_message("a scribe before anyone writes").is_false()
	assert_bool("scribe" in kinds.call(letters)).is_true()
	assert_bool("door_guard" in kinds.call(letters)).is_true()
	assert_int(int(people.call(stone))).is_less(int(people.call(villages)))
	assert_int(int(people.call(villages))).is_less(int(people.call(letters)))
	assert_int(int(people.call(letters))).is_less(int(people.call(grand)))
	for entry:Dictionary in stone:
		if String(entry.role)=="crowd":assert_float(float(entry.dread)).is_greater(0.5)
	for entry:Dictionary in villages:
		if String(entry.role)=="crowd":assert_float(float(entry.love)).is_greater(0.6)
	assert_str(JSON.stringify(Director.extras({"era_tags":[]},11))).is_equal(JSON.stringify(Director.extras({"era_tags":[]},11)))

# --- Who dares to mutter, and what ---------------------------------------------------

func test_asides_cite_only_facts_present()->void:
	var said:=0
	var runs:=[[home_cast(),events()],[envoy_cast("haughty"),envoy_events()],[envoy_cast("greedy"),envoy_events()]]
	for facts:Dictionary in [hungry_facts(),full_facts(80),{"season":"spring"}]:
		for run:Array in runs:
			var memory:={}
			var cast:Array=run[0]
			for seed_value in 40:
				var since:=99
				for event:Dictionary in run[1]:
					Director.beats_for(event,cast,facts,seed_value,memory)
					var lines:=Director.asides_for(event,facts,cast,seed_value,memory)
					assert_int(lines.size()).is_less_equal(1)
					since+=1
					if not lines.is_empty():
						assert_int(since).override_failure_message("muttered lines too close together").is_greater(Director.ASIDE_GAP)
						since=0
					for line:Dictionary in lines:
						said+=1
						_check_aside(line,event,facts,cast)
	assert_int(said).is_greater(20)

func _check_aside(line:Dictionary,event:Dictionary,facts:Dictionary,cast:Array)->void:
	var text:=String(line.text)
	var who:=String(line.who)
	assert_bool(who in ["main","god","",String(event.get("target","")),String(event.get("actor",""))]).override_failure_message("%s should not mutter: %s" % [who,text]).is_false()
	var speaker:={}
	for c:Dictionary in cast:
		if String(c.key)==who:speaker=c
	assert_bool(speaker.is_empty()).override_failure_message("%s is not in the hall" % who).is_false()
	# Only the bold, a child or an old one dare.
	assert_float(Director.dare(Director.member(speaker))).override_failure_message("%s is too frightened to say: %s" % [who,text]).is_greater_equal(Director.DARE_MIN)
	assert_int(Asides.word_count(text)).override_failure_message("too long: %s" % text).is_less_equal(8)
	# Every cited fact is in the sheet, the event or the cast.
	for cite in line.cites:
		assert_bool(_resolves(String(cite),event,facts,cast)).override_failure_message("'%s' cites %s, which is not there" % [text,cite]).is_true()
	# Every number said is a number the sheet or the event holds.
	var allowed:=_numbers(facts)+_numbers(event)
	var hit:=Director.number_in(String(event.get("text","")))
	if not hit.is_empty():allowed.append(int(hit.value))
	for n in _numbers_in(text):
		assert_bool(n in allowed).override_failure_message("'%s' says %d; the facts hold %s" % [text,n,allowed]).is_true()
	assert_bool(Plain.is_maxim(text)).override_failure_message("a maxim: %s" % text).is_false()
	assert_bool(CV.permits(text,facts.get("era_tags",[]))).override_failure_message("out of its age: %s" % text).is_true()
	assert_bool(CV.imitation_ok(text)).is_true()
	assert_bool(text.contains("{")).is_false()

func _resolves(path:String,event:Dictionary,facts:Dictionary,cast:Array)->bool:
	var parts:=path.split(".")
	match parts[0]:
		"facts":return _walk(facts,parts.slice(1))
		"event":
			if parts[1] in ["amount","resource"]:
				return event.has(parts[1]) or (event.get("terms",{}) as Dictionary).has(parts[1]) or (event.get("cost",{}) as Dictionary).has(parts[1])
			return _walk(event,parts.slice(1))
		"cast":
			for c:Dictionary in cast:
				if String(c.key)==parts[1]:return parts.size()<3 or c.has(parts[2])
	return false

func _walk(at:Variant,path:Array)->bool:
	for key in path:
		if not at is Dictionary or not (at as Dictionary).has(key):return false
		at=(at as Dictionary)[key]
	return true

func _numbers(source:Variant)->Array:
	var out:Array=[]
	if source is Dictionary:
		for key in source:out+=_numbers(source[key])
	elif source is Array:
		for item in source:out+=_numbers(item)
	elif source is int or source is float:out.append(roundi(float(source)))
	return out

func _numbers_in(text:String)->Array:
	var out:Array=[]
	var re:=RegEx.new();re.compile("\\b\\d+\\b")
	for m in re.search_all(text):out.append(int(m.get_string()))
	var words:=RegEx.new();words.compile("(?i)\\b(two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\\b")
	for m in words.search_all(text):out.append(int(NUMBER_WORDS[m.get_string().to_lower()]))
	return out

func test_every_muttered_line_is_short_plain_and_sidelong()->void:
	var slots:={"amount":"40","resource":"fibre","food_days":"nine","name":"Hena","other":"Orrin","number":"forty","envoy_civ":"Ash Wen","enemy":"Kel Var","thing":"staff"}
	for entry:Dictionary in Asides.all_templates():
		var text:=Asides.render(String(entry.text),slots)
		assert_str(text).override_failure_message("unfilled: %s" % entry.text).is_not_empty()
		assert_int(Asides.word_count(text)).override_failure_message("over eight words (%s): %s" % [entry.situation,text]).is_less_equal(Asides.MAX_WORDS)
		assert_bool(Plain.is_maxim(text)).override_failure_message("a maxim (%s): %s" % [entry.situation,text]).is_false()
		# Lines carry no words of a later age unless their situation needs it.
		var tags:Array=Asides.NEEDS.get(String(entry.situation),[])
		assert_array(CV.lexicon_hits(text,tags)).override_failure_message("era words in: %s" % text).is_empty()
		assert_bool(CV.imitation_ok(text)).is_true()
		# Sidelong: never said to the god.
		var low:=text.to_lower()
		for address in ["great one","my lord","o god","my god","your will","as you command"]:
			assert_bool(low.contains(address)).override_failure_message("said to the god: %s" % text).is_false()

func test_the_frightened_never_mutter()->void:
	var memory:={}
	var cast:=home_cast()
	for entry:Dictionary in cast:
		if String(entry.get("role",""))!="animal":entry["dread"]=0.8;entry["courage"]=0.3
	var facts:=full_facts(60)
	for seed_value in 200:
		for event:Dictionary in events():
			Director.beats_for(event,cast,facts,seed_value,memory)
			# Everyone here is frightened, even the child: not a word.
			var lines:=Director.asides_for(event,facts,cast,seed_value,memory)
			assert_array(lines).override_failure_message("someone frightened muttered: %s" % [lines]).is_empty()

func test_a_terrified_room_is_silent()->void:
	var memory:={}
	var dread:=full_facts(60);dread["people_dread"]=0.7
	for seed_value in 120:
		for event:Dictionary in [{"kind":"divine","action":"terrify","target":"main","response":"cower"},{"kind":"divine","action":"terrify","target":"p1","response":"defy"},
				{"kind":"command","verb":"kill","stage":"prostrate","actor":"p1","target":"god"}]:
			Director.beats_for(event,home_cast(),hungry_facts(),seed_value,memory)
			assert_array(Director.asides_for(event,hungry_facts(),home_cast(),seed_value,memory)).is_empty()
		for event:Dictionary in [{"kind":"terrify_envoy","response":"cower","target":"main"}]:
			Director.beats_for(event,envoy_cast(),hungry_facts(),seed_value,memory)
			assert_array(Director.asides_for(event,hungry_facts(),envoy_cast(),seed_value,memory)).is_empty()
		for event:Dictionary in events():
			Director.beats_for(event,home_cast(),dread,seed_value,memory)
			assert_array(Director.asides_for(event,dread,home_cast(),seed_value,memory)).override_failure_message("a muttered line in a hall in dread").is_empty()
	# The silence has one small noise in it now and then, and it is real.
	var breaks:={}
	for seed_value in 80:
		for beat:Dictionary in Director.beats_for({"kind":"divine","action":"terrify","target":"main","response":"cower"},home_cast(),hungry_facts(),seed_value,{}):
			if String(beat.act) in ["stomach_growl","stifle_cough","floor_creak","swallow_loud","bleat"]:breaks[String(beat.act)]=true
	assert_int(breaks.size()).is_greater_equal(3)
	for beat:Dictionary in Director.beats_for({"kind":"divine","action":"terrify","target":"main","response":"cower"},home_cast(),full_facts(60),5,{}):
		assert_bool(String(beat.act) in ["stomach_growl","stifle_cough"]).is_false()

func test_muttering_can_be_turned_off()->void:
	var director:=Director.new()
	var heard:=0
	for i in 60:
		var event:Dictionary=events()[i%events().size()]
		director.beats(event,home_cast(),hungry_facts(),i)
		heard+=director.asides(event,hungry_facts(),home_cast(),i).size()
	assert_int(heard).is_greater(0)
	Director.mutters_enabled=false
	var quiet:=Director.new()
	var off:=0
	for i in 60:
		var event:Dictionary=events()[i%events().size()]
		quiet.beats(event,home_cast(),hungry_facts(),i)
		off+=quiet.asides(event,hungry_facts(),home_cast(),i).size()
	Director.mutters_enabled=true
	assert_int(off).is_equal(0)
	var facts:=hungry_facts();facts["mutters"]=false
	var memory:={}
	for i in 60:
		var event:Dictionary=events()[i%events().size()]
		Director.beats_for(event,home_cast(),facts,i,memory)
		assert_array(Director.asides_for(event,facts,home_cast(),i,memory)).is_empty()

# --- The scenes the player sees most ---------------------------------------------------

func test_the_scenes_are_there()->void:
	var seen:={}
	var facts:=full_facts(60);facts["era_tags"]=["farming","dairy","writing"];facts["era_tier"]=2
	var cast:=home_cast()+[{"key":"scribe","role":"crowd","kind":"scribe","name":"Pell","age":40,"x":0.6}]
	var stranger:=home_cast().duplicate(true);stranger[0]={"key":"main","role":"main","kind":"commoner","name":"Bo Narra","age":30,"courage":0.4,"pride":0.2,"dread":0.4}
	var child:=home_cast().duplicate(true);child[0]={"key":"main","role":"main","kind":"child","name":"Tiri","age":8,"courage":0.6,"pride":0.3,"dread":0.2}
	var gifted:=home_cast().duplicate(true);gifted[0]={"key":"main","role":"main","kind":"child","name":"Asa","age":9,"gifted":"Logistics","courage":0.6,"pride":0.3,"dread":0.2}
	var nervous:=home_cast().duplicate(true);nervous[0]["dread"]=0.6
	var staffed:=home_cast().duplicate(true);staffed[0]["stance"]="staff"
	var summer:=facts.duplicate();summer["season"]="summer"
	var winter:=facts.duplicate();winter["season"]="winter"
	var gift_facts:=facts.duplicate();gift_facts["gift"]={"resource":"Food","amount":40}
	for seed_value in 120:
		var memory:={}
		for pair:Array in [[{"kind":"wait","who":"main"},cast,facts],[{"kind":"promise","who":"main"},cast,facts],[{"kind":"dismiss","who":"main","reaction":"furious"},cast,facts],
				[{"kind":"decree","who":"main","accepted":true,"reaction":"pleased","cost":{"resource":"Food","amount":30}},cast,facts],
				[{"kind":"decree","issued":true,"accepted":true},cast,facts],[{"kind":"divine","action":"bless","target":"main","response":"relief"},cast,facts],
				[{"kind":"summon","who":"main"},nervous,facts],[{"kind":"summon","who":"main"},child,facts],[{"kind":"summon","who":"main"},stranger,facts],
				[{"kind":"summon","who":"main"},gifted,facts],[{"kind":"exit","who":"main","style":"bow","reaction":"delighted"},cast,facts],
				[{"kind":"exit","who":"main","style":"storm","reaction":"furious"},staffed,facts],[{"kind":"god_speaks","text":"Go on."},cast,summer],
				[{"kind":"line","who":"p2","text":"The pens are full."},cast,winter],[{"kind":"god_speaks","text":"Write it."},cast,facts],
				[{"kind":"summon","who":"main"},envoy_cast("haughty"),facts],[{"kind":"summon","who":"main"},envoy_cast("nervous"),facts],[{"kind":"summon","who":"main"},envoy_cast("greedy"),facts],
				[{"kind":"gift","accepted":false,"resource":"Food","amount":40,"who":"main"},envoy_cast("haughty"),gift_facts],[{"kind":"exit","who":"main","style":"storm","reaction":"furious"},envoy_cast("haughty"),gift_facts,"keep"]]:
			# Each moment fresh, except an exit that follows its own audience.
			if pair.size()<4:memory={}
			for beat:Dictionary in Director.beats_for(pair[0],pair[1],pair[2],seed_value,memory):seen[String(beat.act)]=true
	for act in ["catch_eye","deflate_polite","bow_curt","glum","scribble","over_thank","enter_wrong","wave","bow_wrong","count_heads","bump_post",
			"come_back","come_back_for","snatch_up","snore","swat_fly","stamp_feet","shake_hand","sniff_disdain","startle","appraise","gawk","stare_down","nod_too_much"]:
		assert_bool(seen.has(act)).override_failure_message("never played: %s" % act).is_true()

func test_make_them_wait_puts_the_old_one_back_to_sleep()->void:
	var found:=false
	for seed_value in 40:
		var memory:={}
		var woke_first:=false
		for i in 3:
			var first:=Director.beats_for({"kind":"god_speaks","text":"Speak."},home_cast(),full_facts(60),seed_value*10+i,memory)
			if _did(first,"c1","jerk_awake"):woke_first=true;break
		if not woke_first:continue
		var wait:=Director.beats_for({"kind":"wait","who":"main"},home_cast(),full_facts(60),seed_value,memory)
		if not _did(wait,"c1","doze_off"):continue
		# Asleep again, and the next time the god speaks they wake again,
		# though they were woken only a moment ago.
		assert_str(Director.asleep(home_cast(),full_facts(60),memory)).is_equal("c1")
		found=true;break
	assert_bool(found).is_true()

func test_a_stranger_bows_to_the_wrong_person_and_a_child_waves()->void:
	var stranger:=home_cast().duplicate(true);stranger[0]={"key":"main","role":"main","kind":"commoner","name":"Bo Narra","age":30,"courage":0.4,"pride":0.2,"dread":0.4}
	var bowed_to:={}
	for seed_value in 40:
		for beat:Dictionary in Director.beats_for({"kind":"summon","who":"main"},stranger,full_facts(60),seed_value):
			if String(beat.act)=="bow_wrong":bowed_to[String((beat.args as Dictionary).at)]=true
	# The grandest-looking official: the proud war leader.
	assert_bool(bowed_to.has("p1")).is_true()

# --- Same seed, and never stale ----------------------------------------------------------

func test_the_same_seed_gives_the_same_beats()->void:
	for event:Dictionary in events():
		var a:=Director.beats_for(event,home_cast(),hungry_facts(),42,{})
		var b:=Director.beats_for(event,home_cast(),hungry_facts(),42,{})
		assert_str(JSON.stringify(a)).is_equal(JSON.stringify(b))
		assert_str(JSON.stringify(Director.asides_for(event,hungry_facts(),home_cast(),42,{}))).is_equal(JSON.stringify(Director.asides_for(event,hungry_facts(),home_cast(),42,{})))
	assert_str(JSON.stringify(Director.ambient(home_cast(),hungry_facts(),9))).is_equal(JSON.stringify(Director.ambient(home_cast(),hungry_facts(),9)))

func test_variety_holds_over_two_hundred_events()->void:
	var memory:={}
	var rng:=RandomNumberGenerator.new();rng.seed=1234
	var pool:=events()
	var last_sig:={}
	var bit_uses:={}
	var signatures:={}
	for i in 200:
		var event:Dictionary=pool[rng.randi_range(0,pool.size()-1)]
		var facts:=hungry_facts();facts["day"]=4000+i*7
		var list:=Director.beats_for(event,home_cast(),facts,1000+i,memory)
		var sig:=Director._signature(list)
		var kind:=String(event.kind)
		if not sig.is_empty():
			assert_str(sig).override_failure_message("%s played identically twice running (event %d)" % [kind,i]).is_not_equal(String(last_sig.get(kind,"")))
			last_sig[kind]=sig
		signatures[sig]=true
		for bit in memory.get("bits",{}):
			if int(memory.bits[bit])==int(memory.n):bit_uses[bit]=int(bit_uses.get(bit,0))+1
		Director.asides_for(event,facts,home_cast(),1000+i,memory)
	assert_int(bit_uses.size()).override_failure_message("only %d comic bits used: %s" % [bit_uses.size(),bit_uses]).is_greater_equal(12)
	assert_int(signatures.size()).is_greater_equal(120)

func test_the_same_terror_plays_differently_each_time()->void:
	var memory:={}
	var seen:={}
	var event:={"kind":"divine","action":"terrify","target":"main","response":"cower"}
	for i in 30:seen[Director._signature(Director.beats_for(event,home_cast(),hungry_facts(),500+i,memory))]=true
	assert_int(seen.size()).is_greater_equal(24)

## A long campaign: 1000 mixed events over 20 game years, through two ages
## and every season, with hunger, sickness and a war coming and going, the
## court changing, envoys of every temper, summoned strangers and children.
## No bit plays in more than about one event in twelve; no muttered line
## comes back within three game years.
func test_a_long_campaign_stays_fresh()->void:
	var report:=_campaign(1000,20261003)
	var shares:Dictionary=report.shares
	for bit in shares:
		assert_float(float(shares[bit])).override_failure_message("%s played in %.1f%% of events" % [bit,float(shares[bit])*100.0]).is_less_equal(0.085)
	assert_int(int(report.line_repeats_within_3y)).is_equal(0)
	assert_int(int(report.bits_used)).is_greater_equal(25)
	assert_int(int(report.asides)).is_between(40,220)
	print(String(report.text))

func _campaign(count:int,rng_seed:int)->Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=rng_seed
	var memory:={}
	var court:=[
		{"key":"p1","role":"court","kind":"official","name":"Orrin Vael","age":47,"courage":0.75,"pride":0.8,"love":0.35,"dread":0.15,"voice":"achilles"},
		{"key":"p2","role":"court","kind":"official","name":"Suri Danek","age":33,"courage":0.3,"pride":0.3,"love":0.6,"dread":0.55,"voice":"falstaff"},
		{"key":"p3","role":"court","kind":"hearth_chief","name":"Kavu Mbeli","age":41,"courage":0.35,"pride":0.2,"love":0.7,"dread":0.4,"voice":"polonius"},
		{"key":"p4","role":"court","kind":"official","name":"Tamsin Oru","age":29,"courage":0.6,"pride":0.45,"love":0.5,"dread":0.2,"empathy":0.8,"voice":"atticus"},
		{"key":"p5","role":"court","kind":"official","name":"Gedde Ran","age":63,"courage":0.7,"pride":0.6,"love":0.4,"dread":0.1,"voice":"grant","stance":"staff"},
		{"key":"p6","role":"court","kind":"hearth_chief","name":"Mirel Ost","age":52,"courage":0.5,"pride":0.7,"love":0.3,"dread":0.25,"voice":"iago"},
		{"key":"p7","role":"court","kind":"official","name":"Juno Pell","age":36,"courage":0.55,"pride":0.5,"love":0.65,"dread":0.3,"voice":"lincoln"},
	]
	var total:=0
	var day:=0
	var bit_events:={}
	var line_last:={}
	var line_counts:={}
	var repeats:=0
	var asides:=0
	var kinds:={}
	var audience:=0
	var examples:Array=[]
	while total<count:
		audience+=1
		day+=rng.randi_range(48,78)
		var year:=day/365
		var tags:Array=[]
		var tier:=0
		if year>=7:tags=["farming","pottery","dairy"];tier=1
		if year>=14:tags=["farming","pottery","dairy","writing","metal"];tier=2
		var season:=String(SEASONS[int(floor((float(day)+45.0)/91.25))%4])
		var facts:={"day":day,"season":season,"era_tags":tags,"era_tier":tier,"food_days":[60,40,22,12,8,30,90][(year/2+audience/9)%7],
			"people_dread":[0.2,0.3,0.4,0.6,0.25][(year/3)%5],"people_love":[0.5,0.6,0.4,0.7][(year/4)%4]}
		if year%5==2:facts["sickness"]={"name":"the Grey Fever","deaths":2+year%7}
		if year%6>=3:facts["war"]={"enemy":"Kelvar","kind":"feud"}
		var cast:Array=[]
		var roll:=rng.randf()
		var main:Dictionary
		var envoy:=false
		if roll<0.22:
			envoy=true
			main={"key":"main","role":"main","kind":"envoy","name":"Envoy %d" % audience,"age":40,"courage":rng.randf(),"pride":rng.randf(),"temper":["haughty","nervous","greedy","calm"][rng.randi_range(0,3)]}
			facts["envoy"]={"civ":["Ashwen","Kelvar","Tossa"][rng.randi_range(0,2)],"days_waiting":rng.randi_range(1,9),"their_food_days":rng.randi_range(8,60)}
			if rng.randf()<0.4:facts["gift"]={"resource":["Food","Timber","Stone"][rng.randi_range(0,2)],"amount":rng.randi_range(10,60)}
			cast=[main,{"key":"att0","role":"attendant","kind":"guard","name":"Dov","age":26},{"key":"att1","role":"attendant","kind":"bearer","name":"Nel","age":22}]
		elif roll<0.27:main={"key":"main","role":"main","kind":"commoner","name":"Bo Narra %d" % audience,"age":30,"courage":0.4,"pride":0.2,"dread":0.4}
		elif roll<0.30:main={"key":"main","role":"main","kind":"child","name":"Tiri %d" % audience,"age":8,"courage":0.6,"pride":0.3,"dread":0.2,"gifted":"Logistics" if rng.randf()<0.3 else ""}
		else:
			var who:Dictionary=(court[rng.randi_range(0,court.size()-1)] as Dictionary).duplicate()
			who["key"]="main";who["role"]="main"
			main=who
		if not envoy:cast=[main]
		var present:=_shuffled_copy(court,rng).slice(0,rng.randi_range(3,5))
		for o:Dictionary in present:
			if String(o.name)!=String(main.name):cast.append(o)
		cast+=Director.extras(facts,audience)
		var x:=0.05
		for c:Dictionary in cast:c["x"]=x;x+=0.09
		var plan:Array=[{"kind":"summon","who":"main"}]
		if envoy and facts.has("gift"):plan.append({"kind":"gift","accepted":rng.randf()<0.7,"resource":String(facts.gift.resource),"amount":int(facts.gift.amount),"who":"main"})
		for i in rng.randi_range(2,5):
			plan.append({"kind":"line","who":"main" if i%2==0 else String((present[0] as Dictionary).key),"text":["We need %d more hands at the pits." % rng.randi_range(3,40),"The pens are full.","They came by the river path.","It will take %d days." % rng.randi_range(2,30)][rng.randi_range(0,3)]})
			if rng.randf()<0.5:plan.append({"kind":"god_speaks","text":"Go on."})
		var r:=rng.randf()*0.8
		if envoy:
			if r<0.12:plan.append({"kind":"terrify_envoy","response":["defy","cower"][rng.randi_range(0,1)],"target":"main"})
			elif r<0.2:plan.append({"kind":"envoy_insulted","who":"main"})
			plan.append({"kind":"decree","who":"main","accepted":rng.randf()<0.6,"reaction":["pleased","neutral","offended"][rng.randi_range(0,2)],"cost":{"resource":"Food","amount":rng.randi_range(5,40)} if rng.randf()<0.4 else {}})
		else:
			if r<0.1:plan.append({"kind":"divine","action":"terrify","target":"main","response":["cower","endure","defy"][rng.randi_range(0,2)]})
			elif r<0.16:plan.append({"kind":"divine","action":["bless","boon","raise_up"][rng.randi_range(0,2)],"target":"main","response":"blessed","terms":{"resource":"Food","amount":rng.randi_range(5,20)}})
			elif r<0.2:plan.append({"kind":"divine","action":"penance","target":"main","response":"endure"})
			elif r<0.27:plan.append({"kind":"command","verb":"order","stage":"none","actor":String((present[0] as Dictionary).key),"target":"","obedience":"obey","executed":false})
			elif r<0.33:plan.append({"kind":"wait","who":"main"})
			elif r<0.35:plan.append({"kind":"divine","action":"strike_down","target":"main","terminal":true})
			var answer:=rng.randf()
			if answer<0.4:plan.append({"kind":"decree","who":"main","accepted":true,"reaction":"pleased","cost":{"resource":"Food","amount":rng.randi_range(5,40)} if rng.randf()<0.3 else {}})
			elif answer<0.6:plan.append({"kind":"promise","who":"main"})
			elif answer<0.8:plan.append({"kind":"dismiss","who":"main","reaction":["offended","furious","neutral"][rng.randi_range(0,2)]})
			else:plan.append({"kind":"decree","issued":true,"accepted":true})
		var dead:=plan.any(func(e:Dictionary)->bool:return String(e.get("action",""))=="strike_down")
		if not dead:plan.append({"kind":"exit","who":"main","style":["bow","bow","storm"][rng.randi_range(0,2)],"reaction":["pleased","delighted","furious"][rng.randi_range(0,2)]})
		for event:Dictionary in plan:
			if total>=count:break
			var seed_value:=hash("%d|%d" % [audience,total])
			Director.beats_for(event,cast,facts,seed_value,memory)
			kinds[String(event.kind)]=int(kinds.get(String(event.kind),0))+1
			for bit in memory.get("bits",{}):
				if int(memory.bits[bit])==int(memory.n):bit_events[bit]=int(bit_events.get(bit,0))+1
			for line:Dictionary in Director.asides_for(event,facts,cast,seed_value,memory):
				asides+=1
				var id:=String(line.line_id)
				if line_last.has(id) and day-int(line_last[id])<1095:repeats+=1
				line_last[id]=day
				line_counts[id]=int(line_counts.get(id,0))+1
				if examples.size()<24:examples.append("    y%-2d %-16s %-10s \"%s\"" % [day/365,String(line.situation),String((cast.filter(func(c:Dictionary)->bool:return String(c.key)==String(line.who))[0] as Dictionary).get("kind","")),String(line.text)])
			total+=1
	var shares:={}
	for bit in bit_events:shares[bit]=float(bit_events[bit])/float(total)
	var rows:PackedStringArray=PackedStringArray(["","=== LONG CAMPAIGN: %d events, %d audiences, %d years ===" % [total,audience,day/365],"Bits (share of events):"])
	var ordered:=shares.keys()
	ordered.sort_custom(func(a,b)->bool:return float(shares[a])>float(shares[b]))
	for bit in ordered:rows.append("  %-16s %4d  %5.1f%%" % [bit,int(bit_events[bit]),float(shares[bit])*100.0])
	var most:=0
	for id in line_counts:most=maxi(most,int(line_counts[id]))
	rows.append("Muttered lines: %d in %d events (1 in %.1f); %d different lines; most-said line %d times; repeats within 3 years: %d" % [asides,total,float(total)/maxf(1.0,float(asides)),line_counts.size(),most,repeats])
	rows.append("Event mix: %s" % JSON.stringify(kinds))
	rows.append("The first muttered lines (year, situation, who, words):")
	rows.append_array(PackedStringArray(examples))
	return {"shares":shares,"line_repeats_within_3y":repeats,"bits_used":bit_events.size(),"asides":asides,"text":"\n".join(rows)}

func _shuffled_copy(list:Array,rng:RandomNumberGenerator)->Array:
	var out:=list.duplicate()
	for i in range(out.size()-1,0,-1):
		var j:=rng.randi_range(0,i)
		var swap:Variant=out[i];out[i]=out[j];out[j]=swap
	return out

# --- The shape of a moment -----------------------------------------------------------------

func test_anticipation_then_action_then_reaction_then_hold()->void:
	for seed_value in 30:
		var list:=Director.beats_for({"kind":"divine","action":"terrify","target":"main","response":"cower"},home_cast(),hungry_facts(),seed_value)
		var first:={}
		for beat:Dictionary in list:
			var phase:=String(beat.phase)
			if not first.has(phase):first[phase]=float(beat.t)
		assert_float(float(first.get("anticipation",-1.0))).is_equal(0.0)
		assert_float(float(first.action)).is_greater(float(first.anticipation))
		assert_float(float(first.reaction)).is_greater_equal(float(first.action))
		assert_float(float(first.hold)).is_greater(float(first.reaction))
		assert_bool(_did(list,"camera","push_in")).is_true()

func test_the_room_lifts_its_faces_when_the_god_speaks()->void:
	var list:=Director.beats_for({"kind":"god_speaks","text":"Speak."},home_cast(),full_facts(60),5)
	var lifted:={}
	for beat:Dictionary in list:
		if String(beat.act) in ["look_up","late_lift"]:lifted[String(beat.who)]=true
	# Everyone but a sleeper still asleep, and the goat, who does not care.
	assert_int(lifted.size()).is_greater_equal(6)
	assert_bool(lifted.has("goat")).is_false()

func test_the_sleeper_wakes_and_stays_awake_a_while()->void:
	var memory:={}
	var woke_at:=-1
	for i in 60:
		var list:=Director.beats_for({"kind":"god_speaks","text":"Speak."},home_cast(),full_facts(60),i,memory)
		if _did(list,"c1","jerk_awake"):
			if woke_at>=0:assert_int(i-woke_at).is_greater_equal(Director.DOZE_AGAIN)
			woke_at=i
	assert_int(woke_at).is_greater_equal(0)
	var dread:=full_facts(60);dread["people_dread"]=0.7
	assert_str(Director.dozer(home_cast(),dread)).is_empty()

# --- Adapters and the stage's shapes ---------------------------------------------------------

func test_adapters_read_the_engines_results()->void:
	var cast:=home_cast()
	cast[1]["person_id"]=11;cast[2]["person_id"]=12
	var divine:={"ok":true,"action":"terrify","terminal":false,"person_id":5,"response":"defy","effects":{"witnesses":{11:{"response":"unbowed"},12:{"response":"shaken"}}}}
	var e:=Director.event_from_divine(divine,cast,5)
	assert_str(String(e.kind)).is_equal("divine")
	assert_str(String(e.target)).is_equal("main")
	assert_str(String(e.response)).is_equal("defy")
	assert_str(String((e.witnesses as Dictionary).get("p1",""))).is_equal("unbowed")
	var envoy:=Director.event_from_divine({"ok":true,"action":"terrify","person_id":0,"response":"cower"},cast,5)
	assert_str(String(envoy.kind)).is_equal("terrify_envoy")
	var command:={"verb":"detain","stage":"refuse_seized","actor":{"person_id":11,"name":"Orrin Vael"},"target":{"speaker":true,"person_id":5},"obedience":{"id":"refuse","manner":"defiant"}}
	var c:=Director.event_from_command(command,cast,5)
	assert_str(String(c.actor)).is_equal("p1")
	assert_str(String(c.target)).is_equal("main")
	assert_str(String(c.obedience)).is_equal("refuse")
	assert_str(String(Director.event_from_command({"verb":"law"},cast,5).kind)).is_equal("decree")
	var gift:=Director.event_from_resolution({"kind":"gift","terms":{"resource":"Food","amount":40}},"refuse",{"reaction":"offended"})
	assert_bool(bool(gift.accepted)).is_false()
	assert_str(String(Director.event_from_resolution({"kind":"petition"},"promise",{"reaction":"pleased"}).kind)).is_equal("promise")
	assert_str(String(Director.event_from_resolution({"kind":"petition"},"dismiss",{"reaction":"furious"}).kind)).is_equal("dismiss")
	var grant:=Director.event_from_resolution({"kind":"request","terms":{"resource":"Food","amount":30}},"grant",{"reaction":"pleased"})
	assert_int(int((grant.cost as Dictionary).amount)).is_equal(30)
	assert_str(String(Director.event_from_line({"role":"ruler","text":"Kneel."},"").kind)).is_equal("god_speaks")
	assert_str(String(Director.event_wait().kind)).is_equal("wait")

## A cast as the stage hands it over: {key, role, person, figure, mood}.
static func stage_cast()->Array:
	var person:=func(pid:int,name:String,courage:float,pride:float,fear:float,extra:Dictionary={})->Dictionary:
		var p:={"person_id":pid,"name":name,"courage":courage,"pride":pride,"age":40,"personality":{"empathy":0.5},
			"relationships":{"sovereign":{"fear":fear,"trust":0.6,"respect":0.5,"obligation":0.4,"resentment":0.1}}}
		p.merge(extra,true)
		return p
	return [
		{"key":"main","role":"main","person":person.call(5,"Hena Tuvasi",0.9,0.9,0.05),"figure":null,"mood":"neutral"},
		{"key":"p11","role":"court","person":person.call(11,"Orrin Vael",0.75,0.8,0.1),"figure":null,"mood":"neutral"},
		{"key":"p12","role":"court","person":person.call(12,"Suri Danek",0.3,0.3,0.6),"figure":null,"mood":"afraid"},
		{"key":"p13","role":"court","person":person.call(13,"Kavu Mbeli",0.35,0.2,0.4,{"office_key":"settlement","title":"Hearth chief"}),"figure":null,"mood":"neutral"},
	]

func test_the_stage_object_speaks_the_stages_primitives()->void:
	var director:=Director.new()
	var facts:={"era":"stone","season":"winter","stores_days":9,"hungry":true,"sick":false,"at_war":false,"love":0.4,"dread":0.3}
	var seen:={}
	for i in 40:
		var list:=director.beats({"kind":"divine","action":"penance","response":"defy"},stage_cast(),facts,i)
		for beat:Dictionary in list:
			seen[String(beat.act)]=true
			assert_bool(String(beat.act) in ["play","look_at","mood","shot","hush"]).override_failure_message("not a stage primitive: %s" % beat.act).is_true()
			if String(beat.who)=="main":
				assert_bool(String((beat.args as Dictionary).get("beat","")) in Director.KNEEL_LIKE).override_failure_message("main defied but %s" % beat.args).is_false()
				assert_str(String((beat.args as Dictionary).get("fallback",""))).is_not_equal("kneel")
				assert_str(String((beat.args as Dictionary).get("fallback",""))).is_not_equal("bow")
		for line:Dictionary in director.asides({"kind":"divine","action":"penance","response":"defy"},facts,stage_cast(),i):
			assert_str(String(line.act)).is_equal("aside")
			assert_str(String((line.args as Dictionary).text)).is_equal(String(line.text))
	assert_bool(seen.has("play") and seen.has("mood") and seen.has("look_at") and seen.has("shot")).is_true()
	assert_int(int(director.stage_memory.get("n",0))).is_equal(40)

func test_the_stages_facts_and_events_are_read()->void:
	var facts:=Director.normal_facts({"stores_days":40,"hungry":false,"sick":true,"at_war":false,"love":0.7,"dread":0.1})
	assert_int(int(facts.food_days)).is_equal(40)
	assert_bool(Director.sickness(facts).is_empty()).is_false()
	assert_bool(Director.war(facts).is_empty()).is_true()
	assert_float(Director.people_love(facts)).is_equal(0.7)
	assert_bool(Director.hungry(Director.normal_facts({"hungry":true}))).is_true()
	var cast:=Director.normal_cast(stage_cast(),facts)
	assert_str(String((cast[3] as Dictionary).kind)).is_equal("hearth_chief")
	assert_float(float((cast[2] as Dictionary).dread)).is_equal(0.6)
	assert_str(String(Director.normal_event({"kind":"god","text":"Speak."},cast).kind)).is_equal("god_speaks")
	assert_str(String(Director.normal_event({"kind":"enter","who":"main"},cast).kind)).is_equal("summon")
	assert_str(String(Director.normal_event({"kind":"defer"},cast).kind)).is_equal("wait")
	var envoy_stage:=[{"key":"main","role":"main","person":{"name":"Ishkar Velu","role":"envoy","person_id":0}},{"key":"att0","role":"attendant","person":{"name":"Dov"}}]
	var normal:=Director.normal_cast(envoy_stage,{"offer":{"resource":"Food","amount":40},"envoy":{"kind":"threat","temperament":"Proud guardian"}})
	assert_str(String((normal[0] as Dictionary).kind)).is_equal("envoy")
	assert_str(String((normal[0] as Dictionary).temper)).is_equal("haughty")
	assert_str(String((normal[1] as Dictionary).kind)).is_equal("bearer")
	assert_str(String(Director.normal_event({"kind":"divine","action":"terrify","response":"cower"},normal).kind)).is_equal("terrify_envoy")
	var flog:=Director.normal_event({"kind":"divine","action":"envoy_flog"},normal)
	assert_str(String(flog.kind)).is_equal("command")
	assert_str(String(flog.verb)).is_equal("maim")
	var whole:=Director.normal_event({"kind":"divine","result":{"ok":true,"action":"terrify","person_id":5,"response":"defy"}},Director.normal_cast(stage_cast(),facts))
	assert_str(String(whole.response)).is_equal("defy")
	assert_str(String(whole.target)).is_equal("main")
	assert_str(Director.envoy_temper({"their_dread":0.6,"kind":"threat"})).is_equal("nervous")
	assert_str(Director.envoy_temper({"trait":"magpie"})).is_equal("greedy")
	assert_str(Director.envoy_temper({"temperament":"Bridge-builder","kind":"gift"})).is_equal("calm")

func test_every_act_has_a_way_to_be_played()->void:
	var memory:={}
	for event:Dictionary in events()+envoy_events():
		for beat:Dictionary in Director.beats_for(event,home_cast() if not String(event.kind) in ["gift","terrify_envoy","envoy_insulted"] else envoy_cast(),hungry_facts(),8,memory):
			assert_bool(Director.ACTS.has(String(beat.act))).override_failure_message("no acting entry for %s" % beat.act).is_true()
	for loop:Dictionary in Director.ambient(envoy_cast("greedy"),hungry_facts(),8):assert_bool(Director.ACTS.has(String(loop.act))).is_true()
	var kneel:=Director.performance({"act":"kneel","args":{}})
	assert_str(String(kneel.clip)).is_equal("kneel")
	assert_bool(bool(kneel.hold)).is_true()
	assert_str(String(Director.performance({"act":"stand_firm","args":{}}).mood)).is_equal("defiant")

# --- For the coordinator: a sample screenplay ------------------------------------------------

func test_print_a_screenplay()->void:
	var memory:={}
	var stone:={"day":900,"food_days":9,"population":180,"season":"winter","era_tags":[],"era_tier":0,"people_dread":0.3,"people_love":0.5,
		"sickness":{"name":"the Marsh Cough","deaths":3}}
	var letters:={"day":5900,"food_days":44,"population":1400,"season":"summer","era_tags":["farming","pottery","dairy","writing","metal"],"era_tier":2,
		"people_dread":0.25,"people_love":0.6,"war":{"enemy":"Kelvar","kind":"war"},"envoy":{"civ":"Kelvar","days_waiting":6,"their_food_days":30}}
	var letters_gift:=letters.duplicate(true);letters_gift["gift"]={"resource":"Food","amount":40}
	var stone_hall:=home_cast().slice(0,8)+[{"key":"dog","role":"animal","kind":"dog","name":"the dog","x":0.47}]
	var grand_hall:=home_cast()+[{"key":"scribe","role":"crowd","kind":"scribe","name":"Pell Ardo","age":44,"courage":0.6,"pride":0.6,"dread":0.2,"x":0.6},
		{"key":"door_guard","role":"crowd","kind":"door_guard","name":"Hal","age":30,"courage":0.8,"pride":0.5,"x":0.99}]
	var nervous_official:=grand_hall.duplicate(true);nervous_official[0]={"key":"main","role":"main","kind":"official","name":"Bren Toll","age":34,"courage":0.3,"pride":0.3,"love":0.5,"dread":0.6,"voice":"polonius","x":0.40}
	var stranger:=stone_hall.duplicate(true);stranger[0]={"key":"main","role":"main","kind":"commoner","name":"Bo Narra","age":30,"courage":0.4,"pride":0.2,"dread":0.4,"x":0.40}
	var haughty:=[{"key":"main","role":"main","kind":"envoy","name":"Ishkar Velu","age":44,"courage":0.7,"pride":0.8,"temper":"haughty","x":0.26},
		{"key":"att0","role":"attendant","kind":"guard","name":"Dov","age":26,"x":0.09},{"key":"att1","role":"attendant","kind":"bearer","name":"Nel","age":22,"x":0.42}]+grand_hall.slice(1)
	var scenes:=[
		["STONE AGE, WINTER. A stranger from the camp is summoned",{"kind":"summon","who":"main"},stranger,stone],
		["STONE AGE, WINTER. The god speaks",{"kind":"god_speaks","text":"Tell me what you saw."},stranger,stone],
		["STONE AGE, WINTER. Wrath on the stranger, who cowers",{"kind":"divine","action":"terrify","target":"main","response":"cower","witnesses":{"p1":"unbowed"}},stranger,stone],
		["STONE AGE, WINTER. The god makes them wait",{"kind":"wait","who":"main"},stranger,stone],
		["STONE AGE, WINTER. Promise: 'consider it'",{"kind":"promise","who":"main"},stranger,stone],
		["LETTERS AND METAL, SUMMER. A nervous official is summoned",{"kind":"summon","who":"main"},nervous_official,letters],
		["LETTERS AND METAL, SUMMER. A decree granted, costing 30 food",{"kind":"decree","who":"main","accepted":true,"reaction":"delighted","cost":{"resource":"Food","amount":30}},nervous_official,letters],
		["LETTERS AND METAL, SUMMER. They leave pleased",{"kind":"exit","who":"main","style":"bow","reaction":"delighted"},nervous_official,letters],
		["LETTERS AND METAL, SUMMER, AT WAR WITH KELVAR. A haughty envoy of Kelvar arrives",{"kind":"summon","who":"main"},haughty,letters],
		["LETTERS AND METAL, SUMMER. The god turns away Kelvar's gift of 40 food",{"kind":"gift","accepted":false,"resource":"Food","amount":40,"who":"main"},haughty,letters_gift],
		["LETTERS AND METAL, SUMMER. The envoy storms out",{"kind":"exit","who":"main","style":"storm","reaction":"furious"},haughty,letters_gift],
	]
	var text:PackedStringArray=PackedStringArray(["","=== SCREENPLAY ==="])
	var i:=0
	for scene:Array in scenes:
		text.append("-- %s" % scene[0])
		text.append(Director.screenplay(scene[1],scene[2],scene[3],77+i*13,memory))
		i+=1
	print("\n".join(text))

# --- Helpers ------------------------------------------------------------------------------------

func _did(list:Array,who:String,act:String)->bool:
	for beat:Dictionary in list:
		if String(beat.who)==who and String(beat.act)==act:return true
	return false
