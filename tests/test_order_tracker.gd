extends GdUnitTestSuite
## THE FAIL-SAFE ORDER CARDS (order_tracker.gd, order_probes.gd,
## hud/order_stack.gd). The player asked for 20 soldiers and saw nothing
## happen: every order now gets a card at the bottom right that says, from the
## engine's own ledger, how it is carried out, and turns red when nothing has
## happened by the end of the next game day.
## - every hooked entry point registers an order (court words, an office
##   button, the Army screen, the recruitment board, the workshops, the
##   buildings, the defences, research);
## - a levy's card follows called up -> drilling -> done in the real ledger;
## - an order nobody takes, or that nothing moves, turns red after a day;
## - court words no mechanic could take are red at once;
## - the ledger is saved bounded, and an older save loads with none;
## - every card line is short and reads in light and dark.
## Offline; never calls a real API and never writes a save file.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const Probes:=preload("res://scripts/order_probes.gd")
const HO:=preload("res://scripts/home_orders.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const RecordingVoice:=preload("res://tests/court_eval/recording_voice.gd")
const Stack:=preload("res://scripts/hud/order_stack.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

## Stands in for the map and the HUD for the screens' own handlers.
class Host extends Control:
	var reports:Array=[]
	func _report_military_action(result:Dictionary)->void:reports.append(result)
	func request_immediate_dock_refresh()->void:pass
	func issue_civic_directive_text(_text:String)->void:pass


func before_test()->void:
	Fixtures.new(self).base(false)
	GameState.order_tracker={}


func after_test()->void:
	Tokens.set_color_mode("light")


func _newest()->Dictionary:
	return Tracker.orders()[0] if not Tracker.orders().is_empty() else {}


## Days pass for what these orders touch: the drill's own daily step (the
## whole world's day is far too slow for a unit test).
func _advance(days:int)->void:
	for i in days:
		GameState.elapsed_days+=1
		MilitaryCampaign._process_training_day()


func _speak(modal:Control,text:String)->void:
	modal.speech_input.text=text
	modal._speak()


func _court(voice:Node)->Control:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else (Hall.summonable()[0].target as Dictionary)
	var audience:=Hall.summon(target)
	var modal:Control=auto_free(Modal.new())
	modal.voice=voice;modal.audience_id=String(audience.id)
	add_child(modal)
	voice.drain(String(audience.id))
	modal._refresh_footer()
	return modal


func _offline_voice()->Node:
	var voice:Node=auto_free(RecordingVoice.new())
	voice.force_offline=true
	add_child(voice)
	return voice


# --------------------------------------------------------------------------
# Every way of giving an order gets a card
# --------------------------------------------------------------------------

func test_the_players_words_in_court_get_a_card_that_follows_the_levy()->void:
	var modal:=_court(_offline_voice())
	_speak(modal,"raise 20 soldiers")
	var card:=_newest()
	assert_bool(card.is_empty()).is_false()
	assert_str(String(card.words)).is_equal("Raise 20 levies")
	assert_str(String(card.source)).is_equal("court")
	assert_str(String(card.said)).is_equal("raise 20 soldiers")
	assert_bool(bool(card.claimed)).is_true()
	assert_str(String(card.kind)).is_equal("levy")
	assert_str(String(card.screen)).is_equal("military:2")
	assert_str(String(card.line)).contains("20 in drill")
	assert_str(String(card.state)).is_not_equal("nothing")


func test_an_office_button_order_gets_a_card()->void:
	var modal:=_court(_offline_voice())
	modal.office_order("Recruit 10 levies, train them and arm them")
	var card:=_newest()
	assert_str(String(card.get("words",""))).is_equal("Raise 10 levies")
	assert_str(String(card.kind)).is_equal("levy")


func test_court_words_no_mechanic_takes_are_red_at_once()->void:
	var modal:=_court(_offline_voice())
	modal.office_order("Send them!")
	var card:=_newest()
	assert_str(String(card.get("state",""))).is_equal("nothing")
	assert_str(String(card.line)).starts_with("Not carried out")
	# Days later it still says what happened to it.
	GameState.elapsed_days+=3
	Tracker.update()
	assert_str(String(Tracker.find(int(card.id)).line)).starts_with("Not carried out")


func test_the_army_screen_registers_its_orders()->void:
	var Orders:=preload("res://scripts/army_orders.gd")
	var before:=Tracker.orders().size()
	var answer:=Orders.give(Orders.HOME,"defend",{})
	assert_int(Tracker.orders().size()).is_equal(before+1)
	var card:=_newest()
	assert_str(String(card.source)).is_equal("army")
	assert_str(String(card.words)).is_equal("Defend home")
	assert_bool(bool(card.claimed)).is_true()
	assert_str(String(card.state)).is_not_equal("accepted")
	assert_str(String(card.get("who",""))).is_equal(String(answer.get("general","")))
	# A plan with nothing drawn is refused, on its card too.
	Orders.give_plan(Orders.HOME,{"kind":"none"})
	assert_str(String(_newest().state)).is_equal("refused")


func test_the_recruitment_board_registers_its_orders()->void:
	var board:Node=auto_free(preload("res://scripts/hud/recruit_deploy_board.gd").new())
	MilitaryCampaign._ensure_army_templates()
	var template:Dictionary=MilitaryCampaign.army_templates[0]
	var result:Dictionary=board.raise_bands(int(template.template_id),1,20,String(template.name))
	var card:=_newest()
	assert_str(String(card.source)).is_equal("recruit")
	assert_str(String(card.words)).starts_with("Raise a band of 20")
	if result.has("error"):
		assert_str(String(card.state)).is_equal("refused")
	else:
		assert_str(String(card.kind)).is_equal("recruit_line")
		assert_str(String(card.line)).contains("called up")


func test_the_workshop_buildings_defence_and_research_screens_register_orders()->void:
	var host:Host=auto_free(Host.new())
	add_child(host)
	var military:RefCounted=preload("res://scripts/hud/content/dock_content_military.gd").new(host,host)
	military._queue_supply_order("equipment","improvised",4)
	assert_str(String(_newest().source)).is_equal("production")
	assert_str(String(_newest().words)).starts_with("Make 4")
	military._start_line("improvised",6)
	assert_str(String(_newest().words)).starts_with("Keep 6")
	var production:RefCounted=preload("res://scripts/hud/content/dock_content_production.gd").new(host,host)
	production._start("improvised")
	assert_str(String(_newest().source)).is_equal("production")
	var construction:RefCounted=preload("res://scripts/hud/content/dock_content_construction.gd").new(host,host)
	construction._priority("Storage Pits")
	assert_str(String(_newest().source)).is_equal("buildings")
	assert_str(String(_newest().words)).is_equal("Build Storage Pits first")
	construction._set_defence_word("hold")
	assert_str(String(_newest().source)).is_equal("defences")
	assert_str(String(_newest().state)).is_equal("done")
	var inquiry:RefCounted=preload("res://scripts/hud/content/dock_content_inquiry.gd").new(host,host)
	var some:=String((DiscoverySystem.technology_catalog[0] as Dictionary).get("id",""))
	inquiry._research_technology(some)
	assert_str(String(_newest().source)).is_equal("research")
	assert_str(String(_newest().words)).starts_with("Research ")
	for o in Tracker.orders():
		assert_bool(String((o as Dictionary).state) in ["accepted","under_way","done","stalled","refused","nothing","called_off"]).is_true()
		assert_bool(bool((o as Dictionary).claimed) or String((o as Dictionary).state)=="nothing").override_failure_message("unclaimed: %s" % str(o)).is_true()


func test_a_later_word_on_the_same_subject_calls_off_the_earlier_card()->void:
	var host:Host=auto_free(Host.new())
	add_child(host)
	var construction:RefCounted=preload("res://scripts/hud/content/dock_content_construction.gd").new(host,host)
	construction._set_defence_word("build")
	var build:=int(_newest().id)
	construction._set_defence_word("hold")
	var earlier:=Tracker.find(build)
	# "Hold off" does not stand on top of "Build now": it calls it off.
	assert_str(String(earlier.state)).is_equal("called_off")
	assert_str(Stack.status_words(earlier)).is_equal("Called off · now: hold off new defences")
	for o in Tracker.orders():
		if String((o as Dictionary).source)=="defences" and int((o as Dictionary).id)!=build:assert_str(String((o as Dictionary).state)).is_equal("done")
	# A town's first work: the later choice replaces the earlier.
	construction._priority("Storage Pits")
	var pits:=int(_newest().id)
	construction._priority("")
	assert_str(String(Tracker.find(pits).state)).is_equal("called_off")


func test_an_older_saves_replaced_card_closes_when_next_read()->void:
	preload("res://scripts/home_defense.gd").set_word("hold")
	var id:=Tracker.register("Build the next defences now","defences")
	Tracker.claim(id,"defences",{"word":"build"},"Tam","construction")
	assert_str(String(Tracker.find(id).state)).is_equal("called_off")
	assert_str(String(Tracker.find(id).line)).is_equal("Replaced by your later word")


func test_a_days_progress_moves_the_card_where_it_stands()->void:
	var id:=Tracker.register("Build the next defences now","defences")
	var o:=Tracker.find(id)
	o.merge({"claimed":true,"kind":"settled","state":"under_way","line":"Walls rising · 10% · 30 days left","value":10,"total":100},true)
	var stack:Control=auto_free(Stack.new())
	add_child(stack)
	await get_tree().process_frame
	stack.rebuild()
	var card:Control=stack.cards.get_child(0)
	# A day's progress: the same card, new words (rebuilding shook the stack).
	o.merge({"line":"Walls rising · 11% · 29 days left","value":11},true)
	stack.rebuild()
	assert_object(stack.cards.get_child(0)).is_same(card)
	assert_str((card.find_child("OrderStatus",true,false) as Label).text).is_equal("Walls rising · 11% · 29 days left")
	# A new state builds the card again.
	o.merge({"state":"stalled","line":"Stalled: nobody is building"},true)
	stack.rebuild()
	assert_object(stack.cards.get_child(0)).is_not_same(card)


# --------------------------------------------------------------------------
# The card follows the ledger
# --------------------------------------------------------------------------

func test_a_levy_card_goes_called_up_then_drilling_then_done()->void:
	var id:=Tracker.register("Raise 20 levies","court","raise 20 soldiers")
	var done:=HO.perform(HO.read("raise 20 soldiers"))
	Tracker.from_home(id,done,"Rovik")
	var card:=Tracker.find(id)
	assert_str(String(card.kind)).is_equal("levy")
	assert_str(String(card.state)).is_equal("accepted")
	assert_str(String(card.line)).starts_with("20 in drill · fit in about")
	assert_int(int(card.total)).is_greater(0)
	_advance(2)
	Tracker.update()
	card=Tracker.find(id)
	assert_str(String(card.state)).override_failure_message(str(card)).is_equal("under_way")
	assert_int(int(card.value)).is_greater_equal(0)
	# The drill nearly over: the next day finishes it, and the card says so.
	var order:Dictionary={}
	for entry in MilitaryCampaign.training_queue:
		if int((entry as Dictionary).id)==int((card.refs as Dictionary).training_id):order=entry
	assert_bool(order.is_empty()).is_false()
	order["progress_days"]=float(order.required_days)-0.01
	Tracker.update()
	_advance(1)
	Tracker.update()
	card=Tracker.find(id)
	assert_str(String(card.state)).override_failure_message(str(card)).is_equal("done")
	assert_str(String(card.line)).is_equal("20 drilled and under arms at home")


func test_an_order_nobody_takes_turns_red_after_a_day()->void:
	var id:=Tracker.register("Whistle up the wind","court")
	Tracker.update()
	assert_str(String(Tracker.find(id).state)).is_equal("accepted")
	_advance(1)
	Tracker.update()
	assert_str(String(Tracker.find(id).state)).is_equal("accepted")
	_advance(1)
	Tracker.update()
	assert_str(String(Tracker.find(id).state)).is_equal("nothing")
	assert_str(String(Tracker.find(id).line)).is_equal("Nothing has happened yet: no one took this order")


func test_a_claimed_order_the_ledger_never_moves_turns_red_with_the_reason()->void:
	MilitaryCampaign.training_staff.set_policy("army","suspended")
	var id:=Tracker.register("Raise 5 levies","court")
	Tracker.from_home(id,HO.perform(HO.read("Recruit 5 levies")))
	_advance(2)
	Tracker.update()
	var card:=Tracker.find(id)
	assert_str(String(card.state)).override_failure_message(str(card)).is_equal("nothing")
	assert_str(String(card.line)).contains("training is suspended")
	MilitaryCampaign.training_staff.set_policy("army","regular")


func test_a_refusal_says_why_in_numbers()->void:
	MilitaryCampaign.raise_recruits(MilitaryCampaign.recruitment_capacity())
	MilitaryCampaign.start_training("levy","improvised",MilitaryCampaign.aggregate_recruits)
	var id:=Tracker.register("Raise 20 levies","court")
	Tracker.from_home(id,HO.perform(HO.read("raise 20 soldiers")))
	var card:=Tracker.find(id)
	assert_str(String(card.state)).is_equal("refused")
	assert_str(String(card.line)).contains("0 of 20 called up")


# --------------------------------------------------------------------------
# Saved, bounded; older saves load with none
# --------------------------------------------------------------------------

func test_the_ledger_is_saved_and_older_saves_load_with_none()->void:
	var id:=Tracker.register("Raise 20 levies","court")
	Tracker.from_home(id,HO.perform(HO.read("raise 20 soldiers")))
	var saved:=preload("res://scripts/save_system.gd")._capture_reflected(GameState,[])
	assert_bool(saved.has("order_tracker")).is_true()
	GameState.reset_for_new_world(int(GameState.world_seed))
	assert_bool(Tracker.orders().is_empty()).is_true()
	preload("res://scripts/save_system.gd")._apply_reflected(GameState,saved)
	assert_str(String(Tracker.find(id).get("words",""))).is_equal("Raise 20 levies")
	assert_str(String(Tracker.find(id).get("kind",""))).is_equal("levy")
	# An older save has no ledger: it loads with none, never the last game's.
	var older:=saved.duplicate(true);older.erase("order_tracker")
	GameState.reset_for_new_world(int(GameState.world_seed))
	preload("res://scripts/save_system.gd")._apply_reflected(GameState,older)
	assert_bool(Tracker.orders().is_empty()).is_true()


func test_the_ledger_is_bounded()->void:
	for i in 50:Tracker.register("Order %d" % i,"court")
	assert_int(Tracker.orders().size()).is_equal(Tracker.MAX_ORDERS)
	assert_str(String(_newest().words)).is_equal("Order 49")
	# Finished long ago: dropped.
	GameState.order_tracker={}
	var old:=Tracker.register("Old order","court")
	Tracker.done(old,"Done")
	Tracker.find(old)["ended_day"]=int(GameState.elapsed_days)-Tracker.KEEP_FINISHED_DAYS-1
	Tracker.update()
	assert_bool(Tracker.find(old).is_empty()).is_true()


# --------------------------------------------------------------------------
# The cards: short, readable, newest first, at most four
# --------------------------------------------------------------------------

func _sample_orders()->void:
	var levy:=Tracker.register("Raise 20 levies","court","raise 20 soldiers","Corvan of the Birch Stand")
	Tracker.from_home(levy,HO.perform(HO.read("raise 20 soldiers")))
	var gone:=Tracker.register("Whistle up the wind","court")
	Tracker.nothing(gone,"Nothing has happened yet: no one took this order")
	var no:=Tracker.register("Attack Tsaren","army")
	Tracker.refuse(no,"We have nobody trained to send: drill a levy first, about 45 days")
	var made:=Tracker.register("Keep 10 clubs in store","production")
	Tracker.done(made,"10 clubs in store, as asked")
	var stalled:=Tracker.register("Build Storage Pits first","buildings")
	Tracker.find(stalled).merge({"claimed":true,"state":"stalled","line":"Stalled: nobody is building","value":30,"total":100},true)


func test_every_card_line_is_short_and_reads_in_light_and_dark()->void:
	_sample_orders()
	for o in Tracker.orders():
		var order:Dictionary=o
		for text in [String(order.words),String(order.line),Stack.status_words(order)]:
			var words:=0
			for token in text.split(" ",false):
				if Tracker._wordlike(String(token)):words+=1
			assert_int(words).override_failure_message("too long: '%s'" % text).is_less_equal(Tracker.MAX_WORDS)
	for mode in ["light","dark"]:
		Tokens.set_color_mode(mode)
		for state in ["accepted","under_way","done","stalled","refused","nothing"]:
			var ground:=Tokens.PANEL_BG_SOLID.lerp(Tokens.RED,0.10) if state=="nothing" else Tokens.PANEL_BG_SOLID
			var ink:=Tokens.text_for(Stack.state_colour(state)) if state!="accepted" else Tokens.BODY_2
			assert_float(Tokens.contrast(ink,ground)).override_failure_message("%s text on %s paper: %.2f" % [state,mode,Tokens.contrast(ink,ground)]).is_greater_equal(4.5)
			assert_float(Tokens.contrast(Tokens.INK,ground)).is_greater_equal(4.5)
			assert_float(Tokens.contrast(Tokens.MUTED,ground)).is_greater_equal(4.5)


func test_the_stack_shows_the_newest_four_and_all_on_a_click()->void:
	_sample_orders()
	for i in 3:Tracker.register("Extra order %d" % i,"court")
	var stack:Control=auto_free(Stack.new())
	add_child(stack)
	await get_tree().process_frame
	stack.rebuild()
	assert_int(stack.cards.get_child_count()).is_equal(Stack.MAX_VISIBLE)
	var first:Control=stack.cards.get_child(0)
	assert_int(int(first.get_meta("order_id"))).is_equal(int(_newest().id))
	stack.toggle_all()
	assert_bool(stack.all_panel.visible).is_true()
	assert_int(stack.all_rows.get_child_count()).is_equal(Tracker.orders().size())
	# The red card says NOTHING HAS HAPPENED in so many words.
	GameState.order_tracker={}
	var gone:=Tracker.register("Whistle up the wind","court")
	Tracker.nothing(gone,"Nothing has happened yet: no one took this order")
	stack.rebuild()
	var card:Control=stack.cards.get_child(0)
	assert_str((card.find_child("OrderAlarm",true,false) as Label).text).is_equal("NOTHING HAS HAPPENED")
	assert_str((card.find_child("OrderStatus",true,false) as Label).text).is_equal("No one took this order")
	assert_str(stack.caption.text).contains("1 NOT CARRIED OUT")
	# A finished card fades after its few seconds.
	var made:=Tracker.register("Keep 10 clubs in store","production")
	Tracker.done(made,"10 clubs in store, as asked")
	stack.rebuild()
	assert_int(int(stack.cards.get_child(0).get_meta("order_id"))).is_equal(made)
	stack._done_seen[made]=Time.get_ticks_msec()-Stack.DONE_SHOW_MS-5000
	stack.rebuild()
	for child in stack.cards.get_children():
		assert_int(int(child.get_meta("order_id"))).is_not_equal(made)


func test_a_click_opens_the_screen_where_the_order_lives()->void:
	var id:=Tracker.register("Raise 20 levies","court")
	Tracker.from_home(id,HO.perform(HO.read("raise 20 soldiers")))
	var stack:Control=auto_free(Stack.new())
	add_child(stack)
	await get_tree().process_frame
	var opened:Array=[]
	stack.open_requested.connect(func(screen:String)->void:opened.append(screen))
	var card:Control=stack.cards.get_child(0)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	card.gui_input.emit(click)
	assert_array(opened).is_equal(["military:2"])


# --------------------------------------------------------------------------
# Where the cards stand: bottom right, the council's matters above them, and
# a single line at the top right while a dock covers the bottom right
# --------------------------------------------------------------------------

class OrdersHud extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:
		_build_decision_queue()
		dock=PanelContainer.new();dock.visible=false;add_child(dock)
		detail_dock=PanelContainer.new();detail_dock.visible=false;add_child(detail_dock)
		_build_order_stack()
	func _layout()->void:_layout_orders()


func test_the_cards_stand_bottom_right_and_give_way_to_a_dock()->void:
	_sample_orders()
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,720);add_child(canvas)
	var hud:Control=auto_free(OrdersHud.new());canvas.add_child(hud)
	for i in 3:await get_tree().process_frame
	hud.order_stack.rebuild()
	hud._layout_orders()
	for i in 4:await get_tree().process_frame
	var stack:Control=hud.order_stack
	var rect:=Rect2(stack.position,stack.get_combined_minimum_size())
	assert_bool(bool(stack.compact)).is_false()
	assert_float(rect.end.x).is_equal_approx(1280.0-Tokens.EDGE_MARGIN,1.0)
	assert_float(rect.end.y).is_equal_approx(720.0-Tokens.EDGE_MARGIN,1.0)
	assert_float(rect.position.x).is_greater(Tokens.RAIL_WIDTH)
	assert_float(hud.orders_top()).is_less_equal(rect.position.y)
	# A dock reaching the bottom right: the cards become one line at the top.
	hud.dock.position=Vector2(Tokens.DOCK_X,64);hud.dock.size=Vector2(1180,640);hud.dock.visible=true
	hud._layout_orders()
	await get_tree().process_frame
	assert_bool(bool(stack.compact)).is_true()
	assert_float(stack.position.y).is_equal(8.0)
	assert_bool(stack.cards.visible).is_false()
	assert_bool(stack.plate.visible).is_true()
	hud.dock.visible=false
	hud._layout_orders()
	assert_bool(bool(stack.compact)).is_false()


## The court's levy puts a batch of weapons in hand; the workshop officer's
## daily review once broke on it (a batch has no stock target to raise) and
## stopped scheduling for the day. It leaves the batch to its work.
func test_the_workshop_officer_leaves_the_courts_batch_alone()->void:
	MilitaryCampaign.equipment_queue.clear()
	var batch:=MilitaryCampaign.queue_equipment_production("improvised",4)
	assert_bool(batch.has("error")).is_false()
	var said:Variant=MilitaryCampaign.workshop.schedule({"item":"improvised","target":6,"gear":true})
	assert_bool(said is Dictionary).is_true()
	assert_str(String((said as Dictionary).get("message",""))).contains("batch")


## A town's overseer takes the levy through the council's path (court_commands
## _order -> custom_order): the card still follows the levy itself, never a
## bare "takes up your order" marked done.
func test_a_levy_given_to_a_town_overseer_is_followed_in_the_ledger()->void:
	var audience:=Hall.summon(Hall.summonable()[0].target as Dictionary)
	var sid:=String((GameState.player_settlements[0] as Dictionary).get("id","")) if not GameState.player_settlements.is_empty() else ""
	var overseer:={"key":"overseer","kind":"official","name":"Sirra of Reedwater","office_key":"settlement","settlement_id":sid,"person_id":0}
	var r:=CC._result("order",overseer,{},"raise 20 soldiers",false)
	r=CC._order(String(audience.id),audience,r,overseer,"raise 20 soldiers",{})
	assert_str(String(r.get("route",""))).is_equal("home")
	var card:=Tracker.register("Raise 20 levies","court","raise 20 soldiers","Sirra of Reedwater")
	Tracker.from_court(card,r)
	assert_str(String(Tracker.find(card).kind)).is_equal("levy")
	assert_str(String(Tracker.find(card).line)).starts_with("20 in drill")


func test_an_order_whose_band_is_gone_ends_and_clears_instead_of_stalling_forever()->void:
	var id:=Tracker.register("Attack Felik with 400 men","army")
	Tracker.claim(id,"march",{"army_id":987654,"kind":"attack","start_day":int(GameState.elapsed_days)},"Fitha","military")
	# The band was moving once, then was lost: an older save holds it stalled.
	var card:=Tracker.find(id)
	card["state"]="stalled";card["ever_moved"]=true
	GameState.elapsed_days+=1
	Tracker.update()
	card=Tracker.find(id)
	assert_str(String(card.state)).is_equal("refused")
	assert_str(String(card.line)).contains("disbanded or lost")
	# Off the stack the next day, out of the ledger once old.
	GameState.elapsed_days+=2
	assert_bool(Tracker.current().any(func(o:Dictionary)->bool:return int(o.id)==id)).is_false()
	GameState.elapsed_days+=Tracker.KEEP_FINISHED_DAYS+1
	Tracker.update()
	assert_bool(Tracker.find(id).is_empty()).is_true()
