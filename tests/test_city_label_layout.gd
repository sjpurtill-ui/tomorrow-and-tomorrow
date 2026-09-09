extends GdUnitTestSuite
const Labels=preload("res://scripts/hud/city_labels.gd")
class Map extends "res://scripts/local_terrain.gd":
	var army_picked:=false
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 0.0
	func _update_scale_lod()->void:pass
	func _inspect_location(_position:Vector3)->void:pass
	func _select_field_army_from_screen(_point:Vector2)->bool:army_picked=true;return true

class Actions extends Node:
	var camera:Camera3D
	var selected:=""
	func _show_city_intel_summary(id:String)->void:selected=id
	func _focus_settlement_from_screen(_point:Vector2,_close:bool,id:String="")->bool:selected=id;return true

func entry(id:String,point:Vector2,foreign:bool=true)->Dictionary:
	return {"id":id,"anchor":point,"extent":Vector2(230,45),"foreign":foreign}

func assert_separate(cards:Array,bounds:Rect2)->void:
	for i in cards.size():
		assert_bool(bounds.encloses(cards[i].rect)).is_true()
		for j in range(i+1,cards.size()):assert_bool(cards[i].rect.intersects(cards[j].rect)).is_false()

func test_colliding_city_names_are_all_retained_without_covering_each_other_or_pins()->void:
	var entries:Array[Dictionary]=[entry("home",Vector2(640,420),false),entry("breadlands",Vector2(644,418)),entry("seat",Vector2(648,430)),entry("fields",Vector2(635,419))]
	var bounds:=Rect2(90,100,1080,550)
	var result:Dictionary=Labels.arrange(entries,bounds)
	assert_array(result.cards).has_size(4);assert_array(result.overflow).is_empty()
	assert_separate(result.cards,bounds)
	for card:Dictionary in result.cards:
		for city:Dictionary in entries:assert_bool(card.rect.grow(8).has_point(city.anchor)).is_false()

func test_tiny_pan_keeps_city_card_offsets_stable_instead_of_jumping_slots()->void:
	var entries:Array[Dictionary]=[entry("a",Vector2(520,350)),entry("b",Vector2(525,352)),entry("home",Vector2(518,345),false)]
	var bounds:=Rect2(90,100,1080,550)
	var initial:Dictionary=Labels.arrange(entries,bounds)
	var movement:=Vector2(.5,.75)
	for city:Dictionary in entries:city.anchor+=movement
	var next:Dictionary=Labels.arrange(entries,bounds,initial.memory)
	assert_dict(next.memory).is_equal(initial.memory)
	for i in initial.cards.size():assert_vector(next.cards[i].rect.position).is_equal(initial.cards[i].rect.position+movement)

func test_resize_keeps_cards_in_bounds_and_overflow_accounts_for_every_city()->void:
	var entries:Array[Dictionary]=[]
	for i in 70:entries.append(entry("city_%02d" % i,Vector2(510+i%5,350+i%4)))
	var large:Dictionary=Labels.arrange(entries,Rect2(90,100,1330,730))
	var bounds:=Rect2(90,100,914,470)
	var small:Dictionary=Labels.arrange(entries,bounds,large.memory)
	assert_separate(small.cards,bounds)
	assert_int(small.overflow.size()).is_greater(0)
	var ids:Array=[]
	for city:Dictionary in small.cards+small.overflow:ids.append(city.id)
	assert_array(ids).has_size(70)
	ids.sort()
	assert_array(ids).contains_same_exactly(entries.map(func(city:Dictionary):return city.id))

func test_city_name_wrap_preserves_words_and_population_is_not_part_of_the_title()->void:
	var name:="Ashen Breadlands Northern River Trading District"
	var lines:PackedStringArray=Labels.wrap_name(name,ThemeDB.fallback_font,260)
	assert_str(" ".join(lines)).is_equal(name)
	assert_int(lines.size()).is_greater(1)
	for line:String in lines:assert_float(ThemeDB.fallback_font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,Labels.NAME_SIZE).x).is_less_equal(260)

func test_dense_view_list_keeps_full_names_flags_and_direct_city_actions_and_closes_on_map()->void:
	var actions:Node=auto_free(Actions.new());add_child(actions)
	var overlay:Control=auto_free(Labels.new());overlay.terrain=actions;add_child(overlay)
	var identity:Dictionary=preload("res://scripts/city_map_identity.gd").foreign("test_civ")
	for data:Array in [["first","Ashen Breadlands",true],["second","Rivermeet",false]]:
		overlay.overflow.append({"id":data[0],"title":data[1],"foreign":data[2],"anchor":Vector2(600,400),"population":"est. 14–26","color":identity.color,"flag":identity.texture})
	overlay._update_overflow(Vector2(1280,720))
	assert_bool(overlay.more.visible).is_true()
	assert_int(overlay.list_rows.get_child_count()).is_equal(3)
	overlay.more.pressed.emit();assert_bool(overlay.list_panel.visible).is_true()
	var foreign_button:=overlay.list_rows.get_child(1) as Button
	assert_str(foreign_button.text).contains("Ashen Breadlands").contains("est. 14–26")
	assert_bool(foreign_button.icon==identity.texture).is_true()
	foreign_button.pressed.emit();assert_str(actions.selected).is_equal("first")
	(overlay.list_rows.get_child(2) as Button).pressed.emit();assert_str(actions.selected).is_equal("second")
	overlay.more.pressed.emit()
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	overlay._unhandled_input(click);assert_bool(overlay.list_panel.visible).is_false()

func test_owned_and_foreign_cards_share_layout_and_relocated_cards_select_the_right_city()->void:
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(1000)
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3.ZERO;SettlementModel.ensure_founded()
	GameState.player_settlements[0].position=Vector2.ZERO
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(.1,.1),"primary":false,"population_share":.2,"founded_day":20})
	var map:Node3D=auto_free(Map.new());add_child(map)
	map.camera=Camera3D.new();map.add_child(map.camera)
	map.camera.projection=Camera3D.PROJECTION_PERSPECTIVE;map.camera.size=100;map._update_camera()
	var labels:Array[Label3D]=[]
	for data:Array in [["second","Rivermeet  •  200",false],["known","Ashen Breadlands  •  est. 14–26",true],["unknown","Reported settlement  •  Population unknown",true]]:
		var label:=Label3D.new();label.text=data[1];label.set_meta("city_map_id",data[0]);label.set_meta("city_map_foreign",data[2]);label.set_meta("city_map_anchor",Vector3.ZERO)
		label.set_meta("city_civilization_id","test_civ" if data[2] else "player");map.add_child(label);map._update_city_flag(label);labels.append(label)
	map.city_labels.refresh()
	assert_array(map.city_labels.cards).has_size(3)
	assert_separate(map.city_labels.cards,Rect2(90,100,get_viewport().get_visible_rect().size.x-110,get_viewport().get_visible_rect().size.y-170))
	for card:Dictionary in map.city_labels.cards:
		assert_str(String(map.city_labels.city_at(card.rect.get_center()).id)).is_equal(String(card.id))
		if card.id=="second":
			assert_str(String(card.population)).is_equal("Population 200")
			var army_marker:=Node3D.new();map.add_child(army_marker)
			army_marker.global_position=map.camera.project_position(card.rect.get_center(),10)
			map.player_field_army_markers[99]=army_marker
			var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=card.rect.get_center()
			map._unhandled_input(click)
			assert_str(GameState.selected_player_settlement_id).is_equal("second")
			assert_bool(map.army_picked).is_false()
		elif card.id=="known":assert_str(String(card.population)).is_equal("est. 14–26")
		else:assert_str(String(card.population)).is_equal("Population unknown")
	assert_int(map.city_labels.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	labels[1].hide();map.city_labels.refresh()
	assert_array(map.city_labels.cards).has_size(2)
