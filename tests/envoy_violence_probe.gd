extends Node
## Violence against foreign envoys (playtest reports on 48f74ed5):
##   "Slice Taro's hands off and send him home handless." became a scout party
##   led by the envoy; "Cut Nuru's Arms off!" became a seizure of 20 Food; the
##   maimed envoy then answered calmly; and the people whose envoys were killed
##   kept sending friendly gifts.
## Checks, headless and offline (a mocked live reading reproduces the misfire):
##   - a regression table of violent and punitive phrasings: each is an act on
##     the envoy (kill or maim), never goods, a dispatch or a general order,
##     and the live reading cannot turn it into one; seizure and dispatch fire
##     only on explicit words
##   - the maimed envoy: no scout mission, no stores moved, a grudge recorded,
##     their population unchanged, the envoy never speaks calmly afterwards,
##     and the outcome is said once
##   - three envoys killed: their people count exactly three fewer (dossier
##     figure and simulated ledger), ours unchanged; each is a slain-envoy grudge
##   - the offline WRATH choices on an envoy exist and carry the same act
##   - five simulated years later: no friendly gifts from that people, only
##     threats, a halt in envoys, frightened tribute or war moves; the heir
##     inherits the grudge; saves round-trip
##   <godot> --headless --path <worktree> res://tests/envoy_violence_probe.tscn

const HALL:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const CC:=preload("res://scripts/court_commands.gd")
const RIVALS:=preload("res://scripts/rival_rulers.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const WARM:=["gift_goods","gratitude_gift","artifact_gift","accord_offer","protection_pact","league_invitation","trade_offer","scholar_offer","research_sale","license_offer","nonaggression_offer","artifact_purchase"]

## Violent and punitive phrasings against an envoy. {n} is the envoy's name.
const VIOLENT:=[
	"Slice {n}'s hands off and send him home handless.",
	"Cut {n}'s Arms off!",
	"Cut off his hands.",
	"Cut off her ears and send her back.",
	"Cut out his tongue.",
	"Take his eyes.",
	"Blind him.",
	"Put out her eyes and send her home.",
	"Flay him alive.",
	"Kill the envoy.",
	"Behead {n}.",
	"Burn him alive.",
	"Bury {n} alive.",
	"Geld him and send him back to his people.",
	"Brand him.",
	"Whip {n} and throw him out.",
	"Flog the envoy.",
	"Send him home in pieces.",
	"Feed him to the dogs.",
	"Break his legs.",
	"Chop off his fingers.",
	"Hack off both her arms.",
	"Cut off his nose.",
	"Maim the envoy.",
	"Mutilate him and send him back.",
	"Shave his head and strip him naked before the court.",
	"Beat him to death.",
	"Drown {n} in the river.",
	"Stone him.",
	"Impale the envoy on a stake.",
	"Guards, slit his throat.",
	"Sever {n}'s hands and keep the gift.",
	"Castrate him.",
	"Humiliate him and send him home.",
	"Throw him to the wolves.",
	"Cripple him so he never walks again.",
]
## Explicit words that still move goods or parties (these must keep working).
const EXPLICIT:={
	"Take 20 food from their stores.":"take",
	"Seize their timber.":"take",
	"Give the envoy 30 food.":"give",
	"Send scouts to explore the east.":"send",
}

var failures:PackedStringArray=PackedStringArray()
var transcript:PackedStringArray=PackedStringArray()
var probe:Node
var voice:Node

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _ready()->void:
	probe=HallProbe.new()
	probe._setup()
	for civ in CivilizationSystem.civilizations: civ["diplomacy"]=float(civ.get("diplomacy",0.4))   # the hand-made neighbors lack it
	voice=Voice.new(); voice.force_offline=true; add_child(voice)
	GameState.elapsed_days=40
	_test_table()
	_test_maimed_and_sent_home()
	_test_arms_not_food()
	_test_offline_choices()
	_test_other_words_to_envoys()
	var killed:=_test_three_killings()
	_test_five_years(killed)
	_test_fear_posture()
	_test_saves()
	for line in transcript: print(line)
	print("ENVOY_VIOLENCE "+("PASS" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)

# --------------------------------------------------------------------------

func _test_table()->void:
	var routed:=0
	for raw in VIOLENT:
		var text:=String(raw).replace("{n}","Taro")
		var cls:=CC.classify(text)
		var ok:=String(cls.act)=="command" and String(cls.verb) in ["kill","maim"]
		check(ok,"violent phrasing not read as an act on the envoy: '%s' -> %s/%s" % [text,String(cls.act),String(cls.verb)])
		for side in ["take","send","give","order"]:
			check(not CC.live_verb_allowed(side,text),"the live reading could turn '%s' into '%s'" % [text,side])
		if ok: routed+=1
	check(VIOLENT.size()>=30,"the regression table has fewer than 30 phrasings")
	for text in EXPLICIT:
		var cls:=CC.classify(String(text))
		check(String(cls.verb)==String(EXPLICIT[text]),"explicit order '%s' no longer reads as %s (got %s)" % [text,EXPLICIT[text],String(cls.verb)])
		check(CC.live_verb_allowed(String(EXPLICIT[text]),String(text)),"explicit order '%s' refused to the live reading" % text)
	for text in ["Kill him and seize the gift.","Sever Taro's hands and keep the gift."]:
		check(bool(CC.classify(text).get("seize",false)),"'%s' did not keep the gift" % text)
	for text in ["Cut off his hands.","Kill the envoy."]:
		check(not bool(CC.classify(text).get("seize",false)),"'%s' seized goods unasked" % text)
	print("ENVOY_VIOLENCE regression table: %d/%d violent phrasings routed to the envoy act" % [routed,VIOLENT.size()])

func _force(civ_id:String,kinds:Array)->Dictionary:
	for kind in kinds:
		var audience:=HALL.debug_force(String(kind),civ_id)
		if not audience.is_empty(): return audience
	return {}

func _population(civ_id:String)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var ledger:=float(WorldSimulation.scoped(civ_id,func()->float:return float(WorldSimulation.state.population_exact))) if WorldSimulation.actors.has(civ_id) else -1.0
	return {"dossier":float(civ.get("population",0.0)),"ledger":ledger,"ours":float(GameState.population_exact)}

func _stores()->Dictionary:
	return {"food":HALL.player_stock("Food"),"fiber":HALL.player_stock("Fiber Plants"),"timber":HALL.player_stock("Timber")}

func _envoy_spoke_after_ruler(id:String)->String:
	var ruled:=false
	for line:Dictionary in HALL.find(id).get("lines",[]):
		if String(line.get("role",""))=="ruler": ruled=true
		elif ruled and String(line.get("role",""))=="envoy": return String(line.get("text",""))
	return ""

func _react(id:String,result:Dictionary)->void:
	voice.command_reaction(id,result)

func _record(id:String,label:String)->void:
	var audience:=HALL.find(id)
	transcript.append("--- %s · %s" % [label,String((audience.get("speaker",{}) as Dictionary).get("name",""))])
	for line in audience.get("lines",[]):
		var who:=String(line.get("speaker",""))
		transcript.append("  %s%s: %s" % [who if who!="" else "(narrator)"," (aside)" if bool(line.get("aside",false)) else "",String(line.get("text",""))])

func _test_maimed_and_sent_home()->void:
	var audience:=_force("rival_a",["gift"])
	check(not audience.is_empty(),"no gift envoy could be forced")
	if audience.is_empty(): return
	var id:=String(audience.id)
	var name:=String((audience.speaker as Dictionary).get("name","Taro")).get_slice(" ",0)
	var scouts:=CivilizationSystem.scout_missions.size()
	var stores:=_stores()
	var pop:=_population("rival_a")
	var opinion:=float((ForeignDiplomacy.civilization("rival_a").player_relation as Dictionary).get("opinion",0.0))
	var tension:=float((ForeignDiplomacy.civilization("rival_a").player_relation as Dictionary).get("border_tension",0.0))
	var their_dread:=Divine.civ_dread("rival_a")
	# The live model read it as a scout dispatch led by the envoy (the report).
	var live:={"act":"command","verb":"send","actor_ref":name,"target_ref":"","object":"","confidence":0.92}
	var text:="Slice %s's hands off and send him home handless." % name
	HALL.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":GameState.elapsed_days,"aside":false})
	var result:=CC.hear(id,text,{"live":live,"echoed":true})
	check(bool(result.get("handled",false)),"the maiming was not handled")
	check(String(result.get("verb",""))=="maim","the maiming was read as '%s'" % String(result.get("verb","")))
	check(CivilizationSystem.scout_missions.size()==scouts,"a scout party set out when the envoy was maimed")
	check(String(result.get("envoy_state",""))=="maimed","the envoy was not maimed (%s)" % String(result.get("envoy_state","")))
	check(absf(HALL.player_stock("Food")-float(stores.food))<0.01,"stores moved when the envoy was maimed")
	var wrongs:=RIVALS.envoy_wrongs("rival_a")
	check(int(wrongs.maimed)==1,"no maimed-envoy grudge was recorded (%s)" % str(wrongs))
	var after:=_population("rival_a")
	check(absf(float(after.dossier)-float(pop.dossier))<0.01 and absf(float(after.ours)-float(pop.ours))<0.01,"a maimed envoy changed a population")
	var rel:Dictionary=ForeignDiplomacy.civilization("rival_a").player_relation
	check(float(rel.opinion)<opinion-0.3,"their opinion did not crater")
	check(float(rel.border_tension)>tension+0.2,"no border tension spike")
	check(Divine.civ_dread("rival_a")>their_dread,"their dread did not rise")
	check(String(HALL.find(id).get("status",""))=="resolved","the audience did not end")
	check("forfeit" in String(result.get("outcome","")),"the gift's fate was not stated: %s" % String(result.get("outcome","")))
	_react(id,result)
	var calm:=_envoy_spoke_after_ruler(id)
	check(calm=="","the maimed envoy answered: %s" % calm)
	var outcomes:=0
	var staged:=false
	for line:Dictionary in HALL.find(id).get("lines",[]):
		if String(line.get("text",""))==String(result.outcome): outcomes+=1
		if String(line.get("text","")).begins_with("["): staged=true
	check(outcomes==1,"the outcome line appeared %d times" % outcomes)
	check(staged,"no bracketed stage direction for the maiming")
	var fate:=Voice.envoy_state_words(result)
	check("MAIMED" in fate and "never say 'it is done'" in fate,"the live voice is not told the envoy was maimed")
	_record(id,"MAIMED AND SENT HOME")

func _test_arms_not_food()->void:
	var audience:=_force("rival_c",["threat","request","news","gift"])
	check(not audience.is_empty(),"no second envoy could be forced")
	if audience.is_empty(): return
	var id:=String(audience.id)
	var name:=String((audience.speaker as Dictionary).get("name","Nuru")).get_slice(" ",0)
	var stores:=_stores()
	var their_food:=HALL.foreign_stock("rival_c","Food")
	var live:={"act":"command","verb":"take","actor_ref":"","target_ref":name,"object":"","confidence":0.9}
	var text:="Cut %s's Arms off!" % name
	HALL.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":GameState.elapsed_days,"aside":false})
	var result:=CC.hear(id,text,{"live":live,"echoed":true})
	check(String(result.get("verb",""))=="maim","'Cut %s's Arms off!' read as '%s'" % [name,String(result.get("verb",""))])
	check(absf(HALL.player_stock("Food")-float(stores.food))<0.01,"food moved when the envoy's arms were cut off")
	check(absf(HALL.foreign_stock("rival_c","Food")-their_food)<0.01,"their stores moved when the envoy's arms were cut off")
	check(not "Food" in String(result.get("outcome","")),"the outcome speaks of food: %s" % String(result.get("outcome","")))
	_react(id,result)
	check(_envoy_spoke_after_ruler(id)=="","the armless envoy answered calmly")
	_record(id,"ARMS CUT OFF")

func _test_offline_choices()->void:
	var audience:=_force("rival_c",["news","request","threat","gift"])
	if audience.is_empty(): check(false,"no envoy for the offline choices"); return
	var id:=String(audience.id)
	var acts:=HALL.envoy_acts(id)
	var ids:Array=acts.map(func(a:Dictionary)->String:return String(a.id))
	for want in ["envoy_maim","envoy_kill","envoy_detain","envoy_exile","envoy_flog"]:
		check(want in ids,"offline choice %s missing" % want)
	var result:=HALL.envoy_act(id,"envoy_flog")
	check(String(result.get("envoy_state",""))=="beaten","the offline flogging did not land (%s)" % String(result.get("envoy_state","")))
	check(RIVALS.envoy_wrongs("rival_c").beaten>=1,"the flogging left no grudge")
	_react(id,result)
	_record(id,"OFFLINE CHOICE: FLOGGED")

func _test_other_words_to_envoys()->void:
	## The same misfire class with gentler or explicit words.
	var audience:=_force("rival_a",["news","request","threat","gift"])
	if audience.is_empty(): check(false,"no envoy for the gentler words"); return
	var id:=String(audience.id)
	var scouts:=CivilizationSystem.scout_missions.size()
	var polite:=CC.hear(id,"Send him home with our thanks.",{"live":{"act":"command","verb":"send","actor_ref":"him","target_ref":"","object":"","confidence":0.9},"echoed":true})
	check(not bool(polite.get("handled",false)) or String(polite.get("verb",""))!="send","a polite 'send him home' dispatched a party")
	check(CivilizationSystem.scout_missions.size()==scouts,"a polite 'send him home' sent scouts")
	check(String(HALL.find(id).get("status",""))=="waiting","a polite 'send him home' ended the audience as a punishment")
	var told:=CC.hear(id,"Tell your chief to keep his hunters off our ridge.",{"echoed":true})
	check(not bool(told.get("handled",false)),"words for the envoy's chief became an order to our realm")
	var sent:=CC.hear(id,"Send scouts to explore the east.",{"echoed":true})
	check(String(sent.get("verb","")) in ["send","order"] and String((sent.get("actor",{}) as Dictionary).get("kind",""))!="envoy","an explicit dispatch in an envoy audience was led by the envoy")
	check(not "under %s" % String((audience.speaker as Dictionary).get("name","")) in String(sent.get("outcome","")),"the envoy leads our scouts: %s" % String(sent.get("outcome","")))
	var harsh:=CC.hear(id,"Send him back to his chief empty-handed.",{"echoed":true})
	check(String(harsh.get("verb",""))=="exile" and String(harsh.get("envoy_state",""))=="driven out","a harsh dismissal did not drive the envoy out (%s)" % String(harsh.get("verb","")))

func _test_three_killings()->int:
	var civ_id:="rival_b"
	var before:=_population(civ_id)
	var killed:=0
	for i in 3:
		GameState.elapsed_days+=20
		var audience:=_force(civ_id,["gift","news","request","threat"])
		if audience.is_empty(): check(false,"no envoy %d from %s" % [i+1,civ_id]); continue
		var id:=String(audience.id)
		var result:=CC.hear(id,"Guards, kill the envoy.",{})
		check(String(result.get("envoy_state",""))=="dead","envoy %d was not killed (%s)" % [i+1,String(result.get("outcome",""))])
		if String(result.get("envoy_state",""))=="dead": killed+=1
		_react(id,result)
		check(_envoy_spoke_after_ruler(id)=="","a dead envoy spoke")
		if i==0: _record(id,"AN ENVOY SLAIN")
	var after:=_population(civ_id)
	print("ENVOY_VIOLENCE population of %s: dossier %.1f -> %.1f, ledger %.1f -> %.1f; ours %.1f -> %.1f" % [civ_id,float(before.dossier),float(after.dossier),float(before.ledger),float(after.ledger),float(before.ours),float(after.ours)])
	check(absf(float(before.dossier)-float(after.dossier)-3.0)<0.01,"their dossier population fell by %.2f, not 3" % (float(before.dossier)-float(after.dossier)))
	if float(before.ledger)>=0.0: check(absf(float(before.ledger)-float(after.ledger)-3.0)<0.51,"their simulated population fell by %.2f, not 3" % (float(before.ledger)-float(after.ledger)))
	check(absf(float(before.ours)-float(after.ours))<0.01,"our population changed when their envoys died")
	check(int(RIVALS.envoy_wrongs(civ_id).slain)==3,"three slain envoys are not three grudges (%s)" % str(RIVALS.envoy_wrongs(civ_id)))
	return killed

func _test_five_years(killed:int)->void:
	var start:=int(GameState.elapsed_days)
	var per_civ:={"rival_a":{},"rival_b":{},"rival_c":{}}
	var warm:=PackedStringArray()
	var postures:={}
	var heir_checked:=false
	for day in range(start+1,start+5*365+1):
		GameState.elapsed_days=day
		probe._refill()
		# The heir of the killed envoys' ruler takes over in year three.
		if day==start+900:
			var c:=RIVALS.character("rival_b")
			c["dies"]=day
		for audience in HALL.daily(day):
			if String(audience.get("origin",""))!="foreign": continue
			var civ_id:=String(audience.civ_id)
			var type:=String((audience.get("situation",{}) as Dictionary).get("type",audience.kind))
			var tally:Dictionary=per_civ.get(civ_id,{})
			tally[type]=int(tally.get(type,0))+1
			per_civ[civ_id]=tally
			if civ_id in ["rival_a","rival_b"] and type in WARM: warm.append("%s %s day %d" % [civ_id,type,day])
		for audience in HALL.waiting():
			if day-int(audience.arrived_day)>=3:
				var options:=HALL.options(String(audience.id))
				var pick:=""
				for o in options:
					if bool(o.enabled) and String(o.id) in ["defy","refuse","decline","thank","dismiss","rebuff"]: pick=String(o.id); break
				if pick=="":
					for o in options:
						if bool(o.enabled): pick=String(o.id); break
				if pick!="": HALL.resolve(String(audience.id),pick)
		if day%90==0:
			for civ_id in ["rival_a","rival_b"]: postures["%s:%s" % [civ_id,RIVALS.envoy_posture(civ_id)]]=true
		if not heir_checked and day>start+905:
			heir_checked=true
			var c2:=RIVALS.character("rival_b")
			check(int(c2.get("gen",1))>=2,"the ruler of rival_b did not die on cue")
			check(int(RIVALS.envoy_wrongs("rival_b").slain)==3,"the heir did not inherit the slain-envoy grudges")
	var hostile:=0
	for civ_id in ["rival_a","rival_b"]:
		var tally:Dictionary=per_civ[civ_id]
		for type in tally:
			if String(type) in ["redress_demand","tribute_demand","test_of_resolve","emboldened_demand","dread_tribute"]: hostile+=int(tally[type])
	var withheld:=int(RIVALS.character("rival_b").get("envoys_withheld",0))+int(RIVALS.character("rival_a").get("envoys_withheld",0))
	var war:=bool((ForeignDiplomacy.civilization("rival_b").player_relation as Dictionary).get("at_war",false)) or bool((ForeignDiplomacy.civilization("rival_a").player_relation as Dictionary).get("at_war",false))
	var prep:=RIVALS.character("rival_b").has("war_prep_day") or RIVALS.character("rival_a").has("war_prep_day")
	print("ENVOY_VIOLENCE five years after %d killings: arrivals %s" % [killed,str(per_civ)])
	print("ENVOY_VIOLENCE postures seen %s; envoys withheld %d; war prepared %s; war opened %s" % [str(postures.keys()),withheld,str(prep),str(war)])
	check(warm.is_empty(),"a wronged people still sent friendly business: %s" % ", ".join(warm))
	check(hostile+withheld>0 or war or prep,"the wronged peoples did nothing: no threats, no halt, no tribute, no war moves")

func _test_fear_posture()->void:
	## A meek people (Kel Adun: low assertiveness and daring) that has grown
	## smaller than the god's and dreads it more than it hates: no gifts,
	## frightened tribute or silence instead.
	GameState.ensure_population_total(600)
	var c:=RIVALS.character("rival_a")
	if String(c.get("trait",""))=="grudge": c["trait"]="ledger"
	for i in 3: Divine.add_civ_dread("rival_a",0.4)
	var posture:=RIVALS.envoy_posture("rival_a")
	print("ENVOY_VIOLENCE a meek, smaller, dreading people after a maiming: %s" % posture)
	check(posture in ["fearful","halt"],"a meek, terrified people answered with '%s'" % posture)
	check(RIVALS.weight("gift_goods","rival_a")==0.0,"a wronged people may still bring a gift")
	if posture=="fearful":
		check(RIVALS.weight("dread_tribute","rival_a")>1.0,"frightened tribute is not favoured")
		# An ordinary "arrived bearing gifts" occasion, through the real selection.
		var audience:={}
		for tries in 12:
			audience=HALL._generate_foreign_occasion({"type":"ambient","key":"probe:%d" % tries,"civ_id":"rival_a","day":GameState.elapsed_days,"data":{"text":"arrived bearing gifts"}},int(GameState.elapsed_days)+tries)
			if not audience.is_empty(): break
		check(not audience.is_empty(),"the fearful people sent nobody on an ambient occasion")
		if not audience.is_empty():
			var type:=String((audience.get("situation",{}) as Dictionary).get("type",""))
			check(type=="dread_tribute","a fearful people's gift envoy came as '%s', not frightened tribute" % type)
			var lines:Dictionary=RIVALS.open_lines(audience)
			check(not (lines.get("narrator",[]) as Array).is_empty() and "shake" in String((lines.narrator as Array)[0]),"the frightened tribute-bearer shows no fear")

func _test_saves()->void:
	var saved:=ForeignDiplomacy.export_state()
	var before:=RIVALS.envoy_wrongs("rival_b")
	var check_import:=ForeignDiplomacy.import_state(saved.duplicate(true))
	check(not check_import.has("error"),"the save did not load: %s" % str(check_import))
	var after:=RIVALS.envoy_wrongs("rival_b")
	check(int(after.slain)==int(before.slain),"slain-envoy grudges lost in a save round trip")
	check(HALL.validate_state(ForeignDiplomacy.audiences),"the hall state no longer validates")
