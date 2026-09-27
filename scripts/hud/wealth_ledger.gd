extends "res://scripts/hud/home_ledger.gd"
## The Wealth dock: what the day's work yields, which way it is going and what
## holds it back, then the stores of money or exchange metal once they exist.
const Approved:=preload("res://scripts/hud/approved_ui_art.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const PALETTE:=[Color("6b7d50"),Color("497c96"),Color("93958a"),Color("b89339")]
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="WealthLedger";add_theme_constant_override("separation",8)
	var money:=String(data.stage)=="currency";var metal:=String(data.stage)=="weighed_metal"
	var status:=HBoxContainer.new();add_child(status)
	var stage:=_voice("Coin economy" if money else "Weighed-metal exchange" if metal else "Wealth is what we hold and owe one another",18);stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;status.add_child(stage)
	status.add_child(T.make_label(String(data.city),13,T.MUTED))
	# The day's work, as an equivalent number of people working at their best.
	var work:=HBoxContainer.new();work.add_theme_constant_override("separation",14);add_child(work)
	if not data.leader.is_empty():work.add_child(Portrait.picture(data.leader,80,100))
	var reading:=Words.output(data.economy,data.get("history",[]),data.get("conditions",{}))
	var equivalent:=float(data.economy.get("gdp",0.0))
	var headline:="The day's work equals about %s people working at their best" % Plain.number(equivalent)
	if equivalent<0.5:headline="Almost no useful work is being done"
	var box:=_reading(work,headline,String(reading.trend),String(reading.cause),String(reading.tone));box.name="OutputReading"
	if float(data.economy.get("gdp_per_capita",0.0))>0.0:_line(box,"That is %s of a full day's work for each person, children and elders included." % Plain.number(float(data.economy.gdp_per_capita)),13,T.BODY)
	if bool(data.show_work):
		_line(self,"This counts useful work only. It does not count land, buildings, belongings or coin.",13,T.MUTED)
	_rule(self)
	if not money and not metal:
		add_child(_voice("Gifts and shared stores",19))
		_line(self,"There is no money yet. Wealth is the food and materials in store, and the gifts and favours households owe one another.",13,T.BODY)
		_button(self,"See the material stores",data.on_stores,"Wood, stone, clay and fibre in store")
	else:
		add_child(T.make_label("MONEY HELD" if money else "EXCHANGE METAL",12,T.MUTED))
		for item:Dictionary in data.accounts:
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);add_child(row)
			if int(item.art)>=0:row.add_child(Approved.account(int(item.art)))
			var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(text)
			text.add_child(_voice("%s: %s" % [String(item.name),Plain.number(float(item.balance))],19))
			var change:=_account_change(item.points,float(item.balance))
			_line(text,change,13,T.BODY)
			var chart:=Spark.new();chart.points=item.points;chart.custom_minimum_size=Vector2(160,55);row.add_child(chart)
			var open:bool=data.selected==item.key
			_button(row,"Hide" if open else "Details",func():data.on_select.call(String(item.key)),"What this account holds").size_flags_vertical=Control.SIZE_SHRINK_CENTER
			if open:
				_line(self,"%s %s held now. This is what is held, not what comes in each day." % [Plain.number(float(item.balance)),"coins" if money else "measures of metal"],13,T.MUTED)
			_rule(self)
		if money:_composition()
	var footer:=HFlowContainer.new();footer.add_theme_constant_override("h_separation",8);add_child(footer)
	if money or metal:_button(footer,"Past balances",data.on_history,"How these holdings changed over past months")
	_button(footer,"Hide the note" if bool(data.show_work) else "What this counts",data.on_work,"What the day's work measures")
	_button(footer,"Government and policy",data.on_policy,"Officials and standing policy")
	_button(footer,"Material stores",data.on_stores,"Wood, stone, clay and fibre in store")

func _account_change(points:Array,balance:float)->String:
	var known:Array=[]
	for point:Dictionary in points:
		if point.get("value")!=null:known.append(point)
	if known.size()<1:return "No earlier count to compare with."
	var before:=float(known[-2].value) if known.size()>=2 else float(known[-1].value)
	var trend:=Words.direction(balance-before,before*5.0)
	if trend=="steady":return "Steady since the last count."
	return "%s since the last count (%s %s)." % [trend_word(trend),"up" if balance>before else "down",Plain.number(absf(balance-before))]

func _composition()->void:
	add_child(T.make_label("WHERE THE MONEY IS",12,T.MUTED))
	var total:=0.0
	for account:Dictionary in data.accounts:total+=maxf(0,float(account.balance))
	if total<=0:_line(self,"No money is recorded yet.",13,T.MUTED);return
	var bar:=HBoxContainer.new();bar.add_theme_constant_override("separation",1);bar.custom_minimum_size.y=18;add_child(bar)
	var legend:=HFlowContainer.new();legend.add_theme_constant_override("h_separation",16)
	for index in data.accounts.size():
		var account:Dictionary=data.accounts[index];var share:=maxf(0,float(account.balance))/total
		if share<=0:continue
		var segment:=ColorRect.new();segment.color=PALETTE[index];segment.size_flags_horizontal=Control.SIZE_EXPAND_FILL;segment.size_flags_stretch_ratio=share;segment.tooltip_text=String(account.name);bar.add_child(segment)
		legend.add_child(T.make_label("%s: %d in every 100" % [String(account.name),roundi(share*100)],13,T.BODY))
	add_child(legend)
