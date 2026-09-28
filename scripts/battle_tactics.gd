extends RefCounted
## BATTLE TACTICS: what a general actually does on the field, and when that
## becomes possible at all.
##
## Every entry is a real, long-attested way of fighting, named generically (no
## real battles, commanders or peoples). A tactic is available only when the
## side has what makes it possible: the discoveries behind it and the troops
## that carry it out (mounted wings for an envelopment, drilled foot for a
## dense line, armour and wireless for a breakthrough). Generals choose; the
## player never picks a tactic, though the general will talk about it.
##
## Effects are bounded per-round multipliers on the shared combat resolver's
## exposure (who takes the losses), never new casualty sources: each side's
## multiplier stays inside [ROUND_MIN, ROUND_MAX] and the combined value
## inside [COMBINED_MIN, COMBINED_MAX]. Whether a risky manoeuvre works is
## decided by the fighting itself (the side's share of combat power when the
## decisive round comes), not by a pre-rolled coin.
##
## Rivals follow the same rules. Their knowledge is inferred only from what
## they field and their general level of knowledge (known_from_force), never
## from the player's discoveries.
##
## Naval and air forces keep the drawn-zone mechanic. Inside a zone the fleet
## or air commander chooses a zone tactic from ZONE_TACTICS, gated the same
## way; its effect is a small bounded factor on the existing detection and
## damage multipliers (joint_battle.gd).
##
## Pure static helpers: callers pass forces, discovery ids and context, so
## tests need no scene. See docs/MILITARY_MAP_PRESENTATION.md.
##
## (An earlier draft of this file contributed the equipment-weighted
## composition count, the rigid-line idea and the map shape() keys.)

const UnitCatalog:=preload("res://scripts/military_unit_catalog.gd")

## Per-side, per-round exposure multipliers stay inside these bounds.
const ROUND_MIN:=0.6
const ROUND_MAX:=1.7
## Combined per-side exposure after both sides' tactics.
const COMBINED_MIN:=0.55
const COMBINED_MAX:=1.9
## Zone tactic factors (navy and air) stay inside these bounds.
const ZONE_MIN:=0.8
const ZONE_MAX:=1.25

const MISSILE:=["skirmisher","archer","slinger","javelineer","crossbowman","horse_archer","sharpshooter"]
const MOBILE:=["cavalry","light_cavalry","horse_archer","chariot","armored_cavalry","dragoon","war_elephant","motorized_infantry","armored_car","light_tank","heavy_tank","mechanized_infantry","armored_formation","air_assault"]
const SHOCK:=["line_infantry","spearman","pikeman","heavy_swordsman","axeman","mountain_infantry","grenadier"]
const PIKES:=["pikeman","spearman"]
const FIREARM:=["hand_cannoneer","musketeer","grenadier","sharpshooter","rifle_infantry","machine_gun_company","motorized_infantry","mechanized_infantry","assault_infantry","marines","paratrooper","dragoon","anti_tank","mountain_infantry"]
const ARTILLERY:=["field_artillery","modern_artillery","catapult_crew","trebuchet_crew","bombard_crew","horse_artillery","mortar_crew","rocket_artillery"]
const ENGINEER:=["siege_engineer","combat_engineer","ram_crew"]
const ARMOUR:=["armored_formation","light_tank","heavy_tank","mechanized_infantry","armored_car","tank_destroyer"]
const ASSAULT:=["assault_infantry","grenadier","marines","paratrooper"]

## The plain fight, available to everyone. The chosen tactic is this far more
## often than anything clever, as in the historical record.
const BASELINE:="head_on"

## Land catalogue. Keys:
##   names: era words ("hearth" before writing, "lettered", "reckoned").
##   requires_all / requires_any: discoveries (rivals: inferred knowledge).
##   needs: composition shares (missile, mobile, shock, pikes, firearm,
##          artillery, engineer, armour, assault) and min/max troops,
##          min_training, min_command, min_ratio, max_ratio, min_terrain.
##   needs_any: alternative need sets, one of which must hold.
##   roles: {attacker:weight, defender:weight}; kinds: field | raid | assault.
##   rigid: a formed line that a flank attack or envelopment punishes.
##   flank: a manoeuvre against the enemy's side or rear.
##   phases: [{from, to, own, enemy, intensity}] by battle round (1-based).
##   special: behaviour the phases cannot express (see side_effect).
##   shape: how the map draws it (hud/war_front_overlay.gd); era: first age.
const TACTICS:Dictionary={
	"head_on":{"names":{"hearth":"met them head-on","lettered":"a straight fight, line against line","reckoned":"a frontal battle"},
		"requires_all":[],"requires_any":[],"needs":{},"roles":{"attacker":1.0,"defender":1.0},"kinds":["field","raid","assault"],"weight":3.0,"trait":"",
		"phases":[],"shape":"clash","era":"stone"},
	"dawn_raid":{"names":{"hearth":"fell on them at first light","lettered":"a dawn attack","reckoned":"a surprise attack at dawn"},
		"requires_all":[],"requires_any":[],"needs":{"max_troops":800},"roles":{"attacker":1.0},"kinds":["raid","field"],"weight":1.4,"trait":"cunning",
		"phases":[{"from":1,"to":1,"own":0.75,"enemy":1.45},{"from":2,"to":2,"own":0.95,"enemy":1.12}],"shape":"strike","era":"stone"},
	# Only when the ruler orders it (night_approach): a general never gambles a
	# night march on his own. Unseen, the band falls on a camp asleep; seen,
	# it stumbles into a ready defence in the dark.
	"night_attack":{"names":{"hearth":"crept up on them in the dark","lettered":"a night attack","reckoned":"a surprise attack by night"},
		"requires_all":[],"requires_any":[],"needs":{},"roles":{"attacker":1.0},"kinds":["field","raid","assault"],"weight":0.0,"trait":"cunning","ordered":true,"special":"night_unseen",
		"phases":[{"from":1,"to":1,"own":0.65,"enemy":1.7},{"from":2,"to":2,"own":0.85,"enemy":1.3}],"shape":"strike","era":"stone"},
	"night_attack_seen":{"names":{"hearth":"came at them in the dark but were seen","lettered":"a night attack that was seen coming","reckoned":"a night attack met by a ready defence"},
		"requires_all":[],"requires_any":[],"needs":{},"roles":{"attacker":1.0},"kinds":["field","raid","assault"],"weight":0.0,"trait":"cunning","ordered":true,"special":"night_seen",
		"phases":[{"from":1,"to":1,"own":1.15,"enemy":0.95}],"shape":"strike","era":"stone"},
	"ambush":{"names":{"hearth":"lay in wait for them","lettered":"an ambush","reckoned":"an ambush from cover"},
		"requires_all":[],"requires_any":[],"needs":{"max_troops":4000,"min_terrain":1.08},"roles":{"defender":1.0,"attacker":0.35},"kinds":["raid","field"],"weight":1.2,"trait":"cunning",
		"phases":[{"from":1,"to":1,"own":0.7,"enemy":1.6},{"from":2,"to":2,"own":0.9,"enemy":1.1}],"shape":"ambush","era":"stone"},
	"missile_harassment":{"names":{"hearth":"wore them down with slings and arrows","lettered":"a screen of archers and slingers","reckoned":"a skirmish screen"},
		"requires_all":[],"requires_any":["bow_craft","woven_carriers","hafted_weapons"],"needs":{"missile":0.2},"roles":{"attacker":1.0,"defender":1.0},"kinds":["field","raid"],"weight":1.3,"trait":"careful",
		"phases":[{"from":1,"to":2,"own":0.8,"enemy":1.2,"intensity":0.85}],"shape":"screen","era":"stone"},
	"shield_wall":{"names":{"hearth":"locked shields","lettered":"a shield wall","reckoned":"a shield wall"},
		"requires_all":["shield_wall"],"requires_any":[],"needs":{"shock":0.35},"roles":{"defender":1.0,"attacker":0.4},"kinds":["field","assault"],"weight":1.5,"trait":"careful","rigid":true,
		"phases":[{"from":1,"to":99,"own":0.82,"enemy":0.95}],"shape":"shield_line","era":"bronze"},
	"dense_line":{"names":{"hearth":"a close-packed line of spears","lettered":"a deep line of spears","reckoned":"a deep infantry line"},
		"requires_all":["formation_drill"],"requires_any":["hafted_weapons","pike_drill","bronze_weaponry","shield_wall"],"needs":{"shock":0.4,"min_troops":300},"roles":{"attacker":1.0,"defender":1.0},"kinds":["field"],"weight":1.4,"trait":"","rigid":true,
		"phases":[{"from":1,"to":99,"own":0.9,"enemy":1.12}],"shape":"dense_line","era":"bronze"},
	"feigned_retreat":{"names":{"hearth":"ran as if beaten, then turned on them","lettered":"a feigned retreat","reckoned":"a feigned retreat"},
		"requires_all":[],"requires_any":["domesticated_mounts","formation_drill"],"needs":{"min_training":0.5},"needs_any":[{"mobile":0.2},{"missile":0.3,"min_training":0.55}],
		"roles":{"attacker":1.0,"defender":0.8},"kinds":["field"],"weight":0.55,"trait":"cunning","special":"feigned_retreat","shape":"feigned_retreat","era":"bronze"},
	"flank_attack":{"names":{"hearth":"came round their side","lettered":"a flank attack by the riders","reckoned":"a flanking attack"},
		"requires_all":[],"requires_any":["domesticated_mounts","war_chariots"],"needs":{"mobile":0.15},"roles":{"attacker":1.0,"defender":0.5},"kinds":["field"],"weight":1.0,"trait":"bold","flank":true,
		"phases":[{"from":2,"to":99,"own":1.02,"enemy":1.22}],"shape":"flank_hook","era":"bronze"},
	"reserve":{"names":{"hearth":"kept some back until the fight turned","lettered":"a reserve held back","reckoned":"a reserve held back for the decisive moment"},
		"requires_all":["formation_drill"],"requires_any":[],"needs":{"min_troops":800,"min_command":0.5},"roles":{"attacker":1.0,"defender":1.0},"kinds":["field","assault"],"weight":0.9,"trait":"careful",
		"phases":[{"from":1,"to":3,"own":0.9,"enemy":0.95},{"from":4,"to":99,"own":0.92,"enemy":1.25}],"shape":"reserve","era":"bronze"},
	"hammer_and_anvil":{"names":{"hearth":"held them with the spears and struck with the riders","lettered":"held them with foot and struck their rear with horse","reckoned":"hammer and anvil: infantry pinned them, cavalry struck the rear"},
		"requires_all":["formation_drill","domesticated_mounts"],"requires_any":[],"needs":{"shock":0.3,"mobile":0.15,"min_troops":1000},"roles":{"attacker":1.0,"defender":0.3},"kinds":["field"],"weight":0.7,"trait":"bold","flank":true,
		"phases":[{"from":1,"to":2,"own":0.95,"enemy":1.0},{"from":3,"to":99,"own":1.0,"enemy":1.35}],"shape":"hammer_anvil","era":"classical"},
	"double_envelopment":{"names":{"hearth":"let the middle give and closed both sides around them","lettered":"a double envelopment","reckoned":"a double envelopment"},
		"requires_all":["formation_drill"],"requires_any":["domesticated_mounts","war_chariots"],"needs":{"mobile":0.18,"min_troops":2000,"min_command":0.62,"min_ratio":0.8},"roles":{"attacker":0.8,"defender":1.0},"kinds":["field"],"weight":0.3,"trait":"bold","flank":true,
		"special":"double_envelopment","shape":"double_envelopment","era":"classical"},
	"oblique_order":{"names":{"hearth":"struck with one side, held the other back","lettered":"struck with one wing, holding the other back","reckoned":"an oblique attack, one flank refused"},
		"requires_all":["formation_drill","professional_corps"],"requires_any":[],"needs":{"min_troops":3000,"min_training":0.6},"roles":{"attacker":1.0,"defender":0.4},"kinds":["field"],"weight":0.45,"trait":"cunning",
		"phases":[{"from":1,"to":1,"own":0.92,"enemy":1.0},{"from":2,"to":99,"own":0.95,"enemy":1.2}],"shape":"oblique","era":"classical"},
	"fortified_camp":{"names":{"hearth":"fought from behind a ditch and stakes","lettered":"fought from a fortified camp","reckoned":"fought from prepared field works"},
		"requires_all":["field_fortifications"],"requires_any":[],"needs":{"max_ratio":1.1},"roles":{"defender":1.0},"kinds":["field"],"weight":1.1,"trait":"careful",
		"phases":[{"from":1,"to":99,"own":0.78,"enemy":1.1,"intensity":0.85}],"shape":"camp","era":"bronze"},
	"escalade":{"names":{"hearth":"climbed their walls","lettered":"an escalade with ladders","reckoned":"stormed the walls with ladders"},
		"requires_all":[],"requires_any":[],"needs":{},"roles":{"attacker":1.0},"kinds":["assault"],"weight":1.2,"trait":"bold",
		"phases":[{"from":1,"to":99,"own":1.25,"enemy":0.95}],"shape":"storm","era":"bronze"},
	"breach_and_storm":{"names":{"hearth":"broke the wall, then stormed the gap","lettered":"broke the wall with engines, then stormed the breach","reckoned":"breached the defences with guns, then stormed the breach"},
		"requires_all":[],"requires_any":["siege_engineering","counterweight_engines","powder_artillery","field_fortifications"],"needs":{},"needs_any":[{"artillery":0.03},{"engineer":0.03}],"roles":{"attacker":1.0},"kinds":["assault"],"weight":2.0,"trait":"",
		"phases":[{"from":1,"to":2,"own":0.95,"enemy":1.1},{"from":3,"to":99,"own":1.05,"enemy":1.3}],"shape":"breach","era":"classical"},
	"pike_and_shot":{"names":{"hearth":"pikes and guns together","lettered":"pike and shot squares","reckoned":"pike and shot"},
		"requires_all":["pike_drill","matchlock_drill"],"requires_any":[],"needs":{"pikes":0.15,"firearm":0.2},"roles":{"attacker":0.7,"defender":1.0},"kinds":["field"],"weight":1.3,"trait":"","rigid":true,
		"special":"pike_and_shot","phases":[{"from":1,"to":99,"own":0.88,"enemy":1.12}],"shape":"pike_square","era":"gunpowder"},
	"line_volley":{"names":{"hearth":"a line that fired together","lettered":"a firing line, volley by volley","reckoned":"a firing line, volley by volley"},
		"requires_all":["formation_drill"],"requires_any":["matchlock_drill","metallic_cartridges","rifled_barrels"],"needs":{"firearm":0.4},"roles":{"defender":1.0,"attacker":0.5},"kinds":["field","assault"],"weight":1.4,"trait":"","rigid":true,
		"phases":[{"from":1,"to":99,"own":0.92,"enemy":1.18}],"shape":"firing_line","era":"gunpowder"},
	"column_assault":{"names":{"hearth":"a packed rush","lettered":"attack in columns","reckoned":"attack in columns with the bayonet"},
		"requires_all":["professional_corps"],"requires_any":["matchlock_drill","metallic_cartridges"],"needs":{"firearm":0.3,"min_troops":2000},"roles":{"attacker":1.0},"kinds":["field","assault"],"weight":0.8,"trait":"bold",
		"phases":[{"from":1,"to":99,"own":1.12,"enemy":1.2,"intensity":1.1}],"shape":"column","era":"gunpowder"},
	"converging_corps":{"names":{"hearth":"several bands closing from different sides","lettered":"separate columns marching to meet on them","reckoned":"separate corps marching to converge on them"},
		"requires_all":["military_staffs"],"requires_any":["optical_telegraphy","electrical_telegraphy","radio_telegraphy"],"needs":{"min_troops":20000},"roles":{"attacker":1.0},"kinds":["field"],"weight":0.7,"trait":"bold",
		"phases":[{"from":2,"to":99,"own":1.0,"enemy":1.28}],"shape":"converging","era":"gunpowder"},
	"entrenched_defence":{"names":{"hearth":"dug in","lettered":"held a dug-in line","reckoned":"held trench lines"},
		"requires_all":["field_fortifications"],"requires_any":["metallic_cartridges","automatic_actions"],"needs":{"firearm":0.4},"roles":{"defender":1.0},"kinds":["field"],"weight":1.6,"trait":"careful","rigid":true,
		"phases":[{"from":1,"to":99,"own":0.7,"enemy":1.25,"intensity":0.9}],"shape":"trenches","era":"industrial"},
	"defence_in_depth":{"names":{"hearth":"gave ground, then struck back","lettered":"yielded the forward line and counterattacked","reckoned":"defence in depth: the forward line yielded, the reserves counterattacked"},
		"requires_all":["military_staffs","indirect_fire","field_fortifications"],"requires_any":[],"needs":{"min_troops":5000},"roles":{"defender":1.0},"kinds":["field"],"weight":0.9,"trait":"careful",
		"phases":[{"from":1,"to":2,"own":1.05,"enemy":1.0},{"from":3,"to":99,"own":0.85,"enemy":1.35}],"shape":"depth","era":"industrial"},
	"infiltration":{"names":{"hearth":"slipped through in small groups","lettered":"small groups slipped past their strongpoints","reckoned":"small assault groups infiltrated past the strongpoints"},
		"requires_all":["automatic_actions","indirect_fire"],"requires_any":[],"needs":{},"needs_any":[{"assault":0.08},{"firearm":0.4,"artillery":0.05}],"roles":{"attacker":1.0},"kinds":["field","assault"],"weight":0.9,"trait":"cunning",
		"special":"infiltration","phases":[{"from":1,"to":99,"own":0.95,"enemy":1.25}],"shape":"infiltration","era":"industrial"},
	"armoured_breakthrough":{"names":{"hearth":"broke through and closed around them","lettered":"broke through and closed a pocket","reckoned":"an armoured breakthrough closing a pocket"},
		"requires_all":["armored_vehicles","internal_combustion","radio_telegraphy"],"requires_any":[],"needs":{"armour":0.12},"roles":{"attacker":1.0},"kinds":["field"],"weight":1.0,"trait":"bold",
		"special":"armoured_breakthrough","shape":"pocket","era":"modern"},
	"combined_arms":{"names":{"hearth":"every kind of fighter together","lettered":"every arm working as one","reckoned":"infantry, guns and armour working as one"},
		"requires_all":["armored_vehicles","indirect_fire","radio_telegraphy"],"requires_any":[],"needs":{"armour":0.05,"artillery":0.05},"roles":{"attacker":1.0,"defender":1.0},"kinds":["field","assault"],"weight":1.3,"trait":"",
		"phases":[{"from":1,"to":99,"own":0.88,"enemy":1.2}],"shape":"combined","era":"modern"},
}

## Real counters: the tactics that undo each tactic when the enemy uses them.
## A formed line is undone by a blow on its side or rear; a missile screen by
## a fast charge or raised shields; a feigned retreat by a line that will not
## break ranks to chase; a dawn attack by a camp that keeps watch; a column
## by a steady firing line; trenches by infiltration and every arm together;
## a breakthrough by a defence in depth. Plain data, so the general's choice,
## the resolver and the battle view read the same table.
const COUNTERS:Dictionary={
	"shield_wall":["flank_attack","hammer_and_anvil","double_envelopment"],
	"dense_line":["flank_attack","hammer_and_anvil","double_envelopment","oblique_order"],
	"missile_harassment":["flank_attack","hammer_and_anvil","shield_wall","column_assault"],
	"dawn_raid":["fortified_camp","entrenched_defence","reserve"],
	"night_attack":["fortified_camp","reserve"],
	"ambush":["missile_harassment","reserve"],
	"feigned_retreat":["shield_wall","dense_line","pike_and_shot","reserve"],
	"flank_attack":["reserve","pike_and_shot","defence_in_depth","fortified_camp"],
	"hammer_and_anvil":["reserve","pike_and_shot","defence_in_depth"],
	"double_envelopment":["reserve","defence_in_depth","fortified_camp"],
	"oblique_order":["reserve"],
	"fortified_camp":["breach_and_storm"],
	"escalade":["missile_harassment","line_volley"],
	"breach_and_storm":["defence_in_depth","entrenched_defence"],
	"pike_and_shot":["line_volley"],
	"line_volley":["infiltration","combined_arms"],
	"column_assault":["line_volley","entrenched_defence"],
	"converging_corps":["reserve","defence_in_depth"],
	"entrenched_defence":["infiltration","combined_arms"],
	"defence_in_depth":["combined_arms"],
	"infiltration":["defence_in_depth"],
	"armoured_breakthrough":["defence_in_depth"],
}
## A countered tactic keeps this share of the harm it would have done, and its
## own side stands a little more exposed for trying it.
const COUNTERED_KEEP:=0.3
const COUNTERED_EXPOSURE:=1.06
## Surprise tactics belong to the opening of a fight; a general cannot switch
## to them once both sides are locked together.
const OPENING_ONLY:=["dawn_raid","ambush","night_attack","night_attack_seen"]
## What a hard-pressed, careful general falls back on, in order of preference.
const FALLBACKS:=["entrenched_defence","fortified_camp","defence_in_depth","shield_wall","reserve","dense_line"]


## Whether `id` is countered by the enemy using `enemy_id`.
static func countered(id:String,enemy_id:String)->bool:
	return (COUNTERS.get(id,[]) as Array).has(enemy_id)


## Tactics among `options` that counter `enemy_id`.
static func answers_to(enemy_id:String,options:Array)->Array:
	var out:Array=[]
	for option in options:
		if countered(enemy_id,String(option)): out.append(String(option))
	return out


## A general's second look, once a phase of the fight is over. He keeps what
## works. He drops a tactic the enemy has countered (a skilled general sees it
## sooner), answers the enemy's tactic with its counter when his people can
## carry it out, and a hard-pressed careful general digs in or holds a reserve.
## Only tactics recorded as open to this side at the start (plan() "options")
## can be chosen, so knowledge and troops still gate everything.
## context: {progress (attacker winning > 0, -1..1), exchange (exchanges fought)}.
## Returns {plan, changes:{role:{from,to,why}}}; the plan is a new copy.
static func rechoose(plan:Dictionary,context:Dictionary,seed:int)->Dictionary:
	var out:=plan.duplicate(true)
	var changes:={}
	if out.is_empty(): return {"plan":out,"changes":changes}
	var exchange:=int(context.get("exchange",0))
	var progress:=float(context.get("progress",0.0))
	for role in ["attacker","defender"]:
		if not out.get(role) is Dictionary: continue
		var entry:Dictionary=out[role]
		var options:Array=entry.get("options",[])
		if options.size()<=1: continue
		var other:="defender" if role=="attacker" else "attacker"
		var enemy_id:=String((out.get(other,{}) as Dictionary).get("id",BASELINE))
		var own_id:=String(entry.get("id",BASELINE))
		var skill:=clampf(float((entry.get("profile",{}) as Dictionary).get("tactics",0.5)),0.0,1.0)
		var standing:=progress if role=="attacker" else -progress
		var rng:=RandomNumberGenerator.new(); rng.seed=seed+(0 if role=="attacker" else 7919)
		var open:Array=[]
		for option in options:
			if String(option) in OPENING_ONLY or countered(String(option),enemy_id): continue
			open.append(String(option))
		var pick:=""
		var why:=""
		var answers:=answers_to(enemy_id,open)
		if countered(own_id,enemy_id) and rng.randf()<0.35+skill*0.5:
			pick=String(answers[0]) if not answers.is_empty() else (BASELINE if open.has(BASELINE) else "")
			why="countered"
		elif not answers.is_empty() and not answers.has(own_id) and rng.randf()<0.10+skill*0.45:
			pick=String(answers[rng.randi_range(0,answers.size()-1)])
			why="answer"
		elif standing<-0.35 and rng.randf()<0.5:
			for fallback in FALLBACKS:
				if open.has(fallback): pick=fallback; break
			why="hard_pressed"
		if pick=="" or pick==own_id: continue
		entry["id"]=pick
		entry["since"]=exchange
		entry["shape"]=String((TACTICS.get(pick,{}) as Dictionary).get("shape","clash"))
		changes[role]={"from":own_id,"to":pick,"why":why}
	return {"plan":out,"changes":changes}


## Tactics that add a direction of attack (a flank or both flanks), widening
## the front both sides must hold. 0: straight ahead.
static func extra_directions(id:String)->int:
	match id:
		"double_envelopment","converging_corps": return 2
		"flank_attack","hammer_and_anvil","oblique_order","armoured_breakthrough": return 1
	return 0


## Siege works are drawn around an invested city; they are how a siege is
## conducted, not a round effect (the siege model owns pressure and fatigue).
const SIEGE_WORKS:={
	"blockade_camp":{"requires_any":[],"names":{"hearth":"camped around them","lettered":"a ring of camps around the town","reckoned":"a loose blockade"}},
	"circumvallation":{"requires_any":["field_fortifications","siege_engineering"],"names":{"hearth":"dug a ditch around them","lettered":"siege lines around the town, facing in and out","reckoned":"lines of circumvallation and contravallation"}},
}

## Follow-up that any mounted side performs when the enemy breaks; not chosen.
const PURSUIT:={"requires_any":["domesticated_mounts","war_chariots"],"mobile":0.15,"enemy_morale_below":0.38,"from_round":2,"enemy":1.3,
	"names":{"hearth":"our riders ran down the fleeing","lettered":"the horse rode down the fleeing","reckoned":"the cavalry pursued the broken enemy"}}

## Naval and air zone tactics, chosen by the fleet or air commander for a
## force's drawn zone and mission. `units`: at least one in the force.
## Factors: damage (dealt), detection, taken (damage received).
const ZONE_TACTICS:Dictionary={
	"coastal_raiding":{"domain":"navy","missions":["convoy_raiding","patrol"],"units":["war_canoe","galley"],"requires_all":[],"weight":1.4,
		"names":{"hearth":"raided along the shore, beaching to strike","lettered":"coastal raiding from beached ships","reckoned":"coastal raiding"},"factors":{"detection":1.12},"shape":"raid_track"},
	"boarding":{"domain":"navy","missions":["strike_force","patrol","convoy_raiding"],"units":["war_canoe","galley","heavy_galley","sailing_warship"],"requires_all":[],"weight":1.0,
		"names":{"hearth":"grappled their boats and boarded","lettered":"grappled and boarded","reckoned":"closed to grapple and board"},"factors":{"damage":1.1,"taken":1.05},"shape":"engagement_lines"},
	"ramming_line_abreast":{"domain":"navy","missions":["strike_force"],"units":["galley","heavy_galley"],"requires_all":[],"weight":1.2,
		"names":{"hearth":"rowed at them side by side to ram","lettered":"rowed in line abreast to ram","reckoned":"a ramming attack in line abreast"},"factors":{"damage":1.15,"taken":1.05},"shape":"line_abreast"},
	"close_blockade":{"domain":"navy","missions":["patrol","strike_force"],"units":["galley","heavy_galley","sailing_warship","sailing_frigate","ship_of_line","steam_corvette","ironclad"],"requires_all":[],"needs_port":true,"weight":2.0,
		"names":{"hearth":"kept watch at their landing place","lettered":"a close blockade of the harbour","reckoned":"a close blockade of the harbour"},"factors":{"detection":1.18,"taken":1.05},"shape":"cordon"},
	"distant_blockade":{"domain":"navy","missions":["patrol","strike_force"],"units":["destroyer","light_cruiser","heavy_cruiser","battleship","submarine","missile_destroyer"],"requires_all":["naval_torpedoes"],"needs_port":true,"weight":2.2,
		"names":{"hearth":"watched the sea roads from afar","lettered":"a distant blockade of the approaches","reckoned":"a distant blockade, watching the approaches"},"factors":{"detection":1.08,"taken":0.9},"shape":"cordon_wide"},
	"line_of_battle":{"domain":"navy","missions":["strike_force","patrol"],"units":["ship_of_line","sailing_warship","ironclad"],"requires_all":["naval_gunnery"],"weight":1.4,
		"names":{"hearth":"sailed one behind another","lettered":"sailed in line of battle","reckoned":"a line of battle"},"factors":{"damage":1.12,"taken":0.95},"shape":"battle_line"},
	"crossing_the_line":{"domain":"navy","missions":["strike_force"],"units":["battleship","heavy_cruiser"],"requires_all":["naval_fire_control"],"weight":1.2,
		"names":{"hearth":"crossed ahead of their ships","lettered":"crossed ahead of their line","reckoned":"crossed the enemy's line to bring every gun to bear"},"factors":{"damage":1.2},"shape":"crossing"},
	"commerce_raiding":{"domain":"navy","missions":["convoy_raiding"],"units":["sailing_frigate","steam_corvette","light_cruiser","heavy_cruiser","torpedo_boat"],"requires_all":[],"weight":1.4,
		"names":{"hearth":"took their trading boats","lettered":"hunted their merchant ships","reckoned":"commerce raiding against their shipping"},"factors":{"detection":1.1},"shape":"raid_track"},
	"wolf_packs":{"domain":"navy","missions":["convoy_raiding","patrol"],"units":["submarine","nuclear_submarine"],"requires_all":["radio_telegraphy"],"weight":1.5,
		"names":{"hearth":"hunted together","lettered":"submarines hunting together","reckoned":"submarines hunting in packs, gathered by wireless"},"factors":{"damage":1.2,"detection":1.08},"shape":"pack"},
	"escorted_convoys":{"domain":"navy","missions":["convoy_escort"],"units":["sailing_frigate","steam_corvette","destroyer","missile_destroyer","fleet_support"],"requires_all":[],"weight":1.8,
		"names":{"hearth":"guarded the boats as they went","lettered":"escorted the merchant ships in company","reckoned":"escorted convoys"},"factors":{"detection":1.15,"taken":0.92},"shape":"convoy"},
	"fleet_in_being":{"domain":"navy","missions":["hold"],"units":["ship_of_line","battleship","heavy_cruiser","aircraft_carrier","ironclad"],"requires_all":["naval_gunnery"],"weight":1.0,
		"names":{"hearth":"kept the fleet at home as a threat","lettered":"kept the fleet in harbour as a standing threat","reckoned":"a fleet in being"},"factors":{},"shape":"harbour"},
	"carrier_strike":{"domain":"navy","missions":["strike_force"],"units":["aircraft_carrier"],"requires_all":["carrier_aviation"],"weight":1.6,
		"names":{"hearth":"struck from far off","lettered":"struck from beyond sight with carrier aircraft","reckoned":"a carrier strike from beyond the horizon"},"factors":{"damage":1.2,"taken":0.9},"shape":"sortie_arc"},
	"balloon_observation":{"domain":"air","missions":["reconnaissance"],"units":["observation_balloon"],"requires_all":[],"weight":1.5,
		"names":{"hearth":"watched from the air","lettered":"watched from tethered balloons","reckoned":"observation from tethered balloons"},"factors":{"detection":1.05},"shape":"watch"},
	"air_reconnaissance":{"domain":"air","missions":["reconnaissance"],"units":["recon_plane","airship","recon_drone"],"requires_all":[],"weight":1.6,
		"names":{"hearth":"flew over them to look","lettered":"flew over their lines to look","reckoned":"air reconnaissance over their lines"},"factors":{"detection":1.12},"shape":"sortie_arc"},
	"fighter_sweep":{"domain":"air","missions":["air_superiority"],"units":["fighter","heavy_fighter","jet_fighter"],"requires_all":[],"weight":1.4,
		"names":{"hearth":"cleared the sky","lettered":"swept the sky with fighters","reckoned":"fighter sweeps for air superiority"},"factors":{"damage":1.1},"shape":"hatch"},
	"directed_interception":{"domain":"air","missions":["interception","air_superiority"],"units":["fighter","heavy_fighter","jet_fighter"],"requires_all":["radio_telegraphy"],"requires_any":["crystal_radio_detection","tuned_radio_reception"],"weight":1.6,
		"names":{"hearth":"met the raiders where the watchers pointed","lettered":"fighters sent onto the raiders by watchers on the ground","reckoned":"ground-directed interception"},"factors":{"detection":1.22,"damage":1.05},"shape":"interception"},
	"close_support":{"domain":"air","missions":["close_air_support"],"units":["close_air_support","tactical_bomber","attack_helicopter","strike_drone","jet_bomber"],"requires_all":[],"weight":1.5,
		"names":{"hearth":"struck them from above as they fought","lettered":"aircraft striking over the fighting line","reckoned":"close air support over the front"},"factors":{"damage":1.05},"shape":"support"},
	"interdiction":{"domain":"air","missions":["logistics_strike"],"units":["tactical_bomber","close_air_support","jet_bomber","strike_drone"],"requires_all":[],"weight":1.5,
		"names":{"hearth":"struck their carriers on the road","lettered":"struck their roads and supply columns","reckoned":"interdiction of roads and supply behind the front"},"factors":{"damage":1.08},"shape":"interdiction"},
	"escorted_day_bombing":{"domain":"air","missions":["strategic_bombing"],"units":["strategic_bomber","jet_bomber","tactical_bomber"],"requires_all":[],"needs_escort":true,"weight":1.6,
		"names":{"hearth":"struck their towns by day, guarded","lettered":"bombed by day under fighter escort","reckoned":"escorted daylight bombing of industry"},"factors":{"damage":1.1,"taken":0.88},"shape":"bombing_route"},
	"night_area_bombing":{"domain":"air","missions":["strategic_bombing"],"units":["strategic_bomber","jet_bomber","tactical_bomber"],"requires_all":[],"weight":1.0,
		"names":{"hearth":"struck their towns in the dark","lettered":"bombed their towns by night","reckoned":"night area bombing"},"factors":{"damage":0.9,"taken":0.82},"shape":"bombing_route"},
	"airlift":{"domain":"air","missions":["air_supply"],"units":["transport_aircraft","transport_helicopter","airship"],"requires_all":[],"weight":1.5,
		"names":{"hearth":"carried food through the air","lettered":"flew supplies in","reckoned":"an airlift"},"factors":{},"shape":"airlift"},
}


# --- Knowledge -------------------------------------------------------------------

## The player's own discoveries.
static func known_for_player()->Array:
	if Engine.get_main_loop()==null: return []
	return (GameState.known_discoveries as Array).duplicate()


## What a rival demonstrably knows: the gates of the troops it fields, plus
## what its general level of knowledge (0..1) makes certain. Never the
## player's discoveries.
static func known_from_force(force:Dictionary,technology:float=-1.0)->Array:
	var known:Array=[]
	for formation_variant in force.get("formations",[]):
		if not formation_variant is Dictionary: continue
		var formation:Dictionary=formation_variant
		if int(formation.get("count",0))<=0: continue
		var unit:=String(formation.get("unit",""))
		var gate:=UnitCatalog.gate_for(unit)
		if gate!="" and gate not in known: known.append(gate)
		if unit in ["pikeman","musketeer","rifle_infantry","grenadier"] and "formation_drill" not in known: known.append("formation_drill")
	if technology>=0.27:
		for id in ["hafted_weapons","shield_wall","bow_craft"]:
			if id not in known: known.append(id)
	if technology>=0.45:
		for id in ["formation_drill","field_fortifications"]:
			if id not in known: known.append(id)
	return known


static func _weighted_count(formation:Dictionary)->float:
	# An unequipped formation still counts, but only for part of its weight.
	var count:=maxf(0.0,float(formation.get("count",0)))
	if not formation.has("equipment"): return count
	var required:=maxf(1.0,float(formation.get("equipment_required",formation.get("authorized_count",count))))
	return count*(0.35+0.65*clampf(float(formation.get("equipment",0))/required,0.0,1.0))


## Aggregate composition shares and the facts a tactic needs.
static func profile(force:Dictionary,commander:Dictionary={})->Dictionary:
	var totals:={"missile":0.0,"mobile":0.0,"shock":0.0,"pikes":0.0,"firearm":0.0,"artillery":0.0,"engineer":0.0,"armour":0.0,"assault":0.0}
	var weight_total:=0.0
	var headcount:=0.0
	var training:=0.0
	for formation_variant in force.get("formations",[]):
		if not formation_variant is Dictionary: continue
		var formation:Dictionary=formation_variant
		var count:=maxf(0.0,float(formation.get("count",0)))
		if count<=0.0: continue
		var weight:=_weighted_count(formation)
		var unit:=String(formation.get("unit",""))
		headcount+=count; weight_total+=weight
		training+=count*clampf(float(formation.get("training",0.3)),0.0,1.0)
		if unit in MISSILE or String(formation.get("weapon","")) in ["bow","sling","javelin","crossbow"]: totals.missile+=weight
		if unit in MOBILE: totals.mobile+=weight
		if unit in SHOCK: totals.shock+=weight
		if unit in PIKES or String(formation.get("weapon",""))=="pike": totals.pikes+=weight
		if unit in FIREARM: totals.firearm+=weight
		if unit in ARTILLERY: totals.artillery+=weight
		if unit in ENGINEER: totals.engineer+=weight
		if unit in ARMOUR: totals.armour+=weight
		if unit in ASSAULT: totals.assault+=weight
	var result:Dictionary={}
	for key in totals: result[key]=float(totals[key])/weight_total if weight_total>0.0 else 0.0
	var troops:=int(force.get("troops",0))
	result["troops"]=troops if troops>0 else int(headcount)
	result["training"]=training/headcount if headcount>0.0 else clampf(float(force.get("readiness",0.4)),0.0,1.0)*0.6
	var chief:Dictionary=commander if not commander.is_empty() else (force.get("commander",{}) as Dictionary)
	result["command"]=clampf(float(chief.get("command",0.5)),0.0,1.0)
	result["tactics"]=clampf(float(chief.get("tactics",0.5)),0.0,1.0)
	result["resolve"]=clampf(float(chief.get("resolve",0.5)),0.0,1.0)
	return result


# --- Availability and choice -----------------------------------------------------

static func _has_all(known:Array,ids:Array)->bool:
	for id in ids:
		if not known.has(id): return false
	return true


static func _has_any(known:Array,ids:Array)->bool:
	if ids.is_empty(): return true
	for id in ids:
		if known.has(id): return true
	return false


static func _meets(needs:Dictionary,own:Dictionary,battle:Dictionary)->bool:
	for key in needs:
		var value:=float(needs[key])
		match String(key):
			"min_troops": if int(own.get("troops",0))<int(value): return false
			"max_troops": if int(own.get("troops",0))>int(value): return false
			"min_training": if float(own.get("training",0.0))<value: return false
			"min_command": if float(own.get("command",0.5))<value: return false
			"min_ratio": if float(battle.get("ratio",1.0))<value: return false
			"max_ratio": if float(battle.get("ratio",1.0))>value: return false
			"min_terrain": if float(battle.get("terrain",1.0))<value: return false
			_: if float(own.get(String(key),0.0))<value: return false
	return true


## Whether a tactic can be used. side: {known, profile, role};
## battle: {kind, terrain, ratio}.
static func available(id:String,side:Dictionary,battle:Dictionary)->bool:
	var spec:Dictionary=TACTICS.get(id,{})
	if spec.is_empty(): return false
	var known:Array=side.get("known",[])
	var own:Dictionary=side.get("profile",{})
	if not _has_all(known,spec.get("requires_all",[])) or not _has_any(known,spec.get("requires_any",[])): return false
	if not (spec.get("roles",{}) as Dictionary).has(String(side.get("role","attacker"))): return false
	if String(battle.get("kind","field")) not in (spec.get("kinds",["field"]) as Array): return false
	if not _meets(spec.get("needs",{}),own,battle): return false
	var alternatives:Array=spec.get("needs_any",[])
	if alternatives.is_empty(): return true
	for alternative in alternatives:
		if _meets(alternative,own,battle): return true
	return false


static func available_ids(side:Dictionary,battle:Dictionary)->Array:
	var ids:Array=[]
	for id in TACTICS:
		# Ordered tactics (the night attack) are the ruler's, never a choice.
		if bool((TACTICS[id] as Dictionary).get("ordered",false)): continue
		if available(String(id),side,battle): ids.append(String(id))
	return ids


# --- The night approach ---------------------------------------------------------------

## The chance of reaching the enemy unseen by night is kept inside these.
const SURPRISE_MIN:=0.05
const SURPRISE_MAX:=0.85
## Their numbers when nobody has counted them.
const UNCOUNTED_WATCH:=60.0


## The chance a band ordered to strike by night reaches its enemy unseen.
## Fewer men, a shorter march, fewer and less wary watchers, cover near them
## and a cunning leader help. context: {troops, march_days, watchers (their
## numbers; below 0 when nobody has counted them), alert (0..1: at war with
## us), cover (0.8 open ground .. 1.2 woods and broken ground), tactics (the
## leader's skill 0..1)}. Returns the chance and each stated input.
static func surprise_odds(context:Dictionary)->Dictionary:
	var troops:=maxf(1.0,float(context.get("troops",10)))
	var days:=clampf(float(context.get("march_days",1)),0.0,90.0)
	var counted:=float(context.get("watchers",-1.0))
	var watchers:=counted if counted>=0.0 else UNCOUNTED_WATCH
	var alert:=clampf(float(context.get("alert",0.0)),0.0,1.0)
	var cover:=clampf(float(context.get("cover",1.0)),0.8,1.2)
	var skill:=clampf(float(context.get("tactics",0.5)),0.0,1.0)
	var size:=clampf(1.12-0.12*log(troops)/log(10.0),0.55,1.0)
	var road:=pow(0.93,days)
	var watch:=1.0/(1.0+watchers/150.0)
	var wary:=1.0-0.35*alert
	var chance:=clampf(0.72*size*road*watch*wary*cover*(0.8+0.4*skill),SURPRISE_MIN,SURPRISE_MAX)
	return {"chance":chance,"troops":int(troops),"march_days":int(days),"watchers":roundi(watchers),"counted":counted>=0.0,"alert":alert,"cover":cover,"tactics":skill}


## A chance in plain words: "about 1 in 3", "about even", "about 3 in 4".
static func chance_words(p:float)->String:
	if p>=0.8: return "about 4 in 5"
	if p>=0.7: return "about 3 in 4"
	if p>=0.6: return "about 2 in 3"
	if p>=0.45: return "about even"
	return "about 1 in %d" % maxi(2,roundi(1.0/maxf(0.01,p)))


## Cover near a place for a night approach, from its ground.
static func cover_of(ground_kind:String)->float:
	return float({"forest":1.2,"rough":1.1,"pass":1.1,"marsh":1.0,"ford":1.0,"bridge":0.95,"open":0.9}.get(ground_kind,1.0))


## A band ordered to fall on the enemy by night: one seeded roll at the stated
## chance decides whether it reaches them unseen. Unseen, it strikes a camp
## still asleep that has no time for anything clever; seen, it stumbles into
## a ready defence in the dark. The roll and the chance stay on the plan.
static func night_approach(plan:Dictionary,side:String,chance:float,seed:int)->Dictionary:
	var out:=plan.duplicate(true)
	var rng:=RandomNumberGenerator.new(); rng.seed=seed^0x51ee7
	var unseen:=rng.randf()<clampf(chance,0.0,1.0)
	var id:="night_attack" if unseen else "night_attack_seen"
	var entry:Dictionary=(out.get(side,{}) as Dictionary).duplicate(true)
	entry["id"]=id; entry["shape"]=String((TACTICS[id] as Dictionary).get("shape","strike")); entry["since"]=0
	entry["surprise"]={"chance":chance,"unseen":unseen}
	out[side]=entry
	var other:="defender" if side=="attacker" else "attacker"
	if unseen and out.get(other) is Dictionary:
		var them:Dictionary=(out[other] as Dictionary).duplicate(true)
		them["id"]=BASELINE; them["shape"]="clash"; them["since"]=0
		out[other]=them
	return out


## The general's choice. Deterministic for a seed. Clever manoeuvres need
## skill, and even a skilled general fights plainly much of the time.
static func choose(side:Dictionary,enemy:Dictionary,battle:Dictionary,seed:int)->String:
	var ids:=available_ids(side,battle)
	if ids.is_empty(): return BASELINE
	var own:Dictionary=side.get("profile",{})
	var character:Dictionary=side.get("character",{})
	var skill:=float(own.get("tactics",0.5))
	var boldness:=clampf(float(character.get("ambition",0.5))*0.5+float(character.get("confidence",0.5))*0.5,0.0,1.0)
	var caution:=clampf(float(character.get("care",0.5))*0.6+float(character.get("fear",0.3))*0.4,0.0,1.0)
	var enemy_rigid:=bool(enemy.get("rigid",false))
	var weights:Array=[]
	var total:=0.0
	for id in ids:
		var spec:Dictionary=TACTICS[id]
		var weight:=float(spec.get("weight",1.0))*float((spec.get("roles",{}) as Dictionary).get(String(side.get("role","attacker")),0.0))
		if id!=BASELINE:
			# Unskilled generals rarely attempt anything but the plain fight.
			weight*=0.25+skill*1.1
			match String(spec.get("trait","")):
				"bold": weight*=0.6+boldness*0.9
				"careful": weight*=0.6+caution*0.9
				"cunning": weight*=0.7+skill*0.6
			if bool(spec.get("flank",false)) and enemy_rigid: weight*=1.3
		weights.append(weight); total+=weight
	if total<=0.0: return BASELINE
	var rng:=RandomNumberGenerator.new(); rng.seed=seed
	var roll:=rng.randf()*total
	for index in ids.size():
		roll-=float(weights[index])
		if roll<=0.0: return String(ids[index])
	return String(ids[-1])


static func _context(role:String,battle:Dictionary,own_troops:float,other_troops:float)->Dictionary:
	var kind:=String(battle.get("kind","field"))
	if kind=="assault" and role=="defender": kind="field"
	return {"kind":kind,"terrain":float(battle.get("terrain",1.0)) if role=="defender" else 1.0,"ratio":maxf(1.0,own_troops)/maxf(1.0,other_troops)}


## Both sides' tactics for one engagement: the record kept on it (saveable
## plain data). sides: {attacker:{force, known, character, commander},
## defender:{...}}; battle: {kind: field|raid|assault, terrain}.
static func plan(sides:Dictionary,battle:Dictionary,seed:int)->Dictionary:
	var result:={}
	var profiles:={}
	for role in ["attacker","defender"]:
		var side:Dictionary=sides.get(role,{})
		profiles[role]=profile(side.get("force",{}),side.get("commander",{}))
	for pass_index in 2:
		for role in ["attacker","defender"]:
			var other:="defender" if role=="attacker" else "attacker"
			var side:Dictionary=sides.get(role,{})
			var own_profile:Dictionary=profiles[role]
			var other_profile:Dictionary=profiles[other]
			var context:=_context(role,battle,float(own_profile.troops),float(other_profile.troops))
			var enemy_view:={}
			# Second look: a flank attack is drawn to a rigid line it can see.
			if pass_index==1:
				if not result.has(other): continue
				enemy_view["rigid"]=bool((TACTICS.get(String(result[other].id),{}) as Dictionary).get("rigid",false))
				if not bool(enemy_view.rigid): continue
			var choice_side:={"known":side.get("known",[]),"profile":own_profile,"role":role,"character":side.get("character",{})}
			var id:=choose(choice_side,enemy_view,context,seed+(0 if role=="attacker" else 7919))
			# options: what this side could do in this battle at all, kept so the
			# general can change course between phases (rechoose) without the
			# resolver ever looking up knowledge again.
			result[role]={"id":id,"profile":own_profile,"pursuit":_can_pursue(side.get("known",[]),own_profile),"shape":String((TACTICS.get(id,{}) as Dictionary).get("shape","clash")),
				"options":available_ids(choice_side,context),"since":0}
	return result


static func _can_pursue(known:Array,own:Dictionary)->bool:
	return _has_any(known,PURSUIT.requires_any) and float(own.get("mobile",0.0))>=float(PURSUIT.mobile)


# --- Resolution --------------------------------------------------------------------

static func _phase(spec:Dictionary,round_number:int)->Dictionary:
	for phase_variant in spec.get("phases",[]):
		var phase:Dictionary=phase_variant
		if round_number>=int(phase.get("from",1)) and round_number<=int(phase.get("to",99)): return phase
	return {}


## One side's own/enemy multipliers for a round. share: this side's share of
## combat power this round; enemy_morale: the other side's morale.
static func side_effect(entry:Dictionary,enemy_entry:Dictionary,battle_round:int,share:float,enemy_morale:float)->Dictionary:
	var id:=String(entry.get("id",BASELINE))
	var spec:Dictionary=TACTICS.get(id,TACTICS[BASELINE])
	var own:Dictionary=entry.get("profile",{})
	var enemy_profile:Dictionary=enemy_entry.get("profile",{})
	var enemy_spec:Dictionary=TACTICS.get(String(enemy_entry.get("id",BASELINE)),{})
	var result:={"own":1.0,"enemy":1.0,"intensity":1.0,"event":"","phase":"hold"}
	# A tactic adopted mid-battle (rechoose) runs its own timetable from then.
	var round_number:=maxi(1,battle_round-int(entry.get("since",0)))
	var phase:=_phase(spec,round_number)
	if not phase.is_empty():
		result.own=float(phase.get("own",1.0)); result.enemy=float(phase.get("enemy",1.0)); result.intensity=float(phase.get("intensity",1.0))
	match String(spec.get("special","")):
		"night_unseen":
			if round_number==1: result.event="We fell on them while they slept."; result.phase="turn"
		"night_seen":
			if round_number==1: result.event="Their watch saw us coming in the dark."; result.phase="failed"
		"feigned_retreat":
			if round_number==1:
				result.own=1.15; result.enemy=0.95; result.phase="yield"
			elif round_number<=3:
				if float(enemy_profile.get("training",0.5))<float(own.get("training",0.5))-0.05:
					result.own=0.85; result.enemy=1.55; result.phase="turn"
					result.event="They broke ranks to chase us, and we turned on them."
				else:
					result.own=1.2; result.enemy=1.0; result.phase="failed"
					result.event="They did not take the bait and held their ranks."
		"double_envelopment":
			if round_number<=2:
				result.own=1.15; result.enemy=1.0; result.phase="yield"
			elif share>=0.46:
				result.own=0.95; result.enemy=1.55+(0.15 if bool(enemy_spec.get("rigid",false)) else 0.0); result.phase="closing"
				result.event="The wings closed behind them."
			else:
				result.own=1.3; result.enemy=1.0; result.phase="failed"
				result.event="The centre gave way before the wings could close."
		"armoured_breakthrough":
			if round_number<=2:
				result.own=1.08; result.enemy=1.05; result.phase="break_in"
			elif share>=0.5:
				result.own=0.95; result.enemy=1.6; result.phase="closing"
				result.event="The armour broke through and closed a pocket behind them."
			else:
				result.own=1.15; result.enemy=1.0; result.phase="failed"
				result.event="The breakthrough stalled against their reserves."
		"pike_and_shot":
			if float(enemy_profile.get("mobile",0.0))>=0.2: result.own=0.8
		"infiltration":
			if String(enemy_entry.get("id",""))=="entrenched_defence": result.enemy=float(result.enemy)*1.15
	if bool(spec.get("flank",false)) and bool(enemy_spec.get("rigid",false)) and float(result.enemy)>1.0 and String(spec.get("special",""))!="double_envelopment":
		result.enemy=float(result.enemy)*1.15
	if bool(entry.get("pursuit",false)) and battle_round>=int(PURSUIT.from_round) and enemy_morale<float(PURSUIT.enemy_morale_below):
		result.enemy=float(result.enemy)*float(PURSUIT.enemy)
		if String(result.event)=="": result.event="Our riders ran down the fleeing."
		result["pursuit"]=true
	result.own=clampf(float(result.own),ROUND_MIN,ROUND_MAX)
	result.enemy=clampf(float(result.enemy),ROUND_MIN,ROUND_MAX)
	result.intensity=clampf(float(result.intensity),0.8,1.2)
	return result


## The combined per-round effect of both plans on the shared resolver:
## bounded attacker/defender exposure multipliers, an intensity factor, and
## the round's notable event (if any).
static func round_effects(plan:Dictionary,round_number:int,attacker_share:float,attacker_morale:float,defender_morale:float)->Dictionary:
	if plan.is_empty(): return {"attacker":1.0,"defender":1.0,"intensity":1.0,"event":"","attacker_phase":"hold","defender_phase":"hold"}
	var attacker:Dictionary=plan.get("attacker",{})
	var defender:Dictionary=plan.get("defender",{})
	var a:=side_effect(attacker,defender,round_number,attacker_share,defender_morale)
	var d:=side_effect(defender,attacker,round_number,1.0-attacker_share,attacker_morale)
	# A countered tactic does little of what it was meant to, and exposes its side.
	var a_countered:=countered(String(attacker.get("id",BASELINE)),String(defender.get("id",BASELINE)))
	var d_countered:=countered(String(defender.get("id",BASELINE)),String(attacker.get("id",BASELINE)))
	if a_countered: _blunt(a)
	if d_countered: _blunt(d)
	var event:=String(a.event) if String(a.event)!="" else String(d.event)
	return {
		"attacker":clampf(float(a.own)*float(d.enemy),COMBINED_MIN,COMBINED_MAX),
		"defender":clampf(float(d.own)*float(a.enemy),COMBINED_MIN,COMBINED_MAX),
		"intensity":clampf(float(a.intensity)*float(d.intensity),0.8,1.2),
		"event":event,"attacker_phase":String(a.phase),"defender_phase":String(d.phase),
		"event_side":"attacker" if String(a.event)!="" else ("defender" if String(d.event)!="" else ""),
		"attacker_countered":a_countered,"defender_countered":d_countered}


static func _blunt(effect:Dictionary)->void:
	if float(effect.enemy)>1.0: effect.enemy=1.0+(float(effect.enemy)-1.0)*COUNTERED_KEEP
	effect.own=clampf(maxf(float(effect.own),1.0)*COUNTERED_EXPOSURE,ROUND_MIN,ROUND_MAX)


# --- What the map draws --------------------------------------------------------------

## The battle's drawn shape for one side after `rounds` rounds. phase is the
## last recorded phase of a special tactic (hold, yield, turn, closing,
## failed). Keys: shape, bulge (−1 back … +1 forward at the contact),
## wings (0..1 curl of both ends), wing (0..1 one end), closure (0..1
## ring or pocket), depth (extra lines behind), hardening (0..1).
static func shape(id:String,rounds:int,phase:String="hold")->Dictionary:
	var spec:Dictionary=TACTICS.get(id,TACTICS[BASELINE])
	var r:=maxi(0,rounds)
	var out:={"shape":String(spec.get("shape","clash")),"bulge":0.0,"wings":0.0,"wing":0.0,"closure":0.0,"depth":0,"hardening":clampf(float(r)/6.0,0.0,1.0)}
	match id:
		"feigned_retreat":
			out.bulge=-0.8 if phase in ["yield","hold"] else (0.7 if phase=="turn" else -1.0)
		"double_envelopment":
			out.bulge=-0.5 if phase in ["yield","hold"] else (-0.2 if phase=="closing" else -0.9)
			out.wings=minf(1.0,float(r)/4.0) if phase!="failed" else 0.4
			out.closure=clampf(float(r-2)/3.0,0.0,1.0) if phase=="closing" else 0.0
		"flank_attack","ambush","dawn_raid":
			out.wing=minf(1.0,float(r)/3.0)
		"hammer_and_anvil":
			out.wing=0.0 if r<=2 else minf(1.0,float(r-2)/2.0)
		"oblique_order":
			out.wing=0.6
		"column_assault","breach_and_storm","escalade":
			out.bulge=minf(1.0,float(r)/2.0)
		"armoured_breakthrough":
			out.bulge=minf(1.0,float(r)/2.0)
			out.closure=clampf(float(r-2)/3.0,0.0,1.0) if phase=="closing" else 0.0
		"infiltration":
			out.bulge=0.4
		"reserve","defence_in_depth","fortified_camp","entrenched_defence":
			out.depth=2 if id=="defence_in_depth" else 1
		"converging_corps":
			out.wings=minf(1.0,float(r)/3.0)
	return out


# --- Words -----------------------------------------------------------------------------

static func name_of(id:String,stage:String="reckoned")->String:
	var spec:Dictionary=TACTICS.get(id,ZONE_TACTICS.get(id,SIEGE_WORKS.get(id,{})))
	var names:Dictionary=spec.get("names",{})
	return String(names.get(stage,names.get("reckoned",id.replace("_"," "))))


## One sentence for the general's report, in the era's words.
static func report_sentence(plan:Dictionary,home_side:String,stage:String)->String:
	if plan.is_empty(): return ""
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var ours:=String((plan.get(home_side,{}) as Dictionary).get("id",BASELINE))
	var theirs:=String((plan.get(enemy_side,{}) as Dictionary).get("id",BASELINE))
	var text:=""
	if stage=="hearth": text="We %s." % name_of(ours,stage)
	else: text="We fought %s." % _with_article(name_of(ours,stage)) if ours==BASELINE else "Our general chose %s." % _with_article(name_of(ours,stage))
	if theirs!=BASELINE:
		text+=" "+("They %s." % name_of(theirs,stage) if stage=="hearth" else "The enemy answered with %s." % _with_article(name_of(theirs,stage)))
	return text


## "a shield wall" stays; "met them head-on" is a verb phrase and stays.
static func _with_article(phrase:String)->String:
	for lead in ["a ","an ","the ","met ","fought ","fell ","lay ","wore ","locked ","came ","kept ","held ","let ","struck ","climbed ","broke ","ran ","slipped ","dug ","gave ","yielded ","separate ","several ","small ","every ","pikes ","infantry","pike and","attack in","hammer","defence","lines"]:
		if phrase.begins_with(lead): return phrase
	return "a %s" % phrase


# --- Zones (navy and air) -------------------------------------------------------------

static func _unit_count(record:Dictionary,ids:Array)->int:
	var units:Dictionary=record.get("units",{})
	var total:=0
	for id in ids: total+=maxi(0,int(units.get(id,0)))
	return total


## Zone tactics the force's commander could use for its mission. context:
## {port: a known hostile port lies in the zone, escort: friendly fighters
## fly in the same zone}.
static func zone_available(record:Dictionary,known:Array,context:Dictionary={})->Array:
	var ids:Array=[]
	var mission:=String(record.get("mission","hold"))
	for id in ZONE_TACTICS:
		var spec:Dictionary=ZONE_TACTICS[id]
		if String(spec.domain)!=String(record.get("domain","")): continue
		if mission not in (spec.missions as Array): continue
		if _unit_count(record,spec.units)<=0: continue
		if not _has_all(known,spec.get("requires_all",[])) or not _has_any(known,spec.get("requires_any",[])): continue
		if bool(spec.get("needs_port",false)) and not bool(context.get("port",false)): continue
		if bool(spec.get("needs_escort",false)) and not bool(context.get("escort",false)): continue
		ids.append(String(id))
	return ids


## The commander's choice for the zone. He keeps a tactic that still fits
## rather than switching daily; otherwise the most demanding one his force
## can carry out.
static func zone_choose(record:Dictionary,known:Array,context:Dictionary={})->String:
	var ids:=zone_available(record,known,context)
	if ids.is_empty(): return ""
	var current:=String(record.get("tactic",""))
	if current in ids: return current
	var best:=""
	var best_weight:=-1.0
	for id in ids:
		var spec:Dictionary=ZONE_TACTICS[id]
		var weight:=float(spec.get("weight",1.0))+float((spec.get("requires_all",[]) as Array).size())*0.2
		if weight>best_weight: best_weight=weight; best=String(id)
	return best


static func zone_factor(id:String,key:String)->float:
	var spec:Dictionary=ZONE_TACTICS.get(id,{})
	return clampf(float((spec.get("factors",{}) as Dictionary).get(key,1.0)),ZONE_MIN,ZONE_MAX)


## A force's zone knowledge: its hulls' and airframes' gates plus, for the
## player, the player's discoveries. `catalog` is joint_force_catalog UNITS.
static func zone_known(record:Dictionary,catalog:Dictionary,player_known:Array=[])->Array:
	var known:Array=player_known.duplicate()
	var units:Dictionary=record.get("units",{})
	for id in units:
		if int(units[id])<=0 or not catalog.has(id): continue
		var gate:=String((catalog[id] as Dictionary).get("gate",""))
		if gate!="" and gate not in known: known.append(gate)
	return known
