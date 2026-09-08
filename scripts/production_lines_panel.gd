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

func _ready() -> void:
	add_theme_constant_override("separation",6)
	summary=Label.new();summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(summary)
	labor=HSlider.new();labor.min_value=0;labor.max_value=100;labor.step=5;labor.tooltip_text="Share of the existing Crafting workforce assigned to military production. Idle lines return their capacity to civilian work."
	add_child(labor);labor.value_changed.connect(func(value:float):MilitaryCampaign.set_production_labor_share(value/100);refresh())
	line_choice=OptionButton.new();line_choice.fit_to_longest_item=false;add_child(line_choice);line_choice.item_selected.connect(func(_index:int):refresh(true))
	var controls:=HBoxContainer.new();add_child(controls)
	var caption:=Label.new();caption.text="Stock target (0 = no limit)";controls.add_child(caption)
	target=SpinBox.new();target.min_value=0;target.max_value=1000000000;target.step=1;target.value=5;target.custom_minimum_size.x=110;target.tooltip_text="0 runs continuously. A positive target pauses work when that many usable items are in stock, and resumes after they are issued.";controls.add_child(target)
	caption=Label.new();caption.text="Priority";controls.add_child(caption)
	priority=SpinBox.new();priority.min_value=.05;priority.max_value=4;priority.step=.05;priority.value=1;priority.custom_minimum_size.x=80;controls.add_child(priority)
	button(controls,"Apply",apply_settings)
	var actions:=HBoxContainer.new();add_child(actions)
	pause_button=button(actions,"Pause",toggle_pause)
	button(actions,"Retool to selected item",retool)
	button(actions,"Close line",close_line)
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	feedback=Label.new();feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(feedback)
	refresh(true)

func button(parent:Node,text:String,action:Callable)->Button:
	var control:=Button.new();control.text=text;parent.add_child(control);control.pressed.connect(action);return control

func selected_id()->int:
	return int(line_choice.get_item_metadata(line_choice.selected)) if line_choice.selected>=0 else -1

func selected_job()->Dictionary:
	var id:=selected_id()
	for job in MilitaryCampaign.equipment_queue:
		if int(job.id)==id:return job
	return {}

func report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Updated.")));refresh(true)

func apply_settings()->void:
	var job:=selected_job()
	if job.is_empty():return
	MilitaryCampaign.set_production_line_allocation(int(job.id),priority.value)
	if bool(job.get("persistent",false)):report(MilitaryCampaign.configure_production_line(int(job.id),int(target.value),bool(job.get("paused",false))))
	else:report({"message":"Batch priority updated."})

func toggle_pause()->void:
	var job:=selected_job()
	if job.is_empty():return
	report(MilitaryCampaign.configure_production_line(int(job.id),int(job.get("target_stock",0)),not bool(job.get("paused",false))))

func retool()->void:
	if product_choice==null or product_choice.selected<0:return
	report(MilitaryCampaign.retool_production_line(selected_id(),String(product_choice.get_item_metadata(product_choice.selected))))

func close_line()->void:
	report(MilitaryCampaign.cancel_equipment_job(selected_id()))

func _process(delta:float)->void:
	remaining-=delta
	if remaining<=0 and is_visible_in_tree():remaining=.5;refresh()

func refresh(editors:bool=false)->void:
	if line_choice==null:return
	var data:=MilitaryCampaign.production_lines_snapshot()
	var workforce:Dictionary=data.workforce
	var actual_share:=MilitaryCampaign.workshop_utilization()
	summary.text="Crafting: %.1f effective workers · %.0f%% assigned to military work (limit %.0f%%)\nHealth %.0f%% · labor %.0f%% · workplaces %.0f%% · logistics %.0f%%" % [float(workforce.workers),actual_share*100,float(data.labor_share)*100,float(workforce.health)*100,float(workforce.labor_efficiency)*100,float(workforce.workplace_condition)*100,float(workforce.logistics)*100]
	labor.set_value_no_signal(float(data.labor_share)*100)
	var ids:Array=[]
	for line in data.lines:ids.append([line.id,line.item])
	var next_signature:=str(ids)
	if next_signature!=signature:
		var selected:=selected_id();line_choice.clear()
		for line in data.lines:
			line_choice.add_item("%d · %s" % [int(line.id),MilitaryCampaign.PersistentProduction.product_name(String(line.item))]);line_choice.set_item_metadata(line_choice.item_count-1,int(line.id))
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
	for resource in line.inputs_per_day:inputs.append("%s: %.2f stored / %.2f per item / %.2f per day" % [ResourceSystem.display_name(String(resource)),float(GameState.resource_stockpiles.get(resource,0)),float(line.materials[resource]),float(line.inputs_per_day[resource])])
	var condition:=String(line.state)
	if condition=="Working" and float(line.daily_work)<=0:condition="Waiting for labor or usable workplaces"
	details.text="%s · stock %d · %s\nEfficiency %.0f%% · forecast %.2f/day · last day %d completed\nInputs at this rate: %s\nWork in progress %.0f%% · %.0f%% of military workshop effort" % [condition,int(line.stock),"CONTINUOUS — NO LIMIT" if int(line.target_stock)==0 else "maintain %d" % int(line.target_stock),float(line.efficiency)*100,float(line.forecast_output_per_day),int(line.last_output),", ".join(inputs),float(line.progress_days)/float(line.work_per_item)*100,float(line.share)*100]
