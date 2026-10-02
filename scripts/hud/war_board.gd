extends VBoxContainer
## THE WAR SCREEN, laid out as HOI4 lays out war: the map is the screen, and
## the war reads at a glance around its edges. Grand strategy: the ruler
## decides how many serve, who leads, and a stance toward each enemy; the war
## leader and the generals do the rest (who goes, the road, the camps, the
## pace, the fight). Nothing here moves a band or draws a line.
##   the strip   along the top, under the clock (WarStrip, top level): the
##               soldiers against the share kept, the army's size (a plain
##               share that reads the same for 120 people and a billion:
##               army_levy_law.gd), one in how many taken from work, pay,
##               armed and fed. Icons and numbers;
##   the column  this board, in the narrow panel at the right edge
##               (military_roster_screen.gd): one card per people at feud or
##               war (who is winning, the dead, what is happening now, the
##               stance), the leaders as portrait cards, and the spies,
##               folded;
##   the bar     the army bar along the bottom (hud/army_bar.gd), shown with
##               this screen even with no band out: the levy at home, then
##               every band, army and garrison.
## The sentences live in the tooltips.

signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const LedgerMarks:=preload("res://scripts/hud/war_ledger_marks.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const Orders:=preload("res://scripts/army_orders.gd")
const Commands:=preload("res://scripts/leader_commands.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const Strips:=preload("res://scripts/hud/force_strips.gd")
const GeneralRecord:=preload("res://scripts/general_record.gd")
const Forces:=preload("res://scripts/hud/war_forces_model.gd")
const CovertBoard:=preload("res://scripts/hud/covert_board.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const REFRESH_SECONDS:=1.0
## The stances, in the order the row shows them: [id, label, war_loop objective, tip].
const STANCES:=[
	["leave","Leave them be","war_let","Bury the dead and let it pass this year. Their grudge cools, unless they are the kind to come back bolder."],
	["defend","Defend","war_guard","Keep a watch on the approaches for half a year. Their raiders meet our fighters, not our fields."],
	["punish","Punish","war_burn","Send a band to burn their stores. If no one knows where they live, they track the raiders home first."],
	["take","Take a town","","March on a town of theirs and take it. The war leader chooses who goes and how; you choose the town."],
	["peace","Seek peace","war_parley","Send two messengers to ask for an end to it."],
]
## Each stance's word on its button and its mark (resource_icons command_glyph).
const SHORT:={"leave":"Leave","defend":"Defend","punish":"Punish","take":"Take","peace":"Peace"}
const MARKS:={"leave":"leave","defend":"defend","punish":"raid","take":"besiege","peace":"peace","pay":"price"}
## The layout the HUD and the roster screen share: the column's width (the
## council queue's, so the right edge reads as one column), and where the
## strip stands under the clock.
const COLUMN_WIDTH:=400.0
const STRIP_TOP:=62.0
const STRIP_HEIGHT:=50.0
## The strip's chips that can give way when the screen is narrow; those
## that warn of something (unpaid, short of gear, hungry) give way last
## (shed_order).
const SHED_ORDER:=["Watch","DrawnFrom","Pay","Armed","Fed"]

var strip:PanelContainer
var army_box:HBoxContainer
var enemy_box:VBoxContainer
var leader_box:VBoxContainer
var enemy_count:Label
var feedback:Label
var covert:Control
var covert_toggle:Button
var clock:=0.0
var _strip_room:=-1.0
## The chips in the order they give way, the quiet ones first.
var _shed:Array=SHED_ORDER.duplicate()
## Each section's last signature, and how long a rebuild has waited on the
## ruler's hand (seconds).
var signatures:={}
var waited:={}
## A section under the pointer waits this long for the pointer to leave
## before its numbers are read again; never while one of its menus is open
## or a button is held.
const HOVER_HOLD_SECONDS:=5.0


func setup(_block:Dictionary={})->void:
	name="WarBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",10)
	_build_strip()
	feedback=_line("",13,T.GOLD_TEXT,true);feedback.name="Said";feedback.visible=false;feedback.max_lines_visible=3;add_child(feedback)
	var enemies_head:=_kicker_row("Enemies")
	enemy_count=enemies_head.get_meta("count")
	enemy_box=VBoxContainer.new();enemy_box.name="Enemies";enemy_box.add_theme_constant_override("separation",8);add_child(enemy_box)
	var leaders_head:=_kicker_row("Leaders")
	var name_one:=_small_button("General","plus","Raise one of our people to lead bands as a general. The war council gives them work against an enemy; you can name who leads against each people.")
	name_one.name="NameGeneral";name_one.pressed.connect(_name_general);leaders_head.add_child(name_one)
	leader_box=VBoxContainer.new();leader_box.name="Leaders";leader_box.add_theme_constant_override("separation",6);add_child(leader_box)
	# Spies and assassins (covert_board.gd): folded until asked for; it only
	# informs, the god gives covert orders at court.
	covert_toggle=Button.new();covert_toggle.name="CovertToggle";covert_toggle.flat=true;covert_toggle.focus_mode=Control.FOCUS_NONE
	covert_toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT;covert_toggle.add_theme_font_override("font",T.font("ui_strong"));covert_toggle.add_theme_font_size_override("font_size",12)
	for state:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:covert_toggle.add_theme_color_override(state,T.INK_MUTED)
	covert_toggle.tooltip_text="Our agents abroad, what they have learned and the spies of theirs we caught. Covert orders are given at court."
	add_child(covert_toggle)
	covert=CovertBoard.new();covert.name="CovertBoard";add_child(covert);covert.setup();covert.visible=false
	covert_toggle.pressed.connect(func()->void:covert.visible=not covert.visible;_spies_words())
	_spies_words()
	refresh(true)


func _process(delta:float)->void:
	_place_strip()
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## Each section is read again only when what it shows has changed, and not
## under the ruler's hand: a menu of it open, a button held, or the pointer
## on it (for a few seconds). After the ruler's own word (force) all three.
func refresh(force:=false)->void:
	var reading:=Law.reading(MilitaryCampaign)
	var glance:=strength(MilitaryCampaign)
	_rebuild("army",army_box,str([reading,glance,pay_words(),Forces.drawn_from(MilitaryCampaign)]),force,func()->void:_build_army(reading,glance))
	var entries:=Ledger.entries().filter(func(e:Dictionary)->bool:return String(e.kind)!="ended")
	_rebuild("enemies",enemy_box,str(entries.map(func(e:Dictionary)->Array:
		var front:Dictionary=WarLoop.front(String(e.civ_id))
		return [e.civ_id,e.kind,e.hot,e.our_dead,e.their_dead,e.get("quiet",0),front.get("stance",""),front.get("general",""),e.get("strength",1.0),now_words(e)])),force,func()->void:_build_enemies(entries))
	var commands:=Commands.commands(MilitaryCampaign)
	_rebuild("leaders",leader_box,str(commands.map(func(c:Dictionary)->Array:return [c.id,c.bands,c.men,c.full,c.hungry,snappedf(float(c.will),0.05),snappedf(float(c.supply),0.05)])),force,func()->void:_build_leaders(commands))
	if force or clock==0.0:_spies_words()


func _rebuild(key:String,box:Control,next:String,force:bool,build:Callable)->void:
	if not force and next==String(signatures.get(key,"")):
		waited.erase(key)
		return
	if not force and _in_use(box,float(waited.get(key,0.0))):
		waited[key]=float(waited.get(key,0.0))+REFRESH_SECONDS
		return
	signatures[key]=next
	waited.erase(key)
	build.call()


## Whether the ruler is using a section: one of its menus open or a button
## held on it always; the pointer resting on it, for HOVER_HOLD_SECONDS.
func _in_use(box:Control,waited_seconds:float)->bool:
	if box==null or not box.is_visible_in_tree():return false
	for node in box.find_children("*","",true,false):
		if node is MenuButton and (node as MenuButton).get_popup().visible:return true
		if node is OptionButton and (node as OptionButton).get_popup().visible:return true
	if not box.get_global_rect().has_point(box.get_global_mouse_position()):return false
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or waited_seconds<HOVER_HOLD_SECONDS


# --- The strip: HOI4's top bar for the army --------------------------------

func _build_strip()->void:
	strip=PanelContainer.new();strip.name="WarStrip";strip.top_level=true;strip.mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=T.paper_panel_style(true,T.RADIUS_CARD,0.0)
	style.border_color=T.RULE_STRONG;style.content_margin_left=12.0;style.content_margin_right=12.0;style.content_margin_top=4.0;style.content_margin_bottom=4.0
	style.shadow_color=Color(0,0,0,0.16 if T.is_light() else 0.4);style.shadow_size=5;style.shadow_offset=Vector2(0,2)
	strip.add_theme_stylebox_override("panel",style)
	army_box=HBoxContainer.new();army_box.name="Army";army_box.add_theme_constant_override("separation",10);army_box.alignment=BoxContainer.ALIGNMENT_BEGIN
	strip.add_child(army_box)
	add_child(strip)


## Under the clock, from the rail's dock edge to the column. On a narrow
## screen the words under the numbers go first, then the least pressing
## chips (SHED_ORDER); the soldiers and the army size always stay.
func _place_strip()->void:
	if strip==null or not is_inside_tree():return
	var view:=get_viewport().get_visible_rect().size
	var room:=maxf(240.0,view.x-T.EDGE_MARGIN-COLUMN_WIDTH-12.0-T.DOCK_X)
	if room!=_strip_room:_strip_room=room;_fit_strip()
	strip.position=Vector2(T.DOCK_X,STRIP_TOP)
	strip.size=Vector2(minf(room,strip.get_combined_minimum_size().x),STRIP_HEIGHT)


func _fit_strip()->void:
	if strip==null or _strip_room<0.0:return
	var words:Array=army_box.find_children("Caption","",true,false)
	var size_word:=army_box.get_node_or_null("Size/SizeWord") as Control
	if size_word!=null:words.append(size_word)
	for chip_name in _shed:
		var chip:=army_box.get_node_or_null(String(chip_name)) as Control
		if chip!=null and chip.has_meta("wanted"):chip.visible=bool(chip.get_meta("wanted"))
		var rule:=army_box.get_node_or_null(String(chip_name)+"Rule") as Control
		if chip!=null and rule!=null:rule.visible=chip.visible
	for word in words:(word as Control).visible=true
	if _strip_width()<=_strip_room:return
	for word in words:(word as Control).visible=false
	for chip_name in _shed:
		if _strip_width()<=_strip_room:break
		var chip:=army_box.get_node_or_null(String(chip_name)) as Control
		if chip==null or not chip.visible:continue
		chip.visible=false
		var rule:=army_box.get_node_or_null(String(chip_name)+"Rule") as Control
		if rule!=null:rule.visible=false
	strip.reset_size()


func _strip_width()->float:
	army_box.reset_size();strip.reset_size()
	return strip.get_combined_minimum_size().x


func _build_army(reading:Dictionary,glance:Dictionary)->void:
	_clear(army_box)
	var now:=int(reading.now);var target:=int(reading.target)
	# Soldiers: those under arms against the share kept, HOI4's manpower.
	var soldiers:=_chip("Soldiers","serving")
	var numbers:=VBoxContainer.new();numbers.add_theme_constant_override("separation",2);numbers.alignment=BoxContainer.ALIGNMENT_CENTER;numbers.mouse_filter=Control.MOUSE_FILTER_IGNORE;soldiers.add_child(numbers)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",3);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;numbers.add_child(top)
	var big:=_line(compact(now),18,T.INK);big.name="Now";big.add_theme_font_override("font",T.font("ui_strong"));top.add_child(big)
	if target>=0:
		var of:=_line("/ "+compact(target),14,T.INK_MUTED);of.name="Target";of.size_flags_vertical=Control.SIZE_SHRINK_END;top.add_child(of)
	var word:=_line("soldiers",12,T.INK_MUTED);word.name="Caption";word.size_flags_vertical=Control.SIZE_SHRINK_END;word.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(word)
	var bar:=StrengthBar.new();bar.name="Strength";bar.parts=glance;bar.target=target;bar.custom_minimum_size=Vector2(92,6);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;numbers.add_child(bar)
	soldiers.tooltip_text="Soldiers: %s%s.\n%s\nEveryone in the army: ready, in drill, waiting or hurt. The watch at home is apart." % [EraWords.grouped(now),(" of %s kept (%s of %s people)" % [EraWords.grouped(target),Law.level_name(String(reading.level)),EraWords.grouped(int(reading.population))]) if target>=0 else "",strength_words(glance,now,target)]
	_rule(army_box,"SoldiersRule")
	# The army's size: the ruler's one decision about it, a plain share.
	var size_box:=HBoxContainer.new();size_box.name="Size";size_box.add_theme_constant_override("separation",8);army_box.add_child(size_box)
	var size_word:=_line("Army size",12,T.INK_MUTED);size_word.name="SizeWord";size_word.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	size_word.tooltip_text="How many of the people the war leader keeps under arms. They call up, drill and arm to it, and send the surplus home."
	size_box.add_child(size_word)
	var pick:=HBoxContainer.new();pick.name="Levels";pick.add_theme_constant_override("separation",0);pick.size_flags_vertical=Control.SIZE_SHRINK_CENTER;size_box.add_child(pick)
	var count:=Law.LEVELS.size()
	for i in count:
		var id:=String((Law.LEVELS[i] as Dictionary).id)
		var button:=Button.new();button.name="Level_%s" % id;button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE
		button.text=Law.level_name(id);button.custom_minimum_size=Vector2(40,30)
		button.add_theme_font_override("font",T.font("ui_strong"));button.add_theme_font_size_override("font_size",13)
		for state:String in ["font_color","font_hover_color","font_focus_color"]:button.add_theme_color_override(state,T.INK_MUTED)
		for state:String in ["font_pressed_color","font_hover_pressed_color"]:button.add_theme_color_override(state,T.INK)
		button.add_theme_stylebox_override("normal",_segment(false,false,i,count));button.add_theme_stylebox_override("hover",_segment(false,true,i,count))
		button.add_theme_stylebox_override("pressed",_segment(true,false,i,count));button.add_theme_stylebox_override("hover_pressed",_segment(true,true,i,count))
		button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		button.set_pressed_no_signal(id==String(reading.level))
		button.tooltip_text="%s of the people under arms.\n%s" % [Law.level_name(id),Law.cost_words(id,int(reading.population),int(reading.able))]
		button.pressed.connect(func()->void:_choose_level(id))
		pick.add_child(button)
	if String(reading.level)=="":
		var unset:=_line("Not set",12,T.RED_TEXT);unset.name="NotSet";unset.size_flags_vertical=Control.SIZE_SHRINK_CENTER;unset.tooltip_text="Choose a share: until then nobody is called up or sent home on its account.";size_box.add_child(unset)
	# Where they come from: every soldier is one fewer at work.
	var from:=Forces.drawn_from(MilitaryCampaign)
	_rule(army_box,"DrawnFromRule")
	var drawn:=_value_chip("DrawnFrom","work","1 in %d" % int(from.one_in) if int(from.soldiers)>0 else "none",T.INK if int(from.soldiers)>0 else T.INK_MUTED,"Taken from work: %s of %s workers%s.\nCalling people up takes them from every kind of work alike: fields, crafts, building." % [EraWords.grouped(int(from.soldiers)),EraWords.grouped(int(from.workers)),(" (1 in %d)" % int(from.one_in)) if int(from.soldiers)>0 else ""],"from work")
	drawn.set_meta("wanted",true)
	# Pay, from the realm's purse (realm_purse.gd).
	var pay:=pay_words()
	var months:=int(Purse.state().get("unpaid_months",0))
	var pay_word:="Paid";var pay_ink:=T.GREEN_TEXT
	if months>0:pay_word="Unpaid %d mo" % months;pay_ink=T.RED_TEXT
	elif pay!="" and not Purse.line_on("army"):pay_word="Stopped";pay_ink=T.AMBER_TEXT
	var pay_rule:=_rule(army_box,"PayRule");pay_rule.visible=pay!=""
	var paid:=_value_chip("Pay","coins",pay_word,pay_ink,"%s\nSoldiers are paid from %s on top of their rations. Unpaid, they lose will each month, are slower to muster, and some go home. The Wealth page sets it." % [pay,Purse.account_name()],"pay")
	paid.set_meta("wanted",pay!="");paid.visible=pay!=""
	# Armed and fed, as HOI4's equipment and supply at a glance.
	var armed:=float(glance.armed)
	_rule(army_box,"ArmedRule")
	var arms:=_value_chip("Armed","gear","%d%%" % roundi(armed*100.0),T.GREEN_TEXT if armed>=0.999 else (T.AMBER_TEXT if armed>=0.5 else T.RED_TEXT),"Armed: %d%% of the gear our soldiers need is in their hands. Short kit is made in the workshops (Production)." % roundi(armed*100.0),"armed")
	arms.set_meta("wanted",now>0);arms.visible=now>0
	var fed:=float(glance.fed)
	var fed_rule:=_rule(army_box,"FedRule");fed_rule.visible=fed>=0.0
	var eats:=_value_chip("Fed","supply","%d%%" % roundi(fed*100.0) if fed>=0.0 else "—",T.GREEN_TEXT if fed>=0.75 else (T.AMBER_TEXT if fed>=0.45 else T.RED_TEXT),"Fed in the field: %d%% of the rations our bands out need reached them, by the supply model's own measure." % roundi(maxf(0.0,fed)*100.0),"fed")
	eats.set_meta("wanted",fed>=0.0);eats.visible=fed>=0.0
	var watch:=int(glance.get("watch",0))
	var watch_rule:=_rule(army_box,"WatchRule");watch_rule.visible=watch>0
	var guard:=_value_chip("Watch","guard",compact(watch),T.INK,"On the watch at home: %s. Those set to defence work guard the towns. They are not the army: the army size never calls them up or sends them home." % EraWords.grouped(watch),"on watch")
	guard.set_meta("wanted",watch>0);guard.visible=watch>0
	var warning:=[]
	if months>0 or pay_word=="Stopped":warning.append("Pay")
	if now>0 and armed<0.999:warning.append("Armed")
	if fed>=0.0 and fed<0.75:warning.append("Fed")
	_shed=SHED_ORDER.filter(func(chip_name:String)->bool:return chip_name not in warning)+SHED_ORDER.filter(func(chip_name:String)->bool:return chip_name in warning)
	_fit_strip()


## The army's pay in a line (realm_purse.gd): its cost a season, or how long
## it has gone unpaid; "" with nobody to pay.
static func pay_words()->String:
	var per:=Purse.line_cost_per_day("army")*Purse.SEASON_DAYS
	if per<=0.5:return ""
	var months:=int(Purse.state().get("unpaid_months",0))
	if months>0:return "Unpaid %d %s: will falling, some going home." % [months,"month" if months==1 else "months"]
	if not Purse.line_on("army"):return "Their pay is stopped: about %s a season." % Purse.amount_text(per)
	return "Pay: %s a season, in %s." % [Purse.amount_text(per),Purse.pay_word()]


func _choose_level(id:String)->void:
	var result:=Law.choose(MilitaryCampaign,id)
	_say(String(result.get("said",result.get("error",""))) if String(result.get("said",""))!="" else "The army is kept at %s of the people." % Law.level_name(id))
	refresh(true)


## A count that fits a chip at any size: "120", "48,300", "1.2 million",
## "3.4 billion" (the full count is in the chip's tooltip).
static func compact(value:int)->String:
	if absi(value)<1_000_000:return EraWords.grouped(value)
	if absi(value)<1_000_000_000:return "%s million" % _one_place(float(value)/1_000_000.0)
	return "%s billion" % _one_place(float(value)/1_000_000_000.0)


static func _days(count:int)->String:
	return "1 day" if count==1 else "%d days" % count


static func _one_place(value:float)->String:
	return str(roundi(value)) if absf(value)>=100.0 or is_equal_approx(value,roundf(value)) else "%.1f" % value


# --- Our enemies ----------------------------------------------------------

func _build_enemies(entries:Array)->void:
	_clear(enemy_box)
	enemy_count.text=str(entries.size()) if not entries.is_empty() else ""
	if entries.is_empty():
		var calm:=PanelContainer.new();calm.name="Calm";calm.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,10,0));enemy_box.add_child(calm)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);calm.add_child(row)
		row.add_child(_icon("leave",T.INK_MUTED,18))
		var said:=_line("At peace",14,T.INK_MUTED);said.tooltip_text="No feud or war with anyone.";row.add_child(said)
	else:
		for e:Dictionary in entries:enemy_box.add_child(_enemy_row(e))
	# Every people we know, ranked as we know them (hud/peoples_known_board.gd,
	# at the head of the Known World).
	var all:=Button.new();all.name="AllPeoples";all.text="All peoples we know";all.focus_mode=Control.FOCUS_NONE
	all.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;all.tooltip_text="Every people we have met, ranked as we know them."
	all.add_theme_font_size_override("font_size",13)
	all.add_theme_color_override("font_color",T.GOLD_TEXT);all.add_theme_color_override("font_hover_color",T.INK);all.add_theme_color_override("font_pressed_color",T.INK)
	for state:String in ["normal","pressed","disabled"]:all.add_theme_stylebox_override(state,_skin(Color(0,0,0,0),Color(0,0,0,0),2,0))
	all.add_theme_stylebox_override("hover",_skin(T.HOVER_BG,Color(0,0,0,0),2,0))
	all.pressed.connect(func()->void:
		var scene:=get_tree().current_scene if is_inside_tree() else null
		var hud:Variant=scene.get("hud") if scene!=null else null
		if hud==null or not hud.has_method("has_provider") or not hud.has_provider("world"):return
		close_wanted.emit()
		hud.open_dock("world",0))
	enemy_box.add_child(all)


## One people at feud or war, as an HOI4 war card: who they are and how hot,
## the dead on each side, who is winning, what is happening now, and the
## stance as a row of buttons.
func _enemy_row(e:Dictionary)->Control:
	var civ_id:=String(e.civ_id)
	var tone:=LedgerMarks.chip_tone(Ledger.state_word(e))
	var panel:=PanelContainer.new();panel.name="Enemy_%s" % civ_id
	panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,Color(tone,0.8),10,3))
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);column.add_child(head)
	var emblem:=TextureRect.new();emblem.texture=Identity.emblem(civ_id);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.custom_minimum_size=Vector2(30,30)
	emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(emblem)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",-2);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_PASS;head.add_child(words)
	var title:=Label.new();title.text=String(e.name);T.text(title,"voice_small",T.INK);title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(title)
	var since:=int(e.get("days",0))
	words.add_child(_line("%s · %s" % ["War" if String(e.kind)=="war" else "Feud","begun today" if since<=0 else Ledger.span_words(since)],12,T.INK_MUTED))
	var trade_line:=String(preload("res://scripts/trade_words.gd").war_line(civ_id))
	words.tooltip_text="%s.%s" % [Ledger.subtitle(e),("\n"+trade_line) if trade_line!="" else ""]
	var dead:=DeadStrip.new();dead.name="Dead";dead.ours=int(e.our_dead);dead.theirs=int(e.their_dead);dead.custom_minimum_size=Vector2(104,26);dead.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	dead.tooltip_text="The dead of it all told: %s of ours (left), %s of theirs (right)." % [EraWords.grouped(int(e.our_dead)),EraWords.grouped(int(e.their_dead))];head.add_child(dead)
	var chip:=Chip.new();chip.word=Ledger.state_word(e);chip.tooltip_text=Ledger.clock_words(e) if String(e.kind)=="feud" else "At war since %s." % Ledger.span_words(since);head.add_child(chip)
	# HOI4's read of who is winning: our share of the strength against theirs.
	var odds:=Strips.OddsBar.new();odds.name="Odds";column.add_child(odds)
	odds.set_odds(Ledger.odds(e),Ledger.odds_words(e))
	odds.tooltip_text="Their strength against ours, by the war leader's reckoning: people, warriors and readiness on one scale.\nWorn by the fighting: we are %d%% worn, they are %d%%." % [roundi(float(e.get("our_worn",0.0))*100.0),roundi(float(e.get("their_worn",0.0))*100.0)]
	column.add_child(_now_row(e))
	var stances:=HBoxContainer.new();stances.name="Stances";stances.add_theme_constant_override("separation",3);column.add_child(stances)
	var chosen:=String(WarLoop.front(civ_id).get("stance",""))
	for spec:Array in STANCES:
		var id:=String(spec[0])
		if id=="take":
			stances.add_child(_take_button(civ_id,chosen=="take"));continue
		var button:=_stance_button(id,chosen==id)
		button.tooltip_text="%s: %s" % [String(spec[1]),String(spec[3])]
		button.pressed.connect(func()->void:_stance(civ_id,id,String(spec[2])))
		stances.add_child(button)
	var foot:=HBoxContainer.new();foot.add_theme_constant_override("separation",8);column.add_child(foot)
	foot.add_child(_led_by(civ_id))
	if String(e.kind)=="feud" and float(e.get("blood_price",0.0))>0.0:
		var pay:=_stance_button("pay",false)
		pay.toggle_mode=false;pay.text="Pay %s food" % compact(roundi(float(e.blood_price)));pay.size_flags_horizontal=Control.SIZE_SHRINK_END;_compact_skin(pay,6.0)
		pay.tooltip_text="Pay a blood price of %s food for the dead of theirs. It ends the feud at once; their raiders will not come for it." % EraWords.grouped(roundi(float(e.blood_price)))
		pay.pressed.connect(func()->void:_stance(civ_id,"pay","war_price"))
		foot.add_child(pay)
	var besieged:=_yield_home(civ_id)
	if besieged!=null:column.add_child(besieged)
	return panel


## What is happening with this people now, in one short line with its mark:
## our band and where it is bound, the war leader's errand, or how quiet it
## is (now_short). The council's full account is in the tooltip.
func _now_row(e:Dictionary)->Control:
	var said:=now_short(e)
	var row:=HBoxContainer.new();row.name="Now";row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS
	var mark:=StateMark.new();mark.state=String(said.state);mark.custom_minimum_size=Vector2(18,18);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(mark)
	var text:=_line(String(said.text),13,T.RED_TEXT if bool(said.get("danger",false)) else T.INK);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text.clip_text=true;text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(text)
	var details:=now_details(e)
	var whole:=now_words(e)
	row.tooltip_text=(whole.substr(0,1).to_upper()+whole.substr(1)+".\n" if whole!="" else "")+details.substr(0,1).to_upper()+details.substr(1)
	text.tooltip_text=row.tooltip_text
	# Our eyes there, when we have any (covert_ops.gd).
	var eyes:Dictionary=Covert.eyes_on(String(e.civ_id))
	if int(eyes.count)>0:
		var spies:=HBoxContainer.new();spies.name="Eyes";spies.add_theme_constant_override("separation",3);spies.mouse_filter=Control.MOUSE_FILTER_PASS
		spies.add_child(_icon("eye",T.INK_MUTED,16))
		spies.add_child(_line(str(int(eyes.count)),13,T.INK))
		spies.tooltip_text="Our eyes in %s: %d%s." % [String(e.name),int(eyes.count),(" · last word %s" % Ledger.span_words(int(eyes.last_word_days))) if int(eyes.last_word_days)>=0 else ""]
		row.add_child(spies)
	return row


## The line under the odds: {state (battle_marks glyph), text, danger}.
## Our band out against them: "Tula · 12 → Ashford · 8 days"; else the war
## leader's errand ("Tracking the raiders · 12 days"), their raiders coming,
## or how long it has been quiet.
static func now_short(e:Dictionary)->Dictionary:
	var civ_id:=String(e.get("civ_id",""))
	var today:=int(WorldSimulation.state.elapsed_days) if WorldSimulation!=null and WorldSimulation.state!=null else 0
	var council:GDScript=load("res://scripts/war_council.gd")
	var bands:Array=council.call("bands_against",civ_id) if civ_id!="" else []
	if not bands.is_empty():
		var band:Dictionary=bands[0]
		var card:Dictionary=BarModel.army_card(MilitaryCampaign,band)
		var who:="%s · %s" % [String(card.get("short","Our band")),compact(int(card.get("men",0)))]
		var more:=(" +%d" % (bands.size()-1)) if bands.size()>1 else ""
		var state:=String(card.get("state","holding"))
		var place:=String((band.get("council",{}) as Dictionary).get("name",band.get("destination_name",""))) if band.get("council") is Dictionary else String(band.get("destination_name",""))
		match state:
			"fighting":return {"state":state,"text":"%s%s in battle" % [who,more],"danger":true}
			"besieging":return {"state":state,"text":"%s%s besieging %s" % [who,more,place]}
			"broken":return {"state":state,"text":"%s%s broken" % [who,more],"danger":true}
			"hungry":return {"state":state,"text":"%s%s going hungry" % [who,more],"danger":true}
		if String(band.get("status",""))=="moving":
			var days:=maxi(0,int(band.get("arrival_day",today))-today)
			var home:=String(band.get("destination_id",""))=="player_home"
			return {"state":"marching","text":"%s%s → %s%s" % [who,more,"home" if home else (place if place!="" else "the march"),(" · %s" % _days(days)) if days>0 else ""]}
		return {"state":state,"text":"%s%s at %s" % [who,more,place if place!="" else String(band.get("location_name","the field"))]}
	var op:Dictionary=e.get("band",{}) if e.get("band") is Dictionary else {}
	if not op.is_empty():
		var words:=String(op.get("words","out against them"))
		var left:=int(op.get("days_left",0))
		return {"state":"marching","text":"%s%s" % [words.substr(0,1).to_upper()+words.substr(1),(" · %s" % _days(left)) if left>0 else ""]}
	if bool(e.get("hot",false)):return {"state":"fighting","text":"Their raiders may come","danger":true}
	var quiet:=int(e.get("quiet",0))
	return {"state":"holding","text":"Quiet · %s" % Ledger.span_words(quiet) if quiet<99999 else "No blood spilled yet"}


func _stance_button(id:String,chosen:bool)->Button:
	var button:=Button.new();button.name="Stance_%s" % id;button.text=String(SHORT.get(id,id.capitalize()));button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE
	button.icon=Icons.command_texture(String(MARKS.get(id,"front")),T.INK,32);button.add_theme_constant_override("icon_max_width",14);button.add_theme_constant_override("h_separation",3)
	button.add_theme_font_size_override("font_size",12);button.custom_minimum_size=Vector2(0,28);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_compact_skin(button,4.0)
	button.set_pressed_no_signal(chosen)
	return button


## When this people besieges our home, the one way to give it up. Home is
## never lost by pulling back or by a lost fight (field_sustainment,
## civilization_siege): only by the ruler's word. Two presses, the second
## within a few seconds, because it cannot be undone.
func _yield_home(civ_id:String)->Control:
	var siege:Dictionary=MilitaryCampaign.active_siege
	if String(siege.get("mode",""))!="defensive":return null
	var by:=String(siege.get("attacker_id",""))
	if by!=civ_id and String((siege.get("threat",{}) as Dictionary).get("source_civ_id",""))!=civ_id:return null
	var home:=String((siege.get("home_city",{}) as Dictionary).get("name",WorldSimulation.state.settlement_name))
	var days:=maxi(1,int(WorldSimulation.state.elapsed_days)-int(siege.get("start_day",WorldSimulation.state.elapsed_days)))
	var row:=HBoxContainer.new();row.name="Besieged";row.add_theme_constant_override("separation",8)
	row.add_child(_icon("besiege",T.RED,18))
	var said:=_line("%s besieged · day %d" % [home,days],13,T.RED_TEXT);said.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	said.tooltip_text="They besiege %s: day %d. It is lost only if you yield it." % [home,days]
	row.add_child(said)
	var give:=Button.new();give.name="YieldHome";give.text="Yield %s" % home;give.focus_mode=Control.FOCUS_NONE;give.add_theme_font_size_override("font_size",13);_compact_skin(give)
	give.tooltip_text="Give %s up to them. Our people there live on under their rule. It cannot be undone." % home
	give.pressed.connect(func()->void:
		if not give.has_meta("armed"):
			give.set_meta("armed",true);give.text="Press again to yield %s" % home
			get_tree().create_timer(4.0).timeout.connect(func()->void:
				if is_instance_valid(give) and give.has_meta("armed"):give.remove_meta("armed");give.text="Yield %s" % home)
			return
		var result:Dictionary=MilitaryCampaign.siege_order(String(siege.get("id","")),"surrender")
		_say(String(result.get("message",result.get("error","%s is yielded." % home))))
		refresh(true))
	row.add_child(give)
	return row


## Who leads against this people: the war leader's choice, or a general the
## ruler names (WarLoop.front(civ_id).general: a figure id, "" for the war
## leader's choice). The war council gives that general the bands it sends.
func _led_by(civ_id:String)->Control:
	var row:=HBoxContainer.new();row.name="LedBy";row.add_theme_constant_override("separation",6);row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var generals:=Commands.leaders(MilitaryCampaign).filter(func(l:Dictionary)->bool:return String(l.id)!=Commands.WAR_LEADER and String(l.get("status",""))=="living")
	var chosen:=String(WarLoop.front(civ_id).get("general",""))
	var word:=_line("Led by",12,T.INK_MUTED);word.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(word)
	if generals.is_empty():
		var who:=_line("War leader",13,T.INK);who.tooltip_text="The war leader chooses who goes: no general has come forward yet.";row.add_child(who)
		return row
	var pick:=OptionButton.new();pick.name="General";pick.focus_mode=Control.FOCUS_NONE;pick.add_theme_font_size_override("font_size",13);pick.fit_to_longest_item=false
	pick.clip_text=true;pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pick.custom_minimum_size=Vector2(96,28);_compact_skin(pick)
	pick.add_item("War leader's choice");pick.set_item_metadata(0,"")
	pick.set_item_tooltip(0,"Whoever the war leader thinks best for the work.")
	var selected:=0
	for general:Dictionary in generals:
		var commander:Dictionary=general.get("commander",{})
		var levers:=GeneralRecord.levers(commander)
		pick.add_item(String(general.name))
		pick.set_item_metadata(pick.item_count-1,String(general.id))
		pick.set_item_tooltip(pick.item_count-1,"Fight %+d%%, march %+d%% against an ordinary general." % [roundi(float(levers.fight)*100.0),roundi(float(levers.pace)*100.0)])
		if String(general.id)==chosen:selected=pick.item_count-1
	pick.select(selected)
	pick.tooltip_text="The general who leads what we send against them."
	pick.item_selected.connect(func(index:int)->void:_lead(civ_id,String(pick.get_item_metadata(index)),pick.get_item_text(index)))
	row.add_child(pick)
	return row


func _lead(civ_id:String,general:String,name_words:String)->void:
	WarLoop.front(civ_id)["general"]=general
	_say(("%s leads against them from now on." % name_words) if general!="" else "The war leader chooses who leads against them.")
	refresh(true)


## The army at a glance, the watch at home apart: {ready (fighters at home
## beyond the watch, in the field and holding towns), drill, drill_days,
## waiting (recruits waiting to drill), away (hurt, scattered or taken),
## watch (keeping the watch at home), armed (0..1: gear issued of gear
## wanted), fed (0..1 of those out by the bars' own measure; -1 when nobody
## is out)}.
static func strength(mc:Node)->Dictionary:
	var ledger:Dictionary=mc.personnel_ledger()
	var watch:=Law.watch(mc)
	var formations:Array=(mc.home_army.get("formations",[]) as Array).duplicate()
	var out:=0
	var fed:=0.0
	for army_variant in mc.field_armies:
		if not army_variant is Dictionary or int((army_variant as Dictionary).get("troops",0))<=0:continue
		var army:Dictionary=army_variant
		formations.append_array(army.get("formations",[]))
		var card:=BarModel.army_card(mc,army)
		if bool(card.get("unknown",false)):continue
		out+=int(card.men);fed+=float(card.men)*clampf(float(card.get("supply",1.0)),0.0,1.0)
	var drill:=BarModel.drill_card(mc)
	return {"ready":maxi(0,int(ledger.home)-int(watch.home))+int(ledger.field)+int(ledger.occupation),"drill":maxi(0,int(ledger.training)-int(watch.drill)),"drill_days":int(drill.get("days",0)),
		"waiting":int(ledger.recruits),"away":int(ledger.recovering)+int(ledger.get("missing",0)),"watch":int(watch.kept),
		"armed":float(BarModel.gear_of(formations,mc).share),"fed":snappedf(fed/float(out),0.01) if out>0 else -1.0}


## The bar in words: "327 ready · 85 in drill, about 40 days · 12 waiting to
## drill · 9 hurt or away · 188 to call up".
static func strength_words(glance:Dictionary,now:int,target:int)->String:
	var parts:=PackedStringArray(["%s ready" % EraWords.grouped(int(glance.ready))])
	if int(glance.drill)>0:parts.append("%s in drill%s" % [EraWords.grouped(int(glance.drill)),(", about %d days" % int(glance.drill_days)) if int(glance.drill_days)>0 else ""])
	if int(glance.waiting)>0:parts.append("%s waiting to drill" % EraWords.grouped(int(glance.waiting)))
	if int(glance.get("away",0))>0:parts.append("%s hurt or away" % EraWords.grouped(int(glance.away)))
	if target>now:parts.append("%s to call up" % EraWords.grouped(target-now))
	elif target>=0 and now>target:parts.append("%s above the share" % EraWords.grouped(now-target))
	return " · ".join(parts)


## What is happening with this people now, in a few words (the details in
## now_details): the war council's own reading (war_council.gd
## operation_words): our band out and how it stands ("Rovik besieges
## Oakford, day 12: odds 3 to 2, fed 80%"), their band coming, the trackers
## or messengers out, or why the war leader waits.
static func now_words(e:Dictionary)->String:
	var civ_id:=String(e.get("civ_id",""))
	var council:GDScript=load("res://scripts/war_council.gd")
	var said:=String(council.call("operation_words",civ_id)) if civ_id!="" else ""
	if said!="":return said
	var bands:Array=e.get("bands",[])
	if not bands.is_empty():
		var b:Dictionary=bands[0]
		return "%s %s%s" % [String(b.name),String(b.where),(" and %d more" % (bands.size()-1)) if bands.size()>1 else ""]
	if bool(e.get("hot",false)):return "nobody of ours is out; their raiders may come"
	return "quiet for %s" % Ledger.span_words(int(e.get("quiet",0)))


## Everything happening with this people now, for the pointer: the council's
## account (the band, the odds it set out at, how it is fed, the stance in
## force), our other bands at their towns, and their last raid.
static func now_details(e:Dictionary)->String:
	var civ_id:=String(e.get("civ_id",""))
	var parts:=PackedStringArray()
	var council:GDScript=load("res://scripts/war_council.gd")
	var said:=String(council.call("operation_details",civ_id)).trim_suffix(".") if civ_id!="" else ""
	if said!="":parts.append(said)
	for b:Dictionary in e.get("bands",[]):parts.append("%s · %s · %s" % [String(b.name),EraWords.grouped(int(b.troops)),String(b.where)])
	var raid:Dictionary=e.get("last_raid",{})
	if not raid.is_empty() and int(raid.get("days_ago",9999))<=120:parts.append("their last raid %s ago" % Ledger.span_words(int(raid.days_ago)))
	if parts.is_empty():
		if bool(e.get("hot",false)):parts.append("no one of ours is out against them; their raiders may come")
		else:parts.append("quiet for %s" % Ledger.span_words(int(e.get("quiet",0))))
	return "; ".join(parts)+"."


func _take_button(civ_id:String,chosen:bool)->Control:
	var pick:=MenuButton.new();pick.name="Stance_take";pick.text="Take ▾";pick.flat=false;pick.focus_mode=Control.FOCUS_NONE
	pick.icon=Icons.command_texture(String(MARKS.take),T.INK,32);pick.add_theme_constant_override("icon_max_width",14);pick.add_theme_constant_override("h_separation",3)
	pick.add_theme_font_size_override("font_size",12);pick.custom_minimum_size=Vector2(0,28);pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_compact_skin(pick,4.0)
	pick.tooltip_text="%s: %s The war leader gathers until the odds are 3 to 2, feeds the march or waits, then lays siege or storms." % [String(STANCES[3][1]),String(STANCES[3][3])]
	if chosen:pick.add_theme_stylebox_override("normal",_compact_style(true,false,4.0))
	var popup:=pick.get_popup()
	var council:GDScript=load("res://scripts/war_council.gd")
	var towns:Array=council.call("known_towns",civ_id)
	if towns.is_empty():
		pick.disabled=true;pick.tooltip_text="Take a town: we know of no town of theirs yet. Scouts find their towns."
		return pick
	var aim:Dictionary=WarLoop.front(civ_id).get("take",{}) if WarLoop.front(civ_id).get("take") is Dictionary else {}
	var preview:=towns.slice(0,8)
	for i in preview.size():
		var p:Dictionary=preview[i]
		var look:=Orders.preview(Orders.HOME,"attack",{"type":"place","place":p})
		var days:=int(look.get("days",0))
		var odds:Dictionary=look.get("odds",{}) if look.get("odds") is Dictionary else {}
		var marked:=" ✓" if String(aim.get("city_id",""))==String(p.city_id) else ""
		popup.add_item("%s%s%s%s" % [Orders.place_name(p),(" · %d days" % days) if days>0 else "",(" · odds "+Orders.odds_short(float(odds.odds),bool(odds.ours))) if not odds.is_empty() else "",marked],i)
		popup.set_item_tooltip(i,"\n".join(look.get("lines",[])))
	popup.id_pressed.connect(func(index:int)->void:_take(civ_id,preview[index]))
	return pick


## A stance is the god's word to the war council (war_council.gd order): it
## acts on it at once with the real army, says what it did or why it waits,
## and keeps to it. Pay settles the feud with a blood price (war_loop.gd).
func _stance(civ_id:String,id:String,objective:String)->void:
	# One "Go anyway" at most, and only for the latest word.
	for child in get_children():
		if String(child.name).begins_with("GoAnyway"):remove_child(child);child.queue_free()
	if id=="pay":
		_say(WarLoop.order(civ_id,objective))
		refresh(true)
		return
	var council:GDScript=load("res://scripts/war_council.gd")
	var label:=""
	for spec:Array in STANCES:
		if String(spec[0])==id:label=String(spec[1])
	var answer:Dictionary=council.call("order",civ_id,id,{"card":true,"words":"%s: %s" % [WarLoop._name(civ_id),label.to_lower()]})
	_say(String(answer.get("says",answer.get("outcome",""))))
	# The war leader waits for the odds or the road: the god can send them anyway.
	if String(answer.get("verdict","")) in ["object","wait"] and id=="punish":
		var go:=Button.new();go.text="Go anyway";go.name="GoAnyway";go.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;_compact_skin(go)
		go.pressed.connect(func()->void:
			go.queue_free()
			var again:Dictionary=council.call("order",civ_id,id,{"insist":true,"card":true,"words":"%s: %s, go anyway" % [WarLoop._name(civ_id),label.to_lower()]})
			_say(String(again.get("says",again.get("outcome",""))))
			refresh(true))
		feedback.add_sibling(go)
	refresh(true)


func _take(civ_id:String,place:Dictionary,insist:=false)->void:
	# One "Go anyway" at most, and only for the latest word.
	for child in get_children():
		if String(child.name).begins_with("GoAnyway"):remove_child(child);child.queue_free()
	var council:GDScript=load("res://scripts/war_council.gd")
	var answer:Dictionary=council.call("order",civ_id,"take",{"place":place,"insist":insist,"card":true,"words":"Take %s%s" % [Orders.place_name(place),", go anyway" if insist else ""]})
	_say(String(answer.get("says",answer.get("outcome",""))))
	if String(answer.get("verdict","")) in ["object","wait"] and not insist:
		var go:=Button.new();go.text="Go anyway";go.name="GoAnyway";go.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;_compact_skin(go)
		go.pressed.connect(func()->void:go.queue_free();_take(civ_id,place,true))
		feedback.add_sibling(go)
	refresh(true)


# --- Our leaders ----------------------------------------------------------

func _build_leaders(commands:Array)->void:
	_clear(leader_box)
	for c:Dictionary in commands:leader_box.add_child(_leader_row(c))


func _name_general()->void:
	var result:Dictionary=Commands.commission_general(MilitaryCampaign)
	if result.has("error"):_say(String(result.error));return
	_say(("%s is named a general. %s" if bool(result.get("new",false)) else "%s is free to lead already. %s") % [String(result.name),String(result.get("line",""))])
	refresh(true)


## A leader as HOI4 shows one: the face, the name, the skill pips, and, while
## they lead bands, their men with three bars (men, will, fed). Their record
## and what their hand changes, in the engine's numbers, are in the tooltip.
func _leader_row(c:Dictionary)->Control:
	var leader:Dictionary=c.leader
	var war_leader:=String(c.id)==Commands.WAR_LEADER
	var panel:=PanelContainer.new();panel.name="Leader_%s" % String(c.id)
	panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,8,0))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);panel.add_child(row)
	var frame:=PanelContainer.new();frame.clip_contents=true;frame.custom_minimum_size=Vector2(40,48);frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var ground:=T.flat(T.PAPER_SUNK);ground.border_color=Commands.color(String(c.id));ground.border_width_left=3;frame.add_theme_stylebox_override("panel",ground);row.add_child(frame)
	var face:=TextureRect.new();face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var key:=String(leader.get("figure_id","")) if String(leader.get("figure_id",""))!="" else String(leader.get("name",""))
	face.texture=Portrait.texture({"name":String(leader.get("name","")),"person_id":absi(key.hash())%997+1});frame.add_child(face)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",2);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(words)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);top.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(top)
	var name_label:=_line(String(leader.get("name","The war leader")),14,T.INK);name_label.add_theme_font_override("font",T.font("ui_strong"))
	name_label.clip_text=true;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(name_label)
	var role:=_line("War leader" if war_leader else "General",12,T.INK_MUTED);role.size_flags_vertical=Control.SIZE_SHRINK_CENTER;top.add_child(role)
	if war_leader:
		var other:=Button.new();other.name="NameWarLeader";other.text="Change";other.flat=true;other.focus_mode=Control.FOCUS_NONE
		other.add_theme_font_size_override("font_size",12);other.add_theme_color_override("font_color",T.GOLD_TEXT);other.add_theme_color_override("font_hover_color",T.INK)
		other.tooltip_text="The war leader at home is the Marshal among the officials, or the best of the field staff while no one holds that office. Choose the Marshal among the officials."
		other.pressed.connect(_name_war_leader)
		top.add_child(other)
	if not (leader.get("commander",{}) as Dictionary).is_empty():
		var pips:=Strips.GeneralPips.new();pips.name="Pips";words.add_child(pips)
		pips.set_commander(leader.get("commander",{}),String(leader.get("name","")),war_leader)
	var below:=HBoxContainer.new();below.add_theme_constant_override("separation",6);below.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(below)
	if int(c.get("men",0))>0:
		below.add_child(_icon("men",T.INK,16))
		var men:=_line(compact(int(c.men)),13,T.INK);men.add_theme_font_override("font",T.font("ui_strong"));below.add_child(men)
		var bars:=CommandBars.new();bars.name="Bars";bars.men=int(c.men);bars.full=int(c.full);bars.will=float(c.will);bars.fed=float(c.supply)
		bars.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bars.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		bars.tooltip_text="Men %d of %d · will %d%% · fed %d%%" % [int(c.men),int(c.full),roundi(float(c.will)*100.0),roundi(float(c.supply)*100.0)]
		below.add_child(bars)
	else:
		below.add_child(_line("At home",12,T.INK_MUTED))
	# What their hand changes, in the engine's numbers, and what they have done.
	var record:=Commands.record(leader)
	var told:=PackedStringArray([leader_doing(c)])
	var rated:=skill_words(leader.get("commander",{}))
	if rated!="":told.append(rated)
	if int(record.get("battles",0))>0:told.append("Fought %d · won %d · lost %d" % [int(record.get("battles",0)),int(record.get("won",0)),int(record.get("lost",0))])
	for said:String in [GeneralRecord.lever_line(leader.get("commander",{}),String(leader.get("name","")),float(c.get("men",0))),GeneralRecord.words(record)]:
		if said!="":told.append(said)
	panel.tooltip_text="\n".join(told)
	return panel


## The officials, where the ruler names the Marshal (the war leader at home).
func _name_war_leader()->void:
	var scene:=get_tree().current_scene if is_inside_tree() else null
	var hud:Variant=scene.get("hud") if scene!=null else null
	if hud==null or not hud.has_method("has_provider") or not hud.has_provider("government"):return
	close_wanted.emit()
	hud.open_dock("government",0)


## What a leader is best and worst at, by the skills the engine fights,
## camps and marches with: "Best at holding firm (5/5) · weakest at supply
## (2/5)".
const SKILL_WORDS:={"command":"planning","tactics":"fighting","resolve":"holding firm","logistics":"supply"}
static func skill_words(commander:Dictionary)->String:
	if commander.is_empty():return ""
	var best:="";var worst:="";var high:=-1;var low:=6
	for skill:String in SKILL_WORDS:
		var pips:=Strips.GeneralPips.pips(float(commander.get(skill,0.5)))
		if pips>high:high=pips;best=skill
		if pips<low:low=pips;worst=skill
	if high==low:return "Even in every skill (%d/5)" % high
	return "Best at %s (%d/5) · weakest at %s (%d/5)" % [SKILL_WORDS[best],high,SKILL_WORDS[worst],low]


## What a leader is doing now: their bands and men and where, or "at home".
static func leader_doing(c:Dictionary)->String:
	var bands:=(c.bands as Array).size()
	if bands==0:return "Keeps the watch at home." if String(c.id)==Commands.WAR_LEADER else "Waits at home for a command."
	var places:=PackedStringArray()
	for place in (c.get("places",{}) as Dictionary):places.append(String(place))
	var hungry:=(" · %d hungry" % int(c.hungry)) if int(c.get("hungry",0))>0 else ""
	return "Leads %s men in %d %s · %s%s" % [EraWords.grouped(int(c.men)),bands,"band" if bands==1 else "bands",", ".join(places),hungry]


# --- Spies ------------------------------------------------------------------

func _spies_words()->void:
	if covert_toggle==null:return
	var abroad:=Covert.agents_abroad().size()
	covert_toggle.text="SPIES%s  %s" % [(" · %d abroad" % abroad) if abroad>0 else "","▾" if covert!=null and covert.visible else "›"]


# --- Pieces ---------------------------------------------------------------

func _say(text:String)->void:
	feedback.text=text
	feedback.tooltip_text=text
	feedback.visible=text!=""


## A section's kicker with room on its right for a count or a button.
func _kicker_row(title:String)->HBoxContainer:
	var row:=HBoxContainer.new();row.name=title+"Head";row.add_theme_constant_override("separation",6);add_child(row)
	var kicker:=_line(title.to_upper(),12,T.INK_MUTED);kicker.add_theme_font_override("font",T.font("ui_strong"));kicker.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(kicker)
	var count:=_line("",12,T.INK_MUTED);count.add_theme_font_override("font",T.font("ui_strong"));count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(count)
	var gap:=Control.new();gap.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(gap)
	row.set_meta("count",count)
	return row


func _small_button(text:String,mark:String,tip:String)->Button:
	var button:=Button.new();button.text=text;button.focus_mode=Control.FOCUS_NONE;button.tooltip_text=tip
	button.icon=Icons.command_texture(mark,T.INK,32);button.add_theme_constant_override("icon_max_width",12);button.add_theme_constant_override("h_separation",3)
	button.add_theme_font_size_override("font_size",12);button.custom_minimum_size=Vector2(0,24)
	_compact_skin(button)
	return button


## A strip chip: a mark and, beside it, what the caller adds.
func _chip(chip_name:String,mark:String)->HBoxContainer:
	var chip:=HBoxContainer.new();chip.name=chip_name;chip.add_theme_constant_override("separation",6);chip.mouse_filter=Control.MOUSE_FILTER_STOP
	var icon:=_icon(mark,T.INK,22);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(icon)
	army_box.add_child(chip)
	return chip


## A strip chip with one value: mark, number, a word or two under it, and
## the sentence in its tooltip.
func _value_chip(chip_name:String,mark:String,value:String,ink:Color,tip:String,caption:="")->HBoxContainer:
	var chip:=_chip(chip_name,mark)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",-3);stack.alignment=BoxContainer.ALIGNMENT_CENTER;stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(stack)
	var label:=_line(value,16,ink);label.name="Value";label.add_theme_font_override("font",T.font("ui_strong"));label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stack.add_child(label)
	if caption!="":
		var under:=_line(caption,12,T.INK_MUTED);under.name="Caption";under.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(under)
	chip.tooltip_text=tip
	return chip


func _rule(parent:Node,rule_name:String)->Control:
	var rule:=ColorRect.new();rule.name=rule_name;rule.color=T.RULE;rule.custom_minimum_size=Vector2(1,28);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)
	return rule


static func _icon(mark:String,ink:Color,px:int)->TextureRect:
	var icon:=TextureRect.new();icon.texture=Icons.command_texture(mark,ink,48);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size=Vector2(px,px);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return icon


## One segment of the army size control: square inside, rounded at the ends.
static func _segment(pressed:bool,hover:bool,index:int,count:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=T.ACTIVE_BG if pressed else (T.HOVER_BG if hover else T.BUTTON_BG)
	style.border_color=T.GOLD if pressed else T.BORDER_2
	style.set_border_width_all(1)
	if index>0:style.border_width_left=0
	if pressed:style.border_width_bottom=3
	style.corner_radius_top_left=3 if index==0 else 0;style.corner_radius_bottom_left=3 if index==0 else 0
	style.corner_radius_top_right=3 if index==count-1 else 0;style.corner_radius_bottom_right=3 if index==count-1 else 0
	style.content_margin_left=6.0;style.content_margin_right=6.0
	return style


static func _compact_style(pressed:bool,hover:bool,pad:=7.0)->StyleBoxFlat:
	var style:=T.button_pressed_style() if pressed else T.action_button_style(false,hover)
	style.content_margin_left=pad;style.content_margin_right=pad;style.content_margin_top=2.0;style.content_margin_bottom=2.0
	if pressed:style.border_width_bottom=3
	return style


static func _compact_skin(button:Control,pad:=7.0)->void:
	button.add_theme_stylebox_override("normal",_compact_style(false,false,pad))
	button.add_theme_stylebox_override("hover",_compact_style(false,true,pad))
	button.add_theme_stylebox_override("pressed",_compact_style(true,false,pad))
	button.add_theme_stylebox_override("hover_pressed",_compact_style(true,true,pad))
	button.add_theme_stylebox_override("disabled",T.button_disabled_style())
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	for state:String in ["font_color","font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]:button.add_theme_color_override(state,T.INK)
	button.add_theme_color_override("font_disabled_color",T.DISABLED)


func _clear(box:Node)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()


static func _skin(bg:Color,border:Color,margin:int,left:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1)
	if left>0:style.border_width_left=left
	style.set_corner_radius_all(T.RADIUS_CARD);style.set_content_margin_all(margin)
	return style


static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_PASS
	label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));label.add_theme_color_override("font_color",color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


## HOI4's manpower bar: ready (green), in drill (amber), waiting, hurt or
## away (rule), against the share kept (the ink tick); over the share, the
## tick falls inside the bar.
class StrengthBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var parts:Dictionary={}
	var target:=-1
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var whole:=Rect2(Vector2.ZERO,size)
		draw_rect(whole,T.PAPER_SUNK)
		var segments:=[[int(parts.get("ready",0)),T.GREEN],[int(parts.get("drill",0)),T.AMBER],[int(parts.get("waiting",0))+int(parts.get("away",0)),T.RULE_STRONG]]
		var total:=0
		for segment:Array in segments:total+=int(segment[0])
		var scale:=float(maxi(1,maxi(total,target)))
		var x:=0.0
		for segment:Array in segments:
			var width:=size.x*float(segment[0])/scale
			if width>0.0:draw_rect(Rect2(x,0.0,width,size.y),segment[1]);x+=width
		draw_rect(whole,T.RULE,false,1.0)
		if target>0:
			var tick:=clampf(size.x*float(target)/scale,1.0,size.x-1.0)
			draw_line(Vector2(tick,-3.0),Vector2(tick,size.y+3.0),T.INK,2.0)


## A command at a glance, as HOI4's army card: men of full strength, will
## and fed, each a short bar in the army bar's colours.
class CommandBars extends Control:
	const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var men:=0
	var full:=0
	var will:=0.0
	var fed:=0.0
	func _ready()->void:custom_minimum_size=Vector2(120,10);mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var width:=minf(80.0,(size.x-12.0)/3.0)
		var shares:=[float(men)/maxf(1.0,float(full)),will,fed]
		var inks:=[T.GREEN,BarModel.will_color(will),T.TEAL if fed>=0.75 else (T.AMBER if fed>=0.4 else T.RED)]
		for i in 3:BarModel.draw_bar(self,Rect2(Vector2(float(i)*(width+6.0),(size.y-7.0)*0.5),Vector2(width,7.0)),clampf(float(shares[i]),0.0,1.0),inks[i])


## The dead on each side, compact (war_ledger_marks.draw_dead).
class DeadStrip extends Control:
	const Marks:=preload("res://scripts/hud/war_ledger_marks.gd")
	var ours:=0
	var theirs:=0
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:Marks.draw_dead(self,Rect2(Vector2.ZERO,size),ours,theirs,true)


## HOT, SIMMERING, WAR (war_ledger_marks.draw_chip).
class Chip extends Control:
	const Marks:=preload("res://scripts/hud/war_ledger_marks.gd")
	var word:=""
	func _ready()->void:
		custom_minimum_size=Vector2(Marks.chip_width(word),24);size_flags_vertical=Control.SIZE_SHRINK_CENTER;mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:Marks.draw_chip(self,Rect2(Vector2(0,0),Vector2(size.x,24)),word)


## A band's state, as the army bar and the map draw it (battle_marks.gd).
class StateMark extends Control:
	const Marks:=preload("res://scripts/hud/battle_marks.gd")
	var state:="holding"
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:Marks.draw_state(self,size*0.5,state,minf(size.x,size.y)*0.5-2.0)
