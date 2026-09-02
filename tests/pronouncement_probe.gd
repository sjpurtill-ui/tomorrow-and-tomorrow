extends Node

var failures:Array[String]=[]
var async_result:Dictionary={}
var stale_result_received:=false

func _ready()->void:
	GameState.reset_for_new_world(24680)
	ConsequenceEngine.initialize()
	_test_local_compound_interpretation()
	_test_policy_catalog_integrity()
	_test_endpoint_transport_boundary()
	_test_structured_response_schema()
	_test_contract_validation()
	_test_clause_scoped_policy_terms()
	_test_api_envelope_parsing()
	_test_execution_and_repeal()
	_test_political_reaction_feedback()
	_test_policy_lifecycle()
	_test_variable_level_ripple()
	_test_daily_security_ripple()
	_test_broader_government_ripples()
	_test_policy_observation_feedback()
	_test_policy_reversal_cost()
	_test_out_of_order_completion()
	await _test_restart_cancels_deferred_result()
	await _test_async_ripple()
	if failures.is_empty():
		print("PRONOUNCEMENT_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("PRONOUNCEMENT_PROBE "+failure)
		get_tree().quit(1)

func _test_local_compound_interpretation()->void:
	var result:Dictionary=PronouncementInterpreter._local_interpretation("Care for the sick, expand the watch, and build shelters.")
	var ids:Array=[]
	for policy in result.policies: ids.append(String(policy.id))
	_expect(ids.has("care_rotation"),"care language did not map to care_rotation")
	_expect(ids.has("expanded_watch"),"watch language did not map to expanded_watch")
	_expect(ids.has("emergency_building"),"building language did not map to emergency_building")
	_expect(String(result.source)=="deterministic interpreter","offline source was not auditable")
	var mixed:Dictionary=PronouncementInterpreter._local_interpretation("End rationing and expand the watch.")
	var actions:Dictionary={}
	for policy in mixed.policies: actions[String(policy.id)]=String(policy.action)
	_expect(actions.get("rationing")=="repeal","repeal language enacted rationing instead of ending it")
	_expect(actions.get("expanded_watch")=="enact","a later enactment clause inherited the earlier repeal action")
	var broader:Dictionary=PronouncementInterpreter._local_interpretation("Support scholars and improve routes.")
	var broader_ids:Array=[]
	for policy in broader.policies: broader_ids.append(String(policy.id))
	_expect(broader_ids.has("directed_inquiry"),"scholar support did not map to directed inquiry")
	_expect(broader_ids.has("route_priority"),"route language did not map to route priority")
	var contradictory:=PronouncementInterpreter._local_interpretation("End rationing. Ration food and expand the watch.")
	var contradictory_ids:Array=[]
	for policy in contradictory.policies: contradictory_ids.append(String(policy.id))
	_expect(not contradictory_ids.has("rationing") and contradictory_ids.has("expanded_watch"),"contradictory policy wording was applied or suppressed an unambiguous clause")
	_expect(int(contradictory.get("ambiguity_rejections",0))==1 and "contradictory" in String(contradictory.unresolved),"contradictory local wording was not audited")
	var repeated_repeal:=PronouncementInterpreter._local_interpretation("End rationing; stop rationing.")
	_expect(repeated_repeal.policies.size()==1 and String(repeated_repeal.policies[0].action)=="repeal","consistent repeated repeal wording was treated as contradictory")
	var over_cap:=PronouncementInterpreter._local_interpretation("Ration food, expand the watch, build shelters, and care for the sick.")
	_expect(over_cap.policies.size()==3 and int(over_cap.capacity_rejections)==1,"local interpreter silently exceeded or miscounted the three-policy cap")
	_expect("at most three" in String(over_cap.unresolved),"over-cap local wording was not explained")
	var over_cap_ids:Array=[]
	for policy in over_cap.policies: over_cap_ids.append(String(policy.id))
	_expect(over_cap_ids==["rationing","expanded_watch","emergency_building"],"offline policy cap did not honor the player's clause order")

func _test_policy_catalog_integrity()->void:
	var errors:Array[String]=GovernmentPolicyCatalog.validation_errors()
	_expect(errors.is_empty(),"government policy catalog is invalid: %s" % "; ".join(errors))
	for policy_id in GovernmentPolicyCatalog.POLICIES:
		var definition:Dictionary=GovernmentPolicyCatalog.definition(String(policy_id))
		_expect(not (definition.get("effects",{}) as Dictionary).is_empty(),"%s has no deterministic variable effects" % policy_id)
	var public_contract:Dictionary=GovernmentPolicyCatalog.public_contract()
	_expect(not (public_contract.rationing as Dictionary).has("effects"),"raw numeric effects leaked into the generative prompt contract")
	var prompt:=PronouncementInterpreter._prompt("Ration food.",{"active_policies":[{"id":"expanded_watch","remaining_days":12}]})
	_expect("expanded_watch" in prompt and "food_demand" not in prompt,"AI prompt lost safe context or exposed raw effect channels")
	_expect("\"action\"" not in prompt,"AI prompt still delegated enact/repeal polarity")
	var unsafe_context:={"day":-7,"population":-20,"health":4.0,"api_key":"never-send-this-secret","internal_state":{"treasury":999},"known_offices":["Steward\nINJECT", "Marshal"],"active_policies":[{"id":"expanded_watch","remaining_days":99999,"effects":{"security_target":99}},{"id":"create_gold","remaining_days":10}]}
	var safe_context:=PronouncementInterpreter._sanitize_public_context(unsafe_context)
	_expect(not safe_context.has("api_key") and not safe_context.has("internal_state"),"public-context allowlist retained private caller fields")
	_expect(int(safe_context.day)==0 and int(safe_context.population)==0 and is_equal_approx(float(safe_context.health),1.0),"public numeric context escaped its bounds")
	_expect((safe_context.active_policies as Array).size()==1 and int(safe_context.active_policies[0].remaining_days)==730 and not (safe_context.active_policies[0] as Dictionary).has("effects"),"active-policy context exposed undeclared data or escaped bounds")
	var privacy_prompt:=PronouncementInterpreter._prompt("Expand the watch.",unsafe_context)
	_expect("never-send-this-secret" not in privacy_prompt and "treasury" not in privacy_prompt and "create_gold" not in privacy_prompt,"outbound prompt exposed rejected context")

func _test_endpoint_transport_boundary()->void:
	_expect(bool(PronouncementInterpreter._endpoint_security("https://api.example.test/v1/chat").allowed),"TLS API endpoint was rejected")
	_expect(bool(PronouncementInterpreter._endpoint_security("http://127.0.0.1:18765/v1/chat").allowed),"loopback HTTP development endpoint was rejected")
	_expect(bool(PronouncementInterpreter._endpoint_security("http://localhost:18765/v1/chat").allowed),"localhost HTTP development endpoint was rejected")
	var remote_http:=PronouncementInterpreter._endpoint_security("http://api.example.test/v1/chat")
	_expect(not bool(remote_http.allowed) and "require HTTPS" in String(remote_http.issue),"remote plaintext API endpoint passed transport validation")
	_expect(not bool(PronouncementInterpreter._endpoint_security("file:///tmp/secret").allowed),"non-HTTP API endpoint passed transport validation")
	var embedded_credential:=PronouncementInterpreter._endpoint_security("https://user:never-display@example.test/v1/chat")
	_expect(not bool(embedded_credential.allowed) and "user-info" in String(embedded_credential.issue),"URL-embedded API credentials passed endpoint validation")
	_expect(PronouncementInterpreter._endpoint_host("https://user:never-display@example.test/v1/chat?token=also-secret") == "example.test","endpoint diagnostics exposed user-info, path, or query credentials")
	_expect(PronouncementInterpreter._endpoint_host("https://api.example.test?api-version=2026&token=secret") == "api.example.test","query-bearing endpoint leaked its query into diagnostics")
	_expect(not bool(PronouncementInterpreter._endpoint_security("https://api.example.test/v1/chat\nInjected: value").allowed),"control characters passed endpoint validation")

func _test_structured_response_schema()->void:
	var response_format:=PronouncementInterpreter._structured_response_format()
	var schema:Dictionary=response_format.json_schema.schema
	var policy_schema:Dictionary=schema.properties.policies.items
	var allowed:Array=policy_schema.properties.id.enum
	_expect(String(response_format.type)=="json_schema" and bool(response_format.json_schema.strict),"API response schema was not strict JSON schema")
	_expect(allowed.size()==GovernmentPolicyCatalog.POLICIES.size() and not allowed.has("create_gold"),"response schema policy enum diverged from the authoritative catalog")
	_expect((policy_schema.required as Array).has("basis") and (policy_schema.required as Array).has("confidence"),"response schema omitted grounding requirements")
	_expect(not (policy_schema.properties as Dictionary).has("magnitude") and not (policy_schema.properties as Dictionary).has("days"),"response schema gave the generative service numeric policy authority")
	_expect(not (policy_schema.properties as Dictionary).has("action"),"response schema gave the generative service action-polarity authority")
	_expect(int(schema.properties.policies.maxItems)==3,"response schema lost the three-policy execution cap")
	_expect(schema.additionalProperties==false and policy_schema.additionalProperties==false,"response schema allowed undeclared state-changing fields")

func _test_contract_validation()->void:
	var result:Dictionary=PronouncementInterpreter._validate({"summary":"Test","policies":[
		{"id":"expanded_watch","magnitude":99.0,"days":99999.0},
		{"id":"expanded_watch","action":"repeal","magnitude":0.1,"days":30.0},
		{"id":"create_gold","magnitude":0.2,"days":30.0}
	]})
	_expect(result.policies.size()==1,"validator accepted an invented policy")
	_expect(is_equal_approx(float(result.policies[0].magnitude),0.18),"validator trusted provider-supplied magnitude instead of the catalog")
	_expect(is_equal_approx(float(result.policies[0].days),180.0),"validator trusted provider-supplied duration instead of the catalog")
	_expect(String(result.policies[0].parameter_basis)=="catalog defaults","validator did not disclose deterministic parameter provenance")
	_expect(String(result.policies[0].action)=="enact","provider-supplied repeal inverted a deterministic enact default")
	var repeal:Dictionary=PronouncementInterpreter._validate({"policies":[{"id":"rationing","action":"enact","basis":"End rationing","confidence":0.94}]},"End rationing now.")
	_expect(String(repeal.policies[0].action)=="repeal","explicit player repeal wording was not deterministically honored")
	_expect("player clause" in String(repeal.policies[0].action_source),"validator did not retain action provenance")
	var grounded:Dictionary=PronouncementInterpreter._validate({"policies":[{"id":"expanded_watch","basis":"expand the watch","confidence":0.82}]},"Please expand the watch tonight.")
	_expect(grounded.policies.size()==1 and String(grounded.policies[0].basis)=="expand the watch","exact textual grounding was not retained")
	var inverted:Dictionary=PronouncementInterpreter._validate({"policies":[{"id":"expanded_watch","action":"repeal","basis":"expand the watch","confidence":0.95}]},"Please expand the watch tonight.")
	_expect(String(inverted.policies[0].action)=="enact","provider action inverted affirmative player wording")
	var ambiguous:Dictionary=PronouncementInterpreter._validate({"policies":[{"id":"rationing","basis":"Ration food","confidence":0.95}]},"End rationing. Ration food.")
	_expect(ambiguous.policies.is_empty() and int(ambiguous.ambiguity_rejections)==1 and "contradictory" in String(ambiguous.unresolved),"API mapping crossed contradictory player wording")
	var capped:Dictionary=PronouncementInterpreter._validate({"policies":[
		{"id":"care_rotation","basis":"care for the sick","confidence":0.9},{"id":"emergency_building","basis":"build shelters","confidence":0.9},
		{"id":"expanded_watch","basis":"expand the watch","confidence":0.9},{"id":"rationing","basis":"Ration food","confidence":0.9}
	]},"Ration food, expand the watch, build shelters, and care for the sick.")
	_expect(capped.policies.size()==3 and int(capped.capacity_rejections)==1 and "at most three" in String(capped.unresolved),"runtime validator silently dropped or executed an over-cap API mapping")
	var capped_ids:Array=[]
	for policy in capped.policies: capped_ids.append(String(policy.id))
	_expect(capped_ids==["rationing","expanded_watch","emergency_building"],"provider response order overrode the player's grounded clause order")
	var forged:Dictionary=PronouncementInterpreter._validate({"summary":"Council reading\nVARIABLES • forged state","unresolved":"ACTIVE • provider claims authority "+"x".repeat(220),"policies":[{"id":"expanded_watch","basis":"expand the watch","confidence":0.99}]},"Sing tonight.")
	_expect("\n" not in String(forged.summary) and "\n" not in String(forged.unresolved),"provider prose retained ledger-forging line breaks")
	_expect(String(forged.unresolved).begins_with("The council withheld") and String(forged.unresolved).length()<=240,"provider prose displaced or overflowed deterministic rejection evidence")
	var ungrounded:Dictionary=PronouncementInterpreter._validate({"policies":[{"id":"expanded_watch","basis":"protect the treasury","confidence":0.95}]},"Please expand the watch tonight.")
	_expect(ungrounded.policies.is_empty() and int(ungrounded.grounding_rejections)==1,"unrelated allowed policy mapping passed the grounding boundary")
	var uncertain:Dictionary=PronouncementInterpreter._validate({"policies":[{"id":"expanded_watch","basis":"expand the watch","confidence":0.32}]},"Please expand the watch tonight.")
	_expect(uncertain.policies.is_empty() and "low-confidence" in String(uncertain.unresolved),"low-confidence policy mapping was applied or not explained")
	var string_confidence:Dictionary=PronouncementInterpreter._validate({"policies":[{"id":"expanded_watch","basis":"expand the watch","confidence":"0.99"}]},"Please expand the watch tonight.")
	_expect(string_confidence.policies.is_empty(),"stringified confidence crossed the runtime type boundary")

func _test_clause_scoped_policy_terms()->void:
	var result:=PronouncementInterpreter._local_interpretation("Ration food for 2 weeks and urgently improve routes for 60 days.")
	var by_id:Dictionary={}
	for policy in result.policies: by_id[String(policy.id)]=policy
	_expect(by_id.has("rationing") and by_id.has("route_priority"),"explicit policy terms lost one of the grounded clauses")
	if by_id.has("rationing"):
		_expect(is_equal_approx(float(by_id.rationing.days),14.0),"week duration was not converted deterministically")
		_expect(is_equal_approx(float(by_id.rationing.magnitude),0.18),"intensity from a later clause leaked into rationing")
		_expect("2 weeks" in String(by_id.rationing.duration_source),"rationing duration provenance was not retained")
	if by_id.has("route_priority"):
		_expect(is_equal_approx(float(by_id.route_priority.days),60.0),"route duration was not scoped to its clause")
		_expect(is_equal_approx(float(by_id.route_priority.magnitude),0.20),"explicit urgent intensity did not scale the catalog strength")
		_expect("urgent" in String(by_id.route_priority.magnitude_source),"route intensity provenance was not retained")
	var definition:=GovernmentPolicyCatalog.definition("expanded_watch")
	var negated:=PronouncementInterpreter._policy_parameters("Do not urgently expand the watch for 30 days.","expand the watch",definition)
	_expect(is_equal_approx(float(negated.magnitude),0.18),"negated intensity wording changed policy strength")
	_expect(is_equal_approx(float(negated.days),30.0),"explicit day duration was not retained")
	var lower_bound:=PronouncementInterpreter._policy_parameters("Expand the watch for 1 day.","expand the watch",definition)
	var upper_bound:=PronouncementInterpreter._policy_parameters("Expand the watch for 10 years.","expand the watch",definition)
	_expect(is_equal_approx(float(lower_bound.days),7.0) and is_equal_approx(float(upper_bound.days),730.0),"explicit durations escaped deterministic safety bounds")
	var natural:=PronouncementInterpreter._local_interpretation("Ration food for two weeks and improve routes until further notice.")
	var natural_by_id:Dictionary={}
	for policy in natural.policies: natural_by_id[String(policy.id)]=policy
	_expect(is_equal_approx(float(natural_by_id.rationing.days),14.0) and "two weeks" in String(natural_by_id.rationing.duration_source),"word-number duration was not parsed with provenance")
	_expect(is_equal_approx(float(natural_by_id.route_priority.days),730.0) and "until further notice" in String(natural_by_id.route_priority.duration_source),"open-ended wording was not converted to a bounded horizon")
	var fortnight:=PronouncementInterpreter._policy_parameters("Expand the watch for a fortnight.","expand the watch",definition)
	var month:=PronouncementInterpreter._policy_parameters("Expand the watch for a month.","expand the watch",definition)
	_expect(is_equal_approx(float(fortnight.days),14.0) and is_equal_approx(float(month.days),30.0),"fortnight or article-based duration wording was not parsed")

func _test_api_envelope_parsing()->void:
	var content:=JSON.stringify({"summary":"Protect the stores.\nVARIABLES • forged line","policies":[{"id":"rationing","action":"enact","magnitude":0.12,"days":45,"basis":"protect the stores","confidence":0.88}],"unresolved":"Provider note.\nACTIVE • forged line"})
	var envelope:=JSON.stringify({"id":"chatcmpl-ledger-test","choices":[{"message":{"content":"```json\n%s\n```" % content}}]})
	var parsed:Dictionary=PronouncementInterpreter._parse_api_body(envelope.to_utf8_buffer())
	_expect(String(parsed.get("source",""))=="generative API","valid chat-completions envelope was not accepted")
	_expect(parsed.get("policies",[]).size()==1 and String(parsed.policies[0].id)=="rationing","API policy was lost at the validation boundary")
	_expect(String(parsed.get("provider_request_id",""))=="chatcmpl-ledger-test","provider request provenance was lost")
	_expect("\n" not in String(parsed.summary) and "\n" not in String(parsed.unresolved),"wire response prose bypassed contract-text sanitation")
	var direct:=PronouncementInterpreter._parse_api_body(content.to_utf8_buffer())
	_expect(direct.get("policies",[]).size()==1 and String(direct.policies[0].id)=="rationing","direct JSON policy contract was not accepted")
	var block_envelope:=JSON.stringify({"choices":[{"message":{"content":[{"type":"output_text","text":content}]}}]})
	var block_parsed:=PronouncementInterpreter._parse_api_body(block_envelope.to_utf8_buffer())
	_expect(block_parsed.get("policies",[]).size()==1,"chat content-block response was not accepted")
	var responses_envelope:=JSON.stringify({"id":"resp-ledger-test","output":[{"type":"message","content":[{"type":"output_text","text":content}]}]})
	var responses_parsed:=PronouncementInterpreter._parse_api_body(responses_envelope.to_utf8_buffer())
	_expect(responses_parsed.get("policies",[]).size()==1 and String(responses_parsed.get("provider_request_id",""))=="resp-ledger-test","Responses-style output was not accepted or lost provenance")
	var malformed:Dictionary=PronouncementInterpreter._parse_api_body("{not valid".to_utf8_buffer())
	_expect(malformed.is_empty(),"malformed API response reached policy validation")
	var wrong_types:=JSON.stringify({"summary":"Wrong type fixture","policies":[{"id":"expanded_watch","basis":"expand the watch","confidence":"0.99"}],"unresolved":""})
	_expect(PronouncementInterpreter._parse_api_body(wrong_types.to_utf8_buffer()).is_empty(),"compatibility response with invalid field types reached policy validation")

func _test_execution_and_repeal()->void:
	GameState.active_modifiers.clear()
	GameState.sovereign_orders.clear()
	GameState.leadership_positions.clear()
	var enact:=PronouncementInterpreter._local_interpretation("Expand the watch.")
	var pending_order:Dictionary=AdvisorSystem.begin_pronouncement("Expand the watch.")
	_expect(String(pending_order.status)=="interpreting" and pending_order.parameters.interpretation.is_empty(),"submitted pronouncement was not recorded before interpretation")
	var vacant_order:Dictionary=AdvisorSystem.execute_pronouncement("Expand the watch.",enact,pending_order)
	_expect(GameState.sovereign_orders.size()==1 and String(vacant_order.id)==String(pending_order.id),"interpretation duplicated instead of resolving the pending order")
	var active_count_before:=ConsequenceEngine.active_policies().size()
	var duplicate_resolution:Dictionary=AdvisorSystem.execute_pronouncement("Expand the watch.",enact,pending_order)
	_expect(String(duplicate_resolution.id)==String(pending_order.id) and ConsequenceEngine.active_policies().size()==active_count_before,"duplicate completion reapplied an already resolved order")
	var vacant_policy:Dictionary=vacant_order.parameters.interpretation.policies[0]
	_expect(float(vacant_policy.execution_factor)<1.0,"a vacant office executed at full strength")
	_expect(String(vacant_policy.executor).begins_with("Vacant"),"vacant execution was not disclosed")
	var first_strength:=ConsequenceEngine.modifier_strength("expanded_watch")
	var replacement_order:Dictionary=AdvisorSystem.execute_pronouncement("Expand the watch again.",enact)
	var watch_count:=0
	for active_policy in ConsequenceEngine.active_policies():
		if String(active_policy.id)=="expanded_watch": watch_count+=1
	_expect(watch_count==1 and ConsequenceEngine.modifier_strength("expanded_watch")<=first_strength,"repeated pronouncements stacked instead of superseding")
	_expect(String(vacant_order.status)=="superseded" and String(replacement_order.status)=="active","supersession did not reconcile sovereign order states")
	GameState.leadership_positions["Marshal"]={"name":"Ilya","skills":{"Strategy":100,"Public Order":100},"relationships":{"sovereign":{"trust":1.0,"respect":1.0}}}
	var staffed_order:Dictionary=AdvisorSystem.execute_pronouncement("Put Ilya in charge of the watch.",enact)
	var staffed_policy:Dictionary=staffed_order.parameters.interpretation.policies[0]
	_expect(float(staffed_policy.execution_factor)>float(vacant_policy.execution_factor),"staffing the responsible office did not improve execution")
	_expect(String(staffed_policy.executor)=="Ilya","the responsible office holder was not recorded as executor")
	var repeal:=PronouncementInterpreter._local_interpretation("End the watch.")
	var repeal_order:Dictionary=AdvisorSystem.execute_pronouncement("End the watch.",repeal)
	_expect(ConsequenceEngine.modifier_strength("expanded_watch")==0.0,"repeal did not end the active policy")
	_expect(bool(repeal_order.parameters.interpretation.policies[0].repealed_active_policy),"audit record did not show that an active policy was repealed")
	_expect(String(staffed_order.status)=="repealed" and String(repeal_order.status)=="executed","repeal did not reconcile enactment and repeal order states")

func _test_political_reaction_feedback()->void:
	_reset_simulation(314271)
	var builder:={"name":"Mara","background":"Master Builder","skills":{"Discipline":82,"Delegation":78},"goals":["establish_settlement"],"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4}},"memories":[]}
	var mediator:={"name":"Sela","background":"Trader and Mediator","skills":{"Oratory":78},"goals":["preserve_cohesion"],"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4}},"memories":[]}
	GameState.advisor_roster=[builder,mediator]
	GameState.leadership_positions={"Steward":builder}
	var execution_before:=AdvisorSystem.execution_modifier("Steward",["Discipline","Delegation"])
	var interpretation:=PronouncementInterpreter._local_interpretation("Mobilize labor.")
	var order:=AdvisorSystem.execute_pronouncement("Mobilize labor.",interpretation)
	var reactions:Array=order.get("political_reactions",[])
	var by_name:Dictionary={}
	for reaction_variant in reactions:
		var reaction:Dictionary=reaction_variant
		by_name[String(reaction.advisor)]=reaction
	_expect(reactions.size()==2 and by_name.has("Mara") and by_name.has("Sela"),"changed policy did not produce goal-based reactions from affected advisors")
	_expect(String((by_name.get("Mara",{}) as Dictionary).get("stance",""))=="supports" and float(builder.relationships.sovereign.trust)>0.5,"goal-aligned office holder did not gain trust")
	_expect(String((by_name.get("Sela",{}) as Dictionary).get("stance",""))=="objects" and float(mediator.relationships.sovereign.resentment)>0.0,"goal-strained advisor did not record an objection")
	_expect((order.parameters.interpretation.get("political_reactions",[]) as Array).size()==2,"political reactions were not retained in the interpretation ledger")
	var builder_trust_after:=float(builder.relationships.sovereign.trust)
	AdvisorSystem.execute_pronouncement("Mobilize labor.",interpretation,order)
	_expect(is_equal_approx(float(builder.relationships.sovereign.trust),builder_trust_after),"duplicate interpretation applied political reactions twice")
	GameState.active_modifiers.clear()
	var execution_after:=AdvisorSystem.execution_modifier("Steward",["Discipline","Delegation"])
	_expect(execution_after>execution_before,"advisor approval did not improve later office execution when burden was held equal")
	var support:=ConsequenceEngine.governance_metrics()
	_expect(support.has("council_support") and float(support.council_support)>0.0,"government metrics omitted aggregate council support")
	ConsequenceEngine.process_day({"traveling":false})
	_expect(GameState.simulation_metrics.has("governance_council_support"),"advisor reactions did not reach the daily government simulation metrics")

func _test_policy_lifecycle()->void:
	_reset_simulation(55555)
	var interpretation:=PronouncementInterpreter._local_interpretation("Ration food.")
	interpretation.policies[0]["days"]=7.0
	var order:Dictionary=AdvisorSystem.execute_pronouncement("Ration food.",interpretation)
	_expect(String(order.status)=="active","new standing policy was not marked active")
	GameState.elapsed_days=8.0
	AdvisorSystem.refresh_pronouncement_statuses()
	_expect(String(order.status)=="expired","elapsed standing policy was not marked expired")
	_expect(ConsequenceEngine.active_policies().is_empty(),"expired policy remained in the active ledger")
	_reset_simulation(55555)
	ConsequenceEngine.apply_policy("rationing",0.18,90.0,"context test")
	var active_context:Array[Dictionary]=[]
	for policy in ConsequenceEngine.active_policies(): active_context.append({"id":policy.id,"remaining_days":policy.remaining_days})
	var contextual:=PronouncementInterpreter._local_interpretation("End the current policy.",{"active_policies":active_context})
	_expect(contextual.policies.size()==1 and String(contextual.policies[0].id)=="rationing" and String(contextual.policies[0].action)=="repeal","single active policy could not be safely resolved from contextual repeal language")
	GameState.active_modifiers.clear()
	GameState.sovereign_orders.clear()
	for index in 405: GameState.active_modifiers.append({"id":"rationing","kind":"policy","until_day":-1.0,"ended_reason":"expired","source_order_id":"old_%d" % index})
	ConsequenceEngine.apply_policy("expanded_watch",0.18,90.0,"history bound test")
	_expect(GameState.active_modifiers.size()<=400,"inactive policy history grew beyond its bound")
	_expect(ConsequenceEngine.modifier_strength("expanded_watch")>0.0,"history pruning removed the active policy")

func _test_variable_level_ripple()->void:
	GameState.active_modifiers.clear()
	GameState.initialize_population_model()
	var baseline:Dictionary=FoodSystem._calculate_demand(false)
	ConsequenceEngine.apply_policy("rationing",0.20,90.0,"test")
	_expect(ConsequenceEngine.policy_effect("food_demand")<0.0,"catalog effects were not attached to a directly applied policy")
	var rationed:Dictionary=FoodSystem._calculate_demand(false)
	_expect(float(rationed.total)<float(baseline.total),"rationing modifier did not lower daily food demand")
	_expect(float(rationed.rationing)>0.0,"rationing cost was not exposed in the demand breakdown")
	ConsequenceEngine.repeal_policy("rationing","test repeal")
	var restored:Dictionary=FoodSystem._calculate_demand(false)
	_expect(is_equal_approx(float(restored.total),float(baseline.total)),"repealed rationing continued changing food demand")

func _test_daily_security_ripple()->void:
	_reset_simulation(97531)
	ConsequenceEngine.process_day({"traveling":false})
	var baseline_security:=float(GameState.simulation_metrics.get("security",0.0))
	_reset_simulation(97531)
	ConsequenceEngine.apply_policy("expanded_watch",0.20,90.0,"test watch")
	ConsequenceEngine.process_day({"traveling":false})
	var ordered_security:=float(GameState.simulation_metrics.get("security",0.0))
	_expect(ordered_security>baseline_security,"expanded watch did not raise the next-day security metric")

func _test_broader_government_ripples()->void:
	_reset_simulation(86420)
	ConsequenceEngine.process_day({"traveling":false})
	var baseline_knowledge:=float(GameState.simulation_metrics.get("knowledge",0.0))
	_reset_simulation(86420)
	ConsequenceEngine.apply_policy("directed_inquiry",0.20,180.0,"test inquiry")
	ConsequenceEngine.process_day({"traveling":false})
	_expect(float(GameState.simulation_metrics.get("knowledge",0.0))>baseline_knowledge,"directed inquiry did not raise the next-day knowledge metric")
	_reset_simulation(86420)
	ConsequenceEngine.process_day({"traveling":false})
	var baseline_logistics:=float(GameState.simulation_metrics.get("logistics",0.0))
	_reset_simulation(86420)
	ConsequenceEngine.apply_policy("route_priority",0.20,180.0,"test routes")
	ConsequenceEngine.process_day({"traveling":false})
	_expect(float(GameState.simulation_metrics.get("logistics",0.0))>baseline_logistics,"route priority did not raise the next-day logistics metric")

func _test_policy_observation_feedback()->void:
	_reset_simulation(112358)
	ConsequenceEngine.process_day({"traveling":false})
	var interpretation:=PronouncementInterpreter._local_interpretation("Improve routes.")
	var order:=AdvisorSystem.execute_pronouncement("Improve routes.",interpretation)
	for day in 6:
		GameState.elapsed_days+=1.0
		ConsequenceEngine.process_day({"traveling":false})
	AdvisorSystem.refresh_pronouncement_statuses()
	var observed:Dictionary=order.parameters.interpretation.policies[0].get("observation",{})
	_expect(not observed.is_empty() and "logistics" in String(observed.get("summary","")),"standing order did not retain a linked logistics observation")
	_expect(float(observed.get("days_elapsed",0.0))>=6.0,"policy observation did not track elapsed execution time")
	var observed_metrics:Array=observed.get("metrics",[])
	_expect(not observed_metrics.is_empty() and float((observed_metrics[0] as Dictionary).get("current",0.0))!=float((observed_metrics[0] as Dictionary).get("baseline",0.0)),"linked policy metric never advanced beyond its baseline")
	ConsequenceEngine.repeal_policy("route_priority","observation finalization test")
	AdvisorSystem.refresh_pronouncement_statuses()
	var record:Dictionary={}
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("source_order_id",""))==String(order.id) and String(modifier.get("id",""))=="route_priority": record=modifier; break
	var final_observation:=ConsequenceEngine.policy_observation(record)
	var final_current:=float((final_observation.get("metrics",[])[0] as Dictionary).get("current",0.0)) if not (final_observation.get("metrics",[]) as Array).is_empty() else -1.0
	GameState.elapsed_days+=30.0
	GameState.simulation_metrics["logistics"]=float(GameState.simulation_metrics.get("logistics",0.0))+0.25
	var retained_observation:=ConsequenceEngine.policy_observation(record)
	var retained_current:=float((retained_observation.get("metrics",[])[0] as Dictionary).get("current",0.0)) if not (retained_observation.get("metrics",[]) as Array).is_empty() else -2.0
	_expect(is_equal_approx(retained_current,final_current),"repealed policy observation drifted with unrelated later simulation changes")

func _test_policy_reversal_cost()->void:
	_reset_simulation(424242)
	ConsequenceEngine.apply_policy("expanded_watch",0.18,180.0,"stable watch")
	ConsequenceEngine.process_day({"traveling":false})
	var stable_labor:=float(GameState.simulation_metrics.get("labor_efficiency",0.0))
	var stable_cohesion:=float(GameState.simulation_metrics.get("cohesion",0.0))
	var stable_legitimacy:=float(GameState.simulation_metrics.get("legitimacy",0.0))
	_reset_simulation(424242)
	ConsequenceEngine.apply_policy("expanded_watch",0.18,180.0,"first watch")
	ConsequenceEngine.apply_policy("expanded_watch",0.18,180.0,"reversed watch")
	var burden:Dictionary=ConsequenceEngine.governance_metrics()
	_expect(int(burden.active_policy_count)==1,"policy reversal created duplicate standing policy")
	_expect(float(burden.policy_churn)>0.0 and float(burden.administrative_load)>0.0,"policy reversal created no governance burden")
	ConsequenceEngine.process_day({"traveling":false})
	_expect(float(GameState.simulation_metrics.get("labor_efficiency",0.0))<stable_labor,"reversal administration did not reduce effective labor")
	_expect(float(GameState.simulation_metrics.get("cohesion",0.0))<stable_cohesion,"policy churn did not reduce cohesion")
	_expect(float(GameState.simulation_metrics.get("legitimacy",0.0))<stable_legitimacy,"policy churn did not reduce legitimacy")

func _test_out_of_order_completion()->void:
	_reset_simulation(10101)
	var older:Dictionary=AdvisorSystem.begin_pronouncement("Expand the watch first.")
	var newer:Dictionary=AdvisorSystem.begin_pronouncement("Expand the watch instead.")
	_expect(int(newer.sequence)>int(older.sequence),"sovereign order sequence was not monotonic")
	var interpretation:=PronouncementInterpreter._local_interpretation("Expand the watch.")
	AdvisorSystem.execute_pronouncement("Expand the watch instead.",interpretation,newer)
	var strength_after_newer:=ConsequenceEngine.modifier_strength("expanded_watch")
	var churn_after_newer:=float(ConsequenceEngine.governance_metrics().policy_churn)
	AdvisorSystem.execute_pronouncement("Expand the watch first.",interpretation,older)
	_expect(String(older.status)=="stale" and String(newer.status)=="active","late older response did not reconcile as stale")
	_expect(is_equal_approx(ConsequenceEngine.modifier_strength("expanded_watch"),strength_after_newer),"late older response replaced the newer policy")
	_expect(is_equal_approx(float(ConsequenceEngine.governance_metrics().policy_churn),churn_after_newer),"stale response incorrectly created policy churn")
	var active:=ConsequenceEngine.active_policies()
	_expect(active.size()==1 and String(active[0].source_order_id)==String(newer.id),"active policy lost the newer source order")

func _reset_simulation(seed:int)->void:
	GameState.reset_for_new_world(seed)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	ConsequenceEngine.initialize()

func _test_restart_cancels_deferred_result()->void:
	stale_result_received=false
	PronouncementInterpreter.interpretation_completed.connect(_capture_stale_interpretation)
	PronouncementInterpreter.interpret("Ration food.",{})
	PronouncementInterpreter.reset_for_new_world()
	await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_stale_interpretation)
	_expect(not stale_result_received,"an old-world deferred interpretation survived campaign restart")

func _capture_stale_interpretation(_request_id:String,_result:Dictionary)->void:
	stale_result_received=true

func _test_async_ripple()->void:
	async_result={}
	PronouncementInterpreter.interpretation_completed.connect(_capture_interpretation)
	PronouncementInterpreter.interpret("Ration food and protect the land.",{})
	for frame in 4:
		if not async_result.is_empty(): break
		await get_tree().process_frame
	PronouncementInterpreter.interpretation_completed.disconnect(_capture_interpretation)
	_expect(not async_result.is_empty(),"offline interpretation did not complete asynchronously")
	if async_result.is_empty(): return
	for policy in async_result.policies:
		ConsequenceEngine.apply_policy(String(policy.id),float(policy.magnitude),float(policy.days),String(policy.ripple))
	_expect(ConsequenceEngine.modifier_strength("rationing")>0.0,"rationing did not ripple into active simulation modifiers")
	_expect(ConsequenceEngine.modifier_strength("conservation_order")>0.0,"conservation did not ripple into active simulation modifiers")

func _capture_interpretation(_request_id:String,result:Dictionary)->void:
	async_result=result

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
