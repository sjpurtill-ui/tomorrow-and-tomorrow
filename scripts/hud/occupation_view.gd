extends CanvasLayer
const MODEL=preload("res://scripts/occupation_governance.gd")
const INK:=Color("10191d")
const TEXT:=Color("e7e9df")
const MUTED:=Color("a5b5b8")
const GOLD:=Color("f2c14e")
const RED:=Color("ee866d")
var civ_id:=""
var region_id:=""
var summary:Label
var detail:Label
var feedback:Label
var resident_count:SpinBox
var transfer_count:SpinBox
var transfer_status:OptionButton
var transfer_report:Label
var community_choice:OptionButton
var community_signature:=""
var timer:=0.0
var policy_buttons:Dictionary={}
var canvas:Control
var panel:PanelContainer
var tabs:TabContainer
var alert:Label
var metrics:Dictionary={}
var selected_policy:=""
var policy_title:Label
var policy_detail:Label
var policy_terms:Label
var policy_commit:Button
var decision:VBoxContainer
var decision_title:Label
var decision_detail:Label
var decision_commit:Button
var pending_decision:=""
var reviewed_residents:=0
var transfer_quote:Label
var transfer_commit:Button
var reviewed_transfer:=""
var current:Dictionary={}
var previous_scale:Vector2i
var previous_aspect:int
var rights:Button
var transfer_page:=0
var reinforce:Button
var control_explanation:Label
var reviewed_reinforcements:=0

static func open(civ:String,region:String)->void:
	var view=load("res://scripts/hud/occupation_view.gd").new();view.civ_id=civ;view.region_id=region
	Engine.get_main_loop().root.add_child(view)
func _style()->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=INK;s.border_color=Color("34474b");s.set_border_width_all(1);s.set_corner_radius_all(8)
	for edge in ["left","right","top","bottom"]:s.set("content_margin_"+edge,12.0)
	return s
func _label(parent:Node,text:String,font_size:int=14,color:Color=TEXT)->Label:
	var n:=Label.new();n.text=text;n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.add_theme_font_size_override("font_size",font_size);n.add_theme_color_override("font_color",color);parent.add_child(n);return n
func _box(parent:Node)->VBoxContainer:
	var n:=VBoxContainer.new();n.add_theme_constant_override("separation",9);parent.add_child(n);return n
func _row(parent:Node)->HBoxContainer:
	var n:=HBoxContainer.new();n.add_theme_constant_override("separation",8);parent.add_child(n);return n
func _button(parent:Node,text:String,callback:Callable,color:Color=TEXT)->Button:
	var n:=Button.new();n.text=text;n.custom_minimum_size.y=34;n.add_theme_font_size_override("font_size",14);n.add_theme_color_override("font_color",color)
	var s:=_style();s.bg_color=Color("223035");s.content_margin_top=5;s.content_margin_bottom=5;n.add_theme_stylebox_override("normal",s)
	n.pressed.connect(callback);parent.add_child(n);return n
func _metric(parent:Node,key:String,title:String,explanation:String)->void:
	var box:=_box(parent);box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var row:=_row(box);var name:=_label(row,title,13,MUTED);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var value:=_label(row,"",18);value.autowrap_mode=TextServer.AUTOWRAP_OFF
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=5;box.add_child(bar)
	box.tooltip_text=explanation;metrics[key]={"value":value,"bar":bar}
func _ready()->void:
	layer=79;previous_scale=get_window().content_scale_size;previous_aspect=get_window().content_scale_aspect
	get_window().content_scale_size=Vector2i.ZERO;get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	canvas=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(canvas)
	panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",_style());panel.add_theme_font_override("font",load("res://assets/fonts/battle/Barlow-Medium.ttf"));canvas.add_child(panel)
	panel.minimum_size_changed.connect(_layout.call_deferred)
	_layout()
	var column:=_box(panel);var top:=_row(column)
	summary=_label(top,"Occupied settlement",24);summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(top,"Return",queue_free)
	alert=_label(column,"",15,GOLD)
	reinforce=_button(column,"Reinforcements",_reinforce,GOLD);reinforce.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var vital:=GridContainer.new();vital.columns=2;vital.add_theme_constant_override("h_separation",20);vital.add_theme_constant_override("v_separation",8);column.add_child(vital)
	_metric(vital,"garrison","Effective garrison","Soldiers present / required. Effective security also needs supply; understaffing increases resistance in the monthly model.")
	_metric(vital,"resistance","Resistance","Opposition to occupation, not a revolt probability. Grievance and weak security increase it; security and legitimacy reduce it over time.")
	tabs=TabContainer.new();tabs.use_hidden_tabs_for_min_size=false;tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(tabs)
	var government:=_box(tabs);government.name="Government"
	var choices:=_row(government);var list:=_box(choices);list.custom_minimum_size.x=175;var preview:=_box(choices);preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for key:String in MODEL.POLICIES:policy_buttons[key]=_button(list,MODEL.POLICIES[key].label,_select_policy.bind(key),RED if key=="forced_labor" else TEXT)
	policy_title=_label(preview,"",20,GOLD);policy_detail=_label(preview,"",14);policy_terms=_label(preview,"",13,MUTED)
	policy_commit=_button(preview,"Adopt policy",_commit_policy,GOLD)
	var people:=_box(tabs);people.name="Residents"
	detail=_label(people,"",14,MUTED)
	var indicators:=GridContainer.new();indicators.columns=2;indicators.add_theme_constant_override("h_separation",20);indicators.add_theme_constant_override("v_separation",10);people.add_child(indicators)
	for item in [["welfare","Welfare","Services and living conditions; rights and supply help, coercion and damage hurt."],["trust","Trust","Trust in the administration. Improves slowly with security, welfare and rights; inherited grievance slows recovery."],["local_institutions","Local institutions","Institutional capacity supporting legitimacy and reconstruction."],["damage","Infrastructure damage","Damaged share of infrastructure. Repairs need supplied administration and local institutions."],["grievance","Grievance","Current harm and dissatisfaction. Reform does not erase it."],["inherited_grievance","Inherited grievance","Grievance transmitted over generations; it changes slowly."],["inequality","Legal inequality","Unequal legal treatment; policy moves it gradually toward its rights setting."],["integration","Integration","Long-term civic integration. Peace, supply, rights and trust support growth."]]:_metric(indicators,item[0],item[1],item[2])
	policy_buttons.reconstruct=_button(people,"Review reconstruction",_review.bind("reconstruct"),GOLD)
	var transfers:=_box(tabs);transfers.name="Movement"
	_label(transfers,"Move residents to home",20)
	_label(transfers,"Requires a land route, a garrison, travel rations and housing. People leave this city at departure and join home only on arrival.",13,MUTED)
	var transfer_row:=_row(transfers);transfer_count=SpinBox.new();transfer_count.min_value=1;transfer_count.max_value=1000000000;transfer_count.value=5;transfer_row.add_child(transfer_count)
	transfer_status=OptionButton.new();transfer_status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for key:String in MilitaryCampaign.occupation_transfers.STATUSES:transfer_status.add_item(MilitaryCampaign.occupation_transfers.STATUSES[key])
	transfer_row.add_child(transfer_status)
	var transfer_actions:=_row(transfers);_button(transfer_actions,"Review route & cost",_preview_transfer);transfer_commit=_button(transfer_actions,"Confirm departure",_depart_transfer,GOLD);transfer_commit.disabled=true
	transfer_quote=_label(transfers,"Choose the number of residents and their legal status, then review the route.",13,MUTED)
	transfer_count.value_changed.connect(func(_value:float):reviewed_transfer="";transfer_commit.disabled=true)
	transfer_status.item_selected.connect(func(_value:int):reviewed_transfer="";transfer_commit.disabled=true)
	transfer_report=_label(transfers,"",14)
	var pages:=_row(transfers);_button(pages,"Previous groups",func():transfer_page=maxi(0,transfer_page-1);_refresh());_button(pages,"Next groups",func():transfer_page+=1;_refresh())
	community_choice=OptionButton.new();community_choice.fit_to_longest_item=false;transfers.add_child(community_choice)
	rights=_button(transfers,"Grant equal citizenship",_emancipate)
	var control:=_box(tabs);control.name="Control"
	_label(control,"Decisions that change the city permanently",20,RED)
	control_explanation=_label(control,"",14,GOLD)
	_button(control,"Assign arrived troops to strengthen control",func():
		var ready:=MilitaryCampaign.occupation_action_availability(civ_id,region_id,"reinforce_control")
		if ready.has("error"):feedback.text=String(ready.error);return
		reviewed_reinforcements=int(ready.amount);pending_decision="reinforce_control";tabs.hide();decision.show();decision_title.text="Strengthen the garrison";decision_detail.text="Transfer %d soldiers from the army stationed here into the occupation force. They leave that field army; no people are created. Supply and resistance can change the requirement."%int(ready.amount);decision_commit.text="Assign %d soldiers"%int(ready.amount);_layout())
	_label(control,"Review a decision to see its consequences before issuing it. Local self-rule as a policy keeps your administration; restoring control below ends it.",14,MUTED)
	policy_buttons.raze=_button(control,"Review destruction of infrastructure",_review.bind("raze"),RED)
	_button(control,"Review return to original polity",_review.bind("restore_self_rule"))
	var resident_row:=_row(control);resident_count=SpinBox.new();resident_count.min_value=1;resident_count.max_value=1000000000;resident_row.add_child(resident_count)
	_button(resident_row,"Review killing residents",_review.bind("kill_residents"),RED)
	decision=_box(column);decision.visible=false;decision_title=_label(decision,"",18,RED);decision_detail=_label(decision,"",14)
	var confirmation:=_row(decision);decision_commit=_button(confirmation,"Confirm",_confirm_decision,RED);_button(confirmation,"Cancel",func():decision.hide();tabs.show();pending_decision="")
	feedback=_label(column,"Policies update conditions over months and years. Bars show current state, not predicted trends.",13,MUTED)
	var world:=CityEncounterWorld.terrain(get_tree().root)
	if world!=null:CityEncounterWorld.focus(world,region_id)
	canvas.resized.connect(_layout);_refresh();_layout()
func _layout()->void:
	if panel==null:return
	var screen:=get_viewport().get_visible_rect().size
	var width:=minf(650,screen.x-24);panel.position=Vector2(screen.x-width-12,12);panel.size=Vector2(width,0)
func _exit_tree()->void:
	get_window().set_deferred("content_scale_size",previous_scale);get_window().set_deferred("content_scale_aspect",previous_aspect)
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	timer+=delta
	if timer>=.5:timer=0;_refresh()
func _select_policy(key:String)->void:
	selected_policy=key;_refresh()
func _commit_policy()->void:
	if selected_policy=="forced_labor":_review(selected_policy)
	else:_order(selected_policy)
func _order(order:String)->void:
	var result:Dictionary=CivilizationSystem.set_occupation_policy(civ_id,region_id,order);feedback.text=String(result.get("error",result.get("message","")));_refresh()
func _refresh()->void:
	current=CivilizationSystem.occupation_governance_snapshot(civ_id,region_id)
	if current.is_empty():
		summary.text="Administration ended";alert.text="Control has changed. Return to the map for the current situation.";tabs.hide();decision.hide();return
	var data:=current;summary.text=String(data.name)
	var missing:=maxi(0,ceili(float(data.required_garrison))-int(data.garrison))
	var availability:=MilitaryCampaign.occupation_action_availability(civ_id,region_id,"reinforce_occupation")
	reinforce.visible=data.get("control",{}).has("error")
	reinforce.text="Assign %d arrived soldiers"%int(availability.amount) if availability.has("amount") else "Bring a field army to reinforce"
	reinforce.tooltip_text=String(availability.get("error","Transfers soldiers from the strongest army stationed here into this garrison."))
	var control:Dictionary=data.get("control",{})
	alert.text=("Troops present; control unsupported. " if control.has("error") else "Effective garrison in place. ")+"%d residents · %s"%[roundi(float(data.population)),String(data.milestone)]
	alert.tooltip_text=String(control.get("error","Supplied and ready troops meet the current population and resistance requirement."))
	metrics.garrison.bar.tooltip_text=String(control.get("error","Current occupation requirement met."))
	metrics.garrison.value.text="%.1f / %d"%[float(control.get("effective",data.garrison)),ceili(float(data.required_garrison))];metrics.garrison.bar.value=100*float(control.get("effective",data.garrison))/maxf(1,float(data.required_garrison))
	for key:String in metrics:
		if key=="garrison":continue
		metrics[key].value.text="%d%%"%roundi(float(data.get(key,0))*100);metrics[key].bar.value=float(data.get(key,0))*100
	detail.text="%s · Administrative legitimacy %d%% · Independence support %d%%"%["Reconstruction authorized" if bool(data.reconstruction) else ("Ruins persist until reconstruction" if bool(data.ruined) else "Inhabited settlement"),roundi(float(data.legitimacy)*100),roundi(float(data.support)*100)]
	if selected_policy.is_empty():selected_policy=String(data.policy)
	var coercion:=CivilizationSystem.occupation_coercion_availability(civ_id,region_id)
	control_explanation.text=String(coercion.get("error","The force meets the city-wide control requirement. Each coercive operation commits it for 30 days; resident operations are limited by troops left after garrison duties."))
	var rules:Dictionary=MODEL.POLICIES[selected_policy];var remaining:=maxi(0,int(data.last_order_day)+30-int(GameState.elapsed_days))
	policy_title.text=String(rules.label);policy_detail.text=String(rules.description)
	policy_terms.text="Policy settings: rights %d%% · coercion %d%%\nExtraction %d%% · local autonomy %d%%\n%s"%[roundi(float(rules.rights)*100),roundi(float(rules.coercion)*100),roundi(float(rules.extraction)*100),roundi(float(rules.autonomy)*100),"Next change in %d days."%remaining if remaining>0 else "Locks administrative changes for 30 days. Social effects take years."]
	policy_commit.disabled=remaining>0 or selected_policy==String(data.policy);policy_commit.text="Current policy" if selected_policy==String(data.policy) else "Review enslavement" if selected_policy=="forced_labor" else "Adopt "+String(rules.label)
	if selected_policy in ["forced_labor","military_rule"] and coercion.has("error"):
		policy_commit.disabled=true;policy_terms.text+="\n"+String(coercion.error)
	for key:String in policy_buttons:
		policy_buttons[key].disabled=(remaining>0) if key in ["raze","reconstruct"] else false
		policy_buttons[key].tooltip_text="Next administrative order in %d days."%remaining if remaining>0 else ""
	var active:Array=MilitaryCampaign.occupation_transfers.data.transfers
	transfer_page=clampi(transfer_page,0,maxi(0,(active.size()-1)/3));var lines:Array[String]=[]
	for transfer:Dictionary in active.slice(transfer_page*3,transfer_page*3+3):lines.append("%d from %s · %.0f km left · %.0f rations%s"%[int(transfer.people),String(transfer.origin_region_name),maxf(0,float(transfer.distance)-float(transfer.traveled)),float(transfer.food)," · awaiting housing" if bool(transfer.arrived) else ""])
	transfer_report.text="Traveling groups %d/%d\n"%[transfer_page+1,maxi(1,ceili(active.size()/3.0))]+("\n".join(lines) if not lines.is_empty() else "No groups traveling.")
	var signature:=JSON.stringify(MilitaryCampaign.occupation_transfers.data.groups)
	if signature!=community_signature:
		community_signature=signature;var selected:=community_choice.get_selected_id();community_choice.clear()
		for group:Dictionary in MilitaryCampaign.occupation_transfers.data.groups:
			community_choice.add_item("%s · %s"%[String(group.origin_name),MilitaryCampaign.occupation_transfers.STATUSES[String(group.status)]],int(group.id))
			if int(group.id)==selected:community_choice.select(community_choice.item_count-1)
	rights.disabled=community_choice.item_count==0
func _review(order:String)->void:
	if order in ["raze","kill_residents","forced_labor","military_rule"]:
		var allowed:=CivilizationSystem.occupation_coercion_availability(civ_id,region_id,int(resident_count.value) if order=="kill_residents" else 0)
		if allowed.has("error"):feedback.text=String(allowed.error);return

	tabs.hide();reviewed_residents=int(resident_count.value)
	pending_decision=order;decision.show();decision_title.text={"raze":"Destroy infrastructure","reconstruct":"Authorize reconstruction","restore_self_rule":"Return control","kill_residents":"Kill %d residents"%int(resident_count.value),"forced_labor":"Impose enslavement"}.get(order,order)
	decision_detail.text={"raze":"All infrastructure damage becomes 100%. Grievance rises by 25 points, institutions lose up to 30 points, and relations worsen. Residents stay alive here. Another administrative order requires 30 days.","reconstruct":"Authorize gradual repairs supported by supply and local institutions. This does not instantly rebuild the city or charge a separate construction budget. Administrative changes lock for 30 days.","restore_self_rule":"Control returns to the original polity. Your garrison begins its physical return journey. Prior damage and grievance remain.","kill_residents":"These are permanent deaths. Trust and legitimacy become zero, grievance reaches 100%, resistance rises and relations collapse. No residents are transferred. This commits the force for 30 days.","forced_labor":"Residents are held in slavery. Extraction increases while welfare, trust and legitimacy deteriorate. Relations worsen immediately; inherited grievance persists. Administrative changes lock for 30 days."}.get(order,"")
	decision_commit.text=decision_title.text;_layout()
func _reinforce()->void:
	var availability:=MilitaryCampaign.occupation_action_availability(civ_id,region_id,"reinforce_occupation")
	if not availability.has("error"):
		var result:=MilitaryCampaign.reinforce_occupation(civ_id,region_id);feedback.text=String(result.get("error",result.get("message","")));_refresh()
	else:
		var world:=CityEncounterWorld.terrain(get_tree().root)
		if world!=null:world._on_hud_section_requested("military",0);queue_free()
		else:feedback.text=String(availability.error)
func _confirm_decision()->void:
	var order:=pending_decision;pending_decision="";decision.hide();tabs.show()
	if order=="reinforce_control":
		var ready:=MilitaryCampaign.occupation_action_availability(civ_id,region_id,"reinforce_control")
		if ready.has("error") or int(ready.get("amount",0))!=reviewed_reinforcements:feedback.text=String(ready.get("error","The available force changed. Review the assignment again."));return
		var result:=MilitaryCampaign.reinforce_occupation(civ_id,region_id,true);feedback.text=String(result.get("error",result.get("message","")));_refresh()
	elif order in ["kill_residents","restore_self_rule"]:_resident_order(order)
	elif not order.is_empty():_order(order)
func _resident_order(order:String)->void:
	var result:=CivilizationSystem.occupation_resident_order(civ_id,region_id,order,reviewed_residents);feedback.text=String(result.get("error",result.get("message","")));_refresh()
func _transfer_status()->String:return String(MilitaryCampaign.occupation_transfers.STATUSES.keys()[transfer_status.selected])
func _transfer_key()->String:return "%d/%s"%[int(transfer_count.value),_transfer_status()]
func _preview_transfer()->void:
	var result:Dictionary=MilitaryCampaign.occupation_transfers.preview(civ_id,region_id,int(transfer_count.value),_transfer_status())
	transfer_quote.text=String(result.error) if result.has("error") else "%d residents · %.0f km · about %d days · %.0f rations from this region. Arrival status: %s."%[int(result.people),float(result.distance),int(result.days),float(result.food),MilitaryCampaign.occupation_transfers.STATUSES[_transfer_status()]]
	reviewed_transfer="" if result.has("error") else _transfer_key();transfer_commit.disabled=reviewed_transfer.is_empty()
func _depart_transfer()->void:
	if reviewed_transfer!=_transfer_key():return
	var result:Dictionary=MilitaryCampaign.occupation_transfers.depart(civ_id,region_id,int(transfer_count.value),_transfer_status());feedback.text=String(result.get("error",result.get("message","")));reviewed_transfer="";transfer_commit.disabled=true;_refresh()
func _emancipate()->void:
	if community_choice.selected<0:return
	var result:Dictionary=MilitaryCampaign.occupation_transfers.emancipate(community_choice.get_item_id(community_choice.selected));feedback.text=String(result.get("error",result.get("message","")));_refresh()
