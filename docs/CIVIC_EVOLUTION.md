# Civic evolution: government, court and civic life by discovery

The form of rule changes with what a people knows, not with the calendar. The
stages live in `data/civic/civic_stages.json`, and the 1200–1800 research ids
live in `data/civic/y1200_triggers.json`. `scripts/civic_stages.gd` derives a
people's stage from its known discoveries every time it is asked. Nothing new
is saved.

The stage drives:

- **Offices.** `GovernmentPeopleSystem` stays the owner of offices and people.
  The stage renames offices, adds the offices that discoveries create and
  abolishes some offices again.
- **The court.** `scripts/hud/court_backdrop.gd` draws the scene;
  `court_roster.gd` sets who sits, what the groups are called and who attends;
  `audience_modal.gd` shows the name, setting and ceremony in the header.
- **Speech.** `character_voice.gd` sets how officials address the god and
  gives each official the court protocol in their prompt brief.

Real history is calibration only. The names are generic, and there are no
real polities, people or places.

## How a stage is chosen

1. **Requirements.** Each stage has requirement groups. Every group must be
   met, and a group is met when at least `min` (default 1) of its ids are
   known. A stage can also have alternative requirement sets from
   `y1200_triggers.json`. A stage marked `y1200_only` can be reached only
   through those.
2. **Lean.** The lean is **throne** or **assembly**. It counts the known
   throne markers (chiefly rank, kingship, dynastic succession, anointing,
   vassal oaths, homage, fiefs and so on) against the known assembly markers
   (free assembly, elected magistrates, lot, majority vote, juries,
   tribunes, sworn communes, chartered liberties and so on).
   - Assembly wins when it has more markers.
   - On a tie with at least one assembly marker, assembly also wins unless
     the society's values make it centralized.
3. **Track.** Stages are `any`, `throne` or `assembly`. A people keeps to its
   own track whenever that track has an eligible stage, so a city-state gets
   an assembly, not a throne. A would-be city-state that has none of its own
   track's stages yet can still have a chief's hall or a palace first.
4. **Highest rank wins.**
5. **Era floor.** `floor_by_tier`, indexed by `CharacterVoice.era_tier`,
   keeps a people whose material era has outrun its recorded institutions
   from sitting in a court below that era. This covers older saves and
   catalog-only worlds:

   | Era tier | Lowest court |
   |---|---|
   | 0 | Hearth council |
   | 1 | Elders' circle |
   | 2 | Chief's hall |
   | 3 | Temple-palace |
   | 4 | Palace bureaucracy (throne peoples only) |

Tests and captures can pin a stage with `CivicStages.stage_override`. The
court follows `CharacterVoice.knowledge_override["player"]`, so the court,
the titles and the speech always agree.

## Stage table

Years are the research blocks' target years, for orientation only.
Discoveries, not years, trigger the stages.

| # | Stage | Track | Triggered by | ≈ year |
|---|---|---|---|---|
| 0 | **Hearth council** (the fire circle) | any | Start of the game | 0 |
| 1 | **Elders' circle** (the elders' ring) | any | Two of `elder_consultation_rites`, `household_councils`, `elder_council_assent`, `dissenting_voice_custom`, `consensus_amendment_custom`, `customary_law` | 10–35 |
| 2 | **Chief's hall** | any | `paramount_chiefdom`, `hereditary_chiefly_rank` or `tributary_villages` | 140–215 |
| 3 | **Temple-palace with scribes** (the house of the god) | any | A god's-house office (`temple_high_steward`, `offering_keepers`, `temple_ration_issue`, `temple_common_storehouse` or `separate_temple_palace_stores`) **and** records (`pictographic_records`, `impressed_number_tablets`, `token_envelopes`, `formal_archives` or `phonetic_notation`) | 255–260 |
| 4 | **Palace bureaucracy** (the palace hall) | throne | `kingship` or `dynastic_succession` **and** `formal_archives`, `palace_department_registers`, `provincial_governors`, `census_rolls` or `provincial_accounts` | 365–405 |
| 5 | **Citizen assembly and magistrates** (the assembly place) | assembly | `annual_elected_magistrates`, `majority_vote_assembly`, `lot_chosen_council` or `citizen_jury_courts` **and** a public voice (`free_adult_assembly`, `assembly_petition_rights`, `warrior_acclamation_assembly`, `shrine_league_confederation`, `public_heralds`) or letters (`phonetic_notation`, `consonantal_alphabet` or `full_vowel_alphabet`) | 750–800 |
| 6 | **Imperial court with ministries** (the throne hall) | throne | Provincial rule (`provincial_governors`, `circuit_inspectors`, `divided_provincial_powers` or `rotated_appointed_prefects`) **and** realm-wide office (`realm_wide_standardization`, `rotated_appointed_prefects`, `written_office_examinations`, `universal_loyalty_oath` or `state_official_academy`) **and** monarchy (`kingship`, `dynastic_succession`, `priestly_anointing` or `veiled_monarchy_offices`) | 930–980 |
| 7 | **Council house of the commonwealth** | assembly | Two of `mixed_constitution_checks`, `commoners_veto_tribunes`, `magistrate_edict_law`, `end_of_term_audits`, `federal_proportional_league` and `binding_jurist_opinions` | 960–1045 |
| 8 | **Late-antique consistory** | throne | Two of `compiled_rescript_code`, `shared_co_rulers`, `civil_military_separation`, `hereditary_trade_obligation`, `head_land_tax_units`, `nine_rank_official_grading` and `federate_settlement`; *or, from 1200–1800:* two of `promulgated_edict_code`, `household_great_offices`, `register_of_dignities`, `jurist_digest_codification` and `regional_vicariates` | 1160–1300 |
| 9 | **Feudal hall** (the great hall) | throne | *1200–1800 only:* `homage_commendation`, `fief_tenure_for_service` or `hereditary_fief_succession` **and** `itinerant_royal_court`, `household_great_offices`, `hereditary_fief_succession`, `seigneurial_immunity_courts`, `castellan_local_lordship`, `border_march_wardens` or `forest_law_courts` | 1360–1470 |
| 10 | **Chancery court** (the chamber of the seal) | throne | `printing_process` or `relief_block_cutting` **and** a record material (`paper_making`, `parchment_record_preparation` or `bookbinding_assemblies`) **and** `petition_registers`, `official_mandate_registers` or `public_office_handover`; *or, from 1200–1800:* `royal_chancery_office`, `chancery_enrolment_rolls` or `sealed_royal_writs` **and** `counting_table_audit`, `royal_justice_circuits`, `realm_holding_survey`, `public_notaries` or `writ_forms_of_action` | 1360–1580 |
| 10 | **Chartered commune** (the commune's hall) | assembly | *1200–1800 only:* `sworn_town_commune` or `chartered_town_liberties` **and** `elected_town_consuls`, `chartered_town_liberties`, `town_residence_freedom`, `town_trade_statute_book`, `guild_council_seats` or `craft_guilds` | 1575–1605 |
| 11 | **Assembly of the estates** (the hall of the estates) | any | `craft_guilds` **and** `municipal_charters`, `provincial_town_councils`, `charter_colonies` or `chartered_craft_associations` **and** `noble_council`, `vassal_loyalty_oaths`, `service_land_grants` or `provincial_town_councils`; *or, from 1200–1800:* `estates_assembly` **and** `great_liberties_charter`, `fixed_capital_archives`, `permanent_high_court`, `consented_taxation`, `chartered_town_liberties` or `guild_council_seats` | 1540–1680 |

The typical paths are:

- **A throne people:** hearth → elders → chief's hall → house of the god →
  palace → throne hall → consistory → feudal hall → chancery → estates.
- **An assembly people (a city-state):** hearth → elders → chief's hall →
  house of the god → assembly place → council house → chartered commune →
  estates.

## Offices

The six founding offices keep their keys: Steward, Quartermaster, Marshal,
Scholar, ChiefScout and Envoy. The size of the society (`government_stage`)
still decides how many of them sit. At the hearth council, titles are
unchanged: they still come from size and form, capped by era (for example
Hearth Chief, War Leader and Pathfinder). From the elders' circle on, the
stage sets every title.

Discoveries add three offices. Their requirements are in
`civic_stages.json → offices` plus `y1200_triggers.json → offices`.

| Office | Added when | Minimum size / rank | Abolished at |
|---|---|---|---|
| **HighPriest** (the god's own servants) | `first_shrine_house`, `offering_keepers`, `temple_high_steward`, `temple_common_storehouse`, `priestly_anointing`, `oracle_consultation` (later `ranked_priestly_hierarchy`, …) | Government stage 1, elders' circle | Assembly place and council house: the priesthoods become civic posts outside the council |
| **Justice** (judging splits from the Steward) | `standing_arbiter_appointment`, `regional_arbitration_circuits`, `specialized_courts`, `written_law_code`, `sworn_judges`, `royal_appeal_court`, `citizen_jury_courts`, `written_court_procedure` (later `royal_justice_circuits`, `permanent_high_court`, …) | Government stage 2, elders' circle | — |
| **Treasurer** (the treasury splits from the Quartermaster's stores) | `public_credit`, `die_struck_coinage`, `inscribed_treasury_accounts`, `district_royal_banks`, `league_common_treasury`, `annual_tax_budget`, `separate_temple_palace_stores` (later `counting_table_audit`, …) | Government stage 3, temple-palace | — |

When an office stops being active, its holder loses it through the existing
`_synchronize_office_holders` path. The new offices are ordinary keys, so
the existing systems can appoint to them, dismiss their holders and name
successors.

### Titles by stage

| Stage | Steward | Quartermaster | Marshal | Scholar | ChiefScout | Envoy | HighPriest | Justice | Treasurer | Settlement leader |
|---|---|---|---|---|---|---|---|---|---|---|
| Hearth council | (size/form titles: Hearth Chief …) | Keeper of Stores | War Leader | Lore Keeper | Pathfinder | Messenger | Keeper of the God's Fire | Arbiter | Keeper of the Treasury | Hearth Elder |
| Elders' circle | First Elder | Keeper of Stores | War Leader | Lore Keeper | Pathfinder | Messenger | Keeper of the God's Fire | Arbiter | Counter of Gifts | Village Elder |
| Chief's hall | Chief's Right Hand | Keeper of Tribute | War Chief | Rememberer | Master of Trails | Speaker to Strangers | Keeper of Offerings | Lawspeaker | Tribute Counter | Headman |
| Temple-palace | High Steward | Overseer of the Granaries | Captain of the Guard | Chief Scribe | Overseer of Roads | Messenger of the House | High Priest | Judge of the Gate | Keeper of the Sealed Stores | Town Overseer |
| Palace bureaucracy | Grand Steward | Overseer of Granaries and Stores | General of the Host | Master of the Archives | Master of Messengers | Royal Envoy | High Priest | Chief Judge | Overseer of the Treasury | Governor |
| Citizen assembly | Presiding Magistrate | Grain Commissioner | Elected General | Keeper of the Public Records | Commissioner of Roads and Watch | Sworn Ambassador | *(abolished)* | Magistrate of the Courts | Treasurer of the City | Town Magistrate |
| Imperial court | First Minister | Minister of Supply | Master of the Armies | Minister of Rites and Learning | Master of the Imperial Post | Minister for Foreign Peoples | Chief of the Sacred Rites | Minister of Justice | Minister of the Treasury | Prefect |
| Council house | Chief Magistrate | Commissioner of the Grain Supply | Commander Chosen by the House | Keeper of the Laws | Commissioner of Roads | Legate of the Commonwealth | *(abolished)* | Judging Magistrate | Treasury Magistrate | Municipal Magistrate |
| Late-antique consistory | Master of Offices | Count of Supplies | Master of Soldiers | Master of Memorials | Master of the Post | Master of Embassies | Patriarch of the God's House | Palace Jurist | Count of the Treasury | Count of the District |
| Feudal hall | Steward of the Realm | Chamberlain | Marshal of the Host | Keeper of the Charters | Warden of the Marches | Envoy of the Overlord | Chaplain of the Realm | Justiciar | Treasurer of the Chamber | Castellan |
| Chancery court | Chancellor | Steward of the Household | Constable | Master of the Rolls | Master of Couriers | Secretary for Foreign Letters | Primate of the Realm | Chief Justice | Lord Treasurer | Shire Reeve |
| Chartered commune | Chief Consul | Warden of the Market | Captain of the Commune | Town Clerk | Warden of the Gates and Roads | Orator of the Commune | Priest of the Commune | Judge of the Commune | Chamberlain of the Commune | Consul |
| Estates assembly | Chancellor of the Estates | Master of Provisions | Marshal of the Realm | Rector of Learning | Master of Posts | Ambassador of the Estates | Speaker of the Clergy | Chief Justice of the Realm | Treasurer of the Estates | Mayor |

The split and renamed offices follow real patterns:

- The Steward becomes the Chancellor, and the Quartermaster the Chamberlain.
- The ChiefScout becomes a master of the post.
- The Treasurer splits from the Quartermaster, the Justice from the Steward,
  and the HighPriest from the Steward's household.

## Court, protocol and address

| Stage | Seats | Council called | Attendants in the scene | Protocol | Officials address the god as |
|---|---|---|---|---|---|
| Hearth council | 7 | The Council | — | Everyone sits about the one fire; anyone may speak | Their dialect's term (unchanged: "Great One", "Sky-Holder", …) |
| Elders' circle | 7 | The Elders | 2 elders | The eldest speak first; a carved staff passes hand to hand | Eldest Fire · Old One Above · Keeper of Us All |
| Chief's hall | 7 | The Hall Council | 2 hall warriors, a guest bearing gifts | Guests stand until bidden; gifts laid before the high seat | High Giver · Lord Above the Hall · Giver of Plenty |
| Temple-palace | 8 | The Household of the God | a keeper of offerings, 2 scribes, a door guard, 2 kneeling petitioners | Kneel at the threshold; a scribe records every word | Lord of the House · Dweller Within · Lord of the Offerings |
| Palace bureaucracy | 8 | The Palace Council | herald, 3 scribes, priest, 2 guards, 3 prostrate petitioners | Prostration; a herald cries each name; petitions arrive written, through the archive | Most High · Lord of the Two Houses · Eternal Majesty |
| Citizen assembly | 9 | The Magistrates | herald, secretary, 14 citizens on the tiers, 2 petitioners with boughs | No one kneels; speakers by the water-clock; the assembly votes | Guardian of the City · Patron of the Assembly · Protector of the Town |
| Imperial court | 9 | The Ministries | master of ceremonies, 3 ministers, 3 secretaries, 2 priests, 4 guards, 3 petitioners | Full prostration in silence; audiences by appointment through the ministries | Sacred Majesty · Lord of the World · Divine Majesty |
| Council house | 9 | The Senate | 2 attendants with rods, 2 clerks, 12 councillors, petitioner at the bar | Councillors sit, citizens stand; motions decided by division | Patron of the Commonwealth · Guardian of the Laws · Divine Protector |
| Late-antique consistory | 9 | The Privy Consistory | 2 ushers with rods, 2 officers, 2 clergy, 3 retainers, 2 notaries, 3 petitioners | Kneel and kiss the hem; petitions as sealed memorials | Most Serene One · Your Eternity · Most Pious Lord |
| Feudal hall | 9 | The Great Officers | herald, 4 sworn retainers, 2 great officers, chaplain, clerk, 3 vassals | Hands between the lord's hands; the court travels, living on dues | Liege Lord · Lord of All the Oaths · High Overlord |
| Chancery court | 9 | The Privy Council | crier, 4 clerks, 2 masters of requests, 2 sergeants, 4 suitors | Sealed writs on the court's roll; three bows | Most Gracious Lord · Your Grace Above All · Sovereign Lord |
| Chartered commune | 9 | The Consuls of the Commune | town crier, 2 clerks, 10 guild masters and sworn townsmen, 2 watchmen, 2 petitioners | The great bell calls the council; the charter is read; petitions entered in the town book | Patron of the Commune · Protector of Our Liberties · Lord of the Charter |
| Estates assembly | 9 | The Council of the Estates | 2 heralds, 14 deputies on three benches, 2 clerks, speaker of the clergy, 2 guards, 2 bearers of grievances | Each estate in its benches; grievances before grants | Most Sovereign Lord · Sovereign of the Estates · Lord of All the Estates |

**Address.** Each official keeps one form of address per stage, chosen
deterministically from the stage's list and kept for life within that
stage. When the court changes, the same person learns its new manners. At
the hearth council, addresses stay exactly as they were: the speaker's
dialect term.

**Brief.** Every official's and master builder's prompt brief carries
`court protocol: …`, so model-written speech reflects kneeling, heralds,
petitions and so on.

**Event.** When the stage changes, `GovernmentPeopleSystem` records a dated
major event, "The Court Changes: <stage>", at its monthly tick. The first
sighting after loading a save is silent.

## Law and justice

| Stage | Law |
|---|---|
| Hearth council | Custom remembered by everyone; quarrels talked out in the circle |
| Elders' circle | Customary law spoken by the elders: blood-price, go-betweens, banishment |
| Chief's hall | The chief's judgment; a lawspeaker recites custom; oaths before the god |
| Temple-palace | Judges at the god's gate; witnessed agreements pressed into tablets |
| Palace bureaucracy | Written law code with set penalties; sworn judges; appeal to the ruler's court |
| Citizen assembly | Statutes voted by the assembly; juries by lot; magistrates audited |
| Imperial court | One law for the realm; a ministry of justice; an extortion court for governors |
| Council house | Magistrates' yearly edicts and jurists' opinions; tribunes' veto |
| Late-antique consistory | Collected codes of rescripts; binding jurists; the god's house hears civil suits |
| Feudal hall | Lords judge in their own lands under sworn custom; the overlord's court hears vassals |
| Chancery court | Writs under seal open standing courts; equity before the chancellor |
| Chartered commune | Town statutes sworn by commune and guilds; consuls judge by the charter |
| Estates assembly | Statutes need the estates' consent; common courts, town charters, guild ordinances |

## Seat of rule and civic buildings

The `seat_of_rule` and `civic_buildings` fields of each stage describe the
ruler's hall and the civic buildings that should appear in settlements. The
art prompts in `docs/art/COURT_STAGE_ART_BRIEF.md` draw on both. The
settlement renderer does not read `civic_buildings` yet (see Limitations).

| Stage | Seat of rule | Civic buildings in settlements |
|---|---|---|
| Hearth council | Ring of logs and hides round the common fire | Fire ring, storage pits, drying racks |
| Elders' circle | Ring of standing stones, carved seats for the eldest | Meeting stone, boundary markers, watched common store |
| Chief's hall | Long timber hall, high seat, shields, feast boards | Chief's longhouse, tribute store, feast ground, shrine house |
| Temple-palace | Mudbrick god's house, niched facade, offering table, scribes' benches | God's storehouse, scribes' house, ration hall, shrine terrace |
| Palace bureaucracy | Dressed-stone hall, stepped dais, archives, guard posts | Governor's residence, district archive, law stele, palace granary |
| Citizen assembly | Open-air stepped tiers, speakers' platform | Assembly place, council house, law court, treasury, market wardens |
| Imperial court | Vaulted throne hall, gold apse, purple hangings | Prefecture, post station, state granary, provincial treasury, academy |
| Council house | Tiered marble benches, magistrates' chairs, bronze doors | Council house, record office, basilica court, baths |
| Late-antique consistory | Dim basilica, blue-and-gold apse, hanging lamps | Fortified count's hall, god's-house court, charity hospital, tithe barn |
| Feudal hall | Great hall of timber trusses over stone, high table, shields | Castle and bailey, manor court, tithe barn, lord's mill |
| Chancery court | Vaulted chamber of the seal, clerks' table, chests of rolls | Chancery house, shire court, toll house, guild hall, record tower |
| Chartered commune | Council chamber over the market, bell tower, guild banners | Town hall with belfry, guild halls, market cross, walls, weigh house |
| Estates assembly | Great hall, three banks of benches, canopy of state, rose window | Town hall, guild halls, exchange, hall of learning, cloth hall |

## 1200–1800

`data/civic/y1200_triggers.json` is the single mapping from the 1200–1800
research ids to stages, tracks and office triggers. These ids come from
`docs/research/y1200/*_1200_1800.md`, rows tagged `[gov: …]`. They are not
in the game catalog yet. Once a built research block makes them knowable,
they take effect with no code change. If the registry renames or dedupes an
id, edit only that file. Its `watch` list holds tagged ids that may deserve
new offices later: `pestilence_health_boards`, `impeaching_censorate`,
`three_department_ministries`, `sworn_royal_council`, `privy_seal_office`
and `keepers_of_the_peace`.

## Save compatibility

- No new saved fields. `GovernmentPeopleSystem` has no new variables. The
  stage cache and the "last stage seen" record are static and never
  reflected.
- An old save derives its court from its `known_discoveries` when loaded.
  The era floor keeps older catalog-only worlds from falling back to the
  fire circle.
- Offices that a stage adds or abolishes are handled by the existing
  office synchronisation.

## Limitations

- The new offices (HighPriest, Justice, Treasurer) are council seats with
  their own titles, skills and holders. No system routes work to them yet:
  granary, treasury and judicial effects still run through the Steward and
  the Quartermaster.
- Settlement visuals do not read `civic_buildings` yet. The art brief lists
  what should change.
- Foreign civilizations derive a stage too: `CivicStages.current(civ_id)`
  works. But only the player's court is drawn, and foreign leaders still
  use their dialect address.
