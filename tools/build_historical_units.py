"""Build the first six study-selected historical units with baked animation."""
from pathlib import Path
import math
import json
import bpy
from mathutils import Vector, Euler

support_path = Path(__file__).with_name('build_support_units.py')
support_text = support_path.read_text()
exec(compile(support_text.split('\nunits=[]; manifest=')[0], str(support_path), 'exec'))
from basic_unit_motion import limb, sample
SOURCE = ROOT/'art_source/historical_units'
SOURCE.mkdir(parents=True, exist_ok=True)
M['camel'] = material('camel', (.56,.36,.17))
M['blue'] = material('indigo cloth', (.15,.24,.40))
M['green'] = material('moss cloth', (.23,.35,.16))
M['ochre'] = material('ochre cloth', (.62,.37,.12))

IDS = ['slinger','javelin_skirmisher','crossbow_infantry','chariot_archer','horse_archer','camel_cavalry']
LABELS = ['SLINGER','JAVELIN SKIRMISHER','CROSSBOW INFANTRY','CHARIOT ARCHER','HORSE ARCHER','CAMEL CAVALRY']

def animal_joints(joints, parents, origin, camel=False):
    o=Vector(origin); h=.25 if camel else 0
    for name,pos in {'neck':(0,-.61,1.20+h),'tail':(0,.84,1.10+h)}.items():
        joints[name]=tuple(o+Vector(pos)); parents[name]='body'
    for front,y in [('front',-.55),('back',.58)]:
        for side,s in [('L',-1),('R',1)]:
            name=front+'.'+side
            joints[name]=tuple(o+Vector((s*.23,y,.92+h)))
            joints[name+'.lower']=tuple(o+Vector((s*.25,y,.48)))
            parents[name]='body'; parents[name+'.lower']=name

def animal(origin, camel=False):
    o=Vector(origin); h=.25 if camel else 0; mat='camel' if camel else 'horse'
    def at(p): return tuple(o+Vector(p))
    ellipsoid('Animal barrel',at((0,.07,1.13+h)),(.34,.80,.43),mat,'body')
    if camel:
        ellipsoid('Camel hump',at((0,.20,1.63)),(.29,.40,.42),mat,'body')
        ribbon('Long curved camel neck',[at((0,-.55,1.3)),at((0,-.85,1.23)),at((0,-1.10,1.72)),at((0,-1.18,2.12))],.14,mat,'neck')
        ellipsoid('Camel head',at((0,-1.27,2.13)),(.13,.26,.14),mat,'neck')
        ellipsoid('Camel muzzle',at((0,-1.49,2.06)),(.12,.15,.09),'horse_dark','neck')
        for s in [-1,1]:
            rod('Camel ear',at((s*.11,-1.12,2.18)),at((s*.21,-1.09,2.29)),.045,mat,'neck',.018)
            ellipsoid('Camel eye',at((s*.125,-1.32,2.18)),(.014,.025,.018),'eyes','neck')
    else:
        ellipsoid('Horse chest',at((0,-.47,1.15)),(.30,.35,.40),mat,'body')
        rod('Horse neck',at((0,-.52,1.23)),at((0,-.89,1.82)),.23,mat,'neck',.16,10)
        ellipsoid('Horse head',at((0,-1,1.86)),(.16,.30,.20),mat,'neck')
        ellipsoid('Horse muzzle',at((0,-1.23,1.72)),(.135,.20,.115),'horse_dark','neck')
        for s in [-1,1]:
            rod('Horse ear',at((s*.105,-.86,1.99)),at((s*.13,-.85,2.22)),.064,mat,'neck',.01,5)
            ellipsoid('Horse eye',at((s*.15,-1.08,1.90)),(.015,.033,.022),'eyes','neck')
        ribbon('Mane',[at((0,-.38,1.50)),at((0,-.59,1.69)),at((0,-.77,1.93))],.065,'horse_dark','neck')
    rod('Tail',at((0,.77,1.22+h)),at((0,1.11,.54)),.055,'horse_dark','tail',.025)
    for name in ['front.L','front.R','back.L','back.R']:
        a=Vector(joints[name]); b=Vector(joints[name+'.lower']); foot=Vector((b.x,b.y-.04,.105))
        rod('Upper leg',a,b,.090,mat,name,.063)
        ellipsoid('Knee',b,(.072,.075,.08),mat,name+'.lower')
        rod('Lower leg',b,foot,.050,mat,name+'.lower',.035)
        box('Foot pad' if camel else 'Hoof',tuple(foot),(.18 if camel else .13,.22,.12),'horse_dark',name+'.lower',.025)
    box('Saddle blanket',at((0,.05,1.45+h)),(.77,.74,.10),'team_color','body',.04)
    box('Saddle',at((0,.07,1.53+h)),(.52,.44,.12),'leather','body',.04)

def bow_weapon(hand, horizontal=False):
    o=Vector(hand)
    points=[(-.55,-.07,0),(-.32,-.20,0),(0,0,0),(.32,-.20,0),(.55,-.07,0)] if horizontal else [(0,-.07,-.50),(0,-.20,-.29),(0,0,0),(0,-.20,.29),(0,-.07,.50)]
    points=[o+Vector(p) for p in points]
    ribbon('Crossbow prod' if horizontal else 'Composite bow',points,.027,'wood','hand.L')
    for end in [points[0],points[-1]]:
        middle=Vector(joints['string'])
        obj=rod('Bow cord',end,middle,.008,'linen','hand.L',vertices=5)
        group=obj.vertex_groups.new(name='string')
        for v in obj.data.vertices:
            p=obj.matrix_world@v.co
            if (p-middle).length < (p-end).length:
                obj.vertex_groups['hand.L'].remove([v.index]); group.add([v.index],1,'REPLACE')
    if horizontal:
        box('Crossbow stock',tuple(o+Vector((0,.17,-.045))),(.075,.79,.09),'wood','hand.L',.015)
        box('Trigger',tuple(o+Vector((0,.38,-.11))),(.035,.035,.09),'iron','hand.L',.006)
    a=Vector(joints['projectile'])
    rod('Arrow shaft',a,a+Vector((0,-.68,0)),.010,'wood','projectile',vertices=6)
    rod('Arrowhead',a+Vector((0,-.65,0)),a+Vector((0,-.77,0)),.032,'iron','projectile',0,4)
    box('Arrow fletching',tuple(a+Vector((0,-.06,0))),(.075,.10,.008),'linen','projectile',0)

def pose(rig,kind,clip,t):
    p=rig.pose.bones; phase=t*math.tau
    for b in p: b.location=(0,0,0); b.rotation_euler=(0,0,0); b.scale=(1,1,1)
    mounted=kind in ['horse_archer','camel_cavalry','chariot_archer']
    p['crew'].rotation_euler.x=.012*math.sin(phase)
    p['head'].rotation_euler.y=.025*math.sin(phase)
    if mounted:
        p['neck'].rotation_euler.x=.022*math.sin(phase)
        p['tail'].rotation_euler.z=.08*math.sin(phase)
    if clip=='walk':
        if mounted:
            for i,n in enumerate(['front.L','front.R','back.L','back.R']):
                offset=0 if (i in [0,2] if kind=='camel_cavalry' else i in [0,3]) else math.pi
                swing=math.sin(phase+offset)
                p[n].rotation_euler.x=.38*swing
                p[n+'.lower'].rotation_euler.x=-.48*max(0,swing)
            p['crew'].location.y=.03*(1-math.cos(phase*2))
            if kind=='chariot_archer':
                for side in ['L','R']: p['wheel.'+side].rotation_euler.x=phase
        else:
            for side,s in [('L',1),('R',-1)]: p['leg.'+side].rotation_euler.x=.32*s*math.sin(phase)
            p['crew'].location.y=.022*(1-math.cos(phase*2))
    if clip=='death':
        stagger=ease(t,.04,.22); fall=ease(t,.22,.68); settle=ease(t,.68,.83)
        p['head'].rotation_euler.x=.30*stagger
        p['head'].rotation_euler.y=0
        if mounted: p['tail'].rotation_euler.z=.25*fall
        p['crew'].rotation_euler.x=-.16*stagger
        if mounted and kind!='chariot_archer':
            p['root'].rotation_euler.z=1.48*fall
            p['root'].location.y=-.55*fall
            for n in ['front.L','front.R','back.L','back.R']:
                p[n].rotation_euler.x=.55*stagger; p[n+'.lower'].rotation_euler.x=-1.05*stagger
            p['neck'].rotation_euler.x=.30*fall
            p['crew'].rotation_euler.z=.20*fall
        else:
            p['crew'].rotation_euler.x=-1.48*fall-.07*settle
            p['crew'].location.y=-.65*fall
            p['crew'].location.z=-.17*fall
            for side,s in [('L',-1),('R',1)]:
                p['arm.'+side].rotation_euler.x=1.5*fall
                p['arm.'+side].rotation_euler.z=.28*s*fall
                p['leg.'+side].rotation_euler.x=.42*fall
            if kind=='chariot_archer':
                p['cart'].rotation_euler.z=-.17*fall
                p['wheel.R'].rotation_euler.z=.8*fall
                p['wheel.R'].location.x=.4*fall
                p['neck'].rotation_euler.x=.16*fall
        if 'projectile' in p: p['projectile'].scale=(.001,)*3
        return

    left=Vector(joints['hand.L']); right=Vector(joints['hand.R']); wrist=(0,0,0)
    if clip=='attack':
        wind=ease(t,.06,.30); release=ease(t,.40,.49); recover=ease(t,.70,1)
        p['crew'].rotation_euler.y=(-.15*wind+.27*release)*(1-recover)
        p['crew'].rotation_euler.x=.10*release*(1-recover)
        if kind in ['slinger','javelin_skirmisher','camel_cavalry']:
            right=Vector(operator)+Vector(sample(t,[(0,(.28,-.32,1.30)),(.25,(.42,.15,1.71)),(.37,(.42,.12,1.73)),(.49,(.28,-.57,1.49)),(.62,(.35,-.46,1.22)),(1,(.28,-.32,1.30))]))
            if kind=='slinger':
                p['sling'].rotation_euler.y=math.tau*2*ease(t,.02,.43)
                p['sling'].rotation_euler.x=.4*wind*(1-recover)
            else:
                wrist=(sample(t,[(0,0),(.30,-.35),(.49,.20),(.65,.55),(1,0)]),0,0)
        else:
            draw=ease(t,.08,.34)*(1-ease(t,.44,.49))
            # Both hands stay on the weapon and nock; release follows the draw.
            left=Vector(joints['hand.L'])+Vector((0,-.06*wind*(1-recover),.12*wind*(1-recover)))
            right=left+Vector((.02,.30+.20*draw,0))
            p['string'].location.z=-.20*draw
            p['projectile'].location.z=-.20*draw
            if kind=='crossbow_infantry':
                # Reload by bringing the stock down and returning the draw hand.
                left.z-=.25*ease(t,.58,.72)*(1-ease(t,.85,1))
        if .46<t<.96:
            p['projectile'].location.z+=4.5*ease(t,.46,.60)
            if t>.60: p['projectile'].scale=(.001,)*3
    bpy.context.view_layer.update()
    for side,target in [('L',left),('R',right)]:
        limb(rig,joints,'arm.'+side,'forearm.'+side,'hand.'+side,target,Vector(operator)+Vector((-1 if side=='L' else 1,.1,1.15)),wrist if side=='R' else None)

units=[]; manifest={'units':[],'fps':24,'clips':CLIPS,'source':'Historical_Military_Unit_Progression.docx','status':'visual prototypes; recruitment integration pending'}
for kind,label in zip(IDS,LABELS):
    parts=[]; mounted=kind in ['horse_archer','camel_cavalry','chariot_archer']
    riding=mounted and kind!='chariot_archer'; camel=kind=='camel_cavalry'
    operator=Vector((0,1.65,.58)) if kind=='chariot_archer' else Vector((0,0,.95 if camel else (.69 if riding else 0)))
    animal_origin=(0,-1.20,0) if kind=='chariot_archer' else (0,0,0)
    joints={'root':(0,0,.92 if riding else 0),'body':(0,0,.8),'crew':tuple(operator+Vector((0,0,.90))),'head':tuple(operator+Vector((0,0,1.55)))}
    parents={'body':'root','crew':'root','head':'crew'}
    ranged=kind in ['crossbow_infantry','horse_archer','chariot_archer']
    for side,s in [('L',-1),('R',1)]:
        for n,pos in [('leg',(s*.13,0,.88)),('arm',(s*.28,0,1.43)),('forearm',(s*.39,-.12,1.17)),('hand',(-.15,-.53,1.42) if ranged and side=='L' else ((-.13,-.23,1.42) if ranged else (s*.28,-.32,1.30)))]:
            joints[n+'.'+side]=tuple(operator+Vector(pos))
        parents.update({'leg.'+side:'crew','arm.'+side:'crew','forearm.'+side:'arm.'+side,'hand.'+side:'forearm.'+side})
    if mounted: animal_joints(joints,parents,animal_origin,camel)
    if kind=='chariot_archer':
        joints.update({'cart':(0,1.6,.5),'wheel.L':(-.88,1.65,.55),'wheel.R':(.88,1.65,.55)})
        parents.update({'cart':'root','wheel.L':'cart','wheel.R':'cart'})
    if ranged:
        joints['string']=tuple(Vector(joints['hand.L'])+Vector((0,.30,0)))
        joints['projectile']=joints['string']; parents.update({'string':'hand.L','projectile':'hand.L'})
    elif kind=='slinger':
        joints['sling']=joints['hand.R']; parents['sling']='hand.R'
        joints['projectile']=tuple(Vector(joints['hand.R'])+Vector((.52,0,.08))); parents['projectile']='sling'
    else:
        joints['projectile']=joints['hand.R']; parents['projectile']='hand.R'
    rig=rig_for(kind,joints,parents)
    cloth='green' if kind in ['slinger','javelin_skirmisher'] else ('blue' if kind in ['horse_archer','crossbow_infantry'] else 'ochre')
    M['cloth_levy']=M[cloth]; M['cloth_infantry']=M[cloth]
    crew(operator.x,operator.y,riding)
    # Crew helper provides a standard .69 m seated offset; adapt to this mount/platform.
    for obj in list(parts):
        obj.location.z+=operator.z-(.69 if riding else 0)
        if any(g.name.startswith('arm.') for g in obj.vertex_groups):
            parts.remove(obj); bpy.data.objects.remove(obj,do_unlink=True)
    for side in ['L','R']:
        a,b,c=[joints[n+'.'+side] for n in ['arm','forearm','hand']]
        rod('Upper sleeve',a,b,.072,cloth,'arm.'+side,.057)
        rod('Forearm',b,c,.055,'skin','forearm.'+side,.042)
        ellipsoid('Hand',c,(.055,.055,.065),'skin','hand.'+side)
    if kind in ['slinger','javelin_skirmisher']:
        box('Stone or javelin pouch',tuple(operator+Vector((.22,.05,.99))),(.18,.19,.25),'leather','crew',.04)
    if camel:
        ellipsoid('Wrapped headcloth',tuple(operator+Vector((0,0,1.78))),(.155,.14,.10),'linen','head')
        box('Headcloth drape',tuple(operator+Vector((0,.12,1.61))),(.28,.06,.26),'linen','head',.025)
    if mounted: animal(animal_origin,camel)
    if ranged:
        bow_weapon(joints['hand.L'],kind=='crossbow_infantry')
        rod('Quiver',operator+Vector((.21,.13,1.0)),operator+Vector((.23,.15,1.54)),.085,'leather','crew')
        for x in [.17,.23,.29]: rod('Spare arrow',operator+Vector((x,.15,1.45)),operator+Vector((x,.15,1.73)),.009,'wood','crew',vertices=5)
    elif kind=='slinger':
        a=Vector(joints['sling']); b=Vector(joints['projectile'])
        for y in [-.025,.025]: rod('Sling cord',a+Vector((0,y,0)),b+Vector((0,y,0)),.008,'linen','sling',vertices=5)
        box('Sling pouch',tuple(b),(.10,.09,.018),'leather','sling',.008)
        ellipsoid('Sling stone',tuple(b+Vector((0,0,.03))),(.04,.035,.035),'stone','projectile')
    else:
        a=Vector(joints['hand.R'])
        rod('Throwing spear',a+Vector((0,.45,0)),a+Vector((0,-.9,0)),.018,'wood','projectile')
        rod('Spear point',a+Vector((0,-.88,0)),a+Vector((0,-1.08,0)),.042,'bronze','projectile',0,4)
        o=Vector(joints['hand.L'])
        rod('Round hide shield',o+Vector((0,-.04,0)),o+Vector((0,-.10,0)),.26,'leather','hand.L',vertices=12)
        ellipsoid('Shield boss',tuple(o+Vector((0,-.13,0))),(.07,.035,.07),'bronze','hand.L')
        for x in [.16,.23]: rod('Spare javelin',operator+Vector((x,.17,.81)),operator+Vector((x,.17,1.97)),.015,'wood','crew')
    if kind=='chariot_archer':
        box('Chariot floor',(0,1.65,.53),(1.42,1.05,.15),'wood','cart',.025)
        box('Curved front panel',(0,1.16,1.02),(1.43,.12,.85),'ochre','cart',.08)
        box('Chariot faction panel',(0,1.089,1.03),(.40,.018,.47),'team_color','cart',.015)
        for s in [-1,1]:
            box('Side rail',(s*.66,1.48,1.15),(.10,.73,.13),'wood','cart',.02)
            rod('Side upright',(s*.66,1.65,.58),(s*.66,1.65,1.2),.04,'wood','cart')
            rod('Shaft',(s*.4,1.2,.60),(s*.4,-1.55,.9),.038,'wood','cart')
            wheel('Chariot wheel',s*.88,1.65,.55,.53,'wheel.'+('L' if s<0 else 'R'))
        rod('Harness yoke',(-.5,-1.48,1.4),(.5,-1.48,1.4),.045,'wood','body')
        ribbon('Harness strap',[(-.32,-1.7,1.25),(0,-1.6,1.55),(.32,-1.7,1.25)],.023,'leather','body')
    # Reuse the established sampled-animation export and ground contact pass.
    bake=support_text.split("    bpy.ops.object.select_all(action='DESELECT')\n    for obj in parts:")[1].split('\nfor i,(rig,mesh,label) in enumerate(units):')[0]
    bake="bpy.ops.object.select_all(action='DESELECT')\nfor obj in parts:"+bake
    lines=bake.splitlines(); bake='\n'.join(lines[:2]+[line[4:] if line.startswith('    ') else line for line in lines[2:]])
    exec(compile(bake,str(__file__),'exec'))

presentation='for i,(rig,mesh,label) in enumerate(units):'+support_text.split('\nfor i,(rig,mesh,label) in enumerate(units):')[1]
presentation=presentation.replace('(i-1)*4.2','(i-2.5)*4.2').replace('data.ortho_scale=13.6','data.ortho_scale=27')
presentation=presentation.replace('support_units_preview.png','historical_units_preview.png').replace('support_units.blend','historical_units.blend').replace('support_manifest.json','historical_manifest.json').replace('SUPPORT_UNITS_BUILD_COMPLETE','HISTORICAL_UNITS_BUILD_COMPLETE')
exec(compile(presentation,str(__file__),'exec'))
