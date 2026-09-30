extends "res://scripts/hud/production_queue.gd"
const Buildings:=preload("res://scripts/hud/construction_art.gd")
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="IllustratedConstructionQueue";add_theme_constant_override("separation",0)
	var header:=HBoxContainer.new();add_child(header)
	var manager:=T.make_label("LEADER MANAGED" if String(data.get("priority","")).is_empty() else "PRIORITY OVERRIDE",12,T.GOLD);manager.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(manager)
	header.add_child(T.make_label(String(data.get("city","")),12,T.BODY))
	if not String(data.get("priority","")).is_empty():_button(header,"↶",func():data.on_priority.call(""),"Return all construction to leader choice")
	if data.has("shelter"):add_child(T.make_label(String(data.shelter.detail),12,T.BODY))
	var reserves:=HBoxContainer.new();reserves.add_theme_constant_override("separation",12);add_child(reserves)
	for resource:String in data.get("stocks",{}):
		var group:=HBoxContainer.new();group.size_flags_horizontal=Control.SIZE_EXPAND_FILL;group.tooltip_text=resource;reserves.add_child(group)
		group.add_child(Art.picture(Art.resource(resource),30,34));group.add_child(T.make_label("%.0f" % float(data.stocks[resource]),12,T.BODY))
	reserves.add_child(T.make_label("%d builders · %d carriers" % [int(data.get("builders",0)),int(data.get("carriers",0))],11,T.MUTED))
	_rule(self)
	if not bool(data.get("committed",false)):_button(self,"Choose settlement site",data.get("on_site"),"Construction begins after settling")
	for project:Dictionary in data.get("projects",[]):_building(project)
	if data.get("projects",[]).is_empty():add_child(T.make_label("No completed works yet." if int(data.get("completed",0))==0 else "No available projects.",12,T.MUTED))
	var footer:=HBoxContainer.new();add_child(footer)
	var count:=T.make_label("%d completed" % int(data.get("completed",0)),11,T.MUTED);count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(count)
	_button(footer,"Building record",data.get("on_record"),"Completed structures and settlement fabric")
func _building(project:Dictionary)->void:
	var title:=String(project.name);var selected:=String(data.get("selected",""))==title
	var done:=bool(project.done);var active:=bool(project.active) and not done
	var shell:=PanelContainer.new();shell.add_theme_stylebox_override("panel",T.flat(Color.TRANSPARENT,T.GOLD if selected else T.BORDER_SOFT,1,0,7));add_child(shell)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",5);shell.add_child(column)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);column.add_child(row)
	row.add_child(Buildings.for_title(title,156,96))
	var work:=VBoxContainer.new();work.size_flags_horizontal=Control.SIZE_EXPAND_FILL;work.size_flags_vertical=Control.SIZE_SHRINK_CENTER;work.add_theme_constant_override("separation",5);row.add_child(work)
	var heading:=HBoxContainer.new();work.add_child(heading)
	var label:=T.make_label(title,16,T.INK);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.tooltip_text=String(project.effect);heading.add_child(label)
	# A work finished lately carries the builders' stamp (hud/town_works_board.gd).
	if done and int(project.get("finished_ago",-1))>=0 and int(project.finished_ago)<=int(data.get("fresh_days",30)):
		var stamp:=preload("res://scripts/hud/town_works_board.gd").Stamp.new();stamp.tooltip_text="Finished %s" % String(project.get("finished_words",""));heading.add_child(stamp)
	heading.add_child(T.make_label("✓" if done else "%d%%" % roundi(float(project.progress)*100),13,T.GREEN if done or active else T.MUTED))
	_bar(work,float(project.progress),T.GREEN)
	var state:=T.make_label(String(project.state),11,T.GREEN if done or active else T.RED if not project.blockers.is_empty() else T.MUTED);state.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;state.tooltip_text="\n".join(project.blockers);work.add_child(state)
	# What it does, at a glance: its first effects, with their size.
	var impact:Dictionary=project.get("impact",{}) if project.get("impact") is Dictionary else {}
	var glance:=HFlowContainer.new();glance.name="Glance";glance.add_theme_constant_override("h_separation",14);glance.add_theme_constant_override("v_separation",2);work.add_child(glance)
	for line in (impact.get("lines",[]) as Array).slice(0,3):
		var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",4);chip.tooltip_text=String(line.get("words",""));glance.add_child(chip)
		chip.add_child(T.make_label(String(line.label),11,T.MUTED))
		chip.add_child(T.make_label(String(line.value),11,T.GREEN_TEXT if String(line.get("tone",""))=="good" else (T.RED_TEXT if String(line.get("tone",""))=="bad" else T.GOLD_TEXT)))
	if not done:
		var supplies:=HBoxContainer.new();supplies.add_theme_constant_override("separation",12);work.add_child(supplies)
		for i in mini(3,project.inputs.size()):_material_chip(supplies,project.inputs[i])
		if project.inputs.size()>3:supplies.add_child(T.make_label("+%d" % (project.inputs.size()-3),10,T.MUTED))
	var controls:=VBoxContainer.new();controls.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(controls)
	if title==String(data.get("priority","")):controls.add_child(T.make_label("★",13,T.GOLD))
	_button(controls,"▴" if selected else "▾",func():data.on_select.call(title),"Project materials and priority")
	if selected:
		_rule(column)
		if not done:
			var materials:=HBoxContainer.new();materials.add_theme_constant_override("separation",12);column.add_child(materials)
			for input:Dictionary in project.inputs:_material_chip(materials,input)
			materials.tooltip_text=String(project.bill_note)
			# What stops it, each a short red chip.
			if not (project.blockers as Array).is_empty():
				var chips:=HFlowContainer.new();chips.add_theme_constant_override("h_separation",6);chips.add_theme_constant_override("v_separation",4);column.add_child(chips)
				for blocker:String in project.blockers:
					var chip:=PanelContainer.new();var style:=T.flat(T.DANGER_BG,T.DANGER_BORDER,1,10);style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=1;style.content_margin_bottom=2
					chip.add_theme_stylebox_override("panel",style);chip.add_child(T.make_label(blocker,12,T.RED_TEXT));chips.add_child(chip)
		# Everything it does with the engine's numbers (building_impact.gd); the
		# why of each line waits in its tooltip.
		if not (impact.get("lines",[]) as Array).is_empty():
			column.add_child(T.make_label("What it does" if done else "What it will do",12,T.GOLD_TEXT,0.06))
			var panel:=preload("res://scripts/hud/impact_panel.gd").new();column.add_child(panel);panel.setup({"lines":impact.lines,"columns":2,"compact":true})
			panel.tooltip_text=String(project.effect).left(1).to_upper()+String(project.effect).substr(1)
		if not done and bool(data.get("can_prioritize",false)):
			var actions:=HBoxContainer.new();column.add_child(actions)
			_button(actions,"Prioritize when ready",func():data.on_priority.call(title),"Leader continues feasible work until this project is ready",title==String(data.get("priority","")))
			if title==String(data.get("priority","")):_button(actions,"Return to leader",func():data.on_priority.call(""),"Restore automatic project selection")
func _material_chip(parent:Node,input:Dictionary)->void:
	var group:=HBoxContainer.new();group.add_theme_constant_override("separation",2);group.tooltip_text=String(input.resource)+" · stores / required";parent.add_child(group)
	group.add_child(Art.picture(Art.resource(String(input.resource)),24,24))
	group.add_child(T.make_label("%.0f / %.0f" % [float(input.stored),float(input.required)],10,T.RED if float(input.stored)<float(input.required) else T.MUTED))
