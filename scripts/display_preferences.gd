extends Node
## Machine-local display and input choices, separate from world saves.
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const SETTINGS_PATH:="user://display.cfg"
const DEFAULT_MAP_SCROLL_SPEED:=4.0
const MIN_MAP_SCROLL_SPEED:=0.5
const MAX_MAP_SCROLL_SPEED:=12.0
var ui_scale:=1.25
var render_scale:=0.75
var shadows:=false
var frame_limit:=60
var music_volume:=1.0
var map_scroll_speed:=DEFAULT_MAP_SCROLL_SPEED
var color_theme:="light"
var config_path:=SETTINGS_PATH
var applying:=false

func _ready()->void:
	var config:=ConfigFile.new()
	if config.load(config_path)==OK:
		ui_scale=clampf(float(config.get_value("display","ui_scale",1.25)),1.0,1.75)
		render_scale=clampf(float(config.get_value("display","render_scale",0.75)),0.5,1.0)
		shadows=bool(config.get_value("display","shadows",false))
		frame_limit=int(config.get_value("display","frame_limit",60))
		music_volume=clampf(float(config.get_value("display","music_volume",1.0)),0.0,1.0)
		color_theme=String(config.get_value("display","color_theme","light"))
		if color_theme not in ["light","dark"]:color_theme="light"
		var saved_speed:Variant=config.get_value("camera","map_scroll_speed",DEFAULT_MAP_SCROLL_SPEED)
		if (saved_speed is float or saved_speed is int) and is_finite(float(saved_speed)):
			map_scroll_speed=clampf(float(saved_speed),MIN_MAP_SCROLL_SPEED,MAX_MAP_SCROLL_SPEED)
		if frame_limit not in [30,60,120]:frame_limit=60
	get_window().size_changed.connect(apply)
	Tokens.set_color_mode(color_theme)
	apply()

static func logical_size(pixels:Vector2i,density:float,scale:float)->Vector2i:
	# Keep a usable canvas on small screens; never squeeze the navigation rail
	# or minimum dialog width offscreen. Larger windows can use the full scale.
	var factor:=maxf(0.1,minf(maxf(1.0,density)*scale,minf(float(pixels.x)/1024.0,float(pixels.y)/640.0)))
	return Vector2i(roundi(pixels.x/factor),roundi(pixels.y/factor))

func apply()->void:
	if applying:return
	applying=true
	var window:=get_window()
	var density:=DisplayServer.screen_get_scale(window.current_screen) if DisplayServer.get_name()!="headless" else 1.0
	window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_size=logical_size(window.size,density,ui_scale)
	window.content_scale_factor=1.0
	# The canvas remains at output resolution; only the 3D image is downsampled.
	window.scaling_3d_mode=Viewport.SCALING_3D_MODE_BILINEAR
	window.scaling_3d_scale=render_scale
	Engine.max_fps=frame_limit
	apply_music()
	for child in get_parent().get_children():
		if child is DirectionalLight3D:child.shadow_enabled=shadows
	applying=false

func apply_music()->void:
	var bus:=AudioServer.get_bus_index("Music")
	if bus<0:
		AudioServer.add_bus()
		bus=AudioServer.bus_count-1
		AudioServer.set_bus_name(bus,"Music")
		AudioServer.set_bus_send(bus,"Master")
	AudioServer.set_bus_mute(bus,music_volume<=0.0)
	AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(0.0001,music_volume)))
	var score:=get_parent().get_node_or_null("Score") as AudioStreamPlayer
	if score:score.bus="Music"

func persist()->void:
	var config:=ConfigFile.new()
	for key in ["ui_scale","render_scale","shadows","frame_limit","music_volume","color_theme"]:config.set_value("display",key,get(key))
	config.set_value("camera","map_scroll_speed",map_scroll_speed)
	if config.save(config_path)!=OK:push_warning("Settings apply this session but could not be saved.")

func add_navigation_controls(parent:Node)->void:
	var heading:=Label.new();heading.text="MAP CONTROLS";heading.add_theme_font_size_override("font_size",16);parent.add_child(heading)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);parent.add_child(row)
	var label:=Label.new();label.text="Map scroll speed · %.1f×"%map_scroll_speed
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
	var reset:=Button.new();reset.text="Default";reset.custom_minimum_size.y=38;row.add_child(reset)
	var slider:=HSlider.new();slider.name="MapScrollSpeed"
	slider.min_value=MIN_MAP_SCROLL_SPEED;slider.max_value=MAX_MAP_SCROLL_SPEED;slider.step=0.5
	slider.value=map_scroll_speed;slider.custom_minimum_size.y=32
	slider.tooltip_text="Two-finger map panning. Changes apply immediately and are remembered between games."
	slider.value_changed.connect(func(value:float):map_scroll_speed=value;label.text="Map scroll speed · %.1f×"%value;persist())
	reset.pressed.connect(func():slider.value=DEFAULT_MAP_SCROLL_SPEED)
	parent.add_child(slider)

func _choice(parent:Node,label:String,labels:Array,current:int,callback:Callable)->OptionButton:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);parent.add_child(row)
	var text:=Label.new();text.text=label;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
	var options:=OptionButton.new();options.custom_minimum_size=Vector2(170,38)
	for value in labels:options.add_item(String(value))
	options.select(current);options.item_selected.connect(callback);row.add_child(options)
	return options

func set_color_theme(mode:String,reload_scene:bool=true)->void:
	color_theme="dark" if mode=="dark" else "light"
	Tokens.set_color_mode(color_theme)
	persist()
	if reload_scene and is_inside_tree():get_tree().reload_current_scene.call_deferred()

func add_controls(parent:Node)->void:
	var heading:=Label.new();heading.text="DISPLAY & PERFORMANCE";heading.add_theme_font_size_override("font_size",16);parent.add_child(heading)
	var appearance:=_choice(parent,"Interface colors",["Light","Dark"],1 if color_theme=="dark" else 0,func(index:int):set_color_theme("dark" if index==1 else "light"))
	appearance.name="ColorTheme"
	_choice(parent,"Text & interface size",["100%","125%","150%","175%"],clampi(roundi((ui_scale-1)*4),0,3),func(index:int):ui_scale=1.0+index*.25;apply();persist())
	_choice(parent,"3D resolution",["50% · fastest","75% · balanced","100% · sharpest"],[0.5,0.75,1.0].find(render_scale),func(index:int):render_scale=[0.5,0.75,1.0][index];apply();persist())
	_choice(parent,"Terrain shadows",["Off · faster","On"],1 if shadows else 0,func(index:int):shadows=index==1;apply();persist())
	_choice(parent,"Frame limit",["30 fps","60 fps","120 fps"],[30,60,120].find(frame_limit),func(index:int):frame_limit=[30,60,120][index];apply();persist())
	var music_label:=Label.new();music_label.text="Music volume · %d%%"%roundi(music_volume*100);parent.add_child(music_label)
	var music:=HSlider.new();music.min_value=0;music.max_value=100;music.step=1;music.value=music_volume*100;music.custom_minimum_size.y=32
	music.tooltip_text="Music only. Zero mutes music; other sounds are unchanged."
	music.value_changed.connect(func(value:float):music_volume=value/100;music_label.text="Music volume · %d%%"%roundi(value);apply_music();persist())
	parent.add_child(music)
	var hint:=Label.new();hint.text="Changes apply immediately. Lower 3D resolution keeps text sharp. UI size is limited on small windows to keep controls reachable. A frame limit is a ceiling, not a performance promise.";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_font_size_override("font_size",14);parent.add_child(hint)
