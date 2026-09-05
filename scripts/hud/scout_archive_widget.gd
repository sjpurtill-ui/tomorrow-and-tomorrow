extends VBoxContainer
const Model:=preload("res://scripts/scout_archive.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
var records:Array=[]
var view_state:Dictionary={}
var open_report:Callable
var search:LineEdit
var filter:OptionButton
var order:OptionButton
var results:VBoxContainer
var counter:Label
var previous:Button
var next:Button
var visible_items:Array=[]

func _ready()->void:
	add_theme_constant_override("separation",8)
	search=LineEdit.new(); search.name="ReportSearch"; search.placeholder_text="Search findings, party, place or day…"
	search.text=String(view_state.get("query","")); search.clear_button_enabled=true
	search.custom_minimum_size.y=34; add_child(search)
	var controls:=HBoxContainer.new(); add_child(controls)
	filter=OptionButton.new(); filter.name="ReportFilter"
	for label:String in Model.FILTERS: filter.add_item(label)
	filter.selected=int(view_state.get("filter",0)); controls.add_child(filter)
	order=OptionButton.new(); order.name="ReportOrder"; order.add_item("Significant first"); order.add_item("Newest first")
	order.selected=int(view_state.get("order",0)); order.size_flags_horizontal=Control.SIZE_EXPAND_FILL; controls.add_child(order)
	var pages:=HBoxContainer.new(); add_child(pages)
	previous=Button.new(); previous.text="‹ PREV"; previous.name="PreviousReports"; pages.add_child(previous)
	counter=T.make_label("",11,T.MUTED); counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL; counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; pages.add_child(counter)
	next=Button.new(); next.text="NEXT ›"; next.name="NextReports"; pages.add_child(next)
	results=VBoxContainer.new(); results.name="ReportResults"; results.add_theme_constant_override("separation",6); add_child(results)
	search.text_changed.connect(func(value:String)->void: view_state.query=value; view_state.page=0; rebuild())
	filter.item_selected.connect(func(index:int)->void: view_state.filter=index; view_state.page=0; rebuild())
	order.item_selected.connect(func(index:int)->void: view_state.order=index; view_state.page=0; rebuild())
	previous.pressed.connect(func()->void: view_state.page=int(view_state.get("page",0))-1; rebuild())
	next.pressed.connect(func()->void: view_state.page=int(view_state.get("page",0))+1; rebuild())
	rebuild()

func rebuild()->void:
	for child in results.get_children(): results.remove_child(child); child.queue_free()
	var selected:=Model.select(records,String(view_state.get("query","")),int(view_state.get("filter",0)),int(view_state.get("order",0))==0)
	var pages:=maxi(1,ceili(float(selected.size())/Model.PAGE_SIZE))
	var page:=clampi(int(view_state.get("page",0)),0,pages-1); view_state.page=page
	previous.disabled=page==0; next.disabled=page==pages-1
	counter.text="%d reports · %d / %d" % [selected.size(),page+1,pages]
	visible_items=selected.slice(page*Model.PAGE_SIZE,(page+1)*Model.PAGE_SIZE)
	if visible_items.is_empty():
		var empty:=T.make_label("No matching reports. Try another word or filter.",12,T.MUTED); empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; results.add_child(empty)
	for item:Dictionary in visible_items:
		var button:=Button.new(); button.name="Report_"+str(item.report.get("mission_id",0)); button.custom_minimum_size.y=92
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal",T.flat(T.ROW_BG,T.BORDER_SOFT,1,5))
		button.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,5))
		button.tooltip_text="%s
%s
%s
Open the full returned account; simulation speed is unchanged." % [item.title,item.place,item.detail]
		results.add_child(button)
		var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
		for side:String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,9)
		button.add_child(margin)
		var stack:=VBoxContainer.new(); stack.mouse_filter=Control.MOUSE_FILTER_IGNORE; stack.add_theme_constant_override("separation",4); margin.add_child(stack)
		var meta:="DAY %d · %s · %s%s" % [item.day,item.party,item.kind," · "+String(item.review) if item.review!="" else ""]
		var color:Color=T.RED if int(item.losses)>0 else (T.GOLD if bool(item.meaningful) else T.MUTED)
		var labels:Array=[T.make_label(meta,10,color),T.make_label(String(item.title),14,T.INK),T.make_label(String(item.place),11,T.TEXT_SOFT)]
		for label:Label in labels:
			label.mouse_filter=Control.MOUSE_FILTER_IGNORE; label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size.x=0; stack.add_child(label)
		button.pressed.connect(func()->void:
			Model.mark_reviewed(item.report)
			if open_report.is_valid(): open_report.call(item.report)
			rebuild())
