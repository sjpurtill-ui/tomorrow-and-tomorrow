extends Node2D

const MAP_SIZE := Vector2i(1920, 1080)
const PROVINCE_COUNT := 320
const COUNTRY_COUNT := 1
const SAMPLE_STEP := 4
const TERRAIN_STEP := 2

var province_map: Image
var province_texture: ImageTexture
var terrain_texture: ImageTexture
var seeds: Array[Vector2] = []
var province_owner: Array[int] = []
var province_names: Array[String] = []
var province_neighbors: Array[Array] = []
var province_terrain: Array[String] = []
var province_population: Array[int] = []
var province_resource: Array[String] = []
var province_resource_amount: Array[int] = []
var province_elevation: Array[float] = []
var province_is_water: Array[bool] = []
var armies: Array[Dictionary] = []
var selected_province := -1
var hovered_province := -1
var selected_army := -1
var camera_pos := Vector2(MAP_SIZE) * 0.5
var zoom := 0.75
var dragging := false
var drag_origin := Vector2.ZERO
var camera_origin := Vector2.ZERO
var game_day := 1
var game_speed := 1
var day_progress := 0.0
var treasury: Array[float] = []
var income: Array[float] = []
var world_seed := 0
var continent_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var map_level := "world"
var active_province := -1
var local_texture: ImageTexture
var local_sites: Array[Dictionary] = []

const TERRAIN_COLORS := {
	"Plains": Color("#d8c97a"), "Forest": Color("#739163"),
	"Hills": Color("#aa9269"), "Mountains": Color("#8c8980"),
	"Marsh": Color("#719384")
}

var country_names := ["Your People"]
var country_colors := [Color("#5b8fc4")]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	randomize()
	world_seed = GameState.world_seed if GameState.world_seed != 0 else randi()
	GameState.world_seed = world_seed
	seed(world_seed)
	_configure_world_noise()
	_generate_seeds()
	_assign_countries()
	_build_province_map()
	_build_adjacency()
	_generate_province_data()
	_build_terrain_texture()
	_create_starting_armies()
	_recalculate_economy()
	queue_redraw()

func _configure_world_noise() -> void:
	continent_noise.seed = world_seed
	continent_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	continent_noise.frequency = 0.0017
	continent_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	continent_noise.fractal_octaves = 3
	detail_noise.seed = world_seed ^ 0x5f3759df
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.006
	detail_noise.fractal_octaves = 2

func _generate_seeds() -> void:
	var margin := 25.0
	var attempts := 0
	while seeds.size() < PROVINCE_COUNT and attempts < 20000:
		attempts += 1
		var point := Vector2(randf_range(margin, MAP_SIZE.x - margin), randf_range(margin, MAP_SIZE.y - margin))
		var min_distance := 43.0 + randf_range(-7.0, 9.0)
		var valid := true
		for existing in seeds:
			if point.distance_to(existing) < min_distance:
				valid = false
				break
		if valid:
			seeds.append(point)
	while seeds.size() < PROVINCE_COUNT:
		seeds.append(Vector2(randf_range(margin, MAP_SIZE.x - margin), randf_range(margin, MAP_SIZE.y - margin)))
	for i in PROVINCE_COUNT:
		province_names.append(_make_province_name(i))

func _assign_countries() -> void:
	for i in PROVINCE_COUNT:
		province_owner.append(-1)

func _build_province_map() -> void:
	province_map = Image.create(MAP_SIZE.x / SAMPLE_STEP, MAP_SIZE.y / SAMPLE_STEP, false, Image.FORMAT_RGBA8)
	for y in province_map.get_height():
		for x in province_map.get_width():
			var world_point := Vector2(x * SAMPLE_STEP + SAMPLE_STEP * 0.5, y * SAMPLE_STEP + SAMPLE_STEP * 0.5)
			var nearest := _nearest_seed(world_point)
			province_map.set_pixel(x, y, _encoded_id(nearest))
	province_texture = ImageTexture.create_from_image(province_map)

func _build_adjacency() -> void:
	province_neighbors.clear()
	for i in PROVINCE_COUNT:
		province_neighbors.append([])
	for y in province_map.get_height() - 1:
		for x in province_map.get_width() - 1:
			var current := _map_id(x, y)
			var right := _map_id(x + 1, y)
			var down := _map_id(x, y + 1)
			_link_provinces(current, right)
			_link_provinces(current, down)

func _link_provinces(a: int, b: int) -> void:
	if a == b or a < 0 or b < 0:
		return
	if b not in province_neighbors[a]:
		province_neighbors[a].append(b)
	if a not in province_neighbors[b]:
		province_neighbors[b].append(a)

func _map_id(x: int, y: int) -> int:
	var encoded := province_map.get_pixel(x, y)
	return int(round(encoded.r * 255.0)) + int(round(encoded.g * 255.0)) * 256 - 1

func _generate_province_data() -> void:
	var terrains := ["Plains", "Plains", "Forest", "Forest", "Hills", "Mountains", "Marsh"]
	var resources := ["Grain", "Grain", "Timber", "Iron", "Coal", "None"]
	for i in PROVINCE_COUNT:
		var point := seeds[i]
		var latitude: float = abs(point.y / float(MAP_SIZE.y) - 0.5) * 2.0
		var broad: float = continent_noise.get_noise_2d(point.x, point.y)
		var detail: float = detail_noise.get_noise_2d(point.x, point.y)
		var elevation: float = _elevation_at(point)
		var water: bool = elevation < -0.045
		province_elevation.append(elevation)
		province_is_water.append(water)
		var terrain: String
		if water:
			terrain = "Ocean"
		elif elevation > 0.42:
			terrain = "Mountains"
		elif elevation > 0.25:
			terrain = "Hills"
		elif latitude < 0.68 and detail > 0.05:
			terrain = "Forest"
		elif detail < -0.28:
			terrain = "Marsh"
		else:
			terrain = terrains[randi() % 2]
		province_terrain.append(terrain)
		if water:
			province_population.append(0)
			province_resource.append("Fish")
			province_resource_amount.append(randi_range(1, 4))
			continue
		var base_population := randi_range(35, 180)
		if terrain == "Plains": base_population += 70
		if terrain == "Mountains" or terrain == "Marsh": base_population -= 20
		province_population.append(max(15, base_population) * 1000)
		province_resource.append(resources[randi() % resources.size()])
		province_resource_amount.append(randi_range(1, 5))

func _elevation_at(point: Vector2) -> float:
	var latitude: float = abs(point.y / float(MAP_SIZE.y) - 0.5) * 2.0
	var broad: float = continent_noise.get_noise_2d(point.x, point.y)
	var detail: float = detail_noise.get_noise_2d(point.x, point.y)
	var plates := sin(point.x * 0.0041 + sin(point.y * 0.0027)) * 0.10
	plates += cos(point.y * 0.0053 - point.x * 0.0011) * 0.07
	return broad * 0.73 + detail * 0.18 + plates - pow(latitude, 5.0) * 0.14

func _build_terrain_texture() -> void:
	var image := Image.create(MAP_SIZE.x / TERRAIN_STEP, MAP_SIZE.y / TERRAIN_STEP, false, Image.FORMAT_RGB8)
	for y in image.get_height():
		for x in image.get_width():
			var point := Vector2(x * TERRAIN_STEP, y * TERRAIN_STEP)
			var elevation := _elevation_at(point)
			var latitude: float = abs(point.y / float(MAP_SIZE.y) - 0.5) * 2.0
			var moisture: float = detail_noise.get_noise_2d(point.x + 8300.0, point.y - 4100.0)
			var color: Color
			if elevation < -0.045:
				var depth: float = clampf((-0.045 - elevation) * 2.8, 0.0, 1.0)
				color = Color("#6f9eaa").lerp(Color("#416f82"), depth)
			else:
				color = Color("#cbbb91")
				var vegetation: float = clampf((moisture - 0.02) * 0.28, 0.0, 0.12)
				color = color.lerp(Color("#788f68"), vegetation)
				var relief: float = clampf((elevation - 0.18) * 0.45, 0.0, 0.20)
				color = color.lerp(Color("#8e806b"), relief)
				if latitude > 0.84:
					color = color.lerp(Color("#e5e1d5"), clampf((latitude - 0.84) * 2.8, 0.0, 0.55))
				if elevation < -0.015:
					color = color.lerp(Color("#dfcf9e"), 0.45)
			var across_coast := (_elevation_at(point + Vector2(4, 0)) < -0.045) != (elevation < -0.045)
			across_coast = across_coast or ((_elevation_at(point + Vector2(0, 4)) < -0.045) != (elevation < -0.045))
			if across_coast:
				color = Color("#344b4d")
			else:
				var slope: float = clampf((_elevation_at(point + Vector2(3, 3)) - elevation) * 0.75, -0.035, 0.035)
				color = color.lightened(slope) if slope >= 0.0 else color.darkened(-slope)
			image.set_pixel(x, y, color)
	terrain_texture = ImageTexture.create_from_image(image)

func _create_starting_armies() -> void:
	var center := Vector2(MAP_SIZE) * 0.5
	var starting_province := -1
	var best_distance := INF
	for province in PROVINCE_COUNT:
		if not province_is_water[province]:
			var distance := seeds[province].distance_squared_to(center)
			if distance < best_distance:
				best_distance = distance
				starting_province = province
	if starting_province >= 0:
		armies.append({"owner": 0, "province": starting_province, "population": 120, "type": "Settler"})

func _recalculate_economy() -> void:
	treasury.resize(COUNTRY_COUNT)
	income.resize(COUNTRY_COUNT)
	for country in COUNTRY_COUNT:
		income[country] = 0.0
	for province in PROVINCE_COUNT:
		if province_owner[province] >= 0 and not province_is_water[province]:
			income[province_owner[province]] += province_population[province] / 100000.0 + province_resource_amount[province] * 0.15

func _nearest_seed(point: Vector2) -> int:
	var nearest := 0
	var best := INF
	var warped := point + Vector2(sin(point.y * 0.018) * 14.0, sin(point.x * 0.014) * 12.0)
	for i in seeds.size():
		var distance := warped.distance_squared_to(seeds[i])
		if distance < best:
			best = distance
			nearest = i
	return nearest

func _encoded_id(id: int) -> Color:
	var value := id + 1
	return Color(float(value % 256) / 255.0, float(value / 256) / 255.0, 0.0, 1.0)

func _province_at(screen_position: Vector2) -> int:
	var world := (screen_position - get_viewport_rect().size * 0.5) / zoom + camera_pos
	if world.x < 0 or world.y < 0 or world.x >= MAP_SIZE.x or world.y >= MAP_SIZE.y:
		return -1
	return _nearest_seed(world)

func _input(event: InputEvent) -> void:
	if map_level == "local":
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				dragging = event.pressed
				drag_origin = event.position
				camera_origin = camera_pos
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				zoom = min(zoom * 1.15, 2.4)
				queue_redraw()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				zoom = max(zoom / 1.15, 0.5)
				queue_redraw()
		elif event is InputEventMouseMotion and dragging:
			camera_pos = camera_origin - (event.position - drag_origin) / zoom
			_clamp_camera()
			queue_redraw()
		return
	if event is InputEventMouseMotion:
		hovered_province = _province_at(event.position)
		if dragging:
			camera_pos = camera_origin - (event.position - drag_origin) / zoom
			_clamp_camera()
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked := _province_at(event.position)
			if event.double_click and clicked >= 0 and not province_is_water[clicked]:
				_enter_province(clicked)
				return
			selected_province = clicked
			selected_army = _army_in_province(selected_province)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_try_move_selected_army(_province_at(event.position))
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			drag_origin = event.position
			camera_origin = camera_pos
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = min(zoom * 1.15, 2.4)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = max(zoom / 1.15, 0.45)
			queue_redraw()

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera_pos += direction * 650.0 * delta / zoom
		_clamp_camera()
		queue_redraw()
	if Input.is_key_pressed(KEY_SPACE):
		game_speed = 0
	day_progress += delta * game_speed * 1.5
	if day_progress >= 1.0:
		var elapsed_days := int(day_progress)
		day_progress -= elapsed_days
		game_day += elapsed_days
		for country in COUNTRY_COUNT:
			treasury[country] += income[country] * elapsed_days / 30.0
		queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE and map_level == "local":
		_leave_province()
		return
	if event.keycode >= KEY_0 and event.keycode <= KEY_4:
		game_speed = int(event.keycode - KEY_0)
		queue_redraw()

func _army_in_province(province: int) -> int:
	for i in armies.size():
		if armies[i].province == province:
			return i
	return -1

func _try_move_selected_army(destination: int) -> void:
	if selected_army < 0 or destination < 0:
		return
	var origin: int = armies[selected_army].province
	if destination in province_neighbors[origin] and not province_is_water[destination]:
		armies[selected_army].province = destination
		selected_province = destination
		queue_redraw()

func _clamp_camera() -> void:
	camera_pos.x = clamp(camera_pos.x, 0.0, MAP_SIZE.x)
	camera_pos.y = clamp(camera_pos.y, 0.0, MAP_SIZE.y)

func _enter_province(province: int) -> void:
	GameState.active_province = province
	GameState.province_name = province_names[province]
	GameState.province_terrain = province_terrain[province]
	_capture_province_shape(province)
	get_tree().change_scene_to_file("res://local_terrain.tscn")

func _capture_province_shape(province: int) -> void:
	var min_x := province_map.get_width()
	var min_y := province_map.get_height()
	var max_x := 0
	var max_y := 0
	for y in province_map.get_height():
		for x in province_map.get_width():
			if _map_id(x, y) == province:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	var width := max_x - min_x + 1
	var height := max_y - min_y + 1
	var mask := Image.create(width, height, false, Image.FORMAT_L8)
	for y in height:
		for x in width:
			mask.set_pixel(x, y, Color.WHITE if _map_id(min_x + x, min_y + y) == province else Color.BLACK)
	GameState.province_mask = mask
	GameState.province_aspect = float(width) / float(height)

func _leave_province() -> void:
	map_level = "world"
	active_province = -1
	camera_pos = Vector2(MAP_SIZE) * 0.5
	zoom = 0.75
	queue_redraw()

func _build_local_map(province: int) -> void:
	var local_seed: int = world_seed ^ ((province + 1) * 104729)
	var height_noise := FastNoiseLite.new()
	height_noise.seed = local_seed
	height_noise.frequency = 0.0035
	height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	height_noise.fractal_octaves = 4
	var ground_noise := FastNoiseLite.new()
	ground_noise.seed = local_seed ^ 0x45d9f3b
	ground_noise.frequency = 0.012
	var image := Image.create(MAP_SIZE.x / TERRAIN_STEP, MAP_SIZE.y / TERRAIN_STEP, false, Image.FORMAT_RGB8)
	var base_terrain: String = province_terrain[province]
	for y in image.get_height():
		for x in image.get_width():
			var point := Vector2(x * TERRAIN_STEP, y * TERRAIN_STEP)
			var height: float = height_noise.get_noise_2d(point.x, point.y)
			var ground: float = ground_noise.get_noise_2d(point.x, point.y)
			var color := Color("#a99d72")
			if base_terrain == "Forest": color = Color("#6f805e")
			elif base_terrain == "Hills": color = Color("#9d8d6d")
			elif base_terrain == "Mountains": color = Color("#817c70")
			elif base_terrain == "Marsh": color = Color("#718478")
			color = color.lightened(clampf(height * 0.10 + ground * 0.035, -0.08, 0.10)) if height >= 0.0 else color.darkened(clampf(-height * 0.08, 0.0, 0.08))
			# Narrow streams follow a warped vertical contour through the province.
			var river_x := MAP_SIZE.x * 0.52 + sin(point.y * 0.009 + local_seed) * 110.0 + height_noise.get_noise_2d(0.0, point.y) * 130.0
			if abs(point.x - river_x) < 7.0:
				color = Color("#668f99")
			image.set_pixel(x, y, color)
	local_texture = ImageTexture.create_from_image(image)
	local_sites.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = local_seed
	var site_types := ["Timber", "Stone", "Fertile", "Game"]
	for i in 28:
		local_sites.append({
			"position": Vector2(rng.randf_range(70, MAP_SIZE.x - 70), rng.randf_range(70, MAP_SIZE.y - 70)),
			"type": site_types[rng.randi_range(0, site_types.size() - 1)]
		})

func _draw() -> void:
	draw_rect(get_viewport_rect(), Color("#16232a"))
	var center := get_viewport_rect().size * 0.5
	draw_set_transform(center - camera_pos * zoom, 0.0, Vector2.ONE * zoom)
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE)), Color("#d9ccb0"))
	if map_level == "world":
		_draw_provinces()
		_draw_armies()
	else:
		_draw_local_map()
	draw_set_transform(Vector2.ZERO)
	_draw_ui()

func _draw_local_map() -> void:
	draw_texture_rect(local_texture, Rect2(Vector2.ZERO, Vector2(MAP_SIZE)), false)
	for site in local_sites:
		var position: Vector2 = site.position
		var color := Color("#536849")
		var symbol := "T"
		if site.type == "Stone":
			color = Color("#716e66")
			symbol = "◆"
		elif site.type == "Fertile":
			color = Color("#9b873f")
			symbol = "●"
		elif site.type == "Game":
			color = Color("#775844")
			symbol = "▲"
		draw_circle(position, 8.0, Color(0.12, 0.12, 0.10, 0.35))
		draw_circle(position, 6.0, color)
		draw_string(ThemeDB.fallback_font, position + Vector2(10, 5), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#eee5cc"))

func _draw_provinces() -> void:
	draw_texture_rect(terrain_texture, Rect2(Vector2.ZERO, Vector2(MAP_SIZE)), false)
	var cell := SAMPLE_STEP
	# Province borders sit over geography; coastlines come from the terrain raster.
	for y in province_map.get_height() - 1:
		for x in province_map.get_width() - 1:
			var id := _map_id(x, y)
			var right := _map_id(x + 1, y)
			var down := _map_id(x, y + 1)
			if _elevation_at(Vector2(x * cell, y * cell)) < -0.045:
				continue
			if id != right:
				draw_line(Vector2((x + 1) * cell, y * cell), Vector2((x + 1) * cell, (y + 1) * cell), Color(0.24, 0.22, 0.17, 0.42), 0.65 / zoom, true)
			if id != down:
				draw_line(Vector2(x * cell, (y + 1) * cell), Vector2((x + 1) * cell, (y + 1) * cell), Color(0.24, 0.22, 0.17, 0.42), 0.65 / zoom, true)

func _province_color(id: int) -> Color:
	if province_is_water[id]:
		var coastal := false
		for neighbor in province_neighbors[id]:
			if not province_is_water[neighbor]:
				coastal = true
				break
		return Color("#3d7890") if coastal else Color("#28556f")
	var color: Color = TERRAIN_COLORS[province_terrain[id]]
	if province_owner[id] >= 0:
		color = country_colors[province_owner[id]].lerp(color, 0.22)
	return color

func _draw_armies() -> void:
	for i in armies.size():
		var army := armies[i]
		var position: Vector2 = seeds[army.province]
		var chosen := i == selected_army
		var radius := 11.0 if chosen else 8.5
		draw_circle(position, radius + 3.0, Color(0.10, 0.12, 0.11, 0.55))
		draw_circle(position, radius, Color("#efe2bd") if chosen else Color("#d9c48f"))
		draw_arc(position, radius, 0.0, TAU, 24, Color("#4c4434"), 1.5 / zoom, true)
		# A tiny tent glyph remains legible without overpowering the geography.
		var tent := PackedVector2Array([position + Vector2(-5, 4), position + Vector2(0, -5), position + Vector2(5, 4)])
		draw_polyline(tent, Color("#4c4434"), 1.6 / zoom, true)
		if chosen:
			draw_string(ThemeDB.fallback_font, position + Vector2(15, 5), "%d" % army.population, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#2e2a21"))

func _draw_ui() -> void:
	if map_level == "local":
		draw_rect(Rect2(18, 18, 310, 76), Color(0.10, 0.12, 0.12, 0.82), true)
		draw_string(ThemeDB.fallback_font, Vector2(32, 47), province_names[active_province].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#efe2bd"))
		draw_string(ThemeDB.fallback_font, Vector2(32, 74), "%s province  •  local seed %d" % [province_terrain[active_province], world_seed ^ ((active_province + 1) * 104729)], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#eee6d2"))
		draw_string(ThemeDB.fallback_font, Vector2(24, get_viewport_rect().size.y - 22), "Escape: world map  •  Middle-drag: pan  •  Wheel: zoom", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#eee6d2"))
		return
	draw_rect(Rect2(18, 18, 238, 48), Color(0.10, 0.12, 0.12, 0.76), true)
	draw_string(ThemeDB.fallback_font, Vector2(32, 48), "WORLD SEED  %d" % world_seed, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#eee6d2"))
	draw_string(ThemeDB.fallback_font, Vector2(24, get_viewport_rect().size.y - 22), "Double-click land: enter province  •  Middle-drag: pan  •  Wheel: zoom", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#eee6d2"))
	if selected_army >= 0:
		var settler := armies[selected_army]
		draw_rect(Rect2(18, 78, 238, 76), Color(0.10, 0.12, 0.12, 0.82), true)
		draw_string(ThemeDB.fallback_font, Vector2(32, 106), "SETTLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#efe2bd"))
		draw_string(ThemeDB.fallback_font, Vector2(32, 132), "Population  %d" % settler.population, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#eee6d2"))
		draw_string(ThemeDB.fallback_font, Vector2(24, get_viewport_rect().size.y - 44), "Right-click a neighboring land province to move", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#eee6d2"))

func _format_population(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	return "%dk" % (value / 1000)

func _make_province_name(index: int) -> String:
	var starts := ["Ash", "Bel", "Cor", "Dun", "Eld", "Fen", "Grey", "High", "Iron", "Jun", "Kings", "Low", "Mar", "Nor", "Oak", "Pen", "Raven", "Stone", "Thorn", "West"]
	var ends := ["barrow", "bridge", "coast", "dale", "field", "ford", "haven", "march", "mere", "moor", "port", "reach", "stead", "vale", "watch", "wick"]
	return starts[index % starts.size()] + ends[(index * 7 + 3) % ends.size()]
