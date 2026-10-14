extends VBoxContainer
## THE SPIES PAGE (rail F3): our networks among other peoples and the watch
## for theirs among us, on paper like every other page.
##
## Nothing here is managed person by person. Top: one table row for each
## people we know: how hard we watch them (one choice of four), the
## network's strength, how many of ours are there, its last word and its
## risk (covert_ops.gd). Then the watch at home: one choice, the share
## watched against the share asked for, and the distrust it costs
## (eyes_corps.gd). The Pathfinder keeps both to the level set: who goes, who
## is taught, who is replaced. Below, one line each: what they sent home, how
## our errands ended, theirs we caught and those we hold (covert_ops.gd,
## captured_agents.gd). A killing or a burning stays a word at court.
##
## sections(), corps_view(), network_rows() and watch_rows() are the data
## (also read by tests).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI:=preload("res://scripts/hud/world_ui.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const Corps:=preload("res://scripts/eyes_corps.gd")
const REFRESH_SECONDS:=1.5
## The society's name by age (never "spies" early).
const SOCIETY:={"hearth":"The Listeners","lettered":"The Quiet Watch","reckoned":"The Service"}

var box:VBoxContainer
var clock:=0.0
var signature:=""
## The last answer to a button, shown under the buttons until the next press.
var answer:=""
var selected_network:=""
var record_kind:="learned"
var record_query:=""
var record_page:=0
var records_expanded:=false
var record_data:Array=[]
var record_entries:VBoxContainer
var record_count:Label
var record_previous:Button
var record_next:Button
var overview:BoxContainer

func setup()->void:
	name="CovertBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	box=VBoxContainer.new(); box.add_theme_constant_override("separation",10); add_child(box)
	resized.connect(_layout_overview)
	if "--capture-covert-sample" in OS.get_cmdline_user_args(): capture_sample()
	refresh(true)


## Capture only ("--capture-covert-sample"; never saved, captures run isolated):
## a watch at home part built, a settled network among one people we know and
## none among another.
static func capture_sample()->void:
	var ops:Dictionary=Covert.state()
	if ops.has("capture_sample"): return
	ops["capture_sample"]=true
	var corps:Dictionary=Corps.state()
	corps.eyes.merge({"policy":"few","members":2.0,"craft":0.62,"training":[{"count":1.0,"done":int(GameState.elapsed_days)+60}]},true)
	corps["watch"]=2
	corps.wary.merge({"members":Corps.watch_wanted(2)*0.7,"craft":0.55},true)
	corps["distrust"]=0.08
	var day:=int(GameState.elapsed_days); var shown:=0
	if not ops.get("reach") is Dictionary: ops["reach"]={}
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary or String((c as Dictionary).get("id","")) in ["","player"]: continue
		var civ:Dictionary=c
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		relation["contact_level"]=2; relation["home_location_known"]=true; civ["player_relation"]=relation
		(ops.reach as Dictionary)[String(civ.id)]=2 if shown==0 else 0
		if shown==0:
			for i in 3: (ops.ops as Array).append({"kind":"plant","stage":"in_place","civ_id":String(civ.id),"agent_name":"","cover":"trader","civ_name":String(civ.get("name","")),"target_desc":"Live among them","start_day":day-365*(4-i)-30,"settled_day":day-365*(4-i),"recruits":2-i,"odds":{"caught":0.04},"report_day":day+9000,"next_report":day+9000,"seed":"capture:%d" % i})
		shown+=1
		if shown>=2: break


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS: return
	clock=0.0
	refresh()


## Our two corps for the seals: {stage, eyes:{...}, wary:{...}, distrust,
## cohesion_cost, course_days, course_food, cap} (eyes_corps.gd summary).
static func corps_view()->Dictionary:
	return Corps.summary()


## The board's data, newest first: [{kind, title, rows:[String], tone}].
## kind: "abroad", "learned", "outcomes", "caught"; "empty" when nothing.
static func sections()->Array:
	var out:Array=[]
	var eyes:=Corps.word("eyes")
	var learned:=Covert.learned(maxi(1,(Covert.state().learned as Array).size()))
	if not learned.is_empty():
		var rows2:Array=[]
		for f:Dictionary in learned: rows2.append("%s — %s%s" % [String(f.fact),_age(int(f.age_days)),(" · FALSE: "+String(f.get("found_by",""))) if bool(f.get("found_false",false)) else ""])
		out.append({"kind":"learned","title":"What they sent home","rows":rows2})
	var outcomes:=Covert.outcomes(maxi(1,(Covert.state().ops as Array).size()))
	if not outcomes.is_empty():
		var rows3:Array=[]
		for o:Dictionary in outcomes: rows3.append("%s (%s)" % [String(o.line),_age(int(o.age_days))])
		out.append({"kind":"outcomes","title":"How our errands ended","rows":rows3})
	var caught:=Covert.caught_spies(maxi(1,(Covert.state().caught as Array).size()))
	if not caught.is_empty():
		var rows4:Array=[]
		for c:Dictionary in caught: rows4.append("%s%s of %s, %s%s" % [(String(c.name)+", ") if String(c.get("name",""))!="" else "",("an assassin" if String(c.kind)=="assassinate" else Corps.an_eye()),String(c.civ_name),_age(int(c.age_days)),(" · "+String(c.fate)) if String(c.fate)!="" else ""])
		out.append({"kind":"caught","title":"Theirs we found among us","rows":rows4})
	# Those we hold, what they said (a word our own eyes showed false is
	# marked), and ours judged abroad (captured_agents.gd).
	var Held:=preload("res://scripts/captured_agents.gd")
	var held:=Held.board_rows(Held.RECORDS_MAX*(Held.SAID_MAX+1)+Held.ABROAD_MAX)
	var held_name:=""
	for index in held.size():
		var line:=String(held[index])
		if line.begins_with("   said:"):held[index]=held_name+" "+line.strip_edges()
		else:held_name=line.get_slice(",",0)
	if not held.is_empty(): out.append({"kind":"prisoners","title":"Those we hold, and what they said","rows":held})
	return out


## One row for each people we know: how hard we watch them (the ruler's one
## choice) and what the network there is, in the engine's numbers.
## [{civ_id, name, level, wanted, placed, on_way, recruits, years, strength,
##   last_word_days, risk, barred, words}].
static func network_rows()->Array:
	var out:Array=[]
	if WorldSimulation.world==null: return out
	var eyes:=Corps.word("eyes")
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary: continue
		var civ:Dictionary=c
		var id:=String(civ.get("id",""))
		if id=="" or id=="player" or not bool(civ.get("alive",true)): continue
		var rel:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		if int(rel.get("contact_level",0))<1: continue
		var n:=Covert.network(id)
		var level:=Covert.network_level(id)
		var barred:=Covert.method_barred("plant")
		if barred=="" and not Covert.knows_where(id): barred=Covert.unplaced_words(id)
		var on_way:=Covert._network_placed(id)-int(n.eyes)
		var words:=""
		if int(n.eyes)<=0 and on_way<=0: words=barred if barred!="" else ("We keep no watch among them." if level==0 else "The network is being started.")
		else:
			var parts:PackedStringArray=[]
			if int(n.eyes)<=0: parts.append("The network is on its way there")
			else:
				parts.append("Network strength %d in 100" % roundi(float(n.strength)*100.0))
				parts.append("there %s" % ("under a year" if float(n.years)<1.0 else "%d years" % roundi(float(n.years))))
				parts.append("no word yet" if int(n.last_word_days)<0 else "last word %s" % _age(int(n.last_word_days)))
				parts.append("risk of being found %s" % _risk_words(float(n.risk)))
				var body:="%d of ours there" % int(n.eyes)
				if on_way>0: body+=", %d more on the way" % on_way
				if int(n.recruits)>0: body+=", %d of theirs won over" % int(n.recruits)
				parts.append(body)
			words=" · ".join(parts)
			if barred!="": words+=". It cannot grow: "+barred
		out.append({"civ_id":id,"name":String(civ.get("name",id)),"level":level,"wanted":int(Covert.NETWORK_EYES[level]),"placed":int(n.eyes),"on_way":on_way,"recruits":int(n.recruits),
			"years":float(n.years),"strength":float(n.strength),"last_word_days":int(n.last_word_days),"risk":float(n.risk),"barred":barred,"words":words,"eyes_word":eyes})
	return out


## Sets how hard we watch one people. Returns the Pathfinder's answer.
func set_network(civ_id:String,level:int)->String:
	answer=Covert.set_network_level(civ_id,level)
	refresh(true)
	return answer


## Our networks: a row for each people we know, one choice each.
static func abroad_words(view:Dictionary)->String:
	var placed:=Covert._network_placed(); var wanted:=Covert.network_wanted()
	var c:Dictionary=view.eyes
	if wanted<=0 and placed<=0 and float(c.members)<1.0 and float(c.training)<1.0: return ""
	var parts:PackedStringArray=["All our networks together: %d of ours abroad or on the way, of the %d they ask for" % [placed,wanted]]
	if roundi(float(c.members))>0: parts.append("%d taught and waiting" % roundi(float(c.members)))
	if roundi(float(c.training))>0: parts.append("%d learning" % roundi(float(c.training)))
	if float(c.members)>0.0: parts.append("craft %d in 100" % roundi(float(c.craft)*100.0))
	return " · ".join(parts)+"."


## The four levels of the watch at home, with what each means in the engine's
## numbers: [{level, label, active, share, wanted, words}].
static func watch_rows()->Array:
	var out:Array=[]
	var now:=Corps.watch_level()
	for level in 4:
		var share:=float(Corps.WATCH_SHARE[level])
		var wanted:=Corps.watch_wanted(level)
		var words:="Keep no watch at home. No one is taken from other work, and no distrust is bred."
		if level>0: words="Watch about %d in 100 of our people for theirs: %s kept at it, away from other work at %s food a day each. The people's trust in one another falls by up to %d in 100." % [roundi(share*100.0),_kept(wanted),_n(Corps.KEEP_FOOD),roundi(share*Corps.WATCH_DISTRUST*Corps.COHESION_COST*100.0)]
		out.append({"level":level,"label":String(Corps.WATCH_NAMES[level]),"active":level==now,"share":share,"wanted":wanted,"words":words})
	return out


## Sets how hard we watch our own people, as the Pathfinder's order would.
func set_watch(level:int)->String:
	var done:=preload("res://scripts/court_eyes_orders.gd").perform({"corps":"wary","policy":String(Corps.POLICY_ORDER[clampi(level,0,3)])})
	answer=String(done.get("says",""))
	refresh(true)
	return answer


## The watch at home: one choice, the share watched and what it costs.
static func _kept(n:float)->String:
	if n<0.75: return "part of one person's days"
	return "about %d of ours" % maxi(1,roundi(n))


static func _risk_words(risk:float)->String:
	if risk<=0.05: return "slight"
	if risk<=0.12: return "about 1 in 10"
	if risk<=0.3: return "about 1 in 4"
	if risk<=0.5: return "about even"
	return "high"


static func _age(days:int)->String:
	if days<=0: return "today"
	if days==1: return "yesterday"
	if days<14: return "%d days ago" % days
	if days<60: return "%d weeks ago" % maxi(1,roundi(days/7.0))
	if days<548: return "%d months ago" % maxi(1,roundi(days/30.0))
	return "%d years ago" % roundi(days/365.0)


static func _n(v:float)->String:
	return ("%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(".")


static func _rounded(view:Dictionary)->Array:
	var out:=[String(view.stage),roundi(float(view.distrust)*100.0),int(view.watch),roundi(float(view.coverage)*100.0)]
	for corps in ["eyes","wary"]:
		var c:Dictionary=view[corps]
		out.append([String(c.policy),roundi(float(c.members)),roundi(float(c.training)),roundi(float(c.craft)*20.0)])
	return out


func refresh(force:=false)->void:
	var data:=sections()
	var view:=corps_view()
	var rows:=network_rows()
	var sig:=str([data,_rounded(view),answer,rows])
	if not force and sig==signature: return
	var focused:=get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if not force and focused is LineEdit and box.is_ancestor_of(focused):return
	# Do not rebuild under the pointer (a click is informing).
	if not force and is_instance_valid(box) and box.get_global_rect().has_point(box.get_global_mouse_position()): return
	signature=sig
	UI.clear(box)
	if answer!="":
		var said:=Label.new();said.name="Answer";said.text=answer
		said.add_theme_font_override("font",T.voice_font(true));said.add_theme_font_size_override("font_size",15);said.add_theme_color_override("font_color",T.BODY)
		said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		box.add_child(said)
	# Reading the archive gives the records the whole page. The overview keeps
	# reports beside the two decisions, with the reports first on small windows.
	overview=null
	if records_expanded:
		_record_browser(data,box)
	else:
		overview=BoxContainer.new();overview.name="IntelligenceOverview"
		overview.add_theme_constant_override("separation",12);box.add_child(overview)
		var reports:=VBoxContainer.new();reports.size_flags_horizontal=Control.SIZE_EXPAND_FILL;overview.add_child(reports)
		_record_browser(data,reports)
		if data.is_empty():UI.label(reports,"Nothing has come back yet",14,T.INK_MUTED,false,true)
		var decisions:=VBoxContainer.new();decisions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		decisions.add_theme_constant_override("separation",10);overview.add_child(decisions)
		_networks(rows,view,decisions)
		_home(view,decisions)
		_layout_overview()

func _layout_overview()->void:
	if is_instance_valid(overview):overview.vertical=size.x<720

## One selected network; every known people remains in the chooser.
func _networks(rows:Array,view:Dictionary,parent:Container)->void:
	var column:=UI.sheet(parent,"Networks",12)
	column.add_theme_constant_override("separation",8)
	var head:=UI.heading(column,"Networks abroad")
	head.tooltip_text="Choose how hard we watch each people; the Pathfinder picks who goes, replaces any who are found and teaches as many as it takes. A killing or a burning among them is a word at court: the war leader answers for it.\n"+abroad_words(view)
	UI.label(column,abroad_short(view),14,T.INK_MUTED,false,true)
	if rows.is_empty():
		UI.label(column,"We know no other people yet",12,T.INK_MUTED)
		return
	var selector:=OptionButton.new();selector.name="NetworkPeople";T.apply_button_style(selector)
	selector.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var selected_index:=0
	for index in rows.size():
		selector.add_item(String(rows[index].name))
		if String(rows[index].civ_id)==selected_network:selected_index=index
	selected_network=String(rows[selected_index].civ_id);selector.select(selected_index);column.add_child(selector)
	selector.item_selected.connect(func(index:int)->void:selected_network=String(rows[index].civ_id);refresh(true))
	for r:Dictionary in rows:
		if String(r.civ_id)!=selected_network:continue
		var card:=VBoxContainer.new();card.name="People_"+String(r.civ_id);card.add_theme_constant_override("separation",8);column.add_child(card)
		var choices:=HFlowContainer.new();choices.add_theme_constant_override("h_separation",8);choices.add_theme_constant_override("v_separation",8);card.add_child(choices)
		for level in 4:
			var civ_id:=String(r.civ_id);var chosen:=level
			var b:=UI.chip(choices,String(Covert.NETWORK_NAMES[level]),level==int(r.level),func()->void:set_network(civ_id,chosen),_level_words(level))
			b.name="Network_%s_%d" % [String(r.civ_id),level]
		var facts:=HFlowContainer.new();facts.add_theme_constant_override("h_separation",20);facts.add_theme_constant_override("v_separation",8);card.add_child(facts)
		if int(r.placed)>0 or int(r.on_way)>0:
			var strength_group:=UI.line(facts)
			UI.label(strength_group,"Strength %d%%" % roundi(float(r.strength)*100.0),14,T.INK)
			var strength:=UI.bar(strength_group,float(r.strength),T.TEAL,72);strength.name="Strength_"+String(r.civ_id)
			strength.tooltip_text="It grows with the years it has lived there and the locals it wins over."
			UI.label(facts,"%d of ours · %d on the way" % [int(r.placed),int(r.on_way)],14,T.INK_MUTED).tooltip_text="%d of theirs won over" % int(r.recruits)
			UI.label(facts,"No word yet" if int(r.last_word_days)<0 else "Last word "+_age(int(r.last_word_days)),14,T.INK_MUTED)
			if int(r.placed)>0:UI.tag(facts,"Found: "+_risk_short(float(r.risk)),"danger" if float(r.risk)>0.3 else ("warn" if float(r.risk)>0.12 else "muted")).tooltip_text="Risk of being found: %s" % _risk_words(float(r.risk))
		else:
			UI.label(facts,"No watch among them" if int(r.level)==0 else "%d asked for · none there yet" % int(r.wanted),14,T.INK_MUTED)
		if String(r.barred)!="":UI.label(card,String(r.barred),14,T.AMBER_TEXT,false,true)

## What a level of watching buys, in the engine's numbers.
static func _level_words(level:int)->String:
	match level:
		1:return "%d of ours kept there: a little word, little risk" % int(Covert.NETWORK_EYES[1])
		2:return "%d kept there: steadier word, locals won over" % int(Covert.NETWORK_EYES[2])
		3:return "%d kept there, after their crafts too: the most word, the most found" % int(Covert.NETWORK_EYES[3])
	return "no watch among them"

## "3 of 6 ours abroad · 2 learning", for the heading.
static func abroad_short(view:Dictionary)->String:
	var placed:=Covert._network_placed(); var wanted:=Covert.network_wanted()
	var c:Dictionary=view.eyes
	var parts:PackedStringArray=["%d %s abroad · %d requested" % [placed,Corps.word("eyes").to_lower(),wanted]]
	if roundi(float(c.members))>0:parts.append("%s taught" % preload("res://scripts/hud/era_words.gd").grouped(roundi(float(c.members))))
	if roundi(float(c.training))>0:parts.append("%d learning" % roundi(float(c.training)))
	return " · ".join(parts)

static func _risk_short(risk:float)->String:
	if risk<=0.05: return "rarely"
	if risk<=0.12: return "1 in 10"
	if risk<=0.3: return "1 in 4"
	if risk<=0.5: return "even"
	return "likely"

## The watch at home: one choice, the share watched and what it costs.
func _home(view:Dictionary,parent:Container)->void:
	var c:Dictionary=view.wary
	var column:=UI.sheet(parent,"Home",12)
	column.add_theme_constant_override("separation",8)
	var cost:=roundi(float(view.cohesion_cost)*100.0)
	var head:=UI.heading(column,"Watch at home")
	head.tooltip_text="Ours who watch for theirs among us. A harder watch catches more, but the people start wondering who reports on whom. The Pathfinder finds and teaches as many as it takes, and sends the rest back to other work. Distrust is what it costs, in points of 100 of their trust in one another."
	var row:=VBoxContainer.new();row.add_theme_constant_override("separation",8);column.add_child(row)
	var have:=roundi(float(view.coverage)*100.0); var aim:=roundi(float(view.watch_share)*100.0)
	var reading:=HFlowContainer.new();reading.add_theme_constant_override("h_separation",10);row.add_child(reading)
	var coverage:=UI.bar(reading,float(view.coverage)/maxf(0.01,float(view.watch_share)) if aim>0 else 0.0,T.TEAL,64)
	coverage.name="Coverage"
	coverage.tooltip_text="Watching %d in 100 of our people; this level asks for %d." % [have,aim]
	var chips:=HFlowContainer.new();chips.add_theme_constant_override("h_separation",8);chips.add_theme_constant_override("v_separation",8);row.add_child(chips)
	var lit:=""
	for watch:Dictionary in watch_rows():
		var chosen:=int(watch.level)
		var b:=UI.chip(chips,String(watch.label),bool(watch.active),func()->void:set_watch(chosen),String(watch.words))
		b.name="Watch_%d" % int(watch.level)
		if bool(watch.active):lit=String(watch.words)
	var now:=UI.label(reading,"%d in 100 watched%s" % [have,("" if have==aim else (" of %d asked" % aim))],14,T.BODY)
	if cost>0:UI.label(reading,"Trust −%d" % cost,14,T.RED_TEXT if cost>=2 else T.INK_MUTED)
	now.name="Watching"
	now.tooltip_text=lit+(("\nCraft %d in 100." % roundi(float(c.craft)*100.0)) if float(c.members)>0.0 else "")

## A short report digest; the archive is an explicit, bounded reading mode.
func _record_browser(data:Array,parent:Container)->void:
	record_data=data
	if data.is_empty():return
	if not data.any(func(part:Dictionary)->bool:return String(part.kind)==record_kind):record_kind=String(data[0].kind)
	var column:=UI.sheet(parent,"Records",12)
	column.add_theme_constant_override("separation",8)
	var head:=UI.heading(column,"Intelligence records" if records_expanded else "Latest intelligence")
	var browse:=UI.verb(head,"Back to latest" if records_expanded else "Browse records",func()->void:
		records_expanded=not records_expanded;record_page=0;refresh(true))
	browse.name="BrowseRecords"
	var categories:=HFlowContainer.new();categories.add_theme_constant_override("h_separation",8);categories.add_theme_constant_override("v_separation",4);column.add_child(categories)
	var names:={"learned":"Reports","outcomes":"Operations","caught":"Caught here","prisoners":"In custody"}
	for section:Dictionary in data:
		var kind:=String(section.kind)
		var choose:=UI.chip(categories,"%s · %d" % [String(names.get(kind,section.title)),section.rows.size()],kind==record_kind,func()->void:
			record_kind=kind;record_page=0;refresh(true))
		choose.name="Records_"+kind
	if records_expanded:
		var search:=LineEdit.new();search.name="RecordSearch";search.placeholder_text="Search these records";search.text=record_query
		search.custom_minimum_size.y=40;column.add_child(search)
		search.text_changed.connect(func(value:String)->void:record_query=value;record_page=0;_fill_record_entries())
	record_entries=VBoxContainer.new();record_entries.name="RecordEntries";record_entries.add_theme_constant_override("separation",10);column.add_child(record_entries)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",8);column.add_child(footer)
	record_count=UI.label(footer,"",14,T.INK_MUTED,false,true)
	record_previous=UI.verb(footer,"Previous",func()->void:record_page-=1;_fill_record_entries())
	record_next=UI.verb(footer,"Next",func()->void:record_page+=1;_fill_record_entries())
	_fill_record_entries()

func _fill_record_entries()->void:
	UI.clear(record_entries)
	var all:Array=[]
	for section:Dictionary in record_data:
		if String(section.kind)==record_kind:all=section.rows;break
	var matching:=all.filter(func(entry:Variant)->bool:return not records_expanded or record_query.strip_edges().is_empty() or String(entry).to_lower().contains(record_query.strip_edges().to_lower()))
	var limit:=6 if records_expanded else 3
	var pages:=maxi(1,ceili(float(matching.size())/float(limit)))
	record_page=clampi(record_page,0,pages-1) if records_expanded else 0
	var start:=record_page*limit
	for index in range(start,mini(start+limit,matching.size())):
		var words:=UI.label(record_entries,String(matching[index]),16,T.BODY,false,true)
		words.name="Report_%d" % index
	if matching.is_empty():UI.label(record_entries,"No matching records",14,T.INK_MUTED)
	record_count.text=("%d–%d of %d matching · %d total" % [start+1,mini(start+limit,matching.size()),matching.size(),all.size()]) if records_expanded and not matching.is_empty() else ("No matches · %d total" % all.size() if records_expanded else "Latest %d of %d records" % [mini(limit,matching.size()),all.size()])
	record_previous.visible=records_expanded;record_next.visible=records_expanded
	record_previous.disabled=record_page<=0;record_next.disabled=record_page>=pages-1
