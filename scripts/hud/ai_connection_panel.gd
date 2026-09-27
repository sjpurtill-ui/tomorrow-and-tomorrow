extends CanvasLayer
## The AI connection sheet: paper and ink. The everyday choice (how people
## talk) sits on top; the key, model, service address and the conversation
## export are developer settings kept behind one "Advanced" disclosure.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const P:=preload("res://scripts/hud/paper_sheet.gd")
const Store:=preload("res://scripts/ai_connection_store.gd")
var key:LineEdit
var model:LineEdit
var endpoint:LineEdit
var status:Label
var card:PanelContainer
var shade:ColorRect
var remember:CheckBox
var advanced:VBoxContainer
var advanced_toggle:Button
var pause=preload("res://scripts/hud/simulation_pause.gd").new()

func _ready()->void:
	layer=100
	pause.acquire(get_tree().current_scene)
	shade=ColorRect.new();shade.color=T.SCRIM;shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade)
	shade.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:queue_free())
	card=PanelContainer.new();card.theme=T.control_theme();card.add_theme_stylebox_override("panel",P.sheet_style(20));shade.add_child(card)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",12);card.add_child(root)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",12);root.add_child(head)
	var title:=P.label(head,"AI connection","title",T.INK,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var close:=P.button(head,"Close",func():queue_free());close.name="Close";close.size_flags_horizontal=Control.SIZE_SHRINK_END;close.custom_minimum_size=Vector2(96,38)
	P.rule(root)
	Store.ensure_loaded()
	P.label(root,"With a connection you can type anything to your people and their leaders. Without one, you choose from prepared replies. Your key stays on this computer and is never written into a saved game.","body",T.BODY)
	status=P.label(root,"","body",T.INK)
	_show_status(PronouncementInterpreter.connection_problem())
	# How people talk: the one everyday choice.
	P.kicker(root,"How people talk")
	var mode_row:=HBoxContainer.new();mode_row.add_theme_constant_override("separation",8);root.add_child(mode_row)
	var modes:=OptionButton.new();modes.name="AiModeSelector";modes.size_flags_horizontal=Control.SIZE_EXPAND_FILL;modes.custom_minimum_size.y=38;T.text(modes,"small",T.INK);mode_row.add_child(modes)
	var ai_mode:=preload("res://scripts/ai_mode.gd")
	for index in ai_mode.MODES.size():
		modes.add_item(String(ai_mode.LABELS[ai_mode.MODES[index]]),index)
		if ai_mode.MODES[index]==ai_mode.mode():modes.select(index)
	modes.item_selected.connect(func(index:int):ai_mode.set_mode(ai_mode.MODES[index]);status.text="People now talk this way: %s." % ai_mode.label())
	var off:=P.button(mode_row,"Turn AI off",func():PronouncementInterpreter.set_api_enabled(false);_show_status(PronouncementInterpreter.connection_problem()))
	off.size_flags_horizontal=Control.SIZE_SHRINK_END;off.custom_minimum_size.x=140
	# Advanced: the developer settings, closed by default.
	advanced_toggle=P.button(root,"Show advanced settings",_toggle_advanced);advanced_toggle.name="AdvancedToggle"
	advanced=VBoxContainer.new();advanced.name="Advanced";advanced.add_theme_constant_override("separation",8);advanced.visible=false;root.add_child(advanced)
	key=_field(advanced,"API key","");key.secret=true;key.placeholder_text="Leave blank to keep the key you already set" if PronouncementInterpreter.configuration_status().configured else "Paste your key here";key.max_length=8192
	remember=CheckBox.new();remember.text="Remember the key on this computer";T.text(remember,"small",T.BODY);remember.disabled=not Store.supported();remember.button_pressed=not remember.disabled
	if remember.disabled:remember.tooltip_text="This build cannot store the key safely, so it lasts until you quit."
	advanced.add_child(remember)
	model=_field(advanced,"Model",OS.get_environment("LEVIATHAN_AI_MODEL"))
	if model.text.is_empty():model.text=PronouncementInterpreter.DEFAULT_API_MODEL
	endpoint=_field(advanced,"Service address",OS.get_environment("LEVIATHAN_AI_ENDPOINT"))
	if endpoint.text.is_empty():endpoint.text="https://api.openai.com/v1/chat/completions"
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",8);advanced.add_child(actions)
	P.button(actions,"Use this connection",_apply,true)
	var export_button:=P.button(actions,"Export conversations",Callable());export_button.name="ExportInteractions"
	export_button.pressed.connect(func():
		var exported:Dictionary=preload("res://scripts/interaction_store.gd").export_bundle()
		status.text="Saved %d conversations to %s" % [int(exported.get("count",0)),ProjectSettings.globalize_path(String(exported.get("path","")))] if bool(exported.get("ok",false)) else "Could not export the conversations.";_fit.call_deferred())
	P.button(advanced,"Forget the saved connection",func():
		var confirmation:=ConfirmationDialog.new();confirmation.theme=T.control_theme();confirmation.dialog_text="Remove this game's saved AI connection from this computer and stop using it now?";confirmation.ok_button_text="Forget it";confirmation.cancel_button_text="Keep it";add_child(confirmation)
		confirmation.confirmed.connect(func():_show_status(String(Store.forget().get("message","Could not remove the saved connection. Try again.")));confirmation.queue_free())
		confirmation.canceled.connect(confirmation.queue_free);confirmation.popup_centered())
	get_viewport().size_changed.connect(_fit);card.minimum_size_changed.connect(_fit.call_deferred);_fit.call_deferred()

func _toggle_advanced()->void:
	advanced.visible=not advanced.visible
	advanced_toggle.text="Hide advanced settings" if advanced.visible else "Show advanced settings"
	_fit.call_deferred()

## Status words for any platform ("on this Mac" becomes "on this computer").
func _show_status(text:String)->void:
	var plain:=text.replace("on this Mac","on this computer").replace("macOS Keychain","the saved key store").replace("Keychain","the saved key store").replace("Menu → AI Connection","this sheet")
	status.text=plain if plain!="" else "Connected. People can answer in their own words."

func _field(root:Node,title:String,value:String)->LineEdit:
	P.label(root,title,"small",T.INK_MUTED,false)
	var field:=LineEdit.new();field.text=value;field.custom_minimum_size.y=36;T.text(field,"small",T.INK);root.add_child(field);return field
func _fit()->void:
	var extent:=get_viewport().get_visible_rect().size;shade.size=extent
	card.size=Vector2(minf(600,extent.x-40),0);card.position=(extent-card.size)*.5
func _apply()->void:
	var result:=PronouncementInterpreter.configure_connection(key.text,model.text,endpoint.text,remember.button_pressed)
	if not result.has("error"):key.clear()
	_show_status(String(result.get("error",result.get("message",""))));_fit.call_deferred()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:get_viewport().set_input_as_handled();queue_free()
func _exit_tree()->void:
	pause.release()
