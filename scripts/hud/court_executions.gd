extends RefCounted
## The court's executions (L): which way a person the engine has put to death
## is put to death on the stage, from the god's own words or the director's
## choice among the ways the people know. Presentation only: the engine has
## already killed them (court_commands / court_persons / envoy_kill / the
## god's wrath); nothing here changes the ledger, and the method has no
## mechanical effect.
##   Executions.parse(text, facts)  -> method id the words name (if the people can)
##   Executions.available(facts)    -> the method ids this people can stage now
##   Executions.choose(facts, seed, last) -> the director's pick, never `last`
##   Executions.caption(method, name) -> "Heha Bikatmat is beheaded before the whole court."
##   Executions.style(victim)       -> "full", "mild" or "off" (children: always "off")
## facts: {known: [discovery ids], tags: [era tags], set: "fire_ring"...,
##   dogs: bool, great_work: bool}; facts_from_game() fills it.

const Self:=preload("res://scripts/hud/court_executions.gd")

## The player's setting (display_preferences.gd): "full" (the default),
## "mild" (no blood or body parts: a cutaway with sounds and the room) or
## "off" (the old sober kneel and sink).
static var gore:="full"
const GORE_LEVELS:=["full","mild","off"]
## The method played last (never twice running).
static var last_used:=""

## The 25 acts. n: the design's number; words: what the god may say for it
## (a regular expression, matched before the more general ones); needs_any:
## discovery ids or era tags, one of which the people must know (empty: any
## age); needs_all: each must be known; sets: the halls it can play in
## (empty: any); done: how the caption says it; seconds: about how long.
const METHODS:=[
	{"id":"cannon","n":25,"name":"Cannon mouth","words":"cannon|blow (him|her|them) (from|out of)|from the gun","needs_any":["solid_bored_cannon","powder_artillery","guns"],"done":"blown from the mouth of the cannon","seconds":9.0},
	{"id":"volley","n":24,"name":"Firing squad","words":"firing squad|musket|muskets|shoot (him|her|them) with guns|guns","needs_any":["muskets","matchlock_drill","wheel_lock_firearms","rest_musket","hand_gun_tubes"],"done":"shot by a line of muskets","seconds":10.0},
	{"id":"blade","n":23,"name":"The falling blade","words":"falling blade|drop the blade|the blade|guillotine","needs_all":["gunpowder","metal"],"done":"put under the falling blade","seconds":8.0},
	{"id":"monolith","n":22,"name":"Under the great stone","words":"great stone|monolith|standing stone|under the stone","needs_any":["megalith_raising","great_work_parties","flood_season_great_works"],"done":"crushed under the great stone","seconds":9.0},
	{"id":"catapult","n":21,"name":"Catapult launch","words":"catapult|fling (him|her|them)|launch (him|her|them)|throwing engine","needs_any":["torsion_spring_engines","siege_engineering"],"done":"flung from the throwing engine","seconds":10.0},
	{"id":"bronze","n":20,"name":"Dipped in molten bronze","words":"molten|cast (him|her|them) in bronze|bronze statue|make (him|her|them) a statue|into a statue","needs_any":["freestanding_bronze_statuary","cast_bronze_doors","copper_casting"],"done":"dipped in molten bronze and set up by the door","seconds":11.0},
	{"id":"wheel","n":19,"name":"The wheel and the hill","words":"wheel|roll (him|her|them) down","needs_any":["wheel","solid_wheel_assembly"],"done":"tied to a wheel and rolled down the hill","seconds":10.0},
	{"id":"elephant","n":18,"name":"Elephant foot","words":"elephant","needs_any":["war_elephants"],"done":"trodden under the elephant's foot","seconds":8.0},
	{"id":"bear","n":17,"name":"The bear pit","words":"bear|to the beasts","needs_all":["masonry","institutions"],"done":"fed to the bear","seconds":9.0},
	{"id":"arrows","n":16,"name":"Volley of arrows","words":"arrow|arrows|archers|bowmen|shoot (him|her|them)","needs_any":["bow_craft","composite_bow","lath_stiffened_bow"],"done":"shot full of arrows","seconds":9.0},
	{"id":"stake","n":15,"name":"The stake","words":"impale|impaled|stake|spike","needs_any":["farming","pottery"],"done":"set on a stake","seconds":10.0},
	{"id":"boil","n":14,"name":"Boiled in the pot","words":"boil|boiled|cauldron|stew (him|her|them)|into the pot","needs_any":["pottery"],"done":"boiled in the great pot","seconds":11.0},
	{"id":"saw","n":13,"name":"Sawn in half","words":"saw (him|her|them)|sawn|in half","needs_any":["bronze_toothed_saws","cord_tensioned_frame_saws"],"done":"sawn in half","seconds":10.0},
	{"id":"quarter","n":12,"name":"Quartered by oxen","words":"quarter|quartered|tear (him|her|them) apart|pull (him|her|them) apart|four oxen","needs_any":["paired_ox_yoke","ox_drawn_ard","ox_drawn_sledges","shared_plough_teams"],"done":"pulled apart by four oxen","seconds":10.0},
	{"id":"hang","n":11,"name":"Neck-stretch hanging","words":"hang|hanged|hung|noose|gallows|from the beam","needs_all":["rope_laying"],"sets":["longhouse","shelter","mudbrick_hall","grand_hall"],"done":"hanged from the roof beam","seconds":10.0},
	{"id":"behead","n":10,"name":"Three-swing beheading","words":"behead|beheaded|decapitate|off with (his|her|their) head|(his|her|their) head off|take (his|her|their) head|axe","needs_any":["copper_battle_axes","bronze_weaponry","bronze_alloying","metal"],"done":"beheaded at the third stroke","seconds":11.0},
	{"id":"pigs","n":9,"name":"The pig pen","words":"pig|pigs|swine|hogs|pig pen","needs_any":["mast_fed_swine","scrap_fed_pigs"],"done":"thrown to the pigs","seconds":9.0},
	{"id":"herd","n":8,"name":"Trampled by the herd","words":"trample|trampled|stampede|run the herd|under the herd","needs_any":["dairy","animal_taming","pack_animals"],"done":"trampled by the herd","seconds":9.0},
	{"id":"buried","n":7,"name":"Buried to the neck","words":"bury|buried|to the neck|in the ground","needs_all":["farming","dairy"],"done":"buried to the neck and trodden by an ox","seconds":11.0},
	{"id":"stoning","n":6,"name":"Stoned by the whole court","words":"stone (him|her|them)|stoned|stoning|stones at|rocks at","done":"stoned by the whole court","seconds":10.0},
	{"id":"spears","n":5,"name":"Spear pincushion","words":"spear|spears|run (him|her|them) through","done":"speared by the watch","seconds":9.0},
	{"id":"dogs","n":4,"name":"Death by hounds","words":"dog|dogs|hounds|wolves","needs_set":"dogs","done":"fed to the camp dogs","seconds":10.0},
	{"id":"fire","n":3,"name":"Into the fire","words":"burn|burned|burnt|into the fire|fire|flames|pyre|roast","done":"thrown into the fire","seconds":9.0},
	{"id":"club","n":2,"name":"Club home run","words":"club|clubbed|cudgel|bludgeon|brain (him|her|them)|knock (his|her|their) head","done":"clubbed, head and all, into the cooking pot","seconds":9.0},
	{"id":"boulder","n":1,"name":"Boulder drop","words":"boulder|crush|crushed|flatten|a rock on","done":"flattened under a boulder","seconds":10.0},
]

## Current release scope: the user's selected acts 2, 3, 4 and 10.
## Keep the other catalog entries and assets for later, but do not offer,
## choose or stage them. Words naming a parked method use an active fallback.
static var staged:Array=["club","fire","dogs","behead"]

static var _by_id:Dictionary={}
static var _res:Dictionary={}

static func is_staged(id:String)->bool:
	return id in staged and not method(id).is_empty()

static func method(id:String)->Dictionary:
	if _by_id.is_empty():
		for m:Dictionary in METHODS:_by_id[String(m.id)]=m
	return _by_id.get(id,{})

static func ids()->Array:
	var out:=[]
	for m:Dictionary in METHODS:out.append(String(m.id))
	return out

## Whether the people know what the method needs.
static func knows(m:Dictionary,facts:Dictionary)->bool:
	var known:Array=facts.get("known",[]) if facts.get("known") is Array else []
	var tags:Array=facts.get("tags",[]) if facts.get("tags") is Array else []
	var has:=func(need:String)->bool:return known.has(need) or tags.has(need)
	var any:Array=m.get("needs_any",[])
	if not any.is_empty():
		var one:=false
		for need:String in any:
			if has.call(need):one=true;break
		if not one:return false
	for need:String in m.get("needs_all",[]):
		if not has.call(need):return false
	var sets:Array=m.get("sets",[])
	if not sets.is_empty() and not String(facts.get("set","")) in sets:return false
	var needs_set:=String(m.get("needs_set",""))
	if needs_set=="dogs" and not bool(facts.get("dogs",true)):return false
	return true

## The method ids this people can stage now (era and hall), in the design's order.
static func available(facts:Dictionary,staged_only:=true)->Array:
	var out:=[]
	for n in range(1,26):
		for m:Dictionary in METHODS:
			if int(m.n)!=n:continue
			if staged_only and not is_staged(String(m.id)):continue
			if knows(m,facts):out.append(String(m.id))
	return out

## The method the god's own words name ("" if none, or if the people cannot).
static func parse(text:String,facts:Dictionary={})->String:
	var said:=text.to_lower()
	if said.strip_edges().is_empty():return ""
	# "Shoot him": with guns, the muskets; before them, the bows.
	var best:="";var at:=1<<30
	for m:Dictionary in METHODS:
		var hit:=_re(String(m.id),String(m.words)).search(said)
		if hit==null:continue
		# a more particular method listed earlier wins a tie at the same place
		if hit.get_start()<at:best=String(m.id);at=hit.get_start()
	if best.is_empty():return ""
	if best=="volley" and not knows(method("volley"),facts) and knows(method("arrows"),facts):best="arrows"
	if not facts.is_empty() and not knows(method(best),facts):return ""
	return best

static func _re(id:String,words:String)->RegEx:
	if not _res.has(id):
		var re:=RegEx.new()
		re.compile("(?<![a-z])("+words+")(?![a-z])")
		_res[id]=re
	return _res[id]

## The director's pick: seeded by the person and the day, among the methods
## this people can stage, never the one used last.
static func choose(facts:Dictionary,seed_value:int,last:="")->String:
	var can:=available(facts)
	if can.size()>1:can.erase(last)
	if can.is_empty():return "club"
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	return String(can[rng.randi()%can.size()])

## The method for an execution: the god's words if they name one the people
## can stage, else the director's pick.
static func pick(words:String,facts:Dictionary,seed_value:int,last:="")->String:
	var named:=parse(words,facts)
	if is_staged(named):return named
	return choose(facts,seed_value,last)

## The narrator's words for what the picture shows.
static func caption(id:String,name:String)->String:
	var m:=method(id)
	var who:=name.strip_edges() if not name.strip_edges().is_empty() else "They"
	if m.is_empty():return "%s is put to death before the whole court." % who
	return "%s is %s before the whole court." % [who,String(m.done)]

## How an execution is shown: the player's setting, but a child is never
## shown harmed (the old sober exit) and neither is anyone under "off".
static func style(victim:Dictionary)->String:
	if is_child(victim):return "off"
	return gore if gore in GORE_LEVELS else "full"

static func is_child(person:Dictionary)->bool:
	var age:Variant=person.get("age",null)
	if age is int or age is float:return float(age)<15.0
	var kind:=String(person.get("kind",""))
	return kind=="child" or String(age if age!=null else "").to_lower()=="child"

## What the game knows now, for the gating (era tags from character_voice).
static func facts_from_game(set_kind:="")->Dictionary:
	var out:={"known":[],"tags":[],"set":set_kind,"dogs":true}
	var loop:=Engine.get_main_loop() as SceneTree
	if loop==null or loop.root==null:return out
	var state:Node=loop.root.get_node_or_null("GameState")
	if state!=null and state.get("known_discoveries") is Array:out.known=(state.get("known_discoveries") as Array).duplicate()
	var voice:=load("res://scripts/character_voice.gd")
	if voice!=null and voice.has_method("era_tags"):
		var tags:Variant=voice.call("era_tags","player")
		out.tags=Array(tags) if tags is Array else []
	return out

## The offline menu ("Put to death ▾"): [{id, label, order}] for what this
## people can stage, the order phrased as the god would say it (the engine's
## reading of "put ... to death" decides; the rest names the method).
static func menu(facts:Dictionary,name:String)->Array:
	var out:=[]
	var who:=name.strip_edges() if not name.strip_edges().is_empty() else "them"
	for id:String in available(facts):
		out.append({"id":id,"label":String(method(id).name),"order":"Put %s to death %s." % [who,String(ORDER_WORDS.get(id,"before the court"))]})
	return out

const ORDER_WORDS:={
	"boulder":"under a boulder","club":"with the club","fire":"in the fire","dogs":"by the dogs",
	"spears":"on the spears of the watch","stoning":"by stoning","buried":"buried to the neck","herd":"under the stampede",
	"pigs":"by the pigs","behead":"by the axe","hang":"by the noose","quarter":"quartered by oxen",
	"saw":"sawn in half","boil":"boiled in the cauldron","stake":"on the stake","arrows":"by the archers",
	"bear":"by the bear","elephant":"under the elephant","wheel":"on the wheel",
	"bronze":"in molten bronze","catapult":"by the catapult","monolith":"under the great stone",
	"blade":"under the falling blade","volley":"by the firing squad","cannon":"from the cannon",
}
