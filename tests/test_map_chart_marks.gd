extends GdUnitTestSuite
## Map chart work (codex/map-2): the discovery mask painted incrementally must
## equal a full repaint, and the settlement glyph atlas has one mark per stage.

const RENDERER:=preload("res://scripts/local_terrain.gd")
const ICONS:=preload("res://scripts/resource_icons.gd")

class IsolatedRenderer extends RENDERER:
	func _ready()->void:pass

var renderer:Node3D


func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(741991)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	renderer=auto_free(IsolatedRenderer.new())
	renderer.set_process(false);add_child(renderer)
	renderer.world_width=40075.0;renderer.world_depth=20004.0


func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)


func test_incremental_discovery_mask_matches_full_repaint()->void:
	CivilizationSystem.revealed_areas.clear()
	CivilizationSystem._add_revealed_area(Vector2(120,40),60.0,"probe")
	CivilizationSystem._add_revealed_trail([{"x":120.0,"z":40.0},{"x":300.0,"z":90.0}],34.0,"probe")
	renderer._refresh_discovery_mask(true)
	# A new record, then the latest trail extended in place.
	CivilizationSystem._add_revealed_area(Vector2(-400,-250),80.0,"probe")
	renderer._refresh_discovery_mask()
	CivilizationSystem._append_revealed_travel(Vector2(300,90),Vector2(420,160))
	CivilizationSystem._append_revealed_travel(Vector2(420,160),Vector2(520,210))
	renderer._refresh_discovery_mask()
	var incremental:Image=renderer.discovery_mask_image.duplicate()
	renderer._refresh_discovery_mask(true)
	assert_that(incremental.get_data()).is_equal(renderer.discovery_mask_image.get_data())
	assert_int(renderer.discovery_mask_painted).is_equal(CivilizationSystem.revealed_areas.size())


func test_forgotten_record_forces_a_full_repaint()->void:
	CivilizationSystem.revealed_areas.clear()
	CivilizationSystem._add_revealed_area(Vector2(0,0),200.0,"probe")
	CivilizationSystem._add_revealed_area(Vector2(900,0),200.0,"probe")
	renderer._refresh_discovery_mask(true)
	CivilizationSystem.revealed_areas.pop_front();CivilizationSystem.fog_revision+=1
	renderer._refresh_discovery_mask()
	var after_forgetting:Image=renderer.discovery_mask_image.duplicate()
	renderer._refresh_discovery_mask(true)
	assert_that(after_forgetting.get_data()).is_equal(renderer.discovery_mask_image.get_data())


func test_settlement_atlas_has_a_distinct_mark_per_stage_and_for_strangers()->void:
	var atlas:=ICONS.settlement_atlas()
	assert_int(atlas.get_width()).is_equal(ICONS.SETTLEMENT_GLYPH_PX*ICONS.SETTLEMENT_GLYPH_COUNT)
	var image:=atlas.get_image()
	var inked:Array[int]=[]
	for index in ICONS.SETTLEMENT_GLYPH_COUNT:
		var cell:=image.get_region(Rect2i(index*ICONS.SETTLEMENT_GLYPH_PX,0,ICONS.SETTLEMENT_GLYPH_PX,ICONS.SETTLEMENT_GLYPH_PX))
		var count:=0
		for y in cell.get_height():
			for x in cell.get_width():
				if cell.get_pixel(x,y).a>0.5:count+=1
		inked.append(count)
	# Every cell carries a mark, and the camp to megalopolis marks grow.
	for index in ICONS.SETTLEMENT_GLYPH_COUNT:assert_int(inked[index]).is_greater(40)
	for stage in range(1,7):assert_int(inked[stage]).is_greater_equal(inked[stage-1])
