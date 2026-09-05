# People and legacies

Open with F10, Military > People & Legacies, or the battlefield header. A campaign general's inspector also has Read Life Story. Person navigation and biography/deed pages do not scroll.

The simulation begins with eight emerging figures: a general, scholar, physician, engineer, agronomist, organizer, artist and explorer. It retains at most twelve living/captive/wounded figures and 512 lifetime records, independent of population size. These are exceptional narrative records over numerical population cohorts; their death never deducts population a second time.

The seeded generator provides 1,536 distinct full-name combinations (four fictional regional naming traditions, each with twelve women's names, twelve men's names and sixteen family names). Names stay unique within the chronicle. Backgrounds combine upbringing, origin, vocation, formative experience, personality and ambition. These are explicitly fictional backgrounds. Recorded deeds come from supported work, discoveries, battles, capture, recovery and death. The most recent twelve deeds are retained per figure.

Three patronage slots grant 23.7–29.64% additional research progress in a figure's field, conditional on the existing research system having the labor, attention and evidence needed to make progress. Supporting someone creates no research by itself. Living bonuses cap at 40% per domain. Each complete supported work year earns two reputation points; assisting a discovery earns eight; a recorded battle earns three. Renowned begins at twenty and Great at sixty.

Generals blend their talent with the existing institutional commander skills. Patronage and the security legacy also affect command. Independent field-army appointments use persistent figure IDs; an appointed government Marshal retains their current official identity and aptitudes, and unavailable commanders are replaced. Existing battle results drive death/capture/injury, with injury recovery after 180 days. The standalone battle demo and Battle Lab use generated names without recording their simulated deeds into the campaign chronicle.

At death, earned supported work and reputation produce a smaller research legacy: 0.4 percentage points per supported year plus 0.1 per reputation point, capped at 12% per person and 20% per domain in total. No unearned lifetime achievements are invented. Aging is processed from game days; a new figure can emerge every five years if slots remain. This first balance pass rewards patronage and accumulated work; monuments, authored books, schools, political movements, rival-civilization biographies and family dynasties are not yet modeled.

Export/import version 1 is included in MilitaryCampaign's state payload. Old payloads without this field keep compatibility. Invalid imports are rejected before mutation, and military validation failure restores figure state. This does not add a new disk-save UI to the project.

Verification: tests/historical_figures_probe.tscn exercises all 1,536 names, reproducibility, patronage limits, discovery attribution, death/legacy, commander succession, duplicate events, JSON round trip, invalid import rejection, numeric population preservation, and bounded growth. Existing battle and map probes cover integration.
