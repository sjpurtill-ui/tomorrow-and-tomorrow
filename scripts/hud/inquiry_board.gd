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
		var domain:=String(record.get("dynamic","knowledge"))
		var card:=_card(projects_grid)
		if Visuals.for_discovery(record)!=null:
			Visuals.paint_discovery(card,record,112)
		else:
			var notes:=PanelContainer.new();notes.custom_minimum_size.y=112;notes.add_theme_stylebox_override("panel",T.flat(T.TILE_BG,T.BORDER_SOFT,1,0,14));card.add_child(notes)
			var method:=T.make_label(String(record.get("project_method","Observers compare evidence in the field.")),14,T.BODY);method.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notes.add_child(method)
		card.add_child(T.make_label(Visuals.name_for(domain).to_upper(),11,T.GOLD))
		var title:=_serif(String(record.get("name","An open question")),21);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.add_child(title)
		var progress:=clampf(float(record.get("progress",0)),0,1)
		_meter(card,progress,Visuals.color(domain))
		_note(card,"%d%% · %s"%[roundi(progress*100),String(record.get("bottleneck","Gathering evidence"))])
		_note(card,Visuals.workforce(float(record.get("research_workforce",0))))
		var goal:=String(record.get("observation",record.get("project_goal","")))
		if not goal.is_empty():_note(card,goal)
		_button(card,"Review this investigation",data.on_domain.bind(domain),"Review this field and its current investigations")
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
		var card:=_card(fields_grid);Visuals.paint(card,String(field.id),116)
		var title:=_serif(Visuals.name_for(String(field.id)),21);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.add_child(title)
		_note(card,String(field.goal).left(1).to_upper()+String(field.goal).substr(1))
		_meter(card,float(field.share),Visuals.color(String(field.id)))
		_note(card,"%d%% attention · %d active"%[roundi(float(field.share)*100),int(field.active)])
		var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",6);card.add_child(controls)
		_button(controls,"−",field.on_less,"Reduce relative attention by one step")
		(controls.get_child(0) as Button).disabled=int(field.weight)<=0
		_button(controls,"+",field.on_more,"Increase relative attention by one step")
		_button(controls,"Explore",field.on_open,"Review this field’s purpose and investigations")
	resized.connect(_arrange);_arrange()
func _card(parent:Node)->VBoxContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
	panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.BORDER,1,0,12))
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",9);panel.add_child(box);return box
func _meter(parent:Node,fraction:float,color:Color)->void:
	var bar:=ProgressBar.new();bar.custom_minimum_size.y=6;bar.show_percentage=false;bar.value=fraction*100;parent.add_child(bar)
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color))
func _arrange()->void:
	if fields_grid:fields_grid.columns=3 if size.x>=720 else 2
	if projects_grid:projects_grid.columns=2 if size.x>=560 else 1
