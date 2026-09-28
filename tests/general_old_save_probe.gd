extends Node
## An older save loads into the current game: the general campaign stays
## closed, the date, people and research are the save's, the fields newer
## releases added start from safe defaults, and the world goes on a day.
##
## With the private fixture (an override.cfg user directory named
## TomorrowAndTomorrow_GeneralCampaign_Test holding
## saves/pre_general_release.save, a save from before the general-led
## campaign) the probe loads that. Without it, the probe writes an older save
## from a fresh world into a temporary slot (legacy_save_fixture.gd) and loads
## that. It never needs the player's saves.
##
## Every check reports, and the probe always quits: exit 0 with
## GENERAL_OLD_SAVE_PASS, or exit 1 with GENERAL_OLD_SAVE_FAIL. (It used to
## assert the private directory; a failed assert stopped the script and left
## the process running.)

const FIXTURE_DIR:="TomorrowAndTomorrow_GeneralCampaign_Test"
const FIXTURE_SLOT:="pre_general_release"
const Legacy:=preload("res://tests/legacy_save_fixture.gd")
const DAY:=preload("res://scripts/civilization_day.gd")
## What the older save made here must have lost, or the load proves nothing.
const MUST_REMOVE:=["curated_GeneralCampaign","reflected_GeneralDialogue","player MilitaryCampaign.engagements","player MilitaryCampaign.joint_operations.raiding","player CivilizationSystem.formation_memory","player ConsequenceEngine._home_intake_today"]
var failures:Array[String]=[]
var finished:=false


func _ready()->void:
	# A script error part way would stop _ready with the process still
	# running; the watchdog still ends it.
	get_tree().create_timer(240.0).timeout.connect(func()->void:
		_expect(false,"timed out")
		_finish(""))
	var fixture:=OS.get_user_data_dir().ends_with(FIXTURE_DIR) and FileAccess.file_exists(SaveSystem.slot_path(FIXTURE_SLOT))
	var slot:=FIXTURE_SLOT if fixture else "general_old_save_probe_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	if fixture:print("GENERAL_OLD_SAVE using the private fixture ",SaveSystem.slot_path(FIXTURE_SLOT))
	else:
		_new_world()
		var made:=Legacy.write(slot)
		_expect(not made.has("error"),"could not write the older save: %s" % str(made))
		if made.has("error"):
			_finish(slot)
			return
		for item:String in MUST_REMOVE:
			_expect(item in made.removed,"the older save still holds %s (a renamed field needs legacy_save_fixture.gd updated)" % item)
	var before:=SaveSystem.save_metadata(slot)
	_expect(not before.is_empty(),"the older save has no readable date and people")
	var saved_state:Dictionary=SaveSystem._read_payload(slot).get("reflected_GameState",{})
	# The live game has a general campaign open and state of its own that the
	# older save does not have; none of it may survive the load.
	GeneralCampaign.active=true
	CivilizationSystem.formation_memory["probe:stale"]={"day":1}
	ConsequenceEngine._home_intake_today=0.25
	var result:=SaveSystem.load_game(slot)
	_expect(result.has("ok"),"the older save did not load: %s" % str(result))
	if result.has("ok"):
		_expect(not GeneralCampaign.active,"the general campaign stayed open after loading an older save")
		_expect(int(GameState.elapsed_days)==int(before.get("elapsed_days",-1)),"date not restored (%d, saved %s)" % [int(GameState.elapsed_days),str(before.get("elapsed_days"))])
		_expect(GameState.population_total==int(before.get("population",-1)),"people not restored (%d, saved %s)" % [GameState.population_total,str(before.get("population"))])
		_expect(Array(GameState.known_discoveries)==Array(saved_state.get("known_discoveries",[])),"research not restored")
		_expect(not CivilizationSystem.formation_memory.has("probe:stale"),"the live game's battle memory leaked into the older save")
		if not fixture:
			var joint:Dictionary=MilitaryCampaign.joint_operations.state
			var newer:={"raiding":joint.get("raiding"),"raids_out":joint.get("raids_out"),"war_ledger":joint.get("war_ledger"),"wounded":joint.get("wounded"),"captured_holding":joint.get("captured_holding")}
			_expect(newer=={"raiding":{},"raids_out":{},"war_ledger":{},"wounded":[],"captured_holding":0},"the air and sea war's newer fields did not start empty: %s" % str(newer))
			_expect(MilitaryCampaign.own_engagements.is_empty() and MilitaryCampaign.active_engagement.is_empty(),"battles appeared from nowhere")
			_expect(is_equal_approx(ConsequenceEngine._home_intake_today,1.0),"the live game's rations leaked into the older save")
		# The world goes on a day from the older save.
		var day:=int(GameState.elapsed_days)+1
		WorldSimulation.advance_day(day,DAY.context(CivilizationSystem.player_world_origin))
		_expect(int(GameState.elapsed_days)==day,"the older save's world did not go on a day (%d)" % int(GameState.elapsed_days))
		if failures.is_empty():print("GENERAL_OLD_SAVE ",String(result.get("message","")))
	_finish("" if fixture else slot)


## A fresh world with two other peoples, two days on.
func _new_world()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(5151)
	MilitaryCampaign.reset_for_new_world()
	GameState.opponent_count=2
	CivilizationSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	for day in range(1,3):WorldSimulation.advance_day(day,DAY.context(Vector2.ZERO))


func _expect(condition:bool,message:String)->void:
	if condition:return
	failures.append(message)
	push_error("GENERAL_OLD_SAVE "+message)


func _finish(slot:String)->void:
	if finished:return
	finished=true
	if slot!="":DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	if failures.is_empty():
		print("GENERAL_OLD_SAVE_PASS")
		get_tree().quit(0)
	else:
		print("GENERAL_OLD_SAVE_FAIL (%d)" % failures.size())
		get_tree().quit(1)
