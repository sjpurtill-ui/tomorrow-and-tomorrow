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
## Words about a foreign town or its people ("conscript the men of Tsaren",
## "take their weapons") are the war leader's business, never these.
##
## read(text) -> {kind:"recruit"|"arm", count, item?, for_recruits?} or {}.
## perform(reading) -> {ok, says, outcome, kind, count, ...}: says is the
##   official's own plain answer, outcome the narration; ok=false when nothing
##   could be set in motion (and says what stands in the way).
## Static helpers; preload.

const DEFAULT_RECRUITS:=10

const RECRUIT_VERBS:="(?i)\\b(recruit|enlist|draft|conscript|levy|call up|call out|muster|raise)\\b"
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

static func read(text:String)->Dictionary:
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	if clean.is_empty() or clean.ends_with("?"): return {}
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
		if word=="raise" and _has(lower,"\\braise [\\w' ]{0,30}?up\\b"): return {}
		return {"kind":"recruit","count":n}
	return {}

# --------------------------------------------------------------------------
# Carrying them out
# --------------------------------------------------------------------------

static func perform(reading:Dictionary)->Dictionary:
	match String(reading.get("kind","")):
		"recruit": return _recruit(reading)
		"arm": return _arm(reading)
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
