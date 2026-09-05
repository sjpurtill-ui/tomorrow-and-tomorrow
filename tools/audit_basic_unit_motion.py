"""Render representative combat beats and report ground bounds from Blender."""
import bpy
import json
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art_source/basic_units/motion_review'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_source/basic_units/basic_units.blend'))
scene=bpy.context.scene
scene.render.resolution_x=1050
scene.render.resolution_y=700
scene.cycles.samples=12
checks=[]
for clip,fraction,label in [('attack',.29,'windup'),('attack',.48,'strike'),
                             ('attack',.61,'release'),('death',.30,'buckle'),
                             ('death',.61,'impact'),('death',.90,'settled')]:
    for name in ['levy','line_infantry','skirmisher']:
        rig=bpy.data.objects[name]
        strip=rig.animation_data.nla_tracks[clip].strips[0]
        rig.animation_data.action=strip.action
        rig.animation_data.action_slot=strip.action_slot
    frame=fraction*(42 if clip=='attack' else 60)
    scene.frame_set(int(frame),subframe=frame%1)
    bpy.context.view_layer.update()
    for name in ['levy','line_infantry','skirmisher']:
        obj=bpy.data.objects[name+'_mesh']
        evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
        mesh=evaluated.to_mesh()
        points=[evaluated.matrix_world@v.co for v in mesh.vertices]
        low=min(range(len(points)),key=lambda i:points[i].z)
        groups=[obj.vertex_groups[g.group].name for g in obj.data.vertices[low].groups]
        checks.append({'unit':name,'beat':label,'min_z':min(p.z for p in points),'max_z':max(p.z for p in points),'lowest_bones':groups})
        evaluated.to_mesh_clear()
    scene.render.filepath=str(OUT/(clip+'_'+label+'.png'))
    if '--bounds-only' not in sys.argv: bpy.ops.render.render(write_still=True)
(OUT/'bounds.json').write_text(json.dumps(checks,indent=2))
print('MOTION_REVIEW_COMPLETE',json.dumps(checks))

# Check every baked combat frame, including transitions between reviewed poses.
worst=[]
for name in ['levy','line_infantry','skirmisher']:
    rig=bpy.data.objects[name]; obj=bpy.data.objects[name+'_mesh']
    for clip,end in [('attack',42),('death',60)]:
        strip=rig.animation_data.nla_tracks[clip].strips[0]
        rig.animation_data.action=strip.action; rig.animation_data.action_slot=strip.action_slot
        lowest=(10,None,None)
        for frame in range(end+1):
            scene.frame_set(frame)
            evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get()); mesh=evaluated.to_mesh()
            for v in mesh.vertices:
                z=(evaluated.matrix_world@v.co).z
                if z<lowest[0]: lowest=(z,frame,[obj.vertex_groups[g.group].name for g in obj.data.vertices[v.index].groups])
            evaluated.to_mesh_clear()
        worst.append({'unit':name,'clip':clip,'min_z':lowest[0],'frame':lowest[1],'bones':lowest[2]})
(OUT/'all_frame_ground_check.json').write_text(json.dumps(worst,indent=2))
print('ALL_FRAME_GROUND_CHECK',json.dumps(worst))
