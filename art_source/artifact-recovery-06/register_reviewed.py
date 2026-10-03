"""Register individually inspected built-in results and preserve exact prompts."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/artifact_art'))
import prehistoric
from locking import manifest_lock

bank = prehistoric.bank
records = json.loads(Path(__file__).with_name('reviewed.json').read_text(encoding='utf-8'))
with manifest_lock(bank.MANIFEST.with_suffix('.lock')):
    for record in records:
        bank.register(record['id'], record['source'], record['review'])
    document = json.loads(bank.MANIFEST.read_text(encoding='utf-8'))
    raw = bank.MANIFEST.read_bytes()
    for record in records:
        row = document['entries'][record['id']]
        if record.get('prompt_verified', True):
            row['generation_prompt'] = record['prompt']
        pattern = rb'    \{\r*\n      "catalogue_id": ' + str(record['id']).encode() + rb',.*?    \},\r*\n'
        replacement = ('    ' + json.dumps(row, indent=2, ensure_ascii=False).replace('\n', '\n    ') + ',\n').encode()
        raw, count = re.subn(pattern, lambda match: replacement, raw, flags=re.S)
        assert count == 1
    bank.MANIFEST.write_bytes(raw)
print('Reviewed originals and exact generation prompts recorded:', len(records))
