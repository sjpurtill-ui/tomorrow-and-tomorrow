extends GdUnitTestSuite
## A town we take shows as ours on the chart, in the court's books and in
## the city report; every people's emblem is its own; our marks are unmistakable.
const ICONS=preload("res://scripts/resource_icons.gd")
const Identity=preload("res://scripts/city_map_identity.gd")
const Ownership=preload("res://scripts/map_ownership.gd")
const Combat=preload("res://scripts/civilization_combat.gd")
class Map extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 0.0

func before_test()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	MilitaryCampaign.reset_for_new_world()
	GameState.elapsed_days=400.0
	MilitaryCampaign.last_processed_day=400

func after_test()->void:
	MilitaryCampaign.occupation_forces.clear()

## A known second town of a people that has one (the town that will fall).
func _town()->Dictionary:
	var intel=CivilizationSystem.city_intelligence
	for civ:Dictionary in CivilizationSystem.civilizations:
		civ.player_relation.contact_level=2
		var capital:String=intel.primary_id(String(civ.id))
		for site:Dictionary in intel.sites(false):
			if site.civ_id==civ.id and String(site.city_id)!=capital:
				intel.publish("player",intel.capture("player",String(site.city_id),.85,390,"Scout report","test"),392)
				return intel.known("player",String(site.city_id))
	return {}

func _map(city:Dictionary)->Node3D:
	var map:Node3D=auto_free(Map.new());add_child(map)
	map.camera=Camera3D.new();map.add_child(map.camera)
	map.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	map.camera_target=Vector3(float(city.position.x),0,float(city.position.z))
	map.set_camera_distance_level(2);map.camera.size=map.zoom_target_size;map._update_camera()
	return map

## The fall of a town, as the general's campaign plays it: the region changes
## hands and our band leaves a guard (general_campaign._secure_home).
func _take(city:Dictionary,guard:int)->void:
	var owner:=String(city.civ_id)
	var index:=CivilizationSystem._civilization_index(owner)
	var fell:Dictionary=CivilizationSystem._capture_region(CivilizationSystem.civilizations[index],String(city.city_id),{"remaining_troops":400,"supply_level":1.0,"readiness":1.0,"dead":3},{"dead":9})
	CivilizationSystem.civilizations[index]=fell.get("civilization",CivilizationSystem.civilizations[index])
	MilitaryCampaign.occupation_forces.append({"civ_id":owner,"region_id":String(city.city_id),"region_name":String(city.name),"troops":guard,"committed_day":400,"formations":[]})

func test_a_town_we_take_turns_ours_on_the_chart()->void:
	var city:=_town()
	assert_bool(city.is_empty()).is_false()
	var map:=_map(city)
	map._refresh_contact_encounter_markers()
	var marker:Node3D=map.contact_encounter_markers[city.city_id]
	var label:=marker.get_node("SettlementLabel") as Label3D
	var glyph:=marker.get_node("RegionalCityGlyph") as GeometryInstance3D
	assert_str(String(label.get_meta("city_civilization_id"))).is_equal(String(city.civ_id))
	assert_int(int(glyph.get_meta("glyph"))).is_equal(ICONS.SETTLEMENT_GLYPH_FOREIGN)
	assert_bool(label.get_node("CivilizationFlag").texture==Identity.foreign(String(city.civ_id)).texture).is_true()
	_take(city,17)
	# No new scout report: the next map snapshot alone must show it as ours.
	map._refresh_contact_encounter_markers()
	assert_bool(marker==map.contact_encounter_markers[city.city_id]).is_true()
	assert_str(String(label.get_meta("city_civilization_id"))).is_equal("player")
	assert_int(int(glyph.get_meta("glyph"))).is_equal(ICONS.SETTLEMENT_GLYPH_OCCUPIED)
	assert_bool(label.get_node("CivilizationFlag").texture==Identity.emblem("player")).is_true()
	map.city_labels.refresh()
	var card:Dictionary=map.city_labels.cards[0]
	var people:=String(CivilizationSystem.civilizations[CivilizationSystem._civilization_index(String(city.civ_id))].name)
	assert_str(String(card.affiliation)).starts_with("Ours · taken from ")
	assert_str(String(card.affiliation).to_lower()).contains(people.to_lower().trim_prefix("the "))
	assert_str(String(card.note)).starts_with("Held since Year ")
	assert_str(String(card.note)).ends_with("17 hold it")
	assert_int(int(card.badge)).is_equal(17)
	assert_bool(card.flag==Identity.emblem("player")).is_true()

func test_our_book_names_us_holder_and_every_report_agrees()->void:
	var city:=_town()
	var intel=CivilizationSystem.city_intelligence
	assert_str(String(intel.known("player",city.city_id).controller)).is_equal(String(city.civ_id))
	_take(city,9)
	# The stored scout record is untouched evidence; what we are told is ours.
	assert_str(String(intel.records.player[city.city_id].controller)).is_equal(String(city.civ_id))
	assert_str(String(intel.known("player",city.city_id).controller)).is_equal("player")
	var listed:Array=intel.known_cities("player","",false)
	assert_str(String(listed.filter(func(c:Dictionary)->bool:return c.city_id==city.city_id)[0].controller)).is_equal("player")
	# The war planner no longer offers our own town as a target.
	for row:Dictionary in intel.public_regions(String(city.civ_id)):
		if row.id==city.city_id:assert_bool(bool(row.available)).is_false()
	# The city report and the dock caption say the same as the map card.
	var status:=Ownership.status(intel.known("player",city.city_id))
	assert_str(String(status.kind)).is_equal("occupied")
	var dock:Variant=preload("res://scripts/hud/content/dock_detail_foreign_city.gd").new(null,null,String(city.city_id))
	var caption:=String(dock.tab(0).blocks[0].caption)
	assert_str(caption).starts_with(String(status.line))
	assert_str(caption).contains("9 hold it")
	# Other observers keep their own last sighting.
	intel.publish("civ_09",intel.location_record({"city_id":city.city_id,"civ_id":city.civ_id,"name":city.name,"position":city.position},390,"x","y"),392)
	assert_str(String(intel.known("civ_09",city.city_id).controller)).is_equal("")

func test_a_town_we_lose_shows_its_new_holder()->void:
	var city:=_town()
	var intel=CivilizationSystem.city_intelligence
	_take(city,5)
	intel.publish("player",intel.capture("player",String(city.city_id),.85,401,"Scout report","after"),402)
	assert_str(String(intel.records.player[city.city_id].controller)).is_equal("player")
	var index:=CivilizationSystem._civilization_index(String(city.civ_id))
	CivilizationSystem._restore_region_to_rival(CivilizationSystem.civilizations[index],String(city.city_id))
	MilitaryCampaign.occupation_forces.clear()
	assert_str(String(intel.known("player",city.city_id).controller)).is_equal(String(city.civ_id))
	assert_str(String(Ownership.status(intel.known("player",city.city_id)).kind)).is_not_equal("occupied")

func test_world_capture_changes_the_holder_at_once()->void:
	var civ:={"id":"civ_07","strategic_regions":[{"id":"civ_07_region_01","controller":"civ_07"},{"id":"civ_07_region_02","controller":"civ_07"}]}
	Combat._set_controller(civ,"civ_07_region_02","player")
	assert_str(String(civ.strategic_regions[1].controller)).is_equal("player")
	assert_int(int(civ.strategic_regions[1].last_control_change_day)).is_equal(400)
	assert_str(String(civ.strategic_regions[0].controller)).is_equal("civ_07")

func test_marks_read_by_kind()->void:
	var intel=CivilizationSystem.city_intelligence
	var capital_id:String=intel.primary_id("civ_01")
	var capital:={"city_id":capital_id,"civ_id":"civ_01","controller":"civ_01","fields":{}}
	assert_str(String(Ownership.status(capital).kind)).is_equal("rival_capital")
	assert_int(int(Ownership.status(capital).glyph)).is_equal(ICONS.SETTLEMENT_GLYPH_RIVAL_CAPITAL)
	var burned:={"city_id":"civ_01_region_02","civ_id":"civ_01","controller":"civ_01","fields":{"damage":{"low":.7,"high":.9}}}
	assert_str(String(Ownership.status(burned).kind)).is_equal("ruined")
	MilitaryCampaign.active_siege={"active":true,"mode":"offensive","region_id":"civ_01_region_02","days":3}
	var sieged:={"city_id":"civ_01_region_02","civ_id":"civ_01","controller":"civ_01","fields":{}}
	assert_str(String(Ownership.status(sieged).kind)).is_equal("besieged")
	assert_str(String(Ownership.status(sieged).note)).is_equal("Our siege · day 4")
	MilitaryCampaign.active_siege={}
	var plain:={"city_id":"civ_02_region_02","civ_id":"civ_02","controller":"civ_02","fields":{}}
	var foreign:=Ownership.status(plain)
	assert_str(String(foreign.kind)).is_equal("foreign")
	assert_float((foreign.accent as Color).a).is_greater(0.0)
	# Every kind has its own mark in the atlas, and the chart key lists them.
	var marks:={}
	for row:Dictionary in Ownership.LEGEND:marks[int(row.glyph)]=true
	for glyph in [ICONS.SETTLEMENT_GLYPH_FOREIGN,ICONS.SETTLEMENT_GLYPH_OCCUPIED,ICONS.SETTLEMENT_GLYPH_RIVAL_CAPITAL,ICONS.SETTLEMENT_GLYPH_BESIEGED,ICONS.SETTLEMENT_GLYPH_RUINED]:
		assert_bool(marks.has(glyph)).is_true()
	var image:=ICONS.settlement_atlas().get_image()
	var cells:={}
	for index in ICONS.SETTLEMENT_GLYPH_COUNT:
		cells[image.get_region(Rect2i(index*ICONS.SETTLEMENT_GLYPH_PX,0,ICONS.SETTLEMENT_GLYPH_PX,ICONS.SETTLEMENT_GLYPH_PX)).get_data().hex_encode()]=true
	assert_int(cells.size()).is_equal(ICONS.SETTLEMENT_GLYPH_COUNT)

func test_no_two_peoples_share_outline_and_colour()->void:
	for seed_value in [1,424242,-212121,1788457137]:
		GameState.reset_for_new_world(seed_value)
		var pairs:={}
		for index in 36:
			var id:="civ_%02d" % (index+1)
			var entry:=Identity.foreign(id)
			var key:=String(entry.shape)+"|"+(entry.accent as Color).to_html()
			assert_bool(pairs.has(key)).override_failure_message("%s shares %s" % [id,key]).is_false()
			pairs[key]=true
			# Our round seal is ours alone.
			assert_str(String(entry.shape)).is_not_equal("seal")
		# The first eight peoples of a world, the ones met first, all differ in outline.
		var outlines:={}
		for index in 8:outlines[String(Identity.foreign("civ_%02d" % (index+1)).shape)]=true
		assert_int(outlines.size()).is_equal(8)

func test_our_emblem_is_unmistakable_and_the_same_everywhere()->void:
	var ours:=Identity.emblem("player")
	assert_bool(ours==Identity.player_crest(maxi(0,GameState.founding_banner_index))).is_true()
	for index in 36:assert_bool(Identity.foreign("civ_%02d" % (index+1)).texture==ours).is_false()
	# The gold star sits above the seal: gold pixels in the top band of ours only.
	var image:=ours.get_image();image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	assert_bool(_has_gold_top(image)).is_true()
	var theirs:Image=(Identity.foreign("civ_01").texture as Texture2D).get_image();theirs.clear_mipmaps();theirs.convert(Image.FORMAT_RGBA8)
	assert_bool(_has_gold_top(theirs)).is_false()
	# The court's league rows wear the very emblems the city cards do.
	var court:Node=preload("res://scripts/hud/court_council_panel.gd").new()
	add_child(court);auto_free(court)
	court._fill_league({"league":{"members":["player","civ_01"],"goal":"defense","since":0,"joined":{},"votes":{}}})
	var seen:={}
	for id in ["player","civ_01"]:
		var row:Node=court.find_child("Member_"+id,true,false)
		assert_object(row).is_not_null()
		var icon:=row.find_children("*","TextureRect",true,false)[0] as TextureRect
		seen[id]=icon.texture
	assert_bool(seen.player==ours).is_true()
	assert_bool(seen.civ_01==Identity.foreign("civ_01").texture).is_true()

static func _has_gold_top(image:Image)->bool:
	var gold:=ICONS.EMBLEM_GOLD
	for y in int(image.get_height()*0.12):
		for x in image.get_width():
			var c:=image.get_pixel(x,y)
			if c.a>0.8 and absf(c.r-gold.r)<.08 and absf(c.g-gold.g)<.08 and absf(c.b-gold.b)<.08:return true
	return false

func test_every_screen_that_shows_a_holder_still_loads()->void:
	for path in ["res://scripts/city_intelligence_screen.gd","res://scripts/hud/war_front_overlay.gd","res://scripts/hud/map_legend.gd","res://scripts/hud/court_council_panel.gd"]:
		var script:=load(path) as Script
		assert_bool(script!=null and script.can_instantiate()).override_failure_message(path).is_true()
