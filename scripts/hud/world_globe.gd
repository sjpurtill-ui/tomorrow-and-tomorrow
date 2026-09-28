extends Control
## "The world": the god's view of the whole world as a turning globe, with
## how much of it our people know. Opened from the map toolbar ("World") or by
## zooming out past the far lands; zooming in, or clicking a known place,
## hands the map back there, and Close returns to where the map was.
##
## Unknown ground is blank vellum. Everything drawn on the globe comes from
## the revealed records (world_globe_chart.gd), our own towns, towns we hold,
## and other peoples' towns as they were last seen (city intelligence). Time
## keeps running while it is open; nothing here is saved.
##
## Captions stay neutral: "the world", "known to our people". Nothing here
## says the people know the world is round.

const Chart:=preload("res://scripts/world_globe_chart.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const P:=preload("res://scripts/hud/paper_sheet.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Ownership:=preload("res://scripts/map_ownership.gd")
const CityLabels:=preload("res://scripts/hud/city_labels.gd")
const SHADER:=preload("res://scripts/hud/world_globe.gdshader")
## Inner classes reach the static helpers through this self-reference.
const WorldGlobe:=preload("res://scripts/hud/world_globe.gd")
const LAYER:=76
const FOV_DEGREES:=30.0
## Eye distance in globe radii; the resting distance is fitted to the screen.
const NEAR_DISTANCE:=1.9
const REST_FILL:=0.43
## One wheel notch moves the eye this much closer (on the distance above the ground).
const WHEEL_STEP:=0.82
const IDLE_SECONDS:=4.0
const DRIFT:=0.045
const MAX_LATITUDE:=deg_to_rad(84.0)
const PLANET_RADIUS_KM:=Chart.WIDTH_KM/TAU
## Map distance levels the globe hands back to: a town at the valley, ground at the region.
const TOWN_LEVEL:=1
const GROUND_LEVEL:=2

var terrain:Node
var hud:Node
var from_zoom:=false
var chart:RefCounted
var center_lat:=0.0
var center_lon:=0.0
## Turn about the view axis: the map's heading at the hand-over, eased to north-up.
var roll:=0.0
var distance:=4.3
var distance_goal:=4.3
var rest_distance:=4.3
var spin:=Vector2.ZERO
var idle:=0.0
var drift_weight:=0.0
var dragging:=false
var drag_travel:=0.0
var drag_stamp:=0
var drag_velocity:=Vector2.ZERO
var pointer:=Vector2(-1,-1)
var opacity:=0.0
var phase:="opening"
var motion:Tween
var globe_rect:ColorRect
var globe_material:ShaderMaterial
var marks:Control
var card:PanelContainer
var close_button:Button
var hint_panel:PanelContainer
var hint_label:Label
var hint_hold:=0.0
var chart_alpha:=0.0
var map_mix:=1.0
var shown_revision:=-1
## Marks and the chart are gathered on the first frames, not while opening.
var refresh_elapsed:=0.9
## Peoples whose emblems are still to be drawn, one at a time while at rest.
var pending_emblems:=PackedStringArray()
var emblem_wait:=0.5
var marks_signature:=""
var realm_signature:=""
var tan_half_fov:=tan(deg_to_rad(FOV_DEGREES*0.5))
var headline:Label
var growth:Label
var land_value:Label
var sea_value:Label
var learned_bar:Control
var learned_rows:VBoxContainer
var previous_disable_3d:=false
var owns_3d_switch:=false
## A fixed "today" for the growth words (captures); -1 reads the calendar.
var today_override:=-1
## The eye distance the opening zoom starts from.
var opening_start:=4.3
var covered_frame:=-1
var covered_now:=false


static func open(terrain_node:Node,hud_node:Node=null,zoomed_out:=false)->Control:
	var host:Node=terrain_node if is_instance_valid(terrain_node) else (Engine.get_main_loop() as SceneTree).current_scene
	if host==null:return null
	var layer:=CanvasLayer.new()
	layer.name="WorldGlobeLayer"
	layer.layer=LAYER
	host.add_child(layer)
	var view:Control=load("res://scripts/hud/world_globe.gd").new()
	view.terrain=terrain_node if is_instance_valid(terrain_node) else null
	view.hud=hud_node
	view.from_zoom=zoomed_out
	layer.add_child(view)
	return view


func _ready()->void:
	open_views+=1
	name="WorldGlobe"
	theme=T.control_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_mode=Control.FOCUS_ALL
	# Hover words come from _get_tooltip; a blank tooltip switches them on.
	tooltip_text=" "
	chart=Chart.shared()
	globe_rect=ColorRect.new()
	globe_rect.name="Globe"
	globe_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	globe_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	globe_material=ShaderMaterial.new()
	globe_material.shader=SHADER
	globe_rect.material=globe_material
	add_child(globe_rect)
	marks=MarksLayer.new()
	marks.name="Marks"
	marks.view=self
	add_child(marks)
	_build_card()
	_build_controls()
	_apply_palette()
	var start:=_start_point()
	center_lat=start.x
	center_lon=start.y
	get_viewport().size_changed.connect(_layout)
	_layout()
	distance=_opening_distance()
	distance_goal=rest_distance
	_refresh_chart(true)
	_update_uniforms()
	_begin_opening()


func _exit_tree()->void:
	open_views=maxi(0,open_views-1)
	_set_3d_hidden(false)
	if motion and motion.is_valid():motion.kill()


# --- Layout -----------------------------------------------------------------

func view_size()->Vector2:
	return get_viewport_rect().size if is_inside_tree() else Vector2(1920,1080)


func globe_center()->Vector2:
	var view:=view_size()
	var left:=card.position.x+card.size.x if card else 0.0
	return Vector2(left+(view.x-left)*0.5,view.y*0.5+10.0)


func globe_radius()->float:
	return Chart.screen_radius(view_size().y*0.5,distance,tan_half_fov)


func _layout()->void:
	var view:=view_size()
	if card:
		var width:=clampf(view.x*0.23,330.0,420.0)
		card.position=Vector2(24,24)
		card.custom_minimum_size.x=width
		_fit_card()
	if close_button:
		close_button.reset_size()
		close_button.position=Vector2(view.x-close_button.size.x-24,24)
	if hint_panel:
		hint_panel.reset_size()
		var left:=card.position.x+card.size.x if card else 0.0
		hint_panel.position=Vector2(left+(view.x-left-hint_panel.size.x)*0.5,view.y-hint_panel.size.y-18)
	# The whole world rests at about REST_FILL of the free height.
	var free_width:=view.x-(card.position.x+card.size.x if card else 0.0)
	var radius:=minf(view.y*REST_FILL,free_width*0.44)
	var tan_edge:=radius/(view.y*0.5)*tan_half_fov
	rest_distance=sqrt(1.0+1.0/maxf(tan_edge*tan_edge,0.0001))
	if phase=="open" and distance_goal>rest_distance*1.12:distance_goal=rest_distance*1.12


## The card is as tall as its words. Wrapped labels report inflated heights
## until they have been laid out once, so this is re-asserted every frame.
func _fit_card()->void:
	if card==null:return
	var wanted:=Vector2(card.custom_minimum_size.x,card.get_combined_minimum_size().y)
	if card.size.distance_to(wanted)>0.5:card.size=wanted


# --- Opening, closing, handing the map back ---------------------------------

## Where the view starts: the map's own centre (so zooming out stays in place),
## else home.
func _start_point()->Vector2:
	var at:=Vector2.ZERO
	if is_instance_valid(terrain) and terrain.get("camera_target") is Vector3:
		var target:Vector3=terrain.get("camera_target")
		at=Vector2(target.x,target.z)
	elif CivilizationSystem!=null:
		at=CivilizationSystem.player_world_origin
	return Chart.lat_lon(at)


## The eye distance whose view matches the map's current height, so the globe
## takes over from the map at the same scale.
static func map_match_distance(map_height_km:float,tan_half:float)->float:
	return 1.0+maxf(1.0,map_height_km)*0.5/(PLANET_RADIUS_KM*tan_half)


func _map_height_km()->float:
	if is_instance_valid(terrain):
		var camera:Variant=terrain.get("camera")
		if camera is Camera3D:return maxf(1.0,(camera as Camera3D).size)
	return 1700.0


func _opening_distance()->float:
	if from_zoom:
		opening_start=minf(rest_distance*0.9,map_match_distance(_map_height_km(),tan_half_fov))
		return opening_start
	return rest_distance*0.88


## Which way the map's screen-up points, as a bearing east of north: the
## globe starts turned the same way so the hand-over does not jump.
func map_heading()->float:
	if not is_instance_valid(terrain):return 0.0
	var yaw:Variant=terrain.get("camera_yaw")
	if not (yaw is float):return 0.0
	return heading_for_yaw(float(yaw))


static func heading_for_yaw(yaw:float)->float:
	return atan2(-cos(yaw),sin(yaw))


func _begin_opening()->void:
	phase="opening"
	opacity=0.0
	roll=map_heading() if from_zoom else 0.0
	if motion and motion.is_valid():motion.kill()
	motion=create_tween().set_parallel(true)
	motion.tween_method(_set_opacity,0.0,1.0,T.MOTION.slow).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if from_zoom:
		# The globe takes over at the map's own scale and heading, then draws
		# back and turns north-up: one continuous zoom out of the map.
		var start_roll:=roll
		motion.tween_method(func(t:float)->void:
			var eased:=ease(t,-2.0)
			distance=lerpf(opening_start,rest_distance,eased)
			distance_goal=distance
			roll=start_roll*(1.0-eased)
			_update_uniforms(),0.0,1.0,1.25).set_delay(0.05)
	else:
		motion.tween_method(_set_distance,distance,rest_distance,0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.chain().tween_callback(func()->void:
		phase="open"
		roll=0.0
		distance_goal=rest_distance)


func _set_opacity(value:float)->void:
	opacity=value
	_update_uniforms()


func _set_distance(value:float)->void:
	distance=value
	distance_goal=value
	_update_uniforms()


## Close: back to the map exactly as it was.
func close()->void:
	if phase in ["closing","leaving"]:return
	phase="closing"
	_set_3d_hidden(false)
	if motion and motion.is_valid():motion.kill()
	motion=create_tween().set_parallel(true)
	motion.tween_method(_set_opacity,opacity,0.0,T.MOTION.slow).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.tween_method(_set_distance,distance,maxf(NEAR_DISTANCE,distance*0.82),T.MOTION.slow).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.chain().tween_callback(_free_view)


## Hands the map back over `position` (map km): the globe turns to it and
## closes in, the map opens beneath at the far-lands distance, then eases in
## to `level` (3 stays at the far lands).
func leave_to(position:Vector2,level:int=GROUND_LEVEL)->void:
	if phase in ["closing","leaving"]:return
	phase="leaving"
	var goal:=Chart.lat_lon(position)
	var from_lat:=center_lat
	var from_lon:=center_lon
	var turn:=wrapf(goal.y-from_lon,-PI,PI)
	var start_distance:=distance
	var arrive_distance:=map_match_distance(_far_lands_height_km(),tan_half_fov)
	var from_roll:=roll
	var arrive_roll:=from_roll+wrapf(map_heading()-from_roll,-PI,PI)
	if motion and motion.is_valid():motion.kill()
	motion=create_tween()
	motion.tween_method(func(t:float)->void:
		var eased:=ease(t,-2.2)
		center_lat=lerpf(from_lat,goal.x,eased)
		center_lon=from_lon+turn*eased
		distance=lerpf(start_distance,arrive_distance,ease(t,2.4))
		distance_goal=distance
		# Turn to the map's heading as it arrives, so the map takes over in place.
		roll=lerpf(from_roll,arrive_roll,ease(t,2.4))
		_update_uniforms(),0.0,1.0,1.1)
	motion.tween_callback(func()->void:
		_set_3d_hidden(false)
		if is_instance_valid(terrain) and terrain.has_method("_world_view_arrive"):terrain._world_view_arrive(position))
	motion.tween_method(_set_opacity,1.0,0.0,T.MOTION.slow).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.tween_callback(func()->void:
		if level<3 and is_instance_valid(terrain) and terrain.has_method("set_camera_distance_level"):terrain.set_camera_distance_level(level)
		_free_view())


func _far_lands_height_km()->float:
	if is_instance_valid(terrain) and terrain.has_method("_distance_camera_size"):
		return float(terrain._distance_camera_size(3))
	return 1700.0


func _free_view()->void:
	_set_3d_hidden(false)
	var layer:=get_parent()
	if layer is CanvasLayer:layer.queue_free()
	else:queue_free()


## While the globe covers the whole screen the map below need not be drawn.
func _set_3d_hidden(hidden:bool)->void:
	if not is_inside_tree():return
	var viewport:=get_viewport()
	if hidden and not owns_3d_switch:
		previous_disable_3d=viewport.disable_3d
		viewport.disable_3d=true
		owns_3d_switch=true
	elif not hidden and owns_3d_switch:
		viewport.disable_3d=previous_disable_3d
		owns_3d_switch=false


# --- Frame ---------------------------------------------------------------------

func _process(delta:float)->void:
	delta=clampf(delta,0.0,0.1)
	chart.poll()
	# A chart published by anyone (this view or the background prewarm) is shown.
	if chart.revision!=shown_revision and chart.current(int(GameState.world_seed)):_apply_chart()
	refresh_elapsed+=delta
	if refresh_elapsed>=1.0:
		refresh_elapsed=0.0
		_refresh_chart(false)
		_gather_marks()
	_fit_card()
	# A people's emblem not yet drawn anywhere takes a moment to draw: only one
	# at a time, and only while the view rests (never during the opening zoom).
	emblem_wait-=delta
	if not pending_emblems.is_empty() and phase=="open" and not dragging and emblem_wait<=0.0:
		_draw_one_emblem()
		emblem_wait=0.3
	if hint_hold>0.0:
		hint_hold-=delta
		if hint_hold<=0.0:hint_label.text=_hint_words()
	if phase=="open":
		_set_3d_hidden(opacity>=0.999)
		_advance_motion(delta)
	_update_uniforms()
	marks.queue_redraw()


func _advance_motion(delta:float)->void:
	if dragging:
		idle=0.0
		return
	# A released drag coasts to a stop, as a globe spun by hand.
	if spin.length()>0.0005:
		_turn(spin.x*delta,spin.y*delta)
		spin*=exp(-delta*3.2)
		idle=0.0
	else:
		spin=Vector2.ZERO
		idle+=delta
	# Left alone, the world turns slowly eastward.
	drift_weight=move_toward(drift_weight,1.0 if idle>=IDLE_SECONDS else 0.0,delta*0.5)
	if drift_weight>0.0:center_lon=wrapf(center_lon-DRIFT*drift_weight*delta,-PI,PI)
	# The eye glides to its goal distance.
	distance=lerpf(distance,distance_goal,1.0-exp(-delta*9.0))


func _turn(dlat:float,dlon:float)->void:
	center_lat=clampf(center_lat+dlat,-MAX_LATITUDE,MAX_LATITUDE)
	center_lon=wrapf(center_lon+dlon,-PI,PI)


func basis()->Basis:
	return Chart.view_basis(center_lat,center_lon,roll)


func _update_uniforms()->void:
	if globe_material==null:return
	var view:=view_size()
	globe_material.set_shader_parameter("globe_from_view",basis().inverse())
	globe_material.set_shader_parameter("eye_distance",distance)
	globe_material.set_shader_parameter("tan_half_fov",tan_half_fov)
	globe_material.set_shader_parameter("view_size",view)
	globe_material.set_shader_parameter("globe_center",globe_center())
	globe_material.set_shader_parameter("globe_radius_px",globe_radius())
	globe_material.set_shader_parameter("opacity",opacity)
	globe_material.set_shader_parameter("chart_alpha",chart_alpha)
	globe_material.set_shader_parameter("map_mix",map_mix)
	# The glow that finds a tiny known patch is for far views only.
	globe_material.set_shader_parameter("halo_strength",smoothstep(1.9,3.4,distance))
	# At the map's own scale the globe wears the map's colours (see the shader).
	globe_material.set_shader_parameter("map_likeness",1.0-smoothstep(1.52,NEAR_DISTANCE,distance))
	for control:Control in [card,close_button,hint_panel,marks]:
		if control:control.modulate.a=opacity


# --- The chart ------------------------------------------------------------------

func _refresh_chart(first:bool)->void:
	if CivilizationSystem==null:return
	var areas:Array=CivilizationSystem.revealed_areas
	chart.refresh(areas,int(GameState.world_seed),city_sources,height_source.bind(terrain))
	if first and chart.current(int(GameState.world_seed)):_apply_chart()


## Draws the chart in the background before anyone opens the view (the map's
## toolbar asks a few seconds after the world loads), so a long-travelled
## world's first opening does not wait on it. Nothing is shown or saved.
static func prewarm(terrain_node:Node)->void:
	if CivilizationSystem==null or GameState==null:return
	var model:RefCounted=Chart.shared()
	model.refresh(CivilizationSystem.revealed_areas,int(GameState.world_seed),city_sources,height_source.bind(terrain_node))
	# Collect the finished job even if the view is never opened.
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null or _prewarm_poll.is_valid() or not model.busy():return
	_prewarm_poll=func()->void:
		if not model.busy() or model.poll():
			tree.process_frame.disconnect(_prewarm_poll)
			_prewarm_poll=Callable()
			if open_views==0:_upload_ahead(model)
	tree.process_frame.connect(_prewarm_poll)


static var _prewarm_poll:Callable=Callable()
## Views open now: the background prewarm leaves textures to an open view.
static var open_views:=0


## Puts the prewarmed chart on the graphics card and draws it once on an
## invisible pixel, so the first opening does not stall on the upload.
static func _upload_ahead(model:RefCounted)->void:
	if model.image==null or model.routes==null or int(model.texture_revision)==int(model.revision):return
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null:return
	model.textures=[ImageTexture.create_from_image(model.image)]
	model.route_textures=[ImageTexture.create_from_image(model.routes)]
	model.texture_front=0
	model.texture_revision=model.revision
	var layer:=CanvasLayer.new()
	layer.name="WorldViewUploadAhead"
	layer.layer=-100
	var pixel:=ColorRect.new()
	pixel.size=Vector2.ONE
	pixel.modulate.a=0.01
	pixel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var ahead:=ShaderMaterial.new()
	ahead.shader=SHADER
	ahead.set_shader_parameter("known_map",model.textures[0])
	ahead.set_shader_parameter("previous_map",model.textures[0])
	ahead.set_shader_parameter("route_map",model.route_textures[0])
	ahead.set_shader_parameter("previous_route_map",model.route_textures[0])
	pixel.material=ahead
	layer.add_child(pixel)
	tree.root.add_child(layer)
	tree.create_timer(0.5).timeout.connect(layer.queue_free)


## The figures for this world, or none while its chart is still being drawn.
func current_stats()->Dictionary:
	return chart.stats if chart!=null and chart.current(int(GameState.world_seed)) else Chart.empty_stats()


## Where each observed town's report came from, so the ground it revealed is
## credited to scouts, armies or envoys.
static func city_sources()->Dictionary:
	var sources:={}
	var book:Dictionary=CivilizationSystem.city_intelligence.records.get("player",{}) if CivilizationSystem.city_intelligence!=null else {}
	for id:String in book:
		var record:Dictionary=book[id]
		var at:Dictionary=record.get("position",{})
		sources["%d|%d" % [roundi(float(at.get("x",0.0))),roundi(float(at.get("z",0.0)))]]=String(record.get("source",""))
	return sources


## The map's own planet raster when it is ready (the globe then matches the
## map's coasts), else the planet's exact heights.
static func height_source(terrain_node:Node)->Dictionary:
	if is_instance_valid(terrain_node):
		var render:Variant=terrain_node.get("macro_render")
		if render is RefCounted:
			var levels:Variant=(render as RefCounted).get("levels")
			if levels is Array and not (levels as Array).is_empty() and (levels as Array)[0] is RefCounted:
				var raster:RefCounted=(levels as Array)[0]
				if int(raster.get("seed_value"))==int(GameState.world_seed):
					return {"heights":raster.get("heights"),"colors":raster.get("colors"),"origin":raster.get("origin"),"cell":raster.get("cell"),"columns":raster.get("columns"),"rows":raster.get("rows")}
	if PlanetEnvironment!=null:
		PlanetEnvironment.prepare_macro_sampling()
		return {"exact":Callable(PlanetEnvironment,"_world_height_unchecked")}
	return {}


func _apply_chart()->void:
	if not chart.current(int(GameState.world_seed)):return
	if chart.revision==shown_revision:return
	# The chart keeps its textures between openings: reopening uploads nothing
	# unless the known world changed. A new chart goes into the texture not on
	# show, so the one on show can stay as the ground the new one inks over.
	var held:Array=chart.textures
	var held_routes:Array=chart.route_textures
	if int(chart.texture_revision)!=int(chart.revision):
		if held.is_empty() or held_routes.size()!=held.size():
			held=[ImageTexture.create_from_image(chart.image)]
			held_routes=[ImageTexture.create_from_image(chart.routes)]
			chart.texture_front=0
		else:
			var back:=1-int(chart.texture_front)
			if held.size()<2:
				held.append(ImageTexture.create_from_image(chart.image))
				held_routes.append(ImageTexture.create_from_image(chart.routes))
			else:
				(held[back] as ImageTexture).update(chart.image)
				(held_routes[back] as ImageTexture).update(chart.routes)
			chart.texture_front=back
		chart.textures=held
		chart.route_textures=held_routes
		chart.texture_revision=chart.revision
	var front_index:=int(chart.texture_front)
	var behind_index:=1-front_index if held.size()>1 else front_index
	var front:ImageTexture=held[front_index]
	var behind:ImageTexture=held[behind_index]
	globe_material.set_shader_parameter("known_map",front)
	globe_material.set_shader_parameter("route_map",held_routes[front_index])
	globe_material.set_shader_parameter("previous_route_map",held_routes[behind_index] if shown_revision>=0 else held_routes[front_index])
	if shown_revision<0:
		# First sight in this opening: the known world inks in over blank vellum.
		globe_material.set_shader_parameter("previous_map",front)
		chart_alpha=0.0
		map_mix=1.0
		var ink_in:=create_tween()
		ink_in.tween_method(func(value:float)->void:chart_alpha=value,0.0,1.0,T.MOTION.scene).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		# Newly known ground inks in over what was already known.
		globe_material.set_shader_parameter("previous_map",behind)
		map_mix=0.0
		var ink_in:=create_tween()
		ink_in.tween_method(func(value:float)->void:map_mix=value,0.0,1.0,T.MOTION.scene).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	shown_revision=chart.revision
	_update_card()


# --- Input ------------------------------------------------------------------------

func _gui_input(event:InputEvent)->void:
	if phase in ["closing","leaving"]:
		accept_event()
		return
	if event is InputEventMouseButton:
		var button:=event as InputEventMouseButton
		if button.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
			if button.pressed:
				dragging=true
				drag_travel=0.0
				drag_stamp=Time.get_ticks_usec()
				drag_velocity=Vector2.ZERO
				spin=Vector2.ZERO
			else:
				var was_click:=dragging and drag_travel<5.0 and button.button_index==MOUSE_BUTTON_LEFT
				dragging=false
				if was_click:_click(button.position)
				elif drag_velocity.length()>0.02 and Time.get_ticks_usec()-drag_stamp<80000:spin=drag_velocity
			idle=0.0
		elif button.pressed and button.button_index==MOUSE_BUTTON_WHEEL_UP:
			_zoom(button.position,-maxf(0.2,button.factor if button.factor>0.0 else 1.0))
		elif button.pressed and button.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(button.position,maxf(0.2,button.factor if button.factor>0.0 else 1.0))
		accept_event()
	elif event is InputEventMouseMotion:
		var moved:=event as InputEventMouseMotion
		pointer=moved.position
		if dragging:
			drag_travel+=moved.relative.length()
			var per_pixel:=_radians_per_pixel()
			var dlat:=moved.relative.y*per_pixel
			var dlon:=-moved.relative.x*per_pixel/maxf(0.2,cos(center_lat))
			_turn(dlat,dlon)
			# A throw keeps the speed of the last moments of the drag.
			var now:=Time.get_ticks_usec()
			var seconds:=clampf(float(now-drag_stamp)/1000000.0,1.0/240.0,0.1)
			drag_stamp=now
			drag_velocity=drag_velocity.lerp(Vector2(dlat,dlon)/seconds,0.5)
		idle=0.0
		accept_event()
	elif event is InputEventMagnifyGesture:
		var pinch:=event as InputEventMagnifyGesture
		if absf(pinch.factor-1.0)>0.02:_zoom(pinch.position,-(pinch.factor-1.0)*3.0)
		accept_event()
	elif event is InputEventPanGesture:
		var pan:=event as InputEventPanGesture
		var per_pixel:=_radians_per_pixel()*6.0
		_turn(-pan.delta.y*per_pixel,pan.delta.x*per_pixel/maxf(0.2,cos(center_lat)))
		idle=0.0
		accept_event()


func _input(event:InputEvent)->void:
	if not (event is InputEventKey) or not event.is_pressed():return
	var key:=event as InputEventKey
	# A screen opened above the world view (the court, a report) keeps its keys.
	if _covered():return
	if key.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
		return
	# A rail shortcut (F1-F12) goes on to its screen; the world view makes way.
	if key.keycode>=KEY_F1 and key.keycode<=KEY_F12:
		close()
		return
	var handled:=true
	match key.keycode:
		KEY_LEFT:_turn(0.0,-0.12)
		KEY_RIGHT:_turn(0.0,0.12)
		KEY_UP,KEY_PLUS,KEY_EQUAL,KEY_KP_ADD:
			if not key.echo:_zoom(globe_center(),-1.0)
		KEY_DOWN,KEY_MINUS,KEY_KP_SUBTRACT:
			if not key.echo:_zoom(globe_center(),1.0)
		KEY_W:_turn(0.12,0.0)
		KEY_S:_turn(-0.12,0.0)
		KEY_A:_turn(0.0,-0.12)
		KEY_D:_turn(0.0,0.12)
		_:handled=false
	if handled:
		idle=0.0
		get_viewport().set_input_as_handled()


## True while another screen shows above this one (a higher canvas layer with
## something visible on it).
func _covered()->bool:
	var tree:=get_tree()
	if tree==null:return false
	# Once per frame at most: held keys repeat.
	if covered_frame==Engine.get_process_frames():return covered_now
	covered_frame=Engine.get_process_frames()
	covered_now=false
	for node:Node in tree.root.find_children("*","CanvasLayer",true,false):
		var layer:=node as CanvasLayer
		if layer.layer<=LAYER or not layer.visible or layer.is_ancestor_of(self):continue
		for child:Node in layer.get_children():
			if child is Control and (child as Control).is_visible_in_tree() and (child as Control).size.x*(child as Control).size.y>1.0:
				covered_now=true
				return true
	return false


## How far the ground at the centre turns per screen pixel, so a drag keeps
## the ground under the pointer.
func _radians_per_pixel()->float:
	return (maxf(1.05,distance)-1.0)*tan_half_fov/maxf(1.0,view_size().y*0.5)


## Wheel and keys: closer toward the pointer, and past the closest view the
## map takes over where the pointer is.
func _zoom(at:Vector2,steps:float)->void:
	if phase!="open":return
	idle=0.0
	var goal:=zoom_goal(distance_goal,steps,rest_distance)
	if bool(goal.leave):
		# Past the closest view the map takes over where the pointer is.
		var target:=map_point_at(at)
		leave_to(target if target!=Vector2.INF else Chart.map_position(center_lat,center_lon),3)
		return
	if steps<0.0:
		var aimed:=_globe_point(at)
		if aimed!=Vector3.ZERO:
			# Close in on what is under the pointer.
			var here:=Chart.globe_vector(center_lat,center_lon)
			var toward:=here.slerp(aimed,clampf(1.0-pow(WHEEL_STEP,-steps),0.0,1.0)*0.85)
			var lat_lon:=Chart.vector_lat_lon(toward)
			center_lat=clampf(lat_lon.x,-MAX_LATITUDE,MAX_LATITUDE)
			center_lon=lat_lon.y
	distance_goal=float(goal.distance)


## Where a wheel step takes the eye: {distance, leave}. One step at the
## closest view hands over to the map instead.
static func zoom_goal(current_goal:float,steps:float,rest:float)->Dictionary:
	if steps<0.0:
		var closer:=1.0+(current_goal-1.0)*pow(WHEEL_STEP,-steps)
		if closer<NEAR_DISTANCE-0.001:
			if current_goal<=NEAR_DISTANCE+0.02:return {"distance":current_goal,"leave":true}
			closer=NEAR_DISTANCE
		return {"distance":closer,"leave":false}
	return {"distance":minf(rest*1.12,1.0+(current_goal-1.0)*pow(WHEEL_STEP,-steps)),"leave":false}


func _globe_point(screen:Vector2)->Vector3:
	return Chart.screen_to_globe(screen,globe_center(),view_size().y*0.5,distance,tan_half_fov,basis())


## The map position (km) under a screen point, or Vector2.INF off the globe.
func map_point_at(screen:Vector2)->Vector2:
	return Chart.map_point_at(screen,globe_center(),view_size().y*0.5,distance,tan_half_fov,basis())


func _click(at:Vector2)->void:
	var mark:Dictionary=(marks as MarksLayer).mark_at(at)
	if not mark.is_empty():
		leave_to(mark.position,TOWN_LEVEL)
		return
	var position:=map_point_at(at)
	if position==Vector2.INF:return
	if known_at(position):leave_to(position,GROUND_LEVEL)
	else:
		hint_label.text="No one of ours has been there yet."
		hint_hold=2.6
		hint_panel.reset_size()
		_layout()


static func known_at(position:Vector2)->bool:
	return CivilizationSystem!=null and CivilizationSystem._position_is_revealed(position)


func _get_tooltip(at:Vector2)->String:
	var mark:Dictionary=(marks as MarksLayer).mark_at(at)
	if not mark.is_empty():return String(mark.tip)
	var position:=map_point_at(at)
	if position==Vector2.INF:return ""
	if known_at(position):return "Known to our people. Click to go there."
	return "Unknown to our people."


# --- Words and the card ----------------------------------------------------------

static func category_words(id:String)->String:
	var early:=EraWords.hearth()
	match id:
		"travel":return "Our own travels"
		"scouts":return "Walkers" if early else "Scouts"
		"envoys":return "Envoys"
		"trade":return "Traders"
		"war":return "War bands" if early else "Armies"
	return "Other tellings"


static func category_color(id:String)->Color:
	match id:
		"travel":return T.GREEN
		"scouts":return T.TEAL
		"envoys":return T.VIOLET
		"trade":return T.AMBER
		"war":return T.RED
	return T.MUTED


## "We know about 0.40% of the world."
static func headline_words(stats:Dictionary)->String:
	var fraction:=float(stats.get("known_fraction",0.0))
	if fraction<=0.0:return "Our people know only the ground under their feet."
	return "We know about %s of the world." % Chart.percent_text(fraction)


## "Up from 0.10% ten winters ago", from the records' own days; "" when there
## is no earlier history to compare.
static func growth_words(chart_model:RefCounted,today:int,early:bool)->String:
	var stats:Dictionary=chart_model.stats
	var now:=float(stats.get("known_fraction",0.0))
	if now<=0.0:return ""
	var unit:="winters" if early else "years"
	if today>=10*Chart.YEAR_DAYS:
		var then:float=chart_model.known_fraction_at(today-10*Chart.YEAR_DAYS)
		if then<=0.0:return "Ten %s ago our people knew none of it." % unit
		if absf(now-then)<now*0.001:return "No more than ten %s ago." % unit
		return "Up from %s ten %s ago." % [Chart.percent_text(then),unit]
	var days:PackedInt32Array=stats.get("days",PackedInt32Array())
	if days.is_empty() or today<Chart.YEAR_DAYS:return ""
	var first:=days[0]
	for day in days:first=mini(first,day)
	var founding:float=chart_model.known_fraction_at(first)
	if founding<=0.0 or absf(now-founding)<now*0.001:return ""
	return "Up from %s when we first settled." % Chart.percent_text(founding)


## Shares of what is known, largest first: [[id, share 0..1], ...].
static func learned_shares(stats:Dictionary)->Array:
	var by:Dictionary=stats.get("by_category",{})
	var total:=0.0
	for id:String in by:total+=float(by[id])
	var rows:Array=[]
	if total<=0.0:return rows
	for id:String in Chart.CATEGORIES:
		var share:=float(by.get(id,0.0))/total
		if share>0.0005:rows.append([id,share])
	rows.sort_custom(func(a:Array,b:Array)->bool:return float(a[1])>float(b[1]))
	return rows


static func share_words(share:float)->String:
	if share<0.01:return "under 1%"
	return "%d%%" % roundi(share*100.0)


func _build_card()->void:
	card=PanelContainer.new()
	card.name="KnownCard"
	card.mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=P.sheet_style(22)
	card.add_theme_stylebox_override("panel",style)
	add_child(card)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",10)
	card.add_child(stack)
	P.kicker(stack,"Known to our people")
	var title:=P.label(stack,"The world","title",T.INK,false)
	title.name="Title"
	P.rule(stack)
	headline=P.label(stack,"","voice",T.INK)
	headline.name="Headline"
	growth=P.label(stack,"","voice_small",T.INK_MUTED)
	growth.name="Growth"
	growth.add_theme_font_override("font",T.font("voice_italic"))
	var split:=HBoxContainer.new()
	split.add_theme_constant_override("separation",28)
	stack.add_child(split)
	land_value=_stat(split,"Land","LandKnown")
	sea_value=_stat(split,"Sea","SeaKnown")
	P.kicker(stack,"How we learned it")
	learned_bar=LearnedBar.new()
	learned_bar.name="LearnedBar"
	learned_bar.custom_minimum_size=Vector2(0,10)
	stack.add_child(learned_bar)
	learned_rows=VBoxContainer.new()
	learned_rows.name="LearnedRows"
	learned_rows.add_theme_constant_override("separation",4)
	stack.add_child(learned_rows)
	P.kicker(stack,"On the world")
	var legend:=VBoxContainer.new()
	legend.name="Legend"
	legend.add_theme_constant_override("separation",4)
	stack.add_child(legend)
	_legend_row(legend,Identity.emblem("player"),"Our towns and the land around them")
	_legend_row(legend,null,"Other peoples' towns, as last seen")
	_legend_row(legend,null,"Blank vellum: no one of ours has been there",true)
	_update_card()


func _stat(parent:Node,caption:String,node_name:String)->Label:
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",0)
	parent.add_child(column)
	P.kicker(column,caption)
	var value:=P.label(column,"","value",T.INK,false)
	value.name=node_name
	P.label(column,"of the world","small",T.INK_MUTED,false)
	return value


func _legend_row(parent:Node,icon:Texture2D,words:String,vellum:=false)->void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	parent.add_child(row)
	var swatch:=LegendMark.new()
	swatch.icon=icon
	swatch.vellum=vellum
	swatch.custom_minimum_size=Vector2(22,22)
	swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)
	var label:=P.label(row,words,"small",T.BODY)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL


func _update_card()->void:
	if headline==null:return
	var stats:=current_stats()
	var drawn:bool=chart!=null and bool(chart.current(int(GameState.world_seed)))
	headline.text=headline_words(stats) if drawn else "Gathering what our people know."
	var today:=today_override if today_override>=0 else int(floor(GameState.elapsed_days))
	growth.text=growth_words(chart,today,EraWords.hearth()) if drawn else ""
	growth.visible=growth.text!=""
	land_value.text=Chart.percent_text(float(stats.get("land_fraction",0.0)))
	sea_value.text=Chart.percent_text(float(stats.get("sea_fraction",0.0)))
	var shares:=learned_shares(stats)
	(learned_bar as LearnedBar).shares=shares
	learned_bar.queue_redraw()
	for child in learned_rows.get_children():child.queue_free()
	for entry:Array in shares:
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",8)
		learned_rows.add_child(row)
		var dot:=ColorRect.new()
		dot.color=category_color(String(entry[0]))
		dot.custom_minimum_size=Vector2(10,10)
		dot.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var words:=P.label(row,category_words(String(entry[0])),"small",T.BODY,false)
		words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		P.label(row,share_words(float(entry[1])),"small",T.INK,false)
	if shares.is_empty():P.label(learned_rows,"Only what the people saw where they first camped.","small",T.INK_MUTED)
	_layout()


func _build_controls()->void:
	close_button=P.button(self,"Back to the map",close)
	close_button.name="BackToMap"
	close_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	close_button.autowrap_mode=TextServer.AUTOWRAP_OFF
	close_button.custom_minimum_size=Vector2(170,40)
	close_button.tooltip_text="Return to the map where you were (Esc)."
	hint_panel=PanelContainer.new()
	hint_panel.name="Hint"
	hint_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=T.paper_panel_style(true,T.RADIUS_CARD,0.0)
	style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=7;style.content_margin_bottom=7
	hint_panel.add_theme_stylebox_override("panel",style)
	add_child(hint_panel)
	hint_label=P.label(hint_panel,_hint_words(),"small",T.BODY,false)
	hint_label.name="HintText"
	hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER


static func _hint_words()->String:
	return "Drag to turn the world · Scroll to look closer · Click known ground to go there"


func _apply_palette()->void:
	var dark:=not T.is_light()
	globe_material.set_shader_parameter("backdrop_center",Color("2c231a") if dark else Color("4a3b2b"))
	globe_material.set_shader_parameter("backdrop_edge",Color("0d0a07") if dark else Color("211912"))
	globe_material.set_shader_parameter("paper",Color(0.925,0.886,0.792) if not dark else Color(0.86,0.81,0.71))


# --- Marks ------------------------------------------------------------------------

## Our towns, towns we hold and other peoples' towns as last seen, as globe
## vectors, rebuilt when any of them changes.
func _gather_marks()->void:
	var settlements:Array=GameState.player_settlements
	var book:Dictionary=CivilizationSystem.city_intelligence.records.get("player",{}) if CivilizationSystem!=null and CivilizationSystem.city_intelligence!=null else {}
	var realm_key:="%d|%d|%d" % [int(GameState.world_seed),int(GameState.settlement_network_revision),settlements.size()]
	# Emblems drawn elsewhere meanwhile (the map's own town names) count too.
	var signature:="%s|%d|%d|%d" % [realm_key,book.size(),int(CivilizationSystem.observation_revision) if CivilizationSystem!=null else 0,Identity.cache.size()]
	if signature==marks_signature:return
	marks_signature=signature
	var list:Array[Dictionary]=[]
	var ours:=Identity.emblem("player")
	var home_name:=String(GameState.settlement_name)
	for settlement:Dictionary in settlements:
		var at:Variant=settlement.get("position",Vector2.ZERO)
		if not at is Vector2:continue
		var primary:=bool(settlement.get("primary",false))
		var name_text:=CityLabels.chart_name(String(settlement.get("name",home_name)))
		list.append({"id":String(settlement.get("id","")),"kind":"ours","rank":0 if primary else 1,"position":at,"vector":_vector(at),"emblem":ours,
			"name":name_text if primary else "","tip":"%s · our %s" % [name_text,EraWords.word("place","town")],"people":"player"})
	# Before any town is founded our people are wherever they have walked to.
	if list.is_empty() and CivilizationSystem!=null:
		var here:=CivilizationSystem.player_world_origin
		list.append({"id":"our_people","kind":"ours","rank":0,"position":here,"vector":_vector(here),"emblem":ours,
			"name":"Our people","tip":"Our people, still looking for a place to settle","people":"player"})
	# Town reaches change only with the settlement network: skip the snapshot otherwise.
	if realm_key!=realm_signature:
		realm_signature=realm_key
		var realm:Array=[]
		if SettlementModel!=null and not settlements.is_empty():
			for record:Dictionary in SettlementModel.settlement_network_snapshot().settlements:
				var boundary:PackedVector2Array=record.get("boundary",PackedVector2Array())
				if boundary.size()>=3:
					var vectors:=PackedVector3Array()
					for point in boundary:vectors.append(_vector(point))
					realm.append(vectors)
		(marks as MarksLayer).realm=realm
	if CivilizationSystem!=null and CivilizationSystem.city_intelligence!=null:
		var named:={}
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false):
			var location:Dictionary=city.get("position",{})
			var at:=Vector2(float(location.get("x",0.0)),float(location.get("z",0.0)))
			var status:=_town_status(city)
			var kind:=String(status.get("kind","foreign"))
			var holder:=String(status.get("emblem",""))
			var people:=String(city.get("civ_id",""))
			var rank:=2 if kind=="occupied" else (3 if kind=="rival_capital" else (4 if kind=="besieged" else (6 if kind=="ruined" else 5)))
			var label:=""
			if kind!="occupied" and people!="" and not named.has(people):
				label=Ownership.people(people)
				named[people]=true
			var when:=EraWords.when(int(city.get("observed_day",-1)))
			var town_name:=CityLabels.chart_name(String(city.get("name","A town")))
			var tip:="%s · %s" % [town_name,String(status.get("line",""))] if kind=="occupied" else "%s · %s, as last seen in %s" % [town_name,P.first_up(Ownership.people(people)) if people!="" else "Strangers",when]
			if kind=="ruined":tip+=". Burned or broken then."
			list.append({"id":String(city.get("city_id","")),"kind":kind,"rank":rank,"position":at,"vector":_vector(at),
				"emblem":_emblem_now(holder),"emblem_id":holder,"name":label,"tip":tip,"people":people,"stale":int(city.get("observed_day",-1))<int(GameState.elapsed_days)-3*Chart.YEAR_DAYS})
	list.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.rank)<int(b.rank))
	(marks as MarksLayer).entries=list


## Who holds a known town and how it is marked (map_ownership.gd). Reading a
## people's colour draws their emblem the first time, which takes a moment;
## until the emblems involved are drawn (one at a time, while the view rests)
## the town is marked plainly as ours or as a stranger's.
func _town_status(city:Dictionary)->Dictionary:
	var holder:=String(city.get("controller",""))
	var original:=String(city.get("civ_id",""))
	if holder=="":holder=original
	var waiting:=false
	for civ_id:String in [holder,original]:
		if civ_id=="" or civ_id=="player":continue
		if not (Identity.cache_seed==int(WorldSimulation.state.world_seed) and Identity.cache.has(civ_id)):
			waiting=true
			if not pending_emblems.has(civ_id):pending_emblems.append(civ_id)
	if not waiting:return Ownership.status(city)
	var held:=not Ownership.player_hold(String(city.get("city_id",""))).is_empty() or holder=="player"
	return {"kind":"occupied" if held else "foreign","emblem":"player" if held else "","line":"Ours · taken from "+Ownership.people(original) if held else ""}


## A people's emblem if it is already drawn; otherwise it is queued and the
## mark waits a frame or two (drawing one takes a noticeable moment).
func _emblem_now(civ_id:String)->Texture2D:
	if civ_id=="":return null
	if civ_id=="player" or (Identity.cache_seed==int(WorldSimulation.state.world_seed) and Identity.cache.has(civ_id)):return Identity.emblem(civ_id)
	if not pending_emblems.has(civ_id):pending_emblems.append(civ_id)
	return null


func _draw_one_emblem()->void:
	var civ_id:=pending_emblems[0]
	pending_emblems.remove_at(0)
	var texture:=Identity.emblem(civ_id)
	for entry:Dictionary in (marks as MarksLayer).entries:
		if String(entry.get("emblem_id",""))==civ_id:entry["emblem"]=texture


static func _vector(position:Vector2)->Vector3:
	var lat_lon:=Chart.lat_lon(position)
	return Chart.globe_vector(lat_lon.x,lat_lon.y)


## Screen position and whether it faces the eye, for a globe vector.
func project(v:Vector3)->Vector3:
	return Chart.globe_to_screen(v,globe_center(),view_size().y*0.5,distance,tan_half_fov,basis())


class MarksLayer extends Control:
	## Emblems and names drawn over the globe: ours first, then towns we hold,
	## chief towns, and other towns. A mark that would sit on another is left
	## as a small ink dot; names only where they have room.
	## The globe is always parchment, whatever the interface palette: its marks
	## use the chart's own inks, not the night or day text colours.
	const PARCHMENT:=Color("f6efe1")
	const INK:=Color("20231f")
	const GOLD_INK:=Color("8a6118")
	var view:Control
	var entries:Array[Dictionary]=[]
	var realm:Array=[]
	var placed:Array[Dictionary]=[]

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func mark_at(at:Vector2)->Dictionary:
		var best:Dictionary={}
		var best_distance:=INF
		for mark:Dictionary in placed:
			var gap:=(mark.screen as Vector2).distance_to(at)
			if gap<=float(mark.size)*0.6+4.0 and gap<best_distance:
				best=mark.entry
				best_distance=gap
		return best

	func _draw()->void:
		placed.clear()
		if view==null:return
		var fade:float=view.opacity
		if fade<=0.01:return
		var radius:float=view.globe_radius()
		var scale:=clampf(radius/420.0,0.8,1.35)
		var gold:=GOLD_INK
		# Our land: a gold wash inside each town's reach.
		for polygon:PackedVector3Array in realm:
			var points:=PackedVector2Array()
			var facing:=true
			for v in polygon:
				var s:Vector3=view.project(v)
				if s.z<=0.0:facing=false;break
				points.append(Vector2(s.x,s.y))
			if not facing or points.size()<3:continue
			var box:=Rect2(points[0],Vector2.ZERO)
			for p in points:box=box.expand(p)
			if box.size.x<2.5 and box.size.y<2.5:
				draw_circle(box.get_center(),2.2,Color(gold,0.55*fade))
				continue
			if Geometry2D.triangulate_polygon(points).is_empty():continue
			draw_colored_polygon(points,Color(gold,0.30*fade))
			points.append(points[0])
			draw_polyline(points,Color(gold,0.85*fade),1.2,true)
		# Emblems stand on short leaders above their towns, in rank order, where
		# they fit; a town left without one is a small ink dot. The ground at
		# the town itself stays uncovered.
		var ink:=Color(0.14,0.10,0.07)
		var labels:Array[Rect2]=[]
		var dots:=PackedVector2Array()
		for entry:Dictionary in entries:
			var s:Vector3=view.project(entry.vector)
			if s.z<=0.0:continue
			var at:=Vector2(s.x,s.y)
			var mark_size:=(30.0 if int(entry.rank)==0 else (24.0 if String(entry.kind) in ["ours","occupied"] else 21.0))*scale
			var centre:=at+Vector2(0,-mark_size*0.85)
			var clear:=true
			for mark:Dictionary in placed:
				if (mark.screen as Vector2).distance_to(centre)<(float(mark.size)+mark_size)*0.5:clear=false;break
			if not clear:
				dots.append(at)
				continue
			placed.append({"screen":centre,"size":mark_size,"entry":entry,"at":at})
		for at in dots:
			draw_circle(at,2.4,Color(PARCHMENT,0.85*fade))
			draw_circle(at,1.5,Color(ink,fade))
		for mark:Dictionary in placed:
			var entry:Dictionary=mark.entry
			var at:Vector2=mark.at
			var centre:Vector2=mark.screen
			var mark_size:=float(mark.size)
			var box:=Rect2(centre-Vector2(mark_size,mark_size)*0.5,Vector2(mark_size,mark_size))
			draw_line(at,centre+Vector2(0,mark_size*0.42),Color(PARCHMENT,0.7*fade),3.0,true)
			draw_line(at,centre+Vector2(0,mark_size*0.42),Color(ink,0.85*fade),1.1,true)
			draw_circle(at,1.6,Color(ink,fade))
			var emblem:Texture2D=entry.get("emblem")
			if emblem!=null:
				var alpha:=0.72 if bool(entry.get("stale",false)) else 1.0
				draw_texture_rect(emblem,box,false,Color(1,1,1,alpha*fade))
			else:
				draw_circle(centre,mark_size*0.32,Color(PARCHMENT,fade))
				draw_arc(centre,mark_size*0.32,0.0,TAU,24,Color(ink,fade),1.2,true)
			if String(entry.kind)=="occupied":
				draw_arc(centre,mark_size*0.62,0.0,TAU,32,Color(gold,0.9*fade),1.6,true)
			var hover:Vector2=view.pointer
			if hover.distance_to(centre)<=mark_size*0.6:
				draw_arc(centre,mark_size*0.66,0.0,TAU,32,Color(GOLD_INK,fade),1.8,true)
			labels.append(box)
		for mark:Dictionary in placed:
			var words:=String((mark.entry as Dictionary).get("name",""))
			if words!="":
				var mark_size:=float(mark.size)
				_label(words,Rect2((mark.screen as Vector2)-Vector2(mark_size,mark_size)*0.5,Vector2(mark_size,mark_size)),labels,fade,int((mark.entry as Dictionary).rank)==0)

	func _label(words:String,box:Rect2,labels:Array[Rect2],fade:float,ours:bool)->void:
		var font:=T.voice_font()
		var font_size:=17 if ours else 15
		var width:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		for offset:Vector2 in [Vector2(box.size.x*0.5+6,6),Vector2(-box.size.x*0.5-6-width,6),Vector2(-width*0.5,-box.size.y*0.5-8),Vector2(-width*0.5,box.size.y*0.5+font_size+4)]:
			var origin:=box.get_center()+offset
			var rect:=Rect2(origin-Vector2(2,font_size),Vector2(width+4,font_size+6))
			var clash:=false
			for other:Rect2 in labels:
				if other.intersects(rect):clash=true;break
			if clash or not get_rect().grow(-8).encloses(rect):continue
			labels.append(rect)
			var halo:=Color(PARCHMENT,0.92*fade)
			draw_string_outline(font,origin,words,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,8,halo)
			draw_string(font,origin,words,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(INK,fade))
			return


class LearnedBar extends Control:
	## One inked bar split by how each part of the known world was learned.
	var shares:Array=[]

	func _draw()->void:
		var width:=size.x
		draw_rect(Rect2(Vector2.ZERO,size),Color(T.TRACK,0.6))
		var x:=0.0
		for entry:Array in shares:
			var w:=float(entry[1])*width
			draw_rect(Rect2(Vector2(x,0),Vector2(maxf(1.0,w),size.y)),WorldGlobe.category_color(String(entry[0])))
			x+=w
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE_STRONG,false,1.0)


class LegendMark extends Control:
	var icon:Texture2D
	var vellum:=false

	func _draw()->void:
		var box:=Rect2(Vector2(1,1),size-Vector2(2,2))
		if vellum:
			draw_rect(box,Color(0.925,0.886,0.792))
			draw_rect(box,T.RULE_STRONG,false,1.0)
			return
		if icon!=null:
			draw_texture_rect(icon,box,false)
			return
		# Another people's mark: a small inked lozenge in a stone wash.
		var centre:=size*0.5
		var r:=size.x*0.42
		var lozenge:=PackedVector2Array([centre+Vector2(0,-r),centre+Vector2(r*0.8,0),centre+Vector2(0,r),centre+Vector2(-r*0.8,0)])
		draw_colored_polygon(lozenge,Color("7c8588"))
		lozenge.append(lozenge[0])
		draw_polyline(lozenge,T.INK,1.2,true)
		draw_circle(centre,r*0.28,Color("e7e4d4"))
