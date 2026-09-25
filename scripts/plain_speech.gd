extends RefCounted
## Plain speech. People at court say concrete things about the situation in
## front of them: who, what, what it costs, what they want the god to do and
## why. Character shows in diction, rhythm and temper, never in invented
## fortune-cookie maxims ("a free bundle is best counted twice", "a full store
## is a quiet camp", "gift-food fills bellies, but a fox leaves tracks") or
## skaldic kennings ("word-hoard", "border-song").
##
## One detector, used in three places:
##  - tests/plain_speech_probe.gd scans every offline line table;
##  - audience_voice.gd (and the other live voices) strip flagged sentences
##    from model output before it is shown;
##  - interaction_store.gd / court_persons_bridge.gd refuse to learn a flagged
##    reply template, so a maxim never reaches offline play.
##
## The heuristics work clause by clause. A clause is aphoristic when it states
## a timeless generality with no speaker in it (no I/we/you), nothing counted,
## nobody named and no {token} standing for a real value.

## Words that put a speaker, a listener or the present moment into a clause.
const STANCE:="(?i)\\b(i|i'm|i'll|i've|i'd|me|my|mine|myself|we|we're|we'll|we've|we'd|us|our|ours|ourselves|you|you're|you'll|you've|you'd|your|yours|ye|yer|let's|let|he|she|him|her|his|they|them|their|theirs|they're|they'll|this|these|those|here|there|present|now|today|tonight|yesterday|tomorrow|already|still|yet|left|last|next|ago|since|sent|brought|came|went|said|told|asked|saw|heard|took|gave|did|was|were|had|will|would|shall|should|must|can|could|may|might)\\b"
## First and second person only (a maxim may still say "today").
const PERSON:="(?i)\\b(i|i'm|i'll|i've|i'd|me|my|mine|we|we're|we'll|we've|we'd|us|our|ours|you|you're|you'll|you've|you'd|your|yours|ye|yer)\\b"
## Tokens that are only seasoning, not concrete content.
const SEASONING_TOKENS:="\\{(address|oath|proverb|god_address)\\}"
## A generic subject opening a clause.
const GENERIC_OPEN:="(?i)^(but |and |yet |so )?(a|an|every|whoever|anyone who|he who|she who|those who|one who|the one who|the \\w+ (that|who|which))\\b"
## Verbs that turn a noun phrase into a timeless saying (base forms; the
## third-person forms are derived).
const VERB_BASE:=["fill","feed","keep","leave","make","buy","mend","break","burn","bend","warm","starve","hide","know","remember","forget","wait","chase","sink","outlast","rattle","count","give","take","pay","cut","catch","bite","bark","sing","build","grow","last","travel","run","win","lose","hold","carry","owe","cost","bring","ask","tell","lie","speak","walk","sleep","eat","hunt","die","live","beat","end","come","go","fall","rise","melt","freeze","flood","drown","fly","feast","fatten","thin","sharpen","dull","shine","smoke","stink","sour","spoil","rot","heal","hurt","weigh","matter","argue","blow","flow","forgive","return","tangle","untie","tie","knot","spill","echo","serve","rule","obey","trust","fear","love","hate","kill","save","guard","open","shut","care","plant","hiss","bleed","wander","listen","answer","wear","wake","dig","stand","sit","follow","lead","need","want","spend","waste","steal","sow","reap","ripen","crack","hunger","roar","whisper","shout"]
## Nouns that make a generic subject into a folk image.
const IMAGE_NOUNS:="fox|foxes|wolf|wolves|goose|geese|crow|crows|bear|bears|heron|herons|eel|eels|river|rivers|sea|tide|tides|wind|winds|ice|fire|fires|flame|flames|spark|sparks|stone|stones|flint|hearth|hearths|snake|snakes|dog|dogs|owl|owls|ox|oxen|hare|hares|deer|boar|raven|ravens|bird|birds|fish|tree|trees|root|roots|seed|seeds|smoke|winter|winters|storm|storms|gull|gulls|goat|goats|mud|trap|traps|field|fields|lamp|lamps|gourd|gourds|shore|edge|edges|cook|cooks|guest|guests|boast|boasts|belly|bellies|horse|horses|spear|spears|knot|knots|sack|sacks|store|stores|camp|camps|bundle|bundles|gift|gifts|feast|feasts|hunger|meal|meals|word|words|tongue|tongues|hand|hands|debt|debts|friend|friends|neighbour|neighbours|stranger|strangers|leak|leaks|rope|ropes|bone|bones|pot|pots|cup|cups|honey|nettle|nettles|thorn|thorns|plants|men|folk|people|peoples|grief|pride|fear|anger|silence|patience|haste|rain|rains|snow|frost|sun|moon|night|nights|road|roads|path|paths|wall|walls|border|borders|back|backs"
## Beasts and weather that a saying gives a will ("the wind does not argue").
const NATURE_NOUNS:=["fox","wolf","goose","crow","bear","heron","eel","river","sea","tide","wind","ice","spark","snake","owl","hare","raven","gull","goat","mud","storm","frost","smoke","boar","dog","trap","gourd"]
## What only a creature with a will does ("the river gives", "the wind does not argue").
const PERSONIFY:="(?i)^(knows|remembers|forgets|waits|chases|counts|gives|takes|keeps|forgives|cares|argues|does not|doesn't|never|always|lies|speaks|owes|pays|asks|tells|trusts|fears|loves|hates|laughs|listens|judges|punishes|rewards)\\b"
## Words that open a parallel verbless pair but never a saying.
const PARALLEL_STOP:=["of","how","not","no","very","so","too","as","what","who","and","but","a","an","is","it","that","then","like","some","each","every","more","less","twice","once","the","if","until","when","where","why","which","with","for","to","in","on","at","by","from","nothing","all","one","two","three","yes","good","well","driven","go","come","other","another"]
## Skaldic kennings and invented compound metaphors.
const KENNING:="(?i)\\b[a-z]+-(hoard|song|road|storm|horse|feast|knot|sayer)\\b"

## A label stuck on the front of a line to announce it ("Observe:", "Mark
## this:", "Plainly:", "Hear me:"). People at a fire just say the thing.
const TAG_OPENER:="(?i)^\\W*((good|well|now|so|friends|o)[.,]\\s+)?(observe|mark|hear|consider|note|behold|listen|know|understand|watch|attend|remember|picture|weigh|write this down|trust me|plainly|honestly|briefly|frankly|bluntly|calmly|simply|to be brief|to wit|in short|short answer|straight talk|cold truth|true thing first|put it this way|here'?s how i see it|let'?s be fair|between us|i ask you|i tell you|let it be known|let there be no doubt)\\b[^:.!?\"]{0,30}:(\\s+|$)"

static var _res:Dictionary={}

static func _re(key:String,pattern:String)->RegEx:
	if not _res.has(key):
		var r:=RegEx.new()
		r.compile(pattern)
		_res[key]=r
	return _res[key]

static func _third(v:String)->String:
	if v.ends_with("y") and not v.ends_with("ey") and not v.ends_with("ay"): return v.substr(0,v.length()-1)+"ies"
	if v.ends_with("s") or v.ends_with("sh") or v.ends_with("ch") or v.ends_with("x") or v.ends_with("o"): return v+"es"
	return v+"s"

static var _verbs_s_text:=""
static var _verbs_base_text:=""

static func _verbs_s()->String:
	if _verbs_s_text.is_empty():
		var forms:PackedStringArray=PackedStringArray()
		for v in VERB_BASE: forms.append(_third(String(v)))
		_verbs_s_text="|".join(forms)+"|is|does(n't| not)|never \\w+s|always \\w+s|don't|dinnae|cannae|willnae"
	return _verbs_s_text

static func _verbs_base()->String:
	if _verbs_base_text.is_empty():
		_verbs_base_text="|".join(PackedStringArray(VERB_BASE))+"|do(n't| not)|never \\w+|always \\w+|cannae|dinnae|willnae"
	return _verbs_base_text

## Pattern rules applied to one clause (already stripped of vocatives and
## seasoning tokens). Each returns the rule's name when it fires.
static func clause_reason(raw_clause:String)->String:
	var c:=_normalize_clause(raw_clause)
	if c.is_empty(): return ""
	if _re("kenning",KENNING).search(c)!=null: return "kenning"
	var concrete:=_concrete(c)
	# "X is best counted twice", "better left unsaid": a prescription with no one in it.
	if not concrete and _re("best","(?i)\\b(is|are|'s)\\s+(best|better|safest|wisest|worst)\\s+[a-z]+(ed|en|t|wn|ne)\\b").search(c)!=null:
		return "best_done"
	# "Yielding plants today plants a hungry hand tomorrow": a today/tomorrow antithesis.
	if _re("today_tomorrow","(?i)\\btoday\\b.*\\btomorrow\\b").search(c)!=null and _re("person",PERSON).search(c)==null and not _has_token(c):
		return "antithesis"
	if concrete: return ""
	var progressive:=_re("progressive","(?i)\\b(is|are)\\s+\\w+ing\\b").search(c)!=null
	# "A full store is a quiet camp", "a gift-bearer made trail-leader is a costly knot".
	if not progressive and _re("equation","(?i)^(but |and |yet |so )?(a|an|every|each|no)\\s+([\\w'-]+\\s+){0,4}?(is|are|makes?)\\s+(a|an|the|no)\\s+([\\w'-]+\\s*){1,4}$").search(c)!=null:
		return "equation"
	# "Cheap rope, short trip." "Warm words, cold spears." "Honey on the lip, nettle in the sleeve."
	var pair:=_re("parallel","(?i)^([\\w'-]+(?:\\s+[\\w'-]+){1,3}),\\s+([\\w'-]+(?:\\s+[\\w'-]+){1,3})$").search(c)
	if pair!=null:
		var a:=pair.get_string(1).split(" ",false)
		var b:=pair.get_string(2).split(" ",false)
		if a.size()==b.size() and not String(a[0]).to_lower() in PARALLEL_STOP and not String(b[0]).to_lower() in PARALLEL_STOP and _re("parallel_verb","(?i)\\b(is|are|was|were|am|be|been|has|have|had|"+_verbs_s()+")\\b").search(c)==null:
			return "parallel"
	# "Every edge is honest once it's struck", "Never trust a goat...", "An agreement is only as good as..."
	if not progressive and _re("generic_open",GENERIC_OPEN).search(c)!=null and _re("generic_verb","(?i)^(but |and |yet |so )?(a|an|every|whoever|anyone who|he who|she who|those who|one who|the one who|the \\w+ (that|who|which))\\s+([\\w'-]+\\s+){0,3}?(only |always |never |rarely |seldom )?("+_verbs_s()+"|are)\\b").search(c)!=null:
		return "generic_truth"
	# "Gift-food fills bellies", "twenty meals buy a long border-song", "a fox leaves tracks",
	# "The wind does not argue", "Mud remembers every foot", "Tired hands break tools".
	var image:=_re("folk_image","(?i)^(?:but |and |yet |so )?(the |a |an )?(?:[\\w'-]+\\s+){0,2}?("+IMAGE_NOUNS+"|[a-z]+-[a-z]+)\\s+([\\w'-]+(?:\\s+[\\w'-]+)?)").search(c)
	if image!=null and not progressive:
		var article:=image.get_string(1).strip_edges().to_lower()
		var noun:=image.get_string(2).to_lower()
		var named:="-" in image.get_string(2) and image.get_string(2)!=noun   # "Early-Riser" is a name
		var rest:=image.get_string(3).to_lower()
		var plural:=noun.ends_with("s") or noun in ["geese","oxen","men","folk","people","deer","fish"]
		var verb_re:=_re("vs_"+str(plural),"(?i)^("+(_verbs_base() if plural else _verbs_s())+")\\b")
		# "The stores are low" is our stores, today; only a beast or the weather
		# given a will ("the wind does not argue") is a folk image with "the".
		if verb_re.search(rest)!=null and not rest.begins_with("is ") and rest!="is" and (article!="the" or (noun in NATURE_NOUNS and _re("personify",PERSONIFY).search(rest)!=null)) and not named: return "folk_image"
	# "Anger is a poor servant", "Fear is a thin rope to lead by".
	if _re("abstract_equation","(?i)^(anger|fear|pride|hunger|grief|haste|patience|silence|greed|hope|trust|doubt|courage|glory|valour|honour|wisdom)\\s+(is|makes?)\\s+(a|an|the|not|no|only|never|so)\\b").search(c)!=null: return "equation"
	# "Never trust a thin cook": a commandment to nobody in particular.
	if raw_clause.strip_edges().begins_with("Never ") and not raw_clause.strip_edges().begins_with("Never mind"): return "generic_truth"
	return ""

static func _has_token(c:String)->bool:
	return _re("token","(?i)(\\{[a-z_]+\\}|%[sd]|%\\.\\d?f)").search(c)!=null or _re("digits","\\d").search(c)!=null

## True when a clause names something real: a number, a {token} for a live
## value, a capitalized name mid-clause, or a speaker/listener/moment.
static func _concrete(c:String)->bool:
	if _has_token(c): return true
	if _re("stance",STANCE).search(c)!=null: return true
	# A proper name after the first word ("... than Elarin's hunters").
	var words:=c.split(" ",false)
	for i in range(1,words.size()):
		var w:=String(words[i]).strip_edges().trim_prefix("\"").trim_prefix("'").trim_prefix("(")
		if w.length()>=3 and w[0]==w[0].to_upper() and w[0]!=w[0].to_lower() and w.substr(1)==w.substr(1).to_lower(): return true
	return false

static func _normalize_clause(clause:String)->String:
	var c:=_re("seasoning",SEASONING_TOKENS).sub(clause,"",true)
	c=c.strip_edges()
	# Leading interjections and vocatives: "Och,", "Hm.", "Feast-Giver,", "Great One,", "my chief,".
	for i in 4:
		var before:=c
		c=_re("interject","(?i)^(och|aye|well|now|now then|hm+|hrm|so|ha|ho-ho|oh|ah|look|listen|hark|mark me|mark this|plainly|verily|strictly speaking|consider|remember this|observe|here's how i see it|put it this way|good|prudent|that'll do)[,.!:]?\\s+").sub(c,"")
		c=_re("vocative","^((O|My|my|o)\\s+)?([A-Z][\\w'-]*)(\\s+[A-Z][\\w'-]*){0,2},\\s+").sub(c,"")
		c=_re("vocative_low","(?i)^(my|ma|o)\\s+[\\w'-]+(\\s+[\\w'-]+)?,\\s+").sub(c,"")
		c=c.strip_edges().trim_prefix(",").strip_edges()
		if c==before: break
	c=c.strip_edges().trim_suffix(".").trim_suffix("!").trim_suffix("?").trim_suffix(";").trim_suffix(",").strip_edges()
	c=c.trim_prefix("\"").trim_suffix("\"").trim_prefix("'").trim_suffix("'").strip_edges()
	return c

## Splits text into sentences (kept with their end punctuation).
static func sentences(text:String)->PackedStringArray:
	var out:PackedStringArray=PackedStringArray()
	var t:=text.strip_edges()
	var start:=0
	var i:=0
	while i<t.length():
		var ch:=t[i]
		if ch in ".!?" and (i+1>=t.length() or t[i+1]==" "):
			var s:=t.substr(start,i-start+1).strip_edges()
			if not s.is_empty(): out.append(s)
			start=i+1
		i+=1
	var tail:=t.substr(start).strip_edges()
	if not tail.is_empty(): out.append(tail)
	return out

## Splits one sentence into clauses at ; : — and at ", but" / ", yet".
static func clauses(sentence:String)->PackedStringArray:
	var t:=sentence
	for sep in [";",":",", but ",", yet ",", and ",", so "]:
		t=t.replace(sep,"|")
	var out:PackedStringArray=PackedStringArray()
	for part in t.split("|",false):
		var p:=String(part).strip_edges()
		if not p.is_empty(): out.append(p)
	return out

## Why a sentence reads as an invented maxim, or "" when it is plain speech.
static func sentence_reason(sentence:String,line:String="")->String:
	var r:=_sentence_reason(sentence)
	# "Every hearth gives a share of every hunt. I will collect it myself": a
	# plan someone is making, not a saying, when the line has a speaker or a will.
	if r=="generic_truth" and not line.is_empty() and _re("generic_copula","(?i)^(but |and |yet |so )?(a|an|every|whoever)\\s+([\\w'-]+\\s+){0,3}?(only )?(is|are)\\b").search(_normalize_clause(sentence))==null and (_re("person",PERSON).search(line)!=null or _re("will","(?i)\\bwill\\b").search(line)!=null):
		return ""
	return r

static func _sentence_reason(sentence:String)->String:
	var whole:=clause_reason(sentence)
	if not whole.is_empty(): return whole
	for c in clauses(sentence):
		var r:=clause_reason(c)
		if not r.is_empty(): return r
	return ""

## Every flagged sentence of a line: [{"sentence","reason"}].
static func flags(text:String)->Array:
	var out:Array=[]
	var tag:=tag_opener(text)
	if not tag.is_empty(): out.append({"sentence":tag,"reason":"tag_opener"})
	for s in sentences(text):
		var r:=sentence_reason(s,text)
		if not r.is_empty(): out.append({"sentence":s,"reason":r})
	return out

static func is_maxim(text:String)->bool:
	for s in sentences(text):
		if not sentence_reason(s,text).is_empty(): return true
	return false

## The line with every aphoristic sentence (or aphoristic clause of an
## otherwise plain sentence) removed. Returns "" when nothing of substance is
## left, so the caller drops the line or falls back to an offline one.
static func strip(text:String)->String:
	text=strip_tag_opener(text)
	var kept:PackedStringArray=PackedStringArray()
	for s in sentences(text):
		if sentence_reason(s,text).is_empty():
			kept.append(s)
			continue
		# Keep the plain clauses of a mixed sentence ("Twenty meals; Elarin will
		# call it theft") when they still say something on their own.
		var parts:PackedStringArray=PackedStringArray()
		for c in clauses(s):
			if clause_reason(c).is_empty() and _normalize_clause(c).split(" ",false).size()>=4: parts.append(_normalize_clause(c))
		if not parts.is_empty():
			var joined:="; ".join(parts)
			joined=joined.substr(0,1).to_upper()+joined.substr(1)
			if not joined.ends_with(".") and not joined.ends_with("!") and not joined.ends_with("?"): joined+="."
			kept.append(joined)
	var out:=" ".join(kept).strip_edges()
	if out.split(" ",false).size()<3: return ""
	return out

## The announcing label at the start of a line ("Observe:"), or "".
static func tag_opener(text:String)->String:
	var m:=_re("tag_opener",TAG_OPENER).search(text)
	return m.get_string().strip_edges() if m!=null else ""

## The line without its announcing label, first letter raised.
static func strip_tag_opener(text:String)->String:
	var m:=_re("tag_opener",TAG_OPENER).search(text)
	if m==null: return text
	var rest:=text.substr(m.get_end()).strip_edges()
	if rest.is_empty(): return ""
	return rest.substr(0,1).to_upper()+rest.substr(1)

## Share of lines flagged, for reports: {"lines","flagged","share","examples"}.
static func survey(lines:Array,keep_examples:int=12)->Dictionary:
	var flagged:=0
	var examples:Array=[]
	for line in lines:
		var f:=flags(String(line))
		if f.is_empty(): continue
		flagged+=1
		if examples.size()<keep_examples: examples.append({"line":String(line),"why":String((f[0] as Dictionary).reason)})
	return {"lines":lines.size(),"flagged":flagged,"share":(float(flagged)/float(lines.size())) if not lines.is_empty() else 0.0,"examples":examples}

## Prompt text shared by every live voice.
const PROMPT_RULES:="""Plain speech: people say concrete things about the situation in front of them: who, what, how much, what it costs, what they want the god to do and why. Character shows through word choice, rhythm and temper, never through sayings. Never invent maxims, proverbs, aphorisms or riddles: no "X is best Y", no "a Z is a W", no "N fills bellies, but a fox leaves tracks", no kennings or poetic compounds (word-hoard, border-song, trail-leader). At most one short, natural, era-true idiom per speaker in a whole scene, and usually none. Use the real names, places, amounts and strings given.
Bad: "Feast-Giver, a free bundle is best counted twice: it asks no carrying, no return, and feeds many hearths!" Good: "Great One, it's forty hides and they want nothing back. I'd take it."
Bad: "Gift-food fills bellies, but a fox leaves tracks." Good: "The meat is welcome, but Elarin will expect our hunters at their fire next spring."
Bad: "Their word-hoard will call it theft; twenty meals buy a long border-song." Good: "Elarin will call this theft. Twenty meals isn't worth a feud on the border."
"""

## Court members speak only when they add something the ruler cannot see.
const PROMPT_ASIDE_RULES:="""Other court members stay silent by default. At most ONE of them may add ONE line, and only if it carries real guidance the ruler does not already see: a hidden string, a tell or risk, a fact about these people, a serious objection with concrete stakes, an answer to a question put to them, or their own life or kin being affected. Never a line that praises, repeats or comments on the order, the gift or the choice. If nobody has such guidance, only the addressed person speaks."""

## For a live reply that must not come back empty: the maxims go, and when
## nothing but maxims was said the reply stands as it was (a regenerate would
## double the cost of the exchange).
static func strip_or_keep(text:String)->String:
	var plain:=strip(text)
	return plain if not plain.is_empty() else text

## One line for the other live prompts (leaders, envoys, generals).
const PROMPT_SHORT:="Speak plainly and concretely about the actual situation (who, what, how much, what it costs, what you want and why); character shows in word choice and temper. Never invent maxims, proverbs, aphorisms, riddles or kennings (no 'X is best Y', 'a Z is a W', 'N fills bellies, but a fox leaves tracks'); a real idiom at most rarely."
