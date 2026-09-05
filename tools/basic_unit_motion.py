"""Authored, baked combat motion for the founding-force rigs.

Bone-local Y is world Z; local Z points forward (-world Y). Two-bone IK
keeps the hands on their equipment and the support feet on the ground.
"""
import math
from mathutils import Vector, Matrix, Euler


def sample(t, keys):
    if t <= keys[0][0]: return keys[0][1]
    for (a, va), (b, vb) in zip(keys, keys[1:]):
        if t <= b:
            u = (t-a)/(b-a)
            u = u*u*(3-2*u)
            if isinstance(va, (tuple, list)):
                return tuple(x+(y-x)*u for x,y in zip(va,vb))
            return va+(vb-va)*u
    return keys[-1][1]


def orient(rig, bone, position, rotation):
    import bpy
    rest = rig.data.bones[bone].matrix_local.to_3x3()
    m = (rotation @ rest).to_4x4()
    m.translation = position
    rig.pose.bones[bone].matrix = m
    # Blender caches parent pose matrices. Flush before assigning a child's
    # world pose, or the baked local transforms pull the joints apart.
    bpy.context.view_layer.update()


def limb(rig, joints, upper, lower, tip, target, pole, wrist=None):
    """Analytical IK, baked into deform bones (no runtime constraints)."""
    p = rig.pose.bones
    rest = rig.data.bones[upper]
    parent = p[upper].parent
    anchor = parent.matrix @ parent.bone.matrix_local.inverted() @ rest.head_local
    a,b,c = [Vector(joints[n]) for n in (upper,lower,tip)]
    l1,l2 = (b-a).length,(c-b).length
    offset = Vector(target)-anchor
    d = max(abs(l1-l2)+.001, min(offset.length, l1+l2-.001))
    axis = offset.normalized()
    end = anchor + axis*d
    bend = Vector(pole)-anchor
    bend = (bend-axis*bend.dot(axis)).normalized()
    along = (l1*l1-l2*l2+d*d)/(2*d)
    elbow = anchor+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
    orient(rig, upper, anchor, (b-a).rotation_difference(elbow-anchor).to_matrix())
    orient(rig, lower, elbow, (c-b).rotation_difference(end-elbow).to_matrix())
    orient(rig, tip, end, Euler(wrist or (0,0,0), 'XYZ').to_matrix())


def combat_pose(rig, joints, kind, clip, t):
    import bpy
    p = rig.pose.bones
    if clip == 'attack':
        if kind == 'levy':
            # Load the back foot, lift the club behind the shoulder, step and
            # drive through the strike, then recover more slowly than the hit.
            weight = sample(t, [(0,0),(.27,-.075),(.46,.12),(.57,.13),(.82,.045),(1,0)])
            p['pelvis'].location = (0,-.035,weight)
            p['chest'].rotation_euler = (sample(t,[(0,0),(.28,-.12),(.46,.27),(.60,.20),(1,0)]),
                sample(t,[(0,0),(.28,-.32),(.46,.30),(.63,.22),(1,0)]),0)
            p['head'].rotation_euler.x = -.09*math.sin(math.pi*t)
            hand = sample(t,[(0,joints['hand.R']),(.27,(.39,.13,1.77)),(.37,(.40,.09,1.79)),
                (.48,(.27,-.51,1.20)),(.56,(.23,-.48,1.10)),(.80,(.39,-.31,1.20)),(1,joints['hand.R'])])
            wrist = sample(t,[(0,0),(.28,-1.0),(.37,-.82),(.48,1.93),(.57,2.05),(.82,.40),(1,0)])
            other = sample(t,[(0,joints['hand.L']),(.29,(-.35,-.24,1.35)),(.50,(-.48,-.31,1.19)),(1,joints['hand.L'])])
            step = sample(t,[(0,0),(.26,0),(.45,.18),(.67,.18),(1,0)])
            lift = sample(t,[(0,0),(.26,0),(.34,.09),(.45,0),(.72,0),(.86,.055),(1,0)])
            left_wrist=(0,0,-.10)
        elif kind == 'line_infantry':
            # Chamber a horizontal spear behind the shield before a fast lunge.
            weight = sample(t,[(0,0),(.24,-.045),(.45,.18),(.54,.18),(.78,.025),(1,0)])
            p['pelvis'].location=(0,-.045,weight)
            p['chest'].rotation_euler=(sample(t,[(0,0),(.26,-.055),(.45,.16),(.60,.12),(1,0)]),
                sample(t,[(0,0),(.25,-.16),(.45,.14),(.65,.08),(1,0)]),0)
            hand=sample(t,[(0,joints['hand.R']),(.23,(.38,.12,1.34)),(.34,(.39,.12,1.34)),
                (.44,(.34,-.60,1.34)),(.52,(.34,-.60,1.34)),(.76,(.37,-.12,1.32)),(1,joints['hand.R'])])
            wrist=sample(t,[(0,0),(.23,1.53),(.70,1.53),(.85,.65),(1,0)])
            other=sample(t,[(0,joints['hand.L']),(.24,(-.32,-.34,1.30)),(.45,(-.33,-.51,1.32)),(.68,(-.34,-.35,1.29)),(1,joints['hand.L'])])
            step=sample(t,[(0,0),(.22,0),(.42,.25),(.67,.25),(1,0)])
            lift=sample(t,[(0,0),(.22,0),(.31,.07),(.42,0),(.7,0),(.84,.06),(1,0)])
            left_wrist=(0,0,0)
        else:
            # Draw to the cheek, hold aim, release string and arrow, follow through.
            weight=0
            p['pelvis'].location.y=-.025
            draw=sample(t,[(0,0),(.17,0),(.40,1),(.55,1),(.59,0),(.64,.14),(.71,0),(1,0)])
            p['chest'].rotation_euler.y=sample(t,[(0,0),(.40,-.075),(.55,-.075),(.62,.04),(1,0)])
            p['head'].rotation_euler.y=.08*math.sin(math.pi*t)
            other=sample(t,[(0,joints['hand.L']),(.20,(-.38,-.48,1.43)),(.73,(-.38,-.48,1.43)),(1,joints['hand.L'])])
            nock=Vector(other)+Vector((0,.10+.24*draw,0))
            hand=sample(t,[(0,joints['hand.R']),(.17,tuple(Vector(other)+Vector((0,.10,0)))),
                (.40,(-.38,-.14,1.43)),(.55,(-.38,-.14,1.43)),(.63,(-.24,.06,1.46)),(.78,(.10,-.02,1.24)),(1,joints['hand.R'])])
            if .17 <= t <= .55: hand=tuple(nock)
            p['bowstring'].location.z=-.24*draw
            p['arrow'].location.z=-.24*draw
            if .56 <= t < .94:
                p['arrow'].location.z=sample(t,[(.56,-.24),(.61,2.0),(.68,5.0),(.94,5.0)])
                p['arrow'].scale=(.001,.001,.001) if t>=.68 else (1,1,1)
            wrist=0; left_wrist=(0,0,0); step=0; lift=0
        bpy.context.view_layer.update()
        limb(rig,joints,'thigh.L','shin.L','foot.L',(-.14,-step,.12+lift),(-.14,-1,.45))
        limb(rig,joints,'thigh.R','shin.R','foot.R',(.14,.035,.12),(.14,-1,.45))
        limb(rig,joints,'upper_arm.R','forearm.R','hand.R',hand,(.9,.10,1.25),(wrist,0,0))
        limb(rig,joints,'upper_arm.L','forearm.L','hand.L',other,(-.9,-.1,1.15),left_wrist)
    else:
        # Pelvis-driven fall: recoil -> knee failure -> hip/shoulder impact -> settle.
        # Both legs articulate throughout; the actor does not pivot as one plank.
        side={'levy':-.12,'line_infantry':.10,'skirmisher':-.20}[kind]
        hip=sample(t,[(0,(0,0,.89)),(.12,(0,.025,.84)),(.30,(side*.25,.08,.65)),
            (.48,(side*.6,.29,.47)),(.61,(side,.48,.28)),(.67,(side,.48,.32)),
            (.77,(side,.49,.28)),(1,(side,.49,.28))])
        angle=sample(t,[(0,0),(.12,-.16),(.30,-.20),(.48,-.72),(.61,-1.49),
            (.67,-1.40),(.77,-1.49),(1,-1.49)])
        roll=sample(t,[(0,0),(.30,side*.8),(.61,side),(.77,side*.85),(1,side*.85)])
        rotation=Euler((angle,roll,0),'XYZ').to_matrix()
        root_position=Vector(hip)-rotation@Vector(joints['pelvis'])
        orient(rig,'root',root_position,rotation)
        p['chest'].rotation_euler.x=sample(t,[(0,0),(.12,-.10),(.30,.32),(.48,.17),(.61,.06),(.70,-.04),(.82,0),(1,0)])
        p['head'].rotation_euler.x=sample(t,[(0,0),(.10,-.19),(.30,.26),(.55,.18),(.62,-.10),(.72,.05),(.84,0),(1,0)])
        p['head'].rotation_euler.y=sample(t,[(0,0),(.30,0),(.70,.22),(.84,.25),(1,.25)])
        bpy.context.view_layer.update()
        for suffix,s in [('L',-1),('R',1)]:
            ankle=sample(t,[(0,(s*.14,0,.12)),(.25,(s*.17,-.035,.12)),
                (.48,(s*.22,-.12,.12)),(.63,(s*.25,-.23,.14)),(.79,(s*.25,-.22,.131)),(1,(s*.25,-.22,.131))])
            limb(rig,joints,'thigh.'+suffix,'shin.'+suffix,'foot.'+suffix,ankle,(s*.30,-.5,.62),
                (sample(t,[(0,0),(.48,0),(.77,-.40),(1,-.40)]),0,s*.12))
            hand=sample(t,[(0,joints['hand.'+suffix]),(.14,(s*.44,-.20,1.32)),
                (.31,(s*.45,-.22,.85)),(.49,(s*.53,.35,.36)),(.61,(s*.53,.95,.10)),
                (.68,(s*.53,.94,.14)),(.80,(s*.53,.95,.08)),(1,(s*.53,.95,.08))])
            if suffix=='L' and kind=='skirmisher':
                wrist=(0,sample(t,[(0,0),(.34,.25),(.61,math.pi/2),(.80,math.pi/2),(1,math.pi/2)]),0)
            else:
                early_angle=1.05 if kind=='line_infantry' and suffix=='R' else .3*s
                wrist=(sample(t,[(0,0),(.28,early_angle),(.60,s*math.pi/2),(.80,s*math.pi/2),(1,s*math.pi/2)]),0,0)
            limb(rig,joints,'upper_arm.'+suffix,'forearm.'+suffix,'hand.'+suffix,hand,
                (s*.85,.60,.18),wrist)
        if kind=='skirmisher': p['arrow'].scale=(.001,.001,.001) if t>.30 else (1,1,1)
