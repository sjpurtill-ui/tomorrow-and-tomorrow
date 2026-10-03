extends RefCounted
## THE COURT'S EXECUTION SOUNDS: comic, juicy, synthesized (docs: court_night
## EXECUTIONS.md). Cartoon gore in sound: SPLAT, CRACK, a hollow bonk, the
## pot lid's clank, the fire's WHOOMPH, the neck's BOING, crunches and
## squelches, a bone's pop, the saw's rasp, a long rip, the cauldron's bubbles,
## the bear's gulp and burp, the elephant, the pigs, the ox, the whistle and
## the far-off splat, the arrows, the muskets, the cannon, the geyser and the
## patter on the front row, the retching, the groan, the lone clap, and the
## musician's drum roll before and the hit on the punchline.
##
## The sounds must carry the joke on their own: with the gore setting "mild"
## the picture cuts away and only these are heard. So each is a little larger
## than life, and each act's timeline (ACTS) leaves the beat of silence where
## the laugh goes.
##
## make(name, variant) -> samples; stream(name, variant) -> AudioStreamWAV.
## CUES: every name L can cue ({variants, db, kind}). ACTS: the sound track of
## an act, [{t, cue, who, db?, variant?}] (t in seconds from the act's own
## moment, negative before it; who a role: executioner, victim, cook, dog,
## room, musician, front_row, flatterer). court_sound.gd play_act() plays one.
## Pure and deterministic; safe on a worker thread.

const Synth:=preload("res://scripts/hud/court_synth.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")
const Music:=preload("res://scripts/hud/court_music.gd")
const RATE:=22050

const CUES:={
	# impacts
	"gore_splat":{"variants":3,"db":-5.0,"kind":"gore"},
	"gore_crack":{"variants":2,"db":-4.0,"kind":"gore"},
	"bonk":{"variants":3,"db":-7.0,"kind":"thing"},
	"lid_clank":{"variants":2,"db":-8.0,"kind":"thing"},
	"gore_chop":{"variants":2,"db":-5.0,"kind":"gore"},
	"splat_distant":{"variants":2,"db":-10.0,"kind":"gore"},
	# fire, spring, flight
	"whoomph":{"variants":2,"db":-5.0,"kind":"fire"},
	"boing":{"variants":2,"db":-7.0,"kind":"thing"},
	"whistle_long":{"variants":2,"db":-11.0,"kind":"thing"},
	"head_whistle":{"variants":2,"db":-12.0,"kind":"thing"},
	"swing_whoosh":{"variants":3,"db":-8.0,"kind":"thing"},
	# crunches, squelches, pops, saws, rips
	"crunch":{"variants":3,"db":-7.0,"kind":"gore"},
	"crunch_loop":{"variants":2,"db":-8.0,"kind":"gore"},
	"wheel_crunch":{"variants":1,"db":-8.0,"kind":"gore"},
	"squelch":{"variants":3,"db":-7.0,"kind":"gore"},
	"bone_pop":{"variants":3,"db":-7.0,"kind":"gore"},
	"saw_rasp":{"variants":1,"db":-10.0,"kind":"thing"},
	"rip":{"variants":2,"db":-8.0,"kind":"gore"},
	# liquids
	"bubbling":{"variants":1,"db":-12.0,"kind":"thing"},
	"pot_plop":{"variants":2,"db":-7.0,"kind":"thing"},
	"spoon_stir":{"variants":1,"db":-13.0,"kind":"thing"},
	"blood_geyser":{"variants":2,"db":-7.0,"kind":"gore"},
	"blood_patter":{"variants":2,"db":-10.0,"kind":"gore"},
	"blink":{"variants":1,"db":-14.0,"kind":"thing"},
	# beasts
	"bear_swallow":{"variants":1,"db":-6.0,"kind":"animal"},
	"burp":{"variants":2,"db":-6.0,"kind":"animal"},
	"elephant_trumpet":{"variants":2,"db":-6.0,"kind":"animal"},
	"pig_swarm":{"variants":1,"db":-8.0,"kind":"animal"},
	"ox_low":{"variants":2,"db":-9.0,"kind":"animal"},
	"dog_snarl":{"variants":2,"db":-9.0,"kind":"animal"},
	"drag":{"variants":2,"db":-12.0,"kind":"thing"},
	"bone_drop":{"variants":2,"db":-10.0,"kind":"thing"},
	# weapons
	"arrow_volley":{"variants":1,"db":-7.0,"kind":"thing"},
	"arrow_thunk":{"variants":3,"db":-8.0,"kind":"thing"},
	"musket_volley":{"variants":2,"db":-4.0,"kind":"thing"},
	"cannon_boom":{"variants":1,"db":-3.0,"kind":"thing"},
	"axe_thunk":{"variants":2,"db":-6.0,"kind":"thing"},
	"axe_clang":{"variants":2,"db":-8.0,"kind":"thing"},
	"axe_pull":{"variants":2,"db":-10.0,"kind":"thing"},
	"head_roll":{"variants":2,"db":-9.0,"kind":"thing"},
	# people
	"windup":{"variants":2,"db":-10.0,"kind":"voice"},
	"retch":{"variants":2,"db":-9.0,"kind":"voice"},
	"crowd_groan":{"variants":2,"db":-9.0,"kind":"voice"},
	"lone_clap":{"variants":2,"db":-11.0,"kind":"thing"},
	"ow":{"variants":2,"db":-11.0,"kind":"voice"},
	# the musician
	"drum_roll":{"variants":2,"db":-9.0,"kind":"music"},
	"log_roll":{"variants":1,"db":-10.0,"kind":"music"},
	"punch_drum":{"variants":2,"db":-8.0,"kind":"music"},
	"punch_cymbal":{"variants":1,"db":-8.0,"kind":"music"},
	"punch_log":{"variants":1,"db":-9.0,"kind":"music"},
	# for the other acts
	"boulder_roll":{"variants":2,"db":-8.0,"kind":"thing"},
	"crumble":{"variants":1,"db":-10.0,"kind":"thing"},
	"smoke_poof":{"variants":1,"db":-12.0,"kind":"thing"},
	"spear_thunk":{"variants":3,"db":-7.0,"kind":"thing"},
	"hide_thwap":{"variants":1,"db":-9.0,"kind":"thing"},
	"stone_clack":{"variants":3,"db":-8.0,"kind":"thing"},
	"dig":{"variants":2,"db":-11.0,"kind":"thing"},
	"hoof":{"variants":2,"db":-9.0,"kind":"animal"},
	"stampede":{"variants":1,"db":-6.0,"kind":"animal"},
	"bones_rattle":{"variants":2,"db":-9.0,"kind":"thing"},
	"rope_creak":{"variants":2,"db":-11.0,"kind":"thing"},
	"slurp":{"variants":2,"db":-11.0,"kind":"voice"},
	"sprinkle":{"variants":1,"db":-14.0,"kind":"thing"},
	"slow_squelch":{"variants":1,"db":-9.0,"kind":"gore"},
	"bear_roar":{"variants":1,"db":-5.0,"kind":"animal"},
	"spit":{"variants":1,"db":-9.0,"kind":"animal"},
	"sizzle":{"variants":1,"db":-8.0,"kind":"thing"},
	"ratchet":{"variants":2,"db":-12.0,"kind":"thing"},
	"catapult_thwack":{"variants":1,"db":-5.0,"kind":"thing"},
	"tooth_tink":{"variants":1,"db":-12.0,"kind":"thing"},
	"basket_thump":{"variants":1,"db":-9.0,"kind":"thing"},
	"musket_cock":{"variants":1,"db":-12.0,"kind":"thing"},
	"fuse":{"variants":1,"db":-13.0,"kind":"thing"},
	"wipe":{"variants":1,"db":-15.0,"kind":"thing"},
	"flick":{"variants":1,"db":-10.0,"kind":"gore"},
	# K's clips (acts 2, 4, 10)
	"club_tap":{"variants":2,"db":-13.0,"kind":"thing"},
	"face_splash":{"variants":1,"db":-10.0,"kind":"gore"},
	"lid_pat":{"variants":2,"db":-13.0,"kind":"thing"},
	"tug":{"variants":3,"db":-11.0,"kind":"thing"},
	"slip":{"variants":3,"db":-14.0,"kind":"thing"},
}

## Each act's sound, as L's scene will play it (seconds from the act's moment;
## negative before it). "punch" and "roll" are the musician's: play_act()
## turns them into what the people can play (a cymbal only once they have
## them, a drum, else hands on a log). An entry may carry "if": "hungry" or
## "not_hungry" (the stores really low, from the fact sheet). The 25 acts of
## EXECUTIONS.md, by number:
##   1 boulder_drop  2 club_home_run  3 into_the_fire  4 dog_dinner
##   5 spear_pincushion  6 stoned_by_court  7 buried_to_neck  8 trampled_by_herd
##   9 pig_pen  10 three_swing_beheading  11 neck_stretch_hanging
##   12 quartered_by_oxen  13 sawn_in_half  14 boiled_in_pot  15 the_stake
##   16 volley_of_arrows  17 bear_pit  18 elephant_foot  19 wheel_and_hill
##   20 molten_bronze  21 catapult_launch  22 great_stone  23 falling_blade
##   24 firing_squad  25 cannon_mouth
const ACT_NUMBERS:=["","boulder_drop","club_home_run","into_the_fire","dog_dinner","spear_pincushion","stoned_by_court",
	"buried_to_neck","trampled_by_herd","pig_pen","three_swing_beheading","neck_stretch_hanging","quartered_by_oxen",
	"sawn_in_half","boiled_in_pot","the_stake","volley_of_arrows","bear_pit","elephant_foot","wheel_and_hill",
	"molten_bronze","catapult_launch","great_stone","falling_blade","firing_squad","cannon_mouth"]
## The room's own noise, hushed when dread is high (a terrified hall is silent).
const ROOM_NOISE:=["room_gasp","crowd_groan","lone_clap","snort_laugh"]
const ACTS:={
	# 2. Club home run: the wind-up, CRACK, the head's arc into the pot, the
	# cook looks, stirs, puts the lid on. Ba-dum.
	"club_home_run":[
		# timed to K's clip (EXEC_PLANS): the impact at 3.62 s is t = 0
		{"t":-3.17,"cue":"club_tap","who":"executioner","variant":0},
		{"t":-2.67,"cue":"club_tap","who":"executioner","variant":1},
		{"t":-2.4,"cue":"roll","who":"musician"},
		{"t":-0.95,"cue":"windup","who":"executioner"},
		{"t":-0.12,"cue":"swing_whoosh","who":"executioner","variant":0},
		{"t":0.0,"cue":"gore_crack","who":"victim"},
		{"t":0.06,"cue":"head_whistle","who":"victim"},
		{"t":1.38,"cue":"pot_plop","who":"cook"},
		{"t":1.43,"cue":"face_splash","who":"cook"},
		{"t":1.75,"cue":"room_gasp","who":"room"},
		{"t":2.38,"cue":"faint_thump","who":"victim","variant":0},
		{"t":3.98,"cue":"lid_clank","who":"cook","variant":0},
		{"t":4.26,"cue":"lid_pat","who":"cook","variant":0},
		{"t":4.38,"cue":"lone_clap","who":"flatterer"},
		{"t":4.53,"cue":"lid_pat","who":"cook","variant":1},
		{"t":4.66,"cue":"punch","who":"musician"},
		{"t":4.75,"cue":"retch","who":"front_row","variant":1},
	],
	# 10. Three-swing beheading: stuck in the block; bounced off; off it pops,
	# rolls to face the god, blinks; the geyser soaks the front row.
	"three_swing_beheading":[
		# timed to K's clip (EXEC_PLANS): the third swing's chop at 8.7 s is t = 0;
		# the roll comes before the first swing
		{"t":-9.15,"cue":"roll","who":"musician"},
		{"t":-8.28,"cue":"spit","who":"executioner","db":-3.0},
		{"t":-6.85,"cue":"swing_whoosh","who":"executioner","variant":1},
		{"t":-6.75,"cue":"axe_thunk","who":"executioner","variant":0},
		{"t":-6.25,"cue":"strain","who":"executioner","variant":0},
		{"t":-6.05,"cue":"axe_pull","who":"executioner","variant":1},
		{"t":-5.85,"cue":"strain","who":"executioner","variant":1},
		{"t":-3.28,"cue":"swing_whoosh","who":"executioner","variant":2},
		{"t":-3.2,"cue":"axe_clang","who":"executioner","variant":0},
		{"t":-2.85,"cue":"ow","who":"executioner","variant":0},
		{"t":-0.12,"cue":"swing_whoosh","who":"executioner","variant":0},
		{"t":0.0,"cue":"gore_chop","who":"victim","variant":0},
		{"t":0.04,"cue":"bone_pop","who":"victim","variant":1},
		{"t":0.05,"cue":"blood_geyser","who":"victim","variant":0},
		{"t":0.35,"cue":"room_gasp","who":"room"},
		{"t":0.8,"cue":"blood_patter","who":"front_row","variant":0},
		{"t":1.45,"cue":"head_roll","who":"victim","variant":1},
		{"t":2.2,"cue":"blink","who":"victim"},
		{"t":2.3,"cue":"lone_clap","who":"flatterer","variant":1},
		{"t":2.42,"cue":"punch","who":"musician"},
		{"t":2.6,"cue":"retch","who":"front_row","variant":0},
	],
	# 4. Dog dinner: dragged behind the windbreak, snarls, loud crunching; the
	# dog trots back, drops a thighbone at the god's feet, wags.
	"dog_dinner":[
		# timed to K's clip (EXEC_PLANS): the grab is t = 0
		{"t":-2.2,"cue":"roll","who":"musician"},
		{"t":0.0,"cue":"dog_snarl","who":"dog","variant":0},
		{"t":0.6,"cue":"faint_thump","who":"victim","variant":1},
		{"t":2.6,"cue":"dog_snarl","who":"dog","variant":1,"db":-3.0},
		{"t":2.7,"cue":"tug","who":"victim","variant":0},
		{"t":3.12,"cue":"tug","who":"victim","variant":1},
		{"t":3.52,"cue":"tug","who":"victim","variant":2},
		{"t":3.8,"cue":"slip","who":"victim","variant":0},
		{"t":4.0,"cue":"slip","who":"victim","variant":1},
		{"t":4.15,"cue":"slip","who":"victim","variant":2},
		{"t":4.35,"cue":"drag","who":"victim","variant":0},
		{"t":5.4,"cue":"drag","who":"victim","variant":1,"db":-6.0},
		{"t":6.8,"cue":"crunch","who":"dog","variant":1,"db":-5.0},
		{"t":7.0,"cue":"crunch","who":"dog","variant":0},
		{"t":7.25,"cue":"crowd_groan","who":"room","variant":0},
		{"t":7.6,"cue":"crunch","who":"dog","variant":1},
		{"t":8.2,"cue":"crunch","who":"dog","variant":2},
		{"t":8.75,"cue":"crunch","who":"dog","variant":0,"db":-5.0},
		{"t":9.6,"cue":"paws","who":"dog"},
		{"t":10.6,"cue":"bone_drop","who":"dog","variant":0},
		{"t":10.85,"cue":"dog_thump","who":"dog"},
		{"t":11.0,"cue":"punch","who":"musician"},
	],
	# 1. Boulder drop: tipped off the log, SPLAT; a feeble wave; rolled off, the
	# person peeled off the floor like a hide, rolled up and carried out.
	"boulder_drop":[
		{"t":-3.4,"cue":"roll","who":"musician"},
		{"t":-1.6,"cue":"strain","who":"executioner"},
		{"t":-1.1,"cue":"boulder_roll","who":"executioner","variant":0},
		{"t":-0.2,"cue":"swing_whoosh","who":"victim","variant":0},
		{"t":0.0,"cue":"gore_splat","who":"victim","variant":2},
		{"t":0.35,"cue":"room_gasp","who":"room"},
		{"t":1.8,"cue":"rustle","who":"victim","db":-4.0},
		{"t":2.8,"cue":"strain","who":"executioner"},
		{"t":3.0,"cue":"boulder_roll","who":"executioner","variant":0,"db":-3.0},
		{"t":4.9,"cue":"rip","who":"victim","variant":1,"db":-4.0},
		{"t":5.0,"cue":"squelch","who":"victim","variant":2},
		{"t":5.7,"cue":"punch","who":"musician"},
		{"t":6.3,"cue":"rustle","who":"executioner"},
		{"t":6.8,"cue":"step_earth","who":"executioner","variant":0},
		{"t":7.3,"cue":"step_earth","who":"executioner","variant":1},
		{"t":7.8,"cue":"step_earth","who":"executioner","variant":2},
		{"t":8.2,"cue":"crowd_groan","who":"room","variant":1},
	],
	# 3. Into the fire: heaved on, WHOOMPH; a charred figure walks two steps,
	# coughs a smoke ring, crumbles; the elder warms his hands.
	"into_the_fire":[
		{"t":-2.8,"cue":"roll","who":"musician"},
		{"t":-1.0,"cue":"heave","who":"executioner","variant":0},
		{"t":-0.3,"cue":"swing_whoosh","who":"victim","variant":1},
		{"t":0.0,"cue":"whoomph","who":"victim","variant":0},
		{"t":0.4,"cue":"room_gasp","who":"room"},
		{"t":1.2,"cue":"fire_pop","who":"victim","variant":4},
		{"t":2.3,"cue":"step_earth","who":"victim","variant":0},
		{"t":2.9,"cue":"step_earth","who":"victim","variant":1},
		{"t":3.5,"cue":"cough","who":"victim","variant":0},
		{"t":3.9,"cue":"smoke_poof","who":"victim"},
		{"t":5.0,"cue":"crumble","who":"victim"},
		{"t":7.0,"cue":"punch","who":"musician"},
		{"t":7.6,"cue":"rub_hands","who":"elder","db":6.0},
		{"t":8.4,"cue":"hum_yes","who":"elder","variant":2},
	],
	# 5. Spear pincushion: spear after spear; they wobble; the child's spear
	# hits the hide wall; one last spear, and down like a felled tree.
	"spear_pincushion":[
		{"t":-2.6,"cue":"roll","who":"musician"},
		{"t":-0.16,"cue":"spear_thunk","who":"victim","variant":0},
		{"t":0.2,"cue":"spear_thunk","who":"victim","variant":1},
		{"t":0.45,"cue":"room_gasp","who":"room"},
		{"t":0.5,"cue":"spear_thunk","who":"victim","variant":2},
		{"t":0.82,"cue":"spear_thunk","who":"victim","variant":0},
		{"t":1.1,"cue":"spear_thunk","who":"victim","variant":1},
		{"t":1.9,"cue":"creak","who":"victim","variant":1,"db":-6.0},
		{"t":2.8,"cue":"hide_thwap","who":"child"},
		{"t":3.2,"cue":"snort_laugh","who":"room","variant":1},
		{"t":4.3,"cue":"spear_thunk","who":"victim","variant":2},
		{"t":4.8,"cue":"creak","who":"victim","variant":1},
		{"t":5.6,"cue":"faint_thump","who":"victim","variant":1,"db":3.0},
		{"t":6.1,"cue":"punch","who":"musician"},
		{"t":6.9,"cue":"lone_clap","who":"flatterer","variant":0},
	],
	# 6. Stoned by the whole court: everyone throws; a cairn; a hand pokes out,
	# one finger up; the child's stone bonks an official.
	"stoned_by_court":[
		{"t":-2.2,"cue":"roll","who":"musician"},
		{"t":0.0,"cue":"bonk","who":"victim","variant":0},
		{"t":0.22,"cue":"bonk","who":"victim","variant":1},
		{"t":0.4,"cue":"stone_clack","who":"victim","variant":0},
		{"t":0.55,"cue":"bonk","who":"victim","variant":0},
		{"t":0.75,"cue":"stone_clack","who":"victim","variant":1},
		{"t":0.95,"cue":"stone_clack","who":"victim","variant":2},
		{"t":1.1,"cue":"stone_clack","who":"victim","variant":0},
		{"t":1.32,"cue":"stone_clack","who":"victim","variant":1},
		{"t":1.6,"cue":"stone_clack","who":"victim","variant":2},
		{"t":1.95,"cue":"stone_clack","who":"victim","variant":0,"db":-3.0},
		{"t":3.1,"cue":"rustle","who":"victim","db":-3.0},
		{"t":3.5,"cue":"room_gasp","who":"room"},
		{"t":4.4,"cue":"bonk","who":"official","variant":2},
		{"t":4.6,"cue":"ow","who":"official","variant":1},
		{"t":5.2,"cue":"punch","who":"musician"},
		{"t":5.8,"cue":"snort_laugh","who":"room","variant":0},
	],
	# 7. Buried to the neck: dug in; the goat eats their hair; an ox ambles
	# through: POP; the ox shakes its hoof.
	"buried_to_neck":[
		{"t":-5.0,"cue":"roll","who":"musician"},
		{"t":-3.8,"cue":"dig","who":"executioner","variant":0},
		{"t":-3.2,"cue":"dig","who":"executioner","variant":1},
		{"t":-2.6,"cue":"goat_bleat","who":"goat","variant":1},
		{"t":-2.2,"cue":"goat_chew","who":"goat"},
		{"t":-1.6,"cue":"ox_low","who":"ox","variant":0},
		{"t":-1.0,"cue":"hoof","who":"ox","variant":0},
		{"t":-0.55,"cue":"hoof","who":"ox","variant":1},
		{"t":0.0,"cue":"bone_pop","who":"victim","variant":0},
		{"t":0.02,"cue":"gore_splat","who":"victim","variant":0,"db":-6.0},
		{"t":0.4,"cue":"room_gasp","who":"room"},
		{"t":1.3,"cue":"flick","who":"ox"},
		{"t":2.1,"cue":"ox_low","who":"ox","variant":1,"db":-3.0},
		{"t":2.7,"cue":"punch","who":"musician"},
		{"t":3.3,"cue":"crowd_groan","who":"room","variant":0},
	],
	# 8. Trampled by the herd: the herd stampedes through; flattened, hoofprints;
	# a goat stops to chew their sleeve.
	"trampled_by_herd":[
		{"t":-2.4,"cue":"roll","who":"musician"},
		{"t":-1.0,"cue":"goat_bleat","who":"herd","variant":0},
		{"t":-0.6,"cue":"stampede","who":"herd"},
		{"t":0.0,"cue":"gore_splat","who":"victim","variant":1,"db":-3.0},
		{"t":0.5,"cue":"room_gasp","who":"room"},
		{"t":3.2,"cue":"goat_chew","who":"goat","db":4.0},
		{"t":3.9,"cue":"goat_bleat","who":"goat","variant":2},
		{"t":4.5,"cue":"punch","who":"musician"},
		{"t":5.2,"cue":"retch","who":"front_row","variant":1},
	],
	# 9. The pig pen: the pigs swarm; a clean skeleton stands up, shrugs, collapses.
	"pig_pen":[
		{"t":-2.2,"cue":"roll","who":"musician"},
		{"t":0.0,"cue":"pig_swarm","who":"herd"},
		{"t":0.6,"cue":"crunch","who":"herd","variant":0},
		{"t":1.0,"cue":"crowd_groan","who":"room","variant":0},
		{"t":1.5,"cue":"crunch","who":"herd","variant":1},
		{"t":4.0,"cue":"bones_rattle","who":"victim","variant":0},
		{"t":5.8,"cue":"bones_rattle","who":"victim","variant":1},
		{"t":6.9,"cue":"punch","who":"musician"},
		{"t":7.5,"cue":"retch","who":"front_row","variant":0},
	],
	# 11. Neck-stretch hanging: the drop, BOING, the head pops off on the
	# rebound, the body thuds, the head swings on in the noose.
	"neck_stretch_hanging":[
		{"t":-2.6,"cue":"roll","who":"musician"},
		{"t":-1.3,"cue":"rope_creak","who":"executioner","variant":0},
		{"t":-0.25,"cue":"swing_whoosh","who":"victim","variant":0},
		{"t":0.0,"cue":"boing","who":"victim","variant":0},
		{"t":1.0,"cue":"bone_pop","who":"victim","variant":2},
		{"t":1.3,"cue":"faint_thump","who":"victim","variant":0},
		{"t":1.55,"cue":"room_gasp","who":"room"},
		{"t":2.0,"cue":"rope_creak","who":"victim","variant":1},
		{"t":3.6,"cue":"punch","who":"musician"},
		{"t":4.3,"cue":"snort_laugh","who":"room","variant":2},
	],
	# 12. Quartered by oxen: four ropes, four oxen; the limbs pop off, the
	# torso drops; one ox drags an arm out of the door.
	"quartered_by_oxen":[
		{"t":-2.8,"cue":"roll","who":"musician"},
		{"t":-2.0,"cue":"ox_low","who":"ox","variant":0},
		{"t":-1.1,"cue":"rope_creak","who":"ox","variant":0},
		{"t":-0.65,"cue":"hoof","who":"ox","variant":0},
		{"t":-0.4,"cue":"hoof","who":"ox","variant":1},
		{"t":0.0,"cue":"bone_pop","who":"victim","variant":0},
		{"t":0.02,"cue":"rip","who":"victim","variant":0,"db":-4.0},
		{"t":0.12,"cue":"bone_pop","who":"victim","variant":1},
		{"t":0.2,"cue":"bone_pop","who":"victim","variant":2},
		{"t":0.31,"cue":"bone_pop","who":"victim","variant":0},
		{"t":0.55,"cue":"faint_thump","who":"victim","variant":1},
		{"t":0.75,"cue":"room_gasp","who":"room"},
		{"t":1.7,"cue":"ox_low","who":"ox","variant":1,"db":-3.0},
		{"t":2.3,"cue":"drag","who":"ox","variant":1},
		{"t":2.5,"cue":"hoof","who":"ox","variant":0,"db":-4.0},
		{"t":3.0,"cue":"hoof","who":"ox","variant":1,"db":-6.0},
		{"t":3.9,"cue":"punch","who":"musician"},
		{"t":4.6,"cue":"retch","who":"front_row","variant":0},
	],
	# 13. Sawn in half: two men saw lengthwise; the halves fall left and
	# right; each half's eye blinks at the other.
	"sawn_in_half":[
		{"t":-5.8,"cue":"roll","who":"musician"},
		{"t":-3.5,"cue":"saw_rasp","who":"executioner"},
		{"t":-0.5,"cue":"rip","who":"victim","variant":1},
		{"t":0.0,"cue":"faint_thump","who":"victim","variant":0},
		{"t":0.1,"cue":"squelch","who":"victim","variant":0},
		{"t":0.22,"cue":"faint_thump","who":"victim","variant":1},
		{"t":0.55,"cue":"room_gasp","who":"room"},
		{"t":1.7,"cue":"blink","who":"victim"},
		{"t":2.05,"cue":"blink","who":"victim","db":-2.0},
		{"t":2.7,"cue":"punch","who":"musician"},
		{"t":3.3,"cue":"crowd_groan","who":"room","variant":1},
	],
	# 14. Boiled in the pot: in, bubbles; the cook adds herbs, tastes, adds
	# salt; a skull bobs up (a hungry onlooker's stomach, only when the stores
	# are really low).
	"boiled_in_pot":[
		{"t":-2.2,"cue":"roll","who":"musician"},
		{"t":0.0,"cue":"pot_plop","who":"victim","variant":0},
		{"t":0.3,"cue":"bubbling","who":"cook"},
		{"t":0.45,"cue":"room_gasp","who":"room"},
		{"t":1.2,"cue":"spoon_stir","who":"cook"},
		{"t":2.9,"cue":"sprinkle","who":"cook"},
		{"t":3.6,"cue":"slurp","who":"cook","variant":0},
		{"t":5.0,"cue":"sprinkle","who":"cook"},
		{"t":5.8,"cue":"pot_plop","who":"victim","variant":1,"db":-8.0},
		{"t":6.3,"cue":"punch","who":"musician"},
		{"t":7.1,"cue":"stomach_growl","who":"front_row","variant":0,"if":"hungry"},
		{"t":7.1,"cue":"crowd_groan","who":"room","variant":0,"if":"not_hungry"},
	],
	# 15. The stake: hoisted on; a slow slide down to the scribe's eye level;
	# the scribe keeps writing.
	"the_stake":[
		{"t":-2.6,"cue":"roll","who":"musician"},
		{"t":-1.2,"cue":"heave","who":"executioner","variant":1},
		{"t":-0.6,"cue":"strain","who":"executioner","variant":0},
		{"t":0.0,"cue":"squelch","who":"victim","variant":1},
		{"t":0.3,"cue":"room_gasp","who":"room"},
		{"t":0.5,"cue":"slow_squelch","who":"victim"},
		{"t":1.1,"cue":"scribble","who":"scribe","variant":0,"db":6.0},
		{"t":2.7,"cue":"scribble","who":"scribe","variant":1,"db":6.0},
		{"t":4.0,"cue":"punch","who":"musician"},
		{"t":4.7,"cue":"ahem","who":"scribe","variant":1},
	],
	# 16. Volley of arrows: archers fire until they are a porcupine; the last
	# arrow knocks off their hat.
	"volley_of_arrows":[
		{"t":-2.4,"cue":"roll","who":"musician"},
		{"t":0.0,"cue":"arrow_volley","who":"victim"},
		{"t":0.55,"cue":"room_gasp","who":"room"},
		{"t":1.0,"cue":"arrow_volley","who":"victim","db":-2.0},
		{"t":3.3,"cue":"arrow_thunk","who":"victim","variant":2},
		{"t":3.42,"cue":"bonk","who":"victim","variant":2,"db":-6.0},
		{"t":3.5,"cue":"rustle","who":"victim"},
		{"t":4.1,"cue":"punch","who":"musician"},
		{"t":4.7,"cue":"snort_laugh","who":"room","variant":1},
	],
	# 17. The bear pit: the bear lumbers in, swallows them whole, burps, and
	# spits out a sandal.
	"bear_pit":[
		{"t":-2.8,"cue":"roll","who":"musician"},
		{"t":-1.3,"cue":"bear_roar","who":"bear"},
		{"t":-0.6,"cue":"hoof","who":"bear","variant":1,"db":3.0},
		{"t":-0.25,"cue":"hoof","who":"bear","variant":0,"db":3.0},
		{"t":0.0,"cue":"bear_swallow","who":"bear"},
		{"t":0.6,"cue":"room_gasp","who":"room"},
		{"t":2.3,"cue":"burp","who":"bear","variant":0},
		{"t":3.9,"cue":"spit","who":"bear"},
		{"t":4.7,"cue":"punch","who":"musician"},
		{"t":5.4,"cue":"lone_clap","who":"flatterer","variant":1},
	],
	# 18. Elephant foot: the elephant steps on the head: POP; it shakes its foot clean.
	"elephant_foot":[
		{"t":-3.0,"cue":"roll","who":"musician"},
		{"t":-1.6,"cue":"elephant_trumpet","who":"elephant","variant":0},
		{"t":-0.5,"cue":"hoof","who":"elephant","variant":1,"db":5.0},
		{"t":0.0,"cue":"bone_pop","who":"victim","variant":1},
		{"t":0.01,"cue":"gore_splat","who":"victim","variant":2,"db":-4.0},
		{"t":0.45,"cue":"room_gasp","who":"room"},
		{"t":1.5,"cue":"flick","who":"elephant"},
		{"t":2.3,"cue":"elephant_trumpet","who":"elephant","variant":1,"db":-4.0},
		{"t":3.1,"cue":"punch","who":"musician"},
		{"t":3.8,"cue":"retch","who":"front_row","variant":1},
	],
	# 19. The wheel and the hill: tied to a wheel and rolled out of the door;
	# crunch... crunch... crunch, further away; one shoe rolls back in.
	"wheel_and_hill":[
		{"t":-2.8,"cue":"roll","who":"musician"},
		{"t":-1.4,"cue":"rope_creak","who":"executioner","variant":0},
		{"t":-0.5,"cue":"creak","who":"executioner","variant":2},
		{"t":0.0,"cue":"wheel_crunch","who":"victim"},
		{"t":0.6,"cue":"room_gasp","who":"room"},
		{"t":5.4,"cue":"head_roll","who":"victim","variant":1,"db":-8.0},
		{"t":6.3,"cue":"punch","who":"musician"},
		{"t":7.0,"cue":"lone_clap","who":"flatterer","variant":0},
	],
	# 20. Dipped in molten bronze: lowered into the crucible, a squeak cut off
	# by the hiss; hoisted out a statue, set down by the door with a ring.
	"molten_bronze":[
		{"t":-2.8,"cue":"roll","who":"musician"},
		{"t":-1.8,"cue":"bubbling","who":"executioner","db":-4.0},
		{"t":-1.1,"cue":"rope_creak","who":"executioner","variant":0},
		{"t":-0.08,"cue":"yelp_small","who":"victim","variant":0},
		{"t":0.0,"cue":"sizzle","who":"victim"},
		{"t":0.45,"cue":"room_gasp","who":"room"},
		{"t":2.6,"cue":"rope_creak","who":"executioner","variant":0},
		{"t":3.8,"cue":"lid_clank","who":"victim","variant":1},
		{"t":3.8,"cue":"bump","who":"victim","variant":1,"db":2.0},
		{"t":4.5,"cue":"punch","who":"musician"},
		{"t":5.2,"cue":"lone_clap","who":"flatterer","variant":1},
	],
	# 21. Catapult launch: cranked, loaded, THWACK; a long whistle; a distant
	# splat; one tooth drops back into the hall.
	"catapult_launch":[
		{"t":-3.6,"cue":"roll","who":"musician"},
		{"t":-2.0,"cue":"ratchet","who":"executioner","variant":0},
		{"t":-0.28,"cue":"catapult_thwack","who":"executioner"},
		{"t":0.1,"cue":"whistle_long","who":"victim","variant":0},
		{"t":0.5,"cue":"room_gasp","who":"room"},
		{"t":3.1,"cue":"splat_distant","who":"room","variant":0},
		{"t":4.6,"cue":"tooth_tink","who":"room"},
		{"t":5.3,"cue":"punch","who":"musician"},
		{"t":5.9,"cue":"snort_laugh","who":"room","variant":2},
	],
	# 22. Under the great stone: the rope team lowers a monolith: squelch; the
	# architect checks it's level.
	"great_stone":[
		{"t":-3.2,"cue":"roll","who":"musician"},
		{"t":-2.4,"cue":"heave","who":"executioner","variant":0},
		{"t":-1.9,"cue":"heave","who":"executioner","variant":1},
		{"t":-1.6,"cue":"boulder_roll","who":"executioner","variant":1},
		{"t":-0.9,"cue":"rope_creak","who":"executioner","variant":0},
		{"t":0.0,"cue":"gore_splat","who":"victim","variant":2,"db":-2.0},
		{"t":0.05,"cue":"squelch","who":"victim","variant":2},
		{"t":0.45,"cue":"room_gasp","who":"room"},
		{"t":2.3,"cue":"stone_clack","who":"architect","variant":0,"db":-6.0},
		{"t":2.75,"cue":"hum_yes","who":"architect","variant":0},
		{"t":3.4,"cue":"punch","who":"musician"},
		{"t":4.1,"cue":"lone_clap","who":"flatterer","variant":0},
	],
	# 23. The falling blade: raised, released; the head in the basket; the dog
	# fetches it like a ball.
	"falling_blade":[
		{"t":-4.4,"cue":"roll","who":"musician"},
		{"t":-2.2,"cue":"ratchet","who":"executioner","variant":1},
		{"t":-0.25,"cue":"swing_whoosh","who":"executioner","variant":2},
		{"t":0.0,"cue":"gore_chop","who":"victim","variant":1},
		{"t":0.15,"cue":"basket_thump","who":"victim"},
		{"t":0.5,"cue":"room_gasp","who":"room"},
		{"t":1.7,"cue":"dog_bark","who":"dog","variant":1},
		{"t":2.1,"cue":"paws","who":"dog"},
		{"t":2.7,"cue":"basket_thump","who":"dog","db":-6.0},
		{"t":3.1,"cue":"paws","who":"dog"},
		{"t":3.7,"cue":"dog_thump","who":"dog"},
		{"t":4.1,"cue":"punch","who":"musician"},
		{"t":4.7,"cue":"snort_laugh","who":"room","variant":0},
	],
	# 24. Firing squad: the first volley misses everything but the hat; the
	# second lands and the body jigs; the smoke clears; the cymbal.
	"firing_squad":[
		{"t":-3.0,"cue":"roll","who":"musician"},
		{"t":-1.8,"cue":"musket_cock","who":"executioner"},
		{"t":0.0,"cue":"musket_volley","who":"executioner","variant":0},
		{"t":0.15,"cue":"bonk","who":"victim","variant":2,"db":-5.0},
		{"t":0.3,"cue":"rustle","who":"victim"},
		{"t":1.5,"cue":"snort_laugh","who":"room","variant":1},
		{"t":2.1,"cue":"musket_cock","who":"executioner","db":-3.0},
		{"t":3.1,"cue":"musket_volley","who":"executioner","variant":1},
		{"t":3.3,"cue":"step_earth","who":"victim","variant":0,"db":6.0},
		{"t":3.45,"cue":"step_earth","who":"victim","variant":1,"db":6.0},
		{"t":3.6,"cue":"step_earth","who":"victim","variant":2,"db":6.0},
		{"t":3.75,"cue":"step_earth","who":"victim","variant":3,"db":6.0},
		{"t":3.9,"cue":"step_earth","who":"victim","variant":0,"db":6.0},
		{"t":4.3,"cue":"faint_thump","who":"victim","variant":0},
		{"t":5.6,"cue":"punch","who":"musician"},
		{"t":6.4,"cue":"lone_clap","who":"flatterer","variant":1},
	],
	# 25. Cannon mouth: tied over the muzzle, the fuse fizzing: BOOM; a red mist;
	# everyone blinks; the scribe wipes the tablet; the flatterer applauds, alone.
	"cannon_mouth":[
		{"t":-4.6,"cue":"roll","who":"musician"},
		{"t":-3.6,"cue":"rope_creak","who":"executioner","variant":0},
		{"t":-2.6,"cue":"fuse","who":"executioner"},
		{"t":0.0,"cue":"cannon_boom","who":"victim"},
		{"t":0.4,"cue":"blood_patter","who":"front_row","variant":1,"db":2.0},
		{"t":0.9,"cue":"blood_patter","who":"room","variant":0},
		{"t":2.5,"cue":"blink","who":"front_row"},
		{"t":2.7,"cue":"blink","who":"room","db":-2.0},
		{"t":2.85,"cue":"blink","who":"official","db":-3.0},
		{"t":3.5,"cue":"wipe","who":"scribe"},
		{"t":4.6,"cue":"punch","who":"musician"},
		{"t":5.3,"cue":"lone_clap","who":"flatterer","variant":0},
	],
}

static func has(name:String)->bool:
	return CUES.has(name)

static func variants(name:String)->int:
	return int((CUES.get(name,{}) as Dictionary).get("variants",1))

static func level(name:String)->float:
	return float((CUES.get(name,{}) as Dictionary).get("db",-10.0))

static func stream(name:String,variant:=0)->AudioStreamWAV:
	return Synth.to_stream(make(name,variant),0.0)

static func make(name:String,variant:=0)->PackedFloat32Array:
	var v:=posmod(variant,maxi(1,variants(name)))
	var rng:=RandomNumberGenerator.new();rng.seed=Synth.seed_of("court_gore|%s|%d" % [name,v])
	var b:PackedFloat32Array
	match name:
		"gore_splat":b=splat(v,rng)
		"gore_crack":b=crack(v,rng)
		"bonk":b=bonk(v,rng)
		"lid_clank":b=lid_clank(v,rng)
		"gore_chop":b=chop(v,rng)
		"splat_distant":b=splat_distant(v,rng)
		"whoomph":b=whoomph(v,rng)
		"boing":b=boing(v,rng)
		"whistle_long":b=whistle(v,rng,2.6,2400.0,520.0)
		"head_whistle":b=head_whistle(v,rng)
		"swing_whoosh":b=whoosh(v,rng)
		"crunch":b=crunch(v,rng)
		"crunch_loop":b=crunch_loop(v,rng)
		"wheel_crunch":b=wheel_crunch(v,rng)
		"squelch":b=squelch(v,rng)
		"bone_pop":b=bone_pop(v,rng)
		"saw_rasp":b=saw_rasp(v,rng)
		"rip":b=rip(v,rng)
		"bubbling":b=bubbling(v,rng)
		"pot_plop":b=pot_plop(v,rng)
		"spoon_stir":b=spoon_stir(v,rng)
		"blood_geyser":b=geyser(v,rng)
		"blood_patter":b=patter(v,rng)
		"blink":b=blink(v,rng)
		"bear_swallow":b=bear_swallow(v,rng)
		"burp":b=burp(v,rng)
		"elephant_trumpet":b=trumpet(v,rng)
		"pig_swarm":b=pig_swarm(v,rng)
		"ox_low":b=ox_low(v,rng)
		"dog_snarl":b=dog_snarl(v,rng)
		"drag":b=drag(v,rng)
		"bone_drop":b=bone_drop(v,rng)
		"arrow_volley":b=arrow_volley(v,rng)
		"arrow_thunk":b=arrow_thunk(v,rng)
		"musket_volley":b=musket_volley(v,rng)
		"cannon_boom":b=cannon(v,rng)
		"axe_thunk":b=axe_thunk(v,rng)
		"axe_clang":b=axe_clang(v,rng)
		"axe_pull":b=axe_pull(v,rng)
		"head_roll":b=head_roll(v,rng)
		"windup":b=windup(v,rng)
		"retch":b=retch(v,rng)
		"crowd_groan":b=crowd_groan(v,rng)
		"lone_clap":b=lone_clap(v,rng)
		"ow":b=ow(v,rng)
		"drum_roll":b=drum_roll(v,rng,"frame" if v==0 else "clay")
		"log_roll":b=log_roll(v,rng)
		"punch_drum":b=punch_drum(v,rng,"frame" if v==0 else "clay")
		"punch_cymbal":b=punch_cymbal(v,rng)
		"punch_log":b=punch_log(v,rng)
		"boulder_roll":b=boulder_roll(v,rng)
		"crumble":b=crumble(v,rng)
		"smoke_poof":b=smoke_poof(v,rng)
		"spear_thunk":b=spear_thunk(v,rng)
		"hide_thwap":b=hide_thwap(v,rng)
		"stone_clack":b=stone_clack(v,rng)
		"dig":b=dig(v,rng)
		"hoof":b=hoof(v,rng)
		"stampede":b=stampede(v,rng)
		"bones_rattle":b=bones_rattle(v,rng)
		"rope_creak":b=rope_creak(v,rng)
		"slurp":b=slurp(v,rng)
		"sprinkle":b=sprinkle(v,rng)
		"slow_squelch":b=slow_squelch(v,rng)
		"bear_roar":b=bear_roar(v,rng)
		"spit":b=spit(v,rng)
		"sizzle":b=sizzle(v,rng)
		"ratchet":b=ratchet(v,rng)
		"catapult_thwack":b=catapult_thwack(v,rng)
		"tooth_tink":b=tooth_tink(v,rng)
		"basket_thump":b=basket_thump(v,rng)
		"musket_cock":b=musket_cock(v,rng)
		"fuse":b=fuse(v,rng)
		"wipe":b=wipe(v,rng)
		"flick":b=flick(v,rng)
		"club_tap":b=club_tap(v,rng)
		"face_splash":b=face_splash(v,rng)
		"lid_pat":b=lid_pat(v,rng)
		"tug":b=tug(v,rng)
		"slip":b=slip(v,rng)
		_:b=Synth.buffer(0.05)
	Synth.fade_edges(b,0.002,0.02)
	var top:=Synth.peak_of(b)
	if top>0.0001:Synth.scale(b,0.7/top)
	return b

# =============================================================================
# Pieces
# =============================================================================

## A falling tone (Hz) over seconds, enveloped: a thud, a gulp, a blip.
static func _sweep(seconds:float,f0:float,f1:float,harm:Array,attack:=0.004)->PackedFloat32Array:
	var t:=Synth.tone(Synth.track(seconds,[[0.0,f0],[seconds,f1]]),harm)
	Synth.shape(t,[[0.0,0.0],[attack,1.0],[seconds,0.0]])
	return t

## Wet noise: white noise through a band that moves (Hz a point), enveloped.
static func _wet(seconds:float,points:Array,q:float,rng:RandomNumberGenerator,env:Array)->PackedFloat32Array:
	var n:=Synth.white(seconds,rng)
	var c:=Synth.track(seconds,points)
	var frames:=PackedFloat32Array();frames.resize(c.size()/32+1)
	for i in frames.size():frames[i]=c[mini(i*32,c.size()-1)]
	Synth.bandpass_track(n,frames,q)
	Synth.lowpass(n,3800.0)
	Synth.shape(n,env)
	return n

## A few bubbles (a gas pocket's ring rises in pitch as it shrinks).
static func _bubbles(b:PackedFloat32Array,from:float,to:float,count:int,low:float,high:float,amp:float,rng:RandomNumberGenerator)->void:
	for k in count:
		var f:=rng.randf_range(low,high)
		var d:=rng.randf_range(0.02,0.05)
		var bl:=_sweep(d,f,f*rng.randf_range(1.3,1.8),[1.0],0.002)
		Synth.mix_into(b,bl,Synth.n_of(rng.randf_range(from,to)),amp*rng.randf_range(0.5,1.0))

## A heavy thud on the earth floor.
static func _thud(b:PackedFloat32Array,at:float,f:float,amp:float,rng:RandomNumberGenerator)->void:
	Synth.mix_into(b,_sweep(0.3,f,f*0.55,[1.0,0.4,0.15]),Synth.n_of(at),amp*0.8)
	# the knock that carries on small speakers
	Synth.modal(b,at,[Vector3(f*4.2,0.5,0.05),Vector3(f*7.1,0.25,0.03)],rng,amp)
	var dirt:=Synth.white(0.08,rng)
	Synth.lowpass2(dirt,500.0)
	Synth.shape(dirt,[[0.0,1.0],[0.08,0.0]])
	Synth.mix_into(b,dirt,Synth.n_of(at),amp*0.8)

# =============================================================================
# Impacts
# =============================================================================

## SPLAT: the low thump of the weight, the wet "splorch" sweeping down, a few
## bubbles in the squish, and the spatter landing round about.
static func splat(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	_thud(b,0.0,72.0+v*8.0,1.0,rng)
	Synth.mix_into(b,_wet(0.32,[[0.0,1400.0],[0.06,900.0],[0.32,280.0]],1.6,rng,[[0.0,0.0],[0.004,1.0],[0.08,0.6],[0.32,0.0]]),0,2.2)
	_bubbles(b,0.05,0.45,6+v*2,180.0,420.0,0.35,rng)
	for k in 14:Synth.burst(b,rng.randf_range(0.08,0.7),0.004,rng.randf_range(2000.0,4500.0),1.5,rng.randf_range(0.05,0.2),rng)
	return b

## A splat heard from beyond the wall: duller, smaller, with the wall's echo.
static func splat_distant(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var near:=splat(v,rng)
	Synth.lowpass(near,1500.0)
	var b:=Synth.buffer(1.4)
	Synth.mix_into(b,near,0,1.0)
	Synth.mix_into(b,near,Synth.n_of(0.21),0.25)
	return b

## CRACK: a club meets a head, a bat meets a ball: a hard click, the hollow
## wood-and-bone ring, a crunch inside it, the thump.
static func crack(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.6)
	Synth.burst(b,0.0,0.004,3200.0,0.5,1.4,rng)
	Synth.modal(b,0.0,[Vector3(470.0+v*60.0,0.8,0.06),Vector3(1120.0+v*90.0,0.6,0.045),Vector3(2350.0,0.4,0.03),Vector3(3900.0,0.25,0.02)],rng,1.0)
	for k in 7:Synth.burst(b,0.003+rng.randf_range(0.0,0.035),0.003,rng.randf_range(1500.0,4000.0),1.2,rng.randf_range(0.3,0.7),rng)
	Synth.mix_into(b,_sweep(0.18,140.0,80.0,[1.0,0.3]),0,0.6)
	return b

## A hollow comic bonk: a stone on a skull, a coconut's knock, its pitch
## dropping as it rings.
static func bonk(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.45)
	var f:=380.0+v*90.0
	Synth.mix_into(b,_sweep(0.32,f,f*0.8,[1.0,0.0,0.18],0.002),0,1.0)
	Synth.mix_into(b,_sweep(0.08,f*2.31,f*2.0,[1.0],0.001),0,0.35)
	Synth.burst(b,0.0,0.003,2500.0,1.0,0.5,rng)
	return b

## A lid set on a pot: the clank, then the lid rocking on its rim, quicker
## and quicker, and still. 0: clay; 1: bronze (rings long).
static func lid_clank(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.2)
	var modes:Array=[Vector3(880,1.0,0.05),Vector3(2140,0.6,0.035),Vector3(3650,0.3,0.02)]
	if v==1:modes=[Vector3(1240,1.0,0.5),Vector3(2930,0.7,0.35),Vector3(4710,0.4,0.22),Vector3(6260,0.2,0.15)]
	Synth.modal(b,0.0,modes,rng,1.0)
	Synth.burst(b,0.0,0.004,2500.0,1.0,0.6,rng)
	var t:=0.11;var gap:=0.075;var amp:=0.45
	while gap>0.012 and t<1.0:
		Synth.modal(b,t,modes.slice(0,2),rng,amp)
		t+=gap;gap*=0.78;amp*=0.8
	return b

## The third swing lands: a wet thock through the neck and into the block.
static func chop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.7)
	Synth.burst(b,0.0,0.005,2600.0,0.7,1.0,rng)
	Synth.modal(b,0.004,[Vector3(180.0,0.7,0.08),Vector3(430.0,0.5,0.05),Vector3(950.0,0.3,0.03)],rng,1.0)
	Synth.mix_into(b,_wet(0.25,[[0.0,1200.0],[0.25,350.0]],1.8,rng,[[0.0,0.0],[0.003,1.0],[0.25,0.0]]),0,1.6)
	_bubbles(b,0.04,0.3,4+v,200.0,500.0,0.25,rng)
	return b

# =============================================================================
# Fire, spring, flight, swings
# =============================================================================

## WHOOMPH: the fire takes a whole person at once: air sucked in, then the
## roar flaring up and settling, a low boom under it, crackling after.
static func whoomph(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.2
	var b:=Synth.pink(d,rng,1.0)
	var c:=Synth.track(d,[[0.0,250.0],[0.12,350.0],[0.32,2600.0+v*400.0],[1.2,700.0],[d,400.0]])
	var frames:=PackedFloat32Array();frames.resize(c.size()/32+1)
	for i in frames.size():frames[i]=c[mini(i*32,c.size()-1)]
	Synth.bandpass_track(b,frames,0.8)
	Synth.shape(b,[[0.0,0.0],[0.14,0.25],[0.3,1.0],[0.7,0.6],[d,0.0]])
	Synth.mix_into(b,_sweep(1.0,62.0,38.0,[1.0,0.3]),Synth.n_of(0.24),0.9)
	var t:=0.5
	while t<d-0.1:
		Synth.burst(b,t,0.002,rng.randf_range(2000.0,5000.0),1.0,rng.randf_range(0.1,0.35),rng);t+=rng.randf_range(0.02,0.12)
	return b

## BOING: the stretched neck springs back: a twanging tone whose pitch wobbles
## wide and settles, through a jaw-harp mouth.
static func boing(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.3+0.3*v
	var f0:=150.0-30.0*v
	var p:=Synth.buffer(d)
	for i in p.size():
		var t:=float(i)/RATE
		p[i]=f0*(1.0+0.45*exp(-t*3.0)*sin(TAU*(11.0-2.0*v)*t))*(1.0+0.25*exp(-t*8.0))
	var b:=Synth.tone(p,[1.0,0.7,0.5,0.35,0.25,0.18,0.12])
	Synth.resonate(b,800.0,220.0)
	Synth.shape(b,[[0.0,0.0],[0.005,1.0],[d*0.4,0.5],[d,0.0]])
	return b

## A long falling whistle (a catapult's passenger, high over the wall).
static func whistle(v:int,rng:RandomNumberGenerator,d:float,f_hi:float,f_lo:float)->PackedFloat32Array:
	var p:=Synth.track(d,[[0.0,f_hi*(1.0+0.05*v)],[d*0.5,f_hi*0.62],[d,f_lo]])
	for i in p.size():p[i]*=1.0+0.012*sin(TAU*6.0*float(i)/RATE)
	var b:=Synth.tone(p,[1.0,0.12])
	var air:=Synth.white(d,rng,0.25)
	Synth.bandpass(air,1800.0,1.0)
	for i in b.size():b[i]+=air[i]*0.3
	Synth.shape(b,[[0.0,0.0],[0.08,1.0],[d*0.8,0.8],[d,0.0]])
	return b

## A head sailing up and over into the pot: a rising-then-falling whistle.
static func head_whistle(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.2
	var p:=Synth.track(d,[[0.0,900.0],[0.45,1700.0+v*200.0],[d,700.0]])
	var b:=Synth.tone(p,[1.0,0.1])
	var air:=Synth.white(d,rng,0.4)
	Synth.bandpass(air,1500.0,2.0)
	for i in b.size():b[i]=b[i]*0.7+air[i]*0.15
	Synth.shape(b,[[0.0,0.0],[0.1,1.0],[d*0.8,0.7],[d,0.0]])
	return b

## A big swing through the air.
static func whoosh(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.42+0.06*v
	return _wet(d,[[0.0,300.0],[d*0.55,1500.0+v*250.0],[d,400.0]],1.1,rng,[[0.0,0.0],[d*0.55,1.0],[d,0.0]])

# =============================================================================
# Crunches, squelches, pops, saws, rips
# =============================================================================

## A bone crunched: a snap, then a dense cluster of crackles, with the wet in it.
static func crunch(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.35+0.08*v
	var b:=Synth.buffer(d+0.15)
	Synth.burst(b,0.0,0.004,1800.0,0.8,1.0,rng)
	Synth.mix_into(b,_sweep(0.08,260.0,140.0,[1.0,0.4]),0,0.5)
	var t:=0.005
	while t<d:
		Synth.burst(b,t,0.0025,rng.randf_range(1400.0,5000.0),1.3,rng.randf_range(0.2,0.8)*(1.0-0.6*t/d),rng);t+=rng.randf_range(0.003,0.018)
	Synth.mix_into(b,_wet(d,[[0.0,700.0],[d,400.0]],1.5,rng,[[0.0,0.0],[0.01,0.6],[d,0.0]]),0,0.7)
	return b

## The dogs at their dinner, behind the windbreak: crunch after crunch, wet
## chewing between, a growl under it, a gnaw.
static func crunch_loop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=3.4
	var b:=Synth.buffer(d)
	var t:=0.05
	while t<d-0.5:
		var one:=crunch(rng.randi_range(0,2),rng)
		Synth.mix_into(b,one,Synth.n_of(t),rng.randf_range(0.6,1.0))
		for k in 3:Synth.mix_into(b,_wet(0.09,[[0.0,600.0],[0.09,300.0]],2.0,rng,[[0.0,0.0],[0.02,1.0],[0.09,0.0]]),Synth.n_of(t+0.25+k*0.11),0.35)
		t+=rng.randf_range(0.42,0.66)
	var g:=dog_snarl(1,rng)
	Synth.mix_into(b,g,Synth.n_of(1.2),0.35)
	return b

## Tied to a wheel and rolled out of the door and down the hill: crunch...
## crunch... crunch, further each time, and the wheel's rumble going.
static func wheel_crunch(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=4.6
	var b:=Synth.buffer(d)
	var t:=0.1;var k:=0
	while t<d-0.6:
		var one:=crunch(k%3,rng)
		Synth.lowpass(one,4000.0-k*500.0)
		Synth.mix_into(b,one,Synth.n_of(t),pow(0.66,k))
		t+=0.55+k*0.06;k+=1
	var rumble:=Synth.brown(d,rng,1.0)
	Synth.lowpass(rumble,160.0)
	for i in rumble.size():
		var tt:=float(i)/RATE
		rumble[i]*=(0.6+0.4*sin(TAU*2.2*tt))*exp(-tt*0.8)
	Synth.mix_into(b,rumble,0,0.22)
	return b

## A squelch: a wet squish whose band slides like a vowel, with bubbles.
static func squelch(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.38+0.08*v
	var b:=_wet(d,[[0.0,320.0],[d*0.35,1250.0],[d,480.0]],4.0,rng,[[0.0,0.0],[0.02,1.0],[d*0.7,0.7],[d,0.0]])
	var flutter:=Synth.wander(d,0.012,rng,0.4,1.0)
	for i in b.size():b[i]*=flutter[i]
	_bubbles(b,0.05,d,5,250.0,600.0,0.12,rng)
	return b

## A bone pops out of its joint: a click, a short knock, a tiny squish.
static func bone_pop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.3)
	Synth.burst(b,0.0,0.003,3000.0+v*400.0,1.2,1.0,rng)
	Synth.modal(b,0.0,[Vector3(680.0+v*90.0,0.7,0.03),Vector3(1650.0,0.3,0.015)],rng,1.0)
	Synth.mix_into(b,_wet(0.12,[[0.0,900.0],[0.12,400.0]],3.0,rng,[[0.0,0.0],[0.005,1.0],[0.12,0.0]]),Synth.n_of(0.01),0.5)
	return b

## Two men sawing lengthwise: stroke and back, the teeth rasping (the noise
## chopped at the teeth's rate, which rises and falls with the stroke).
static func saw_rasp(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var stroke:=0.5
	var b:=Synth.buffer(stroke*6.0+0.2)
	for s in 6:
		var n:=Synth.white(stroke,rng)
		var ph:=0.0
		for i in n.size():
			var x:=float(i)/float(n.size())
			var speed:=sin(PI*x)
			ph+=(40.0+60.0*speed)*(1.2 if s%2==0 else 0.9)/RATE
			n[i]*=(0.25+0.75*pow(0.5+0.5*sin(TAU*ph),4.0))*speed
		var hi:=n.duplicate()
		Synth.bandpass(n,2600.0 if s%2==0 else 2100.0,1.2)
		Synth.bandpass(hi,900.0,1.0)
		for i in n.size():n[i]+=hi[i]*0.5
		Synth.mix_into(b,n,Synth.n_of(0.05+s*stroke),1.0)
	Synth.lowpass(b,5000.0)
	return b

## A long rip, lengthwise: tearing that speeds up and ends in a pop and a flap.
static func rip(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.9+0.2*v
	var b:=Synth.buffer(d+0.3)
	var t:=0.0
	while t<d:
		var x:=t/d
		Synth.burst(b,t,0.0018,rng.randf_range(1200.0,3800.0),1.3,rng.randf_range(0.3,1.0)*(0.4+0.6*x),rng)
		t+=lerpf(0.02,0.0025,x)*rng.randf_range(0.6,1.4)
	Synth.mix_into(b,_wet(d,[[0.0,500.0],[d,900.0]],1.5,rng,[[0.0,0.0],[d*0.3,0.4],[d,0.8]]),0,0.6)
	Synth.burst(b,d,0.01,1500.0,0.8,1.0,rng)
	Synth.mix_into(b,_wet(0.2,[[0.0,600.0],[0.2,250.0]],1.0,rng,[[0.0,1.0],[0.2,0.0]]),Synth.n_of(d+0.02),0.6)
	return b

# =============================================================================
# Liquids
# =============================================================================

## The cauldron on the boil: bubbles rising and bursting over a low rumble.
static func bubbling(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=4.0
	var b:=Synth.brown(d,rng,0.25)
	Synth.lowpass(b,200.0)
	_bubbles(b,0.0,d-0.1,70,180.0,900.0,0.5,rng)
	return Synth.seamless(b,0.3)

## Something heavy into the pot: the "bloop", the splash, drops falling back.
static func pot_plop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.9)
	Synth.mix_into(b,_sweep(0.16,240.0+v*30.0,95.0,[1.0,0.2],0.003),0,1.0)
	Synth.mix_into(b,_wet(0.35,[[0.0,2600.0],[0.35,1100.0]],1.0,rng,[[0.0,0.0],[0.006,1.0],[0.35,0.0]]),Synth.n_of(0.01),0.9)
	_bubbles(b,0.08,0.5,7,300.0,800.0,0.3,rng)
	for k in 8:Synth.burst(b,rng.randf_range(0.2,0.75),0.004,rng.randf_range(1800.0,3500.0),2.0,rng.randf_range(0.05,0.15),rng)
	# the pot rings a little
	Synth.modal(b,0.0,[Vector3(330.0,0.2,0.2),Vector3(790.0,0.1,0.12)],rng,1.0)
	return b

## The cook stirs: liquid swirling round, the spoon knocking the pot's side.
static func spoon_stir(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.6
	var b:=Synth.white(d,rng)
	var c:=Synth.buffer(d)
	for i in c.size():c[i]=700.0+350.0*sin(TAU*1.6*float(i)/RATE)
	var frames:=PackedFloat32Array();frames.resize(c.size()/32+1)
	for i in frames.size():frames[i]=c[mini(i*32,c.size()-1)]
	Synth.bandpass_track(b,frames,3.0)
	Synth.shape(b,[[0.0,0.0],[0.15,1.0],[d-0.2,1.0],[d,0.0]])
	for k in 3:Synth.modal(b,0.3+k*0.62,[Vector3(520.0,0.5,0.04),Vector3(1300.0,0.25,0.02)],rng,1.0)
	return b

## The blood geyser: spurts in time with a heart that has not heard the news,
## each weaker, a wet hiss and gurgle.
static func geyser(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.8
	var b:=Synth.buffer(d)
	var t:=0.0;var amp:=1.0
	while t<d-0.3:
		var spurt:=_wet(0.38,[[0.0,1600.0],[0.38,700.0]],1.2,rng,[[0.0,0.0],[0.01,1.0],[0.38,0.0]])
		Synth.mix_into(b,spurt,Synth.n_of(t),amp)
		_bubbles(b,t+0.05,t+0.3,3,200.0,450.0,0.3*amp,rng)
		t+=0.42+0.05*v;amp*=0.78
	Synth.lowpass(b,2800.0)
	return b

## Patter on the front row: drops landing, a lot and then fewer, a few big drips.
static func patter(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.0
	var b:=Synth.buffer(d)
	var t:=0.0
	while t<d:
		var x:=t/d
		Synth.burst(b,t,0.003,rng.randf_range(2000.0,5000.0),2.0,rng.randf_range(0.2,0.8)*(1.0-0.7*x),rng)
		if rng.randf()<0.25:Synth.mix_into(b,_sweep(0.03,rng.randf_range(400.0,800.0),300.0,[1.0],0.001),Synth.n_of(t),0.2)
		t+=lerpf(0.006,0.12,x*x)*rng.randf_range(0.5,1.5)
	for k in 3:Synth.mix_into(b,_sweep(0.05,1400.0,2200.0,[1.0],0.002),Synth.n_of(rng.randf_range(0.6,1.9)),0.4)
	return b

## The head blinks: a tiny wet "plip".
static func blink(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.15)
	Synth.mix_into(b,_sweep(0.035,1700.0,2500.0,[1.0],0.001),0,1.0)
	Synth.burst(b,0.0,0.002,3500.0,2.0,0.3,rng)
	return b

# =============================================================================
# Beasts
# =============================================================================

static func _beast(f0:float,fs:float,extra:Dictionary)->Dictionary:
	var v:=Voice.plain("man",int(f0))
	v["f0"]=f0;v["fs"]=fs
	v.merge(extra,true)
	return v

## The bear swallows them whole: GLORP, throat working.
static func bear_swallow(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.2)
	var bear:=_beast(62.0,0.72,{"breath":0.3,"jitter":0.05,"shimmer":0.2,"fry":0.15,"rd":1.0})
	var gl:=Voice.gesture(bear,[[0.02,"o",0.0,0.0,1.0,0.8],[0.25,"o",0.9,0.3,0.85,0.8],[0.25,"u",0.8,0.2,0.7,1.0],[0.05,"u",0.0,0.0,0.7]],rng.randi())
	Synth.mix_into(b,gl,0,1.0)
	Synth.mix_into(b,_sweep(0.3,380.0,110.0,[1.0,0.3],0.005),Synth.n_of(0.15),0.7)
	for k in 3:Synth.burst(b,0.55+k*0.12,0.006,900.0,2.0,0.3,rng)
	return b

## A long, satisfied burp.
static func burp(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var who:=_beast(72.0 if v==0 else 95.0,0.78 if v==0 else 0.9,{"breath":0.25,"jitter":0.08,"shimmer":0.3,"fry":0.3,"rd":0.7})
	var b:=Voice.gesture(who,[[0.02,"o",0.0,0.0,1.0],[0.25,"o",0.9,0.2,1.1],[0.35,"a",1.0,0.25,0.95],[0.25,"o",0.8,0.2,0.8],[0.05,"u",0.0,0.0,0.8]],rng.randi())
	var out:=Synth.buffer(1.1)
	Synth.mix_into(out,b,0,1.0)
	Synth.burst(out,0.9,0.006,700.0,1.0,0.4,rng)
	return out

## An elephant trumpets: a rough brassy tone rising and wavering through its trunk.
static func trumpet(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.3
	var p:=Synth.track(d,[[0.0,330.0+v*40.0],[0.15,520.0+v*60.0],[0.9,480.0],[d,420.0]])
	var growl:=Synth.wander(d,0.04,rng,0.9,1.1)
	for i in p.size():p[i]*=growl[i]
	var harm:Array=[]
	for k in 18:harm.append(1.0/float(k+1))
	var b:=Synth.tone(p,harm)
	for i in b.size():b[i]*=0.7+0.3*sin(TAU*27.0*float(i)/RATE)
	var trunk:=b.duplicate()
	Synth.resonate(trunk,1250.0,300.0)
	var bell:=b.duplicate()
	Synth.resonate(bell,2700.0,500.0)
	for i in b.size():b[i]=b[i]*0.2+trunk[i]+bell[i]*0.5
	var air:=Synth.white(d,rng,0.15)
	Synth.bandpass(air,2000.0,0.8)
	for i in b.size():b[i]+=air[i]
	Synth.shape(b,[[0.0,0.0],[0.06,1.0],[d*0.7,0.9],[d,0.0]])
	Synth.lowpass(b,6000.0)
	return b

## The pig pen: grunts, squeals and chomping, many pigs at once.
static func pig_swarm(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=3.2
	var b:=Synth.buffer(d)
	for k in 16:
		var at:=rng.randf_range(0.0,d-0.4)
		if rng.randf()<0.7:
			var pig:=_beast(rng.randf_range(95.0,140.0),0.95,{"breath":0.4,"jitter":0.06,"shimmer":0.25,"fry":0.1,"nasal":0.6})
			var g:=Voice.gesture(pig,[[0.01,"o",0.0,0.0,1.0,1.0],[0.08,"o",0.8,0.4,1.25,1.0],[0.07,"u",0.6,0.3,0.9,1.0],[0.02,"u",0.0,0.0,0.9]],rng.randi())
			Synth.mix_into(b,g,Synth.n_of(at),rng.randf_range(0.5,1.0))
		else:
			var sq:=_sweep(0.25,rng.randf_range(900.0,1300.0),rng.randf_range(1300.0,1700.0),[1.0,0.4,0.2],0.01)
			Synth.mix_into(b,sq,Synth.n_of(at),rng.randf_range(0.2,0.45))
	var t:=0.1
	while t<d-0.1:
		Synth.burst(b,t,0.006,rng.randf_range(1500.0,3000.0),1.5,rng.randf_range(0.1,0.3),rng);t+=rng.randf_range(0.04,0.15)
	return b

## The ox lows: "mmmoooaaa".
static func ox_low(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var ox:=_beast(92.0+v*12.0,0.8,{"breath":0.2,"jitter":0.03,"shimmer":0.1})
	return Voice.gesture(ox,[[0.02,"u",0.0,0.0,1.0,1.0],[0.3,"u",0.8,0.1,1.1,1.0],[0.5,"o",1.0,0.15,1.25],[0.6,"a",0.9,0.2,1.0],[0.2,"o",0.5,0.2,0.85],[0.05,"u",0.0,0.0,0.8]],rng.randi())

## The camp dogs growl and snarl as they drag their dinner off.
static func dog_snarl(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var dog:=_beast(85.0+v*20.0,1.25,{"breath":0.45,"jitter":0.1,"shimmer":0.35,"fry":0.25,"rd":0.8})
	var b:=Voice.gesture(dog,[[0.02,"a",0.0,0.0,1.0],[0.5,"a",0.7,0.5,1.05],[0.3,"ae",0.8,0.5,1.4],[0.3,"a",0.6,0.5,1.0],[0.05,"a",0.0,0.0,1.0]],rng.randi())
	for i in b.size():b[i]*=0.6+0.4*sin(TAU*31.0*float(i)/RATE)
	return b

## A body dragged over the earth floor.
static func drag(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.6
	var b:=Synth.pink(d,rng,1.0)
	Synth.lowpass(b,1600.0)
	var scrape:=Synth.white(d,rng,0.4)
	Synth.bandpass(scrape,2100.0,1.5)
	for i in b.size():b[i]+=scrape[i]
	var grit:=Synth.wander(d,0.01,rng,0.3,1.0)
	var tugs:=Synth.buffer(d)
	for i in tugs.size():tugs[i]=0.4+0.6*pow(0.5+0.5*sin(TAU*1.8*float(i)/RATE),2.0)
	for i in b.size():b[i]*=grit[i]*tugs[i]
	Synth.shape(b,[[0.0,0.0],[0.1,1.0],[d*0.7,0.8],[d,0.0]])
	return b

## A bone dropped at the god's feet: a dry knock, a bounce.
static func bone_drop(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.6)
	Synth.modal(b,0.0,[Vector3(640.0+v*80.0,1.0,0.04),Vector3(1580.0,0.5,0.025),Vector3(2900.0,0.25,0.015)],rng,1.0)
	Synth.mix_into(b,_sweep(0.06,160.0,110.0,[1.0]),0,0.4)
	Synth.modal(b,0.16,[Vector3(640.0+v*80.0,0.5,0.03),Vector3(1580.0,0.2,0.02)],rng,0.5)
	Synth.modal(b,0.26,[Vector3(640.0+v*80.0,0.25,0.02)],rng,0.4)
	return b

# =============================================================================
# Weapons
# =============================================================================

## One arrow arriving: a short hiss, a thunk into the target, the shaft's quiver.
static func arrow_thunk(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.6)
	Synth.mix_into(b,_wet(0.09,[[0.0,2400.0],[0.09,900.0]],1.5,rng,[[0.0,0.0],[0.07,1.0],[0.09,0.0]]),0,0.4)
	var at:=0.09
	Synth.burst(b,at,0.004,1500.0,1.0,0.8,rng)
	Synth.modal(b,at,[Vector3(190.0+v*25.0,0.7,0.05),Vector3(520.0,0.4,0.03)],rng,1.0)
	# the shaft quivers: a fast-wobbling twang, dying
	var q:=Synth.buffer(0.35)
	for i in q.size():
		var t:=float(i)/RATE
		q[i]=sin(TAU*(95.0+v*10.0)*t+2.0*sin(TAU*14.0*t))*exp(-t*12.0)
	Synth.mix_into(b,q,Synth.n_of(at+0.005),0.35)
	return b

## A volley: arrows hissing in and thunking home, close together, ragged.
static func arrow_volley(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(2.0)
	for k in 11:
		Synth.mix_into(b,arrow_thunk(k%3,rng),Synth.n_of(rng.randf_range(0.0,1.25)),rng.randf_range(0.6,1.0))
	return b

## A musket volley: a ragged rank of cracks and booms, then the smoke's echo.
static func musket_volley(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.8
	var b:=Synth.buffer(d)
	for k in 5+v*2:
		var at:=rng.randf_range(0.0,0.14)
		Synth.burst(b,at,0.006,3000.0,0.4,1.2,rng)
		Synth.burst(b,at,0.09,700.0,0.7,1.4,rng)
		Synth.mix_into(b,_sweep(0.35,140.0,60.0,[1.0,0.6,0.4,0.2],0.002),Synth.n_of(at),0.6)
	var tail:=Synth.brown(d,rng,1.0)
	Synth.lowpass(tail,500.0)
	Synth.shape(tail,[[0.0,0.0],[0.06,1.0],[0.6,0.4],[d,0.0]])
	Synth.mix_into(b,tail,0,0.35)
	var echo:=b.duplicate()
	Synth.lowpass(echo,1500.0)
	Synth.mix_into(b,echo,Synth.n_of(0.28),0.3)
	return b

## The cannon: a crack, a chest-deep boom, the rumble rolling away, bits falling.
static func cannon(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=3.6
	var b:=Synth.buffer(d)
	Synth.burst(b,0.0,0.01,2200.0,0.4,1.5,rng)
	Synth.mix_into(b,_sweep(0.9,58.0,28.0,[1.0,0.5,0.2],0.003),0,1.0)
	# the body of the BOOM, where small speakers can say it
	Synth.burst(b,0.0,0.6,320.0,0.6,2.2,rng)
	Synth.mix_into(b,_sweep(0.7,130.0,70.0,[1.0,0.8,0.6,0.45,0.3,0.2],0.003),0,0.9)
	var rumble:=Synth.brown(d,rng,1.0)
	Synth.lowpass(rumble,400.0)
	Synth.shape(rumble,[[0.0,0.0],[0.03,1.0],[1.2,0.5],[d,0.0]])
	Synth.mix_into(b,rumble,0,1.0)
	var t:=0.6
	while t<2.6:
		Synth.burst(b,t,0.004,rng.randf_range(1500.0,4000.0),1.2,rng.randf_range(0.05,0.2),rng);t+=rng.randf_range(0.03,0.2)
	return b

## The axe bites into the block and sticks: a deep wooden thunk, a creak.
static func axe_thunk(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.8)
	Synth.burst(b,0.0,0.004,2000.0,0.8,0.8,rng)
	Synth.modal(b,0.0,[Vector3(150.0+v*20.0,1.0,0.12),Vector3(410.0,0.6,0.07),Vector3(880.0,0.35,0.04),Vector3(1700.0,0.2,0.02)],rng,1.0)
	var creak:=_sweep(0.25,260.0,240.0,[1.0,0.5,0.3,0.2])
	for i in creak.size():creak[i]*=0.5+0.5*sin(TAU*45.0*float(i)/RATE)
	Synth.mix_into(b,creak,Synth.n_of(0.3),0.15)
	return b

## The second swing bounces off: a ringing CLANG, the haft buzzing in the hands.
static func axe_clang(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.2)
	Synth.burst(b,0.0,0.004,3500.0,0.6,0.8,rng)
	var ring:=Synth.buffer(1.1)
	Synth.modal(ring,0.0,[Vector3(1150.0+v*120.0,1.0,0.35),Vector3(2580.0,0.6,0.25),Vector3(4170.0,0.35,0.15)],rng,1.0)
	# the haft's buzz shakes the ring
	for i in ring.size():ring[i]*=0.55+0.45*sin(TAU*(23.0-12.0*float(i)/float(ring.size()))*float(i)/RATE)
	Synth.mix_into(b,ring,0,1.0)
	return b

## Working the stuck axe free: a strain, the wood creaking, a pop.
## Variant 1 is the wood alone (the grunts are the executioner's own strain):
## the creak working loose, and the pop as it comes free at 0.75 s.
static func axe_pull(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.3)
	if v==0:
		var man:=Voice.plain("man",61)
		man["oq"]=0.44;man["tremor"]=0.05;man["tremor_hz"]=9.0
		var g:=Voice.gesture(man,[[0.02,"y",0.0,0.0,1.0],[0.6,"y",0.7,0.2,1.2,0.8],[0.08,"y",0.0,0.3,1.0]],rng.randi())
		Synth.mix_into(b,g,0,0.7)
	var creak:=_sweep(0.6,300.0,340.0,[1.0,0.6,0.4,0.25])
	for i in creak.size():creak[i]*=0.4+0.6*pow(0.5+0.5*sin(TAU*38.0*float(i)/RATE),3.0)
	Synth.mix_into(b,creak,Synth.n_of(0.1),0.25 if v==0 else 0.45)
	Synth.modal(b,0.75,[Vector3(420.0,0.8,0.05),Vector3(1100.0,0.4,0.02)],rng,1.0)
	return b

## The head rolls across the earth floor, bump by bump, slowing, still.
static func head_roll(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.8)
	var t:=0.0;var gap:=0.12;var amp:=1.0
	while t<1.5 and amp>0.08:
		_thud(b,t,120.0+rng.randf_range(-10.0,10.0),amp,rng)
		t+=gap;gap*=1.17+0.05*v;amp*=0.8
	return b

# =============================================================================
# People
# =============================================================================

## The executioner's wind-up: a long breath in and a rising "hnnnnngh".
static func windup(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var man:=Voice.plain("man" if v==0 else "old_man",71+v)
	man["oq"]=0.44;man["breath"]=0.2
	return Voice.gesture(man,[[0.25,"a",0.0,0.7,1.0],[0.05,"y",0.0,0.0,1.0],[0.55,"y",0.7,0.2,1.35,0.8],[0.05,"y",0.0,0.0,1.4]],rng.randi())

## "Ow!": the axe bounced and stung the hands.
static func ow(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var man:=Voice.plain("man" if v==0 else "youth_m",83+v)
	return Voice.gesture(man,[[0.01,"a",0.0,0.0,1.3],[0.18,"a",1.0,0.2,1.55],[0.12,"o",0.8,0.1,1.2],[0.08,"u",0.0,0.1,1.1]],rng.randi())

## Someone in the front row is sick into a pot: the heave, again, and the splash.
static func retch(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.9)
	var who:=Voice.plain("man" if v==0 else "woman",97+v)
	who["breath"]=0.5;who["fry"]=0.25;who["jitter"]=0.05
	var heave:=[[0.05,"a",0.0,0.6,1.0],[0.02,"a",0.0,0.0,1.0],[0.22,"o",0.9,0.5,0.85],[0.06,"a",0.0,0.0,0.8]]
	Synth.mix_into(b,Voice.gesture(who,heave,rng.randi()),0,0.8)
	Synth.mix_into(b,Voice.gesture(who,[[0.03,"a",0.0,0.6,1.0],[0.3,"a",1.0,0.6,0.75],[0.06,"a",0.0,0.0,0.7]],rng.randi()),Synth.n_of(0.55),1.0)
	var splash:=_wet(0.45,[[0.0,1800.0],[0.45,700.0]],1.0,rng,[[0.0,0.0],[0.01,1.0],[0.45,0.0]])
	Synth.mix_into(b,splash,Synth.n_of(0.72),0.8)
	_bubbles(b,0.8,1.2,5,250.0,500.0,0.2,rng)
	Synth.modal(b,0.72,[Vector3(310.0,0.3,0.15),Vector3(760.0,0.15,0.08)],rng,1.0)
	return b

## The hall's disgust: a few people's "ughh", a beat apart.
static func crowd_groan(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.5)
	var regs:=["man","woman","old_woman","man","youth_f"]
	for k in 5:
		var who:=Voice.plain(String(regs[(k+v)%regs.size()]),131+k*7+v)
		who["breath"]=0.3
		var g:=Voice.gesture(who,[[0.02,"u",0.0,0.0,1.0],[0.12,"u",0.7,0.3,1.05],[0.4,"a",0.6,0.4,0.82],[0.06,"a",0.0,0.1,0.8]],rng.randi())
		Synth.mix_into(b,g,Synth.n_of(rng.randf_range(0.0,0.3)),rng.randf_range(0.5,1.0))
	Synth.lowpass(b,4000.0)
	return b

## The flatterer applauds, alone: a few claps, slowing, into silence.
static func lone_clap(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(3.0)
	var t:=0.02;var gap:=0.42
	for k in 5+v:
		Synth.burst(b,t,0.012,rng.randf_range(1200.0,1700.0),0.8,1.0,rng)
		Synth.mix_into(b,_sweep(0.02,450.0,380.0,[1.0],0.001),Synth.n_of(t),0.4)
		t+=gap;gap*=1.17
	return b

# =============================================================================
# The musician
# =============================================================================

## The drum roll before: taps quickening and swelling, and no end to it (the
## hit comes on the punchline).
static func drum_roll(v:int,rng:RandomNumberGenerator,kind:String)->PackedFloat32Array:
	var d:=2.2
	var b:=Synth.buffer(d+0.3)
	var t:=0.0
	while t<d:
		var x:=t/d
		var hit:=Music.drum(kind,"t",0.35+0.6*x,rng)
		Synth.mix_into(b,hit,Synth.n_of(t),1.0)
		t+=lerpf(0.11,0.045,x)*rng.randf_range(0.9,1.1)
	return b

## No drum yet: hands drumming on a log, quickening.
static func log_roll(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.2
	var b:=Synth.buffer(d+0.3)
	var t:=0.0
	while t<d:
		var x:=t/d
		Synth.modal(b,t,[Vector3(rng.randf_range(210.0,250.0),0.8,0.05),Vector3(620.0,0.4,0.03)],rng,0.35+0.6*x)
		Synth.burst(b,t,0.006,900.0,0.8,0.2+0.3*x,rng)
		t+=lerpf(0.12,0.05,x)*rng.randf_range(0.9,1.1)
	return b

## The punchline on a drum: ba-DUM.
static func punch_drum(v:int,rng:RandomNumberGenerator,kind:String)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	Synth.mix_into(b,Music.drum(kind,"t",0.7,rng),0,1.0)
	Synth.mix_into(b,Music.drum(kind,"d",1.0,rng),Synth.n_of(0.17),1.2)
	return b

## The punchline with small cymbals (once the people have them): ba-dum-TSS.
static func punch_cymbal(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(2.0)
	Synth.mix_into(b,Music.drum("clay","t",0.7,rng),0,1.0)
	Synth.mix_into(b,Music.drum("clay","d",1.0,rng),Synth.n_of(0.16),1.1)
	Synth.mix_into(b,Music.cymbal(rng),Synth.n_of(0.34),1.4)
	return b

## The punchline on a log: tok-TOK.
static func punch_log(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.7)
	Synth.modal(b,0.0,[Vector3(240.0,0.6,0.05),Vector3(650.0,0.3,0.03)],rng,1.0)
	Synth.modal(b,0.17,[Vector3(200.0,1.0,0.08),Vector3(560.0,0.5,0.04)],rng,1.0)
	return b

# =============================================================================
# More pieces for the other acts
# =============================================================================

## A great stone rolling or grinding over the earth (0: a boulder tipped off a
## log; 1: the monolith let down, slower, deeper, the ropes groaning with it).
static func boulder_roll(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.8+0.8*v
	var b:=Synth.brown(d,rng,1.0)
	var mid:=Synth.pink(d,rng,0.5)
	Synth.lowpass(b,260.0 if v==0 else 180.0)
	Synth.bandpass(mid,600.0,0.8)
	var turn:=0.24 if v==0 else 0.5
	for i in b.size():
		var t:=float(i)/RATE
		var bump:=0.55+0.45*pow(0.5+0.5*sin(TAU*t/turn),3.0)
		b[i]=(b[i]+mid[i])*bump
	var t2:=0.05
	while t2<d-0.1:
		Synth.burst(b,t2,0.003,rng.randf_range(1500.0,3500.0),1.2,rng.randf_range(0.05,0.25),rng);t2+=rng.randf_range(0.02,0.1)
	Synth.shape(b,[[0.0,0.0],[0.2,1.0],[d-0.3,0.9],[d,0.0]])
	return b

## Ash falling in on itself: a dense sift of grains, thinning, a soft puff.
static func crumble(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.6
	var b:=Synth.buffer(d+0.3)
	var t:=0.0
	while t<d:
		var x:=t/d
		Synth.burst(b,t,0.002,rng.randf_range(2500.0,6000.0),1.5,rng.randf_range(0.1,0.5)*(1.0-0.8*x),rng)
		t+=lerpf(0.002,0.03,x)
	var hiss:=Synth.pink(d,rng,0.4)
	Synth.lowpass(hiss,1800.0)
	Synth.shape(hiss,[[0.0,0.0],[0.1,1.0],[d,0.0]])
	Synth.mix_into(b,hiss,0,0.6)
	Synth.mix_into(b,smoke_poof(0,rng),Synth.n_of(d),0.5)
	return b

## A soft "poof" (a smoke ring coughed out; the last of the ash settling).
static func smoke_poof(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.pink(0.25,rng,1.0)
	Synth.lowpass2(b,700.0)
	Synth.shape(b,[[0.0,0.0],[0.015,1.0],[0.25,0.0]])
	var out:=Synth.buffer(0.3)
	Synth.mix_into(out,b,0,1.0)
	Synth.burst(out,0.0,0.004,1500.0,1.0,0.3,rng)
	return out

## A spear arrives and sticks: a hiss, a deep thunk, the long shaft wobbling.
static func spear_thunk(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	Synth.mix_into(b,_wet(0.16,[[0.0,1600.0],[0.16,600.0]],1.3,rng,[[0.0,0.0],[0.12,1.0],[0.16,0.0]]),0,0.5)
	var at:=0.16
	Synth.burst(b,at,0.005,1200.0,0.9,0.9,rng)
	Synth.modal(b,at,[Vector3(140.0+v*15.0,0.9,0.08),Vector3(380.0,0.5,0.05),Vector3(820.0,0.25,0.03)],rng,1.0)
	var q:=Synth.buffer(0.75)
	for i in q.size():
		var t:=float(i)/RATE
		q[i]=sin(TAU*(70.0+v*8.0)*t+3.0*sin(TAU*9.0*t))*exp(-t*5.0)
	Synth.mix_into(b,q,Synth.n_of(at+0.01),0.45)
	return b

## A spear into the hide windbreak instead: a flappy thump and the stakes rattling.
static func hide_thwap(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.7)
	var flap:=Synth.white(0.12,rng)
	Synth.lowpass2(flap,800.0)
	Synth.shape(flap,[[0.0,0.0],[0.004,1.0],[0.12,0.0]])
	Synth.mix_into(b,flap,0,1.0)
	Synth.modal(b,0.0,[Vector3(95.0,0.6,0.08),Vector3(210.0,0.3,0.05)],rng,1.0)
	for k in 4:Synth.modal(b,0.05+k*0.07,[Vector3(rng.randf_range(400.0,700.0),0.25,0.03)],rng,1.0-0.2*k)
	return b

## Stone on stone: the cairn growing.
static func stone_clack(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.35)
	Synth.burst(b,0.0,0.003,3000.0,0.8,0.8,rng)
	Synth.modal(b,0.0,[Vector3(1650.0+v*230.0,0.8,0.025),Vector3(3100.0+v*180.0,0.5,0.015),Vector3(780.0+v*60.0,0.4,0.03)],rng,1.0)
	Synth.mix_into(b,_sweep(0.06,200.0,140.0,[1.0]),0,0.3)
	return b

## A digging stick or hoe into earth, and the earth thrown aside.
static func dig(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.9)
	var bite:=Synth.white(0.12,rng)
	Synth.lowpass(bite,1600.0)
	var grit:=Synth.wander(0.12,0.004,rng,0.2,1.0)
	for i in bite.size():bite[i]*=grit[i]
	Synth.shape(bite,[[0.0,0.0],[0.01,1.0],[0.12,0.0]])
	Synth.mix_into(b,bite,0,1.0)
	_thud(b,0.0,110.0,0.4,rng)
	var land:=Synth.white(0.25,rng)
	Synth.lowpass(land,1200.0)
	Synth.shape(land,[[0.0,0.0],[0.02,1.0],[0.25,0.0]])
	Synth.mix_into(b,land,Synth.n_of(0.45),0.5)
	return b

## A heavy hoof on the earth floor (an ox, a cow).
static func hoof(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.35)
	_thud(b,0.0,85.0+v*10.0,0.8,rng)
	Synth.modal(b,0.004,[Vector3(380.0+v*40.0,0.5,0.03),Vector3(900.0,0.2,0.015)],rng,1.0)
	return b

## A herd stampeding through the hall: hooves on hooves, bleats and lows, the rumble.
static func stampede(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=3.2
	var b:=Synth.buffer(d)
	var t:=0.0
	while t<d-0.3:
		var x:=t/d
		var amp:=sin(PI*minf(1.0,x*1.1))
		Synth.mix_into(b,hoof(rng.randi_range(0,1),rng),Synth.n_of(t),amp*rng.randf_range(0.5,1.0))
		t+=rng.randf_range(0.03,0.09)
	var rumble:=Synth.brown(d,rng,1.0)
	Synth.lowpass(rumble,200.0)
	Synth.shape(rumble,[[0.0,0.0],[d*0.4,1.0],[d,0.0]])
	Synth.mix_into(b,rumble,0,0.4)
	return b

## Dry bones: 0 a skeleton getting up (a rising clatter); 1 one falling in a heap.
static func bones_rattle(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.2
	var b:=Synth.buffer(d+0.3)
	var t:=0.0
	while t<d:
		var x:=t/d
		var density:=lerpf(0.05,0.012,x) if v==0 else lerpf(0.006,0.08,x)
		var amp:=(0.4+0.6*x) if v==0 else (1.0-0.8*x)
		Synth.modal(b,t,[Vector3(rng.randf_range(900.0,2600.0),0.6,0.012),Vector3(rng.randf_range(2600.0,4200.0),0.3,0.008)],rng,amp)
		t+=density*rng.randf_range(0.5,1.5)
	if v==1:Synth.mix_into(b,_sweep(0.1,180.0,120.0,[1.0,0.5]),Synth.n_of(0.05),0.4)
	return b

## A rope under a weight: fibres creaking against the beam (0); swinging, a
## creak at each end of the swing, dying away (1).
static func rope_creak(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.0 if v==0 else 4.0
	var b:=Synth.buffer(d+0.2)
	var times:Array=[0.0] if v==0 else [0.0,1.05,2.1,3.15]
	var k:=0
	for at in times:
		var amp:=pow(0.7,k)
		var imp:=Synth.buffer(0.7)
		var t:=0.0
		while t<0.6:
			var i0:=Synth.n_of(t)
			if i0<imp.size():imp[i0]+=rng.randf_range(0.5,1.0)*sin(PI*t/0.6)
			t+=1.0/lerpf(70.0,180.0,sin(PI*t/0.6))*rng.randf_range(0.85,1.15)
		for m in [[320.0,30.0,1.0],[740.0,40.0,0.6],[1350.0,60.0,0.3]]:
			var ring:=imp.duplicate()
			Synth.resonate(ring,float(m[0]),float(m[1]))
			Synth.mix_into(b,ring,Synth.n_of(float(at)),float(m[2])*amp)
		k+=1
	Synth.highpass(b,120.0)
	return b

## Tasting from the ladle: a slurp, a thoughtful "mm".
static func slurp(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.3)
	var s:=_wet(0.5,[[0.0,500.0],[0.5,2200.0]],3.0,rng,[[0.0,0.0],[0.05,1.0],[0.45,0.8],[0.5,0.0]])
	var bub:=Synth.wander(0.5,0.008,rng,0.3,1.0)
	for i in s.size():s[i]*=bub[i]
	Synth.mix_into(b,s,0,1.0)
	var cook:=Voice.plain("woman" if v==1 else "man",211)
	Synth.mix_into(b,Voice.gesture(cook,[[0.01,"u",0.0,0.0,1.0,1.0],[0.25,"u",0.6,0.05,1.1,1.0],[0.2,"u",0.6,0.05,0.95,1.0],[0.03,"u",0.0,0.0,0.9,1.0]],rng.randi()),Synth.n_of(0.7),0.6)
	return b

## A pinch of salt into the pot.
static func sprinkle(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.6)
	for k in 40:Synth.burst(b,rng.randf_range(0.0,0.45),0.0015,rng.randf_range(3000.0,7000.0),2.0,rng.randf_range(0.1,0.4),rng)
	return b

## A long slow squelch: sliding down the stake.
static func slow_squelch(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.6
	var b:=_wet(d,[[0.0,300.0],[0.8,700.0],[1.6,400.0],[d,600.0]],5.0,rng,[[0.0,0.0],[0.2,1.0],[d-0.3,0.9],[d,0.0]])
	var stick:=Synth.wander(d,0.05,rng,0.2,1.0)
	for i in b.size():b[i]*=stick[i]
	for k in 5:Synth.mix_into(b,bone_pop(k%3,rng),Synth.n_of(rng.randf_range(0.2,d-0.3)),0.15)
	return b

## The bear: a deep roar, its breath in it.
static func bear_roar(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var bear:=_beast(88.0,0.7,{"breath":0.5,"jitter":0.12,"shimmer":0.4,"fry":0.3,"rd":0.6})
	var b:=Voice.gesture(bear,[[0.03,"a",0.0,0.3,1.0],[0.5,"a",1.0,0.6,1.2],[0.6,"o",0.9,0.6,0.85],[0.2,"o",0.4,0.4,0.7],[0.04,"o",0.0,0.0,0.7]],rng.randi())
	for i in b.size():b[i]*=0.65+0.35*sin(TAU*24.0*float(i)/RATE)
	return b

## "Ptoo": something spat out, flying, landing with a slap.
static func spit(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.1)
	Synth.burst(b,0.0,0.01,1800.0,1.0,1.0,rng)
	Synth.mix_into(b,_wet(0.12,[[0.0,1200.0],[0.12,700.0]],1.5,rng,[[0.0,1.0],[0.12,0.0]]),Synth.n_of(0.01),0.6)
	Synth.mix_into(b,_wet(0.35,[[0.0,800.0],[0.35,1400.0]],1.0,rng,[[0.0,0.0],[0.3,1.0],[0.35,0.0]]),Synth.n_of(0.1),0.25)
	var land:=Synth.white(0.05,rng)
	Synth.bandpass(land,1400.0,0.8)
	Synth.shape(land,[[0.0,1.0],[0.05,0.0]])
	Synth.mix_into(b,land,Synth.n_of(0.5),0.9)
	Synth.mix_into(b,_sweep(0.05,220.0,160.0,[1.0]),Synth.n_of(0.5),0.4)
	return b

## Molten bronze meeting something cooler: a hiss of steam, spitting.
static func sizzle(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.4
	var b:=Synth.white(d,rng)
	Synth.bandpass(b,4500.0,1.2)
	var steam:=Synth.pink(d,rng,1.0)
	Synth.bandpass(steam,1200.0,0.8)
	for i in b.size():b[i]=b[i]*0.7+steam[i]*0.5
	Synth.shape(b,[[0.0,0.0],[0.05,1.0],[0.8,0.7],[d,0.0]])
	var t:=0.0
	while t<d-0.2:
		Synth.burst(b,t,0.002,rng.randf_range(2500.0,6000.0),1.0,rng.randf_range(0.3,0.9)*(1.0-t/d),rng);t+=rng.randf_range(0.01,0.06)
	Synth.lowpass(b,7000.0)
	return b

## A crank's pawl clicking over its ratchet, quick and steady.
static func ratchet(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=1.4+0.4*v
	var b:=Synth.buffer(d)
	var t:=0.02
	while t<d-0.05:
		Synth.modal(b,t,[Vector3(rng.randf_range(1500.0,1700.0),0.7,0.015),Vector3(3300.0,0.4,0.01)],rng,1.0)
		Synth.burst(b,t,0.002,2500.0,1.5,0.4,rng)
		t+=0.12-0.02*v
	var creak:=creak_wood(rng,d)
	Synth.mix_into(b,creak,0,0.25)
	return b

static func creak_wood(rng:RandomNumberGenerator,d:float)->PackedFloat32Array:
	var c:=_sweep(d,180.0,210.0,[1.0,0.6,0.4,0.25,0.15])
	for i in c.size():c[i]*=0.4+0.6*pow(0.5+0.5*sin(TAU*31.0*float(i)/RATE),3.0)
	Synth.shape(c,[[0.0,0.0],[0.1,1.0],[d-0.1,1.0],[d,0.0]])
	return c

## The catapult's arm let go: a huge wooden THWACK on the crossbar, and the throw.
static func catapult_thwack(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	Synth.mix_into(b,_wet(0.3,[[0.0,300.0],[0.25,1400.0],[0.3,600.0]],1.0,rng,[[0.0,0.0],[0.25,1.0],[0.3,0.0]]),0,0.7)
	var at:=0.28
	Synth.burst(b,at,0.006,2000.0,0.6,1.2,rng)
	Synth.modal(b,at,[Vector3(115.0,1.0,0.18),Vector3(330.0,0.6,0.1),Vector3(690.0,0.35,0.06),Vector3(1400.0,0.2,0.03)],rng,1.0)
	_thud(b,at,70.0,0.6,rng)
	return b

## A single tooth landing on the floor: tink, tink-tink.
static func tooth_tink(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.6)
	var at:=0.0;var amp:=1.0;var gap:=0.16
	for k in 4:
		Synth.modal(b,at,[Vector3(3800.0,0.8,0.02),Vector3(5900.0,0.4,0.012)],rng,amp)
		at+=gap;gap*=0.6;amp*=0.5
	return b

## Something landing in a wicker basket.
static func basket_thump(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.5)
	_thud(b,0.0,130.0,0.8,rng)
	for k in 16:Synth.burst(b,rng.randf_range(0.0,0.12),0.002,rng.randf_range(1500.0,3500.0),1.5,rng.randf_range(0.1,0.35),rng)
	return b

## A rank of muskets cocked: click... click-click... click.
static func musket_cock(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.2)
	for at in [0.0,0.28,0.36,0.62,0.9]:
		Synth.modal(b,float(at),[Vector3(2400.0,0.6,0.012),Vector3(4100.0,0.4,0.008)],rng,1.0)
		Synth.modal(b,float(at)+0.03,[Vector3(1900.0,0.5,0.01)],rng,0.7)
	return b

## A fuse burning down: a fizzing crackle.
static func fuse(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=2.2
	var b:=Synth.white(d,rng,0.4)
	Synth.bandpass(b,3800.0,1.0)
	var t:=0.0
	while t<d:
		Synth.burst(b,t,0.0015,rng.randf_range(3000.0,7000.0),1.5,rng.randf_range(0.2,0.8),rng);t+=rng.randf_range(0.005,0.03)
	Synth.shape(b,[[0.0,0.0],[0.05,1.0],[d-0.05,1.0],[d,0.0]])
	return b

## A cloth wiping a tablet clean, back and forth.
static func wipe(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.2)
	for k in 4:
		var s:=Synth.white(0.22,rng)
		Synth.bandpass(s,1600.0,0.8)
		Synth.shape(s,[[0.0,0.0],[0.08,1.0],[0.22,0.0]])
		Synth.mix_into(b,s,Synth.n_of(0.02+k*0.27),0.9)
	return b

## A foot (or a hoof) shaken clean: two quick wet flicks.
static func flick(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.7)
	for k in 2:
		Synth.mix_into(b,_wet(0.12,[[0.0,700.0],[0.12,1500.0]],2.0,rng,[[0.0,0.0],[0.03,1.0],[0.12,0.0]]),Synth.n_of(0.02+k*0.25),0.8)
		for j in 5:Synth.burst(b,0.08+k*0.25+rng.randf_range(0.0,0.15),0.003,rng.randf_range(2000.0,4000.0),1.5,0.2,rng)
	return b

# =============================================================================
# K's clips: the club's taps, the soup in the cook's face, the pats on the lid,
# the dog's tugs and the fingers slipping
# =============================================================================

## The club tapped on the floor, like a batter at the plate: a dry wooden
## knock on packed earth.
static func club_tap(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.35)
	_thud(b,0.0,150.0+v*20.0,0.5,rng)
	Synth.modal(b,0.0,[Vector3(780.0+v*90.0,0.9,0.035),Vector3(1650.0+v*120.0,0.45,0.02),Vector3(2900.0,0.2,0.01)],rng,1.0)
	for k in 6:Synth.burst(b,rng.randf_range(0.004,0.05),0.002,rng.randf_range(2000.0,4000.0),1.5,rng.randf_range(0.05,0.15),rng)
	return b

## The pot's broth in the cook's face: a wet slap, drips, and a spluttered "pff".
static func face_splash(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(1.0)
	Synth.mix_into(b,_wet(0.16,[[0.0,2600.0],[0.16,900.0]],1.2,rng,[[0.0,0.0],[0.004,1.0],[0.16,0.0]]),0,1.0)
	Synth.mix_into(b,_sweep(0.06,260.0,170.0,[1.0,0.3]),0,0.35)
	_bubbles(b,0.12,0.55,7,900.0,2200.0,0.25,rng)
	# the cook blows it off his lips
	var pff:=Synth.white(0.18,rng)
	Synth.bandpass(pff,1100.0,0.9)
	Synth.shape(pff,[[0.0,0.0],[0.01,1.0],[0.05,0.6],[0.18,0.0]])
	for i in pff.size():pff[i]*=0.6+0.4*sin(TAU*31.0*float(i)/RATE)
	Synth.mix_into(b,pff,Synth.n_of(0.6),0.5)
	return b

## A hand patting a clay lid: a soft palm thump with the pot's short ring.
static func lid_pat(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.4)
	_thud(b,0.0,190.0+v*15.0,0.6,rng)
	Synth.modal(b,0.0,[Vector3(520.0+v*30.0,0.5,0.06),Vector3(1310.0,0.25,0.03)],rng,0.6)
	var palm:=Synth.white(0.03,rng)
	Synth.bandpass(palm,900.0,0.8)
	Synth.shape(palm,[[0.0,1.0],[0.03,0.0]])
	Synth.mix_into(b,palm,0,0.5)
	return b

## The dog's tug: a jerk of cloth and a body dragged a hand's breadth, a growl in it.
static func tug(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var d:=0.42
	var b:=Synth.pink(d,rng,1.0)
	Synth.lowpass(b,1500.0)
	var scrape:=Synth.white(d,rng,0.5)
	Synth.bandpass(scrape,1900.0+v*200.0,1.4)
	for i in b.size():b[i]+=scrape[i]
	Synth.shape(b,[[0.0,0.0],[0.015,1.0],[0.12,0.7],[d,0.0]])
	# the cloth snapping taut
	var snap:=Synth.white(0.04,rng)
	Synth.bandpass(snap,3200.0,1.0)
	Synth.shape(snap,[[0.0,1.0],[0.04,0.0]])
	Synth.mix_into(b,snap,0,0.5)
	# the growl through teeth: a low buzz, rough
	var growl:=_sweep(0.3,95.0+v*8.0,80.0,[1.0,0.7,0.5,0.35,0.25],0.02)
	for i in growl.size():growl[i]*=0.5+0.5*absf(sin(TAU*27.0*float(i)/RATE))
	Synth.mix_into(b,growl,Synth.n_of(0.02),0.45)
	return b

## Fingers slipping on the floor: a squeak and a short scrape of nails.
static func slip(v:int,rng:RandomNumberGenerator)->PackedFloat32Array:
	var b:=Synth.buffer(0.3)
	var f0:=1500.0+v*260.0
	var squeak:=_sweep(0.12,f0,f0*1.35,[1.0,0.3],0.01)
	for i in squeak.size():squeak[i]*=0.6+0.4*sin(TAU*55.0*float(i)/RATE)
	Synth.mix_into(b,squeak,0,0.6)
	var nails:=Synth.white(0.2,rng)
	Synth.bandpass(nails,3400.0+v*300.0,1.6)
	Synth.shape(nails,[[0.0,0.0],[0.02,1.0],[0.2,0.0]])
	for i in nails.size():nails[i]*=0.5+0.5*pow(absf(sin(TAU*40.0*float(i)/RATE)),2.0)
	Synth.mix_into(b,nails,Synth.n_of(0.06),0.5)
	return b
