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
	theme=T.control_theme()
	search=LineEdit.new(); search.name="ReportSearch"; search.placeholder_text="Search for a place, a find or a people…"
	T.text(search,"body",T.INK)
	search.text=String(view_state.get("query","")); search.clear_button_enabled=true
	search.custom_minimum_size.y=34; add_child(search)
	var controls:=HBoxContainer.new(); add_child(controls)
	filter=OptionButton.new(); filter.name="ReportFilter"
	for label:String in Model.FILTERS: filter.add_item(label)
	filter.selected=int(view_state.get("filter",0)); T.text(filter,"small",T.INK); controls.add_child(filter)
	order=OptionButton.new(); order.name="ReportOrder"; order.add_item("Significant first"); order.add_item("Newest first")
	order.selected=int(view_state.get("order",0)); T.text(order,"small",T.INK); order.size_flags_horizontal=Control.SIZE_EXPAND_FILL; controls.add_child(order)
	var pages:=HBoxContainer.new(); add_child(pages)
	previous=Button.new(); previous.text="Previous"; previous.name="PreviousReports"; T.text(previous,"small",T.INK); pages.add_child(previous)
	counter=T.make_label("",12,T.INK_MUTED); T.text(counter,"small",T.INK_MUTED); counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL; counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; pages.add_child(counter)
	next=Button.new(); next.text="Next"; next.name="NextReports"; T.text(next,"small",T.INK); pages.add_child(next)
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
	counter.text="%d reports · page %d of %d" % [selected.size(),page+1,pages]
	visible_items=selected.slice(page*Model.PAGE_SIZE,(page+1)*Model.PAGE_SIZE)
	if visible_items.is_empty():
		var empty:=T.make_label("No reports match. Try another word or show all reports.",12,T.INK_MUTED); T.text(empty,"small",T.INK_MUTED); empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; results.add_child(empty)
	for item:Dictionary in visible_items:
		var button:=Button.new(); button.name="Report_"+str(item.report.get("mission_id",0)); button.custom_minimum_size.y=92
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal",T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD))
		button.add_theme_stylebox_override("hover",T.flat(T.PAPER,T.RULE_STRONG,1,T.RADIUS_CARD))
		button.add_theme_stylebox_override("pressed",T.flat(T.PAPER_SUNK,T.RULE_STRONG,1,T.RADIUS_CARD))
		button.tooltip_text="%s
%s
%s
Read the whole telling." % [item.title,item.place,item.detail]
		results.add_child(button)
		var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
		for side:String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,9)
		button.add_child(margin)
		var stack:=VBoxContainer.new(); stack.mouse_filter=Control.MOUSE_FILTER_IGNORE; stack.add_theme_constant_override("separation",4); margin.add_child(stack)
		var review:=String(item.review)
		var meta:="%s · %s · %s%s" % [Model.calendar_date(int(item.day)),item.party,item.kind," · "+("Not yet read" if review=="UNREAD" else "Read") if review!="" else ""]
		var color:Color=T.RED_TEXT if int(item.losses)>0 else (T.GOLD_TEXT if bool(item.meaningful) else T.INK_MUTED)
		var labels:Array=[T.text(Label.new(),"small",color),T.text(Label.new(),"body",T.INK),T.text(Label.new(),"small",T.BODY)]
		labels[0].text=meta; labels[1].text=String(item.title); labels[2].text=String(item.place)
		for label:Label in labels:
			label.mouse_filter=Control.MOUSE_FILTER_IGNORE; label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size.x=0; stack.add_child(label)
		button.pressed.connect(func()->void:
			Model.mark_reviewed(item.report)
			if open_report.is_valid(): open_report.call(item.report)
			rebuild())
