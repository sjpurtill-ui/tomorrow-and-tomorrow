extends Control
## THE BATTLE'S DAYS, as a track to scrub: a stop for the two sides drawn up
## and one for each day of fighting. Over each day, two small bars: the men
## each side lost that day (battle_record.gd losses_by_phase). The day shown
## is ringed; a battle still being fought marks today. Click a stop or drag
## along the track to move through the battle (hud/battle_panel.gd steps the
## field). Drawn on change only.

signal chosen(step:int)

const T:=preload("res://scripts/hud/hud_tokens.gd")
const PAD:=26.0
const BAR_ROOM:=22.0

var labels:Array=[]
## Per day (index 0 is day 1): {left, right} men lost.
var losses:Array=[]
## One plain line per stop, for pointing at it.
var tips:Array=[]
var selected:=0
## The stop that is today, for a battle still being fought; -1 when over.
var now:=-1
var left_colour:=Color("356f66")
var right_colour:=Color("a34435")
var _dragging:=false


func _init()->void:
	custom_minimum_size=Vector2(320,62)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	focus_mode=Control.FOCUS_NONE


func configure(stop_labels:Array,day_losses:Array,stop_tips:Array,shown:int,today:int)->void:
	labels=stop_labels; losses=day_losses; tips=stop_tips; selected=shown; now=today
	queue_redraw()


func select(index:int)->void:
	if index==selected: return
	selected=index
	queue_redraw()


func _stop_x(index:int)->float:
	var n:=maxi(1,labels.size()-1)
	return PAD+(size.x-PAD*2.0)*float(index)/float(n)


func _nearest(x:float)->int:
	var best:=0; var gap:=INF
	for i in labels.size():
		var d:=absf(_stop_x(i)-x)
		if d<gap: gap=d; best=i
	return best


func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
		_dragging=(event as InputEventMouseButton).pressed
		if _dragging: _choose((event as InputEventMouseButton).position.x)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_choose((event as InputEventMouseMotion).position.x)
		accept_event()


func _choose(x:float)->void:
	if labels.is_empty(): return
	var index:=_nearest(x)
	if index!=selected: chosen.emit(index)


func _get_tooltip(at:Vector2)->String:
	if labels.is_empty(): return ""
	var index:=_nearest(at.x)
	return String(tips[index]) if index<tips.size() else ""


func _draw()->void:
	if labels.is_empty(): return
	var line_y:=BAR_ROOM+8.0
	var font:=T.font("ui")
	var strong:=T.font("ui_strong")
	var first:=_stop_x(0); var last:=_stop_x(labels.size()-1)
	# The track reads on either paper; the days played so far in gold.
	draw_line(Vector2(first,line_y),Vector2(last,line_y),Color(T.INK_MUTED,0.4),4.0,true)
	draw_line(Vector2(first,line_y),Vector2(_stop_x(selected),line_y),T.GOLD,4.0,true)
	# The men lost each day, on one scale for the whole battle.
	var most:=1
	for pair in losses: most=maxi(most,maxi(int(pair.get("left",0)),int(pair.get("right",0))))
	for i in range(1,labels.size()):
		if i-1>=losses.size(): break
		var pair:Dictionary=losses[i-1]
		var x:=_stop_x(i)
		var bar:=clampf((size.x-PAD*2.0)/float(maxi(1,labels.size()-1))*0.16,3.0,9.0)
		var lh:=(BAR_ROOM-2.0)*float(pair.get("left",0))/float(most)
		var rh:=(BAR_ROOM-2.0)*float(pair.get("right",0))/float(most)
		if lh>0.0: draw_rect(Rect2(x-bar-1.0,line_y-6.0-lh,bar,lh),Color(left_colour,0.85))
		if rh>0.0: draw_rect(Rect2(x+1.0,line_y-6.0-rh,bar,rh),Color(right_colour,0.85))
	# The stops; every one lettered when there is room, else every few.
	var spacing:=(last-first)/float(maxi(1,labels.size()-1))
	var every:=maxi(1,ceili(64.0/maxf(1.0,spacing)))
	for i in labels.size():
		var x:=_stop_x(i)
		var shown:=i==selected
		draw_circle(Vector2(x,line_y),7.0 if shown else 5.0,T.PAPER_RAISED)
		draw_circle(Vector2(x,line_y),5.0 if shown else 3.6,T.GOLD if i<=selected else T.INK_MUTED)
		if shown: draw_arc(Vector2(x,line_y),9.0,0.0,TAU,24,T.GOLD,2.0,true)
		if i==now: draw_arc(Vector2(x,line_y),12.0,0.0,TAU,24,Color(T.RED,0.8),1.4,true)
		if i%every!=0 and not shown and i!=labels.size()-1: continue
		var text:=String(labels[i])
		var f:=strong if shown else font
		var width:=f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		var tx:=clampf(x-width*0.5,0.0,size.x-width)
		draw_string(f,Vector2(tx,line_y+24.0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK if shown else T.INK_MUTED)
