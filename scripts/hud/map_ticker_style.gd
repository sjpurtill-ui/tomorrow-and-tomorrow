extends RefCounted
## THE MAP TICKER ON PAPER (codex/beauty-3): the one-line status strip over
## the map (the Chronicle's latest tale, travel and founding notices) was 10 px
## gold type straight on the land, unreadable over bright grass. It now sits
## on a small paper slip hanging under the top bar, in the UI face at a
## readable size, in ink, and fits its text: an empty ticker shows no slip.

const HudT:=preload("res://scripts/hud/hud_tokens.gd")
const TOP:=74.0
const PAD:=Vector2(16.0,5.0)

static func style(label:Label)->void:
	var slip:=StyleBoxFlat.new()
	slip.bg_color=Color(HudT.PANEL_BG_SOLID,0.95)
	slip.border_color=Color(HudT.BORDER_SOFT,0.9)
	slip.set_border_width_all(1)
	slip.set_corner_radius_all(2)
	slip.content_margin_left=PAD.x;slip.content_margin_right=PAD.x
	slip.content_margin_top=PAD.y;slip.content_margin_bottom=PAD.y
	slip.shadow_color=Color(0.12,0.09,0.05,0.16)
	slip.shadow_size=6;slip.shadow_offset=Vector2(0,2)
	label.add_theme_stylebox_override("normal",slip)
	label.add_theme_font_override("font",HudT.FONT_UI)
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",HudT.INK)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.clip_text=true
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.set_meta("ticker_fitted","")

## Sizes the slip to its text, centred over the map. Cheap when the text and
## width are unchanged; hides the slip when there is nothing to say.
static func fit(label:Label,viewport_width:float)->void:
	# Older systems still hand the ticker shouted text; it reads as a sentence.
	var calm:=preload("res://scripts/hud/paper_kit.gd").calm_line(label.text)
	if calm!=label.text.strip_edges() and calm!="":label.text=calm
	var key:="%s|%d" % [label.text,roundi(viewport_width)]
	# A telling that asks the god's hand (one of theirs held under guard)
	# carries its own plain button beside the slip; checked now and then.
	if Engine.get_process_frames()%30==0 or String(label.get_meta("ticker_fitted",""))!=key:_action_button(label)
	if String(label.get_meta("ticker_fitted",""))==key:return
	label.set_meta("ticker_fitted",key)
	if label.text.strip_edges()=="":
		label.self_modulate.a=0.0
		return
	label.self_modulate.a=1.0
	var font:Font=label.get_theme_font("font")
	var width:=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
	var usable:=maxf(240.0,viewport_width-HudT.RAIL_WIDTH-48.0)
	var box:=Vector2(minf(width+PAD.x*2.0+4.0,usable),28.0)
	label.size=box
	label.position=Vector2(HudT.RAIL_WIDTH+(viewport_width-HudT.RAIL_WIDTH-box.x)*0.5,TOP)
	var button:=label.get_node_or_null("TickerAction") as Button
	if button!=null:button.position=Vector2(box.x+8.0,0.0)

## The newest telling's own button: "Bring them before you" for a spy or an
## assassin held under guard (captured_agents.gd), while they are held and
## the slip shows that telling. Nothing opens unless pressed.
static func _action_button(label:Label)->void:
	var button:=label.get_node_or_null("TickerAction") as Button
	var id:=""
	var newest:Array=preload("res://scripts/chronicle.gd").entries("notice",1)
	if not newest.is_empty() and label.text.strip_edges()!="":
		var action:Variant=(newest[0] as Dictionary).get("action",{})
		if action is Dictionary and String((action as Dictionary).get("kind",""))=="prisoner" and label.text.begins_with(String((newest[0] as Dictionary).get("title","~"))):
			id=String((action as Dictionary).get("prisoner_id",""))
			if not preload("res://scripts/captured_agents.gd").is_held(id):id=""
	if id=="":
		if button!=null:button.visible=false
		return
	if button==null:
		button=Button.new();button.name="TickerAction";button.text="Bring them before you"
		button.focus_mode=Control.FOCUS_NONE;button.mouse_filter=Control.MOUSE_FILTER_STOP
		button.add_theme_font_override("font",HudT.FONT_UI);button.add_theme_font_size_override("font_size",13)
		button.add_theme_color_override("font_color",HudT.INK)
		var slip:=StyleBoxFlat.new();slip.bg_color=Color(HudT.PANEL_BG_SOLID,0.97);slip.border_color=HudT.GOLD;slip.set_border_width_all(1);slip.set_corner_radius_all(2)
		slip.content_margin_left=10;slip.content_margin_right=10;slip.content_margin_top=3;slip.content_margin_bottom=3
		for state in ["normal","hover","pressed","focus"]:button.add_theme_stylebox_override(state,slip)
		label.add_child(button)
		button.pressed.connect(func()->void:
			preload("res://scripts/audience_director.gd").open_court_for({"prisoner_id":String(button.get_meta("prisoner_id",""))}))
	button.set_meta("prisoner_id",id)
	button.tooltip_text="Have them brought into the court, to question them and decide their fate."
	button.visible=true
	button.position=Vector2(label.size.x+8.0,0.0)
