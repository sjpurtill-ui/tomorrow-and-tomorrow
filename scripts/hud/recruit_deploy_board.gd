extends VBoxContainer
const T=preload("res://scripts/hud/hud_tokens.gd")
var edit:Callable
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
const Art=preload("res://scripts/hud/military_roster_visuals.gd")
const INK:=Color("e8e9df")
const DIM:=Color("a5b1ac")
const GOLD:=Color("d9b772")
var columns:GridContainer
var templates_column:VBoxContainer
var queue_column:VBoxContainer
var template_cards:VBoxContainer
var queue_title:Label
func setup(block:Dictionary)->void:
	name="RecruitDeployBoard";edit=block.edit_template
	add_theme_constant_override("separation",16)
	var theme_skin:=Theme.new()
	for kind in ["Button","OptionButton","CheckButton"]:
		for state in ["normal","hover","pressed","disabled"]:
			theme_skin.set_stylebox(state,kind,skin(Color("35413b") if state=="hover" else Color("26302b"),GOLD if state=="pressed" else Color("596052"),8))
		for state in ["font_color","font_hover_color","font_pressed_color"]:theme_skin.set_color(state,kind,INK)
		theme_skin.set_color("font_disabled_color",kind,Color("7c847b"));theme_skin.set_font_size("font_size",kind,13)
	theme_skin.set_stylebox("normal","LineEdit",skin(Color("171e1b"),Color("596052"),7));theme_skin.set_color("font_color","LineEdit",INK)
	theme=theme_skin
	var top:=PanelContainer.new();top.add_theme_stylebox_override("panel",skin(Color("202923"),Color("606652"),14));add_child(top)
	var status:=VBoxContainer.new();status.add_theme_constant_override("separation",7);top.add_child(status)
	status.add_child(label("ARMY RECRUITMENT COMMAND",12,GOLD))
	workforce=label("",16,INK);workforce.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_child(workforce)
	feedback=label("Choose a template to begin training. Each line reserves its own people and equipment.",12,DIM);feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_child(feedback)
	columns=GridContainer.new();columns.columns=2;columns.add_theme_constant_override("h_separation",20);columns.add_theme_constant_override("v_separation",18);add_child(columns)
	queue_column=VBoxContainer.new();queue_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;queue_column.size_flags_stretch_ratio=1.6;queue_column.add_theme_constant_override("separation",10);columns.add_child(queue_column)
	queue_title=label("RECRUITMENT QUEUE",16,GOLD);queue_column.add_child(queue_title)
	rows=VBoxContainer.new();rows.add_theme_constant_override("separation",12);queue_column.add_child(rows)
	templates_column=VBoxContainer.new();templates_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;templates_column.add_theme_constant_override("separation",10);columns.add_child(templates_column)
	var title:=HBoxContainer.new();templates_column.add_child(title)
	var caption:=label("FORMATION TEMPLATES",16,GOLD);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_child(caption)
	button(title,"+ New",func():
		var result:=MilitaryCampaign.create_army_template()
		if result.has("template"):edit.call(int(result.template.template_id)),"Create a formation template")
	var settings:=PanelContainer.new();settings.add_theme_stylebox_override("panel",skin(Color("202923"),Color("465044"),10));templates_column.add_child(settings)
	var settings_box:=VBoxContainer.new();settings_box.add_theme_constant_override("separation",8);settings.add_child(settings_box)
	settings_box.add_child(label("NEW TRAINING ORDER",11,DIM))
	var options:=HBoxContainer.new();options.add_theme_constant_override("separation",10);settings_box.add_child(options)
	parallel=number(options,"At a time",1);serial=number(options,"Batches",1)
	repeat=CheckButton.new();repeat.text="Repeat";repeat.tooltip_text="Keep training new batches until you stop this line";settings_box.add_child(repeat)
	template_cards=VBoxContainer.new();template_cards.add_theme_constant_override("separation",10);templates_column.add_child(template_cards)
	build_templates();resized.connect(layout_columns);layout_columns();rebuild()
func skin(bg:Color,border:Color,margin:int=10)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1);style.set_content_margin_all(margin);return style
func label(text:String,size:int=12,color:Color=DIM)->Label:
	return T.make_label(text,size,GOLD if color==T.INK else DIM if color==T.MUTED else INK if color==T.BODY else color)
func layout_columns()->void:
	if not columns:return
	columns.columns=2 if size.x>=850 else 1
	templates_column.custom_minimum_size.x=310 if columns.columns==2 else 0
func build_templates()->void:
	for item:Dictionary in MilitaryCampaign.army_template_snapshot().templates:
		var id:=int(item.template_id)
		var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",skin(Color("26302b"),Color("5b6252"),12));template_cards.add_child(card)
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);card.add_child(box)
		var head:=HBoxContainer.new();head.add_theme_constant_override("separation",12);box.add_child(head)
		var entries:Array=item.get("entries",[])
		var art:=TextureRect.new();art.custom_minimum_size=Vector2(58,76);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var path:=Art.illustration_path(String(entries[0].get("unit","levy"))) if not entries.is_empty() else ""
		if not path.is_empty():art.texture=load(path)
		head.add_child(art)
		var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(names)
		var heading:=label(String(item.name),16,INK);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;names.add_child(heading)
		var people:=0
		for entry:Dictionary in entries:people+=int(entry.count)
		names.add_child(label("%d soldiers / formation" % people,12,GOLD))
		for entry:Dictionary in entries:
			var line:=label("%d × %s · %s" % [int(entry.count),String(entry.unit).replace("_"," ").capitalize(),MilitaryCampaign.PersistentProduction.product_name(String(entry.weapon))],12,DIM);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(line)
		var actions:=HBoxContainer.new();box.add_child(actions)
		var train:=button(actions,"Train",func():report(MilitaryCampaign.recruit_deploy.add(id,int(parallel.value),int(serial.value),repeat.button_pressed)),"Create a recruitment line using this template")
		train.name="TrainTemplate"+str(id);train.size_flags_horizontal=Control.SIZE_EXPAND_FILL;train.disabled=entries.is_empty()
		train.add_theme_stylebox_override("normal",skin(Color("47533a"),GOLD,9))
		button(actions,"Edit",func():edit.call(id),"Edit this formation's composition")
func empty_queue()->void:
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",skin(Color("1b241f"),Color("465044"),16));rows.add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",15);panel.add_child(box)
	var art:=TextureRect.new();art.texture=Art.artwork("army");art.custom_minimum_size.y=140;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;box.add_child(art)
	box.add_child(label("NO FORMATIONS IN TRAINING",17,INK))
	var hint:=label("Choose Train on a formation template. Its people, equipment and instruction progress will appear here.",13,DIM);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(hint)
	for step:String in ["01  ENLIST     Available adults fill the formation", "02  EQUIP      Weapons are reserved from your stores", "03  TRAIN      Instruction builds readiness", "04  DEPLOY  Join an army or form a new command at home"]:
		var text:=label(step,12,DIM);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(text)
func number(parent:Node,title:String,value:int)->SpinBox:
	var box:=VBoxContainer.new();parent.add_child(box);box.add_child(label(title,10,T.MUTED))
	var input:=SpinBox.new();input.min_value=1;input.max_value=1000000000;input.value=value;input.custom_minimum_size.x=82;box.add_child(input);return input
func button(parent:Node,title:String,action:Callable,tip:String="")->Button:
	var result:=Button.new();result.text=title;result.custom_minimum_size.y=32;result.tooltip_text=tip;result.pressed.connect(action);parent.add_child(result);return result
func report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Updated")))
	rebuild()
func rebuild()->void:
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	live.clear()
	var lines:Array=MilitaryCampaign.recruit_deploy.data.lines
	queue_title.text="RECRUITMENT QUEUE · %d LINES" % lines.size()
	if lines.is_empty():empty_queue()
	page=clampi(page,0,maxi(0,(lines.size()-1)/4))
	if lines.size()>4:
		var paging:=HBoxContainer.new();rows.add_child(paging)
		button(paging,"‹",func():page=maxi(0,page-1);rebuild(),"Previous lines")
		paging.add_child(label("%d / %d" % [page+1,ceili(lines.size()/4.0)],11,T.MUTED))
		button(paging,"›",func():page+=1;rebuild(),"Next lines")
	for item:Dictionary in lines.slice(page*4,page*4+4):
		var id:=int(item.id)
		var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",skin(Color("26302b"),Color("5b6252"),12));rows.add_child(panel)
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",5);panel.add_child(box)
		var top:=HBoxContainer.new();box.add_child(top)
		var title:=label(String(item.name),13,T.INK);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
		button(top,"Resume" if bool(item.paused) else "Pause",func():report(MilitaryCampaign.recruit_deploy.configure(id,"paused",not bool(item.paused))),"Pause or resume this line")
		button(top,"Cancel",func():report(MilitaryCampaign.recruit_deploy.cancel(id)),"Cancel line; release recruits and return equipment")
		var settings:=HFlowContainer.new();settings.add_theme_constant_override("h_separation",6);box.add_child(settings)
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
		var summary:=label("",10,T.MUTED);box.add_child(summary);live.append({"summary":summary,"id":id})
		var slot_page:=clampi(int(slot_pages.get(id,0)),0,maxi(0,(item.slots.size()-1)/4))
		if item.slots.size()>4:
			var paging:=HBoxContainer.new();box.add_child(paging)
			button(paging,"‹",func():slot_pages[id]=maxi(0,slot_page-1);rebuild(),"Previous formations")
			paging.add_child(label("Formations %d–%d" % [slot_page*4+1,mini(item.slots.size(),slot_page*4+4)],10,T.MUTED))
			button(paging,"›",func():slot_pages[id]=mini((item.slots.size()-1)/4,slot_page+1);rebuild(),"Next formations")
		for slot in item.slots.slice(slot_page*4,slot_page*4+4):
			var slot_id:=int(slot)
			box.add_child(label("FORMATION %d" % (item.slots.find(slot)+1),11,GOLD))
			var row:=HBoxContainer.new();box.add_child(row)
			var bars:=VBoxContainer.new();bars.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(bars)
			var controls:Array=[]
			for label in ["People","Equipment","Training"]:
				var strip:=HBoxContainer.new();bars.add_child(strip)
				var caption:=label(label,10,T.MUTED);caption.custom_minimum_size.x=68;strip.add_child(caption)
				var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=10;bar.add_theme_stylebox_override("background",skin(Color("121a15"),Color("3c493a"),0));bar.add_theme_stylebox_override("fill",skin(Color("81945d"),Color("81945d"),0));bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;strip.add_child(bar)
				var value:=label("",10,T.BODY);value.custom_minimum_size.x=65;strip.add_child(value);controls.append({"bar":bar,"value":value})
			var deploy:=button(row,"Deploy",func():report(MilitaryCampaign.recruit_deploy.deploy(id,slot_id,true)),"Deploy after 20% training. Incomplete training and equipment reduce fighting strength.")
			live.append({"id":id,"slot":slot_id,"controls":controls,"deploy":deploy})
	signature=shape()
	update_values()
func shape()->String:
	var parts:Array=[]
	for item:Dictionary in MilitaryCampaign.recruit_deploy.data.lines:parts.append([item.id,item.slots,item.deployed])
	return str(parts)
func update_values()->void:
	workforce.text="MANPOWER  %d available     |     %d serving     |     %d civilian jobs displaced" % [maxi(0,MilitaryCampaign.recruitment_capacity()-MilitaryCampaign._mobilized_count()),MilitaryCampaign._mobilized_count(),int(MilitaryCampaign.population_commitment_snapshot().excess_beyond_defense)]
	for row:Dictionary in live:
		var item:=MilitaryCampaign.recruit_deploy.line(int(row.id))
		if item.is_empty():continue
		if row.has("summary"):
			row.summary.text="%d deployed · %d active · %s pending" % [int(item.deployed),item.slots.size(),"∞" if bool(item.repeat) else str(item.remaining)];continue
		var state:=MilitaryCampaign.recruit_deploy.status(int(row.id),int(row.slot))
		var values:Array=[[state.people,maxi(1,int(state.target))],[state.equipment,maxi(1,int(state.equipment_required))],[roundi(float(state.training)*100),100]]
		for index in 3:
			row.controls[index].bar.value=float(values[index][0])/values[index][1]*100
			row.controls[index].value.text=("%d%%" % values[index][0]) if index==2 else "%d/%d" % values[index]
		row.deploy.disabled=not bool(state.early)
func _process(delta:float)->void:
	refresh_clock+=delta
	if refresh_clock<.5 or rows==null:return
	refresh_clock=0
	if signature!=shape():rebuild()
	else:update_values()
