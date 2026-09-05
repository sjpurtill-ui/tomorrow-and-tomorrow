extends VBoxContainer
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Plot:=preload("res://scripts/hud/trend_plot.gd")
static var selected_ranges:Dictionary={}
var data:Dictionary={}
var graph:Control
var buttons:Array[Button]=[]
const RANGES:=[365,3650,36500,0]
func setup(value:Dictionary)->void:
	data=value
	add_theme_constant_override("separation",8)
	var controls:=HBoxContainer.new()
	add_child(controls)
	for index in RANGES.size():
		var button:=Button.new()
		button.text=["1 YEAR","10 YEARS","100 YEARS","ALL"][index]
		button.toggle_mode=true
		button.add_theme_font_size_override("font_size",10)
		button.pressed.connect(_select.bind(index))
		controls.add_child(button)
		buttons.append(button)
	graph=Plot.new()
	add_child(graph)
	var legend:=HFlowContainer.new()
	legend.add_theme_constant_override("h_separation",14)
	add_child(legend)
	for line in data.series: legend.add_child(Tokens.make_label("● "+String(line.label),11,line.color))
	var note:=Tokens.make_label(String(data.get("description","")),11,Tokens.MUTED)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
	_select(int(selected_ranges.get(data.id,1)))
func _select(index:int)->void:
	selected_ranges[data.id]=index
	if selected_ranges.size()>1024: selected_ranges.erase(selected_ranges.keys()[0])
	for i in buttons.size(): buttons[i].set_pressed_no_signal(i==index)
	var rows:Array=data.get("items",[])
	var visible_rows:Array=[]
	var end_day:=int(rows[-1].day) if not rows.is_empty() else 0
	for row in rows:
		if RANGES[index]==0 or int(row.day)>=end_day-RANGES[index]: visible_rows.append(row)
	graph.configure(visible_rows,data.series,String(data.unit))
