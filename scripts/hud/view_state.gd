extends RefCounted
## Keeps what the player is looking at across a panel rebuild: every
## ScrollContainer's offset, the focused control, and any widget's own view
## state (a page number, how many entries are shown). Nodes are addressed by
## child-index path from the root, because rebuilt nodes get fresh auto names.
##
## Scroll offsets are re-applied for a few frames after a rebuild: new content
## has no size until the containers sort, so a single immediate assignment is
## clamped to a short scroll range and the panel snaps to the top.

const SETTLE_FRAMES:=6

static func capture(root:Node)->Dictionary:
	var state:={"scroll":{},"widgets":{},"focus":""}
	if root==null or not is_instance_valid(root):return state
	_walk(root,"",state)
	if root.is_inside_tree():
		var owner:=root.get_viewport().gui_get_focus_owner()
		if owner!=null and (owner==root or root.is_ancestor_of(owner)):state.focus=_path(root,owner)
	return state

static func restore(root:Node,state:Dictionary)->void:
	if root==null or not is_instance_valid(root) or state.is_empty():return
	var widgets:Dictionary=state.get("widgets",{})
	for key:String in widgets:
		var widget:=resolve(root,key)
		if widget!=null and widget.has_method("restore_view_state"):widget.restore_view_state(widgets[key])
	var focus:=String(state.get("focus",""))
	if focus!="" and root.is_inside_tree():
		var owner:=root.get_viewport().gui_get_focus_owner()
		var target:=resolve(root,focus) as Control
		if (owner==null or not owner.is_inside_tree()) and target!=null and target.focus_mode!=Control.FOCUS_NONE and target.is_visible_in_tree():
			target.grab_focus()
	_settle_scrolls(root,state.get("scroll",{}))

static func resolve(root:Node,key:String)->Node:
	var node:=root
	if key=="":return node
	for part in key.split("/"):
		var index:=int(part)
		if node==null or index>=node.get_child_count():return null
		node=node.get_child(index)
	return node

static func _walk(node:Node,key:String,state:Dictionary)->void:
	if node is ScrollContainer:
		var scroll:=node as ScrollContainer
		if scroll.scroll_vertical!=0 or scroll.scroll_horizontal!=0:
			state.scroll[key]=Vector2i(scroll.scroll_horizontal,scroll.scroll_vertical)
	if node.has_method("view_state"):state.widgets[key]=node.view_state()
	for index in node.get_child_count():
		_walk(node.get_child(index),(key+"/" if key!="" else "")+str(index),state)

static func _path(root:Node,node:Node)->String:
	var parts:PackedStringArray=[]
	while node!=root and node!=null:
		parts.insert(0,str(node.get_index()));node=node.get_parent()
	return "/".join(parts)

static func _settle_scrolls(root:Node,scrolls:Dictionary)->void:
	if scrolls.is_empty():return
	var applied:Dictionary={}
	for frame in SETTLE_FRAMES+1:
		if frame>0:
			if not is_instance_valid(root) or not root.is_inside_tree():return
			await root.get_tree().process_frame
			if not is_instance_valid(root):return
		for key:String in scrolls:
			var scroll:=resolve(root,key) as ScrollContainer
			if scroll==null:continue
			if applied.has(key) and applied[key]==null:continue
			var now:=Vector2i(scroll.scroll_horizontal,scroll.scroll_vertical)
			var target:Vector2i=scrolls[key]
			if applied.has(key) and now!=(applied[key] as Vector2i):
				# A layout pass that shortened the range clamps the offset; that
				# is not the player. Any other change is theirs and wins.
				var bar:=scroll.get_v_scroll_bar()
				var clamped:=now.y<target.y and float(now.y)>=bar.max_value-bar.page-1.0
				if not clamped:
					applied[key]=null;continue
			scroll.scroll_horizontal=target.x;scroll.scroll_vertical=target.y
			applied[key]=Vector2i(scroll.scroll_horizontal,scroll.scroll_vertical)
