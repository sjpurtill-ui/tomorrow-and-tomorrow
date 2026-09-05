"""Build classical infantry, elephant, siege engines, and a naval prototype.

Blender background script; all meshes and animation are generated locally.
"""
from pathlib import Path
import math
import json
import bpy
from mathutils import Vector

support_path=Path(__file__).with_name('build_support_units.py')
support_text=support_path.read_text()
exec(compile(support_text.split('\nunits=[]; manifest=')[0],str(support_path),'exec'))
from basic_unit_motion import limb, sample
SOURCE=ROOT/'art_source/classical_units'; SOURCE.mkdir(parents=True,exist_ok=True)
M['elephant']=material('elephant grey',(.32,.34,.32))
M['ivory']=material('ivory',(.78,.72,.52))
M['red']=material('classical red',(.46,.095,.055))
M['hide']=material('siege hide',(.36,.27,.17))
M['hull']=material('hull timber',(.23,.105,.045))
M['cloth_levy']=M['red']; M['cloth_infantry']=M['red']
IDS=['pike_phalanx','legionary_infantry','war_elephant','battering_ram','siege_tower','trireme']
LABELS=['PIKE PHALANX','LEGIONARY INFANTRY','WAR ELEPHANT','BATTERING RAM','SIEGE TOWER','TRIREME']

def add_person_joints(o):
    joints.update({'crew':tuple(o+Vector((0,0,.9))),'head':tuple(o+Vector((0,0,1.55)))})
    parents.update({'crew':'root','head':'crew'})
    for side,s in [('L',-1),('R',1)]:
        for n,pos in [('leg',(s*.13,0,.88)),('arm',(s*.28,0,1.43)),('forearm',(s*.39,-.12,1.17)),('hand',(s*.28,-.32,1.30))]:
            joints[n+'.'+side]=tuple(o+Vector(pos))
        parents.update({'leg.'+side:'crew','arm.'+side:'crew','forearm.'+side:'arm.'+side,'hand.'+side:'forearm.'+side})

def person(o,seat=False):
    start=len(parts); crew(o.x,o.y,seat)
    for obj in list(parts[start:]):
        obj.location.z+=o.z-(.69 if seat else 0)
        if any(g.name.startswith('arm.') for g in obj.vertex_groups):
            parts.remove(obj); bpy.data.objects.remove(obj,do_unlink=True)
    for side in ['L','R']:
        a,b,c=[joints[n+'.'+side] for n in ['arm','forearm','hand']]
        rod('Sleeve',a,b,.075,'red','arm.'+side,.056)
        rod('Forearm',b,c,.053,'skin','forearm.'+side,.045)
        ellipsoid('Hand',c,(.055,.055,.065),'skin','hand.'+side)

def plate_mesh(name,verts,faces,mat,bone):
    data=bpy.data.meshes.new(name); data.from_pydata(verts,[],faces); data.update()
    obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj)
    return finish(obj,name,mat,bone)

def pose(rig,kind,clip,t):
    p=rig.pose.bones; phase=math.tau*t
    for b in p: b.location=(0,0,0); b.rotation_euler=(0,0,0); b.scale=(1,1,1)
    if kind=='trireme':
        if clip!='death':
            p['hull'].rotation_euler.z=.018*math.sin(phase)
            p['hull'].location.y=.04*math.sin(phase)
        if clip in ['walk','attack']:
            for bone in p:
                if bone.name.startswith('oars.'):
                    s=-1 if bone.name.startswith('oars.L') else 1
                    bone.rotation_euler.y=.14*math.sin(phase)
                    bone.rotation_euler.z=s*.025*(1-math.cos(phase))
        if clip=='attack':
            drive=ease(t,.10,.47)*(1-ease(t,.64,1))
            p['root'].location.z=1.5*drive
            p['hull'].rotation_euler.x=-.025*ease(t,.45,.5)*(1-ease(t,.5,.7))
        if clip=='death':
            fall=ease(t,.08,.75)
            p['hull'].rotation_euler.z=.75*fall
            p['hull'].location.y=-2.0*fall
            p['mast'].rotation_euler.x=.65*fall
            for n in p:
                if n.name.startswith('oars.R'): n.rotation_euler.y=.5*fall
        return
    p['crew'].rotation_euler.x=.012*math.sin(phase)
    p['head'].rotation_euler.y=.025*math.sin(phase)
    if clip=='walk':
        if kind=='war_elephant':
            for i,n in enumerate(['front.L','front.R','back.L','back.R']):
                swing=math.sin(phase+(0 if i in [0,3] else math.pi))
                p[n].rotation_euler.x=.22*swing
                p[n+'.lower'].rotation_euler.x=-.26*max(0,swing)
            p['body'].location.y=.028*(1-math.cos(phase*2))
            p['crew'].location.y=.028*(1-math.cos(phase*2))
            p['trunk'].rotation_euler.x=.12*math.sin(phase)
        else:
            for side,s in [('L',1),('R',-1)]: p['leg.'+side].rotation_euler.x=.3*s*math.sin(phase)
            if kind in ['battering_ram','siege_tower']:
                for n in p:
                    if n.name.startswith('wheel'): n.rotation_euler.x=phase
    if clip=='death':
        stagger=ease(t,.02,.22); fall=ease(t,.22,.76)
        p['head'].rotation_euler=(.23*stagger,0,0)
        if kind=='war_elephant':
            p['root'].rotation_euler.z=1.45*fall
            p['root'].location.y=-.8*fall
            p['crew'].rotation_euler.x=.25*stagger
            p['trunk'].rotation_euler.x=.35*fall
            for n in ['front.L','front.R','back.L','back.R']:
                p[n].rotation_euler.x=.35*stagger; p[n+'.lower'].rotation_euler.x=-.65*stagger
        else:
            p['crew'].rotation_euler.x=-1.5*fall
            p['crew'].location.y=-.64*fall
            p['crew'].location.z=-.2*fall
            for side,s in [('L',-1),('R',1)]:
                # Let the arms and weapons fall with the torso. Counter-rotating
                # them upright made the long pike prop the entire corpse up.
                p['arm.'+side].rotation_euler.x=.08*fall
                p['arm.'+side].rotation_euler.z=s*.10*fall
                p['leg.'+side].rotation_euler.x=.4*fall
            if kind in ['battering_ram','siege_tower']:
                p['body'].rotation_euler.z=.23*fall
                p['wheel.FR'].rotation_euler.z=1.2*fall
                p['wheel.FR'].location.x=.6*fall
                if kind=='battering_ram': p['ram'].rotation_euler.x=.45*fall
                else:
                    p['ramp'].rotation_euler.x=1.4*fall
                    p['crown'].rotation_euler.z=.55*fall
        return
    right=Vector(joints['hand.R']); left=Vector(joints['hand.L']); wrist=(0,0,0)
    if clip=='attack':
        thrust=ease(t,.27,.43)*(1-ease(t,.60,.92))
        if kind in ['pike_phalanx','legionary_infantry']:
            wind=ease(t,.04,.23)*(1-ease(t,.64,1))
            right+=Vector((0,.13*wind-.28*thrust,.02*wind))
            left+=Vector((0,-.09*thrust,0))
            p['crew'].rotation_euler.y=-.10*wind+.21*thrust
            p['crew'].rotation_euler.x=.12*thrust
            wrist=(1.48*ease(t,.04,.23)*(1-ease(t,.73,1)),0,0) if kind=='pike_phalanx' else (-1.48*ease(t,.04,.24)*(1-ease(t,.68,1)),0,0)
        elif kind=='war_elephant':
            p['body'].rotation_euler.x=.08*thrust
            p['neck'].rotation_euler.x=.18*thrust
            p['trunk'].rotation_euler.x=-.6*ease(t,.08,.30)*(1-ease(t,.55,.90))
            right+=Vector((0,-.18*thrust,.08*thrust))
        elif kind=='battering_ram':
            pull=ease(t,.04,.25); impact=ease(t,.25,.40); recover=ease(t,.62,1)
            p['ram'].location.z=(-.45*pull+.95*impact)*(1-recover)
            p['ram'].rotation_euler.x=-.06*math.sin(math.pi*t)
            right+=Vector((-.12,-.2*impact,.04*pull))
            left+=Vector((.12,-.2*impact,.04*pull))
            p['crew'].rotation_euler.x=.12*impact*(1-recover)
        elif kind=='siege_tower':
            p['ramp'].rotation_euler.x=1.52*ease(t,.10,.55)
            p['crown'].rotation_euler.x=.01*math.sin(phase)*(1-ease(t,.65,.8))
    bpy.context.view_layer.update()
    for side,target in [('L',left),('R',right)]:
        limb(rig,joints,'arm.'+side,'forearm.'+side,'hand.'+side,target,operator+Vector((-1 if side=='L' else 1,.1,1.1)),wrist if side=='R' else None)

units=[]; manifest={'units':[],'fps':24,'clips':CLIPS,'status':'visual prototypes; gameplay integration pending'}
for kind,label in zip(IDS,LABELS):
    parts=[]; mounted=kind=='war_elephant'
    operator=Vector((0,.20,2.16)) if mounted else (Vector((1.45,.6,0)) if kind in ['battering_ram','siege_tower'] else Vector((0,0,0)))
    joints={'root':(0,0,1.6 if mounted else 0),'body':(0,0,1.7 if mounted else .5)}
    parents={'body':'root'}
    if kind!='trireme': add_person_joints(operator)
    if kind=='war_elephant':
        joints.update({'neck':(0,-1,2.0),'trunk':(0,-1.98,2.25),'tail':(0,1.4,2.1)})
        parents.update({'neck':'body','trunk':'neck','tail':'body'})
        for front,y in [('front',-.82),('back',.88)]:
            for side,s in [('L',-1),('R',1)]:
                n=front+'.'+side; joints[n]=(s*.58,y,1.6); joints[n+'.lower']=(s*.60,y,.78)
                parents[n]='body'; parents[n+'.lower']=n
    if kind in ['battering_ram','siege_tower']:
        for side,x in [('L',-1.15),('R',1.15)]:
            for end,y in [('F',-1.05),('B',1.05)]:
                n='wheel.'+end+side; joints[n]=(x,y,.40); parents[n]='body'
        if kind=='battering_ram': joints['ram']=(0,0,1.0); parents['ram']='body'
        else:
            joints.update({'ramp':(0,-1.1,3.9),'crown':(0,0,4.4)})
            parents.update({'ramp':'body','crown':'body'})
    if kind=='trireme':
        joints.update({'hull':(0,0,0),'mast':(0,0,1.65)}); parents.update({'hull':'root','mast':'hull'})
        for side,s in [('L',-1),('R',1)]:
            for level in range(3):
                for index in range(16):
                    n='oars.'+side+str(level)+'.'+str(index)
                    joints[n]=(s*(1.82+level*.10),-8.4+index*1.08,.42+level*.35)
                    parents[n]='hull'
    rig=rig_for(kind,joints,parents)
    if kind!='trireme': person(operator,mounted)
    if kind in ['pike_phalanx','legionary_infantry']:
        ellipsoid('Bronze helmet',(0,.005,1.76),(.15,.14,.115),'bronze','head')
        for s in [-1,1]: box('Cheek guard',(s*.127,-.03,1.61),(.035,.11,.16),'bronze','head',.015)
        box('Body armor',(0,-.015,1.27),(.47,.32,.35),'bronze' if kind=='pike_phalanx' else 'iron','crew',.045)
        if kind=='legionary_infantry':
            for z in [1.13,1.20,1.27,1.34]: box('Armor band',(0,-.19,z),(.46,.025,.028),'iron','crew',.006)
        hand=Vector(joints['hand.L'])
        if kind=='pike_phalanx':
            rod('Round shield',hand+Vector((0,-.04,0)),hand+Vector((0,-.11,0)),.32,'bronze','hand.L',vertices=16)
        else:
            box('Tall legionary shield',tuple(hand+Vector((0,-.09,-.15))),(.57,.10,.96),'red','hand.L',.11)
            for x in [-.245,.245]: box('Shield edge',tuple(hand+Vector((x,-.153,-.15))),(.025,.018,.76),'bronze','hand.L',.006)
            box('Shield spine',tuple(hand+Vector((0,-.155,-.15))),(.035,.023,.8),'bronze','hand.L',.005)
        ellipsoid('Shield boss',tuple(hand+Vector((0,-.17,0))),(.08,.045,.08),'bronze','hand.L')
        hand=Vector(joints['hand.R'])
        if kind=='pike_phalanx':
            rod('Long pike',hand+Vector((0,0,-1.05)),hand+Vector((0,0,3.85)),.022,'wood','hand.R',vertices=8)
            rod('Pike point',hand+Vector((0,0,3.83)),hand+Vector((0,0,4.08)),.047,'iron','hand.R',0,4)
        else:
            rod('Sword grip',hand+Vector((0,0,.065)),hand+Vector((0,0,-.12)),.033,'wood','hand.R')
            box('Sword guard',tuple(hand+Vector((0,0,-.13))),(.17,.065,.04),'bronze','hand.R',.015)
            rod('Short sword',hand+Vector((0,0,-.16)),hand+Vector((0,0,-.70)),.048,'iron','hand.R',0,4)
    elif kind=='war_elephant':
        ellipsoid('Elephant torso',(0,.12,2.0),(.85,1.43,.92),'elephant','body')
        ellipsoid('Elephant head',(0,-1.31,2.32),(.62,.67,.66),'elephant','neck')
        for s in [-1,1]:
            ellipsoid('Elephant ear',(s*.66,-1.0,2.23),(.15,.50,.58),'elephant','neck')
            ellipsoid('Elephant eye',(s*.49,-1.74,2.53),(.032,.04,.032),'eyes','neck')
            ribbon('Curved tusk',[(s*.37,-1.71,1.96),(s*.41,-2.13,1.85),(s*.40,-2.45,2.02)],.065,'ivory','neck')
        ribbon('Trunk',[(0,-1.94,2.35),(0,-2.12,1.68),(0,-2.20,1.12),(0,-2.42,.98)],.14,'elephant','trunk')
        rod('Elephant tail',(0,1.45,2.1),(0,1.65,.98),.04,'elephant','tail',.025)
        for n in ['front.L','front.R','back.L','back.R']:
            a=Vector(joints[n]); b=Vector(joints[n+'.lower']); foot=Vector((b.x,b.y,.19))
            rod('Elephant upper leg',a,b,.245,'elephant',n,.21,10)
            rod('Elephant lower leg',b,foot,.205,'elephant',n+'.lower',.23,10)
            ellipsoid('Elephant foot',foot,(.25,.27,.2),'elephant',n+'.lower')
        box('War elephant cloth',(0,.10,2.74),(1.70,1.82,.12),'team_color','body',.09)
        box('Rider platform',(0,.20,2.82),(1.16,1.12,.16),'wood','body',.03)
        for s in [-1,1]:
            box('Howdah rail',(s*.56,.20,3.24),(.065,1.08,.08),'wood','body',.015)
            for y in [-.28,.68]: rod('Howdah post',(s*.56,y,2.84),(s*.56,y,3.27),.03,'wood','body')
        hand=Vector(joints['hand.R'])
        rod('Rider spear',hand+Vector((0,0,-.65)),hand+Vector((0,0,1.30)),.018,'wood','hand.R')
        rod('Spear tip',hand+Vector((0,0,1.3)),hand+Vector((0,0,1.52)),.045,'bronze','hand.R',0,4)
    elif kind in ['battering_ram','siege_tower']:
        for side,x in [('L',-1.15),('R',1.15)]:
            for end,y in [('F',-1.05),('B',1.05)]: wheel('Siege wheel',x,y,.4,.38,'wheel.'+end+side)
        for s in [-1,1]: box('Chassis rail',(s*.75,0,.52),(.17,2.9,.22),'wood','body',.02)
        if kind=='battering_ram':
            for y in [-.85,.85]:
                for s in [-1,1]: rod('Ram frame',(s*.78,y,.6),(s*.64,y,1.9),.075,'wood','body',vertices=6)
                rod('Crossbar',(-.72,y,1.9),(.72,y,1.9),.065,'wood','body')
                for s in [-1,1]: rod('Suspension rope',(s*.25,y,1.85),(s*.14,y,1.08),.02,'linen','ram')
            rod('Ram beam',(0,1.60,1.0),(0,-1.85,1.0),.16,'wood','ram',vertices=12)
            box('Iron ram head',(0,-1.90,1.0),(.39,.40,.38),'iron','ram',.07)
            for s in [-1,1]:
                panel=box('Protective sloped roof',(s*.44,0,2.03),(.99,2.72,.10),'hide','body',.02)
                panel.rotation_euler.y=s*.36
        else:
            for z in [.70,2.1,3.9]: box('Tower floor',(0,0,z),(2.04,2.48,.14),'wood','body',.015)
            for s in [-1,1]:
                for y in [-1.1,1.1]: box('Tower upright',(s*.9,y,2.7),(.17,.17,4.5),'wood','body',.015)
                box('Hide side',(s*.99,0,2.55),(.10,2.34,3.7),'hide','body',.025)
                for z in [1.1,1.8,2.5,3.2]: box('Slat binding',(s*1.051,0,z),(.025,2.3,.04),'wood','body',.006)
            box('Front mantlet',(0,-1.16,2.20),(1.94,.12,2.9),'hide','body',.025)
            box('Tower faction banner',(0,-1.235,2.4),(.55,.02,1.1),'team_color','body',.01)
            box('Boarding ramp',(0,-1.1,4.9),(1.65,.10,2.0),'wood','ramp',.015)
            for s in [-1,1]:
                box('Parapet side',(s*.96,0,4.46),(.14,2.48,.85),'wood','crown',.02)
                for y in [-.9,-.3,.3,.9]: box('Battlement',(s*.96,y,5.03),(.17,.32,.34),'wood','crown',.02)
            for z in [1.0,1.4,1.8,2.2,2.6,3.0,3.4,3.8]: rod('Ladder rung',(-.35,1.18,z),(.35,1.18,z),.035,'wood','body')
            for x in [-.38,.38]: box('Ladder rail',(x,1.18,2.3),(.06,.06,3.6),'wood','body',.01)
    else:
        # Long, narrow, pointed hull; three visible banks of representative oars.
        sections=[(-15,.08),(-12,1.30),(-8,2.12),(-3,2.36),(4,2.36),(10,1.80),(14,.18)]
        verts=[]
        for y,w in sections: verts.extend([(-w,y,1.5),(-w*.72,y,-.15),(0,y,-.70),(w*.72,y,-.15),(w,y,1.5)])
        faces=[]
        for i in range(len(sections)-1):
            for j in range(4): a=i*5+j; faces.append((a,a+5,a+6,a+1))
        faces.extend([(4,3,2,1,0),tuple(range((len(sections)-1)*5,len(sections)*5))])
        plate_mesh('Trireme hull',verts,faces,'hull','hull')
        deck=[]
        for y,w in sections: deck.extend([(-w*.94,y,1.38),(w*.94,y,1.38)])
        plate_mesh('Open deck',deck,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(len(sections)-1)],'wood','hull')
        # Raised central walkway, access hatches, and a few representative marines
        # make the long deck readable at the same human scale as the land units.
        box('Central walkway',(0,0,1.44),(.68,22,.10),'hull','hull',.01)
        for y in [-5,5]:
            box('Rowing deck hatch',(0,y,1.51),(1.5,1.9,.12),'hull','hull',.02)
            for x in [-.5,-.25,0,.25,.5]: box('Hatch grating',(x,y,1.59),(.055,1.70,.045),'wood','hull',.005)
        for y in [-10,-7,-4,3,6,9]: box('Deck crossbeam',(0,y,1.405),(3.0,.065,.045),'hull','hull',.005)
        for index,y in enumerate([-8,-5,5,8]):
            x=-1.35 if index%2 else 1.35
            box('Marine tunic',(x,y,2.63),(.40,.27,.44),'red','hull',.04)
            ellipsoid('Marine head',(x,y,3.04),(.12,.11,.15),'skin','hull')
            ellipsoid('Marine helmet',(x,y,3.15),(.14,.13,.08),'bronze','hull')
            for s in [-1,1]:
                rod('Marine leg',(x+s*.12,y,2.41),(x+s*.13,y,1.51),.068,'leather','hull')
                rod('Marine arm',(x+s*.22,y,2.80),(x+s*.27,y-.14,2.46),.05,'skin','hull')
            rod('Marine shield',(x-.24,y-.13,2.51),(x-.24,y-.20,2.51),.27,'team_color','hull',vertices=12)
            rod('Marine spear',(x+.27,y-.14,1.65),(x+.27,y-.14,3.68),.017,'wood','hull')
        for s in [-1,1]:
            ribbon('Gunwale',[(s*w,y,1.55) for y,w in sections],.085,'wood','hull')
            ribbon('Painted hull stripe',[(s*w*.94,y,.80) for y,w in sections],.07,'red','hull')
            for level in range(3):
                for index in range(16):
                    y=-8.4+index*1.08; z=.42+level*.35
                    start=(s*(1.82+level*.10),y,z)
                    end=(s*(5.7+level*.20),y+1.0,-.18)
                    bone='oars.'+('L' if s<0 else 'R')+str(level)+'.'+str(index)
                    rod('Oar shaft',start,end,.045,'wood',bone,vertices=6)
                    blade=box('Oar blade',end,(.80,.16,.055),'linen',bone,.015)
                    blade.rotation_euler.z=s*.20
            ellipsoid('Bow eye',(s*.52,-13.4,1.05),(.04,.26,.17),'linen','hull')
            ellipsoid('Bow pupil',(s*.56,-13.4,1.05),(.025,.10,.11),'eyes','hull')
        rod('Bronze ram',(0,-13.9,.22),(0,-16.2,.22),.27,'bronze','hull',.10,6)
        rod('Mast',(0,0,1.4),(0,0,7.4),.10,'wood','mast',.07)
        rod('Yard',(-3.2,0,6.0),(3.2,0,6.0),.065,'wood','mast')
        rod('Furled sail',(-2.95,0,5.82),(2.95,0,5.82),.15,'linen','mast')
        for x in [-2.8,2.8]: ribbon('Rigging',[(x,0,1.45),(0,0,7.2),(0,-8,1.4)],.015,'linen','mast')
        box('Fleet pennant',(.46,0,7.04),(.88,.025,.44),'team_color','mast',.005)
        for s in [-1,1]: rod('Steering oar',(s*.7,11,2),(s*2.1,13.3,-.5),.09,'wood','hull')

    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts: obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join()
    mesh=bpy.context.object; mesh.name=kind+'_mesh'; bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    modifier=mesh.modifiers.new('Unit skeleton','ARMATURE'); modifier.object=rig; mesh.parent=rig
    bounds=[]
    for clip,duration in CLIPS.items():
        action=bpy.data.actions.new(clip); rig.animation_data_create(); rig.animation_data.action=action
        end=round(duration*24)
        for frame in range(end+1):
            pose(rig,kind,clip,frame/end); bpy.context.view_layer.update()
            evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); data=evaluated.to_mesh()
            lowest=min((evaluated.matrix_world@v.co).z for v in data.vertices); evaluated.to_mesh_clear()
            # Watercraft intentionally intersect the waterline and sink when disabled.
            correction=max(0,.008-lowest) if kind!='trireme' else 0
            rig.pose.bones['root'].location.y+=correction
            for bone in rig.pose.bones:
                for prop in ['location','rotation_euler','scale']: bone.keyframe_insert(prop,frame=frame)
            bounds.append({'clip':clip,'frame':frame,'ground_correction':correction})
        slot=rig.animation_data.action_slot; rig.animation_data.action=None
        track=rig.animation_data.nla_tracks.new(); track.name=clip
        strip=track.strips.new(clip,0,action); strip.action_slot=slot; track.mute=True
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); mesh.select_set(True); bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/(kind+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_materials='EXPORT')
    manifest['units'].append({'id':kind,'label':label,'file':kind+'.glb','triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons),'bones':len(joints),'domain':'naval' if kind=='trireme' else 'land'})
    (SOURCE/(kind+'_ground_checks.json')).write_text(json.dumps(bounds))
    units.append((rig,mesh,label))

for i,(rig,mesh,label) in enumerate(units):
    rig.location.x=(i-2)*7 if i<5 else 30
    strip=rig.animation_data.nla_tracks['idle'].strips[0]
    rig.animation_data.action=strip.action; rig.animation_data.action_slot=strip.action_slot
scene.frame_start=0; scene.frame_end=60; scene.frame_set(0)
scene.render.engine='CYCLES'; scene.cycles.samples=20
scene.render.resolution_x=1800; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.17,.20,.23,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
ground=material('Presentation floor',(.06,.09,.10)); bpy.ops.mesh.primitive_plane_add(size=200); bpy.context.object.data.materials.append(ground)
for name,loc,power,size in [('Key',(-8,-12,18),8000,12),('Fill',(20,-8,14),6000,12),('Rim',(2,15,20),10000,10)]:
    data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.shape='DISK'; data.size=size
    obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj); obj.location=loc
    obj.rotation_euler=(Vector((5,0,2))-obj.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Presentation camera'); camera=bpy.data.objects.new('Presentation camera',data)
scene.collection.objects.link(camera); camera.location=(14,-40,28)
camera.rotation_euler=(Vector((8,0,2))-camera.location).to_track_quat('-Z','Y').to_euler()
data.type='ORTHO'; data.ortho_scale=59; scene.camera=camera
scene.render.image_settings.file_format='PNG'; scene.render.filepath=str(SOURCE/'classical_units_preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'classical_units.blend'))
(OUT/'classical_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
bpy.ops.render.render(write_still=True)
print('CLASSICAL_UNITS_BUILD_COMPLETE',json.dumps(manifest))
