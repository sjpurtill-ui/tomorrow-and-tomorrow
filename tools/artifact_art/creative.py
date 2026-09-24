#!/usr/bin/env python3
"""Authored prehistoric experiments, shared by the runtime and illustration queue.
These are fictional finds inspired by human ingenuity, not archaeological claims.
"""
import json
from locking import manifest_lock
import prehistoric as p
from catalogue import write_document
from experiment_families import BRIEFS as MORE_BRIEFS
from experiment_episodes import EPISODES, TRACE_FAMILIES
BRIEFS = [
('The shell that held a seam','shell and plant fiber','oral_epics','A ragged shell disc with one crudely abraded hole, caught in a short loop of twisted grass beside two scraps of hide. Close overhead view; emphasize the practical fastening, no bead necklace or decorative motif.','A hole turns a brittle shell into a fastening point. It invites experiments in joining flexible materials.'),
('Night in a hollow stone','sandstone and animal fat','charcoal','A palm-sized naturally hollow sandstone holding a tiny pool of dull yellow rendered fat and a charred moss wick, one low flame. Side view against a broad charcoal cave wash that fades into ivory paper. Uneven uncarved lip, no pottery or metal.','Fuel held beside a wick suggests a portable source of light.'),
('The reed that answered','reed','oral_epics','A split dried reed with a rough blowing notch and only two uneven finger holes. Diagonal close view above river silt, a broken reed section showing its hollow interior. No polished flute, decoration or musical notation.','Breath changes pitch inside a hollow tube; sound becomes something people can investigate.'),
('Memory tied in grass','grass fiber','tallies','One frayed length of hand-twisted grass cord with three widely separated bulky knots of unequal size, partly uncoiled on pale dust. Overhead looping composition. No beads, writing or elaborate knot system.','A knot can preserve a reminder beyond the moment it was made.'),
('A handle held by pitch','flint, branch and resin','controlled_flaking','A small crude stone flake wedged in the split end of a crooked twig, secured by a dark lumpy resin dab and a few rough sinew turns. Enlarged joint is the focus, twig extends diagonally. No refined axe geometry.','The useful object is a combination: cutting edge, grip and adhesive working together.'),
('The stone that carried warmth','stone and hide','charcoal','An irregular fire-reddened cobble nestled in a torn folded hide scrap with scorched contact patches. Low side view; a few cold hearth ashes at one edge. No people or hot glow.','A warmed mass releases heat gradually, suggesting that warmth can be moved and stored.'),
('Water in a folded skin','hide and thorn','oral_epics','A crude folded scrap of animal hide cupped into a shallow pouch, its corners pinned with two rough thorns, a little dark water gathered inside. Close overhead view; uneven raw edges, no stitched leather bottle.','A flexible surface can become a container when its edges are held together.'),
('The pebble that steadied a net','stone and bast fiber','stone_sorting','One flat natural pebble with two shallow pecked edge notches tied into a ragged fragment of very loose hand-knotted bast mesh. Riverbank mud, side-on low composition. No manufactured fishing net or uniform knots.','A small weight changes how a flexible mesh behaves in moving water.'),
('A bird from one thumb','unfired clay','clay_shaping','A thumb-sized sun-dried clay lump pinched twice into the suggestion of a bird, one crude beak and a lopsided body, visible thumb ridges. A broken clay pinch beside it gives scale. No pedestal, glaze or finished sculpture.','A few changes of shape can make an absent animal recognizable.'),
('Tracks remembered in red','ochre and limestone','oral_epics','A broken cave-wall surface carrying three crude red-ochre impressions resembling cloven hoof tracks, unevenly spaced along a natural crack. Oblique view of rock face; no animal portrait, alphabet or prepared plaque.','The trace of an animal can stand for the animal itself, preserving an observation for others.'),
('The fork that turned a load','forked branch','stone_sorting','A short crooked forked branch whose crotch is deeply compressed and shiny from rubbing against a coarse stone. Show both together on bare dirt with the branch angled under the stone edge. No engineered lever frame.','Changing the place where force is applied can make a heavy object easier to move.'),
('Three colors in a shell','shell and earth pigments','oral_epics','An unworked broad mussel shell containing separate small thumb-smudged patches of red ochre, yellow earth and charcoal. Overhead asymmetrical crescent composition, a short stained twig at the rim. No brushes with ferrules.','A natural hollow keeps different pigments close at hand without mixing them.'),
('The split bone and the sinew','bone and sinew','stone_sorting','A stout bone sliver with a naturally split end trapping one coarse sinew strand, lying beside a ragged punctured hide offcut. Macro view of the split; no drilled needle eye, refined sewing kit or neat stitching.','A split can grip a flexible strand and pull it through another material.'),
('A bark fold against rain','bark and twig','oral_epics','A curved bark sheet folded over a handful of dry tinder and pinned roughly with a slender twig. Three-quarter view, one lifted corner reveals the dry fibers; damp pebbles nearby. No woven basket.','Overlapping a water-shedding surface protects fragile material inside.'),
('The whistle in the joint','animal bone','oral_epics','A small hollow animal joint-bone with one rough side opening and a worn lip, open end visible. Sparse cool gray cave wash below, ivory above. No long flute, hole sequence or engraving.','A small air cavity offers a surprising way to make a loud signal.'),
('A child beside an adult','ochre and cave stone','oral_epics','A vertical irregular cave-rock face holding two overlapping ochre hand traces, one noticeably small, one adult-sized. Faded sprayed edges and untouched rock, no framing. Broad empty ivory above and left.','Marks can preserve presence and relationships long after their makers leave.'),
('The thorn that closed a tear','thorn and hide','oral_epics','A single long curved thorn pushed through both sides of a ragged hide tear, rough plant fiber wound around its exposed ends. Enlarged close composition, no blood or refined sewing.','A temporary repair holds separated edges together, inviting better ways to mend.'),
('An ember under ash','charcoal, ash and fungus','charcoal','A palm-sized cup-shaped piece of bracket fungus holding a black ember beneath pale ash, a faint warm red point visible through a crack. Bare stony ground. No ceramic vessel or modern fire starter.','Insulating a small ember can preserve fire between hearths.'),
('A tooth made to swing','tooth and fiber','oral_epics','One small unpolished animal tooth with fiber wrapped around its natural root constriction, suspended just above the ground. Off-center vertical composition; rough binding, no drilled hole or decorative carving.','A natural narrowing becomes a secure attachment, making a found object wearable.'),
('The sand that took a shape','dried clay and sand','clay_shaping','A flat cracked patch of sun-dried clay with the shallow impression left by a pressed scallop shell; the unworked shell lies beside it. Oblique overhead view; irregular unfinished clay margins. No seal, mold box or casting.','Pressing a surface into a yielding material transfers its shape.'),
('The stone with two voices','thin slate','oral_epics','Two unequal thin natural slate fragments resting on separate small pebbles, a short battered stone striker nearby. Low side view highlighting the lifted ends and different lengths. No tuned musical instrument frame.','Pieces of the same material can sound different when struck.'),
('Seeds saved in a gourd','wild gourd and seeds','oral_epics','A small dried wild gourd with an irregular broken opening, a few mixed wild seeds inside and spilled nearby. No cut lid, painted pattern or cultivated grain field. Warm overhead illustration with generous paper.','A dry natural shell separates a small reserve from the surrounding ground.'),
('The wedge left in wood','stone and branch','controlled_flaking','A blunt triangular stone chip still jammed in the torn end of a short branch, exposing pale split fibers. Close diagonal view of the joint; a pounding pebble nearby. No metal axe or sawn lumber.','A widening shape can turn a crack into a useful split.'),
('A crescent remembered','charcoal and stone','tallies','An unprepared flat rock with four rough charcoal crescent-like daubs of different fullness, scattered rather than in a ruled sequence. Faint rubbed corrections, no numerals, astrology or engraved calendar.','Repeated changes in the sky might be compared through marks kept on one surface.'),
('The feather that spread ochre','feather and pigment','oral_epics','A ragged feather with ochre clinging to its uneven barbs beside one broad feather-shaped smear on bare stone. Close overhead view; no quill writing or bound brush.','A soft edge spreads material differently from a finger or a hard point.'),
('A sling of split bark','bark fiber and stone','stone_sorting','Two rough lengths of twisted bast ending at a small folded bark pocket cradling a pebble. Loose asymmetrical loops across pale ground. Crude damaged construction, no woven pouch, leather tooling or combat scene.','A flexible extension changes the reach and motion of a hand-held weight.'),
('The hollow that kept droplets','leaf and clay','clay_shaping','A crumpled broad leaf pressed into a barely shaped clay hollow, tiny water droplets following its veins. Three-quarter close view, cracked clay edges; no finished bowl, firing or irrigation device.','A lining changes how a porous hollow holds liquid.'),
('Resin remembered a fingerprint','resin and wood','oral_epics','An irregular amber-brown resin lump stuck to a splinter of wood, one clear coarse fingertip impression in its dull surface. No polished gemstone or pendant. Sparse dark branch shadow fading into paper.','A soft material can take a mark and later harden around it.'),
('The scraper with a soft grip','flint and hide','controlled_flaking','A stubby rough flint scraper whose blunt end is wrapped in a single torn hide strip, the edge exposed. Side view; crude frayed wrap without standardized handle.','Protecting the hand allows a sharp edge to be used with greater control.'),
('A path made of contrasts','pale and dark stones','oral_epics','A compact surviving patch of earth with three pale pebbles set against dark gravel leading toward one larger upright natural rock. Oblique close view, no road or carved symbols.','Objects placed where they contrast with their surroundings can help someone find a way.'),
('The twisted root join','root and wood','stone_sorting','Two crooked branch fragments lashed at an awkward angle with a single flexible root, root fibers fraying under tension. Close view of a practical unstable joint, no frame, nails or finished carpentry.','Wrapping a joint distributes strain and joins materials without shaping matching surfaces.'),
('An animal hiding in the rock','ochre and limestone','oral_epics','A bulging irregular limestone fragment whose natural ridge becomes the back of a rough red-ochre horse; only a few strokes add head and legs. Partial figure crosses a crack. No repeated bovine-and-hand motif.','An existing shape can become part of an image, turning observation into representation.')
]
STYLE = ('The supplied references guide painting medium ONLY: ivory fibrous paper, matte gouache, broken dry-brush edges, restrained ochre, charcoal, muted olive and earth colors. These are FICTIONAL PREHISTORIC FINDS: ingenious but crude handmade experiments, never later finished technology. Follow the specified mechanism and materials. No generic river decoration, alphabets, ornate craftsmanship, metal, modern components, polished 3D, photographic lighting, labels, captions, frames or grids. One distinct square illustration. Keep the object legible with generous ivory negative space. Vary viewpoint and silhouette as specified; no repeated centered rock template. Organic remains are imagined preserved fragments, not modern reconstructions. Do not add people or workshops.')
def extend():
    path=p.bank.ROOT/'data/artifacts/prehistoric_experiments.json'
    authored=json.loads(path.read_text()) if path.exists() else {}
    manifest=json.loads(p.bank.MANIFEST.read_text())
    families=BRIEFS+MORE_BRIEFS
    assert len(families)==123
    for offset in range(3936):
        family=offset%123
        episode=offset//123
        name,material,subject,scene,insight=families[family]
        i=160+offset
        if episode:
            label,construction,trace,question=EPISODES[episode]
            name+=' · '+label.lower()
            direction=trace if 160+family in TRACE_FAMILIES else construction
            scene+=' Distinct experiment for this specimen (takes precedence over the base arrangement): '+direction
            scene+=' Preserve the recognizable underlying practical idea. Keep all additions crudely made from raw prehistoric materials; no refined later invention. For a one-piece object, a support means the natural surface touching it, not an invented complex mechanism.'
            insight+=' '+question
        assert len(insight)<=600
        definition={'name':name,'form':name.lower(),'material':material,'discovery_id':subject,'artifact_origin':'prehistoric','art_collection':'prehistoric-v1','catalogue_id':i,'insight':insight}
        row=manifest['entries'][i]
        if row['status']!='pending' or row.get('prompt_override'):
            assert authored.get(str(i))==definition, 'Never change a generated concept silently'
            continue
        authored[str(i)]=definition
        row.update(definition,creative_direction='prehistoric ingenuity',prompt=f'Use case: historical-scene. Artifact {i:04d}: {name}.\n{STYLE}\nSubject: {scene}\nUnderlying idea (communicate visually, NO TEXT): {insight}')
    write_document(path,authored);write_document(p.bank.MANIFEST,manifest)
    print(f'{len(authored)} authored experiments ready')
if __name__=='__main__':
    with manifest_lock(p.bank.MANIFEST.with_suffix('.lock')):
        extend()
