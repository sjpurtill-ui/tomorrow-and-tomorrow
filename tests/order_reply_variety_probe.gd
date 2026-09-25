extends Node
## The god's orders get answers, not boilerplate. Runs the 41 orders of
## universal_order_probe (same seed, same leader, offline) and measures the
## spoken replies: at most 15% may open with the same sentence, and no
## sentence may appear in more than 3 of the 41 replies.
##   <godot> --headless --path <worktree> res://tests/order_reply_variety_probe.tscn

const Universal:=preload("res://tests/universal_order_probe.gd")
const OPENER_SHARE_MAX:=0.15
const SENTENCE_REPEAT_MAX:=3

var failures:Array[String]=[]

func _ready()->void:
	var probe:Node=Universal.new()
	var speeches:Array[String]=[]
	for order_variant in Universal.ORDERS:
		var order_text:=String(order_variant)
		var city:String=probe._world()
		var leader:=GovernmentPeopleSystem.settlement_leader(city)
		var reading:=PronouncementInterpreter._local_interpretation(order_text,{"settlement":{"id":city}})
		var order:=AdvisorSystem.begin_civic_directive(order_text,city,leader)
		var resolved:=AdvisorSystem.resolve_civic_directive(order_text,reading,order,city,int(leader.get("person_id",0)))
		if String(resolved.get("status","")) in ["awaiting_clarification","awaiting_confirmation"]:
			var confirm:=AdvisorSystem.begin_civic_directive("Yes, do it.",city,leader)
			resolved=AdvisorSystem.resolve_civic_directive("Yes, do it.",PronouncementInterpreter._local_interpretation("Yes, do it."),confirm,city,int(leader.get("person_id",0)))
		var reply:=String(resolved.get("leader_reply",""))
		var speech:=reply.split("\n\nSTATE ·")[0].split("\n\nRECEIPT · ")[0].replace("\n"," ")
		if speech.begins_with("Accepted meaning:"): speech=speech.substr(speech.find("  ")+2) if speech.find("  ")>0 else speech
		speeches.append(speech.strip_edges())
		print("REPLY | %s | %s" % [order_text,speech])
	probe.free()
	var openers:Dictionary={}
	var sentence_orders:Dictionary={}
	for index in speeches.size():
		var sentences:=_sentences(speeches[index])
		if sentences.is_empty(): continue
		openers[sentences[0]]=int(openers.get(sentences[0],0))+1
		var seen:Dictionary={}
		for sentence in sentences:
			if seen.has(sentence): continue
			seen[sentence]=true
			sentence_orders[sentence]=int(sentence_orders.get(sentence,0))+1
	var top_opener:=""; var top_count:=0
	for key in openers:
		if int(openers[key])>top_count: top_count=int(openers[key]); top_opener=String(key)
	var repeated:Array[String]=[]
	for key in sentence_orders:
		if int(sentence_orders[key])>SENTENCE_REPEAT_MAX: repeated.append("%dx %s" % [int(sentence_orders[key]),String(key)])
	var worst:=0; var worst_sentence:=""
	for key in sentence_orders:
		if int(sentence_orders[key])>worst: worst=int(sentence_orders[key]); worst_sentence=String(key)
	print("METRIC opener_top=%d/%d (%.0f%%) \"%s\"" % [top_count,speeches.size(),100.0*float(top_count)/maxf(1.0,float(speeches.size())),top_opener])
	print("METRIC distinct_openers=%d" % openers.size())
	print("METRIC sentence_worst=%d \"%s\"" % [worst,worst_sentence])
	print("METRIC sentences_over_%d=%d" % [SENTENCE_REPEAT_MAX,repeated.size()])
	for line in repeated: print("REPEATED ",line)
	if float(top_count)/maxf(1.0,float(speeches.size()))>OPENER_SHARE_MAX: failures.append("opener share %d/%d exceeds 15%%: %s" % [top_count,speeches.size(),top_opener])
	if not repeated.is_empty(): failures.append("%d sentences appear in more than %d replies" % [repeated.size(),SENTENCE_REPEAT_MAX])
	if failures.is_empty():
		print("ORDER_REPLY_VARIETY PASS")
		get_tree().quit(0)
		return
	for failure in failures: push_error(failure)
	print("ORDER_REPLY_VARIETY FAIL (%d)" % failures.size())
	get_tree().quit(1)

static func _sentences(text:String)->Array[String]:
	## Split on sentence ends; a quoted order counts as part of its sentence.
	var out:Array[String]=[]
	var current:=""
	var quoted:=false
	for i in text.length():
		var c:=text[i]
		current+=c
		if c=="“": quoted=true
		elif c=="”": quoted=false
		if not quoted and c in ".!?" and (i+1>=text.length() or text[i+1]==" "):
			var s:=current.strip_edges()
			if s.length()>1: out.append(s)
			current=""
	if current.strip_edges().length()>1: out.append(current.strip_edges())
	return out
