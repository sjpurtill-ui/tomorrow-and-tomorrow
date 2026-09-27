extends GdUnitTestSuite
## Button labels on paper must read: WCAG 4.5:1 for live text, 3:1 when
## disabled, in both palettes. Covers the shared HUD theme and the button
## builders the discovery popup and the Chronicle card use.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Art=preload("res://scripts/hud/research_visuals.gd")
const ChronicleCard=preload("res://scripts/hud/chronicle_card.gd")
const DiscoveryPopup=preload("res://scripts/hud/discovery_popup.gd")
const Prefs=preload("res://scripts/display_preferences.gd")
## [font colour item, stylebox item, minimum ratio]
const STATES:=[["font_color","normal",4.5],["font_hover_color","hover",4.5],["font_pressed_color","pressed",4.5],["font_hover_pressed_color","hover_pressed",4.5],["font_disabled_color","disabled",3.0]]
class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value

func after()->void:
	T.set_color_mode("light")

static func luminance(color:Color)->float:
	var channels:=[color.r,color.g,color.b]
	for i in 3:channels[i]=channels[i]/12.92 if channels[i]<=0.03928 else pow((channels[i]+0.055)/1.055,2.4)
	return 0.2126*channels[0]+0.7152*channels[1]+0.0722*channels[2]

static func contrast(a:Color,b:Color)->float:
	var high:=maxf(luminance(a),luminance(b));var low:=minf(luminance(a),luminance(b))
	return (high+0.05)/(low+0.05)

## A translucent ground is judged over the paper it sits on.
static func ground(style:StyleBox)->Color:
	var bg:=(style as StyleBoxFlat).bg_color
	return T.PANEL_BG.lerp(Color(bg.r,bg.g,bg.b),bg.a)

func check_button(button:Button,where:String)->void:
	for state:Array in STATES:
		var style:=button.get_theme_stylebox(String(state[1]))
		assert_object(style).override_failure_message("%s has no %s style" % [where,state[1]]).is_instanceof(StyleBoxFlat)
		var ratio:=contrast(button.get_theme_color(String(state[0])),ground(style))
		assert_float(ratio).override_failure_message("%s %s text contrast %.2f < %.1f in %s mode" % [where,state[1],ratio,state[2],T.color_mode]).is_greater_equal(float(state[2]))

func themed_root()->Control:
	var root:Control=auto_free(Control.new());root.theme=T.control_theme();add_child(root)
	return root

func test_theme_buttons_read_in_every_state_in_both_palettes()->void:
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		var root:=themed_root()
		var button:=Button.new();button.text="Continue";root.add_child(button)
		check_button(button,"theme Button")
		# Disabled is visibly different from a live button, not just greyer text.
		assert_bool(button.get_theme_stylebox("disabled").bg_color!=button.get_theme_stylebox("normal").bg_color).is_true()
		assert_bool(button.get_theme_color("font_disabled_color")!=button.get_theme_color("font_color")).is_true()
		assert_bool(button.get_theme_stylebox("pressed").bg_color!=button.get_theme_stylebox("hover").bg_color).is_true()

func test_discovery_and_chronicle_buttons_read_in_both_palettes()->void:
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		var root:=themed_root()
		check_button(Art.button(root,"View in research",func()->void:pass),"research button")
		var card:=ChronicleCard.new()
		check_button(card._button(root,"Open Hearth-Tales",func()->void:pass,true),"chronicle primary button")
		check_button(card._button(root,"×",func()->void:pass),"chronicle side button")
		card.free()

func test_close_glyph_exists_in_the_interface_face()->void:
	assert_bool(T.FONT_UI.has_char("×".unicode_at(0))).is_true()

func test_game_display_preferences_theme_popups_on_canvas_layers()->void:
	# The game themes controls that sit under CanvasLayers and SubViewports;
	# without it Button text falls back to Godot's pale default on paper.
	T.set_color_mode("light")
	var window:=get_window();var saved:=[window.theme,window.content_scale_mode,window.content_scale_aspect,window.content_scale_size,window.scaling_3d_mode]
	var prefs:Node=auto_free(Prefs.new());prefs.config_path="user://button_contrast_no_display.cfg";add_child(prefs)
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.known_discoveries.append("food_drying")
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1200,900);add_child(canvas)
	var host:=Host.new();canvas.add_child(host);var hud:=Control.new();host.add_child(hud)
	var popup:=DiscoveryPopup.announce(host,hud,[{"id":"food_drying","day":12}])
	check_button(popup.next_button,"discovery popup Continue")
	popup.close()
	window.theme=saved[0];window.content_scale_mode=saved[1];window.content_scale_aspect=saved[2];window.content_scale_size=saved[3];window.scaling_3d_mode=saved[4]
