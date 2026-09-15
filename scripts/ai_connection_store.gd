extends RefCounted
## Device credentials are deliberately outside all reflected campaign state.
static var loaded:=false
static var issue:=""
static var backend:Callable

static func helper_path()->String:
	if OS.has_feature("editor"):return ProjectSettings.globalize_path("res://artifacts/native/KeychainBridge")
	return OS.get_executable_path().get_base_dir().path_join("../Helpers/KeychainBridge").simplify_path()

static func supported()->bool:
	return backend.is_valid() or (DisplayServer.get_name()!="headless" and OS.get_name()=="macOS" and FileAccess.file_exists(helper_path()))

static func call_store(action:String,connection:Dictionary={})->Dictionary:
	if backend.is_valid():return backend.call(action,connection)
	if not supported():return {"error":"Secure storage is unavailable in this build. Use a session key or launch the Mac release."}
	var process:=OS.execute_with_pipe(helper_path(),PackedStringArray([action]),true)
	if process.is_empty():return {"error":"Could not open macOS Keychain storage."}
	var pipe:FileAccess=process.stdio
	if action=="save":pipe.store_line(JSON.stringify(connection));pipe.flush()
	var parser:=JSON.new()
	if parser.parse(pipe.get_line())!=OK:return {"error":"Keychain did not respond. Unlock your login keychain and try again."}
	var result:Dictionary=parser.data if parser.data is Dictionary else {}
	if not bool(result.get("ok",false)) and int(result.get("code",0))!=-25300:
		return {"error":"Keychain access failed (code %d). Unlock your login keychain and try again; no key was saved." % int(result.get("code",0))}
	return result

static func ensure_loaded()->void:
	if loaded:return
	loaded=true
	if not OS.get_environment("LEVIATHAN_AI_API_KEY").is_empty() or not OS.get_environment("OPENAI_API_KEY").is_empty():return
	if not supported():return
	var result:=call_store("read")
	if result.has("error"):issue=String(result.error);return
	var connection:Dictionary=result.get("connection",{})
	if connection.is_empty():return
	var endpoint:=String(connection.get("endpoint",""))
	var override_endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT")
	if not override_endpoint.is_empty() and override_endpoint!=endpoint:
		issue="The launch endpoint differs from the saved connection. Configure its key explicitly.";return
	for pair in [["key","LEVIATHAN_AI_API_KEY"],["model","LEVIATHAN_AI_MODEL"],["endpoint","LEVIATHAN_AI_ENDPOINT"]]:
		OS.set_environment(pair[1],String(connection.get(pair[0],"")))

static func forget()->Dictionary:
	var result:=call_store("delete")
	if result.has("error"):return result
	loaded=true;issue=""
	for name:String in ["LEVIATHAN_AI_API_KEY","OPENAI_API_KEY"]:OS.unset_environment(name)
	return {"ok":true,"message":"Saved connection removed from Keychain and this game session."}
