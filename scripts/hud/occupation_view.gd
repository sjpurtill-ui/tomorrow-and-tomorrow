extends CanvasLayer
const MODEL=preload("res://scripts/occupation_governance.gd")
var civ_id:String=""
var region_id:String=""
var summary:Label
var detail:Label
var feedback:Label
var timer:float=0
var policy_buttons:Dictionary={}

static func open(civ:String,region:String)->void:
	var view=load("res://scripts/hud/occupation_view.gd").new()
	view.civ_id=civ; view.region_id=region
	Engine.get_main_loop().root.add_child(view)

func _ready()->void:
	layer=89
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
	var tabs:=TabContainer.new(); tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(tabs)
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
	feedback=Label.new(); feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(feedback)
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
	summary.text="%s • %s
%d residents • %d garrison soldiers / %d required • Resistance %d%% • Integration %d%%
%s • Policy changes take at least 30 days; social recovery takes years." % [data.name,MODEL.POLICIES[String(data.policy)].label,roundi(float(data.population)),int(data.garrison),ceili(float(data.required_garrison)),roundi(float(data.resistance)*100),roundi(float(data.integration)*100),data.milestone]
	detail.text="RESIDENT CONDITIONS
Welfare %d%% • Trust %d%% • Local institutions %d%%
Grievance %d%% • Inherited grievance %d%% • Legal inequality %d%%
Independence support %d%% • Administrative legitimacy %d%%

Infrastructure damage %d%% • %s

Residents retain their origin and remain in this region. Razing buildings does not kill or move them. Reform changes legal treatment; it does not erase prior harm." % [roundi(float(data.welfare)*100),roundi(float(data.trust)*100),roundi(float(data.local_institutions)*100),roundi(float(data.grievance)*100),roundi(float(data.inherited_grievance)*100),roundi(float(data.inequality)*100),roundi(float(data.support)*100),roundi(float(data.legitimacy)*100),roundi(float(data.damage)*100),"reconstruction authorized" if bool(data.reconstruction) else ("ruins persist" if bool(data.ruined) else "inhabited settlement")]
	var cooldown:=int(GameState.elapsed_days)-int(data.last_order_day)<30
	for key:String in policy_buttons:
		var button:Button=policy_buttons[key]
		button.disabled=cooldown or key==String(data.policy)
		button.tooltip_text="Current policy" if key==String(data.policy) else ("Wait until day %d for another administrative order." % (int(data.last_order_day)+30) if cooldown else "")
