extends RefCounted
## One row per land kit: what it is, what it does in battle, what it costs to
## make and to keep in the field, and how it is drawn. The combat simulator,
## the production lines and the supply lines all read these rows, so a musket
## is changed in one place. Unlock rules stay in
## military_unit_catalog.gd EQUIPMENT_GATES (the discovery each kit needs).
##
## Stats are per man, as the combat simulator has always used them: a crew
## kit concentrates its crew's firepower, so a field gun's attack is per
## gunner and a combat frame's is per supervisor (eight frames each).
##   family, gen   the kit's family and its order within it (retooling keeps
##                 more skill inside a family; newer generations replace older)
##   year          the game year the kit usually appears (its gate's year)
##   crew          men per set; below 1, one man runs several machines
##   crewless      share of battle losses that fall on machines, not men
##   supply        loads a day per set on the supply line besides the men's
##                 food (fodder, fuel, charge, spares); one load = one man's
##                 food for a day
##   glyph         the battle-plate and production icon (resource_icons.gd)
##   look          one line for artists: what the soldier or machine looks like
## Armor kits (shield, padded, lamellar, scale, mail, plate with spear) keep
## their rows in armor_equipment.gd; ARMOR_FAMILY below places them.

const ArmorKits:=preload("res://scripts/armor_equipment.gd")

const FAMILIES:={
	"hand":{"label":"Hand arms","order":0},
	"missile":{"label":"Missile arms","order":1},
	"protection":{"label":"Armour","order":2},
	"mount":{"label":"Mounts","order":3},
	"firearm":{"label":"Firearms","order":4},
	"crew":{"label":"Crew weapons","order":5},
	"guns":{"label":"Siege engines and guns","order":6},
	"vehicle":{"label":"Vehicles","order":7},
	"autonomous":{"label":"Drones and robots","order":8},
	"support":{"label":"Support kits","order":9}
}

const KITS:={
	# Hand arms.
	"improvised":{"name":"Improvised Arms","family":"hand","gen":0,"year":0,"attack":0.65,"defense":0.70,"armor":0.00,"penetration":0.10,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.0,"materials":{"Timber":0.35},"days":0.25,"delivery":0.8,"glyph":"club","look":"Digging stick, club or stone axe; no two alike."},
	"spear":{"name":"Spears","family":"hand","gen":1,"year":0,"attack":1.00,"defense":1.18,"armor":0.05,"penetration":0.55,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.0,"materials":{"Timber":0.65,"Stone":0.10},"days":0.55,"delivery":1.0,"glyph":"spear","look":"Ash shaft, flint or fire-hardened point; hide wrap."},
	"axe":{"name":"Bronze Axes","family":"hand","gen":2,"year":400,"attack":1.22,"defense":0.92,"armor":0.05,"penetration":0.80,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.0,"materials":{"Timber":0.40,"Copper Ore":0.40,"Tin Ore":0.06},"days":1.00,"delivery":1.4,"glyph":"axe","look":"Socketed bronze axe, small wicker shield, linen kilt."},
	"sword_shield":{"name":"Sword & Shield","family":"hand","gen":3,"year":400,"attack":1.12,"defense":1.22,"armor":0.38,"penetration":0.42,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.0,"materials":{"Timber":0.50,"Copper Ore":0.50,"Tin Ore":0.08},"days":1.60,"delivery":1.8,"glyph":"sword","look":"Short bronze or iron blade, big round or oblong shield with a painted rim."},
	"pike":{"name":"Pikes","family":"hand","gen":4,"year":878,"attack":1.00,"defense":1.45,"armor":0.05,"penetration":0.75,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.0,"materials":{"Timber":1.10,"Iron Ore":0.25},"days":0.90,"delivery":1.6,"glyph":"pike","look":"Five-metre ash pike, steel head, open helmet; packed in a square block."},
	# Missile arms.
	"sling":{"name":"Slings","family":"missile","gen":0,"year":0,"attack":0.95,"defense":0.70,"armor":0.00,"penetration":0.30,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.0,"materials":{"Fiber Plants":0.30,"Stone":0.20},"days":0.30,"delivery":0.6,"glyph":"sling","look":"Braided cord sling and a pouch of river stones."},
	"bow":{"name":"Bows","family":"missile","gen":1,"year":0,"attack":1.18,"defense":0.70,"armor":0.00,"penetration":0.35,"crew":1.0,"crewless":0.0,"ammo":"arrows","ammo_per":6,"supply":0.05,"materials":{"Timber":0.45,"Fiber Plants":0.30},"days":0.80,"delivery":0.8,"glyph":"bow","look":"Self bow of one stave, quiver of reed arrows."},
	"javelin":{"name":"Javelins","family":"missile","gen":1,"year":0,"attack":1.10,"defense":0.80,"armor":0.00,"penetration":0.55,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.0,"materials":{"Timber":0.70,"Stone":0.10},"days":0.50,"delivery":1.0,"glyph":"javelin","look":"Three light throwing spears and a small hide shield."},
	"mounted_bow":{"name":"Horse Bows","family":"missile","gen":2,"year":722,"attack":1.30,"defense":0.80,"armor":0.05,"penetration":0.50,"crew":1.0,"crewless":0.0,"ammo":"arrows","ammo_per":24,"supply":5.0,"materials":{"Timber":0.50,"Fiber Plants":0.60,"Copper Ore":0.05},"days":1.40,"delivery":1.2,"glyph":"horse_archer","look":"Short recurved bow of horn and sinew; a rider with two quivers and a spare horse."},
	"crossbow":{"name":"Crossbows","family":"missile","gen":3,"year":847,"attack":1.30,"defense":0.85,"armor":0.05,"penetration":1.05,"crew":1.0,"crewless":0.0,"ammo":"arrows","ammo_per":24,"supply":0.05,"materials":{"Timber":0.60,"Iron Ore":0.25,"Fiber Plants":0.15},"days":1.60,"delivery":1.4,"glyph":"crossbow","look":"Stock and trigger lock, bronze or steel bow; a man-high shield to reload behind."},
	# Mounts.
	"chariot_kit":{"name":"War Chariots","family":"mount","gen":0,"year":500,"attack":1.35,"defense":0.85,"armor":0.15,"penetration":0.60,"crew":2.0,"crewless":0.0,"ammo":"arrows","ammo_per":12,"supply":10.0,"materials":{"Timber":3.00,"Copper Ore":0.40,"Fiber Plants":0.80},"days":6.00,"delivery":8.0,"glyph":"chariot","look":"Light two-wheeled car, two horses, a driver and an archer."},
	"lance":{"name":"Horses & Lances","family":"mount","gen":1,"year":778,"attack":1.35,"defense":0.72,"armor":0.18,"penetration":0.70,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":5.0,"materials":{"Timber":1.10,"Copper Ore":0.15},"days":1.25,"delivery":1.6,"glyph":"horse","look":"Rider on a small horse, long spear couched or thrown."},
	"elephant_kit":{"name":"War Elephants","family":"mount","gen":2,"year":500,"attack":1.60,"defense":1.20,"armor":0.60,"penetration":0.80,"crew":3.0,"crewless":0.0,"ammo":"arrows","ammo_per":12,"supply":60.0,"materials":{"Timber":1.50,"Fiber Plants":1.00,"Copper Ore":0.40},"days":4.00,"delivery":6.0,"glyph":"elephant","look":"Elephant with a driver on its neck and two archers in a tower."},
	"armored_lance":{"name":"Armoured Horse","family":"mount","gen":3,"year":720,"attack":1.55,"defense":1.10,"armor":0.60,"penetration":0.90,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":7.0,"materials":{"Timber":1.20,"Copper Ore":0.80,"Tin Ore":0.12,"Fiber Plants":0.40},"days":3.00,"delivery":3.0,"glyph":"heavy_horse","look":"Big horse in a scale or mail trapper, rider in mail with a heavy lance."},
	"dragoon_kit":{"name":"Dragoon Carbines","family":"mount","gen":4,"year":1976,"attack":1.3,"defense":1.0,"armor":0.05,"penetration":1.3,"crew":1.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":3,"supply":5.5,"materials":{"Iron Ore":1.20,"Timber":0.60,"Fiber Plants":0.30},"days":2.20,"delivery":2.0,"glyph":"dragoon","look":"Rider in a long coat with a short musket slung, who dismounts to fight."},
	# Firearms.
	"hand_cannon":{"name":"Hand Cannon","family":"firearm","gen":0,"year":1822,"attack":0.95,"defense":0.75,"armor":0.00,"penetration":1.2,"crew":1.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":3,"supply":0.4,"materials":{"Copper Ore":0.90,"Tin Ore":0.10,"Timber":0.40},"days":1.80,"delivery":1.4,"glyph":"hand_cannon","look":"Bronze tube on a pole, touched off with a glowing match; smoke and noise."},
	"musket":{"name":"Muskets","family":"firearm","gen":1,"year":1920,"attack":1.15,"defense":0.95,"armor":0.00,"penetration":1.45,"crew":1.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":3,"supply":0.5,"materials":{"Iron Ore":1.30,"Timber":0.50},"days":2.00,"delivery":1.4,"glyph":"musket","look":"Long matchlock on a forked rest, bandolier of powder flasks, broad hat."},
	"grenadier_kit":{"name":"Flintlocks & Grenades","family":"firearm","gen":2,"year":2138,"attack":1.35,"defense":1.05,"armor":0.00,"penetration":1.5,"crew":1.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":4,"supply":0.6,"materials":{"Iron Ore":1.50,"Timber":0.50,"Sulfur":0.10,"Nitrates":0.15},"days":2.30,"delivery":1.5,"glyph":"musket","look":"Flintlock with a socket bayonet, tall cap, grenade pouch; coat in the army's colour."},
	"marksman_rifle":{"name":"Rifled Muskets","family":"firearm","gen":3,"year":2290,"attack":1.4,"defense":0.95,"armor":0.00,"penetration":1.45,"crew":1.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":3,"supply":0.6,"materials":{"Iron Ore":1.60,"Timber":0.50},"days":2.60,"delivery":1.5,"glyph":"rifle","look":"Long rifled barrel, green or grey jacket, powder horn; fights in open order."},
	"mountain_kit":{"name":"Mountain Kit","family":"firearm","gen":3,"year":2320,"attack":1.4,"defense":1.1,"armor":0.00,"penetration":1.4,"crew":1.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":3,"supply":1.0,"materials":{"Iron Ore":1.50,"Timber":0.50,"Fiber Plants":1.00},"days":2.60,"delivery":2.0,"glyph":"mountain","look":"Rifle, rope, iron-shod staff and a pack mule; wool against the cold."},
	"service_rifle":{"name":"Service Rifles","family":"firearm","gen":4,"year":2560,"attack":1.80,"defense":1.18,"armor":0.05,"penetration":1.60,"crew":1.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":30,"supply":1.5,"materials":{"Iron Ore":1.80,"Timber":0.55,"Copper Ore":0.10},"days":2.20,"delivery":1.15,"glyph":"rifle","look":"Bolt rifle and bayonet, peaked cap then steel helmet; drab wool."},
	"marine_kit":{"name":"Sea Raider Arms","family":"hand","gen":3,"year":668,"attack":1.20,"defense":1.10,"armor":0.20,"penetration":0.60,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":0.1,"materials":{"Timber":0.60,"Copper Ore":0.40,"Fiber Plants":0.30},"days":1.40,"delivery":1.4,"glyph":"marine","look":"Light shield, short spear and blade, rope and boat hook; fights off the ships."},
	"engineering_kit":{"name":"Assault Engineer Kit","family":"firearm","gen":5,"year":2713,"attack":1.40,"defense":1.40,"armor":0.20,"penetration":1.60,"crew":1.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":30,"supply":3.0,"materials":{"Iron Ore":2.0,"Timber":1.2,"Sulfur":0.2,"Nitrates":0.3},"days":3.00,"delivery":2.5,"glyph":"engineer","look":"Rifle slung, charges, wire cutters, bridging planks and a flame gun."},
	"assault_kit":{"name":"Assault Weapons","family":"firearm","gen":6,"year":2713,"attack":2.1,"defense":1.30,"armor":0.10,"penetration":1.80,"crew":1.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":60,"supply":2.5,"materials":{"Iron Ore":2.20,"Copper Ore":0.20,"Timber":0.40},"days":3.20,"delivery":1.6,"glyph":"assault_rifle","look":"Short automatic weapon, grenades, steel helmet; moves by rushes."},
	"airborne_kit":{"name":"Airborne Kit","family":"firearm","gen":6,"year":2775,"attack":2.00,"defense":1.15,"armor":0.05,"penetration":1.70,"crew":1.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":40,"supply":2.5,"materials":{"Iron Ore":1.80,"Fiber Plants":3.00,"Copper Ore":0.20},"days":4.00,"delivery":1.6,"glyph":"paratrooper","look":"Folding-stock weapon, round jump helmet, parachute harness."},
	"air_assault_kit":{"name":"Air Assault Kit","family":"firearm","gen":7,"year":2763,"attack":2.40,"defense":1.30,"armor":0.10,"penetration":1.80,"crew":1.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":40,"supply":20.0,"materials":{"Iron Ore":3.00,"Bauxite":2.00,"Copper Ore":0.40,"Crude Oil":0.60},"days":8.00,"delivery":2.0,"glyph":"helicopter","look":"Light rifle and radio; the squad's share of a transport helicopter."},
	"networked_rifle":{"name":"Networked Rifle Kit","family":"firearm","gen":8,"year":2888,"attack":2.80,"defense":1.80,"armor":0.35,"penetration":2.10,"crew":1.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":40,"supply":4.0,"materials":{"Iron Ore":1.6,"Copper Ore":0.4,"Fine Sand":0.3,"Graphite":0.2,"Civilian Goods":6.0},"days":6.00,"delivery":1.4,"glyph":"networked","look":"Plate carrier, helmet with a night optic, short carbine, radio on the chest."},
	"exosuit":{"name":"Powered Exosuit","family":"firearm","gen":9,"year":2996,"attack":3.40,"defense":2.60,"armor":1.80,"penetration":2.40,"crew":1.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":90,"supply":12.0,"materials":{"Iron Ore":6.0,"Nickel Ore":1.5,"Graphite":1.0,"Fine Sand":0.6,"Bauxite":1.5,"Copper Ore":2.0,"Civilian Goods":40.0},"days":40.00,"delivery":4.0,"glyph":"exosuit","look":"A soldier inside a jointed frame: battery spine, plated limbs, a heavy weapon carried in one arm."},
	# Crew weapons.
	"machine_gun":{"name":"Machine Guns","family":"crew","gen":0,"year":2624,"attack":4.20,"defense":2.25,"armor":0.08,"penetration":1.50,"crew":8.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":220,"supply":8.0,"materials":{"Iron Ore":14.0,"Timber":1.50,"Copper Ore":0.80},"days":18.0,"delivery":8.0,"glyph":"machine_gun","look":"Water-cooled gun on a tripod, belts of cartridges, a team of eight."},
	"mortar":{"name":"Mortars","family":"crew","gen":1,"year":2664,"attack":3.60,"defense":0.90,"armor":0.00,"penetration":1.40,"crew":4.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":20,"supply":12.0,"materials":{"Iron Ore":6.0,"Copper Ore":0.3},"days":8.0,"delivery":5.0,"glyph":"mortar","look":"Short tube on a base plate, lobbing bombs over the lines."},
	"anti_tank_kit":{"name":"Antitank Guns","family":"crew","gen":2,"year":2710,"attack":2.00,"defense":1.40,"armor":0.05,"penetration":3.60,"crew":3.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":12,"supply":8.0,"materials":{"Iron Ore":5.0,"Copper Ore":0.3},"days":9.0,"delivery":5.0,"glyph":"anti_tank","look":"Low gun with a long thin barrel behind a shield, dug in by a road."},
	"anti_air_gun":{"name":"Antiaircraft Guns","family":"crew","gen":2,"year":2676,"attack":2.20,"defense":1.30,"armor":0.10,"penetration":1.60,"crew":6.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":30,"supply":20.0,"materials":{"Iron Ore":8.0,"Copper Ore":0.6},"days":12.0,"delivery":8.0,"glyph":"anti_air","look":"Quick-firing gun pointed at the sky on a cross mount."},
	"laser_point_defence":{"name":"Laser Point Defence","family":"crew","gen":3,"year":2995,"attack":3.00,"defense":2.60,"armor":0.60,"penetration":1.50,"crew":6.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":80.0,"materials":{"Iron Ore":6.0,"Copper Ore":4.0,"Fine Sand":2.0,"Graphite":1.0,"Nickel Ore":1.0,"Civilian Goods":80.0},"days":60.0,"delivery":10.0,"glyph":"laser","look":"A turret with a glass eye on a truck, and a generator humming beside it."},
	# Siege engines and guns.
	"ram":{"name":"Battering Rams","family":"guns","gen":0,"year":300,"attack":0.90,"defense":1.00,"armor":0.30,"penetration":1.20,"crew":8.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":1.0,"materials":{"Timber":6.00,"Fiber Plants":1.00},"days":5.0,"delivery":8.0,"glyph":"ram","look":"A tree trunk on ropes under a hide roof, pushed on rollers."},
	"siege_kit":{"name":"Siege Kit","family":"guns","gen":1,"year":724,"attack":0.88,"defense":0.72,"armor":0.08,"penetration":0.92,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":1.0,"materials":{"Timber":3.20,"Fiber Plants":0.80,"Stone":0.45,"Iron Ore":0.12},"days":3.80,"delivery":6.0,"glyph":"engineer","look":"Ladders, mantlets, picks and baskets for earth."},
	"catapult":{"name":"Catapults","family":"guns","gen":1,"year":724,"attack":2.20,"defense":0.50,"armor":0.05,"penetration":1.30,"crew":8.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":3.0,"materials":{"Timber":5.00,"Fiber Plants":1.50,"Copper Ore":0.30},"days":8.0,"delivery":8.0,"glyph":"catapult","look":"Twisted-sinew arm or bolt thrower on a timber frame."},
	"trebuchet":{"name":"Trebuchets","family":"guns","gen":2,"year":1667,"attack":3.20,"defense":0.50,"armor":0.05,"penetration":1.60,"crew":8.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":5.0,"materials":{"Timber":10.0,"Fiber Plants":2.00,"Iron Ore":0.40,"Stone":1.00},"days":14.0,"delivery":14.0,"glyph":"trebuchet","look":"Tall throwing arm with a box of stones for a counterweight."},
	"bombard":{"name":"Bombards","family":"guns","gen":3,"year":1848,"attack":3.80,"defense":0.50,"armor":0.10,"penetration":1.90,"crew":8.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":6,"supply":30.0,"materials":{"Copper Ore":6.00,"Tin Ore":0.80,"Timber":3.00},"days":16.0,"delivery":14.0,"glyph":"bombard","look":"Huge bronze tube on a timber bed, dragged by oxen."},
	"field_gun":{"name":"Field Guns","family":"guns","gen":4,"year":2062,"attack":5.00,"defense":0.48,"armor":0.12,"penetration":1.80,"crew":5.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":8,"supply":25.0,"materials":{"Iron Ore":8.00,"Timber":4.00,"Fiber Plants":0.50},"days":12.0,"delivery":10.0,"glyph":"field_gun","look":"Cast gun on a two-wheeled carriage with its limber and a team of horses."},
	"horse_gun":{"name":"Horse Artillery","family":"guns","gen":5,"year":2326,"attack":4.60,"defense":0.55,"armor":0.10,"penetration":1.70,"crew":8.0,"crewless":0.0,"ammo":"artillery_rounds","ammo_per":8,"supply":45.0,"materials":{"Iron Ore":6.00,"Timber":3.00,"Fiber Plants":0.50},"days":12.0,"delivery":10.0,"glyph":"field_gun","look":"Light gun whose whole crew rides; unlimbers at a gallop."},
	"modern_field_gun":{"name":"Modern Field Artillery","family":"guns","gen":6,"year":2664,"attack":7.20,"defense":0.72,"armor":0.18,"penetration":2.40,"crew":8.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":28,"supply":60.0,"materials":{"Iron Ore":24.0,"Copper Ore":1.50,"Timber":2.00},"days":34.0,"delivery":18.0,"glyph":"howitzer","look":"Steel howitzer with a recoil cylinder, split trail, camouflage net."},
	"rocket_launcher":{"name":"Rocket Launchers","family":"guns","gen":7,"year":2785,"attack":8.00,"defense":0.60,"armor":0.30,"penetration":1.80,"crew":5.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":24,"supply":70.0,"materials":{"Iron Ore":18.0,"Copper Ore":2.0,"Crude Oil":0.5,"Civilian Goods":10.0},"days":30.0,"delivery":18.0,"glyph":"rocket","look":"Rack of rails on a lorry, firing a ripple of rockets in a roar."},
	"precision_launcher":{"name":"Precision Launchers","family":"guns","gen":8,"year":2902,"attack":16.0,"defense":1.00,"armor":0.80,"penetration":5.00,"crew":4.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":12,"supply":120.0,"materials":{"Iron Ore":20.0,"Copper Ore":3.0,"Fine Sand":1.0,"Graphite":1.0,"Crude Oil":2.0,"Civilian Goods":60.0},"days":70.0,"delivery":20.0,"glyph":"precision","look":"Boxy launcher pod on a wheeled truck; each round steered by satellites."},
	# Vehicles.
	"motorized_kit":{"name":"Motor Lorries","family":"vehicle","gen":0,"year":2677,"attack":1.88,"defense":1.32,"armor":0.28,"penetration":1.02,"crew":4.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":24,"supply":25.0,"materials":{"Iron Ore":18.0,"Copper Ore":2.5,"Fiber Plants":1.0,"Civilian Goods":8.0},"days":26.0,"delivery":12.0,"glyph":"lorry","look":"Canvas-topped lorry; riflemen on benches in the back."},
	"armored_car_kit":{"name":"Armoured Cars","family":"vehicle","gen":1,"year":2709,"attack":2.60,"defense":1.60,"armor":2.00,"penetration":1.30,"crew":4.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":12,"supply":40.0,"materials":{"Iron Ore":22.0,"Copper Ore":1.5,"Crude Oil":0.3,"Civilian Goods":10.0},"days":30.0,"delivery":14.0,"glyph":"armored_car","look":"Four-wheeled steel box with a small turret; scouts the roads."},
	"light_tank_kit":{"name":"Light Tanks","family":"vehicle","gen":2,"year":2709,"attack":4.80,"defense":3.00,"armor":2.40,"penetration":1.90,"crew":3.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":30,"supply":80.0,"materials":{"Iron Ore":30.0,"Copper Ore":2.0,"Crude Oil":0.5,"Civilian Goods":15.0},"days":45.0,"delivery":20.0,"glyph":"light_tank","look":"Small tracked tank, riveted plates, one small gun or twin machine guns."},
	"armored_vehicle":{"name":"Medium Tanks","family":"vehicle","gen":3,"year":2709,"attack":4.80,"defense":3.70,"armor":2.80,"penetration":2.80,"crew":5.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":18,"supply":150.0,"materials":{"Iron Ore":65.0,"Copper Ore":5.0,"Tin Ore":1.0,"Civilian Goods":25.0},"days":80.0,"delivery":28.0,"glyph":"tank","look":"Welded tracked tank, sloped front, medium gun in a round turret."},
	"heavy_tank_kit":{"name":"Heavy Tanks","family":"vehicle","gen":4,"year":2768,"attack":5.60,"defense":4.60,"armor":3.40,"penetration":3.40,"crew":5.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":20,"supply":220.0,"materials":{"Iron Ore":90.0,"Copper Ore":6.0,"Tin Ore":1.5,"Crude Oil":1.0,"Civilian Goods":35.0},"days":110.0,"delivery":36.0,"glyph":"heavy_tank","look":"Wide slab-sided tank with a long heavy gun; slow and thirsty."},
	"tank_destroyer_kit":{"name":"Tank Destroyers","family":"vehicle","gen":4,"year":2768,"attack":5.20,"defense":2.60,"armor":2.60,"penetration":4.40,"crew":4.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":20,"supply":130.0,"materials":{"Iron Ore":55.0,"Copper Ore":3.0,"Crude Oil":0.5,"Civilian Goods":20.0},"days":70.0,"delivery":26.0,"glyph":"tank_destroyer","look":"Turretless tracked hull with a very long gun, low to the ground."},
	"mechanized_kit":{"name":"Armoured Carriers","family":"vehicle","gen":5,"year":2768,"attack":3.00,"defense":2.80,"armor":2.20,"penetration":1.60,"crew":8.0,"crewless":0.0,"ammo":"small_arms_ammunition","ammo_per":300,"supply":90.0,"materials":{"Iron Ore":26.0,"Copper Ore":2.0,"Crude Oil":0.5,"Civilian Goods":15.0},"days":40.0,"delivery":20.0,"glyph":"carrier","look":"Tracked steel box with a ramp; a squad rides inside, a gun on top."},
	"main_battle_tank":{"name":"Main Battle Tanks","family":"vehicle","gen":6,"year":2842,"attack":8.50,"defense":6.80,"armor":4.20,"penetration":4.60,"crew":4.0,"crewless":0.0,"ammo":"heavy_shells","ammo_per":40,"supply":600.0,"materials":{"Iron Ore":90.0,"Copper Ore":6.0,"Nickel Ore":2.0,"Fine Sand":0.5,"Crude Oil":3.0,"Civilian Goods":60.0},"days":140.0,"delivery":40.0,"glyph":"mbt","look":"Low wide tank with a long stabilised gun, night sights and angular armour."},
	# Drones and robots.
	"drone_team":{"name":"Drone Teams","family":"autonomous","gen":0,"year":2980,"attack":9.00,"defense":2.50,"armor":0.00,"penetration":4.40,"crew":2.0,"crewless":0.6,"ammo":"heavy_shells","ammo_per":6,"supply":30.0,"materials":{"Copper Ore":2.0,"Graphite":1.5,"Fine Sand":0.6,"Nickel Ore":0.6,"Fiber Plants":1.0,"Civilian Goods":25.0},"days":14.0,"delivery":3.0,"glyph":"drone","look":"Two operators in a dugout with goggles and a case of small four-rotor drones."},
	"robotic_vehicle":{"name":"Robotic Combat Vehicles","family":"autonomous","gen":1,"year":2990,"attack":5.4,"defense":3.4,"armor":2.60,"penetration":3.40,"crew":0.3334,"crewless":0.9,"ammo":"heavy_shells","ammo_per":10,"supply":150.0,"materials":{"Iron Ore":20.0,"Copper Ore":4.0,"Nickel Ore":1.5,"Graphite":1.0,"Fine Sand":1.0,"Civilian Goods":50.0},"days":90.0,"delivery":16.0,"glyph":"robot_vehicle","look":"Driverless tracked machine the size of a car, a sensor mast and a remote gun; one operator runs three."},
	"combat_frame":{"name":"Combat Frames","family":"autonomous","gen":2,"year":2996,"attack":4.3,"defense":2.5,"armor":2.40,"penetration":3.00,"crew":0.125,"crewless":0.95,"ammo":"small_arms_ammunition","ammo_per":120,"supply":25.0,"materials":{"Iron Ore":6.0,"Nickel Ore":1.5,"Bauxite":1.5,"Graphite":1.0,"Fine Sand":0.8,"Copper Ore":1.5,"Civilian Goods":40.0},"days":60.0,"delivery":3.0,"glyph":"combat_frame","look":"Man-tall jointed machine of graphite plates, a sensor slit for a face glowing in the army's colour; one supervisor runs eight."},
	# Support kits.
	"repair_kit":{"name":"Armorer tools","family":"support","gen":0,"year":600,"attack":0.0,"defense":0.5,"armor":0.0,"penetration":0.0,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":1.0,"materials":{"Timber":2.0,"Stone":2.0},"days":3.0,"delivery":1.0,"glyph":"support","look":"Anvil, tongs, rivets and a mule cart."},
	"medical_kit":{"name":"Medical care equipment","family":"support","gen":0,"year":2384,"attack":0.0,"defense":0.6,"armor":0.0,"penetration":0.0,"crew":1.0,"crewless":0.0,"ammo":"","ammo_per":0,"supply":1.0,"materials":{"Timber":1.0,"Fiber Plants":2.0},"days":2.0,"delivery":1.0,"glyph":"support","look":"Litters, dressings and a wagon with a red-painted cover."}
}

## Where the armor kits (armor_equipment.gd) sit: all are spear-and-armour
## kits, ordered by protection's arrival.
const ARMOR_FAMILY:={
	"padded_spear":{"gen":0,"year":700,"glyph":"spear","look":"Quilted linen coat over a spearman."},
	"shield_spear":{"gen":1,"year":500,"glyph":"spear","look":"Fitted wooden shield with a bronze boss."},
	"scale_spear":{"gen":2,"year":600,"glyph":"spear","look":"Coat of overlapping bronze scales."},
	"lamellar_spear":{"gen":3,"year":702,"glyph":"spear","look":"Laced plates of rawhide or iron in rows."},
	"mail_spear":{"gen":4,"year":893,"glyph":"spear","look":"Knee-length mail shirt and conical helmet."},
	"plate_spear":{"gen":5,"year":1856,"glyph":"spear","look":"Articulated steel plate from head to foot."}
}

## The kit's full row: the ledger's own, or an armor kit placed in the
## protection family. Empty for ships, aircraft and unknown ids.
static var _armor_rows:Dictionary={}
static func row(id:String)->Dictionary:
	if KITS.has(id): return KITS[id]
	if ArmorKits.KITS.has(id):
		if not _armor_rows.has(id):
			var kit:Dictionary=(ArmorKits.KITS[id] as Dictionary).duplicate()
			kit.merge(ARMOR_FAMILY.get(id,{}),true)
			kit["family"]="protection"
			for key in ["crewless","supply"]: if not kit.has(key): kit[key]=0.0
			_armor_rows[id]=kit
		return _armor_rows[id]
	return {}

static func has(id:String)->bool:
	return KITS.has(id) or ArmorKits.KITS.has(id)

static func family(id:String)->String:
	return String(row(id).get("family",""))

static func generation(id:String)->int:
	return int(row(id).get("gen",0))

static func year(id:String)->float:
	return float(row(id).get("year",0.0))

## Men per set (a float: below one, a man runs several machines).
static func crew(id:String)->float:
	return maxf(0.01,float(row(id).get("crew",1.0)))

## Share of the kit's battle losses that are machines lost, not men.
static func crewless(id:String)->float:
	return clampf(float(row(id).get("crewless",0.0)),0.0,1.0)

## Loads a day each set asks of the supply line, besides its men's food.
static func supply(id:String)->float:
	return maxf(0.0,float(row(id).get("supply",0.0)))

static func glyph(id:String)->String:
	return String(row(id).get("glyph","spear"))

static func label(id:String)->String:
	return String(row(id).get("name",id.replace("_"," ").capitalize()))

## Skill a production line keeps when it retools from one kit to another:
## all of it for the same kit, most of it within a family, less between land
## kits of different families, little for anything else (ships, carts).
const KEEP_SAME:=1.0
const KEEP_FAMILY:=0.80
const KEEP_LAND:=0.40
const KEEP_OTHER:=0.20

static func retention(from_id:String,to_id:String)->float:
	if from_id==to_id: return KEEP_SAME
	var a:=family(from_id)
	var b:=family(to_id)
	if a!="" and a==b: return KEEP_FAMILY
	if a!="" and b!="": return KEEP_LAND
	return KEEP_OTHER

## How the kit compares with another of its family, for the picker:
## signed change in attack and defense, as fractions.
static func compare(id:String,against:String)->Dictionary:
	var a:=row(id)
	var b:=row(against)
	if a.is_empty() or b.is_empty(): return {}
	var atk_b:=maxf(0.01,float(b.get("attack",1.0)))
	var def_b:=maxf(0.01,float(b.get("defense",1.0)))
	return {"attack":float(a.get("attack",1.0))/atk_b-1.0,"defense":float(a.get("defense",1.0))/def_b-1.0,"armor":float(a.get("armor",0.0))-float(b.get("armor",0.0)),"penetration":float(a.get("penetration",0.0))-float(b.get("penetration",0.0))}
