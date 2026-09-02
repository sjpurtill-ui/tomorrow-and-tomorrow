extends Control

## A non-scrolling viewport for finite modal content. Small differences are
## handled with a modest uniform fit. If a list or grid would become unreadable,
## its direct children are split into pages instead. Whole ledgers must never be
## miniaturized into illegible texture.

var effective_scale:float=1.0
var content_padding:=Vector2.ZERO
var allow_pagination:bool=true
var minimum_readable_scale:float=0.74
var current_page:int=0
var page_count:int=1
var _last_signature:=Vector4(-1.0,-1.0,-1.0,-1.0)
var _pager:HBoxContainer
var _page_label:Label


func _ready()->void:
	clip_contents=true
	set_process(true)
	_fit_content.call_deferred()


func _process(_delta:float)->void:
	_fit_content()


func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED or what==NOTIFICATION_CHILD_ORDER_CHANGED:
		_fit_content.call_deferred()


func _content_control()->Control:
	for child in get_children():
		if child is Control and child!=_pager: return child as Control
	return null


func _fit_content()->void:
	var content:=_content_control()
	if content==null or size.x<=1.0 or size.y<=1.0: return
	var managed:=_managed_page_items(content)
	var minimum:=_estimated_full_minimum(content,managed)
	if minimum.x<=0.0 or minimum.y<=0.0: return
	var available:=Vector2(maxf(1.0,size.x-content_padding.x*2.0),maxf(1.0,size.y-content_padding.y*2.0))
	var signature:=Vector4(size.x+float(current_page)*0.001,size.y+float(managed.size())*0.001,minimum.x,minimum.y)
	if signature.is_equal_approx(_last_signature): return
	_last_signature=signature
	var raw_scale:=minf(1.0,minf(available.x/minimum.x,available.y/minimum.y))
	if allow_pagination and raw_scale<minimum_readable_scale and managed.size()>1:
		_apply_readable_page(content,managed,available)
		return
	_restore_all_items(managed)
	_hide_pager()
	page_count=1
	current_page=0
	effective_scale=raw_scale
	content.scale=Vector2.ONE*effective_scale
	var logical_size:=available/effective_scale
	content.size=Vector2(maxf(minimum.x,logical_size.x),maxf(minimum.y,logical_size.y))
	var rendered_size:=content.size*effective_scale
	content.position=content_padding+(available-rendered_size)*0.5


func _managed_page_items(content:Control)->Array[Control]:
	var result:Array[Control]=[]
	for child in content.get_children():
		if not child is Control: continue
		var control:=child as Control
		if not control.has_meta("viewport_page_item") and control.visible:
			control.set_meta("viewport_page_item",true)
		if control.has_meta("viewport_page_item"): result.append(control)
	return result


func _estimated_full_minimum(content:Control,items:Array[Control])->Vector2:
	if items.is_empty(): return content.get_combined_minimum_size()
	if content is GridContainer:
		var grid:=content as GridContainer
		var columns:=maxi(1,grid.columns)
		var width:=0.0
		var height:=0.0
		var row_width:=0.0
		var row_height:=0.0
		for index in items.size():
			var item_min:=items[index].get_combined_minimum_size()
			row_width+=item_min.x
			row_height=maxf(row_height,item_min.y)
			if index%columns==columns-1 or index==items.size()-1:
				width=maxf(width,row_width)
				height+=row_height
				row_width=0.0; row_height=0.0
		return Vector2(width,height)
	if content is HBoxContainer:
		var h_width:=0.0
		var h_height:=0.0
		for item in items:
			var item_min:=item.get_combined_minimum_size()
			h_width+=item_min.x
			h_height=maxf(h_height,item_min.y)
		return Vector2(h_width,h_height)
	var v_width:=0.0
	var v_height:=0.0
	for item in items:
		var item_min:=item.get_combined_minimum_size()
		v_width=maxf(v_width,item_min.x)
		v_height+=item_min.y
	return Vector2(v_width,v_height)


func _apply_readable_page(content:Control,items:Array[Control],available:Vector2)->void:
	var page_groups:=_page_groups(content,items,available-Vector2(0,34))
	page_count=maxi(1,page_groups.size())
	current_page=clampi(current_page,0,page_count-1)
	var visible_indices:Array=page_groups[current_page] if not page_groups.is_empty() else []
	for index in items.size(): items[index].visible=index in visible_indices
	_show_pager()
	var page_available:=Vector2(available.x,maxf(1.0,available.y-34.0))
	var visible_minimum:=content.get_combined_minimum_size()
	effective_scale=minf(1.0,minf(page_available.x/maxf(1.0,visible_minimum.x),page_available.y/maxf(1.0,visible_minimum.y)))
	content.scale=Vector2.ONE*effective_scale
	var logical_size:=page_available/effective_scale
	content.size=Vector2(maxf(visible_minimum.x,logical_size.x),maxf(visible_minimum.y,logical_size.y))
	content.position=content_padding


func _page_groups(content:Control,items:Array[Control],available:Vector2)->Array[Array]:
	var groups:Array[Array]=[]
	var current:Array=[]
	var used:=0.0
	var limit:=available.y
	var horizontal:=content is HBoxContainer
	if horizontal: limit=available.x
	if content is GridContainer:
		var columns:=maxi(1,(content as GridContainer).columns)
		var row:Array=[]
		var row_size:=0.0
		for index in items.size():
			row.append(index)
			row_size=maxf(row_size,items[index].get_combined_minimum_size().y)
			if row.size()>=columns or index==items.size()-1:
				if not current.is_empty() and used+row_size>limit:
					groups.append(current); current=[]; used=0.0
				current.append_array(row); used+=row_size; row=[]; row_size=0.0
	else:
		for index in items.size():
			var item_min:=items[index].get_combined_minimum_size()
			var item_size:=item_min.x if horizontal else item_min.y
			if not current.is_empty() and used+item_size>limit:
				groups.append(current); current=[]; used=0.0
			current.append(index); used+=item_size
	if not current.is_empty(): groups.append(current)
	return groups


func _restore_all_items(items:Array[Control])->void:
	for item in items: item.visible=true


func _show_pager()->void:
	if _pager==null:
		_pager=HBoxContainer.new()
		_pager.name="ViewportPager"
		_pager.alignment=BoxContainer.ALIGNMENT_END
		_pager.add_theme_constant_override("separation",6)
		add_child(_pager)
		var previous:=Button.new()
		previous.text="‹ PREVIOUS"
		previous.custom_minimum_size=Vector2(88,30)
		previous.pressed.connect(_change_page.bind(-1))
		_pager.add_child(previous)
		_page_label=Label.new()
		_page_label.custom_minimum_size=Vector2(76,30)
		_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_page_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		_page_label.add_theme_font_size_override("font_size",11)
		_pager.add_child(_page_label)
		var next:=Button.new()
		next.text="NEXT ›"
		next.custom_minimum_size=Vector2(72,30)
		next.pressed.connect(_change_page.bind(1))
		_pager.add_child(next)
	_pager.visible=true
	_pager.position=Vector2(content_padding.x,size.y-content_padding.y-32.0)
	_pager.size=Vector2(maxf(1.0,size.x-content_padding.x*2.0),30)
	_page_label.text="PAGE %d / %d" % [current_page+1,page_count]
	(_pager.get_child(0) as Button).disabled=current_page<=0
	(_pager.get_child(2) as Button).disabled=current_page>=page_count-1


func _hide_pager()->void:
	if _pager: _pager.visible=false


func _change_page(delta:int)->void:
	current_page=clampi(current_page+delta,0,maxi(0,page_count-1))
	_last_signature=Vector4(-1,-1,-1,-1)
	_fit_content.call_deferred()
