extends RefCounted
## Words for the court-known persons engine (court_persons.gd). The engine
## decides; these only say it. Each beat is spoken from, in order: a template
## learned from live play for exactly this situation (court_persons_bridge.gd,
## matched on action, role, guilt, lie state and era), else the banks below.
## Banks are era-neutral (fire, stone, hide, kin, seasons); any word a people
## does not yet know is filtered by character_voice.gd before it is spoken.
## Slots: {name} {given} {trade} {village} {age} {household} {detail} {He} {he}
## {his} {event} {liar} {liar_title} {charge} {place} {witness} {culprit}
## {named} {kin} {office} {spouse} {act} {ledger} {title} {count} {god_address}.

const CV:=preload("res://scripts/character_voice.gd")
const Bridge:=preload("res://scripts/court_persons_bridge.gd")

const BANK:={
	# ---- an official answers
	"blame":["That was {name}'s doing, {god_address}: the {trade} of {village}. {He} had the keeping of it the day {event}.",
		"{name}. A {trade}, {age} winters, {household}. It was under {his} hands that {event}, and everyone at the fire knows it.",
		"Ask anyone at {village}: {name} the {trade}. {He} {detail}, and {he} was the one at the work when {event}."],
	"blame_lie":["It was {name}, {god_address}, the {trade} from {village}. {He} was set to watch over it, and {he} let it go.",
		"{name}. A {trade} of {village}, {age} winters. {He} had the minding of it; the fault is {his} that {event}.",
		"That would be {name}, the {trade}. {He} {detail}. Careless hands, {god_address}; that is why {event}."],
	"blame_again":["I told you, {god_address}: {name}, the {trade} of {village}. That has not changed.","The same as before: {name}. Ask me a hundred times, it will still be {name}."],
	"credit":["Credit {name}, {god_address}: the {trade} of {village}. {He} worked it out, {age} winters old and stubborn as a root.",
		"{name} is behind it. {He} {detail}, and {he} kept at it until it was done."],
	"describe":["{name}, {god_address}: a {trade} of {village}, {age} winters, {household}. {He} {detail}.",
		"There is {name}, the {trade}. {Age} winters, {household}. {He} {detail}; you would know {him} anywhere.",
		"{name} of {village}. A {trade}; {household}. {He} {detail}, and {he} is {temper}."],
	"describe_group":["The {trade} of {village}? {count} of them work together. {name} speaks for them; {he} {detail}.",
		"There are {count} {trade} at {village}, and {name} is the one they listen to. {He} is {temper}."],
	"unknown":["No one at this court knows such a one, {god_address}. The {trade} beyond the hills might. We could send runners to look.",
		"I cannot name them; nobody here has met them. Send runners, and they will be found."],
	"found":["The runners are back. They found {name}, a {trade}, {age} winters, {household}. {He} {detail}.",
		"Found, {god_address}: {name} the {trade}. {He} walked three days to answer."],
	"tell_charge":["{charge} are the {liar_title}'s charge, not a {trade}'s. Everyone here knows who keeps them.",
		"Odd. I always thought {charge} were {liar}'s to watch."],
	# ---- a stage direction
	"tell_demeanor":["[{liar} answers quickly and does not meet your eyes.]","[{liar} rubs a thumb along the edge of their cloak and looks at the fire, not at you.]"],
	"tell_voice":["[{liar}'s voice climbs as they speak, and the court goes still.]","[{liar} swallows hard between each word.]"],
	"liar_uneasy":["[On the bench, {liar} shifts and looks toward the door.]","[{liar} goes very still on the bench.]"],
	"threatened":["[The court leans away as your anger fills the hall; {given} shrinks to the floor.]","[{given} flinches as if struck, though no one has moved.]"],
	"arrive_stage":["[{name} is brought in, still dirty from the work, and drops to both knees before you.]","[{name}, {age} winters, is led to the fire; {he} {detail}, and cannot stop staring at you.]"],
	"arrive_group":["[{count} {trade} crowd in at the door; {name} is pushed to the front to speak for them.]"],
	"ledger_contradicts":["[The {ledger} are laid out before you. The marks for the day {event} are the {title}'s own, not {named}'s.]"],
	"ledger_confirms":["[The {ledger} are laid out before you. They bear out what was said about the day {event}.]"],
	"nothing":["[The {ledger} are brought. They say nothing to the point.]"],
	"judge_execute":["[The guards drag {name} to the centre of the hall; one blow, and {he} does not rise. Nobody on the bench breathes.]","[{name} is held down by the fire and struck dead; the court turns its faces from the blood.]"],
	"judge_exile":["[{name} is stripped of everything but {his} clothes and driven out past the last hearth.]"],
	"judge_maim":["[The guards hold {name} down and do what you commanded; {his} cry goes on and on, and then {he} is carried out.]"],
	"judge_curse":["[Your curse falls on {name} before the whole court; the people near {him} step back as if {he} burned.]"],
	"judge_example":["[{name} is bound hand and foot and carried through the camp, so that every hearth sees what befalls those who cross you.]"],
	"judge_exalt":["[The court parts as {name} is brought forward and set in the place of honour nearest the fire.]"],
	"judge_reward":["[A gift from the stores is carried in and set before {name}, who touches it as if it might vanish.]"],
	"judge_pardon":["[At your word the guards step back from {name}.]"],
	"judge_priest":["[{name} is led to the god's fire and given the keeping of it before the whole court.]"],
	"judge_office":["[The marks of office are hung on {name}, the {trade}, before the whole court; the bench stares.]"],
	"judge_marry":["[{spouse} is brought in and set beside {name}; the court murmurs its blessing.]"],
	"judge_novel":["[At your word it is done: {act}. The court watches {name} in silence.]"],
	# ---- the summoned speak for themselves
	"arrive_guilty":["You sent for me, {god_address}. I came as fast as I could.","I am here. I am here. What would you have of me?"],
	"arrive_named":["I am {given}, a {trade} of {village}. They said you called for me by name, {god_address}. I do not know why.","Why me, {god_address}? I am only a {trade}."],
	"arrive":["{given}, {god_address}. A {trade} of {village}. I have never stood so near the fire of the god.","I came when I was called. What would you have of a {trade}?"],
	"alibi":["I was {place} that whole moon, {god_address}. {witness} was with me every day; ask {witness}.","When {event}, I was {place}. {witness} can tell you. I only heard of it when we walked home."],
	"alibi_named":["I was {place} when it happened, {god_address}! {witness} was with me. Whoever named me was not there to see it.","{place}, {god_address}, the whole moon, with {witness}. Who says it was me? {charge} are not a {trade}'s to keep; ask {liar}."],
	"alibi_kin":["I was {place}, with {witness}. I know who was minding it that day, {god_address}: {culprit}. Ask {liar} why {liar} named me instead.",
		"Not me. I was {place}. It was {culprit} at the work that day, and {liar} knows it; that is {liar}'s own kin."],
	"protest":["I did not do it, {god_address}. I swear by the fire, I was not even near.","No! Not by my hand. I was {place}, and {witness} will say so."],
	"protest_named":["I did not do it! I was {place}, with {witness}. Why would {liar} say it was me? {charge} are {liar}'s to keep, not mine.",
		"No, {god_address}. I was far away. Ask {liar} who truly had the keeping of it."],
	"swear_true":["I swear it before you and before my children: I had no part in it.","I swear it, {god_address}, by my own life."],
	"swear_true_named":["I swear it before you. I was {place} with {witness}. {liar} named the wrong one.","By the fire and by my children, I swear I had no part in it."],
	"thanks_alibi":["Thank you, {god_address}. I was {place}; {witness} knows. That is the whole of it.","Your mercy is more than I hoped. But hear me: I was {place}, with {witness}."],
	"thanks_alibi_named":["Thank you, {god_address}. I was {place} with {witness}. It was never mine to keep; ask {liar}."],
	"witness":["{witness} was with me, {god_address}. Send for {witness} if you doubt me.","Ask {witness}. We were {place} together the whole moon."],
	"vague":["I was... at the work, mostly. Here and there. Where I always am, {god_address}.","Near {village}. At the fire, then at the work, then... I do not remember every day."],
	"deny":["It was not me, {god_address}. I do not know who says so, but it was not me.","No. Others were there too. Why me?"],
	"beg":["Please, {god_address}. I have children. Whatever you think I did, spare them.","Mercy, {god_address}, mercy. I will work twice as hard; only spare my household."],
	"confess":["It was me. It was me, {god_address}. I was careless; that is why {event}. Do what you will.","Yes. I did it. I have not slept since. Take me, not my household."],
	"swear_false":["I swear it, {god_address}. I had no part in it.","I swear by the fire. It was not me."],
	"shift_blame":["Why ask me? There were others at the work. Ask them what they saw.","Plenty of hands were near it, {god_address}. Mine were only two of them."],
	"no_one_guilty":["No one, {god_address}. No one knows anything.","There is no one else. I was alone."],
	"no_one":["Who else? Only my own household knows my days, {god_address}.","No one, {god_address}; I keep to my own work."],
	"false_confession":["Yes. Yes, it was me. I did it. Only spare my children, {god_address}, I beg you.","It was me. Whatever you say I did, I did it. Please."],
	"did_what":["Did what, {god_address}? I have done nothing but my work.","I do not understand. What is it I am meant to have done?"],
	"where_plain":["At {village}, {god_address}, at my work as always.","Where I always am: at the fire at {village}."],
	"thanks":["You are kind, {god_address}. I will tell my household.","Thank you. I did not expect kindness today."],
	"cower":["Forgive me, {god_address}, whatever I have done.","I am nothing, {god_address}. Do not look at me so."],
	"talk":["I will answer whatever you ask, {god_address}.","Ask, {god_address}. I will tell you what I know."],
	"react_maim":["[{given} makes no sound now.]"],
	"react_curse":["What will become of my household now?","I will carry it. I have no choice."],
	"react_example":["Let them look. Let them all look.","I understand, {god_address}. Everyone will understand."],
	"react_exalt":["Me? A {trade}? I will not shame you, {god_address}.","I do not know what to say. I will serve you until I am in the ground."],
	"react_reward":["My household will eat well. I will not forget it.","This is more than a {trade} earns in a season."],
	"react_pardon":["I will not waste this, {god_address}.","Thank you. Thank you. I will go home now, if I may."],
	"react_priest":["I will keep your fire as long as I draw breath.","I am not worthy of it. I will try to be."],
	"react_marry":["As you will it, {god_address}.","I will be a good {trade} to {spouse}, and a good partner."],
	"react_novel":["As you command, {god_address}."],
	# ---- accusation of an official
	"protest_honest":["I told you the truth, {god_address}. It was {named}; I have nothing else to give you.","You wound me. I have never lied to you, and I did not now."],
	"confess_self":["...It was mine. The fault is mine that {event}; I named {named} to save my own skin. Do what you will with me.","I lied. {charge} are my charge, and I failed at them. {named} had nothing to do with it."],
	"confess_kin":["It was {culprit}. My own blood. I named {named} to spare {culprit}. Punish me if you must, but I could not give you my kin.","Forgive me. It was {culprit} at the work that day, not {named}. I lied to shield my family."],
	"double_down":["I have told you what happened, {god_address}. It was {named}.","Why would I lie to you? It was {named}; ask anyone."],
	# ---- the bench
	"witness_wary":["Careful. If the god doubts the honest, we are all on the fire.","I would not want to be called a liar with nothing behind it."],
	"witness_exposed":["So that is how it was. I wondered.","A lie to the god's face. I did not think anyone here had the nerve."],
	"witness_doubt":["That is fear speaking, not the truth.","I have seen a hare confess to being a wolf when the dogs were close."],
	"witness_execute":["That settles who holds the fire here.","Nobody will sleep tonight."],
	"witness_exile":["Out into the cold. They will not last the winter alone.","Gone. Let the camp remember it."],
	"witness_maim":["Everyone will know that face now.","A hard lesson, and a lasting one."],
	"witness_curse":["No one will share a fire with them now.","A curse from the god's own mouth. Terrible."],
	"witness_example":["Every hearth will hear of this by morning.","Fear teaches fast. It does not teach well."],
	"witness_exalt":["A {trade} raised up. The whole camp will be at our doors asking for the same.","Well. Who would have thought it."],
	"witness_reward":["Good. Reward work and get more of it.","That will be talked of at every hearth."],
	"witness_pardon":["Mercy. It suits you.","They will remember this kindness."],
	"witness_priest":["A keeper for the fire. The people will like it.","Let us hope they keep it better than they kept their tongue."],
	"witness_marry":["A good match, or a good lesson. We will see.","The camp loves a wedding."],
	"witness_novel":["Well. That will be remembered."],
}

## Beats that belong to the principal speaker of an exchange; these may be
## replaced by a learned template for the same situation.
const PRINCIPAL_BEATS:=["blame","blame_lie","blame_again","credit","describe","describe_group","found","unknown","alibi","alibi_named","alibi_kin","protest","protest_named","swear_true","swear_true_named",
	"thanks_alibi","thanks_alibi_named","witness","vague","deny","beg","confess","swear_false","shift_blame","no_one_guilty","no_one","false_confession","did_what","where_plain","thanks","cower","talk",
	"protest_honest","confess_self","confess_kin","double_down","react_exalt","react_reward","react_pardon","react_priest","react_marry","react_curse","react_example"]

static func fill(template:String,slots:Dictionary)->String:
	var out:=template
	var s:=slots.duplicate()
	if not s.has("god_address"): s["god_address"]="Great One"
	var he:=String(s.get("he","they"))
	s["He"]=he.capitalize()
	s["him"]="her" if he=="she" else ("him" if he=="he" else "them")
	s["Age"]=String(s.get("age","")).capitalize()
	s["Given"]=String(s.get("given",""))
	for k in s:
		out=out.replace("{"+String(k)+"}",String(s[k]))
	out=out.replace("  "," ").strip_edges()
	if out.length()>0 and not out.begins_with("["): out=out.substr(0,1).to_upper()+out.substr(1)
	return sentence_case(out)

static func sentence_case(text:String)->String:
	## A slot that opens a sentence ("{charge} are...") starts with a capital.
	var re:=RegEx.new(); re.compile("((?<!\\.)[.!?] |\\[|: )([a-z])")
	var out:=text
	for m in re.search_all(text):
		var at:=m.get_start(2)
		out=out.substr(0,at)+m.get_string(2).to_upper()+out.substr(at+1)
	return out

static func _lower_lead(text:String)->String:
	## Lower-case a line's first letter after a lead-in, unless it is "I" or a name.
	var first:=text.get_slice(" ",0)
	if first=="I" or first.begins_with("I'") or first.begins_with("I,"): return text
	if first.length()>1 and first.substr(1,1)==first.substr(1,1).to_lower() and first.substr(0,1)==first.substr(0,1).to_upper() and first.to_lower() in ["yes","no","yes.","no.","no!","yes,","no,","why","who","what","it","not","please","thank","mercy","ask","that","there","when","then","this","your","you","we","my","me","a","the","at","near","where","forgive","as","well","nobody","no-one","why,","mercy,","please,"]:
		return text.substr(0,1).to_lower()+text.substr(1)
	return text

static func usable(text:String,slots:Dictionary={})->bool:
	## Era-true, with every slot filled. Words the facts themselves use (an
	## event's own title, a place) are allowed to the speaker.
	if text=="" or "{" in text: return false
	var facts:PackedStringArray=PackedStringArray()
	for k in slots: facts.append(String(slots[k]))
	return CV.permits(text,CV.era_tags("player")+CV.lexicon_tags_in(" ".join(facts)))

static func render(beats:Array,sig:Dictionary,rng:RandomNumberGenerator)->Array:
	## Beats to transcript lines. The principal line may come from a learned
	## template for exactly this situation; everything else from the banks.
	var out:Array=[]
	var principal_done:=false
	for b in beats:
		if not b is Dictionary: continue
		var beat:Dictionary=b
		var key:=String(beat.get("beat",""))
		var slots:Dictionary=beat.get("slots",{}) if beat.get("slots") is Dictionary else {}
		var persona:=_persona(beat)
		if persona.has("address"): slots=slots.merged({"god_address":String(persona.address)},true)
		var text:=""
		var principal:=not principal_done and String(beat.get("role",""))!="narrator" and not bool(beat.get("aside",false)) and key in PRINCIPAL_BEATS
		if principal:
			principal_done=true
			var learned:=Bridge.replay(sig,key,slots,rng)
			if learned!="" and usable(learned,slots): text=learned
		if text=="":
			var bank:Array=BANK.get(key,[])
			var pool:Array=[]
			for t in bank:
				var filled:=fill(String(t),slots)
				if usable(filled,slots): pool.append(filled)
			if pool.is_empty(): continue
			text=String(pool[rng.randi_range(0,pool.size()-1)])
			# A modelled speaker sometimes opens in their own manner.
			var tics:Array=persona.get("tics",[]) if persona.get("tics") is Array else []
			if String(beat.get("role",""))!="narrator" and not tics.is_empty() and rng.randf()<0.25 and not text.begins_with("["):
				var tic:=String(tics[rng.randi_range(0,tics.size()-1)])
				if CV.permits(tic,CV.era_tags("player")) and not bool(beat.get("aside",false)): text="%s %s" % [tic,_lower_lead(text)]
		out.append({"speaker":String(beat.get("speaker","")),"role":String(beat.get("role","official")),"person_id":int(beat.get("person_id",0)),"text":text,"aside":bool(beat.get("aside",false)),"beat":key})
	return out

static func _persona(beat:Dictionary)->Dictionary:
	var of:Dictionary=beat.get("persona_of",{}) if beat.get("persona_of") is Dictionary else {}
	if int(of.get("official",0))>0:
		var p:=GovernmentPeopleSystem.person_snapshot(int(of.official))
		return CV.for_person(p) if not p.is_empty() else {}
	if String(of.get("known",""))!="":
		var cp:Variant=load("res://scripts/court_persons.gd")
		var rec:Dictionary=(cp as GDScript).call("by_id",String(of.known)) if cp is GDScript else {}
		return (cp as GDScript).call("persona",rec) if not rec.is_empty() else {}
	return {}

static func principal_beat(beats:Array)->String:
	## The beat of the exchange's principal line (the one a learned template may replace).
	for b in beats:
		if not b is Dictionary: continue
		var beat:Dictionary=b
		if String(beat.get("role",""))!="narrator" and not bool(beat.get("aside",false)) and String(beat.get("beat","")) in PRINCIPAL_BEATS: return String(beat.beat)
	return ""

static func novel_choices(sig:Dictionary)->Array:
	return Bridge.promoted(sig)
