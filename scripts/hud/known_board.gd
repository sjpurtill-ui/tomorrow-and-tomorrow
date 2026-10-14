extends "res://scripts/hud/home_ledger.gd"
## WHAT WE KNOW (Research › What we know): a strip of three figures, then one
## row per field: its mark and name, how much of the field is known as a bar
## against all its questions, what its knowledge adds now (the engine's
## totals, the three largest) and its newest finding. A row opens in place to
## every effect the field's knowledge adds, with its account on hover, and
## its findings newest first. Known effects nothing reads yet are one line.
## Data: dock_content_inquiry.gd _known_block; nothing here reads the engine.
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const NAME_W:=150.0
const COUNT_W:=110.0
## Findings listed in an opened field before "and N earlier".
const FINDINGS_SHOWN:=36

func setup(block:Dictionary)->void:
	data=block;name="KnownBoard";add_theme_constant_override("separation",8)
	_figures(self)
	var table:=VBoxContainer.new();table.name="Fields";table.add_theme_constant_override("separation",0);add_child(table)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);table.add_child(head)
	for spec:Array in [["FIELD",NAME_W+30.0],["KNOWN",COUNT_W],["WHAT IT ADDS NOW",0.0]]:
		var label:=T.make_label(String(spec[0]),11,T.GOLD_TEXT,0.06)
		if float(spec[1])>0.0:label.custom_minimum_size.x=float(spec[1])
		else:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		head.add_child(label)
	var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size.y=1;table.add_child(rule)
	for field:Dictionary in data.get("fields",[]):_field(table,field)
	var inert:Array=data.get("inert",[])
	if not inert.is_empty():
		var names:Array[String]=[]
		for row:Dictionary in inert:names.append("%s %s" % [String(row.label),String(row.amount)])
		var line:=T.make_label("%d known effect%s nothing uses yet" % [inert.size(),"" if inert.size()==1 else "s"],12,T.TEXT_SOFT);line.name="Inert"
		line.tooltip_text="Part of what the people know, but nothing in the world reads them yet, so they change nothing:\n"+"\n".join(names);line.mouse_filter=Control.MOUSE_FILTER_PASS
		add_child(line)

## Known, learned this year, newest.
func _figures(parent:Node)->void:
	var strip:=HBoxContainer.new();strip.name="Figures";strip.add_theme_constant_override("separation",10);parent.add_child(strip)
	for figure:Dictionary in data.get("figures",[]):
		var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=float(figure.get("stretch",1.0));panel.tooltip_text=String(figure.get("tip",""))
		panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.BORDER_SOFT,1,T.RADIUS_CONTROL,8));strip.add_child(panel)
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",1);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(box)
		box.add_child(T.make_label(String(figure.title),11,T.GOLD_TEXT,0.06))
		var value:=_voice(String(figure.value),24 if String(figure.value).length()<=14 else 18);value.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(value)
		value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if String(figure.value).length()>14 else TextServer.AUTOWRAP_OFF;value.custom_minimum_size.x=80
		var note:=T.make_label(String(figure.get("note","")),12,T.TEXT_SOFT);note.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(note)
		if figure.has("ratio"):_bar(box,float(figure.ratio),T.GOLD)

func _field(parent:Node,field:Dictionary)->void:
	var id:=String(field.id)
	var accent:=Visuals.color(id)
	var open:=bool(field.get("open",false))
	var box:=VBoxContainer.new();box.name="Field_"+id;box.add_theme_constant_override("separation",0);parent.add_child(box)
	var row:=Button.new();row.name="Row";row.flat=true;row.focus_mode=Control.FOCUS_NONE;row.custom_minimum_size.y=30
	row.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,Color.TRANSPARENT,0,2,0));row.add_theme_stylebox_override("pressed",T.flat(T.ACTIVE_BG,Color.TRANSPARENT,0,2,0))
	if open:row.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG,Color.TRANSPARENT,0,2,0))
	row.tooltip_text=("Close" if open else "Open")+" %s: every effect its knowledge adds and its findings." % Visuals.name_for(id).to_lower()
	if field.get("on_toggle") is Callable:row.pressed.connect(field.on_toggle)
	box.add_child(row)
	var line:=HBoxContainer.new();line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);line.add_theme_constant_override("separation",8);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(line)
	var lead:=HBoxContainer.new();lead.add_theme_constant_override("separation",6);lead.custom_minimum_size.x=NAME_W+30.0;lead.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(lead)
	var mark:=T.make_label("▾" if open else "▸",11,T.GOLD_TEXT);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;lead.add_child(mark)
	var glyph:=TextureRect.new();glyph.texture=Icons.domain_texture(id,accent);glyph.custom_minimum_size=Vector2(20,20);glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE;lead.add_child(glyph)
	var title:=T.make_label(Visuals.name_for(id),13,T.INK);title.size_flags_vertical=Control.SIZE_SHRINK_CENTER;title.mouse_filter=Control.MOUSE_FILTER_IGNORE;lead.add_child(title)
	var count:=HBoxContainer.new();count.add_theme_constant_override("separation",6);count.custom_minimum_size.x=COUNT_W;count.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(count)
	var number:=T.make_label(EraWordsNumber.grouped(int(field.known)),13,T.BODY);number.custom_minimum_size.x=36;number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;number.size_flags_vertical=Control.SIZE_SHRINK_CENTER;number.mouse_filter=Control.MOUSE_FILTER_IGNORE;count.add_child(number)
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(60,6);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.value=float(field.known)/maxf(1.0,float(field.get("total",1)))*100.0
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(accent));count.add_child(bar)
	var adds:=T.make_label("",12,T.BODY);adds.name="Adds";adds.size_flags_horizontal=Control.SIZE_EXPAND_FILL;adds.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	adds.clip_text=true;adds.custom_minimum_size.x=1;adds.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(adds)
	var parts:Array=field.get("adds",[])
	# As many of the largest effects as the line holds, whole, and how many more.
	adds.resized.connect(func()->void:_fit_parts(adds,parts))
	_fit_parts(adds,parts)
	var hair:=ColorRect.new();hair.color=Color(T.BORDER_SOFT,0.5);hair.custom_minimum_size.y=1;hair.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(hair)
	if open:_opened(box,field,accent)

static func _fit_parts(label:Label,parts:Array)->void:
	if parts.is_empty():
		label.text="Nothing yet; it opens later knowledge";return
	var font:=label.get_theme_font("font");var px:=label.get_theme_font_size("font_size")
	var room:=label.size.x if label.size.x>1.0 else 380.0
	var text:=String(parts[0])
	for k in range(1,parts.size()):
		var rest:=parts.size()-k-1
		var trial:=text+" · "+String(parts[k])
		var tail:=(" · %d more" % rest) if rest>0 else ""
		if font.get_string_size(trial+tail,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>room:
			text+=" · %d more" % (parts.size()-k);break
		text=trial
	if label.text!=text:label.text=text

## An opened field: every effect its knowledge adds, two or three to a line,
## each with its account on hover; then its findings, newest first.
func _opened(parent:Node,field:Dictionary,accent:Color)->void:
	var pad:=MarginContainer.new();pad.add_theme_constant_override("margin_left",36);pad.add_theme_constant_override("margin_top",6);pad.add_theme_constant_override("margin_bottom",8);parent.add_child(pad)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);pad.add_child(box)
	var effects:Array=field.get("effects",[])
	if not effects.is_empty():
		var grid:=GridContainer.new();grid.name="Effects";grid.columns=3 if size.x>=760.0 else 2;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",2);box.add_child(grid)
		for row:Dictionary in effects:
			var cell:=HBoxContainer.new();cell.add_theme_constant_override("separation",6);cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.mouse_filter=Control.MOUSE_FILTER_PASS
			var lines:Array[String]=[String(row.get("headline",""))]
			for note:Variant in row.get("notes",[]):lines.append(String(note))
			cell.tooltip_text="\n".join(lines).strip_edges()
			var label:=T.make_label(String(row.label),12,T.BODY);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(label)
			var tone:=String(row.get("tone",""))
			var amount:=T.make_label(String(row.amount),12,T.RED_TEXT if tone=="bad" else (T.GREEN_TEXT if tone=="good" else T.INK));amount.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(amount)
			grid.add_child(cell)
	var findings:Array=field.get("findings",[])
	if not findings.is_empty():
		box.add_child(T.make_label("FINDINGS, NEWEST FIRST",11,T.GOLD_TEXT,0.06))
		var flow:=HFlowContainer.new();flow.name="Findings";flow.add_theme_constant_override("h_separation",14);flow.add_theme_constant_override("v_separation",2);box.add_child(flow)
		for item:Dictionary in findings.slice(0,FINDINGS_SHOWN):
			var label:=T.make_label(String(item.name),12,T.INK);label.tooltip_text=String(item.get("tip",""));label.mouse_filter=Control.MOUSE_FILTER_PASS
			flow.add_child(label)
		if findings.size()>FINDINGS_SHOWN:
			flow.add_child(T.make_label("and %d earlier" % (findings.size()-FINDINGS_SHOWN),12,T.TEXT_SOFT))

## Thousands grouped the way the top bar groups them.
class EraWordsNumber:
	static func grouped(value:int)->String:return preload("res://scripts/hud/era_words.gd").grouped(value)
