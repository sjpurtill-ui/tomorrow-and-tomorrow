extends RefCounted
## WHAT BECOMES OF A TOWN WE HOLD.
##
## After a town is taken, the god's words about it are not a new attack.
## They are orders to the garrison that holds it, and the court is the only
## place they are given (the occupation screen now only reports). Each order
## goes through the occupation machinery that already exists, and every
## person it touches is counted in the town's one ledger (town_ledger.gd;
## docs/ADJUDICATION.md):
##   - how we rule it: civilization_system.set_occupation_policy (civil
##     administration, self-rule, equal citizenship, rule by the spear,
##     enslavement of the town), reconstruction;
##   - killing: civilization_system.occupation_resident_order kill_residents.
##     Those we hold (bound, at forced labour, serving, hostages) cannot run:
##     all of them die, and the garrison's hands set only how long it takes.
##     The free are each caught on the stated odds (catch_odds: our fighters
##     to their men, and what already holds them), one seeded roll each; the
##     rest run for their refuge (pursuit.gd offers a chase);
##   - moving people home, free or bonded, and captives:
##     military_campaign.occupation_transfers (they walk the road, eat
##     travel rations and arrive later, into their own community record);
##     each is rounded up on the stated odds; freeing captives already home:
##     occupation_transfers.emancipate;
##   - burning: the houses, stores and walls go and whoever is left free
##     scatters to their people's other towns (or the hills). The town becomes
##     our ruin, in the ledger and in the world: it is not handed back to its
##     old people. With a garrison left there it is ours to hold; when we
##     leave, nobody holds it, and whether its people come back to live in it
##     is its own event, with odds and a date (daily), told when our people
##     hear of it. Our own account of the burning (dated the day) replaces
##     any old scout report of the place;
##   - giving it back: occupation_resident_order restore_self_rule (the
##     garrison marches home);
##   - the garrison's size: military_campaign.reinforce_occupation from a band
##     standing at the town;
##   - tribute: their stores, through civilization_exchange.
##
## Every result is said with its numbers and how it was decided ("17 of ours
## against 38 bound men: none could run. All 38 were killed."). Consequences
## are real and bounded: dread and grudges reach the people who were struck
## and, more faintly, every people that knows us; our war reputation (mercy,
## fear, grievance) and our court's dread of the god move; one sober
## Chronicle entry tells it.
##
## apply() -> {ok, outcome (one plain note), text (the sober account),
##             killed, escaped, captives, moved, burned, tribute, left,
##             spared, policy, reinforced, freed, fled (the flight record)}
##             | {error}.

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Combat:=preload("res://scripts/civilization_combat.gd")
const Governance:=preload("res://scripts/occupation_governance.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

## Adult men in a farming village's population (the rest are women,
## children and the old): roughly a quarter.
const MEN_SHARE:=0.24
## The chance to catch each free man as a killing begins, with a garrison of
## about one fighter to three of their men (catch_odds moves it).
const CAUGHT_SHARE:=0.7
## Women and children in the population.
const WOMEN_CHILDREN_SHARE:=0.55
## The chance to round up each woman or child; the rest flee or hide.
const ROUNDED_UP_SHARE:=0.6
## What one fighter can do: kill the men who stand (a day's work), guard
## captives on the road.
const KILLS_PER_FIGHTER:=5
const CAPTIVES_PER_FIGHTER:=4
## Food a band carries off as tribute, per fighter.
const TRIBUTE_PER_FIGHTER:=40.0
## A ruin we burned and left: its people may come back to live in it between
## these many days after, and we hear of it some days later.
const RESETTLE_DAYS:=[60,300]
const LEARN_DAYS:=[10,60]
const RESETTLERS:=[10,60]

const POLICY_WORDS:=[
	["military_rule","\\b(military rule|rule [\\w' ]{0,20}by (the )?(spear|sword|force|fear)|by force of arms|under the spear|martial)"],
	["self_rule","\\b(govern (themselves|itself)|rule themselves|self.rule|their own elders|let them rule|keep their own (ways|elders|chief))"],
	["equal_citizenship","\\b(equal citizens|equal citizenship|make them (our own|our people|citizens|one of us)|full citizens|as equals)"],
	["stewardship","\\b(civil administration|(govern|rule) [\\w' ]{0,20}(well|fairly|justly|kindly)|as a town of ours|administer it|steward|protect (it|them|the town))"],
	["forced_labor","\\b(enslave (the |its |their )?(whole )?(town|people|them|everyone|rest|rest of them|survivors|others)|enslave everyone (else|left)|enslave all (the )?(rest|others|who are left)|make (them|the town|its people|the rest) (our )?slaves|forced labou?r|work them as slaves)"],
]
## "Enslave the women", "enslave the girls": those people taken home in
## bonds (the captives' road), as "take the women to Seanstone" is.
const ENSLAVE_GROUP:="\\benslave\\s+(all\\s+)?(of\\s+)?(the\\s+|their\\s+|its\\s+)?(young\\s+|little\\s+|older\\s+)?(women|womenfolk|wives|girls|daughters|children|boys|young ones|men|males|elders|old people|old men|old women)\\b"
## "Kill the men you have tied up": only those we hold.
const BOUND_ONLY:="\\b((that|whom|who|which)\\s+(you|we|they|your men|the garrison|our men|you've|we've)\\s+(have\\s+|had\\s+|already\\s+|just\\s+)*(tied|bound|chained|taken|captured|caught|rounded up|locked up|roped)|(the|all the|every one of the|those|these)\\s+(bound|tied|captive|chained|roped|captured)\\s+(men|ones|prisoners|males)|the prisoners|those (we|you) (hold|are holding|have tied|have bound)|(who|that) are (tied|bound|chained|held|prisoners|under guard))"

## RAPE of a town's women by the garrison, at the god's word ("let the men
## rape the women of Tsaren"). Grown women only: the ledger's girls are
## children, and no garrison of ours is set on children (the commander
## refuses that part, plainly). Early war was cruel in this way, and it
## changed peoples' numbers: the pregnancies go into the struck people's own
## count, and the children are born to them.
## The words: rape, ravish, violate, defile, let loose on, "give the women to
## the men", "let the soldiers have the women".
const VIOLATE_VERB:="\\b(rape|rapes|raped|raping|ravish\\w*|violate|violated|violating|defile|defiled|defiling|have their way with|take their pleasure (of|with)|let [\\w' ]{0,30}loose on|loose on)"
const VIOLATE_GIVEN:="\\b(give|hand)\\b[\\w' ]{0,30}\\b(women|womenfolk|wives)\\b[\\w' ]{0,16}\\b(to|for) (the|our) (men|soldiers|garrison|fighters|warriors|troops)\\b|\\blet (the|our) (men|soldiers|garrison|fighters|warriors|troops) (have|use|enjoy) (the|their|all the) (women|womenfolk|wives)\\b"
const VIOLATE_ADULTS:="\\b(women|womenfolk|wives|females?|widows|mothers)\\b"
const VIOLATE_KIDS:="\\b(girls?|daughters|children|child|boys?|maidens|young ones|little ones|kids)\\b"
## Where the words for this act end and the next order begins.
const VIOLATE_STOP:="\\b(then|and then|kill|slay|slaughter|massacre|butcher|execute|take|bring|carry|drive|lead|send|march|burn|raze|torch|spare|free|release|keep|hold|bind|enslave|loot|plunder|strip)\\b"
## How many days it goes on when the words do not say.
const VIOLATE_DAYS:=3
## Of the women raped, the share who die of it.
const VIOLATE_DEATH:=0.02
## Of the women raped and living, the share of an age to conceive and not
## already with child.
const FERTILE_SHARE:=0.6
## The chance of conceiving from one day of it: about 5 in 100, the measured
## rate for a single assault.
const CONCEIVE_PER_DAY:=0.05
## The pregnancies show after this many days, and our war leader hears of it.
const SHOWN_DAYS:=90
## Where their people's own lives are not simulated, the children are born
## this long after, this share of the pregnancies ending in a child born alive.
const BIRTH_DAYS:=270
const BORN_SHARE:=0.8

static func _re(pattern:String,text:String)->RegExMatch:
	var r:=RegEx.new(); r.compile(pattern); return r.search(text)

static func _has(pattern:String,text:String)->bool:
	return _re(pattern,text)!=null

static func fate_words(lower:String,home_name:String="")->Dictionary:
	## What the god's words decide about a town we hold. {} when nothing.
	var out:={}
	var home:=home_name.to_lower().strip_edges() if home_name!="" else String(WorldSimulation.state.settlement_name).to_lower() if WorldSimulation.state!=null else ""
	var kill:=_has("\\b(kill|kil\\b|kiil|rid [\\w' ]{0,24}of [\\w' ]{0,24}\\b(men|males|menfolk|man|people|souls?)\\b|slay|slaughter|massacre|butcher|execute|cut down|put [\\w' ]{0,24}to the sword|put [\\w' ]{0,24}to death|no quarter)",lower)
	var everyone:=_has("\\b(everyone|everybody|every soul|every one of them|all of them|them all|man, woman and child|men, women and children|women and children too|leave none|nobody alive|no one alive)\\b",lower)
	var people:=_has("\\b(women|womenfolk|females?|girls|wives|daughters|children|captives?|slaves?|bondservants?|young ones|people|residents|families|them|villagers|townsfolk|townspeople|inhabitants)\\b",lower)
	var carry:=_has("\\b(take|bring|carry|lead|drive|march|send|haul|herd|move|settle|resettle)\\b",lower)
	var homeward:=_has("\\b(home|back|with us|to our|captives?)\\b",lower) or (home!="" and home in lower)
	var bonded:=_has("\\b(women|womenfolk|females?|girls|wives|daughters|captives?|slaves?|bondservants?|bonded|as spoils)\\b",lower)
	var count_match:=_re("\\b(\\d{1,4})\\b",lower)
	if count_match!=null: out["count"]=int(count_match.get_string(1))
	if kill: out["kill_men"]=true
	if kill and everyone: out["kill_all"]=true; out["kill_all_words"]=true
	# The groups the words themselves name for the killing ("all the women"):
	# a reading's "kill everyone" never widens them (apply honours these).
	if kill and not everyone:
		var named:=named_kill_groups(lower)
		if not named.is_empty(): out["kill_named"]=named
	# Who is to be killed: "kill the women" never kills the men, and "the boys"
	# are never all the children (town_ledger's make-up of the children).
	if kill and not everyone:
		var groups:=kill_groups(lower)
		if groups!=["men"]: out["kill_groups"]=groups
		if groups.has("children"):
			var kkw:=kid_words(kill_span(lower))
			if not kkw.is_empty():
				out["kill_kids"]=kkw.bands
				out["kill_kids_words"]=String(kkw.words)
				if bool(kkw.get("aged",false)) and out.has("count") and int(out.count)==int(kkw.get("age_number",-1)): out.erase("count")
	if kill and _has(BOUND_ONLY,lower): out["bound_only"]=true
	# "Enslave the women" is the captives' road, as "take them home" is.
	if _has(ENSLAVE_GROUP,lower) and not out.has("kill_all"):
		carry=true; people=true; homeward=true; bonded=true
	if carry and people and homeward and not out.has("kill_all"):
		if _has("\\bas (our own|citizens|free|our people|equals|kin)\\b",lower) and not bonded: out["move"]="citizen"
		elif _has("\\b(penal|to labou?r|to work)\\b",lower) and not bonded: out["move"]="penal"
		else:
			out["captives"]=true
			out["take"]=take_words(lower)
			# "The girls under ten": which of the children, by band.
			var kw:=kid_words(lower)
			if not kw.is_empty():
				out["kids"]=kw.bands
				out["kids_words"]=String(kw.words)
				# A number in the words is their age, not how many to take.
				if bool(kw.get("aged",false)) and out.has("count") and int(out.count)==int(kw.get("age_number",-1)): out.erase("count")
	if _has("\\b(burn|raze|torch|set fire|to the ground|level it|flatten|tear [\\w' ]{0,12}down|destroy (it|the town|what))",lower): out["raze"]=true
	if _has("\\b(tribute|plunder|loot|sack it|take their (food|grain|stores|goods)|strip (it|the town|them|their stores))\\b",lower): out["tribute"]=true
	if _has("\\b(spare|mercy|merciful|leave them (be|in peace)|let them (be|live)|no harm|harm no one|treat them (well|kindly|gently)|be gentle)\\b",lower) and not kill: out["spare"]=true
	if _has("\\b(hold|keep|garrison|govern|rule) (it|the town|the place|them|the ruins?)\\b",lower): out["hold"]=true
	if _has("\\b(give it back|hand it back|(give|hand) [\\w' ]{1,20} back|return it|leave it|withdraw|come home|pull out|abandon|let them have it back|leave [\\w' ]{1,24}? to (its|their) (own )?(people|folk|elders|kin|chiefs?)|give (it|the town|the place|the village) up|give up (the town|the place|the village)|evacuate)\\b",lower) and not out.has("hold"): out["leave"]=true
	if _has("\\b(rebuild|repair|reconstruct|build it (up|again))\\b",lower) and not out.has("raze"): out["reconstruct"]=true
	if _has("\\b(strengthen|reinforce|more (soldiers|fighters|men|spears) (to|in|at|for)|send more|add [\\w' ]{0,12}to the garrison|bigger garrison)\\b",lower): out["reinforce"]=true
	if _has("\\b(free|release|emancipate|unbind) (the )?(captives|slaves|bonded)",lower) and not kill: out["free"]=true
	if not out.has("captives"):
		for row in POLICY_WORDS:
			if _has(String(row[1]),lower): out["policy"]=String(row[0]); break
	# Rape: the women the words name (grown women only); children named are
	# refused by the commander (_violate).
	var span:=violate_span(lower)
	if span!="":
		if _has(VIOLATE_ADULTS,span): out["violate"]=true
		if _has(VIOLATE_KIDS,span): out["violate_kids"]=true
		var long:=_re("\\b(\\d{1,2}|one|two|three|four|five|six|seven) (whole )?days?\\b",lower)
		if long!=null:
			out["violate_days"]=int(long.get_string(1)) if long.get_string(1).is_valid_int() else int(AGE_WORDS.get(long.get_string(1),VIOLATE_DAYS))
			# "For three days" is how long, never how many.
			if out.has("count") and int(out.count)==int(out.violate_days): out.erase("count")
	if out.is_empty() or (out.size()==1 and out.has("count")): return {}
	if _has(GROUP_WORDS,lower): out["group"]=true
	return out

## The words the order to rape is about: from the verb to the next order
## ("rape the women and kill the men": "the women and"); when the verb has
## no people of its own ("rape and kill the women"), the next order's. ""
## when the words give no such order.
static func violate_span(lower:String)->String:
	var given:=_re(VIOLATE_GIVEN,lower)
	if given!=null: return given.get_string()
	var m:=_re(VIOLATE_VERB,lower)
	if m==null: return ""
	var rest:=lower.substr(m.get_end())
	var stop:=_re(VIOLATE_STOP,rest)
	var span:=rest if stop==null else rest.substr(0,stop.get_start())
	if not _has(VIOLATE_ADULTS,span) and not _has(VIOLATE_KIDS,span) and stop!=null:
		var after:=rest.substr(stop.get_end())
		var stop2:=_re(VIOLATE_STOP,after)
		span=after if stop2==null else after.substr(0,stop2.get_start())
	return span if (_has(VIOLATE_ADULTS,span) or _has(VIOLATE_KIDS,span)) else ""

## The groups a killing names, from the words after the verb up to the next
## order ("kill the males and take the women" kills the men only). Default men.
const KILL_VERB:="\\b(kill|kil\\b|kiil|rid [\\w' ]{0,24}of|slay|slaughter|massacre|butcher|execute|cut down|put [\\w' ]{0,24}to the sword|put [\\w' ]{0,24}to death)"

## The words a killing falls on: from the verb up to the next order. "" when
## no killing is named. The next order starts at its own verb, with or
## without "and" or a comma: "kill all the males of tsaren take the women and
## girls to seanstone and burn tsaren" kills the men only.
const NEXT_ORDER:="\\b(then|and then|take|bring|carry|drive|lead|send|march|haul|herd|burn|raze|torch|set fire|spare|free|release|let|leave|keep|hold|bind|tie|round up|enslave|make|give|loot|plunder|sack|strip|rebuild|govern|rule)\\b"
static func kill_span(lower:String)->String:
	var m:=_re(KILL_VERB,lower)
	if m==null: return ""
	var span:=lower.substr(m.get_start())
	var cut:=span.length()
	for stop in [" and take"," and bring"," and burn"," and carry"," and drive"," and lead"," and send"," and march"," then ",",",".",";","!"]:
		var at:=span.find(stop)
		if at>0 and at<cut: cut=at
	# The next order's own verb, past the killing's words ("put ... to the
	# sword" and "cut down" are the killing itself).
	var own:=_re(KILL_VERB,span)
	var from:=own.get_end() if own!=null else 0
	var r:=RegEx.new(); r.compile(NEXT_ORDER)
	for hit in r.search_all(span,from):
		# "the men who take up arms", "those that hold the gate": inside the killing's object.
		var before:=span.substr(0,hit.get_start()).strip_edges()
		if before.ends_with(" who") or before.ends_with(" that") or before.ends_with(" which") or before.ends_with(" to"): continue
		if hit.get_start()<cut: cut=hit.get_start()
		break
	return span.substr(0,cut).strip_edges()

## The groups a killing's own words name, [] when they name none ("kill
## them", "kill everyone"): kill_groups without its default of the men.
static func named_kill_groups(lower:String)->Array:
	var m:=_re(KILL_VERB,lower)
	if m==null: return []
	var span:=kill_span(lower).replace("old men","old ones")
	if not _has("\\b(men|males|menfolk|husbands|fathers|sons|fighting men|grown men|every man|women|womenfolk|females?|wives|mothers|children|boys|girls|daughters|young ones|babies|infants|elders|old people|old ones|old women)\\b",span): return []
	return kill_groups(lower)

static func kill_groups(lower:String)->Array:
	var m:=_re(KILL_VERB,lower)
	if m==null: return ["men"]
	var span:=kill_span(lower).replace("old men","old ones")
	var out:Array=[]
	if _has("\\b(men|males|menfolk|husbands|fathers|sons|fighting men|grown men|every man)\\b",span): out.append("men")
	if _has("\\b(women|womenfolk|females?|wives|mothers)\\b",span): out.append("women")
	if _has("\\b(children|boys|girls|daughters|young ones|babies|infants)\\b",span): out.append("children")
	if _has("\\b(elders|old people|old ones|old women)\\b",span): out.append("elders")
	return out if not out.is_empty() else ["men"]

## Which people the words take: {group: share of the free}. "the women and
## girls" -> women 1, children 0.5 (the girls). Default: women and children.
static func take_words(lower:String)->Dictionary:
	var out:={}
	if _has("\\b(everyone|everybody|all of them|them all|the people|its people|their people|villagers|townsfolk|townspeople|inhabitants|residents|families)\\b",lower):
		return {"men":1.0,"women":1.0,"children":1.0,"elders":1.0}
	if _has("\\b(women|womenfolk|wives|females?|mothers)\\b",lower): out["women"]=1.0
	var girls:=_has("\\b(girls|daughters)\\b",lower)
	var boys:=_has("\\b(boys)\\b",lower)
	if _has("\\b(children|young ones|little ones|babies|infants)\\b",lower) or (girls and boys): out["children"]=1.0
	elif girls or boys: out["children"]=0.5
	if _has("\\b(elders|old people|old men|old women|old ones)\\b",lower): out["elders"]=1.0
	if _has("\\b(men|males|menfolk|husbands|fathers|sons)\\b",lower.replace("old men","old ones")) and not _has("\\b(kill|slay|put [\\w' ]{0,24}to (the sword|death))",lower): out["men"]=1.0
	if out.is_empty(): out={"women":1.0,"children":1.0}
	return out

const AGE_WORDS:={"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"thirteen":13,"fourteen":14,"fifteen":15}
const AGE_RE:="(\\d{1,2}|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen)"

static func _age(word:String)->int:
	return int(word) if word.is_valid_int() else int(AGE_WORDS.get(word,-1))

## Which of the children the words mean, by band (town_ledger KID_BANDS):
## {bands: {band: share of that band}, words: "girls under ten", aged (an
## age was named), age_number}; {} when the words mean the children as a
## whole or none of them. "girls under 10" -> girls_young 1; "boys" -> both
## boys' bands; "girls under five" -> about half the girls under ten; "the
## older girls" -> girls_older.
static func kid_words(lower:String)->Dictionary:
	var girls:=_has("\\b(girls?|daughters?)\\b",lower)
	var boys:=_has("\\b(boys?|sons)\\b",lower)
	var kids:=_has("\\b(children|child|kids?|young ones|little ones|babies|infants|toddlers)\\b",lower)
	if not girls and not boys and not kids: return {}
	var below:=Ledger.CHILD_YEARS.size()
	var from:=0
	var aged:=false
	var number:=-1
	var m:=_re("\\b(?:under|below|younger than|less than)\\s+(?:the age of\\s+|age\\s+)?"+AGE_RE+"\\b",lower)
	if m!=null and _age(m.get_string(1))>0: number=_age(m.get_string(1)); below=clampi(number,1,Ledger.CHILD_YEARS.size()); aged=true
	m=_re("\\b"+AGE_RE+"\\s+(?:and|or)\\s+(?:under|younger|below)\\b",lower)
	if m!=null and _age(m.get_string(1))>=0: number=_age(m.get_string(1)); below=clampi(number+1,1,Ledger.CHILD_YEARS.size()); aged=true
	m=_re("\\b(?:over|above|older than)\\s+(?:the age of\\s+|age\\s+)?"+AGE_RE+"\\b",lower)
	if m!=null and _age(m.get_string(1))>=0: number=_age(m.get_string(1)); from=clampi(number+1,0,Ledger.CHILD_YEARS.size()-1); aged=true
	m=_re("\\b"+AGE_RE+"\\s+(?:and|or)\\s+(?:over|older|above)\\b",lower)
	if m!=null and _age(m.get_string(1))>=0: number=_age(m.get_string(1)); from=clampi(number,0,Ledger.CHILD_YEARS.size()-1); aged=true
	if not aged:
		if _has("\\b(little|small|young|youngest)\\s+(girls?|boys?|children|ones|daughters|sons|kids)\\b|\\b(babies|infants|toddlers|little ones)\\b",lower): below=Ledger.YOUNG_AGE
		elif _has("\\b(older|oldest|grown|big)\\s+(girls?|boys?|children|daughters|sons|kids)\\b",lower): from=Ledger.YOUNG_AGE
	var all_ages:=below>=Ledger.CHILD_YEARS.size() and from<=0
	if (girls==boys) and all_ages: return {}
	var bands:={}
	for band:String in Ledger.KID_BANDS:
		if girls and not boys and band.begins_with("boys"): continue
		if boys and not girls and band.begins_with("girls"): continue
		var part:=Ledger.band_part(band,from,below)
		if part>0.0: bands[band]=snappedf(part,0.001)
	if bands.is_empty(): return {}
	var who:="girls" if girls and not boys else ("boys" if boys and not girls else "children")
	var ages:=""
	if from<=0 and below==Ledger.YOUNG_AGE: ages=" under ten"
	elif from<=0 and below<Ledger.CHILD_YEARS.size(): ages=" under %s" % _count(below)
	elif from==Ledger.YOUNG_AGE and below>=Ledger.CHILD_YEARS.size(): ages=" of ten and older"
	elif from>0 and below>=Ledger.CHILD_YEARS.size(): ages=" of %s and older" % _count(from)
	elif from>0: ages=" of %s to %s" % [_count(from),_count(below-1)]
	return {"bands":bands,"words":who+ages,"aged":aged,"age_number":number}


## Words for the people of a town as a body: the men, the women, everyone.
## An order that names no town is about a town only when it names them.
const GROUP_WORDS:="\\b(males?|men|menfolk|boys|sons|fighting men|grown men|every man|females?|women|womenfolk|girls|wives|daughters|children|everyone|everybody|every soul|all of them|them all|villagers|townsfolk|townspeople|inhabitants|residents|population|families|captives|its people|their people|the people)\\b"
## Words that point at a town without naming it.
const TOWN_REF:="\\b((the|that|this|their|our new|the captured|the taken|the conquered) (town|village|city|settlement|capital|place|stronghold)|the garrison|the captives)\\b"

static func implicit(fate:Dictionary,lower:String)->bool:
	## Is this fate order about a town we hold even though it names none?
	## Violence to, or carrying off of, the people as a body; freeing its
	## captives; or any other fate (burn, tribute, rule, give back) with words
	## pointing at the town. "Kill him" and "take them home" never are.
	if fate.is_empty(): return false
	var group:=bool(fate.get("group",false))
	if group and (bool(fate.get("kill_men",false)) or bool(fate.get("captives",false)) or String(fate.get("move",""))!="" or bool(fate.get("free",false))): return true
	return _has(TOWN_REF,lower)


static func honour_words(fate:Dictionary)->Dictionary:
	## The ruler's own words over any reading's flags: when the words name who
	## is to die ("kill all the women of Tsaren") and do not say everyone, a
	## "kill everyone" from elsewhere (a live reader's kill_all) is those
	## groups, never the whole town.
	var named:Array=fate.get("kill_named",[]) if fate.get("kill_named") is Array else []
	if not bool(fate.get("kill_all",false)) or bool(fate.get("kill_all_words",false)) or named.is_empty(): return fate
	var out:=fate.duplicate(true)
	out.erase("kill_all")
	if named!=["men"]: out["kill_groups"]=named.duplicate()
	else: out.erase("kill_groups")
	return out

static func apply(civ_id:String,region_id:String,fate_in:Dictionary,general:Dictionary={})->Dictionary:
	var fate:=honour_words(fate_in)
	var world:Variant=WorldSimulation.world
	var mc:Variant=WorldSimulation.military
	if world==null or mc==null: return {"error":"Nobody holds that town for us."}
	var index:int=world._civilization_index(civ_id)
	if index<0: return {"error":"That town's people are no longer known to us."}
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	# Who holds it: the one reading every system uses (town_ledger.hold).
	var h:=Ledger.hold(civ_id,region_id)
	if region.is_empty() or not bool(h.held):
		var why:=Ledger.hold_words(h)
		return {"error":(why+" Nobody of ours is there to carry out the order.") if why!="" else "We do not hold that town."}
	var garrison:=int(h.garrison)
	var name:=String(region.get("name","the town"))
	var home:=String(WorldSimulation.state.settlement_name)
	var day:=int(WorldSimulation.state.elapsed_days)
	# The town's one ledger of its people: every step below reads it afresh
	# and writes it before the world's own count changes (town_ledger.gd).
	var out:={"ok":true,"town":name,"garrison":garrison,"killed":0,"escaped":0,"captives":0,"moved":0,"move_status":"","burned":false,"tribute":0,"left":false,"spared":false,"policy":"","reinforced":0,"freed":0,"arrive_days":0,"fled":{},"violated":0,"violate_deaths":0,"conceived":0}
	var parts:PackedStringArray=PackedStringArray()
	var refusals:PackedStringArray=PackedStringArray()
	var harsh:=0.0
	# Strengthen the garrison from a band standing at the town.
	if bool(fate.get("reinforce",false)):
		var before:=garrison
		# The rebuilt garrison record keeps what this garrison is doing and
		# what it did (measures in force, the card note, the totals).
		var kept:={}
		var at_before:int=mc._occupation_force_index(civ_id,region_id)
		if at_before>=0:
			for key in ["measures","measure_note","note_before","fate","fate_note"]:
				if mc.occupation_forces[at_before].has(key): kept[key]=mc.occupation_forces[at_before][key]
		var more:Dictionary=mc.reinforce_occupation(civ_id,region_id)
		var at_after:int=mc._occupation_force_index(civ_id,region_id)
		if at_after>=0:
			for key in kept: mc.occupation_forces[at_after][key]=kept[key]
		if more.has("error"): refusals.append(String(more.error))
		else:
			garrison=int(mc.occupation_force_for_region(civ_id,region_id).get("troops",garrison))
			out.reinforced=maxi(0,garrison-before); out.garrison=garrison
			parts.append("%s more join the garrison of %s; %s hold it now." % [_cap(_count(int(out.reinforced))),name,_count(garrison)])
	# Rape of the women, before anything else the words order.
	if bool(fate.get("violate",false)) or bool(fate.get("violate_kids",false)): harsh+=_violate(civ_id,region_id,name,fate,garrison,general,out,parts,refusals,day)
	# Killing: those we hold, then the free on the stated odds.
	if bool(fate.get("kill_men",false)): harsh+=_kill(civ_id,region_id,name,fate,garrison,out,parts,refusals,day)
	# People walked home: captives in bonds, or residents as our own.
	var status:=String(fate.get("move","enslaved" if bool(fate.get("captives",false)) else ""))
	if status!="": harsh+=_carry(civ_id,region_id,name,home,status,fate,garrison,out,parts,refusals,day)
	# Freeing captives already brought home from this town.
	if bool(fate.get("free",false)):
		var freed_people:=0
		var total:=float(WorldSimulation.state.population_exact) if float(WorldSimulation.state.population_exact)>0.0 else float(WorldSimulation.state.population_total)
		for group:Dictionary in mc.occupation_transfers.data.groups:
			if String(group.get("origin_region",""))!=region_id or String(group.get("status",""))=="citizen": continue
			if not mc.occupation_transfers.emancipate(int(group.id)).has("error"):
				out.freed=int(out.freed)+1
				freed_people+=roundi(float(group.get("share",0.0))*total)
		if int(out.freed)>0:
			var l:=Ledger.of(civ_id,region_id)
			l["freed"]=int(l.get("freed",0))+freed_people
			parts.append("The %s captives from %s living among us are free people now, with our rights." % [_count(freed_people),name] if freed_people>0 else "The captives from %s living among us are free people now, with our rights." % name)
		else: refusals.append("Nobody from %s is held in bonds among us." % name)
	# Tribute: what the band can carry of their stores.
	if bool(fate.get("tribute",false)):
		var stock:=Hall.foreign_stock(civ_id,"Food")
		var got:=0.0
		if stock>0.0: got=Hall.EXCHANGE.take(civ_id,"Food",minf(stock*0.25,float(garrison)*TRIBUTE_PER_FIGHTER))
		if got>0.0:
			Hall.EXCHANGE.receive("player","Food",got)
			out.tribute=roundi(got)
			parts.append("The band carried off %d Food from their stores." % roundi(got))
			harsh+=0.2
		else:
			refusals.append("Their stores are already empty; there is nothing to take.")
	# How we rule it.
	var policy:=String(fate.get("policy",""))
	if policy!="" and not bool(fate.get("raze",false)):
		var ruled:Dictionary=world.set_occupation_policy(civ_id,region_id,policy)
		if ruled.has("error"): refusals.append(String(ruled.error))
		else:
			out.policy=policy
			parts.append(String({"military_rule":"%s is ruled by the spear now: our fighters' word is law there.","self_rule":"%s keeps its own elders; we take little and ask little.",
				"equal_citizenship":"The people of %s are counted as our own people now, with our rights.","stewardship":"%s is governed as a town of ours: its stores kept and its people protected.",
				"forced_labor":"The people of %s are held as slaves and made to work for us."}.get(policy,"%s has a new order.")) % name)
			if policy in ["military_rule","forced_labor"]: harsh+=0.5 if policy=="military_rule" else 0.8
	if bool(fate.get("reconstruct",false)):
		var built:Dictionary=world.set_occupation_policy(civ_id,region_id,"reconstruct")
		if built.has("error"): refusals.append(String(built.error))
		else: parts.append("Rebuilding begins at %s, as fast as our stores and their hands allow." % name)
	# Burning: the town becomes our ruin; the garrison stays only if told to.
	if bool(fate.get("raze",false)): harsh+=_burn(civ_id,region_id,name,fate,garrison,out,parts,refusals,day)
	# Given back, or stripped and left: the town goes back and the garrison comes home.
	if not bool(out.burned) and (bool(fate.get("leave",false)) or (bool(fate.get("tribute",false)) and not bool(fate.get("hold",false)) and policy=="")):
		# A ruin we burned is left to nobody, never handed back to its old people
		# (as court_war_orders._abandon).
		var ruin:=not Ledger.our_ruin(region_id).is_empty()
		var back:Dictionary=mc.evacuate_occupation(civ_id,region_id) if ruin else world.occupation_resident_order(civ_id,region_id,"restore_self_rule")
		if not back.has("error"):
			out.left=true
			var bands:=bands_home(region_id,int(back.get("army_id",-1)))
			parts.append("The garrison marches home%s%s." % [" behind the captives" if int(out.captives)>0 else "",(", and %s with it" % bands) if bands!="" else ""])
			# Nobody of ours stays to guard those we held: they go free, said here.
			var freed:=Ledger.settle(civ_id,region_id,true)
			if not freed.is_empty():
				parts.append(String(freed.words))
				out["went_free"]=int(freed.freed)+int(freed.scattered)
		else:
			refusals.append("The garrison cannot leave yet: %s" % String(back.error))
	if bool(fate.get("spare",false)) or (parts.is_empty() and refusals.is_empty() and bool(fate.get("hold",false))):
		out.spared=true
		var civ:Dictionary=world.civilizations[index]
		var ri:int=world._region_index(civ,region_id)
		if ri>=0:
			var r:Dictionary=civ.strategic_regions[ri]
			var data:Dictionary=Governance.state(r)
			data.grievance=clampf(float(data.grievance)-.1,0,1); data.trust=clampf(float(data.trust)+.1,0,1)
			r.governance=data; civ.strategic_regions[ri]=r; world.civilizations[index]=civ
			if WorldSimulation.enabled: Combat.governance(civ_id,region_id,r)
		parts.append("%s is spared. %s of ours hold it, and nobody there is harmed." % [name,_cap(_count(garrison))])
	if parts.is_empty():
		if not refusals.is_empty(): return {"error":" ".join(refusals)}
		return {"error":"Tell me what is to become of %s: spare it and hold it, take captives and burn it, put the men to the sword, or take tribute and leave." % name}
	_consequences(civ_id,name,out,harsh,general,day)
	# Told for a generation by their people, and heard of by every people we
	# know (deeds.gd).
	var deeds:=preload("res://scripts/deeds.gd")
	if int(out.killed)>0: deeds.record(civ_id,"massacre",int(out.killed),"the slaughter of %d at %s" % [int(out.killed),name],day)
	if int(out.get("violated",0))>0: deeds.record(civ_id,"violation",int(out.violated),"what our garrison did to the women of %s" % name,day)
	out["text"]=" ".join(parts)+(" But "+_lower_first(" ".join(refusals)) if not refusals.is_empty() else "")
	out["outcome"]=_note(name,out)
	# People got away and the garrison still holds the town: a chase can follow.
	var held_at:int=mc._occupation_force_index(civ_id,region_id)
	if int(out.escaped)>0 and Ledger.holds(civ_id,region_id) and not bool(out.left) and Ledger.running_men(Ledger.of(civ_id,region_id))>0: out["fled"]=Ledger.running(Ledger.of(civ_id,region_id)).duplicate(true)
	# The garrison's card on the map says what was last done there.
	if held_at>=0:
		var brief:=_note(name,out).trim_prefix(name+": ").trim_suffix(".")
		mc.occupation_forces[held_at]["fate_note"]=_cap(brief).substr(0,80)
		# Measures still in force keep the card; this order waits behind them.
		if bool(mc.occupation_forces[held_at].get("measure_note",false)):
			mc.occupation_forces[held_at]["note_before"]=_cap(brief).substr(0,80)
			Measures.refresh_note(mc.occupation_forces[held_at])
		# The tribute taken (the people are counted in the town's ledger).
		var past:Dictionary=(mc.occupation_forces[held_at].get("fate") as Dictionary).duplicate() if mc.occupation_forces[held_at].get("fate") is Dictionary else {}
		past["tribute"]=int(past.get("tribute",0))+int(out.get("tribute",0))
		past["day"]=day
		mc.occupation_forces[held_at]["fate"]=past
	Chronicle.record({"key":"town_fate:%s:%d" % [region_id,day],"title":_title(name,out).substr(0,70),"text":" ".join(parts),
		"tier":"moment","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	return out


# --------------------------------------------------------------------------
# Rape
# --------------------------------------------------------------------------

## The chance each free woman is found and raped: one fighter reaching about
## two women a day over the days it goes on, against the women there. Those
## we hold cannot hide (+0.25). Within what sacked towns show: in a small
## town most, in a large one with a small garrison a third or more.
static func violate_odds(garrison:int,women:int,days:int)->float:
	if women<=0 or garrison<=0: return 0.0
	var reach:=clampf(float(garrison)*2.0*float(maxi(1,days))/float(women),0.0,1.5)
	return clampf(0.2+0.5*reach/1.5+0.05*float(maxi(1,days)-1),0.15,0.85)

## The god's order to rape the women of a town we hold. Those we hold are
## reached first and cannot hide; the free are each reached on the stated
## odds, one seeded roll each. A few die of it (the ledger's dead, through
## the world's count as a killing is). Of the rest, those of an age to bear
## and not already with child conceive on the stated odds, and those
## pregnancies go into their own people's count (_conceive). Children are
## never part of it: the commander refuses that, plainly.
static func _violate(civ_id:String,region_id:String,name:String,fate:Dictionary,garrison:int,general:Dictionary,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	if bool(fate.get("violate_kids",false)):
		refusals.append("None of the children of %s are touched: I will not set the men on children." % name)
	if not bool(fate.get("violate",false)): return 0.0
	var l:=Ledger.of(civ_id,region_id)
	var held:=0
	for status in Ledger.HELD: held+=Ledger.count(l,String(status),"women")
	var free:=Ledger.count(l,"free","women")
	if held+free<=0:
		refusals.append("There are no women left in %s. %s" % [name,_left_words(civ_id,region_id,name)])
		return 0.0
	var days:=clampi(int(fate.get("violate_days",VIOLATE_DAYS)),1,7)
	var p:=violate_odds(garrison,held+free,days)
	var p_held:=minf(0.95,p+0.25)
	var r:=Ledger.rng(region_id,day,"violate")
	var hurt_held:=Ledger.roll(r,held,p_held)
	var hurt_free:=Ledger.roll(r,free,p)
	var hurt:=hurt_held+hurt_free
	var died:=Ledger.roll(r,hurt,VIOLATE_DEATH)
	var fertile:=Ledger.roll(r,hurt-died,FERTILE_SHARE)
	var p_child:=1.0-pow(1.0-CONCEIVE_PER_DAY,float(days))
	var conceived:=Ledger.roll(r,fertile,p_child)
	# The dead, out of the ledger first and then the world's count (as _kill).
	if died>0:
		var backup:=l.duplicate(true)
		var gone:=int(Ledger.remove(l,Ledger.plan_of(Ledger.HELD,["women"]),mini(died,hurt_held),"killed").total)
		gone+=int(Ledger.remove(l,[["free","women"]],died-gone,"killed").total)
		var done:Dictionary=WorldSimulation.world.occupation_resident_order(civ_id,region_id,"kill_residents",gone,true) if gone>0 else {}
		if done.has("error"):
			Ledger.region_ref(civ_id,region_id)["ledger"]=backup
			l=Ledger.of(civ_id,region_id)
			died=0
			_grieve(civ_id,region_id)
		else: died=gone
		# The world keeps its own copy of the town now: read the ledger afresh.
		l=Ledger.of(civ_id,region_id)
	else: _grieve(civ_id,region_id)
	l["violated"]=int(l.get("violated",0))+hurt
	l["violated_dead"]=int(l.get("violated_dead",0))+died
	l["conceived"]=int(l.get("conceived",0))+conceived
	if conceived>0:
		var rec:={"day":day,"n":conceived,"shown":false}
		# Their own people's demography carries the pregnancies when it is
		# simulated; else the children are born here on the stated share.
		if not _conceive(civ_id,region_id,conceived):
			rec["born"]=Ledger.roll(r,conceived,BORN_SHARE)
			rec["due"]=day+BIRTH_DAYS
		var list:Array=l.get("pregnancies",[]) if l.get("pregnancies") is Array else []
		list.append(rec)
		l["pregnancies"]=list
	out.violated=hurt
	out.violate_deaths=died
	out.conceived=conceived
	out["violate_odds"]=p
	out["violate_days"]=days
	Measures.settle_records(civ_id,region_id)
	parts.append(_violate_words(name,garrison,days,held,hurt_held,free,hurt_free,p,died))
	return 1.0 if hurt>0 else 0.0

## "For three days the 17 of the garrison were let loose on the women of
## Tsaren. All 12 we held were raped. Of the 204 free in their houses, each
## had about 1 in 3 chance of being found, and 70 were. Two died of it."
static func _violate_words(name:String,garrison:int,days:int,held:int,hurt_held:int,free:int,hurt_free:int,p:float,died:int)->String:
	var bits:PackedStringArray=PackedStringArray()
	bits.append("For %s the %s of the garrison were let loose on the women of %s." % [_days(days),_count(garrison),name])
	if held>0: bits.append(("All %s we held were raped." % _count(held)) if hurt_held>=held else ("Of the %s we held, %s were raped." % [_count(held),_count(hurt_held)]))
	if free>0: bits.append("Of the %s free in their houses, each had %s of being found, and %s were." % [_count(free),Ledger.chance_words(p),_count(hurt_free)])
	if died>0: bits.append("%s died of it." % _cap(_count(died)))
	bits.append("If any are with child, it will show in a few months.")
	return " ".join(bits)

## A town's people after a cruelty that killed nobody: grievance at its
## height, trust gone, resistance up (as a killing leaves them).
static func _grieve(civ_id:String,region_id:String)->void:
	var world:Variant=WorldSimulation.world
	var index:int=world._civilization_index(civ_id)
	if index<0: return
	var civ:Dictionary=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri<0: return
	var region:Dictionary=civ.strategic_regions[ri]
	var data:Dictionary=Governance.state(region)
	data.grievance=1.0; data.trust=0.0
	region.governance=data
	region["resistance"]=clampf(float(region.get("resistance",0.0))+0.25,0.0,1.0)
	civ.strategic_regions[ri]=region; world.civilizations[index]=civ
	if WorldSimulation.enabled: Combat.governance(civ_id,region_id,region)

## Pregnancies into the struck people's own count, where their town's lives
## are simulated: the town's pregnancy record (game_state
## process_reproduction_day) carries them to term with its own losses, and
## the children are born to them there. False where it is not simulated.
static func _conceive(civ_id:String,region_id:String,n:int)->bool:
	if n<=0 or not WorldSimulation.enabled: return false
	var region:Dictionary=WorldSimulation.world.region_snapshot(civ_id,region_id)
	var local_id:=String(region.get("local_city_id",""))
	if local_id.is_empty(): return false
	var added:Variant=WorldSimulation.scoped(Combat.owner(civ_id),func()->int:
		return WorldSimulation.settlements.with_city_resources(local_id,func()->int:
			return WorldSimulation.settlements.with_local_population(func()->int:
				var state:Variant=WorldSimulation.state
				state.pregnancy_cohorts["first_trimester"]=float(state.pregnancy_cohorts.get("first_trimester",0.0))+float(n)
				return n,true)
		)
	)
	return int(added)==n

## Children born in a town whose people are not simulated: the town's count,
## its people's count and young, and the ledger's free children together.
static func _births(civ_id:String,region_id:String,n:int)->int:
	if n<=0: return 0
	var world:Variant=WorldSimulation.world
	var index:int=world._civilization_index(civ_id)
	if index<0: return 0
	var l:=Ledger.of(civ_id,region_id)
	var r:=Ledger.region_ref(civ_id,region_id)
	if r.is_empty(): return 0
	# The bands first: they are made to add up to the children already there.
	Ledger._kid_add(l,"p:free",n)
	var row:Dictionary=l.present.free
	row["children"]=int(row.get("children",0))+n
	l["joined"]=int(l.get("joined",0))+n
	r["population"]=float(r.get("population",0.0))+float(n)
	var civ:Dictionary=world.civilizations[index]
	civ["population"]=float(civ.get("population",0.0))+float(n)
	if civ.get("cohorts") is Dictionary and (civ.cohorts as Dictionary).has("children"):
		(civ.cohorts as Dictionary)["children"]=float(civ.cohorts.children)+float(n)
	return n

## Each day: the pregnancies show and our war leader hears of it; where their
## lives are not simulated, the children are born when they are due. Told
## once each, in the Chronicle.
static func _pregnancies_day(civ_id:String,region_id:String,l:Dictionary,day:int)->void:
	var list:Variant=l.get("pregnancies")
	if not list is Array: return
	var name:=String(Ledger.region_ref(civ_id,region_id).get("name","the town"))
	for rec in list:
		if not rec is Dictionary: continue
		var p:Dictionary=rec
		if not bool(p.get("shown",false)) and day>=int(p.get("day",day))+SHOWN_DAYS:
			p["shown"]=true
			Chronicle.record({"key":"violated_with_child:%s:%d" % [region_id,int(p.day)],"title":("With Child in %s" % name).substr(0,70),
				"text":"%s of the women of %s our garrison raped are with child by our men." % [_cap(_count(int(p.n))),name],"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
		if p.has("due") and not bool(p.get("born_done",false)) and day>=int(p.due):
			p["born_done"]=true
			var born:=_births(civ_id,region_id,int(p.get("born",0)))
			if born>0:
				Chronicle.record({"key":"violated_born:%s:%d" % [region_id,int(p.day)],"title":("Children Born in %s" % name).substr(0,70),
					"text":"%s children were born in %s to the women our garrison raped. Of %s pregnancies, the rest were lost." % [_cap(_count(born)),name,_count(int(p.n))],"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})


# --------------------------------------------------------------------------
# Killing
# --------------------------------------------------------------------------

## The chance to catch each free man as a killing starts: our fighters to
## their men, and what already holds them (kept indoors, kin held as
## hostages, their weapons taken). Within what early warfare shows: most who
## stand are caught, a good share of the rest get away.
static func catch_odds(garrison:int,free:int,force:Dictionary,l:Dictionary)->float:
	if free<=0: return 1.0
	var p:=CAUGHT_SHARE+0.2*(clampf(float(garrison)*3.0/float(free),0.0,1.5)-1.0)
	if not Measures._running(force,"curfew").is_empty(): p+=0.08
	if not l.is_empty() and Ledger.count(l,"hostage")>0: p+=0.04
	if not Measures._running(force,"disarm").is_empty(): p+=0.03
	return clampf(p,0.35,0.92)

## The god's order to kill. Those we hold cannot run and all die (a number
## asked takes them first); the garrison's hands set only how long it takes.
## The free are each caught on the stated odds, one seeded roll each, at most
## a day's work of our fighters; the rest run for their refuge.
static func _kill(civ_id:String,region_id:String,name:String,fate:Dictionary,garrison:int,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	# Some of the children only ("kill the boys"): those bands, on the same
	# odds; any grown group named with them goes by the whole-group path.
	var only_kids:Dictionary=fate.get("kill_kids",{}) if fate.get("kill_kids") is Dictionary else {}
	if not only_kids.is_empty() and not bool(fate.get("kill_all",false)) and (fate.get("kill_groups",["men"]) as Array).has("children"):
		var harsh:=0.0
		var grown:=(fate.get("kill_groups",[]) as Array).filter(func(g:Variant)->bool: return String(g)!="children")
		if not grown.is_empty():
			var rest:=fate.duplicate(); rest["kill_groups"]=grown; rest.erase("kill_kids")
			harsh=maxf(harsh,_kill(civ_id,region_id,name,rest,garrison,out,parts,refusals,day))
		return maxf(harsh,_kill_kids(civ_id,region_id,name,fate,only_kids,garrison,out,parts,refusals,day))
	var world:Variant=WorldSimulation.world
	var l:=Ledger.of(civ_id,region_id)
	var all:=bool(fate.get("kill_all",false))
	var bound_only:=bool(fate.get("bound_only",false))
	var groups:Array=Ledger.GROUPS if all else (fate.get("kill_groups",["men"]) as Array)
	var who:="people" if all or groups.size()>=Ledger.GROUPS.size() else " and ".join(PackedStringArray(groups.map(func(g:Variant)->String: return String(Ledger.GROUP_WORDS.get(String(g),"people")))))
	var asked:=int(fate.get("count",0))
	var held_plan:=Ledger.plan_of(["bound","worker","conscript","hostage"],groups)
	var held:=0
	var bound:=0
	for step in held_plan:
		var k:=Ledger.count(l,String(step[0]),String(step[1]))
		held+=k
		if String(step[0])=="bound": bound+=k
	# "bound men" when all we hold are bound; "men we hold" when some work or serve.
	var held_words:=("bound "+who) if bound==held else (who+" we hold")
	var free_by:={}
	var free:=0
	for g in groups:
		var n:=0 if bound_only else Ledger.count(l,"free",String(g))
		free_by[g]=n; free+=n
	if held+free<=0:
		refusals.append(("There are no %s of %s under our guard to kill. %s" % [who,name,_left_words(civ_id,region_id,name)]) if bound_only else ("There are no %s left in %s to kill. %s" % [who,name,_left_words(civ_id,region_id,name)]))
		return 0.0
	var per_day:=maxi(1,garrison*KILLS_PER_FIGHTER*(2 if all else 1))
	var take_held:=held if asked<=0 else mini(held,asked)
	var want_free:=free if asked<=0 else mini(free,maxi(0,asked-take_held))
	var force:Dictionary=WorldSimulation.military.occupation_force_for_region(civ_id,region_id)
	var p:=catch_odds(garrison,want_free,force,l)
	var r:=Ledger.rng(region_id,day,"kill:"+who)
	var caught_by:={}
	var caught:=0
	var left:=want_free
	for g in groups:
		var n:=mini(int(free_by[g]),left); left-=n
		var c:=mini(Ledger.roll(r,n,p),maxi(0,per_day-caught))
		caught_by[g]=c; caught+=c
	# The rest run as the killing starts (a number asked leaves the others be).
	var escaped_by:={}
	var escaped:=0
	if want_free>0 and asked<=0:
		for g in groups:
			var e:=int(free_by[g])-int(caught_by[g])
			escaped_by[g]=e; escaped+=e
	var total:=take_held+caught
	var available:=maxi(0,roundi(float(Ledger.region_ref(civ_id,region_id).get("population",0.0))))
	total=mini(total,available)
	# The ledger first (the world's deaths rebuild the town's record, and the
	# ledger goes with it): the held, then the caught; the rest run.
	var backup:=l.duplicate(true)
	var held_dead:=int(Ledger.remove(l,held_plan,mini(take_held,total),"killed").total)
	var free_dead:=0
	for g in groups:
		var c:=mini(int(caught_by[g]),total-held_dead-free_dead)
		if c>0: free_dead+=int(Ledger.remove(l,[["free",String(g)]],c,"killed").total)
	var refuge:=Pursuit.refuge(civ_id,region_id)
	for g in groups:
		if int(escaped_by.get(g,0))>0: Ledger.run(l,"free",String(g),int(escaped_by[g]),refuge,day)
	if held_dead+free_dead>0:
		var done:Dictionary=world.occupation_resident_order(civ_id,region_id,"kill_residents",held_dead+free_dead,true)
		if done.has("error"):
			# Nothing happened in the world: nothing happened in the ledger.
			Ledger.region_ref(civ_id,region_id)["ledger"]=backup
			refusals.append(String(done.error)); return 0.0
	out.killed=int(out.killed)+held_dead+free_dead
	out.escaped=int(out.escaped)+escaped
	out["kill_odds"]=p
	out["held_killed"]=held_dead
	out["kill_escaped"]=escaped
	Measures.settle_records(civ_id,region_id)
	parts.append(_kill_words(name,who,garrison,held_dead,take_held,want_free,free_dead,escaped,p,per_day,refuge,held_words,asked>0 and free>want_free))
	return 1.0 if held_dead+free_dead>0 else 0.0

## Only some of the children ("the boys", "the girls under ten"), band by
## band from the town's ledger: those we hold cannot run and all die; the
## free are each caught on the stated odds (catch_odds), one seeded roll each;
## the rest run for their refuge. kids: {band: share of that band}.
static func _kill_kids(civ_id:String,region_id:String,name:String,fate:Dictionary,kids:Dictionary,garrison:int,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	var world:Variant=WorldSimulation.world
	var l:=Ledger.of(civ_id,region_id)
	var who:=String(fate.get("kill_kids_words","children"))
	var asked:=int(fate.get("count",0))
	var bound_only:=bool(fate.get("bound_only",false))
	var held_order:=["bound","worker","conscript","hostage"]
	var held_by:={}
	var held:=0
	var bound:=0
	var free_by:={}
	var free:=0
	for band in Ledger.KID_BANDS:
		var share:=clampf(float(kids.get(band,0.0)),0.0,1.0)
		if share<=0.0: continue
		var h:=0
		for status in held_order:
			var k:=roundi(float(int(Ledger.kids(l,String(status)).get(band,0)))*share)
			h+=k
			if status=="bound": bound+=k
		if h>0: held_by[band]=h; held+=h
		var n:=0 if bound_only else roundi(float(int(Ledger.kids(l,"free").get(band,0)))*share)
		if n>0: free_by[band]=n; free+=n
	if held+free<=0:
		refusals.append(("There are no %s of %s under our guard to kill. %s" % [who,name,_left_words(civ_id,region_id,name)]) if bound_only else ("There are no %s left in %s to kill. %s" % [who,name,_left_words(civ_id,region_id,name)]))
		return 0.0
	var per_day:=maxi(1,garrison*KILLS_PER_FIGHTER)
	var take_held:=held if asked<=0 else mini(held,asked)
	var want_free:=free if asked<=0 else mini(free,maxi(0,asked-take_held))
	var force:Dictionary=WorldSimulation.military.occupation_force_for_region(civ_id,region_id)
	var p:=catch_odds(garrison,want_free,force,l)
	var r:=Ledger.rng(region_id,day,"kill:"+who)
	var caught_by:={}
	var caught:=0
	var left:=want_free
	for band in free_by:
		var n:=mini(int(free_by[band]),left); left-=n
		var c:=mini(Ledger.roll(r,n,p),maxi(0,per_day-caught))
		caught_by[band]=c; caught+=c
	var escaped_by:={}
	var escaped:=0
	if want_free>0 and asked<=0:
		for band in free_by:
			var e:=int(free_by[band])-int(caught_by.get(band,0))
			escaped_by[band]=e; escaped+=e
	var total:=mini(take_held+caught,maxi(0,roundi(float(Ledger.region_ref(civ_id,region_id).get("population",0.0)))))
	# The ledger first (as _kill): those we held, then the caught; the rest run.
	var backup:=l.duplicate(true)
	var held_dead:=0
	var room:=mini(take_held,total)
	for band in held_by:
		if room-held_dead<=0: break
		held_dead+=int(Ledger.remove_kids(l,held_order,{band:mini(int(held_by[band]),room-held_dead)},"killed").total)
	var free_dead:=0
	for band in caught_by:
		var c:=mini(int(caught_by[band]),total-held_dead-free_dead)
		if c>0: free_dead+=int(Ledger.remove_kids(l,["free"],{band:c},"killed").total)
	var refuge:=Pursuit.refuge(civ_id,region_id)
	for band in escaped_by:
		if int(escaped_by[band])>0: Ledger.run(l,"free","children",int(escaped_by[band]),refuge,day,[band])
	if held_dead+free_dead>0:
		var done:Dictionary=world.occupation_resident_order(civ_id,region_id,"kill_residents",held_dead+free_dead,true)
		if done.has("error"):
			Ledger.region_ref(civ_id,region_id)["ledger"]=backup
			refusals.append(String(done.error)); return 0.0
	out.killed=int(out.killed)+held_dead+free_dead
	out.escaped=int(out.escaped)+escaped
	out["kill_odds"]=p
	out["held_killed"]=int(out.get("held_killed",0))+held_dead
	out["kill_escaped"]=int(out.get("kill_escaped",0))+escaped
	Measures.settle_records(civ_id,region_id)
	var held_words:=("bound "+who) if bound==held else (who+" we hold")
	parts.append(_kill_words(name,who,garrison,held_dead,take_held,want_free,free_dead,escaped,p,per_day,refuge,held_words,asked>0 and free>want_free))
	return 1.0 if held_dead+free_dead>0 else 0.0

## "17 of ours against 38 bound men: none could run. All 38 were killed."
static func _kill_words(name:String,who:String,garrison:int,held_dead:int,held:int,free:int,free_dead:int,escaped:int,p:float,per_day:int,refuge:Dictionary,held_words:String,rest_left:bool)->String:
	var ours:="%s of ours" % _cap(_count(garrison))
	var t:=""
	var days:=ceili(float(held_dead+free_dead)/float(maxi(1,per_day)))
	if free<=0:
		t="%s against %s %s: none could run. %s were killed." % [ours,_count(held),held_words,("All %s" % _count(held_dead)) if held_dead==held else _cap(_count(held_dead))]
	elif held<=0:
		t="%s against %s %s of %s, free in their houses: %s. %s %s of %s were put to the sword" % [ours,_count(free),who,name,_chance(p),_cap(_count(free_dead)),who,name]
		t+=("; %s got away %s." % [_count(escaped),Pursuit.toward_words(refuge)]) if escaped>0 else "; none got away."
	else:
		t="%s against %s %s and %s free. %s could not run: %s were killed. Of the free, %s: %s more %s of %s were put to the sword" % [ours,_count(held),held_words,_count(free),"The bound" if held_words.begins_with("bound") else "Those we held",("all %s" % _count(held_dead)) if held_dead==held else _count(held_dead),_chance(p),_count(free_dead),who,name]
		t+=("; %s got away %s." % [_count(escaped),Pursuit.toward_words(refuge)]) if escaped>0 else "; none got away."
	if rest_left: t+=" The rest are left in their houses."
	if days>1: t+=" It took %s." % _days(days)
	return t

## "a good chance to catch each, about 7 in 10".
static func _chance(p:float)->String:
	var quality:="a good chance" if p>=0.6 else ("an even chance" if p>=0.4 else "a poor chance")
	return "%s to catch each, %s" % [quality,Ledger.chance_words(p)]

## Who is still in the town, in words: "Tsaren has 70 women, 93 children and
## 63 old people left, all free in their houses."
static func _left_words(civ_id:String,region_id:String,name:String)->String:
	var c:=Ledger.counts(civ_id,region_id)
	if c.is_empty() or int(c.here)<=0: return "Nobody is left in %s." % name
	return "In %s now: %s." % [name,Ledger.here_words(c)]


# --------------------------------------------------------------------------
# Taking people home
# --------------------------------------------------------------------------

## The chance to round up each of those the god names: the men bound or dead
## leave nobody to hide them; kept indoors, fewer slip away.
static func round_up_odds(l:Dictionary,force:Dictionary)->float:
	var p:=ROUNDED_UP_SHARE
	var men_start:=maxi(1,roundi(float(int(l.get("start",0)))*MEN_SHARE))
	if Ledger.count(l,"free","men")<=roundi(float(men_start)*0.1): p+=0.15
	if not Measures._running(force,"curfew").is_empty(): p+=0.05
	return clampf(p,0.4,0.85)

## Captives in bonds, or residents moved as our own or to labour. Those we
## already hold (bound, hostages) go first and none of them can slip away;
## the free are each rounded up on the stated odds (captives), one seeded roll
## each. All bounded by what the garrison can guard on the road, by the road,
## the rations and the room at home.
static func _carry(civ_id:String,region_id:String,name:String,home:String,status:String,fate:Dictionary,garrison:int,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	var mc:Variant=WorldSimulation.military
	var l:=Ledger.of(civ_id,region_id)
	var enslaved:=status=="enslaved"
	var take:Dictionary=fate.get("take",{"women":1.0,"children":1.0}) if enslaved else {"men":1.0,"women":1.0,"children":1.0,"elders":1.0}
	var kids:Dictionary=fate.get("kids",{}) if enslaved and fate.get("kids") is Dictionary else {}
	if not kids.is_empty() and not take.has("children"): take=take.duplicate(); take["children"]=1.0
	# Who is taken, one unit at a time: a group, or a band of its children
	# ("the girls under ten": town_ledger's children's make-up).
	var units:={}
	for g in Ledger.GROUPS:
		if not take.has(g) or (g=="children" and not kids.is_empty()): continue
		units[g]={"group":g,"band":"","share":clampf(float(take[g]),0.0,1.0)}
	for band in Ledger.KID_BANDS:
		if float(kids.get(band,0.0))>0.0: units[band]={"group":"children","band":band,"share":clampf(float(kids[band]),0.0,1.0)}
	var held_by:={}
	var held_n:=0
	var pool_by:={}
	var pool:=0
	for key in units:
		var u:Dictionary=units[key]
		var h:=roundi(float(_unit_count(l,"bound",u)+_unit_count(l,"hostage",u))*float(u.share)) if enslaved else 0
		if h>0: held_by[key]=h; held_n+=h
		var n:=roundi(float(_unit_count(l,"free",u))*float(u.share))
		if n>0: pool_by[key]=n; pool+=n
	var whom:=_take_names(take,kids,String(fate.get("kids_words","")))
	if pool+held_n<=0:
		refusals.append("There are no %s left in %s to take. %s" % [whom,name,_left_words(civ_id,region_id,name)])
		return 0.0
	var wanted:=pool+held_n if enslaved else roundi(float(pool)*0.3)
	var asked:=int(fate.get("count",0))
	if asked>0 and not bool(fate.get("kill_men",false)): wanted=mini(wanted,asked)
	var force:Dictionary=mc.occupation_force_for_region(civ_id,region_id)
	var p:=round_up_odds(l,force) if enslaved else 1.0
	var r:=Ledger.rng(region_id,day,"carry:"+status)
	var cap:=garrison*CAPTIVES_PER_FIGHTER
	var left:=wanted
	# Those we hold: none can slip away.
	var held_caught_by:={}
	var held_caught:=0
	for g in held_by:
		var c:=mini(mini(int(held_by[g]),left),maxi(0,cap-held_caught))
		held_caught_by[g]=c; held_caught+=c; left-=c
	# The free: each on the stated odds.
	var caught_by:={}
	var caught:=0
	var ran_by:={}
	var hid:=0
	for g in pool_by:
		var n:=mini(int(pool_by[g]),maxi(0,left)); left-=n
		var rolled:=Ledger.roll(r,n,p) if enslaved else n
		var c:=mini(rolled,maxi(0,cap-held_caught-caught))
		caught_by[g]=c; caught+=c
		if enslaved:
			# Those who slipped the round-up: some run for it, the rest hide.
			var evaded:=n-rolled
			var ran:=Ledger.roll(r,evaded,0.5)
			ran_by[g]=ran; hid+=evaded-ran
	if held_caught+caught<=0:
		refusals.append("We could not lay hands on any of the %s of %s." % [whom,name])
		return 0.0
	# The road, the rations and the room at home set how many can go.
	var count:=held_caught+caught
	var moved:Dictionary={}
	var last_error:=""
	for attempt in 8:
		if count<1: break
		var tried:Dictionary=mc.occupation_transfers.depart(civ_id,region_id,count,status,enslaved)
		if not tried.has("error"): moved=tried; break
		last_error=String(tried.error)
		count=count/2
	if moved.is_empty():
		refusals.append(last_error if last_error!="" else "There was nobody to take.")
		return 0.0
	var transfer:Dictionary=(mc.occupation_transfers.data.transfers as Array).back()
	out.arrive_days=int(transfer.get("days",0))
	# The ledger: those we held go first, then the free, by unit in
	# proportion to those caught.
	var from_held:=mini(count,held_caught)
	var went:=Ledger.split_by(from_held,_weights(held_caught_by))
	for key in units:
		var k:=int(went.get(key,0))
		if k<=0: continue
		var u:Dictionary=units[key]
		if String(u.band)!="": Ledger.remove_kids(l,["bound","hostage"],{String(u.band):k},"taken")
		else: Ledger.remove(l,[["bound",String(u.group)],["hostage",String(u.group)]],k,"taken")
	went=Ledger.split_by(count-from_held,_weights(caught_by))
	for key in units:
		var k:=int(went.get(key,0))
		if k<=0: continue
		var u:Dictionary=units[key]
		if String(u.band)!="": Ledger.remove_kids(l,["free"],{String(u.band):k},"taken")
		else: Ledger.remove(l,[["free",String(u.group)]],k,"taken")
	var refuge:=Pursuit.refuge(civ_id,region_id)
	var ran:=0
	for key in ran_by:
		var u:Dictionary=units[key]
		var n:=mini(int(ran_by[key]),_unit_count(l,"free",u))
		if n>0:
			var rec:=Ledger.run(l,"free",String(u.group),n,refuge,day,[String(u.band)] if String(u.band)!="" else [])
			if not rec.is_empty(): ran+=n
	out.escaped=int(out.escaped)+ran
	if from_held>0: Measures.settle_records(civ_id,region_id)
	var road:="about %s on the road" % _days(int(out.arrive_days))
	if enslaved:
		out.captives=count
		var how:=""
		if held_caught>0 and pool>0: how="the %s we held could not slip away, and of the rest, %s" % [_count(held_caught),_chance(p)]
		elif held_caught>0: how="all %s were already under our guard, so none could slip away" % _count(held_caught)
		else: how=_chance(p)+(", with their men bound or dead" if p>=ROUNDED_UP_SHARE+0.15-0.001 else "")
		var there:=" (%s of them there)" % _count(pool+held_n) if not kids.is_empty() or asked>0 else ""
		var t:="%s of ours rounded up the %s of %s%s: %s. %s were led away toward %s as captives, %s." % [_cap(_count(garrison)),whom,name,there,how,_cap(_count(count)),home,road]
		if held_caught+caught>count: t+=" We could not feed or house more on the road, so %s we had caught stay in the town." % _count(held_caught+caught-count)
		if ran>0: t+=" %s ran %s." % [_cap(_count(ran)),Pursuit.toward_words(refuge)]
		if hid>0: t+=" %s hid in the town and were not found." % _cap(_count(hid))
		parts.append(t)
		return 0.7
	out.moved=count; out.move_status=status
	parts.append("%s people of %s set out for %s %s, %s." % [_cap(_count(count)),name,home,"as our own people" if status=="citizen" else "to labour for us",road])
	return 0.4 if status=="penal" else 0.0

## "women and girls", "women and children", "girls under ten", "people".
static func _take_names(take:Dictionary,kids:Dictionary={},kids_words:String="")->String:
	if take.size()>=4 and kids.is_empty(): return "people"
	var words:PackedStringArray=PackedStringArray()
	for g in Ledger.GROUPS:
		if not take.has(g): continue
		if g=="children" and not kids.is_empty(): words.append(kids_words if kids_words!="" else "children")
		elif g=="children" and float(take[g])<1.0: words.append("girls")
		else: words.append(String(Ledger.GROUP_WORDS[g]))
	return " and ".join(words)

## How many of one unit (a group, or a band of its children) have a status.
static func _unit_count(l:Dictionary,status:String,u:Dictionary)->int:
	if String(u.get("band",""))!="": return int(Ledger.kids(l,status).get(String(u.band),0))
	return Ledger.count(l,status,String(u.get("group","")))

static func _weights(by:Dictionary)->Dictionary:
	var out:={}
	for k in by: out[k]=float(by[k])
	return out


# --------------------------------------------------------------------------
# Burning: our ruin
# --------------------------------------------------------------------------

## Burning: the houses, the stores and the walls go; whoever is still free in
## the town scatters to their people's other towns (or the hills); those we
## hold stay under guard only if the garrison stays. The town becomes our
## ruin in the ledger and the world, dated the day; it is not given back.
static func _burn(civ_id:String,region_id:String,name:String,fate:Dictionary,garrison:int,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	var world:Variant=WorldSimulation.world
	var mc:Variant=WorldSimulation.military
	var l:=Ledger.of(civ_id,region_id)
	# The town is gone: whoever was running from it reaches their refuge now.
	if not Ledger.running(l).is_empty():
		Pursuit.arrive(civ_id,region_id)
		l=Ledger.of(civ_id,region_id)
	var index:int=world._civilization_index(civ_id)
	var stays:=bool(fate.get("hold",false)) or String(fate.get("policy",""))!=""
	var refuge:=Pursuit.refuge(civ_id,region_id)
	var where:="the hills" if bool(refuge.get("hills",false)) else String(refuge.get("name","the hills"))
	# Who scatters: the free, and those we hold if we go.
	var statuses:Array=["free"] if stays else Ledger.PRESENT
	var n:=0
	for status in statuses: n+=Ledger.count(l,String(status))
	var men:=0
	if n>0:
		var removed:=Ledger.remove(l,Ledger.plan_of(statuses),n,"displaced")
		Ledger.went_to(l,where,int(removed.total))
		men=int(removed.get("men",0))
		Pursuit._reach_refuge(civ_id,region_id,int(removed.total),refuge,men)
	# The town itself: houses, stores and walls.
	var civ:Dictionary=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri>=0:
		var r:Dictionary=civ.strategic_regions[ri]
		var data:Dictionary=Governance.state(r)
		data.ruined=true; data.reconstruction=false
		data.grievance=clampf(float(data.grievance)+.25,0,1)
		data.local_institutions=maxf(0,float(data.local_institutions)-.3)
		data.last_coercive_day=day
		r.governance=data
		r["damage"]=1.0
		r["fortification"]=0.0
		if Ledger.present_total(l)<=0: r["resistance"]=0.0
		if r.has("stores"): r["stores"]={}
		civ.strategic_regions[ri]=r
		world.civilizations[index]=civ
		if WorldSimulation.enabled:
			Combat.governance(civ_id,region_id,r)
			Combat.damage_city(civ_id,region_id,1.0)
	# Measures that held people end when those people are gone.
	Measures.settle_records(civ_id,region_id)
	out.burned=true
	# The town's record as the world keeps it now (the scattering rebuilt it).
	l=Ledger.of(civ_id,region_id)
	var remain:=Ledger.present_total(l)
	var t:="%s was burned: its houses, its stores and its walls." % name
	if n>0: t+=" %s who %s still there scattered %s." % [_cap(_count(n)),"was" if n==1 else "were",Pursuit.toward_words(refuge)]
	var ruin:={"day":day,"before":Ledger.accounted(l),"by":"player","held":true,"left_day":-1,"stores_lost":true,"resettle":{}}
	l["ruin"]=ruin
	if not stays:
		# Nobody left to hold: the garrison comes home and the ruin is nobody's.
		var gone:Dictionary=mc.evacuate_occupation(civ_id,region_id)
		if gone.has("error"):
			refusals.append("The garrison cannot leave yet: %s" % String(gone.error))
		else:
			out.left=true
			ruin.held=false; ruin.left_day=day
			_schedule_resettle(civ_id,region_id,l,day)
			var bands:=bands_home(region_id,int(gone.get("army_id",-1)))
			t+=" The garrison marches home%s%s; nobody holds the ruins." % [" behind the captives" if int(out.captives)>0 else "",(", and %s with it" % bands) if bands!="" else ""]
	else:
		t+=" %s of ours stay to hold the ruins%s." % [_cap(_count(garrison)),(", with %s under guard" % _count(remain)) if remain>0 else ""]
	t+=" Nobody lives there now." if remain<=0 else ""
	parts.append(t)
	# Our own account of it, dated the day, replaces any old report of the place.
	firsthand(civ_id,region_id,day,"our own fighters")
	return 0.6

## A town we leave (burned, or given back) has nothing left for our bands to
## hold there: every band of ours standing idle at it turns for home with the
## garrison, so nobody is left "holding" a ruin. Returns the bands' names in
## words ("Vani's band"), "" when none was there.
static func bands_home(region_id:String,except_army:int=-1)->String:
	var mc:Variant=WorldSimulation.military
	if mc==null: return ""
	var names:PackedStringArray=[]
	for army in (mc.field_armies as Array).duplicate():
		var a:Dictionary=army
		var id:=int(a.get("army_id",0))
		if id==except_army or String(a.get("location_id",""))!=region_id or String(a.get("status",""))!="stationed" or int(a.get("troops",0))<=0: continue
		if mc._army_in_battle(id): continue
		var back:Dictionary=mc.return_field_army(id)
		if back.has("error"): continue
		var index:int=mc._field_army_index(id)
		if index>=0: (mc.field_armies[index] as Dictionary).erase("court_order")
		var general:=String((a.get("commander",{}) as Dictionary).get("name","")).get_slice(" of ",0).get_slice(" ",0)
		names.append(("%s's band" % general) if general!="" else String(a.get("name","our band")))
	if names.is_empty(): return ""
	return names[0] if names.size()==1 else "%s and %s" % [", ".join(names.slice(0,names.size()-1)),names[names.size()-1]]

## Our people saw it themselves: the city's record is today's, from them.
static func firsthand(civ_id:String,region_id:String,day:int,source:String)->void:
	var world:Variant=WorldSimulation.world
	if world==null or world.city_intelligence==null: return
	var intel:Variant=world.city_intelligence
	var seen:Dictionary=intel.capture("player",region_id,0.9,day,source,"ruin:%s:%d" % [region_id,day])
	if seen.is_empty(): return
	var book:Dictionary=intel.records.get("player",{})
	if book.has(region_id) and (book[region_id] as Dictionary).get("position") is Dictionary:
		seen["position"]=((book[region_id] as Dictionary).position as Dictionary).duplicate(true)
	intel.publish("player",seen,day)

## A ruin we burned and left: will its people come back to live in it? The
## odds from who survived to return, their dread of us and the war; the roll
## is made once (seeded) with its date and the day our people hear of it.
static func _schedule_resettle(civ_id:String,region_id:String,l:Dictionary,day:int)->void:
	var ruin:Dictionary=l.get("ruin",{})
	if ruin.is_empty() or not (ruin.get("resettle",{}) as Dictionary).is_empty(): return
	var before:=maxi(1,int(ruin.get("before",1)))
	var alive:=Ledger.gone(l,"fled")+Ledger.gone(l,"displaced")+Ledger.running_total(l)
	var share:=clampf(float(alive)/float(before),0.0,1.0)
	var dread:=clampf(DIVINE.civ_dread(civ_id),0.0,1.0)
	var at_war:=false
	var index:int=WorldSimulation.world._civilization_index(civ_id)
	if index>=0: at_war=bool((WorldSimulation.world.civilizations[index].get("player_relation",{}) as Dictionary).get("at_war",false))
	var p:=clampf(0.3+0.4*share-0.3*dread-(0.15 if at_war else 0.0),0.05,0.85)
	var r:=Ledger.rng(region_id,day,"resettle")
	var when:=day+r.randi_range(int(RESETTLE_DAYS[0]),int(RESETTLE_DAYS[1]))
	ruin["resettle"]={"chance":p,"happens":r.randf()<p,"day":when,"learn_day":when+r.randi_range(int(LEARN_DAYS[0]),int(LEARN_DAYS[1])),"done":false,"happened":false,"known":false,"people":0}

## Each day: whoever we held where no garrison of ours stands is free again; an empty
## ruin has nobody to resist us; a ruin's people come back on their day (if
## the roll said so and nobody of ours holds it), and our people hear of it
## later. Returns report matters filed.
static func daily(day:int)->Array:
	var filed:Array=[]
	var world:Variant=WorldSimulation.world
	var mc:Variant=WorldSimulation.military
	if world==null or mc==null: return filed
	# No garrison of ours there any more: whoever we held is free again, and
	# the war leader says so once (town_ledger.settle).
	filed.append_array(Ledger.settle_all())
	for pair in Ledger.towns():
		var civ_id:=String(pair[0]); var region_id:=String(pair[1])
		var r:=Ledger.region_ref(civ_id,region_id)
		var l:=Ledger.of(civ_id,region_id)
		_pregnancies_day(civ_id,region_id,l,day)
		var ruin:Dictionary=l.get("ruin",{}) if l.get("ruin") is Dictionary else {}
		if ruin.is_empty(): continue
		var h:=Ledger.hold(civ_id,region_id)
		var ours:=bool(h.ours)
		var held:=bool(h.held)
		if ours and Ledger.present_total(l)<=0: r["resistance"]=0.0
		if not held and ours and (ruin.get("resettle",{}) as Dictionary).is_empty():
			ruin["held"]=false
			if int(ruin.get("left_day",-1))<0: ruin["left_day"]=day
			_schedule_resettle(civ_id,region_id,l,day)
		var rs:Dictionary=ruin.get("resettle",{}) if ruin.get("resettle") is Dictionary else {}
		if rs.is_empty(): continue
		if not bool(rs.get("done",false)) and day>=int(rs.get("day",day+1)):
			rs["done"]=true
			if bool(rs.get("happens",false)) and not held and ours:
				var n:=_resettle(civ_id,region_id,day)
				# The town's record was rebuilt: say so on the ledger it has now.
				var fresh:Dictionary=Ledger.of(civ_id,region_id).get("ruin",{})
				rs=fresh.get("resettle",{}) if fresh.get("resettle") is Dictionary else rs
				rs["done"]=true
				if n>=0: rs["happened"]=true; rs["people"]=n; rs["day"]=day
		if bool(rs.get("happened",false)) and not bool(rs.get("known",false)) and day>=int(rs.get("learn_day",day+1)):
			rs["known"]=true
			filed.append(_heard(civ_id,region_id,rs,day))
	return filed

## Their people come back to live in the ruin: the town is theirs again,
## still broken, with some settlers from their largest town. Returns how
## many came (-1 when it could not happen).
static func _resettle(civ_id:String,region_id:String,day:int)->int:
	var world:Variant=WorldSimulation.world
	var index:int=world._civilization_index(civ_id)
	if index<0: return -1
	var civ:Dictionary=world.civilizations[index]
	var source:=-1
	var best:=0.0
	for i in (civ.strategic_regions as Array).size():
		var sr:Dictionary=civ.strategic_regions[i]
		if String(sr.get("id",""))==region_id or String(sr.get("controller",civ_id))!=civ_id: continue
		if float(sr.get("population",0.0))>best: best=float(sr.get("population",0.0)); source=i
	var r:=Ledger.rng(region_id,day,"resettlers")
	var n:=0
	if source>=0: n=mini(r.randi_range(int(RESETTLERS[0]),int(RESETTLERS[1])),roundi(best*0.2))
	var back:Dictionary=world.abandon_occupied_region(civ_id,region_id)
	if back.has("error"): return -1
	civ=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri>=0:
		var ruined:Dictionary=civ.strategic_regions[ri]
		ruined["damage"]=maxf(0.85,float(ruined.get("damage",0.0)))
		if n>0 and not WorldSimulation.enabled:
			var sri:int=world._region_index(civ,String(civ.strategic_regions[source].id)) if source>=0 else -1
			if sri>=0:
				civ.strategic_regions[sri]["population"]=maxf(0.0,float(civ.strategic_regions[sri].get("population",0.0))-float(n))
				ruined["population"]=float(ruined.get("population",0.0))+float(n)
		civ.strategic_regions[ri]=ruined
		world.civilizations[index]=civ
	return n

## Our people hear the ruin is lived in again: one report, one Chronicle
## line, and the chart shows their town again from what we heard.
static func _heard(civ_id:String,region_id:String,rs:Dictionary,day:int)->Dictionary:
	var world:Variant=WorldSimulation.world
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	var name:=String(region.get("name","the ruin"))
	var people:String=load("res://scripts/map_ownership.gd").people(civ_id)
	var n:=int(rs.get("people",0))
	var parts:=String(preload("res://scripts/hud/era_words.gd").when(int(rs.get("day",day)))).split(" · ")
	var when:=("in the %s of %s" % [parts[1].to_lower(),parts[0]]) if parts.size()==2 else "lately"
	var text:="Hunters from the %s side say %s have come back to live in the ruins of %s%s. They moved in %s; nobody of ours was there to stop them." % [name,people,name,(", about %d of them" % (roundi(float(n)/5.0)*5 if n>=10 else n)) if n>0 else "",when]
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",civ_id,"report",text,day)
	Chronicle.record({"key":"ruin_resettled:%s:%d" % [region_id,int(rs.get("day",day))],"title":("%s Lived In Again" % name).substr(0,70),"text":text,"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	firsthand(civ_id,region_id,day,"hunters' word")
	return matter if matter is Dictionary and not (matter as Dictionary).is_empty() else {"text":text}


# --------------------------------------------------------------------------
# Consequences and words
# --------------------------------------------------------------------------

## Dread and grudges; our reputation; the court's dread of the god.
static func _consequences(civ_id:String,name:String,out:Dictionary,harsh:float,general:Dictionary,day:int)->void:
	var mc:Variant=WorldSimulation.military
	var killed:=int(out.killed); var captives:=int(out.captives); var violated:=int(out.get("violated",0))
	var weight:=clampf(float(killed+captives+violated)/60.0,0.0,1.0)
	if bool(out.spared) or int(out.freed)>0 or String(out.policy) in ["self_rule","equal_citizenship","stewardship"]:
		Hall._shift_relation(civ_id,0.06,-0.04)
		mc._adjust_war_reputation(0.08,0.0,-0.04)
	if harsh<=0.0: return
	var what:="the women of %s your men raped" % name if violated>0 and killed==0 else "the men of %s you put to the sword" % name if killed>0 else ("the women and children of %s you carried off" % name if captives>0 else ("%s, which you burned" % name if bool(out.burned) else "what you did to %s" % name))
	# The people who were struck: hatred, dread and a grudge they keep.
	Hall._shift_relation(civ_id,-clampf(0.12*harsh,0.05,0.4),clampf(0.1*harsh,0.05,0.3))
	DIVINE.add_civ_dread(civ_id,clampf(0.06*harsh+0.12*weight,0.04,0.35))
	preload("res://scripts/rival_rulers.gd").grudge(civ_id,what,clampf(0.5+0.5*harsh,0.5,1.5),"town_fate:%s:%d" % [name,day])
	ForeignDiplomacy.remember(civ_id,"The god's people did this to %s: %s." % [name,_memory(name,out)])
	# Every people that knows us hears of it: dread, and a little less goodwill.
	for civ:Dictionary in WorldSimulation.world.civilizations:
		var other:=String(civ.get("id",""))
		if other==civ_id or other=="player": continue
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		DIVINE.add_civ_dread(other,clampf(0.03*harsh+0.05*weight,0.01,0.12))
		Hall._shift_relation(other,-clampf(0.03*harsh,0.01,0.08),clampf(0.02*harsh,0.0,0.06))
	# Our own record: feared, hated, remembered.
	mc._adjust_war_reputation(0.0,clampf(0.05*harsh+0.1*weight,0.02,0.3),clampf(0.04*harsh+0.08*weight,0.02,0.25))
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	if killed>0 or violated>0:
		metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-clampf(0.01+0.03*weight,0.01,0.04),0.0,1.0)
	if captives>0:
		metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-clampf(0.01+0.02*weight,0.01,0.03),0.0,1.0)
	# The court hears what the god ordered; they fear the god more.
	for person:Dictionary in Hall._officials():
		var pid:=int(person.get("person_id",0))
		if pid<=0: continue
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":clampf(0.015*harsh+0.02*weight,0.01,0.05),"hold_days":60})
	var gpid:=int(general.get("person_id",0))
	if gpid>0:
		GovernmentPeopleSystem.record_person_memory(gpid,"At the god's word my fighters %s." % _memory(name,out),"divine",0.85,{"emotion":"duty","outcome":"town_fate"})


static func _note(name:String,out:Dictionary)->String:
	if bool(out.spared) and int(out.killed)==0 and int(out.captives)==0 and int(out.get("violated",0))==0: return "%s is spared and held." % name
	var bits:PackedStringArray=PackedStringArray()
	if int(out.get("violated",0))>0: bits.append("%s women raped" % _count(int(out.violated))+(", %s died of it" % _count(int(out.violate_deaths)) if int(out.get("violate_deaths",0))>0 else ""))
	if int(out.killed)>0: bits.append("%s killed" % _count(int(out.killed)))
	if int(out.escaped)>0: bits.append("%s got away" % _count(int(out.escaped)))
	if int(out.captives)>0: bits.append("%s captives on the road to %s" % [_count(int(out.captives)),String(WorldSimulation.state.settlement_name)])
	if int(out.moved)>0: bits.append("%s people on the road to %s" % [_count(int(out.moved)),String(WorldSimulation.state.settlement_name)])
	if bool(out.burned): bits.append("the town burned")
	if int(out.tribute)>0: bits.append("%d Food taken" % int(out.tribute))
	if String(out.policy)!="": bits.append(String({"military_rule":"ruled by the spear","self_rule":"left to its own elders","equal_citizenship":"its people made our own","stewardship":"governed as ours","forced_labor":"its people enslaved"}.get(String(out.policy),"a new order")))
	if int(out.reinforced)>0: bits.append("the garrison now %s" % _count(int(out.garrison)))
	if int(out.freed)>0: bits.append("the captives freed")
	if bool(out.left) and not bool(out.burned): bits.append("the garrison coming home")
	if bool(out.left) and bool(out.burned): bits.append("nobody holds the ruins")
	if bits.is_empty(): return "%s: the god's word is carried out." % name
	return "%s: %s." % [name,", ".join(bits)]


static func _title(name:String,out:Dictionary)->String:
	if int(out.killed)>0 and bool(out.burned): return "The Sack of %s" % name
	if int(out.killed)>0: return "The Men of %s Put to the Sword" % name
	if int(out.get("violated",0))>0: return "The Rape of %s" % name
	if int(out.captives)>0 and bool(out.burned): return "%s Burned, Its Women and Children Taken" % name
	if bool(out.burned): return "%s Burned" % name
	if int(out.captives)>0: return "Captives Taken From %s" % name
	if String(out.policy)=="forced_labor": return "%s Enslaved" % name
	if String(out.policy)=="military_rule": return "%s Under the Spear" % name
	if int(out.tribute)>0: return "Tribute From %s" % name
	if int(out.moved)>0: return "People of %s Come to Live Among Us" % name
	if bool(out.left): return "%s Given Back" % name
	return "%s Spared" % name if bool(out.spared) else "The Order for %s" % name


static func _memory(name:String,out:Dictionary)->String:
	var bits:PackedStringArray=PackedStringArray()
	if int(out.get("violated",0))>0: bits.append("raped %s of the women of %s" % [_count(int(out.violated)),name])
	if int(out.killed)>0: bits.append("killed %s of %s" % [_count(int(out.killed)),name])
	if int(out.captives)>0: bits.append("drove %s captives home" % _count(int(out.captives)))
	if bool(out.burned): bits.append("burned %s" % name)
	if int(out.tribute)>0: bits.append("stripped its stores")
	if String(out.policy)=="forced_labor": bits.append("made its people slaves")
	if String(out.policy)=="military_rule": bits.append("ruled it by the spear")
	return " and ".join(bits) if not bits.is_empty() else "held %s" % name


static func _count(n:int)->String:
	## Counted heads: words for a few, figures beyond a dozen.
	return preload("res://scripts/battle_account.gd").count_words(n) if n<=12 else str(n)


static func _days(n:int)->String:
	return "a day" if n<=1 else "%s days" % _count(n)


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)


static func _lower_first(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_lower()+text.substr(1)
