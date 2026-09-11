"""Authored review content. Proposals are not implemented game features."""
PAGES = []
def page(title, *blocks):
    PAGES.append((title, list(blocks)))
def p(text): return ('p', text)
def h(text): return ('h', text)
def bullets(*items): return ('bullets', list(items))
def table(headers, rows, widths=None): return ('table', headers, rows, widths)

page('Technology and civilization across all history',
 p('Tomorrow and Tomorrow'),
 p('Design proposal for Sean Purtill  •  Review draft 1  •  September 10 2026'),
 p('We should build a vast, interconnected discovery network that carries a society from early human survival through the future of humanity. Technology should change what people can do, how they live, what their leaders can attempt, and which other societies they depend on. It must remain a central source of surprise and strategic choice throughout the 2,500–3,000-year campaign.'),
 p('The defining branching rule is access with consequences. A civilization that misses a strong route can still reach the technology through slower, disadvantageous routes: foreign research, partnerships, acquired expertise, and the difficult rebuilding of its own foundations. Early choices determine timing, independence, cost, and bargaining power. They do not permanently remove human possibilities.'),
 h('The proposed scale'),
 p('Plan for 5,000 distinct, authored discoveries across 24 connected fields. This document includes a 600-entry candidate atlas, worked branch designs, acquisition rules, campaign pacing, future frontiers, and acceptance criteria. The 5,000 figure is a production target for review, not a claim that 5,000 finished nodes or their complete prerequisite graph have been authored here.'),
 p('A discovery earns its place by adding a distinct mechanism, useful practice, institution, production method, or strategic capability. Repeated maturity labels, alternate translations, art variants, and different routes to the same discovery do not inflate the count.'),
 h('The decision requested'),
 p('Review the branching contract, historical breadth, future boundaries, and campaign timescale before implementation and mass artwork production. This draft proposes the system; it does not change the player game.'),
 ('cover_art', None))

page('How to review this proposal',
 p('Start with the branching contract and route comparison, then read the worked branches. The candidate atlas provides breadth: 25 concrete subjects in each of 24 fields. Those subjects are an editorial starting set, not 600 automatic unlocks or 600 mandatory clicks.'),
 table(['Review area','Recommendation'],[
 ['Access to knowledge','All supported capabilities remain reachable in principle. Missing a favorable route creates dependence or delay.'],
 ['Scale','A 5,000-discovery authoring target with individual causal and historical review.'],
 ['Branch structure','Alternative foundations, cross-field combinations, and reconvergence on one discovery record.'],
 ['Player role','Give leaders objectives and research priorities; inspect or override a project when useful.'],
 ['Campaign','A fictional 2,500–3,000-year civilization history with condition-led progression and optional continuation.'],
 ['Future','Substantial planetary and space development, with uncertain engineering treated explicitly.']],[1.45,5.35]),
 h('Authority of the rules'),
 p('Your instructions in this conversation are authoritative. Recovered repository requirements include thousands of seeded routes, concrete consequences, physical information travel, gradual adoption, equal rules for rivals, aggregate population, and a long civilization lifecycle. Your clarification adds the decisive interpretation: disadvantaged branches can recover through dependence and partnerships.'),
 p('Proposed additions are the 24-field editorial taxonomy, 5,000-node allocation, route cost model, future confidence classes, and quantitative verification targets. These are offered for review rather than presented as previously approved rules.'),
 h('Important limits of this draft'),
 p('The worked dependencies are game design proposals, not claims that every civilization in real history followed those sequences. The 600 atlas entries need individual effects, prerequisites, sources, and implementation contracts before becoming production nodes. The source notes ground selected historical and engineering distinctions; they are not an individual historical audit of all 600 candidates.'),
 p('The requested paper-and-gouache aesthetic remains the art direction. Asset generation resumes after the technology identities and display rules are agreed.'))

page('The verified gap in the current game',
 p('At source revision 940d5a2, the initialized live technology catalog contains 197 entries. The older frontier catalog still defines 4,608 combinations: 12 domains, four subconditions, eight evidence traditions, and twelve maturity stages. An explicit eligibility check excludes every entry marked frontier from player and rival research. [R1–R3]'),
 table(['Finding','Design implication'],[
 ['197 live discoveries','The authored list is useful existing work, but is too narrow to establish the intended historical and future breadth.'],
 ['4,608 disabled combinations','Their count represents repeated traditions and maturity levels. Restore the ambition while replacing repetition with distinct content.'],
 ['Latest live earliest gate near year 268','This is an eligibility floor, not a measured completion time. The catalog does not demonstrate millennial pacing.'],
 ['58 of 197 entries are security','Civilian institutions, culture, household life, ecology, and modern science need much deeper representation.'],
 ['15 authored alternative foundation routes','Existing reconvergence and exchange machinery provide a starting point, not a complete branching architecture.']],[2.25,4.55]),
 p('The retirement first appears in the accessible history at checkpoint bac2035 on September 4. That broad checkpoint does not establish the original discussion or approval behind the decision. The current README describes 150 authored technologies and is behind the live count. [R1–R4]'),
 h('What we retain'),
 p('Retain useful existing discoveries, their stable identities, earned knowledge, and integration with real resources and social systems. Retain the distinction between hearing of something and operating it. Keep the current civic and military ownership rules.'),
 h('What must change'),
 p('Replace the finite early-heavy progression with an expansive causal network. Extend viable inquiry into modern civilian life and future capabilities. Make route dependence visible. Test the entire campaign under ordinary research rules, including rival societies, rather than treating a short accelerated fixture as proof.'),
 p('This review makes no gameplay changes and does not reactivate the old combinations.'))

page('The branching contract',
 bullets(
 'Reachability survives a missed branch. A lost opportunity may close a convenient local route, but a supported capability remains recoverable through another causal route, imported practice, partnership, or rebuilding foundations.',
 'Different means can solve the same problem. Preserving food can involve drying, smoking, salting, fermentation, cooling, or later refrigeration. These are distinct methods with different requirements, not cosmetic variants.',
 'Some outcomes genuinely combine knowledge. Refrigerated freight needs a cooling mechanism, power, insulation, vehicles or vessels, maintenance, and an operating organization. An OR route cannot silently remove an indispensable physical requirement.',
 'Routes reconverge on one discovery. Learning a method locally and later studying a foreign example improves evidence or proficiency where appropriate; it does not award the discovery bonus twice.',
 'A favorable independent route provides the strongest position. It gives earlier mastery, control over dissemination, a local skill base, and freedom from a supplier’s terms.',
 'Fallbacks have visible disadvantages. They involve waiting for another society, travel, negotiations, payments, restricted teaching, integration work, or dependence on imported equipment and maintenance.',
 'The world changes route economics. Climate, accessible materials, transport, labor, institutions, and inherited practice make different routes attractive. A culture label cannot make a people intellectually incapable.',
 'Knowledge and operation are separate. A society can understand a process without the materials or infrastructure to deploy it. Purchasing its output does not automatically teach the process.',
 'Unknown outcomes remain unknown. Show observable problems and plausible investigations. Reveal a named foreign invention only through actual evidence or reports.',
 'Every civilization obeys these rules. Difficulty changes decision quality and uncertainty management, not free discoveries or hidden research multipliers.'),
 p('These rules preserve branching without turning the tree into a sequence of irreversible doors. Strategic loss is real: a civilization can spend generations paying for something its neighbor controls. Recovery is also real.'))

page('The routes to the same technology',
 table(['Route','What it requires','Why it can be worse'],[
 ['Independent discovery','Local foundations, evidence, people, equipment, and sustained inquiry','Research risk and upfront investment; success creates autonomy.'],
 ['Rebuild a missed route','Missing foundational practices and the means to teach them','Longer prerequisite chain and opportunity cost before useful output.'],
 ['Foreign instruction','A willing knowledgeable source, actual contact, negotiated terms, and traveling teachers or records','Arrival delay, fees, restricted scope, and time to reproduce the practice.'],
 ['Research partnership','Complementary partners, agreed contributions, communication, and a real joint program','Coordination delay, shared control, obligations, disclosure, and exit risk.'],
 ['Licensed production','Permission, local plant, training, inputs, and testing','Royalties, tool or part dependence, export restrictions, and limited design knowledge.'],
 ['Reverse engineering','An acquired example, instruments, skilled study, and underlying science','Incomplete information, uncertain failures, and redesign work.'],
 ['Imported service','Transport, payment, a supplier, and access to the product or service','The capability can disappear when supply stops; no automatic local mastery.']],[1.3,2.65,2.85]),
 p('Partnership is a meaningful fallback, not a fake button with a universal penalty. A small society may accomplish something with partners that it cannot presently fund alone. It still accepts obligations and reduced independence. A successful independent pioneer does not lose its lead because a neighbor clicked “partner.”'),
 h('Fair comparison'),
 p('Compare total time from opportunity to reliable local operation, not just the research bar after foreign knowledge arrives. A follower must first wait for someone to discover and adopt the method, learn that it exists, secure access, receive the knowledge, and reproduce it. A follower can recover faster than starting everything over while still arriving later and paying more for dependence.'),
 p('An ally that receives reliable joint results is a co-developer where it actually contributed; a client buying instructions is a dependent learner. The interface and history must distinguish them.'))

page('Making dependence measurable',
 p('Illustrative balance example, not historical timing: two societies begin with comparable foundations for mechanically refrigerated freight. Their local circumstances and research priorities may differ; the numbers below are a controlled comparison of route mechanics.'),
 table(['Event','Independent pioneer','Dependent follower'],[
 ['Years 0 to 8','Runs trials and develops a reproducible design','Chooses another priority; no local design work'],
 ['Years 8 to 10','Builds plant and trains operators','Receives a dated report after discovery'],
 ['Years 10 to 12','Operates and improves the system','Negotiates a license and receives equipment'],
 ['Years 12 to 15','Has an established maintenance workforce','Builds compatible facilities and trains staff'],
 ['At year 15','Controls designs and local servicing','Operates under a royalty and parts agreement'],
 ['Subsequent choices','License, withhold, improve, or standardize','Keep paying, diversify, partner, or fund local mastery']],[1.4,2.7,2.7]),
 p('Payments transfer value between real ledgers. A royalty cannot be a cost to one side with no recipient. Imported machines, spare parts, teachers, and confidential documents must physically arrive. A relationship panel should explain who can interrupt which input and how long the local reserve lasts.'),
 h('A path back to independence'),
 p('The follower can train engineers, study failures, develop substitute components, and validate a locally maintained design. This creates a bounded program with clear milestones. It does not force endless license renewal or erase acquired knowledge when a treaty ends. Losing the supplier interrupts dependent production according to actual stocks and skills.'),
 h('What cannot be allowed'),
 bullets('No instantaneous teaching across an unknown map.', 'No duplicate discovery effects through repeated licenses or gifts.', 'No automatic technology seizure when a city falls.', 'No artificial forgetting of understood physics after a diplomatic dispute.', 'No permanently inaccessible basic capability because a seed removed its only route.'),
 p('The dependency model is a proposed extension of the existing exchange system. Current code does not implement all of these agreements or production constraints.'))

page('The structure of a discovery',
 p('A discovery is a stable capability or body of knowledge. Routes explain how it can be learned. Deployment explains where it is actually used. This separation lets a large network remain coherent and prevents every import, maturity step, and local variation from becoming a duplicate technology.'),
 table(['Record','Required content'],[
 ['Identity','Stable ID, concrete name, field, scope, source confidence, and plain description'],
 ['Causal foundation','Necessary concepts or capabilities expressed as explicit AND and OR groups'],
 ['Acquisition routes','Independent routes, evidence routes, partnership requirements, and rebuilding alternatives'],
 ['Evidence','Observable triggers, experiments, reproduction criteria, provenance, and uncertainty'],
 ['Operating requirements','Materials, energy, tools, people, infrastructure, organization, and maintenance'],
 ['Consequences','New actions or recipes; constraints removed; costs, externalities, and affected social groups'],
 ['Diffusion','Teachability, tacit skill, reproduction difficulty, interoperability, and dependence'],
 ['Presentation','Unrevealed question, revealed title, discovery account, art brief, and contextual successors']],[1.45,5.35]),
 h('A readable eligibility expression'),
 p('Useful refrigerated freight requires: a reproducible cooling method AND suitable insulation AND an adequate power source AND freight handling. The cooling method may come from a locally developed compressor route OR a locally developed absorption route OR acquired design knowledge that the receiving society can reproduce. Imported know-how does not bypass the power and insulation requirements.'),
 h('One graph and several relationships'),
 p('Scientific prerequisites form a directed acyclic graph. Teaching, trade, rivalry, licensing, and feedback may form networks with cycles; they belong to different relationship types. “Better instruments help science, and science helps instruments” must be modeled through successive explicit capabilities, not a prerequisite loop that makes both impossible.'),
 p('An editor can inspect all content. A player sees only known work, named evidence, and plausible nearby questions. The presentation must not expose the hidden graph through searches, disabled labels, artwork, or hover text.'))

page('From an observation to a changed society',
 table(['Stage','What happens','What the player sees'],[
 ['Observation','Practice, a problem, an artifact, or an anomaly supplies evidence','A useful question with a source and a reason to care'],
 ['Investigation','Assigned people test an approach using actual resources','An approach, progress, constraints, and competing advice'],
 ['Reproduction','A result works beyond one fortunate trial','What was established and what remains uncertain'],
 ['Demonstration','A workshop, clinic, field, or machine proves practical operation','A visible first use and its measured tradeoffs'],
 ['Adoption','Operators train and suitable sites change practice','Actual adoption by relevant population or production share'],
 ['Maintenance and transfer','Practice is repaired, taught, standardized, or adapted','Benefits sustained, spread, or constrained by local conditions']],[1.3,2.8,2.7]),
 p('These are states of a discovery, not six separately counted technologies. A new method becomes a separate node only when its mechanism or capability changes. Failure may produce evidence, but repeating a cheap failed trial cannot manufacture unlimited research.'),
 h('Routine life creates knowledge'),
 p('Farmers, builders, caregivers, navigators, miners, artists, and administrators generate observations through real activity. Formal researchers compare and extend that evidence. Early societies should not need a modern laboratory institution to discover cordage or better storage.'),
 h('Institutions preserve and reproduce it'),
 p('Apprenticeship, teaching, archives, professional exchange, workshops, and later laboratories increase continuity and reproducibility. Written records are valuable, but oral and embodied traditions remain valid knowledge carriers. Losing a library harms what depended on that library; it does not instantly erase every skill in the population.'),
 h('Authority stays with existing systems'),
 p('GovernmentPeopleSystem remains the owner of civic officials and daily labor. HistoricalFigures records exceptional contributors rather than a duplicate research workforce. Generals execute military operations in every period. Research programs request resources and communicate objectives through those owners.'))

page('Campaign time and historical breadth',
 p('Actual human technological history spans far more than 3,000 years; early stone tool traditions alone extend deep into prehistory. A literal Earth chronology cannot fit inside the requested campaign duration. [H1] We must make that design choice explicit.'),
 h('Recommended interpretation'),
 p('The standard game is a fictional civilization history lasting roughly 2,500–3,000 simulated years, covering the breadth of human technological development at a deliberately compressed pace. Days, seasons, travel, aging, and supply keep one coherent simulation calendar. Earth dates are research references, not global unlock dates or a second hidden clock.'),
 p('The opening society consists of humans capable of language, learning, and cooperation, with a small survival repertoire. A deep-prehistory starting scenario can begin with more elementary tool and fire practices. Biological human evolution is not silently compressed into the campaign; an evolutionary prologue would be a separate scope decision.'),
 h('A tuning envelope rather than an era lock'),
 table(['Campaign years','Expected breadth in a viable reference run'],[
 ['0 to 250','Survival, local materials, food, movement, social memory, and durable settlement options'],
 ['250 to 900','Intensification, cities, writing alternatives, metallurgy, maritime networks, civic specialization'],
 ['900 to 1700','Complex institutions, experimental sciences, precision trades, print, regional and ocean exchange'],
 ['1700 to 2250','Mechanization, public health, electricity, mass systems, modern measurement and communications'],
 ['2250 to 2650','Computation, advanced medicine, planetary systems, mature aviation and space access'],
 ['2650 to 3000 and beyond','Advanced planetary and space industry, biological and institutional futures']],[1.5,5.3]),
 p('These overlapping targets guide balance tests, not mandatory player epochs. Exceptional societies can lead in one field and lag in another. Collapse, isolation, and recovery alter trajectories. Research should not wait on a date after the necessary capabilities genuinely exist. Conversely, a large workforce cannot replace missing evidence, precision, or industrial chains.'),
 p('The player may continue beyond the legacy review. Future content must be substantial before year 3,000 in successful reference campaigns; it cannot consist of a final cinematic or a single “Future Technology” repeatable.'))

page('Keeping discovery engaging for thousands of years',
 p('The player directs a civilization, not thousands of individual progress bars. At any moment, leaders bring a small set of consequential questions: secure winter food, reduce deaths in childbirth, free workshops from a foreign fuel supplier, or establish a reliable route to an orbital settlement.'),
 h('Different scales of attention'),
 bullets('A strategic objective links a problem to several plausible research programs and operating changes.', 'A program funds a coherent line of work and delegates routine project selection to responsible leaders.', 'A discovery report explains a concrete breakthrough and its immediate consequences.', 'The atlas lets interested players inspect every known dependency, rival report, local bottleneck, and alternative route.'),
 h('Reasons to change course'),
 p('A new specimen opens a cheaper route. A partner withholds a crucial component. An old technology becomes valuable in a new climate or supply crisis. A rival’s reported success creates a reason to study its methods. A breakthrough in measurement unlocks work in medicine and navigation at once. These are changes in available actions, not random bonus cards.'),
 h('Notification discipline'),
 p('Routine completions enter a digest; the player can mark fields or projects for immediate notice. First successful uses, serious research failures, a strategically important foreign dependency, and leader requests receive prominent reports. Full detail remains available. This would revise the current rule that every new player discovery opens a pause popup, which would become exhausting at this scale.'),
 h('Pacing without invented simulation'),
 p('The existing documented maximum of three days per second implies about 84.5 hours for 2,500 years before pauses or stalls. [R6] Introduce bounded advance-to-report and scalable quiet-time presentation. Research, travel, births, deaths, and resource balances still advance under their rules. Optimization must preserve an equivalent event sequence within a stated tolerance; do not simply award a century of progress.'),
 p('Proposed playtest criteria: a useful opening discovery in the first 5–10 minutes; several materially different priorities visible in each session; no mandatory response to minor refinements; and meaningful frontier questions in every late campaign segment. These are targets to measure, not claims of current performance.'))

page('Costs and consequences make the network real',
 p('Every production technology changes a recipe, capacity limit, feasible quality, reliability, or usable resource. Its benefits depend on where it is deployed. An unused invention does not improve the whole civilization by a flat percentage.'),
 h('A discovery must change a decision'),
 p('Rotary milling changes the work needed to process grain and can concentrate milling power. Electrification changes where motors can operate but introduces grids, generation, and maintenance. Refrigeration expands useful transport distance for perishable goods while increasing energy demand. A household register changes what the government can administer and what it can observe about people.'),
 h('Benefits do not stack without a mechanism'),
 p('Replacing an older furnace substitutes its operating recipe. It does not retain every historical efficiency bonus and multiply them forever. Shared capacity limits, adoption shares, quality bands, and conservation determine output. Retired equipment can remain useful in a low-fuel locality, and simultaneous processes can coexist.'),
 h('Externalities and social consequences'),
 p('Technologies can shift labor demand, ownership, education, disease exposure, pollution, land use, military vulnerability, and political bargaining. Consequences belong to affected groups and places. A printing capability makes cheap reproduction possible; it does not automatically create liberty. A surveillance capability increases observation where deployed; legitimacy depends on institutions and actions.'),
 h('Domestic life belongs in the core'),
 p('Childcare, clean birthing practices, clothing, food preparation, heating, disability access, literacy, repair, sanitation, and household tools deserve the same causal attention as weapons. Their effects change productive time, survival, participation, and everyday living conditions. They provide distinctive scenes and stories across the entire campaign.'),
 h('A content admission rule'),
 p('For every proposed node, write a before-and-after example that names an action or constraint. If the only difference is a name, an illustration, or a generic +1% with no material cause, merge it into another node or represent it as proficiency. That rule protects the 5,000-node target from the repetition that weakened the previous catalog.'))

page('Historical plurality and independent discovery',
 p('The network must represent the breadth of human invention without forcing every society through one regional sequence. Environmental practice, water management, navigation, crops, construction, institutions, medicine, and records have different viable traditions. A historical example is evidence for a mechanism; it is not an ethnic permission gate.'),
 h('Scientific necessity and historical sequence'),
 p('Separate a genuinely necessary capability from something that happened earlier in one place. Agriculture need not require a plough, wheat, large draft animals, or urban government. Long-distance navigation need not require the same instrument everywhere. Printing must accommodate different forms of reproduction rather than a single European invention gate; UNESCO’s account of Korean print history illustrates why. [H2]'),
 h('Coexistence and uneven development'),
 p('A maritime society can be exceptional at navigation and weak at inland transport. A highly literate administrative state may lack domestic heavy industry. A pastoral society can possess sophisticated ecological and logistical knowledge. The game should show these actual strengths rather than assigning one universal “civilization level.”'),
 h('Borrowing preserves history'),
 p('Record which society or contributor supplied evidence, who reproduced the result, and who made it practical locally. Migration, trade, apprenticeship, translated records, traveling experts, and collaboration can all carry knowledge. Transport and trust change the ease of transmission; cultural identity does not determine intelligence.'),
 h('Knowledge can be contested'),
 p('A successful observation can precede its correct theory. Preserve useful practices with uncertain explanations. Competing hypotheses consume effort until evidence discriminates among them. The system should not reward confidently wrong explanations with permanent scientific bonuses, but those explanations can affect institutional choices and future inquiry.'),
 h('Power is an outcome'),
 p('Coercive institutions, colonial extraction, forced labor, and exclusion belong to historical analysis where modeled. They are not universal prerequisites for advancement or free efficiency upgrades. Any represented mechanism carries its actual people, resource, resistance, and institutional consequences. This document proposes a simulation design rather than a claim that one political tradition is history’s endpoint.'))

page('A substantial future with honest uncertainty',
 p('The future should contain many intersecting projects with real dependencies, not a row of guaranteed miracles. A mature civilization can pursue planetary restoration, biological capabilities, automation, resilient institutions, ocean settlement, space industry, or interstellar investigation. These futures can coexist and compete for finite people, energy, materials, and attention.'),
 table(['Confidence class','How it belongs in the game'],[
 ['Demonstrated capability','Historical or contemporary evidence supports the mechanism. Local adoption still requires infrastructure and skill.'],
 ['Demonstrated components','Parts work, but scale, integration, cost, durability, or deployment remains a distinct engineering program.'],
 ['Plausible extrapolation','Known principles support investigation; success and practical limits are uncertain and visible.'],
 ['Open scientific conjecture','Optional speculative scenario content, clearly separated from the grounded default catalog.']],[2.1,4.7]),
 p('NASA’s readiness levels distinguish early concepts from demonstrated systems. The game can use a simpler internal maturity model without claiming that a research paper equals a deployable technology. [F1]'),
 h('Examples that need separate milestones'),
 bullets('Fusion experiments, sustained plant operation, heat recovery, fuel supply, material lifetime, and net electric delivery are different problems. ITER explicitly is not an electricity-generating plant. [F2]', 'Quantum devices, error correction, useful algorithms, and economical operation should not collapse into an all-purpose supercomputer unlock. [F3]', 'Producing oxygen experimentally on Mars is evidence for one process. It does not demonstrate a self-sufficient settlement, an industrial propellant chain, or a transformed planetary atmosphere. [F4]'),
 h('The frontier boundary'),
 p('Include physically grounded orbital habitats, deep-space logistics, closed-loop resource systems, advanced therapies, and powerful computation. Treat radical life extension, autonomous interstellar settlement, and major ecosystem engineering as uncertain programs. Faster-than-light travel, guaranteed mind uploading, and unlimited energy are not default historical outcomes. Their inclusion would require a separately reviewed speculative setting.'),
 p('Future uncertainty must change the route, cost, or achieved performance. It must not become an unexplained random refusal after the player has paid for every advertised prerequisite.'))

page('How the technology web should look and feel',
 p('The atlas should let the player ask “What can we do about this?” and “Why are we dependent?” It must handle thousands of nodes through context and navigation rather than shrinking everything into one unreadable screen.'),
 bullets('Default view: current objectives, a few plausible approaches, important new findings, and actual bottlenecks.', 'Branch view: the selected discovery, its visible prerequisites, alternative acquisition routes, and revealed consequences.', 'Dependency view: known foreign suppliers, licenses, partners, fragile inputs, local reserves, and paths to independence.', 'History view: who discovered or taught a method, how it spread, and what changed afterward.', 'Full atlas: searchable revealed knowledge, filters by field and practical problem, and progressively expanded connections.'),
 h('Different lines carry different meanings'),
 p('Use distinct labeled relationships for necessary foundations, alternative routes, complementary inputs, and foreign instruction. Do not rely only on color. A fork means a choice of means; a convergence means shared knowledge. The inspector states whether a missing item is knowledge, a material, a workshop, trained people, or permission.'),
 h('The approved visual language'),
 p('Use the supplied artwork and approved Apprentice Contracts painting as the aesthetic reference: warm ivory paper, sparse gouache, matte ochre and muted terracotta, charcoal and olive shapes, worn print texture, simplified faces, and generous negative space. The subject is a specific practice, mechanism, or human consequence.'),
 p('Give distinct discovery subjects their own illustration once content is stable. Do not illustrate Stone Selection with generic pottery. Keep hidden topics from leaking through art. Full discovery panels preserve the square composition; compact cards use deliberate layouts that keep people and tools visible rather than blindly cropping the lower half away.'),
 h('A discovery report'),
 p('“Our millwrights have reproduced a water-driven grain mill. Two riverside settlements can adopt it now; the upland settlement lacks reliable flow. Milling labor falls where the mill operates, but seasonal water disputes will need a rule. The builders propose training a second crew.” The numbers come from the simulation, and the illustration shows the wheel and grain handling.'))

page('Three societies and three technological histories',
 h('The inland river society'),
 p('Seasonal floods create a reason to study water, calendars, soil, storage, and civic coordination. Surplus supports specialist construction and records. The society becomes strong in hydraulic works and public administration but lacks some ores. It funds a material partnership with an upland neighbor. When relations deteriorate, it can pay more for imported metal, search farther away, or invest in substitutes. Its earlier strengths still matter.'),
 h('The coastal trading society'),
 p('Fishing, preservation, boat repair, weather, and navigation support a maritime economy. Contact brings valuable evidence and borrowed practices, but reliance on imported precision tools later limits independent shipbuilding. Leaders argue for a domestic toolmaking program. The player can accept generations of dependence or divert resources now. Foreign research provides a route forward without granting the same strategic position as pioneering those processes locally.'),
 h('The dryland mobile society'),
 p('Water storage, animal care, route memory, portable shelter, textile repair, and negotiated access make mobility viable. Dense settlement is an option rather than a universal early requirement. Local resources favor solar energy and later distributed systems; water-intensive heavy industry remains costly. The society can obtain that industry through partnerships, imports, or building the supporting infrastructure. Its earlier mobility knowledge can support transport and remote operations.'),
 h('A late convergence'),
 p('All three can eventually participate in a planetary communications network. They arrive with different material chains, organizations, bargaining power, standards, and local expertise. The river society may finance it, the coastal society carry components, and the dryland society host remote stations. None receives a fixed ethnic bonus, and no branch makes the technology permanently forbidden.'),
 h('What a replay must demonstrate'),
 p('Different geography and choices should produce different affordable routes and sequences. Comparable decision quality should not lead to one mandatory opening in every world. These are scenario sketches for testing. They are not claims that the current game produces these histories.'))

page('The simulation architecture that supports the breadth',
 p('Separate immutable content from changing society state. The full authored catalog stores concepts, routes, effect definitions, and references. Each civilization stores compact known-state, evidence, adoption, dependence, and active-work records. No research workload scales with individual people.'),
 h('A bounded working set'),
 p('Index prerequisites and route triggers so a discovery, arriving report, changed resource access, or new institution revisits only affected candidates. Advance active investigations and relevant adoption cohorts; do not scan every possible route for every person on every day. The interface renders a bounded visible subgraph and loads only nearby artwork.'),
 h('State that must not be lost'),
 p('Completed discovery IDs are durable. A compact record for every known capability is bounded by the catalog, not by population or elapsed days. Keep current obligations, critical evidence, and active agreements. Detailed narrative history may be capped or summarized, but eviction of a report must not erase a discovery or cancel a real debt.'),
 h('Authority and parity'),
 p('Use the existing WorldSimulation and society ownership boundaries. GovernmentPeopleSystem supplies civilian labor; ResourceSystem and city ledgers own physical stocks; military systems own formations and operational doctrine. The technology layer changes capabilities and requests work through those interfaces. Opponents use the same route eligibility, learning, adoption, and payment code.'),
 h('Determinism and generative text'),
 p('World seeds may shape which local opportunities appear and how difficult they are, but not change physical law or secretly remove every recovery route. Store route origins and stochastic state so reloading does not reroll a result. Language models may explain evidence and suggest priorities; they cannot invent a new resource, prerequisite bypass, or completed discovery at runtime.'),
 h('When a model is missing'),
 p('A future node that requires a new power grid, orbital logistics, industrial chemistry, or public health model is marked as awaiting that system. A named technology and a +5% placeholder are not a delivered capability. Research content and its operating model must be integrated together.'))

page('Content production and migration',
 h('A production unit is a connected branch'),
 p('Author and deliver connected branches containing early foundations, alternative routes, later applications, social consequences, and at least one cross-field connection. A branch is complete when the player and an opponent can discover, reproduce, use, teach, lose access to, and recover its capabilities under ordinary rules.'),
 table(['Stage','Required result'],[
 ['Design inventory','A distinct identity, a before-and-after use, source confidence, and candidate dependencies'],
 ['Graph review','Necessary versus alternative prerequisites, no cycles, and recoverable access'],
 ['Simulation contract','Inputs, outputs, adoption, ownership, effects, failure conditions, and externalities'],
 ['Player experience','A credible question, useful report, leader behavior, and visible consequence'],
 ['Verification','Parity, conservation, reachability, dependence, persistence, and whole-campaign checks'],
 ['Art and release','Subject-specific art, verified layout, documented integration, and updated coverage count']],[1.45,5.35]),
 h('Keep the existing work accountable'),
 p('Audit each of the 197 live discoveries: keep, rename with an alias, split with an explicit migration, or merge into a canonical identity. Do not silently delete earned capabilities. Inspect each legacy frontier effect and map it conservatively where justified; unmapped historical records remain readable without granting thousands of new discoveries.'),
 h('Do not lose the intended scope again'),
 p('Maintain separate counts for proposed, authored, mechanically implemented, tested, and integrated discoveries. Publish coverage by historical horizon and field. Any change that removes live branches or shortens the progression requires an explicit design review describing what player possibilities disappear. A graph-count test alone does not certify quality.'),
 h('Suggested delivery sequence'),
 p('First establish the branching and dependency machinery with a representative connected slice. In parallel in the production plan, author the full historical and future catalog so late scope cannot disappear behind endless early polishing. Then integrate complete field-spanning branches, calibrate the full campaign, and generate the finalized art set. This document does not authorize autonomous changes to the game before your review.'))

page('Acceptance criteria for the complete system',
 table(['Test','Required evidence'],[
 ['Every node earns its place','A concrete capability or constraint change; no count padding through repeated maturity labels'],
 ['Every proposed branch is causal','Explicit AND and OR groups, no prerequisite cycles, and reviewed physical necessities'],
 ['Missed routes remain recoverable','A solver finds an independent rebuilding or external acquisition route when its stated material and contact conditions can be met'],
 ['Dependence is consequential','Controlled comparisons show later access, payments or obligations, and reduced autonomy; becoming independent removes only genuine dependencies'],
 ['No acquisition exploits','Repeated gifts, licenses, capture, reloads, and overlapping routes cannot duplicate effects or stocks'],
 ['People and resources remain real','Adoption consumes actual work and inputs; equal player and opponent accounting'],
 ['Information is earned','Unknown names, artwork, locations, supplier knowledge, and future outcomes do not leak'],
 ['A full campaign stays alive','Natural research runs through 2,500–3,000 years contain distinct early, middle, modern, and future discoveries'],
 ['The future works in the world','Late discoveries enable operating systems and player choices, rather than text-only unlocks'],
 ['Scale stays practical','Record counts depend on catalog, settlements, and active work; no population-proportional agents; measured frame and turn budgets'],
 ['Presentation remains readable','Large and small windows, keyboard access, visible route semantics, and unclipped subject art']],[2.1,4.7]),
 p('Whole-campaign evidence must include ordinary prerequisite and resource gates, multiple environments, isolated and connected societies, a dependency crisis, recovery after disruption, and shared player/opponent rules. Synthetic unlock-all runs are useful for UI coverage but cannot prove historical pacing.'),
 p('Proposed minimum review set: 30 diverse seeds for graph and route checks, six deeply inspected campaign histories, controlled dependence comparisons at early and late horizons, and measured active-world performance. Expand the sample when failures expose a new class of problem. These are acceptance targets, not tests already run.'))

page('Decisions for this review',
 table(['Decision','Proposed position'],[
 ['Meaning of branching','Confirmed by your clarification: access survives, but weaker routes impose delay and dependence.'],
 ['Catalog ambition','Approve 5,000 distinct discoveries as an authoring target, with quality and whole-history coverage taking precedence over padding.'],
 ['Time interpretation','Use a fictional compressed human history over 2,500–3,000 real simulation years; no forced Earth-date unlock ladder.'],
 ['Starting repertoire','Human language and cooperation are present; specify whether fire and basic stone practice are already known or first discoveries.'],
 ['Default visibility','Known knowledge and plausible questions only, with an optional unrestricted encyclopedia outside the live campaign.'],
 ['Future boundary','Grounded planetary and space futures by default; open conjectures belong to separately identified optional content.'],
 ['Player attention','Delegated programs and selective major reports, with complete manual inspection available.'],
 ['Production order','Review the branch architecture and atlas before mass artwork, then implement connected branches with actual consequences.']],[1.65,5.15]),
 h('What is ready to review now'),
 p('The acquisition contract, state model, route economics, worked branch designs, field allocation, and 600 named candidate subjects are concrete proposals. The full 5,000-node prerequisite and consequence catalog is the next authoring deliverable after this direction is agreed; it is not concealed inside an inflated generated count.'),
 h('What remains open'),
 p('Exact balance values, individual historical attributions, several new operating models, and the full production graph remain to be authored and tested. Those gaps must stay visible in the coverage ledger. Review approval should establish the intended experience and scope, not be mistaken for certification that the entire system already exists.'),
 p('The intended result is a civilization whose discoveries tell an intelligible history: people encounter problems, find different routes through them, depend on one another, gain and lose advantages, and open possibilities that previous generations could scarcely imagine.'))
