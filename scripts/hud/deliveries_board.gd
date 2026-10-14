extends VBoxContainer
## A live, bounded route record. The settlement model remains the owner of
## cargo, arrival dates, travel capacity and historical deliveries.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const PAGE_SIZE:=6
var data:Dictionary={}
var read:Callable
var clock:=0.0
var signature:=""
var columns:GridContainer
var summary:Label
var capacity:Label
var on_road:Dictionary={}
var arrived:Dictionary={}
var history_open:=false

func setup(block:Dictionary)->void:
	name="DeliveriesBoard";size_flags_horizontal=Control.SIZE_EXPAND_FILL;theme=T.control_theme();add_theme_constant_override("separation",16)
	read=block.get("read",Callable())
	summary=S.voice("",24);summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(summary)
	capacity=S.label("",14,T.INK_MUTED);capacity.name="TravelCapacity";capacity.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(capacity)
	columns=S.columns(self,"DeliveryColumns",420.0,2);columns.add_theme_constant_override("v_separation",24)
	on_road=_section("On the road","Shipments")
	arrived=_section("Recently arrived","Arrivals")
	resized.connect(_arrange)
	refresh(true)

func update_block(block:Dictionary)->bool:
	read=block.get("read",read);refresh();return true

func _process(delta:float)->void:
	clock+=delta
	if clock<1.0:return
	clock=0.0;refresh()

func refresh(force:=false)->void:
	if not read.is_valid():return
	var next:Dictionary=read.call()
	var changed:=str(hash([next,T.color_mode]))
	if not force and changed==signature:return
	signature=changed;data=next
	var travel:Dictionary=data.get("capacity",{})
	capacity.text="Leaders send spare stores along known paths · up to %s km · about %s km a day." % [Plain.number(float(travel.get("range_km",0.0))),Plain.number(float(travel.get("speed_km_per_day",0.0)))] if bool(travel.get("ready",false)) else String(travel.get("reason",""))
	_build_rows(on_road,false);_build_rows(arrived,true);_update_view()

func _section(title:String,key:String)->Dictionary:
	var box:=VBoxContainer.new();box.name=key;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",8);columns.add_child(box)
	box.add_child(S.label(title,20,T.INK,true))
	var search:=LineEdit.new();search.name="Find"+key;search.placeholder_text="Find a place or material";search.custom_minimum_size.y=40;box.add_child(search)
	var pager:=HFlowContainer.new();pager.name=key+"Pager";pager.add_theme_constant_override("h_separation",8);pager.add_theme_constant_override("v_separation",4);box.add_child(pager)
	var previous:=S.verb("‹",Callable(),"Previous "+title.to_lower());previous.name="Previous"+key;pager.add_child(previous)
	var count:=S.label("",14,T.INK_MUTED);count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pager.add_child(count)
	var next:=S.verb("›",Callable(),"Next "+title.to_lower());next.name="Next"+key;pager.add_child(next)
	var rows:=VBoxContainer.new();rows.name=key+"Rows";rows.add_theme_constant_override("separation",0);box.add_child(rows)
	var refs:={"box":box,"search":search,"pager":pager,"previous":previous,"next":next,"count":count,"rows":rows,"page":0,"query":""}
	var history:=key=="Arrivals"
	previous.disabled=false;next.disabled=false
	previous.pressed.connect(func()->void:refs.page-=1;_build_rows(refs,history))
	next.pressed.connect(func()->void:refs.page+=1;_build_rows(refs,history))
	search.text_changed.connect(func(words:String)->void:refs.query=words;refs.page=0;_build_rows(refs,history))
	if history:
		var toggle:=S.verb("Every arrival",func()->void:history_open=not history_open;_build_rows(refs,true);_update_view());toggle.name="EveryArrival";toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;box.add_child(toggle);refs.toggle=toggle
	return refs

func _build_rows(refs:Dictionary,history:bool)->void:
	for child:Node in refs.rows.get_children():refs.rows.remove_child(child);child.queue_free()
	var all_rows:Array=[]
	for row:Dictionary in data.get("history" if history else "shipments",[]):
		if not history or String(row.get("status",""))=="delivered":all_rows.append(row)
	if not history:all_rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.arrival_day)<float(b.arrival_day))
	var rows:Array=[]
	var query:="" if history and not history_open else String(refs.query).strip_edges().to_lower()
	for row:Dictionary in all_rows:
		var words:="%s %s %s" % [String(row.get("source_name","")),String(row.get("destination_name","")),String(row.get("resource",""))]
		if query.is_empty() or words.to_lower().contains(query):rows.append(row)
	var limit:=PAGE_SIZE if not history or history_open else 3
	var last:=maxi(0,ceili(float(rows.size())/limit)-1)
	var page_index:=clampi(int(refs.page),0,last) if not history or history_open else 0
	if not history or history_open:refs.page=page_index
	refs.search.visible=(all_rows.size()>PAGE_SIZE or not query.is_empty()) and (not history or history_open)
	refs.pager.visible=all_rows.size()>limit and (not history or history_open)
	refs.count.text="%d–%d of %d" % [page_index*limit+1,mini((page_index+1)*limit,rows.size()),rows.size()] if not rows.is_empty() else "No matches"
	refs.previous.disabled=page_index==0;refs.next.disabled=page_index>=last
	if history:
		refs.toggle.visible=history_open or all_rows.size()>3
		refs.toggle.text="Back to deliveries" if history_open else "Every arrival · %d" % all_rows.size()
		refs.box.move_child(refs.toggle,1 if history_open else refs.box.get_child_count()-1)
	var today:=int(data.get("day",0))
	for row:Dictionary in rows.slice(page_index*limit,(page_index+1)*limit):
		var left:=maxi(0,ceili(float(row.get("arrival_day",today)))-today)
		var ago:=maxi(0,today-int(row.get("day",today)))
		var when:=("Today" if ago==0 else Plain.span_text(ago)+" ago") if history else ("Arrives today" if left==0 else "In "+Plain.span_text(left))
		var entry:=S.row(refs.rows,{"id":str(refs.rows.get_child_count()),"icon":String(row.get("resource","")),"label":"%s %s" % [Plain.number(float(row.get("delivered" if history else "quantity",0.0))),String(row.get("resource","")).to_lower()],"value":when,"note":"%s → %s" % [String(row.get("source_name","")),String(row.get("destination_name",""))],"tip":"%s · %s → %s" % [when,String(row.get("source_name","")),String(row.get("destination_name",""))]})
		var skin:StyleBoxFlat=entry.panel.get_theme_stylebox("panel").duplicate();skin.border_width_bottom=0;entry.panel.add_theme_stylebox_override("panel",skin)
	if rows.is_empty():
		var empty:=S.label("No matching deliveries." if not query.is_empty() else ("No arrival recorded yet." if history else "Nothing is on the road just now."),14,T.INK_MUTED);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;refs.rows.add_child(empty)
	_arrange.call_deferred()

func _update_view()->void:
	on_road.box.visible=not history_open
	capacity.visible=not history_open
	if history_open:
		var count:=0
		for row:Dictionary in data.get("history",[]):
			if String(row.get("status",""))=="delivered":count+=1
		summary.text="%d arrivals recorded" % count
	else:
		var ships:Array=data.get("shipments",[])
		summary.text="%d %s on the road" % [ships.size(),"delivery" if ships.size()==1 else "deliveries"] if not ships.is_empty() else "Nothing on the road just now"
	(arrived.box.get_child(0) as Label).text="Arrival archive" if history_open else "Recently arrived"
	_arrange.call_deferred()

func _arrange()->void:
	if columns==null:return
	var available:=size.x
	var ancestor:=get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			available=minf(available,maxf(0.0,ancestor.size.x-24.0));break
		ancestor=ancestor.get_parent()
	S.flow(columns,available)
	if history_open:columns.columns=1
	S.compact(self,available)
