extends Control
var fabric:="tannin"
var strength:=1.0
func _draw()->void:
	var faded:=Color("d9cfb8")
	var dyed:=Color("655749")
	var color:=faded.lerp(dyed,clampf(strength,0,1))
	draw_rect(Rect2(Vector2.ZERO,size),color if fabric!="calendered" else faded)
	if fabric=="resist":
		for i in range(3):draw_line(Vector2(i*size.x/3,0),Vector2((i+1)*size.x/3,size.y),faded,7)
	elif fabric=="printed":
		for x in range(4):
			for y in range(2):draw_circle(Vector2((x+.5)*size.x/4,(y+.5)*size.y/2),4,faded)
	elif fabric=="calendered":
		draw_rect(Rect2(Vector2(0,size.y*.3),Vector2(size.x,size.y*.25)),Color(1,1,1,.35*strength))
	draw_rect(Rect2(Vector2.ZERO,size),Color("80745f"),false,1)
