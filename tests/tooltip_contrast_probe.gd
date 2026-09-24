extends Node
## Hover clues must be readable everywhere. Hovers real controls on the dock
## (the culture showcase), the audience modal and the artifact gallery, in
## light and dark mode, lets Godot raise its own tooltip popup, and checks the
## TooltipPanel/TooltipLabel colours (contrast ratio), padding and wrap width.
## Headless: checks only, prints "TOOLTIP_CONTRAST PASS". Windowed
## (tools/run_isolated_gpu_probe.ps1) with `-- --shots=<dir>` it also saves one
## capture per surface and mode.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Prefs:=preload("res://scripts/display_preferences.gd")
const Gallery:=preload("res://scripts/hud/artifact_gallery.gd")
const GalleryProbe:=preload("res://tests/artifact_gallery_probe.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")

var failures:Array[String]=[]
var shots:=""
var game_speed:=1.0
var prefs:Node

func _set_game_speed(value:float)->void:game_speed=value

func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);printerr("TOOLTIP_CONTRAST FAIL: ",message)

func _frames(count:int=3)->void:
	for i in count:await get_tree().process_frame

func _ready()->void:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):shots=argument.trim_prefix("--shots=")
	if DisplayServer.get_name()=="headless":shots=""
	get_tree().current_scene=self
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	GalleryProbe.Stub.populate()
	# The game's own display preferences own the root theme (never the user's saved file).
	prefs=Prefs.new();prefs.config_path="user://tooltip_contrast_probe_absent.cfg"
	add_child(prefs)
	if not shots.is_empty():
		get_window().size=Vector2i(1600,900)
	await _frames(2)
	for mode:String in ["light","dark"]:
		prefs.color_theme=mode;T.set_color_mode(mode);prefs.apply()
		check(get_tree().root.theme==T.control_theme(),"the root window does not carry the HUD theme in %s mode" % mode)
		await _dock(mode)
		await _audience(mode)
		await _gallery(mode)
	T.set_color_mode("light")
	print("TOOLTIP_CONTRAST ","PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

# ---------------------------------------------------------------------------

static func _luminance(color:Color)->float:
	return color.srgb_to_linear().get_luminance()

static func contrast(a:Color,b:Color)->float:
	var la:=_luminance(a);var lb:=_luminance(b)
	return (maxf(la,lb)+0.05)/(minf(la,lb)+0.05)

func _find_tooltip(node:Node)->Node:
	if node is Window and String((node as Window).theme_type_variation)=="TooltipPanel":return node
	for child:Node in node.get_children(true):
		var found:=_find_tooltip(child)
		if found:return found
	return null

func _find_label(node:Node)->Label:
	if node is Label:return node as Label
	for child:Node in node.get_children(true):
		var found:=_find_label(child)
		if found:return found
	return null

func _tipped(root:Node,prefer:String="")->Control:
	## A visible, on-screen control with a hover clue (prefer one containing
	## any of the |-separated words in `prefer`).
	var fallback:Control=null
	var stack:Array[Node]=[root]
	var screen:=get_viewport().get_visible_rect()
	while not stack.is_empty():
		var node:Node=stack.pop_back()
		for child:Node in node.get_children():stack.append(child)
		if not node is Control:continue
		var control:=node as Control
		if control.tooltip_text.strip_edges().is_empty() or not control.is_visible_in_tree():continue
		if not screen.encloses(control.get_global_rect()) or control.size.x<4.0:continue
		if prefer!="":
			for word:String in prefer.split("|"):
				if control.tooltip_text.contains(word):return control
		if fallback==null:fallback=control
	return fallback

func _hover(control:Control,surface:String,mode:String)->void:
	if control==null:check(false,"%s (%s): no control with a hover clue" % [surface,mode]);return
	var point:=control.get_global_rect().get_center()
	for i in 3:
		var motion:=InputEventMouseMotion.new();motion.position=point+Vector2(i,0);motion.global_position=motion.position
		get_viewport().push_input(motion,true)
		await get_tree().process_frame
	var waited:=0.0
	var tip:Node=null
	while waited<3.0:
		await get_tree().process_frame;waited+=maxf(get_process_delta_time(),1.0/60.0)
		tip=_find_tooltip(control)
		if tip and (tip as Window).visible:break
	if tip==null:check(false,"%s (%s): hovering '%s' raised no tooltip" % [surface,mode,control.tooltip_text.left(40)]);return
	await _frames(3)
	var panel:=tip as Window
	var label:=_find_label(tip)
	var style:=panel.get_theme_stylebox("panel") as StyleBoxFlat
	check(style!=null,"%s (%s): the tooltip panel is not the HUD style" % [surface,mode])
	if style==null or label==null:return
	var ink:=label.get_theme_color("font_color")
	var ratio:=contrast(ink,style.bg_color)
	check(style.bg_color.a>=0.95,"%s (%s): the tooltip panel is see-through (%.2f)" % [surface,mode,style.bg_color.a])
	check(ratio>=7.0,"%s (%s): tooltip contrast %.1f:1 (ink %s on %s)" % [surface,mode,ratio,ink.to_html(false),style.bg_color.to_html(false)])
	check((mode=="light")==(_luminance(style.bg_color)>0.5),"%s (%s): tooltip panel is not %s" % [surface,mode,"paper" if mode=="light" else "dark"])
	check(style.content_margin_left>=10.0 and style.content_margin_top>=6.0,"%s (%s): tooltip padding too tight" % [surface,mode])
	check(panel.size.x<=T.TOOLTIP_MAX_WIDTH+style.content_margin_left+style.content_margin_right+16.0,"%s (%s): tooltip %.0f px wide, past the readable width" % [surface,mode,panel.size.x])
	check(label.get_theme_font_size("font_size")>=14,"%s (%s): tooltip text is too small" % [surface,mode])
	var one_line:=label.get_theme_font("font").get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1.0,label.get_theme_font_size("font_size")).x
	if one_line>T.TOOLTIP_MAX_WIDTH:
		check(label.autowrap_mode!=TextServer.AUTOWRAP_OFF and label.get_line_count()>1 and label.get_visible_line_count()>=label.get_line_count(),"%s (%s): a long clue is not wrapped in full (%d lines, %d visible)" % [surface,mode,label.get_line_count(),label.get_visible_line_count()])
	print("TOOLTIP %s %s: %.1f:1 ink %s on %s, %s, '%s'" % [surface,mode,ratio,ink.to_html(false),style.bg_color.to_html(false),panel.size,control.tooltip_text.left(48).replace("\n"," / ")])
	if not shots.is_empty():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(shots)
		var path:=shots.path_join("tooltip-%s-%s.png" % [surface,mode])
		get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ",path)
	# Move away so the next surface starts clean.
	var away:=InputEventMouseMotion.new();away.position=Vector2(2,2);away.global_position=away.position
	get_viewport().push_input(away,true)
	await _frames(4)

func _dock(mode:String)->void:
	var host:=Control.new();host.name="FakeHud";host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(host)
	host.add_user_signal("section_requested",[{"name":"section","type":TYPE_STRING},{"name":"sub","type":TYPE_INT}])
	var backdrop:=ColorRect.new();backdrop.color=Color("56613f") if mode=="light" else Color("1d2a24");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;host.add_child(backdrop)
	var provider=load("res://scripts/hud/content/dock_content_civilization.gd").new(null,host)
	provider.artifact_source=GalleryProbe.Stub
	var built:Variant=provider.tab(0)
	var blocks:Array=built.get("blocks",[]) if built is Dictionary else []
	var dock:=PanelContainer.new();dock.theme=T.control_theme();dock.position=Vector2(T.DOCK_X,8);dock.size=Vector2(T.DOCK_WIDTH,get_viewport().get_visible_rect().size.y-16)
	var dock_style:=T.dock_style();dock_style.set_content_margin_all(18);dock.add_theme_stylebox_override("panel",dock_style);host.add_child(dock)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;dock.add_child(scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	DockBlocks.render(body,blocks)
	await _frames(6)
	var showcase:=body.find_child("ArtifactShowcase",true,false) as Control
	if showcase:
		scroll.scroll_vertical=int(maxf(0,showcase.position.y-260))
		await _frames(3)
	await _hover(_tipped(showcase if showcase else body,"llure"),"dock",mode)
	# A long clue on a dock row wraps at a readable width.
	var row:=Button.new();row.name="LongClueRow";row.text="Regard of the court";row.custom_minimum_size=Vector2(300,40)
	row.tooltip_text="Dread buys obedience and costs honesty; love buys candour. Dread soured by resentment shows first in their words, then in their work, and at last in flight. Both fade with time: dread in weeks, love over seasons."
	body.add_child(row);body.move_child(row,0);scroll.scroll_vertical=0
	await _frames(4)
	await _hover(row,"dock-long",mode)
	host.queue_free();await _frames(2)

func _audience(mode:String)->void:
	var terrain:=ModalProbe.TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():check(false,"no audience could be forced");director.queue_free();terrain.queue_free();return
	var modal:Control=director.open_audience(String(audience.id))
	await _frames(4)
	modal.skip_reveal()
	await _frames(4)
	await _hover(_tipped(modal,"Dread buys|their ruler's trust"),"audience",mode)
	modal.make_them_wait()
	await _frames(2)
	director.queue_free();terrain.queue_free()
	await _frames(2)

func _gallery(mode:String)->void:
	var backdrop:=ColorRect.new();backdrop.color=Color("56613f");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
	var gallery:=Gallery.open(self,null,"",GalleryProbe.Stub)
	await _frames(8)
	await _hover(_tipped(gallery,"Allure"),"gallery",mode)
	gallery.close()
	backdrop.queue_free()
	await _frames(3)
