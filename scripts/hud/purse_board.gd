extends VBoxContainer
## THE REALM'S PURSE, at a glance (the Wealth tab, above the day's work): one
## account the god commands, read as the War screen reads the army
## (hud/war_board.gd). Every number is the engine's own (realm_purse.gd):
##   the purse   what it holds, what comes in and goes out a season, and what
##               it would buy; the season's money in and out as two bars;
##   the levy    light, usual or heavy, said plainly ("one part in twenty of
##               every harvest"), with what each brings in and costs;
##   its lines   the soldiers' pay, the scholars' keep, hired crews and food
##               for hungry towns: a switch each, its cost a season, its effect;
##   the wealth  who holds it by fifths, and the pressure it puts on trust.
## The words follow the age: the common store, silver, then coin.

signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const REFRESH_SECONDS:=1.0
const LINE_LABELS:={"army":"Soldiers","scholars":"Scholars","crews":"Crews","relief":"Food bought","debts":"Old debts","spent":"Gifts and buying"}

var head_box:VBoxContainer
var levy_box:VBoxContainer
var lines_box:VBoxContainer
var wealth_box:VBoxContainer
var ledger_box:VBoxContainer
var feedback:Label
var clock:=0.0
var signatures:={}


func setup(_block:Dictionary={})->void:
	name="PurseBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	head_box=_section(Purse.account_name())
	feedback=_line("",14,T.GOLD_TEXT,true);feedback.name="Said";feedback.visible=false;add_child(feedback)
	levy_box=_section("The levy")
	lines_box=_section("What it pays for")
	wealth_box=_section("Who holds the wealth")
	ledger_box=_section("Lately")
	refresh(true)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## The dock's own refresh (dock_panel.gd, each day the page is open): the
## board keeps its nodes and reads the purse again, as a fresh page would.
func update_block(_block:Dictionary)->bool:
	clock=0.0
	refresh()
	return true


## Each section is drawn again only when what it shows has changed and no
## button of it is held.
func refresh(force:=false)->void:
	var forecast:=Purse.forecast()
	var purse:=Purse.state()
	var season:=Purse.season()
	_rebuild("head",head_box,str([roundi(float(purse.balance)),roundi(float(forecast["in"])),roundi(float(forecast.out)),Purse.unit_word(),roundi(Purse.buys_rations()),season.total_in,season.total_out]),force,func()->void:_build_head(forecast,season))
	_rebuild("levy",levy_box,str([String(purse.levy),Purse.unit_word(),roundi(float(forecast.levy)),snappedf(float((forecast.quote as Dictionary).evasion),0.01)]),force,func()->void:_build_levy(String(purse.levy)))
	_rebuild("lines",lines_box,str([purse.lines,int(purse.unpaid_months),purse.last_army,forecast.lines,Purse.market_open()]),force,func()->void:_build_lines(forecast,purse))
	var parts:Variant=WorldSimulation.state.economy_metrics.get("social_pressure_parts",{})
	_rebuild("wealth",wealth_box,str([WorldSimulation.state.wealth_shares,parts,String(WorldSimulation.state.economy_stage)]),force,func()->void:_build_wealth())
	_rebuild("ledger",ledger_box,str((purse.ledger as Array).slice(0,5)),force,func()->void:_build_ledger(purse))


func _rebuild(key:String,box:Control,next:String,force:bool,build:Callable)->void:
	if not force and next==String(signatures.get(key,"")):return
	if not force and box.is_visible_in_tree() and box.get_global_rect().has_point(box.get_global_mouse_position()) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):return
	signatures[key]=next
	build.call()


# --- The purse --------------------------------------------------------------------

func _build_head(forecast:Dictionary,season:Dictionary)->void:
	_clear(head_box)
	# The account's own name heads it, by the age: the common store, silver, the treasury.
	var kicker:=get_child(head_box.get_index()-1) as Label
	if kicker!=null:kicker.text=Purse.account_name().to_upper()
	var panel:=_panel(head_box,"Purse")
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	panel.tooltip_text="The realm's one account. Every town keeps its own stores; this is the god's to spend."
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",22);column.add_child(head)
	var held:=_number(head,Purse.number(Purse.balance()),Purse.unit_word());held.name="Balance"
	held.tooltip_text="What %s holds now, in %s." % [Purse.account_name(),Purse.unit_word()]
	var inn:=_number(head,"+"+Purse.number(float(forecast["in"])),"a season");inn.name="ComingIn"
	inn.tooltip_text="The levy at today's work, after what is hidden."
	var out:=_number(head,"−"+Purse.number(float(forecast.out)),"a season");out.name="GoingOut"
	out.tooltip_text="What the lines switched on cost a season at today's numbers."
	# What it buys: food at the market price, or before a market the seasons
	# of the soldiers' pay it holds.
	var rations:=Purse.buys_rations()
	var army:=float(((forecast.lines as Dictionary).get("army",{}) as Dictionary).get("per_season",0.0))
	if rations>=0.0:
		var buys:=_number(head,EraWords.grouped(roundi(rations)),"rations it buys");buys.name="Buys"
		buys.tooltip_text="Food at today's market price, about %s a ration." % Purse.number(float(WorldSimulation.state.market_prices.get("Food",1.0)))
	elif army>0.5:
		var pays:=_number(head,Purse.number(Purse.balance()/army),"seasons of soldiers' pay");pays.name="Buys"
		pays.tooltip_text="How long it would pay the soldiers alone, at today's pay."
	# HOI4's budget: what comes in against what goes out, line by line.
	var bar:=BudgetBar.new();bar.name="Budget";bar.custom_minimum_size=Vector2(0,30)
	var ins:Array=[["Levy",float(forecast.levy),T.GREEN]]
	if float(forecast.rich)>0.0:ins.append(["The rich",float(forecast.rich),T.GREEN.darkened(0.2)])
	var outs:Array=[]
	for line:String in Purse.LINES:
		var entry:Dictionary=(forecast.lines as Dictionary).get(line,{})
		if bool(entry.get("on",false)) and float(entry.get("per_season",0.0))>0.0:outs.append([String(LINE_LABELS[line]),float(entry.per_season),_ink(line)])
	bar.ins=ins;bar.outs=outs
	bar.tooltip_text=_budget_words(ins,outs)
	column.add_child(bar)
	var net:=float(forecast.net)
	var verdict:="A season: %s in, %s out: %s %s." % [Purse.number(float(forecast["in"])),Purse.number(float(forecast.out)),Purse.number(absf(net)),"left over" if net>=0.0 else "short"]
	if net<-0.01 and float(forecast.seasons_left)>=0.0:verdict="A season: %s in, %s out: lasts about %s %s." % [Purse.number(float(forecast["in"])),Purse.number(float(forecast.out)),Purse.number(float(forecast.seasons_left)),"season" if float(forecast.seasons_left)<1.5 else "seasons"]
	var said:=_line(verdict,13,T.RED_TEXT if net<-0.01 else T.INK_MUTED,true);said.name="Verdict";column.add_child(said)
	var last:=_line("Last season: %s came in, %s went out." % [Purse.number(float(season.total_in)),Purse.number(float(season.total_out))],13,T.INK_MUTED,true);last.name="LastSeason"
	column.add_child(last)
	if float(forecast.debt)>0.5:column.add_child(_line("Old debts owed: %s, repaid from it monthly." % Purse.number(float(forecast.debt)),13,T.INK_MUTED,true))


func _budget_words(ins:Array,outs:Array)->String:
	var parts:PackedStringArray=[]
	for entry:Array in ins:parts.append("%s +%s" % [String(entry[0]),Purse.number(float(entry[1]))])
	for entry:Array in outs:parts.append("%s −%s" % [String(entry[0]),Purse.number(float(entry[1]))])
	return "A season, in %s: %s" % [Purse.unit_word(),", ".join(parts)]


# --- The levy -----------------------------------------------------------------------

func _build_levy(current:String)->void:
	_clear(levy_box)
	var panel:=_panel(levy_box,"Levy")
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var pick:=HBoxContainer.new();pick.name="Levels";pick.add_theme_constant_override("separation",8);column.add_child(pick)
	for level:String in Purse.LEVELS:
		var q:=Purse.quote(level)
		var button:=Button.new();button.name="Level_%s" % level;button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE
		button.text="%s\n%s" % [String(Purse.LEVEL_NAMES[level]),String(q.words)]
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.set_pressed_no_signal(level==current)
		button.tooltip_text="%s: %s of %s.\nBrings about %s a season.\nAbout 1 in %d hide what they owe.\nTrust in you −%d, holding together −%d." % [String(Purse.LEVEL_NAMES[level]),String(q.words),Purse.harvest_word(),Purse.amount_text(float(q.per_season)),int(q.hidden_one_in),roundi(float(q.trust)),roundi(float(q.cohesion))]
		button.pressed.connect(func()->void:_choose_levy(level))
		pick.add_child(button)
	var q:=Purse.quote(current)
	var line:=_line("%s of %s: %s a season." % [_cap(String(q.words)),Purse.harvest_word(),Purse.number(float(q.per_season))],14,T.INK,true);line.name="LevyNow"
	line.tooltip_text="In %s, at today's work, after what is hidden." % Purse.unit_word()
	column.add_child(line)
	var cost:=_line("1 in %d hide their dues · trust −%d, holding together −%d" % [int(q.hidden_one_in),roundi(float(q.trust)),roundi(float(q.cohesion))],13,T.INK_MUTED,true);cost.name="LevyCost"
	cost.tooltip_text="A light levy is what custom expects. Heavier ones are resented: trust in you and how well the people hold together fall while it lasts, and more is hidden."
	column.add_child(cost)
	var reach:=_line("Our hands reach %d in 100 of what is owed." % roundi(float(q.reach)*100.0),13,T.INK_MUTED,true);reach.name="Reach"
	reach.tooltip_text="Helpers and clerks, tallies and registers find what is owed. A few hundred people are counted face to face."
	column.add_child(reach)


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
	for line:String in Purse.LINES:lines_box.add_child(_line_row(line,forecast,purse))
	var army:Dictionary=purse.get("last_army",{}) if purse.get("last_army") is Dictionary else {}
	if int(purse.get("unpaid_months",0))>0:
		var warn:=_line("Soldiers unpaid %d %s: will −%d, %d went home." % [int(purse.unpaid_months),"month" if int(purse.unpaid_months)==1 else "months",roundi(float(army.get("will_lost",0.0))*100.0),int(army.get("deserted",0))],13,T.RED_TEXT,true)
		warn.name="Unpaid";lines_box.add_child(warn)


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
	if line=="relief" and Purse.market_open():
		var now:=Button.new();now.name="BuyNow";now.text="Buy now";now.focus_mode=Control.FOCUS_NONE;now.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		now.tooltip_text="Spend up to a quarter of %s on food for hungry towns today." % Purse.account_name()
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
			if not Purse.market_open():return "No market yet: nothing can be bought"
			var towns:=Purse.food_places()
			if towns.size()<2:return "One town only: no other town to buy from"
			var hungry:=towns.filter(func(p:Dictionary)->bool:return float(p.days)<Purse.HUNGRY_DAYS).size()
			return "%d hungry %s · food about %s a ration" % [hungry,"town" if hungry==1 else "towns",Purse.number(float(WorldSimulation.state.market_prices.get("Food",1.0)))]
	return ""

func _effect_tip(line:String)->String:
	match line:
		"army":return "Pay on top of rations: %s. Unpaid soldiers lose will each month, are slower to muster, and some go home; more after three months." % Purse.pay_word()
		"scholars":return "A keep for those at research, a seventh of a day's work each. While it is paid, research goes faster."
		"crews":return "Wages for those at building, a seventh of a day's work each. While they are paid, building goes faster."
		"relief":return "Each month, food is bought at the market price from towns with more than %d days of it, for towns under %d days." % [int(Purse.SELLER_DAYS),int(Purse.HUNGRY_DAYS)]
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
	var said:="Bought %s rations for %s." % [Purse.number(float(bought.rations)),Purse.amount_text(float(bought.spent))] if float(bought.spent)>0.0 else "Nothing bought: %s." % String(bought.reason)
	_say(said)
	Tracker.setting_order("Buy food for the hungry",{"ok":float(bought.spent)>0.0,"message":said,"reason":said},"purse",_keeper(),"economy:2")
	refresh(true)


# --- Who holds the wealth ----------------------------------------------------------------

func _build_wealth()->void:
	_clear(wealth_box)
	var panel:=_panel(wealth_box,"Wealth")
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	var shares:Array=WorldSimulation.state.wealth_shares
	if shares.size()!=5:shares=[0.08,0.13,0.19,0.25,0.35]
	var fifths:=FifthsBar.new();fifths.name="Fifths";fifths.shares=shares.duplicate();fifths.custom_minimum_size=Vector2(0,22)
	fifths.tooltip_text="Each fifth of our households, poorest to richest, and its part of all we have."
	column.add_child(fifths)
	var top:=roundi(float(shares[4])*100.0)
	var said:=_line("The richest fifth hold %d in 100; the poorest %d." % [top,roundi(float(shares[0])*100.0)],14,T.INK,true);said.name="Shares"
	column.add_child(said)
	var bounds:Array=preload("res://scripts/economy_system.gd").WEALTH_BOUNDS.get(String(WorldSimulation.state.economy_stage),[0.28,0.55,0.38])
	var usual:=_line("In this age it settles near %d; it cannot pass %d." % [roundi(float(bounds[2])*100.0),roundi(float(bounds[1])*100.0)],13,T.INK_MUTED,true);usual.name="Usual"
	usual.tooltip_text="Sharing out, feasts and the purse's pay pull it down; want, rising prices and failed debts push it up."
	column.add_child(usual)
	var parts:Dictionary=WorldSimulation.state.economy_metrics.get("social_pressure_parts",{}) if WorldSimulation.state.economy_metrics.get("social_pressure_parts") is Dictionary else {}
	var causes:PackedStringArray=[]
	for pair:Array in [["unequal","shares"],["want","want"],["prices","prices"],["levy","levy"]]:
		var points:=float(parts.get(String(pair[0]),0.0))*100.0
		if points>=0.5:causes.append("%s −%d" % [String(pair[1]),roundi(points)])
	var pressure:=_line(("Pressure on trust: "+", ".join(causes)+".") if not causes.is_empty() else "No pressure on trust from want or shares.",13,T.RED_TEXT if not causes.is_empty() else T.INK_MUTED,true)
	pressure.name="Pressure"
	pressure.tooltip_text="Points a day's reckoning takes from trust in you; holding together loses about half as much."
	column.add_child(pressure)


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
	var kicker:=_line(title.to_upper(),13,T.INK_MUTED);kicker.add_theme_font_override("font",T.font("ui_strong"));add_child(kicker)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);add_child(box)
	return box

func _panel(parent:Node,name_hint:String)->PanelContainer:
	var panel:=PanelContainer.new();panel.name=name_hint;panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,12,0,T.RULE));parent.add_child(panel)
	return panel

func _number(parent:Node,value:String,word:String)->Control:
	var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",6);chip.mouse_filter=Control.MOUSE_FILTER_PASS;parent.add_child(chip)
	var big:=_line(value,22,T.INK);big.add_theme_font_override("font",T.font("ui_strong"));chip.add_child(big)
	var small:=_line(word,13,T.INK_MUTED);small.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(small)
	return chip

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


## HOI4's budget: what comes in (top, greens) against what goes out (bottom,
## one colour a line), both on one scale; the shorter bar shows the gap.
class BudgetBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var ins:Array=[]
	var outs:Array=[]
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var total_in:=0.0
		for entry:Array in ins:total_in+=float(entry[1])
		var total_out:=0.0
		for entry:Array in outs:total_out+=float(entry[1])
		var scale:=maxf(0.001,maxf(total_in,total_out))
		var half:=floorf((size.y-4.0)/2.0)
		for pair:Array in [[ins,0.0],[outs,half+4.0]]:
			var y:=float(pair[1])
			draw_rect(Rect2(0.0,y,size.x,half),T.PAPER_SUNK)
			var x:=0.0
			for entry:Array in (pair[0] as Array):
				var width:=size.x*float(entry[1])/scale
				if width>0.5:draw_rect(Rect2(x,y,width,half),entry[2]);x+=width
			draw_rect(Rect2(0.0,y,size.x,half),T.RULE,false,1.0)


## The fifths of our households, poorest first, each its share of the wealth.
class FifthsBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var shares:Array=[]
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var inks:=[T.TEAL.lightened(0.35),T.TEAL.lightened(0.18),T.TEAL,T.GOLD.lightened(0.15),T.GOLD]
		var x:=0.0
		for index in mini(5,shares.size()):
			var width:=size.x*clampf(float(shares[index]),0.0,1.0)
			draw_rect(Rect2(x,0.0,width,size.y),inks[index])
			if index>0:draw_line(Vector2(x,0.0),Vector2(x,size.y),T.PAPER,1.0)
			x+=width
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE,false,1.0)
