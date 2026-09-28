extends Control
## THE ARMY BAR: HOI4's strip of army cards along the bottom of the map.
##
## One paper card per army, band, garrison and the levy at home
## (hud/army_bar_model.gd gives every number). A card shows the general's
## face and name, the men, three bars (gear, will to fight, supply) and one
## state glyph. Click finds the army and selects it; double-click opens its
## orders (the army command panel, or a held town's own view). An army of
## several bands lists them in a small row above the bar when selected.
## Hovering a bar says what it means and what holds it back; clicking a short
## gear bar opens production. Numbers only; the sentences live in tooltips.

signal army_selected(card:Dictionary)
signal army_opened(card:Dictionary)

const Model:=preload("res://scripts/hud/army_bar_model.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const CARD_SIZE:=Vector2(204,70)
const CHIP_SIZE:=Vector2(150,30)
const GAP:=6.0
const REFRESH_SECONDS:=0.5

var terrain:Node
var cards:Array[Dictionary]=[]
var selected_id:=""
var scroll:=0
var area:=Rect2()
var clock:=REFRESH_SECONDS
var _shape:=""
var strip:Control
var members:Control
var left_button:Button
var right_button:Button


func _ready()->void:
	name="ArmyBar"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	members=Control.new();members.name="Bands";members.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(members)
	strip=Control.new();strip.name="Cards";strip.mouse_filter=Control.MOUSE_FILTER_IGNORE;strip.clip_contents=true;add_child(strip)
	left_button=_arrow("‹",-1);right_button=_arrow("›",1)
	refresh()
	_mount_plans.call_deferred()


## The battle plans the generals are carrying out stay drawn on the map, as
## HOI4 keeps its front lines: under the rest of the HUD, over the ground.
var plans:Control

func _exit_tree()->void:
	if is_instance_valid(plans):plans.queue_free()

func _mount_plans()->void:
	var hud:=get_parent()
	# Only under the HUD shell (hud/command_rail_hud.gd), never another parent.
	if hud==null or not hud.has_method("_position_army_bar") or is_instance_valid(plans):return
	plans=PlanInk.new();plans.bar=self;plans.name="BattlePlans"
	hud.add_child(plans);hud.move_child(plans,0)


func _arrow(text:String,step:int)->Button:
	var button:=Button.new();button.text=text;button.focus_mode=Control.FOCUS_NONE
	button.custom_minimum_size=Vector2(22,CARD_SIZE.y);button.size=button.custom_minimum_size
	button.tooltip_text="More armies" if step>0 else "Earlier armies"
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_color_override("font_color",T.INK);button.add_theme_color_override("font_hover_color",T.INK)
	button.add_theme_stylebox_override("normal",T.action_button_style(false));button.add_theme_stylebox_override("hover",T.action_button_style(false,true))
	button.add_theme_stylebox_override("pressed",T.button_pressed_style());button.add_theme_stylebox_override("disabled",T.button_disabled_style())
	button.pressed.connect(func():scroll=clampi(scroll+step,0,maxi(0,cards.size()-_fits()));_arrange())
	add_child(button);button.hide()
	return button


## Height the bar needs, including the bands row of a selected army.
func bar_height()->float:
	return CARD_SIZE.y+((CHIP_SIZE.y+GAP) if _selected_group().size()>1 else 0.0)


## The HUD gives the bar the stretch of screen above the map toolbar.
func place(rect:Rect2)->void:
	area=rect
	position=rect.position;size=rect.size
	_arrange()


func _fits()->int:
	return maxi(1,floori((area.size.x+GAP)/(CARD_SIZE.x+GAP)))


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


func refresh()->void:
	var fresh:=Model.cards()
	# A selection made on the map shows on the bar too.
	if is_instance_valid(terrain) and "selected_army_id" in terrain:
		var on_map:=int(terrain.selected_army_id)
		if on_map>0:
			for card:Dictionary in fresh:
				if on_map in (card.members as Array) and String(card.id)!=selected_id and not _member_selected(card,on_map):selected_id=String(card.id)
	var shape:=str(fresh.map(func(c:Dictionary)->String:return String(c.id)))+selected_id
	cards=fresh
	visible=not cards.is_empty()
	if shape!=_shape:
		_shape=shape
		_rebuild()
	else:
		for node in strip.get_children()+members.get_children():
			if node.has_method("bind"):
				for card:Dictionary in _all_cards():
					if String(card.id)==String(node.card_id):node.bind(card,_is_selected(card));break


func _member_selected(card:Dictionary,army_id:int)->bool:
	return selected_id=="army:%d" % army_id and String(card.kind)=="group"


func _all_cards()->Array:
	var out:Array=cards.duplicate()
	for card:Dictionary in cards:
		if String(card.kind)=="group":out.append_array(card.get("member_cards",[]))
	return out


func _is_selected(card:Dictionary)->bool:
	return String(card.id)==selected_id


func _selected_group()->Array:
	for card:Dictionary in cards:
		if String(card.kind)!="group":continue
		if String(card.id)==selected_id:return card.member_cards
		for member:Dictionary in card.member_cards:
			if String(member.id)==selected_id:return card.member_cards
	return []


func _rebuild()->void:
	for node in strip.get_children()+members.get_children():
		node.get_parent().remove_child(node);node.queue_free()
	for card:Dictionary in cards:
		var face:=ArmyCard.new();face.bar=self;strip.add_child(face);face.bind(card,_is_selected(card))
	for card:Dictionary in _selected_group():
		var chip:=BandChip.new();chip.bar=self;members.add_child(chip);chip.bind(card,_is_selected(card))
	scroll=clampi(scroll,0,maxi(0,cards.size()-_fits()))
	# The bands row changes the bar's height: the HUD places it again.
	var hud:=get_parent()
	if hud!=null and hud.has_method("_position_army_bar"):hud.call_deferred("_position_army_bar")
	_arrange()


func _arrange()->void:
	if strip==null:return
	var count:=strip.get_child_count()
	var fits:=_fits()
	var overflow:=count>fits
	var shown:=mini(count,fits)
	var width:=shown*CARD_SIZE.x+maxi(0,shown-1)*GAP
	var chips:=members.get_child_count()
	var top:=size.y-CARD_SIZE.y
	var left:=maxf(0.0,(size.x-width)*0.5)
	strip.position=Vector2(left,top);strip.size=Vector2(width,CARD_SIZE.y)
	var i:=0
	for node:Control in strip.get_children():
		if node.is_queued_for_deletion():continue
		node.position=Vector2((i-scroll)*(CARD_SIZE.x+GAP),0);node.size=CARD_SIZE
		i+=1
	left_button.visible=overflow;right_button.visible=overflow
	left_button.disabled=scroll<=0;right_button.disabled=scroll>=count-fits
	left_button.position=Vector2(left-28,top);right_button.position=Vector2(left+width+6,top)
	var chip_width:=chips*CHIP_SIZE.x+maxi(0,chips-1)*GAP
	members.position=Vector2(maxf(0.0,(size.x-chip_width)*0.5),top-CHIP_SIZE.y-GAP);members.size=Vector2(chip_width,CHIP_SIZE.y)
	var j:=0
	for node:Control in members.get_children():
		if node.is_queued_for_deletion():continue
		node.position=Vector2(j*(CHIP_SIZE.x+GAP),0);node.size=CHIP_SIZE
		j+=1


# --- Acting on a card ----------------------------------------------------------

func select_card(card:Dictionary)->void:
	selected_id=String(card.id)
	var army:=int(card.get("army_id",-1))
	if is_instance_valid(terrain):
		if "selected_army_id" in terrain:terrain.selected_army_id=army if String(card.kind) in ["army","group"] else -1
		var at:Vector2=card.get("position",Vector2.INF)
		if at.is_finite() and terrain.has_method("_set_camera_target") and terrain.has_method("_height_at"):
			terrain._set_camera_target(Vector3(at.x,terrain._height_at(at.x,at.y),at.y))
		if terrain.has_method("_refresh_player_field_army_markers"):terrain._refresh_player_field_army_markers()
	# The open army panel follows the bar.
	var screen:Variant=MilitaryCampaign.joint_operations.screen
	if is_instance_valid(screen) and String(screen.get("domain"))=="army" and screen.has_method("choose_force") and String(card.kind)!="garrison":
		screen.choose_force(army)
	_shape=""
	refresh()
	army_selected.emit(card)


func open_card(card:Dictionary)->void:
	select_card(card)
	if String(card.kind)=="garrison":
		preload("res://scripts/hud/occupation_view.gd").open(String(card.civ_id),String(card.region_id))
	else:
		var screen:Variant=MilitaryCampaign.joint_operations.screen
		if not (is_instance_valid(screen) and String(screen.get("domain"))=="army"):
			MilitaryCampaign.joint_operations.open_hierarchy("army")
			screen=MilitaryCampaign.joint_operations.screen
		if is_instance_valid(screen) and screen.has_method("choose_force"):screen.choose_force(int(card.get("army_id",0)))
	army_opened.emit(card)


func open_production()->void:
	if is_instance_valid(terrain) and "hud" in terrain and terrain.hud and terrain.hud.has_method("open_dock"):
		terrain.hud.open_dock("production",2)


class ArmyCard extends Control:
	## One army's card: face, name, men, three bars, a state glyph.
	var bar:Node
	var card:Dictionary={}
	var card_id:=""
	var chosen:=false
	var face:TextureRect
	var face_frame:Panel
	var hovered:=false
	const PAD:=5.0

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_STOP
		custom_minimum_size=CARD_SIZE
		face_frame=Panel.new();face_frame.clip_contents=true;face_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
		face_frame.position=Vector2(PAD,PAD);face_frame.size=Vector2(44,58)
		var ground:=StyleBoxFlat.new();ground.bg_color=T.PAPER_SUNK;face_frame.add_theme_stylebox_override("panel",ground)
		add_child(face_frame)
		face=TextureRect.new();face.mouse_filter=Control.MOUSE_FILTER_IGNORE;face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);face_frame.add_child(face)
		mouse_entered.connect(func():hovered=true;queue_redraw())
		mouse_exited.connect(func():hovered=false;queue_redraw())
		if not card.is_empty():_face()

	func bind(data:Dictionary,is_chosen:bool)->void:
		var changed_face:bool=String(card.get("id",""))!=String(data.id) or card.get("general",{})!=data.get("general",{})
		card=data;card_id=String(data.id);chosen=is_chosen
		tooltip_text=Model.tooltip(card)
		if changed_face and is_instance_valid(face):_face()
		queue_redraw()

	func _face()->void:
		var general:Dictionary=card.get("general",{})
		match String(card.get("kind","")):
			"home":
				face.texture=Icons.command_texture("home",T.INK,64);face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				return
			"garrison":
				if general.is_empty():
					face.texture=Icons.command_texture("defend",T.INK,64);face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					return
		if general.is_empty():
			face.texture=Icons.command_texture("will",T.INK,64);face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			return
		face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.texture=Portrait.texture({"name":String(general.get("full_name",general.get("name",""))),"person_id":absi(String(general.get("figure_id",general.get("name",""))).hash())%997+1})

	func _gui_input(event:InputEvent)->void:
		if not (event is InputEventMouseButton) or not event.pressed:return
		if event.button_index!=MOUSE_BUTTON_LEFT:return
		accept_event()
		if event.double_click:bar.open_card(card);return
		if _gear_rect().grow(3).has_point(event.position) and not (card.get("gear_detail",{}).get("missing",{}) as Dictionary).is_empty():
			bar.select_card(card);bar.open_production();return
		bar.select_card(card)

	func _body_left()->float:return PAD+44.0+8.0
	## Gear, will and supply, one under another, each after its mark.
	func _bar_rect(row:int)->Rect2:
		var left:=_body_left()+17.0
		return Rect2(Vector2(left,29.0+float(row)*13.0),Vector2(size.x-left-PAD-3.0,7.0))
	func _gear_rect()->Rect2:return _bar_rect(0)

	func _get_tooltip(at:Vector2)->String:
		if card.is_empty():return ""
		for row in 3:
			var rect:=_bar_rect(row).grow_individual(16,3,2,3)
			if rect.has_point(at):
				match row:
					0:return Model.gear_words(card.get("gear_detail",{}))
					1:return Model.will_words(float(card.will))+"\nBelow a quarter they break."
					2:return Model.supply_line(card)
		return tooltip_text

	func _draw()->void:
		if card.is_empty():return
		var box:=Rect2(Vector2.ZERO,size)
		var style:=StyleBoxFlat.new()
		style.bg_color=T.HOVER_BG if hovered else T.PAPER_RAISED
		style.border_color=T.GOLD if chosen else T.RULE
		style.set_border_width_all(1);style.set_corner_radius_all(T.RADIUS_CARD)
		if chosen:style.border_width_top=3
		style.shadow_color=Color(0,0,0,0.16 if T.is_light() else 0.4);style.shadow_size=4;style.shadow_offset=Vector2(0,2)
		draw_style_box(style,box)
		var fade:=0.55 if bool(card.get("unknown",false)) else 1.0
		var strong:=T.font("ui_strong")
		var left:=_body_left()
		# The state glyph at the shoulder, then the men, then the name.
		BattleMarks.draw_state(self,Vector2(size.x-PAD-8.0,13.0),String(card.get("state","holding")),7.0,fade)
		var men:=EraWords.grouped(int(card.get("men",0)))
		var men_w:=strong.get_string_size(men,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
		var men_x:=size.x-PAD-20.0-men_w
		draw_texture_rect(Icons.command_texture("men",T.INK,32),Rect2(Vector2(men_x-17.0,4.0),Vector2(16,16)),false,Color(1,1,1,fade))
		draw_string(strong,Vector2(men_x,18),men,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(T.INK,fade))
		var group:=String(card.get("kind",""))=="group"
		var badge:=" ×%d" % (card.members as Array).size() if group else ""
		var badge_w:=strong.get_string_size(badge,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x if group else 0.0
		var room:=men_x-19.0-left-badge_w-4.0
		var name:=String(card.get("short",card.get("title","")))
		draw_string(strong,Vector2(left,18),name,HORIZONTAL_ALIGNMENT_LEFT,room,14,Color(T.INK,fade),TextServer.JUSTIFICATION_NONE)
		if group:draw_string(strong,Vector2(left+minf(room,strong.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x)+2.0,18),badge,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.GOLD_TEXT)
		# Gear, will, supply.
		var gear:=float(card.get("gear",1.0))
		var rows:=[["gear",gear,Model.gear_color(gear)],["will",float(card.get("will",0.6)),Model.will_color(float(card.get("will",0.6)))],["supply",float(card.get("supply",1.0)),Model.supply_color(String(card.get("supply_state","well")))]]
		for row in 3:
			var rect:=_bar_rect(row)
			draw_texture_rect(Icons.command_texture(String(rows[row][0]),T.INK_MUTED,32),Rect2(Vector2(left,rect.position.y-4.0),Vector2(14,14)),false,Color(1,1,1,fade))
			Model.draw_bar(self,rect,float(rows[row][1]),Color(rows[row][2],fade))


class PlanInk extends Control:
	## Front lines drawn by the player (army_orders.gd give_plan) that a
	## general is holding: an inked line with its teeth. The army command
	## panel draws them itself while it is open.
	var bar:Node
	var clock:=0.0
	var heights:Dictionary={}

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta:float)->void:
		clock+=delta
		if clock>=0.1:clock=0.0;queue_redraw()

	func _screen(terrain:Node,point:Dictionary)->Vector2:
		var at:=Vector2(float(point.get("x",0.0)),float(point.get("z",0.0)))
		if not heights.has(at):
			if heights.size()>2048:heights.clear()
			heights[at]=float(terrain._height_at(at.x,at.y))
		var world:=Vector3(at.x,float(heights[at])+0.001,at.y)
		if terrain.camera.is_position_behind(world):return Vector2.INF
		return terrain.camera.unproject_position(world)

	func _draw()->void:
		var terrain:Node=bar.terrain if bar!=null else null
		if not is_instance_valid(terrain) or not ("camera" in terrain) or terrain.camera==null:return
		if is_instance_valid(MilitaryCampaign.joint_operations.screen):return
		var command:RefCounted=MilitaryCampaign.command_hierarchy
		var held:={}
		for entry:Dictionary in command.data.nodes.values():
			var order:Dictionary=entry.get("order",{})
			if String(order.get("mission",""))=="defend":held[String(order.get("zone_id",""))]=true
		var ink:=BattleMarks.OXBLOOD
		for region:Dictionary in command.data.zones:
			if String(region.get("plan",""))!="front" or not held.has(String(region.get("id",""))) or not region.get("line") is Array:continue
			var line:=PackedVector2Array()
			for p in region.line:
				if not p is Dictionary:continue
				var at:=_screen(terrain,p)
				if at.is_finite():line.append(at)
			if line.size()<2:continue
			draw_polyline(line,Color(BattleMarks.PAPER,0.85),6.0,true)
			draw_polyline(line,Color(ink,0.9),3.0,true)
			for i in line.size()-1:
				var a:=line[i];var b:=line[i+1];var length:=a.distance_to(b)
				if length<4.0:continue
				var along:=(b-a)/length;var out:=Vector2(along.y,-along.x)
				var t:=7.0
				while t<length:
					var base:=a+along*t
					draw_colored_polygon(PackedVector2Array([base-along*4.0,base+along*4.0,base+out*7.0]),Color(ink,0.9))
					t+=14.0


class BandChip extends Control:
	## One band of a selected army: name, men and its state glyph.
	var bar:Node
	var card:Dictionary={}
	var card_id:=""
	var chosen:=false
	var hovered:=false

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func():hovered=true;queue_redraw())
		mouse_exited.connect(func():hovered=false;queue_redraw())

	func bind(data:Dictionary,is_chosen:bool)->void:
		card=data;card_id=String(data.id);chosen=is_chosen
		tooltip_text=Model.tooltip(card)
		queue_redraw()

	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			accept_event()
			if event.double_click:bar.open_card(card)
			else:bar.select_card(card)

	func _draw()->void:
		if card.is_empty():return
		var style:=StyleBoxFlat.new()
		style.bg_color=T.HOVER_BG if hovered else T.PAPER
		style.border_color=T.GOLD if chosen else T.RULE
		style.set_border_width_all(1);style.set_corner_radius_all(T.RADIUS_CONTROL)
		if chosen:style.border_width_left=3
		draw_style_box(style,Rect2(Vector2.ZERO,size))
		BattleMarks.draw_state(self,Vector2(15,size.y*0.5),String(card.get("state","holding")),6.0)
		var strong:=T.font("ui_strong")
		var men:=EraWords.grouped(int(card.get("men",0)))
		var men_w:=strong.get_string_size(men,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(T.font("ui"),Vector2(28,size.y*0.5+5),String(card.get("short","")),HORIZONTAL_ALIGNMENT_LEFT,size.x-40-men_w,13,T.INK)
		draw_string(strong,Vector2(size.x-8-men_w,size.y*0.5+5),men,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK)
