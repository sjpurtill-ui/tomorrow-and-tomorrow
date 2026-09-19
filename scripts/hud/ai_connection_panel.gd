extends CanvasLayer
var key:LineEdit
var model:LineEdit
var endpoint:LineEdit
var status:Label
var card:PanelContainer
var shade:ColorRect
var remember:CheckBox
var pause=preload("res://scripts/hud/simulation_pause.gd").new()

func _ready()->void:
	layer=100
	pause.acquire(get_tree().current_scene)
	shade=ColorRect.new();shade.color=Color("071015d9");shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade)
	shade.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:queue_free())
	card=PanelContainer.new();shade.add_child(card)
	var style:=StyleBoxFlat.new();style.bg_color=Color("12242b");style.border_color=Color("768d8e");style.set_border_width_all(1);style.set_corner_radius_all(10);style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=18;style.content_margin_bottom=18;card.add_theme_stylebox_override("panel",style)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",12);card.add_child(root)
	var title:=Label.new();title.text="AI Connection";title.add_theme_font_size_override("font_size",24);root.add_child(title)
	preload("res://scripts/ai_connection_store.gd").ensure_loaded()
	var note:=Label.new();note.text="One reusable key for civics and leader conversations. Remember it securely on this Mac—never in campaign saves.";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(note)
	key=_field(root,"API key","");key.secret=true;key.placeholder_text="Leave blank to keep configured key" if PronouncementInterpreter.configuration_status().configured else "Paste your existing key once · never in chat";key.max_length=8192
	remember=CheckBox.new();remember.text="Remember on this Mac · Keychain";remember.disabled=not preload("res://scripts/ai_connection_store.gd").supported();remember.button_pressed=not remember.disabled;root.add_child(remember)
	model=_field(root,"Model",OS.get_environment("LEVIATHAN_AI_MODEL"))
	if model.text.is_empty():model.text=PronouncementInterpreter.DEFAULT_API_MODEL
	endpoint=_field(root,"Endpoint",OS.get_environment("LEVIATHAN_AI_ENDPOINT"))
	if endpoint.text.is_empty():endpoint.text="https://api.openai.com/v1/chat/completions"
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.text=PronouncementInterpreter.connection_problem();root.add_child(status)
	var actions:=HBoxContainer.new();root.add_child(actions)
	var use:=Button.new();use.text="Use connection";use.custom_minimum_size.y=40;actions.add_child(use);use.pressed.connect(_apply)
	var off:=Button.new();off.text="Turn AI off";actions.add_child(off);off.pressed.connect(func():PronouncementInterpreter.set_api_enabled(false);status.text=PronouncementInterpreter.connection_problem())
	var close:=Button.new();close.text="Close";actions.add_child(close);close.pressed.connect(func():queue_free())
	var forget:=Button.new();forget.text="Forget saved connection…";root.add_child(forget)
	forget.pressed.connect(func():
		var confirmation:=ConfirmationDialog.new();confirmation.theme=preload("res://scripts/hud/hud_tokens.gd").control_theme();confirmation.dialog_text="Remove this game's saved AI connection from Keychain and clear it from this session?";add_child(confirmation)
		confirmation.confirmed.connect(func():status.text=String(preload("res://scripts/ai_connection_store.gd").forget().get("message","Could not remove the saved connection. Unlock Keychain and try again."));confirmation.queue_free())
		confirmation.canceled.connect(confirmation.queue_free);confirmation.popup_centered())
	get_viewport().size_changed.connect(_fit);card.minimum_size_changed.connect(_fit.call_deferred);_fit.call_deferred()
func _field(root:Node,title:String,value:String)->LineEdit:
	var label:=Label.new();label.text=title;root.add_child(label)
	var field:=LineEdit.new();field.text=value;field.custom_minimum_size.y=36;root.add_child(field);return field
func _fit()->void:
	var extent:=get_viewport().get_visible_rect().size;shade.size=extent
	card.size=Vector2(minf(580,extent.x-40),0);card.position=(extent-card.size)*.5
func _apply()->void:
	var result:=PronouncementInterpreter.configure_connection(key.text,model.text,endpoint.text,remember.button_pressed)
	if not result.has("error"):key.clear()
	status.text=String(result.get("error",result.get("message","")));_fit.call_deferred()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:get_viewport().set_input_as_handled();queue_free()
func _exit_tree()->void:
	pause.release()
