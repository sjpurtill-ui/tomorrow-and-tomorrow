extends ScrollContainer
## Fallback for legacy finite modals. Preserve authored text size and visibility:
## a smaller window introduces scrolling, never arbitrary pages or tiny text.
## Modern popups provide their own fixed header and scrolling body.

# Retained for callers that inspected the old fitting contract.
var effective_scale:float=1.0
var content_padding:=Vector2.ZERO
var allow_pagination:bool=false
var minimum_readable_scale:float=1.0
var current_page:int=0
var page_count:int=1

func _ready()->void:
	clip_contents=true
	follow_focus=true
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	_fit_content.call_deferred()

func _notification(what:int)->void:
	if what==NOTIFICATION_CHILD_ORDER_CHANGED:
		_fit_content.call_deferred()

func _fit_content()->void:
	for child in get_children():
		if child is Control and not child is ScrollBar:
			var content:=child as Control
			content.scale=Vector2.ONE
			content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			content.size_flags_vertical=Control.SIZE_EXPAND_FILL
