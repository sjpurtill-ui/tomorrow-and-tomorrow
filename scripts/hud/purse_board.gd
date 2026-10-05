extends VBoxContainer
## WHAT WE OWN AND THE REALM'S PURSE, at a glance. One question a section,
## answered first in big plain words; the supporting numbers stay small and
## the rest is in tooltips. Every number is the engine's own (standing.gd
## wealth_held, civilian_goods.gd, realm_purse.gd, enterprise.gd).
##
## The Wealth tab ("wealth", the default) is what the people own and can
## trade, goods first:
##   what we own  goods held in every town, what they buy at our own prices,
##                a head against a typical people of the age, and what can
##                change hands; coin and weighed metal once known;
##   what we make goods a day and their worth; arms point to Production;
##   treasures    the pieces held and their appraisal;
##   materials    timber, stone, clay and fibre in store, a secondary line;
##   the treasury after coinage: the purse's sections below, in coin;
##   trade and business  barter at home, then the business rung and stance;
##   the wealth   who holds it by fifths, and the pressure it puts on trust;
##   the store    before coinage, one line and a link to Food & water.
## The Food & water tab ("store") holds the common store while it is food:
##   the store    how long it lasts and whether it grows; what comes in and
##                goes out a season, two labelled bars;
##   where from   each town's levy, and what never came in;
##   the levy     light, usual or heavy: a button each with what it takes,
##                brings in and costs in trust;
##   pays for     the soldiers' pay, the scholars' keep, hired crews and food
##                for hungry towns: a switch each, its cost and its effect.
## The purse's sections live where its money is: with the food until coinage,
## then with the wealth (the treasury, in coin).

signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const Business:=preload("res://scripts/enterprise.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Arms:=preload("res://scripts/weapons_stock.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const Standing:=preload("res://scripts/standing.gd")
const Scale:=preload("res://scripts/standing_scale.gd")
const Production:=preload("res://scripts/hud/content/dock_content_production.gd")
const Graphics:=preload("res://scripts/hud/wealth_graphics.gd")
const MaterialArt:=preload("res://scripts/hud/materials_art.gd")
const ProductArt:=preload("res://scripts/hud/production_art.gd")
const ArtifactArt:=preload("res://scripts/hud/artifact_visuals.gd")
const Emblem:=preload("res://scripts/hud/hud_chrome_icon.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const REFRESH_SECONDS:=1.0
const LINE_LABELS:={"army":"Soldiers","scholars":"Scholars","crews":"Crews","relief":"Food for the hungry","debts":"Old debts","spent":"Gifts and buying","spoiled":"Rot"}
## Business does "hardly anything yet" below this much added to all work;
## its stance is then tucked behind one button.
const BUSINESS_MATTERS:=0.01
## A store that would last this many seasons or more is shrinking "slowly".
const SLOW_SEASONS:=20.0

var head_box:VBoxContainer
var levy_box:VBoxContainer
var sources_box:VBoxContainer
var business_box:VBoxContainer
var goods_box:VBoxContainer
var own_box:VBoxContainer
var treasures_box:VBoxContainer
var materials_box:VBoxContainer
var store_box:VBoxContainer
var lines_box:VBoxContainer
var wealth_box:VBoxContainer
var ledger_box:VBoxContainer
var feedback:Label
## "wealth" (the Wealth tab) or "store" (the common store on Food & water).
var mode:="wealth"
## Whether the purse counted in food when the board was drawn: its sections
## move between the tabs at coinage, so the dock draws the board afresh.
var kind_at_setup:=true
var clock:=0.0
var signatures:={}
## Opens another screen: on_open.call(section, sub) (the dock's provider).
var on_open:Callable
## The player opened the business stance choice.
var stances_open:=false
var responsive_grids:Array[GridContainer]=[]

func _ready()->void:
	_bind_layout.call_deferred()

func _bind_layout()->void:
	var ancestor:=get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			if not ancestor.resized.is_connected(_responsive):ancestor.resized.connect(_responsive)
			break
		ancestor=ancestor.get_parent()
	_responsive()

func setup(block:Dictionary={})->void:
	name="PurseBoard"
	if block.get("on_open") is Callable:on_open=block.on_open
	mode="store" if String(block.get("mode","wealth"))=="store" else "wealth"
	kind_at_setup=Purse.in_kind()
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	theme=T.control_theme()
	add_theme_constant_override("separation",16 if mode=="wealth" else 10)
	feedback=_line("",14,T.GOLD_TEXT,true);feedback.name="Said";feedback.visible=false
	if mode=="wealth":
		own_box=_visual_section("What we own",self,"WealthHero","wealth")
		add_child(feedback)
		var cards:=_grid(self,"WealthCards",3,780)
		goods_box=_visual_section("What we make",cards,"MakingCard","production")
		treasures_box=_visual_section("Treasures",cards,"TreasuresCard","")
		materials_box=_visual_section("Materials in store",cards,"MaterialsCard","materials")
	if _purse_here():
		head_box=_section(Purse.account_name())
		if mode=="store":add_child(feedback)
		sources_box=_section("Where it comes from")
		levy_box=_section("The levy")
		lines_box=_section("What it pays for")
	if mode=="wealth":
		var society:=_grid(self,"WealthSociety",2,820)
		business_box=_visual_section("Trade and business",society,"BusinessCard","trade")
		wealth_box=_visual_section("Who holds the wealth",society,"DistributionCard","overview")
		if kind_at_setup:store_box=_section(Purse.account_name())
	if _purse_here():ledger_box=_section("Lately")
	resized.connect(_responsive)
	refresh(true)
	_responsive()

## Whether this board holds the purse's own sections: the store's on Food &
## water while it is food, the treasury's on Wealth once it is coin.
func _purse_here()->bool:
	return (mode=="store")==kind_at_setup


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## The dock's own refresh (dock_panel.gd, each day the page is open): the
## board keeps its nodes and reads the purse again, as a fresh page would.
func update_block(block:Dictionary)->bool:
	if String(block.get("mode","wealth"))!=mode or Purse.in_kind()!=kind_at_setup:return false
	if block.get("on_open") is Callable:on_open=block.on_open
	clock=0.0
	refresh()
	return true


## Each section is drawn again only when what it shows has changed and no
## button of it is held.
func refresh(force:=false)->void:
	if _purse_here():
		var forecast:=Purse.forecast()
		var purse:=Purse.state()
		var season:=Purse.season()
		_rebuild("head",head_box,str([roundi(float(purse.balance)),roundi(float(forecast["in"])),roundi(float(forecast.out)),Purse.unit_word(),roundi(Purse.buys_rations()),roundi(Purse.days_of_food()),season.total_in,season.total_out]),force,func()->void:_build_head(forecast,season))
		var sources:=Purse.sources()
		_rebuild("sources",sources_box,str([sources.towns.map(func(t:Dictionary)->int: return roundi(float(t.levy))),roundi(float(sources.rich)),roundi(float(sources.get("charter",0.0))),roundi(float(sources.deposits)),roundi(float(sources.evaded)),Purse.unit_word()]),force,func()->void:_build_sources(sources))
		_rebuild("levy",levy_box,str([String(purse.levy),Purse.unit_word(),Purse.LEVELS.map(func(l:String)->int:return roundi(float(Purse.quote(l).per_season))),snappedf(float((forecast.quote as Dictionary).evasion),0.01)]),force,func()->void:_build_levy(String(purse.levy)))
		_rebuild("lines",lines_box,str([purse.lines,int(purse.unpaid_months),purse.last_army,forecast.lines,Purse.market_open()]),force,func()->void:_build_lines(forecast,purse))
		_rebuild("ledger",ledger_box,str((purse.ledger as Array).slice(0,5)),force,func()->void:_build_ledger(purse))
	if mode!="wealth":return
	var held:=Standing.wealth_held()
	var cards:=Production.household_cards()
	var spare:=0.0
	for card:Dictionary in cards:spare+=float(card.get("spare",0.0))
	if cards.is_empty():spare=Goods.spare()
	var people:=roundi(float(WorldSimulation.state.population_exact))
	_rebuild("own",own_box,str([held.goods,held.coin,held.coin_word,held.worth,Goods.buys(float(held.goods),["Food","Timber","Stone","Fiber Plants"]),spare,people,int(_year()),T.color_mode]),force,func()->void:_build_own(held,spare))
	var report:Dictionary=WorldSimulation.state.civilian_goods.get("report",{})
	_rebuild("goods",goods_box,str([int(WorldSimulation.state.elapsed_days),GameState.player_settlements.size(),snappedf(float(report.get("made",0.0)),0.1),roundi(Goods.stock()),roundi(Arms.watch()),roundi(Goods.worth_in_rations(1.0)*10.0),Production._goods_bench()]),force,func()->void:_build_goods(cards))
	_rebuild("treasures",treasures_box,str([int(held.treasures),roundi(float(held.treasure_worth)),people,int(_year()),_treasure_picture_key()]),force,func()->void:_build_treasures(held))
	_rebuild("materials",materials_box,str([roundi(float(held.materials)),people,int(_year())]),force,func()->void:_build_materials(held))
	var e:=Business.state()
	_rebuild("business",business_box,str([Business.rung(),snappedf(Business.share(),0.001),snappedf(float(e.get("target",0.0)),0.001),Business.stance(),snappedf(Business.factor(),0.001),int(e.get("boom_months",0)),Business.bust_left(),Business.choices().map(func(id:String)->Array:var q:=Business.quote(id);return [id,Purse.number(float(q.purse_now)),Purse.number(float(q.purse_season))]),Business.next_needs(),Purse.unit_word(),stances_open,String(WorldSimulation.state.economy_stage),snappedf(float(WorldSimulation.state.economy_metrics.get("market_access",0.0)),0.01)]),force,func()->void:_build_business())
	var parts:Variant=WorldSimulation.state.economy_metrics.get("social_pressure_parts",{})
	_rebuild("wealth",wealth_box,str([WorldSimulation.state.wealth_shares,parts,String(WorldSimulation.state.economy_stage)]),force,func()->void:_build_wealth())
	if store_box!=null:_rebuild("store",store_box,str([roundi(Purse.balance()),roundi(Purse.days_of_food())]),force,func()->void:_build_store_pointer())
	_responsive()


func _rebuild(key:String,box:Control,next:String,force:bool,build:Callable)->void:
	if box==null:return
	if not force and next==String(signatures.get(key,"")):return
	if not force and box.is_visible_in_tree() and box.get_global_rect().has_point(box.get_global_mouse_position()) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):return
	signatures[key]=next
	build.call()


# --- The store ----------------------------------------------------------------------

## How long the store lasts (food) or what it holds (coin), and whether it is
## growing, in one big line; what it holds, then what comes in and goes out a
## season as two labelled bars. Last season's actual sums are in the bars'
## tooltip.
func _build_head(forecast:Dictionary,season:Dictionary)->void:
	_clear(head_box)
	# The account's own name heads it, by the age: the common store, the treasury.
	var kicker:=head_box.get_meta("section_kicker",null) as Label if mode=="wealth" else get_child(head_box.get_index()-1) as Label
	if kicker!=null:kicker.text=Purse.account_name().to_upper()
	var panel:=_panel(head_box,"Purse")
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	panel.tooltip_text="The realm's one account. Every town keeps its own stores; this is the god's to spend." if not Purse.in_kind() else "Food the levy took from every town's stores, kept for all. The god's to spend: it pays the soldiers, feeds the hungry, keeps scholars and crews. It rots slowly, as stored food does."
	var net:=float(forecast.net)
	var trend:=_trend(net,float(forecast.seasons_left))
	var head:=HBoxContainer.new();head.name="Headline";head.add_theme_constant_override("separation",12);column.add_child(head)
	var big:=_answer(_store_words(forecast));big.name="StoreAnswer";big.autowrap_mode=TextServer.AUTOWRAP_OFF;head.add_child(big)
	var moving:=_line(String(trend.text),16,trend.color);moving.name="Verdict";moving.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	moving.add_theme_font_override("font",T.font("ui_strong"))
	moving.tooltip_text="A season: %s in, %s out: %s %s." % [Purse.number(float(forecast["in"])),Purse.number(float(forecast.out)),Purse.number(absf(net)),"left over" if net>=0.0 else "short"]
	head.add_child(moving)
	var held:=_line(_held_words(forecast),13,T.INK_MUTED,true);held.name="Balance"
	held.tooltip_text="What %s holds now, in %s." % [Purse.account_name(),Purse.unit_word()]
	column.add_child(held)
	# HOI4's budget: what comes in against what goes out, a season, on one scale.
	var ins:Array=[["Levy",float(forecast.levy),T.GREEN]]
	if float(forecast.rich)>0.0:ins.append(["The rich",float(forecast.rich),T.GREEN.darkened(0.2)])
	if float(forecast.get("charter",0.0))>0.0:ins.append([Business.purse_name(),float(forecast.charter),T.GREEN.lightened(0.25)])
	var outs:Array=[]
	for line:String in Purse.LINES:
		var entry:Dictionary=(forecast.lines as Dictionary).get(line,{})
		if bool(entry.get("on",false)) and float(entry.get("per_season",0.0))>0.0:outs.append([String(LINE_LABELS[line]),float(entry.per_season),_ink(line)])
	if float(forecast.get("rot",0.0))>=0.5:outs.append([String(LINE_LABELS.spoiled),float(forecast.rot),T.INK_MUTED])
	var scale:=maxf(0.001,maxf(float(forecast["in"]),float(forecast.out)))
	var budget:=VBoxContainer.new();budget.name="Budget";budget.add_theme_constant_override("separation",4);column.add_child(budget)
	budget.tooltip_text="Last season: %s came in, %s went out." % [Purse.number(float(season.total_in)),Purse.number(float(season.total_out))]
	budget.mouse_filter=Control.MOUSE_FILTER_PASS
	budget.add_child(_flow_row("ComingIn","Comes in","+"+Purse.number(float(forecast["in"]))+" a season",ins,scale,T.GREEN_TEXT))
	budget.add_child(_flow_row("GoingOut","Goes out","−"+Purse.number(float(forecast.out))+" a season",outs,scale,T.RED_TEXT if net<-0.01 else T.INK))
	if float(forecast.debt)>0.5:column.add_child(_line("Old debts owed: %s, repaid from it monthly." % Purse.number(float(forecast.debt)),13,T.INK_MUTED,true))


## "408 days of food", or "1,200 coin" after coinage.
func _store_words(forecast:Dictionary)->String:
	if Purse.in_kind():return "%s days of food" % EraWords.grouped(roundi(Purse.days_of_food()))
	return Purse.amount_text(float(forecast.balance))

## The small line under the answer: what it holds, and before coinage who it
## feeds; after, what it buys.
func _held_words(forecast:Dictionary)->String:
	if Purse.in_kind():return "%s rations held: enough to feed everyone that long." % Purse.number(Purse.balance())
	var rations:=Purse.buys_rations()
	if rations>=0.0:return "It buys %s rations at today's market price." % EraWords.grouped(roundi(rations))
	var army:=float(((forecast.lines as Dictionary).get("army",{}) as Dictionary).get("per_season",0.0))
	if army>0.5:return "It pays the soldiers for %s seasons." % Purse.number(Purse.balance()/army)
	return "What %s holds now." % Purse.account_name()

## Growing, steady, shrinking slowly, or running out: {text, color}.
static func _trend(net:float,seasons_left:float)->Dictionary:
	if net>0.01:return {"text":"growing","color":T.GREEN_TEXT}
	if net>=-0.01:return {"text":"steady","color":T.INK_MUTED}
	if seasons_left<0.0 or seasons_left>=SLOW_SEASONS:return {"text":"shrinking slowly","color":T.AMBER_TEXT}
	return {"text":"runs out in about %s %s" % [Purse.number(seasons_left),"season" if seasons_left<1.5 else "seasons"],"color":T.RED_TEXT}

## One labelled row of the budget: a word, a bar of its parts on the shared
## scale, and the season's sum. The tooltip names each part.
func _flow_row(node_name:String,word:String,amount:String,parts:Array,scale:float,color:Color)->Control:
	var row:=HBoxContainer.new();row.name=node_name;row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_PASS
	var label:=_line(word,13,T.INK);label.custom_minimum_size=Vector2(78,0);row.add_child(label)
	var bar:=PartsBar.new();bar.name="Bar";bar.parts=parts;bar.scale_to=scale;bar.custom_minimum_size=Vector2(80,12)
	bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(bar)
	var sum:=_line(amount,13,color);sum.custom_minimum_size=Vector2(132,0);sum.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(sum)
	var said:PackedStringArray=[]
	for entry:Array in parts:said.append("%s %s" % [String(entry[0]),Purse.number(float(entry[1]))])
	row.tooltip_text="%s a season, in %s: %s." % [word,Purse.unit_word(),", ".join(said)] if not said.is_empty() else "%s: nothing a season." % word
	return row


# --- Where it comes from ------------------------------------------------------------

## Each town's levy on what its people make, a season at the pace of the last
## months; the rich's levy; what other systems paid in; and what never came:
## hidden by households, or beyond the keepers' reach.
func _build_sources(sources:Dictionary)->void:
	_clear(sources_box)
	var towns:Array=sources.towns
	if towns.is_empty() and float(sources.rich)<=0.0 and float(sources.deposits)<=0.0 and float(sources.get("charter",0.0))<=0.0:
		sources_box.add_child(_line("Nothing has come in yet.",13,T.INK_MUTED,true));return
	var total:=float(sources.rich)+float(sources.deposits)+float(sources.get("charter",0.0))
	for t:Dictionary in towns: total+=float(t.levy)
	var rows:Array=[]
	for t:Dictionary in towns: rows.append([String(t.name),float(t.levy),"the levy on what %s people make" % EraWords.grouped(int(t.people)),"%s %s hidden by households" % [Purse.number(float(t.evaded)),Purse.unit_word()] if float(t.evaded)>=0.5 else ""])
	if float(sources.rich)>0.0: rows.append(["The rich",float(sources.rich),"the levy on the richest fifth (while the wealth levy holds)",""])
	if float(sources.get("charter",0.0))>0.0: rows.append([Business.purse_name(),float(sources.charter),"the purse's part of what the business sector makes, taken with the levy",""])
	if float(sources.deposits)>0.0: rows.append(["Other",float(sources.deposits),"tolls, spoils and fees paid in",""])
	var top:Array=rows[0]
	for r:Array in rows:if float(r[1])>float(top[1]):top=r
	# The answer names the biggest giver; the sums are on the rows (a season at
	# the pace of the last months, which the store's forecast need not match).
	var answer:=_answer("Most from %s: %d in 100" % [String(top[0]),roundi(float(top[1])/maxf(0.001,total)*100.0)] if rows.size()>1 else "All from %s" % String(top[0]),17)
	answer.name="SourcesAnswer";sources_box.add_child(answer)
	answer.tooltip_text="A season at the pace of the last months: %s in all." % Purse.amount_text(total)
	for r:Array in rows:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_PASS
		var who:=_line(String(r[0]),13,T.INK);who.custom_minimum_size=Vector2(140,0);row.add_child(who)
		var bar:=PartsBar.new();bar.parts=[[String(r[0]),float(r[1]),T.GREEN]];bar.scale_to=maxf(1.0,total);bar.custom_minimum_size=Vector2(80,10)
		bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(bar)
		var amount:=_line("+%s · %d%%" % [Purse.number(float(r[1])),roundi(float(r[1])/maxf(0.001,total)*100.0)],13,T.GREEN_TEXT);amount.custom_minimum_size=Vector2(132,0);amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(amount)
		row.tooltip_text=_cap(String(r[2]))+(". "+_cap(String(r[3]))+"." if String(r[3])!="" else ".")
		sources_box.add_child(row)
	var lost:PackedStringArray=[]
	if float(sources.evaded)>=0.5: lost.append("%s hidden by households" % Purse.number(float(sources.evaded)))
	if float(sources.unreached)>=0.5: lost.append("%s beyond the keepers' reach" % Purse.number(float(sources.unreached)))
	if float(sources.get("short",0.0))>=0.5: lost.append("%s left with towns that had none to spare" % Purse.number(float(sources.short)))
	if not lost.is_empty(): sources_box.add_child(_line("Never came in, a season: %s." % ", ".join(lost),13,T.INK_MUTED,true))
	if float(sources.coin_share)>0.01: sources_box.add_child(_line("%d%% of it is paid in coin; the rest is taken in goods." % roundi(float(sources.coin_share)*100.0),13,T.INK_MUTED,true))


# --- The levy -----------------------------------------------------------------------

## One button a level: what it takes, what it brings in a season and what it
## costs in trust. The one line under them: how many hide their dues.
func _build_levy(current:String)->void:
	_clear(levy_box)
	var q:=Purse.quote(current)
	var now:=_answer("We take %s of %s" % [String(q.words),Purse.harvest_word()],17);now.name="LevyNow"
	now.tooltip_text="%s a season, in %s, at today's work after what is hidden." % [Purse.number(float(q.per_season)),Purse.unit_word()]
	levy_box.add_child(now)
	var pick:=HBoxContainer.new();pick.name="Levels";pick.add_theme_constant_override("separation",8);levy_box.add_child(pick)
	for level:String in Purse.LEVELS:
		var lq:=Purse.quote(level)
		var button:=Button.new();button.name="Level_%s" % level;button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE
		var cost:="no cost to trust" if roundi(float(lq.trust))<=0 else "trust −%d" % roundi(float(lq.trust))
		button.text="%s: %s\n+%s a season · %s" % [String(Purse.LEVEL_NAMES[level]),String(lq.words),Purse.number(float(lq.per_season)),cost]
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.set_pressed_no_signal(level==current)
		button.tooltip_text="%s: %s of %s.\nBrings about %s a season.\nAbout 1 in %d hide what they owe.\nTrust in you −%d, holding together −%d." % [String(Purse.LEVEL_NAMES[level]),String(lq.words),Purse.harvest_word(),Purse.amount_text(float(lq.per_season)),int(lq.hidden_one_in),roundi(float(lq.trust)),roundi(float(lq.cohesion))]
		button.pressed.connect(func()->void:_choose_levy(level))
		pick.add_child(button)
	var cost:=_line("1 in %d hide their dues; holding together −%d." % [int(q.hidden_one_in),roundi(float(q.cohesion))],13,T.INK_MUTED,true);cost.name="LevyCost"
	cost.tooltip_text="A light levy is what custom expects. Heavier ones are resented: trust in you and how well the people hold together fall while it lasts, and more is hidden.\nOur hands reach %d in 100 of what is owed: helpers and clerks, tallies and registers find it." % roundi(float(q.reach)*100.0)
	levy_box.add_child(cost)


func _choose_levy(level:String)->void:
	var result:=Purse.set_levy(level)
	var q:Dictionary=result.get("quote",{})
	var said:="The levy is %s: %s of %s." % [level,String(q.get("words","")),Purse.harvest_word()]
	_say(said)
	Tracker.setting_order("Set the levy to %s" % level,{"ok":true,"message":said},"purse",_keeper(),"economy:2")
	refresh(true)


# --- What it pays for -----------------------------------------------------------------

func _build_lines(forecast:Dictionary,purse:Dictionary)->void:
	_clear(lines_box)
	var paid:PackedStringArray=[]
	for line:String in Purse.LINES:
		if bool(((forecast.lines as Dictionary).get(line,{}) as Dictionary).get("on",false)):paid.append(String(LINE_LABELS[line]).to_lower())
	var answer:=_answer("Pays for "+_and_list(paid) if not paid.is_empty() else "Pays for nothing yet",17);answer.name="PaysAnswer"
	lines_box.add_child(answer)
	for line:String in Purse.LINES:lines_box.add_child(_line_row(line,forecast,purse))
	var army:Dictionary=purse.get("last_army",{}) if purse.get("last_army") is Dictionary else {}
	if int(purse.get("unpaid_months",0))>0:
		var warn:=_line("Soldiers unpaid %d %s: will −%d, %d went home." % [int(purse.unpaid_months),"month" if int(purse.unpaid_months)==1 else "months",roundi(float(army.get("will_lost",0.0))*100.0),int(army.get("deserted",0))],13,T.RED_TEXT,true)
		warn.name="Unpaid";lines_box.add_child(warn)


static func _and_list(words:PackedStringArray)->String:
	if words.size()<=1:return "".join(words)
	return ", ".join(words.slice(0,words.size()-1))+" and "+words[words.size()-1]


func _line_row(line:String,forecast:Dictionary,purse:Dictionary)->Control:
	var entry:Dictionary=(forecast.lines as Dictionary).get(line,{})
	var on:=bool(entry.get("on",false))
	var panel:=PanelContainer.new();panel.name="Line_%s" % line
	panel.add_theme_stylebox_override("panel",_skin(T.PAPER,T.RULE,8,4 if on else 0,_ink(line) if on else T.RULE))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);panel.add_child(row)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",1);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);words.add_child(top)
	var title:=_line(String(Purse.LINE_NAMES[line]),14,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));top.add_child(title)
	if line!="relief":
		var cost:=_line("%s a season" % Purse.number(float(entry.get("per_season",0.0))),14,T.INK if on else T.INK_MUTED);cost.name="Cost";top.add_child(cost)
	var effect:=_line(_effect_words(line,on,entry,purse),13,T.INK_MUTED,true);effect.name="Effect";words.add_child(effect)
	effect.tooltip_text=_effect_tip(line)
	var toggle:=Button.new();toggle.name="Toggle";toggle.toggle_mode=true;toggle.focus_mode=Control.FOCUS_NONE
	toggle.text="On" if on else "Off";toggle.custom_minimum_size=Vector2(56,0);toggle.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	toggle.set_pressed_no_signal(on)
	toggle.tooltip_text="%s: %s." % [String(Purse.LINE_NAMES[line]),"switch it off" if on else "switch it on"]
	toggle.pressed.connect(func()->void:_toggle(line,not on))
	row.add_child(toggle)
	if line=="relief":
		var now:=Button.new();now.name="BuyNow";now.text="Send now";now.focus_mode=Control.FOCUS_NONE;now.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		now.tooltip_text="Send up to a quarter of %s to hungry towns today." % Purse.account_name()
		now.pressed.connect(_buy_now)
		row.add_child(now)
	return panel


## What a line does now, in the engine's numbers (twelve words or fewer).
func _effect_words(line:String,on:bool,entry:Dictionary,purse:Dictionary)->String:
	match line:
		"army":
			if on and int(purse.get("unpaid_months",0))==0:return "%s · will and readiness kept" % String(entry.get("who",""))
			return "Unpaid: will −%d a month, 1 in 50 go home" % roundi(100.0*0.06)
		"scholars":return ("%s · research %d%% faster: a 100-day discovery in %d days" if on else "%s · would make research %d%% faster: a 100-day discovery in %d days") % [String(entry.get("who","")),roundi(Purse.SCHOLARS_MAX*100.0),roundi(100.0/(1.0+Purse.SCHOLARS_MAX))]
		"crews":return ("%s · building %d%% faster: a 100-day work in %d days" if on else "%s · would build %d%% faster: a 100-day work in %d days") % [String(entry.get("who","")),roundi(Purse.CREWS_MAX*100.0),roundi(100.0/(1.0+Purse.CREWS_MAX))]
		"relief":
			var towns:=Purse.food_places()
			var hungry:=towns.filter(func(p:Dictionary)->bool:return float(p.days)<Purse.HUNGRY_DAYS).size()
			if Purse.in_kind():return "%d hungry %s now" % [hungry,"town" if hungry==1 else "towns"]
			if not Purse.market_open():return "%d hungry %s · no market to buy more" % [hungry,"town" if hungry==1 else "towns"]
			return "%d hungry %s · food about %s a ration" % [hungry,"town" if hungry==1 else "towns",Purse.number(float(WorldSimulation.state.market_prices.get("Food",1.0)))]
	return ""

func _effect_tip(line:String)->String:
	match line:
		"army":return "Pay on top of rations: %s. Unpaid soldiers lose will each month, are slower to muster, and some go home; more after three months." % Purse.pay_word()
		"scholars":return "A keep for those at research, a seventh of a day's work each. While it is paid, research goes faster."
		"crews":return "Wages for those at building, a seventh of a day's work each. While they are paid, building goes faster."
		"relief":
			var tip:="Each month, food goes from the store to towns under %d days of it, up to a quarter of the store." % int(Purse.HUNGRY_DAYS)
			if not Purse.in_kind():tip+=" With coin, more is bought at the market price from towns with more than %d days of it." % int(Purse.SELLER_DAYS)
			return tip
	return ""

func _toggle(line:String,on:bool)->void:
	var result:=Purse.set_line(line,on)
	var said:="%s: %s." % [String(Purse.LINE_NAMES[line]),"on" if on else "off"]
	if on and line!="relief":said="%s: on, about %s a season." % [String(Purse.LINE_NAMES[line]),Purse.amount_text(float(result.get("cost_per_season",0.0)))]
	_say(said)
	Tracker.setting_order("%s %s" % [String(Purse.LINE_NAMES[line]),"on" if on else "off"],{"ok":true,"message":said},"purse",_keeper(),"economy:2")
	refresh(true)

func _buy_now()->void:
	var bought:=Purse.buy_relief(Purse.balance()*Purse.RELIEF_SHARE)
	var said:="Sent %s rations to the hungry." % Purse.number(float(bought.rations)) if float(bought.rations)>0.0 else "Nothing sent: %s." % String(bought.reason)
	_say(said)
	Tracker.setting_order("Buy food for the hungry",{"ok":float(bought.spent)>0.0,"message":said,"reason":said},"purse",_keeper(),"economy:2")
	refresh(true)


# --- What we make ---------------------------------------------------------------------

## What the makers make a day and its worth, in every town (the Production
## screen's own count). Goods held are in "What we own"; barter is with
## trade. Arms are counted on the Production screen.
func _build_goods(cards:Array)->void:
	_clear(goods_box)
	var report:Dictionary=WorldSimulation.state.civilian_goods.get("report",{})
	var made:=float(report.get("made",0.0))
	# Every town's makers, as the Production screen counts them.
	if not cards.is_empty():
		made=0.0
		for card:Dictionary in cards:made+=float(card.get("made",0.0))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);goods_box.add_child(row)
	row.add_child(_goods_picture())
	var reading:=VBoxContainer.new();reading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(reading)
	var answer:=_answer("%s goods" % _amount(made),30);answer.name="GoodsMade"
	var buys:=Goods.buys(maxf(made,0.0),["Food","Timber"])
	answer.tooltip_text="Makers make for the homes first, then for barter. Each makes about %s a day now: more with the crafts the people know, and as well as people work.\nA day's goods buy %s rations or %s timber at our own prices." % [_amount(Goods.goods_per_maker_day()),_amount(float(buys.Food)),_amount(float(buys.Timber))]
	reading.add_child(answer)
	reading.add_child(_line("made each day",14,T.INK_MUTED))
	var worth:=_line("Worth %s rations a day" % _amount(Goods.worth_in_rations(made)),16,T.TEAL_TEXT,true)
	goods_box.add_child(worth)
	if String(report.get("reason",""))!="" and made<=0.001:
		goods_box.add_child(_line(String(report.reason)+".",13,T.INK_MUTED,true))
	# Arms are made by the same makers; they are shown with the workshops.
	var arms:=VBoxContainer.new();arms.name="ArmsPointer";arms.add_theme_constant_override("separation",8);goods_box.add_child(arms)
	var said:=_line("Makers also equip the watch.",13,T.INK_MUTED,true);said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;arms.add_child(said)
	said.tooltip_text="While the watch lacks arms, some makers make them instead of goods. What is held, made and needed is on the Production screen, under Military."
	arms.add_child(_go("SeeArms","See arms","Open Production, Military: arms in store, on the watch, made a day.","production",2))


# --- What we own --------------------------------------------------------------------

## The goods held in every town and what they are worth at our own prices
## (trade_prices.gd): the answer; what they buy; a head against a typical
## people of the age (standing_scale.gd, the yardstick Standing's Wealth
## reads); what can change hands; coin and weighed metal once known.
func _build_own(held:Dictionary,spare:float)->void:
	_clear(own_box)
	var goods:=float(held.goods)
	var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var top:=_grid(own_box,"GoodsOverview",2,560)
	var reading:=VBoxContainer.new();reading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;reading.add_theme_constant_override("separation",4);top.add_child(reading)
	var answer:=_answer("%s goods" % EraWords.grouped(roundi(goods)),48);answer.name="GoodsHeld"
	answer.add_theme_font_override("font",T.font("voice"))
	answer.tooltip_text="Made things our homes hold and keep for barter, in every town: tools, cord, baskets, pots. Goods are our first money.\nOne is worth %s rations at our own prices." % _amount(Goods.worth_in_rations(1.0))
	reading.add_child(answer)
	var value:=_line("Worth %s rations" % EraWords.grouped(roundi(Goods.worth_in_rations(goods))),22,T.GOLD_TEXT,true);value.name="GoodsValue";reading.add_child(value)
	var available:=HBoxContainer.new();available.add_theme_constant_override("separation",12);available.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(available)
	var ring:=Graphics.new();ring.name="GoodsAvailability";ring.kind="ring";ring.values=[spare,goods];ring.custom_minimum_size=Vector2(136,136);available.add_child(ring)
	ring.mouse_filter=Control.MOUSE_FILTER_PASS
	ring.tooltip_text="Share of recorded goods available to change hands, after homes, learners and workshop reserves."
	var reserve:=VBoxContainer.new();reserve.size_flags_horizontal=Control.SIZE_EXPAND_FILL;reserve.size_flags_vertical=Control.SIZE_SHRINK_CENTER;available.add_child(reserve)
	var change:=_answer("%s available" % EraWords.grouped(roundi(spare)),22);change.name="GoodsSpare";reserve.add_child(change)
	change.tooltip_text="Goods beyond what the homes need, what the learners will take and what is kept back for the first workshops. With other peoples they buy food, materials, arms, and bring families who come to work: see Trade."
	reserve.add_child(_line("to trade or give",14,T.INK_MUTED,true))
	reserve.add_child(_line("%s kept for use" % EraWords.grouped(roundi(maxf(0.0,goods-spare))),14,T.INK_MUTED,true))
	var buys:=Goods.buys(goods,["Timber","Stone","Fiber Plants"])
	var typical:=float(Scale.anchors(Scale.GOODS,_year())[1])
	var head:=_line("%s per person · %s typical for our age" % [_amount(goods/people),_amount(typical)],14,T.INK_MUTED,true);head.name="GoodsAHead"
	head.tooltip_text="Goods held per person, compared with a typical people of our age. Both bars use the same scale."
	reading.add_child(head)
	var compare:=Graphics.new();compare.name="GoodsComparison";compare.kind="comparison";compare.values=[goods/people,typical];compare.labels=["Ours","Typical"];compare.custom_minimum_size=Vector2(180,62);reading.add_child(compare)
	var buy:=_line("Buying power · choose one equivalent",12,T.GOLD_TEXT,true);buy.name="GoodsBuy"
	buy.tooltip_text="All %s goods would buy %s timber, %s stone OR %s fibre at our own prices. These are alternatives, not additional holdings." % [EraWords.grouped(roundi(goods)),EraWords.grouped(roundi(float(buys.Timber))),EraWords.grouped(roundi(float(buys.Stone))),EraWords.grouped(roundi(float(buys["Fiber Plants"])))];own_box.add_child(buy)
	var exchange:=_grid(own_box,"GoodsEquivalents",3,560)
	for spec:Array in [["Timber","timber",0],["Stone","stone",1],["Fiber Plants","fibre",3]]:
		var option:=HBoxContainer.new();option.add_theme_constant_override("separation",10);option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;exchange.add_child(option)
		option.add_child(MaterialArt.picture(int(spec[2]),72,64))
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.size_flags_vertical=Control.SIZE_SHRINK_CENTER;option.add_child(text)
		text.add_child(_answer(EraWords.grouped(roundi(float(buys[spec[0]]))),26))
		text.add_child(_line("loads of "+String(spec[1]),13,T.INK_MUTED,true))
	if float(held.coin)>=0.5:
		var coin:=_line("With %s in %s, worth %s goods." % [EraWords.grouped(roundi(float(held.coin))),String(held.coin_word),EraWords.grouped(roundi(float(held.worth)-goods))],13,T.INK,true);coin.name="CoinHeld"
		coin.tooltip_text="What households, their hoards and the treasury hold, at our own prices."
		own_box.add_child(coin)


# --- Treasures ------------------------------------------------------------------------

func _build_treasures(held:Dictionary)->void:
	_clear(treasures_box)
	var count:=int(held.treasures)
	var worth:=float(held.treasure_worth)
	var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var typical:=float(Scale.anchors(Scale.TREASURES,_year())[1])
	var row:=HBoxContainer.new();row.name="TreasuresRow";row.add_theme_constant_override("separation",12);treasures_box.add_child(row)
	var art:=_treasure_picture()
	if art!=null:row.add_child(art)
	var said:Label
	if count==0:said=_answer("None held yet",24)
	else:said=_answer("%d %s" % [count,"treasure" if count==1 else "treasures"],30)
	said.name="Treasures";said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(said)
	said.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	said.tooltip_text="Old pieces found on the land or got in trade. Each is appraised by its rarity, how long we have held it and how well it is studied.\nAbout %s goods a head; a typical people of our age holds about %s." % [_amount(worth/people),_amount(typical)]
	treasures_box.add_child(_line("Appraised at about %s goods" % EraWords.grouped(roundi(worth)) if count>0 else "Discoveries and exchanges grow the collection.",15,T.GOLD_TEXT,true))
	var see:=Button.new();see.name="SeeTreasures";see.text="See treasures";see.focus_mode=Control.FOCUS_NONE;see.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	see.tooltip_text="Open the collection: every piece, what it is worth and what it does."
	see.pressed.connect(func()->void:preload("res://scripts/hud/exchange_collection_panel.gd").open())
	_style_link(see)
	treasures_box.add_child(see)


# --- Materials in store ------------------------------------------------------------------

func _build_materials(held:Dictionary)->void:
	_clear(materials_box)
	var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var materials:=float(held.materials)
	var typical:=float(Scale.anchors(Scale.MATERIALS,_year())[1])
	var row:=HBoxContainer.new();row.name="MaterialsRow";row.add_theme_constant_override("separation",3);materials_box.add_child(row)
	for index in 4:
		var art:=MaterialArt.picture(index,48,48);art.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(art)
	var said:=_answer("%s loads" % EraWords.grouped(roundi(materials)),30);said.name="Materials";materials_box.add_child(said)
	said.tooltip_text="In every town's yards. Builders and makers draw on them; what they can spare also changes hands by barter."
	var head:=_line("%s per person · %s typical" % [_amount(materials/people),_amount(typical)],13,T.INK_MUTED,true);head.name="MaterialsAHead";materials_box.add_child(head)
	head.tooltip_text="A typical people of our age, counted the same way."
	materials_box.add_child(_go("SeeMaterials","See materials","Open Materials: each one in store, coming in and going out.","economy",1))


# --- The common store, from the Wealth tab ----------------------------------------------

## Before coinage the common store is food: it lives on Food & water. One
## line and a way there.
func _build_store_pointer()->void:
	_clear(store_box)
	var row:=HBoxContainer.new();row.name="StorePointer";row.add_theme_constant_override("separation",10);store_box.add_child(row)
	var said:=_line("%s rations, %s days of food; kept with Food & water." % [EraWords.grouped(roundi(Purse.balance())),EraWords.grouped(roundi(Purse.days_of_food()))],13,T.INK_MUTED,true)
	said.name="StoreLine";said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(said)
	said.tooltip_text="Food the levy took from every town's stores, kept for all. It pays the soldiers, feeds the hungry, keeps scholars and crews. It is food, so it lives with the food; with coin it becomes the treasury, here."
	row.add_child(_go("SeeStore","See the store","Open Food & water: the common store, the levy and what it pays for.","economy",0))


## A button that opens another screen (the dock's provider).
func _go(node_name:String,text:String,tip:String,section:String,sub:int)->Button:
	var go:=Button.new();go.name=node_name;go.text=text;go.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_style_link(go)
	go.tooltip_text=tip
	go.pressed.connect(func()->void:if on_open.is_valid():on_open.call(section,sub))
	go.disabled=not on_open.is_valid()
	return go

static func _year()->float:
	return maxf(0.0,float(WorldSimulation.state.elapsed_days)/365.0)


static func _amount(value:float)->String:
	if value>=10.0:return EraWords.grouped(roundi(value))
	return str(snappedf(value,0.1))


# --- Business -------------------------------------------------------------------------

## The rung we stand on and, in plain words, what business does now; what
## the next rung needs; the stance and its bust odds, shown at once only
## when business does enough to matter (else behind one button). Every
## number is the engine's (enterprise.gd).
func _build_business()->void:
	_clear(business_box)
	_build_barter()
	var panel:=_panel(business_box,"Business")
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	var r:=Business.rung()
	var x:=Business.effects()
	var work:=float(x.work)
	var matters:=work>=BUSINESS_MATTERS or Business.booming() or Business.bust_left()>0
	var ladder:PackedStringArray=[]
	for index in Business.RUNGS.size():ladder.append(("› " if index==r else "   ")+Business.rung_name(index))
	var effect_word:="" if r<1 else (": hardly any effect yet" if not matters else ": all work %s" % Business.percent(work))
	var where:=_answer(Business.rung_name(r)+effect_word,17);where.name="RungNow"
	where.tooltip_text="The steps of business, ours marked:\n"+"\n".join(ladder)
	column.add_child(where)
	var needs:=Business.next_needs(true)
	if needs!="":
		var next:=_line("Next: %s; needs %s." %[String((Business.RUNGS[r+1] as Dictionary).short).to_lower(),needs],13,T.INK_MUTED,true);next.name="NextRung"
		next.tooltip_text="%s needs %s." % [Business.rung_name(r+1),Business.next_needs()]
		column.add_child(next)
	if r<1:return
	var e:=Business.state()
	var share:=Business.share()
	var goal:=float(e.get("target",Business.target()))
	var said:=_line("Business holds %s workers, heading for %s." %[Business.in_100(share),Business.in_100(goal)],13,T.INK,true);said.name="ShareWords"
	said.tooltip_text="Growing takes decades; failures are fast. This rung can hold up to %s of the workers." % Business.in_100(float((Business.RUNGS[r] as Dictionary).cap))
	column.add_child(said)
	var effect:=_line("%s to all work and goods; trade reach +%d." % [Business.percent(work),roundi(float(x.trade)*100.0)],13,T.GREEN_TEXT if matters else T.INK_MUTED,true);effect.name="BusinessEffect"
	effect.tooltip_text="What business does now, at its size today: all work (harvests, within what the land yields; building, digging, hauling and learning) and the goods made go this much faster, trade reaches this much further, and the richest fifth settle %d parts in 100 higher. The workshops' making capacity rises with it, up to its usual ceiling." % roundi(float(x.rich)*100.0)
	column.add_child(effect)
	var left:=Business.bust_left()
	if left>0:
		var bust:=_line("A bust: all work %s for %d more %s, easing." % [Business.percent(-Business.BUST_HIT*float(left)/maxf(1.0,float((e.get("bust",{}) as Dictionary).get("months",1)))),left,"month" if left==1 else "months"],13,T.RED_TEXT,true);bust.name="BustNow"
		column.add_child(bust)
	elif Business.booming():
		var boom:=_line("Booming %d %s on credit: work +%d%%, bust odds up %d%%." % [int(e.get("boom_months",0)),"month" if int(e.get("boom_months",0))==1 else "months",roundi(Business.BOOM_GAIN*100.0),roundi(float(e.get("boom_months",0))/Business.BOOM_ODDS_MONTHS*100.0)],13,T.GOLD_TEXT,true);boom.name="BoomNow"
		column.add_child(boom)
	# The stance: one at a time, set like the levy. While business does
	# hardly anything it waits behind one button.
	var current:=Business.stance()
	var shown:=matters or stances_open
	var toggle:=Button.new();toggle.name="StanceToggle";toggle.focus_mode=Control.FOCUS_NONE;toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	toggle.text=("Stance: %s · hide" if shown else "Stance: %s · change") % Business.stance_name(current)
	toggle.tooltip_text="How the god treats business: guarded, chartered or open. It matters little while business is this small."
	toggle.pressed.connect(func()->void:stances_open=not shown;refresh(true))
	toggle.visible=not matters
	column.add_child(toggle)
	var choice:=VBoxContainer.new();choice.name="StanceChoice";choice.add_theme_constant_override("separation",6);choice.visible=shown;column.add_child(choice)
	var pick:=HFlowContainer.new();pick.name="Stances";pick.add_theme_constant_override("h_separation",8);pick.add_theme_constant_override("v_separation",8);choice.add_child(pick)
	for id:String in Business.choices():
		var q:=Business.quote(id)
		var button:=Button.new();button.name="Stance_%s" % id;button.toggle_mode=true;button.focus_mode=Control.FOCUS_ALL
		button.text="%s\n%s work · %s" % [Business.stance_name(id),Business.percent(float(q.work)),_short_odds(float(q.bust_year))]
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.set_pressed_no_signal(id==current)
		var fee:=("\n%s: about %s a season at today's size, %s once grown." % [String(q.purse_name),Purse.amount_text(float(q.purse_now)),Purse.number(float(q.purse_season))]) if float(q.purse_season)>=0.5 else ""
		button.tooltip_text="%s: %s.\nGrows toward %s of the workers.\nAll work and goods %s, trade reach +%d.\nThe richest fifth +%d parts in 100.\nBusts: %s.%s\nChanging costs %d points of trust." % [Business.stance_name(id),String(q.words).to_lower(),Business.in_100(float(q.target)),Business.percent(float(q.work)),roundi(float(q.trade)*100.0),roundi(float(q.rich)*100.0),String(q.odds).to_lower(),fee,roundi(Business.CHANGE_TRUST*100.0)]
		button.pressed.connect(func()->void:_choose_stance(id))
		pick.add_child(button)
	var q:=Business.quote(current)
	var odds:=_line("%s: busts %s." % [Business.stance_name(current),String(Business.odds_words(Business.bust_year())).to_lower()],13,T.INK_MUTED,true);odds.name="BustOdds"
	odds.tooltip_text=String(q.words)+".\nA bust cuts business by a third at once, slows all work 4% for 6 to 12 months, writes off debts, and costs the rich and the people's unity. Honest books (double-entry ledgers, audited accounts, a central bank) make busts rarer."
	choice.add_child(odds)


## How goods change hands at home in this age, and a way to the Trade page.
func _build_barter()->void:
	var row:=HBoxContainer.new();row.name="Barter";row.add_theme_constant_override("separation",10);business_box.add_child(row)
	var stage:=String(WorldSimulation.state.economy_stage)
	var words:="Goods change hands by barter, for food and materials." if stage=="subsistence" else ("Weighed metal settles trades beside barter." if stage=="weighed_metal" else "Coin settles most trades.")
	var said:=_line(words,13,T.INK,true);said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(said)
	said.tooltip_text="%d in 100 of what is made reaches the market. Makers and carriers widen it: makers bring goods to trade, carriers bring them to the hearth." % roundi(float(WorldSimulation.state.economy_metrics.get("market_access",0.0))*100.0)
	row.add_child(_go("SeeTrade","See trade","Open Trade: what passes between us and other peoples.","economy",3))


## "bust 1 in 40 yrs" for a stance button's second line.
static func _short_odds(year:float)->String:
	if year<=0.0:return "no busts"
	return "bust 1 in %s yrs" % EraWords.grouped(maxi(1,roundi(1.0/year)))

func _choose_stance(id:String)->void:
	var result:=Business.set_stance(id)
	var said:=String(result.get("error","")) if not bool(result.get("ok",false)) else "Business is %s%s." % [Business.stance_name(id).to_lower(),(": trust −%d" % roundi(float(result.trust)*100.0)) if float(result.get("trust",0.0))>0.0 else ""]
	_say(said)
	Tracker.setting_order("Business: %s" % Business.stance_name(id),{"ok":bool(result.get("ok",false)),"message":said,"reason":said},"purse",_keeper(),"economy:2")
	refresh(true)


# --- Who holds the wealth ----------------------------------------------------------------

func _build_wealth()->void:
	_clear(wealth_box)
	var shares:Array=WorldSimulation.state.wealth_shares
	if shares.size()!=5:shares=[0.08,0.13,0.19,0.25,0.35]
	var top:=roundi(float(shares[4])*100.0)
	var said:=_answer("The richest fifth hold %d in 100; the poorest %d" % [top,roundi(float(shares[0])*100.0)],17);said.name="Shares"
	wealth_box.add_child(said)
	var fifths:=Graphics.new();fifths.name="Fifths";fifths.kind="fifths";fifths.values=shares.duplicate();fifths.labels=["Poorest","2nd","Middle","4th","Richest"];fifths.custom_minimum_size=Vector2(200,180)
	fifths.mouse_filter=Control.MOUSE_FILTER_PASS
	fifths.tooltip_text="Each fifth of our households, poorest to richest, and its part of all we have."
	wealth_box.add_child(fifths)
	var ends:=_line("Each column is one fifth of households.",13,T.INK_MUTED,true);ends.name="FifthsEnds";wealth_box.add_child(ends)
	var bounds:Array=preload("res://scripts/economy_system.gd").WEALTH_BOUNDS.get(String(WorldSimulation.state.economy_stage),[0.28,0.55,0.38])
	var parts:Dictionary=WorldSimulation.state.economy_metrics.get("social_pressure_parts",{}) if WorldSimulation.state.economy_metrics.get("social_pressure_parts") is Dictionary else {}
	var causes:PackedStringArray=[]
	for pair:Array in [["unequal","shares"],["want","want"],["prices","prices"],["levy","levy"]]:
		var points:=float(parts.get(String(pair[0]),0.0))*100.0
		if points>=0.5:causes.append("%s −%d" % [String(pair[1]),roundi(points)])
	var pressure:=_line(("Pressure on trust: "+", ".join(causes)+".") if not causes.is_empty() else "No pressure on trust from want or shares.",13,T.RED_TEXT if not causes.is_empty() else T.INK_MUTED,true)
	pressure.name="Pressure"
	pressure.tooltip_text="Points a day's reckoning takes from trust in you; holding together loses about half as much.\nIn this age the richest fifth's part settles near %d in 100 and cannot pass %d. Sharing out, feasts and the purse's pay pull it down; want, rising prices and failed debts push it up." % [roundi(float(bounds[2])*100.0),roundi(float(bounds[1])*100.0)]
	wealth_box.add_child(pressure)


# --- Lately -------------------------------------------------------------------------------

func _build_ledger(purse:Dictionary)->void:
	_clear(ledger_box)
	var entries:Array=(purse.ledger as Array).slice(0,5)
	if entries.is_empty():
		ledger_box.add_child(_line("Nothing yet: the first reckoning comes at the month's end.",13,T.INK_MUTED,true));return
	for entry:Dictionary in entries:
		var amount:=float(entry.get("amount",0.0))
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10)
		var when:=_line(EraWords.when(int(entry.get("day",0))),13,T.INK_MUTED);when.custom_minimum_size=Vector2(118,0);row.add_child(when)
		var what:=_line(Tracker.short(String(entry.get("why","")),9),13,T.INK,true);what.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(what)
		what.tooltip_text=String(entry.get("why",""))
		if absf(amount)>=0.05:row.add_child(_line(("+" if amount>0.0 else "−")+Purse.number(absf(amount)),13,T.GREEN_TEXT if amount>0.0 else T.RED_TEXT))
		ledger_box.add_child(row)


# --- Pieces ---------------------------------------------------------------------------------

func _keeper()->String:
	var gov=WorldSimulation.government
	if gov==null:return ""
	var holder:Dictionary=gov.officeholder("Treasurer")
	if holder.is_empty():holder=gov.officeholder("Steward")
	return String(holder.get("name",""))

func _ink(line:String)->Color:
	match line:
		"army":return T.AMBER
		"scholars":return T.BLUE
		"crews":return T.TEAL
		"relief":return T.GREEN
		"spent":return T.VIOLET
	return T.RULE_STRONG

func _say(text:String)->void:
	feedback.text=text
	feedback.visible=text!=""

func _section(title:String)->VBoxContainer:
	if mode=="wealth":return _visual_section(title,self,title.to_pascal_case()+"Card","")
	var kicker:=_line(title.to_upper(),13,T.INK_MUTED);kicker.add_theme_font_override("font",T.font("ui_strong"));add_child(kicker)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);add_child(box)
	return box

func _panel(parent:Node,name_hint:String)->PanelContainer:
	var panel:=PanelContainer.new();panel.name=name_hint
	var skin:=_skin(T.PAPER_RAISED,T.RULE,12,0,T.RULE)
	if mode=="wealth":skin.set_border_width_all(0);skin.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel",skin);parent.add_child(panel)
	return panel

func _visual_section(title:String,parent:Node,node_name:String,icon:String)->VBoxContainer:
	var panel:=PanelContainer.new();panel.name=node_name;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=_skin(T.PAPER_RAISED,T.RULE,18,0,T.RULE)
	if node_name=="WealthHero":style.border_width_top=3;style.border_color=T.GOLD
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12);panel.add_child(column)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",8);column.add_child(header)
	if not icon.is_empty():
		var mark:=Emblem.new(icon);mark.custom_minimum_size=Vector2(28,28);header.add_child(mark)
	var kicker:=_line(title.to_upper(),12,T.GOLD_TEXT,true);kicker.set_meta("wealth_section",true);kicker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;kicker.size_flags_vertical=Control.SIZE_SHRINK_CENTER;header.add_child(kicker)
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",8);box.set_meta("section_kicker",kicker);column.add_child(box)
	return box

func _grid(parent:Node,node_name:String,count:int,threshold:float)->GridContainer:
	var grid:=GridContainer.new();grid.name=node_name;grid.columns=1;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",12)
	grid.set_meta("wide_columns",count);grid.set_meta("wide_threshold",threshold);parent.add_child(grid)
	responsive_grids.append(grid)
	return grid

func _responsive()->void:
	var available:=size.x
	var ancestor:=get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			if ancestor.size.x>0:available=minf(available,maxf(0.0,ancestor.size.x-24.0))
			break
		ancestor=ancestor.get_parent()
	var retained:Array[GridContainer]=[]
	for grid:GridContainer in responsive_grids:
		if not is_instance_valid(grid):continue
		retained.append(grid)
		var columns:=int(grid.get_meta("wide_columns")) if available>=float(grid.get_meta("wide_threshold")) else 1
		if grid.columns!=columns:grid.columns=columns
	responsive_grids=retained

func _style_link(button:Button)->void:
	button.focus_mode=Control.FOCUS_ALL
	button.custom_minimum_size.y=32
	button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size",14)
	for state:String in ["normal","hover","pressed"]:
		var style:=_skin(T.PAPER_RAISED if state=="normal" else T.HOVER_BG,T.RULE,8,0,T.RULE)
		style.content_margin_top=4;style.content_margin_bottom=4
		button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color",T.TEAL_TEXT)

func _goods_picture()->Control:
	var mount:=PanelContainer.new();mount.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var paper:=_skin(Color("eee5d6"),T.RULE,6,0,T.RULE)
	mount.add_theme_stylebox_override("panel",paper)
	var picture:=TextureRect.new();picture.name="MakingIllustration";picture.custom_minimum_size=Vector2(64,64)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.mouse_filter=Control.MOUSE_FILTER_PASS
	var bench:=Production._goods_bench()
	picture.texture=ProductArt.texture(1) if bench=="kiln" else Icons.workshop_texture(bench,Color("39352d"),96)
	picture.tooltip_text="The crafts our people can practise."
	mount.add_child(picture)
	return mount

func _treasure_picture_key()->Array:
	var result:Array=[]
	var exchange:Dictionary=WorldSimulation.state.society_exchange
	for item:Variant in (exchange.get("collections",{}) as Dictionary).values():
		if item is Dictionary and String(item.get("kind",""))=="artifact":result.append([item.get("id",""),ArtifactArt.image_path(item)])
	return result

func _treasure_picture()->TextureRect:
	var exchange:Dictionary=WorldSimulation.state.society_exchange
	for item:Variant in (exchange.get("collections",{}) as Dictionary).values():
		if not item is Dictionary:continue
		var texture:=ArtifactArt.texture(item)
		if texture==null:continue
		var picture:=TextureRect.new();picture.name="HeldTreasureIllustration";picture.texture=texture;picture.custom_minimum_size=Vector2(82,82)
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.mouse_filter=Control.MOUSE_FILTER_PASS
		picture.tooltip_text=String(item.get("name","A treasure in our collection"))
		return picture
	return null

## A section's answer: the one thing it says, in big plain words.
func _answer(text:String,font_size:=22)->Label:
	var label:=_line(text,font_size,T.INK,true);label.add_theme_font_override("font",T.font("ui_strong"))
	return label

func _clear(box:Node)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func _skin(bg:Color,border:Color,margin:int,left:int,stripe:Color)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1)
	if left>0:style.border_width_left=left;style.border_color=stripe
	style.set_corner_radius_all(T.RADIUS_CARD);style.set_content_margin_all(margin)
	return style

static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_PASS
	label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));label.add_theme_color_override("font_color",color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


## One bar of parts on a shared scale (HOI4's budget): each part its own
## colour, left to right; the empty rest is the paper's.
class PartsBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var parts:Array=[]
	var scale_to:=1.0
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.PAPER_SUNK)
		var x:=0.0
		for entry:Array in parts:
			var width:=size.x*float(entry[1])/maxf(0.001,scale_to)
			if width>0.5:draw_rect(Rect2(x,0.0,minf(width,size.x-x),size.y),entry[2]);x+=width
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE,false,1.0)
