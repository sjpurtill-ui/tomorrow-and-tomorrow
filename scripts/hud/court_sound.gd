extends Node
## THE COURT'S SOUND: what the hall sounds like while the god holds court.
##
## Voices that babble in each people's own sounds (court_voice.gd), the room's
## breath, bodies, things and animals (court_foley.gd), a bed for each set and
## season (fire, wind, birds, the crowd's low talk), and the god's presence: a
## low swell under a hush when the god speaks, heavier for wrath, warmer for
## favour. Silence is a device here: the crowd's murmur cuts dead the moment
## the god speaks or wrath lands, so a stomach growling or a board creaking in
## that silence is heard by everyone.
##
## Presentation only: it reads the stage (who stands where, their people,
## age, sex and mood) and the fact sheet; it changes nothing.
##
## Use. The stage makes one (CourtSound.attach(stage)) and hands it its events
## and beats; or call it directly:
##   cue(name, at_body, opts)                    a one-shot (CourtFoley.CUES)
##   voice(body, text, seconds, mood, people_id) a line's babble, timed to the
##                                               mouth (court_voice.gd schedule)
##   ambience(set_id, season, facts)             the room's beds and life
##   hush(on_or_seconds)                         the crowd goes dead silent
##   god(text, seconds, tone)                    the swell under the god's words
##   on_event(kind, data)                        the stage's events (section 5)
##   on_beat(beat, body)                         the director's lowered beats
## BEAT_CUES maps the director's acts (court_director.gd ACTS) to sounds.
##
## Placement: each sound is panned by where its maker stands in the picture
## (the stage's screen x): up to about 6 dB to one side at the room's edges,
## a dB or two near the middle; nine pan buses send to "Court".
## The crowd's talk never loops: a few talkers at a time, each a short run
## from somewhere in one of six people's talk, at its own pitch and side of
## the room, with pauses, the room more and less talkative by turns.
## Time is the game's (a clock of process frames), so a movie written with
## --write-movie keeps every sound on its frame.
## A musician plays softly (court_music.gd): what the people know (a hummer,
## bone flute and frame drum, reed pipe and clay drum and rattle, a lyre),
## in their own scale and beat. When the god speaks or wrath lands the music
## stops dead mid-phrase (a squeak, a stray tap, then nothing) and creeps back
## later, one tentative phrase first; after favour it picks up brighter; a gift
## taken gets a flourish. It drops under every line said. music_changed tells
## a visible musician what to do: "play", "stop_dead", "tentative",
## "flourish", "rest".
## Mixing: everything plays on the "Court" bus (to Master), whose volume and
## mute are the player's "Court sounds" setting (display_preferences.gd).
## Nothing plays while muted or while the court is hidden. Streams are made
## once and cached; the beds, the god and the common sounds are made on a
## worker thread when the court opens; a line's voice is made on a worker
## thread and joins the mouth where it has got to. No per-frame work: one
## timer at a tenth of a second runs the room's random life while it is open.

const Synth:=preload("res://scripts/hud/court_synth.gd")
const Voice:=preload("res://scripts/hud/court_voice.gd")
const Foley:=preload("res://scripts/hud/court_foley.gd")
const Self:=preload("res://scripts/hud/court_sound.gd")
const Music:=preload("res://scripts/hud/court_music.gd")

## The musician's state, for a visible musician (the stage's acting): "play"
## (a phrase begins), "stop_dead" (cut off by the god), "tentative" (trying
## again, quietly), "flourish" (a gift), "rest" (between phrases).
signal music_changed(state:String)

const BUS:="Court"
## The player's court volume, 0..1 (display_preferences.gd sets it).
static var volume:=1.0
## Made once per session and shared by every court: "name|variant" -> stream.
static var _cache:Dictionary={}
static var _lock:=Mutex.new()
## Render voices on the calling thread (tests, offline renders).
static var sync_render:=false
## The court that is open now (the set's animals call it: animal()).
static var current:Node
## Our people's tongue for the murmur, by "owner:seed" (written on the main
## thread, read by workers), and the six talkers made from it.
static var _tongues:Dictionary={}
static var _tracks:Dictionary={}
static var _prewarmed:Dictionary={}
## The keeper: one quiet node for the whole game that makes sounds ahead of
## time and collects every worker job (prewarm()); courts hand theirs to it.
static var keeper:Node
const MURMUR_PEOPLE:={"murmur_small":3,"murmur":6,"murmur_hall":10}
const MURMUR_SECONDS:=9.0
## The live murmur: how many talk at most, and at what level (dB, a run).
const TALK_SLOTS:={"murmur_small":3,"murmur":5,"murmur_hall":8}
const TALK_DB:={"murmur_small":-11.0,"murmur":-13.0,"murmur_hall":-15.0}
## Pan: buses Court-4..Court+4, AudioEffectPanner pan k*PAN_STEP (0.32 at the
## edge: the far side about 6 dB down).
const PAN_STEPS:=4
const PAN_STEP:=0.08
## The music's level (a phrase peaks at 0.6): soft, under the room.
const MUSIC_DB:=-23.0
## Who plays what and how, by "tongue key@ensemble" (made on the main thread).
static var _music_specs:Dictionary={}

## The director's acts (court_director.gd ACTS) as sounds: [cue, dB offset,
## delay seconds]. Acts of the dog and the goat sound only from an animal.
const BEAT_CUES:={
	"gasp":["gasp",0.0,0.05],"hand_to_mouth":["gasp",-5.0,0.05],"startle":["gasp",-4.0,0.0],"mortified":["gasp",-6.0,0.1],
	"snap_alert":["gasp",-6.0,0.0],"flinch":["rustle",-2.0,0.0],"wobble":["gasp",-7.0,0.1],
	"knees_knock":["knees_knock",0.0,0.0],"tremble":["rustle",-8.0,0.0],
	"faint":["faint_thump",0.0,0.55],"half_catch":["oof",-2.0,0.45],
	"drop_bowl":["bowl_drop",0.0,0.15],
	"stifle_laugh":["snort_laugh",0.0,0.05],"laugh":["laugh",0.0,0.0],"smirk":["hmph",-10.0,0.1],
	"snore":["snore",0.0,0.0],"doze":["snore",-8.0,1.2],"doze_off":["sigh",-4.0,0.3],"jerk_awake":["snort_wake",0.0,0.0],"yawn":["yawn",0.0,0.1],
	"stomach_growl":["stomach_growl",0.0,0.0],"floor_creak":["creak",0.0,0.0],
	"swallow_loud":["swallow",0.0,0.1],"gulp":["swallow",-6.0,0.05],
	"stifle_cough":["cough_fought",0.0,0.0],"cough":["cough",0.0,0.0],"cover_mouth":["cough_fought",-6.0,0.1],"clear_throat":["ahem",0.0,0.0],
	"struggle_bundle":["strain",0.0,0.1],"set_down_bundle":["bundle_thud",0.0,0.25],"lift_bundle":["heave",0.0,0.15],
	"shush":["shush",0.0,0.1],"elbow":["bump",-3.0,0.15],"nudge":["bump",-8.0,0.1],"bump_post":["bump",0.0,0.0],
	"kneel":["rustle",0.0,0.3],"kneel_bound":["rustle",0.0,0.3],"prostrate":["faint_thump",-8.0,0.5],"sit_down":["rustle",-2.0,0.4],
	"bow":["rustle",-6.0,0.2],"bow_deep":["rustle",-3.0,0.2],"double_bow":["rustle",-6.0,0.2],"over_thank":["hum_yes",-2.0,0.2],"copy":["rustle",-6.0,0.2],
	"stamp_feet":["stamp",0.0,0.0],"rub_hands":["rub_hands",0.0,0.0],"wring_hands":["rub_hands",-6.0,0.0],"breath":["breath_out",0.0,0.0],
	"swat_fly":["slap",-3.0,0.25],"swat_miss":["slap",0.0,0.25],"sharpen_spear":["spear_sharpen",0.0,0.0],"scribble":["scribble",0.0,0.0],
	"shake_hand":["rustle",-6.0,0.0],"smooth_clothes":["rustle",-4.0,0.0],
	"exhale":["sigh",0.0,0.0],"deflate_polite":["sigh",-3.0,0.3],"face_fall":["sigh",-8.0,0.2],"nod_too_much":["hum_yes",0.0,0.0],
	"sniff_disdain":["hmph",0.0,0.2],"brush_sleeve":["rustle",-6.0,0.0],
	"mutter":["mutter",0.0,0.0],"whisper":["mutter",-3.0,0.0],"count_fingers":["mutter",-4.0,0.2],"count_heads":["mutter",-6.0,0.2],
	# the animals
	"whimper":["dog_whimper",0.0,0.0],"hide_under":["dog_whimper",-6.0,0.2],"sniff":["dog_sniff",0.0,0.1],"perk_up":["",0.0,0.0],
	"bleat":["goat_bleat",0.0,0.0],"chew":["goat_chew",0.0,0.0],"nibble":["goat_chew",-2.0,0.0],"lie_down":["rustle",-8.0,0.3],
	"bark":["dog_bark",0.0,0.0],
}
## The sounds the director's beats name (court_director.gd SOUNDS: a beat
## lowered to {act: "sound", args: {name, gain, pace?, people?, words?, who}}),
## as cues: [cue, dB offset, variant (-1 any)]. Any cue name of
## court_foley.gd CUES is also heard as itself. footsteps, murmur_cut and the
## babble_* names are handled on their own (footsteps(), hush(), voice()).
const SOUND_NAMES:={
	"snore":["snore",0.0,-1],"growl":["stomach_growl",0.0,-1],"cough_fought":["cough_fought",0.0,-1],"cough":["cough",0.0,-1],
	"creak":["creak",0.0,-1],"swallow":["swallow",0.0,-1],"gasp":["gasp",0.0,-1],"gasp_room":["room_gasp",0.0,-1],
	"snort_laugh":["snort_laugh",0.0,-1],"bowl_clatter":["bowl_drop",0.0,-1],"bundle_thud_grunt":["bundle_thud",0.0,-1],
	"grunt":["grunt",0.0,-1],"faint_thump":["faint_thump",0.0,-1],"body_floor":["faint_thump",-4.0,-1],
	"dog_whimper":["dog_whimper",0.0,-1],"dog_sniff":["dog_sniff",0.0,-1],"dog_flop":["dog_flop",0.0,-1],"dog_bark":["dog_bark",0.0,-1],
	"goat_bleat":["goat_bleat",0.0,-1],"goat_chew":["goat_chew",0.0,-1],"goat_nibble":["goat_chew",-3.0,-1],
	"thud_wood":["bump",0.0,1],"stamp":["stamp",0.0,-1],"breath_out":["breath_out",0.0,-1],"slap_air":["whoosh",0.0,-1],"slap":["slap",0.0,-1],
	"yawn":["yawn",0.0,-1],"knees_knock":["knees_knock",0.0,-1],"kneel_cloth":["kneel_cloth",0.0,-1],"oof":["oof",0.0,-1],
	"shh":["shush",0.0,-1],"throat_clear":["ahem",0.0,-1],"babble_ahem":["ahem",0.0,-1],"sniff":["sniff",0.0,-1],
	"snort_wake":["snort_wake",0.0,-1],"reed_scratch":["scribble",0.0,-1],"soft_clap":["soft_clap",0.0,-1],"yelp_small":["yelp_small",0.0,-1],
	"snatch":["snatch",0.0,-1],"shoo":["shoo",0.0,-1],"laugh":["laugh",0.0,-1],"sigh":["sigh",0.0,-1],"hum_yes":["hum_yes",0.0,-1],
	"rustle":["rustle",0.0,-1],"scuff":["scuff",0.0,-1],"whoosh":["whoosh",0.0,-1],"hmph":["hmph",0.0,-1],
}
## Footsteps by pace: [seconds, steps a second, cue, dB].
const PACES:={"walk":[1.6,1.8,"step",0.0],"shuffle":[1.1,2.6,"scuff",-2.0],"hurry":[1.0,2.8,"step",0.0],"stomp":[1.4,2.2,"step",4.0],"run":[0.9,3.6,"step",1.0]}
## The babble a beat may ask for: [whisper, mood, seconds a word].
const BABBLES:={"babble_mutter":[true,"neutral",0.28],"whisper_babble":[true,"neutral",0.26],"babble_count":[true,"neutral",0.3],
	"babble_thanks":[false,"warm",0.22]}
## When the director names its own sounds, the stage's acts it leaves silent
## may still rustle: cloth and hands only, never a voice (the director
## decides who is heard; the room's gasp is heard once).
const QUIET_ACTS:=["bow","bow_deep","bow_small","double_bow","copy","sit_down","smooth_clothes","brush_sleeve","flinch","rub_hands","wring_hands",
	"sharpen_spear","shake_hand","tremble"]

## Acts that are walking: footsteps for their length.
const WALK_ACTS:={"storm_off":1.6,"bolt":1.0,"hurry":0.9,"hurry_round":1.2,"enter_wrong":1.0,"come_back":1.4,"come_back_for":1.4,"hurry_after":0.9,
	"back_out_bowing":2.0,"walk_in":2.0,"walk_out":2.0,"step_back":0.5,"make_room":0.6}
## Acts only an animal makes a sound for.
const ANIMAL_ACTS:=["whimper","hide_under","sniff","bleat","chew","nibble","lie_down","bark","perk_up"]
## The god's acts of wrath and of favour (divine_regard.gd and the stage).
const WRATH:=["terrify","penance","rebuke","threaten","strike_down","cast_out","curse","smite","envoy_flog","envoy_maim","envoy_kill","envoy_detain","envoy_exile"]
const FAVOUR:=["bless","boon","raise_up","honour","honor","reward","favour","favor"]
## The sets (court_set_3d.gd kinds): open air or under a roof, the floor.
const OPEN_SETS:=["fire_ring","shelter"]
## How often a bird is heard by season: seconds between, at least and at most.
const BIRD_SPANS:={"spring":[2.0,6.0],"summer":[2.5,7.0],"autumn":[9.0,22.0]}
const WOOD_FLOORS:=["grand_hall"]

## The stage this sound belongs to (a CourtStage), or null.
var stage:Control
var set_kind:="fire_ring"
var season:="summer"
var facts:Dictionary={}
## What played, newest last (tests and review): [{name, at, db, key}]. Kept short.
var played:Array=[]
var _pool:Array[AudioStreamPlayer]=[]
## The game's own clock (seconds of process time since this sound was made).
var _clock:=0.0
## The crowd's talkers: players, when each may start again, their fades.
var _slots:Array[AudioStreamPlayer]=[]
var _slot_free:=PackedFloat32Array()
var _slot_tw:Array=[]
var _talk_size:="murmur"
var _talk_db:=-17.0
var _energy:=0.7
var _energy_at:=0.0
var _shy_until:=0.0
var _duck_until:=0.0
## The musician.
var _music:AudioStreamPlayer
var _music_tw:Tween
var _music_key:=""
var _music_next:=INF
var _music_until:=0.0
var _music_last:=-1
var _music_tentative:=false
var _music_bright_until:=0.0
var _music_side:=2
var _music_said:=""
var _beds:Dictionary={}       # role -> AudioStreamPlayer
var _bed_db:Dictionary={}     # role -> the level it rests at
var _bed_tweens:Dictionary={}
var _god:AudioStreamPlayer
var _god_tween:Tween
var _timer:Timer
var _rng:=RandomNumberGenerator.new()
var _next:Dictionary={}       # random life -> when it next sounds
var _queue:Array=[]           # [{at, name, variant, body, db, pitch}]
var _hush_until:=0.0
var _hushed:=false
var _hush_began:=0.0
var _voices:Dictionary={}     # identity -> voice spec
var _talk:Dictionary={}       # body instance id -> token of the line in flight
var _token:=0
var _open:=false
var _tasks:Array[int]=[]      # worker-thread jobs not yet collected
## The keeper (prewarm()): makes sounds ahead of time and collects jobs.
var keeps:=false
var _tongue_key:=""
var _animal_last:Dictionary={} # cue -> when an animal last made it
var _bed_list:Array=[]        # beds_for() of the open room, made once

# =============================================================================
# Setting up
# =============================================================================

## The sound of a stage: made once as the stage's child and returned again
## after. Positional sound joins the stage's 3D hall when it has one.
static func attach(stage_node:Control)->Node:
	if stage_node==null:return null
	var existing:=stage_node.get_node_or_null("CourtSound")
	if existing!=null:return existing
	var made:Node=Self.new()
	made.name="CourtSound"
	made.set("stage",stage_node)
	stage_node.add_child(made)
	return made

func _ready()->void:
	if keeps:
		_timer=Timer.new();_timer.name="Collect";_timer.wait_time=0.25
		add_child(_timer);_timer.timeout.connect(_tick)
		if not _tasks.is_empty():_timer.start()
		return
	ensure_bus()
	if stage!=null:
		current=self
		_tongue_key=register_tongue("player",world_seed())
		prewarm(keeper.get_parent() if keeper!=null and is_instance_valid(keeper) and keeper.is_inside_tree() else get_tree().root)
	_rng.seed=hash("court_sound|%s" % (String(stage.get("audience_key")) if stage!=null and stage.get("audience_key")!=null else "court"))
	for i in 8:
		var p:=AudioStreamPlayer.new();p.bus=BUS;p.name="Sound%d" % i
		add_child(p);_pool.append(p)
	_god=AudioStreamPlayer.new();_god.name="God";_god.bus=BUS;add_child(_god)
	for i in 8:
		var t:=AudioStreamPlayer.new();t.bus=BUS;t.name="Talk%d" % i
		add_child(t);_slots.append(t);_slot_tw.append(null)
	_slot_free.resize(8)
	_music=AudioStreamPlayer.new();_music.name="Musician";_music.bus=BUS;add_child(_music)
	_timer=Timer.new();_timer.name="RoomLife";_timer.wait_time=0.1
	add_child(_timer);_timer.timeout.connect(_tick)
	set_process(true)
	if stage!=null:
		if not stage.visibility_changed.is_connected(_on_visibility):stage.visibility_changed.connect(_on_visibility)

func _process(delta:float)->void:
	_clock+=delta

func _exit_tree()->void:
	if current==self:current=null
	if keeper==self:keeper=null
	stop_all()
	# a court that closes does not wait for its jobs: the keeper collects them
	if not keeps and keeper!=null and is_instance_valid(keeper) and keeper.is_inside_tree():
		for id in _tasks:keeper.call("_track",id)
	else:
		for id in _tasks:WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()

## A worker-thread job to collect once it is done (every task is waited for).
func _track(id:int)->void:
	if id<0:return
	_tasks.append(id)
	if is_inside_tree():_ensure_timer()

func _collect()->void:
	var i:=0
	while i<_tasks.size():
		if WorkerThreadPool.is_task_completed(_tasks[i]):
			WorkerThreadPool.wait_for_task_completion(_tasks[i]);_tasks.remove_at(i)
		else:i+=1

## The "Court" bus (to Master) with a little room on it, at the player's level.
static func ensure_bus()->int:
	var bus:=AudioServer.get_bus_index(BUS)
	if bus<0:
		AudioServer.add_bus()
		bus=AudioServer.bus_count-1
		AudioServer.set_bus_name(bus,BUS)
		AudioServer.set_bus_send(bus,"Master")
		var room:=AudioEffectReverb.new()
		room.room_size=0.25;room.damping=0.7;room.wet=0.0;room.dry=1.0;room.spread=0.6;room.predelay_msec=12.0
		AudioServer.add_bus_effect(bus,room,0)
	for k in range(-PAN_STEPS,PAN_STEPS+1):
		if k==0 or AudioServer.get_bus_index(pan_bus(k))>=0:continue
		AudioServer.add_bus()
		var b:=AudioServer.bus_count-1
		AudioServer.set_bus_name(b,pan_bus(k))
		AudioServer.set_bus_send(b,BUS)
		var panner:=AudioEffectPanner.new();panner.pan=float(k)*PAN_STEP
		AudioServer.add_bus_effect(b,panner,0)
	AudioServer.set_bus_mute(bus,volume<=0.0)
	AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(0.0001,volume)))
	return bus

## The bus for a place across the room: k from -PAN_STEPS (left) to +PAN_STEPS.
static func pan_bus(k:int)->String:
	return BUS if k==0 else "%s%+d" % [BUS,k]

## The player's "Court sounds" level (0 mutes them).
static func set_volume(value:float)->void:
	volume=clampf(value,0.0,1.0)
	ensure_bus()

static func muted()->bool:
	var bus:=AudioServer.get_bus_index(BUS)
	return volume<=0.0 or (bus>=0 and AudioServer.is_bus_mute(bus))

## Whether anything may sound now: not muted, and the court is open and shown.
func can_play()->bool:
	if muted() or not is_inside_tree():return false
	if stage!=null and not stage.is_visible_in_tree():return false
	return true

func _on_visibility()->void:
	if stage==null:return
	if stage.is_visible_in_tree():
		if _open:_start_beds()
	else:
		stop_all()

## Every sound stops (the court hidden, closed, or muted).
func stop_all()->void:
	for p in _pool:
		if is_instance_valid(p):p.stop()
	for t in _slots:
		if is_instance_valid(t):t.stop()
	if is_instance_valid(_music):_music.stop()
	for role in _beds:
		var b:AudioStreamPlayer=_beds[role]
		if is_instance_valid(b):b.stop()
	if is_instance_valid(_god):_god.stop()
	if is_instance_valid(_timer):_timer.stop()
	_queue.clear()

# =============================================================================
# Streams, made once
# =============================================================================

## A cue's stream, from the cache or made now.
static func stream_for(name:String,variant:=0)->AudioStreamWAV:
	var key:="%s|%d" % [name,variant]
	_lock.lock()
	var held:Variant=_cache.get(key,null)
	_lock.unlock()
	if held!=null:return held
	var made:AudioStreamWAV
	if name.begins_with("talker@"):made=_talker_stream(name.trim_prefix("talker@"),variant)
	elif name.begins_with("music"):made=_music_stream(name,variant)
	elif name.contains("@"):made=_murmur_stream(name.get_slice("@",0),name.get_slice("@",1))
	else:made=Foley.stream(name,variant)
	_lock.lock();_cache[key]=made;_lock.unlock()
	return made

## A people's tongue, read here (main thread) so workers can make its murmur.
static func register_tongue(owner:String,seed_value:int)->String:
	var key:="%s:%d" % [owner,seed_value]
	_lock.lock();var has:=_tongues.has(key);_lock.unlock()
	if not has:
		var tongue:=Voice.phonology(owner,seed_value)
		_lock.lock();_tongues[key]=tongue;_lock.unlock()
	return key

## The crowd's murmur of a size ("murmur_small", "murmur", "murmur_hall") in a
## registered tongue: six talkers made once per tongue, mixed to the size.
static func _murmur_stream(size:String,key:String)->AudioStreamWAV:
	_lock.lock()
	var tracks:Variant=_tracks.get(key,null)
	var tongue:Dictionary=_tongues.get(key,{})
	_lock.unlock()
	if tracks==null:tracks=_talkers(key)
	var rng:=RandomNumberGenerator.new();rng.seed=Synth.seed_of(key+"|"+size)
	var b:=Foley.murmur_mix(tracks,int(MURMUR_PEOPLE.get(size,6)),MURMUR_SECONDS,rng)
	var top:=Synth.peak_of(b)
	if top>0.0001:Synth.scale(b,0.6/top)
	return Synth.to_stream(b,0.0,true)

## One of the six talkers of a registered tongue (made all together, once).
static func _talker_stream(key:String,k:int)->AudioStreamWAV:
	return Synth.to_stream(_talkers(key)[clampi(k,0,Foley.MURMUR_VOICES.size()-1)],0.0)

static func _talkers(key:String)->Array[PackedFloat32Array]:
	_lock.lock()
	var held:Variant=_tracks.get(key,null)
	var tongue:Dictionary=_tongues.get(key,{})
	_lock.unlock()
	if held!=null:return held
	var made:=Foley.murmur_tracks(tongue,Synth.seed_of(key),Foley.TALKER_SECONDS+0.6)
	_lock.lock();_tracks[key]=made;_lock.unlock()
	return made

## Who plays what among a people with a registered tongue, from what they know
## (discovery ids): the key their music's streams are made under.
static func register_music(tongue_key:String,known:Array)->String:
	_lock.lock()
	var tongue:Dictionary=_tongues.get(tongue_key,{})
	_lock.unlock()
	var family:=String(tongue.get("family","west_african"))
	var spec:=Music.people(family,Synth.seed_of(tongue_key+"|music"),known)
	var key:="%s@%s" % [tongue_key,String((spec.ensemble as Dictionary).name)]
	_lock.lock();_music_specs[key]=spec;_lock.unlock()
	return key

static func music_spec(key:String)->Dictionary:
	_lock.lock()
	var spec:Dictionary=_music_specs.get(key,{})
	_lock.unlock()
	return spec

## A stream of the people's music: "music@<key>" a phrase (variant 0..7),
## "musicfl@<key>" the flourish, "musicstop@<key>" the stop (variant 0..2),
## "musictap@<key>" the drum's stray tap.
static func _music_stream(name:String,variant:int)->AudioStreamWAV:
	var kind:=name.get_slice("@",0)
	var spec:=music_spec(name.substr(name.find("@")+1))
	if spec.is_empty():return Synth.to_stream(Synth.buffer(0.05))
	var samples:PackedFloat32Array
	match kind:
		"musicfl":samples=Music.flourish(spec)
		"musicstop":samples=Music.stop(spec,variant)
		"musictap":samples=Music.tap(spec)
		_:samples=Music.phrase(spec,variant)
	return Synth.to_stream(samples,0.0)

## Makes the court's sounds ahead of time on a worker thread, so the room is
## never silent when the court opens: the beds, our people's murmur in their
## own tongue, the god's swells and the common sounds. Call once the game
## has loaded (display_preferences.gd does) and again when the court is
## first summoned; a second call for the same world does nothing.
static func prewarm(host:Node,force:=false)->void:
	if host==null or not host.is_inside_tree():return
	if DisplayServer.get_name()=="headless" and not force:return
	var key:=register_tongue("player",world_seed())
	if _prewarmed.has(key) and not force:return
	_prewarmed[key]=true
	var list:Array=[]
	for bed in ["fire","wind_soft","wind_hard","wind_indoor","room"]:list.append([bed,0])
	for k in Foley.MURMUR_VOICES.size():list.append(["talker@"+key,k])
	list.append(["god_swell_wrath",0]);list.append(["god_swell_favour",0])
	for cue_name in ["gasp","room_gasp","creak","stomach_growl","snore","snort_wake","swallow","cough_fought","knees_knock","rustle","snort_laugh","fire_pop","step_earth","kneel_cloth","faint_thump","bowl_drop"]:
		for v in Foley.variants(cue_name):list.append([cue_name,v])
	if keeper==null or not is_instance_valid(keeper):
		keeper=Self.new()
		keeper.name="CourtSoundKeeper"
		keeper.set("keeps",true)
		host.add_child.call_deferred(keeper)
	keeper.call("_track",warm(list))

static func cached(name:String,variant:=0)->bool:
	_lock.lock()
	var has:=_cache.has("%s|%d" % [name,variant])
	_lock.unlock()
	return has

## Makes these [[name, variant]...] on a worker thread, once.
static func warm(list:Array)->int:
	var todo:Array=[]
	for item in list:
		if not cached(String(item[0]),int(item[1])):todo.append(item)
	if todo.is_empty():return -1
	return WorkerThreadPool.add_task(func()->void:
		for item in todo:stream_for(String(item[0]),int(item[1]))
	,false,"court sound")

## Forgets every made stream (tests).
static func clear_cache()->void:
	_lock.lock();_cache.clear();_lock.unlock()

# =============================================================================
# One-shots
# =============================================================================

## Plays a sound at a body (a figure's Node3D) or the room. opts: variant
## (else a fresh one), db (added to its level), pitch (1 = as made; else a
## little random), delay (seconds). A hush silences the room's idle life, not
## a cue: the stomach that growls in the silence IS the joke.
## Returns whether it will sound.
func cue(name:String,at_body:Node3D=null,opts:Dictionary={})->bool:
	if name.is_empty() or not can_play():return false
	if not Foley.CUES.has(name) and name!="mutter" and not name.begins_with("music"):return false
	if float(opts.get("delay",0.0))>0.0:
		_queue.append({"at":_now()+float(opts.delay),"name":name,"body":at_body,"opts":opts.duplicate()})
		_ensure_timer()
		return true
	if name=="mutter":
		return voice(at_body,_mutter_text(),1.1,"neutral","",{"whisper":true,"db":float(opts.get("db",0.0))})
	if name.begins_with("music"):
		var made:=stream_for(name,maxi(0,int(opts.get("variant",0))))
		return _play(made,at_body,MUSIC_DB+float(opts.get("db",0.0)),1.0,name.get_slice("@",0),int(opts.get("pan",_music_pan())))!=null
	var real:=name
	var variant:=int(opts.get("variant",-1))
	var n:=Foley.variants(real)
	if variant<0:variant=_rng.randi_range(0,n-1)
	var s:=stream_for(real,variant)
	var db:=Foley.level(real)+float(opts.get("db",0.0))
	var pitch:=float(opts.get("pitch",_rng.randf_range(0.95,1.05)))
	return _play(s,at_body,db,pitch,name,int(opts.get("pan",NO_PAN)))!=null

const NO_PAN:=-99
func _play(s:AudioStream,at_body:Node3D,db:float,pitch:float,label:String,pan:=NO_PAN)->Node:
	if s==null:return null
	var k:=pan if pan!=NO_PAN else pan_of(at_body)
	var q:=_free2d()
	q.bus=pan_bus(clampi(k,-PAN_STEPS,PAN_STEPS))
	q.stream=s;q.volume_db=db;q.pitch_scale=pitch
	q.play()
	played.append({"name":label,"at":_now(),"db":db,"pan":k})
	if played.size()>48:played.pop_front()
	return q

## Where a body stands across the picture, as a pan step: its screen x on
## the stage (world_to_stage), so what is seen on the left is heard on the left.
## 0 for the room itself or a stage that cannot say.
func pan_of(body:Node3D)->int:
	if body==null or not is_instance_valid(body) or not body.is_inside_tree() or stage==null or not stage.has_method("world_to_stage"):return 0
	var w:=maxf(1.0,stage.size.x)
	var at:Variant=stage.call("world_to_stage",body.global_position)
	if not at is Vector2:return 0
	var n:=clampf(((at as Vector2).x/w*2.0-1.0)/0.7,-1.0,1.0)
	return clampi(roundi(n*float(PAN_STEPS)),-PAN_STEPS,PAN_STEPS)

## A free player, or the one that has played longest.
func _free2d()->AudioStreamPlayer:
	var best:=_pool[0];var longest:=-1.0
	for p in _pool:
		if not p.playing:return p
		var at:=p.get_playback_position()
		if at>longest:longest=at;best=p
	return best


## Seconds of the game's own time (a movie's frames, not the wall clock).
func _now()->float:
	return _clock

## Sounds are made on the spot when they must be exact: tests, and a movie
## being written (the frames wait for them, so nothing is late).
static func exact()->bool:
	return sync_render or OS.has_feature("movie")
## Footsteps for a while at a body: earth or wood by the set; pace in steps a second.
func footsteps(body:Node3D,seconds:float,pace:=1.8,heavy:=false,cue_name:="step",db:=0.0)->void:
	if not can_play():return
	var name:=cue_name
	if cue_name=="step":name="step_wood" if set_kind in WOOD_FLOORS else "step_earth"
	var t:=0.0
	var k:=0
	while t<seconds:
		_queue.append({"at":_now()+t,"name":name,"body":body,"opts":{"variant":k%4,"db":db+(3.0 if heavy else 0.0)+_rng.randf_range(-2.0,1.0)}})
		t+=1.0/pace*_rng.randf_range(0.92,1.08);k+=1
	_ensure_timer()

## Footsteps at one of the director's paces: walk, shuffle, hurry, stomp, run.
func steps_at_pace(body:Node3D,pace:String,db:=0.0)->void:
	var p:Array=PACES.get(pace,PACES.walk)
	footsteps(body,float(p[0]),float(p[1]),false,String(p[2]),float(p[3])+db)

## Whether a sound name (the director's or a cue's) is one this court can make.
static func knows(name:String)->bool:
	return SOUND_NAMES.has(name) or Foley.CUES.has(name) or BABBLES.has(name) or name in ["footsteps","murmur_cut","snort_wake","mutter"]

## One of the director's sounds by name ({name, gain, pace?, people?,
## words?, dur?, text?}) at a body. Returns whether it will sound.
func sound(args:Dictionary,body:Node3D=null,who:="")->bool:
	var name:=String(args.get("name",""))
	if name.is_empty():return false
	var db:=clampf(linear_to_db(maxf(0.05,float(args.get("gain",0.8))))+2.0,-18.0,4.0)
	if name=="murmur_cut":
		hush(float(args.get("dur",2.0)))
		return true
	if not can_play():return false
	if name=="footsteps":
		steps_at_pace(body,String(args.get("pace","walk")),db)
		return true
	if BABBLES.has(name):
		var spec:Array=BABBLES[name]
		var words:=maxi(1,int(args.get("words",4)))
		var text:=String(args.get("text",""))
		if text.is_empty():text=_babble_text(words)
		var fig:=_figure(who)
		var secs:=clampf(float(words)*float(spec[2]),0.6,3.0)
		var mood:String=String(spec[1]) if not bool(spec[0]) else _mood_of(fig)
		return voice(body,text,secs,mood,String(args.get("people","")),{"person":_person(fig),"whisper":bool(spec[0]),"db":db,"kind":_kind_of(who)})
	var cue_name:=name
	var variant:=-1
	if SOUND_NAMES.has(name):
		var m:Array=SOUND_NAMES[name]
		cue_name=String(m[0]);db+=float(m[1]);variant=int(m[2])
	elif not Foley.CUES.has(name):return false
	var opts:={"db":db,"delay":float(args.get("delay",0.0))}
	if variant>=0:opts["variant"]=variant
	if cue_name in ["gasp","snort_laugh","laugh","cough","cough_fought","ahem","hmph","yawn","sigh","hum_yes","oof","grunt","yelp_small"]:
		opts["variant"]=_register_variant(cue_name,who)
	return cue(cue_name,body,opts)

func _babble_text(words:int)->String:
	var out:PackedStringArray=PackedStringArray()
	var pool:=["ka","lo","mena","ti","sura","na","re","vo","bado","di"]
	for i in words:out.append(pool[_rng.randi_range(0,pool.size()-1)])
	return " ".join(out)

# =============================================================================
# Voices
# =============================================================================

## A line's babble from a body, timed to its mouth: the same text over the
## same seconds as the acting layer's speak(). mood: a mood word or the acting
## layer's vector. people_id: whose people ("player", "civ_07"; else read from
## the person). opts: person (the game person, else the stage's), whisper (a
## mutter), aside (said quietly to the god), db, key (the stage key), kind,
## variant. Returns whether it will sound.
func voice(body:Node3D,text:String,seconds:float,mood:Variant="neutral",people_id:="",opts:Dictionary={})->bool:
	if text.strip_edges().is_empty() or seconds<=0.05 or not can_play():return false
	var person:Dictionary=opts.get("person",{}) if opts.get("person") is Dictionary else {}
	var extra:={"kind":String(opts.get("kind","")),"temper":String(opts.get("temper","")),"variant":String(opts.get("variant",""))}
	if body!=null and is_instance_valid(body) and String(extra.variant).is_empty():
		var v:Variant=body.get("variant")
		if v!=null:extra["variant"]=String(v)
	var owner:=people_id if not people_id.is_empty() else _owner_of(person)
	var spec:=voice_for(person,owner,extra)
	var whisper:=bool(opts.get("whisper",false))
	var db:=-13.0+float(opts.get("db",0.0))
	if whisper:db-=5.0
	if bool(opts.get("aside",false)):db-=4.0
	var feel:=Voice.feeling(mood)
	# Our people at a god's temper: dread puts fear in every voice.
	if owner=="player" and facts.has("dread"):
		feel["fear"]=maxf(float(feel.fear),clampf((float(facts.dread)-0.5)*0.8,0.0,0.4))
	if not whisper:_duck(seconds)
	var token:=_next_token()
	var id:=body.get_instance_id() if body!=null else 0
	_talk[id]=token
	var started:=_now()
	if exact():
		var s:=Voice.render(spec,text,seconds,feel,whisper)
		return _voice_ready(s,id,token,started,db)
	var job:=spec.duplicate(true)
	var me:WeakRef=weakref(self)
	_track(WorkerThreadPool.add_task(func()->void:
		var s:=Voice.render(job,text,seconds,feel,whisper)
		var still:Object=me.get_ref()
		if still!=null:still.call_deferred("_voice_ready",s,id,token,started,db)
	,false,"court voice"))
	return true

## The crowd talks lower while someone speaks up, and comes back after.
func _duck(seconds:float)->void:
	if _hushed:return
	_duck_until=maxf(_duck_until,_now()+seconds)
	if is_instance_valid(_music) and _music.playing:
		var mt:=create_tween()
		mt.tween_property(_music,"volume_db",_music.volume_db-10.0,0.3).set_trans(Tween.TRANS_SINE)
		mt.tween_interval(maxf(0.2,seconds))
		mt.tween_property(_music,"volume_db",_music.volume_db,1.2).set_trans(Tween.TRANS_SINE)
	for i in _slots.size():
		var t:=_slots[i]
		if not t.playing:continue
		var tw:=create_tween()
		tw.tween_property(t,"volume_db",t.volume_db-8.0,0.35).set_trans(Tween.TRANS_SINE)

func _next_token()->int:
	_token+=1
	return _token

func _voice_ready(s:AudioStreamWAV,id:int,token:int,started:float,db:float)->bool:
	if int(_talk.get(id,-1))!=token or not can_play():return false
	var found:Object=instance_from_id(id) if id!=0 else null
	var body:Node3D=found as Node3D if found!=null and is_instance_valid(found) else null
	var late:=_now()-started
	var used:=_play(s,body,db,1.0,"voice")
	if used==null:return false
	# join the mouth where it has got to
	if late>0.03 and late<s.get_length():used.call("seek",late)
	return true

## A person's voice for life (cached for this court).
func voice_for(person:Dictionary,owner:String,extra:Dictionary={})->Dictionary:
	var key:="%s|%d|%s|%s" % [owner,int(person.get("person_id",0)),String(person.get("name","")),String(extra.get("variant",""))]
	if _voices.has(key):return _voices[key]
	var seed_value:=int(person.get("appearance_world_seed",world_seed()))
	var made:=Voice.spec(person,owner,seed_value,extra)
	_voices[key]=made
	return made

## The world's seed (GameState), read without naming the autoload so this
## script also loads in tools run with -s.
static func world_seed()->int:
	var tree:=Engine.get_main_loop() as SceneTree
	var state:Node=tree.root.get_node_or_null("GameState") if tree!=null and tree.root!=null else null
	return int(state.get("world_seed")) if state!=null else 0

static func _owner_of(person:Dictionary)->String:
	return String(person.get("appearance_civ_id",person.get("civilization_id","player")))

func _mutter_text()->String:
	var words:=["mm","so","there","it","was","the","and","he","then","well"]
	var out:PackedStringArray=PackedStringArray()
	for i in _rng.randi_range(3,6):out.append(words[_rng.randi_range(0,words.size()-1)])
	return " ".join(out)

# =============================================================================
# The room: beds, life, hush
# =============================================================================

## The room's sound for a set (court_set_3d.gd kinds: fire_ring, shelter,
## longhouse, mudbrick_hall, grand_hall) in a season (spring, summer, autumn,
## winter), dressed by the fact sheet: how many stand about (era tier), the
## people's dread (a frightened hall talks low), hens and goats where the
## people keep them.
func ambience(set_id:String,season_id:String,facts_in:Dictionary={})->void:
	set_kind=set_id if not set_id.is_empty() else "fire_ring"
	season=season_id if season_id in ["spring","summer","autumn","winter"] else "summer"
	facts=facts_in.duplicate()
	# the set knows which beasts the people keep (hens, goats)
	var cs:Variant=stage.get("court_set") if stage!=null else null
	if cs is Node3D and is_instance_valid(cs) and (cs as Node3D).get("facts") is Dictionary:
		var kept:Dictionary=(cs as Node3D).get("facts")
		for key in ["herds","fowl"]:
			if kept.has(key) and not facts.has(key):facts[key]=kept[key]
	_open=true
	var bus:=ensure_bus()
	var room:=AudioServer.get_bus_effect(bus,0) as AudioEffectReverb
	if room!=null:
		var open_air:=set_kind in OPEN_SETS
		room.wet=0.04 if open_air else (0.12 if set_kind in ["longhouse"] else 0.18)
		room.room_size=0.15 if open_air else (0.32 if set_kind=="longhouse" else 0.55)
	_bed_list=beds_for(set_kind,season,facts)
	if _tongue_key.is_empty():_tongue_key=register_tongue("player",world_seed())
	var talk:Array=talk_for(facts)
	_talk_size=String(talk[0]);_talk_db=float(talk[1])
	var warm_list:Array=[]
	# the musician: what the people know, their own way of playing it
	_music_key=register_music(_tongue_key,_known())
	_music_side=[-2,2,3,-3][absi(hash(_music_key))%4]
	for k in Music.PHRASES:warm_list.append(["music@"+_music_key,k])
	warm_list.append(["musicstop@"+_music_key,0]);warm_list.append(["musictap@"+_music_key,0]);warm_list.append(["musicfl@"+_music_key,0])
	_music_next=_now()+_rng.randf_range(0.8,2.5)
	for k in Foley.MURMUR_VOICES.size():warm_list.append(["talker@"+_tongue_key,k])
	for role in _bed_list:warm_list.append([String(role[1]),0])
	warm_list.append(["god_swell_wrath",0]);warm_list.append(["god_swell_favour",0])
	for name in ["gasp","room_gasp","creak","stomach_growl","snore","fire_pop","knees_knock","swallow","cough_fought","rustle","snort_laugh"]:
		for v in Foley.variants(name):warm_list.append([name,v])
	if exact():
		# made here and now: the room starts complete
		for role in _bed_list:stream_for(String(role[1]),0)
		if OS.has_feature("movie"):
			for item in warm_list:stream_for(String(item[0]),int(item[1]))
	else:
		_track(warm(warm_list))
	# the room is already talking when the court opens, and talks a good deal at first
	for i in _slot_free.size():_slot_free[i]=_now()+_rng.randf_range(0.0,0.6)
	_energy=_rng.randf_range(0.75,1.0);_energy_at=_now()+_rng.randf_range(8.0,16.0)
	_next.clear()
	if can_play():_start_beds()

## What our people know (discovery ids): the fact sheet's "known" when the
## stage gives it, else the game's own (character_voice.gd known_ids).
func _known()->Array:
	if facts.get("known") is Array:return facts.known
	if ResourceLoader.exists("res://scripts/character_voice.gd") and world_seed()!=0:
		var cv:GDScript=load("res://scripts/character_voice.gd")
		var got:Variant=cv.call("known_ids","player")
		if got is Array:return got
	return []

## The beds for a set and season: [[role, bed name, dB offset]...].
static func beds_for(set_id:String,season_id:String,facts_in:Dictionary)->Array:
	var out:Array=[]
	var open_air:=set_id in OPEN_SETS
	out.append(["fire","fire",0.0 if open_air else -2.0])
	if open_air:out.append(["wind","wind_hard" if season_id=="winter" else "wind_soft",-3.0 if season_id=="winter" else 0.0])
	else:out.append(["wind","wind_indoor",6.0 if season_id=="winter" else 0.0])
	if not open_air:out.append(["room","room",0.0])
	return out

## The crowd's talk for the facts: [size, dB a run]. More talk as the age
## grows; a frightened hall talks low.
static func talk_for(facts_in:Dictionary)->Array:
	var tier:=int(facts_in.get("era_tier",facts_in.get("tier",0)))
	var dread:=float(facts_in.get("dread",facts_in.get("people_dread",0.2)))
	var size:="murmur_small" if tier<=0 else ("murmur" if tier<=2 else "murmur_hall")
	return [size,float(TALK_DB[size])-(5.0 if dread>=0.55 else 0.0)]

func _start_beds()->void:
	if not can_play():return
	for role:Array in _bed_list:
		var bed_role:=String(role[0]);var bed_name:=String(role[1])
		if not cached(bed_name,0) and not exact():continue
		var p:AudioStreamPlayer=_beds.get(bed_role,null)
		if p==null:
			p=AudioStreamPlayer.new();p.name="Bed_"+bed_role;p.bus=BUS;add_child(p);_beds[bed_role]=p
		var level:=Foley.level(bed_name.get_slice("@",0))+float(role[2])
		_bed_db[bed_role]=level
		var s:=stream_for(bed_name,0)
		if p.stream!=s:p.stream=s
		if not p.playing:
			p.volume_db=level-30.0 if not _hushed else -80.0
			p.play(_rng.randf_range(0.0,maxf(0.0,s.get_length()-1.0)))
			_fade(bed_role,level,1.2)
	_ensure_timer()
func _fade(role:String,to_db:float,seconds:float)->void:
	var p:AudioStreamPlayer=_beds.get(role,null)
	if p==null:return
	var old:Tween=_bed_tweens.get(role,null)
	if old!=null and old.is_valid():old.kill()
	if seconds<=0.0:p.volume_db=to_db;return
	var tw:=create_tween()
	tw.tween_property(p,"volume_db",to_db,seconds).set_trans(Tween.TRANS_SINE)
	_bed_tweens[role]=tw

func _ensure_timer()->void:
	if is_instance_valid(_timer) and _timer.is_stopped() and is_inside_tree():_timer.start()

## The crowd goes dead silent: true (until hush(false)), false (they breathe
## again: the murmur creeps back, a beat late), or seconds.
func hush(on:Variant=true)->void:
	var until:=_hush_until
	if on is bool:
		if bool(on):until=_now()+3600.0
		else:until=0.0
	else:until=maxf(_hush_until,_now()+float(on))
	_hush_until=until
	if _hush_until>_now() and not _hushed:
		_hushed=true
		_hush_began=_now()
		# the cut is sharp: that is the joke
		_cut_talk()
		_music_stop_dead()
		_fade("fire",float(_bed_db.get("fire",-20.0))-4.0,0.25)
		_fade("wind",float(_bed_db.get("wind",-26.0))-3.0,0.4)
		_ensure_timer()
	elif _hush_until<=_now() and _hushed:
		_unhush()

func _unhush()->void:
	_hushed=false
	_hush_until=0.0
	var now:=_now()
	# someone has to be first to speak again: one whisper, then the rest
	if _open and now-_hush_began>1.5:
		cue("mutter",_someone_in_crowd(),{"db":-3.0,"delay":0.45})
	_fade("fire",float(_bed_db.get("fire",-17.0)),1.0)
	_fade("wind",float(_bed_db.get("wind",-26.0)),1.5)
	# the talk comes back late and shy, one and then another: nobody wants to be first
	_shy_until=now+3.0
	for i in _slot_free.size():_slot_free[i]=now+0.9+float(i)*_rng.randf_range(0.35,0.8)
	# the musician waits longer still, then tries again, quietly (after favour, at once and brighter)
	if now<_music_bright_until:_music_next=now+_rng.randf_range(0.6,1.4);_music_tentative=false
	else:_music_next=maxf(_music_next,now+_rng.randf_range(3.0,6.0))

## The crowd's talk stops dead (a hush): every talker cut in a few hundredths.
func _cut_talk()->void:
	for i in _slots.size():
		var t:=_slots[i]
		var old:Variant=_slot_tw[i]
		if old is Tween and (old as Tween).is_valid():(old as Tween).kill()
		_slot_free[i]=maxf(_slot_free[i],_hush_until+0.5)
		if not t.playing:continue
		var tw:=create_tween()
		tw.tween_property(t,"volume_db",-80.0,0.06)
		tw.tween_callback(t.stop)
		_slot_tw[i]=tw

## The musician stops dead: the phrase cut in hundredths of a second, the
## lead's own squeak or honk or plunk as it breaks off, the drummer's hand
## already on its way down for one more tap, then nothing. They wait for the
## god to finish, then try again, tentatively.
func _music_stop_dead()->void:
	if not is_instance_valid(_music) or _music_key.is_empty():return
	var now:=_now()
	_music_tentative=true
	_music_next=maxf(_music_next,_hush_until+_rng.randf_range(3.0,6.0))
	if not _music.playing or now>=_music_until:return
	if _music_tw!=null and _music_tw.is_valid():_music_tw.kill()
	var tw:=create_tween()
	tw.tween_property(_music,"volume_db",-80.0,0.03)
	tw.tween_callback(_music.stop)
	_music_tw=tw
	_music_until=now
	var pan:=_music_pan()
	_play(stream_for("musicstop@"+_music_key,_rng.randi_range(0,2)),null,MUSIC_DB+5.0,1.0,"music_stop",pan)
	var spec:=music_spec(_music_key)
	if String((spec.get("ensemble",{}) as Dictionary).get("drum",""))!="":
		_queue.append({"at":now+_rng.randf_range(0.22,0.34),"name":"musictap@"+_music_key,"body":null,"opts":{"db":3.0,"pan":pan}})
		_ensure_timer()
	_say_music("stop_dead")

## Where the musician sits: their figure, when the stage stands one up
## (extras "musician"), else a place of their own off to one side.
func _music_pan()->int:
	var b:=_body_of("musician")
	return pan_of(b) if b!=null else _music_side

## The musician between the god's words: a phrase when it is time, a rest
## between; the first after a stop is tentative (quiet, and given up after a
## few notes); after favour, brighter (a little higher and quicker, sooner).
func _music_tick(now:float)->void:
	if _music_said in ["play","tentative","flourish"] and now>=_music_until:_say_music("rest")
	if _music_key.is_empty() or now<_music_next:return
	var k:=_rng.randi_range(0,Music.PHRASES-1)
	if k==_music_last:k=(k+1)%Music.PHRASES
	if not cached("music@"+_music_key,k) and not exact():
		if not cached("music@"+_music_key,0):return
		k=0
	_music_last=k
	var s:=stream_for("music@"+_music_key,k)
	var bright:=now<_music_bright_until
	var level:=MUSIC_DB+(2.0 if bright else 0.0)-(10.0 if now<_duck_until else 0.0)
	_music.stream=s
	_music.bus=pan_bus(_music_pan())
	_music.pitch_scale=1.06 if bright else 1.0
	if _music_tw!=null and _music_tw.is_valid():_music_tw.kill()
	var length:=s.get_length()/_music.pitch_scale
	if _music_tentative:
		_music_tentative=false
		_music.volume_db=level-9.0
		_music.play()
		var tw:=create_tween()
		tw.tween_interval(1.3)
		tw.tween_property(_music,"volume_db",-60.0,0.6)
		tw.tween_callback(_music.stop)
		_music_tw=tw
		_music_until=now+1.9
		_music_next=now+1.9+_rng.randf_range(2.0,3.5)
		played.append({"name":"music_tentative","at":now,"db":level-9.0,"pan":_music_pan()})
		_say_music("tentative")
		return
	_music.volume_db=level
	_music.play()
	_music_until=now+length
	_music_next=_music_until+_rng.randf_range(1.0,4.0)*(0.4 if bright else 1.0)
	played.append({"name":"music","at":now,"db":level,"pan":_music_pan()})
	_say_music("play")

func _say_music(state:String)->void:
	_music_said=state
	music_changed.emit(state)

## The musician's state now: {key, playing, tentative_next, bright, until}.
func music_state()->Dictionary:
	return {"key":_music_key,"playing":is_instance_valid(_music) and _music.playing and _now()<_music_until,
		"tentative_next":_music_tentative,"bright":_now()<_music_bright_until,"until":_music_until,"next":_music_next}

## The talkers' stream key: ours when made, else any tongue's already made.
func _talk_key()->String:
	if cached("talker@"+_tongue_key,Foley.MURMUR_VOICES.size()-1):return _tongue_key
	_lock.lock()
	var keys:=_cache.keys()
	_lock.unlock()
	for k in keys:
		var name:=String(k)
		if name.begins_with("talker@") and name.ends_with("|%d" % (Foley.MURMUR_VOICES.size()-1)):return name.get_slice("|",0).trim_prefix("talker@")
	return ""

## The crowd's talk, a tick at a time: the room's mood for talk drifts; each
## talker whose turn it is starts a run (murmur_run), or keeps quiet.
func _crowd_talk(now:float)->void:
	var key:=_talk_key()
	if key.is_empty():return
	if now>=_energy_at:
		_energy=_rng.randf_range(0.3,1.0);_energy_at=now+_rng.randf_range(6.0,16.0)
	var most:int=int(TALK_SLOTS.get(_talk_size,5))
	var live:=clampi(roundi(float(most)*_energy),1,most)
	for i in mini(most,_slots.size()):
		if now<_slot_free[i]:continue
		if i>=live:
			_slot_free[i]=now+_rng.randf_range(1.0,3.0);continue
		var run:=murmur_run(_rng,_energy)
		_slot_free[i]=now+float(run.length)/float(run.pitch)+float(run.gap)
		var level:=_talk_db+float(run.db)-(8.0 if now<_duck_until else 0.0)-(6.0 if now<_shy_until else 0.0)
		if bool(run.aside):
			var what:String=["laugh","hum_yes","sigh","cough","snort_laugh"][_rng.randi_range(0,4)]
			_play(stream_for(what,_rng.randi_range(0,Foley.variants(what)-1)),null,level-2.0,float(run.pitch),"talk_"+what,int(run.pan))
			continue
		var t:=_slots[i]
		t.stream=stream_for("talker@"+key,int(run.talker))
		t.bus=pan_bus(int(run.pan))
		t.pitch_scale=float(run.pitch)
		t.volume_db=level-30.0
		t.play(float(run.from))
		var old:Variant=_slot_tw[i]
		if old is Tween and (old as Tween).is_valid():(old as Tween).kill()
		var tw:=create_tween()
		tw.tween_property(t,"volume_db",level,0.25)
		tw.tween_interval(maxf(0.1,float(run.length)/float(run.pitch)-0.55))
		tw.tween_property(t,"volume_db",-50.0,0.3)
		tw.tween_callback(t.stop)
		_slot_tw[i]=tw

## One run of the crowd's talk: which of the six talks, from where in their
## talk, for how long, at what pitch (another person, near enough), at what
## level and from which side of the room, and the pause before that talker's
## next turn; now and then not words but a laugh, a hum, a cough (aside).
## energy: how talkative the room is now (0..1).
static func murmur_run(rng:RandomNumberGenerator,energy:float)->Dictionary:
	var length:=rng.randf_range(1.2,4.5)
	return {"talker":rng.randi_range(0,Foley.MURMUR_VOICES.size()-1),"from":rng.randf_range(0.0,Foley.TALKER_SECONDS-length-0.3),
		"length":length,"pitch":rng.randf_range(0.9,1.1),"db":rng.randf_range(-6.0,0.0),"pan":rng.randi_range(-3,3),
		"gap":rng.randf_range(0.2,2.2)/maxf(0.25,energy),"aside":rng.randf()<0.05}

## The crowd's talk over `seconds` as runs [{t, talker, from, length, pitch,
## db, pan, aside}], as the court plays it (offline renders and tests).
static func murmur_schedule(seed_value:int,seconds:float,size:="murmur",preroll:=8.0)->Array:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var most:int=int(TALK_SLOTS.get(size,5))
	var free:=PackedFloat32Array();free.resize(most)
	for i in most:free[i]=rng.randf_range(0.2,2.0)
	# a room waiting for its god talks a good deal at first
	var energy:=rng.randf_range(0.75,1.0);var energy_at:=-preroll+rng.randf_range(8.0,16.0)
	var out:Array=[]
	# the room was already talking before we came in
	var now:=-preroll
	for i in most:free[i]+=now
	while now<seconds:
		if now>=energy_at:energy=rng.randf_range(0.3,1.0);energy_at=now+rng.randf_range(6.0,16.0)
		var live:=clampi(roundi(float(most)*energy),1,most)
		for i in most:
			if now<free[i]:continue
			if i>=live:free[i]=now+rng.randf_range(1.0,3.0);continue
			var run:=murmur_run(rng,energy)
			run["t"]=now;run["slot"]=i
			free[i]=now+float(run.length)/float(run.pitch)+float(run.gap)
			var ends:=now+float(run.length)/float(run.pitch)
			if ends<=0.0:continue
			if now<0.0:
				# heard from the middle of what they were saying
				var cut:=-now*float(run.pitch)
				run["from"]=float(run.from)+cut;run["length"]=float(run.length)-cut;run["t"]=0.0
				if bool(run.aside):continue
			out.append(run)
		now+=0.1
	return out

func hushed()->bool:
	return _hushed

## The swell under the god's words, for their seconds and a breath after.
## tone: "wrath", "favour" or "" (awe).
func god(text:String,seconds:float,tone:="")->bool:
	hush(seconds+1.4)
	if not can_play():return false
	var wrath:=tone=="wrath"
	var favour:=tone in ["favour","favor"]
	var s:=stream_for("god_swell_wrath" if wrath else "god_swell_favour",0)
	var level:=-11.0 if wrath else (-14.0 if favour else -19.0)
	if _god_tween!=null and _god_tween.is_valid():_god_tween.kill()
	# a second line while the first still hums carries on the same swell
	if not (_god.playing and _god.stream==s):
		_god.stream=s;_god.volume_db=-40.0;_god.pitch_scale=1.0 if wrath or favour else 0.94
		_god.play()
	_god_tween=create_tween()
	_god_tween.tween_property(_god,"volume_db",level,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_god_tween.tween_interval(maxf(0.4,seconds+0.4))
	_god_tween.tween_property(_god,"volume_db",-60.0,2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_god_tween.tween_callback(_god.stop)
	played.append({"name":"god_swell_%s" % ("wrath" if wrath else ("favour" if favour else "awe")),"at":_now(),"db":level})
	return true

## A tenth of a second of the room's life: queued sounds, then the fire's
## pops and hisses, the birds, the hens, the goat, the beds still to start.
func _tick()->void:
	if not _tasks.is_empty():_collect()
	if keeps:
		if _tasks.is_empty():_timer.stop()
		return
	if not can_play():
		if _tasks.is_empty():_timer.stop()
		return
	var now:=_now()
	if _hushed and now>=_hush_until:_unhush()
	var i:=0
	while i<_queue.size():
		var item:Dictionary=_queue[i]
		if now>=float(item.at):
			_queue.remove_at(i)
			var opts:Dictionary=(item.opts as Dictionary).duplicate();opts.erase("delay")
			var body:Variant=item.body
			cue(String(item.name),body as Node3D if is_instance_valid(body) else null,opts)
		else:i+=1
	if not _open:
		if _queue.is_empty() and not _hushed and _tasks.is_empty():_timer.stop()
		return
	# beds made since the court opened
	for role:Array in _bed_list:
		var p:AudioStreamPlayer=_beds.get(String(role[0]),null)
		if (p==null or not p.playing) and cached(String(role[1]),0):_start_beds();break
	if _hushed:return
	_crowd_talk(now)
	_music_tick(now)
	_life("fire_pop",now,0.25,1.6,0.0)
	_life("fire_hiss",now,7.0,20.0,0.0)
	_life("log_settle",now,18.0,45.0,0.0)
	var open_air:=set_kind in OPEN_SETS
	if BIRD_SPANS.has(season):
		var span:Array=BIRD_SPANS[season]
		_life("bird",now,float(span[0]),float(span[1]),0.0 if open_air else -9.0)
	elif season=="winter":_life("crow",now,25.0,60.0,0.0 if open_air else -8.0)
	if bool(facts.get("fowl",false)):_life("hens",now,8.0,20.0,0.0)
	if bool(facts.get("herds",false)):_life("goat_chew",now,14.0,30.0,0.0)
	if season=="summer" and open_air:_life("fly_buzz",now,40.0,90.0,-2.0)

func _life(name:String,now:float,low:float,high:float,db:float)->void:
	var at:=float(_next.get(name,-1.0))
	if at<0.0:
		_next[name]=now+_rng.randf_range(low*0.3,high);return
	if now<at:return
	_next[name]=now+_rng.randf_range(low,high)
	var n:=Foley.variants(name)
	# the big pops are rarer
	var v:=_rng.randi_range(0,n-1)
	if name=="fire_pop" and v>=4 and _rng.randf()<0.6:v=_rng.randi_range(0,3)
	if not cached(name,v):
		if name in ["bird","crow","hens","fly_buzz","goat_chew"] and not sync_render:
			_track(warm([[name,v]]));return
	cue(name,null,{"variant":v,"db":db+_rng.randf_range(-3.0,1.5)})

# =============================================================================
# The stage's events and the director's beats
# =============================================================================

## A stage event (docs/COURT_STAGE_3D.md section 5).
func on_event(kind:String,data:Dictionary={})->void:
	match kind:
		"open":
			var f:Dictionary=stage.get("facts") if stage!=null and stage.get("facts") is Dictionary else {}
			ambience(String(data.get("set",f.get("set",_set_of(f)))),String(f.get("season","summer")),f)
		"line":
			var who:=String(data.get("who",""))
			var fig:=_figure(who)
			if fig==null:return
			var seconds:=float(data.get("talk_seconds",data.get("seconds",1.5)))
			voice(_body(fig),String(data.get("text","")),seconds,_mood_of(fig),"",{"person":_person(fig),"aside":bool(data.get("aside",false)),"kind":_kind_of(who)})
		"god":
			var tone:=String(data.get("tone",""))
			god(String(data.get("text","")),float(data.get("seconds",2.0)),tone)
		"divine":
			var action:=String(data.get("action",""))
			if action in WRATH:
				hush(3.0)
				# the wind rises a moment, as if the sky leaned in
				var wind:AudioStreamPlayer=_beds.get("wind",null)
				if wind!=null and wind.playing:
					var level:=float(_bed_db.get("wind",-26.0))
					var old:Tween=_bed_tweens.get("wind",null)
					if old!=null and old.is_valid():old.kill()
					var tw:=create_tween()
					tw.tween_property(wind,"volume_db",level+7.0,0.8).set_trans(Tween.TRANS_SINE)
					tw.tween_property(wind,"volume_db",level-3.0,2.4).set_trans(Tween.TRANS_SINE)
					_bed_tweens["wind"]=tw
				# the swell under it darkens to wrath
				god("",2.6,"wrath")
				# the musician stops dead first, as if they felt it coming; the
				# boom lands a beat after, in the gap (the squeak is not lost under it)
				var beat:=0.45 if is_instance_valid(_music) and _music_said=="stop_dead" and _now()-_hush_began<0.1 else 0.0
				cue("god_wrath_boom",null,{"db":0.0 if action in ["strike_down","cast_out","smite"] else -6.0,"delay":beat})
				if not action.begins_with("envoy_kill"):cue("room_gasp",null,{"delay":beat+0.35})
			elif action in FAVOUR:
				god("",2.0,"favour")
				# the musician picks up again at once, brighter
				_music_bright_until=_now()+25.0
				_music_tentative=false
				_music_next=minf(_music_next,_hush_until+_rng.randf_range(0.6,1.4))
				cue("hum_yes",null,{"db":-6.0,"delay":0.9})
		"enter":
			var fig:=_figure(String(data.get("who","")))
			if fig!=null:footsteps(_body(fig),1.6)
		"exit":
			var fig:=_figure(String(data.get("who","")))
			var style:=String(data.get("style","bow"))
			if fig==null:return
			match style:
				"storm":footsteps(_body(fig),1.6,2.6,true)
				"fall":cue("faint_thump",_body(fig),{"delay":0.3})
				"led":footsteps(_body(fig),2.2,1.6)
				_:footsteps(_body(fig),1.8,1.7)
		"decree":
			if not bool(data.get("accepted",true)):hush(1.6)
		"gift":
			if bool(data.get("accepted",true)) and not _music_key.is_empty():
				# a gift taken: the musician plays it in
				_queue.append({"at":_now()+0.5,"name":"musicfl@"+_music_key,"body":null,"opts":{"db":3.0}})
				_music_next=maxf(_music_next,_now()+4.0)
				_ensure_timer()
				_music_until=_now()+2.5
				_say_music("flourish")
		"close":
			_open=false
			for role in _beds:_fade(String(role),-80.0,0.8)
			if is_instance_valid(_god) and _god.playing:
				var tw:=create_tween();tw.tween_property(_god,"volume_db",-60.0,0.8);tw.tween_callback(_god.stop)

## One of the director's lowered beats as the stage plays it ({t, who, act,
## args}; args.beat names the act). Only the "play" primitive sounds (the
## mood and look of the same act are silent), the room's hush, and asides.
func on_beat(beat:Dictionary,body:Node3D=null)->void:
	var act:=String(beat.get("act",""))
	var args:Dictionary=beat.get("args",{}) if beat.get("args") is Dictionary else {}
	var who:=String(beat.get("who",""))
	match act:
		"hush":
			hush(float(args.get("dur",2.0)))
			return
		"room_gasp","murmur_up":
			# the room as one: its gasp, or its talk rising again
			if act=="room_gasp":cue("room_gasp",null,{"delay":float(args.get("delay",0.0))})
			else:hush(false)
			return
		"aside":
			var fig:=_figure(who)
			var text:=String(args.get("text",""))
			var heard:Dictionary=args.get("sound",{}) if args.get("sound") is Dictionary else {}
			if fig!=null and not text.is_empty():
				var db:=clampf(linear_to_db(maxf(0.05,float(heard.get("gain",0.6))))+2.0,-12.0,3.0) if not heard.is_empty() else 0.0
				voice(body if body!=null else _body(fig),text,clampf(text.length()*0.03,0.8,2.6),_mood_of(fig),String(heard.get("people","")),{"person":_person(fig),"whisper":true,"kind":_kind_of(who),"db":db})
			return
		"sound":
			sound(args,body if body!=null else _body_of(who),who)
			return
		"play":pass
		_:return
	var name:=String(args.get("beat",args.get("clip","")))
	# The director that names its sounds is the one who decides who is heard.
	if director_names_sounds() and not name in QUIET_ACTS:return
	sound_for_act(name,who,body if body!=null else _body_of(who),args)

## Whether the installed director lowers its own "sound" beats (court_director.gd SOUNDS).
static var _names_sounds:=-1
static func director_names_sounds()->bool:
	if _names_sounds<0:
		_names_sounds=0
		if ResourceLoader.exists("res://scripts/hud/court_director.gd"):
			var script:GDScript=load("res://scripts/hud/court_director.gd")
			if script!=null and script.get_script_constant_map().has("SOUNDS"):_names_sounds=1
	return _names_sounds==1

## The sound of one of the director's acts by `who` at `body`.
func sound_for_act(act:String,who:String,body:Node3D,args:Dictionary={})->bool:
	if WALK_ACTS.has(act):
		footsteps(body,float(WALK_ACTS[act]),2.6 if act in ["bolt","storm_off","hurry","hurry_after"] else 1.8,act=="storm_off")
		return true
	if not BEAT_CUES.has(act):return false
	var kind:=_kind_of(who)
	var animal:=kind in ["dog","goat"]
	if act in ANIMAL_ACTS and not animal:return false
	if act=="whimper" and kind=="goat":return false
	var spec:Array=BEAT_CUES[act]
	var name:=String(spec[0])
	if name.is_empty():return false
	# The dog barks only when it is a dog; the child's whimper is a child's.
	if act=="hide_behind" and kind=="child":name="whimper_child"
	var opts:={"db":float(spec[1]),"delay":float(spec[2])}
	# Voices of the room in their own register.
	if name in ["gasp","snort_laugh","laugh","cough","cough_fought","ahem","hmph","yawn","sigh","hum_yes","oof","strain","heave"]:
		opts["variant"]=_register_variant(name,who)
	return cue(name,body,opts)

## A variant of a voice-of-the-room sound that fits who makes it (gasp
## variants: 0 man, 1 woman, 2 child, 3 old).
func _register_variant(name:String,who:String)->int:
	var fig:=_figure(who)
	var person:=_person(fig) if fig!=null else {}
	var years:=int(person.get("age",35)) if (person.get("age",35) is int or person.get("age",35) is float) else 35
	var woman:=String(person.get("sex",""))=="female"
	var n:=Foley.variants(name)
	var v:=1 if woman else 0
	if years<13:v=2
	elif years>=60:v=3
	return mini(v,n-1)

# --- the animals ---------------------------------------------------------------

## What a beast's own clips sound like: [cue, dB, least seconds between]
## (court_animal_3d.gd plays them as it lives on the set; M's hook calls animal()).
const ANIMAL_SOUNDS:={
	"dog":{"bark":["dog_bark",0.0,0.0],"sniff":["dog_sniff",0.0,2.0],"scratch":["dog_scratch",0.0,3.0],"lie":["dog_flop",0.0,3.0],
		"cower":["dog_whimper",0.0,2.5],"tilt":["dog_query",0.0,3.0],"yawn":["dog_yawn",0.0,6.0],"shake":["dog_shake",0.0,6.0],
		"wag":["dog_thump",0.0,4.0],"grab":["snatch",-4.0,1.0],"walk":["paws",0.0,0.0],"trot":["paws",2.0,0.0]},
	"goat":{"bleat":["goat_bleat",0.0,2.0],"chew":["goat_chew",0.0,6.0],"graze":["goat_chew",-2.0,6.0],"eat":["goat_chew",-2.0,6.0]},
	"hen":{"peck":["hens",-3.0,6.0],"cluck":["hens",0.0,4.0],"idle":["hens",-6.0,10.0]},
}

## A beast on the set did something (one of its clips): it is heard, at its
## place, not too often. The tail thumps only when the dog is lying down; in
## the god's hush the beasts are quieter (a whimper is not).
func animal(species:String,clip:String,body:Node3D=null)->bool:
	var table:Dictionary=ANIMAL_SOUNDS.get(species,{})
	if not table.has(clip) or not can_play():return false
	var spec:Array=table[clip]
	var name:=String(spec[0])
	if clip=="wag" and body!=null and body.has_method("is_down") and not bool(body.call("is_down")):return false
	var now:=_now()
	var gap:=float(spec[2])
	if gap>0.0 and now-float(_animal_last.get(name,-99.0))<gap:return false
	_animal_last[name]=now
	var db:=float(spec[1])-(6.0 if _hushed and name!="dog_whimper" else 0.0)
	if name=="paws":
		var pace:=4.0 if clip=="trot" else 2.6
		footsteps(body,1.2,pace,false,"paws",db)
		return true
	return cue(name,body,{"db":db})

# --- reading the stage --------------------------------------------------------

## One of the crowd (an extra of the director's), or null.
func _someone_in_crowd()->Node3D:
	if stage==null:return null
	var extras:Variant=stage.get("extras")
	if not extras is Dictionary:return null
	var keys:Array=[]
	for key in extras:
		if String(((extras as Dictionary)[key] as Dictionary).get("role",""))=="crowd":keys.append(key)
	if keys.is_empty():return null
	return _body(_figure(String(keys[_rng.randi_range(0,keys.size()-1)])))

func _figure(who:String)->Object:
	if stage==null or who.is_empty() or not stage.has_method("figure"):return null
	return stage.call("figure",who)

## Where `who` stands: their figure, or the set's beast for an animal.
func _body_of(who:String)->Node3D:
	var b:=_body(_figure(who))
	if b!=null:return b
	var kind:=_kind_of(who)
	var court_set:Variant=stage.get("court_set") if stage!=null else null
	if kind in ["dog","goat","hen"] and court_set is Node3D and is_instance_valid(court_set) and (court_set as Node3D).has_method("animal"):
		var beast:Variant=(court_set as Node3D).call("animal",kind)
		if beast is Node3D and is_instance_valid(beast):return beast
	return null

func _body(fig:Object)->Node3D:
	if fig==null:return null
	var b:Variant=fig.get("body3d")
	return b as Node3D if b is Node3D and is_instance_valid(b) else null

func _person(fig:Object)->Dictionary:
	if fig==null:return {}
	var p:Variant=fig.get("person")
	return p if p is Dictionary else {}

func _mood_of(fig:Object)->String:
	if fig==null:return "neutral"
	var own:Variant=fig.get("own_mood")
	if own!=null and String(own)!="" and String(own)!="neutral":return String(own)
	var b:=_body(fig)
	if b!=null and b.get("mood")!=null:return String(b.get("mood"))
	return "neutral"

func _kind_of(who:String)->String:
	if stage==null:return ""
	var extras:Variant=stage.get("extras")
	if extras is Dictionary and (extras as Dictionary).has(who):return String(((extras as Dictionary)[who] as Dictionary).get("kind",""))
	if who in ["dog","goat"]:return who
	return ""

static func _set_of(f:Dictionary)->String:
	var tier:=int(f.get("era_tier",f.get("tier",0)))
	return ["fire_ring","longhouse","mudbrick_hall","grand_hall","grand_hall"][clampi(tier,0,4)]

# =============================================================================
# Offline: a scene mixed down to samples (review renders and tests)
# =============================================================================

## Mixes a little scene: items {t, cue | bed | voice | god, variant, db,
## until (a bed or swell stops, sharp, here), text, seconds, mood, spec,
## whisper}. Returns samples (22050 Hz mono), unnormalised, with the levels
## the game would use.
static func render_scene(items:Array,seconds:float)->PackedFloat32Array:
	var out:=Synth.buffer(seconds)
	for item:Dictionary in items:
		var at:=Synth.n_of(float(item.get("t",0.0)))
		var gain:=db_to_linear(float(item.get("db",0.0)))
		var samples:PackedFloat32Array
		if item.has("cue"):
			var name:=String(item.cue)
			samples=Synth.samples_of(stream_for(name,int(item.get("variant",0))))
			gain*=db_to_linear(Foley.level(name))
		elif item.has("bed") or item.has("god"):
			var name:=String(item.get("bed",item.get("god","")))
			var src:=stream_for(name,0)
			var looped:=Synth.samples_of(src)
			var until:=float(item.get("until",seconds))
			var count:=Synth.n_of(until)-at
			var head:=src.loop_begin
			var span:=maxi(1,looped.size()-head)
			samples=PackedFloat32Array();samples.resize(maxi(0,count))
			for i in samples.size():samples[i]=looped[i] if i<looped.size() else looped[head+(i-looped.size())%span]
			# the cut (a hush is sharp; a swell lets go slowly)
			var tail:=Synth.n_of(float(item.get("release",0.06)))
			var fade_in:=Synth.n_of(float(item.get("attack",0.5)))
			for i in mini(fade_in,samples.size()):samples[i]*=float(i)/float(fade_in)
			for i in mini(tail,samples.size()):samples[samples.size()-1-i]*=float(i)/float(tail)
			gain*=db_to_linear(Foley.level(name) if item.has("bed") else float(item.get("level",-14.0)))
		elif item.has("music"):
			# one of the musician's streams, cut off at `until` (a stop dead is sharp)
			var name:=String(item.music)
			var src:=Synth.samples_of(stream_for(name,int(item.get("variant",0))))
			var until:=float(item.get("until",float(at)/Synth.RATE+float(src.size())/Synth.RATE))
			var count:=mini(src.size(),Synth.n_of(until)-at)
			samples=src.slice(0,maxi(0,count))
			var tail:=Synth.n_of(float(item.get("release",0.0)))
			for i in mini(tail,samples.size()):samples[samples.size()-1-i]*=float(i)/float(maxi(1,tail))
			gain*=db_to_linear(MUSIC_DB)
		elif item.has("talk"):
			# the crowd's talk as the court plays it (murmur_schedule), in a tongue
			var key:=String(item.talk)
			var until:=float(item.get("until",seconds))
			var count:=Synth.n_of(until)-at
			samples=PackedFloat32Array();samples.resize(maxi(0,count))
			var size:=String(item.get("size","murmur"))
			var tracks:=_talkers(key)
			for run:Dictionary in murmur_schedule(int(item.get("seed",1)),until-float(item.get("t",0.0)),size):
				var piece:PackedFloat32Array
				if bool(run.aside):
					var what:String=["laugh","hum_yes","sigh","cough","snort_laugh"][int(run.talker)%5]
					piece=Synth.samples_of(stream_for(what,0))
					Synth.scale(piece,db_to_linear(-2.0+float(run.db)))
				else:
					var src:PackedFloat32Array=tracks[int(run.talker)]
					var n:=Synth.n_of(float(run.length))
					var start:=Synth.n_of(float(run.from))
					var pitch:=float(run.pitch)
					var outn:=int(float(n)/pitch)
					piece=PackedFloat32Array();piece.resize(outn)
					var fade:=Synth.n_of(0.25)
					for i in outn:
						var pos:=float(start)+float(i)*pitch
						var j:=int(pos);var f:=pos-j
						var v:=lerpf(src[mini(j,src.size()-1)],src[mini(j+1,src.size()-1)],f)
						piece[i]=v*minf(1.0,minf(float(i)/fade,float(outn-i)/fade))*db_to_linear(float(run.db))
				Synth.mix_into(samples,piece,Synth.n_of(float(run.t)),1.0)
			# the hush: the talk cut dead at `until` already; it may start late (attack)
			var fade_in:=Synth.n_of(float(item.get("attack",0.0)))
			for i in mini(fade_in,samples.size()):samples[i]*=float(i)/float(maxi(1,fade_in))
			var tail:=Synth.n_of(float(item.get("release",0.06)))
			for i in mini(tail,samples.size()):samples[samples.size()-1-i]*=float(i)/float(tail)
			gain*=db_to_linear(float(TALK_DB.get(size,-17.0)))
		elif item.has("voice"):
			samples=Voice.render_samples(item.spec,String(item.voice),float(item.get("seconds",2.0)),item.get("mood","neutral"),bool(item.get("whisper",false)))
			var top:=Synth.peak_of(samples)
			if top>0.0:Synth.scale(samples,0.62/top)
			gain*=db_to_linear(-13.0-(5.0 if bool(item.get("whisper",false)) else 0.0))
		Synth.mix_into(out,samples,at,gain)
	return out
