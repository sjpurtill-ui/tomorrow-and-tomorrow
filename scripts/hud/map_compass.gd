extends Button
## A small drawn compass rose for the map toolbar. The needle points to where
## north lies on screen; clicking it turns the map back to north-up.
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const ARROW_ANGLES:={"→":0.0,"↘":45.0,"↓":90.0,"↙":135.0,"←":180.0,"↖":225.0,"↑":270.0,"↗":315.0}
var north_angle:=-PI*0.5

func _init()->void:
	name="MapCompass"
	text=""
	custom_minimum_size=Vector2(34,32)
	focus_mode=Control.FOCUS_NONE
	add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
	add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	var hover:=Tokens.flat(Tokens.GOLD_WASH,Color(0,0,0,0),0,Tokens.RADIUS_CONTROL)
	add_theme_stylebox_override("hover",hover)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

## Takes the eight-way screen arrow the map reports for north.
func set_north(arrow:String)->void:
	var angle:=deg_to_rad(float(ARROW_ANGLES.get(arrow,270.0)))
	if is_equal_approx(angle,north_angle):return
	north_angle=angle
	queue_redraw()

func _draw()->void:
	var center:=size*0.5
	var radius:=minf(size.x,size.y)*0.5-3.0
	var ink:=Tokens.INK if is_hovered() else Tokens.BODY
	draw_arc(center,radius,0.0,TAU,32,Tokens.RULE_STRONG,1.0,true)
	for quarter in 4:
		var direction:=Vector2.from_angle(north_angle+quarter*PI*0.5)
		draw_line(center+direction*(radius-3.0),center+direction*radius,Tokens.RULE_STRONG,1.0,true)
	var forward:=Vector2.from_angle(north_angle)
	var side:=forward.orthogonal()*3.2
	var tip:=center+forward*(radius-4.0)
	var tail:=center-forward*(radius-6.0)
	draw_colored_polygon(PackedVector2Array([tip,center+side,center-side]),Tokens.GOLD)
	draw_colored_polygon(PackedVector2Array([tail,center-side,center+side]),ink.lerp(Tokens.PAPER,0.35))
	draw_circle(center,1.6,ink)
