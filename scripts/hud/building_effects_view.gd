extends GridContainer
## All primary effects visible together. No selected-row detail browser.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Icons=preload("res://scripts/resource_icons.gd")
const Pair=preload("res://scripts/hud/comparison_tile.gd")
var readings:Array=[]
func setup(items:Array)->void:
	name="BuildingEffects";readings=items
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("h_separation",12);add_theme_constant_override("v_separation",12)
	for item:Dictionary in items:add_child(_tile(item))
	resized.connect(_fit);_fit.call_deferred()
func _fit()->void:columns=3 if size.x>=960 else (2 if size.x>=480 else 1)
func _label(text:String,points:int,color:Color)->Label:
	var label:=T.make_label(text,points,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label
func _number(n:float)->String:
	if absf(n)>=1000000:return "%.1fm"%(n/1000000)
	if absf(n)>=10000:return "%.1fk"%(n/1000)
	return ("%.2f"%n).trim_suffix("0").trim_suffix("0").trim_suffix(".")
func _tile(item:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name=String(item.id);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",T.paper_panel_style(false,T.RADIUS_CARD,12))
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);panel.add_child(body)
	var pair:=Pair.new();body.add_child(pair)
	pair.fill(item.title,item.left_label,item.left,item.right_label,item.right,item.unit,"",item.get("tip",""))
	# Exact comparisons remain in metadata/tooltips, compact readings at empire scale.
	pair.values[0].text=_number(float(item.left));pair.values[1].text=_number(float(item.right))
	pair.values[0].tooltip_text=str(item.left)+" "+String(item.unit);pair.values[1].tooltip_text=str(item.right)+" "+String(item.unit)
	pair.mark.visible=true;pair.mark.custom_minimum_size=Vector2(28,28)
	var icon:=String(item.get("icon","homes"))
	pair.mark.texture=Icons.moment_texture(icon,T.GOLD,32) if icon in ["birth","sickness","fire","death"] else (Icons.domain_texture("health",T.TEAL) if icon=="health" else Icons.town_texture(icon,T.TEAL,32))
	if not String(item.get("status","")).is_empty():
		var status:=_label(String(item.status),14,T.RED if bool(item.get("bad",false)) else T.TEAL);status.name="Status";body.add_child(status)
	for effect:Dictionary in item.get("effects",[]):
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);body.add_child(row)
		var caption:=_label(effect.label,13,T.INK_MUTED);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(caption)
		var value:=_label(String(effect.value),18,T.TEAL);value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(value);row.tooltip_text=String(effect.get("tip",""))
	return panel
