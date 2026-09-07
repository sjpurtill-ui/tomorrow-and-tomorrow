"""Blender background authoring: derive a 12 m² house for inherited small parcels.
Run from this worktree with Blender --background --python tools/build_organic_small_house.py.
Source kit is metre-sized; shorten both horizontal dimensions, retain full height.
This is an authored smaller building, not a runtime change to the km/metre scale.
"""
import bpy
import math
from pathlib import Path

root = Path(__file__).resolve().parents[1]
kit = root / 'assets/buildings/organic_town'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(kit / 'house_medium.glb'))
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        for vertex in obj.data.vertices:
            vertex.co.x *= math.sqrt(0.5)
            vertex.co.y *= math.sqrt(0.5)
        obj.name = 'House_small_12m2'
bpy.ops.export_scene.gltf(filepath=str(kit / 'house_small.glb'), export_format='GLB', export_yup=True, export_materials='EXPORT')
