extends Tree
## Lazy, expandable echelons. Browsing never splits or recruits a force.
const T=preload("res://scripts/hud/hud_tokens.gd")
signal command_selected(selection:Dictionary)
var service:="army"
var command:RefCounted
var structure_signature:=""
var expanded:Dictionary={}
var active_selection:Dictionary={}
func _ready()->void:
	command=MilitaryCampaign.command_hierarchy
	columns=3;column_titles_visible=true;hide_root=true;select_mode=Tree.SELECT_MULTI
	set_column_title(0,"COMMAND");set_column_title(1,"PEOPLE" if service=="army" else "CRAFT");set_column_title(2,"ORDER")
	add_theme_font_size_override("title_button_font_size",14)
	var title_font:=get_theme_font("title_button_font")
	var title_width:=title_font.get_string_size(get_column_title(1),HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+24
	set_column_expand(1,false);set_column_custom_minimum_width(1,maxi(84,ceili(title_width)));set_column_custom_minimum_width(2,95)
	set_column_clip_content(0,true);set_column_clip_content(2,true)
	add_theme_font_size_override("font_size",14);add_theme_constant_override("v_separation",9)
	add_theme_color_override("font_color",T.BODY_2);add_theme_color_override("font_selected_color",T.GOLD_BRIGHT)
	add_theme_color_override("title_button_color",T.MUTED);add_theme_color_override("guide_color",T.BORDER_SOFT)
	add_theme_stylebox_override("panel",T.flat(Color("091216"),T.BORDER_2,1,5,4))
	add_theme_stylebox_override("selected",T.flat(T.GOLD_WASH,T.GOLD,1,3))
	add_theme_stylebox_override("selected_focus",T.flat(T.GOLD_WASH,T.GOLD_BRIGHT,1,3))
	custom_minimum_size.y=180;size_flags_vertical=Control.SIZE_EXPAND_FILL
	# Native Tree locks its items while dispatching a mouse selection. Populate
	# the expanded branch after that event, including when it came from a click.
	item_collapsed.connect(func(item:TreeItem):_expand_deferred.call_deferred(item.get_instance_id()))
	multi_selected.connect(_selection_changed)
	rebuild()
func _selection_changed(item:TreeItem,_column:int,selected:bool)->void:
	var entry:Dictionary=item.get_metadata(0)
	if not entry.has("id"):return
	if selected:_emit_selection(entry)
	elif active_selection.get("id","")==entry.get("id","") and active_selection.get("path",[])==entry.get("path",[]):_emit_selection({})
func _emit_selection(entry:Dictionary)->void:
	active_selection={} if entry.is_empty() else {"id":entry.id,"path":entry.path.duplicate()}
	command_selected.emit(entry)
func rebuild(retain:String="",path:Array=[])->void:
	_remember(get_root());command.sync();clear();var root:=create_item()
	var branch:=_actual(root,command.node(service));branch.collapsed=false
	if retain=="" or not _select_id(branch,retain,path):_emit_selection({})
	structure_signature=_structure()
func _select_id(item:TreeItem,id:String,path:Array=[],notify:bool=true)->bool:
	var meta:Dictionary=item.get_metadata(0)
	if meta.get("id","")==id and meta.get("path",[])==path:
		item.select(0)
		if notify:_emit_selection(meta)
		return true
	for child:TreeItem in item.get_children():
		if _select_id(child,id,path,notify):return true
	return false
func _actual(parent:TreeItem,record:Dictionary)->TreeItem:
	var item:=_row(parent,command.preview(String(record.id)))
	for child:Dictionary in command.children(String(record.id)):_actual(item,child)
	item.collapsed=not bool(expanded.get(String(record.id)+str([]),false));return item
func _row(parent:TreeItem,entry:Dictionary)->TreeItem:
	var item:=create_item(parent);item.set_metadata(0,entry)
	item.set_text(0,String(entry.name));item.set_text(1,str(entry.count))
	var mission:=String(entry.order.get("mission",""))
	item.set_text(2,"NO OBJECTIVE" if mission=="" else "HOLDING" if mission=="cancelled" else mission.replace("_"," ").to_upper())
	item.set_custom_color(2,T.MUTED if mission=="" else T.GOLD)
	item.set_tooltip_text(0,"%s · %s\nSelect a command to give its whole subtree an objective. Expand to inspect smaller formations." % [entry.name,entry.leader])
	if not entry.parts.is_empty():
		var placeholder:=create_item(item);placeholder.set_metadata(0,{"placeholder":true});placeholder.set_selectable(0,false);item.collapsed=true
		if bool(expanded.get(String(entry.id)+str(entry.path),false)):
			item.collapsed=false;_expanded(item)
	return item
func _expand_deferred(item_id:int)->void:
	# A refresh may have freed this row since the native click was dispatched.
	var item:=instance_from_id(item_id)
	if is_instance_valid(item) and item is TreeItem and item.get_tree()==self:_expanded(item)
func _expanded(item:TreeItem)->void:
	if not is_instance_valid(item) or item.collapsed:return
	var first:=item.get_first_child()
	if first==null or not (first.get_metadata(0) as Dictionary).get("placeholder",false):return
	first.free()
	var entry:Dictionary=item.get_metadata(0)
	for index in entry.parts.size():
		var path:Array=entry.path.duplicate();path.append(index)
		var child:Dictionary=command.preview(String(entry.id),path)
		if not child.is_empty():_row(item,child)
func selections()->Array:
	var result:Array=[];var current:=get_next_selected(null)
	while current!=null:
		var entry:Dictionary=current.get_metadata(0)
		if not entry.get("placeholder",false):result.append(entry)
		current=get_next_selected(current)
	return result
func refresh()->void:
	command.sync()
	var signature:=_structure()
	if signature!=structure_signature:
		var selected:=get_next_selected(null)
		var selected_rows:=selections()
		var retain:Dictionary=active_selection if not active_selection.is_empty() else selected.get_metadata(0) if selected!=null else {}
		rebuild(String(retain.get("id","")),retain.get("path",[]))
		for previous:Dictionary in selected_rows:_select_id(get_root().get_first_child(),String(previous.id),previous.path,false)
		return
	_update_counts(get_root())
func _structure()->String:
	var records:Array=[]
	for entry:Dictionary in command.data.nodes.values():
		if entry.service==service:records.append([entry.id,entry.parent,entry.force_id,entry.level])
	return str(records)
func _update_counts(item:TreeItem)->void:
	if item==null:return
	var entry:Variant=item.get_metadata(0)
	if entry is Dictionary and entry.has("id"):
		var current:Dictionary=command.preview(String(entry.id),entry.get("path",[]))
		if not current.is_empty():
			# Clicks must use the same strength and order that the row displays.
			item.set_metadata(0,current)
			item.set_text(1,str(current.count))
			var mission:=String(current.order.get("mission",""))
			item.set_text(2,"NO OBJECTIVE" if mission=="" else "HOLDING" if mission=="cancelled" else mission.replace("_"," ").to_upper())
			item.set_custom_color(2,T.MUTED if mission=="" else T.GOLD)
			if int(command.node(String(current.id)).get("force_id",-1))>=0:_refresh_parts(item,current)
	for child:TreeItem in item.get_children():_update_counts(child)
func _refresh_parts(item:TreeItem,current:Dictionary)->void:
	# Adjust only this force's virtual children; ordinary count changes keep
	# existing rows, expansion and scroll position instead of rebuilding.
	var children:=item.get_children();var expected:int=current.parts.size()
	if not children.is_empty() and (children[0].get_metadata(0) as Dictionary).get("placeholder",false):
		if expected==0:children[0].free()
		return
	while children.size()>expected:
		var removed:TreeItem=children.pop_back()
		if _contains_active(removed):_emit_selection({})
		removed.free()
	if children.is_empty() and expected>0 and item.collapsed:
		var placeholder:=create_item(item);placeholder.set_metadata(0,{"placeholder":true});placeholder.set_selectable(0,false);return
	for index in range(children.size(),expected):
		var path:Array=current.path.duplicate();path.append(index)
		_row(item,command.preview(String(current.id),path))
func _contains_active(item:TreeItem)->bool:
	var meta:Dictionary=item.get_metadata(0)
	if not active_selection.is_empty() and meta.get("id","")==active_selection.id and meta.get("path",[])==active_selection.path:return true
	for child:TreeItem in item.get_children():
		if _contains_active(child):return true
	return false
func _remember(item:TreeItem)->void:
	if item==null:return
	var entry:Variant=item.get_metadata(0)
	if entry is Dictionary and entry.has("id"):expanded[String(entry.id)+str(entry.get("path",[]))]=not item.collapsed
	for child:TreeItem in item.get_children():_remember(child)
