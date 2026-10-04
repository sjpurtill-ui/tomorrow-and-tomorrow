extends VBoxContainer
## THE TRADE PAGE: trade with every people we know, one row each, as the War
## screen keeps one row per enemy. Each row shows, from the trade ledger's
## own numbers (trade_ledger.gd, trade_words.gd):
##   what flows each way a season (or a month, once silver or coin pays), with
##   each good's mark and a bar of its worth each way;
##   how much they lean on us and we on them: the share of a good's supply
##   that comes from the other, and how long the stores last without it;
##   their stance toward us, and tribute either way;
##   our stance toward them (the buttons: Trade freely, Favour, Toll,
##   Embargo, Squeeze, Demand tribute, Send gifts), each with its effect and
##   their odds in the engine's numbers on the pointer;
##   their answer: the odds while word travels, then the answer itself;
##   what our goods buy from them (the "Buy with goods" menu): arms, what they
##   have to spare, families who come to work, our own taken captive, each
##   at its stated terms (trade_ledger.gd deal_terms, goods_deal).
## A stance is the god's word, the same as at court (court_trade.gd): the
## Messenger (the Headman while there is none) carries it, and it gets a card
## at the bottom right. Below, the trade between other peoples we know of.
## Every label is MAX_WORDS words or fewer. Observe and choose: nothing here
## moves goods by hand.

signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const Words:=preload("res://scripts/trade_words.gd")
const CourtTrade:=preload("res://scripts/court_trade.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Arms:=preload("res://scripts/weapons_stock.gd")
const REFRESH_SECONDS:=1.0
const MAX_WORDS:=12
const HOVER_HOLD_SECONDS:=5.0
## The stance buttons, in order.
const STANCE_ORDER:=["free","favour","toll","embargo","squeeze","tribute","gifts"]

var summary_box:VBoxContainer
var peoples_box:VBoxContainer
var others_box:VBoxContainer
var feedback:Label
var clock:=0.0
var signature:=""
var waited:=0.0
var built_msec:=-100000
const REBUILD_MS:=2000


func setup(_block:Dictionary={})->void:
	name="TradeBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",14)
	summary_box=_section("Our trade")
	feedback=_line("",15,T.GOLD_TEXT,true);feedback.name="Said";feedback.visible=false;add_child(feedback)
	peoples_box=_section("Peoples we know")
	others_box=_section("Between other peoples")
	refresh(true)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## What the page shows has changed: a settlement, a stance, an answer, a day.
static func reading_signature()->String:
	var s:=Ledger.peek()
	if s.is_empty():return "empty:%d" % int(GameState.elapsed_days/30)
	var parts:=PackedStringArray()
	for k:String in (s.get("pairs",{}) as Dictionary):
		var p:Dictionary=s.pairs[k]
		parts.append("%s:%d:%s" % [k,int(p.get("last_day",-1)),String(p.get("form",""))])
	parts.append(str(s.get("stances",{})))
	parts.append(str((s.get("answers",{}) as Dictionary).keys()))
	parts.append(str(s.get("tributes",{})))
	parts.append(str((s.get("news",[]) as Array).size()))
	parts.append(str(int(GameState.elapsed_days)/7))
	return str(hash("|".join(parts)))


func refresh(force:=false)->void:
	var next:=reading_signature()
	if not force and next==signature:return
	# At the fastest pace the ledger moves every day: the page is read again at
	# most every REBUILD_MS, so the odds on its buttons cost little.
	if not force and Time.get_ticks_msec()-built_msec<REBUILD_MS:return
	if not force and _in_use(waited):
		waited+=REFRESH_SECONDS
		return
	waited=0.0
	built_msec=Time.get_ticks_msec()
	signature=next
	_build_summary()
	_build_peoples()
	_build_others()


func _in_use(waited_seconds:float)->bool:
	if not is_visible_in_tree():return false
	for node in find_children("*","",true,false):
		if node is MenuButton and (node as MenuButton).get_popup().visible:return true
	if not get_global_rect().has_point(get_global_mouse_position()):return false
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or waited_seconds<HOVER_HOLD_SECONDS


# --- Our trade at a glance ----------------------------------------------------

func _build_summary()->void:
	_clear(summary_box)
	var panel:=_panel(summary_box,"Summary")
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	var partners:=Ledger.partners("player").filter(func(row:Dictionary)->bool:return float(row.value)>=Ledger.PARTNER_FLOOR)
	var sent:=0.0;var came:=0.0
	for row:Dictionary in Ledger.partners("player"):
		sent+=Ledger.flow_value("player",String(row.id))
		came+=Ledger.flow_value(String(row.id),"player")
	# The answer first: whom we trade with and how much passes a season.
	var answer:=_line("No goods pass between us and any people yet" if partners.is_empty() else "%d trading %s: %s sent, %s brought in a season" % [partners.size(),"partner" if partners.size()==1 else "partners",EraWords.grouped(roundi(sent*3.0)),EraWords.grouped(roundi(came*3.0))],17,T.INK,true)
	answer.name="TradeAnswer";answer.add_theme_font_override("font",T.font("ui_strong"))
	answer.tooltip_text="Worth of goods, a season. Gifts and barter settle each season; silver and coin each month."
	column.add_child(answer)
	# What we can trade and pay with, on one small line.
	var means:PackedStringArray=["%s goods to trade" % EraWords.grouped(roundi(Goods.spare()))]
	var unit:=Ledger.purse_unit("player")
	# What we can pay other peoples with now (trade_ledger.pay moves no more).
	if unit!="":means.append("%s %s to pay with" % [EraWords.grouped(roundi(Ledger.purse_balance("player"))),unit])
	var tribute_in:=0.0
	for c:Dictionary in CivilizationSystem.civilizations:
		var t:=Stances.tribute(String(c.get("id","")),"player")
		if not t.is_empty():tribute_in+=float(t.value)
	if tribute_in>0.0:means.append("%s tribute a season" % EraWords.grouped(roundi(tribute_in)))
	var spare:=_line(" · ".join(means)+".",13,T.INK_MUTED,true);spare.name="GoodsToTrade"
	spare.tooltip_text="Goods beyond what the homes use: they buy what other peoples have to spare, arms, and families who come to work. Makers make about %s a day.\nArms beyond what the watch lacks can be traded too; they are counted on the Production screen, under Military." % str(snappedf(float((GameState.civilian_goods.get("report",{}) as Dictionary).get("made",0.0)),0.1))
	column.add_child(spare)


# --- One row per people ---------------------------------------------------------

func _build_peoples()->void:
	_clear(peoples_box)
	var rows:Array=[]
	for c:Dictionary in CivilizationSystem.civilizations:
		var id:=String(c.get("id",""))
		if id=="" or not bool(c.get("alive",true)):continue
		var contact:=int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))
		if contact<1:continue
		var value:=Ledger.flow_value("player",id)+Ledger.flow_value(id,"player")
		rows.append({"id":id,"contact":contact,"value":value,"name":String(c.get("name",id))})
	rows.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return int(x.contact)>int(y.contact) or (int(x.contact)==int(y.contact) and (float(x.value)>float(y.value) or (float(x.value)==float(y.value) and String(x.name)<String(y.name)))))
	if rows.is_empty():
		var calm:=_panel(peoples_box,"None")
		calm.add_child(_line("We have met no other people yet.",14,T.INK_MUTED,true))
		return
	for row:Dictionary in rows:peoples_box.add_child(_people_row(String(row.id),int(row.contact)))


func _people_row(civ_id:String,contact:int)->Control:
	var name:=Ledger.name_of(civ_id)
	var ours:=Stances.stance("player",civ_id)
	var theirs:=Stances.stance(civ_id,"player")
	var tone:=T.GREEN if Ledger.flow_value("player",civ_id)+Ledger.flow_value(civ_id,"player")>=Ledger.PARTNER_FLOOR else T.RULE
	if String(ours.get("id","free")) in Stances.COERCIVE or String(theirs.get("id","free")) in Stances.COERCIVE:tone=T.AMBER
	if "embargo" in [String(ours.get("id","")),String(theirs.get("id",""))]:tone=T.RED
	var panel:=PanelContainer.new();panel.name="People_%s" % civ_id
	panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,tone,12,3))
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",12);column.add_child(head)
	var emblem:=TextureRect.new();emblem.texture=Identity.emblem(civ_id);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.custom_minimum_size=Vector2(36,36);head.add_child(emblem)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",0);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(words)
	var title:=Label.new();title.name="Name";title.text=name;T.text(title,"voice",T.INK);words.add_child(title)
	var p:=Ledger.pair("player",civ_id)
	var subtitle:="Known only by word: no trader reaches them" if contact<2 else (Words.form_words(String(p.get("form","gift"))) if not p.is_empty() else "Met; no goods have passed yet")
	if not p.is_empty() and Ledger.blocked("player",civ_id)!="":subtitle=_blocked_words(Ledger.blocked("player",civ_id))
	words.add_child(_line(subtitle,13,T.INK_MUTED))
	var bar:=FlowBar.new();bar.name="Flows";bar.out_value=Ledger.flow_value("player",civ_id);bar.in_value=Ledger.flow_value(civ_id,"player");bar.custom_minimum_size=Vector2(180,22)
	bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	bar.tooltip_text="Worth a month: we send %s, they send %s (each side's own prices)." % [EraWords.grouped(roundi(bar.out_value)),EraWords.grouped(roundi(bar.in_value))]
	head.add_child(bar)
	if contact<2:return panel
	column.add_child(_flows("We send",Words.flow_items("player",civ_id),String(p.get("form","gift"))))
	column.add_child(_flows("They send",Words.flow_items(civ_id,"player"),String(p.get("form","gift"))))
	for pair_:Array in [[civ_id,"player"],["player",civ_id]]:
		var lean:=Words.lean_label(String(pair_[0]),String(pair_[1]))
		if lean=="":continue
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);column.add_child(line)
		var l1:=_line(lean,13,T.INK);l1.name="Lean";line.add_child(l1)
		var lasts:=Words.lasts_label(String(pair_[0]),String(pair_[1]))
		if lasts!="":line.add_child(_line("· "+lasts,13,T.INK_MUTED))
		line.tooltip_text=Words.leaning_line(String(pair_[0]),String(pair_[1]))
	var theirs_words:=Words.theirs_label(civ_id)
	if theirs_words!="":
		var against:=_line(theirs_words,13,T.RED_TEXT if String(theirs.get("id","")) in Stances.COERCIVE else T.GREEN_TEXT);against.name="Theirs";column.add_child(against)
	var tribute:=Words.tribute_label(civ_id)
	if tribute!="":column.add_child(_line(tribute,13,T.GOLD_TEXT))
	var owed:=Words.owed_label(civ_id)
	if owed!="":
		var debt:=_line(owed,13,T.INK_MUTED);debt.name="Owed"
		debt.tooltip_text="Gifts not yet returned. A people that owes us gives way more readily: up to 1 in 10 on its answer."
		column.add_child(debt)
	column.add_child(_stance_buttons(civ_id,ours))
	var buy:=_buy_menu(civ_id)
	if buy!=null:column.add_child(buy)
	var odds_row:=_odds_row(civ_id,ours)
	if odds_row!=null:column.add_child(odds_row)
	var last:=Words.answer_label("player",civ_id)
	if last!="":
		var said:=_line(last,13,T.INK_MUTED);said.name="LastWord";said.tooltip_text=Words.answer_line("player",civ_id);column.add_child(said)
	return panel


func _blocked_words(why:String)->String:
	match why:
		"war":return "At war: no trader crosses"
		"feud":return "Feuding: no trader crosses"
		"hostile":return "They will not meet our traders"
	return "Embargoed: nothing passes" if why.begins_with("embargo") else why


## "We send ▸ [mark] 12 flint · [mark] 30 food · a season".
func _flows(lead:String,items:Array,form:String)->Control:
	var row:=HBoxContainer.new();row.name=lead.replace(" ","");row.add_theme_constant_override("separation",8)
	var label:=_line(lead,13,T.INK_MUTED);label.custom_minimum_size=Vector2(78,0);row.add_child(label)
	if items.is_empty():
		row.add_child(_line("nothing yet",13,T.INK_MUTED))
		return row
	for item:Array in items:
		var good:=String(item[0])
		var mark:=TextureRect.new();mark.texture=Icons.texture_for(good);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;mark.custom_minimum_size=Vector2(20,20)
		mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(mark)
		row.add_child(_line(Words.amount(float(item[1]),good),13,T.INK))
	row.add_child(_line(Words.period_word(form),13,T.INK_MUTED))
	return row


## The stance buttons: the one in force pressed; the pointer tells what each
## does and their odds.
func _stance_buttons(civ_id:String,ours:Dictionary)->Control:
	var row:=HFlowContainer.new();row.name="Stances";row.add_theme_constant_override("h_separation",6);row.add_theme_constant_override("v_separation",6)
	var chosen:=String(ours.get("id","free"))
	for id:String in STANCE_ORDER:
		if id=="squeeze":
			row.add_child(_squeeze_button(civ_id,chosen=="squeeze",String(ours.get("good",""))))
			continue
		var button:=Button.new();button.name="Stance_%s" % id;button.text=String(Words.LABELS[id]);button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE
		button.set_pressed_no_signal(chosen==id)
		button.tooltip_text=Words.tip(id,"player",civ_id)
		button.pressed.connect(func()->void:_choose(civ_id,id,""))
		row.add_child(button)
	return row


func _squeeze_button(civ_id:String,chosen:bool,good_now:String)->Control:
	var pick:=MenuButton.new();pick.name="Stance_squeeze";pick.flat=false;pick.focus_mode=Control.FOCUS_NONE
	pick.text=("Squeeze %s ▾" % Words.good_word(good_now)) if chosen and good_now!="" else "Squeeze ▾"
	if chosen:pick.add_theme_stylebox_override("normal",T.button_pressed_style())
	var goods:=_squeeze_goods(civ_id)
	var popup:=pick.get_popup()
	if goods.is_empty():
		pick.disabled=true;pick.tooltip_text="They lean on us for no good we could squeeze."
		return pick
	for i in goods.size():
		var row:Dictionary=goods[i]
		popup.add_item(_short("%s · %s" % [Words.good_word(String(row.good)),String(row.words)]),i)
		popup.set_item_tooltip(i,Words.tip("squeeze","player",civ_id,String(row.good)))
	pick.tooltip_text="Cut off a good they lean on, and buy it up from others."
	popup.id_pressed.connect(func(index:int)->void:_choose(civ_id,"squeeze",String((goods[index] as Dictionary).good)))
	return pick


## Goods to squeeze: those they lean on us for, then those they lack.
func _squeeze_goods(civ_id:String)->Array:
	var out:Array=[]
	for row:Dictionary in Ledger.reading(civ_id,"player"):
		if float(row.share)>=0.05:out.append({"good":String(row.good),"words":"%s from us" % Words.share_words(float(row.share))})
	var g:Dictionary=Ledger.report(civ_id).get("g",{})
	for good:String in Ledger.GOODS:
		if good=="Food" or out.any(func(r:Dictionary)->bool:return String(r.good)==good):continue
		if Ledger.want_of(g,good)>0.0 and float((g.get(good,{}) as Dictionary).get("d",0.0))>0.0:out.append({"good":good,"words":"they lack it"})
		if out.size()>=6:break
	return out


## What our goods can buy from them, each at its stated terms: arms for the
## watch, what they have to spare, families who come to work, our own taken
## captive. Choosing one carries it out (trade_ledger.gd goods_deal).
func _buy_menu(civ_id:String)->Control:
	# The terms are read once a day for each people (trade_ledger.gd deal_offers).
	var offers:=Ledger.deal_offers("player",civ_id)
	var pick:=MenuButton.new();pick.name="BuyWithGoods";pick.flat=false;pick.focus_mode=Control.FOCUS_NONE
	pick.text="Buy with goods ▾"
	if offers.is_empty():
		pick.disabled=true;pick.tooltip_text="They have nothing to spare for our goods."
		return pick
	var popup:=pick.get_popup()
	var terms:Array=offers
	for i in offers.size():
		var t:Dictionary=offers[i]
		var what:=String(t.what)
		if bool(t.ok):popup.add_item(_short(_cap(String(t.words))),i)
		else:
			popup.add_item(_short("%s · %s" % [_deal_name(what),String(t.why)]),i)
			popup.set_item_disabled(popup.get_item_count()-1,true)
		popup.set_item_tooltip(popup.get_item_count()-1,"%s goods a %s at their own prices. We have %s goods to spare." % [str(snappedf(float(t.each),0.1)),"head" if what in Ledger.PEOPLE else ("set" if what==Ledger.ARMS else "load"),str(roundi(float(t.spare)))])
	pick.tooltip_text="Our goods buy what they have to spare, at their prices."
	popup.id_pressed.connect(func(index:int)->void:_deal(civ_id,terms[index] as Dictionary))
	return pick


func _deal_name(what:String)->String:
	match what:
		"families":return "Families to work"
		"captives":return "Ransom our captives"
		Ledger.ARMS:return "Arms"
	return _cap(Words.good_word(what))


func _deal(civ_id:String,terms:Dictionary)->void:
	var done:=Ledger.goods_deal("player",civ_id,String(terms.what),float(terms.count))
	var said:=String(done.get("said",""))
	_say(said)
	Tracker.setting_order("Buy with goods: %s" % Ledger.name_of(civ_id),{"ok":bool(done.get("ok",false)),"message":said,"reason":said},"trade",String(CourtTrade.carrier().get("name","")),"economy:3")
	refresh(true)


## Their answer: the odds while word travels and after, as chips.
func _odds_row(civ_id:String,ours:Dictionary)->Control:
	var id:=String(ours.get("id","free"))
	if not id in Stances.COERCIVE:return null
	var row:=HFlowContainer.new();row.name="Odds";row.add_theme_constant_override("h_separation",6);row.add_theme_constant_override("v_separation",4)
	var waiting:=Words.waiting_label("player",civ_id)
	row.add_child(_line(waiting if waiting!="" else "Their answer",13,T.INK_MUTED))
	var o:=Stances.odds(id,"player",civ_id,String(ours.get("good","")),float(ours.get("amount",0.0)))
	for chip:Array in Words.odds_chips(o.p):
		var label:=_line("%s %s" % [String(chip[0]),String(chip[1])],13,T.INK)
		var holder:=PanelContainer.new();holder.add_theme_stylebox_override("panel",_skin(T.PAPER_SUNK,T.RULE,4,0));holder.add_child(label)
		holder.tooltip_text=_odds_tip(o.f)
		row.add_child(holder)
	return row


## What the odds are weighed on, in plain words with the numbers.
static func _odds_tip(f:Dictionary)->String:
	if f.is_empty():return ""
	var lines:=PackedStringArray()
	lines.append("They lean on us: %s of what they get." % Words.share_words(float(f.get("dep",0.0))))
	lines.append("Our strength against theirs: %.1f to 1." % float(f.get("ratio",1.0)))
	lines.append("Others who could supply them: %s." % Words.share_words(float(f.get("alt",0.0))))
	if float(f.get("obligation",0.0))>0.0: lines.append("What they owe us for our gifts: %s of a full debt." % Words.share_words(float(f.obligation)))
	lines.append("Their ruler: boldness %d in 10%s." % [roundi(float(f.get("assertive",0.5))*10.0),(", %s" % String(f.trait)) if String(f.get("trait",""))!="" else ""])
	return "\n".join(lines)


func _choose(civ_id:String,id:String,good:String)->void:
	var name:=Ledger.name_of(civ_id)
	var done:=CourtTrade.perform({"kind":"trade","act":id,"civ_id":civ_id,"people":name,"good":good,"amount":0,"page":true})
	_say(String(done.get("says","")))
	var words:="%s: %s" % [String(Words.LABELS.get(id,id)),name]
	Tracker.setting_order(words,{"ok":bool(done.get("ok",false)),"message":String(done.get("outcome","")),"reason":String(done.get("says",""))},"trade",String(CourtTrade.carrier().get("name","")),"economy:3")
	refresh(true)


# --- Trade between other peoples -------------------------------------------------

func _build_others()->void:
	_clear(others_box)
	var s:=Ledger.peek()
	var rows:Array=[]
	for p:Dictionary in (s.get("pairs",{}) as Dictionary).values():
		var a:=String(p.get("a",""));var b:=String(p.get("b",""))
		if a=="player" or b=="player" or not _met(a) or not _met(b):continue
		var value:=float((p.get("val",{}) as Dictionary).get("ab",0.0))+float((p.get("val",{}) as Dictionary).get("ba",0.0))
		var line:=""
		for side:Array in [[a,b],[b,a]]:
			var st:=Stances.stance(String(side[0]),String(side[1]))
			if String(st.get("id","free"))!="free":line=_short(_cap(Words.act_words(String(side[0]),String(st.id),String(side[1]),String(st.get("good","")))))
		if line=="" and value<Ledger.PARTNER_FLOOR:continue
		if line=="":line=_short("%s and %s · %s" % [Ledger.name_of(a),Ledger.name_of(b),Words.form_words(String(p.get("form","gift")))])
		rows.append({"line":line,"value":value})
	rows.sort_custom(func(x:Dictionary,y:Dictionary)->bool:return float(x.value)>float(y.value))
	if rows.is_empty():
		others_box.add_child(_line("We know of no trade between other peoples.",13,T.INK_MUTED,true))
		return
	for row:Dictionary in rows.slice(0,6):others_box.add_child(_line(String(row.line),13,T.INK))


func _met(id:String)->bool:
	var c:=Ledger.civ(id)
	return not c.is_empty() and int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2


# --- Pieces ---------------------------------------------------------------------

func _say(text:String)->void:
	feedback.text=text
	feedback.visible=text!=""


func _section(title:String)->VBoxContainer:
	var kicker:=_line(title.to_upper(),13,T.INK_MUTED);kicker.add_theme_font_override("font",T.font("ui_strong"));add_child(kicker)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);add_child(box)
	return box


func _panel(parent:Node,name_hint:String)->PanelContainer:
	var panel:=PanelContainer.new();panel.name=name_hint;panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,12,0));parent.add_child(panel)
	return panel


func _number(parent:Node,value:String,word:String)->Control:
	var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",6);chip.mouse_filter=Control.MOUSE_FILTER_PASS;parent.add_child(chip)
	var big:=_line(value,22,T.INK);big.add_theme_font_override("font",T.font("ui_strong"));chip.add_child(big)
	var small:=_line(word,13,T.INK_MUTED);small.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(small)
	return chip


func _clear(box:Node)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


static func _short(text:String)->String:
	var words:=text.split(" ",false)
	return text if words.size()<=MAX_WORDS else " ".join(words.slice(0,MAX_WORDS))


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


## Worth each way a month: our goods out (amber, left) against theirs in
## (teal, right), each against the larger.
class FlowBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var out_value:=0.0
	var in_value:=0.0
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var top:=maxf(0.001,maxf(out_value,in_value))
		var half:=size.x*0.5
		draw_rect(Rect2(Vector2(0,4),Vector2(size.x,size.y-8)),T.PAPER_SUNK)
		var w_out:=half*clampf(out_value/top,0.0,1.0)
		var w_in:=half*clampf(in_value/top,0.0,1.0)
		if w_out>0.0:draw_rect(Rect2(Vector2(half-w_out,4),Vector2(w_out,size.y-8)),T.AMBER)
		if w_in>0.0:draw_rect(Rect2(Vector2(half,4),Vector2(w_in,size.y-8)),T.TEAL)
		draw_line(Vector2(half,0),Vector2(half,size.y),T.INK,1.5)
		draw_rect(Rect2(Vector2(0,4),Vector2(size.x,size.y-8)),T.RULE,false,1.0)
