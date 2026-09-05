"""Build the next three roster units: lancer, ballista crew, and field gun crew."""
from pathlib import Path
import math
import json
import bpy
from mathutils import Vector

# Reuse the original pack's geometry helpers and palette without rebuilding it.
HELPERS=Path(__file__).with_name('build_basic_units.py').read_text().split('\nunits=[]')[0]
exec(compile(HELPERS,str(Path(__file__).with_name('build_basic_units.py')),'exec'))
SOURCE=ROOT/'art_source/support_units'
SOURCE.mkdir(parents=True,exist_ok=True)
M['horse']=material('horse',(.25,.105,.045))
M['horse_dark']=material('horse_dark',(.07,.038,.025))
M['gunmetal']=material('gunmetal',(.10,.14,.15),.7)
M['flash']=material('flash',(1.0,.55,.06))
M['flash'].node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value=(1,.24,.025,1)
M['flash'].node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value=3
CLIPS={'idle':2.0,'walk':1.0,'attack':1.75,'death':2.5}

def wheel(name,x,y,z,r,bone):
    # Wheel in the YZ plane, axle along X.
    bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=6,
        location=(x,y,z),major_radius=r-.035,minor_radius=.04,rotation=(0,math.pi/2,0))
    finish(bpy.context.object,name+' iron tyre','iron',bone)
    rod(name+' hub',(x-.10,y,z),(x+.10,y,z),.08,'wood',bone,vertices=10)
    for i in range(8):
        a=math.tau*i/8
        rod(name+' spoke',(x,y,z),(x,y+math.sin(a)*(r-.06),z+math.cos(a)*(r-.06)),.025,'wood',bone,vertices=6)

def crew(x,y,seat=False):
    # Same faceted face, clothing and faction tab as the founding infantry.
    z=.69 if seat else 0
    base=Vector((x,y,z))
    def at(p): return tuple(base+Vector(p))
    box('Crew tunic',at((0,0,1.25)),(.47,.28,.43),'cloth_infantry' if seat else 'cloth_levy','crew',.05)
    rod('Crew tunic skirt',at((0,0,.81)),at((0,0,1.07)),.24,'cloth_levy','crew',.20,10)
    box('Crew belt',at((0,0,1.05)),(.45,.30,.06),'leather','crew',.01)
    box('Crew buckle',at((0,-.16,1.05)),(.065,.025,.052),'bronze','crew',.008)
    rod('Crew neck',at((0,0,1.46)),at((0,0,1.57)),.07,'skin','head')
    ellipsoid('Crew face',at((0,-.005,1.66)),(.13,.115,.16),'skin','head')
    ellipsoid('Crew headwear',at((0,.01,1.76)),(.145,.13,.08),'iron' if seat else 'cloth_infantry','head')
    box('Crew nose',at((0,-.122,1.65)),(.037,.04,.06),'skin','head',.008)
    for s in [-1,1]: box('Crew eye',at((s*.05,-.113,1.68)),(.025,.015,.012),'eyes','head',.002)
    box('Crew faction tab',at((.16,-.155,1.31)),(.068,.015,.13),'team_color','crew',.006)
    for side,s in [('L',-1),('R',1)]:
        hip=at((s*.13,0,.88))
        knee=at((s*.38,-.23,.62)) if seat else at((s*.14,0,.48))
        ankle=at((s*.40,-.07,.24)) if seat else at((s*.14,0,.12))
        rod('Crew thigh',hip,knee,.082,'cloth_infantry','leg.'+side,.075)
        rod('Crew calf',knee,ankle,.069,'leather','leg.'+side,.05)
        box('Crew boot',tuple(Vector(ankle)+Vector((0,-.06,-.035))),(.14,.26,.13),'leather','leg.'+side,.025)
        shoulder=at((s*.28,0,1.43)); elbow=at((s*.36,-.10,1.19)); hand=at((s*.28,-.32,1.30))
        rod('Crew sleeve',shoulder,tuple(Vector(shoulder).lerp(Vector(elbow),.48)),.10,'cloth_infantry','arm.'+side,.085)
        rod('Crew upper arm',shoulder,elbow,.065,'skin','arm.'+side,.06)
        rod('Crew forearm',elbow,hand,.057,'skin','arm.'+side,.045)
        ellipsoid('Crew hand',hand,(.06,.055,.065),'skin','arm.'+side)
    return base

def rig_for(kind,joints,parents):
    data=bpy.data.armatures.new(kind+'_skeleton'); rig=bpy.data.objects.new(kind,data)
    scene.collection.objects.link(rig); bpy.context.view_layer.objects.active=rig; rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for name,p in joints.items():
        bone=data.edit_bones.new(name); bone.head=p; bone.tail=Vector(p)+Vector((0,0,.12))
        if name in parents: bone.parent=data.edit_bones[parents[name]]
    bpy.ops.object.mode_set(mode='OBJECT')
    for bone in rig.pose.bones: bone.rotation_mode='XYZ'
    return rig

def ease(t,a,b):
    v=min(1,max(0,(t-a)/(b-a)))
    return v*v*(3-2*v)

def pose(rig,kind,clip,t):
    p=rig.pose.bones
    for b in p: b.location=(0,0,0); b.rotation_euler=(0,0,0); b.scale=(1,1,1)
    phase=t*math.tau
    p['crew'].rotation_euler.x=.012*math.sin(phase)
    p['head'].rotation_euler.y=.04*math.sin(phase)
    if clip=='death': p['head'].rotation_euler=(.12*ease(t,.15,.70),0,0)
    if kind=='cavalry':
        p['neck'].rotation_euler.x=.02*math.sin(phase)
        p['tail'].rotation_euler.z=.08*math.sin(phase)
        if clip in ('walk','attack'):
            stride=1 if clip=='walk' else math.sin(math.pi*t)
            p['root'].location.y=.035*(1-math.cos(phase*2))*stride
            for index,name in enumerate(['front.L','front.R','back.L','back.R']):
                swing=math.sin(phase+(0 if index in (0,3) else math.pi))
                p[name].rotation_euler.x=.44*swing*stride
                p[name+'.lower'].rotation_euler.x=-.42*max(0,swing)*stride
            p['neck'].rotation_euler.x=.06*math.sin(phase)*stride
            p['crew'].rotation_euler.x=.045*math.sin(phase)*stride
        if clip=='attack':
            drive=ease(t,.10,.36)*(1-ease(t,.72,1))
            p['lance'].rotation_euler.x=1.48*drive
            p['crew'].rotation_euler.x=.19*drive
            p['neck'].rotation_euler.x=.14*drive
            p['lance'].location.z=.18*ease(t,.36,.44)*(1-ease(t,.54,.80))
        if clip=='death':
            buckle=ease(t,.06,.36); fall=ease(t,.28,.69)
            p['root'].location.y=-.51*fall-.10*buckle*(1-fall)
            p['root'].rotation_euler.z=1.49*fall
            for name in ['front.L','front.R','back.L','back.R']:
                p[name].rotation_euler.x=.52*buckle
                p[name+'.lower'].rotation_euler.x=-1.05*buckle
            p['crew'].rotation_euler.x=.25*buckle
            p['crew'].rotation_euler.z=.12*fall
            p['neck'].rotation_euler.x=.32*fall
            p['lance'].rotation_euler.x=.35*fall
            p['tail'].rotation_euler.z=.3*fall
    else:
        if clip=='walk':
            for name in ['wheel.L','wheel.R']: p[name].rotation_euler.x=phase
            for side,s in [('L',1),('R',-1)]: p['leg.'+side].rotation_euler.x=.30*s*math.sin(phase)
            p['crew'].location.y=.025*(1-math.cos(phase*2))
        if clip=='attack':
            if kind=='siege_engineer':
                draw=ease(t,.10,.36)*(1-ease(t,.48,.54))
                p['bow.L'].rotation_euler.y=-.17*draw
                p['bow.R'].rotation_euler.y=.17*draw
                p['string'].location.z=-.30*draw
                p['bolt'].location.z=-.30*draw
                p['winch'].rotation_euler.x=math.tau*ease(t,.02,.38)
                p['arm.R'].rotation_euler.x=.28*math.sin(phase*2)*(1-ease(t,.4,.5))
                if .50<t<.94:
                    p['bolt'].location.z=6*ease(t,.50,.65)
                    if t>.65: p['bolt'].scale=(.001,)*3
                p['beam'].rotation_euler.x=-.035*math.sin(math.pi*min(1,max(0,(t-.5)/.2)))
            else:
                recoil=ease(t,.32,.36)*(1-ease(t,.39,.78))
                p['barrel'].location.z=-.22*recoil
                p['barrel'].rotation_euler.x=-.035*recoil
                p['crew'].rotation_euler.x=-.13*recoil
                p['arm.R'].rotation_euler.x=.45*ease(t,.1,.25)*(1-ease(t,.35,.64))
                p['flash'].scale=(1,1,1) if .33<t<.40 else (.001,)*3
        if kind=='field_artillery' and clip!='attack': p['flash'].scale=(.001,)*3
        if clip=='death':
            fall=ease(t,.10,.68)
            p['crew'].rotation_euler.x=-1.48*fall
            p['crew'].location.y=-.63*fall
            p['crew'].location.z=-.24*fall
            for side,s in [('L',1),('R',-1)]:
                p['arm.'+side].rotation_euler.z=s*.30*fall
                p['arm.'+side].rotation_euler.x=1.78*fall
                p['leg.'+side].rotation_euler.x=.40*fall
            p['wheel.R'].rotation_euler.z=1.46*fall
            p['wheel.R'].location.x=1.25*fall
            p['wheel.R'].location.y=-.36*fall
            p['body'].rotation_euler.z=-.12*fall
            if kind=='siege_engineer':
                p['beam'].rotation_euler.x=.30*fall
                p['bow.R'].rotation_euler.z=-.7*fall
                p['bolt'].scale=(.001,)*3
            else:
                p['barrel'].rotation_euler.x=.24*fall
                p['barrel'].location.y=-.11*fall

units=[]; manifest={'units':[],'fps':24,'clips':CLIPS,'forward_axis_godot':'+Z'}
for kind,label in [('cavalry','MOUNTED LANCER'),('siege_engineer','SIEGE ENGINEERS'),('field_artillery','FIELD ARTILLERY')]:
    parts=[]
    mounted=kind=='cavalry'
    operator=Vector((0,-.02,.69)) if mounted else Vector((1.08,.40,0))
    joints={'root':(0,0,.92 if mounted else 0),'body':(0,0,.7 if mounted else .45),
            'crew':tuple(operator+Vector((0,0,.90))),'head':tuple(operator+Vector((0,0,1.55)))}
    parents={'body':'root','crew':'root','head':'crew'}
    for side,s in [('L',-1),('R',1)]:
        joints['leg.'+side]=tuple(operator+Vector((s*.13,0,.88)))
        joints['arm.'+side]=tuple(operator+Vector((s*.28,0,1.43)))
        parents['leg.'+side]='crew'; parents['arm.'+side]='crew'
    if mounted:
        joints.update({'neck':(0,-.61,1.20),'tail':(0,.84,1.10),'lance':(.28,-.34,1.99)})
        parents.update({'neck':'body','tail':'body','lance':'crew'})
        for front,y in [('front',-.55),('back',.58)]:
            for side,s in [('L',-1),('R',1)]:
                name=front+'.'+side
                joints[name]=(s*.23,y,.92); joints[name+'.lower']=(s*.25,y,.48)
                parents[name]='body'; parents[name+'.lower']=name
    else:
        joints.update({'wheel.L':(-.73,0,.48),'wheel.R':(.73,0,.48)})
        parents.update({'wheel.L':'root','wheel.R':'root'})
        if kind=='siege_engineer':
            joints.update({'beam':(0,0,1.03),'bow.L':(0,-.52,1.12),'bow.R':(0,-.52,1.12),
                           'string':(0,-.25,1.12),'bolt':(0,-.25,1.15),'winch':(0,.48,.94)})
            parents.update({'beam':'body','bow.L':'beam','bow.R':'beam','string':'beam','bolt':'beam','winch':'body'})
        else:
            joints.update({'barrel':(0,-.1,.94),'flash':(0,-1.3,.99)})
            parents.update({'barrel':'body','flash':'barrel'})
    rig=rig_for(kind,joints,parents)
    crew(float(operator.x),float(operator.y),mounted)
    if mounted:
        ellipsoid('Horse barrel',(0,.07,1.13),(.34,.80,.43),'horse','body')
        ellipsoid('Horse chest',(0,-.47,1.15),(.30,.35,.40),'horse','body')
        rod('Horse neck',(0,-.52,1.23),(0,-.89,1.82),.23,'horse','neck',.16,10)
        ellipsoid('Horse head',(0,-1.00,1.86),(.16,.30,.20),'horse','neck')
        ellipsoid('Horse muzzle',(0,-1.23,1.72),(.135,.20,.115),'horse_dark','neck')
        for s in [-1,1]:
            rod('Horse ear',(s*.105,-.86,1.99),(s*.13,-.85,2.22),.064,'horse','neck',.01,5)
            ellipsoid('Horse eye',(s*.15,-1.08,1.90),(.015,.033,.022),'eyes','neck')
        ribbon('Mane',[(0,-.38,1.50),(0,-.59,1.69),(0,-.77,1.93)],.067,'horse_dark','neck')
        rod('Tail',(0,.77,1.22),(0,1.11,.54),.085,'horse_dark','tail',.035,8)
        box('Saddle blanket',(0,.05,1.40),(.77,.75,.10),'shield_red','body',.04)
        box('Saddle',(0,.10,1.49),(.54,.48,.13),'leather','body',.045)
        for name in ['front.L','front.R','back.L','back.R']:
            a=Vector(joints[name]); b=Vector(joints[name+'.lower']); foot=Vector((b.x,b.y-.04,.105))
            rod('Horse upper leg',a,b,.098,'horse',name,.075)
            ellipsoid('Horse knee',b,(.08,.085,.09),'horse_dark',name+'.lower')
            rod('Horse lower leg',b,foot,.06,'horse',name+'.lower',.046)
            box('Hoof',tuple(foot+Vector((0,-.025,-.02))),(.13,.19,.14),'horse_dark',name+'.lower',.015)
        # Reins are bound to the neck and stay a deliberately simple silhouette.
        for s in [-1,1]: ribbon('Rein',[(s*.16,-1.20,1.78),(s*.24,-.58,1.57),(s*.28,-.34,1.94)],.012,'leather','neck')
        rod('Lance shaft',(.28,-.34,1.21),(.28,-.34,3.20),.022,'wood','lance')
        rod('Lance head',(.28,-.34,3.20),(.28,-.34,3.45),.062,'iron','lance',0,4)
        box('Lance pennon',(.42,-.34,2.98),(.29,.016,.18),'team_color','lance',.002)
    else:
        for side,s in [('L',-1),('R',1)]: wheel('Wheel '+side,s*.73,0,.48,.46,'wheel.'+side)
        rod('Axle',(-.86,0,.48),(.86,0,.48),.065,'iron','body')
        for s in [-1,1]: box('Carriage rail',(s*.34,.25,.57),(.13,1.75,.16),'wood','body',.015)
        box('Cross brace',(0,.25,.65),(.94,.16,.13),'wood','body',.012)
        box('Faction plate',(0,-.47,.69),(.29,.028,.23),'team_color','body',.01)
        if kind=='siege_engineer':
            for s in [-1,1]:
                rod('Frame upright',(s*.38,-.42,.6),(s*.38,-.42,1.28),.09,'wood','body',vertices=4)
                rod('Torsion skein',(s*.38,-.42,.85),(s*.38,-.42,1.25),.075,'linen','body',vertices=10)
                side='L' if s<0 else 'R'
                rod('Bow arm',(s*.08,-.52,1.12),(s*.94,-.66,1.12),.053,'wood','bow.'+side,.025)
                # Split string segment: attachment stays with bow, nock follows string bone.
                endpoint=Vector((s*.94,-.66,1.12)); midpoint=Vector(joints['string'])
                o=rod('Draw cord',endpoint,midpoint,.012,'linen','bow.'+side,vertices=6)
                group=o.vertex_groups.new(name='string')
                for v in o.data.vertices:
                    w=o.matrix_world@v.co
                    if (w-midpoint).length < (w-endpoint).length:
                        o.vertex_groups['bow.'+side].remove([v.index]); group.add([v.index],1,'REPLACE')
            box('Bolt track',(0,-.08,1.06),(.16,1.7,.12),'wood','beam',.012)
            rod('Siege bolt',(0,-.25,1.15),(0,-1.44,1.15),.014,'wood','bolt')
            rod('Siege bolt tip',(0,-1.41,1.15),(0,-1.59,1.15),.06,'iron','bolt',0,4)
            rod('Winch drum',(-.25,.48,.94),(.25,.48,.94),.09,'wood','winch')
            rod('Winch crank',(.27,.48,.94),(.27,.70,.94),.023,'iron','winch')
        else:
            for s in [-1,1]: box('Cheek bracket',(s*.23,-.04,.78),(.10,.55,.35),'wood','body',.035)
            rod('Cannon barrel',(0,.35,.94),(0,-1.24,.99),.17,'gunmetal','barrel',.105,16)
            for y,r in [(.28,.181),(-.10,.155),(-.60,.135),(-1.21,.127)]:
                rod('Barrel reinforcing ring',(0,y-.025,.94+(.35-y)*.031),(0,y+.025,.94+(.35-y)*.031),r,'iron','barrel',vertices=16)
            rod('Dark muzzle bore',(0,-1.273,.99),(0,-1.278,.99),.088,'eyes','barrel',vertices=16)
            rod('Trunnion',(-.34,-.10,.94),(.34,-.10,.94),.055,'iron','barrel')
            rod('Trail',(0,.35,.55),(0,1.38,.14),.095,'wood','body',.065,4)
            rod('Muzzle flash',(0,-1.28,.99),(0,-1.88,.99),.19,'flash','flash',0,7)
            box('Ammo chest',(-1.07,.66,.19),(.40,.45,.36),'wood','root',.025)
            for y in [.56,.72]: ellipsoid('Cannonball',(-1.07,y,.43),(.075,.075,.075),'gunmetal','root')
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts: obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join()
    mesh=bpy.context.object; mesh.name=kind+'_mesh'; bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    modifier=mesh.modifiers.new('Unit skeleton','ARMATURE'); modifier.object=rig; mesh.parent=rig
    crew_groups={g.index for g in mesh.vertex_groups if g.name in ['crew','head','arm.L','arm.R','leg.L','leg.R']}
    crew_vertices=[v.index for v in mesh.data.vertices if any(g.group in crew_groups for g in v.groups)]
    bounds=[]
    for clip,duration in CLIPS.items():
        action=bpy.data.actions.new(clip); rig.animation_data_create(); rig.animation_data.action=action
        end=round(duration*24)
        for frame in range(end+1):
            pose(rig,kind,clip,frame/end)
            bpy.context.view_layer.update()
            # Make sure the full rig stays above the terrain, including equipment.
            evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); evaluated_mesh=evaluated.to_mesh()
            if not mounted:
                crew_low=min((evaluated.matrix_world@evaluated_mesh.vertices[i].co).z for i in crew_vertices)
                if crew_low<.008:
                    evaluated.to_mesh_clear()
                    rig.pose.bones['crew'].location.y+=.008-crew_low
                    bpy.context.view_layer.update()
                    evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); evaluated_mesh=evaluated.to_mesh()
            lowest=min((evaluated.matrix_world@v.co).z for v in evaluated_mesh.vertices)
            evaluated.to_mesh_clear()
            if lowest<.008: rig.pose.bones['root'].location.y+=.008-lowest
            for bone in rig.pose.bones:
                for prop in ['location','rotation_euler','scale']: bone.keyframe_insert(prop,frame=frame)
            bounds.append({'clip':clip,'frame':frame,'ground_correction':max(0,.008-lowest)})
        slot=rig.animation_data.action_slot; rig.animation_data.action=None
        track=rig.animation_data.nla_tracks.new(); track.name=clip
        strip=track.strips.new(clip,0,action); strip.action_slot=slot; track.mute=True
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); mesh.select_set(True); bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/(kind+'.glb')),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_materials='EXPORT')
    triangles=sum(len(p.vertices)-2 for p in mesh.data.polygons)
    manifest['units'].append({'id':kind,'label':label,'file':kind+'.glb','triangles':triangles,'bones':len(joints)})
    (SOURCE/(kind+'_ground_checks.json')).write_text(json.dumps(bounds))
    units.append((rig,mesh,label))

for i,(rig,mesh,label) in enumerate(units):
    rig.location.x=(i-1)*4.2
    for track in rig.animation_data.nla_tracks: track.mute=True
    strip=rig.animation_data.nla_tracks['idle'].strips[0]
    rig.animation_data.action=strip.action; rig.animation_data.action_slot=strip.action_slot
scene.frame_start=0; scene.frame_end=60; scene.frame_set(0)
scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.render.resolution_x=1600; scene.render.resolution_y=900; scene.render.resolution_percentage=100
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.13,.16,.18,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
ground_mat=material('Support preview ground',(.035,.052,.06))
bpy.ops.mesh.primitive_plane_add(size=200); bpy.context.object.data.materials.append(ground_mat)
for i,(_,_,label) in enumerate(units):
    curve=bpy.data.curves.new('Label','FONT'); curve.body=label; curve.align_x='CENTER'; curve.size=.19
    obj=bpy.data.objects.new(label,curve); scene.collection.objects.link(obj)
    obj.location=((i-1)*4.2,-1.85,.05); obj.rotation_euler=(math.radians(70),0,0); curve.materials.append(M['linen'])
for name,loc,power,size in [('Key',(-4,-5,8),1400,6),('Fill',(5,-2,5),1000,5),('Rim',(1,5,7),1700,4)]:
    data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.shape='DISK'; data.size=size
    obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj); obj.location=loc
    obj.rotation_euler=(Vector((0,0,1))-obj.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Presentation camera'); camera=bpy.data.objects.new('Presentation camera',data)
scene.collection.objects.link(camera); camera.location=(4,-13,8)
camera.rotation_euler=(Vector((0,0,1.35))-camera.location).to_track_quat('-Z','Y').to_euler()
data.type='ORTHO'; data.ortho_scale=13.6; scene.camera=camera
scene.render.image_settings.file_format='PNG'; scene.render.filepath=str(SOURCE/'support_units_preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'support_units.blend'))
(OUT/'support_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
bpy.ops.render.render(write_still=True)
print('SUPPORT_UNITS_BUILD_COMPLETE',json.dumps(manifest))
