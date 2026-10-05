extends "res://scripts/hud/home_ledger.gd"
## The Wealth dock: what the day's work yields, which way it is going and what
## holds it back, then the stores of money or exchange metal once they exist.
##
## The live refresh (update_block) keeps every node while the page keeps its
## shape (the same stage, leader, accounts and opened one) and writes the
## day's figures into them; _fill makes every figure's words for the first
## drawing and every refresh alike.
const Approved:=preload("res://scripts/hud/approved_ui_art.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
var _shape:Array=[]
var _refs:Dictionary={}
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="WealthLedger";add_theme_constant_override("separation",12)
	_shape=shape_of(block)
	_refs={"accounts":[],"segments":[],"legend":[],"conditions":[]}
	var money:=String(data.stage)=="currency";var metal:=String(data.stage)=="weighed_metal"
	var status:=HBoxContainer.new();add_child(status)
	var stage:=_voice("Coin economy" if money else "Weighed-metal exchange" if metal else "Barter: goods for food and materials",18);stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;status.add_child(stage)
	_refs.city=_line(status,"",13,T.MUTED);_refs.city.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	# The day's work, as an equivalent number of people working at their best.
	var work:=BoxContainer.new();work.name="WorkLayout";work.add_theme_constant_override("separation",20);_card(self).add_child(work);_refs.work=work
	var story:=HBoxContainer.new();story.add_theme_constant_override("separation",14);story.size_flags_horizontal=Control.SIZE_EXPAND_FILL;work.add_child(story)
	if not data.leader.is_empty():
		var portrait:=VBoxContainer.new();portrait.custom_minimum_size.x=100;portrait.add_theme_constant_override("separation",4);story.add_child(portrait)
		var frame:=_card(portrait,2);frame.add_child(Portrait.picture(data.leader,100,124))
		_refs.leader=_line(portrait,"",12,T.MUTED);_refs.leader.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var box:=VBoxContainer.new();box.name="OutputReading";box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",3);story.add_child(box);_refs.reading=box
	_line(box,"THE DAY'S WORK",12,T.MUTED)
	_refs.output=_line(box,"",40,T.INK);_refs.output.name="WorkEquivalent";_refs.output.add_theme_font_override("font",T.font("ui_strong"))
	_refs.headline=_line(box,"",14,T.BODY)
	_refs.cause=_line(box,"",13,T.MUTED)
	if float(data.economy.get("gdp_per_capita",0.0))>0.0:_refs.per_head=_line(box,"",13,T.BODY)
	var measures:=HBoxContainer.new();measures.name="WorkConditions";measures.add_theme_constant_override("separation",16);measures.size_flags_horizontal=Control.SIZE_EXPAND_FILL;measures.size_flags_vertical=Control.SIZE_SHRINK_CENTER;work.add_child(measures)
	var dial_column:=VBoxContainer.new();dial_column.add_theme_constant_override("separation",0);measures.add_child(dial_column)
	_refs.dial=EfficiencyDial.new();_refs.dial.name="WorkerEffectiveness";dial_column.add_child(_refs.dial)
	var dial_caption:=_line(dial_column,"Worker effectiveness",12,T.MUTED);dial_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var conditions:=VBoxContainer.new();conditions.size_flags_horizontal=Control.SIZE_EXPAND_FILL;conditions.size_flags_vertical=Control.SIZE_SHRINK_CENTER;conditions.add_theme_constant_override("separation",8);measures.add_child(conditions)
	for spec:Array in [["health","Health"],["housing","Shelter"],["cohesion","Goodwill"]]:
		var condition:=VBoxContainer.new();condition.add_theme_constant_override("separation",2);conditions.add_child(condition)
		var label:=_line(condition,"",12,T.MUTED);label.name=String(spec[0]).capitalize()+"Condition"
		var fill:=T.flat(T.TEAL)
		var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(100,5);bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",fill);condition.add_child(bar)
		_refs.conditions.append({"key":spec[0],"title":spec[1],"label":label,"bar":bar,"fill":fill})
	if bool(data.show_work):
		_line(self,"This counts useful work only. It does not count land, buildings, belongings or coin.",13,T.MUTED)
	if not money and not metal:
		add_child(_voice("Goods, stores and gifts",19))
		_line(self,"There is no money yet. Households trade goods for food and materials at remembered prices. Wealth lies in goods, stores, treasures and the favours people owe one another.",13,T.BODY)
		_button(self,"See the material stores",data.on_stores,"Wood, stone, clay and fibre in store")
	else:
		add_child(T.make_label("MONEY HELD" if money else "EXCHANGE METAL",12,T.MUTED))
		for item:Dictionary in data.accounts:
			var account:=VBoxContainer.new();account.add_theme_constant_override("separation",8);_card(self,12).add_child(account)
			var row:=BoxContainer.new();row.add_theme_constant_override("separation",12);account.add_child(row)
			var summary:=HBoxContainer.new();summary.add_theme_constant_override("separation",12);summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(summary)
			if int(item.art)>=0:
				var art:=Approved.account(int(item.art));art.custom_minimum_size=Vector2(92,48);art.size_flags_vertical=Control.SIZE_SHRINK_CENTER;summary.add_child(art)
			var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.size_flags_vertical=Control.SIZE_SHRINK_CENTER;summary.add_child(text)
			var refs:={"balance":_voice("",24),"held":null,"row":row}
			text.add_child(refs.balance)
			refs.change=_line(text,"",13,T.BODY)
			var chart:=Spark.new();chart.custom_minimum_size=Vector2(110,48);chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL;chart.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(chart);refs.spark=chart
			var open:bool=data.selected==item.key
			_button(summary,"Hide" if open else "Details",func():data.on_select.call(String(item.key)),"What this account holds").size_flags_vertical=Control.SIZE_SHRINK_CENTER
			if open:
				refs.held=_line(account,"",13,T.MUTED)
			(_refs.accounts as Array).append(refs)
		if money:_composition()
	var footer:=HFlowContainer.new();footer.add_theme_constant_override("h_separation",8);add_child(footer)
	if money or metal:_button(footer,"Past balances",data.on_history,"How these holdings changed over past months")
	_button(footer,"Hide the note" if bool(data.show_work) else "What this counts",data.on_work,"What the day's work measures")
	_button(footer,"Officials in court",data.on_policy,"Summon an official: what they do, how well, and the standing orders they carry out")
	_button(footer,"Material stores",data.on_stores,"Wood, stone, clay and fibre in store")
	_fill()
	resized.connect(_arrange);_arrange()

func _card(parent:Node,padding:int=16)->PanelContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,padding));parent.add_child(panel);return panel

## Resize the existing containers; daily updates never rebuild the artwork.
func _arrange()->void:
	if _refs.is_empty():return
	(_refs.work as BoxContainer).vertical=size.x<700
	for refs:Dictionary in _refs.accounts:(refs.row as BoxContainer).vertical=size.x<540

## The live refresh: the same nodes take the day's figures while the page
## keeps its shape; a page of another shape is drawn afresh.
func update_block(block:Dictionary)->bool:
	if _refs.is_empty() or shape_of(block)!=_shape:return false
	data=block
	_fill()
	return true

## What the page's nodes are: the stage, the leader's picture, whether the
## note and the output per head are shown, each account (its picture, the one
## opened) and which accounts hold money in the composition bar.
static func shape_of(block:Dictionary)->Array:
	var stage:=String(block.get("stage",""))
	var leader:Dictionary=block.get("leader",{})
	var accounts:Array=[]
	var holding:Array=[]
	var total:=0.0
	for account:Dictionary in block.get("accounts",[]):total+=maxf(0,float(account.get("balance",0.0)))
	for account:Dictionary in block.get("accounts",[]):
		accounts.append([String(account.get("key","")),int(account.get("art",-1))])
		holding.append(total>0 and maxf(0,float(account.get("balance",0.0)))/total>0)
	return [stage,Portrait.picture_key(leader) if not leader.is_empty() else [],bool(block.get("show_work",false)),float((block.get("economy",{}) as Dictionary).get("gdp_per_capita",0.0))>0.0,accounts,String(block.get("selected","")),total>0,holding]

## Every figure on the page that follows the day.
func _fill()->void:
	var money:=String(data.stage)=="currency"
	_put(_refs.city,String(data.city))
	if _refs.has("leader"):_put(_refs.leader,String(data.leader.get("name","")))
	var reading:=Words.output(data.economy,data.get("history",[]),data.get("conditions",{}))
	var equivalent:=float(data.economy.get("gdp",0.0))
	var headline:="The day's work equals about %s people working at their best" % Plain.number(equivalent)
	if equivalent<0.5:headline="Almost no useful work is being done"
	_put(_refs.output,Plain.number(equivalent))
	_put(_refs.headline,headline)
	var cause:=String(reading.cause).get_slice("; ",1)
	var conditions:Dictionary=data.get("conditions",{})
	if not conditions.has_all(["health","housing","cohesion"]):cause="Some working conditions have not been measured."
	var lead:="Today, " if conditions.has_all(["health","housing","cohesion"]) else ""
	if _has_work_history(data.get("history",[])):lead=trend_word(String(reading.trend))+": "
	var detail:=lead+cause
	_put(_refs.cause,detail.left(1).to_upper()+detail.substr(1),tone_color(String(reading.tone)))
	(_refs.dial as EfficiencyDial).set_measure(data.economy.get("productivity"))
	for refs:Dictionary in _refs.conditions:
		var measured:bool=conditions.has(refs.key) and conditions[refs.key]!=null
		var ratio:=maxf(0.0,float(conditions[refs.key])) if measured else 0.0
		_put(refs.label,"%s  %s" % [refs.title,("%d%%" % roundi(ratio*100.0)) if measured else "Not measured"],T.AMBER_TEXT if measured and ratio<0.75 else T.MUTED)
		var tint:=T.AMBER if measured and ratio<0.75 else T.TEAL
		if (refs.fill as StyleBoxFlat).bg_color!=tint:(refs.fill as StyleBoxFlat).bg_color=tint
		(refs.bar as ProgressBar).value=clampf(ratio,0.0,1.0)*100.0
		(refs.bar as ProgressBar).tooltip_text="%s: %s" % [refs.title,("%d%% of need" % roundi(ratio*100.0)) if refs.key=="housing" and measured else (("%d%%" % roundi(ratio*100.0)) if measured else "not measured")]
	if _refs.has("per_head"):_put(_refs.per_head,"That is %s of a full day's work for each person, children and elders included." % Plain.number(float(data.economy.gdp_per_capita)))
	for index in mini((data.accounts as Array).size(),(_refs.accounts as Array).size()):
		var item:Dictionary=data.accounts[index];var refs:Dictionary=_refs.accounts[index]
		_put(refs.balance,"%s: %s" % [String(item.name),Plain.number(float(item.balance))])
		_put(refs.change,_account_change(item.points,float(item.balance)))
		var spark:Control=refs.spark
		if spark.get("points")!=item.points:spark.set("points",item.points);spark.queue_redraw()
		if refs.held!=null:_put(refs.held,"%s %s held now. This is what is held, not what comes in each day." % [Plain.number(float(item.balance)),"coins" if money else "measures of metal"])
	if money:_fill_composition()

func _has_work_history(history:Array)->bool:
	var latest:Dictionary={}
	for index in range(history.size()-1,-1,-1):
		var entry:Dictionary=history[index]
		if not entry.has("output_per_capita"):continue
		if latest.is_empty():latest=entry
		elif int(latest.get("day",0))-int(entry.get("day",0))>=30:return true
	return false

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
		var segment:=ColorRect.new();segment.color=[T.GREEN,T.BLUE,T.TEAL,T.GOLD][index%4];segment.size_flags_horizontal=Control.SIZE_EXPAND_FILL;segment.size_flags_stretch_ratio=share;segment.tooltip_text=String(account.name);bar.add_child(segment)
		var said:=T.make_label("%s: %d in every 100" % [String(account.name),roundi(share*100)],13,T.BODY);legend.add_child(said)
		(_refs.segments as Array).append([index,segment]);(_refs.legend as Array).append([index,said])
	add_child(legend)

## The composition bar's shares and words, written in place.
func _fill_composition()->void:
	var total:=0.0
	for account:Dictionary in data.accounts:total+=maxf(0,float(account.balance))
	if total<=0:return
	for pair:Array in _refs.segments:
		var account:Dictionary=data.accounts[int(pair[0])]
		var segment:ColorRect=pair[1]
		var share:=maxf(0,float(account.balance))/total
		if segment.size_flags_stretch_ratio!=share:segment.size_flags_stretch_ratio=share
		segment.tooltip_text=String(account.name)
	for pair:Array in _refs.legend:
		var account:Dictionary=data.accounts[int(pair[0])]
		_put(pair[1],"%s: %d in every 100" % [String(account.name),roundi(maxf(0,float(account.balance))/total*100)])

## The model permits 150% output. A fixed scale and a 100% reference keep
## above-baseline work honest instead of silently capping it at a full ring.
class EfficiencyDial extends Control:
	const Tokens=preload("res://scripts/hud/hud_tokens.gd")
	var measure:Variant=null
	func _init()->void:
		custom_minimum_size=Vector2(122,92);mouse_filter=Control.MOUSE_FILTER_PASS
		tooltip_text="Useful work per worker, relative to a healthy, settled worker. The arc runs from 0 to 150%; the mark is 100%."
	func set_measure(value:Variant)->void:
		if measure==value:return
		measure=value;queue_redraw()
	func _draw()->void:
		var center:=Vector2(size.x*.5,50);var radius:=39.0;var start:=PI*.75;var sweep:=PI*1.5
		draw_arc(center,radius,start,start+sweep,56,Tokens.TRACK,6,true)
		if measure!=null:
			var ratio:=clampf(float(measure)/1.5,0.0,1.0)
			if ratio>0:draw_arc(center,radius,start,start+sweep*ratio,56,Tokens.TEAL,6,true)
		var mark:=Vector2.from_angle(start+sweep/1.5)
		draw_line(center+mark*(radius-7),center+mark*(radius+7),Tokens.RULE_STRONG,1.5,true)
		draw_string(Tokens.font("ui"),Vector2(size.x-28,14),"100",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Tokens.MUTED)
		var text:="%d%%" % roundi(float(measure)*100.0) if measure!=null else "—"
		var face:=Tokens.font("ui_strong");var width:=face.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,26).x
		draw_string(face,Vector2(center.x-width*.5,58),text,HORIZONTAL_ALIGNMENT_LEFT,-1,26,Tokens.INK)
		draw_string(Tokens.font("ui"),Vector2(8,91),"0",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Tokens.MUTED)
		draw_string(Tokens.font("ui"),Vector2(size.x-32,91),"150%",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Tokens.MUTED)
