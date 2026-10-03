"""Court acting (K): executions, batch A, built to N's tracks
(codex/court-exec-sound, court_gore_foley.gd ACTS): each act's blow falls at
N's lead, every beat on N's offsets from it. Same conventions as
court_anims_exec.py (events, props, stage; every clip of an act starts at the
act's 0 unless the plan starts it later). Positions are worked out against M's
props (court_exec_props.json): the stake's top, the cauldron's seat and rim,
the ledge's tipping edge, where a spear, a bow and a ladle are gripped.

  3  into the fire       a shove, a hop, a teeter, WHOOMPH; the charred one
                         gets up stiff as a plank, walks two steps, coughs a
                         smoke ring and crumbles
  5  spear pincushion    five spears, a creak; the child's goes into the wall
                         and the victim snorts; one in the head; timber
  6  stoned by the court bonk, bonk, bonk, a cairn; a finger up out of the top;
                         the child's stone goes backwards onto an official
  1  boulder drop        lounging, picking his teeth, SPLAT; a feeble wave from
                         under it; peeled off the floor, rolled up, carried out
  14 boiled in the pot   dangled, dropped, spun by the cook's stirring, a
                         sneeze at the herbs, sunk; the cook tastes, salts and
                         taps the skull back down
  16 volley of arrows    two volleys, a porcupine; the captain's long aim takes
                         the hat; a sigh, and over backwards
  15 the stake           hoisted up and set down on it; a slow slide down to the
                         scribe's eye level, toes to the floor; a peek at the
                         tablet; ahem
"""
import math
from mathutils import Vector

import cf_anim
from cf_anim import add, both, side, merge, wave
import court_anims_lib as L
from court_anims_lib import ArmKey, arm_at, arm_fk, arm_solve, legs_fk, plant, tremble, breathe, drift, pulses, mv, landmarks
from court_anims_clips import (Act, clip, torso_of, tpose, body_pt, hand_mouth, hand_heart, hand_belly, hand_thigh, hand_face,
                               hand_crown, stance_arm, hang, UPPER, FULL)
from court_anims_more import _legs0
from court_anims_exec import V, godot, fist, Tool, both_knees, square, KNEEL_UP, ev, ADULTS

CHILD = ["child"]


def make_exec2(clips):
    act_fire(clips)
    act_spears(clips)
    act_stones(clips)
    act_boulder(clips)
    act_boil(clips)
    act_arrows(clips)
    act_stake(clips)


# --- helpers ---------------------------------------------------------------------------

def with_(d, **kw):
    out = dict(d)
    out.update(kw)
    return out


def tipped(deg, way, extra=(0.0, 0.0, 0.0)):
    """The torso of a body kept straight and tipped `deg` about its ankles
    (the legs FK at rest follow the hips): way "back", "fwd", "left" (its
    left), "right"; `extra` is added to where the hips go."""
    f = L.FRAME
    h = (f.pelvis.z - f.ankle["L"].z) / L.K
    th = math.radians(deg)
    up = h * math.cos(th) - h
    off = h * math.sin(th)
    rot, loc = {"back": ((-deg, 0, 0), (0.0, off, up)), "fwd": ((deg, 0, 0), (0.0, -off, up)),
                "left": ((0, deg, 0), (off, 0.0, up)), "right": ((0, -deg, 0), (-off, 0.0, up))}[way]
    return dict(hips=rot, hips_loc=(loc[0] + extra[0], loc[1] + extra[1], loc[2] + extra[2]))


def legs(a, **bones):
    """FK legs: the stance's legs with these rotations added (thigh_L=(x,y,z)...)."""
    extra = {}
    for name, rot in bones.items():
        extra[name.replace("_", ".")] = {"rot": rot}
    return merge(_legs0(a), extra)


def bound(s_):
    """A hand tied behind the back, the wrists crossed over the tailbone."""
    f = L.FRAME
    return arm_at(s_, w=body_pt(-0.03, 0.11, f.z_hip / L.K + 0.05), along=(-0.6, 0.35, -0.7), palm=(0.1, 1.0, 0.1), pole=(0.9, 0.7, 0.1),
                  curl=(50, 40, 20))


def in_role(P, at, yaw):
    """A point in the act's frame (Godot axes, the victim at the origin facing
    +Z) as a role standing at `at` turned `yaw` degrees sees it (Blender
    figure axes, k-scaled)."""
    th = math.radians(yaw)
    d = (P[0] - at[0], P[1] - at[1], P[2] - at[2])
    left = d[0] * math.cos(th) - d[2] * math.sin(th)
    front = d[0] * math.sin(th) + d[2] * math.cos(th)
    return V(left, -front, d[1])


def shoulder_in_hall(a, torso, s_):
    """Where a shoulder is in the hall when the body holds `torso` (figure axes)."""
    return L.chest_to_world(torso_of(a.B, tpose(**torso)), L.FRAME.shoulder[s_])


def yaw_to(at, P):
    """The yaw (degrees) that turns a role at `at` to face the point P."""
    return round(math.degrees(math.atan2(P[0] - at[0], P[2] - at[2])), 1)


# =====================================================================================
# 3. Into the fire. N: heave -1.0, swing_whoosh -0.3, WHOOMPH 0, fire_pop 1.2,
#    step_earth 2.3 / 2.9, cough 3.5, smoke_poof 3.9, crumble 5.0, punch 7.0,
#    rub_hands 7.6 (elder), hum_yes 8.4; lead 2.8. The hearth is at the victim's
#    left (x 1.55); the shover stands at its right.
# =====================================================================================

FIRE_T0 = 2.8
FIRE_AT = [1.55, 0.0, 0.0]
FIRE_SHOVER = [-0.70, 0.0, 0.0]


def act_fire(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    T = FIRE_T0

    a = Act(8.6, drag=0.6, feet=False, base_pose=square())
    l0 = _legs0(a)
    X = 0.32                                    # where it lands in the fire from (its left)
    look_r = dict(neck=(0, 0, -12), head=(-4, 0, -38))
    shoved = dict(hips=(0, 10, 0), hips_loc=(0.08, 0.0, 0.02), spine=(0, 6, 0), chest=(-4, 8, 0), neck=(0, 0, 8), head=(-6, -6, 14))
    hop = dict(hips=(0, 12, 0), hips_loc=(0.24, 0.0, 0.08), spine=(0, 6, 0), chest=(-6, 8, 0), head=(-8, -4, 10))
    teeter_a = dict(hips=(0, -5, 0), hips_loc=(X, 0.0, 0.0), spine=(0, -6, 0), chest=(0, -8, 0), head=(-4, 0, -6))
    teeter_b = dict(hips=(0, 14, 0), hips_loc=(X, 0.0, 0.0), spine=(0, 8, 0), chest=(0, 10, 0), head=(-6, 0, 10))
    lying = with_(tipped(84, "left", (X, 0.0, 0.04)), spine=(0, 4, 0), chest=(-4, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0))
    landed = with_(lying, hips_loc=(lying["hips_loc"][0], 0.0, lying["hips_loc"][2] + 0.03))
    twitch = with_(lying, chest=(-4, 10, 0), head=(-6, 0, 12))
    half = with_(tipped(45, "left", (X, 0.0, 0.0)), chest=(-2, 0, 0), head=(-4, 0, 0))
    up = dict(hips_loc=(X, 0.0, 0.0), spine=(-2, 0, 0), chest=(-4, 0, 0), head=(-4, 0, 0))
    step1 = with_(up, hips_loc=(X, -0.30, 0.0))
    step2 = with_(up, hips_loc=(X, -0.62, 0.0))
    breath_in = with_(step2, chest=(-10, 0, 0), neck=(-4, 0, 0), head=(-8, 0, 0))
    cough_t = with_(step2, spine=(6, 0, 0), chest=(14, 0, 0), neck=(8, 0, 0), head=(10, 0, 0))
    ring_t = with_(step2, chest=(-6, 0, 0), neck=(-6, 0, 0), head=(-14, 0, 0))
    watch_ring = with_(step2, chest=(-8, 0, 0), neck=(-12, 0, 0), head=(-26, 0, 0))
    look_down = with_(step2, neck=(10, 0, 0), head=(26, 0, 0))
    sheep = with_(step2, head=(-2, 6, 8))
    crumble = dict(hips=(18, 0, 0), hips_loc=(X, -0.55, -0.45), spine=(18, 0, 0), chest=(12, 0, 0), neck=(10, 0, 0), head=(12, 0, 0))
    for t, tor, kind in ((0.0, {}, "ease"), (1.6, {}, "ease"), (1.85, look_r, "out"), (2.45, look_r, "ease"), (2.5, shoved, "snap"),
                         (2.58, hop, "out"), (2.63, teeter_a, "in"), (2.69, teeter_b, "ease"), (2.86, lying, "in"), (2.95, landed, "settle"),
                         (3.9, landed, "ease"), (T + 1.2, twitch, "snap"), (4.15, landed, "ease"), (4.3, landed, "ease"), (4.55, half, "linear"),
                         (4.75, up, "out"), (4.85, with_(up, chest=(-8, 0, 0)), "settle"), (T + 2.3, step1, "ease"), (5.45, step1, "ease"),
                         (T + 2.9, step2, "ease"), (6.15, breath_in, "ease"), (T + 3.5, cough_t, "snap"), (6.5, step2, "ease"),
                         (T + 3.9, ring_t, "out"), (7.0, watch_ring, "ease"), (7.3, look_down, "ease"), (7.55, sheep, "ease"),
                         (T + 5.0, sheep, "ease"), (8.1, crumble, "in"), (8.6, crumble, "ease")):
        a.t(t, kind, **tor)
    a.legs([(0.0, l0), (2.5, l0), (2.58, legs(a, thigh_L=(-20, 0, 0), shin_L=(35, 0, 0), thigh_R=(-24, 0, 0), shin_R=(40, 0, 0)), "out"),
            (2.66, legs(a, thigh_L=(0, -6, 0), thigh_R=(-10, 38, 0), shin_R=(30, 0, 0)), "in"), (2.86, l0, "ease"), (4.85, l0),
            (4.97, legs(a, thigh_L=(-26, 0, 0), shin_L=(10, 0, 0), thigh_R=(10, 0, 0)), "ease"), (T + 2.3, l0, "in"),
            (5.57, legs(a, thigh_R=(-26, 0, 0), shin_R=(10, 0, 0), thigh_L=(10, 0, 0)), "ease"), (T + 2.9, l0, "in"),
            (T + 5.0, l0), (8.1, both_knees(a, lean=18), "in"), (8.6, both_knees(a, lean=18))])
    for s_ in "LR":
        clasp = arm_at(s_, w=body_pt(0.05, -0.22, f.z_waist / k + 0.04), along=(-0.6, -0.4, 0.4), palm=(-0.5, 0.2, -0.8), pole=(0.9, 0.3, -0.3), curl=(40, 30, 10))
        fly = arm_at(s_, w=body_pt(0.34, -0.10, z_chest + 0.32), along=(0.4, -0.2, 0.9), palm=(0.0, -1.0, 0.0), pole=(0.8, 0.3, -0.5), curl=(-6, -10, -10), sh=(0, -12, 0))
        mill_a = arm_at(s_, w=body_pt(0.52, -0.05, z_chest + 0.10), along=(0.9, 0.0, 0.3), palm=(0.0, -1.0, 0.2), pole=(0.3, 0.6, -0.7), curl=(-6, -10, -10))
        mill_b = arm_at(s_, w=body_pt(0.40, 0.10, z_chest + 0.42), along=(0.5, 0.3, 0.8), palm=(0.0, 1.0, 0.0), pole=(0.3, 0.6, -0.7), curl=(-6, -10, -10))
        flung = arm_at(s_, w=body_pt(0.48, -0.02, z_chest + 0.18), along=(0.8, 0.0, 0.6), palm=(0.0, -0.3, -0.95), pole=(0.6, 0.6, -0.4), curl=(20, 14, 6))
        stiff = a.rest_arm[s_].copy(w=a.rest_arm[s_].w + mv(Vector((0.08 * k, -0.03 * k, 0.05 * k)), s_), curl=(14, 6, 0), sh=(0, -6, 0))
        a.rest(s_, 0.0).arm(s_, 0.4, clasp, "ease").arm(s_, 2.45, clasp).arm(s_, 2.52, fly, "snap")
        a.arm(s_, 2.6, mill_a if s_ == "L" else mill_b, "ease").arm(s_, 2.69, mill_b if s_ == "L" else mill_a, "ease")
        a.arm(s_, 2.84, flung, "in").arm(s_, 4.3, flung).arm(s_, 4.8, stiff, "out")
        if s_ == "R":
            cough = hand_mouth("R").copy(curl=(40, 30, 14))
            a.arm(s_, 6.15, stiff).arm(s_, T + 3.5, cough, "snap").arm(s_, 6.55, cough).arm(s_, 6.85, stiff, "ease")
        a.arm(s_, T + 5.0, stiff).arm(s_, 8.1, hang(a, s_, 18, curl=(30, 20, 10)), "in").arm(s_, 8.6, hang(a, s_, 18, curl=(30, 20, 10)))
    a.f(0.0, "ease", worry=0.6, brows=0.5, lids=1.1).f(1.85, "out", lids=1.4, brows=1.0, worry=0.9, eyes_x=-1.0).f(2.45, "ease", lids=1.4, brows=1.0, worry=0.9, eyes_x=-1.0)
    a.f(2.5, "snap", lids=1.45, jaw=0.7, brows=1.0, worry=1.0).f(2.8, "ease", lids=0.1, tight=1.0, jaw=0.5)
    a.f(4.75, "out", lids=1.35, jaw=0.0, brows=0.2).f(6.15, "ease", lids=1.35, puff=0.3).f(T + 3.5, "snap", lids=0.0, puff=1.0, tight=0.6)
    a.f(6.5, "ease", lids=1.2, puff=0.0).f(T + 3.9, "out", lids=1.2, jaw=0.45, puff=0.0, eyes_y=0.3).f(7.0, "ease", lids=1.3, jaw=0.0, eyes_y=1.0)
    a.f(7.3, "ease", lids=1.1, eyes_y=-1.0, brows=0.6).f(7.55, "ease", lids=1.0, smile=0.45, brows=0.7).f(T + 5.0, "ease", lids=1.0, smile=0.45, brows=0.7)
    a.f(8.05, "snap", lids=0.2, smile=0.0)
    clips["exec_fire_victim"] = clip(
        "exec_fire_victim", 8.6, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        stage={"fire": FIRE_AT, "ash": [X, 0.0, 0.58]},
        events=[ev(2.5, "shoved"), ev(T, "whoomph", bone="chest"), ev(T, "char", note="J's charred look from here"), ev(T + 1.2, "fire_pop"),
                ev(4.3, "get_up"), ev(T + 2.3, "step"), ev(T + 2.9, "step"), ev(T + 3.5, "cough"),
                ev(T + 3.9, "smoke_ring", bone="head", dir=(0.0, 0.25, 1.0)), ev(T + 5.0, "crumble", note="the ash pile takes over by 8.1")])

    # ---- the shover (at the victim's right, facing it, 0.70 m off): cracks his
    #      knuckles, winds up, shoves, flinches from the whoomph, claps the soot
    #      off his hands, a satisfied nod
    a = Act(5.0, drag=0.6)
    lean_back = dict(hips_loc=(0.0, 0.06, -0.02), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(-4, 0, 0), head=(-4, 0, 0))
    lunge = dict(hips_loc=(0.0, -0.18, -0.05), spine=(12, 0, 0), chest=(10, 0, 0), neck=(-4, 0, 0), head=(-8, 0, 0))
    recoil = dict(hips_loc=(0.0, 0.10, -0.02), spine=(-8, 0, 0), chest=(-12, 0, 6), neck=(6, 0, 8), head=(10, 0, 20))
    calm = dict(chest=(-2, 0, 0), head=(-2, 0, 0))
    nod = dict(chest=(-2, 0, 0), neck=(8, 0, 0), head=(12, 0, 0))
    for t, tor, kind in ((0.0, {}, "ease"), (0.5, dict(chest=(0, 0, 6), head=(0, 0, 6)), "ease"), (0.9, dict(chest=(0, 0, -6), head=(0, 0, -6)), "ease"),
                         (1.3, {}, "ease"), (T - 1.0, lean_back, "ease"), (2.35, with_(lean_back, chest=(-12, 0, 0)), "ease"), (2.5, lunge, "snap"),
                         (2.75, lunge, "ease"), (2.86, recoil, "snap"), (3.4, recoil, "ease"), (3.7, calm, "ease"), (4.3, nod, "out"), (4.6, calm, "ease"),
                         (5.0, calm, "ease")):
        a.t(t, kind, **tor)
    for s_ in "LR":
        crack = arm_at(s_, w=body_pt(0.03, -0.28, z_chest - 0.02), along=(-0.6, -0.5, 0.4), palm=(-0.9, 0.0, -0.2), pole=(0.9, 0.3, -0.5), curl=(70, 60, 30))
        back = arm_at(s_, w=body_pt(0.18, -0.10, z_chest + 0.04), along=(0.0, -0.3, 0.95), palm=(0.0, -1.0, 0.0), pole=(0.9, 0.5, -0.2), curl=(-6, -10, -10), sh=(0, -6, 0))
        push = arm_at(s_, w=body_pt(0.12, -0.42, z_chest + 0.06), along=(0.0, -0.2, 0.98), palm=(0.0, -1.0, 0.0), pole=(0.9, 0.3, -0.4), curl=(-8, -12, -10))
        shield = arm_at(s_, w=body_pt(0.06, -0.26, f.z_shoulder / k + 0.10), along=(-0.8, -0.2, 0.5), palm=(0.0, -0.95, 0.3), pole=(0.9, 0.0, -0.4), curl=(10, 4, 0), sh=(0, -14, -4))
        clap_out = arm_at(s_, w=body_pt(0.14, -0.30, z_chest - 0.08), along=(-0.3, -0.4, 0.85), palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.3, -0.6), curl=(4, -4, -6))
        clap_in = clap_out.copy(w=clap_out.w + mv(Vector((-0.11 * k, 0.0, 0.0)), s_))
        a.rest(s_, 0.0).rest(s_, 0.7).arm(s_, 0.9, crack, "out").arm(s_, 1.3, crack).arm(s_, 1.85, back, "ease").arm(s_, 2.35, back)
        a.arm(s_, 2.5, push, "snap").arm(s_, 2.75, push).arm(s_, 2.88, shield, "snap").arm(s_, 3.4, shield)
        a.arm(s_, 3.6, clap_out, "ease").arm(s_, 3.68, clap_in, "in").arm(s_, 3.76, clap_out, "out").arm(s_, 3.84, clap_in, "in").arm(s_, 4.0, clap_out, "out").rest(s_, 4.4, "ease")
    a.foot("R", 0.0).foot("R", 1.75).foot("R", 1.9, (-0.02, 0.16, 0.0), "out", lift=0.04).foot("R", 2.75, (-0.02, 0.16, 0.0)).foot("R", 3.5, (0, 0, 0), "out", lift=0.04)
    a.foot("L", 0.0).foot("L", 2.38).foot("L", 2.5, (0.02, -0.22, 0.0), "snap", lift=0.05).foot("L", 2.86, (0.02, -0.22, 0.0)).foot("L", 3.05, (0.02, 0.0, 0.0), "out", lift=0.05)
    a.foot("L", 5.0, (0.02, 0.0, 0.0))
    a.f(0.0, "ease", stern=0.5, lids=0.85).f(1.8, "ease", stern=0.9, tight=0.8, puff=0.7).f(2.5, "snap", stern=1.0, jaw=0.4, tight=0.6)
    a.f(2.86, "snap", lids=0.1, tight=1.0, jaw=0.2).f(3.5, "ease", lids=0.8, stern=0.3).f(4.3, "ease", smile=0.5, lids=0.8).f(5.0, "ease", smile=0.4, lids=0.85)
    clips["exec_fire_shover"] = clip("exec_fire_shover", 5.0, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
                                     events=[ev(T - 1.0, "heave"), ev(2.5, "shove"), ev(2.86, "recoil"), ev(3.68, "clap"), ev(3.84, "clap")])


# =====================================================================================
# 5. Spear pincushion. N: thunks -0.16 / 0.2 / 0.5 / 0.82 / 1.1, creak 1.9,
#    hide_thwap 2.8 (child), snort_laugh 3.2, thunk 4.3, creak 4.8, faint_thump
#    5.6, punch 6.1, lone_clap 6.9; lead 2.6. The spears come from its right.
# =====================================================================================

SPEAR_T0 = 2.6
SPEAR_RELEASE = 0.62
SPEAR_FLIGHT = 0.30
# (act time, bone, where it goes in: Godot axes for a 1.72 m body at rest)
SPEAR_HITS = [(2.44, "chest", (-0.15, 1.30, 0.03)), (2.80, "thigh.R", (-0.13, 0.72, 0.03)), (3.10, "upper_arm.R", (-0.21, 1.36, 0.0)),
              (3.42, "hips", (-0.17, 0.98, 0.02)), (3.70, "spine", (-0.15, 1.12, -0.03)), (6.90, "head", (-0.08, 1.63, 0.0))]


def act_spears(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    T = SPEAR_T0

    # ---- the victim: hands tied behind, facing the god
    a = Act(9.0, drag=0.6, feet=False, base_pose=square())
    l0 = _legs0(a)
    keys = [(0.0, {}, "ease"), (2.2, dict(neck=(0, 0, -8), head=(-4, 0, -18)), "ease")]
    # each spear knocks it a little further to its left and turns it
    drift_x = 0.0
    for i, (t, bone, at) in enumerate(SPEAR_HITS[:5]):
        drift_x += 0.018
        hit = dict(hips=(0, 6 + 2 * i, 0), hips_loc=(drift_x + 0.03, 0.0, 0.0), spine=(0, 5, 0), chest=(-6 if i % 2 == 0 else 4, 8, 8 if i % 2 == 0 else -4),
                   neck=(0, 0, 6), head=(-8, 4, 12 if i % 2 == 0 else -6))
        rest_ = dict(hips=(0, 3, 0), hips_loc=(drift_x, 0.0, 0.0), spine=(2, 2, 0), chest=(0, 4, 0), head=(-2, 0, 2))
        keys.append((t, hit, "snap"))
        keys.append((min(t + 0.2, SPEAR_HITS[i + 1][0] - 0.02) if i < 4 else t + 0.25, rest_, "settle"))
    settle = dict(hips=(0, 3, 0), hips_loc=(drift_x, 0.0, 0.0), spine=(2, 2, 0), chest=(0, 4, 0), head=(-2, 0, 2))
    sway_r = with_(settle, hips=(0, -6, 0), chest=(0, -6, 0))
    sway_l = with_(settle, hips=(0, 7, 0), chest=(0, 6, 0))
    look_wall = with_(settle, chest=(0, 4, 10), neck=(0, 0, 18), head=(-4, 0, 54))
    to_child = with_(settle, chest=(0, 4, -8), neck=(0, 0, -12), head=(-6, 0, -30))
    snort = with_(to_child, chest=(6, 4, -8), head=(4, 0, -30))
    smug = with_(settle, chest=(-4, 2, 0), head=(-6, 0, -6))
    speared = with_(smug, neck=(-6, 8, 0), head=(-10, 14, 8))
    t1 = tipped(6, "back", (drift_x, 0.0, 0.0))
    teeter = with_(speared, hips=(-6, 3, 0), hips_loc=t1["hips_loc"])
    t2 = tipped(86, "back", (drift_x, 0.0, 0.03))
    timber = with_(t2, spine=(0, 0, 0), chest=(0, 0, 0), neck=(0, 6, 0), head=(-6, 10, 0))
    keys += [(4.2, settle, "ease"), (T + 1.9, sway_r, "ease"), (4.85, sway_l, "ease"), (5.1, settle, "ease"),
             (T + 2.8 + 0.05, look_wall, "snap"), (5.7, look_wall, "ease"), (5.78, to_child, "out"), (T + 3.2, snort, "snap"),
             (6.0, to_child, "ease"), (6.12, snort, "snap"), (6.3, to_child, "ease"), (6.6, smug, "ease"), (6.86, smug, "ease"),
             (T + 4.3, speared, "snap"), (7.1, speared, "settle"), (T + 4.8, teeter, "ease"), (7.75, with_(teeter, hips=(-3, 3, 0)), "ease"),
             (T + 5.6, timber, "in"), (8.3, with_(timber, hips_loc=(drift_x, t2["hips_loc"][1], t2["hips_loc"][2] + 0.05)), "settle"),
             (9.0, timber, "ease")]
    for t, tor, kind in keys:
        a.t(t, kind, **tor)
    hop = legs(a, thigh_L=(-10, 0, 0), shin_L=(24, 0, 0), thigh_R=(-14, 0, 0), shin_R=(28, 0, 0))
    a.legs([(0.0, l0), (3.68, l0), (3.74, hop, "out"), (3.92, l0, "in"), (9.0, l0)])
    for s_ in "LR":
        a.arm(s_, 0.0, bound(s_)).arm(s_, 9.0, bound(s_))
    a.on_top(lambda t: {} if not (T + 3.2 <= t <= 6.4) else merge(
        {"chest": {"rot": (2.5 * pulses(t, T + 3.2, 0.13, 6, 0.8), 0, 0)}}, {"shoulder.L": {"rot": (0, -3.0 * pulses(t, T + 3.2, 0.13, 6, 0.8), 0)}},
        {"shoulder.R": {"rot": (0, 3.0 * pulses(t, T + 3.2, 0.13, 6, 0.8), 0)}}))
    a.f(0.0, "ease", worry=0.7, brows=0.6, lids=1.1).f(2.2, "ease", worry=0.9, lids=1.3, eyes_x=-0.9)
    for i, (t, bone, at) in enumerate(SPEAR_HITS[:5]):
        a.f(t, "snap", lids=0.05, tight=1.0, jaw=0.4 if i != 3 else 0.8, brows=0.8 if i == 3 else 0.2).f(t + 0.15, "ease", lids=1.0, worry=0.8, tight=0.4)
    a.f(4.2, "ease", lids=0.9, worry=0.6, frown=0.4).f(T + 2.85, "snap", lids=1.3, eyes_x=1.0, brows=0.8).f(5.78, "out", lids=1.1, eyes_x=-1.0, brows=0.5)
    a.f(T + 3.2, "snap", smile=0.9, lids=0.6, brows=0.4, eyes_x=-1.0, puff=0.4).f(6.3, "ease", smile=0.8, lids=0.7, eyes_x=-0.8)
    a.f(6.6, "ease", smile=0.6, lids=0.75, brows=-0.2).f(T + 4.3, "snap", lids=1.45, eyes_y=1.0, eyes_x=0.4, jaw=0.3, brows=1.0, smile=0.0)
    a.f(7.4, "ease", lids=1.4, eyes_y=1.0, jaw=0.3).f(T + 5.6, "ease", lids=0.6, eyes_y=0.6)
    clips["exec_spear_victim"] = clip(
        "exec_spear_victim", 9.0, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        hits=[{"t": t, "bone": b, "at": list(p)} for t, b, p in SPEAR_HITS],
        events=[ev(t, "spear_hit", bone=b, at=p) for t, b, p in SPEAR_HITS] + [ev(T + 1.9, "creak"), ev(T + 3.2, "snort"), ev(T + 4.8, "creak"),
                                                                                ev(T + 5.6, "thud")])

    # ---- a thrower: a javelin back over the right shoulder, a step in, the throw,
    #      release at 0.62 (it flies 0.3 s)
    a = Act(1.4, drag=0.5)
    a.arm_drag = 0.0
    carry_t = dict(chest=(-2, 0, -6), head=(0, 0, -4))
    draw_t = dict(hips=(0, 0, -16), hips_loc=(0.0, 0.07, -0.02), spine=(-4, 0, -10), chest=(-8, 0, -24), neck=(0, 0, 14), head=(-4, 0, 22))
    throw_t = dict(hips=(0, 0, 14), hips_loc=(0.0, -0.10, -0.04), spine=(10, 0, 10), chest=(10, 0, 16), neck=(0, 0, -6), head=(-4, 0, -10))
    after_t = dict(hips=(0, 0, 8), hips_loc=(0.0, -0.06, -0.02), spine=(4, 0, 6), chest=(2, 0, 8), head=(-4, 0, -4))
    for t, tor, C, u, fo, kind in ((0.0, carry_t, V(-0.20, -0.02, 1.48), (0.0, -1.0, 0.12), (0.0, -0.2, 1.0), "ease"),
                                   (0.42, draw_t, V(-0.26, 0.26, 1.50), (0.05, -1.0, 0.22), (0.0, -0.3, 1.0), "ease"),
                                   (SPEAR_RELEASE, throw_t, V(-0.12, -0.40, 1.56), (0.0, -1.0, 0.10), (0.0, -0.8, 0.5), "snap"),
                                   (0.9, after_t, V(-0.04, -0.40, 1.15), (0.2, -0.9, -0.3), (0.2, -0.7, -0.6), "ease"),
                                   (1.4, after_t, V(-0.08, -0.30, 1.05), (0.2, -0.9, -0.3), (0.2, -0.7, -0.6), "ease")):
        a.t(t, kind, **tor)
        a.world("R", t, tor, fist("R", C, u, fo, (-0.8, 0.3, -0.5)), kind)
    aim = arm_at("L", w=body_pt(0.16, -0.48, z_chest + 0.08), along=(0.0, -0.95, 0.2), palm=(-0.9, 0.0, -0.3), pole=(0.9, 0.3, -0.3), curl=(10, 4, 0))
    a.rest("L", 0.0).world("L", 0.42, draw_t, aim, "out").rest("L", 1.0, "ease").rest("L", 1.4)
    a.foot("L", 0.0).foot("L", 0.42).foot("L", SPEAR_RELEASE, (0.02, -0.22, 0.0), "snap", lift=0.05).foot("L", 1.4, (0.02, -0.22, 0.0))
    a.f(0.0, "ease", stern=0.5, lids=0.8).f(0.42, "ease", stern=0.9, tight=0.8, lids=0.7, brows=-0.5).f(SPEAR_RELEASE, "snap", jaw=0.5, stern=0.8)
    a.f(1.0, "ease", lids=0.9, stern=0.3)
    clips["exec_spear_throw"] = clip("exec_spear_throw", 1.4, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.2, blend_out=0.4,
                                     props={"R": "spear"}, props_until={"R": SPEAR_RELEASE}, events=[ev(SPEAR_RELEASE, "release", flight=SPEAR_FLIGHT)])

    # ---- the child's throw: the spear in both hands, far too long; a wobble, a
    #      heave that goes nowhere near; both hands over its mouth (release 0.9)
    a = Act(1.8, drag=0.5)
    a.arm_drag = 0.0
    up_t = dict(hips_loc=(0.0, 0.03, 0.0), spine=(-6, 0, 0), chest=(-10, 0, 0), head=(-10, 0, 0))
    wob_t = dict(hips=(0, 8, 0), hips_loc=(0.04, 0.03, 0.0), spine=(-6, 6, 0), chest=(-10, 8, 0), head=(-10, 0, 8))
    wob2_t = dict(hips=(0, -6, 0), hips_loc=(-0.03, 0.03, 0.0), spine=(-6, -5, 0), chest=(-10, -6, 0), head=(-10, 0, -6))
    heave_t = dict(hips=(0, 0, 26), hips_loc=(0.04, -0.12, -0.03), spine=(10, 0, 20), chest=(12, 0, 26), head=(-4, 0, 18))
    oops_t = dict(hips_loc=(0.0, -0.06, 0.0), chest=(4, 0, 0), neck=(4, 0, 0), head=(6, 0, 20))
    for t, tor, C, u, kind in ((0.0, up_t, V(-0.02, -0.14, 1.12), (0.1, -0.5, 0.86), "ease"), (0.3, wob_t, V(0.04, -0.12, 1.14), (0.45, -0.4, 0.8), "ease"),
                               (0.55, wob2_t, V(-0.06, -0.12, 1.12), (-0.3, -0.5, 0.8), "ease"), (0.75, up_t, V(-0.04, -0.06, 1.20), (0.0, -0.3, 0.95), "out"),
                               (0.9, heave_t, V(0.10, -0.34, 1.14), (0.7, -0.5, 0.5), "snap")):
        a.t(t, kind, **tor)
        Cl = Vector(C) - Vector(u).normalized() * (0.13 * k)
        a.world("R", t, tor, fist("R", C, u, (0.0, -0.4, 0.9), (-0.8, 0.3, -0.5)), kind)
        a.world("L", t, tor, fist("L", Cl, u, (0.0, -0.4, 0.9), (0.8, 0.3, -0.5)), kind)
    for s_ in "LR":
        mouth = hand_mouth(s_, cover=True).copy(curl=(20, 12, 8))
        a.arm(s_, 1.2, hang(a, s_, 0, curl=(10, 4, 0)), "ease").arm(s_, 1.45, mouth, "out").arm(s_, 1.8, mouth)
    a.t(1.2, "ease", **oops_t).t(1.45, "out", **with_(oops_t, chest=(8, 0, 0), head=(10, 0, 20))).t(1.8, "ease", **with_(oops_t, chest=(8, 0, 0), head=(10, 0, 20)))
    a.foot("L", 0.0).foot("L", 0.25).foot("L", 0.4, (0.04, 0.0, 0.0), "out", lift=0.03).foot("L", 0.75).foot("L", 0.9, (0.02, -0.18, 0.0), "snap", lift=0.05)
    a.foot("L", 1.8, (0.02, -0.18, 0.0))
    a.f(0.0, "ease", tight=0.7, puff=0.6, lids=0.8).f(0.9, "snap", jaw=0.5, lids=1.2).f(1.2, "ease", lids=1.4, brows=1.0, jaw=0.4, eyes_x=0.8)
    a.f(1.45, "out", lids=1.45, brows=1.0, worry=0.8).f(1.8, "ease", lids=1.45, brows=1.0, worry=0.8)
    clips["child_spear_throw"] = clip("child_spear_throw", 1.8, a, kind="exec", hold=True, tags=["exec", "child", "comic"], bodies=CHILD, blend_in=0.2, blend_out=0.4,
                                      props={"R": "spear"}, props_until={"R": 0.9}, events=[ev(0.9, "release", flight=0.5)])


# =====================================================================================
# 6. Stoned by the court. N: bonks 0 / 0.22 / 0.55, clacks 0.4 / 0.75 / 0.95 /
#    1.1 / 1.32 / 1.6 / 1.95, rustle 3.1, gasp 3.5, bonk 4.4 (official), ow 4.6,
#    punch 5.2, snort 5.8; lead 2.2.
# =====================================================================================

STONE_T0 = 2.2
STONE_RELEASE = 0.45
STONE_FLIGHT = 0.35
STONE_BONKS = [2.2, 2.42, 2.75]
STONE_CLACKS = [2.6, 2.95, 3.15, 3.3, 3.52, 3.8, 4.15]
CAIRN_AT = [0.0, 0.0, 0.12]


def act_stones(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    T = STONE_T0
    lm = landmarks()

    a = Act(9.0, drag=0.6, feet=False, base_pose=square())
    l0 = _legs0(a)
    b1 = dict(spine=(2, 0, 0), chest=(4, 0, 0), neck=(10, 0, 0), head=(16, 0, -6))
    b2 = dict(chest=(2, -10, -8), neck=(0, 0, -6), head=(6, -6, -16))
    b3 = dict(chest=(6, 0, 4), neck=(12, 0, 6), head=(18, 8, 10))
    dizzy_a = dict(neck=(4, 0, 10), head=(6, 10, 16))
    dizzy_b = dict(neck=(4, 0, -10), head=(6, -10, -16))
    cower = with_(KNEEL_UP, hips=(14, 0, 0), spine=(18, 0, 0), chest=(14, 0, 0), neck=(12, 0, 0), head=(16, 0, 0))
    ball = with_(KNEEL_UP, hips=(50, 0, 0), spine=(26, 0, 0), chest=(20, 0, 0), neck=(14, 0, 0), head=(18, 0, 0))
    for t, tor, kind in ((0.0, {}, "ease"), (1.9, dict(chest=(-4, 0, 0), neck=(-6, 0, 0), head=(-12, 0, 0)), "ease"), (STONE_BONKS[0], b1, "snap"),
                         (2.34, {}, "settle"), (STONE_BONKS[1], b2, "snap"), (2.62, {}, "settle"), (STONE_BONKS[2], b3, "snap"), (2.86, dizzy_a, "ease"),
                         (2.98, dizzy_b, "ease"), (3.25, cower, "in"), (3.34, with_(cower, hips_loc=(0, 0.07, -0.40)), "settle"), (3.9, ball, "ease"),
                         (9.0, ball, "ease")):
        a.t(t, kind, **tor)
    a.legs([(0.0, l0), (3.02, l0), (3.25, both_knees(a, lean=14), "in"), (3.9, both_knees(a, lean=50), "ease"), (9.0, both_knees(a, lean=50))])
    for s_ in "LR":
        over = arm_at(s_, w=body_pt(0.10, -0.04, f.z_top / k + 0.02), along=(-0.6, 0.1, -0.2), palm=(0.0, 0.0, -1.0), pole=(0.8, 0.0, 0.4), curl=(30, 20, 10), sh=(0, -10, 0))
        a.rest(s_, 0.0).rest(s_, 2.82).arm(s_, 3.08, over, "out").arm(s_, 9.0 if s_ == "L" else 4.9, over)
    # the right arm comes up out of the top of the cairn, one finger raised; it
    # wags the finger (one moment...), then flops over the side
    sh_r = shoulder_in_hall(a, ball, "R")
    finger = ArmKey(sh_r + Vector((-0.06 * k, -0.03 * k, 0.52 * k)), (-0.9, 0.3, -0.2), (0.0, -0.1, 1.0), (1.0, 0.0, 0.0), curl=(96, -12, 70))
    wag = finger.copy(curl=(96, 26, 70))
    flop = ArmKey(sh_r + Vector((-0.42 * k, -0.06 * k, 0.24 * k)), (-0.3, 0.3, 0.9), (-0.7, 0.0, -0.7), (0.0, 0.0, -1.0), curl=(40, 30, 20))
    a.world("R", 5.0, ball, finger.copy(w=finger.w - Vector((0, 0, 0.30 * k)), curl=(70, 60, 50)), "ease").world("R", T + 3.1, ball, finger, "out")
    a.world("R", 5.9, ball, finger)
    for i, tt in enumerate((6.02, 6.14, 6.26, 6.38)):
        a.world("R", tt, ball, wag if i % 2 == 0 else finger, "snap")
    a.world("R", 7.3, ball, finger).world("R", 7.65, ball, flop, "in").world("R", 9.0, ball, flop)
    a.f(0.0, "ease", worry=0.6, lids=1.1).f(1.9, "ease", worry=0.9, lids=1.35, eyes_y=1.0)
    for tb in STONE_BONKS:
        a.f(tb, "snap", lids=0.0, tight=1.0, jaw=0.4).f(tb + 0.12, "ease", lids=0.8, worry=0.8)
    a.f(2.95, "ease", lids=0.6, eyes_x=0.8, jaw=0.4).f(3.25, "ease", lids=0.0, tight=1.0, worry=1.0).f(9.0, "ease", lids=0.0, tight=1.0, worry=1.0)
    clips["exec_stone_victim"] = clip(
        "exec_stone_victim", 9.0, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        stage={"cairn": CAIRN_AT, "cairn_height": 0.9},
        events=[ev(tb, "bonk", bone="head") for tb in STONE_BONKS]
        + [ev(tc, "cairn", fill=round((i + 1) / len(STONE_CLACKS), 2)) for i, tc in enumerate(STONE_CLACKS)]
        + [ev(T + 3.1, "finger_up", bone="hand.R"), ev(7.65, "finger_flop", bone="hand.R")])

    # ---- a stone from anyone in the room (upper body only: they throw from where
    #      they stand): release 0.45, flies 0.35 s
    a = Act(1.1, drag=0.5)
    a.arm_drag = 0.0
    wind = dict(hips=(0, 0, -10), spine=(-4, 0, -6), chest=(-6, 0, -16), head=(-2, 0, 14))
    throw = dict(hips=(0, 0, 10), hips_loc=(0, -0.05, -0.02), spine=(8, 0, 8), chest=(8, 0, 12), head=(-4, 0, -6))
    for t, tor, C, fo, kind in ((0.0, {}, V(-0.18, -0.24, 1.02), (0.0, -0.3, 1.0), "ease"), (0.3, wind, V(-0.26, 0.16, 1.58), (0.0, 0.3, 1.0), "out"),
                                (STONE_RELEASE, throw, V(-0.10, -0.46, 1.48), (0.0, -0.9, 0.3), "snap"), (0.75, throw, V(-0.04, -0.34, 1.05), (0.0, -0.5, -0.8), "ease"),
                                (1.1, {}, V(-0.14, -0.20, 0.96), (0.0, -0.3, 1.0), "ease")):
        a.t(t, kind, **tor)
        a.world("R", t, tor, fist("R", C, (0.0, -0.2, 0.98), fo, (-0.8, 0.3, -0.5), curl=(80, 70, 40)), kind)
    a.f(0.0, "ease", stern=0.6).f(0.3, "ease", stern=1.0, tight=0.8, brows=-0.6).f(STONE_RELEASE, "snap", jaw=0.4, stern=0.8).f(1.1, "ease", stern=0.4, smile=0.2)
    clips["exec_stone_throw"] = clip("exec_stone_throw", 1.1, a, kind="exec", tags=["exec", "room"], bodies=ADULTS, groups=dict(UPPER), blend_in=0.15, blend_out=0.35,
                                     props={"R": "stone"}, props_until={"R": STONE_RELEASE}, events=[ev(STONE_RELEASE, "release", flight=STONE_FLIGHT)])

    # ---- the child's stone: far too big, heaved up in both hands and let go over
    #      its own head, backwards (onto the official behind); a look ahead for it
    a = Act(1.8, drag=0.5)
    a.arm_drag = 0.0
    lift_t = dict(hips_loc=(0, 0.0, -0.06), spine=(16, 0, 0), chest=(10, 0, 0), head=(10, 0, 0))
    over_t = dict(hips_loc=(0, 0.04, 0.02), spine=(-12, 0, 0), chest=(-18, 0, 0), neck=(-10, 0, 0), head=(-20, 0, 0))
    look_t = dict(chest=(-2, 0, 0), neck=(-4, 0, 8), head=(-8, 0, 14))
    for t, tor, z, y, kind in ((0.0, {}, 0.95, -0.24, "ease"), (0.25, lift_t, 0.84, -0.28, "out"), (0.5, over_t, 1.92, 0.08, "snap"), (0.7, over_t, 1.88, 0.10, "ease"),
                               (1.0, look_t, 1.20, -0.16, "ease"), (1.8, look_t, 1.15, -0.16, "ease")):
        a.t(t, kind, **tor)
        for s_ in "LR":
            hold_ = arm_at(s_, w=body_pt(0.10, y, z), along=(-0.6, -0.2, 0.75), palm=(-0.95, 0.0, 0.2), pole=(0.9, 0.2, -0.4), curl=(40, 30, 10))
            a.world(s_, t, tor, hold_, kind)
    a.f(0.0, "ease", tight=0.8, puff=0.8).f(0.5, "snap", jaw=0.4, lids=1.2).f(1.0, "ease", lids=1.3, brows=0.9, eyes_x=0.6).f(1.8, "ease", lids=1.3, brows=1.0, worry=0.4)
    clips["child_stone_throw"] = clip("child_stone_throw", 1.8, a, kind="exec", hold=True, tags=["exec", "child", "comic"], bodies=CHILD, blend_in=0.2, blend_out=0.4,
                                      props={"L": "stone"}, props_until={"L": 0.5}, events=[ev(0.5, "release", flight=0.6, dir=(0.0, 0.6, -0.8))])

    # ---- bonked: the one the child's stone lands on (the hit at 0.0): a crouch,
    #      both hands to the crown, a rub, then a long glare at the child
    a = Act(2.4, drag=0.6)
    hit = dict(spine=(6, 0, 0), chest=(8, 0, 0), neck=(10, 0, 0), head=(14, 0, 0), hips_loc=(0, 0, -0.03))
    glare = dict(chest=(0, 0, -16), neck=(0, 0, -12), head=(-4, 0, -30))
    a.t(0.0).t(0.06, "snap", **hit).t(0.4, "settle", **with_(hit, head=(8, 0, 0))).t(1.2, "ease", **with_(hit, head=(8, 0, 0))).t(1.5, "out", **glare).t(2.4, "ease", **glare)
    for s_ in "LR":
        rub = arm_at(s_, contact=lm["crown"] + Vector((0.03 * k, 0.0, 0.0)), along=(-0.4, 0.3, 0.85), palm=(-0.3, 0.2, -0.9), pole=(0.9, 0.0, 0.3), curl=(30, 20, 10), reach=0.5)
        a.rest(s_, 0.0).arm(s_, 0.18, rub, "out")
        for i in range(3):
            a.arm(s_, 0.35 + 0.18 * i, rub.copy(w=rub.w + mv(Vector((0.02 * k * (1 if i % 2 == 0 else -1), 0.02 * k, 0)), s_)), "ease")
        if s_ == "R":
            a.arm(s_, 1.2, rub).arm(s_, 2.4, rub)
        else:
            a.rest(s_, 1.3, "ease").rest(s_, 2.4)
    a.f(0.0).f(0.06, "snap", lids=0.0, tight=1.0, jaw=0.5).f(0.4, "ease", lids=0.4, tight=0.8, frown=0.6).f(1.5, "out", stern=1.0, brows=-1.0, lids=0.7, eyes_x=-0.9)
    a.f(2.4, "ease", stern=1.0, brows=-1.0, lids=0.7, eyes_x=-0.9)
    clips["room_bonked"] = clip("room_bonked", 2.4, a, kind="react", hold=False, tags=["exec", "room", "comic"], groups=dict(UPPER), blend_in=0.04, blend_out=0.6,
                                events=[ev(0.0, "bonk"), ev(0.2, "ow")])


# =====================================================================================
# 1. Boulder drop. N: strain -1.6, boulder_roll -1.1, whoosh -0.2, SPLAT 0,
#    rustle 1.8, strain 2.8, boulder_roll 3.0, rip 4.9, squelch 5.0, punch 5.7,
#    rustle 6.3, step_earth 6.8 / 7.3 / 7.8, groan 8.2; lead 3.4. The victim
#    lounges on his back, his head toward M's ledge (its tipping edge just past
#    his head); the boulder lands on his chest.
# =====================================================================================

BOULDER_T0 = 3.4
LEDGE_AT = [0.0, 0.0, -1.62]
BOULDER_LANDS = [0.0, 0.42, -0.70]
BOULDER_OFF = [1.25, 0.42, -0.70]
PUSHERS = ([0.62, 0.0, -2.42], [-0.62, 0.0, -2.42])


def act_boulder(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    T = BOULDER_T0

    a = Act(9.0, drag=0.6, feet=False, base_pose=square())
    l0 = _legs0(a)
    sit = dict(hips=(-12, 0, 0), hips_loc=(0, 0.30, -0.74), spine=(6, 0, 0), chest=(4, 0, 0), head=(4, 0, 0))
    lounge = dict(hips=(-86, 0, 0), hips_loc=(0, 0.33, -0.77), spine=(2, 0, 0), chest=(4, 0, 0), neck=(16, 0, 0), head=(10, 0, 0))
    bob_a = with_(lounge, head=(10, 0, 8))
    bob_b = with_(lounge, head=(10, 0, -6))
    hear = with_(lounge, neck=(10, 0, 0), head=(4, 0, 0))
    look_up = with_(lounge, chest=(-2, 0, 0), neck=(-14, 0, 0), head=(-24, 0, 0))
    cringe = with_(lounge, neck=(18, 0, 0), head=(14, 0, 0))
    flat = dict(hips=(-90, 0, 0), hips_loc=(0, 0.33, -0.82), spine=(0, 0, 0), chest=(0, 0, 0), neck=(-4, 0, 0), head=(-4, 0, 0))
    keys = [(0.0, {}, "ease"), (0.25, dict(chest=(4, 0, 0), head=(4, 0, 0)), "ease"), (0.75, sit, "in"), (0.85, with_(sit, hips_loc=(0, 0.30, -0.75)), "settle"),
            (1.45, lounge, "ease")]
    for i in range(6):
        keys.append((1.75 + 0.22 * i, bob_a if i % 2 == 0 else bob_b, "ease"))
    keys += [(3.0, lounge, "ease"), (3.08, hear, "out"), (3.15, look_up, "snap"), (3.28, cringe, "snap"), (T, flat, "in"), (9.0, flat, "ease")]
    for t, tor, kind in keys:
        a.t(t, kind, **tor)
    sit_legs = legs(a, thigh_L=(-78, 0, -6), shin_L=(84, 0, 0), foot_L=(-6, 0, 0), thigh_R=(-78, 0, 6), shin_R=(84, 0, 0), foot_R=(-6, 0, 0))
    lounge_legs = legs(a, thigh_R=(-48, 0, 4), shin_R=(96, 0, 0), foot_R=(-6, 0, 0), foot_L=(24, 0, 0))
    tap = legs(a, thigh_R=(-48, 0, 4), shin_R=(96, 0, 0), foot_R=(-6, 0, 0), foot_L=(4, 0, 0))
    flat_legs = legs(a, thigh_L=(0, 0, -10), thigh_R=(0, 0, 10), foot_L=(40, 0, 0), foot_R=(40, 0, 0))
    lk = [(0.0, l0), (0.25, l0), (0.75, sit_legs, "in"), (1.45, lounge_legs, "ease")]
    for i in range(6):
        lk.append((1.75 + 0.22 * i, tap if i % 2 == 0 else lounge_legs, "ease"))
    lk += [(3.15, lounge_legs, "ease"), (3.28, legs(a, thigh_R=(-60, 0, 4), shin_R=(80, 0, 0), thigh_L=(-30, 0, 0), shin_L=(20, 0, 0)), "snap"),
           (T, flat_legs, "in"), (9.0, flat_legs)]
    a.legs(lk)
    # arms: on the knees sitting; lounging, the left hand behind the head and the
    # right picking his teeth; up to shield the face; flat out on the floor under
    # the stone; the right forearm lifts and the hand flaps (a feeble wave)
    sh = {s_: shoulder_in_hall(a, flat, s_) for s_ in "LR"}
    for s_ in "LR":
        knee = arm_at(s_, w=body_pt(0.16, -0.36, 0.52), along=(0.0, -0.6, -0.8), palm=(0.0, 0.3, -0.95), pole=(0.9, 0.3, 0.0), curl=(30, 20, 10))
        shield = arm_at(s_, w=body_pt(0.10, -0.30, f.z_shoulder / k + 0.18), along=(-0.6, -0.2, 0.75), palm=(0.0, -0.95, 0.3), pole=(0.9, 0.2, -0.4), curl=(10, 4, 0))
        out_w = sh[s_] + mv(Vector((0.56 * k, -0.08 * k, -0.10 * k)), s_)
        out_w.z = 0.05 * k
        spread = ArmKey(out_w, mv((0.0, 0.0, 1.0), s_), mv((1.0, 0.0, 0.0), s_), mv((0.0, 0.0, -1.0), s_), curl=(14, 8, 4))
        a.rest(s_, 0.0).rest(s_, 0.3).world(s_, 0.8, sit, knee, "ease")
        a.arm(s_, 3.12, shield if s_ == "L" else hand_mouth("R").copy(curl=(80, -10, 60)), "ease").arm(s_, 3.28, shield, "snap").world(s_, T + 0.04, flat, spread, "in")
        if s_ == "L":
            a.arm(s_, 1.45, hand_crown("L"), "ease").arm(s_, 3.12, hand_crown("L")).world(s_, 9.0, flat, spread)
        else:
            pick = hand_mouth("R").copy(curl=(80, -10, 60))
            a.arm(s_, 1.5, pick, "out")
            for i in range(7):
                a.arm(s_, 1.7 + 0.2 * i, pick.copy(w=pick.w + Vector((0.01 * k * (1 if i % 2 == 0 else -1), 0.0, -0.008 * k))), "ease")
            elbow_up = ArmKey(out_w + Vector((0.06 * k, -0.02 * k, 0.24 * k)), (-0.3, 0.0, -1.0), (-0.2, -0.1, 1.0), (0.0, -1.0, 0.0), curl=(10, 4, 0))
            a.world(s_, T + 1.6, flat, spread).world(s_, 5.3, flat, elbow_up, "out")
            for i in range(4):
                sw = 1.0 if i % 2 == 0 else -1.0
                a.world(s_, 5.42 + 0.14 * i, flat, elbow_up.copy(along=Vector((-0.2 + 0.45 * sw, -0.1, 1.0)), palm=Vector((0.0, -1.0, 0.0))), "ease")
            a.world(s_, 6.15, flat, spread, "in").world(s_, 9.0, flat, spread)
    a.f(0.0, "ease", lids=0.85, smile=0.3).f(1.45, "ease", puff=0.5, lids=0.75, eyes_y=0.4, smile=0.2)
    for i in range(6):
        a.f(1.75 + 0.22 * i, "ease", puff=0.6 if i % 2 == 0 else 0.35, lids=0.7, eyes_x=0.4 * (1 if i % 2 == 0 else -1))
    a.f(3.0, "ease", puff=0.3, lids=0.8).f(3.08, "out", lids=1.1, eyes_y=0.6, brows=0.4).f(3.15, "snap", lids=1.45, brows=1.0, jaw=0.75, eyes_y=1.0)
    a.f(3.28, "snap", lids=0.0, tight=1.0, worry=1.0).f(T + 0.1, "ease", lids=0.0, tight=1.0)
    clips["exec_boulder_victim"] = clip(
        "exec_boulder_victim", 9.0, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        stage={"ledge": LEDGE_AT, "boulder_lands": BOULDER_LANDS},
        events=[ev(1.75, "whistle"), ev(T, "splat", bone="chest"), ev(T, "flatten", note="J's flattened look from here"),
                ev(5.3, "hand_wave", bone="hand.R"), ev(T + 4.9, "peel", note="the body is the rug from here: the peeler's hands have it")])

    # ---- the pushers behind the ledge (twins, each turned a little inward): a
    #      look, a nod, spit on the hands, a long strain, it goes and they lurch
    #      after it, a wince at the splat, a hand over the eyes
    for sd, nm in ((1.0, "exec_boulder_push_l"), (-1.0, "exec_boulder_push_r")):
        a = Act(4.6, drag=0.6)
        glance = dict(neck=(0, 0, -10 * sd), head=(-4, 0, -26 * sd))
        nodd = dict(neck=(8, 0, -10 * sd), head=(12, 0, -26 * sd))
        strain = dict(hips=(18, 0, 0), hips_loc=(0, -0.10, -0.06), spine=(16, 0, 0), chest=(10, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0))
        lurch = dict(hips=(26, 0, 0), hips_loc=(0, -0.24, -0.08), spine=(20, 0, 0), chest=(14, 0, 0), neck=(-10, 0, 0), head=(-16, 0, 0))
        wince = dict(chest=(-4, 0, 10 * sd), neck=(6, 0, 12 * sd), head=(10, 0, 30 * sd))
        for t, tor, kind in ((0.0, {}, "ease"), (0.4, glance, "out"), (0.85, nodd, "out"), (1.0, glance, "ease"), (1.3, {}, "ease"), (T - 1.6, strain, "ease"),
                             (2.25, with_(strain, hips_loc=(0, -0.12, -0.07)), "ease"), (T - 1.1, lurch, "out"), (2.7, with_(strain, hips=(8, 0, 0)), "ease"),
                             (3.0, {}, "ease"), (T, wince, "snap"), (3.9, wince, "ease"), (4.25, {}, "ease"), (4.6, {}, "ease")):
            a.t(t, kind, **tor)
        for s_ in "LR":
            rub = arm_at(s_, w=body_pt(0.04, -0.28, z_chest - 0.06), along=(-0.5, -0.5, 0.6), palm=(-0.9, 0.0, -0.3), pole=(0.9, 0.3, -0.4), curl=(10, 4, 0))
            press = arm_at(s_, w=body_pt(0.16, -0.40, z_chest - 0.04), along=(0.0, -0.4, 0.92), palm=(0.0, -1.0, 0.1), pole=(0.9, 0.3, -0.3), curl=(-4, -8, -8))
            ahead = arm_at(s_, w=body_pt(0.18, -0.56, z_chest - 0.10), along=(0.1, -0.8, 0.5), palm=(0.0, -0.9, -0.3), pole=(0.9, 0.3, -0.3), curl=(10, 4, 0))
            a.rest(s_, 0.0)
            if s_ == "R":
                spit = hand_mouth("R").copy(curl=(20, 10, 4))
                a.rest(s_, 0.95).arm(s_, 1.15, spit, "out").arm(s_, 1.28, spit)
            else:
                a.rest(s_, 1.28)
            a.arm(s_, 1.42, rub, "out").arm(s_, 1.6, rub.copy(w=rub.w + Vector((0, 0, 0.03 * k)))).world(s_, T - 1.6, strain, press, "out").world(s_, 2.25, strain, press)
            a.world(s_, T - 1.1, lurch, ahead, "out").rest(s_, 2.9, "ease")
            if s_ == ("L" if sd > 0 else "R"):
                a.arm(s_, T + 0.04, hand_face(s_).copy(curl=(10, 6, 0)), "snap").arm(s_, 3.9, hand_face(s_).copy(curl=(10, 6, 0))).rest(s_, 4.35, "ease")
            a.rest(s_, 4.6)
        a.on_top(lambda t: tremble(t, 1.2 * L.clamp01((t - 1.8) / 0.1) * (1 - L.clamp01((t - 2.28) / 0.05)), 1.3, 0.3))
        a.foot("L", 0.0).foot("L", 1.7).foot("L", 1.8, (0.0, 0.18, 0.0), "out", lift=0.03).foot("L", 2.3, (0.0, 0.18, 0.0)).foot("L", 2.5, (0.0, -0.08, 0.0), "out", lift=0.05)
        a.foot("L", 4.6, (0.0, -0.08, 0.0))
        a.f(0.0, "ease", lids=0.85).f(0.85, "ease", smile=0.4).f(1.2, "ease", puff=0.6).f(1.8, "ease", tight=1.0, puff=1.0, lids=0.3, frown=0.6)
        a.f(2.3, "snap", lids=1.4, jaw=0.5, brows=1.0).f(3.0, "ease", lids=1.1).f(T, "snap", lids=0.0, tight=1.0, frown=0.7).f(3.9, "ease", lids=0.0, tight=0.8)
        a.f(4.25, "ease", lids=0.9, smile=0.2).f(4.6, "ease", lids=0.9)
        clips[nm] = clip(nm, 4.6, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.4, blend_out=0.5,
                         events=[ev(T - 1.6, "strain"), ev(T - 1.1, "boulder_goes")])

    # ---- rolling it off (crouched at its side, both hands on it): a shove at 0.4
    #      (N's strain 2.8 = act 6.2), then a long look down at what is left
    a = Act(2.6, drag=0.6, feet=False)
    crouch = dict(hips=(30, 0, 0), hips_loc=(0, -0.06, -0.24), spine=(16, 0, 0), chest=(10, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0))
    shove = with_(crouch, hips_loc=(0, -0.18, -0.22))
    peer = dict(hips=(20, 0, 0), hips_loc=(0, -0.04, -0.04), spine=(14, 0, 0), chest=(10, 0, 0), neck=(14, 0, 0), head=(26, 0, 0))
    a.t(0.0).t(0.2, "ease", **crouch).t(0.4, "snap", **shove).t(0.7, "ease", **crouch).t(1.1, "ease", **peer).t(2.6, "ease", **peer)
    low = legs(a, thigh_L=(-40, 0, 0), shin_L=(62, 0, 0), foot_L=(-22, 0, 0), thigh_R=(-30, 0, 0), shin_R=(52, 0, 0), foot_R=(-22, 0, 0))
    bent = legs(a, thigh_L=(-20, 0, 0), shin_L=(22, 0, 0), foot_L=(-2, 0, 0), thigh_R=(-20, 0, 0), shin_R=(22, 0, 0), foot_R=(-2, 0, 0))
    a.legs([(0.0, _legs0(a)), (0.2, low, "ease"), (0.7, low), (1.1, bent, "ease"), (2.6, bent)])
    for s_ in "LR":
        press = arm_at(s_, w=body_pt(0.16, -0.46, 0.66), along=(0.0, -0.3, 0.95), palm=(0.0, -1.0, 0.1), pole=(0.9, 0.3, -0.3), curl=(-4, -8, -8))
        on_knee = arm_at(s_, w=body_pt(0.14, -0.28, 0.60), along=(0.0, -0.4, -0.9), palm=(0.0, 0.3, -0.95), pole=(0.9, 0.3, 0.0), curl=(30, 20, 10))
        a.rest(s_, 0.0).world(s_, 0.2, crouch, press, "out").world(s_, 0.4, shove, press.copy(w=press.w + Vector((0, -0.12 * k, 0))), "snap")
        a.world(s_, 0.7, crouch, press).world(s_, 1.1, peer, on_knee, "ease").world(s_, 2.6, peer, on_knee)
    a.f(0.0, "ease", tight=0.8, puff=0.8).f(0.4, "snap", jaw=0.4).f(1.1, "ease", lids=1.1, sneer=0.6, frown=0.5, eyes_y=-0.8)
    a.f(2.6, "ease", lids=1.1, sneer=0.6, frown=0.5, eyes_y=-0.8)
    clips["exec_boulder_rolloff"] = clip("exec_boulder_rolloff", 2.6, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.3, blend_out=0.5,
                                         events=[ev(0.4, "boulder_off")])

    # ---- the peel (from 7.75): bend, pinch the edge, RIP (0.55 = act 8.3), hold it
    #      up dangling and look at it, a shake; roll it up (1.95 = act 9.7, N's
    #      rustle); tuck it under the left arm
    a = Act(2.7, drag=0.5, feet=False)
    bend = dict(hips=(64, 0, 0), hips_loc=(0, 0.08, -0.12), spine=(18, 0, 0), chest=(8, 0, 0), neck=(-10, 0, 0), head=(-12, 0, 0))
    hold_up = dict(chest=(-4, 0, 0), neck=(2, 0, 0), head=(4, 0, 0))
    shake = with_(hold_up, chest=(-4, 0, 6), head=(4, 0, -6))
    roll = dict(hips=(10, 0, 0), spine=(8, 0, 0), chest=(6, 0, 0), neck=(8, 0, 0), head=(16, 0, 0))
    proud = dict(chest=(-6, 0, 4), head=(-6, 0, 10))
    for t, tor, kind in ((0.0, {}, "ease"), (0.28, bend, "ease"), (0.4, bend, "ease"), (0.55, hold_up, "out"), (1.15, hold_up, "ease"), (1.25, shake, "snap"),
                         (1.37, hold_up, "snap"), (1.49, shake, "snap"), (1.62, hold_up, "ease"), (1.9, hold_up, "ease"), (2.05, roll, "ease"),
                         (2.2, with_(roll, chest=(9, 0, 0)), "ease"), (2.35, roll, "ease"), (2.5, proud, "out"), (2.7, proud, "ease")):
        a.t(t, kind, **tor)
    a.legs([(0.0, _legs0(a)), (0.28, legs(a, thigh_L=(-14, 0, 0), shin_L=(20, 0, 0), thigh_R=(-14, 0, 0), shin_R=(20, 0, 0)), "ease"),
            (0.4, legs(a, thigh_L=(-14, 0, 0), shin_L=(20, 0, 0), thigh_R=(-14, 0, 0), shin_R=(20, 0, 0))), (0.6, _legs0(a), "ease"), (2.7, _legs0(a))])
    for s_ in "LR":
        pinch = arm_at(s_, w=body_pt(0.18, -0.58, 0.10), along=(0.0, -0.6, -0.8), palm=(-0.9, 0.0, 0.3), pole=(0.9, 0.3, 0.0), curl=(60, -10, 70))
        up_ = arm_at(s_, w=body_pt(0.22, -0.40, f.z_shoulder / k + 0.06), along=(0.0, -0.5, 0.85), palm=(-0.9, 0.0, 0.2), pole=(0.9, 0.3, -0.4), curl=(60, -10, 70))
        a.rest(s_, 0.0).world(s_, 0.28, bend, pinch, "ease").world(s_, 0.4, bend, pinch).arm(s_, 0.55, up_, "out").arm(s_, 1.9, up_)
        for i in range(3):
            r_ = arm_at(s_, w=body_pt(0.16, -0.32 - 0.04 * (i % 2), f.z_waist / k + 0.02 + 0.05 * (i % 2)), along=(0.0, -0.9, 0.3 if i % 2 == 0 else -0.3),
                        palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.3, -0.4), curl=(60, 50, 30))
            a.arm(s_, 2.05 + 0.15 * i, r_, "ease")
    tuck = fist("L", V(0.22, -0.08, 0.98), (0.0, -1.0, 0.0), (0.0, -0.6, -0.8), (0.9, 0.3, -0.3), curl=(80, 70, 40))
    a.world("L", 2.5, proud, tuck, "out").world("L", 2.7, proud, tuck)
    a.rest("R", 2.55, "ease").rest("R", 2.7)
    a.f(0.0, "ease", lids=0.9).f(0.55, "snap", jaw=0.3, lids=1.2, brows=0.6).f(0.8, "ease", lids=1.1, sneer=0.5, brows=0.4).f(1.25, "ease", lids=1.0, frown=0.3)
    a.f(2.05, "ease", tight=0.4, lids=0.8).f(2.5, "out", smile=0.7, lids=0.8)
    clips["exec_rug_peel"] = clip("exec_rug_peel", 2.7, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.3, blend_out=0.5,
                                  events=[ev(0.55, "rip", hands="LR"), ev(1.95, "roll_up"), ev(2.5, "tucked", hand="L")])

    # ---- walking off with the rolled rug clamped under the left arm (a loop of
    #      two steps a second, in place: the director moves him; N's step_earth)
    tuck_l = arm_solve("L", fist("L", V(0.22, -0.08, 0.98), (0.0, -1.0, 0.0), (0.0, -0.6, -0.8), (0.9, 0.3, -0.3), curl=(80, 70, 40)))

    def carry(t):
        p = cf_anim._walk(t % 1.0, 1.0, 24.0, 52.0, 0.022, head_down=0.0, swing=0.9)
        add(p, "spine", rot=(0, 4, 0))
        add(p, "chest", rot=(0, 4, 0))
        p.update(tuck_l)
        return p
    a = Act(1.0, drag=0.0, feet=False)
    a.t(0.0)
    c = clip("exec_carry_walk", 1.0, a, kind="walk", loop=True, tags=["exec", "executioner"], bodies=ADULTS, speed_mps=0.9, blend_in=0.3, blend_out=0.3,
             events=[ev(0.2, "step"), ev(0.7, "step")])
    c.body = carry
    c.face_fn = lambda t: {"smile": 0.5, "lids": 0.85}
    clips["exec_carry_walk"] = c


# =====================================================================================
# 14. Boiled in the pot. N: pot_plop 0, bubbling 0.3, stir 1.2, sprinkle 2.9,
#     slurp 3.6, sprinkle 5.0, pot_plop 5.8 (the skull), punch 6.3, growl or
#     groan 7.1; lead 2.2. The victim's place is the cauldron's middle; it hangs
#     by the wrists from M's hoist beam (3.2 m) and the executioner holds the
#     rope's end; it sits in on M's body seat (clay 0.36, bronze 0.46).
# =====================================================================================

BOIL_T0 = 2.2
BOIL_COOK = [0.0, 0.0, -0.80]
BOIL_ROPE = [1.15, 0.0, -0.25]


def act_boil(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    T = BOIL_T0
    lm = landmarks()

    a = Act(7.8, drag=0.7, feet=False, base_pose=square())
    l0 = _legs0(a)
    hung = dict(hips_loc=(0, 0.0, 1.05), spine=(-2, 0, 0), chest=(-4, 0, 0), neck=(6, 0, 0), head=(16, 0, 0))
    sit = dict(hips=(-12, 0, 0), hips_loc=(0, 0.04, -0.40), spine=(10, 0, 0), chest=(4, 0, 0), neck=(-4, 0, 0), head=(-6, 0, 0))
    keys = [(0.0, hung, "ease")]
    for i in range(6):
        sw = 1 if i % 2 == 0 else -1
        keys.append((0.25 + 0.27 * i, with_(hung, hips=(0, 0, 12 * sw), head=(16, 0, 12 * sw)), "ease"))
    keys += [(1.85, hung, "ease"), (2.0, with_(hung, hips_loc=(0, 0.0, 0.70)), "in"), (T, with_(sit, hips_loc=(0, 0.04, -0.47)), "in"),
             (2.4, sit, "settle"), (2.9, sit, "ease"), (3.3, sit, "ease")]
    # the cook's big stir (3.4-4.5) carries it round once
    for i in range(5):
        keys.append((3.4 + 0.22 * (i + 1), with_(sit, hips=(-12, 0, 72 * (i + 1)), head=(-8, 0, 10)), "linear" if i < 4 else "out"))
    sit_r = with_(sit, hips=(-12, 0, 360))
    sneeze_in = with_(sit_r, chest=(-6, 0, 0), neck=(-8, 0, 0), head=(-16, 0, 0))
    sneeze = with_(sit_r, spine=(16, 0, 0), chest=(12, 0, 0), neck=(10, 0, 0), head=(16, 0, 0))
    watch = with_(sit_r, neck=(0, 0, 0), head=(-10, 0, 0))
    sunk = with_(sit_r, hips_loc=(0, 0.04, -1.08))
    keys += [(4.6, with_(sit_r, head=(-4, 8, 14)), "ease"), (5.0, sit_r, "ease"), (5.3, sneeze_in, "ease"), (5.5, sneeze_in, "ease"), (5.58, sneeze, "snap"),
             (5.8, sit_r, "ease"), (6.0, watch, "ease"), (6.7, watch, "ease"), (7.4, sunk, "in"), (7.8, sunk, "ease")]
    for t, tor, kind in keys:
        a.t(t, kind, **tor)
    kick_a = legs(a, thigh_L=(-40, 0, 0), shin_L=(60, 0, 0), thigh_R=(-6, 0, 0), shin_R=(10, 0, 0))
    kick_b = legs(a, thigh_R=(-40, 0, 0), shin_R=(60, 0, 0), thigh_L=(-6, 0, 0), shin_L=(10, 0, 0))
    sit_legs = legs(a, thigh_L=(-76, 0, -10), shin_L=(96, 0, 0), thigh_R=(-76, 0, 10), shin_R=(96, 0, 0))
    lk = [(0.0, l0)]
    for i in range(6):
        lk.append((0.2 + 0.27 * i, kick_a if i % 2 == 0 else kick_b, "ease"))
    lk += [(1.85, l0, "ease"), (T, sit_legs, "in"), (7.8, sit_legs)]
    a.legs(lk)
    rim_r = 0.50
    for s_ in "LR":
        tied = arm_at(s_, w=body_pt(0.03, -0.02, f.z_top / k + 0.22), along=(-0.2, 0.0, 0.98), palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.0, -0.3), curl=(60, 50, 30), sh=(0, -16, 0))
        flail = arm_at(s_, w=body_pt(0.40, -0.10, f.z_shoulder / k + 0.25), along=(0.6, -0.2, 0.7), palm=(0.0, -0.9, 0.3), pole=(0.6, 0.3, -0.7), curl=(-6, -10, -10))
        rim = arm_at(s_, w=V(rim_r, -0.06, 0.95), along=(0.6, 0.0, -0.8), palm=(0.0, 0.0, -1.0), pole=(0.9, 0.4, 0.0), curl=(50, 40, 20))
        wheee = arm_at(s_, w=body_pt(0.30, -0.12, f.z_shoulder / k + 0.30), along=(0.4, -0.2, 0.9), palm=(0.0, -1.0, 0.0), pole=(0.6, 0.3, -0.7), curl=(-6, -10, -10))
        a.arm(s_, 0.0, tied).arm(s_, 1.85, tied).arm(s_, T + 0.05, flail, "out").world(s_, 2.45, sit, rim, "ease").world(s_, 3.35, sit, rim)
        a.arm(s_, 3.6, wheee, "out").arm(s_, 4.4, wheee).world(s_, 4.75, sit_r, rim, "ease").world(s_, 5.2, sit_r, rim)
        if s_ == "R":
            a.arm(s_, 5.45, hand_mouth("R", cover=True), "out").arm(s_, 5.62, hand_mouth("R", cover=True)).world(s_, 5.95, sit_r, rim, "ease")
        a.world(s_, 6.9, sit_r, rim).arm(s_, 7.4, tied, "in").arm(s_, 7.8, tied)
    a.f(0.0, "ease", lids=1.4, worry=1.0, jaw=0.5, eyes_y=-0.9).f(1.85, "ease", lids=1.4, worry=1.0, jaw=0.6, eyes_y=-0.9).f(T, "snap", lids=0.0, puff=1.0)
    a.f(2.45, "out", lids=1.4, jaw=0.6, worry=0.9, brows=1.0).f(3.3, "ease", lids=1.3, jaw=0.4, worry=0.8, tight=0.4).f(4.4, "ease", lids=0.5, eyes_x=0.8, jaw=0.3, smile=0.3)
    a.f(4.6, "ease", lids=0.6, smile=0.2).f(5.3, "ease", lids=0.4, jaw=0.4, brows=0.8).f(5.58, "snap", lids=0.0, tight=1.0, jaw=0.2)
    a.f(5.8, "ease", lids=0.8, worry=0.5).f(6.0, "ease", lids=1.0, frown=0.8, stern=0.6, eyes_x=0.0, eyes_y=0.4).f(6.7, "ease", lids=1.0, frown=0.9, stern=0.8)
    a.f(7.1, "ease", lids=1.4, worry=1.0, jaw=0.4).f(7.4, "in", lids=0.0, puff=0.8)
    clips["exec_boil_victim"] = clip(
        "exec_boil_victim", 7.8, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        stage={"cauldron": [0.0, 0.0, 0.0], "rope_top": 3.2, "seat": 0.42},
        events=[ev(1.85, "dropped"), ev(T, "plop", bone="hips"), ev(3.4, "spun"), ev(5.58, "sneeze", bone="head", dir=(0.0, -0.2, 1.0)),
                ev(7.4, "sunk", note="gone under: hide the body; the skull bobs up at 8.0")])

    # ---- the cook behind the cauldron (its middle 0.80 m ahead, rim 0.9-0.96):
    #      the ladle (M's: the bowl 1.0 m along +Y from the grip) stirs round the
    #      victim, never through it; a splash in the face; the big stir that spins
    #      the victim; herbs; a taste; salt; the skull tapped back down twice
    a = Act(10.0, drag=0.8)
    a.arm_drag = 0.0
    ladle_u = (0.05, -0.18, -0.98)
    fo = (0.3, -0.7, -0.4)
    pole = (-0.8, 0.4, -0.4)

    def stir_C(ang, r=0.08, cx=-0.20, cy=-0.38, z=1.30):
        return V(cx + r * math.cos(ang), cy + r * math.sin(ang), z)
    stir_t = dict(spine=(8, 0, 0), chest=(6, 0, 0), neck=(4, 0, 0), head=(12, 0, 0))
    up_t = dict(stir_t, neck=(-6, 0, 0), head=(-20, 0, 0))
    big_t = dict(spine=(12, 0, 4), chest=(10, 0, 6), neck=(6, 0, 0), head=(16, 0, 0), hips_loc=(0, -0.03, -0.02))
    wipe_t = dict(chest=(-6, 0, 0), neck=(-4, 0, 0), head=(-10, 0, 0))
    taste_t = dict(chest=(-4, 0, 0), neck=(-6, 0, 0), head=(-8, 0, 0))
    think_t = dict(chest=(-4, 0, 0), neck=(-6, 0, 4), head=(-14, 6, 10))
    jump_t = dict(stir_t, hips_loc=(0, 0.04, 0.0), chest=(-4, 0, 0), head=(-4, 0, 0))
    plan = []
    t = 0.0
    n = 0
    while t < 10.01:
        if t < 2.15:
            plan.append((t, up_t if 0.45 < t < 1.15 else stir_t, stir_C(n * math.pi / 2)))
        elif t < 3.3:
            plan.append((t, wipe_t if t < 2.85 else stir_t, stir_C(n * math.pi / 2) if t >= 2.85 else None))
        elif t < 4.55:
            plan.append((t, big_t, stir_C(n * math.pi / 2, 0.18, -0.10, -0.30, 1.26)))
        elif t < 5.6:
            plan.append((t, stir_t, stir_C(n * math.pi / 2)))
        elif t < 6.9:
            plan.append((t, taste_t if t < 6.3 else think_t, None))
        elif t < 7.9:
            plan.append((t, stir_t, stir_C(n * math.pi / 2)))
        elif t < 8.7:
            plan.append((t, stir_t, None))
        else:
            plan.append((t, stir_t, stir_C(n * math.pi / 2, 0.06)))
        t = round(t + (0.24 if 3.3 <= t < 4.55 else 0.3), 3)
        n += 1
    for t, tor, C in plan:
        a.t(t, "ease", **tor)
        if C is not None:
            a.world("R", t, tor, fist("R", C, ladle_u, fo, pole), "ease")
    held = stir_C(0.0)
    a.world("R", 2.2, stir_t, fist("R", held, ladle_u, fo, pole)).world("R", 2.85, stir_t, fist("R", held, ladle_u, fo, pole))
    # tasting from the long ladle: the fist low in front, the bowl up at the lips
    taste_u = Vector((0.08, 0.36, 0.93))
    taste_C = V(-0.10, -0.50, 0.62)
    a.world("R", 5.62, taste_t, fist("R", taste_C, taste_u, (0.0, -0.9, 0.3), pole), "out")
    a.world("R", 6.05, taste_t, fist("R", taste_C + V(0.0, 0.02, 0.02), taste_u, (0.0, -0.9, 0.3), pole), "ease")
    a.world("R", 6.6, think_t, fist("R", V(-0.16, -0.36, 1.10), ladle_u, fo, pole), "ease")
    # the skull: a start, then two taps back down
    hold_C = stir_C(0.0)
    tap_hi = V(-0.06, -0.48, 1.42)
    tap_lo = V(-0.04, -0.52, 1.20)
    a.t(8.0, "snap", **jump_t).t(8.2, "ease", **stir_t)
    a.world("R", 7.95, stir_t, fist("R", hold_C, ladle_u, fo, pole), "ease").world("R", 8.12, stir_t, fist("R", tap_hi, ladle_u, fo, pole), "out")
    a.world("R", 8.25, stir_t, fist("R", tap_lo, ladle_u, fo, pole), "in").world("R", 8.37, stir_t, fist("R", tap_hi, ladle_u, fo, pole), "out")
    a.world("R", 8.48, stir_t, fist("R", tap_lo, ladle_u, fo, pole), "in")
    # the left hand: on the hip; wipes the splash off its face; herbs, then salt,
    # from the pouch at its belt, sprinkled over the pot
    hip_l = stance_arm("hip", "L")
    wipe = hand_mouth("L").copy(along=Vector((-0.95, -0.2, 0.2)), palm=Vector((0.0, 1.0, 0.0)), curl=(40, 30, 10))
    wipe2 = wipe.copy(w=wipe.w + Vector((-0.10 * k, 0.0, 0.05 * k)))
    pouch = arm_at("L", w=body_pt(0.22, -0.10, f.z_hip / k + 0.04), along=(0.0, -0.3, -0.95), palm=(-0.9, 0.0, 0.0), pole=(0.9, 0.3, 0.0), curl=(70, 60, 50))
    over = arm_at("L", w=V(0.04, -0.52, 1.32), along=(-0.3, -0.6, -0.4), palm=(0.0, 0.0, -1.0), pole=(0.9, 0.3, -0.3), curl=(70, 60, 50))
    over2 = over.copy(curl=(56, 24, 30), w=over.w + Vector((0.0, -0.02 * k, 0.01 * k)))
    a.arm("L", 0.0, hip_l).arm("L", 2.2, hip_l).arm("L", 2.35, wipe, "out").arm("L", 2.55, wipe2, "ease").arm("L", 2.72, wipe, "ease").arm("L", 2.9, hip_l, "ease")
    for t0, pinches in ((T + 2.9 - 0.3, 2), (T + 5.0 - 0.3, 3)):
        a.arm("L", t0 - 0.25, hip_l).arm("L", t0, pouch, "ease").arm("L", t0 + 0.25, over, "out")
        for i in range(pinches):
            a.arm("L", t0 + 0.37 + 0.12 * i, over2 if i % 2 == 0 else over, "ease")
        a.arm("L", t0 + 0.4 + 0.12 * pinches + 0.25, hip_l, "ease")
    a.arm("L", 10.0, hip_l)
    a.f(0.0, "ease", lids=0.75, smile=0.2).f(0.5, "ease", lids=1.0, eyes_y=0.8).f(1.15, "ease", lids=0.75, smile=0.2).f(T, "snap", lids=0.0, puff=0.6)
    a.f(2.45, "ease", lids=0.3, tight=0.5).f(2.9, "ease", lids=0.75, smile=0.1).f(5.1, "ease", lids=0.8, smile=0.3)
    a.f(T + 3.6, "snap", puff=0.8, lids=0.4).f(6.1, "ease", jaw=0.2, lids=0.9, eyes_y=0.8, brows=0.4).f(6.4, "ease", jaw=0.0, lids=0.9, eyes_y=0.8, smile=0.2)
    a.f(6.75, "ease", lids=0.8, smile=0.5).f(7.2, "ease", lids=0.8, smile=0.3).f(8.0, "snap", lids=1.25, brows=0.6).f(8.5, "ease", lids=0.8, smile=0.3, stern=0.3)
    a.f(10.0, "ease", lids=0.8, smile=0.3)
    clips["exec_cook_boil"] = clip("exec_cook_boil", 10.0, a, kind="exec", hold=True, tags=["exec", "cook"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
                                   props={"R": "ladle"}, stage={"cauldron": [0.0, 0.0, 0.80]},
                                   events=[ev(T, "splash_face"), ev(T + 1.2, "stir_big"), ev(T + 2.9, "sprinkle", hand="L"), ev(T + 3.6, "slurp"),
                                           ev(T + 5.0, "sprinkle", hand="L"), ev(8.0, "start"), ev(8.25, "tap"), ev(8.48, "tap")])

    # ---- the rope man (at the hoist's post, facing the cauldron): leaning back on
    #      the rope against the weight; lets go at 1.85; dusts off his hands
    a = Act(3.6, drag=0.6)
    lean_t = dict(hips_loc=(0, 0.08, -0.06), spine=(-8, 0, 0), chest=(-10, 0, 0), neck=(4, 0, 0), head=(-8, 0, 0))
    free_t = dict(hips_loc=(0, 0.02, 0.0), chest=(-4, 0, 0), head=(-10, 0, 0))
    a.t(0.0, "ease", **lean_t).t(1.75, "ease", **with_(lean_t, chest=(-12, 0, 0))).t(1.85, "snap", **free_t).t(2.4, "ease", chest=(0, 0, 0), head=(4, 0, -10))
    a.t(3.6, "ease")
    for s_, z in (("R", 1.50), ("L", 1.24)):
        g = fist(s_, V(0.0 if s_ == "R" else 0.02, -0.30, z), (0.0, -0.3, 0.95), (0.0, -0.6, 0.2), (0.9 if s_ == "L" else -0.9, 0.3, -0.5), curl=(90, 80, 40))
        opened = arm_at(s_, w=body_pt(0.26, -0.24, f.z_shoulder / k + 0.18), along=(0.5, -0.3, 0.8), palm=(0.0, -1.0, 0.0), pole=(0.8, 0.3, -0.5), curl=(-6, -12, -12))
        dust = arm_at(s_, w=body_pt(0.10, -0.28, z_chest - 0.10), along=(-0.4, -0.5, 0.75), palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.3, -0.6), curl=(4, -4, -6))
        dust_in = dust.copy(w=dust.w + mv(Vector((-0.10 * k, 0.0, 0.03 * k)), s_))
        a.world(s_, 0.0, lean_t, g).world(s_, 1.8, lean_t, g).arm(s_, 1.95, opened, "snap").arm(s_, 2.5, dust, "ease")
        for i in range(4):
            a.arm(s_, 2.62 + 0.12 * i, dust_in if i % 2 == 0 else dust, "ease")
        a.rest(s_, 3.4, "ease").rest(s_, 3.6)
    a.foot("L", 0.0, (0.0, -0.15, 0.0)).foot("L", 1.85, (0.0, -0.15, 0.0)).foot("L", 2.05, (0.0, 0.0, 0.0), "out", lift=0.04)
    a.f(0.0, "ease", tight=0.7, puff=0.5).f(1.85, "snap", lids=1.3, brows=0.6).f(2.4, "ease", smile=0.4, lids=0.85)
    clips["exec_rope_release"] = clip("exec_rope_release", 3.6, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.3, blend_out=0.5,
                                      events=[ev(1.85, "let_go")])


# =====================================================================================
# 16. Volley of arrows. N: volley 0, volley 1.0, arrow_thunk 3.3, bonk 3.42 (the
#     hat), rustle 3.5, punch 4.1, snort 4.7; lead 2.4 (asked of N: a
#     faint_thump at 5.0, the fall). The archers stand off its left front.
# =====================================================================================

ARROW_T0 = 2.4
ARROW_FLIGHT = 0.08
ARROW_HITS = [(2.40, "chest", (0.08, 1.32, 0.12)), (2.43, "hips", (0.12, 0.98, 0.10)), (2.47, "thigh.L", (0.10, 0.72, 0.08)),
              (2.52, "upper_arm.L", (0.20, 1.38, 0.04)), (2.58, "chest", (-0.06, 1.25, 0.13)), (2.63, "thigh.R", (-0.06, 0.66, 0.09)),
              (3.40, "spine", (0.02, 1.12, 0.14)), (3.44, "chest", (0.14, 1.40, 0.10)), (3.49, "forearm.L", (0.22, 1.02, 0.06)),
              (3.55, "shin.L", (0.09, 0.40, 0.07)), (3.62, "hips", (-0.10, 0.94, 0.12))]
ARROW_HAT_T = 5.7
ARROW_FALL_T = 7.4


def act_arrows(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    T = ARROW_T0

    a = Act(8.2, drag=0.6, feet=False, base_pose=square())
    l0 = _legs0(a)
    keys = [(0.0, {}, "ease"), (2.2, dict(neck=(0, 0, 8), head=(-4, 0, 16)), "ease")]
    for i, (t, b, p) in enumerate(ARROW_HITS):
        sgn = 1.0 if i % 2 == 0 else -1.0
        keys.append((t, dict(hips_loc=(-0.006 * (i + 1), 0.010 * (i + 1), 0.0), chest=(-4, -6 * sgn, -4 * sgn), neck=(0, 0, 4 * sgn), head=(-6, 0, 8 * sgn)), "snap"))
    stand = dict(hips_loc=(-0.07, 0.11, 0.0), chest=(-2, 0, 0), head=(-2, 0, 0))
    look_down = with_(stand, neck=(10, 0, 0), head=(24, 0, 0))
    look_l = with_(look_down, head=(24, 0, 22))
    look_r = with_(look_down, head=(24, 0, -22))
    to_captain = with_(stand, neck=(0, 0, 10), head=(-4, 0, 26))
    duck = with_(stand, neck=(10, 0, 0), head=(14, 0, 0), hips_loc=(-0.07, 0.11, -0.03))
    follow = with_(stand, chest=(-6, 0, 0), neck=(-12, 0, 0), head=(-26, 0, -14))
    sigh_ = with_(stand, chest=(6, 0, 0), neck=(6, 0, 0), head=(8, 0, 0))
    t2 = tipped(86, "back", (-0.07, 0.11, 0.03))
    timber = with_(t2, head=(-6, 0, 0))
    keys += [(3.0, stand, "settle"), (3.75, stand, "settle"), (4.1, look_down, "ease"), (4.45, look_l, "ease"), (4.85, look_r, "ease"), (5.15, stand, "ease"),
             (5.35, to_captain, "out"), (ARROW_HAT_T - 0.04, to_captain, "ease"), (ARROW_HAT_T + 0.04, duck, "snap"), (6.05, follow, "out"),
             (6.35, follow, "ease"), (6.75, sigh_, "ease"), (6.95, sigh_, "ease"), (ARROW_FALL_T, timber, "in"),
             (7.52, with_(timber, hips_loc=(t2["hips_loc"][0], t2["hips_loc"][1], t2["hips_loc"][2] + 0.03)), "settle"), (8.2, timber, "ease")]
    for t, tor, kind in keys:
        a.t(t, kind, **tor)
    a.legs([(0.0, l0), (8.2, l0)])
    for s_ in "LR":
        a.arm(s_, 0.0, bound(s_)).arm(s_, 8.2, bound(s_))
    a.f(0.0, "ease", worry=0.7, lids=1.1).f(2.2, "ease", lids=1.3, worry=0.9, eyes_x=0.8)
    for t in (2.40, 2.52, 2.63, 3.40, 3.55, 3.62):
        a.f(t, "snap", lids=0.0, tight=1.0, jaw=0.3).f(t + 0.08, "ease", lids=0.3, tight=0.8)
    a.f(4.1, "ease", lids=1.3, brows=0.9, eyes_y=-1.0).f(5.15, "ease", lids=1.1, brows=0.6).f(5.35, "out", lids=1.3, brows=0.9, eyes_x=0.9)
    a.f(ARROW_HAT_T, "snap", lids=0.0, tight=1.0).f(6.05, "out", lids=1.35, eyes_y=1.0, jaw=0.3).f(6.75, "ease", lids=0.7, puff=0.6, worry=0.5)
    a.f(6.95, "ease", lids=0.6, smile=0.2, puff=0.0).f(ARROW_FALL_T, "ease", lids=0.4)
    clips["exec_arrow_victim"] = clip(
        "exec_arrow_victim", 8.2, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        hits=[{"t": t, "bone": b, "at": list(p)} for t, b, p in ARROW_HITS],
        events=[ev(t, "arrow_hit", bone=b, at=p) for t, b, p in ARROW_HITS]
        + [ev(ARROW_HAT_T, "hat_off", bone="head", dir=(-0.3, 0.6, -0.75)), ev(6.75, "sigh"), ev(ARROW_FALL_T, "thud")])

    def archer(name, looses, length, captain=False):
        """The bow in the left fist, its stave up the thumb side (M's bow: +Y up
        the stave, the string behind); the right hand draws to the jaw."""
        a = Act(length, drag=0.5)
        a.arm_drag = 0.0
        ready = {}
        aim = dict(hips=(0, 0, -20), spine=(0, 0, -10), chest=(-2, 0, -40), neck=(0, 0, 20), head=(4, 0, 34))
        bow_low = fist("L", V(0.22, -0.20, 0.95), (0.0, -0.3, 0.95), (0.2, -0.6, -0.6), (0.9, 0.3, -0.3))
        bow_up = fist("L", V(0.40, -0.44, 1.42), (0.0, 0.0, 1.0), (0.8, -0.6, 0.0), (0.9, 0.3, -0.3))
        string = arm_at("R", w=V(-0.30, -0.36, 1.42), along=(0.8, -0.5, 0.0), palm=(0.0, 0.0, -1.0), pole=(-0.6, 0.6, -0.3), curl=(60, 70, 10))
        drawn = arm_at("R", w=V(0.04, -0.12, 1.52), along=(0.8, -0.5, 0.0), palm=(0.0, 0.0, -1.0), pole=(-0.6, 0.8, 0.0), curl=(60, 70, 10))
        loosed = arm_at("R", w=V(0.14, 0.04, 1.56), along=(0.6, -0.3, 0.2), palm=(0.0, 0.0, -1.0), pole=(-0.6, 0.8, 0.0), curl=(-6, -12, -12))
        quiver = arm_at("R", w=V(0.14, 0.12, 1.62), along=(0.0, 0.3, 0.95), palm=(0.9, 0.0, 0.0), pole=(-0.8, 0.4, -0.3), curl=(50, 40, 20))
        first = looses[0]
        a.t(0.0, "ease", **ready).world("L", 0.0, ready, bow_low).rest("R", 0.0)
        a.t(first - 0.85, "ease", **ready).world("L", first - 0.85, ready, bow_low).rest("R", first - 0.85)
        for i, tl in enumerate(looses):
            long_aim = captain and i == len(looses) - 1
            draw_t = tl - (1.1 if long_aim else 0.42)
            a.t(draw_t - 0.25, "ease", **aim).world("L", draw_t - 0.25, aim, bow_up, "out")
            a.world("R", draw_t - 0.25, aim, string, "out").world("R", draw_t, aim, drawn, "ease")
            if long_aim:
                # the long comic aim: the head cocks one way and the other, the bow
                # nudged up, down, up, the tongue in the cheek (puff)
                for j, jt in enumerate((draw_t + 0.25, draw_t + 0.5, draw_t + 0.75)):
                    cock = 1 if j % 2 == 0 else -1
                    jt_aim = with_(aim, neck=(0, 0, 20 + 4 * cock), head=(4, 6 * cock, 34 + 5 * cock))
                    a.t(jt, "ease", **jt_aim)
                    a.world("L", jt, jt_aim, bow_up.copy(w=bow_up.w + Vector((0, 0, 0.015 * cock * k))), "ease")
                    a.world("R", jt, jt_aim, drawn)
            a.t(tl, "ease", **aim).world("R", tl - 0.02, aim, drawn).world("R", tl + 0.06, aim, loosed, "snap").world("L", tl, aim, bow_up)
            if i < len(looses) - 1:
                a.world("R", tl + 0.3, aim, quiver, "ease").world("R", tl + 0.48, aim, quiver)
        last = looses[-1]
        a.t(last + 0.6, "ease", **ready).world("L", last + 0.6, ready, bow_low, "ease").rest("R", last + 0.6, "ease")
        a.t(length, "ease", **ready).world("L", length, ready, bow_low).rest("R", length)
        a.f(0.0, "ease", lids=0.85, stern=0.3)
        for i, tl in enumerate(looses):
            a.f(tl - 0.4, "ease", lids=0.5, stern=0.8, tight=0.4).f(tl + 0.1, "snap", lids=0.9, stern=0.3)
        if captain:
            a.f(last - 1.0, "ease", lids=0.3, tight=0.6, puff=0.5).f(last - 0.3, "ease", lids=0.25, tight=0.8, puff=0.8)
            a.f(last + 0.3, "out", smile=1.0, lids=0.9, brows=0.6).f(length, "ease", smile=0.8, lids=0.9)
        a.foot("L", 0.0).foot("L", first - 0.95).foot("L", first - 0.75, (0.10, -0.12, 0.0), "out", lift=0.04).foot("L", length, (0.10, -0.12, 0.0))
        clips[name] = clip(name, length, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.3, blend_out=0.5,
                           props={"L": "bow"}, events=[ev(tl, "loose", flight=ARROW_FLIGHT) for tl in looses])
    archer("exec_archer", [T - ARROW_FLIGHT, T + 1.0 - ARROW_FLIGHT], 4.2)
    archer("exec_archer_captain", [ARROW_HAT_T - ARROW_FLIGHT], 6.4, captain=True)


# =====================================================================================
# 15. The stake. N: heave -1.2, strain -0.6, squelch 0, slow_squelch 0.5,
#     scribble 1.1 / 2.7 (scribe), punch 4.0, ahem 4.7 (scribe); lead 2.6. M's
#     stake stands just behind the victim's place; its top is set at 1.85 m (M's
#     is 2.68: sink or scale it); the two hoisters lift the victim by the seat,
#     carry it back over the tip and set it down; it slides to the standing
#     scribe's eye level, its toes just reaching the floor.
# =====================================================================================

STAKE_T0 = 2.6
STAKE_AT = [0.0, 0.0, -0.35]
STAKE_TOP = 1.85
HOISTERS = ([0.42, 0.0, -0.18], [-0.42, 0.0, -0.18])
SCRIBE_AT = [-0.80, 0.0, 0.45]


def act_stake(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    T = STAKE_T0
    back = -STAKE_AT[2]                                   # how far back the stake is (Blender +y)
    pz = f.pelvis.z / k                                   # the pelvis at rest (1.72 m units)
    held_z = STAKE_TOP + 0.13 - pz                        # held just over the tip
    perch_z = STAKE_TOP + 0.07 - pz                       # set down on it
    end_z = 0.02                                          # toes on the floor

    a = Act(8.0, drag=0.7, feet=False, base_pose=square())
    l0 = _legs0(a)
    look_back = dict(chest=(-2, 0, 10), neck=(0, 0, 14), head=(-4, 0, 40))
    gulp = dict(chest=(2, 0, 0), neck=(6, 0, 0), head=(8, 0, 0))
    grabbed = dict(hips_loc=(0, 0.02, 0.05), chest=(-6, 0, 0), head=(-8, 0, 0))
    rising = dict(hips=(-10, 0, 0), hips_loc=(0, 0.10, 0.45), spine=(4, 0, 0), chest=(0, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0))
    held = dict(hips=(-12, 0, 0), hips_loc=(0, back, held_z), spine=(4, 0, 0), chest=(0, 0, 0), neck=(10, 0, 0), head=(26, 0, 0))
    perch = dict(hips=(-6, 0, 0), hips_loc=(0, back, perch_z), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(-8, 0, 0), head=(-14, 0, 0))
    wob_a = with_(perch, hips=(-6, 7, 0), chest=(-10, 8, 0))
    wob_b = with_(perch, hips=(-6, -7, 0), chest=(-10, -8, 0))
    seat = dict(hips=(-4, 0, 0), hips_loc=(0, back, perch_z), spine=(2, 0, 0), chest=(0, 0, 0), neck=(0, 0, 0), head=(-4, 0, 0))
    keys = [(0.0, {}, "ease"), (0.35, look_back, "out"), (0.8, look_back, "ease"), (0.95, gulp, "ease"), (T - 1.2, grabbed, "snap"), (1.55, grabbed, "ease"),
            (2.15, rising, "ease"), (T - 0.4, held, "out"), (2.5, with_(held, hips_loc=(0, back, held_z + 0.01)), "ease"), (T, perch, "snap"),
            (2.75, wob_a, "ease"), (2.9, wob_b, "ease"), (3.05, seat, "ease")]
    # the slide: four slips down (in), each caught; the last puts its toes on the floor
    z = perch_z
    steps = [(T + 0.5, 0.48, 0.30), (3.95, 0.45, 0.32), (4.75, 0.5, 0.30), (5.55, 0.32, perch_z - end_z - 0.92)]
    for t0, dur, dz in steps:
        keys.append((t0, with_(seat, hips_loc=(0, back, z)), "ease"))
        z -= dz
        keys.append((t0 + dur, with_(seat, hips_loc=(0, back, z), head=(6, 0, 4)), "in"))
        keys.append((t0 + dur + 0.1, with_(seat, hips_loc=(0, back, z + 0.012)), "settle"))
    phew = with_(seat, hips_loc=(0, back, end_z), chest=(4, 0, 0), neck=(4, 0, 0), head=(6, 0, 0))
    peek = with_(seat, hips_loc=(0, back, end_z), spine=(6, -4, -10), chest=(8, -6, -16), neck=(4, 0, -12), head=(12, 0, -30))
    away = with_(seat, hips_loc=(0, back, end_z), chest=(-4, 0, 4), neck=(-4, 0, 8), head=(-10, 0, 26))
    keys += [(6.1, phew, "ease"), (6.35, phew, "ease"), (6.75, peek, "ease"), (T + 4.7 - 0.05, peek, "ease"), (T + 4.7 + 0.12, away, "snap"), (8.0, away, "ease")]
    keys.sort(key=lambda kk: kk[0])
    for t, tor, kind in keys:
        a.t(t, kind, **tor)
    toes = legs(a, foot_L=(30, 0, 0), foot_R=(30, 0, 0))
    tuck = legs(a, thigh_L=(-60, 0, -6), shin_L=(80, 0, 0), thigh_R=(-60, 0, 6), shin_R=(80, 0, 0), foot_L=(10, 0, 0), foot_R=(10, 0, 0))
    kick_a = legs(a, thigh_L=(-30, 0, 0), shin_L=(30, 0, 0), thigh_R=(-60, 0, 0), shin_R=(90, 0, 0), foot_L=(20, 0, 0), foot_R=(10, 0, 0))
    kick_b = legs(a, thigh_L=(-60, 0, 0), shin_L=(90, 0, 0), thigh_R=(-30, 0, 0), shin_R=(30, 0, 0), foot_L=(10, 0, 0), foot_R=(20, 0, 0))
    dangle = legs(a, thigh_L=(-26, 0, -4), shin_L=(30, 0, 0), thigh_R=(-26, 0, 4), shin_R=(30, 0, 0), foot_L=(30, 0, 0), foot_R=(30, 0, 0))
    straight = legs(a, thigh_L=(-6, 0, -3), shin_L=(4, 0, 0), thigh_R=(-6, 0, 3), shin_R=(4, 0, 0), foot_L=(48, 0, 0), foot_R=(48, 0, 0))
    a.legs([(0.0, l0), (T - 1.25, l0), (T - 1.2, toes, "snap"), (1.55, toes), (1.85, tuck, "ease"), (2.05, kick_a, "ease"), (2.25, kick_b, "ease"),
            (2.45, tuck, "ease"), (T, dangle, "snap"), (5.55, dangle), (5.87, straight, "in"), (8.0, straight)])
    for s_ in "LR":
        flap = arm_at(s_, w=body_pt(0.42, -0.06, f.z_shoulder / k + 0.06), along=(0.9, -0.2, 0.4), palm=(0.0, -0.4, -0.9), pole=(0.5, 0.5, -0.7), curl=(10, 4, 0), sh=(0, -10, 0))
        yikes = arm_at(s_, w=body_pt(0.34, -0.10, f.z_shoulder / k + 0.40), along=(0.4, -0.2, 0.9), palm=(0.0, -1.0, 0.0), pole=(0.8, 0.3, -0.5), curl=(-8, -14, -14), sh=(0, -14, 0))
        balance = arm_at(s_, w=body_pt(0.56, -0.08, f.z_shoulder / k - 0.02), along=(0.95, -0.2, 0.1), palm=(0.0, -0.3, -0.95), pole=(0.4, 0.6, -0.6), curl=(4, -4, -6))
        a.rest(s_, 0.0).rest(s_, T - 1.25).arm(s_, T - 1.15, flap, "snap").arm(s_, 2.45, flap).arm(s_, T + 0.05, yikes, "snap").arm(s_, 2.95, yikes)
        a.arm(s_, 3.3, balance, "ease").arm(s_, 5.8, balance).arm(s_, 6.2, hang(a, s_, 4, curl=(24, 14, 6)), "ease").arm(s_, 8.0, hang(a, s_, 4, curl=(24, 14, 6)))
    a.f(0.0, "ease", worry=0.8, lids=1.1).f(0.35, "out", lids=1.35, eyes_x=0.9, brows=0.8).f(0.95, "ease", lids=1.2, puff=0.4, worry=1.0)
    a.f(T - 1.2, "snap", lids=1.45, jaw=0.5, brows=1.0).f(2.4, "ease", lids=1.45, eyes_y=-1.0, jaw=0.4, worry=1.0)
    a.f(T, "snap", lids=1.45, jaw=0.8, brows=1.0, eyes_y=0.6).f(3.2, "ease", lids=1.3, jaw=0.5, brows=0.9)
    for t0, dur, dz in steps:
        a.f(t0 + dur, "snap", lids=1.4, jaw=0.4, brows=1.0).f(t0 + dur + 0.25, "ease", lids=0.9, tight=0.6, worry=0.6)
    a.f(6.1, "ease", lids=0.7, smile=0.5, puff=0.6).f(6.4, "ease", lids=0.9, smile=0.3).f(6.75, "ease", lids=1.1, eyes_x=-0.8, eyes_y=-0.4, brows=0.5)
    a.f(T + 4.7 + 0.12, "snap", lids=1.0, eyes_x=0.9, eyes_y=0.5, smile=0.3, puff=0.5).f(8.0, "ease", lids=1.0, eyes_x=0.9, eyes_y=0.5, smile=0.3, puff=0.5)
    clips["exec_stake_victim"] = clip(
        "exec_stake_victim", 8.0, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        stage={"stake": STAKE_AT, "top": STAKE_TOP},
        events=[ev(T - 1.2, "grabbed"), ev(T, "squelch", bone="hips"), ev(T + 0.5, "slide")] + [ev(t0 + dur, "slip") for t0, dur, dz in steps]
        + [ev(5.87, "toes_down"), ev(6.75, "peek"), ev(T + 4.7 + 0.12, "look_away")])

    # ---- the hoisters, one each side, facing the victim: crouch and take it under
    #      the seat, heave (1.4), up overhead and back over the tip, on their toes,
    #      set it down (2.6), step out, dust off their hands
    for sd, nm, at in ((1.0, "exec_stake_hoist_l", HOISTERS[0]), (-1.0, "exec_stake_hoist_r", HOISTERS[1])):
        yaw = -90.0 * sd
        a = Act(4.4, drag=0.6)
        a.arm_drag = 0.0
        crouch_t = dict(hips=(24, 0, 0), hips_loc=(0, 0.04, -0.20), spine=(14, 0, 0), chest=(8, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0))
        mid_t = dict(hips=(6, 0, 0), hips_loc=(0, 0.0, -0.06), spine=(0, 0, 0), chest=(-4, 0, 0), neck=(-6, 0, 0), head=(-12, 0, 0))
        up_t = dict(hips_loc=(0, 0.0, 0.05), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(-8, 0, 0), head=(-18, 0, 0))
        set_t = dict(hips_loc=(0, 0.0, 0.0), spine=(-4, 0, 0), chest=(-6, 0, 0), head=(-12, 0, 0))
        out_t = dict(chest=(-2, 0, 0), head=(-4, 0, 0))
        nod_t = dict(neck=(8, 0, 0), head=(12, 0, 0))
        for t, tor, kind in ((0.0, {}, "ease"), (0.45, nod_t, "out"), (0.7, {}, "ease"), (1.0, crouch_t, "ease"), (T - 1.2, crouch_t, "ease"),
                             (2.0, mid_t, "out"), (T - 0.4, up_t, "out"), (2.5, up_t, "ease"), (T, set_t, "in"), (3.0, out_t, "ease"), (4.4, out_t, "ease")):
            a.t(t, kind, **tor)
        # under the victim's seat at each moment (the act's frame, Godot), a hand
        # either side of the hoister's own reach
        for t, tor, hl, kind in ((1.0, crouch_t, (0, 0.0, 0.0), "ease"), (T - 1.2, crouch_t, (0, 0.02, 0.05), "ease"), (2.0, mid_t, (0, 0.10, 0.45), "out"),
                                 (T - 0.4, up_t, (0, back, held_z), "out"), (2.5, up_t, (0, back, held_z + 0.01), "ease"), (T, set_t, (0, back, perch_z), "in")):
            seat_z = pz + hl[2] - 0.10
            for s_, dz_ in (("L", 0.06 * sd), ("R", -0.08 * sd)):
                P = (0.10 * sd, seat_z, -hl[1] - 0.02 + dz_)
                W = in_role(P, at, yaw)
                key = ArmKey(W, mv((0.9, 0.2, -0.5), s_), (0.0, -0.4, 0.92), mv((0.0, -0.3, 0.95), s_), curl=(40, 30, 10))
                a.world(s_, t, tor, key, kind)
        for s_ in "LR":
            dust = arm_at(s_, w=body_pt(0.10, -0.28, z_chest - 0.10), along=(-0.4, -0.5, 0.75), palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.3, -0.6), curl=(4, -4, -6))
            dust_in = dust.copy(w=dust.w + mv(Vector((-0.10 * k, 0.0, 0.03 * k)), s_))
            a.rest(s_, 0.0).rest(s_, 0.7).arm(s_, 3.05, dust, "ease")
            for i in range(4):
                a.arm(s_, 3.17 + 0.12 * i, dust_in if i % 2 == 0 else dust, "ease")
            a.rest(s_, 4.0, "ease").rest(s_, 4.4)
        a.on_top(lambda t: tremble(t, 1.1 * L.clamp01((t - 1.5) / 0.1) * (1 - L.clamp01((t - 2.55) / 0.08)), 1.2, 0.4))
        for s_ in "LR":
            a.foot(s_, 0.0).foot(s_, 1.95).foot(s_, T - 0.4, (0, 0, 0.05), "out", rot=(32, 0, 0)).foot(s_, 2.5, (0, 0, 0.05), rot=(32, 0, 0))
            a.foot(s_, T, (0, 0, 0), "in").foot(s_, 2.9, (0, 0.20, 0), "out", lift=0.04).foot(s_, 4.4, (0, 0.20, 0))
        a.f(0.0, "ease", stern=0.6, lids=0.85).f(0.45, "ease", smile=0.3).f(T - 1.2, "ease", tight=1.0, puff=0.9, lids=0.3).f(T, "ease", tight=0.4, lids=0.8)
        a.f(3.1, "ease", smile=0.6, lids=0.85).f(4.4, "ease", smile=0.5)
        clips[nm] = clip(nm, 4.4, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.4, blend_out=0.5,
                         events=[ev(T - 1.2, "heave"), ev(T - 0.6, "strain"), ev(T, "set_down"), ev(3.17, "dust")])
