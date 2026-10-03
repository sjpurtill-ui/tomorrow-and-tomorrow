"""Install reviewed opening paintings without replacing their predecessors."""
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
selection = json.loads(Path(__file__).with_name('selected.json').read_text(encoding='utf-8'))
manifest_path = ROOT / 'assets/ui/research/subject-art-manifest.json'
bindings_path = ROOT / 'assets/ui/research/paper/first300-card-bindings.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
manifest_text = subprocess.check_output(['git', 'show', 'HEAD:assets/ui/research/subject-art-manifest.json'], cwd=ROOT).decode('utf-8')
bindings = json.loads(bindings_path.read_text(encoding='utf-8'))
for row in selection:
    source = Path(row['source'])
    dest = ROOT / row['asset'].removeprefix('res://')
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if dest.exists():
        assert hashlib.sha256(dest.read_bytes()).hexdigest() == digest, 'Refuse replacement'
    else:
        shutil.copy2(source, dest)
    row['sha256'] = digest
    row['mode'] = 'built-in image_gen'
    sidecar = dest.with_name(row['id'] + '.json')
    sidecar.write_text(json.dumps(row, indent=2) + '\n', encoding='utf-8')
    manifest[row['id']] = {'path': row['asset'], 'focus': row['focus']}
    replacement = json.dumps(manifest[row['id']], indent=2).replace('\n', '\n  ')
    pattern = r'(?m)^  "' + re.escape(row['id']) + r'": \{.*?^  \}'
    manifest_text, count = re.subn(pattern, '  "' + row['id'] + '": ' + replacement, manifest_text, flags=re.S)
    assert count == 1, 'Expected exactly one existing subject entry'
    bindings[row['id']] = row['asset']
manifest_path.write_text(manifest_text, encoding='utf-8')
bindings_path.write_text(json.dumps(bindings, indent=2) + '\n', encoding='utf-8')
Path(__file__).with_name('selected.json').write_text(json.dumps(selection, indent=2) + '\n', encoding='utf-8')
print('Installed', len(selection), 'reviewed original paintings; prior images preserved')
