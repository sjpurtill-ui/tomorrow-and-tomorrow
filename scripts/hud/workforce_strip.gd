extends Control
## One reconciled visual for the existing assigned workforce. Selection only;
## assignment remains in the People screen's guarded command handlers.
const T=preload("res://scripts/hud/hud_tokens.gd")
const ROLES=preload("res://scripts/manual_work.gd").ROLES
const COLORS=[Color("84b879"),Color("b5b274"),Color("b4977c"),Color("bf955c"),Color("a1a7bd"),Color("79abb6"),Color("ab96c6"),Color("83baa8"),Color("c98d82")]
signal picked(role:String)
var counts:Dictionary={}
var names:Dictionary={}
var selected:=""
var changes:Dictionary={}
var segments:Array[Dictionary]=[]
func _init()->void:
	name="AssignedWorkforce";custom_minimum_size=Vector2(180,32);size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
func fill(current:Dictionary,labels:Dictionary,focus:String,deltas:Dictionary)->void:
	counts=current.duplicate();names=labels;selected=focus;changes=deltas.duplicate();queue_redraw()
func _parts()->Array[Dictionary]:
	var result:Array[Dictionary]=[];var total:=0
	for role:String in ROLES:total+=maxi(0,int(counts.get(role,0)))
	if total<=0:return result
	var x:=0.0
	for index in ROLES.size():
		var role:String=ROLES[index];var count:=maxi(0,int(counts.get(role,0)))
		if count<=0:continue
		var width:=size.x*float(count)/total
		result.append({"role":role,"count":count,"rect":Rect2(x,0,width,size.y),"color":COLORS[index]});x+=width
	return result
func _draw()->void:
	segments=_parts()
	for part:Dictionary in segments:
		var rect:Rect2=part.rect
		draw_rect(rect,Color(part.color,0.4))
		draw_line(rect.position+Vector2(0,2),Vector2(rect.end.x,2),part.color,3)
		if String(part.role)==selected:draw_rect(rect.grow(-1),T.INK,false,2)
		var label:="%s %d" % [String(names.get(part.role,part.role)).get_slice(" ",0),int(part.count)]
		var font:=T.font("ui");var width:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		if width+8<=rect.size.x:draw_string(font,Vector2(rect.position.x+(rect.size.x-width)/2,21),label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK)
func _get_tooltip(at:Vector2)->String:
	for part:Dictionary in _parts():
		if (part.rect as Rect2).has_point(at):return "%s · %d assigned%s" % [names.get(part.role,part.role),int(part.count)," · last change %+d" % int(changes[part.role]) if changes.has(part.role) else ""]
	return "Assigned workers only. All military manpower belongs to Defense."
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for part:Dictionary in _parts():
			if (part.rect as Rect2).has_point(event.position):picked.emit(String(part.role));accept_event();return
