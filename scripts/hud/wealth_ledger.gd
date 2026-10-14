extends VBoxContainer
## Account choices keep their balances together and show one selected record.
## Current work and its limiting condition follow; measured work conditions
## expand in place. Refreshes and account changes preserve the controls.
##
## The live refresh (update_block) keeps every node while the page keeps its
## shape and writes the day's figures into them.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
var data:Dictionary
var _shape:Array=[]
var _refs:Dictionary={}
var _work_details:VBoxContainer

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="WealthLedger";add_theme_constant_override("separation",16)
	_shape=shape_of(block)
	_refs={"accounts":[]}
	var money:=String(block.stage)=="currency";var metal:=String(block.stage)=="weighed_metal"
	var work_group:=VBoxContainer.new();work_group.add_theme_constant_override("separation",8);add_child(work_group)
	var head:=S.head(work_group,"The day's work",String(block.get("city","")))
	_refs.city=head.side
	var work:=VBoxContainer.new();work.name="WorkLayout";work.add_theme_constant_override("separation",0);work_group.add_child(work)
	_refs.work=S.row(work,{"id":"work","icon":"make","icon_kind":"people","label":"Work done","value_width":70.0})
	(_refs.work.value as Label).name="WorkEquivalent"
	_work_details=VBoxContainer.new();_work_details.name="WorkConditions";_work_details.visible=false
	var show_work:=S.verb("Work conditions",func():_work_details.visible=not _work_details.visible,"Health, shelter, goodwill and worker effectiveness");show_work.name="ShowWorkConditions";show_work.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;work.add_child(show_work);work.add_child(_work_details)
	_refs.dial=S.row(_work_details,{"id":"effect","icon":"walker","icon_kind":"chart","label":"Worker effectiveness","bar_width":90.0,"value_width":70.0})
	(_refs.dial.panel as Control).name="WorkerEffectiveness"
	_refs.conditions_row=S.row(_work_details,{"id":"conditions","icon":"life","icon_kind":"people","label":"Conditions","bar_width":90.0,"value_width":70.0})
	(_refs.conditions_row.note as Label).name="Conditions"
	if money or metal:
		var accounts_head:=S.head(self,"Money held" if money else "Exchange metal")
		if block.get("on_history") is Callable:(accounts_head.row as HBoxContainer).add_child(S.verb("Past balances",block.on_history,"How these holdings changed over past months"))
		var choices:=HFlowContainer.new();choices.name="AccountChoices";choices.add_theme_constant_override("h_separation",8);choices.add_theme_constant_override("v_separation",6);add_child(choices)
		var selected:=String(block.get("selected",""))
		if selected.is_empty() and not (block.accounts as Array).is_empty():selected=String(block.accounts[0].key)
		for item:Dictionary in block.accounts:
			var open:=selected==String(item.key)
			var choice:=S.verb("",func():data.on_select.call(String(item.key)),"View this balance and its recent counts",open);choice.name="Account_"+String(item.key);choices.add_child(choice)
			var detail:=VBoxContainer.new();detail.add_theme_constant_override("separation",4);detail.visible=open;add_child(detail)
			var held:=S.label("",14,T.INK_MUTED);held.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_child(held)
			var reading:=HFlowContainer.new();reading.add_theme_constant_override("h_separation",8);detail.add_child(reading)
			var change:=S.label("",14,T.INK_MUTED);reading.add_child(change)
			var spark:=preload("res://scripts/hud/material_stock_spark.gd").new();reading.add_child(spark)
			(_refs.accounts as Array).append({"choice":choice,"held":held,"change":change,"spark":spark,"detail":detail,"chosen":open})
		if money:
			var share:=VBoxContainer.new();share.name="Composition";share.add_theme_constant_override("separation",8);share.custom_minimum_size.y=S.ROW_HEIGHT;add_child(share)
			var lead:=S.label("Where the money is",14,T.INK);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;share.add_child(lead)
			_refs.composition=S.label("",14,T.INK_MUTED);_refs.composition.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_refs.composition.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;share.add_child(_refs.composition)
	move_child(work_group,get_child_count()-1)
	_fill()
	resized.connect(_arrange)

## On a narrow page the rows keep their names and figures only.
func _arrange()->void:
	S.compact(self,size.x)

## The live refresh: the same nodes take the day's figures while the page
## keeps its shape; a page of another shape is drawn afresh.
func update_block(block:Dictionary)->bool:
	if _refs.is_empty() or shape_of(block)!=_shape:return false
	data=block
	_fill()
	return true

## What the page's nodes are: the stage, each account and the one opened.
static func shape_of(block:Dictionary)->Array:
	var accounts:Array=[]
	for account:Dictionary in block.get("accounts",[]):accounts.append(String(account.get("key","")))
	return [String(block.get("stage","")),accounts,block.get("on_history") is Callable]

## Every figure on the page that follows the day.
func _fill()->void:
	var money:=String(data.stage)=="currency"
	S.put(_refs.city,String(data.get("city","")))
	var economy:Dictionary=data.get("economy",{})
	var reading:=Words.output(economy,data.get("history",[]),data.get("conditions",{}))
	var equivalent:=float(economy.get("gdp",0.0))
	var conditions:Dictionary=data.get("conditions",{})
	var cause:=String(reading.cause).get_slice("; ",1)
	if not conditions.has_all(["health","housing","cohesion"]):cause="Some working conditions have not been measured."
	var lead:=""
	if _has_work_history(data.get("history",[])):lead=_trend_word(String(reading.trend))+": "
	var detail:=lead+cause
	var per_head:=float(economy.get("gdp_per_capita",0.0))
	S.set_row(_refs.work,{"label":"Work done","note":(detail.left(1).to_upper()+detail.substr(1)) if not detail.is_empty() else "","note_color":_tone(String(reading.tone)),"value":Plain.number(equivalent),
		"tip":("The day's work equals about %s people working at their best." % Plain.number(equivalent) if equivalent>=0.5 else "Almost no useful work is being done.")+("\nThat is %s of a full day's work for each person, children and elders included." % Plain.number(per_head) if per_head>0.0 else "")+"\nThis counts useful work only. It does not count land, buildings, belongings or coin."})
	var measure:Variant=economy.get("productivity")
	S.set_row(_refs.dial,{"label":"Worker effectiveness","note":"against 150%","value":("%d%%" % roundi(float(measure)*100.0)) if measure!=null else "—","ratio":clampf(float(measure)/1.5,0.0,1.0) if measure!=null else -1.0,"bar_color":T.TEAL,
		"tip":"Useful work per worker, relative to a healthy, settled worker (100%). The bar runs from 0 to 150%."})
	(_refs.dial.panel as Control).set_meta("measure",measure)
	# Health, shelter and goodwill on one row; the bar is the weakest of them.
	var parts:PackedStringArray=[]
	var weakest:=INF
	var low:=false
	for spec:Array in [["health","Health"],["housing","Shelter"],["cohesion","Goodwill"]]:
		var measured:bool=conditions.has(spec[0]) and conditions[spec[0]]!=null
		var ratio:=maxf(0.0,float(conditions[spec[0]])) if measured else 0.0
		parts.append("%s  %s" % [spec[1],("%d%%" % roundi(ratio*100.0)) if measured else "Not measured"])
		if measured:
			weakest=minf(weakest,ratio)
			low=low or ratio<0.75
	S.set_row(_refs.conditions_row,{"label":"Conditions","note":" · ".join(parts),"note_color":T.AMBER_TEXT if low else T.INK_MUTED,"value":("%d%%" % roundi(weakest*100.0)) if weakest<INF else "—","ratio":clampf(weakest,0.0,1.0) if weakest<INF else -1.0,"bar_color":T.AMBER if low else T.TEAL,
		"tip":"Health, shelter (against need) and goodwill hold work back below 100%. The bar and figure are the weakest of the three."})
	var selected:=String(data.get("selected",""))
	if selected.is_empty() and not (data.get("accounts",[]) as Array).is_empty():selected=String(data.accounts[0].key)
	var total:=0.0
	for account:Dictionary in data.get("accounts",[]):total+=maxf(0,float(account.balance))
	for index in mini((data.get("accounts",[]) as Array).size(),(_refs.accounts as Array).size()):
		var item:Dictionary=data.accounts[index];var refs:Dictionary=_refs.accounts[index]
		var chosen:=selected==String(item.key)
		refs.detail.visible=chosen
		if bool(refs.chosen)!=chosen:
			T.apply_button_style(refs.choice)
			if chosen:refs.choice.add_theme_stylebox_override("normal",refs.choice.get_theme_stylebox("pressed").duplicate())
			refs.chosen=chosen
		(refs.choice as Button).text="%s: %s" % [String(item.name),Plain.number(float(item.balance))]
		S.put(refs.held,"%s %s held now. This is what is held, not what comes in each day." % [Plain.number(float(item.balance)),"coins" if money else "measures of metal"])
		S.put(refs.change,_account_change(item.get("points",[]),float(item.balance)))
		refs.spark.points=item.get("points",[]);refs.spark.visible=not (refs.spark.points as Array).is_empty();refs.spark.queue_redraw()
	if _refs.has("composition"):
		var shares:PackedStringArray=[]
		for account:Dictionary in data.get("accounts",[]):
			if total>0 and float(account.balance)>0:shares.append("%s: %d in every 100" % [String(account.name),roundi(maxf(0,float(account.balance))/total*100)])
		S.put(_refs.composition," · ".join(shares) if not shares.is_empty() else "No money is recorded yet.")

static func _tone(tone:String)->Color:
	match tone:
		"bad":return T.RED_TEXT
		"warn":return T.AMBER_TEXT
		"good":return T.GREEN_TEXT
	return T.INK_MUTED

static func _trend_word(trend:String)->String:
	match trend:
		"rising":return "Rising"
		"falling":return "Falling"
	return "Steady"

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
	if known.size()<1:return "no earlier count"
	var before:=float(known[-2].value) if known.size()>=2 else float(known[-1].value)
	var trend:=Words.direction(balance-before,before*5.0)
	if trend=="steady":return "steady since the last count"
	return "%s %s since the last count" % ["up" if balance>before else "down",Plain.number(absf(balance-before))]
