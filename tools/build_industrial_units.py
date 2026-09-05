"""Build rifle infantry, machine-gun company and motorized infantry."""
from pathlib import Path
import bpy
import math
import json
from mathutils import Vector

support_path=Path(__file__).with_name('build_support_units.py')
support_text=support_path.read_text()
exec(compile(support_text.split('\nunits=[]; manifest=')[0],str(support_path),'exec'))
SOURCE=ROOT/'art_source/industrial_units'; SOURCE.mkdir(parents=True,exist_ok=True)
M['uniform']=material('uniform',(.22,.28,.14))
M['vehicle']=material('vehicle',(.19,.25,.13),.18)
M['canvas']=material('canvas',(.38,.35,.22))
M['rubber']=material('rubber',(.035,.041,.035))
M['glass']=material('glass',(.14,.24,.26),.25)
M['cloth_levy']=M['uniform']; M['cloth_infantry']=M['uniform']

def firearm(origin,bone,heavy=False):
    o=Vector(origin)
    box('Gun receiver',tuple(o),(.15 if heavy else .065,.37,.12 if heavy else .075),'gunmetal',bone,.012)
    box('Stock',tuple(o+Vector((0,.25,-.01))),(.11,.27,.14),'wood',bone,.025)
    rod('Gun barrel',o+Vector((0,-.12,.015)),o+Vector((0,-.81,.015)),.038 if heavy else .019,'gunmetal',bone,vertices=10)
    rod('Barrel collar',o+Vector((0,-.68,.015)),o+Vector((0,-.72,.015)),.047 if heavy else .025,'iron',bone,vertices=10)
    box('Front sight',tuple(o+Vector((0,-.70,.06))),(.012,.035,.06),'gunmetal',bone,.002)
    box('Magazine',tuple(o+Vector((.025,-.06,-.11))),(.05,.13,.15),'gunmetal',bone,.008)

def gun_flash(origin):
    a=Vector(origin)
    rod('Muzzle flash',a,a+Vector((0,-.30,0)),.11,'flash','flash',0,6)

def truck_wheel(x,y,bone):
    rod('Truck tyre',(x-.11,y,.46),(x+.11,y,.46),.43,'rubber',bone,vertices=16)
    rod('Truck hub',(x-.115,y,.46),(x+.115,y,.46),.23,'vehicle',bone,vertices=12)
    rod('Hub cap',(x-.12,y,.46),(x+.12,y,.46),.085,'iron',bone,vertices=10)

def pose(rig,kind,clip,t):
    p=rig.pose.bones; phase=t*math.tau
    for b in p: b.location=(0,0,0); b.rotation_euler=(0,0,0); b.scale=(1,1,1)
    p['flash'].scale=(.001,)*3
    p['crew'].rotation_euler.x=.012*math.sin(phase)
    p['head'].rotation_euler.y=.02*math.sin(phase)
    vehicle=kind=='motorized_infantry'
    if clip=='walk':
        if vehicle:
            for name in ['wheel.FL','wheel.FR','wheel.RL','wheel.RR']: p[name].rotation_euler.x=phase
            p['body'].location.y=.028*math.sin(phase*2)
        elif kind=='rifle_infantry':
            for side,s in [('L',1),('R',-1)]: p['leg.'+side].rotation_euler.x=s*.34*math.sin(phase)
            p['crew'].location.y=.022*(1-math.cos(phase*2))
        else:
            # Carry/transport presentation; tripod and crew move with the unit.
            for side,s in [('L',1),('R',-1)]: p['leg.'+side].rotation_euler.x=s*.22*math.sin(phase)
    if clip=='attack':
        aim=ease(t,.02,.18)*(1-ease(t,.78,1))
        p['crew'].rotation_euler.x=.08*aim
        p['head'].rotation_euler.x=.045*aim
        shots=[.32] if kind=='rifle_infantry' else [.27,.40,.53]
        recoil=0
        for shot in shots:
            recoil+=ease(t,shot,shot+.025)*(1-ease(t,shot+.025,shot+.105))
            if shot<t<shot+.055: p['flash'].scale=(1,1,1)
        p['weapon'].location.z=-.045*recoil
        p['weapon'].rotation_euler.x=-.04*recoil
        p['crew'].rotation_euler.x-=.035*recoil
        if vehicle: p['body'].rotation_euler.x=.015*recoil
    if clip=='death':
        fall=ease(t,.10,.74)
        p['head'].rotation_euler=(.14*fall,0,0)
        if vehicle:
            p['body'].rotation_euler.z=-.12*fall
            p['hood'].rotation_euler.x=-.7*fall
            p['wheel.FR'].rotation_euler.z=-.38*fall
            p['crew'].rotation_euler.x=1.25*fall
            p['crew'].location.y=-.28*fall
        else:
            p['crew'].rotation_euler.x=-1.48*fall
            p['crew'].location.y=-.57*fall
            p['crew'].location.z=-.22*fall
            for side,s in [('L',1),('R',-1)]:
                p['arm.'+side].rotation_euler.x=1.7*fall
                p['arm.'+side].rotation_euler.z=.2*s*fall
                p['leg.'+side].rotation_euler.x=.22*fall
            if kind=='machine_gun_company':
                p['weapon'].rotation_euler.z=.5*fall
                p['weapon'].location.y=-.5*fall

units=[]; manifest={'units':[],'fps':24,'clips':CLIPS,'forward_axis_godot':'+Z'}
for kind,label in [('rifle_infantry','RIFLE INFANTRY'),('machine_gun_company','MACHINE-GUN COMPANY'),('motorized_infantry','MOTORIZED INFANTRY')]:
    parts=[]; mounted=False
    vehicle=kind=='motorized_infantry'; mg=kind=='machine_gun_company'
    operator=Vector((.35,.55,1.13)) if vehicle else Vector((0,.82 if mg else 0,0))
    gun=Vector((0,-.05,1.28)) if mg else operator+Vector((.28,-.32,1.30))
    joints={'root':(0,0,0),'body':(0,0,.85),'crew':tuple(operator+Vector((0,0,.90))),
            'head':tuple(operator+Vector((0,0,1.55)))}
    parents={'body':'root','crew':'body' if vehicle else 'root','head':'crew'}
    for side,s in [('L',-1),('R',1)]:
        joints['leg.'+side]=tuple(operator+Vector((s*.13,0,.88)))
        joints['arm.'+side]=tuple(operator+Vector((s*.28,0,1.43)))
        parents['leg.'+side]='crew'; parents['arm.'+side]='crew'
    joints['weapon']=tuple(gun); parents['weapon']='body' if mg else 'crew'
    joints['flash']=tuple(gun+Vector((0,-.83,.015))); parents['flash']='weapon'
    if vehicle:
        for side,x in [('L',-.94),('R',.94)]:
            for axle,y in [('F',-1.35),('R',1.2)]:
                name='wheel.'+axle+side; joints[name]=(x,y,.46); parents[name]='root'
        joints['hood']=(0,-.75,1.40); parents['hood']='body'
    rig=rig_for(kind,joints,parents)
    # Reuse the crew body, raising all rest vertices for the truck bed.
    start=len(parts); crew(operator.x,operator.y,False)
    if vehicle:
        for obj in parts[start:]: obj.location.z+=operator.z
    # Distinct olive helmet, pack, pouches and webbing.
    head=operator+Vector((0,.012,1.755))
    ellipsoid('Steel helmet',head,(.16,.145,.09),'vehicle','head')
    box('Backpack',tuple(operator+Vector((0,.21,1.29))),(.32,.20,.35),'canvas','crew',.045)
    for s in [-1,1]:
        box('Webbing strap',tuple(operator+Vector((s*.13,-.16,1.29))),(.045,.018,.34),'canvas','crew',.003)
        box('Ammo pouch',tuple(operator+Vector((s*.16,-.17,1.08))),(.11,.075,.11),'canvas','crew',.01)
    firearm(gun,'weapon',mg)
    gun_flash(joints['flash'])
    if mg:
        for end in [(-.48,-.54,.06),(.48,-.54,.06),(0,.52,.06)]:
            rod('Tripod leg',(0,0,1.20),end,.033,'gunmetal','weapon',vertices=8)
        rod('Gun swivel',(0,0,1.06),(0,0,1.29),.07,'iron','weapon')
        box('Ammo box',(.35,.08,.22),(.33,.42,.40),'vehicle','root',.025)
        ribbon('Ammo feed',[(.07,-.07,1.26),(.32,-.02,1.10),(.35,.08,.43)],.027,'bronze','weapon')
    if vehicle:
        box('Chassis',(0,.05,.73),(1.72,3.90,.23),'gunmetal','body',.03)
        box('Cab',(0,-.79,1.58),(1.68,1.17,1.55),'vehicle','body',.09)
        box('Cab roof',(0,-.79,2.40),(1.84,1.31,.13),'vehicle','body',.045)
        box('Windscreen',(0,-1.391,2.03),(1.40,.035,.54),'glass','body',.025)
        box('Windscreen pillar',(0,-1.42,2.04),(.055,.045,.59),'vehicle','body',.008)
        for s in [-1,1]:
            box('Door window',(s*.852,-.73,2.04),(.028,.85,.50),'glass','body',.025)
            box('Door handle',(s*.884,-.50,1.58),(.03,.15,.035),'iron','body',.007)
            box('Headlamp',(s*.57,-1.98,1.17),(.23,.08,.23),'linen','body',.045)
            box('Cargo side',(s*.82,1.04,1.44),(.13,2.13,.68),'vehicle','body',.025)
        box('Engine hood',(0,-1.58,1.40),(1.35,.73,.40),'vehicle','hood',.075)
        box('Radiator',(0,-1.981,1.29),(.94,.035,.43),'gunmetal','body',.012)
        for x in [-.34,-.17,0,.17,.34]: box('Grille slat',(x,-2.009,1.29),(.035,.016,.37),'iron','body',.002)
        box('Bumper',(0,-2.07,.88),(1.98,.13,.16),'iron','body',.02)
        box('Cargo bed',(0,1.08,1.02),(1.68,2.14,.20),'wood','body',.018)
        box('Tailgate',(0,2.13,1.43),(1.73,.10,.70),'vehicle','body',.025)
        box('Tailgate faction panel',(0,2.191,1.43),(.39,.022,.25),'team_color','body',.01)
        box('Supply crate',(-.37,1.44,1.38),(.65,.75,.53),'canvas','body',.045)
        for side,x in [('L',-.94),('R',.94)]:
            for axle,y in [('F',-1.35),('R',1.2)]: truck_wheel(x,y,'wheel.'+axle+side)

    # Same export, pose validation, source layout and lighting pipeline as pack 2.
    bake=support_text.split("    bpy.ops.object.select_all(action='DESELECT')\n    for obj in parts:")[1].split('\nfor i,(rig,mesh,label) in enumerate(units):')[0]
    bake="bpy.ops.object.select_all(action='DESELECT')\nfor obj in parts:"+bake
    import textwrap
    # The first two lines were reconstructed outside the original four-space block.
    lines=bake.splitlines(); bake='\n'.join(lines[:2]+[line[4:] if line.startswith('    ') else line for line in lines[2:]])
    exec(compile(bake,str(__file__),'exec'))

presentation=support_text.split('\nfor i,(rig,mesh,label) in enumerate(units):')[1]
presentation='for i,(rig,mesh,label) in enumerate(units):'+presentation
presentation=presentation.replace("support_units_preview.png","industrial_units_preview.png").replace("support_units.blend","industrial_units.blend").replace("support_manifest.json","industrial_manifest.json").replace("SUPPORT_UNITS_BUILD_COMPLETE","INDUSTRIAL_UNITS_BUILD_COMPLETE")
exec(compile(presentation,str(__file__),'exec'))
