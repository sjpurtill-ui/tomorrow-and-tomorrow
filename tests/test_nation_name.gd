extends GdUnitTestSuite
## OUR NATION'S NAME (nation_name.gd, hud/nation_name_card.gd, the court's
## court_realm_acts.nation). A people of one town goes by that town. With a
## second town the ruler may name the nation: at that founding (skipping asks
## again only at the next founding), on the Government screen, or in the
## court. The name is saved; an older save loads unnamed and reads as before.
## Foreign peoples, envoys, the Chronicle and the Standing board use it; the
## home town's own uses stay the town. Offline; never calls a real API.

const NationName:=preload("res://scripts/nation_name.gd")
const Card:=preload("res://scripts/hud/nation_name_card.gd")
const Realm:=preload("res://scripts/court_realm_acts.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Envoys:=preload("res://scripts/envoy_messages.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Answers:=preload("res://scripts/court_answers.gd")
const StandingDock:=preload("res://scripts/hud/content/dock_content_standing.gd")
const GovernmentDock:=preload("res://scripts/hud/content/dock_content_government.gd")
const ChronicleDock:=preload("res://scripts/hud/content/dock_content_chronicle.gd")

class Hud extends Control:
	var refreshes:=0
	func request_immediate_dock_refresh()->void:refreshes+=1

var slot:=""
var fx:Fixtures
var _processing:Dictionary={}


func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)


func before_test()->void:
	slot="nation_name_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	# Seanstone, its court (Kishan the headman, Suri, Kavu, Imeri), the Esurai;
	# second_town() founds another town of ours as a caravan's arrival does.
	fx=Fixtures.new(self)
	fx.base(false)


func after_test()->void:
	if slot!="": DirAccess.remove_absolute(SaveSystem.slot_path(slot))


func after()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))
	preload("res://scripts/ai_mode.gd").reset_for_tests(preload("res://scripts/ai_mode.gd").SETTINGS_PATH)


## The Chronicle's lines about our nation's name, newest first.
func _told()->Array:
	var out:Array=[]
	for e in preload("res://scripts/chronicle.gd").data().entries:
		if String((e as Dictionary).get("key","")).begins_with("nation_name:"): out.append(e)
	return out


func _chips(column:Node)->Array:
	var row:=column.find_child("NationNameSuggestions",true,false)
	if row==null: return []
	return row.get_children().filter(func(n:Node)->bool: return n is Button)


func _speak(text:String)->Dictionary:
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	var id:=String(Hall.summon({"person_id":int(steward.person_id)}).get("id",""))
	assert_str(id).override_failure_message("nobody came to the court").is_not_empty()
	var card:=Tracker.register(Tracker.court_title(text),"court",text,String(steward.name))
	var heard:=CC.hear(id,text)
	Tracker.from_court(card,heard)
	heard["card"]=Tracker.find(card)
	return heard


func test_one_town_reads_as_the_town_and_cannot_be_named_yet()->void:
	assert_int(NationName.towns()).is_equal(1)
	assert_str(GameState.nation_name).is_equal("")
	assert_bool(NationName.can_name()).is_false()
	assert_bool(NationName.ask_at_founding()).is_false()
	# Everything reads as before: the people go by the first town.
	assert_str(CivilizationSystem._player_civilization_name()).is_equal("SEANSTONE")
	assert_str(StandingDock.new(null,null)._our_name()).is_equal("The people of Seanstone")
	assert_str(Envoys._god()).is_equal("the god of Seanstone")
	assert_str(String(ChronicleDock.new(null,null).meta().eyebrow)).is_equal("THE STORY OF THE PEOPLE")
	assert_str(String(CommunityNetwork.nodes()[0].name)).is_equal("Seanstone")
	assert_bool(Facts.sheet(["common"]).has("nation")).is_false()
	# The Government screen has no nation line, and nothing can name it.
	assert_str(String(GovernmentDock.new(null,null).tab(0).blocks[0].type)).is_equal("cabinet")
	var refused:=NationName.give_name("The Reedfolk","screen")
	assert_bool(bool(refused.ok)).is_false()
	assert_str(String(refused.why)).is_equal("one_town")
	assert_str(GameState.nation_name).is_equal("")
	assert_array(_told()).is_empty()


func test_the_second_founding_asks_and_its_card_names_the_nation()->void:
	fx.second_town("Reedmouth")
	assert_int(NationName.towns()).is_equal(2)
	assert_bool(NationName.ask_at_founding()).is_true()
	# The founding card: the heading, "And our nation", and names heard among
	# the people, each one invented and short enough for a herald.
	var column:VBoxContainer=auto_free(VBoxContainer.new())
	add_child(column)
	Card.founding_heading(column,"Reedmouth")
	var input:=Card.add_field(column)
	assert_str(input.text).is_equal("")
	var heard:=NationName.suggestions(4)
	assert_int(heard.size()).is_greater_equal(3)
	for name in heard:
		assert_int(name.length()).is_less_equal(NationName.MAX_LENGTH)
		assert_bool(name.to_lower().contains("esurai") or name.to_lower().contains("varesh")).is_false()
	assert_bool(heard.has("The Folk of Seanstone")).override_failure_message(str(heard)).is_true()
	var chips:=_chips(column)
	assert_int(chips.size()).is_equal(heard.size())
	(chips[0] as Button).pressed.emit()
	assert_str(input.text).is_equal(heard[0])
	var done:=Card.commit_founding(input,"Reedmouth")
	assert_bool(bool(done.ok)).override_failure_message(str(done)).is_true()
	assert_str(GameState.nation_name).is_equal(heard[0])
	assert_str(String(done.line)).is_equal("Our people are now called %s." % NationName.in_sentence(heard[0]))
	assert_bool(NationName.ask_at_founding()).is_false()
	# Told once in the Chronicle, in plain words, with the town just founded.
	var told:=_told()
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].title)).is_equal("A Name for Our People: %s" % heard[0])
	assert_str(String(told[0].text)).contains("Reedmouth")
	assert_str(String(told[0].text)).contains(NationName.in_sentence(heard[0]))
	# A third founding does not ask again.
	fx.second_town("Ashbank")
	assert_bool(NationName.ask_at_founding()).is_false()


func test_skipping_names_nothing_and_only_the_next_founding_asks_again()->void:
	fx.second_town("Reedmouth")
	var inbox:=GameState.council_inbox.size()
	var column:VBoxContainer=auto_free(VBoxContainer.new())
	add_child(column)
	var input:=Card.add_field(column)
	# The line left empty: nothing is named, nothing is told, nobody is asked.
	assert_dict(Card.commit_founding(input,"Reedmouth")).is_empty()
	assert_str(GameState.nation_name).is_equal("")
	assert_array(_told()).is_empty()
	assert_int(GameState.council_inbox.size()).is_equal(inbox)
	# Between foundings the Government screen only offers it, quietly.
	var page:=GovernmentDock.new(null,null).tab(0)
	assert_str(String(page.blocks[0].type)).is_equal("rows")
	assert_str(String(page.blocks[0].items[0].name)).is_equal("Our nation: not yet named")
	assert_str(String(page.blocks[0].items[0].value)).is_equal("Name it")
	assert_str(String(page.blocks[1].type)).is_equal("cabinet")
	# The next founding asks again.
	fx.second_town("Ashbank")
	assert_bool(NationName.ask_at_founding()).is_true()


func test_the_government_screen_renames_the_nation()->void:
	fx.second_town("Reedmouth")
	assert_bool(bool(NationName.give_name("the reedfolk","screen").ok)).is_true()
	assert_str(GameState.nation_name).is_equal("The Reedfolk")
	var hud:Hud=auto_free(Hud.new())
	add_child(hud)
	# The dock keeps its provider while the screen is open.
	var provider=GovernmentDock.new(null,hud)
	var page:Dictionary=provider.tab(0)
	var row:Dictionary=page.blocks[0].items[0]
	assert_str(String(row.name)).is_equal("Our nation: The Reedfolk")
	assert_str(String(row.value)).is_equal("Rename")
	# One click opens the small card; the name given there is the nation's.
	(row.on_click as Callable).call()
	var card:=hud.find_child("NationNameCard",true,false)
	assert_object(card).is_not_null()
	var input:LineEdit=card.find_child("NationName",true,false)
	assert_str(input.text).is_equal("The Reedfolk")
	var confirm:Button=card.find_child("NationNameConfirm",true,false)
	# Another people's name is refused on the card, and nothing changes.
	input.text="the Esurai"
	input.text_changed.emit(input.text)
	confirm.pressed.emit()
	assert_str(GameState.nation_name).is_equal("The Reedfolk")
	assert_str((card.find_child("NationNameStatus",true,false) as Label).text).contains("another people")
	input.text="ashfolk"
	input.text_changed.emit(input.text)
	confirm.pressed.emit()
	assert_str(GameState.nation_name).is_equal("Ashfolk")
	assert_int(hud.refreshes).is_equal(1)
	assert_bool(card.is_queued_for_deletion()).is_true()
	var told:=_told()
	assert_int(told.size()).is_equal(2)
	assert_str(String(told[0].title)).is_equal("A New Name for Our People: Ashfolk")
	assert_str(String(told[0].text)).is_equal("By the god's word, the Reedfolk are called Ashfolk from this day.")


func test_the_court_line_names_the_nation_and_the_order_card_is_done()->void:
	# The words that name all our towns together, and look-alikes that do not.
	for said in ["Call our nation the Reedfolk","call our people the reedfolk","Our people shall be called the Reedfolk","name our realm the Reedfolk",
			"From now on we shall be known as the Reedfolk","Let our nation be called the Reedfolk.","the name of our nation is the Reedfolk",
			"rename our nation to the Reedfolk","Kishan, call our nation the Reedfolk","Our people will be known as the Reedfolk from this day"]:
		assert_str(String(Realm.nation(said).get("name",""))).override_failure_message("'%s' did not name the nation" % said).is_equal("The Reedfolk")
	for said in ["call our people to the fire","Call our people home","our people are hungry","Rename Seanstone to Godshold","Call our town Godshold",
			"What is our nation called?","name the people who stole the grain","call the people together","Kill Kavu, call our nation the Reedfolk"]:
		assert_dict(Realm.nation(said)).override_failure_message("'%s' was read as naming the nation" % said).is_empty()
	# One town: the headman says plainly the people go by it; nothing changes.
	var early:=_speak("Call our nation the Reedfolk")
	assert_bool(bool(early.handled)).is_true()
	assert_str(String(early.verb)).is_equal("nation_name")
	assert_bool(bool(early.executed)).is_false()
	assert_str(String(early.actor_says)).contains("Seanstone")
	assert_str(String(early.outcome)).starts_with("Nothing is changed")
	assert_str(String(early.card.state)).is_equal("nothing")
	assert_str(GameState.nation_name).is_equal("")
	# Two towns: named, the headman answers in his own words, the card is done.
	fx.second_town("Reedmouth")
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	var r:=_speak("Our people shall be called the Reedfolk")
	assert_bool(bool(r.handled)).is_true()
	assert_str(String(r.verb)).is_equal("nation_name")
	assert_bool(bool(r.executed)).is_true()
	assert_str(String(r.actor_name)).is_equal(String(steward.name))
	# In their own manner (their disposition), always the name and the word sent out.
	var firsts:=Realm.NATION_ANSWERS.values().map(func(pair:Array)->String: return String(pair[0]).replace("{Name}","The Reedfolk").replace("{name}","the Reedfolk").replace("{towns}","Seanstone and Reedmouth"))
	assert_bool(firsts.has(String(r.actor_says))).override_failure_message(String(r.actor_says)).is_true()
	assert_str(String(r.outcome)).contains("our people are called the Reedfolk")
	assert_str(String(r.card.state)).is_equal("done")
	assert_str(GameState.nation_name).is_equal("The Reedfolk")
	assert_int(_told().size()).is_equal(1)
	# Officials answer from the fact sheet: what we are called.
	var sheet:=Facts.sheet(["common"])
	assert_str(String(sheet.get("nation",""))).is_equal("The Reedfolk")
	assert_str(Answers._common_answer(sheet,"what is our nation called?")).is_equal("We are the Reedfolk.")
	# A new name, and the same name again.
	var again:=_speak("name our realm Ashmark")
	assert_bool(bool(again.executed)).is_true()
	assert_str(String(again.actor_says)).contains("Ashmark")
	assert_str(String(again.actor_says)).contains("Seanstone and Reedmouth")
	# Every manner answers both a first name and a new one, the facts kept.
	for pair:Array in Realm.NATION_ANSWERS.values():
		assert_int(pair.size()).is_equal(2)
		for template:String in pair: assert_bool(template.contains("{towns}") and (template.contains("{name}") or template.contains("{Name}"))).override_failure_message(template).is_true()
	var same:=_speak("call our nation Ashmark")
	assert_bool(bool(same.executed)).is_false()
	assert_str(String(same.card.state)).is_equal("nothing")
	assert_str(GameState.nation_name).is_equal("Ashmark")
	assert_int(_told().size()).is_equal(2)


func test_the_save_keeps_the_name_and_an_older_save_loads_unnamed()->void:
	fx.second_town("Reedmouth")
	assert_bool(bool(NationName.give_name("The Reedfolk","court").ok)).is_true()
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.has("error")).override_failure_message(str(saved)).is_false()
	GameState.nation_name="Somebody Else"
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	assert_str(GameState.nation_name).is_equal("The Reedfolk")
	assert_int(NationName.towns()).is_equal(2)
	# A save from before nations had names: the field is absent.
	var payload:=SaveSystem._read_payload(slot)
	assert_bool((payload.reflected_GameState as Dictionary).erase("nation_name")).is_true()
	assert_bool(SaveSystem._write_payload(SaveSystem.slot_path(slot),payload).has("error")).is_false()
	var older:=SaveSystem.load_game(slot)
	assert_bool(older.has("error")).override_failure_message(str(older)).is_false()
	assert_str(GameState.nation_name).is_equal("")
	# ...and reads as before: the people go by the first town, and the next
	# founding (two towns, no name) will ask.
	assert_str(CivilizationSystem._player_civilization_name()).is_equal("SEANSTONE")
	assert_str(NationName.people_title()).is_equal("The people of Seanstone")
	assert_bool(NationName.ask_at_founding()).is_true()


func test_foreign_and_chronicle_uses_show_the_name()->void:
	fx.second_town("Reedmouth")
	NationName.give_name("The Reedfolk","court")
	var civ_id:=String(CivilizationSystem.civilizations[0].id)
	# The world's name for us: wars, the competition row, the battle markers.
	assert_str(CivilizationSystem._player_civilization_name()).is_equal("The Reedfolk")
	assert_str(CivilizationSystem._participant_name("player")).is_equal("The Reedfolk")
	assert_str(CivilizationSystem._war_name("player",civ_id,"",int(GameState.elapsed_days))).starts_with("The Reedfolk–Esurai")
	var ours:Dictionary={}
	for row:Dictionary in CivilizationSystem.competition_snapshot().leaders:
		if String(row.id)=="player": ours=row
	assert_str(String(ours.get("name",""))).is_equal("The Reedfolk")
	# How envoys and foreign rulers name us.
	assert_str(Envoys._god()).is_equal("the god of the Reedfolk")
	var known:=ForeignDialogue.known_context(civ_id)
	if not known.is_empty(): assert_str(String(known.get("player_people",""))).is_equal("The Reedfolk")
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	var audience:=String(Hall.summon({"person_id":int(steward.person_id)}).get("id",""))
	assert_str(String(Hall.voice_context(audience).get("player_people",""))).is_equal("The Reedfolk")
	# The Chronicle, the Standing board and the peoples' network.
	assert_str(String(ChronicleDock.new(null,null).meta().eyebrow)).is_equal("THE STORY OF THE REEDFOLK")
	assert_str(StandingDock.new(null,null)._our_name()).is_equal("The Reedfolk")
	assert_str(String(CommunityNetwork.nodes()[0].name)).is_equal("The Reedfolk")
	var told:=_told()
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].text)).is_equal("By the god's word, the people of Seanstone and Reedmouth are called the Reedfolk from this day.")


func test_the_home_towns_own_uses_stay_the_town()->void:
	fx.second_town("Reedmouth")
	NationName.give_name("The Reedfolk","court")
	assert_str(GameState.settlement_name).is_equal("Seanstone")
	assert_str(CivilizationSystem._player_home_name()).is_equal("SEANSTONE")
	# Where the army stands, how many live at home, the court's "home".
	var sheet:=Facts.sheet(["common"])
	assert_str(String(sheet.home)).is_equal("Seanstone")
	assert_str(Answers._common_answer(sheet,"how many are we?")).contains("Seanstone")
	assert_str(preload("res://scripts/hud/people_model.gd").home_name()).is_equal("Seanstone")
	assert_str(preload("res://scripts/hud/forces_model.gd").where_of({"home":true})).is_equal("Seanstone")
	# Our towns keep their own names; the town's renaming stays the town's.
	for city:Dictionary in GameState.player_settlements: assert_str(String(city.name)).is_not_equal("The Reedfolk")
	assert_str(String(Realm.rename("Rename Seanstone to Godshold").get("name",""))).is_equal("Godshold")
	assert_dict(Realm.nation("Rename Seanstone to Godshold")).is_empty()
	# Unnamed, an official says plainly what we go by.
	GameState.nation_name=""
	assert_str(Answers._common_answer(Facts.sheet(["common"]),"what are we called?")).is_equal("Our people have no name of their own yet; we go by Seanstone.")
