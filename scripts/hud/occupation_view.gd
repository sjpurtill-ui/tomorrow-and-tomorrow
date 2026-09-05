extends CanvasLayer
const MODEL=preload("res://scripts/occupation_governance.gd")
var civ_id:String=""
var region_id:String=""
var summary:Label
var detail:Label
var feedback:Label
var resident_count:SpinBox
var transfer_count:SpinBox
var transfer_status:OptionButton
var transfer_report:Label
var community_choice:OptionButton
var community_signature:String=""
var timer:float=0
var policy_buttons:Dictionary={}

static func open(civ:String,region:String)->void:
	var view=load("res://scripts/hud/occupation_view.gd").new()
	view.civ_id=civ; view.region_id=region
	Engine.get_main_loop().root.add_child(view)

func _ready()->void:
	layer=79
	var background:=ColorRect.new()
	background.color=Color("142029"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	background.add_child(margin)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",12); margin.add_child(column)
	var top:=HBoxContainer.new(); column.add_child(top)
	var title:=Label.new(); title.text="OCCUPATION • PEOPLE & GOVERNMENT"; title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(title)
	var close:=Button.new(); close.text="RETURN TO MAP"; close.pressed.connect(queue_free); top.add_child(close)
	summary=Label.new(); summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(summary)
	var tabs:=TabContainer.new(); tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL; tabs.use_hidden_tabs_for_min_size=false; column.add_child(tabs)
	var policies:=VBoxContainer.new(); policies.name="Government"; tabs.add_child(policies)
	for key:String in MODEL.POLICIES:
		var row:=HBoxContainer.new(); policies.add_child(row)
		var button:=Button.new(); button.text=String(MODEL.POLICIES[key].label); button.custom_minimum_size=Vector2(185,48); row.add_child(button)
		button.pressed.connect(_order.bind(key)); policy_buttons[key]=button
		var description:=Label.new(); description.text=String(MODEL.POLICIES[key].description); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(description)
	var people:=VBoxContainer.new(); people.name="Residents & recovery"; tabs.add_child(people)
	detail=Label.new(); detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; people.add_child(detail)
	for order:String in ["raze","reconstruct"]:
		var button:=Button.new(); button.text="RAZE INFRASTRUCTURE • residents remain" if order=="raze" else "AUTHORIZE RECONSTRUCTION"; button.pressed.connect(_order.bind(order)); people.add_child(button); policy_buttons[order]=button
	var resident_row:=HBoxContainer.new();people.add_child(resident_row)
	resident_count=SpinBox.new();resident_count.min_value=1;resident_count.max_value=1000000000;resident_count.value=1;resident_row.add_child(resident_count)
	var killing:=Button.new();killing.text="KILL SELECTED RESIDENTS";killing.tooltip_text="Mass killing: selected residents die; trust and diplomatic relations collapse. This does not raze infrastructure or move survivors.";killing.pressed.connect(_resident_order.bind("kill_residents"));resident_row.add_child(killing)
	var autonomy:=Button.new();autonomy.text="RESTORE LOCAL SELF-RULE";autonomy.tooltip_text="Return control to the original polity and order a physical garrison withdrawal.";autonomy.pressed.connect(_resident_order.bind("restore_self_rule"));people.add_child(autonomy)
	var transfers:=VBoxContainer.new(); transfers.name="Movement & status"; tabs.add_child(transfers)
	var explanation:=Label.new(); explanation.text="Residents travel to your home settlement. A continuous land route, travel rations and available housing are required. Food leaves the occupied region at departure; people arrive after the journey. Penal status means imposed coercive labor, not evidence of individual guilt."; explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; transfers.add_child(explanation)
	var transfer_row:=HBoxContainer.new();transfers.add_child(transfer_row)
	transfer_count=SpinBox.new();transfer_count.min_value=1;transfer_count.max_value=1000000000;transfer_count.value=5;transfer_row.add_child(transfer_count)
	transfer_status=OptionButton.new()
	for key:String in MilitaryCampaign.occupation_transfers.STATUSES: transfer_status.add_item(MilitaryCampaign.occupation_transfers.STATUSES[key])
	transfer_row.add_child(transfer_status)
	var transfer_actions:=HBoxContainer.new();transfers.add_child(transfer_actions)
	var send:=Button.new();send.text="REVIEW TRANSFER";send.pressed.connect(_preview_transfer);transfer_actions.add_child(send)
	var depart:=Button.new();depart.text="SEND RESIDENTS";depart.pressed.connect(_depart_transfer);transfer_actions.add_child(depart)
	transfer_report=Label.new();transfer_report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;transfers.add_child(transfer_report)
	community_choice=OptionButton.new();transfers.add_child(community_choice)
	var rights:=Button.new();rights.text="GRANT EQUAL CITIZENSHIP";rights.pressed.connect(_emancipate);transfers.add_child(rights)
	feedback=Label.new(); feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(feedback)
	for label:Label in find_children("*","Label",true,false):label.add_theme_font_size_override("font_size",14)
	_refresh()

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: queue_free(); get_viewport().set_input_as_handled()

func _process(delta:float)->void:
	timer+=delta
	if timer>=.5: timer=0; _refresh()

func _order(order:String)->void:
	var result:Dictionary=CivilizationSystem.set_occupation_policy(civ_id,region_id,order)
	feedback.text=String(result.get("error",result.get("message","")))
	_refresh()

func _refresh()->void:
	var data:Dictionary=CivilizationSystem.occupation_governance_snapshot(civ_id,region_id)
	if data.is_empty():
		summary.text="This region is no longer under your administration. Return to the map for current reports."
		for button:Button in policy_buttons.values(): button.disabled=true
		return
	summary.text="%s • %s\n%d residents • %d garrison soldiers / %d required • Resistance %d%% • Integration %d%%\n%s • Policy changes take at least 30 days; social recovery takes years." % [data.name,MODEL.POLICIES[String(data.policy)].label,roundi(float(data.population)),int(data.garrison),ceili(float(data.required_garrison)),roundi(float(data.resistance)*100),roundi(float(data.integration)*100),data.milestone]
	detail.text="RESIDENT CONDITIONS\nWelfare %d%% • Trust %d%% • Local institutions %d%%\nGrievance %d%% • Inherited grievance %d%% • Legal inequality %d%%\nIndependence support %d%% • Administrative legitimacy %d%%\n\nInfrastructure damage %d%% • %s\n\nResidents retain their origin and remain in this region. Razing buildings does not kill or move them. Reform changes legal treatment; it does not erase prior harm." % [roundi(float(data.welfare)*100),roundi(float(data.trust)*100),roundi(float(data.local_institutions)*100),roundi(float(data.grievance)*100),roundi(float(data.inherited_grievance)*100),roundi(float(data.inequality)*100),roundi(float(data.support)*100),roundi(float(data.legitimacy)*100),roundi(float(data.damage)*100),"reconstruction authorized" if bool(data.reconstruction) else ("ruins persist" if bool(data.ruined) else "inhabited settlement")]
	var transfer_lines:Array[String]=[]
	for transfer:Dictionary in MilitaryCampaign.occupation_transfers.data.transfers:
		transfer_lines.append("%d residents from %s • %.0f km remaining • %.0f rations%s" % [int(transfer.people),String(transfer.origin_region_name),maxf(0,float(transfer.distance)-float(transfer.traveled)),float(transfer.food)," • waiting for housing" if bool(transfer.arrived) else ""])
	transfer_report.text="TRAVELING GROUPS\n"+("\n".join(transfer_lines) if not transfer_lines.is_empty() else "No groups traveling.")
	var signature:=JSON.stringify(MilitaryCampaign.occupation_transfers.data.groups)
	if signature!=community_signature:
		community_signature=signature
		var selected_id:=community_choice.get_selected_id() if community_choice.selected>=0 else -1
		community_choice.clear()
		for group:Dictionary in MilitaryCampaign.occupation_transfers.data.groups:
			community_choice.add_item("%s • %s • grievance %d%%" % [String(group.origin_name),MilitaryCampaign.occupation_transfers.STATUSES[String(group.status)],roundi(float(group.grievance)*100)],int(group.id))
			if int(group.id)==selected_id:community_choice.select(community_choice.item_count-1)
	var cooldown:=int(GameState.elapsed_days)-int(data.last_order_day)<30
	for key:String in policy_buttons:
		var button:Button=policy_buttons[key]
		button.disabled=cooldown or key==String(data.policy)
		button.tooltip_text="Current policy" if key==String(data.policy) else ("Wait until day %d for another administrative order." % (int(data.last_order_day)+30) if cooldown else "")

func _transfer_status()->String:
	return String(MilitaryCampaign.occupation_transfers.STATUSES.keys()[transfer_status.selected])
func _preview_transfer()->void:
	var result:Dictionary=MilitaryCampaign.occupation_transfers.preview(civ_id,region_id,int(transfer_count.value),_transfer_status())
	feedback.text=String(result.error) if result.has("error") else "%d residents • %.0f km • about %d days • %.0f travel rations from the occupied region." % [int(result.people),float(result.distance),int(result.days),float(result.food)]
func _depart_transfer()->void:
	var result:Dictionary=MilitaryCampaign.occupation_transfers.depart(civ_id,region_id,int(transfer_count.value),_transfer_status())
	feedback.text=String(result.get("error",result.get("message","")))
	_refresh()
func _emancipate()->void:
	if community_choice.selected<0:return
	var result:Dictionary=MilitaryCampaign.occupation_transfers.emancipate(community_choice.get_item_id(community_choice.selected))
	feedback.text=String(result.get("error",result.get("message","")))
	_refresh()

func _resident_order(order:String)->void:
	var result:Dictionary=CivilizationSystem.occupation_resident_order(civ_id,region_id,order,int(resident_count.value))
	feedback.text=String(result.get("error",result.get("message","")));_refresh()
