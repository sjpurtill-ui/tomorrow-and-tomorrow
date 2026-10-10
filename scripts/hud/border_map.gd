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
var _note_signature:=0


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
		if selected>=0 and moving<0:
			var f:=Forts.find_fort(selected)
			var stamp:=hash([f,Forts.watch().garrisons,Forts.costs().posts,T.color_mode])
			if stamp!=_note_signature: open_note(selected)
	if is_instance_valid(key_card):
		# Cards fit their words (wrapped labels settle a frame after a rebuild).
		key_card.size=key_card.get_combined_minimum_size()
		var view:=get_viewport().get_visible_rect().size
		key_card.position=Vector2(T.RAIL_WIDTH+24.0,maxf(T.CONTENT_TOP+8.0,view.y-key_card.size.y-160.0))
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
	if _pointer_over_cards(at): return
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
	if result.has("fort"): open_note(int(result.fort.id))

## Lets a carried fort go, else closes the open note. Whether anything went.
func _let_go()->bool:
	if moving>=0:
		moving=-1
		if selected>=0: open_note(selected)
		_changed()
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
	if fort.is_empty(): _close_note(); return
	_close_note()
	selected=id
	var k:=Forts.kind(String(fort.kind))
	var kept:=Forts.watch()
	var bill:=Forts.costs(null,kept)
	_note_signature=hash([fort,kept.garrisons,bill.posts,T.color_mode])
	var building:=String(fort.status)=="building"
	var manned:=int(kept.garrisons.get(id,0))
	var need:=int(k.get("garrison",1))
	var lost:=0.0
	for post:Dictionary in bill.posts:
		if int(post.id)==id: lost=float(post.lost)
	note=Kit.panel(PLUM,16); note.name="FortNote"
	_layers[1].add_child(note)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",12); column.custom_minimum_size=Vector2(320,0); note.add_child(column)
	var head:=_heading(column,String(k.get("name","Fort")),String(fort.get("name","")),String(fort.kind),building)
	var close:=Kit.quiet_button(head,"×",func()->void:_close_note(),"Close fort note · Esc")
	close.name="CloseFortNote"; close.custom_minimum_size=Vector2(36,36)
	var facts:=Kit.section(column,12)
	facts.add_theme_constant_override("separation",8)
	if building:
		var work:=float(k.get("work",1.0))
		var done:=clampf(float(fort.get("progress",0.0))/work,0.0,1.0)
		var days:=ceili((work-float(fort.get("progress",0.0)))/maxf(1.0,float(manned)))
		_status(facts,"Raising the fort","%d%%" % roundi(done*100.0),T.VIOLET)
		_bar(facts,done,T.VIOLET)
		Kit.label(facts,("About %d days to stand. Holds no ground until complete." % days) if manned>0 else "Work is waiting. Send a garrison to raise this fort.","note",T.AMBER if manned<=0 else Color.TRANSPARENT)
	else:
		var condition:=clampf(float(fort.get("condition",1.0)),0.0,1.0)
		var tone:=T.TEAL if condition>=0.7 else (T.AMBER if condition>=0.4 else T.RED)
		_status(facts,"Well kept" if condition>=0.95 else "Below full condition","%d%% kept" % roundi(condition*100.0),tone)
		_bar(facts,condition,tone)
		if condition<0.95: Kit.label(facts,"Keep the garrison and upkeep supplied to restore this fort.","note",T.AMBER)
	var grid:=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",18); grid.add_theme_constant_override("v_separation",12); column.add_child(grid)
	_metric(grid,"Garrison","%d / %d" % [manned,need],T.RED if manned<need else T.INK)
	_metric(grid,"Reach","%d km" % roundi(Forts.reach_of(fort)) if not building else "Not held yet")
	_metric(grid,"From home","%d km" % roundi(Forts._pos(fort).distance_to(Forts.seat())))
	_metric(grid,"Food lost / day",_amount(lost),T.AMBER if lost>0.0 else T.INK)
	var upkeep:=_materials(k.get("upkeep",{}),1.0)
	if upkeep!="": Kit.label(column,"Upkeep · %s each day" % upkeep,"note")
	_rule(column)
	var buttons:=HBoxContainer.new(); buttons.add_theme_constant_override("separation",8); column.add_child(buttons)
	var back:=Forts.recovered(fort)
	var move:=Kit.button(buttons,"Move",true,func()->void:start_move(id),"Keeps %d%% of its work and costs a quarter of a new fort's materials. Until it stands again it holds no ground." % roundi(Forts.MOVE_KEEP*100.0))
	move.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var break_down:=func()->void:
		Forts.dismantle(id)
		_close_note(); _changed()
	var remove:=Kit.button(buttons,"Break down",false,break_down,"Take it down: %s back to the stores. The ground it held is no longer ours." % (_materials(back,1.0) if not back.is_empty() else "nothing"))
	remove.add_theme_color_override("font_color",T.RED_TEXT)
	remove.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if not back.is_empty(): Kit.label(column,"Broken down it gives back %s." % _materials(back,1.0),"note")
	_place_note()

func start_move(id:int)->void:
	moving=id
	if is_instance_valid(note): note.visible=false
	_changed()

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
	if is_instance_valid(key_card) and Rect2(at,note.size).intersects(key_card.get_global_rect().grow(12)):
		at.x=key_card.position.x+key_card.size.x+16
	at.x=clampf(at.x,T.RAIL_WIDTH+8.0,maxf(T.RAIL_WIDTH+8.0,view.x-note.size.x-16))
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
	var standing:=Forts.standing().size()
	var going:=Forts.forts().filter(func(f:Dictionary)->bool:return String(f.get("status",""))=="building").size()
	var to_man:=Forts.share_to_man()
	var compact:=get_viewport().get_visible_rect().size.y<800.0
	var signature:=hash([compact,kept,snappedf(float(bill.food_lost),0.1),Forts.border_share(),standing,going,String(next.get("id","")),moving,to_man,T.color_mode])
	if signature==_key_signature: return
	_key_signature=signature
	key_card.theme=T.control_theme()
	key_card.add_theme_stylebox_override("panel",Kit.card_style(14,PLUM if T.is_light() else T.VIOLET))
	for child in key_card.get_children(): child.hide(); child.queue_free()
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",6 if compact else 10); column.custom_minimum_size=Vector2(304,0); key_card.add_child(column)
	var head:=_heading(column,"The frontier","The border",String(next.get("id","watch_camp")))
	var close:=Kit.quiet_button(head,"×",func()->void:set_shown(terrain,false),"Leave border view")
	close.name="CloseBorder"; close.custom_minimum_size=Vector2(36,36)
	Kit.label(column,"%d fort%s standing%s" % [standing,"" if standing==1 else "s",(" · %d going up" % going) if going>0 else ""],"note")
	var numbers:=HBoxContainer.new(); numbers.add_theme_constant_override("separation",14); column.add_child(numbers)
	_metric(numbers,"Posted",str(int(kept.posted)))
	_metric(numbers,"On the line",str(int(kept.line)))
	_metric(numbers,"Food lost / day",_amount(float(bill.food_lost)))
	var holds:=Kit.section(column,10); holds.add_theme_constant_override("separation",6)
	var strength_ink:=T.TEAL if line>=0.7 else (T.AMBER if line>=0.4 else T.RED)
	_status(holds,"The line holds" if km>0.0 else "Open country","%d%%" % roundi(line*100.0) if km>0.0 else "Unlinked",strength_ink if km>0.0 else T.INK_MUTED)
	_bar(holds,line,strength_ink)
	if km>0.0:
		Kit.label(holds,"%d in 100 crossings stopped · %d km of line" % [roundi(line*100.0),roundi(km)],"note")
	else:
		Kit.label(holds,"Link standing forts to watch the land between them.","note")
	if km>0.0 and int(kept.line)<=0:
		Kit.label(holds,"The garrisons take everyone posted. No one is left to walk the line.","note",T.RED)
	var share_row:=HBoxContainer.new(); share_row.add_theme_constant_override("separation",8); column.add_child(share_row)
	var share_words:=VBoxContainer.new(); share_words.size_flags_horizontal=Control.SIZE_EXPAND_FILL; share_words.add_theme_constant_override("separation",0); share_row.add_child(share_words)
	Kit.label(share_words,"Watch sent out","body")
	Kit.label(share_words,"%d%% of the watch at home" % roundi(Forts.border_share()*100.0),"note")
	for step:Array in [["−",-0.1,"Fewer on the border: less food lost on the road, a thinner line."],["+",0.1,"More on the border: forts manned first, then the line between them."]]:
		var b:=Kit.button(share_row,String(step[0]),false,func()->void:Forts.set_border_share(clampf(Forts.border_share()+float(step[1]),0.0,1.0));_changed(),String(step[2]))
		b.name="FewerBorderWatch" if float(step[1])<0.0 else "MoreBorderWatch"
		b.custom_minimum_size=Vector2(36,36)
		b.disabled=Forts.border_share()<=0.0 if float(step[1])<0.0 else Forts.border_share()>=1.0
	if to_man>Forts.border_share()+0.001:
		var man:=Kit.button(column,"Man every fort · %d%% of the watch" % roundi(to_man*100.0),true,func()->void:Forts.set_border_share(to_man);_changed(),"Sends enough of the watch at home to fill the garrisons, if available. More food is lost on the road; fewer keep watch at home.")
		man.name="ManEveryFort"
	_rule(column)
	if next.is_empty(): Kit.label(column,"Our people know no way to raise a fort yet.","note")
	elif moving>=0:
		Kit.label(column,"Moving %s" % String(Forts.find_fort(moving).get("name","the fort")),"heading",T.VIOLET)
		Kit.label(column,"Choose new ground. The preview shows what changes.","note")
		Kit.button(column,"Cancel move",false,func()->void:_let_go(),"Keep the fort where it stands · Esc or right-click")
	else:
		Kit.label(column,"Click open land to raise a %s." % String(next.name).to_lower(),"body")
		if not compact: Kit.label(column,"Inspect a fort for orders. Preview the cost before you place.","note")
	if not compact: _legend(column)

## A compact field-atlas heading. Its seal uses the actual available fort kind.
func _heading(parent:Node,kicker:String,title:String,kind_id:String,building:bool=false)->HBoxContainer:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",12); parent.add_child(row)
	var seal:=FortSeal.new(); seal.kind_id=kind_id; seal.building=building; seal.custom_minimum_size=Vector2(52,58); row.add_child(seal)
	var words:=VBoxContainer.new(); words.size_flags_horizontal=Control.SIZE_EXPAND_FILL; words.add_theme_constant_override("separation",0); row.add_child(words)
	Kit.label(words,kicker,"kicker")
	var name_label:=Kit.label(words,title,"title")
	name_label.add_theme_font_override("font",T.voice_font()); name_label.add_theme_font_size_override("font_size",28)
	return row

func _metric(parent:Node,caption:String,value:String,tone:Color=Color.TRANSPARENT)->void:
	var col:=VBoxContainer.new(); col.size_flags_horizontal=Control.SIZE_EXPAND_FILL; col.add_theme_constant_override("separation",0); parent.add_child(col)
	var number:=Kit.label(col,value,"value",tone)
	number.add_theme_font_size_override("font_size",22)
	Kit.label(col,caption,"note")

func _status(parent:Node,caption:String,value:String,tone:Color)->void:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",10); parent.add_child(row)
	Kit.label(row,caption,"body").size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Kit.label(row,value,"heading",tone,false)

func _rule(parent:Node)->void:
	var line:=HSeparator.new(); line.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(line)

func _legend(parent:Node)->void:
	var swatches:=LegendInk.new(); swatches.custom_minimum_size=Vector2(270,40); parent.add_child(swatches)

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


## A cartographer's seal: status and kind, with small compass ticks.
class FortSeal extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	var kind_id:="watch_camp"
	var building:=false
	func _ready()->void: mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		var c:=Vector2(26,28)
		draw_circle(c,24,T.PAPER_SUNK)
		draw_arc(c,24,0,TAU,48,T.RULE,1,true)
		for i in 4:
			var spoke:=Vector2.from_angle(TAU*float(i)/4.0)
			draw_line(c+spoke*21,c+spoke*26,T.GOLD,1,true)
		var glyph:=Icons.chart_texture("fort:%s%s" % [kind_id,":building" if building else ""],T.text_for(T.VIOLET),64)
		draw_texture_rect(glyph,Rect2(c-Vector2(19,19),Vector2(38,38)),false)

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
		var ink:=PLUM if T.is_light() else T.VIOLET
		var rows:=[[3.2,0.97,false,"Strong line → fewer crossings"],[1.4,0.62,true,"Dotted line → open country"]]
		for i in rows.size():
			var row:Array=rows[i]
			var y:=10.0+float(i)*20.0
			if bool(row[2]):
				for k in 4: draw_circle(Vector2(4.0+float(k)*7.0,y),1.6,Color(ink,float(row[1])))
			else: draw_line(Vector2(0,y),Vector2(26,y),Color(ink,float(row[1])),float(row[0]),true)
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
	var _quote_age:=0.0
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
	var _foreign:Array=[]

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func forget()->void:
		_quote={}; _quote_key=Vector2i(1<<30,1<<30)

	func _process(delta:float)->void:
		if owner_map==null: return
		_elapsed+=delta
		_quote_age+=delta
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
			if key!=_quote_key or _quote_moving!=int(owner_map.moving) or _quote_age>=0.5:
				_quote_age=0.0
				_quote_key=key; _quote_moving=int(owner_map.moving)
				_quote=Forts.quote(_ground,int(owner_map.moving))
		queue_redraw()

	func _read_border()->void:
		_names=[]; _stretches=[]
		for f:Dictionary in Forts.forts():
			if String(f.get("status",""))!="abandoned": _names.append([Forts._pos(f),String(f.get("name",""))])
		var kept:=Forts.watch()
		for st:Dictionary in kept.stretches: _stretches.append([Vector2(st.mid),float(st.strength),float(st.per_km)])
		_foreign=[]
		for f:Dictionary in Forts.known_foreign_forts(): _foreign.append([f.at,"%s's %s" % [String(f.owner_name),String(Forts.kind(String(f.kind)).get("name","fort")).to_lower()],preload("res://scripts/nation_borders.gd").nation_color(String(f.owner)).darkened(0.45)])

	func _draw()->void:
		_draw_border_words()
		_draw_selection()
		if not _mouse.is_finite(): return
		if not _hover_fort.is_empty(): _draw_fort_hover(); return
		if _ground.is_finite() and not _quote.is_empty() and _quote.has("kind"): _draw_ghost()

	func _draw_selection()->void:
		if int(owner_map.selected)<0 or int(owner_map.moving)>=0: return
		var fort:=Forts.find_fort(int(owner_map.selected))
		if fort.is_empty(): return
		var at:Vector2=owner_map.call("screen_of",Forts._pos(fort))
		if not at.is_finite(): return
		draw_arc(at,25,0,TAU,48,Color(PAPER,0.95),5,true)
		draw_arc(at,25,0,TAU,48,PLUM,1.5,true)
		for i in 4:
			var spoke:=Vector2.from_angle(TAU*float(i)/4.0)
			draw_line(at+spoke*23,at+spoke*30,PLUM,2,true)

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
		for row:Array in _foreign:
			var s:Vector2=owner_map.call("screen_of",row[0])
			if not s.is_finite(): continue
			var text:=String(row[1])
			var w:=voice.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
			var at:=s+Vector2(-w*0.5,28)
			draw_string_outline(voice,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,5,Color(PAPER,0.92))
			draw_string(voice,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,row[2])
		for row:Array in _stretches:
			var s:Vector2=owner_map.call("screen_of",row[0])
			if not s.is_finite(): continue
			var strength:float=row[1]
			var text:="holds %d in 100 · %s a km" % [roundi(strength*100.0),str(snappedf(float(row[2]),0.1)).trim_suffix(".0")]
			var w:=ui.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			var box:=Rect2(s-Vector2(w*0.5+8,10),Vector2(w+16,20))
			var ink:=T.TEAL if strength>=0.7 else (T.AMBER if strength>=0.4 else T.RED)
			draw_style_box(T.flat(T.PAPER_RAISED,Color(ink,0.9),1,3,0),box)
			draw_rect(Rect2(box.position+Vector2(1,box.size.y-4),Vector2((box.size.x-2)*clampf(strength,0.0,1.0),3)),ink)
			draw_string(ui,box.position+Vector2(8,14),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)

	## The border as it would run with the fort there: a dashed plum line over
	## a faint wash, so the ground it takes in reads before the click.
	func _draw_new_border(points:PackedVector2Array)->void:
		if points.size()<3:return
		var screen:=PackedVector2Array()
		for p:Vector2 in points:
			var s:Vector2=owner_map.call("screen_of",p)
			if s.is_finite():screen.append(s)
		if screen.size()<3:return
		screen.append(screen[0])
		for i in range(1,screen.size()):
			draw_line(screen[i-1],screen[i],Color(PAPER,0.55),4.0,true)
			_dashed(screen[i-1],screen[i],Color(PLUM,0.9),2.0)

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
			_draw_new_border(_quote.get("outline",PackedVector2Array()))
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
		var moving:=int(owner_map.moving)>=0
		var title:=("Move %s" % String(Forts.find_fort(int(owner_map.moving)).get("name","the fort"))) if moving else String(q.kind_name)
		var rows:Array=[]
		var refusal:Dictionary=owner_map.get("_refusal")
		if not refusal.is_empty() and Time.get_ticks_msec()<int(refusal.until): rows.append([String(refusal.text),T.RED_TEXT,true])
		var problem:=String(q.get("problem",""))
		var hero:={}
		if problem!="":
			rows.append([problem,T.RED_TEXT,true])
			rows.append(["Choose another place on known, open land.",T.BODY,false])
		else:
			if moving: rows.append(["Holds no ground while it goes up again.",T.AMBER_TEXT,false])
			rows.append(["%d watch · about %d days · %d km from home" % [int(q.garrison),int(q.days),roundi(float(q.km))],T.BODY,false])
			rows.append(["Materials · %s" % owner_map.call("_materials",q.cost,1.0),T.INK,true])
			if not (q.short as Dictionary).is_empty(): rows.append([Forts.short_words(q),T.RED_TEXT,true])
			rows.append(["Road loss · %s food/day (%d%% of supplies carried)" % [owner_map.call("_amount",float(q.food_lost)),roundi(float(q.loss_share)*100.0)],T.BODY,false])
			var up:=String(owner_map.call("_materials",q.upkeep,1.0))
			if up!="": rows.append(["Upkeep · %s/day" % up,T.MUTED,false])
			var gain:=float(q.gain_km2)
			if absf(gain)>=1.0:
				hero={"value":("%s%s km²" % ["+" if gain>0.0 else "−",_thousands(absf(gain))]),"caption":"Ground gained when it stands" if gain>0.0 else "Ground given up after moving","ink":T.TEAL if gain>0.0 else T.RED}
			else:
				hero={"value":"No new ground","caption":"This site is inside the border","ink":T.INK_MUTED}
			if (q.links as Array).is_empty(): rows.append(["A lone post. Link another fort to watch the line.",T.AMBER_TEXT,false])
			for link:Dictionary in q.links: rows.append(["Links to %s · %d km of line" % [String(link.name),roundi(float(link.km))],T.BODY,false])
		rows.append([("Click to set it down · Esc to cancel" if moving else "Click to raise this fort") if ok else "Cannot place here",T.VIOLET_TEXT if ok else T.RED_TEXT,true])
		_tip(title,rows,T.VIOLET if ok else T.RED,String(q.kind),hero)

	func _draw_fort_hover()->void:
		var f:=_hover_fort
		if int(owner_map.selected)==int(f.id) and is_instance_valid(owner_map.note) and owner_map.note.visible: return
		var s:Vector2=owner_map.call("screen_of",Forts._pos(f))
		if s.is_finite():
			draw_arc(s,22.0,0.0,TAU,40,Color(PAPER,0.8),5.0,true)
			draw_arc(s,22.0,0.0,TAU,40,Color(PLUM,0.95),2.0,true)
			if String(f.get("status",""))=="standing": _circle(Forts._pos(f),Forts.reach_of(f),Color(PLUM,0.6),true)
		var k:=Forts.kind(String(f.kind))
		var kept:=Forts.watch()
		var manned:=int(kept.garrisons.get(int(f.id),0))
		var status:="Going up, %d in 100 raised" % roundi(100.0*float(f.get("progress",0.0))/maxf(1.0,float(k.get("work",1.0)))) if String(f.status)=="building" else "Kept %d in 100" % roundi(100.0*float(f.get("condition",1.0)))
		_tip(String(f.get("name","")),[[String(k.get("name","")),T.MUTED,false],[status,T.BODY,false],["%d of %d to man it · %d km out" % [manned,int(k.get("garrison",0)),roundi(Forts._pos(f).distance_to(Forts.seat()))],T.RED_TEXT if manned<int(k.get("garrison",0)) else T.BODY,false],["Click for orders: move it or break it down",T.MUTED,false]],T.VIOLET,String(f.kind),{},String(f.status)=="building")

	## A paper note beside the pointer: a title and rows [text, colour, strong].
	func _tip(title:String,rows:Array,accent:Color,kind_id:String="",hero:Dictionary={},building:bool=true)->void:
		var ui:=T.font("ui"); var strong:=T.font("ui_strong"); var voice:=T.voice_font()
		var view:=get_viewport_rect().size
		var width:=minf(TIP_WIDTH,view.x-T.RAIL_WIDTH-80.0)
		var title_width:=width-52.0 if kind_id!="" else width
		var title_height:=maxf(40.0,voice.get_multiline_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,title_width,24).y)
		var height:=title_height+32.0
		if not hero.is_empty(): height+=70.0
		for row:Array in rows:
			if String(row[0])!="":
				var face:=strong if bool(row[2]) else ui
				height+=face.get_multiline_string_size(String(row[0]),HORIZONTAL_ALIGNMENT_LEFT,width,14).y+8.0
		var box:=Vector2(width+32.0,height+12.0)
		var origin:=_tip_origin(box,view)
		var rect:=Rect2(origin,box)
		draw_style_box(T.flat(Color(0.12,0.09,0.05,0.16),Color.TRANSPARENT,0,4,0),Rect2(rect.position+Vector2(0,4),rect.size).grow(3))
		draw_style_box(T.paper_panel_style(true,4,0),rect)
		draw_rect(Rect2(origin,Vector2(box.x,3)),accent)
		var title_x:=origin.x+16.0
		if kind_id!="":
			var c:=origin+Vector2(35,38)
			draw_circle(c,22,T.PAPER_SUNK)
			draw_arc(c,22,0,TAU,40,T.RULE,1,true)
			draw_texture_rect(Icons.chart_texture("fort:%s%s" % [kind_id,":building" if building else ""],T.text_for(accent),64),Rect2(c-Vector2(18,18),Vector2(36,36)),false)
			title_x+=52.0
		draw_multiline_string(voice,Vector2(title_x,origin.y+16.0+voice.get_ascent(24)),title,HORIZONTAL_ALIGNMENT_LEFT,title_width,24,-1,T.INK)
		var y:=origin.y+title_height+24.0
		draw_line(Vector2(origin.x+16,y),Vector2(origin.x+box.x-16,y),T.RULE,1)
		y+=12.0
		if not hero.is_empty():
			var hero_ink:Color=T.text_for(hero.ink)
			draw_style_box(T.flat(T.PAPER_SUNK,Color.TRANSPARENT,0,2,0),Rect2(Vector2(origin.x+12,y),Vector2(box.x-24,60)))
			draw_rect(Rect2(Vector2(origin.x+12,y),Vector2(3,60)),hero.ink)
			draw_string(strong,Vector2(origin.x+24,y+27),String(hero.value),HORIZONTAL_ALIGNMENT_LEFT,width-16,23,hero_ink)
			draw_string(ui,Vector2(origin.x+24,y+47),String(hero.caption),HORIZONTAL_ALIGNMENT_LEFT,width-16,13,T.INK_MUTED)
			y+=70
		for row:Array in rows:
			var words:=String(row[0])
			if words=="": continue
			var face:=strong if bool(row[2]) else ui
			draw_multiline_string(face,Vector2(origin.x+16,y+face.get_ascent(14)),words,HORIZONTAL_ALIGNMENT_LEFT,width,14,-1,row[1])
			y+=face.get_multiline_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,width,14).y+8.0

	## Prefer a free corner around the pointer, avoiding the persistent cards.
	func _tip_origin(box:Vector2,view:Vector2)->Vector2:
		var best:=Vector2.ZERO; var penalty:=INF
		var choices:=[_mouse+Vector2(30,18),_mouse-Vector2(box.x+30,-18),_mouse-Vector2(-30,box.y+18),_mouse-box-Vector2(30,18)]
		for choice:Vector2 in choices:
			var at:=Vector2(clampf(choice.x,T.RAIL_WIDTH+8.0,maxf(T.RAIL_WIDTH+8.0,view.x-box.x-12)),clampf(choice.y,T.CONTENT_TOP,maxf(T.CONTENT_TOP,view.y-box.y-150)))
			var rect:=Rect2(at,box); var cost:=at.distance_to(choice)
			for card:Control in [owner_map.key_card,owner_map.note]:
				if is_instance_valid(card) and card.visible:
					var overlap:=rect.intersection(card.get_global_rect().grow(12))
					cost+=overlap.get_area()
			if rect.has_point(_mouse): cost+=10000
			if cost<penalty: penalty=cost; best=at
		return best

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
