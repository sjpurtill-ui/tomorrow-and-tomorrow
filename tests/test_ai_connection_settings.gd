extends GdUnitTestSuite
const ENV:=["LEVIATHAN_AI_API_KEY","OPENAI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL"]
var previous:Dictionary={}
var enabled:=true
func before_test()->void:
	enabled=GameState.civic_api_enabled
	for key:String in ENV:
		previous[key]={"exists":OS.has_environment(key),"value":OS.get_environment(key)};OS.unset_environment(key)
	GameState.civic_api_enabled=true
func after_test()->void:
	for key:String in ENV:
		if previous[key].exists:OS.set_environment(key,previous[key].value)
		else:OS.unset_environment(key)
	GameState.civic_api_enabled=enabled
func test_missing_local_key_is_not_reported_as_a_service_outage()->void:
	assert_str(PronouncementInterpreter.connection_problem()).contains("No API key")
	assert_array(PronouncementInterpreter.configuration_status().missing).has_size(1)
	assert_dict(PronouncementInterpreter._api_config()).is_empty()
func test_session_setup_redacts_key_and_retains_it_for_model_changes()->void:
	var secret:="test-session-only-value"
	assert_bool(PronouncementInterpreter.configure_connection(secret,"","").has("ok")).is_true()
	assert_bool(PronouncementInterpreter.configuration_status().configured).is_true()
	assert_str(JSON.stringify(PronouncementInterpreter.configuration_status())).not_contains(secret)
	assert_str(PronouncementInterpreter.connection_problem()).is_empty()
	assert_bool(PronouncementInterpreter.configure_connection("","chosen-model","").has("ok")).is_true()
	assert_str(String(PronouncementInterpreter._api_config().api_key)).is_equal(secret)
func test_invalid_connection_does_not_mutate_session()->void:
	assert_bool(PronouncementInterpreter.configure_connection("test-key","model","http://example.com/v1").has("error")).is_true()
	assert_bool(OS.has_environment("LEVIATHAN_AI_API_KEY")).is_false()
	assert_bool(PronouncementInterpreter.configure_connection("bad\nkey","model","").has("error")).is_true()
func test_service_failures_explain_the_actual_kind_of_failure()->void:
	assert_str(PronouncementInterpreter.connection_response_problem(401,HTTPRequest.RESULT_SUCCESS)).contains("API key")
	assert_str(PronouncementInterpreter.connection_response_problem(429,HTTPRequest.RESULT_SUCCESS)).contains("limit")
	assert_str(PronouncementInterpreter.connection_response_problem(503,HTTPRequest.RESULT_SUCCESS)).contains("server error")
