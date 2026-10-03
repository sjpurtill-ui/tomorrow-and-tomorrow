extends GdUnitTestSuite
## THE COURT AS A STAGE (scripts/hud/court_stage.gd, hud/audience_modal.gd).
## The player asked for an animated court with speech bubbles over real
## characters: dialogue to read, not a script.
## - a home audience and an envoy audience each build a stage, and the
##   figures standing on it are exactly who is in the audience;
## - a new line pops a bubble above the one who says it; the god's words come
##   from above and the engine's facts are a caption;
## - the words reveal at a reading pace, a click finishes them and a second
##   click brings the next line;
## - the history behind "Earlier" keeps every line, and no "NAME: words"
##   script rows sit in the main view;
## - the court at rest stands its officials in the hall as figures.
## Offline; never calls a real API and never writes a save file.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

var _root_size:=Vector2i.ZERO


func before_test()->void:
	Fixtures.new(self).base(false)
	_root_size=get_tree().root.size
	get_tree().root.size=Vector2i(1920,1080)


func after_test()->void:
	get_tree().root.size=_root_size
	Tokens.set_color_mode("light")


func _home_audience()->String:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else (Hall.summonable()[0].target as Dictionary)
	return String(Hall.summon(target).get("id",""))


func _envoy_audience()->String:
	for kind in ["gift","news","request","threat","proposal"]:
		var made:=Hall.debug_force(kind)
		if not made.is_empty():return String(made.id)
	return ""


func _open(id:String,view:=Vector2i.ZERO)->Control:
	## The real Court, with no voice: every line here is put in by the test.
	## view: a screen of that size (a viewport of its own), else the root.
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	if view!=Vector2i.ZERO:_screen(view).add_child(modal)
	else:add_child(modal)
	await await_idle_frame()
	await await_idle_frame()
	await await_idle_frame()
	# Whatever the hall said on opening is shown at once.
	modal.skip_reveal()
	await await_idle_frame()
	return modal


var _viewport:SubViewport

func _screen(view:Vector2i)->SubViewport:
	## A screen of a given size: the court measures itself against its viewport.
	if not is_instance_valid(_viewport):
		_viewport=auto_free(SubViewport.new())
		_viewport.disable_3d=true;_viewport.gui_disable_input=false
		add_child(_viewport)
	_viewport.size=view
	return _viewport


func _say(id:String,line:Dictionary)->void:
	var full:={"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"","day":int(GameState.elapsed_days),"aside":false}
	full.merge(line,true)
	Hall.append_line(id,full)


func _cast(modal:Control)->Array[String]:
	var keys:Array[String]=[]
	for key in modal.court_stage.cast_order:
		if modal.court_stage.has_figure(key) and not modal.court_stage.figure(key).leaving:keys.append(String(key))
	return keys


func _bubbles(modal:Control)->Array:
	var result:=[]
	for child in modal.speech_box.get_children():
		if child is Stage.Bubble and not (child as Stage.Bubble).dropping:result.append(child)
	return result


func _labels_outside(root:Node,skip:Node)->Array[Label]:
	var found:Array[Label]=[]
	for child in root.get_children():
		if child==skip:continue
		if child is Label:found.append(child as Label)
		found.append_array(_labels_outside(child,skip))
	return found


func test_a_home_audience_stands_the_one_summoned_and_the_court_on_the_stage()->void:
	var id:=_home_audience()
	assert_str(id).is_not_empty()
	var modal:Control=await _open(id)
	assert_object(modal.court_stage).is_not_null()
	assert_str(String(modal.court_stage.layout_kind)).is_equal("home")
	assert_object(modal.court_stage.find_parent("HallPanel")).is_not_null()
	# Exactly who is in the audience: the one before you and the court.
	var expected:Array[String]=[Stage.MAIN]
	for person:Dictionary in Hall.court(id):expected.append("p%d" % int(person.person_id))
	var cast:=_cast(modal)
	cast.sort();expected.sort()
	assert_array(cast).is_equal(expected)
	var main:Control=modal.court_stage.figure(Stage.MAIN)
	var speaker:Dictionary=Hall.find(id).speaker
	assert_str(String((main.find_child("FigureName",true,false) as Label).text)).is_equal(String(speaker.name))
	# Every figure stands inside the stage, the one before you in front.
	await get_tree().create_timer(1.6).timeout
	var stage_rect:Rect2=modal.court_stage.get_global_rect().grow(2.0)
	for key in cast:
		var f:Control=modal.court_stage.figure(key)
		assert_bool(stage_rect.encloses(f.get_global_rect())).override_failure_message("%s stands outside the stage: %s in %s" % [key,f.get_global_rect(),stage_rect]).is_true()
		if key!=Stage.MAIN:assert_float(f.size.y).is_less(main.size.y)
	# Each has a painting, read through the one accessor.
	assert_object(main.painting.texture).is_not_null()
	# The hall is the era's own setting.
	assert_object(modal.court_stage.get_parent().find_child("CourtScene",false,false)).is_not_null()


func test_an_envoy_audience_stands_the_envoy_their_company_and_our_court()->void:
	var id:=_envoy_audience()
	assert_str(id).is_not_empty()
	var modal:Control=await _open(id)
	assert_object(modal.envoy_stage).is_not_null()
	assert_str(String(modal.court_stage.layout_kind)).is_equal("envoy")
	var expected:Array[String]=[Stage.MAIN,"att0","att1"]
	var court:Array[Dictionary]=Hall.court(id)
	for index in mini(court.size(),2):expected.append("p%d" % int(court[index].person_id))
	var cast:=_cast(modal)
	cast.sort();expected.sort()
	assert_array(cast).is_equal(expected)
	# The envoy's name and people on their plate; their company has none.
	var envoy:Control=modal.court_stage.figure(Stage.MAIN)
	assert_str((envoy.find_child("EnvoyName",true,false) as Label).text).is_equal(String(Hall.find(id).speaker.name))
	assert_bool(modal.court_stage.figure("att0").plate.visible).is_false()
	# Nobody shares a painting with another on one stage.
	var keys:={}
	for key in cast:
		var person:Dictionary=modal.court_stage.figure(key).person
		var slot:Array=Portrait.claim(modal.scene_portraits,person)
		keys[str([int(slot[3]),int(slot[0]),int(slot[2])])]=true
	assert_int(keys.size()).is_equal(cast.size())


func test_a_new_line_pops_a_bubble_above_the_one_who_says_it()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var court:Array[Dictionary]=Hall.court(id)
	assert_bool(court.is_empty()).is_false()
	var witness:Dictionary=court[0]
	var key:="p%d" % int(witness.person_id)
	_say(id,{"speaker":String(witness.name),"role":"official","person_id":int(witness.person_id),"text":"The ford is low this month; the herds can cross."})
	modal.skip_reveal()
	await await_idle_frame()
	var bubbles:=_bubbles(modal)
	assert_int(bubbles.size()).is_equal(1)
	var bubble:Stage.Bubble=bubbles[0]
	assert_str(bubble.speaker).is_equal(key)
	assert_str(bubble.label.text).is_equal("The ford is low this month; the herds can cross.")
	# Its tail ends on that figure: over their head, or beside it.
	var f:Control=modal.court_stage.figure(key)
	var tip:Vector2=bubble.position+bubble.tip
	assert_str(bubble.tail_side).is_not_equal("none")
	assert_float(absf(tip.x-f.home.x)).is_less_equal(f.size.x*.6)
	assert_float(tip.y).is_less_equal(f.home.y-f.size.y*.5)
	# The speaker steps forward; the others turn toward them.
	assert_str(String(modal.court_stage.speaking_key)).is_equal(key)
	# The one before you answers: a new bubble over them, the first one fades.
	var speaker:Dictionary=Hall.find(id).speaker
	_say(id,{"speaker":String(speaker.name),"role":"official","person_id":int(speaker.get("person_id",0)),"text":"Then we cross before the rains."})
	modal.skip_reveal()
	await await_idle_frame()
	var newest:Stage.Bubble=_bubbles(modal)[-1]
	assert_str(newest.speaker).is_equal(Stage.MAIN)
	assert_int(_bubbles(modal).size()).is_less_equal(2)


func test_the_gods_words_come_from_above_and_the_facts_are_a_caption()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	_say(id,{"speaker":"You","role":"ruler","text":"Bring the herds to the high meadow."})
	_say(id,{"role":"narrator","text":"[The marshal bows and goes out to the herders.]"})
	modal.skip_reveal()
	await await_idle_frame()
	var above:=modal.court_stage.find_child("VoiceFromAbove",true,false) as Control
	assert_object(above).is_not_null()
	assert_str((above.find_child("Said",true,false) as Label).text).is_equal("Bring the herds to the high meadow.")
	assert_float(above.position.y).is_less(modal.court_stage.size.y*.4)
	var caption:=modal.court_stage.find_child("Caption",true,false) as Control
	assert_object(caption).is_not_null()
	# A stage direction is told as what happens, without its brackets.
	assert_str((caption.find_child("Said",true,false) as Label).text).is_equal("The marshal bows and goes out to the herders.")
	assert_float(caption.position.y).is_greater(modal.court_stage.size.y*.5)
	assert_int(_bubbles(modal).size()).is_equal(0)


func test_words_reveal_at_a_reading_pace_and_clicks_finish_then_advance()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var speaker:Dictionary=Hall.find(id).speaker
	var pid:=int(speaker.get("person_id",0))
	_say(id,{"speaker":String(speaker.name),"role":"official","person_id":pid,"text":"We have counted the stores twice and the second count is lower."})
	_say(id,{"speaker":String(speaker.name),"role":"official","person_id":pid,"text":"Someone is taking grain at night."})
	modal._pump()
	assert_bool(modal.revealing).is_true()
	var first:Label=modal._reveal_label
	assert_str(first.text).is_equal("We have counted the stores twice and the second count is lower.")
	assert_float(first.visible_ratio).is_less(1.0)
	# It is not instant: after a few frames the words are still coming.
	await await_idle_frame()
	await await_idle_frame()
	assert_float(first.visible_ratio).is_less(1.0)
	assert_int(int(modal.rendered_lines)).is_equal(1)
	# A click shows the words at once; the next line waits for a second click.
	modal.advance()
	assert_float(first.visible_ratio).is_equal(1.0)
	assert_bool(modal.revealing).is_true()
	modal._pump()
	assert_int(int(modal.rendered_lines)).is_equal(1)
	modal.advance()
	assert_int(int(modal.rendered_lines)).is_equal(2)
	assert_str((modal._reveal_label as Label).text).is_equal("Someone is taking grain at night.")
	# A click anywhere on the stage does the same as advance().
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	modal.court_stage._gui_input(click)
	assert_float((modal._reveal_label as Label).visible_ratio).is_equal(1.0)


func test_the_history_keeps_every_line_and_the_main_view_has_no_script_rows()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var speaker:Dictionary=Hall.find(id).speaker
	var witness:Dictionary=Hall.court(id)[0]
	var said:=[
		{"speaker":"You","role":"ruler","text":"Who let the fire at the kilns go out?"},
		{"speaker":String(speaker.name),"role":"official","person_id":int(speaker.get("person_id",0)),"text":"The boy who tends it was sent for water."},
		{"speaker":String(witness.name),"role":"official","person_id":int(witness.person_id),"text":"I sent him. The well rope had broken."},
		{"role":"narrator","text":"Two firings are lost; the potters start again tomorrow."},
		{"speaker":String(witness.name),"role":"official","person_id":int(witness.person_id),"text":"It will not happen again.","aside":true},
	]
	for line:Dictionary in said:_say(id,line)
	modal.skip_reveal()
	await await_idle_frame()
	# History: hidden behind "Earlier", and it has every line.
	var history:=modal.transcript_scroll as Control
	assert_bool(history.visible).is_false()
	var kept:=""
	for label in modal.transcript.find_children("*","Label",true,false):kept+=(label as Label).text+"\n"
	for line:Dictionary in said:assert_str(kept).contains(String(line.text))
	modal.toggle_popover("WhatWasSaid")
	assert_bool(history.visible).is_true()
	assert_bool((modal.card.find_child("OpenWhatWasSaid",true,false) as Button).button_pressed).is_true()
	modal.toggle_popover("WhatWasSaid")
	assert_bool(history.visible).is_false()
	# The main view: the words alone, in bubbles, never "Name: words".
	var names:=["You",String(speaker.name),String(witness.name)]
	for label in _labels_outside(modal.card,history):
		for who in names:
			assert_bool(label.text.begins_with(who+":")).override_failure_message("a script row in the main view: %s" % label.text).is_false()
	var newest:Stage.Bubble=_bubbles(modal)[-1]
	assert_str(newest.label.text).is_equal("It will not happen again.")
	assert_str(newest.kind).is_equal("aside")


func test_someone_not_yet_in_the_hall_walks_in_to_speak()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	_say(id,{"speaker":"Old Mether","role":"official","person_id":0,"text":"I saw the boy at the well myself."})
	modal.skip_reveal()
	await await_idle_frame()
	var key:String=modal.court_stage.key_for_name("Old Mether")
	assert_str(key).is_not_empty()
	assert_str(String(_bubbles(modal)[-1].speaker)).is_equal(key)


func test_when_the_audience_is_concluded_they_take_their_leave()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	modal._show_outcome({"ok":true,"outcome":"They go.","reaction":"pleased"})
	assert_bool(modal._leave_when_quiet).is_true()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(modal._leave_when_quiet).is_false()
	assert_bool(modal.court_stage.figure(Stage.MAIN).leaving).is_true()


func test_the_court_at_rest_stands_its_officials_as_figures()->void:
	var modal:Control=auto_free(Modal.new())
	add_child(modal)
	await await_idle_frame()
	await await_idle_frame()
	var seats:=modal.find_children("Seat_*","Control",true,false)
	assert_bool(seats.is_empty()).is_false()
	for seat in seats:
		var standing:=(seat as Control).find_child("Figure",false,false)
		assert_bool(standing is Stage.Figure).is_true()
		assert_object((standing as Stage.Figure).painting.texture).is_not_null()


func test_one_accessor_gives_each_person_their_picture()->void:
	var registry:={}
	var a:={"name":"Hena","person_id":0}
	var b:={"name":"Tuk","person_id":0}
	var first:=Stage.figure_picture(a,registry)
	var again:=Stage.figure_picture(a,registry)
	var other:=Stage.figure_picture(b,registry)
	assert_object(first.texture).is_not_null()
	assert_array(first.slot).is_equal(again.slot)
	assert_array(first.slot).is_not_equal(other.slot)


# --- Review fixes: long lines, one picture seam, resizing, the 60-line hall ----

const LONG_LINE:="The herders came down from the high meadow two days early because the ford was already rising, and they say the second flock is still above the gorge with only the boy Teren and two dogs, and the rain on the ridge has not stopped since the moon was new, so either we send ten strong men with ropes before nightfall or we count those sheep as lost."

func _main_line(id:String,text:String)->void:
	var speaker:Dictionary=Hall.find(id).speaker
	_say(id,{"speaker":String(speaker.name),"role":"official","person_id":int(speaker.get("person_id",0)),"text":text})


func _assert_inside(bubble:Control,stage:Control)->void:
	var room:=Rect2(Vector2.ZERO,stage.size).grow(1.0)
	assert_bool(room.encloses(bubble.get_rect())).override_failure_message("words spill off the stage: %s in %s" % [bubble.get_rect(),stage.size]).is_true()


func test_a_long_line_stays_whole_on_the_players_screen()->void:
	## The user's screen: 1920x1080 at 125% is 1536x864 to the game.
	var id:=_home_audience()
	var modal:Control=await _open(id,Vector2i(1536,864))
	for frame in 3:await await_idle_frame()
	# The hall keeps a real height; the stakes fold before it gets too short.
	assert_float(modal.court_stage.size.y).is_greater_equal(Modal.HALL_FLOOR.y)
	for text in [LONG_LINE.substr(0,216),LONG_LINE,LONG_LINE+" "+LONG_LINE.substr(0,90)]:
		_main_line(id,text)
		modal.skip_reveal()
		await await_idle_frame()
		var bubble:Stage.Bubble=_bubbles(modal)[-1]
		_assert_inside(bubble,modal.court_stage)
		# Whole, or cut at a word with a way to the rest in Earlier.
		if bubble.truncated:
			assert_str(bubble.label.text).ends_with("…")
			assert_bool(text.begins_with(bubble.label.text.trim_suffix("…"))).is_true()
			assert_bool((bubble.find_child("More",false,false) as Control).visible).is_true()
		else:
			assert_str(bubble.label.text).is_equal(text)
	# The card fits the screen at any of the small sizes.
	for view in [Vector2i(1280,720),Vector2i(1138,640),Vector2i(1024,640)]:
		_screen(view)
		for frame in 4:await await_idle_frame()
		var shown:Rect2=modal.card.get_global_rect()
		assert_bool(Rect2(Vector2.ZERO,Vector2(view)).grow(1.0).encloses(shown)).override_failure_message("the card spills off a %s screen: %s" % [view,shown]).is_true()
		_assert_inside(_bubbles(modal)[-1],modal.court_stage)


func test_more_on_cut_words_opens_earlier_at_that_line()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	# A short hall: the words cannot all fit even wide and small.
	modal.court_stage.size=Vector2(640,240)
	var text:=LONG_LINE+" "+LONG_LINE+" "+LONG_LINE
	_main_line(id,text)
	modal.skip_reveal()
	await await_idle_frame()
	var bubble:Stage.Bubble=_bubbles(modal)[-1]
	assert_bool(bubble.truncated).is_true()
	(bubble.find_child("More",false,false) as Button).pressed.emit()
	await await_idle_frame()
	assert_bool(modal.transcript_scroll.visible).is_true()
	var row:Control=modal._history_rows[bubble.ref]
	var kept:=""
	for label in row.find_children("*","Label",true,false):kept+=(label as Label).text
	assert_str(kept).contains(text)


func test_bubbles_fit_again_when_the_stage_changes_size()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	_main_line(id,LONG_LINE)
	modal.skip_reveal()
	await await_idle_frame()
	var bubble:Stage.Bubble=_bubbles(modal)[-1]
	var before:=bubble.size
	modal.court_stage.size=Vector2(520,260)
	await await_idle_frame()
	assert_float(bubble.size.x).is_less_equal(520.0-16.0)
	assert_bool(bubble.size!=before).is_true()
	_assert_inside(bubble,modal.court_stage)


func test_every_portrait_goes_through_the_one_seam()->void:
	## Roster rows, the court at rest, the history and the envoy channel all
	## read pictures through CourtStage.figure_picture.
	var modal:Control=auto_free(Modal.new())
	add_child(modal)
	await await_idle_frame()
	await await_idle_frame()
	var portraits:Array[Node]=modal.card.find_children("Portrait","TextureRect",true,false)
	assert_bool(portraits.is_empty()).is_false()
	for picture in portraits:assert_bool(picture.has_meta("figure_slot")).override_failure_message("a portrait skips the seam: %s" % picture.get_path()).is_true()
	var civ:=""
	for entry in preload("res://scripts/hud/court_roster.gd").foreign_peoples():
		if not ForeignDiplomacy.leader(String(entry.civ_id)).is_empty():civ=String(entry.civ_id);break
	if civ.is_empty():return
	assert_bool(modal.show_foreign(civ)).is_true()
	await await_idle_frame()
	for picture in modal.card.find_children("Portrait","TextureRect",true,false):
		assert_bool(picture.has_meta("figure_slot")).override_failure_message("a foreign portrait skips the seam: %s" % picture.get_path()).is_true()


func test_new_lines_keep_showing_after_the_hall_drops_its_oldest()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	for index in Hall.LINES_MAX+12:
		_main_line(id,"Count %d." % index)
		modal.skip_reveal()
	assert_int((Hall.find(id).lines as Array).size()).is_equal(Hall.LINES_MAX)
	_main_line(id,"And the last of them.")
	modal._pump()
	assert_str((modal._reveal_label as Label).text).is_equal("And the last of them.")
	modal.skip_reveal()
	var kept:=0
	for row in modal._history_rows:
		for label in row.find_children("LineText","Label",true,false):
			if (label as Label).text.begins_with("Count ") or (label as Label).text=="And the last of them.":kept+=1
	assert_int(kept).is_equal(Hall.LINES_MAX+13)


func test_words_after_they_have_gone_are_a_caption()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	modal.court_stage.conclude(0.0)
	var before:=_bubbles(modal).size()
	_main_line(id,"I will come back when the rain stops.")
	modal.skip_reveal()
	await await_idle_frame()
	assert_int(_bubbles(modal).size()).is_less_equal(before)
	var shown:=modal.court_stage._caption as Control
	assert_str((shown.find_child("Said",true,false) as Label).text).contains("I will come back when the rain stops.")


func test_the_condemned_do_not_bow_out()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var pid:=int(Hall.find(id).speaker.get("person_id",0))
	assert_str(modal.exit_style_for({"action":"strike_down","terminal":true,"removed":true,"person_id":pid})).is_equal("fall")
	assert_str(modal.exit_style_for({"action":"cast_out","terminal":true,"removed":true,"person_id":pid})).is_equal("led")
	assert_str(modal.exit_style_for({"verb":"kill","terminal":true,"target":{"key":"someone_else","person_id":pid+999}})).is_not_equal("fall")
	assert_str(modal.exit_style_for({"ok":true,"reaction":"offended"})).is_equal("storm")
	assert_str(modal.exit_style_for({"ok":true,"reaction":"pleased"})).is_equal("bow")
	modal._show_outcome({"ok":true,"outcome":"They are put to death.","action":"strike_down","terminal":true,"removed":true,"person_id":pid,"reaction":"furious"})
	await await_idle_frame()
	await await_idle_frame()
	assert_str(String(modal.court_stage.figure(Stage.MAIN).exit_style)).is_equal("fall")


func test_a_warning_waits_for_the_words_being_revealed()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	_say(id,{"role":"narrator","text":"The herders count the flock twice and come up four short."})
	modal._pump()
	assert_bool(modal.revealing).is_true()
	var telling:=modal.court_stage._caption as Control
	modal._show_toast("That cannot be done now.")
	assert_object(modal.court_stage._caption).is_same(telling)
	modal.advance()
	modal.advance()
	var shown:=modal.court_stage._caption as Control
	assert_str((shown.find_child("Said",true,false) as Label).text).is_equal("That cannot be done now.")


func test_older_words_never_cover_the_gods()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var witness:Dictionary=Hall.court(id)[0]
	_say(id,{"speaker":String(witness.name),"role":"official","person_id":int(witness.person_id),"text":LONG_LINE})
	_main_line(id,LONG_LINE.substr(0,120))
	_say(id,{"speaker":"You","role":"ruler","text":"Send the ten men with ropes before dark."})
	modal.skip_reveal()
	await await_idle_frame()
	var band:Rect2=(modal.court_stage._god as Control).get_rect()
	for bubble in _bubbles(modal):
		assert_bool((bubble as Control).get_rect().intersects(band)).override_failure_message("an old bubble covers the god's words").is_false()


func test_an_envoys_words_keep_clear_of_the_offered_object()->void:
	var id:=_envoy_audience()
	var modal:Control=await _open(id)
	var stage:Control=modal.court_stage
	if stage.right_reserve<=0.0:return
	var speaker:Dictionary=Hall.find(id).speaker
	_say(id,{"speaker":String(speaker.name),"role":"envoy","text":LONG_LINE})
	modal.skip_reveal()
	await await_idle_frame()
	var bubble:Stage.Bubble=_bubbles(modal)[-1]
	assert_float(bubble.get_rect().end.x).is_less_equal(stage.size.x-stage.right_reserve+1.0)
	for key in stage.cast_order:
		var f:Control=stage.figure(key)
		assert_float(f.home.x+f.size.x*.5).is_less_equal(stage.size.x-stage.right_reserve+4.0)


func test_a_large_court_still_stands_inside_an_envoys_stage()->void:
	var stage:Control=auto_free(Stage.new())
	stage.layout_kind="envoy";stage.right_reserve=320.0
	add_child(stage)
	stage.size=Vector2(1300,420)
	stage.add_figure(Stage.MAIN,{"name":"Esi"},Stage.MAIN,"Esi")
	for index in 7:stage.add_figure("p%d" % index,{"name":"Official %d" % index,"person_id":900+index},"court","Official %d" % index)
	await await_idle_frame()
	var first:Control=stage.figure("p0")
	for index in 7:
		var f:Control=stage.figure("p%d" % index)
		assert_float(f.home.x+f.size.x*.5).is_less_equal(1300.0-320.0+4.0)
		if index>=Stage.ENVOY_COURT_X.size():assert_float(f.size.y).is_less(first.size.y)


func test_what_you_know_never_spills_off_a_short_stage()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id,Vector2i(1138,640))
	modal.toggle_popover("WhatYouKnow")
	await await_idle_frame()
	await await_idle_frame()
	var pop:=modal.envoy_popovers["WhatYouKnow"] as Control
	var holder:=pop.get_parent() as Control
	assert_bool(pop.visible).is_true()
	assert_float(pop.position.y+pop.size.y).is_less_equal(holder.size.y+1.0)


# --- Modelled figures (tools/blender/court_figures.py, hud/court_figure_3d.gd) ----

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Looks:=preload("res://scripts/people_appearance.gd")
const EarlyArt:=preload("res://scripts/hud/early_civ_art.gd")


func _clip_of(modal:Control,key:String)->String:
	var f:Stage.Figure=modal.court_stage.figure(key)
	return String(f.body3d.clip) if f!=null and f.body3d!=null else ""


func test_the_people_on_the_stage_are_modelled_figures_in_one_hall()->void:
	assert_bool(Figure3D.available()).override_failure_message("the court figures did not load from assets/court_figures").is_true()
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var stage:Control=modal.court_stage
	assert_bool(stage.three_d).is_true()
	# One SubViewport for the whole stage; every figure's body stands in it.
	assert_int(stage.find_children("*","SubViewport",true,false).size()).is_equal(1)
	assert_bool(_cast(modal).is_empty()).is_false()
	for key in _cast(modal):
		var f:Stage.Figure=stage.figure(key)
		assert_object(f.body3d).is_not_null()
		assert_object(f.body3d.get_parent()).is_same(stage.view3d)
		assert_bool(f.painting.visible).is_false()
		# Their feet stand on the stage where the layout put them.
		var feet:Vector2=stage.world_to_stage(f.body3d.global_position)
		assert_float(feet.distance_to(f.home+Vector2(f.walk,0.0))).is_less(3.0)
	# Nothing runs per frame: the figures move by clips and tweens alone.
	assert_bool(stage.figure(Stage.MAIN).body3d.has_method("_process")).is_false()
	assert_bool(stage.has_method("_process")).is_false()


func test_each_person_wears_their_peoples_look()->void:
	var registry:={}
	var ours:={"name":"Hena","person_id":0,"sex":"female","age":34}
	var look:=Stage.figure_look(ours,registry)
	var people:=Looks.profile(EarlyArt.owner(ours))
	assert_str(String(look.variant)).is_equal("female_adult")
	# Skin within the people's range; cloth of the people's three dyes.
	var lightest:=Color(String(people.skin[0]));var deepest:=Color(String(people.skin[2]))
	var skin:Color=look.skin
	assert_float(skin.get_luminance()).is_between(deepest.get_luminance()-0.01,lightest.get_luminance()+0.01)
	var dyes:=PackedStringArray()
	for hex in people.cloth:dyes.append(String(hex).to_lower())
	if String(look.outfit)!="hide":
		for c in look.cloth:assert_bool(dyes.has((c as Color).to_html(false))).is_true()
	# The same person always looks the same; old men grey.
	assert_str(var_to_str(Stage.figure_look(ours,{}))).is_equal(var_to_str(Stage.figure_look(ours,{})))
	var elder:=Stage.figure_look({"name":"Old Mether","person_id":0,"sex":"male","age":71},{})
	assert_str(String(elder.variant)).is_equal("male_old")
	assert_float((elder.hair_colour as Color).get_luminance()).is_greater(0.35)
	# On one screen nobody is dressed and coloured just like another.
	var keys:={}
	for index in 12:
		var other:=Stage.figure_look({"name":"Twin","person_id":4000+index,"sex":"male","age":30},registry)
		keys[Stage._look_key(other)]=true
	assert_int(keys.size()).is_greater_equal(10)
	# Their dress is the dress of the age their people have reached.
	var tier:int=Stage._era_tier(EarlyArt.owner(ours))
	if tier!=2:assert_str(String(look.outfit)).is_equal(String(Stage.ERA_DRESS[clampi(tier,0,3)]))


func test_the_room_acts_out_what_is_said()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var court:Array[Dictionary]=Hall.court(id)
	assert_bool(court.is_empty()).is_false()
	var witness:="p%d" % int(court[0].person_id)
	var speaker:Dictionary=Hall.find(id).speaker
	_say(id,{"speaker":String(speaker.name),"role":"official","person_id":int(speaker.get("person_id",0)),"text":"The ford is low; the herds can cross before the rains come down."})
	modal._pump()
	await await_idle_frame()
	# The speaker talks with their hands, in their own stance.
	var main:Stage.Figure=modal.court_stage.figure(Stage.MAIN)
	assert_str(_clip_of(modal,Stage.MAIN)).contains("talk")
	# The others keep their stance and look at the one speaking.
	var w:Stage.Figure=modal.court_stage.figure(witness)
	assert_str(_clip_of(modal,witness)).is_equal(w.body3d.rest_clip())
	assert_bool(w.body3d._gaze_on).is_true()
	assert_float(w.body3d.gaze.global_position.distance_to(main.body3d.head_top())).is_less(0.5*main.body3d.scale.y)
	modal.skip_reveal()
	# The god speaks: every face lifts toward the voice, above them all.
	_say(id,{"speaker":"You","role":"ruler","text":"Then cross."})
	modal.skip_reveal()
	await await_idle_frame()
	for key in _cast(modal):
		var f:Stage.Figure=modal.court_stage.figure(key)
		assert_bool(f.body3d._gaze_on).is_true()
		assert_float(f.body3d.gaze.global_position.y).is_greater(f.body3d.head_top().y)
	# What the hall shows of the one it names, they do.
	_say(id,{"role":"narrator","text":"[%s kneels before you.]" % String(speaker.name)})
	modal.skip_reveal()
	await await_idle_frame()
	assert_str(_clip_of(modal,Stage.MAIN)).is_equal("kneel")


func test_wrath_brings_them_down_and_favour_brings_a_bow()->void:
	assert_str(Stage.divine_mood("terrify")).is_equal("dread")
	assert_str(Stage.divine_mood("penance")).is_equal("dread")
	assert_str(Stage.divine_mood("bless")).is_equal("reverence")
	var id:=_home_audience()
	var modal:Control=await _open(id)
	modal.court_stage.react(Stage.MAIN,"dread")
	assert_str(_clip_of(modal,Stage.MAIN)).is_equal("kneel")
	modal.court_stage.react(Stage.MAIN,"reverence")
	assert_str(_clip_of(modal,Stage.MAIN)).is_equal("bow")
	assert_str(Stage.gesture_in("The headman bows and sends for the tally-keeper.")).is_equal("reverence")
	assert_str(Stage.gesture_in("She falls to her knees.")).is_equal("dread")


func test_they_walk_in_and_walk_out_as_people_do()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var stage:Control=modal.court_stage
	var f:Stage.Figure=stage.add_figure("late",{"name":"Late Tamsa","person_id":0},"court","Tamsa","",true)
	await await_idle_frame()
	# Walking in from beyond the edge, turned the way they go.
	assert_str(String(f.body3d.clip)).is_equal("walk_in")
	assert_float(absf(f.walk)).is_greater(0.0)
	assert_float(absf(f.body3d.rotation_degrees.y)).is_greater(60.0)
	stage.settle()
	assert_float(f.walk).is_equal(0.0)
	assert_str(String(f.body3d.clip)).is_equal(f.body3d.rest_clip())
	# Taking their leave: a bow first, then they are gone and still.
	stage.conclude(0.0,"bow")
	await await_idle_frame()
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	assert_bool(main.leaving).is_true()
	assert_str(String(main.body3d.clip)).is_equal("bow")
	stage.settle()
	assert_bool(main.body3d.visible).is_false()
	assert_bool(main.body3d.player.is_playing()).is_false()
	assert_int(main.body3d.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)


# --- Review fixes: directions act on whom they name, the engine's defiance --------

func test_directions_move_only_the_one_they_are_about()->void:
	# Real lines the hall writes (rival_rulers.gd, upkeep_warnings.gd, court_commands.gd).
	assert_str(Stage.gesture_in("[The envoy comes in with a guard of spearmen and keeps a hand near their knife; nobody from Varrow kneels.]")).is_equal("")
	assert_str(Stage.gesture_in("[Tamsa comes in with mud to the elbows.]")).is_equal("")
	assert_str(Stage.gesture_in("[Kel takes up a flint blade, then freezes; the point trembles a hand's breadth from Oru, and every eye turns to you.]")).is_equal("")
	assert_str(Stage.gesture_in("[Kel steps toward Oru with a club, stops, and falls to their knees instead, the club still in hand.]")).is_equal("dread")
	assert_str(Stage.gesture_in("[Kel bows and goes out to see it done; word of the order runs ahead of them through the camp.]")).is_equal("reverence")
	assert_str(Stage.gesture_in("[The envoy will not bow to you.]")).is_equal("")
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var court:Array[Dictionary]=Hall.court(id)
	assert_bool(court.is_empty()).is_false()
	var other:Dictionary=court[0]
	var key:="p%d" % int(other.person_id)
	var main_before:=_clip_of(modal,Stage.MAIN)
	# Another official bows: they bow; the one before the god does not.
	_say(id,{"role":"narrator","text":"[%s bows and goes out to see it done.]" % String(other.name),"about":String(other.name)})
	modal.skip_reveal()
	await await_idle_frame()
	assert_str(_clip_of(modal,key)).is_equal("bow")
	assert_str(_clip_of(modal,Stage.MAIN)).is_equal(main_before)
	# Someone not standing here kneels: nobody moves.
	_say(id,{"role":"narrator","text":"[Oru falls to their knees.]","about":"Oru"})
	modal.skip_reveal()
	await await_idle_frame()
	assert_str(_clip_of(modal,Stage.MAIN)).is_equal(main_before)
	# A defiant envoy's entrance moves nobody.
	_say(id,{"role":"narrator","text":"[The envoy comes in with a guard of spearmen and keeps a hand near their knife; nobody from Varrow kneels.]"})
	modal.skip_reveal()
	await await_idle_frame()
	assert_str(_clip_of(modal,Stage.MAIN)).is_equal(main_before)


func test_the_defiant_stand_their_ground()->void:
	# The engine decides who defies (divine_regard.gd response_to); the stage agrees.
	assert_str(Stage.divine_mood("terrify","defy")).is_equal("defy")
	assert_str(Stage.divine_mood("terrify","cower")).is_equal("dread")
	assert_str(Stage.divine_mood("penance","endure")).is_equal("endure")
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var main:Stage.Figure=modal.court_stage.figure(Stage.MAIN)
	modal.court_stage.react(Stage.MAIN,Stage.divine_mood("terrify","defy"))
	assert_str(_clip_of(modal,Stage.MAIN)).is_not_equal("kneel")
	assert_str(String(main.body3d.mood)).is_equal("defiant")
	# Moods from the engine's regard and an envoy's temper.
	assert_str(Stage.mood_of({"id":"terror","dread":0.9})).is_equal("afraid")
	assert_str(Stage.mood_of({"love":0.8})).is_equal("warm")
	assert_str(Stage.mood_of({},-0.7)).is_equal("defiant")


func test_an_envoys_punishment_shows_on_them()->void:
	assert_str(Stage.divine_mood("envoy_flog")).is_equal("dread")
	assert_str(Stage.divine_mood("envoy_detain")).is_equal("dread")
	assert_str(Stage.divine_mood("envoy_flog","defy")).is_equal("defy")


func test_the_hall_runs_lean()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	assert_int(modal.court_stage.view3d.msaa_3d).is_equal(Viewport.MSAA_2X)
	# Many colours never grow the shared materials past their limit.
	for index in Figure3D.MATERIAL_LIMIT+40:
		Figure3D.material("CLOTH_A",Color(float(index%97)/96.0,float(index%13)/12.0,0.5))
	assert_int(Figure3D._materials.size()).is_less_equal(Figure3D.MATERIAL_LIMIT)


func test_each_person_keeps_a_stance_and_a_face_of_their_own()->void:
	var registry:={}
	var a:=Stage.figure_look({"name":"Hena","person_id":11,"sex":"female","age":34},registry)
	var b:=Stage.figure_look({"name":"Tuk","person_id":12,"sex":"male","age":40},registry)
	assert_bool(String(a.stance) in Figure3D.STANCES).is_true()
	assert_bool((a.face as Dictionary).size()>=10).is_true()
	assert_bool(var_to_str(a.face)!=var_to_str(b.face)).is_true()
	# Most men go shaven or stubbled; a beard is one of several shapes.
	var bare:=0
	for index in 60:
		var man:=Stage.figure_look({"name":"Man %d" % index,"person_id":5000+index,"sex":"male","age":35},{})
		if String(man.beard) in ["","beard_stubble"]:bare+=1
		else:assert_bool(String(man.beard) in ["beard_short","beard_chin","beard_moustache","beard_full"]).is_true()
	assert_int(bare).is_greater(30)


func test_bubbles_hang_over_the_modelled_head()->void:
	var id:=_home_audience()
	var modal:Control=await _open(id)
	_main_line(id,"Count them again.")
	modal.skip_reveal()
	await await_idle_frame()
	var stage:Control=modal.court_stage
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	var head:Vector2=stage.world_to_stage(main.body3d.head_top())
	var bubble:Stage.Bubble=_bubbles(modal)[-1]
	var tip:Vector2=bubble.position+bubble.tip
	assert_float(absf(tip.x-head.x)).is_less(main.size.x*.35)
	assert_float(tip.y).is_less_equal(head.y+main.size.y*.2)
	# The name plate stands under their feet, not over them.
	assert_float(main.plate.position.y).is_greater_equal(main.size.y)


func test_without_the_models_the_painted_figures_stand()->void:
	Figure3D.enabled=false
	var id:=_home_audience()
	var modal:Control=await _open(id)
	var stage:Control=modal.court_stage
	assert_bool(stage.three_d).is_false()
	assert_int(stage.find_children("*","SubViewport",true,false).size()).is_equal(0)
	for key in _cast(modal):
		var f:Stage.Figure=stage.figure(key)
		assert_object(f.body3d).is_null()
		assert_object(f.painting.texture).is_not_null()
	Figure3D.enabled=true


func test_figures_of_one_colour_share_their_materials()->void:
	var a:=Figure3D.new();var b:=Figure3D.new()
	auto_free(a);auto_free(b)
	var look:={"variant":"female_adult","outfit":"tunic","hair":"bun","skin":Color("9f6a43"),"hair_colour":Color("2b2018"),"cloth":[Color("a8432f"),Color("5b4130"),Color("c9a43c")]}
	assert_bool(a.setup(look)).is_true()
	assert_bool(b.setup(look)).is_true()
	var body_a:=a.model.find_child("Body",true,false) as MeshInstance3D
	var body_b:=b.model.find_child("Body",true,false) as MeshInstance3D
	assert_object(body_a.get_surface_override_material(0)).is_same(body_b.get_surface_override_material(0))
	# One hair, one outfit shown; the rest hidden.
	var shown:=0
	for mesh in a.model.find_children("hair_*","MeshInstance3D",true,false):
		if (mesh as MeshInstance3D).visible:shown+=1
	assert_int(shown).is_equal(1)
	for mesh in a.model.find_children("robe_*","MeshInstance3D",true,false):assert_bool((mesh as MeshInstance3D).visible).is_false()
	for clip in Figure3D.CLIPS:assert_bool(a.player.has_animation(clip)).override_failure_message("missing clip "+clip).is_true()
