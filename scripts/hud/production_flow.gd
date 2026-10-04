extends Control
## The Production screen's centrepiece: what the makers' hands make today,
## from what, and what it does for us, drawn as an inked chart on paper.
##
##   from the stores        at the benches            what it makes
##   (material marks)  ==>  (the benches, by era)  ==>  (homes, barter, the
##                                                      watch, each line)
##
## Each ribbon's width is the day's real flow (dock_content_production.gd
## flow_model, the engine's numbers); grains run along it, more of them the
## more it carries. A material a bench wants and cannot get is a dry, broken
## ribbon with a red mark and its words ("no flint: arms stalled").
##
## Cheap by design: the chart (ribbons, marks, words) is drawn once per data
## or size change; only the grains layer redraws, about 30 times a second,
## and only while the chart is visible in the tree.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")

## Which benches a page shows: "all", "civilian" (household benches) or
## "military" (arms and the workshop lines).
var mode:="all"
var model:Dictionary={}
## Laid-out nodes: id -> {pos, r, kind, ...}; ribbons: [{points (centre), width, ...}].
var _nodes:={}
var _ribbons:Array=[]
var _grains:Grains
var _laid_for:=Vector2.ZERO

const MATERIAL_TINT:={"Timber":Color("#6f8a3e"),"Fiber Plants":Color("#86a85a"),"Clay":Color("#b06a3e"),"Stone":Color("#8a8f8c"),"Flint":Color("#4a4f52"),
	"Copper Ore":Color("#c0703a"),"Tin Ore":Color("#9aa3a8"),"Iron Ore":Color("#9a4a36"),"Coal":Color("#2f3236"),"Spun Yarn":Color("#a89060"),"Woven Cloth":Color("#a89060")}
const OUTPUT_TINT:={"homes":Color("#536d32"),"barter":Color("#8a6118"),"watch":Color("#a34435"),"gear":Color("#4d6389")}
const MIN_RIBBON:=2.5
const MAX_RIBBON:=26.0
const NODE_R:=17.0
const BENCH_R:=30.0

func _init()->void:
	custom_minimum_size=Vector2(560,250)
	mouse_filter=Control.MOUSE_FILTER_PASS
	tooltip_text=" "
	clip_contents=true
	_grains=Grains.new();_grains.name="Grains";_grains.flow=self
	_grains.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grains.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(_grains)

func set_model(next:Dictionary,page:String="all")->void:
	mode=page;model=next
	custom_minimum_size.y=_wanted_height()
	_laid_for=Vector2.ZERO
	queue_redraw()

func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED:_laid_for=Vector2.ZERO;queue_redraw()

# --- What this page shows -----------------------------------------------------------

func _benches()->Array:
	var keep:Array=[]
	for bench:Dictionary in model.get("benches",[]):
		var id:=String(bench.id)
		if mode=="civilian" and id!="goods":continue
		if mode=="military" and id=="goods":continue
		keep.append(bench)
	return keep

func _bench_ids()->Array:
	var ids:Array=[]
	for bench:Dictionary in _benches():ids.append(String(bench.id))
	return ids

func _links()->Array:
	var ids:=_bench_ids()
	var keep:Array=[]
	for link:Dictionary in model.get("links",[]):
		if String(link.to) in ids or String(link.from) in ids:keep.append(link)
	return keep

func _materials()->Array:
	var used:={}
	var ids:=_bench_ids()
	for link:Dictionary in model.get("links",[]):
		if String(link.to) in ids:used[String(link.from)]=true
	var keep:Array=[]
	for material:Dictionary in model.get("materials",[]):
		if used.has(String(material.resource)):keep.append(material)
	return keep.slice(0,7)

func _outputs()->Array:
	var targets:={}
	var ids:=_bench_ids()
	for link:Dictionary in model.get("links",[]):
		if String(link.from) in ids:targets[String(link.to)]=true
	var keep:Array=[]
	for output:Dictionary in model.get("outputs",[]):
		if targets.has(String(output.id)):keep.append(output)
	return keep.slice(0,6)

func _wanted_height()->float:
	if _benches().is_empty():return 64.0
	var rows:=maxi(maxi(_materials().size(),_outputs().size()),2)
	# Each bench wants room for its mark and its two lines of words.
	return clampf(maxf(72.0+rows*46.0,40.0+_benches().size()*118.0),250.0,440.0)

# --- Layout ---------------------------------------------------------------------------

func _layout()->void:
	if _laid_for==size:return
	_laid_for=size
	_nodes.clear();_ribbons.clear()
	var top:=40.0;var bottom:=size.y-16.0
	var left_x:=minf(size.x*.26,210.0)
	var right_x:=size.x-minf(size.x*.26,200.0)
	var mid_x:=(left_x+right_x)*.5
	var materials:=_materials();var benches:=_benches();var outputs:=_outputs()
	for i in materials.size():
		var m:Dictionary=materials[i]
		_nodes[String(m.resource)]={"pos":Vector2(left_x,_row_y(i,materials.size(),top,bottom)),"r":NODE_R,"side":"material","data":m}
	for i in benches.size():
		var b:Dictionary=benches[i]
		_nodes[String(b.id)]={"pos":Vector2(mid_x,_row_y(i,benches.size(),top,bottom-34.0,130.0)),"r":BENCH_R,"side":"bench","data":b}
	for i in outputs.size():
		var o:Dictionary=outputs[i]
		_nodes[String(o.id)]={"pos":Vector2(right_x,_row_y(i,outputs.size(),top,bottom)),"r":NODE_R,"side":"output","data":o}
	# Ribbon widths: materials in on one scale, what comes out on another
	# (a good is not a load of timber); the square root keeps a trickle visible.
	var links:=_links()
	var most_in:=0.0;var most_out:=0.0
	for link:Dictionary in links:
		if _nodes.get(String(link.from),{}).get("side","")=="material":most_in=maxf(most_in,float(link.per_day))
		else:most_out=maxf(most_out,float(link.per_day))
	# Stack the ribbons where they meet a bench so they enter side by side.
	var enter:={};var leave:={}
	for link:Dictionary in links:
		var a:Dictionary=_nodes.get(String(link.from),{});var b:Dictionary=_nodes.get(String(link.to),{})
		if a.is_empty() or b.is_empty():continue
		var dry:=bool(link.get("dry",false))
		var top_flow:=most_in if String(a.side)=="material" else most_out
		var width:=MIN_RIBBON if dry or top_flow<=0.0 or float(link.per_day)<=0.0 else lerpf(MIN_RIBBON+1.5,MAX_RIBBON,sqrt(float(link.per_day)/top_flow))
		_ribbons.append({"link":link,"from":a,"to":b,"width":width,"dry":dry,"tint":_tint(link,a,b)})
	for ribbon:Dictionary in _ribbons:
		var key_in:=String(ribbon.link.to);var key_out:=String(ribbon.link.from)
		enter[key_in]=float(enter.get(key_in,0.0))+float(ribbon.width)+2.0
		leave[key_out]=float(leave.get(key_out,0.0))+float(ribbon.width)+2.0
	var enter_at:={};var leave_at:={}
	for ribbon:Dictionary in _ribbons:
		var a:Dictionary=ribbon.from;var b:Dictionary=ribbon.to
		var key_in:=String(ribbon.link.to);var key_out:=String(ribbon.link.from)
		var w:=float(ribbon.width)
		var out_y:=-float(leave[key_out])*.5+float(leave_at.get(key_out,0.0))+w*.5+1.0
		leave_at[key_out]=float(leave_at.get(key_out,0.0))+w+2.0
		var in_y:=-float(enter[key_in])*.5+float(enter_at.get(key_in,0.0))+w*.5+1.0
		enter_at[key_in]=float(enter_at.get(key_in,0.0))+w+2.0
		var start:Vector2=(a.pos as Vector2)+Vector2(float(a.r)+3.0,clampf(out_y,-float(a.r)*1.6,float(a.r)*1.6))
		var finish:Vector2=(b.pos as Vector2)+Vector2(-float(b.r)-3.0,clampf(in_y,-float(b.r)*1.4,float(b.r)*1.4))
		ribbon.points=_curve(start,finish,18)

func _row_y(index:int,count:int,top:float,bottom:float,most:float=64.0)->float:
	if count<=1:return (top+bottom)*.5
	var step:=minf((bottom-top)/float(count),most)
	var span:=step*float(count-1)
	return (top+bottom)*.5-span*.5+step*float(index)

func _curve(a:Vector2,b:Vector2,steps:int)->PackedVector2Array:
	var points:=PackedVector2Array()
	var pull:=(b.x-a.x)*.5
	for i in steps+1:
		var t:=float(i)/float(steps)
		points.append(a.bezier_interpolate(a+Vector2(pull,0),b-Vector2(pull,0),b,t))
	return points

func _tint(link:Dictionary,a:Dictionary,b:Dictionary)->Color:
	if String(a.side)=="material":return MATERIAL_TINT.get(String(link.from),T.RULE_STRONG)
	var kind:=String((b.data as Dictionary).get("kind",""))
	return OUTPUT_TINT.get(kind,T.GOLD)

# --- Drawing --------------------------------------------------------------------------

func _draw()->void:
	_layout()
	var frame:=Rect2(Vector2.ZERO,size)
	draw_rect(frame,T.PAPER_RAISED)
	# A chart's double rule.
	draw_rect(frame.grow(-3.0),Color(T.RULE_STRONG,.55),false,1.0)
	draw_rect(frame.grow(-6.0),Color(T.RULE,.45),false,1.0)
	var font:=T.font("ui");var strong:=T.font("ui_strong")
	if _nodes.is_empty():
		var words:=_idle_words()
		var fit:=15
		while fit>12 and font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fit).x>size.x-28.0:fit-=1
		_text(font,words,Vector2(size.x*.5,size.y*.5+5.0),fit,T.INK_MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		return
	# Column captions, like the legend on an engraved chart.
	var captions:=[["FROM THE STORES","material"],["AT THE BENCHES","bench"],["WHAT IT MAKES","output"]]
	for caption:Array in captions:
		var x:=_column_x(String(caption[1]))
		if x<0.0:continue
		_text(strong,String(caption[0]),Vector2(x,24.0),12,T.GOLD_TEXT,HORIZONTAL_ALIGNMENT_CENTER)
	for ribbon:Dictionary in _ribbons:_draw_ribbon(ribbon)
	for id:String in _nodes:_draw_node(_nodes[id],font,strong)
	for ribbon:Dictionary in _ribbons:
		if bool(ribbon.dry):_draw_break(ribbon,font)

## What an empty chart says: why nothing is made on this page today.
func _idle_words()->String:
	if mode=="military":
		return "No arms or gear in the making today: the watch has the arms it wants and no workshop line is working."
	return "Nothing is being made today."

func _column_x(side:String)->float:
	for id:String in _nodes:
		if String(_nodes[id].side)==side:return float((_nodes[id].pos as Vector2).x)
	return -1.0

func _draw_ribbon(ribbon:Dictionary)->void:
	var points:PackedVector2Array=ribbon.points
	var w:=float(ribbon.width)
	var tint:Color=ribbon.tint
	if bool(ribbon.dry):
		# Dry: a thin dashed trace, broken in the middle.
		var half:=points.size()/2
		for i in range(0,points.size()-1):
			if absi(i-half)<=1:continue
			if i%2==0:draw_line(points[i],points[i+1],Color(T.RED,.75),1.6,true)
		return
	var upper:=PackedVector2Array();var lower:=PackedVector2Array()
	for i in points.size():
		var tangent:=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
		var normal:=Vector2(-tangent.y,tangent.x)*w*.5
		upper.append(points[i]+normal);lower.append(points[i]-normal)
	var shape:=upper.duplicate()
	for i in range(lower.size()-1,-1,-1):shape.append(lower[i])
	draw_colored_polygon(shape,Color(tint,.30))
	# Inked edges, a touch darker than the wash.
	draw_polyline(upper,Color(tint.darkened(.35),.85),1.2,true)
	draw_polyline(lower,Color(tint.darkened(.35),.85),1.2,true)

func _draw_break(ribbon:Dictionary,font:Font)->void:
	var points:PackedVector2Array=ribbon.points
	var mid:=points[points.size()/2]
	var r:=6.0
	draw_circle(mid,r+3.0,T.PAPER_RAISED)
	draw_line(mid+Vector2(-r,-r),mid+Vector2(r,r),T.RED,2.4,true)
	draw_line(mid+Vector2(-r,r),mid+Vector2(r,-r),T.RED,2.4,true)
	var words:=String(ribbon.link.get("words",""))
	if words.is_empty():return
	var at:=mid+Vector2(0,-12)
	var width:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	draw_rect(Rect2(at+Vector2(-width*.5-5,-14),Vector2(width+10,18)),Color(T.PAPER_RAISED,.92))
	_text(font,words,at,13,T.RED_TEXT,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_node(node:Dictionary,font:Font,strong:Font)->void:
	var pos:Vector2=node.pos
	var r:=float(node.r)
	var data:Dictionary=node.data
	match String(node.side):
		"material":
			var low:=data.has("days_left") and float(data.days_left)<90.0
			_disc(pos,r,T.RED if low else T.RULE_STRONG)
			_icon(Icons.material_texture(String(data.resource),48),pos,r*1.5)
			var x:=pos.x-r-8.0
			_text(strong,String(data.name),Vector2(x,pos.y-2),14,T.INK,HORIZONTAL_ALIGNMENT_RIGHT)
			var note:=Plain.number(float(data.amount))+" in store"
			var tone:=T.INK_MUTED
			if low:note="runs out in "+Plain.span_text(float(data.days_left));tone=T.RED_TEXT
			_text(font,note,Vector2(x,pos.y+14),13,tone,HORIZONTAL_ALIGNMENT_RIGHT)
		"bench":
			var stalled:=String(data.get("stalled",""))!=""
			draw_circle(pos,r+5.0,Color(T.GOLD,.10))
			_disc(pos,r,T.RED if stalled else T.GOLD)
			draw_arc(pos,r+4.0,0,TAU,48,Color(T.GOLD if not stalled else T.RED,.45),1.0,true)
			_icon(Icons.workshop_texture(String(data.kind),T.INK,64),pos,r*1.55)
			var hands:=float(data.get("hands",0.0))
			var sub:=("%s %s" % [Plain.number(hands),"maker" if is_equal_approx(hands,1.0) else "makers"]) if hands>=0.05 else "no makers"
			if stalled:sub+=" · "+String(data.stalled)
			# A paper plate under the bench's words, so ribbons pass behind them.
			var plate_w:=maxf(strong.get_string_size(String(data.name),HORIZONTAL_ALIGNMENT_LEFT,-1,14).x,font.get_string_size(sub,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)+14.0
			draw_rect(Rect2(pos+Vector2(-plate_w*.5,r+4),Vector2(plate_w,36)),Color(T.PAPER_RAISED,.94))
			_text(strong,String(data.name),pos+Vector2(0,r+18),14,T.INK,HORIZONTAL_ALIGNMENT_CENTER)
			_text(font,sub,pos+Vector2(0,r+34),13,T.RED_TEXT if stalled else T.INK_MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		"output":
			var kind:=String(data.get("kind",""))
			var tint:Color=OUTPUT_TINT.get(kind,T.GOLD)
			_disc(pos,r,tint)
			var texture:=Icons.equipment_texture(String(data.item),T.INK,T.GOLD,48) if kind=="gear" else Icons.workshop_texture(kind,T.INK,48)
			_icon(texture,pos,r*1.5)
			var x:=pos.x+r+8.0
			var per_day:=float(data.get("per_day",0.0))
			_text(strong,_rate(per_day,String(data.get("unit",""))),Vector2(x,pos.y-2),14,T.INK if per_day>0.0 else T.INK_MUTED,HORIZONTAL_ALIGNMENT_LEFT)
			_text(font,String(data.name).to_lower() if kind!="gear" else String(data.name),Vector2(x,pos.y+14),13,T.INK_MUTED,HORIZONTAL_ALIGNMENT_LEFT)

static func _rate(per_day:float,unit:String)->String:
	if per_day<=0.0:return "none today"
	var said:=Plain.rate_short(per_day)
	return said if unit.is_empty() else said.replace(" a ",(" %s a " % unit))

func _disc(pos:Vector2,r:float,ring:Color)->void:
	draw_circle(pos,r,T.PAPER)
	draw_arc(pos,r,0,TAU,40,ring,1.8,true)

func _icon(texture:Texture2D,pos:Vector2,side:float)->void:
	if texture==null:return
	draw_texture_rect(texture,Rect2(pos-Vector2(side,side)*.5,Vector2(side,side)),false)

func _text(font:Font,text:String,at:Vector2,font_size:int,color:Color,align:int)->void:
	var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var x:=at.x
	if align==HORIZONTAL_ALIGNMENT_CENTER:x-=width*.5
	elif align==HORIZONTAL_ALIGNMENT_RIGHT:x-=width
	draw_string(font,Vector2(x,at.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

# --- Tooltips: the engine's sentences ---------------------------------------------------

func _get_tooltip(at:Vector2)->String:
	_layout()
	for id:String in _nodes:
		var node:Dictionary=_nodes[id]
		if at.distance_to(node.pos)<=float(node.r)+10.0 or _label_box(node).has_point(at):return _node_tip(node)
	for ribbon:Dictionary in _ribbons:
		var points:PackedVector2Array=ribbon.points
		for point in points:
			if at.distance_to(point)<=maxf(6.0,float(ribbon.width)*.5+2.0):return _ribbon_tip(ribbon)
	return ""

func _label_box(node:Dictionary)->Rect2:
	var pos:Vector2=node.pos
	match String(node.side):
		"material":return Rect2(pos+Vector2(-170,-18),Vector2(170,40))
		"output":return Rect2(pos+Vector2(0,-18),Vector2(170,40))
	return Rect2(pos+Vector2(-90,float(node.r)),Vector2(180,40))

func _node_tip(node:Dictionary)->String:
	var data:Dictionary=node.data
	match String(node.side):
		"material":
			var lines:PackedStringArray=["%s: %s in store." % [String(data.name),Plain.number(float(data.amount))]]
			var used:=0.0
			for link:Dictionary in model.get("links",[]):
				if String(link.from)==String(data.resource):used+=float(link.per_day)
			if used>0.0:lines.append("The benches drew about %s a day today." % Plain.number(used))
			var trend:=float(data.get("trend",0.0))
			if absf(trend)>=.01:lines.append("%s about %s a day over the last %s." % ["Up" if trend>0.0 else "Down",Plain.number(absf(trend)),Plain.span_text(float(data.get("trend_days",7)))])
			if data.has("days_left"):lines.append("At that pace it runs out in %s." % Plain.span_text(float(data.days_left)))
			return "\n".join(lines)
		"bench":
			var lines:PackedStringArray=[String(data.name)]
			var hands:=float(data.get("hands",0.0))
			lines.append("%s makers at work here." % Plain.number(hands))
			var per_day:=float(data.get("per_day",0.0))
			match String(data.id):
				"goods":lines.append("They made %s goods today: tools, baskets, pots and fittings for the homes, and goods to barter." % Plain.number(per_day))
				"arms":
					lines.append("They made %s sets of arms today; the watch still wants %d." % [Plain.number(per_day),int(data.get("wanted",0))])
				"lines":lines.append("The workshop lines make the bands' gear, one product a line.")
			if String(data.get("stalled",""))!="":lines.append("Stalled: %s." % String(data.stalled))
			return "\n".join(lines)
		"output":
			var per_day:=float(data.get("per_day",0.0))
			match String(data.get("kind","")):
				"homes":return "For the homes: %s goods a day replace what wears out and fill the households' stores." % Plain.number(per_day)
				"barter":return "For barter: %s goods a day beyond what the homes need, made only from materials the builders can spare." % Plain.number(per_day)
				"watch":return "Arms for the watch: %s sets a day, kept in store until the watch takes them up." % Plain.number(per_day)
				"gear":return "%s: %s. %d in store%s." % [String(data.name),Plain.rate_text(per_day),int(data.get("stock",0)),(", keeping %d" % int(data.target)) if int(data.get("target",0))>0 else ""]
	return ""

func _ribbon_tip(ribbon:Dictionary)->String:
	var link:Dictionary=ribbon.link
	var from:Dictionary=(ribbon.from as Dictionary).data
	var to:Dictionary=(ribbon.to as Dictionary).data
	if bool(ribbon.dry):return _cap(String(link.get("words","")))+"."
	return "%s to %s: about %s a day." % [String(from.get("name","")),String(to.get("name","")).to_lower(),Plain.number(float(link.per_day))]

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)


## The grains moving along the ribbons: the only part redrawn each frame,
## at about 30 a second, and only while the chart is on screen.
class Grains extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var flow:Control
	var clock:=0.0
	var _since:=0.0
	func _ready()->void:set_process(is_visible_in_tree())
	func _notification(what:int)->void:
		if what==NOTIFICATION_VISIBILITY_CHANGED:set_process(is_visible_in_tree())
	func _process(delta:float)->void:
		clock+=delta;_since+=delta
		if _since<1.0/30.0:return
		_since=0.0
		queue_redraw()
	func _draw()->void:
		if flow==null:return
		for ribbon:Dictionary in flow._ribbons:
			if bool(ribbon.dry) or not ribbon.has("points"):continue
			var per_day:=float(ribbon.link.per_day)
			if per_day<=0.0:continue
			var points:PackedVector2Array=ribbon.points
			# More grains on a fuller ribbon: the eye reads the rate.
			var count:=clampi(ceili(sqrt(per_day)*2.0),1,9)
			var speed:=0.16+0.04*minf(per_day,4.0)
			var w:=float(ribbon.width)
			var grain:=clampf(w*.16,1.4,3.2)
			var ink:=Color(T.INK,.62)
			for i in count:
				var t:=fposmod(clock*speed+float(i)/float(count)+float(ribbon.width)*.013,1.0)
				var at:=_along(points,t)
				# Spread across the ribbon a little, the same each pass.
				var offset:=(float((i*37)%7)/6.0-.5)*w*.45
				draw_circle(at+Vector2(0,offset),grain,ink)
	static func _along(points:PackedVector2Array,t:float)->Vector2:
		var f:=t*float(points.size()-1)
		var i:=clampi(floori(f),0,points.size()-2)
		return points[i].lerp(points[i+1],f-float(i))
