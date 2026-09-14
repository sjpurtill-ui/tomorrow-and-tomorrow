#!/usr/bin/env python3
"""Build a resumable, one-image-per-artifact art catalogue. No image generation API."""
import argparse, fcntl, hashlib, json, os, re, shutil, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'assets/ui/artifacts/early-civ-v1'
MANIFEST=ROOT/'art_source/early-civ-art/manifest.json'
INDEX=DEST/'index.json'
STYLE=('Match the supplied game style references: warm ivory fibrous paper, matte gouache and dry brush, worn print grain, broad flat pigment shapes, muted ochre, rust, charcoal and olive, simplified dark human silhouettes, rough fading painted edges, serene historical mood. Generous untouched paper; no photograph, no polished 3D, no vector icon, no text, no labels, no watermark, no frame. One finished square illustration, never a grid. Show the specific artifact prominently and legibly, with sparse period-appropriate human or landscape context. Keep upper 35–45% mostly ivory; concentrate artifact in lower half but leave airy margins. Each entry is a distinct image, not a recolor of another file.')
SCENES=[
'A hand-knapped flint blade with chipped edges and a broad flat face, displayed carefully by a craftsperson over a rough stone slab; sparse riverbank workshop behind. No metal cutting edge.',
'One pierced shell bead threaded on a short plant-fiber cord, enlarged in the foreground beside a maker’s fingers; a soft hint of a shoreline behind.',
'A flattened small bone counting token on a woven mat beside a few seeds, enlarged enough for the markings to read; a seated keeper of stores in the distance.',
'A hand-built earthenware ceremonial bowl seen in three-quarter view on a low wooden stand; sparse gathering silhouettes behind, no modern glazing.',
'A preserved hand-woven plant-fiber textile fragment spread over a low wooden frame; the motif must be woven or dyed into the fibers, with frayed edges and a distant weaver.',
'A flat slate tablet with incised pictorial marks on a rough workbench; one hand brushes dust from its surface; a quiet keeper of oral histories beyond.',
'A straight wooden measuring rod with spaced notches, lying diagonally across a pale work surface; a faint ancient builder silhouette in context.',
'A translucent amber pendant hanging from a simple fiber cord across a dark hand; soft amber pigment, no glossy photographic jewelry lighting.',
'A small carved soapstone seal beside its clear motif impression in wet clay; a sparse storeroom keeper silhouette behind.',
'A small hand-modelled clay figurine with deliberate motif decoration, on a low earthen plinth beside the maker’s hands; no modern sculpture pedestal.',
'A hollow bone flute with credible finger holes, held diagonally above a simple woven mat; a tiny traveler silhouette beside a river in the distance.',
'A weathered wooden panel bearing the painted motif, resting against a low shelter post; sparse silhouettes of a maker and listener behind.',
'A substantial hand-built clay storage jar with visible motif decoration on its rounded body, beside a handful of grain on an earthen floor.',
'A wooden hand spindle with its whorl and a loose strand of plant fiber, displayed over a plain woven mat; a distant seated spinner.',
'A weathered upright basalt route marker in a low grassy landscape, its intentional motif marks large and readable; a tiny traveling figure gives scale.',
'A limestone calendar stone with a careful sequence of tally-like pits and the motif engraved on its face; a distant sky-watcher adds sparse context.'
]
STYLE_DETAILS={
'etched':'Make the motif a deliberate shallow incised line design.',
'painted':'Make the motif a restrained ochre or charcoal pigment design on the object.',
'banded':'Arrange the motif in two clear bands around or along the object.',
'dotted':'Construct the motif from clearly deliberate small dots or impressed pits.',
'spiraling':'Arrange the motif in a gentle curling or spiraling sequence.',
'paired':'Show two deliberately paired examples of the motif on the object.',
'interlaced':'Interlace two motif lines with visibly alternating crossings.',
'radiating':'Arrange the motif outward from a central point.',
'bordered':'Enclose the motif in a simple period-appropriate decorative border.',
'repeated':'Repeat the same motif in an orderly readable sequence.',
'angular':'Make the motif geometric and angular rather than curving.',
'flowing':'Make the motif continuous and fluid with long flowing lines.',
'layered':'Show two overlapping generations of intentional motif decoration.',
'faded':'Show a worn, faded motif that is still legible on an aged surface.',
'polished':'Make the decorated face carefully burnished while retaining the reference’s matte painted aesthetic.',
'miniature':'Show a visibly tiny version beside fingertips or seeds for scale; retain readable motif decoration.'
}
MOTIF_DETAILS={
'river':'a sinuous branching watercourse','sun':'a circular sun with short rays','moon':'a crescent moon','herd':'a small procession of grazing animals','spiral':'a coiled spiral','mountain':'a jagged mountain ridge','seed':'a paired seed or sprouting grain','rain':'descending rain marks','wave':'a repeating cresting wave','hand':'an intentional human handprint','star':'a simple star-shaped cluster','bird':'a bird in profile or flight','leaf':'a veined leaf','hearth':'a small flame enclosed by hearth stones','path':'a winding footpath with footprint-like marks','ancestor':'a simplified elder or ancestral human figure'
}
def constants():
    source=(ROOT/'scripts/artifact_collection.gd').read_text()
    return {key:json.loads(re.search(r'const '+key+r' := (\[[^\n]+\])',source)[1]) for key in ['FORMS','STYLES','FORM_MATERIALS','MOTIFS','SUBJECTS']}
def build():
    c=constants();old=json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {'entries':[]}
    prior={e['catalogue_id']:e for e in old['entries']};entries=[]
    for i in range(4096):
        f=i%16;s=(i//16)%16;m=(i//256)%16
        name=f"{c['FORM_MATERIALS'][f].capitalize()} {c['FORMS'][f]} · {c['STYLES'][s]} {c['MOTIFS'][m]}"
        prompt=f"Use case: historical-scene. Asset: game artifact catalogue {i:04d}, {name}.\nStyle references: all four provided images guide medium, palette and composition only, not their subject.\n{STYLE}\nSubject and context: {SCENES[f]}\nArtifact decoration: {MOTIF_DETAILS[c['MOTIFS'][m]]}. {STYLE_DETAILS[c['STYLES'][s]]} For fiber objects interpret cut or engraved marks as woven or dyed marks; preserve plausible construction. Make the described style and motif distinguish this object from all other entries.\nNo typography or modern objects. Return ONE illustration."
        row={'catalogue_id':i,'artifact_origin':'civilization','name':name,'form':c['FORMS'][f],'material':c['FORM_MATERIALS'][f],'style':c['STYLES'][s],'motif':c['MOTIFS'][m],'discovery_id':c['SUBJECTS'][f],'path':f"res://assets/ui/artifacts/early-civ-v1/artifact-{i:04d}.png",'prompt':prompt,'status':'pending'}
        row.update({k:v for k,v in prior.get(i,{}).items() if k in ['status','sha256','source','width','height','review','generation_prompt']})
        entries.append(row)
    manifest={'version':1,'expected_count':4096,'collection':'early-civ-v1','purpose':'Preserved civilization-made art, never prehistoric exploration finds.','generator':'built-in image_gen','style_references':[f'art_source/artifact-paper-references/style-{i}.png' for i in range(1,5)],'entries':entries}
    DEST.mkdir(parents=True,exist_ok=True);MANIFEST.parent.mkdir(parents=True,exist_ok=True);write_document(MANIFEST,manifest)
    write_index(manifest)
    return manifest

def write_document(path,data):
    temporary=path.with_name(path.name+f'.{os.getpid()}.tmp')
    temporary.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
    temporary.replace(path)

def write_index(manifest):
    approved={str(e['catalogue_id']):{'path':e['path'],'sha256':e['sha256']} for e in manifest['entries'] if e['status']=='approved'}
    write_document(INDEX,{'version':1,'expected_count':4096,'approved':approved})

def import_settings(path):
    resource='res://'+str(path.relative_to(ROOT))
    imported='res://.godot/imported/'+path.name+'-'+hashlib.md5(resource.encode()).hexdigest()+'.ctex'
    config=path.with_suffix(path.suffix+'.import')
    if config.exists():
        text=config.read_text()
        text=re.sub(r'process/size_limit=\d+', 'process/size_limit=512',text)
        config.write_text(text)
    else:
        config.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="'+imported+'"\nmetadata={"vram_texture": false}\n\n[deps]\nsource_file="'+resource+'"\ndest_files=["'+imported+'"]\n\n[params]\ncompress/mode=0\nmipmaps/generate=false\nprocess/size_limit=512\n')

def register(i,source,review=None):
    manifest=json.loads(MANIFEST.read_text());row=manifest['entries'][i];src=Path(source).resolve()
    raw=src.read_bytes()
    if raw[:8]!=b'\x89PNG\r\n\x1a\n':raise ValueError('Expected original generated PNG')
    width,height=struct.unpack('>II',raw[16:24])
    if min(width,height)<1024 or width!=height:raise ValueError('Expected square artwork, at least 1024 pixels')
    digest=hashlib.sha256(raw).hexdigest()
    if any(e.get('sha256')==digest and e['catalogue_id']!=i for e in manifest['entries']):raise ValueError('An existing illustration cannot stand in for a distinct artifact')
    dest=ROOT/row['path'].removeprefix('res://')
    if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest()!=digest:raise ValueError('Do not overwrite an existing original')
    if src!=dest:shutil.copyfile(src,dest)
    import_settings(dest)
    row.update(status='approved' if review else 'generated',sha256=digest,source=row.get('source',str(src)) if src==dest else str(src),width=width,height=height)
    if review:row['review']=review
    write_document(MANIFEST,manifest)
    write_index(manifest)
    print(json.dumps({'id':i,'status':row['status'],'path':str(dest)}))

def audit(require_complete=False):
    data=json.loads(MANIFEST.read_text());errors=[];seen=set();counts={}
    if [e['catalogue_id'] for e in data['entries']]!=list(range(4096)):errors.append('Catalogue IDs are not exactly 0–4095')
    for row in data['entries']:
        status=row['status'];counts[status]=counts.get(status,0)+1
        if status not in ['pending','generated','approved','rejected']:errors.append(f"Invalid status {row['catalogue_id']}")
        if status in ['generated','approved']:
            path=ROOT/row['path'].removeprefix('res://')
            if not path.is_file():errors.append(f"Missing image {row['catalogue_id']}");continue
            digest=hashlib.sha256(path.read_bytes()).hexdigest()
            if digest!=row['sha256']:errors.append(f"Changed image {row['catalogue_id']}")
            if digest in seen:errors.append(f"Duplicate image {row['catalogue_id']}")
            seen.add(digest)
        if status=='approved' and not row.get('review'):errors.append(f"Missing visual review {row['catalogue_id']}")
    if require_complete and counts.get('approved',0)!=4096:errors.append('All 4,096 illustrations must be approved before marking delivery complete')
    print(json.dumps({'counts':counts,'errors':errors},indent=2));return bool(errors)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['build','register','audit','next']);p.add_argument('--id',type=int);p.add_argument('--source');p.add_argument('--review');p.add_argument('--complete',action='store_true');p.add_argument('--limit',type=int,default=8);a=p.parse_args()
    if a.command=='build':build();print('Built 4096 distinct artifact prompts')
    elif a.command=='register':
        with open(MANIFEST.with_suffix('.lock'),'w') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX);register(a.id,a.source,a.review)
    elif a.command=='audit':raise SystemExit(audit(a.complete))
    else:print(json.dumps([{'catalogue_id':e['catalogue_id'],'prompt':e['prompt']} for e in json.loads(MANIFEST.read_text())['entries'] if e['status']=='pending'][:a.limit]))
