extends RefCounted
## Display preferences (display_preferences.gd) reshape the root window when
## they apply: a 64 px headless window becomes a 640 x 640 canvas with EXPAND
## aspect, 3D scaling and a 60 fps cap. They also re-apply whenever the
## window's size changes, so a suite that puts the window back while its
## preferences node is still in the tree gets the change re-applied over its
## restore. Every later suite then draws and projects on the wrong canvas
## (test_map_chart's chart-scale check failed after test_button_contrast).
##
## Suites that add a DisplayPreferences node call capture() before and
## restore() after: restore cuts any preferences node still listening, then
## puts every value apply() touches back.

const Prefs:=preload("res://scripts/display_preferences.gd")

static func capture(window:Window)->Array:
	return [window.theme,window.content_scale_mode,window.content_scale_aspect,window.content_scale_size,
		window.content_scale_factor,window.scaling_3d_mode,window.scaling_3d_scale,Engine.max_fps]

static func restore(window:Window,saved:Array)->void:
	if saved.is_empty():return
	for connection:Dictionary in window.size_changed.get_connections():
		var callable:Callable=connection.callable
		var target:Object=callable.get_object()
		if target!=null and target.get_script()==Prefs:window.size_changed.disconnect(callable)
	window.theme=saved[0];window.content_scale_mode=saved[1];window.content_scale_aspect=saved[2];window.content_scale_size=saved[3]
	window.content_scale_factor=saved[4];window.scaling_3d_mode=saved[5];window.scaling_3d_scale=saved[6];Engine.max_fps=saved[7]
