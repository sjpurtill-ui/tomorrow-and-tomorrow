"""Generate six medieval roster prototypes, baked GLBs and editable Blender source."""
from pathlib import Path
import bpy
import math
import json
from mathutils import Vector, Matrix

classical_path=Path(__file__).with_name('build_classical_units.py')
classical_text=classical_path.read_text()
exec(compile(classical_text.split('\nunits=[]; manifest=')[0],str(classical_path),'exec'))
from basic_unit_motion import orient
historical_text=Path(__file__).with_name('build_historical_units.py').read_text()
bow_code='def bow_weapon'+historical_text.split('def bow_weapon',1)[1].split('\ndef pose',1)[0]
exec(compile(bow_code,str(__file__),'exec'))
SOURCE=ROOT/'art_source/medieval_units'; SOURCE.mkdir(parents=True,exist_ok=True)
M['blue']=material('medieval blue',(.12,.24,.36))
M['green']=material('archer green',(.18,.29,.14))
M['steel']=material('plate steel',(.40,.44,.47),.65)
M['darksteel']=material('blackened iron',(.10,.13,.15),.6)
M['smoke']=material('powder smoke',(.52,.49,.42))
IDS=['armored_foot','pavise_crossbowman','longbowman','counterweight_trebuchet','hand_cannon_team','bombard']
LABELS=['ARMORED FOOT SOLDIER','PAVISE CROSSBOWMAN','LONGBOWMAN','COUNTERWEIGHT TREBUCHET','HAND-CANNON TEAM','BOMBARD']
THROW_KEYS=[(0,0),(.20,-.05),(.29,0),(.48,2.28),(.58,2.08),(.74,2.14),(1,2.14)]

def pose(rig,kind,clip,t):
    p=rig.pose.bones; phase=t*math.tau
    for b in p: b.location=(0,0,0); b.rotation_euler=(0,0,0); b.scale=(1,1,1)
    for n in ['flash','smoke']:
        if n in p: p[n].scale=(.001,)*3
    p['crew'].rotation_euler.x=.012*math.sin(phase)
    p['head'].rotation_euler.y=.02*math.sin(phase)
    if clip=='walk':
        for side,s in [('L',1),('R',-1)]: p['leg.'+side].rotation_euler.x=.30*s*math.sin(phase)
        for n in p:
            if n.name.startswith('wheel'): n.rotation_euler.x=phase
        if kind=='pavise_crossbowman':
            p['pavise'].location.y=.12+.015*math.sin(phase*2)
            p['pavise'].rotation_euler.x=.10
    if clip=='death':
        stagger=ease(t,.02,.22); fall=ease(t,.22,.76)
        p['head'].rotation_euler=(.25*stagger,0,0)
        p['crew'].rotation_euler.x=-1.5*fall
        p['crew'].location.y=-.64*fall
        p['crew'].location.z=-.2*fall
        for side,s in [('L',-1),('R',1)]:
            p['arm.'+side].rotation_euler.x=.08*fall
            p['arm.'+side].rotation_euler.z=s*.10*fall
            p['leg.'+side].rotation_euler.x=.40*fall
        if 'projectile' in p: p['projectile'].scale=(.001,)*3
        if kind=='pavise_crossbowman': p['pavise'].rotation_euler.x=1.46*fall
        if kind=='counterweight_trebuchet':
            p['body'].rotation_euler.z=.20*fall
            p['arm'].rotation_euler.x=.9*fall
            p['weight'].rotation_euler.x=-.55*fall
            p['sling'].rotation_euler.x=.7*fall
        if kind=='bombard':
            p['barrel'].rotation_euler.z=.27*fall
            p['barrel'].location.x=.20*fall
            p['body'].rotation_euler.z=-.12*fall
        return
    left=Vector(joints['hand.L']); right=Vector(joints['hand.R']); wrist=(0,0,0)
    if clip=='attack':
        wind=ease(t,.03,.24); hit=ease(t,.29,.43); recover=ease(t,.67,1)
        if kind=='armored_foot':
            right=operator+Vector(sample(t,[(0,(.28,-.32,1.30)),(.24,(.34,.08,1.81)),(.32,(.35,.05,1.77)),(.46,(.29,-.57,1.16)),(.59,(.34,-.45,1.12)),(1,(.28,-.32,1.30))]))
            wrist=(sample(t,[(0,0),(.26,-.45),(.46,1.75),(.60,1.65),(1,0)]),0,0)
            p['crew'].rotation_euler.y=(-.23*wind+.43*hit)*(1-recover)
            p['crew'].rotation_euler.x=.16*hit*(1-recover)
            left+=Vector((0,-.08*hit*(1-recover),.04*wind*(1-recover)))
        elif kind in ['pavise_crossbowman','longbowman']:
            aim=ease(t,.02,.18)*(1-ease(t,.70,1))
            draw=ease(t,.08,.34)*(1-ease(t,.44,.49))
            left+=Vector((0,-.025*aim,.07*aim))
            right=left+Vector((.02,.30+.18*draw,0))
            p['string'].location.z=-.18*draw
            p['projectile'].location.z=-.18*draw
            if .46<t<.96:
                p['projectile'].location.z+=4.5*ease(t,.46,.60)
                if t>.60: p['projectile'].scale=(.001,)*3
            if kind=='pavise_crossbowman':
                # Duck toward the tall shield after firing, then recover.
                duck=ease(t,.59,.75)*(1-ease(t,.85,1))
                p['crew'].rotation_euler.x=.25*duck
                left.z-=.30*duck; right.z-=.30*duck
        elif kind in ['hand_cannon_team','bombard']:
            recoil=ease(t,.34,.38)*(1-ease(t,.40,.72))
            p['crew'].rotation_euler.x=-.13*recoil
            if kind=='hand_cannon_team':
                right+=Vector((-.11,-.08,.13))*wind*(1-recover)
                left+=Vector((0,.065*recoil,0))
            else:
                p['barrel'].location.z=-.23*recoil
                p['barrel'].rotation_euler.x=-.025*recoil
                right+=Vector((-.13,-.20,.10))*wind*(1-recover)
            p['flash'].scale=(1,)*3 if .35<t<.42 else (.001,)*3
            smoke=ease(t,.36,.45)*(1-ease(t,.56,.81))
            p['smoke'].scale=(max(.001,smoke),)*3
            p['smoke'].location.y=.25*ease(t,.38,.80)
        elif kind=='counterweight_trebuchet':
            angle=sample(t,THROW_KEYS)
            p['arm'].rotation_euler.x=angle
            p['weight'].rotation_euler.x=-angle
            p['sling'].rotation_euler.x=-.25*ease(t,.30,.46)+.65*ease(t,.46,.60)
            p['winch'].rotation_euler.x=math.tau*ease(t,.02,.22)
            p['crew'].rotation_euler.x=.12*wind*(1-recover)
    bpy.context.view_layer.update()
    for side,target in [('L',left),('R',right)]:
        limb(rig,joints,'arm.'+side,'forearm.'+side,'hand.'+side,target,operator+Vector((-1 if side=='L' else 1,.1,1.1)),wrist if side=='R' else None)
    if kind=='counterweight_trebuchet':
        # Loaded stone follows the sling. Release moves it into an independent arc.
        loaded=p['sling'].matrix @ rig.data.bones['sling'].matrix_local.inverted() @ Vector(joints['projectile'])
        if clip=='attack' and t>.46:
            u=min(1,(t-.46)/.24)
            # Continue from the exact sling release point, without teleporting
            # from the moving sling into a separate hard-coded flight position.
            arm_rotation=Matrix.Rotation(sample(.46,THROW_KEYS),3,'X')
            sling_rotation=Matrix.Rotation(-.25,3,'X')
            pivot=Vector(joints['arm']); sling=Vector(joints['sling'])
            released=pivot+arm_rotation@(sling-pivot)+arm_rotation@sling_rotation@(Vector(joints['projectile'])-sling)
            loaded=released+Vector((0,-12*u,2*u-5*u*u))
            if t>.63: p['projectile'].scale=(.001,)*3
        scale=p['projectile'].scale.copy()
        orient(rig,'projectile',loaded,Matrix.Identity(3))
        p['projectile'].scale=scale

units=[]; manifest={'units':[],'fps':24,'clips':CLIPS,'status':'visual prototypes; gameplay integration pending'}
for kind,label in zip(IDS,LABELS):
    parts=[]; mounted=False
    operator=Vector((1.70,.45,0)) if kind=='counterweight_trebuchet' else (Vector((1.05,.40,0)) if kind=='bombard' else Vector((0,0,0)))
    joints={'root':(0,0,0),'body':(0,0,.3)}; parents={'body':'root'}
    add_person_joints(operator)
    if kind in ['pavise_crossbowman','longbowman','hand_cannon_team']:
        joints['hand.L']=tuple(operator+Vector((-.15,-.53,1.42)))
        joints['hand.R']=tuple(operator+Vector((-.13,-.23,1.42)))
    if kind in ['pavise_crossbowman','longbowman']:
        joints['string']=tuple(Vector(joints['hand.L'])+Vector((0,.30,0)))
        joints['projectile']=joints['string']; parents.update({'string':'hand.L','projectile':'hand.L'})
    if kind=='pavise_crossbowman': joints['pavise']=(-.48,-.35,.08); parents['pavise']='root'
    if kind=='counterweight_trebuchet':
        joints.update({'arm':(0,0,3.0),'weight':(0,-.65,3.56),'sling':(0,2.8,.60),'projectile':(0,3.7,.22),'winch':(0,1.25,.6)})
        parents.update({'arm':'body','weight':'arm','sling':'arm','projectile':'root','winch':'body'})
        for side,x in [('L',-1.2),('R',1.2)]:
            for end,y in [('F',-1.1),('B',1.1)]: joints['wheel.'+end+side]=(x,y,.3); parents['wheel.'+end+side]='body'
    if kind in ['hand_cannon_team','bombard']:
        if kind=='bombard': joints['barrel']=(0,0,.72); parents['barrel']='body'; muzzle=Vector((0,-1.58,.78)); parent='barrel'
        else: muzzle=Vector(joints['hand.L'])+Vector((0,-.70,.05)); parent='hand.L'
        joints.update({'flash':tuple(muzzle),'smoke':tuple(muzzle+Vector((0,-.2,.06)))})
        parents.update({'flash':parent,'smoke':parent})
    rig=rig_for(kind,joints,parents)
    cloth='green' if kind=='longbowman' else 'blue'
    M['red']=M[cloth]; M['cloth_levy']=M[cloth]; M['cloth_infantry']=M[cloth]
    person(operator)
    if kind=='armored_foot':
        box('Breastplate',(0,-.015,1.27),(.49,.34,.39),'steel','crew',.075)
        ellipsoid('Enclosed helmet',(0,0,1.71),(.155,.15,.20),'steel','head')
        box('Visor slit',(0,-.148,1.73),(.19,.015,.024),'eyes','head',.006)
        rod('Helmet ridge',(0,-.1,1.86),(0,.11,1.86),.025,'darksteel','head')
        for side,s in [('L',-1),('R',1)]:
            ellipsoid('Pauldron',(s*.29,0,1.43),(.13,.15,.13),'steel','arm.'+side)
            rod('Vambrace',joints['forearm.'+side],joints['hand.'+side],.061,'steel','forearm.'+side,.053)
            box('Greave',(s*.14,-.065,.40),(.15,.11,.43),'steel','leg.'+side,.03)
        h=Vector(joints['hand.R'])
        rod('Sword grip',h+Vector((0,0,-.10)),h+Vector((0,0,.10)),.030,'leather','hand.R')
        box('Crossguard',tuple(h+Vector((0,0,.12))),(.25,.055,.045),'steel','hand.R',.012)
        rod('Longsword blade',h+Vector((0,0,.15)),h+Vector((0,0,1.00)),.052,'steel','hand.R',0,4)
        h=Vector(joints['hand.L'])
        plate_mesh('Heater shield',[tuple(h+Vector(p)) for p in [(-.25,-.08,.25),(.25,-.08,.25),(.23,-.08,-.16),(0,-.08,-.48),(-.23,-.08,-.16)]],[(0,4,3,2,1)],'team_color','hand.L')
    elif kind in ['pavise_crossbowman','longbowman']:
        bow_weapon(joints['hand.L'],kind=='pavise_crossbowman')
        if kind=='longbowman':
            # Lengthen the stave and strings around the grip, preserving the nock.
            h=Vector(joints['hand.L'])
            for obj in parts:
                if obj.name.startswith(('Composite bow','Bow cord')):
                    for v in obj.data.vertices:
                        w=obj.matrix_world@v.co; w.z=h.z+(w.z-h.z)*1.55
                        v.co=obj.matrix_world.inverted()@w
            ellipsoid('Archer hood',(0,.045,1.74),(.15,.135,.13),'green','head')
        else:
            box('Tall pavise',(-.48,-.38,.78),(.67,.13,1.40),'wood','pavise',.13)
            box('Pavise painted face',(-.48,-.46,.81),(.54,.02,1.15),'team_color','pavise',.10)
            box('Pavise ridge',(-.48,-.49,.81),(.075,.055,1.17),'bronze','pavise',.02)
            rod('Pavise prop',(-.48,-.29,1.06),(-.48,.20,.08),.027,'wood','pavise')
        rod('Quiver',(.24,.13,1.03),(.24,.15,1.58),.08,'leather','crew')
        for x in [.18,.24,.30]: rod('Spare arrow',(x,.15,1.4),(x,.15,1.79),.009,'wood','crew')
    elif kind=='counterweight_trebuchet':
        for s in [-1,1]:
            box('Base rail',(s*.86,.15,.36),(.20,3.7,.22),'wood','body',.025)
            for y in [-1.15,1.25]: rod('A frame',(s*.86,y,.44),(s*.86,0,3.05),.10,'wood','body',vertices=6)
            for end,y in [('F',-1.1),('B',1.1)]: wheel('Transport wheel',s*1.2,y,.30,.28,'wheel.'+end+('L' if s<0 else 'R'))
        rod('Pivot axle',(-1.03,0,3),(1.03,0,3),.10,'iron','body')
        rod('Throwing arm',(0,-.65,3.56),(0,2.8,.6),.105,'wood','arm',.075,6)
        rod('Weight hanger',(0,-.65,3.56),(0,-.65,3.05),.045,'iron','weight')
        box('Counterweight',(0,-.65,2.70),(.8,.8,.70),'stone','weight',.06)
        for x in [-.22,.22]: rod('Sling cord',(0,2.8,.6),(x,3.7,.22),.015,'linen','sling')
        box('Sling pouch',(0,3.7,.20),(.46,.31,.06),'leather','sling',.03)
        ellipsoid('Stone shot',(0,3.7,.28),(.18,.17,.17),'stone','projectile')
        rod('Winch',(-.5,1.25,.6),(.5,1.25,.6),.085,'wood','winch')
        box('Trebuchet faction panel',(.98,0,1.8),(.03,.5,.7),'team_color','body',.02)
    elif kind=='hand_cannon_team':
        h=Vector(joints['hand.L'])
        rod('Wooden tiller',h+Vector((0,.50,-.025)),h+Vector((0,-.08,.015)),.035,'wood','hand.L')
        rod('Hand cannon barrel',h+Vector((0,-.05,.035)),h+Vector((0,-.68,.05)),.070,'bronze','hand.L',.065,12)
        rod('Muzzle bore',h+Vector((0,-.687,.05)),h+Vector((0,-.693,.05)),.043,'eyes','hand.L',vertices=12)
        h=Vector(joints['hand.R'])
        rod('Ignition match',h,h+Vector((-.08,-.20,.06)),.012,'wood','hand.R')
        ellipsoid('Match ember',tuple(h+Vector((-.08,-.20,.06))),(.018,.018,.018),'flash','hand.R')
        box('Powder pouch',(.24,.08,1.02),(.18,.13,.22),'leather','crew',.035)
    elif kind=='bombard':
        for x in [-.42,.42]: box('Timber bed',(x,.05,.27),(.19,2.1,.28),'wood','body',.025)
        for y in [-.70,.65]: box('Bed crossbrace',(0,y,.44),(1.04,.20,.20),'wood','body',.025)
        rod('Bombard barrel',(0,.62,.72),(0,-1.56,.78),.30,'darksteel','barrel',.25,16)
        for y in [-1.5,-1.13,-.75,-.36,.03,.48]:
            rod('Forged reinforcing hoop',(0,y-.045,.76),(0,y+.045,.76),.325 if y>.0 else .285,'iron','barrel',vertices=16)
        rod('Dark bombard bore',(0,-1.575,.78),(0,-1.583,.78),.195,'eyes','barrel',vertices=16)
        for y in [.25,.68]: ellipsoid('Stone cannonball',(-.83,y,.16),(.15,.15,.15),'stone','root')
        box('Powder chest',(-.94,1.13,.24),(.5,.55,.43),'wood','root',.035)
        box('Bombard faction plate',(0,-.82,.32),(.34,.025,.20),'team_color','body',.01)
    if kind in ['hand_cannon_team','bombard']:
        o=Vector(joints['flash']); radius=.13 if kind=='hand_cannon_team' else .27
        rod('Powder flash',o,o+Vector((0,-radius*3,0)),radius,'flash','flash',0,7)
        ellipsoid('Powder smoke',joints['smoke'],(radius*2,radius*3,radius*2),'smoke','smoke')

    # Share the established export/ground-contact implementation with pack 5.
    block=classical_text.split("    bpy.ops.object.select_all(action='DESELECT')\n    for obj in parts:",1)[1].split('\nfor i,(rig,mesh,label) in enumerate(units):',1)[0]
    block="bpy.ops.object.select_all(action='DESELECT')\nfor obj in parts:"+block
    lines=block.splitlines(); block='\n'.join(lines[:2]+[line[4:] if line.startswith('    ') else line for line in lines[2:]])
    exec(compile(block,str(__file__),'exec'))

presentation='for i,(rig,mesh,label) in enumerate(units):'+support_text.split('\nfor i,(rig,mesh,label) in enumerate(units):')[1]
presentation=presentation.replace('(i-1)*4.2','(i-2.5)*6.2').replace('data.ortho_scale=13.6','data.ortho_scale=41')
presentation=presentation.replace('support_units_preview.png','medieval_units_preview.png').replace('support_units.blend','medieval_units.blend').replace('support_manifest.json','medieval_manifest.json').replace('SUPPORT_UNITS_BUILD_COMPLETE','MEDIEVAL_UNITS_BUILD_COMPLETE')
exec(compile(presentation,str(__file__),'exec'))
