extends "res://scripts/hud/settlement_overview.gd"
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
var fields_grid:GridContainer
var projects_grid:GridContainer
func setup(block:Dictionary)->void:
	data=block;name="InquiryBoard";add_theme_constant_override("separation",16)
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",16);add_child(heading)
	var intro:=VBoxContainer.new();intro.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(intro)
	intro.add_child(_serif("At the edge of what we know",27))
	_note(intro,"Follow the work underway, or give your people a new question to pursue.")
	_button(heading,"Explore the discovery tree",data.on_tree,"Explore known methods and their prerequisites")
	add_child(T.make_label("INVESTIGATIONS UNDERWAY",12,T.GOLD))
	projects_grid=GridContainer.new();projects_grid.columns=2;projects_grid.add_theme_constant_override("h_separation",16);projects_grid.add_theme_constant_override("v_separation",14);add_child(projects_grid)
	for record:Dictionary in data.investigations:
		_investigation(record)
	if data.investigations.is_empty():
		var empty:=_card(projects_grid);Visuals.paint(empty,"knowledge",130)
		empty.add_child(_serif("The next question is still open",22))
		_note(empty,"Research needs observers, evidence and earlier knowledge. Explore the tree to choose an available question, or ask your leader to prioritize research work.")
		_button(empty,"Review research work",data.on_work,"Review the leader’s local research priority")
	_rule(self)
	var field_heading:=HBoxContainer.new();add_child(field_heading)
	var field_title:=T.make_label("WHERE SHOULD WE LOOK NEXT?",12,T.GOLD);field_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;field_heading.add_child(field_title)
	_button(field_heading,"Research workforce",data.on_work,"Review how local leaders assign research work")
	_note(self,"Attention divides your existing observers between fields. More attention helps pursue a question; it cannot replace missing evidence.")
	fields_grid=GridContainer.new();fields_grid.columns=3;fields_grid.add_theme_constant_override("h_separation",16);fields_grid.add_theme_constant_override("v_separation",18);add_child(fields_grid)
	for field:Dictionary in data.fields:
		var outer:=_card(fields_grid);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);outer.add_child(row)
		var art:=Visuals.art(String(field.id))
		var thumb:=TextureRect.new();thumb.texture=Visuals.source_texture(art) if art else null;thumb.custom_minimum_size=Vector2(92,92)
		thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;thumb.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;thumb.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(thumb)
		var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",5);row.add_child(card)
		card.add_child(_serif(Visuals.name_for(String(field.id)),18))
		var goal:=String(field.goal).left(1).to_upper()+String(field.goal).substr(1);_clamped(card,goal,12,T.TEXT_SOFT);outer.get_parent().tooltip_text=goal
		_meter(card,float(field.share),Visuals.color(String(field.id)))
		var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",6);card.add_child(controls)
		var share:=T.make_label("%d%% attention · %d active"%[roundi(float(field.share)*100),int(field.active)],12,T.BODY);share.size_flags_horizontal=Control.SIZE_EXPAND_FILL;share.clip_text=true;controls.add_child(share)
		_button(controls,"−",field.on_less,"Reduce relative attention by one step")
		(controls.get_child(1) as Button).disabled=int(field.weight)<=0
		_button(controls,"+",field.on_more,"Increase relative attention by one step")
		_button(controls,"Explore",field.on_open,"Review this field’s purpose and investigations")
	resized.connect(_arrange);_arrange()
func _investigation(record:Dictionary)->void:
	# The subject paintings are square, so a square thumbnail beside the text shows the whole scene in a compact row.
	var domain:=String(record.get("dynamic","knowledge"));var accent:=Visuals.color(domain)
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	panel.tooltip_text="Review this field and its current investigations";projects_grid.add_child(panel)
	var idle:=T.flat(T.ROW_BG,T.BORDER,1,0,10);var hover:=T.flat(T.HOVER_BG,T.GOLD,1,0,10)
	panel.add_theme_stylebox_override("panel",idle)
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",hover))
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",idle))
	var review:Callable=data.on_domain.bind(domain)
	panel.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:review.call())
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);row.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(row)
	const SIDE:=124.0
	if Visuals.for_discovery(record)!=null:
		Visuals.paint_discovery(row,record,SIDE).custom_minimum_size.x=SIDE
	else:
		var tile:=PanelContainer.new();tile.custom_minimum_size=Vector2(SIDE,SIDE);tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_theme_stylebox_override("panel",T.flat(T.TILE_BG,T.BORDER_SOFT,1,0,0));row.add_child(tile)
		var glyph:=TextureRect.new();glyph.texture=preload("res://scripts/resource_icons.gd").domain_texture(domain,accent);glyph.custom_minimum_size=Vector2(56,56)
		glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;tile.add_child(glyph)
	var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",5);text.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(text)
	var progress:=clampf(float(record.get("progress",0)),0,1);var researchers:=float(record.get("research_workforce",0))
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);head.mouse_filter=Control.MOUSE_FILTER_PASS;text.add_child(head)
	var eyebrow:=T.make_label(Visuals.name_for(domain).to_upper(),11,T.GOLD);eyebrow.size_flags_horizontal=Control.SIZE_EXPAND_FILL;eyebrow.clip_text=true;head.add_child(eyebrow)
	head.add_child(T.make_label("%d%% · %s"%[roundi(progress*100),Visuals.workforce(researchers)],12,Visuals.text_color(domain)))
	text.add_child(_serif(String(record.get("name","An open question")),19))
	_meter(text,progress,accent)
	var bottleneck:=String(record.get("bottleneck","Gathering evidence"))
	var reason:=bottleneck.split(" — ",true,1)
	var phase:=Visuals.phase({"assignment":{"bottleneck":bottleneck,"active":true,"capacity":{"researchers":researchers}}})
	if phase.is_empty():phase=reason[0].left(1)+reason[0].substr(1).to_lower()
	_clamped(text,phase,13,T.BODY,1)
	if reason.size()>1:_clamped(text,reason[1].left(1).to_upper()+reason[1].substr(1)+".",12,T.TEXT_SOFT)
	var goal:=String(record.get("observation",record.get("project_goal",record.get("project_method",""))))
	panel.tooltip_text=(goal+"\n\n" if not goal.is_empty() else "")+"Click to review this field and its current investigations."
func _clamped(parent:Node,value:String,font:int,ink:Color,lines:int=2)->void:
	var label:=T.make_label(value,font,ink);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible=lines;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;parent.add_child(label)
func _card(parent:Node)->VBoxContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
	panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.BORDER,1,0,12))
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",9);panel.add_child(box);return box
func _meter(parent:Node,fraction:float,color:Color)->void:
	var bar:=ProgressBar.new();bar.custom_minimum_size.y=6;bar.show_percentage=false;bar.value=fraction*100;parent.add_child(bar)
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color))
func _arrange()->void:
	if fields_grid:fields_grid.columns=3 if size.x>=1100 else (2 if size.x>=520 else 1)
	if projects_grid:projects_grid.columns=2 if size.x>=560 else 1
