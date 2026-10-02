extends VBoxContainer
## THE WAR SCREEN'S "SPIES AND ASSASSINS": a compact, plain section mounted on
## the War screen (hud/war_board.gd). It shows, from the covert ledger
## (covert_ops.gd), our agents abroad, what they have learned, how our
## operations ended, and the spies of theirs our watch has caught. No tabs, no
## controls: the god gives covert orders at court, and this only informs.
##
## sections() is the data (also read by tests); the board builds plain rows
## from it, in the War screen's paper-and-ink look. A readable empty state
## stands when no one of ours is abroad.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const REFRESH_SECONDS:=1.5

var box:VBoxContainer
var clock:=0.0
var signature:=""


func setup()->void:
	name="CovertBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	box=VBoxContainer.new(); box.add_theme_constant_override("separation",8); add_child(box)
	refresh(true)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS: return
	clock=0.0
	refresh()


## The board's data, newest first: [{kind, title, rows:[String], tone}].
## kind: "abroad", "learned", "outcomes", "caught"; "empty" when nothing.
static func sections()->Array:
	var out:Array=[]
	var abroad:=Covert.agents_abroad()
	if not abroad.is_empty():
		var rows:Array=[]
		for a:Dictionary in abroad:
			rows.append("%s · %s · %s · %s · risk %s" % [String(a.name),_cover_words(String(a.cover),String(a.kind)),String(a.civ_name),String(a.last_word),_risk_words(float(a.risk))])
		out.append({"kind":"abroad","title":"Our agents abroad","rows":rows})
	var learned:=Covert.learned(6)
	if not learned.is_empty():
		var rows2:Array=[]
		for f:Dictionary in learned: rows2.append("%s — %s" % [String(f.fact),_age(int(f.age_days))])
		out.append({"kind":"learned","title":"What they have learned","rows":rows2})
	var outcomes:=Covert.outcomes(6)
	if not outcomes.is_empty():
		var rows3:Array=[]
		for o:Dictionary in outcomes: rows3.append("%s (%s)" % [String(o.line),_age(int(o.age_days))])
		out.append({"kind":"outcomes","title":"How our ventures ended","rows":rows3})
	var caught:=Covert.caught_spies(6)
	if not caught.is_empty():
		var rows4:Array=[]
		for c:Dictionary in caught: rows4.append("%s of %s, %s%s" % [("an assassin" if String(c.kind)=="assassinate" else "a spy"),String(c.civ_name),_age(int(c.age_days)),(" · "+String(c.fate)) if String(c.fate)!="" else ""])
		out.append({"kind":"caught","title":"Their spies we have caught","rows":rows4})
	if out.is_empty():
		out.append({"kind":"empty","title":"","rows":["No one of ours is abroad in secret."]})
	return out


static func _cover_words(cover:String,kind:String)->String:
	var work:String=String({"watch":"watching","plant":"a source","steal":"after a secret","sabotage":"to strike their stores","assassinate":"to strike their leaders"}.get(kind,"abroad"))
	if cover=="none": return work
	return "%s, as %s %s" % [work,"an" if cover=="envoy" else "a",cover]


static func _risk_words(risk:float)->String:
	if risk<=0.12: return "slight"
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
	var sig:=str(data)
	if not force and sig==signature: return
	# Do not rebuild under the pointer (a click is informing).
	if not force and is_instance_valid(box) and box.get_global_rect().has_point(box.get_global_mouse_position()): return
	signature=sig
	for child in box.get_children(): box.remove_child(child); child.queue_free()
	for section:Dictionary in data:
		if String(section.kind)=="empty":
			box.add_child(_line(String((section.rows as Array)[0]),14,T.INK_MUTED,true))
			continue
		box.add_child(_panel(section))


func _panel(section:Dictionary)->Control:
	var panel:=PanelContainer.new(); panel.name=String(section.kind).capitalize()
	var style:=StyleBoxFlat.new(); style.bg_color=T.PAPER_RAISED; style.border_color=T.RULE; style.set_border_width_all(1)
	style.set_corner_radius_all(T.RADIUS_CARD); style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",4); panel.add_child(column)
	var head:=_line(String(section.title).to_upper(),12,T.INK_MUTED); head.add_theme_font_override("font",T.font("ui_strong")); column.add_child(head)
	for row in section.rows: column.add_child(_line(String(row),13,T.INK,true))
	return panel


static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new(); label.text=text; label.mouse_filter=Control.MOUSE_FILTER_PASS
	label.add_theme_font_override("font",T.font("ui")); label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size)); label.add_theme_color_override("font_color",color)
	if wrap: label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label
