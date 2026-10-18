extends VBoxContainer
## Living Pantry: a representative landscape carries the current food reading.
## All values and commands come from the provider; this view owns no game state.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const ART_PATH:="res://assets/ui/provisions/living-pantry.jpg"
const SCENE_INK:=Color("fff4db")
const SCENE_MUTED:=Color("e8e3cf")
const SCENE_WARN:=Color("ffd69a")
const FLOW_CELLS := [["Produced", "Brought in", null], ["Taken", "Taken in", null], ["Eaten", "Meals eaten", "eaten"], ["Spoiled", "Spoiled", "spoiled"], ["Keeping", "Lost in drying", "keeping"], ["Net", "Store change", "net"]]
const SOURCE_ICONS := {"Wild gathering":"gather", "Hunting":"hunt", "Fishing":"fish", "Cultivation":"tend"}
const SOURCE_NAMES := ["Cultivation", "Wild gathering", "Hunting", "Fishing"]

var data:Dictionary={}
var _storage_grid:Control
var daily_values:Dictionary={}
var flow_strip:Control
var flow_bar:FlowBar
var _shape:Array=[]
var _refs:Dictionary={}
var _grids:Array[GridContainer]=[]
var _margin:MarginContainer
var _body:VBoxContainer
var _scene:PantryScene
var _details_open:=false
var _delivery_page:=0
var _choices:Dictionary={}
var _layout_width:=-1.0

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="ProvisionsLedger"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",0)
	_shape=shape_of(block)
	_refs={"stores":[],"sources":[],"deliveries":[],"source_labels":{}}
	_margin=MarginContainer.new();_margin.name="PantryReadingWidth";add_child(_margin)
	_body=VBoxContainer.new();_body.add_theme_constant_override("separation",14);_margin.add_child(_body)
	_build_scene()
	_refs.source_grid=GridContainer.new();_refs.source_grid.name="FoodSourcesCompact";_refs.source_grid.columns=2;_refs.source_grid.add_theme_constant_override("h_separation",12);_refs.source_grid.add_theme_constant_override("v_separation",8);_body.add_child(_refs.source_grid)
	_storage_grid=preload("res://scripts/hud/storage_capacity_grid.gd").new();_body.add_child(_storage_grid)
	_build_daily_flow()
	_build_commands()
	_build_details()
	resized.connect(_layout)
	_body.resized.connect(_layout)
	_fill();_layout.call_deferred()

func _build_scene()->void:
	_scene=PantryScene.new();_scene.name="PantryPainting"
	_scene.custom_minimum_size.y=380;_scene.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_scene.tooltip_text="A representative food landscape. The figures describe this settlement; painted buildings and people are illustrative."
	if ResourceLoader.exists(ART_PATH):_scene.picture=load(ART_PATH)
	elif FileAccess.file_exists(ART_PATH):_scene.picture=ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(ART_PATH)))
	_body.add_child(_scene)
	for source_name:String in SOURCE_NAMES:
		var box:=VBoxContainer.new();box.name="Source_"+("Gathering" if source_name=="Wild gathering" else source_name)
		box.add_theme_constant_override("separation",0);_scene.add_child(box)
		var title:=_scene_label(source_name,14,true);box.add_child(title)
		title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var value:=_scene_label("",25,true);value.name="Value";box.add_child(value)
		var status:=_scene_label("",14);status.name="Status";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(status)
		_refs.source_labels[source_name]={"box":box,"title":title,"value":value,"status":status}
	var story:=VBoxContainer.new();story.name="PantrySituation";story.add_theme_constant_override("separation",2);_scene.add_child(story)
	_refs.story=story
	story.add_child(_scene_label("OUR DAILY BREAD",14,true))
	_refs.headline=_scene_label("",35,true);_refs.headline.add_theme_font_override("font",T.font("voice"));story.add_child(_refs.headline)
	var reserve:=VBoxContainer.new();reserve.name="PantryReserve";reserve.add_theme_constant_override("separation",1);_scene.add_child(reserve);_refs.reserve=reserve
	reserve.add_child(_scene_label("IN OUR STORES",14,true))
	var amount:=HBoxContainer.new();amount.add_theme_constant_override("separation",8);reserve.add_child(amount)
	_refs.reserve_value=_scene_label("",52,true);_refs.reserve_value.name="ReserveValue";amount.add_child(_refs.reserve_value)
	_refs.reserve_unit=_scene_label("days of food",19);_refs.reserve_unit.size_flags_vertical=Control.SIZE_SHRINK_CENTER;amount.add_child(_refs.reserve_unit)
	_refs.horizon=_scene_label("",14);_refs.horizon.visible=false;reserve.add_child(_refs.horizon)
	_refs.stock=_scene_label("",16);reserve.add_child(_refs.stock)
	_refs.forecast=_scene_label("",15,true);_refs.forecast.name="PantryForecast";_refs.forecast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;reserve.add_child(_refs.forecast)
	var water_box:=VBoxContainer.new();water_box.name="PantryWater";water_box.add_theme_constant_override("separation",3);_scene.add_child(water_box);_refs.water_box=water_box
	water_box.add_child(_scene_label("WATER",14,true))
	_refs.water_status=_scene_label("",20,true);_refs.water_status.name="WaterStatus";_refs.water_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;water_box.add_child(_refs.water_status)
	_refs.water_amounts=_scene_label("",14);_refs.water_amounts.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;water_box.add_child(_refs.water_amounts)
	_refs.water_place=_scene_label("",14);_refs.water_place.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;water_box.add_child(_refs.water_place)

func _build_daily_flow()->void:
	flow_strip=preload("res://scripts/hud/resource_flow_strip.gd").new();_body.add_child(flow_strip)
	var coverage:=HFlowContainer.new();coverage.name="NeedsAndDelivery";coverage.add_theme_constant_override("h_separation",24);coverage.add_theme_constant_override("v_separation",10);_body.add_child(coverage)
	_refs.food_coverage=preload("res://scripts/hud/comparison_tile.gd").new();_refs.food_coverage.name="FoodCoverage";coverage.add_child(_refs.food_coverage)
	_refs.water_coverage=preload("res://scripts/hud/comparison_tile.gd").new();_refs.water_coverage.name="WaterCoverage";coverage.add_child(_refs.water_coverage)
	var daily_box:=VBoxContainer.new();daily_box.name="PantryDailyFlow";daily_box.add_theme_constant_override("separation",6);_body.add_child(daily_box)
	var daily:=HFlowContainer.new();daily.name="Daily";daily.add_theme_constant_override("h_separation",28);daily.add_theme_constant_override("v_separation",8);daily_box.add_child(daily)
	# The main causal chain is first; losses stay adjacent as quieter evidence.
	for key:String in ["Produced","Taken","Eaten","Net","Spoiled","Keeping"]:
		var cell:=VBoxContainer.new();cell.name="Cell_"+key;cell.add_theme_constant_override("separation",1);daily.add_child(cell)
		var caption:=""
		for pair:Array in FLOW_CELLS:
			if pair[0]==key:caption=pair[1]
		cell.add_child(S.label(caption,14,T.INK_MUTED))
		var value:=S.voice("",25 if key in ["Produced","Eaten","Net"] else 19);value.name="Daily_"+key;cell.add_child(value);daily_values[key]=value
	flow_bar=FlowBar.new();flow_bar.name="FlowBar";flow_bar.custom_minimum_size=Vector2(0,5);daily_box.add_child(flow_bar)
	var caption:=HFlowContainer.new();caption.add_theme_constant_override("h_separation",12);daily_box.add_child(caption)
	_refs.today_side=S.label("",14,T.INK_MUTED,true);caption.add_child(_refs.today_side)
	_refs.period=S.label("",14,T.INK_MUTED);caption.add_child(_refs.period)
	_refs.missions=S.label("",14,T.INK_MUTED);_refs.missions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;daily_box.add_child(_refs.missions)

func _build_commands()->void:
	var row:=HFlowContainer.new();row.name="PantryActions";row.add_theme_constant_override("h_separation",12);row.add_theme_constant_override("v_separation",8);_body.add_child(row)
	_refs.work_caption=S.label("",16,T.INK,true);_refs.work_caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER;_refs.work_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_refs.work_caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(_refs.work_caption)
	_refs.assign=S.verb("Assign workers",func():_invoke("on_assign"),"Open the food allocation and its consequences.",false,true);_refs.assign.name="AssignFoodWorkers";row.add_child(_refs.assign)
	_refs.assign_water=S.verb("Water carriers",func():_invoke("on_assign_water"),"Open Logistics. These workers carry water, supplies and materials.");_refs.assign_water.name="AssignWaterCarriers";row.add_child(_refs.assign_water)
	_refs.talk=S.verb("Talk with the leader",func():_invoke("on_talk"),"Speak with this settlement’s leader.");_refs.talk.name="TalkFoodLeader";row.add_child(_refs.talk)
	_refs.deliveries_button=S.verb("Deliveries",func():_invoke("on_trade"),"Every delivery between your settlements, on the road and arrived.");row.add_child(_refs.deliveries_button)
	var choices:=HFlowContainer.new();choices.name="PantryDirection";choices.add_theme_constant_override("h_separation",8);choices.add_theme_constant_override("v_separation",6);_body.add_child(choices);_refs.choices=choices
	_refs.direction=S.label("",14,T.INK_MUTED);_refs.direction.size_flags_vertical=Control.SIZE_SHRINK_CENTER;choices.add_child(_refs.direction)
	for spec:Array in [["provisions","Ask for more food","Provisions"],["water","Ask for more water","Water"],["","Let leader decide",""]]:
		var focus_id:=String(spec[0])
		var button:=S.verb(String(spec[1]),func():_invoke("on_focus",focus_id))
		button.name="Choice_"+String(spec[2]);button.toggle_mode=true;choices.add_child(button);_choices[focus_id]=button
		var selected:StyleBoxFlat=button.get_theme_stylebox("normal").duplicate()
		selected.border_color=T.ACTION;selected.border_width_bottom=2;selected.border_width_top=2;selected.border_width_left=2;selected.border_width_right=2
		button.add_theme_stylebox_override("pressed",selected)

func _build_details()->void:
	_refs.details_toggle=S.verb("Stores, source health & history",_toggle_details,"Read the exact store counts, land condition, fire and deliveries.")
	_refs.details_toggle.name="PantryDetails";_refs.details_toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;_body.add_child(_refs.details_toggle)
	var details:=VBoxContainer.new();details.name="PantryEvidence";details.add_theme_constant_override("separation",14);details.visible=false;_body.add_child(details);_refs.details=details
	var grid:=S.columns(details,"FoodEvidenceColumns",340.0,2);_grids.append(grid)
	var stores:=VBoxContainer.new();stores.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stores.add_theme_constant_override("separation",6);grid.add_child(stores);_refs.stores_column=stores
	var sources:=VBoxContainer.new();sources.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sources.add_theme_constant_override("separation",6);grid.add_child(sources);_refs.sources_column=sources
	var stores_head:=S.head(stores,"What we have");_refs.stores_side=stores_head.side
	for item:Dictionary in data.get("rows",[]):
		_refs.stores.append(S.row(stores,{"id":String(item.name),"icon":"Food" if String(item.name)!="Stored food" else "Clay","label":String(item.name)}))
	_refs.storage_capacity=S.label("",14,T.INK_MUTED);_refs.storage_capacity.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stores.add_child(_refs.storage_capacity)
	_refs.fire=S.row(stores,{"id":"fire","icon":"fetch","icon_kind":"people","label":"Hearth fire","bar_width":60.0})
	stores.add_child(S.label("Days of food over time",14,T.INK_MUTED))
	var spark:=Spark.new();spark.name="FoodHistory";spark.custom_minimum_size=Vector2(80,36);spark.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stores.add_child(spark);_refs.spark=spark
	_refs.past_range=S.label("",14,T.INK_MUTED);stores.add_child(_refs.past_range)
	var sources_head:=S.head(sources,"Where it comes from");_refs.sources_side=sources_head.side
	for source:Dictionary in data.get("sources",[]):
		var source_name:=String(source.get("name","Source"))
		_refs.sources.append(S.row(sources,{"id":source_name,"icon":String(SOURCE_ICONS.get(source_name,"gather")),"icon_kind":"people","label":source_name,"bar_width":60.0}))
	_refs.water_row=S.row(sources,{"id":"water_source","icon":"Freshwater","label":"Water"})
	_refs.water_map=S.verb("Show water on map",func():_invoke("on_water_map"));sources.add_child(_refs.water_map)
	var road:=VBoxContainer.new();road.name="PantryDeliveries";road.add_theme_constant_override("separation",4);details.add_child(road);_refs.road=road
	S.head(road,"On the road")
	for index:int in 6:_refs.deliveries.append(S.row(road,{"id":"delivery_"+str(index),"label":""}))
	var pager:=HBoxContainer.new();pager.add_theme_constant_override("separation",8);road.add_child(pager);_refs.delivery_pager=pager
	_refs.previous=S.verb("Previous",func():_delivery_page=maxi(0,_delivery_page-1);_fill());pager.add_child(_refs.previous)
	_refs.delivery_page=S.label("",14,T.INK_MUTED);_refs.delivery_page.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pager.add_child(_refs.delivery_page)
	_refs.next=S.verb("Next",func():_delivery_page+=1;_fill());pager.add_child(_refs.next)

func _invoke(key:String,argument:Variant=null)->void:
	var action:Variant=data.get(key)
	if not action is Callable:return
	if argument==null:action.call()
	else:action.call(argument)

func _toggle_details()->void:
	_details_open=not _details_open;_refs.details.visible=_details_open
	_refs.details_toggle.text="Hide pantry details" if _details_open else "Stores, source health & history"

func capture_view_state()->Dictionary:
	return {"details_open":_details_open,"delivery_page":_delivery_page}

func restore_view_state(state:Dictionary)->void:
	_details_open=bool(state.get("details_open",false));_delivery_page=maxi(0,int(state.get("delivery_page",0)))
	_refs.details.visible=_details_open;_refs.details_toggle.text="Hide pantry details" if _details_open else "Stores, source health & history"
	_fill()

func _scene_label(words:String,font_size:int,strong:bool=false)->Label:
	var label:=S.label(words,font_size,SCENE_INK,strong)
	label.add_theme_color_override("font_shadow_color",Color(0.025,0.05,0.04,0.92))
	label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2)
	label.add_theme_constant_override("shadow_outline_size",3)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _layout()->void:
	if _scene==null:return
	var side:=maxi(0,roundi((size.x-1360.0)/2.0))
	_margin.add_theme_constant_override("margin_left",side);_margin.add_theme_constant_override("margin_right",side)
	var width:=maxf(1.0,_body.size.x)
	if width<200:return
	_layout_width=width
	var compact:=width<680
	_refs.source_grid.visible=compact
	for source_name:String in SOURCE_NAMES:
		var refs:Dictionary=_refs.source_labels[source_name]
		var parent:Node=_refs.source_grid if compact else _scene
		if refs.box.get_parent()!=parent:refs.box.reparent(parent)
		refs.title.add_theme_color_override("font_color",T.INK if compact else SCENE_INK)
		refs.value.add_theme_color_override("font_color",T.INK if compact else SCENE_INK)
		refs.status.add_theme_color_override("font_color",T.INK_MUTED if compact else SCENE_MUTED)
		refs.value.add_theme_font_size_override("font_size",21 if compact else 25)
		for label:Label in [refs.title,refs.value,refs.status]:label.add_theme_constant_override("shadow_outline_size",0 if compact else 3);label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT if compact else Color(0.025,0.05,0.04,.92))
	_refs.water_box.visible=not compact
	if compact:
		_scene.custom_minimum_size.y=240
		_refs.headline.add_theme_font_size_override("font_size",25)
		_refs.headline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_refs.reserve_value.add_theme_font_size_override("font_size",40)
		_refs.story.position=Vector2(14,14);_refs.story.size=Vector2(width-28,70)
		_refs.reserve.position=Vector2(14,96);_refs.reserve.size=Vector2(width-28,132)
		for grid:GridContainer in _grids:S.flow(grid,width)
		S.compact(self,width)
		return
	_refs.headline.autowrap_mode=TextServer.AUTOWRAP_OFF
	var height:=clampf(width*0.30,330.0,390.0)
	_scene.custom_minimum_size.y=height
	_place(_refs.source_labels["Cultivation"].box,Vector2(0.045,0.06),Vector2(0.23,0.23),width,height)
	_place(_refs.source_labels["Wild gathering"].box,Vector2(0.76,0.06),Vector2(0.23,0.23),width,height)
	_place(_refs.source_labels["Hunting"].box,Vector2(0.76,0.27),Vector2(0.23,0.23),width,height)
	_place(_refs.source_labels["Fishing"].box,Vector2(0.48,0.38),Vector2(0.23,0.23),width,height)
	_place(_refs.story,Vector2(0.035,0.30),Vector2(0.43,0.27),width,height)
	_place(_refs.reserve,Vector2(0.035,0.58),Vector2(0.58,0.41),width,height)
	_place(_refs.water_box,Vector2(0.67,0.72),Vector2(0.30,0.27),width,height)
	_refs.headline.add_theme_font_size_override("font_size",35 if width>=1000 else 30)
	_refs.reserve_value.add_theme_font_size_override("font_size",52 if width>=1000 else 46)
	for grid:GridContainer in _grids:S.flow(grid,width)
	S.compact(self,width)

func _place(control:Control,at:Vector2,extent:Vector2,width:float,height:float)->void:
	control.position=Vector2(width*at.x,height*at.y)
	control.size=Vector2(width*extent.x,height*extent.y)

func update_block(block:Dictionary)->bool:
	if _refs.is_empty() or shape_of(block)!=_shape:return false
	data=block;_fill();return true

static func shape_of(block:Dictionary)->Array:
	var rows:Array=[]
	for item:Dictionary in block.get("rows",[]):rows.append(String(item.get("name","")))
	var sources:Array=[]
	for source:Dictionary in block.get("sources",[]):sources.append(String(source.get("name","")))
	return [rows,sources]

static func _current_focus(block:Dictionary)->String:
	var focus:=String(block.get("focus",""))
	return "" if bool(block.get("managed",true)) else (focus if focus in ["provisions","water"] else "other")

func _who()->String:
	return _who_of(data)

func _fill()->void:
	_storage_grid.fill(data.get("storage_rows",[]),data.get("on_expand_storage",Callable()),data.get("on_builders",Callable()))
	var amounts:=flow_amounts(data.get("flow",{}))
	var measured:=bool(data.get("flow_known",true))
	var stock:=0.0
	for row:Dictionary in data.get("rows",[]):stock+=float(row.get("stock",0))
	flow_strip.fill(S.n(float(amounts.Produced)+float(amounts.Taken))+" / day" if measured else "Unknown",S.n(stock),S.n(float(amounts.Eaten))+" eaten / day" if measured else "Unknown","Rations produced + taken in","Rations held now",("%s lost + %s to parties / day" % [S.n(float(amounts.Spoiled)+float(amounts.Keeping)),S.n(float(data.get("flow",{}).get("Missions",0)))]) if measured else "Daily flows not yet measured")
	var daily_need:=float(data.get("food_need",amounts.Eaten))
	var water:Dictionary=data.get("water",{})
	var need:=float(water.get("required_today",0.0))
	_fill_scene(amounts,water)
	_refs.food_coverage.fill("Daily meals","NEEDED",daily_need,"EATEN",float(amounts.Eaten),"rations / day","Food","Food actually consumed in the latest daily ledger. This includes provisioned field armies.")
	_refs.food_coverage.visible=measured and data.has("food_need")
	_refs.water_coverage.visible=water.has("required_today") and water.has("collected_today")
	if _refs.water_coverage.visible:_refs.water_coverage.fill("Daily water","NEEDED",need,"FETCHED",float(water.collected_today),"water units / day","Freshwater")
	var hands:=float(data.get("food_workers",0.0))
	S.put(_refs.work_caption,"Food effort: %s worker-equivalents · %d%%" % [S.n(hands),roundi(float(data.get("food_share",0.0))*100.0)])
	_refs.work_caption.tooltip_text="Effective worker-equivalents on food in this settlement; these are not a headcount. Assign workers opens the civilization-wide allocation.\n"+String(data.get("food_plan",""))
	_refs.assign.visible=data.get("on_assign") is Callable
	_refs.assign_water.visible=data.get("on_assign_water") is Callable
	_refs.talk.visible=data.get("on_talk") is Callable;_refs.talk.text="Talk with %s" % _who()
	_refs.deliveries_button.visible=bool(data.get("has_deliveries",false)) and data.get("on_trade") is Callable
	_refs.choices.visible=bool(data.get("can_direct",false)) and data.get("on_focus") is Callable
	S.put(_refs.direction,"%s directs the work" % _who().capitalize())
	for focus_id:String in _choices:
		var choice:Button=_choices[focus_id]
		choice.set_pressed_no_signal(_current_focus(data)==focus_id)
		choice.tooltip_text=("Let %s spread work across what this place needs." % _who()) if focus_id.is_empty() else ("Ask %s to put more people on %s. Other work slows." % [_who(),"gathering, hunting, fishing and carrying food" if focus_id=="provisions" else "finding, reaching and carrying water"])
	_choices[""].text="Let %s decide" % _who()
	_refs.fire.panel.visible=not (data.get("fire",{}) as Dictionary).is_empty()
	_refs.water_row.panel.visible=not (data.get("water_access",{}) as Dictionary).is_empty()
	_refs.water_map.visible=data.get("on_water_map") is Callable
	S.put(_refs.storage_capacity,"Storage room: %s rations. Excess food is discarded at the end of the day." % S.n(float(data.get("capacity",0.0))) if float(data.get("capacity",0.0))>0 else "No storage capacity recorded yet.")
	# The day's rations.
	for key:String in daily_values:
		var amount:=float(amounts.get(key,0))
		var words:=S.n(amount) if key!="Net" else S.signed(amount)
		if key in ["Eaten","Spoiled","Keeping"] and amount>=0.5:words="−"+S.n(amount)
		if key in ["Produced","Taken"] and amount>=0.5:words="+"+S.n(amount)
		S.put(daily_values[key],words,(T.RED_TEXT if amount<0 else T.GREEN_TEXT) if key=="Net" else T.INK)
	for key:String in ["Taken","Keeping"]:
		(daily_values[key].get_parent() as Control).visible=absf(float(amounts[key]))>=0.5
	(daily_values.Produced.get_parent() as Control).tooltip_text="Rations gathered, hunted, fished or harvested per day in the latest account."
	(daily_values.Taken.get_parent() as Control).tooltip_text="Food taken in from towns we hold."
	(daily_values.Eaten.get_parent() as Control).tooltip_text="Rations eaten per day in the latest account, including any provisioned field armies."
	(daily_values.Spoiled.get_parent() as Control).tooltip_text="Rations lost from stores in the latest daily account, including spoilage and any storage overflow. The store details give each kind."
	(daily_values.Keeping.get_parent() as Control).tooltip_text="Drying, smoking and canning make fresh food keep, and take some of its weight: about an eighth dried, a sixth smoked, a tenth canned."
	(daily_values.Net.get_parent() as Control).tooltip_text="The change in the stores over the day's count: brought in and taken in, less eaten, spoiled and lost in drying."
	var sent:=float(data.get("flow",{}).get("Missions",0))
	_refs.missions.visible=sent>=0.5
	S.put(_refs.missions,"Also today: %s rations went out with parties that left." % S.n(sent))
	S.put(_refs.today_side,"Stores are growing" if float(amounts.Net)>=0.5 else ("Stores are shrinking" if float(amounts.Net)<=-0.5 else "No change to stores today"),T.GREEN_TEXT if float(amounts.Net)>=0.5 else (T.RED_TEXT if float(amounts.Net)<=-0.5 else T.INK_MUTED))
	flow_bar.amounts=amounts;flow_bar.queue_redraw()
	# The stores, each with what spoiled of it today (they sum to Spoiled above).
	var rows:Array=data.get("rows",[])
	for index in mini(rows.size(),(_refs.stores as Array).size()):
		var item:Dictionary=rows[index]
		var amount:=float(item.get("stock",0.0));var lost:=float(item.get("lost",0.0))
		var note:=("%s spoiled today" % S.n(lost)) if lost>=0.5 else "nothing spoiled"
		if not measured:note="Losses not measured yet"
		if measured and amount>=0.5 and daily_need>0.0:note+=" · %s alone" % Plain.span_text(amount/daily_need)
		S.set_row(_refs.stores[index],{"label":String(item.name),"note":note,"note_color":T.AMBER_TEXT if lost>amount*0.02 and lost>=0.5 else T.INK_MUTED,"value":S.n(amount),
			"tag":"Empty" if amount<0.5 else "","tag_color":T.RED,"tip":String(item.get("detail",""))})
	S.put(_refs.stores_side,"%s spoiled today" % S.n(float(amounts.Spoiled)) if measured else "Store losses not measured yet")
	if _refs.has("fire"):
		var fire:Dictionary=data.get("fire",{})
		var lit:=bool(fire.get("available",false))
		var embers:=clampf(float(fire.get("embers",0.0)),0.0,1.0)
		var fuel:=float(data.get("fuel",-1.0))
		S.set_row(_refs.fire,{"label":"Hearth fire","note":("lit by "+String(fire.get("source","none")).replace("_"," ") if lit else "no one keeps a fire")+(" · %s wood smoked food today" % S.n(fuel) if fuel>=0.5 else ""),"value":"%d%%" % roundi(embers*100.0),"value_color":T.INK if lit else T.RED_TEXT,
			"ratio":embers,"bar_color":T.AMBER if lit else T.RED,"tag":"Out" if not lit else "","tag_color":T.RED,
			"tip":"%s\nKeeping it alive burned %s wood today; smoking meat and fish so they keep burned %s." % [String(fire.get("status","")),S.n(float(fire.get("maintenance_timber",0.0))),S.n(maxf(0.0,fuel))]})
	var points:Array=data.get("history",[])
	var spark:Control=_refs.spark
	if spark.get("points")!=points:spark.set("points",points);spark.queue_redraw()
	var low:=INF;var high:=-INF
	for point:Dictionary in points:
		if point.get("value")==null:continue
		low=minf(low,float(point.value));high=maxf(high,float(point.value))
	S.put(_refs.past_range,"%s to %s days" % [S.n(low),S.n(high)] if high>=low else "first count to come")
	# Where it comes from.
	var sources:Array=data.get("sources",[])
	var total_in:=0.0
	for source:Dictionary in sources:total_in+=float(source.get("produced",0.0))
	for index in mini(sources.size(),(_refs.sources as Array).size()):
		var source:Dictionary=sources[index]
		var amount:=float(source.get("produced",0.0))
		var ground:=clampf(float(source.get("source_health",1.0)),0.0,1.0)
		var overused:=bool(source.get("overused",false))
		var access:=String(source.get("access",""))
		var reach:=access in ["available","retrievable","retrievable game grounds","ambient wildlife only"]
		var tip:="Rations this source gave today."
		if source.has("renewable"):tip+=" The land nearby grows back about %s rations a day of it; taking more thins the game, fish or plants until they are rested." % S.n(float(source.renewable))
		var source_note:=access if not reach or access=="ambient wildlife only" else ("%d%% of daily food" % roundi(amount/maxf(1.0,total_in)*100.0) if amount>=0.5 else "")
		if source.has("source_health"):
			source_note+=("\n" if not source_note.is_empty() else "")+"Land supply: %d%% of original" % roundi(ground*100.0)
			tip+="\nThe land holds %d%% of its original supply." % roundi(ground*100.0)
		if bool(source.get("travel_limited",false)):
			source_note+="\nLimited while traveling"
			tip+=" This source is limited while the people are traveling."
		S.set_row(_refs.sources[index],{"label":String(source.get("name","")),"note":source_note,
			"value":("+"+S.n(amount)) if amount>=0.5 else "none","value_color":T.INK if amount>=0.5 else T.INK_MUTED,
			"ratio":ground if source.has("source_health") and (amount>=0.5 or source.has("renewable")) else -1.0,"bar_color":T.GREEN if ground>=0.8 else (T.AMBER if ground>=0.5 else T.RED),
			"tag":"Overused" if overused else ("Not known" if access=="practice not discovered" else ""),"tag_color":T.AMBER if overused else T.MUTED,"tip":tip})
	S.put(_refs.sources_side,"Supply bars compare land condition with its original capacity.")
	if _refs.has("water_row"):
		var w:Dictionary=data.get("water_access",{})
		var known:=bool(w.get("recognized",false))
		var near:=bool(w.get("accessible",false))
		var source_kind:=String(w.get("source_kind",""))
		var source_note:=source_kind.capitalize() if source_kind.to_lower() not in ["","none","unknown"] else "Known water source"
		var distance:=float(w.get("distance_km",-1.0))
		if distance>=0.0 and is_finite(distance):source_note+=", %s km away" % S.n(distance)
		else:source_note+=" · distance not recorded"
		S.set_row(_refs.water_row,{"label":"Water","note":source_note if known else "no stream, spring or lake known",
			"value":S.n(float(water.get("collected_today",0.0))) if need>0.0 else "—","tag":"In reach" if known and near else ("Too far" if known else "Unknown"),"tag_color":T.TEAL if known and near else T.RED,
			"tip":("Close enough to fetch every day; households and carriers bring it in." if near else "Too far to fetch every day. More carriers will not bring it closer.") if known else "More carriers cannot make water appear: scouts or a closer look at the map may find a source."})
	var shipments:Array=data.get("deliveries",[])
	var pages:=maxi(1,ceili(float(shipments.size())/6.0))
	_delivery_page=clampi(_delivery_page,0,pages-1)
	_refs.road.visible=not shipments.is_empty()
	_refs.delivery_pager.visible=pages>1
	_refs.previous.disabled=_delivery_page==0;_refs.next.disabled=_delivery_page>=pages-1
	S.put(_refs.delivery_page,"%d–%d of %d" % [_delivery_page*6+1,mini((_delivery_page+1)*6,shipments.size()),shipments.size()])
	for index:int in 6:
		var actual:=_delivery_page*6+index
		var row:Dictionary=_refs.deliveries[index]
		row.panel.visible=actual<shipments.size()
		if actual>=shipments.size():continue
		var shipment:Dictionary=shipments[actual]
		S.set_row(row,{"label":"%s from %s" % [String(shipment.get("resource","")).capitalize(),String(shipment.get("source_name",""))],"note":String(shipment.get("when","")),"value":S.n(float(shipment.get("quantity",0.0)))})
	if not measured:
		for value:Label in daily_values.values():S.put(value,"—",T.INK_MUTED)
		S.put(_refs.today_side,"Daily food not measured yet",T.INK_MUTED)
		flow_bar.amounts={};flow_bar.queue_redraw()
	S.put(_refs.period,"Rations per day · latest account" if measured else "Food flows are not measured yet")
	_layout.call_deferred()

func _fill_scene(amounts:Dictionary,water:Dictionary)->void:
	var measured:=bool(data.get("flow_known",true))
	var stock:=0.0
	for row:Dictionary in data.get("rows",[]):stock+=float(row.get("stock",0.0))
	var days:=float(data.get("food_days",-1.0))
	S.put(_refs.reserve_value,S.n(days) if days>=0 else S.n(stock),SCENE_INK)
	S.put(_refs.reserve_unit,"days of food" if days>=0 else "rations held",SCENE_MUTED)
	S.put(_refs.horizon,("Food stores are empty" if stock<=0 else "Food for %s" % EraWords.days_in_words(days)) if days>=0 else "Days of food not measured yet",SCENE_MUTED)
	S.put(_refs.stock,"%s rations held" % S.n(stock) if days>=0 else "",SCENE_MUTED)
	_refs.stock.visible=days>=0
	_refs.reserve.tooltip_text="Food held divided by the current daily need. Food continues to arrive: this is reserve cover, not a countdown to starvation."
	var forecast:Dictionary=data.get("forecast90",{})
	var shortage:=int(forecast.get("first_shortage_day",-1))
	var ending:=float(forecast.get("ending_days",-1.0))
	var forecast_words:="90-day outlook not available yet"
	if shortage==0:forecast_words="Food is short now in the 90-day outlook"
	elif shortage>0:forecast_words="A shortage is expected in %d days" % shortage
	elif forecast.has("first_shortage_day"):
		forecast_words=("In 90 days: %s days held · no shortage" % S.n(ending)) if ending>=0 else "No shortage in the current 90-day outlook"
	S.put(_refs.forecast,forecast_words,SCENE_WARN if shortage>=0 else SCENE_INK)
	_refs.forecast.tooltip_text="The latest 90-day estimate uses seasonal yields, spoilage and need. Food keeps arriving: reserve days are not a countdown to starvation."
	if int(data.get("forecast_day",-1))>=0:_refs.forecast.tooltip_text+="\nLast reckoned on day %d." % int(data.forecast_day)
	var headline:="Food held in reserve."
	if measured:
		headline="Building a reserve." if float(amounts.Net)>=0.5 else ("Drawing on our stores." if float(amounts.Net)<=-0.5 else "Holding our reserve.")
	if measured and data.has("food_intake_ratio") and float(data.get("food_home_need",data.get("food_need",0)))>0:
		var intake:=float(data.food_intake_ratio)
		if intake>=0.98:headline="People here are fed.\n"+headline
		elif intake>=0:headline="Not enough to eat.\n%d%% of local meals met." % roundi(intake*100.0)
	elif not measured:headline="The first count is ahead."
	S.put(_refs.headline,headline,SCENE_INK)
	var sources:Dictionary={}
	for source:Dictionary in data.get("sources",[]):sources[String(source.get("name",""))]=source
	for source_name:String in SOURCE_NAMES:
		var refs:Dictionary=_refs.source_labels[source_name]
		var source:Dictionary=sources.get(source_name,{})
		var known:=not source.is_empty() and measured
		S.put(refs.value,(S.n(float(source.get("produced",0)))+" / day") if known else "—",T.INK if _layout_width>0 and _layout_width<680 else SCENE_INK)
		var access:=String(source.get("access",""))
		var status:="Not measured yet" if not known else ""
		if access=="practice not discovered":status="Not discovered"
		elif bool(source.get("overused",false)):status="Overused"
		elif source.has("source_health") and float(source.source_health)<0.5:status="Depleted"
		elif not access.is_empty() and access not in ["available","retrievable","retrievable game grounds"]:status=access.capitalize()
		var travel_limited:=bool(source.get("travel_limited",false))
		if travel_limited:status+=(" · " if not status.is_empty() else "")+"Travel limited"
		S.put(refs.status,status,SCENE_WARN if bool(source.get("overused",false)) or travel_limited or status=="Depleted" else SCENE_MUTED)
		refs.status.visible=not status.is_empty()
		var tip:="Rations brought in at the latest daily count."
		if source.has("renewable"):tip+=" Nearby supply renews at about %s rations a day." % S.n(float(source.renewable))
		if source.has("source_health"):tip+=" Land condition: %d%% of original supply." % roundi(float(source.source_health)*100)
		if travel_limited:tip+=" This source is limited while the people are traveling."
		refs.box.tooltip_text=tip
	var need:=float(water.get("required_today",0))
	var water_known:=need>0 and water.has("intake_ratio")
	var ratio:=float(water.get("intake_ratio",-1))
	S.put(_refs.water_status,"Drinking needs met" if water_known and ratio>=0.999 else ("%d%% of drinking needs met" % roundi(ratio*100) if water_known else "Water not measured yet"),SCENE_INK if ratio>=0.98 or not water_known else SCENE_WARN)
	S.put(_refs.water_amounts,"%s collected · %s needed" % [S.n(float(water.get("collected_today",0))),S.n(need)] if water_known else "",SCENE_MUTED)
	_refs.water_amounts.visible=water_known
	var access:Dictionary=data.get("water_access",{})
	var place:=""
	if not access.is_empty():
		if not bool(access.get("recognized",false)):place="No water source known"
		elif not bool(access.get("accessible",false)):place="Known water is too far to fetch"
	S.put(_refs.water_place,place,SCENE_WARN);_refs.water_place.visible=not place.is_empty()
	_refs.water_box.tooltip_text="Drinking needs met uses actual water intake, including stored water. Collected water alone is not the same measure."

class PantryScene extends Control:
	var picture:Texture2D
	var _vertical:GradientTexture2D
	var _left:GradientTexture2D
	func _init()->void:
		_vertical=_shade(PackedFloat32Array([0.0,0.30,0.44,0.74,1.0]),PackedColorArray([Color(0.025,0.06,0.045,0.30),Color(0.025,0.06,0.045,0.02),Color(0.025,0.06,0.045,0.10),Color(0.025,0.06,0.045,0.58),Color(0.025,0.06,0.045,0.86)]),true)
		_left=_shade(PackedFloat32Array([0.0,0.52,1.0]),PackedColorArray([Color(0.025,0.06,0.045,0.32),Color(0.025,0.06,0.045,0),Color(0.025,0.06,0.045,0)]),false)
	func _shade(offsets:PackedFloat32Array,colors:PackedColorArray,vertical:bool)->GradientTexture2D:
		var ramp:=Gradient.new();ramp.offsets=offsets;ramp.colors=colors
		var texture:=GradientTexture2D.new();texture.gradient=ramp
		texture.width=4 if vertical else 256;texture.height=256 if vertical else 4
		texture.fill_from=Vector2.ZERO;texture.fill_to=Vector2.DOWN if vertical else Vector2.RIGHT
		return texture
	func _ready()->void:
		clip_contents=true;mouse_filter=Control.MOUSE_FILTER_PASS
		texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		resized.connect(queue_redraw)
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("1b3030"))
		if picture!=null and size.x>0 and size.y>0:
			var source_size:=picture.get_size()
			var shown_height:=minf(source_size.y,source_size.x*size.y/size.x)
			draw_texture_rect_region(picture,Rect2(Vector2.ZERO,size),Rect2(0,0,source_size.x,shown_height))
		# One continuous texture per shade avoids overlapping translucent band
		# edges at fractional UI scales; the painting keeps its natural colour.
		draw_texture_rect(_vertical,Rect2(Vector2.ZERO,size),false)
		draw_texture_rect(_left,Rect2(0,size.y*0.28,size.x,size.y*0.72),false)

## The strip's figures (the dock draws them under the tabs): food in store
## against the room for it, the 90-day outlook in days, water fetched against
## the day's need, the hands on food. The top bar's days are not repeated.
const KPI_LABELS:={"store":"Food in store","ahead":"In 90 days","water":"Water today","hands":"Hands on food"}
static func kpis(data:Dictionary)->Array:
	return S.dock_kpis(kpi_items(data),KPI_LABELS)

static func kpi_items(data:Dictionary)->Array:
	var out:Array=[]
	# Food in store against the room for it.
	var stock:=0.0
	for item:Dictionary in data.get("rows",[]):stock+=float(item.get("stock",0.0))
	var room:=float(data.get("capacity",0.0))
	var full:=stock/room if room>0.0 else -1.0
	out.append(S.kpi_item("store",{"value":S.n(stock),"ratio":clampf(full,0.0,1.0) if full>=0.0 else -1.0,"color":T.RED if full>=0.98 else (T.AMBER if full>=0.85 else T.GREEN),
		"sub":("of %s room" % S.n(room)) if room>0.0 else "no granary yet",
		"tip":"Rations held in every store here. Food beyond the room the pits, granaries and sealed jars give is thrown out at the end of the day.\n%s" % String(data.get("lean",""))}))
	# The outlook in days, the same unit as the top bar's food.
	var forecast:Dictionary=data.get("forecast90",{})
	var shortage:=int(forecast.get("first_shortage_day",-1))
	var ending:=float(forecast.get("ending_days",-1.0))
	var ahead:={"value":"—","sub":"not reckoned yet","ratio":-1.0,"tip":"The 90-day outlook is reckoned each week from the season's yields, spoilage and need."}
	if shortage>=0:
		ahead={"value":"Short now" if shortage==0 else "Short in %d days" % shortage,"value_color":T.RED_TEXT,"sub":"at the season's yields","ratio":clampf(float(shortage)/90.0,0.0,1.0),"color":T.RED,"edge":T.RED,
			"tip":"At the season's yields, spoilage and need, food runs short in %s." % Plain.duration_text(float(shortage))}
	elif forecast.has("first_shortage_day"):
		ahead={"value":preload("res://scripts/hud/era_words.gd").days_in_words(maxf(0.0,ending)) if ending>=0.0 else "—","sub":"of food left · no shortage","ratio":clampf(ending/maxf(90.0,ending),0.0,1.0) if ending>=0.0 else -1.0,"color":T.GREEN,
			"tip":"Days of food in store 90 days from now, at the season's yields, spoilage and need. No shortage is expected before then."}
	out.append(S.kpi_item("ahead",ahead))
	# Water fetched against the day's need (the top bar holds the days in store).
	var water:Dictionary=data.get("water",{})
	var wet:=Words.water(water)
	var need:=float(water.get("required_today",0.0))
	if need>0.0:
		var ratio:=clampf(float(water.get("intake_ratio",0.0)),0.0,1.0)
		out.append(S.kpi_item("water",{"value":"%d%%" % roundi(ratio*100.0),"value_color":(T.RED_TEXT if String(wet.tone)=="bad" else T.AMBER_TEXT) if ratio<0.98 else T.INK,"ratio":ratio,"color":T.TEAL if ratio>=0.98 else (T.AMBER if ratio>=0.8 else T.RED),
			"sub":"of %s drinks needed" % S.n(need),
			"tip":"%s.\nYesterday %s drinks were fetched for the %s needed; %s are kept in store. One drink is one person's water for a day." % [String(wet.sentence).trim_suffix("."),S.n(float(water.get("collected_today",0.0))),S.n(need),S.n(float(water.get("stored",0.0)))]}))
	else:out.append(S.kpi_item("water",{"value":"—","sub":"counted after the first day","ratio":-1.0}))
	# The hands on food, against everyone at work.
	var hands:=float(data.get("food_workers",0.0))
	var share:=float(data.get("food_share",0.0))
	out.append(S.kpi_item("hands",{"value":S.n(hands),"ratio":clampf(share,0.0,1.0),"color":T.GOLD,"sub":"%d in 100 at work" % roundi(share*100.0),
		"tip":(String(data.get("food_plan",""))+"\n" if String(data.get("food_plan",""))!="" else "")+("%s decides the daily food work." % _who_of(data).capitalize() if bool(data.get("managed",true)) else "You asked for extra hands on part of the work.")}))
	return out

static func _who_of(block:Dictionary)->String:
	var who:=String(block.get("leader_name",""))
	return who if not who.is_empty() else "the leader"

## The day's terms as the engine gives them.
static func flow_amounts(flow:Dictionary)->Dictionary:
	var out:={}
	for key:String in ["Produced","Taken","Eaten","Spoiled","Keeping","Net"]:out[key]=float(flow.get(key,0))
	return out

## One bar for the day's food: what was eaten, spoiled, lost in drying and
## kept, each a share of everything that left or stayed.
class FlowBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var amounts:Dictionary={}
	static func colors()->Dictionary:
		return {"eaten":T.AMBER,"spoiled":T.RED,"keeping":T.TEAL,"net":T.GREEN}
	func _draw()->void:
		var parts:Array=[]
		for pair:Array in FLOW_CELLS:
			if pair[2]==null:continue
			var amount:=float(amounts.get(pair[0],0.0))
			# A day the stores shrank has no "kept" share.
			if String(pair[0])=="Net":amount=maxf(0.0,amount)
			if amount>0.0:parts.append([amount,colors()[pair[2]]])
		draw_rect(Rect2(Vector2.ZERO,size),Color(T.INK,0.10))
		var total:=0.0
		for part:Array in parts:total+=float(part[0])
		if total<=0.0:return
		var x:=0.0
		for part:Array in parts:
			var width:=size.x*float(part[0])/total
			draw_rect(Rect2(x,0,maxf(1.0,width-1.0),size.y),part[1])
			x+=width
