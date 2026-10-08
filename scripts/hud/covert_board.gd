extends VBoxContainer
## THE HIDDEN FOLIO: the eyes and the wary, mounted on the War screen
## (hud/war_board.gd). In the early ages it reads as a secret society's book:
## night-dark vellum, gold leaf, an eye sigil ringed by cipher marks, and the
## society's name (The Listeners, then The Quiet Watch). In a reckoned age it
## turns to the service's terminal: phosphor green on black.
##
## Top: our two corps (eyes_corps.gd) as seals, each with how many serve, how
## many learn, their craft as a row of marks and the course; the wary carry
## the distrust they cost at home. Below: our eyes abroad, what they sent
## home, how our errands ended, theirs we caught, and those we hold
## (covert_ops.gd, captured_agents.gd).
##
## It is also where the god gives the orders, in plain buttons: how many to
## teach for each corps (the same policy the Pathfinder carries at court,
## court_eyes_orders.gd), and an errand among each people we know (watch,
## live among them, steal a craft) with the engine's odds on the button. A
## killing or a burning stays a word at court: the war leader answers for it.
##
## sections(), corps_view(), level_rows() and errand_rows() are the data
## (also read by tests).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const Corps:=preload("res://scripts/eyes_corps.gd")
const Orders:=preload("res://scripts/covert_orders.gd")
const REFRESH_SECONDS:=1.5
## The errands a button can send (the eyes' own work, carried by the
## Pathfinder); the peoples shown at most.
const ERRANDS:=["watch","plant","steal"]
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


## A row of craft marks: filled to the corps' craft, out of the age's cap.
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
	refresh(true)


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
	var abroad:=Covert.agents_abroad()
	if not abroad.is_empty():
		var rows:Array=[]
		for a:Dictionary in abroad:
			rows.append("%s · %s · %s · %s · risk %s" % [String(a.name),_cover_words(String(a.cover),String(a.kind)),String(a.civ_name),String(a.last_word),_risk_words(float(a.risk))])
		out.append({"kind":"abroad","title":"Our %s abroad" % eyes,"rows":rows})
	# Our networks: eyes and won locals in each people, how long, how strong.
	var nets:=Covert.networks()
	if not nets.is_empty():
		var rows_n:Array=[]
		for n:Dictionary in nets:
			rows_n.append("%s · %d %s, %d won over · %s · strength %d in 100 · %s · each meeting %s" % [String(n.civ_name),int(n.eyes),Corps.word("eye") if int(n.eyes)==1 else eyes,int(n.recruits),
				"under a year" if float(n.years)<1.0 else ("%d years" % roundi(float(n.years))),roundi(float(n.strength)*100.0),
				"no word yet" if int(n.last_word_days)<0 else "last word %s" % _age(int(n.last_word_days)),_risk_words(float(n.risk))])
		out.append({"kind":"networks","title":"Our networks","rows":rows_n})
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
	if out.is_empty():
		out.append({"kind":"empty","title":"","rows":["No one of ours lives among another people yet."]})
	return out


static func _cover_words(cover:String,kind:String)->String:
	var work:String=String({"watch":"watching","plant":"living among them","steal":"after a secret","sabotage":"to strike their stores","assassinate":"to strike their leaders"}.get(kind,"abroad"))
	if cover=="none": return work
	return "%s, as %s %s" % [work,"an" if cover=="envoy" else "a",cover]


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


## The four teaching levels for one corps, with what each means in the
## engine's numbers: [{id, label, active, yearly, words}].
static func level_rows(corps:String)->Array:
	var people:=maxf(1.0,float(GameState.population_exact))
	var sum:=Corps.summary()
	var out:Array=[]
	for id:String in Corps.POLICY_ORDER:
		var row:Array=Corps.POLICIES[id]
		var yearly:=float(row[1])*people/1000.0
		var words:=""
		if id=="none": words="No one starts the course. Those we have keep serving until the years thin them."
		else: words="About %s a year start a %d-day course at %s food a day each, and leave other work while they learn and serve." % [_count(yearly),int(sum.course_days),_n(float(sum.course_food))]
		out.append({"id":id,"label":String(row[0]),"active":Corps.policy(corps)==id,"yearly":yearly,"words":words})
	return out


## Every people we know, with the odds of each errand our eyes can run among
## them: [{civ_id, name, errands:[{kind, label, success, caught, days, barred}]}].
## The odds are for whoever would go now: a trained eye of ours when one is
## ready, else an untried volunteer (covert_ops.gd volunteer_for).
static func errand_rows()->Array:
	var out:Array=[]
	if WorldSimulation.world==null: return out
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary: continue
		var civ:Dictionary=c
		var id:=String(civ.get("id",""))
		if id=="" or id=="player" or not bool(civ.get("alive",true)): continue
		var rel:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		if int(rel.get("contact_level",0))<1: continue
		var errands:Array=[]
		for kind:String in ERRANDS:
			var barred:=Covert.method_barred(kind)
			var e:={"kind":kind,"label":_errand_label(kind),"barred":barred}
			if barred=="":
				var o:=Covert.odds(kind,id,"","none",_likely_agent(kind))
				e["success"]=float(o.get("success",0.0))
				e["caught"]=float(o.get("settle",0.0))+float(o.get("caught",0.0)) if kind=="plant" else float(o.get("caught",0.0))
				e["days"]=int(o.get("days",0))
			errands.append(e)
		out.append({"civ_id":id,"name":String(civ.get("name",id)),"errands":errands})
		if out.size()>=MAX_PEOPLES: break
	return out


## Who would go, for the odds shown (nothing is drawn or spent): a trained
## eye at the corps' craft, else a volunteer of middling hand.
static func _likely_agent(kind:String)->Dictionary:
	if kind in ["watch","plant"] and Corps.members("eyes")>=1.0:
		var k:=Corps.craft("eyes")
		return {"stealth":clampf(k,0.1,0.95),"tongue":clampf(k*0.9+0.05,0.1,0.95),"nerve":clampf(k*0.85+0.1,0.1,0.95),"blade":0.4,"poison":0.35,"trained":true}
	return {"stealth":0.55,"tongue":0.5,"nerve":0.5,"blade":0.45,"poison":0.4}


static func _errand_label(kind:String)->String:
	return String({"watch":"Watch them","plant":"Live among them","steal":"Steal a craft"}.get(kind,kind))


## Sets one corps' teaching, as the Pathfinder's order would. Returns the words.
func set_level(corps:String,level:String)->String:
	var done:=preload("res://scripts/court_eyes_orders.gd").perform({"corps":corps,"policy":level})
	answer=String(done.get("says",""))
	refresh(true)
	return answer


## Sends one errand among a people, as the Pathfinder's order would, on the
## odds the button showed. Returns the official's answer.
func send(kind:String,civ_id:String)->String:
	var done:=Orders.perform({"kind":kind,"civ_id":civ_id,"city_id":"","cover":"none","target_desc":_errand_label(kind)},true)
	answer=String(done.get("says",""))
	if String(done.get("outcome",""))!="": answer+=" "+String(done.outcome)
	refresh(true)
	return answer


static func _count(n:float)->String:
	if n<1.0: return "one every %d years" % maxi(2,roundi(1.0/maxf(0.01,n)))
	return str(roundi(n))


static func _n(v:float)->String:
	return ("%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(".")


func refresh(force:=false)->void:
	var data:=sections()
	var view:=corps_view()
	var errands:=errand_rows()
	var sig:=str([data,_rounded(view),answer,_errand_sig(errands)])
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
	var seals:=HBoxContainer.new(); seals.add_theme_constant_override("separation",12); column.add_child(seals)
	seals.add_child(_seal("eyes",view,ink))
	seals.add_child(_seal("wary",view,ink))
	if answer!="":
		var said:=_line(answer,13,ink[4],true,"voice_italic"); said.name="Answer"; column.add_child(said)
	column.add_child(_send_panel(errands,ink))
	column.add_child(_cipher_rule(ink))
	for section:Dictionary in data:
		if String(section.kind)=="empty":
			column.add_child(_line(String((section.rows as Array)[0]),14,ink[5],true,"voice_italic"))
			continue
		column.add_child(_panel(section,ink))


static func _errand_sig(rows:Array)->Array:
	var out:Array=[]
	for r:Dictionary in rows:
		var e:Array=[String(r.civ_id)]
		for x:Dictionary in r.errands: e.append(roundi(float(x.get("success",0.0))*100.0))
		out.append(e)
	return out


static func _rounded(view:Dictionary)->Array:
	var out:=[String(view.stage),roundi(float(view.distrust)*100.0)]
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


func _seal(corps:String,view:Dictionary,ink:Array)->Control:
	var c:Dictionary=view[corps]
	var panel:=PanelContainer.new(); panel.name="Seal_"+corps; panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=StyleBoxFlat.new(); style.bg_color=ink[1]; style.border_color=ink[2]; style.set_border_width_all(1)
	style.set_corner_radius_all(T.RADIUS_CARD); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style)
	var col:=VBoxContainer.new(); col.add_theme_constant_override("separation",4); panel.add_child(col)
	var name:=Corps.word("Eyes") if corps=="eyes" else Corps.word("Wary")
	col.add_child(_line(("Our %s" % Corps.word("eyes")).to_upper() if corps=="eyes" else name.to_upper(),12,ink[3],false,"ui_strong"))
	var count:=_line(str(roundi(float(c.members))),28,ink[4],false,"display")
	col.add_child(count)
	var serving:=("serve abroad or wait to go" if corps=="eyes" else "watch among our own people")
	col.add_child(_line("%s · %d learning" % [serving,roundi(float(c.training))],13,ink[5],true))
	var marks:=Marks.new(); marks.value=float(c.craft); marks.cap=float(view.cap); marks.leaf=ink[3]; col.add_child(marks)
	marks.tooltip_text="Craft %d in 100; the most this age can teach is %d." % [roundi(float(c.craft)*100.0),roundi(float(view.cap)*100.0)]
	col.add_child(_line("%s how many a year?" % Corps.word("train").capitalize(),12,ink[3],false,"ui_strong"))
	var levels:=HBoxContainer.new(); levels.name="Levels_"+corps; levels.add_theme_constant_override("separation",4); col.add_child(levels)
	for row:Dictionary in level_rows(corps):
		var b:=_ink_button(String(row.label),bool(row.active),ink)
		b.name="Level_%s_%s" % [corps,String(row.id)]; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.tooltip_text=String(row.words)
		var level:=String(row.id)
		b.pressed.connect(func()->void: set_level(corps,level))
		levels.add_child(b)
	for row:Dictionary in level_rows(corps):
		if bool(row.active): col.add_child(_line(String(row.words),12,ink[5],true))
	if corps=="wary":
		var cost:=roundi(float(view.cohesion_cost)*100.0)
		col.add_child(_line("Watching %d in 100 of our people · distrust costs %d in 100 of their trust in one another" % [roundi(float(view.coverage)*100.0),cost],13,ink[6] if cost>=2 else ink[5],true))
	panel.tooltip_text=("Ours who live unseen among other peoples. A taught one blends in far better than a volunteer." if corps=="eyes" else "Ours who watch for theirs among us. More of them catch more, but the people start wondering who reports on whom.")
	return panel


## Send our eyes: a row for each people we know, a button for each errand
## with its odds, and who would go.
func _send_panel(rows:Array,ink:Array)->Control:
	var panel:=PanelContainer.new(); panel.name="Send"
	var style:=StyleBoxFlat.new(); style.bg_color=ink[1]; style.border_color=ink[2]; style.set_border_width_all(1)
	style.set_corner_radius_all(T.RADIUS_CARD); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style)
	var col:=VBoxContainer.new(); col.add_theme_constant_override("separation",6); panel.add_child(col)
	col.add_child(_line(("Send our %s" % Corps.word("eyes")).to_upper(),12,ink[3],false,"ui_strong"))
	var ready:=floori(Corps.members("eyes"))
	col.add_child(_line(("%d taught %s ready: one of them goes." % [ready,Corps.word("eye") if ready==1 else Corps.word("eyes")]) if ready>=1 else "None taught yet: an untried volunteer goes. Teach some above to raise the odds.",13,ink[5],true))
	if rows.is_empty():
		col.add_child(_line("We know no other people yet. Our scouts must find them first.",13,ink[5],true,"voice_italic"))
		return panel
	for r:Dictionary in rows:
		var line:=HBoxContainer.new(); line.name="People_"+String(r.civ_id); line.add_theme_constant_override("separation",6); col.add_child(line)
		var who:=_line(String(r.name),14,ink[4],false,"ui_strong"); who.custom_minimum_size=Vector2(110,0); who.size_flags_horizontal=Control.SIZE_EXPAND_FILL; who.clip_text=true; line.add_child(who)
		for e:Dictionary in r.errands:
			if String(e.barred)!="": continue
			var b:=_ink_button("%s · %d%%" % [String(e.label),roundi(float(e.success)*100.0)],false,ink)
			b.name="Send_%s_%s" % [String(e.kind),String(r.civ_id)]
			b.tooltip_text="%s: about %d in 100 it works · about %d in 100 ours is caught · %d days to reach them." % [String(e.label),roundi(float(e.success)*100.0),roundi(float(e.caught)*100.0),int(e.days)]
			var kind:=String(e.kind); var civ_id:=String(r.civ_id)
			b.pressed.connect(func()->void: send(kind,civ_id))
			line.add_child(b)
	col.add_child(_line("A killing or a burning among them is a word at court: the war leader answers for it.",12,ink[5],true,"voice_italic"))
	return panel


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
