extends RefCounted
## Court members are silent by default. In an envoy audience, a court scene or
## after an order, a member speaks only when they add real guidance the ruler
## cannot already see on screen:
##   - information the ruler lacks (a hidden string, a tell, a risk, a fact
##     about the other people),
##   - a serious objection with concrete stakes,
##   - an answer to a question put to them,
##   - their own life or kin being affected.
## Every candidate aside is scored deterministically from game state; only the
## best one, and only if it clears THRESHOLD, is spoken: at most one per
## exchange. Lines that praise, restate the obvious or comment on the order are
## dropped. Option-card voices ("Objects" / "For it") pass the same test.
##
## Nothing here calls a model: the live voice folds the one chosen member into
## the exchange's single request (see audience_voice.gd), or uses the offline
## line.

const Plain:=preload("res://scripts/plain_speech.gd")

const THRESHOLD:=0.5
## What kind of contribution a candidate is, and what it is worth by itself.
const BASE:={
	"direct_question":1.0,   # the ruler named or asked them
	"hidden_info":0.9,       # a string, tell or fact not on screen
	"own_kin":0.8,           # their own life or kin at stake
	"objection":0.65,        # against an answer, with a reason
	"dissent":0.55,          # a witness who resents what the god did (a risk)
	"report":0.5,            # their office's own finding
	"support":0.4,           # for an answer
	"interject":0.1, "react":0.1, "aside":0.1, "closing_aside":0.05, "witness":0.1, "bicker":0.0, "praise":0.0,
}
const PRAISE:="(?i)\\b(wise|wisely|splendid|magnificent|glorious|marvellous|marvelous|well said|how true|of course|as you say|as ever|brilliant|perfect|so wise|excellent|masterful|just so|quite right|indeed)\\b"
const CONCRETE:="(?i)(\\d|\\b(days?|months?|winters?|seasons?|hunters?|spears?|food|meat|hides?|clay|stone|wood|stores?|pits?|border|valley|river|ridge|ford|kin|sister|brother|son|daughter|mother|father|wife|husband|child|children|owe|owed|debt|back|return|next|within)\\b)"

## Score one candidate: {"kind","text","person_id"} plus optional
## "on_screen" (true when the same point is already shown, e.g. on a card).
## seen: text already visible to the ruler (facts, cards, lines so far).
static func score(candidate:Dictionary,seen:String="")->float:
	var kind:=String(candidate.get("kind","aside"))
	var text:=String(candidate.get("text","")).strip_edges()
	if text.is_empty(): return 0.0
	var value:=float(BASE.get(kind,0.1))
	if RegEx.create_from_string(CONCRETE).search(text)!=null: value+=0.15
	if Plain.is_maxim(text): value-=0.5
	if RegEx.create_from_string(PRAISE).search(text)!=null and kind!="direct_question": value-=0.4
	if bool(candidate.get("on_screen",false)) and kind!="direct_question": value-=0.5
	elif not seen.is_empty() and restates(text,seen) and kind!="direct_question": value-=0.5
	return value

## The one candidate worth saying, or {} when nobody has real guidance.
static func pick(candidates:Array,seen:String="")->Dictionary:
	var best:={}
	var best_score:=THRESHOLD-0.0001
	for c in candidates:
		if not c is Dictionary: continue
		var v:=score(c,seen)
		if v>best_score:
			best_score=v
			best=(c as Dictionary).duplicate()
			best["score"]=v
	return best

static func clears(candidate:Dictionary,seen:String="")->bool:
	return score(candidate,seen)>=THRESHOLD

## True when most of a line's content words are already in what is seen.
static func restates(text:String,seen:String)->bool:
	var words:=_content_words(text)
	if words.size()<3: return false
	var have:=_content_words(seen)
	var lookup:={}
	for w in have: lookup[w]=true
	var hits:=0
	for w in words:
		if lookup.has(w): hits+=1
	return float(hits)/float(words.size())>=0.7

static func _content_words(text:String)->PackedStringArray:
	var out:PackedStringArray=PackedStringArray()
	var re:=RegEx.create_from_string("[A-Za-z']{4,}")
	for m in re.search_all(text.to_lower()):
		var w:=m.get_string()
		if w in ["that","this","they","them","their","with","have","will","would","your","from","what","when","were","been","into","there","then","than","just","only","like","about","over","more","some"]: continue
		out.append(w)
	return out

## True when the ruler's words name or address this member (their given name,
## a part of it, or their office).
static func addressed(player_text:String,member:Dictionary)->bool:
	var low:=" "+player_text.to_lower()+" "
	var name:=String(member.get("name","")).to_lower()
	for part in name.split(" ",false):
		var p:=String(part).strip_edges().trim_suffix(",")
		if p.length()>=3 and not p in ["the","of","who"] and RegEx.create_from_string("\\b"+p.replace("-","\\-")+"\\b").search(low)!=null: return true
	var persona:Dictionary=member.get("persona",{}) if member.get("persona") is Dictionary else {}
	var title:=String(persona.get("title","")).to_lower()
	if title.length()>=4 and title in low: return true
	return false

## Option cards: whether a "For it" / "Objects" voice adds information the
## card does not already carry. voice is the card text "Name (Office): “...”".
static func card_voice_ok(option:Dictionary,side:String)->bool:
	var said:=String(option.get(side,""))
	if said.is_empty(): return false
	var inner:=said
	var open:=said.find("“")
	if open>=0: inner=said.substr(open+1).trim_suffix("”")
	var seen:=String(option.get("label",""))+" "+String(option.get("sub",""))
	return clears({"kind":"objection" if side=="objection" else "support","text":inner},seen)
