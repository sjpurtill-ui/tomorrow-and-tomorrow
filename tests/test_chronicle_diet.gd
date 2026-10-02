extends GdUnitTestSuite
## The Chronicle's diet (scripts/chronicle.gd folding, and the noisiest
## sources: court rites, aims, finished works, the year's title). Forty years
## of the kinds of lines a real campaign records are replayed through
## Chronicle.record: every moment stays a moment, routine repeats fold into one
## card with a true count and the latest words, and nothing that waits on the
## god is folded away.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const Build:=preload("res://scripts/settlement_construction.gd")
const Y:=365
const WORKS:=["Storage Pits","Lean-to Shelters","Open Work Area","Gathering Yard","Hearth Shrine","Public Stores","Framed Hall"]
const TOWNS:=[["settlement_001","Ashley Springs"],["settlement_002","Highwatch"],["settlement_003","Stonefield"],["settlement_004","Valebridge"],["settlement_005","Windfield"]]

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	ForeignDiplomacy.ensure();ForeignDiplomacy.audiences.erase("lives")
	Chronicle.pending_cards.clear()
	GameState.chronicle={}


## One line of the replay: when, how it is recorded, and what the test
## expects of it. `old` is the tier the line was told at before the diet.
func _line(day:int,group:String,old:String,request:Dictionary,pending:=false)->Dictionary:
	return {"day":day,"group":group,"old":old,"request":request,"pending":pending}


## A real campaign's chatter, forty years of it (the year-228 save's families).
func _fixture()->Array:
	var lines:Array=[]
	# A cairn for the dead after every hard year (crisis_system.gd remember).
	for y in 40:
		lines.append(_line(y*Y+30,"rite:cairn","notice",{"rite":"cairn","label":"for the dead of the Dry Year of year %d" % (y+1)}))
	# One moment a year: a great death or a first knowing.
	for y in 40:
		if y%2==0:lines.append(_line(y*Y+300,"","moment",{"key":"court:death:person:%d" % (500+y),"title":"Elder %d of the Ford Is Dead" % y,"text":"Elder %d died aged 70." % y,"tier":"moment","kind":"death","action":{"kind":"court","focus":{"person_id":500+y}}},true))
		else:lines.append(_line(y*Y+300,"","moment",{"key":"discovery:found_%d" % y,"title":"Finding %d" % y,"text":"A first knowing.","tier":"moment","kind":"discovery"}))
	# Six aims, each one taken up, argued over, behind, called into question,
	# a rival's boast beside it, and failed (legacy_aims.gd).
	for c in 6:
		var s:=(1+6*c)*Y+60
		var civ:="Kezari" if c%2==0 else "Malewa"
		lines.append(_line(s,"aim:proposed","notice",{"key":"aim:proposed:%d:a%d" % [s,c],"title":"The Court Speaks of an Aim","text":"Nesh Reedwater waits to be summoned. The court speaks of: Make the %s Fear Our Name." % civ,
			"tier":Aims.proposal_tier("propose",c==0),"kind":"court","domain":"institutions","action":{"kind":"court","focus":{"person_id":171}},"ledger":false},true))
		lines.append(_line(s+20,"","moment",{"key":"aim:start:aim_%d" % c,"title":"An Aim for a Generation: Make the %s Fear Our Name" % civ,"text":"Make the %s fear our name. They have six winters." % civ,"tier":"moment","kind":"milestone"}))
		lines.append(_line(s+21,"aim:contradiction","notice",{"key":"aim:contradiction:aim_%d" % c,"title":"An Aim at Odds","clash":civ}))
		lines.append(_line(s+2*Y+90,"aim:course","notice",{"key":"aim:course:aim_%d" % c,"title":"Our Aim Falters","text":"Make the %s Fear Our Name: barely begun, and four winters left. Oru Stonewash would speak with the god about it." % civ,
			"tier":Aims.COURSE_TIER,"kind":"court","domain":"institutions","action":{"kind":"court","focus":{"person_id":177}},"ledger":false},true))
		lines.append(_line(s+3*Y+120,"aim:proposed","notice",{"key":"aim:proposed:%d:r%d" % [s+3*Y+120,c],"title":"A Call to Set Our Aim Aside","text":"Nesh Reedwater waits to be summoned. Some at the fire are tired of the old aim and speak of new ones: Master Custom and Law.",
			"tier":Aims.proposal_tier("renew",false),"kind":"court","domain":"institutions","action":{"kind":"court","focus":{"person_id":171}},"ledger":false},true))
		lines.append(_line(s+4*Y+150,"aim:rival","notice",{"key":"aim:rival:failed:civ_02:%d" % c,"title":"The Boast of the Ildor Came to Nothing","text":"Ilak of Thornbrake of the Ildor swore to spread their hunting grounds toward ours, and it came to nothing.",
			"tier":Aims.rival_end_tier("failed",c==3,false),"kind":"contact","domain":"culture"}))
		lines.append(_line(s+5*Y+250,"","moment",{"key":"aim:fail:aim_%d" % c,"title":"An Aim Unmet: Make the %s Fear Our Name" % civ,"text":"The winters ran out before it was done.","tier":"moment","kind":"court"}))
	# Seven works raised in five towns (35), the first town's in era step 1,
	# the second's too, the last three's after the realm's next step.
	for k in TOWNS.size():
		for i in WORKS.size():
			lines.append(_line((2+8*k)*Y+100+20*i,"work:"+String(WORKS[i]),"moment",{"work":WORKS[i],"town":k,"era":1 if k<=1 else 2,"before":i}))
	# Lines from files this diet does not own (war_loop.gd, rival_rulers.gd,
	# the ledger), folded by the general rule alone.
	for n in 9:
		var d:=20*Y+10+n*120
		lines.append(_line(d,"ildor will not talk","notice",{"key":"war:op:civ_02:war_parley:%d" % d,"title":"Ildor Will Not Talk","text":"Lorn's messengers came back with nothing. Ildor will not hear of it.","tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":"civ_02"}}}))
	var envoys:=["Skai","Brann","Ilo","Arn","Torv"]
	for n in 5:
		var d:int=[5*Y+40,6*Y+70,7*Y+200,30*Y+40,38*Y+90][n]
		lines.append(_line(d,"kezari sends no envoys","notice",{"key":"court:rival:%d" % d,"title":"Kezari Sends No Envoys","text":"Kezari will not send another envoy into the hall where you slew their envoy %s." % envoys[n],"tier":"notice","kind":"contact","action":{"kind":"court","focus":{"civ_id":"civ_01"}}}))
	for n in 7:
		var d:=15*Y+20+n*100
		lines.append(_line(d,"city reconnaissance","notice",{"key":"ev|%d|CITY RECONNAISSANCE" % d,"title":"City Reconnaissance","text":"Watching Pohiri: 4 scouts came home after %d months away." % (3+n),"tier":"notice","kind":"scout","action":{"kind":"scout_report","mission_id":110+n},"ledger":false}))
	# What waits on the god: a feud begun, its battles, a crisis's end, an old
	# order's callback (a summons), children lost, a great work to dedicate.
	lines.append(_line(23*Y+10,"","moment",{"key":"war:feud:civ_01:%d" % (23*Y+10),"title":"Blood Feud With Kezari","text":"Kezari will have vengeance. Nuna waits at the fire for your word.","tier":"moment","kind":"war","action":{"kind":"court","focus":{"civ_id":"civ_01"}}},true))
	for n in 3:
		lines.append(_line(23*Y+40+n*40,"battle at the ford","notice",{"key":"battle:%d" % n,"title":"Battle at the Ford","text":"Our fighters met Kezari's at the ford (%d)." % n,"tier":"notice","kind":"war","action":{"kind":"battle","battle_seed":n}},true))
	for n in 2:
		lines.append(_line(24*Y+50+n*400,"after the dry year","notice",{"key":"crisis:c%d:end" % n,"title":"After the Dry Year","text":"The Dry Year has passed (%d)." % n,"tier":"notice","kind":"omen"},true))
	for n in 3:
		lines.append(_line(26*Y+50+n*200,"an old order remembered","notice",{"key":"court:callback:order_%d" % n,"title":"An Old Order Remembered","text":"Lisse has word for you of what came of it (%d)." % n,"tier":"notice","kind":"court","action":{"kind":"court","focus":{"person_id":163}}},true))
	for n in 3:
		lines.append(_line(27*Y+50+n*90,"a child is lost","notice",{"key":"demo:child_%d" % n,"title":"A Child Is Lost","text":"A child of the Reed hearth died (%d)." % n,"tier":"notice","kind":"death"},true))
	lines.append(_line(28*Y+120,"","moment",{"key":"ceremony:ring","title":"The Ring of Stones stands finished","text":"The people gather for its dedication.","tier":"moment","kind":"ceremony","action":{"kind":"ceremony","work_id":"ring"}},true))
	lines.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.day)<int(b.day))
	return lines


## Records one line the way its source does, and returns the request's key
## and words (for the checks), or {} when nothing was told.
func _play(line:Dictionary)->Dictionary:
	var day:=int(line.day)
	GameState.elapsed_days=float(day)
	var r:Dictionary=line.request
	if r.has("rite"):
		Lives._mark_rite(String(r.rite),String(r.label),day,10,0)
		var told:Dictionary=Chronicle.entries()[0]
		return {"key":String(told.key),"text":"A cairn of stones: %s." % String(r.label),"tier":"notice"}
	if r.has("work"):
		var town:Array=TOWNS[int(r.town)]
		var said:PackedStringArray=["room for food +%d rations" % (1000+day%997)]
		var request:=Build.finished_telling(String(r.work),String(town[0]),String(town[1]),said,day,int(r.era),int(r.before))
		Chronicle.record(request)
		return {"key":String(request.key),"text":String(request.text),"tier":String(request.tier),"request":request}
	if r.has("clash"):
		var odds:="Some at the fire shake their heads. You would have the %s fear us, while we keep a pact with them? The god has chosen, and the people will try to do both." % String(r.clash)
		var request:={"key":String(r.key),"title":String(r.title),"text":odds,"tier":Aims.clash_tier(odds,day),"kind":"court","domain":"security","ledger":false}
		Chronicle.record(request)
		return {"key":String(r.key),"text":odds,"tier":String(request.tier),"request":request}
	var copy:=r.duplicate(true)
	copy["day"]=day
	Chronicle.record(copy)
	return {"key":String(r.key),"text":String(r.get("text","")),"tier":String(r.get("tier","notice")),"request":copy}


func _entry(key:String)->Dictionary:
	for e in GameState.chronicle.get("entries",[]):
		if String((e as Dictionary).get("key",""))==key:return e
	return {}


func test_forty_years_of_chatter_fold_and_every_turning_point_stays()->void:
	var lines:=_fixture()
	var played:Array=[]
	for line in lines:
		var told:=_play(line)
		assert_dict(told).is_not_empty()
		played.append({"line":line,"told":told})
	var entries:Array=GameState.chronicle.entries
	# Nothing recorded was lost (whispers stay under their limit here).
	assert_int(entries.size()).is_equal(played.size())
	assert_int(entries.filter(func(x:Dictionary)->bool:return String(x.tier)=="whisper").size()).is_less_equal(Chronicle.WHISPER_LIMIT)
	var before_cards:=0
	var before_moments:=0
	for p in played:
		if String(p.line.old)!="whisper":before_cards+=1
		if String(p.line.old)=="moment":before_moments+=1
	var after_cards:=Chronicle.entries("notice").size()
	var after_moments:=Chronicle.entries("moment").size()
	# The routine families (rites, aims' talk, works, refusals, watch reports).
	var routine:=played.filter(func(p:Dictionary)->bool:return String(p.line.group)!="" and not bool(p.line.pending) and String(p.line.group) not in ["battle at the ford","after the dry year","an old order remembered","a child is lost"])
	var routine_after:=routine.filter(func(p:Dictionary)->bool:return String(_entry(String(p.told.key)).tier)!="whisper").size()
	print("CHRONICLE DIET replay: %d lines; cards %d -> %d; moments %d -> %d; routine lines %d -> %d cards" % [played.size(),before_cards,after_cards,before_moments,after_moments,routine.size(),routine_after])
	var by_group:={}
	for p in played:
		var g:=String(p.line.group)
		if g!="":by_group[g]=int(by_group.get(g,0))+1
	for g in ["rite:cairn","aim:proposed","aim:course","aim:contradiction","aim:rival","ildor will not talk","kezari sends no envoys","city reconnaissance"]:
		var cards:=0
		for p in played:
			if String(p.line.group)==g and String(_entry(String(p.told.key)).tier)!="whisper":cards+=1
		print("  %-26s %2d lines -> %2d cards" % [g,int(by_group[g]),cards])
	var work_cards:=0
	for p in played:
		if String(p.line.group).begins_with("work:") and String(_entry(String(p.told.key)).tier)!="whisper":work_cards+=1
	print("  %-26s %2d lines -> %2d cards" % ["finished works",35,work_cards])

	# 1. Every moment is kept as a moment; the monthly cap never bit here.
	for p in played:
		var e:=_entry(String(p.told.key))
		assert_dict(e).is_not_empty()
		assert_bool(e.has("crowded")).is_false()
		if String(p.told.tier)=="moment":
			assert_str(String(e.tier)).is_equal("moment")
			assert_bool(e.has("same_as")).is_false()
	assert_int(after_moments).is_equal(played.filter(func(p:Dictionary)->bool:return String(p.told.tier)=="moment").size())

	# 2. Nothing that waits on the god is folded away or lowered.
	for p in played:
		if not bool(p.line.pending):continue
		var e:=_entry(String(p.told.key))
		assert_bool(e.has("same_as")).override_failure_message("folded: "+String(p.told.key)).is_false()
		assert_str(String(e.tier)).is_equal(String(p.told.tier))

	# 3. Counts are true: each card counts itself and every repeat folded into
	# it, and each folded repeat points at a card of its own group.
	for e in entries:
		var entry:Dictionary=e
		if not entry.has("same_as"):continue
		var head:=_entry(String(entry.same_as))
		assert_dict(head).is_not_empty()
		assert_str(Chronicle.fold_group(head)).is_equal(Chronicle.fold_group(entry))
		assert_str(String(head.tier)).is_not_equal("whisper")
	for e in entries:
		var card:Dictionary=e
		if String(card.tier)=="whisper":continue
		var folded:=entries.filter(func(x:Dictionary)->bool:return String(x.get("same_as",""))==String(card.key)).size()
		assert_int(int(card.get("told",1))).override_failure_message("count on "+String(card.key)).is_equal(1+folded)

	# 4. The most recent words of every group can be read: on its card, or on
	# the card it folded into as the latest line.
	var latest:={}
	for p in played:
		if String(p.line.group)!="":latest[String(p.line.group)]=p
	for g in latest:
		var told:Dictionary=latest[g].told
		var e:=_entry(String(told.key))
		var words:=Chronicle.plain(String(told.text))
		if e.has("same_as"):
			var head:=_entry(String(e.same_as))
			assert_str(String(head.last_text)).is_equal(words)
			assert_str(String(head.text)).contains(words)
			assert_int(int(head.last_day)).is_equal(int(latest[g].line.day))
		else:
			assert_str(String(e.text)).contains(words)

	# The cairns: forty rites fold by kind into a handful of cards, the first
	# one counting the next ten years.
	var cairn_cards:=entries.filter(func(x:Dictionary)->bool:return Chronicle.fold_group(x)=="rite:cairn" and String(x.tier)!="whisper")
	assert_int(cairn_cards.size()).is_less_equal(4)
	var first_cairn:Dictionary=cairn_cards.back()
	assert_int(int(first_cairn.told)).is_equal(11)
	assert_str(String(first_cairn.text)).contains("Told eleven times since Year 1; the latest, Year 11")
	assert_str(String(first_cairn.text)).contains("for the dead of the Dry Year of year 11.")
	var cairns_counted:=0
	for card in cairn_cards:cairns_counted+=int((card as Dictionary).get("told",1))
	assert_int(cairns_counted).is_equal(40)

	# The aims: only real changes are cards (taken up, failed, the very first
	# question, a clash not argued over this generation).
	var aim_status:=played.filter(func(p:Dictionary)->bool:return String(p.line.group).begins_with("aim:"))
	assert_int(aim_status.size()).is_equal(30)
	var aim_cards:=aim_status.filter(func(p:Dictionary)->bool:return String(_entry(String(p.told.key)).tier)!="whisper")
	assert_int(aim_cards.size()).is_less_equal(6)
	assert_str(String(_entry("aim:proposed:%d:a0" % (Y+60)).tier)).is_equal("notice")
	assert_str(String(_entry("aim:contradiction:aim_0").tier)).is_equal("notice")
	assert_str(String(_entry("aim:contradiction:aim_1").tier)).is_equal("notice")
	assert_str(String(_entry("aim:contradiction:aim_2").tier)).is_equal("whisper")
	# A rival's boast that came close (we were warned) is still news.
	assert_str(String(_entry("aim:rival:failed:civ_02:3").tier)).is_equal("notice")

	# The works: a kind is a moment the first time, then told once per era
	# step; a new town's first work is its own notice; the rest fold, counted.
	var works:=played.filter(func(p:Dictionary)->bool:return String(p.line.group).begins_with("work:"))
	assert_int(works.size()).is_equal(35)
	assert_int(works.filter(func(p:Dictionary)->bool:return String(_entry(String(p.told.key)).tier)=="moment").size()).is_equal(7)
	assert_int(work_cards).is_equal(17)
	var hall_era2:Dictionary=_entry("work_done:settlement_003:Framed Hall")
	assert_str(String(hall_era2.tier)).is_equal("notice")
	assert_int(int(hall_era2.told)).is_equal(3)
	assert_str(String(hall_era2.text)).contains("Raised at Windfield")
	var windfield_first:Dictionary=_entry("work_done:settlement_005:Storage Pits")
	assert_str(String(windfield_first.tier)).is_equal("notice")
	assert_str(String(windfield_first.text)).contains("Raised at Windfield, its first work")

	# Routine lines from other files fold by the general rule; a folded card
	# opens what its latest line opens.
	var talk:=entries.filter(func(x:Dictionary)->bool:return String(x.get("family",""))=="ildor will not talk" and String(x.tier)!="whisper")
	assert_int(talk.size()).is_equal(1)
	assert_int(int(talk[0].told)).is_equal(9)
	var watch:=entries.filter(func(x:Dictionary)->bool:return String(x.get("family",""))=="city reconnaissance" and String(x.tier)!="whisper")
	assert_int(watch.size()).is_equal(1)
	assert_int(int(((watch[0] as Dictionary).action as Dictionary).mission_id)).is_equal(116)
	# Envoy refusals years apart are each told; close ones fold.
	var refusals:=entries.filter(func(x:Dictionary)->bool:return String(x.get("family",""))=="kezari sends no envoys" and String(x.tier)!="whisper")
	assert_int(refusals.size()).is_equal(3)
	# The whole replay: the routine families shrink to a fraction of their
	# cards; every moment is still a moment.
	assert_int(routine_after).is_less_equal(routine.size()/3)
	# The folded store still reads as a valid Chronicle.
	assert_bool(Chronicle.valid_state(GameState.chronicle)).is_true()


func _raid(key:String,day:int,extra:Dictionary={})->Dictionary:
	GameState.elapsed_days=float(day)
	var line:={"key":key,"day":day,"title":"Kezari Raiders at the Herds","text":"Raiders came at dusk.","tier":"notice","kind":"war","action":{"kind":"court","focus":{"civ_id":"civ_01"}}}
	line.merge(extra,true)
	return Chronicle.record(line)


func test_a_family_folds_within_its_window_and_is_news_again_after()->void:
	var first:=_raid("raid:1",100)
	var second:=_raid("raid:2",900,{"text":"Raiders came at dawn."})
	assert_str(String(first.tier)).is_equal("notice")
	assert_str(String(second.tier)).is_equal("whisper")
	assert_str(String(second.same_as)).is_equal("raid:1")
	assert_int(int(first.told)).is_equal(2)
	assert_str(String(first.text)).starts_with("Raiders came at dusk. Told twice since Year 1; the latest, Year 3 · ")
	assert_str(String(first.text)).ends_with(": Raiders came at dawn.")
	# A repeat keeps its own line in the event ledger.
	assert_bool(GameState.simulation_events.any(func(e:Dictionary)->bool:return String(e.get("id",""))=="chronicle_raid:2")).is_true()
	# More than the window after the last one: news again, a card of its own.
	var third:=_raid("raid:3",2100,{"text":"Raiders burned the fold."})
	assert_str(String(third.tier)).is_equal("notice")
	assert_bool(third.has("same_as")).is_false()
	# A line asked never to fold, and a moment, stand alone.
	var kept:=_raid("raid:4",2110,{"fold":false})
	assert_str(String(kept.tier)).is_equal("notice")
	assert_bool(kept.has("same_as")).is_false()
	var felt:=_raid("raid:5",2400,{"tier":"moment"})
	assert_str(String(felt.tier)).is_equal("moment")
	assert_bool(felt.has("same_as")).is_false()


func test_an_older_save_still_loads_and_folds_into_its_old_cards()->void:
	# The shape the year-228 campaign saved: no fold fields anywhere.
	var old:={"version":1,"scan_day":83390,"firsts":{"founding":13},"keys":{"court:rite:83385:832e820fec":83385,"annal:226":82854},"moment_days":[83300],"moment_ids":{},
		"entries":[
			{"key":"court:rite:83385:832e820fec","day":83385,"tier":"notice","kind":"ceremony","title":"A cairn of stones for the dead","text":"A cairn of stones: for the dead of the Dry Year of year 229.","family":"a cairn of stones for the dead","action":{"kind":"court","focus":{}},"domain":"court"},
			{"key":"annal:226","day":82854,"tier":"notice","kind":"annal","title":"A year of many births","text":"Many births marked 227.","family":"a year of many births","domain":"annals","draft_text":"581 people.","polished":true},
			{"key":"war:feud_end:civ_02:77425","day":77425,"tier":"moment","kind":"war","title":"The Feud With Ildor Is Settled","text":"Ildor will send no more raiders.","family":"the feud with ildor is settled","action":{"kind":"court","focus":{"civ_id":"civ_02"}},"domain":"security"}]}
	assert_bool(Chronicle.valid_state(old)).is_true()
	assert_bool(Chronicle.valid_state({})).is_true()
	assert_bool(Chronicle.valid_state({"entries":[{"key":1,"title":"x","day":0,"tier":"notice"}]})).is_false()
	assert_bool(Chronicle.valid_state({"entries":[{"key":"k","title":"x","day":0,"tier":"notice","told":"two"}]})).is_false()
	GameState.chronicle=old.duplicate(true)
	GameState.elapsed_days=83385.0+300.0
	# The next cairn folds into the card the old save already holds.
	Lives._mark_rite("cairn","for the dead of the Hungry Winter of year 230",int(GameState.elapsed_days),10,0)
	var card:Dictionary=GameState.chronicle.entries.filter(func(e:Dictionary)->bool:return String(e.key)=="court:rite:83385:832e820fec")[0]
	assert_int(int(card.told)).is_equal(2)
	assert_str(String(card.base_text)).is_equal("A cairn of stones: for the dead of the Dry Year of year 229.")
	assert_str(String(card.text)).contains("for the dead of the Hungry Winter of year 230.")
	assert_bool(Chronicle.valid_state(GameState.chronicle)).is_true()
	# And the fold survives a save and load.
	var state:=SaveSystem._capture_reflected(GameState,[])
	GameState.reset_for_new_world(90210)
	SaveSystem._apply_reflected(GameState,state)
	assert_bool(Chronicle.valid_state(GameState.chronicle)).is_true()
	var loaded:Dictionary=GameState.chronicle.entries.filter(func(e:Dictionary)->bool:return String(e.key)=="court:rite:83385:832e820fec")[0]
	assert_int(int(loaded.told)).is_equal(2)
	assert_int(int(loaded.last_day)).is_equal(83685)


func test_a_quiet_year_is_titled_by_what_stood_out_and_never_twice_running()->void:
	# Thirty-five quiet years of a people that grows a little every year: the
	# old rule called nearly every one "A year of many births".
	var rng:=RandomNumberGenerator.new();rng.seed=228
	var annals:Array=[]
	var titles:Array=[]
	var old_many:=0
	for y in 35:
		var born:=rng.randi_range(38,52)
		var buried:=rng.randi_range(28,38)
		var a:={"year":y,"born":born,"buried":buried,"learned":[],"scouts":{"n":rng.randi_range(0,2)},"dry":[],"routine":0}
		if born>=buried+3:old_many+=1
		var title:=Annals._quiet_title(a,y*7919,annals)
		titles.append(title)
		annals.append({"y":y,"born":born,"buried":buried,"title":title})
	for i in range(1,titles.size()):
		assert_str(String(titles[i])).is_not_equal(String(titles[i-1]))
	var many:=titles.filter(func(t:String)->bool:return t=="A year of many births").size()
	print("CHRONICLE DIET annal titles: 'A year of many births' %d -> %d of 35 (%s)" % [old_many,many,", ".join(PackedStringArray(titles.slice(0,6)))])
	assert_int(many).is_less_equal(4)
	assert_int(old_many).is_greater(20)
	# A real rise in births still names the year, and a record says so.
	var steady:Array=[]
	for y in 9:steady.append({"y":y,"born":40,"buried":30,"title":"A quiet year"})
	assert_str(Annals._quiet_title({"born":61,"buried":30,"learned":[],"scouts":{"n":0},"dry":[]},1,steady)).is_equal("The most births in ten years")
	assert_str(Annals._quiet_title({"born":52,"buried":30,"learned":[],"scouts":{"n":0},"dry":[]},1,steady.slice(0,2))).is_equal("A year of many births")
	# Said of last year too: the year says what differs.
	var last:=[{"y":0,"born":40,"buried":30,"title":"A year on the roads"}]
	assert_str(Annals._quiet_title({"born":41,"buried":30,"learned":[],"scouts":{"n":3},"dry":[]},1,last)).is_equal("41 born, 30 buried")
