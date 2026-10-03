extends GdUnitTestSuite
## THE COURT'S DIRECTOR (scripts/hud/court_director.gd, court_asides.gd).
## The whole room acts out what the engine decided, with comic timing, and
## never contradicts it:
## - one the engine says defied the god never kneels, bows or shakes;
## - nobody is hungry on stage while the stores are full; no cough without a
##   sickness, no spears without a war;
## - a muttered line cites only what the fact sheet and the event hold, in
##   plain speech of the people's own age;
## - the same seed gives the same beats, and two hundred events in a row do
##   not go stale.
## Pure: no game state is read or written.

const Director:=preload("res://scripts/hud/court_director.gd")
const Asides:=preload("res://scripts/hud/court_asides.gd")
const CV:=preload("res://scripts/character_voice.gd")
const Plain:=preload("res://scripts/plain_speech.gd")

const NUMBER_WORDS:={"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12}

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

static func envoy_cast()->Array:
	var out:Array=[
		{"key":"main","role":"main","kind":"envoy","name":"Ishkar Velu","age":44,"courage":0.6,"pride":0.6,"x":0.26},
		{"key":"att0","role":"attendant","kind":"guard","name":"Dov","age":26,"x":0.09},
		{"key":"att1","role":"attendant","kind":"bearer","name":"Nel","age":22,"x":0.42},
	]
	for entry:Dictionary in home_cast():
		if String(entry.key)!="main" and String(entry.key)!="goat":out.append(entry)
	return out

static func hungry_facts()->Dictionary:
	return {"food_days":9,"population":214,"season":"winter","era_tags":[],"era_tier":0,"people_dread":0.35,"people_love":0.5,
		"sickness":{"name":"the Marsh Cough","deaths":3},"war":{"enemy":"Kelvar","kind":"feud"},
		"envoy":{"civ":"Ashwen","days_waiting":4,"their_food_days":25},"gift":{"resource":"Food","amount":40}}

static func full_facts(days:int)->Dictionary:
	return {"food_days":days,"population":214,"season":"summer","era_tags":["farming","pottery"],"era_tier":1,"people_dread":0.2,"people_love":0.55}

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
		{"kind":"decree","who":"main","accepted":false,"reaction":"offended"},
		{"kind":"promise","who":"main"},
		{"kind":"dismiss","who":"main"},
		{"kind":"summon","who":"main"},
		{"kind":"exit","who":"main","style":"storm"},
		{"kind":"exit","who":"main","style":"bow"},
	]

static func envoy_events()->Array:
	return [
		{"kind":"gift","accepted":true,"resource":"Food","amount":40,"who":"main"},
		{"kind":"gift","accepted":false,"resource":"Food","amount":40,"who":"main"},
		{"kind":"gift","accepted":true,"resource":"Timber","amount":25,"who":"main"},
		{"kind":"terrify_envoy","response":"defy","target":"main"},
		{"kind":"terrify_envoy","response":"cower","target":"main"},
		{"kind":"envoy_insulted","who":"main"},
		{"kind":"line","who":"main","text":"My ruler sends greetings and asks that you remember the river crossing, where our hunters and yours met last summer, and the 12 days it took us to come here."},
		{"kind":"decree","who":"main","accepted":true,"reaction":"pleased","terms":{"resource":"Food","amount":30}},
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
			for beat:Dictionary in Director.beats(event,home_cast(),hungry_facts(),seed_value,memory):
				if String(beat.who)==String(event.target):
					assert_bool(String(beat.act) in Director.KNEEL_LIKE or String(beat.act)=="kneel_bound").override_failure_message(
						"%s defied the god but was shown to %s (seed %d)" % [event.target,beat.act,seed_value]).is_false()
		for beat:Dictionary in Director.beats({"kind":"terrify_envoy","response":"defy","target":"main"},envoy_cast(),hungry_facts(),seed_value,memory):
			if String(beat.who)=="main":assert_bool(String(beat.act) in Director.KNEEL_LIKE).override_failure_message("the envoy defied but %s" % beat.act).is_false()

func test_defiance_stands_firm_and_cowering_goes_down()->void:
	var firm:=Director.beats({"kind":"divine","action":"terrify","target":"main","response":"defy"},home_cast(),full_facts(60),3)
	var cowed:=Director.beats({"kind":"divine","action":"terrify","target":"main","response":"cower"},home_cast(),full_facts(60),3)
	assert_bool(_did(firm,"main","stand_firm")).is_true()
	assert_bool(_did(cowed,"main","kneel")).is_true()
	assert_bool(_did(cowed,"main","stand_firm")).is_false()

func test_a_refusal_never_bows_and_seized_is_forced_down_bound()->void:
	for seed_value in 60:
		var seized:=Director.beats({"kind":"command","verb":"detain","stage":"refuse_seized","actor":"p1","target":"main","obedience":"refuse"},home_cast(),hungry_facts(),seed_value)
		var fled:=Director.beats({"kind":"command","verb":"exile","stage":"refuse_flee","actor":"p1","target":"main","obedience":"refuse"},home_cast(),hungry_facts(),seed_value)
		for beat:Dictionary in seized+fled:
			if String(beat.who)=="p1":assert_bool(String(beat.act) in Director.KNEEL_LIKE).override_failure_message("p1 refused but %s" % beat.act).is_false()
		assert_bool(_did(seized,"p1","kneel_bound")).is_true()
		assert_bool(_did(fled,"p1","kneel_bound")).is_false()
		assert_bool(_did(fled,"p1","bolt")).is_true()

func test_the_dead_do_nothing_more_and_nobody_laughs()->void:
	var memory:={}
	for seed_value in 80:
		var event:={"kind":"divine","action":"strike_down","target":"main","terminal":true}
		var list:=Director.beats(event,home_cast(),hungry_facts(),seed_value,memory)
		for beat:Dictionary in list:
			assert_bool(String(beat.act) in Director.COMIC_ACTS).override_failure_message("comedy at a death: %s %s" % [beat.who,beat.act]).is_false()
			if String(beat.who)=="main":assert_str(String(beat.act)).is_equal("stricken")
		assert_bool(_did(list,"c1","cover_eyes") or _did(list,"p4","cover_eyes") or _did(list,"c3","cover_eyes")).override_failure_message("nobody covered the child's eyes").is_true()
		assert_array(Director.asides(event,hungry_facts(),home_cast(),seed_value,memory)).is_empty()

# --- Only what the facts hold -------------------------------------------------------

func test_nobody_is_hungry_while_the_stores_are_full()->void:
	for days in [16,35,120,400]:
		for seed_value in 60:
			var facts:=full_facts(days)
			facts["gift"]={"resource":"Food","amount":40}
			for cast in [home_cast(),envoy_cast()]:
				for loop:Dictionary in Director.ambient(cast,facts,seed_value):
					assert_bool(String(loop.act) in Director.HUNGER_ACTS).override_failure_message("hunger shown with %d days of food: %s" % [days,loop.act]).is_false()
			for event:Dictionary in [{"kind":"divine","action":"boon","target":"p4","response":"blessed","terms":{"resource":"Food","amount":12}},{"kind":"divine","action":"penance","target":"main","response":"endure"}]:
				for beat:Dictionary in Director.beats(event,home_cast(),facts,seed_value):
					assert_bool(String(beat.act) in Director.HUNGER_ACTS).override_failure_message("hungry beat with %d days: %s" % [days,beat.act]).is_false()
			for beat:Dictionary in Director.beats({"kind":"gift","accepted":true,"resource":"Food","amount":40,"who":"main"},envoy_cast(),facts,seed_value):
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
			for beat:Dictionary in Director.beats(event,home_cast(),calm,seed_value,memory):
				assert_bool(String(beat.act) in Director.SICK_ACTS+Director.WAR_ACTS).override_failure_message("%s in %s with no sickness or war" % [beat.act,event.kind]).is_false()
	var acts:={}
	for loop:Dictionary in Director.ambient(home_cast(),hungry_facts(),4):acts[String(loop.act)]=String(loop.because)
	assert_bool(acts.has("cough")).is_true()
	assert_bool(acts.has("sharpen_spear")).is_true()
	assert_str(String(acts.get("cough",""))).is_equal("sickness")

# --- Words from the facts only --------------------------------------------------------

func test_asides_cite_only_facts_present()->void:
	var said:=0
	var runs:=[[home_cast(),events()],[envoy_cast(),envoy_events()]]
	for facts:Dictionary in [hungry_facts(),full_facts(80),{"season":"spring"}]:
		for run:Array in runs:
			var memory:={}
			var cast:Array=run[0]
			for seed_value in 30:
				var last_had:=false
				for event:Dictionary in run[1]:
					Director.beats(event,cast,facts,seed_value,memory)
					var lines:=Director.asides(event,facts,cast,seed_value,memory)
					assert_int(lines.size()).is_less_equal(1)
					assert_bool(last_had and not lines.is_empty()).override_failure_message("two muttered lines running").is_false()
					last_had=not lines.is_empty()
					for line:Dictionary in lines:
						said+=1
						_check_aside(line,event,facts,cast)
	assert_int(said).is_greater(20)

func _check_aside(line:Dictionary,event:Dictionary,facts:Dictionary,cast:Array)->void:
	var text:=String(line.text)
	var who:=String(line.who)
	assert_bool(who in ["main","god","",String(event.get("target","")),String(event.get("actor",""))]).override_failure_message("%s should not mutter: %s" % [who,text]).is_false()
	var keys:=cast.map(func(c:Dictionary)->String:return String(c.key))
	assert_bool(who in keys).is_true()
	# Every cited fact is in the sheet, the event or the cast.
	for cite in line.cites:
		assert_bool(_resolves(String(cite),event,facts,cast)).override_failure_message("'%s' cites %s, which is not there" % [text,cite]).is_true()
	# Every number said is a number the sheet or the event holds.
	var allowed:=_numbers(facts)+_numbers(event)
	var said:=String(event.get("text",""))
	var hit:=Director.number_in(said)
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
		"facts":
			var at:Variant=facts
			for i in range(1,parts.size()):
				if not at is Dictionary or not (at as Dictionary).has(parts[i]):return false
				at=(at as Dictionary)[parts[i]]
			return true
		"event":
			match parts[1]:
				"amount":return (event.get("terms",{}) as Dictionary).has("amount") or event.has("amount")
				"resource":return (event.get("terms",{}) as Dictionary).has("resource") or event.has("resource")
				"text":return event.has("text")
			return event.has(parts[1])
		"cast":
			for c:Dictionary in cast:
				if String(c.key)==parts[1]:return true
	return false

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

func test_every_muttered_line_is_plain_and_of_any_age()->void:
	var slots:={"amount":"twelve","resource":"food","food_days":"nine","name":"Hena","number":"forty","days_waiting":"four","envoy_civ":"Ashwen","enemy":"Kelvar","sickness":"the Marsh Cough","deaths":"three"}
	for entry:Dictionary in Asides.all_templates():
		var text:=Asides.render(String(entry.text),slots)
		assert_str(text).override_failure_message("unfilled: %s" % entry.text).is_not_empty()
		assert_bool(Plain.is_maxim(text)).override_failure_message("a maxim (%s): %s" % [entry.situation,text]).is_false()
		# Muttered lines carry no gated words at all: they fit the oldest age.
		assert_array(CV.lexicon_hits(text,[])).override_failure_message("era words in: %s" % text).is_empty()
		assert_bool(CV.imitation_ok(text)).is_true()
		assert_bool(text.to_lower().contains("god says") or text.to_lower().begins_with("i am your god")).is_false()

func test_an_aside_needs_its_facts()->void:
	# Food gift to a hall whose stores are not on the sheet: no line about days of food.
	var memory:={}
	for seed_value in 200:
		for line:Dictionary in Director.asides({"kind":"divine","action":"boon","target":"p4","response":"blessed","terms":{"resource":"Food","amount":12}},{"season":"spring"},home_cast(),seed_value,memory):
			assert_bool("facts.food_days" in line.cites).is_false()
			assert_str(String(line.situation)).is_not_equal("boon_hungry")

# --- Same seed, and never stale ----------------------------------------------------------

func test_the_same_seed_gives_the_same_beats()->void:
	for event:Dictionary in events():
		var a:=Director.beats(event,home_cast(),hungry_facts(),42,{})
		var b:=Director.beats(event,home_cast(),hungry_facts(),42,{})
		assert_str(JSON.stringify(a)).is_equal(JSON.stringify(b))
		assert_str(JSON.stringify(Director.asides(event,hungry_facts(),home_cast(),42,{}))).is_equal(JSON.stringify(Director.asides(event,hungry_facts(),home_cast(),42,{})))
	assert_str(JSON.stringify(Director.ambient(home_cast(),hungry_facts(),9))).is_equal(JSON.stringify(Director.ambient(home_cast(),hungry_facts(),9)))

func test_variety_holds_over_two_hundred_events()->void:
	var memory:={}
	var rng:=RandomNumberGenerator.new();rng.seed=1234
	var pool:=events()
	var last_sig:={}
	var bit_uses:={}
	var signatures:={}
	var asides:=0
	var aside_run:=0
	for i in 200:
		var event:Dictionary=pool[rng.randi_range(0,pool.size()-1)]
		var list:=Director.beats(event,home_cast(),hungry_facts(),1000+i,memory)
		var sig:=Director._signature(list)
		var kind:=String(event.kind)
		if not sig.is_empty():
			assert_str(sig).override_failure_message("%s played identically twice running (event %d)" % [kind,i]).is_not_equal(String(last_sig.get(kind,"")))
			last_sig[kind]=sig
		signatures[sig]=true
		for bit in memory.get("bits",{}):
			if int(memory.bits[bit])==int(memory.n):bit_uses[bit]=int(bit_uses.get(bit,0))+1
		var lines:=Director.asides(event,hungry_facts(),home_cast(),1000+i,memory)
		if lines.is_empty():aside_run=0
		else:
			asides+=1;aside_run+=1
			assert_int(aside_run).is_less(2)
	assert_int(bit_uses.size()).override_failure_message("only %d comic bits used: %s" % [bit_uses.size(),bit_uses]).is_greater_equal(12)
	for bit in bit_uses:assert_int(int(bit_uses[bit])).override_failure_message("%s used %d times in 200" % [bit,bit_uses[bit]]).is_less_equal(40)
	assert_int(signatures.size()).is_greater_equal(120)
	# About one event in four or five has a muttered line.
	assert_int(asides).is_between(25,70)

func test_the_same_terror_plays_differently_each_time()->void:
	var memory:={}
	var seen:={}
	var event:={"kind":"divine","action":"terrify","target":"main","response":"cower"}
	for i in 30:seen[Director._signature(Director.beats(event,home_cast(),hungry_facts(),500+i,memory))]=true
	assert_int(seen.size()).is_greater_equal(24)

# --- The shape of a moment -----------------------------------------------------------------

func test_anticipation_then_action_then_reaction_then_hold()->void:
	for seed_value in 30:
		var list:=Director.beats({"kind":"divine","action":"terrify","target":"main","response":"cower"},home_cast(),hungry_facts(),seed_value)
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
	var list:=Director.beats({"kind":"god_speaks","text":"Speak."},home_cast(),full_facts(60),5)
	var lifted:={}
	for beat:Dictionary in list:
		if String(beat.act) in ["look_up","late_lift"]:lifted[String(beat.who)]=true
	# Everyone but a sleeper still asleep, and the goat, who does not care.
	assert_int(lifted.size()).is_greater_equal(6)
	assert_bool(lifted.has("goat")).is_false()

func test_the_sleeper_wakes_and_stays_awake_a_while()->void:
	var memory:={}
	var woke_at:=-1
	for i in 40:
		var list:=Director.beats({"kind":"god_speaks","text":"Speak."},home_cast(),full_facts(60),i,memory)
		if _did(list,"c1","jerk_awake"):
			if woke_at>=0:assert_int(i-woke_at).is_greater_equal(Director.DOZE_AGAIN)
			woke_at=i
	assert_int(woke_at).is_greater_equal(0)
	# In a room in dread, nobody dozes.
	var dread:=full_facts(60);dread["people_dread"]=0.7
	assert_str(Director.dozer(home_cast(),dread)).is_empty()

# --- Adapters from the engine's results --------------------------------------------------

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
	var gift:=Director.event_from_resolution({"kind":"gift","terms":{"resource":"Food","amount":40}},"refuse",{"reaction":"offended"})
	assert_bool(bool(gift.accepted)).is_false()
	assert_str(String(Director.event_from_line({"role":"ruler","text":"Kneel."},"").kind)).is_equal("god_speaks")

func test_the_crowd_is_of_its_people_and_its_age()->void:
	var stone:=Director.extras({"era_tags":[],"people_dread":0.7,"people_love":0.2},3)
	var herds:=Director.extras({"era_tags":["dairy","farming"],"people_dread":0.1,"people_love":0.8},3)
	var keys:=func(list:Array)->Array:return list.map(func(e:Dictionary)->String:return String(e.key))
	assert_bool("goat" in keys.call(stone)).override_failure_message("a goat before anyone pens a herd").is_false()
	assert_bool("goat" in keys.call(herds)).is_true()
	assert_bool("dog" in keys.call(stone)).is_true()
	for entry:Dictionary in stone:
		if String(entry.role)=="crowd":assert_float(float(entry.dread)).is_greater(0.5)
	for entry:Dictionary in herds:
		if String(entry.role)=="crowd":assert_float(float(entry.love)).is_greater(0.6)
	# The same seed gives the same crowd.
	assert_str(JSON.stringify(Director.extras({"era_tags":[]},11))).is_equal(JSON.stringify(Director.extras({"era_tags":[]},11)))

func test_every_act_has_a_way_to_be_played()->void:
	var memory:={}
	for event:Dictionary in events():
		for beat:Dictionary in Director.beats(event,home_cast(),hungry_facts(),8,memory):
			assert_bool(Director.ACTS.has(String(beat.act))).override_failure_message("no acting entry for %s" % beat.act).is_true()
	for loop:Dictionary in Director.ambient(home_cast(),hungry_facts(),8):assert_bool(Director.ACTS.has(String(loop.act))).is_true()
	var kneel:=Director.performance({"act":"kneel","args":{}})
	assert_str(String(kneel.clip)).is_equal("kneel")
	assert_bool(bool(kneel.hold)).is_true()
	assert_str(String(Director.performance({"act":"stand_firm","args":{}}).mood)).is_equal("defiant")

# --- For the coordinator: a sample screenplay ------------------------------------------------

func test_print_a_screenplay()->void:
	var memory:={}
	var facts:=hungry_facts()
	var scenes:=[
		["The god speaks into a hungry hall",{"kind":"god_speaks","text":"Why are my people thin?"},home_cast()],
		["Wrath on the petitioner, who cowers",{"kind":"divine","action":"terrify","target":"main","response":"cower","witnesses":{"p1":"unbowed","p2":"shaken","p3":"shaken","p4":"shaken"}},home_cast()],
		["Wrath on the war leader, who defies it",{"kind":"divine","action":"terrify","target":"p1","response":"defy"},home_cast()],
		["A boon of twelve food while the stores hold nine days",{"kind":"divine","action":"boon","target":"p4","response":"blessed","terms":{"resource":"Food","amount":12}},home_cast()],
		["An envoy's food gift, accepted",{"kind":"gift","accepted":true,"resource":"Food","amount":40,"who":"main"},envoy_cast()],
		["The envoy is terrified",{"kind":"terrify_envoy","response":"cower","target":"main"},envoy_cast()],
		["An order nobody can carry out",{"kind":"command","verb":"order","stage":"none","actor":"p2","target":"","obedience":"obey","executed":false},home_cast()],
		["A petition granted",{"kind":"decree","who":"main","accepted":true,"reaction":"delighted"},home_cast()],
	]
	var text:PackedStringArray=PackedStringArray(["","=== SCREENPLAY (food 9 days, Marsh Cough 3 dead, feud with Kelvar, winter) ==="])
	var i:=0
	for scene:Array in scenes:
		text.append("-- %s" % scene[0])
		text.append(Director.screenplay(scene[1],scene[2],facts,77+i*13,memory))
		i+=1
	text.append("-- Idle business in this hall:")
	for loop:Dictionary in Director.ambient(home_cast(),facts,77):
		text.append("  %-6s %-14s every %s  (because %s)" % [loop.who,loop.act,"held" if bool(loop.hold) else "%s-%ss" % [loop.every[0],loop.every[1]],loop.because])
	print("\n".join(text))

# --- Helpers ------------------------------------------------------------------------------------

func _did(list:Array,who:String,act:String)->bool:
	for beat:Dictionary in list:
		if String(beat.who)==who and String(beat.act)==act:return true
	return false
