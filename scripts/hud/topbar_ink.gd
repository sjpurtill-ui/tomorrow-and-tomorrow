extends RefCounted
## Local contrast for lettering over terrain; no backing panel or zoom polling.
const EDGE := Color("20271f")

static func apply(control: Control) -> void:
	control.add_theme_color_override("font_outline_color", EDGE)
	control.add_theme_constant_override("outline_size", 2)
	if control is Label or control is RichTextLabel:
		control.add_theme_color_override("font_shadow_color", Color(0.04, 0.06, 0.04, 0.75))
		control.add_theme_constant_override("shadow_offset_x", 0)
		control.add_theme_constant_override("shadow_offset_y", 1)
		control.add_theme_constant_override("shadow_outline_size", 1)
