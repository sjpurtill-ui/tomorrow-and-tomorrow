extends VBoxContainer
## Compact controls in the existing Supply tab, not a separate production screen.
var product_choice: OptionButton
var line_choice: OptionButton
var target: SpinBox
var priority: SpinBox
var labor: HSlider
var details: Label
var summary: Label
var feedback: Label
var pause_button: Button
var remaining:=0.0
var signature:=""
var board:VBoxContainer
var manual:VBoxContainer
var board_state:Dictionary={"mode":0}

func _ready() -> void:
	add_theme_constant_override("separation",6)
	summary=Label.new();summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(summary)
	board=preload("res://scripts/hud/production_board.gd").new();add_child(board)
	var management:=HBoxContainer.new();add_child(management)
	button(management,"Delegate lines",func():report(WorldSimulation.military.workshop.delegate_lines()))
	button(management,"Manual controls",func():manual.visible=not manual.visible)
	manual=VBoxContainer.new();manual.visible=false;add_child(manual)
	labor=HSlider.new();labor.min_value=0;labor.max_value=100;labor.step=5;labor.tooltip_text="Shared civilian and military workshops use existing craftspeople. Idle lines release capacity."
	manual.add_child(labor);labor.value_changed.connect(func(value:float):WorldSimulation.military.set_production_labor_share(value/100);refresh())
	line_choice=OptionButton.new();line_choice.fit_to_longest_item=false;manual.add_child(line_choice);line_choice.item_selected.connect(func(_index:int):refresh(true))
	var controls:=HBoxContainer.new();manual.add_child(controls)
	var caption:=Label.new();caption.text="Stock target (0 = no limit)";controls.add_child(caption)
	target=SpinBox.new();target.min_value=0;target.max_value=1000000000;target.step=1;target.value=5;target.custom_minimum_size.x=110;target.tooltip_text="0 runs continuously. A positive target pauses work when that many usable items are in stock, and resumes after they are issued.";controls.add_child(target)
	caption=Label.new();caption.text="Priority";controls.add_child(caption)
	priority=SpinBox.new();priority.min_value=.05;priority.max_value=4;priority.step=.05;priority.value=1;priority.custom_minimum_size.x=80;controls.add_child(priority)
	button(controls,"Apply",apply_settings)
	var actions:=HBoxContainer.new();manual.add_child(actions)
	pause_button=button(actions,"Pause",toggle_pause)
	button(actions,"Retool to selected item",retool)
	button(actions,"Close line",close_line)
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;manual.add_child(details)
	feedback=Label.new();feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(feedback)
	refresh(true)

func button(parent:Node,text:String,action:Callable)->Button:
	var control:=Button.new();control.text=text;parent.add_child(control);control.pressed.connect(action);return control

func selected_id()->int:
	return int(line_choice.get_item_metadata(line_choice.selected)) if line_choice.selected>=0 else -1

func selected_job()->Dictionary:
	var id:=selected_id()
	for job in WorldSimulation.military.equipment_queue:
		if int(job.id)==id:return job
	return {}

func report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Updated.")));refresh(true)

func apply_settings()->void:
	var job:=selected_job()
	if job.is_empty():return
	WorldSimulation.military.set_production_line_allocation(int(job.id),priority.value)
	if bool(job.get("persistent",false)):report(WorldSimulation.military.configure_production_line(int(job.id),int(target.value),bool(job.get("paused",false))))
	else:report({"message":"Batch priority updated."})

func toggle_pause()->void:
	var job:=selected_job()
	if job.is_empty():return
	report(WorldSimulation.military.configure_production_line(int(job.id),int(job.get("target_stock",0)),not bool(job.get("paused",false))))

func retool()->void:
	if product_choice==null or product_choice.selected<0:return
	report(WorldSimulation.military.retool_production_line(selected_id(),String(product_choice.get_item_metadata(product_choice.selected))))

func close_line()->void:
	report(WorldSimulation.military.cancel_equipment_job(selected_id()))

func _process(delta:float)->void:
	remaining-=delta
	if remaining<=0 and is_visible_in_tree():remaining=.5;refresh()

func refresh(editors:bool=false)->void:
	if line_choice==null:return
	var data:=WorldSimulation.military.production_lines_snapshot()
	summary.text="SHARED WORKSHOPS · %d / %d lines\n%s\n%s" % [data.lines.size(),int(data.capacity),WorldSimulation.military.workshop.owner(),String(WorldSimulation.military.workshop.data.status)]
	if not board.get_global_rect().has_point(board.get_global_mouse_position()) or editors:
		board.setup({"lines":data.lines,"receipts":WorldSimulation.military.workshop.data.receipts,"totals":WorldSimulation.military.workshop.data.totals,"day":int(WorldSimulation.state.elapsed_days),"view_state":board_state,"on_open":func(id:int):
			for index:int in line_choice.item_count:
				if int(line_choice.get_item_metadata(index))==id:line_choice.select(index)
			manual.show();refresh(true)})
	labor.set_value_no_signal(float(data.labor_share)*100)
	var ids:Array=[]
	for line in data.lines:ids.append([line.id,line.item])
	var next_signature:=str(ids)
	if next_signature!=signature:
		var selected:=selected_id();line_choice.clear()
		for line in data.lines:
			line_choice.add_item("%d · %s" % [int(line.id),WorldSimulation.military.PersistentProduction.product_name(String(line.item))]);line_choice.set_item_metadata(line_choice.item_count-1,int(line.id))
			if int(line.id)==selected:line_choice.select(line_choice.item_count-1)
		signature=next_signature;editors=true
	var line:Dictionary={}
	for record in data.lines:
		if int(record.id)==selected_id():line=record;break
	if line.is_empty():details.text="No production lines. Choose an item above to start one.";return
	var persistent:=bool(line.get("persistent",false))
	if editors:
		target.set_value_no_signal(float(line.get("target_stock",0)));priority.set_value_no_signal(float(line.allocation))
	target.editable=persistent;pause_button.disabled=not persistent
	pause_button.text="Resume" if bool(line.get("paused",false)) else "Pause"
	if not persistent:details.text="Existing batch · %.0f%% efficiency · %.2f work/day. Its prepaid materials and completion rules are preserved." % [float(line.efficiency)*100,float(line.daily_work)];return
	var inputs:Array[String]=[]
	for resource in line.inputs_per_day:inputs.append("%s: %.2f stored / %.2f per item / %.2f per day" % [WorldSimulation.resources.display_name(String(resource)),float(WorldSimulation.state.resource_stockpiles.get(resource,0)),float(line.materials[resource]),float(line.inputs_per_day[resource])])
	var condition:=String(line.state)
	if condition=="Working" and float(line.daily_work)<=0:condition="Waiting for labor or usable workplaces"
	elif condition=="Working" and line.get("licensed",false):condition="Working under foreign license (65% throughput)"
	var forecast:="forecast %.2f/day" % float(line.forecast_output_per_day)
	if line.has("forecast_inspections_per_day"):
		forecast="inspection capacity %.2f/day · accepted yield varies" % float(line.forecast_inspections_per_day)
	details.text="%s · stock %d · %s\nEfficiency %.0f%% · %s · last day %d completed\nInputs at this rate: %s\nWork in progress %.0f%% · %.0f%% of military workshop effort" % [condition,int(line.stock),"CONTINUOUS — NO LIMIT" if int(line.target_stock)==0 else "maintain %d" % int(line.target_stock),float(line.efficiency)*100,forecast,int(line.last_output),", ".join(inputs),float(line.progress_days)/float(line.work_per_item)*100,float(line.share)*100]

	if line.has("accepted_total"):
		details.text+="\nInspected totals: %d accepted · %d rejected." % [int(line.accepted_total),int(line.rejected_total)]
	if line.has("abrasive_last"):
		var check:Dictionary=line.abrasive_last
		details.text+="\nInspection: %s · %d rejected total." % ["accepted" if check.accepted else "rejected",int(line.get("abrasive_rejected",0))]
		details.text+="\nSize / form / surface ratios: %.2f / %.2f / %.2f (limit 1.00)." % [float(check.report.size_ratio),float(check.report.form_ratio),float(check.report.surface_ratio)]
	var coproducts:Array[String]=[]
	for resource:String in line.get("co_products",{}):coproducts.append("%.2f %s" % [float(line.co_products[resource]),resource])
	if not coproducts.is_empty():details.text+="\nAlso yields per completed batch: "+", ".join(coproducts)+". Target follows the primary product."
