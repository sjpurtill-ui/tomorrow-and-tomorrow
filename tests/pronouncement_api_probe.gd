extends Node

var failures:Array[String]=[]
var api_result:Dictionary={}
var concurrent_orders:Dictionary={}
var cancelled_result_received:=false
var retry_result:Dictionary={}
var retry_completion_count:=0
var grounding_result:Dictionary={}
var downgrade_result:Dictionary={}
var downgrade_completion_count:=0
var retry_progress:Array[Dictionary]=[]
var fallback_result:Dictionary={}
var fallback_progress:Array[Dictionary]=[]
var malformed_contract_result:Dictionary={}
var cancel_progress:Array[Dictionary]=[]
var redirect_result:Dictionary={}
var oversize_result:Dictionary={}

func _ready()->void:
	var configuration:=PronouncementInterpreter.configuration_status()
	_expect(bool(configuration.get("configured",false)) and bool(configuration.get("structured_output",false)),"API diagnostics did not report strict configured mode")
	_expect(String(configuration.get("model",""))=="mock-model" and String(configuration.get("endpoint_host",""))=="127.0.0.1:18765","API diagnostics omitted the safe model or endpoint host")
	_expect(String(configuration.get("transport_security",""))=="local loopback HTTP","API diagnostics did not distinguish loopback development transport")
	var diagnostic_text:=JSON.stringify(configuration)
	_expect("mock-key" not in diagnostic_text and "/v1/chat/completions" not in diagnostic_text,"API diagnostics exposed credentials or a full endpoint path")
	GameState.reset_for_new_world(271828)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	var api_scholar:={"name":"Nima","background":"Keeper of Records","skills":{"Research":84,"Education":80},"goals":["preserve_knowledge"],"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4}},"memories":[]}
	GameState.advisor_roster=[api_scholar]
	GameState.leadership_positions={"Scholar":api_scholar}
	var pending_order:Dictionary=AdvisorSystem.begin_pronouncement("Support scholars and improve routes.")
	_expect(String(pending_order.status)=="interpreting" and GameState.sovereign_orders.size()==1,"HTTP pronouncement was not recorded before dispatch")
	PronouncementInterpreter.interpretation_completed.connect(_capture_result)
	PronouncementInterpreter.interpret("Support scholars and improve routes.",{"population":120,"day":0})
	for frame in 300:
		if not api_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_result)
	_expect(not api_result.is_empty(),"HTTP interpretation did not complete")
	if not api_result.is_empty():
		_expect(String(api_result.get("source",""))=="generative API","configured HTTP endpoint fell back to the local interpreter")
		_expect("\n" not in String(api_result.get("summary","")),"HTTP provider prose retained a ledger-forging line break")
		_expect(bool(api_result.get("structured_output_requested",false)) and bool(api_result.get("structured_output_used",false)) and not bool(api_result.get("structured_output_downgraded",false)),"HTTP request did not use the strict response schema")
		var policies:Array=api_result.get("policies",[])
		var by_id:Dictionary={}
		for policy in policies: by_id[String(policy.id)]=policy
		_expect(policies.size()==2,"API allowlist did not reject the invented policy")
		_expect(by_id.has("directed_inquiry"),"API inquiry policy was not accepted")
		_expect(by_id.has("route_priority"),"API route policy was not accepted")
		if by_id.has("directed_inquiry"):
			_expect(String(by_id.directed_inquiry.get("basis",""))=="support scholars" and float(by_id.directed_inquiry.get("confidence",0.0))>=0.55,"API policy lost its exact-text grounding")
		if by_id.has("route_priority"):
			_expect(is_equal_approx(float(by_id.route_priority.magnitude),0.16),"API response gained authority over catalog strength")
			_expect(is_equal_approx(float(by_id.route_priority.days),240.0),"API response gained authority over catalog duration")
			_expect(String(by_id.route_priority.parameter_basis)=="catalog defaults","API policy omitted deterministic parameter provenance")
		var order:Dictionary=AdvisorSystem.execute_pronouncement("Support scholars and improve routes.",api_result,pending_order)
		_expect(GameState.sovereign_orders.size()==1 and String(order.id)==String(pending_order.id),"HTTP response duplicated instead of resolving the pending order")
		_expect(String(order.parameters.interpretation.source)=="generative API","order lost API provenance")
		_expect(ConsequenceEngine.modifier_strength("directed_inquiry")>0.0,"API inquiry policy did not reach game modifiers")
		_expect(ConsequenceEngine.modifier_strength("route_priority")>0.0,"API route policy did not reach game modifiers")
		_expect((order.get("political_reactions",[]) as Array).size()==1 and String(order.political_reactions[0].advisor)=="Nima","grounded API policies did not ripple into named council reactions")
		_expect(float(api_scholar.relationships.sovereign.trust)>0.5,"API-origin policy approval did not change the advisor relationship used by later execution")
	await _test_transient_retry()
	await _test_structured_output_downgrade()
	await _test_terminal_api_fallback_progress()
	await _test_malformed_contract_fallback()
	await _test_redirect_refusal()
	await _test_oversized_response_refusal()
	await _test_retry_backoff_cancellation()
	await _test_ungrounded_allowed_policy_rejection()
	await _test_concurrent_http_ordering()
	await _test_http_cancellation()
	if failures.is_empty():
		print("PRONOUNCEMENT_API_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("PRONOUNCEMENT_API_PROBE "+failure)
		get_tree().quit(1)

func _capture_result(_request_id:String,result:Dictionary)->void:
	api_result=result

func _test_transient_retry()->void:
	GameState.reset_for_new_world(141421)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	retry_result={}
	retry_completion_count=0
	retry_progress.clear()
	var pending_order:=AdvisorSystem.begin_pronouncement("Retry interpretation: support scholars and improve routes.")
	PronouncementInterpreter.interpretation_completed.connect(_capture_retry_result)
	PronouncementInterpreter.interpretation_progress.connect(_capture_retry_progress)
	var request_id:=PronouncementInterpreter.interpret("Retry interpretation: support scholars and improve routes.",{})
	pending_order["request_id"]=request_id
	for frame in 1200:
		if not retry_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_retry_result)
	PronouncementInterpreter.interpretation_progress.disconnect(_capture_retry_progress)
	_expect(not retry_result.is_empty(),"transient HTTP failure never recovered")
	_expect(retry_completion_count==1,"retried request emitted more than one completion")
	_expect(int(retry_result.get("api_attempts",0))==2,"successful retry did not retain its attempt count")
	_expect("attempt 2" in String(retry_result.get("source_detail","")),"successful retry was not auditable")
	var stages:Array[String]=[]
	for progress in retry_progress: stages.append(String(progress.get("stage","")))
	_expect(stages.count("requesting")==2 and stages.has("retrying") and stages.has("accepted"),"retry lifecycle did not emit requesting, retrying, and accepted stages")
	if not retry_result.is_empty():
		var resolved:=AdvisorSystem.execute_pronouncement(String(pending_order.parameters.text),retry_result,pending_order)
		_expect(String(resolved.id)==String(pending_order.id) and GameState.sovereign_orders.size()==1,"retry duplicated the pending sovereign order")
		_expect(ConsequenceEngine.active_policies().size()==2,"retried interpretation did not apply exactly one copy of each policy")
	_expect(PronouncementInterpreter.pending_request_count()==0,"successful retry remained pending")

func _capture_retry_result(_request_id:String,result:Dictionary)->void:
	retry_completion_count+=1
	retry_result=result

func _capture_retry_progress(_request_id:String,status:Dictionary)->void:
	retry_progress.append(status.duplicate(true))

func _test_structured_output_downgrade()->void:
	GameState.reset_for_new_world(223607)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	downgrade_result={}
	downgrade_completion_count=0
	var pending_order:=AdvisorSystem.begin_pronouncement("Schema downgrade interpretation: support scholars and improve routes.")
	PronouncementInterpreter.interpretation_completed.connect(_capture_downgrade_result)
	PronouncementInterpreter.interpret("Schema downgrade interpretation: support scholars and improve routes.",{})
	for frame in 1200:
		if not downgrade_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_downgrade_result)
	_expect(not downgrade_result.is_empty() and downgrade_completion_count==1,"structured-output downgrade did not resolve exactly once")
	_expect(int(downgrade_result.get("api_attempts",0))==2 and bool(downgrade_result.get("structured_output_downgraded",false)),"schema rejection did not trigger one compatibility downgrade")
	_expect(bool(downgrade_result.get("structured_output_requested",false)) and not bool(downgrade_result.get("structured_output_used",true)),"downgraded response provenance was incorrect")
	_expect("compatibility downgrade" in String(downgrade_result.get("source_detail","")),"schema downgrade was not disclosed")
	var resolved:=AdvisorSystem.execute_pronouncement(String(pending_order.parameters.text),downgrade_result,pending_order)
	_expect(String(resolved.id)==String(pending_order.id) and GameState.sovereign_orders.size()==1,"schema downgrade duplicated the sovereign order")
	_expect(ConsequenceEngine.active_policies().size()==2,"compatible plain-JSON retry did not apply the grounded policies")

func _capture_downgrade_result(_request_id:String,result:Dictionary)->void:
	downgrade_completion_count+=1
	downgrade_result=result

func _test_terminal_api_fallback_progress()->void:
	GameState.reset_for_new_world(244949)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	fallback_result={}
	fallback_progress.clear()
	var pending_order:=AdvisorSystem.begin_pronouncement("Permanent failure interpretation: expand the watch.")
	PronouncementInterpreter.interpretation_completed.connect(_capture_fallback_result)
	PronouncementInterpreter.interpretation_progress.connect(_capture_fallback_progress)
	PronouncementInterpreter.interpret("Permanent failure interpretation: expand the watch.",{})
	for frame in 1200:
		if not fallback_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_fallback_result)
	PronouncementInterpreter.interpretation_progress.disconnect(_capture_fallback_progress)
	_expect(String(fallback_result.get("source",""))=="deterministic interpreter" and int(fallback_result.get("api_attempts",0))==2,"terminal API failure did not produce an auditable deterministic fallback")
	var stages:Array[String]=[]
	for progress in fallback_progress: stages.append(String(progress.get("stage","")))
	_expect(stages.count("requesting")==2 and stages.has("retrying") and stages.has("fallback"),"terminal failure did not emit the complete fallback lifecycle")
	var resolved:=AdvisorSystem.execute_pronouncement(String(pending_order.parameters.text),fallback_result,pending_order)
	_expect(String(resolved.status)=="active" and ConsequenceEngine.modifier_strength("expanded_watch")>0.0,"safe deterministic fallback did not resolve the original typed order")

func _capture_fallback_result(_request_id:String,result:Dictionary)->void:
	fallback_result=result

func _capture_fallback_progress(_request_id:String,status:Dictionary)->void:
	fallback_progress.append(status.duplicate(true))

func _test_malformed_contract_fallback()->void:
	GameState.reset_for_new_world(256019)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	malformed_contract_result={}
	var pending_order:=AdvisorSystem.begin_pronouncement("Malformed contract interpretation: expand the watch.")
	PronouncementInterpreter.interpretation_completed.connect(_capture_malformed_contract_result)
	PronouncementInterpreter.interpret("Malformed contract interpretation: expand the watch.",{})
	for frame in 1200:
		if not malformed_contract_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_malformed_contract_result)
	_expect(String(malformed_contract_result.get("source",""))=="deterministic interpreter" and int(malformed_contract_result.get("api_attempts",0))==2,"malformed typed contract was accepted or skipped the bounded fallback path")
	_expect(String(malformed_contract_result.get("provider_request_id",""))!="malformed-contract-provider","malformed contract retained provider acceptance provenance")
	var resolved:=AdvisorSystem.execute_pronouncement(String(pending_order.parameters.text),malformed_contract_result,pending_order)
	_expect(String(resolved.status)=="active" and ConsequenceEngine.modifier_strength("expanded_watch")>0.0,"malformed-contract fallback did not preserve the typed deterministic order")

func _capture_malformed_contract_result(_request_id:String,result:Dictionary)->void:
	malformed_contract_result=result

func _test_redirect_refusal()->void:
	GameState.reset_for_new_world(264575)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	redirect_result={}
	var pending_order:=AdvisorSystem.begin_pronouncement("Redirect interpretation: expand the watch.")
	PronouncementInterpreter.interpretation_completed.connect(_capture_redirect_result)
	PronouncementInterpreter.interpret("Redirect interpretation: expand the watch.",{})
	for frame in 1200:
		if not redirect_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_redirect_result)
	_expect(String(redirect_result.get("source",""))=="deterministic interpreter","provider redirect was followed instead of falling back safely")
	_expect(String(redirect_result.get("provider_request_id",""))!="redirect-followed","redirected provider response crossed the transport boundary")
	var resolved:=AdvisorSystem.execute_pronouncement(String(pending_order.parameters.text),redirect_result,pending_order)
	_expect(String(resolved.status)=="active" and ConsequenceEngine.modifier_strength("expanded_watch")>0.0,"redirect refusal did not preserve the bounded local interpretation")

func _capture_redirect_result(_request_id:String,result:Dictionary)->void:
	redirect_result=result

func _test_oversized_response_refusal()->void:
	GameState.reset_for_new_world(282843)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	oversize_result={}
	var pending_order:=AdvisorSystem.begin_pronouncement("Oversize interpretation: expand the watch.")
	PronouncementInterpreter.interpretation_completed.connect(_capture_oversize_result)
	PronouncementInterpreter.interpret("Oversize interpretation: expand the watch.",{})
	for frame in 1600:
		if not oversize_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_oversize_result)
	_expect(String(oversize_result.get("source",""))=="deterministic interpreter" and int(oversize_result.get("api_attempts",0))==2,"oversized provider body was accepted or did not fail through the bounded retry path")
	_expect(String(oversize_result.get("provider_request_id",""))!="oversized-provider-response","oversized provider payload reached policy validation")
	var resolved:=AdvisorSystem.execute_pronouncement(String(pending_order.parameters.text),oversize_result,pending_order)
	_expect(String(resolved.status)=="active" and ConsequenceEngine.modifier_strength("expanded_watch")>0.0,"oversize refusal did not preserve the bounded local interpretation")

func _capture_oversize_result(_request_id:String,result:Dictionary)->void:
	oversize_result=result

func _test_retry_backoff_cancellation()->void:
	PronouncementInterpreter.reset_for_new_world()
	cancelled_result_received=false
	PronouncementInterpreter.interpretation_completed.connect(_capture_cancelled_result)
	var request_id:=PronouncementInterpreter.interpret("Retry interpretation cancellation: expand the watch.",{})
	var reached_backoff:=false
	for frame in 600:
		var progress:=PronouncementInterpreter.request_progress(request_id)
		if bool(progress.get("retry_scheduled",false)):
			reached_backoff=true
			break
		await get_tree().process_frame
	_expect(reached_backoff,"retrying request never entered cancellable backoff")
	_expect(PronouncementInterpreter.cancel(request_id),"request could not be cancelled during retry backoff")
	await get_tree().create_timer(0.35).timeout
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_cancelled_result)
	_expect(not cancelled_result_received,"request cancelled during retry backoff emitted a completion")
	_expect(PronouncementInterpreter.pending_request_count()==0,"backoff cancellation remained pending")

func _test_ungrounded_allowed_policy_rejection()->void:
	GameState.reset_for_new_world(173205)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	grounding_result={}
	var pending_order:=AdvisorSystem.begin_pronouncement("Grounding rejection: ration food.")
	PronouncementInterpreter.interpretation_completed.connect(_capture_grounding_result)
	PronouncementInterpreter.interpret("Grounding rejection: ration food.",{})
	for frame in 600:
		if not grounding_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_grounding_result)
	_expect(not grounding_result.is_empty() and String(grounding_result.get("source",""))=="generative API","grounding rejection fixture did not return an API interpretation")
	_expect((grounding_result.get("policies",[]) as Array).is_empty(),"API applied allowed policy IDs unsupported by the typed pronouncement")
	_expect(int(grounding_result.get("grounding_rejections",0))==2 and "withheld" in String(grounding_result.get("unresolved","")),"grounding rejection was not auditable")
	var resolved:=AdvisorSystem.execute_pronouncement("Grounding rejection: ration food.",grounding_result,pending_order)
	_expect(String(resolved.status)=="recorded_unresolved","ungrounded API result did not settle as an unresolved order")
	_expect(ConsequenceEngine.active_policies().is_empty(),"ungrounded API result changed standing game variables")

func _capture_grounding_result(_request_id:String,result:Dictionary)->void:
	grounding_result=result

func _test_concurrent_http_ordering()->void:
	GameState.reset_for_new_world(161803)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	concurrent_orders.clear()
	PronouncementInterpreter.interpretation_completed.connect(_resolve_concurrent_result)
	var older:=AdvisorSystem.begin_pronouncement("Slow interpretation: support scholars and improve routes.")
	var older_request:=PronouncementInterpreter.interpret("Slow interpretation: support scholars and improve routes.",{})
	concurrent_orders[older_request]=older
	var newer:=AdvisorSystem.begin_pronouncement("Fast interpretation: support scholars and improve routes.")
	var newer_request:=PronouncementInterpreter.interpret("Fast interpretation: support scholars and improve routes.",{})
	concurrent_orders[newer_request]=newer
	for frame in 600:
		if String(older.status)!="interpreting" and String(newer.status)!="interpreting": break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_resolve_concurrent_result)
	_expect(String(newer.status)=="active","newer fast HTTP response did not establish policy")
	_expect(String(older.status)=="stale","older slow HTTP response was not rejected as stale")
	var active:=ConsequenceEngine.active_policies()
	_expect(active.size()==2,"concurrent HTTP interpretations created an incorrect active-policy count")
	for policy in active: _expect(String(policy.source_order_id)==String(newer.id),"late HTTP response replaced a policy from the newer order")
	_expect(float(ConsequenceEngine.governance_metrics().policy_churn)==0.0,"stale HTTP response created reversal churn")

func _resolve_concurrent_result(request_id:String,result:Dictionary)->void:
	if not concurrent_orders.has(request_id): return
	var order:Dictionary=concurrent_orders[request_id]
	AdvisorSystem.execute_pronouncement(String(order.parameters.text),result,order)

func _test_http_cancellation()->void:
	PronouncementInterpreter.reset_for_new_world()
	cancelled_result_received=false
	cancel_progress.clear()
	PronouncementInterpreter.interpretation_completed.connect(_capture_cancelled_result)
	PronouncementInterpreter.interpretation_progress.connect(_capture_cancel_progress)
	var request_id:=PronouncementInterpreter.interpret("Slow interpretation: expand the watch.",{})
	_expect(PronouncementInterpreter.pending_request_count()==1,"HTTP cancellation fixture never became pending")
	_expect(PronouncementInterpreter.cancel(request_id),"pending HTTP request refused cancellation")
	await get_tree().create_timer(0.55).timeout
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_cancelled_result)
	PronouncementInterpreter.interpretation_progress.disconnect(_capture_cancel_progress)
	_expect(not cancelled_result_received,"cancelled HTTP request emitted a late interpretation")
	_expect(PronouncementInterpreter.pending_request_count()==0,"cancelled HTTP request remained registered")
	var stages:Array[String]=[]
	for progress in cancel_progress: stages.append(String(progress.get("stage","")))
	_expect(stages.has("requesting") and stages.has("cancelled"),"HTTP cancellation did not emit a visible lifecycle transition")

func _capture_cancelled_result(_request_id:String,_result:Dictionary)->void:
	cancelled_result_received=true

func _capture_cancel_progress(_request_id:String,status:Dictionary)->void:
	cancel_progress.append(status.duplicate(true))

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
