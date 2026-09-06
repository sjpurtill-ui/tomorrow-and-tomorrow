extends Control
## Observation only: no troop orders or visible tactical grid.
func _ready()->void:mouse_filter=MOUSE_FILTER_IGNORE
func _process(_delta:float)->void:queue_redraw()
func point(cell:Vector2i)->Vector2:
	return size*.5+Vector2(cell)*minf(size.x,size.y)/float(GeneralCampaign.RADIUS*2+4)
func _draw()->void:
	if GeneralCampaign.state.is_empty():return
	var state:Dictionary=GeneralCampaign.state
	var font:=ThemeDB.fallback_font
	draw_circle(point(Vector2i.ZERO),6,Color("e3c579"))
	draw_string(font,point(Vector2i.ZERO)+Vector2(10,-9),"Alderford",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f6e6b8"))
	for known:Dictionary in state.seen.values():
		var p:=point(known.home)
		draw_rect(Rect2(p-Vector2(6,6),Vector2(12,12)),Color("d58964"))
		draw_string(font,p+Vector2(-55,-13),String(known.name),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("f4d8c6"))
		var observed:=point(known.cell)
		draw_circle(observed,5,Color("de795e"))
		draw_string(font,observed+Vector2(9,20),"%d seen · day %d"%[int(known.troops),int(known.day)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e5c6b4"))
	var here:=point(state.cell)
	draw_circle(here,8,Color("73ddcc"))
	draw_arc(here,13,0,TAU,32,Color("c0fff0"),2)
	draw_string(font,here+Vector2(12,20),"%d fit soldiers"%int(GeneralCampaign.army().get("troops",0)),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("b8ffe9"))
	if not state.mission.is_empty():
		var destination:Vector2i=Vector2i.ZERO
		if state.mission.action in ["attack","besiege"]:destination=state.seen[String(state.mission.target)].home
		var path:Array=state.get("route",[])
		var last:=here
		for cell:Vector2i in path:
			var next:=point(cell);draw_line(last,next,Color("c1bc8099"),2);last=next
	draw_string(font,Vector2(18,size.y-38),"Local terrain • routes chosen by your general",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("c5d1c7"))
	draw_string(font,Vector2(18,size.y-17),"Enemy counters are dated observations, not live intelligence.",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a8bfb9"))
