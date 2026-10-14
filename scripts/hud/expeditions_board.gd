extends VBoxContainer
## WORLD › EXPEDITIONS, on one page (the old scouting window and the "every
## telling" screen folded in):
##
##   ┌ Send scouts                     ┬ Unread tellings, grouped
##   │ share kept · what they seek ·   │ "Armed strangers on the road ×3
##   │ where they leave from · Send an │  NE · W · N  Year 436"  [Read]
##   │ expedition (planned on the map) │
##   │ parties away, with their bars   │
##   ├ Foreign towns: one row each, party size, length, Send / Watch
##   └ Every telling: search, filter chips and a dense paged table
##
## The KPI strip above (parties away, tellings, last return) is the
## provider's (content/dock_content_world.gd). Everything here reads the
## engine's one source: CivilizationSystem.scouting_staff, the city watch
## orders (city_watch_orders.gd), exploration_status() and the scout reports
## (scout_archive.gd). Routes and finds are drawn on the map while this tab
## is open (expedition_routes_overlay.gd).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI:=preload("res://scripts/hud/world_ui.gd")
const Archive:=preload("res://scripts/scout_archive.gd")
const Orders:=preload("res://scripts/hud/city_watch_orders.gd")
const When:=preload("res://scripts/hud/report_when.gd")

const PRESETS:=[["Off",0.0],["Little",2.0],["Regular",5.0],["A lot",10.0]]
const FOCUSES:=[["exploration","Explore"],["recruitment","Find bands"],["prospecting","Prospect"]]
const PAGE:=12
const GROUPS_SHOWN:=8
const TWO_AT:=600.0

var model:Dictionary={}
var headline:Label
## Search, filter, order and page of the tellings table, kept by the World
## page across its daily rebuilds.
var view:Dictionary={}
var send_box:VBoxContainer
var unread_box:VBoxContainer
var cities_box:VBoxContainer
var tellings_box:VBoxContainer
var top:GridContainer
var search:LineEdit
var results:VBoxContainer
var counter:Label
var previous:Button
var next:Button
var visible_items:Array=[]
## Foreign towns, as the old window's tests knew them: {city_id: {name,
## meta, count, minus, plus, days, cost, risk, once, keep, stop, status, note}}.
var city_rows:Dictionary={}
var city_choice:Dictionary={}
var city_feedback:Dictionary={}
var cities_note:Label
var cities_empty:Label
var origin_selector:OptionButton
var _printed:=""

func setup(block:Dictionary)->void:
	name="ExpeditionsBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	_take(block)
	# The page's counts, one line (the provider's "line").
	headline=UI.label(self,String(block.get("line","")),13,T.INK,false,true);headline.name="Line"
	headline.tooltip_text=String(block.get("line_tip",""))
	top=UI.columns(self,"SendAndUnread")
	send_box=UI.sheet(top,"Send")
	unread_box=UI.sheet(top,"Unread")
	# On a wide page (2000 px) the tellings stand beside the planner.
	wide_row=HBoxContainer.new();wide_row.name="Wide";wide_row.add_theme_constant_override("separation",14);add_child(wide_row)
	wide_left=VBoxContainer.new();wide_left.add_theme_constant_override("separation",12);wide_left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;wide_left.size_flags_stretch_ratio=0.7;wide_row.add_child(wide_left)
	wide_right=VBoxContainer.new();wide_right.add_theme_constant_override("separation",12);wide_right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;wide_row.add_child(wide_right)
	cities_box=UI.sheet(self,"ForeignTowns")
	tellings_box=UI.sheet(self,"Tellings")
	_build_tellings_frame()
	redraw()
	resized.connect(_layout);_layout()

func update_block(block:Dictionary)->bool:
	_take(block)
	if headline!=null:headline.text=String(block.get("line",""))
	var staff:Dictionary=CivilizationSystem.scouting_staff.snapshot()
	var exploration:Dictionary=CivilizationSystem.exploration_status()
	var parties:Array=[]
	for party:Dictionary in exploration.get("parties",[]):parties.append([party.get("mission_id",0),roundi(float(party.get("progress",0.0))*70.0),party.get("overdue_days",0)])
	_redraw_if("send",[staff.get("share"),staff.get("focus"),staff.get("origin_city_id"),staff.get("away"),staff.get("target"),staff.get("review_in"),parties],_fill_send)
	var revision:=Archive.revision(_reports())
	_redraw_if("unread",revision,_fill_unread)
	_redraw_if("cities",[int(GameState.elapsed_days)/7,Orders.watch_count(),CivilizationSystem.scout_missions.size(),city_feedback.size()],_fill_cities)
	_redraw_if("tellings",[revision,view.duplicate()],_fill_tellings)
	return true

var _prints:Dictionary={}
func _redraw_if(part:String,key:Variant,fill:Callable)->void:
	var printed:=var_to_str(key)
	if String(_prints.get(part,""))==printed:return
	_prints[part]=printed
	fill.call()

func _take(block:Dictionary)->void:
	model=block
	var given:Variant=block.get("view")
	view=given if given is Dictionary else {}
	for pair:Array in [["query",""],["filter",0],["order",1],["page",0]]:
		if not view.has(String(pair[0])):view[String(pair[0])]=pair[1]

const WIDE_AT:=800.0
var wide_row:HBoxContainer
var wide_left:VBoxContainer
var wide_right:VBoxContainer
var _wide:=false

func _layout()->void:
	if top==null:return
	var wide:=size.x>=WIDE_AT
	if wide!=_wide:
		_wide=wide
		var send:=send_box.get_parent();var unread:=unread_box.get_parent();var tellings:=tellings_box.get_parent()
		for frame:Node in [send,unread,tellings]:frame.get_parent().remove_child(frame)
		if wide:
			wide_left.add_child(send);wide_left.add_child(unread);wide_right.add_child(tellings)
		else:
			top.add_child(send);top.add_child(unread);add_child(tellings)
		wide_row.visible=wide;top.visible=not wide
		move_child(cities_box.get_parent(),get_child_count()-1)
		if not wide:move_child(tellings,get_child_count()-1)
	if not _wide:top.columns=2 if size.x>=TWO_AT else 1

## Draws every part from the engine as it stands now.
func redraw()->void:
	_fill_send()
	_fill_unread()
	_fill_cities()
	_fill_tellings()

func _reports()->Array:
	var given:Variant=model.get("reports")
	return given if given is Array else CivilizationSystem.scout_reports

# --------------------------------------------------------------- send scouts

func _fill_send()->void:
	UI.clear(send_box)
	var staff:Dictionary=CivilizationSystem.scouting_staff.snapshot()
	var share:=float(staff.get("share",0.0))*100.0
	var Words:=preload("res://scripts/hud/era_words.gd")
	var send_head:=UI.heading(send_box,"Send scouts","%s scouts out · room for %s" % [Words.grouped(int(staff.get("away",0))),Words.grouped(int(staff.get("target",0)))])
	send_head.tooltip_text="Scouts are the people kept for scouting; they go out in parties. The share below sets how many may be kept."
	var kept:=_control_row(send_box,"Share")
	for preset:Array in PRESETS:
		var amount:=float(preset[1])
		var b:=UI.chip(kept,String(preset[0]),is_equal_approx(share,amount),func()->void:set_share(amount),"%.0f%% of the people of %s kept for scouting. Parties already away finish their journeys if you lower it." % [amount,String(staff.get("origin_label","home"))])
		b.name="Share_%s" % String(preset[0]).replace(" ","")
	var shown:=("%d%%" % roundi(share)) if is_equal_approx(share,roundf(share)) else "%.1f%%" % share
	UI.label(kept,shown,13,T.INK,true).name="ShareValue"
	var seek:=_control_row(send_box,"Seek")
	for focus:Array in FOCUSES:
		var key:=String(focus[0])
		var tip:String=String({"exploration":"New ground, finds and knowledge.","recruitment":"Search for scarce wandering bands who may join us. Taking people from a foreign town is a separate, hostile order.","prospecting":String((staff.get("prospecting",{}) as Dictionary).get("message","Survey real ground for rare ore and fuel. Nothing reaches the stores until a deposit is worked."))}.get(key,""))
		var b:=UI.chip(seek,String(focus[1]),String(staff.get("focus",""))==key,func()->void:set_focus(key),String(tip))
		b.name="Focus_"+key
	var from:=_control_row(send_box,"From")
	origin_selector=OptionButton.new();origin_selector.name="ScoutOrigin";origin_selector.focus_mode=Control.FOCUS_NONE
	origin_selector.custom_minimum_size=Vector2(170,24);origin_selector.size_flags_horizontal=Control.SIZE_EXPAND_FILL;origin_selector.clip_text=true;origin_selector.add_theme_font_size_override("font_size",12)
	origin_selector.add_theme_color_override("font_color",T.INK)
	from.add_child(origin_selector)
	var chosen:=String(staff.get("origin_city_id",""))
	for option:Dictionary in CivilizationSystem.scout_origin_options():
		origin_selector.add_item(String(option.label).capitalize())
		origin_selector.set_item_metadata(origin_selector.item_count-1,String(option.id))
		if String(option.id)==chosen:origin_selector.select(origin_selector.item_count-1)
	origin_selector.item_selected.connect(func(index:int)->void:set_origin(String(origin_selector.get_item_metadata(index))))
	var act:=UI.line(send_box)
	var plan:Variant=model.get("on_plan")
	var expedition:=UI.verb(act,"Send expedition",plan if plan is Callable else Callable(),"Push far one way, by land or by sea. Choose the direction, how far and how many on the map; the farther they push, the fewer come home.",true)
	expedition.name="SendExpedition"
	var status:=UI.label(act,_status_words(staff),12,T.INK_MUTED,false,true);status.name="Status"
	status.custom_minimum_size.x=60
	status.tooltip_text=String(staff.get("status",""))
	if String(staff.get("focus",""))=="recruitment":_reception_line(send_box,staff)
	_parties(send_box)
	_last_back(send_box)

func _control_row(parent:Node,caption:String)->HBoxContainer:
	var row:=UI.line(parent,6)
	UI.cell(row,caption,52,12,T.INK_MUTED)
	return row

static func _status_words(staff:Dictionary)->String:
	if float(staff.get("share",0.0))<=0.0:return "No new departures"
	var review:=int(staff.get("review_in",0))
	var food:=float(staff.get("daily_food",0.0))
	var carried:=(" · %.0f food a day carried" % food) if food>=0.5 else ""
	return ("Next party checked in %d days" % review if review>0 else "Next party checked tomorrow")+carried

func _reception_line(parent:Node,staff:Dictionary)->void:
	var reception:Dictionary=staff.get("reception",{})
	var nomads:Dictionary=(staff.get("recruitment",{}) as Dictionary).get("nomads",{})
	var text:="Room for %d newcomers · %d bands met" % [int(reception.get("capacity",0)),int(nomads.get("known_bands",0))]
	var tone:="info"
	if int(reception.get("capacity",0))<2:text="No room for newcomers: invitations wait";tone="warn"
	elif not bool(nomads.get("available",true)):text="No wandering bands are left to find";tone="warn"
	var row:=UI.line(parent)
	UI.tag(row,text,tone).tooltip_text=String(reception.get("message",nomads.get("message","")))

## Parties away: one line each with its journey bar.
func _parties(parent:Node)->void:
	var exploration:Dictionary=CivilizationSystem.exploration_status()
	var parties:Array=exploration.get("parties",[])
	if parties.is_empty():return
	UI.rule(parent)
	for party:Dictionary in parties:
		var row:=UI.line(parent)
		row.name="Party_%d" % int(party.get("mission_id",0))
		var overdue:=int(party.get("overdue_days",0))
		UI.icon(row,"scout",T.TEAL if overdue<=0 else T.AMBER,18)
		var title:=UI.label(row,_party_title(party),13,T.INK,true,true)
		title.tooltip_text=String(party.get("turnback_reason","What they see stays with them until they come home."))
		UI.bar(row,float(party.get("progress",0.0)),T.AMBER if overdue>0 else T.TEAL,70)
		UI.cell(row,"%d" % int(party.get("personnel",0)),34,12,T.INK_MUTED,false,HORIZONTAL_ALIGNMENT_RIGHT).tooltip_text="Scouts in the party"
		var due:=int(party.get("days_remaining",0))
		UI.cell(row,("late %s" % When.span(overdue)) if overdue>0 else ("home in %s" % When.span(due) if due>1 else "home any day"),104,12,T.AMBER_TEXT if overdue>0 else T.TEAL_TEXT)

## The latest parties home, one line each, under the planner: who went, where,
## when, and any lost.
func _last_back(parent:Node)->void:
	var reports:=_reports()
	if reports.is_empty():return
	UI.rule(parent)
	UI.heading(parent,"Last back")
	var shown:=0
	for item:Dictionary in select(reports,"",0,false):
		if shown>=5:break
		shown+=1
		var report:Dictionary=item.report
		var row:=UI.hot_row(parent,"Back_%d" % shown,func()->void:open_report(report),"%s\n%s\n%s" % [String(item.title),String(item.party),String(item.detail)])
		UI.cell(row,Archive.calendar_date(int(item.day)).replace("Year ",""),74,12,T.INK_MUTED)
		UI.label(row,"%d scouts · %s" % [int(report.get("personnel",0)),String(item.place).replace("Out to the ","").replace(" and back","").to_lower()],12,T.BODY,false,true)
		if int(item.losses)>0:UI.tag(row,"lost %d" % int(item.losses),"danger")

static func _party_title(party:Dictionary)->String:
	return preload("res://scripts/hud/content/dock_content_world.gd").party_title(String(party.get("target_label","")),String(party.get("planned_heading","")))

func set_share(percent:float)->void:
	var staff:Dictionary=CivilizationSystem.scouting_staff.snapshot()
	CivilizationSystem.scouting_staff.set_policy(percent/100.0,String(staff.get("focus","exploration")))
	_fill_send()

func set_focus(key:String)->void:
	CivilizationSystem.scouting_staff.set_policy(float(CivilizationSystem.scouting_staff.data.share),key)
	_fill_send()

func set_origin(id:String)->void:
	CivilizationSystem.scouting_staff.set_origin(id)
	_fill_send();_fill_cities()

# ------------------------------------------------------------ unread, grouped

## Unread tellings grouped by what they tell: [{title, kind, reports (newest
## first), places (short compass words), day, losses}].
static func unread_groups(reports:Array)->Array:
	var by_title:Dictionary={}
	var order:Array=[]
	for report:Dictionary in reports:
		if not report.has("archive_reviewed") or bool(report.archive_reviewed):continue
		var item:=Archive.summary(report)
		var key:=String(item.title)
		if not by_title.has(key):
			by_title[key]={"title":key,"kind":_kind(item),"reports":[],"places":[],"day":0,"losses":0,"priority":int(item.priority)}
			order.append(key)
		var group:Dictionary=by_title[key]
		(group.reports as Array).append(report)
		group.losses=int(group.losses)+int(item.losses)
		group.day=maxi(int(group.day),int(item.day))
		group.priority=maxi(int(group.priority),int(item.priority))
		var place:=_place_word(report)
		if place!="" and not (group.places as Array).has(place):(group.places as Array).append(place)
	var groups:Array=[]
	for key:String in order:
		var group:Dictionary=by_title[key]
		(group.reports as Array).sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.get("day",0))>int(b.get("day",0)))
		groups.append(group)
	groups.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if int(a.priority)!=int(b.priority):return int(a.priority)>int(b.priority)
		return int(a.day)>int(b.day))
	return groups

## A telling's title for one line: the name before any " · " gloss, the
## whole in the row's pointer ("The sound stone hung on a root · a smaller
## working contact" -> "The sound stone hung on a root").
static func short_title(title:String)->String:
	return title.get_slice(" · ",0).strip_edges()

## The moment icon a telling is drawn with.
static func _kind(item:Dictionary)->String:
	if int(item.get("losses",0))>0:return "death"
	var title:=String(item.get("title","")).to_lower()
	if title.begins_with("contact"):return "contact"
	if "newcomers" in title or "recruit" in title:return "birth"
	if "strangers" in title or "armed" in title:return "stranger"
	if "city" in title:return "settlement"
	if bool(item.get("meaningful",false)):return "discovery"
	return "scout"

## Where a party went, as a short compass word ("NE"), else "".
static func _place_word(report:Dictionary)->String:
	var route:Array=report.get("route",[])
	if route.size()<2:return ""
	var World:=preload("res://scripts/hud/content/dock_content_world.gd")
	var line:=World.points(route)
	if line.size()<2:return ""
	var far:=World.farthest(line)
	if far.distance_to(line[0])<=1.0:return "near"
	return UI.short_compass(World.compass(line[0],far))

func _fill_unread()->void:
	UI.clear(unread_box)
	var groups:=unread_groups(_reports())
	var unread:=0
	for group:Dictionary in groups:unread+=(group.reports as Array).size()
	UI.heading(unread_box,"Unread tellings","" if unread>0 else "all read")
	if groups.is_empty():return
	for index in mini(groups.size(),GROUPS_SHOWN):
		var group:Dictionary=groups[index]
		var reports:Array=group.reports
		var newest:Dictionary=reports[0]
		var read:=func()->void:open_report(newest)
		var row:=UI.hot_row(unread_box,"Group_%d" % index,read,"%s\n%d unread · newest %s\nRead opens the newest; each one read leaves this list." % [String(group.title),reports.size(),Archive.calendar_date(int(group.day))])
		UI.icon(row,String(group.kind),T.RED if int(group.losses)>0 else T.GOLD,18)
		UI.label(row,short_title(String(group.title)),13,T.INK,true,true)
		if reports.size()>1:UI.label(row,"×%d" % reports.size(),12,T.GOLD_TEXT,true)
		UI.cell(row," · ".join(PackedStringArray((group.places as Array).slice(0,3))),70,12,T.INK_MUTED)
		UI.verb(row,"Read",read).name="Read"
	if groups.size()>GROUPS_SHOWN:
		var more:=UI.line(unread_box,6)
		UI.label(more,"+%d more kinds" % (groups.size()-GROUPS_SHOWN),12,T.INK_MUTED)
		UI.verb(more,"List all unread",func()->void:view.filter=4;view.page=0;_fill_tellings(),"Show only the unread in the table below").name="AllUnread"

func open_report(report:Dictionary)->void:
	Archive.mark_reviewed(report)
	var reader:Variant=model.get("on_read")
	if reader is Callable and (reader as Callable).is_valid():(reader as Callable).call(report)
	_fill_unread.call_deferred()
	_fill_tellings.call_deferred()

# -------------------------------------------------------------- foreign towns

func _fill_cities()->void:
	UI.clear(cities_box)
	city_rows.clear()
	var cities:Array[Dictionary]=Orders.rival_cities()
	cities_box.get_parent().visible=not cities.is_empty()
	var head:=UI.heading(cities_box,"Foreign towns","watching %d · up to %d at once" % [Orders.watch_count(),Orders.MAX_WATCHES])
	cities_note=head.get_node("Note") as Label
	cities_empty=UI.label(cities_box,"No foreign town reported yet",12,T.INK_MUTED)
	cities_empty.visible=cities.is_empty()
	if cities.is_empty():return
	var header:=UI.line(cities_box)
	for spec:Array in [["Town",96],["People",64],["Away · seen",100],["Scouts",82],["Visit",136],["",100]]:
		var title:=UI.cell(header,String(spec[0]),float(spec[1]),12,T.INK_MUTED,true)
		if String(spec[0])=="Town":title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for city:Dictionary in cities:
		var id:=String(city.city_id)
		if not city_choice.has(id):
			var chosen:Dictionary=Orders.defaults(id,city)
			city_choice[id]={"days":int(chosen.days),"personnel":int(chosen.personnel)}
		_city_row(id,Orders.row(city,int(city_choice[id].days),int(city_choice[id].personnel)))

## "40 years ago · stale" -> ["40 yr ago", stale?].
static func _seen_short(seen:String)->Array:
	var parts:=seen.trim_prefix("seen ").split(" · ")
	var when:=String(parts[0]).replace(" years"," yr").replace(" year"," yr").replace(" months"," mo").replace(" days"," d")
	return [when,parts.size()>1 and String(parts[1]).to_lower() in ["stale","old","outdated"]]

func _city_row(id:String,row_model:Dictionary)->void:
	var on_report:Variant=model.get("on_city_report")
	var open:Callable=on_report.bind(id) if on_report is Callable else Callable()
	var people:=String(row_model.people)
	var tip:="%s · %s · %.0f km away · %s
Click for what we know of it." % [String(row_model.name),people,float(row_model.distance_km),String(row_model.seen)]
	var row:=UI.hot_row(cities_box,"City_"+id.validate_node_name(),open,tip)
	var name_cell:=HBoxContainer.new();name_cell.add_theme_constant_override("separation",6);name_cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	name_cell.custom_minimum_size.x=96;name_cell.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(name_cell)
	var name_label:=UI.label(name_cell,String(row_model.name),13,T.INK,true,true)
	var status:=UI.label(name_cell,"Watched" if bool(row_model.watching) else ("Party away" if bool(row_model.away) else ""),12,T.GREEN_TEXT if bool(row_model.watching) else T.GOLD_TEXT,true)
	status.tooltip_text=String(row_model.status)
	var meta:=UI.cell(row,people.trim_suffix(" people"),64,12,T.BODY)
	meta.tooltip_text=tip
	var seen:=_seen_short(String(row_model.seen))
	UI.cell(row,"%.0f km · %s" % [float(row_model.distance_km),String(seen[0]).trim_suffix(" ago")],100,12,T.AMBER_TEXT if bool(seen[1]) else T.BODY).tooltip_text="%.0f km away · %s" % [float(row_model.distance_km),String(row_model.seen)]
	var party:=HBoxContainer.new();party.add_theme_constant_override("separation",2);party.custom_minimum_size.x=82;row.add_child(party)
	var personnel:=int(row_model.personnel)
	var minus:=UI.verb(party,"−",func()->void:_choose(id,"personnel",int(city_choice[id].personnel)-1),"One scout fewer (at least %d)" % Orders.MIN_PARTY);minus.name="FewerScouts"
	minus.disabled=personnel<=Orders.MIN_PARTY
	var count:=UI.cell(party,"%d" % personnel,30,13,T.INK,true,HORIZONTAL_ALIGNMENT_CENTER);count.name="Count"
	count.tooltip_text="%d scouts in the party" % personnel
	var plus:=UI.verb(party,"+",func()->void:_choose(id,"personnel",int(city_choice[id].personnel)+1),"One scout more (at most %d)" % Orders.MAX_PARTY);plus.name="MoreScouts"
	plus.disabled=personnel>=Orders.MAX_PARTY
	var visit:=HBoxContainer.new();visit.add_theme_constant_override("separation",2);visit.custom_minimum_size.x=136;row.add_child(visit)
	var days_buttons:Dictionary={}
	for days:int in CivilizationSystem.SCOUT_DURATIONS:
		var choice:=UI.chip(visit,"1 yr" if days==365 else "%dd" % days,days==int(row_model.days),func()->void:_choose(id,"days",days),"Whole journey: out, watching and back")
		choice.name="Days%d" % days
		days_buttons[days]=choice
	var acts:=HBoxContainer.new();acts.add_theme_constant_override("separation",4);acts.custom_minimum_size.x=100;acts.alignment=BoxContainer.ALIGNMENT_END;row.add_child(acts)
	var once_blocked:=String(row_model.once_blocked)
	var watch:Dictionary=row_model.watch
	var changed:=bool(row_model.watching) and (int(watch.get("duration_days",0))!=int(row_model.days) or int(watch.get("personnel",0))!=personnel)
	var watch_blocked:=String(row_model.watch_blocked)
	var once:=UI.verb(acts,"Send",func()->void:_order(id,"once"),once_blocked if once_blocked!="" else "%s
%s" % [String(row_model.cost),String(row_model.risk)],true);once.name="SendOnce"
	once.disabled=once_blocked!=""
	var keep:=UI.verb(acts,"Update" if changed else "Watch",func()->void:_order(id,"watch"),"Staff send one party at a time, and the next after each return. Word still travels home; there is no live view.");keep.name="KeepWatching"
	keep.visible=not bool(row_model.watching) or changed
	keep.disabled=watch_blocked!=""
	if keep.disabled:keep.tooltip_text=watch_blocked
	var stop:=UI.verb(acts,"Stop",func()->void:_order(id,"stop"),"No further departures. A party already away finishes and comes home.");stop.name="StopWatching"
	stop.visible=bool(row_model.watching)
	# Barred orders: the buttons stay, greyed, with the reason in their pointer;
	# a reached limit (six watched) or an order's answer is one line under the row.
	var lines:PackedStringArray=[]
	var warn:=false
	if city_feedback.has(id):
		lines.append(String(city_feedback[id].text));warn=bool(city_feedback[id].error)
	elif keep.disabled and not bool(row_model.watching) and watch_blocked!=once_blocked:
		lines.append("Watch: "+watch_blocked);warn=true
	var note:=UI.label(cities_box,"  ".join(lines),12,T.AMBER_TEXT if warn else T.INK_MUTED);note.name="Note_"+id.validate_node_name()
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.visible=not lines.is_empty()
	if once_blocked!="" and once_blocked==watch_blocked:
		note.text=once_blocked
		UI.tag(name_cell,"out of reach","muted").tooltip_text=once_blocked
	var cost:=Label.new();cost.text=String(row_model.cost) if once_blocked=="" else "";cost.visible=false
	var risk:=Label.new();risk.text=String(row_model.risk) if once_blocked=="" else "";risk.visible=false
	row.add_child(cost);row.add_child(risk)
	city_rows[id]={"row":row,"name":name_label,"status":status,"meta":meta,"count":count,"minus":minus,"plus":plus,"days":days_buttons,
		"cost":cost,"risk":risk,"once":once,"keep":keep,"stop":stop,"note":note}

func _choose(id:String,key:String,value:int)->void:
	city_choice[id][key]=Orders.clamp_party(value) if key=="personnel" else value
	city_feedback.erase(id)
	_fill_cities()

func _order(id:String,kind:String)->void:
	var choice:Dictionary=city_choice.get(id,{})
	var result:Dictionary
	if kind=="once":result=Orders.send_once(id,int(choice.days),int(choice.personnel))
	elif kind=="watch":result=Orders.keep_watching(id,int(choice.days),int(choice.personnel))
	else:result=Orders.stop_watching(id)
	if result.has("error"):city_feedback[id]={"text":String(result.error),"error":true}
	elif kind=="once":city_feedback[id]={"text":"%d scouts have left. Their report comes when they do." % int(choice.personnel),"error":false}
	else:city_feedback[id]={"text":String(result.get("message","")),"error":false}
	_fill_cities();_fill_send()

# ------------------------------------------------------------- every telling

func _build_tellings_frame()->void:
	var head:=UI.heading(tellings_box,"Every telling","")
	counter=head.get_node("Note") if head.has_node("Note") else null
	if counter==null:
		counter=T.make_label("",12,T.INK_MUTED);counter.name="Note";head.add_child(counter)
	var bar:=UI.line(tellings_box,6)
	search=LineEdit.new();search.name="ReportSearch";search.placeholder_text="Search a place, a find or a people";search.clear_button_enabled=true
	search.custom_minimum_size=Vector2(110,26);search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search.add_theme_font_size_override("font_size",13);search.add_theme_color_override("font_color",T.INK)
	var field:=T.flat(T.FIELD_BG,T.RULE,1,T.RADIUS_CONTROL);field.content_margin_left=8
	search.add_theme_stylebox_override("normal",field);search.add_theme_stylebox_override("focus",T.flat(T.FIELD_BG,T.GOLD,1,T.RADIUS_CONTROL,8))
	search.text=String(view.get("query",""))
	bar.add_child(search)
	search.text_changed.connect(func(value:String)->void:view.query=value;view.page=0;_fill_rows())
	var filters:=HBoxContainer.new();filters.name="Filters";filters.add_theme_constant_override("separation",4);bar.add_child(filters)
	var order:=UI.chip(bar,"Newest",int(view.get("order",1))==1,func()->void:view.order=0 if int(view.get("order",1))==1 else 1;view.page=0;_fill_tellings(),"Newest first, or the weightiest first")
	order.name="Order"
	previous=UI.verb(bar,"‹",func()->void:view.page=int(view.page)-1;_fill_rows(),"Newer page");previous.name="PreviousReports"
	next=UI.verb(bar,"›",func()->void:view.page=int(view.page)+1;_fill_rows(),"Older page");next.name="NextReports"
	var columns:=UI.line(tellings_box)
	columns.name="Columns"
	for spec:Array in [["When",96],["",22],["What came home",0],["Where",96],["",64]]:
		var title:=UI.cell(columns,String(spec[0]),float(spec[1]),12,T.INK_MUTED,true)
		if int(spec[1])==0:title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	results=VBoxContainer.new();results.name="ReportResults";results.add_theme_constant_override("separation",0);tellings_box.add_child(results)

func _fill_tellings()->void:
	if tellings_box==null:return
	var filters:=tellings_box.find_child("Filters",true,false) as HBoxContainer
	if filters!=null:
		UI.clear(filters)
		for index in [0,1,3,4]:
			var chosen:=int(index)
			var name_text:=String(["All","Findings","Routine","Losses","Unread"][index])
			UI.chip(filters,name_text,int(view.get("filter",0))==index,func()->void:view.filter=chosen;view.page=0;_fill_tellings()).name="Filter_"+name_text
	var order:=tellings_box.find_child("Order",true,false) as Button
	if order!=null:order.set_pressed_no_signal(int(view.get("order",1))==1)
	_fill_rows()

## scout_archive.select, without writing every telling out to search it
## when nothing is searched for (the same filters and the same order).
static func select(reports:Array,query:String,filter_index:int,important_first:bool)->Array:
	if query.strip_edges()!="":return Archive.select(reports,query,filter_index,important_first)
	var selected:Array=[]
	for report:Dictionary in reports:
		var item:=Archive.summary(report)
		if filter_index==1 and not bool(item.meaningful): continue
		if filter_index==2 and (bool(item.meaningful) or int(item.losses)>0): continue
		if filter_index==3 and int(item.losses)==0: continue
		if filter_index==4 and item.review!="UNREAD": continue
		selected.append(item)
	selected.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if important_first and int(a.priority)!=int(b.priority): return int(a.priority)>int(b.priority)
		if int(a.day)!=int(b.day): return int(a.day)>int(b.day)
		return String(a.id)<String(b.id))
	return selected

func _fill_rows()->void:
	if results==null:return
	UI.clear(results)
	var reports:=_reports()
	var selected:=select(reports,String(view.get("query","")),int(view.get("filter",0)),int(view.get("order",1))==0)
	var pages:=maxi(1,ceili(float(selected.size())/PAGE))
	var page:=clampi(int(view.get("page",0)),0,pages-1);view.page=page
	previous.disabled=page==0;next.disabled=page>=pages-1
	counter.text=("%d–%d of %d" % [page*PAGE+1,mini(selected.size(),(page+1)*PAGE),selected.size()]) if not selected.is_empty() else "none match"
	visible_items=selected.slice(page*PAGE,(page+1)*PAGE)
	for item:Dictionary in visible_items:
		var report:Dictionary=item.report
		var row:=UI.hot_row(results,"Report_%s" % str(report.get("mission_id",0)),func()->void:open_report(report),"%s\n%s\n%s" % [String(item.title),String(item.place),String(item.detail)])
		UI.cell(row,Archive.calendar_date(int(item.day)),96,12,T.INK_MUTED)
		UI.icon(row,_kind(item),T.RED if int(item.losses)>0 else (T.GOLD if bool(item.meaningful) else T.INK_MUTED),18)
		UI.label(row,short_title(String(item.title)),13,T.INK if bool(item.meaningful) or int(item.losses)>0 else T.BODY,String(item.review)=="UNREAD",true)
		# Who went is in the row's pointer: the title gets the width.
		UI.cell(row,String(item.place).replace("Out to the ","").replace(" and back",""),96,12,T.BODY).tooltip_text=String(item.party)
		var state:=HBoxContainer.new();state.custom_minimum_size.x=64;state.alignment=BoxContainer.ALIGNMENT_END;row.add_child(state)
		if int(item.losses)>0:UI.tag(state,"lost %d" % int(item.losses),"danger")
		elif String(item.review)=="UNREAD":UI.tag(state,"unread","gold")
	if visible_items.is_empty():UI.label(results,"No telling matches",12,T.INK_MUTED)
