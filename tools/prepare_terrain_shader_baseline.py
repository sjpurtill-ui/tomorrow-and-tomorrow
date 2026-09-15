#!/usr/bin/env python3
"""Extract the prior terrain shader for the isolated native comparison."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('revision', help='Reviewed prior integrated Git revision')
args = parser.parse_args()
revision = subprocess.check_output(['git', '-C', str(root), 'rev-parse', '--verify', args.revision + '^{commit}'], text=True).strip()


def source(path):
    return subprocess.check_output(['git', '-C', str(root), 'show', revision + ':' + path], text=True)


terrain = source('scripts/local_terrain.gd').split('func _create_terrain_material()', 1)[1]
shader = terrain.split('shader.code = """', 1)[1].split('"""', 1)[0]
# Freeze revision-owned include bodies too. Leaving res:// include directives in
# the baseline caused both baseline and candidate Shader objects to load the
# candidate checkout's helpers, invalidating paired measurements of include work.
for include_path in ('scripts/surface_precision.gdshaderinc',
                     'scripts/ground_surface.gdshaderinc',
                     'scripts/seasonal_surface.gdshaderinc'):
    directive = '#include "res://' + include_path + '"'
    assert directive in shader
    shader = shader.replace(directive, source(include_path))
cutting = source('scripts/landscape_resource_visuals.gd').split('const CUTTING_SHADER:="""', 1)[1].split('"""', 1)[0]
assert shader.count('varying vec3 world_position;') == 1
shader = shader.replace('varying vec3 world_position;', cutting + '\nvarying vec3 world_position;')
folder = root / 'artifacts' / 'terrain-shader-cost'
folder.mkdir(parents=True, exist_ok=True)
(folder / '.gdignore').touch()
destination = folder / 'baseline-shader.txt'
if destination.exists() and destination.read_text() != shader:
    raise RuntimeError('Refusing to replace a different baseline; preserve that comparison first.')
destination.write_text(shader)
receipt = {'revision': revision, 'sha256': hashlib.sha256(shader.encode()).hexdigest()}
(folder / 'baseline.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt))
