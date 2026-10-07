extends RefCounted
## STANDING: what we are (strengths), how each other people sees us (views)
## and how our own feel about it (pride). docs/STANDING_DESIGN.md.
##
## Every people runs the same code in its own WorldSimulation scope (its own
## state, army, offices and works); only the views OF US held by others are the
## human player's. Everything here is READ from state that already exists: soldiers and their
## readiness, stores, works and treasures, scholars and discoveries, offices,
## roads, and the memories other systems already keep of our deeds (foreign
## dread in divine_regard.gd, respect and resentment in society_exchange.gd,
## grudges in rival_rulers.gd, their rulers' trust in ForeignDiplomacy).
## Nothing is stored, so nothing can drift from the ledger. Every value comes
## with its reasons in plain words, for the court and the Standing page.
##
## Strengths are 0..1 against the age (standing_scale.gd): 0.5 is the typical
## people of the age, 0.8 what its best-documented peoples did, 1.0 the most
## the age has plausibly seen, on a log scale between (a village is not weak
## for lacking an empire's army, and no hoard of one thing fills a strength).
## Views are what one other people feels: 0..1. Envy and Contempt are the two
## dangers read from the views.

const Hall:=preload("res://scripts/audience_hall.gd")
const Rewards:=preload("res://scripts/undertaking_rewards.gd")
const Exchange:=preload("res://scripts/society_exchange.gd")
const Culture:=preload("res://scripts/artifact_culture.gd")
const LIVES_PATH:="res://scripts/court_lives.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
## The built fabric (built_fabric.gd): fine works, walls and stone.
const Fabric:=preload("res://scripts/built_fabric.gd")
## The age's yardstick: what 20%, 50%, 80% and 100% mean for each strength.
const Scale:=preload("res://scripts/standing_scale.gd")

## A trained, ready warrior counts as this many untrained defenders.
const WARRIOR_WEIGHT:=3.0
## Envy and Contempt start to move peoples above these.
const ENVY_RAID_FLOOR:=0.40
const CONTEMPT_FLOOR:=0.3

## The nine strengths in the order the Standing page's rose draws them,
## clockwise from the top: hard power, plenty, soft power, learning, order.
## [id, name, what it is, the rail section that raises it (and its tab),
## that section's name, what raising it costs the people]
const STRENGTHS:=[
	["might","Might","warriors trained and ready to fight","military",0,"Warriors","people out of the fields, and food and arms for them"],
	["endurance","Endurance","how long we could hold out, starved or besieged","economy",0,"Food","stores put by, and the hands to fill them"],
	["wealth","Wealth","goods, materials and treasures we hold","economy",2,"Wealth","makers' hands and materials; plenty draws envy"],
	["reach","Reach","how far our carriers go and how many peoples know us","world",0,"Known World","carriers and scouts away from home"],
	["persuasion","Persuasion","our envoy's skill and how open our ways are","court",0,"The court","a skilled envoy, gifts, and time spent abroad"],
	["splendor","Splendor","great works and treasures others hear of","construction",3,"Landmarks","builders, materials and years"],
	["genius","Genius","what we know against the peoples we know","inquiry",0,"Research","people at research, and food for them"],
	["cunning","Cunning","scouts and watchers: what we find out and keep hidden","world",0,"Known World","scouts' days and sometimes their lives"],
	["order","Order","trust in the chiefs, holding together, a steward's hand","court",0,"The court","able officials, and restraint"],
]
## The six views another people holds of us: [id, name, what it makes them do].
const VIEWS:=[
	["allure","Allure","they want to come to us, trade with us and learn from us"],
	["awe","Awe","they defer to us and bring gifts"],
	["fear","Fear","they remember our wrath and give way"],
	["respect","Respect","they treat us as equals and weigh our word"],
	["trust","Trust","they believe our promises: pacts, trade, marriages"],
	["resentment","Resentment","they want redress, and grudges bring raiders"],
]
## What each strength makes of us when it leads, when it is second, and when
## it is neglected: the words of the Standing page's "what we are".
const LEANING:={"might":"A people of spears","endurance":"A hardy people","wealth":"A people rich in goods","reach":"A far-travelling people","persuasion":"A people of good words","splendor":"A people of great works","genius":"A learned people","cunning":"A watchful people","order":"A well-ordered people"}
const ALSO:={"might":"strong in spears","endurance":"hard to starve out","wealth":"rich in goods","reach":"known far and wide","persuasion":"well spoken","splendor":"rich in works","genius":"learned","cunning":"watchful","order":"orderly"}
const NEGLECT:={"might":"with few spears","endurance":"who could not hold out long","wealth":"with little to trade","reach":"known to few","persuasion":"whose words carry little weight","splendor":"with nothing to show","genius":"slow to learn","cunning":"blind to what others plan","order":"quarrelsome"}

## How long a people remembers what was done to it, against oral memory: a
## people that writes keeps its dread and its grudges twice as long, one that
## prints three times (docs/STANDING_DESIGN.md section 6). Read from what that
## people itself knows.
static func memory_span(civ_id:String)->float:
	var voice:=load("res://scripts/character_voice.gd") as GDScript
	if voice==null or civ_id=="": return 1.0
	var known:Array=voice.call("known_ids",civ_id)
	for id in preload("res://scripts/hud/era_words.gd").STATISTICS:
		if known.has(id): return 3.0
	return 2.0 if (voice.call("era_tags",civ_id) as Array).has("writing") else 1.0

static func _lives()->GDScript:
	return load(LIVES_PATH) as GDScript if ResourceLoader.exists(LIVES_PATH) else null

static func _rivals()->GDScript:
	return load(RIVALS_PATH) as GDScript if ResourceLoader.exists(RIVALS_PATH) else null

static func _day()->int:
	return int(floor(WorldSimulation.state.elapsed_days))

# ------------------------------------------------------------------ strengths

## Our fighting strength in "people who can fight": every grown person defends
## the homes a little, a trained and ready warrior counts WARRIOR_WEIGHT times.
## The same scale war_loop.ratio gives other peoples (their people x readiness).
static func _population()->float:
	return maxf(1.0,float(WorldSimulation.state.population_exact))

static func our_fighting_strength()->float:
	var pop:=_population()
	var warriors:=clampf(_warriors(),0.0,pop)
	var readiness:=_readiness()
	# Behind walls and in stone, every defender counts for more (built_fabric.gd FORT_STRENGTH).
	return maxf(1.0,(pop-warriors)*0.8+warriors*(1.0+WARRIOR_WEIGHT*readiness))*(1.0+Fabric.FORT_STRENGTH*_walls())

## The defences' bonus (military_campaign.gd settlement_defense_snapshot).
static func _walls()->float:
	return maxf(0.0,Fabric.defense_bonus_now())

static func _warriors()->float:
	if WorldSimulation.military==null: return 0.0
	var fielded:=float(WorldSimulation.military.home_army.get("troops",0))
	var trainees:=float(WorldSimulation.military._queued_trainees()) if WorldSimulation.military.has_method("_queued_trainees") else 0.0
	var recruits:=float(WorldSimulation.military.aggregate_recruits)
	return fielded+trainees*0.65+recruits*0.35

static func _readiness()->float:
	if WorldSimulation.military==null: return clampf(float(WorldSimulation.state.simulation_metrics.get("security",0.38)),0.0,1.0)
	return clampf(float(WorldSimulation.military.home_army.get("readiness",WorldSimulation.state.simulation_metrics.get("security",0.38))),0.0,1.0)

## Another people's fighting strength on the same scale (war_loop.ratio's).
static func their_fighting_strength(civ:Dictionary)->float:
	var pop:=maxf(10.0,float(civ.get("population",100.0)))
	var readiness:=clampf(float(civ.get("military_readiness",0.45)),0.2,1.0)
	var warriors:=clampf(float(civ.get("military_population",0.0)),0.0,pop)
	return maxf(1.0,(pop-warriors)*(0.55+readiness*0.3)+warriors*(1.0+WARRIOR_WEIGHT*readiness))

static func strengths()->Dictionary:
	## {id: {value, why}} for Might, Genius, Persuasion, Cunning, Wealth,
	## Splendor, Order, Endurance, Reach (and "_culture", the allure of our
	## culture, for the views). Always read fresh: nothing here can go stale.
	return _reckon_strengths()

## The same nine values (and their parts) without the reasons: another
## people's month, which only the engine reads (their_true, renown, pride,
## the daily systems). Every value is the one strengths() gives; nobody reads
## a computer people's reasons, so they are never written. {id: {value,
## why:"", parts}}.
static func values()->Dictionary:
	var was:=_words
	_words=false
	var out:=_reckon_strengths()
	_words=was
	return out

## Whether the reading in hand writes its reasons (values() turns them off).
static var _words:=true

## Kept for callers and tests from before readings were stored (no-op).
static func forget()->void:
	pass

static func _reckon_strengths()->Dictionary:
	var year:=_year()
	var result:Dictionary={}
	result["might"]=_might(year)
	result["genius"]=_genius(year)
	result["persuasion"]=_persuasion(year)
	result["cunning"]=_cunning(year)
	result["wealth"]=_wealth(year)
	var splendor:=_splendor(year)
	result["_culture"]=float(splendor.get("_culture",0.0))
	result["_beauty"]=float(splendor.get("_beauty",0.0))
	splendor.erase("_culture");splendor.erase("_beauty")
	result["splendor"]=splendor
	result["order"]=_order(year)
	result["endurance"]=_endurance(year)
	result["reach"]=_reach(year)
	return result

## The game year of the people in scope (0 = 5000 BC).
static func _year()->float:
	return maxf(0.0,float(WorldSimulation.state.elapsed_days)/365.0)

## One part of a strength: its reading against the age (0..1), its weight,
## the measure itself and the age's typical measure.
static func _part(id:String,score:float,weight:float,measure:float,anchors:Array)->Dictionary:
	return {"id":id,"score":clampf(score,0.0,1.0),"weight":weight,"measure":measure,"typical":float(anchors[1]) if anchors.size()>1 else 0.5,"high":float(anchors[2]) if anchors.size()>2 else 0.8,"max":float(anchors[3]) if anchors.size()>3 else 1.0}

static func _blend(parts:Array)->float:
	var total:=0.0
	var weights:=0.0
	for p:Dictionary in parts:
		total+=float(p.score)*float(p.weight)
		weights+=float(p.weight)
	return clampf(total/maxf(0.0001,weights),0.0,1.0)

static func _entry(parts:Array,why:String)->Dictionary:
	return {"value":_blend(parts),"why":why,"parts":parts}

## "1.4 in 100" for a share.
static func _per_hundred(share:float)->String:
	var x:=share*100.0
	if x>=9.95: return "%d in 100" % roundi(x)
	return "%.1f in 100" % x

static func _n(x:float)->String:
	if absf(x)>=10.0: return "%d" % roundi(x)
	return "%.1f" % x

## "about twice a typical people of our age (30)": a measure against the age.
static func _vs(measure:float,anchors:Array,typical_words:String="")->String:
	var words:=Scale.compare_words(measure,anchors)
	if words=="": return ""
	return "%s (%s)" % [words,typical_words if typical_words!="" else _n(float(anchors[1]))]

static func _pct(x:float)->String:
	return "%d%%" % roundi(x*100.0)

static func _count_word(n:int)->String:
	return ["no","one","two","three","four","five","six","seven","eight","nine","ten"][n] if n>=0 and n<=10 else str(n)

## MIGHT: the share of the whole people ready to fight (warriors x their
## readiness), walls and stone counting each defender for more, against the
## age (standing_scale.gd might_anchors: the benchmark's defense_labor_share).
static func _might(year:float)->Dictionary:
	var pop:=_population()
	var warriors:=clampf(_warriors(),0.0,pop)
	var readiness:=_readiness()
	var walls:=_walls()
	var lift:=1.0+Fabric.FORT_STRENGTH*walls
	var share:=warriors*readiness/pop*lift
	var a:=Scale.might_anchors(year)
	var parts:=[_part("ready",Scale.score(share,a),1.0,share,a)]
	if not _words: return _entry(parts,"")
	var why:="%d under arms or training, ready %d%%, among %d people: %s ready to fight%s, %s" % [roundi(warriors),roundi(readiness*100.0),roundi(pop),_per_hundred(share),(" with walls and stone (x%.2f)" % lift) if walls>0.005 else "",_vs(share,a,_per_hundred(float(a[1])))]
	return _entry(parts,why)

## GENIUS: what we know against the age (standing_scale.gd known_anchors) and
## how many of us are at research; the most learned people we know is named
## beside it, as far as we know them.
static func _genius(year:float)->Dictionary:
	var s=WorldSimulation.state
	var known:=float(s.known_discoveries.size())
	var a:=Scale.known_anchors(year)
	var scholars:=maxf(0.0,float(s.effective_workers("Knowledge")))
	var share:=scholars/_population()
	var sa:=Scale.anchors(Scale.SCHOLARS,year)
	var parts:=[_part("known",Scale.score(known,a),GENIUS_WEIGHTS.known,known,a),_part("scholars",Scale.score(share,sa),GENIUS_WEIGHTS.scholars,share,sa)]
	if not _words: return _entry(parts,"")
	var why:="%d practices known, %s; %d at research (%s), %s" % [roundi(known),_vs(known,a,"about %d" % roundi(float(a[1]))),roundi(scholars),_per_hundred(share),_vs(share,sa,_per_hundred(float(sa[1])))]
	var rival:=best_known_rival()
	if not rival.is_empty():
		if bool(rival.get("unknown",false)): why+="; we know too little of the peoples we know to say what they know"
		else: why+="; the most learned people we know, %s, %s" % [String(rival.name),String(rival.words)]
	return _entry(parts,why)

const GENIUS_WEIGHTS:={"known":0.6,"scholars":0.4}
const PERSUASION_WEIGHTS:={"envoy":0.3,"openness":0.15,"familiarity":0.1,"treaties":0.15,"gifts":0.15,"abroad":0.15}
const CUNNING_WEIGHTS:={"scout":0.25,"eyes":0.25,"agents":0.15,"caught":0.1,"intel":0.25}
const SPLENDOR_WEIGHTS:={"works":0.55,"culture":0.25,"beauty":0.2}

## What our great works' renown (great_works.gd renown points) adds to
## Splendor now, over having none: the works part read against the age, x its
## weight. The works screens and the dedication say it in these numbers.
static func works_splendor(points:float,year:float=-1.0)->float:
	var a:=Scale.anchors(Scale.WORKS,_year() if year<0.0 else year)
	return SPLENDOR_WEIGHTS.works*(Scale.score(1.0+maxf(0.0,points),a)-Scale.score(1.0,a))

## What the realm's fine works (built_fabric.gd realm_beauty) add to Splendor
## now, over none, and their reading against the age: {splendor, score, typical}.
static func beauty_reading(beauty:float,year:float=-1.0)->Dictionary:
	var y:=_year() if year<0.0 else year
	var a:=Scale.beauty_anchors(y)
	var score:=Scale.score(1.0+10.0*maxf(0.0,beauty),a)
	return {"splendor":SPLENDOR_WEIGHTS.beauty*(score-Scale.score(1.0,a)),"score":score,"typical":float(Scale.anchors(Scale.BEAUTY,y)[1])}

## What walls and stone (the defences' bonus) do for our strengths: every
## defender counts x(1 + FORT_STRENGTH x bonus) in Might and in others'
## reckoning, and the walls are a part of Endurance read against the age:
## {might_factor, endurance, score, typical}.
static func walls_reading(bonus:float,year:float=-1.0)->Dictionary:
	var y:=_year() if year<0.0 else year
	var a:=Scale.anchors(Scale.WALLS,y)
	var score:=Scale.score(maxf(0.0,bonus),a)
	return {"might_factor":1.0+Fabric.FORT_STRENGTH*maxf(0.0,bonus),"endurance":ENDURANCE_WEIGHTS.walls*score,"score":score,"typical":float(a[1])}

## PERSUASION: our envoy's skill, how open our ways are, how well we know
## the peoples we know, the treaties and exchanges we keep, the gifts we give
## and the time our envoys spend abroad. A typical people of the age reads 0.5.
static func _persuasion(year:float)->Dictionary:
	var speaker:=_speaker()
	var envoy:=float(speaker.skill)
	var s=WorldSimulation.state
	var lived:Dictionary=s.societal_values.get("lived",{}) if s.societal_values is Dictionary else {}
	var openness:=clampf((float(lived.get("openness",.5))+float(lived.get("pluralism",.5)))*.5,0,1)
	var familiarity:=_familiarity()
	var fa:=Scale.anchors(Scale.FAMILIARITY,year)
	var kept:=treaties_kept()
	var ta:=Scale.anchors(Scale.TREATIES,year)
	var gifts:=gifts_given()
	var ga:=Scale.anchors(Scale.GIFTS,year)
	var abroad:=envoy_days()
	var ea:=Scale.anchors(Scale.ENVOY_DAYS,year)
	var gift_rate:=float(gifts.per_head_year)
	var days_rate:=float(abroad.days)/_population()*100.0
	var parts:=[_part("envoy",Scale.skill_score(envoy),PERSUASION_WEIGHTS.envoy,envoy,[0.2,Scale.ORDINARY_SKILL,0.8,1.0]),
		_part("openness",openness,PERSUASION_WEIGHTS.openness,openness,[0.2,0.5,0.8,1.0]),
		_part("familiarity",Scale.score(familiarity,fa),PERSUASION_WEIGHTS.familiarity,familiarity,fa),
		_part("treaties",Scale.score(1.0+float(kept.count),ta),PERSUASION_WEIGHTS.treaties,float(kept.count),ta),
		_part("gifts",Scale.score(1.0+20.0*gift_rate,ga),PERSUASION_WEIGHTS.gifts,gift_rate,ga),
		_part("abroad",Scale.score(1.0+days_rate/10.0,ea),PERSUASION_WEIGHTS.abroad,days_rate,ea)]
	if not _words: return _entry(parts,"")
	var bits:PackedStringArray=[]
	bits.append(String(speaker.words))
	bits.append("openness %s" % _pct(openness))
	bits.append("%s treat%s or exchange%s kept" % [_count_word(int(kept.count)),"y" if int(kept.count)==1 else "ies","" if int(kept.count)==1 else "s"])
	bits.append(("gifts worth %s a head a year" % _n(gift_rate)) if gift_rate>0.005 else "no gifts given lately")
	bits.append(("%d envoy-days abroad in five years" % roundi(float(abroad.days))) if float(abroad.days)>=1.0 else "no envoys abroad in five years")
	return _entry(parts,", ".join(bits))

## CUNNING: our chief scout, the scouts and the watch, our agents abroad,
## the spies of theirs we catch and turn, and how well we know the peoples
## we know. A typical people of the age reads 0.5.
static func _cunning(year:float)->Dictionary:
	var s=WorldSimulation.state
	var pop:=_population()
	var scout:=_office_skill("ChiefScout","Knowledge")
	var surveyors:=float(s.population_allocations.get("Survey",0))
	var watch:=float(s.population_allocations.get("Defense",0))
	var eyes:=(surveyors+watch*0.5)/pop
	var sa:=Scale.anchors(Scale.SCOUTS,year)
	var agents:=agents_abroad_count()
	var caught:=spies_caught()
	var intel:=_intel()
	var ia:=Scale.anchors(Scale.INTEL,year)
	var parts:=[_part("scout",Scale.skill_score(scout),CUNNING_WEIGHTS.scout,scout,[0.2,Scale.ORDINARY_SKILL,0.8,1.0]),
		_part("eyes",Scale.score(eyes,sa),CUNNING_WEIGHTS.eyes,eyes,sa),
		_part("agents",Scale.bonus_score(float(agents),AGENTS_HALF),CUNNING_WEIGHTS.agents,float(agents),[0.0,0.0,AGENTS_HALF,AGENTS_HALF*3.0]),
		_part("caught",Scale.bonus_score(float(caught.count),CAUGHT_HALF),CUNNING_WEIGHTS.caught,float(caught.count),[0.0,0.0,CAUGHT_HALF,CAUGHT_HALF*3.0]),
		_part("intel",Scale.score(intel,ia) if intel>=0.0 else Scale.TYPICAL_SCORE,CUNNING_WEIGHTS.intel,intel,ia)]
	if not _words: return _entry(parts,"")
	var bits:PackedStringArray=[]
	bits.append("our chief scout's skill %s%s" % [_pct(scout),"" if scout>0.2 else " (no chief scout named)"])
	bits.append("%d out scouting and %d on the watch (%s, %s)" % [roundi(surveyors),roundi(watch),_per_hundred(eyes),_vs(eyes,sa,_per_hundred(float(sa[1])))])
	bits.append(("%s agent%s abroad" % [_count_word(agents),"" if agents==1 else "s"]) if agents>0 else "no agents abroad")
	if int(caught.count)>0: bits.append("%s of their spies caught or turned in three years" % _count_word(int(caught.count)))
	if intel>=0.0: bits.append("we know the peoples we know %s" % _knowledge_words(intel))
	return _entry(parts,", ".join(bits))

## Agents abroad and spies caught: each this many more lifts the part half
## the way from typical to the most.
const AGENTS_HALF:=2.0
const CAUGHT_HALF:=3.0

static func _knowledge_words(intel:float)->String:
	if intel>=0.6: return "well"
	if intel>=0.35: return "fairly well"
	if intel>=0.2: return "a little"
	return "hardly at all"

## WEALTH: what the people own and can trade, a head, against the age: made
## goods (with coin and weighed metal once known, at what they buy in goods),
## materials in store, and treasures. Food in store is Endurance's alone: a
## granary is not riches to trade. Every town counts (wealth_held).
static func _wealth(year:float)->Dictionary:
	var pop:=_population()
	var held:=wealth_held()
	var worth:=float(held.worth)/pop
	var materials:=float(held.materials)/pop
	var treasures:=float(held.treasure_worth)/pop
	var ga:=Scale.anchors(Scale.GOODS,year)
	var ma:=Scale.anchors(Scale.MATERIALS,year)
	var ta:=Scale.anchors(Scale.TREASURES,year)
	var parts:=[_part("goods",Scale.score(worth,ga),WEALTH_WEIGHTS.goods,worth,ga),_part("materials",Scale.score(materials,ma),WEALTH_WEIGHTS.materials,materials,ma),
		_part("treasures",Scale.score(treasures,ta),WEALTH_WEIGHTS.treasures,treasures,ta)]
	if not _words: return _entry(parts,"")
	var goods_words:="%s goods (about %s a head; a typical people of our age about %s)" % [EraWordsRef.grouped(roundi(float(held.goods))),_n(float(held.goods)/pop),_n(float(ga[1]))]
	if float(held.coin)>=0.5: goods_words="%s goods and %s in %s, worth %s goods together (about %s a head; a typical people of our age about %s)" % [EraWordsRef.grouped(roundi(float(held.goods))),EraWordsRef.grouped(roundi(float(held.coin))),String(held.coin_word),EraWordsRef.grouped(roundi(float(held.worth))),_n(worth),_n(float(ga[1]))]
	var count:=int(held.treasures)
	var treasure_words:=("no treasures" if count==0 else "%s treasure%s worth about %s goods" % [_count_word(count),"" if count==1 else "s",EraWordsRef.grouped(roundi(float(held.treasure_worth)))])
	if float(ta[1])>0.05: treasure_words+=" (%s a head; typical %s)" % [_n(treasures),_n(float(ta[1]))]
	var why:="%s; %s loads of materials a head (typical %s); %s" % [goods_words,_n(materials),_n(float(ma[1])),treasure_words]
	return _entry(parts,why)

const EraWordsRef:=preload("res://scripts/hud/era_words.gd")

## What the people in scope holds, in every town: made goods, materials
## (timber, stone, clay and fibre), coin and weighed metal (once known), and
## treasures, with what the coin and treasures are worth in goods at the
## people's own prices (trade_prices.gd). {goods, materials, coin, coin_word,
## treasures, treasure_worth, worth (goods + coin's worth)}. The same for
## every people, read in its own scope.
static func wealth_held()->Dictionary:
	var s=WorldSimulation.state
	# The place in scope, then every other town's own stores and purses
	# (settlement_model.gd keeps them in its local_resources).
	var places:Array=[s]
	var here:=String(s.resource_settlement_id)
	for record in s.player_settlements:
		if not record is Dictionary or bool((record as Dictionary).get("primary",false)) or String((record as Dictionary).get("id",""))==here: continue
		var local:Variant=(record as Dictionary).get("local_resources",{})
		if local is Dictionary and not (local as Dictionary).is_empty(): places.append(local)
	var goods:=0.0
	var materials:=0.0
	var coin:=0.0
	for place:Variant in places:
		var stock:Variant=place.get("resource_stockpiles")
		if stock is Dictionary:
			goods+=maxf(0.0,_num((stock as Dictionary).get(WEALTH_GOODS,0.0)))
			for resource:String in WEALTH_MATERIALS: materials+=maxf(0.0,_num((stock as Dictionary).get(resource,0.0)))
		# Coin and weighed metal, once the people keep them (economy_system.gd):
		# the households' purses, hoards and mutual aid, and the town's own.
		for field:String in WEALTH_MONEY: coin+=maxf(0.0,_num(place.get(field)))
	# The treasury's coin (realm_purse.gd keeps the realm's one account).
	var purse:Variant=s.realm_purse
	if purse is Dictionary: coin+=maxf(0.0,_num((purse as Dictionary).get("coin",0.0)))
	var prices:=preload("res://scripts/trade_prices.gd")
	var goods_price:=maxf(0.01,prices.in_scope(WEALTH_GOODS))
	var count:=0
	var appraised:=0.0
	var collection:=preload("res://scripts/artifact_collection.gd")
	var exchange:Variant=s.society_exchange
	if exchange is Dictionary and (exchange as Dictionary).get("collections") is Dictionary:
		for item:Variant in ((exchange as Dictionary).collections as Dictionary).values():
			if item is Dictionary and String((item as Dictionary).get("kind",""))=="artifact":
				count+=1
				appraised+=maxf(0.0,float(collection.price(item)))
	var coin_worth:=coin*prices.in_scope("Coin")/goods_price
	return {"goods":goods,"materials":materials,"coin":coin,"coin_word":"coin" if String(s.economy_stage)=="currency" else "weighed metal","treasures":count,"treasure_worth":appraised/goods_price,"worth":goods+coin_worth}

static func _num(value:Variant)->float:
	return float(value) if value is float or value is int else 0.0

const WEALTH_GOODS:="Civilian Goods"
const WEALTH_MATERIALS:=["Timber","Stone","Clay","Fiber Plants"]
## The money a town's people and keepers hold (game_state.gd), in coin.
const WEALTH_MONEY:=["private_currency","currency_hoards","mutual_aid_reserve","public_treasury","weighed_metal_circulation"]
const WEALTH_WEIGHTS:={"goods":0.6,"materials":0.25,"treasures":0.15}
const ENDURANCE_WEIGHTS:={"food":0.45,"water":0.1,"walls":0.2,"health":0.125,"cohesion":0.125}
const ORDER_WEIGHTS:={"legitimacy":0.35,"cohesion":0.2,"administration":0.2,"steward":0.25}
const REACH_WEIGHTS:={"logistics":0.5,"met":0.5}

## SPLENDOR: our great works' renown, our culture's allure and the fine
## works of our towns, against the age. Returns "_culture" and "_beauty" for
## the views as well.
static func _splendor(year:float)->Dictionary:
	# Every standing great work counts, whatever it was built for (its size,
	# outcome and repair); welcoming and far-famed purposes add on top.
	var report:=Culture.allure_report(false)
	var works:=float(report.works)
	var points:=maxf(0.0,float(report.get("works_points",0.0)))
	var culture:=clampf(maxf(0.0,float(report.allure)-works),0.0,1.0)
	# The fine works our builders raise and keep in every town (built_fabric.gd).
	var beauty:=Fabric.realm_beauty()
	var wa:=Scale.anchors(Scale.WORKS,year)
	var ca:=Scale.anchors(Scale.CULTURE,year)
	var ba:=Scale.anchors(Scale.BEAUTY,year)
	var parts:=[_part("works",Scale.score(1.0+points,wa),SPLENDOR_WEIGHTS.works,points,wa),_part("culture",Scale.score_share(culture,ca),SPLENDOR_WEIGHTS.culture,culture,ca),_part("beauty",Scale.score(1.0+10.0*beauty,Scale.beauty_anchors(year)),SPLENDOR_WEIGHTS.beauty,beauty,ba)]
	var why:=""
	if _words:
		var standing_works:=int(report.get("works_standing",0))
		var works_words:="no great work standing yet" if points<0.5 else ("%s, renown %d" % ["lesser monuments and remains that visitors see" if standing_works==0 else ("one great work standing" if standing_works==1 else "%d great works standing" % standing_works),roundi(points)])
		why="%s (a typical people of our age: renown about %d); our culture's allure %s (typical %s); our builders' fine works %s (typical %s)" % [works_words,maxi(0,roundi(float(wa[1])-1.0)),_pct(culture),_pct(float(ca[1])),_pct(beauty),_pct(float(ba[1]))]
	var out:=_entry(parts,why)
	out["_culture"]=clampf(float(report.allure)+beauty*Fabric.BEAUTY_CULTURE,0.0,1.0)
	out["_beauty"]=beauty
	return out

## ORDER: trust in the chiefs, holding together, the hands at administration
## and the steward's own, against the age.
static func _order(year:float)->Dictionary:
	var s=WorldSimulation.state
	var m:Dictionary=s.simulation_metrics
	var legitimacy:=float(m.get("legitimacy",0.5))
	var cohesion:=float(m.get("cohesion",0.5))
	var admin:=float(s.population_allocations.get("Administration",0))/_population()
	var steward:=_office_skill("Steward","Administration")
	var la:=Scale.anchors(Scale.LEGITIMACY,year)
	var ca:=Scale.anchors(Scale.COHESION,year)
	var aa:=Scale.anchors(Scale.ADMINISTRATION,year)
	var parts:=[_part("legitimacy",Scale.score_share(legitimacy,la),ORDER_WEIGHTS.legitimacy,legitimacy,la),_part("cohesion",Scale.score_share(cohesion,ca),ORDER_WEIGHTS.cohesion,cohesion,ca),
		_part("administration",Scale.score(admin,aa),ORDER_WEIGHTS.administration,admin,aa),_part("steward",Scale.skill_score(steward),ORDER_WEIGHTS.steward,steward,[0.2,Scale.ORDINARY_SKILL,0.8,1.0])]
	if not _words: return _entry(parts,"")
	var why:="trust in the chiefs %s and holding together %s (a typical people of our age: %s and %s); %s at administration (typical %s); the steward's skill %s%s" % [_pct(legitimacy),_pct(cohesion),_pct(float(la[1])),_pct(float(ca[1])),_per_hundred(admin),_per_hundred(float(aa[1])),_pct(steward),"" if steward>0.2 else " (no steward named)"]
	return _entry(parts,why)

## ENDURANCE: how long we could hold out, starved or besieged: food and
## water in store, walls, health and holding together, against the age.
static func _endurance(year:float)->Dictionary:
	var s=WorldSimulation.state
	var m:Dictionary=s.simulation_metrics
	var food_days:=maxf(0.0,float(m.get("food_days",0.0)))
	var water_days:=maxf(0.0,float(s.water_metrics.get("days",0.0)))
	var walls:=_walls()
	var health:=float(s.population_health)
	var cohesion:=float(m.get("cohesion",0.5))
	var fa:=Scale.anchors(Scale.STORES,year)
	var wa:=Scale.anchors(Scale.WATER,year)
	var da:=Scale.anchors(Scale.WALLS,year)
	var ha:=Scale.anchors(Scale.HEALTH,year)
	var ca:=Scale.anchors(Scale.COHESION,year)
	var parts:=[_part("food",Scale.score(food_days,fa),ENDURANCE_WEIGHTS.food,food_days,fa),_part("water",Scale.score(water_days,wa),ENDURANCE_WEIGHTS.water,water_days,wa),_part("walls",Scale.score(walls,da),ENDURANCE_WEIGHTS.walls,walls,da),
		_part("health",Scale.score_share(health,ha),ENDURANCE_WEIGHTS.health,health,ha),_part("cohesion",Scale.score_share(cohesion,ca),ENDURANCE_WEIGHTS.cohesion,cohesion,ca)]
	if not _words: return _entry(parts,"")
	var why:="food for %d days, %s; water for %d (typical %d); walls %s (typical %s); health %s" % [roundi(food_days),_vs(food_days,fa),roundi(water_days),roundi(float(wa[1])),_wall_words(walls),_wall_words(float(da[1])),_pct(health)]
	return _entry(parts,why)

static func _wall_words(bonus:float)->String:
	if bonus<0.005: return "none"
	return "+%d%% to every defender" % roundi(bonus*100.0)

## REACH: how far our carriers go and how many peoples know us.
static func _reach(year:float)->Dictionary:
	var met:=0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if bool(civ.get("alive",true)) and int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: met+=1
	var logistics:=float(WorldSimulation.state.simulation_metrics.get("logistics",0.16))
	var la:=Scale.anchors(Scale.LOGISTICS,year)
	var ma:=Scale.anchors(Scale.MET,year)
	var parts:=[_part("logistics",Scale.score_share(logistics,la),REACH_WEIGHTS.logistics,logistics,la),_part("met",Scale.score(1.0+float(met),ma),REACH_WEIGHTS.met,float(met),ma)]
	if not _words: return _entry(parts,"")
	var why:="carrying and hauling %s (a typical people of our age: %s); %s %s met (typical %s)" % [_pct(logistics),_pct(float(la[1])),_count_word(met),"people" if met==1 else "peoples",_n(maxf(0.0,float(ma[1])-1.0))]
	return _entry(parts,why)

## Who carries our word abroad and their Diplomacy: the Envoy once that
## office is open (government stage 4), the Steward (the hearth chief who
## speaks for the people) before it. An open office left empty reads 0.2.
## {skill, words}.
static func _speaker()->Dictionary:
	var government=WorldSimulation.government
	var open:=government!=null and government.has_method("office_is_active") and bool(government.office_is_active("Envoy"))
	if open:
		var envoy:=_office_skill("Envoy","Diplomacy")
		return {"skill":envoy,"words":("our envoy's skill %s%s" % [_pct(envoy),"" if envoy>0.2 else " (the office stands empty)"]) if _words else ""}
	var chief:=_office_skill("Steward","Diplomacy")
	return {"skill":chief,"words":("our chief speaks for us (no envoy's office yet), skill %s" % _pct(chief)) if _words else ""}

static func _office_skill(office:String,skill:String)->float:
	var government=WorldSimulation.government
	var holder:Dictionary=government.officeholder(office) if government!=null and government.has_method("officeholder") else {}
	if holder.is_empty(): return 0.2
	return clampf(float((holder.get("skills",{}) as Dictionary).get(skill,40.0))/100.0,0.0,1.0)

static func _familiarity()->float:
	var total:=0.0
	var count:=0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		total+=float(_ties(String(civ.id)).get("familiarity",0.0))
		count+=1
	return total/float(count) if count>0 else 0.0

## Our ties with a people, read without creating a record (a reading must
## never change the ledger it reads).
static func _ties(civ_id:String)->Dictionary:
	var connections:Variant=(Exchange.data() as Dictionary).get("connections",{})
	if not connections is Dictionary: return {}
	var ties:Variant=(connections as Dictionary).get(Exchange.owner_id(civ_id),{})
	return ties if ties is Dictionary else {}

## How well we know the peoples we know: their contact_intelligence, the mean
## over every people met (0..0.95); -1 when we know nobody.
static func _intel()->float:
	var total:=0.0
	var count:=0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if not bool(civ.get("alive",true)) or int(relation.get("contact_level",0))<2: continue
		total+=clampf(float(relation.get("contact_intelligence",0.0)),0.0,1.0)
		count+=1
	return total/float(count) if count>0 else -1.0

# ------------------------------------------------- the ledgers the arts read

## The people in scope as the shared ledgers name it ("player" for the god's).
static func _owner()->String:
	return String(WorldSimulation.actor_id)

## Treaties in force with the peoples we know (trade, non-aggression, an
## alliance) and the exchanges we kept to the end (trade_pacts.gd): {count,
## in_force, kept}. Read only: the ledgers are never made here.
static func treaties_kept()->Dictionary:
	var in_force:=0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if not bool(civ.get("alive",true)) or int(relation.get("contact_level",0))<2 or bool(relation.get("at_war",false)): continue
		if String(relation.get("treaty","none")) in ["trade","non_aggression","alliance"]: in_force+=1
	var kept:=0
	var book:Variant=ForeignDiplomacy.audiences.get("trade_pacts",{})
	var pacts:Variant=(book as Dictionary).get("pacts",[]) if book is Dictionary else []
	var owner:=_owner()
	if pacts is Array:
		for p in pacts:
			if not p is Dictionary: continue
			# The exchange binds both sides: ours, and theirs with us.
			if owner!="player" and String((p as Dictionary).get("civ_id",""))!=owner: continue
			var status:=String((p as Dictionary).get("status",""))
			if status=="completed" or (status=="active" and int((p as Dictionary).get("miss_p",0))==0 and int((p as Dictionary).get("done",0))>0): kept+=1
	return {"count":in_force+kept,"in_force":in_force,"kept":kept}

## Gifts we gave other peoples (the trade ledger's gifts, envoys' gifts
## included), as a yearly rate a head of our people, the older the less:
## {per_head_year, value}.
const GIFT_RECENT_DAYS:=3*365
static func gifts_given()->Dictionary:
	var trade:Variant=ForeignDiplomacy.audiences.get("trade",{})
	var pairs:Variant=(trade as Dictionary).get("pairs",{}) if trade is Dictionary else {}
	var owner:=_owner()
	var day:=_day()
	var rate:=0.0
	var value:=0.0
	if pairs is Dictionary:
		for k in pairs:
			var p:Variant=(pairs as Dictionary)[k]
			if not p is Dictionary: continue
			var dir:=""
			if String((p as Dictionary).get("a",""))==owner: dir="ab"
			elif String((p as Dictionary).get("b",""))==owner: dir="ba"
			else: continue
			var kinds:Variant=(p as Dictionary).get("kinds",{})
			var row:Variant=(kinds as Dictionary).get(dir+":gift") if kinds is Dictionary else null
			if not row is Dictionary: continue
			var given:=maxf(0.0,float((row as Dictionary).get("value",0.0)))
			var since:=maxi(365,day-maxi(0,int((p as Dictionary).get("met",0))))
			var age:=day-int((row as Dictionary).get("day",day))
			var fresh:=1.0 if age<=GIFT_RECENT_DAYS else (0.5 if age<=GIFT_RECENT_DAYS*2 else 0.25)
			value+=given
			rate+=given/float(since)*365.0*fresh
	return {"per_head_year":rate/_population(),"value":value}

## Envoy-days our people spent abroad in the last five years: envoys on
## missions (CivilizationSystem diplomatic missions, every people's own) and,
## for the god's people, hands lent abroad on an envoy's business.
const ABROAD_WINDOW:=5*365
static func envoy_days()->Dictionary:
	var world=WorldSimulation.world
	var day:=_day()
	var from:=day-ABROAD_WINDOW
	var total:=0.0
	var missions:=0
	var records:Array=[]
	if world!=null and "diplomatic_history" in world: records.append_array(world.diplomatic_history)
	if world!=null and "diplomatic_mission" in world and not (world.diplomatic_mission as Dictionary).is_empty(): records.append(world.diplomatic_mission)
	for r in records:
		if not r is Dictionary: continue
		var start:=int((r as Dictionary).get("depart_day",day))
		var end:=int((r as Dictionary).get("returned_day",mini(day,int((r as Dictionary).get("return_day",day)))))
		var overlap:=mini(end,day)-maxi(start,from)
		if overlap<=0: continue
		total+=float(overlap)*maxf(1.0,float((r as Dictionary).get("personnel",1)))
		missions+=1
	if _owner()=="player": total+=float(preload("res://scripts/lent_hands.gd").away(day))*30.0
	return {"days":total,"missions":missions}

## Our agents abroad now: for the god's people, agents on a watch or a source
## left in their towns (covert_ops.gd) and turned spies sent back as our eyes;
## for another people, its spies on the road to us or among us (the same
## ledger, from their side).
static func agents_abroad_count()->int:
	var covert:Variant=ForeignDiplomacy.audiences.get("covert",{})
	var owner:=_owner()
	var n:=0
	if covert is Dictionary:
		if owner=="player":
			for op in (covert as Dictionary).get("ops",[]):
				if op is Dictionary and String((op as Dictionary).get("stage","")) in ["travelling","in_place"] and String((op as Dictionary).get("kind","")) in ["watch","plant"]: n+=1
		else:
			for spy in (covert as Dictionary).get("incoming",[]):
				if spy is Dictionary and String((spy as Dictionary).get("civ_id",""))==owner: n+=1
	if owner=="player":
		var captives:Variant=ForeignDiplomacy.audiences.get("captives",{})
		if captives is Dictionary:
			for p in (captives as Dictionary).get("prisoners",[]):
				if p is Dictionary and String((p as Dictionary).get("status",""))=="double": n+=1
	return n

## Spies of others caught (and turned) in the last three years: for the god's
## people, theirs our watch took and those won over; for another people, ours
## its watch took (captured_agents.gd abroad).
const CAUGHT_WINDOW:=3*365
static func spies_caught()->Dictionary:
	var owner:=_owner()
	var day:=_day()
	var n:=0
	var turned:=0
	var captives:Variant=ForeignDiplomacy.audiences.get("captives",{})
	if owner=="player":
		var covert:Variant=ForeignDiplomacy.audiences.get("covert",{})
		if covert is Dictionary:
			for c in (covert as Dictionary).get("caught",[]):
				if c is Dictionary and day-int((c as Dictionary).get("day",-99999))<=CAUGHT_WINDOW: n+=1
		if captives is Dictionary:
			for p in (captives as Dictionary).get("prisoners",[]):
				if p is Dictionary and String((p as Dictionary).get("status","")) in ["joined","double"]: turned+=1
	elif captives is Dictionary:
		for a in (captives as Dictionary).get("abroad",[]):
			if a is Dictionary and String((a as Dictionary).get("civ_id",""))==owner and day-int((a as Dictionary).get("day",day))<=CAUGHT_WINDOW: n+=1
	return {"count":n+turned,"caught":n,"turned":turned}

## The most learned people we know, as far as we know them: {civ_id, name,
## known, low, high, exact, words}; {"unknown": true} when we know too little
## of any of them; {} when we know nobody. Their own count (their
## known_discoveries, in their own ledger), seen through our estimate: never
## a false 0.
static func best_known_rival()->Dictionary:
	var best:={}
	var any:=false
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)) or int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		any=true
		var id:=String(civ.id)
		var theirs:=known_of(id)
		if theirs<0: continue
		var est:=estimate(id,"known",float(theirs),true)
		if bool(est.get("unknown",false)): continue
		if best.is_empty() or float(est.value)>float(best.known):
			best={"civ_id":id,"name":String(civ.get("name",id)),"known":float(est.value),"low":float(est.low),"high":float(est.high),"exact":bool(est.exact)}
	if not any: return {}
	if best.is_empty(): return {"unknown":true}
	var ours:=float(WorldSimulation.state.known_discoveries.size())
	var amount:=("%d" % roundi(float(best.known))) if bool(best.exact) else ("about %d (%d to %d, by our watchers)" % [roundi(float(best.known)),roundi(float(best.low)),roundi(float(best.high))])
	best["words"]="knows %s, %s ours" % [amount,Scale.against_words(float(best.known),maxf(1.0,ours))]
	return best

## How many practices another people knows, read from its own ledger (its
## known_discoveries in its own scope); -1 when the world does not simulate it.
static func known_of(civ_id:String)->int:
	var state:Variant=Exchange.owner_state(civ_id)
	if state==null: return -1
	return (state.known_discoveries as Array).size()

# ---------------------------------------------------------------------- views

## How one other people sees us: {known, allure, awe, fear, respect, trust,
## resentment, envy, contempt, strength_ratio, why:{view: text}}. A people that
## has not met us holds no view (known false, all zero).
static func view_of(civ_id:String,our:Dictionary={})->Dictionary:
	if String(WorldSimulation.actor_id)!="player": return {"known":false,"allure":0.0,"awe":0.0,"fear":0.0,"respect":0.0,"trust":0.0,"resentment":0.0,"envy":0.0,"contempt":0.0,"strength_ratio":1.0,"why":{}}
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if not civ.is_empty() else {}
	var empty:={"known":false,"allure":0.0,"awe":0.0,"fear":0.0,"respect":0.0,"trust":0.0,"resentment":0.0,"envy":0.0,"contempt":0.0,"strength_ratio":1.0,"why":{}}
	if civ.is_empty() or int(relation.get("contact_level",0))<2: return empty
	if our.is_empty(): our=strengths()
	var why:Dictionary={}
	# Might as they see it: ours over theirs, on one scale.
	var ours:=our_fighting_strength()
	var theirs:=their_fighting_strength(civ)
	# Bound with others against us, they weigh us against all of them.
	var league:=load("res://scripts/fear_league.gd") as GDScript
	if league!=null and bool(league.call("is_member",civ_id)): theirs=maxf(theirs,float(league.call("combined_strength")))
	var ratio:=ours/maxf(1.0,theirs)
	var might_term:=clampf((ratio-0.8)/1.6,0.0,1.0)
	# Works they have heard of, and what we know that they do not.
	var heard:=clampf(Rewards.diplomatic_bonus(WorldSimulation.state,civ_id,_day())/0.20,0.0,1.0)
	# They know their own learning (their known_discoveries, in their own
	# ledger); a people the world does not simulate counts as a typical one.
	var counted:=known_of(civ_id)
	var their_known:=float(counted) if counted>=0 else float(Scale.known_anchors(_year())[1])
	var our_known:=float(WorldSimulation.state.known_discoveries.size())
	var lead:=clampf((our_known-their_known)/maxf(20.0,maxf(our_known,their_known)),-1.0,1.0)
	var awe:=clampf(might_term*0.45+heard*0.35+maxf(0.0,lead)*0.35,0.0,1.0)
	why["awe"]="our fighting strength %s theirs%s%s" % [_ratio_words(ratio)," · works of ours they have heard of" if heard>0.05 else "",_lead_words(civ_id,our_known,their_known) if lead>0.05 else ""]
	var lives:=_lives()
	var fear:=float(lives.call("rival_dread",civ_id)) if lives!=null else 0.0
	why["fear"]="what they remember of our wrath and harm" if fear>0.05 else "no harm done to them"
	# Allure: what our name draws by itself (renown: works, culture, plenty,
	# learning, order, good words), a lead in learning they can see, and our
	# warbands at a tense border menacing them.
	var tension:=clampf(float(relation.get("border_tension",0.0)),0.0,1.0)
	var menace:=maxf(0.0,float(our.might.value)-MENACE_FROM)*tension*BORDER_MENACE
	var drawn:=renown(our)
	var allure:=clampf(float(drawn.allure)+maxf(0.0,lead)*0.1-menace,0.0,1.0)
	why["allure"]="%s%s" % [String(drawn.allure_why),(" · our warbands at a tense border menace them (−%d)" % roundi(menace*100.0)) if menace>0.005 else ""]
	var ties:=_ties(civ_id)
	var respect:=clampf(float(ties.get("respect",0.0))+heard*0.25+maxf(0.0,lead)*0.2+clampf(ratio-0.7,0.0,1.0)*0.2+float(our.order.value)*0.15+float(our.get("_beauty",0.0))*Fabric.BEAUTY_RESPECT,0.0,1.0)
	why["respect"]="their scholars' and travellers' regard, works that stand, our order"
	var rivals:=_rivals()
	var character:Dictionary=rivals.call("rival_character",civ_id) if rivals!=null else {}
	var leader:=ForeignDiplomacy.leader(civ_id)
	# How our envoys carry themselves (persuasion: the messenger's skill, our
	# openness) moves their trust in our word by up to 10 points either way.
	var persuaded:=(float((our.get("persuasion",{}) as Dictionary).get("value",0.5))-0.5)*0.2
	var trust:=clampf(0.5+float(leader.get("trust",0.0))*0.5+(0.15 if String(relation.get("treaty","none")) not in ["none","","war"] else 0.0)-(0.3 if bool(relation.get("at_war",false)) else 0.0)+persuaded,0.0,1.0)
	why["trust"]="their ruler's trust in our word%s%s" % [(" · a treaty between us" if String(relation.get("treaty","none")) not in ["none","","war"] else ""),(" · our envoys' persuasion %+d" % roundi(persuaded*100.0)) if absf(persuaded)>=0.01 else ""]
	var grudge:=float(character.get("grudge_weight",0.0))
	# Open grudges (their ruler's) over what their people still tell of us.
	var told:=float(preload("res://scripts/deeds.gd").resentment(civ_id))
	var resentment:=clampf(float(ties.get("resentment",0.0))+grudge*0.5+told*0.6,0.0,1.0)
	why["resentment"]=("grudges held against us" if grudge>0.05 else "")+(" · " if grudge>0.05 and told>0.05 else "")+("what they still tell of us" if told>0.05 else "") if resentment>0.05 else "no grudge held"
	# The dangers: rich and not feared is raided; weak and unrespected is tested.
	# Envy grows with our plenty and more with how far it passes theirs (their
	# own month's reading; a people not simulated counts as a typical one).
	var our_wealth:=float(our.wealth.value)
	var their_wealth:=their_reading_value(civ_id,"wealth")
	var richer:=maxf(0.0,our_wealth-their_wealth)
	var envy:=clampf((our_wealth*ENVY_PLENTY+richer*ENVY_RICHER+heard*0.4)*(1.0-awe)*(1.0-trust*0.5)*(1.0-fear*0.5),0.0,1.0)
	why["envy"]="they see our goods and works%s%s" % [_plenty_words(civ_id,our_wealth,their_wealth) if richer>0.05 else ""," and too few to guard them" if awe<0.35 else ""]
	var contempt:=clampf((1.0-respect)*clampf(1.25-ratio,0.0,1.0)*(1.0-fear*0.6),0.0,1.0)
	why["contempt"]="our fighting strength %s theirs" % _ratio_words(ratio)
	return {"known":true,"allure":allure,"awe":awe,"fear":fear,"respect":respect,"trust":trust,"resentment":resentment,"envy":envy,"contempt":contempt,"strength_ratio":ratio,"why":why}

## " · we know about 90 things they do not", from our estimate of what they
## know (the same estimate the Standing page shows); "" when we cannot say.
static func _lead_words(civ_id:String,ours:float,theirs:float)->String:
	var est:=estimate(civ_id,"known",theirs,true)
	if bool(est.get("unknown",false)): return ""
	var lead:=roundi(ours-float(est.value))
	if lead<=0: return ""
	return (" · we know %d things they do not" if bool(est.exact) else " · we know about %d things they do not, by our watchers' reckoning") % lead

## " (our plenty 76% against their about 48%)", their plenty from our
## estimate of them; " (our plenty 76%)" when we cannot say theirs.
static func _plenty_words(civ_id:String,ours:float,theirs:float)->String:
	var est:=estimate(civ_id,"wealth",theirs)
	if bool(est.get("unknown",false)): return " (our plenty %d%%)" % roundi(ours*100.0)
	return " (our plenty %d%% against their %s)" % [roundi(ours*100.0),estimate_words(est)]

static func _ratio_words(ratio:float)->String:
	if ratio>=3.0: return "is several times"
	if ratio>=1.8: return "is about twice"
	if ratio>=1.25: return "is greater than"
	if ratio>=0.8: return "matches"
	if ratio>=0.5: return "is below"
	return "is a fraction of"

## Every people we have met, with its view of us.
static func views()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if String(WorldSimulation.actor_id)!="player": return result
	_begin_reading()
	var our:=strengths()
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)): continue
		var v:=view_of(String(civ.id),our)
		if not bool(v.known): continue
		v["civ_id"]=String(civ.id)
		v["civ_name"]=String(civ.get("name",civ.id))
		result.append(v)
	_end_reading()
	return result

# ---------------------------------------------------------------------- pride

## Our own people's pride in who they are: the splendour they live among and
## the awe and allure a people like theirs commands. The same for every people,
## computer-run or not: read from its own strengths (its works, might,
## learning, plenty, order and culture), never from who happens to have met it.
## {value, why, awe, allure}. 0.5 is ordinary: a typical people of the age is
## neither proud nor ashamed. `seen` is kept for callers.
static func pride(our:Dictionary={},_seen:Array=[])->Dictionary:
	if our.is_empty(): our=strengths()
	var command:=renown(our)
	var value:=clampf(0.5+(float(our.splendor.value)-0.5)*PRIDE_SPLENDOR+(float(command.awe)-AWE_ORDINARY)*PRIDE_AWE+(float(command.allure)-ALLURE_ORDINARY)*PRIDE_ALLURE,0.0,1.0)
	var words:PackedStringArray=[]
	if float(our.splendor.value)>=0.6: words.append("the works and treasures we live among, finer than most of the age")
	elif float(our.splendor.value)<0.4: words.append("works and treasures poorer than most of the age")
	else: words.append("works and treasures like most peoples of the age")
	if float(command.awe)>=AWE_ORDINARY+0.1: words.append("the awe our might and works command")
	if float(command.allure)>=ALLURE_ORDINARY+0.1: words.append("the pull of our plenty and our ways")
	return {"value":value,"awe":float(command.awe),"allure":float(command.allure),"why":", ".join(words)}

## What a reading of 1 above the typical in each moves pride.
const PRIDE_SPLENDOR:=0.3
const PRIDE_AWE:=0.25
const PRIDE_ALLURE:=0.15
## The awe a typical people of the age commands by what it is.
const AWE_ORDINARY:=0.25

## The awe and allure a people commands by what it is, before anyone in
## particular sees it (view_of adds each observer's own memories and
## strength). Each strength is read against the typical people of the age
## (0.5): a typical people commands AWE_ORDINARY and ALLURE_ORDINARY. Might,
## works and learning awe; works, culture, plenty, learning, good order and
## good words draw; warbands past the ordinary put people off.
## {awe, allure, allure_why}.
static func renown(our:Dictionary={})->Dictionary:
	if our.is_empty(): our=strengths()
	var might:=float(our.might.value)
	var genius:=float(our.genius.value)
	var splendor:=float(our.splendor.value)
	var wealth:=float(our.wealth.value)
	var order:=float(our.order.value)
	var persuasion:=float((our.get("persuasion",{}) as Dictionary).get("value",0.5))
	var culture:=_culture_score(our)
	var awe:=clampf(AWE_ORDINARY+(might-0.5)*0.45+(splendor-0.5)*0.35+(genius-0.5)*0.3,0.0,1.0)
	var menace:=maxf(0.0,might-MENACE_FROM)*RENOWN_MENACE
	var allure:=clampf(ALLURE_ORDINARY+(splendor-0.5)*0.2+(culture-0.5)*0.2+(wealth-0.5)*0.2+(genius-0.5)*0.1+(order-0.5)*0.1+(persuasion-0.5)*PERSUASION_ALLURE-menace,0.0,1.0)
	var bits:PackedStringArray=[]
	for pair:Array in [["plenty",wealth],["culture",culture],["works",splendor],["learning",genius],["order",order],["good words",persuasion]]:
		var v:=float(pair[1])
		if v>=0.6: bits.append("our %s draws them" % String(pair[0]))
		elif v<=0.35: bits.append("our %s does not" % String(pair[0]))
	if menace>0.005: bits.append("our warbands put them off (−%d)" % roundi(menace*100.0))
	return {"awe":awe,"allure":allure,"allure_why":("; ".join(bits)) if not bits.is_empty() else "nothing about us draws them more than any people of the age"}

## The culture part of our splendor (its reading against the age); a reading
## from before the parts were kept counts as typical.
static func _culture_score(our:Dictionary)->float:
	for part in (our.get("splendor",{}) as Dictionary).get("parts",[]):
		if part is Dictionary and String((part as Dictionary).get("id",""))=="culture": return float((part as Dictionary).score)
	return 0.5

## Might past this reading menaces would-be newcomers and neighbours.
const MENACE_FROM:=0.5
## How much each point of might past MENACE_FROM takes from allure: by itself,
## and again at a tense border (x the tension).
const RENOWN_MENACE:=0.15
const BORDER_MENACE:=0.3
## Persuasion's share in our allure: good words draw people to us.
const PERSUASION_ALLURE:=0.15
## Envy: our plenty, and how far it passes theirs. With ENVY_RAID_FLOOR
## 0.40, a people as rich as the player's at year 75 (Wealth 76%: 248 days of
## food), with few under arms and twelve neighbours met, draws about one envy
## raid in three years; a typical people none; the richest the age has seen
## (Wealth 90%), unguarded, about one a year, and guarded as a typical people
## fewer (the PR's table).
const ENVY_PLENTY:=0.6
const ENVY_RICHER:=0.6

# -------------------------------------------------------- read by daily systems

## The month's reading of might and pride, stored in the people's own metrics
## (saved with them): the daily systems that read them (attraction, cohesion
## and legitimacy targets) must not rebuild every people's view each day, and a
## reading kept with the state can never belong to another world or save.
## ConsequenceEngine.process_day calls this once a month.
static func record_monthly()->void:
	# Only the god's people reads its own reasons (the Standing page, the
	# court); another people's month is values only, read on its officials as
	# its own day last settled them.
	var ours:=String(WorldSimulation.actor_id)=="player"
	_begin_reading(not ours)
	_record_monthly(ours)
	_end_reading()

## One reading of every view of us shares what does not change while it is
## read: our people's own dread (court_lives.gd begin_reading), and the roll
## of officials, reconciled once at the start (GovernmentPeopleSystem
## initialize, as its own day does for its lookups) instead of again for
## every officeholder each view asks after.
static var _reading_depth:=0
static var _reading_government:Object=null
static var _reading_was_initializing:=false
## `settled`: the roll is read as the people's own day last reconciled it
## (GovernmentPeopleSystem.process_day, every day it steps), without
## reconciling it again: another people's month, which must not change the
## ledger it reads. A government not yet founded is founded as before.
static func _begin_reading(settled:bool=false)->void:
	if _reading_depth==0:
		var government=WorldSimulation.government
		if government!=null and "initializing" in government and not bool(government.initializing):
			if not settled or not "people" in government or (government.people as Array).is_empty():government.initialize()
			_reading_government=government
			_reading_was_initializing=bool(government.initializing)
			government.initializing=true
	_reading_depth+=1
	var lives:=_lives()
	if lives!=null:lives.call("begin_reading")
static func _end_reading()->void:
	_reading_depth=maxi(0,_reading_depth-1)
	if _reading_depth==0 and _reading_government!=null:
		if is_instance_valid(_reading_government):_reading_government.initializing=_reading_was_initializing
		_reading_government=null
	var lives:=_lives()
	if lives!=null:lives.call("end_reading")

static func _record_monthly(ours:bool=true)->void:
	var our:=strengths() if ours else values()
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	for row:Array in STRENGTHS: metrics["standing_"+String(row[0])]=float((our[String(row[0])] as Dictionary).value)
	# The day of the reading: another people's month is read from here, and
	# a reading this old is read again (their_reading).
	metrics["standing_day"]=float(_day())
	var command:=renown(our)
	metrics["standing_awe"]=float(command.awe)
	metrics["standing_allure"]=float(command.allure)
	metrics["standing_pride"]=float(pride(our).value)
	# What our people still tell of their god's deeds (deeds.gd): the love and
	# dread the god itself earned, beyond the ordinary moods of a court. Only
	# the god's people hold a god in love or dread, and a god who has done
	# nothing worth telling is neutral, so no people gains or loses by default
	# (another people's month reads neutral too).
	if String(WorldSimulation.actor_id)=="player":
		var told:Dictionary=preload("res://scripts/deeds.gd").home()
		metrics["standing_love"]=float(told.love)
		metrics["standing_dread"]=float(told.dread)
	# How many peoples we know are moved against us (the rail's Standing badge):
	# only the god's people is seen by the others (views), so another's is 0.
	metrics["standing_dangers"]=float(danger_count(our)) if ours else 0.0

## Peoples we know who are moved against us now: envy or contempt past their
## floors, a grudge heavy enough to raid, or a league against us.
static func danger_count(our:Dictionary={})->int:
	var count:=0
	var league:=load("res://scripts/fear_league.gd") as GDScript
	var war:=load("res://scripts/war_loop.gd") as GDScript
	_begin_reading()
	for v:Dictionary in views():
		var id:=String(v.civ_id)
		var moved:=float(v.envy)>ENVY_RAID_FLOOR or float(v.contempt)>CONTEMPT_FLOOR
		if not moved and war!=null: moved=float(war.call("grudge_raid_chance",id))>0.0
		if not moved and league!=null: moved=bool(league.call("is_member",id))
		if moved: count+=1
	_end_reading()
	return count

static func monthly()->Dictionary:
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	return {"might":float(metrics.get("standing_might",0.0)),"pride":float(metrics.get("standing_pride",0.5)),"allure":float(metrics.get("standing_allure",ALLURE_ORDINARY)),"awe":float(metrics.get("standing_awe",0.0)),
		"love":float(metrics.get("standing_love",LOVE_ORDINARY)),"dread":float(metrics.get("standing_dread",0.0)),
		"persuasion":float(metrics.get("standing_persuasion",0.5)),"cunning":float(metrics.get("standing_cunning",0.5))}

## How much a target's fighting strength against ours holds a ruler back from
## declaring war on it: positive when they are stronger (awe of their might),
## negative when they are much weaker (contempt emboldens). The same for every
## ruler, read in its own scope; war decisions add it to other deterrence.
static func war_deterrence(target:Dictionary)->float:
	var ratio:=their_fighting_strength(target)/our_fighting_strength()
	return clampf((ratio-1.0)*0.12,-0.12,0.18)

## Allure an ordinary people commands (a plain village's culture and plenty).
const ALLURE_ORDINARY:=0.25

## THE GOD'S PEOPLE, LOVING OR AFRAID, for what the god has done (deeds.gd:
## love and dread still told at the hearths, 0 when nothing is). Love draws
## families in and binds them, and a remembered cruelty (negative love) does
## the reverse; dread drives families off and frays them once it runs high,
## though it props up the chiefs' word (people obey what they fear). Shares
## a month at full love or full dread (x100 for points of 100).
const LOVE_ORDINARY:=0.0
const LOVE_DRAW:=0.08
const LOVE_BIND:=0.05
const LOVE_OBEY:=0.03
const DREAD_DRIVE_OFF:=0.08
const DREAD_FRAYS:=0.15
const DREAD_FRAY:=0.08
const DREAD_OBEY:=0.03

## What our people's love and dread of the god do this month, as shares
## (multiply by 100 for points): {draw, bind, obey_love, drive_off, fray,
## obey_dread}.
static func god_effects(m:Dictionary={})->Dictionary:
	if m.is_empty(): m=monthly()
	var love:=float(m.get("love",LOVE_ORDINARY))-LOVE_ORDINARY
	var dread:=float(m.get("dread",0.0))
	return {"draw":love*LOVE_DRAW,"bind":love*LOVE_BIND,"obey_love":love*LOVE_OBEY,
		"drive_off":-dread*DREAD_DRIVE_OFF,"fray":-maxf(0.0,dread-DREAD_FRAYS)*DREAD_FRAY,"obey_dread":dread*DREAD_OBEY}

## Our warbands menace would-be newcomers; pride keeps our own people; allure
## draws others in.
static func attraction_shift()->float:
	var m:=monthly()
	var god:=god_effects(m)
	return -maxf(0.0,float(m.might)-MENACE_FROM)*ATTRACTION_MENACE+(float(m.pride)-0.5)*0.08+(float(m.allure)-ALLURE_ORDINARY)*0.08+persuasion_draw(float(m.persuasion))+float(god.draw)+float(god.drive_off)

## What might past MENACE_FROM takes from how much families want to join us
## and stay, a month (a war-minded people at 0.85 loses about 5.6 points).
const ATTRACTION_MENACE:=0.16

## Pride lifts how well the people hold together and trust their chiefs, a little.
static func cohesion_shift()->float:
	var m:=monthly()
	var god:=god_effects(m)
	return (float(m.pride)-0.5)*0.06+float(god.bind)+float(god.fray)

static func legitimacy_shift()->float:
	var m:=monthly()
	var god:=god_effects(m)
	return (float(m.pride)-0.5)*0.04+float(god.obey_love)+float(god.obey_dread)

## How far pride forgives the chiefs: the share by which the blame for
## unpopular orders, constant change and failed aims is lightened. A proud
## people forgives up to 30%; one ashamed of itself blames up to 20% more.
static func forgiveness()->float:
	return clampf((float(monthly().pride)-0.5)*0.8,-0.2,0.3)

## Share of the people under arms (trained, training or called up) that
## households carry without complaint; beyond it, levies are resented.
const LEVY_EASY_SHARE:=0.05

## How much a heavy levy weighs on the people, 0..: the share under arms past
## LEVY_EASY_SHARE (fields without hands, sons away). Read the same way for
## every people from its own army.
static func levy_burden()->float:
	return maxf(0.0,_warriors()/_population()-LEVY_EASY_SHARE)

## The blame multiplier the daily systems apply (1 - forgiveness).
static func blame()->float:
	return 1.0-forgiveness()

# ------------------------------------------------ read by the Standing page

## What the shape of our strengths makes of us, in plain words:
## {id, words, top, second, low, mean, spread, lopsided}. id is the leading
## strength's id, "balanced" or "small".
static func posture(our:Dictionary={})->Dictionary:
	if our.is_empty(): our=strengths()
	var ranked:Array=[]
	for row:Array in STRENGTHS: ranked.append({"id":String(row[0]),"name":String(row[1]),"value":float((our[String(row[0])] as Dictionary).value)})
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.value)>float(b.value))
	var top:Dictionary=ranked[0]
	var second:Dictionary=ranked[1]
	var low:Dictionary=ranked[-1]
	var total:=0.0
	for entry:Dictionary in ranked: total+=float(entry.value)
	var spread:=float(top.value)-float(low.value)
	var id:=String(top.id)
	var words:=""
	if float(top.value)<0.3:
		id="small"
		words="A small people, not yet strong in anything"
	elif spread<0.3:
		id="balanced"
		words="A balanced people: nothing stands far above the rest, nothing is left undone"
	else:
		words=String(LEANING[top.id])
		if float(second.value)>=0.45 and float(second.value)>=float(top.value)-0.25: words+=", "+String(ALSO[second.id])
		if float(low.value)<0.25: words+=", "+String(NEGLECT[low.id])
	return {"id":id,"words":words+".","top":top,"second":second,"low":low,"mean":total/float(ranked.size()),"spread":spread,"lopsided":spread>=0.55}

## One sentence of how a people sees us, from its strongest feeling and the
## dangers it holds.
static func view_words(v:Dictionary)->String:
	if not bool(v.get("known",false)): return "They have not met us."
	var lead:=""
	var best:=0.2
	for pair:Array in [["allure","They are drawn to us"],["awe","They hold us in awe"],["fear","They fear us"],["respect","They respect us"],["trust","They trust our word"],["resentment","They resent us"]]:
		if float(v.get(String(pair[0]),0.0))>best:
			best=float(v.get(String(pair[0]),0.0))
			lead=String(pair[1])
	var parts:PackedStringArray=[]
	parts.append((lead+".") if lead!="" else "They hardly know what to make of us.")
	if float(v.get("envy",0.0))>ENVY_RAID_FLOOR: parts.append("They eye our stores.")
	if float(v.get("contempt",0.0))>CONTEMPT_FLOOR: parts.append("They think us easy to push.")
	elif float(v.get("resentment",0.0))>=0.4 and not lead.begins_with("They resent"): parts.append("They hold a grudge.")
	return " ".join(parts)

## "about 2 in 100 each month" for a monthly chance.
static func monthly_odds_words(chance:float)->String:
	if chance<=0.0: return "none"
	if chance>=0.0095: return "about %d in 100 each month" % maxi(1,roundi(chance*100.0))
	return "about 1 in %d each month" % maxi(100,roundi(1.0/chance/50.0)*50)

## "1.8 times as often" or "half as often" against a people that feels
## nothing either way about us.
static func times_words(weight:float)->String:
	if weight>=1.05: return "%.1f times as often" % weight
	if weight<=0.55: return "half as often or less"
	return "less often (%.1f times)" % weight

## What this people's view makes it do, with the engine's own odds and
## weights: [{id, tone ("danger", "good", "calm"), words, detail}].
static func consequences(civ_id:String,v:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if not bool(v.get("known",false)): return out
	# What they mean to do about us at last: bow, or come with everything.
	var answer:=load("res://scripts/world_answer.gd") as GDScript
	if answer!=null: out.append_array(answer.call("standing_rows",civ_id,v))
	var league:=load("res://scripts/fear_league.gd") as GDScript
	if league!=null and bool(league.call("is_member",civ_id)):
		var others:PackedStringArray=[]
		for id in league.call("members"):
			if String(id)!=civ_id: others.append(String(ForeignDiplomacy.civilization(String(id)).get("name",id)))
		out.append({"id":"league","tone":"danger","words":"Bound with %s against us, for fear of us" % " and ".join(others),"detail":"They weigh our strength against all of theirs together, back each other's raids and demands (%.1f times as often) and share every grudge." % float(league.get_script_constant_map().get("RAID_BACKING",1.5))})
	var war:=load("res://scripts/war_loop.gd") as GDScript
	if war!=null:
		var grudge:=float(war.call("grudge_raid_chance",civ_id))
		if grudge>0.0: out.append({"id":"grudge","tone":"danger","words":"Raiders to settle an old grudge: %s" % monthly_odds_words(grudge),"detail":"Their ruler's grudges weigh heavy enough to send raiders without a new quarrel."})
		var raid:=float(war.call("envy_raid_chance",civ_id,float(v.get("envy",0.0))))
		if raid>0.0: out.append({"id":"envy","tone":"danger","words":"Raiders for our goods: %s" % monthly_odds_words(raid),"detail":"Envy %d%%: %s." % [roundi(float(v.envy)*100.0),String((v.get("why",{}) as Dictionary).get("envy",""))]})
	var lives:=_lives()
	if lives!=null:
		for row:Array in [["tribute_demand","Demands for tribute and tests of our resolve","danger"],["redress_demand","Demands to right old wrongs","danger"],["gift_goods","Gifts and offers of peace","good"],["trade_offer","Offers of trade and pacts","good"]]:
			var weight:=float(lives.call("standing_weight",String(row[0]),civ_id,v))
			if absf(weight-1.0)<0.15: continue
			var tone:=String(row[2])
			if weight<1.0: tone="calm" if tone=="danger" else "danger"
			out.append({"id":String(row[0]),"tone":tone,"words":"%s: %s" % [String(row[1]),times_words(weight)],"detail":"When their envoys come, against a people that feels nothing either way about us."})
	return out

## What pride and menace do at home this month, in points of 100:
## {attraction, cohesion, legitimacy, menace}.
static func home_effects()->Dictionary:
	var m:=monthly()
	var god:=god_effects(m)
	return {"attraction":((float(m.pride)-0.5)+(float(m.allure)-ALLURE_ORDINARY))*8.0+persuasion_draw(float(m.persuasion))*100.0+(float(god.draw)+float(god.drive_off))*100.0,"cohesion":cohesion_shift()*100.0,"legitimacy":legitimacy_shift()*100.0,"menace":-maxf(0.0,float(m.might)-MENACE_FROM)*ATTRACTION_MENACE*100.0,"persuasion_draw":persuasion_draw(float(m.persuasion))*100.0,"forgiveness":forgiveness(),"levy":levy_burden(),"under_arms":_warriors()/_population(),
		# What their love and dread of the god do, in points of 100 (god_effects).
		"god":{"draw":float(god.draw)*100.0,"bind":float(god.bind)*100.0,"obey_love":float(god.obey_love)*100.0,"drive_off":float(god.drive_off)*100.0,"fray":float(god.fray)*100.0,"obey_dread":float(god.obey_dread)*100.0},
		# What the levy costs, as ConsequenceEngine's targets take it.
		"levy_cohesion":levy_burden()*60.0,"levy_trust":levy_burden()*40.0*blame()}

## Whether the people in scope is due its month's reading: 30 days or more
## since its last (standing_day), or none yet, or a calendar set back. A
## computer people steps several days at once (day_span.gd), so a reading on
## day%30 alone would miss most of its months.
const READING_EVERY:=30
static func reading_due()->bool:
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	if not metrics.has("standing_day") or not metrics.has("standing_pride"): return true
	var since:=int(WorldSimulation.state.elapsed_days)-int(float(metrics.standing_day))
	return since>=READING_EVERY or since<0

# ------------------------------------------------ other peoples, as we know them

## Another people's month's reading is read from their own ledger (their
## simulation_metrics, written by their own record_monthly in their own
## scope); one older than this is reckoned again in their scope.
const READING_STALE_DAYS:=45
## Below this certainty we can say nothing of them: "unknown", never a false 0.
const UNKNOWN_BELOW:=0.1
## How far either side an estimate of one of their readings runs (points of
## 100, or a share of a count) when we hardly know them: x (1 - certainty).
const ESTIMATE_WIDEST:=0.4
## Cunning's hand in how sure we are: a reading of 1 adds this, 0 takes it.
const CUNNING_CERTAINTY:=0.3
## An agent of ours on watch among them, or a source in their town (and for
## another people, a spy of theirs among us): at least this sure.
const EYES_CERTAINTY:=0.75
## One estimate a season: the same until new word comes.
const ESTIMATE_SEASON:=91

## Our own month's reading of one of our strengths (0.5 before the first).
static func own_art(id:String)->float:
	return clampf(float(WorldSimulation.state.simulation_metrics.get("standing_"+id,0.5)),0.0,1.0)

## Another people's (owner's) month's reading of one strength: 0.5 when the
## world does not simulate them.
static func art_of(owner:String,id:String)->float:
	var state:Variant=Exchange.owner_state(owner)
	if state==null: return 0.5
	return clampf(float(state.simulation_metrics.get("standing_"+id,0.5)),0.0,1.0)

## Their true strengths, {id: value}: their own month's reading, or reckoned
## again in their own scope when it is missing or old. Read only: the world is
## never made or remade by a reading (as civilization_combat._away). {} when
## the world does not simulate them.
static func their_true(civ_id:String)->Dictionary:
	var state:Variant=Exchange.owner_state(civ_id)
	if state==null: return {}
	var owner:=Exchange.owner_id(civ_id)
	var metrics:Dictionary=state.simulation_metrics
	var out:Dictionary={}
	if metrics.has("standing_day") and int(state.elapsed_days)-int(float(metrics.standing_day))<=READING_STALE_DAYS:
		for row:Array in STRENGTHS: out[String(row[0])]=clampf(float(metrics.get("standing_"+String(row[0]),0.5)),0.0,1.0)
		return out
	if owner!="player" and not WorldSimulation.actors.has(owner): return {}
	# One reckoning a day serves every reading of them that day (their own
	# month will be recorded soon; until then this is the same code as ours).
	var key:="%s|%s|%d" % [String(WorldSimulation.actor_id),owner,int(state.elapsed_days)]
	if _their_cache.has(key): return (_their_cache[key] as Dictionary).duplicate()
	var theirs:Variant=_settled_values() if owner==String(WorldSimulation.actor_id) else WorldSimulation.scoped(owner,func()->Dictionary: return _settled_values())
	if not theirs is Dictionary: return {}
	for row:Array in STRENGTHS:
		var entry:Variant=(theirs as Dictionary).get(String(row[0]),{})
		out[String(row[0])]=clampf(float((entry as Dictionary).get("value",0.5)),0.0,1.0) if entry is Dictionary else 0.5
	if _their_cache.size()>=64: _their_cache.clear()
	_their_cache[key]=out.duplicate()
	return out
static var _their_cache:Dictionary={}

## The nine values of the people in scope (values()), read on its officials as
## its own day last settled them: a reading from another people's scope must
## not reconcile (and so change) this people's roll of officials.
static func _settled_values()->Dictionary:
	var government=WorldSimulation.government
	var hold:=government!=null and "initializing" in government and not bool(government.initializing) and "people" in government and not (government.people as Array).is_empty()
	if hold: government.initializing=true
	var out:=values()
	if hold: government.initializing=false
	return out

## Their reading of one strength as it stands (true, not our estimate: their
## own feelings and plans read their own); the typical 0.5 when unknown.
static func their_reading_value(civ_id:String,id:String)->float:
	return float(their_true(civ_id).get(id,Scale.TYPICAL_SCORE))

## Our relation with a people we know, as our own scope keeps it.
static func _relation_with(civ_id:String)->Dictionary:
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if String(civ.get("id",""))==civ_id: return civ.get("player_relation",{})
	return {}

## How sure we are of another people, 0..1: how well we know them (our
## relation's contact_intelligence: 0.2 at a first meeting, up to 0.95 with
## envoys, scouts and years), an agent of ours among them (at least
## EYES_CERTAINTY), and our cunning (CUNNING_CERTAINTY either way).
static func certainty(civ_id:String)->float:
	var relation:=_relation_with(civ_id)
	if relation.is_empty() or int(relation.get("contact_level",0))<2: return 0.0
	var sure:=clampf(float(relation.get("contact_intelligence",0.2)),0.0,0.95)
	if _eyes_among(civ_id)>0: sure=maxf(sure,EYES_CERTAINTY)
	var read:=clampf(sure+(own_art("cunning")-0.5)*2.0*CUNNING_CERTAINTY,0.0,1.0)
	# An eye long settled among them: what they are is known nearly to the
	# head, whatever our cunning (covert_ops.gd entrenched_years; 20 years: 0.97).
	if _owner()=="player" and Engine.get_main_loop()!=null:
		var years:=float(preload("res://scripts/covert_ops.gd").entrenched_years(civ_id))
		if years>0.0: read=maxf(read,clampf(EYES_CERTAINTY+(0.97-EYES_CERTAINTY)*years/20.0,EYES_CERTAINTY,0.97))
	return read

## Our network among them (covert_ops.gd network), 0..1: our cunning reads
## them as if this much sharper, for warnings and for their envoys' bluffs.
static func network_edge(civ_id:String)->float:
	if _owner()!="player" or Engine.get_main_loop()==null or civ_id=="": return 0.0
	return float(preload("res://scripts/covert_ops.gd").network_strength(civ_id))

## Our cunning as it bears on one people: our own, sharpened by a network.
static func cunning_toward(civ_id:String)->float:
	return clampf(art_of("player","cunning")+network_edge(civ_id)*0.45,0.0,1.0)

## Our agents among them now (the god's covert ops on watch or a source);
## for another people, its spies among us.
static func _eyes_among(civ_id:String)->int:
	var covert:Variant=ForeignDiplomacy.audiences.get("covert",{})
	if not covert is Dictionary: return 0
	var n:=0
	if _owner()=="player":
		for op in (covert as Dictionary).get("ops",[]):
			if op is Dictionary and String((op as Dictionary).get("civ_id",""))==civ_id and String((op as Dictionary).get("stage",""))=="in_place" and String((op as Dictionary).get("kind","")) in ["watch","plant"]: n+=1
	elif Exchange.owner_id(civ_id)=="player":
		for spy in (covert as Dictionary).get("incoming",[]):
			if spy is Dictionary and String((spy as Dictionary).get("civ_id",""))==_owner(): n+=1
	return n

## Our estimate of one of their readings: {value, low, high, exact, spread,
## certainty, unknown, right}. The surer we are, the narrower the band; and
## the surer and more cunning, the likelier our watchers got it right at all
## (else the value is off by up to the band). One estimate a season.
## `is_count`: a count (practices known), whose band is a share of it.
static func estimate(civ_id:String,key:String,truth:float,is_count:bool=false)->Dictionary:
	var sure:=certainty(civ_id)
	if sure<UNKNOWN_BELOW: return {"unknown":true,"value":-1.0,"low":-1.0,"high":-1.0,"exact":false,"spread":ESTIMATE_WIDEST,"certainty":sure,"right":false}
	var spread:=ESTIMATE_WIDEST*(1.0-sure)
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|estimate|%s|%s|%s|%d" % [int(WorldSimulation.state.world_seed),_owner(),civ_id,key,_day()/ESTIMATE_SEASON])
	var right:=rng.randf()<estimate_right_odds(sure)
	var err:=0.0 if right else rng.randf_range(-1.0,1.0)*spread
	var value:float
	var low:float
	var high:float
	if is_count:
		value=maxf(0.0,truth*(1.0+err))
		low=maxf(0.0,value*(1.0-spread))
		high=value*(1.0+spread)
	else:
		value=clampf(truth+err,0.0,1.0)
		low=clampf(value-spread,0.0,1.0)
		high=clampf(value+spread,0.0,1.0)
	return {"unknown":false,"value":value,"low":low,"high":high,"exact":spread<0.03,"spread":spread,"certainty":sure,"right":right}

## The odds our watchers got a reading of theirs right at all, by how sure we
## are of them and our cunning.
static func estimate_right_odds(sure:float)->float:
	return clampf(sure*0.6+(own_art("cunning")-0.5)*0.4,0.05,0.95)

## Another people's nine strengths as we know them: {id: {value, low, high,
## exact, unknown}} plus "_certainty"; {} when the world does not simulate
## them, we have not met them or we know too little of them to say. The same for every people: our
## knowledge of them and our cunning set the band.
static func their_strengths(civ_id:String)->Dictionary:
	if civ_id=="": return {}
	# Too little known of them to say anything: nothing to lay beside ours.
	var sure:=certainty(civ_id)
	if sure<UNKNOWN_BELOW: return {}
	var truth:=their_true(civ_id)
	if truth.is_empty(): return {}
	var result:Dictionary={"_certainty":sure}
	for row:Array in STRENGTHS:
		var id:=String(row[0])
		var est:=estimate(civ_id,id,float(truth.get(id,0.5)))
		result[id]={"value":float(est.value),"low":float(est.low),"high":float(est.high),"exact":bool(est.exact),"unknown":bool(est.unknown)}
	return result

## "about 60% (50 to 70)" or "62%" or "unknown" for one of their estimates.
static func estimate_words(est:Dictionary)->String:
	if bool(est.get("unknown",false)) or float(est.get("value",-1.0))<0.0: return "unknown"
	if bool(est.get("exact",false)): return "%d%%" % roundi(float(est.value)*100.0)
	return "about %d%% (%d to %d)" % [roundi(float(est.value)*100.0),roundi(float(est.low)*100.0),roundi(float(est.high)*100.0)]

# ------------------------------------------------------- cunning at work
# Every effect reads the cunning of the people it serves from that people's
# own month's reading; the same rule for every people.

## The odds a raid coming at a people is seen before it falls, and how many
## days before: a typical people (0.5) half the time, 18 days ahead.
const FOREWARN_ODDS_TYPICAL:=0.5
const FOREWARN_ODDS_SLOPE:=0.8
const FOREWARN_DAYS_MIN:=5.0
const FOREWARN_DAYS_SPAN:=25.0
static func forewarn_odds(cunning:float)->float:
	return clampf(FOREWARN_ODDS_TYPICAL+(cunning-0.5)*FOREWARN_ODDS_SLOPE,0.05,0.95)
static func forewarn_days(cunning:float)->int:
	return roundi(FOREWARN_DAYS_MIN+clampf(cunning,0.0,1.0)*FOREWARN_DAYS_SPAN)

## A people arming against us is heard of when it begins on forewarn_odds;
## otherwise word comes only in the last this many days before they march
## (world_answer.gd _late_word, read at its monthly reckoning).
const LATE_WORD_DAYS:=30

## How our watchers read an envoy's threat (rival_rulers.gd _bluff): the odds
## a bluff shows its tells, a real threat its signs, and a real threat a
## misleading tell. A typical people keeps the old odds (0.85, 0.7, 0.15).
static func bluff_reading(cunning:float)->Dictionary:
	return {"tells":clampf(0.55+cunning*0.6,0.5,0.98),"signs":clampf(0.4+cunning*0.6,0.4,0.95),"false_tells":clampf(0.3-cunning*0.3,0.02,0.3)}

## CUNNING AGAINST CUNNING: every agent's odds weigh the cunning of the
## people that sends it against the cunning of the people it works among (the
## keeper), the same rule whichever people sends and whichever keeps, the
## god's or another's (covert_ops.gd odds and _catch_chance, captured_agents.gd
## double_odds and a turned agent found out). Each point of the sender's
## cunning over the keeper's adds COVERT_EDGE to the agent's odds of success
## and takes CATCH_EDGE from its odds of being caught (or traced); each point
## of the keeper's over the sender's does the reverse. Two peoples of equal
## cunning leave the odds as they are.
const COVERT_EDGE:=0.2
const CATCH_EDGE:=0.3
## The sender's edge in an agent's odds of success (keeper typical when not given).
static func covert_edge(sender:float,keeper:float=0.5)->float:
	return (sender-keeper)*COVERT_EDGE
## The keeper's edge in catching (or tracing) the sender's agent: positive
## when the keeper is the more cunning (sender typical when not given).
static func catch_edge(keeper:float,sender:float=0.5)->float:
	return (keeper-sender)*CATCH_EDGE

## The covert odds between us and one people we know, as our watchers reckon
## their cunning (their own month's reading through our estimate): {ours,
## theirs (-1 unknown), low, high, exact, unknown, agents (our agents' odds),
## caught (ours caught among them), theirs_caught (their spies caught among
## us)}: points of 0..1 added to the stated odds. The roll itself reads their
## true cunning; this is what the page and the court say of it.
static func covert_between(civ_id:String)->Dictionary:
	var ours:=own_art("cunning")
	var est:=estimate(civ_id,"cunning",their_reading_value(civ_id,"cunning"))
	if bool(est.get("unknown",false)): return {"ours":ours,"theirs":-1.0,"unknown":true,"agents":0.0,"caught":0.0,"theirs_caught":0.0}
	var theirs:=float(est.value)
	return {"ours":ours,"theirs":theirs,"low":float(est.low),"high":float(est.high),"exact":bool(est.exact),"unknown":false,
		"agents":covert_edge(ours,theirs),"caught":catch_edge(theirs,ours),"theirs_caught":catch_edge(ours,theirs)}

## The spies line of a people's card and the court's fact sheet: {words,
## detail, tone}; {} when we have not met them.
static func spies_words(civ_id:String)->Dictionary:
	if int(_relation_with(civ_id).get("contact_level",0))<2: return {}
	var c:=covert_between(civ_id)
	var ours:=float(c.ours)
	if bool(c.unknown):
		return {"tone":"calm","words":"Spies between us: we know too little of them to say how their cunning weighs against ours",
			"detail":"Cunning against cunning: the more cunning people's agents do better among the other, and its watch catches more of the other's, by the same rule both ways. Our cunning is %d%%." % roundi(ours*100.0)}
	var theirs_words:=estimate_words({"value":float(c.theirs),"low":float(c.low),"high":float(c.high),"exact":bool(c.exact)})
	var words:="Spies between us: our agents' odds %s and caught %s among them; their spies caught %s among us" % [_points(float(c.agents)),_points(float(c.caught)),_points(float(c.theirs_caught))]
	var detail:="Our cunning %d%% against theirs, %s by our watchers' reckoning. Cunning against cunning, the same rule both ways: every 10 points of one people's cunning over the other's add %d points to its agents' odds, take %d from their odds of being caught, and add %d to its watch's odds of catching the other's spies. %sAdded to the stated odds of every watch, source, theft and strike." % [roundi(ours*100.0),theirs_words,roundi(COVERT_EDGE*10.0),roundi(CATCH_EDGE*10.0),roundi(CATCH_EDGE*10.0),"These numbers come from our estimate of them; the odds themselves read how cunning they truly are. " if not bool(c.exact) else ""]
	var lead:=ours-float(c.theirs)
	return {"tone":"good" if lead>=0.15 else ("danger" if lead<=-0.15 else "calm"),"words":words,"detail":detail}

## "+3 points", "-1 point", "unchanged" for an edge in odds.
static func _points(x:float)->String:
	var points:=roundi(x*100.0)
	if points==0: return "unchanged"
	return "%+d point%s" % [points,"" if absi(points)==1 else "s"]

## A scout's or spy's look at a town (city_intelligence.gd capture): the
## quality of the look rises, and the error band narrows, with cunning.
const INTEL_SHARPEN:=0.2
static func intel_quality_edge(cunning:float)->float:
	return (cunning-0.5)*INTEL_SHARPEN
static func intel_error_factor(cunning:float)->float:
	return clampf(1.15-cunning*0.3,0.8,1.15)

# ---------------------------------------------------- persuasion at work

## An envoy's deal (envoy_deals.gd): their ruler pays more freely to a
## persuasive people (temper), and bends to harder terms more often (odds).
const DEAL_TEMPER:=0.2
const COUNTER_EDGE:=0.2
static func deal_temper(persuasion:float)->float:
	return (persuasion-0.5)*DEAL_TEMPER
static func counter_edge(persuasion:float)->float:
	return (persuasion-0.5)*COUNTER_EDGE

## A message sent home with a captured agent (captured_agents.gd): heeded
## more often from a persuasive people.
const MESSAGE_EDGE:=0.2
static func message_edge(persuasion:float)->float:
	return (persuasion-0.5)*MESSAGE_EDGE

## Exchanges and treaties hold better: a trade pact bears this many more
## failed portions before it is ended (trade_pacts.gd MISSES_TO_LAPSE), and a
## treaty between two peoples breaks only when regard falls this much lower
## (civilization_system.gd: 0.04 by default).
static func pact_grace(persuasion:float)->int:
	return roundi((persuasion-0.5)*4.0)
const TREATY_BREAK:=0.04
const TREATY_HOLD:=0.12
static func treaty_floor(first:String,second:String)->float:
	return TREATY_BREAK-((art_of(first,"persuasion")+art_of(second,"persuasion"))*0.5-0.5)*TREATY_HOLD

## Families of other peoples drawn to settle with us (society_exchange.gd
## attraction): this much a month at full persuasion past the typical.
const PERSUASION_DRAW:=0.06
static func persuasion_draw(persuasion:float)->float:
	return (persuasion-0.5)*PERSUASION_DRAW

## Softer grudges: a new grudge against a persuasive people weighs less
## (rival_rulers.gd grudge): x0.8 at full persuasion, x1.2 at none.
const GRUDGE_SOFTEN:=0.4
static func grudge_factor(persuasion:float)->float:
	return clampf(1.0-(persuasion-0.5)*GRUDGE_SOFTEN,0.7,1.3)

## What our cunning and persuasion do this month, with the engine's numbers,
## for the Standing page and the court: {cunning:[...], persuasion:[...]},
## each row {words, detail}.
static func arts_at_work()->Dictionary:
	var c:=own_art("cunning")
	var p:=own_art("persuasion")
	var bluff:=bluff_reading(c)
	var sure:=_mean_certainty()
	var cunning_rows:Array=[
		{"words":"Raids seen coming: %d in 100, about %d days ahead" % [roundi(forewarn_odds(c)*100.0),forewarn_days(c)],"detail":"When raiders are sent against us, our watchers see them coming on these odds; then the watch keeps the approaches until they come, and meets them on ground of our choosing. A typical people of the age sees %d in 100, %d days ahead." % [roundi(forewarn_odds(0.5)*100.0),forewarn_days(0.5)]},
		{"words":"A people arming against us heard of at once: %d in 100" % roundi(forewarn_odds(c)*100.0),"detail":"Otherwise word comes only in the last %d days before they march." % LATE_WORD_DAYS},
		{"words":"An envoy's bluff seen through: %d in 100; a real threat's signs read: %d in 100" % [roundi(float(bluff.tells)*100.0),roundi(float(bluff.signs)*100.0)],"detail":"Misleading tells on a real threat: %d in 100. A typical people: 85, 70 and 15." % roundi(float(bluff.false_tells)*100.0)},
		{"words":"Our agents among a people of typical cunning: odds %s, caught %s" % [_signed_points(covert_edge(c,0.5)),_signed_points(catch_edge(0.5,c))],"detail":"Cunning against cunning, the same rule for every people, ours among them and theirs among us: every 10 points of the sender's cunning over the keeper's add %d points to an agent's odds and take %d from its odds of being caught; the keeper's cunning over the sender's does the reverse. Added to the stated odds of every watch, source, theft and strike." % [roundi(COVERT_EDGE*10.0),roundi(CATCH_EDGE*10.0)]},
		{"words":"Spies of a people of typical cunning caught: %s" % _signed_points(catch_edge(c,0.5)),"detail":"Added to our watch's odds of taking a spy or an assassin of theirs. A more cunning people's spies are caught less often, a less cunning people's more, by the same rule."},
	]
	var against:=_most_cunning_known()
	if not against.is_empty(): cunning_rows.append(against)
	if sure>=0.0:
		cunning_rows.append({"words":"What we know of the peoples we know: within %d points either way, right %d in 100" % [roundi(ESTIMATE_WIDEST*(1.0-clampf(sure,0.0,1.0))*100.0),roundi(estimate_right_odds(sure)*100.0)],"detail":"Our estimates of their strengths, their learning and their spears, on every screen that shows them. Envoys, scouts and years of contact make them surer; cunning adds or takes away up to %d points." % roundi(CUNNING_CERTAINTY*100.0)})
	var grace:=maxi(1,3+pact_grace(p))
	var persuasion_rows:Array=[
		{"words":"Envoys' deals: their ruler pays %s; agrees to harder terms %s" % [_share_words(deal_temper(p),"more","less"),_signed_points(counter_edge(p))],"detail":"In every envoy's bargain: what they offer for what they ask, and the odds they take our counter."},
		{"words":"A message sent home with a captured agent heeded: %s" % _signed_points(message_edge(p)),"detail":"Added to the odds their ruler heeds a warning, bows to a threat, takes an offer of peace or meets a demand."},
		{"words":"Exchanges bear %d failed portion%s before they are ended" % [grace,"" if grace==1 else "s"],"detail":"Three for a typical people. Between any two peoples, a treaty breaks once regard falls below %d in 100; the more persuasive the two, the lower it must fall first (%d points lower for two of the best)." % [roundi(TREATY_BREAK*100.0),roundi(0.5*TREATY_HOLD*100.0)]},
		{"words":"Families of other peoples drawn to us: %+.1f a month (points of 100)" % (persuasion_draw(p)*100.0),"detail":"Added to how much families want to join us and stay."},
		{"words":"New grudges against us weigh x%.2f" % grudge_factor(p),"detail":"A grudge of theirs over a wrong of ours starts lighter, so it fades sooner and sends raiders later."},
		{"words":"Their rulers' trust in our word: %s" % _signed_points((p-0.5)*0.2),"detail":"How our envoys carry themselves."},
	]
	return {"cunning":cunning_rows,"persuasion":persuasion_rows,"cunning_value":c,"persuasion_value":p}

## The arts' row for the peoples we know: the most cunning of them as our
## watchers reckon it, with every one's odds in the detail; {} when we know
## nobody well enough to say.
static func _most_cunning_known()->Dictionary:
	var best:={}
	var lines:PackedStringArray=[]
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)) or int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		var id:=String(civ.id)
		var c:=covert_between(id)
		if bool(c.unknown): continue
		var name:=String(civ.get("name",id))
		lines.append("%s, cunning %s: our agents %s, caught %s; theirs caught %s" % [name,estimate_words({"value":float(c.theirs),"low":float(c.low),"high":float(c.high),"exact":bool(c.exact)}),_points(float(c.agents)),_points(float(c.caught)),_points(float(c.theirs_caught))])
		if best.is_empty() or float(c.theirs)>float(best.theirs): best={"name":name,"theirs":float(c.theirs),"c":c}
	if best.is_empty(): return {}
	var c:Dictionary=best.c
	return {"words":"The most cunning people we know, %s, cunning %s: our agents %s and caught %s among them; theirs caught %s among us" % [String(best.name),estimate_words({"value":float(c.theirs),"low":float(c.low),"high":float(c.high),"exact":bool(c.exact)}),_points(float(c.agents)),_points(float(c.caught)),_points(float(c.theirs_caught))],
		"detail":"By our watchers' reckoning of each people's cunning. "+"; ".join(lines)+"."}

static func _signed_points(x:float,up:String="",down:String="")->String:
	var points:=roundi(x*100.0)
	if points==0: return "as for a typical people"
	var unit:="point" if absi(points)==1 else "points"
	if up!="": return "%d %s %s" % [absi(points),unit,up if points>0 else down]
	return "%+d %s" % [points,unit]

## "a tenth more", "a twentieth less", "7 in 100 more": a multiplier's share.
static func _share_words(x:float,up:String,down:String)->String:
	var share:=roundi(absf(x)*100.0)
	if share==0: return "as to a typical people"
	var words:=String({5:"a twentieth",10:"a tenth",20:"a fifth",25:"a quarter",50:"a half"}.get(share,"%d in 100" % share))
	return "%s %s" % [words,up if x>0.0 else down]

## How sure we are of the peoples we know, on average (-1 when none).
static func _mean_certainty()->float:
	var total:=0.0
	var count:=0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)) or int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		total+=certainty(String(civ.id))
		count+=1
	return total/float(count) if count>0 else -1.0
