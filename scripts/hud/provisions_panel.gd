extends "res://scripts/hud/home_ledger.gd"
## The Food dock: how long the food and water last, which way they are going
## and why, then the stores by kind. Every number is read as a sentence.
##
## The live refresh (update_block) keeps every node while the page keeps its
## shape (the same leader and choices, the same stores, the same one opened)
## and writes the day's sentences into them; _fill makes every one of them,
## for the first drawing and every refresh alike.
const FoodArt:=preload("res://scripts/hud/provisions_art.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
var _shape:Array=[]
var _refs:Dictionary={}
func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="ProvisionsLedger";add_theme_constant_override("separation",8)
	_shape=shape_of(block)
	_refs={"rows":[]}
	var leader:=String(data.get("leader_name",""))
	var head:=HBoxContainer.new();add_child(head)
	var owner:=_line(head,"",13,T.MUTED)
	owner.name="Owner";_refs.owner=owner
	_refs.city=T.make_label("",13,T.BODY);head.add_child(_refs.city)
	# Food: the headline sentence, with its direction and cause.
	var food_row:=HBoxContainer.new();food_row.add_theme_constant_override("separation",14);add_child(food_row)
	food_row.add_child(FoodArt.picture(0,120,72))
	var food_reading:=_reading(food_row,"","","","");food_reading.name="FoodReading";_refs.food=food_reading
	var flow_line:=_line(self,"",13,T.BODY);flow_line.name="FlowSentence";_refs.flow=flow_line
	# Why this many hands are on food: the planners' own numbers.
	if String(data.get("food_plan",""))!="":
		var plan:=_line(self,"",13,T.BODY);plan.name="FoodPlan";_refs.plan=plan
	# Water, the same way.
	var water_row:=HBoxContainer.new();water_row.add_theme_constant_override("separation",14);add_child(water_row)
	water_row.add_child(FoodArt.picture(4,120,72))
	var water_reading:=_reading(water_row,"","","","");water_reading.name="WaterReading";_refs.water=water_reading
	_button(water_row,"Water sources",data.on_water,"Where the water comes from and how it is carried").size_flags_vertical=Control.SIZE_SHRINK_CENTER
	# Looking ahead.
	var outlook:=HBoxContainer.new();add_child(outlook)
	var ahead:=_line(outlook,"",13,T.BODY);ahead.name="Forecast";_refs.forecast=ahead
	_button(outlook,"Past seasons",data.on_history,"How the food stores changed in past months").size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_rule(self)
	add_child(T.make_label("STORES BY KIND",12,T.MUTED))
	for item:Dictionary in data.rows:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);add_child(row)
		row.add_child(FoodArt.picture(FoodArt.food(String(item.name)),160,72))
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(text)
		text.add_child(_voice(String(item.name),18))
		var refs:={"line":_line(text,"",13,T.BODY),"detail":null}
		var open:bool=data.selected==item.name
		_button(row,"Hide" if open else "Details",func():data.on_select.call(String(item.name)),"What this store holds and what spoils").size_flags_vertical=Control.SIZE_SHRINK_CENTER
		if open:
			var detail:=HBoxContainer.new();add_child(detail)
			refs.detail=_line(detail,"",13,T.MUTED)
			_button(detail,"Where it comes from",data.on_sources,"Known sources, preparation and preservation")
		_rule(self)
		(_refs.rows as Array).append(refs)
	# One plain way to ask for more hands, with the current choice marked.
	if bool(data.can_direct):
		var who:=leader if not leader.is_empty() else "the leader"
		var focus:=String(data.get("focus",""))
		var current:="" if bool(data.managed) else (focus if focus in ["provisions","water"] else "other")
		_choices(self,"Ask %s for more hands on" % who,[
			{"id":"provisions","label":"Food","tip":"More people gather, hunt, fish and carry food. Other work slows.","on_press":func():data.on_focus.call("provisions")},
			{"id":"water","label":"Water","tip":"More people find, reach and carry water. Other work slows.","on_press":func():data.on_focus.call("water")},
			{"id":"","label":"Let %s decide" % who,"tip":"The leader spreads the work across what the place needs.","on_press":func():data.on_focus.call("")},
		],current)
	var footer:=HFlowContainer.new();footer.add_theme_constant_override("h_separation",8);add_child(footer)
	_button(footer,"Where food comes from",data.on_sources,"Known sources, preparation and preservation")
	_button(footer,"Deliveries between places",data.on_trade,"Food and goods on the road between your settlements")
	_fill()

## The live refresh: the same nodes take the day's sentences while the page
## keeps its shape; a page of another shape is drawn afresh.
func update_block(block:Dictionary)->bool:
	if _refs.is_empty() or shape_of(block)!=_shape:return false
	data=block
	_fill()
	return true

## What the page's nodes are: who is named, whether the planners' word is
## shown, the stores in order with the one opened, and the choices offered.
static func shape_of(block:Dictionary)->Array:
	var rows:Array=[]
	for item:Dictionary in block.get("rows",[]):rows.append(String(item.get("name","")))
	var focus:=String(block.get("focus",""))
	var current:="" if bool(block.get("managed",true)) else (focus if focus in ["provisions","water"] else "other")
	return [String(block.get("leader_name","")),String(block.get("food_plan",""))!="",rows,String(block.get("selected","")),bool(block.get("can_direct",false)),current]

## Every sentence on the page that follows the day.
func _fill()->void:
	var flow:Dictionary={}
	for key:String in data.flow:flow[key.to_lower()]=float(data.flow[key])
	var leader:=String(data.get("leader_name",""))
	_put(_refs.owner,("%s decides the daily food work" % leader if not leader.is_empty() else "The local leader decides the daily food work") if bool(data.managed) else "You asked for extra hands on part of the work")
	_put(_refs.city,String(data.city))
	var food:=Words.food(float(data.food_days),flow,data.has("food_days") and float(data.food_days)>=0.0)
	_fill_reading(_refs.food,String(food.headline),String(food.trend),String(food.cause),String(food.tone))
	_put(_refs.flow,Words.flow_sentence(flow))
	if _refs.has("plan"):_put(_refs.plan,String(data.food_plan))
	var water:Dictionary=Words.water(data.water)
	_fill_reading(_refs.water,String(water.headline),"",String(water.cause),String(water.tone))
	var forecast:Dictionary=data.forecast90
	var shortage:=int(forecast.get("first_shortage_day",-1))
	var ahead:=""
	if forecast.is_empty():ahead="Looking ahead: the first season's forecast is not made yet."
	elif shortage>0:ahead="Looking ahead: food runs short in "+Plain.duration_text(float(shortage))+" if the seasons go as expected."
	else:
		var ending:=float(forecast.get("ending_days",-1.0))
		ahead="Looking ahead: no shortage expected in the next three months"+(", with food for "+Plain.span_text(ending)+" left at the end." if ending>0.0 else ".")
	_put(_refs.forecast,ahead,tone_color("bad") if shortage>0 else T.BODY)
	var eaten:=maxf(0.5,float(flow.get("eaten",0.0)))
	for index in mini((data.rows as Array).size(),(_refs.rows as Array).size()):
		var item:Dictionary=data.rows[index];var refs:Dictionary=_refs.rows[index]
		var stock:=float(item.stock);var lost:=float(item.lost)
		var line:="%s rations" % Plain.number(stock)
		if stock>0.05:line+=", enough on their own for "+Plain.span_text(stock/eaten)
		if lost>0.05:line+="; %s spoil each day" % Plain.number(lost)
		_put(refs.line,line,tone_color("warn") if lost>0.05 and lost>stock*0.02 else T.BODY)
		if refs.detail!=null:_put(refs.detail,String(item.detail))

## A reading's words (see home_ledger._reading) written into its box.
func _fill_reading(box:VBoxContainer,headline:String,trend:String,cause:String,tone:String)->void:
	_put(box.get_child(0),headline)
	var detail:=(trend_word(trend)+": " if not trend.is_empty() else "")+cause
	_put(box.get_child(1),detail.left(1).to_upper()+detail.substr(1),tone_color(tone))
