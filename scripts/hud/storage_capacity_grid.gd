extends VBoxContainer
## Retained, always-visible per-type capacity. No aggregate can conceal a full
## store; controls dispatch to the selected city's construction queue.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
var tiles:Dictionary={}
var grid:GridContainer
var action:Callable

func _init()->void:
	name="StorageCapacityGrid"
	add_theme_constant_override("separation",6)
	add_child(S.label("STORAGE · towns expand at 80% full",14,T.INK_MUTED,true))
	grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",10);add_child(grid)
	resized.connect(func():grid.columns=3 if size.x>=900 else 2 if size.x>=530 else 1)

func fill(rows:Array,callback:Callable)->void:
	action=callback
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
			tiles[kind]={"box":box,"button":button,"amount":amount,"bar":bar,"status":status}
		var tile:Dictionary=tiles[kind]
		var over:=float(row.used)>float(row.capacity)
		S.put(tile.amount,"%s / %s %s%s" % [S.n(float(row.used)),S.n(float(row.capacity)),String(row.unit)," · OVERFLOW" if over else ""],T.RED_TEXT if over else T.INK)
		tile.bar.value=clampf(float(row.used)/maxf(1,float(row.capacity))*100,0,100)
		S.put(tile.status,String(row.status),T.INK_MUTED)
		tile.button.disabled=bool(row.pending)
		tile.button.text="Queued" if bool(row.pending) else "+ Space"
		tile.button.tooltip_text=String(row.tip)
