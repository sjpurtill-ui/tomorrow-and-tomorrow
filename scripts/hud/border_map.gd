extends Node
## THE BORDER ON THE MAP: where the god raises, moves and breaks down forts
## (fort_border.gd). A toggle beside Supply on the map toolbar. When on:
##   - the pointer carries a ghost of the next fort over open land: its reach
##     ringed, dashed ties to the forts it would link with, and a paper note
##     beside it with what it costs and gains in the engine's numbers
##     (FortBorder.quote): materials, food lost on the road, days to raise,
##     the ground the border gains. A click raises it (FortBorder.place);
##   - a click on a fort opens its note: how it is manned and kept, and
##     Move (the ghost then carries it; a click sets it down) or Break down;
##   - the key at the map's foot sums the border: the watch out, how the line
##     holds, the food lost a day, and the share of the watch sent out (−/+).
## Right-click or Esc lets a move go, then the fort's note. The border line
## itself is the terrain's chart ink (fort_line_visual.gd).

const Forts:=preload("res://scripts/fort_border.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

const NODE_NAME:="BorderMap"
## Our colour (fort_line_visual.gd PLUM).
const PLUM:=Color("#7b2a7a")
const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
## Turned on closer in than this, the view pulls out to the region.
const CLOSE_KM:=40.0
const REGION_LEVEL:=2
## A fort's mark answers the pointer within this many pixels.
const FORT_HIT_PX:=18.0

var terrain:Node
var enabled:=false
var chart:Control
var key_card:PanelContainer
var note:PanelContainer
var _layers:Array[CanvasLayer]=[]
## The fort whose note is open (-1 none); the fort being carried (-1 none).
var selected:=-1
var moving:=-1
## A refusal shown in the ghost's note for a moment: {text, until}.
var _refusal:Dictionary={}
var _key_signature:=0
var _look:=0.0


# --- The toolbar's toggle ----------------------------------------------------

static func find(t:Node)->Node:
	return t.get_node_or_null(NODE_NAME) if is_instance_valid(t) else null

static func ensure(t:Node)->Node:
	var node:=find(t)
	if node==null and is_instance_valid(t) and t.is_inside_tree():
		node=load("res://scripts/hud/border_map.gd").new()
		node.name=NODE_NAME
		node.set("terrain",t)
		t.add_child(node)
	return node

## THE ONE WAY to show or hide the border mode (the War board's "Place forts
## on the map", a test): the toolbar's Border button follows.
static func set_shown(t:Node,on:=true)->void:
	if not is_instance_valid(t): return
	var hud:Variant=t.get("hud")
	var button:Button=(hud as Node).find_child("ToolbarBorder",true,false) as Button if hud is Node and is_instance_valid(hud) else null
	if button!=null:
		if button.button_pressed!=on: button.button_pressed=on
		return
	var node:=ensure(t)
	if node!=null: node.call("set_enabled",on)

static func is_shown(t:Node)->bool:
	var node:=find(t)
	return node!=null and bool(node.get("enabled"))

## The Border toggle for the map toolbar (command_rail_hud._build_toolbar).
static func toggle_button(t:Node)->Button:
	var button:=Button.new()
	button.name="ToolbarBorder"
	button.text="Border"
	button.toggle_mode=true
	button.icon=Icons.chart_texture("fort:stone_fort",INK,40)
	button.add_theme_constant_override("icon_max_width",20)
	button.add_theme_constant_override("h_separation",6)
	button.custom_minimum_size=Vector2(0,32)
	button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",T.BODY)
	button.add_theme_color_override("font_pressed_color",T.GOLD_TEXT)
	button.add_theme_color_override("font_hover_pressed_color",T.GOLD_TEXT)
	button.add_theme_stylebox_override("normal",T.action_button_style(false))
	button.add_theme_stylebox_override("hover",T.action_button_style(false,true))
	button.add_theme_stylebox_override("pressed",T.action_button_style(true))
	button.add_theme_stylebox_override("hover_pressed",T.action_button_style(true,true))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.tooltip_text="Our border and its forts. Click open land to raise a fort there; click a fort to move it or break it down."
	button.toggled.connect(func(on:bool)->void:
		var node:=ensure(t)
		if node!=null: node.call("set_enabled",on))
	return button


# --- Life ----------------------------------------------------------------------

func set_enabled(on:bool)->void:
	enabled=on
	if on:
		_build()
		var camera:Variant=terrain.get("camera")
		if is_instance_valid(camera) and float(camera.size)<CLOSE_KM and terrain.has_method("set_camera_distance_level"): terrain.set_camera_distance_level(REGION_LEVEL)
		_key_signature=0
		_refresh_key()
	else:
		moving=-1; _close_note()
	for layer in _layers: layer.visible=on
	set_process(on)

func _build()->void:
	if is_instance_valid(chart): return
	var ink_layer:=CanvasLayer.new(); ink_layer.name="BorderInk"; ink_layer.layer=1; add_child(ink_layer)
	chart=BorderChart.new(); chart.name="BorderChart"; chart.set("owner_map",self); ink_layer.add_child(chart)
	var card_layer:=CanvasLayer.new(); card_layer.name="BorderCards"; card_layer.layer=4; add_child(card_layer)
	key_card=Kit.panel(PLUM,14); key_card.name="BorderKey"; card_layer.add_child(key_card)
	_layers=[ink_layer,card_layer]

func _process(delta:float)->void:
	if not enabled: return
	var covered:=is_instance_valid(terrain.get("world_globe")) if is_instance_valid(terrain) else false
	for layer in _layers: layer.visible=not covered
	_look+=delta
	if _look>=0.5:
		_look=0.0
		_refresh_key()
	if is_instance_valid(key_card):
		# Cards fit their words (wrapped labels settle a frame after a rebuild).
		key_card.size=key_card.get_combined_minimum_size()
		var view:=get_viewport().get_visible_rect().size
		key_card.position=Vector2(T.RAIL_WIDTH+40.0,view.y-key_card.size.y-176.0)
	if is_instance_valid(note): note.size=note.get_combined_minimum_size()
	if is_instance_valid(note) and selected>=0: _place_note()

func camera()->Camera3D:
	if not is_instance_valid(terrain): return null
	var c:Variant=terrain.get("camera")
	return c if is_instance_valid(c) and c is Camera3D else null

func screen_of(p:Vector2)->Vector2:
	var cam:=camera()
	if cam==null: return Vector2.INF
	var h:=maxf(0.0,float(terrain._rendered_ground_height_at(p))) if terrain.has_method("_rendered_ground_height_at") else 0.0
	var world:=Vector3(p.x,h,p.y)
	if cam.is_position_behind(world): return Vector2.INF
	return cam.unproject_position(world)

## The ground under a screen point, or INF.
func ground_at(screen:Vector2)->Vector2:
	if not is_instance_valid(terrain) or not terrain.has_method("_terrain_hit"): return Vector2.INF
	var hit:Dictionary=terrain._terrain_hit(screen)
	if not hit.has("position"): return Vector2.INF
	return Vector2((hit.position as Vector3).x,(hit.position as Vector3).z)

## Our fort under a screen point, or {}.
func fort_at(screen:Vector2)->Dictionary:
	var best:={}; var nearest:=FORT_HIT_PX
	for f:Dictionary in Forts.forts():
		if String(f.get("status",""))=="abandoned": continue
		var s:=screen_of(Forts._pos(f))
		if s.is_finite() and s.distance_to(screen)<nearest: nearest=s.distance_to(screen); best=f
	return best

func _pointer_over_cards(at:Vector2)->bool:
	for card:Control in [key_card,note]:
		if is_instance_valid(card) and card.visible and card.get_global_rect().has_point(at): return true
	return get_viewport().gui_get_hovered_control()!=null and get_viewport().gui_get_hovered_control()!=chart


# --- The god's hand --------------------------------------------------------------

func _unhandled_input(event:InputEvent)->void:
	if not enabled: return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if _let_go(): get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton) or not event.pressed: return
	if is_instance_valid(terrain.get("world_globe")): return
	if event.button_index==MOUSE_BUTTON_RIGHT:
		if _let_go(): get_viewport().set_input_as_handled()
		return
	if event.button_index!=MOUSE_BUTTON_LEFT: return
	click(event.position)
	get_viewport().set_input_as_handled()

## A left click on the map at `at` (screen): open a fort's note, set a carried
## fort down, or raise a fort.
func click(at:Vector2)->void:
	var fort:=fort_at(at)
	if moving<0 and not fort.is_empty():
		open_note(int(fort.id)); return
	var ground:=ground_at(at)
	if not ground.is_finite(): return
	var result:Dictionary=Forts.move(moving,ground) if moving>=0 else Forts.place(ground)
	if result.has("error"):
		_refusal={"text":String(result.error),"until":Time.get_ticks_msec()+2600}
		return
	moving=-1
	_close_note()
	_changed()

## Lets a carried fort go, else closes the open note. Whether anything went.
func _let_go()->bool:
	if moving>=0:
		moving=-1
		if selected>=0: open_note(selected)
		return true
	if selected>=0: _close_note(); return true
	return false

func _changed()->void:
	if is_instance_valid(terrain): terrain.set("_border_watch_day",-1)
	_key_signature=0
	_refresh_key()
	if is_instance_valid(chart): chart.call("forget")


# --- The fort's note ---------------------------------------------------------------

func open_note(id:int)->void:
	var fort:=Forts.find_fort(id)
	if fort.is_empty(): return
	_close_note()
	selected=id
	var k:=Forts.kind(String(fort.kind))
	var kept:=Forts.watch()
	var bill:=Forts.costs(null,kept)
	note=Kit.panel(PLUM,14); note.name="FortNote"
	_layers[1].add_child(note)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",6); column.custom_minimum_size=Vector2(320,0); note.add_child(column)
	var head:=HBoxContainer.new(); head.add_theme_constant_override("separation",10); column.add_child(head)
	var glyph:=TextureRect.new(); glyph.texture=Icons.chart_texture("fort:%s%s" % [String(fort.kind),"" if String(fort.status)=="standing" else ":building"],PLUM,64)
	glyph.custom_minimum_size=Vector2(44,44); glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; head.add_child(glyph)
	var titles:=VBoxContainer.new(); titles.add_theme_constant_override("separation",0); titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL; head.add_child(titles)
	Kit.label(titles,String(k.get("name","Fort")),"kicker")
	Kit.label(titles,String(fort.get("name","")),"heading")
	var need:=int(k.get("garrison",1))
	var manned:=int(kept.garrisons.get(id,0))
	var km:=Forts._pos(fort).distance_to(Forts.seat())
	var lost:=0.0
	for post:Dictionary in bill.posts:
		if int(post.id)==id: lost=float(post.lost)
	var facts:=Kit.section(column,10)
	if String(fort.status)=="building":
		var work:=float(k.get("work",1.0))
		var done:=clampf(float(fort.get("progress",0.0))/work,0.0,1.0)
		var days:=ceili((work-float(fort.get("progress",0.0)))/maxf(1.0,float(manned)))
		Kit.label(facts,"Going up: %d in 100 raised%s." % [roundi(done*100.0),(", about %d days more" % days) if manned>0 else "; no one is posted to raise it"],"body")
		_bar(facts,done,PLUM)
	else:
		var condition:=clampf(float(fort.get("condition",1.0)),0.0,1.0)
		Kit.label(facts,"Holds %d km of ground about it. Kept %d in 100%s." % [roundi(Forts.reach_of(fort)),roundi(condition*100.0)," (short of upkeep, it wears down)" if condition<0.95 else ""],"body")
		_bar(facts,condition,T.TEAL if condition>=0.7 else (T.AMBER if condition>=0.4 else T.RED))
	Kit.label(facts,"%d of %d to man it · %d km out · %s food lost on the road a day" % [manned,need,roundi(km),_amount(lost)],"note",T.RED if manned<need else Color(0,0,0,0))
	var upkeep:=_materials(k.get("upkeep",{}),1.0)
	if upkeep!="": Kit.label(facts,"Upkeep %s a day" % upkeep,"note")
	var buttons:=HBoxContainer.new(); buttons.add_theme_constant_override("separation",8); column.add_child(buttons)
	var back:=Forts.recovered(fort)
	Kit.button(buttons,"Move",true,func()->void:start_move(id),"Carry it elsewhere: it keeps %d in 100 of its work and costs a quarter of a new fort's materials. Until it stands again it holds no ground." % roundi(Forts.MOVE_KEEP*100.0))
	var break_down:=func()->void:
		Forts.dismantle(id)
		_close_note(); _changed()
	Kit.button(buttons,"Break down",false,break_down,"Take it down: %s back to the stores. The ground it held is no longer ours." % (_materials(back,1.0) if not back.is_empty() else "nothing"))
	var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; buttons.add_child(spacer)
	Kit.quiet_button(buttons,"Close",func()->void:_close_note())
	if not back.is_empty(): Kit.label(column,"Broken down it gives back %s." % _materials(back,1.0),"note")
	_place_note()

func start_move(id:int)->void:
	moving=id
	if is_instance_valid(note): note.visible=false

func _close_note()->void:
	if is_instance_valid(note): note.queue_free()
	note=null
	selected=-1

func _place_note()->void:
	if not is_instance_valid(note) or not note.visible: return
	var fort:=Forts.find_fort(selected)
	if fort.is_empty(): _close_note(); return
	var s:=screen_of(Forts._pos(fort))
	if not s.is_finite(): return
	var view:=get_viewport().get_visible_rect().size
	var at:=s+Vector2(28,-note.size.y*0.5)
	if at.x+note.size.x>view.x-16.0: at.x=s.x-28.0-note.size.x
	at.y=clampf(at.y,T.CONTENT_TOP+8.0,maxf(T.CONTENT_TOP+8.0,view.y-note.size.y-150.0))
	note.position=at


# --- The key ------------------------------------------------------------------------

func _refresh_key()->void:
	if not is_instance_valid(key_card): return
	var kept:=Forts.watch()
	var bill:=Forts.costs(null,kept)
	var held:=0.0; var km:=0.0
	for st:Dictionary in kept.stretches: held+=float(st.strength)*float(st.km); km+=float(st.km)
	var line:=held/km if km>0.0 else 0.0
	var next:=Forts.best_kind()
	var signature:=hash([int(kept.posted),roundi(line*100.0),roundi(float(bill.food_lost)),snappedf(Forts.border_share(),0.05),Forts.forts().size(),String(next.get("id","")),moving])
	if signature==_key_signature: return
	_key_signature=signature
	for child in key_card.get_children(): child.queue_free()
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",6); column.custom_minimum_size=Vector2(300,0); key_card.add_child(column)
	Kit.label(column,"The border","kicker")
	var standing:=Forts.standing().size()
	var going:=Forts.forts().filter(func(f:Dictionary)->bool:return String(f.get("status",""))=="building").size()
	Kit.label(column,"%d on watch · %d fort%s%s" % [int(kept.posted),standing,"" if standing==1 else "s",(" · %d going up" % going) if going>0 else ""],"heading")
	var holds:=HBoxContainer.new(); holds.add_theme_constant_override("separation",8); column.add_child(holds)
	var words:=Kit.label(holds,("The line holds %d in 100" % roundi(line*100.0)) if km>0.0 else "No two forts linked: open","body")
	words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var bar:=_bar(holds,line,T.TEAL if line>=0.7 else (T.AMBER if line>=0.4 else T.RED)); bar.custom_minimum_size=Vector2(90,6); bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	if km>0.0 and int(kept.line)<=0:
		var need:=0
		for f:Dictionary in Forts.forts():
			if String(f.get("status",""))!="abandoned": need+=int(Forts.kind(String(f.kind)).get("garrison",0))
		Kit.label(column,"The forts' garrisons take all %d sent out (they need %d): none are left to walk the line between them." % [int(kept.posted),need],"note",T.RED)
	Kit.label(column,"%s food lost on the road a day" % _amount(float(bill.food_lost)),"note")
	var share_row:=HBoxContainer.new(); share_row.add_theme_constant_override("separation",6); column.add_child(share_row)
	var said:=Kit.label(share_row,"%d in 100 of the watch at home sent out" % roundi(Forts.border_share()*100.0),"note"); said.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	said.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for step:Array in [["−",-0.1,"Fewer on the border: less food lost on the road, a thinner line."],["+",0.1,"More on the border: forts manned first, then the line between them."]]:
		var b:=Kit.button(share_row,String(step[0]),false,func()->void:Forts.set_border_share(clampf(Forts.border_share()+float(step[1]),0.0,1.0));_changed(),String(step[2]))
		b.custom_minimum_size=Vector2(36,32)
	_legend(column)
	if next.is_empty(): Kit.label(column,"Our people know no way to raise a fort yet.","note")
	elif moving>=0: Kit.label(column,"Carrying %s: click where it should stand. Right-click to let it go." % String(Forts.find_fort(moving).get("name","the fort")),"note",PLUM)
	else: Kit.label(column,"Click open land to raise a %s (%s). Click a fort to move it or break it down." % [String(next.name).to_lower(),_materials(next.cost,1.0)],"note")

func _legend(parent:Node)->void:
	var swatches:=LegendInk.new(); swatches.custom_minimum_size=Vector2(270,62); parent.add_child(swatches)

func _bar(parent:Node,share:float,ink:Color)->Control:
	var bar:=ShareBar.new(); bar.share=share; bar.ink=ink; bar.custom_minimum_size=Vector2(0,6); bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar


# --- Words ------------------------------------------------------------------------

static func _amount(value:float)->String:
	if value<10.0: return str(snappedf(value,0.1)).trim_suffix(".0")
	return str(roundi(value))

## "30 timber, 10 fiber plants".
static func _materials(amounts:Dictionary,scale:float)->String:
	var parts:PackedStringArray=[]
	for m:String in amounts:
		if float(amounts[m])*scale>0.0: parts.append("%s %s" % [_amount(float(amounts[m])*scale),m.to_lower()])
	return ", ".join(parts)


## A thin bar of a share, in an ink.
class ShareBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var share:=0.0
	var ink:=Color.BLACK
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*clampf(share,0.0,1.0),size.y)),ink)


## The key's three inks: a kept line, a thin one, open ground.
class LegendInk extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const PLUM:=Color("#7b2a7a")
	func _draw()->void:
		var ui:=T.font("ui")
		var rows:=[[3.2,0.97,false,"Well kept: few slip through"],[1.5,0.75,false,"Thinly kept"],[1.4,0.62,true,"Open: anyone walks in and out"]]
		for i in rows.size():
			var row:Array=rows[i]
			var y:=10.0+float(i)*20.0
			if bool(row[2]):
				for k in 4: draw_circle(Vector2(4.0+float(k)*7.0,y),1.6,Color(PLUM,float(row[1])))
			else: draw_line(Vector2(0,y),Vector2(26,y),Color(PLUM,float(row[1])),float(row[0]),true)
			draw_string(ui,Vector2(36,y+5.0),String(row[3]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.BODY)


## The ghost and the pointer's notes, drawn over the map.
class BorderChart extends Control:
	const Forts:=preload("res://scripts/fort_border.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const PLUM:=Color("#7b2a7a")
	const INK:=Color("#2b2118")
	const PAPER:=Color("#efe3c2")
	const TIP_WIDTH:=300.0
	var owner_map:Node
	var _quote:Dictionary={}
	var _quote_key:=Vector2i(1<<30,1<<30)
	var _quote_moving:=-2
	var _hover_fort:Dictionary={}
	var _mouse:=Vector2.INF
	var _ground:=Vector2.INF
	var _elapsed:=0.0
	var _view:=0
	## Captures and tests: the pointer held here instead of the mouse.
	var pointer_override:=Vector2.INF
	## Every fort's name and every stretch's hold, refreshed with the pointer.
	var _names:Array=[]
	var _stretches:Array=[]

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func forget()->void:
		_quote={}; _quote_key=Vector2i(1<<30,1<<30)

	func _process(delta:float)->void:
		if owner_map==null: return
		_elapsed+=delta
		if _elapsed>=0.25 or _names.is_empty(): _read_border()
		# The words ride the map: redrawn whenever the view moves.
		var viewer:Camera3D=owner_map.call("camera")
		if viewer!=null:
			var view:=hash([viewer.global_transform,viewer.size])
			if view!=_view: _view=view; queue_redraw()
		var mouse:=pointer_override if pointer_override.is_finite() else get_local_mouse_position()
		var over:=(bool(owner_map.call("_pointer_over_cards",mouse)) and not pointer_override.is_finite()) or not get_viewport_rect().has_point(mouse)
		if over:
			if _mouse.is_finite(): _mouse=Vector2.INF; _hover_fort={}; queue_redraw()
			return
		if mouse==_mouse and _elapsed<0.25: return
		_elapsed=0.0
		_mouse=mouse
		_hover_fort={} if int(owner_map.moving)>=0 else owner_map.call("fort_at",mouse)
		_ground=owner_map.call("ground_at",mouse) if _hover_fort.is_empty() else Vector2.INF
		if _ground.is_finite():
			var cam:Camera3D=owner_map.call("camera")
			var grain:=maxf(0.25,float(cam.size)/300.0) if cam!=null else 1.0
			var key:=Vector2i(roundi(_ground.x/grain),roundi(_ground.y/grain))
			if key!=_quote_key or _quote_moving!=int(owner_map.moving):
				_quote_key=key; _quote_moving=int(owner_map.moving)
				_quote=Forts.quote(_ground,int(owner_map.moving))
		queue_redraw()

	func _read_border()->void:
		_names=[]; _stretches=[]
		for f:Dictionary in Forts.forts():
			if String(f.get("status",""))!="abandoned": _names.append([Forts._pos(f),String(f.get("name",""))])
		var kept:=Forts.watch()
		for st:Dictionary in kept.stretches: _stretches.append([Vector2(st.mid),float(st.strength),float(st.per_km)])

	func _draw()->void:
		_draw_border_words()
		if not _mouse.is_finite(): return
		if not _hover_fort.is_empty(): _draw_fort_hover(); return
		if _ground.is_finite() and not _quote.is_empty() and _quote.has("kind"): _draw_ghost()

	## Each fort's name beneath its mark; on each stretch between linked forts,
	## how many in 100 crossings it stops and its watch a km.
	func _draw_border_words()->void:
		var voice:=T.voice_font(true); var ui:=T.font("ui_strong")
		for row:Array in _names:
			var s:Vector2=owner_map.call("screen_of",row[0])
			if not s.is_finite(): continue
			var text:=String(row[1])
			var w:=voice.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
			var at:=s+Vector2(-w*0.5,30)
			draw_string_outline(voice,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,5,Color(PAPER,0.92))
			draw_string(voice,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(PLUM.darkened(0.25),0.95))
		for row:Array in _stretches:
			var s:Vector2=owner_map.call("screen_of",row[0])
			if not s.is_finite(): continue
			var strength:float=row[1]
			var text:="holds %d in 100 · %s a km" % [roundi(strength*100.0),str(snappedf(float(row[2]),0.1)).trim_suffix(".0")]
			var w:=ui.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			var box:=Rect2(s-Vector2(w*0.5+8,10),Vector2(w+16,20))
			var ink:=T.TEAL if strength>=0.7 else (T.AMBER if strength>=0.4 else T.RED)
			draw_style_box(T.flat(Color(PAPER,0.95),Color(ink,0.9),1,3,0),box)
			draw_rect(Rect2(box.position+Vector2(1,box.size.y-4),Vector2((box.size.x-2)*clampf(strength,0.0,1.0),3)),ink)
			draw_string(ui,box.position+Vector2(8,14),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)

	func _circle(center:Vector2,km:float,colour:Color,dashed:bool)->void:
		var pts:=PackedVector2Array()
		for k in 49:
			var s:Vector2=owner_map.call("screen_of",center+Vector2.from_angle(TAU*float(k)/48.0)*km)
			if s.is_finite(): pts.append(s)
		if pts.size()<3: return
		if dashed:
			for i in range(0,pts.size()-1,2): draw_line(pts[i],pts[i+1],colour,1.6,true)
		else: draw_polyline(pts,colour,1.6,true)

	func _draw_ghost()->void:
		var ok:=String(_quote.get("problem",""))=="" and (_quote.short as Dictionary).is_empty()
		var ink:=PLUM if ok else T.RED
		var reach:=float(Forts.kind(String(_quote.kind)).get("reach",0.0))
		# A fort being carried: a dashed track from where it stands.
		var carried:=Forts.find_fort(int(owner_map.moving)) if int(owner_map.moving)>=0 else {}
		if not carried.is_empty():
			var from:Vector2=owner_map.call("screen_of",Forts._pos(carried))
			if from.is_finite(): _dashed(from,_mouse,Color(INK,0.7),1.6)
		if String(_quote.get("problem",""))=="":
			_circle(_ground,reach,Color(ink,0.75),true)
			for link:Dictionary in _quote.links:
				var other:=Forts.find_fort(int(link.get("to",-1)))
				if other.is_empty(): continue
				var there:Vector2=owner_map.call("screen_of",Forts._pos(other))
				if not there.is_finite(): continue
				draw_line(_mouse,there,Color(PAPER,0.6),5.0,true)
				_dashed(_mouse,there,Color(PLUM,0.95),2.4)
		var glyph:=Icons.chart_texture("fort:%s:building" % String(_quote.kind),ink,64)
		draw_texture_rect(glyph,Rect2(_mouse-Vector2(22,22),Vector2(44,44)),false,Color(1,1,1,0.9))
		_draw_quote_tip(ok)

	func _draw_quote_tip(ok:bool)->void:
		var q:=_quote
		var title:=("Move %s here" % String(Forts.find_fort(int(owner_map.moving)).get("name","the fort"))) if int(owner_map.moving)>=0 else ("Raise a %s here" % String(q.kind_name).to_lower())
		var rows:Array=[]
		var refusal:Dictionary=owner_map.get("_refusal")
		if not refusal.is_empty() and Time.get_ticks_msec()<int(refusal.until): rows.append([String(refusal.text),T.RED_TEXT,true])
		var problem:=String(q.get("problem",""))
		if problem!="":
			rows.append([problem,T.RED_TEXT,true])
		else:
			rows.append(["%d km out · %d of the watch to man it · about %d days to raise" % [roundi(float(q.km)),int(q.garrison),int(q.days)],T.BODY,false])
			var cost:="Costs %s" % owner_map.call("_materials",q.cost,1.0)
			rows.append([cost,T.BODY,false])
			if not (q.short as Dictionary).is_empty(): rows.append([Forts.short_words(q),T.RED_TEXT,true])
			rows.append(["%s food lost on the road a day (%d in 100 of what is carried out)" % [owner_map.call("_amount",float(q.food_lost)),roundi(float(q.loss_share)*100.0)],T.BODY,false])
			var up:=String(owner_map.call("_materials",q.upkeep,1.0))
			if up!="": rows.append(["Upkeep %s a day" % up,T.MUTED,false])
			var gain:=float(q.gain_km2)
			if absf(gain)>=1.0: rows.append([("The border grows by %s km²" if gain>0.0 else "The border shrinks by %s km²") % _thousands(absf(gain)),T.GREEN_TEXT if gain>0.0 else T.RED_TEXT,true])
			else: rows.append(["Inside the border already: no ground gained",T.MUTED,false])
			if (q.links as Array).is_empty(): rows.append(["Links to no fort: a lone post, the land about it open",T.AMBER_TEXT,false])
			for link:Dictionary in q.links: rows.append(["Links to %s, %d km of line to watch" % [String(link.name),roundi(float(link.km))],T.BODY,false])
		rows.append([("Click to set it down · right-click to let it go" if int(owner_map.moving)>=0 else "Click to raise it") if ok else "",T.MUTED,false])
		_tip(title,rows,PLUM if ok else T.RED)

	func _draw_fort_hover()->void:
		var f:=_hover_fort
		var s:Vector2=owner_map.call("screen_of",Forts._pos(f))
		if s.is_finite():
			draw_arc(s,22.0,0.0,TAU,40,Color(PAPER,0.8),5.0,true)
			draw_arc(s,22.0,0.0,TAU,40,Color(PLUM,0.95),2.0,true)
			if String(f.get("status",""))=="standing": _circle(Forts._pos(f),Forts.reach_of(f),Color(PLUM,0.6),true)
		var k:=Forts.kind(String(f.kind))
		var kept:=Forts.watch()
		var manned:=int(kept.garrisons.get(int(f.id),0))
		var status:="Going up, %d in 100 raised" % roundi(100.0*float(f.get("progress",0.0))/maxf(1.0,float(k.get("work",1.0)))) if String(f.status)=="building" else "Kept %d in 100" % roundi(100.0*float(f.get("condition",1.0)))
		_tip(String(f.get("name","")),[[String(k.get("name","")),T.MUTED,false],[status,T.BODY,false],["%d of %d to man it · %d km out" % [manned,int(k.get("garrison",0)),roundi(Forts._pos(f).distance_to(Forts.seat()))],T.RED_TEXT if manned<int(k.get("garrison",0)) else T.BODY,false],["Click for orders: move it or break it down",T.MUTED,false]],PLUM)

	## A paper note beside the pointer: a title and rows [text, colour, strong].
	func _tip(title:String,rows:Array,accent:Color)->void:
		var ui:=T.font("ui"); var strong:=T.font("ui_strong")
		var height:=40.0
		for row:Array in rows:
			if String(row[0])!="": height+=ui.get_multiline_string_size(String(row[0]),HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,14).y+3.0
		var box:=Vector2(TIP_WIDTH+28.0,height+8.0)
		var view:=get_viewport_rect().size
		var origin:=_mouse+Vector2(30,18)
		if origin.x+box.x>view.x-12.0: origin.x=_mouse.x-30.0-box.x
		if origin.y+box.y>view.y-150.0: origin.y=_mouse.y-box.y-18.0
		origin.y=clampf(origin.y,T.CONTENT_TOP,maxf(T.CONTENT_TOP,view.y-box.y-150.0))
		var rect:=Rect2(origin,box)
		draw_style_box(T.flat(Color(0.12,0.09,0.05,0.16),Color(0,0,0,0),0,6,0),Rect2(rect.position+Vector2(0,4),rect.size).grow(3))
		draw_style_box(T.flat(T.PANEL_BG_SOLID,T.RULE,1,4,0),rect)
		draw_rect(Rect2(origin,Vector2(box.x,3)),accent)
		var y:=origin.y+28.0
		draw_string(strong,Vector2(origin.x+14,y),title,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,17,T.INK)
		y+=10.0
		for row:Array in rows:
			var text:=String(row[0])
			if text=="": continue
			var font:=strong if bool(row[2]) else ui
			draw_multiline_string(font,Vector2(origin.x+14,y+font.get_ascent(14)),text,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,14,-1,row[1])
			y+=ui.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,TIP_WIDTH,14).y+3.0

	func _dashed(a:Vector2,b:Vector2,colour:Color,width:float)->void:
		var length:=a.distance_to(b)
		var t:=0.0
		while t<length:
			draw_line(a.lerp(b,t/length),a.lerp(b,minf(t+8.0,length)/length),colour,width,true)
			t+=13.0

	static func _thousands(value:float)->String:
		var text:=str(roundi(value))
		var out:=""
		while text.length()>3:
			out=","+text.substr(text.length()-3)+out
			text=text.substr(0,text.length()-3)
		return text+out
