extends RefCounted
## HOME ORDERS WITH REAL MECHANICS (docs/ADJUDICATION.md: every order, the
## same path; never say an order is carried out unless a mechanic did it).
##
## An order about our own people at home that a real system carries out goes
## to that system, never into a vague standing directive:
##   recruit  "Recruit 20 more warriors", "Raise thirty new fighters", "Call up
##            fifteen more men to fight": MilitaryCampaign.raise_recruits(n).
##            Real adults leave their work; they wait for weapons and drill.
##            Only as many as there are free adults can be called up.
##   arm      "make the weapons we need for the soldiers I requisitioned",
##            "Make twenty spears", "Arm the recruits": the workshops' queue
##            (MilitaryCampaign.queue_equipment_production); the materials are
##            set aside now. With no number, enough for the recruits waiting.
##   found_towns  "Stop founding new towns", "don't found any more towns
##            without my word", "found new towns as you see fit", "our
##            leaders may settle new land again": the leaders' leave to found
##            new towns on their own (auto_founding.gd), the same switch as the
##            Settlement dock's. One town asked for ("found a town by the
##            river") is not their leave.
## Words about a foreign town or its people ("conscript the men of Tsaren",
## "take their weapons") are the war leader's business, never these.
##
## read(text) -> {kind:"recruit"|"arm"|"found_towns", count, item?,
##   for_recruits?, allow?} or {}.
## perform(reading) -> {ok, says, outcome, kind, count, ...}: says is the
##   official's own plain answer, outcome the narration; ok=false when nothing
##   could be set in motion (and says what stands in the way).
## Static helpers; preload.

const DEFAULT_RECRUITS:=10

## "Muster" and "call out" gather the fighters we have (the war leader's);
## these call up new ones.
const RECRUIT_VERBS:="(?i)\\b(recruit|enlist|draft|conscript|levy|call up|raise)\\b"
## A march or a strike is the war leader's, even with fighters named.
const WAR_WORDS:="(?i)\\b(attack|march|strike|raid|besiege|storm|assault|invade|conquer|burn|fight them|go to war|war on|against)\\b"
const FIGHTER_NOUNS:="(?i)\\b(warriors?|fighters?|soldiers?|spearmen|bowmen|archers|recruits?|levies|troops|men (to|who can|who will|for the) (fight|war|band|spears?)|fighting men|more men|able men|young men|new men|a war ?band|a band|a host|an army)\\b"
const MAKE_VERBS:="(?i)\\b(make|craft|forge|fashion|produce|prepare|shape|knap|carve|build|fit out|arm|equip|outfit)\\b"
const WEAPON_NOUNS:="(?i)\\b(weapons?|arms|spears?|bows?|clubs?|axes?|shields?|swords?|lances?|gear|equipment|kit)\\b"
## Theirs, not ours: occupation measures and captives belong to the war leader.
const THEIRS:="(?i)\\b(their|theirs|captives?|prisoners?|bondservants?|enemy|enemies)\\b"

const ITEM_WORDS:=[["spear","\\bspears?\\b"],["bow","\\b(bows?|archers?|bowmen)\\b"],["improvised","\\b(clubs?|staves|staffs?|cudgels?|sticks?)\\b"],["sword_shield","\\b(swords?|shields?)\\b"],["lance","\\blances?\\b"]]
const ITEM_NAMES:={"improvised":"clubs and sharpened staves","spear":"spears","bow":"bows","sword_shield":"swords and shields","lance":"lances"}
## What a recruit is armed with, best first, when the words name no weapon.
const FIRST_WEAPONS:=["spear","improvised"]

## New towns, the leaders' leave to found them (see found_reading).
const PLACE_NOUNS:="(?:towns?|cities|city|villages?|settlements?|hamlets?|colony|colonies)"
const ONE_PLACE:=["town","city","village","settlement","hamlet","colony"]
## Founding a place: "found new towns", "the founding of new villages",
## "don't found any more towns"; a plainer verb needs the place to be new:
## "build new towns", "start more villages" (never "make our towns stronger").
const FOUND_PLACES:="(?i)\\b(?:found|founding|founds|colonise|colonising|colonize|colonizing)\\s+(?:(?:any|some|more|new|other|further|fresh|another|a|an|no|the|our|of)\\s+){0,3}"+PLACE_NOUNS+"\\b|\\b(?:build|building|start|starting|raise|raising|make|making|plant|planting|settle|settling)\\s+(?:(?:any|a|an|no|some)\\s+)?(?:(?:more|new|other|further|fresh|another)\\s+){1,2}"+PLACE_NOUNS+"\\b"
## Settling new land: "settle new land", "found new homes".
const FOUND_LAND:="(?i)\\b(?:found|founding|founds|settle|settling|settles|colonise|colonising|colonize|colonizing)\\s+(?:(?:any|some|more|the|our|of)\\s+){0,2}(?:new|fresh|other|further|free|empty|open|unclaimed|good)\\s+(?:land|lands|ground|homes|hearths|places)\\b"
## Settlers sent out (only with words that stop or allow it: "send settlers
## to the river" is one party, not the leaders' leave).
const SEND_SETTLERS:="(?i)\\bsend(?:s|ing)?\\s+(?:(?:out|off|away|any|more|new|our|the)\\s+){0,3}settlers\\b|\\bsettlers\\s+(?:out|away)\\b"
## "No more new towns", "new towns only when I order it": said without a verb.
const NEW_PLACES:="(?i)\\bnew\\s+(?:towns|cities|villages|settlements|colonies)\\b"
## "found" that is the finding of something ("the scout who found new land").
const FINDING:="(?i)\\b(who|that|which|had|have|has|we|they|i|he|she|it|scouts?|hunters?|someone|somebody|nobody|everyone)\\s+found\\b"
## Words that hold the leaders back: nothing is founded without the god's word.
const FOUND_STOP:="(?i)\\b(stop|stops|stopping|halt|cease|quit|no more|no longer|don'?t|do not|dont|never|not|no new|nobody|no one|forbid|forbidden|ban|banned|mustn'?t|must not|shall not|may not|cannot|can'?t|hold off|leave (?:it |that |them |this |the founding |new towns )?to me|i (?:will|shall|alone|myself) (?:decide|choose|say)|i decide|wait (?:for|on) my|until i|unless i|except (?:when|if|on|by) (?:i|my)|only (?:when|if|on|at|by|after|once|with) (?:i|my|me)|without my (?:word|leave|order|orders|say|permission|command|consent))\\b"
## ...unless they say the god's word is no longer needed.
const FOUND_FREE:="(?i)\\b(?:(?:no longer|don'?t|do not|dont|needn'?t|need not|never) (?:need|wait for|wait on|ask for|ask|require|have to (?:ask|wait))|without (?:asking|waiting|needing)|(?:don'?t|do not|never) stop)\\b"
## Leave given in so many words (one town or one party asked for is not it).
const FOUND_LEAVE:="(?i)\\b(?:may|can|free to|as you see fit|as they see fit|whenever|again|on (?:your|their) own|yourselves|themselves|let (?:them|the|our|my)|leave (?:it|that|this) to (?:the|our|you)|allow|permit|resume|keep|continue|go on|carry on|you decide|they decide|leaders decide)\\b"
## A question about it is talk ("why did our leaders found new towns").
const QUESTION_LEADS:="(?i)^\\s*(?:what|why|how|who|whom|where|when|whose|which)\\b"
## A march or a strike beside it is the war leader's.
const FOUND_WAR:="(?i)\\b(attack|march|strike|raid|besiege|storm|assault|invade|conquer|go to war|war on)\\b"

const UNITS:={"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"thirteen":13,"fourteen":14,"fifteen":15,"sixteen":16,"seventeen":17,"eighteen":18,"nineteen":19}
const TENS:={"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"seventy":70,"eighty":80,"ninety":90}

static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile(pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

## The first number said: digits, or words ("thirty", "twenty-five", "a
## dozen", "a score", "a hundred"). 0 when none.
static func number_in(text:String)->int:
	var lower:=text.to_lower()
	var d:=_re("\\b(\\d{1,5})\\b").search(lower)
	if d!=null: return int(d.get_string(1))
	var m:=_re("\\b(twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(?:[ -](one|two|three|four|five|six|seven|eight|nine))?\\b").search(lower)
	if m!=null: return int(TENS[m.get_string(1)])+(int(UNITS.get(m.get_string(2),0)) if m.get_string(2)!="" else 0)
	var u:=_re("\\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen)\\b").search(lower)
	if u!=null: return int(UNITS[u.get_string(1)])
	if _has(lower,"\\b(a )?dozen\\b"): return 12
	if _has(lower,"\\ba score\\b"): return 20
	if _has(lower,"\\b(a )?hundred\\b"): return 100
	return 0

## Words about a foreign town or people named by name.
static func _names_foreign(lower:String)->bool:
	var WarOrders:=preload("res://scripts/court_war_orders.gd")
	var names:Array[String]=[]
	if WorldSimulation.military!=null and WorldSimulation.world!=null:
		for t:Dictionary in WarOrders.held_towns(): names.append(String(t.name))
		for t:Dictionary in WarOrders.known_places(): names.append(String(t.name).trim_prefix("Reported home of "))
	if WorldSimulation.world!=null:
		for c in WorldSimulation.world.civilizations:
			if c is Dictionary and String((c as Dictionary).get("id",""))!="player": names.append(String((c as Dictionary).get("name","")))
	for n in names:
		if n.length()>=3 and WarOrders._name_hit(lower,n): return true
	return false

## The leaders' leave to found new towns (auto_founding.gd): {kind:
## "found_towns", allow} when the words give it or take it back, else {}.
## Not a question, a march, a foreign town named, one town asked for ("found a
## new town by the river") or one party sent ("send settlers to the ford").
static func found_reading(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?") or _has(clean,QUESTION_LEADS): return {}
	# "The scout who found new land" came upon it; nobody founded anything.
	var lower:=_re(FINDING).sub(clean.to_lower(),"$1 came upon",true)
	if _has(lower,FOUND_WAR) or _names_foreign(lower): return {}
	var stop:=_has(lower,FOUND_STOP) and not _has(lower,FOUND_FREE)
	var leave:=_has(lower,FOUND_LEAVE) or _has(lower,FOUND_FREE)
	var place:=_re(FOUND_PLACES).search(lower)
	if place!=null:
		var said:=place.get_string().split(" ",false)
		if not stop and not leave and String(said[said.size()-1]) in ONE_PLACE: return {}
	elif not _has(lower,FOUND_LAND):
		# Settlers sent out, or new towns named without a verb: only with
		# words that stop or allow it.
		if not (_has(lower,SEND_SETTLERS) or _has(lower,NEW_PLACES)) or not (stop or leave): return {}
	return {"kind":"found_towns","allow":not stop}

static func read(text:String)->Dictionary:
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	if clean.is_empty() or clean.ends_with("?"): return {}
	# The god's word on new towns comes first: "at their own judgment" is not
	# someone else's people, and "against my word" is no war.
	var founding:=found_reading(clean)
	if not founding.is_empty(): return founding
	if _has(lower,THEIRS) or _has(lower,WAR_WORDS) or _names_foreign(lower): return {}
	# Weapons for our fighters: "make the weapons we need", "arm the recruits".
	var make:=_re(MAKE_VERBS).search(lower)
	var weapon:=_re(WEAPON_NOUNS).search(lower)
	var arming:=_has(lower,"\\b(arm|equip|outfit|fit out)\\b") and _has(lower,FIGHTER_NOUNS+"|\\b(them|the men|our men|new men)\\b")
	if (make!=null and weapon!=null and weapon.get_start()>make.get_start()) or arming:
		var item:=""
		for pair in ITEM_WORDS:
			if _has(lower,String(pair[1])): item=String(pair[0]); break
		return {"kind":"arm","count":number_in(lower),"item":item,"for_recruits":arming or _has(lower,FIGHTER_NOUNS+"|\\b(requisitioned|called up|conscripted|drafted|raised)\\b")}
	# Fighters called up from our own people.
	var verb:=_re(RECRUIT_VERBS).search(lower)
	if verb==null: return {}
	var noun:=_has(lower,FIGHTER_NOUNS)
	var n:=number_in(lower)
	var word:=verb.get_string(1)
	# "Recruit 20", "draft thirty": the verb alone is enough; "raise", "call
	# up", "gather" need fighters named ("raise the wall", "gather the hunters").
	if word in ["recruit","enlist","draft"] or (word in ["conscript","levy"] and (noun or n>0)) or noun:
		if word=="raise" and (_has(lower,"\\braise [\\w' ]{0,30}?up\\b") or _has(lower,"\\b(spirits?|morale|hopes?|hearts?|pay|wages?|rations?|banners?|standards?|voices?|the alarm)\\b")): return {}
		return {"kind":"recruit","count":n}
	return {}

# --------------------------------------------------------------------------
# Carrying them out
# --------------------------------------------------------------------------

static func perform(reading:Dictionary)->Dictionary:
	match String(reading.get("kind","")):
		"recruit": return _recruit(reading)
		"arm": return _arm(reading)
		"found_towns": return preload("res://scripts/auto_founding.gd").court_order(bool(reading.get("allow",true)))
	return {"ok":false,"kind":"","says":"","outcome":""}

static func _recruit(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return {"ok":false,"kind":"recruit","says":"","outcome":""}
	var asked:=int(reading.get("count",0))
	var named:=asked>0
	var n:=asked if named else DEFAULT_RECRUITS
	var r:Dictionary=mc.raise_recruits(n)
	var raised:=int(r.get("raised",0))
	var waiting:=int(r.get("recruit_reserve",mc.aggregate_recruits))
	var out:={"ok":raised>0,"kind":"recruit","count":raised,"asked":n,"waiting":waiting}
	if raised<=0:
		out.says="There is nobody left to call up: every able adult is already under arms or away."
		out.outcome="Nothing is set in motion: no free adults remain to be called up."
		return out
	var short:=(" Only %d could be found; there are no more free adults." % raised) if raised<n else ""
	var unnamed:=" You named no number, so I called up %d." % raised if not named else ""
	out.says="%d are called up and leave their work in the fields and workshops.%s%s %d now wait for weapons and drill." % [raised,short,unnamed,waiting]
	out.outcome="%d called up from our own people; %d recruits now wait for weapons and drill, and that much less work is done at home." % [raised,waiting]
	return out

## What the recruits waiting need, less what is in store.
static func _needed(mc:Variant,item:String)->int:
	return maxi(0,int(mc.aggregate_recruits)-int((mc.military_inventory as Dictionary).get(item,0)))

static func _arm(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return {"ok":false,"kind":"arm","says":"","outcome":""}
	var asked:=int(reading.get("count",0))
	var items:Array=[String(reading.item)] if String(reading.get("item",""))!="" else FIRST_WEAPONS.duplicate()
	var problem:=""
	for item:String in items:
		var n:=asked if asked>0 else _needed(mc,item)
		if n<=0:
			var stock:=int((mc.military_inventory as Dictionary).get(item,0))
			return {"ok":true,"kind":"arm","count":0,"item":item,"says":"We have what they need: %d %s in store for the %d recruits waiting. Nothing more has to be made." % [stock,String(ITEM_NAMES.get(item,item)),int(mc.aggregate_recruits)],
				"outcome":"Nothing more is set to be made: the %s in store are enough." % String(ITEM_NAMES.get(item,item))}
		var queued:Dictionary=mc.queue_equipment_production(item,n)
		if queued.has("error"):
			if problem=="": problem=String(queued.error)
			continue
		var days:=float(queued.get("work_days",0.0))
		var names:=String(ITEM_NAMES.get(item,item))
		var materials:PackedStringArray=PackedStringArray()
		var recipe:Dictionary=mc._equipment_recipe(item)
		for m in (recipe.get("materials",{}) as Dictionary):
			materials.append("%d %s" % [ceili(float(recipe.materials[m])*n),String(m)])
		var for_whom:=" for the %d recruits waiting" % int(mc.aggregate_recruits) if asked<=0 and bool(reading.get("for_recruits",true)) else ""
		var experimental:=" We have not made these before, so it goes slowly." if bool(queued.get("experimental",false)) else ""
		return {"ok":true,"kind":"arm","count":int(queued.get("queued",n)),"item":item,
			"says":"The workshops are set to make %d %s%s: about %d days of work, and %s are set aside for it now.%s" % [int(queued.get("queued",n)),names,for_whom,ceili(days),", ".join(materials) if not materials.is_empty() else "nothing",experimental],
			"outcome":"%d %s put in hand in the workshops, about %d workshop-days; the materials are taken from the stores now." % [int(queued.get("queued",n)),names,ceili(days)]}
	return {"ok":false,"kind":"arm","count":0,"says":"The workshops cannot take it: %s" % problem,"outcome":"Nothing is set in motion: %s" % problem}
