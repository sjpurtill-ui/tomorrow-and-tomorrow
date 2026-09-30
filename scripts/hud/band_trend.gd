extends Control
## A band's last months on its Readiness row: strength as the ink line,
## supply as the pale line beneath (0-100%), from the samples home knows of
## (field_sustainment.trend_known). The tooltip says the numbers.

const T:=preload("res://scripts/hud/hud_tokens.gd")

var samples:Array=[]

func _ready()->void:
	custom_minimum_size=Vector2(84,22);mouse_filter=Control.MOUSE_FILTER_STOP

func set_samples(known:Array)->void:
	samples=known
	tooltip_text=words(known)
	visible=known.size()>=2
	queue_redraw()

## "Last 45 days: 820 men, now 640. Supply 90%, now 55%. Will 80%, now 62%."
static func words(known:Array)->String:
	if known.size()<2: return ""
	var first:Array=known[0]; var last:Array=known[-1]
	var days:=int(last[0])-int(first[0])
	return "The last %d days: %d men, now %d. Supply %d%%, now %d%%. Will to fight %d%%, now %d%%." % [days,int(first[1]),int(last[1]),int(first[2]),int(last[2]),int(first[3]),int(last[3])]

func _draw()->void:
	if samples.size()<2: return
	var box:=Rect2(Vector2(2,3),size-Vector2(4,6))
	draw_line(Vector2(box.position.x,box.end.y),box.end,Color(T.RULE_STRONG,0.6),1.0)
	var most:=1
	for s:Array in samples: most=maxi(most,int(s[1]))
	var first_day:=float(int((samples[0] as Array)[0]))
	var span:=maxf(1.0,float(int((samples[-1] as Array)[0]))-first_day)
	var men:=PackedVector2Array(); var fed:=PackedVector2Array()
	for s:Array in samples:
		var x:=box.position.x+box.size.x*(float(int(s[0]))-first_day)/span
		men.append(Vector2(x,box.end.y-box.size.y*float(int(s[1]))/float(most)))
		fed.append(Vector2(x,box.end.y-box.size.y*clampf(float(int(s[2]))/100.0,0.0,1.0)))
	draw_polyline(fed,Color(T.INK_MUTED,0.55),1.2,true)
	draw_polyline(men,T.INK,1.6,true)
	draw_circle(men[-1],2.0,T.INK)
