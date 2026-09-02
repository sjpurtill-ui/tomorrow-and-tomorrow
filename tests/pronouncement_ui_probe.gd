extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
var failures:Array[String]=[]

func _ready()->void:
	GameState.reset_for_new_world(314159)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	AdvisorSystem.register_advisors([{"name":"ROUTE COORDINATION COUNCIL","background":"Caravan Organizer","skills":{"Administration":72,"Logistics":78}}])
	terrain._open_council_panel()
	await get_tree().process_frame
	var config_label:=terrain.council_panel.find_child("InterpreterConfigLabel",true,false) as Label
	_expect(config_label!=null and "POLICY INTERPRETATION  •  LOCAL RULES" in config_label.text,"council did not disclose its safe local interpretation mode")
	if config_label: _expect("credential" in config_label.tooltip_text.to_lower() and "displayed" in config_label.tooltip_text.to_lower(),"interpreter status did not disclose credential redaction")
	var order_input:LineEdit=null
	for candidate in terrain.council_panel.find_children("*","LineEdit",true,false):
		if "policy to enact" in String(candidate.placeholder_text).to_lower():
			order_input=candidate
			break
	_expect(order_input!=null,"real council panel did not expose its pronouncement field")
	if order_input:
		order_input.text="Ration food and improve routes."
		terrain._issue_freeform_order(order_input)
		_expect(not order_input.editable,"input remained editable during interpretation")
		_expect(GameState.sovereign_orders.size()==1 and String(GameState.sovereign_orders[0].status)=="interpreting","typed pronouncement was not immediately recorded as pending")
		terrain._open_council_panel()
		var pending_text:=""
		for label in terrain.council_panel.find_children("*","Label",true,false): pending_text+=String(label.text)+"\n"
		_expect("INTERPRETING" in pending_text and "AWAITING BOUNDED INTERPRETATION" in pending_text,"pending interpretation did not survive council close/reopen")
		for frame in 12:
			if not GameState.sovereign_orders.is_empty() and String(GameState.sovereign_orders[0].status)!="interpreting": break
			await get_tree().process_frame
		_expect(not GameState.sovereign_orders.is_empty() and String(GameState.sovereign_orders[0].status)!="interpreting","typed UI pronouncement did not resolve its pending order")
		if not GameState.sovereign_orders.is_empty():
			var order:Dictionary=GameState.sovereign_orders[0]
			_expect(String(order.get("type",""))=="pronouncement","UI created the wrong order type")
			var ids:Array=order.get("policy_ids",[])
			_expect(ids.has("rationing"),"typed rationing language did not reach the order record")
			_expect(ids.has("route_priority"),"typed route language did not reach the order record")
		_expect(ConsequenceEngine.modifier_strength("rationing")>0.0,"typed rationing language did not reach game modifiers")
		_expect(ConsequenceEngine.modifier_strength("route_priority")>0.0,"typed route language did not reach game modifiers")
		var reopened_input:LineEdit=null
		for candidate in terrain.council_panel.find_children("*","LineEdit",true,false):
			if "policy to enact" in String(candidate.placeholder_text).to_lower(): reopened_input=candidate; break
		_expect(reopened_input and reopened_input.editable and reopened_input.text.is_empty(),"pronouncement field did not recover after completion")
		_expect(terrain.pronouncement_status_label and "INTERPRETED VIA" in terrain.pronouncement_status_label.text,"council did not display interpretation provenance")
		terrain._open_council_panel()
		await get_tree().process_frame
		var visible_policy_text:=""
		var policy_audit_text:=""
		for label in terrain.council_panel.find_children("*","Label",true,false):
			visible_policy_text+=String(label.text)+"\n"
			policy_audit_text+=String(label.tooltip_text)+"\n"
		_expect("POLICIES IN FORCE" in visible_policy_text,"council did not expose the active-policy ledger")
		_expect("RATIONING" in visible_policy_text and "ROUTE PRIORITY" in visible_policy_text,"active typed policies were absent from the government ledger")
		_expect("DAYS LEFT" in visible_policy_text,"active policy duration was not visible")
		_expect("CHANGES" in visible_policy_text and "food demand" in visible_policy_text and "logistics" in visible_policy_text,"active ledger did not disclose affected game variables")
		_expect("GROUNDED READING" in policy_audit_text and "ration" in policy_audit_text.to_lower(),"council audit tooltip did not preserve the phrase grounding its interpreted policy")
		_expect("ACTION SOURCE  •  deterministic enact reading of player clause" in policy_audit_text,"council audit tooltip did not disclose deterministic action polarity")
		_expect("TERMS  •  catalog defaults" in policy_audit_text,"council audit tooltip did not disclose where policy strength and duration came from")
		_expect("LATEST OBSERVED" in visible_policy_text,"council did not expose the latest linked metric observation")
		_expect("ACTIVE" in visible_policy_text,"pronouncement history did not display reconciled lifecycle status")
		_expect("ADMINISTRATION USED" in visible_policy_text and "RECENT POLICY CHANGES" in visible_policy_text and "COUNCIL SUPPORT" in visible_policy_text,"council did not expose government burden and political support")
		_expect("COUNCIL RESPONSE" in visible_policy_text and "ROUTE COORDINATION COUNCIL" in visible_policy_text,"pronouncement history did not expose institutional council reactions")
		var ambiguity_input:LineEdit=null
		for candidate in terrain.council_panel.find_children("*","LineEdit",true,false):
			if "policy to enact" in String(candidate.placeholder_text).to_lower(): ambiguity_input=candidate; break
		if ambiguity_input:
			ambiguity_input.text="End rationing. Ration food and improve routes."
			terrain._issue_freeform_order(ambiguity_input)
			for frame in 12:
				if not GameState.sovereign_orders.is_empty() and String(GameState.sovereign_orders[0].status)!="interpreting": break
				await get_tree().process_frame
			terrain._open_council_panel()
			await get_tree().process_frame
			var ambiguity_text:=""
			for label in terrain.council_panel.find_children("*","Label",true,false): ambiguity_text+=String(label.text)+"\n"+String(label.tooltip_text)+"\n"
			_expect("UNRESOLVED" in ambiguity_text and "BOUNDED LOCAL INTERPRETATION" in ambiguity_text and "contradictory" in ambiguity_text,"partial pronouncement history hid or mislabelled a withheld contradictory clause")
			_expect(ConsequenceEngine.modifier_strength("rationing")>0.0,"withheld contradiction incorrectly ended the existing rationing policy")
		var cancellation_input:LineEdit=null
		for candidate in terrain.council_panel.find_children("*","LineEdit",true,false):
			if "policy to enact" in String(candidate.placeholder_text).to_lower(): cancellation_input=candidate; break
		if cancellation_input:
			cancellation_input.text="Expand the watch."
			terrain._issue_freeform_order(cancellation_input)
			var cancel_order:Dictionary=GameState.sovereign_orders[0]
			terrain._open_council_panel()
			var cancel_button:Button=null
			for button in terrain.council_panel.find_children("*","Button",true,false):
				if String(button.text)=="WITHDRAW PENDING POLICY": cancel_button=button; break
			_expect(cancel_button!=null,"pending pronouncement exposed no cancellation control")
			if cancel_button: cancel_button.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			_expect(String(cancel_order.status)=="cancelled","cancelled pronouncement did not retain cancelled ledger status")
			_expect(ConsequenceEngine.modifier_strength("expanded_watch")==0.0,"cancelled deferred interpretation applied policy")
			_expect(PronouncementInterpreter.pending_request_count()==0,"cancelled interpretation remained pending")
			var cancelled_text:=""
			for label in terrain.council_panel.find_children("*","Label",true,false): cancelled_text+=String(label.text)+"\n"
			_expect("CANCELLED" in cancelled_text and "No standing policy was applied" in cancelled_text,"cancellation outcome was not visible in council history")
	if failures.is_empty():
		print("PRONOUNCEMENT_UI_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("PRONOUNCEMENT_UI_PROBE "+failure)
		get_tree().quit(1)

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
