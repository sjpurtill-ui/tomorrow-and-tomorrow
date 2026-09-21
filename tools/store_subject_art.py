"""Persist a reviewed-source imagegen result and its exact prompt into this worktree."""
import argparse, hashlib, json, re, shutil
from pathlib import Path

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--payload',required=True)
args=parser.parse_args();data=json.loads(args.payload)
assert re.fullmatch(r'[a-z0-9_]+',data['id'])
source=Path(data['source']);assert source.is_file() and '.codex/generated_images/' in str(source)
collection=data.get('collection','research');assert collection in ['research','military']
folder=root/('assets/ui/'+collection+'/subjects');folder.mkdir(parents=True,exist_ok=True)
version=int(data.get('version',1));assert version>=1
dest=folder/(data['id']+'-v'+str(version)+'.png')
if dest.exists():assert hashlib.sha256(dest.read_bytes()).digest()==hashlib.sha256(source.read_bytes()).digest(), 'Refuse silent replacement'
else:
 temporary=dest.with_suffix('.png.part');shutil.copy2(source,temporary);temporary.replace(dest)
data['asset']='res://'+str(dest.relative_to(root));data['sha256']=hashlib.sha256(dest.read_bytes()).hexdigest();data['mode']=data.get('mode','built-in image_gen / edit' if version>1 else 'built-in image_gen / new image');data['review']='pending visual audit'
(folder/(data['id']+'.json')).write_text(json.dumps(data,indent=2)+'\n')
print(data['id']+' saved')
