"""Bake Blender combat clips into shared GPU vertex-animation textures.

One mesh and two floating-point EXRs per unit animate every representative
in a Godot MultiMesh. No per-representative skeleton or animation player.
"""
import bpy
import json
import math
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/basic_units/crowds'
OUT.mkdir(parents=True,exist_ok=True)
support='--support' in sys.argv
industrial='--industrial' in sys.argv
historical='--historical' in sys.argv
classical='--classical' in sys.argv
medieval='--medieval' in sys.argv
source='industrial_units/industrial_units.blend' if industrial else ('support_units/support_units.blend' if support else 'basic_units/basic_units.blend')
if historical: source='historical_units/historical_units.blend'
if classical: source='classical_units/classical_units.blend'
if medieval: source='medieval_units/medieval_units.blend'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_source'/source))
scene=bpy.context.scene
WIDTH=128
CLIPS=[('idle',8,48,True),('walk',8,24,True),('attack',15,42,False),('death',21,60,False)]

def save_texture(name, pixels, height):
    image=bpy.data.images.new(name,WIDTH,height,alpha=True,float_buffer=True)
    image.colorspace_settings.name='Non-Color'
    image.pixels.foreach_set(pixels)
    image.filepath_raw=str(OUT/(name+'.exr'))
    image.file_format='OPEN_EXR'
    image.save()
    bpy.data.images.remove(image)

ids=['rifle_infantry','machine_gun_company','motorized_infantry'] if industrial else (['cavalry','siege_engineer','field_artillery'] if support else ['levy','line_infantry','skirmisher'])
if historical: ids=['slinger','javelin_skirmisher','crossbow_infantry','chariot_archer','horse_archer','camel_cavalry']
if classical: ids=['pike_phalanx','legionary_infantry','war_elephant','battering_ram','siege_tower']
if medieval: ids=['armored_foot','pavise_crossbowman','longbowman','counterweight_trebuchet','hand_cannon_team','bombard']
for unit_id in ids:
    rig=bpy.data.objects[unit_id]; obj=bpy.data.objects[unit_id+'_mesh']
    rig.location=(0,0,0)
    for track in rig.animation_data.nla_tracks: track.mute=True
    obj.data.calc_loop_triangles()
    # Godot's front faces are clockwise; Blender's are counterclockwise.
    corners=[(tri.vertices[i],tri.loops[i],tri.material_index) for tri in obj.data.loop_triangles for i in (0,2,1)]
    rows=math.ceil(len(corners)/WIDTH)
    total=sum(c[1] for c in CLIPS)
    height=rows*total
    positions=[0.0]*(WIDTH*height*4); normals=[0.0]*len(positions)
    colors=[]; team=[]
    for _,_,mat_idx in corners:
        mat=obj.data.materials[mat_idx]
        colors.extend(list(mat.diffuse_color))
        team.append(1.0 if mat.name=='team_color' else 0.0)
    frame_index=0; clips={}; base=[]; base_normals=[]
    for clip,count,end,loop in CLIPS:
        strip=rig.animation_data.nla_tracks[clip].strips[0]
        rig.animation_data.action=strip.action; rig.animation_data.action_slot=strip.action_slot
        clips[clip]={'start':frame_index,'count':count,'duration':end/24,'loop':loop}
        for sample in range(count):
            frame=end*sample/(count if loop else count-1)
            scene.frame_set(int(frame),subframe=frame%1)
            evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
            mesh=evaluated.to_mesh()
            for index,(vertex,loop_index,_) in enumerate(corners):
                v=evaluated.matrix_world@mesh.vertices[vertex].co
                n=mesh.corner_normals[loop_index].vector
                # Blender Z up / -Y forward -> Godot Y up / +Z forward.
                point=(v.x,v.z,-v.y); normal=(n.x,n.z,-n.y)
                # EXR image rows are flipped by the image-file convention.
                # Write top-to-bottom lookup rows into Blender's bottom-up pixels.
                row=frame_index*rows+index//WIDTH
                offset=((height-1-row)*WIDTH+index%WIDTH)*4
                positions[offset:offset+4]=[*point,1.0]
                normals[offset:offset+4]=[*normal,1.0]
                if frame_index==0: base.extend(point); base_normals.extend(normal)
            evaluated.to_mesh_clear()
            frame_index+=1
    save_texture(unit_id+'_positions',positions,height)
    save_texture(unit_id+'_normals',normals,height)
    data={'width':WIDTH,'rows_per_frame':rows,'height':height,'vertex_count':len(corners),
          'positions':base,'normals':base_normals,'colors':colors,'team':team,'clips':clips}
    (OUT/(unit_id+'.json')).write_text(json.dumps(data,separators=(',',':')))
    print('CROWD_BAKED',unit_id,len(corners),total,WIDTH,height)
