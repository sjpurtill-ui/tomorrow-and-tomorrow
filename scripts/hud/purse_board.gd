extends VBoxContainer
## THE WEALTH TAB, one page. A strip of five figures across the top (goods
## held, goods to trade, goods made a day, the common store, treasures), then
## two columns of one-line rows:
##   left   the common store (the treasury after coinage): who gives it and
##          whether it grows, the levy as three choices on its row, each line
##          of spending with its cost and a switch on its row;
##          the day's work (hud/wealth_ledger.gd, mounted here);
##   right  what our goods would buy, the treasures held, trade and business
##          with its stance choices on the rows, and who holds the wealth by
##          fifths with the pressure it puts on trust.
## Every number is the engine's own (standing.gd wealth_held,
## civilian_goods.gd, realm_purse.gd, enterprise.gd). Sections are drawn
## again only when what they show changes; the strip's figures are written in
## place.
## "store" draws the store's rows alone.

signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const Business:=preload("res://scripts/enterprise.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Arms:=preload("res://scripts/weapons_stock.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const Standing:=preload("res://scripts/standing.gd")
const Scale:=preload("res://scripts/standing_scale.gd")
const Production:=preload("res://scripts/hud/content/dock_content_production.gd")
const ArtifactArt:=preload("res://scripts/hud/artifact_visuals.gd")
const Ledger:=preload("res://scripts/hud/wealth_ledger.gd")
const REFRESH_SECONDS:=1.0
const LINE_LABELS:={"army":"Soldiers","scholars":"Scholars","crews":"Crews","relief":"Food for the hungry","debts":"Old debts","spent":"Gifts and buying","spoiled":"Wear"}
## Business does "hardly anything yet" below this much added to all work;
## its stance is then tucked behind one button.
const BUSINESS_MATTERS:=0.01
## A store that would last this many seasons or more is shrinking "slowly".
const SLOW_SEASONS:=20.0

var head_box:VBoxContainer
var levy_box:VBoxContainer
var sources_box:VBoxContainer
var business_box:VBoxContainer
var own_box:VBoxContainer
var lines_box:VBoxContainer
var wealth_box:VBoxContainer
## The store's own head, named by the age (the common store, the treasury).
var store_kicker:Label
var feedback:Label
## "wealth" (the Wealth tab) or "store" (the store's rows alone).
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
var kpis:Dictionary={}
## The day's work (wealth_ledger.gd), mounted in the left column.
var ledger:Control

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
	add_theme_constant_override("separation",10)
	feedback=S.label("",13,T.GOLD_TEXT);feedback.name="Said";feedback.visible=false;feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var left:VBoxContainer=self
	var right:VBoxContainer=self
	if mode=="wealth":
		kpis=S.kpi_strip(self,[
			{"id":"held","label":"Goods held","icon":"Civilian Goods"},
			{"id":"spare","label":"To trade","icon":"Civilian Goods"},
			{"id":"made","label":"Made a day","icon":"make","icon_kind":"people"},
			{"id":"market","label":"To market","icon":"carry","icon_kind":"people"},
			{"id":"treasures","label":"Treasures","icon":"find","icon_kind":"chart","action":{"text":"Give","on_press":func()->void:preload("res://scripts/hud/exchange_collection_panel.gd").open(),"tip":"Every piece, what it is worth and what it does; hand one to another people"}},
		],"WealthKpis")
		for pair:Array in [["held","GoodsHeld"],["spare","GoodsSpare"],["made","GoodsMade"],["market","MarketReach"],["treasures","Treasures"]]:
			((kpis[pair[0]] as Dictionary).value as Label).name=String(pair[1])
		((kpis.held as Dictionary).sub as Label).name="GoodsValue"
		((kpis.treasures as Dictionary).action as Button).name="SeeTreasures"
		add_child(feedback)
		var grid:=_grid(self,"WealthColumns",2,700)
		grid.add_theme_constant_override("v_separation",14)
		left=_column(grid,"WealthLeft");right=_column(grid,"WealthRight")
	# The common store (the treasury after coinage).
	var store_head:=S.head(left,Purse.account_name())
	store_kicker=store_head.title;store_kicker.set_meta("wealth_section",true)
	head_box=_part(left)
	if mode=="store":add_child(feedback)
	sources_box=_part(left)
	levy_box=_part(left)
	lines_box=_part(left)
	if mode=="wealth":
		own_box=_section("What our goods buy",right,"OwnCard")
		business_box=_section("Trade and business",right,"BusinessCard")
		wealth_box=_section("Who holds the wealth",right,"DistributionCard")
		var block_ledger:Variant=block.get("ledger")
		if block_ledger is Dictionary:
			ledger=Ledger.new();right.add_child(ledger);ledger.setup(block_ledger)
	resized.connect(_responsive)
	refresh(true)
	_responsive()

func _column(parent:Node,node_name:String)->VBoxContainer:
	var column:=VBoxContainer.new();column.name=node_name;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",4);parent.add_child(column)
	return column

## A part of the store's rows.
func _part(parent:VBoxContainer)->VBoxContainer:
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",0);box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(box)
	return box

## A section of the right column: its small gold head, then its rows.
func _section(title:String,parent:VBoxContainer,node_name:String)->VBoxContainer:
	var holder:=VBoxContainer.new();holder.name=node_name;holder.add_theme_constant_override("separation",0);parent.add_child(holder)
	var head:=S.head(holder,title);(head.title as Label).set_meta("wealth_section",true)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",0);box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;holder.add_child(box)
	return box

func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()

## The dock's own refresh (dock_panel.gd, each day the page is open): the
## board keeps its nodes and reads the purse again, as a fresh page would.
func update_block(block:Dictionary)->bool:
	if String(block.get("mode","wealth"))!=mode or Purse.in_kind()!=kind_at_setup:return false
	if (block.get("ledger") is Dictionary)!=(ledger!=null):return false
	if ledger!=null and not ledger.update_block(block.ledger):return false
	if block.get("on_open") is Callable:on_open=block.on_open
	clock=0.0
	refresh()
	return true

## Each section is drawn again only when what it shows has changed and no
## button of it is held.
func refresh(force:=false)->void:
	var forecast:=Purse.forecast()
	var purse:=Purse.state()
	var season:=Purse.season()
	_rebuild("head",head_box,str([roundi(float(purse.balance)),roundi(float(forecast["in"])),roundi(float(forecast.out)),Purse.unit_word(),roundi(Purse.buys_rations()),season.total_in,season.total_out,mode]),force,func()->void:_build_head(forecast,season))
	var sources:=Purse.sources()
	_rebuild("sources",sources_box,str([sources.towns.map(func(t:Dictionary)->int: return roundi(float(t.levy))),roundi(float(sources.evaded)),Purse.unit_word()]),force,func()->void:_build_sources(sources))
	_rebuild("levy",levy_box,str([String(purse.levy),Purse.unit_word(),Purse.LEVELS.map(func(l:String)->int:return roundi(float(Purse.quote(l).per_season))),snappedf(float((forecast.quote as Dictionary).evasion),0.01)]),force,func()->void:_build_levy(String(purse.levy)))
	_rebuild("lines",lines_box,str([purse.lines,int(purse.unpaid_months),purse.last_army,forecast.lines,Purse.market_open(),_town_count()]),force,func()->void:_build_lines(forecast,purse))
	if mode!="wealth":return
	var held:=Standing.wealth_held()
	var cards:=Production.household_cards()
	var spare:=0.0
	for card:Dictionary in cards:spare+=float(card.get("spare",0.0))
	if cards.is_empty():spare=Goods.spare()
	_fill_kpis(held,spare,cards,forecast)
	var people:=roundi(float(WorldSimulation.state.population_exact))
	_rebuild("own",own_box,str([held.goods,held.coin,held.coin_word,held.worth,Goods.buys(float(held.goods),["Food","Timber","Stone","Fiber Plants"]),spare,people,int(_year())]),force,func()->void:_build_own(held,spare))
	var e:=Business.state()
	_rebuild("business",business_box,str([Business.rung(),snappedf(Business.share(),0.001),snappedf(float(e.get("target",0.0)),0.001),Business.stance(),snappedf(Business.factor(),0.001),int(e.get("boom_months",0)),Business.bust_left(),Business.choices().map(func(id:String)->Array:var q:=Business.quote(id);return [id,Purse.number(float(q.purse_now)),Purse.number(float(q.purse_season))]),Business.next_needs(),Purse.unit_word(),stances_open,String(WorldSimulation.state.economy_stage),snappedf(float(WorldSimulation.state.economy_metrics.get("market_access",0.0)),0.01)]),force,func()->void:_build_business())
	var parts:Variant=WorldSimulation.state.economy_metrics.get("social_pressure_parts",{})
	_rebuild("wealth",wealth_box,str([WorldSimulation.state.wealth_shares,parts,String(WorldSimulation.state.economy_stage)]),force,func()->void:_build_wealth())
	_responsive()

func _rebuild(key:String,box:Control,next:String,force:bool,build:Callable)->void:
	if box==null:return
	if not force and next==String(signatures.get(key,"")):return
	if not force and box.is_visible_in_tree() and box.get_global_rect().has_point(box.get_global_mouse_position()) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):return
	signatures[key]=next
	build.call()

# --- The strip ------------------------------------------------------------------------------

func _fill_kpis(held:Dictionary,spare:float,cards:Array,forecast:Dictionary)->void:
	var goods:=float(held.goods)
	var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var typical:=float(Scale.anchors(Scale.GOODS,_year())[1])
	var a_head:=goods/people
	S.set_kpi(kpis.held,{"value":S.n(goods),"ratio":clampf(a_head/maxf(0.01,typical*2.0),0.0,1.0),"color":T.GREEN if a_head>=typical else T.AMBER,
		"sub":"Worth %s rations" % S.n(Goods.worth_in_rations(goods)),
		"tip":"Made things our homes hold and keep for barter, in every town: tools, cord, baskets, pots. Goods are our first money.\nThe bar: goods a head against twice what a typical people of our age holds.\n%s goods a head; a typical people of our age holds %s.\nOne is worth %s rations at our own prices." % [S.n(a_head),S.n(typical),S.n(Goods.worth_in_rations(1.0))]})
	S.set_kpi(kpis.spare,{"value":S.n(spare),"ratio":clampf(spare/maxf(1.0,goods),0.0,1.0),"color":T.TEAL,"sub":"%s kept for use" % S.n(maxf(0.0,goods-spare)),
		"tip":"Goods beyond what the homes need, what the learners will take and what is kept back for the first workshops. With other peoples they buy food, materials, arms, and bring families who come to work (the Trade tab).\nThe bar: the share of all goods held that can change hands."})
	var report:Dictionary=WorldSimulation.state.civilian_goods.get("report",{})
	var made:=float(report.get("made",0.0))
	var worn:=0.0
	if not cards.is_empty():
		made=0.0
		for card:Dictionary in cards:made+=float(card.get("made",0.0));worn+=float(card.get("worn",0.0))
	S.set_kpi(kpis.made,{"value":S.n(made),"ratio":clampf(made/maxf(0.01,made+worn),0.0,1.0) if made+worn>0.01 else -1.0,"color":T.GREEN,"sub":"worth %s rations · %s wear out" % [S.n(Goods.worth_in_rations(made)),S.n(worn)],
		"tip":"Goods the makers made today in every town (the Workshops tab draws how). Each maker makes about %s a day: more with the crafts the people know, and as well as people work.\nThe bar: made against made and worn out." % S.n(Goods.goods_per_maker_day())})
	var reach:=clampf(float(WorldSimulation.state.economy_metrics.get("market_access",0.0)),0.0,1.0)
	S.set_kpi(kpis.market,{"value":"%d%%" % roundi(reach*100.0),"ratio":reach,"color":T.TEAL,"sub":"of what is made",
		"tip":"%d in 100 of what is made reaches the market, where goods change hands %s. Makers and carriers widen it: makers bring goods to trade, carriers bring them to the hearth." % [roundi(reach*100.0),"by barter, for food and materials" if String(WorldSimulation.state.economy_stage)=="subsistence" else ("with weighed metal beside barter" if String(WorldSimulation.state.economy_stage)=="weighed_metal" else "for coin")]})
	var count:=int(held.treasures);var worth:=float(held.treasure_worth)
	var t_typical:=float(Scale.anchors(Scale.TREASURES,_year())[1])
	S.set_kpi(kpis.treasures,{"value":S.n(count),"ratio":clampf((worth/people)/maxf(0.01,t_typical*2.0),0.0,1.0),"color":T.GOLD,"sub":"appraised %s goods" % S.n(worth) if count>0 else "none held yet",
		"tip":"Old pieces found on the land or got in trade. Each is appraised by its rarity, how long we have held it and how well it is studied.\nThe bar: worth a head (%s goods) against twice a typical people of our age (%s)." % [S.n(worth/people),S.n(t_typical)]})

# --- The store ----------------------------------------------------------------------

## Who gives the store and whether it grows; old debts if any.
func _build_head(forecast:Dictionary,season:Dictionary)->void:
	_clear(head_box)
	if store_kicker!=null:store_kicker.text=Purse.account_name().to_upper()
	var trend:=_trend(float(forecast.net),float(forecast.seasons_left))
	var rations:=Purse.buys_rations()
	var row:=S.row(head_box,{"id":"store","icon":"Stored food" if Purse.in_kind() else "Coin","label":"Holds","note":_given_words(),"value":Purse.amount_text(float(forecast.balance)),"value_width":110.0,
		"tag":String(trend.text).capitalize() if String(trend.text) in ["growing","steady"] else "Shrinking","tag_color":T.GREEN if String(trend.text)=="growing" else (T.MUTED if String(trend.text)=="steady" else T.RED),
		"tip":"%s%s" % ["The realm's one account. Every town keeps its own stores; this is the god's to spend." if not Purse.in_kind() else "Goods the levy took from the households' spare. The god's to spend. Goods wear out slowly here, as they do in the homes.",("\nAt today's prices it would buy %s rations." % EraWords.grouped(roundi(rations))) if rations>=0.0 else ""]})
	(row.note as Label).name="Balance";(row.value as Label).name="StoreAnswer"
	# Whether it grows, said on the same row (its reckoning in the pointer).
	var verdict:=S.label(_trend_words(float(forecast.net),String(trend.text)).trim_suffix("."),12,trend.color);verdict.name="Verdict";verdict.tooltip_text=_season_words(forecast,season)
	verdict.size_flags_vertical=Control.SIZE_SHRINK_CENTER;verdict.mouse_filter=Control.MOUSE_FILTER_PASS
	verdict.clip_text=true;verdict.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;verdict.custom_minimum_size.x=1;verdict.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var line:=(row.panel as PanelContainer).get_child(0) as HBoxContainer
	line.add_child(verdict);line.move_child(verdict,(row.value as Label).get_index())
	if float(forecast.debt)>0.5:S.row(head_box,{"id":"debt","label":"Old debts","note":"repaid monthly","value":Purse.number(float(forecast.debt)),"value_color":T.RED_TEXT})

## Growing, steady, shrinking slowly, or running out: {text, color}.
static func _trend(net:float,seasons_left:float)->Dictionary:
	if net>0.01:return {"text":"growing","color":T.GREEN_TEXT}
	if net>=-0.01:return {"text":"steady","color":T.INK_MUTED}
	if seasons_left<0.0 or seasons_left>=SLOW_SEASONS:return {"text":"shrinking slowly","color":T.AMBER_TEXT}
	return {"text":"runs out in about %s %s" % [Purse.number(seasons_left),"season" if seasons_left<1.5 else "seasons"],"color":T.RED_TEXT}

## Who gives it: "Given by the households of Ashleyfire."
func _given_words()->String:
	var towns:=_town_count()
	if towns<=1:return "given by the households of %s" % String(WorldSimulation.state.settlement_name)
	return "given by the households of our %d towns" % towns

func _town_count()->int:
	return Purse.food_places().size()

## "Growing by about 260 a season."
static func _trend_words(net:float,trend:String)->String:
	if trend=="growing":return "Growing by about %s a season." % Purse.number(net)
	if trend=="steady":return "Steady: what comes in goes out."
	if trend=="shrinking slowly":return "Shrinking by about %s a season." % Purse.number(-net)
	return _cap(trend)+"."

## The season's reckoning, for the tooltip: what comes in and what goes out.
func _season_words(forecast:Dictionary,season:Dictionary)->String:
	var ins:PackedStringArray=["the levy %s" % Purse.number(float(forecast.levy))]
	if float(forecast.rich)>0.0:ins.append("the rich %s" % Purse.number(float(forecast.rich)))
	if float(forecast.get("charter",0.0))>0.0:ins.append("%s %s" % [Business.purse_name().to_lower(),Purse.number(float(forecast.charter))])
	var outs:PackedStringArray=[]
	for line:String in Purse.LINES:
		var entry:Dictionary=(forecast.lines as Dictionary).get(line,{})
		if bool(entry.get("on",false)) and float(entry.get("per_season",0.0))>=0.5:outs.append("%s %s" % [String(LINE_LABELS[line]).to_lower(),Purse.number(float(entry.per_season))])
	if float(forecast.get("rot",0.0))>=0.5:outs.append("wear %s" % Purse.number(float(forecast.rot)))
	return "A season at today's settings, in %s.\nIn: %s.\nOut: %s.\nLast season %s came in and %s went out." % [Purse.unit_word(),", ".join(ins),", ".join(outs) if not outs.is_empty() else "nothing",Purse.number(float(season.total_in)),Purse.number(float(season.total_out))]

## Only with several towns: who gives most, one row each.
func _build_sources(sources:Dictionary)->void:
	_clear(sources_box)
	var towns:Array=sources.towns
	sources_box.visible=towns.size()>1
	if not sources_box.visible:return
	var most:=0.0
	for t:Dictionary in towns:most=maxf(most,float(t.levy))
	for t:Dictionary in towns:
		S.row(sources_box,{"id":String(t.name),"icon":"shelter","icon_kind":"people","label":String(t.name),"note":"%s people" % EraWords.grouped(int(t.people)),"ratio":float(t.levy)/maxf(0.01,most),"bar_width":60.0,"value":"%s a season" % Purse.number(float(t.levy)),"value_width":110.0,
			"tip":"The levy on what %s people make; %s hidden by households." % [EraWords.grouped(int(t.people)),Purse.number(float(t.evaded))]})

## The levy: three choices on its row, what it brings and what it costs.
func _build_levy(current:String)->void:
	_clear(levy_box)
	var q:=Purse.quote(current)
	var trust:=roundi(float(q.trust))
	var buttons:Array=[]
	for level:String in Purse.LEVELS:
		var lq:=Purse.quote(level)
		buttons.append({"text":String(Purse.LEVEL_NAMES[level]),"chosen":level==current,"on_press":_choose_levy.bind(level),
			"tip":"%s: %s of %s.\nBrings about %s a season.\nAbout 1 in %d hide what they owe.\nTrust in you −%d, holding together −%d." % [String(Purse.LEVEL_NAMES[level]),String(lq.words),Purse.harvest_word(),Purse.amount_text(float(lq.per_season)),int(lq.hidden_one_in),roundi(float(lq.trust)),roundi(float(lq.cohesion))]})
	var row:=S.row(levy_box,{"id":"levy","icon":"Civilian Goods","label":"The levy","label_width":90.0,"note":"a season · "+("custom expects it" if trust<=0 else "trust −%d" % trust)+" · 1 in %d hide dues" % int(q.hidden_one_in),"value":Purse.number(float(q.per_season)),"value_width":64.0,"buttons":buttons,
		"tip":"%s of %s, at today's work, after what is hidden.\nA light levy is what custom expects. Heavier ones are resented: trust in you and how well the people hold together (−%d now) fall while it lasts, and more is hidden.\nOur hands reach %d in 100 of what is owed." % [_cap(String(q.words)),Purse.harvest_word(),roundi(float(q.cohesion)),roundi(float(q.reach)*100.0)]})
	(row.note as Label).name="LevyCost";(row.value as Label).name="LevyNow"
	var levels:=HBoxContainer.new();levels.name="Levels";levels.visible=false;levy_box.add_child(levels)
	for index in (row.buttons as Array).size():(row.buttons[index] as Button).name="Level_%s" % String(Purse.LEVELS[index])

func _choose_levy(level:String)->void:
	var result:=Purse.set_levy(level)
	var q:Dictionary=result.get("quote",{})
	var said:="The levy is %s: %s of %s." % [level,String(q.get("words","")),Purse.harvest_word()]
	_say(said)
	Tracker.setting_order("Set the levy to %s" % level,{"ok":true,"message":said},"purse",_keeper(),"economy:2")
	refresh(true)

## What the store pays for: one row a line, its cost and a switch on the row.
func _build_lines(forecast:Dictionary,purse:Dictionary)->void:
	_clear(lines_box)
	var title:=S.label("It pays for",12,T.INK_MUTED,true);title.name="PaysAnswer";lines_box.add_child(title)
	for line:String in Purse.LINES:
		# Food is bought for a hungry town from another of ours: never with one town.
		if line=="relief" and _town_count()<=1 and not Purse.line_on("relief"):continue
		_line_row(line,forecast,purse)
	var army:Dictionary=purse.get("last_army",{}) if purse.get("last_army") is Dictionary else {}
	if int(purse.get("unpaid_months",0))>0:
		var warn:=S.row(lines_box,{"id":"unpaid","label":"Soldiers unpaid","note":"will −%d, %d went home" % [roundi(float(army.get("will_lost",0.0))*100.0),int(army.get("deserted",0))],"value":"%d %s" % [int(purse.unpaid_months),"month" if int(purse.unpaid_months)==1 else "months"],"value_color":T.RED_TEXT,"tag":"Unpaid","tag_color":T.RED})
		(warn.panel as Control).name="Unpaid"

const LINE_ICONS:={"army":["watch","people"],"scholars":["learn","people"],"crews":["build","people"],"relief":["Food","resource"]}

func _line_row(line:String,forecast:Dictionary,purse:Dictionary)->void:
	var entry:Dictionary=(forecast.lines as Dictionary).get(line,{})
	var on:=bool(entry.get("on",false))
	var spec:Array=LINE_ICONS.get(line,["stores","people"])
	var buttons:Array=[]
	if line=="relief":buttons.append({"text":"Send now","on_press":_buy_now,"tip":"Send up to a quarter of %s to hungry towns today." % Purse.account_name()})
	var refs:=S.row(lines_box,{"id":line,"icon":String(spec[0]),"icon_kind":String(spec[1]),"label":String(Purse.LINE_NAMES[line]),"label_color":T.INK if on else T.INK_MUTED,"note":_effect_words(line,on,entry,purse),
		"value":"%s a season" % Purse.amount_text(float(entry.get("per_season",0.0))) if line!="relief" else "","value_color":T.INK if on else T.INK_MUTED,"value_width":96.0,"buttons":buttons,"tip":_effect_tip(line)})
	(refs.panel as Control).name="Line_%s" % line
	(refs.note as Label).name="Effect";(refs.value as Label).name="Cost"
	var toggle:=Switch.new();toggle.name="Toggle"
	toggle.set_pressed_no_signal(on)
	toggle.tooltip_text="%s: %s." % [String(Purse.LINE_NAMES[line]),"switch it off" if on else "switch it on"]
	toggle.pressed.connect(func()->void:_toggle(line,not on))
	((refs.panel as PanelContainer).get_child(0) as HBoxContainer).add_child(toggle)

## What a line does now, in the engine's numbers, in a few words.
func _effect_words(line:String,on:bool,entry:Dictionary,purse:Dictionary)->String:
	match line:
		"army":
			if on and int(purse.get("unpaid_months",0))==0:return "%s · their will holds" % String(entry.get("who",""))
			return "unpaid: their will falls, some go home"
		"scholars":return "%s · research %d%% faster" % [String(entry.get("who","")),roundi(Purse.SCHOLARS_MAX*100.0)]
		"crews":return "%s · building %d%% faster" % [String(entry.get("who","")),roundi(Purse.CREWS_MAX*100.0)]
		"relief":
			var hungry:=Purse.food_places().filter(func(p:Dictionary)->bool:return float(p.days)<Purse.HUNGRY_DAYS).size()
			if hungry==0:return "no town is hungry"
			return "%d hungry %s" % [hungry,"town" if hungry==1 else "towns"]
	return ""

func _effect_tip(line:String)->String:
	match line:
		"army":return "Pay on top of rations, in %s. Unpaid soldiers lose will each month (−%d at most), are slower to muster, and 1 in 50 go home; more after three months." % [Purse.pay_word(),roundi(100.0*0.06)]
		"scholars":return "A keep for those at research, a seventh of a day's work each. While it is paid, research goes %d%% faster: a 100-day discovery takes %d days." % [roundi(Purse.SCHOLARS_MAX*100.0),roundi(100.0/(1.0+Purse.SCHOLARS_MAX))]
		"crews":return "Wages for those at building, a seventh of a day's work each. While they are paid, building goes %d%% faster: a 100-day work takes %d days." % [roundi(Purse.CREWS_MAX*100.0),roundi(100.0/(1.0+Purse.CREWS_MAX))]
		"relief":
			return "Each month, up to a quarter of %s buys food for towns under %d days of it, from our towns with more than %d days, at their own price. The goods (or coin) go to the sellers." % [Purse.account_name(),int(Purse.HUNGRY_DAYS),int(Purse.SELLER_DAYS)]
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

# --- What our goods buy ------------------------------------------------------------------

## What all the goods held are worth and would buy at our own prices
## (trade_prices.gd), one row each; coin and weighed metal once known.
func _build_own(held:Dictionary,_spare:float)->void:
	_clear(own_box)
	var goods:=float(held.goods)
	var buys:=Goods.buys(goods,["Timber","Stone","Fiber Plants"])
	var head:=S.label("All goods would buy",13,T.INK);head.name="GoodsBuy"
	head.tooltip_text="All %s goods would buy %s timber, %s stone OR %s fibre at our own prices. These are alternatives, not additional holdings." % [EraWords.grouped(roundi(goods)),EraWords.grouped(roundi(float(buys.Timber))),EraWords.grouped(roundi(float(buys.Stone))),EraWords.grouped(roundi(float(buys["Fiber Plants"])))]
	var row:=HFlowContainer.new();row.name="GoodsEquivalents";row.add_theme_constant_override("h_separation",8);row.add_theme_constant_override("v_separation",2);row.custom_minimum_size.y=S.ROW_HEIGHT;own_box.add_child(row)
	head.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(head)
	for index in 3:
		var spec:Array=[["Timber","timber"],["Stone","stone"],["Fiber Plants","fibre"]][index]
		if index>0:
			var either:=S.label("or",12,T.INK_MUTED);either.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(either)
		row.add_child(S.icon(String(spec[0]),18))
		var said:=S.label("%s %s" % [S.n(float(buys[spec[0]])),String(spec[1])],14,T.INK,true);said.size_flags_vertical=Control.SIZE_SHRINK_CENTER;said.tooltip_text=head.tooltip_text;row.add_child(said)
	var people:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var a_head:=S.label("",1,T.INK_MUTED);a_head.name="GoodsAHead";a_head.visible=false;a_head.text="%s a head" % S.n(goods/people);own_box.add_child(a_head)
	if float(held.coin)>=0.5:
		var coin:=S.row(own_box,{"id":"coin","icon":"Coin","label":"Coin held","note":"in %s" % String(held.coin_word),"value":"worth %s goods" % S.n(float(held.worth)-goods),"value_width":130.0,"tip":"What households, their hoards and the treasury hold, at our own prices."})
		(coin.panel as Control).name="CoinHeld"

static func _year()->float:
	return maxf(0.0,float(WorldSimulation.state.elapsed_days)/365.0)

## A button that opens another screen (the dock's provider).
func _go(node_name:String,text:String,tip:String,section:String,sub:int)->Button:
	var go:=S.verb(text,func()->void:if on_open.is_valid():on_open.call(section,sub),tip)
	go.name=node_name
	go.disabled=not on_open.is_valid()
	return go

# --- Business -------------------------------------------------------------------------

## How goods change hands at home; the rung of business and what it does;
## what the next rung needs; the stance as choices on a row (behind one
## button while business does hardly anything). The engine's numbers
## (enterprise.gd).
func _build_business()->void:
	_clear(business_box)
	var stage:=String(WorldSimulation.state.economy_stage)
	var barter:=Control.new();barter.name="Barter";barter.visible=false;barter.tooltip_text="Goods change hands at home %s." % ("by barter, for food and materials" if stage=="subsistence" else ("with weighed metal beside barter" if stage=="weighed_metal" else "for coin"));business_box.add_child(barter)
	var panel:=VBoxContainer.new();panel.name="Business";panel.add_theme_constant_override("separation",0);business_box.add_child(panel)
	var r:=Business.rung()
	var x:=Business.effects()
	var work:=float(x.work)
	var matters:=work>=BUSINESS_MATTERS or Business.booming() or Business.bust_left()>0
	var ladder:PackedStringArray=[]
	for index in Business.RUNGS.size():ladder.append(("› " if index==r else "   ")+Business.rung_name(index))
	var effect_word:="" if r<1 else ("hardly any effect yet" if not matters else "all work %s" % Business.percent(work))
	var where:=S.row(panel,{"id":"rung","icon":"make","icon_kind":"people","label":Business.rung_name(r),"note":effect_word,"value":"","value_width":4.0,"tip":"The steps of business, ours marked:\n"+"\n".join(ladder)})
	(where.label as Label).name="RungNow"
	if r>=1:(where.note as Label).text=effect_word
	var needs:=Business.next_needs(true)
	if needs!="":
		var next:=S.row(panel,{"id":"next","label":"Next: %s" % String((Business.RUNGS[r+1] as Dictionary).short).to_lower(),"note":"needs %s" % needs,"value":"","value_width":4.0,"tip":"%s needs %s." % [Business.rung_name(r+1),Business.next_needs()]})
		(next.panel as Control).name="NextRung"
	if r<1:return
	var e:=Business.state()
	var share:=Business.share()
	var goal:=float(e.get("target",Business.target()))
	var held:=S.row(panel,{"id":"share","label":"Holds workers","note":"heading for %s" % Business.in_100(goal),"ratio":clampf(share/maxf(0.0001,goal),0.0,1.0),"bar_width":60.0,"value":Business.in_100(share),"value_width":90.0,
		"tip":"Growing takes decades; failures are fast. This rung can hold up to %s of the workers." % Business.in_100(float((Business.RUNGS[r] as Dictionary).cap))})
	(held.panel as Control).name="ShareWords"
	var effect:=S.row(panel,{"id":"effect","label":"Effect","note":"%s to all work and goods" % Business.percent(work),"note_color":T.GREEN_TEXT if matters else T.INK_MUTED,"value":"reach +%d" % roundi(float(x.trade)*100.0),"value_width":90.0,
		"tip":"What business does now, at its size today: all work (harvests, within what the land yields; building, digging, hauling and learning) and the goods made go this much faster, trade reaches this much further, and the richest fifth settle %d parts in 100 higher." % roundi(float(x.rich)*100.0)})
	(effect.note as Label).name="BusinessEffect"
	var left:=Business.bust_left()
	if left>0:
		var bust:=S.row(panel,{"id":"bust","label":"A bust","note":"all work %s, easing" % Business.percent(-Business.BUST_HIT*float(left)/maxf(1.0,float((e.get("bust",{}) as Dictionary).get("months",1)))),"value":"%d %s" % [left,"month" if left==1 else "months"],"value_color":T.RED_TEXT,"value_width":90.0,"tag":"Bust","tag_color":T.RED})
		(bust.panel as Control).name="BustNow"
	elif Business.booming():
		var boom:=S.row(panel,{"id":"boom","label":"Booming on credit","note":"work +%d%%, bust odds up %d%%" % [roundi(Business.BOOM_GAIN*100.0),roundi(float(e.get("boom_months",0))/Business.BOOM_ODDS_MONTHS*100.0)],"value":"%d %s" % [int(e.get("boom_months",0)),"month" if int(e.get("boom_months",0))==1 else "months"],"value_width":90.0,"tag":"Boom","tag_color":T.GOLD})
		(boom.panel as Control).name="BoomNow"
	# The stance: one at a time, set like the levy.
	var current:=Business.stance()
	var shown:=matters or stances_open
	var stance_row:=HBoxContainer.new();stance_row.add_theme_constant_override("separation",6);stance_row.custom_minimum_size.y=S.ROW_HEIGHT;panel.add_child(stance_row)
	var stance_label:=S.label("Stance",14,T.INK);stance_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;stance_row.add_child(stance_label)
	var toggle:=S.verb(("%s · hide" if shown else "%s · change") % Business.stance_name(current),func()->void:stances_open=not shown;refresh(true),"How the god treats business: guarded, chartered or open. It matters little while business is this small.")
	toggle.name="StanceToggle";toggle.visible=not matters;stance_row.add_child(toggle)
	var choice:=VBoxContainer.new();choice.name="StanceChoice";choice.add_theme_constant_override("separation",2);choice.visible=shown;choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stance_row.add_child(choice)
	var pick:=HFlowContainer.new();pick.name="Stances";pick.add_theme_constant_override("h_separation",4);pick.add_theme_constant_override("v_separation",4);choice.add_child(pick)
	for id:String in Business.choices():
		var q:=Business.quote(id)
		var fee:=("\n%s: about %s a season at today's size, %s once grown." % [String(q.purse_name),Purse.amount_text(float(q.purse_now)),Purse.number(float(q.purse_season))]) if float(q.purse_season)>=0.5 else ""
		var button:=S.verb("%s · %s · %s" % [Business.stance_name(id),Business.percent(float(q.work)),_short_odds(float(q.bust_year))],_choose_stance.bind(id),
			"%s: %s.\nGrows toward %s of the workers.\nAll work and goods %s, trade reach +%d.\nThe richest fifth +%d parts in 100.\nBusts: %s.%s\nChanging costs %d points of trust." % [Business.stance_name(id),String(q.words).to_lower(),Business.in_100(float(q.target)),Business.percent(float(q.work)),roundi(float(q.trade)*100.0),roundi(float(q.rich)*100.0),String(q.odds).to_lower(),fee,roundi(Business.CHANGE_TRUST*100.0)],id==current)
		button.name="Stance_%s" % id;button.toggle_mode=true;button.set_pressed_no_signal(id==current)
		pick.add_child(button)
	var q:=Business.quote(current)
	var odds:=S.label("busts %s" % String(Business.odds_words(Business.bust_year())).to_lower(),12,T.INK_MUTED);odds.name="BustOdds"
	odds.tooltip_text=String(q.words)+".\nA bust cuts business by a third at once, slows all work 4% for 6 to 12 months, writes off debts, and costs the rich and the people's unity. Honest books (double-entry ledgers, audited accounts, a central bank) make busts rarer."
	choice.add_child(odds)

## "bust 1 in 40 yrs" for a stance button.
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

## Each fifth of households, poorest to richest, as a row with its bar; then
## what want and shares take from trust.
func _build_wealth()->void:
	_clear(wealth_box)
	var shares:Array=WorldSimulation.state.wealth_shares
	if shares.size()!=5:shares=[0.08,0.13,0.19,0.25,0.35]
	var fifths:=FifthsBar.new();fifths.name="Fifths";fifths.values=shares.duplicate();fifths.custom_minimum_size=Vector2(0,22)
	fifths.tooltip_text="Each fifth of our households, poorest to richest, and its part of all we have."
	var top:=roundi(float(shares[4])*100.0)
	var said:=S.label("Richest fifth %d in 100 · poorest %d" % [top,roundi(float(shares[0])*100.0)],14,T.INK,true);said.name="Shares"
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);head.custom_minimum_size.y=S.ROW_HEIGHT;wealth_box.add_child(head)
	said.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(said)
	fifths.size_flags_horizontal=Control.SIZE_EXPAND_FILL;fifths.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(fifths)
	var bounds:Array=preload("res://scripts/economy_system.gd").WEALTH_BOUNDS.get(String(WorldSimulation.state.economy_stage),[0.28,0.55,0.38])
	var parts:Dictionary=WorldSimulation.state.economy_metrics.get("social_pressure_parts",{}) if WorldSimulation.state.economy_metrics.get("social_pressure_parts") is Dictionary else {}
	var causes:PackedStringArray=[]
	var total:=0.0
	for pair:Array in [["unequal","shares"],["want","want"],["prices","prices"],["levy","levy"]]:
		var points:=float(parts.get(String(pair[0]),0.0))*100.0
		total+=points
		if points>=0.5:causes.append("%s −%d" % [String(pair[1]),roundi(points)])
	var pressure:=S.row(wealth_box,{"id":"pressure","icon":"spirit","icon_kind":"people","label":"Pressure on trust","note":", ".join(causes) if not causes.is_empty() else "none from want or shares","value":"−%d" % roundi(total) if total>=0.5 else "0","value_color":T.RED_TEXT if total>=0.5 else T.INK_MUTED,
		"tip":"Points a day's reckoning takes from trust in you; holding together loses about half as much.\nIn this age the richest fifth's part settles near %d in 100 and cannot pass %d. Sharing out, feasts and the purse's pay pull it down; want, rising prices and failed debts push it up." % [roundi(float(bounds[2])*100.0),roundi(float(bounds[1])*100.0)]})
	(pressure.panel as Control).name="Pressure"

# --- Pieces ---------------------------------------------------------------------------------

func _keeper()->String:
	var gov=WorldSimulation.government
	if gov==null:return ""
	var holder:Dictionary=gov.officeholder("Treasurer")
	if holder.is_empty():holder=gov.officeholder("Steward")
	return String(holder.get("name",""))

func _say(text:String)->void:
	feedback.text=text
	feedback.visible=text!=""

func _grid(parent:Node,node_name:String,count:int,threshold:float)->GridContainer:
	var grid:=GridContainer.new();grid.name=node_name;grid.columns=1;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",12)
	grid.set_meta("wide_columns",count);grid.set_meta("wide_threshold",threshold);parent.add_child(grid)
	responsive_grids=responsive_grids.filter(func(kept:GridContainer)->bool:return is_instance_valid(kept) and not kept.is_queued_for_deletion())
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
	# Five figures across a wide page; three, then two, as it narrows.
	var strip:=get_node_or_null("WealthKpis") as GridContainer
	if strip!=null:
		var across:=5 if available>=600 else (3 if available>=420 else 2)
		if strip.columns!=across:strip.columns=across

func _clear(box:Node)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=S.label(text,size,color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

## The five fifths of households as one bar, poorest left, each its share.
class FifthsBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var values:Array=[]
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var total:=0.0
		for v in values:total+=maxf(0.0,float(v))
		if total<=0.0:return
		var x:=0.0
		var inks:=[Color(T.GOLD,0.30),Color(T.GOLD,0.45),Color(T.GOLD,0.60),Color(T.GOLD,0.78),T.GOLD]
		var face:=T.font("ui")
		for i in values.size():
			var w:=size.x*maxf(0.0,float(values[i]))/total
			draw_rect(Rect2(x,0,maxf(1.0,w-1.0),size.y),inks[mini(i,4)])
			var words:="%d" % roundi(float(values[i])*100.0)
			draw_string(face,Vector2(x+4,size.y-6),words,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK if i<3 else T.PAPER_RAISED)
			x+=w

## A small switch, gold when on (a spending line's).
class Switch extends Button:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	func _init()->void:
		toggle_mode=true;flat=true;focus_mode=Control.FOCUS_NONE
		custom_minimum_size=Vector2(46,24);size_flags_vertical=Control.SIZE_SHRINK_CENTER
		mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	func _draw()->void:
		var on:=button_pressed
		var track:=Rect2((size.x-38.0)/2.0,(size.y-20.0)/2.0,38.0,20.0)
		var style:=StyleBoxFlat.new();style.set_corner_radius_all(10);style.set_border_width_all(1)
		style.bg_color=T.GOLD if on else T.PAPER_SUNK;style.border_color=T.GOLD if on else T.RULE_STRONG
		draw_style_box(style,track)
		var knob:=Vector2(track.end.x-10.0 if on else track.position.x+10.0,track.get_center().y)
		draw_circle(knob,7.0,T.PAPER_RAISED)
		draw_arc(knob,7.0,0.0,TAU,24,T.RULE_STRONG,1.0,true)
