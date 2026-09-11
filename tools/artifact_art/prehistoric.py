#!/usr/bin/env python3
"""Prehistoric art queue. Uses original PNGs from individual built-in tool calls."""
import argparse, fcntl, json, re
import catalogue as bank
bank.DEST=bank.ROOT/'assets/ui/artifacts/prehistoric-v1'
bank.MANIFEST=bank.ROOT/'art_source/prehistoric-art/manifest.json'
bank.INDEX=bank.DEST/'index.json'
SCENES=[
'A lumpy gray cobble with a shallow, barely pecked depression: a very crude stone bowl. Uneven thick battered rim, coarse pitting, no circular symmetry, no ornament.',
'A naturally rounded stone heavily bruised and battered at one end from simple pounding, neither shaped nor engraved, lying alone in earth dust.',
'A thick irregular flint flake with accidental-looking chipped edges and a coarse striking platform. NOT a perfected symmetrical blade or polished handaxe.',
'A fist-sized rough pebble with only a few large crude chips removed from one side to make a chopping edge. Most of the original lumpy cortex remains.',
'An unfinished thick pointed piece of flint, badly asymmetrical with coarse flake scars and blunt areas, abandoned before finishing. No handle or haft.',
'A coarse flat sandstone slab with an irregular shallow worn patch from repeated rubbing; a few crushed seeds nearby. No manufactured milling mechanism.',
'A rough, friable lump of red ochre with a scraped corner and a small smear of loose red earth pigment in the dust. The mineral is the artifact, not a manufactured paint pot.',
'A small naturally irregular grinding pebble stained with rubbed-in ochre pigment at its blunt end; a few primitive pigment crumbs beside it.',
'An irregular broken rock face bearing a few hesitant faded charcoal strokes. These are crude nonlinguistic traces, not writing, measures or an ornamental pattern.',
'A roughly fractured natural cave-wall rock flake carrying a faint primitive ochre palm print with uneven fingertips, weathered almost away; no prepared plaque.',
'A roughly fractured natural cave-wall limestone fragment bearing a partial crude ochre animal outline reminiscent of prehistoric cave painting. A few rough strokes suggest a wild bovine back, uneven legs and horned head, with a faint palm smear nearby. Follow the natural rock, not a prepared plaque.',
'A broken unpolished bone fragment with three faint short isolated abrasion scratches, far apart at unrelated angles. The marks never touch, cross, join or form V shapes. They read as incidental wear, never glyphs or writing. No standardized counting scale, elaborate carvings, letters or decorative pictogram.',
'A splinter of bone crudely rubbed toward an uneven point, with the broken end still rough. No needle eye, turned surface, engineered fitting, or elaborate decoration.',
'A worn animal tooth fragment with naturally mottled enamel and earth in its natural crevices. No intentional scratches, engraving, letters, notches, polished pendant, metal fitting or drilled decoration.',
'A small lopsided pinch of sun-dried, UNFIRED clay retaining crude fingertip impressions. It is a shapeless or barely human-like experimental lump, never a finished ceramic figurine or vessel.',
'A rough cracked cobble with ancient soot, scorching and ash lodged in the fractures, beside a tiny charcoal crumb. No formal fireplace, kiln or later architecture.'
]
GUIDE=('The four supplied reference images define ONLY the painting aesthetic: warm ivory textured paper, restrained flat matte gouache and dry brush, coarse broken pigment edges, muted earth colors and charcoal, generous untouched paper. These finds PRE-DATE THE LIVING CIVILIZATIONS IN THE GAME. They must be VERY CRUDE, humble, irregular and worn. No refined craftsmanship, symmetrical shapes, polished ornamental surfaces, formal repeated decorations, seals, writing, standardized tools, fired pottery, woven cloth, metal, workshops, benches, buildings or clothed figures. No people needed. No automatic river motif. Show the object clearly in the lower half, with sparse bare dust, coarse stone or cave traces; upper half and broad margins remain cream paper. Painterly illustration, never photography, glossy 3D, vector icon, text, frame or grid. One distinct square image.')

def build():
    source=(bank.ROOT/'scripts/prehistoric_artifacts.gd').read_text()
    c={k:json.loads(re.search(r'const '+k+r' := (\[[^\n]+\])',source)[1]) for k in ['FORMS','VARIANTS','TRACES','MATERIALS','SUBJECTS']}
    prior=json.loads(bank.MANIFEST.read_text()) if bank.MANIFEST.exists() else {'entries':[]};old={e['catalogue_id']:e for e in prior['entries']};rows=[]
    for i in range(4096):
        f=i%16;v=(i//16)%16;t=(i//256)%16
        name=f"{c['VARIANTS'][v].capitalize()} {c['FORMS'][f]} · {c['TRACES'][t]}"
        prompt=f"Use case: historical-scene. Prehistoric exploration artifact {i:04d}: {name}.\n{GUIDE}\nSpecific subject: {SCENES[f]}\nMaterial: {c['MATERIALS'][f]}. Distinguishing physical variant: {c['VARIANTS'][v]}. Surface preservation: {c['TRACES'][t]}; show this as natural weathering or residue, not sophisticated decoration. Preserve the recognizable crude object and prehistoric origin above all."
        row={'catalogue_id':i,'artifact_origin':'prehistoric','name':name,'form':c['FORMS'][f],'material':c['MATERIALS'][f],'variant':c['VARIANTS'][v],'trace':c['TRACES'][t],'discovery_id':c['SUBJECTS'][f],'path':f'res://assets/ui/artifacts/prehistoric-v1/artifact-{i:04d}.png','prompt':prompt,'status':'pending'}
        row.update({k:value for k,value in old.get(i,{}).items() if k in ['status','sha256','source','width','height','review','generation_prompt','revisions']});rows.append(row)
    data={'version':1,'expected_count':4096,'collection':'prehistoric-v1','generator':'built-in image_gen','style_references':[f'art_source/artifact-paper-references/style-{i}.png' for i in range(1,5)],'entries':rows}
    bank.DEST.mkdir(parents=True,exist_ok=True);bank.MANIFEST.parent.mkdir(parents=True,exist_ok=True);bank.write_document(bank.MANIFEST,data);bank.MANIFEST.with_name('.gitignore').write_text('*.lock\nproduction-control.json\n');bank.write_index(data)
    print('Built 4096 prehistoric-only entries; civilization artwork is separate.')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['build','register','audit','next']);p.add_argument('--id',type=int);p.add_argument('--source');p.add_argument('--review');p.add_argument('--complete',action='store_true');p.add_argument('--limit',type=int,default=4);a=p.parse_args()
    if a.command=='build':build()
    elif a.command=='register':
        with open(bank.MANIFEST.with_suffix('.lock'),'w') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX);bank.register(a.id,a.source,a.review)
    elif a.command=='audit':raise SystemExit(bank.audit(a.complete))
    else:print(json.dumps([{'catalogue_id':e['catalogue_id'],'prompt':e['prompt']} for e in json.loads(bank.MANIFEST.read_text())['entries'] if e['status']=='pending'][:a.limit]))
