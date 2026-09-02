extends RefCounted

# Broad capability scales used to summarize what a civilization can actually do.
# These are not a technology tree and are never presented as a list of things to
# unlock. Thousands of contingent discoveries create the path; these nine bands
# only give the simulation a bounded way to describe the resulting social scale.

const DOMAINS:Array[String]=[
	"demography","nutrition","health","labor","knowledge","production",
	"infrastructure","logistics","ecology","institutions","security","culture"
]

const ERA_NAMES:Array[String]=[
	"FOUNDING","SETTLED","URBAN","REGIONAL","STATE","INDUSTRIAL",
	"NATIONAL","GLOBAL","PLANETARY"
]

# Population is a requirement for coordination at scale, never a victory score
# or a cap. The final milestone is deliberately several billions rather than a
# magic one-billion finish line; populations may continue indefinitely.
const POPULATION_FLOORS:Array[float]=[
	1.0,250.0,5_000.0,50_000.0,500_000.0,5_000_000.0,
	50_000_000.0,500_000_000.0,5_000_000_000.0
]
const SETTLEMENT_FLOORS:Array[int]=[0,1,1,2,4,8,16,32,64]
const CAPACITY_FLOORS:Array[float]=[0.0,0.16,0.24,0.34,0.44,0.54,0.64,0.74,0.84]
const EVIDENCE_FLOORS:Array[int]=[0,1,3,6,12,20,32,48,72]
const ADOPTION_FLOORS:Array[float]=[0.0,0.02,0.04,0.08,0.14,0.22,0.34,0.48,0.62]
const REACH_FLOORS:Array[float]=[0.0,0.0,0.0,0.05,0.12,0.24,0.40,0.62,0.86]

# A civilization cannot climb the broad scale from one lucky idea. It needs a
# growing body of established findings, multiple lived subconditions, distinct
# investigative traditions, and mature lines of practice. All values are fixed
# per civilization and independent of its population count.
const DISCOVERY_COUNT_FLOORS:Array[int]=[0,1,4,10,20,36,60,96,144]
const MATURITY_FLOORS:Array[int]=[0,1,2,3,4,5,7,9,12]
const BREADTH_FLOORS:Array[int]=[0,1,2,3,4,4,4,4,4]
const LENS_FLOORS:Array[int]=[0,1,2,3,4,5,6,7,8]

const DOMAIN_PURPOSE:Dictionary={
	"demography":"Population renewal, survival, age structure, and life-course support.",
	"nutrition":"Reliable food, dietary quality, reserves, and land productivity.",
	"health":"Prevention, sanitation, treatment, and population-wide care.",
	"labor":"Sustainable work, specialization, coordination, and automation.",
	"knowledge":"Observation, education, science, communication, and shared understanding.",
	"production":"Tools, craft, industry, standards, and material throughput.",
	"infrastructure":"Housing, public works, utilities, networks, and resilience.",
	"logistics":"Movement, storage, trade, information flow, and global supply.",
	"ecology":"Land health, recovery, pollution control, and planetary limits.",
	"institutions":"Legitimate administration, law, public capacity, and governance.",
	"security":"Public safety, defense, crisis readiness, and collective security.",
	"culture":"Cohesion, legitimacy, pluralism, memory, and common identity."
}

const SUPPORT_DOMAINS:Dictionary={
	"demography":["health","nutrition"],"nutrition":["ecology","logistics"],
	"health":["knowledge","infrastructure"],"labor":["health","institutions"],
	"knowledge":["culture","infrastructure"],"production":["knowledge","labor"],
	"infrastructure":["production","institutions"],"logistics":["infrastructure","production"],
	"ecology":["knowledge","institutions"],"institutions":["culture","knowledge"],
	"security":["institutions","logistics"],"culture":["institutions","knowledge"]
}

const MILESTONE_NAMES:Dictionary={
	"demography":["Founding Cohorts","Household Continuity","Urban Vital Rolls","Regional Census","Civil Registration","Demographic Science","National Population System","Global Population Observatory","Planetary Demographic Stewardship"],
	"nutrition":["Shared Provisions","Agrarian Surplus","Urban Provisioning","Regional Granaries","State Food Reserve","Industrial Food System","National Distribution","Global Food Security","Planetary Biosphere Provisioning"],
	"health":["Practical Care","Community Sanitation","Civic Medicine","Regional Hospitals","Public Health Administration","Clinical Health System","Universal Care Network","Global Epidemic Coordination","Planetary Health System"],
	"labor":["Work Rotations","Specialist Crafts","Urban Labor Exchange","Regional Division of Labor","Public Labor Administration","Mechanized Work","National Employment System","Global Workforce Network","Planetary Human–Machine Economy"],
	"knowledge":["Collective Memory","Writing and Teaching","Scholarly Institutions","Print and Public Learning","Scientific Institutions","Mass Education and Research","Digital Computation","Global Knowledge Network","Planetary Knowledge Commons"],
	"production":["Hand Production","Permanent Workshops","Urban Manufactures","Regional Foundries","Standard Manufacture","Industrial Production","Automated Industry","Global Supply Production","Planetary Closed-Loop Industry"],
	"infrastructure":["Founding Shelter","Durable Settlement","Urban Utilities","Regional Corridors","Civic Engineering","Industrial Metropolis","National Grids","Continental Megasystems","Planetary Built Environment"],
	"logistics":["Carrying Parties","Roads and Stores","Ports and Canals","Regional Freight","State Transport Service","Rail, Steam, and Telegraph","Motor and Aviation Networks","Global Real-Time Logistics","Planetary Mobility Network"],
	"ecology":["Landscape Memory","Managed Commons","Watershed Practice","Regional Conservation","Pollution Administration","Restoration Science","National Environmental Standards","Global Climate Coordination","Planetary Boundaries Governance"],
	"institutions":["Founding Council","Formal Custom and Law","Civic Administration","Regional Government","State Bureaucracy","Representative Public State","National Administrative System","Global Institutions","Planetary Governance"],
	"security":["Common Watch","Organized Militia","Fortified Settlements","Professional Forces","State Defense System","Industrial Defense","National Joint Command","Collective Global Security","Planetary Security Architecture"],
	"culture":["Founding Memory","Shared Traditions","Literate Public Culture","Regional Identity","Civic Media","Mass Culture","Plural National Culture","Global Cultural Exchange","Planetary Civic Identity"]
}

const MILESTONE_OUTCOMES:Dictionary={
	"demography":["Six numeric age cohorts make population renewal legible without person records.","Stable shelter and care can sustain growth beyond the founding group.","Births, deaths, housing, and dependents can be planned across a city.","Comparable censuses coordinate migration and services among settlements.","A civil registry measures an entire territorial population in aggregate.","Forecasts connect fertility, mortality, age structure, health, and work.","National-scale cohorts support pensions, education, housing, and labor planning.","Comparable population systems coordinate migration and crisis response worldwide.","Human population can be supported across the full planet without a numeric ceiling."],
	"nutrition":["Daily production, intake, and reserves are accounted for collectively.","Reliable cultivation and storage can feed a permanent settlement.","Markets, stores, and transport provision dense non-farming populations.","Distributed granaries absorb regional harvest failure.","Measured reserves and relief prevent local shortage from becoming state famine.","Mechanized cultivation, preservation, and processing multiply food output.","Cold chains and national distribution move diverse food at population scale.","International reserves and exchange respond to continental food shocks.","Food production operates within planetary water, soil, climate, and biodiversity limits."],
	"health":["Clean water, wound care, and maternal practice reduce immediate mortality.","Waste, water, and isolation practices protect a permanent community.","Dedicated carers and facilities make treatment a civic capacity.","Referral, records, and supply connect care across settlements.","Surveillance and sanitation make prevention a state responsibility.","Laboratories, clinical standards, and manufactured medicine transform survival.","Population-wide access makes health a durable national system.","Shared surveillance and response contain threats that cross every border.","Human health is managed with climate, ecology, movement, and the whole biosphere."],
	"labor":["Aggregate role allocations distribute essential work without individual simulation.","Regular specialists preserve craft and technique across generations.","Dense settlements coordinate employers, workers, apprentices, and public duties.","Transport and standards permit specialization among whole regions.","Institutions measure labor supply, obligations, safety, and public works.","Machines multiply output while changing skill, injury, and resource demands.","Education, labor law, and employment systems coordinate tens of millions.","Remote work, migration, automation, and supply chains form one world labor system.","Human work and automation are coordinated planet-wide without person-level runtime state."],
	"knowledge":["Observation and memory preserve useful differences from lived experience.","Records and organized teaching carry knowledge beyond direct witnesses.","Dedicated schools and scholars sustain criticism across generations.","Reproducible texts widen literacy, administration, and experimental exchange.","Publicly supported research connects measurement, replication, and theory.","Mass education creates a broad population able to use and extend knowledge.","Computation and electronic communication transform storage, modeling, and coordination.","A worldwide network shares evidence fast enough for planetary problems.","Knowledge is preserved, verified, and accessible as a planetary common capacity."],
	"production":["Materials are transformed with hand tools and bounded aggregate workshops.","Permanent specialists and stores raise consistent output.","Dense workshop districts support complex chains of intermediate goods.","Energy, transport, and standards connect specialized regional production.","Interchangeable measures and public procurement enable large manufactures.","Mechanized energy and factories multiply output per worker.","Automation and national standards coordinate high-volume complex production.","Components and materials move through a worldwide production system.","Industry closes material loops and operates within planetary resource budgets."],
	"infrastructure":["Aggregate shelter capacity protects the founding population.","Durable housing, water, paths, and stores support a permanent settlement.","Utilities and public works support dense urban life.","Roads, bridges, ports, and water systems connect multiple settlements.","State engineering coordinates standards, maintenance, and disaster response.","Power, sanitation, transit, and dense construction support industrial cities.","National energy, water, transport, and communication grids become interoperable.","Continental systems provide redundancy across borders and hazards.","The full planet is served by resilient, maintained, ecologically bounded infrastructure."],
	"logistics":["Carriers and route memory move provisions beyond immediate ground.","Maintained paths and distributed stores link a settlement network.","Ports, canals, warehouses, and accounts sustain urban exchange.","Scheduled freight joins specialized regions into one material economy.","A state service coordinates mail, roads, stores, and strategic movement.","Rail, steamships, and telegraph collapse continental time and distance.","Motor, aviation, container, and communications networks reach a whole nation.","Live information coordinates worldwide movement of goods, people, and aid.","Planet-scale mobility remains redundant, accountable, and within ecological limits."],
	"ecology":["Observed seasonal limits constrain gathering and extraction.","Shared rules prevent immediate commons from being exhausted.","Water, soil, forest, and waste are managed as connected local systems.","Regions coordinate conservation beyond one settlement's boundary.","Measurement and enforcement make pollution a public responsibility.","Ecological science restores damaged systems as well as limiting harm.","National standards manage air, water, habitat, extraction, and cumulative risk.","Climate, oceans, biodiversity, and pollution require binding global coordination.","Civilization remains inside measured planetary boundaries while supporting billions."],
	"institutions":["A founding council makes collective choices and records obligations.","Known procedures outlast particular disputes and leaders.","Specialized offices administer an urban population and public works.","Multiple settlements share law, revenue, representation, and services.","A territorial state can reliably implement policy across distance.","Professional administration and representation constrain and extend public power.","National systems deliver law, welfare, infrastructure, and crisis response at scale.","Treaties and global bodies govern problems no state can solve alone.","Legitimate institutions coordinate the full planet while preserving accountable local rule."],
	"security":["A rotating watch protects people, stores, and warning routes.","Training, command, and supply create organized collective defense.","Fortification and permanent readiness defend dense settlement systems.","Specialized forces and staffs operate across a region.","A state integrates intelligence, logistics, mobilization, law, and military command.","Industrial supply and communications reshape both war and civil protection.","Joint national commands protect infrastructure, population, and territory.","Collective institutions deter major war and coordinate transnational crisis response.","Planetary security addresses war, disaster, systemic technology, climate, and space hazards."],
	"culture":["Shared memory gives the founding group continuity and mutual obligation.","Traditions, ritual, and teaching reproduce identity across generations.","Literacy and public gathering permit debate beyond kin and household.","Connected settlements form regional identities without erasing local difference.","Civic media and institutions create a territorial public sphere.","Mass education and communication produce shared culture at industrial scale.","A plural national culture can coordinate diversity without requiring uniformity.","Worldwide exchange makes distant lives visible while sustaining distinct traditions.","A planetary identity supports common obligations without deleting local peoples or cultures."]
}

static func all_nodes()->Array[Dictionary]:
	var nodes:Array[Dictionary]=[]
	for domain in DOMAINS:
		nodes.append_array(nodes_for_domain(domain))
	return nodes

static func nodes_for_domain(domain:String)->Array[Dictionary]:
	var nodes:Array[Dictionary]=[]
	if domain not in DOMAINS: return nodes
	var names:Array=MILESTONE_NAMES[domain]
	var outcomes:Array=MILESTONE_OUTCOMES[domain]
	for tier in ERA_NAMES.size():
		var prerequisites:Array[String]=[]
		if tier>0: prerequisites.append(node_id(domain,tier-1))
		if tier>=2:
			for support in SUPPORT_DOMAINS[domain]: prerequisites.append(node_id(String(support),tier-1))
		nodes.append({
			"id":node_id(domain,tier),"domain":domain,"tier":tier,"era":ERA_NAMES[tier],
			"name":String(names[tier]),"purpose":String(DOMAIN_PURPOSE[domain]),
			"outcome":String(outcomes[tier]),"population_floor":POPULATION_FLOORS[tier],
			"settlement_floor":SETTLEMENT_FLOORS[tier],"capacity_floor":CAPACITY_FLOORS[tier],
			"evidence_floor":EVIDENCE_FLOORS[tier],"adoption_floor":ADOPTION_FLOORS[tier],
			"reach_floor":REACH_FLOORS[tier],"requires":prerequisites
		})
	return nodes

static func node(domain:String,tier:int)->Dictionary:
	if domain not in DOMAINS or tier<0 or tier>=ERA_NAMES.size(): return {}
	return nodes_for_domain(domain)[tier]

static func node_id(domain:String,tier:int)->String:
	return "%s_%02d" % [domain,tier]

static func era_name(tier:int)->String:
	return ERA_NAMES[clampi(tier,0,ERA_NAMES.size()-1)]
