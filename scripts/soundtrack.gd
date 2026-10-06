extends Node
## THE SOUNDTRACK: music by the mood of the game.
##
## Each mood has its own folder of pieces under assets/audio/score/<mood>/;
## dropping a piece into the folder adds it. A piece named "y500_..." plays
## only from game year 500 on, "y1-200_..." only in years 1 to 200 (years);
## a piece with no years plays in every age. Pieces in the "any" folder
## belong to every mood. The mood is read from the world
## every few seconds (mood_now): calm peacetime while our people know of no
## other people, contact once another people has been met and all is at
## peace, war while the people are at war or a fight, a siege or a coming
## war band is on them. A
## piece of the present mood starts, then the next one GAP_MIN to GAP_MAX
## seconds of real time after it began (silence between when the piece is
## shorter; a longer piece plays to its end and the next follows it), never the same piece twice running when the mood has others.
## When the mood turns, the piece playing fades out over FADE seconds and one
## of the new mood begins. A mood with no pieces yet is silent.
## Real time, not the world's days: speed and pause change nothing. Plays on
## the Music bus through the scene's "Score" player (display_preferences.gd).

const SCORE_DIR:="res://assets/audio/score/"
const MOODS:=["calm","contact","war"]
const DEFAULT_MOOD:="calm"
## The folder whose pieces join every mood's.
const ANY_MOOD:="any"
## Seconds from the start of one piece to the start of the next.
const GAP_MIN:=300.0
const GAP_MAX:=300.0
## How often the mood is read, and how long a piece takes to fade when it turns.
const MOOD_CHECK:=5.0
const FADE:=4.0
const VOLUME_DB:=-6.0

var player:AudioStreamPlayer
var mood:=DEFAULT_MOOD
var last_piece:=""
var _next_cue:=0.0
var _next_check:=0.0
var _fading:=false
var _rng:=RandomNumberGenerator.new()

func _ready()->void:
	name="Soundtrack"
	process_mode=Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	player=get_parent().get_node_or_null("Score") as AudioStreamPlayer
	if player==null:return
	player.volume_db=VOLUME_DB
	mood=mood_now()
	play_next()

func _process(_delta:float)->void:
	if player==null or _fading:return
	var now:=_seconds()
	if now>=_next_check:
		_next_check=now+MOOD_CHECK
		var wanted:=mood_now()
		if wanted!=mood:
			mood=wanted
			_turn()
			return
	if now>=_next_cue and not player.playing:play_next()

## The pieces of one mood: every .mp3, .ogg or .wav in its folder.
static func pieces(of_mood:String)->PackedStringArray:
	var out:PackedStringArray=[]
	var dir:=SCORE_DIR+of_mood+"/"
	var names:PackedStringArray=ResourceLoader.list_directory(dir) if ResourceLoader.has_method("list_directory") else DirAccess.get_files_at(dir)
	for file:String in names:
		var plain:=file.trim_suffix(".import").trim_suffix(".remap")
		if plain.get_extension().to_lower() in ["mp3","ogg","wav"] and not out.has(dir+plain):out.append(dir+plain)
	out.sort()
	return out

## The game years a piece plays in, from its file name: "y500_..." from
## year 500 on, "y1-200_..." in years 1 to 200; a name with no years plays in
## every year. [first, last] (last 0: no end).
static func years(piece:String)->Array:
	var found:=RegEx.create_from_string("^y(\\d\\d*)(?:-(\\d\\d*))?_").search(piece.get_file())
	if found==null:return [0,0]
	return [int(found.get_string(1)),int(found.get_string(2)) if found.get_string(2)!="" else 0]

static func from_year(piece:String)->int:
	return int(years(piece)[0])

## The pieces of a mood that belong to the game year `year`.
static func pieces_for_year(of_mood:String,year:int)->PackedStringArray:
	var out:PackedStringArray=[]
	var every:=pieces(of_mood)
	if of_mood!=ANY_MOOD:every.append_array(pieces(ANY_MOOD))
	for piece:String in every:
		var span:=years(piece)
		if int(span[0])<=year and (int(span[1])==0 or year<=int(span[1])):out.append(piece)
	return out

## The game's mood now, from the one world: war while our people are at war
## or a fight, a siege or a war band coming is on them; contact once another
## people has been met; calm before that.
static func mood_now()->String:
	if Engine.get_main_loop()==null:return DEFAULT_MOOD
	var military:=(Engine.get_main_loop() as SceneTree).root.get_node_or_null("MilitaryCampaign")
	if military!=null:
		for key:String in ["active_engagement","active_siege","active_threat"]:
			var value:Variant=military.get(key)
			if value is Dictionary and not (value as Dictionary).is_empty():return "war"
	var world:Variant=WorldSimulation.world if WorldSimulation!=null else null
	if world!=null and world.has_method("player_effects"):
		if int((world.call("player_effects") as Dictionary).get("war_count",0))>0:return "war"
	if met_another_people():return "contact"
	return DEFAULT_MOOD

## Whether our people have met another people (first contact made).
static func met_another_people()->bool:
	for civ:Variant in CivilizationSystem.civilizations:
		if not civ is Dictionary or String((civ as Dictionary).get("id",""))=="player":continue
		var relation:Variant=(civ as Dictionary).get("player_relation",{})
		if relation is Dictionary and int((relation as Dictionary).get("contact_level",0))>=1:return true
	return false

## The next piece of a mood: never the one just played when there are others.
static func choose(list:PackedStringArray,last:String,roll:float)->String:
	if list.is_empty():return ""
	var choices:=Array(list)
	if choices.size()>1:choices.erase(last)
	return String(choices[mini(choices.size()-1,floori(roll*choices.size()))])

func play_next()->void:
	var piece:=choose(pieces_for_year(mood,int(GameState.elapsed_days)/365+1),last_piece,_rng.randf())
	_next_cue=_seconds()+_rng.randf_range(GAP_MIN,GAP_MAX)
	if piece=="":return
	var stream:=load(piece) as AudioStream
	if stream==null:return
	last_piece=piece
	player.stream=stream
	player.volume_db=VOLUME_DB
	player.play()

## The mood turned: fade what is playing and begin the new mood's music.
func _turn()->void:
	if not player.playing:
		play_next()
		return
	_fading=true
	var fade:=create_tween()
	fade.tween_property(player,"volume_db",-40.0,FADE)
	fade.finished.connect(func()->void:
		player.stop()
		_fading=false
		play_next())

func _seconds()->float:
	return Time.get_ticks_msec()/1000.0
