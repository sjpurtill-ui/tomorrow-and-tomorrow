#!/usr/bin/env python3
"""Preserve an unsuitable original and queue a specifically corrected subject."""
import argparse
import fcntl
import json
import shutil
import prehistoric as p
from creative import STYLE

def revise(identifier, reason, subject):
    manifest=json.loads(p.bank.MANIFEST.read_text())
    row=manifest['entries'][identifier]
    assert row['status'] in ('generated','approved')
    source=p.bank.ROOT/row['path'].removeprefix('res://')
    revisions=row.setdefault('revisions',[])
    destination=p.bank.MANIFEST.parent/'rejected'/f'artifact-{identifier:04d}-revision-{len(revisions)+1}.png'
    destination.parent.mkdir(parents=True,exist_ok=True)
    assert not destination.exists()
    shutil.move(str(source),str(destination))
    imported=source.with_suffix('.png.import')
    if imported.exists():shutil.move(str(imported),str(destination.with_suffix('.png.import')))
    revisions.append({'path':str(destination.relative_to(p.bank.ROOT)),'reason':reason,
        **{key:row[key] for key in ('source','sha256','review','prompt') if key in row}})
    for key in ('source','sha256','review','width','height'):row.pop(key,None)
    row.update(status='pending',prompt_override=True,
        prompt=f"Use case: historical-scene. Artifact {identifier:04d}: {row['name']}.\n{STYLE}\nSpecific corrected subject: {subject}\nUnderlying idea (NO TEXT): {row['insight']}")
    p.bank.write_document(p.bank.MANIFEST,manifest)
    p.bank.write_index(manifest)
    print(f'Preserved revision and queued {identifier}')

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('id',type=int)
    parser.add_argument('--reason',required=True)
    parser.add_argument('--subject',required=True)
    args=parser.parse_args()
    with open(p.bank.MANIFEST.with_suffix('.lock'),'w') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        revise(args.id,args.reason,args.subject)
