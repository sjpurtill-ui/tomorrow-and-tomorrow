extends GdUnitTestSuite
class Terrain extends "res://scripts/local_terrain.gd":
	var movement_count:=0
	func _move_settlers_to_screen(_screen_position:Vector2)->void:movement_count+=1
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
class Hud extends Control:
	var dock:Control
	var detail_dock:Control
	var closed:=false
	func close_dock()->void:closed=true;dock.hide();detail_dock.hide()

func test_map_click_dismisses_tip_and_all_dock_levels_once()->void:
	var terrain:Node3D=auto_free(Terrain.new());add_child(terrain)
	var hud:Hud=auto_free(Hud.new());add_child(hud)
	hud.dock=Control.new();hud.add_child(hud.dock)
	hud.detail_dock=Control.new();hud.add_child(hud.detail_dock)
	terrain.hud=hud
	terrain.map_help_panel=PanelContainer.new();terrain.add_child(terrain.map_help_panel)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	terrain._unhandled_input(click)
	assert_int(terrain.movement_count).is_equal(0)
	assert_bool(hud.closed).is_true()
	assert_bool(terrain.map_help_dismissed).is_true()
	assert_bool(terrain.map_help_panel.visible).is_false()
	assert_bool(terrain._dismiss_map_panels()).is_false()

func test_report_backdrop_distinguishes_content_from_surrounding_map()->void:
	var terrain:Node3D=auto_free(Terrain.new());add_child(terrain)
	var root:Control=auto_free(Control.new());add_child(root);root.size=Vector2(800,600)
	var dimmer:=ColorRect.new();dimmer.size=root.size;root.add_child(dimmer)
	var body:=PanelContainer.new();body.position=Vector2(100,100);body.size=Vector2(600,400);root.add_child(body)
	assert_bool(terrain._outside_report_body(root,Vector2(20,20))).is_true()
	assert_bool(terrain._outside_report_body(root,Vector2(150,150))).is_false()
	root.hide()
	assert_bool(terrain._outside_report_body(root,Vector2(20,20))).is_false()
