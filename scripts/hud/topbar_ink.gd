extends RefCounted
## Local contrast for lettering over terrain; no backing panel or zoom polling.
const TEXT := Color("fffef8")
const ACTIVE := Color("ffe39a")
const EDGE := Color("172019")

static func apply(control: Control) -> void:
	control.add_theme_color_override("font_outline_color", EDGE)
	control.add_theme_constant_override("outline_size", 1)
	if control is Label or control is RichTextLabel:
		control.add_theme_color_override("font_shadow_color", Color(0.04, 0.06, 0.04, 0.95))
		control.add_theme_constant_override("shadow_offset_x", 0)
		control.add_theme_constant_override("shadow_offset_y", 1)
		control.add_theme_constant_override("shadow_outline_size", 1)
