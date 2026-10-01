"""Preserve reviewed imagegen originals and update only selected subject bindings."""
import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
rows = json.loads((HERE / 'selected.json').read_text(encoding='utf-8'))
def replace_member(raw, key, value, allow_insert=False):
    match = re.search(r'(?m)^  "' + re.escape(key) + r'":\s*', raw)
    encoded = json.dumps(value)
    if match:
        _, length = json.JSONDecoder().raw_decode(raw[match.end():])
        return raw[:match.end()] + encoded + raw[match.end()+length:]
    assert allow_insert
    end = raw.rfind('\n}')
    assert end >= 0
    return raw[:end].rstrip() + ',\n  "' + key + '": ' + encoded + raw[end:]
manifest_path = ROOT / 'assets/ui/research/subject-art-manifest.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
first = json.loads((ROOT / 'assets/ui/research/paper/first300-card-bindings.json').read_text())
art600_path = ROOT / 'data/research/art_600.json'
art600_document = json.loads(art600_path.read_text())
art600 = art600_document['items']
for row in rows:
    key = row['id']
    assert key not in first, 'Resolve higher-priority first-300 binding explicitly'
    assert key not in art600 or row.get('replace_art600', False)
    source = Path(row['source'])
    destination = ROOT / f"assets/ui/research/subjects/{key}-v{row['version']}.png"
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if destination.exists():
        assert hashlib.sha256(destination.read_bytes()).hexdigest() == digest
    else:
        shutil.copy2(source, destination)
    sidecar = destination.with_name(key + '.json')
    prior = HERE / 'prior' / (key + '-v1.json')
    prior.parent.mkdir(exist_ok=True)
    resource_path = 'res://' + destination.relative_to(ROOT).as_posix()
    if sidecar.exists() and not prior.exists() and json.loads(sidecar.read_text()).get('asset') != resource_path:
        shutil.copy2(sidecar, prior)
    metadata = dict(row)
    metadata.update(asset=resource_path,
                    sha256=digest, mode='built-in image_gen / edit')
    sidecar.write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
    manifest[key] = {'path': metadata['asset'], 'focus': row['focus']}
    if row.get('replace_art600', False):
        prior_binding = HERE / 'prior' / (key + '-art600.json')
        if not prior_binding.exists():
            prior_binding.write_text(json.dumps(art600[key], indent=2) + '\n')
        art600[key] = {'path': metadata['asset'], 'style': 'culture: tapestry-inspired painting'}
raw_manifest = manifest_path.read_text(encoding='utf-8')
for row in rows:
    raw_manifest = replace_member(raw_manifest, row['id'], manifest[row['id']], True)
manifest_path.write_text(raw_manifest, encoding='utf-8')
if any(row.get('replace_art600', False) for row in rows):
    raw_art600 = art600_path.read_text(encoding='utf-8')
    for row in rows:
        if row.get('replace_art600', False):
            raw_art600 = replace_member(raw_art600, row['id'], art600[row['id']])
    art600_path.write_text(raw_art600, encoding='utf-8')
print('Preserved and bound reviewed opening paintings:', len(rows))
