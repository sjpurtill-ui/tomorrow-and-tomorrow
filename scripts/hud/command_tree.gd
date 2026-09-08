extends Tree
## Lazy, expandable echelons. Browsing never splits or recruits a force.
signal command_selected(selection:Dictionary)
var service:="army"
var command:RefCounted
var structure_signature:=""
var expanded:Dictionary={}
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
	custom_minimum_size.y=220;size_flags_vertical=Control.SIZE_EXPAND_FILL
	# Native Tree locks its items while dispatching a mouse selection. Populate
	# the expanded branch after that event, including when it came from a click.
	item_collapsed.connect(func(item:TreeItem):_expand_deferred.call_deferred(item.get_instance_id()))
	multi_selected.connect(func(item:TreeItem,_column:int,selected:bool):if selected:command_selected.emit(item.get_metadata(0)))
	rebuild()
func rebuild(retain:String="")->void:
	_remember(get_root());command.sync();clear();var root:=create_item()
	var branch:=_actual(root,command.node(service));branch.collapsed=false
	if retain!="":_select_id(branch,retain)
	structure_signature=_structure()
func _select_id(item:TreeItem,id:String)->void:
	var meta:Dictionary=item.get_metadata(0)
	if meta.get("id","")==id and meta.get("path",[]).is_empty():item.select(0);command_selected.emit(meta)
	for child:TreeItem in item.get_children():_select_id(child,id)
func _actual(parent:TreeItem,record:Dictionary)->TreeItem:
	var item:=_row(parent,command.preview(String(record.id)))
	for child:Dictionary in command.children(String(record.id)):_actual(item,child)
	item.collapsed=not bool(expanded.get(String(record.id)+str([]),false));return item
func _row(parent:TreeItem,entry:Dictionary)->TreeItem:
	var item:=create_item(parent);item.set_metadata(0,entry)
	item.set_text(0,String(entry.name));item.set_text(1,str(entry.count))
	var mission:=String(entry.order.get("mission",""))
	item.set_text(2,"Unassigned" if mission=="" else "Holding" if mission=="cancelled" else mission.replace("_"," ").capitalize())
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
		var retain:=String((selected.get_metadata(0) as Dictionary).get("id","")) if selected!=null else ""
		rebuild(retain);return
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
			item.set_text(1,str(current.count))
			var mission:=String(current.order.get("mission",""))
			item.set_text(2,"Unassigned" if mission=="" else "Holding" if mission=="cancelled" else mission.replace("_"," ").capitalize())
	for child:TreeItem in item.get_children():_update_counts(child)
func _remember(item:TreeItem)->void:
	if item==null:return
	var entry:Variant=item.get_metadata(0)
	if entry is Dictionary and entry.has("id"):expanded[String(entry.id)+str(entry.get("path",[]))]=not item.collapsed
	for child:TreeItem in item.get_children():_remember(child)
