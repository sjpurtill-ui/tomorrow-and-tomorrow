extends RefCounted
## THE KEEPER'S HAND — an optional live rewrite of a finished year's entry.
##
## Offline the year's entry is the deterministic telling from
## chronicle_annals.gd, and that is all. When the AI connection is on
## (PronouncementInterpreter._api_config, the same gpt-6-luna connection the
## court and envoys use), each closed year is sent once, asynchronously, with
## its draft and structured facts, and the model is asked to tell the same
## facts as a better paragraph. The answer is used only if it invents nothing:
## every number and every name in it must already be in the facts, no maxim,
## no word the people have no knowledge for, and no talk of games or systems.
## Anything else keeps the deterministic text.
##
## Cached per year in GameState.chronicle.polish[year] = {status, text, ...}:
## a year is asked for at most once, whatever the answer. Older saves simply
## have no cache. The game never waits on it: the entry is told at once and
## its text replaced if and when an acceptable answer arrives.

const CV:=preload("res://scripts/character_voice.gd")
const Plain:=preload("res://scripts/plain_speech.gd")

const MAX_TEXT:=900
const MIN_TEXT:=40
const TIMEOUT_SECONDS:=40
const MAX_COMPLETION_TOKENS:=900
const POLISH_MAX:=80
const PROMPT:="""You keep the annals of a small people in a fictional world. You are given one year's entry, already written, and the facts it was written from. Rewrite the entry as one plain paragraph a reader will enjoy: vary the order, join related facts, lead with what mattered most that year. Rules, all strict: Use only the facts given. Every name, number, count, age and year in your text must appear in the facts exactly as given (you may write a number as digits or as the same number in words only if the facts do). Do not add events, causes, motives, feelings, weather, places, objects or people that the facts do not state. Do not call the people's god by any name. Plain, concrete words; no proverbs, maxims, sayings, riddles or moral lessons; no rhetorical questions. Nothing the people have no word for: no metals, machines, writing, money or cities unless the facts name them. Never mention a game, player, simulation, system, model or chronicle feature. Keep it under 700 characters. Return JSON: {"text": "..."}."""
## Words that may open a sentence without being a fact themselves.
const COMMON_OPENERS:=["the","a","an","it","its","in","no","of","at","by","for","from","when","while","after","before","that","this","then","there","they","their","them","some","each","every","all","one","two","three","four","five","six","seven","eight","nine","ten","both","none","nothing","again","once","but","and","so","yet","still","only","even","as","with","without","on","to","this","these","those","since","though","although","if","never","more","fewer","most","many","few","what","who","which","over","under","until","through","across","year","years","its","his","her","our","we","us","here","now","later","first","last","together","by year's end"]
const META:=["game","player","simulation","system","model","prompt","json","chronicle feature","interface","ai "]
const NUMBER_WORDS:=["one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety","hundred","thousand",
	"first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth","twice","thrice","once","half","dozen"]

## Tests: replaces the transport. Called with (year, payload); the test later
## calls receive(year, body_text) as the service would.
static var send_hook:Callable=Callable()
## Tests: pretend a connection is configured.
static var config_override:Dictionary={}
static var force_offline:=false


static func _config()->Dictionary:
	if force_offline:return {}
	if not config_override.is_empty():return config_override
	if Engine.get_main_loop()==null:return {}
	# Only the player's game spends on the live service: never a headless run,
	# a test runner or a probe scene, even when a key is configured.
	if DisplayServer.get_name()=="headless":return {}
	var scene:=(Engine.get_main_loop() as SceneTree).current_scene if Engine.get_main_loop() is SceneTree else null
	if scene==null or scene.scene_file_path!=String(ProjectSettings.get_setting("application/run/main_scene","")):return {}
	return PronouncementInterpreter._api_config()


static func _store(c:Dictionary)->Dictionary:
	if not c.get("polish") is Dictionary:c["polish"]={}
	return c.polish


## A year's entry has just been told: ask once for a better telling. Returns
## true if a request went out.
static func request(c:Dictionary,entry:Dictionary,facts:Dictionary={})->bool:
	# Only a year's own entry; a generation's account is told as written.
	if String(entry.get("kind",""))!="annal" or not String(entry.get("key","")).begins_with("annal:"):return false
	var config:=_config()
	if config.is_empty():return false
	var year:=str(int(entry.get("year",int(String(entry.get("key","annal:-1")).get_slice(":",1))+1)))
	var store:=_store(c)
	if store.has(year):return false
	store[year]={"status":"pending","key":String(entry.get("key","")),"draft":String(entry.get("text","")),"facts":facts.duplicate(true)}
	while store.size()>POLISH_MAX:store.erase(store.keys()[0])
	var user:="YEAR %s. TITLE: %s\nDRAFT: %s\nFACTS: %s" % [year,String(entry.get("title","")),String(entry.get("text","")),JSON.stringify(facts).substr(0,2400)]
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":MAX_COMPLETION_TOKENS,
		"messages":[{"role":"system","content":PROMPT},{"role":"user","content":user}]}
	if bool(config.get("structured_output",false)):
		payload["response_format"]={"type":"json_schema","json_schema":{"name":"annal","strict":true,"schema":{"type":"object","additionalProperties":false,"properties":{"text":{"type":"string"}},"required":["text"]}}}
	if send_hook.is_valid():
		send_hook.call(year,payload)
		return true
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null or tree.root==null:
		store[year].status="failed"
		return false
	var http:=HTTPRequest.new()
	http.timeout=TIMEOUT_SECONDS
	http.max_redirects=0
	http.body_size_limit=131072
	tree.root.add_child(http)
	http.request_completed.connect(func(result:int,code:int,_h:PackedStringArray,body:PackedByteArray)->void:
		http.queue_free()
		if result==HTTPRequest.RESULT_SUCCESS and code>=200 and code<300:receive(year,body.get_string_from_utf8())
		else:_fail(year,"transport %d, http %d" % [result,code]))
	var headers:=PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % String(config.get("api_key","")),"X-Client-Request-Id: annal-%s-%d" % [year,Time.get_ticks_msec()]])
	if http.request(String(config.get("endpoint","")),headers,HTTPClient.METHOD_POST,JSON.stringify(payload))!=OK:
		http.queue_free()
		_fail(year,"request could not start")
	return true


static func _fail(year:String,why:String)->void:
	var c:Dictionary=GameState.chronicle
	var store:=_store(c)
	if store.get(year) is Dictionary:
		store[year].status="failed";store[year]["why"]=why.substr(0,120)


## The service's answer (the whole response body). Applies it if it passes.
static func receive(year:String,body:String)->bool:
	var c:Dictionary=GameState.chronicle
	var store:=_store(c)
	if not store.get(year) is Dictionary or String(store[year].get("status",""))!="pending":return false
	var record:Dictionary=store[year]
	var text:=_answer_text(body)
	var entry:=_entry(c,String(record.get("key","")))
	if entry.is_empty():
		record.status="failed";record["why"]="entry gone"
		return false
	var why:=validate(String(record.get("draft","")),String(entry.get("title","")),record.get("facts",{}) if record.get("facts") is Dictionary else {},text)
	record.erase("facts")
	if why!="":
		record.status="fallback";record["why"]=why.substr(0,160)
		return false
	record.status="done";record["text"]=text
	entry["draft_text"]=String(entry.get("text",""))
	entry["text"]=text
	entry["polished"]=true
	return true


static func _entry(c:Dictionary,key:String)->Dictionary:
	for e in c.get("entries",[]):
		if e is Dictionary and String(e.get("key",""))==key:return e
	return {}


static func _answer_text(body:String)->String:
	var envelope:Variant=JSON.parse_string(body)
	var content:=""
	if envelope is Dictionary and (envelope as Dictionary).get("choices") is Array and not (envelope.choices as Array).is_empty():
		var msg:Variant=(envelope.choices[0] as Dictionary).get("message",{})
		if msg is Dictionary:content=String(PronouncementInterpreter._content_text(msg.get("content",""))) if Engine.get_main_loop()!=null else String(msg.get("content",""))
	elif envelope is Dictionary and (envelope as Dictionary).has("text"):
		return String(envelope.text).strip_edges()
	content=content.strip_edges().trim_prefix("```json").trim_suffix("```").strip_edges()
	var inner:Variant=JSON.parse_string(content)
	if inner is Dictionary and (inner as Dictionary).get("text") is String:return String(inner.text).strip_edges()
	return content


## "" when `text` tells only what the draft and facts already hold; else why not.
static func validate(draft:String,title:String,facts:Dictionary,text:String)->String:
	var t:=text.strip_edges()
	if t.length()<MIN_TEXT:return "too short"
	if t.length()>MAX_TEXT:return "too long"
	if "\n" in t or "{" in t or "*" in t or "#" in t:return "not plain prose"
	var source:=(draft+" "+title+" "+JSON.stringify(facts))
	var lower_source:=source.to_lower()
	var lower:=t.to_lower()
	for word in META:
		if word in lower:return "talks about the game"
	# Numbers: every figure must already be there.
	var digits:=RegEx.create_from_string("\\d[\\d,]*")
	var known_digits:={}
	for m in digits.search_all(source):known_digits[m.get_string().replace(",","")]=true
	for m in digits.search_all(t):
		if not known_digits.has(m.get_string().replace(",","")):return "invented number %s" % m.get_string()
	var words:=RegEx.create_from_string("[A-Za-z][A-Za-z'\\-]*")
	var source_words:={}
	for m in words.search_all(source):source_words[m.get_string()]=true;source_words[m.get_string().to_lower()]=true
	for m in words.search_all(t):
		var w:=m.get_string()
		var lw:=w.to_lower()
		if NUMBER_WORDS.has(lw) and not source_words.has(lw):return "invented number %s" % w
		if w.substr(0,1)==w.substr(0,1).to_upper() and w.substr(0,1)!=w.substr(0,1).to_lower():
			# A capital: a name, unless it only opens a sentence.
			if source_words.has(w):continue
			var at:=m.get_start()
			var before:=t.substr(0,at).strip_edges()
			var opens:=before=="" or before.ends_with(".") or before.ends_with("!") or before.ends_with("?") or before.ends_with(":") or before.ends_with(";")
			if opens and (COMMON_OPENERS.has(lw) or source_words.has(lw)):continue
			return "invented name %s" % w
	if not lower_source.contains("god") and lower.contains("god"):return "speaks of a god the facts do not"
	# Nothing new under the words: most of the longer words must come from
	# the facts, so an invented happening cannot slip in lower case.
	var long_words:=0;var new_words:=0
	for m in words.search_all(t):
		var lw2:=m.get_string().to_lower()
		if lw2.length()<5:continue
		long_words+=1
		if not source_words.has(lw2) and not source_words.has(lw2.trim_suffix("s")) and not source_words.has(lw2+"s") and not source_words.has(lw2.trim_suffix("ed")) and not source_words.has(lw2.trim_suffix("d")):new_words+=1
	if long_words>0 and float(new_words)/float(long_words)>0.3:return "too much that is not in the facts"
	if Engine.get_main_loop()!=null:
		if not CV.permits(t,CV.era_tags("player")):return "a word the people have no knowledge for"
	if Plain.is_maxim(t):return "a maxim"
	return ""
