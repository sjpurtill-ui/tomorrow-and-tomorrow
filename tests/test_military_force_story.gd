extends GdUnitTestSuite
## The Forces page in plain words: what each force has, lacks, who fills it and
## the one next step. Pure sentences first, then the live screen.
const Story=preload("res://scripts/hud/military_force_story.gd")
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
const JARGON:=["PERSONNEL","LISTED SOLDIERS","FORCE GROUPS","NEED ATTENTION","planned","Short ","Missing gear","Condition "]

func _ctx(extra:Dictionary={})->Dictionary:
	var ctx:={"service":"army","stage":"hearth","free_adults":0,"policy":{"id":"regular","label":"Regular","intake":1.0},"food_for_drill":true,
		"supply":{"name":"Simple levy weapons","stores":0,"making":false,"per_day":0.0,"steward":""},"line":{"paused":false,"auto_deploy":true},"days_left":-1,"stalled":"","captain":{},"defense_target":0}
	ctx.merge(extra,true)
	return ctx

func _line(extra:Dictionary={})->Dictionary:
	var row:={"kind":"line","place":"reserve","name":"LEVY BAND","count":20,"authorized":20,"gear":17,"gear_required":20,"skill":0.0,"experience":0.0,"condition":1.0,"progress":.85,"hurt":19,"in_training":true}
	row.merge(extra,true)
	return row

func _reserve(extra:Dictionary={})->Dictionary:
	var row:={"kind":"formation","place":"reserve","name":"Home reserve","count":2,"authorized":2,"gear":0,"gear_required":2,"skill":.7,"experience":.01,"condition":.98}
	row.merge(extra,true)
	return row

func _all_text(story:Dictionary)->String:
	return " ".join([story.headline,story.people,story.arms,story.drill,story.condition,story.action.label])

func test_full_band_is_not_called_short_and_hurt_recruits_are_explained()->void:
	var story:=Story.describe(_line(),_ctx())
	assert_str(story.headline).starts_with("Levy band has all 20 warriors it is meant to have.")
	assert_str(story.people).starts_with("19 were hurt in drill along the way; others took their places")
	assert_str(_all_text(story)).not_contains("39")
	for word:String in JARGON:assert_str(_all_text(story)).not_contains(word)

func test_short_line_says_who_calls_up_the_rest_and_when()->void:
	var story:=Story.describe(_line({"count":12,"hurt":0}),_ctx({"free_adults":30}))
	assert_str(story.headline).contains("12 of the 20 warriors it is meant to have")
	assert_str(story.people).is_equal("8 more will be called up from the people tomorrow.")
	var slow:=Story.describe(_line({"count":12,"hurt":0}),_ctx({"free_adults":3}))
	assert_str(slow.people).contains("as they come free (3 are free now)")

func test_short_line_with_no_free_adults_says_no_one_is_being_called_up()->void:
	var story:=Story.describe(_line({"count":12,"hurt":0}),_ctx({"free_adults":0}))
	assert_str(story.people).contains("8 places are empty and no one is being called up").contains("every adult is already at work")
	assert_bool(story.attention).is_true()
	var paused:=Story.describe(_line({"count":12,"hurt":0}),_ctx({"free_adults":40,"line":{"paused":true}}))
	assert_str(paused.people).contains("no one is being called up: this recruitment is paused")
	assert_str(paused.action.id).is_equal("recruitment")

func test_short_home_reserve_is_filled_only_when_the_ruler_calls_up_replacements()->void:
	var story:=Story.describe(_reserve({"count":3,"authorized":8,"gear":3,"gear_required":3}),_ctx({"free_adults":50}))
	assert_str(story.headline).contains("3 of the 8 warriors it is meant to have")
	assert_str(story.people).contains("No one is being called up to fill them")
	assert_str(story.action.id).is_equal("reinforce")
	assert_str(story.action.label).is_equal("Call up 5 replacements")

func test_unarmed_force_names_the_workshop_pace_or_the_missing_order()->void:
	var nothing:=Story.describe(_reserve(),_ctx())
	assert_str(nothing.arms).is_equal("None of the 2 are armed yet; they wait for simple levy weapons.")
	assert_str(nothing.headline).contains("2 still waiting for weapons, and no one is making them: there is no steward to order them. Start simple levy weapons in Production.")
	assert_str(nothing.action.id).is_equal("production")
	assert_str(nothing.action.label).is_equal("Order weapons")
	var making:=Story.describe(_line(),_ctx({"supply":{"name":"Simple levy weapons","stores":0,"making":true,"per_day":.5,"steward":"your steward Anka"}}))
	assert_str(making.arms).is_equal("17 of 20 armed; 3 still wait for simple levy weapons.")
	assert_str(making.headline).ends_with("3 still waiting for weapons; the workshop is making them, about 6 days.")
	assert_str(making.action.id).is_not_equal("production")
	var quartermaster:=Story.describe(_line(),_ctx({"supply":{"name":"Simple levy weapons","making":true,"per_day":.5,"steward":"your quartermaster Anka","steward_title":"the Quartermaster"}}))
	assert_str(quartermaster.headline).ends_with("3 still waiting for weapons; the Quartermaster is making them, about 6 days.")
	var planned:=Story.describe(_line(),_ctx({"supply":{"name":"Simple levy weapons","covered":true,"days":4.0,"maker":"the Quartermaster"}}))
	assert_str(planned.headline).ends_with("3 still waiting for weapons; the Quartermaster is making them, about 4 days.")
	assert_str(planned.action.id).is_not_equal("production")
	var steward:=Story.describe(_reserve(),_ctx({"supply":{"name":"Simple levy weapons","stores":0,"making":false,"per_day":0.0,"steward":"your steward Anka"}}))
	assert_str(steward.headline).contains("2 still waiting for weapons; your steward Anka is ordering them from the workshop.")
	assert_str(steward.action.id).is_not_equal("production")
	var stored:=Story.describe(_reserve(),_ctx({"supply":{"name":"Simple levy weapons","stores":5}}))
	assert_str(stored.headline).contains("2 weapons are in stores and will be handed out within days")
	# Away from home the full reason stays on the weapons line.
	var away:=Story.describe(_reserve({"place":"field","count":2,"authorized":4}),_ctx())
	assert_str(away.arms).contains("Weapons reach them only at home")

func test_untrained_and_drilled_forces_read_plainly()->void:
	var untrained:=Story.describe(_reserve({"skill":0.0,"gear":2}),_ctx({"policy":{"label":"Suspend","intake":0.0}}))
	assert_str(untrained.drill).starts_with("Untrained: they have barely drilled.").contains("no one is drilling now")
	assert_str(untrained.action.id).is_equal("training")
	assert_str(untrained.action.label).is_equal("Start drill")
	var drilled:=Story.describe(_reserve({"gear":2}),_ctx())
	assert_str(drilled.drill).is_equal("Well drilled (70%); they have seen almost no fighting.")
	assert_str(drilled.action.id).is_equal("captain")

func test_drill_that_waits_for_weapons_says_so()->void:
	var story:=Story.describe(_line(),_ctx({"stalled":"gear"}))
	assert_str(story.drill).is_equal("First drill is 85% done and cannot go further until everyone is armed. Then they form their own band at home.")

func test_condition_is_only_shown_when_it_matters()->void:
	assert_str(Story.describe(_reserve({"gear":2}),_ctx()).condition).is_empty()
	var poor:=Story.describe(_reserve({"gear":2,"condition":.6}),_ctx())
	assert_str(poor.condition).contains("In poor shape (60%)")
	assert_bool(poor.attention).is_true()

func test_navy_and_air_forces_use_the_same_plain_words()->void:
	var boats:={"kind":"service","name":"River watch","count":1,"authorized":3,"skill":.5,"experience":.1,"condition":.9}
	var story:=Story.describe(boats,_ctx({"service":"navy","stage":"hearth","auto_replace":true,"supply":{"name":"War canoe","stores":0}}))
	assert_str(story.headline).starts_with("River watch has 1 of the 3 boats it is meant to have.")
	assert_str(story.people).is_equal("2 places are empty. New craft join by themselves once more are built and crews are free; none are waiting in stores.")
	assert_str(Story.describe(boats,_ctx({"service":"air","stage":"reckoned","auto_replace":false})).people).contains("replacements are switched off")
	for word:String in JARGON:assert_str(_all_text(story)).not_contains(word)

func test_summary_speaks_in_forces_and_warriors()->void:
	var rows:=[_reserve(),_line()]
	var told:=[Story.describe(rows[0],_ctx()),Story.describe(rows[1],_ctx())]
	var summary:=Story.summary(rows,told,"army","hearth")
	assert_str(summary.forces).is_equal("2 forces")
	assert_str(summary.fighters).is_equal("22 warriors")
	assert_str(summary.attention).starts_with("2 need you: ")
	assert_str(Story.summary(rows,told,"army","reckoned").fighters).is_equal("22 soldiers")

func test_live_screen_tells_the_reported_story_without_jargon()->void:
	GameState.reset_for_new_world(424242);MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(120)
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":2,"authorized_count":2,"equipment":0,"training":.7,"experience":.01,"personnel_condition":.98}],.8,.7)
	MilitaryCampaign.recruit_deploy.data={"next_id":2,"next_slot":2,"lines":[{"id":1,"name":"LEVY BAND","template_id":1,"entries":[{"unit":"levy","weapon":"improvised","count":20}],"parallel":1,"remaining":0,"repeat":false,"priority":1,"paused":false,"auto_deploy":true,"target_army":0,"deployed":0,"slots":[1]}]}
	MilitaryCampaign.training_queue=[{"id":5,"mode":"new","unit":"levy","weapon":"improvised","count":20,"initial_count":39,"experience":0.0,"progress_days":5.95,"required_days":7.0,"injury_accumulator":0.0,"deployment_line":1,"deployment_slot":1,"entry_index":0,"target_count":20,"reserved_equipment":17,"equipment_access_today":.85,"personnel_condition":1.0}]
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	assert_int(screen.bindings.size()).is_equal(2)
	var band:Dictionary=screen.bindings[1]
	assert_str(band.title.text).is_equal("Levy band")
	assert_str(band.headline.text).contains("all 20")
	assert_str(band.drill.text).contains("cannot go further until everyone is armed")
	assert_str(band.arms.text).contains("17 of 20 armed")
	var text:=""
	for node:Node in screen.find_children("*","Label",true,false):text+=(node as Label).text+"\n"
	for node:Node in screen.find_children("*","Button",true,false):text+=(node as Button).text+"\n"
	for word:String in JARGON:assert_str(text).not_contains(word)
	assert_str(screen.hero_values.strength.text).is_equal("22 warriors")
	WorldSimulation.clear()
