extends VBoxContainer
## Functional capacity is primary and bounded by category, regardless of population.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Icons=preload("res://scripts/resource_icons.gd")
const S=preload("res://scripts/hud/econ_sheet.gd")
var spread:BoxContainer
var capacity:GridContainer
var cells:Dictionary={}
var jobs:VBoxContainer
var data:Dictionary={}
var lanes:Array=[]
var builders:Label
var assign:Button
func _init()->void:
	name="TownContext";add_theme_constant_override("separation",10)
	spread=BoxContainer.new();spread.add_theme_constant_override("separation",18);add_child(spread)
	capacity=GridContainer.new();capacity.size_flags_horizontal=SIZE_EXPAND_FILL;capacity.add_theme_constant_override("h_separation",14);capacity.add_theme_constant_override("v_separation",12);spread.add_child(capacity)
	jobs=VBoxContainer.new();jobs.size_flags_horizontal=SIZE_EXPAND_FILL;jobs.size_flags_stretch_ratio=.6;jobs.add_theme_constant_override("separation",8);spread.add_child(jobs)
	builders=T.make_label("",16,T.INK);builders.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;jobs.add_child(builders)
	for i in 2:
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",3);jobs.add_child(box)
		var heading:=T.make_label("",15,T.INK);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(heading)
		var bar:=ProgressBar.new();bar.custom_minimum_size.y=7;bar.show_percentage=false;bar.max_value=1;box.add_child(bar)
		bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(T.TEAL))
		var note:=T.make_label("",13,T.INK_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(note)
		lanes.append({"box":box,"heading":heading,"bar":bar,"note":note})
	assign=_action(jobs,"Assign builders","on_assign")
	_action(jobs,"Manage storage","on_storage")
	resized.connect(_fit)
func _action(parent:Node,title:String,key:String)->Button:
	var button:=Button.new();button.text=title;T.apply_button_style(button);parent.add_child(button)
	button.pressed.connect(func():var action:Callable=data.get(key,Callable());if action.is_valid():action.call())
	return button
func setup(block:Dictionary)->void:update_block(block)
func update_block(block:Dictionary)->bool:
	data=block
	for cell:Dictionary in cells.values():cell.box.hide()
	for row:Dictionary in block.get("capacity",[]):_capacity(row)
	builders.text="%d builders · %d on civic work" % [int(block.get("builders",0)),roundi(float(block.get("civic_builders",0)))]
	var work:Array=block.get("work",[])
	for i in 2:
		var lane:Dictionary=lanes[i];lane.box.visible=i<work.size() or i==0
		var job:Dictionary=work[i] if i<work.size() else {}
		lane.heading.text=("Now · " if i==0 else "Waiting priority · ")+String(job.get("name","No known civic work waiting"))
		lane.bar.visible=not job.is_empty();lane.bar.value=float(job.get("progress",{}).get("ratio",0))
		lane.note.text=String(job.get("sub","Homes, repairs and other builder jobs remain separate."))
	assign.disabled=not (block.get("on_assign",Callable()) as Callable).is_valid()
	_fit();return true
func _capacity(row:Dictionary)->void:
	var id:=String(row.id)
	if not cells.has(id):
		var box:=VBoxContainer.new();box.custom_minimum_size.x=160;box.size_flags_horizontal=SIZE_EXPAND_FILL;capacity.add_child(box)
		var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",5);box.add_child(heading)
		var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(20,20);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;heading.add_child(icon)
		icon.texture=Icons.town_texture("homes" if id=="housing" else "stores",T.INK,24) if id not in ["drinking","water","food"] else Icons.material_texture("Food" if id=="food" else "Freshwater",24)
		var title:=T.make_label("",14,T.INK);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.size_flags_horizontal=SIZE_EXPAND_FILL;heading.add_child(title)
		var value:=T.make_label("",19,T.INK);box.add_child(value)
		var unit:=T.make_label("",12,T.INK_MUTED);unit.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(unit)
		var bar:=ProgressBar.new();bar.custom_minimum_size.y=5;bar.show_percentage=false;box.add_child(bar)
		bar.add_theme_stylebox_override("background",T.flat(T.TRACK))
		var gap:=T.make_label("",12,T.INK_MUTED);gap.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(gap)
		cells[id]={"box":box,"title":title,"value":value,"unit":unit,"bar":bar,"gap":gap}
	var cell:Dictionary=cells[id];cell.box.show();cell.title.text=String(row.name);cell.unit.text=String(row.unit)
	var known:bool=row.get("used") is float or row.get("used") is int
	known=known and (row.get("capacity") is float or row.get("capacity") is int)
	cell.bar.visible=known
	if not known:cell.value.text="Not measured";cell.gap.text="No daily reading yet";return
	var used:=float(row.used);var room:=float(row.capacity);var excess:=used-room
	cell.value.text="%s / %s" % [_quantity(used),_quantity(room)]
	cell.bar.max_value=maxf(1,maxf(used,room));cell.bar.value=used
	cell.bar.add_theme_stylebox_override("fill",T.flat(T.RED if excess>0 else T.TEAL))
	cell.gap.text="%s %s" % [_quantity(absf(excess)),String(row.over if excess>0 else row.under)]
	if float(row.get("incoming",0))>0:cell.gap.text+=" · %s incoming" % _quantity(float(row.incoming))
	cell.box.tooltip_text="%s: %.2f / %.2f %s" % [row.name,used,room,row.unit]
func _fit()->void:
	spread.vertical=size.x<900
	capacity.columns=3 if size.x>=650 else 2 if size.x>=360 else 1
	jobs.custom_minimum_size.x=0 if spread.vertical else 220

static func _quantity(value:float)->String:
	for scale:Array in [[1000000000.0,"b"],[1000000.0,"m"],[10000.0,"k"]]:
		if absf(value)>=float(scale[0]):
			var divisor:=1000.0 if String(scale[1])=="k" else float(scale[0])
			return ("%.2f" % (value/divisor)).trim_suffix("0").trim_suffix("0").trim_suffix(".")+String(scale[1])
	return S.n(value)
