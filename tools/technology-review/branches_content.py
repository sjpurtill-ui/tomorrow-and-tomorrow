from design_content import p,h,bullets,table

EXTRA_PAGES = []
def page(title,*blocks):EXTRA_PAGES.append((title,list(blocks)))

page('Scholar envoys and purchased research',
 p('Your requested acquisition ladder should be explicit: paid or traded scholar envoys in the late early and middle game, followed by the purchase of research to accelerate work later in the campaign. These are important playable routes, not background flavor.'),
 h('Scholar envoys'),
 p('A leader asks a known society to send a teacher, craft expert, physician, mathematician, navigator, or other scholar. The request names an observed subject or a practical problem, offers payment or a negotiated exchange, and states the visit’s scope. The source can offer only knowledge it possesses and can actually transmit.'),
 p('The agreement can exchange goods, teaching in another subject, access to a workshop, or a negotiated civic obligation. The envoy travels through the existing mission system. Teaching begins after arrival and requires local learners, time, translation where relevant, and appropriate equipment. Hands-on trades need demonstrations; an oral tradition does not require paper to be teachable.'),
 h('A visible example'),
 p('“Ask the river cities for a waterworks scholar. Offer twelve timber shipments or a season of navigation instruction.” The quantities are a proposal priced by real stocks and logistics, not fixed universal costs. The resulting program shows the scholar’s arrival estimate, promised teaching, local readiness, payment, and remaining dependence.'),
 h('Purchased research later in the game'),
 p('Research offices, laboratories, firms, or states can sell experimental data, reproducible methods, design studies, specialist services, patents where those institutions exist, or a commissioned research program. Buying a package should materially shorten the recipient’s remaining investigation when the evidence is relevant and usable. A license to operate a product is a different purchase from the knowledge needed to redesign it.'),
 p('Pay on agreed milestones such as authenticated delivery and local reproduction. Verified results add bounded topic-specific evidence or reduce search work; they do not bypass hard scientific foundations, industrial inputs, or validation. A duplicate package cannot be purchased repeatedly for unlimited progress.'),
 h('Speed and dependence can coexist'),
 p('A late purchase may take a follower from ten remaining years of work to four. That is a genuine advantage over continuing unaided. The follower still pays, arrives after the source’s original breakthrough, and may depend on licensed equipment or missing tacit expertise. The system must not impose a blanket rule that purchased research is always slower than the buyer’s own remaining research.'))

page('The graph language in concrete form',
 p('Use four explicit relationships. Foundations are knowledge that must be present. Alternative routes are different sufficient sets of foundations. Operating inputs are resources and facilities needed to use a capability. Transfer is an acquisition event that carries real evidence from another society. Only the first two determine the prerequisite graph.'),
 ('branch_diagram',None),
 h('Reading the example'),
 p('Drying and smoking are distinct methods. Either can contribute to the broader ability to provision travel, but they have different climates, fuel needs, foods, and storage performance. The provisioning capability also needs suitable containers and an actual food surplus. Its effect is a longer viable journey under those conditions.'),
 p('A visiting scholar can help reproduce smoking. That route enters the same smoking discovery record as local experimentation. It does not create a second “foreign smoking” technology. The envoy cannot conjure fuel, food, or storage, and an arid society may still prefer drying.'),
 h('Different kinds of reconvergence'),
 p('Equivalent acquisition converges on the same method. Different physical methods can converge on a shared service, such as preserved provisions, while remaining distinct technologies. This distinction allows broad branching without erasing the differences that make each route interesting.'),
 p('Later technologies can re-open old choices. Reliable refrigeration changes the preservation portfolio; it does not make drying obsolete in every place or remove its usefulness when power fails.'))

page('Worked branches for food and water',
 h('Food preservation to dependable supply'),
 p('Foundation: observing spoilage and recurring food availability. Independent branches include drying with suitable airflow; smoke preservation with controlled fire; salting with accessible salt; and controlled fermentation with vessels and repeatable cultures. Each has its own food suitability and operating costs.'),
 p('Reconnection: preserved provisions plus containers and organized carrying support longer journeys and reserve management. Later pressure canning, mechanical cooling, and cold-chain logistics expand the portfolio. Refrigeration requires power, insulation, equipment, and maintenance; a report about a refrigerator is not an operating cold chain.'),
 p('Fallback: hire preservation specialists, acquire a demonstrated apparatus, or buy a later validated process study. Imported food can bridge a shortage without teaching preservation. A follower can become independent by reproducing the process and training operators. Consequences include new settlement reach, seasonal resilience, energy demand, and control of storage facilities.'),
 h('Water supply to public health'),
 p('Foundation: observations of water sources, seasonal behavior, and illness. Wells, rainwater cisterns, gravity systems, and infiltration galleries provide different supply routes; geology, rainfall, gradient, and water quality determine feasibility. No settlement must build the same Roman-style aqueduct to advance.'),
 p('Reconnection: reliable supply plus maintenance and waste separation supports settlement health and growth. Filtration, disinfection, pressure networks, and treatment depend on different knowledge and equipment combinations. Desalination extends supply where energy and maintenance are affordable.'),
 p('Fallback: invite a waterworks scholar, exchange surveying expertise, or procure a treatment design. Operators must still learn sampling and repair. A contract for clean-water delivery creates service dependence rather than local treatment mastery. The political consequence is concrete: who pays for and receives dependable water.'),
 p('Review test: two environments should favor different supply methods while preserving a route to safe water in each viable settlement. If no local process is physically possible, the game must explain the transport or relocation requirement rather than pretending the society lacks intelligence.'))

page('Worked branches for industry and power',
 h('Metals and the tools to reproduce them'),
 p('Stone selection and controlled flaking support early tools. Furnaces, fuel, ore knowledge, and process control open separate metallurgical routes. Copper and bronze are valuable possibilities, but a universal “bronze civilization level” must not be a logical requirement for every conceivable iron process. Each proposed dependency needs physical justification.'),
 p('Reconnection: workable materials, shaping, and measurement support dependable tools. Later high-temperature processes, machine tools, alloy control, and interchangeable components connect into precision manufacture. These are distinct capabilities: possessing an alloy does not supply the machinery to make a precise part.'),
 p('Fallback: buy metal, hire a founder, invite a toolmaker, license a production process, or purchase inspection research. Imported stock enables some production but leaves supply risk. Independent mastery needs appropriate samples, working facilities, and repeatable local quality. Consequences include repair autonomy, new construction, arms quality, mining demand, and pollution.'),
 h('Power without one mandatory fuel history'),
 p('Mechanical work can come from people, animals, water, or wind before more advanced engines. Electrical generation can draw on several conversion mechanisms. Hydroelectric, thermal, photovoltaic, and other systems share grid and load questions while retaining different geography, storage, and maintenance demands.'),
 p('Reconnection: useful electrical service requires generation, conductors, protection, distribution, and compatible loads. A solar route cannot ignore intermittency; a thermal route cannot ignore fuel and heat rejection. Electrification changes the location and scale of productive work.'),
 p('Fallback: import generating equipment, negotiate an interconnection, commission engineers, or buy research that improves local conversion or storage. Purchased plant can provide power before domestic manufacturing exists, at the cost of parts and service dependence. Later mastery comes from reproducing and maintaining the technology, not merely owning the asset.'),
 p('Review test: an industrial economy should remain viable without one specific fossil resource if it can build an alternative supply chain. Alternative routes need not be equally cheap or fast.'))

page('Worked branches for knowledge and computation',
 h('Memory to mass communication'),
 p('Oral epics, memorized rules, knots, marks, and written records provide different capacities for remembering and transmitting information. Each supports particular kinds of reliability, scale, and teaching. Writing is not the first point at which a society possesses knowledge.'),
 p('Branching includes pictographic and phonetic systems; different recording media; manuscript copying, woodblock printing, and movable type; and later broadcast or network communication. Type systems, inks, surfaces, language conventions, and trained production determine cost. The historical reference set must include multiple traditions. [H2]'),
 p('Fallback: invite a scribe or printer, exchange scholars, translate imported work, acquire presses, or purchase publishing methods. A foreign library may reveal a result while its language or missing craft knowledge delays useful reproduction. Wider literacy changes the audience and institutions that can use the result.'),
 h('Calculation to advanced computation'),
 p('Counting, notation, formal inference, measurement, and algorithmic methods support multiple calculating traditions. Mechanical devices, relay circuits, vacuum tubes, and semiconductor electronics have distinct capabilities and operating requirements. A society can import a later computer without reproducing every obsolete device, but it still needs the relevant concepts and an operating environment.'),
 p('Reconnection: usable computational services need a processing mechanism, information representation, reliable power, input and output, and people or systems capable of programming and maintenance. Advanced electronics add purity, fabrication, precision, architecture, and software dependencies.'),
 p('Fallback: purchase compute services, software, circuit designs, or validated research. Each purchase grants what was actually sold. Buying remote compute accelerates some investigations but creates network and supplier dependence; it does not grant domestic chip fabrication. Quantum approaches have workload-specific uses and demanding reliability requirements, not a universal multiplier. [F3]'),
 p('Review test: a polity should be able to use advanced computing while being strategically dependent on a supplier, then pursue a costly and intelligible path to greater autonomy.'))

page('Worked branches for medicine and institutions',
 h('Care to modern therapeutic systems'),
 p('Caregiving observations, wound cleaning, medicinal comparison, fracture care, and birth attendance provide early practice. Records, anatomy, instruments, controlled trials, and biological understanding connect toward more specialized treatment. Useful sanitation practice can precede an adequate explanation of microbes.'),
 p('Reconnection: effective treatment is a demonstrated method plus trained staff, supplies, and access. Vaccines, surgery, antibiotics, imaging, and regenerative therapies require different supporting systems. A drug discovery does not vaccinate the population or staff every clinic.'),
 p('Fallback: request a physician-scholar, exchange clinical observations, procure medicine, purchase trial data, or license production. Imported medicine may reduce harm promptly while local manufacture remains unavailable. Reproduction and distribution determine the local benefit. Ethical and institutional choices affect which groups receive care and how evidence is obtained.'),
 h('Institutions as learned capacities'),
 p('Remembered judgments, councils, ledgers, surveys, and public coordination open administrative capacities. Courts, public budgets, civil services, appeals, and oversight can develop through different political settings. Knowing how to run an election does not force a state to adopt representative government; possessing accounts does not guarantee honest officials.'),
 p('Reconnection: reliable administration combines recordkeeping, communication, competent staff, enforceable procedures, and legitimacy sufficient for the task. Different constitutional arrangements can use these capabilities. Institutional choices can conflict in operation without making their underlying knowledge permanently unknowable.'),
 p('Fallback: invite jurists or administrators, translate procedures, negotiate technical assistance, or purchase systems later. A foreign model can fail locally if it assumes absent staff, records, or social acceptance. The disadvantage should be an explainable implementation burden rather than a cultural penalty.'),
 p('Review test: technical capability, actual policy, and political legitimacy are separate states. The tree cannot encode a mandatory ladder from one named government to another.'))

page('Worked branches for fleets and flight',
 h('Watercraft to ocean power'),
 p('Floats, dugouts, framed or sewn hulls, paddles, sails, and navigation develop through distinct materials and environments. Rope, woodwork, hull sealing, weather knowledge, and crew organization repeatedly cross-connect. Naval arsenals later join specialized construction, standardized fittings, stores, and repair.'),
 p('Reconnection: a capable fleet is hulls plus propulsion, navigation, trained crews, maintenance, and supply. Armed vessels require separate weapon, fire-control, and doctrine capabilities. An armored hull does not provide submarine detection, and a large gun does not make a transport a capable battleship.'),
 p('Fallback: buy hulls, employ shipwrights, exchange navigators, license engines, or commission naval research. Purchased ships can enter service after delivery and crew preparation; domestic construction remains a separate capability. Access to dockyards and spare parts becomes a strategic dependency.'),
 h('Aviation as a combination of fields'),
 p('Stable structures, aerodynamic evidence, propulsion, control, and light materials create routes to flight. Balloons, gliders, fixed-wing craft, and rotary-wing craft solve different problems. There is no requirement to research every obsolete aircraft before adopting a newer design, but missing control, engine, or manufacturing foundations must still be addressed.'),
 p('Reconnection: useful air operations require an aircraft, trained crews, fuel or power, maintenance, navigation, and suitable bases. Fighter tactics, bombing, maritime patrol, transport, and carrier operations are distinct research and training questions.'),
 p('Fallback: purchase airframes, request instructors, negotiate licensed assembly, or buy tested component research. Imported fighters without suitable fuel, spares, trained crews, or maintenance have limited availability. Generals and their service commanders decide operational use under the player’s objectives.'),
 p('Review test: industrial sophistication, equipment ownership, service readiness, and doctrine are separately visible. A technology unlock cannot silently create pilots, crews, ships, or fuel.'))

page('Worked branches for space and human futures',
 h('Space access to durable habitation'),
 p('Orbital mechanics, launch systems, guidance, communications, energy, and materials converge on space access. Sustained habitation then needs radiation protection, thermal control, life support, maintenance, supply, and governance. A launch capability is one foundation, not a single prerequisite that grants colonies.'),
 p('Branching includes orbital stations, rotating habitats, surface settlements, robotic industry, and scientific probes. Local oxygen production and other resource processes can reduce supply dependence only after scaled equipment and reliability are established. Experimental evidence such as MOXIE supports a specific process, not a complete settlement. [F4]'),
 p('Fallback: buy launch services, share a station, purchase life-support research, or lease specialist equipment. These routes accelerate access for a weaker society while creating contractual, logistical, and operational dependencies. A domestic space industry is an intelligible long program of suppliers, expertise, and demonstrated reliability.'),
 h('Several futures for people'),
 p('Advanced medicine, assistive systems, biological engineering, computation, ecological restoration, and institutional design open different ways to improve human life. A society may emphasize longevity, resilience, exploration, cultural continuity, or wider access to advanced capabilities. These priorities must produce distinct material and social consequences.'),
 p('Reconnection: lasting future settlements need food, water, energy, repair, skilled learning, reproduction and care, communication, and workable institutions. High automation can shift labor but cannot erase energy, maintenance, political choice, or finite material supply.'),
 p('Fallback: contract for advanced medical research, form a space consortium, purchase automation services, or trade access to scientific facilities. The source’s demonstrated capability, the buyer’s foundations, and the agreement’s content constrain the result. A purchased study can speed research; an unproven promise cannot be treated as a finished technology.'),
 p('Review test: several viable late-game projects remain available, with uncertain but explainable engineering paths. There is no single mandatory ending and no final repeatable that merely raises all statistics.'))

page('Military forces built from capabilities',
 p('Military breadth should emerge from equipment, organization, training, doctrine, support, and environment. Expand the current unit catalog into distinct roles and design families, with explicit differences in how forces operate. The 96 role examples on the following pages are a review inventory; variants count as new roles only where behavior differs.'),
 table(['Layer','Examples of decisions and consequences'],[
 ['Role and formation','Screen, scout, hold, assault, support, transport, intercept, escort, deny, or sustain'],
 ['Equipment','Weapons, protection, sensors, propulsion, communications, ammunition, and specialist tools'],
 ['Personnel and training','Operators, crews, junior leaders, maintainers, specialists, cohesion, and replacement training'],
 ['Doctrine','Formation behavior, combined operations, engagement methods, concealment, and command practice'],
 ['Support','Transport, repair, supply, medical care, engineering, bases, and available industrial replacements'],
 ['Operating conditions','Terrain, weather, visibility, distance, sea state, airfields, communication, and enemy capabilities']],[1.55,5.25]),
 h('Diversity that changes the battle'),
 p('A dispersed scout screen gathers information and avoids sustained contact. Dense spear infantry holds a line but is vulnerable to flanking and some missile conditions. Mounted troops trade sustainment and terrain access for mobility. Artillery trades ammunition, positioning, and protection for effects at range. Detection and logistics can defeat a nominally more advanced formation.'),
 h('No single strength ladder'),
 p('Use relevant attributes such as detection, concealment, mobility, frontage, protection by threat, fire effectiveness, ammunition endurance, readiness, and repairability. Do not compress every contest into “technology level wins.” Older equipment can remain effective in the right terrain or with better supply, within credible physical limits.'),
 h('The player and the generals'),
 p('The player sets objectives, force priorities, budgets, and strategic constraints through conversation, with optional inspection of designs. Generals execute deployment, engagement, maneuver, and routine logistics. Unit diversity must enrich their decisions and the visible consequences, not revive direct cohort control.'))

MILITARY_ROLES = [
('Early foot and mounted forces',[
'Sling skirmishers','Javelin screens','Foot archers','Crossbow companies','Spear line infantry','Pike formations','Shielded assault infantry','Mounted scouts','Horse archers','Lance cavalry','Chariot detachments','Elephant corps']),
('Specialists and field support',[
'Sappers','Pioneer companies','Pontoon crews','Siege engine crews','Fortress garrisons','Mountain infantry','Mounted couriers','Medical detachments','Ammunition trains','Field repair companies','Signals detachments','Transport columns']),
('Surface naval forces',[
'War canoes','Boarding galleys','Oared missile vessels','Sailing escorts','Ships of the line','Coastal gunboats','Torpedo boats','Destroyer escorts','Cruisers','Battleships','Fleet carriers','Amphibious assault ships']),
('Undersea coastal and naval support',[
'Attack submarines','Missile submarines','Minelayers','Minesweepers','Mine countermeasure vessels','Coastal missile batteries','Harbor defense craft','Submarine rescue vessels','Fleet replenishment ships','Repair tenders','Naval survey ships','Landing craft']),
('Air forces and air support',[
'Observation balloons','Reconnaissance aircraft','Interceptors','Air superiority fighters','Multirole fighters','Close support aircraft','Tactical bombers','Long range bombers','Maritime patrol aircraft','Transport aircraft','Airborne early warning aircraft','Aerial refueling tankers']),
('Mechanized land forces',[
'Motorized infantry','Mechanized infantry','Tracked reconnaissance vehicles','Light tanks','Medium maneuver tanks','Heavy breakthrough tanks','Main battle tanks','Tank destroyers','Armored personnel carriers','Infantry fighting vehicles','Recovery vehicles','Bridging vehicles']),
('Fire support and modern specialists',[
'Mortar sections','Towed field artillery','Self propelled artillery','Rocket artillery','Anti tank teams','Air defense gun batteries','Surface to air missile units','Counterbattery radar teams','Electronic attack teams','Counter drone teams','Air assault infantry','Special reconnaissance teams']),
('Future and strategic forces',[
'Uncrewed reconnaissance swarms','Remote combat aircraft','Uncrewed surface scouts','Autonomous mine clearance teams','Robotic resupply detachments','Directed energy defense units','Persistent high altitude sensors','Space surveillance detachments','Orbital inspection craft','Orbital repair craft','Planetary defense interceptors','Deep space communications protection teams'])]

for start in [0,4]:
    blocks=[p('These role families span different operating periods. They are not all simultaneously available, not one fixed upgrade sequence, and not 96 separate population agents. Each requires a defined operating model, equipment, personnel, training, and support.')]
    for title,roles in MILITARY_ROLES[start:start+4]:
        blocks += [h(title),p('; '.join(roles)+'.')]
    blocks += [p('Variants within a role may use different armor, weapons, hulls, propulsion, sensors, or local materials. A variant earns a distinct profile only if it changes tactical use, sustainment, environment, or cost. Future roles require the confidence and capability review used by the rest of the catalog.')]
    page('Military role inventory '+('from early forces to fleets' if start==0 else 'from aviation to future forces'),*blocks)

page('Military research is more than weapons',
 table(['Research branch','Examples','What changes'],[
 ['Weapons and effects','Bow construction, crossbows, rifling, ammunition, fire control, guidance','Range, accuracy, target effects, rate of fire, manufacture, and supply'],
 ['Protection and survival','Shields, armor, compartmentation, damage control, camouflage, active protection','Survival against particular threats and burdens of weight or complexity'],
 ['Mobility and platforms','Animal handling, hulls, engines, suspension, airframes, propulsion','Terrain access, operational reach, transport demand, and repair'],
 ['Sensing and communication','Scouts, signals, radio, radar, sonar, electronic support, networks','What a commander can know, how quickly orders arrive, and what can be disrupted'],
 ['Organization and doctrine','Drill, staff work, reserve systems, combined arms, convoy defense, carrier operations','Coordination, initiative, frontage, response, and operational behavior'],
 ['Sustainment and medicine','Supply trains, repair, standard parts, evacuation, replenishment, bases','Readiness over distance and time, replacement throughput, and recovery']],[1.6,2.7,2.5]),
 p('Civilian discoveries provide many foundations. Metallurgy, optics, medicine, computation, transport, and energy should not be duplicated as separately stacked military technologies. A military application becomes its own node when it adds a distinct design, doctrine, production method, or operating capability.'),
 h('Learning through practice'),
 p('Exercises, trials, maintenance records, and returned combat observations inform doctrine. Losses are not a research currency. An organization must compare evidence and train people to change behavior. A doctrine discovered by one staff does not instantly retrain every formation.'),
 h('Countermeasures keep the graph alive'),
 p('Fortifications and siege methods, armor and penetration, submarines and detection, radio and electronic attack, drones and air defense create continuing branches. Their effectiveness depends on deployment, intelligence, and resources. There is no universal hard counter detached from engagement conditions.'))

page('A complete military branch example',
 h('From protected infantry movement to combined mechanized forces'),
 p('Scientific and industrial foundations: combustion or suitable electric drive, load-bearing structures, precision components, fuels or storage, maintainable running gear, and vehicle manufacture. Weapon and armor research determine what a design can mount and survive. Radio or other communication determines how formations coordinate.'),
 p('Alternative acquisition routes: develop a local chassis; adapt an existing civilian vehicle; buy foreign vehicles and instructors; negotiate licensed assembly; or purchase research into a specific engine, protection system, or suspension. An adapted truck, armored carrier, and tracked fighting vehicle solve different problems rather than acting as interchangeable steps.'),
 h('What must happen before an operational unit exists'),
 bullets('Build or purchase the actual equipment and deliver it.', 'Recruit the operators, dismounts, maintainers, and support personnel from conserved population.', 'Train crews and formation leaders; accumulate practical readiness.', 'Provide ammunition, fuel or power, repair parts, recovery equipment, and usable routes.', 'Place the formation under the existing command hierarchy and give its general an objective.'),
 h('A meaningful fork'),
 p('Wheeled formations can offer lower operating burdens and useful road mobility; tracked formations can offer different off-road performance and protection at greater support cost. Local terrain, bridges, fuel, industrial skill, and enemy threats decide their value. Do not hard-code one as the universal upgrade.'),
 h('Dependence as military vulnerability'),
 p('A purchased fleet of vehicles may arrive much sooner than a domestic design. It can still become a strategic liability when ammunition, specialized parts, technical documentation, or trained maintenance depend on the seller. A later purchase of engineering research can accelerate domestic substitution. Treaty termination interrupts only the inputs and services actually controlled by the source.'),
 h('Verification'),
 p('Test the same force with and without spares; the same design under different terrain and logistics; imported equipment with inadequate training; and a general adapting to a threat rather than choosing the highest nominal technology. The resulting battle or readiness change must come from the simulation, not an illustrative report alone.'))
