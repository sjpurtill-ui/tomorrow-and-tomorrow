extends VBoxContainer
const T=preload("res://scripts/hud/hud_tokens.gd")
func label(parent:Node,text:String,size:int=13,color:Color=T.BODY)->Label:
	var item:=T.make_label(text,size,color);item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(item);return item
func setup(block:Dictionary)->void:
	add_theme_constant_override("separation",10)
	var q:Dictionary=block.quote
	label(self,"RECRUITMENT ON" if bool(block.ordered) else "READY TO RECRUIT",11,T.TEAL)
	label(self,String(q.summary),18,T.INK)
	var bar:=HBoxContainer.new();bar.custom_minimum_size.y=8;bar.add_theme_constant_override("separation",2);add_child(bar)
	var legend:=HBoxContainer.new();add_child(legend)
	for state:Array in [["AT HOME",int(q.home),T.GREEN],["TRAINING",int(q.active_training),T.BLUE],["TO RECRUIT",int(q.missing),T.GOLD]]:
		if state[1]>0:
			var fill:=ColorRect.new();fill.color=state[2];fill.size_flags_horizontal=Control.SIZE_EXPAND_FILL;fill.size_flags_stretch_ratio=state[1];bar.add_child(fill)
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;legend.add_child(column)
		label(column,str(state[1]),26,state[2]);label(column,state[0],10,T.MUTED)
	label(self,"Target: %d soldiers · at-home soldiers keep their training" % int(q.required),12,T.MUTED)
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);add_child(grid)
	for tile:Array in [["PEOPLE WHO CAN JOIN","%d" % int(q.people_room),"%d missing from this design" % int(q.missing)],["TRAINING SPACE","%d free" % int(q.training_places),"Crowding slows instruction"]]:
		var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",T.tile_style());grid.add_child(panel)
		var column:=VBoxContainer.new();panel.add_child(column)
		label(column,tile[0],10,T.MUTED);label(column,tile[1],22,T.INK);label(column,tile[2],11,T.TEXT_SOFT)
	label(self,"EQUIPMENT FOR NEW RECRUITS",11,T.GOLD)
	for row:Dictionary in q.equipment_rows:
		if int(row.needed)<=0:continue
		var line:=HBoxContainer.new();add_child(line)
		var name:=label(line,MilitaryCampaign.PersistentProduction.product_name(String(row.weapon)),13,T.INK);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var stock:=label(line,"%d stored / %d needed" % [int(row.stored),int(row.needed)],13,T.GREEN if int(row.stored)>=int(row.needed) else T.GOLD)
		stock.autowrap_mode=TextServer.AUTOWRAP_OFF
		label(self,"%d already issued · %d reserved for training" % [int(row.issued),int(row.reserved)],11,T.MUTED)
	if int(q.start_now)>0:label(self,"Next group: %d recruits · about %.0f extra rations through instruction, paid daily. Instruction can draw down civilian food." % [int(q.start_now),float(q.food)],12,T.TEXT_SOFT)
	if not q.blockers.is_empty():
		label(self,"WHAT LIMITS THE NEXT GROUP",10,T.GOLD)
		for reason:String in q.blockers:label(self,reason,12,T.TEXT_SOFT)
	label(self,"One order keeps recruitment running. Staff organize each group; you can stop future recruitment at any time.",12,T.TEAL)
