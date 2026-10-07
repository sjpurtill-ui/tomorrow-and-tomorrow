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
## (covert_ops.gd, captured_agents.gd). It only informs: the god gives the
## orders at court (the Pathfinder).
##
## sections() and corps_view() are the data (also read by tests).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const Corps:=preload("res://scripts/eyes_corps.gd")
const REFRESH_SECONDS:=1.5

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
	var learned:=Covert.learned(6)
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
		out.append({"kind":"empty","title":"","rows":["No one of ours lives among another people yet. Teach %s through the Pathfinder at court." % eyes]})
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
	return "%d months ago" % maxi(1,roundi(days/30.0))


func refresh(force:=false)->void:
	var data:=sections()
	var view:=corps_view()
	var sig:=str([data,_rounded(view)])
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
	column.add_child(_cipher_rule(ink))
	for section:Dictionary in data:
		if String(section.kind)=="empty":
			column.add_child(_line(String((section.rows as Array)[0]),14,ink[5],true,"voice_italic"))
			continue
		column.add_child(_panel(section,ink))


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
	col.add_child(_line("Teaching: %s · a course of %d days" % [String(c.policy_label).to_lower(),int(view.course_days)],13,ink[5],true))
	if corps=="wary":
		var cost:=roundi(float(view.cohesion_cost)*100.0)
		col.add_child(_line("Watching %d in 100 of our people · distrust costs %d in 100 of their trust in one another" % [roundi(float(view.coverage)*100.0),cost],13,ink[6] if cost>=2 else ink[5],true))
	panel.tooltip_text="Set at court: the Pathfinder's \"%s %s\" and \"%s\"." % [Corps.word("train").capitalize(),Corps.word("eyes"),Corps.word("Wary")]
	return panel


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
