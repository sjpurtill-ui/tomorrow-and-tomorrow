## Terrain-derived landmark features. classify() reads a ground survey from
## the rendered heightfield (the same authority the renderer draws) and names
## the CLASS of ground a scout party is standing on; entries_for_class() then
## offers the named features that class can plausibly contain. A landmark's
## feature_id doubles as its future illustration filename:
## assets/textures/landmarks/<feature_id>.png
##
## Every myth line is written to be read aloud when the player clicks the
## landmark: the mythic explanation the naming party told around the fire.

# Thresholds are calibrated against the live height field (see
# tests/landmark_classification_probe.gd): heights run roughly -3..8 world
# units with 1 unit ≈ 1 km horizontally.
static func classify(survey:Dictionary)->String:
	if survey.is_empty(): return ""
	var biome:=String(survey.get("biome",""))
	if biome=="water": return ""
	var slope:=float(survey.get("slope",0.0))
	var relief:=float(survey.get("relief",0.0))
	var height:=float(survey.get("height",0.0))
	var river:=float(survey.get("river_distance_km",INF))
	var woodland:=float(survey.get("woodland",0.0))
	var precipitation:=float(survey.get("precipitation",0.5))
	if bool(survey.get("coastal",false)): return "coast"
	if slope>=0.50: return "cliffs"
	if height>6.0: return "summit"
	if precipitation>0.68 and relief<=-0.06 and biome!="wetland": return "springs"
	if relief<=-0.15: return "vale" if woodland>=0.30 or precipitation>=0.55 else "hollow"
	if river<3.2 and height<3.0: return "river"
	if biome=="wetland": return "wetland"
	if woodland>0.42 or biome=="woodland": return "grove"
	if biome=="steppe": return "dryland"
	if biome=="tundra": return "cold"
	if height>3.2 or relief>=0.12: return "ridge"
	return "plain"


static func entries_for_class(feature_class:String)->Array:
	return FEATURES.get(feature_class,FEATURES["plain"]) as Array


## Picks a feature for the surveyed ground. Names containing %s take an
## adjective; fixed names stand alone. Returns {} for unnameable ground.
static func pick(survey:Dictionary,rng:RandomNumberGenerator,adjective:String,taken_names:Array)->Dictionary:
	var feature_class:=classify(survey)
	if feature_class=="": return {}
	var pool:Array=entries_for_class(feature_class)
	for _attempt in 6:
		var entry:Dictionary=pool[rng.randi_range(0,pool.size()-1)]
		var template:=String(entry.name)
		var landmark_name:=template % adjective if "%s" in template else template
		if landmark_name in taken_names: continue
		return {"feature_id":String(entry.id),"class":feature_class,"name":landmark_name,"description":String(entry.description),"myth":String(entry.myth)}
	return {}


const FEATURES:Dictionary={
"cliffs":[
	{"id":"scarp_wall","name":"The %s Scarp","description":"A sheer broken face of layered rock the party steered by for days.","myth":"They say the world was once a single page, and here a god folded it too quickly."},
	{"id":"organ_pipes","name":"The %s Pipes","description":"Columns of fractured stone standing in ranks like enormous flutes.","myth":"When the wind runs from the north the cliff sings, and the old people say it is practicing a name it has not yet been given."},
	{"id":"falcon_ledges","name":"The %s Ledges","description":"Stepped shelves of bare rock streaked white by nesting birds.","myth":"Each ledge is said to hold one year of the mountain's memory; the birds nest there to keep the years warm."},
	{"id":"weeping_face","name":"The Weeping Face","description":"A dark cliff seeping water down its whole height even in dry months.","myth":"The rock mourns a river that once ran above it; the tears are all that remain of the old channel."},
	{"id":"broken_stair","name":"The %s Stair","description":"Collapsed rock terraces that descend the scarp like ruined steps.","myth":"Giants cut a stairway to reach the low country, then broke it behind them so nothing could follow."},
	{"id":"red_seam","name":"The %s Seam","description":"A band of rust-colored stone running level through the grey face.","myth":"A wound in the world's side, cauterized by the first sunrise and never fully healed."},
	{"id":"echo_wall","name":"The Echo Wall","description":"A concave cliff that returns a shout three times, each fainter.","myth":"The wall keeps every word said before it and returns only the ones it has grown tired of."},
	{"id":"hanging_gate","name":"The Hanging Gate","description":"Two leaning pillars of rock framing a gap high in the cliff line.","myth":"The dead were once carried through the gap so their shadows could not find the way back."},
	{"id":"honeycomb_bluff","name":"The %s Honeycombs","description":"A soft cliff riddled with wind-carved pockets and hollows.","myth":"Swarms of stone bees are said to sleep in the holes, waiting for a summer long enough to wake them."},
	{"id":"anvil_head","name":"The %s Anvil","description":"A flat-topped promontory of dark rock jutting from the scarp.","myth":"On this anvil the thunder is forged; the smell of struck iron comes before every storm."},
	{"id":"skull_brow","name":"The %s Brow","description":"An overhanging shelf that shadows the ground beneath all day.","myth":"The hill is the head of a buried watcher, and this is the brow above its unopened eye."},
	{"id":"split_tower","name":"The Split Tower","description":"A freestanding rock spire cracked cleanly from crown to base.","myth":"Two brothers quarreled over who would carry the sky, and the tower could not choose between them."},
	{"id":"tidefall_face","name":"The %s Face","description":"A cliff whose strata ripple like frozen water.","myth":"A wave from the world's first sea stands here, stopped mid-break by a word no one remembers."},
	{"id":"lantern_hollows","name":"The Lantern Hollows","description":"Shallow caves in the cliff that catch low sun and glow at dusk.","myth":"Lights kindle in the rock for travelers who deserve them; the party did not say whether theirs was lit."},
	{"id":"grinding_edge","name":"The %s Edge","description":"A knife-thin rim of rock where the plateau shears away.","myth":"The world sharpens itself here, and what it is preparing to cut has not yet arrived."},
],
"ridge":[
	{"id":"long_spine","name":"The %s Spine","description":"A bare ridgeline visible for a full day's walk in open country.","myth":"The backbone of a beast that lay down before the first winter and has not yet decided to rise."},
	{"id":"watchers_row","name":"The Watchers' Row","description":"A crest studded with upright boulders in a rough line.","myth":"Sentries of an older people, turned to stone at their posts and still counted loyal."},
	{"id":"wind_keel","name":"The %s Keel","description":"A narrow ridge polished by constant wind, bare of all soil.","myth":"The upturned hull of the boat that carried the land itself across the original waters."},
	{"id":"saddle_pass","name":"The %s Saddle","description":"A low dip in the ridgeline that funnels every traveler through it.","myth":"Whoever crosses the saddle is briefly weighed; the mountain keeps no record but never forgets."},
	{"id":"cinder_crest","name":"The %s Crest","description":"A ridge of dark shattered stone warm to the touch at midday.","myth":"Embers of the sky's first fire were raked into a line here to dry the new-made world."},
	{"id":"three_sisters","name":"The Three Sisters","description":"Three matched knolls rising evenly along one crest.","myth":"Three sisters who refused to be parted were granted their wish more literally than they hoped."},
	{"id":"serpent_back","name":"The %s Serpent","description":"A sinuous ridge that doubles back on itself twice.","myth":"A serpent so long it starved chasing its own tail; the land grew over it out of respect."},
	{"id":"banner_heights","name":"The %s Heights","description":"A high shoulder where cloud streams off the crest like cloth.","myth":"The sky pins its banners here when it musters for storms."},
	{"id":"whetstone_ridge","name":"The Whetstone","description":"A long ridge of fine grey stone that takes a sharp edge.","myth":"Heroes were sent to sharpen their oaths, not their blades, against this stone."},
	{"id":"old_wall","name":"The Old Wall","description":"A ridgeline so straight and even it looks deliberately built.","myth":"The boundary of a kingdom that fell so completely only its fence remains."},
	{"id":"stormworn_crown","name":"The %s Crown","description":"A rounded summit ringed by lightning-scarred outcrops.","myth":"A crown set down by a king who understood, too late, what it cost to wear."},
	{"id":"marching_hogback","name":"The %s Hogback","description":"A steep-sided ridge running dead level for many miles.","myth":"An army that marched in perfect step for so long the ground learned the rhythm and kept it."},
	{"id":"harp_ridge","name":"The %s Harp","description":"Parallel rock ribs down the ridge flank, evenly spaced.","myth":"The wind's own instrument; it plays only on nights when no one is listening on purpose."},
	{"id":"bone_comb","name":"The Bone Comb","description":"A crest of pale weathered pinnacles in a tight row.","myth":"The comb of the giantess who braided the rivers; she will return for it when her hair grows back."},
	{"id":"beacon_brow","name":"The %s Beacon","description":"An isolated high point commanding every approach.","myth":"A fire lit here is said to be seen not just far away, but long ago."},
],
"summit":[
	{"id":"sky_altar","name":"The %s Altar","description":"A flat summit plate of frost-split rock above all nearby ground.","myth":"The table where the sky eats; climbers leave nothing, and take nothing, and are counted polite."},
	{"id":"cold_throne","name":"The Cold Throne","description":"A summit block shaped like an enormous weathered seat.","myth":"Reserved for the winter itself, which sits here to survey what it will keep."},
	{"id":"cloud_anchor","name":"The %s Anchor","description":"A peak that holds a standing cap of cloud in clear weather.","myth":"The last mooring of the sky; if the cloud ever slips loose, the sky will drift out to sea."},
	{"id":"first_light_horn","name":"The %s Horn","description":"A sharp summit that catches dawn before the land below wakes.","myth":"The horn is sounded by sunlight alone; the day does not begin until it has been struck."},
	{"id":"star_quarry","name":"The Star Quarry","description":"A summit crater strewn with glassy black stones.","myth":"Fallen stars were mined here by hands that needed light more than we do."},
	{"id":"silence_top","name":"The %s Silence","description":"A high dome where wind stops strangely at the crest.","myth":"The mountain holds its breath at the top; no one has stayed long enough to hear it exhale."},
	{"id":"snow_library","name":"The Snow Library","description":"Layered ice fields banded like stacked pale pages.","myth":"Every winter writes one page; the party could not read the script but felt strongly it was about them."},
	{"id":"eagle_gate","name":"The %s Gate","description":"Twin summit pinnacles that frame the pass between them.","myth":"Only things carried by wings or by grief pass between the pillars unchallenged."},
	{"id":"thunder_nest","name":"The Thunder Nest","description":"A ring of shattered rock at the very peak, scorched in places.","myth":"Thunder is hatched here, blind and loud, and pushed from the nest to learn to strike."},
	{"id":"grey_pilgrim","name":"The Grey Pilgrim","description":"A lone summit tor visible from every direction.","myth":"A pilgrim who reached the top and saw the destination was behind him all along; he is still deciding."},
	{"id":"worlds_tooth","name":"The %s Tooth","description":"A steep pyramid of bare rock rising past the treeline.","myth":"The world keeps one tooth to remember being young and hungry."},
	{"id":"lantern_peak","name":"The %s Lantern","description":"A pale summit that holds alpenglow long after sunset.","myth":"A lamp trimmed by unseen hands so the dead can find the way down the far side."},
	{"id":"frost_forge","name":"The Frost Forge","description":"A summit basin where ice stands in worked, angular blocks.","myth":"Winter's smithy; the hammering is heard in the joints of old scouts before every storm."},
	{"id":"hushed_choir","name":"The Hushed Choir","description":"A crown of standing pinnacles around a snow-filled bowl.","myth":"Singers who climbed to be heard by the sky, granted an audience, and never needed words again."},
	{"id":"keystone_dome","name":"The %s Keystone","description":"A massive rounded cap of unbroken stone at the range's height.","myth":"The stone that locks the arches of the earth; pity whoever is sent to fetch it."},
],
"hollow":[
	{"id":"mist_bowl","name":"The %s Bowl","description":"A broad depression that gathers mist each morning.","myth":"The land's own cup; each dawn it is filled, and each day something unseen drinks."},
	{"id":"sunken_court","name":"The Sunken Court","description":"A flat-floored hollow ringed by low banks.","myth":"Judgments were once passed here by a court that sank rather than err; petitioners still whisper down."},
	{"id":"sleepers_dell","name":"The Sleeper's Dell","description":"A sheltered hollow of unusual stillness and deep grass.","myth":"Something kind sleeps beneath it; the grass grows thick so footsteps will not wake it."},
	{"id":"echo_kettle","name":"The %s Kettle","description":"A steep round pit where sound circles before fading.","myth":"A word dropped in the kettle boils slowly for years and returns to its speaker as weather."},
	{"id":"salt_pan_hollow","name":"The %s Pan","description":"A shallow basin crusted white at its center in dry months.","myth":"A sea that overslept and was left behind by the tide; it dreams in salt."},
	{"id":"drowned_orchard","name":"The Drowned Orchard","description":"A hollow of dead standing trunks in seasonal standing water.","myth":"An orchard that loved its reflection too much; both are still there, holding hands."},
	{"id":"low_lantern","name":"The %s Lantern","description":"A depression that holds evening light after nearby ground darkens.","myth":"The sun leaves one coin of light here nightly as toll for crossing the sky unbothered."},
	{"id":"breath_pit","name":"The Breathing Pit","description":"A hollow with a faint updraft warmer than the evening air.","myth":"The earth breathes through it; hold a feather over the mouth and learn whether the earth slept well."},
	{"id":"hares_amphitheater","name":"The Hares' Theater","description":"Tiered natural banks around a small green floor.","myth":"On certain moons the hares convene here; their business is their own, but it is clearly parliamentary."},
	{"id":"shadow_pocket","name":"The %s Pocket","description":"A north-cut hollow where frost persists into late spring.","myth":"Winter's coin purse, where it keeps a little cold against a bad summer."},
	{"id":"kneeling_ground","name":"The Kneeling Ground","description":"A hollow where all surrounding slopes incline gently inward.","myth":"The hills knelt here once, to something worth kneeling to, and never quite straightened."},
	{"id":"still_bowl","name":"The %s Still","description":"A windless basin where smoke rises perfectly straight.","myth":"The air of the first calm morning was stored here and is opened only briefly for emergencies."},
	{"id":"antler_hollow","name":"The Antler Hollow","description":"A dell floor scattered with years of shed antlers.","myth":"Stags pay their crowns to the ground here in exchange for another year of being uncatchable."},
	{"id":"quiet_larder","name":"The %s Larder","description":"A cool deep-soiled hollow dense with roots and burrows.","myth":"The generous cellar of a spirit who feeds anything small enough to knock at the right door."},
	{"id":"buried_bell","name":"The Buried Bell","description":"A round hollow that hums faintly in strong wind.","myth":"A bell buried to silence bad news; it rings only under the ground, and only when the news comes true."},
],
"vale":[
	{"id":"green_hall","name":"The %s Hall","description":"A sheltered valley roofed by leaning trees on both slopes.","myth":"The hall of a hospitality older than houses; guests are safe, provided they praise the cooking of rain."},
	{"id":"honey_combe","name":"The %s Combe","description":"A steep-sided fertile valley loud with bees all summer.","myth":"The valley keeps summer folded in its floor and shares it by the spoonful."},
	{"id":"cradle_vale","name":"The Cradle","description":"A deep even valley of soft ground and gentle water.","myth":"The land's firstborn was rocked here; the sides still curve to fit something dearly held."},
	{"id":"singing_bottoms","name":"The Singing Bottoms","description":"A valley floor of tall grasses that hiss and chord in wind.","myth":"A choir that pledged to sing until the drought ended; the drought ended, but they had grown to like it."},
	{"id":"orchard_slip","name":"The %s Slip","description":"A narrow vale thick with wild fruit trees.","myth":"Seeds spilled from the sack of a traveler who was never hungry again and never learned why."},
	{"id":"lambs_run","name":"The Lambs' Run","description":"A long grassy vale between two guardian ridges.","myth":"The hills stand watch as shepherds here; the wolves know it and grieve about it privately."},
	{"id":"fiddlers_glen","name":"The %s Glen","description":"A wooded valley where a stream steps down small terraces.","myth":"A fiddler challenged the stream to a reel and lost graciously; the stream still plays his part and its own."},
	{"id":"mirror_reach","name":"The Mirror Reach","description":"A still valley pool that holds the sky perfectly at dawn.","myth":"Here the sky checks its face; mornings are clear when it is pleased with what it sees."},
	{"id":"velvet_gap","name":"The %s Gap","description":"A moss-floored vale where sound falls strangely soft.","myth":"The valley swallowed a war whole and has been quietly digesting it for a thousand years."},
	{"id":"heartwood_dale","name":"The Heartwood Dale","description":"A deep dale sheltering trees far older than the slopes' forest.","myth":"When the first forest retreated, it left its heart here for safekeeping, and it still beats in ring after ring."},
	{"id":"ribbon_meads","name":"The %s Meads","description":"Flower meadows braided by a slow clear stream.","myth":"A ribbon dropped from the hair of the dawn; no one has been quick enough at sunrise to return it."},
	{"id":"foxglove_furrow","name":"The %s Furrow","description":"A straight vale as even as a plowed line.","myth":"One furrow of the field the gods began and abandoned; what they meant to sow is a popular argument."},
	{"id":"harvest_hold","name":"The Harvest Hold","description":"A wide vale of deep dark soil, sheltered from every wind.","myth":"The valley hoards ripeness as misers hoard coin, but unlike them it loves to be robbed."},
	{"id":"swallowtail_vale","name":"The %s Vale","description":"A forked green valley that splits around a wooded knoll.","myth":"The valley is the tail of a buried swallow whose return flight will announce the world's best spring."},
	{"id":"lantern_bottom","name":"The Firefly Bottom","description":"A humid valley floor thick with fireflies at midsummer.","myth":"Sparks from the first hearth escaped downhill and settled here; they still practice being stars."},
],
"river":[
	{"id":"stone_ford","name":"The %s Ford","description":"A reliable shallow crossing over clean gravel.","myth":"The river agreed to kneel here, once a day, forever, to settle a debt it will not discuss."},
	{"id":"otter_gate","name":"The Otter Gate","description":"A narrow channel between boulders where the current runs glassy.","myth":"Tribute of one fish is owed to the otters at the gate; the ferryman who refused is now a heron."},
	{"id":"braided_shallows","name":"The %s Braids","description":"The river splits into shifting gravel channels here.","myth":"Two rivers who loved the same valley agreed to take turns; they have never once kept the schedule."},
	{"id":"drum_rapids","name":"The %s Drums","description":"Rapids over hollow-sounding rock ledges.","myth":"The river's drummers, who beat the rhythm the water has marched to since it left the mountain."},
	{"id":"kingfisher_bend","name":"The Kingfisher Bend","description":"A deep slow meander under an undercut bank.","myth":"The river paused here to admire a kingfisher and never fully regained its pace."},
	{"id":"salmon_stair","name":"The %s Stair","description":"Low rock steps the migrating fish leap in sequence.","myth":"A staircase cut for the fish by a giant who lost a bet to them and paid honestly."},
	{"id":"whispering_eyot","name":"The Whispering Eyot","description":"A willow-grown island parting the current.","myth":"An island that overhears everything the river carries and repeats it only to willows."},
	{"id":"copper_shoals","name":"The %s Shoals","description":"Shallows over sand that glitters faintly at noon.","myth":"A drowned king's ransom, paid to the river to release him; the river kept both."},
	{"id":"old_ferry_reach","name":"The Old Ferry Reach","description":"A straight calm reach between high banks.","myth":"A ferry crossed here long before boats; what it carried and in what direction is not asked twice."},
	{"id":"loomwater","name":"The %s Loom","description":"Interleaving currents that weave visible seams downstream.","myth":"The river weaves its own shroud endlessly, unpicking it each night out of good sense."},
	{"id":"heron_court","name":"The Heron Court","description":"Broad shallows where herons stand spaced like sentries.","myth":"The river's magistrates; they hear the water's disputes all day and swallow the evidence."},
	{"id":"thundershoot","name":"The %s Shoot","description":"A short violent chute between smooth rock walls.","myth":"Here the river remembers being young, briefly and at the top of its voice."},
	{"id":"meander_scar","name":"The %s Oxbow","description":"A crescent of still water left by the river's old course.","myth":"The river shed this bend as a snake sheds skin; the abandoned water is still owed a visit."},
	{"id":"gravel_forge","name":"The Gravel Forge","description":"A noisy riffle that rounds and polishes its stones.","myth":"Apprentice stones are finished here before being placed in the world; the rejects pave the ford."},
	{"id":"nightwater_ford","name":"The Nightwater Ford","description":"A wide crossing where the river runs warm after dark.","myth":"The moon fords the river here on cloudy nights, and the water keeps the warmth of her feet."},
],
"wetland":[
	{"id":"reed_parliament","name":"The Reed Parliament","description":"A vast reedbed roaring with birds at dusk.","myth":"All the marsh's factions assemble at dusk; nothing is ever resolved, which is why the marsh endures."},
	{"id":"lantern_mire","name":"The %s Mire","description":"A peat bog where pale lights drift on humid nights.","myth":"Lanterns of the patient dead, who are not lost and would like visitors to stop assuming so."},
	{"id":"sunken_meadow","name":"The Sunken Meadow","description":"Grassland flooded to a hand's depth most of the year.","myth":"A meadow that chose the frogs over the sheep and has never regretted it audibly."},
	{"id":"black_tarn","name":"The %s Tarn","description":"A cold peat-dark pool of unmeasured depth.","myth":"The marsh's one closed eye; what it watches with the open one is the whole rest of the sky."},
	{"id":"cranes_wading","name":"The Cranes' Wading","description":"Open shallows crossed by generations of crane tracks.","myth":"Cranes taught patience to the water here; the lesson took, which is why the marsh never leaves."},
	{"id":"quaking_lawn","name":"The %s Lawn","description":"A floating mat of moss that trembles underfoot.","myth":"The marsh's drumskin; walk gently, for whatever it summons answers footsteps in kind."},
	{"id":"eel_weir","name":"The Old Eel Weir","description":"Drowned wattle rows from fishers no memory names.","myth":"Built by folk who traded their names to the eels for full traps; both sides kept the bargain."},
	{"id":"mistwrack","name":"The %s Wrack","description":"Fog banks that snag in dead standing timber.","myth":"Wrecked fog, driven aground; the trees are masts of a fleet that sailed too low."},
	{"id":"bittern_hush","name":"The Bittern's Hush","description":"A silent pool where a booming call sounds at dawn.","myth":"The marsh's herald, announcing each day to an authority who has never once replied."},
	{"id":"iris_shallows","name":"The %s Shallows","description":"Flag iris blooming across drowned ground each spring.","myth":"Swords of a marsh-drowned army flowering into something with better judgment."},
	{"id":"tussock_maze","name":"The Tussock Maze","description":"Sedge mounds in standing water, pathless and repeating.","myth":"The marsh rearranges the maze nightly, not from malice but because it dislikes being memorized."},
	{"id":"otterholt_fen","name":"The %s Fen","description":"A rich fen veined with clear channels and otter slides.","myth":"Dug in one joyful night by otters, as their side of a bargain nobody else remembers making."},
	{"id":"drowned_bell_pool","name":"The Drowned Bell Pool","description":"A round pool that rings faintly when rain begins.","myth":"A chapel sank here rather than change its faith; the bell keeps its own services now."},
	{"id":"marsh_kings_table","name":"The Marsh King's Table","description":"A single dry islet of firm ground deep in the wetland.","myth":"The only guest-right in the marsh: whoever reaches the table may eat and leave unfollowed, once."},
	{"id":"willow_wake","name":"The %s Wake","description":"A procession of ancient willows along a buried channel.","myth":"Mourners at the funeral of a river; they planted themselves rather than go home after."},
],
"springs":[
	{"id":"warm_mouths","name":"The Warm Mouths","description":"Water rising warm from several vents year-round.","myth":"The earth speaks here in its sleep, warmly and in an old dialect of steam."},
	{"id":"maidens_well","name":"The %s Well","description":"A clear pool welling silently from white gravel.","myth":"A well that grants exactly what is asked, which is why the wise ask it for nothing."},
	{"id":"iron_bloom_spring","name":"The %s Bloom","description":"A spring staining its channel rust-orange.","myth":"The earth's blood, shed slowly and without complaint, for a wound it considers worth it."},
	{"id":"seven_sisters_seep","name":"The Seven Seeps","description":"Seven small springs feeding one bright rill.","myth":"Seven sisters who wept at one parting; their tears agreed to travel on together."},
	{"id":"prophets_basin","name":"The %s Basin","description":"A spring pool that never clouds, even in flood.","myth":"Water that shows the looker not the future but the one thing they are avoiding, which is worse."},
	{"id":"steam_garden","name":"The Steam Garden","description":"Warm ground and vents amid unusually lush growth.","myth":"The winter is bribed here annually with flowers; it takes the bribe and pretends not to."},
	{"id":"stone_cup","name":"The Stone Cup","description":"A spring rising through a natural bowl of worn rock.","myth":"The cup of a shrine older than thirst; drink kneeling and the water counts you a friend."},
	{"id":"night_singer_spring","name":"The %s Singer","description":"A spring whose flow chimes audibly after dark.","myth":"It sings the water down from inside the hill, one note per drop, and has never missed one."},
	{"id":"healers_steam","name":"The Healer's Steam","description":"Hot seeps whose mists ease joint pain, scouts claim.","myth":"The breath of a buried physician who still keeps rounds, gentle and unlicensed."},
	{"id":"mirror_seep","name":"The %s Mirror","description":"A film of spring water over black rock, bright as glass.","myth":"The earth's own looking-glass; it checks itself rarely, and mostly the sky uses it uninvited."},
	{"id":"bubbling_court","name":"The Bubbling Court","description":"A cluster of cold springs that pulse in turn.","myth":"An underground parliament voting eternally; each bubble a motion, none ever carried."},
	{"id":"first_water","name":"The First Water","description":"A powerful spring that heads the local stream.","myth":"Where the river is born daily; it emerges knowing everything and forgets it all by the first bend."},
	{"id":"sweetwater_gate","name":"The %s Gate","description":"Twin springs flanking a natural rock doorway.","myth":"Guests of the hill wash at both doors, once for arriving and once for the person they arrive as."},
	{"id":"winter_kettle","name":"The Winter Kettle","description":"A steaming pool that keeps its clearing green in snow.","myth":"Winter's own kitchen; even the cold must eat, and it is politely never asked what."},
	{"id":"weeping_stone_spring","name":"The Weeping Stone","description":"A boulder shedding a constant thread of spring water.","myth":"A stone that volunteered to do the world's crying so the rest could get on with things."},
],
"grove":[
	{"id":"elder_ring","name":"The %s Ring","description":"An old stand of trees in a near-perfect circle.","myth":"The trees joined hands for a dance the night time began, and dawn has never caught them finished."},
	{"id":"kings_copse","name":"The King's Copse","description":"A dense copse unlike the surrounding country.","myth":"Planted over a king's grave, one tree per unpaid promise; it is a large copse."},
	{"id":"lightning_oak_stand","name":"The %s Oaks","description":"Storm-scarred oaks that thrive despite repeated strikes.","myth":"Oaks that argue with the lightning as equals; the scars are the points they conceded."},
	{"id":"whisper_pines","name":"The Whisper Pines","description":"Pines that sound like low speech in any breeze.","myth":"They repeat everything said beneath them, a season late and to entirely the wrong audience."},
	{"id":"mast_hall","name":"The %s Hall","description":"Beech giants over open shade-bare ground.","myth":"The forest's feasting hall; the tables are laid each autumn and the guests wear bristles."},
	{"id":"crooked_sisters","name":"The Crooked Sisters","description":"Wind-bent trees all leaning the same way.","myth":"Sisters who leaned to hear a secret the wind was telling; it has not finished the sentence."},
	{"id":"honey_hollow_trees","name":"The %s Hives","description":"Ancient hollow trunks loud with wild bees.","myth":"The forest's treasury; its gold is audited hourly by ten thousand very serious clerks."},
	{"id":"deer_church","name":"The Deer Church","description":"A vaulted glade where deer gather at dusk.","myth":"The deer keep an observance older than altars; the sermon is silence and attendance is excellent."},
	{"id":"lantern_birches","name":"The %s Birches","description":"White birches that stay bright in failing light.","myth":"Candles of the forest, lit for whichever traveler is most lost; they cannot all be for the party."},
	{"id":"gallows_yew","name":"The Old Yew","description":"One vast dark yew centuries older than the wood around it.","myth":"The tree remembers being alone before the forest came; it forgives the forest, mostly."},
	{"id":"nutwood_maze","name":"The %s Maze","description":"Hazel thickets in winding natural corridors.","myth":"The squirrels' great work, grown rather than built, and navigable only by the forgetful."},
	{"id":"green_chapel","name":"The Green Chapel","description":"A moss-floored clearing walled by holly.","myth":"A chapel that consecrated itself when no one arrived to do it properly; it holds that against nobody."},
	{"id":"wolf_nursery","name":"The %s Thicket","description":"Impassable blackthorn sheltering old den mounds.","myth":"The forest's nursery; thorns face outward for reasons any parent understands."},
	{"id":"singing_aspens","name":"The Singing Aspens","description":"An aspen stand that shimmers audibly in still air.","myth":"Leaves that applaud the light; on windless days they practice quietly, from memory."},
	{"id":"rootgate","name":"The %s Rootgate","description":"Two fused trees arching over the path.","myth":"Passing under trades one small sorrow for one small errand; the exchange rate is considered fair."},
],
"dryland":[
	{"id":"standing_herd","name":"The Standing Herd","description":"Scattered boulders across dry grass like grazing beasts.","myth":"A herd that would not move for the drought was granted permission to stop forever."},
	{"id":"dust_choir","name":"The %s Choir","description":"Wind-fluted rocks that moan in dry gales.","myth":"Voices that sang the rain here once and are practicing for an encore no cloud has yet booked."},
	{"id":"cracked_pan","name":"The %s Pan","description":"A hard clay flat crazed into vast tiles.","myth":"The floor of heaven's kiln, where the sun still fires its pots each noon."},
	{"id":"thorn_banner","name":"The Thorn Banner","description":"One huge thorn tree alone on open steppe.","myth":"The flag of a country whose borders are wherever shade falls; population varies by hour."},
	{"id":"grass_sea_barrow","name":"The %s Barrow","description":"A single ancient mound in the grass sea.","myth":"An island raised for a drowned sailor buried a thousand miles from water, so he would not feel singled out."},
	{"id":"red_road","name":"The Red Road","description":"A band of ochre earth running straight to the horizon.","myth":"The path the sunset takes home when it is too tired to go around."},
	{"id":"whistling_gap","name":"The %s Gap","description":"A notch between low hills that whistles in season.","myth":"The steppe's doorbell; what it announces has excellent manners and has never yet come in."},
	{"id":"bone_orchard","name":"The Bone Orchard","description":"Bleached great-beast bones half-sunk in grass.","myth":"Seeds of animals yet to come, planted patiently by the ones before."},
	{"id":"mirage_terrace","name":"The %s Terrace","description":"Low benches of rock that shimmer falsely with water.","myth":"The ghost of a lake keeps its old shoreline out of habit and hospitality."},
	{"id":"wind_mane","name":"The Wind's Mane","description":"Long dunes of pale grass combed all one way.","myth":"The steppe is a horse mid-gallop; the grass is its mane, and we live between two hoofbeats."},
	{"id":"sun_anvil","name":"The %s Anvil","description":"A dark rock pavement fiercely hot by midday.","myth":"Where summer is hammered out annually; the sparks are what we call cicadas."},
	{"id":"old_wells_row","name":"The Old Wells","description":"A line of dry hand-dug wells along no known road.","myth":"Dug by a people walking behind the rain; the wells mark where it was, never where it went."},
	{"id":"silver_sage_flat","name":"The %s Flats","description":"Aromatic silver scrub as far as sight runs.","myth":"The steppe's incense, burned green and standing, for a ceremony conducted entirely by wind."},
	{"id":"marmot_capital","name":"The Marmot Capital","description":"A city of burrow mounds and sentinel whistlers.","myth":"The oldest continuous government on the steppe; its laws are two, and both are about hawks."},
	{"id":"lightning_glass_reach","name":"The %s Glass","description":"Fused sand tubes scattered over a storm-struck flat.","myth":"The sky writes its name here in glass when it wants the steppe to remember who is taller."},
],
"cold":[
	{"id":"frost_fleet","name":"The Frost Fleet","description":"Wind-carved snowdrifts standing like sails.","myth":"Ships of the winter fleet, at anchor until the long ice comes to launch them."},
	{"id":"cairn_line","name":"The %s Cairns","description":"Old stone piles marching over the barrens.","myth":"Each cairn holds a traveler's coldest hour so they could walk on without it; add a stone, leave an hour."},
	{"id":"blue_pane","name":"The %s Pane","description":"A frozen melt-sheet of extraordinary clear blue ice.","myth":"A window the sky dropped; whatever looks up through it is patient and appreciates visitors standing still."},
	{"id":"reindeer_road","name":"The Reindeer Road","description":"A migration path worn to stone by hooves.","myth":"The herds follow the same dream each year; the road is where it touches the ground."},
	{"id":"howl_gate","name":"The %s Gate","description":"A col that funnels wind into a single sustained note.","myth":"The north keeps a hound at this gate; the note is not wind, it is patience."},
	{"id":"white_court","name":"The White Court","description":"Snow-mounded boulders in a ring on open tundra.","myth":"Winter's councilors, seated; matters are decided slowly, at a pace of one word per storm."},
	{"id":"embers_grave","name":"The Ember's Grave","description":"A black rock patch always free of snow.","myth":"The burial place of a fire that served faithfully; the ground keeps it warm in turn."},
	{"id":"aurora_stones","name":"The %s Stones","description":"Upright slabs aligned with the winter lights.","myth":"Needles that pin the aurora down on its wildest nights, so morning finds the sky where it was left."},
	{"id":"moss_banner_flat","name":"The %s Banners","description":"Vivid moss and lichen flats amid grey barrens.","myth":"The tundra's heraldry, flown at ankle height for an audience of the honest."},
	{"id":"silence_field","name":"The Silence Field","description":"A snowfield where sound dies within paces.","myth":"All the hushes ever hushed are stored here; the tundra lends them out for funerals and first snows."},
	{"id":"frost_giants_step","name":"The %s Step","description":"A single vast rectangular rock terrace.","myth":"One stair of a flight the frost giants dismantled behind them; the rest is weather now."},
	{"id":"ptarmigan_keep","name":"The Ptarmigan Keep","description":"Broken crags full of wintering birds.","myth":"The smallest garrison in the world holds this fort against the cold, and has never lost."},
	{"id":"breath_of_the_north","name":"The North's Breath","description":"A vent of fog rising from deep rock even at depth of winter.","myth":"Proof the north is a sleeping body, not a direction; the party declined to check further."},
	{"id":"sun_wheel_barrens","name":"The %s Wheel","description":"Frost-sorted stone rings patterning the barrens.","myth":"Wheels of the sun's winter cart, taken off and stored while it walks the low road."},
	{"id":"last_tree","name":"The Last Tree","description":"One stunted, ancient tree beyond all others.","myth":"The forest's ambassador to the ice, maintaining an embassy of one, with honors."},
],
"coast":[
	{"id":"gull_parliament_stack","name":"The %s Stack","description":"A sea-stack white with gulls off the headland.","myth":"The sea's tally-post; each gull a kept promise, which explains both the number and the noise."},
	{"id":"salt_gate","name":"The Salt Gate","description":"A natural rock arch over deep tidal water.","myth":"The door between drinkable and undrinkable; the sea and rain agreed on it and both respect it."},
	{"id":"wreck_comb","name":"The %s Comb","description":"Rows of black reef teeth exposed at low tide.","myth":"The sea grooms its drowned with this comb; sailors salute it from a sensible distance."},
	{"id":"singing_shingle","name":"The Singing Shingle","description":"A steep pebble beach that chimes as waves draw back.","myth":"The sea counting its change, coin by coin, and always suspecting the land of shortchanging it."},
	{"id":"seal_moot","name":"The Seal Moot","description":"Flat skerries crowded with hauled-out seals.","myth":"The seals hold court on land matters here, having jurisdiction over everything the tide touches twice."},
	{"id":"weepwater_cliff","name":"The %s Falls","description":"A stream leaping straight off the sea-cliff into surf.","myth":"A river that chose the short way to the sea out of love; the sea has never quite recovered."},
	{"id":"tide_clock_pool","name":"The Tide Clock","description":"A blowhole pool that spouts on the flood.","myth":"The coast's own clock; it keeps sea-time, which is exact and answers to no one."},
	{"id":"drift_king_strand","name":"The %s Strand","description":"A beach that collects unusual driftwood from far waters.","myth":"The sea returns borrowed things here, gradually, to whoever waits without asking."},
	{"id":"mother_of_storms_point","name":"The Storm Mother's Point","description":"A headland that splits weather visibly around it.","myth":"Storms are whelped in the deep and weaned at this point; the gales are the ones that will not leave home."},
	{"id":"glass_cove","name":"The %s Cove","description":"A sheltered cove of water clear to great depth.","myth":"The sea keeps one honest window; what admires you through it is best greeted with a nod."},
	{"id":"hermits_stair","name":"The Hermit's Stair","description":"Natural rock steps descending the cliff to a cave.","myth":"Cut by a hermit who went down to argue with the sea daily; records suggest the argument continues."},
	{"id":"foam_meadow","name":"The %s Meadow","description":"A reach where standing foam banks drift like sheep.","myth":"The sea's flock, put out to graze; shearing has been attempted once, by a fool, memorably."},
	{"id":"anchor_stone","name":"The Anchor Stone","description":"A huge pierced boulder alone above the tideline.","myth":"The land is a boat and this is its anchor; do not move it, however good the reason sounds at the time."},
	{"id":"whale_road_watch","name":"The %s Watch","description":"A high bluff where migrating whales pass close inshore.","myth":"The whales exchange news with the headland in passing; the headland tells the grass, and the grass tells no one."},
	{"id":"amber_wrack_line","name":"The Amber Line","description":"A strand where sea-amber beads the wrack after storms.","myth":"Tears of a pine forest the sea took long ago, returned a bead at a time as the debt is remembered."},
],
"plain":[
	{"id":"lark_rise_field","name":"The %s Rise","description":"A gentle swell of grass loud with skylarks.","myth":"The larks hold the deed to this air and re-proclaim it every dawn, in full, from memory."},
	{"id":"wandering_stone","name":"The Wandering Stone","description":"One glacial boulder alone on open grassland.","myth":"A stone on a pilgrimage too slow to observe; its resting places are holy for exactly as long as it rests."},
	{"id":"kestrel_common","name":"The %s Common","description":"Hunting grassland quartered by hovering kestrels.","myth":"The kestrels are the plain's readers; the grass is script, and windy days are difficult chapters."},
	{"id":"old_king_furrows","name":"The Old Furrows","description":"Faint ridge-lines of cultivation no memory claims.","myth":"Fields of the people before, still faintly combed; their harvest went with them, all but the pattern."},
	{"id":"sun_stone_row","name":"The %s Row","description":"Weathered standing stones no living people claim.","myth":"Guests who stayed past the end of a feast so good the ending never took; they are still politely waiting."},
	{"id":"fox_earth_knoll","name":"The Fox Knoll","description":"A low mound riddled with generations of fox earths.","myth":"The plain's counting-house; the foxes audit the hens of three horizons from here."},
	{"id":"midsummer_floor","name":"The Midsummer Floor","description":"A circle of finer, brighter grass in rougher ground.","myth":"Danced flat on the year's longest night by attendees the grass declines to describe."},
	{"id":"cloud_flock_downs","name":"The %s Downs","description":"Rolling grass under vast slow cloud shadows.","myth":"The clouds pasture their shadows here, and shepherd them home at dusk along the ridgeline."},
	{"id":"quail_hundred","name":"The Quail Hundred","description":"Rich grass parceled by invisible quail territories.","myth":"A hundred small kingdoms with excellent borders and terrible foreign policy, all of it in June."},
	{"id":"thistle_crown_field","name":"The %s Crown","description":"A ring of tall thistles on a slight rise.","myth":"The plain crowns itself each summer, purple and armed, having learned what happens to unarmed kings."},
	{"id":"dew_pond_green","name":"The Dew Pond","description":"A small round pond on high open grass, never dry.","myth":"Filled nightly by the dew on agreement; the pond's side of the bargain is to hold the moon steady."},
	{"id":"hare_gallops","name":"The %s Gallops","description":"A long level of turf beaten by racing hares.","myth":"Where March is run off annually; the hares race it out of the country and are champions every year."},
	{"id":"harvest_moon_balk","name":"The Moon Balk","description":"A pale unplowed line crossing the grassland.","myth":"The moon's right-of-way; nothing sown on it comes up, and nothing walking it at full moon casts one shadow."},
	{"id":"bee_orchid_bank","name":"The %s Bank","description":"A warm south bank starred with rare orchids.","myth":"Flowers that practice being bees; some year they will get it right, and honey will need renegotiating."},
	{"id":"plovers_keep","name":"The Plovers' Keep","description":"Open ground defended loudly by nesting plovers.","myth":"The plain's alarm was given to its smallest birds, on the sound reasoning that they would enjoy it most."},
],
}
