extends RefCounted
## A typed or offline order to raise a great work ("Build a great temple to me
## on the hill", "Raise a ring of standing stones") starts one through the
## Great Works system: a concept mapped from the god's words, a commission in
## a settlement with its real costs, labour and master builder, and the stage
## gates, setbacks and dedication that follow. The custom order that read the
## same words keeps only its first month of marking out, so the labour is not
## paid twice. Static; preload.

const GREAT_WORKS_PATH:="res://scripts/great_works.gd"
const GWA_PATH:="res://scripts/great_works_audience.gd"
## Words that ask for a lasting work rather than a small shrine or a carving.
const WORK_WORDS:=["temple","monument","standing stone","stone circle","ring of stone","stone ring","great mound","burial mound","mound","pyramid","ziggurat","tower","great hall","wonder","great work","obelisk","colossus","henge","cairn","observatory","great house"]
const BUILD_VERBS:=["build","raise","erect","make","set up","put up","dig","carve","heap","pile","start","begin","construct","found"]
## Days the custom order's own labour and building drag keep running after a
## work is commissioned (the marking out); the work itself carries the rest.
const MARKING_OUT_DAYS:=30

static func asks_for_work(text:String)->bool:
	var lower:=" "+text.to_lower()+" "
	var verb:=false
	for v in BUILD_VERBS:
		if lower.contains(" "+String(v)+" "): verb=true
	if not verb: return false
	for word in WORK_WORDS:
		if lower.contains(String(word)): return true
	return false

static func _site_words(text:String)->String:
	## "on the hill", "by the river": where it should stand, which the concept
	## grammar would otherwise read as its form.
	var re:=RegEx.new()
	re.compile("(?i)\\b(on|by|at|near|above|beside|over|below) the [a-z]+")
	return re.sub(text,"",true).strip_edges()

static func start_from_order(text:String,order_id:String="")->Dictionary:
	## {asked:bool, started:bool, name, line} — `line` is what the one who took
	## the order says of the work, in plain words.
	if WorldSimulation.actor_id!="player" or not asks_for_work(text): return {"asked":false,"started":false}
	# "Raise the dead from the burial mound" asks for a miracle, not a mound.
	if preload("res://scripts/custom_directive.gd").detect_natures(text).has("miracle"): return {"asked":false,"started":false}
	if not ResourceLoader.exists(GREAT_WORKS_PATH): return {"asked":true,"started":false}
	var gw:GDScript=load(GREAT_WORKS_PATH)
	var city_id:=String((load(GWA_PATH) as GDScript).call("default_city_id")) if ResourceLoader.exists(GWA_PATH) else ""
	if city_id=="": return {"asked":true,"started":false}
	# A settlement carries one work at a time.
	for work_variant in gw.call("works","player"):
		var work:Dictionary=work_variant
		if String(work.get("status",""))in ["building","stalled"]:
			var busy:=String(work.get("name",work.get("work_id","the work already rising")))
			return {"asked":true,"started":false,"line":"The builders are already on %s. Yours will wait until it stands." % busy}
	var words:=_site_words(text)
	var concept:Dictionary=gw.call("concept_from_words",words,"player")
	if concept.is_empty(): return {"asked":true,"started":false,"line":"No one here can yet picture how to raise it. It will be a lesser thing, made of what we have."}
	var first:=String(concept.get("proposed_ambition","modest"))
	var tried:Array[String]=[]
	for ambition in [first,"modest"]:
		if ambition in tried: continue
		tried.append(ambition)
		var ask:Dictionary=gw.call("retarget",concept,ambition)
		var result:Dictionary=gw.call("commission",city_id,ask,ambition,"player")
		if not bool(result.get("ok",false)): continue
		var name:=String(result.get("name",concept.get("name","the work")))
		_trim_custom_labour(order_id)
		var builder:=""
		for work_variant in gw.call("works","player"):
			var work:Dictionary=work_variant
			if String(work.get("work_id",""))==String(result.get("id","")): builder=String(work.get("architect",""))
		var line:="%s is marked out today%s. %s" % [name,(", and %s will lead the builders" % builder) if builder!="" else "",_cost_words(result)]
		_chronicle(name,line,city_id)
		return {"asked":true,"started":true,"name":name,"ambition":ambition,"id":String(result.get("id","")),"line":line.strip_edges()}
	return {"asked":true,"started":false,"line":"We do not yet know how to raise a thing like that. What we can do now is a lesser work, and it will look like one."}

static func _cost_words(result:Dictionary)->String:
	var assessment:Dictionary=result.get("assessment",{}) if result.get("assessment") is Dictionary else {}
	var spoken:=String(assessment.get("spoken","")).strip_edges()
	return spoken.substr(0,220) if spoken!="" else "It will take years of work and stone."

static func _chronicle(name:String,line:String,city_id:String)->void:
	preload("res://scripts/chronicle.gd").record({"key":"order_work:%s:%s" % [city_id,name.md5_text().left(8)],"title":"The God Calls for %s" % name,
		"text":"By the god's word: %s" % line,"tier":"moment","kind":"milestone","domain":"infrastructure","ledger":true})

static func _trim_custom_labour(order_id:String)->void:
	if order_id=="": return
	var today:=float(WorldSimulation.state.elapsed_days)
	for modifier_variant in WorldSimulation.state.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("id",""))!="custom_directive" or String(modifier.get("source_order_id",""))!=order_id: continue
		var params:Array=modifier.get("custom_parameters",[])
		if params.has("labor") or params.has("construction"):
			modifier["until_day"]=minf(float(modifier.get("until_day",today)),today+float(MARKING_OUT_DAYS))
