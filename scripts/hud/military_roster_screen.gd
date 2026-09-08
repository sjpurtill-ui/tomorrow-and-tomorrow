extends CanvasLayer
## A broad, visual service ledger over the existing world; no secondary map.
var service:String="army"
var training_view:=false
var panel:PanelContainer
var body:VBoxContainer
var policy_status:Label
var policy_buttons:Dictionary={}
var bindings:Array[Dictionary]=[]
var rows_signature:=""
var timer:=0.0
var scroll:ScrollContainer
var selected_row:Dictionary={}
var heading:Label
var close_button:Button
var management_button:Button
func _ready()->void:
	layer=87
	panel=PanelContainer.new();add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left=.055;panel.anchor_right=.945;panel.anchor_top=.12;panel.anchor_bottom=.92
	var skin:=StyleBoxFlat.new();skin.bg_color=Color("101b21");skin.border_color=Color("52666c");skin.set_border_width_all(1);skin.set_content_margin_all(18);skin.corner_radius_top_left=8;skin.corner_radius_top_right=8
	panel.add_theme_stylebox_override("panel",skin);panel.add_theme_font_size_override("font_size",15)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	var header:=HBoxContainer.new();column.add_child(header)
	heading=_label(header,"FORCES",23);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for domain in ["army","navy","air"]:
		var selected_service:=String(domain)
		_button(header,selected_service.capitalize(),func():service=selected_service;selected_row={};_build_body())
	close_button=_button(header,"Close ×",queue_free);close_button.custom_minimum_size=Vector2(86,40)
	var nav:=HBoxContainer.new();column.add_child(nav)
	_button(nav,"Forces roster",func():training_view=false;selected_row={};_build_body())
	_button(nav,"Training strategy",func():training_view=true;selected_row={};_build_body())
	management_button=_button(nav,"Army builds",func():_management(1))
	_button(nav,"Supply",func():_management(3))
	var map_button:=_button(nav,"Command on map",func():
		queue_free()
		if service!="army":MilitaryCampaign.joint_operations.open_service(service))
	map_button.tooltip_text="Close this overview and return to the actual world map. Navy and Air retain their distinct command controls."
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
	_build_body()
func _management(sub:int)->void:
	if service!="army":
		queue_free();MilitaryCampaign.joint_operations.open_service(service);return
	var scene:=get_tree().current_scene
	if scene!=null and "hud" in scene and scene.hud:scene.hud.open_dock("military",sub,false)
	queue_free()
func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled();queue_free()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled();queue_free()
func _process(delta:float)->void:
	timer+=delta
	if timer<.5:return
	timer=0
	if training_view:_update_policy();return
	var rows:=_rows()
	if _signature(rows)!=rows_signature:_build_body();return
	for i in mini(rows.size(),bindings.size()):_update_row(bindings[i],rows[i])
func _label(parent:Node,text:String,size:int=15)->Label:
	var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",size);parent.add_child(node);return node
func _button(parent:Node,text:String,callback:Callable)->Button:
	var node:=Button.new();node.text=text;node.pressed.connect(callback);parent.add_child(node);return node
func _bar(parent:Node,color:Color)->ProgressBar:
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(105,8);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var fill:=StyleBoxFlat.new();fill.bg_color=color;bar.add_theme_stylebox_override("fill",fill)
	var track:=StyleBoxFlat.new();track.bg_color=Color("35464b");bar.add_theme_stylebox_override("background",track);parent.add_child(bar);return bar
func _clear()->void:
	for child in body.get_children():body.remove_child(child);child.queue_free()
	bindings.clear();policy_buttons.clear()
func _build_body()->void:
	_clear();heading.text=service.to_upper()+" · "+("TRAINING STRATEGY" if training_view else "FORCES")
	management_button.text="Army builds" if service=="army" else "Ports & shipbuilding" if service=="navy" else "Airbases & aircraft"
	if training_view:_policy();return
	var rows:=_rows();rows_signature=_signature(rows)
	var intro:=HBoxContainer.new();body.add_child(intro)
	var text:=_label(intro,"%d formations · Staff training: %s" % [rows.size(),MilitaryCampaign.training_staff.policy(service).label],16);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(intro,"How much should we train?",func():training_view=true;_build_body())
	if not selected_row.is_empty():_inspection()
	if rows.is_empty():
		_label(body,"No formations in this service yet.",19)
		var note:=_label(body,"Set a training policy now. Staff apply it automatically as formations enter service.",15);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		return
	var headers:=HBoxContainer.new();body.add_child(headers)
	for title in ["UNIT / COMMAND","PERSONNEL","EQUIPMENT","SKILLS","STAFF ACTIVITY"]:
		var label:=_label(headers,title,12);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_stretch_ratio=2.1 if title=="UNIT / COMMAND" else 1.0
	for data:Dictionary in rows:
		var row:=HBoxContainer.new();row.custom_minimum_size.y=70;row.add_theme_constant_override("separation",14);body.add_child(row)
		var identity:=HBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.size_flags_stretch_ratio=2.1;row.add_child(identity)
		var emblem:=_label(identity,String(data.glyph),30);emblem.custom_minimum_size.x=42;emblem.add_theme_color_override("font_color",Color("dfb967"))
		var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_child(names)
		var chosen:=data.duplicate(true)
		var name_button:=_button(names,String(data.name),func():selected_row=chosen;_build_body());name_button.alignment=HORIZONTAL_ALIGNMENT_LEFT;name_button.clip_text=true
		var location:=_label(names,String(data.location),12);location.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var binding:Dictionary={}
		for key in ["personnel","equipment","skill","activity"]:
			var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(cell)
			binding[key]=_label(cell,"",14);binding[key].text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			binding[key+"_bar"]=_bar(cell,Color("88b6ce") if key=="skill" else Color("88c5a6"))
			binding[key+"_note"]=_label(cell,"",12);binding[key+"_note"].text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		bindings.append(binding);_update_row(binding,data)
func _signature(rows:Array)->String:
	var keys:Array=[]
	for row:Dictionary in rows:keys.append([row.name,row.location])
	return str(keys)
func _update_row(binding:Dictionary,data:Dictionary)->void:
	if bool(data.get("unknown",false)):
		binding.personnel.text="%d reported" % int(data.count) if int(data.count)>0 else "Unreported"
		binding.equipment.text="Not reported";binding.skill.text="Not reported";binding.activity.text="Awaiting report"
		for key in ["personnel","equipment","skill","activity"]:binding[key+"_bar"].visible=false;binding[key+"_note"].text=""
		return
	binding.personnel.text="%d / %d" % [data.count,data.authorized];binding.personnel_bar.value=float(data.count)/maxf(1,data.authorized)*100
	binding.personnel_note.text="Condition %d%%" % roundi(data.condition*100)
	binding.equipment.text="%d%% equipped" % roundi(data.equipment*100);binding.equipment_bar.value=data.equipment*100
	binding.equipment_note.text=String(data.equipment_note)
	binding.skill.text="Drill %d%%" % roundi(data.skill*100);binding.skill_bar.value=data.skill*100
	binding.skill_note.text="Experience %d%%" % roundi(data.experience*100)
	binding.activity.text=String(data.activity);binding.activity_bar.value=data.progress*100
	binding.activity_note.text=String(data.training_note)
func _rows()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var campaign=MilitaryCampaign
	if service=="army":
		var forces:Array=[{"force":campaign.home_army,"location":"Home reserve"}]
		var snapshot:Dictionary=campaign.field_armies_snapshot()
		for army:Dictionary in snapshot.get("armies",[]):
			var home:bool=String(army.get("location_id",""))=="player_home" and army.get("status","")=="stationed"
			var report:Dictionary=army.get("last_report",{})
			if not home and not bool(snapshot.get("live_reports",false)):
				if report.get("formations",[]).is_empty():
					result.append({"name":String(army.get("name","Field army")),"glyph":"⚑","location":"Awaiting formation report","count":int(report.get("troops",0)),"unknown":true});continue
				forces.append({"force":report,"location":"%s · report %dd old" % [army.get("name","Field army"),maxi(0,int(GameState.elapsed_days)-int(report.get("day",0)))]})
			else:forces.append({"force":army,"location":army.get("name","Field army")})
		for occupation:Dictionary in campaign.occupation_forces:forces.append({"force":occupation,"location":"Occupation garrison"})
		for group:Dictionary in forces:
			for unit:Dictionary in group.force.get("formations",[]):
				var count:=int(unit.get("count",0));var attending:=int(unit.get("training_attending",0)) if not "report" in String(group.location) else 0
				var type_id:=String(unit.get("unit","levy"))
				var glyph:="♞" if type_id in ["cavalry","horse_archer","mounted_archer"] else "➶" if String(unit.get("weapon",""))=="bow" else "⚔"
				result.append({"name":campaign.UnitCatalog.archetype(type_id).get("label",type_id),"glyph":glyph,"location":group.location,"count":count,"authorized":int(unit.get("authorized_count",count)),"condition":float(unit.get("personnel_condition",1)),"equipment":float(unit.get("equipment",0))/maxf(1,unit.get("equipment_required",count)),"equipment_note":"Ammo %d / %d" % [unit.get("ammunition",0),unit.get("ammunition_required",0)],"skill":float(unit.get("training",0)),"experience":float(unit.get("experience",0)),"activity":"Staff training" if attending>0 else "On duty / reserve","progress":float(campaign.training_program.get("progress_days",0))/maxf(1,campaign.training_program.get("duration_days",1)) if attending>0 else 0.0,"training_note":"%d soldiers rotating" % attending if attending>0 else "Policy: "+String(campaign.training_staff.policy(service).label)})
		for trainee:Dictionary in campaign.training_queue:
			var count:=int(trainee.get("count",0));var days:=float(trainee.get("required_days",1));var progress:=float(trainee.get("progress_days",0))
			result.append({"name":campaign.UnitCatalog.archetype(String(trainee.get("unit","levy"))).get("label","Recruits"),"glyph":"◇","location":"Initial instruction","count":count,"authorized":int(trainee.get("initial_count",count)),"condition":float(trainee.get("personnel_condition",1)),"equipment":float(trainee.get("equipment_access_today",0)),"equipment_note":"Training equipment access","skill":0.0,"experience":float(trainee.get("experience",0)),"activity":"Initial training","progress":progress/maxf(1,days),"training_note":"%.0f / %.0f instruction days" % [progress,days]})
	else:
		var op=campaign.joint_operations
		for unit:Dictionary in op.state.forces:
			if unit.owner!="player" or unit.domain!=service:continue
			var authorized:=0
			for amount in unit.authorized.values():authorized+=int(amount)
			var staff_status:=String(unit.get("training_status",""))
			var exercising:=int(unit.get("training_attending",0))>0 and float(unit.training)>=1.0
			var activity:=staff_status if exercising else String(unit.status)
			var note:=String(unit.status) if exercising else staff_status
			if note==activity or note=="":note="Policy: "+String(campaign.training_staff.policy(service).label)
			result.append({"name":unit.name,"glyph":"⚓" if service=="navy" else "✈","location":op.base(int(unit.base_id)).get("name","Base unavailable"),"count":op.hardware(unit),"authorized":authorized,"condition":float(unit.condition),"equipment":float(op.hardware(unit))/maxf(1,authorized),"equipment_note":"%d crew" % op.crew(unit),"skill":float(unit.get("proficiency",.45 if float(unit.training)>=1 else 0)),"experience":float(unit.experience),"activity":activity,"progress":float(unit.training),"training_note":note})
	return result
func _inspection()->void:
	var box:=HBoxContainer.new();body.add_child(box)
	_label(box,String(selected_row.glyph),48)
	var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_child(details)
	_label(details,String(selected_row.name),21)
	if bool(selected_row.get("unknown",false)):
		_label(details,"Awaiting a dated report of this army’s formations and equipment.",14);return
	_label(details,"Drill %d%%   ·   Experience %d%%   ·   Condition %d%%" % [selected_row.skill*100,selected_row.experience*100,selected_row.condition*100])
	var note:=_label(details,"Service staff choose exercises under your standing policy. New recruits attend full-time instruction.",14);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(box,"Training policy",func():training_view=true;selected_row={};_build_body())
func _policy()->void:
	_label(body,"HOW MUCH SHOULD WE TRAIN?",24)
	var note:=_label(body,"You set the commitment. Staff select units, organize exercises and stop for shortages or emergencies.",15);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",12);body.add_child(grid)
	for id:String in MilitaryCampaign.training_staff.POLICIES:
		var definition:Dictionary=MilitaryCampaign.training_staff.POLICIES[id]
		var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",10);grid.add_child(card)
		var choice:=id
		var button:=_button(card,String(definition.label),func():MilitaryCampaign.training_staff.set_policy(service,choice);_update_policy());button.toggle_mode=true;button.custom_minimum_size.y=44;policy_buttons[id]=button
		_label(card,"%d%% rotating" % roundi(float(definition.share)*100),20)
		var bar:=_bar(card,Color("dfb967"));bar.value=float(definition.share)*100
		_label(card,"Drill target: %d%%" % roundi(float(definition.target)*100),14)
		var description:=_label(card,String(definition.description),13);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size.x=135
	policy_status=_label(body,"",16);policy_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_label(body,"TRAINING INVESTMENT",17)
	var costs:=_label(body,"Initial instruction: at least 45 effective days for land forces; naval and air crews require at least 90 effective days of full-time instruction. Army exercises run 72–252 effective days. Higher commitments consume more food, training materials and fuel, and leave fewer personnel on immediate duty.",14);costs.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var protection:=_label(body,"Staff protect a seven-day civilian food reserve. Shortages pause progress; repeated orders never accelerate it.",14);protection.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_update_policy()
func _update_policy()->void:
	var state:Dictionary=MilitaryCampaign.training_staff.snapshot(service)
	for id in policy_buttons:policy_buttons[id].set_pressed_no_signal(id==state.id)
	policy_status.text=String(state.status)+"\nTraining spent: %.1f extra rations · %.1f base materials" % [state.food_spent,state.materials_spent]
	if service=="army" and not state.active.is_empty():policy_status.text+="\n%s · %.0f / %.0f effective days · %.1f extra rations used" % [state.active.label,state.active.progress_days,state.active.duration_days,state.active.food_consumed_total]
