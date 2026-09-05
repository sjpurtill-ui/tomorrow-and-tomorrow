"""Rebuild the original early-unit asset pack with Blender's bundled Python.

blender --background --python tools/build_basic_units.py
No external assets or Python dependencies. Coordinates: metres, Z up, -Y forward.
"""
import bpy
import math
import json
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
sys.dont_write_bytecode = True
from basic_unit_motion import combat_pose
OUT = ROOT / 'assets' / 'models' / 'basic_units'
SOURCE = ROOT / 'art_source' / 'basic_units'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.fps = 24
scene.world.color = (.20, .20, .20)

def material(name, color, metal=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = .78
    p.inputs['Metallic'].default_value = metal
    return m

M = {k: material(k, c, .5 if k in ('iron', 'bronze') else 0) for k,c in {
    'skin':(.63,.40,.24), 'cloth_levy':(.34,.24,.16),
    'cloth_infantry':(.24,.29,.33), 'cloth_skirmisher':(.18,.32,.22),
    'leather':(.12,.075,.042), 'wood':(.36,.20,.08),
    'iron':(.40,.45,.48), 'bronze':(.60,.40,.17),
    'shield_red':(.49,.12,.085), 'linen':(.71,.62,.43),
    'hair':(.075,.043,.025), 'eyes':(.026,.021,.016),
    'team_color':(.23,.53,.61), 'stone':(.25,.26,.24),
}.items()}
parts=[]

def finish(obj, name, mat, bone):
    obj.name=name
    obj.data.materials.append(M[mat])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bone:
        g=obj.vertex_groups.new(name=bone)
        g.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
    parts.append(obj)
    return obj

def box(name, pos, size, mat, bone, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    o=bpy.context.object; o.scale=size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod=o.modifiers.new('Crafted edges','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,mat,bone)

def ellipsoid(name,pos,size,mat,bone):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=1, location=pos)
    o=bpy.context.object; o.scale=size
    return finish(o,name,mat,bone)

def rod(name,a,b,r,mat,bone,r2=None,vertices=8):
    direction=Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r, radius2=r if r2 is None else r2,
        depth=direction.length, location=(Vector(a)+Vector(b))/2)
    o=bpy.context.object; o.rotation_euler=direction.to_track_quat('Z','Y').to_euler()
    return finish(o,name,mat,bone)

def ribbon(name,points,r,mat,bone):
    for i in range(len(points)-1): rod(name+str(i),points[i],points[i+1],r,mat,bone,vertices=6)

units=[]
manifest={'units':[], 'fps':24, 'forward_axis_godot':'+Z', 'height_metres':1.82,
          'clips':{'idle':2.0,'walk':1.0,'attack':1.75,'death':2.5}}
for kind,label in [('levy','LEVY'),('line_infantry','SPEAR INFANTRY'),('skirmisher','BOW SKIRMISHER')]:
    parts=[]
    archer=kind=='skirmisher'
    cloth='cloth_'+('infantry' if kind=='line_infantry' else kind)
    joints={'root':(0,0,0),'pelvis':(0,0,.89),'chest':(0,0,1.16),'head':(0,0,1.56)}
    parent={'pelvis':'root','chest':'pelvis','head':'chest'}
    for side,s in [('L',-1),('R',1)]:
        joints['thigh.'+side]=(s*.13,0,.89)
        joints['shin.'+side]=(s*.14,0,.49)
        joints['foot.'+side]=(s*.14,0,.12)
        joints['upper_arm.'+side]=(s*.28,0,1.43)
        joints['forearm.'+side]=(s*.38,-.06,1.15)
        joints['hand.'+side]=(s*.38,-.25,1.19)
        if archer:
            joints['forearm.'+side]=(-.36,-.23,1.40) if side=='L' else (.27,.015,1.40)
            joints['hand.'+side]=(-.38,-.48,1.40) if side=='L' else (-.22,-.06,1.40)
        for child,par in [('thigh','pelvis'),('shin','thigh.'+side),('foot','shin.'+side),
                          ('upper_arm','chest'),('forearm','upper_arm.'+side),('hand','forearm.'+side)]:
            parent[child+'.'+side]=par
    if archer:
        joints['bowstring']=tuple(Vector(joints['hand.L'])+Vector((0,.10,0)))
        joints['arrow']=joints['bowstring']
        parent['bowstring']='hand.L'; parent['arrow']='hand.L'
    arm_data=bpy.data.armatures.new(kind+'_skeleton')
    rig=bpy.data.objects.new(kind,arm_data); scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig; rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for name,p in joints.items():
        b=arm_data.edit_bones.new(name); b.head=p; b.tail=Vector(p)+Vector((0,0,.12))
        if name in parent: b.parent=arm_data.edit_bones[parent[name]]
    bpy.ops.object.mode_set(mode='OBJECT')
    for b in rig.pose.bones: b.rotation_mode='XYZ'
    rod('Tunic skirt',(0,0,.79),(0,0,1.07),.265,cloth,'pelvis',.21,10)
    box('Tunic torso',(0,0,1.25),(.49,.28,.42),cloth,'chest',.065)
    box('Belt',(0,-.005,1.06),(.47,.30,.065),'leather','pelvis',.012)
    box('Buckle',(0,-.163,1.06),(.07,.025,.058),'bronze','pelvis',.008)
    box('Supply pouch',(.22,-.09,.97),(.12,.12,.14),'leather','pelvis')
    rod('Neck',(0,0,1.45),(0,0,1.57),.075,'skin','head')
    ellipsoid('Face',(0,-.008,1.655),(.135,.115,.165),'skin','head')
    ellipsoid('Hair cap',(0,.02,1.746),(.138,.115,.072),'hair','head')
    box('Nose',(0,-.123,1.651),(.04,.043,.063),'skin','head',.009)
    for s in [-1,1]:
        box('Eye',(s*.053,-.113,1.685),(.027,.014,.013),'eyes','head',.002)
        ellipsoid('Ear',(s*.132,.005,1.659),(.022,.03,.045),'skin','head')
    box('Collar',(0,-.152,1.435),(.19,.015,.035),'linen','chest',.008)
    box('Faction tab',(.18,-.155,1.30),(.065,.014,.13),'team_color','chest',.005)
    for side,s in [('L',-1),('R',1)]:
        t,k,f=[joints[n+'.'+side] for n in ['thigh','shin','foot']]
        rod('Leg '+side,t,k,.085,'skin','thigh.'+side,.075)
        rod('Calf '+side,k,f,.071,'skin','shin.'+side,.055)
        rod('Boot cuff '+side,(s*.14,0,.12),(s*.14,0,.29),.072,'leather','shin.'+side,.072)
        box('Boot '+side,(s*.14,-.055,.07),(.145,.27,.14),'leather','foot.'+side,.03)
        shoulder,elbow,hand=[Vector(joints[n+'.'+side]) for n in ['upper_arm','forearm','hand']]
        rod('Sleeve '+side,shoulder,shoulder.lerp(elbow,.48),.105,cloth,'upper_arm.'+side,.094)
        rod('Upper arm '+side,shoulder.lerp(elbow,.4),elbow,.069,'skin','upper_arm.'+side,.064)
        ellipsoid('Elbow '+side,elbow,(.065,.065,.065),'skin','forearm.'+side)
        rod('Forearm '+side,elbow,hand,.06,'skin','forearm.'+side,.046)
        rod('Wrist wrap '+side,elbow.lerp(hand,.65),hand,.057,'leather','forearm.'+side,.049)
        ellipsoid('Hand '+side,hand,(.063,.064,.070),'skin','hand.'+side)
    if kind=='levy':
        rod('Club shaft',(.38,-.25,.98),(.38,-.25,1.72),.036,'wood','hand.R',.05)
        ellipsoid('Stone club head',(.38,-.25,1.70),(.095,.073,.13),'stone','hand.R')
        for z in [1.63,1.67,1.71]:
            rod('Head binding',(.38,-.25,z),(.38,-.25,z+.014),.079,'linen','hand.R',vertices=8)
        box('Cloth headband',(0,-.005,1.741),(.274,.239,.037),'linen','head',.04)
    elif kind=='line_infantry':
        # Long shaft and a broad leaf-shaped spearhead stay readable at strategy distance.
        rod('Spear',(.38,-.25,.10),(.38,-.25,2.15),.022,'wood','hand.R')
        rod('Leaf spear lower',(.38,-.25,2.10),(.38,-.25,2.19),.013,'iron','hand.R',.065,4)
        rod('Leaf spear tip',(.38,-.25,2.19),(.38,-.25,2.42),.065,'iron','hand.R',0,4)
        rod('Shield rim',(-.38,-.30,1.12),(-.38,-.37,1.12),.325,'bronze','hand.L',vertices=12)
        rod('Red shield',(-.38,-.375,1.12),(-.38,-.395,1.12),.295,'shield_red','hand.L',vertices=12)
        rod('Shield boss',(-.38,-.40,1.12),(-.38,-.46,1.12),.076,'iron','hand.L',.035,10)
        for s in [-1,1]: box('Shield motif',(-.38+s*.15,-.409,1.12),(.035,.015,.40),'linen','hand.L',.002)
        ellipsoid('Helmet dome',(0,.012,1.763),(.154,.139,.11),'iron','head')
        box('Helmet brow',(0,-.124,1.728),(.30,.045,.046),'bronze','head',.008)
        for s in [-1,1]: box('Cheek guard',(s*.123,-.03,1.65),(.035,.14,.13),'iron','head',.015)
        box('Padded breastplate',(0,-.14,1.27),(.36,.065,.25),'iron','chest',.035)
    else:
        h=Vector(joints['hand.L'])
        points=[tuple(h+Vector((0,-.15*math.sin(math.pi*i/8),-.49+.98*i/8))) for i in range(9)]
        ribbon('Bow stave',points,.018,'wood','hand.L')
        midpoint=h+Vector((0,.10,0))
        for endpoint in (Vector(points[0]),Vector(points[-1])):
            string=rod('Bowstring',endpoint,midpoint,.0035,'linen','hand.L',vertices=6)
            center_group=string.vertex_groups.new(name='bowstring')
            # Only the nocking ends follow the draw bone; limb tips stay fixed.
            for vertex in string.data.vertices:
                world=string.matrix_world@vertex.co
                if (world-midpoint).length < (world-endpoint).length:
                    string.vertex_groups['hand.L'].remove([vertex.index])
                    center_group.add([vertex.index],1.0,'REPLACE')
        rod('Arrow',midpoint,midpoint+Vector((0,-.92,0)),.008,'wood','arrow',vertices=6)
        rod('Arrowhead',midpoint+Vector((0,-.90,0)),midpoint+Vector((0,-1.00,0)),.033,'iron','arrow',0,4)
        box('Arrow fletching',midpoint+Vector((0,-.04,0)),(.018,.09,.06),'linen','arrow',.001)
        rod('Quiver',(.14,.20,1.01),(.24,.22,1.49),.078,'leather','chest',.085)
        for i in range(4):
            x=.20+(i%2)*.045; y=.20+(i//2)*.045
            rod('Spare arrow',(x,y,1.35),(x+.06,y,1.66),.006,'wood','chest',vertices=5)
            box('Fletching',(x+.055,y,1.62),(.025,.016,.07),'linen','chest',.001)
        # Soft green cap with a visible leather brow.
        ellipsoid('Archer cap',(0,.016,1.76),(.15,.13,.084),cloth,'head')
        box('Cap band',(0,-.01,1.724),(.28,.24,.028),'leather','head',.035)
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts: o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    mesh=bpy.context.object; mesh.name=kind+'_mesh'
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    mod=mesh.modifiers.new('Unit skeleton','ARMATURE'); mod.object=rig
    mesh.parent=rig
    # Rigid weights deliberately preserve the faceted toy-soldier silhouette.
    for clip,duration in manifest['clips'].items():
        action=bpy.data.actions.new(clip)
        rig.animation_data_create(); rig.animation_data.action=action
        end=round(duration*24)
        for f in range(end+1):
            t=f/end; phase=t*math.tau
            for b in rig.pose.bones: b.rotation_euler=(0,0,0); b.location=(0,0,0); b.scale=(1,1,1)
            p=rig.pose.bones
            p['chest'].rotation_euler.x=.018*math.sin(phase)
            if clip=='walk':
                p['pelvis'].location.y=.025*(1-math.cos(phase*2))
                for side,s in [('L',1),('R',-1)]:
                    p['thigh.'+side].rotation_euler.x=s*.43*math.sin(phase)
                    p['shin.'+side].rotation_euler.x=-.48*max(0,s*math.sin(phase))
                    p['foot.'+side].rotation_euler.x=.15*max(0,s*math.sin(phase))
                    p['upper_arm.'+side].rotation_euler.x=-s*(.045 if archer else .13)*math.sin(phase)
            elif clip in ('attack','death'):
                combat_pose(rig,joints,kind,clip,t)
            for b in p:
                b.keyframe_insert('rotation_euler',frame=f)
                b.keyframe_insert('location',frame=f)
                b.keyframe_insert('scale',frame=f)
        slot=rig.animation_data.action_slot
        rig.animation_data.action=None
        track=rig.animation_data.nla_tracks.new(); track.name=clip
        strip=track.strips.new(clip,0,action)
        if hasattr(strip,'action_slot'): strip.action_slot=slot
        track.mute=True
    for b in rig.pose.bones: b.rotation_euler=(0,0,0); b.location=(0,0,0)
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); mesh.select_set(True)
    bpy.context.view_layer.objects.active=rig
    # Solo this rig in its editable source file and export one self-contained GLB.
    bpy.ops.export_scene.gltf(filepath=str(OUT/(kind+'.glb')),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,
        export_nla_strips_merged_animation_name='idle',export_materials='EXPORT')
    triangles=sum(len(p.vertices)-2 for p in mesh.data.polygons)
    manifest['units'].append({'id':kind,'label':label,'file':kind+'.glb','triangles':triangles,'bones':len(joints)})
    units.append((rig,mesh,label))

# Shared Blender source has all three fully editable rigs, meshes and clips.
for i,(rig,mesh,label) in enumerate(units):
    rig.location.x=(i-1)*2.3
    for track in rig.animation_data.nla_tracks: track.mute=True
    idle_strip=rig.animation_data.nla_tracks['idle'].strips[0]
    rig.animation_data.action=idle_strip.action
    rig.animation_data.action_slot=idle_strip.action_slot
scene.frame_start=0; scene.frame_end=60; scene.frame_set(0)
scene.render.engine='CYCLES'; scene.cycles.samples=32
scene.render.resolution_x=1500; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.16,.19,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
ground_mat=material('Preview ground',(.035,.052,.06))
bpy.ops.mesh.primitive_plane_add(size=200)
ground=bpy.context.object; ground.name='Preview ground'; ground.data.materials.append(ground_mat)
for x in [-2.3,0,2.3]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=.85,depth=.07,location=(x,0,-.025))
    bpy.context.object.data.materials.append(M['stone'])
def text_obj(body,pos,size):
    curve=bpy.data.curves.new('Caption','FONT'); curve.body=body; curve.align_x='CENTER'; curve.size=size; curve.extrude=.0003
    o=bpy.data.objects.new(body,curve); scene.collection.objects.link(o); o.location=pos
    o.rotation_euler=(math.radians(70),0,0); curve.materials.append(M['linen'])
for i,(_,_,label) in enumerate(units): text_obj(label,((i-1)*2.3,-1.03,.10),.17)
text_obj('TOMORROW AND TOMORROW',(0,.55,2.90),.22)
text_obj('FOUNDING FORCES  /  FIRST ASSET SET',(0,.55,2.62),.105)
for name,loc,power,size in [('Key',(-3,-4,7),950,5),('Fill',(4,-1,4),700,4),('Rim',(1,4,6),1200,3)]:
    data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.shape='DISK'; data.size=size
    o=bpy.data.objects.new(name,data); scene.collection.objects.link(o); o.location=loc
    o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Presentation camera'); cam=bpy.data.objects.new('Presentation camera',data)
scene.collection.objects.link(cam); cam.location=(3,-10,6)
cam.rotation_euler=(Vector((0,0,1.3))-cam.location).to_track_quat('-Z','Y').to_euler()
data.type='ORTHO'; data.ortho_scale=8.4; scene.camera=cam
scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(SOURCE/'basic_units_preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'basic_units.blend'))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
bpy.ops.render.render(write_still=True)
print('BASIC_UNITS_BUILD_COMPLETE '+json.dumps(manifest))
