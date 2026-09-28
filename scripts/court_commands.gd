extends RefCounted
## Court commands: the god's word is law.
##
## Everything the ruler types in the Court (a summoned official, an envoy, the
## court at rest once someone answers) is read here as a speech act: question,
## statement, command, threat or blessing. Commands name who must act (the
## actor: "Ansel", "you", the guards by default) and on whom ("him", "the war
## leader", "Zuri"), resolved against the people actually present or known.
##
## The ENGINE decides first. Obedience comes from the actor's love and dread
## of the god (divine_regard.gd): almost always they obey (the frightened at
## once, the loving with reluctance when the act is cruel); a loving, gentle
## hand may hesitate once and plead, and the god's insistence ("I DEMAND IT")
## settles it; a genuine refusal is rare (dread nearly gone, courage high,
## pride or resentment high) and always has consequences: they flee, or the
## court seizes them and they kneel bound before you. The act itself goes
## through the real systems (execution/exile/imprisonment through
## GovernmentPeopleSystem, goods through the real stores, scouts and envoys
## through CivilizationSystem, every other order through the civic pipeline
## or the custom-directive seam below). The voice is then told what happened
## and only describes it.
##
## Any other order goes through custom_order(): the civic pipeline for a
## settlement leader or a catalog policy, otherwise the universal
## custom-directive path (custom_directive.gd). `custom_directive_handler`
## (func(text, context)->{ok, outcome}) may override it.
## Static helpers; reference with preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const CV:=preload("res://scripts/character_voice.gd")
const ScoutSurvival:=preload("res://scripts/scout_survival.gd")
const CustomDirective:=preload("res://scripts/custom_directive.gd")
const Sovereign:=preload("res://scripts/sovereign_weapons.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const TownFateWords:=preload("res://scripts/town_fate.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")
const Realm:=preload("res://scripts/court_realm_acts.gd")
const Persons:=preload("res://scripts/court_persons.gd")

const ACTS:=["question","statement","command","threat","blessing"]
const VERBS:=["kill","maim","exile","detain","penance","terrify","bless","boon","raise","demote","appoint","give","take","send","war","order"]
## Acts done to a person by a person: the ones a gentle hand balks at.
const CRUEL:=["kill","maim","detain","exile"]
## Acts on a body. Checked before goods and dispatch, so "cut his arms off" is
## never a store seizure and "send him home handless" is never a scout party.
const BODY_PARTS:="(hands?|arms?|ears?|nose|noses|tongues?|fingers?|thumbs?|feet|foot|legs?|knees?|toes?|lips?|eyes?|eyelids|teeth|jaw|spine|hamstrings?|tendons?|manhood|balls|testicles|genitals|beard|hair|scalp|face|cheeks?)"
const POSSESSOR:="(his|her|their|its|both|each|one|the envoy's|the herald's|the messenger's|(?-i:[A-Z])[\\w-]*'s)"
const MAIM_PATTERN:="(?i)\\b(maim|maims|mutilate|mutilates|cripple|disfigure|deface|blind|castrate|geld|emasculate|hamstring|hobble|kneecap|gouge|put out (his|her|their) eyes|take (his|her|their) (eyes|hands|ears|tongue|fingers)|(cut|cuts|slice|slices|chop|chops|hack|hacks|lop|lops|saw|tear|rip|shear|clip|cleave|sever|severs|break|breaks|smash|crush|burn|brand|pierce|nail|remove|pluck|pull) [\\w' ]{0,20}?"+POSSESSOR+" [\\w' ]{0,14}?"+BODY_PARTS+"|"+POSSESSOR+" "+BODY_PARTS+" (off|cut off|cut out|sliced off|chopped off|hacked off|broken|crushed|put out)|handless|armless|earless|noseless|tongueless|eyeless|footless|legless|blinded|maimed|mutilated|crippled|gelded|branded|brand (him|her|them|(?-i:[A-Z])\\w+|the envoy|the herald)|(flog|whip|scourge|lash|beat|thrash|cane|birch|kick) (him|her|them|(?-i:[A-Z])\\w+|the envoy|the herald|the messenger)|humiliate|shave (his|her|their) (head|beard)|strip [\\w' ]{0,30}?(naked|bare)|parade [\\w' ]{0,30}?naked|spit (on|at) (him|her|them|(?-i:[A-Z])\\w+)|piss on|urinate on|tar and feather|smear [\\w' ]{0,30}?(dung|filth|excrement)|drag [\\w' ]{0,30}?through the (dirt|mud|dung|filth))\\b"
## Shame and beatings, as opposed to cutting: the envoy walks home bruised or shamed.
const HUMILIATE_PATTERN:="(?i)\\b(humiliate|shave (his|her|their) (head|beard)|strip [\\w' ]{0,30}?(naked|bare)|parade [\\w' ]{0,30}?naked|spit (on|at)|piss on|urinate on|tar and feather|smear [\\w' ]{0,30}?(dung|filth|excrement)|drag [\\w' ]{0,30}?through the (dirt|mud|dung|filth))\\b"
const BEAT_PATTERN:="(?i)\\b(flog|whip|scourge|lash|beat|thrash|cane|birch|kick)\\b"
## The ruler's explicit word to keep what the envoy carried.
const SEIZE_PATTERN:="(?i)\\b(seize|keep|take|confiscate|plunder|loot|claim)\\b[\\w' ]{0,40}?\\b(gift|gifts|goods|packs?|bundles?|loads?|tribute|offering|what (he|she|they) (brought|carried|carries)|food|timber|stone|clay|fiber|fibre|grain|meat|wood)\\b"
## "Send him home / back": for a foreign envoy, a dismissal, never a dispatch.
const SEND_HOME_PATTERN:="(?i)\\b(send|sent|ship|return|pack) (him|her|them|(?-i:[A-Z])\\w+|the envoy|the herald|the messenger|this envoy)( [\\w']+){0,2}? (home|back|away|packing)\\b"
const HARSH_DISMISSAL_PATTERN:="(?i)\\b(empty-handed|in disgrace|in chains|with nothing|packing|kick|kicked|throw|thrown|drive|driven|out of my (sight|hall)|get out|begone|whip|spear|dogs?)\\b"
## A foreign envoy leads our scouts only when the ruler says exactly that.
const ENVOY_LEADS_PATTERN:="(?i)\\b(lead|guide|show) (our|my|the) (scouts?|party|parties|outriders|hunters|way)\\b"
## Explicit words for goods moving, and for a party going out.
const EXPLICIT_TAKE_PATTERN:="(?i)\\b(take|seize|confiscate|plunder|loot|strip)\\b[\\w' ]{0,40}?\\b(food|meat|grain|provisions|rations|timber|wood|logs|stone|stones|clay|fiber|fibre|reeds|flax|gift|gifts|goods|packs?|stores|tribute|loads?)\\b"
const LIVE_CONFIDENCE:=0.6
## A people as a body, or a town's people: "all the males", "every man",
## "the villagers", "them all". Harm ordered on them is a war order about a
## town (court_war_orders.group_harm_reading), never a punishment of anyone
## in the hall.
const GROUP_OBJECT_PATTERN:="(?i)\\b(males?|men|menfolk|boys|grown men|fighting men|every (man|male|boy|soul|last one|one of (them|its|their) \\w+)|females?|women|womenfolk|girls|children|everyone|everybody|all of them|them all|villagers|townsfolk|townspeople|inhabitants|residents|population|its people|their people|the people|whole (town|village|people|tribe)|all (the|of|those|these|who|that|its|their)|ringleaders?|troublemakers?|agitators?|instigators?|rebels|anyone who|anybody who|whoever|any who|those who|captives?|prisoners?|bondservants?|bondsmen|slaves)\\b|\\ball\\s*[!.]*$"
## Words that name one person as the object: only these let harm fall on
## someone in the hall ("them" and "they" never do on their own).
const PERSON_PRONOUNS:=["himself","herself","yourself","him","her","you","this one","that one","the traitor","the wretch","this wretch","the fool","this fool","that fool","the dog","this dog","that dog","the coward","this coward"]
## The god's yes to a war leader's "Shall I march on it?": "yes", "go
## ahead", "SEND THEM!", "yes, march on it", "do it now".
const CONFIRM_PATTERN:="(?i)^\\s*(?=\\w)(?:(?:yes|yeah|yep|yea|aye|ok|okay|sure|all right|alright|very well|indeed|of course)\\b[\\s,!.]*)?(?:please\\s+)?(?:(?:do it|do so|do that|go ahead|go on|go|proceed|carry on|march on it|march on them|march them|march|take it|send them(?: in| out| now| off)?|send the (?:men|band|host|warriors|fighters)|send them all|send it|attack|then go|go then|so be it|make it so|see to it|get going|get on with it|be off)\\b)?[\\s!.,]*(?:now|at once|then|already)?[\\s!.]*$"
const PENDING_DAYS:=2

static var custom_directive_handler:Callable=Callable()

# --------------------------------------------------------------------------
# Lexicon
# --------------------------------------------------------------------------

const INSIST_PATTERN:="(?i)^\\s*(yes,? )?(i demand it|i command it|i insist|do it|do it now|now|obey|obey me|obey your god|you heard me|did you not hear me|do as i (say|said|command)|i said do it|i said (kill|strike|do)|i will be obeyed|i gave you an order|do what i (say|said|command)|you will do it|at once|go on|go ahead|get on with it|proceed|carry on|carry it out|go anyway|march anyway|send them anyway|send them( in| out| now| off)?|send them all|send the band|march them|take them (anyway|as they are)|(let them )?go as they are|as they are|then go)\\b[\\s!.]*$"
## [verb, pattern]; checked in order. Patterns match the verb phrase only.
const VERB_PATTERNS:=[
	["kill","(?i)\\b(kill|kills|kil|kiil|killl|rid [\\w' ]{0,20}? of (all |every |each )?(one of )?(its |their |the )?(men|males|menfolk|people|inhabitants|villagers|townsfolk)|slay|slaughter|execute|behead|murder|butcher|stab|strangle|throttle|hang|smite|gut|decapitate|strike [\\w' ]{0,30}?down|cut [\\w' ]{0,24}?(throat|down)|put [\\w' ]{0,30}?to death|take (his|her|their) (head|life)|end (his|her|their) (life|days)|break (his|her|their) neck|off with (his|her|their) head|death to|make (him|her|them) (die|bleed)|spill (his|her|their) blood|bleed (him|her|them)|burn (him|her|them|(?-i:[A-Z])\\w+|the envoy|the herald)( alive)?|bur(y|ied) [\\w' ]{0,30}?alive|feed [\\w' ]{0,30}?to (the |my )?(dogs|wolves|pigs|hounds|crows|ravens|fire|fish|river|beasts)|(throw|give|hand|toss) [\\w' ]{0,30}?to the (dogs|wolves|pigs|hounds)|drown (him|her|them|(?-i:[A-Z])\\w+)|impale|crucify|flay|skin [\\w' ]{0,20}?alive|boil [\\w' ]{0,20}?alive|stone (him|her|them|(?-i:[A-Z])\\w+)|(beat|whip|flog|club|stone|burn|kick|starve|bleed|torture) [\\w' ]{0,30}?to death|(send|return|ship) [\\w' ]{0,40}?in pieces|(chop|cut|hack) [\\w' ]{0,30}?(head off|into pieces|to pieces|in pieces|apart)|draw and quarter|quarter (him|her|them)|sacrifice (him|her|them|(?-i:[A-Z])\\w+)|slit (his|her|their) throat|rid [\\w' ]{0,30}?of (every|all|each|its|their|the)\\b[\\w' ]{0,24}?\\b(men|males|menfolk|man|people|villagers|souls?)|(have|get|want|see that|see to it that) [\\w' ]{1,40}?(killed|executed|slain|beheaded|hanged|hung|drowned|strangled|murdered|put to death))\\b"],
	["maim",MAIM_PATTERN],
	["exile","(?i)\\b(exile|banish|expel|cast [\\w' ]{0,30}?out|drive [\\w' ]{0,30}?out|throw [\\w' ]{0,30}?out|send [\\w' ]{0,30}?away (forever|for good|from the realm)|out of my (sight|realm|lands) forever)\\b"],
	["detain","(?i)\\b(imprison|jail|gaol|lock [\\w' ]{0,30}?up|bind (him|her|them|(?-i:[A-Z])\\w+)|chains?|chained|shackles?|shackled|fetters?|fettered|in irons|put [\\w' ]{0,30}?in (bonds|the stocks)|arrest|detain|seize (him|her|them)|put [\\w' ]{0,30}?under guard|take [\\w' ]{0,24}?prisoner|throw [\\w' ]{0,30}?in(to)? the pit)\\b"],
	["penance","(?i)\\b(penance|atone|repent|keep vigil)\\b"],
	["demote","(?i)\\b(demote|dismiss|strip [\\w' ]{0,30}?of (his|her|their)? ?(office|rank|post|title|command)|remove [\\w' ]{0,30}?from (office|post|rank|command)|relieve [\\w' ]{0,30}?of (his|her|their)? ?(office|duties|post|command))\\b"],
	["appoint","(?i)\\b(appoint|install|make [\\w' ]{1,30}? (our|the|my|your) new |make [\\w' ]{1,30}? (our|the|my) |name [\\w' ]{1,30}? (as )?(our|the|my) )"],
	["raise","\\b(?i:(promote|exalt|elevate|raise [\\w' ]{0,30}?up))\\b|\\b(?i:honou?r) ((?i:him|her|them)|[A-Z]\\w+)\\b"],
	["boon","(?i)\\b(reward|boon)\\b"],
	["bless","\\b(?i:bless) ((?i:him|her|them)|[A-Z]\\w+)\\b"],
	["send","(?i)\\b((send|dispatch) [\\w' ]{0,40}?(to scout|scouting|scouts|to explore|exploring|outriders|an envoy|envoys|a messenger|messengers|an embassy|to (?-i:[A-Z])\\w+)|go (and )?(scout|explore)|scout the|explore the)\\b"],
]
const GIVE_PATTERN:="(?i)\\b(give|hand|grant|bestow|send|bring)\\b"
const TAKE_PATTERN:="(?i)\\b(take|seize|confiscate|strip)\\b"
const ORDER_LEADS:=["i order that ","i order ","i command that ","i command ","i want you to ","i need you to ","i demand that ","i demand ","i decree that ","i decree ","you will ","you shall ","you must ","see that ","see to it that ","make sure ","let ","have "]
const IMPERATIVES:=["throw","celebrate","teach","honour","honor","go","come","bring","fetch","make","dig","plant","hunt","gather","build","haul","drag","lug","quarry","chop","raise","feed","ration","guard","watch","train","clear","move","prepare","ready","double","halve","cut","burn","tell","find","get","take","keep","hold","open","close","set","call","summon","march","attack","defend","fortify","scout","sow","reap","harvest","store","share","stop","start","begin","finish","double","count","mend","repair","clean","carry","lead","muster","warn","teach","show","search","track","herd","fish","cook","dry","smoke","weave","fire","bake"]
const RESOURCE_WORDS:={"food":"Food","meat":"Food","grain":"Food","provisions":"Food","rations":"Food","timber":"Timber","wood":"Timber","logs":"Timber","stone":"Stone","stones":"Stone","clay":"Clay","fiber":"Fiber Plants","fibre":"Fiber Plants","fibers":"Fiber Plants","reeds":"Fiber Plants","flax":"Fiber Plants"}
const NUMBER_WORDS:={"a dozen":12,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"fifteen":15,"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"a hundred":100,"hundred":100}
const OFFICE_WORDS:={"war leader":"Marshal","warleader":"Marshal","marshal":"Marshal","watch captain":"Marshal","war chief":"Marshal","warchief":"Marshal","chief of war":"Marshal","war captain":"Marshal",
	"pathfinder":"ChiefScout","chief scout":"ChiefScout","chief of scouts":"ChiefScout","head scout":"ChiefScout","scout chief":"ChiefScout",
	"hearth chief":"Steward","steward":"Steward","headman":"Steward","head man":"Steward","chief of the hearths":"Steward",
	"keeper of stores":"Quartermaster","keeper of the stores":"Quartermaster","quartermaster":"Quartermaster","keeper of tribute":"Quartermaster","tribute keeper":"Quartermaster","storekeeper":"Quartermaster","store keeper":"Quartermaster",
	"lore keeper":"Scholar","scholar":"Scholar","messenger":"Envoy"}
const PRONOUNS:=["himself","herself","themselves","yourself","him","her","them","he","she","they","you","this one","that one","the traitor","the wretch","this wretch","the fool","this fool","that fool","the dog","this dog","that dog","the coward","this coward"]
const HEADINGS:=["northeast","northwest","southeast","southwest","north","south","east","west"]
const REFUSAL_PATTERN:="(?i)\\b(i (will|shall) not (do|kill|fight|strike|harm|hurt|obey|lift|raise|touch|slay|bind|cast|take|go|carry)|i won't (do|kill|fight|strike|harm|hurt|obey|go)|i refuse|i cannot do|i can't do|i will never|never will i|not by my hand|find another hand|another hand|give the order to another|ask another)\\b"

# --------------------------------------------------------------------------
# Speech acts
# --------------------------------------------------------------------------

static func _re(pattern:String)->RegEx:
	var re:=RegEx.new(); re.compile(pattern)
	return re

static func classify(text:String)->Dictionary:
	## Offline reading of the ruler's words. Always returns
	## {act, verb, verb_at, confidence, insist, resource, amount, heading, order}.
	var clean:=text.strip_edges()
	var out:={"act":"statement","verb":"none","verb_at":-1,"verb_end":-1,"confidence":0.3,"insist":false,"resource":"","amount":0.0,"heading":"","text":clean,"harm":"","seize":false}
	if clean.is_empty(): return out
	var lower:=clean.to_lower()
	if _re(INSIST_PATTERN).search(clean)!=null:
		out.act="command"; out.insist=true; out.confidence=0.8
		return out
	var question:=clean.ends_with("?")
	if not question:
		for lead:String in ["what","why","how","who","whom","where","when","tell me"]:
			if lower.begins_with(lead+" "): question=true; break
	if question:
		out.act="question"; out.confidence=0.8
		return out
	var resource:=_resource_in(lower)
	out.resource=resource
	out.amount=_amount_in(lower)
	for h:String in HEADINGS:
		if _re("\\b%s\\b" % h).search(lower)!=null: out.heading=h; break
	# Harm first: a body is never goods or a party ("cut his arms off", "slice
	# his hands off and send him home"). Keeping what they carried is its own
	# explicit clause ("kill him and seize the gift").
	for pair in VERB_PATTERNS.slice(0,2):
		var hm:=_re(String(pair[1])).search(clean)
		if hm!=null:
			_verb(out,String(pair[0]),hm)
			out.harm="kill" if String(pair[0])=="kill" else harm_kind(clean)
			out.seize=_re(SEIZE_PATTERN).search(clean)!=null
			return out
	# Goods next: "give Zuri 20 food", "take their stone".
	if resource!="":
		var give:=_re(GIVE_PATTERN).search(clean)
		if give!=null and not " from " in lower:
			return _verb(out,"give",give)
		var take:=_re(TAKE_PATTERN).search(clean)
		if take!=null: return _verb(out,"take",take)
	# An order at home a real system carries out (recruits called up, weapons
	# made: home_orders.gd): its own verb, so "make the weapons we need" is
	# never an appointment and "raise thirty new fighters" never a march.
	var home:=HomeOrders.read(clean)
	if not home.is_empty():
		out.act="command"; out.verb="home"; out.confidence=0.85; out["home"]=home
		return out
	for pair in VERB_PATTERNS:
		var m:=_re(String(pair[1])).search(clean)
		if m!=null: return _verb(out,String(pair[0]),m)
	var spoken:=DIVINE.intent(clean)
	if spoken=="terrify": out.act="threat"; out.verb="terrify"; out.confidence=0.8; return out
	if spoken in ["bless","raise_up"]: out.act="blessing"; out.verb="bless" if spoken=="bless" else "raise"; out.confidence=0.8; return out
	if _imperative(clean): out.act="command"; out.verb="order"; out.confidence=0.65; return out
	return out

static func harm_kind(text:String)->String:
	## "mutilate" (a body part, blinding, gelding, branding), "beat" or "humiliate".
	var cut:=_re(MAIM_PATTERN).search(text)
	var shame:=_re(HUMILIATE_PATTERN).search(text)
	var beat:=_re(BEAT_PATTERN).search(text)
	var body:=_re("(?i)\\b(maim|mutilat|cripple|disfigure|deface|blind|castrat|geld|emasculat|hamstring|hobble|kneecap|gouge|brand|put out|handless|armless|earless|noseless|tongueless|eyeless|footless|legless)").search(text)
	var part:=_re("(?i)\\b"+BODY_PARTS+"\\b").search(text)
	if body!=null or (part!=null and cut!=null and shame==null): return "mutilate"
	if beat!=null: return "beat"
	if shame!=null: return "humiliate"
	return "mutilate"

static func is_harm(text:String)->bool:
	## Violence or punishment done to a body, however phrased.
	return _re(String(VERB_PATTERNS[0][1])).search(text)!=null or _re(MAIM_PATTERN).search(text)!=null

static func _verb(out:Dictionary,verb:String,m:RegExMatch)->Dictionary:
	out.act="command"; out.verb=verb; out.verb_at=m.get_start(); out.verb_end=m.get_end(); out.confidence=0.85
	return out

static func _resource_in(lower:String)->String:
	for word:String in RESOURCE_WORDS:
		if _re("\\b%s\\b" % word).search(lower)!=null: return String(RESOURCE_WORDS[word])
	return ""

static func _amount_in(lower:String)->float:
	var m:=_re("\\b(\\d+(?:\\.\\d+)?)\\b").search(lower)
	if m!=null: return float(m.get_string(1))
	for word:String in NUMBER_WORDS:
		if _re("\\b%s\\b" % word).search(lower)!=null: return float(NUMBER_WORDS[word])
	return 0.0

static func _strip_leads(text:String)->String:
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return clean.substr(lead.length()).strip_edges()
	return clean

static func _imperative(text:String)->bool:
	var lower:=text.strip_edges().to_lower()
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return true
	# Drop a vocative ("Ansel, gather the hunters").
	var comma:=lower.find(",")
	if comma>0 and comma<28 and lower.substr(0,comma).split(" ",false).size()<=3: lower=lower.substr(comma+1).strip_edges()
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return true
	var words:=lower.split(" ",false)
	if words.is_empty(): return false
	var first:=String(words[0]).trim_suffix("!").trim_suffix(".").trim_suffix(",")
	return first in IMPERATIVES or first in PronouncementInterpreter.DIRECTIVE_VERBS

# --------------------------------------------------------------------------
# Who is here
# --------------------------------------------------------------------------

static func roster(audience:Dictionary)->Array[Dictionary]:
	## Everyone a reference may land on: the one before you, the court
	## present, every other official known, and an envoy's own person.
	var out:Array[Dictionary]=[]
	if audience.is_empty(): return out
	var id:=String(audience.get("id",""))
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	var speaker_pid:=int(speaker.get("person_id",0))
	var present:Dictionary={}
	for p:Dictionary in Hall.court(id): present[int(p.person_id)]=true
	if String(audience.get("origin",""))=="foreign":
		out.append({"key":"envoy","kind":"envoy","person_id":0,"figure_id":"","name":String(speaker.get("name","the envoy")),"title":"envoy","office_key":"","settlement_id":"","civ_id":String(audience.get("civ_id","")),"speaker":true,"present":true})
	elif speaker_pid<=0:
		var holder:Dictionary=Hall._matter_holder(audience)
		var figure:=String(holder.get("figure_id",""))
		if figure=="" and String(audience.get("holder_key","")).begins_with("figure:"): figure=String(audience.holder_key).trim_prefix("figure:")
		if figure!="":
			out.append({"key":"figure:"+figure,"kind":"figure","person_id":0,"figure_id":figure,"name":String(speaker.get("name","")),"title":String(speaker.get("title","")),"office_key":"","settlement_id":"","speaker":true,"present":true})
	for p:Dictionary in Hall._officials():
		var pid:=int(p.person_id)
		out.append({"key":"person:%d" % pid,"kind":"official","person_id":pid,"figure_id":"","name":String(p.get("name","")),"title":String(p.get("office_title","")),
			"office_key":String(p.get("office_key","")),"settlement_id":String(p.get("settlement_id","")),"speaker":pid==speaker_pid and speaker_pid>0,"present":pid==speaker_pid or present.has(pid)})
	# The realm's figures of renown who are not before the god: the war
	# leaders who lead our bands and hold our garrisons, and the others the
	# realm knows by name. Named, so "Kill Rovik" said to the Headman lands on
	# Rovik wherever he stands (and says where), never on the one spoken to.
	var listed:={}
	for e:Dictionary in out:
		if String(e.get("figure_id",""))!="": listed[String(e.figure_id)]=true
	for f:Dictionary in figures_at_large():
		var fid:=String(f.get("id",""))
		if fid=="" or listed.has(fid): continue
		listed[fid]=true
		var at:=figure_at(fid,String(f.get("name","")))
		out.append({"key":"figure:"+fid,"kind":"figure","person_id":0,"figure_id":fid,"name":String(f.get("name","")),"title":figure_title(f),"office_key":"","settlement_id":"",
			"speaker":false,"present":false,"where":String(at.words),"from":String(at.from)})
	# The council's people the god has put out of office or holds under guard,
	# and the commoners the court knows by name (the one brought in first):
	# named, the god's word reaches them too (court_realm_acts.gd).
	var pids:={}
	for e:Dictionary in out:
		if int(e.get("person_id",0))>0: pids[int(e.person_id)]=true
	for e:Dictionary in Realm.former_entries(pids):
		if int(e.person_id)==speaker_pid and speaker_pid>0: e["speaker"]=true; e["present"]=true
		out.append(e)
	if String(audience.get("origin",""))=="court": out.append_array(Realm.known_entries(audience))
	return out

static func figures_at_large()->Array[Dictionary]:
	## Living figures of renown the god can reach: at liberty, recovering from
	## wounds, or bound under guard at the god's word (never the dead or the
	## cast out).
	var out:Array[Dictionary]=[]
	var figures:Variant=Engine.get_main_loop().root.get_node_or_null("HistoricalFigures") if Engine.get_main_loop() is SceneTree else null
	if figures==null: return out
	for f in figures.people:
		if f is Dictionary and String((f as Dictionary).get("status","")) in ["living","wounded","detained"] and String((f as Dictionary).get("name",""))!="": out.append(f)
	return out

static func figure_title(f:Dictionary)->String:
	## "war leader" for a General (as Hall._summoned_speaker says it), else the calling.
	var role:=String(f.get("role",""))
	return "war leader" if role=="General" else role.to_lower()

static func figure_where(fid:String,name:String)->String:
	## Where a figure of renown is now, in plain words: "holding Tsaren with its
	## garrison", "with Rovik's band, camped about 20 km from home", "at Seanstone".
	return String(figure_at(fid,name).words)

static func figure_at(fid:String,name:String)->Dictionary:
	## {words (where they are, for the reader and the court), from (the place
	## they would be brought in from; "" when they are at home)}.
	var mc:Variant=WorldSimulation.military
	var home:=String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "home"
	if mc==null: return {"words":"at "+home,"from":""}
	for f in mc.occupation_forces:
		var c:Dictionary=(f as Dictionary).get("commander",{}) if (f as Dictionary).get("commander") is Dictionary else {}
		if (fid!="" and String(c.get("figure_id",""))==fid) or (name!="" and String(c.get("name",""))==name):
			var town:=String(WarOrders._held_town(String((f as Dictionary).get("region_id",""))).get("name",(f as Dictionary).get("region_name","")))
			if town!="": return {"words":"holding %s with its garrison" % town,"from":town}
	for a in mc.field_armies:
		var army:Dictionary=a
		var c:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		if not ((fid!="" and String(c.get("figure_id",""))==fid) or (name!="" and String(c.get("name",""))==name)): continue
		if int(army.get("troops",0))<=0: continue
		var band:=String(army.get("name","the band"))
		if band==band.to_upper():
			var words:=PackedStringArray()
			for w in band.to_lower().split(" ",false): words.append(w.substr(0,1).to_upper()+w.substr(1))
			band=" ".join(words)
		if WarOrders._at_home(army): return {"words":"with %s at %s" % [band,home],"from":""}
		var place:=String(army.get("location_name",""))
		if place=="" or place==place.to_upper(): place="the band's camp"
		return {"words":"with %s, %s" % [band,WarOrders._where(army)],"from":place}
	return {"words":"at "+home,"from":""}

static func _entry(list:Array[Dictionary],key:String)->Dictionary:
	for e:Dictionary in list:
		if String(e.key)==key: return e
	return {}

static func _speaker_entry(list:Array[Dictionary])->Dictionary:
	for e:Dictionary in list:
		if bool(e.speaker): return e
	return {}

static func _name_keys(e:Dictionary)->Array[String]:
	var keys:Array[String]=[]
	# Given name, a one-word byname, or the whole epithet; never "who" or "the"
	# out of "Oren Who Found the Ford" (era_names.gd).
	keys.append_array(preload("res://scripts/era_names.gd").name_keys(String(e.name)))
	# "Aro of Seanstone" answers to Aro, never to every word about Seanstone.
	var home:=String(GameState.settlement_name).to_lower()
	if home!="": keys.erase(home)
	return keys

static func _title_keys(e:Dictionary)->Array[String]:
	var keys:Array[String]=[]
	var title:=String(e.get("title","")).to_lower().strip_edges()
	if title!="":
		keys.append(title)
		if " of " in title: keys.append(title.get_slice(" of ",0))
	for word:String in OFFICE_WORDS:
		if String(OFFICE_WORDS[word])==String(e.get("office_key","")): keys.append(word)
	if String(e.kind)=="envoy":
		for w:String in ["envoy","messenger","herald","emissary"]: keys.append(w)
	# A war leader of renown answers to "the war leader" only before the god;
	# away, "the war leader" is the Marshal's office (Rovik is Rovik by name).
	if String(e.kind)=="figure" and "war" in title and bool(e.get("present",false)):
		for w:String in ["war leader","general"]: keys.append(w)
	elif String(e.kind)=="figure" and not bool(e.get("present",false)):
		keys.clear()
	# The council's people out of office answer to their names only; a known
	# commoner to their trade ("the hunter") only when before the god or just named.
	if String(e.kind)=="former": keys.clear()
	if String(e.kind)=="known":
		keys.clear()
		var trade:=String(e.get("trade",""))
		if trade!="" and (bool(e.get("speaker",false)) or bool(e.get("focus",false))):
			keys.append(String(Persons.trade_label(trade)).to_lower())
	return keys

static func mentions(text:String,list:Array[Dictionary])->Array[Dictionary]:
	## Every reference to a person in the words, in order:
	## {at, end, key (entry key, "" for a pronoun), word, by:"name"|"title"|"pronoun"|"guards"|"god"}.
	var found:Array[Dictionary]=[]
	var taken:Dictionary={}
	var lower:=text.to_lower()
	for by:String in ["name","title"]:
		# Present people first, so a shared first name lands on who is here.
		var ordered:=list.duplicate()
		ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(bool(a.present))>int(bool(b.present)))
		for e:Dictionary in ordered:
			var keys:Array[String]=_name_keys(e) if by=="name" else _title_keys(e)
			keys.sort_custom(func(a:String,b:String)->bool:return a.length()>b.length())
			for k:String in keys:
				for m in _re("\\b%s\\b" % _escape(k)).search_all(lower):
					var at:=m.get_start()
					if _overlaps(taken,at,m.get_end()): continue
					# "Their headman", "his war leader", "a headman": someone else's, never ours.
					if by=="title" and _re("\\b(their|his|her|its|whose|a|an|another|some|every|each|any)\\s+$").search(lower.substr(0,at))!=null: continue
					for i in range(at,m.get_end()): taken[i]=true
					var hit:={"at":at,"end":m.get_end(),"key":String(e.key),"word":k,"by":by}
					# "Rovik's men": what is his, not him ("of":"men").
					var owned:=_re("^(?:'|’)s\\s+([a-z]+)").search(lower.substr(m.get_end()))
					if owned!=null: hit["of"]=owned.get_string(1)
					found.append(hit)
	for m in _re("\\b(guards?|warriors|my (warriors|guards|spears))\\b").search_all(lower):
		if not _overlaps(taken,m.get_start(),m.get_end()): found.append({"at":m.get_start(),"end":m.get_end(),"key":"","word":m.get_string(),"by":"guards"})
	for p:String in PRONOUNS:
		for m in _re("\\b%s\\b" % _escape(p)).search_all(lower):
			if _overlaps(taken,m.get_start(),m.get_end()): continue
			for i in range(m.get_start(),m.get_end()): taken[i]=true
			found.append({"at":m.get_start(),"end":m.get_end(),"key":"","word":p,"by":"pronoun"})
	for m in _re("\\b(me|myself)\\b").search_all(lower):
		if not _overlaps(taken,m.get_start(),m.get_end()): found.append({"at":m.get_start(),"end":m.get_end(),"key":"","word":m.get_string(),"by":"god"})
	found.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.at)<int(b.at))
	return found

static func _escape(text:String)->String:
	var out:=""
	for c in text:
		out+=("\\"+c) if c in ".^$*+?()[]{}|\\-" else c
	return out

static func _overlaps(taken:Dictionary,from:int,to:int)->bool:
	for i in range(from,to):
		if taken.has(i): return true
	return false

static func _salient(audience:Dictionary,list:Array[Dictionary],exclude:String)->Dictionary:
	## Who "him"/"her"/"the traitor" means: the last person the god dealt with,
	## else the one standing before the god, else the last to speak.
	var focus:Dictionary=audience.get("command_focus",{}) if audience.get("command_focus") is Dictionary else {}
	# The one the court just named here ("Who is the laziest man?" ... "kill
	# him"), unless the god has dealt with someone since (court_persons.gd).
	var named:Dictionary=audience.get("named_focus",{}) if audience.get("named_focus") is Dictionary else {}
	var named_entry:=_entry(list,String(named.get("key","")))
	if not named_entry.is_empty() and String(named_entry.key)!=exclude and Hall._day()-int(named.get("day",-99))<=PENDING_DAYS and int(named.get("line",-1))>=int(focus.get("line",-1)): return named_entry
	var last:=_entry(list,String(focus.get("last_ref","")))
	if not last.is_empty() and String(last.key)!=exclude: return last
	var speaker:=_speaker_entry(list)
	if not speaker.is_empty() and String(speaker.key)!=exclude: return speaker
	var lines:Array=audience.get("lines",[])
	for i in range(lines.size()-1,-1,-1):
		var pid:=int((lines[i] as Dictionary).get("person_id",0))
		if pid<=0: continue
		var e:=_entry(list,"person:%d" % pid)
		if not e.is_empty() and String(e.key)!=exclude: return e
	return {}

static func resolve_ref(ref:String,audience:Dictionary,list:Array[Dictionary],actor_key:String="")->Dictionary:
	## A live classifier's reference ("Ansel", "him", "the war leader").
	var clean:=ref.strip_edges()
	if clean=="": return {}
	# An exact roster key (the order reader's ids): that entry, nobody else.
	var keyed:=_entry(list,clean)
	if not keyed.is_empty(): return keyed
	var lower:=clean.to_lower()
	if "before me" in lower or "in front of me" in lower or "before you" in lower:
		var speaker:=_speaker_entry(list)
		if not speaker.is_empty() and String(speaker.key)!=actor_key: return speaker
	var found:=mentions(clean,list)
	if not lower in ["me","myself","the god","god"]: found=found.filter(func(m:Dictionary)->bool:return String(m.by)!="god")
	# "All the males of Tsaren", "the villagers": a people, not one person here.
	if not _clear_person(clean,list) and (_re(GROUP_OBJECT_PATTERN).search(clean)!=null or _names_a_place(lower)): return {}
	# A reference that names nobody we know ("figure:x" no longer on the
	# rolls, "the potter", "Tavo") is nobody: never the one before the god.
	if found.is_empty(): return {}
	return _land(found[0],audience,list,actor_key)

static func _land(m:Dictionary,audience:Dictionary,list:Array[Dictionary],actor_key:String)->Dictionary:
	var by:=String(m.by)
	if by in ["name","title"]: return _entry(list,String(m.key))
	if by=="pronoun":
		var word:=String(m.word)
		if word in ["yourself","himself","herself","themselves"] and actor_key!="": return _entry(list,actor_key)
		if word=="you":
			var speaker:=_speaker_entry(list)
			if not speaker.is_empty() and String(speaker.key)!=actor_key: return speaker
		return _salient(audience,list,actor_key)
	if by=="god": return {"key":"god","kind":"god","name":"the god"}
	return {}

# --------------------------------------------------------------------------
# Obedience: the engine decides, the voice only describes
# --------------------------------------------------------------------------

static func obedience(actor:Dictionary,verb:String,insist:bool,roll:float)->Dictionary:
	## {id:"obey"|"reluctant"|"hesitate"|"refuse", manner, chance}
	if actor.is_empty() or int(actor.get("person_id",0))<=0: return {"id":"obey","manner":"guards","chance":0.0}
	var dread:=DIVINE.dread_of(actor)
	var love:=DIVINE.love_of(actor)
	var rel:=DIVINE.sovereign(actor)
	var resentment:=clampf(float(rel.get("resentment",0.0)),0.0,1.0)
	var courage:=clampf(float(actor.get("courage",0.5)),0.0,1.0)
	var pride:=clampf(float(actor.get("pride",0.5)),0.0,1.0)
	var personality:Dictionary=actor.get("personality",{}) if actor.get("personality") is Dictionary else {}
	var empathy:=clampf(float(personality.get("empathy",0.5)),0.0,1.0)
	var cruel:=verb in CRUEL
	var chance:=0.0
	if dread<=0.15 and courage>=0.75 and (resentment>=0.35 or pride>=0.75):
		chance=clampf(0.2+(courage-0.75)*2.0+maxf(0.0,resentment-0.35)*1.2+maxf(0.0,pride-0.75)*1.0-dread*2.0,0.0,0.95)
		if not cruel: chance*=0.3
		if insist: chance*=0.7
	if roll<chance: return {"id":"refuse","manner":"defiant","chance":chance}
	var manner:="trembling" if dread>=0.5 else ("grim" if cruel else "ready")
	if cruel and verb=="kill" and not insist and love>=0.6 and dread<0.4 and empathy>=0.5: return {"id":"hesitate","manner":"stricken","chance":chance}
	if cruel and (love>=0.55 or empathy>=0.62 or insist): return {"id":"reluctant","manner":"stricken" if love>=0.55 else manner,"chance":chance}
	return {"id":"obey","manner":manner,"chance":chance}

static func _roll(audience:Dictionary,key:String)->float:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|command|%s|%s|%d|%d" % [int(GameState.world_seed),String(audience.get("id","")),key,int(GameState.elapsed_days),(audience.get("lines",[]) as Array).size()])
	return rng.randf()

static func _person(e:Dictionary)->Dictionary:
	if e.is_empty() or int(e.get("person_id",0))<=0: return {}
	var p:=Hall._official(int(e.person_id))
	return p if not p.is_empty() else GovernmentPeopleSystem.person_snapshot(int(e.person_id))

# --------------------------------------------------------------------------
# Hearing the god
# --------------------------------------------------------------------------

static func hear(id:String,text:String,context:Dictionary={})->Dictionary:
	## The ruler spoke. Returns {handled:false, act} for questions, statements
	## and acts the ordinary flow already carries; otherwise the engine's full
	## result (see _result) after the act. context: {terrain, civic_settlement,
	## live:{act,verb,actor_ref,target_ref,object,confidence}, echoed:bool}.
	var audience:=Hall.find(id)
	var clean:=text.strip_edges().replace("\n"," ").substr(0,400)
	if audience.is_empty() or String(audience.get("status",""))!="waiting" or clean.is_empty(): return {"handled":false,"act":"statement"}
	var decree:=_sovereign_decree(id,clean,context)
	if not decree.is_empty(): return decree
	var list:=roster(audience)
	var cls:=classify(clean)
	# The order reader (order_reader.gd) resolved a war or a town's fate to
	# ids we supplied: the engine carries that reading. Never a person.
	var forced:Dictionary=context.get("war_reading",{}) if context.get("war_reading") is Dictionary else {}
	if not forced.is_empty():
		# The war leader's own question about a town is open ("The women as
		# well?"): an answer that names one of his choices ("bind them") is
		# that choice, for the people he asked about, whatever group the
		# reading assumed (court_war_orders.pending_answer).
		var open:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
		if String(open.get("ask",""))=="measure" and String(forced.get("kind","")) in ["measure","fate","town_word"]:
			var answered:=WarOrders.pending_answer(audience,clean)
			if not answered.is_empty() and String((answered.get("target",{}) as Dictionary).get("city_id",""))==String((forced.get("target",{}) as Dictionary).get("city_id","")): forced=answered
		cls.act="command"; cls.verb="war"; cls["war"]=forced
		return _perform(id,audience,list,"war",_speaker_entry(list),{},clean,cls,bool(forced.get("insist",false)),context)
	# The reader heard "yes, go ahead" to an objection or a hesitation.
	if bool(context.get("insist",false)): cls.act="command"; cls.insist=true
	var live:Dictionary=context.get("live",{}) if context.get("live") is Dictionary else {}
	var from_live:=false
	var reader:=bool(context.get("reader",false))
	if not live.is_empty() and (reader or String(cls.act) in ["statement","question"] or String(cls.verb) in ["none","order"]):
		var lact:=String(live.get("act",""))
		var lverb:=String(live.get("verb","none"))
		if lact=="command" and lverb in VERBS and float(live.get("confidence",0.0))>=LIVE_CONFIDENCE and live_verb_allowed(lverb,clean):
			cls.act="command"; cls.verb=lverb; cls.confidence=float(live.confidence); from_live=true
			if lverb in ["kill","maim"]: cls.harm="kill" if lverb=="kill" else harm_kind(clean); cls.seize=_re(SEIZE_PATTERN).search(clean)!=null
			var obj:=String(live.get("object","")).to_lower()
			if String(cls.resource)=="": cls.resource=_resource_in(obj)
			if float(cls.amount)<=0.0: cls.amount=_amount_in(obj)
			for h:String in HEADINGS:
				if String(cls.heading)=="" and h in obj: cls.heading=h
	var foreign:=String(audience.get("origin",""))=="foreign"
	# The god's yes to "Shall I march on it?": the march asked for goes, with
	# the war leader still free to object if it cannot be done well.
	var confirming:=_confirmed_war(id,audience,list,clean,context)
	if not confirming.is_empty(): return confirming
	# The realm's own business, read before war (court_realm_acts.gd): the
	# god's anger or favour on many, a law for our own people, the realm's
	# name, a verb that falls on one person named in any case, a gift.
	if not foreign and not bool(cls.insist) and String(cls.act)!="question":
		var realm:=_realm(id,audience,list,clean,cls,context)
		if realm.has("result"): return realm.result
		if realm.has("cls"): cls=realm.cls
	var own_business:=bool(cls.get("realm",false))
	# Harm on people who are one of ours' own ("kill Rovik's men"): never the
	# owner, never a town's people; said plainly, nothing done.
	if String(cls.verb) in CRUEL and String(cls.act)=="command" and not bool(cls.insist) and not own_business:
		var owned:=_owned_people(_harm_object(clean,cls),list)
		if owned!="": return _plain_answer(id,audience,clean,context,"%s are our own people. Nothing is done to them: say plainly whom you mean." % _cap_first(owned))
	# Harm ordered on a people or a town's people ("kill all the males of
	# Tsaren") is a war order about that town, whoever it was said to and
	# whatever the live reading names: never a hand laid on anyone here.
	var people:=harm_to_people(clean,cls,list,live) if not bool(cls.insist) and String(cls.act)!="question" and not own_business else ""
	if people!="":
		cls.act="command"; cls.merge(_people_route(clean,cls,audience,live,people),true)
	# A war order ("attack Tsaren", "march home", "raid their fields") goes to
	# the war leader as a real objective, never to the generic directive path.
	elif not foreign and not bool(cls.insist) and not own_business:
		var war_reading:=WarOrders.read_live(String(live.get("object","")),clean,String(audience.get("civ_id","")),id) if from_live and String(cls.verb)=="war" else WarOrders.read(clean,String(audience.get("civ_id","")),id)
		# The answer to "Which town?": the order given before, at the town named now.
		var answered:=_which_town_answer(audience,clean)
		if not answered.is_empty() and String(war_reading.get("kind",""))!="fate": war_reading=answered
		# The answer to the war leader's own question ("Shall I send some after them?").
		var replied:=WarOrders.pending_answer(audience,clean)
		if not replied.is_empty() and not String(war_reading.get("kind","")) in ["fate","pursue"]: war_reading=replied
		var named_place:=(war_reading.get("target",{}) as Dictionary).has("city_id") or (war_reading.get("target",{}) as Dictionary).has("unknown")
		# What becomes of a people in our hands is never a court punishment
		# ("kill all the males" is not "kill him", "put the captives to death"
		# is the captives' fate) nor a vague directive.
		var about_a_town:=String(war_reading.get("kind","")) in ["fate","which_town","no_town","pursue","let_go","keep","abandon","measure","town_word","measure_drop","captives","follow_kill","take_first","group_maim"] or bool(war_reading.get("answer",false))
		if not war_reading.is_empty() and String(cls.act)!="question" and (String(cls.verb) in ["none","order","send","take","give","war"] or named_place or about_a_town):
			cls.act="command"; cls.verb="war"; cls["war"]=war_reading
	if foreign and not bool(cls.insist) and String(cls.verb) in ["none","order","send","give"] and not String(cls.act)=="question" and _re(SEND_HOME_PATTERN).search(clean)!=null and _re("(?i)\\b(scouts?|scouting|explore|exploring|outriders|expedition)\\b").search(clean)==null:
		# "Send him home": the envoy goes home, never made to lead a party nor
		# sent as our own embassy. Driven out when said harshly; otherwise the
		# audience carries on and the answer cards remain.
		if _re(HARSH_DISMISSAL_PATTERN).search(clean)==null: return {"handled":false,"act":"statement"}
		cls.act="command"; cls.verb="exile"; cls.confidence=0.85; cls.verb_at=_re(SEND_HOME_PATTERN).search(clean).get_start()
	var insist:=bool(cls.insist)
	if insist:
		var pending:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
		if not pending.is_empty() and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS and String(pending.get("verb",""))=="war":
			# The god overrides the war leader's objection: the original order stands.
			var again_war:=WarOrders.read(String(pending.get("text","")),String(audience.get("civ_id","")))
			if not again_war.is_empty():
				var insisted:=cls.duplicate(); insisted["war"]=again_war; insisted["verb"]="war"
				return _perform(id,audience,list,"war",_entry(list,String(pending.get("actor",""))),{},clean,insisted,true,context)
		if not pending.is_empty() and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS:
			var pending_said:=String(pending.get("text",""))
			var pending_cls:=classify(pending_said)
			pending_cls["verb"]=String(pending.verb)
			var pending_people:=harm_to_people(pending_said,pending_cls,list) if String(pending.verb) in ["kill","maim"] else ""
			if pending_people!="":
				# A hesitation over harm to a people is never settled on a person here.
				var as_war:=cls.duplicate(); as_war.merge(_people_route(pending_said,pending_cls,audience,{},pending_people),true)
				return _perform(id,audience,list,String(as_war.verb),_entry(list,String(pending.get("actor",""))) if String(as_war.verb)=="order" else {},{},clean,as_war,true,context)
			return _perform(id,audience,list,String(pending.verb),_entry(list,String(pending.get("actor",""))),_entry(list,String(pending.get("target",""))),clean,cls,true,context)
		# Nothing waits on the god's word. A war order given here before is given
		# again, insisted on (the war leader says plainly if it is already on
		# the road). Anything else was already acted on: "do it" never repeats
		# a deed on whoever now stands there, and never becomes a standing
		# order called "do it" (docs/ADJUDICATION.md: honest words).
		var lines:Array=audience.get("lines",[])
		for i in range(lines.size()-1,-1,-1):
			var line:Dictionary=lines[i]
			if String(line.get("role",""))!="ruler": continue
			var said:=String(line.get("text",""))
			if said==clean: continue
			var again:=classify(said)
			if bool(again.insist) or String(again.act)=="question": continue
			var again_people:=harm_to_people(said,again,list)
			if again_people!="":
				# "Now!" after "kill all the males of Tsaren": the same war order again.
				var repeated:=again.duplicate(); repeated["act"]="command"; repeated.merge(_people_route(said,again,audience,{},again_people),true)
				if String(repeated.verb)!="war": return _nothing_waiting(id,audience,clean,context,said)
				repeated["text"]=said
				return _perform(id,audience,list,"war",{},{},clean,repeated,true,context)
			var again_war:=WarOrders.read(said,String(audience.get("civ_id","")),id) if not foreign else {}
			if not again_war.is_empty() and not String(again_war.get("kind","")) in ["no_town"]:
				var insisted:=again.duplicate(); insisted["act"]="command"; insisted["verb"]="war"; insisted["war"]=again_war; insisted["text"]=said
				return _perform(id,audience,list,"war",_speaker_entry(list),{},clean,insisted,true,context)
			if String(again.act) in ["command","threat","blessing"] and String(again.verb)!="none":
				return _nothing_waiting(id,audience,clean,context,said)
		# No order given here at all: words for the room to answer, never an act.
		return {"handled":false,"act":"command","verb":"none"}
	if String(cls.act)!="command" and String(cls.act)!="threat" and String(cls.act)!="blessing": return {"handled":false,"act":String(cls.act)}
	var parts2:=_parties(clean,cls,audience,list,live if from_live else {})
	var actor:Dictionary=parts2.actor
	var target:Dictionary=parts2.target
	var speaker:=_speaker_entry(list)
	# Words to a foreign envoy ("tell your chief...") are conversation, not an
	# order to our own realm with the envoy as its hand.
	if foreign and String(cls.verb)=="order" and String(actor.get("kind",""))=="envoy": return {"handled":false,"act":"command","verb":"order"}
	if String(cls.act) in ["threat","blessing"]:
		# Aimed at the one before you, the ordinary spoken act already carries it.
		if target.is_empty() or String(target.get("kind",""))!="official" or String(target.key)==String(speaker.get("key","")): return {"handled":false,"act":String(cls.act)}
	if String(cls.verb)=="order" and String(context.get("civic_settlement",""))!="" and (actor.is_empty() or String(actor.key)==String(speaker.get("key",""))):
		return {"handled":false,"act":"command","verb":"order"}   # the settlement leader's civic conversation carries it
	return _perform(id,audience,list,String(cls.verb),actor,target,clean,cls,false,context)

static func _realm(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,cls:Dictionary,context:Dictionary)->Dictionary:
	## The realm's own business (court_realm_acts.gd): {"result":...} when it
	## was carried out here, {"cls":...} when the ordinary path carries it on,
	## {} when these words are none of it.
	var mention:=func(t:String,l:Array[Dictionary])->Array[Dictionary]: return mentions(t,l)
	var verb:=String(cls.verb)
	# The answer to "Whom do you mean?" after the god's anger with no one named.
	var whom:=Realm.answer_whom(audience,clean,list,mention)
	if not whom.is_empty(): return {"result":_group(id,audience,list,clean,whom,context)}
	# The realm's own name.
	var renamed:=Realm.rename(clean)
	if not renamed.is_empty():
		_echo(id,audience,clean,context)
		audience.erase("pending_command")
		return {"result":Realm.perform_rename(id,_result("rename",{},{},clean,false),renamed)}
	# The god's anger or favour on a whole people, a town, our people, the court, the fields.
	if verb in ["none","order","terrify","bless","raise","penance","boon"] or String(cls.act) in ["statement","threat","blessing"]:
		var g:=Realm.group_act(clean,audience,list,mention)
		if not g.is_empty(): return {"result":_group(id,audience,list,clean,g,context)}
	# A law for our own people (never a war order, never anyone in the hall).
	if verb in ["none","order","kill","maim","exile","detain","penance","home"] or String(cls.act) in ["statement","threat"]:
		var law:=Realm.law(clean,list,mention)
		if not law.is_empty():
			var out:=cls.duplicate()
			out.act="command"; out.verb="law"; out["law"]=law; out["realm"]=true
			return {"cls":out}
	# A gift, maybe of what the stores do not hold ("Give Suri a gift of bronze").
	if verb in ["none","order","give","boon","take"]:
		var gift:=Realm.gift(clean)
		if not gift.is_empty() and not (verb=="give" and String(cls.resource)!="" and not gift.has("material")):
			var out2:=cls.duplicate()
			out2.act="command"; out2.verb="boon"; out2["realm"]=true
			if gift.has("material") and not Realm.stores_hold(String(gift.material)): out2["gift_material"]=String(gift.material)
			var named:=Realm.person_verb(_re("(?i)\\b(give|grant|bestow|send|bring)\\b").sub(clean,"reward",false),list,mention,func()->Dictionary: return _salient(audience,list,""))
			if not named.is_empty(): out2["target_key"]=String(named.key)
			elif bool(gift.get("take",false)) or _re("(?i)\\b(you|yourself)\\b").search(clean)!=null: out2["target_key"]=String(_speaker_entry(list).get("key",""))
			if String(out2.get("target_key",""))!="": return {"cls":out2}
	# An office (or the god's fire) given to one person named: "make imeri war
	# leader", "Imeri is my new war leader", "Make her a priest".
	if verb in ["none","order","raise"]:
		var ap:=_appoint_reading(clean,audience,list)
		if not ap.is_empty():
			var out4:=cls.duplicate()
			out4.act="command"; out4.verb="appoint"; out4["target_key"]=String(ap.key); out4["realm"]=true
			return {"cls":out4}
	# A verb that falls on one person named in any case ("bless suri", "flog the
	# headman", "let kishan go", "fire kavu", "Kavu must be punished").
	if verb in ["none","order"] or String(cls.act) in ["statement","threat","blessing"]:
		var pv:=Realm.person_verb(clean,list,mention,func()->Dictionary: return _salient(audience,list,""))
		if not pv.is_empty():
			var out3:=cls.duplicate()
			out3.act="command"; out3.verb=String(pv.verb); out3.verb_at=int(pv.at); out3.verb_end=int(pv.end); out3["target_key"]=String(pv.key); out3["realm"]=true
			if pv.has("harm"): out3.harm=String(pv.harm)
			return {"cls":out3}
	return {}

const PRIEST_WORDS:="(?i)\\b(priest|priestess|keeper of (the|my|your) (god's )?fire|fire-?keeper|holy (man|woman)|shaman)\\b"

static func _appoint_reading(clean:String,audience:Dictionary,list:Array[Dictionary])->Dictionary:
	## {key} of the one given an office (or the god's fire) by these words; {}.
	var office:=_office_in(clean)
	if office=="" and _re(PRIEST_WORDS).search(clean)==null: return {}
	var found:=mentions(clean,list)
	# "make/name/appoint/set X ...": the first one named after the verb.
	var lead:=_re("(?i)\\b(make|name|appoint|set|install|raise|put)\\b").search(clean)
	if lead!=null:
		for f:Dictionary in found:
			if int(f.at)<lead.get_end(): continue
			if String(f.by) in ["guards","god"]: continue
			if String(f.by)=="pronoun" and not String(f.word) in Realm.ONE_PERSON: continue
			var key:=String(f.get("key",""))
			if String(f.by)=="pronoun":
				key=String(_speaker_entry(list).get("key","")) if String(f.word) in ["you","yourself"] else String(_salient(audience,list,"").get("key",""))
			return {"key":key} if key!="" else {}
	# "X is (now) my new war leader".
	var is_now:=_re("(?i)^\\s*(?<who>[\\w' -]{2,40}?)\\s+(is|will be|shall be)\\s+(now\\s+)?(my|our|the|a)?\\s*(new\\s+)?").search(clean)
	if is_now!=null:
		for f:Dictionary in found:
			if int(f.end)<=is_now.get_end("who") and String(f.by) in ["name","title"] and String(f.get("of",""))=="": return {"key":String(f.key)}
	return {}

static func realm_business(id:String,text:String)->bool:
	## Are these words the realm's own business the engine carries (a law, the
	## god's act on many, the realm's name, a verb on one person named, a gift)?
	## Read only; nothing is done. The court screen asks before handing words
	## about people to the persons engine.
	var audience:=Hall.find(id)
	var clean:=text.strip_edges()
	if audience.is_empty() or clean=="" or String(audience.get("origin",""))!="court" or clean.ends_with("?"): return false
	var list:=roster(audience)
	var mention:=func(t:String,l:Array[Dictionary])->Array[Dictionary]: return mentions(t,l)
	if not Realm.rename(clean).is_empty(): return true
	if not Realm.group_act(clean,audience,list,mention).is_empty(): return true
	if not Realm.law(clean,list,mention).is_empty(): return true
	if not Realm.gift(clean).is_empty(): return true
	return not Realm.person_verb(clean,list,mention,func()->Dictionary: return _salient(audience,list,"")).is_empty()

static func _echo(id:String,audience:Dictionary,clean:String,context:Dictionary)->void:
	## The ruler's words in the transcript, once (the caller did not show them).
	if bool(context.get("echoed",false)): return
	Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":clean,"day":Hall._day(),"aside":false})
	audience["echoed_here"]=clean

static func _group(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,g:Dictionary,context:Dictionary)->Dictionary:
	## The god's anger or favour on many, carried out and said (court_realm_acts.gd).
	_echo(id,audience,clean,context)
	audience.erase("pending_command")
	var r:=Realm.perform_group(id,audience,_result(String(g.get("act","terrify")),{},{},clean,false),g)
	# Nobody could tell whom: the one before the god asks it, once.
	if String(r.get("actor_says",""))!="":
		var speaker:=_speaker_entry(list)
		r.actor=speaker.duplicate(); r.actor_name=String(speaker.get("name",""))
	return r

static func _nothing_waiting(id:String,audience:Dictionary,clean:String,context:Dictionary,last:String)->Dictionary:
	## "Do it!", "SEND THEM!" with nothing waiting on the god's word: nothing is
	## set in motion, said plainly, with what it would need. Never a deed done
	## again on whoever stands there now, never a standing order named "Do it!".
	return _plain_answer(id,audience,clean,context,"Nothing waits on your word now: your last order, \"%s\", was already answered. Nothing new is set in motion." % last.strip_edges().substr(0,80),true)

static func _plain_answer(id:String,audience:Dictionary,clean:String,context:Dictionary,words:String,insist:bool=false)->Dictionary:
	## The court's plain answer when nothing is to be done: handled, nothing
	## changed, and said so.
	if not bool(context.get("echoed",false)):
		Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":clean,"day":Hall._day(),"aside":false})
		audience["echoed_here"]=clean
	var r:=_result("none",{},{},clean,insist)
	r.stage="none"; r.executed=false
	r.outcome=words
	return r

static func _which_town_answer(audience:Dictionary,clean:String)->Dictionary:
	## After the war leader asked "Which town?", a reply naming a held town
	## carries the order that was given, at that town. {} otherwise.
	var pending:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if not bool(pending.get("which_town",false)) or Hall._day()-int(pending.get("day",-99))>PENDING_DAYS: return {}
	var lower:=clean.to_lower()
	for town:Dictionary in WarOrders.held_towns():
		if WarOrders._name_hit(lower,String(town.name)):
			var said:=String(pending.get("text",""))
			# The order was about what the garrison does with its people.
			var measures:=Measures.read(said)
			if not measures.is_empty():
				var on_town:=WarOrders._measure_reading(said,String(Measures.conditions(said.to_lower()).main),town,measures,false)
				if not on_town.is_empty(): return on_town
			var fate:=preload("res://scripts/town_fate.gd").fate_words(said.to_lower())
			if fate.is_empty() and pending.get("fate") is Dictionary: fate=(pending.fate as Dictionary).duplicate()
			if fate.is_empty(): return {}
			return {"kind":"fate","target":town,"fate":fate,"full":false,"insist":false,"place":"","army_words":false,"text":said.substr(0,300)}
	return {}

static func live_verb_allowed(verb:String,text:String)->bool:
	## The live reading may sharpen an order, never turn a punishment into
	## moving stores or a party, nor move goods on words that name none.
	if is_harm(text) and not verb in ["kill","maim","detain","exile","terrify","penance"]: return false
	match verb:
		"take": return _re(EXPLICIT_TAKE_PATTERN).search(text)!=null
		"give": return _resource_in(text.to_lower())!="" or _re("(?i)\\b(gift|gifts|goods|reward|bundle)\\b").search(text)!=null
		"send": return _re(String(VERB_PATTERNS[VERB_PATTERNS.size()-1][1])).search(text)!=null or _re("(?i)\\b(scouts?|scouting|explore|expedition|party|envoys?|messengers?|embassy)\\b").search(text)!=null
	return true

static func harm_to_people(text:String,cls:Dictionary,list:Array[Dictionary],live:Dictionary={})->String:
	## Harm ordered on a people rather than a person: "group" when its object
	## is a people as a body ("all the males of Tsaren", "every man in
	## Tsaren", "them all"), "place" when it is a town or people by name
	## ("slaughter the Esurai", "death to Tsaren"); "" when the harm is
	## aimed at one person, or is no harm at all. Read from the ruler's own
	## words; a live reading may add a group object but can never replace
	## one with somebody in the hall.
	var verb:=String(cls.get("verb",""))
	var lower:=text.to_lower()
	var fate_kill:=bool(TownFateWords.fate_words(lower).get("kill_men",false))
	var live_harm:=String(live.get("act",""))=="command" and String(live.get("verb","")) in ["kill","maim"]
	if not (verb in ["kill","maim"] or fate_kill or live_harm or is_harm(text)): return ""
	var object:=_harm_object(text,cls)
	if _clear_person(object,list): return ""
	if _re(GROUP_OBJECT_PATTERN).search(object)!=null: return "group"
	if _names_a_place(object.to_lower()): return "place"
	if not live.is_empty():
		var said:=(String(live.get("object",""))+" "+String(live.get("target_ref",""))).strip_edges()
		if said!="" and _re(GROUP_OBJECT_PATTERN).search(said)!=null: return "group"
		if said!="" and _names_a_place(said.to_lower()): return "place"
	return ""

static func _harm_object(text:String,cls:Dictionary)->String:
	## The words the harm falls on: from the verb on (the verb phrase itself
	## may hold "his" or "him"); without a verb, the order less its lead
	## ("I want you to") and any opening vocative. A closing vocative
	## ("..., war leader!") is dropped too.
	var clean:=text.strip_edges()
	var at:=int(cls.get("verb_at",-1))
	var own:=String(cls.get("text",clean))==clean
	var object:=clean.substr(at) if own and at>=0 and at<clean.length() else _strip_leads(clean)
	var lower:=object.to_lower()
	for lead:String in ["you to ","you "]:
		if lower.begins_with(lead): object=object.substr(lead.length()); lower=object.to_lower()
	var comma:=object.find(",")
	if not (own and at>=0) and comma>0 and comma<28 and object.substr(0,comma).split(" ",false).size()<=3: object=object.substr(comma+1).strip_edges()
	var last:=object.rfind(",")
	if last>0:
		var tail:=object.substr(last+1).strip_edges().trim_suffix("!").trim_suffix(".").strip_edges()
		if tail.split(" ",false).size()<=4 and _re("(?i)\\b(him|her|himself|herself|you|yourself|kill|slay|then|and)\\b").search(tail)==null: object=object.substr(0,last)
	return object

static func _clear_person(object:String,list:Array[Dictionary])->bool:
	## Does the object name one person: by name, by title, or "him"/"her"/"you"?
	## ("the men that you have tied up": that "you" is who did the tying.)
	for m:Dictionary in mentions(object,list):
		if String(m.by) in ["name","title"] and not _theirs_not_them(m): return true
		if String(m.by)=="pronoun" and String(m.word) in PERSON_PRONOUNS and not _clause_subject(object,m): return true
	return false

## "Rovik's men", "Kishan's household": people or things of theirs, not the
## person ("Rovik's hands" is still Rovik).
static func _theirs_not_them(m:Dictionary)->bool:
	var of:=String(m.get("of",""))
	return of!="" and _re("(?i)^"+BODY_PARTS+"$").search(of)==null

const OWN_PEOPLE_WORDS:=["men","band","fighters","warriors","soldiers","spears","family","kin","kinsmen","household","sons","daughters","wife","wives","husband","children","people","folk","servants","guards","garrison","followers","hunters","scouts"]

static func _owned_people(object:String,list:Array[Dictionary])->String:
	## Harm on people who belong to one of ours ("Rovik's men", "Kishan's
	## family"): the words as said, or "". Never the owner, never a town.
	for m:Dictionary in mentions(object,list):
		if String(m.by) in ["name","title"] and String(m.get("of","")) in OWN_PEOPLE_WORDS:
			return object.substr(int(m.at),int(m.end)-int(m.at)).strip_edges()+"'s "+String(m.of)
	return ""

## "You" doing something inside the words ("the men that you have tied up",
## "those you hold"): the one who did it, never the one the act falls on.
static func _clause_subject(text:String,m:Dictionary)->bool:
	if String(m.get("word",""))!="you": return false
	var after:=text.substr(int(m.end)).to_lower()
	return _re("^\\s*('ve|'d|have|had|hold|held|took|take|bound|tied|caught|captured|keep|kept|are|were|rounded|seized|brought|left|saw|found|will|shall|can|could|must|should|may|did|do|guard|guarded|chained|locked|drove|burned|spared|let)\\b").search(after)!=null

static func _names_a_place(lower:String)->bool:
	## A town (ours or theirs) or a people named in the words.
	var names:Array[String]=[]
	for t:Dictionary in WarOrders.held_towns(): names.append(String(t.name))
	for t:Dictionary in WarOrders.known_places(): names.append(String(t.name))
	if WorldSimulation.world!=null:
		for c:Dictionary in WorldSimulation.world.civilizations:
			if String(c.get("id",""))!="player": names.append(String(c.get("name","")))
	for n:String in names:
		if n!="" and WarOrders._name_hit(lower,n): return true
	return false

static func _people_reading(text:String,cls:Dictionary,audience:Dictionary,live:Dictionary,people:String)->Dictionary:
	## The war reading for harm ordered on a people. A town named with no
	## people words ("burn Tsaren") keeps its ordinary war reading.
	var civ:=String(audience.get("civ_id",""))
	var id:=String(audience.get("id",""))
	if people=="place":
		var plain:=WarOrders.read(text,civ,id)
		if not plain.is_empty() and String(plain.get("kind",""))!="held": return plain
	var cverb:=String(cls.get("verb",""))
	var verb:="maim" if cverb=="maim" or (cverb!="kill" and String(live.get("verb",""))=="maim") else "kill"
	return WarOrders.group_harm_reading(text,verb,String(live.get("object","")),civ,id)

static func _people_route(text:String,cls:Dictionary,audience:Dictionary,live:Dictionary,people:String)->Dictionary:
	## Where harm ordered on a people goes: {verb:"war", war} for a town,
	## ours or theirs; {verb:"order"} for words about our own people with no
	## town or foe in them ("kill all the rebels"), which go to the council's
	## own path like any other order. Never a person in the hall.
	var reading:=_people_reading(text,cls,audience,live,people)
	# "Put the prisoners to death" with nobody of theirs in our hands: the
	# captives' own plain answer (we hold none), never a standing order.
	if String(reading.get("kind",""))=="no_town":
		var captive:=WarOrders.captive_reading(text)
		if not captive.is_empty() and String(captive.get("part",""))=="prisoners": return {"verb":"war","war":captive}
	if String(reading.get("kind",""))=="no_town" and people=="group" and _re("(?i)\\b(their|theirs|them|the enemy|enemy|foes?|those people)\\b").search(text)==null and not _names_a_place(text.to_lower()) and not _any_war():
		var out:={"verb":"order","harm":""}
		out.erase("war")
		return out
	return {"verb":"war","war":reading}

static func _any_war()->bool:
	if WorldSimulation.world==null: return false
	for c:Dictionary in WorldSimulation.world.civilizations:
		var rel:Dictionary=c.get("player_relation",{}) if c.get("player_relation") is Dictionary else {}
		if bool(rel.get("at_war",false)): return true
	return false

static func _confirmed_war(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary)->Dictionary:
	## After "Shall I march on it?", the god's yes sends that march. {} when
	## there is no such question open or these words are not a yes.
	var pending:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if not bool(pending.get("confirm",false)) or Hall._day()-int(pending.get("day",-99))>PENDING_DAYS: return {}
	if not bool(context.get("confirm",false)) and _re(CONFIRM_PATTERN).search(clean)==null and _re(INSIST_PATTERN).search(clean)==null: return {}
	var march:=WarOrders.read(String(pending.get("text","")),String(audience.get("civ_id","")),id)
	if march.is_empty(): return {}
	var cls:=classify(clean)
	cls["act"]="command"; cls["verb"]="war"; cls["war"]=march
	return _perform(id,audience,list,"war",_entry(list,String(pending.get("actor",""))),{},clean,cls,false,context)

static func _sovereign_decree(id:String,text:String,context:Dictionary)->Dictionary:
	## Weapons of mass destruction are loosed, or forbidden again, only by the
	## god's own words here (sovereign_weapons.gd); the decision is recorded and
	## remembered. Weapons the realm does not know yet are ordinary speech.
	var decree:=Sovereign.parse_decree(text)
	if decree.is_empty(): return {}
	var means:Array=[]
	for m:String in decree.means:
		if m in WorldSimulation.state.known_discoveries: means.append(m)
	if means.is_empty(): return {}
	if not bool(context.get("echoed",false)):
		Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":Hall._day(),"aside":false})
	var names:Array[String]=[]
	for m:String in means:
		if String(decree.decree)=="authorize": WorldSimulation.military.record_sovereign_decision(m,{"source":"court","spoken":text,"day":Hall._day(),"audience":id})
		else: WorldSimulation.military.revoke_sovereign_decision(m)
		names.append(Sovereign.label(m))
	var r:=_result("sovereign",{},{},text,false)
	r.stage="sovereign_decree"
	r["sovereign"]={"decree":String(decree.decree),"means":means}
	r.outcome=("Your word is recorded: the generals may now use %s. The realm and its neighbours will remember that the decision was yours." if String(decree.decree)=="authorize" else "Your word is recorded: no general may use %s.") % ", ".join(names)
	return r

static func _parties(text:String,cls:Dictionary,audience:Dictionary,list:Array[Dictionary],live:Dictionary)->Dictionary:
	## Who must act and on whom.
	var found:=mentions(text,list)
	var verb:=String(cls.verb)
	var at:=int(cls.verb_at)
	var actor:Dictionary={}
	var actor_mention:Dictionary={}
	var guards:=false
	var lower:=text.to_lower()
	for m:Dictionary in found:
		if String(m.by)=="guards" and (at<0 or int(m.at)<at): guards=true
	if not live.is_empty():
		var aref:=String(live.get("actor_ref",""))
		if aref!="" and not aref.to_lower() in ["you","the god","god","i","me"]: actor=resolve_ref(aref,audience,list,"")
		elif aref.to_lower()=="you": actor=_speaker_entry(list)
	if actor.is_empty() and not guards and at>=0:
		for m:Dictionary in found:
			if String(m.by) in ["name","title"] and int(m.at)<at:
				var between:=lower.substr(int(m.end),at-int(m.end)).strip_edges()
				between=between.trim_prefix(",").trim_prefix("—").trim_prefix("-").strip_edges()
				if between in ["","now","you","shall","must","will","go","go and","you will","you must"] or between.begins_with(",") :
					actor=_entry(list,String(m.key)); actor_mention=m
		# Vocative at the end: "Kill him, Ansel!"
		if actor.is_empty() and not found.is_empty():
			var last:Dictionary=found[found.size()-1]
			if String(last.by) in ["name","title"] and int(last.at)>at and lower.substr(int(last.end)).strip_edges().trim_suffix("!").trim_suffix(".").strip_edges()=="" and lower.substr(0,int(last.at)).strip_edges().ends_with(","):
				actor=_entry(list,String(last.key)); actor_mention=last
	if actor.is_empty() and not guards and at<0:
		for m:Dictionary in found:
			if String(m.by) in ["name","title"] and int(m.at)==0: actor=_entry(list,String(m.key)); actor_mention=m
	if actor.is_empty() and not guards and verb in ["give","send","order","take"]:
		actor=_speaker_entry(list)
		if verb=="send" and String(actor.get("kind",""))=="envoy": actor={}
	var actor_key:=String(actor.get("key",""))
	var target:Dictionary={}
	# The realm's own reading already named them (court_realm_acts.person_verb).
	if String(cls.get("target_key",""))!="": target=_entry(list,String(cls.target_key))
	if target.is_empty() and not live.is_empty() and String(live.get("target_ref",""))!="":
		target=resolve_ref(String(live.target_ref),audience,list,actor_key)
	if target.is_empty():
		var candidates:Array[Dictionary]=[]
		for m:Dictionary in found:
			if m==actor_mention or String(m.by)=="guards": continue
			if String(m.by)=="god" and not verb in CRUEL: continue   # "a stone to me" is not a target
			if String(m.by)=="pronoun" and _clause_subject(text,m): continue   # "the men you have tied up"
			if String(m.by) in ["name","title"] and verb in CRUEL and _theirs_not_them(m): continue   # "Rovik's men"
			if verb=="appoint" and String(m.by)=="title" and not candidates.is_empty(): continue
			candidates.append(m)
		var chosen:Dictionary={}
		for m:Dictionary in candidates:
			if at<0 or int(m.at)>=at: chosen=m; break
		if chosen.is_empty() and not candidates.is_empty(): chosen=candidates[0]
		if not chosen.is_empty(): target=_land(chosen,audience,list,actor_key)
	# Nobody named: the last one dealt with, or the one before the god. Never
	# for harm unless the words point at one person ("his hands", "the
	# traitor"): "put the captives to death" or "kill Tavo" (nobody we know)
	# never falls on whoever is standing there.
	# (Not when the words name something that is nobody in the hall: "dismiss
	# the war chief" with no such office is nobody, never the one spoken to.)
	if target.is_empty() and verb in ["penance","demote","raise","bless","boon","terrify","pardon","curse"] and not _object_named(text,cls):
		target=_salient(audience,list,actor_key)
	elif target.is_empty() and verb in CRUEL and _points_at_one(text.substr(maxi(0,at)) if at>=0 else text):
		target=_salient(audience,list,actor_key)
	if verb in ["send","order"] and target.is_empty(): target=actor
	return {"actor":actor,"target":target,"guards":guards}

## Words after the verb that name something, but no one in the hall ("the
## war chief" with nobody holding it, "the harvest"): nobody is assumed.
static func _object_named(text:String,cls:Dictionary)->bool:
	var at:=int(cls.get("verb_end",-1))
	if at<0 or at>text.length(): return false
	var rest:=text.substr(at).to_lower()
	rest=_re("(?i)\\b(now|at once|today|tonight|again|too|as well|please|before (the court|them all|everyone|us all|you all)|for (his|her|their|its) [\\w' ]+|with [\\w' ]+|up)\\b").sub(rest,"",true)
	rest=_re("[^a-z' ]").sub(rest," ",true).strip_edges()
	if rest=="": return false
	for p:String in PRONOUNS:
		if _re("\\b%s\\b" % _escape(p)).search(rest)!=null: return false
	return true

## Words that point at one person without naming them: "him", "her", "you",
## "the traitor", or a possessive on a body ("cut off his hands").
static func _points_at_one(text:String)->bool:
	for m:Dictionary in mentions(text,[] as Array[Dictionary]):
		if String(m.by)=="pronoun" and String(m.word) in PERSON_PRONOUNS and not _clause_subject(text,m): return true
	return _re("(?i)\\b(his|her)\\b").search(text)!=null

static func _perform(id:String,audience:Dictionary,list:Array[Dictionary],verb:String,actor:Dictionary,target:Dictionary,text:String,cls:Dictionary,insist:bool,context:Dictionary)->Dictionary:
	audience.erase("echoed_here")
	if not bool(context.get("echoed",false)):
		Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":Hall._day(),"aside":false})
		audience["echoed_here"]=text
	if verb in ["kill","maim"]:
		# Last guard: harm whose object is a people or a town's people never
		# lands on the actor, the one spoken to or anyone else in the hall.
		var said:=String(cls.get("text",text))
		var live:Dictionary=context.get("live",{}) if context.get("live") is Dictionary else {}
		var people:=harm_to_people(said,cls,list,live)
		if people!="":
			cls=cls.duplicate(); cls.merge(_people_route(said,cls,audience,live,people),true)
			verb=String(cls.verb); target={} if verb=="war" else actor
	if verb in ["kill","maim"]:
		# "Whoever resists, kill him", "if he lies again, kill him": harm only on
		# a condition is a standing word to a garrison, or a threat to the one
		# named; nobody dies now.
		var said:=String(cls.get("text",text))
		var cond:=Measures.conditions(said.to_lower())
		if String(cond.clause)!="" and not is_harm(String(cond.main)):
			var reading:=WarOrders.read(said,String(audience.get("civ_id","")),id)
			if reading.is_empty(): reading=WarOrders.conditional_reading(said,id)
			# "If he lies again": one person, threatened. "Whoever resists": nobody here.
			var one:=_re("(?i)\\b(if|should|whenever|when) (he|she|you)\\b").search(String(cond.clause))!=null
			if not reading.is_empty():
				cls=cls.duplicate(); cls["verb"]="war"; cls["war"]=reading; verb="war"; target={}
			elif one and not target.is_empty() and String(target.get("kind",""))!="god":
				cls=cls.duplicate(); cls["verb"]="terrify"; verb="terrify"; actor={}
			else:
				return _fallback(id,_result(verb,actor,{},text,insist),"Nobody here was named.")
	if verb in ["kill","maim"] and String(audience.get("origin",""))=="court":
		# "Kill them" with nobody named: never anyone in the hall. About a town
		# we hold it is the war leader's question; otherwise the court waits
		# to be told who is meant.
		var said:=String(cls.get("text",text))
		var object:=_harm_object(said,cls)
		if not _clear_person(object,list) and _re("(?i)\\b(them|those|these|they)\\b").search(object)!=null:
			var reading:=WarOrders.read(said,String(audience.get("civ_id","")),id)
			if reading.is_empty(): reading=WarOrders.pronoun_harm_reading(said,id)
			if not reading.is_empty():
				cls=cls.duplicate(); cls["verb"]="war"; cls["war"]=reading; verb="war"; target={}
			else:
				return _fallback(id,_result(verb,actor,{},text,insist),"Nobody here was named.")
	if verb in ["detain","exile"]:
		# Binding or driving out a people ("lock up all the men", "detain the
		# villagers") is what a garrison does to a town, or the council's
		# business at home: never a hand laid on anyone in the hall.
		var said:=String(cls.get("text",text))
		var object:=_harm_object(said,cls)
		if not _clear_person(object,list) and _re(GROUP_OBJECT_PATTERN).search(object)!=null:
			var reading:=WarOrders.read(said,String(audience.get("civ_id","")),id)
			cls=cls.duplicate()
			if not reading.is_empty(): cls["verb"]="war"; cls["war"]=reading; verb="war"; target={}
			else: cls["verb"]="order"; verb="order"; target=actor
		elif String(audience.get("origin",""))=="court" and not _clear_person(object,list) and _re("(?i)\\b(them|those|these|they)\\b").search(object)!=null:
			# "Tie them up" with nobody named: a town's people, or nobody here.
			var reading:=WarOrders.read(said,String(audience.get("civ_id","")),id)
			if not reading.is_empty():
				cls=cls.duplicate(); cls["verb"]="war"; cls["war"]=reading; verb="war"; target={}
			else:
				return _fallback(id,_result(verb,actor,{},text,insist),"Nobody here was named.")
	# A war order falls on a town or an army, never on a person in the hall.
	if verb=="war": target={}
	# A law for our own people: the council keeps it; nobody here is touched.
	if verb=="law":
		audience.erase("pending_command")
		var speaker_now:=_speaker_entry(list)
		return _law(id,audience,_result("law",speaker_now,{},text,insist),speaker_now,text,cls,context)
	var r:=_result(verb,actor,target,text,insist)
	audience.erase("pending_command")
	if String(target.get("kind",""))=="god":
		r.outcome="No hand in the hall will turn on the god. The whole court falls on its face."
		r.stage="prostrate"
		_apply_court(id,"terrify",{},[])
		return r
	if verb=="war": return _war(id,audience,list,r,actor,text,cls,insist)
	# The engine decides obedience before anything is done or voiced.
	var person:=_person(actor)
	var ob:=obedience(person,verb,insist,_roll(audience,verb+String(actor.get("key",""))))
	# The actor may not be the victim; a self-strike becomes the guards'.
	if not actor.is_empty() and String(actor.key)==String(target.get("key","")) and verb in CRUEL:
		actor={}; ob={"id":"obey","manner":"guards","chance":0.0}; r.actor={}
	r.obedience=ob
	_focus(audience,target,actor)
	match String(ob.id):
		"hesitate":
			audience["pending_command"]={"verb":verb,"actor":String(actor.get("key","")),"target":String(target.get("key","")),"day":Hall._day(),"text":text.substr(0,200)}
			r.stage="hesitate"
			r.outcome="%s has not done it. They hold back and plead with you; your word still stands." % String(actor.name)
			return r
		"refuse":
			return _refusal(id,audience,list,r,person,verb)
	# The court's known commoners and the council's people out of office: the
	# god's word reaches them as it reaches the officials (court_realm_acts.gd).
	var kind:=String(target.get("kind",""))
	if kind=="known" and verb in KNOWN_ACTS: return _known_act(id,audience,r,verb,target,cls,text)
	if kind=="former" and verb in KNOWN_ACTS: return _former_act(id,audience,r,verb,actor,target,cls,text)
	# A gift of what the stores do not hold: honour instead, said plainly.
	if verb=="boon" and String(cls.get("gift_material",""))!="": return _honour_instead(id,audience,r,target,String(cls.gift_material))
	# "Reward Suri with twenty food": the amount named, not the stock boon.
	if verb=="boon" and String(cls.get("resource",""))!="" and float(cls.get("amount",0.0))>0.0:
		verb="give"; r.verb="give"; r.stage="give"
	match verb:
		"kill","exile","detain","maim": return _punish(id,audience,list,r,verb,actor,target,cls)
		"penance","terrify","bless","boon","raise": return _spoken_act(id,audience,r,verb,target)
		"demote": return _demote(id,audience,r,target)
		"appoint": return _appoint(id,audience,r,target,text)
		"give": return _give(id,audience,r,target,cls)
		"take": return _take(id,audience,r,target,cls)
		"send": return _send(id,audience,r,actor,cls,context,text)
		"pardon": return _pardon(id,audience,r,target)
		"curse": return _curse(id,audience,r,target)
		"marry": return _marry(id,audience,r,target)
	return _order(id,audience,r,actor,text,context)

## Acts that reach a known commoner or one of the council's people out of office.
const KNOWN_ACTS:=["kill","exile","detain","maim","penance","terrify","bless","boon","raise","demote","appoint","give","take","pardon","curse","marry"]
const METALS:=["bronze","iron","gold","silver","copper","tin","steel"]

static func _honour_instead(id:String,audience:Dictionary,r:Dictionary,target:Dictionary,material:String)->Dictionary:
	## A gift of what the stores do not hold (bronze before anyone works metal):
	## nothing leaves the stores; the one named is honoured before the court.
	var name:=String(target.get("name",""))
	var why:="There is no %s in your stores: nobody here has ever worked it." % material if material in METALS else "There is no %s in your stores to give." % material
	if target.is_empty():
		r.stage="none"; r.executed=false
		r.outcome=why+" Nothing is given."
		return r
	match String(target.get("kind","")):
		"official":
			var pid:=int(target.person_id)
			r.effects=_apply_court(id,"raise_up",_person(target),[pid])
			GovernmentPeopleSystem.record_person_memory(pid,"The god would have given me %s, and honoured me before the court instead." % material,"divine",0.6,{"emotion":"awe","outcome":"honoured"})
			r.witness_ids=_witness_ids(id,[pid])
		"figure":
			HistoricalFigures.note(String(target.figure_id),Hall._day(),"Honoured by the ruler before the court.",1)
			r.witness_ids=_witness_ids(id,[])
		"known":
			Persons.perform(id,"exalt",{"target":{"kind":"known","id":String(target.known_id)}},{"silent":true})
		_:
			r.stage="none"; r.executed=false
			r.outcome=why+" Nothing is given."
			return r
	r.stage="raise"; r.executed=true; r.reaction="delighted"; r.verb="boon"
	r.terms={"resource":material,"amount":0}
	r.outcome="%s %s is honoured before the court instead; nothing leaves the stores." % [why,name]
	return r

static func _pardon(id:String,audience:Dictionary,r:Dictionary,target:Dictionary)->Dictionary:
	## Mercy: the bound walk free; one who stands charged with nothing hears it.
	var name:=String(target.get("name",""))
	match String(target.get("kind","")):
		"official":
			var pid:=int(target.person_id)
			r.effects=DIVINE.apply_to_court("bless",_person(target),_court_watchers(id,[pid]))
			GovernmentPeopleSystem.record_person_memory(pid,"The god spoke mercy over me before the court, though nothing stood against me.","divine",0.55,{"emotion":"relief","outcome":"pardoned"})
			r.outcome="Nothing stands against %s; they hear your mercy before the court and are glad of it." % name
			r.stage="bless"; r.executed=true; r.reaction="pleased"; r.witness_ids=_witness_ids(id,[pid])
			return r
		"figure":
			var figure:Dictionary=HistoricalFigures.by_id(String(target.figure_id))
			if figure.is_empty(): return _fallback(id,r,"")
			if String(figure.get("status",""))=="detained":
				figure["status"]="living"
				HistoricalFigures.note(String(target.figure_id),Hall._day(),"Freed by the ruler's word.")
				r.outcome="%s is freed at your word and walks out of the guards' keeping. Their old command stays with whoever took it up." % name
			else:
				HistoricalFigures.note(String(target.figure_id),Hall._day(),"Pardoned by the ruler before the court.")
				r.outcome="Nothing stands against %s; your mercy is carried to them." % name
			r.effects=_apply_court(id,"bless",{"person_id":0,"name":name},[])
			r.stage="none"; r.executed=true; r.reaction="pleased"; r.witness_ids=_witness_ids(id,[])
			return r
	return _fallback(id,r,"")

static func _curse(id:String,audience:Dictionary,r:Dictionary,target:Dictionary)->Dictionary:
	## The god's curse: terror before the court, and love that does not come back soon.
	var name:=String(target.get("name",""))
	match String(target.get("kind","")):
		"official":
			var pid:=int(target.person_id)
			r.effects=DIVINE.apply_to_court("terrify",_person(target),_court_watchers(id,[pid]))
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":-0.06,"resentment":0.04,"hold_days":30})
			GovernmentPeopleSystem.record_person_memory(pid,"The god cursed me before the whole court.","divine",0.85,{"emotion":"terror","outcome":"cursed"})
			r.outcome="You curse %s before the court. They go grey; nobody on the bench will meet their eyes." % name
			r.stage="terrify"; r.executed=true; r.reaction="furious"; r.witness_ids=_witness_ids(id,[pid])
			return r
		"figure":
			var done:=_figure_act(id,r,"terrify",target)
			done.outcome="You curse %s. %s" % [name,String(done.outcome)]
			return done
	return _fallback(id,r,"")

static func _marry(id:String,audience:Dictionary,r:Dictionary,target:Dictionary)->Dictionary:
	## A match for one of the council: said plainly, nothing done without a name.
	r.stage="none"; r.executed=false
	r.outcome="The court makes no match for %s without your naming whom they are to wed." % String(target.get("name","them"))
	return r

static func _court_watchers(id:String,exclude:Array)->Array:
	var watchers:Array=[]
	for wid in _witness_ids(id,exclude):
		var p:=Hall._official(int(wid))
		if not p.is_empty(): watchers.append(p)
	return watchers

## The persons engine's action for each verb on a known commoner.
const KNOWN_ACTION:={"kill":"execute","exile":"exile","maim":"maim","detain":"bind","bless":"exalt","raise":"exalt","boon":"reward","give":"reward","terrify":"terrify","penance":"penance","curse":"curse","marry":"marry_off","pardon":"free"}
const KNOWN_STAGE:={"kill":"kill","exile":"exile","maim":"maim","detain":"detain","bless":"raise","raise":"raise","boon":"boon","give":"boon","terrify":"terrify","penance":"penance","curse":"terrify","appoint":"appoint"}

static func _known_act(id:String,audience:Dictionary,r:Dictionary,verb:String,target:Dictionary,cls:Dictionary,text:String)->Dictionary:
	## One of the court's known commoners (court_persons.gd), before the god or
	## brought in: the persons engine decides and applies it; the court sees it.
	var ref:={"kind":"known","id":String(target.get("known_id",""))}
	var p:=Persons.by_id(String(ref.id))
	var name:=String(p.get("name",target.get("name","")))
	if p.is_empty() or String(p.get("status",""))!="living": return _fallback(id,r,"%s is no longer among the living." % name if not p.is_empty() else "")
	var params:={"target":ref}
	var action:=String(KNOWN_ACTION.get(verb,""))
	match verb:
		"maim": params["harm"]=String(cls.get("harm","mutilate"))
		"pardon": action="free" if bool(p.get("bound",false)) else "pardon"
		"appoint":
			var office:=_office_in(text)
			if _re("(?i)\\b(priest|priestess|keeper of (the|my|your) (god's )?fire|holy|shaman|fire-keeper)\\b").search(text)!=null: action="make_priest"
			elif office!="" and GovernmentPeopleSystem.office_is_active(office): action="make_official"; params["office"]=office
			else: action="exalt"
		"demote","take":
			r.stage="none"; r.executed=false
			r.outcome="%s holds no office and keeps nothing apart from their household; there is nothing to take." % name
			return r
	if action=="": return _fallback(id,r,"")
	var here:=bool(target.get("speaker",false))
	var done:=Persons.perform(id,action,params,{"silent":true})
	if not bool(done.get("ok",false)): return _fallback(id,r,"")
	r.executed=true
	r.stage=String(KNOWN_STAGE.get(verb,"none"))
	# The god's fire has no old keeper to take the marks from: they are honoured.
	if action in ["make_priest","exalt"]: r.stage="raise"
	if verb=="maim": r["harm"]=String(params.get("harm","mutilate"))
	r.removed=verb in ["kill","exile"]
	r.reaction="furious" if verb in ["kill","exile","maim","terrify","curse","detain"] else ("delighted" if verb in ["bless","raise","boon","give","appoint"] else "neutral")
	var said:=String(done.get("outcome",""))
	if not here:
		# Not before the god: brought in under guard, then it is done.
		var rest:=said.trim_prefix(name+" ")
		said=("%s was brought in under guard from %s and %s" % [name,String(p.get("village","their hearth")),rest.trim_prefix("was ")]) if rest!=said and rest.begins_with("was ") else "%s was brought in under guard from %s. %s" % [name,String(p.get("village","their hearth")),said]
	r.outcome=said
	r["known"]=String(ref.id)
	r.witness_ids=_witness_ids(id,[])
	if bool(done.get("conclude",false)) or (here and r.removed): r.terminal=true
	return r

static func _former_act(id:String,audience:Dictionary,r:Dictionary,verb:String,actor:Dictionary,target:Dictionary,cls:Dictionary,text:String)->Dictionary:
	## One of the council's people out of office or held under guard: the god's
	## word reaches them through GovernmentPeopleSystem.
	var pid:=int(target.get("person_id",0))
	var person:=GovernmentPeopleSystem.person_snapshot(pid)
	var name:=String(person.get("name",target.get("name","")))
	var status:=String(person.get("status",""))
	if person.is_empty() or not status in ["active","detained"]: return _fallback(id,r,"")
	var held:=status=="detained"
	var watchers:=_court_watchers(id,[])
	r.witness_ids=_witness_ids(id,[])
	match verb:
		"kill":
			var dead:=GovernmentPeopleSystem.person_put_to_death(pid)
			if not bool(dead.get("ok",false)): return _fallback(id,r,String(dead.get("reason","")))
			r.effects=DIVINE.apply_to_court("strike_down",{"person_id":0,"name":name},watchers)
			r.outcome="%s was %sput to death at your word, before the court. It cost you legitimacy and cohesion." % [name,"brought out of the guards' keeping and " if held else ""]
			r.removed=true; r.executed=true; r.reaction="furious"
		"exile":
			if held: GovernmentPeopleSystem.person_released(pid)
			var gone:=GovernmentPeopleSystem.person_departs(pid,"exiled")
			if not bool(gone.get("ok",false)): return _fallback(id,r,String(gone.get("reason","")))
			r.effects=DIVINE.apply_to_court("cast_out",{"person_id":0,"name":name},watchers)
			r.outcome="%s was cast out of the realm at your word." % name
			r.removed=true; r.executed=true; r.reaction="furious"
		"detain":
			if held:
				r.stage="none"; r.outcome="%s is already bound and under guard at your word." % name
				return r
			var bound:=GovernmentPeopleSystem.person_departs(pid,"detained")
			if not bool(bound.get("ok",false)): return _fallback(id,r,String(bound.get("reason","")))
			r.effects=DIVINE.apply_to_court("penance",{"person_id":0,"name":name},watchers)
			r.outcome="%s was bound and put under guard at your word." % name
			r.executed=true; r.reaction="furious"
		"maim":
			var harm:=String(cls.get("harm","mutilate"))
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":0.3 if harm=="mutilate" else 0.2,"resentment":0.2 if harm=="mutilate" else 0.12,"love":-0.12,"hold_days":90})
			GovernmentPeopleSystem.record_person_memory(pid,"The god had me %s before the whole court." % String({"beat":"flogged","humiliate":"shamed"}.get(harm,"maimed")),"divine",0.9,{"emotion":"terror","outcome":"maimed"})
			r.effects=DIVINE.apply_to_court("terrify",{"person_id":0,"name":name},watchers)
			r.outcome="%s was %s at your word, before the court. They live, and they will not forget it." % [name,String({"beat":"flogged bloody","humiliate":"shamed"}.get(harm,"maimed"))]
			r.executed=true; r.reaction="furious"; r.harm=harm
		"pardon":
			if held:
				var freed:=GovernmentPeopleSystem.person_released(pid)
				if not bool(freed.get("ok",false)): return _fallback(id,r,String(freed.get("reason","")))
				GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":0.1,"fear":-0.05,"resentment":-0.05})
				GovernmentPeopleSystem.record_person_memory(pid,"The god had my bonds cut and let me walk free.","divine",0.8,{"emotion":"relief","outcome":"freed"})
				r.effects=DIVINE.apply_to_court("bless",{"person_id":0,"name":name},watchers)
				r.outcome="%s is freed at your word and walks out of the guards' keeping. The office they held stays with the one who took it up." % name
			else:
				GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":0.06,"fear":-0.03})
				r.outcome="Nothing stands against %s; they hear your mercy." % name
			r.stage="none"; r.executed=true; r.reaction="pleased"
		"appoint":
			var office:=_office_in(text)
			if office=="" or not GovernmentPeopleSystem.office_is_active(office):
				GovernmentPeopleSystem.adjust_person_bonds(pid,{"respect":0.08,"love":0.05})
				r.outcome="%s is honoured before the court; no office was named for them." % name
				r.stage="raise"; r.executed=true; r.reaction="delighted"
				return r
			if held: GovernmentPeopleSystem.person_released(pid)
			var former:Dictionary=GovernmentPeopleSystem.officeholder(office)
			var appointed:=GovernmentPeopleSystem.mark_central_appointment(pid,office)
			if appointed.is_empty(): return _fallback(id,r,"%s cannot hold that office now." % name)
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"respect":0.08,"love":0.06,"obligation":0.06,"resentment":-0.05})
			GovernmentPeopleSystem.record_person_memory(pid,"The god gave me back an office before the whole court: %s." % String(appointed.get("office_title",office)),"divine",0.8,{"emotion":"awe","outcome":"appointed"})
			if not former.is_empty() and int(former.person_id)!=pid:
				GovernmentPeopleSystem.adjust_person_bonds(int(former.person_id),{"resentment":0.1,"respect":-0.04})
				GovernmentPeopleSystem.record_person_memory(int(former.person_id),"The god gave my office to %s before the court." % name,"divine",0.7,{"emotion":"shame","outcome":"replaced"})
			r.outcome="%s%s is %s again by your word.%s" % [("%s is freed, and " % name) if held else "",name if not held else "",String(appointed.get("office_title",office))," %s no longer holds it." % String(former.name) if not former.is_empty() and int(former.person_id)!=pid else ""]
			r.outcome=r.outcome.replace("and  is","and is")
			r.stage="appoint"; r.executed=true; r.reaction="delighted"
		"demote":
			r.stage="none"; r.executed=false
			r.outcome="%s holds no office now; there is nothing to strip." % name
		"take":
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":0.05,"obligation":0.05})
			r.stage="penance"; r.executed=true
			r.outcome="%s keeps nothing apart from the common stores; the fine becomes a fast and a vigil." % name
		"give","boon":
			var boon:=Hall._boon_terms()
			var resource:=String(cls.get("resource","")) if String(cls.get("resource",""))!="" else String(boon.resource)
			var want:=float(cls.get("amount",0.0)) if float(cls.get("amount",0.0))>0.0 else float(boon.amount)
			var paid:=Hall._debit_player(resource,minf(want,floorf(Hall.player_stock(resource))))
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":0.08,"obligation":0.1,"resentment":-0.05})
			r.terms={"resource":resource,"amount":paid}
			r.outcome=("You gave %s %d %s from the stores." % [name,roundi(paid),resource]) if paid>0.0 else "Your stores hold no %s to give %s." % [resource,name]
			r.stage="give" if paid>0.0 else "none"; r.executed=paid>0.0; r.reaction="delighted"
		"curse","terrify","penance","bless","raise":
			var action:=String({"curse":"terrify","raise":"raise_up"}.get(verb,verb))
			r.effects=DIVINE.apply_to_court(action,person,watchers)
			if verb=="curse": GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":-0.06,"resentment":0.04})
			r.outcome=String({"curse":"You curse %s before the court.","terrify":"Your anger falls on %s before the court.","penance":"%s must fast and keep vigil at your word.","bless":"You bless %s before the court.","raise":"You honour %s before the court."}[verb]) % name
			r.stage=String({"curse":"terrify","raise":"raise"}.get(verb,verb)); r.executed=true; r.reaction="furious" if verb in ["curse","terrify","penance"] else "delighted"
		"marry":
			return _marry(id,audience,r,target)
		_:
			return {}
	return r

static func _law(id:String,audience:Dictionary,r:Dictionary,actor:Dictionary,text:String,cls:Dictionary,context:Dictionary)->Dictionary:
	## A law for our own people: the council takes it up as a standing order
	## (custom_order, never a war order); a harsh law is remembered with dread.
	var law:Dictionary=cls.get("law",{}) if cls.get("law") is Dictionary else {}
	var ctx:=context.duplicate()
	ctx["law"]=true; ctx["audience_id"]=id; ctx["actor"]=actor.duplicate()
	var words:=_strip_vocative(text,actor)
	var routed:=custom_order(words,ctx)
	r.verb="order"; r["law"]=true; r["route"]=String(routed.get("route",""))
	r.reaction="neutral"
	if not bool(routed.get("ok",true)):
		r.stage="none"; r.executed=false
		r.outcome=String(routed.get("outcome",""))
		return r
	r.stage="order"; r.executed=true
	if bool(law.get("harsh",false)): DIVINE.record_people_act("harsh_law")
	if int(actor.get("person_id",0))>0:
		GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"obligation":0.02})
		GovernmentPeopleSystem.record_person_memory(int(actor.person_id),"The god gave the people a law before the court: %s" % words.substr(0,160),"divine",0.55,{"emotion":"duty","outcome":"law"})
	r.outcome="From today it is the law. %s%s" % [String(routed.get("outcome","")),(" The people will fear it." if bool(law.get("harsh",false)) else "")]
	return r

static func _result(verb:String,actor:Dictionary,target:Dictionary,text:String,insist:bool)->Dictionary:
	return {"handled":true,"ok":true,"act":"command","verb":verb,"text":text,"insist":insist,"actor":actor.duplicate(),"target":target.duplicate(),
		"actor_name":String(actor.get("name","")),"target_name":String(target.get("name","")),"executed":false,"terminal":false,"removed":false,
		"outcome":"","stage":verb,"reaction":"neutral","effects":{},"obedience":{"id":"obey","manner":"guards"},"witness_ids":[]}

static func _focus(audience:Dictionary,target:Dictionary,actor:Dictionary)->void:
	var key:=String(target.get("key",""))
	if key=="" or key=="god": key=String(actor.get("key",""))
	if key!="": audience["command_focus"]={"last_ref":key,"day":Hall._day(),"line":(audience.get("lines",[]) as Array).size()}

static func _witness_ids(id:String,exclude:Array)->Array:
	var out:Array=[]
	var audience:=Hall.find(id)
	var speaker_pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	if speaker_pid>0 and not speaker_pid in exclude and not Hall._official(speaker_pid).is_empty(): out.append(speaker_pid)
	for p:Dictionary in Hall.court(id):
		if not int(p.person_id) in exclude and not int(p.person_id) in out: out.append(int(p.person_id))
	return out

static func _apply_court(id:String,action:String,target:Dictionary,exclude:Array)->Dictionary:
	var watchers:Array=[]
	for wid in _witness_ids(id,exclude):
		var p:=Hall._official(int(wid))
		if not p.is_empty(): watchers.append(p)
	return DIVINE.apply_to_court(action,target,watchers)

# --------------------------------------------------------------------------
# Acts
# --------------------------------------------------------------------------

static func _punish(id:String,audience:Dictionary,list:Array[Dictionary],r:Dictionary,verb:String,actor:Dictionary,target:Dictionary,cls:Dictionary={})->Dictionary:
	var kind:=String(target.get("kind",""))
	# Nobody the words name is known here: said plainly, and nobody is touched.
	if target.is_empty():
		var why:=_nobody_named(String(r.text),cls)
		if why=="": return _fallback(id,r,"")
		r.stage="none"; r.executed=false
		r.outcome=why+" Nothing is done."
		return r
	if kind=="envoy": return _punish_envoy(id,audience,r,verb,actor,cls)
	if verb=="maim": return _maim_person(id,audience,r,actor,target,cls)
	var name:=String(target.get("name","them"))
	var by:=String(actor.get("name",""))
	var hand:=" by %s's hand" % by if by!="" else ""
	var action:=String({"kill":"strike_down","exile":"cast_out","detain":"detain"}.get(verb,"strike_down"))
	if kind=="official":
		var pid:=int(target.person_id)
		var before:=_witness_ids(id,[pid])
		if action=="detain":
			var person:=_person(target)
			var gone:=GovernmentPeopleSystem.person_departs(pid,"detained")
			if not bool(gone.get("ok",false)): return _fallback(id,r,String(gone.get("reason","")))
			r.effects=_apply_court(id,"penance",person,[pid])
			GovernmentPeopleSystem.record_person_memory(pid,"The god had me bound and put under guard before the whole court.","divine",0.85,{"emotion":"terror","outcome":"detained"})
			r.outcome="%s was bound and put under guard at your word%s, stripped of office.%s" % [name,hand," %s took up the work." % ", ".join(PackedStringArray(gone.get("successors",[]))) if not (gone.get("successors",[]) as Array).is_empty() else ""]
			r.removed=true
		else:
			var done:=Hall.divine(id,action,String(r.text),pid,{"agent_name":by,"agent_pid":int(actor.get("person_id",0)),"quiet":true})
			if not bool(done.get("ok",false)): return _fallback(id,r,String(done.get("outcome","")))
			r.effects=done.get("effects",{}); r.outcome=String(done.outcome); r.removed=true
			r.terminal=bool(done.get("terminal",false)); r.reaction=String(done.get("reaction","furious")); r.successor=String(done.get("successor",""))
		r.witness_ids=before
		if bool(target.get("speaker",false)) and not r.terminal:
			r.terminal=true
			Hall.conclude(id,String(r.outcome),action)
	elif kind=="figure":
		var figure:Dictionary=HistoricalFigures.by_id(String(target.figure_id))
		var day:=Hall._day()
		# Not before the god: brought in under guard from where they are (the
		# summons the court already has), and it is done before the court.
		var here:=bool(target.get("speaker",false)) or bool(target.get("present",false))
		var at:=figure_at(String(target.figure_id),name)
		var where:=String(target.get("where",at.words))
		var from:=String(target.get("from",at.from))
		if verb=="detain" and String(figure.get("status",""))=="detained":
			r.outcome="%s is already bound and under guard at your word." % name
			r.stage="none"; r.executed=false
			return r
		if verb=="kill": HistoricalFigures.record_death(String(target.figure_id),day,"execution at the ruler's word")
		elif not figure.is_empty():
			figure["status"]="exiled" if verb=="exile" else "detained"; figure["supported"]=false
			HistoricalFigures.note(String(target.figure_id),day,"Cast out of the realm by the ruler's word." if verb=="exile" else "Bound and put under guard by the ruler's word.")
		# Whoever next leads what they led (their band, their garrison).
		var successor:=_succeed(String(target.figure_id),name)
		var metrics:Dictionary=GameState.simulation_metrics
		metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-(0.05 if verb=="kill" else 0.02),0.01,0.99)
		metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-(0.03 if verb=="kill" else 0.01),0.01,0.99)
		r.witness_ids=_witness_ids(id,[])
		r.effects=_apply_court(id,action if action!="detain" else "cast_out",{"person_id":0,"name":name},[])
		var fetched:=("%s was brought in under guard from %s and " % [name,from]) if not here and from!="" else ("%s was brought before you and " % name if not here else "%s was " % name)
		r.outcome=fetched+String({"kill":"killed%s at your word, before the court. It cost you legitimacy and cohesion.","exile":"cast out of the realm%s at your word.","detain":"bound and put under guard%s at your word."}.get(verb,"dealt with%s at your word.")) % hand
		if successor!="": r.outcome+=" %s takes over %s's command." % [successor,WarOrders._given(name)]
		r.removed=true; r.reaction="furious"
		r["where"]=where; r["successor"]=successor
		if here:
			r.terminal=true
			Hall.conclude(id,String(r.outcome),action)
	else:
		return _fallback(id,r,"")
	r.executed=true
	if not actor.is_empty() and int(actor.get("person_id",0))>0: _hand_of_the_god(r,actor,target,verb)
	return r

## Words that are capitalised but are no one's name.
const NOT_NAMES:=["I","The","Our","My","Their","Them","It","Home","Your","War","Battle","Me","You","One","A","An","All","Every","Each","Any","Some","If","And","Then","He","She","They","We","Let","Set",
	"Make","Put","Now","Take","Keep","Kill","Slay","Execute","Behead","Hang","Maim","Blind","Flog","Whip","Bind","Chain","Seize","Arrest","Exile","Banish","Drive","Cut","Burn","Strike","Have","See","Bring","Send","Do","No","Yes","God","Lord"]

## Words after a verb that are no one's name ("kill them", "kill everyone").
const COMMON_OBJECTS:=["him","her","them","it","all","everyone","everybody","anyone","someone","somebody","nobody","none","who","whom","that","this","those","these","now","too","again","first",
	"quickly","slowly","yourself","himself","herself","themselves","me","myself","us","yes","no","then","here","there","already","back","home","away","out","off","up","down"]

static func _nobody_named(text:String,cls:Dictionary={})->String:
	## Why an act on a person landed on nobody, in plain words: a name the
	## court does not know, or a commoner the court knows who is not here.
	var words:Array[String]=[]
	for m in _re("\\b([A-Z][a-z'-]{2,})\\b").search_all(text): words.append(m.get_string(1))
	# "kill tavo": the one word after the verb, when it is no common word.
	var end:=int(cls.get("verb_end",-1))
	if end>0 and end<=text.length():
		var rest:=_re("(?i)^\\s*([a-z][a-z'-]{2,})[\\s!.,]*(now|at once|today)?[\\s!.]*$").search(text.substr(end))
		if rest!=null and not rest.get_string(1).to_lower() in COMMON_OBJECTS:
			words.append(rest.get_string(1).substr(0,1).to_upper()+rest.get_string(1).substr(1).to_lower())
	for word:String in words:
		if word in NOT_NAMES or _names_a_place(word.to_lower()): continue
		var known:Dictionary=preload("res://scripts/court_persons.gd").resolve_name(word)
		if String(known.get("kind",""))=="known":
			var persons:=preload("res://scripts/court_persons.gd")
			var p:Dictionary=persons.by_id(String(known.get("id","")))
			if not p.is_empty():
				var trade:=String(persons.trade_label(String(p.get("trade","")))) if String(p.get("trade",""))!="" else "one of our people"
				var article:=("an " if trade.substr(0,1) in ["a","e","i","o","u"] else "a ") if String(p.get("trade",""))!="" else ""
				return "%s is not before you: %s is %s%s at %s. Summon them first." % [String(p.get("name",word)),"she" if String(p.get("sex",""))=="female" else "he",article,trade,String(p.get("village","home"))]
		return "Nobody at court knows anyone called %s." % word
	return ""

static func _succeed(fid:String,name:String)->String:
	## A war leader of renown killed, cast out or bound: the next war leader
	## (HistoricalFigures.commander finds or raises one) takes his band and
	## the garrison he held. The new commander's name, or "" when he led nothing.
	var mc:Variant=WorldSimulation.military
	var figures:Variant=WorldSimulation.figures
	if mc==null or figures==null: return ""
	# Never the one who is losing the command (relieved, he is still living):
	# kept out of the choosing while the next war leader is found.
	var gone:Dictionary=figures.by_id(fid) if fid!="" else {}
	var status:=String(gone.get("status",""))
	if not gone.is_empty() and status in ["living","wounded"]: gone["status"]="relieved"
	var next:=_succeed_all(mc,figures,fid,name)
	if not gone.is_empty() and String(gone.get("status",""))=="relieved": gone["status"]=status
	return next

static func _succeed_all(mc:Variant,figures:Variant,fid:String,name:String)->String:
	var led:=func(c:Variant)->bool:
		if not c is Dictionary: return false
		return (fid!="" and String((c as Dictionary).get("figure_id",""))==fid) or (fid=="" and name!="" and String((c as Dictionary).get("name",""))==name)
	var next:Dictionary={}
	for i in mc.field_armies.size():
		var army:Dictionary=mc.field_armies[i]
		if not bool(led.call(army.get("commander",{}))): continue
		var fresh:Dictionary=figures.commander(mc._acting_field_commander(false),"army_%d" % int(army.get("army_id",0)))
		if fresh.is_empty(): continue
		army["commander"]=fresh
		# A march the court ordered is led by the new war leader from now on.
		if army.get("court_order") is Dictionary:
			(army.court_order as Dictionary)["general"]=WarOrders._given(String(fresh.get("name","")))
			(army.court_order as Dictionary)["general_pid"]=0
		mc.field_armies[i]=army
		next=fresh
	for i in mc.occupation_forces.size():
		var force:Dictionary=mc.occupation_forces[i]
		var c:Variant=force.get("commander",{})
		if not bool(led.call(c)) and not (c is Dictionary and name!="" and String((c as Dictionary).get("name",""))==name): continue
		if next.is_empty(): next=figures.commander(mc._acting_field_commander(false),"garrison_%s" % String(force.get("region_id","")))
		if next.is_empty(): continue
		force["commander"]=next.duplicate(true)
		mc.occupation_forces[i]=force
	return String(next.get("name",""))

static func _hand_of_the_god(r:Dictionary,actor:Dictionary,target:Dictionary,verb:String)->void:
	## The one who carried it out carries it after: dread of the god, and for
	## the gentle, a wound that becomes resentment.
	var person:=_person(actor)
	if person.is_empty(): return
	var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
	var empathy:=clampf(float(personality.get("empathy",0.5)),0.0,1.0)
	var reluctant:=String((r.obedience as Dictionary).get("id",""))=="reluctant"
	var deltas:={"fear":0.06 if verb=="kill" else 0.03,"love":-0.07 if reluctant else -0.03,"obligation":0.03,
		"resentment":(0.05+0.06*empathy) if reluctant else 0.01*empathy,"hold_days":60 if verb=="kill" else 20}
	r["actor_after"]=GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),deltas)
	var name:=String(target.get("name","them"))
	var memory:=String({"kill":"At the god's word I killed %s with my own hands, before the whole court.","exile":"At the god's word I drove %s out of the realm.","detain":"At the god's word I bound %s and put them under guard."}.get(verb,"At the god's word I acted against %s.")) % name
	GovernmentPeopleSystem.record_person_memory(int(actor.person_id),memory,"divine",0.9 if verb=="kill" else 0.7,{"emotion":"horror" if reluctant else "duty","outcome":"carried_out_"+verb})

## What each act on a foreign envoy costs between the peoples:
## [opinion, tension, trust, their dread, grudge weight, grudge kind].
const ENVOY_ACTS:={
	"kill":[-0.5,0.45,-0.4,0.3,1.0,"slain_envoy"],
	"mutilate":[-0.42,0.38,-0.35,0.3,0.85,"maimed_envoy"],
	"beat":[-0.3,0.26,-0.25,0.18,0.6,"beaten_envoy"],
	"humiliate":[-0.26,0.2,-0.2,0.12,0.5,"insulted_envoy"],
	"detain":[-0.3,0.3,-0.25,0.18,0.7,"seized_envoy"],
	"exile":[-0.12,0.08,-0.1,0.06,0.3,"insulted_envoy"],
}
const ENVOY_STATE:={"kill":"dead","mutilate":"maimed","beat":"beaten","humiliate":"shamed","detain":"bound","exile":"driven out"}

static func envoy_act(id:String,verb:String,text:String="",harm:String="")->Dictionary:
	## The offline WRATH menu's acts on a foreign envoy (kill, maim, detain,
	## drive out), through the same engine path as the typed order.
	var audience:=Hall.find(id)
	if audience.is_empty() or String(audience.get("status",""))!="waiting" or String(audience.get("origin",""))!="foreign": return {"handled":false,"ok":false,"outcome":"No envoy is waiting."}
	var list:=roster(audience)
	var envoy:=_speaker_entry(list)
	var words:=text if text!="" else ("Flog the envoy and throw them out." if harm=="beat" else String({"kill":"Put the envoy to death.","maim":"Maim the envoy and send them home.","detain":"Seize the envoy and hold them.","exile":"Drive the envoy out of my hall."}.get(verb,"Drive the envoy out.")))
	var cls:=classify(words)
	cls.act="command"; cls.verb=verb
	if harm!="": cls.harm=harm
	elif verb=="maim" and String(cls.get("harm",""))=="": cls.harm="mutilate"
	return _perform(id,audience,list,verb,{},envoy,words,cls,false,{})

static func _envoy_harm(verb:String,cls:Dictionary)->String:
	if verb=="maim":
		var h:=String(cls.get("harm",""))
		return h if h in ["mutilate","beat","humiliate"] else "mutilate"
	return verb if ENVOY_ACTS.has(verb) else "exile"

static func _body_part(text:String)->String:
	var m:=_re("(?i)\\b"+BODY_PARTS+"\\b").search(text)
	return m.get_string(1).to_lower() if m!=null else ""

static func _punish_envoy(id:String,audience:Dictionary,r:Dictionary,verb:String,actor:Dictionary,cls:Dictionary={})->Dictionary:
	var civ_id:=String(audience.civ_id)
	var civ_name:=String(audience.get("civ_name",civ_id))
	var name:=String((audience.speaker as Dictionary).get("name","the envoy"))
	var by:=String(actor.get("name","")) if String(actor.get("kind",""))!="envoy" else ""
	if by=="": r.actor={}; r.actor_name=""
	var hand:=" by %s's hand" % by if by!="" else ""
	var harm:=_envoy_harm(verb,cls)
	var row:Array=ENVOY_ACTS[harm]
	var part:=_body_part(String(r.text)) if harm=="mutilate" else ""
	Hall._shift_relation(civ_id,float(row[0]),float(row[1])); Hall._leader_trust(civ_id,float(row[2]))
	DIVINE.record_envoy_harm(civ_id,civ_name,name,harm,float(row[3]))
	var parts:PackedStringArray=PackedStringArray()
	match harm:
		"kill":
			var died:=envoy_dies(civ_id)
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was put to death in the ruler's hall and will never come home." % name)
			parts.append("%s, envoy of %s, was killed%s at your word. They will never come home; %s counts one fewer (about %d now)." % [name,civ_name,hand,civ_name,roundi(float(died.get("after",0.0)))])
		"mutilate":
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was sent home maimed%s from the ruler's hall." % [name," (their "+part+" cut away)" if part!="" else ""])
			parts.append("%s, envoy of %s, was maimed%s at your word%s and sent home alive, crippled, to show their people what you did." % [name,civ_name,hand," (their "+part+")" if part!="" else ""])
		"beat":
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was flogged in the ruler's hall and sent home bleeding." % name)
			parts.append("%s, envoy of %s, was beaten bloody%s at your word and thrown out to walk home." % [name,civ_name,hand])
		"humiliate":
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was shamed before the ruler's court and sent home in disgrace." % name)
			parts.append("%s, envoy of %s, was shamed before the whole court%s at your word and sent home in disgrace." % [name,civ_name,hand])
		"detain":
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was seized and held captive in the ruler's hall." % name)
			parts.append("%s, envoy of %s, was bound and held%s at your word." % [name,civ_name,hand])
		_:
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was driven out of the ruler's hall." % name)
			parts.append("%s, envoy of %s, was driven out of your hall%s." % [name,civ_name,hand])
	# What they carried: kept only on the ruler's explicit word, otherwise it
	# goes home with the fleeing bearers.
	var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
	var carried:=String(audience.get("kind",""))=="gift" and not terms.is_empty() and float(terms.get("amount",0.0))>0.0
	var goods:={}
	if carried and bool(cls.get("seize",false)):
		var got:=Hall.EXCHANGE.take(civ_id,String(terms.resource),float(terms.amount))
		var kept:=Hall.EXCHANGE.receive("player",String(terms.resource),got) if got>0.0 else 0.0
		goods={"resource":String(terms.resource),"amount":kept,"seized":true}
		parts.append("You kept the %d %s they carried; they will call it theft as well." % [roundi(kept),String(terms.resource)] if kept>0.0 else "Your guards turned out their packs, but the %s never reached your stores." % String(terms.resource).to_lower())
		Hall._shift_relation(civ_id,-0.06,0.05)
	elif carried:
		goods={"resource":String(terms.resource),"amount":0.0,"seized":false}
		parts.append("The %s gift is forfeit: their bearers fled with it." % String(terms.resource))
	r.terms=goods
	var weight:=float(row[4])+(0.2 if bool(goods.get("seized",false)) else 0.0)
	var clause:=String({"kill":"how you slew our envoy %s in your hall","mutilate":"how you sent our envoy %s home maimed","beat":"how you had our envoy %s flogged","humiliate":"how you shamed our envoy %s before your court","detain":"how you seized our envoy %s","exile":"how you drove our envoy %s from your hall"}[harm]) % name.get_slice(" ",0)
	var rivals:=Hall._rivals()
	var posture:=""
	if rivals!=null:
		rivals.call("grudge",civ_id,clause,weight,"%s:%s" % [String(row[5]),id])
		if bool(goods.get("seized",false)): rivals.call("grudge",civ_id,"the gift you tore from our bearers",0.3,"seized_gift:"+id)
		posture=String(rivals.call("envoy_posture",civ_id))
	parts.append(String({"redress":"%s will demand redress, and the border is on edge.","halt":"%s may send no more envoys.","fearful":"%s is frightened; hatred and dread of you both rise.","war":"%s is preparing for war."}.get(posture,"Their people will hear of it: hatred and dread of you both rise, and the border grows dangerous.")).replace("%s",civ_name))
	r.outcome=" ".join(parts)
	r.envoy_state=String(ENVOY_STATE.get(harm,"gone")); r.harm=harm; r.part=part
	audience["envoy_fate"]={"state":String(r.envoy_state),"harm":harm,"part":part}
	r.executed=true; r.removed=true; r.terminal=true; r.reaction="furious"
	r.stage=verb
	r.witness_ids=_witness_ids(id,[])
	r.effects=_apply_court(id,"strike_down" if harm in ["kill","mutilate"] else "cast_out",{"person_id":0,"name":name},[])
	Hall.conclude(id,String(r.outcome),"envoy_"+("maim" if verb=="maim" else verb))
	Hall._add_sequel(audience,"envoy_"+harm,Hall._day())
	return r

static func envoy_dies(civ_id:String)->Dictionary:
	## A foreign envoy killed at our court: their people count one fewer (the
	## simulated polity's own ledger when it has one); ours is untouched.
	var index:=Hall._civ_index(civ_id)
	if index<0: return {}
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	var before:=float(civ.get("population",1.0))
	var owner:=Hall.SOCIETY.owner_id(civ_id)
	if owner!="player" and Hall.SOCIETY.owner_state(civ_id)!=null and WorldSimulation.actors.has(owner):
		WorldSimulation.scoped(owner,func()->void:
			if WorldSimulation.state.has_method("register_population_deaths"): WorldSimulation.state.call("register_population_deaths",1,"envoy slain at a foreign court"))
	var after:=maxf(1.0,before-1.0)
	civ["population"]=after
	if civ.get("cohorts") is Dictionary and before>0.0:
		var cohorts:Dictionary=civ.cohorts
		for key in cohorts.keys(): cohorts[key]=float(cohorts[key])*after/before
	WorldSimulation.world.civilizations[index]=civ
	return {"before":before,"after":after}

static func _maim_person(id:String,audience:Dictionary,r:Dictionary,actor:Dictionary,target:Dictionary,cls:Dictionary)->Dictionary:
	## One of our own maimed or flogged before the court: they live, keep their
	## place, and carry terror and a wound that becomes resentment.
	if String(target.get("kind",""))=="figure": return _maim_figure(id,r,actor,target,cls)
	if String(target.get("kind",""))!="official": return _fallback(id,r,"")
	var pid:=int(target.person_id)
	var harm:=String(cls.get("harm","mutilate"))
	var person:=_person(target)
	var name:=String(target.get("name","them"))
	var by:=String(actor.get("name",""))
	GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":0.3 if harm=="mutilate" else 0.2,"resentment":0.2 if harm=="mutilate" else 0.12,"love":-0.12,"respect":-0.05,"hold_days":90})
	GovernmentPeopleSystem.record_person_memory(pid,"The god had me %s before the whole court." % String({"mutilate":"maimed","beat":"flogged","humiliate":"shamed"}.get(harm,"maimed")),"divine",0.9,{"emotion":"terror","outcome":"maimed"})
	r.effects=_apply_court(id,"terrify",person,[pid])
	r.outcome="%s was %s%s at your word, before the court. They live, and they will not forget it." % [name,String({"mutilate":"maimed","beat":"flogged bloody","humiliate":"shamed"}.get(harm,"maimed")),(" by %s's hand" % by) if by!="" else ""]
	r.executed=true; r.reaction="furious"; r.stage="maim"; r.harm=harm; r.part=_body_part(String(r.text))
	r.witness_ids=_witness_ids(id,[pid])
	if not actor.is_empty() and int(actor.get("person_id",0))>0: _hand_of_the_god(r,actor,target,"maim")
	return r

static func _maim_figure(id:String,r:Dictionary,actor:Dictionary,target:Dictionary,cls:Dictionary)->Dictionary:
	## A figure of renown maimed or flogged at the god's word (brought in from
	## where they are when not before the god): they live and keep what they
	## lead, and the realm remembers it.
	var fid:=String(target.get("figure_id",""))
	var figure:Dictionary=HistoricalFigures.by_id(fid)
	if figure.is_empty(): return _fallback(id,r,"")
	var harm:=String(cls.get("harm","mutilate"))
	var name:=String(target.get("name","them"))
	var here:=bool(target.get("speaker",false)) or bool(target.get("present",false))
	var at:=figure_at(fid,name)
	var where:=String(target.get("where",at.words))
	var from:=String(target.get("from",at.from))
	var day:=Hall._day()
	var done:=String({"mutilate":"maimed","beat":"flogged bloody","humiliate":"shamed"}.get(harm,"maimed"))
	HistoricalFigures.note(fid,day,"%s before the court at the ruler's word." % _cap_first(done))
	figure["renown"]=maxi(0,int(figure.get("renown",0))-1)
	var metrics:Dictionary=GameState.simulation_metrics
	metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-0.01,0.01,0.99)
	r.effects=_apply_court(id,"terrify",{"person_id":0,"name":name},[])
	var by:=String(actor.get("name",""))
	var fetched:=("%s was brought in under guard from %s and " % [name,from]) if not here and from!="" else ("%s was brought before you and " % name if not here else "%s was " % name)
	r.outcome=fetched+"%s%s at your word, before the court. They live, and they will not forget it." % [done,(" by %s's hand" % by) if by!="" else ""]
	r.executed=true; r.reaction="furious"; r.stage="maim"; r.harm=harm; r.part=_body_part(String(r.text))
	r["where"]=where
	r.witness_ids=_witness_ids(id,[])
	if not actor.is_empty() and int(actor.get("person_id",0))>0: _hand_of_the_god(r,actor,target,"maim")
	return r

static func _cap_first(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)

static func _figure_act(id:String,r:Dictionary,verb:String,target:Dictionary)->Dictionary:
	## Favour, penance or terror for a figure of renown (a war leader of our
	## bands, the realm's great makers): the realm hears it, their renown
	## moves, and the court sees it. Relieved of command: the next war leader
	## takes their band and garrison.
	var fid:=String(target.get("figure_id",""))
	var figure:Dictionary=HistoricalFigures.by_id(fid)
	if figure.is_empty(): return _fallback(id,r,"")
	var name:=String(target.get("name",figure.get("name","them")))
	var here:=bool(target.get("speaker",false)) or bool(target.get("present",false))
	var at:=figure_at(fid,name)
	var away:=(" Word of it goes to them at %s." % String(at.from)) if not here and String(at.from)!="" else ""
	var day:=Hall._day()
	match verb:
		"bless","raise","boon":
			HistoricalFigures.note(fid,day,"Honoured by the ruler before the court.",1)
			r.effects=_apply_court(id,"bless",{"person_id":0,"name":name},[])
			r.outcome="%s is honoured at your word before the court; their renown grows.%s" % [name,away]
			r.reaction="delighted"
		"penance","terrify":
			HistoricalFigures.note(fid,day,"Made to do penance by the ruler's word." if verb=="penance" else "Terrified by the ruler's anger.")
			r.effects=_apply_court(id,"terrify",{"person_id":0,"name":name},[])
			r.outcome=("%s is made to do penance at your word.%s" if verb=="penance" else "Your anger falls on %s; the court shrinks from it.%s") % [name,away]
			r.reaction="furious"
		"demote":
			var next:=_succeed(fid,name)
			figure["supported"]=false
			HistoricalFigures.note(fid,day,"Relieved of command by the ruler's word.")
			r.effects=_apply_court(id,"cast_out",{"person_id":0,"name":name},[])
			r.outcome=("%s is relieved of command at your word. %s takes over %s's command." % [name,next,WarOrders._given(name)]) if next!="" else "%s holds no command to lose; your displeasure is heard." % name
			r.reaction="offended"
		_:
			return _fallback(id,r,"")
	r.executed=true; r.stage=verb if STAGE.has(verb) else "none"
	r.witness_ids=_witness_ids(id,[])
	return r

static func _spoken_act(id:String,audience:Dictionary,r:Dictionary,verb:String,target:Dictionary)->Dictionary:
	if String(target.get("kind",""))=="figure": return _figure_act(id,r,verb,target)
	var action:=String({"raise":"raise_up"}.get(verb,verb))
	if String(target.get("kind",""))=="envoy":
		if action=="terrify":
			var done:=Hall.divine(id,"terrify",String(r.text))
			r.merge(done,true); r.handled=true; r.executed=bool(done.get("ok",false)); r.stage="terrify"
			return r
		action="bless"
	if String(target.get("kind",""))!="official": return _fallback(id,r,"")
	var done2:=Hall.divine(id,action,String(r.text),int(target.person_id),{"quiet":true})
	if not bool(done2.get("ok",false)):
		# Already done here, or the stores cannot pay: say so plainly.
		r.outcome=String(done2.get("outcome",""))
		if r.outcome=="": r.outcome="It is already done."
		r.stage="none"
		return r
	r.effects=done2.get("effects",{}); r.outcome=String(done2.outcome); r.response=String(done2.get("response",""))
	r.reaction=String(done2.get("reaction","neutral")); r.executed=true; r.stage=verb
	if done2.has("terms"): r.terms=done2.terms
	r.witness_ids=_witness_ids(id,[int(target.person_id)])
	return r

static func _demote(id:String,audience:Dictionary,r:Dictionary,target:Dictionary)->Dictionary:
	if String(target.get("kind",""))=="figure": return _figure_act(id,r,"demote",target)
	if String(target.get("kind",""))!="official": return _fallback(id,r,"")
	var removed:Dictionary
	if String(target.office_key)=="settlement": removed=GovernmentPeopleSystem.remove_settlement_leader(String(target.settlement_id),"dismiss")
	else: removed=GovernmentPeopleSystem.remove_central_officeholder(String(target.office_key),"dismiss")
	if not bool(removed.get("ok",false)): return _fallback(id,r,String(removed.get("reason","")))
	var pid:=int(target.person_id)
	GovernmentPeopleSystem.adjust_person_bonds(pid,{"resentment":0.12,"fear":0.05,"respect":-0.06})
	GovernmentPeopleSystem.record_person_memory(pid,"The god stripped me of my office before the whole court.","divine",0.8,{"emotion":"shame","outcome":"demoted"})
	var heir:=String((removed.get("successor",{}) as Dictionary).get("name",""))
	r.outcome="%s was stripped of office at your word.%s" % [String(target.name)," %s holds it now." % heir if heir!="" else ""]
	r.executed=true; r.reaction="offended"; r.witness_ids=_witness_ids(id,[pid])
	if bool(target.get("speaker",false)):
		r.terminal=true
		Hall.conclude(id,String(r.outcome),"demote")
	return r

static func _office_in(text:String)->String:
	var lower:=text.to_lower()
	for office:Dictionary in GovernmentPeopleSystem.active_offices():
		var title:=String(GovernmentPeopleSystem.office_definition(String(office.key)).get("title","")).to_lower()
		if title!="" and _re("\\b%s\\b" % _escape(title)).search(lower)!=null: return String(office.key)
	var keys:=OFFICE_WORDS.keys()
	keys.sort_custom(func(a:Variant,b:Variant)->bool:return String(a).length()>String(b).length())
	for word in keys:
		if _re("\\b%s\\b" % _escape(String(word))).search(lower)!=null: return String(OFFICE_WORDS[word])
	return ""

static func _appoint(id:String,audience:Dictionary,r:Dictionary,target:Dictionary,text:String)->Dictionary:
	# A figure of renown holds no office of the council: the honour is theirs.
	if String(target.get("kind",""))=="figure": return _figure_act(id,r,"raise",target)
	if String(target.get("kind",""))!="official": return _fallback(id,r,"")
	var office:=_office_in(text)
	var pid:=int(target.person_id)
	if office=="" or not GovernmentPeopleSystem.office_is_active(office) or String(target.office_key)==office:
		return _spoken_act(id,audience,r,"raise",target)
	var former:Dictionary=GovernmentPeopleSystem.officeholder(office)
	var appointed:=GovernmentPeopleSystem.mark_central_appointment(pid,office)
	if appointed.is_empty(): return _spoken_act(id,audience,r,"raise",target)
	GovernmentPeopleSystem.adjust_person_bonds(pid,{"respect":0.08,"love":0.05,"obligation":0.06})
	GovernmentPeopleSystem.record_person_memory(pid,"The god made me %s before the whole court." % String(appointed.get("office_title",office)),"divine",0.8,{"emotion":"awe","outcome":"appointed"})
	if not former.is_empty() and int(former.person_id)!=pid:
		GovernmentPeopleSystem.adjust_person_bonds(int(former.person_id),{"resentment":0.1,"respect":-0.04})
		GovernmentPeopleSystem.record_person_memory(int(former.person_id),"The god gave my office to %s before the court." % String(target.name),"divine",0.7,{"emotion":"shame","outcome":"replaced"})
	r.outcome="%s is now %s by your word.%s" % [String(target.name),String(appointed.get("office_title",office))," %s no longer holds it." % String(former.name) if not former.is_empty() and int(former.person_id)!=pid else ""]
	r.executed=true; r.reaction="delighted"; r.stage="appoint"; r.witness_ids=_witness_ids(id,[pid])
	return r

static func _give(id:String,audience:Dictionary,r:Dictionary,target:Dictionary,cls:Dictionary)->Dictionary:
	var resource:=String(cls.resource) if String(cls.resource)!="" else "Food"
	var want:=float(cls.amount)
	if want<=0.0: want=float(Hall._boon_terms().amount)
	want=clampf(want,1.0,5000.0)
	var stock:=Hall.player_stock(resource)
	var paid:=0.0
	if stock>=1.0: paid=Hall._debit_player(resource,minf(want,floorf(stock)))
	r.terms={"resource":resource,"amount":paid}
	var who:=String(target.get("name","them"))
	if paid<=0.0:
		r.outcome="Your stores hold no %s to give %s." % [resource,who]
		r.stage="none"; r.executed=false
		return r
	var short:=" (all the stores held)" if paid+0.001<want else ""
	match String(target.get("kind","")):
		"envoy":
			var civ_id:=String(audience.civ_id)
			Hall._credit_civ(civ_id,resource,paid)
			Hall._shift_relation(civ_id,clampf(paid/400.0,0.01,0.12),-clampf(paid/800.0,0.0,0.06))
			ForeignDiplomacy.remember(civ_id,"The ruler gave our envoy %d %s to carry home." % [roundi(paid),resource])
			r.outcome="You gave %d %s to %s to carry home to %s%s." % [roundi(paid),resource,who,String(audience.get("civ_name","their people")),short]
			r.reaction="pleased"
		"official":
			var pid:=int(target.person_id)
			r.effects=_apply_court(id,"boon",_person(target),[pid])
			r.outcome="You gave %s %d %s from the stores%s." % [who,roundi(paid),resource,short]
			r.reaction="delighted"; r.witness_ids=_witness_ids(id,[pid])
		"figure":
			var at:=figure_at(String(target.get("figure_id","")),who)
			var sent:=(" It is carried out to them at %s." % String(at.from)) if not bool(target.get("present",false)) and String(at.from)!="" else ""
			r.outcome="You gave %s %d %s from the stores%s.%s" % [who,roundi(paid),resource,short,sent]
			r.reaction="delighted"; r.witness_ids=_witness_ids(id,[])
		_:
			r.outcome="%d %s left the stores at your word%s." % [roundi(paid),resource,short]
	r.executed=true; r.stage="give"
	return r

static func _take(id:String,audience:Dictionary,r:Dictionary,target:Dictionary,cls:Dictionary)->Dictionary:
	var resource:=String(cls.resource) if String(cls.resource)!="" else "Food"
	var want:=clampf(float(cls.amount) if float(cls.amount)>0.0 else 20.0,1.0,2000.0)
	if String(audience.get("origin",""))=="foreign" and (String(target.get("kind",""))=="envoy" or target.is_empty()):
		var civ_id:=String(audience.civ_id)
		var theirs:=Hall.foreign_stock(civ_id,resource)
		var got:=0.0
		if theirs>0.0:
			got=Hall.EXCHANGE.take(civ_id,resource,minf(want,theirs))
			if got>0.0: Hall.EXCHANGE.receive("player",resource,got)
		Hall._shift_relation(civ_id,-0.15,0.12); Hall._leader_trust(civ_id,-0.12)
		DIVINE.add_civ_dread(civ_id,0.08)
		ForeignDiplomacy.remember(civ_id,"The ruler seized %s from our people through our envoy." % resource.to_lower())
		r.terms={"resource":resource,"amount":got}
		r.outcome=("Your guards took %d %s from the stores of %s. Their people will call it theft." % [roundi(got),resource,String(audience.get("civ_name",""))]) if got>0.0 else "Your guards turned out the envoy's packs; %s had no %s to seize, and will remember the insult." % [String(audience.get("civ_name","their people")),resource.to_lower()]
		r.executed=true; r.stage="take"; r.reaction="furious"
		return r
	# Officials keep nothing apart from the common stores: a fine becomes penance.
	if String(target.get("kind",""))=="figure": return _figure_act(id,r,"penance",target)
	if String(target.get("kind",""))=="official":
		var done:=_spoken_act(id,audience,r,"penance",target)
		if bool(done.executed): done.outcome="%s holds nothing apart from the common stores; the fine becomes penance. %s" % [String(target.name),String(done.outcome)]
		return done
	return _fallback(id,r,"")

static func _send(id:String,audience:Dictionary,r:Dictionary,actor:Dictionary,cls:Dictionary,context:Dictionary,text:String)->Dictionary:
	var lower:=text.to_lower()
	var civ:Dictionary={}
	for c:Dictionary in WorldSimulation.world.civilizations:
		var cname:=String(c.get("name","")).to_lower()
		if cname!="" and cname in lower: civ=c; break
	if String(actor.get("kind",""))=="envoy" and _re(ENVOY_LEADS_PATTERN).search(text)==null: actor={}; r.actor={}; r.actor_name=""
	var who:=String(actor.get("name",""))
	if not civ.is_empty() and (_re("(?i)\\b(envoy|envoys|messenger|embassy|word)\\b").search(text)!=null or not "scout" in lower):
		var sent:=dispatch_envoy(civ,text,String(cls.get("resource","")))
		if not bool(sent.get("ok",false)):
			# Nobody set out: the plain reason, never a standing order.
			r.executed=false; r.stage="none"; r.reaction="neutral"
			r["actor_says"]=String(sent.says)
			r.outcome="Nothing is set in motion: %s" % String(sent.why)
			return r
		r["actor_says"]=String(sent.says)
		r.outcome=String(sent.outcome)
	else:
		var heading:=String(cls.heading)
		# The god may overrule the Chief Scout's caution. The party goes, and
		# the odds it carries say plainly what that costs.
		var reckless:=_re("(?i)\\b(regardless|whatever the (cost|danger|risk)|no matter (what|the cost|the danger)|at any cost|at all costs|do not turn back|don't turn back|never turn back)\\b").search(text)!=null
		var far:=_re("(?i)\\b(far|farther|further|distant|beyond the|to the ends|as far as|long journey|a year)\\b").search(text)!=null
		var sent2:Dictionary={}
		for days:int in ([365,180,90,30] if far else [30]):
			sent2=CivilizationSystem.dispatch_scouts(days,"open_world",heading,0,false,"",reckless)
			if not sent2.has("error"): break
		if sent2.has("error"): return _order(id,audience,r,actor,text,context,String(sent2.error))
		# The party as it really left: how many, which way, how long (the mission record).
		var party:Dictionary=CivilizationSystem.scout_missions[-1] if not CivilizationSystem.scout_missions.is_empty() else {}
		var scouts:=int(party.get("personnel",0))
		var away:=maxi(1,int(party.get("actual_return_day",party.get("return_day",0)))-int(GameState.elapsed_days))
		r.outcome="A scouting party%s sets out%s at your word%s; they should be back in about %d days." % [(" of %d" % scouts) if scouts>0 else ""," to the "+heading if heading!="" else ""," under "+who if who!="" else "",away]
		if reckless:
			r.outcome+=" You have told them not to turn back; the Chief Scout judges that %s." % ScoutSurvival.odds_phrase({"death_chance":float(party.get("field_death_chance",0.0))})
	if int(actor.get("person_id",0))>0:
		GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"obligation":0.02,"respect":0.01})
		GovernmentPeopleSystem.record_person_memory(int(actor.person_id),"The god sent me out: %s" % text.substr(0,160),"divine",0.6,{"emotion":"duty","outcome":"sent"})
	r.executed=true; r.stage="send"; r.reaction="pleased"
	return r

static func _order(id:String,audience:Dictionary,r:Dictionary,actor:Dictionary,text:String,context:Dictionary,blocker:String="")->Dictionary:
	## Any other order: the actor takes it up and it goes to the council.
	## Words that only assent or urge are an answer, never an order of their
	## own; an order a real system carries out at home goes to that system.
	if actor.is_empty() and String(r.get("verb",""))=="home":
		actor=_speaker_entry(roster(audience))
		r.actor=actor.duplicate(); r.actor_name=String(actor.get("name",""))
	var ctx:=context.duplicate()
	ctx["audience_id"]=id
	ctx["actor"]=actor.duplicate()
	if String(actor.get("office_key",""))=="settlement": ctx["settlement_id"]=String(actor.get("settlement_id",""))
	elif not _person(actor).is_empty() and String(_person(actor).get("local_leader_of",""))!="": ctx["settlement_id"]=String(_person(actor).local_leader_of)
	var words:=_strip_vocative(text,actor)
	if blocker=="" and bare_assent(words): return _assent(id,audience,r,actor,words)
	var home:=HomeOrders.read(words) if blocker=="" and String(ctx.get("settlement_id",""))=="" else {}
	if not home.is_empty(): return _home(id,r,actor,words,home)
	var routed:=custom_order(words,ctx)
	if int(actor.get("person_id",0))>0:
		GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"obligation":0.02,"fear":0.01})
		GovernmentPeopleSystem.record_person_memory(int(actor.person_id),"The god gave me an order before the court: %s" % words.substr(0,160),"divine",0.55,{"emotion":"duty","outcome":"ordered"})
	var who:=String(actor.get("name",""))
	r.outcome=("%s%s " % [blocker+" " if blocker!="" else "","%s takes up your order." % who if who!="" else "Your order is taken up."])+String(routed.get("outcome",""))
	r.route=String(routed.get("route",""))
	r.executed=true; r.stage="order"; r.reaction="neutral"
	if not bool(routed.get("ok",true)):
		# Nothing was set in motion: the plain truth, never "it will be done".
		r.outcome=(blocker+" " if blocker!="" else "")+String(routed.get("outcome",""))
		r.executed=false
	r.verb="order"
	return r

## Words that only assent or urge, with no order of their own: "SEND THEM!",
## "go ahead", "Do it!", "Take them as they are", "yes, now".
const ASSENT_PHRASES:=["go","go on","go ahead","proceed","carry on","carry it out","get on with it","do it","do so","do that","do as i said","do as i say",
	"send them","send it","send them all","send the men","send the band","send the host","send the warriors","send the fighters","send everyone",
	"march","march on","take them","take them anyway","take them as they are","as they are","go as they are","let them go as they are",
	"you heard me","what are you waiting for","i said do it","i said go","make it so","so be it","very well","ok","okay","get going","be off","off you go"]
const ASSENT_FILLER:=["yes","yea","aye","then","now","at","once","already","please","just","right","immediately","so","well","and","quickly","today"]
## A war leader's march that the god's "yes" or "do it" may name again: the
## engine says where it stands ("already on the road") and never marches twice.
const MARCH_KINDS:=["attack","siege","raid","storm","intercept","recall","defend","drill"]

static func bare_assent(text:String)->bool:
	var words:=Array(_re("[^a-z' ]").sub(text.to_lower()," ",true).split(" ",false))
	while not words.is_empty() and String(words[0]) in ASSENT_FILLER: words.pop_front()
	while not words.is_empty() and String(words[words.size()-1]) in ASSENT_FILLER: words.pop_back()
	if words.is_empty(): return text.strip_edges()!=""
	return " ".join(PackedStringArray(words)) in ASSENT_PHRASES

static func _assent(id:String,audience:Dictionary,r:Dictionary,actor:Dictionary,words:String)->Dictionary:
	## A bare "yes" or "send them" that reached the order path: no question was
	## open for it (hear() answers those first). The last march ordered here is
	## named again, so the war leader says where it stands; otherwise nothing is
	## set in motion and the court says so. Never a new standing order.
	var list:=roster(audience)
	var civ:=String(audience.get("civ_id",""))
	var lines:Array=audience.get("lines",[])
	for i in range(lines.size()-1,-1,-1):
		var line:Dictionary=lines[i]
		if String(line.get("role",""))!="ruler": continue
		var said:=String(line.get("text","")).strip_edges()
		if said==words.strip_edges() or said==String(r.get("text","")).strip_edges() or bare_assent(said): continue
		var again:=WarOrders.read(said,civ,id)
		if String(again.get("kind","")) in MARCH_KINDS: return _war(id,audience,list,r,actor,said,{"war":again},false)
		break
	r.verb="order"; r.executed=false; r.stage="none"; r.reaction="neutral"
	var ask:="Send whom, and where?" if "send" in words.to_lower() else ("March where, and against whom?" if _re("(?i)\\b(march|go)\\b").search(words)!=null else "What would you have done?")
	r["actor_says"]="%s No order is waiting on your word, so nothing goes until you say what is to be done." % ask
	r.outcome="Nothing is set in motion: no order was waiting for your word."
	return r

static func _home(id:String,r:Dictionary,actor:Dictionary,words:String,home:Dictionary)->Dictionary:
	## An order at home a real system carries out (home_orders.gd): done, or
	## the plain reason it cannot be.
	var done:=HomeOrders.perform(home)
	r.verb="order"; r["route"]="home"; r["home"]=done.duplicate()
	r["actor_says"]=String(done.get("says",""))
	r.outcome=String(done.get("outcome",""))
	r.executed=bool(done.get("ok",false)) and int(done.get("count",0))>0
	r.stage="order" if r.executed else "none"
	r.reaction="neutral"
	if int(actor.get("person_id",0))>0:
		GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"obligation":0.02,"fear":0.01})
		GovernmentPeopleSystem.record_person_memory(int(actor.person_id),"The god gave me an order before the court: %s" % words.substr(0,160),"divine",0.55,{"emotion":"duty","outcome":"ordered"})
	return r

## An envoy to a people, carrying what the words ask: a truce (at war) or a
## promise of peace, trade, a gift with good words; plain words ("send an
## envoy to the Esurai") ask for an audience with their ruler, which war does
## not forbid. Real missions only (civilization_system, foreign_diplomacy):
## {ok, purpose, says, outcome, why}.
static func dispatch_envoy(civ:Dictionary,text:String,gift:String="")->Dictionary:
	var civ_id:=String(civ.get("id",""))
	var name:=String(civ.get("name","their people"))
	var lower:=text.to_lower()
	var rel:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	var at_war:=bool(rel.get("at_war",false))
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	if not mission.is_empty():
		var away:=String(mission.get("civilization","another people"))
		return {"ok":false,"purpose":"","why":"our envoys are already away, to the %s, and nobody else can go until they return." % away,
			"says":"Our envoys are already on the road to the %s. Nobody else can go until they come back." % away}
	var purpose:=""
	if _re("(?i)\\b(peace|truce|end (the|this) war|stop the fighting|terms)\\b").search(lower)!=null: purpose="seek_peace" if at_war else "non_aggression"
	elif not at_war and _re("(?i)\\b(trade|barter)\\b").search(lower)!=null: purpose="open_trade"
	elif not at_war and gift!="": purpose="goodwill"
	var result:Dictionary={}
	var instead:=""
	if purpose!="":
		result=WorldSimulation.world.dispatch_diplomat(civ_id,gift if purpose=="goodwill" else "",purpose)
		if result.has("error") and purpose in ["seek_peace","non_aggression","open_trade"]:
			# They would turn that proposal away now (the world's own rule): the
			# envoys go to speak with their ruler instead, and the court says why.
			instead=_envoy_reason(String(result.error),name)+" "
			result={}
	if purpose=="" or not instead.is_empty():
		purpose="audience"
		result=WorldSimulation.diplomacy.send_audience(civ_id)
	if result.has("error"):
		var why:=_envoy_reason(String(result.error),name)
		return {"ok":false,"purpose":purpose,"why":(instead+why).strip_edges(),"says":"No envoy can go to the %s now. %s" % [name,(instead+why).strip_edges()]}
	var what:=String({"audience":"to speak with their ruler and bring back the answer","seek_peace":"to ask for a truce","non_aggression":"to ask that neither people raid the other",
		"open_trade":"to propose trade","goodwill":"with a gift and good words"}.get(purpose,""))
	var days:=maxi(1,int(WorldSimulation.world.diplomatic_mission.get("arrival_day",0))-int(WorldSimulation.state.elapsed_days))
	return {"ok":true,"purpose":purpose,"why":"","says":"%sEnvoys go to the %s at your word%s, %s. They will be about %d days on the road there." % [instead,name," instead" if instead!="" else "",what,days],
		"outcome":"%sEnvoys set out for the %s %s: about %d days there, and as long back with the answer." % [instead,name,what,days]}

## A diplomatic refusal in the court's own words (the world's messages carry
## labels meant for a ledger: "Esurai refuses peace: WILL REFUSE. ...").
static func _envoy_reason(error:String,name:String)->String:
	if "refuses peace" in error.to_lower(): return "The %s will not hear of a truce now; they would only turn the envoys back until the war goes worse for them." % name
	var plain:=_re("\\b[A-Z]{2,}( [A-Z]{2,})*\\b").sub(error,"",true)
	plain=_re("\\s+").sub(plain.replace(": .",".").replace(":.","."), " ",true).strip_edges()
	return plain

static func _war(id:String,audience:Dictionary,list:Array[Dictionary],r:Dictionary,actor:Dictionary,text:String,cls:Dictionary,insist:bool)->Dictionary:
	## A war order: the war leader weighs it against what is really there and
	## either sets a real objective in motion or says plainly why not
	## (court_war_orders.gd). Never "we will" followed by nothing.
	var reading:Dictionary=cls.get("war",{}) if cls.get("war") is Dictionary else {}
	if reading.is_empty(): reading=WarOrders.read(text,String(audience.get("civ_id","")),id)
	# The war leader carries it, whoever it was spoken to; a summoned war
	# leader of renown answers for himself and his own band.
	var speaker:=_speaker_entry(list)
	var general:=WarOrders.war_leader({"figure_id":String(speaker.get("figure_id",""))} if String(speaker.get("kind",""))=="figure" else {})
	var general_key:=("person:%d" % int(general.get("person_id",0))) if int(general.get("person_id",0))>0 else ("figure:"+String(general.get("figure_id","")) if String(general.get("figure_id",""))!="" else "")
	var carrier:=_entry(list,general_key) if general_key!="" else {}
	if carrier.is_empty(): carrier=actor if not actor.is_empty() else _speaker_entry(list)
	r.actor=carrier.duplicate(); r.actor_name=String(carrier.get("name",""))
	r.verb="war"
	var decision:=WarOrders.perform(reading,insist,{"general":general,"army_id":int(reading.get("army_id",0)),"audience_id":id})
	r["war"]=decision
	r["objective"]=(decision.get("objective",{}) as Dictionary).duplicate(true)
	r["actor_says"]=String(decision.get("says",""))
	var verdict:=String(decision.get("verdict","impossible"))
	# Spoken to someone else (the steward, the court at large): it goes to the war leader.
	var passed:=not general.is_empty() and String(carrier.get("key",""))!=general_key
	var relay:="Word goes to %s. " % String(general.get("name","the war leader")) if passed else ""
	if passed and String(r.actor_says)!="": r.actor_says="%s sends back word: \"%s\"" % [WarOrders._given(String(general.get("name",""))),String(r.actor_says)]
	match verdict:
		"act":
			r.stage="war_march"; r.executed=true; r.reaction="grave"
			r.obedience={"id":"obey","manner":"ready","chance":0.0}
			r.outcome=relay+String(decision.outcome)
			audience.erase("pending_command")
		"object":
			r.stage="war_object"; r.executed=false; r.reaction="troubled"
			r.obedience={"id":"object","manner":"grim","chance":0.0}
			r.outcome=relay+String(decision.outcome)
			audience["pending_command"]={"verb":"war","actor":String(carrier.get("key","")),"target":"","day":Hall._day(),"text":String(reading.get("text",text)).substr(0,200)}
		"fate":
			# What becomes of a town we hold (town_fate.gd): carried out.
			r.stage="war_fate"; r.executed=true; r.reaction="grave"
			r.obedience={"id":"obey","manner":"grim","chance":0.0}
			r.outcome=relay+String(decision.outcome)
			audience.erase("pending_command")
		"ask":
			# Which town? Nothing is done until the god names it; the next
			# words that name a town we hold carry this order there.
			r.stage="war_ask"; r.executed=false; r.reaction="neutral"
			r.obedience={"id":"object","manner":"plain","chance":0.0}
			r.outcome=relay+String(decision.outcome)
			audience["pending_command"]={"verb":"war","which_town":true,"actor":String(carrier.get("key","")),"target":"","day":Hall._day(),"text":String(reading.get("text",text)).substr(0,200),"fate":(reading.get("fate",{}) as Dictionary).duplicate()}
		"ask_march":
			# The town is still theirs: the war leader asks to march on it
			# first. The march is the pending order; "yes" / "do it" sends it.
			r.stage="war_ask"; r.executed=false; r.reaction="grave"
			r.obedience={"id":"object","manner":"plain","chance":0.0}
			r.outcome=relay+String(decision.outcome)
			audience["pending_command"]={"verb":"war","confirm":true,"actor":String(carrier.get("key","")),"target":"","day":Hall._day(),"text":String(decision.get("march_text","")).substr(0,200)}
		"held":
			# An attack on a town we already hold: the plain truth, no march.
			r.stage="war_held"; r.executed=false; r.reaction="neutral"
			r.obedience={"id":"object","manner":"plain","chance":0.0}
			r.outcome=relay+String(decision.outcome)
			audience.erase("pending_command")
		"noted":
			# The god let the war leader's question drop: nothing more is done.
			r.stage="war_fate"; r.executed=false; r.reaction="neutral"
			r.obedience={"id":"obey","manner":"plain","chance":0.0}
			r.outcome=relay+String(decision.outcome)
			audience.erase("pending_command")
		_:
			r.stage="war_refuse"; r.executed=false; r.reaction="troubled"
			r.obedience={"id":"object","manner":"plain","chance":0.0}
			r.outcome=relay+String(decision.outcome)
	# What the staging shows: the captives of a fight are not a garrison's
	# business, and a march already on the road has nothing in its way.
	if String(decision.get("kind",""))=="captives" and verdict=="fate": r.stage="war_captives"
	elif String(decision.get("reason",""))=="already_marching": r.stage="war_already"
	# The war leader asked something back (a chase, leaving a town): the answer carries it.
	if decision.get("pending") is Dictionary:
		audience["pending_command"]=(decision.pending as Dictionary).merged({"verb":"war","actor":String(carrier.get("key","")),"target":"","day":Hall._day()},true)
	var pid:=int(carrier.get("person_id",0))
	if pid>0:
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"obligation":0.02,"respect":0.01})
		GovernmentPeopleSystem.record_person_memory(pid,"The god ordered war: %s. %s" % [text.substr(0,120),"We marched." if verdict=="act" else "I told the god why not."],"divine",0.6,{"emotion":"duty","outcome":verdict})
	return r

static func _strip_vocative(text:String,actor:Dictionary)->String:
	var clean:=text.strip_edges()
	if actor.is_empty() or not actor.has("name"): return clean
	for k:String in _name_keys(actor)+_title_keys(actor):
		var re:=_re("(?i)^(the )?%s\\s*[,:\\-—]?\\s*" % _escape(k))
		var m:=re.search(clean)
		if m!=null and m.get_end()<clean.length(): return clean.substr(m.get_end()).strip_edges()
	return clean

static func custom_order(text:String,context:Dictionary)->Dictionary:
	## Orders the court has no dedicated act for. A settlement leader's order,
	## or one the civic catalog recognises, goes through the civic pipeline
	## (which answers in the leader's voice and falls back to the custom
	## directive itself); anything else is applied at once through the
	## universal custom-directive path (custom_directive.gd): bounded changes
	## on DecreeStatistics parameters, real costs, side effects. Never refused.
	## custom_directive_handler, when set, is asked first.
	# Never let a war order fall into the generic directive path (a law for our
	# own people is never one: court_realm_acts.law read it so).
	var law:=bool(context.get("law",false))
	var war:=WarOrders.read(text,"") if not law else {}
	# "We hold no town of theirs" answers harm to a foe's people; words about
	# our own people ("kill all the rebels") go on to the council's path.
	if not war.is_empty() and not (String(war.get("kind",""))=="no_town" and not _any_war()):
		var decided:=WarOrders.perform(war,false)
		# No voice speaks here: the war leader's words and the note together.
		return {"ok":true,"route":"war","war":decided,"objective":decided.get("objective",{}),"outcome":(String(decided.get("says",""))+" "+String(decided.get("outcome",""))).strip_edges()}
	# Recruits called up, weapons made: the real systems, never a directive.
	var home:=HomeOrders.read(text) if not law else {}
	if not home.is_empty():
		var done:=HomeOrders.perform(home)
		return {"ok":bool(done.get("ok",false)),"route":"home","home":done,"outcome":(String(done.get("says",""))+" "+String(done.get("outcome",""))).strip_edges()}
	# A bare "yes" or "send them" is no order to set standing.
	if bare_assent(text): return {"ok":false,"route":"recorded","outcome":"Nothing is set in motion: no order was waiting for your word."}
	if custom_directive_handler.is_valid():
		var handled:Variant=custom_directive_handler.call(text,context)
		if handled is Dictionary and bool((handled as Dictionary).get("ok",false)): return handled
	var terrain:Variant=context.get("terrain",null)
	var sid:=String(context.get("settlement_id",""))
	var civic:=terrain is Object and is_instance_valid(terrain) and (terrain as Object).has_method("issue_civic_directive_text")
	if civic and (sid!="" or Hall.is_directive(text)):
		if sid!="": SettlementModel.select_settlement(sid)
		(terrain as Object).call("issue_civic_directive_text",text)
		return {"ok":true,"route":"civic","outcome":"It goes out to the council to be carried out."}
	var plan:=CustomDirective.offline_plan(text)
	if plan.is_empty(): plan=CustomDirective.attempt_plan(text)
	var policy:=CustomDirective.policy_from_plan(plan)
	var actor:Dictionary=context.get("actor",{}) if context.get("actor") is Dictionary else {}
	var execution:=0.8
	var person:=_person(actor)
	if not person.is_empty():
		var office:=String(person.get("office_key","Steward"))
		execution=clampf(float(AdvisorSystem.execution_modifier_for_advisor(person,office if office!="settlement" else "Steward",["Administration"])),0.2,1.2)
	var order_id:="court_%s_%d_%d" % [String(context.get("audience_id","")),Hall._day(),hash(text)%100000]
	var applied:Dictionary=ConsequenceEngine.apply_directive(CustomDirective.ID,CustomDirective.MAIN_MAGNITUDE,float(policy.get("days",CustomDirective.DEFAULT_DAYS)),"court_command",
		{"source_order_id":order_id,"directive_parameters":policy.get("directive_parameters",{})},execution)
	if not bool(applied.get("applied",false)):
		if civic:
			(terrain as Object).call("issue_civic_directive_text",text)
			return {"ok":true,"route":"civic","outcome":"It goes out to the council to be carried out."}
		# Nothing was set in motion: say so, never that it will be done.
		return {"ok":false,"route":"recorded","outcome":"Nothing is set in motion: nobody here has a way to carry that out as it was said. Say plainly what is to be done, and by whom."}
	var rate:=float((applied.get("assessment",{}) as Dictionary).get("implementation_rate",0.5))
	# Only a standing effort was set: say so, never that a concrete deed was done.
	var words:="well" if rate>=0.72 else ("unevenly" if rate>=0.36 else "only a little")
	var lacking:=String(plan.get("source",""))=="attempt"
	var outcome:=("We lack the means for most of it; the council will try %s as a standing order, and it will take hold %s." if lacking else "The council takes up %s as a standing order; it will take hold %s, and the reports will show what comes of it.") % [CustomDirective.display_name(plan),words]
	# A lasting work asked for ("Build a great monument to me") is commissioned
	# through the great works themselves; the standing order keeps only its
	# first month of marking out (order_great_work.gd).
	var work:Dictionary=preload("res://scripts/order_great_work.gd").start_from_order(text,order_id) if not law else {}
	# (The builder's own words; the assessment's reckoning stays on the work's card.)
	if bool(work.get("started",false)): outcome=String(work.get("line","")).get_slice(" Their chief worry",0).strip_edges()
	elif bool(work.get("asked",false)) and String(work.get("line",""))!="": outcome+=" "+String(work.line)
	return {"ok":true,"route":"custom_directive","order_id":order_id,"plan":plan,"applied":applied,"work":work,"outcome":outcome}

static func _refusal(id:String,audience:Dictionary,list:Array[Dictionary],r:Dictionary,person:Dictionary,verb:String)->Dictionary:
	## Rare and consequential: the brave, unafraid and embittered say no, and
	## then flee the god's reach, or the court seizes them for your judgment.
	var pid:=int(person.get("person_id",0))
	var name:=String(person.get("name","They"))
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	var flee:=courage>=0.8 and _roll(audience,"flee%d" % pid)<0.6
	GovernmentPeopleSystem.record_person_memory(pid,"I refused the god's command before the whole court.","divine",0.9,{"emotion":"defiance","outcome":"refused"})
	r.witness_ids=_witness_ids(id,[pid])
	if flee:
		var gone:=GovernmentPeopleSystem.person_departs(pid,"fled")
		r.stage="refuse_flee"; r.removed=bool(gone.get("ok",false))
		r.outcome="%s refused your command and fled the hall, beyond the reach of your guards.%s" % [name," %s took up the work." % ", ".join(PackedStringArray(gone.get("successors",[]))) if not (gone.get("successors",[]) as Array).is_empty() else ""]
		r.effects=_apply_court(id,"cast_out",{"person_id":0,"name":name},[pid])
		if bool((r.actor as Dictionary).get("speaker",false)):
			r.terminal=true
			Hall.conclude(id,String(r.outcome),"fled")
	else:
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":0.3,"resentment":0.1,"love":-0.05,"hold_days":30})
		r.stage="refuse_seized"
		r.outcome="%s refused your command. The court seized them; they kneel bound before you, awaiting your judgment." % name
		r.effects=_apply_court(id,"terrify",{"person_id":0,"name":name},[pid])
		audience["command_focus"]={"last_ref":"person:%d" % pid,"day":Hall._day()}
	r.executed=false; r.reaction="furious"
	return r

static func _fallback(id:String,r:Dictionary,reason:String)->Dictionary:
	## The act could not land as spoken (no one by that name, or the office
	## machinery refused): still a result, never silence. Just after an order
	## about a town we hold, words that land on nobody here are talk about
	## that town: the room answers them (from the facts), never this line.
	var audience:=Hall.find(id)
	if not audience.is_empty() and String(r.get("target_name",""))=="" and _town_talk(audience):
		r.handled=false; r.stage="none"; r.outcome=""; r["speech"]=true
		# The ruler's words are the voice's to show now, once.
		if String(audience.get("echoed_here",""))==String(r.get("text","")):
			var lines:Array=audience.get("lines",[])
			if not lines.is_empty() and String((lines[-1] as Dictionary).get("role",""))=="ruler" and String((lines[-1] as Dictionary).get("text",""))==String(r.get("text","")): lines.pop_back()
			audience.erase("echoed_here")
		return r
	r.stage="none"
	r.outcome=(reason+" " if reason!="" else "")+"Nobody here answers to that; the court waits for you to name who you mean."
	return r

## Is this audience in the middle of the business of a town we hold (an
## order about it just given, or its war leader's report on it)?
static func _town_talk(audience:Dictionary)->bool:
	if String(audience.get("origin",""))!="court" or WarOrders.held_towns().is_empty(): return false
	var last:Dictionary=audience.get("town_order",{}) if audience.get("town_order") is Dictionary else {}
	return not last.is_empty() and Hall._day()-int(last.get("day",-99))<=PENDING_DAYS

# --------------------------------------------------------------------------
# Words for the voice: stage directions and reactions
# --------------------------------------------------------------------------

const WEAPONS_STONE:=["a flint knife","a stone axe","a hardwood club","a fire-hardened spear","a bone dagger","a heavy hand-stone"]
const WEAPONS_METAL:=["a bronze blade","an iron sword","a copper axe","an iron-headed spear"]
## By how they kill, so a club never "opens a throat".
const BLADES:=["an iron sword","a bronze blade","a flint knife","a bone dagger","an obsidian knife"]
const CLUBS:=["a stone axe","a hardwood club","a heavy hand-stone","a copper axe"]

static func weapons(tags:Array)->Array[String]:
	var out:Array[String]=[]
	var metal:=tags.has("metal")
	for w:String in (WEAPONS_METAL if metal else [])+WEAPONS_STONE:
		if CV.permits(w,tags): out.append(w)
	return out

## Bracketed stage directions, per engine outcome. Tokens: {actor} {target}
## {weapon} {res} {amt}. "their/them" throughout: no one's sex is assumed.
const STAGE:={
	"kill_by":["[{actor} crosses the floor in three strides and drives {blade} into {target}'s throat; blood sprays across the hearthstones and the court cries out.]",
		"[{actor} seizes {target} by the hair and opens their neck with {blade}; {target} falls, and the watchers shrink back from the spreading dark.]",
		"[{actor} brings {club} down on {target}'s skull once, then again; the body slumps to the floor and nobody in the hall breathes.]",
		"[{actor} catches {target} as they rise and drives {blade} up under the ribs; {target} sags, and someone at the back retches.]"],
	"kill_by_reluctant":["[{actor}'s hands shake, but {blade} goes into {target}'s throat all the same; blood soaks their arms and they stand weeping over the body.]",
		"[{actor} whispers something to {target}, then cuts them down with {blade}; the court turns its faces from the blood pooling by the fire.]",
		"[{actor} closes their eyes and swings {club}; {target} drops without a sound, and {actor} does not look down.]"],
	"kill_guards":["[The guards drag {target} to the centre of the hall and break their skull with {club}; the court stares at the floor.]",
		"[Two guards pin {target} to the ground and {weapon} does the rest; blood runs between the floor stones as the court stands frozen.]",
		"[{target} is hauled out past the fire; one cry comes from outside, then silence, and the guards return with {blade} dripping.]"],
	"exile":["[{target} is stripped of every mark of office and driven out past the last hearth with nothing but the clothes on their back.]",
		"[Spear points herd {target} to the edge of the camp and push them out into the dark; the court listens to the footsteps fade.]"],
	"detain":["[{target}'s arms are wrenched behind them and their wrists bound with rawhide cord; they are dragged away to be kept under guard.]",
		"[{target} is thrown to the floor and tied hand and foot; the guards haul them off under watch while the court looks away.]"],
	"give":["[Bearers carry {amt} {res} out of the stores and heap it at {target}'s feet while the whole court watches.]",
		"[{amt} {res} is brought out and laid before {target}, who stares at the pile and then at you.]"],
	"take":["[The guards tear open the envoy's packs and haul the goods away; the envoy watches, white to the lips.]",
		"[Your guards strip the envoy's bearers of their loads while the envoy stands rigid with fury.]"],
	"penance":["[{target} sinks to their knees and presses their brow to the cold ground, beginning the fast.]",
		"[{target} unbelts, kneels in the ashes at the edge of the fire, and bows their head for the vigil.]"],
	"terrify":["[{target} goes grey and sinks to the floor as the god's anger fills the hall.]"],
	"bless":["[{target} bows low while the court watches, the god's favour settling on them like the warmth of a fire.]",
		"[The court draws back to give {target} room; they stand straighter than anyone has seen them stand.]"],
	"raise":["[The court parts as {target} is brought forward and set in the place of honour nearest the fire.]"],
	"appoint":["[The marks of office are taken from their old keeper and hung on {target} before the whole court.]",
		"[{target} is led to the seat of the office and the court rises to acknowledge them.]"],
	"boon":["[A gift from the stores is carried in and set before {target}; they touch it as if it might vanish.]"],
	"demote":["[{target}'s marks of office are taken from them before the whole court; they stand bare and silent.]"],
	"send":["[{actor} bows, gathers their gear and strides out of the hall, already calling for companions.]",
		"[{actor} touches their brow to the floor and is gone before the fire settles, shouting for packs and water skins.]"],
	"war_march":["[{actor} is on their feet at once, calling for the fighters to gather their spears and food.]",
		"[{actor} goes out to the drill ground; within the hour the fighters are being counted and loaded for the road.]"],
	"war_object":["[{actor} does not move to the door. They stand where they are and answer you plainly.]"],
	"war_refuse":["[{actor} stays where they are and tells you what stands in the way.]"],
	"war_fate":["[{actor} bows and sends a runner to the garrison with your word.]","[{actor} goes out to send your word to the garrison; the court is very quiet.]"],
	"war_captives":["[{actor} goes out to give your word to those who guard the captives; the court is very quiet.]","[{actor} bows and sends a runner with your word about the captives.]"],
	"war_already":["[{actor} answers at once; the fighters are already on the road.]"],
	"order":["[{actor} bows and goes out to see it done; word of the order runs ahead of them through the camp.]",
		"[{actor} is on their feet at once and out through the door, calling names as they go.]"],
	"hesitate":["[{actor} takes up {blade}, then freezes; the point trembles a hand's breadth from {target}, and every eye turns to you.]",
		"[{actor} steps toward {target} with {weapon}, stops, and falls to their knees instead, the weapon still in hand.]"],
	"refuse_flee":["[{actor} lets {weapon} fall, turns, and runs out of the hall into the dark before the guards can close on them.]",
		"[{actor} flings {weapon} at the fire and bolts through the door; by the time the guards reach it they are gone into the night.]"],
	"refuse_seized":["[{actor} throws {weapon} down; the others fall on them at once and force them to their knees before you, arms bound.]",
		"[{actor} refuses and the court is on them in a heartbeat, dragging them to the floor and binding them before your seat.]"],
	"prostrate":["[The whole court falls on its face; nobody dares so much as lift their eyes toward you.]"],
	"envoy_kill":["[The guards seize {target} and cut them down where they stand with {blade}; their blood runs across the floor stones and their bearers flee screaming from the hall.]",
		"[{target} has no time to cry out; {blade} opens their throat, and the envoy's companions throw down their packs and run.]",
		"[The guards bring {club} down on {target}'s skull; they crumple without a word, and their retinue wails at the door as the guards drive them off.]"],
	"envoy_maim_mutilate":["[The guards force {target} to the floor and {blade} takes their {part}; they scream until their voice breaks, and their bearers weep as they drag them out toward home.]",
		"[{target} is held down across the hearthstones while {blade} does its work on their {part}; they faint, and their retinue carries them out, white-faced and silent.]",
		"[Two guards pin {target} while {blade} hacks at them; the envoy's shrieks fill the hall, and their companions haul them out with blood soaking through the cloth.]",
		"[{target} screams and thrashes as {blade} falls; the wound is seared in the fire, and their bearers drag the fainting envoy out onto the road home.]"],
	"envoy_maim_beat":["[The guards throw {target} down and flog them until their back runs red; their bearers lift the sobbing envoy and stumble out.]",
		"[Fists and {club} fall on {target} until they curl on the floor; their companions drag them out, bleeding and groaning.]"],
	"envoy_maim_humiliate":["[The guards shave {target}'s head and strip them before the whole court; the envoy shakes with shame and fury as they are shoved out of the door.]",
		"[{target} is dragged through the ash and dung by the fire while the court jeers; their retinue throws a cloak over them and hurries them away.]"],
	"maim_beat":["[The guards throw {target} down and flog them until their back runs red; the court stares at the floor until it is over.]",
		"[{target} is stretched over the log by the fire and beaten; nobody in the hall moves to help them.]"],
	"maim":["[The guards hold {target} down and {blade} falls; they scream, and the court stares at the floor until it is over.]",
		"[{target} is forced to their knees and struck again and again with {club}; nobody in the hall moves to help them.]"],
	"envoy_detain":["[{target} is thrown down and bound with cord while their bearers are driven out, wailing, to carry word home.]"],
	"envoy_exile":["[{target} is hustled out of the hall at spear point, their packs kicked after them into the dirt.]"],
}

static func stage_key(result:Dictionary)->String:
	var stage:=String(result.get("stage",""))
	var target:Dictionary=result.get("target",{}) if result.get("target") is Dictionary else {}
	var has_actor:=String(result.get("actor_name",""))!="" and not (result.get("actor",{}) as Dictionary).is_empty()
	if String(target.get("kind",""))=="envoy" and stage in ["kill","detain","exile"]: return "envoy_"+stage
	if String(target.get("kind",""))=="envoy" and stage=="maim": return "envoy_maim_"+String(result.get("harm","mutilate"))
	if stage=="maim" and String(result.get("harm",""))=="beat": return "maim_beat"
	if stage=="kill":
		if not has_actor: return "kill_guards"
		return "kill_by_reluctant" if String((result.get("obedience",{}) as Dictionary).get("id",""))=="reluctant" else "kill_by"
	return stage if STAGE.has(stage) else ""

static func stage_bank(result:Dictionary)->Array:
	return STAGE.get(stage_key(result),[])

static func _pick(list:Array,tags:Array,rng:RandomNumberGenerator,fallback:String)->String:
	var pool:Array=[]
	for w in list:
		if CV.permits(String(w),tags): pool.append(w)
	# The newest the era allows are the ones at hand; keep a little variety.
	if pool.is_empty(): return fallback
	return String(pool[rng.randi_range(0,mini(1,pool.size()-1)) if tags.has("metal") else rng.randi_range(0,pool.size()-1)])

static func stage_tokens(result:Dictionary,tags:Array,rng:RandomNumberGenerator)->Dictionary:
	var terms:Dictionary=result.get("terms",{}) if result.get("terms") is Dictionary else {}
	var any:=weapons(tags)
	var weapon:=String(any[rng.randi_range(0,any.size()-1)]) if not any.is_empty() else "bare hands"
	var out:={"actor":String(result.get("actor_name","")),"target":String(result.get("target_name","")),"weapon":weapon,
		"blade":_pick(BLADES,tags,rng,"a sharpened stone"),"club":_pick(CLUBS,tags,rng,"a heavy stone"),
		"res":String(terms.get("resource","")).to_lower(),"amt":"%d" % roundi(float(terms.get("amount",0.0))) if terms.has("amount") else ""}
	if String(out.actor)=="": out.erase("actor")
	if String(result.get("part",""))!="": out["part"]=String(result.part)
	return out

## Reactions (opener x closer pairs, as in divine_voice.gd).
const REACTION:={
	"obey_deed":[["It is done, {address}.","As you commanded.","Your word was my hand.","I did not falter.","You spoke, and it is finished."],
		["Command me again.","Nobody will question it.","The hall is yours.","Let it be a lesson to every one of us.","I would do it again."]],
	"reluctant_deed":[["It is done.","I have done as you commanded.","My hands obeyed you.","You are my god, and it is done."],
		["Do not ask me to wash them yet.","I will carry it all my days.","I pray I never do it again.","Let no one say I was slow."]],
	"obey_task":[["At once, {address}.","I go now.","It will be done.","As you command."],
		["You will hear of it soon.","I come back only when it is done.","Nothing will stop me.","I am already on my way."]],
	"plead":[["Do not ask this of me, {address}.","Not by my hand, I beg you.","Mercy, for them and for me.","I have eaten at their fire."],
		["Say it once more and I will do it.","If you will it again, I will obey.","Let another hand do it, or say the word again.","I will obey, but I beg you to think."]],
	"refuse":[["No. Not this, {address}.","I will not do this thing.","You may be a god; I am still a person."],
		["Do with me what you will.","Find another hand.","I will not carry this on my soul."]],
	"receive":[["You honour me, {address}.","This is more than I earned.","My household will eat well."],
		["I will not forget it.","I will repay it in work.","Everyone saw your hand open."]],
	"seized":[["Let me go.","I only said what was true.","Strike, then."],
		["I am still not sorry.","My kin will remember this.","I have nothing more to say."]],
}

static func reaction_bank(key:String)->Array:
	var pair:Array=REACTION.get(key,[])
	if pair.size()<2: return []
	var out:Array=[]
	for a in pair[0]:
		for b in pair[1]: out.append("%s %s" % [String(a),String(b)])
	return out

static func actor_reaction_key(result:Dictionary)->String:
	var ob:=String((result.get("obedience",{}) as Dictionary).get("id","obey"))
	var stage:=String(result.get("stage",""))
	match ob:
		"hesitate": return "plead"
		"refuse": return "refuse"
		"reluctant": return "reluctant_deed" if stage in ["kill","exile","detain","maim"] else "obey_task"
	if stage in ["kill","exile","detain","maim"]: return "obey_deed"
	if stage in ["send","order"]: return "obey_task"
	return ""   # war_*: the war leader's own words (actor_says) answer

## What the voice is told: the engine's decision in plain words.
static func decided_words(result:Dictionary)->String:
	var ob:Dictionary=result.get("obedience",{}) if result.get("obedience") is Dictionary else {}
	var actor:=String(result.get("actor_name",""))
	var parts:PackedStringArray=PackedStringArray()
	parts.append("WHAT ACTUALLY HAPPENED (decided; describe it, never change it): "+String(result.get("outcome","")))
	match String(ob.get("id","obey")):
		"obey": if actor!="": parts.append("%s OBEYED%s." % [actor," at once, trembling" if String(ob.get("manner",""))=="trembling" else ", without hesitating"])
		"reluctant": parts.append("%s OBEYED, reluctantly: it cost them; they did it anyway." % actor)
		"hesitate": parts.append("%s HESITATED: they have NOT done it yet; they plead once with the god. The god's word still stands; if the god insists they will do it." % actor)
		"refuse": parts.append("%s REFUSED. %s" % [actor,"They fled the hall." if String(result.get("stage",""))=="refuse_flee" else "The court seized them; they kneel bound before the god."])
	if String(result.get("verb",""))=="war":
		var verdict:=String((result.get("war",{}) as Dictionary).get("verdict",""))
		parts.append("THE WAR LEADER'S ANSWER, in substance (keep every number exactly): "+String(result.get("actor_says","")))
		if verdict=="act": parts.append("The army HAS set out; say so plainly with the place and the days on the road.")
		elif verdict=="fate" and String((result.get("war",{}) as Dictionary).get("kind",""))=="captives": parts.append("The god's word about the captives of our fight HAS been carried out; tell it soberly, keeping every number, with no gore.")
		elif verdict=="fate": parts.append("The god's word about the town we hold HAS been carried out; tell it soberly, keeping every number, with no gore.")
		elif verdict=="held": parts.append("The town is ALREADY OURS; nobody marches against it. Say who holds it and ask what is to become of it.")
		elif verdict=="noted": parts.append("The god let it drop: nothing more is done to the town's people. Say so plainly.")
		elif verdict=="ask": parts.append("NOTHING has been done yet; the war leader asks the god ONE question, with the choices exactly as given. Ask it once, plainly.")
		elif verdict=="object": parts.append("%s OBJECTS: nothing has marched. They explain why and what would fix it; if the god insists they will go." % actor)
		elif String((result.get("war",{}) as Dictionary).get("reason",""))=="already_marching": parts.append("Nothing NEW is ordered: the army the god sent is ALREADY on the road; say so plainly with the place and the days left. Never promise to go again.")
		else: parts.append("It CANNOT be done as ordered: nothing has marched. Say plainly why and what would change that. Never promise to go.")
	if bool(result.get("removed",false)) and String(result.get("target_name",""))!="": parts.append("%s is gone and does not speak." % String(result.target_name))
	return " ".join(parts)
