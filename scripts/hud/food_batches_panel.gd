extends VBoxContainer
const B=preload("res://scripts/food_batches.gd")
const K=preload("res://scripts/food_batch_knowledge.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const UI_FONT:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
var subject:=""
# Retained as a hidden plain-text accessibility/testing summary. The visible
# inspector is deliberately composed from metrics, conditions and lot rows.
var details:Label
var metrics:Dictionary={}
var conditions:Label
var lots_box:VBoxContainer
var install_button:Button
var elapsed:=0.0

func _ready()->void:
	if not K.METHODS.has(subject):return
	add_theme_constant_override("separation",8)
	details=Label.new();details.visible=false;add_child(details)
	var metric_grid:=GridContainer.new();metric_grid.columns=3;metric_grid.add_theme_constant_override("h_separation",6);metric_grid.add_theme_constant_override("v_separation",6);add_child(metric_grid)
	for spec:Array in [["installed","INSTALLED"],["capacity","CAPACITY / DAY"],["throughput","TODAY"],["available","AVAILABLE"],["process","IN PROCESS"],["loss","LOSS TODAY"]]:metrics[spec[0]]=_metric(metric_grid,String(spec[1]))
	var condition_card:=PanelContainer.new();condition_card.add_theme_stylebox_override("panel",T.brief_style("warn"));add_child(condition_card)
	var condition_stack:=VBoxContainer.new();condition_stack.add_theme_constant_override("separation",3);condition_card.add_child(condition_stack)
	_label(condition_stack,"OPERATING CONDITIONS",10,T.GOLD)
	conditions=_label(condition_stack,"",12,T.BODY,true)
	lots_box=VBoxContainer.new();lots_box.add_theme_constant_override("separation",4);add_child(lots_box)
	install_button=Button.new();install_button.text="INSTALL ANOTHER SETUP";install_button.clip_text=true;install_button.custom_minimum_size.y=34
	install_button.add_theme_font_override("font",UI_FONT);install_button.add_theme_font_size_override("font_size",12)
	install_button.add_theme_stylebox_override("normal",T.action_button_style(true));install_button.add_theme_stylebox_override("hover",T.action_button_style(true,true));add_child(install_button)
	install_button.pressed.connect(func()->void:
		var result:=B.install(subject);install_button.tooltip_text=String(result.get("message",result.get("error","")));refresh())
	refresh()

func _label(parent:Node,text_value:String,size_value:int,color:Color,wrap:=false)->Label:
	var value:=Label.new();value.text=text_value;value.add_theme_font_override("font",UI_FONT);value.add_theme_font_size_override("font_size",size_value);value.add_theme_color_override("font_color",color)
	value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF;parent.add_child(value);return value

func _metric(parent:Node,caption:String)->Label:
	var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",T.tile_style());parent.add_child(card)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",1);card.add_child(stack)
	_label(stack,caption,9,T.MUTED)
	return _label(stack,"—",16,T.INK)

func _lot_row(item:Dictionary)->void:
	var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",T.row_style(T.TEAL));lots_box.add_child(card)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);card.add_child(row)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy)
	_label(copy,"LOT %d · %s" % [int(item.id),String(item.kind).replace("_"," ").capitalize()],11,T.INK)
	var observations:Array[String]=[]
	var observed:Dictionary=item.get("observations",{})
	for pair:Array in [["trace","tracked"],["loss","loss measured"],["humidity","humidity measured"],["acidity","acidity measured"],["activity","water activity"],["review","handling reviewed"],["barrier","barrier tested"]]:
		if observed.has(pair[0]):observations.append(pair[1])
	if observed.has("leak"):observations.append("leak check passed" if bool(observed.get("leak_pass",false)) else "leak check failed")
	_label(copy,"Ready day %d%s" % [int(item.ready)," · "+", ".join(observations) if not observations.is_empty() else ""],10,T.TEXT_SOFT,true)
	var amount:=_label(row,"%.1f" % float(item.amount),15,T.GREEN);amount.tooltip_text="Rations in this batch"

func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()

func refresh()->void:
	if not is_instance_valid(details):return
	var ledger:=B.data();var spec:Dictionary=K.METHODS[subject]
	var solar:=B.solar_factor(WorldSimulation.food.current_environment_profile(),int(WorldSimulation.state.elapsed_days)) if subject in ["grain_parboiling","indirect_solar_food_drying"] else 1.0
	metrics.installed.text=str(int(ledger.tools.get(subject,0)))
	metrics.capacity.text="%.0f rations" % float(spec.rate)
	metrics.throughput.text="%.0f%%" % (solar*100.0)
	metrics.throughput.add_theme_color_override("font_color",T.GREEN if solar>=.75 else T.AMBER if solar>.0 else T.RED)
	metrics.available.text="%.1f" % B.available_total()
	metrics.process.text="%.1f" % B.in_process()
	metrics.loss.text="%.2f" % float(ledger.report.get("loss",0))
	var condition_lines:Array[String]=["Shares remaining Logistics workers with grain handling and preservation."]
	if spec.mode=="selected_food":condition_lines.append("Only identified compatible ingredient lots enter this method; later cooking may still need water, fuel, and a qualified vessel.")
	if subject in ["grain_parboiling","indirect_solar_food_drying"]:condition_lines.append("Wet grain and loaded trays need later handling. Cold or wet conditions can stop solar work; fuelled drying additionally consumes timber.")
	condition_lines.append("Assays consume samples. Packaging protection needs a passing leak check renewed every three days.")
	conditions.text="\n".join(condition_lines)
	for child:Node in lots_box.get_children():lots_box.remove_child(child);child.queue_free()
	if not ledger.lots.is_empty():_label(lots_box,"ACTIVE BATCHES",10,T.GOLD)
	var shown:=0
	for lot:Dictionary in ledger.lots:
		_lot_row(lot);shown+=1
		if shown>=4:break
	if ledger.lots.size()>shown:_label(lots_box,"+ %d more batches" % (ledger.lots.size()-shown),10,T.MUTED)
	# Compact text equivalent for accessibility and legacy assertions.
	details.text="%d installed · %.0f rations per handler-day. Available: %.1f rations · in process: %.1f · loss today: %.2f. %s" % [int(ledger.tools.get(subject,0)),float(spec.rate),B.available_total(),B.in_process(),float(ledger.report.get("loss",0))," ".join(condition_lines)]
	var quote:=B.quote(subject);install_button.disabled=quote.has("error");install_button.tooltip_text=String(quote.get("message",quote.get("error","")))
