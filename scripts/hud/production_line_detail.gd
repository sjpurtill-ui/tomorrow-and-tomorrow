extends VBoxContainer
## One line, opened from its name on the Production screen: what it makes,
## four numbers, what each item takes, and the few things to do with it
## (target, pause, change product, crafting share, close). Values come from
## the production snapshot; controls keep the simulation's own validation and
## delegation rules. Priority is the line's place in the list, set on the
## Production screen itself.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const W:=preload("res://scripts/hud/production_widgets.gd")

func setup(data:Dictionary)->void:
	name="ProductionLineDetail";theme=T.control_theme()
	add_theme_constant_override("separation",14)
	var line:Dictionary=data.line
	var story:=Plain.line_story(line,{})
	var view:=Plain.line_view(line,{},{"name":String(data.get("title",""))})
	var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",14);add_child(hero)
	var mark:=TextureRect.new();mark.texture=Icons.equipment_texture(String(line.get("item","")),T.INK,T.GOLD,96);mark.custom_minimum_size=Vector2(56,56)
	mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;hero.add_child(mark)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.size_flags_vertical=Control.SIZE_SHRINK_CENTER;hero.add_child(identity)
	var title:=Label.new();title.text=String(data.title);T.text(title,"voice",T.INK);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;identity.add_child(title)
	identity.tooltip_text=String(data.get("description",""));identity.mouse_filter=Control.MOUSE_FILTER_PASS
	var tone:={"good":T.GREEN,"warn":T.AMBER,"bad":T.RED}.get(String(view.look),T.RULE_STRONG) as Color
	var state:=W.Chip.new(String(story.short),tone,String(story.held));identity.add_child(state)
	var managed:=bool(line.get("planner_managed",false)) and bool(data.get("staff_enabled",true))
	var owner:=Plain.officer(String(data.get("owner","")))
	var who:=HBoxContainer.new();who.add_theme_constant_override("separation",8);add_child(who)
	var runner:=Label.new();runner.size_flags_horizontal=Control.SIZE_EXPAND_FILL;T.text(runner,"small",T.INK_MUTED);who.add_child(runner)
	runner.text=("%s runs this line" % String(owner.name)) if managed and not owner.is_empty() else "You run this line"
	if not managed:_button(who,"Hand back to staff",data.get("on_delegate"),"Staff set this line's target to what the bands need again. Work in progress is kept.")
	var tiles:=GridContainer.new();tiles.columns=4;tiles.add_theme_constant_override("h_separation",8);add_child(tiles)
	var target:=int(line.get("target_stock",0))
	_tile(tiles,"In store","%d / %s" % [int(line.get("stock",0)),Plain.target_text(target)],"%d in store; the line keeps %s." % [int(line.get("stock",0)),("%d" % target) if target>0 else "making without a limit"])
	_tile(tiles,"Output",String(view.bar_text),String(story.pace))
	_tile(tiles,"Last day",str(int(line.get("last_output",0))),"Finished on the last working day.")
	_tile(tiles,"Skill","%d%%" % roundi(float(line.get("efficiency",0))*100),"How practised the hands are; it grows with work.")
	var progress:=clampf(float(line.get("progress_days",0))/maxf(.001,float(line.get("work_per_item",1))),0,1)
	var next:=W.OutputBar.new(200);next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	next.set_reading(progress,String(view.look),"Next one %d%% done" % roundi(progress*100),String(story.eta));add_child(next)
	var inputs:=VBoxContainer.new();inputs.add_theme_constant_override("separation",4);add_child(inputs)
	var head:=HBoxContainer.new();inputs.add_child(head)
	_cell(head,"EACH ONE TAKES",0,true,T.GOLD_TEXT,"kicker");_cell(head,"IN STORE",78,false,T.INK_MUTED,"kicker");_cell(head,"EACH",66,false,T.INK_MUTED,"kicker");_cell(head,"A DAY",66,false,T.INK_MUTED,"kicker")
	for input:Dictionary in line.get("materials_status",[]):
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS;inputs.add_child(row)
		var short:=maxf(0,float(input.per_item)-float(input.stored))
		var color:=T.RED_TEXT if short>0 else T.BODY
		row.tooltip_text=("Short %s for one item. " % Plain.number(short) if short>0 else "Enough in store for one item. ")+"The daily figure is at today's pace; other lines share these stores."
		var icon:=TextureRect.new();icon.texture=Icons.material_texture(String(input.get("resource","")),32);icon.custom_minimum_size=Vector2(18,18)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
		_cell(row,String(input.name),0,true,color,"small");_cell(row,Plain.number(float(input.stored)),78,false,color,"small")
		_cell(row,Plain.number(float(input.per_item)),66,false,T.INK_MUTED,"small");_cell(row,Plain.number(float(input.per_day)),66,false,T.INK_MUTED,"small")
	var targets:=HBoxContainer.new();targets.add_theme_constant_override("separation",4);add_child(targets)
	var keep:=Label.new();keep.text="KEEP IN STORE";T.text(keep,"kicker",T.INK_MUTED);keep.custom_minimum_size.x=120;keep.size_flags_vertical=Control.SIZE_SHRINK_CENTER;targets.add_child(keep)
	for choice:int in [0,5,20,100,500]:
		_button(targets,Plain.target_text(choice),func():data.on_target.call(choice),"Keep making without a limit." if choice==0 else "Keep %d in store." % choice,target==choice)
	var footer:=HFlowContainer.new();footer.add_theme_constant_override("h_separation",6);footer.add_theme_constant_override("v_separation",6);add_child(footer)
	_button(footer,"Resume" if bool(line.get("paused",false)) else "Pause",data.get("on_pause"),"Start or stop this line. Work in progress is kept.")
	_button(footer,"Change product",data.get("on_retool"),"Make something else on this line. Some skill carries over; unfinished work is lost.")
	_button(footer,"Crafting share",data.get("on_labor"),"How much of all crafting goes to the workshop lines.")
	var close:=_button(footer,"Close line",data.get("on_close"),"Finished goods stay in store; work in progress is lost.")
	close.add_theme_color_override("font_color",T.RED_TEXT)

func _button(parent:Node,text:String,callback:Variant,tip:String,selected:bool=false)->Button:
	var button:=W.text_button(text,tip,selected,36);button.custom_minimum_size.y=30;parent.add_child(button)
	if callback is Callable and callback.is_valid():button.pressed.connect(callback)
	else:button.disabled=true
	return button

func _tile(parent:Node,caption:String,value:String,tip:String)->void:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.tooltip_text=tip;panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD);style.set_content_margin_all(8);panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(column)
	var label:=Label.new();label.text=caption.to_upper();T.text(label,"kicker",T.INK_MUTED);column.add_child(label)
	var number:=Label.new();number.text=value;T.text(number,"value",T.INK);column.add_child(number)

func _cell(parent:Node,text:String,width:float,expand:bool,color:Color,role:String)->void:
	var label:=Label.new();label.text=text;T.text(label,role,color);label.custom_minimum_size.x=width;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if expand:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	else:label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(label)
