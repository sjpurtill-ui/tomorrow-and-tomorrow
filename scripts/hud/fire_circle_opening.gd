extends Control
## The game opens at the fire circle. The Hearth Chief asks the god one
## question in their own voice, "What should our children say of us?", and
## the answer becomes the people's founding purpose (PeopleDirection). Four
## answers suited to the land are offered as icon cards with a few words each
## (the full sentence is the tooltip); the rest wait behind "Other answers…",
## and a god who is online may answer in their own words.
##
## The same scene returns at the first fire, when the Hearth Chief asks what the
## new home is called (mode "name"); the terrain wires that mode to its own
## naming commit, and the name may be left for later.
##
## Compatibility: `opening`, `ambition_buttons`, `selected_focus` and a page
## holding a "ConfirmFocus" button mirror the old direction screen for callers.

const Lines:=preload("res://scripts/fire_circle_voice.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const SERIF:="res://assets/fonts/cinzel/Cinzel.ttf"
const UI_FONT:="res://assets/fonts/battle/Barlow-Medium.ttf"

var mode:="purpose"
var opening:=true
var person:Dictionary={}
var ambition_buttons:Array[Button]=[]
var pages:Array[Control]=[]
var selected_focus:=""
var typed_words:=""
var speech:Label
var echo:Label
var answers:VBoxContainer
var more_button:Button
var more_grid:GridContainer
var typed:LineEdit
var confirm:Button
var name_input:LineEdit
var name_confirm:Button
var later_button:Button
var suggestions:HBoxContainer
var card:PanelContainer
var backdrop:Control

func _ready()->void:
	name="FireCircleOpening" if mode=="purpose" else "FireCircleNaming"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	theme=Theme.new()
	if ResourceLoader.exists(UI_FONT): theme.default_font=load(UI_FONT)
	T.add_tooltip_style(theme)
	person=Lines.hearth_chief()
	var night:=ColorRect.new();night.color=Color("0c0f10");night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);night.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(night)
	backdrop=Backdrop.new();backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	backdrop.configure(0,true)
	var shade:=ColorRect.new();shade.color=Color(0.02,0.02,0.02,0.35);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shade)
	var place:=_label("THE FIRE CIRCLE · DUSK" if mode=="purpose" else "THE FIRST FIRE",13,Color("d9b56a"))
	place.position=Vector2(18,14);add_child(place)
	var frame:=MarginContainer.new();frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for side in ["left","right"]: frame.add_theme_constant_override("margin_"+side,16)
	frame.add_theme_constant_override("margin_top",48);frame.add_theme_constant_override("margin_bottom",24);add_child(frame)
	var stack:=VBoxContainer.new();stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(stack)
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(spacer)
	var centre:=HBoxContainer.new();centre.alignment=BoxContainer.ALIGNMENT_CENTER;centre.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(centre)
	card=PanelContainer.new();card.add_theme_stylebox_override("panel",_box(Color(0.06,0.05,0.04,0.94),Color("8a6d3b"),20));centre.add_child(card)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",18);card.add_child(row)
	var left:=VBoxContainer.new();left.add_theme_constant_override("separation",6);row.add_child(left)
	if not person.is_empty(): left.add_child(Portrait.picture(person,112,140))
	var who:=_label(String(person.get("name","The eldest at the fire")),15,Color("ecdfc4"));who.custom_minimum_size.x=112;who.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;left.add_child(who)
	left.add_child(_label(String(person.get("office_title","Hearth Chief")),12,Color("a89a7c")))
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10);row.add_child(column)
	pages.append(column)
	speech=_label("",20,Color("f1e6cc"));speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if ResourceLoader.exists(SERIF): speech.add_theme_font_override("font",load(SERIF))
	column.add_child(speech)
	echo=_label("",15,Color("d9b56a"));echo.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;echo.visible=false;column.add_child(echo)
	if mode=="purpose": _build_purpose(column)
	else: _build_name(column)
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()

func _build_purpose(column:VBoxContainer)->void:
	speech.text="“%s”" % Lines.say(person,"ask")
	answers=VBoxContainer.new();answers.add_theme_constant_override("separation",8);column.add_child(answers)
	var profile:=PlanetEnvironment.profile_at(CivilizationSystem.player_world_origin)
	var first:=Lines.offered(profile,int(GameState.world_seed))
	# Four cards suited to the land; every other answer waits behind one toggle.
	var offered_row:=HBoxContainer.new();offered_row.add_theme_constant_override("separation",10);answers.add_child(offered_row)
	for id in first: _answer(offered_row,id,true,false)
	more_button=Button.new();more_button.name="OtherAnswers";more_button.text="Other answers…";more_button.flat=true;more_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	more_button.add_theme_color_override("font_color",Color("a89a7c"));more_button.add_theme_font_size_override("font_size",14)
	more_button.pressed.connect(func()->void:_show_more(not more_grid.visible))
	answers.add_child(more_button)
	more_grid=GridContainer.new();more_grid.name="MoreAnswers";more_grid.columns=5;more_grid.visible=false
	more_grid.add_theme_constant_override("h_separation",8);more_grid.add_theme_constant_override("v_separation",8);answers.add_child(more_grid)
	for id in Lines.others(first): _answer(more_grid,id,false,true)
	if _online():
		typed=LineEdit.new();typed.name="OwnWords";typed.placeholder_text="Or say it in your own words…";typed.max_length=240;typed.custom_minimum_size.y=32
		typed.add_theme_font_size_override("font_size",14)
		typed.text_submitted.connect(func(text:String)->void:
			if text.strip_edges()=="": return
			typed_words=text.strip_edges()
			_select(Lines.interpret(typed_words,first[0])))
		answers.add_child(typed)
	confirm=Button.new();confirm.name="ConfirmFocus";confirm.text="Answer them";confirm.disabled=true;confirm.custom_minimum_size=Vector2(0,44)
	confirm.add_theme_stylebox_override("normal",_box(Color("c7a55f"),Color("c7a55f"),8));confirm.add_theme_stylebox_override("disabled",_box(Color("3a3226"),Color("5c4a2c"),8));confirm.add_theme_color_override("font_color",Color("112126"));confirm.add_theme_font_size_override("font_size",16)
	confirm.add_theme_color_override("font_disabled_color",Color("6a6150"))
	confirm.pressed.connect(_begin)
	column.add_child(confirm)

func _show_more(open:bool)->void:
	more_grid.visible=open
	for button in ambition_buttons:
		if bool(button.get_meta("more",false)): button.visible=open or String(button.get_meta("ambition"))==selected_focus
	more_button.text="Fewer answers" if open else "Other answers…"
	_layout.call_deferred()

func _answer(parent:Container,id:String,shown:bool,small:bool)->void:
	## One answer as a card: an icon and a few words. The full sentence is the
	## tooltip, and is what the god is heard to say once it is chosen.
	var button:=Button.new();button.name="Answer_"+id
	button.text=String(Lines.LABELS.get(id,PeopleDirection.AMBITIONS[id].name))
	button.icon=Lines.icon(id,Color("d9b56a"),36 if small else 48)
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
	button.expand_icon=false;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size=Vector2(0,72) if small else Vector2(0,104)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",13 if small else 16)
	button.add_theme_constant_override("icon_max_width",36 if small else 48)
	button.set_meta("ambition",id);button.set_meta("more",small);button.visible=shown
	for kind in ["normal","hover","pressed","focus"]:
		button.add_theme_stylebox_override(kind,_box(Color(1,1,1,0.04) if kind=="normal" else Color(0.85,0.7,0.4,0.16),Color("5c4a2c") if kind=="normal" else Color("c7a55f"),8))
	button.add_theme_color_override("font_color",Color("e6dcc4"))
	button.tooltip_text=String(Lines.ANSWERS.get(id,PeopleDirection.AMBITIONS[id].vision))
	button.pressed.connect(func()->void:typed_words="";_select(id))
	parent.add_child(button);ambition_buttons.append(button)

func _select(id:String)->void:
	if not PeopleDirection.AMBITIONS.has(id): return
	selected_focus=id
	for button in ambition_buttons:
		var mine:=String(button.get_meta("ambition"))==id
		if mine and bool(button.get_meta("more",false)) and not more_grid.visible: _show_more(true)
		button.add_theme_color_override("font_color",Color("ffe3a3") if mine else Color("e6dcc4"))
		button.add_theme_stylebox_override("normal",_box(Color(0.85,0.7,0.4,0.2) if mine else Color(1,1,1,0.04),Color("c7a55f") if mine else Color("5c4a2c"),8))
	var said:=typed_words if typed_words!="" else String(Lines.ANSWERS.get(id,""))
	echo.text="You: “%s”\n%s: “%s”" % [said,String(person.get("name","The Hearth Chief")).get_slice(" ",0),Lines.say(person,"reply")]
	echo.visible=true
	confirm.disabled=false
	confirm.text="So it will be · set out"
	_layout.call_deferred()

func _begin()->void:
	if selected_focus=="": return
	var result:Dictionary=PeopleDirection.choose(selected_focus)
	if result.has("error"): echo.text=String(result.error);return
	if typed_words!="": PeopleDirection._log(int(GameState.elapsed_days),"At the fire the god said: “%s”" % typed_words.substr(0,200))
	queue_free()

func _build_name(column:VBoxContainer)->void:
	speech.text="“%s”" % Lines.say(person,"name")
	name_input=LineEdit.new();name_input.name="SettlementName";name_input.placeholder_text="Name the place…";name_input.max_length=32;name_input.custom_minimum_size.y=46
	name_input.add_theme_font_size_override("font_size",18)
	column.add_child(name_input)
	suggestions=HBoxContainer.new();suggestions.add_theme_constant_override("separation",8);column.add_child(suggestions)
	var hint:=_label("Heard at the fire:",13,Color("a89a7c"));suggestions.add_child(hint)
	for suggestion in Lines.name_suggestions(PlanetEnvironment.profile_at(CivilizationSystem.player_world_origin),int(GameState.world_seed)):
		var chip:=Button.new();chip.text=suggestion;chip.flat=true;chip.add_theme_color_override("font_color",Color("d9b56a"))
		chip.pressed.connect(func()->void:
			name_input.text=suggestion;name_input.text_changed.emit(suggestion);name_input.grab_focus())
		suggestions.add_child(chip)
	var footer:=HBoxContainer.new();footer.alignment=BoxContainer.ALIGNMENT_END;footer.add_theme_constant_override("separation",10);column.add_child(footer)
	later_button=Button.new();later_button.text="Let the name come later";later_button.custom_minimum_size=Vector2(0,42);later_button.flat=true
	later_button.add_theme_color_override("font_color",Color("a89a7c"));footer.add_child(later_button)
	name_confirm=Button.new();name_confirm.text="Name it";name_confirm.custom_minimum_size=Vector2(150,42);name_confirm.disabled=true
	name_confirm.add_theme_stylebox_override("normal",_box(Color("c7a55f"),Color("c7a55f"),8));name_confirm.add_theme_stylebox_override("disabled",_box(Color("3a3226"),Color("5c4a2c"),8));name_confirm.add_theme_color_override("font_color",Color("112126"))
	name_confirm.add_theme_color_override("font_disabled_color",Color("6a6150"))
	footer.add_child(name_confirm)
	name_input.grab_focus.call_deferred()

func named_line(chosen:String)->String:
	return Lines.say(person,"named",chosen)

func _layout()->void:
	if not is_instance_valid(card): return
	var extent:=get_viewport().get_visible_rect().size
	card.custom_minimum_size=Vector2(minf(880.0,extent.x-32.0),0)

func _box(bg:Color,border:Color,pad:float)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1)
	style.set_corner_radius_all(5);style.set_content_margin_all(pad)
	return style

func _label(text:String,size:int,color:Color)->Label:
	var label:=Label.new();label.text=text
	label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color)
	return label

func _online()->bool:
	if not is_instance_valid(PronouncementInterpreter) or not PronouncementInterpreter.has_method("configuration_status"): return false
	return bool((PronouncementInterpreter.configuration_status() as Dictionary).get("configured",false))
