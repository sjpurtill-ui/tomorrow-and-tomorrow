import json, hashlib, shutil
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[2]
selected=Path(__file__).with_name('selected.json')
rows=json.loads(selected.read_text(encoding='utf-8'))
for row in rows:
    source=Path(row['source'])
    target=root/'assets/ui/research'/f"{row['id']}-v1.png"
    if 'prior_sha256' not in row:
        row['prior_sha256']=hashlib.sha256(target.read_bytes()).hexdigest()
        row['prior_dimensions']=list(Image.open(target).size)
    row['path']='res://'+target.relative_to(root).as_posix()
    row['dimensions']=list(Image.open(source).size)
    assert row['dimensions'][0]/row['dimensions'][1]>2.5
    shutil.copyfile(source,target)
    row['sha256']=hashlib.sha256(target.read_bytes()).hexdigest()
selected.write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
print('REGISTERED_OVERVIEWS',len(rows))
