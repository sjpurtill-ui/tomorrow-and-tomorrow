extends VBoxContainer
## THE TRADE PAGE: available goods and recent exchange lead, followed by one
## selected people: its mark, route status, recorded pace and our decisions.
## Terms opens its decisions and evidence inline, keeping the partner in
## view. Each reads the trade ledger's own
## numbers (trade_ledger.gd, trade_words.gd):
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
## Compact menu descriptions retain their full terms in the pointer. Every
## command calls the same ledger and court handlers as the other interfaces.

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
const Graphics:=preload("res://scripts/hud/trade_graphics.gd")
const Emblem:=preload("res://scripts/hud/hud_chrome_icon.gd")
const MaterialArt:=preload("res://scripts/hud/materials_art.gd")
const ProvisionsArt:=preload("res://scripts/hud/provisions_art.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
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
var summary_signature:=""
var others_signature:=""
var people_signatures:Dictionary={}
var responsive_grids:Array[GridContainer]=[]
var visual_sections:Array[Dictionary]=[]
var expanded_people:Dictionary={}
const PARTNER_PAGE_SIZE:=6
var selected_partner:=""
var partner_query:=""
var partner_page:=0
var browse_open:=false
var partner_workspace:BoxContainer
var browser:VBoxContainer
var partner_choices:VBoxContainer
var partner_search:LineEdit
var browser_close:Button
var partner_pager:HFlowContainer
var partner_previous:Button
var partner_next:Button
var partner_count:Label
var other_page:=0
var others_open:=false
var evidence_open:Dictionary={}

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


func setup(_block:Dictionary={})->void:
	name="TradeBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	theme=T.control_theme()
	add_theme_constant_override("separation",16)
	summary_box=VBoxContainer.new();summary_box.name="TradeHero";summary_box.add_theme_constant_override("separation",12);add_child(summary_box)
	feedback=S.label("",16,T.GOLD_TEXT);feedback.name="Said";feedback.visible=false;feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(feedback)
	partner_workspace=BoxContainer.new();partner_workspace.name="TradeWorkspace";partner_workspace.add_theme_constant_override("separation",24);add_child(partner_workspace)
	peoples_box=VBoxContainer.new();peoples_box.name="SelectedPartner";peoples_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;partner_workspace.add_child(peoples_box)
	_build_partner_browser()
	var others:=VBoxContainer.new();others.name="OtherTrade";others.add_theme_constant_override("separation",0);add_child(others)
	others_box=VBoxContainer.new();others_box.add_theme_constant_override("separation",0);others.add_child(others_box)
	resized.connect(_responsive)
	refresh(true)
	_responsive()

## Daily dock refresh keeps the board, its scroll position and open choices.
func update_block(_block:Dictionary)->bool:
	clock=0.0
	refresh()
	return true


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## What the page shows has changed: a settlement, a stance, an answer, a day.
static func reading_signature()->String:
	var s:=Ledger.peek()
	var peoples:Array=[]
	for c:Dictionary in CivilizationSystem.civilizations:
		peoples.append([c.get("id",""),c.get("name",""),c.get("alive",true),c.get("player_relation",{})])
	return str(hash([s.get("pairs",{}),s.get("stances",{}),s.get("answers",{}),s.get("tributes",{}),s.get("reports",{}),peoples,
		int(GameState.elapsed_days),Ledger.revision,Goods.spare(),Ledger.purse_unit("player"),Ledger.purse_balance("player"),T.color_mode]))


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
	theme=T.control_theme()
	feedback.add_theme_color_override("font_color",T.GOLD_TEXT)
	var kept_sections:Array[Dictionary]=[]
	for item:Dictionary in visual_sections:
		if not is_instance_valid(item.get("panel")):continue
		var panel:=item.panel as PanelContainer
		if not is_instance_valid(panel) or not panel.is_inside_tree():continue
		kept_sections.append(item)
		var skin:=_folio_rule(0)
		panel.add_theme_stylebox_override("panel",skin)
		(item.kicker as Label).add_theme_color_override("font_color",T.INK)
	visual_sections=kept_sections
	var peoples_kicker:=find_child("PeoplesHeading",true,false) as Label
	if peoples_kicker!=null:peoples_kicker.add_theme_color_override("font_color",T.INK_MUTED)
	var next_summary:=str(hash([_known_rows(),Goods.spare(),Ledger.purse_unit("player"),Ledger.purse_balance("player"),Ledger.peek().get("tributes",{}),T.color_mode]))
	if force or next_summary!=summary_signature:
		summary_signature=next_summary
		_build_summary()
	_build_peoples(force)
	var state:=Ledger.peek()
	var next_others:=str(hash([state.get("pairs",{}),state.get("stances",{}),_known_rows(),T.color_mode]))
	if force or next_others!=others_signature:
		others_signature=next_others
		_build_others()
	_responsive()


func _in_use(waited_seconds:float)->bool:
	if not is_visible_in_tree():return false
	for node in find_children("*","",true,false):
		if node is MenuButton and (node as MenuButton).get_popup().visible:return true
	var focused:=get_viewport().gui_get_focus_owner()
	if focused!=null and is_ancestor_of(focused) and Input.is_action_pressed("ui_accept"):return true
	if not get_global_rect().has_point(get_global_mouse_position()):return false
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or waited_seconds<HOVER_HOLD_SECONDS


# --- Our trade at a glance ----------------------------------------------------

## The strip's figures (the dock draws them under the tabs): goods to
## trade, what came in and went out a season, partners, tribute.
static func kpis()->Array:
	return S.dock_kpis(kpi_items(),{})

static func kpi_items()->Array:
	var partners:=0;var known:=0
	var sent:=0.0;var came:=0.0
	for row:Dictionary in known_rows():
		known+=1
		if int(row.contact)<2:continue
		sent+=Ledger.flow_value("player",String(row.id))
		came+=Ledger.flow_value(String(row.id),"player")
		if float(row.value)>=Ledger.PARTNER_FLOOR:partners+=1
	var tribute_in:=0.0;var tribute_out:=0.0
	for c:Dictionary in CivilizationSystem.civilizations:
		var t:=Stances.tribute(String(c.get("id","")),"player")
		if not t.is_empty():tribute_in+=float(t.value)
		var o:=Stances.tribute("player",String(c.get("id","")))
		if not o.is_empty():tribute_out+=float(o.value)
	var spare:=Goods.spare()
	var unit:=Ledger.purse_unit("player")
	var items:Array=[
		{"id":"spare","label":"Goods to trade","icon":"Civilian Goods","value":S.n(spare),"ratio":-1.0,"sub":("%s %s too" % [S.n(Ledger.purse_balance("player")),unit]) if unit!="" else "spare goods",
			"tip":"Goods beyond household use and workshop reserves, available to buy what other peoples can spare. This is the same balance used by Buy with goods."},
		{"id":"came","label":"In a season","icon":"carry","icon_kind":"people","value":S.n(came*3.0),"ratio":clampf(came/maxf(0.01,came+sent),0.0,1.0) if came+sent>0.0 else -1.0,"color":T.TEAL,"sub":"received, at their prices",
			"tip":"What other peoples sent us, smoothed monthly and reckoned for a season, at each sender's own prices. The bar: its share of all that passed."},
		{"id":"sent","label":"Out a season","icon":"carry","icon_kind":"people","value":S.n(sent*3.0),"ratio":clampf(sent/maxf(0.01,came+sent),0.0,1.0) if came+sent>0.0 else -1.0,"color":T.GOLD,"sub":"sent, at our prices",
			"tip":"What we sent other peoples, smoothed monthly and reckoned for a season, at our own prices. The bar: its share of all that passed."},
		{"id":"partners","label":"Partners","icon":"walker","icon_kind":"chart","value":"%d of %d" % [partners,known],"ratio":float(partners)/float(known) if known>0 else -1.0,"color":T.GREEN,
			"sub":"recent trade" if partners>0 else ("little trade" if sent+came>0.0 else "no trade yet"),"tip":"Peoples we know with whom goods passed recently, of all the peoples we know."},
	]
	if tribute_in>0.0 or tribute_out>0.0:
		items.append({"id":"tribute","label":"Tribute a season","icon":"Coin","value":S.signed(tribute_in-tribute_out),"ratio":-1.0,"sub":"%s in · %s out" % [S.n(tribute_in),S.n(tribute_out)],"tip":"Tribute paid to us and by us, worth a season."})
	return items

## A scrolling situation summary; the compatibility chart retains exact totals.
func _build_summary()->void:
	_clear(summary_box)
	var items:=kpi_items()
	var lead:=S.voice("%s goods available to trade" % String(items[0].value),24);lead.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;lead.tooltip_text=String(items[0].tip);summary_box.add_child(lead)
	var partners:Dictionary=items[3]
	var context:=S.label("Recent trade with %s peoples%s" % [String(partners.value)," · "+String(items[0].sub) if Ledger.purse_unit("player")!="" else ""],16,T.INK_MUTED);context.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;context.tooltip_text=String(partners.tip);summary_box.add_child(context)
	var pace:=S.label("A season's pace: worth %s received · %s sent" % [String(items[1].value),String(items[2].value)],14,T.INK_MUTED);pace.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;pace.tooltip_text=String(items[1].tip)+"\n"+String(items[2].tip);summary_box.add_child(pace)
	for item:Dictionary in items:
		if item.id!="tribute":continue
		var tribute:=S.label("Tribute %s a season · %s" % [String(item.value),String(item.sub)],14,T.INK_MUTED);tribute.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;tribute.tooltip_text=String(item.tip);summary_box.add_child(tribute)
	var sent:=0.0;var came:=0.0
	for row:Dictionary in _known_rows():
		if int(row.contact)<2:continue
		sent+=Ledger.flow_value("player",String(row.id))
		came+=Ledger.flow_value(String(row.id),"player")
	var chart:=Graphics.new();chart.name="FlowTotals";chart.compact=true;chart.values=[came*3.0,sent*3.0];summary_box.add_child(chart)
	# The prose says the season's in and out; the chart keeps the exact reading.
	chart.visible=false
	chart.tooltip_text="Smoothed monthly values expressed as a seasonal pace, at each sender's own prices. The bar is centered on equal exchange: left means more received, right means more sent. It compares recorded worth, not stock, coin or profit."


# --- One row per people ---------------------------------------------------------

func _known_rows()->Array:
	return known_rows()

static func known_rows()->Array:
	var rows:Array=[]
	for c:Dictionary in CivilizationSystem.civilizations:
		var id:=String(c.get("id",""))
		if id=="" or not bool(c.get("alive",true)):continue
		var contact:=int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))
		if contact<1:continue
		var value:=Ledger.flow_value("player",id)+Ledger.flow_value(id,"player")
		rows.append({"id":id,"contact":contact,"value":value,"name":String(c.get("name",id)),"sent":Ledger.flow_value("player",id),"received":Ledger.flow_value(id,"player"),"available":contact>=2 and Ledger.blocked("player",id).is_empty()})
	rows.sort_custom(func(x:Dictionary,y:Dictionary)->bool:
		if bool(x.available)!=bool(y.available):return bool(x.available)
		return int(x.contact)>int(y.contact) or (int(x.contact)==int(y.contact) and (float(x.value)>float(y.value) or (float(x.value)==float(y.value) and String(x.name)<String(y.name)))))
	return rows

func _build_partner_browser()->void:
	browser=VBoxContainer.new();browser.name="PartnerBrowser";browser.add_theme_constant_override("separation",8);partner_workspace.add_child(browser)
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",8);browser.add_child(heading)
	var title:=S.label("Choose a people",16,T.INK,true);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.size_flags_vertical=Control.SIZE_SHRINK_CENTER;heading.add_child(title)
	browser_close=S.verb("Back to terms",_toggle_partner_browser,"Close the chooser and return to the selected people's terms");browser_close.name="ClosePartnerChooser";heading.add_child(browser_close)
	partner_search=LineEdit.new();partner_search.name="FindPartner";partner_search.placeholder_text="Find a people";partner_search.custom_minimum_size.y=40;browser.add_child(partner_search)
	partner_search.text_changed.connect(func(words:String)->void:partner_query=words;partner_page=0;_build_partner_choices())
	partner_pager=HFlowContainer.new();partner_pager.add_theme_constant_override("h_separation",8);partner_pager.add_theme_constant_override("v_separation",4);browser.add_child(partner_pager)
	partner_previous=S.verb("‹",func()->void:partner_page-=1;_build_partner_choices(),"Previous peoples");partner_previous.name="PreviousPartners";partner_pager.add_child(partner_previous)
	partner_count=S.label("",14,T.INK_MUTED);partner_count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;partner_pager.add_child(partner_count)
	partner_next=S.verb("›",func()->void:partner_page+=1;_build_partner_choices(),"Next peoples");partner_next.name="NextPartners";partner_pager.add_child(partner_next)
	partner_choices=VBoxContainer.new();partner_choices.name="PartnerChoices";partner_choices.add_theme_constant_override("separation",6);browser.add_child(partner_choices)

func _build_partner_choices()->void:
	_clear(partner_choices)
	var all_rows:=_known_rows()
	var rows:Array=[]
	for row:Dictionary in all_rows:
		if partner_query.strip_edges().is_empty() or String(row.name).to_lower().contains(partner_query.strip_edges().to_lower()):rows.append(row)
	browser.visible=not all_rows.is_empty()
	partner_search.visible=all_rows.size()>PARTNER_PAGE_SIZE or not partner_query.is_empty()
	var last:=maxi(0,ceili(float(rows.size())/PARTNER_PAGE_SIZE)-1)
	partner_page=clampi(partner_page,0,last)
	partner_pager.visible=all_rows.size()>PARTNER_PAGE_SIZE
	partner_count.text="%d–%d of %d" % [partner_page*PARTNER_PAGE_SIZE+1,mini((partner_page+1)*PARTNER_PAGE_SIZE,rows.size()),rows.size()] if not rows.is_empty() else "No matches"
	partner_previous.disabled=partner_page==0;partner_next.disabled=partner_page>=last
	for row:Dictionary in rows.slice(partner_page*PARTNER_PAGE_SIZE,(partner_page+1)*PARTNER_PAGE_SIZE):
		var id:=String(row.id)
		var button:=S.verb(String(row.name),_choose_partner.bind(id),String(row.name)+(" · Known only by word" if int(row.contact)<2 else (" · Trade available" if bool(row.available) else " · Route blocked")),id==selected_partner)
		button.name="PartnerChoice_"+id;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		partner_choices.add_child(button)
	if rows.is_empty():partner_choices.add_child(S.label("No matching peoples.",14,T.INK_MUTED))

func _choose_partner(civ_id:String)->void:
	selected_partner=civ_id; browse_open=false
	if not expanded_people.has(civ_id):expanded_people[civ_id]=true
	_build_peoples();_responsive()

func _build_peoples(force:=false)->void:
	var rows:=_known_rows()
	if rows.is_empty():
		if force or peoples_box.get_node_or_null("None")==null or people_signatures.get("empty_theme","")!=T.color_mode:
			_clear(peoples_box);people_signatures.clear()
			people_signatures["empty_theme"]=T.color_mode
			var calm:=S.label("We have met no other people yet.",16,T.INK_MUTED);calm.name="None";peoples_box.add_child(calm)
		_build_partner_choices()
		return
	if not rows.any(func(row:Dictionary)->bool:return String(row.id)==selected_partner):
		selected_partner=String(rows[0].id)
		if not expanded_people.has(selected_partner):expanded_people[selected_partner]=true
	_build_partner_choices()
	var keep:Array[String]=[]
	var state:=Ledger.peek()
	for row:Dictionary in rows:
		if String(row.id)!=selected_partner:continue
		var id:=String(row.id);var node_name:="People_"+id;keep.append(node_name)
		var details:Array=[row,T.color_mode,Ledger.civ(id).get("player_relation",{}),expanded_people.get(id,false),evidence_open.get(id,false)]
		if int(row.contact)>=2:
			details.append_array([Ledger.pair("player",id),Stances.stance("player",id),Stances.stance(id,"player"),
				Ledger.most_needed("player",id),Ledger.most_needed(id,"player"),Ledger.blocked("player",id),
				state.get("answers",{}),state.get("tributes",{}),Ledger.revision,int(GameState.elapsed_days),Goods.spare(),Ledger.purse_balance("player")])
		var next:=str(hash(details))
		var old:=peoples_box.get_node_or_null(NodePath(node_name))
		if force or old==null or next!=String(people_signatures.get(id,"")):
			var focused:=get_viewport().gui_get_focus_owner()
			var focus_name:=String(focused.name) if focused!=null and old!=null and old.is_ancestor_of(focused) else ""
			if old!=null:peoples_box.remove_child(old);old.queue_free()
			old=_people_row(id,int(row.contact));peoples_box.add_child(old);people_signatures[id]=next
			if not focus_name.is_empty():
				var replacement:=old.find_child(focus_name,true,false) as Control
				if replacement!=null:replacement.grab_focus.call_deferred()
		peoples_box.move_child(old,keep.size()-1)
	for child in peoples_box.get_children():
		if not String(child.name) in keep:peoples_box.remove_child(child);child.queue_free()
	for id:String in people_signatures.keys():
		if not "People_"+id in keep:people_signatures.erase(id)


func _people_row(civ_id:String,contact:int)->Control:
	var name:=Ledger.name_of(civ_id)
	var ours:=Stances.stance("player",civ_id)
	var theirs:=Stances.stance(civ_id,"player")
	var panel:=PanelContainer.new();panel.name="People_%s" % civ_id
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var line_style:=StyleBoxFlat.new();line_style.bg_color=Color.TRANSPARENT;line_style.border_width_bottom=1;line_style.border_color=Color(T.RULE,0.45);line_style.content_margin_top=0;line_style.content_margin_bottom=8
	panel.add_theme_stylebox_override("panel",line_style)
	var column:=VBoxContainer.new();column.name="Content";column.add_theme_constant_override("separation",12);panel.add_child(column)
	var head:=HBoxContainer.new();head.name="PartnerIdentity";head.add_theme_constant_override("separation",8);head.custom_minimum_size.y=S.ROW_HEIGHT;head.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(head)
	var art:=_partner_art(civ_id,contact);head.add_child(art)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_theme_constant_override("separation",4);head.add_child(identity)
	var title:=S.label(name,20,T.INK,true);title.name="Name";title.tooltip_text=name;title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.custom_minimum_size.x=90;identity.add_child(title)
	var p:=Ledger.pair("player",civ_id)
	var subtitle:="known only by word: no trader reaches them" if contact<2 else (Words.form_words(String(p.get("form","gift"))) if not p.is_empty() else "met; no goods have passed yet")
	var blocked:=Ledger.blocked("player",civ_id) if contact>=2 and not p.is_empty() else ""
	if blocked!="":subtitle=Ledger.sea_words("player",civ_id) if blocked=="sea" else _blocked_words(blocked)
	var form_label:=S.label(_cap(subtitle),14,T.RED_TEXT if blocked!="" else T.INK_MUTED);form_label.name="Form";form_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;form_label.tooltip_text=subtitle;identity.add_child(form_label)
	var toggle:=S.verb("Change people",_toggle_partner_browser,"Choose another people to review their trade and set our terms");toggle.name="ChangePartner";head.add_child(toggle)
	if contact<2:
		head.add_child(S.tag("Not met",T.MUTED))
		return panel
	var form:=String(p.get("form","gift"))
	column.add_child(S.label("Recorded pace · "+Words.period_word(form),14,T.INK_MUTED))
	var summary:=HBoxContainer.new();summary.add_theme_constant_override("separation",16);column.add_child(summary)
	var bar:=Graphics.new();bar.name="Flows";bar.compact=true;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_stretch_ratio=1.2;bar.custom_minimum_size=Vector2(60,20);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	bar.values=[Words.per_period(Ledger.flow_value(civ_id,"player"),form),Words.per_period(Ledger.flow_value("player",civ_id),form)];summary.add_child(bar)
	bar.tooltip_text="Worth %s at each sender's own prices. Left of center means more received; right means more sent. These are smoothed values, so blocked routes retain readings from earlier trade." % Words.period_word(form)
	var stance_id:=String(ours.get("id","free"))
	summary.add_child(S.tag("Our stance: "+String(Words.LABELS.get(stance_id,stance_id)),T.RED if stance_id in Stances.COERCIVE else (T.GREEN if stance_id in ["free","favour","gifts"] else T.GOLD)))
	var details:=VBoxContainer.new();details.name="TradeTerms";details.add_theme_constant_override("separation",16);details.visible=bool(expanded_people.get(civ_id,false));column.add_child(details);column=details
	var decisions:=VBoxContainer.new();decisions.name="TradeDecisions";decisions.add_theme_constant_override("separation",12);column.add_child(decisions)
	var evidence:=VBoxContainer.new();evidence.name="TradeEvidence";evidence.add_theme_constant_override("separation",12);evidence.visible=bool(evidence_open.get(civ_id,false));column.add_child(evidence)
	var evidence_toggle:=S.verb("Hide exchange detail" if evidence.visible else "Goods & dependence",func()->void:evidence_open[civ_id]=not bool(evidence_open.get(civ_id,false));_build_peoples();_responsive(),"Exact goods exchanged and how much each people depends on the other")
	evidence_toggle.name="ExchangeEvidence";evidence_toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;column.add_child(evidence_toggle);column.move_child(evidence_toggle,1)
	var goods:=_grid(evidence,"GoodsExchanged",2,640)
	goods.add_child(_flows("We send",Words.flow_items("player",civ_id),form))
	goods.add_child(_flows("They send",Words.flow_items(civ_id,"player"),form))
	goods.add_theme_constant_override("v_separation",0)
	var needs:=_grid(evidence,"Dependence",2,640)
	needs.add_theme_constant_override("v_separation",0)
	for pair_:Array in [["player",civ_id],[civ_id,"player"]]:
		var owner:=String(pair_[0]);var from:=String(pair_[1])
		var need:=Ledger.most_needed(owner,from)
		if need.is_empty() or float(need.get("share",0))<0.05:continue
		needs.add_child(_dependence(owner,from,need))
	if needs.get_child_count()==0:needs.visible=false
	# Their stance, tribute and what is owed, on one line.
	var standing:=VBoxContainer.new();standing.add_theme_constant_override("separation",8);decisions.add_child(standing)
	var theirs_words:=Words.theirs_label(civ_id)
	if theirs_words!="":
		var against:=S.label(theirs_words,14,T.RED_TEXT if String(theirs.get("id","")) in Stances.COERCIVE else T.GREEN_TEXT,true);against.name="Theirs";standing.add_child(against)
	var tribute:=Words.tribute_label(civ_id)
	if tribute!="":standing.add_child(S.label(tribute,14,T.GOLD_TEXT,true))
	var owed:=Words.owed_label(civ_id)
	if owed!="":
		var debt:=S.label(owed,14,T.INK_MUTED);debt.name="Owed"
		debt.tooltip_text="Gifts not yet returned. A people that owes us gives way more readily: up to 1 in 10 on its answer."
		standing.add_child(debt)
	if standing.get_child_count()==0:standing.visible=false
	for reading:Label in standing.get_children():reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	# Our terms: the stance buttons and what our goods buy, on one row.
	var action_head:=HBoxContainer.new();action_head.add_theme_constant_override("separation",12);decisions.add_child(action_head)
	var lead:=S.label("Set our terms",16,T.INK,true);lead.size_flags_horizontal=Control.SIZE_EXPAND_FILL;lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;action_head.add_child(lead)
	var buy:=_buy_menu(civ_id)
	if buy!=null:buy.size_flags_vertical=Control.SIZE_SHRINK_CENTER;action_head.add_child(buy)
	var terms:=_stance_buttons(civ_id,ours);decisions.add_child(terms)
	var odds_row:=_odds_row(civ_id,ours)
	if odds_row!=null:decisions.add_child(odds_row)
	var last:=Words.answer_label("player",civ_id)
	if last!="":
		var said:=_line(last,14,T.INK_MUTED,true);said.name="LastWord";said.tooltip_text=Words.answer_line("player",civ_id);decisions.add_child(said)
	return panel


func _toggle_partner_browser()->void:
	browse_open=not browse_open;_responsive()
	if browse_open and partner_search.visible:partner_search.grab_focus.call_deferred()

func _toggle_people(civ_id:String)->void:
	selected_partner=civ_id
	expanded_people[civ_id]=not bool(expanded_people.get(civ_id,false))
	_build_peoples();_responsive()


## The people's own mark (city_map_identity.gd), small, at the line's head.
func _partner_art(civ_id:String,_contact:int)->TextureRect:
	var art:=TextureRect.new();art.name="PartnerIllustration";art.texture=Identity.emblem(civ_id)
	art.custom_minimum_size=Vector2(40,40);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.size_flags_vertical=Control.SIZE_SHRINK_CENTER;art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return art


func _blocked_words(why:String)->String:
	match why:
		"war":return "At war: no trader crosses"
		"feud":return "Feuding: no trader crosses"
		"hostile":return "They will not meet our traders"
		"unlocated":return "We do not know where they live: find their home first"
		"sea":return "The sea between us is too wide for our boats or theirs"
	return "Embargoed: nothing passes" if why.begins_with("embargo") else why


## "We send ▸ [mark] 12 flint · [mark] 30 food · a season".
func _flows(lead:String,items:Array,form:String)->Control:
	var row:=VBoxContainer.new();row.name=lead.replace(" ","");row.add_theme_constant_override("separation",8)
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.custom_minimum_size.y=S.ROW_HEIGHT
	var head:=S.label(lead+" · "+Words.period_word(form),14,T.GOLD_TEXT if lead=="We send" else T.TEAL_TEXT,true);head.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.custom_minimum_size.x=130;row.add_child(head)
	if items.is_empty():
		var none:=S.label("nothing recorded yet",14,T.INK_MUTED);none.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(none)
		return row
	var goods:=HFlowContainer.new();goods.name="Goods";goods.size_flags_horizontal=Control.SIZE_EXPAND_FILL;goods.add_theme_constant_override("h_separation",12);goods.add_theme_constant_override("v_separation",2);row.add_child(goods)
	for item:Array in items:
		var good:=String(item[0])
		var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",4);chip.set_meta("good",good);chip.set_meta("amount",float(item[1]));goods.add_child(chip)
		chip.tooltip_text="%s %s, at the recent trading pace." % [Words.amount(float(item[1]),good),Words.period_word(form)]
		chip.add_child(S.icon("Arms" if good=="Arms" else good,18))
		var amount:=S.label("%s %s" % [Words.qty(float(item[1])),"fighters armed" if good=="Arms" else Words.good_word(good)],14,T.INK,true);amount.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(amount)
	return row

func _dependence(owner:String,from:String,need:Dictionary)->Control:
	var share:=clampf(float(need.share),0.0,1.0)
	var days:=float(need.get("days",-1))
	var duration:="no shortage without it" if days<0 else "%s without it" % EraWords.days(days)
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var refs:=S.row(box,{"id":"lean","label":("Our %s from them" if owner=="player" else "Their %s from us") % Words.good_word(String(need.good)),"note":duration,"ratio":share,"bar_color":T.TEAL if owner=="player" else T.GOLD,"bar_width":60.0,"value":"%d%%" % roundi(share*100.0),"value_width":44.0,"label_width":170.0,
		"tip":"%s: %d%% of %s supply comes from %s. %s." % [Ledger.name_of(owner),roundi(share*100.0),Words.good_word(String(need.good)),Ledger.name_of(from),_cap(duration)]})
	(refs.panel as Control).name="OurDependence" if owner=="player" else "TheirDependence"
	(refs.value as Label).name="Lean";(refs.bar as Control).name="SupplyShare"
	return box


## The stance buttons: the one in force pressed; the pointer tells what each
## does and their odds.
func _stance_buttons(civ_id:String,ours:Dictionary)->Control:
	var row:=HFlowContainer.new();row.name="Stances";row.add_theme_constant_override("h_separation",8);row.add_theme_constant_override("v_separation",8)
	var chosen:=String(ours.get("id","free"))
	for id:String in STANCE_ORDER:
		if id=="squeeze":
			row.add_child(_squeeze_button(civ_id,chosen=="squeeze",String(ours.get("good",""))))
			continue
		var button:=Button.new();button.name="Stance_%s" % id;button.text=String(Words.LABELS[id]);button.toggle_mode=true;_style_action(button)
		button.set_pressed_no_signal(chosen==id)
		button.tooltip_text=Words.tip(id,"player",civ_id)
		button.pressed.connect(func()->void:_choose(civ_id,id,""))
		row.add_child(button)
	return row


func _squeeze_button(civ_id:String,chosen:bool,good_now:String)->Control:
	var pick:=MenuButton.new();pick.name="Stance_squeeze";pick.flat=false;_style_action(pick)
	pick.text=("Squeeze %s ▾" % Words.good_word(good_now)) if chosen and good_now!="" else "Squeeze ▾"
	if chosen:pick.add_theme_stylebox_override("normal",pick.get_theme_stylebox("pressed").duplicate())
	var goods:=_squeeze_goods(civ_id)
	var popup:=pick.get_popup()
	_style_popup(popup)
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
	var pick:=MenuButton.new();pick.name="BuyWithGoods";pick.flat=false;_style_action(pick)
	pick.text="Buy with goods ▾"
	if offers.is_empty():
		pick.disabled=true;pick.tooltip_text="They have nothing to spare for our goods."
		return pick
	var popup:=pick.get_popup()
	_style_popup(popup)
	var terms:Array=offers
	for i in offers.size():
		var t:Dictionary=offers[i]
		var what:=String(t.what)
		if bool(t.ok):popup.add_item("%s · %s for %s goods" % [_deal_name(what),S.n(float(t.count)),S.n(float(t.goods))],i)
		else:
			popup.add_item(_short("%s · %s" % [_deal_name(what),String(t.why)]),i)
			popup.set_item_disabled(popup.get_item_count()-1,true)
		popup.set_item_tooltip(popup.get_item_count()-1,"%s\n%s\nWith %s: %s goods a %s at their prices. We have %s goods to spare." % [String(t.get("words","")),String(t.get("why","")),Ledger.name_of(civ_id),str(snappedf(float(t.each),0.1)),"head" if what in Ledger.PEOPLE else ("set" if what==Ledger.ARMS else "load"),str(roundi(float(t.spare)))])
	pick.tooltip_text="Our goods buy what they have to spare, at their prices."
	if offers.any(func(offer:Dictionary)->bool:return bool(offer.ok)):T.apply_button_style(pick,true)
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
			if String(st.get("id","free"))!="free":line=_cap(Words.act_words(String(side[0]),String(st.id),String(side[1]),String(st.get("good",""))))
		if line=="" and value<Ledger.PARTNER_FLOOR:continue
		if line=="":line="%s and %s · %s" % [Ledger.name_of(a),Ledger.name_of(b),Words.form_words(String(p.get("form","gift")))]
		rows.append({"line":line,"value":value})
	rows.sort_custom(func(x:Dictionary,y:Dictionary)->bool:return float(x.value)>float(y.value))
	if rows.is_empty():
		var empty:=S.label("We know of no trade between other peoples.",16,T.INK_MUTED);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;others_box.add_child(empty)
		return
	var toggle:=S.verb("Between other peoples · %d %s%s" % [rows.size(),"exchange" if rows.size()==1 else "exchanges"," · hide" if others_open else ""],func()->void:others_open=not others_open;_build_others(),"Recorded exchange between other peoples we have met")
	toggle.name="OtherTradeToggle";toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;others_box.add_child(toggle)
	if not others_open:return
	var last:=maxi(0,ceili(float(rows.size())/PARTNER_PAGE_SIZE)-1);other_page=clampi(other_page,0,last)
	if last>0:
		var pager:=HFlowContainer.new();pager.add_theme_constant_override("h_separation",8);others_box.add_child(pager)
		var previous:=S.verb("Previous",func()->void:other_page-=1;_build_others());previous.disabled=other_page==0;pager.add_child(previous)
		pager.add_child(S.label("Page %d / %d" % [other_page+1,last+1],14,T.INK_MUTED))
		var next:=S.verb("Next",func()->void:other_page+=1;_build_others());next.disabled=other_page>=last;pager.add_child(next)
	for row:Dictionary in rows.slice(other_page*PARTNER_PAGE_SIZE,(other_page+1)*PARTNER_PAGE_SIZE):S.row(others_box,{"id":"other","icon":"carry","icon_kind":"people","label":String(row.line),"value":"%s a month" % S.n(float(row.value)) if float(row.value)>=0.5 else "","value_width":4.0})


func _met(id:String)->bool:
	var c:=Ledger.civ(id)
	return not c.is_empty() and int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2


# --- Pieces ---------------------------------------------------------------------

func _say(text:String)->void:
	feedback.text=text
	feedback.visible=text!=""


func _section(title:String)->VBoxContainer:
	var section:=VBoxContainer.new();section.add_theme_constant_override("separation",12);add_child(section)
	var head:=S.head(section,title);(head.title as Label).name="PeoplesHeading"
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",0);section.add_child(box)
	return box

func _visual_section(title:String,parent:Node,node_name:String,icon:String,hero:=false)->VBoxContainer:
	var panel:=PanelContainer.new();panel.name=node_name;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=_folio_rule(0)
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",8);column.add_child(header)
	header.visible=not hero
	if not icon.is_empty():
		var mark:=Emblem.new(icon);mark.custom_minimum_size=Vector2(28,28);header.add_child(mark)
	var kicker:=_line(title.to_upper(),20,T.INK,true);kicker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;kicker.size_flags_vertical=Control.SIZE_SHRINK_CENTER;header.add_child(kicker)
	visual_sections.append({"panel":panel,"kicker":kicker,"hero":hero})
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",8);column.add_child(box)
	return box

static func _folio_rule(padding:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color.TRANSPARENT;style.border_color=T.RULE;style.border_width_bottom=1
	style.content_margin_top=padding;style.content_margin_bottom=maxi(16,padding)
	return style

func _grid(parent:Node,node_name:String,count:int,threshold:float)->GridContainer:
	var grid:=GridContainer.new();grid.name=node_name;grid.columns=1;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",12)
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
	# The strip's figures: all across a wide page, fewer as it narrows.
	var strip:=find_child("TradeKpis",true,false) as GridContainer
	if strip!=null:
		var across:=clampi(floori((available+10.0)/120.0),2,strip.get_child_count())
		if strip.columns!=across:strip.columns=across
	S.compact(self,available)
	if partner_workspace!=null:
		partner_workspace.vertical=available<850.0
		browser.custom_minimum_size.x=0.0 if partner_workspace.vertical else 260.0
		browser.size_flags_horizontal=Control.SIZE_EXPAND_FILL if partner_workspace.vertical else Control.SIZE_FILL
		browser.visible=not _known_rows().is_empty() and (not partner_workspace.vertical or browse_open)
		browser_close.visible=partner_workspace.vertical and browse_open
		partner_workspace.move_child(browser,0 if partner_workspace.vertical else 1)
		var change:=find_child("ChangePartner",true,false) as Button
		if change!=null:change.visible=partner_workspace.vertical;change.text="Hide chooser" if browse_open else "Change people"
	# A narrow page keeps each people's name, balance and Terms on its line.
	for head:Node in find_children("PartnerIdentity","HBoxContainer",true,false):
		for child in head.get_children():
			if child.name=="Form" or child is PanelContainer or (child is Label and child.has_theme_stylebox_override("normal")):(child as Control).visible=available>=S.COMPACT_BELOW
	var retained:Array[GridContainer]=[]
	for grid:GridContainer in responsive_grids:
		if not is_instance_valid(grid) or not grid.is_inside_tree():continue
		retained.append(grid)
		var count:=int(grid.get_meta("wide_columns")) if available>=float(grid.get_meta("wide_threshold")) else 1
		if grid.columns!=count:grid.columns=count
	responsive_grids=retained

func _style_action(button:Button)->void:
	T.apply_button_style(button)
	button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN

func _style_popup(popup:PopupMenu)->void:
	popup.add_theme_font_override("font",T.font("ui"))
	popup.add_theme_font_size_override("font_size",16)
	popup.add_theme_constant_override("v_separation",20)

func _answer(text:String,size:=30)->Label:
	var label:=_line(text,size,T.INK,true)
	label.add_theme_font_override("font",T.font("ui_strong"))
	return label


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
	label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",maxi(14,size));label.add_theme_color_override("font_color",color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label
