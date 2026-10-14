extends VBoxContainer
## THE WAR SCREEN, laid out as HOI4 lays out war: the map is the screen, and
## the war reads at a glance around its edges. Grand strategy: the ruler
## decides how many keep watch, how many of them stay home, who leads, and a
## stance toward each enemy; the war leader and the generals do the rest (who
## goes, the road, the camps, the pace, the fight). Nothing here moves a band
## or draws a line. KEEPING WATCH IS THE MILITARY (watch_military.gd): the
## watch share of the people is the manpower; there is no recruiting apart.
##   the column  this board, in the narrow panel at the right edge
##               (military_roster_screen.gd), top to bottom: the manpower
##               (the watch, its share of the people and the control to
##               change it), the home guard (the share of the watch that
##               guards home and the towns, led by the war leader at home),
##               the offensive troops (the rest, in bands led by the
##               generals); then one card per people at feud or war (who is
##               winning, the dead, what is happening now, the stance), the
##               leaders as portrait cards, and the spies, folded;
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
const Watch:=preload("res://scripts/watch_military.gd")
const Allocation:=preload("res://scripts/hud/war_allocation_model.gd")
const Makeup:=preload("res://scripts/army_makeup.gd")
const Economy:=preload("res://scripts/army_economy.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const Dense:=preload("res://scripts/hud/dense_blocks.gd")
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
## The layout the HUD and the roster screen share: the column's width on a
## narrow screen; from WIDE_VIEW on, two panes side by side (column_width).
const COLUMN_WIDTH:=440.0
const WIDE_VIEW:=1520.0
const PANE_GAP:=20


## The column's width for a screen this wide: one pane, or two side by side.
static func column_width(view_width:float)->float:
	return COLUMN_WIDTH*2.0+float(PANE_GAP)-28.0 if view_width>=WIDE_VIEW else COLUMN_WIDTH


## Whether this screen is wide enough for both panes at once.
static func wide(view_width:float)->bool:
	return view_width>=WIDE_VIEW

## The watch, top to bottom: the manpower, the home guard, the offensive
## troops (watch_military.gd reading).
var manpower_box:VBoxContainer
var guard_box:VBoxContainer
var offense_box:VBoxContainer
var enemy_box:VBoxContainer
var border_box:VBoxContainer
var leader_box:VBoxContainer
var needs_box:VBoxContainer
var tabs_row:HBoxContainer
var tab_buttons:={}
var panes:HBoxContainer
var army_pane:VBoxContainer
var side_pane:VBoxContainer
var army_section:VBoxContainer
var fronts_section:VBoxContainer
var leaders_section:VBoxContainer
## The part shown on a narrow screen: "army", "fronts" or "leaders".
var tab:="army"
var costs_expanded:=false
var _wide:=false
var _laid:=false
var leaders_kicker:Label
var leaders_heading:Control
var enemy_count:Label
var feedback:Label
var covert:Control
var covert_toggle:Button
var clock:=0.0
## Capture only ("--capture-war-scroll=<px>"): the column shown further down.
var _capture_scroll:=-1
var _capture_covert:=false
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
	add_theme_constant_override("separation",8)
	feedback=_line("",13,T.GOLD_TEXT,true);feedback.name="Said";feedback.visible=false;feedback.max_lines_visible=3;add_child(feedback)
	# What needs the god now (the notice column's own rows, notification_stack
	# needing()): the column steps aside while this screen holds the right edge,
	# so its rows stand here, one line each, above the army.
	needs_box=VBoxContainer.new();needs_box.name="NeedsYou";needs_box.add_theme_constant_override("separation",3);add_child(needs_box)
	# Three parts: the army, the fronts, the leaders. Side by side on a wide
	# screen; one at a time, by the tabs, on a narrow one.
	tabs_row=HBoxContainer.new();tabs_row.name="WarTabs";tabs_row.add_theme_constant_override("separation",0);add_child(tabs_row)
	panes=HBoxContainer.new();panes.name="Panes";panes.add_theme_constant_override("separation",PANE_GAP);panes.size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_child(panes)
	army_pane=_pane("ArmyPane");panes.add_child(army_pane)
	side_pane=_pane("SidePane");panes.add_child(side_pane)
	army_section=_pane("ArmySection");army_pane.add_child(army_section)
	fronts_section=_pane("FrontsSection");side_pane.add_child(fronts_section)
	leaders_section=_pane("LeadersSection");side_pane.add_child(leaders_section)
	for spec:Array in [["army","Army",army_section],["fronts","Fronts",fronts_section],["leaders","Leaders",leaders_section]]:
		var key:=String(spec[0])
		var tab_button:=Button.new();tab_button.name="Tab_%s" % key;tab_button.text=String(spec[1]);tab_button.toggle_mode=true;tab_button.focus_mode=Control.FOCUS_ALL
		tab_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tab_button.custom_minimum_size=Vector2(0,40)
		tab_button.add_theme_font_override("font",T.font("ui_strong"));tab_button.add_theme_font_size_override("font_size",14)
		for state:String in ["font_color","font_hover_color","font_focus_color"]:tab_button.add_theme_color_override(state,T.INK_MUTED)
		for state:String in ["font_pressed_color","font_hover_pressed_color"]:tab_button.add_theme_color_override(state,T.INK)
		for state:String in ["normal","hover","pressed","hover_pressed"]:tab_button.add_theme_stylebox_override(state,_tab_style(state.contains("pressed"),state.contains("hover")))
		tab_button.add_theme_stylebox_override("focus",T.gold_outline_style())
		tab_button.pressed.connect(func()->void:show_tab(key))
		tabs_row.add_child(tab_button);tab_buttons[key]=tab_button
	# The army, top to bottom: how many and where they stand, the home guard
	# and its towns, what it is made of, what it costs.
	manpower_box=VBoxContainer.new();manpower_box.name="Manpower";manpower_box.add_theme_constant_override("separation",10);army_section.add_child(manpower_box)
	guard_box=VBoxContainer.new();guard_box.name="HomeGuard";guard_box.add_theme_constant_override("separation",6);guard_box.visible=false;army_section.add_child(guard_box)
	offense_box=VBoxContainer.new();offense_box.name="Offensive";offense_box.add_theme_constant_override("separation",6);offense_box.visible=false;army_section.add_child(offense_box)
	# The fronts: each people at feud or war, then our border.
	var enemies_head:=_kicker_row("Enemies",fronts_section)
	enemy_count=enemies_head.get_meta("count")
	enemies_head.add_child(_all_peoples_link())
	enemy_box=VBoxContainer.new();enemy_box.name="Enemies";enemy_box.add_theme_constant_override("separation",8);fronts_section.add_child(enemy_box)
	border_box=VBoxContainer.new();border_box.name="Border";border_box.add_theme_constant_override("separation",6);fronts_section.add_child(border_box)
	# The leaders, then our eyes abroad.
	var leaders_head:=_kicker_row("Leaders",leaders_section)
	# The tab already says "Leaders": its kicker shows only beside the Fronts.
	leaders_kicker=leaders_head.get_child(0)
	leaders_heading=leaders_head
	leader_box=VBoxContainer.new();leader_box.name="Leaders";leader_box.add_theme_constant_override("separation",6);leaders_section.add_child(leader_box)
	# Spies and assassins (covert_board.gd): folded until asked for; it only
	# informs, the god gives covert orders at court.
	covert_toggle=Button.new();covert_toggle.name="CovertToggle";covert_toggle.flat=true;covert_toggle.focus_mode=Control.FOCUS_ALL
	covert_toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT;covert_toggle.add_theme_font_override("font",T.font("ui_strong"));covert_toggle.custom_minimum_size.y=40;covert_toggle.add_theme_font_size_override("font_size",14)
	for state:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:covert_toggle.add_theme_color_override(state,T.INK_MUTED)
	covert_toggle.tooltip_text="Our eyes among other peoples, the wary at home, what word came back and who was caught. Their own page on the rail (F3) sets how hard we watch each people and our own."
	leaders_section.add_child(covert_toggle)
	covert=CovertBoard.new();covert.name="CovertBoard";leaders_section.add_child(covert);covert.setup();covert.visible=false
	for argument in OS.get_cmdline_user_args():
		if String(argument).begins_with("--capture-war-tab="):tab=String(argument).trim_prefix("--capture-war-tab=")
	_apply_width()
	covert_toggle.pressed.connect(func()->void:covert.visible=not covert.visible;_spies_words())
	_spies_words()
	for argument in OS.get_cmdline_user_args():
		if String(argument).begins_with("--capture-war-scroll="):_capture_scroll=int(String(argument).trim_prefix("--capture-war-scroll="))
		if String(argument)=="--capture-covert":covert.visible=true;_spies_words();_capture_covert=true
	refresh(true)


func _process(delta:float)->void:
	if _capture_covert and is_instance_valid(covert):_capture_scroll=maxi(0,int(covert.position.y)-12)
	if _capture_scroll>=0:
		var holder:=get_parent()
		while holder!=null and not holder is ScrollContainer:holder=holder.get_parent()
		if holder!=null:(holder as ScrollContainer).scroll_vertical=_capture_scroll
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## Each section is read again only when what it shows has changed, and not
## under the ruler's hand: a menu of it open, a button held, or the pointer
## on it (for a few seconds). After the ruler's own word (force) all three.
func refresh(force:=false)->void:
	var forces:=Allocation.read(MilitaryCampaign)
	var general:=Orders.war_leader_name()
	var makeup:=Makeup.rows(MilitaryCampaign)
	_apply_width()
	var found:=_needing()
	_rebuild("needs",needs_box,str((found[1] as Array).map(func(n:Dictionary)->Array:return [n.get("key",""),n.get("title",""),n.get("text",""),n.get("verb","")])) if found.size()>1 else "",force,func()->void:_build_needs(found))
	_rebuild("watch",[manpower_box],str([forces,general,makeup.map(func(r:Dictionary)->Array:return [r.share,r.kind,r.men,r.target,snappedf(float(r.armed),0.02),snappedf(float(r.drill),0.02)]),pay_words(),Forces.drawn_from(MilitaryCampaign),int(Purse.state().get("unpaid_months",0))]),force,func()->void:_build_watch(forces,general,makeup))
	_rebuild("border",border_box,str(border_signature()),force,func()->void:_clear(border_box);border_box.add_child(_border_card()))
	_set_tab_counts(forces)
	# A people broken past fighting (no town of its own left) is off the fronts.
	var entries:=Ledger.entries().filter(func(e:Dictionary)->bool:return String(e.kind)!="ended" and not WarLoop.broken(String(e.civ_id)))
	_rebuild("enemies",enemy_box,str(entries.map(func(e:Dictionary)->Array:
		var front:Dictionary=WarLoop.front(String(e.civ_id))
		return [e.civ_id,e.kind,e.hot,e.our_dead,e.their_dead,e.get("quiet",0),front.get("stance",""),front.get("general",""),e.get("strength",1.0),now_words(e)])),force,func()->void:_build_enemies(entries))
	var commands:=Commands.commands(MilitaryCampaign)
	_rebuild("leaders",leader_box,str(commands.map(func(c:Dictionary)->Array:return [c.id,c.bands,c.men,c.full,c.hungry,snappedf(float(c.will),0.05),snappedf(float(c.supply),0.05)])),force,func()->void:_build_leaders(commands))
	if force or clock==0.0:_spies_words()


func _rebuild(key:String,box:Variant,next:String,force:bool,build:Callable)->void:
	if not force and next==String(signatures.get(key,"")):
		waited.erase(key)
		return
	var boxes:Array=box if box is Array else [box]
	if not force and boxes.any(func(b:Control)->bool:return _in_use(b,float(waited.get(key,0.0)))):
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
	_say(String(result.get("said",result.get("error",""))) if String(result.get("said",""))!="" else "The watch is kept at %s of the people." % Law.level_name(id))
	refresh(true)


# --- Forces: where every soldier stands (war_allocation_model.gd) -------------

## Who is under arms and where they stand, top to bottom, every number from
## one ledger (war_allocation_model.gd read): the forces (how many, the share
## of the people with the control to change it, one bar of where every one of
## them is, how ready they are, how many stay home); the towns (each town's
## guard against what it needs); the bands out (men, will and fed, where
## bound).
func _build_watch(f:Dictionary,general:String,makeup:Array=[])->void:
	_clear(manpower_box)
	# The bands out are the army bar's cards along the bottom of the map;
	# here they are one part of the bar of where everyone stands.
	manpower_box.add_child(_forces_card(f,general))
	manpower_box.add_child(_makeup_card(makeup))
	manpower_box.add_child(_cost_card(f))


## What the Border card shows, coarsely, for its rebuild.
static func border_signature()->Array:
	var Forts:=preload("res://scripts/fort_border.gd")
	var kept:=Forts.watch()
	var strengths:=[]
	for s:Dictionary in kept.stretches:strengths.append(snappedf(float(s.strength),0.05))
	return [Forts.forts().map(func(f:Dictionary)->Array:return [int(f.id),String(f.status),snappedf(float(f.get("condition",1.0)),0.1)]),snappedf(Forts.border_share(),0.05),strengths,int(kept.posted)]


## (2b) The border (fort_border.gd), as a section of the Fronts: our forts
## and how well the line holds in one row with its state tag, who stands on
## it, the share of the home guard sent out with the control, and the verb
## to place or move forts on the map itself (hud/border_map.gd).
func _border_card()->Control:
	var Forts:=preload("res://scripts/fort_border.gd")
	var panel:=_card();panel.name="BorderCard"
	var plum:=Color("7b2a7a") if T.is_light() else Color("d69bd2")
	var column:=panel.get_node("Column") as VBoxContainer
	var kept:=Forts.watch()
	var bill:=Forts.costs(null,kept)
	var standing:=Forts.standing().size()
	var going:=Forts.forts().filter(func(f:Dictionary)->bool:return String(f.get("status",""))=="building").size()
	var garrison:=0
	for people:Variant in kept.garrisons.values():garrison+=int(people)
	var held:=0.0;var km:=0.0
	for st:Dictionary in kept.stretches:held+=float(st.strength)*float(st.km);km+=float(st.km)
	var line_strength:=held/km if km>0.0 else 0.0
	# The army's own bands at their border stations (war_council.border_bands):
	# with the forts' watch, everyone of ours on the border. One count.
	var bands:Dictionary=preload("res://scripts/war_council.gd").border_bands()
	var on_border_all:=int(kept.posted)+int(bands.men)
	# Head: the fort mark, "Border", the forts, the state tag.
	var head:=HBoxContainer.new();head.name="Border";head.add_theme_constant_override("separation",8);column.add_child(head)
	var emblem:=TextureRect.new();emblem.texture=Icons.chart_texture("fort:%s" % String(Forts.best_kind().id),plum,64)
	emblem.custom_minimum_size=Vector2(22,22);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.mouse_filter=Control.MOUSE_FILTER_IGNORE;emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(emblem)
	var title:=_line("Border",14,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(title)
	var detail:="%d %s" % [standing,"fort" if standing==1 else "forts"]
	if going>0:detail+=" · %d going up" % going
	if standing+going==0:detail="no forts"
	var count:=_line(detail,12,T.INK_MUTED);count.name="FortCount";count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(count)
	var state_words:="Open"
	var state_ink:=T.INK_MUTED
	if km>0.0:
		state_words="Well watched" if line_strength>=0.7 else ("Watched" if line_strength>=0.4 else "Thin")
		state_ink=T.TEAL_TEXT if line_strength>=0.7 else (T.AMBER_TEXT if line_strength>=0.4 else T.RED_TEXT)
	elif going>0:state_words="Building";state_ink=T.AMBER_TEXT
	elif int(bands.men)>0:state_words="Bands hold it";state_ink=T.AMBER_TEXT
	var tag:=_line(state_words,12,state_ink);tag.name="LineHolds";tag.add_theme_font_override("font",T.font("ui_strong"));tag.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(tag)
	if km<=0.0 and int(bands.men)>0:tag.tooltip_text="No forts are linked, so the border is held by the army's own bands under the Defend stance: %s in %d at their stations, holding %d of the %d km given them. Forts would let the home guard watch it instead." % [EraWords.grouped(int(bands.men)),int(bands.bands),roundi(float(bands.held_km)),roundi(float(bands.assigned_km))]
	elif km>0.0:tag.tooltip_text="%d km linked between forts, %s watching between them. Only linked stretches are watched: about %d in 100 crossings are stopped there, fewer for the stealthy. Unlinked ground stays open." % [roundi(km),EraWords.grouped(int(kept.line)),roundi(line_strength*100.0)]
	else:tag.tooltip_text="No two forts are linked, so nothing watches the ground between them. Raise forts within reach of each other to link their watch."
	if km>0.0:
		var bar:=ShareBar.new();bar.name="LineBar";bar.share=line_strength;bar.ink=T.TEAL if line_strength>=0.7 else (T.AMBER if line_strength>=0.4 else T.RED);bar.custom_minimum_size=Vector2(0,5);bar.mouse_filter=Control.MOUSE_FILTER_PASS
		bar.tooltip_text=tag.tooltip_text;column.add_child(bar)
	# No fort and nobody on it: the head and the verb, nothing more.
	if standing+going==0 and on_border_all<=0:
		var place:=_border_verb(Forts,true)
		place.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		head.add_child(place)
		return panel
	# Who stands on it and what it costs, one line of figures.
	var facts:=HBoxContainer.new();facts.name="BorderFacts";facts.add_theme_constant_override("separation",14);column.add_child(facts)
	facts.add_child(_fact("Posted",compact(on_border_all),"on it","%s of ours on the border: %s of the home guard in the forts and along linked stretches, and %s of the army in %d %s at border stations (the Defend stance)." % [EraWords.grouped(on_border_all),EraWords.grouped(int(kept.posted)),EraWords.grouped(int(bands.men)),int(bands.bands),"band" if int(bands.bands)==1 else "bands"]))
	facts.add_child(_fact("Garrison",compact(garrison),"in forts","%s in the forts. Garrisons are manned first; those left watch the linked stretches." % EraWords.grouped(garrison)))
	var lost:=roundi(float(bill.food_lost))
	facts.add_child(_fact("FoodLoss",compact(lost),"food lost a day","%s food spoils or is eaten on the road each day, in addition to the rations the border watch eats. Roads and carts reduce this loss." % EraWords.grouped(lost),T.RED_TEXT if lost>0 else T.INK))
	# The share of the home guard sent out, and the verb.
	var share:=Forts.border_share()
	var split:=HBoxContainer.new();split.name="BorderCost";split.add_theme_constant_override("separation",6);column.add_child(split)
	var share_words:=_line("Send %d%% of the home guard" % roundi(share*100.0),12,T.INK);share_words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;share_words.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	share_words.tooltip_text="The share of the home guard sent out to the forts and the line between them; garrisons are filled first."
	split.add_child(share_words)
	for step:int in [-1,1]:
		var button:=_step_button("BorderLess" if step<0 else "BorderMore","−" if step<0 else "+","Send 10% fewer of the home guard to the border." if step<0 else "Send 10% more of the home guard to the border; garrisons are filled first.",func()->void:Forts.set_border_share(clampf(Forts.border_share()+float(step)*0.1,0.0,1.0));refresh(true))
		button.disabled=share<=0.0 if step<0 else share>=1.0;split.add_child(button)
	split.add_child(_border_verb(Forts,standing+going==0))
	return panel


## "Place a fort" / "Forts on map": the Border map, on the map itself.
func _border_verb(Forts:GDScript,first:bool)->Button:
	var open:=Dense.verb("Place a fort" if first else "Forts on map",null,"Open the Border map: inspect the watch, choose ground for a fort, or move an existing post.")
	open.name="OpenBorder"
	open.pressed.connect(func()->void:
		var scene:=get_tree().current_scene if is_inside_tree() else null
		if scene==null:return
		close_wanted.emit()
		preload("res://scripts/hud/border_map.gd").set_shown(scene,true))
	return open


## A figure in a line: the number strong, its words muted after it.
func _fact(fact_name:String,value:String,caption:String,tip:String,ink:=T.INK)->Control:
	var row:=HBoxContainer.new();row.name=fact_name;row.add_theme_constant_override("separation",4);row.mouse_filter=Control.MOUSE_FILTER_PASS;row.tooltip_text=tip
	var number:=_line(value,13,ink);number.name="Value";number.add_theme_font_override("font",T.font("ui_strong"));number.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(number)
	var label:=_line(caption,12,T.INK_MUTED);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(label)
	return row


func _card()->PanelContainer:
	# A section of the sheet, not a box on it: a hairline above, no paper.
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",_section_style())
	var column:=VBoxContainer.new();column.name="Column";column.add_theme_constant_override("separation",12);panel.add_child(column)
	return panel


static func _section_style()->StyleBoxFlat:
	var style:=T.paper_panel_style(true,T.RADIUS_CARD,16)
	style.set_border_width_all(0)
	return style


## A big number, its words beside it, and room on the right for buttons.
func _headline(parent:Control,mark:String,number:int,words:String,tip:String)->HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS;row.tooltip_text=tip
	row.add_child(_icon(mark,T.INK,20))
	var big:=_line(compact(number),32,T.INK);big.name="Number";big.add_theme_font_override("font",T.font("ui_strong"));big.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(big)
	var said:=_line(words,13,T.INK_MUTED);said.name="Words";said.size_flags_vertical=Control.SIZE_SHRINK_CENTER;said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;said.clip_text=true;said.text_overrun_behavior=TextServer.OVERRUN_TRIM_WORD;row.add_child(said)
	parent.add_child(row)
	return row


func _step_button(button_name:String,text:String,tip:String,action:Callable)->Button:
	var button:=Button.new();button.name=button_name;button.text=text;button.focus_mode=Control.FOCUS_ALL;button.tooltip_text=tip
	button.custom_minimum_size=Vector2(40,40);button.size_flags_vertical=Control.SIZE_SHRINK_CENTER;button.add_theme_font_size_override("font_size",14);_compact_skin(button,6.0)
	button.pressed.connect(action)
	return button


## Each part of the allocation in its own ink: guard teal, ready green, the
## fronts red (a shade per people), other field work gold, garrisons violet,
## crews blue, drill amber, the hurt and away the rule's grey.
static func part_ink(part:Dictionary,index:=0)->Color:
	match String(part.get("ink","")):
		"guard":return T.TEAL
		"ready":return T.GREEN
		"front":return T.RED.darkened(0.18*float(index%3))
		"field":return T.GOLD
		"held":return T.VIOLET
		"crews":return T.BLUE
		"drill":return T.AMBER
	return T.RULE_STRONG


## (1) The forces: how many are under arms with the control to change it,
## the quick shares, one bar of where every soldier stands with its legend,
## their readiness, where they come from and their pay, and the home guard
## (its share with the control, how many now) over each town's guard.
func _forces_card(f:Dictionary,general:="")->Control:
	var panel:=_card();panel.name="ForcesCard"
	var column:=panel.get_node("Column") as VBoxContainer
	var total:=int(f.total);var watch:=int(f.watch)
	var tip:="The army: everyone in it, anywhere, %s of the people. It is three things: the home guard (some of them out on the border), those free to send, and those in the field. The − and + here set how big it is, as a share of the people: more join at home at once and drill over time; fewer sends the least drilled at home back to their work. Keeping watch on the People view is this same number." % Watch.percent(float(total)/float(maxi(1,int(f.population))))
	var head:=_headline(column,"guard",total,"in the army",tip)
	head.name="Total"
	# Only when the army is not yet the size asked for: a small tag.
	if total!=watch:
		var gap:=_line(("+%s more than asked" % compact(total-watch)) if total>watch else ("%s still joining" % compact(watch-total)),12,T.AMBER_TEXT)
		gap.name="Over" if total>watch else "Under";gap.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		gap.tooltip_text=("You asked for %s. %s more are in the army: away in the field, holding towns, hurt, or kept on because so few are over the share that sending them home is not worth it. Those beyond the share go back to their work when they come home." % [EraWords.grouped(watch),EraWords.grouped(total-watch)]) if total>watch else ("You asked for %s: %s more are still joining." % [EraWords.grouped(watch),EraWords.grouped(watch-total)])
		column.add_child(gap)
	head.add_child(_step_button("WatchLess","−","A smaller army: one in a hundred of the people fewer. The least drilled at home go back to their work.",func()->void:_step_watch(-1)))
	head.add_child(_step_button("WatchMore","+","A bigger army: one in a hundred of the people more. They leave other work and join at home.",func()->void:_step_watch(1)))
	# The quick shares, as plain shares of the people (army_levy_law LEVELS).
	var pick:=HBoxContainer.new();pick.name="Levels";pick.add_theme_constant_override("separation",0);column.add_child(pick)
	var count:=Law.LEVELS.size()
	var now_level:=_nearest_level(float(f.share))
	var now_cost:=Economy.cost(0)
	for i in count:
		var id:=String((Law.LEVELS[i] as Dictionary).id)
		var button:=Button.new();button.name="Level_%s" % id;button.toggle_mode=true;button.focus_mode=Control.FOCUS_ALL
		button.text=Law.level_name(id);button.custom_minimum_size=Vector2(38,40);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_override("font",T.font("ui_strong"));button.add_theme_font_size_override("font_size",13)
		for state:String in ["font_color","font_hover_color","font_focus_color"]:button.add_theme_color_override(state,T.INK_MUTED)
		for state:String in ["font_pressed_color","font_hover_pressed_color"]:button.add_theme_color_override(state,T.INK)
		button.add_theme_stylebox_override("normal",_segment(false,false,i,count));button.add_theme_stylebox_override("hover",_segment(false,true,i,count))
		button.add_theme_stylebox_override("pressed",_segment(true,false,i,count));button.add_theme_stylebox_override("hover_pressed",_segment(true,true,i,count))
		button.add_theme_stylebox_override("focus",T.gold_outline_style())
		button.set_pressed_no_signal(id==now_level)
		var at_level:=Law.target_men(id,int(f.population))
		var effect:=Economy.step_words(now_cost,Economy.cost(at_level-watch)) if at_level>watch else PackedStringArray()
		button.tooltip_text="An army of %s of the people.\n%s%s" % [Law.level_name(id),Law.cost_words(id,int(f.population),int(f.able)),("\n\n"+"\n".join(effect)) if not effect.is_empty() else ""]
		button.pressed.connect(func()->void:_choose_level(id))
		pick.add_child(button)
	# Where every one of them stands: one bar, its legend under it (the home
	# guard's part is named once, on its own line below).
	var bar:=AllocationBar.new();bar.name="Allocation";bar.parts=f.parts;bar.target=watch;bar.custom_minimum_size=Vector2(0,14)
	bar.tooltip_text=allocation_words(f)
	column.add_child(bar)
	var legend:=HFlowContainer.new();legend.name="Legend";legend.add_theme_constant_override("h_separation",12);legend.add_theme_constant_override("v_separation",2);column.add_child(legend)
	var fronts:=0
	var guard:=0
	for part:Dictionary in f.parts:
		var ink:=part_ink(part,fronts)
		if String(part.ink)=="front":fronts+=1
		if String(part.id)=="guard":guard=int(part.men);continue
		legend.add_child(_legend_chip(part,ink))
	# How ready they are: drill and arms at home, will and fed of those out.
	var ready:Dictionary=f.ready_share
	var gauges:=HBoxContainer.new();gauges.name="Readiness";gauges.add_theme_constant_override("separation",10);column.add_child(gauges)
	gauges.add_child(_gauge("Drill",float(ready.drill),T.GREEN if float(ready.drill)>=0.6 else T.AMBER,"Drill: how well the watch at home is drilled, rising every day it drills at the training policy's pace."))
	# One measure of "armed" everywhere: the whole army's gear in hand
	# (strength()), never the home guard's alone.
	var armed_all:=float(strength(MilitaryCampaign).armed)
	gauges.add_child(_gauge("Armed",armed_all,BarModel.gear_color(armed_all),"Armed: %d%% of the gear our soldiers need is in their hands, at home and in the bands; the rest fight with what comes to hand. Short kit is made in the workshops (Production)." % roundi(armed_all*100.0)))
	gauges.add_child(_gauge("Will",float(ready.will),BarModel.will_color(maxf(0.0,float(ready.will))),"Will to fight of the bands out, by their men. Below a third they are close to breaking." if float(ready.will)>=0.0 else "Will to fight of the bands out: nobody is out."))
	gauges.add_child(_gauge("Fed",float(ready.fed),T.TEAL if float(ready.fed)>=0.75 else (T.AMBER if float(ready.fed)>=0.4 else T.RED),"Fed in the field: the share of the rations the bands out need that reached them." if float(ready.fed)>=0.0 else "Fed in the field: nobody is out."))
	# Where they come from and their pay: two facts, said once, here.
	var facts:=HBoxContainer.new();facts.name="Facts";facts.add_theme_constant_override("separation",14);column.add_child(facts)
	var from:=Forces.drawn_from(MilitaryCampaign)
	var drawn:=_line("1 in %s from work" % EraWords.grouped(int(from.one_in)) if int(from.soldiers)>0 else "None taken from work",12,T.INK_MUTED);drawn.name="DrawnFrom";drawn.mouse_filter=Control.MOUSE_FILTER_PASS
	drawn.tooltip_text="In the army, not at other work: %s of %s who can work.\nEvery one of them is one fewer getting food, making or building." % [EraWords.grouped(int(from.soldiers)),EraWords.grouped(int(from.workers))]
	facts.add_child(drawn)
	var pay:=pay_words()
	if pay!="":
		var months:=int(Purse.state().get("unpaid_months",0))
		var pay_word:="Pay: paid";var pay_ink:=T.GREEN_TEXT
		if months>0:pay_word="Pay: unpaid %d %s" % [months,"month" if months==1 else "months"];pay_ink=T.RED_TEXT
		elif not Purse.line_on("army"):pay_word="Pay: stopped";pay_ink=T.AMBER_TEXT
		var paid:=_line(pay_word,12,pay_ink);paid.name="Pay";paid.mouse_filter=Control.MOUSE_FILTER_PASS
		paid.tooltip_text="%s\nSoldiers are paid from %s on top of their rations. Unpaid, they lose will each month, are slower to muster, and some go home. The Wealth page sets it." % [pay,Purse.account_name()]
		facts.add_child(paid)
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;facts.add_child(spacer)
	var people:=Button.new();people.name="People";people.text="People ›";people.flat=true;people.focus_mode=Control.FOCUS_ALL
	people.add_theme_font_size_override("font_size",12);people.add_theme_color_override("font_color",T.GOLD_TEXT);people.add_theme_color_override("font_hover_color",T.INK)
	people.tooltip_text="Who works at what, keeping watch among the rest (the People view)."
	people.pressed.connect(_open_people)
	facts.add_child(people)
	# The home guard: its share of the army with the control, how many now
	# (said once, here), and each town's guard against what it needs.
	var guard_title:=_line("Home guard",20,T.INK);guard_title.add_theme_font_override("font",T.font("ui_strong"));column.add_child(guard_title)
	var split:=HBoxContainer.new();split.name="Split";split.add_theme_constant_override("separation",6);column.add_child(split)
	var swatch:=ColorRect.new();swatch.color=T.TEAL;swatch.custom_minimum_size=Vector2(9,9);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;split.add_child(swatch)
	var on_border:=int(preload("res://scripts/fort_border.gd").watch().get("posted",0))
	var split_words:=_line("Keep %d%% · %s now" % [roundi(float(f.home_share)*100.0),compact(guard)],13,T.INK);split_words.name="GuardLine";split_words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;split_words.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	split_words.tooltip_text="The home guard: the part of the army kept at home and in the towns, %s of them now%s, led by %s. The war council never sends the home guard away; everyone else is free to send. The − and + move it by a tenth of the army." % [EraWords.grouped(guard),(" (%s out on the border)" % EraWords.grouped(on_border)) if on_border>0 else "",(general+", the war leader") if general!="" else "the war leader"]
	split.add_child(split_words)
	split.add_child(_step_button("GuardLess","−","A smaller home guard, by a tenth of the army: more are free to send.",func()->void:_step_split(-1)))
	split.add_child(_step_button("GuardMore","+","A bigger home guard, by a tenth of the army: idle bands come home to guard.",func()->void:_step_split(1)))
	# Who stands at home and who would rise, in the words every screen uses
	# (watch_military.gd home_standing).
	var standing:=Watch.home_standing(MilitaryCampaign)
	var rise_line:=_line("%s on watch, %s can rise, all towns" % [compact(int(standing.on_watch)),compact(int(standing.can_rise))],12,T.INK_MUTED);rise_line.name="OnWatch"
	rise_line.tooltip_text="Counted over all our towns that keep a guard (home alone: %s can rise).
On watch: everyone under arms standing in our towns today, the home guard there and those free to send (%s posted out on the border besides).
Can rise: the townsfolk who take up arms beside them, untrained, when raiders come." % [EraWords.grouped(int(standing.can_rise_home)),EraWords.grouped(int(standing.on_border))]
	var standing_row:=HBoxContainer.new();standing_row.add_theme_constant_override("separation",14);standing_row.add_child(rise_line)
	# The home guard posted out, said beside it so the counts add up.
	if int(standing.on_border)>0:
		var posted:=_line("%s on the border" % compact(int(standing.on_border)),12,T.INK_MUTED);posted.name="OnBorderLine"
		posted.tooltip_text="Of the home guard, posted to the forts and the line between them; not in the towns."
		standing_row.add_child(posted)
	var indent:=MarginContainer.new();indent.add_theme_constant_override("margin_left",17);indent.add_child(standing_row);column.add_child(indent)
	column.add_child(_towns_rows(f))
	return panel


## Each town's share of the home guard against what it needs, short in red:
## one row a town, the four most short first; the rest in the tooltip.
func _towns_rows(f:Dictionary)->Control:
	var box:=VBoxContainer.new();box.name="TownsCard";box.add_theme_constant_override("separation",2)
	var towns:Array=(f.towns as Array).duplicate()
	if towns.is_empty():return box
	var home:Dictionary=towns[0]
	var rest:=towns.slice(1)
	rest.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.short)>int(b.short))
	var ordered:=[home]+rest
	var shown:=ordered.slice(0,4)
	var short_towns:=towns.filter(func(t:Dictionary)->bool:return int(t.short)>0).size()
	for town:Dictionary in shown:
		var row:=HBoxContainer.new();row.name="Town_%s" % String(town.id);row.add_theme_constant_override("separation",8);row.mouse_filter=Control.MOUSE_FILTER_PASS
		var pad:=Control.new();pad.custom_minimum_size=Vector2(9,0);pad.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(pad)
		var short:=int(town.short)
		var name_label:=_line(String(town.name),12,T.INK);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(name_label)
		var bar:=ShareBar.new();bar.share=float(town.guard)/float(maxi(1,int(town.need)));bar.ink=T.TEAL if short<=0 else T.RED;bar.custom_minimum_size=Vector2(90,5);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(bar)
		var count:=_line("%s of %s needed" % [compact(int(town.guard)),compact(int(town.need))],12,T.INK if short<=0 else T.RED_TEXT);count.add_theme_font_override("font",T.font("ui_strong"));count.custom_minimum_size=Vector2(118,0);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;count.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(count)
		row.tooltip_text="%s: %s of its %s people on guard; it needs %s (%s of its people, at least %d).%s" % [String(town.name),EraWords.grouped(int(town.guard)),EraWords.grouped(int(town.people)),EraWords.grouped(int(town.need)),Watch.percent(Watch.GUARD_SHARE),Watch.GUARD_MIN,(" %s short: raise the army or keep more at home." % EraWords.grouped(short)) if short>0 else ""]
		box.add_child(row)
	if towns.size()>shown.size():
		var others:=ordered.slice(shown.size())
		short_towns=others.filter(func(t:Dictionary)->bool:return int(t.short)>0).size()
		var more:=_line("+%d more towns%s" % [others.size(),(" · %d short" % short_towns) if short_towns>0 else ""],12,T.RED_TEXT if short_towns>0 else T.INK_MUTED);more.name="MoreTowns"
		more.tooltip_text="\n".join(others.map(func(t:Dictionary)->String:return "%s: %s / %s" % [String(t.name),EraWords.grouped(int(t.guard)),EraWords.grouped(int(t.need))]))
		var indent:=MarginContainer.new();indent.add_theme_constant_override("margin_left",17);indent.add_child(more);box.add_child(indent)
	return box


## (1b) The army's makeup (army_makeup.gd): each kind of fighter, the
## best our people can field in it today, its share with the control to
## change it, and its men against the share, armed and drilled. The war
## leader does the rest: the men join or retrain, the workshops make the
## kits and the carts.
func _makeup_card(rows:Array)->Control:
	var panel:=_card();panel.name="MakeupCard"
	var column:=panel.get_node("Column") as VBoxContainer
	var title:=_line("Army makeup",20,T.INK);title.add_theme_font_override("font",T.font("ui_strong"))
	title.tooltip_text="Set what the army is made of. The war leader fills each kind with the best fighters and gear our people can make, retrains a few at home each day toward it, and has the workshops make the kits and carts it needs."
	title.mouse_filter=Control.MOUSE_FILTER_PASS
	column.add_child(title)
	# A kind with nobody in it and no share asked is not a row with a dead
	# bar: it is one of the buttons on the last line.
	var empty:Array=[]
	for r:Dictionary in rows:
		if int(r.men)<=0 and int(r.target)<=0 and float(r.share)<=0.0:empty.append(r)
		else:column.add_child(_makeup_row(r))
	if not empty.is_empty():
		var add:=HFlowContainer.new();add.name="AddKinds";add.add_theme_constant_override("h_separation",4);add.add_theme_constant_override("v_separation",4);column.add_child(add)
		var word:=_line("Add",12,T.INK_MUTED);word.size_flags_vertical=Control.SIZE_SHRINK_CENTER;add.add_child(word)
		for r:Dictionary in empty:
			var id:=String(r.id)
			var more:=_small_button(String(r.label),"plus","A tenth of the army as %s. %s" % [String(r.label).to_lower(),("Our best now: %s." % String(r.kind)) if bool(r.can) else "Our people cannot train any of these yet."])
			more.name="Add_%s" % id;more.disabled=not bool(r.can)
			_compact_skin(more,4.0);more.add_theme_constant_override("h_separation",2)
			more.pressed.connect(func()->void:_step_makeup(id,1))
			add.add_child(more)
	return panel


func _makeup_row(r:Dictionary)->Control:
	var row:=HBoxContainer.new();row.name="Kind_%s" % String(r.id);row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS
	var can:=bool(r.can)
	var glyph:=Blocks.glyph_of(String(r.unit),String(r.item)) if can else String(r.glyph)
	var icon:=TextureRect.new();icon.texture=Icons.arm_texture(glyph,T.INK if can else T.INK_MUTED,T.GOLD,64);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size=Vector2(26,26);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",0);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(words)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(top)
	var name_label:=_line(String(r.label),13,T.INK if can else T.INK_MUTED);name_label.add_theme_font_override("font",T.font("ui_strong"));name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(name_label)
	var men:=_line("%s / %s" % [compact(int(r.men)),compact(int(r.target))],12,T.INK if int(r.men)>=int(r.target) else T.AMBER_TEXT);men.mouse_filter=Control.MOUSE_FILTER_IGNORE;men.size_flags_horizontal=Control.SIZE_EXPAND_FILL;men.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;top.add_child(men)
	var waiting:=String(r.get("waiting",""))
	# The kind of fighter only; the kit they carry is in the tooltip.
	var kind:=_line(String(r.kind).get_slice(" · ",0) if waiting=="" else "%s · waiting" % String(r.best).get_slice(" · ",0),11,T.INK_MUTED if waiting=="" else T.AMBER_TEXT);kind.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;kind.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(kind)
	var bars:=HBoxContainer.new();bars.add_theme_constant_override("separation",4);bars.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(bars)
	for pair:Array in [[float(r.armed),BarModel.gear_color(maxf(0.0,float(r.armed)))],[float(r.drill),T.GREEN if float(r.drill)>=0.6 else T.AMBER]]:
		var bar:=ShareBar.new();bar.share=maxf(0.0,float(pair[0]));bar.ink=pair[1];bar.custom_minimum_size=Vector2(0,4);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;bars.add_child(bar)
	var share:=_line("%d%%" % roundi(float(r.share)*100.0),14,T.INK);share.add_theme_font_override("font",T.font("ui_strong"));share.custom_minimum_size=Vector2(40,0);share.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;share.size_flags_vertical=Control.SIZE_SHRINK_CENTER;share.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(share)
	var id:=String(r.id)
	var less:=_step_button("Less_%s" % id,"−","A tenth of the army fewer %s; the others take their place." % String(r.label).to_lower(),func()->void:_step_makeup(id,-1))
	var more:=_step_button("More_%s" % id,"+","A tenth of the army more %s." % String(r.label).to_lower(),func()->void:_step_makeup(id,1))
	less.disabled=float(r.share)<=0.0;more.disabled=not can or float(r.share)>=1.0
	row.add_child(less);row.add_child(more)
	var tip:=PackedStringArray([String(r.tip),
		("Our best now: %s." % String(r.kind)) if can else "Our people cannot train any of these yet.",
		("%s wait for their kit: %s" % [String(r.best),waiting]) if waiting!="" else "",
		Economy.kit_words(String(r.unit),String(r.item)) if can else "",
		"%s of %s in the share (%d%% of the army)." % [EraWords.grouped(int(r.men)),EraWords.grouped(int(r.target)),roundi(float(r.share)*100.0)],
		("Armed: %d%% of their kit in hand." % roundi(float(r.armed)*100.0)) if float(r.armed)>=0.0 else "",
		("Drill: %d%%." % roundi(float(r.drill)*100.0)) if float(r.drill)>=0.0 else ""])
	row.tooltip_text="
".join(Array(tip).filter(func(x:String)->bool:return x!=""))
	return row


func _step_makeup(id:String,direction:int)->void:
	var result:=Makeup.step(MilitaryCampaign,id,direction)
	if result.has("error"):_say(String(result.error))
	refresh(true)


## (1c) What the army costs the people (army_economy.gd), as it is and with
## one step more (a hundredth of the people): the hands it takes and from
## which work, the food, the births past the watch the people can spare,
## the pay, the gear and the carts still to make. Red where it hurts.
func _cost_card(f:Dictionary)->Control:
	var panel:=_card();panel.name="CostCard"
	var outer:=panel.get_node("Column") as VBoxContainer
	var toggle:=Button.new();toggle.name="CostDetails";toggle.text="Cost to the people  ▾" if costs_expanded else "Cost to the people  ›";toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT;T.apply_button_style(toggle,false);outer.add_child(toggle)
	var column:=VBoxContainer.new();column.name="CostComparison";column.add_theme_constant_override("separation",8);column.visible=costs_expanded;outer.add_child(column)
	toggle.pressed.connect(func()->void:costs_expanded=not costs_expanded;column.visible=costs_expanded;toggle.text="Cost to the people  ▾" if costs_expanded else "Cost to the people  ›")
	var now:=Economy.cost(0)
	var population:=maxi(1,int(f.population))
	var next_share:=(floorf(float(f.share)*100.0+0.0001)+1.0)/100.0
	var extra:=maxi(1,roundi(float(population)*next_share)-int(now.watch))
	var more:=Economy.cost(extra)
	var warnings:=PackedStringArray()
	if float(now.food_net)<0.0:warnings.append("Food: %s a day" % _signed_compact(float(now.food_net)))
	if float(now.pay_season)>float(now.income_season):warnings.append("Army pay exceeds income")
	if float(now.births)>0.05:warnings.append("Births lost: %s of 100" % _births_words(float(now.births)))
	if not warnings.is_empty():
		var warning:=_line(" · ".join(warnings),14,T.RED_TEXT,true);warning.name="CostWarning";outer.add_child(warning);outer.move_child(warning,1)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",6);column.add_child(head)
	var title:=_line("Impact",14,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(title)
	head.add_child(_cost_cell("now",T.INK_MUTED,76));head.add_child(_cost_cell("with +%s" % compact(extra),T.INK_MUTED,76))
	title.mouse_filter=Control.MOUSE_FILTER_PASS
	title.tooltip_text="What keeping this army costs, from the engine's own rules: now, and with %s more under arms (%s of the people)." % [EraWords.grouped(extra),Watch.percent(next_share)]
	var food_now:=float(now.food_net);var food_more:=float(more.food_net)
	var manual:=WorldSimulation.actor_id=="player" and Economy.Manual.manual()
	_cost_row(column,"Hands","%s · 1 in %d" % [compact(int(now.watch)),int(now.one_in)] if int(now.watch)>0 else "none",
		"%s · 1 in %d" % [compact(int(more.watch)),int(more.one_in)],T.AMBER_TEXT if int((more.from as Dictionary).get("Food",0))>0 else T.INK,
		"Everyone under arms is off other work: %s of %s who can work. %s more would come from %s.%s" % [EraWords.grouped(int(now.watch)),EraWords.grouped(int(now.able)),EraWords.grouped(extra),Economy.from_words(more.from),
			" With the daily work set by hand the watch takes from the biggest task first." if manual else " The leaders take them from every task in its share."])
	# Grown less eaten, before spoilage and drying: not the Economy page's
	# "Kept" (the change in the stores after them), so not called that.
	_cost_row(column,"Food grown less eaten",_signed_compact(food_now),_signed_compact(food_more),T.RED_TEXT if food_more<0.0 else T.INK,
		"Food grown and gathered against food eaten, a day, before spoilage and drying (the Economy page's Kept is the stores' change after them): %s in, %s eaten (soldiers eat %s of a ration more each than at rest). With %s more: %s fewer brought in by the food getters they leave, %s more eaten.%s" % [EraWords.grouped(roundi(float(now.food_in))),EraWords.grouped(roundi(float(now.food_need))),str(Economy.Impact.EXERTION.Defense),EraWords.grouped(extra),EraWords.grouped(roundi(float(more.food_lost))),EraWords.grouped(roundi(float(more.food_need)-float(now.food_need))),
			(" The stores hold about %s days." % EraWords.grouped(roundi(float(now.food_days)))) if float(now.food_days)>0.0 else ""],food_now<0.0)
	_cost_row(column,"Births lost, of 100",_births_words(float(now.births)),_births_words(float(more.births)),T.RED_TEXT if float(more.births)>0.05 else T.INK,
		"Up to %s can keep watch at no extra cost (5 in 100 of the people, or the towns' guard if more). Past that every one more costs births, work and weariness, as an extra learner does: %s over now, %s with %s more." % [EraWords.grouped(int(now.free)),EraWords.grouped(roundi(float(now.over))),EraWords.grouped(roundi(float(more.over))),EraWords.grouped(extra)],float(now.births)>0.05)
	var income:=maxf(0.0,float(now.income_season))
	var pay_now:=_pay_share(float(now.pay_season),income);var pay_more:=_pay_share(float(more.pay_season),income)
	# Past all the realm brings in, the figures themselves: pay against income.
	var over_now:=pay_now.begins_with("over");var over_more:=pay_more.begins_with("over")
	if over_now or over_more:
		pay_now=_pay_against(float(now.pay_season),income);pay_more=_pay_against(float(more.pay_season),income)
	_cost_row(column,"Pay a season, of income" if (over_now or over_more) else "Pay, share of income",pay_now,pay_more,T.RED_TEXT if over_more else T.INK,
		"Soldiers' pay against what the realm brings in a season (%s): %s now, %s with %s more.%s" % [Purse.amount_text(income),Purse.amount_text(float(now.pay_season)),Purse.amount_text(float(more.pay_season)),EraWords.grouped(extra),
			" The pay is more than all the realm brings in: it comes out of the stores, and unpaid soldiers lose will." if over_more else ""],over_now)
	var gear_tip:=PackedStringArray()
	for row:Dictionary in now.gear:gear_tip.append("%s %s: %s maker-days%s" % [EraWords.grouped(int(row.sets)),String(row.name).to_lower(),EraWords.grouped(roundi(float(row.days))),(" · "+Economy.materials_words(row.materials)) if not (row.materials as Dictionary).is_empty() else ""])
	_cost_row(column,"Gear, maker-days",compact(roundi(float(now.gear_days))) if float(now.gear_days)>=0.5 else "none",compact(roundi(float(more.gear_days))),T.INK,
		("The kits the army still lacks, made by the makers and the workshops, taking their materials from the stores:\n"+"\n".join(gear_tip)+(("\nMaterials: "+Economy.materials_words(now.gear_materials,6)) if not (now.gear_materials as Dictionary).is_empty() else "")) if not gear_tip.is_empty() else "Every soldier has his kit. More soldiers, or another makeup, need more.")
	_cost_row(column,"Carts to build",compact(int(now.carts)) if int(now.carts)>0 else "none",compact(int(more.carts)) if int(more.carts)>0 else "none",T.INK,
		"A baggage train of a cart for every %d under arms, as the carriers can drive them: %s in store, %s to build%s." % [int(Economy.Carts.READY_PER),EraWords.grouped(int(now.carts_held)),EraWords.grouped(int(now.carts)),(" ("+Economy.materials_words(now.carts_materials)+")") if not (now.carts_materials as Dictionary).is_empty() else ""])
	return panel


func _cost_row(parent:Control,label:String,now:String,more:String,more_ink:Color,tip:String,now_bad:=false)->void:
	var row:=HBoxContainer.new();row.name="Cost_%s" % label.replace(" ","");row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS;row.tooltip_text=tip
	var name_label:=_line(label,12,T.INK_MUTED);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(name_label)
	row.add_child(_cost_cell(now,T.RED_TEXT if now_bad else T.INK,76,true))
	row.add_child(_cost_cell(more,more_ink,76,true))
	parent.add_child(row)


func _cost_cell(text:String,ink:Color,width:float,strong:=false)->Label:
	var cell:=_line(text,12,ink);cell.custom_minimum_size=Vector2(width,0);cell.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;cell.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cell.clip_text=false
	if strong:cell.add_theme_font_override("font",T.font("ui_strong"))
	return cell


static func _signed_compact(v:float)->String:
	if absf(v)<0.5:return "0"
	return ("+" if v>=0.0 else "−")+compact(roundi(absf(v)))


## Pay against income, the figures themselves: "40 of 1".
static func _pay_against(pay:float,income:float)->String:
	return "%s of %s" % [compact(roundi(pay)),compact(roundi(income))]


## Pay as a share of what the realm brings in, never a runaway figure: past
## all of it, "over all".
static func _pay_share(pay:float,income:float)->String:
	if pay<=0.0:return "none"
	if income<=0.0 or pay>income:return "over all"
	return _pct(pay/income)


static func _pct(share:float)->String:
	return ("%.1f%%" % (share*100.0)) if share<0.1 else "%d%%" % roundi(share*100.0)


static func _births_words(fewer:float)->String:
	return "%.1f" % fewer if fewer>=0.05 else "none"


## The bar in words, part by part, for the pointer.
static func allocation_words(f:Dictionary)->String:
	var lines:=PackedStringArray(["The army: %s." % EraWords.grouped(int(f.total))])
	for part:Dictionary in f.parts:lines.append("%s: %s" % [String(part.label),EraWords.grouped(int(part.men))])
	lines.append("The tick marks the share the people keep on watch: %s." % EraWords.grouped(int(f.watch)))
	return "\n".join(lines)


func _legend_chip(part:Dictionary,ink:Color)->Control:
	var chip:=HBoxContainer.new();chip.name="Part_%s" % String(part.id).replace(":","_");chip.add_theme_constant_override("separation",4);chip.mouse_filter=Control.MOUSE_FILTER_PASS
	var swatch:=ColorRect.new();swatch.color=ink;swatch.custom_minimum_size=Vector2(9,9);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(swatch)
	var said:=_line(String(part.label),12,T.INK_MUTED);said.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(said)
	var men:=_line(compact(int(part.men)),12,T.INK if int(part.men)>0 else T.INK_MUTED);men.add_theme_font_override("font",T.font("ui_strong"));men.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(men)
	chip.tooltip_text="%s: %s.\n%s" % [String(part.label),EraWords.grouped(int(part.men)),String(part.tip)]
	return chip


## A small labelled gauge: "Drill 70%" over a short bar; "—" when unknown.
func _gauge(label:String,share:float,ink:Color,tip:String)->Control:
	var box:=VBoxContainer.new();box.name=label;box.add_theme_constant_override("separation",1);box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.mouse_filter=Control.MOUSE_FILTER_PASS;box.tooltip_text=tip
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",4);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(top)
	var word:=_line(label,12,T.INK_MUTED);word.mouse_filter=Control.MOUSE_FILTER_IGNORE;word.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(word)
	var value:=_line("%d%%" % roundi(share*100.0) if share>=0.0 else "—",12,T.INK);value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(value)
	var bar:=ShareBar.new();bar.share=share;bar.ink=ink;bar.custom_minimum_size=Vector2(0,5);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(bar)
	return box


## The level whose share is nearest the watch's (0.5 point at most), or "".
static func _nearest_level(share:float)->String:
	for entry:Dictionary in Law.LEVELS:
		if absf(float(entry.share)-share)<=0.005:return String(entry.id)
	return ""


## The watch one in a hundred of the people up or down (to the next whole
## share), through the People view's own split (watch_military.gd).
func _step_watch(direction:int)->void:
	var r:=Watch.reading(MilitaryCampaign)
	var percent:=float(r.share)*100.0
	var next:=(floorf(percent+0.0001)+1.0) if direction>0 else maxf(0.0,ceilf(percent-0.0001)-1.0)
	var result:=MilitaryCampaign.set_watch_share(next/100.0)
	_say(String(result.get("said",result.get("error",""))))
	refresh(true)


## The home guard a tenth of the watch up or down.
func _step_split(direction:int)->void:
	var share:=clampf(snappedf(MilitaryCampaign.watch_split()+float(direction)*Watch.HOME_SHARE_STEP,Watch.HOME_SHARE_STEP),0.0,1.0)
	var result:=MilitaryCampaign.set_watch_split(share)
	_say(String(result.get("said",result.get("error",""))))
	refresh(true)


func _open_people()->void:
	var scene:=get_tree().current_scene if is_inside_tree() else null
	var hud:Variant=scene.get("hud") if scene!=null else null
	if hud==null or not hud.has_method("has_provider") or not hud.has_provider("overview"):return
	close_wanted.emit()
	hud.open_dock("overview",0)


## The home guard by town, as the guard ledger spreads it
## (civilization_combat.gd): [{id, name, guard}], home first.
static func guard_towns(mc:Node)->Array:
	var out:Array=[]
	var ledger:Dictionary=preload("res://scripts/civilization_combat.gd").guard_ledger(mc)
	for city:Dictionary in WorldSimulation.state.player_settlements:
		var id:=String(city.get("id",""))
		if not ledger.has(id):continue
		var entry:={"id":id,"name":String(city.get("name","")) if String(city.get("name",""))!="" else String(WorldSimulation.state.settlement_name),"guard":int((ledger[id] as Dictionary).get("watch",0))}
		if bool(city.get("primary",false)):out.push_front(entry)
		else:out.append(entry)
	return out


## A count that fits a chip at any size: "120", "48,300", "1.2 million",
## "3.4 billion" (the full count is in the chip's tooltip).
static func compact(value:int)->String:
	if absi(value)<1_000_000:return EraWords.grouped(value)
	if absi(value)<1_000_000_000:return "%s million" % _one_place(float(value)/1_000_000.0)
	return "%s billion" % _one_place(float(value)/1_000_000_000.0)


## Travel time in the one unit the war map uses too (war_ledger_model
## span_words): days under two months, then months, then winters.
static func _days(count:int)->String:
	return Ledger.span_words(count)


static func _one_place(value:float)->String:
	return str(roundi(value)) if absf(value)>=100.0 or is_equal_approx(value,roundf(value)) else "%.1f" % value


# --- Our enemies ----------------------------------------------------------

func _build_enemies(entries:Array)->void:
	_clear(enemy_box)
	enemy_count.text=str(entries.size()) if not entries.is_empty() else ""
	if entries.is_empty():
		# At peace is one small line; the border below is what can be done.
		var row:=HBoxContainer.new();row.name="Calm";row.add_theme_constant_override("separation",6);enemy_box.add_child(row)
		row.add_child(_icon("leave",T.INK_MUTED,14))
		var said:=_line("At peace with everyone",12,T.INK_MUTED);said.tooltip_text="No feud or war with anyone.";row.add_child(said)
		enemy_box.add_child(_neighbours())
		return
	for e:Dictionary in entries:enemy_box.add_child(_enemy_row(e))


## At peace, the peoples we know, nearest first, as the enemies would be
## read: their mark, name, what lies between us, their warriors as our
## watchers reckon them and the march to their nearest town we know.
func _neighbours()->Control:
	var Known:=preload("res://scripts/hud/peoples_known_model.gd")
	var box:=VBoxContainer.new();box.name="Neighbours";box.add_theme_constant_override("separation",0)
	var peoples:Array=Known.met_peoples(int(WorldSimulation.state.elapsed_days)) if WorldSimulation!=null and WorldSimulation.state!=null else []
	if peoples.is_empty():return box
	var home:Vector2=CivilizationSystem.player_world_origin
	var reach:={}
	for people:Dictionary in peoples:
		var at:Dictionary=people.get("home_position",{}) if people.get("home_position") is Dictionary else {}
		reach[String(people.civ_id)]=home.distance_to(Vector2(float(at.get("x",0.0)),float(at.get("z",0.0)))) if not at.is_empty() else INF
	peoples.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(reach[String(a.civ_id)])<float(reach[String(b.civ_id)]))
	var rows:Array=[]
	for people:Dictionary in peoples.slice(0,5):
		var civ_id:=String(people.civ_id)
		var e:=Allocation.enemy(civ_id,0,true)
		var between:=Known.relation_cell(people)
		var nearest:Dictionary=e.nearest
		var tone:=String(between.get("tone","ink"))
		rows.append({"icon":Identity.emblem(civ_id),"cells":{"name":String(people.name),"warriors":Allocation.theirs_words(e),"march":_days(int(nearest.days)) if not nearest.is_empty() else "—"},
			"tag":{"text":String(between.get("text","")),"tone":{"danger":"bad","warn":"warn","good":"good"}.get(tone,"")},
			"tip":"%s: %s
%s
%s" % [String(people.name),String(between.get("tip","")),"We know too little of them to count their warriors." if bool(e.unknown) else "Their warriors as our watchers reckon them: about %s (between %s and %s)." % [EraWords.grouped(int(e.theirs)),EraWords.grouped(int(e.low)),EraWords.grouped(int(e.high))],
				("Their nearest town we know, %s, lies about %s km off: some %s on the road." % [String(nearest.name),EraWords.grouped(roundi(float(nearest.km))),_days(int(nearest.days))]) if not nearest.is_empty() else "We know of no town of theirs yet: scouts find their towns."]})
	Dense.render_table(box,{"columns":[{"key":"name","label":"Peoples we know"},{"key":"warriors","label":"warriors","width":84,"align":"right"},{"key":"march","label":"march","width":66,"align":"right"}],"rows":rows})
	if peoples.size()>5:box.add_child(_line("+%d more peoples" % (peoples.size()-5),12,T.INK_MUTED))
	return box


## One people at feud or war, as an HOI4 war card: who they are and how hot,
## the dead on each side, who is winning, what is happening now, and the
## stance as a row of buttons.
func _enemy_row(e:Dictionary)->Control:
	var civ_id:=String(e.civ_id)
	var tone:=LedgerMarks.chip_tone(Ledger.state_word(e))
	var panel:=PanelContainer.new();panel.name="Enemy_%s" % civ_id
	# The people's war in a band of its tone down the left, not a box.
	var band:=StyleBoxFlat.new();band.bg_color=Color(tone,0.06);band.border_color=Color(tone,0.85);band.border_width_left=3
	band.content_margin_left=10.0;band.content_margin_right=4.0;band.content_margin_top=6.0;band.content_margin_bottom=6.0
	panel.add_theme_stylebox_override("panel",band)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);column.add_child(head)
	var emblem:=TextureRect.new();emblem.texture=Identity.emblem(civ_id);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.custom_minimum_size=Vector2(30,30)
	emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(emblem)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",-2);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_PASS;head.add_child(words)
	var title:=Label.new();title.text=String(e.name);T.text(title,"body",T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.add_theme_font_size_override("font_size",20);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(title)
	var since:=int(e.get("days",0))
	words.add_child(_line("%s · %s" % ["War" if String(e.kind)=="war" else "Feud","begun today" if since<=0 else Ledger.span_words(since)],12,T.INK_MUTED))
	var trade_line:=String(preload("res://scripts/trade_words.gd").war_line(civ_id))
	words.tooltip_text="%s.%s" % [Ledger.subtitle(e),("\n"+trade_line) if trade_line!="" else ""]
	var dead_word:=_line("Fallen",11,T.INK_MUTED);dead_word.size_flags_vertical=Control.SIZE_SHRINK_CENTER;dead_word.tooltip_text="The dead of it all told: ours on the left, theirs on the right.";head.add_child(dead_word)
	var dead:=DeadStrip.new();dead.name="Dead";dead.ours=int(e.our_dead);dead.theirs=int(e.their_dead);dead.custom_minimum_size=Vector2(104,26);dead.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	dead.tooltip_text="The dead of it all told: %s of ours (left, in our ink), %s of theirs (right, in red)." % [EraWords.grouped(int(e.our_dead)),EraWords.grouped(int(e.their_dead))];head.add_child(dead)
	var chip:=Chip.new();chip.word=Ledger.state_word(e);chip.tooltip_text=Ledger.clock_words(e) if String(e.kind)=="feud" else "At war since %s." % Ledger.span_words(since);head.add_child(chip)
	# HOI4's read of who is winning: our share of the strength against theirs.
	var odds:=Strips.OddsBar.new();odds.name="Odds";column.add_child(odds)
	odds.set_odds(Ledger.odds(e),Ledger.odds_words(e))
	odds.tooltip_text="Their strength against ours, by the war leader's reckoning: people, warriors and readiness on one scale.\nWorn by the fighting: we are %d%% worn, they are %d%%." % [roundi(float(e.get("our_worn",0.0))*100.0),roundi(float(e.get("their_worn",0.0))*100.0)]
	column.add_child(_forces_row(civ_id))
	column.add_child(_now_row(e))
	var stances:=HFlowContainer.new();stances.name="Stances";stances.add_theme_constant_override("h_separation",4);stances.add_theme_constant_override("v_separation",4);column.add_child(stances)
	var chosen:=String(WarLoop.front(civ_id).get("stance",""))
	for spec:Array in STANCES:
		var id:=String(spec[0])
		if id=="take":
			stances.add_child(_take_button(civ_id,chosen=="take"));continue
		var button:=_stance_button(id,chosen==id)
		button.tooltip_text="%s: %s" % [String(spec[1]),String(spec[3])]
		button.pressed.connect(func()->void:_stance(civ_id,id,String(spec[2])))
		stances.add_child(button)
	var foot:=VBoxContainer.new();foot.add_theme_constant_override("separation",8);column.add_child(foot)
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


## Our men against theirs on this front, as HOI4 lays the divisions side by
## side: ours in bands against them, theirs as our watchers reckon, and the
## march to their nearest town we know (war_allocation_model.gd enemy).
func _forces_row(civ_id:String)->Control:
	var council:GDScript=load("res://scripts/war_council.gd")
	var ours:=0
	for band:Dictionary in council.call("bands_against",civ_id):ours+=int(band.get("troops",0))
	var e:=Allocation.enemy(civ_id,ours)
	var row:=HBoxContainer.new();row.name="Forces";row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS
	row.add_child(_icon("attack",T.INK,16))
	var mine:=_line(compact(ours),14,T.INK);mine.add_theme_font_override("font",T.font("ui_strong"));row.add_child(mine)
	row.add_child(_line("vs",12,T.INK_MUTED))
	var theirs:=_line(Allocation.theirs_words(e),14,T.RED_TEXT);theirs.name="Theirs";theirs.add_theme_font_override("font",T.font("ui_strong"));row.add_child(theirs)
	var nearest:Dictionary=e.nearest
	var road:=_line("%s · %s off" % [String(nearest.name),_days(int(nearest.days))] if not nearest.is_empty() else "no town of theirs known",12,T.INK_MUTED);road.name="Road"
	road.size_flags_horizontal=Control.SIZE_EXPAND_FILL;road.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;road.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;road.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(road)
	var their_words:="We know too little of them to count their warriors." if bool(e.unknown) else "Their warriors as our watchers reckon them: about %s (somewhere between %s and %s)." % [EraWords.grouped(int(e.theirs)),EraWords.grouped(int(e.low)),EraWords.grouped(int(e.high))]
	row.tooltip_text="Ours against them: %s in bands sent against them.
%s%s" % [EraWords.grouped(ours),their_words,("
Their nearest town we know, %s, lies about %s km off: some %s on the road." % [String(nearest.name),EraWords.grouped(roundi(float(nearest.km))),_days(int(nearest.days))]) if not nearest.is_empty() else "
We know of no town of theirs yet: scouts find their towns."]
	return row


## What is happening with this people now, in one short line with its mark:
## our band and where it is bound, the war leader's errand, or how quiet it
## is (now_short). The council's full account is in the tooltip.
func _now_row(e:Dictionary)->Control:
	var said:=now_short(e)
	var row:=HBoxContainer.new();row.name="Now";row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS
	var mark:=StateMark.new();mark.state=String(said.state);mark.custom_minimum_size=Vector2(18,18);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(mark)
	var text:=_line(String(said.text),13,T.RED_TEXT if bool(said.get("danger",false)) else T.INK);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.add_child(text)
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
	# Gathering every spear against us (world_answer.gd): it leads the card.
	if int(e.get("arming_days",-1))>=0:
		var left:=int(e.arming_days)
		return {"state":"fighting","text":"Gathering every spear · they march %s" % ("any day" if left<=3 else "in "+_days(left)),"danger":true}
	var council:GDScript=load("res://scripts/war_council.gd")
	var bands:Array=council.call("bands_against",civ_id) if civ_id!="" else []
	if not bands.is_empty():
		var band:Dictionary=bands[0]
		var card:Dictionary=BarModel.army_card(MilitaryCampaign,band)
		# The men stand once, on the line above (ours against theirs).
		var who:=String(card.get("short","Our band"))
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
	var button:=Button.new();button.name="Stance_%s" % id;button.text=String(SHORT.get(id,id.capitalize()));button.toggle_mode=true;button.focus_mode=Control.FOCUS_ALL
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
	var give:=Button.new();give.name="YieldHome";give.text="Yield %s" % home;give.focus_mode=Control.FOCUS_ALL;give.add_theme_font_size_override("font_size",13);_compact_skin(give)
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
	var pick:=OptionButton.new();pick.name="General";pick.focus_mode=Control.FOCUS_ALL;pick.add_theme_font_size_override("font_size",13);pick.fit_to_longest_item=false
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


## The watch at a glance (watch_military.gd): {ready (at home, in the
## bands and holding towns), drill (0: the watch drills at home), drill_days,
## waiting (called up and not yet joined), away (hurt, scattered or taken),
## watch (the home guard standing at home), armed (0..1: gear issued of gear
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
	return {"ready":int(ledger.home)+int(ledger.field)+int(ledger.occupation),"drill":int(ledger.training),"drill_days":int(drill.get("days",0)),
		"waiting":int(ledger.recruits),"away":int(ledger.recovering)+int(ledger.get("missing",0)),"watch":int(watch.kept),
		"armed":float(BarModel.gear_of(formations,mc).share),"fed":snappedf(fed/float(out),0.01) if out>0 else -1.0}


## The bar in words: "327 ready · 9 hurt or away · 12 to join".
static func strength_words(glance:Dictionary,now:int,target:int)->String:
	var parts:=PackedStringArray(["%s ready" % EraWords.grouped(int(glance.ready))])
	if int(glance.drill)>0:parts.append("%s in a drill course%s" % [EraWords.grouped(int(glance.drill)),(", about %d days" % int(glance.drill_days)) if int(glance.drill_days)>0 else ""])
	if int(glance.waiting)>0:parts.append("%s joining the watch" % EraWords.grouped(int(glance.waiting)))
	if int(glance.get("away",0))>0:parts.append("%s hurt or away" % EraWords.grouped(int(glance.away)))
	if target>now:parts.append("%s to join" % EraWords.grouped(target-now))
	elif target>=0 and now>target:parts.append("%s more than asked" % EraWords.grouped(now-target))
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
	var pick:=MenuButton.new();pick.name="Stance_take";pick.text="Take ▾";pick.flat=false;pick.focus_mode=Control.FOCUS_ALL
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
	for c:Dictionary in commands:leader_box.add_child(_leader_row(c,commands))
	# Raise another general: the verb at the foot of the list it adds to.
	var foot:=HBoxContainer.new();foot.name="LeadersFoot";foot.add_theme_constant_override("separation",8);leader_box.add_child(foot)
	var name_one:=Dense.verb("+ Name a general",_name_general,"Raise one of our people to lead bands as a general. The war council gives them work against an enemy; you can name who leads against each people.")
	name_one.name="NameGeneral";T.apply_button_style(name_one,true);foot.add_child(name_one)


func _name_general()->void:
	var result:Dictionary=Commands.commission_general(MilitaryCampaign)
	if result.has("error"):_say(String(result.error));return
	_say(("%s is named a general. %s" if bool(result.get("new",false)) else "%s is free to lead already. %s") % [String(result.name),String(result.get("line",""))])
	refresh(true)


## A leader as HOI4 shows one: the face, the name, the skill pips, and, while
## they lead bands, their men with three bars (men, will, fed). Their record
## and what their hand changes, in the engine's numbers, are in the tooltip.
func _leader_row(c:Dictionary,commands:Array=[])->Control:
	var leader:Dictionary=c.leader
	var war_leader:=String(c.id)==Commands.WAR_LEADER
	var panel:=PanelContainer.new();panel.name="Leader_%s" % String(c.id)
	# A row of the list, a hairline under it; the portrait carries the eye.
	var line:=T.paper_panel_style(true,T.RADIUS_CARD,16);line.set_border_width_all(0)
	panel.add_theme_stylebox_override("panel",line)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);panel.add_child(row)
	var frame:=PanelContainer.new();frame.clip_contents=true;frame.custom_minimum_size=Vector2(56,64);frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var ground:=T.flat(T.PAPER_SUNK);ground.border_color=Commands.color(String(c.id));ground.border_width_left=3;frame.add_theme_stylebox_override("panel",ground);row.add_child(frame)
	var face:=TextureRect.new();face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var key:=String(leader.get("figure_id","")) if String(leader.get("figure_id",""))!="" else String(leader.get("name",""))
	face.texture=Portrait.texture({"name":String(leader.get("name","")),"person_id":absi(key.hash())%997+1});frame.add_child(face)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",8);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(words)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);top.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(top)
	var name_label:=_line(String(leader.get("name","The war leader")),18,T.INK);name_label.add_theme_font_override("font",T.font("ui_strong"))
	name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(name_label)
	# Who they are and where, as the Council says it (person_posts.gd).
	var post:=preload("res://scripts/person_posts.gd").of({"person_id":int(leader.get("person_id",0)),"figure_id":String(leader.get("figure_id",""))},commands)
	var title:=String(post.get("title",""))
	if title=="":title="War leader" if war_leader else "General"
	var role:=_line(title,12,T.INK_MUTED);role.size_flags_vertical=Control.SIZE_SHRINK_CENTER;words.add_child(role)
	if war_leader:
		var other:=Button.new();other.name="NameWarLeader";other.text="Change";other.flat=true;other.focus_mode=Control.FOCUS_ALL
		T.apply_button_style(other,false)
		other.tooltip_text="The war leader at home is the Marshal among the officials, or the best of the field staff while no one holds that office. Summon the Marshal to the court to hear who could replace them."
		other.pressed.connect(_name_war_leader)
		top.add_child(other)
	if not (leader.get("commander",{}) as Dictionary).is_empty():
		var ratings:=HFlowContainer.new();ratings.name="Ratings";ratings.add_theme_constant_override("h_separation",12);ratings.add_theme_constant_override("v_separation",6);words.add_child(ratings)
		var commander:Dictionary=leader.get("commander",{})
		for skill:Array in Strips.GeneralPips.SKILLS:
			var skill_id:=String(skill[0])
			if not commander.has(skill_id) or (skill_id=="logistics" and not war_leader):continue
			var rating:=_line("%s  %d/5" % [{"command":"Plan","tactics":"Fight","resolve":"Hold","logistics":"Supply"}.get(skill_id,String(skill[2])),Strips.GeneralPips.pips(float(commander[skill_id]))],14,T.GOLD_TEXT)
			rating.tooltip_text="%s: %s." % [String(skill[2]),String(skill[3])];rating.mouse_filter=Control.MOUSE_FILTER_PASS;ratings.add_child(rating)
	var below:=HBoxContainer.new();below.add_theme_constant_override("separation",6);below.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(below)
	if int(c.get("men",0))>0:
		below.add_child(_icon("men",T.INK,16))
		var men:=_line(compact(int(c.men)),13,T.INK);men.add_theme_font_override("font",T.font("ui_strong"));below.add_child(men)
		var bars:=CommandBars.new();bars.name="Bars";bars.men=int(c.men);bars.full=int(c.full);bars.will=float(c.will);bars.fed=float(c.supply)
		bars.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bars.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		bars.tooltip_text="Men %d of %d · will %d%% · fed %d%%" % [int(c.men),int(c.full),roundi(float(c.will)*100.0),roundi(float(c.supply)*100.0)]
		below.add_child(bars)
	else:
		below.add_child(_line(String(post.get("place","")) if String(post.get("place",""))!="" else "At home",12,T.INK_MUTED))
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


## What the four groups of pips on each leader are: one word over each, the
## meaning on the pointer (force_strips GeneralPips SKILLS, its own layout:
## an 18 px mark, then five pips, 71 px a group).
func _pip_header()->Control:
	var row:=HBoxContainer.new();row.name="PipHeader";row.add_theme_constant_override("separation",0)
	var pad:=Control.new();pad.custom_minimum_size=Vector2(50,0);pad.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(pad)
	for skill:Array in Strips.GeneralPips.SKILLS:
		var word:=_line({"command":"Plan","tactics":"Fight","resolve":"Hold","logistics":"Supply"}.get(String(skill[0]),String(skill[2])),11,T.INK_MUTED)
		word.add_theme_font_override("font",T.font("ui_strong"));word.custom_minimum_size=Vector2(71,0)
		word.tooltip_text="%s, five pips at most: %s." % [String(skill[2]),String(skill[3])]
		row.add_child(word)
	return row


## The court, on the Marshal (the war leader at home): who else could hold
## the office is told there, and "make X our war leader" names them.
func _name_war_leader()->void:
	close_wanted.emit()
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var pid:=int(marshal.get("person_id",0))
	load("res://scripts/audience_director.gd").open_court_for({"person_id":pid} if pid>0 else {})


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
	# The society's name by age (covert_board.gd): never "spies" early.
	covert_toggle.text="%s%s  %s" % [preload("res://scripts/eyes_corps.gd").word("Eyes").to_upper(),(" · %d abroad" % abroad) if abroad>0 else "","▾" if covert!=null and covert.visible else "›"]


# --- Panes and tabs ---------------------------------------------------------

func _pane(pane_name:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.name=pane_name;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",20)
	return box


## One of the three parts on a narrow screen (on a wide one all show).
func show_tab(key:String)->void:
	tab=key if key in ["army","fronts","leaders"] else "army"
	_apply_width(true)


## Lays the parts for the screen's width: both panes side by side from
## WIDE_VIEW on, else the tabs and one part.
func _apply_width(force:=false)->void:
	if army_pane==null:return
	var view_width:=get_viewport().get_visible_rect().size.x if is_inside_tree() else 0.0
	var now:=wide(view_width)
	if _laid and now==_wide and not force:return
	_wide=now;_laid=true
	tabs_row.visible=not now
	army_pane.custom_minimum_size.x=0.0
	if now:
		army_pane.visible=true;side_pane.visible=true
		army_section.visible=true;fronts_section.visible=true;leaders_section.visible=true
	else:
		army_pane.visible=tab=="army";side_pane.visible=tab!="army"
		fronts_section.visible=tab=="fronts";leaders_section.visible=tab=="leaders"
	for key:String in tab_buttons:(tab_buttons[key] as Button).set_pressed_no_signal(key==tab)
	if leaders_heading!=null:leaders_heading.visible=now
	# On a wide screen the border stands under the army (home and its edge
	# together), on a narrow one with the fronts.
	if border_box!=null:
		var want:Control=army_section if now else fronts_section
		if border_box.get_parent()!=want:
			border_box.get_parent().remove_child(border_box);want.add_child(border_box)


## The tabs carry how many enemies there are (the kicker does on a wide
## screen, where the tabs are hidden): one count, shown once.
func _set_tab_counts(_forces:Dictionary)->void:
	if tab_buttons.is_empty():return
	var open:=Ledger.entries().filter(func(e:Dictionary)->bool:return String(e.kind)!="ended").size()
	(tab_buttons.fronts as Button).text="Fronts · %d" % open if open>0 else "Fronts"
	if enemy_count!=null:enemy_count.visible=_wide


func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED:_apply_width()


static func _tab_style(pressed:bool,hover:bool)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0,0,0,0) if not hover else T.HOVER_BG
	style.border_color=T.GOLD if pressed else T.RULE
	style.border_width_bottom=3 if pressed else 1
	style.content_margin_left=6.0;style.content_margin_right=6.0;style.content_margin_top=6.0;style.content_margin_bottom=6.0
	return style


## "All peoples ›": every people we know, ranked (the Known World).
func _all_peoples_link()->Button:
	var all:=Button.new();all.name="AllPeoples";all.text="All peoples ›";all.focus_mode=Control.FOCUS_ALL;all.flat=true
	all.tooltip_text="Every people we have met, ranked as we know them."
	all.add_theme_font_size_override("font_size",12)
	all.add_theme_color_override("font_color",T.GOLD_TEXT);all.add_theme_color_override("font_hover_color",T.INK);all.add_theme_color_override("font_pressed_color",T.INK)
	all.pressed.connect(func()->void:
		var scene:=get_tree().current_scene if is_inside_tree() else null
		var hud:Variant=scene.get("hud") if scene!=null else null
		if hud==null or not hud.has_method("has_provider") or not hud.has_provider("world"):return
		close_wanted.emit()
		hud.open_dock("world",0))
	return all


# --- What needs the god now (the notice column's rows) -----------------------

## The notice column's rows that need the god (notification_stack.gd
## needing()), one line each with their button; [] outside the game.
func _needing()->Array:
	var scene:=get_tree().current_scene if is_inside_tree() else null
	var hud:Variant=scene.get("hud") if scene!=null and "hud" in scene else null
	if not hud is Node or not is_instance_valid(hud):return []
	var stack:=preload("res://scripts/hud/notification_stack.gd").of(hud)
	if stack==null or not stack.has_method("needing"):return []
	return [stack,stack.call("needing")]


func _build_needs(found:Array)->void:
	_clear(needs_box)
	needs_box.visible=false
	if found.size()<2:return
	var stack:Node=found[0]
	var rows:Array=found[1]
	needs_box.visible=not rows.is_empty()
	var Standing:=preload("res://scripts/hud/standing_notices.gd")
	# A notice that only opens this screen is already its content here.
	rows=rows.filter(func(n:Dictionary)->bool:return String((n.get("action",{}) if n.get("action") is Dictionary else {}).get("kind",""))!="war")
	needs_box.visible=not rows.is_empty()
	for n:Dictionary in rows.slice(0,3):
		var tone:=Standing.tone_color(String(n.get("tone","amber")))
		var row:=PanelContainer.new();row.name="Need_%s" % String(n.get("key","")).trim_prefix("standing:").replace(":","_")
		var skin:=_skin(T.PAPER_RAISED,T.RULE,4,4);skin.border_color=tone;skin.border_width_left=4;skin.content_margin_left=8
		row.add_theme_stylebox_override("panel",skin);row.tooltip_text=Standing.tip(n);row.mouse_filter=Control.MOUSE_FILTER_PASS
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",6);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(line)
		var icon:=TextureRect.new();icon.texture=Standing.icon(n);icon.custom_minimum_size=Vector2(18,18);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(icon)
		var title:=_line(String(n.get("title","")),13,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(title)
		var fact:=_line(String(n.get("text","")),12,T.INK_MUTED);fact.size_flags_horizontal=Control.SIZE_EXPAND_FILL;fact.clip_text=true;fact.text_overrun_behavior=TextServer.OVERRUN_TRIM_WORD;fact.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(fact)
		var verb:=Button.new();verb.name="Verb";verb.text=String(n.get("verb","See"));verb.focus_mode=Control.FOCUS_ALL;verb.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		verb.add_theme_font_override("font",T.font("ui_strong"));verb.add_theme_font_size_override("font_size",12)
		for state:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:verb.add_theme_color_override(state,Color("fbf6ea"))
		for state:String in ["normal","hover","pressed"]:
			var vs:=T.flat(tone if state=="normal" else tone.darkened(0.12),Color(0,0,0,0),0,8);vs.content_margin_left=8;vs.content_margin_right=8;vs.content_margin_top=1;vs.content_margin_bottom=1
			verb.add_theme_stylebox_override(state,vs)
		verb.add_theme_stylebox_override("focus",T.gold_outline_style())
		T.apply_button_style(verb,false)
		var action:Dictionary=n.get("action",{}) if n.get("action") is Dictionary else {}
		verb.pressed.connect(func()->void:if is_instance_valid(stack):stack.call("act",action))
		line.add_child(verb)
		needs_box.add_child(row)
	if rows.size()>3:
		var more:=_line("+%d more in Notices" % (rows.size()-3),12,T.INK_MUTED);more.name="NeedsMore";needs_box.add_child(more)


# --- Pieces ---------------------------------------------------------------

func _say(text:String)->void:
	feedback.text=text
	feedback.tooltip_text=text
	feedback.visible=text!=""


## A section's kicker with room on its right for a count or a button.
func _kicker_row(title:String,parent:Control=null)->HBoxContainer:
	var row:=HBoxContainer.new();row.name=title+"Head";row.add_theme_constant_override("separation",6);(parent if parent!=null else self).add_child(row)
	var kicker:=_line(title,22,T.INK);kicker.add_theme_font_override("font",T.font("ui_strong"));kicker.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(kicker)
	var count:=_line("",12,T.INK_MUTED);count.add_theme_font_override("font",T.font("ui_strong"));count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(count)
	var gap:=Control.new();gap.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(gap)
	row.set_meta("count",count)
	return row


func _small_button(text:String,mark:String,tip:String)->Button:
	var button:=Button.new();button.text=text;button.focus_mode=Control.FOCUS_ALL;button.tooltip_text=tip
	button.icon=Icons.command_texture(mark,T.INK,32);button.add_theme_constant_override("icon_max_width",12);button.add_theme_constant_override("h_separation",3)
	button.add_theme_font_size_override("font_size",14);button.custom_minimum_size=Vector2(0,40)
	_compact_skin(button)
	return button



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
	style.content_margin_left=pad;style.content_margin_right=pad;style.content_margin_top=6.0;style.content_margin_bottom=6.0
	if pressed:style.border_width_bottom=3
	return style


static func _compact_skin(button:Control,pad:=7.0)->void:
	button.custom_minimum_size.y=maxf(40,button.custom_minimum_size.y)
	button.add_theme_font_size_override("font_size",14)
	button.add_theme_stylebox_override("normal",_compact_style(false,false,pad))
	button.add_theme_stylebox_override("hover",_compact_style(false,true,pad))
	button.add_theme_stylebox_override("pressed",_compact_style(true,false,pad))
	button.add_theme_stylebox_override("hover_pressed",_compact_style(true,true,pad))
	button.add_theme_stylebox_override("disabled",T.button_disabled_style())
	button.add_theme_stylebox_override("focus",T.gold_outline_style())
	for state:String in ["font_color","font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]:button.add_theme_color_override(state,T.INK)
	button.add_theme_color_override("font_disabled_color",T.DISABLED)


func _clear(box:Node)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()


static func _skin(bg:Color,border:Color,margin:int,left:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(0)
	if left>0:style.border_width_left=3
	style.set_corner_radius_all(T.RADIUS_CARD);style.set_content_margin_all(margin)
	return style


static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_PASS
	label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",maxi(14,size));label.add_theme_color_override("font_color",color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


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


## Where every soldier stands, as one bar: each part in its ink
## (part_ink), against the share the people keep on watch (the ink tick).
class AllocationBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Board:=preload("res://scripts/hud/war_board.gd")
	var parts:Array=[]
	var target:=-1
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var whole:=Rect2(Vector2.ZERO,size)
		draw_rect(whole,T.PAPER_SUNK)
		var total:=0
		for part:Dictionary in parts:total+=int(part.men)
		var scale:=float(maxi(1,maxi(total,target)))
		var x:=0.0
		var fronts:=0
		for part:Dictionary in parts:
			var width:=size.x*float(part.men)/scale
			var ink:Color=Board.part_ink(part,fronts)
			if String(part.ink)=="front":fronts+=1
			if width>0.0:
				draw_rect(Rect2(x,0.0,width,size.y),ink)
				if x>0.0:draw_line(Vector2(x,0.0),Vector2(x,size.y),T.PAPER_RAISED,1.0)
				x+=width
		draw_rect(whole,T.RULE_STRONG,false,1.0)
		if target>0 and target!=total:
			var tick:=clampf(size.x*float(target)/scale,1.0,size.x-1.0)
			draw_line(Vector2(tick,-3.0),Vector2(tick,size.y+3.0),T.INK,2.0)


## One share as a short bar in its ink; an empty track when unknown (<0).
class ShareBar extends Control:
	const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
	var share:=0.0
	var ink:=Color.WHITE
	func _draw()->void:BarModel.draw_bar(self,Rect2(Vector2.ZERO,size),clampf(share,0.0,1.0),ink)
