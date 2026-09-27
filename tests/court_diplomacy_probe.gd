extends Node
## Isolated captures of word abroad in the one court (1600x900):
## 1. a wrath ultimatum being composed to a revering people,
## 2. its answer in the conversation (awed compliance) with what is in motion,
## 3. the same threat to a proud, unafraid people (refusal),
## 4. a standing exchange ready to seal,
## 5. the pacts-and-leagues pane with the ruler's ties.
## Prints the offline exchanges and a mocked live one. Saves
## artifacts/court-*.png, checks the sheet fits, and exits.

const Messages:=preload("res://scripts/envoy_messages.gd")
const Court:=preload("res://scripts/hud/audience_modal.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
var valid:=true

func _snap(file:String)->void:
	for frame in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+file)

func _civ(civ_id:String)->Dictionary:
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==civ_id: return civ
	return {}

func _run(civ_id:String,choice:Dictionary,purpose:String)->Dictionary:
	var sent:=Messages.send(civ_id,purpose,choice)
	if sent.has("error"): print("SEND ERROR ",sent.error); valid=false; return {}
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	GameState.elapsed_days=int(mission.arrival_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	var menace:Dictionary=CivilizationSystem.diplomatic_mission.menace.duplicate(true)
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	return menace

func _print_thread(civ_id:String,title:String)->void:
	print("=== ",title)
	for line:Dictionary in ForeignDialogue.thread(civ_id).messages: print("  [",String(line.role),"] ",String(line.content))

func _ready()->void:
	DisplayServer.window_set_title("TEST CAPTURE · Court diplomacy · closes automatically")
	GameState.civic_api_enabled=false
	var revering:=preload("res://tests/diplomacy_fixture.gd").build_fixture()
	var proud:=String(CivilizationSystem.civilizations[2].id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	_civ(revering).player_relation.opinion=0.85
	ForeignDiplomacy.leader(revering)["trust"]=0.7
	ForeignDiplomacy.leader(revering)["audience_day"]=0
	ForeignDiplomacy.leader(proud)["audience_day"]=0
	var court:Control=Court.new();add_child(court)
	await get_tree().process_frame
	court.show_foreign(revering)
	court.compose.choose("ultimatum",{"by":"wrath","demand":"tribute","size":"heavy","consequence":"war","deadline":182,"token":"firebrand"})
	await _snap("court-compose-ultimatum.png")
	var view:=get_viewport().get_visible_rect()
	valid=valid and view.encloses(court.card.get_global_rect()) and view.encloses(court.compose.send_button.get_global_rect())
	print("FIT ",valid," ",court.card.get_global_rect()," ",view)
	print("REVERING FORECAST ",court.compose.reception.text)
	court._close()
	await get_tree().process_frame
	# The comply case: a revering people and the god's wrath.
	var menace:=_run(revering,{"by":"wrath","demand":"tribute","size":"heavy","consequence":"war","deadline":182,"token":"firebrand"},"ultimatum")
	_print_thread(revering,"REVERING (offline) answer=%s mood=%s" % [String(menace.result.answer),String(menace.result.mood)])
	court=Court.new();add_child(court)
	await get_tree().process_frame
	court.show_foreign(revering)
	await _snap("court-answer-revering.png")
	court._close()
	# The refuse case: a proud, unafraid people.
	_civ(proud).player_relation.opinion=-0.6
	ForeignDiplomacy.leader(proud)["trust"]=-0.4
	Rivals.grudge(proud,"the hunters you turned back at the ford",1.0,"probe")
	print("PROUD FORECAST ",Messages.forecast(proud,Messages.priced(proud,Messages.build("ultimatum",{"by":"wrath","demand":"tribute","size":"heavy","consequence":"war"}))))
	var refused:=_run(proud,{"by":"wrath","demand":"tribute","size":"heavy","consequence":"war","deadline":182},"ultimatum")
	_print_thread(proud,"PROUD (offline) answer=%s mood=%s" % [String(refused.result.answer),String(refused.result.mood)])
	court=Court.new();add_child(court)
	await get_tree().process_frame
	court.show_foreign(proud)
	await _snap("court-answer-proud.png")
	# A mocked live voice for the same refusal: validated or refused.
	var mock:={"envoy_words":"I stood in front of their elders and told them you are angry, and what you want of their stores before the second season ends.","reply":"You want our food because you are angry? We have no quarrel with you that food would mend. Go home and tell your god my fighters know the way to your fires as well as yours know ours."}
	var record:Dictionary=Messages.find_mission(proud,int(CivilizationSystem.diplomatic_history[0].depart_day))
	var copy:=record.duplicate(true);copy.menace.result["told"]=false
	print("MOCK LIVE accepted=",Messages.accept_voice(copy,mock)," reply=",mock.reply)
	print("MOCK LIVE PROMPT ",String(Messages.voice_messages(proud,copy.menace)[0].content).substr(0,400))
	print("MOCK LIVE FACTS ",String(Messages.voice_messages(proud,copy.menace)[1].content))
	# A standing exchange on the table, ready to seal (a mocked round trip).
	var trader:=String(CivilizationSystem.civilizations[1].id)
	ForeignDiplomacy.leader(trader)["audience_day"]=0
	var carried:={"player_gives":"Food","player_amount":100,"foreign_gives":"Timber","foreign_amount":10,"cadence":"year","portions":10,"when_ready":true,"carry_debt":false}
	ForeignDialogue.ask(trader,"Offer them a hundred rations a year for ten timber, each paid when the timber comes, for ten years.")
	ForeignDialogue.pending.clear()
	var t:Dictionary=ForeignDialogue.thread(trader)
	t.staged_result={"envoy_words":"I offered them a hundred rations a year for ten timber, paid as each load arrives, for ten years.","reply":"A hundred rations a year for ten timber, each paid when the timber arrives, for ten years. I agree to that.",
		"accord":"","tone":"equals","generous":false,"reaction":"unchanged","commitment":{},"envoy_terms":carried.duplicate(),"exchange":carried.merged({"stance":"accept"})}
	t.retryable=false
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	court.show_foreign(trader)
	court.compose.choose("leader_parley")
	await _snap("court-trade-seal.png")
	var seal:=court.find_child("SealExchange",true,false) as Button
	print("SEAL visible=",seal.visible," disabled=",seal.disabled," words=",(court.find_child("ExchangeWords",true,false) as Label).text)
	# Pacts and leagues, with the ruler's ties.
	court.show_foreign(revering)
	court.show_foreign_view("pacts")
	await _snap("court-pacts.png")
	print("PACTS ",court.find_child("LeagueTerms",true,false)!=null," ",court.find_child("Ties",true,false)!=null)
	valid=valid and court.find_child("LeagueTerms",true,false)!=null and court.find_child("Ties",true,false)!=null
	print("COURT_DIPLOMACY ","PASS" if valid else "FAIL")
	get_tree().quit(0 if valid else 1)
