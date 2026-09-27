extends CanvasLayer
## After the home falls: who can still get away, where the survivors are, and
## how the occupied cities stand. Plain choices with sensible sizes, each
## confirmed once. Anything more is said to the leaders in court.
const T=preload("res://scripts/hud/hud_tokens.gd")
const P=preload("res://scripts/hud/paper_sheet.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
## Share of the people readied to flee, and the days of food they carry.
const FLEE_SHARE:=.15
const FLEE_DAYS:=45
const EFFECTS:={"protect":"Look after the people there; more of them come to want us back.","institutions":"Keep their own ways of running things alive.","organize":"Win more of them to our side. The occupiers grow more suspicious.","outside_help":"Ask friendly peoples for help. They may say no, and the occupiers notice.","autonomy":"Ask to be let go. Needs nearly half the people behind us.","revolt":"Rise up. Needs more than half behind us; failing costs lives and brings a harder hand."}
var root:Control
var body:VBoxContainer
var summary:Label
var feedback:Label
var survivors:Label
var occupied:Label
var escape_box:VBoxContainer
var cities_box:VBoxContainer
var decision:VBoxContainer
var decision_text:Label
var decision_commit:Button
var pending:Callable
var heading:="north"
var poll:float=0
var signature:=""

static func open()->void:
	var tree_root:Node=Engine.get_main_loop().root
	if tree_root.has_meta("recovery_view") and is_instance_valid(tree_root.get_meta("recovery_view")):return
	var view=load("res://scripts/hud/recovery_screen.gd").new();tree_root.set_meta("recovery_view",view);tree_root.add_child.call_deferred(view)

func _ready()->void:
	layer=79
	root=Control.new();add_child(root)
	var sheet:=P.modal(root,"After the fall","Recovery briefing",Vector2(720,860),queue_free)
	summary=P.label(sheet,"","body",T.BODY)
	body=P.scroll_body(sheet,12)
	P.kicker(body,"Those who can still get away")
	escape_box=VBoxContainer.new();escape_box.add_theme_constant_override("separation",6);body.add_child(escape_box)
	P.kicker(body,"The survivors on the road")
	survivors=P.label(body,"","body",T.BODY)
	P.kicker(body,"Our cities under their rule")
	occupied=P.label(body,"","body",T.BODY)
	cities_box=VBoxContainer.new();cities_box.add_theme_constant_override("separation",6);body.add_child(cities_box)
	decision=VBoxContainer.new();decision.add_theme_constant_override("separation",8);sheet.add_child(decision);decision.visible=false
	P.rule(decision)
	decision_text=P.label(decision,"","body",T.INK)
	var confirm:=HBoxContainer.new();confirm.add_theme_constant_override("separation",8);decision.add_child(confirm)
	decision_commit=P.button(confirm,"Yes, do it",_commit,true)
	P.button(confirm,"Not now",func():decision.hide();pending=Callable())
	var talk:=P.button(sheet,"Talk it over in court",func():queue_free();P.summon({}))
	talk.tooltip_text="Anything else you want done, tell your people in court."
	feedback=P.label(sheet,"","small",T.BODY)
	_refresh()

func _commit()->void:
	var action:=pending
	decision.hide();pending=Callable()
	if action.is_valid():action.call()

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	poll+=delta
	if poll>=.5:poll=0;_refresh()

static func _share_words(value:float)->String:
	return "almost none" if value<.1 else "a few" if value<.3 else "some" if value<.5 else "most" if value<.8 else "nearly all"

func _refresh()->void:
	var data:Dictionary=MilitaryCampaign.recovery.snapshot()
	var prepared:Dictionary=data.preparation
	var group:Dictionary=data.remnant
	summary.text="Our people and their story go on. Some may slip away to build again; the cities taken from us may yet be won back. Neither is certain."
	var cities:Array=[]
	for entry:Dictionary in data.occupied:cities.append("%s:%s:%s" % [entry.city_id,entry.get("liberated",false),not (entry.order as Dictionary).is_empty()])
	var next:=JSON.stringify([prepared,group.get("phase",""),cities,heading])
	if next!=signature:
		signature=next
		_escape_actions(prepared,group)
		_city_actions(data.occupied)
	survivors.text="No group is on the road." if group.is_empty() else "%s survivors from %s are %s; they have come %s of the way to a new site. Their food lasts about %s. They carry what they know; what they left behind stays behind." % [EraWords.grouped(int(group.people)),String(group.origin_name),String(group.phase).replace("_"," "),_share_words(float(group.get("traveled",0))/maxf(1.0,float(group.get("distance",1)))),EraWords.days(float(group.food)/maxf(1,float(group.people)))]
	occupied.text="None of our cities are held by others." if data.occupied.is_empty() else ""
	occupied.visible=occupied.text!=""

func _escape_actions(prepared:Dictionary,group:Dictionary)->void:
	for child in escape_box.get_children():escape_box.remove_child(child);child.queue_free()
	if not group.is_empty():
		P.label(escape_box,"The group that fled is already on its way. Send them looking for a place to rebuild; they head %s." % heading,"body",T.BODY)
		_direction_row(escape_box)
		P.button(escape_box,"Look for a place to rebuild",_seek,true)
		return
	if prepared.is_empty():
		P.label(escape_box,"No one is getting ready to flee. A group set aside now eats its own food each day and no longer works on the defences.","body",T.BODY)
		P.button(escape_box,"Ready a group to flee",_prepare,true)
		return
	P.label(escape_box,"%s people are ready to flee with food for about %s. Our defences are %d%% weaker while they wait." % [EraWords.grouped(int(prepared.people)),EraWords.days(float(prepared.food)/maxf(1,float(prepared.people))),roundi((1-MilitaryCampaign.recovery.defense_factor())*100)],"body",T.BODY)
	P.label(escape_box,"Which way should they go? Now: %s." % heading,"small",T.BODY)
	_direction_row(escape_box)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);escape_box.add_child(row)
	P.button(row,"Lead them out",_escape,true)
	P.button(row,"Stand them down",_cancel)

func _direction_row(parent:Node)->void:
	var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",4);grid.add_theme_constant_override("v_separation",4);parent.add_child(grid)
	for direction:String in CivilizationSystem.SCOUT_HEADINGS:
		var button:=P.button(grid,direction.capitalize(),_set_heading.bind(direction))
		if direction==heading:button.add_theme_stylebox_override("normal",T.button_pressed_style())

func _set_heading(direction:String)->void:
	heading=direction;signature="";_refresh()

func _city_actions(entries:Array)->void:
	for child in cities_box.get_children():cities_box.remove_child(child);child.queue_free()
	for entry:Dictionary in entries:
		var city:=String(entry.city_id)
		var card:=P.card(cities_box,T.GOLD)
		P.label(card,String(SettlementModel.settlement_record(city).get("name",city)),"value",T.INK)
		var gov:Dictionary=entry.region.governance
		if bool(entry.get("liberated",false)):
			P.label(card,"It is ours again.","body",T.BODY);continue
		P.label(card,"%s of its people want us back. The occupiers are %s, and their hand is %s. Last word from there came in %s." % [_share_words(float(gov.support)).capitalize(),"deeply suspicious" if float(gov.suspicion)>.6 else "watchful" if float(gov.suspicion)>.3 else "at ease","heavy" if float(gov.repression)>.6 else "firm" if float(gov.repression)>.3 else "light",EraWords.when(int(entry.last_report_day))],"body",T.BODY)
		if not (entry.order as Dictionary).is_empty():
			P.label(card,"Our people there are at work on what we asked; it cannot be done before %s." % EraWords.when(int(entry.order.resolve_day)),"small",T.BODY);continue
		var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);card.add_child(grid)
		for order:String in MilitaryCampaign.recovery.ORDERS:
			var button:=P.button(grid,String(MilitaryCampaign.recovery.ORDERS[order]),_resistance.bind(order,city))
			button.tooltip_text=String(EFFECTS.get(order,""))

func _show(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Done.")));signature="";_refresh()
func _prepare()->void:
	var people:=clampi(roundi(float(GameState.population_total)*FLEE_SHARE),2,1000000)
	_review("Ready %s people to flee?" % EraWords.grouped(people),"They set aside food for %d days and stop working on the defences." % FLEE_DAYS,func():_show(MilitaryCampaign.recovery.prepare(people,FLEE_DAYS)))
func _escape()->void:
	var direction:=heading
	_review("Lead them out to the %s?" % direction,"The siege lines, how ready they are and how much food they carry decide who gets through. Some may be lost.",func():_show(MilitaryCampaign.recovery.escape(direction)))
func _cancel()->void:_show(MilitaryCampaign.recovery.cancel_preparation())
func _seek()->void:_show(MilitaryCampaign.recovery.seek_site(heading))
func _resistance(order:String,city:String="")->void:
	if city=="":
		var entries:Array=MilitaryCampaign.recovery.data.occupied
		if entries.is_empty():return
		city=String(entries[0].city_id)
	_review("%s?" % String(MilitaryCampaign.recovery.ORDERS[order]),"%s It takes about a month once word reaches them, and uses the city's own food." % String(EFFECTS.get(order,"")),func():_show(MilitaryCampaign.recovery.queue_resistance(city,order)))
func _review(title:String,explanation:String,action:Callable)->void:
	decision.show();decision_text.text=title+"\n"+explanation;pending=action
