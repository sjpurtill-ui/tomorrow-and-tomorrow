extends TextureRect
## A long archive keeps paintings only for cards actually inside its scroll area.
## The shared bounded texture cache handles recently viewed images.
var fetch:Callable
var scroll:ScrollContainer
func _ready()->void:
	resized.connect(refresh)
	visibility_changed.connect(refresh)
	if is_instance_valid(scroll):
		scroll.resized.connect(refresh)
		scroll.get_v_scroll_bar().value_changed.connect(func(_value:float)->void:refresh())
		scroll.get_h_scroll_bar().value_changed.connect(func(_value:float)->void:refresh())
	call_deferred("refresh")
func refresh()->void:
	if not is_instance_valid(scroll) or not fetch.is_valid():return
	if is_visible_in_tree() and size.y>0 and scroll.get_global_rect().intersects(get_global_rect()):
		if texture==null:texture=fetch.call()
	else:texture=null
