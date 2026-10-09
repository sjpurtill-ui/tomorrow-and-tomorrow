class_name AiWireTest
extends GdUnitTestSuite
## The wire to the model (scripts/ai_wire.gd): a chat request becomes an
## Anthropic Messages request for a Claude model, and the reply comes back in
## the chat shape every caller reads.

const Wire:=preload("res://scripts/ai_wire.gd")


func _chat(schema:=true)->Dictionary:
	var payload:={"model":"claude-haiku-5-5","max_completion_tokens":900,"reasoning_effort":"low","prompt_cache_key":"court","temperature":0.2,
		"messages":[{"role":"system","content":"You read orders."},{"role":"user","content":"Raise ten levies."}]}
	if schema:
		payload["response_format"]={"type":"json_schema","json_schema":{"name":"r","strict":true,"schema":{"type":"object","additionalProperties":false,
			"required":["kind","count"],"properties":{"type":{"type":"string","enum":["none","person"]},"kind":{"type":"string","enum":["order","speech"]},"count":{"type":"integer","minimum":0,"maximum":100},
			"who":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","maxLength":40}}},"maxItems":5}}}}}
	return payload


func test_only_claude_models_take_the_anthropic_road()->void:
	assert_bool(Wire.is_anthropic("claude-haiku-5-5")).is_true()
	assert_bool(Wire.is_anthropic("gpt-6-luna")).is_false()


func test_a_chat_request_becomes_a_messages_request()->void:
	var out:=Wire.to_messages_request(_chat(),"claude-haiku-5-5")
	assert_str(String(out.model)).is_equal("claude-haiku-5-5")
	assert_str(String(out.system)).is_equal("You read orders.")
	assert_array(out.messages as Array).has_size(1)
	assert_str(String((out.messages[0] as Dictionary).role)).is_equal("user")
	assert_bool(out.has("temperature") or out.has("prompt_cache_key") or out.has("reasoning_effort") or out.has("response_format")).is_false()
	assert_str(String(out.output_config.effort)).is_equal("low")
	assert_dict(out.thinking as Dictionary).is_equal({"type":"adaptive"})
	# The answer's cap plus room for thinking.
	assert_int(int(out.max_tokens)).is_equal(900+int(Wire.THINKING_ROOM.low))
	var schema:Dictionary=out.output_config.format.schema
	assert_str(String(out.output_config.format.type)).is_equal("json_schema")
	assert_bool((schema.properties.count as Dictionary).has("minimum")).is_false()
	assert_bool((schema.properties.who as Dictionary).has("maxItems")).is_false()
	var item:Dictionary=schema.properties.who.items
	assert_bool(bool(item.additionalProperties)).is_false()
	assert_bool((item.properties.id as Dictionary).has("maxLength")).is_false()
	assert_array(schema.properties.kind.enum as Array).is_equal(["order","speech"])
	# A field named "type" stays a field, not the schema's own type.
	assert_array(schema.properties.type.enum as Array).is_equal(["none","person"])
	assert_bool((schema.properties as Dictionary).has("additionalProperties")).is_false()


func test_turns_alternate_and_never_end_on_the_model()->void:
	var payload:={"model":"claude-haiku-5-5","messages":[{"role":"system","content":"a"},{"role":"system","content":"b"},
		{"role":"user","content":"one"},{"role":"user","content":[{"type":"text","text":"two"}]},{"role":"assistant","content":"reply"}]}
	var out:=Wire.to_messages_request(payload,"claude-haiku-5-5")
	assert_str(String(out.system)).is_equal("a\n\nb")
	var roles:=(out.messages as Array).map(func(m:Dictionary)->String:return String(m.role))
	assert_array(roles).is_equal(["user","assistant","user"])
	assert_str(String((out.messages[0] as Dictionary).content)).is_equal("one\n\ntwo")


func test_a_messages_reply_reads_as_a_chat_reply()->void:
	var reply:={"id":"msg_1","type":"message","model":"claude-haiku-5-5","stop_reason":"end_turn",
		"content":[{"type":"thinking","thinking":"","signature":"x"},{"type":"text","text":"{\"kind\":\"order\"}"}],
		"usage":{"input_tokens":1200,"output_tokens":80,"cache_read_input_tokens":300}}
	var chat:Dictionary=JSON.parse_string(Wire.to_chat_reply(JSON.stringify(reply).to_utf8_buffer(),200).get_string_from_utf8())
	assert_str(String(chat.choices[0].message.content)).is_equal("{\"kind\":\"order\"}")
	assert_str(String(chat.choices[0].finish_reason)).is_equal("stop")
	assert_int(int(chat.usage.prompt_tokens)).is_equal(1500)
	assert_int(int(chat.usage.completion_tokens)).is_equal(80)


func test_cut_off_refused_and_failed_replies_read_as_such()->void:
	var cut:Dictionary=JSON.parse_string(Wire.to_chat_reply(JSON.stringify({"type":"message","stop_reason":"max_tokens","content":[{"type":"text","text":"{\"ki"}]}).to_utf8_buffer(),200).get_string_from_utf8())
	assert_str(String(cut.choices[0].finish_reason)).is_equal("length")
	var refused:Dictionary=JSON.parse_string(Wire.to_chat_reply(JSON.stringify({"type":"message","stop_reason":"refusal","content":[{"type":"text","text":"no"}]}).to_utf8_buffer(),200).get_string_from_utf8())
	assert_str(String(refused.choices[0].finish_reason)).is_equal("content_filter")
	assert_str(String(refused.choices[0].message.content)).is_empty()
	var failed:Dictionary=JSON.parse_string(Wire.to_chat_reply(JSON.stringify({"type":"error","error":{"type":"invalid_request_error","message":"bad schema"}}).to_utf8_buffer(),400).get_string_from_utf8())
	assert_str(String(failed.error.message)).is_equal("bad schema")


func test_fenced_json_loses_its_fence_when_json_was_asked()->void:
	var reply:={"type":"message","stop_reason":"end_turn","content":[{"type":"text","text":"```json\n{\"a\":1}\n```"}]}
	var chat:Dictionary=JSON.parse_string(Wire.to_chat_reply(JSON.stringify(reply).to_utf8_buffer(),200,true).get_string_from_utf8())
	assert_str(String(chat.choices[0].message.content)).is_equal("{\"a\":1}")


func test_the_reader_may_use_another_service_than_the_voice()->void:
	var had:=OS.get_environment("ANTHROPIC_API_KEY")
	OS.set_environment("ANTHROPIC_API_KEY","sk-ant-test")
	var voice:={"endpoint":"https://api.openai.com/v1/chat/completions","api_key":"sk-proj-x","model":"gpt-6-luna","structured_output":true}
	var reader:=Wire.config_for_model(voice,"claude-haiku-5-5")
	assert_str(String(reader.endpoint)).is_equal(Wire.ANTHROPIC_ENDPOINT)
	assert_str(String(reader.api_key)).is_equal("sk-ant-test")
	assert_str(String(reader.provider)).is_equal("anthropic")
	OS.set_environment("ANTHROPIC_API_KEY",had)
