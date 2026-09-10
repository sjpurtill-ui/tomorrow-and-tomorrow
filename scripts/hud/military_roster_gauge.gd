extends ProgressBar
## Small pictorial meters retain exact values in the adjacent live labels.
var ink:=Color("89bca9")
var mode:="segments"
var marks:=10
func _ready()->void:
	show_percentage=false;mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("background",StyleBoxEmpty.new());add_theme_stylebox_override("fill",StyleBoxEmpty.new())
	custom_minimum_size=Vector2(70,21)
	value_changed.connect(func(_value:float):queue_redraw())
	resized.connect(queue_redraw)
func _draw()->void:
	var count:=maxi(1,marks);var step:=size.x/count
	for index in count:
		var fraction:=clampf(value/100.0*count-index,0,1)
		var color:=Color("30434a").lerp(ink,fraction)
		var x:=step*(index+.5)
		if mode=="people":
			draw_circle(Vector2(x,4),2.5,color)
			draw_line(Vector2(x,10),Vector2(x,19),color,4,true)
			draw_line(Vector2(x-3,11),Vector2(x+3,11),color,2,true)
		elif mode=="chevrons":
			draw_polyline(PackedVector2Array([Vector2(x-step*.34,14),Vector2(x,6),Vector2(x+step*.34,14)]),color,3,true)
		else:
			var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(2)
			draw_style_box(style,Rect2(index*step+1,6,maxf(1,step-3),10))
