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
## laughs at a death or an exile, and a terrified hall is silent.
##
## The hall grows with the age (extras): a few people, a child and the dog
## at first; more people, a goat once herds are penned, a guard at the door
## and, where the people write, a scribe who gets every word down. The season
## shows (stamping feet in winter, a fly in summer). Officials are the
## engine's own officeholders: the director never invents one.
##
## Variety: each comic bit rests a while after it plays (memory, a small
## presentation-only dictionary the stage owns), so in a long campaign no bit
## is more than about one event in twelve, and the same kind of event never
## plays out identically twice in a row. Muttered lines rest three game years.
##
## Two ways in. The stage holds one director (CourtStage.director =
## CourtDirector.new(), docs/COURT_STAGE_3D.md section 5), which keeps its own
## memory and speaks the stage's primitive beats:
##   director.beats(event, cast, facts, seed)  -> [{t, who, act, args}]
##       act: play, look_at, mood, shot, hush (args.beat names the act below)
##   director.asides(event, facts, cast, seed) -> [{t, who, act:"aside", args:{text}, text, cites}]
##   director.ambient(cast, facts, seed)       -> [{who, act, every, dur, args, because, hold, primitives}]
## and the pure functions behind them, for tests and the screenplay:
##   beats_for(event, cast, facts, seed, memory) -> [{t, who, act, args, phase}]
##   asides_for(event, facts, cast, seed, memory)
## Both read the stage's own shapes too: a cast entry {key, role, person,
## figure, mood}, facts {stores_days, hungry, sick, at_war, love, dread,
## offer}, events "god", "enter", "divine" {action, response}, and an
## engine result passed whole as event.result.
##
## who is a cast key, "camera" (a shot: wide, push_in, reaction, two_shot,
## shake) or "room" (hush: everyone's idle business pauses). act names are
## the acting vocabulary in ACTS: each says the face it wears, how long it
## lasts and, until the acting layer (court_acting.gd) has a clip of that
## name, the nearest clip and mood the figures already have.
##
## The adapters (event_from_divine, event_from_command, event_from_line,
## event_from_resolution, event_from_exit, event_wait) read the engine's own
## result dictionaries; cast_member(), extras() and facts_now() build the
## cast and the fact sheet. Static helpers; preload.

const Asides:=preload("res://scripts/hud/court_asides.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")

## Muttered lines may be turned off (a setting; CourtStage.mutters_enabled
## forwards here). The fact sheet's "mutters": false does the same.
static var mutters_enabled:=true

## The stores' days of food below which people are hungry on stage (the
## hall's own words: under 16 days "food is short"); under 7 they starve.
const HUNGRY_DAYS:=16
const STARVING_DAYS:=7
const FULL_DAYS:=35
const DREAD_HIGH:=0.55
const LOVE_HIGH:=0.62

## Getting down before the god: never done by one who stood firm.
const KNEEL_LIKE:=["kneel","prostrate","bow","bow_deep","bow_small","bow_early","double_bow","bow_curt","bow_wrong","bow_to_post","over_thank","back_out_bowing",
	"head_down","plead","cower","wobble","flinch","knees_knock","tremble","faint","mortified","deflate_polite","nod_too_much"]
const HUNGER_ACTS:=["eye_food","rub_belly","lick_lips","stomach_growl"]
const SICK_ACTS:=["cough","cover_mouth","keep_apart","stifle_cough"]
const WAR_ACTS:=["sharpen_spear","glance_door"]
const WINTER_ACTS:=["stamp_feet","breath","rub_hands"]
const SUMMER_ACTS:=["swat_fly","swat_miss","fan_self"]
## Light business, never played at a death or an exile.
const COMIC_ACTS:=["stifle_laugh","elbow","wobble","drop_bowl","jerk_awake","look_wrong_way","double_take","yawn","faint","half_catch",
	"nibble","copy","shush","bow_early","double_bow","late_lift","snap_alert","sniff","shoo","count_fingers","bleat","grimace","smirk","beam",
	"over_thank","bump_post","bow_to_post","come_back","come_back_for","snatch_up","snore","enter_wrong","wave","gape","bow_wrong","point_up","stomach_growl","floor_creak",
	"swallow_loud","swat_fly","swat_miss","stamp_feet","shake_hand","gawk","startle","sniff_disdain","stare_down","blink_first","nod_too_much","sit_down"]

## The acting vocabulary. clip/mood: the nearest the modelled figures already
## have (court_figure_3d.gd CLIPS and MOODS), used until the acting layer
## gives the act its own clip; face: shape-key weights; dur: seconds; hold:
## stays until something else is asked; look: "god", "god_up", "at" (args.at),
## "away" or ""; desc: how the screenplay tells it.
const ACTS:={
	# executions (the acting's clips by these names when it has them)
	"windup":{"clip":"raise_hand","mood":"defiant","face":{"brows_down":0.6,"lips_pressed":0.7},"dur":0.9,"hold":true,"look":"at","desc":"winds up a great blow"},
	"swing":{"clip":"point","mood":"defiant","face":{"jaw_open":0.5,"brows_down":0.6},"dur":0.5,"look":"","desc":"swings"},
	"squint":{"clip":"","mood":"","face":{"eyes_narrow":0.8,"lips_pressed":0.6},"dur":0.5,"look":"at","desc":"takes aim with one eye"},
	"tug":{"clip":"point","mood":"","face":{"lips_pressed":0.8,"eyes_narrow":0.5},"dur":0.9,"look":"","desc":"tugs at the stuck blade"},
	"stir":{"clip":"point","mood":"","face":{"eyes_narrow":0.3},"dur":1.0,"look":"","desc":"stirs the pot"},
	"taste":{"clip":"raise_hand","mood":"","face":{"lips_pressed":0.4,"brows_up":0.3},"dur":0.9,"look":"","desc":"tastes, considers, adds salt"},
	"wipe_face":{"clip":"raise_hand","mood":"","face":{"eyes_narrow":0.7,"lips_pressed":0.6},"dur":1.4,"look":"","desc":"wipes the spatter from their face"},
	"retch":{"clip":"bow","mood":"afraid","face":{"jaw_open":0.4,"eyes_narrow":0.6},"dur":1.3,"look":"","desc":"is sick into the nearest pot"},
	"hide_eyes":{"clip":"raise_hand","mood":"afraid","face":{"eyes_narrow":0.9},"dur":1.6,"look":"","desc":"hides their eyes"},
	"vomit":{"clip":"bow","mood":"afraid","face":{"jaw_open":0.4,"eyes_narrow":0.6},"dur":3.6,"look":"","desc":"is sick into the nearest pot"},
	"applaud_alone":{"clip":"raise_hand","mood":"warm","face":{"smile":0.7},"dur":3.6,"look":"god","desc":"applauds, alone, and keeps on a beat too long"},
	"cover_eyes_peek":{"clip":"raise_hand","mood":"afraid","face":{"eyes_narrow":0.8},"dur":3.2,"look":"","desc":"covers their eyes, then peeks through their fingers"},
	"flinch_splash":{"clip":"","mood":"afraid","face":{"eyes_wide":0.8},"dur":2.6,"look":"","desc":"flinches from the splash"},
	"wince_crunch":{"clip":"","mood":"","face":{"lips_pressed":0.8,"eyes_narrow":0.7},"dur":2.6,"look":"","desc":"winces at each crunch"},
	"throw":{"clip":"point","mood":"defiant","face":{"brows_down":0.4},"dur":0.5,"look":"at","desc":"throws"},
	"warm_hands":{"clip":"bow","mood":"warm","face":{"smile":0.3},"dur":1.6,"look":"","desc":"warms their hands at the embers"},
	"cough_smoke":{"clip":"","mood":"","face":{"jaw_open":0.5,"eyes_narrow":0.6},"dur":1.0,"look":"","desc":"coughs a ring of smoke"},
	"stroke_chin":{"clip":"","mood":"","face":{"eyes_narrow":0.4},"dur":1.6,"look":"","desc":"watches, stroking their chin"},
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
	"bubble":{"dur":0.0,"desc":"'s words come in a {style} bubble"},
	"shrug":{"clip":"","mood":"","face":{"brows_up":0.6,"lips_pressed":0.4},"dur":1.0,"look":"","desc":"shrugs, very slightly"},
	"raise_finger":{"clip":"raise_hand","mood":"","face":{"brows_up":0.5,"jaw_open":0.2},"dur":0.9,"speed":1.4,"look":"god","desc":"lifts a finger to correct someone"},
	"lower_finger":{"clip":"","mood":"neutral","face":{"lips_pressed":0.6},"dur":0.8,"look":"","desc":"thinks better of it and lowers the finger"},
	"nod_along":{"clip":"","mood":"defiant","face":{"brows_down":0.4,"lips_pressed":0.5},"dur":1.6,"look":"god","desc":"nods along gravely, as if they had said it themselves"},
	"soft_clap":{"clip":"","mood":"warm","face":{"smile":0.6},"dur":0.9,"look":"god","desc":"claps, softly, once or twice, then stops when nobody joins in"},
	"edge_forward":{"clip":"","mood":"","face":{"lips_pressed":0.3},"dur":1.0,"look":"god","desc":"edges a step nearer the front"},
	"check_room":{"clip":"","mood":"","face":{"brows_up":0.4},"dur":1.0,"look":"away","desc":"glances round to see what everyone else thinks"},
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
	# Favour, promises, waiting.
	"over_thank":{"clip":"bow","mood":"warm","face":{"smile":0.8,"brows_up":0.3},"dur":3.6,"speed":1.6,"look":"god","desc":"thanks the god over and over, bowing each time"},
	"deflate_polite":{"clip":"","mood":"neutral","face":{"smile":0.3,"brows_worried":0.5},"dur":2.0,"look":"","desc":"keeps smiling while their shoulders sink"},
	"nod_too_much":{"clip":"","mood":"warm","face":{"smile":0.3},"dur":1.6,"speed":1.8,"look":"god","desc":"nods, and keeps on nodding"},
	"clear_throat":{"clip":"","mood":"","face":{"jaw_open":0.2},"dur":0.8,"look":"","desc":"clears their throat"},
	"smooth_clothes":{"clip":"","mood":"","face":{},"dur":1.2,"look":"","desc":"smooths their clothes"},
	"catch_eye":{"clip":"","mood":"","face":{"brows_up":0.5,"smile":0.2},"dur":1.2,"look":"god","desc":"tries to catch the god's eye"},
	"sit_down":{"clip":"","mood":"","face":{},"dur":3.0,"hold":true,"look":"","desc":"sits down on the floor"},
	"doze_off":{"clip":"","mood":"neutral","face":{"blink":1.0},"dur":3.0,"hold":true,"look":"","desc":"nods off again"},
	"glum":{"clip":"","mood":"grieved","face":{"lips_pressed":0.4},"dur":1.6,"look":"","desc":"looks glum"},
	# Arrivals.
	"enter_wrong":{"clip":"","mood":"afraid","face":{"eyes_wide":0.5},"dur":1.6,"look":"away","desc":"comes in by the wrong side and stops, lost"},
	"hurry_round":{"clip":"","mood":"afraid","face":{},"dur":1.2,"look":"","desc":"hurries round to the right place"},
	"gape":{"clip":"","mood":"","face":{"jaw_open":0.6,"eyes_wide":0.6},"dur":1.8,"look":"god_up","desc":"stares up, mouth open"},
	"wave":{"clip":"raise_hand","mood":"warm","face":{"smile":0.7},"dur":1.2,"look":"god_up","desc":"waves at the god"},
	"nudge":{"clip":"","mood":"","face":{"eyes_narrow":0.3},"dur":0.7,"look":"at","desc":"nudges {at}"},
	"gawk":{"clip":"","mood":"","face":{"eyes_wide":0.4,"jaw_open":0.2},"dur":1.8,"look":"away","desc":"gawks at the roof"},
	"wipe_hands":{"clip":"","mood":"","face":{},"dur":1.0,"look":"","desc":"wipes their hands on their clothes"},
	"bow_wrong":{"clip":"bow","mood":"warm","face":{},"dur":2.2,"look":"at","desc":"bows deeply to {at} instead of the god"},
	"point_up":{"clip":"point","mood":"","face":{"brows_up":0.6},"dur":1.2,"look":"god_up","desc":"points them up, at the god"},
	"mortified":{"clip":"","mood":"afraid","face":{"eyes_wide":0.7},"dur":1.0,"look":"","desc":"realises, mortified"},
	"nod_proud":{"clip":"","mood":"warm","face":{"smile":0.4},"dur":1.4,"look":"at","desc":"nods at {at}, proud"},
	# A gifted child shows their gift without meaning to.
	"count_heads":{"clip":"","mood":"","face":{"lips_pressed":0.2},"dur":2.0,"look":"away","desc":"counts everyone in the hall under their breath"},
	"study_posts":{"clip":"","mood":"","face":{"eyes_narrow":0.3},"dur":2.0,"look":"away","desc":"studies how the roof posts are lashed"},
	"turn_stone":{"clip":"","mood":"","face":{"eyes_narrow":0.3},"dur":2.0,"look":"","desc":"turns a pebble from the floor over in their fingers"},
	"study_roof":{"clip":"","mood":"","face":{"eyes_narrow":0.3},"dur":2.0,"look":"away","desc":"measures the hall with a thumb held out"},
	"work_knot":{"clip":"","mood":"","face":{"lips_pressed":0.3},"dur":2.0,"look":"","desc":"works a knot in a cord, fast"},
	"eye_stores":{"clip":"","mood":"","face":{"eyes_narrow":0.3},"dur":2.0,"look":"away","desc":"looks hard at the food baskets"},
	"watch_guards":{"clip":"","mood":"","face":{"eyes_narrow":0.3},"dur":2.0,"look":"away","desc":"watches how the guards stand"},
	"watch_god":{"clip":"","mood":"","face":{"brows_up":0.3},"dur":2.0,"look":"god_up","desc":"watches the god, unafraid"},
	"line_up":{"clip":"","mood":"","face":{"lips_pressed":0.3},"dur":2.0,"look":"","desc":"lines up the bowls on the floor by size"},
	"tend_hurt":{"clip":"","mood":"","face":{},"dur":2.0,"look":"away","desc":"looks at the old one's bad leg, frowning"},
	# Exits.
	"back_out_bowing":{"clip":"bow","mood":"warm","face":{"smile":0.4},"dur":2.4,"look":"god","desc":"backs away, bowing"},
	"bump_post":{"clip":"","mood":"afraid","face":{"eyes_wide":0.8},"dur":0.6,"look":"","desc":"backs into the door post"},
	"bow_to_post":{"clip":"bow","mood":"","face":{},"dur":1.2,"speed":1.5,"look":"","desc":"bows to the post, by mistake"},
	"storm_off":{"clip":"","mood":"defiant","face":{"brows_down":0.6},"dur":1.6,"look":"","desc":"storms off"},
	"stop_short":{"clip":"","mood":"","face":{"eyes_wide":0.4},"dur":0.6,"look":"","desc":"stops short at the door"},
	"come_back":{"clip":"","mood":"defiant","face":{"lips_pressed":0.8},"dur":1.6,"look":"","desc":"stalks back in for their {thing}"},
	"come_back_for":{"clip":"","mood":"defiant","face":{"lips_pressed":0.8},"dur":1.6,"look":"at","desc":"stalks back in: {at} is still standing there with the bundle"},
	"hurry_after":{"clip":"","mood":"afraid","face":{},"dur":0.8,"look":"at","desc":"hurries after {at}"},
	"snore":{"clip":"","mood":"neutral","face":{"blink":1.0,"jaw_open":0.3},"dur":2.0,"look":"","desc":"snores, softly, into the silence"},
	"snatch_up":{"clip":"","mood":"defiant","face":{"lips_pressed":0.8},"dur":0.8,"look":"","desc":"snatches up their {thing}"},
	"jerk_head":{"clip":"","mood":"defiant","face":{"brows_down":0.5},"dur":0.8,"look":"at","desc":"jerks their head at {at}: come on"},
	# Envoys and their company.
	"sniff_disdain":{"clip":"","mood":"defiant","face":{"sneer":0.5},"dur":1.6,"look":"away","desc":"looks the hall over and sniffs"},
	"brush_sleeve":{"clip":"","mood":"","face":{"sneer":0.3},"dur":1.0,"look":"","desc":"brushes something off their sleeve"},
	"bow_curt":{"clip":"bow","mood":"","face":{"lips_pressed":0.3},"dur":1.0,"speed":2.2,"look":"","desc":"gives the smallest possible bow"},
	"startle":{"clip":"","mood":"afraid","face":{"eyes_wide":0.8},"dur":0.7,"look":"at","desc":"startles at {at}"},
	"appraise":{"clip":"","mood":"","face":{"eyes_narrow":0.4},"dur":2.0,"look":"away","desc":"looks over the hall's goods, pricing them"},
	"rub_hands_greedy":{"clip":"","mood":"warm","face":{"smile":0.5},"dur":1.2,"look":"","desc":"rubs their hands together"},
	"whisper":{"clip":"","mood":"","face":{"jaw_open":0.1},"dur":1.2,"look":"at","desc":"whispers to {at}"},
	"stare_down":{"clip":"","mood":"defiant","face":{"eyes_narrow":0.6},"dur":2.4,"look":"at","desc":"stares at {at}"},
	"blink_first":{"clip":"","mood":"","face":{"blink":1.0},"dur":0.8,"look":"away","desc":"blinks first, and looks away"},
	# The season and the scribe.
	"stamp_feet":{"clip":"","mood":"","face":{"lips_pressed":0.3},"dur":1.2,"look":"","desc":"stamps their feet against the cold"},
	"breath":{"clip":"","mood":"","face":{},"dur":1.0,"look":"","desc":"breathes out a puff of white"},
	"swat_fly":{"clip":"","mood":"","face":{"eyes_narrow":0.5},"dur":0.8,"look":"","desc":"swats at a fly"},
	"swat_miss":{"clip":"","mood":"","face":{"eyes_wide":0.5},"dur":0.8,"look":"at","desc":"swats at the fly and catches {at} instead"},
	"scribble":{"clip":"","mood":"","face":{"eyes_narrow":0.4},"dur":2.0,"look":"","desc":"scribbles furiously"},
	"review_brief":{"clip":"stroke_chin","mood":"","face":{"eyes_narrow":0.2},"dur":2.4,"speed":0.7,"look":"","desc":"considers the briefing"},
	"shake_hand":{"clip":"","mood":"","face":{"lips_pressed":0.5},"dur":1.0,"look":"","desc":"shakes out a cramped hand"},
	"scratch_out":{"clip":"","mood":"","face":{"brows_down":0.4},"dur":1.0,"look":"","desc":"scratches something out"},
	# Silence.
	"stomach_growl":{"clip":"","mood":"afraid","face":{"eyes_wide":0.6},"dur":0.9,"look":"","desc":"'s stomach growls into the silence"},
	"floor_creak":{"clip":"","mood":"afraid","face":{"eyes_wide":0.7},"dur":0.9,"look":"","desc":"shifts, and the floor creaks, loud"},
	"swallow_loud":{"clip":"","mood":"afraid","face":{"lips_pressed":0.5},"dur":0.7,"look":"","desc":"swallows, loudly"},
	"stifle_cough":{"clip":"","mood":"afraid","face":{"cheeks_puff":0.6},"dur":1.0,"look":"","desc":"fights down a cough"},
	# The camera and the room.
	"wide":{"dur":1.0,"desc":"WIDE on the hall"},
	"push_in":{"dur":1.2,"desc":"PUSH IN on {target}"},
	"reaction":{"dur":1.0,"desc":"CUT to {target}"},
	"two_shot":{"dur":1.2,"desc":"TWO SHOT, {a} and {b}"},
	"shake":{"dur":0.4,"desc":"the frame shakes ({strength})"},
	"hush":{"dur":2.0,"desc":"the room goes still"},
}


## What is heard (court sound, codex/court-sound): beats carry
## sound {name, gain, pace?, glyph?, people, who}. Names agreed with the
## sound builder; a name the sound side lacks plays nothing. glyph: the tiny
## wordless bubble a noise gets on the stage (bubble spec, hook notes).
const SOUNDS:={
	"snore":["snore",0.7,"zzz"],"stomach_growl":["growl",0.8,"growl"],"stifle_cough":["cough_fought",0.7,"cough"],"cough":["cough",0.8,"cough"],
	"floor_creak":["creak",0.9,"creak"],"swallow_loud":["swallow",0.8,"gulp"],"gulp":["swallow",0.4,""],"gasp":["gasp",0.6,""],
	"stifle_laugh":["snort_laugh",0.6,"snort"],"drop_bowl":["bowl_clatter",1.0,"clatter"],"set_down_bundle":["bundle_thud_grunt",0.9,""],
	"lift_bundle":["grunt",0.7,""],"struggle_bundle":["grunt",0.5,""],"faint":["faint_thump",0.9,"thump"],"whimper":["dog_whimper",0.7,"whimper"],
	"bleat":["goat_bleat",1.0,"bleat"],"chew":["goat_chew",0.3,""],"lie_down":["dog_flop",0.4,""],"sniff":["dog_sniff",0.4,""],
	"enter_wrong":["footsteps",0.6,""],"hurry_round":["footsteps",0.7,""],"storm_off":["footsteps",0.9,""],"back_out_bowing":["footsteps",0.5,""],
	"come_back":["footsteps",0.9,""],"come_back_for":["footsteps",0.9,""],"hurry_after":["footsteps",0.7,""],"bolt":["footsteps",1.0,""],
	"hurry":["footsteps",0.5,""],"edge_forward":["footsteps",0.3,""],"make_room":["footsteps",0.3,""],"step_back":["footsteps",0.4,""],
	"bump_post":["thud_wood",0.9,"thump"],"stamp_feet":["stamp",0.7,""],"breath":["breath_out",0.3,""],"swat_fly":["slap_air",0.4,""],
	"swat_miss":["slap",0.8,"slap"],"yawn":["yawn",0.7,"yawn"],"knees_knock":["knees_knock",0.6,""],"kneel":["kneel_cloth",0.6,""],
	"kneel_bound":["kneel_cloth",0.8,""],"prostrate":["body_floor",0.7,""],"elbow":["oof",0.5,""],"shush":["shh",0.6,""],
	"clear_throat":["throat_clear",0.7,""],"sniff_disdain":["sniff",0.6,""],"jerk_awake":["snort_wake",0.7,"snort"],
	"scribble":["reed_scratch",0.5,""],"swing":["whoosh",0.9,""],"throw":["whoosh",0.6,""],"retch":["retch",0.7,""],
	"wipe_face":["wipe",0.4,""],"cough_smoke":["cough",0.8,"cough"],"stir":["stir",0.5,""],"taste":["slurp",0.6,""],"scratch_out":["reed_scratch",0.6,""],"count_fingers":["babble_count",0.4,""],
	"whisper":["whisper_babble",0.4,""],"over_thank":["babble_thanks",0.7,""],"soft_clap":["soft_clap",0.6,"clap"],
	"raise_finger":["babble_ahem",0.5,""],"startle":["yelp_small",0.7,"gasp"],"snatch_up":["snatch",0.6,""],"wave":["",0.0,""],
	"shoo":["shoo",0.6,""],"nibble":["goat_nibble",0.4,""],"tail_wag":["",0.0,""],"bow_to_post":["",0.0,""],"scratch":["",0.0,""],
}
## The god's moments: the room's murmur is cut sharply and comes back after.
const HUSH_SOUND:="murmur_cut"

## Comic bits: the event kinds each may be drawn for (empty: played only by
## its own moment), its weight, and how many events it rests after it plays.
## A rest of 12 or more keeps a bit under about one event in twelve over a
## long campaign; a bit tied to a rarer moment rests less.
const BITS:={
	"doze_jerk":{"kinds":[],"weight":3.0,"rest":12},
	"drop_bowl":{"kinds":["god_speaks","divine","terrify_envoy"],"weight":1.6,"rest":16,"wrath":true},
	"late_lift":{"kinds":["god_speaks"],"weight":2.0,"rest":14},
	"goat_ignores":{"kinds":["god_speaks","divine"],"weight":2.2,"rest":14},
	"goat_nibble":{"kinds":["line","god_speaks","promise","dismiss","wait"],"weight":1.4,"rest":16},
	"child_hides":{"kinds":["divine","terrify_envoy","command"],"weight":3.0,"rest":12,"wrath":true},
	"dog_whimper":{"kinds":["divine","terrify_envoy","command"],"weight":2.4,"rest":12,"wrath":true},
	"faint":{"kinds":["divine"],"weight":2.0,"rest":20,"wrath":true},
	"gasp_pretend":{"kinds":[],"weight":2.6,"rest":12},
	"side_eye_pair":{"kinds":["command","decree","divine","line"],"weight":2.2,"rest":12},
	"stifle_elbow":{"kinds":["command","god_speaks","decree"],"weight":2.4,"rest":14},
	"eager_bow":{"kinds":["divine","decree","command","god_speaks","summon"],"weight":2.4,"rest":14},
	"bored_guard":{"kinds":["line","gift","decree","dismiss","promise","wait"],"weight":2.0,"rest":12},
	"guard_snap":{"kinds":[],"weight":4.0,"rest":6},
	"dog_sniff_gift":{"kinds":["gift"],"weight":3.0,"rest":8},
	"double_take":{"kinds":["line","divine","gift","decree"],"weight":2.6,"rest":12},
	"count_fingers":{"kinds":["line","gift","decree"],"weight":1.8,"rest":14},
	"child_copies":{"kinds":["decree","line","dismiss","summon"],"weight":1.4,"rest":18},
	"double_bow":{"kinds":[],"weight":2.0,"rest":12},
	"over_thank":{"kinds":[],"weight":2.0,"rest":12},
	"bow_early":{"kinds":[],"weight":2.6,"rest":12},
	"cough_fit":{"kinds":["line","god_speaks","decree","promise","dismiss","summon","gift","wait"],"weight":2.2,"rest":12},
	"smirk_rival":{"kinds":["decree","divine"],"weight":1.6,"rest":14},
	"dead_silence":{"kinds":[],"weight":2.0,"rest":4},
	"winter_stamp":{"kinds":["line","god_speaks","wait","promise","decree","summon"],"weight":2.0,"rest":14},
	"fly_elder":{"kinds":["line","wait","promise","decree","god_speaks"],"weight":2.0,"rest":14},
	"scribe_cramp":{"kinds":["god_speaks","line","decree"],"weight":2.0,"rest":14},
	"bump_post":{"kinds":[],"weight":2.0,"rest":12},
	"forgot_thing":{"kinds":[],"weight":2.0,"rest":10},
	"wrong_door":{"kinds":[],"weight":2.0,"rest":12},
	"bow_wrong":{"kinds":[],"weight":2.0,"rest":8},
	"child_wave":{"kinds":[],"weight":2.0,"rest":8},
	"stare_down":{"kinds":["line"],"weight":1.6,"rest":12},
	"company_gawk":{"kinds":["line"],"weight":1.6,"rest":12},
	"gifted":{"kinds":[],"weight":1.0,"rest":0},
	"envoy_sniff":{"kinds":[],"weight":1.0,"rest":0},
	"envoy_startle":{"kinds":[],"weight":1.0,"rest":0},
	"envoy_appraise":{"kinds":[],"weight":1.0,"rest":0},
	"late_prostrate":{"kinds":[],"weight":1.0,"rest":0},
	# The officials' own ways (quirk_of), each tied to the one who has it.
	"quirk_count":{"kinds":["line","decree","gift","divine"],"weight":3.0,"rest":8},
	"quirk_flatter":{"kinds":["god_speaks","decree","command","divine"],"weight":2.6,"rest":8},
	"quirk_yawn":{"kinds":["line","promise","wait","decree"],"weight":2.6,"rest":8},
	"quirk_jealous":{"kinds":["divine","decree"],"weight":3.0,"rest":6},
	"quirk_agree":{"kinds":["line","god_speaks","promise","dismiss","decree"],"weight":2.6,"rest":8},
}
## How likely a moment's own bit is when it is rested and possible.
const DIRECT_ODDS:={"double_bow":0.35,"over_thank":0.4,"guard_snap":0.6,"bump_post":0.5,"forgot_thing":0.6,"wrong_door":0.5,"bow_wrong":0.7,
	"child_wave":0.6,"stare_down":0.45,"company_gawk":0.5,"bow_early":0.4}
## How likely an official's own way shows when its moment comes.
const QUIRK_CHANCE:=0.45
## Events the sleeper stays awake once woken, before nodding off again.
const DOZE_AGAIN:=12
## How often a light moment gets a bit from the pool, by kind (a ruler's
## line is common, so it rarely does; a terror nearly always draws something).
const BIT_CHANCE:={"line":0.22,"god_speaks":0.3,"divine":0.75,"command":0.6,"decree":0.55,"gift":0.8,"summon":0.55,"promise":0.4,
	"dismiss":0.35,"wait":0.6,"terrify_envoy":0.9,"envoy_insulted":0.8,"exit":0.5}

# =============================================================================
# Beats
# =============================================================================

## The whole room's beats for one engine event. memory: the stage's own
## presentation memory (cooldowns, who dozes, what played last); pass the same
## dictionary for every event of a session, or {} for a one-off.
static func beats_for(event_in:Dictionary,cast_in:Array,facts_in:Dictionary,rng_seed:int,memory:Dictionary={})->Array:
	var facts:=normal_facts(facts_in)
	var cast:=normal_cast(cast_in,facts,memory.get("voices",{}) if memory.get("voices") is Dictionary else {})
	var event:=normal_event(event_in,cast)
	var kind:=String(event.get("kind",""))
	var out:Array=[]
	var sig:=""
	var last:=String((memory.get("sig",{}) as Dictionary).get(kind,"")) if memory.get("sig") is Dictionary else ""
	var ctx:Dictionary={}
	_audience(memory,cast,kind)
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

## A new audience (someone new before the god, or a new arrival) starts its
## own count of who has carried the comedy.
static func _audience(memory:Dictionary,cast:Array,kind:String)->void:
	var main:=""
	for entry in cast:
		if entry is Dictionary and String((entry as Dictionary).get("key",""))=="main":main=String((entry as Dictionary).get("name",""))
	var aud:Dictionary=memory.get("aud",{}) if memory.get("aud") is Dictionary else {}
	if String(aud.get("main",""))!=main or (kind=="summon" and int(aud.get("events",0))>0):
		memory["aud"]={"main":main,"stars":{},"total":0,"events":0}
		memory.erase("last_speaker");memory.erase("quirk_dozed")

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
## sleeper's waking and dozing, this kind's last signature, and what was
## seen (bits with the one each fell on, and every act), for a muttered line
## to answer.
static func _remember(memory:Dictionary,ctx:Dictionary,sig:String,out:Array)->void:
	var n:=int(memory.get("n",0))+1
	memory["n"]=n
	if not memory.get("bits") is Dictionary:memory["bits"]={}
	for bit in ctx.bits:(memory.bits as Dictionary)[String(bit)]=n
	if not memory.get("sig") is Dictionary:memory["sig"]={}
	(memory.sig as Dictionary)[String(ctx.kind)]=sig
	if ctx.has("woke"):memory["woke"]=n
	if ctx.has("dozed"):memory["dozed"]=n
	# A gift turned away stays with the bearer until the envoy goes.
	if String(ctx.kind)=="gift":memory["gift_refused"]=not bool(ctx.event.get("accepted",true))
	elif String(ctx.kind)=="summon":memory["gift_refused"]=false
	var ends:={}
	var acts:={}
	for beat:Dictionary in out:
		var who:=String(beat.who)
		var end:=float(beat.t)+float((beat.args as Dictionary).get("dur",0.8))
		ends[who]=maxf(float(ends.get(who,0.0)),end)
		if who in ["camera","room"]:continue
		if not acts.has(String(beat.act)):acts[String(beat.act)]=[]
		(acts[String(beat.act)] as Array).append({"who":who,"end":end})
	var played:={}
	var aud:Dictionary=memory.get("aud",{}) if memory.get("aud") is Dictionary else {}
	if not aud.get("stars") is Dictionary:aud["stars"]={}
	for bit in (ctx.stars as Dictionary):
		var star:=String(ctx.stars[bit])
		played[String(bit)]={"star":star,"end":float(ends.get(star,2.5))}
		if not star.is_empty():
			(aud.stars as Dictionary)[star]=int((aud.stars as Dictionary).get(star,0))+1
			aud["total"]=int(aud.get("total",0))+1
	aud["events"]=int(aud.get("events",0))+1
	memory["aud"]=aud
	if String(ctx.kind)=="line":memory["last_speaker"]=String(ctx.event.get("who",""))
	if ctx.has("quirk_dozed"):memory["quirk_dozed"]=String(ctx.quirk_dozed)
	elif String(ctx.kind)=="god_speaks":memory.erase("quirk_dozed")
	memory["last"]={"n":n,"played":played,"acts":acts,"number":int(ctx.get("number",-1)),"number_from":String(ctx.get("number_from","")),
		"other":String(ctx.get("other","")),"struck":String(ctx.get("struck",""))}
	memory["last_envier"]=String(ctx.get("envier",""))

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
			if bool(event.get("removed",false)) and String(event.get("verb",""))=="exile":return "grave"
			if String(event.get("obedience",""))=="refuse" or String(event.get("verb","")) in ["kill","maim","detain","exile"]:return "tense"
		"exit":
			if String(event.get("style","")) in ["fall","led"]:return "grave"
			if String(event.get("style","")) in ["storm","flee"]:return "tense"
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
## commoner, elder, child, scribe, door_guard, dog, goat. temper (an envoy's):
## haughty, nervous, greedy or calm. gifted: the work a gifted child is
## gifted in (geniuses.gd LAYERS).
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
		"temper":String(entry.get("temper","")),"gifted":String(entry.get("gifted","")),"people":String(entry.get("people","player")),
		"x":float(entry.get("x",-1.0)),"index":index}
	m["pos"]=float(entry.pos) if _num(entry.get("pos",null)) else (float(m.x) if float(m.x)>=0.0 else float(index)*0.12)
	m["animal"]=kind in ["dog","goat"]
	m["quirk"]=quirk_of(entry,kind)
	# How hard they flinch, and how soon: the frightened and the timid first.
	m["jumpy"]=clampf(float(m.dread)*0.6+(1.0-float(m.courage))*0.5,0.0,1.0)
	return m

## Each officeholder's comic way, kept for life: the pedant who counts, the
## flatterer, the sleepy one, the jealous one, the one who agrees with
## everyone, or none. Read from their temper (GovernmentPeopleSystem's
## disposition, which their personality fixes), else their lifelong voice
## model, else their traits, else a steady roll of who they are.
const QUIRKS:=["pedant","flatterer","sleepy","jealous","yes_man"]
const QUIRK_BY_DISPOSITION:={"sycophantic":"flatterer","cantankerous":"jealous","principled":"pedant","diplomatic":"yes_man"}
const QUIRK_BY_VOICE:={"polonius":"yes_man","cicero":"pedant","grant":"pedant","falstaff":"flatterer","odysseus":"flatterer","quixote":"flatterer",
	"sancho":"sleepy","nestor":"sleepy","iago":"jealous","achilles":"jealous","heathcliff":"jealous","lady_macbeth":"jealous"}
const QUIRK_BY_TRAIT:={"Methodical":"pedant","Skeptical":"pedant","Ambitious":"jealous","Humble":"yes_man","Cautious":"yes_man","Patient":"sleepy","Warm":"flatterer","Generous":"flatterer"}
static func quirk_of(entry:Dictionary,kind:String)->String:
	if entry.has("quirk"):return String(entry.quirk)
	if not kind in ["official","hearth_chief"]:return ""
	var id:=str(int(entry.get("person_id",0))) if int(entry.get("person_id",0))>0 else String(entry.get("name",""))
	var roll:=posmod(hash("quirk|"+id),6)
	var disposition:=String(entry.get("disposition",""))
	if QUIRK_BY_DISPOSITION.has(disposition):return String(QUIRK_BY_DISPOSITION[disposition])
	if disposition=="pragmatic":return "sleepy" if roll<2 else ""
	var voice:=String(entry.get("voice","")).to_lower()
	if QUIRK_BY_VOICE.has(voice):return String(QUIRK_BY_VOICE[voice])
	for t in (entry.get("traits",[]) if entry.get("traits") is Array else []):
		if QUIRK_BY_TRAIT.has(String(t)):return String(QUIRK_BY_TRAIT[String(t)])
	return ["pedant","flatterer","sleepy","jealous","yes_man",""][roll]

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
		"people":String(person.get("appearance_civ_id",person.get("civilization_id","player"))),
		"courage":float(person.get("courage",0.5)),"pride":float(person.get("pride",0.5)),"empathy":float(personality.get("empathy",0.5)),
		"love":float(divine.call("love_of",person)),"dread":float(divine.call("dread_of",person)),"resentment":float(rel.get("resentment",0.0)),
		"office":String(person.get("office_title",person.get("title",""))),"voice":String(person.get("voice_model",""))}
	if String(person.get("office_key",""))=="settlement":entry["kind"]="hearth_chief"
	if person.get("traits") is Array:entry["traits"]=(person.traits as Array).duplicate()
	# Their temper, which their personality fixes for life.
	if Engine.get_main_loop()!=null and int(person.get("person_id",0))>0 and String(person.get("office_key",""))!="":
		var disposition:Variant=GovernmentPeopleSystem.leader_disposition(person)
		if disposition is Dictionary:entry["disposition"]=String((disposition as Dictionary).get("id",""))
	# Someone the court summoned from among the people, not an officeholder.
	if String(person.get("known_id",""))!="" or String(person.get("kind",""))=="known":entry["kind"]="child" if years<14 else "commoner"
	elif years<14:entry["kind"]="child"
	var genius:Variant=person.get("genius",null)
	if genius is Dictionary and String((genius as Dictionary).get("layer",""))!="":entry["gifted"]=String(genius.layer)
	elif String(person.get("gifted",""))!="":entry["gifted"]=String(person.gifted)
	entry.merge(extra,true)
	return entry

## The people who stand about the hall besides the court, more of them as
## the age grows: an old one, a child and someone of the camp with a bowl at
## first; a little one and another of the people once they settle; more
## people, a guard at the door and, where the people write ("writing"), a
## scribe; the dog always, and a goat once the people pen herds ("dairy").
## Their love and dread of the god are the people's own (facts people_love,
## people_dread), each a little their own. Named in the people's tongue
## (era_names.gd) when the game is running; `taken` keeps names unshared.
## The officials are never invented here: they are the engine's officeholders.
static func extras(facts:Dictionary,rng_seed:int,taken:Dictionary={})->Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|extras" % rng_seed)
	var dread:=people_dread(facts)
	var love:=people_love(facts) if _num(facts.get("people_love",null)) else 0.45
	var tags:Array=facts.get("era_tags",[]) if facts.get("era_tags") is Array else []
	var tier:=int(facts.era_tier) if _num(facts.get("era_tier",null)) else int(preload("res://scripts/character_voice.gd").era_tier(tags))
	var rows:Array=[["crowd_elder","elder",62+rng.randi_range(0,14),""],["crowd_child","child",6+rng.randi_range(0,5),""],["crowd_bowl","commoner",22+rng.randi_range(0,20),"bowl"]]
	var protocol:=presentation(facts)
	if not bool(protocol.get("rustic_props",true)):
		rows[2]=["crowd_visitor","commoner",int(rows[2][2]),"clasped"]
	if tier>=1:
		rows.append(["crowd_child2","child",3+rng.randi_range(0,3),""])
		rows.append(["crowd_1","commoner",18+rng.randi_range(0,30),""])
	if tier>=2:
		for i in 2:rows.append(["crowd_%d" % (rows.size()-3),"commoner",18+rng.randi_range(0,40),""])
		rows.append(["door_guard","door_guard",22+rng.randi_range(0,15),""])
	if tier>=3:
		for i in 2:rows.append(["crowd_%d" % (rows.size()-3),"commoner",18+rng.randi_range(0,40),""])
	if tags.has("writing"):rows.append(["scribe","scribe",26+rng.randi_range(0,25),""])
	# A working ministry or cabinet has a small adult support staff. The
	# ledger's actual petitioners and officials are cast separately; random
	# village children should not occupy their conference-room chairs.
	if String(protocol.get("period","")) in ["early_modern","industrial","modern"]:
		rows=[["crowd_visitor","commoner",24+rng.randi_range(0,35),"clasped"],
			["door_guard","door_guard",24+rng.randi_range(0,25),"stand"]]
		if bool(protocol.get("paperwork",false)):rows.append(["scribe","scribe",26+rng.randi_range(0,35),"stand"])
	var out:Array=[]
	var serial:=0
	for row in rows:
		var kind:=String(row[1])
		var woman:=rng.randf()<0.5
		var entry:={"key":String(row[0]),"role":"crowd","kind":kind,"age":int(row[2]),"sex":"female" if woman else "male",
			"courage":clampf(0.5+rng.randf_range(-0.25,0.25)-(0.15 if kind=="child" else 0.0)+(0.25 if kind=="door_guard" else 0.0),0.05,0.95),"pride":clampf(rng.randf_range(0.15,0.55),0.0,1.0),
			"empathy":clampf(rng.randf_range(0.35,0.8),0.0,1.0),"love":clampf(love+rng.randf_range(-0.12,0.12),0.0,1.0),"dread":clampf(dread+rng.randf_range(-0.1,0.15),0.0,1.0),
			"name":_crowd_name(rng_seed,serial,woman,taken)}
		if String(row[3])!="":entry["stance"]=String(row[3])
		if kind=="scribe" and bool(protocol.get("paperwork",false)):entry["paperwork"]=true
		out.append(entry)
		serial+=1
	if bool(protocol.get("court_animals",true)):
		out.append({"key":"dog","role":"animal","kind":"dog","name":"the dog"})
		if tags.has("dairy"):out.append({"key":"goat","role":"animal","kind":"goat","name":"the goat"})
	return out

static func _crowd_name(rng_seed:int,serial:int,woman:bool,taken:Dictionary)->String:
	if Engine.get_main_loop()==null or not ResourceLoader.exists("res://scripts/era_names.gd"):return ""
	var made:Dictionary=(load("res://scripts/era_names.gd") as GDScript).call("make",int(GameState.world_seed),900000+posmod(rng_seed,9000)*20+serial,woman,"player",taken)
	var name:=String(made.get("name",""))
	if not name.is_empty():
		taken[name]=true
		taken["given:"+String(made.get("given",name.get_slice(" ",0)))]=true
	return name

## An envoy's temper on stage, from what the engine holds of them: their
## people's dread of our god (nervous), their ruler's temperament and their
## business (haughty: a proud guardian, a threat, a bluffer or a grudge),
## their ruler's trait (greedy: one who counts every gift or covets crafts).
static func envoy_temper(envoy:Dictionary)->String:
	if _num(envoy.get("their_dread",null)) and float(envoy.their_dread)>=0.45:return "nervous"
	var mark:=String(envoy.get("trait",""))
	if String(envoy.get("temperament",""))=="Proud guardian" or String(envoy.get("kind",""))=="threat" or mark in ["bluffer","grudge"]:return "haughty"
	if mark in ["ledger","magpie","hunter"] or String(envoy.get("kind",""))=="request":return "greedy"
	if String(envoy.get("kind",""))=="news" and String(envoy.get("temperament",""))=="Bridge-builder":return "nervous"
	return "calm"

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

## Profiles are supplied with the fact sheet, never inferred from the day or
## the player's knowledge here. An envoy may retain their own people's manners.
## Old callers without a profile keep the original performance unchanged.
static func presentation(facts:Dictionary,person:Dictionary={})->Dictionary:
	var profiles:Dictionary=facts.get("presentations",{}) if facts.get("presentations") is Dictionary else {}
	var owner:=String(person.get("people",""))
	if owner!="" and profiles.get(owner) is Dictionary:return profiles[owner]
	return facts.get("presentation",{}) if facts.get("presentation") is Dictionary else {}

static func routine_act(facts:Dictionary,person:Dictionary,fallback:String,departure:=false)->String:
	var profile:=presentation(facts,person)
	var act:=String(profile.get("routine_departure" if departure else "routine_greeting",fallback))
	return act if ACTS.has(act) else fallback

static func _greet(ctx:Dictionary,out:Array,t:float,who:String,fallback:String,departure:=false)->void:
	if String(ctx.firm)==who:return
	var person:=_m(ctx,who)
	_beat(out,t,who,routine_act(ctx.facts,person,fallback,departure),{"routine":true} if not presentation(ctx.facts,person).is_empty() else {},"action")

static func _writing_act(facts:Dictionary,person:Dictionary)->String:
	var profile:=presentation(facts,person)
	# The existing rig has no folio: consider the briefing without miming
	# writing on an absent page. A supported stationery prop can add that later.
	return "review_brief" if bool(profile.get("paperwork",false)) and String(profile.get("period","")) in ["medieval","early_modern","industrial","modern"] else "scribble"

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
	return float(m.get("pos",float(m.get("index",0))*0.12))

## The nearest person to m (by where they stand), of the kinds given.
static func _nearest(ctx:Dictionary,m:Dictionary,kinds:Array=[],exclude:Array=[])->Dictionary:
	var best:={};var gap:=INF
	if m.is_empty():return best
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

static func _shuffled(rng:RandomNumberGenerator,list:Array)->Array:
	var out:=list.duplicate()
	for i in range(out.size()-1,0,-1):
		var j:=rng.randi_range(0,i)
		var swap:Variant=out[i];out[i]=out[j];out[j]=swap
	return out

# --- Facts, read -------------------------------------------------------------------

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func hungry(facts:Dictionary)->bool:
	if _num(facts.get("food_days",null)):return float(facts.food_days)<HUNGRY_DAYS
	return bool(facts.get("hungry",false))

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

## The one who dozes through the audience: an old person in the crowd or
## among the officials, while nobody is in terror. The same each time for a
## cast, so ambient and the god's voice agree on who wakes.
static func dozer(cast:Array,facts:Dictionary)->String:
	if people_dread(facts)>=DREAD_HIGH:return ""
	var best:="";var best_age:=0
	for entry in cast:
		if not entry is Dictionary:continue
		var m:=member(entry)
		if String(m.role)=="main" or bool(m.animal) or String(m.kind) in ["envoy","guard","bearer","attendant","child","scribe","door_guard"]:continue
		if int(m.age)>=58 and float(m.dread)<0.5 and int(m.age)>best_age:best=String(m.key);best_age=int(m.age)
	return best

# --- Writing beats -------------------------------------------------------------------

static func _beat(out:Array,t:float,who:String,act:String,args:Dictionary={},phase:="reaction")->void:
	if who.is_empty():return
	var spec:Dictionary=ACTS.get(act,{})
	var a:=args.duplicate()
	if not a.has("dur"):a["dur"]=float(spec.get("dur",0.8))
	if spec.has("speed") and not a.has("speed"):a["speed"]=float(spec.speed)
	var beat:={"t":snappedf(maxf(t,0.0),0.01),"who":who,"act":act,"args":a,"phase":phase}
	# What is heard: the act's own sound, or the one the beat asks for
	# ("" for silence); the room's hush cuts the murmur.
	var sound:Array=SOUNDS.get(act,[])
	if a.has("sound"):
		sound=[String(a.sound),float(a.get("gain",0.8)),String(a.get("glyph",""))] if String(a.sound)!="" else []
		a.erase("sound")
	if who=="room" and act=="hush":
		a["cut"]=true
		beat["sound"]={"name":HUSH_SOUND,"dur":float(a.dur),"gain":1.0,"glyph":"","who":"room"}
	elif not sound.is_empty() and String(sound[0])!="":
		beat["sound"]={"name":String(sound[0]),"gain":float(sound[1]),"glyph":String(sound[2]),"who":who}
		if String(sound[0])=="footsteps":(beat.sound as Dictionary)["pace"]=String({"storm_off":"stomp","come_back":"stomp","come_back_for":"stomp","bolt":"run","hurry_after":"hurry","hurry_round":"hurry","hurry":"hurry","back_out_bowing":"shuffle","edge_forward":"shuffle","make_room":"shuffle","step_back":"shuffle"}.get(act,"walk"))
	out.append(beat)

static func _shot(out:Array,t:float,shot:String,args:Dictionary={})->void:
	_beat(out,t,"camera",shot,args,"camera")

## A bit was played: remembered with the one it fell on (the star), so a
## muttered line can answer it.
static func _ran(ctx:Dictionary,bit:String)->void:
	if not (ctx.bits as Array).has(bit):(ctx.bits as Array).append(bit)
	# A moment that is someone's own (an envoy's temper, a gifted child) still
	# plays, but does not count them past their share.
	var star:=String(ctx.get("star",""))
	if not star.is_empty() and not _share_left(ctx,star):star=""
	(ctx.stars as Dictionary)[bit]=star
	ctx["star"]=""

## How much of one audience's comedy one person may carry: about a quarter
## once there is enough of it (the one before the god may carry two bits).
const STAR_SHARE:=0.25
## What a bit may leave on the moment, put back if the bit is taken back.
const SIDE_KEYS:=["woke","fainted","number","number_from","other","struck","eager","cougher","dozed","star","quirk_dozed"]

## Plays a bit unless the one it would fall on already carries their share
## of this audience's comedy; then it is taken back whole. True if it played.
static func _try(ctx:Dictionary,bit:String,out:Array,at:float)->bool:
	var size:=out.size()
	var saved:={}
	for key in SIDE_KEYS:
		if ctx.has(key):saved[key]=ctx[key]
	if not _bit(ctx,bit,out,at):return false
	var star:=String(ctx.get("star",""))
	if not star.is_empty() and not _share_left(ctx,star):
		out.resize(size)
		for key in SIDE_KEYS:
			if saved.has(key):ctx[key]=saved[key]
			else:ctx.erase(key)
		return false
	_ran(ctx,bit)
	return true

## Whether this person may carry one more bit in this audience.
static func _share_left(ctx:Dictionary,star:String)->bool:
	var aud:Dictionary=ctx.memory.get("aud",{}) if ctx.memory.get("aud") is Dictionary else {}
	var stars:Dictionary=aud.get("stars",{}) if aud.get("stars") is Dictionary else {}
	var total:=int(aud.get("total",0))
	var mine:=int(stars.get(star,0))
	for bit in (ctx.stars as Dictionary):
		var who:=String(ctx.stars[bit])
		if who.is_empty():continue
		total+=1
		if who==star:mine+=1
	var allowed:=maxi(2 if star==String(ctx.main) else 1,floori(STAR_SHARE*float(total+1)))
	return mine+1<=allowed

## Is a bit rested (and, when drawn from the pool, does it fit this kind)?
static func _rested(ctx:Dictionary,bit:String,pooled:=false)->bool:
	var spec:Dictionary=BITS.get(bit,{})
	if pooled and not String(ctx.kind) in (spec.get("kinds",[]) as Array):return false
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
	# An official's own way comes out when its moment comes (the pedant when
	# a number is said, the flatterer when the god speaks), more often than
	# the room's chance business.
	var ways:Array=[]
	for bit in ["quirk_count","quirk_flatter","quirk_yawn","quirk_jealous","quirk_agree"]:
		if not (ctx.bits as Array).has(bit) and _rested(ctx,bit,true) and _can(ctx,bit):ways.append(bit)
	if not ways.is_empty() and rng.randf()<QUIRK_CHANCE:
		if _try(ctx,String(ways[rng.randi_range(0,ways.size()-1)]),out,at):
			count-=1
			if count<=0:return
	if rng.randf()>float(BIT_CHANCE.get(String(ctx.kind),0.4)):return
	var open:Array=[]
	var total:=0.0
	for bit:String in BITS:
		if (ctx.bits as Array).has(bit):continue
		if not _rested(ctx,bit,true) or not _can(ctx,bit):continue
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
		_try(ctx,bit,out,at+float(i)*0.5)

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
		"wait":_wait(ctx,out)
		"gift":_gift(ctx,out)
		"summon":_summon(ctx,out)
		"exit":_exit(ctx,out)
		"terrify_envoy":_terrify_envoy(ctx,out)
		"envoy_insulted":_insulted(ctx,out)
		"execution":_execution(ctx,out)
	return out

## The god speaks: the room stills and every face lifts toward the voice, a
## ripple from the one before the god outward. The goat does not care; the
## scribe, where the people write, gets every word down.
static func _god_speaks(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var rng:RandomNumberGenerator=ctx.rng
	# The stage says how the words land (court_stage.gd _tone_of): wrath or
	# favour; either spelling of favour.
	var tone:=String(event.get("tone",""))
	var wrath:=tone=="wrath"
	var favour:=tone in ["favor","favour"]
	_beat(out,0.0,"room","hush",{"dur":1.6,"bubbles":"dim"},"anticipation")
	var addressed:=String(event.get("target",event.get("who",ctx.main)))
	var main:=_m(ctx,addressed)
	# Let the room register the voice, move once, and let the face hold it.
	# No camera hunt through the crowd while the player reads the words.
	var voice_hold:=maxf(2.2,float(event.get("seconds",2.0))+0.8)
	if not main.is_empty():
		_shot(out,0.24,"push_in",{"target":addressed,"dramatic":true,"seconds":1.05})
		_shot(out,voice_hold,"wide",{"dramatic":true,"time":1.1})
	var order:Array=_people(ctx)
	var origin:=_where(main) if not main.is_empty() else 0.5
	order.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return absf(_where(a)-origin)<absf(_where(b)-origin) if not is_equal_approx(absf(_where(a)-origin),absf(_where(b)-origin)) else int(a.index)<int(b.index))
	var sleeper:=_asleep(ctx)
	var dozing:=String(ctx.memory.get("quirk_dozed",""))
	if not _m(ctx,dozing).is_empty():
		_beat(out,0.7,dozing,"jerk_awake",{},"reaction")
		_beat(out,1.1,dozing,"nod_too_much",{},"reaction")
	var step:=0
	for m:Dictionary in order:
		if String(m.key)==sleeper or String(m.key)==dozing:continue
		if String(m.kind)=="scribe":continue
		var look_at:=0.05+step*0.07+rng.randf()*0.08
		# The live stage owns its conversation focus; standalone directors keep
		# their original ripple. Consume the same draw for the other reactions.
		if not bool(event.get("attention_staged",false)):_beat(out,look_at,String(m.key),"look_up",{},"action")
		step+=1
	for dog:Dictionary in _of_kind(ctx,["dog"]):_beat(out,0.2,String(dog.key),"perk_up",{},"action")
	for scribe:Dictionary in _of_kind(ctx,["scribe"]):_beat(out,0.3,String(scribe.key),_writing_act(ctx.facts,scribe),{},"action")
	# Under the voice, one or two do their own small thing.
	var rng0:RandomNumberGenerator=ctx.rng
	for m:Dictionary in _shuffled(rng0,_people(ctx,[String(ctx.main),sleeper,dozing])).slice(0,rng0.randi_range(1,2)):
		var small:String=["straighten","lips_pressed","shift_weight","glance_up" if float(m.dread)>=0.4 or wrath else "smile_warm"][rng0.randi_range(0,3)]
		_beat(out,0.9+rng0.randf()*0.6,String(m.key),small,{},"reaction")
	# The voice usually wakes the sleeper, a beat behind everyone; now and
	# then they sleep straight through it.
	if not sleeper.is_empty() and rng.randf()<0.75:_wake(ctx,out,0.9)
	# The god's voice in a room that dreads it: someone trembles under it.
	if people_dread(ctx.facts)>=DREAD_HIGH:
		var shaky:Array=_jumpiest(_people(ctx,[String(ctx.main)]))
		if not shaky.is_empty():_beat(out,0.6,String((shaky[0] as Dictionary).key),"glance_up",{"because":"people_dread"},"reaction")
	_play_bits(ctx,out,0.4)
	# Angry words: the one they fall on goes still, and the jumpiest in the
	# room flinches at the first of them.
	if wrath:
		if not main.is_empty():_beat(out,0.25,String(ctx.main),"freeze",{},"reaction")
		var jumpy:Array=_jumpiest(_people(ctx,[String(ctx.main),sleeper]))
		if not jumpy.is_empty():_beat(out,0.35,String((jumpy[0] as Dictionary).key),"flinch",{"dur":0.5},"reaction")
	if favour and people_love(ctx.facts)>=LOVE_HIGH:
		var warm:Array=_people(ctx,[String(ctx.main)])
		if not warm.is_empty():_beat(out,1.0,String(_pick(ctx,warm).key),"lean_in",{"because":"people_love"},"reaction")

## How a line's bubble is performed (never what it says): "tremble" for the
## terrified (dread high, or they went down before the god just now),
## "aside" for words murmured to the god alone, "small" for a child, else
## "speech". amount: how much it trembles, 0..1.
static func speech_style(event:Dictionary,cast:Array,facts:Dictionary={},memory:Dictionary={})->Dictionary:
	var who:=String(event.get("who",""))
	var m:={}
	var index:=0
	for entry in cast:
		if entry is Dictionary and String((entry as Dictionary).get("key",""))==who:m=member(entry,index)
		index+=1
	if String(event.get("kind",""))=="god_speaks":return {"style":"god","amount":0.0}
	if m.is_empty():return {"style":"speech","amount":0.0}
	var shaken:=false
	var last:Dictionary=memory.get("last",{}) if memory.get("last") is Dictionary else {}
	var acts:Dictionary=last.get("acts",{}) if last.get("acts") is Dictionary else {}
	for act in ["kneel","knees_knock","prostrate","flinch","faint","plead"]:
		for seen in acts.get(act,[]):
			if String((seen as Dictionary).get("who",""))==who:shaken=true
	var dread:=maxf(float(m.dread),people_dread(facts)*0.8)
	if shaken or dread>=DREAD_HIGH:return {"style":"tremble","amount":clampf(0.35+dread*0.6,0.3,1.0)}
	if bool(event.get("aside",false)):return {"style":"aside","amount":0.0}
	if String(m.kind)=="child":return {"style":"small","amount":0.0}
	return {"style":"speech","amount":0.0}

## A line said: the speaker talks (the stage does that). Around them, now and
## then, someone reacts: a number said lands as a double take timed to when
## the number appears in the bubble, and the scribe writes it down.
static func _line(ctx:Dictionary,out:Array)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var who:=String(ctx.event.get("who",""))
	if not _m(ctx,who).is_empty():
		var style:=speech_style(ctx.event,ctx.cast,ctx.facts,ctx.memory)
		_beat(out,0.0,who,"bubble",style,"action")
	var listeners:Array=_people(ctx,[who])
	if listeners.is_empty():return
	var said:=number_in(String(ctx.event.get("text","")))
	if not said.is_empty():
		for scribe:Dictionary in _of_kind(ctx,["scribe"],[who]):_beat(out,0.15+float(said.at)*0.025+0.3,String(scribe.key),_writing_act(ctx.facts,scribe),{},"reaction")
	if rng.randf()<0.35:
		var nodder:=_pick(ctx,listeners)
		if float(nodder.love)>=0.45:_beat(out,1.2+rng.randf()*0.8,String(nodder.key),"nod",{},"reaction")
		else:_beat(out,1.4+rng.randf()*0.8,String(nodder.key),"shift_weight",{},"reaction")
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
	# Anticipation: the room stills, then the camera registers the subject.
	# A physical response keeps the whole body in view.
	_beat(out,0.0,"room","hush",{"dur":3.6 if big else 2.4},"anticipation")
	if not t_m.is_empty():_shot(out,0.18,"push_in",{"target":target,"close":big,"dramatic":true,"whole":response=="cower","seconds":0.85})
	var sleeper:=_asleep(ctx)
	for m:Dictionary in _people(ctx,[target,sleeper]):
		if rng.randf()<(0.75 if big else 0.4):_beat(out,0.08+rng.randf()*0.2,String(m.key),"freeze",{},"anticipation")
	# The action: what the engine says they did.
	var land:=0.55 if big else 0.7
	if big:_shot(out,land,"shake",{"strength":0.22,"dramatic":true})
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
		_gasp(ctx,out,land+1.0,[target,sleeper],true)
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
	# The hold: nobody moves; then the room breathes again. Under a terror the
	# silence is total, and one small noise breaks it.
	var hold:=land+(2.9 if big else 2.2)
	_beat(out,hold,"room","hush",{"dur":1.4 if big else 0.9},"hold")
	if big and not (ctx.bits as Array).has("goat_ignores") and _rested(ctx,"dead_silence") and _can(ctx,"dead_silence") and _try(ctx,"dead_silence",out,hold+0.5):pass
	if not ctx.bits.has("gasp_pretend") and not ctx.bits.has("dead_silence") and big:
		var shaken:Array=_jumpiest(_people(ctx,[target,String(ctx.get("fainted","")),sleeper]))
		if not shaken.is_empty():_beat(out,hold+0.7,String((shaken[0] as Dictionary).key),"straighten",{},"hold")
	# Cowering reaches its kneel after the tremble. Do not pull away halfway
	# down; no timing or lower-body track of the adjudicated response changes.
	var release:=maxf(hold+0.6,land+1.5+2.5+0.5) if big and response=="cower" else hold+0.6
	_shot(out,release,"wide",{"dramatic":true,"time":1.1})

## How a witness meets the god's act (divine_regard.gd witness_response):
## used only when the engine's own reading of them is not given.
static func _witness(action:String,m:Dictionary)->String:
	if action in ["terrify","penance","cast_out","strike_down"]:
		return "unbowed" if float(m.pride)>0.72 and float(m.courage)>0.68 else "shaken"
	var bar:=float({"bless":0.7,"boon":0.65,"raise_up":0.6}.get(action,0.7))
	return "envy" if float(m.pride)>bar else "glad"

## Favour: the favoured one glows and, now and then, cannot stop thanking;
## the proud who think it should have been them look sideways.
static func _favour(ctx:Dictionary,out:Array,action:String,target:String,response:String)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var t_m:=_m(ctx,target)
	if not t_m.is_empty():_shot(out,0.22,"push_in",{"target":target,"dramatic":true,"seconds":0.9})
	_beat(out,0.0,"room","hush",{"dur":1.2},"anticipation")
	if not t_m.is_empty():
		_beat(out,0.5,target,"exhale" if response=="relief" else "beam",{},"action")
		if _bit_ready(ctx,"over_thank") and _try(ctx,"over_thank",out,1.1):pass
		else:_beat(out,1.1,target,"bow",{},"action")
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
	if not envier.is_empty() and not t_m.is_empty():
		# Their sideways reaction still plays in the room. The favoured face
		# keeps this beat rather than a second shot interrupting the first move.
		ctx["envier"]=String(envier.key)
	# A gift of food from the stores while people go short: every eye on it.
	var terms:Dictionary=ctx.event.get("terms",{}) if ctx.event.get("terms") is Dictionary else {}
	if action=="boon" and String(terms.get("resource","")).to_lower()=="food" and hungry(ctx.facts):
		var eyes:Array=_shuffled(rng,_people(ctx,[target]))
		for i in mini(2 if not starving(ctx.facts) else 3,eyes.size()):
			_beat(out,1.4+i*0.3,String((eyes[i] as Dictionary).key),"eye_food",{"at":target,"because":"food_days"},"reaction")
	_play_bits(ctx,out,1.3)
	_beat(out,3.0,"room","hush",{"dur":0.6},"hold")
	_shot(out,3.8,"wide",{"dramatic":true,"time":1.1})

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
			var act:String=["look_away","look_away","lips_pressed","freeze","head_down"][rng.randi_range(0,4)]
			_beat(out,t,key,act,{},"reaction")
	for child:Dictionary in _of_kind(ctx,["child"]):
		var adult:=_nearest(ctx,child,["elder","commoner","official","hearth_chief"],[target])
		if not adult.is_empty():_beat(out,1.0+rng.randf()*0.3,String(adult.key),"cover_eyes",{"at":String(child.key)},"reaction")
	for dog:Dictionary in _of_kind(ctx,["dog"]):_beat(out,2.2,String(dog.key),"whimper",{},"hold")
	if not loving.is_empty():_shot(out,1.6,"reaction",{"target":String(loving.key)})
	_shot(out,3.8,"wide")

## Cast out: no comedy either. The near edge away; the fond watch them go.
static func _cast_out(ctx:Dictionary,out:Array,target:String)->void:
	_beat(out,0.0,"room","hush",{"dur":3.6},"anticipation")
	if not _m(ctx,target).is_empty():_beat(out,0.3,target,"stricken",{},"action")
	var rng:RandomNumberGenerator=ctx.rng
	for m:Dictionary in _people(ctx,[target]):
		var t:=0.8+_lag(ctx,m)
		if absf(_where(m)-_where(_m(ctx,target)))<0.2 and rng.randf()<0.7:_beat(out,t,String(m.key),"edge_away",{"at":target},"reaction")
		elif float(m.love)>=0.5 or float(m.empathy)>=0.6:_beat(out,t+0.6,String(m.key),["watch_go","watch_go","hand_to_mouth"][rng.randi_range(0,2)],{"at":target},"reaction")
		else:_beat(out,t+0.4,String(m.key),["look_away","lips_pressed","freeze"][rng.randi_range(0,2)],{},"reaction")
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
		# and someone is a beat late. Then nobody breathes.
		_shot(out,0.0,"wide")
		var all:Array=_people(ctx)
		var late:={}
		var can_be_late:Array=all.filter(func(m:Dictionary)->bool:return _share_left(ctx,String(m.key)))
		if all.size()>=3 and not can_be_late.is_empty():late=_pick(ctx,can_be_late)
		for m:Dictionary in all:
			if String(m.key)==String(late.get("key","")):continue
			_beat(out,0.2+rng.randf()*0.35,String(m.key),"prostrate",{},"action")
		if not late.is_empty():
			_beat(out,0.7,String(late.key),"look_wrong_way",{},"reaction")
			_beat(out,1.4,String(late.key),"prostrate",{},"reaction")
			ctx["star"]=String(late.key)
			_ran(ctx,"late_prostrate")
		for dog:Dictionary in _of_kind(ctx,["dog"]):_beat(out,1.0,String(dog.key),"lie_down",{},"reaction")
		_beat(out,2.0,"room","hush",{"dur":1.6},"hold")
		if _rested(ctx,"dead_silence") and _can(ctx,"dead_silence") and _try(ctx,"dead_silence",out,2.6):pass
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
				_shot(out,0.0,"push_in",{"target":actor,"close":true})
				_beat(out,0.5,actor,"shake_head",{},"action")
				_beat(out,1.0,actor,"stand_firm",{},"action")
				_gasp(ctx,out,1.1,[actor],_rested(ctx,"gasp_pretend"))
				if stage=="refuse_flee":_beat(out,2.0,actor,"bolt",{},"action")
				elif stage=="refuse_seized":
					var hands:Array=_of_kind(ctx,["guard","door_guard","official","hearth_chief","commoner"],[actor,String(ctx.main)])
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
				var watchers:Array=_people(ctx,[actor,target])
				if not watchers.is_empty() and rng.randf()<0.45:_beat(out,1.2+rng.randf()*0.5,String(_pick(ctx,watchers).key),"look_at",{"at":actor},"reaction")
	# A cruel order: the officials look at one another; nobody laughs.
	if verb in ["kill","maim","detain","exile"]:
		var two:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[actor,target]))
		if two.size()>=2:
			_beat(out,1.2,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"reaction")
			_beat(out,1.3,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"reaction")
		for m:Dictionary in _people(ctx,[actor,target]+two.slice(0,2).map(func(x:Dictionary)->String:return String(x.key))):
			if rng.randf()<0.5:continue
			var act:String=["look_away","lips_pressed","hand_to_mouth","freeze"][rng.randi_range(0,3)] if float(m.empathy)>=0.5 or float(m.love)>=0.5 else ["lips_pressed","look_at","freeze"][rng.randi_range(0,2)]
			_beat(out,1.0+_lag(ctx,m),String(m.key),act,{"at":actor} if act=="look_at" else {},"reaction")
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
	if _rested(ctx,"stifle_elbow") and _can(ctx,"stifle_elbow") and rng.randf()<0.65 and _try(ctx,"stifle_elbow",out,2.0):pass
	elif rng.randf()<0.5:_play_bits(ctx,out,2.2)

## A gasp through the room; with `pretend`, one or two of the jumpiest then
## pretend it never happened (the bit, which rests like any other).
static func _gasp(ctx:Dictionary,out:Array,at:float,exclude:Array,pretend:=true)->void:
	var rng:RandomNumberGenerator=ctx.rng
	# The visitor's own company does not gasp at them: they hurry after.
	var room:Array=_people(ctx,exclude).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["guard","bearer","attendant"])
	if room.size()<2:return
	var heard:=false
	for m:Dictionary in room:
		var roll:=rng.randf()
		var act:="gasp" if roll<0.6 else ("hand_to_mouth" if roll<0.8 else "freeze")
		# The proud and brave do not gasp: they set their jaw.
		if float(m.pride)>0.7 and float(m.courage)>0.65:act=["lips_pressed","cross_arms","straighten"][rng.randi_range(0,2)]
		# The whole room's gasp is heard once, as one sound.
		var args:={}
		if act=="gasp":
			args={"sound":"gasp_room","gain":1.0,"glyph":"gasp"} if not heard else {"sound":""}
			heard=true
		_beat(out,at+rng.randf()*0.15,String(m.key),act,args,"reaction")
	if not pretend:return
	var caught:Array=_shuffled(rng,_jumpiest(room).filter(func(m:Dictionary)->bool:return _share_left(ctx,String(m.key))).slice(0,3))
	var pretenders:=1+rng.randi_range(0,1)
	for i in mini(pretenders,caught.size()):_beat(out,at+1.6+i*0.25,String((caught[i] as Dictionary).key),"pretend_calm",{},"hold")
	if not caught.is_empty():ctx["star"]=String((caught[0] as Dictionary).key)
	_ran(ctx,"gasp_pretend")

## A decree: the god's own (issued), or a petition granted, refused, or
## granted at a cost the people will carry.
static func _decree(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var rng:RandomNumberGenerator=ctx.rng
	var who:=String(event.get("who",ctx.main))
	var reaction:=String(event.get("reaction","neutral"))
	var accepted:=bool(event.get("accepted",reaction in ["delighted","pleased"]))
	var w:=_m(ctx,who)
	if bool(event.get("issued",false)):
		# The god lays down a decree: the officials take it gravely, the
		# scribe gets it down, the eager over-agree.
		_beat(out,0.0,"room","hush",{"dur":1.4},"anticipation")
		for m:Dictionary in _of_kind(ctx,["official","hearth_chief"]):
			if rng.randf()<0.6:_beat(out,0.6+_lag(ctx,m),String(m.key),["nod","straighten","lips_pressed"][rng.randi_range(0,2)],{},"reaction")
		for scribe:Dictionary in _of_kind(ctx,["scribe"]):_beat(out,0.4,String(scribe.key),_writing_act(ctx.facts,scribe),{},"reaction")
	elif not w.is_empty():
		if accepted:
			_beat(out,0.4,who,"exhale" if float(w.dread)>=0.4 else "beam",{},"action")
			# Now and then one bow is not enough for them.
			if _bit_ready(ctx,"over_thank") and _try(ctx,"over_thank",out,1.1):pass
			elif _bit_ready(ctx,"double_bow") and _try(ctx,"double_bow",out,1.1):pass
			else:_greet(ctx,out,1.1,who,"bow")
		elif reaction in ["offended","furious"]:
			_beat(out,0.4,who,"stiffen" if reaction=="furious" or float(w.pride)>0.65 else "face_fall",{},"action")
		else:_beat(out,0.5,who,"face_fall",{"dur":1.0},"action")
	# What it costs the people, in their eyes.
	var cost:Dictionary=event.get("cost",{}) if event.get("cost") is Dictionary else {}
	if accepted and not cost.is_empty():
		var payers:Array=_shuffled(rng,_people(ctx,[who]).filter(func(m:Dictionary)->bool:return String(m.kind) in ["official","hearth_chief","commoner","elder"]))
		if payers.size()>=2:
			_beat(out,1.4,String((payers[0] as Dictionary).key),"side_eye",{"at":who},"reaction")
			_beat(out,1.7,String((payers[1] as Dictionary).key),"exchange_look",{"at":String((payers[0] as Dictionary).key)},"reaction")
		for chief:Dictionary in _of_kind(ctx,["hearth_chief"],[who]):
			_beat(out,1.9,String(chief.key),"glum",{},"reaction");break
	var others:Array=_people(ctx,[who])
	if not accepted and not others.is_empty():
		var kind_one:Array=others.filter(func(m:Dictionary)->bool:return float(m.empathy)>=0.6)
		if not kind_one.is_empty():_beat(out,1.2,String(_pick(ctx,kind_one).key),"sympathetic_look",{"at":who},"reaction")
	_play_bits(ctx,out,1.0)

static func _bit_ready(ctx:Dictionary,bit:String,chance:=-1.0)->bool:
	## True when one of the moment's own bits plays now (rested, possible, and
	## the roll falls its way): the plain version of the moment steps aside.
	if String(ctx.gravity)=="grave":return false
	var odds:=chance if chance>=0.0 else float(DIRECT_ODDS.get(bit,0.5))
	if bit=="guard_snap" and String(ctx.kind)=="terrify_envoy":odds=0.85
	return _rested(ctx,bit) and _can(ctx,bit) and (ctx.rng as RandomNumberGenerator).randf()<odds

## The sleeper wakes: the voice or the fury jolts them, they look the wrong
## way, then up, a full second behind the room.
static func _wake(ctx:Dictionary,out:Array,at:float)->void:
	if (ctx.bits as Array).has("doze_jerk") or not _rested(ctx,"doze_jerk"):return
	_try(ctx,"doze_jerk",out,at)

## Whether the sleeper is asleep now, for the stage's idle business: the
## doze resumes once DOZE_AGAIN events have passed since they were woken,
## or at once when the god makes the hall wait.
static func asleep(cast:Array,facts:Dictionary,memory:Dictionary)->String:
	var key:=dozer(cast,facts)
	if key.is_empty():return ""
	var n:=int(memory.get("n",0))
	var woke:=int(memory.get("woke",-1000))
	if int(memory.get("dozed",-1000))>woke:return key
	return key if n-woke>=DOZE_AGAIN else ""

## "Consider it": the hopeful nod, and their shoulders sink politely.
static func _promise(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",ctx.main))
	var rng:RandomNumberGenerator=ctx.rng
	var w:=_m(ctx,who)
	if not w.is_empty() and String(ctx.firm)!=who:
		if (float(w.love)>=0.4 or float(w.dread)>=0.45) and rng.randf()<0.5:
			_beat(out,0.4,who,"nod_too_much",{},"action")
			_beat(out,2.1,who,"deflate_polite",{"dur":1.6},"action")
		else:
			_beat(out,0.4,who,"deflate_polite",{},"action")
			_greet(ctx,out,2.0,who,"bow_small")
	var doubters:Array=_people(ctx,[who]).filter(func(m:Dictionary)->bool:return float(m.pride)>=0.6 and float(m.love)<0.45)
	if not doubters.is_empty() and rng.randf()<0.6:_beat(out,1.0+rng.randf()*0.4,String(_pick(ctx,doubters).key),"eyes_narrow",{"at":who},"reaction")
	var two:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[who]))
	if two.size()>=2 and rng.randf()<0.35:
		_beat(out,1.5,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"reaction")
		_beat(out,1.6,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"reaction")
	_play_bits(ctx,out,1.2)

## Dismissed: a petition turned away (offended, furious) or simply done
## with. They take it in their own way; after a tense audience the room lets
## out its breath.
static func _dismiss(ctx:Dictionary,out:Array)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var who:=String(ctx.event.get("who",ctx.main))
	var reaction:=String(ctx.event.get("reaction","neutral"))
	var w:=_m(ctx,who)
	if not w.is_empty() and String(ctx.firm)!=who:
		if reaction=="furious":
			_beat(out,0.3,who,"stiffen",{},"action")
			_greet(ctx,out,1.2,who,"bow_curt",true)
		elif reaction=="offended":
			_beat(out,0.3,who,"face_fall",{},"action")
			_greet(ctx,out,1.3,who,"bow_small",true)
		else:_greet(ctx,out,0.3,who,"bow_small",true)
	if reaction in ["offended","furious"]:
		var kind_one:Array=_people(ctx,[who]).filter(func(m:Dictionary)->bool:return float(m.empathy)>=0.6)
		if not kind_one.is_empty() and rng.randf()<0.6:_beat(out,1.4,String(_pick(ctx,kind_one).key),"sympathetic_look",{"at":who},"reaction")
	elif rng.randf()<0.5:
		for m:Dictionary in _shuffled(rng,_people(ctx,[who])).slice(0,2):_beat(out,1.0+_lag(ctx,m),String(m.key),"exhale",{},"reaction")
	_play_bits(ctx,out,1.0)

## "Make them wait": the petitioner shifts, clears their throat, tries to
## catch the god's eye; the old one nods off again; a child sits down.
static func _wait(ctx:Dictionary,out:Array)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var who:=String(ctx.event.get("who",ctx.main))
	var w:=_m(ctx,who)
	var fidgets:Array=_shuffled(rng,["shift_weight","clear_throat","smooth_clothes","catch_eye"])
	if not w.is_empty():
		for i in 3:_beat(out,0.6+i*1.3+rng.randf()*0.3,who,String(fidgets[i]),{},"action")
	for m:Dictionary in _shuffled(rng,_people(ctx,[who])).slice(0,2):_beat(out,1.4+rng.randf()*1.6,String(m.key),"shift_weight",{},"reaction")
	# The old one nods off again (or, already asleep, starts to snore).
	var key:=dozer(ctx.cast,ctx.facts)
	if not key.is_empty() and key!=who:
		if _asleep(ctx)==key:_beat(out,2.4,key,"snore",{},"reaction")
		else:_beat(out,2.4,key,"doze_off",{},"reaction")
		ctx["dozed"]=true
	_play_bits(ctx,out,1.8)
	var sleepy:=_quirky(ctx,"sleepy")
	var yawned:=String((ctx.stars as Dictionary).get("quirk_yawn",""))==String(sleepy.get("key","-"))
	if not sleepy.is_empty() and not yawned and rng.randf()<0.7:
		_beat(out,3.2,String(sleepy.key),"doze_off",{},"reaction")
		ctx["quirk_dozed"]=String(sleepy.key)
	for child:Dictionary in _of_kind(ctx,["child"],[who]):
		if rng.randf()<0.4:_beat(out,3.0,String(child.key),"sit_down",{},"reaction");break
	for dog:Dictionary in _of_kind(ctx,["dog"]):
		if rng.randf()<0.5:_beat(out,2.8,String(dog.key),"lie_down",{},"reaction")

## A gift carried in: the bearer heaves it forward and sets it down; taken,
## eyes go to it (hungry eyes if the stores are short and it is food);
## turned away, the bearer has to pick the whole thing up again. The envoy
## shows their own temper in it.
static func _gift(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var rng:RandomNumberGenerator=ctx.rng
	var bearers:Array=_of_kind(ctx,["bearer"])
	if bearers.is_empty():bearers=_of_kind(ctx,["attendant"])
	var bearer:Dictionary=bearers[0] if not bearers.is_empty() else {}
	var envoy:=String(ctx.main)
	var temper:=String(_m(ctx,envoy).get("temper",""))
	if not bearer.is_empty():
		_shot(out,0.0,"two_shot",{"a":envoy,"b":String(bearer.key)})
		_beat(out,0.0,String(bearer.key),"struggle_bundle",{},"anticipation")
		if temper=="haughty":_beat(out,0.7,envoy,"jerk_head",{"at":String(bearer.key)},"anticipation")
		_beat(out,1.2,String(bearer.key),"set_down_bundle",{},"anticipation")
	var accepted:=bool(event.get("accepted",true))
	var food:=String(event.get("resource","")).to_lower()=="food"
	if accepted:
		if envoy!="":
			match temper:
				"haughty":_greet(ctx,out,2.0,envoy,"bow_curt")
				"nervous":_greet(ctx,out,2.0,envoy,"double_bow")
				"greedy":
					_greet(ctx,out,2.0,envoy,"bow_small")
					_beat(out,2.8,envoy,"rub_hands_greedy",{},"action")
				_:_greet(ctx,out,2.0,envoy,"bow_small")
		if food and hungry(ctx.facts):
			var eyes:Array=_shuffled(rng,_people(ctx,[envoy,String(bearer.get("key",""))]).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["envoy","guard","bearer","attendant"]))
			for i in mini(3 if starving(ctx.facts) else 2,eyes.size()):
				_beat(out,2.3+i*0.25,String((eyes[i] as Dictionary).key),"eye_food",{"at":String(bearer.get("key",envoy)),"because":"food_days"},"reaction")
	else:
		if envoy!="":_beat(out,2.0,envoy,"stiffen",{},"action")
		if not bearer.is_empty():
			_beat(out,2.8,String(bearer.key),"grimace",{},"reaction")
			_beat(out,3.3,String(bearer.key),"lift_bundle",{},"reaction")
	_play_bits(ctx,out,1.6)

## Someone arrives. An official walks in by their own feelings (nervous
## ones sometimes by the wrong side); a summoned child stares up and waves;
## someone nobody here knows bows to the wrong person; a gifted child shows
## their gift without meaning to; an envoy shows their temper and their
## company gawks at the hall.
static func _summon(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",ctx.main))
	var w:=_m(ctx,who)
	var rng:RandomNumberGenerator=ctx.rng
	for m:Dictionary in _people(ctx,[who]):
		if rng.randf()<0.7:_beat(out,0.2+_lag(ctx,m),String(m.key),"look_at",{"at":who},"anticipation")
	if w.is_empty():return
	if String(w.kind)=="envoy":
		_envoy_arrives(ctx,out,who)
		return
	var near:=_nearest(ctx,w,["official","hearth_chief","commoner","elder"])
	if not String(w.gifted).is_empty():
		_gifted_arrives(ctx,out,who)
	elif String(w.kind)=="child":
		if _bit_ready(ctx,"child_wave") and _try(ctx,"child_wave",out,1.2):pass
		else:
			_beat(out,1.2,who,"gape",{},"action")
			if not near.is_empty():_beat(out,2.2,String(near.key),"nudge",{"at":who},"reaction")
			_greet(ctx,out,2.6,who,"bow_deep")
	elif String(w.kind)=="commoner":
		_beat(out,1.0,who,"gawk",{},"action")
		_beat(out,1.9,who,"wipe_hands",{},"action")
		if _bit_ready(ctx,"bow_wrong") and _try(ctx,"bow_wrong",out,2.4):pass
		else:_greet(ctx,out,2.6,who,"bow")
	else:
		if float(w.dread)>=0.45 and _bit_ready(ctx,"wrong_door") and _try(ctx,"wrong_door",out,0.0):pass
		elif float(w.dread)>=0.4 and _bit_ready(ctx,"bow_early") and _try(ctx,"bow_early",out,0.6):pass
		else:
			if not near.is_empty():_beat(out,1.4,String(near.key),"make_room",{"at":who},"reaction")
			if float(w.dread)>=0.5:_beat(out,1.8,who,"wring_hands",{},"action")
			elif float(w.love)>=LOVE_HIGH:_beat(out,1.8,who,"beam",{},"action")
			_greet(ctx,out,2.6,who,"bow")
	_play_bits(ctx,out,2.8)

## A gifted child (geniuses.gd, noticed): they do the thing they are gifted
## at, right there in the hall, unasked; the grown-ups notice.
const GIFT_ACTS:={"Logistics":"count_heads","Administration":"line_up","Construction":"study_posts","Extraction":"turn_stone","Survey":"study_roof",
	"Crafting":"work_knot","Food":"eye_stores","Defense":"watch_guards","Knowledge":"watch_god","Care":"tend_hurt"}
static func _gifted_arrives(ctx:Dictionary,out:Array,who:String)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var w:=_m(ctx,who)
	var act:=String(GIFT_ACTS.get(String(w.gifted),"watch_god"))
	_greet(ctx,out,1.0,who,"bow_small")
	_beat(out,2.2,who,act,{"gift":String(w.gifted)},"action")
	var grown:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief","elder"],[who]))
	if grown.size()>=2:
		_beat(out,3.2,String((grown[0] as Dictionary).key),"exchange_look",{"at":String((grown[1] as Dictionary).key)},"reaction")
		_beat(out,3.3,String((grown[1] as Dictionary).key),"exchange_look",{"at":String((grown[0] as Dictionary).key)},"reaction")
	for elder:Dictionary in _of_kind(ctx,["elder"],[who]):
		_beat(out,3.8,String(elder.key),"nod_proud",{"at":who},"reaction");break
	for scribe:Dictionary in _of_kind(ctx,["scribe"]):_beat(out,3.6,String(scribe.key),_writing_act(ctx.facts,scribe),{},"reaction")
	ctx["star"]=who
	_ran(ctx,"gifted")

## An envoy comes in, in their temper; their company looks at our hall.
static func _envoy_arrives(ctx:Dictionary,out:Array,envoy:String)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var e:=_m(ctx,envoy)
	match String(e.temper):
		"haughty":
			_beat(out,1.0,envoy,"sniff_disdain",{},"action")
			_beat(out,2.4,envoy,"brush_sleeve",{},"action")
			_greet(ctx,out,3.2,envoy,"bow_curt")
			ctx["star"]=envoy;_ran(ctx,"envoy_sniff")
		"nervous":
			var dogs:Array=_of_kind(ctx,["dog"])
			if not dogs.is_empty():
				_beat(out,1.0,String((dogs[0] as Dictionary).key),"sniff",{"at":envoy},"action")
				_beat(out,1.4,envoy,"startle",{"at":String((dogs[0] as Dictionary).key)},"action")
				ctx["star"]=envoy;_ran(ctx,"envoy_startle")
			_greet(ctx,out,2.4,envoy,"double_bow")
		"greedy":
			_beat(out,1.0,envoy,"appraise",{},"action")
			_greet(ctx,out,3.0,envoy,"bow_small")
			ctx["star"]=envoy;_ran(ctx,"envoy_appraise")
		_:_greet(ctx,out,1.6,envoy,"bow")
	if _bit_ready(ctx,"company_gawk") and _try(ctx,"company_gawk",out,1.2):pass
	if _bit_ready(ctx,"stare_down") and _try(ctx,"stare_down",out,2.4):pass

## Someone goes. The stage walks them out in the engine's style; the room
## shows what it made of it. Pleased, they back out bowing (and now and then
## into the door post); offended, they storm off (and now and then have to
## come back for what they left). Led away or put to death: no comedy.
static func _exit(ctx:Dictionary,out:Array)->void:
	var who:=String(ctx.event.get("who",ctx.main))
	var style:=String(ctx.event.get("style","bow"))
	var reaction:=String(ctx.event.get("reaction",""))
	var room:Array=_people(ctx,[who])
	var rng:RandomNumberGenerator=ctx.rng
	match style:
		"fall":
			_death(ctx,out,who)
		"led":
			_beat(out,0.0,"room","hush",{"dur":3.0},"anticipation")
			for m:Dictionary in room:
				if float(m.love)>=0.5 or float(m.empathy)>=0.6:_beat(out,0.6+_lag(ctx,m),String(m.key),"watch_go",{"at":who},"reaction")
				else:_beat(out,0.6+_lag(ctx,m),String(m.key),"look_away",{},"reaction")
		"storm","flee":
			_beat(out,0.0,who,"storm_off",{},"action")
			# Now and then they have to come back for what they left: their
			# staff or bowl, or the bearer still standing there with the bundle.
			var forgot:=_bit_ready(ctx,"forgot_thing") and _try(ctx,"forgot_thing",out,2.4)
			var left_behind:=String(_forgotten(ctx).get("follower","")) if forgot else ""
			for att:Dictionary in _of_kind(ctx,["guard","bearer","attendant"]):
				if String(att.key)==left_behind:_beat(out,0.6,left_behind,"look_at",{"at":String(ctx.main)},"reaction")
				else:_beat(out,0.4+_lag(ctx,att),String(att.key),"hurry_after",{"at":who},"action")
			if _rested(ctx,"gasp_pretend") and rng.randf()<0.4:_gasp(ctx,out,0.5,[who],true)
			else:
				# A few gasp; the rest look at one another.
				var few:Array=_shuffled(rng,_people(ctx,[who]).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["guard","bearer","attendant"])).slice(0,rng.randi_range(2,3))
				for m:Dictionary in few:_beat(out,0.5+rng.randf()*0.2,String(m.key),["gasp","hand_to_mouth","eyes_narrow"][rng.randi_range(0,2)],{"at":who},"reaction")
			if not forgot:
				var two:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[who]))
				if two.size()>=2:
					_beat(out,1.9,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"hold")
					_beat(out,2.0,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"hold")
		_:
			if not reaction in ["awe","reverence","dread","fear"] and not presentation(ctx.facts,_m(ctx,who)).is_empty():_greet(ctx,out,0.2,who,"bow_small",true)
			elif reaction in ["pleased","delighted"] and _bit_ready(ctx,"bump_post") and _try(ctx,"bump_post",out,0.2):pass
			elif reaction in ["pleased","delighted"]:_beat(out,0.2,who,"back_out_bowing",{"walk":"backward"},"action")
			for m:Dictionary in room:
				if rng.randf()<0.4:_beat(out,0.8+_lag(ctx,m),String(m.key),"nod",{},"reaction")
			_play_bits(ctx,out,1.2)

## Our god's fury on a foreign envoy: their temper decides how they take it
## (the engine's response), and then the hall is silent.
static func _terrify_envoy(ctx:Dictionary,out:Array)->void:
	var envoy:=String(ctx.main)
	var response:=String(ctx.event.get("response",""))
	var temper:=String(_m(ctx,envoy).get("temper",""))
	_beat(out,0.0,"room","hush",{"dur":3.4},"anticipation")
	_shot(out,0.0,"push_in",{"target":envoy,"close":true})
	_shot(out,0.55,"shake",{"strength":0.3})
	if response in ["defy","defiant"]:
		_beat(out,0.55,envoy,"stand_firm",{},"action")
		_beat(out,1.3,envoy,"hold_gaze",{},"action")
		if temper=="haughty":_beat(out,2.4,envoy,"brush_sleeve",{},"hold")
	else:
		_beat(out,0.55,envoy,"flinch",{},"action")
		_beat(out,0.9,envoy,"step_back",{},"action")
		# The haughty one recovers their dignity, as if nothing happened.
		if temper=="haughty":_beat(out,2.2,envoy,"pretend_calm",{},"hold")
		elif temper=="nervous":_beat(out,1.6,envoy,"knees_knock",{},"action")
	# Their bored guard, suddenly very much awake.
	var snapped:=_bit_ready(ctx,"guard_snap") and _try(ctx,"guard_snap",out,0.8)
	for att:Dictionary in _of_kind(ctx,["attendant","bearer","guard"]):
		if String(att.kind)=="guard" and snapped:continue
		_beat(out,0.8+_lag(ctx,att),String(att.key),"step_back",{},"reaction")
	if not _asleep(ctx).is_empty():_wake(ctx,out,0.8)
	# Our own: the proud enjoy it.
	for m:Dictionary in _of_kind(ctx,["official","hearth_chief"]):
		if float(m.pride)>0.65 and (ctx.rng as RandomNumberGenerator).randf()<0.6:_beat(out,1.4+_lag(ctx,m),String(m.key),"smirk",{"at":envoy},"reaction")
	_play_bits(ctx,out,0.8,1)
	_beat(out,2.6,"room","hush",{"dur":1.2},"hold")
	if _rested(ctx,"dead_silence") and _can(ctx,"dead_silence") and _try(ctx,"dead_silence",out,3.0):pass
	_shot(out,3.4,"wide")

static func _insulted(ctx:Dictionary,out:Array)->void:
	var envoy:=String(ctx.main)
	if envoy!="":_beat(out,0.4,envoy,"stiffen",{},"action")
	if String(_m(ctx,envoy).get("temper",""))=="haughty":_beat(out,1.2,envoy,"sniff_disdain",{},"action")
	if _bit_ready(ctx,"guard_snap") and _try(ctx,"guard_snap",out,0.9):pass
	var two:Array=_shuffled(ctx.rng,_of_kind(ctx,["official","hearth_chief"]))
	if two.size()>=2:
		_beat(out,1.0,String((two[0] as Dictionary).key),"exchange_look",{"at":String((two[1] as Dictionary).key)},"reaction")
		_beat(out,1.1,String((two[1] as Dictionary).key),"exchange_look",{"at":String((two[0] as Dictionary).key)},"reaction")
	_play_bits(ctx,out,0.8)

# =============================================================================
# The bits
# =============================================================================

## Who is asleep on their feet just now: the dozer, unless woken lately.
static func _asleep(ctx:Dictionary)->String:
	if (ctx.bits as Array).has("doze_jerk"):return ""
	return asleep(ctx.cast,ctx.facts,ctx.memory)

## Can the room play this bit now (the people it needs are here, the facts
## allow it)?
static func _can(ctx:Dictionary,bit:String)->bool:
	# Routine etiquette can be restrained without taking worship, terror,
	# defiance or an execution away from the engine's explicit event.
	if String(ctx.kind) in ["summon","gift","decree","promise","dismiss","exit","line","wait","god_speaks"] and not String(ctx.event.get("reaction","")) in ["awe","reverence","dread","fear"]:
		if bit in ["eager_bow","double_bow","over_thank","bow_early","bow_wrong","child_copies","bump_post"]:
			var person:=_m(ctx,String(ctx.event.get("who",ctx.main))) if bit in ["double_bow","over_thank","bow_early","bow_wrong","bump_post"] else {}
			if routine_act(ctx.facts,person,"bow") in ["nod","bow_small"]:return false
	var event:Dictionary=ctx.event
	var target:=String(event.get("target",""))
	var who:=String(event.get("who",ctx.main))
	var season:=String(ctx.facts.get("season","")).to_lower()
	match bit:
		"doze_jerk":return not _asleep(ctx).is_empty()
		"drop_bowl":return not _bowl_holder(ctx).is_empty()
		"late_lift":return not _of_kind(ctx,["child","commoner"],[String(ctx.main)]).is_empty()
		"goat_ignores":return not _of_kind(ctx,["goat"]).is_empty()
		"goat_nibble":return not _of_kind(ctx,["goat"]).is_empty() and not _of_kind(ctx,["official","hearth_chief","elder"]).is_empty()
		"child_hides":return not _of_kind(ctx,["child"],[String(ctx.main)]).is_empty() and String(event.get("action",event.get("verb","")))!="bless"
		"dog_whimper":return not _of_kind(ctx,["dog"]).is_empty()
		"faint":return String(event.get("action",""))=="terrify" and not _fainter(ctx).is_empty()
		"gasp_pretend":return _people(ctx,[target]).size()>=3 and (String(event.get("response",""))=="defy" or String(ctx.kind) in ["envoy_insulted","exit"] or String(event.get("verb","")) in ["kill","maim"] or String(event.get("obedience",""))=="refuse")
		"side_eye_pair":return _of_kind(ctx,["official","hearth_chief"],[target,String(event.get("actor",""))]).size()>=2 and _odd(ctx)
		"stifle_elbow":return _people(ctx,[String(ctx.main)]).size()>=2 and _odd(ctx)
		"eager_bow":return not _eager(ctx).is_empty() and _favourable(ctx)
		"bored_guard":return not _of_kind(ctx,["guard"]).is_empty() and (String(ctx.kind)!="line" or String(event.get("text","")).length()>=90)
		"guard_snap":return not _of_kind(ctx,["guard"]).is_empty()
		"dog_sniff_gift":return not _of_kind(ctx,["dog"]).is_empty()
		"double_take","count_fingers":return not _amount(ctx).is_empty() and not _people(ctx,[String(event.get("who","")),String(ctx.main)]).is_empty()
		"child_copies":return not _of_kind(ctx,["child"],[String(ctx.main)]).is_empty() and not _bower(ctx).is_empty()
		"double_bow","over_thank":
			var w:=_m(ctx,who if String(ctx.kind)!="divine" else target)
			return not w.is_empty() and String(ctx.firm)!=String(w.key) and (bit=="double_bow" or float(w.love)>=0.4 or float(w.dread)>=0.4 or String(event.get("response",""))=="relief")
		"bow_early":
			var w:=_m(ctx,who)
			return not w.is_empty() and (float(w.dread)>=0.4 or float(w.love)>=0.55)
		"cough_fit":return not sickness(ctx.facts).is_empty() and _people(ctx).size()>=2
		"smirk_rival":return not _rival(ctx).is_empty()
		"dead_silence":return not _silence_breaker(ctx).is_empty()
		"winter_stamp":return season=="winter" and not _people(ctx,[String(ctx.main),who]).is_empty()
		"fly_elder":return season=="summer" and not _of_kind(ctx,["elder"],[String(ctx.main),who]).is_empty() and not _nearest(ctx,_of_kind(ctx,["elder"],[String(ctx.main),who])[0],["official","hearth_chief","commoner","child"],[String(ctx.main)]).is_empty()
		"scribe_cramp":
			var scribes:=_of_kind(ctx,["scribe"])
			return not scribes.is_empty() and _writing_act(ctx.facts,scribes[0])=="scribble"
		"bump_post":return not _m(ctx,who).is_empty() and String(ctx.firm)!=who
		"forgot_thing":return not _forgotten(ctx).is_empty()
		"wrong_door":return not _m(ctx,who).is_empty() and not _of_kind(ctx,["official","hearth_chief","door_guard"],[who]).is_empty()
		"bow_wrong":return not _wrong_one(ctx).is_empty()
		"child_wave":return not _m(ctx,who).is_empty()
		"stare_down":return not _of_kind(ctx,["guard"]).is_empty() and not _staring_official(ctx).is_empty()
		"company_gawk":return not _of_kind(ctx,["guard","bearer","attendant"]).is_empty()
		"quirk_count":return not _quirky(ctx,"pedant").is_empty() and not _amount(ctx).is_empty()
		"quirk_flatter":
			var f:=_quirky(ctx,"flatterer")
			return not f.is_empty() and String(ctx.gravity)!="grave"
		"quirk_yawn":return not _quirky(ctx,"sleepy").is_empty() and (String(ctx.kind)!="line" or String(event.get("text","")).length()>=50)
		"quirk_jealous":return not _quirky(ctx,"jealous").is_empty() and _favourable(ctx) and not _favoured(ctx).is_empty()
		"quirk_agree":return not _quirky(ctx,"yes_man").is_empty()
	return false

## Someone present with this comic way who is not being dealt with now.
static func _quirky(ctx:Dictionary,quirk:String)->Dictionary:
	var event:Dictionary=ctx.event
	var skip:=[String(event.get("target","")),String(event.get("who","")),String(event.get("actor","")),String(ctx.firm),String(ctx.gone),String(ctx.main)]
	for m:Dictionary in ctx.cast:
		if String(m.get("quirk",""))==quirk and not String(m.key) in skip:return m
	return {}

## Whom this moment favours (the one blessed, granted or raised).
static func _favoured(ctx:Dictionary)->String:
	var event:Dictionary=ctx.event
	match String(ctx.kind):
		"divine":return String(event.get("target",""))
		"decree":return String(event.get("who",ctx.main)) if not bool(event.get("issued",false)) else ""
	return ""

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
		"god_speaks":return String(event.get("tone","")) in ["favor","favour"]
		"summon":return true
	return false

## The over-eager: a hearth chief (or anyone low in pride and high in love or
## dread) who is not the one being dealt with.
static func _eager(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	var skip:=[String(event.get("target","")),String(event.get("who","")),String(event.get("actor","")),String(ctx.firm)]
	var best:={};var score:=0.0
	for m:Dictionary in _people(ctx,skip):
		if String(m.kind) in ["envoy","guard","bearer","attendant","child","scribe","door_guard"] or String(m.role)=="main":continue
		var s:=(0.4 if String(m.kind)=="hearth_chief" else 0.0)+maxf(float(m.love),float(m.dread))-float(m.pride)*0.6
		if s>score and s>=0.35:score=s;best=m
	return best

static func _bowl_holder(ctx:Dictionary)->Dictionary:
	var skip:=[String(ctx.main),String(ctx.event.get("target","")),String(ctx.event.get("actor",""))]
	for m:Dictionary in _people(ctx,skip):
		if String(m.stance)=="bowl":return m
	for m:Dictionary in _of_kind(ctx,["commoner"],skip):return m
	return {}

static func _fainter(ctx:Dictionary)->Dictionary:
	var target:=String(ctx.event.get("target",""))
	for m:Dictionary in _jumpiest(_people(ctx,[target,String(ctx.main)])):
		if float(m.dread)>=0.45 and float(m.courage)<=0.4 and not String(m.kind) in ["child","envoy","guard","scribe"]:
			if not _nearest(ctx,m,["official","hearth_chief","commoner","elder"],[target]).is_empty():return m
	return {}

## A number to do a double take at: said in a line, the amount given, or
## what a decree costs.
static func _amount(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	var terms:Dictionary=event.get("terms",{}) if event.get("terms") is Dictionary else {}
	var cost:Dictionary=event.get("cost",{}) if event.get("cost") is Dictionary else {}
	if _num(terms.get("amount",null)) and float(terms.amount)>=2.0:return {"value":roundi(float(terms.amount)),"at":1.2,"from":"event.amount"}
	if _num(cost.get("amount",null)) and float(cost.amount)>=2.0:return {"value":roundi(float(cost.amount)),"at":1.3,"from":"event.cost.amount"}
	if _num(event.get("amount",null)) and float(event.amount)>=2.0:return {"value":roundi(float(event.amount)),"at":1.8,"from":"event.amount"}
	if String(ctx.kind)=="line":
		var said:=number_in(String(event.get("text","")))
		if not said.is_empty():return {"value":int(said.value),"at":0.15+float(said.at)*0.025+0.25,"from":"event.text"}
	return {}

## Someone bowing in this moment, whom a child may copy.
static func _bower(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	if String(ctx.kind)=="decree" and bool(event.get("accepted",String(event.get("reaction","")) in ["delighted","pleased"])):return _m(ctx,String(event.get("who",ctx.main)))
	if String(ctx.kind) in ["dismiss","summon"]:
		var w:=_m(ctx,String(event.get("who",ctx.main)))
		return w if not w.is_empty() and String(w.kind)!="child" else {}
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
		if String(m.get("quirk",""))=="jealous":return m
	for m:Dictionary in _of_kind(ctx,["official","hearth_chief"],[target]):
		if float(m.pride)>=0.68 and float(m.love)<0.45:return m
	return {}

## In a terrified silence, the one small noise: a hungry stomach (only when
## the stores are short), a cough fought down (only in a sickness), the goat,
## a creaking floor, a swallow. [who, act].
static func _silence_breaker(ctx:Dictionary)->Array:
	var event:Dictionary=ctx.event
	var skip:=[String(event.get("target","")),String(ctx.main),String(event.get("actor","")),String(ctx.firm),String(ctx.get("fainted",""))]
	var room:Array=_people(ctx,skip).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["envoy","guard","bearer","attendant"])
	var options:Array=[]
	if not room.is_empty():
		var m:Dictionary=room[(ctx.rng as RandomNumberGenerator).randi_range(0,room.size()-1)]
		if hungry(ctx.facts):options.append([String(m.key),"stomach_growl"])
		if not sickness(ctx.facts).is_empty():options.append([String(m.key),"stifle_cough"])
		options.append([String(m.key),"floor_creak"])
		options.append([String(m.key),"swallow_loud"])
	for goat:Dictionary in _of_kind(ctx,["goat"]):options.append([String(goat.key),"bleat"])
	if options.is_empty():return []
	return options[(ctx.rng as RandomNumberGenerator).randi_range(0,options.size()-1)]

## What a storming visitor left behind: their staff or bowl (set down at
## their mark when they went), or, for an envoy, the bearer still holding
## the refused bundle. {thing, follower}.
static func _forgotten(ctx:Dictionary)->Dictionary:
	var who:=String(ctx.event.get("who",ctx.main))
	var w:=_m(ctx,who)
	if w.is_empty():return {}
	if String(w.kind)=="envoy":
		var gift:Dictionary=ctx.facts.get("gift",{}) if ctx.facts.get("gift") is Dictionary else {}
		var bearers:Array=_of_kind(ctx,["bearer"])
		var refused:=bool(ctx.facts.get("gift_refused",false)) or bool(ctx.memory.get("gift_refused",false))
		if not gift.is_empty() and refused and not bearers.is_empty():return {"thing":"bearer","follower":String((bearers[0] as Dictionary).key)}
		return {}
	if String(w.stance) in ["staff","bowl"]:return {"thing":String(w.stance)}
	return {}

## The official a stranger mistakes for the god: the grandest-looking one.
static func _wrong_one(ctx:Dictionary)->Dictionary:
	var who:=String(ctx.event.get("who",ctx.main))
	var w:=_m(ctx,who)
	if w.is_empty() or String(w.kind)!="commoner":return {}
	var best:={}
	for m:Dictionary in _of_kind(ctx,["official","hearth_chief"],[who]):
		if best.is_empty() or float(m.pride)>float(best.pride):best=m
	return best

## The official the envoy's guard sizes up: the proudest who is not afraid.
static func _staring_official(ctx:Dictionary)->Dictionary:
	var best:={}
	for m:Dictionary in _of_kind(ctx,["official","hearth_chief","door_guard"]):
		if float(m.dread)>=0.5:continue
		if best.is_empty() or float(m.pride)+float(m.courage)>float(best.pride)+float(best.courage):best=m
	return best

## Plays one bit. False if it could not be cast after all.
static func _bit(ctx:Dictionary,bit:String,out:Array,at:float)->bool:
	var rng:RandomNumberGenerator=ctx.rng
	var event:Dictionary=ctx.event
	var target:=String(event.get("target",""))
	var who:=String(event.get("who",ctx.main))
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
			var child:Dictionary=_pick(ctx,_of_kind(ctx,["child"],[String(ctx.main)]))
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
			ctx["star"]=String(dog.key)
		"faint":
			var m:=_fainter(ctx)
			var catcher:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			_beat(out,at+0.4,String(m.key),"faint",{},"reaction")
			_beat(out,at+0.55,String(catcher.key),"half_catch",{"at":String(m.key)},"reaction")
			_beat(out,at+1.6,String(catcher.key),"grimace",{},"hold")
			_shot(out,at+0.5,"reaction",{"target":String(m.key)})
			ctx["star"]=String(m.key);ctx["fainted"]=String(m.key)
		"gasp_pretend":
			_gasp(ctx,out,at,[target,String(ctx.firm)],true)
			return false   # _gasp records itself (with its star)
		"side_eye_pair":
			var two:Array=_shuffled(rng,_of_kind(ctx,["official","hearth_chief"],[target,String(event.get("actor",""))]))
			var a:Dictionary=two[0];var b:Dictionary=two[1]
			_beat(out,at,String(a.key),"side_eye",{"at":String(b.key)},"reaction")
			_beat(out,at+0.35,String(b.key),"side_eye",{"at":String(a.key)},"reaction")
			_beat(out,at+1.2,String(a.key),"lips_pressed",{},"hold")
			ctx["star"]=String(a.key)
		"stifle_elbow":
			# Someone low in pride finds it funny; their neighbour does not.
			var room:Array=_people(ctx,busy+[String(ctx.main)]).filter(func(x:Dictionary)->bool:return not String(x.kind) in ["envoy","guard","bearer","attendant"])
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
			ctx["star"]=String(m.key);ctx["number"]=int(amount.value);ctx["number_from"]=String(amount.get("from",""))
		"child_copies":
			var child:Dictionary=_pick(ctx,_of_kind(ctx,["child"],[String(ctx.main)]))
			var model:=_bower(ctx)
			var adult:=_nearest(ctx,child,["elder","commoner","official","hearth_chief"],busy+[String(model.key)])
			_beat(out,at+0.5,String(child.key),"copy",{"at":String(model.key)},"reaction")
			if not adult.is_empty():_beat(out,at+1.6,String(adult.key),"shush",{"at":String(child.key)},"reaction")
			ctx["star"]=String(child.key)
		"double_bow":
			_beat(out,at,who,"double_bow",{},"action")
			ctx["star"]=who
		"over_thank":
			# They cannot stop thanking: bow, thanks, bow, thanks, while the
			# hall waits for them to finish.
			var thanker:=target if String(ctx.kind)=="divine" else who
			_beat(out,at,thanker,"over_thank",{},"action")
			var near:=_nearest(ctx,_m(ctx,thanker),["official","hearth_chief","commoner","elder"],busy+[thanker])
			if not near.is_empty():_beat(out,at+2.6,String(near.key),"shift_weight",{},"reaction")
			ctx["star"]=thanker
		"bow_early":
			_beat(out,at,who,"bow_early",{},"action")
			_beat(out,at+1.7,who,"bow",{},"action")
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
		"dead_silence":
			var pair:=_silence_breaker(ctx)
			if pair.is_empty():return false
			_beat(out,at,String(pair[0]),String(pair[1]),{},"hold")
			# Every head turns to the noise; nobody says a word.
			var lookers:Array=_shuffled(rng,_people(ctx,busy+[String(pair[0])])).slice(0,2)
			for i in lookers.size():_beat(out,at+0.3+i*0.12,String((lookers[i] as Dictionary).key),"look_at",{"at":String(pair[0])},"hold")
			if not String(pair[0]) in ["goat"]:_beat(out,at+0.9,String(pair[0]),"mortified",{},"hold")
			ctx["star"]=String(pair[0])
		"winter_stamp":
			var m:=_pick(ctx,_people(ctx,busy+[String(ctx.main),who]))
			_beat(out,at,String(m.key),"stamp_feet",{"because":"season"},"reaction")
			_beat(out,at+0.6,String(m.key),"breath",{"because":"season"},"reaction")
			var near:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty():_beat(out,at+0.9,String(near.key),"side_eye",{"at":String(m.key)},"reaction")
			ctx["star"]=String(m.key)
		"fly_elder":
			var elder:Dictionary=_of_kind(ctx,["elder"],[String(ctx.main),who])[0]
			var near:=_nearest(ctx,elder,["official","hearth_chief","commoner","child"],[String(ctx.main)]+busy)
			_beat(out,at,String(elder.key),"swat_fly",{"because":"season"},"reaction")
			_beat(out,at+0.9,String(elder.key),"swat_fly",{"because":"season"},"reaction")
			_beat(out,at+1.8,String(elder.key),"swat_miss",{"at":String(near.key),"because":"season"},"reaction")
			_beat(out,at+2.2,String(near.key),"grimace",{},"reaction")
			ctx["star"]=String(elder.key);ctx["struck"]=String(near.key)
		"scribe_cramp":
			var scribe:Dictionary=_of_kind(ctx,["scribe"])[0]
			_beat(out,at,String(scribe.key),"scribble",{},"reaction")
			_beat(out,at+1.8,String(scribe.key),"shake_hand",{},"reaction")
			_beat(out,at+2.6,String(scribe.key),"scratch_out",{},"hold")
			ctx["star"]=String(scribe.key)
		"bump_post":
			# Pleased, they back out bowing, straight into the door post,
			# and bow to the post too, to be safe.
			_beat(out,at,who,"back_out_bowing",{"walk":"backward"},"action")
			_beat(out,at+2.4,who,"bump_post",{"at":"door"},"action")
			if rng.randf()<0.5:_beat(out,at+3.0,who,"bow_to_post",{},"action")
			ctx["star"]=who
		"forgot_thing":
			var left:=_forgotten(ctx)
			var thing:=String(left.thing)
			_beat(out,at,who,"stop_short",{},"button")
			if thing=="bearer":
				_beat(out,at+0.6,who,"come_back_for",{"at":String(left.follower)},"button")
				_beat(out,at+1.6,who,"jerk_head",{"at":String(left.follower)},"button")
			else:
				_beat(out,at+0.6,who,"come_back",{"thing":thing},"button")
				_beat(out,at+1.8,who,"snatch_up",{"thing":thing},"button")
			_beat(out,at+2.4,who,"storm_off",{},"button")
			if thing=="bearer":_beat(out,at+2.6,String(left.follower),"lift_bundle",{},"button")
			ctx["star"]=who
		"wrong_door":
			var pointer:Dictionary=_pick(ctx,_of_kind(ctx,["official","hearth_chief","door_guard"],[who]))
			_beat(out,at,who,"enter_wrong",{"from":"wrong_side"},"anticipation")
			_beat(out,at+1.5,String(pointer.key),"point",{"at":who},"anticipation")
			_beat(out,at+2.2,who,"hurry_round",{},"action")
			_greet(ctx,out,at+3.4,who,"bow")
			ctx["star"]=who;ctx["other"]=String(pointer.key)
		"bow_wrong":
			var wrong:=_wrong_one(ctx)
			_beat(out,at,who,"bow_wrong",{"at":String(wrong.key)},"action")
			_beat(out,at+1.4,String(wrong.key),"point_up",{},"reaction")
			_beat(out,at+2.2,who,"mortified",{},"action")
			_beat(out,at+2.8,who,"bow",{},"action")
			_shot(out,at+1.2,"two_shot",{"a":who,"b":String(wrong.key)})
			ctx["star"]=who;ctx["other"]=String(wrong.key)
		"child_wave":
			_beat(out,at,who,"gape",{},"action")
			_beat(out,at+1.2,who,"wave",{},"action")
			var near:=_nearest(ctx,_m(ctx,who),["elder","commoner","official","hearth_chief"],busy+[who])
			if not near.is_empty():
				_beat(out,at+1.9,String(near.key),"hand_to_mouth",{},"reaction")
				_beat(out,at+2.4,String(near.key),"nudge",{"at":who},"reaction")
			_greet(ctx,out,at+2.9,who,"bow_deep")
			ctx["star"]=who
		"stare_down":
			# Their guard sizes up our proudest; one of them blinks first.
			var guard:Dictionary=_of_kind(ctx,["guard"])[0]
			var ours:=_staring_official(ctx)
			_beat(out,at,String(guard.key),"stare_down",{"at":String(ours.key)},"reaction")
			_beat(out,at+0.4,String(ours.key),"stare_down",{"at":String(guard.key)},"reaction")
			_shot(out,at+0.3,"two_shot",{"a":String(guard.key),"b":String(ours.key)})
			var loser:=String(guard.key) if float(ours.pride)+float(ours.courage)>=1.1 else String(ours.key)
			_beat(out,at+2.4,loser,"blink_first",{},"hold")
			ctx["star"]=String(ours.key) if loser==String(guard.key) else String(guard.key);ctx["other"]=loser
		"quirk_count":
			# The pedant counts it off, lifts a finger to correct someone, and
			# thinks better of it.
			var m:=_quirky(ctx,"pedant")
			var amount:=_amount(ctx)
			_beat(out,float(amount.at)+0.3,String(m.key),"count_fingers",{"number":int(amount.value)},"reaction")
			_beat(out,float(amount.at)+2.0,String(m.key),"raise_finger",{},"reaction")
			var near:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty():_beat(out,float(amount.at)+2.5,String(near.key),"side_eye",{"at":String(m.key)},"reaction")
			_beat(out,float(amount.at)+3.0,String(m.key),"lower_finger",{},"hold")
			ctx["star"]=String(m.key);ctx["number"]=int(amount.value);ctx["number_from"]=String(amount.get("from",""))
		"quirk_flatter":
			# The flatterer agrees with the god harder than anyone; in wrath on
			# another, they nod along as if they had said it themselves.
			var m:=_quirky(ctx,"flatterer")
			var wrath:=String(ctx.gravity)=="tense"
			_beat(out,at,String(m.key),"nod_along" if wrath else "nod_too_much",{},"reaction")
			if not wrath:_beat(out,at+1.2,String(m.key),"soft_clap",{},"reaction")
			var near:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty():_beat(out,at+1.6,String(near.key),"side_eye",{"at":String(m.key)},"reaction")
			ctx["star"]=String(m.key)
		"quirk_yawn":
			var m:=_quirky(ctx,"sleepy")
			_beat(out,at,String(m.key),"yawn",{},"reaction")
			_beat(out,at+1.5,String(m.key),"snap_alert",{},"reaction")
			var near:=_nearest(ctx,m,["official","hearth_chief","commoner","elder"],busy)
			if not near.is_empty():_beat(out,at+1.0,String(near.key),"elbow",{"at":String(m.key)},"reaction")
			ctx["star"]=String(m.key)
		"quirk_jealous":
			# The jealous one looks sideways at the favoured and edges a step
			# nearer the front.
			var m:=_quirky(ctx,"jealous")
			var whom:=_favoured(ctx)
			if String(ctx.get("envier",""))!=String(m.key):_beat(out,at,String(m.key),"side_eye",{"at":whom},"reaction")
			_beat(out,at+0.9,String(m.key),"edge_forward",{},"reaction")
			_beat(out,at+1.8,String(m.key),"smooth_clothes",{},"hold")
			ctx["star"]=String(m.key);ctx["other"]=whom
		"quirk_agree":
			# The one who agrees with everyone: a nod for the last speaker, a
			# nod for this one, a look round to see what the others think.
			var m:=_quirky(ctx,"yes_man")
			var now:=String(event.get("who","")) if String(ctx.kind)=="line" else ""
			var before:=String(ctx.memory.get("last_speaker",""))
			if not now.is_empty() and before!="" and before!=now and not _m(ctx,before).is_empty() and before!=String(m.key):
				_beat(out,at,String(m.key),"look_at",{"at":before},"reaction")
				_beat(out,at+0.4,String(m.key),"nod",{},"reaction")
				_beat(out,at+1.2,String(m.key),"look_at",{"at":now},"reaction")
				_beat(out,at+1.6,String(m.key),"nod_too_much",{},"reaction")
				ctx["other"]=now
			else:
				_beat(out,at,String(m.key),"nod",{},"reaction")
				_beat(out,at+0.8,String(m.key),"check_room",{},"reaction")
				_beat(out,at+1.6,String(m.key),"nod_too_much",{},"reaction")
			ctx["star"]=String(m.key)
		"company_gawk":
			var company:Array=_of_kind(ctx,["guard","bearer","attendant"])
			for i in company.size():_beat(out,at+i*0.3,String((company[i] as Dictionary).key),"gawk",{},"reaction")
			if company.size()>=2:_beat(out,at+1.4,String((company[1] as Dictionary).key),"whisper",{"at":String((company[0] as Dictionary).key)},"reaction")
			ctx["star"]=String((company[0] as Dictionary).key)
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
	var season:=String(ctx.facts.get("season","")).to_lower()
	for beat:Dictionary in out:
		var who:=String(beat.who)
		var act:=String(beat.act)
		if not who in ["camera","room","exec"] and not (ctx.by as Dictionary).has(who):continue
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
		if season!="winter" and act in WINTER_ACTS:continue
		if season!="summer" and act in SUMMER_ACTS:continue
		kept.append(beat)
	return kept

# =============================================================================
# Executions: the engine has put someone to death; how the hall sees it
# (court_executions.gd chose the method; court_exec_stage.gd plays the "exec"
# beats). Each selected method has its own tone and timed room reactions.
# Gore "mild": the blow lands off screen (the camera on
# the room's faces), no blood and no parts. A child, or gore "off", never
# comes here: the stage keeps the old sober kneel and sink.

## event: {kind: "execution", method, victim ("main"), ex (who carries it out,
## "" for the director to choose), style ("full"/"mild"), name, caption}.
static func _execution(ctx:Dictionary,out:Array)->void:
	var event:Dictionary=ctx.event
	var method:=String(event.get("method","club"))
	if not Executions.is_staged(method):return
	var victim:=String(event.get("victim",ctx.main))
	var style:=String(event.get("style","full"))
	var roles:=_exec_roles(ctx,victim,String(event.get("ex","")))
	var length:=9.5
	var plan:=_exec_plan_of(method)
	if not plan.is_empty():
		length=_exec_planned(ctx,out,victim,roles,method,plan)
		_exec(out,length-0.6,"caption",{"text":String(event.get("caption",""))})
		_exec(out,length,"end",{})
		if style=="mild":_exec_mild(out,ctx,victim,roles)
		return
	match method:
		"club":length=_exec_club(ctx,out,victim,roles)
		"behead":length=_exec_behead(ctx,out,victim,roles)
		"dogs":length=_exec_dogs(ctx,out,victim,roles)
		"fire":length=_exec_fire(ctx,out,victim,roles)
		"spears":length=_exec_spears(ctx,out,victim,roles)
		"stoning":length=_exec_stoning(ctx,out,victim,roles)
		"boulder":length=_exec_boulder(ctx,out,victim,roles)
		"boil":length=_exec_boil(ctx,out,victim,roles)
		"arrows":length=_exec_arrows(ctx,out,victim,roles)
		"stake":length=_exec_stake(ctx,out,victim,roles)
		_:length=_exec_club(ctx,out,victim,roles)
	# The caption names the method; then it is over.
	_exec(out,length-1.0,"caption",{"text":String(event.get("caption",""))})
	_exec(out,length,"end",{})
	if style=="mild":_exec_mild(out,ctx,victim,roles)

## Who does what: the one who carries it out (the engine's actor, else the
## boldest of our people), the cook (by the fire), the front row.
static func execution_roles(event:Dictionary,cast:Array,facts:Dictionary)->Dictionary:
	var ctx:=_context(event,normal_cast(cast,facts),normal_facts(facts),0,{})
	return _exec_roles(ctx,String(event.get("victim","main")),String(event.get("ex","")))

static func _exec_can_reach(ctx:Dictionary,role:String,key:String)->bool:
	var choices:Dictionary=ctx.event.get("reachable_roles",{})
	return not choices.has(role) or key in choices[role]

static func _exec_roles(ctx:Dictionary,victim:String,ex_in:String)->Dictionary:
	var ex:=ex_in
	if ex=="" or ex==victim or _m(ctx,ex).is_empty():
		var bold:Array=_people(ctx,[victim]).filter(func(m:Dictionary)->bool:return String(m.kind) in ["official","hearth_chief","guard","commoner"] and _exec_can_reach(ctx,"executioner",String(m.key)))
		bold.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.courage)>float(b.courage) if not is_equal_approx(float(a.courage),float(b.courage)) else int(a.index)<int(b.index))
		ex=String((bold[0] as Dictionary).key) if not bold.is_empty() else ""
	var cook:Array=_of_kind(ctx,["commoner","elder"],[victim,ex]).filter(func(m:Dictionary)->bool:return _exec_can_reach(ctx,"cook",String(m.key)))
	if cook.is_empty():cook=_people(ctx,[victim,ex]).filter(func(m:Dictionary)->bool:return _exec_can_reach(ctx,"cook",String(m.key)))
	var front:Array=_people(ctx,[victim,ex]).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["child","scribe"])
	var v:=_m(ctx,victim)
	front.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return absf(_where(a)-_where(v))<absf(_where(b)-_where(v)))
	return {"ex":ex,"cook":String((cook[0] as Dictionary).key) if not cook.is_empty() else "","front":front.slice(0,2).map(func(m:Dictionary)->String:return String(m.key))}

static func _exec(out:Array,t:float,op:String,args:Dictionary={})->void:
	_beat(out,t,"exec",op,args,"action")

static func _snd(out:Array,t:float,name:String,gain:=0.9,glyph:="")->void:
	_beat(out,t,"exec","noise",{"sound":name,"gain":gain,"glyph":glyph},"action")

## Authored support performances must finish before the room can recruit them.
static func _exec_busy(victim:String,roles:Dictionary)->Array:
	var busy:=[victim,String(roles.ex)]
	busy.append_array(roles.get("busy",[]))
	return busy

## Before: the drum roll, everyone holding their breath.
static func _exec_before(ctx:Dictionary,out:Array,victim:String,roles:Dictionary,length:float)->void:
	var rng:RandomNumberGenerator=ctx.rng
	var busy:=_exec_busy(victim,roles)
	_beat(out,0.0,"room","hush",{"dur":length,"bubbles":"dim"},"anticipation")
	if String(ctx.event.get("method",""))!="dogs":_snd(out,0.0,"drum_roll",0.8)
	for m:Dictionary in _people(ctx,busy):
		if rng.randf()<0.55:_beat(out,0.1+rng.randf()*0.4,String(m.key),"freeze",{"dur":1.6},"anticipation")
	if people_dread(ctx.facts)>=DREAD_HIGH:
		for m:Dictionary in _people(ctx,busy):_beat(out,0.4,String(m.key),"tremble",{"dur":length*0.6},"anticipation")

## After: the front row splattered and wiping, someone faints, someone is
## sick, the child hides their eyes and then peeks, the flatterer applauds
## alone, the scribe keeps writing, the envoy's guard gulps. A terrified room
## does it all in silence and shaking (no applause, no peeking).
static func _exec_after(ctx:Dictionary,out:Array,at:float,victim:String,roles:Dictionary,splash:=true,times:={})->void:
	var rng:RandomNumberGenerator=ctx.rng
	var dread:=people_dread(ctx.facts)>=DREAD_HIGH
	var busy:=_exec_busy(victim,roles)
	var used:=busy.duplicate()
	var t_wipe:=float(times.get("wipe",at+0.5));var t_faint:=float(times.get("faint",at+0.8))
	var t_retch:=float(times.get("retch",at+1.4));var t_clap:=float(times.get("clap",at+2.2))
	_snd(out,at,"crowd_gasp",0.9)
	if splash:
		for key in roles.front:
			if String(key) in busy:continue
			_beat(out,at-0.1,String(key),"flinch_splash",{},"reaction")
			_beat(out,t_wipe+rng.randf()*0.3,String(key),"wipe_face",{},"reaction")
			used.append(String(key))
	var jumpy:Array=_jumpiest(_people(ctx,used).filter(func(m:Dictionary)->bool:return String(m.kind)!="child"))
	if not jumpy.is_empty():
		var fainter:=String((jumpy[0] as Dictionary).key)
		_beat(out,t_faint,fainter,"faint",{},"reaction")
		used.append(fainter)
		var catcher:=_nearest(ctx,jumpy[0],["official","hearth_chief","commoner","elder"],used)
		if not catcher.is_empty() and rng.randf()<0.5:
			_beat(out,t_faint+0.4,String(catcher.key),"half_catch",{"at":fainter},"reaction")
			used.append(String(catcher.key))
	var queasy:Array=_people(ctx,used).filter(func(m:Dictionary)->bool:return not String(m.kind) in ["child","scribe"] and float(m.courage)<0.6)
	if not queasy.is_empty():
		var sick:=String((_pick(ctx,queasy) as Dictionary).key)
		_beat(out,t_retch,sick,"vomit",{},"reaction")
		used.append(sick)
	for child:Dictionary in _of_kind(ctx,["child"],busy):
		if dread:_beat(out,at+0.3,String(child.key),"hide_eyes",{"dur":3.0},"reaction")
		else:_beat(out,at+0.3,String(child.key),"cover_eyes_peek",{},"reaction")
	for scribe:Dictionary in _of_kind(ctx,["scribe"],busy):_beat(out,at+0.6,String(scribe.key),"scribble",{"dur":3.0},"reaction")
	for guard:Dictionary in _of_kind(ctx,["guard"],used):_beat(out,at+0.9,String(guard.key),"gulp",{},"reaction")
	if not dread:
		for m:Dictionary in _people(ctx,used):
			if String(m.get("quirk",""))=="flatterer":
				_beat(out,t_clap,String(m.key),"applaud_alone",{},"reaction")
				# nobody joins in
				var other:=_nearest(ctx,m,["official","hearth_chief","elder","commoner"],used+[String(m.key)])
				if not other.is_empty():_beat(out,t_clap+0.8,String(other.key),"side_eye",{"at":String(m.key)},"reaction")
				_shot(out,t_clap+0.1,"reaction",{"target":String(m.key)})
				break

## The acting's plans for an act (K: court_acting.gd EXEC_PLANS), by method.
const PLAN_OF:={"club":"club_home_run","behead":"three_swing_beheading","dogs":"dog_dinner"}
static func _exec_plan_of(method:String)->Dictionary:
	var act:=String(PLAN_OF.get(method,""))
	if act.is_empty() or not ResourceLoader.exists("res://scripts/hud/court_acting.gd"):return {}
	var plan:Variant=load("res://scripts/hud/court_acting.gd").call("exec_plan",act)
	return plan if plan is Dictionary else {}

static func _plan_cue(plan:Dictionary,name:String,otherwise:float)->float:
	for c:Dictionary in plan.get("cues",[]):
		if String(c.get("cue",""))==name:return float(c.get("t",otherwise))
	return otherwise

## An act the acting has a plan for: the one who does it and the cook step
## up, the plan plays (its clips, props, the split and the blood on its own
## clips' events), and the room reacts on the plan's moments.
static func _exec_planned(ctx:Dictionary,out:Array,victim:String,roles:Dictionary,method:String,plan:Dictionary)->float:
	var ex:=String(roles.ex);var cook:=String(roles.cook)
	var act:=String(PLAN_OF.get(method,""))
	var start:=2.2 if method=="dogs" else 1.3
	var length:=start+float(plan.get("length",10.0))+0.6
	var impact:=start+_plan_cue(plan,"impact",_plan_cue(plan,"grab",0.0))
	var has_ex:=(plan.get("roles",{}) as Dictionary).has("executioner")
	var has_cook:=(plan.get("roles",{}) as Dictionary).has("cook")
	roles["busy"]=[cook] if has_cook and not cook.is_empty() else []
	_exec_before(ctx,out,victim,roles,length)
	if has_ex:
		_shot(out,0.0,"two_shot",{"a":victim,"b":ex,"weight":5})
		_exec(out,0.2,"approach",{"who":ex,"to":victim,"side":-1.0,"dist":0.9,"time":1.0})
	else:
		# The prone body extends toward the camera beyond its standing mark.
		_shot(out,0.0,"frame",{"on":[victim,"windbreak","front:"+victim+":1.9"],"weight":5})
	_exec(out,start,"plan",{"act":act,"ex":ex if has_ex else "","cook":cook if has_cook else ""})
	_exec(out,impact,"blow",{})
	match method:
		"club":
			var plop:=start+_plan_cue(plan,"plop",3.62+1.4)
			_shot(out,start+0.2,"frame",{"on":[victim,ex,"pot"],"time":0.8})
			_shot(out,impact+0.1,"shake",{"strength":0.4})
			_shot(out,impact+0.15,"frame",{"on":[victim,"pot","above:"+victim+":1.2"],"time":0.5})
			_shot(out,plop-0.2,"frame",{"on":[cook,"pot"],"time":0.6})
			_exec_after(ctx,out,impact+0.2,victim,roles,true,
				{"wipe":impact+0.5,"faint":impact+0.6,"retch":start+_plan_cue(plan,"after",8.0)+0.3,"clap":start+_plan_cue(plan,"after",8.0)})
		"behead":
			_shot(out,start+0.2,"frame",{"on":[victim,ex,"block"],"time":0.8})
			_shot(out,start+_plan_cue(plan,"clang",5.5)+0.05,"reaction",{"target":ex})
			_shot(out,start+_plan_cue(plan,"glare",6.75),"frame",{"on":[victim,ex,"block"],"time":0.6})
			_shot(out,impact+0.15,"frame",{"on":[victim,ex,"front:"+victim+":1.9"],"time":0.5})
			for m:Dictionary in _people(ctx,_exec_busy(victim,roles)):
				if float(m.courage)<0.5:_beat(out,start+_plan_cue(plan,"thunk",1.95)+0.1,String(m.key),"flinch",{"dur":0.4},"reaction")
			_exec_after(ctx,out,impact+0.1,victim,roles,true,
				{"wipe":start+_plan_cue(plan,"splash",8.75)+0.4,"faint":impact+0.5,"retch":start+_plan_cue(plan,"after",11.0)+0.3,"clap":start+_plan_cue(plan,"after",11.0)})
			for m:Dictionary in _people(ctx,_exec_busy(victim,roles)).slice(0,2):_beat(out,start+_plan_cue(plan,"head_blink",10.9)+0.15,String(m.key),"double_take",{},"reaction")
		"dogs":
			var gone:=start+_plan_cue(plan,"out_of_sight",6.6)
			_exec(out,0.0,"pack_come",{"more":2})
			_beat(out,0.25,victim,"plead",{"dur":1.5,"sound":""},"anticipation")
			_shot(out,start+0.45,"frame",{"on":[victim,"front:"+victim+":1.6","windbreak"],"time":0.65})
			_shot(out,start+1.3,"shake",{"strength":0.13})
			_shot(out,start+5.05,"frame",{"on":[victim,"front:"+victim+":1.5","windbreak"],"time":0.65})
			# The pack stays at the completed drag endpoint. There is no competing
			# fetch route to cancel its last movement or reset the scene's tone.
			_exec(out,gone,"vanish",{"who":victim})
			_exec(out,gone,"pack_crunch",{"seconds":2.4})
			_exec_dog_witnesses(ctx,out,victim,start,gone,length)
			_shot(out,gone+3.0,"frame",{"on":["windbreak","front:"+victim+":1.5"],"time":1.1})
	return length


## The witnesses cannot make a spectacle of this act. Adults recoil and then
## stay stricken; children keep their eyes covered through the entire scene.
static func _exec_dog_witnesses(ctx:Dictionary,out:Array,victim:String,start:float,gone:float,end:float)->void:
	var witnesses:=_people(ctx,[victim])
	var reaction:=""
	for i in witnesses.size():
		var person:Dictionary=witnesses[i]
		var key:=String(person.key)
		if String(person.kind)=="child":
			_beat(out,0.4,key,"hide_eyes",{"dur":end-0.4,"sound":""},"reaction")
			continue
		var lag:=0.08+0.12*float(i%4)
		_beat(out,start+0.6+lag,key,"flinch",{"dur":0.7,"sound":""},"reaction")
		_beat(out,gone+0.2+lag,key,"stricken",{"dur":end-gone,"sound":""},"reaction")
		if reaction.is_empty() and float(person.courage)<0.7:reaction=key
	if not reaction.is_empty():_shot(out,gone+0.6,"reaction",{"target":reaction,"time":0.8})


## Mild: the blow lands off screen. The camera turns to the room's faces at
## the moment; no blood, no parts; they are simply gone when it turns back.
static func _exec_mild(out:Array,ctx:Dictionary,victim:String,roles:Dictionary)->void:
	var impact:=INF
	var kept:Array=[]
	for beat:Dictionary in out:
		if String(beat.who)=="exec" and String(beat.act) in ["behead","spray","pool","burn","char","crumble","fall","blow"]:
			impact=minf(impact,float(beat.t))
			if String(beat.act)!="blow":continue
		kept.append(beat)
	out.clear();out.append_array(kept)
	if impact==INF:return
	var faces:Array=_people(ctx,_exec_busy(victim,roles))
	if not faces.is_empty():_shot(out,impact-0.15,"reaction",{"target":String((_pick(ctx,faces) as Dictionary).key)})
	_exec(out,impact+0.3,"vanish",{"who":victim})
	_shot(out,impact+2.6,"wide")

# --- the acts -------------------------------------------------------------------------

## 2. Club home run: a huge wind-up, CRACK, the head sails in a long arc into
## the cooking pot; the cook looks in, stirs, and puts the lid on. (Timed to
## the sound's track: the blow at `blow`, the plop 1.25 s after, the stir
## 3.0, the lid 4.6, the lone clap 6.0.)
static func _exec_club(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var ex:=String(roles.ex);var cook:=String(roles.cook)
	var blow:=2.8
	var length:=blow+7.2
	_exec_before(ctx,out,victim,roles,length)
	_exec(out,0.0,"prop",{"name":"pot","id":"pot","at":"fire","toward_camera":1.15,"offset":Vector3(0.75,0,0)})
	_beat(out,0.2,victim,"kneel",{"dur":3.0,"hold":true},"anticipation")
	_shot(out,0.0,"two_shot",{"a":victim,"b":ex,"weight":5})
	_exec(out,0.3,"approach",{"who":ex,"to":victim,"side":-1.0,"dist":0.85,"time":1.0})
	_exec(out,1.3,"prop",{"name":"club","to":ex,"hand":"R"})
	_beat(out,blow-0.9,ex,"windup",{"dur":0.8,"hold":true},"anticipation")
	_exec(out,blow-0.9,"twist",{"who":ex,"yaw":-80.0,"time":0.75})
	_beat(out,blow-0.4,ex,"squint",{"dur":0.3},"anticipation")
	# CRACK
	_exec(out,blow-0.12,"twist",{"who":ex,"yaw":165.0,"time":0.11})
	_exec(out,blow-0.12,"lunge",{"who":ex,"dist":0.22,"time":0.1})
	_beat(out,blow-0.12,ex,"swing",{"dur":0.6},"action")
	_exec(out,blow,"blow",{})
	_snd(out,blow,"club_crack",1.0,"crack")
	_shot(out,blow,"shake",{"strength":0.45})
	_exec(out,blow+0.02,"behead",{"who":victim,"fly":"pot","time":1.23,"arc":2.4,"spin":2.5})
	_exec(out,blow+0.04,"spray",{"at":"neck:"+victim,"dir":"up","seconds":0.9,"amount":70,"speed":3.0})
	_shot(out,blow+0.1,"frame",{"on":[victim,ex,"pot"],"time":0.6})
	_exec(out,blow+0.5,"fall",{"who":victim,"kind":"forward","time":0.55})
	_snd(out,blow+1.25,"plop",0.9,"plop")
	_exec(out,blow+1.27,"spray",{"at":"pot","y":0.45,"dir":"up","seconds":0.25,"amount":28,"speed":1.8,"pool":false})
	# the cook
	if cook!="":
		_beat(out,blow+1.6,cook,"double_take",{"at":ex},"reaction")
		_exec(out,blow+1.7,"approach",{"who":cook,"to":"pot","side":1.0,"dist":0.55,"time":0.8})
		_shot(out,blow+2.4,"frame",{"on":[cook,"pot"],"time":0.7})
		_beat(out,blow+2.6,cook,"lean_in",{"dur":0.4},"action")
		_beat(out,blow+3.0,cook,"stir",{"dur":1.2},"action")
		_exec(out,blow+4.45,"prop",{"name":"lid","id":"lid","at":"pot","y":0.44})
		_exec(out,blow+4.45,"drop",{"id":"lid","at":"pot","offset":Vector3(0,0.44,0),"height":0.35,"time":0.2})
		_snd(out,blow+4.6,"lid_clank",0.8,"clatter")
		_beat(out,blow+4.9,cook,"wipe_hands",{},"reaction")
	_exec_after(ctx,out,blow+1.4,victim,roles,true,{"wipe":blow+0.5,"faint":blow+1.7,"retch":blow+2.2,"clap":blow+6.0})
	return length

## 10. Three-swing beheading: the first stroke sticks in the block, the second
## bounces off, the third pops the head off; it rolls, stops facing the god,
## and blinks; a geyser soaks the front row. (Timed to the sound's track: the
## stuck stroke at `blow`, the pull 0.9, the clang 2.5, the chop 4.8, the
## geyser 5.1, the patter on the front row 5.9, the blink 7.0, the retch 8.1.)
static func _exec_behead(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var ex:=String(roles.ex)
	var blow:=2.6
	var length:=blow+9.0
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"two_shot",{"a":victim,"b":ex,"weight":5})
	_exec(out,0.1,"prop",{"name":"block","id":"block","at":victim,"front":0.5,"of":victim})
	_beat(out,0.3,victim,"kneel",{"dur":10.0,"hold":true},"anticipation")
	_exec(out,0.3,"approach",{"who":ex,"to":victim,"side":-1.0,"dist":0.8,"time":1.0})
	_exec(out,1.2,"lean",{"who":victim,"pitch":36.0,"time":0.6})
	_exec(out,1.3,"prop",{"name":"axe","id":"axe","to":ex,"hand":"R"})
	# one: it sticks in the block
	_beat(out,blow-0.9,ex,"windup",{"dur":0.7,"hold":true},"anticipation")
	_exec(out,blow-0.9,"twist",{"who":ex,"yaw":-70.0,"time":0.65})
	_exec(out,blow-0.2,"twist",{"who":ex,"yaw":120.0,"time":0.1})
	_beat(out,blow-0.2,ex,"swing",{"dur":0.5},"action")
	_exec(out,blow,"blow",{})
	_snd(out,blow,"thunk",1.0,"thump")
	_exec(out,blow+0.02,"stick",{"id":"axe","in":"block"})
	_beat(out,blow+0.25,ex,"tug",{"dur":0.6},"action")
	_exec(out,blow+0.35,"lunge",{"who":ex,"dist":-0.12,"time":0.12})
	_exec(out,blow+0.65,"lunge",{"who":ex,"dist":-0.14,"time":0.12})
	_beat(out,blow+0.4,victim,"side_eye",{"at":ex,"dur":0.9},"reaction")
	_exec(out,blow+0.9,"retrieve",{"id":"axe","who":ex})
	_exec(out,blow+0.9,"lunge",{"who":ex,"dist":-0.3,"time":0.18})
	# two: it bounces off
	_exec(out,blow+1.5,"twist",{"who":ex,"yaw":-120.0,"time":0.7})
	_beat(out,blow+1.5,ex,"windup",{"dur":0.7,"hold":true},"anticipation")
	_exec(out,blow+2.3,"twist",{"who":ex,"yaw":120.0,"time":0.1})
	_beat(out,blow+2.3,ex,"swing",{"dur":0.4},"action")
	_snd(out,blow+2.5,"clang",1.0,"clatter")
	_exec(out,blow+2.5,"twist",{"who":ex,"yaw":-60.0,"time":0.12})
	_beat(out,blow+2.55,ex,"wobble",{"dur":0.8},"reaction")
	_beat(out,blow+2.6,victim,"flinch",{},"reaction")
	_beat(out,blow+3.15,ex,"mortified",{"dur":0.6},"reaction")
	_shot(out,blow+2.55,"reaction",{"target":ex})
	# three: off it comes
	_exec(out,blow+3.75,"twist",{"who":ex,"yaw":-90.0,"time":0.8})
	_beat(out,blow+3.75,ex,"windup",{"dur":0.8,"hold":true},"anticipation")
	_shot(out,blow+3.8,"two_shot",{"a":victim,"b":ex})
	_exec(out,blow+4.6,"twist",{"who":ex,"yaw":150.0,"time":0.1})
	_exec(out,blow+4.6,"lunge",{"who":ex,"dist":0.25,"time":0.1})
	_beat(out,blow+4.6,ex,"swing",{"dur":0.6},"action")
	_snd(out,blow+4.8,"chop",1.0,"crack")
	_exec(out,blow+4.82,"behead",{"who":victim,"fly":"roll","roll_dist":1.5,"time":1.0,"arc":0.45,"spin":0.65,"face_god":false,"blink":false})
	_exec(out,blow+5.1,"spray",{"at":"neck:"+victim,"dir":"camera","seconds":1.8,"amount":120,"speed":4.4,"spread":18.0,"pool_r":0.7})
	_exec(out,blow+5.3,"fall",{"who":victim,"kind":"forward","time":0.5})
	_shot(out,blow+4.9,"frame",{"on":[victim,ex,"front:"+victim+":1.5"],"time":0.5})
	_exec_after(ctx,out,blow+5.4,victim,roles,true,{"wipe":blow+5.9,"faint":blow+6.2,"retch":blow+8.1,"clap":blow+7.6})
	for dog:Dictionary in _of_kind(ctx,["dog"]):_beat(out,blow+6.6,String(dog.key),"sniff",{"at":victim},"reaction")
	return length

## Legacy fallback if the authored dog plan is unavailable: a drag behind
## the windbreak and a stricken court, with no returning-bone punchline.
static func _exec_dogs(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var blow:=2.2
	var length:=blow+8.8
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"frame",{"on":[victim,"windbreak"],"weight":5})
	_beat(out,0.2,victim,"look_wrong_way",{"dur":0.8},"anticipation")
	_snd(out,0.4,"dog_bark",0.8,"bark")
	_exec(out,0.3,"dogs",{"to":victim,"more":2})
	_beat(out,1.0,victim,"double_take",{"dur":0.7},"reaction")
	_beat(out,1.5,victim,"flinch",{},"reaction")
	_exec(out,blow,"blow",{})
	_snd(out,blow,"dog_snarl",0.9)
	_exec(out,blow,"fall",{"who":victim,"kind":"back","time":0.35})
	_exec(out,blow+0.2,"drag",{"who":victim,"to":"windbreak","time":1.8})
	_exec(out,blow+2.0,"vanish",{"who":victim})
	_snd(out,blow+2.0,"crunch_loop",1.0,"crunch")
	_shot(out,blow+2.0,"shake",{"strength":0.12})
	_exec_dog_witnesses(ctx,out,victim,blow,blow+2.0,length)
	_shot(out,blow+5.4,"frame",{"on":["windbreak"],"time":0.8})
	return length

## Sustained body fire, progressive scorching and a heavy collapse.
static func _exec_fire(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var ex:=String(roles.ex)
	var length:=12.0
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"wide",{"weight":5})
	_exec(out,0.3,"approach",{"who":ex,"to":victim,"side":-1.0,"dist":0.6,"time":0.9})
	_beat(out,1.2,ex,"grab",{"at":victim},"action")
	_exec(out,1.5,"heave",{"who":victim,"to":"fire","time":0.9})
	_exec(out,2.4,"blow",{})
	_exec(out,2.4,"flare",{"seconds":3.5,"strength":0.85})
	_exec(out,2.4,"burn",{"who":victim,"seconds":8.5})
	_exec(out,2.4,"char",{"who":victim,"time":4.8})
	_shot(out,2.3,"frame",{"on":[victim,"fire","petitioner"]})
	_beat(out,2.5,victim,"flinch",{"dur":0.7},"action")
	_exec(out,3.2,"walk",{"who":victim,"to":"petitioner","time":2.1})
	_beat(out,5.4,victim,"wobble",{"dur":0.8},"action")
	_exec(out,6.3,"fall",{"who":victim,"kind":"side","time":0.85})
	_shot(out,6.4,"frame",{"on":[victim,"fire"],"time":0.65})
	for m:Dictionary in _people(ctx,[victim,ex]):
		_beat(out,6.6,String(m.key),"cover_eyes_peek",{"dur":2.5},"reaction")
	return length

## 5. Spear pincushion: the watch hurls spears; they wobble; the child's
## spear hits the hide wall; the last one thunks in and they topple.
static func _exec_spears(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var length:=10.0
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"wide",{"weight":5})
	var throwers:Array=_people(ctx,[victim]).filter(func(m:Dictionary)->bool:return String(m.kind) in ["official","hearth_chief","guard","commoner"])
	var t:=1.0
	for i in mini(5,maxi(throwers.size(),1)*2):
		var who:=String((throwers[i%throwers.size()] as Dictionary).key) if not throwers.is_empty() else String(roles.ex)
		_beat(out,t,who,"throw",{"dur":0.5},"action")
		_exec(out,t+0.1,"throw",{"name":"spear","from":who,"to":victim,"time":0.35,"arc":0.3,"height":0.9+0.12*(i%3)})
		_snd(out,t+0.45,"spear_thunk",0.9,"thump")
		_beat(out,t+0.5,victim,"wobble",{"dur":0.4},"reaction")
		t+=0.75
	for child:Dictionary in _of_kind(ctx,["child"]):
		_exec(out,t,"throw",{"name":"spear","from":String(child.key),"to":victim,"time":0.5,"arc":0.5,"miss":Vector3(1.6,0.3,-0.8)})
		_snd(out,t+0.5,"spear_thunk",0.5,"thump")
		_beat(out,t+0.6,String(child.key),"mortified",{},"reaction")
		t+=0.8
		break
	_exec(out,t+0.4,"throw",{"name":"spear","from":String(roles.ex),"to":victim,"time":0.3,"arc":0.2})
	_snd(out,t+0.7,"spear_thunk",1.0,"thump")
	_exec(out,t+1.1,"fall",{"who":victim,"kind":"back","time":0.9})
	_snd(out,t+2.0,"timber_fall",0.8,"thump")
	_exec(out,t+1.2,"pool",{"at":victim,"r":0.5})
	_exec_after(ctx,out,t+2.0,victim,roles,false)
	return maxf(length,t+5.0)

## 6. Stoned by the whole court: everyone throws; they become a cairn; the
## child's stone bonks an official.
static func _exec_stoning(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var length:=10.0
	var rng:RandomNumberGenerator=ctx.rng
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"wide",{"weight":5})
	var all:Array=_people(ctx,[victim])
	var t:=1.0
	for round in 3:
		for m:Dictionary in all:
			if String(m.kind)=="child":continue
			var at:=t+rng.randf()*0.6
			_beat(out,at,String(m.key),"throw",{"dur":0.5},"action")
			_exec(out,at+0.1,"throw",{"name":"stone","from":String(m.key),"to":victim,"time":0.45,"arc":0.7,"height":0.4+0.3*round,"stick":false})
			_snd(out,at+0.55,"stone_bonk",0.6,"thump")
		t+=1.1
	_beat(out,2.0,victim,"flinch",{},"reaction")
	_exec(out,3.5,"fall",{"who":victim,"kind":"side","time":0.6})
	for child:Dictionary in _of_kind(ctx,["child"]):
		var official:=_nearest(ctx,child,["official","hearth_chief"],[victim])
		if official.is_empty():break
		_exec(out,t,"throw",{"name":"stone","from":String(child.key),"to":String(official.key),"time":0.4,"arc":0.5,"height":1.6,"stick":false})
		_snd(out,t+0.4,"stone_bonk",0.9,"thump")
		_beat(out,t+0.45,String(official.key),"double_take",{"at":String(child.key)},"reaction")
		_beat(out,t+0.9,String(child.key),"hide_behind",{"at":_nearest(ctx,child,["elder","commoner","official"],[victim,String(official.key)]).get("key","")},"reaction")
		break
	_exec(out,t+0.5,"vanish",{"who":victim})
	_exec_after(ctx,out,t+0.6,victim,roles,false)
	return maxf(length,t+4.5)

## 1. Boulder drop: two of them tip a boulder; SPLAT; a hand waves feebly.
static func _exec_boulder(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var length:=10.0
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"wide",{"weight":5})
	_beat(out,0.4,victim,"look_up",{"dur":1.2},"anticipation")
	_exec(out,0.2,"prop",{"name":"boulder","id":"boulder","at":victim,"y":3.2})
	_exec(out,1.6,"drop",{"id":"boulder","at":victim,"height":3.2,"time":0.45})
	_snd(out,2.05,"splat",1.0,"thump")
	_shot(out,2.05,"shake",{"strength":0.55})
	_exec(out,2.07,"vanish",{"who":victim})
	_exec(out,2.1,"pool",{"at":victim,"r":0.9,"time":0.6})
	_exec_after(ctx,out,2.3,victim,roles,true)
	return length

## 14. Boiled in the pot: in they go; bubbles; the cook adds herbs, tastes,
## adds salt; a skull bobs up.
static func _exec_boil(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var ex:=String(roles.ex);var cook:=String(roles.cook)
	var length:=11.0
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"wide",{"weight":5})
	_exec(out,0.0,"prop",{"name":"pot","id":"pot","at":"fire","toward_camera":1.0,"offset":Vector3(0.6,0,0)})
	_exec(out,0.3,"approach",{"who":ex,"to":victim,"side":-1.0,"dist":0.6,"time":0.8})
	_beat(out,1.1,ex,"grab",{"at":victim},"action")
	_exec(out,1.4,"drag",{"who":victim,"to":"pot","time":1.0})
	_snd(out,2.4,"big_splash",1.0)
	_exec(out,2.45,"vanish",{"who":victim})
	_exec(out,2.5,"spray",{"at":"pot","y":0.45,"dir":"up","seconds":0.3,"amount":40,"speed":2.2,"pool":false})
	_snd(out,2.8,"bubbling",0.7)
	if cook!="":
		_exec(out,3.4,"approach",{"who":cook,"to":"pot","side":1.0,"dist":0.55,"time":0.8})
		_beat(out,4.4,cook,"stir",{"dur":1.0},"action")
		_beat(out,5.6,cook,"taste",{"dur":0.9},"action")
		_beat(out,6.6,cook,"stir",{"dur":0.8},"action")
		_shot(out,4.5,"reaction",{"target":cook})
	if starving(ctx.facts):
		var hungry_one:Array=_of_kind(ctx,["commoner","elder"],[victim,ex,cook])
		if not hungry_one.is_empty():_beat(out,7.4,String((hungry_one[0] as Dictionary).key),"lean_in",{},"reaction")
	_exec_after(ctx,out,2.6,victim,roles,false)
	return length

## 16. Volley of arrows: archers loose until they look like a porcupine; the
## last arrow knocks off their hat.
static func _exec_arrows(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var length:=10.0
	var rng:RandomNumberGenerator=ctx.rng
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"wide",{"weight":5})
	var archers:Array=_people(ctx,[victim]).filter(func(m:Dictionary)->bool:return String(m.kind) in ["official","hearth_chief","guard","commoner"]).slice(0,3)
	var t:=1.2
	for volley in 3:
		for m:Dictionary in archers:
			_exec(out,t,"throw",{"name":"arrow","from":String(m.key),"to":victim,"time":0.25,"arc":0.15,"height":0.7+rng.randf()*0.6})
		_snd(out,t,"bow_twang",0.8)
		_snd(out,t+0.25,"arrow_thunks",0.9,"thump")
		_beat(out,t+0.3,victim,"wobble",{"dur":0.4},"reaction")
		t+=1.0
	_exec(out,t+0.6,"fall",{"who":victim,"kind":"back","time":0.8})
	_exec(out,t+0.7,"pool",{"at":victim,"r":0.55})
	_exec_after(ctx,out,t+1.2,victim,roles,false)
	return maxf(length,t+4.5)

## 15. The stake: hoisted up, they slide slowly down to eye level with the
## scribe or the elder, who keeps writing.
static func _exec_stake(ctx:Dictionary,out:Array,victim:String,roles:Dictionary)->float:
	var length:=10.0
	_exec_before(ctx,out,victim,roles,length)
	_shot(out,0.0,"wide",{"weight":5})
	_exec(out,0.2,"prop",{"name":"stake","id":"stake","at":victim,"front":-0.4,"of":victim})
	_exec(out,1.4,"pool",{"at":victim,"r":0.45,"time":4.0})
	_beat(out,1.0,victim,"wobble",{"dur":1.0},"action")
	_snd(out,1.2,"squelch",0.9)
	_exec(out,1.6,"fall",{"who":victim,"kind":"side","time":3.5})
	for watcher:Dictionary in _of_kind(ctx,["scribe","elder"]):
		_beat(out,3.0,String(watcher.key),"scribble" if String(watcher.kind)=="scribe" else "stroke_chin",{"dur":3.0},"reaction")
		break
	_exec(out,6.0,"vanish",{"who":victim})
	_exec_after(ctx,out,2.0,victim,roles,false)
	return length

# =============================================================================
# Ambient: the room's own business, from the facts alone
# =============================================================================

## What the people in the hall do while nothing is happening: loops for the
## stage to play at random within `every` seconds (hold: a standing state).
## Only what the facts hold: hunger when the stores are short, a cough while
## a sickness runs, spears while there is a war; the dread and love of the
## god in the faces; stamping and breath in winter, a fly in summer; the
## scribe at work where the people write. If a fact is not in the sheet,
## nothing shows it.
static func ambient(cast_in:Array,facts_in:Dictionary,rng_seed:int)->Array:
	var facts:=normal_facts(facts_in)
	var cast:=normal_cast(cast_in,facts)
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|ambient" % rng_seed)
	var members:Array=[]
	var index:=0
	for entry in cast:
		if entry is Dictionary:members.append(member(entry,index));index+=1
	var people:Array=members.filter(func(m:Dictionary)->bool:return not bool(m.animal))
	var foreign:=["envoy","guard","bearer","attendant"]
	var ours:Array=people.filter(func(m:Dictionary)->bool:return not String(m.kind) in foreign+["scribe","door_guard"] and String(m.role)!="main")
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
			busy[String(m.key)]=true
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
	# War: spears worked sharp, the door watched.
	var fight:=war(facts)
	var guards:Array=people.filter(func(m:Dictionary)->bool:return String(m.kind)=="door_guard")
	if not fight.is_empty():
		var fighters:Array=ours.filter(func(m:Dictionary)->bool:return int(m.age)>=16 and int(m.age)<56 and not busy.has(String(m.key)))
		fighters.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.courage)>float(b.courage) if not is_equal_approx(float(a.courage),float(b.courage)) else int(a.index)<int(b.index))
		if not fighters.is_empty():
			var fighter:Dictionary=fighters[0]
			var act:="sharpen_spear" if bool(presentation(facts,fighter).get("rustic_props",true)) else "glance_door"
			_loop(out,String(fighter.key),act,[6.0,12.0],{},"war",rng)
			busy[String((fighters[0] as Dictionary).key)]=true
		var watcher:Dictionary=guards[0] if not guards.is_empty() else (fighters[1] if fighters.size()>=2 else {})
		if not watcher.is_empty():
			_hold(out,String(watcher.key),"stand_guard",{},"war")
			_loop(out,String(watcher.key),"glance_door",[8.0,15.0],{},"war",rng)
			busy[String(watcher.key)]=true
	for g:Dictionary in guards:
		if not busy.has(String(g.key)):
			_hold(out,String(g.key),"stand_guard",{},"post")
			busy[String(g.key)]=true
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
	var sleeper:=dozer(cast,facts)
	if season=="winter" and not bool(facts.get("indoor",false)):
		for m:Dictionary in _shuffled(rng,ours).slice(0,3):
			if busy.has(String(m.key)):continue
			_loop(out,String(m.key),["rub_hands","stamp_feet","breath"][rng.randi_range(0,2)],[8.0,15.0],{},"season",rng)
	elif season=="summer" and not bool(facts.get("indoor",false)):
		# The fly finds the old one, asleep or not: they swat at it in their sleep.
		var elders:Array=ours.filter(func(m:Dictionary)->bool:return String(m.kind)=="elder")
		if not elders.is_empty():_loop(out,String((elders[0] as Dictionary).key),"swat_fly",[9.0,18.0],{},"season",rng)
		for m:Dictionary in _shuffled(rng,ours).slice(0,1):
			if not busy.has(String(m.key)):_loop(out,String(m.key),"fan_self",[10.0,18.0],{},"season",rng)
	# The sleeper.
	if not sleeper.is_empty():_hold(out,sleeper,"doze",{},"calm")
	# Children are children; animals are animals; the scribe writes.
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
			"scribe":
				_loop(out,String(m.key),_writing_act(facts,m),[4.0,9.0],{},"writing",rng)
			"dog":
				if room_dread>=DREAD_HIGH:_hold(out,String(m.key),"lie_down",{"ears":"back"},"dread")
				else:
					_loop(out,String(m.key),"scratch",[12.0,25.0],{},"life",rng)
					if String((facts.get("gift",{}) as Dictionary).get("resource","")).to_lower()=="food":
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
			"bearer","attendant":
				if not busy.has(String(m.key)):_loop(out,String(m.key),"gawk",[10.0,20.0],{},"strangers",rng)
			"envoy":
				match String(m.temper):
					"haughty":_loop(out,String(m.key),"brush_sleeve",[12.0,22.0],{},"temper",rng)
					"nervous":_loop(out,String(m.key),"wring_hands",[8.0,14.0],{},"temper",rng)
					"greedy":_loop(out,String(m.key),"appraise",[10.0,18.0],{},"temper",rng)
	# Everyone else breathes and shifts now and then (the acting layer blinks).
	for m:Dictionary in people:
		if busy.has(String(m.key)) or String(m.role)=="main" or String(m.kind) in ["child","guard","scribe","door_guard"]:continue
		if rng.randf()<0.5:_loop(out,String(m.key),["shift_weight","scratch"][rng.randi_range(0,1)],[12.0,24.0],{},"life",rng)
	# Each firing in the stage's primitives too (lower()).
	for spec:Dictionary in out:
		var args:Dictionary=(spec.args as Dictionary).duplicate()
		if float(spec.dur)>0.0:args["dur"]=float(spec.dur)
		spec["primitives"]=lower([{"t":0.0,"who":String(spec.who),"act":String(spec.act),"args":args}])
	return out

static func _loop(out:Array,who:String,act:String,every:Array,args:Dictionary,because:String,rng:RandomNumberGenerator)->void:
	var spec:Dictionary=ACTS.get(act,{})
	out.append({"who":who,"act":act,"every":every,"start":snappedf(rng.randf()*float(every[0]),0.1),"dur":float(spec.get("dur",1.0)),"args":args,"because":because,"hold":false})

static func _hold(out:Array,who:String,act:String,args:Dictionary,because:String)->void:
	out.append({"who":who,"act":act,"every":[],"start":0.0,"dur":0.0,"args":args,"because":because,"hold":true})

# =============================================================================
# Asides: a muttered line now and then
# =============================================================================

## Who dares mutter in a god's hall: the bold, the proud, the unafraid; a
## child (children say what they see); an old one past caring. Never the
## frightened.
static func dare(m:Dictionary)->float:
	var d:=float(m.courage)*0.6+float(m.pride)*0.5-float(m.dread)*0.9-0.2
	if String(m.kind)=="child":d+=0.38
	elif int(m.age)>=60:d+=0.2
	return d

## A room too frightened or too grieved for anyone to mutter: a terror, a
## death, a casting out, a refusal, a cruel order, a hall in dread. The
## silence is the joke.
static func silent(ctx:Dictionary)->bool:
	var event:Dictionary=ctx.event
	if String(ctx.gravity)=="grave":return true
	if people_dread(ctx.facts)>=DREAD_HIGH:return true
	match String(ctx.kind):
		"terrify_envoy":return true
		"divine":return String(event.get("action","")) in ["terrify","strike_down","cast_out"]
		"command":return String(event.get("stage",""))=="prostrate" or String(event.get("obedience",""))=="refuse" or String(event.get("verb","")) in ["kill","maim","detain","exile"]
		"exit":return String(event.get("style","")) in ["led","fall"]
	return false

## A muttered line answers a bit everyone just saw: [situation, who speaks].
## who: "near" (the nearest bold one to it), "star" (the one it fell on),
## "struck" (the one the elder swatted), "any" (anyone bold).
const BIT_ASIDES:={
	"doze_jerk":["doze_wake","near"],"drop_bowl":["drop_bowl","near"],"eager_bow":["eager_bow","near"],
	"goat_nibble":["goat_nibble","star"],"goat_ignores":["goat","any"],"dog_sniff_gift":["dog_gift","any"],
	"double_take":["number","star"],"count_fingers":["number","star"],"cough_fit":["sick_cough","near"],
	"bored_guard":["guard_bored","any"],"guard_snap":["guard_awake","any"],"stifle_elbow":["stifle","near"],
	"child_copies":["child_copy","near"],"bow_early":["bow_early","near"],"late_lift":["late_lift","near"],
	"gasp_pretend":["gasp","any"],"winter_stamp":["winter","star"],"fly_elder":["fly","struck"],
	"scribe_cramp":["scribe","near"],"over_thank":["over_thank","near"],"bump_post":["bump_post","any"],
	"forgot_thing":["forgot_thing","any"],"wrong_door":["wrong_door","any"],"bow_wrong":["bow_wrong","any"],
	"child_wave":["child_wave","any"],"stare_down":["stare_down","any"],"company_gawk":["company_gawk","any"],
	"gifted":["gifted","any"],"envoy_sniff":["envoy_haughty","any"],"envoy_startle":["envoy_nervous","any"],
	"envoy_appraise":["envoy_greedy","any"],"side_eye_pair":["absurd","star"],"double_bow":["over_thank","near"],
	"quirk_count":["pedant","star"],"quirk_flatter":["flatter","near"],"quirk_yawn":["yawn","near"],"quirk_jealous":["jealous","star"],
	"quirk_agree":["yes_man","any"],
}
## Or a visible beat of the moment itself: act -> [situation, who speaks].
const ACT_ASIDES:={
	"face_fall":["refused","any"],"deflate_polite":["promise_deflate","any"],"shrug":["absurd","any"],
	"doze_off":["wait_doze","near"],"catch_eye":["wait_long","any"],"storm_off":["storm_out","any"],
	"glum":["cost_grumble","near"],"lift_bundle":["gift_refused","any"],"eye_food":["eat","star"],
	"rub_belly":["penance_hungry","any"],"side_eye":["bless_envy","star"],
}
## How likely a muttered line is when something visible offers one; at most
## one an event, never within ASIDE_GAP events of the last.
const ASIDE_CHANCE:=0.45
const ASIDE_GAP:=3
## A line rests three game years before it may be said again (or, with no
## day on the fact sheet, LINE_REST_EVENTS events); a situation rests too.
const LINE_REST_DAYS:=1095
const LINE_REST_EVENTS:=150
const SITUATION_REST_DAYS:=120
const SITUATION_REST_EVENTS:=16
const DARE_MIN:=0.2

## At most one muttered line for this event, from a bold bystander, in
## answer to something visible, built only from the facts and the event.
## [{t, who, text, cites, situation}]. Call after beats_for for the same event.
static func asides_for(event_in:Dictionary,facts_in:Dictionary,cast_in:Array,rng_seed:int,memory:Dictionary={})->Array:
	var facts:=normal_facts(facts_in)
	var cast:=normal_cast(cast_in,facts,memory.get("voices",{}) if memory.get("voices") is Dictionary else {})
	var event:=normal_event(event_in,cast)
	var ctx:=_context(event,cast,facts,rng_seed+31,memory)
	var n:=int(memory.get("aside_events",0))+1
	memory["aside_events"]=n
	if not mutters_enabled or not bool(facts.get("mutters",true)):return []
	if silent(ctx):return []
	if n-int(memory.get("aside_n",-1000))<=ASIDE_GAP:return []
	var rng:RandomNumberGenerator=ctx.rng
	var options:=_aside_options(ctx)
	if options.is_empty() or rng.randf()>ASIDE_CHANCE:return []
	ctx["aside_n"]=n
	# Weighted, without putting back, until one is said.
	var pool:=options.duplicate()
	while not pool.is_empty():
		var total:=0.0
		for o:Dictionary in pool:total+=float(o.weight)
		var roll:=rng.randf()*total
		var index:=0
		for i in pool.size():
			roll-=float((pool[i] as Dictionary).weight)
			if roll<=0.0:index=i;break
		var option:Dictionary=pool[index]
		pool.remove_at(index)
		var said:=_say(ctx,option)
		if said.is_empty():continue
		memory["aside_n"]=n
		var stamp:={"n":n,"day":_day_of(facts)}
		if not memory.get("aside_lines") is Dictionary:memory["aside_lines"]={}
		if not memory.get("aside_situations") is Dictionary:memory["aside_situations"]={}
		(memory.aside_lines as Dictionary)[String(said.template)]=stamp
		(memory.aside_situations as Dictionary)[String(said.situation)]=stamp
		var recent:Array=memory.get("mutterers",[]) if memory.get("mutterers") is Array else []
		recent.append(String(_m(ctx,String(said.who)).get("name","")))
		while recent.size()>8:recent.pop_front()
		memory["mutterers"]=recent
		said["line_id"]=String(said.template)
		said.erase("template")
		return [said]
	return []

static func _day_of(facts:Dictionary)->int:
	return int(facts.day) if _num(facts.get("day",null)) else -1

## Has this rested long enough: by game days when the sheet has a day, else
## by events.
static func _rested_since(stamp:Variant,facts:Dictionary,n:int,days:int,events:int)->bool:
	if not stamp is Dictionary:return true
	var day:=_day_of(facts)
	if day>=0 and int((stamp as Dictionary).get("day",-1))>=0:return day-int(stamp.day)>=days
	return n-int((stamp as Dictionary).get("n",-100000))>=events

## The muttered lines this moment offers: one for each bit just played and
## each visible beat that has words, with who may say it and the slots.
static func _aside_options(ctx:Dictionary)->Array:
	var event:Dictionary=ctx.event
	var facts:Dictionary=ctx.facts
	var kind:=String(ctx.kind)
	var last:Dictionary=ctx.memory.get("last",{}) if ctx.memory.get("last") is Dictionary else {}
	if int(last.get("n",-1))!=int(ctx.n):return []
	var target:=String(event.get("target",event.get("who",ctx.main)))
	var others:=[target,String(ctx.main),String(event.get("actor",""))]
	var base:=_base_slots(ctx)
	var out:Array=[]
	var played:Dictionary=last.get("played",{}) if last.get("played") is Dictionary else {}
	for bit in played:
		var spec:Array=BIT_ASIDES.get(String(bit),[])
		if spec.is_empty():continue
		var info:Dictionary=played[bit]
		var situation:=String(spec[0])
		var star:=String(info.get("star",""))
		# A cost counted on someone's fingers is a grumble about the cost.
		if String(bit)=="count_fingers" and kind=="decree" and base.has("amount") and base.has("resource"):situation="cost_grumble"
		if situation=="stare_down" and base.has("enemy") and String((facts.get("envoy",{}) as Dictionary).get("civ",""))==String((war(facts)).get("enemy","-")):situation="stare_war"
		out.append(_option(ctx,situation,String(spec[1]),star,float(info.get("end",2.5)),base,last,2.0))
	var acts:Dictionary=last.get("acts",{}) if last.get("acts") is Dictionary else {}
	for act in acts:
		var spec:Array=ACT_ASIDES.get(String(act),[])
		if spec.is_empty():continue
		var seen:Dictionary=(acts[act] as Array)[0]
		var situation:=String(spec[0])
		var star:=String(seen.get("who",""))
		match String(act):
			"eye_food":
				if kind=="divine":situation="boon_hungry"
				elif kind=="gift":situation="gift_food_hungry"
				else:continue
				# The name in a hungry line is the one who got the food.
				star=String(event.get("target",ctx.main)) if kind=="divine" else star
			"lift_bundle":
				var food:=String(event.get("resource","")).to_lower()=="food"
				situation="gift_refused_hungry" if food and hungry(facts) else "gift_refused"
				star=String(ctx.main)
			"side_eye":
				if kind!="divine" or String(ctx.memory.get("last_envier",""))=="":continue
				star=String(event.get("target",""))
			"rub_belly":
				if String(event.get("action",""))!="penance":continue
				star=String(event.get("target",""))
			"face_fall","deflate_polite","storm_off","doze_off","catch_eye":
				pass
			"glum":
				if not (base.has("amount") and base.has("resource")):continue
		var who_speaks:=String(spec[1])
		# Lines about the one who got something are said by someone else.
		if String(act) in ["side_eye"]:who_speaks="envier"
		elif String(act) in ["eye_food"]:who_speaks="watcher"
		out.append(_option(ctx,situation,who_speaks,star,float(seen.get("end",2.5)),base,last,1.4,String(seen.get("who",""))))
	for o:Dictionary in out:(o.exclude as Array).append_array(others)
	return out.filter(func(o:Dictionary)->bool:return not o.is_empty())

static func _option(ctx:Dictionary,situation:String,speak:String,star:String,end:float,base:Dictionary,last:Dictionary,weight:float,seen_by:="")->Dictionary:
	var slots:=base.duplicate()
	var star_m:=_m(ctx,star)
	if not star_m.is_empty() and not bool(star_m.animal):slots["name"]=[String(star_m.given),"cast.%s.name" % star]
	var other:=String(last.get("other",""))
	var other_m:=_m(ctx,other)
	if not other_m.is_empty() and not bool(other_m.animal):slots["other"]=[String(other_m.given),"cast.%s.name" % other]
	if int(last.get("number",-1))>=2:slots["number"]=[_count(int(last.number)),String(last.get("number_from","event.text")),int(last.number)]
	var o:={"situation":situation,"weight":weight,"t":end+0.35,"slots":slots,"exclude":[]}
	match speak:
		"star":
			o["speaker"]=star
		"near":
			o["near"]=star;(o.exclude as Array).append(star)
		"struck":
			o["speaker"]=String(last.get("struck",""))
		"envier":
			o["speaker"]=String(ctx.memory.get("last_envier",""))
		"watcher":
			o["speaker"]=seen_by
		_:
			if star!="":(o.exclude as Array).append(star)
	# Someone answering a bit never mutters about themselves by name.
	if String(o.get("speaker",""))==star and star!="":slots.erase("name")
	return o

## What every line may cite: the facts and the event's own numbers.
static func _base_slots(ctx:Dictionary)->Dictionary:
	var event:Dictionary=ctx.event
	var facts:Dictionary=ctx.facts
	var base:={}
	if _num(facts.get("food_days",null)):base["food_days"]=[_count(int(facts.food_days)),"facts.food_days",int(facts.food_days)]
	var terms:Dictionary=event.get("terms",{}) if event.get("terms") is Dictionary else {}
	var cost:Dictionary=event.get("cost",{}) if event.get("cost") is Dictionary else {}
	if _num(terms.get("amount",null)):base["amount"]=[_count(roundi(float(terms.amount))),"event.terms.amount",roundi(float(terms.amount))]
	elif _num(cost.get("amount",null)):base["amount"]=[_count(roundi(float(cost.amount))),"event.cost.amount",roundi(float(cost.amount))]
	elif _num(event.get("amount",null)):base["amount"]=[_count(roundi(float(event.amount))),"event.amount",roundi(float(event.amount))]
	var resource:=String(terms.get("resource",cost.get("resource",event.get("resource","")))).to_lower()
	if resource=="fiber plants":resource="fibre"
	if not resource.is_empty():base["resource"]=[resource,"event.resource"]
	var envoy:Dictionary=facts.get("envoy",{}) if facts.get("envoy") is Dictionary else {}
	if String(envoy.get("civ",""))!="":base["envoy_civ"]=[String(envoy.civ),"facts.envoy.civ"]
	var fight:=war(facts)
	if String(fight.get("enemy",""))!="":base["enemy"]=[String(fight.enemy),"facts.war.enemy"]
	var left:=_forgotten(ctx)
	if String(left.get("thing",""))!="" and String(left.thing)!="bearer":base["thing"]=[String(left.thing),"cast.%s.stance" % String(event.get("who",ctx.main))]
	return base

## Says it: a bold bystander who fits, in their own manner, filling only
## from the slots; a line or situation said lately is not said again.
static func _say(ctx:Dictionary,option:Dictionary)->Dictionary:
	var rng:RandomNumberGenerator=ctx.rng
	var facts:Dictionary=ctx.facts
	var tags:Array=facts.get("era_tags",[]) if facts.get("era_tags") is Array else []
	var situation:=String(option.situation)
	if not Asides.allowed(situation,tags):return {}
	var n:=int(ctx.get("aside_n",0))
	var said_before:Dictionary=ctx.memory.get("aside_situations",{}) if ctx.memory.get("aside_situations") is Dictionary else {}
	if not _rested_since(said_before.get(situation,null),facts,n,SITUATION_REST_DAYS,SITUATION_REST_EVENTS):return {}
	var exclude:Array=option.get("exclude",[])
	var only:=String(option.get("speaker",""))
	if option.has("speaker") and only.is_empty():return {}
	var candidates:Array=[]
	for m:Dictionary in _people(ctx):
		if String(m.kind) in ["envoy","guard","bearer","attendant"] or String(m.role)=="main":continue
		# Nobody carries the muttering: two of the last eight is enough.
		if _mutter_count(ctx,m)>=2:continue
		if not only.is_empty():
			if String(m.key)!=only:continue
		elif String(m.key) in exclude:continue
		if dare(m)<DARE_MIN:continue
		candidates.append(m)
	if candidates.is_empty():return {}
	var order:=_shuffled(rng,candidates)
	var near:=_m(ctx,String(option.get("near","")))
	if not near.is_empty():
		order.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return absf(_where(a)-_where(near))<absf(_where(b)-_where(near)) if not is_equal_approx(absf(_where(a)-_where(near)),absf(_where(b)-_where(near))) else int(a.index)<int(b.index))
		order=order.slice(0,2)
	var slots:Dictionary=option.get("slots",{})
	var flat:={}
	for key in slots:flat[key]=String((slots[key] as Array)[0])
	var recent:Dictionary=ctx.memory.get("aside_lines",{}) if ctx.memory.get("aside_lines") is Dictionary else {}
	for m:Dictionary in order:
		# Their own manner first; the plain speech of the hall after.
		var manner:=Asides.family(m)
		var lines:Array=_shuffled(rng,Asides.own_lines(situation,manner))
		if manner!="child":lines+=_shuffled(rng,Asides.own_lines(situation,"plain")) if manner!="plain" else []
		for template in lines:
			var key:="%s|%s" % [situation,template]
			if not _rested_since(recent.get(key,null),facts,n,LINE_REST_DAYS,LINE_REST_EVENTS):continue
			var line:=String(template)
			# Nobody says their own name about themselves.
			if line.contains("{name}") and String(m.key)==_key_of_name(ctx,String(flat.get("name",""))):continue
			var text:=Asides.render(line,flat)
			if text.is_empty() or not _era_ok(text,tags) or Asides.word_count(text)>Asides.MAX_WORDS:continue
			var cites:Array=(option.get("cites",[]) as Array).duplicate()
			for slot in Asides.slots_in(line):cites.append(String((slots[slot] as Array)[1]))
			var t:=clampf(float(option.t),1.2,5.0) if option.has("t") else 3.0+rng.randf()*0.5
			# Performed small and sidelong, in their people's babble.
			var sound:={"name":"babble_mutter","gain":0.5,"words":Asides.word_count(text),"people":String(m.people),"who":String(m.key),"glyph":""}
			return {"t":snappedf(t,0.01),"who":String(m.key),"text":text,"cites":cites,"situation":situation,"template":key,"bubble":"mutter","sound":sound}
	return {}

## How many of the last eight muttered lines this person said.
static func _mutter_count(ctx:Dictionary,m:Dictionary)->int:
	var recent:Array=ctx.memory.get("mutterers",[]) if ctx.memory.get("mutterers") is Array else []
	var id:=String(m.name)
	var n:=0
	for who in recent:
		if String(who)==id:n+=1
	return n

static func _key_of_name(ctx:Dictionary,given:String)->String:
	if given.is_empty():return ""
	for m:Dictionary in ctx.cast:
		if String(m.given)==given:return String(m.key)
	return ""

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
		if not entry is Dictionary:continue
		var e:Dictionary=entry
		var pid:=int(e.get("person_id",0))
		if pid==0 and e.get("person") is Dictionary:pid=int((e.person as Dictionary).get("person_id",0))
		if pid==person_id:return String(e.get("key",""))
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

## An order as court_commands.gd decided it. A law the god lays down is a
## decree, issued.
static func event_from_command(result:Dictionary,cast:Array,speaker_id:=0)->Dictionary:
	if String(result.get("verb",""))=="law":return {"kind":"decree","issued":true,"accepted":true,"who":"main","reaction":"neutral"}
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

## An audience answered (audience_hall.resolve): a gift taken or turned away;
## a petition decreed, promised ("consider it"), asked for patience or
## dismissed; a foreign request granted (what it costs our stores) or
## refused; tribute paid; a messenger thanked or rewarded.
static func event_from_resolution(audience:Dictionary,option_id:String,result:Dictionary)->Dictionary:
	var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
	var reaction:=String(result.get("reaction","neutral"))
	if String(audience.get("kind",""))=="gift":
		return {"kind":"gift","accepted":option_id in ["accept","accept_return"],"resource":String(terms.get("resource","")),"amount":terms.get("amount",0),"who":"main","reaction":reaction}
	match option_id:
		"promise","patience":return {"kind":"promise","who":"main","reaction":reaction}
		"dismiss","rebuke":return {"kind":"dismiss","who":"main","reaction":reaction if reaction!="neutral" else "offended"}
	var accepted:=reaction in ["delighted","pleased"] or option_id in ["decree","grant","grant_half","pay","reward","reward_scouts","thank","apologise","welcome"]
	var event:={"kind":"decree","accepted":accepted,"who":"main","reaction":reaction,"option":option_id}
	# What it costs the people: our stores paid out.
	if not terms.is_empty() and option_id in ["grant","pay"]:event["cost"]={"resource":String(terms.get("resource","")),"amount":terms.get("amount",0)}
	elif not terms.is_empty() and option_id=="grant_half":event["cost"]={"resource":String(terms.get("resource","")),"amount":roundi(float(terms.get("amount",0))*0.5)}
	if result.get("cost") is Dictionary:event["cost"]=(result.cost as Dictionary).duplicate()
	return event

## The god makes the hall wait (audience_hall.defer).
static func event_wait(who_key:="main")->Dictionary:
	return {"kind":"wait","who":who_key}

## Someone leaves the stage in the engine's style (audience_modal.exit_style_for),
## with how they took the audience (the result's reaction).
static func event_from_exit(who_key:String,style:String,reaction:="")->Dictionary:
	return {"kind":"exit","who":who_key,"style":style,"reaction":reaction}

## The fact sheet the director reads, from the one ledger: the day, the
## stores' days of food, a running sickness, a war, the season, the people's
## dread and love of the god, what the people know, and for a foreign
## audience the envoy's people, their temper's sources and their gift.
## Reads only; changes nothing.
static func facts_now(audience:Dictionary={})->Dictionary:
	var facts:={}
	if Engine.get_main_loop()==null:return facts
	var hall:GDScript=load("res://scripts/audience_hall.gd")
	var cv:=preload("res://scripts/character_voice.gd")
	var c:Dictionary=hall.call("conditions")
	facts["day"]=int(GameState.elapsed_days)
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
		var leader:Dictionary=ForeignDiplomacy.leader(civ_id)
		var character:Dictionary=leader.get("character",{}) if leader.get("character") is Dictionary else {}
		var foreign:Dictionary=(load("res://scripts/divine_regard.gd") as GDScript).call("foreign_regard",civ_id)
		facts["envoy"]={"civ":String(audience.get("civ_name","")),"civ_id":civ_id,"kind":String(audience.get("kind","")),
			"days_waiting":maxi(0,int(GameState.elapsed_days)-int(audience.get("arrived_day",GameState.elapsed_days))),
			"their_food_days":roundi(float(their.get("food_days",30.0))),"temperament":String(leader.get("temperament","")),
			"trait":String(character.get("trait","")),"their_dread":float(foreign.get("dread",0.0))}
		if String(audience.get("kind",""))=="gift" and audience.get("terms") is Dictionary:facts["gift"]=(audience.terms as Dictionary).duplicate()
	return facts

# =============================================================================
# The stage's own shapes (docs/COURT_STAGE_3D.md section 5)
# =============================================================================

## The fact sheet in the director's words, from either shape: the stage's
## (stores_days, hungry, sick, at_war, love, dread, offer) or facts_now()'s.
## A plain flag without its figure shows, but no line cites a number for it.
static func normal_facts(facts:Dictionary)->Dictionary:
	var out:=facts.duplicate()
	if not out.has("food_days") and _num(facts.get("stores_days",null)):out["food_days"]=roundi(float(facts.stores_days))
	if not out.has("people_dread") and _num(facts.get("dread",null)):out["people_dread"]=float(facts.dread)
	if not out.has("people_love") and _num(facts.get("love",null)):out["people_love"]=float(facts.love)
	# A sickness or a war given only as a flag counts as present, unnamed.
	if not out.get("sickness") is Dictionary:
		if facts.get("sick") is Dictionary:out["sickness"]=(facts.sick as Dictionary).duplicate()
		elif facts.get("sick",false) is bool and bool(facts.get("sick",false)):out["sickness"]={"present":true}
	if not out.get("war") is Dictionary:
		if facts.get("at_war") is Dictionary:out["war"]=(facts.at_war as Dictionary).duplicate()
		elif facts.get("at_war",false) is bool and bool(facts.get("at_war",false)):out["war"]={"present":true}
	if not out.get("gift") is Dictionary and facts.get("offer") is Dictionary and String((facts.offer as Dictionary).get("resource",""))!="":out["gift"]=(facts.offer as Dictionary).duplicate()
	return out

## The cast in the director's words, from either shape. A stage entry
## {key, role, person, figure, mood} is read through cast_member(); the
## envoy's company are their guard and, when a gift is offered, its bearer;
## the envoy's temper is read from the fact sheet (envoy_temper).
## voices: person id -> lifelong voice model, read from the voice registry.
static func normal_cast(cast:Array,facts:Dictionary={},voices:Dictionary={})->Array:
	var attendants:=0
	for entry in cast:
		if entry is Dictionary and String((entry as Dictionary).get("role",""))=="attendant":attendants+=1
	var offer:=facts.get("gift") is Dictionary or facts.get("offer") is Dictionary
	var envoy_facts:Dictionary=facts.get("envoy",{}) if facts.get("envoy") is Dictionary else {}
	var out:Array=[]
	var seen_attendants:=0
	for entry in cast:
		if not entry is Dictionary:continue
		var e:Dictionary=entry
		if not e.get("person") is Dictionary:
			if String(e.get("kind",""))=="envoy" and String(e.get("temper",""))=="" and not envoy_facts.is_empty():
				e=e.duplicate();e["temper"]=envoy_temper(envoy_facts)
			if String(e.get("kind","")) in ["envoy","guard","bearer","attendant"] and not e.has("people") and String(envoy_facts.get("civ_id",""))!="":
				e=e.duplicate();e["people"]=String(envoy_facts.civ_id)
			out.append(e);continue
		var person:Dictionary=e.person
		var extra:={"key":String(e.get("key","")),"role":String(e.get("role","court"))}
		for field in ["kind","voice","stance","x","pos","name","office","age","temper","gifted","people"]:
			if e.has(field):extra[field]=e[field]
		var figure:Variant=e.get("figure",null)
		if figure is Node3D and is_instance_valid(figure):
			var stance:Variant=(figure as Object).get("stance")
			if not extra.has("stance") and stance!=null:extra["stance"]=String(stance)
			if not extra.has("x") and not extra.has("pos") and (figure as Node3D).is_inside_tree():extra["pos"]=(figure as Node3D).global_position.x
		if not extra.has("kind"):
			match String(extra.role):
				"main":
					# The audience's transient envoy has an appearance owner but
					# no person.role. A foreign prisoner outside an envoy audience
					# keeps their identity without becoming an invented diplomat.
					var owner:=String(person.get("appearance_civ_id",person.get("civilization_id","player")))
					if String(person.get("role",""))=="envoy" or (not owner.is_empty() and owner!="player" and owner==String(envoy_facts.get("civ_id",""))):extra["kind"]="envoy"
				"attendant":
					if attendants==1:extra["kind"]="bearer" if offer else "guard"
					else:extra["kind"]=["guard","bearer"][seen_attendants] if seen_attendants<2 else "attendant"
					seen_attendants+=1
		if String(extra.get("kind",""))=="envoy" and not extra.has("temper"):extra["temper"]=envoy_temper(envoy_facts)
		if String(extra.get("kind","")) in ["envoy","guard","bearer","attendant"] and String(envoy_facts.get("civ_id",""))!="":extra["people"]=String(envoy_facts.civ_id)
		var pid:=int(person.get("person_id",0))
		if not extra.has("voice") and voices.has(pid):extra["voice"]=String(voices[pid])
		out.append(cast_member(person,extra))
	return out

## The event in the director's words, from either shape: the stage's kinds
## ("god", "enter", "defer", "divine" with only action and response, an
## envoy's punishment) and an engine result passed whole as event.result.
static func normal_event(event:Dictionary,cast:Array)->Dictionary:
	var out:=event.duplicate()
	var kind:=String(event.get("kind",""))
	kind=String({"god":"god_speaks","enter":"summon","order":"command","defer":"wait"}.get(kind,kind))
	out["kind"]=kind
	var speaker_id:=0
	var main_kind:=""
	for entry in cast:
		if entry is Dictionary and String((entry as Dictionary).get("key",""))=="main":
			speaker_id=int((entry as Dictionary).get("person_id",0));main_kind=String((entry as Dictionary).get("kind",""))
	var result:Dictionary=event.get("result",{}) if event.get("result") is Dictionary else {}
	if not result.is_empty():
		match kind:
			"divine":out.merge(event_from_divine(result,cast,speaker_id),true)
			"command":out.merge(event_from_command(result,cast,speaker_id),true)
		out.erase("result")
	kind=String(out.kind)
	if kind=="divine":
		if not out.has("target"):out["target"]="main"
		var action:=String(out.get("action",""))
		if action.begins_with("envoy_"):
			# The god's hand on an envoy is an order the guards carry out.
			out["kind"]="command";out["verb"]=String({"envoy_maim":"maim","envoy_flog":"maim","envoy_kill":"kill","envoy_detain":"detain","envoy_exile":"exile"}.get(action,"detain"))
			out["stage"]=String(out.verb);out["actor"]="";out["obedience"]="obey";out["executed"]=true
		elif action=="terrify" and String(out.target)=="main" and main_kind=="envoy":out["kind"]="terrify_envoy"
	if String(out.kind)=="gift" and not out.has("accepted"):out["accepted"]=true
	if String(out.kind) in ["summon","wait","promise","dismiss","decree","exit"] and not out.has("who"):out["who"]="main"
	return out

## Lowers the director's beats into the stage's primitives: play (a clip,
## its fallback in the figures' set, held or not), mood (the acting
## layer's vector, the figures' mood name and the face), look_at (the god,
## the god above, a person's key, or away), shot (camera) and hush (room).
## Every primitive keeps the director's act in args.beat (and its other
## args: thing, walk, from, gift), so the acting layer may play the act by
## name once it has a clip for it.
const MOOD_VECTOR:={"warm":{"joy":0.7},"afraid":{"fear":0.8},"defiant":{"anger":0.5,"scorn":0.3},"grieved":{"fear":0.2,"tired":0.6},"neutral":{}}
static func lower(list:Array)->Array:
	var out:Array=[]
	for beat:Dictionary in list:
		var who:=String(beat.who)
		var act:=String(beat.act)
		var args:Dictionary=beat.get("args",{})
		var t:=float(beat.t)
		if who=="camera":
			var shot:=args.duplicate();shot["name"]=act;shot["beat"]=act
			out.append({"t":t,"who":who,"act":"shot","args":shot});continue
		if beat.get("sound") is Dictionary:
			var heard:Dictionary=(beat.sound as Dictionary).duplicate()
			out.append({"t":t,"who":who,"act":"sound","args":heard})
		if who=="room" or who=="exec":
			out.append({"t":t,"who":who,"act":act,"args":args.duplicate()});continue
		if act=="bubble":
			out.append({"t":t,"who":who,"act":"bubble","args":args.duplicate()});continue
		var p:=performance(beat)
		var mood:=String(p.mood)
		if mood!="" or not (p.face as Dictionary).is_empty():
			var vector:Dictionary=(MOOD_VECTOR.get(mood,{}) as Dictionary).duplicate()
			out.append({"t":t,"who":who,"act":"mood","args":{"vector":vector,"name":mood,"face":p.face,"dur":float(p.dur),"hold":bool(p.hold),"beat":act}})
		var play:={"clip":act,"fallback":String(p.clip),"hold":bool(p.hold),"speed":float(p.speed),"dur":float(p.dur),"blend":0.25,"beat":act,"at":String(p.at),"number":args.get("number",null)}
		for extra in ["thing","walk","from","gift","because","routine"]:
			if args.has(extra):play[extra]=args[extra]
		out.append({"t":t,"who":who,"act":"play","args":play})
		match String(p.look):
			"god","god_up":out.append({"t":t,"who":who,"act":"look_at","args":{"target":String(p.look),"weight":0.8,"beat":act,"dur":float(p.dur),"hold":bool(p.hold)}})
			"at":
				if String(p.at)!="":out.append({"t":t,"who":who,"act":"look_at","args":{"target":String(p.at),"weight":0.8,"beat":act,"dur":float(p.dur),"hold":bool(p.hold)}})
			"away":out.append({"t":t,"who":who,"act":"look_at","args":{"target":"away","weight":0.6,"beat":act,"dur":float(p.dur),"hold":bool(p.hold)}})
	return out

# =============================================================================
# The director as the stage's object
# =============================================================================

## Presentation memory for one court: which bits have rested how long, who
## dozes, what played last, which lines were said when, the speakers' voice
## models. Never saved.
var stage_memory:Dictionary={}

func beats(event:Dictionary,cast:Array,facts:Dictionary,rng_seed:int)->Array:
	_learn_voices(cast)
	return lower(beats_for(event,cast,facts,rng_seed,stage_memory))

## Call after beats() for the same event, so a line can answer what played.
## Nothing when muttering is turned off (CourtDirector.mutters_enabled, or
## the stage's own CourtStage.mutters_enabled where it has one).
func asides(event:Dictionary,facts:Dictionary,cast:Array,rng_seed:int)->Array:
	var out:Array=[]
	if not mutters_enabled or not _stage_allows_mutters():return out
	for line:Dictionary in asides_for(event,facts,cast,rng_seed,stage_memory):
		var said:=line.duplicate()
		said["act"]="aside";said["args"]={"text":String(line.text),"bubble":"mutter","sound":line.get("sound",{})}
		out.append(said)
	return out

static func _stage_allows_mutters()->bool:
	if not ResourceLoader.exists("res://scripts/hud/court_stage.gd"):return true
	var stage:Variant=load("res://scripts/hud/court_stage.gd")
	if stage==null:return true
	var flag:Variant=(stage as Object).get("mutters_enabled")
	return not (flag is bool and not bool(flag))

## Whether the sleeper is asleep now (the stage resumes their doze).
func sleeper(cast:Array,facts:Dictionary)->String:
	return asleep(normal_cast(cast,normal_facts(facts)),normal_facts(facts),stage_memory)

## Each speaker's lifelong voice model, read (never assigned) from the voice
## registry (character_voice.gd): a person who has not spoken yet speaks
## plainly until they have one.
func _learn_voices(cast:Array)->void:
	if Engine.get_main_loop()==null:return
	if not stage_memory.get("voices") is Dictionary:stage_memory["voices"]={}
	var registry:Dictionary=preload("res://scripts/character_voice.gd").registry
	var models:Dictionary=registry.get("models",{}) if registry.get("models") is Dictionary else {}
	for entry in cast:
		if not entry is Dictionary or not (entry as Dictionary).get("person") is Dictionary:continue
		var pid:=int(((entry as Dictionary).person as Dictionary).get("person_id",0))
		if pid>0 and models.has("person:%d" % pid):(stage_memory.voices as Dictionary)[pid]=String(models["person:%d" % pid])

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
	if args.has("thing"):text=text.replace("{thing}",String(args.thing) if String(args.thing)!="bearer" else "bearer")
	if args.has("style"):text=text.replace("{style}",String(args.style))
	if beat.get("sound") is Dictionary and String(beat.who)!="room":text+="  [sound: %s%s]" % [String(beat.sound.name),", glyph %s" % beat.sound.glyph if String(beat.sound.get("glyph",""))!="" else ""]
	if String(beat.who)=="room" and String(beat.act)=="hush":text+="  [sound: murmur cut]"
	if args.has("strength"):text=text.replace("{strength}",str(args.strength))
	if args.has("number"):text+=" (\"%d?\")" % int(args.number)
	var who:=String(beat.who)
	if who=="camera":return "[camera] "+text
	if who=="room":return "[room] "+text
	return ("%s%s" if text.begins_with("'") else "%s %s") % [String(names.get(who,who)),text]

static func screenplay(event:Dictionary,cast:Array,facts:Dictionary,rng_seed:int,memory:Dictionary={})->String:
	var lines:PackedStringArray=PackedStringArray()
	var list:=beats_for(event,cast,facts,rng_seed,memory)
	var said:=asides_for(event,facts,cast,rng_seed,memory)
	for beat:Dictionary in list:
		lines.append("  %5.2fs  %-11s %s" % [float(beat.t),String(beat.phase),describe(beat,cast)])
	var names:={}
	for entry in cast:
		if entry is Dictionary:names[String(entry.get("key",""))]=String(entry.get("name",""))
	for line:Dictionary in said:
		lines.append("  %5.2fs  %-11s %s, under their breath: \"%s\"" % [float(line.t),"aside",String(names.get(String(line.who),String(line.who))),String(line.text)])
	return "\n".join(lines)
