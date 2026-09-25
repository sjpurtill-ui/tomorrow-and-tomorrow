extends GdUnitTestSuite
## Player-facing words follow what the people know: carts wait for the wheel,
## saddles for the pack saddle, bullets for guns; an ore is named by its look
## until its metal is known; the air is felt until there is a thermometer.
const Voice:=preload("res://scripts/character_voice.gd")
const ResourceNames:=preload("res://scripts/resource_names.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Hud:=preload("res://scripts/hud/command_rail_hud.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(51515)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	Chronicle.pending_cards.clear()

func after_test()->void:
	Voice.knowledge_override.clear()

func test_carts_saddles_and_bullets_wait_for_their_discoveries()->void:
	var text:="A cartload of hides went by cart. Clay Sling Bullets and a pack saddle. Riders on horseback with guns."
	var early:=Voice.era_plain(text,[])
	assert_str(early).is_equal("A sledge-load of hides went by sledge. Clay Sling Stones and a pack frame. Runners on foot with fire-tubes.")
	assert_array(Voice.lexicon_hits(early,[])).is_empty()
	assert_str(Voice.era_plain(text,["wheel","saddles","riding","guns"])).is_equal(text)
	# A saddle quern is a grinding stone, and a potter's wheel is not a cart.
	assert_str(Voice.era_plain("grain on the saddle quern; wheel-thrown pots",[])).is_equal("grain on the saddle quern; wheel-thrown pots")

func test_wheel_words_open_with_the_real_wheel_discoveries()->void:
	Voice.knowledge_override["player"]=[]
	assert_str(Voice.era_plain_for("an ox cart","player")).is_equal("an ox sledge")
	Voice.knowledge_override["player"]=["solid_wheel_assembly"]
	assert_bool(Voice.era_tags("player").has("wheel")).is_true()
	assert_str(Voice.era_plain_for("an ox cart","player")).is_equal("an ox cart")
	Voice.knowledge_override["player"]=["pack_saddles"]
	var tags:=Voice.era_tags("player")
	assert_bool(tags.has("saddles") and not tags.has("riding")).is_true()
	assert_str(Voice.era_plain_for("Wooden Pack Saddles for the cavalry","player")).is_equal("Wooden Pack Saddles for the swift runners")

func test_the_chronicle_retells_what_the_people_cannot_name()->void:
	Voice.knowledge_override["player"]=[]
	for id in ["copper_outcrop_signs","ore_assaying","copper_smelting"]:GameState.known_discoveries.erase(id)
	var told:=Chronicle.record({"title":"The carts come home","text":"Two wagons of Copper Ore arrived.","tier":"notice"})
	assert_str(String(told.title)).is_equal("The sledges come home")
	assert_str(String(told.text)).is_equal("Two sledges of Green-stained Stone arrived.")

func test_ores_keep_their_look_until_the_metal_is_known()->void:
	assert_str(ResourceNames.label("Copper Ore",[])).is_equal("Green-stained Stone")
	assert_str(ResourceNames.label("Copper Ore",["copper_smelting"])).is_equal("Copper Ore")
	assert_str(ResourceNames.label("Iron Ore",["copper_smelting"])).is_equal("Heavy Red Stone")
	assert_str(ResourceNames.label("Iron Ore",["bloomery_smelting"])).is_equal("Iron Ore")
	assert_str(ResourceNames.label("Fiber Plants",[])).is_equal("Plant Fiber")
	assert_str(ResourceNames.plain("Prospectors locate Iron Ore",[])).is_equal("Prospectors locate Heavy Red Stone")
	GameState.known_discoveries.erase("copper_outcrop_signs");GameState.known_discoveries.erase("ore_assaying");GameState.known_discoveries.erase("copper_smelting")
	var card:=ExpeditionFindings.deposit_card({"resource":"Copper Ore","position":Vector3.ZERO,"id":"d1","quality":0.5},12)
	assert_str(String(card.title)+String(card.description)+String(card.consequence)).not_contains("copper")

func test_the_air_is_felt_until_a_thermometer()->void:
	assert_str(Hud.temperature_words(14.2,"↑",[])).is_equal("Mild ↑")
	assert_str(Hud.temperature_words(-12.0,"→",[])).is_equal("Bitter cold →")
	assert_str(Hud.temperature_words(40.0,"↓",[])).is_equal("Scorching ↓")
	assert_str(Hud.temperature_words(14.2,"↑",["precision_thermometry"])).is_equal("14°C ↑")
