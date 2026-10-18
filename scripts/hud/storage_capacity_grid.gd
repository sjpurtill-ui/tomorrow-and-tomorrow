extends VBoxContainer
## Retained, always-visible per-type capacity. No aggregate can conceal a full
## store; controls dispatch to the selected city's construction queue.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Dense=preload("res://scripts/hud/dense_blocks.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
var tiles:Dictionary={}
var grid:GridContainer
var action:Callable
var builders:Callable

func _init()->void:
	name="StorageCapacityGrid"
	add_theme_constant_override("separation",6)
	var head:=HBoxContainer.new();add_child(head)
	var label:=S.label("STORAGE · towns expand at 80% full",14,T.INK_MUTED,true);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;head.add_child(label)
	head.add_child(S.verb("Builders",func():if builders.is_valid():builders.call(),"Assign people to construction"))
	grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",10);add_child(grid)
	resized.connect(func():grid.columns=3 if size.x>=900 else 2 if size.x>=530 else 1)

func fill(rows:Array,callback:Callable,assign_builders:Callable=Callable())->void:
	action=callback;builders=assign_builders
	visible=not rows.is_empty()
	for row:Dictionary in rows:
		var kind:=String(row.kind)
		if not tiles.has(kind):
			var box:=VBoxContainer.new();box.name="Store_"+kind;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",3);grid.add_child(box)
			var head:=HBoxContainer.new();box.add_child(head)
			var label:=S.label(String(row.label),15,T.INK,true);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(label)
			var button:=S.verb("+ Space",func():if action.is_valid():action.call(kind));button.name="Expand_"+kind;head.add_child(button)
			var amount:=S.label("",14,T.INK);box.add_child(amount)
			var bar:=ProgressBar.new();bar.custom_minimum_size.y=6;bar.show_percentage=false;box.add_child(bar)
			var status:=S.label("",13,T.INK_MUTED);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(status)
			var gain:=S.label("",13,T.TEAL);gain.name="CapacityGain";gain.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(gain)
			var bill:=HFlowContainer.new();bill.name="ExpansionBill";bill.add_theme_constant_override("h_separation",8);box.add_child(bill)
			var work:=ProgressBar.new();work.name="BuilderProgress";work.custom_minimum_size.y=5;work.show_percentage=false;box.add_child(work)
			tiles[kind]={"box":box,"button":button,"amount":amount,"bar":bar,"status":status,"gain":gain,"bill":bill,"cost_signature":[],"work":work}
		var tile:Dictionary=tiles[kind]
		var over:=float(row.used)>float(row.capacity)
		S.put(tile.amount,"%s / %s %s%s" % [S.n(float(row.used)),S.n(float(row.capacity)),String(row.unit)," · OVERFLOW" if over else ""],T.RED_TEXT if over else T.INK)
		tile.bar.value=clampf(float(row.used)/maxf(1,float(row.capacity))*100,0,100)
		S.put(tile.status,String(row.status),T.AMBER_TEXT if String(row.status).begins_with("Needs") else T.INK_MUTED)
		S.put(tile.gain,"Capacity %s → %s · %s builder-work" % [S.n(float(row.capacity)),S.n(float(row.get("capacity_after",float(row.capacity)+float(row.get("added",0))))),S.n(float(row.get("work_required",0)))])
		var costs:Array=row.get("costs",[])
		if tile.cost_signature!=costs:
			for child in tile.bill.get_children():tile.bill.remove_child(child);child.queue_free()
			for cost:Dictionary in costs:
				var chip:=Dense.cost_chip(String(cost.resource),float(cost.have),float(cost.need));chip.tooltip_text="Available / expansion cost";tile.bill.add_child(chip)
			tile.cost_signature=costs.duplicate(true)
		tile.work.visible=float(row.get("work_done",0))>0
		tile.work.max_value=maxf(0.001,float(row.get("work_required",1)));tile.work.value=float(row.get("work_done",0))
		tile.button.disabled=bool(row.get("requested",false)) or bool(row.get("building",false))
		tile.button.text="Building" if bool(row.get("building",false)) else "Queued" if bool(row.get("requested",false)) else "Build first" if bool(row.pending) else "+ Space"
		tile.button.tooltip_text=String(row.tip)
