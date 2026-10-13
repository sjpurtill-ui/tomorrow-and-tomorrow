extends VBoxContainer
## THE HIDDEN FOLIO: the eyes and the wary, mounted on the War screen
## (hud/war_board.gd). In the early ages it reads as a secret society's book:
## night-dark vellum, gold leaf, an eye sigil ringed by cipher marks, and the
## society's name (The Listeners, then The Quiet Watch). In a reckoned age it
## turns to the service's terminal: phosphor green on black.
##
## Nothing here is managed person by person. Top: our networks abroad, one
## choice for each people we know (how hard we watch them) with the network's
## strength, its last word and its risk (covert_ops.gd). Then the watch at
## home: one choice (how hard we watch our own people for theirs) with the
## share watched and the distrust it costs (eyes_corps.gd). The Pathfinder
## keeps both to the level set: who goes, who is taught, who is replaced.
## Below: what they sent home, how our errands ended, theirs we caught, and
## those we hold (covert_ops.gd, captured_agents.gd). A killing or a burning
## stays a word at court: the war leader answers for it.
##
## sections(), corps_view(), network_rows() and watch_rows() are the data
## (also read by tests).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const Corps:=preload("res://scripts/eyes_corps.gd")
const REFRESH_SECONDS:=1.5
## The peoples shown at most.
const MAX_PEOPLES:=8

## The folio's inks by age: [page, raised, rule, leaf (titles and seals),
## text, muted text, danger].
const INKS:={
	"hearth":[Color("17130f"),Color("211b15"),Color("5c4a2a"),Color("d6ad55"),Color("eadcbf"),Color("b9a780"),Color("d9775f")],
	"lettered":[Color("141418"),Color("1d1d24"),Color("4f4a3a"),Color("cfae62"),Color("e6e0cf"),Color("b3ab92"),Color("d9775f")],
	"reckoned":[Color("060a07"),Color("0b130d"),Color("1f4a2c"),Color("4fd08a"),Color("c8f2d6"),Color("7fb894"),Color("f07a6a")],
}
const SOCIETY:={"hearth":"The Listeners","lettered":"The Quiet Watch","reckoned":"The Service"}
const MOTTO:={
	"hearth":"Those of ours who live unseen among other peoples, and those who watch for theirs among us.",
	"lettered":"Watchers kept among the strangers' towns, and gatekeepers set against theirs.",
	"reckoned":"Assets in place abroad, and the counter-intelligence that hunts theirs at home.",
}

var box:VBoxContainer
var clock:=0.0
var signature:=""
## The last answer to a button, shown under the buttons until the next press.
var answer:=""


## The eye sigil: an almond eye, its iris and pupil, a ring of rays and an
## outer ring of cipher marks (seeded, so the same marks always).
class Sigil extends Control:
	var leaf:=Color("d6ad55")
	var dark:=Color("17130f")
	var modern:=false
	func _init()->void:
		custom_minimum_size=Vector2(72,72)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		var c:=size*0.5
		var r:=minf(size.x,size.y)*0.5-2.0
		draw_arc(c,r,0.0,TAU,64,leaf,1.6,true)
		draw_arc(c,r-5.0,0.0,TAU,64,Color(leaf,0.55),1.0,true)
		# Cipher marks in the ring: short strokes and ticks, a fixed hand.
		var rng:=RandomNumberGenerator.new();rng.seed=4471
		for i in 24:
			var a:=TAU*float(i)/24.0
			var p:=c+Vector2.from_angle(a)*(r-2.5)
			var t:=Vector2.from_angle(a+PI*0.5)
			var n:=Vector2.from_angle(a)
			match rng.randi()%4:
				0: draw_line(p-n*2.0,p+n*2.0,leaf,1.2,true)
				1: draw_line(p-t*1.8,p+t*1.8,leaf,1.2,true)
				2: draw_circle(p,0.9,leaf)
				3: draw_line(p-n*2.0-t*1.2,p+n*2.0+t*1.2,leaf,1.2,true)
		# Rays.
		for i in 16:
			var a:=TAU*float(i)/16.0
			draw_line(c+Vector2.from_angle(a)*(r*0.5),c+Vector2.from_angle(a)*(r*0.66),Color(leaf,0.7),1.0,true)
		# The eye.
		var w:=r*0.62
		var h:=r*0.34
		var upper:=PackedVector2Array();var lower:=PackedVector2Array()
		for i in 25:
			var x:=lerpf(-w,w,float(i)/24.0)
			var y:=h*(1.0-pow(x/w,2.0))
			upper.append(c+Vector2(x,-y));lower.append(c+Vector2(x,y))
		draw_polyline(upper,leaf,1.6,true);draw_polyline(lower,leaf,1.6,true)
		draw_circle(c,h*0.82,leaf)
		draw_circle(c,h*0.42,dark)
		if modern: draw_rect(Rect2(c-Vector2(h*0.18,h*0.6),Vector2(h*0.36,h*1.2)),leaf)


## A row of marks: filled to a share (0..1), out of what can be reached.
class Marks extends Control:
	var value:=0.0
	var cap:=1.0
	var leaf:=Color("d6ad55")
	const COUNT:=10
	func _init()->void:
		custom_minimum_size=Vector2(COUNT*11,10)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		for i in COUNT:
			var at:=Vector2(5.0+float(i)*11.0,size.y*0.5)
			var share:=float(i+1)/float(COUNT)
			if share<=value+0.0001: draw_circle(at,3.2,leaf)
			elif share<=cap+0.0001: draw_arc(at,3.0,0.0,TAU,16,Color(leaf,0.6),1.0,true)
			else: draw_line(at-Vector2(2,0),at+Vector2(2,0),Color(leaf,0.3),1.0)


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
func _network_panel(rows:Array,view:Dictionary,ink:Array)->Control:
	var panel:=PanelContainer.new(); panel.name="Networks"
	var style:=StyleBoxFlat.new(); style.bg_color=ink[1]; style.border_color=ink[2]; style.set_border_width_all(1)
	style.set_corner_radius_all(T.RADIUS_CARD); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style)
	var col:=VBoxContainer.new(); col.add_theme_constant_override("separation",8); panel.add_child(col)
	col.add_child(_line("OUR NETWORKS ABROAD",12,ink[3],false,"ui_strong"))
	col.add_child(_line("Choose how hard we watch each people. That is the whole of it: the Pathfinder picks who goes, replaces any who are found and teaches as many as it takes.",13,ink[5],true))
	if rows.is_empty():
		col.add_child(_line("We know no other people yet. Our scouts must find them first.",13,ink[5],true,"voice_italic"))
		return panel
	for r:Dictionary in rows:
		var block:=VBoxContainer.new(); block.name="People_"+String(r.civ_id); block.add_theme_constant_override("separation",2); col.add_child(block)
		var line:=HBoxContainer.new(); line.add_theme_constant_override("separation",6); block.add_child(line)
		var who:=_line(String(r.name),15,ink[4],false,"ui_strong"); who.custom_minimum_size=Vector2(130,0); who.size_flags_horizontal=Control.SIZE_EXPAND_FILL; who.clip_text=true; line.add_child(who)
		var marks:=Marks.new(); marks.name="Strength_"+String(r.civ_id); marks.value=float(r.strength); marks.leaf=ink[3]; marks.size_flags_vertical=Control.SIZE_SHRINK_CENTER; line.add_child(marks)
		marks.tooltip_text="Network strength %d in 100. It grows with the years it has lived there and the locals it wins over." % roundi(float(r.strength)*100.0)
		for level in 4:
			var b:=_ink_button(String(Covert.NETWORK_NAMES[level]),level==int(r.level),ink)
			b.name="Network_%s_%d" % [String(r.civ_id),level]
			b.custom_minimum_size=Vector2(72,0)
			b.tooltip_text=["Keep no watch among them.","A thin network (%d of ours kept there): a little word, little risk." % int(Covert.NETWORK_EYES[1]),"A settled network (%d of ours kept there): steadier word, and locals won over." % int(Covert.NETWORK_EYES[2]),"A deep network (%d of ours kept there) that also goes after their crafts: the most word, and the most of ours found." % int(Covert.NETWORK_EYES[3])][level]
			var civ_id:=String(r.civ_id); var chosen:=level
			b.pressed.connect(func()->void: set_network(civ_id,chosen))
			line.add_child(b)
		block.add_child(_line(String(r.words),13,ink[5] if String(r.barred)=="" else ink[3],true))
	var kept:=abroad_words(view)
	if kept!="": var total:=_line(kept,12,ink[5],true); total.name="Abroad"; col.add_child(total)
	col.add_child(_line("A killing or a burning among them is a word at court: the war leader answers for it.",12,ink[5],true,"voice_italic"))
	return panel


## All our networks together, in one line ("" while none is asked for).
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
func _home_panel(view:Dictionary,ink:Array)->Control:
	var c:Dictionary=view.wary
	var panel:=PanelContainer.new(); panel.name="Home"
	var style:=StyleBoxFlat.new(); style.bg_color=ink[1]; style.border_color=ink[2]; style.set_border_width_all(1)
	style.set_corner_radius_all(T.RADIUS_CARD); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style)
	var col:=VBoxContainer.new(); col.add_theme_constant_override("separation",8); panel.add_child(col)
	col.add_child(_line(("%s: the watch at home" % Corps.word("Wary")).to_upper(),12,ink[3],false,"ui_strong"))
	col.add_child(_line("Choose how hard we watch our own people for theirs. The Pathfinder finds and teaches as many as it takes, and sends the rest back to other work.",13,ink[5],true))
	var block:=VBoxContainer.new(); block.add_theme_constant_override("separation",2); col.add_child(block)
	var line:=HBoxContainer.new(); line.add_theme_constant_override("separation",6); block.add_child(line)
	var who:=_line("Among our own people",15,ink[4],false,"ui_strong"); who.custom_minimum_size=Vector2(130,0); who.size_flags_horizontal=Control.SIZE_EXPAND_FILL; who.clip_text=true; line.add_child(who)
	var marks:=Marks.new(); marks.name="Coverage"; marks.value=float(view.coverage); marks.cap=float(view.watch_share); marks.leaf=ink[3]; marks.size_flags_vertical=Control.SIZE_SHRINK_CENTER; line.add_child(marks)
	marks.tooltip_text="Watching %d in 100 of our people; this level asks for %d." % [roundi(float(view.coverage)*100.0),roundi(float(view.watch_share)*100.0)]
	var lit:=""
	for row:Dictionary in watch_rows():
		var b:=_ink_button(String(row.label),bool(row.active),ink)
		b.name="Watch_%d" % int(row.level)
		b.custom_minimum_size=Vector2(72,0)
		b.tooltip_text=String(row.words)
		var chosen:=int(row.level)
		b.pressed.connect(func()->void: set_watch(chosen))
		line.add_child(b)
		if bool(row.active): lit=String(row.words)
	block.add_child(_line(lit,13,ink[5],true))
	var cost:=roundi(float(view.cohesion_cost)*100.0)
	var have:=roundi(float(view.coverage)*100.0); var aim:=roundi(float(view.watch_share)*100.0)
	var now:=PackedStringArray(["Now watching %d in 100 of our people%s" % [have,"" if have==aim else (", building toward %d" % aim if have<aim else ", easing back toward %d" % aim)]])
	if float(c.members)>0.0: now.append("craft %d in 100" % roundi(float(c.craft)*100.0))
	now.append("distrust costs %d in 100 of their trust in one another" % cost)
	var state:=_line(" · ".join(now),13,ink[6] if cost>=2 else ink[4],true); state.name="Watching"; block.add_child(state)
	panel.tooltip_text="Ours who watch for theirs among us. A harder watch catches more, but the people start wondering who reports on whom."
	return panel


## "about 12 of ours" or, for a small people, part of one person's days.
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


func refresh(force:=false)->void:
	var data:=sections()
	var view:=corps_view()
	var sig:=str([data,_rounded(view),answer,network_rows()])
	if not force and sig==signature: return
	# Do not rebuild under the pointer (a click is informing).
	if not force and is_instance_valid(box) and box.get_global_rect().has_point(box.get_global_mouse_position()): return
	signature=sig
	for child in box.get_children(): box.remove_child(child); child.queue_free()
	var stage:=String(view.stage)
	var ink:Array=INKS.get(stage,INKS.hearth)
	var folio:=PanelContainer.new(); folio.name="Folio"
	var style:=StyleBoxFlat.new(); style.bg_color=ink[0]; style.border_color=ink[3]; style.set_border_width_all(2)
	style.set_corner_radius_all(T.RADIUS_CARD); style.set_content_margin_all(16)
	folio.add_theme_stylebox_override("panel",style)
	box.add_child(folio)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",12); folio.add_child(column)
	column.add_child(_header(stage,ink))
	column.add_child(_cipher_rule(ink))
	if answer!="":
		var said:=_line(answer,13,ink[4],true,"voice_italic"); said.name="Answer"; column.add_child(said)
	column.add_child(_network_panel(network_rows(),view,ink))
	column.add_child(_home_panel(view,ink))
	column.add_child(_cipher_rule(ink))
	for section:Dictionary in data:
		if String(section.kind)=="empty":
			column.add_child(_line(String((section.rows as Array)[0]),14,ink[5],true,"voice_italic"))
			continue
		column.add_child(_panel(section,ink))


static func _rounded(view:Dictionary)->Array:
	var out:=[String(view.stage),roundi(float(view.distrust)*100.0),int(view.watch),roundi(float(view.coverage)*100.0)]
	for corps in ["eyes","wary"]:
		var c:Dictionary=view[corps]
		out.append([String(c.policy),roundi(float(c.members)),roundi(float(c.training)),roundi(float(c.craft)*20.0)])
	return out


func _header(stage:String,ink:Array)->Control:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",14)
	var sigil:=Sigil.new(); sigil.leaf=ink[3]; sigil.dark=ink[0]; sigil.modern=stage=="reckoned"; row.add_child(sigil)
	var words:=VBoxContainer.new(); words.size_flags_horizontal=Control.SIZE_EXPAND_FILL; words.add_theme_constant_override("separation",2); row.add_child(words)
	words.alignment=BoxContainer.ALIGNMENT_CENTER
	var title:=_line(String(SOCIETY.get(stage,SOCIETY.hearth)).to_upper(),22,ink[3],false,"display" if stage!="reckoned" else "ui_strong")
	words.add_child(title)
	words.add_child(_line(String(MOTTO.get(stage,MOTTO.hearth)),14,ink[5],true,"voice_italic" if stage!="reckoned" else "ui"))
	return row


func _cipher_rule(ink:Array)->Control:
	var rule:=_line("◦ ⟡ ◦ ✶ ◦ ⟡ ◦ ✶ ◦ ⟡ ◦" if ink!=INKS.reckoned else "// 01 ·· 10 ·· 01 ·· 10 //",12,Color(ink[3],0.7))
	rule.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return rule


## A button in the folio's inks; a lit one is the choice in force.
static func _ink_button(text:String,lit:bool,ink:Array)->Button:
	var b:=Button.new(); b.text=text; b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_override("font",T.font("ui_strong")); b.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,13))
	for state:String in ["normal","hover","pressed"]:
		var st:=StyleBoxFlat.new(); st.set_corner_radius_all(4); st.set_border_width_all(1)
		st.content_margin_left=8; st.content_margin_right=8; st.content_margin_top=4; st.content_margin_bottom=4
		st.bg_color=Color(ink[3]) if lit else (Color(ink[2],0.55) if state=="hover" else Color(ink[0]))
		st.border_color=Color(ink[3]) if lit or state=="hover" else Color(ink[2])
		b.add_theme_stylebox_override(state,st)
	var fg:Color=ink[0] if lit else ink[4]
	for state:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: b.add_theme_color_override(state,fg)
	return b


func _panel(section:Dictionary,ink:Array)->Control:
	var panel:=PanelContainer.new(); panel.name=String(section.kind).capitalize()
	var style:=StyleBoxFlat.new(); style.bg_color=ink[1]; style.border_color=ink[2]; style.set_border_width_all(1)
	style.set_corner_radius_all(T.RADIUS_CARD); style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",4); panel.add_child(column)
	column.add_child(_line(String(section.title).to_upper(),12,ink[3],false,"ui_strong"))
	for row in section.rows: column.add_child(_line(String(row),13,ink[4],true))
	return panel


static func _line(text:String,size:int,color:Color,wrap:=false,face:="ui")->Label:
	var label:=Label.new(); label.text=text; label.mouse_filter=Control.MOUSE_FILTER_PASS
	label.add_theme_font_override("font",T.font(face)); label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size)); label.add_theme_color_override("font_color",color)
	if wrap: label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label
