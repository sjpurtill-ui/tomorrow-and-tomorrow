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
import court_room_dressing as D

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
    if chapter<10:
        out=glazing if chapter>=2 else {}
        if chapter:
            # WOOD is cut joinery; actual unpeeled logs keep their BARK slot.
            # Bark's oversized dark furrows made the chancery cornice look raw.
            out["WOOD"]={"pattern":16,"albedo":"6b5038","albedo_worn":"7c6045","mottle":.045,"variation":.075,"grain":.03}
            out["PLANK"]={"pattern":9,"albedo":"71583f","albedo_worn":"826a4d","mottle":.035,"variation":.06,"grain":.03}
        if chapter in (2,3,4,5,6,8):
            out["FLAGS"]={"albedo":"9a9282","albedo_worn":"a79f8d","mottle":.045,"variation":.05,"grain":.035}
            out["STONE_BLOCK"]={"albedo":"b0a58f","albedo_worn":"b9af9c","mottle":.035,"variation":.05}
        if chapter==2:out["MUD"]={"pattern":0,"albedo":"b0a080","albedo_worn":"bcad8d","mottle":.10,"grain":.08}
        if chapter in (5,6,9):out["PLASTER"]={"pattern":0,"albedo":"c1b699","albedo_worn":"cdc2a9","mottle":.07,"variation":.06}
        return out
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
        out["CARPET"]={"pattern":18,"albedo":"45545d" if chapter==14 else "5d6263","albedo_worn":"52636c" if chapter==14 else "6b7272","mottle":.025,"variation":.02}
    if not modern:out.update(glazing)
    if chapter==12:out["PLASTER"].update({"albedo":"bcc5b6","albedo_worn":"c8d0c3"})
    return out


# Apertures are deliberately distinct silhouettes, not the same facade recolored.
# x, width, sill, head; enclosed early halls favor small/high openings, while
# later sash and industrial windows admit more controlled daylight.
WINDOWS={
 1:[(-3.55,1.0,1.65,2.30),(.1,.80,1.80,2.35),(3.7,.95,1.65,2.30)],
 2:[(-3.6,1.35,2.0,2.72),(3.6,1.35,2.0,2.72)],
 3:[(-4.25,.65,2.55,3.55),(-2.95,.55,2.8,3.65),(2.95,.55,2.8,3.65),(4.25,.65,2.55,3.55)],
 4:[(-3.5,1.25,1.55,3.12),(3.5,1.25,1.55,3.12)],
 5:[(-3.4,.90,1.65,2.9),(0,.75,1.9,3.0),(3.4,.90,1.65,2.9)],
 6:[(-3.0,1.30,2.25,2.90),(0,1.3,2.25,2.90),(3.0,1.30,2.25,2.90)],
 7:[(-3.5,1.35,1.65,2.85),(3.5,1.35,1.65,2.85)],
 8:[(-3.45,1.35,1.5,3.6),(3.45,1.35,1.5,3.6)],
 9:[(-3.3,1.65,1.40,2.75),(3.3,1.65,1.40,2.75)],
 10:[(-3.5,1.5,1.15,2.95),(3.5,1.5,1.15,2.95)],
 11:[(-3.45,1.5,1.05,2.85),(3.45,1.5,1.05,2.85)],
 12:[(-3.7,1.40,1.05,2.75),(1.75,1.45,1.05,2.75)],
 13:[(-4.3,1.15,.95,3.25),(-1.65,1.15,.95,3.25),(1.65,1.15,.95,3.25),(4.3,1.15,.95,3.25)],
 14:[(-3.0,3.7,.88,2.55),(2.7,2.8,.88,2.55)],
 15:[(-3.0,3.6,.55,2.75)],
}


def lighting(i):
    # Window fills represent diffuse daylight, so do not depend on electrical
    # capabilities. Electrical fixture meshes retain their own capability gates.
    warm=i in (0,1,7,8,9,11)
    sun=[1.05,.48,.62,.56,.52,.45,.43,.46,.50,.43,.40,.38,.36,.42,.31,.29][i]
    ambient=[.48,.38,.41,.39,.41,.39,.44,.38,.40,.43,.45,.44,.47,.48,.52,.54][i]
    # Rays enter from the actual rear apertures and travel toward +Z. A small
    # lateral component avoids the old side-wall wedge across the whole cast.
    dirs=[[-.4,-.7,-.5],[.12,-.70,.72],[-.16,-.64,.78],[.10,-.78,.64]][0 if i==0 else 1+(i%3)]
    light={"open_sky":i==0,"sun_dir":dirs,"sun_energy":sun,"fire_energy":1.15 if i in (0,1,7,8) else 0,
           "fire_range":5.5,"fog":.001,"fill_colour":"c9d6df" if warm else "d3dce0",
           "aperture_z":-3.78,"daylight_strength":0 if i==0 else .03 if i>=14 else .045 if i>=10 else .055}
    look={"ambient_energy":ambient,"exposure":1.0,"sun":"ffe6c5" if warm else "fff0da",
          "ambient":"b9c4c9" if i>=10 else "aab8bd"}
    fills=[] if i==0 else [[x*.82,min(2.35,(sill+head)/2),-2.72,.34 if i<10 else .36,5.4] for x,w,sill,head in WINDOWS[i]]
    if len(fills)>2:fills=[fills[0],fills[-1]]
    return light,look,fills


def rear_facade(b,info,i,h,wall):
    """A thick wall assembled around real openings, with deep interior reveals."""
    windows=WINDOWS[i];start=-5.65
    thick=.34 if i<10 else .24
    for n,(x,w,sill,head) in enumerate(windows):
        left=x-w/2;right=x+w/2
        if left>start:box(b,"WallBackPier_%d"%n,((left+start)/2,h/2,-4),(left-start,h,thick),wall)
        box(b,"WallBackLow_%d"%n,(x,sill/2,-4),(w,sill,thick),wall)
        box(b,"WallBackHigh_%d"%n,(x,(head+h)/2,-4),(w,h-head,thick),wall)
        trim="WOOD" if i in (1,7,9,10,11,12) else "IRON" if i>=13 else "STONE_BLOCK"
        # Splayed-looking deep jambs make windows part of a load-bearing wall.
        for side in (-1,1):box(b,"WindowReveal_%d"%n,(x+side*(w/2+.025),(sill+head)/2,-3.86),(.11,head-sill+.12,.42),trim)
        box(b,"WindowSill_%d"%n,(x,sill,-3.84),(w+.2,.10,.44),trim)
        box(b,"WindowLintel_%d"%n,(x,head+.055,-3.85),(w+.24,.12,.4),trim)
        if i not in (1,2,3,6):
            box(b,"WindowMullion_%d"%n,(x,(sill+head)/2,-3.85),(.055,head-sill,.10),trim)
        if i>=9:
            rows=3 if i==13 else 2
            for row in range(1,rows):box(b,"WindowTransom_%d"%n,(x,sill+(head-sill)*row/rows,-3.84),(w,.045,.095),trim)
        if i in (1,2,3,6):
            for bar in (-.25,0,.25):box(b,"WindowLattice_%d"%n,(x+bar*w,(sill+head)/2,-3.86),(.035,head-sill,.045),"WOOD")
        name="Glazing_%d"%n;box(b,name,(x,(sill+head)/2,-4.06),(w-.05,head-sill-.04,.018),"WINDOW_GLASS",bevel=0);gate(info,"glazing",name)
        if i<=9:
            for side in (-1,1):
                name="Shutter_%d_%s"%(n,side)
                box(b,name,(x+side*(w/2+.2),(sill+head)/2,-3.72),(.32,head-sill,.045),"PLANK",yaw=side*.32)
                for height in (.25,.75):box(b,name,(x+side*(w/2+.2),sill+(head-sill)*height,-3.68),(.28,.035,.025),"WOOD")
                gate(info,"no_glazing",name)
        start=right
    if start<5.65:box(b,"WallBackPier_end",((start+5.65)/2,h/2,-4),(5.65-start,h,thick),wall)
    # Floor skirting and an actual door reveal keep the cutaway readable as an
    # occupied interior. Door leaf is open against the external wall, not a blocker.
    if i>=9:
        box(b,"SkirtingRear",(0,.09,-3.79),(11.15,.18,.08),"WOOD")
        box(b,"CorniceRear",(0,h-.12,-3.72),(11.15,.17,.30),"PLASTER" if i>=10 else "WOOD")
    for z in (.7,2.8):box(b,"EntranceJamb_%s"%z,(-5.51,1.12,z),(.30,2.24,.13),trim)
    box(b,"EntranceHeader",(-5.51,2.28,1.75),(.30,.16,2.23),trim)
    box(b,"OpenDoorLeaf",(-5.86,1.05,.14),(.07,2.1,1.30),"PLANK")


def record_shelves(b,info,name,at,width,height=1.8,kind="book"):
    """Open shelf structure has visible working contents; no false drawer front."""
    x,y,z=at;depth=.26
    box(b,name,(x,y+height/2,z-.1),(width,height,.06),"WOOD")
    for side in (-1,1):box(b,name,(x+side*(width/2-.025),y+height/2,z),(.05,height,depth),"WOOD")
    for shelf in range(4):
        sy=y+.07+shelf*(height-.1)/3
        box(b,name,(x,sy,z),(width,.045,depth),"WOOD")
    D.shelf_records(b,box,info,name,at,width,height,kind)


def architectural_layers(b,info,i,h):
    """A compositional layer per period: structure, work walls and circulation."""
    if i==0:
        for n,x in enumerate((-4.7,4.8)):
            # Portable hide rolls, not anachronistic pottery/baskets at year zero.
            K.log_piece(b,"HideRoll_%d"%n,(x-.32,.16,-3.1),(x+.32,.16,-3.1),.16,slot="HIDE_DARK",end_slot="HIDE",stubs=0,knots=False)
        return
    if i==1:
        for x in (-4.9,-1.9,1.9,4.9):
            beam(b,"WallBrace_%s"%x,(x-.50,1.7,-3.74),(x+.50,2.9,-3.74),.075)
        for x in (-4.95,4.95):
            box(b,"HouseholdChest_%s"%x,(x,.26,-3.55),(1.1,.52,.48),"WOOD")
            box(b,"ChestLid_%s"%x,(x,.54,-3.55),(1.16,.06,.52),"PLANK")
    elif i==2:
        # A shaded portico and clerical store, separated from the open court.
        box(b,"PorticoEntablature",(0,2.92,-2.95),(10.2,.26,.45),"WOOD")
        for x in (-3.5,3.5):box(b,"ClericalStoreBench_%s"%x,(x,.30,-3.65),(1.8,.60,.35),"MUD")
        record_shelves(b,info,"TabletPigeonholes",(0,1.45,-3.72),2.3,1.2,"tablet")
    elif i==3:
        # Broad pilaster/entablature composition instead of four isolated posts.
        box(b,"AudienceEntablature",(0,4.10,-3.51),(10.6,.18,.72),"STONE_BLOCK")
        box(b,"RecessBack",(0,1.9,-3.77),(3.35,3.8,.08),"OCHRE")
        for x in (-1.8,1.8):box(b,"RecessPilaster_%s"%x,(x,1.9,-3.6),(.20,3.8,.45),"STONE_BLOCK")
        box(b,"RecessLintel",(0,3.8,-3.59),(3.85,.24,.48),"STONE_BLOCK")
    elif i==4:
        box(b,"CouncilFrieze",(0,3.5,-3.72),(10.8,.28,.30),"STONE_BLOCK")
        for x in (-4.65,-2.2,2.2,4.65):box(b,"CouncilWallPilaster_%s"%x,(x,1.75,-3.76),(.14,3.5,.25),"STONE_BLOCK")
        record_shelves(b,info,"CouncilRecords",(0,1.6,-3.76),2.2,1.25,"tablet")
    elif i==5:
        # One recessed vault bay is enough to read a ceiling without obscuring
        # the actors in the open-front cutaway camera.
        verts=[]
        for z in (-4.0,-2.95):
            for n in range(17):
                a=n*math.pi/16;verts.append(K.B((math.cos(a)*5.1,2.8+math.sin(a)*1.45,z)))
        faces=[(n,n+1,n+18,n+17) for n in range(16)]
        b.add("VaultCeilingBay",K._bm_from(verts,faces),"PLASTER")
        for n,x in enumerate((-1.65,1.65)):record_shelves(b,info,"ClericalShelves_%d"%n,(x,1.1,-3.73),1.45,1.55,"tablet")
    elif i==6:
        box(b,"LowCeilingBeam",(0,3.06,-2.98),(10.7,.22,.28),"WOOD")
        for x in (-3,0,3):record_shelves(b,info,"ArchiveSlots_%s"%x,(x,.76,-3.72),1.55,1.25,"book")
    elif i==7:
        for side in (-1,1):
            for z in (-3.4,-1.0,1.4):beam(b,"TrussBrace_%s_%s"%(side,z),(side*5.3,2.5,z),(side*3.7,4.15,z),.10)
        box(b,"HallHanging",(0,2.20,-3.73),(2.0,2.4,.045),"WEAVE_A")
        for x in (-4.7,4.7):box(b,"LinenChest_%s"%x,(x,.27,-3.6),(1.15,.54,.4),"PLANK")
    elif i==8:
        for x in (-5.2,5.2):box(b,"HallButtress_%s"%x,(x,2.1,-3.6),(.38,4.2,.55),"STONE_BLOCK")
        box(b,"StoneHallHanging",(0,2.35,-3.75),(2.0,2.8,.045),"WEAVE_A")
        for side in (-1,1):beam(b,"StoneHallRoofBrace_%s"%side,(side*5.25,3.2,-2.9),(side*3.6,4.45,-2.9),.10)
    elif i==9:
        record_shelves(b,info,"ChanceryArchive",(0,.30,-3.74),1.9,2.45,"book")
        box(b,"ChanceryCornice",(0,3.15,-3.62),(10.7,.16,.27),"WOOD")
        for x in (-2.0,2.0):box(b,"ChanceryPanelPost_%s"%x,(x,1.55,-3.69),(.12,3.1,.19),"WOOD")
    elif i==10:
        # This bay backs waiting chairs, so it is storage, not a blocked doorway.
        box(b,"SecretariatCupboard",(0,.48,-3.77),(1.90,.96,.22),"WOOD")
        for side in (-1,1):
            box(b,"CupboardDoor_%s"%side,(side*.46,.49,-3.645),(.86,.81,.035),"PLANK")
            box(b,"CupboardHandle_%s"%side,(side*.12,.56,-3.61),(.055,.08,.03),"BRONZE")
        record_shelves(b,info,"SecretariatRecords",(0,.99,-3.75),1.9,1.65,"book")
    elif i==11:
        for n,x in enumerate((-1.9,0,1.9)):
            width=1.8 if n==1 else 1.3
            box(b,"CabinetPanel_%d"%n,(x,1.75,-3.78),(width,2.95,.055),"WOOD")
            box(b,"CabinetPanelInset_%d"%n,(x,1.75,-3.735),(width-.21,2.7,.025),"PLANK")
        box(b,"CabinetPictureRail",(0,3.1,-3.68),(10.5,.08,.1),"WOOD")
    elif i==12:
        record_shelves(b,info,"MinistryBooks",(-.8,.24,-3.76),1.7,2.6,"book")
        box(b,"OfficeCornice",(0,3.1,-3.65),(10.6,.13,.3),"PLASTER")
    elif i==13:
        box(b,"IronCrossBeam",(0,3.56,-2.7),(10.6,.15,.18),"IRON")
        for side in (-1,1):box(b,"BeamWallBracket_%s"%side,(side*5.30,3.38,-2.7),(.35,.35,.35),"IRON",bevel=0)
        # Bounded filing/dispatch storage stays against the rear wall.
        record_shelves(b,info,"DispatchRecords",(0,.22,-3.75),1.6,2.45,"book")
    elif i==14:
        box(b,"ConferenceCarpet",(0,.007,-1.32),(6.35,.014,3.3),"CARPET",bevel=0)
        for side in (-1,1):
            box(b,"AcousticSide_%s"%side,(side*5.43,1.55,-1.4),(.06,2.2,2.1),"WEAVE_A")
            for n in range(6):box(b,"WindowBlind_%s"%side,(side*2.9,2.42-n*.085,-3.66),(3.6,.045,.12),"WOOD")
        box(b,"MeetingCeilingRaft",(0,2.85,-1.40),(5.9,.13,2.2),"PLASTER")
        for n,x in enumerate((-1.9,0,1.9)):
            name="ConferenceLight_%d"%n;box(b,name,(x,2.75,-1.40),(1.15,.05,.45),"PAPER");gate(info,"electricity",name)
    elif i==15:
        box(b,"ConferenceCarpet",(0,.007,-1.25),(6.3,.014,3.25),"CARPET",bevel=0)
        box(b,"BriefingBackdrop",(2.3,1.5,-3.85),(4.7,2.85,.08),"WOOD")
        box(b,"ReceptionSoffit",(-4.55,2.85,-2.5),(1.7,.18,2.4),"PLASTER")
        box(b,"CeilingPerimeterRear",(0,3.03,-3.55),(10.75,.18,.68),"PLASTER")
        for n,x in enumerate((-2.3,2.3)):
            name="LinearPendant_%d"%n;box(b,name,(x,2.62,-1.4),(1.70,.045,.09),"PAPER");gate(info,"electricity",name)
            for dx in (-.55,.55):
                beam(b,name,(x+dx,2.66,-1.4),(x+dx,3.1,-1.4),.008,"IRON")


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
    D.record(b,box,info,name,at,kind)
    if kind=="paper":
        gate(info,"paper",name)
    elif kind=="book":
        gate(info,"bound_records",name)
    else:
        info["gates"].setdefault("writing",[]).append(name)


def equipment(b,info,chapter,desks):
    for i,(x,y,z) in enumerate(desks):
        if chapter>=2:papers(b,info,"RecordSheet_%d"%i,(x-.25,y,z),"tablet" if chapter<7 else "paper")
        if chapter>=6:papers(b,info,"BoundRecord_%d"%i,(x+.34,y,z-.08),"book")
        if chapter>=11 and (chapter<14 or i>=2):
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
        if chapter==14 and i>=2:
            n="Computer_%d"%i;box(b,n,(x,y+.09,z),(.43,.18,.37),"STONE_BLOCK")
            box(b,n,(x,y+.37,z-.02),(.42,.40,.36),"STONE_BLOCK")
            box(b,n,(x,y+.39,z+.166),(.32,.27,.012),"SOCKET");gate(info,"computer",n)
        if chapter>=15:
            n="FlatDisplay_%d"%i;box(b,n,(x,y+.045,z),(.27,.09,.20),"IRON")
            # Low meeting displays preserve the other participants' sightlines.
            box(b,n,(x,y+.18,z-.055),(.44,.22,.04),"IRON")
            box(b,n,(x,y+.18,z-.03),(.38,.165,.015),"SOCKET");gate(info,"flat_screen",n)


def room_shell(b,info,i):
    title,base,h,floor=CHAPTERS[i]
    if i==0:
        K.ground(b,"Ground",6.5,12,.5,4,lambda x,z:0,lambda x,z:max(0,1-math.hypot(x,z)/6))
        for n,x in enumerate((-4.8,4.8)):
            K.tree(b,"Trees_%d"%n,(x,0,-5.3),4.8,1.7,seed=4+n,clumps=8)
        for n,(x,z) in enumerate(((-3.1,-2.2),(3.1,-2.2),(-4.3,.3),(4.3,.3))):
            K.log_piece(b,"LogSeat_%d"%n,(x-.7,.22,z),(x+.7,.22,z),.25,seed=n,stubs=0)
        panels=[((-5.2,0,-2.5),(-2.8,0,-4.0)),((-1.4,0,-4.2),(1.4,0,-4.2)),((2.8,0,-4.0),(5.2,0,-2.5))]
        for n,(a,c) in enumerate(panels):
            K.hide_panel(b,"Windbreak_%d"%n,a,c,.12,1.8,seed=n,slot="HIDE",sag=.12)
            K.post(b,"WindbreakPost_%d"%n,a,2.1,.065,pointed=False)
            K.post(b,"WindbreakPost_%d_R"%n,c,2.1,.065,pointed=False)
        return
    box(b,"Floor",(0,-.075,0),(11.6,.15,8.4),floor,bevel=0)
    wall="WOOD" if i in (1,7) else ("MUD" if i==2 else "PLASTER" if i>=6 else "STONE_BLOCK")
    if i==8:wall="STONE_BLOCK"
    # Front cutaway; left wall has a real 1.8m doorway.
    box(b,"WallRight",(5.65,h*.5,-.115),(.2,h,7.43),wall)
    box(b,"WallLeftRear",(-5.65,h*.5,-1.565),(.2,h,4.53),wall)
    box(b,"WallLeftFront",(-5.65,h*.5,3.4),(.2,h,1.2),wall)
    box(b,"DoorLintel",(-5.65,2.55,1.75),(.22,.30,1.9),"WOOD" if i<8 else "STONE_BLOCK")
    rear_facade(b,info,i,h,wall)
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
        for n,(x,w,sill,head) in enumerate(WINDOWS[i]):arch(b,"PointedWindow_%d"%n,x,-3.65,w,head-.70,.56,pointed=True)
        box(b,"SolarScreen",(4.9,1.25,-2.55),(1.0,2.5,.12),"PLANK")
        arch(b,"SolarDoor",4.6,-2.50,1.0,1.6,.65,slot="WOOD",pointed=True)
    elif i==9:
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
    light,look,fills=lighting(i)
    info={"chapter":i,"elapsed_year":i*200,"title":title,"look_base":base,"indoor":i!=0,"has_hearth":hearth,
          "floor":"earth" if floor=="GROUND" else "wood" if floor=="PLANK" else "stone","rustic_trophies":i<9,
          "gates":{},"technology_gates":{},"institution_gates":{},"default_tags":[],"props":{},"fx":{"fill":fills},
          "light":light,"look":look,"apertures":WINDOWS.get(i,[]),
          "camera":{"yaw":12,"pitch":-14,"fov":52,"centre":[0,.9,.1],"yaw_range":[-24,28]},"door_side":-1,
          "material_overrides":material_finishes(i)}
    room_shell(b,info,i)
    architectural_layers(b,info,i,h)
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
    desks=[];supports=[]
    if i in (2,3,5,6,7,8,9,10,12,13):
        places=[(-2.8,-.65),(2.8,-.65)]
        if i in (2,6):places=places[:1]
        if working:places=[(-2.6,-1.2),(2.6,-1.2)]
        if i in (7,8):places=[(-3.4,-1.75),(3.4,-1.75)]
        for n,(x,z) in enumerate(places):
            y=table(b,"Desk_%d"%n,(x,0,z),1.9 if working else 1.65,.85 if working else .75,kind="desk" if i>=10 else "trestle")
            desks.append((x,y,z))
            supports.append("Desk_%d"%n)
    if i in (4,11,14,15):
        tz=-1.45 if meeting else -.55
        y=table(b,"CouncilTable",(0,0,tz),4.6 if meeting else 3.0,1.35 if meeting else 1.25,kind="boat" if i==15 else "oval")
        desks=[(-1.1 if meeting else -.7,y,tz),(1.1 if meeting else .7,y,tz)]
        supports=["CouncilTable","CouncilTable"]
    if i==1:
        for x in (-4.85,4.85):table(b,"CommunityBench_%s"%x,(x,0,-2.8),1.1,.4,.45)
    if i==9:
        for n,x in enumerate((-4.7,4.7)):cabinet(b,"RecordChest_%d"%n,(x,0,-2.2),.8,.60)
    if 10<=i<15:
        y=table(b,"SecretaryStation",(-4.6,0,-2.85),1.0,.65,kind="desk")
        if i>=12:desks.append((-4.6,y,-2.85));supports.append("SecretaryStation")
    if i==15:
        # Leave a full side aisle between reception and the conference end chair.
        table(b,"ReceptionConsole",(-4.9,0,-1.75),.85,.55,.84,kind="desk")
    equipment(b,info,i,desks)
    if i>=2:D.work_clusters(b,box,beam,info,i,desks,supports)
    if hearth:
        if i:
            # Flush noncombustible inset: the authored ash/log bases remain above
            # its .005m top, and the planked floor no longer carries the fire.
            box(b,"HearthstoneInset",(0,-.0375,0),(2.3,.085,1.95),"STONE_DARK",bevel=.015)
            for side in (-1,1):box(b,"HearthstoneBorder_%s"%side,(side*1.12,.008,0),(.09,.016,1.98),"FLAGS",bevel=.005)
        S.hearth_ring(b,seed=20+i)
        marks["fire"]=S.mark((0,0,0))
        info["fx"]["fire"]={"pos":[0,.05,0],"size":.8 if i==0 else .7}
        if i==0:info["fx"]["smoke_top"]=7.0
        else:info["fx"]["smoke"]=False
    if i>=2:
        # Neutral institutional alternatives; no unconditional royal throne.
        emblem_y=3.1 if i in (9,10,12,13) else 2.25
        emblem_x=-.62 if i==15 else 0
        if i==2:emblem_x,emblem_y=2.15,1.95
        elif i==4:emblem_y=3.3
        elif i==5:emblem_y=3.5
        elif i==6:emblem_x,emblem_y=1.55,2.1
        elif i==9:emblem_x,emblem_y=1.45,2.25
        elif i==10:emblem_x,emblem_y=1.85,2.25
        elif i==12:emblem_x,emblem_y=3.55,2.25
        beam(b,"InstitutionMount",(emblem_x,emblem_y,-3.8),(emblem_x,emblem_y,-3.59),.025)
        emblem_scale=.7 if i==9 else 1.0
        box(b,"InstitutionAssembly",(emblem_x,emblem_y,-3.60),(emblem_scale,.72*emblem_scale,.07),"WEAVE_B")
        D.plaque_frame(b,box,(emblem_x,emblem_y,-3.60),emblem_scale)
        K.shield(b,"InstitutionThrone",(emblem_x,emblem_y,-3.52),(0,0,1),.36*emblem_scale,slot="SHIELD_C",boss_slot="BRONZE")
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
