extends Control
signal selected(id:String)
var nodes:Array[Dictionary]=[]
var spots:Array[Vector2]=[]
var selection:="player"
func _ready()->void:
	custom_minimum_size=Vector2(450,320); mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
func update_nodes(data:Array[Dictionary])->void:
	nodes=data; queue_redraw()
func _draw()->void:
	spots.clear()
	var center:=size*.5
	for i in nodes.size():
		var angle:=TAU*float(i-1)/maxi(1,nodes.size()-1)-PI*.5
		spots.append(center if i==0 else center+Vector2(cos(angle)*size.x*.34,sin(angle)*size.y*.34))
	for i in range(1,nodes.size()):
		var color:=Color("cf786b") if nodes[i].war else (Color("e9c672") if nodes[i].treaty=="trade" else (Color("7dc5b6") if nodes[i].treaty=="non_aggression" else Color("536774")))
		draw_line(center,spots[i],color,4 if nodes[i].treaty!="none" else 1,true)
	for i in nodes.size():
		var p:=spots[i]
		draw_circle(p,17,Color("e9c672") if nodes[i].id==selection else Color("7da9b7"))
		draw_circle(p,12,Color("1b3540"))
		var name:String=nodes[i].name
		var font:=ThemeDB.fallback_font
		var width:=font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(font,p+Vector2(-width*.5,34),name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ecf1e9"))
	if nodes.size()==1: draw_string(ThemeDB.fallback_font,Vector2(20,30),"New contacts will appear here when encountered.",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("9eafb6"))
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for i in spots.size():
			if event.position.distance_to(spots[i])<44:
				selection=nodes[i].id; selected.emit(selection); queue_redraw(); return
