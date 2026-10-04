"""Sixteen additive court rooms, one visual chapter per 200 elapsed game years.
Blender 5.2: --background --factory-startup --python tools/blender/court_chapter_sets.py
No existing set/kit is modified. All furniture remains separately named for navigation.
"""
import argparse
import hashlib
import json
import math
import os
import sys
import time

import bpy
import bmesh
from mathutils import Matrix, Vector

HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0,HERE)
import court_set_kit as K
import court_set_halls as H
import court_set as S

OUT=os.path.join(ROOT,"assets","court_sets")
CHAPTERS=[
 ("Open hearth gathering","fire_ring",2.5,"GROUND"),
 ("Timber community hall","longhouse",3.2,"PLANK"),
 ("Plastered courtyard record hall","mudbrick_hall",3.5,"FLAGS"),
 ("Axial masonry audience hall","mudbrick_hall",4.4,"FLAGS"),
 ("Colonnaded council room","grand_hall",4.1,"FLAGS"),
 ("Vaulted administrative room","grand_hall",4.3,"STONE_BLOCK"),
 ("Late-antique record chamber","grand_hall",3.4,"FLAGS"),
 ("Timber great hall","longhouse",4.8,"PLANK"),
 ("Stone great hall and solar","grand_hall",4.8,"FLAGS"),
 ("Chancery and guild council","grand_hall",3.7,"PLANK"),
 ("Secretariat and anteroom","grand_hall",3.6,"FLAGS"),
 ("Cabinet council chamber","grand_hall",3.6,"PLANK"),
 ("Ministerial consultation office","grand_hall",3.4,"PLANK"),
 ("Industrial department office","grand_hall",3.8,"FLAGS"),
 ("Executive conference room","grand_hall",3.0,"PLANK"),
 ("Contemporary government conference","grand_hall",3.2,"FLAGS"),
]
K.SLOT_COLOURS.update({"WINDOW_GLASS":(.53,.67,.71),"PAPER":(.85,.81,.70)})


def material_finishes(chapter):
    """Runtime shader finishes; keep this metadata reproducible without a GLB rebuild."""
    glazing={"WINDOW_GLASS":{"pattern":19 if chapter in (7,8,9) else 20,
                            "albedo":"9daea2","albedo_worn":"b1bcb0","mottle":.03,"variation":.025}}
    if chapter<10:return glazing if chapter>=2 else {}
    modern=chapter>=14
    out={"PLASTER":{"pattern":0,"albedo":"deded3" if modern else "d5c8ab",
                     "albedo_worn":"e5e5dc" if modern else "ddcfb6","mottle":.025,"variation":.025,"grain":.025},
         "WEAVE_A":{"pattern":18,"albedo":"344b55" if modern else "485443","albedo_worn":"405963" if modern else "55614e","mottle":.02,"variation":.03},
         "WEAVE_B":{"pattern":18,"albedo":"465964" if modern else "4b5752","albedo_worn":"526771" if modern else "5b6861","mottle":.02,"variation":.03},
         "WOOD":{"pattern":16,"albedo":"79624d" if modern else "674b33","albedo_worn":"846e56" if modern else "785c40","mottle":.025,"variation":.04},
         "PLANK":{"pattern":16,"albedo":"81694f" if modern else "765638","albedo_worn":"90775b" if modern else "87684b","mottle":.025,"variation":.04}}
    if modern:
        out["FLAGS"]={"pattern":17,"albedo":"acb2ae","albedo_worn":"b8bfba","mottle":.02,"variation":.025,"grain":.02}
        out["STONE_BLOCK"]={"pattern":0,"albedo":"c2c8c5","albedo_worn":"cdd0cc","mottle":.02,"variation":.025}
    else:out.update(glazing)
    return out


def box(b,name,at,size,slot="WOOD",yaw=0,bevel=.012):
    bm=bmesh.new();bmesh.ops.create_cube(bm,size=1)
    m=Matrix.Translation(K.B(at)) @ Matrix.Rotation(-yaw,4,'Z') @ Matrix.Diagonal((size[0],size[2],size[1],1))
    bmesh.ops.transform(bm,matrix=m,verts=bm.verts)
    if bevel>0:bmesh.ops.bevel(bm,geom=bm.edges[:],offset=min(bevel,min(size)*.22),segments=1,affect='EDGES')
    bm.normal_update();b.add(name,bm,slot)


def local(at,p,yaw=0):
    x,y,z=p;c=math.cos(yaw);s=math.sin(yaw)
    return (at[0]+c*x+s*z,at[1]+y,at[2]-s*x+c*z)


def beam(b,name,a,z,width=.10,slot="WOOD"):
    # The kit's tube creates actual end caps and metre-scaled UVs.
    bm,caps=K.tube([a,z],[width,width],segs=6,wobble=0)
    b.add(name,bm,slot)
    if caps:b.add(name,caps,slot)


def chair(b,name,at,yaw=0,style=0):
    wood="WOOD" if style<12 else "PLANK"
    def part(p,size,slot=wood):box(b,name,local(at,p,yaw),size,slot,yaw)
    part((0,.435,0),(.56,.07,.56),"WEAVE_B" if style>=11 else wood)
    for x in (-.22,.22):
        for z in (-.22,.22):part((x,.21,z),(.065,.42,.065),"IRON" if style>=14 else wood)
    if style>=14:
        part((0,.81,-.23),(.54,.60,.085),"WEAVE_B")
        # Armless meeting chairs allow a natural lateral stand/seat access leg.
    else:
        height=1.1 if style in (3,7,8) else .95
        for x in (-.235,.235):part((x,(height+.47)/2,-.245),(.065,height-.47,.065))
        part((0,height-.05,-.245),(.55,.09,.08))
        for x in (-.15,0,.15):part((x,.72,-.245),(.06,.43,.05))
        if style in (8,9,11):part((0,.91,-.245),(.40,.22,.05),"WEAVE_A")


def table(b,name,at,width=1.7,depth=.8,height=.76,kind="trestle"):
    if kind in ("oval","boat"):
        count=32;verts=[]
        for y in (height-.09,height):
            for i in range(count):
                a=i*math.tau/count
                # A boat table has a straighter waist than the oval cabinet table.
                x=math.cos(a)*width/2;z=math.sin(a)*depth/2
                if kind=="boat":x*=.84+.16*abs(math.sin(a))
                verts.append(K.B((at[0]+x,at[1]+y,at[2]+z)))
        faces=[tuple(range(count-1,-1,-1)),tuple(range(count,2*count))]
        for i in range(count):j=(i+1)%count;faces.append((i,j,count+j,count+i))
        b.add(name,K._bm_from(verts,faces),"PLANK")
    else:box(b,name,local(at,(0,height-.045,0)),(width,.09,depth),"PLANK")
    if kind=="desk":
        for x in (-width*.34,width*.34):
            box(b,name,local(at,(x,(height-.10)/2,0)),(.36,height-.10,depth*.8),"WOOD")
            for y in (.18,.36,.54):
                box(b,name,local(at,(x,y,depth*.41)),(.30,.025,.025),"BRONZE")
    else:
        for x in (-width*.33,width*.33):
            for z in (-depth*.33,depth*.33):box(b,name,local(at,(x,(height-.1)/2,z)),(.08,height-.1,.08),"IRON" if kind=="boat" else "WOOD")
        if kind=="trestle":box(b,name,local(at,(0,.25,0)),(width*.73,.08,.10),"WOOD")
    return at[1]+height


def cabinet(b,name,at,width=1.35,height=1.8,style=0):
    slot="IRON" if style==13 else "WOOD"
    box(b,name,local(at,(0,height*.5,0)),(width,height,.42),slot)
    for y in (.2,.55,.9,1.25,1.6):
        if y>height-.1:continue
        box(b,name,local(at,(0,y,.22)),(width-.10,.022,.03),"BRONZE" if style<13 else "STONE_DARK")
    for x in (-width*.22,width*.22):box(b,name,local(at,(x,height*.5,.25)),(.07,.05,.03),"BRONZE")


def arch(b,name,x,z,span,spring,rise,depth=.22,slot="STONE_BLOCK",pointed=False):
    for side in (-1,1):box(b,name+"_Pier_"+str(side),(x+side*span/2,spring/2,z),(.18,spring,depth),slot)
    steps=16
    for i in range(steps):
        a=i*math.pi/steps;c=(i+1)*math.pi/steps
        def p(t):
            px=x+math.cos(t)*span/2
            py=spring+math.sin(t)*rise
            if pointed:py+=rise*.25*(1-abs(math.cos(t)))
            return(px,py,z)
        beam(b,name+"_Curve",p(a),p(c),.10,slot)


def gate(info,cap,name):info["technology_gates"].setdefault(cap,[]).append(name)


def papers(b,info,name,at,kind="paper"):
    if kind=="paper":
        box(b,name,local(at,(0,.018,0)),(.40,.036,.29),"PAPER",yaw=.08)
        for i in range(4):box(b,name,local(at,(0,.038,.07-i*.04)),(.24,.002,.006),"SOOT",yaw=.08,bevel=0)
        gate(info,"paper",name)
    elif kind=="book":
        box(b,name,local(at,(0,.055,0)),(.33,.11,.26),"WEAVE_A")
        box(b,name,local(at,(.01,.055,.005)),(.31,.07,.25),"PAPER")
        gate(info,"bound_records",name)
    else:
        box(b,name,local(at,(0,.03,0)),(.28,.06,.21),"TABLET")
        info["gates"].setdefault("writing",[]).append(name)


def equipment(b,info,chapter,desks):
    for i,(x,y,z) in enumerate(desks):
        if chapter>=2:papers(b,info,"RecordSheet_%d"%i,(x-.25,y,z),"tablet" if chapter<7 else "paper")
        if chapter>=6:papers(b,info,"BoundRecord_%d"%i,(x+.34,y,z-.08),"book")
        if chapter>=11:
            n="ElectricLamp_%d"%i;box(b,n,(x-.58,y+.025,z),(.22,.05,.18),"IRON")
            beam(b,n,(x-.58,y+.05,z),(x-.58,y+.38,z),.022,"IRON")
            box(b,n,(x-.58,y+.4,z),(.32,.12,.18),"WEAVE_B");gate(info,"electricity",n)
        if chapter>=12:
            n="Telephone_%d"%i;box(b,n,(x+.52,y+.055,z+.04),(.26,.11,.19),"SOCKET")
            box(b,n,(x+.52,y+.14,z+.04),(.33,.055,.065),"SOCKET");gate(info,"telephone",n)
        if chapter==13:
            n="Typewriter_%d"%i;box(b,n,(x,y+.07,z),(.45,.14,.30),"IRON")
            box(b,n,(x,y+.20,z-.08),(.43,.12,.14),"SOCKET")
            for row in range(3):
                for col in range(8):box(b,n,(x-.15+col*.043,y+.15,z+.03+row*.05),(.025,.016,.022),"PAPER",bevel=0)
            if i<2:
                # These two clerks sit behind their desks; keys face the typist.
                mesh,_=b.bm(n);pivot=K.B((x,y,z))
                bmesh.ops.transform(mesh,matrix=Matrix.Translation(pivot) @ Matrix.Rotation(math.pi,4,'Z') @ Matrix.Translation(-pivot),verts=mesh.verts)
                mesh.normal_update()
            gate(info,"typewriter",n)
        if chapter==14:
            n="Computer_%d"%i;box(b,n,(x,y+.09,z),(.43,.18,.37),"STONE_BLOCK")
            box(b,n,(x,y+.37,z-.02),(.42,.40,.36),"STONE_BLOCK")
            box(b,n,(x,y+.39,z+.166),(.32,.27,.012),"SOCKET");gate(info,"computer",n)
        if chapter>=15:
            n="FlatDisplay_%d"%i;box(b,n,(x,y+.045,z),(.27,.09,.20),"IRON")
            box(b,n,(x,y+.30,z-.055),(.49,.32,.04),"IRON")
            box(b,n,(x,y+.30,z-.03),(.43,.26,.015),"SOCKET");gate(info,"flat_screen",n)


def room_shell(b,info,i):
    title,base,h,floor=CHAPTERS[i]
    if i==0:
        K.ground(b,"Ground",6.5,12,.5,4,lambda x,z:0,lambda x,z:max(0,1-math.hypot(x,z)/6))
        for n,x in enumerate((-4.8,4.8)):
            K.tree(b,"Trees_%d"%n,(x,0,-5.3),4.8,1.7,seed=4+n,clumps=8)
        for n,(x,z) in enumerate(((-3.1,-2.2),(3.1,-2.2),(-4.3,.3),(4.3,.3))):
            K.log_piece(b,"LogSeat_%d"%n,(x-.7,.22,z),(x+.7,.22,z),.25,seed=n,stubs=0)
        for n,x in enumerate((-3.8,0,3.8)):
            K.hide_panel(b,"Windbreak_%d"%n,(x-1.4,0,-4),(x+1.4,0,-4),.12,1.8,seed=n,slot="HIDE",sag=.08)
            K.post(b,"WindbreakPost_%d"%n,(x-1.4,0,-4),2.2,.065,pointed=False)
            K.post(b,"WindbreakPost_%d_R"%n,(x+1.4,0,-4),2.2,.065,pointed=False)
        return
    box(b,"Floor",(0,-.075,0),(11.6,.15,8.4),floor,bevel=0)
    wall="WOOD" if i in (1,7) else ("MUD" if i==2 else "PLASTER" if i>=6 else "STONE_BLOCK")
    if i==8:wall="STONE_BLOCK"
    # Front cutaway; left wall has a real 1.8m doorway.
    box(b,"WallRight",(5.65,h*.5,-.3),(.2,h,7.8),wall)
    box(b,"WallLeftRear",(-5.65,h*.5,-1.65),(.2,h,4.7),wall)
    box(b,"WallLeftFront",(-5.65,h*.5,3.4),(.2,h,1.2),wall)
    box(b,"DoorLintel",(-5.65,2.55,1.75),(.22,.30,1.9),"WOOD" if i<8 else "STONE_BLOCK")
    # Broad modern windows replace separated ancient/high medieval bays.
    windows=[(-3.8,1.3),(0,1.3),(3.8,1.3)] if i<14 else [(-2.8,3.8),(2.8,3.8)]
    sill=1.45 if i in (3,5,8) else 1.05;top=h-.42
    box(b,"WallBackLow",(0,sill*.5,-4),(11.3,sill,.24),wall)
    box(b,"WallBackHigh",(0,(top+h)/2,-4),(11.3,h-top,.24),wall)
    start=-5.65
    for n,(x,w) in enumerate(windows):
        left=x-w/2
        if left>start:box(b,"WallBackPier_%d"%n,((left+start)/2,(sill+top)/2,-4),(left-start,top-sill,.24),wall)
        start=x+w/2
        box(b,"WindowSill_%d"%n,(x,sill,-3.83),(w+.18,.12,.40),"STONE_BLOCK" if i<10 else "WOOD")
        for sx in (-1,1):box(b,"WindowFrame_%d"%n,(x+sx*w/2,(sill+top)/2,-3.85),(.07,top-sill,.09),"WOOD" if i<13 else "IRON")
        box(b,"WindowMullion_%d"%n,(x,(sill+top)/2,-3.85),(.045,top-sill,.065),"WOOD" if i<13 else "IRON")
        name="Glazing_%d"%n;box(b,name,(x,(sill+top)/2,-3.965),(w-.08,top-sill-.08,.018),"WINDOW_GLASS",bevel=0);gate(info,"glazing",name)
    if start<5.65:box(b,"WallBackPier_end",((start+5.65)/2,(sill+top)/2,-4),(5.65-start,top-sill,.24),wall)
    # Construction changes are geometry, not a material-only age switch.
    if i in (1,7):
        for n,x in enumerate((-5.3,-2.0,2.0,5.3)):
            beam(b,"TimberPost_%d"%n,(x,0,-3.6),(x,h-.3,-3.6),.12)
        for n,z in enumerate((-3.4,-1.0,1.4)):
            beam(b,"Rafters_%d"%n,(-5.5,h-.6,z),(0,h+.65,z),.12)
            beam(b,"Rafters_%d"%n,(0,h+.65,z),(5.5,h-.6,z),.12)
            if i==7:
                beam(b,"TrussTie_%d"%n,(-5.5,h-.6,z),(5.5,h-.6,z),.10)
                beam(b,"TrussKing_%d"%n,(0,h-.6,z),(0,h+.65,z),.09)
        if i==7:
            for x in (-4.8,4.8):box(b,"CrossPassage_%s"%x,(x,1.05,-1.7),(.65,2.1,.12),"PLANK")
    elif i==2:
        for n,x in enumerate((-4.7,-1.7,1.7,4.7)):box(b,"CourtyardPost_%d"%n,(x,1.5,-2.9),(.20,3,.20),"WOOD")
        for x in (-4.3,4.3):box(b,"CanopyPorch_%s"%x,(x,3.0,-1.3),(2.4,.16,5.0),"THATCH")
        box(b,"RecordAlcove",(4.7,.55,-3.3),(1.25,1.1,.65),"MUD")
    elif i==3:
        for n,x in enumerate((-4.9,-2.1,2.1,4.9)):
            box(b,"AudiencePier_%d"%n,(x,2.0,-3.5),(.48,4,.48),"STONE_BLOCK")
            # Capital top must sit above the pier top, not share its plane.
            box(b,"AudienceCapital_%d"%n,(x,3.96,-3.5),(.80,.20,.75),"STONE_BLOCK")
        box(b,"RecessPediment",(0,3.4,-3.75),(3.5,.25,.4),"BRICK")
    elif i==4:
        for side in (-1,1):
            for n,z in enumerate((-3.3,-1.7,.0)):H.column(b,"Column_%s_%d"%(side,n),(side*5.1,0,z),3.7,.18,segs=10,drums=3)
        for side in (-1,1):box(b,"ColonnadeCornice_%s"%side,(side*5.1,3.85,-1.65),(.65,.2,4.2),"STONE_BLOCK")
    elif i==5:
        for n,z in enumerate((-3.5,-2.3,-1.1)):arch(b,"VaultRib_%d"%n,0,z,10.2,2.8,1.45,slot="STONE_BLOCK")
        for x in (-4.8,4.8):cabinet(b,"RecordNiche_%s"%x,(x,0,-2.9),.9,1.55)
    elif i==6:
        for n,x in enumerate((-4.2,-1.45,1.45,4.2)):box(b,"PartitionPier_%d"%n,(x,1.45,-3.25),(.18,2.9,.65),"PLASTER")
        box(b,"ClerestoryBand",(0,2.75,-3.70),(10.7,.12,.28),"STONE_BLOCK")
        for n,x in enumerate((-3.0,0,3.0)):cabinet(b,"RearRecordChest_%d"%n,(x,0,-3.7),1.7,.70)
    elif i==8:
        for n,x in enumerate((-3.8,0,3.8)):arch(b,"PointedWindow_%d"%n,x,-3.78,1.3,1.45,2.25,pointed=True)
        box(b,"SolarScreen",(4.9,1.25,-2.55),(1.0,2.5,.12),"PLANK")
        arch(b,"SolarDoor",4.6,-2.50,1.0,1.6,.65,slot="WOOD",pointed=True)
    elif i==9:
        for n,x in enumerate((-4.1,-1.4,1.4,4.1)):arch(b,"ChanceryArcade_%d"%n,x,-3.65,2.0,1.2,1.0,slot="STONE_BLOCK",pointed=True)
        for n,x in enumerate((-4.8,4.8)):box(b,"WindowSeat_%d"%n,(x,.235,-3.45),(1.15,.47,.65),"PLANK")
    elif i==10:
        for x in (-4.9,4.9):
            for z in (-2.7,-1.8,-.9):box(b,"AnteroomScreen_%s_%s"%(x,z),(x,1.1,z),(.12,2.2,.85),"WOOD")
        for n,x in enumerate((-3.8,0,3.8)):box(b,"WindowPediment_%d"%n,(x,3.2,-3.76),(1.75,.17,.25),"STONE_BLOCK")
    elif i==11:
        box(b,"ChimneyBreast",(4.95,1.75,-3.15),(1.0,3.5,.7),"PLASTER")
        box(b,"ColdFireplace",(4.90,.58,-2.77),(.72,1.16,.08),"SOCKET")
        box(b,"Mantel",(4.9,1.23,-2.73),(1.15,.12,.45),"STONE_BLOCK")
    elif i==12:
        for n,z in enumerate((-3.0,-1.6,-.2)):cabinet(b,"MinistryFiling_%d"%n,(5.12,0,z),.7,2.0,style=12)
        # Side screen separates the secretary alcove without cutting its desk.
        box(b,"ConsultationPartition",(-3.95,1.1,-2.9),(.12,2.2,1.2),"PLASTER")
    elif i==13:
        for n,x in enumerate((-4.7,-1.5,1.5,4.7)):beam(b,"IronCeiling_%d"%n,(x,3.55,-4),(x,3.55,2.3),.065,"IRON")
        for n,z in enumerate((-3,-1.6)):cabinet(b,"DepartmentFile_%d"%n,(5.1,0,z),.75,2.0,style=13)
    elif i==14:
        box(b,"CeilingRibbon",(0,2.95,-2.8),(10.8,.15,1.3),"PLASTER")
        for x in (-4.7,4.7):box(b,"AcousticPanel_%s"%x,(x,1.4,-3.8),(1.3,2.1,.07),"WEAVE_B")
    elif i==15:
        for n in range(8):box(b,"ReceptionSlat_%d"%n,(-5.0+n*.18,1.25,-2.9),(.075,2.5,.08),"WOOD")
        box(b,"BriefingWall",(2.7,1.5,-3.8),(3.2,2.6,.12),"PLASTER")
        n="BriefingDisplay";box(b,n,(2.7,1.65,-3.70),(2.5,1.40,.07),"SOCKET");gate(info,"flat_screen",n)
    if i>=9:
        box(b,"Wainscot",(0,.48,-3.83),(11.0,.85,.08),"WOOD" if i<14 else "WEAVE_B")
    if i>=12:
        n="Radiator";box(b,n,(-4.8,.43,-3.60),(1.0,.80,.25),"IRON")
        for k in range(8):box(b,n,(-5.22+k*.12,.45,-3.44),(.045,.68,.03),"STONE_BLOCK")
        gate(info,"radiator",n)
    if i>=14:
        for n,x in enumerate((-3,3)):
            name="Fluorescent_%d"%n;box(b,name,(x,h-.15,-1.1),(1.8,.12,.24),"PAPER");gate(info,"fluorescent",name)
        name="AirConditioning";box(b,name,(5.40,h-.6,-2.0),(.25,.45,1.1),"STONE_BLOCK");gate(info,"air_conditioning",name)


def build(i):
    key="chapter_%02d"%i;title,base,h,floor=CHAPTERS[i]
    b=K.Builder(seed=610+i);hearth=i in (0,1,7,8)
    info={"chapter":i,"elapsed_year":i*200,"title":title,"look_base":base,"indoor":i!=0,"has_hearth":hearth,
          "floor":"earth" if floor=="GROUND" else "wood" if floor=="PLANK" else "stone","rustic_trophies":i<9,
          "gates":{},"technology_gates":{},"institution_gates":{},"default_tags":[],"props":{},"fx":{},
          "light":{"open_sky":i==0,"sun_dir":[-.35,-.75,-.55],"sun_energy":1.5,"fire_energy":1.2 if hearth else 0,"fire_range":6,"fog":.001 if i==0 else .002},
          "look":{"ambient_energy":.48 if i<7 else .52,"exposure":1.03},
          "camera":{"yaw":12,"pitch":-14,"fov":52,"centre":[0,.9,.1],"yaw_range":[-24,28]},"door_side":-1,
          "material_overrides":material_finishes(i)}
    room_shell(b,info,i)
    marks={"focus":S.mark((0,0,1.4)),"throne_gaze":S.mark((0,2.3,6.4)),
           "petitioner":S.mark((-1.3 if hearth else 0,0,2.4)),"execution":S.mark((-1.6 if hearth else 0,0,1.7)),
           "door":S.mark((-5.2,0,1.8)),"door_out":S.mark((-6.8,0,1.8)),"behind_windbreak":S.mark((-7.3,0,-.1))}
    seats=[(-2.8,-2.9),(2.8,-2.9),(-4.35,.45),(4.35,.45),(-.95,-3.0),(.95,-3.0)]
    if i==4:seats=[(-2.8,-1.45),(2.8,-1.45),(-4.2,.9),(4.2,.9),(-.95,-3.05),(.95,-3.05)]
    meeting=i in (11,14,15);working=i in (9,10,12,13)
    if meeting:seats=[(-1.25,-2.56),(1.25,-2.56),(-1.25,-.34),(1.25,-.34),(-2.75,-1.45),(2.75,-1.45)]
    if working:seats=[(-2.6,-2.1),(2.6,-2.1),(-4.35,.45),(4.35,.45),(-.65,-3.1),(.65,-3.1)]
    if i in (7,8):seats[0:2]=[(-3.4,-2.6),(3.4,-2.6)]
    if i==0:seats=[(-2.6,-1.3),(2.6,-1.3),(-3.6,1.5),(3.6,1.5),(-1.2,-3.0),(1.2,-3.0)]
    for n,(x,z) in enumerate(seats):
        at=(x,0,z);yaw=math.atan2(-x,3.2-z)
        face=[0,0,3.2];approach=None;exit_at=local(at,(0,0,1.20),yaw)
        if meeting:
            side=-1 if x<0 else 1
            if n<4:
                yaw=0 if n<2 else math.pi;face=[x,0,-1.45]
                approach=(side*2.15,0,z);exit_at=(side*2.25,0,-2.92 if n<2 else .55)
            else:
                yaw=-side*math.pi/2;face=[0,0,z]
                approach=(x,0,-.35);exit_at=(side*3.65,0,-.35)
        elif working and n<2:
            side=-1 if x<0 else 1;yaw=0;face=[x,0,-1.2]
            approach=(side*1.5,0,z);exit_at=(side*.7,0,-1.55)
        elif i in (7,8) and n<2:
            side=-1 if x<0 else 1;yaw=0;face=[x,0,-1.75]
            approach=(side*2.35,0,z);exit_at=(side*1.6,0,-1.95)
        if i:
            name="Chair_officials_%d"%n;chair(b,name,at,yaw,i)
            marks["officials_%d"%n]=S.mark(at,face=face,sit=True,seat=.47,external_seat=True,seat_exit=[round(v,3) for v in exit_at],seat_mesh=name)
            if approach:marks["officials_%d"%n]["seat_approach"]=[round(v,3) for v in approach]
        else:marks["officials_%d"%n]=S.mark(at)
    for n,(x,z) in enumerate(((-4.4,2.8),(-3.1,3.1),(3.1,3.1),(4.4,2.8))):marks["crowd_%d"%n]=S.mark((x,0,z))
    for n,(x,z) in enumerate(((-1.2,3.1),(1.2,3.1),(0,3.5))):marks["envoy_%d"%n]=S.mark((x,0,z))
    desks=[]
    if i in (2,3,5,6,7,8,9,10,12,13):
        places=[(-2.8,-.65),(2.8,-.65)]
        if i in (2,6):places=places[:1]
        if working:places=[(-2.6,-1.2),(2.6,-1.2)]
        if i in (7,8):places=[(-3.4,-1.75),(3.4,-1.75)]
        for n,(x,z) in enumerate(places):
            y=table(b,"Desk_%d"%n,(x,0,z),1.9 if working else 1.65,.85 if working else .75,kind="desk" if i>=10 else "trestle")
            desks.append((x,y,z))
    if i in (4,11,14,15):
        tz=-1.45 if meeting else -.55
        y=table(b,"CouncilTable",(0,0,tz),4.6 if meeting else 3.0,1.35 if meeting else 1.25,kind="boat" if i==15 else "oval")
        desks=[(-1.1 if meeting else -.7,y,tz),(1.1 if meeting else .7,y,tz)]
    if i==1:
        for x in (-4.85,4.85):table(b,"CommunityBench_%s"%x,(x,0,-2.8),1.1,.4,.45)
    if i==9:
        for n,x in enumerate((-4.7,4.7)):cabinet(b,"RecordChest_%d"%n,(x,0,-2.2),.8,.60)
    if 10<=i<15:
        y=table(b,"SecretaryStation",(-4.6,0,-2.85),1.0,.65,kind="desk")
        if i>=12:desks.append((-4.6,y,-2.85))
    if i==15:
        # Leave a full side aisle between reception and the conference end chair.
        table(b,"ReceptionConsole",(-4.9,0,-1.75),.85,.55,.84,kind="desk")
    equipment(b,info,i,desks)
    if hearth:
        S.hearth_ring(b,seed=20+i)
        marks["fire"]=S.mark((0,0,0))
        info["fx"]["fire"]={"pos":[0,.05,0],"size":.8 if i==0 else .7}
        if i==0:info["fx"]["smoke_top"]=7.0
        else:info["fx"]["smoke"]=False
    if i>=2:
        # Neutral institutional alternatives; no unconditional royal throne.
        box(b,"InstitutionAssembly",(0,2.25,-3.77),(1.0,.72,.07),"WEAVE_B")
        K.shield(b,"InstitutionThrone",(0,2.25,-3.68),(0,0,1),.36,slot="SHIELD_C",boss_slot="BRONZE")
        info["institution_gates"]={"assembly":["InstitutionAssembly"],"throne":["InstitutionThrone"]}
    info["marks"]=marks
    objects=list(b.finish(flat_slots=tuple(K.SLOT_COLOURS)).values());K.write_colors(objects)
    info["ink"]=[o.name for o in objects if not o.name.startswith(("Floor","Ground","Trees","Glazing"))]
    info["objects"]=sorted(o.name for o in objects);info["triangles"]=K.tri_count(objects)
    # Bounds are evidence for asset tests and seat-approach review, not runtime authority.
    info["bounds"]={o.name:[[round(min(K.G(v.co)[a] for v in o.data.vertices),4) for a in range(3)],
                             [round(max(K.G(v.co)[a] for v in o.data.vertices),4) for a in range(3)]] for o in objects}
    info["glb"]="court_chapter_%02d.glb"%i
    K.export_glb(objects,os.path.join(OUT,info["glb"]))
    info["sha256"]=hashlib.sha256(open(os.path.join(OUT,info["glb"]),"rb").read()).hexdigest()
    return key,info


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--chapters",default=",".join(map(str,range(16))))
    a=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    os.makedirs(OUT,exist_ok=True);path=os.path.join(OUT,"court_chapters.json")
    manifest={"generator":"tools/blender/court_chapter_sets.py","version":1,"sets":{}}
    if os.path.exists(path):manifest=json.load(open(path,encoding="utf-8"))
    for i in map(int,a.chapters.split(',')):
        t=time.time();K.clear_scene();key,info=build(i);manifest["sets"][key]=info
        print("COURT_CHAPTER",key,info["title"],info["triangles"],"triangles",len(info["objects"]),"objects",round(time.time()-t,2),"seconds",flush=True)
    with open(path,"w",encoding="utf-8") as f:json.dump(manifest,f,indent=1)

if __name__=="__main__":main()
