extends VBoxContainer
const T=preload("res://scripts/hud/hud_tokens.gd")
var edit:Callable
var template:OptionButton
var parallel:SpinBox
var serial:SpinBox
var repeat:CheckButton
var rows:VBoxContainer
var feedback:Label
var workforce:Label
var refresh_clock:=0.0
var signature:=""
var page:=0
var slot_pages:Dictionary={}
var live:Array[Dictionary]=[]
func setup(block:Dictionary)->void:
	edit=block.edit_template
	add_theme_constant_override("separation",8)
	workforce=T.make_label("",11,T.MUTED);add_child(workforce)
	var heading:=HBoxContainer.new();add_child(heading)
	template=OptionButton.new();template.size_flags_horizontal=Control.SIZE_EXPAND_FILL;template.fit_to_longest_item=false;heading.add_child(template)
	for item:Dictionary in MilitaryCampaign.army_template_snapshot().templates:template.add_item(String(item.name),int(item.template_id))
	button(heading,"Edit",func():edit.call(template.get_selected_id()),"Edit the selected formation template")
	button(heading,"+",func():
		var result:=MilitaryCampaign.create_army_template()
		if result.has("template"):edit.call(int(result.template.template_id)),"Create a formation template")
	var options:=HBoxContainer.new();add_child(options)
	parallel=number(options,"Parallel",1);serial=number(options,"Batches",1)
	repeat=CheckButton.new();repeat.text="∞";repeat.tooltip_text="Repeat batches indefinitely";options.add_child(repeat)
	button(options,"Recruit",func():report(MilitaryCampaign.recruit_deploy.add(template.get_selected_id(),int(parallel.value),int(serial.value),repeat.button_pressed)),"Queue new formations. Drafting does not require spare equipment or food.")
	feedback=T.make_label("",11,T.MUTED);feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(feedback)
	rows=VBoxContainer.new();rows.add_theme_constant_override("separation",8);add_child(rows)
	rebuild()
func number(parent:Node,title:String,value:int)->SpinBox:
	var box:=VBoxContainer.new();parent.add_child(box);box.add_child(T.make_label(title,10,T.MUTED))
	var input:=SpinBox.new();input.min_value=1;input.max_value=1000000000;input.value=value;input.custom_minimum_size.x=82;box.add_child(input);return input
func button(parent:Node,title:String,action:Callable,tip:String="")->Button:
	var result:=Button.new();result.text=title;result.tooltip_text=tip;result.pressed.connect(action);parent.add_child(result);return result
func report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Updated")))
	rebuild()
func rebuild()->void:
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	live.clear()
	var lines:Array=MilitaryCampaign.recruit_deploy.data.lines
	page=clampi(page,0,maxi(0,(lines.size()-1)/4))
	if lines.size()>4:
		var paging:=HBoxContainer.new();rows.add_child(paging)
		button(paging,"‹",func():page=maxi(0,page-1);rebuild(),"Previous lines")
		paging.add_child(T.make_label("%d / %d" % [page+1,ceili(lines.size()/4.0)],11,T.MUTED))
		button(paging,"›",func():page+=1;rebuild(),"Next lines")
	for item:Dictionary in lines.slice(page*4,page*4+4):
		var id:=int(item.id)
		var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",T.tile_style());rows.add_child(panel)
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",5);panel.add_child(box)
		var top:=HBoxContainer.new();box.add_child(top)
		var title:=T.make_label(String(item.name),13,T.INK);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
		button(top,"▶" if bool(item.paused) else "Ⅱ",func():report(MilitaryCampaign.recruit_deploy.configure(id,"paused",not bool(item.paused))),"Pause or resume this line")
		button(top,"×",func():report(MilitaryCampaign.recruit_deploy.cancel(id)),"Cancel line; release recruits and return equipment")
		var settings:=HBoxContainer.new();box.add_child(settings)
		var priority:=OptionButton.new();for label in ["Low","Normal","High"]:priority.add_item(label)
		priority.selected=int(item.priority);priority.tooltip_text="Equipment and manpower priority";settings.add_child(priority)
		priority.item_selected.connect(func(value:int):report(MilitaryCampaign.recruit_deploy.configure(id,"priority",value)))
		var automatic:=CheckButton.new();automatic.text="Auto deploy";automatic.button_pressed=bool(item.auto_deploy);settings.add_child(automatic)
		automatic.toggled.connect(func(value:bool):report(MilitaryCampaign.recruit_deploy.configure(id,"auto_deploy",value)))
		button(settings,"∞" if bool(item.repeat) else "Once",func():report(MilitaryCampaign.recruit_deploy.configure(id,"repeat",not bool(item.repeat))),"Toggle repeating batches")
		var destination:=OptionButton.new();destination.size_flags_horizontal=Control.SIZE_EXPAND_FILL;destination.fit_to_longest_item=false;destination.add_item("Home · new army",0)
		for army:Dictionary in MilitaryCampaign.field_armies:
			destination.add_item(String(army.name),int(army.army_id))
			if int(army.army_id)==int(item.target_army):destination.selected=destination.item_count-1
		destination.tooltip_text="Assembly destination. Existing armies must return home to receive recruits.";box.add_child(destination)
		destination.item_selected.connect(func(index:int):report(MilitaryCampaign.recruit_deploy.configure(id,"target_army",destination.get_item_id(index))))
		var summary:=T.make_label("",10,T.MUTED);box.add_child(summary);live.append({"summary":summary,"id":id})
		var slot_page:=clampi(int(slot_pages.get(id,0)),0,maxi(0,(item.slots.size()-1)/4))
		if item.slots.size()>4:
			var paging:=HBoxContainer.new();box.add_child(paging)
			button(paging,"‹",func():slot_pages[id]=maxi(0,slot_page-1);rebuild(),"Previous formations")
			paging.add_child(T.make_label("Formations %d–%d" % [slot_page*4+1,mini(item.slots.size(),slot_page*4+4)],10,T.MUTED))
			button(paging,"›",func():slot_pages[id]=mini((item.slots.size()-1)/4,slot_page+1);rebuild(),"Next formations")
		for slot in item.slots.slice(slot_page*4,slot_page*4+4):
			var slot_id:=int(slot)
			var row:=HBoxContainer.new();box.add_child(row)
			var bars:=VBoxContainer.new();bars.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(bars)
			var controls:Array=[]
			for label in ["People","Equipment","Training"]:
				var strip:=HBoxContainer.new();bars.add_child(strip)
				var caption:=T.make_label(label,10,T.MUTED);caption.custom_minimum_size.x=68;strip.add_child(caption)
				var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=8;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;strip.add_child(bar)
				var value:=T.make_label("",10,T.BODY);value.custom_minimum_size.x=65;strip.add_child(value);controls.append({"bar":bar,"value":value})
			var deploy:=button(row,"Deploy",func():report(MilitaryCampaign.recruit_deploy.deploy(id,slot_id,true)),"Deploy after 20% training. Incomplete training and equipment reduce fighting strength.")
			live.append({"id":id,"slot":slot_id,"controls":controls,"deploy":deploy})
	signature=shape()
	update_values()
func shape()->String:
	var parts:Array=[]
	for item:Dictionary in MilitaryCampaign.recruit_deploy.data.lines:parts.append([item.id,item.slots,item.deployed])
	return str(parts)
func update_values()->void:
	workforce.text="%d available · %d serving · %d civilian jobs displaced" % [maxi(0,MilitaryCampaign.recruitment_capacity()-MilitaryCampaign._mobilized_count()),MilitaryCampaign._mobilized_count(),int(MilitaryCampaign.population_commitment_snapshot().excess_beyond_defense)]
	for row:Dictionary in live:
		var item:=MilitaryCampaign.recruit_deploy.line(int(row.id))
		if item.is_empty():continue
		if row.has("summary"):
			row.summary.text="%d deployed · %d active · %s pending" % [int(item.deployed),item.slots.size(),"∞" if bool(item.repeat) else str(item.remaining)];continue
		var state:=MilitaryCampaign.recruit_deploy.status(int(row.id),int(row.slot))
		var values:Array=[[state.people,maxi(1,int(state.target))],[state.equipment,maxi(1,int(state.equipment_required))],[roundi(float(state.training)*100),100]]
		for index in 3:
			row.controls[index].bar.value=float(values[index][0])/values[index][1]*100
			row.controls[index].value.text="%d/%d" % values[index]
		row.deploy.disabled=not bool(state.early)
func _process(delta:float)->void:
	refresh_clock+=delta
	if refresh_clock<.5 or rows==null:return
	refresh_clock=0
	if signature!=shape():rebuild()
	else:update_values()
