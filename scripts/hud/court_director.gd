extends RefCounted
## THE COURT'S DIRECTOR: how the whole room acts out what the engine decided.
##
## The engine adjudicates (audience_hall.gd, divine_regard.gd,
## court_commands.gd); the stage shows it. Between them the director turns one
## structured engine event (a line said, a decree, wrath or favour with the
## response the engine rolled, a gift, an arrival, an exit) into a timed list
## of beats for everyone standing in the hall: who does what, when, and where
## the camera looks. It is pure: it reads the event, the cast and the fact
## sheet, never the game state, and it changes nothing. The same seed gives
## the same beats.
##
## How a moment plays: anticipation (the room stills), the action (what was
## decided, done by the one it was done to), the reaction (rippling through
## the room, the jumpy first and the brave last, each by their own love,
## dread, courage and pride), and a held beat of silence, after which there
## may be one small button: the elder who slept through it, the goat. The
## comedy is the people being people at the edge of a god's temper; it never
## changes what happened. A person the engine says stood firm stands firm in
## every beat; nobody is hungry on stage while the stores are full; nobody
## laughs at a death.
##
## Variety: each comic bit has a cooldown kept in the caller's `memory`
## (a small presentation-only dictionary the stage owns), so one bit does not
## come round again for several events, and the same kind of event never
## plays out identically twice in a row. Over hundreds of audiences the pool
## of bits, the people they fall on and their timing keep it from going stale.
##
##   beats(event, cast, facts, seed, memory) -> [{t, who, act, args, phase}]
##   ambient(cast, facts, seed)              -> [{who, act, every, dur, args, because}]
##   asides(event, facts, cast, seed, memory)-> [{t, who, text, cites, situation}]
##
## who is a cast key, "camera" (a shot: wide, push_in, reaction, two_shot,
## shake) or "room" (hush: everyone's idle business pauses). act names are
## the acting vocabulary in ACTS: each says the face it wears, how long it
## lasts and, until the acting layer (court_acting.gd) has a clip of that
## name, the nearest clip and mood the figures already have.
##
## The adapters (event_from_divine, event_from_command, event_from_line,
## event_from_resolution, event_from_exit) read the engine's own result
## dictionaries; cast_member() and facts_now() build the cast and the fact
## sheet. Static helpers; preload.

const Asides:=preload("res://scripts/hud/court_asides.gd")

## The stores' days of food below which people are hungry on stage (the
## hall's own words: under 16 days "food is short"); under 7 they starve.
const HUNGRY_DAYS:=16
const STARVING_DAYS:=7
const FULL_DAYS:=35
const DREAD_HIGH:=0.55
const LOVE_HIGH:=0.62
## A sickness shows when it has killed or when health is failing.
const SICK_HEALTH:=0.62

## Getting down before the god: never done by one who stood firm.
const KNEEL_LIKE:=["kneel","prostrate","bow","bow_deep","bow_small","bow_early","double_bow","head_down","plead","cower","wobble","flinch","knees_knock","tremble","faint"]
const HUNGER_ACTS:=["eye_food","rub_belly","lick_lips"]
const SICK_ACTS:=["cough","cover_mouth","keep_apart"]
const WAR_ACTS:=["sharpen_spear","stand_guard","glance_door"]
const DREAD_ACTS:=["tremble","glance_up","wring_hands"]
const LOVE_ACTS:=["smile_warm","lean_in"]
## Light business, never played at a death.
const COMIC_ACTS:=["stifle_laugh","elbow","wobble","drop_bowl","jerk_awake","look_wrong_way","double_take","yawn","faint","half_catch",
	"nibble","copy","shush","bow_early","double_bow","late_lift","snap_alert","sniff","shoo","count_fingers","bleat","grimace","smirk","beam"]

## The acting vocabulary. clip/mood: the nearest the modelled figures already
## have (court_figure_3d.gd CLIPS and MOODS), used until the acting layer
## gives the act its own clip; face: shape-key weights; dur: seconds; hold:
## stays until something else is asked; look: "god", "god_up", "at" (args.at),
## "away" or ""; desc: how the screenplay tells it.
const ACTS:={
	# Before the god.
	"look_up":{"clip":"","mood":"","face":{"brows_up":0.4},"dur":0.9,"look":"god_up","desc":"lifts their face to the voice"},
	"kneel":{"clip":"kneel","mood":"afraid","face":{"brows_worried":0.7},"dur":2.6,"hold":true,"look":"","desc":"goes down on one knee"},
	"kneel_bound":{"clip":"kneel","mood":"defiant","face":{"brows_down":0.6,"lips_pressed":0.7},"dur":2.6,"hold":true,"look":"god","desc":"is forced down to kneel, bound, chin still up"},
	"prostrate":{"clip":"kneel","mood":"afraid","face":{"eyes_wide":0.5},"dur":2.6,"hold":true,"look":"","desc":"throws themselves down on their face"},
	"bow":{"clip":"bow","mood":"warm","face":{},"dur":2.8,"look":"","desc":"bows"},
	"bow_deep":{"clip":"bow","mood":"warm","face":{"eyes_wide":0.2},"dur":3.2,"speed":0.8,"look":"","desc":"bows far too deep"},
	"bow_small":{"clip":"bow","mood":"","face":{},"dur":1.6,"speed":1.6,"look":"","desc":"dips a small bow"},
	"bow_early":{"clip":"bow","mood":"afraid","face":{"brows_worried":0.4},"dur":2.4,"speed":1.3,"look":"","desc":"bows too early, from too far away, and has to do it again"},
	"double_bow":{"clip":"bow","mood":"warm","face":{"smile":0.4},"dur":3.4,"speed":1.5,"look":"","desc":"bows, comes up, and bows again for luck"},
	"head_down":{"clip":"","mood":"grieved","face":{"lips_pressed":0.6},"dur":2.0,"hold":true,"look":"","desc":"lowers their head and takes it"},
	"plead":{"clip":"raise_hand","mood":"afraid","face":{"brows_worried":0.9},"dur":2.0,"look":"god","desc":"opens their hands and pleads"},
	"stand_firm":{"clip":"","mood":"defiant","face":{"brows_down":0.5,"lips_pressed":0.6,"eyes_narrow":0.3},"dur":2.4,"hold":true,"look":"god","desc":"stands their ground, chin up"},
	"hold_gaze":{"clip":"","mood":"defiant","face":{"eyes_narrow":0.4},"dur":1.8,"look":"god","desc":"holds the god's gaze"},
	"gulp":{"clip":"","mood":"","face":{"jaw_open":0.2,"lips_pressed":0.5},"dur":0.6,"look":"","desc":"swallows, hard"},
	"stricken":{"clip":"","mood":"grieved","face":{"eyes_wide":0.6,"jaw_open":0.2},"dur":2.0,"hold":true,"look":"","desc":"stands stricken"},
	"exhale":{"clip":"","mood":"warm","face":{"cheeks_puff":0.3},"dur":1.2,"look":"","desc":"lets out the breath they were holding"},
	"beam":{"clip":"","mood":"warm","face":{"smile":0.9,"brows_up":0.3},"dur":2.0,"look":"god","desc":"beams"},
	# The room.
	"freeze":{"clip":"","mood":"","face":{"eyes_wide":0.5},"dur":0.8,"look":"","desc":"freezes"},
	"flinch":{"clip":"","mood":"afraid","face":{"eyes_wide":0.8,"brows_up":0.6},"dur":0.6,"look":"","desc":"flinches"},
	"knees_knock":{"clip":"","mood":"afraid","face":{"brows_worried":0.9,"jaw_open":0.2},"dur":1.4,"look":"","desc":"'s knees knock"},
	"tremble":{"clip":"","mood":"afraid","face":{"brows_worried":0.6},"dur":1.6,"look":"","desc":"trembles"},
	"step_back":{"clip":"","mood":"afraid","face":{"eyes_wide":0.4},"dur":0.8,"look":"","desc":"takes a step back"},
	"gasp":{"clip":"","mood":"","face":{"jaw_open":0.6,"eyes_wide":0.7},"dur":0.7,"look":"","desc":"gasps"},
	"pretend_calm":{"clip":"","mood":"neutral","face":{"lips_pressed":0.4},"dur":1.4,"look":"","desc":"pretends they didn't, and looks about to see who noticed"},
	"straighten":{"clip":"","mood":"neutral","face":{},"dur":0.8,"look":"","desc":"straightens up"},
	"smile_warm":{"clip":"","mood":"warm","face":{"smile":0.5},"dur":2.0,"look":"","desc":"smiles"},
	"nod":{"clip":"","mood":"","face":{},"dur":0.8,"look":"","desc":"nods"},
	"shake_head":{"clip":"","mood":"defiant","face":{"lips_pressed":0.5},"dur":1.0,"look":"god","desc":"shakes their head"},
	"side_eye":{"clip":"","mood":"","face":{"eyes_narrow":0.5},"dur":1.2,"look":"at","desc":"slides a look at {at}"},
	"exchange_look":{"clip":"","mood":"","face":{"brows_up":0.5},"dur":1.2,"look":"at","desc":"exchanges a look with {at}"},
	"stifle_laugh":{"clip":"","mood":"warm","face":{"cheeks_puff":0.7,"lips_pressed":0.8},"dur":1.2,"look":"away","desc":"stifles a laugh"},
	"elbow":{"clip":"","mood":"","face":{"eyes_narrow":0.4},"dur":0.6,"look":"at","desc":"elbows {at}"},
	"shush":{"clip":"raise_hand","mood":"","face":{"lips_pressed":0.6},"dur":0.9,"look":"at","desc":"shushes {at}"},
	"wobble":{"clip":"","mood":"afraid","face":{"eyes_wide":0.6},"dur":0.9,"look":"","desc":"wobbles, arms out"},
	"recover":{"clip":"","mood":"neutral","face":{"lips_pressed":0.3},"dur":0.8,"look":"","desc":"recovers with as much dignity as is left"},
	"double_take":{"clip":"","mood":"","face":{"eyes_wide":0.8,"brows_up":0.8},"dur":0.9,"look":"at","desc":"does a double take"},
	"cross_arms":{"clip":"","mood":"defiant","face":{"eyes_narrow":0.3},"dur":1.6,"look":"","desc":"folds their arms"},
	"eyes_narrow":{"clip":"","mood":"","face":{"eyes_narrow":0.7},"dur":1.2,"look":"at","desc":"narrows their eyes at {at}"},
	"lips_pressed":{"clip":"","mood":"","face":{"lips_pressed":0.8},"dur":1.2,"look":"","desc":"presses their lips together"},
	"hand_to_mouth":{"clip":"","mood":"grieved","face":{"eyes_wide":0.5},"dur":1.6,"look":"","desc":"puts a hand to their mouth"},
	"look_away":{"clip":"","mood":"grieved","face":{"brows_worried":0.5},"dur":1.6,"look":"away","desc":"looks away"},
	"cover_eyes":{"clip":"","mood":"grieved","face":{},"dur":2.4,"look":"","desc":"covers {at}'s eyes"},
	"hide_behind":{"clip":"","mood":"afraid","face":{"eyes_wide":0.6},"dur":2.4,"hold":true,"look":"","desc":"hides behind {at}"},
	"peek_out":{"clip":"","mood":"afraid","face":{"eyes_wide":0.4},"dur":1.0,"look":"god","desc":"peeks out"},
	"faint":{"clip":"","mood":"afraid","face":{"eyes_wide":0.2},"dur":1.6,"hold":true,"look":"","desc":"faints"},
	"half_catch":{"clip":"","mood":"","face":{"eyes_wide":0.6},"dur":1.2,"look":"at","desc":"half catches {at}"},
	"drop_bowl":{"clip":"","mood":"afraid","face":{"eyes_wide":0.7,"jaw_open":0.3},"dur":0.8,"look":"","desc":"drops their bowl"},
	"grimace":{"clip":"","mood":"","face":{"lips_pressed":0.7,"brows_worried":0.5},"dur":1.0,"look":"","desc":"grimaces"},
	"doze":{"clip":"","mood":"neutral","face":{"blink":1.0},"dur":4.0,"hold":true,"look":"","desc":"dozes on their feet"},
	"jerk_awake":{"clip":"","mood":"","face":{"eyes_wide":0.9,"brows_up":0.9},"dur":0.6,"look":"","desc":"jerks awake"},
	"look_wrong_way":{"clip":"","mood":"","face":{"brows_up":0.5},"dur":0.9,"look":"away","desc":"looks the wrong way first"},
	"late_lift":{"clip":"","mood":"","face":{"brows_up":0.5},"dur":0.9,"look":"god_up","desc":"is the last to look up"},
	"yawn":{"clip":"","mood":"","face":{"jaw_open":0.9,"eyes_narrow":0.6},"dur":1.6,"look":"","desc":"yawns"},
	"snap_alert":{"clip":"","mood":"afraid","face":{"eyes_wide":0.8},"dur":0.8,"look":"god","desc":"snaps upright, suddenly very awake"},
	"smirk":{"clip":"","mood":"","face":{"sneer":0.4,"smile":0.2},"dur":1.2,"look":"at","desc":"smirks at {at}"},
	"make_room":{"clip":"","mood":"","face":{},"dur":1.0,"look":"at","desc":"shuffles aside to make room for {at}"},
	"wring_hands":{"clip":"","mood":"afraid","face":{"brows_worried":0.7},"dur":1.6,"look":"","desc":"wrings their hands"},
	"copy":{"clip":"bow","mood":"","face":{"lips_pressed":0.3},"dur":1.8,"speed":1.4,"look":"at","desc":"copies {at}, badly"},
	"hesitate":{"clip":"","mood":"afraid","face":{"brows_worried":0.6},"dur":1.4,"look":"god","desc":"hesitates"},
	"hurry":{"clip":"","mood":"afraid","face":{},"dur":0.8,"look":"","desc":"hurries to obey"},
	"grab":{"clip":"point","mood":"defiant","face":{"brows_down":0.5},"dur":1.2,"look":"at","desc":"seizes {at}"},
	"bolt":{"clip":"","mood":"defiant","face":{"eyes_wide":0.4},"dur":0.8,"look":"","desc":"bolts for the door"},
	"watch_go":{"clip":"","mood":"grieved","face":{},"dur":2.0,"look":"at","desc":"watches {at} go"},
	"edge_away":{"clip":"","mood":"","face":{"lips_pressed":0.4},"dur":1.0,"look":"at","desc":"edges away from {at}"},
	"face_fall":{"clip":"","mood":"grieved","face":{"brows_worried":0.8},"dur":1.6,"look":"","desc":"their face falls"},
	"stiffen":{"clip":"","mood":"defiant","face":{"lips_pressed":0.7},"dur":1.2,"look":"god","desc":"stiffens"},
	"sympathetic_look":{"clip":"","mood":"grieved","face":{"brows_worried":0.4},"dur":1.4,"look":"at","desc":"gives {at} a sympathetic look"},
	"count_fingers":{"clip":"","mood":"","face":{"brows_down":0.4},"dur":1.8,"look":"","desc":"counts it off on their fingers"},
	"point":{"clip":"point","mood":"","face":{},"dur":2.0,"look":"at","desc":"points at {at}"},
	"look_at":{"clip":"","mood":"","face":{},"dur":1.0,"look":"at","desc":"looks at {at}"},
	"shrug":{"clip":"","mood":"","face":{"brows_up":0.6,"lips_pressed":0.4},"dur":1.0,"look":"","desc":"shrugs, very slightly"},
	# Animals.
	"perk_up":{"clip":"","mood":"","face":{},"dur":0.8,"look":"god_up","desc":"pricks up its ears"},
	"whimper":{"clip":"","mood":"","face":{},"dur":1.2,"look":"","desc":"whimpers"},
	"hide_under":{"clip":"","mood":"","face":{},"dur":2.4,"hold":true,"look":"","desc":"slinks behind {at}'s legs"},
	"sniff":{"clip":"","mood":"","face":{},"dur":1.4,"look":"at","desc":"sniffs at {at}"},
	"tail_wag":{"clip":"","mood":"","face":{},"dur":1.6,"look":"","desc":"wags its tail"},
	"lie_down":{"clip":"","mood":"","face":{},"dur":3.0,"hold":true,"look":"","desc":"lies down"},
	"chew":{"clip":"","mood":"","face":{},"dur":3.0,"look":"","desc":"chews"},
	"bleat":{"clip":"","mood":"","face":{},"dur":0.8,"look":"","desc":"bleats into the silence"},
	"nibble":{"clip":"","mood":"","face":{},"dur":1.6,"look":"at","desc":"nibbles {at}'s hem"},
	"shoo":{"clip":"raise_hand","mood":"","face":{"lips_pressed":0.5},"dur":0.9,"look":"at","desc":"shoos {at} off"},
	# Gifts.
	"struggle_bundle":{"clip":"","mood":"","face":{"cheeks_puff":0.6,"brows_worried":0.4},"dur":1.2,"look":"","desc":"heaves the bundle forward"},
	"set_down_bundle":{"clip":"bow","mood":"","face":{"cheeks_puff":0.4},"dur":1.0,"speed":1.4,"look":"","desc":"sets the bundle down with a grunt"},
	"lift_bundle":{"clip":"","mood":"","face":{"cheeks_puff":0.7,"brows_worried":0.6},"dur":1.2,"look":"","desc":"heaves the bundle back up"},
	# Idle business (ambient).
	"eye_food":{"clip":"","mood":"","face":{"eyes_wide":0.2},"dur":1.6,"look":"at","desc":"eyes the food"},
	"rub_belly":{"clip":"","mood":"","face":{"brows_worried":0.3},"dur":1.4,"look":"","desc":"rubs their belly"},
	"lick_lips":{"clip":"","mood":"","face":{"jaw_open":0.1},"dur":0.8,"look":"","desc":"licks their lips"},
	"pat_belly":{"clip":"","mood":"warm","face":{},"dur":1.2,"look":"","desc":"pats a full belly"},
	"cough":{"clip":"","mood":"","face":{"jaw_open":0.4,"eyes_narrow":0.5},"dur":1.0,"look":"","desc":"coughs"},
	"cover_mouth":{"clip":"","mood":"","face":{},"dur":1.0,"look":"","desc":"covers their mouth"},
	"keep_apart":{"clip":"","mood":"","face":{"lips_pressed":0.3},"dur":4.0,"hold":true,"look":"","desc":"keeps a careful distance from {at}"},
	"sharpen_spear":{"clip":"","mood":"","face":{"eyes_narrow":0.3},"dur":2.4,"look":"","desc":"works a stone along a spear point"},
	"stand_guard":{"clip":"","mood":"defiant","face":{},"dur":4.0,"hold":true,"look":"","desc":"stands guard by the door"},
	"glance_door":{"clip":"","mood":"","face":{},"dur":1.0,"look":"away","desc":"glances at the door"},
	"glance_up":{"clip":"","mood":"afraid","face":{"brows_worried":0.4},"dur":0.9,"look":"god_up","desc":"glances up, nervously"},
	"lean_in":{"clip":"","mood":"warm","face":{"smile":0.2},"dur":2.0,"look":"god","desc":"leans in"},
	"rub_hands":{"clip":"","mood":"","face":{},"dur":1.4,"look":"","desc":"rubs their hands against the cold"},
	"fan_self":{"clip":"","mood":"","face":{},"dur":1.4,"look":"","desc":"fans themselves"},
	"fidget":{"clip":"","mood":"","face":{},"dur":1.0,"look":"","desc":"fidgets"},
	"tug_sleeve":{"clip":"","mood":"","face":{},"dur":1.0,"look":"at","desc":"tugs {at}'s sleeve"},
	"shift_weight":{"clip":"","mood":"","face":{},"dur":1.2,"look":"","desc":"shifts their weight"},
	"scratch":{"clip":"","mood":"","face":{},"dur":1.2,"look":"","desc":"scratches"},
	"bored":{"clip":"","mood":"neutral","face":{"eyes_narrow":0.4},"dur":4.0,"hold":true,"look":"away","desc":"leans on their spear, bored"},
	"mutter":{"clip":"","mood":"","face":{"jaw_open":0.15},"dur":1.4,"look":"","desc":"mutters"},
	# The camera and the room.
	"wide":{"dur":1.0,"desc":"WIDE on the hall"},
	"push_in":{"dur":1.2,"desc":"PUSH IN on {target}"},
	"reaction":{"dur":1.0,"desc":"CUT to {target}"},
	"two_shot":{"dur":1.2,"desc":"TWO SHOT, {a} and {b}"},
	"shake":{"dur":0.4,"desc":"the frame shakes ({strength})"},
	"hush":{"dur":2.0,"desc":"the room goes still"},
}

## Comic bits: the event kinds each fits, its weight and how many events it
## rests before it may come round again.
const BITS:={
	"doze_jerk":{"kinds":["god_speaks","divine","terrify_envoy"],"weight":3.0,"rest":7},
	"drop_bowl":{"kinds":["god_speaks","divine","terrify_envoy"],"weight":1.6,"rest":10,"wrath":true},
	"late_lift":{"kinds":["god_speaks"],"weight":2.0,"rest":5},
	"goat_ignores":{"kinds":["god_speaks","divine"],"weight":2.2,"rest":6},
	"goat_nibble":{"kinds":["line","god_speaks","promise","dismiss"],"weight":1.4,"rest":9},
	"child_hides":{"kinds":["divine","terrify_envoy","command"],"weight":3.0,"rest":4,"wrath":true},
	"dog_whimper":{"kinds":["divine","terrify_envoy","command"],"weight":2.4,"rest":4,"wrath":true},
	"faint":{"kinds":["divine"],"weight":2.0,"rest":14,"wrath":true},
	"gasp_pretend":{"kinds":["divine","command","envoy_insulted","terrify_envoy","exit"],"weight":2.6,"rest":3},
	"side_eye_pair":{"kinds":["command","decree","divine","line"],"weight":2.2,"rest":3},
	"stifle_elbow":{"kinds":["command","god_speaks","decree"],"weight":2.4,"rest":6},
	"eager_bow":{"kinds":["divine","decree","command","god_speaks","summon"],"weight":2.4,"rest":7},
	"bored_guard":{"kinds":["line","gift","decree","dismiss","promise"],"weight":2.0,"rest":4},
	"guard_snap":{"kinds":["terrify_envoy","envoy_insulted"],"weight":4.0,"rest":2},
	"dog_sniff_gift":{"kinds":["gift"],"weight":3.0,"rest":3},
	"double_take":{"kinds":["line","divine","gift","decree"],"weight":2.6,"rest":2},
	"count_fingers":{"kinds":["line","gift","decree"],"weight":1.4,"rest":5},
	"child_copies":{"kinds":["decree","line","dismiss","summon"],"weight":2.4,"rest":6},
	"double_bow":{"kinds":["decree"],"weight":2.0,"rest":5},
	"bow_early":{"kinds":["summon"],"weight":2.6,"rest":5},
	"cough_fit":{"kinds":["line","god_speaks","decree","promise","dismiss","summon","gift"],"weight":2.2,"rest":3},
	"smirk_rival":{"kinds":["decree","divine"],"weight":1.6,"rest":5},
}
## Bits played by their own moment, never drawn from the pool (they replace
## the plain version of that moment: a double bow instead of a bow, the guard
## snapping awake instead of stepping back, the sleeper woken by the voice).
const DIRECT_BITS:=["double_bow","guard_snap","doze_jerk"]
## Events the sleeper stays awake once woken, before nodding off again.
const DOZE_AGAIN:=10
## How often a light moment gets a bit, by kind (a ruler's line is common, so
## it rarely does; a terror nearly always draws something from the room).
const BIT_CHANCE:={"line":0.22,"god_speaks":0.28,"divine":0.75,"command":0.6,"decree":0.55,"gift":0.8,"summon":0.55,"promise":0.35,
	"dismiss":0.35,"terrify_envoy":0.9,"envoy_insulted":0.8,"exit":0.5}
## About one event in four gets a muttered line, at most one, never two
## events running.
const ASIDE_CHANCE:=0.28
const ASIDE_GAP:=2

# =============================================================================
# Beats
# =============================================================================

## The whole room's beats for one engine event. memory: the stage's own
## presentation memory (cooldowns, who dozes, what played last); pass the same
## dictionary for every event of a session, or {} for a one-off.
static func beats(event:Dictionary,cast:Array,facts:Dictionary,rng_seed:int,memory:Dictionary={})->Array:
	var kind:=String(event.get("kind",""))
	var out:Array=[]
	var sig:=""
	var last:=String((memory.get("sig",{}) as Dictionary).get(kind,"")) if memory.get("sig") is Dictionary else ""
	var ctx:Dictionary={}
	# The same kind of moment never plays out the same way twice running.
	for attempt in 4:
		ctx=_context(event,cast,facts,rng_seed+attempt*7919,memory)
		out=_direct(ctx)
		out=_agree(out,ctx)
		sig=_signature(out)
		if sig.is_empty() or sig!=last:break
	out.sort_custom(_earlier)
	_remember(memory,ctx,sig,out)
	return out

static func _earlier(a:Dictionary,b:Dictionary)->bool:
	if not is_equal_approx(float(a.t),float(b.t)):return float(a.t)<float(b.t)
	if String(a.who)!=String(b.who):return String(a.who)<String(b.who)
	return String(a.act)<String(b.act)

static func _signature(out:Array)->String:
	var parts:PackedStringArray=PackedStringArray()
	for beat:Dictionary in out:
		if String(beat.who) in ["camera","room"]:continue
		parts.append("%s:%s" % [beat.who,beat.act])
	parts.sort()
	return "|".join(parts)

static func _context(event:Dictionary,cast:Array,facts:Dictionary,rng_seed:int,memory:Dictionary)->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%s|director" % [rng_seed,String(event.get("kind",""))])
	var members:Array=[]
	var by_key:Dictionary={}
	var index:=0
	for entry in cast:
		if not entry is Dictionary:continue
		var m:=member(entry,index)
		if String(m.key).is_empty() or by_key.has(String(m.key)):continue
		members.append(m);by_key[String(m.key)]=m
		index+=1
	var n:=int(memory.get("n",0))
	return {"event":event,"kind":String(event.get("kind","")),"cast":members,"by":by_key,"facts":facts,"rng":rng,"memory":memory,"n":n,
		"gravity":_gravity(event),"bits":[],"stars":{},"star":"","firm":_firm(event),"gone":_gone(event),"main":_main_key(members)}

## Remembers what played: the event count, each bit's last outing, the
## sleeper's waking and this kind's last signature.
static func _remember(memory:Dictionary,ctx:Dictionary,sig:String,out:Array)->void:
	var n:=int(memory.get("n",0))+1
	memory["n"]=n
	if not memory.get("bits") is Dictionary:memory["bits"]={}
	for bit in ctx.bits:(memory.bits as Dictionary)[String(bit)]=n
	if not memory.get("sig") is Dictionary:memory["sig"]={}
	(memory.sig as Dictionary)[String(ctx.kind)]=sig
	if ctx.has("woke"):memory["woke"]=n
	# What just played and on whom, and when each was done: a muttered line
	# may answer it (asides).
	var ends:={}
	for beat:Dictionary in out:
		var who:=String(beat.who)
		ends[who]=maxf(float(ends.get(who,0.0)),float(beat.t)+float((beat.args as Dictionary).get("dur",0.8)))
	var played:={}
	for bit in (ctx.stars as Dictionary):
		var star:=String(ctx.stars[bit])
		played[String(bit)]={"star":star,"end":float(ends.get(star,2.5))}
	memory["last"]={"n":n,"played":played,"number":int(ctx.get("number",-1)),"number_from":String(ctx.get("number_from",""))}

## How grave the moment is: "grave" (a death, a casting out), "tense"
## (wrath, a refusal, an insult) or "light".
static func _gravity(event:Dictionary)->String:
	var kind:=String(event.get("kind",""))
	var action:=String(event.get("action",""))
	match kind:
		"divine":
			if action in ["strike_down","cast_out"]:return "grave"
			if action in ["terrify","penance"]:return "tense"
		"command":
			if String(event.get("verb","")) in ["kill","maim"] and bool(event.get("executed",false)):return "grave"
			if String(event.get("obedience",""))=="refuse" or String(event.get("verb","")) in ["kill","maim","detain","exile"]:return "tense"
		"exit":
			if String(event.get("style","")) in ["fall"]:return "grave"
			if String(event.get("style","")) in ["led","storm","flee"]:return "tense"
		"terrify_envoy","envoy_insulted":return "tense"
	return "light"

## The one the engine says stood firm: they never bow, kneel or shake.
static func _firm(event:Dictionary)->String:
	match String(event.get("kind","")):
		"divine","terrify_envoy":
			if String(event.get("response","")) in ["defy","defiant","refuse"]:return String(event.get("target",""))
		"command":
			if String(event.get("obedience",""))=="refuse":return String(event.get("actor",""))
	return ""

## Who leaves the world in this event (a death, a casting out): nothing more
## is asked of them after the action.
static func _gone(event:Dictionary)->String:
	match String(event.get("kind","")):
		"divine":
			if String(event.get("action","")) in ["strike_down","cast_out"]:return String(event.get("target",""))
		"command":
			if bool(event.get("removed",false)) and String(event.get("verb","")) in ["kill","exile"]:return String(event.get("target",""))
	return ""

static func _main_key(members:Array)->String:
	for m:Dictionary in members:
		if String(m.role)=="main":return String(m.key)
	return ""

## One cast entry with every field the director reads, defaults filled.
## kind: official, hearth_chief, petitioner, envoy, guard, bearer, attendant,
## commoner, elder, child, dog, goat.
static func member(entry:Dictionary,index:=0)->Dictionary:
	var role:=String(entry.get("role","court"))
	var age:=int(entry.get("age",35))
	var kind:=String(entry.get("kind",""))
	if kind.is_empty():
		match role:
			"main":kind="petitioner"
			"attendant":kind="attendant"
			"animal":kind="dog"
			"crowd":kind="child" if age<14 else ("elder" if age>=56 else "commoner")
			_:kind="official"
	var name:=String(entry.get("name",""))
	if name.is_empty():name=String({"dog":"the dog","goat":"the goat"}.get(kind,"someone"))
	var m:={"key":String(entry.get("key","")),"name":name,"given":name.get_slice(" ",0),"role":role,"kind":kind,"age":age,
		"courage":clampf(float(entry.get("courage",0.5)),0.0,1.0),"pride":clampf(float(entry.get("pride",0.5)),0.0,1.0),
		"empathy":clampf(float(entry.get("empathy",0.5)),0.0,1.0),"love":clampf(float(entry.get("love",0.4)),0.0,1.0),
		"dread":clampf(float(entry.get("dread",0.2)),0.0,1.0),"resentment":clampf(float(entry.get("resentment",0.0)),0.0,1.0),
		"voice":String(entry.get("voice","")),"stance":String(entry.get("stance","")),"office":String(entry.get("office","")),
		"x":float(entry.get("x",-1.0)),"index":index}
	m["animal"]=kind in ["dog","goat"]
	# How hard they flinch, and how soon: the frightened and the timid first.
	m["jumpy"]=clampf(float(m.dread)*0.6+(1.0-float(m.courage))*0.5,0.0,1.0)
	return m

## A cast entry from a game person (an official, the one before the god):
## their courage, pride, warmth and their love and dread of the god, read the
## way divine_regard.gd reads them. extra: key, role, kind, voice (their
## lifelong voice model), stance, x (where they stand, 0..1 of the stage).
static func cast_member(person:Dictionary,extra:Dictionary={})->Dictionary:
	var divine:GDScript=load("res://scripts/divine_regard.gd")
	var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
	var rel:Dictionary=divine.call("sovereign",person)
	var age:Variant=person.get("age",35)
	var years:=int(age) if (age is int or age is float) else (66 if String(age).to_lower() in ["old","elder","aged"] else (10 if String(age).to_lower()=="child" else 35))
	var entry:={"name":String(person.get("name","")),"person_id":int(person.get("person_id",0)),"age":years,
		"courage":float(person.get("courage",0.5)),"pride":float(person.get("pride",0.5)),"empathy":float(personality.get("empathy",0.5)),
		"love":float(divine.call("love_of",person)),"dread":float(divine.call("dread_of",person)),"resentment":float(rel.get("resentment",0.0)),
		"office":String(person.get("office_title",person.get("title",""))),"voice":String(person.get("voice_model",""))}
	if String(person.get("office_key",""))=="settlement":entry["kind"]="hearth_chief"
	entry.merge(extra,true)
	return entry

## The people who stand about the hall besides the court: an old one, a
## child, someone of the camp with a bowl, the dog, and a goat once the people
## keep penned herds (era tag "dairy": animal_taming, pack_animals). Their love
## and dread of the god are the people's own (facts people_love and
## people_dread), each a little their own. Named in the people's tongue
## (era_names.gd) when the game is running; `taken` keeps names unshared.
## Keys: crowd_elder, crowd_child, crowd_bowl, dog, goat.
static func extras(facts:Dictionary,rng_seed:int,taken:Dictionary={})->Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|extras" % rng_seed)
	var dread:=people_dread(facts)
	var love:=people_love(facts) if _num(facts.get("people_love",null)) else 0.45
	var out:Array=[]
	var people:=[["crowd_elder","elder",62+rng.randi_range(0,14)],["crowd_child","child",5+rng.randi_range(0,5)],["crowd_bowl","commoner",22+rng.randi_range(0,20)]]
	var serial:=0
	for row in people:
		var woman:=rng.randf()<0.5
		var entry:={"key":String(row[0]),"role":"crowd","kind":String(row[1]),"age":int(row[2]),"sex":"female" if woman else "male",
			"courage":clampf(0.5+rng.randf_range(-0.25,0.25)-(0.15 if String(row[1])=="child" else 0.0),0.05,0.95),"pride":clampf(rng.randf_range(0.15,0.55),0.0,1.0),
			"empathy":clampf(rng.randf_range(0.35,0.8),0.0,1.0),"love":clampf(love+rng.randf_range(-0.12,0.12),0.0,1.0),"dread":clampf(dread+rng.randf_range(-0.1,0.15),0.0,1.0),
			"name":_crowd_name(rng_seed,serial,woman,taken)}
		if String(row[1])=="commoner":entry["stance"]="bowl"
		out.append(entry)
		serial+=1
	out.append({"key":"dog","role":"animal","kind":"dog","name":"the dog"})
	var tags:Array=facts.get("era_tags",[]) if facts.get("era_tags") is Array else []
	if tags.has("dairy"):out.append({"key":"goat","role":"animal","kind":"goat","name":"the goat"})
	return out

static func _crowd_name(rng_seed:int,serial:int,woman:bool,taken:Dictionary)->String:
	if Engine.get_main_loop()==null or not ResourceLoader.exists("res://scripts/era_names.gd"):return ""
	var made:Dictionary=(load("res://scripts/era_names.gd") as GDScript).call("make",int(GameState.world_seed),900000+posmod(rng_seed,9000)*10+serial,woman,"player",taken)
	var name:=String(made.get("name",""))
	if not name.is_empty():
		taken[name]=true
		taken["given:"+String(made.get("given",name.get_slice(" ",0)))]=true
	return name

## How a beat is played until the acting layer has its own clip for it:
## {clip, mood, face, look, hold, speed, dur} (clip/mood from the figures'
## own set; look: "god", "god_up", "at", "away" or "").
static func performance(beat:Dictionary)->Dictionary:
	var spec:Dictionary=ACTS.get(String(beat.get("act","")),{})
	var args:Dictionary=beat.get("args",{}) if beat.get("args") is Dictionary else {}
	return {"clip":String(spec.get("clip","")),"mood":String(spec.get("mood","")),"face":(spec.get("face",{}) as Dictionary).duplicate(),
		"look":String(spec.get("look","")),"at":String(args.get("at","")),"hold":bool(spec.get("hold",false)),
		"speed":float(args.get("speed",spec.get("speed",1.0))),"dur":float(args.get("dur",spec.get("dur",0.8)))}

# --- The cast, read ------------------------------------------------------------

static func _m(ctx:Dictionary,key:String)->Dictionary:
	return (ctx.by as Dictionary).get(key,{})

static func _people(ctx:Dictionary,exclude:Array=[])->Array:
	var out:Array=[]
	for m:Dictionary in ctx.cast:
		if bool(m.animal) or String(m.key) in exclude:continue
		out.append(m)
	return out

static func _of_kind(ctx:Dictionary,kinds:Array,exclude:Array=[])->Array:
	var out:Array=[]
	for m:Dictionary in ctx.cast:
		if String(m.kind) in kinds and not String(m.key) in exclude:out.append(m)
	return out

static func _pick(ctx:Dictionary,list:Array)->Dictionary:
	if list.is_empty():return {}
	return list[(ctx.rng as RandomNumberGenerator).randi_range(0,list.size()-1)]

static func _where(m:Dictionary)->float:
	return float(m.x) if float(m.x)>=0.0 else float(m.index)*0.12

## The nearest person to m (by where they stand), of the kinds given.
static func _nearest(ctx:Dictionary,m:Dictionary,kinds:Array=[],exclude:Array=[])->Dictionary:
	var best:={};var gap:=INF
	for o:Dictionary in ctx.cast:
		if String(o.key)==String(m.key) or String(o.key) in exclude:continue
		if bool(o.animal) and not ("dog" in kinds or "goat" in kinds):continue
		if not kinds.is_empty() and not String(o.kind) in kinds:continue
		var d:=absf(_where(o)-_where(m))+float(o.index)*0.0001
		if d<gap:gap=d;best=o
	return best

static func _jumpiest(list:Array)->Array:
	var out:=list.duplicate()
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.jumpy)>float(b.jumpy) if not is_equal_approx(float(a.jumpy),float(b.jumpy)) else int(a.index)<int(b.index))
	return out

## How long after the blow lands this person reacts: the jumpy at once, the
## brave and the proud a little later, with a breath of chance.
static func _lag(ctx:Dictionary,m:Dictionary)->float:
	return 0.05+0.30*(1.0-float(m.jumpy))+(ctx.rng as RandomNumberGenerator).randf()*0.14

# --- Facts, read -------------------------------------------------------------------

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func hungry(facts:Dictionary)->bool:
	return _num(facts.get("food_days",null)) and float(facts.food_days)<HUNGRY_DAYS

static func starving(facts:Dictionary)->bool:
	return _num(facts.get("food_days",null)) and float(facts.food_days)<STARVING_DAYS

static func full(facts:Dictionary)->bool:
	return _num(facts.get("food_days",null)) and float(facts.food_days)>=FULL_DAYS

static func sickness(facts:Dictionary)->Dictionary:
	return facts.get("sickness",{}) if facts.get("sickness") is Dictionary else {}

static func war(facts:Dictionary)->Dictionary:
	return facts.get("war",{}) if facts.get("war") is Dictionary else {}

static func people_dread(facts:Dictionary)->float:
	return float(facts.get("people_dread",0.0)) if _num(facts.get("people_dread",null)) else 0.0

static func people_love(facts:Dictionary)->float:
	return float(facts.get("people_love",0.0)) if _num(facts.get("people_love",null)) else 0.0

## Food in sight: a gift of food carried in, or a boon of food from the stores.
static func _food_in_sight(event:Dictionary,facts:Dictionary)->bool:
	var terms:Dictionary=event.get("terms",{}) if event.get("terms") is Dictionary else {}
	if String(terms.get("resource","")).to_lower()=="food":return true
	var gift:Dictionary=facts.get("gift",{}) if facts.get("gift") is Dictionary else {}
	return String(gift.get("resource","")).to_lower()=="food"

## The one who dozes through the audience: an old person in the crowd or
## among the officials, while nobody is in terror. The same each time for a
## cast, so ambient and the god's voice agree on who wakes.
static func dozer(cast:Array,facts:Dictionary)->String:
	if people_dread(facts)>=DREAD_HIGH:return ""
	var best:="";var best_age:=0
	for entry in cast:
		if not entry is Dictionary:continue
		var m:=member(entry)
		if String(m.role)=="main" or bool(m.animal) or String(m.kind) in ["envoy","guard","bearer","attendant","child"]:continue
		if int(m.age)>=58 and float(m.dread)<0.5 and int(m.age)>best_age:best=String(m.key);best_age=int(m.age)
	return best

# --- Writing beats -------------------------------------------------------------------

static func _beat(out:Array,t:float,who:String,act:String,args:Dictionary={},phase:="reaction")->void:
	var spec:Dictionary=ACTS.get(act,{})
	var a:=args.duplicate()
	if not a.has("dur"):a["dur"]=float(spec.get("dur",0.8))
	if spec.has("speed") and not a.has("speed"):a["speed"]=float(spec.speed)
	out.append({"t":snappedf(maxf(t,0.0),0.01),"who":who,"act":act,"args":a,"phase":phase})

static func _shot(out:Array,t:float,shot:String,args:Dictionary={})->void:
	_beat(out,t,"camera",shot,args,"camera")

## A bit was played: remembered with the one it fell on (the star), so a
## muttered line can answer it.
static func _ran(ctx:Dictionary,bit:String)->void:
	if not (ctx.bits as Array).has(bit):(ctx.bits as Array).append(bit)
	(ctx.stars as Dictionary)[bit]=String(ctx.get("star",""))
	ctx["star"]=""

## Is a bit open now: fits this kind, rested, and the room can play it.
static func _rested(ctx:Dictionary,bit:String)->bool:
	var spec:Dictionary=BITS.get(bit,{})
	if not String(ctx.kind) in (spec.get("kinds",[]) as Array):return false
	# A startle (a bowl dropped, a faint, a child hiding) needs wrath, not favour.
	if bool(spec.get("wrath",false)) and String(ctx.kind) in ["divine","command"] and String(ctx.gravity)!="tense":return false
	var memory:Dictionary=ctx.memory
	var last:=int((memory.get("bits",{}) as Dictionary).get(bit,-1000)) if memory.get("bits") is Dictionary else -1000
	return int(ctx.n)+1-last>int(spec.get("rest",3))

## Chooses up to `count` bits the room can play now, weighted, the longer
## rested a little more likely, and plays them.
static func _play_bits(ctx:Dictionary,out:Array,at:float,count:=1)->void:
	if String(ctx.gravity)=="grave":return
	var rng:RandomNumberGenerator=ctx.rng
	if rng.randf()>float(BIT_CHANCE.get(String(ctx.kind),0.4)):return
	var open:Array=[]
	var total:=0.0
	for bit:String in BITS:
		if bit in DIRECT_BITS or (ctx.bits as Array).has(bit):continue
		if not _rested(ctx,bit) or not _can(ctx,bit):continue
		var last:=int((ctx.memory.get("bits",{}) as Dictionary).get(bit,-1000)) if ctx.memory.get("bits") is Dictionary else -1000
		var rest:=float(int(ctx.n)-last)
		var w:=float(BITS[bit].weight)*clampf(0.8+rest*0.03,0.8,1.6)
		open.append([bit,w]);total+=w
	for i in count:
		if open.is_empty() or total<=0.0:return
		var roll:=rng.randf()*total
		var chosen:=0
		for j in open.size():
			roll-=float(open[j][1])
			if roll<=0.0:chosen=j;break
		var bit:=String(open[chosen][0])
		total-=float(open[chosen][1]);open.remove_at(chosen)
		if _bit(ctx,bit,out,at+float(i)*0.5):_ran(ctx,bit)

# =============================================================================
# The moments
# =============================================================================

static func _direct(ctx:Dictionary)->Array:
	var out:Array=[]
	match String(ctx.kind):
		"god_speaks":_god_speaks(ctx,out)
		"line":_line(ctx,out)
		"divine":_divine(ctx,out)
		"command":_command(ctx,out)
		"decree":_decree(ctx,out)
		"promise":_promise(ctx,out)
		"dismiss":_dismiss(ctx,out)
		"gift":_gift(ctx,out)
		"summon":_summon(ctx,out)
		"exit":_exit(ctx,out)
		"terrify_envoy":_terrify_envoy(ctx,out)
		"envoy_insulted":_insulted(ctx,out)
	return out

## The god speaks: the room stills and every face lifts toward the voice, a
## ripple from the one before the god outward. The goat does not care.
static func _god_speaks(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	_beat(out,0.0,"room","hush",{"dur":1.6},"anticipation")
	var main:=_m(ctx,String(ctx.main))
	var order:Array=_people(ctx)
	var origin:=_where(main) if not main.is_empty() else 0.5
	order.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return absf(_where(a)-origin)<absf(_where(b)-origin) if not is_equal_approx(absf(_where(a)-origin),absf(_where(b)-origin)) else int(a.index)<int(b.index))
	var sleeper:=_asleep(ctx)
	var step:=0
	for m:Dictionary in order:
		if String(m.key)==sleeper:continue
		_beat(out,0.05+step*0.07+(ctx.rng as RandomNumberGenerator).randf()*0.08,String(m.key),"look_up",{},"action")
		step+=1
	for dog:Dictionary in _of_kind(ctx,["dog"]):_beat(out,0.2,String(dog.key),"perk_up",{},"action")
	# The voice usually wakes the sleeper, a beat behind everyone; now and
	# then they sleep straight through it.
	if not sleeper.is_empty() and (ctx.rng as RandomNumberGenerator).randf()<0.75:_wake(ctx,out,0.9)
	# The god's voice in a room that dreads it: someone trembles under it.
	if people_dread(ctx.facts)>=DREAD_HIGH:
		var shaky:Array=_jumpiest(_people(ctx,[String(ctx.main)]))
		if not shaky.is_empty():_beat(out,0.6,String((shaky[0] as Dictionary).key),"glance_up",{"because":"people_dread"},"reaction")
	_play_bits(ctx,out,0.4)
	if String(event.get("tone",""))=="favor" and people_love(ctx.facts)>=LOVE_HIGH:
		var warm:Array=_people(ctx,[String(ctx.main)])
		if not warm.is_empty():_beat(out,1.0,String(_pick(ctx,warm).key),"lean_in",{"because":"people_love"},"reaction")

## A line said: the speaker talks (the stage does that). Around them, now and
## then, someone reacts: a number said lands as a double take timed to when
## the number appears in the bubble.
static func _line(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",""))
	# A listener nods along when the speaker is someone they love the god with.
	var listeners:Array=_people(ctx,[who])
	if listeners.is_empty():return
	if (ctx.rng as RandomNumberGenerator).randf()<0.35:
		var nodder:=_pick(ctx,listeners)
		if float(nodder.love)>=0.45:_beat(out,1.2+(ctx.rng as RandomNumberGenerator).randf()*0.8,String(nodder.key),"nod",{},"reaction")
		else:_beat(out,1.4+(ctx.rng as RandomNumberGenerator).randf()*0.8,String(nodder.key),"shift_weight",{},"reaction")
	_play_bits(ctx,out,0.8)

## The first number said in a line, and when it shows as the words reveal.
static func number_in(text:String)->Dictionary:
	var re:=RegEx.new();re.compile("\\b(\\d[\\d,]*)\\b")
	var hit:=re.search(text)
	if hit==null:return {}
	var value:=int(hit.get_string(1).replace(",",""))
	if value<2:return {}
	return {"value":value,"text":hit.get_string(1),"at":hit.get_start()}

## Wrath and favour, as the engine rolled them.
static func _divine(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var action:=String(event.get("action",""))
	var target:=String(event.get("target",ctx.main))
	var response:=String(event.get("response",""))
	match action:
		"terrify","penance":_wrath(ctx,out,action,target,response)
		"bless","boon","raise_up":_favour(ctx,out,action,target,response)
		"strike_down":_death(ctx,out,target)
		"cast_out":_cast_out(ctx,out,target)

static func _wrath(ctx:Dictionary,out:Array,action:String,target:String,response:String)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var t_m:=_m(ctx,target)
	var big:=action=="terrify"
	# Anticipation: the room stills, the camera goes in on them.
	_beat(out,0.0,"room","hush",{"dur":3.6 if big else 2.4},"anticipation")
	if not t_m.is_empty():_shot(out,0.0,"push_in",{"target":target})
	var sleeper:=_asleep(ctx)
	for m:Dictionary in _people(ctx,[target,sleeper]):
		if rng.randf()<(0.75 if big else 0.4):_beat(out,0.08+rng.randf()*0.2,String(m.key),"freeze",{},"anticipation")
	# The action: what the engine says they did.
	var land:=0.55 if big else 0.7
	if big:_shot(out,land,"shake",{"strength":0.3})
	if not t_m.is_empty():
		match response:
			"defy","defiant":
				_beat(out,land,target,"stand_firm",{},"action")
				_beat(out,land+0.7,target,"hold_gaze",{},"action")
				# Brave, and human: they swallow once they think nobody sees.
				_beat(out,land+2.6,target,"gulp",{},"hold")
			"cower":
				_beat(out,land,target,"flinch",{},"action")
				if big:_beat(out,land+0.35,target,"knees_knock",{"dur":1.3},"action")
				_beat(out,land+(1.5 if big else 0.6),target,"kneel",{},"action")
			_:
				_beat(out,land+0.1,target,"flinch",{"dur":0.4},"action")
				_beat(out,land+0.5,target,"head_down",{},"action")
	# The reaction, from what each witness's own temper made of it.
	var witnesses:Dictionary=ctx.event.get("witnesses",{}) if ctx.event.get("witnesses") is Dictionary else {}
	var start:=land+0.25
	for m:Dictionary in _people(ctx,[target,sleeper]):
		var key:=String(m.key)
		var said:=String(witnesses.get(key,_witness(action,m)))
		var t:=start+_lag(ctx,m)
		if said=="unbowed":
			if rng.randf()<0.6:_beat(out,t+0.3,key,"cross_arms" if float(m.pride)>0.7 else "lips_pressed",{},"reaction")
			continue
		# Not everyone shows it: some go still and stay still.
		if rng.randf()>(0.8 if big and response!="defy" else 0.45):continue
		var menu:Array
		if float(m.jumpy)>=0.55:menu=["flinch","flinch","step_back","tremble","hand_to_mouth"] if big else ["wring_hands","glance_up","lips_pressed"]
		elif float(m.jumpy)>=0.35:menu=["flinch","look_away","hand_to_mouth","lips_pressed"] if big else ["lips_pressed","look_away","glance_up"]
		else:menu=["lips_pressed","straighten","flinch"] if big else ["lips_pressed","straighten"]
		var act:String=menu[rng.randi_range(0,menu.size()-1)]
		_beat(out,t,key,act,{"dur":0.5} if act=="flinch" and float(m.jumpy)<0.55 else {},"reaction")
		if act=="flinch" and float(m.jumpy)>=0.55 and rng.randf()<0.4:_beat(out,t+0.5,key,"step_back",{},"reaction")
	# When they stood up to it, the room cannot believe it: the whole room
	# gasps and then pretends it didn't, or one gasp and two officials' look.
	var defied:=response in ["defy","defiant"]
	if defied and _rested(ctx,"gasp_pretend") and _can(ctx,"gasp_pretend") and rng.randf()<0.6:
		_gasp(ctx,out,land+1.0,[target,sleeper])
	elif defied:
		var aghast:Array=_shuffled(rng,_people(ctx,[target,sleeper]))
		if not aghast.is_empty():_beat(out,land+0.95,String((aghast[0] as Dictionary).key),"gasp",{},"reaction")
		var two:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[target]))
		if two.size()>=2:
			var a:Dictionary=two[0];var b:Dictionary=two[1]
			_beat(out,land+1.4,String(a.key),"exchange_look",{"at":String(b.key)},"reaction")
			_beat(out,land+1.5,String(b.key),"exchange_look",{"at":String(a.key)},"reaction")
	# Fury wakes anyone.
	if big and not _asleep(ctx).is_empty():_wake(ctx,out,land+0.2)
	# Penance is a fast: where the stores already run short, the room feels it.
	if action=="penance" and hungry(ctx.facts):
		var bellies:Array=_people(ctx,[target])
		if not bellies.is_empty():_beat(out,land+1.6,String(_pick(ctx,bellies).key),"rub_belly",{"because":"food_days"},"reaction")
	# A defiance holds the room by itself: one bit at most; a terror, two.
	_play_bits(ctx,out,land+0.9,2 if big and not defied else 1)
	# The hold: nobody moves; then the room breathes again.
	var hold:=land+(2.9 if big else 2.2)
	_beat(out,hold,"room","hush",{"dur":0.9},"hold")
	if not ctx.bits.has("gasp_pretend") and big:
		var shaken:Array=_jumpiest(_people(ctx,[target,String(ctx.get("fainted","")),sleeper]))
		if not shaken.is_empty():_beat(out,hold+0.7,String((shaken[0] as Dictionary).key),"straighten",{},"hold")
	_shot(out,hold+0.6,"wide")

## How a witness meets the god's act (divine_regard.gd witness_response):
## used only when the engine's own reading of them is not given.
static func _witness(action:String,m:Dictionary)->String:
	if action in ["terrify","penance","cast_out","strike_down"]:
		return "unbowed" if float(m.pride)>0.72 and float(m.courage)>0.68 else "shaken"
	var bar:=float({"bless":0.7,"boon":0.65,"raise_up":0.6}.get(action,0.7))
	return "envy" if float(m.pride)>bar else "glad"

static func _favour(ctx:Dictionary,out:Array,action:String,target:String,response:String)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var t_m:=_m(ctx,target)
	if not t_m.is_empty():_shot(out,0.0,"push_in",{"target":target})
	_beat(out,0.0,"room","hush",{"dur":1.2},"anticipation")
	if not t_m.is_empty():
		if response=="relief":
			_beat(out,0.5,target,"exhale",{},"action")
			_beat(out,1.2,target,"bow",{},"action")
		else:
			_beat(out,0.5,target,"beam",{},"action")
			_beat(out,1.1,target,"bow",{},"action")
	var witnesses:Dictionary=ctx.event.get("witnesses",{}) if ctx.event.get("witnesses") is Dictionary else {}
	var envier:={}
	for m:Dictionary in _people(ctx,[target]):
		var key:=String(m.key)
		var said:=String(witnesses.get(key,_witness(action,m)))
		var t:=1.0+_lag(ctx,m)
		if said=="envy":
			_beat(out,t,key,"side_eye",{"at":target},"reaction")
			if envier.is_empty():envier=m
		elif rng.randf()<0.45:
			_beat(out,t,key,"smile_warm" if float(m.love)>=0.4 else "nod",{},"reaction")
	if not envier.is_empty() and not t_m.is_empty():_shot(out,1.6,"two_shot",{"a":target,"b":String(envier.key)})
	# A gift of food from the stores while people go short: every eye on it.
	var terms:Dictionary=ctx.event.get("terms",{}) if ctx.event.get("terms") is Dictionary else {}
	if action=="boon" and String(terms.get("resource","")).to_lower()=="food" and hungry(ctx.facts):
		var eyes:Array=_shuffled(ctx.rng,_people(ctx,[target]))
		for i in mini(2 if not starving(ctx.facts) else 3,eyes.size()):
			_beat(out,1.4+i*0.3,String((eyes[i] as Dictionary).key),"eye_food",{"at":target,"because":"food_days"},"reaction")
	_play_bits(ctx,out,1.3)
	_beat(out,3.0,"room","hush",{"dur":0.6},"hold")

## A death at the god's word: no comedy. The room goes still, looks away,
## covers the children's eyes; the proud make themselves watch.
static func _death(ctx:Dictionary,out:Array,target:String)->void:
	var rng:RandomNumberGenerator=ctx.rng
	_beat(out,0.0,"room","hush",{"dur":5.0},"anticipation")
	_shot(out,0.0,"wide")
	if not _m(ctx,target).is_empty():_beat(out,0.3,target,"stricken",{},"action")
	var loving:={}
	for m:Dictionary in _people(ctx,[target]):
		var key:=String(m.key)
		var t:=0.9+_lag(ctx,m)*1.5
		if String(m.kind)=="child":continue
		if float(m.pride)>0.72 and float(m.courage)>0.68:_beat(out,t,key,"stand_firm",{"dur":3.0},"reaction")
		elif float(m.empathy)>=0.6 or float(m.love)>=0.6:
			_beat(out,t,key,"hand_to_mouth",{},"reaction")
			if loving.is_empty():loving=m
		else:
			var act:String=["look_away","look_away","lips_pressed","freeze"][rng.randi_range(0,3)]
			_beat(out,t,key,act,{},"reaction")
	for child:Dictionary in _of_kind(ctx,["child"]):
		var adult:=_nearest(ctx,child,["elder","commoner","official","hearth_chief"])
		if not adult.is_empty():_beat(out,1.0+rng.randf()*0.3,String(adult.key),"cover_eyes",{"at":String(child.key)},"reaction")
	for dog:Dictionary in _of_kind(ctx,["dog"]):_beat(out,2.2,String(dog.key),"whimper",{},"hold")
	if not loving.is_empty():_shot(out,1.6,"reaction",{"target":String(loving.key)})
	_shot(out,3.8,"wide")

static func _cast_out(ctx:Dictionary,out:Array,target:String)->void:
	_beat(out,0.0,"room","hush",{"dur":3.6},"anticipation")
	if not _m(ctx,target).is_empty():_beat(out,0.3,target,"stricken",{},"action")
	for m:Dictionary in _people(ctx,[target]):
		var t:=0.8+_lag(ctx,m)
		if absf(_where(m)-_where(_m(ctx,target)))<0.2:_beat(out,t,String(m.key),"edge_away",{"at":target},"reaction")
		elif float(m.love)>=0.5 or float(m.empathy)>=0.6:_beat(out,t+0.6,String(m.key),"watch_go",{"at":target},"reaction")
		else:_beat(out,t+0.4,String(m.key),"look_away",{},"reaction")
	_shot(out,0.0,"wide")
	_beat(out,3.0,"room","hush",{"dur":0.8},"hold")

## An order given in the hall, with the engine's obedience.
static func _command(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var actor:=String(event.get("actor",""))
	var target:=String(event.get("target",""))
	var verb:=String(event.get("verb",""))
	var stage:=String(event.get("stage",verb))
	var rng:RandomNumberGenerator=ctx.rng
	if stage=="prostrate":
		# A hand raised against the god: the whole court falls on its face,
		# and someone is a beat late.
		_shot(out,0.0,"wide")
		var all:Array=_people(ctx)
		var late:={}
		if all.size()>=3:late=_pick(ctx,all)
		for m:Dictionary in all:
			if String(m.key)==String(late.get("key","")):continue
			_beat(out,0.2+rng.randf()*0.35,String(m.key),"prostrate",{},"action")
		if not late.is_empty():
			_beat(out,0.7,String(late.key),"look_wrong_way",{},"reaction")
			_beat(out,1.4,String(late.key),"prostrate",{},"reaction")
			ctx["star"]=String(late.key)
			_ran(ctx,"late_prostrate")
		for dog:Dictionary in _of_kind(ctx,["dog"]):_beat(out,1.0,String(dog.key),"lie_down",{},"reaction")
		return
	if _odd(ctx):
		_absurd(ctx,out,actor)
		return
	var ob:=String(event.get("obedience","obey"))
	var manner:=String(event.get("manner",""))
	var a_m:=_m(ctx,actor)
	if not a_m.is_empty():
		match ob:
			"refuse":
				_shot(out,0.0,"push_in",{"target":actor})
				_beat(out,0.5,actor,"shake_head",{},"action")
				_beat(out,1.0,actor,"stand_firm",{},"action")
				_gasp(ctx,out,1.1,[actor])
				if stage=="refuse_flee":_beat(out,2.0,actor,"bolt",{},"action")
				elif stage=="refuse_seized":
					var hands:Array=_of_kind(ctx,["guard","official","hearth_chief","commoner"],[actor,String(ctx.main)])
					hands.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.courage)>float(b.courage) if not is_equal_approx(float(a.courage),float(b.courage)) else int(a.index)<int(b.index))
					for i in mini(2,hands.size()):_beat(out,2.0+i*0.2,String((hands[i] as Dictionary).key),"grab",{"at":actor},"action")
					_beat(out,2.8,actor,"kneel_bound",{},"action")
				_shot(out,3.2,"wide")
				return
			"hesitate":
				_beat(out,0.4,actor,"hesitate",{},"action")
				_beat(out,1.4,actor,"plead",{},"action")
			"reluctant":
				_beat(out,0.4,actor,"hesitate",{"dur":1.0},"action")
				_beat(out,1.2,actor,"look_at",{"at":target if target!="" else String(ctx.main)},"action")
				_beat(out,2.0,actor,"nod",{"dur":1.0},"action")
			_:
				var takes:Array
				if manner=="trembling":takes=[["flinch","hurry"],["flinch","bow_small"],["gulp","hurry"],["wring_hands","nod"]]
				elif manner=="grim":takes=[["lips_pressed","nod"],["look_at","nod"],["straighten","nod"]]
				else:takes=[["nod"],["bow_small"],["straighten","nod"],["nod","hurry"]]
				var take:Array=takes[rng.randi_range(0,takes.size()-1)]
				for i in take.size():
					var act:=String(take[i])
					_beat(out,0.3+i*0.5,actor,act,{"at":target if target!="" else String(ctx.main)} if act=="look_at" else {},"action")
				# Someone watches them go to it.
				var watchers:Array=_people(ctx,[actor,target])
				if not watchers.is_empty() and rng.randf()<0.45:_beat(out,1.2+rng.randf()*0.5,String(_pick(ctx,watchers).key),"look_at",{"at":actor},"reaction")
	# A cruel order: the officials look at one another; nobody laughs.
	if verb in ["kill","maim","detain","exile"]:
		var two:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[actor,target]))
		if two.size()>=2:
			_beat(out,1.2,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"reaction")
			_beat(out,1.3,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"reaction")
		# The rest take it each in their own way, and quietly.
		for m:Dictionary in _people(ctx,[actor,target]+two.slice(0,2).map(func(x:Dictionary)->String:return String(x.key))):
			if rng.randf()<0.5:continue
			var act:String=["look_away","lips_pressed","hand_to_mouth","freeze"][rng.randi_range(0,3)] if float(m.empathy)>=0.5 or float(m.love)>=0.5 else ["lips_pressed","look_at","freeze"][rng.randi_range(0,2)]
			_beat(out,1.0+_lag(ctx,m),String(m.key),act,{"at":actor} if act=="look_at" else {},"reaction")
		if String(ctx.gravity)!="grave":_play_bits(ctx,out,1.6)
		return
	_play_bits(ctx,out,1.0)

## An order nothing in the world can carry out (the engine said "nothing is
## done"): the one told to do it hesitates and looks round for help; the
## officials trade looks; somebody finds it funny and is elbowed for it.
static func _absurd(ctx:Dictionary,out:Array,actor:String)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var a_m:=_m(ctx,actor)
	var helpers:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[actor,String(ctx.main)]))
	if not a_m.is_empty():
		_beat(out,0.4,actor,"hesitate",{},"action")
		if not helpers.is_empty():
			var help:Dictionary=helpers[0]
			_beat(out,1.2,actor,"look_at",{"at":String(help.key)},"action")
			_beat(out,1.7,String(help.key),"shrug" if rng.randf()<0.6 else "look_away",{},"reaction")
		_beat(out,2.4,actor,"nod",{"dur":1.2,"speed":0.6},"action")
	var pair:Array=helpers.slice(1,3) if helpers.size()>=3 else helpers.slice(0,2)
	if pair.size()==2 and rng.randf()<0.7:
		_beat(out,1.5,String((pair[0] as Dictionary).key),"side_eye",{"at":String((pair[1] as Dictionary).key)},"reaction")
		_beat(out,1.8,String((pair[1] as Dictionary).key),"side_eye",{"at":String((pair[0] as Dictionary).key)},"reaction")
	if _rested(ctx,"stifle_elbow") and _can(ctx,"stifle_elbow") and rng.randf()<0.65 and _bit(ctx,"stifle_elbow",out,2.0):_ran(ctx,"stifle_elbow")
	elif rng.randf()<0.5:_play_bits(ctx,out,2.2)

## A gasp through the room, then everyone pretending it didn't happen.
static func _gasp(ctx:Dictionary,out:Array,at:float,exclude:Array)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var room:Array=_people(ctx,exclude)
	if room.size()<2:return
	for m:Dictionary in room:
		var roll:=rng.randf()
		var act:="gasp" if roll<0.6 else ("hand_to_mouth" if roll<0.8 else "freeze")
		_beat(out,at+rng.randf()*0.15,String(m.key),act,{},"reaction")
	# Then, one or two of the jumpiest pretend it never happened.
	var caught:Array=_shuffled(rng,_jumpiest(room).slice(0,3))
	var pretenders:=1+rng.randi_range(0,1)
	for i in mini(pretenders,caught.size()):_beat(out,at+1.6+i*0.25,String((caught[i] as Dictionary).key),"pretend_calm",{},"hold")
	if not caught.is_empty():ctx["star"]=String((caught[0] as Dictionary).key)
	_ran(ctx,"gasp_pretend")

## A petition answered: granted, refused, or merely heard.
static func _decree(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var who:=String(event.get("who",ctx.main))
	var reaction:=String(event.get("reaction","neutral"))
	var accepted:=bool(event.get("accepted",reaction in ["delighted","pleased"]))
	var w:=_m(ctx,who)
	if not w.is_empty():
		if accepted:
			_beat(out,0.4,who,"exhale" if float(w.dread)>=0.4 else "beam",{},"action")
			# Now and then one bow is not enough for them.
			if _bit_ready(ctx,"double_bow") and _bit(ctx,"double_bow",out,1.1):_ran(ctx,"double_bow")
			else:_beat(out,1.1,who,"bow",{},"action")
		elif reaction in ["offended","furious"]:
			_beat(out,0.4,who,"stiffen" if reaction=="furious" or float(w.pride)>0.65 else "face_fall",{},"action")
		elif reaction=="neutral" and not accepted:_beat(out,0.5,who,"face_fall",{"dur":1.0},"action")
		else:_beat(out,0.5,who,"nod",{},"action")
	var others:Array=_people(ctx,[who])
	if not accepted and not others.is_empty():
		var kind_one:Array=others.filter(func(m:Dictionary)->bool:return float(m.empathy)>=0.6)
		if not kind_one.is_empty():_beat(out,1.2,String(_pick(ctx,kind_one).key),"sympathetic_look",{"at":who},"reaction")
	_play_bits(ctx,out,1.0)

static func _bit_ready(ctx:Dictionary,bit:String,chance:=-1.0)->bool:
	## True when one of the moment's own bits plays now (rested, possible, and
	## the roll falls its way): the plain version of the moment steps aside.
	if String(ctx.gravity)=="grave":return false
	var odds:=chance if chance>=0.0 else float({"double_bow":0.4,"guard_snap":0.85 if String(ctx.kind)=="terrify_envoy" else 0.6}.get(bit,0.5))
	return _rested(ctx,bit) and _can(ctx,bit) and (ctx.rng as RandomNumberGenerator).randf()<odds

## The sleeper wakes: the voice or the fury jolts them, they look the wrong
## way, then up, a full second behind the room.
static func _wake(ctx:Dictionary,out:Array,at:float)->void:
	if (ctx.bits as Array).has("doze_jerk"):return
	if _bit(ctx,"doze_jerk",out,at):_ran(ctx,"doze_jerk")

## Whether the sleeper is asleep now, for the stage's idle business: the
## doze resumes once DOZE_AGAIN events have passed since they were woken.
static func asleep(cast:Array,facts:Dictionary,memory:Dictionary)->String:
	var key:=dozer(cast,facts)
	if key.is_empty():return ""
	return key if int(memory.get("n",0))-int(memory.get("woke",-1000))>=DOZE_AGAIN else ""

static func _promise(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",ctx.main))
	var rng:RandomNumberGenerator=ctx.rng
	var w:=_m(ctx,who)
	if not w.is_empty():
		var hope:Array=["nod","bow_small"]+(["beam"] if float(w.love)>=0.5 else ["exhale"])
		_beat(out,0.4,who,String(hope[rng.randi_range(0,hope.size()-1)]),{},"action")
	var doubters:Array=_people(ctx,[who]).filter(func(m:Dictionary)->bool:return float(m.pride)>=0.6 and float(m.love)<0.45)
	if not doubters.is_empty() and rng.randf()<0.7:_beat(out,1.0+rng.randf()*0.4,String(_pick(ctx,doubters).key),"eyes_narrow",{"at":who},"reaction")
	var two:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[who]))
	if two.size()>=2 and rng.randf()<0.4:
		_beat(out,1.5,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"reaction")
		_beat(out,1.6,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"reaction")
	_play_bits(ctx,out,1.2)

static func _dismiss(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",ctx.main))
	if not _m(ctx,who).is_empty() and String(ctx.firm)!=who:_beat(out,0.3,who,"bow_small",{},"action")
	_play_bits(ctx,out,1.0)

## A gift carried in: the bearer heaves it forward and sets it down; taken,
## eyes go to it (hungry eyes if the stores are short and it is food);
## turned away, the bearer has to pick the whole thing up again.
static func _gift(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var bearers:Array=_of_kind(ctx,["bearer"])
	if bearers.is_empty():bearers=_of_kind(ctx,["attendant"])
	var bearer:Dictionary=bearers[0] if not bearers.is_empty() else {}
	var envoy:=String(ctx.main)
	if not bearer.is_empty():
		_shot(out,0.0,"two_shot",{"a":envoy,"b":String(bearer.key)})
		_beat(out,0.0,String(bearer.key),"struggle_bundle",{},"anticipation")
		_beat(out,1.2,String(bearer.key),"set_down_bundle",{},"anticipation")
	var accepted:=bool(event.get("accepted",true))
	var food:=String(event.get("resource","")).to_lower()=="food"
	if accepted:
		if envoy!="":_beat(out,2.0,envoy,"bow_small",{},"action")
		if food and hungry(ctx.facts):
			var eyes:Array=_shuffled(ctx.rng,_people(ctx,[envoy,String(bearer.get("key",""))]).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["envoy","guard","bearer","attendant"]))
			for i in mini(3 if starving(ctx.facts) else 2,eyes.size()):
				_beat(out,2.3+i*0.25,String((eyes[i] as Dictionary).key),"eye_food",{"at":String(bearer.get("key",envoy)),"because":"food_days"},"reaction")
	else:
		if envoy!="":_beat(out,2.0,envoy,"stiffen",{},"action")
		if not bearer.is_empty():
			_beat(out,2.8,String(bearer.key),"grimace",{},"reaction")
			_beat(out,3.3,String(bearer.key),"lift_bundle",{},"reaction")
	_play_bits(ctx,out,1.6)

## Someone summoned walks in (the stage walks them): the room turns to look,
## the nearest shuffles aside, and they show what they feel coming in.
static func _summon(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",ctx.main))
	var w:=_m(ctx,who)
	for m:Dictionary in _people(ctx,[who]):
		if (ctx.rng as RandomNumberGenerator).randf()<0.7:_beat(out,0.2+_lag(ctx,m),String(m.key),"look_at",{"at":who},"anticipation")
	if not w.is_empty():
		var near:=_nearest(ctx,w,["official","hearth_chief","commoner","elder"])
		if not near.is_empty():_beat(out,1.4,String(near.key),"make_room",{"at":who},"reaction")
		if float(w.dread)>=0.5:_beat(out,1.8,who,"wring_hands",{},"action")
		elif float(w.love)>=LOVE_HIGH:_beat(out,1.8,who,"beam",{},"action")
	_play_bits(ctx,out,1.6)

## Someone goes. The stage walks them out in the engine's style; the room
## shows what it made of it.
static func _exit(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",ctx.main))
	var style:=String(ctx.event.get("style","bow"))
	var room:Array=_people(ctx,[who])
	match style:
		"fall":
			_death(ctx,out,who)
		"led":
			for m:Dictionary in room:
				if float(m.love)>=0.5 or float(m.empathy)>=0.6:_beat(out,0.6+_lag(ctx,m),String(m.key),"watch_go",{"at":who},"reaction")
				else:_beat(out,0.6+_lag(ctx,m),String(m.key),"look_away",{},"reaction")
		"storm","flee":
			_gasp(ctx,out,0.5,[who])
			var two:Array=_of_kind(ctx,["official","hearth_chief"],[who])
			if two.size()>=2:
				_beat(out,1.9,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"hold")
				_beat(out,2.0,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"hold")
		_:
			for m:Dictionary in room:
				if (ctx.rng as RandomNumberGenerator).randf()<0.4:_beat(out,0.8+_lag(ctx,m),String(m.key),"nod",{},"reaction")
			_play_bits(ctx,out,1.2)

## Our god's fury on a foreign envoy: their temper decides how they take it.
static func _terrify_envoy(ctx:Dictionary,out:Array)->void:
	var envoy:=String(ctx.main)
	var response:=String(ctx.event.get("response",""))
	_beat(out,0.0,"room","hush",{"dur":3.4},"anticipation")
	_shot(out,0.0,"push_in",{"target":envoy})
	_shot(out,0.55,"shake",{"strength":0.3})
	if response in ["defy","defiant"]:
		_beat(out,0.55,envoy,"stand_firm",{},"action")
		_beat(out,1.3,envoy,"hold_gaze",{},"action")
	else:
		_beat(out,0.55,envoy,"flinch",{},"action")
		_beat(out,0.9,envoy,"step_back",{},"action")
	# Their bored guard, suddenly very much awake.
	var snapped:=_bit_ready(ctx,"guard_snap") and _bit(ctx,"guard_snap",out,0.8)
	if snapped:_ran(ctx,"guard_snap")
	for att:Dictionary in _of_kind(ctx,["attendant","bearer","guard"]):
		if String(att.kind)=="guard" and snapped:continue
		_beat(out,0.8+_lag(ctx,att),String(att.key),"step_back",{},"reaction")
	if not _asleep(ctx).is_empty():_wake(ctx,out,0.8)
	# Our own: the proud enjoy it.
	for m:Dictionary in _of_kind(ctx,["official","hearth_chief"]):
		if float(m.pride)>0.65 and (ctx.rng as RandomNumberGenerator).randf()<0.6:_beat(out,1.4+_lag(ctx,m),String(m.key),"smirk",{"at":envoy},"reaction")
	_play_bits(ctx,out,0.8,2)
	_shot(out,3.0,"wide")

static func _insulted(ctx:Dictionary,out:Array)->void:
	var envoy:=String(ctx.main)
	if envoy!="":_beat(out,0.4,envoy,"stiffen",{},"action")
	if _bit_ready(ctx,"guard_snap") and _bit(ctx,"guard_snap",out,0.9):_ran(ctx,"guard_snap")
	var two:Array=_of_kind(ctx,["official","hearth_chief"])
	if two.size()>=2:
		_beat(out,1.0,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"reaction")
		_beat(out,1.1,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"reaction")
	_play_bits(ctx,out,0.8)

# =============================================================================
# The bits
# =============================================================================

## Who is asleep on their feet just now: the dozer, unless woken in the last
## few events.
static func _asleep(ctx:Dictionary)->String:
	if (ctx.bits as Array).has("doze_jerk"):return ""
	return asleep(ctx.cast,ctx.facts,ctx.memory)

## Can the room play this bit now (the people it needs are here, the facts
## allow it)?
static func _can(ctx:Dictionary,bit:String)->bool:
	var event:Dictionary=ctx.event
	var target:=String(event.get("target",""))
	match bit:
		"doze_jerk":return not _asleep(ctx).is_empty()
		"drop_bowl":return not _bowl_holder(ctx).is_empty()
		"late_lift":return not _of_kind(ctx,["child","commoner"],[String(ctx.main)]).is_empty()
		"goat_ignores":return not _of_kind(ctx,["goat"]).is_empty()
		"goat_nibble":return not _of_kind(ctx,["goat"]).is_empty() and not _of_kind(ctx,["official","hearth_chief","elder"]).is_empty()
		"child_hides":return not _of_kind(ctx,["child"]).is_empty() and String(event.get("action",event.get("verb","")))!="bless"
		"dog_whimper":return not _of_kind(ctx,["dog"]).is_empty()
		"faint":return String(event.get("action",""))=="terrify" and not _fainter(ctx).is_empty()
		"gasp_pretend":return _people(ctx,[target]).size()>=3 and (String(event.get("response",""))=="defy" or String(ctx.kind) in ["envoy_insulted","exit"] or String(event.get("verb","")) in ["kill","maim"])
		"side_eye_pair":return _of_kind(ctx,["official","hearth_chief"],[target,String(event.get("actor",""))]).size()>=2 and _odd(ctx)
		"stifle_elbow":return _people(ctx,[String(ctx.main)]).size()>=2 and _odd(ctx)
		"eager_bow":return not _eager(ctx).is_empty() and _favourable(ctx)
		"bored_guard":return not _of_kind(ctx,["guard"]).is_empty() and (String(ctx.kind)!="line" or String(event.get("text","")).length()>=90)
		"guard_snap":return not _of_kind(ctx,["guard"]).is_empty()
		"dog_sniff_gift":return not _of_kind(ctx,["dog"]).is_empty()
		"double_take","count_fingers":return not _amount(ctx).is_empty() and not _people(ctx,[String(event.get("who","")),String(ctx.main)]).is_empty()
		"child_copies":return not _of_kind(ctx,["child"]).is_empty() and not _bower(ctx).is_empty()
		"double_bow":return bool(event.get("accepted",String(event.get("reaction","")) in ["delighted","pleased"])) and not _m(ctx,String(event.get("who",ctx.main))).is_empty() and String(ctx.firm)!=String(event.get("who",ctx.main))
		"bow_early":
			var w:=_m(ctx,String(event.get("who",ctx.main)))
			return not w.is_empty() and (float(w.dread)>=0.4 or float(w.love)>=0.55)
		"cough_fit":return not sickness(ctx.facts).is_empty() and _people(ctx).size()>=2
		"smirk_rival":return not _rival(ctx).is_empty()
	return false

## Something odd was ordered: the engine could not carry it out ("none"),
## or the order went nowhere; or a petition was answered against custom.
static func _odd(ctx:Dictionary)->bool:
	var event:Dictionary=ctx.event
	match String(ctx.kind):
		"command":return String(event.get("stage",""))=="none" or (String(event.get("verb",""))=="order" and not bool(event.get("executed",true)))
		"decree":return bool(event.get("odd",false)) or String(event.get("reaction",""))=="furious"
		"god_speaks":return bool(event.get("odd",false))
		"line":return bool(event.get("odd",false))
		"divine":return String(event.get("action","")) in ["raise_up"]
	return false

static func _favourable(ctx:Dictionary)->bool:
	var event:Dictionary=ctx.event
	match String(ctx.kind):
		"divine":return String(event.get("action","")) in ["bless","boon","raise_up"]
		"decree":return bool(event.get("accepted",String(event.get("reaction","")) in ["delighted","pleased"]))
		"command":return String(event.get("obedience",""))=="obey" and not String(event.get("verb","")) in ["kill","maim","detain","exile"]
		"god_speaks":return String(event.get("tone",""))=="favor"
		"summon":return true
	return false

## The over-eager: a hearth chief (or anyone low in pride and high in love or
## dread) who is not the one being dealt with.
static func _eager(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	var skip:=[String(event.get("target","")),String(event.get("who","")),String(event.get("actor","")),String(ctx.firm)]
	var best:={};var score:=0.0
	for m:Dictionary in _people(ctx,skip):
		if String(m.kind) in ["envoy","guard","bearer","attendant","child"] or String(m.role)=="main":continue
		var s:=(0.4 if String(m.kind)=="hearth_chief" else 0.0)+maxf(float(m.love),float(m.dread))-float(m.pride)*0.6
		if s>score and s>=0.35:score=s;best=m
	return best

static func _bowl_holder(ctx:Dictionary)->Dictionary:
	for m:Dictionary in _people(ctx,[String(ctx.main),String(ctx.event.get("target","")),String(ctx.event.get("actor",""))]):
		if String(m.stance)=="bowl":return m
	for m:Dictionary in _of_kind(ctx,["commoner"],[String(ctx.main),String(ctx.event.get("target","")),String(ctx.event.get("actor",""))]):return m
	return {}

static func _fainter(ctx:Dictionary)->Dictionary:
	var target:=String(ctx.event.get("target",""))
	for m:Dictionary in _jumpiest(_people(ctx,[target,String(ctx.main)])):
		if float(m.dread)>=0.45 and float(m.courage)<=0.4 and not String(m.kind) in ["child","envoy","guard"]:
			if not _nearest(ctx,m,["official","hearth_chief","commoner","elder"],[target]).is_empty():return m
	return {}

## A number to do a double take at: said in a line, or the amount given.
static func _amount(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	var terms:Dictionary=event.get("terms",{}) if event.get("terms") is Dictionary else {}
	if _num(terms.get("amount",null)) and float(terms.amount)>=2.0:return {"value":roundi(float(terms.amount)),"at":1.2,"from":"event.amount"}
	if _num(event.get("amount",null)) and float(event.amount)>=2.0:return {"value":roundi(float(event.amount)),"at":1.8,"from":"event.amount"}
	if String(ctx.kind)=="line":
		var said:=number_in(String(event.get("text","")))
		if not said.is_empty():return {"value":int(said.value),"at":0.15+float(said.at)*0.025+0.25,"from":"event.text"}
	return {}

## Someone bowing in this moment, whom a child may copy.
static func _bower(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	if String(ctx.kind)=="decree" and bool(event.get("accepted",String(event.get("reaction","")) in ["delighted","pleased"])):return _m(ctx,String(event.get("who",ctx.main)))
	if String(ctx.kind) in ["dismiss","summon"]:return _m(ctx,String(event.get("who",ctx.main)))
	if String(ctx.kind)=="line":
		var who:=_m(ctx,String(event.get("who","")))
		if not who.is_empty() and String(who.kind) in ["official","hearth_chief"]:return who
	return {}

## A proud rival who does not love the god much: smirks at another's fall
## and side-eyes their rise.
static func _rival(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	var target:=String(event.get("target",event.get("who","")))
	if target.is_empty():return {}
	for m:Dictionary in _of_kind(ctx,["official","hearth_chief"],[target]):
		if float(m.pride)>=0.68 and float(m.love)<0.45:return m
	return {}

## Plays one bit. False if it could not be cast after all.
static func _bit(ctx:Dictionary,bit:String,out:Array,at:float)->bool:
	var rng:RandomNumberGenerator=ctx.rng
	var event:Dictionary=ctx.event
	var target:=String(event.get("target",""))
	# Nobody the god is dealing with plays a part in a bystander's bit.
	var busy:=[target,String(ctx.firm),String(ctx.gone),String(event.get("actor","")),String(ctx.get("fainted",""))]
	match bit:
		"doze_jerk":
			# Asleep through the hush; the voice wakes them, they look the
			# wrong way, then up, a full second behind everyone.
			var key:=_asleep(ctx)
			if key.is_empty():return false
			_beat(out,at,key,"jerk_awake",{},"reaction")
			_beat(out,at+0.45,key,"look_wrong_way",{},"reaction")
			_beat(out,at+1.2,key,"look_up",{},"reaction")
			var near:=_nearest(ctx,_m(ctx,key),["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty() and rng.randf()<0.5:_beat(out,at+0.3,String(near.key),"elbow",{"at":key},"reaction")
			ctx["woke"]=true;ctx["star"]=key
		"drop_bowl":
			var m:=_bowl_holder(ctx)
			_beat(out,at,String(m.key),"drop_bowl",{},"reaction")
			var near:=_nearest(ctx,m,["official","hearth_chief","commoner","elder","child"],busy)
			if not near.is_empty():_beat(out,at+0.5,String(near.key),"side_eye",{"at":String(m.key)},"reaction")
			_beat(out,at+1.0,String(m.key),"grimace",{},"hold")
			ctx["star"]=String(m.key)
		"late_lift":
			var m:=_pick(ctx,_of_kind(ctx,["child","commoner"],[String(ctx.main)]))
			# They miss it; someone nudges them; up they look, too late.
			var near:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty():_beat(out,at+0.5,String(near.key),"elbow",{"at":String(m.key)},"reaction")
			_beat(out,at+0.8,String(m.key),"late_lift",{},"reaction")
			ctx["star"]=String(m.key)
		"goat_ignores":
			var goat:Dictionary=_of_kind(ctx,["goat"])[0]
			_beat(out,at,String(goat.key),"chew",{"dur":2.4},"reaction")
			_beat(out,at+2.2,String(goat.key),"bleat",{},"button")
			var near:=_nearest(ctx,goat,["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty():_beat(out,at+2.6,String(near.key),"grimace",{},"button")
			ctx["star"]=String(goat.key)
		"goat_nibble":
			var goat:Dictionary=_of_kind(ctx,["goat"])[0]
			var victim:=_nearest(ctx,goat,["official","hearth_chief","elder"],busy)
			if victim.is_empty():return false
			_beat(out,at,String(goat.key),"nibble",{"at":String(victim.key)},"reaction")
			_beat(out,at+1.1,String(victim.key),"double_take",{"at":String(goat.key)},"reaction")
			_beat(out,at+1.6,String(victim.key),"shoo",{"at":String(goat.key)},"reaction")
			ctx["star"]=String(victim.key)
		"child_hides":
			var child:Dictionary=_pick(ctx,_of_kind(ctx,["child"]))
			var adult:=_nearest(ctx,child,["elder","commoner","official","hearth_chief"],busy)
			if adult.is_empty():return false
			_beat(out,at,String(child.key),"hide_behind",{"at":String(adult.key)},"reaction")
			_beat(out,at+2.0,String(child.key),"peek_out",{},"hold")
			ctx["star"]=String(child.key)
		"dog_whimper":
			var dog:Dictionary=_of_kind(ctx,["dog"])[0]
			var legs:=_nearest(ctx,dog,["elder","commoner","official","hearth_chief","child"],busy)
			_beat(out,at+0.2,String(dog.key),"whimper",{},"reaction")
			if not legs.is_empty():_beat(out,at+0.6,String(dog.key),"hide_under",{"at":String(legs.key)},"reaction")
		"faint":
			var m:=_fainter(ctx)
			var catcher:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			_beat(out,at+0.4,String(m.key),"faint",{},"reaction")
			_beat(out,at+0.55,String(catcher.key),"half_catch",{"at":String(m.key)},"reaction")
			_beat(out,at+1.6,String(catcher.key),"grimace",{},"hold")
			_shot(out,at+0.5,"reaction",{"target":String(m.key)})
			ctx["star"]=String(m.key);ctx["fainted"]=String(m.key)
		"gasp_pretend":
			_gasp(ctx,out,at,[target,String(ctx.firm)])
			return false   # _gasp records itself
		"side_eye_pair":
			var two:Array=_of_kind(ctx,["official","hearth_chief"],[target,String(event.get("actor",""))])
			var a:Dictionary=two[0];var b:Dictionary=two[1]
			_beat(out,at,String(a.key),"side_eye",{"at":String(b.key)},"reaction")
			_beat(out,at+0.35,String(b.key),"side_eye",{"at":String(a.key)},"reaction")
			_beat(out,at+1.2,String(a.key),"lips_pressed",{},"hold")
		"stifle_elbow":
			# Someone low in pride finds it funny; their neighbour does not.
			var room:Array=_people(ctx,busy+[String(ctx.main)])
			room.sort_custom(func(x:Dictionary,y:Dictionary)->bool:return float(x.pride)+float(x.dread)<float(y.pride)+float(y.dread) if not is_equal_approx(float(x.pride)+float(x.dread),float(y.pride)+float(y.dread)) else int(x.index)<int(y.index))
			if room.size()<2:return false
			var giggler:Dictionary=room[0]
			var neighbour:=_nearest(ctx,giggler,["official","hearth_chief","commoner","elder"],busy)
			if neighbour.is_empty():return false
			_beat(out,at,String(giggler.key),"stifle_laugh",{},"reaction")
			_beat(out,at+0.6,String(neighbour.key),"elbow",{"at":String(giggler.key)},"reaction")
			_beat(out,at+1.0,String(giggler.key),"straighten",{},"hold")
			ctx["star"]=String(giggler.key)
		"eager_bow":
			var m:=_eager(ctx)
			_beat(out,at,String(m.key),"bow_deep",{},"reaction")
			_beat(out,at+1.7,String(m.key),"wobble",{},"reaction")
			_beat(out,at+2.5,String(m.key),"recover",{},"hold")
			var near:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty():_beat(out,at+2.1,String(near.key),"side_eye",{"at":String(m.key)},"reaction")
			ctx["star"]=String(m.key);ctx["eager"]=String(m.key)
		"bored_guard":
			var guard:Dictionary=_of_kind(ctx,["guard"])[0]
			_beat(out,at+0.6,String(guard.key),"yawn",{},"reaction")
			ctx["star"]=String(guard.key)
		"guard_snap":
			var guard:Dictionary=_of_kind(ctx,["guard"])[0]
			_beat(out,maxf(at-0.2,0.6),String(guard.key),"snap_alert",{},"reaction")
			_shot(out,maxf(at-0.1,0.7),"reaction",{"target":String(guard.key)})
			ctx["star"]=String(guard.key)
		"dog_sniff_gift":
			var dog:Dictionary=_of_kind(ctx,["dog"])[0]
			var bearers:Array=_of_kind(ctx,["bearer","attendant"])
			var at_whom:=String((bearers[0] as Dictionary).key) if not bearers.is_empty() else String(ctx.main)
			_beat(out,at,String(dog.key),"sniff",{"at":at_whom},"reaction")
			if not bearers.is_empty():_beat(out,at+0.8,at_whom,"shoo",{"at":String(dog.key)},"reaction")
			ctx["star"]=String(dog.key)
		"double_take":
			var amount:=_amount(ctx)
			var listener:Array=_jumpiest(_people(ctx,[String(event.get("who","")),String(ctx.main),target]))
			if listener.is_empty():return false
			var m:Dictionary=listener[mini(rng.randi_range(0,1),listener.size()-1)]
			var said:=String(event.get("who",ctx.main))
			_beat(out,float(amount.at)+0.15,String(m.key),"look_at",{"at":said},"reaction")
			_beat(out,float(amount.at)+0.55,String(m.key),"double_take",{"at":said,"number":int(amount.value)},"reaction")
			ctx["star"]=String(m.key);ctx["number"]=int(amount.value);ctx["number_from"]=String(amount.get("from",""))
		"count_fingers":
			var amount:=_amount(ctx)
			var counters:Array=_people(ctx,[String(event.get("who","")),String(ctx.main),target]).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["envoy","guard","bearer","attendant"])
			if counters.is_empty():return false
			var m:Dictionary=_pick(ctx,counters)
			_beat(out,float(amount.at)+0.4,String(m.key),"count_fingers",{"number":int(amount.value)},"reaction")
			_beat(out,float(amount.at)+2.3,String(m.key),"grimace",{},"hold")
			ctx["star"]=String(m.key)
		"child_copies":
			var child:Dictionary=_pick(ctx,_of_kind(ctx,["child"]))
			var model:=_bower(ctx)
			var adult:=_nearest(ctx,child,["elder","commoner","official","hearth_chief"],busy+[String(model.key)])
			_beat(out,at+0.5,String(child.key),"copy",{"at":String(model.key)},"reaction")
			if not adult.is_empty():_beat(out,at+1.6,String(adult.key),"shush",{"at":String(child.key)},"reaction")
			ctx["star"]=String(child.key)
		"double_bow":
			var who:=String(event.get("who",ctx.main))
			_beat(out,1.1,who,"double_bow",{},"action")
		"bow_early":
			var who:=String(event.get("who",ctx.main))
			_beat(out,0.6,who,"bow_early",{},"action")
			_beat(out,2.3,who,"bow",{},"action")
			ctx["star"]=who
		"cough_fit":
			var room:Array=_people(ctx,busy+[String(ctx.main)])
			if room.is_empty():return false
			var cougher:Dictionary=_pick(ctx,room)
			_beat(out,at,String(cougher.key),"cough",{"because":"sickness"},"reaction")
			_beat(out,at+0.6,String(cougher.key),"cough",{"because":"sickness"},"reaction")
			var near:=_nearest(ctx,cougher,["official","hearth_chief","commoner","elder","child"],busy)
			if not near.is_empty():_beat(out,at+1.0,String(near.key),"edge_away",{"at":String(cougher.key),"because":"sickness"},"reaction")
			ctx["star"]=String(cougher.key);ctx["cougher"]=String(cougher.key)
		"smirk_rival":
			var r:=_rival(ctx)
			var whom:=String(event.get("target",event.get("who","")))
			var favour:=String(event.get("action","")) in ["bless","boon","raise_up"] or bool(event.get("accepted",false))
			_beat(out,at+0.4,String(r.key),"side_eye" if favour else "smirk",{"at":whom},"reaction")
			ctx["star"]=String(r.key)
		_:return false
	return true

# =============================================================================
# Agreement with the engine
# =============================================================================

## The last word: whatever the bits proposed, nothing on stage contradicts
## what the engine decided or what the facts hold.
static func _agree(out:Array,ctx:Dictionary)->Array:
	var kept:Array=[]
	var firm:=String(ctx.firm)
	var gone:=String(ctx.gone)
	var seized:=String(ctx.event.get("stage",""))=="refuse_seized"
	var grave:=String(ctx.gravity)=="grave"
	var food:=hungry(ctx.facts)
	var sick:=not sickness(ctx.facts).is_empty()
	var fighting:=not war(ctx.facts).is_empty()
	for beat:Dictionary in out:
		var who:=String(beat.who)
		var act:=String(beat.act)
		if not who in ["camera","room"] and not (ctx.by as Dictionary).has(who):continue
		# One who stood firm never goes down (bound and forced, they kneel
		# as the engine says, chin up: kneel_bound).
		if who==firm and not firm.is_empty() and act in KNEEL_LIKE:continue
		if who==firm and act=="kneel_bound" and not seized:continue
		# The dead and the cast out do nothing once it is done.
		if who==gone and not gone.is_empty() and act!="stricken":continue
		if grave and act in COMIC_ACTS:continue
		if not food and act in HUNGER_ACTS:continue
		if not sick and act in SICK_ACTS:continue
		if not fighting and act in WAR_ACTS:continue
		kept.append(beat)
	return kept

# =============================================================================
# Ambient: the room's own business, from the facts alone
# =============================================================================

## What the people in the hall do while nothing is happening: loops for the
## stage to play at random within `every` seconds ([] with hold: a standing
## state). Only what the facts hold: hunger when the stores are short, a
## cough while a sickness runs, spears while there is a war; the dread and
## love of the god in the faces; the cold in winter. If a fact is not in the
## sheet, nothing shows it.
static func ambient(cast:Array,facts:Dictionary,rng_seed:int)->Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|ambient" % rng_seed)
	var members:Array=[]
	var index:=0
	for entry in cast:
		if entry is Dictionary:members.append(member(entry,index));index+=1
	var people:Array=members.filter(func(m:Dictionary)->bool:return not bool(m.animal))
	var ours:Array=people.filter(func(m:Dictionary)->bool:return not String(m.kind) in ["envoy","guard","bearer","attendant"] and String(m.role)!="main")
	var out:Array=[]
	var busy:Dictionary={}
	# Hunger: the stores are short.
	if hungry(facts):
		var count:=mini(4 if starving(facts) else 2,ours.size())
		var pool:=_shuffled(rng,ours)
		var gift:Dictionary=facts.get("gift",{}) if facts.get("gift") is Dictionary else {}
		var food_here:=String(gift.get("resource","")).to_lower()=="food"
		for i in count:
			var m:Dictionary=pool[i]
			var act:String=["rub_belly","lick_lips"][rng.randi_range(0,1)] if not food_here else ["eye_food","rub_belly","lick_lips"][rng.randi_range(0,2)]
			var gap:=[7.0,13.0] if starving(facts) else [10.0,18.0]
			_loop(out,String(m.key),act,gap,{"at":"gift"} if act=="eye_food" else {},"food_days",rng)
			busy[String(m.key)]=true
	elif full(facts) and not ours.is_empty() and rng.randf()<0.5:
		_loop(out,String(_shuffled(rng,ours)[0].key),"pat_belly",[30.0,55.0],{},"food_days",rng)
	# Their envoy's people go hungry too: the envoy's company shows it.
	var envoy:Dictionary=facts.get("envoy",{}) if facts.get("envoy") is Dictionary else {}
	if _num(envoy.get("their_food_days",null)) and float(envoy.their_food_days)<12.0:
		for m:Dictionary in people.filter(func(x:Dictionary)->bool:return String(x.kind) in ["bearer","attendant"]):
			_loop(out,String(m.key),"rub_belly",[12.0,20.0],{},"envoy.their_food_days",rng)
	# Sickness: coughing, and someone keeping their distance.
	var sick:=sickness(facts)
	if not sick.is_empty():
		var coughers:=mini(2 if int(sick.get("deaths",0))>=5 else 1,ours.size())
		var pool:=_shuffled(rng,ours)
		for i in coughers:
			var m:Dictionary=pool[i]
			_loop(out,String(m.key),"cough",[5.0,11.0],{},"sickness",rng)
			busy[String(m.key)]=true
		if pool.size()>coughers:
			var wary:Dictionary=pool[coughers]
			_hold(out,String(wary.key),"keep_apart",{"at":String((pool[0] as Dictionary).key)},"sickness")
			busy[String(wary.key)]=true
	# War: spears worked sharp, someone posted at the door.
	var fight:=war(facts)
	if not fight.is_empty():
		var fighters:Array=ours.filter(func(m:Dictionary)->bool:return int(m.age)>=16 and int(m.age)<56 and not busy.has(String(m.key)))
		fighters.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.courage)>float(b.courage) if not is_equal_approx(float(a.courage),float(b.courage)) else int(a.index)<int(b.index))
		if not fighters.is_empty():
			_loop(out,String((fighters[0] as Dictionary).key),"sharpen_spear",[6.0,12.0],{},"war",rng)
			busy[String((fighters[0] as Dictionary).key)]=true
		if fighters.size()>=2:
			_hold(out,String((fighters[1] as Dictionary).key),"stand_guard",{},"war")
			_loop(out,String((fighters[1] as Dictionary).key),"glance_door",[8.0,15.0],{},"war",rng)
			busy[String((fighters[1] as Dictionary).key)]=true
	# The god's dread and love, in the faces.
	var room_dread:=people_dread(facts)
	var room_love:=people_love(facts)
	for m:Dictionary in ours:
		if busy.has(String(m.key)):continue
		var dread:=maxf(float(m.dread),room_dread*0.8)
		if dread>=0.6:
			_loop(out,String(m.key),"glance_up",[6.0,14.0],{},"dread",rng)
			if float(m.courage)<0.4:_loop(out,String(m.key),"tremble",[9.0,16.0],{},"dread",rng)
			busy[String(m.key)]=true
		elif float(m.love)>=LOVE_HIGH or room_love>=0.7:
			if rng.randf()<0.6:
				_hold(out,String(m.key),"smile_warm",{},"love")
				busy[String(m.key)]=true
	# The season, felt in the hall.
	var season:=String(facts.get("season","")).to_lower()
	if season=="winter":
		for m:Dictionary in _shuffled(rng,ours).slice(0,2):
			if not busy.has(String(m.key)):_loop(out,String(m.key),"rub_hands",[8.0,15.0],{},"season",rng)
	elif season=="summer":
		for m:Dictionary in _shuffled(rng,ours).slice(0,1):
			if not busy.has(String(m.key)):_loop(out,String(m.key),"fan_self",[10.0,18.0],{},"season",rng)
	# The sleeper.
	var sleeper:=dozer(cast,facts)
	if not sleeper.is_empty():_hold(out,sleeper,"doze",{},"calm")
	# Children are children; animals are animals.
	for m:Dictionary in members:
		match String(m.kind):
			"child":
				_loop(out,String(m.key),"fidget",[3.0,7.0],{},"life",rng)
				var grown:Array=people.filter(func(x:Dictionary)->bool:return String(x.kind) in ["elder","commoner","official","hearth_chief"])
				if not grown.is_empty():
					var near:={};var gap:=INF
					for o:Dictionary in grown:
						if absf(_where(o)-_where(m))<gap:gap=absf(_where(o)-_where(m));near=o
					_loop(out,String(m.key),"tug_sleeve",[10.0,20.0],{"at":String(near.key)},"life",rng)
			"dog":
				if room_dread>=DREAD_HIGH:_hold(out,String(m.key),"lie_down",{"ears":"back"},"dread")
				else:
					_loop(out,String(m.key),"scratch",[12.0,25.0],{},"life",rng)
					if _num(facts.get("food_days",null)) and String((facts.get("gift",{}) as Dictionary).get("resource","")).to_lower()=="food":
						_loop(out,String(m.key),"sniff",[6.0,10.0],{"at":"gift"},"gift",rng)
					else:_loop(out,String(m.key),"tail_wag",[8.0,16.0],{},"life",rng)
			"goat":
				_hold(out,String(m.key),"chew",{},"life")
				_loop(out,String(m.key),"bleat",[25.0,50.0],{},"life",rng)
			"guard":
				var theirs:=String(envoy.get("civ",""))
				if not fight.is_empty() and theirs!="" and theirs==String(fight.get("enemy","")):_hold(out,String(m.key),"stand_guard",{},"war")
				else:
					_hold(out,String(m.key),"bored",{},"life")
					_loop(out,String(m.key),"yawn",[14.0,30.0],{},"life",rng)
	# Everyone else breathes and shifts now and then (the acting layer blinks).
	for m:Dictionary in people:
		if busy.has(String(m.key)) or String(m.role)=="main" or String(m.kind) in ["child","guard"]:continue
		if rng.randf()<0.5:_loop(out,String(m.key),["shift_weight","scratch"][rng.randi_range(0,1)],[12.0,24.0],{},"life",rng)
	return out

static func _shuffled(rng:RandomNumberGenerator,list:Array)->Array:
	var out:=list.duplicate()
	for i in range(out.size()-1,0,-1):
		var j:=rng.randi_range(0,i)
		var swap:Variant=out[i];out[i]=out[j];out[j]=swap
	return out

static func _loop(out:Array,who:String,act:String,every:Array,args:Dictionary,because:String,rng:RandomNumberGenerator)->void:
	var spec:Dictionary=ACTS.get(act,{})
	out.append({"who":who,"act":act,"every":every,"start":snappedf(rng.randf()*float(every[0]),0.1),"dur":float(spec.get("dur",1.0)),"args":args,"because":because,"hold":false})

static func _hold(out:Array,who:String,act:String,args:Dictionary,because:String)->void:
	out.append({"who":who,"act":act,"every":[],"start":0.0,"dur":0.0,"args":args,"because":because,"hold":true})

# =============================================================================
# Asides: a muttered line now and then
# =============================================================================

## At most one muttered line for this event, from a bystander, built only from
## the facts and the event; about one event in four, never two running,
## never at a death. [{t, who, text, cites, situation}].
static func asides(event:Dictionary,facts:Dictionary,cast:Array,rng_seed:int,memory:Dictionary={})->Array:
	var ctx:=_context(event,cast,facts,rng_seed+31,memory)
	var n:=int(memory.get("aside_events",0))+1
	memory["aside_events"]=n
	if String(ctx.gravity)=="grave":return []
	var last:=int(memory.get("aside_n",-1000))
	if n-last<=ASIDE_GAP:return []
	var rng:RandomNumberGenerator=ctx.rng
	ctx["aside_n"]=n
	var options:=_aside_options(ctx)
	if options.is_empty():return []
	var weight:=0.0
	for o:Dictionary in options:weight+=float(o.weight)
	# A strong situation (the stores and the gift, a defiance) is likelier to
	# draw a mutter than ordinary talk.
	var chance:=ASIDE_CHANCE*clampf(weight/2.0,0.5,1.8)
	if rng.randf()>chance:return []
	var roll:=rng.randf()*weight
	var chosen:Dictionary=options[0]
	for o:Dictionary in options:
		roll-=float(o.weight)
		if roll<=0.0:chosen=o;break
	var said:=_say(ctx,chosen)
	if said.is_empty():return []
	memory["aside_n"]=n
	if not memory.get("aside_lines") is Dictionary:memory["aside_lines"]={}
	(memory.aside_lines as Dictionary)[String(said.template)]=n
	said.erase("template")
	return [said]

## A muttered line that answers a bit just played: the situation, who says
## it (the star themselves, someone near them, an official or anyone) and its
## weight. {name} is the star.
const GAG_ASIDES:={
	"doze_jerk":{"situation":"doze_wake","speak":"near","weight":2.2},
	"drop_bowl":{"situation":"drop_bowl","speak":"near","weight":1.8},
	"eager_bow":{"situation":"eager_bow","speak":"near","weight":2.4},
	"faint":{"situation":"faint","speak":"near","weight":2.4},
	"goat_nibble":{"situation":"goat_nibble","speak":"star","weight":2.6},
	"dog_sniff_gift":{"situation":"dog_gift","speak":"official","weight":1.6},
	"double_take":{"situation":"number","speak":"star","weight":2.0},
	"cough_fit":{"situation":"sick_cough","speak":"near","weight":1.8},
	"guard_snap":{"situation":"guard_awake","speak":"official","weight":1.6},
	"bored_guard":{"situation":"guard_bored","speak":"official","weight":1.2},
	"stifle_elbow":{"situation":"stifle","speak":"near","weight":1.8},
	"child_copies":{"situation":"child_copy","speak":"near","weight":1.8},
	"bow_early":{"situation":"bow_early","speak":"near","weight":1.8},
	"late_lift":{"situation":"late_lift","speak":"near","weight":1.4},
	"goat_ignores":{"situation":"goat","speak":"any","weight":1.4},
	"dog_whimper":{"situation":"dog_scared","speak":"any","weight":1.2},
	"child_hides":{"situation":"child_hides","speak":"near","weight":1.4},
	"gasp_pretend":{"situation":"gasp","speak":"star","weight":1.4},
	"late_prostrate":{"situation":"late_down","speak":"near","weight":1.6},
}

## The situations this event offers, each with who may say it and the slots.
static func _aside_options(ctx:Dictionary)->Array:
	var event:Dictionary=ctx.event
	var facts:Dictionary=ctx.facts
	var kind:=String(ctx.kind)
	var action:=String(event.get("action",""))
	var target:=String(event.get("target",event.get("who",ctx.main)))
	var t_m:=_m(ctx,target)
	var terms:Dictionary=event.get("terms",{}) if event.get("terms") is Dictionary else {}
	var out:Array=[]
	var name:=String(t_m.get("given",""))
	var base:={}
	if not name.is_empty():base["name"]=[name,"cast.%s.name" % target]
	if _num(facts.get("food_days",null)):base["food_days"]=[_count(int(facts.food_days)),"facts.food_days",int(facts.food_days)]
	var amount_v:=-1
	if _num(terms.get("amount",null)):amount_v=roundi(float(terms.amount))
	elif _num(event.get("amount",null)):amount_v=roundi(float(event.amount))
	if amount_v>=0:base["amount"]=[_count(amount_v),"event.amount",amount_v]
	var resource:=String(terms.get("resource",event.get("resource",""))).to_lower()
	if not resource.is_empty():base["resource"]=[resource,"event.resource"]
	var envoy:Dictionary=facts.get("envoy",{}) if facts.get("envoy") is Dictionary else {}
	if String(envoy.get("civ",""))!="":base["envoy_civ"]=[String(envoy.civ),"facts.envoy.civ"]
	if _num(envoy.get("days_waiting",null)) and int(envoy.days_waiting)>=3:base["days_waiting"]=[_count(int(envoy.days_waiting)),"facts.envoy.days_waiting",int(envoy.days_waiting)]
	var fight:=war(facts)
	if String(fight.get("enemy",""))!="":base["enemy"]=[String(fight.enemy),"facts.war.enemy"]
	var sick:=sickness(facts)
	if String(sick.get("name",""))!="":base["sickness"]=[String(sick.name),"facts.sickness.name"]
	if _num(sick.get("deaths",null)) and int(sick.deaths)>=1:base["deaths"]=[_count(int(sick.deaths)),"facts.sickness.deaths",int(sick.deaths)]
	var others:=[target,String(ctx.main),String(event.get("actor",""))]
	var food:=resource=="food"
	# The bits that just played on stage, answered under someone's breath.
	var last:Dictionary=ctx.memory.get("last",{}) if ctx.memory.get("last") is Dictionary else {}
	if int(last.get("n",-1))==int(ctx.n) and last.get("played") is Dictionary:
		for bit in (last.played as Dictionary):
			var gag:Dictionary=GAG_ASIDES.get(String(bit),{})
			if gag.is_empty():continue
			var star:=String((last.played[bit] as Dictionary).get("star",""))
			var end:=float((last.played[bit] as Dictionary).get("end",2.5))
			var o:={"situation":String(gag.situation),"weight":float(gag.weight),"from":"official" if String(gag.speak)=="official" else "any","exclude":others.duplicate(),"t":end+0.35}
			if String(gag.speak)=="star":o["speaker"]=star
			elif not star.is_empty():
				(o.exclude as Array).append(star)
				if String(gag.speak)=="near":o["near"]=star
			var extra:={}
			var star_m:=_m(ctx,star)
			if not star_m.is_empty() and not bool(star_m.animal):extra["name"]=[String(star_m.given),"cast.%s.name" % star]
			if String(bit)=="double_take" and int(last.get("number",-1))>=2:extra["number"]=[_count(int(last.number)),String(last.get("number_from","event.text")),int(last.number)]
			o["extra"]=extra
			out.append(o)
	match kind:
		"divine":
			match action:
				"boon":
					if food and hungry(facts):out.append({"situation":"boon_hungry","weight":2.4,"from":"hungry","exclude":others})
					else:out.append({"situation":"boon_plenty","weight":1.0,"from":"envy","exclude":others})
				"penance":
					if hungry(facts):out.append({"situation":"penance_hungry","weight":2.2,"from":"any","exclude":others})
					out.append(_situation_for_response(String(event.get("response","")),others))
				"terrify":out.append(_situation_for_response(String(event.get("response","")),others))
				"bless","raise_up":
					out.append({"situation":"bless_envy","weight":1.4,"from":"envy","exclude":others})
					out.append({"situation":"bless_glad","weight":0.5,"from":"glad","exclude":others})
		"gift":
			if bool(event.get("accepted",true)):
				if food and hungry(facts):out.append({"situation":"gift_food_hungry","weight":2.4,"from":"hungry","exclude":others})
			else:
				if food and hungry(facts):out.append({"situation":"gift_refused_hungry","weight":2.6,"from":"hungry","exclude":others})
				out.append({"situation":"gift_refused","weight":1.2,"from":"any","exclude":others})
			if base.has("days_waiting") and String(_m(ctx,String(ctx.main)).get("kind",""))=="envoy":out.append({"situation":"envoy_waited","weight":0.7,"from":"official","exclude":others})
			if base.has("enemy") and String(envoy.get("civ",""))==String(fight.get("enemy","")):out.append({"situation":"war_envoy","weight":1.6,"from":"official","exclude":others})
		"decree":
			var accepted:=bool(event.get("accepted",String(event.get("reaction","")) in ["delighted","pleased"]))
			out.append({"situation":"granted" if accepted else "refused","weight":0.8,"from":"any","exclude":others})
			if base.has("days_waiting") and String(_m(ctx,String(ctx.main)).get("kind",""))=="envoy":out.append({"situation":"envoy_waited","weight":0.6,"from":"official","exclude":others})
		"command":
			if String(event.get("stage",""))=="prostrate":out.append({"situation":"prostrate","weight":1.6,"from":"any","exclude":others})
			elif _odd(ctx):out.append({"situation":"absurd","weight":1.8,"from":"any","exclude":others})
		"exit":
			if String(event.get("style",""))=="storm":out.append({"situation":"storm_out","weight":1.4,"from":"any","exclude":others})
		"terrify_envoy":
			if not _of_kind(ctx,["guard"]).is_empty():out.append({"situation":"guard_awake","weight":1.2,"from":"official","exclude":others})
			out.append(_situation_for_response(String(event.get("response","")),others))
		"god_speaks":
			if people_dread(facts)>=DREAD_HIGH:out.append({"situation":"dread_room","weight":0.8,"from":"any","exclude":others,"cites":["facts.people_dread"]})
		"line":
			if base.has("enemy") and String(envoy.get("civ",""))!="" and String(envoy.get("civ",""))==String(fight.get("enemy","")):out.append({"situation":"war_envoy","weight":0.8,"from":"official","exclude":others})
	# What is true of the hall whatever is said: a cough, the cold, the war.
	if String(facts.get("season","")).to_lower()=="winter" and kind in ["line","promise","dismiss"]:out.append({"situation":"winter","weight":0.3,"from":"any","exclude":others})
	if base.has("enemy") and kind in ["line","decree","promise"] and String(envoy.get("civ",""))=="":out.append({"situation":"war_watch","weight":0.4,"from":"any","exclude":others})
	for o:Dictionary in out:o["slots"]=base.merged(o.get("extra",{}),true)
	return out

static func _situation_for_response(response:String,exclude:Array)->Dictionary:
	match response:
		"defy","defiant":return {"situation":"terrify_defy","weight":2.0,"from":"any","exclude":exclude}
		"cower":return {"situation":"terrify_cower","weight":1.6,"from":"any","exclude":exclude}
	return {"situation":"terrify_endure","weight":0.8,"from":"any","exclude":exclude}

## Says it: picks a bystander who fits, in their own manner, filling only
## from the slots; a line said lately is not said again.
static func _say(ctx:Dictionary,option:Dictionary)->Dictionary:
	var rng:RandomNumberGenerator=ctx.rng
	var exclude:Array=option.get("exclude",[])
	exclude=exclude+[String(ctx.main)]
	var from:=String(option.get("from","any"))
	# The engine's own reading of the witnesses, where it gave one.
	var witnesses:Dictionary=ctx.event.get("witnesses",{}) if ctx.event.get("witnesses") is Dictionary else {}
	var candidates:Array=[]
	var only:=String(option.get("speaker",""))
	for m:Dictionary in _people(ctx,exclude):
		if String(m.kind) in ["envoy","guard","bearer","attendant"]:continue
		if not only.is_empty() and String(m.key)!=only:continue
		var fits:=true
		var read:=String(witnesses.get(String(m.key),""))
		if from=="hungry":fits=not (String(m.kind) in ["official","hearth_chief"] and float(m.pride)>0.6)
		elif from=="envy":fits=read=="envy" if not read.is_empty() else float(m.pride)>=0.55
		elif from=="glad":fits=read=="glad" if not read.is_empty() else float(m.love)>=0.4
		elif from=="official":fits=String(m.kind) in ["official","hearth_chief"]
		if fits:candidates.append(m)
	if candidates.is_empty():return {}
	var now:=int(ctx.get("aside_n",0))
	var slots:Dictionary=option.get("slots",{})
	var flat:={}
	for key in slots:flat[key]=String((slots[key] as Array)[0])
	var recent:Dictionary=ctx.memory.get("aside_lines",{}) if ctx.memory.get("aside_lines") is Dictionary else {}
	var tags:Array=ctx.facts.get("era_tags",[]) if ctx.facts.get("era_tags") is Array else []
	var order:=_shuffled(rng,candidates)
	# Someone answering a bit is whoever stands nearest to it.
	var near:=_m(ctx,String(option.get("near","")))
	if not near.is_empty():
		order.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return absf(_where(a)-_where(near))<absf(_where(b)-_where(near)) if not is_equal_approx(absf(_where(a)-_where(near)),absf(_where(b)-_where(near))) else int(a.index)<int(b.index))
		order=order.slice(0,2)
	for m:Dictionary in order:
		var manner:=Asides.family(m)
		var lines:Array=_shuffled(rng,Asides.lines(String(option.situation),manner))
		for template in lines:
			var key:="%s|%s" % [option.situation,template]
			if now-int(recent.get(key,-1000))<40:continue
			var text:=Asides.render(String(template),flat)
			if text.is_empty() or not _era_ok(text,tags):continue
			var cites:Array=(option.get("cites",[]) as Array).duplicate()
			for slot in Asides.slots_in(String(template)):cites.append(String((slots[slot] as Array)[1]))
			var t:=clampf(float(option.t),1.2,4.6) if option.has("t") else 3.0+rng.randf()*0.5
			return {"t":snappedf(t,0.01),"who":String(m.key),"text":text,"cites":cites,"situation":String(option.situation),"template":key}
	return {}

static func _era_ok(text:String,tags:Array)->bool:
	return preload("res://scripts/character_voice.gd").permits(text,tags)

const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
static func _count(n:int)->String:
	return String(NUMBER_WORDS[n]) if n>=0 and n<NUMBER_WORDS.size() else str(n)

# =============================================================================
# From the engine's own results
# =============================================================================

## The key a person stands under on the stage: the one before the god is
## "main"; anyone else by person id.
static func key_of(cast:Array,person_id:int,speaker_id:=0)->String:
	if person_id<=0:return ""
	if person_id==speaker_id:return "main"
	for entry in cast:
		if entry is Dictionary and int(entry.get("person_id",0))==person_id:return String(entry.get("key",""))
	return ""

## Wrath or favour as audience_hall.divine() returned it (and divine_regard's
## apply_to_court effects inside it).
static func event_from_divine(result:Dictionary,cast:Array,speaker_id:=0)->Dictionary:
	var pid:=int(result.get("person_id",0))
	var target:=key_of(cast,pid,speaker_id) if pid>0 else "main"
	var witnesses:={}
	var effects:Dictionary=result.get("effects",{}) if result.get("effects") is Dictionary else {}
	var seen:Dictionary=effects.get("witnesses",{}) if effects.get("witnesses") is Dictionary else {}
	for wid in seen:
		var key:=key_of(cast,int(wid),speaker_id)
		if not key.is_empty():witnesses[key]=String((seen[wid] as Dictionary).get("response",""))
	var event:={"kind":"divine","action":String(result.get("action","")),"target":target if not target.is_empty() else "main",
		"response":String(result.get("response","")),"witnesses":witnesses,"terminal":bool(result.get("terminal",false))}
	if result.get("terms") is Dictionary:event["terms"]=(result.terms as Dictionary).duplicate()
	# The god's fury on a foreign envoy is its own moment.
	if pid==0 and String(result.get("action",""))=="terrify":event["kind"]="terrify_envoy";event["target"]="main"
	return event

## An order as court_commands.gd decided it.
static func event_from_command(result:Dictionary,cast:Array,speaker_id:=0)->Dictionary:
	var actor:Dictionary=result.get("actor",{}) if result.get("actor") is Dictionary else {}
	var target:Dictionary=result.get("target",{}) if result.get("target") is Dictionary else {}
	var ob:Dictionary=result.get("obedience",{}) if result.get("obedience") is Dictionary else {}
	var event:={"kind":"command","verb":String(result.get("verb","")),"stage":String(result.get("stage","")),
		"actor":_who(cast,actor,speaker_id),"target":_who(cast,target,speaker_id),
		"obedience":String(ob.get("id","obey")),"manner":String(ob.get("manner","")),
		"executed":bool(result.get("executed",false)),"removed":bool(result.get("removed",false))}
	if result.get("terms") is Dictionary:event["terms"]=(result.terms as Dictionary).duplicate()
	if String(result.get("response",""))!="":event["response"]=String(result.response)
	return event

static func _who(cast:Array,entry:Dictionary,speaker_id:int)->String:
	if entry.is_empty():return ""
	if bool(entry.get("speaker",false)) or String(entry.get("key",""))=="envoy":return "main"
	var pid:=int(entry.get("person_id",0))
	if pid>0:return key_of(cast,pid,speaker_id)
	var name:=String(entry.get("name",""))
	for c in cast:
		if c is Dictionary and String(c.get("name",""))==name and name!="":return String(c.get("key",""))
	return ""

## A line from the hall: the god's, someone's, or the engine's narration
## (which has no beats: what it tells comes as its own event).
static func event_from_line(line:Dictionary,who_key:String)->Dictionary:
	match String(line.get("role","")):
		"ruler":return {"kind":"god_speaks","text":String(line.get("text",""))}
		"narrator":return {"kind":"narration","text":String(line.get("text",""))}
	return {"kind":"line","who":who_key,"text":String(line.get("text","")),"aside":bool(line.get("aside",false))}

## An audience answered (audience_hall.resolve): a gift taken or turned away,
## a request granted or refused, a petition decided.
static func event_from_resolution(audience:Dictionary,option_id:String,result:Dictionary)->Dictionary:
	var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
	var reaction:=String(result.get("reaction","neutral"))
	if String(audience.get("kind",""))=="gift":
		return {"kind":"gift","accepted":option_id in ["accept","accept_return"],"resource":String(terms.get("resource","")),"amount":terms.get("amount",0),"who":"main","reaction":reaction}
	var accepted:=reaction in ["delighted","pleased"] or option_id in ["grant","grant_half","pay","reward","reward_scouts","thank","apologise"]
	var event:={"kind":"decree","accepted":accepted,"who":"main","reaction":reaction,"option":option_id}
	if not terms.is_empty() and option_id in ["grant","pay"]:event["terms"]=terms.duplicate()
	return event

## Someone leaves the stage in the engine's style (audience_modal.exit_style_for).
static func event_from_exit(who_key:String,style:String)->Dictionary:
	return {"kind":"exit","who":who_key,"style":style}

## The fact sheet the director reads, from the one ledger: the stores' days
## of food, a running sickness, a war, the season, the people's dread and
## love of the god, what the people know, and for a foreign audience the
## envoy's people and their gift. Reads only; changes nothing.
static func facts_now(audience:Dictionary={})->Dictionary:
	var facts:={}
	if Engine.get_main_loop()==null:return facts
	var hall:GDScript=load("res://scripts/audience_hall.gd")
	var cv:=preload("res://scripts/character_voice.gd")
	var c:Dictionary=hall.call("conditions")
	facts["food_days"]=maxi(0,roundi(float(c.get("food_days",30.0))))
	facts["population"]=roundi(float(c.get("population",0.0)))
	facts["health"]=float(c.get("health",1.0))
	facts["season"]=String((load("res://scripts/hearth_count.gd") as GDScript).call("season_name_for_day",int(GameState.elapsed_days)))
	var tags:Array=cv.era_tags("player")
	facts["era_tags"]=tags
	facts["era_tier"]=cv.era_tier(tags)
	var regard:Dictionary=hall.call("people_regard")
	facts["people_dread"]=float(regard.get("dread",0.0))
	facts["people_love"]=float(regard.get("love",0.0))
	var crises:GDScript=load("res://scripts/crisis_system.gd")
	for crisis:Dictionary in crises.call("active"):
		if String(crisis.get("type","")) in ["sickness","stranger"] and String(crisis.get("phase",""))!="over":
			facts["sickness"]={"name":String(crisis.get("name","")),"deaths":int(crisis.get("deaths",0))}
			break
	var enemies:Dictionary=(load("res://scripts/nation_borders.gd") as GDScript).call("hot_enemies")
	for civ_id in enemies:
		var civ:Dictionary=ForeignDiplomacy.civilization(String(civ_id))
		facts["war"]={"enemy":String(civ.get("name",civ_id)),"kind":String(enemies[civ_id]),"civ_id":String(civ_id)}
		break
	if String(audience.get("origin",""))=="foreign":
		var civ_id:=String(audience.get("civ_id",""))
		var their:Dictionary=ForeignDiplomacy.civilization(civ_id)
		facts["envoy"]={"civ":String(audience.get("civ_name","")),"civ_id":civ_id,"days_waiting":maxi(0,int(GameState.elapsed_days)-int(audience.get("arrived_day",GameState.elapsed_days))),
			"their_food_days":roundi(float(their.get("food_days",30.0)))}
		if String(audience.get("kind",""))=="gift" and audience.get("terms") is Dictionary:facts["gift"]=(audience.terms as Dictionary).duplicate()
	return facts

# =============================================================================
# The screenplay: the beats told in words (for review and the tests)
# =============================================================================

static func describe(beat:Dictionary,cast:Array)->String:
	var names:={}
	for entry in cast:
		if entry is Dictionary:
			var m:=member(entry)
			names[String(m.key)]=String(m.name) if String(m.kind)!="child" else "%s (a child)" % String(m.given)
	var spec:Dictionary=ACTS.get(String(beat.act),{})
	var text:=String(spec.get("desc",String(beat.act)))
	var args:Dictionary=beat.get("args",{})
	for slot in ["at","target","a","b"]:
		if args.has(slot):text=text.replace("{%s}" % slot,String(names.get(String(args[slot]),String(args[slot]))))
	if args.has("strength"):text=text.replace("{strength}",str(args.strength))
	if args.has("number"):text+=" (\"%d?\")" % int(args.number)
	var who:=String(beat.who)
	if who=="camera":return "[camera] "+text
	if who=="room":return "[room] "+text
	return ("%s%s" if text.begins_with("'") else "%s %s") % [String(names.get(who,who)),text]

static func screenplay(event:Dictionary,cast:Array,facts:Dictionary,rng_seed:int,memory:Dictionary={})->String:
	var lines:PackedStringArray=PackedStringArray()
	var list:=beats(event,cast,facts,rng_seed,memory)
	var said:=asides(event,facts,cast,rng_seed,memory)
	for beat:Dictionary in list:
		lines.append("  %5.2fs  %-11s %s" % [float(beat.t),String(beat.phase),describe(beat,cast)])
	var names:={}
	for entry in cast:
		if entry is Dictionary:names[String(entry.get("key",""))]=String(entry.get("name",""))
	for line:Dictionary in said:
		lines.append("  %5.2fs  %-11s %s, under their breath: \"%s\"" % [float(line.t),"aside",String(names.get(String(line.who),String(line.who))),String(line.text)])
	return "\n".join(lines)
