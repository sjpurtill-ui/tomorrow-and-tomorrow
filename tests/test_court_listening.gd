extends GdUnitTestSuite
## HOW THE COURT LISTENS: the live order reader is quick, and only reads what
## needs reading (order_reader.gd, audience_modal._speak). Runs the real court
## through the court evaluation's harness and worlds (tests/court_eval); every
## model is a stub and nothing leaves the machine.
##
## The reader's prompt, measured on the evaluation's worlds before this change
## (order_reader.gd at defbff06; four characters a token, roughly):
##   instructions 2863 chars (static), schema 2202-2304 chars rebuilt for every
##   audience (every id listed), brief 768-1275 chars; the schema came first,
##   so no two calls shared a prefix the provider could cache (~1600 tokens
##   processed on every call). A long audience's brief: 2537 chars. A reading
##   (the reply) in the old nested shape: 366 chars.
## After: the schema and the instructions are the same bytes on every call
## (~1300 tokens, cached by the provider after the first call); only the brief
## and the words change; the reply is flat (212 chars); a question, or a plain
## yes or no to the court's own question, needs no reading at all.

const Harness:=preload("res://tests/court_eval/harness.gd")
const OR:=preload("res://scripts/order_reader.gd")
const Hall:=preload("res://scripts/audience_hall.gd")

const OLD_SCHEMA_MIN_CHARS:=2202
const OLD_BRIEF_CHARS:={"tsaren_bound/rovik":1275,"tsaren_bound/headman":952,"battle_won/rovik":832,"envoy_after_fall/envoy":871}
const OLD_READING_CHARS:=366
const CHARS_PER_TOKEN:=4
## OpenAI caches a prompt's prefix from 1024 tokens on.
const CACHE_FLOOR_TOKENS:=1024

var _processing:Dictionary={}
var h:Harness

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)
	h=Harness.new(self)

func after()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))
	preload("res://scripts/ai_mode.gd").reset_for_tests(preload("res://scripts/ai_mode.gd").SETTINGS_PATH)

const CONFIG:={"endpoint":"https://api.openai.com/v1/chat/completions","api_key":"sk-listening-NOT-A-KEY","model":"mock-reader","structured_output":true}

func _payload(world:String,role:String,words:String)->Dictionary:
	var w:=h.fx.use(world)
	assert_bool(w.has("error")).override_failure_message(str(w.get("error",""))).is_false()
	var id:=h.fx.audience_for(w,role)
	assert_str(id).is_not_empty()
	return {"id":id,"payload":OR.build_payload(words,OR.world_brief(id),CONFIG),"brief":OR.world_brief(id)}

static func _prefix(payload:Dictionary)->String:
	return JSON.stringify(payload.get("response_format",{}))+String(((payload.messages as Array)[0] as Dictionary).content)

func test_the_readers_prompt_is_a_cached_prefix_and_a_small_brief()->void:
	var prefixes:={}
	for key in OLD_BRIEF_CHARS:
		var parts:=String(key).split("/")
		var made:=_payload(parts[0],parts[1],"Kill all the men of Tsaren that you have tied up!")
		var payload:Dictionary=made.payload
		var prefix:=_prefix(payload)
		prefixes[prefix]=true
		# No id of this world in the static part: the ids are in the brief only.
		for id in (made.brief.ids as Dictionary):
			if ":" in String(id): assert_str(prefix).override_failure_message("%s in the static prefix" % id).not_contains(String(id))
		var brief:=String(((payload.messages as Array)[1] as Dictionary).content)
		# The brief grows only with the world it describes (the hall now lists
		# the realm's named people too); what is processed fresh on each call is
		# this, where before it was this plus the per-call schema.
		print("reader prompt %s: static %d chars (~%d tokens, cached), brief %d chars (~%d tokens); before: brief %d chars after a %d+ char schema rebuilt per call, nothing cached" % [key,prefix.length(),prefix.length()/CHARS_PER_TOKEN,brief.length(),brief.length()/CHARS_PER_TOKEN,int(OLD_BRIEF_CHARS[key]),OLD_SCHEMA_MIN_CHARS])
		assert_int(brief.length()).is_less(prefix.length())
		assert_str(String(payload.get("prompt_cache_key",""))).is_equal(OR.PROMPT_CACHE_KEY)
		assert_str(String(payload.get("reasoning_effort",""))).is_equal(OR.REASONING_EFFORT)
	# The same bytes on every call, whoever speaks and whatever the world holds.
	assert_int(prefixes.size()).is_equal(1)
	# Long enough for the provider to cache it; the old per-call schema is gone.
	var one:String=prefixes.keys()[0]
	assert_int(one.length()/CHARS_PER_TOKEN).is_greater_equal(CACHE_FLOOR_TOKENS)
	assert_int(JSON.stringify(OR.response_format()).length()).is_less(OLD_SCHEMA_MIN_CHARS)

func test_a_long_audience_brief_keeps_only_the_last_short_lines()->void:
	## Before, the last six lines went in at up to 220 characters each (a long
	## audience's brief was 2537 chars on this world); now the last four, cut
	## to 160: however long the audience, its lines add at most ~700 chars.
	var w:=h.fx.use("tsaren_bound")
	var id:=h.fx.audience_for(w,"rovik")
	var short:=OR.brief_text(OR.world_brief(id)).length()
	for i in 8:
		Hall.append_line(id,{"speaker":"Rovik Longstride","role":"official","person_id":0,"civ_id":"player","text":"Report %d: the garrison keeps the men of Tsaren bound in the long house; two ran toward Stonefield before the ropes were on, and the women bring water and bread each morning under guard while the children stay indoors." % i,"day":0,"aside":false})
	var brief:=OR.brief_text(OR.world_brief(id))
	assert_int(brief.length()-short).is_less_equal(OR.RECENT_LINES*(OR.RECENT_CHARS+24))
	assert_str(brief).contains("Report 7")
	assert_str(brief).not_contains("Report 3")

func test_the_reading_is_flat_and_read_exactly_as_the_old_shape()->void:
	var w:=h.fx.use("tsaren_captured")
	var id:=h.fx.audience_for(w,"rovik")
	var brief:=OR.world_brief(id)
	var town:="town:"+String((w.info as Dictionary).tsaren_id)
	var flat:={"kind":"order","action":"town_fate","actor":"","type":"group","ref":town,"flags":["kill_men","captives","raze"],"count":0,"resource":"","destination":"home","measures":[],"stance":"","confidence":0.95,"clarify":""}
	var nested:={"kind":"order","action":"town_fate","actor":"","target":{"type":"group","ref":town},"details":{"kill_men":true,"kill_all":false,"captives":true,"raze":true,"tribute":false,"spare":false,"hold":false,"leave":false,"free":false,"full_force":false,"count":0,"resource":"","destination":"home","measures":[],"stance":""},"confidence":0.95,"clarify":""}
	assert_int(JSON.stringify(flat).length()).is_less(int(OLD_READING_CHARS*0.75))
	var a:=OR.validate(flat,brief)
	assert_bool(a.has("rejected")).override_failure_message(str(a)).is_false()
	assert_dict(a).is_equal(OR.validate(nested,brief))
	# Unknown flags and ids are refused, as before.
	assert_bool(OR.validate({"kind":"order","action":"town_fate","type":"group","ref":town,"flags":["burn_everyone"]},brief).has("rejected")).is_true()
	assert_bool(OR.validate({"kind":"order","action":"attack","type":"town","ref":"town:nowhere","flags":[]},brief).has("rejected")).is_true()

func test_offline_the_rulers_own_words_go_as_the_brief_they_mean()->void:
	## Without a live voice the envoy carries one of the briefs offered; the
	## ruler's typed words go as the one they mean, and are what the envoy
	## carries. Words that match none are never swapped for another brief.
	var civ_id:=preload("res://tests/diplomacy_fixture.gd").build_fixture()
	ForeignDiplomacy.leader(civ_id)["audience_day"]=0
	var dialogue:=WorldSimulation.dialogue
	assert_str(String(dialogue.typed_choice(civ_id,"Offer them our friendship and ask for safe passage along the river").get("id",""))).is_equal("honour")
	assert_str(String(dialogue.typed_choice(civ_id,"Warn them to keep off our borders").get("id",""))).is_equal("warn")
	assert_str(String(dialogue.typed_choice(civ_id,"What do they want from us?").get("id",""))).is_equal("ask_intent")
	assert_dict(dialogue.typed_choice(civ_id,"We want the river fords kept open")).is_empty()
	var words:="Offer them our friendship and ask for safe passage along the river; give nothing yet."
	assert_bool(dialogue.ask_offline(civ_id,"honour",words)).is_true()
	var thread:Dictionary=dialogue.thread(civ_id)
	assert_str(String(thread.private_brief)).is_equal(words)
	assert_str(String(thread.offline_choice)).is_equal("honour")

func test_the_voice_reads_six_thousand_as_the_facts_number()->void:
	## Live evaluation: true lines were thrown out for "6,000" (read as 6 and
	## 000) and "about 30 days" (the sheet says 30.0).
	var Voice:=preload("res://scripts/audience_voice.gd")
	assert_str(Voice.plain_numbers("We have 6,000 Food and houses for 1,100; 12,345,678 in all")).is_equal("We have 6000 Food and houses for 1100; 12345678 in all")
	var v:Node=Voice.new()
	add_child(v)
	var allowed:Dictionary=v.allowed_numbers({"records":"Stores: 6,000 Food, enough for 30.0 days. People: 900; houses for 1100."},{})
	for n in ["6000","1100","30","30.0","900"]: assert_bool(allowed.has(n)).override_failure_message("%s not allowed: %s" % [n,str(allowed.keys())]).is_true()
	assert_bool(allowed.has("000")).is_false()
	v.queue_free()

func _live(c:Dictionary)->Dictionary:
	var run:=h.run(c,"live")
	return run

static func _calls(run:Dictionary,step:int)->Array:
	return ((run.log as Array)[step] as Dictionary).calls

func test_questions_and_plain_answers_need_no_reading()->void:
	# A question: the voice answers it at once, no reading first.
	var q:=_live({"id":"listen.question","domain":"x","fixture":"war_not_held","speaker":"suri","source":"design","steps":[
		{"say":"How many fighters do we have at home?","ideal":{"kind":"question","action":"none","type":"none"},"expect":{"handled":false}}]})
	assert_bool(bool(q.ok)).override_failure_message(str(q.fails)).is_true()
	var calls:=_calls(q,0)
	assert_bool(calls.any(func(k:Variant)->bool: return String(k).begins_with("read"))).override_failure_message(str(calls)).is_false()
	assert_bool(calls.has("speak (read)")).override_failure_message(str(calls)).is_true()
	# "Shall I march on it?" answered "yes": the march goes, no reading first.
	var yes:=_live({"id":"listen.yes","domain":"x","fixture":"war_not_held","speaker":"headman","source":"design","steps":[
		{"say":"I want you to kill all the males of Tsaren immediately","ideal":{"kind":"order","action":"kill","type":"group","ref":"$tsaren","details":{"kill_men":true},"confidence":0.93},"expect":{"verdict":"ask_march"}},
		{"say":"yes","ideal":{"kind":"order","action":"confirm"},"expect":{"verb":"war","verdict":["act","object"]}}]})
	assert_bool(bool(yes.ok)).override_failure_message(str(yes.fails)).is_true()
	calls=_calls(yes,1)
	assert_bool(calls.any(func(k:Variant)->bool: return String(k).begins_with("read"))).override_failure_message(str(calls)).is_false()

func test_orders_holding_who_or_bring_go_to_the_engine_and_talk_of_people_to_the_persons_engine()->void:
	var chase:=_live({"id":"listen.chase","domain":"x","fixture":"tsaren_fled","speaker":"rovik","source":"design","steps":[
		{"say":"Go after the men who ran","ideal":{"kind":"order","action":"pursue","type":"town","ref":"$tsaren","confidence":0.9},"expect":{"verb":"war","state":{"chases":">0"}}}]})
	assert_bool(bool(chase.ok)).override_failure_message(str(chase.fails)).is_true()
	assert_bool(_calls(chase,0).has("persons")).is_false()
	var who:=_live({"id":"listen.who","domain":"x","fixture":"home_peace","speaker":"headman","source":"design","steps":[
		{"say":"Who is the strongest man in Seanstone?","ideal":{"kind":"question","action":"none","type":"none"},"expect":{"handled":false}}]})
	var calls:=_calls(who,0)
	assert_bool(calls.has("persons")).override_failure_message(str(calls)).is_true()
	assert_bool(calls.any(func(k:Variant)->bool: return String(k).begins_with("read"))).override_failure_message(str(calls)).is_false()
	# A question the facts answer is the voice's, even with "who" in it: the
	# persons engine answered "Who holds Tsaren?" with "Whom do you mean?".
	for q in ["Who holds Tsaren?","Who won the last fight?"]:
		var fact:=_live({"id":"listen.fact_who","domain":"x","fixture":"tsaren_captured","speaker":"suri","source":"design","steps":[
			{"say":q,"ideal":{"kind":"question","action":"none","type":"none"},"expect":{"handled":false}}]})
		calls=_calls(fact,0)
		assert_bool(calls.has("persons")).override_failure_message("%s: %s" % [q,str(calls)]).is_false()
		assert_bool(calls.has("speak (read)")).override_failure_message("%s: %s" % [q,str(calls)]).is_true()
