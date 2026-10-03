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


func _open(id:String)->Control:
	## The real Court, with no voice: every line here is put in by the test.
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	add_child(modal)
	await await_idle_frame()
	await await_idle_frame()
	await await_idle_frame()
	# Whatever the hall said on opening is shown at once.
	modal.skip_reveal()
	await await_idle_frame()
	return modal


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
