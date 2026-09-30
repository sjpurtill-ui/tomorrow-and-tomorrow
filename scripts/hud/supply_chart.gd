extends Control
## The supply map's ink (hud/supply_map.gd draws the wash beneath it): our
## roads in heavy ink; the carts' reach dotted round the hubs; each band's
## and garrison's supply line back to its hub, heavy where it keeps a road
## and dashed across country; home, our towns and the towns we hold ringed
## as hubs; and on every band and garrison a small sack and bar, its share
## of a day's food in the colour of its state. A pointer on a mark, a hub
## or the land gives the numbers in plain words (the key card draws them).
## Observe-only: clicks go through to the map.

const Supply:=preload("res://scripts/supply_state.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
## The wash's own colours (supply_wash.gdshader), for the key's swatches.
const WELL:=Color("#6e8a4a")
const SHORT:=Color("#bd923a")
const STARVE:=Color("#9a4236")
const PLATE_W:=34.0
const PLATE_H:=13.0
const SACK_PX:=12.0
const HOVER_EVERY:=0.12

var terrain:Node
var key_card:Control
## World data from the last paint (supply_map.gd): routes [{points, heights,
## road (PackedByteArray), id}], reach [{points, heights}], hubs [{pos, h,
## kind, name}], marks [{id, pos, h, report}], roads [{a, b, ha, hb, tier}].
var routes:Array=[]
var reach:Array=[]
var hubs:Array=[]
var marks:Array=[]
var roads:Array=[]
var troops:=30
var lines_alpha:=1.0
var _drawn:=-1
var _hover_id:=""
var _hover_elapsed:=0.0
var _land_tip:Dictionary={}
## A mark or hub clicked: its note stays until the next click elsewhere.
var pinned_id:=""
var _pinned_tip:Dictionary={}
var _pinned_at:=Vector2.ZERO
## Counters for probes (never saved).
var redraws:=0

static var _sacks:Dictionary={}


func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_data(data:Dictionary)->void:
	routes=data.get("routes",[]); reach=data.get("reach",[]); hubs=data.get("hubs",[])
	marks=data.get("marks",[]); roads=data.get("roads",[]); troops=int(data.get("troops",30))
	_drawn=-1


func _camera()->Camera3D:
	if not is_instance_valid(terrain): return null
	var c:Variant=terrain.get("camera")
	return c if is_instance_valid(c) and c is Camera3D else null


func _process(delta:float)->void:
	var camera:=_camera()
	if camera==null: return
	var covered:=is_instance_valid(terrain.get("world_globe"))
	visible=not covered
	if covered: return
	lines_alpha=smoothstep(18.0,60.0,camera.size)
	_hover_elapsed+=delta
	if _hover_elapsed>=HOVER_EVERY:
		_hover_elapsed=0.0
		_update_hover()
	var signature:=hash([camera.global_transform,camera.size,camera.fov,get_viewport_rect().size,_hover_id,routes.size(),marks.size(),lines_alpha])
	if signature==_drawn: return
	_drawn=signature
	redraws+=1
	queue_redraw()


# --- Projection ----------------------------------------------------------------

func _screen(p:Vector2,h:float)->Vector2:
	var camera:=_camera()
	var world:=Vector3(p.x,h,p.y)
	if camera==null or camera.is_position_behind(world): return Vector2.INF
	return camera.unproject_position(world)

func _screen_line(points:PackedVector2Array,heights:PackedFloat32Array)->PackedVector2Array:
	var out:=PackedVector2Array()
	for i in points.size():
		var s:=_screen(points[i],heights[i] if i<heights.size() else 0.0)
		if s.is_finite(): out.append(s)
	return out


# --- Drawing -------------------------------------------------------------------

func _draw()->void:
	if _camera()==null: return
	var a:=lines_alpha
	if a>0.01:
		# Our roads: the heavy ink of the network.
		for r:Dictionary in roads:
			var sa:=_screen(r.a,float(r.get("ha",0.0))); var sb:=_screen(r.b,float(r.get("hb",0.0)))
			if not sa.is_finite() or not sb.is_finite(): continue
			draw_line(sa,sb,Color(PAPER,0.55*a),6.0,true)
			draw_line(sa,sb,Color(INK,0.78*a),2.6,true)
		# The carts' reach: a dotted ring, lettered once.
		var label_at:=Vector2.INF
		var clear:=_clear_rect()
		var middle:=clear.get_center()
		for line:Dictionary in reach:
			var pts:=_screen_line(line.points,line.heights)
			_dotted(pts,Color(INK,0.72*a),1.5,7.0)
			# Lettered only where the ring is large enough to carry a word.
			var extent:=Rect2(pts[0],Vector2.ZERO) if not pts.is_empty() else Rect2()
			for p in pts: extent=extent.expand(p)
			if maxf(extent.size.x,extent.size.y)<260.0: continue
			for p in pts:
				if clear.has_point(p) and (not label_at.is_finite() or p.distance_squared_to(middle)<label_at.distance_squared_to(middle)): label_at=p
		# The supply lines.
		for route:Dictionary in routes: _draw_route(route,a)
		if label_at.is_finite(): _label(label_at+Vector2(0,-8),"the carts' reach",a)
	# Hubs: our stores, and the towns we hold as depots.
	for hub:Dictionary in hubs:
		var s:=_screen(hub.pos,float(hub.get("h",0.0)))
		if not s.is_finite(): continue
		var held:=String(hub.kind)=="held"
		draw_circle(s,12.5,Color(PAPER,0.35))
		draw_arc(s,12.0,0.0,TAU,40,Color(INK,0.85),1.4,true)
		if not held: draw_arc(s,9.0,0.0,TAU,32,Color(INK,0.7),1.0,true)
		else:
			for k in 4:
				var d:=Vector2.from_angle(TAU*float(k)/4.0+PI*0.25)
				draw_line(s+d*12.0,s+d*15.5,Color(INK,0.85),1.3,true)
	# Every band and garrison: its sack and bar.
	for mark:Dictionary in marks: _draw_plate(mark)


func _draw_route(route:Dictionary,a:float)->void:
	var points:PackedVector2Array=route.points
	var heights:PackedFloat32Array=route.heights
	var road:PackedByteArray=route.road
	var pts:=PackedVector2Array(); var on:=PackedByteArray()
	for i in points.size():
		var s:=_screen(points[i],heights[i] if i<heights.size() else 0.0)
		if not s.is_finite(): continue
		pts.append(s); on.append(road[i] if i<road.size() else 0)
	if pts.size()<2: return
	var state:=String(route.get("state","well"))
	var tip:=Supply.state_color(state)
	# The line's weight is what it carries: a band's bread and stores a day.
	var weight:=line_weight(float(route.get("loads",0.0)))
	# A paper halo so the ink reads over any wash.
	draw_polyline(pts,Color(PAPER,0.5*a),5.0*weight,true)
	var run:=PackedVector2Array([pts[0]])
	var run_on:=on[0]
	for i in range(1,pts.size()):
		run.append(pts[i])
		if on[i]!=run_on or i==pts.size()-1:
			if run_on==1: draw_polyline(run,Color(INK,0.85*a),2.4*weight,true)
			else: _dashed(run,Color(INK,0.8*a),1.5*weight,7.0,5.0)
			run=PackedVector2Array([pts[i]]); run_on=on[i]
	# Open chevrons toward the band, in the band's colour at the far end.
	var total:=0.0
	for i in range(1,pts.size()): total+=pts[i-1].distance_to(pts[i])
	if total<60.0: return
	for fraction in [0.5,0.82]:
		var target:=total*float(fraction); var walked:=0.0
		for i in range(1,pts.size()):
			var seg:=pts[i-1].distance_to(pts[i])
			if walked+seg>=target:
				var d:=(pts[i]-pts[i-1]).normalized()
				var at:=pts[i-1].lerp(pts[i],(target-walked)/maxf(seg,0.001))
				var n:=Vector2(-d.y,d.x)
				var colour:=INK if fraction<0.7 else tip.darkened(0.2)
				draw_polyline(PackedVector2Array([at-d*5.0+n*4.0,at,at-d*5.0-n*4.0]),Color(colour,0.9*a),1.6,true)
				break
			walked+=seg


## How heavy a supply line is drawn for the loads it carries a day: a war
## band's line is a thread, an armoured corps' a cable (x0.8 to x2.2).
static func line_weight(loads:float)->float:
	return clampf(0.8+0.35*log(1.0+maxf(0.0,loads)/50.0)/log(10.0),0.8,2.2)


func _draw_plate(mark:Dictionary)->void:
	var s:=_screen(mark.pos,float(mark.get("h",0.0)))
	if not s.is_finite(): return
	var report:Dictionary=mark.report
	var garrison:=String(report.get("force_kind",""))=="garrison"
	# Above a band's counter; beneath a held town's mark.
	var centre:=s+(Vector2(0,19.0) if garrison else Vector2(0,-24.0))
	var box:=Rect2(centre-Vector2(PLATE_W,PLATE_H)*0.5,Vector2(PLATE_W,PLATE_H))
	var hovered:=String(mark.id)==_hover_id
	draw_style_box(T.flat(Color(PAPER,0.94),Color(INK,0.55 if not hovered else 0.9),1,2,0),box)
	var state:=String(report.get("state","well"))
	var colour:=Supply.state_color(state)
	var sack:=sack_texture(state,32)
	draw_texture_rect(sack,Rect2(box.position+Vector2(1.5,0.5),Vector2(SACK_PX,SACK_PX)),false)
	var bar:=Rect2(box.position+Vector2(SACK_PX+3.0,PLATE_H*0.5-2.0),Vector2(PLATE_W-SACK_PX-6.0,4.0))
	draw_rect(bar,Color(T.TRACK,0.9))
	draw_rect(Rect2(bar.position,Vector2(bar.size.x*clampf(float(report.get("ratio",0.0)),0.0,1.0),bar.size.y)),colour)
	# The line where a fed day begins.
	var x:=bar.position.x+bar.size.x*Supply.WELL_FROM
	draw_line(Vector2(x,bar.position.y-1.0),Vector2(x,bar.end.y+1.0),Color(INK,0.55),1.0)


## The map between the rail, the top bar and the toolbar, where a caption
## is never under the interface.
func _clear_rect()->Rect2:
	var view:=get_viewport_rect().size
	return Rect2(Vector2(130.0,130.0),(view-Vector2(130.0+300.0,130.0+190.0)).max(Vector2(50,50)))

func _dashed(points:PackedVector2Array,colour:Color,width:float,on:float,off:float)->void:
	var carry:=0.0; var drawing:=true
	for i in range(1,points.size()):
		var a:=points[i-1]; var b:=points[i]
		var length:=a.distance_to(b)
		var t:=0.0
		while t<length:
			var left:=(on if drawing else off)-carry
			var step:=minf(left,length-t)
			if drawing: draw_line(a.lerp(b,t/length),a.lerp(b,(t+step)/length),colour,width,true)
			t+=step; carry+=step
			if carry>=(on if drawing else off)-0.001: carry=0.0; drawing=not drawing

func _dotted(points:PackedVector2Array,colour:Color,radius:float,spacing:float)->void:
	var carry:=spacing*0.5
	for i in range(1,points.size()):
		var a:=points[i-1]; var b:=points[i]
		var length:=a.distance_to(b)
		var t:=spacing-carry
		while t<=length:
			draw_circle(a.lerp(b,t/maxf(length,0.001)),radius,colour)
			t+=spacing
		carry=fmod(carry+length,spacing)

func _label(at:Vector2,text:String,a:float)->void:
	var font:=T.voice_font(true)
	var size_px:=17
	var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x
	var origin:=at-Vector2(width*0.5,0)
	draw_string_outline(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,6,Color(PAPER,0.92*a))
	draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,Color(INK,0.95*a))


# --- Hover -----------------------------------------------------------------------

## The mark or hub under the pointer, or the land (the key card shows it).
func _update_hover()->void:
	var id:=""
	var tip:={}
	var mouse:=get_local_mouse_position()
	var over_ui:=get_viewport().gui_get_hovered_control()!=null
	if visible and not over_ui and get_viewport_rect().has_point(mouse):
		for mark:Dictionary in marks:
			var s:=_screen(mark.pos,float(mark.get("h",0.0)))
			if not s.is_finite(): continue
			var report:Dictionary=mark.report
			var centre:=s+(Vector2(0,19.0) if String(report.get("force_kind",""))=="garrison" else Vector2(0,-24.0))
			if Rect2(centre-Vector2(PLATE_W,PLATE_H)*0.5,Vector2(PLATE_W,PLATE_H)).grow(4.0).has_point(mouse) or s.distance_to(mouse)<11.0:
				id=String(mark.id); tip=_force_tip(report); break
		if id=="":
			for hub:Dictionary in hubs:
				var s:=_screen(hub.pos,float(hub.get("h",0.0)))
				if s.is_finite() and s.distance_to(mouse)<14.0:
					id="hub:"+String(hub.name); tip=_hub_tip(hub); break
		if id=="" and lines_alpha>0.3 and is_instance_valid(terrain) and terrain.has_method("_terrain_hit"):
			var hit:Dictionary=terrain._terrain_hit(mouse)
			if hit.has("position"):
				var at:=Vector2((hit.position as Vector3).x,(hit.position as Vector3).z)
				if bool(CivilizationSystem._position_is_revealed(at)):
					id="land"; tip=_land_tip_at(at)
	_hover_id=id
	if not is_instance_valid(key_card): return
	if tip.is_empty() and pinned_id!="": key_card.call("show_tip",_pinned_tip,_pinned_at)
	else: key_card.call("show_tip",tip,mouse)

## Pins the note of what is under the pointer (a mark or a hub), or lets a
## pinned note go. Clicks still reach the map.
func _input(event:InputEvent)->void:
	if not visible or not (event is InputEventMouseButton) or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
	if _hover_id!="" and _hover_id!="land":
		pinned_id=_hover_id; _pinned_at=event.position
		_update_hover()
		_pinned_tip=key_card.get("tip") if is_instance_valid(key_card) else {}
	else:
		pinned_id=""; _pinned_tip={}

## Pins one mark's note (tests, captures): its id in marks, e.g. "army:7".
func pin(id:String)->void:
	for mark:Dictionary in marks:
		if String(mark.id)!=id: continue
		var s:=_screen(mark.pos,float(mark.get("h",0.0)))
		if not s.is_finite(): return
		pinned_id=id; _pinned_at=s+Vector2(0,-24)
		_pinned_tip=_force_tip(mark.report)
		if is_instance_valid(key_card): key_card.call("show_tip",_pinned_tip,_pinned_at)
		return

func _force_tip(report:Dictionary)->Dictionary:
	var name:=T.sentence_case(String(report.get("name","")))
	if String(report.get("force_kind",""))=="garrison": name="Garrison of "+String(report.get("name",""))
	var lines:=PackedStringArray()
	var why:PackedStringArray=report.get("why",PackedStringArray())
	for k in range(1,why.size()): lines.append(why[k])
	if report.has("loads") and float(report.loads)>0.0: lines.append("Its line carries %d loads a day: bread and its kits' fodder, fuel and rounds." % roundi(float(report.loads)))
	return {"title":name,"state":String(report.get("state","")),"ratio":float(report.get("ratio",0.0)),"text":String(report.get("words","")),"lines":lines}

func _hub_tip(hub:Dictionary)->Dictionary:
	var text:="Our stores: bands draw their food from here." if String(hub.kind)!="held" else "A town we hold: a depot on the supply line. Its garrison eats from its fields."
	return {"title":String(hub.name),"text":text}

func _land_tip_at(at:Vector2)->Dictionary:
	# The same reckoning the day's rations make (supply_state.at_point).
	var key:=Vector2i(roundi(at.x*0.5),roundi(at.y*0.5))
	if _land_tip.get("key",Vector2i.MAX)!=key:
		var report:=Supply.at_point(at,troops)
		var lines:=PackedStringArray()
		var why:PackedStringArray=report.get("why",PackedStringArray())
		for k in range(1,why.size()): lines.append(why[k])
		_land_tip={"key":key,"tip":{"title":"This land","state":String(report.state),"ratio":float(report.ratio),"text":String(report.words),"lines":lines}}
	return _land_tip.tip


# --- Glyphs ------------------------------------------------------------------------

## A grain sack in the colour of a state (well, strained, starving; "" ink):
## full for fed, sagging for short, empty and hatched for starving.
static func sack_texture(state:String,px:int=32)->Texture2D:
	var key:="%s|%d" % [state,px]
	if _sacks.has(key): return _sacks[key]
	var ink:=INK if state=="" else Supply.state_color(state).darkened(0.1)
	var paper:=Color(0.95,0.90,0.78,1.0)
	var prims:Array=[]
	var body_hw:=12.5 if state!="strained" else 13.0
	var body_hh:=12.5 if state!="strained" else 10.5
	var body_y:=35.0 if state!="strained" else 37.0
	prims.append(Icons._rr(28,body_y,body_hw+1.6,body_hh+1.6,8,paper))
	prims.append(Icons._rr(28,body_y,body_hw,body_hh,7,ink))
	if state=="starving":
		prims.append(Icons._rr(28,body_y,body_hw-2.6,body_hh-2.6,5,paper))
		prims.append(Icons._s(20,42,36,28,1.8,ink))
	prims.append_array([Icons._rr(28,20,5.5,4.5,2,ink),Icons._t(23,17,18,9,27,14,ink),Icons._t(33,17,38,9,29,14,ink),Icons._s(21.5,23.5,34.5,23.5,2.4,paper)])
	var texture:=ImageTexture.create_from_image(Icons._render(prims,px,false))
	_sacks[key]=texture
	return texture


# --- The key card (legend and pointer notes) -------------------------------------

## Drawn in the layer above the city labels: the legend at the foot of the
## map, and the note for whatever the pointer rests on.
class KeyCard extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	## The chart's inks and the wash's colours (as the outer class keeps them).
	const INK:=Color("#2b2118")
	const PAPER:=Color("#efe3c2")
	const WELL:=Color("#6e8a4a")
	const SHORT:=Color("#bd923a")
	const STARVE:=Color("#9a4236")
	const S:=preload("res://scripts/supply_state.gd")
	const TIP_WIDTH:=300.0
	var troops:=30
	var tip:Dictionary={}
	var tip_at:=Vector2.ZERO
	var legend_rect:=Rect2()

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func show_tip(value:Dictionary,at:Vector2)->void:
		if value==tip and (value.is_empty() or at.distance_to(tip_at)<1.0): return
		tip=value; tip_at=at
		queue_redraw()

	func set_troops(n:int)->void:
		if n!=troops: troops=n; queue_redraw()

	func _draw()->void:
		_draw_legend()
		if not tip.is_empty(): _draw_tip()

	func _draw_legend()->void:
		var ui:=T.font("ui")
		var view:=get_viewport_rect().size
		# At the map's left foot, above Map help, clear of the army bar.
		var size_px:=Vector2(236,176)
		var origin:=Vector2(T.RAIL_WIDTH+40.0,view.y-size_px.y-176.0)
		legend_rect=Rect2(origin,size_px)
		draw_style_box(T.flat(T.PANEL_BG_SOLID,T.BORDER,1,4,0),legend_rect)
		draw_string(ui,origin+Vector2(14,22),"SUPPLY",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.MUTED)
		var y:=origin.y+40.0
		for row in [[WELL,"Fed",0],[SHORT,"Short of food",0],[STARVE,"Starving",1]]:
			var sw:=Rect2(Vector2(origin.x+14,y-11),Vector2(22,14))
			draw_rect(sw,Color(PAPER,1.0))
			draw_rect(sw,Color(row[0],0.55))
			if int(row[2])==1:
				for k in 5: draw_line(sw.position+Vector2(float(k)*5.0-2.0,14),sw.position+Vector2(float(k)*5.0+10.0,0),Color(STARVE.darkened(0.3),0.9),1.0,true)
			draw_rect(sw,Color(INK,0.5),false,1.0)
			draw_string(ui,Vector2(origin.x+46,y),String(row[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK)
			y+=21.0
		y+=3.0
		var x0:=origin.x+14.0
		draw_line(Vector2(x0,y-5),Vector2(x0+22,y-5),Color(INK,0.8),2.4,true)
		draw_string(ui,Vector2(origin.x+46,y),"Our roads, and supply lines",HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK)
		y+=20.0
		for k in 3: draw_circle(Vector2(x0+3.0+float(k)*8.0,y-5),1.5,Color(INK,0.75))
		draw_string(ui,Vector2(origin.x+46,y),"How far the carts reach",HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK)
		y+=22.0
		draw_string(ui,Vector2(origin.x+14,y),"Shaded for a band of %d" % troops,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.MUTED)

	func _draw_tip()->void:
		var ui:=T.font("ui")
		var title:=String(tip.get("title",""))
		var text:=String(tip.get("text",""))
		var lines:PackedStringArray=tip.get("lines",PackedStringArray())
		var body:=ui.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,14)
		var extra:=0.0
		for l in lines: extra+=ui.get_multiline_string_size("· "+l,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,13).y
		var has_bar:=tip.has("ratio")
		var height:=16.0+20.0+(10.0 if has_bar else 0.0)+body.y+(6.0+extra if extra>0.0 else 0.0)+12.0
		var box_size:=Vector2(TIP_WIDTH+24.0,height)
		var origin:=tip_at+Vector2(18,20)
		var view:=get_viewport_rect().size
		# Above the pointer near the foot of the map, clear of the toolbar.
		if origin.y+box_size.y>view.y-150.0: origin.y=tip_at.y-box_size.y-18.0
		origin.x=clampf(origin.x,96.0,maxf(96.0,view.x-box_size.x-8.0))
		origin.y=clampf(origin.y,80.0,maxf(80.0,view.y-box_size.y-150.0))
		var state:=String(tip.get("state",""))
		var accent:=S.state_color(state) if state!="" else T.BORDER
		draw_style_box(T.flat(T.PANEL_BG_SOLID,Color(accent,0.8),1,4,0),Rect2(origin,box_size))
		draw_rect(Rect2(origin+Vector2(0,4),Vector2(3,box_size.y-8)),accent)
		var y:=origin.y+24.0
		draw_string(ui,Vector2(origin.x+14,y),title,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH*0.62,16,T.INK)
		if state!="":
			var words:=S.state_words(state).to_upper()
			var w:=ui.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			draw_string(ui,Vector2(origin.x+box_size.x-14.0-w,y),words,HORIZONTAL_ALIGNMENT_LEFT,-1,12,S.state_text_color(state))
		if has_bar:
			var bar:=Rect2(Vector2(origin.x+14,y+8),Vector2(box_size.x-28,5))
			draw_rect(bar,T.TRACK)
			draw_rect(Rect2(bar.position,Vector2(bar.size.x*clampf(float(tip.ratio),0.0,1.0),bar.size.y)),accent)
			var x:=bar.position.x+bar.size.x*S.WELL_FROM
			draw_line(Vector2(x,bar.position.y-2),Vector2(x,bar.end.y+2),Color(T.INK,0.6),1.0)
			y+=10.0
		y+=10.0
		draw_multiline_string(ui,Vector2(origin.x+14,y+ui.get_ascent(14)),text,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,14,-1,T.BODY)
		y+=body.y+6.0
		for l in lines:
			draw_multiline_string(ui,Vector2(origin.x+14,y+ui.get_ascent(13)),"· "+l,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,13,-1,T.MUTED)
			y+=ui.get_multiline_string_size("· "+l,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,13).y
