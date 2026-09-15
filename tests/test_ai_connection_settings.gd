extends GdUnitTestSuite
const ENV:=["LEVIATHAN_AI_API_KEY","OPENAI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL"]
var previous:Dictionary={}
var enabled:=true
const Store=preload("res://scripts/ai_connection_store.gd")
var vault:Dictionary={}
func before_test()->void:
	Store.loaded=true;Store.issue="";Store.backend=Callable();vault={}
	enabled=GameState.civic_api_enabled
	for key:String in ENV:
		previous[key]={"exists":OS.has_environment(key),"value":OS.get_environment(key)};OS.unset_environment(key)
	GameState.civic_api_enabled=true
func after_test()->void:
	Store.loaded=false;Store.issue="";Store.backend=Callable()
	for key:String in ENV:
		if previous[key].exists:OS.set_environment(key,previous[key].value)
		else:OS.unset_environment(key)
	GameState.civic_api_enabled=enabled

func fake_store(action:String,connection:Dictionary)->Dictionary:
	if action=="save":vault=connection.duplicate(true);return {"ok":true}
	if action=="delete":vault={};return {"ok":true}
	return {"ok":true,"connection":vault.duplicate(true)}

func test_remember_load_and_forget_keep_credentials_out_of_diagnostics_and_saves()->void:
	Store.backend=fake_store
	assert_bool(PronouncementInterpreter.configure_connection("dummy-persistent-key","test-model","",true).get("ok",false)).is_true()
	for name:String in ENV:OS.unset_environment(name)
	Store.loaded=false
	assert_bool(PronouncementInterpreter.configuration_status().configured).is_true()
	assert_str(PronouncementInterpreter._api_config().api_key).is_equal("dummy-persistent-key")
	assert_str(PronouncementInterpreter._api_config().model).is_equal("test-model")
	assert_str(JSON.stringify(PronouncementInterpreter.configuration_status())).not_contains("dummy-persistent-key")
	var reflected:=SaveSystem._capture_reflected(PronouncementInterpreter,SaveSystem.REFLECT_SKIP.PronouncementInterpreter)
	assert_str(var_to_str(reflected)).not_contains("dummy-persistent-key")
	assert_bool(Store.forget().get("ok",false)).is_true()
	assert_dict(vault).is_empty()
	assert_dict(PronouncementInterpreter._api_config()).is_empty()

func test_keychain_failure_is_not_reported_as_saved_and_does_not_change_connection()->void:
	Store.backend=func(_action:String,_connection:Dictionary)->Dictionary:return {"error":"Keychain locked"}
	assert_str(PronouncementInterpreter.configure_connection("dummy-key","model","",true).get("error","")).is_equal("Keychain locked")
	assert_bool(OS.has_environment("LEVIATHAN_AI_API_KEY")).is_false()

func test_saved_key_is_not_sent_to_an_overridden_endpoint()->void:
	Store.backend=fake_store;vault={"key":"dummy-key","endpoint":"https://api.openai.com/v1/chat/completions","model":"test"}
	OS.set_environment("LEVIATHAN_AI_ENDPOINT","https://example.com/v1/chat/completions")
	Store.loaded=false
	assert_dict(PronouncementInterpreter._api_config()).is_empty()
	assert_str(Store.issue).contains("differs")
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
