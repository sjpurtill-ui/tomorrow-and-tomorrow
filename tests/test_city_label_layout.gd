extends GdUnitTestSuite
const Labels=preload("res://scripts/hud/city_labels.gd")

func test_city_summary_has_units_unknowns_and_bounded_staleness()->void:
	GameState.known_discoveries=[]
	var report:={"observed_day":10,"fields":{"population":{"low":67,"high":158,"observed_day":10},"life_expectancy":{"low":38,"high":52,"observed_day":10}}}
	var fresh:=Labels.report_summary(report,20)
	assert_int(fresh.stats.size()).is_equal(4)
	for stat:Dictionary in fresh.stats:
		assert_float(ThemeDB.fallback_font.get_string_size(String(stat.label),HORIZONTAL_ALIGNMENT_LEFT,-1,9).x).is_less_equal(120.0)
	assert_str(fresh.stats[0].label).contains("PEOPLE")
	assert_str(fresh.stats[1].value).is_equal("Unknown")
	# Before printing, scouts report hands at work, not "GDP · WORK-DAYS/D".
	assert_str(fresh.stats[2].label).contains("HANDS AT WORK")
	assert_str(fresh.stats[3].value).is_equal("40–50 winters")
	assert_int(fresh.level).is_equal(5)
	assert_dict(Labels.report_summary(report,1000)).is_equal(Labels.report_summary(report,10000))
	assert_int(Labels.report_summary({"observed_day":-1},100).level).is_equal(0)

func test_new_city_metrics_build_in_detail_panel()->void:
	var screen=auto_free(preload("res://scripts/city_intelligence_screen.gd").new())
	var rows=auto_free(VBoxContainer.new())
	for key:String in ["science_capacity","gdp","life_expectancy","infant_mortality","education"]:
		screen._metric(rows,key)
		assert_bool(screen.cards.has(key)).is_true()

func test_new_report_has_receipt_grace_without_falsifying_observation_date()->void:
	var report:={"observed_day":10,"reported_day":200,"fields":{"population":{"low":67,"high":158,"observed_day":10,"reported_day":200}}}
	assert_int(Labels.report_summary(report,290).level).is_equal(5)
	assert_int(Labels.report_summary(report,291).level).is_equal(4)
	assert_int(report.fields.population.observed_day).is_equal(10)
	report.fields["science"]={"low":.5,"high":.9,"observed_day":10}
	assert_str(Labels.report_summary(report,200).stats[1].value).is_equal("Unknown")

class Map extends "res://scripts/local_terrain.gd":
	var army_picked:=false
	var site_review_opened:=false
	func _on_settlement_action_pressed()->void:site_review_opened=true
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

func test_founding_card_tracks_convoy_at_all_distances_and_opens_site_review()->void:
	GameState.reset_for_new_world(741991);CivilizationSystem.reset_for_new_world()
	var map:Node3D=auto_free(Map.new());add_child(map)
	map.camera=Camera3D.new();map.add_child(map.camera)
	map.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	map.settler_marker=Area3D.new();map.add_child(map.settler_marker)
	var label:=Label3D.new();map.settler_marker.add_child(label);map.convoy_map_label=label
	label.text="Founding convoy  •  110"
	label.set_meta("city_map_id","__founding_convoy__");label.set_meta("city_civilization_id","player")
	label.set_meta("map_annotation_kind","founding_convoy");label.set_meta("map_status","Fresh water unconfirmed · Review site")
	map._update_city_flag(label)
	for level:Dictionary in map.CAMERA_DISTANCE_LEVELS:
		map.camera.size=float(level.width_km);map._update_camera();map.city_labels.refresh()
		assert_array(map.city_labels.cards).has_size(1)
		var card:Dictionary=map.city_labels.cards[0]
		assert_str(card.title).is_equal("Founding convoy")
		assert_str(card.population).is_equal("Population 110")
		assert_float(card.rect.size.x).is_less_equal(350.0)
		assert_float(card.rect.size.y).is_less_equal(70.0)
		assert_int(label.layers).is_equal(0)
		assert_int((label.get_node("CivilizationFlag") as Sprite3D).layers).is_equal(0)
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=card.rect.get_center()
		map._unhandled_input(click)
		assert_bool(map.site_review_opened).is_true();assert_bool(map.army_picked).is_false()
	map.settler_marker.position=Vector3(.1,0,.1);map.city_labels.refresh()
	assert_vector(map.city_labels.cards[0].anchor).is_equal(map.camera.unproject_position(map.settler_marker.global_position))
	label.hide();map.city_labels.refresh();assert_array(map.city_labels.cards).is_empty()

func test_map_cards_avoid_site_review_panel_as_well_as_other_cards()->void:
	var bounds:=Rect2(90,100,914,470)
	var review:=Rect2(656,108,350,430)
	var entries:Array[Dictionary]=[entry("convoy",Vector2(700,400),false),entry("neighbor",Vector2(600,400))]
	var reserved:Array[Rect2]=[review]
	var result:Dictionary=Labels.arrange(entries,bounds,{},reserved)
	assert_array(result.cards).has_size(2)
	for card:Dictionary in result.cards:assert_bool(card.rect.intersects(review)).is_false()
	assert_separate(result.cards,bounds)

func kusala_report()->Dictionary:
	return {"observed_day":10,"fields":{"population":{"low":89,"high":144},"gdp":{"low":37,"high":70},"science_capacity":{"low":3.2,"high":5.8},"education":{"low":.52,"high":.95},"life_expectancy":{"low":14,"high":28},"infant_mortality":{"low":206,"high":382}}}

func test_scout_report_uses_plain_era_words_and_round_ranges_before_statistics()->void:
	GameState.known_discoveries=[]
	var summary:=Labels.report_summary(kusala_report(),20)
	var text:=str(summary)
	assert_str(text).not_contains("Taught").not_contains("3.2").not_contains("5.8").not_contains("‰").not_contains("GDP")
	assert_str(summary.stats[0].value).is_equal("90–140")
	assert_str(summary.stats[1].value).is_equal("3–6")
	assert_str(summary.stats[1].detail).is_equal("many are taught")
	assert_str(summary.stats[2].value).is_equal("35–70")
	assert_str(summary.stats[3].value).is_equal("14–30 winters")
	assert_str(summary.stats[3].detail).is_equal("Babes lost: 20–40 in 100")
	assert_str(summary.heading).is_equal("WORD")
	# Once statistics exist the precise report returns.
	GameState.known_discoveries=["printing_process"]
	var modern:=Labels.report_summary(kusala_report(),20)
	assert_str(modern.stats[1].value).is_equal("3.2–5.8")
	assert_str(modern.stats[3].detail).contains("infant deaths")
	GameState.known_discoveries=[]

func hover_overlay()->Control:
	var overlay:Control=auto_free(Labels.new());add_child(overlay)
	overlay.last_bounds=Rect2(0,0,1280,720)
	var cards:Array[Dictionary]=[
		{"id":"kusala","compact":true,"rect":Rect2(400,300,120,30),"detail_extent":Vector2(260,150),"anchor":Vector2(460,350),"foreign":true,"lines":["Kusala"],"color":Color.RED,"flag":null},
		{"id":"home","compact":true,"rect":Rect2(700,300,120,30),"detail_extent":Vector2(160,65),"anchor":Vector2(760,350),"foreign":false,"lines":["Seanston"],"color":Color.GREEN,"flag":null}]
	overlay.cards=cards
	return overlay

func test_city_card_is_a_name_until_hovered_then_collapses_on_exit()->void:
	var overlay:=hover_overlay()
	assert_str(overlay.expanded_id()).is_empty()
	overlay.hover_at(Vector2(450,315))
	overlay._process(.1)
	assert_str(overlay.expanded_id()).is_empty()
	overlay._process(.3)
	assert_str(overlay.expanded_id()).is_equal("kusala")
	# The open card is itself part of the hover area.
	var detail:Rect2=overlay.detail_rect(overlay.cards[0])
	assert_vector(detail.size).is_equal(Vector2(260,150))
	overlay.hover_at(Vector2(detail.end.x-5,detail.end.y-5))
	assert_str(overlay.expanded_id()).is_equal("kusala")
	overlay.hover_at(Vector2(100,650))
	assert_str(overlay.expanded_id()).is_empty()

func test_tap_pins_city_card_until_click_away()->void:
	var overlay:=hover_overlay()
	var tap:=InputEventScreenTouch.new();tap.pressed=true;tap.position=Vector2(750,315)
	overlay._input(tap)
	assert_str(overlay.expanded_id()).is_equal("home")
	var away:=InputEventMouseButton.new();away.button_index=MOUSE_BUTTON_LEFT;away.pressed=true;away.position=Vector2(100,650)
	overlay._input(away)
	assert_str(overlay.expanded_id()).is_empty()

# --------------------------------------------------------------------------
# The guard badge: those keeping watch, then "+N" townsfolk who would rise
# --------------------------------------------------------------------------

const EraWords:=preload("res://scripts/hud/era_words.gd")

## One of our towns' cards, measured as the layer measures it, with its guard
## in the badge's parts.
func guard_card(title:String,watch:int,rise:int,flag:bool=false)->Dictionary:
	var label:=Label3D.new();label.text="%s  •  60" % title
	var card:=Labels._measure_card(label,{},false,"",flag,preload("res://scripts/hud/hud_tokens.gd").voice_font(),Rect2(0,0,1600,900),{},"guarded",{"watch":watch,"rise":rise,"bands":0})
	label.free()
	card["id"]="guarded";card["compact"]=true;card["flag"]=null
	return card

func test_guard_badge_sets_the_watch_apart_from_the_townsfolk_and_fits_its_tag()->void:
	var ui:=preload("res://scripts/hud/hud_tokens.gd").font("ui")
	var voice:=preload("res://scripts/hud/hud_tokens.gd").voice_font()
	# "2 +5": the townsfolk take room of their own beside the watch.
	assert_str(Labels.rise_text(5)).is_equal("+5")
	assert_float(Labels.badge_width(2,5)).is_greater(Labels.badge_width(2)+8.0)
	assert_float(Labels.badge_width(0,3)).is_greater(Labels.badge_width(0)+8.0)
	for parts:Array in [[2,5,false],[0,3,false],[1240,3800,false],[2,5,true],[7,0,false]]:
		var card:=guard_card("Ashfire",int(parts[0]),int(parts[1]),bool(parts[2]))
		assert_int(int(card.badge)).is_equal(int(parts[0]))
		assert_int(int(card.rise)).is_equal(int(parts[1]))
		assert_str(String(card.badge_tip)).is_not_empty()
		var text_x:=46.0 if bool(parts[2]) else 11.0
		var name_end:=text_x+voice.get_string_size("Ashfire",HORIZONTAL_ALIGNMENT_LEFT,-1,Labels.NAME_SIZE).x
		# The tag makes room for the whole badge after the name: inside the
		# tag, clear of the name's last letter, on the name's line.
		var tag:=Rect2(Vector2(300,200),Vector2(float(card.name_width),float(card.lines.size())*20+10))
		var chip:=Labels.badge_rect(card,tag)
		assert_bool(tag.encloses(chip)).override_failure_message(str(parts)).is_true()
		assert_float(chip.position.x-tag.position.x).override_failure_message(str(parts)).is_greater_equal(name_end+8.0)
		assert_float(tag.end.x-chip.end.x).is_equal_approx(5.0,1.0)
		# The figures fit inside the chip: count, gap, "+N".
		var figures:=15.0+ui.get_string_size(EraWords.grouped(int(parts[0])),HORIZONTAL_ALIGNMENT_LEFT,-1,Labels.BADGE_SIZE).x
		if int(parts[1])>0:figures+=Labels.BADGE_RISE_GAP+ui.get_string_size(Labels.rise_text(int(parts[1])),HORIZONTAL_ALIGNMENT_LEFT,-1,Labels.BADGE_SIZE).x
		assert_float(figures).is_less_equal(chip.size.x)
		# The open card is never narrower, and its badge stays in place.
		assert_float(float((card.detail as Vector2).x)).is_greater_equal(float(card.name_width))
		assert_bool(Labels.badge_rect(card,Rect2(tag.position,card.detail))==chip).is_true()
	# Nobody keeps watch and nobody would rise: no badge, no room for one.
	var bare:=guard_card("Ashfire",0,0)
	assert_str(String(bare.badge_tip)).is_empty()
	assert_float(float(bare.name_width)).is_equal(ceilf(voice.get_string_size("Ashfire",HORIZONTAL_ALIGNMENT_LEFT,-1,Labels.NAME_SIZE).x+22))

func test_guard_badge_words_say_who_keeps_watch_and_who_would_rise()->void:
	assert_str(Labels.guard_words(2,5)).is_equal("2 keep watch here. If the town is attacked, about 5 of its grown townsfolk would take up whatever is at hand and fight beside them (1 in 10 of the grown people).")
	assert_str(Labels.guard_words(0,3)).is_equal("No one keeps watch here. If the town is attacked, about 3 of its grown townsfolk would take up whatever is at hand and fight (1 in 10 of the grown people).")
	assert_str(Labels.guard_words(1,0)).is_equal("1 keeps watch here.")
	assert_str(Labels.guard_words(2,5,2)).ends_with("None of them is kept as the home guard: a general may lead them away in a band.")
	assert_str(Labels.guard_words(35,9,20)).ends_with("15 of them are the home guard and stay; a general may lead the other 20 away in a band.")
	assert_str(Labels.guard_words(1240,380)).starts_with("1,240 keep watch here.").contains("about 380 of its")
	assert_str(Labels.held_words(17)).is_equal("17 of our fighters hold this town.")

func test_guard_badge_words_open_under_the_pointer_and_stay_on_screen()->void:
	var overlay:=hover_overlay()
	var card:=guard_card("Ashfire",2,5)
	card["rect"]=Rect2(Vector2(400,500),Vector2(float(card.name_width),30));card["anchor"]=Vector2(390,560);card["detail_extent"]=card.detail
	card["color"]=Color.WHITE;card["lines"]=["Ashfire"]
	var shown:Array[Dictionary]=[card,overlay.cards[1]]
	overlay.cards=shown
	var chip:=Labels.badge_rect(card,card.rect)
	# Resting on the badge: its words wait as the card does, then open.
	overlay.hover_at(chip.get_center())
	assert_str(overlay.badge_hover_id).is_equal("guarded")
	assert_str(overlay.badge_at(chip.get_center())).is_equal("guarded")
	overlay._process(.4)
	assert_float(overlay.badge_elapsed).is_greater_equal(Labels.HOVER_DELAY)
	# The card opened under the pointer and its badge did not move.
	assert_str(overlay.expanded_id()).is_equal("guarded")
	assert_str(overlay.badge_at(chip.get_center())).is_equal("guarded")
	# Elsewhere on the open card, or off it: no words.
	overlay.hover_at(card.rect.position+Vector2(8,20))
	assert_str(overlay.badge_hover_id).is_empty()
	overlay.hover_at(Vector2(100,650))
	assert_str(overlay.badge_hover_id).is_empty()
	# A badge with no words (a town of strangers) opens none.
	assert_str(overlay.badge_at(Labels.badge_rect(overlay.cards[1],overlay.cards[1].rect).get_center())).is_empty()
	# The words open under the card, or above it near the foot of the screen,
	# always on screen.
	var screen:=Rect2(0,0,1280,720)
	var below:=Labels.badge_tip_rect(chip,card.rect,Vector2(300,80),screen)
	assert_float(below.position.y).is_greater_equal(card.rect.end.y)
	assert_float(below.position.x).is_equal(chip.position.x)
	var low:=Rect2(Vector2(1200,660),Vector2(70,30))
	var above:=Labels.badge_tip_rect(Labels.badge_rect(card,low),low,Vector2(300,80),screen)
	assert_float(above.end.y).is_less_equal(low.position.y)
	assert_bool(screen.encloses(above)).is_true()
