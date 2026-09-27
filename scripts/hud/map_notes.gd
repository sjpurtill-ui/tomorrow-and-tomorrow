extends RefCounted
## THE MAP'S SMALL CARDS: map help, word from the road and the first-contact
## alert. Paper and ink, 12 px or larger, sentence case,
## and only verbs for controls that exist. Every talk button opens the court.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")

# ------------------------------------------------------------- map help

## What map help says, for the situation on the map.
static func help_words(site_committed:bool,targeting:bool,convoy_active:bool)->Dictionary:
	if targeting:
		return {"title":"Choose land for the new settlement",
			"body":"Move the pointer over the map. Green ground can be settled; red cannot.\nClick to see who would go, what it costs and how long it takes. Right-click or press Esc to stop choosing."}
	if not site_committed:
		return {"title":"Find a home",
			"body":"Left-click land to inspect its ground and water on the card at the right.\nRight-click land to move the travellers there. When a place looks right, press Review founding site on the toolbar."}
	if convoy_active:
		return {"title":"Settlers on the road",
			"body":"The settler caravan is travelling; its leader chooses the camps.\nPress Show on map on the caravan card to follow it."}
	return {"title":"Using the map",
		"body":"Drag with the middle mouse button, press W A S D, or slide two fingers to move. Scroll or pinch to zoom.\nClick a city for details; double-click to move closer. Click the map to close cards and this note."}

## Builds the help button and card on `layer`. Returns their nodes.
static func build_help(layer:CanvasLayer,view:Vector2,on_toggle:Callable,on_close:Callable)->Dictionary:
	var button:=Kit.button(null,"Map help",false,on_toggle,"How to move the map, and what to do next")
	button.name="MapHelpButton"
	button.position=Vector2(T.RAIL_WIDTH+16.0,view.y-130.0)
	button.size=Vector2(112,34)
	layer.add_child(button)
	var panel:=Kit.panel(T.TEAL,14.0)
	panel.name="MapFirstUseHelp"
	panel.position=Vector2(T.RAIL_WIDTH+16.0,view.y-262.0)
	panel.custom_minimum_size=Vector2(420,0)
	panel.size=Vector2(420,120)
	panel.z_index=45
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	panel.add_child(column)
	var header:=HBoxContainer.new()
	column.add_child(header)
	var title:=Kit.label(header,"","heading",Color(0,0,0,0),false)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var close:=Kit.quiet_button(header,"Close",on_close,"Close this note, or click the map. Map help opens it again.")
	close.custom_minimum_size=Vector2(64,28)
	var body:=Kit.label(column,"","body")
	body.custom_minimum_size.x=390
	layer.add_child(panel)
	return {"button":button,"panel":panel,"title":title,"body":body}

## Keeps the card's bottom edge just above the help button as its text grows.
static func place_help(panel:Control,view:Vector2)->void:
	if panel==null:return
	panel.reset_size()
	panel.position=Vector2(T.RAIL_WIDTH+16.0,view.y-140.0-panel.size.y)

# ------------------------------------------------------- word from the road

static func style_notice(button:Button,danger:bool)->void:
	button.theme=T.control_theme()
	for state in ["normal","hover","pressed","focus"]:
		var style:=Kit.card_style(14.0,T.RED if danger else T.GOLD)
		if state=="hover":style.bg_color=T.PAPER
		button.add_theme_stylebox_override(state,style)
	button.add_theme_font_override("font",T.FONT_UI)
	button.add_theme_font_size_override("font_size",14)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(key,T.INK)
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

## "Word from the road": who speaks, what they say, and where to answer.
static func road_words(speaker:String,text:String)->String:
	return "Word from the road, from %s\n%s\n\nClick to answer them in court." % [speaker if speaker!="" else "the caravan's speakers",text.strip_edges()]

static func caravan_words(entry:Dictionary)->String:
	var title:=Kit.sentence(String(entry.get("title",""))).trim_suffix(".")
	var text:=String(entry.get("text","")).strip_edges()
	return "Word from the road, from %s\n%s%s\n\nClick to answer them in court." % [String(entry.get("leader","the caravan leader")),(title+". ") if title!="" else "",text]

static func open_court(focus:Dictionary={})->void:
	preload("res://scripts/audience_director.gd").open_court_for(focus)

# ------------------------------------------------------ first-contact alert

## Builds the alert card. Returns {panel,title,body,world_button}.
static func build_alert(layer:CanvasLayer,view:Vector2,on_show:Callable,on_speak:Callable,on_later:Callable)->Dictionary:
	var panel:=Kit.panel(T.GOLD,16.0)
	panel.name="ForeignObservationAlert"
	panel.position=Vector2(maxf(12.0,view.x-396.0),84)
	panel.custom_minimum_size=Vector2(380,0)
	panel.z_index=80
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	var title:=Kit.label(column,"","heading")
	var body:=Kit.label(column,"","body")
	body.custom_minimum_size=Vector2(348,0)
	body.max_lines_visible=7
	body.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	column.add_child(actions)
	var show:=Kit.button(actions,"Show on map",false,on_show,"Move the map to where they were seen")
	show.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var speak:=Kit.button(actions,"Speak with them",true,on_speak,"Open the court: send word to their people through our envoys")
	speak.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Kit.quiet_button(actions,"Later",on_later,"Close this note; the Chronicle keeps the telling")
	panel.visible=false
	layer.add_child(panel)
	return {"panel":panel,"title":title,"body":body,"world_button":speak}

static func alert_title(first_contact:bool,count:int,day:int)->String:
	var head:="First contact" if first_contact else "Strangers seen"
	if count>1:head="%d bands of strangers seen" % count
	return "%s · %s" % [head,Kit.when(day)]

static func style_alert(panel:PanelContainer,first_contact:bool)->void:
	panel.add_theme_stylebox_override("panel",Kit.card_style(16.0,T.GOLD if first_contact else T.RED))
