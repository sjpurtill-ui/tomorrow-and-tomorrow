extends "res://scripts/hud/home_ledger.gd"
const Icons:=preload("res://scripts/resource_icons.gd")
var routes_grid:GridContainer

func setup(block:Dictionary)->void:
	data=block;theme=T.control_theme();name="ChapterBoard"
	add_theme_constant_override("separation",14)
	var chapter:Dictionary=data.chapter
	_line(self,"CHAPTER %d · %s" % [int(chapter.id)+1,String(chapter.name)],26,T.INK)
	_line(self,"Historical scope: years %d–%d · advance by achievement at any date" % [int(chapter.start),int(chapter.end)],14)
	_line(self,String(chapter.purpose),17)
	if int(chapter.legacy_entry)>0:_line(self,"Existing campaign: entered chapter %d from known discoveries. Earlier chapters have no recorded result." % (int(chapter.legacy_entry)+1),13)
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",8);add_child(actions)
	_button(actions,"Open branching research tree",data.on_tree,"Explore this chapter's real prerequisites and choose team targets.")
	_button(actions,"Defense & generals",data.on_war,"Review forces, equipment, training and the general's objectives.")
	_button(actions,"Assign researchers",data.on_people,"Researchers share one finite workforce with production and defense.")
	_line(self,String(data.pressure),14,T.AMBER_TEXT)
	_line(self,"Complete any route's two discoveries and sustain all its capabilities for %d days. Higher readings help; each bar runs from zero to its stated requirement." % int(chapter.hold_days),14)
	routes_grid=GridContainer.new();routes_grid.name="BreakthroughRoutes";routes_grid.columns=3;routes_grid.add_theme_constant_override("h_separation",14);routes_grid.add_theme_constant_override("v_separation",14);add_child(routes_grid)
	for route:Dictionary in chapter.routes:
		var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",T.flat(T.ACTIVE_BG,T.BORDER_SOFT,1,6,12));routes_grid.add_child(panel)
		var col:=VBoxContainer.new();col.add_theme_constant_override("separation",8);panel.add_child(col)
		var heading:=HBoxContainer.new();col.add_child(heading)
		var icon:=TextureRect.new();icon.texture=Icons.domain_texture(String(route.domain),T.GOLD);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(24,24);heading.add_child(icon)
		_line(heading,String(route.name),19,T.INK)
		for milestone:Dictionary in route.named_milestones:
			var b:=_button(col,("✓ " if bool(milestone.known) else "○ ")+String(milestone.name),data.on_question.bind(String(milestone.id)),"Inspect this milestone and the branches that lead to it.")
			b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size.y=44
		for check:Dictionary in route.checks:
			_line(col,String(check.label),14,T.INK)
			_line(col,"Current %.1f %s · need %.1f %s" % [float(check.value),String(check.unit),float(check.need),String(check.unit)],13)
			_bar(col,float(check.value)/maxf(0.001,float(check.need)),T.GOLD)
		_line(col,"Sustained: %d days · need %d days" % [int(route.days),int(chapter.hold_days)],14,T.INK)
		_bar(col,float(route.days)/float(chapter.hold_days),T.GOLD)
		_line(col,"Qualifying now" if bool(route.ready) else "Meet every requirement to start the sustained run",13)
		_button(col,"Focus this route"+(" · active" if String(chapter.focus)==String(route.id) else ""),data.on_focus.bind(String(route.id)),"Prioritize this route and fund the research fields its prerequisites need.")
	_button(self,"Let advisers balance the routes",data.on_focus.bind(""),"Remove the route preference. Keep current workforce allocations and manual question targets.")
	if bool(chapter.completed):_line(self,"All ten chapters completed. Your civilization continues.",20,T.GREEN_TEXT)
	if not (chapter.history as Array).is_empty():
		_line(self,"Completed chapters",20,T.INK)
		for record:Dictionary in chapter.history:
			_line(self,"%s · %s · year %.1f · %.0f people · %d discoveries" % [String(record.name),String(record.route),float(record.day)/365.0,float(record.population),int(record.discoveries)],14)
	resized.connect(_arrange);_arrange()

func _arrange()->void:
	if routes_grid:routes_grid.columns=3 if size.x>=1000 else 2 if size.x>=680 else 1
