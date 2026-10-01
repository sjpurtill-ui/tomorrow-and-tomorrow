extends Node
## TEST CAPTURE (not the game): the fail-safe order cards at the bottom right
## of the real HUD, over the real map, in light or dark. Gives orders through
## the real entry points (the court's levy, the Army screen, a workshop line),
## leaves one untaken so it turns red, then captures: the map with the stack,
## the stack with every order shown, a dock open (the stack shrinks to its
## one-line plate at the top right) and the court open (the cards stand in
## its right margin when there is room). Prints every rect it checks so an
## overlap with the rail, the toolbar, the army bar, the docks or the court
## is a printed failure. Isolated userdata only (override.cfg); never saves.
##   run through tools/run_isolated_gpu_probe.ps1 with
##   -UserArguments "--out=<dir> [--dark]"
## Quits by itself: ORDER_STACK_CAPTURE DONE (exit 0) or ... FAIL (exit 1).

const Tracker:=preload("res://scripts/order_tracker.gd")
const HO:=preload("res://scripts/home_orders.gd")
const Orders:=preload("res://scripts/army_orders.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

var terrain:Node
var out_dir:=""
var tag:="light"
var failures:Array[String]=[]

func _ready()->void:
	if not OS.get_user_data_dir().get_file().contains("Test"):
		print("ORDER_STACK_CAPTURE refuses to run outside a test user directory")
		get_tree().quit(2);return
	get_tree().create_timer(170.0).timeout.connect(func()->void:
		print("ORDER_STACK_CAPTURE FAIL timed out")
		get_tree().quit(1))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out_dir=a.substr(6)
		if a=="--dark":tag="dark"
	if out_dir=="":out_dir=OS.get_user_data_dir()+"/order_stack_capture/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	# The paper colour the game reads at start (display_preferences.gd), in
	# this test user directory only.
	var settings:=ConfigFile.new()
	settings.load(load("res://scripts/display_preferences.gd").SETTINGS_PATH)
	settings.set_value("display","color_theme",tag)
	settings.save(load("res://scripts/display_preferences.gd").SETTINGS_PATH)
	if tag=="dark":
		Tokens.set_color_mode("dark")
		get_tree().root.theme=Tokens.control_theme()
	GameState.reset_for_new_world(424242)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(30)
	PeopleDirection.choose("makers")
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(10)
	terrain._start_settlement_here()
	await _frames(10)
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	terrain._set_game_speed(5)
	for i in 90:
		terrain.advance_world_time(1.0)
		_release()
		if i%10==0:await get_tree().process_frame
	terrain._set_game_speed(0)
	await _frames(20)
	_give_orders()
	var hud:Node=terrain.hud
	hud.refresh_information_bar()
	await _frames(20)
	hud._layout()
	await _frames(6)
	_check("map",hud)
	await _cap("%s-map" % tag)
	hud.order_stack.toggle_all()
	await _frames(6)
	hud._layout()
	await _frames(3)
	_check("all",hud)
	await _cap("%s-all-orders" % tag)
	hud.order_stack.toggle_all()
	# A dock open: the cards give way to the one-line plate at the top right.
	hud.section_requested.emit("construction",0)
	await _frames(20)
	hud._layout()
	await _frames(6)
	_check("dock",hud)
	await _cap("%s-dock-open" % tag)
	hud.section_requested.emit("",0)
	await _frames(10)
	# The court open: the cards stand in its right margin, or out of its way.
	hud.open_court()
	await _frames(30)
	hud._sync_order_layer()
	hud._layout()
	await _frames(6)
	_check("court",hud)
	await _cap("%s-court-open" % tag)
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.modal):dir.modal.queue_free()
	await _frames(4)
	if failures.is_empty():print("ORDER_STACK_CAPTURE DONE %s" % tag)
	else:
		for f in failures:print("ORDER_STACK_CAPTURE FAIL ",f)
	get_tree().quit(0 if failures.is_empty() else 1)

## Orders through the real entry points, and one nobody takes.
func _give_orders()->void:
	var leader:=Tracker._war_leader()
	var untaken:=Tracker.register("Whistle up the wind","court","whistle up the wind",leader)
	Tracker.find(untaken)["day"]=int(GameState.elapsed_days)-3
	var line:=MilitaryCampaign.start_production_line("improvised",6)
	Tracker.workshop_order("Keep 6 clubs in store",line,"improvised",6,true)
	Orders.give(Orders.HOME,"attack",{})
	var levy:=Tracker.register("Raise 20 levies","court","raise 20 soldiers",leader)
	Tracker.from_home(levy,HO.perform(HO.read("raise 20 soldiers")))
	Tracker.update()
	for o in Tracker.orders():print("ORDER %s | %s | %s | %s | %s" % [String(o.words),String(o.state),String(o.line),String(o.get("who","")),String(o.screen)])

func _check(stage:String,hud:Node)->void:
	var view:=get_viewport().get_visible_rect().size
	var stack:Control=hud.order_stack
	var rect:=stack.get_global_rect()
	print("ORDER_STACK %s view=%s stack=%s compact=%s visible=%s layer=%d" % [stage,view,rect,str(stack.compact),str(stack.is_visible_in_tree()),int(hud.order_layer.layer)])
	if not stack.is_visible_in_tree():
		if stage!="court":failures.append("%s: the stack is hidden" % stage)
		return
	if not Rect2(Vector2.ZERO,view).encloses(rect):failures.append("%s: the stack is off the screen %s" % [stage,rect])
	var others:={"rail":hud.rail_panel,"toolbar":hud.toolbar,"queue":hud.queue_root,"dock":hud.dock,"detail":hud.detail_dock,"kpi":hud.kpi_strip,"time":hud.time_pill}
	for key in others:
		var other:Control=others[key]
		if other==null or not other.is_visible_in_tree():continue
		if key=="queue" and other.get_child_count()==0:continue
		var o:=other.get_global_rect()
		print("ORDER_STACK %s %s=%s" % [stage,key,o])
		if o.intersects(rect.grow(-1.0)):failures.append("%s: the stack covers the %s (%s over %s)" % [stage,key,rect,o])
	var bar:Control=hud.army_bar
	if bar!=null and bar.is_visible_in_tree():
		var cards:Rect2=Rect2(bar.position,Vector2(bar.size.x,bar.size.y))
		print("ORDER_STACK %s army_bar=%s" % [stage,cards])
	if stage=="court":
		var court:=Vector2(minf(1280.0,view.x-40.0),minf(820.0,view.y-40.0))
		var card:=Rect2((view-court)*0.5,court)
		print("ORDER_STACK court card=%s" % card)
		if card.intersects(rect.grow(-1.0)):failures.append("court: the stack covers the court (%s over %s)" % [rect,card])

func _release()->void:
	if terrain.game_speed<=0.0:
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
		terrain._set_game_speed(5)
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.modal):
		dir.modal.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())

func _frames(k:int)->void:
	for i in k:await get_tree().process_frame

func _cap(label:String)->void:
	await RenderingServer.frame_post_draw
	var p:=out_dir.path_join(label+".png")
	get_viewport().get_texture().get_image().save_png(p)
	print("ORDER_STACK capture ",p)
