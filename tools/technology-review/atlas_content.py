"""600 named candidates, with editorial ownership and no implied linear chain."""
DOMAINS = []
def domain(name, target, purpose, groups, links):
    entries=[s.strip() for group in groups for s in group.split(';')]
    assert len(entries)==25,(name,len(entries))
    DOMAINS.append(dict(id=f'D{len(DOMAINS)+1:02}',name=name,target=target,purpose=purpose,groups=groups,entries=entries,links=links))

domain('Food and agriculture',280,'Food quantity, variety, preservation, resilience, and the work required to feed people.',[
'Seasonal food calendars; Selective seed keeping; Root crop propagation; Food drying racks; Smoke preservation',
'Terrace cultivation; Managed fallow; Crop rotation; Grafting orchards; Seed granaries',
'Rotary grain milling; Mechanical threshing; Pressure canning; Soil nutrient testing; Synthetic nitrogen fertilizer',
'Hybrid crop breeding; Refrigerated food storage; Drip irrigation; Integrated pest management; Controlled environment agriculture',
'Precision fermentation; Cultured food bioreactors; Salt tolerant crop breeding; Robotic selective harvesting; Closed nutrient food production'],
'Water supplies; biological breeding; energy; land ecology; transport and storage.')
domain('Water and sanitation',180,'Reliable water access and removal of waste from household to planetary systems.',[
'Water source comparison; Lined wells; Rainwater cisterns; Household boiling; Waste separation',
'Gravity aqueducts; Infiltration galleries; Ceramic water pipes; Public washing facilities; Covered drains',
'Municipal filtration; Pressure water networks; Sewer ventilation; Waterborne disease tracing; Mechanical sewage pumping',
'Drinking water disinfection; Activated sludge treatment; Membrane desalination; Leak detection networks; Wastewater nutrient recovery',
'Energy recovering desalination; Selective contaminant membranes; Autonomous water network control; Closed habitat water recycling; Distributed potable reuse'],
'Hydrology; public health; pumps; electricity; institutions and maintenance.')
domain('Ecology and land stewardship',180,'Knowledge of living landscapes and ways to sustain productive environments.',[
'Animal track interpretation; Seasonal burning practice; Habitat refuges; Seed dispersal observation; Woodland coppicing',
'Community grazing rules; Contour erosion control; Managed fisheries; Mixed woodland cultivation; Watershed protection',
'Species inventories; Population ecology; Forest regeneration plans; Pest predator management; Wetland drainage assessment',
'Habitat corridors; Ecosystem restoration; Catch limits from stock surveys; Biodiversity monitoring; Invasive species control',
'Assisted ecosystem migration; Genomic conservation planning; Automated habitat monitoring; Marine habitat reconstruction; Regional ecological recovery models'],
'Food; land tenure; biological science; climate; observation instruments.')
domain('Materials and chemistry',300,'Matter that people can characterize, transform, combine, and recover.',[
'Stone selection; Controlled flaking; Tempered clay; Charcoal making; Mineral pigment preparation',
'Copper smelting; Bronze alloying; Bloomery iron; Glassmaking; Lime mortar chemistry',
'Coke metallurgy; Bulk sulfuric acid production; Fractional distillation; Electrochemical refining; Industrial steelmaking',
'Synthetic polymers; Semiconductor grade silicon; Composite laminates; Corrosion resistant alloys; Catalytic process design',
'High temperature structural ceramics; Recyclable thermoset chemistry; High entropy alloys; Selective metal recovery; Radiation tolerant structural materials'],
'Heat and power; mines; precision tools; buildings; computation and spacecraft.')
domain('Energy and power',260,'Usable work and heat with real conversion losses and operating constraints.',[
'Fire maintenance; Fire ignition; Insulated hearths; Fuel drying; Charcoal heat control',
'Water wheels; Wind driven mills; Mechanical power transmission; Furnace draft control; Heat resistant boilers',
'Steam engines; Steam turbines; Electrical generators; Alternating current transmission; Hydroelectric power',
'Photovoltaic conversion; Lithium ion storage; Fission power generation; Grid frequency control; High efficiency heat pumps',
'Long duration grid storage; Fusion confinement; Fusion fuel breeding; Fusion heat extraction; Net electric fusion operation'],
'Materials; machinery; water; industrial demand; waste heat and environment.')
domain('Machinery and manufacturing',240,'Repeatable production and the tools that make better tools possible.',[
'Wedges and levers; Bow drills; Wood joinery; Hafted tools; Rope lifting rigs',
'Treadle lathes; Water powered hammers; Screw presses; Gear cutting; Interchangeable gauges',
'Precision machine tools; Interchangeable components; Assembly line organization; Hydraulic machinery; Steam powered excavation',
'Numerical machine control; Industrial robotics; Additive manufacturing; Non destructive inspection; Semiconductor lithography',
'Adaptive factory control; In process defect correction; Robotic field repair; Microfabrication assembly; Distributed manufacturing verification'],
'Metrology; materials; labor; energy; software and production standards.')
domain('Fibers clothing and domestic practice',120,'Textiles, shelter equipment, and household techniques that change daily work.',[
'Twisted cordage; Basket weaving; Hide tanning; Bone needle sewing; Insulated clothing',
'Spindle spinning; Pattern looms; Felt making; Textile dye fixation; Soap making',
'Mechanized spinning; Power looms; Sewing machines; Domestic refrigeration appliances; Efficient cooking stoves',
'Synthetic textile fibers; Flame resistant fabrics; Washing machines; Ergonomic household tools; Adaptive assistive clothing',
'Textile fiber separation; Reparable domestic robots; Low energy fabric finishing; Responsive insulating textiles; Closed loop textile production'],
'Chemistry; household energy; labor participation; health; cold environments.')
domain('Buildings and cities',220,'Places that can be built, maintained, inhabited, and changed.',[
'Framed shelters; Earthen walls; Thatched roofing; Stone foundations; Passive shelter ventilation',
'Load bearing arches; Vaulted construction; Planned street drainage; Fire separation rules; Courtyard climate design',
'Structural steel frames; Reinforced concrete; Safety elevators; Building services coordination; Industrial housing systems',
'Seismic isolation; Glazed curtain walls; District heating; Accessible building design; Whole building energy control',
'Low carbon structural binders; Robotic construction assembly; Reusable building components; Adaptive coastal foundations; Self monitoring structures'],
'Materials; water; household needs; land administration; energy and transport.')
domain('Overland transport and logistics',180,'Moving people and goods through actual terrain at affordable cost.',[
'Encoded route memory; Carrying frames; Pack animal handling; Sled transport; Wheeled carts',
'Graded roads; Timber bridges; Relay stations; Caravanserais; Standard cargo measures',
'Rail traction; Railway signaling; Pneumatic tires; Road freight engines; Intermodal freight handling',
'Container logistics; Refrigerated freight; Warehouse automation; Electric road traction; Supply network forecasting',
'Autonomous freight corridors; High speed magnetic transport; Robotic last mile delivery; Predictive infrastructure repair; Resilient multimodal routing'],
'Animals; mechanical power; roads; communications; storage and production.')
domain('Navigation and maritime systems',160,'Waterborne movement, navigation, trade, and maintainable marine infrastructure.',[
'Hide floats; Dugout hulls; Paddled river craft; Sewn plank hulls; Celestial wayfinding',
'Sail handling; Outrigger stabilization; Hull caulking; Coastal pilotage; Dry docks',
'Ocean position finding; Marine chronometers; Iron ship framing; Screw propellers; Powered harbor handling',
'Marine radar; Satellite aided navigation; Diesel electric ship systems; Automated ballast control; Container ports',
'Autonomous ocean navigation; Low emission marine propulsion; Robotic hull maintenance; Offshore logistics hubs; Deep ocean cargo habitats'],
'Weather; cordage; hull materials; port institutions; power and surveillance.')
domain('Flight and aerospace',160,'Lift, propulsion, airframes, operation, and access beyond the atmosphere.',[
'Kite stability; Buoyancy experiments; Lightweight frame construction; Fabric aerodynamic testing; Wind profile observation',
'Glider control; Lighter than air craft; Propeller aerodynamics; Lift measurement; Airframe load testing',
'Powered fixed wing flight; Aircraft engine cooling; Instrument flight; All metal airframes; Air traffic coordination',
'Jet propulsion; Rotary wing control; Pressurized cabins; Supersonic inlet control; Reusable launch vehicles',
'Electric regional aircraft; Autonomous flight verification; High temperature flight structures; Integrated spaceplane operations; Reusable orbital transfer stages'],
'Fuel; structures; measurement; control systems; operations and space logistics.')
domain('Mathematics and measurement',180,'Abstractions and instruments that make comparison, prediction, and precision possible.',[
'Material tallies; Shared measures; Geometric comparison; Seasonal reckoning; Fractional quantities',
'Place value calculation; Algebraic methods; Trigonometric methods; Geometric surveying; Mechanical timekeeping',
'Differential calculus; Probability theory; Statistical inference; Precision dimensional standards; Thermodynamic measurement',
'Information theory; Control theory; Atomic timekeeping; Numerical simulation; Uncertainty quantification',
'Quantum limited sensing; Distributed precision timing; Automated formal proof; Multiscale predictive modeling; Extreme environment metrology'],
'Every experimental field; navigation; accounting; machinery; scientific reliability.')
domain('Records and communication',240,'Storing, reproducing, carrying, and interpreting information.',[
'Oral epics; Pictographic records; Clay record tablets; Knotted record systems; Messenger routes',
'Phonetic notation; Fiber writing sheets; Woodblock printing; Movable type composition; Public postal relays',
'Optical telegraphy; Electrical telegraphy; Telephone networks; Radio transmission; Mass newspaper production',
'Optical fiber links; Packet switched networks; Satellite communications; Error correcting transmission; Secure digital messaging',
'Delay tolerant interplanetary networks; Deep space optical links; Archival media longevity; Authenticated synthetic media; Resilient decentralized communications'],
'Language; education; materials; electricity; institutions and computation.')
domain('Medicine and public health',280,'Preventing harm, caring for people, and making treatments reproducible.',[
'Wound cleaning; Medicinal plant comparison; Birth attendance; Fracture splinting; Maternal recovery care',
'Clinical case records; Isolation practice; Surgical anatomy; Trained midwifery; Community infirmaries',
'Anesthesia; Antiseptic surgery; Germ theory; Immunization programs; Public health surveillance',
'Antibiotic production; Diagnostic imaging; Blood transfusion services; Organ transplantation; Emergency care systems',
'Personalized cell therapy; Targeted drug delivery; Regenerative tissue treatment; Rapid pathogen platform response; Long term implant integration'],
'Water; biology; chemistry; records; energy; training and access institutions.')
domain('Biology and biotechnology',200,'Understanding, breeding, cultivating, and deliberately changing living systems.',[
'Animal taming; Seed germination trials; Yeast culture maintenance; Selective herd breeding; Plant disease observation',
'Comparative anatomy; Microscopy; Biological classification; Controlled breeding trials; Fermentation cultures',
'Cell theory; Heredity experiments; Microbial isolation; Enzyme chemistry; Evolutionary population analysis',
'DNA sequencing; Recombinant production; Genomic selection; Gene editing; Tissue culture methods',
'Engineered microbial consortia; Programmable cell systems; Biomanufacturing containment; Organ scaffold cultivation; Evolution resistant bioprocesses'],
'Medicine; food; ecology; instruments; industrial processes and oversight.')
domain('Law governance and civic systems',240,'Institutional techniques and capacities with contestable political uses.',[
'Customary law; Household councils; Remembered judgments; Shared store rules; Water access agreements',
'Property registers; Census rolls; Specialized courts; Public levy schedules; Municipal administration',
'Professional civil service; Public budget accounting; Representative assembly procedure; Independent statistical offices; Labor inspection systems',
'Administrative appeals; Electoral administration; Public procurement audits; Emergency coordination systems; Data protection institutions',
'Algorithmic decision review; Cross border resource arbitration; Long horizon public trusts; Habitat constitutional design; Distributed civic verification'],
'Records; social legitimacy; economics; communication; public services and culture.')
domain('Exchange finance and economic organization',200,'Ways to coordinate exchange, absorb risk, and finance long projects.',[
'Reciprocal gift accounting; Barter equivalence practices; Market gatherings; Cargo seals; Debt witnesses',
'Standard coin assay; Merchant credit; Bills of exchange; Mutual risk pools; Partnership accounting',
'Double entry bookkeeping; Joint stock organization; Central clearing; Public bond markets; Industrial cost accounting',
'Electronic settlement; Deposit protection systems; Project finance; Supply chain credit; Payment fraud detection',
'Programmable settlement agreements; Resource circularity accounting; Interplanetary clearing; Automated market oversight; Long duration liability finance'],
'Measurement; law; communication; logistics; trust and productive capability.')
domain('Learning labor and organizations',160,'How people teach, coordinate, preserve skill, and sustain difficult work.',[
'Apprentice contracts; Labor rotations; Crew handoffs; Shared childcare; Work and rest limits',
'Traveling scholar instruction; Translation workshops; Craft guild training; Public instruction; Scholarly correspondence',
'Research universities; Technical institutes; Experimental replication networks; Occupational safety training; Work motion studies',
'Professional certification; Multidisciplinary laboratories; Open scientific repositories; Distance education; Research procurement offices',
'Immersive skill transfer; Human machine team training; Automated experimental facilities; Continuous technical retraining; Intergenerational mission education'],
'Civic labor ownership; culture; communication; equipment; health and research diffusion.')
domain('Culture belief and collective memory',180,'Creative and social practices that give discoveries meaning and preserve plurality.',[
'Rhythmic performance; Pigment image making; Ritual gathering practice; Kinship memory; Festival calendars',
'Public theatre; Civic games; Comparative chronicles; Musical notation; Monument conservation',
'Public libraries; Museum curation; Photographic documentation; Recorded sound; Mass public exhibition',
'Broadcast production; Film editing; Digital cultural archives; Interactive media design; Community heritage stewardship',
'Immersive cultural environments; Durable language preservation; Collective memory authentication; Participatory virtual performance; Interplanetary cultural exchange'],
'Teaching; records; materials; institutions; media and social cohesion.')
domain('Defense and military operations',280,'Organized protection and force with real equipment, people, doctrine, and supply.',[
'Organized watch; Bow craft; Hafted weapons; Shield wall discipline; Field fortifications',
'Combined infantry drill; Mounted reconnaissance; Siege engineering; Military staff planning; Naval boarding doctrine',
'Rifled barrels; Metallic cartridges; Indirect fire control; Armored fighting vehicles; Battlefield medical evacuation',
'Combined arms doctrine; Integrated air defense; Anti submarine coordination; Electronic warfare; Precision targeting networks',
'Human supervised autonomous formations; Directed energy defense; Distributed sensor defense; Orbital asset protection; Contested logistics autonomy'],
'Separate military section defines the broader unit families and specialized research layers.')
domain('Electronics and computation',300,'Devices and methods for sensing, calculation, control, and digital systems.',[
'Mechanical counting aids; Logical inference methods; Mechanical calculation; Electrical conduction measurement; Electromagnetic switching',
'Vacuum tube amplification; Boolean circuit design; Stored program architecture; Semiconductor transistors; Magnetic data storage',
'Integrated circuits; Microprocessors; Operating systems; Relational data systems; Digital control electronics',
'Distributed computing; Machine learning methods; High density accelerators; Reliable embedded systems; Cryptographic hardware',
'Fault tolerant quantum computing; Neuromorphic computation; Photonic interconnect systems; Verifiable autonomous planning; Energy proportional computing'],
'Mathematics; materials purity; precision manufacture; power; communication and institutions.')
domain('Earth oceans and climate',160,'Understanding the physical planet and acting on evidence about it.',[
'Weather signs; Mineral field mapping; Tidal calendars; Groundwater tracing; Seasonal flood records',
'Stratigraphic observation; Compass field measurement; Barometric observation; Ocean current charts; Temperature record networks',
'Seismology; Plate tectonic theory; Atmospheric circulation models; Oceanographic surveying; Radiometric dating',
'Satellite Earth observation; Climate system modeling; Hazard early warning; Carbon cycle measurement; Deep ocean sensing',
'Verified carbon removal; Ice sheet dynamics forecasting; Regional water climate prediction; Planetary sensor integration; Climate intervention monitoring'],
'Land use; navigation; energy; materials; computing and public coordination.')
domain('Space science and settlement',180,'Astronomy, space infrastructure, and durable presence beyond the home world.',[
'Constellation records; Eclipse prediction; Optical telescopes; Orbital mechanics; Stellar spectroscopy',
'Liquid rocket propulsion; Spacecraft guidance; Orbital launch operations; Space life support; Planetary robotic probes',
'Orbital docking; Space radiation protection; Surface resource prospecting; In situ oxygen extraction; Orbital construction',
'Reusable surface landers; Cryogenic orbital storage; Closed habitat agriculture; Extraterrestrial metal processing; Rotating habitat engineering',
'Nuclear electric deep space propulsion; Asteroid material processing; Autonomous outer system observatories; Beamed sail probes; Interstellar communication receivers'],
'Aerospace; power; biology; construction; supply; institutions and long-term reliability.')
domain('Human futures and resilient civilization',120,'Integrated capabilities for long lives, extreme environments, and lasting societies.',[
'Intergenerational knowledge trusts; Disaster refuge planning; Redundant skill preservation; Long distance care coordination; Accessible civic participation',
'Life course health records; Integrated disaster recovery; Critical infrastructure redundancy; Global scientific agreements; Long term ecological trusteeship',
'Advanced prosthetic control; Neural interface rehabilitation; Organ replacement coordination; Distributed emergency manufacturing; Planetary resource stewardship',
'Evidence based aging intervention; Resilient food energy settlements; Reproductive health in low gravity; Autonomous habitat repair; Long duration crew governance',
'Multigenerational space habitation; Closed civilization material cycles; Deep time archive recovery; Interstellar probe autonomy; Planetary defense coordination'],
'Integrates existing fields. Far-future candidates require explicit engineering confidence review.')

assert len(DOMAINS)==24
assert sum(d['target'] for d in DOMAINS)==5000
assert sum(len(d['entries']) for d in DOMAINS)==600
names=[s.casefold() for d in DOMAINS for s in d['entries']]
assert len(set(names))==600, 'Duplicate candidate name'
