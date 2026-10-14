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
## The peoples shown at most.
const MAX_PEOPLES:=8
## The society's name by age (never "spies" early).
const SOCIETY:={"hearth":"The Listeners","lettered":"The Quiet Watch","reckoned":"The Service"}

var box:VBoxContainer
var clock:=0.0
var signature:=""
## The last answer to a button, shown under the buttons until the next press.
var answer:=""

func setup()->void:
	name="CovertBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	box=VBoxContainer.new(); box.add_theme_constant_override("separation",10); add_child(box)
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
	var learned:=Covert.learned(10)
	if not learned.is_empty():
		var rows2:Array=[]
		for f:Dictionary in learned: rows2.append("%s — %s%s" % [String(f.fact),_age(int(f.age_days)),(" · FALSE: "+String(f.get("found_by",""))) if bool(f.get("found_false",false)) else ""])
		out.append({"kind":"learned","title":"What they sent home","rows":rows2})
	var outcomes:=Covert.outcomes(6)
	if not outcomes.is_empty():
		var rows3:Array=[]
		for o:Dictionary in outcomes: rows3.append("%s (%s)" % [String(o.line),_age(int(o.age_days))])
		out.append({"kind":"outcomes","title":"How our errands ended","rows":rows3})
	var caught:=Covert.caught_spies(6)
	if not caught.is_empty():
		var rows4:Array=[]
		for c:Dictionary in caught: rows4.append("%s%s of %s, %s%s" % [(String(c.name)+", ") if String(c.get("name",""))!="" else "",("an assassin" if String(c.kind)=="assassinate" else Corps.an_eye()),String(c.civ_name),_age(int(c.age_days)),(" · "+String(c.fate)) if String(c.fate)!="" else ""])
		out.append({"kind":"caught","title":"Theirs we found among us","rows":rows4})
	# Those we hold, what they said (a word our own eyes showed false is
	# marked), and ours judged abroad (captured_agents.gd).
	var held:=preload("res://scripts/captured_agents.gd").board_rows(6)
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
		if out.size()>=MAX_PEOPLES: break
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
	# Do not rebuild under the pointer (a click is informing).
	if not force and is_instance_valid(box) and box.get_global_rect().has_point(box.get_global_mouse_position()): return
	signature=sig
	UI.clear(box)
	if answer!="":
		var said:=Label.new();said.name="Answer";said.text=answer
		said.add_theme_font_override("font",T.voice_font(true));said.add_theme_font_size_override("font_size",15);said.add_theme_color_override("font_color",T.BODY)
		said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		box.add_child(said)
	_networks(rows,view)
	_home(view)
	var grid:=UI.columns(box,"Records")
	grid.columns=3 if size.x>=800.0 else 2
	for section:Dictionary in data:_records(grid,section)
	if data.is_empty():UI.label(box,"Nothing has come back yet",12,T.INK_MUTED)

## Our networks: one row for each people we know, one choice each.
func _networks(rows:Array,view:Dictionary)->void:
	var column:=UI.sheet(box,"Networks")
	var head:=UI.heading(column,"Networks abroad",abroad_short(view))
	head.tooltip_text="Choose how hard we watch each people; the Pathfinder picks who goes, replaces any who are found and teaches as many as it takes. A killing or a burning among them is a word at court: the war leader answers for it.\n"+abroad_words(view)
	if rows.is_empty():
		UI.label(column,"We know no other people yet",12,T.INK_MUTED)
		return
	# Until a network stands anywhere, no columns of zeros: each row says what
	# its chosen level buys.
	var standing:=false
	for r:Dictionary in rows:standing=standing or int(r.placed)>0 or int(r.on_way)>0
	if not standing:
		for r:Dictionary in rows:
			var row:=UI.line(column,6);row.name="People_"+String(r.civ_id)
			var who:=UI.label(row,String(r.name),13,T.INK,true);who.custom_minimum_size.x=96
			var chips:=HBoxContainer.new();chips.add_theme_constant_override("separation",3);row.add_child(chips)
			for level in 4:
				var civ_id:=String(r.civ_id);var chosen:=level
				var b:=UI.chip(chips,String(Covert.NETWORK_NAMES[level]),level==int(r.level),func()->void:set_network(civ_id,chosen),_level_words(level))
				b.name="Network_%s_%d" % [String(r.civ_id),level]
			var buys:=UI.label(row,_level_words(int(r.level)) if String(r.barred)=="" else String(r.barred),12,T.BODY if String(r.barred)=="" else T.AMBER_TEXT,false,true)
			buys.tooltip_text=String(r.words)
		return
	var titles:=UI.line(column,6)
	UI.label(titles,"",12,T.INK_MUTED,true,true).custom_minimum_size.x=96
	UI.cell(titles,"Strength",64,12,T.INK_MUTED,true)
	UI.cell(titles,"How hard we watch",236,12,T.INK_MUTED,true)
	UI.cell(titles,"Ours",44,12,T.INK_MUTED,true,HORIZONTAL_ALIGNMENT_RIGHT)
	UI.cell(titles,"Last word",80,12,T.INK_MUTED,true)
	UI.cell(titles,"Found",54,12,T.INK_MUTED,true)
	for r:Dictionary in rows:
		var row:=UI.line(column,6);row.name="People_"+String(r.civ_id)
		row.tooltip_text=String(r.words)
		var who:=UI.label(row,String(r.name),13,T.INK,true,true);who.custom_minimum_size.x=96;who.tooltip_text=String(r.words)
		if String(r.barred)!="":UI.tag(row,"stuck","warn").tooltip_text=String(r.barred)
		var strength:=UI.bar(row,float(r.strength),T.TEAL,64)
		strength.name="Strength_"+String(r.civ_id)
		strength.tooltip_text="Network strength %d in 100. It grows with the years it has lived there and the locals it wins over." % roundi(float(r.strength)*100.0)
		var chips:=HBoxContainer.new();chips.add_theme_constant_override("separation",3);chips.custom_minimum_size.x=236;row.add_child(chips)
		for level in 4:
			var civ_id:=String(r.civ_id);var chosen:=level
			var tip:String=["Keep no watch among them.","A thin network (%d of ours kept there): a little word, little risk." % int(Covert.NETWORK_EYES[1]),"A settled network (%d of ours kept there): steadier word, and locals won over." % int(Covert.NETWORK_EYES[2]),"A deep network (%d of ours kept there) that also goes after their crafts: the most word, and the most of ours found." % int(Covert.NETWORK_EYES[3])][level]
			var b:=UI.chip(chips,String(Covert.NETWORK_NAMES[level]),level==int(r.level),func()->void:set_network(civ_id,chosen),tip)
			b.name="Network_%s_%d" % [String(r.civ_id),level]
		var ours:="%d" % int(r.placed)+(("+%d" % int(r.on_way)) if int(r.on_way)>0 else "")
		UI.cell(row,ours,44,13,T.INK,true,HORIZONTAL_ALIGNMENT_RIGHT).tooltip_text="%d of ours there%s%s" % [int(r.placed),(", %d on the way" % int(r.on_way)) if int(r.on_way)>0 else "",(", %d of theirs won over" % int(r.recruits)) if int(r.recruits)>0 else ""]
		UI.cell(row,"—" if int(r.placed)<=0 else ("none yet" if int(r.last_word_days)<0 else _age(int(r.last_word_days)).replace(" ago","")),80,12,T.BODY)
		var found:=HBoxContainer.new();found.custom_minimum_size.x=54;row.add_child(found)
		if int(r.placed)>0:UI.tag(found,_risk_short(float(r.risk)),"danger" if float(r.risk)>0.3 else ("warn" if float(r.risk)>0.12 else "muted")).tooltip_text="Risk of being found: %s" % _risk_words(float(r.risk))

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
	var parts:PackedStringArray=["%d of %d ours abroad" % [placed,wanted]]
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
func _home(view:Dictionary)->void:
	var c:Dictionary=view.wary
	var column:=UI.sheet(box,"Home")
	var cost:=roundi(float(view.cohesion_cost)*100.0)
	var head:=UI.heading(column,"%s: the watch at home" % Corps.word("Wary"),"distrust −%d" % cost if cost>0 else "",T.RED_TEXT if cost>=2 else T.INK_MUTED)
	head.tooltip_text="Ours who watch for theirs among us. A harder watch catches more, but the people start wondering who reports on whom. The Pathfinder finds and teaches as many as it takes, and sends the rest back to other work. Distrust is what it costs, in points of 100 of their trust in one another."
	var row:=UI.line(column,6)
	var who:=UI.label(row,"Our own people",13,T.INK,true,true);who.custom_minimum_size.x=96
	var have:=roundi(float(view.coverage)*100.0); var aim:=roundi(float(view.watch_share)*100.0)
	var coverage:=UI.bar(row,float(view.coverage)/maxf(0.01,float(view.watch_share)) if aim>0 else 0.0,T.TEAL,64)
	coverage.name="Coverage"
	coverage.tooltip_text="Watching %d in 100 of our people; this level asks for %d." % [have,aim]
	var chips:=HBoxContainer.new();chips.add_theme_constant_override("separation",3);chips.custom_minimum_size.x=236;row.add_child(chips)
	var lit:=""
	for watch:Dictionary in watch_rows():
		var chosen:=int(watch.level)
		var b:=UI.chip(chips,String(watch.label),bool(watch.active),func()->void:set_watch(chosen),String(watch.words))
		b.name="Watch_%d" % int(watch.level)
		if bool(watch.active):lit=String(watch.words)
	var now:=UI.label(row,"%d in 100 watched%s" % [have,("" if have==aim else (" of %d asked" % aim))],12,T.BODY,false,true)
	now.name="Watching"
	now.tooltip_text=lit+(("\nCraft %d in 100." % roundi(float(c.craft)*100.0)) if float(c.members)>0.0 else "")

## One kind of record (what came back, errands, caught, held): a line each.
func _records(parent:Node,section:Dictionary)->void:
	var column:=UI.sheet(parent,String(section.kind).capitalize())
	UI.heading(column,String(section.title),"%d" % (section.rows as Array).size())
	for text in section.rows:
		var line:=UI.label(column,String(text),12,T.BODY,false,true)
		line.tooltip_text=String(text)
		line.custom_minimum_size.y=22
