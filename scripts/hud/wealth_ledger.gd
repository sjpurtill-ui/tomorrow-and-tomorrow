extends "res://scripts/hud/production_queue.gd"
const Approved:=preload("res://scripts/hud/approved_ui_art.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const PALETTE:=[Color("6b7d50"),Color("497c96"),Color("93958a"),Color("b89339")]
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;add_theme_constant_override("separation",8)
	var money:=String(data.stage)=="currency";var metal:=String(data.stage)=="weighed_metal"
	var status:=HBoxContainer.new();add_child(status);var stage:=_serif("Coin economy" if money else "Weighed-metal exchange" if metal else "Wealth before money",16);stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;status.add_child(stage);status.add_child(T.make_label(String(data.city),12,T.MUTED))
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);add_child(head)
	if not data.leader.is_empty():head.add_child(Portrait.picture(data.leader,80,100))
	var manager:=VBoxContainer.new();manager.size_flags_horizontal=Control.SIZE_EXPAND_FILL;manager.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(manager)
	var name_label:=_serif(String(data.leader.get("name","Founding camp")),16);name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;manager.add_child(name_label);manager.add_child(T.make_label("Leader managed" if bool(data.managed) else "Directed priorities",12,T.MUTED))
	for spec in [["%.1f" % float(data.economy.gdp),"Output / day"],["%.2f" % float(data.economy.gdp_per_capita),"Output / person"],["%d%%" % roundi(float(data.economy.productivity)*100),"Productivity"]]:
		var cell:=VBoxContainer.new();cell.custom_minimum_size.x=100;cell.size_flags_vertical=Control.SIZE_SHRINK_CENTER;cell.tooltip_text="Real economic output, not currency or stored wealth";head.add_child(cell);cell.add_child(_serif(spec[0],23));cell.add_child(T.make_label(spec[1],11,T.MUTED))
	_rule(self)
	if not money and not metal:
		add_child(_serif("Direct allocation & reciprocity",19))
		var note:=T.make_label("Wealth is held in useful goods. Currency accounts do not exist yet.",12,T.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(note)
		_button(self,"View material stores",data.on_stores,"Physical reserves are tracked by material, without invented monetary values")
	else:
		var labels:=HBoxContainer.new();labels.add_theme_constant_override("separation",16);add_child(labels)
		var heading:=_serif("MONEY ACCOUNTS" if money else "EXCHANGE METAL",16);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;labels.add_child(heading)
		var balance:=T.make_label("BALANCE",11,T.MUTED);balance.custom_minimum_size.x=105;labels.add_child(balance)
		var trend:=T.make_label("RECORDED TREND",11,T.MUTED);trend.custom_minimum_size.x=160;labels.add_child(trend);var spacer:=Control.new();spacer.custom_minimum_size.x=28;labels.add_child(spacer)
		for item:Dictionary in data.accounts:
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);add_child(row)
			if int(item.art)>=0:row.add_child(Approved.account(int(item.art)))
			var account_label:=_serif(String(item.name),20);account_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;account_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(account_label)
			var amount:=_serif("%.0f" % float(item.balance),23);amount.custom_minimum_size.x=105;row.add_child(amount)
			var chart:=Spark.new();chart.points=item.points;chart.custom_minimum_size=Vector2(160,55);row.add_child(chart)
			_button(row,"▴" if data.selected==item.key else "⌄",func():data.on_select.call(String(item.key)),"Account details")
			for child in row.get_children():child.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			if data.selected==item.key:
				var note:=T.make_label("%.2f %s · recorded holdings, not daily income" % [float(item.balance),"currency units" if money else "metal-value units"],12,T.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(note)
			_rule(self)
		if money:_composition()
	var work:=HBoxContainer.new();work.add_theme_constant_override("separation",14);add_child(work)
	if preload("res://scripts/hud/early_civ_art.gd").active():
		var activity:=TextureRect.new();activity.texture=preload("res://scripts/hud/ambition_art.gd").texture(1)
		activity.custom_minimum_size=Vector2(150,150);activity.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		activity.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;activity.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		activity.mouse_filter=Control.MOUSE_FILTER_IGNORE;work.add_child(activity)
	else:work.add_child(Approved.picture(Rect2(105,810,520,139),310,84))
	var brief:=VBoxContainer.new();brief.size_flags_horizontal=Control.SIZE_EXPAND_FILL;brief.size_flags_vertical=Control.SIZE_SHRINK_CENTER;work.add_child(brief);brief.add_child(_serif("Work & productivity",20))
	var formula:=T.make_label("%.1f effective worker-days × %.0f%% = %.1f output" % [float(data.economy.effective_workers),float(data.economy.productivity)*100,float(data.economy.gdp)],11,T.MUTED);formula.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;brief.add_child(formula)
	_button(work,"⌄",data.on_work,"Economic output calculation")
	if bool(data.show_work):
		var note:=T.make_label("Output measures current effective labor and productivity. It does not value land, buildings, possessions, or coin balances.",12,T.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(note)
	_rule(self)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",14);add_child(footer)
	if money or metal:_button(footer,"Account history",data.on_history,"Recorded balances over time")
	_button(footer,"Economic policy",data.on_policy,"Government and policy");_button(footer,"Material stores",data.on_stores,"Physical reserves")
func _composition()->void:
	add_child(_serif("Where money is held",16))
	var total:=0.0
	for account:Dictionary in data.accounts:total+=maxf(0,float(account.balance))
	if total<=0:add_child(T.make_label("No currency balances recorded.",12,T.MUTED));return
	var bar:=HBoxContainer.new();bar.add_theme_constant_override("separation",1);bar.custom_minimum_size.y=18;add_child(bar)
	var legend:=HFlowContainer.new();legend.add_theme_constant_override("h_separation",16)
	for index in data.accounts.size():
		var account:Dictionary=data.accounts[index];var share:=maxf(0,float(account.balance))/total
		if share<=0:continue
		var segment:=ColorRect.new();segment.color=PALETTE[index];segment.size_flags_horizontal=Control.SIZE_EXPAND_FILL;segment.size_flags_stretch_ratio=share;segment.tooltip_text=String(account.name);bar.add_child(segment)
		legend.add_child(T.make_label("%d%%  %s" % [roundi(share*100),String(account.name)],11,PALETTE[index]))
	add_child(legend)
func _serif(text:String,font_size:int)->Label:
	var label:=T.make_label(text,font_size,T.INK);var font:=SystemFont.new();font.font_names=PackedStringArray(["Georgia"]);label.add_theme_font_override("font",font);return label
