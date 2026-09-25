extends GdUnitTestSuite
## Multiple research design blocks (data/research/blocks.json): the loader merges
## blocks in order, later blocks build on earlier ids, the era gate's window
## follows the latest block, and the first block behaves exactly as before.
## The game manifest lists the real 0-600, 600-1200, 1200-1800 and 1800-2400 blocks; the fixture
## second block here is a synthetic one built by
## tools/research/build_research_block.py (tests/fixtures/research_blocks), and
## FIRST_ONLY is the 0-600 block alone.
const Catalog=preload("res://scripts/research_600_catalog.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Visuals=preload("res://scripts/hud/research_visuals.gd")
const FIXTURE:="res://tests/fixtures/research_blocks/blocks.json"
const FIRST_ONLY:="res://tests/fixtures/research_blocks/first_block_only.json"
const FIXTURE_IDS:=["fx_bloom_hearths","bloomery_smelting","fx_iron_edge_tools","fx_district_courts"]

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	_use("")
	GameState.elapsed_days=0
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _use(manifest:String)->void:
	Catalog.use_manifest(manifest)
	Visuals.art600={}
	GameState.reset_for_new_world(60060);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()

func _entry(id:String)->Dictionary:
	return DiscoverySystem.discovery_definition(id)

func _earliest_years()->Dictionary:
	var result:Dictionary={}
	for entry:Dictionary in DiscoverySystem.technology_catalog:result[String(entry.id)]=DiscoverySystem.research_600_earliest_year(entry)
	return result

func test_the_game_manifest_lists_all_four_blocks()->void:
	_use("")
	assert_array(Catalog.blocks()).is_equal(["y0_600","y600_1200","y1200_1800","y1800_2400"])
	assert_float(Catalog.window_end_year()).is_equal(2400.0)
	var all:Array[String]=Catalog.block_ids("y0_600").duplicate()
	all.append_array(Catalog.block_ids("y600_1200"))
	all.append_array(Catalog.block_ids("y1200_1800"))
	all.append_array(Catalog.block_ids("y1800_2400"))
	assert_array(all).is_equal(Catalog.ids())
	assert_int(int(Catalog.meta().get("design_node_count",0))).is_equal(1101)
	assert_dict(Catalog.block_meta("y0_600")).is_equal(Catalog.meta())
	var second:=Catalog.block_meta("y600_1200")
	assert_int(int(second.get("node_count",0))).is_equal(964)
	assert_int(Catalog.block_ids("y600_1200").size()).is_equal(964)
	assert_array(second.get("prior_blocks",[])).is_equal(["y0_600"])
	assert_int(int(second.get("cross_block_references",0))).is_greater(0)
	var third:=Catalog.block_meta("y1200_1800")
	assert_int(int(third.get("node_count",0))).is_equal(937)
	assert_int(Catalog.block_ids("y1200_1800").size()).is_equal(937)
	assert_array(third.get("prior_blocks",[])).is_equal(["y0_600","y600_1200"])
	assert_int(int(third.get("cross_block_references",0))).is_greater(0)
	var fourth:=Catalog.block_meta("y1800_2400")
	assert_int(int(fourth.get("node_count",0))).is_equal(1139)
	assert_int(Catalog.block_ids("y1800_2400").size()).is_equal(1139)
	assert_array(fourth.get("prior_blocks",[])).is_equal(["y0_600","y600_1200","y1200_1800"])
	assert_int(int(fourth.get("cross_block_references",0))).is_greater(0)
	assert_array(Catalog.art_manifests()).is_equal(["res://data/research/art_600.json","res://data/research/art_y600_1200.json","res://data/research/art_y1200_1800.json","res://data/research/art_y1800_2400.json"])

func test_blocks_load_in_order_and_keep_the_first_block_intact()->void:
	_use(FIRST_ONLY)
	var first_ids:=Catalog.ids().duplicate()
	var first_meta:=Catalog.meta().duplicate(true)
	var first_years:=_earliest_years()
	_use(FIXTURE)
	assert_array(Catalog.blocks()).is_equal(["y0_600","y600_1200"])
	assert_array(Catalog.block_ids("y0_600")).is_equal(first_ids)
	assert_array(Catalog.block_ids("y600_1200")).is_equal(FIXTURE_IDS)
	assert_int(Catalog.ids().size()).is_equal(first_ids.size()+FIXTURE_IDS.size())
	assert_dict(Catalog.meta()).is_equal(first_meta)
	assert_int(int(Catalog.block_meta("y600_1200").get("node_count",0))).is_equal(4)
	for id:String in FIXTURE_IDS:
		assert_str(Catalog.block_of(id)).is_equal("y600_1200")
		assert_bool(_entry(id).is_empty()).override_failure_message(id).is_false()
	assert_str(Catalog.block_of("tallies")).is_equal("y0_600")
	# Every first-block design item keeps its gate; only entries left outside
	# every design move (undated, or dated past year 600) may change.
	var years:=_earliest_years()
	for id:String in first_ids:
		if years.has(id):assert_float(float(years[id])).override_failure_message(id).is_equal(float(first_years[id]))

func test_later_blocks_build_on_earlier_ids()->void:
	_use(FIXTURE)
	var hearths:=_entry("fx_bloom_hearths")
	assert_array(hearths.requires_all).is_equal(["copper_smelting"])
	assert_array(hearths.precedents).is_equal(["kiln_control"])
	GameState.known_discoveries.assign(["tallies"])
	assert_bool(P.ready(hearths,0)).is_false()
	GameState.known_discoveries.assign(["copper_smelting"])
	assert_bool(P.ready(hearths,0)).is_true()
	# An existing catalog id beyond year 600 takes its foundations and gate from the new block.
	var bloomery:=_entry("bloomery_smelting")
	assert_array(bloomery.requires_all).is_equal(["fx_bloom_hearths"])
	assert_float(DiscoverySystem.research_600_earliest_year(bloomery)).is_equal(665.0)
	assert_float(DiscoverySystem.discovery_era("bloomery_smelting")).is_equal(680.0)
	# requires_any groups may mix blocks.
	assert_array(_entry("fx_district_courts").requires_any).is_equal([["place_value","fx_iron_edge_tools"]])
	# Year adjustments move the proposed year and shift the band with it.
	assert_float(float(Catalog.item("fx_iron_edge_tools").proposed_year)).is_equal(720.0)
	assert_float(DiscoverySystem.research_600_earliest_year(_entry("fx_iron_edge_tools"))).is_equal(700.0)
	# Design conditions work the same way in later blocks.
	var society:=preload("res://tools/research/research_600_probe.gd").permissive_society();society.year=1000.0
	society.population=100.0
	assert_bool(DiscoverySystem.research_600_open(_entry("fx_district_courts"),society)).is_false()
	society.population=600.0
	assert_bool(DiscoverySystem.research_600_open(_entry("fx_district_courts"),society)).is_true()

func test_block_effects_and_art_apply_only_to_their_own_ids()->void:
	_use(FIRST_ONLY)
	var copper_effects:Dictionary=_entry("copper_smelting").effects.duplicate(true)
	var signal_art:=Visuals.subject_art_key(_entry("agreed_signal_codes"))
	_use(FIXTURE)
	var hearths:=_entry("fx_bloom_hearths")
	assert_dict(hearths.effects).is_equal({"metal_yield":0.012,"fuel_demand":0.004})
	assert_str(String(hearths.observation)).is_equal("Iron comes out of the clay hearth as a spongy bloom.")
	# A later block's effect file cannot re-author an earlier block's item.
	assert_dict(_entry("copper_smelting").effects).is_equal(copper_effects)
	# Unauthored new items get the per-line default.
	assert_dict(_entry("fx_iron_edge_tools").effects).is_equal(Catalog.DEFAULT_EFFECTS.production)
	assert_array(Catalog.art_manifests()).is_equal(["res://data/research/art_600.json","res://tests/fixtures/research_blocks/art_y600_1200.json"])
	assert_str(Visuals.subject_art_key(hearths)).is_equal("res://assets/ui/research/discovery-600/agreed_signal_codes.png")
	# Earlier blocks' paintings win for their ids.
	assert_str(Visuals.subject_art_key(_entry("agreed_signal_codes"))).is_equal(signal_art)

func test_the_era_gate_window_follows_the_latest_block()->void:
	_use(FIXTURE)
	assert_float(Catalog.window_end_year()).is_equal(1200.0)
	var eras:=preload("res://scripts/technology_eras.gd")
	var between:=0
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		var id:=String(entry.id)
		if Catalog.has(id) or Catalog.redate(id)>=0.0:continue
		var earliest:=DiscoverySystem.research_600_earliest_year(entry)
		var era:=DiscoverySystem.discovery_era(id)
		if eras.HISTORICAL_YEAR.has(id):
			var expected:=era*Catalog.ERA_BAND_FRACTION
			if era>600.0:expected=maxf(600.0,expected)
			if era>600.0 and era<=1200.0:between+=1
			if era>1200.0:expected=maxf(1200.0,expected)
			assert_float(earliest).override_failure_message(id).is_equal_approx(expected,0.001)
		else:
			assert_float(earliest).override_failure_message(id).is_greater_equal(1200.0)
	# Entries dated 600-1200 but not designed by the new block stay behind year 600.
	assert_int(between).is_greater(0)
	# Undated entries outside every registry wait for the latest window's end.
	assert_float(Catalog.earliest_year({"id":"zz_undated_probe"},300.0,false)).is_equal(1200.0)
	assert_float(Catalog.earliest_year({"id":"zz_dated_probe"},700.0,true)).is_equal(630.0)
	assert_float(Catalog.earliest_year({"id":"zz_dated_probe"},1300.0,true)).is_equal(1200.0)
	# The design items of the new block open at their own band, not at the window.
	assert_float(DiscoverySystem.research_600_earliest_year(_entry("fx_bloom_hearths"))).is_equal(640.0)
	GameState.known_discoveries.assign(["copper_smelting"])
	assert_bool(DiscoverySystem.research_600_open(_entry("fx_bloom_hearths"),{},int(ceil(639.0*365.0)))).is_false()
	assert_bool(DiscoverySystem.research_600_open(_entry("fx_bloom_hearths"),{},int(ceil(640.0*365.0)))).is_true()
	GameState.elapsed_days=int(ceil(640.0*365.0))
	assert_bool(DiscoverySystem._discovery_is_eligible(_entry("fx_bloom_hearths"),int(ceil(640.0*365.0)))).is_true()

func test_the_first_block_alone_restores_the_600_window()->void:
	_use(FIXTURE)
	_use(FIRST_ONLY)
	assert_float(Catalog.window_end_year()).is_equal(600.0)
	assert_bool(Catalog.has("fx_bloom_hearths")).is_false()
	assert_bool(_entry("fx_bloom_hearths").is_empty()).is_true()
	assert_float(Catalog.earliest_year({"id":"zz_undated_probe"},300.0,false)).is_equal(600.0)
	assert_float(Catalog.earliest_year({"id":"zz_dated_probe"},640.0,true)).is_equal(600.0)
	assert_float(DiscoverySystem.research_600_earliest_year(_entry("bloomery_smelting"))).is_greater_equal(660.0)

func test_restoring_the_game_manifest_restores_every_block()->void:
	_use(FIXTURE)
	_use("")
	assert_array(Catalog.blocks()).is_equal(["y0_600","y600_1200","y1200_1800","y1800_2400"])
	assert_float(Catalog.window_end_year()).is_equal(2400.0)
	assert_bool(Catalog.has("fx_bloom_hearths")).is_false()
	assert_bool(_entry("fx_bloom_hearths").is_empty()).is_true()
	# The real block designs bloomery smelting again, not the fixture's hearths.
	assert_str(Catalog.block_of("bloomery_smelting")).is_equal("y600_1200")
	assert_array(_entry("bloomery_smelting").requires_all).is_equal(["shaft_furnaces","clay_tuyere_draft"])
	assert_float(DiscoverySystem.research_600_earliest_year(_entry("bloomery_smelting"))).is_equal(660.0)
