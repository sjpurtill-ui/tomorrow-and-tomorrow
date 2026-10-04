"""Court acting (K): executions, played as cartoon slapstick (the user's call,
court_night/EXECUTIONS.md). Comic timing first: the wind-up, the hit, a beat,
then the punchline. Bright and silly, never lingering on suffering.

Every clip here is one role of one act, all of an act's clips starting at the
act's time 0 (the director starts them together). Each carries:
  events  [{t, name, ...}]: when the stage, sound, blood and body parts act:
          "split" (J swaps in the pre-split body; part, bone), "spray" and
          "geyser" (M's blood; bone, dir), "impact", "thunk", "clang", "plop",
          "thud", "tap", "whoosh", "grab", "slip"... dir is in the figure's own
          frame as Godot holds it (x its left, y up, z its front).
  props   {"R": prop}: the prop a fist holds; it is drawn at the fist
          (court_acting.gd fist_frame: origin in the curled fingers, +Y out of
          the thumb side along the handle to the head, +Z where the knuckles
          point, the blade's edge).
  stage   where the act's fixed things stand for a 1.72 m body, in this
          figure's frame (Godot axes): the block, the pot.
Positions of the other roles and the flight of parts are in court_acting.gd
EXEC_PLANS (the director reads them; this file only writes the clips).
"""
import math
from mathutils import Vector

import cf_anim
from cf_anim import add, both, side, merge, wave
import court_anims_lib as L
from court_anims_lib import ArmKey, arm_at, arm_fk, arm_solve, legs_fk, plant, tremble, breathe, drift, pulses, mv, landmarks
from court_anims_clips import (Act, clip, torso_of, tpose, body_pt, hand_mouth, hand_heart, hand_belly, hand_thigh, hand_face,
                               stance_arm, hang, UPPER, FULL)
from court_anims_more import _legs0

ADULTS = ["male_adult", "female_adult", "male_old", "female_old", "male_young", "female_young"]


def V(x, y, z):
    """A point in the figure's own frame (Blender axes: x its left, -y its
    front, z up), metres for a 1.72 m body."""
    return Vector((x * L.K, y * L.K, z * L.K))


def godot(v):
    """A direction in Blender figure axes as Godot holds it (x left, y up, z front)."""
    return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]


def fist(s, C, u, fore, pole, curl=(96, 88, 46), sh=(0.0, 0.0, 0.0), arc=None):
    """An ArmKey (in the hall) closing hand s round a handle: the handle passes
    through the curled fingers at C and runs along u out of the thumb side;
    the forearm comes from about -fore. The game finds the same point and
    axes from the posed bones (court_acting.gd fist_frame)."""
    f = L.FRAME
    hs = f.p["hand"] * L.K
    u = Vector(u).normalized()
    fore = Vector(fore)
    a = (fore - u * fore.dot(u)).normalized()
    n = a.cross(u) if s == "L" else u.cross(a)
    W = Vector(C) - a * (f.hand_len * 0.56 - 0.012 * hs) - n * (0.020 * hs) + u * (0.006 * hs)
    return ArmKey(W, Vector(pole).normalized(), a, n, curl, sh, arc)


class Tool:
    """Keys for a two-handed tool: the right fist at C (the prop's anchor), the
    left fist `gap` metres further along the handle (negative: below it)."""

    def __init__(self, act, gap, poles=((-0.8, 0.3, -0.6), (0.8, 0.3, -0.6))):
        self.a = act
        self.gap = gap
        self.poles = poles

    def key(self, t, torso, C, u, foreR, foreL=None, kind="ease", left=True, arc=None):
        u = Vector(u).normalized()
        a = self.a
        a.t(t, kind, **torso)
        a.world("R", t, torso, fist("R", C, u, foreR, self.poles[0], arc=arc), kind)
        if left:
            a.world("L", t, torso, fist("L", Vector(C) + u * (self.gap * L.K), u, foreL if foreL is not None else foreR, self.poles[1], arc=arc), kind)
        return self


def both_knees(a, lean=0.0):
    """Leg keys for kneeling on both knees (shins flat behind); lean: degrees
    the hips pitch forward, taken back out of the thighs so the knees stay put."""
    legs0 = _legs0(a)
    return merge(legs0, {"thigh.L": {"rot": (8 - lean, 0, -4)}, "shin.L": {"rot": (92, 0, 0)}, "foot.L": {"rot": (-52, 0, 0)}, "toe.L": {"rot": (-50, 0, 0)},
                         "thigh.R": {"rot": (8 - lean, 0, 4)}, "shin.R": {"rot": (92, 0, 0)}, "foot.R": {"rot": (-52, 0, 0)}, "toe.R": {"rot": (-50, 0, 0)}})


def square():
    """J's easy stance with its lean and weight shift taken out: a kneeling
    victim faces the god square on."""
    p = cf_anim.relaxed()
    for b in ("hips", "spine", "chest", "neck", "head", "thigh.L", "thigh.R", "shin.L", "foot.L"):
        p[b] = {"rot": (0.0, 0.0, 0.0)}
    p["hips"]["loc"] = (0.0, 0.0, 0.0)
    return p


KNEEL_UP = dict(hips=(2, 0, 0), hips_loc=(0, 0.07, -0.41), spine=(-2, 0, 0), chest=(-5, 0, 0), neck=(-4, 0, 0), head=(-12, 0, 3))


def ev(t, name, **kw):
    e = {"t": round(t, 3), "name": name}
    for k_, v in kw.items():
        e[k_] = [round(x, 3) for x in v] if isinstance(v, (list, tuple)) else v
    return e


def shake_arms(t, start, end, amount, rate=1.0):
    """Arms buzzing like a struck bell (after an axe bounces off)."""
    if t < start or t > end:
        return {}
    fade = 1.0 - (t - start) / (end - start)
    b = amount * fade
    p = {}
    for s_, sg in (("L", 1.0), ("R", -1.0)):
        side(p, "upper_arm", s_, rot=(b * 3.0 * math.sin(2 * math.pi * 23 * rate * t), 0, b * 2.0 * sg * math.sin(2 * math.pi * 19 * rate * t + 0.5)))
        side(p, "forearm", s_, rot=(b * 4.0 * math.sin(2 * math.pi * 27 * rate * t + 1.0), 0, 0))
    add(p, "head", rot=(b * 1.5 * math.sin(2 * math.pi * 17 * t), 0, b * 2.0 * math.sin(2 * math.pi * 21 * t)))
    return p


def make_exec(clips):
    act_club(clips)
    act_axe(clips)
    act_dogs(clips)
    room(clips)


# =====================================================================================
# 2. Club home run: the victim kneels facing the god; the batter, at their right
#    side and side on to the god, taps the club on their head twice, calls the
#    shot at the cook's pot at the far end of the hall, winds up with a leg kick,
#    CRACK; the head sails up and away into the pot; the cook looks in, looks at
#    the god, stirs, puts the lid on
# =====================================================================================

T_CRACK = 3.62
T_PLOP = 5.0


def act_club(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    lm = landmarks()

    # ---- the victim (kneeling, facing the god, hands pressed together)
    a = Act(6.8, drag=0.8, feet=False, base_pose=square())
    kneel = both_knees(a)
    a.legs([(0.0, kneel), (6.8, kneel)])
    up = dict(KNEEL_UP)
    duck = dict(up, neck=(4, 0, 0), head=(4, 0, 3), chest=(-2, 0, 0))
    look_up = dict(up, neck=(-8, 0, 0), head=(-22, 0, 3))
    over_sh = dict(up, chest=(-5, 0, -8), neck=(-4, 0, -14), head=(-14, 0, -32))
    to_pot = dict(up, chest=(-5, 0, 12), neck=(-4, 0, 22), head=(-14, 0, 55))
    braced = dict(up, spine=(4, 0, 0), chest=(4, 0, 0), neck=(6, 0, 0), head=(10, 0, 0))
    hit = dict(braced, hips_loc=(0.0, 0.11, -0.41), spine=(-4, 0, 2), chest=(-10, 4, 4), neck=(-8, 0, 0))
    headless = dict(up, spine=(0, 0, 2), chest=(-3, 0, 4))
    slump_legs = both_knees(a, lean=70)
    slump = dict(hips=(72, 0, 4), hips_loc=(0, 0.04, -0.43), spine=(16, 0, 2), chest=(10, 0, 0), neck=(10, 0, 0), head=(10, 0, 0))
    keys = [(0.0, up, "ease"), (0.45, duck, "snap"), (0.62, look_up, "out"), (0.95, duck, "snap"), (1.12, look_up, "out"),
            (1.3, over_sh, "ease"), (1.6, over_sh, "ease"), (1.85, to_pot, "out"), (2.3, to_pot, "ease"), (2.6, up, "ease"),
            (2.75, braced, "out"), (T_CRACK - 0.01, braced, "ease"), (T_CRACK + 0.06, hit, "snap"), (T_CRACK + 0.5, headless, "settle"),
            (5.55, headless, "ease"), (6.0, slump, "in"), (6.12, dict(slump, hips=(76, 0, 4)), "settle"), (6.8, slump, "ease")]
    for t, tor, kind in keys:
        a.t(t, kind, **tor)
    a.legs([(0.0, kneel), (5.55, kneel), (6.0, slump_legs, "in"), (6.8, slump_legs)])
    for s_ in "LR":
        pray = arm_at(s_, w=body_pt(0.035, -0.25, z_chest - 0.08), along=(-0.25, -0.35, 0.90), palm=(-0.98, 0.1, 0.0), pole=(0.9, 0.3, -0.6),
                      curl=(4, -4, -6), sh=(0, -4, 0))
        tight = pray.copy(w=pray.w + Vector((0, 0.02 * k, 0.05 * k)), curl=(10, 4, 0), sh=(0, -14, -4))
        a.rest(s_, 0.0).arm(s_, 0.3, pray, "out").arm(s_, 2.6, pray).arm(s_, 2.8, tight, "out").arm(s_, T_CRACK + 0.4, tight)
        # headless: the hands come up and pat about where the head was
        pat_lo = arm_at(s_, w=body_pt(0.08, -0.06, f.z_shoulder / k + 0.02), along=(-0.6, 0.0, 0.8), palm=(-0.9, 0.0, -0.4), pole=(0.9, 0.2, -0.4),
                        curl=(10, 6, 0), sh=(0, -10, 0))
        pat_hi = pat_lo.copy(w=pat_lo.w + Vector((0, 0, 0.07 * k)))
        a.arm(s_, 4.35, pat_lo, "out").arm(s_, 4.62, pat_hi, "out").arm(s_, 4.78, pat_lo, "snap")
        a.arm(s_, 4.95, pat_hi, "out").arm(s_, 5.12, pat_lo, "snap")
        flop = arm_at(s_, w=body_pt(0.30, -0.42, 0.06), along=(0.2, -0.9, -0.2), palm=(0.0, 0.0, -1.0), pole=(0.9, 0.2, 0.0), curl=(10, 4, 0))
        a.arm(s_, 5.5, pat_lo.copy(sh=(0, -16, 0)), "ease").world(s_, 6.05, slump, flop, "in").world(s_, 6.8, slump, flop)
    a.on_top(lambda t: tremble(t, 1.4 * L.clamp01((t - 2.6) / 0.3) * (1.0 - L.clamp01((t - T_CRACK) / 0.05)), 1.3, 0.4))
    a.f(0.0, "ease", worry=0.7, brows=0.6, lids=1.15).f(0.45, "snap", lids=0.1, tight=0.8, worry=0.8).f(0.62, "out", lids=1.3, eyes_y=1.0, worry=0.7, brows=0.8)
    a.f(0.95, "snap", lids=0.1, tight=0.8).f(1.12, "out", lids=1.3, eyes_y=1.0, brows=0.8).f(1.3, "ease", lids=1.2, eyes_x=-0.9, worry=0.8)
    a.f(1.85, "out", lids=1.35, eyes_x=0.9, brows=0.9, jaw=0.25).f(2.3, "ease", lids=1.4, brows=1.0, jaw=0.45, worry=1.0)
    a.f(2.45, "snap", lids=1.4, jaw=0.0, puff=0.4, worry=1.0).f(2.75, "out", lids=0.0, tight=1.0, worry=1.0, frown=0.6).f(T_CRACK, "ease", lids=0.0, tight=1.0, worry=1.0)
    clips["exec_club_victim"] = clip(
        "exec_club_victim", 6.8, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        events=[ev(0.45, "tap"), ev(0.95, "tap"), ev(T_CRACK, "impact"), ev(T_CRACK, "split", part="head", bone="neck"),
                ev(T_CRACK, "spray", bone="neck", dir=(0.1, 0.55, -0.85)), ev(6.02, "thud")])

    # ---- the batter (at the victim's right, turned to face the victim's side):
    #      the victim's head is at (0.20, -0.95, 1.19) in his frame (Blender axes,
    #      1.72 m bodies); his swing carries it out to his left, the victim's back
    a = Act(7.0, drag=0.5)
    a.arm_drag = 0.0
    tool = Tool(a, -0.11)
    hip_L = stance_arm("hip", "L")
    carry_t = {}
    carry_C, carry_u, carry_f = V(-0.13, -0.17, 1.18), (-0.22, 0.30, 0.93), (0.15, -0.45, 0.85)
    tap_t = dict(spine=(8, 0, 4), chest=(6, 0, 6), head=(14, 0, 8), hips_loc=(0.0, -0.03, -0.01))
    head_top = V(0.20, -0.95, 1.33)
    tap_C = V(0.02, -0.42, 1.06)
    tap_u = (head_top - tap_C)
    tap_C = head_top - tap_u.normalized() * (0.70 * k)
    lift_C = tap_C + V(0.0, 0.03, 0.08)
    call_t = dict(spine=(-2, 0, 10), chest=(-4, 0, 16), neck=(-2, 0, 8), head=(-6, 0, 22))
    call_C, call_u = V(0.18, -0.40, 1.42), (0.86, -0.42, 0.30)
    coil_t = dict(hips=(0, 0, -12), hips_loc=(0.0, 0.01, -0.06), spine=(6, 0, -10), chest=(6, 0, -24), neck=(0, 0, 14), head=(4, 0, 22))
    coil_C, coil_u = V(-0.16, -0.08, 1.32), (-0.18, 0.48, 0.86)
    kick_t = dict(coil_t, hips_loc=(-0.02, 0.05, -0.03), chest=(4, 0, -36), hips=(0, 0, -20), head=(4, 0, 30))
    kick_C, kick_u = V(-0.20, 0.0, 1.36), (-0.35, 0.62, 0.70)
    stride_t = dict(hips=(0, 0, 10), hips_loc=(0.02, -0.06, -0.08), spine=(8, 0, -6), chest=(8, 0, -14), neck=(0, 0, 8), head=(6, 0, 18))
    stride_C, stride_u = V(-0.22, -0.18, 1.22), (-0.55, 0.30, 0.78)
    hitpt = V(0.20, -0.95, 1.19)
    hit_u = Vector((0.35, -0.90, 0.10)).normalized()
    hit_C = hitpt - hit_u * (0.70 * k)
    hit_t = dict(hips=(0, 0, 34), hips_loc=(0.03, -0.08, -0.08), spine=(10, 0, 8), chest=(8, 0, 16), neck=(0, 0, -8), head=(4, 0, -4))
    thru_t = dict(hips=(0, 0, 60), hips_loc=(0.04, -0.06, -0.05), spine=(4, 0, 22), chest=(0, 0, 34), neck=(-4, 0, -12), head=(-10, 0, -18))
    thru_C, thru_u = V(0.20, -0.10, 1.40), (0.18, 0.62, 0.76)
    watch_t = dict(thru_t, neck=(-10, 0, 10), head=(-18, 0, 30))
    watch2_t = dict(thru_t, neck=(-4, 0, 16), head=(2, 0, 44))
    proud_t = dict(spine=(-4, 0, 0), chest=(-8, 0, 4), neck=(-4, 0, 0), head=(-6, 0, 6))
    nod_t = dict(proud_t, neck=(8, 0, 0), head=(14, 0, 0))
    # right fist and club through it all; the left hand on the hip, then on the club
    a.t(0.0, "ease", **carry_t)
    for t, tor, C, u, fo, kind in ((0.0, carry_t, carry_C, carry_u, carry_f, "ease"),
                                   (0.3, tap_t, lift_C, tap_u, (0.2, -0.7, -0.3), "out"),
                                   (0.45, tap_t, tap_C, tap_u, (0.2, -0.7, -0.3), "in"),
                                   (0.68, tap_t, lift_C, tap_u, (0.2, -0.7, -0.3), "out"),
                                   (0.95, tap_t, tap_C, tap_u, (0.2, -0.7, -0.3), "in"),
                                   (1.25, carry_t, carry_C, carry_u, carry_f, "ease"),
                                   (1.6, call_t, call_C, call_u, (0.7, -0.6, 0.2), "out"),
                                   (2.15, call_t, call_C, call_u, (0.7, -0.6, 0.2), "ease")):
        a.t(t, kind, **tor)
        a.world("R", t, tor, fist("R", C, u, fo, (-0.6, 0.3, -0.8)), kind)
    a.arm("L", 0.0, hip_L).arm("L", 2.25, hip_L)
    # into the batter's stance, two waggles, the leg kick and hold, the swing, the follow-through
    tool.key(2.6, coil_t, coil_C, coil_u, (0.1, -0.6, 0.75), (0.3, -0.5, 0.8), "ease")
    tool.key(2.85, coil_t, coil_C + V(0.02, 0.0, 0.02), (-0.08, 0.40, 0.92), (0.1, -0.6, 0.75), (0.3, -0.5, 0.8), "ease")
    tool.key(3.02, coil_t, coil_C, coil_u, (0.1, -0.6, 0.75), (0.3, -0.5, 0.8), "ease")
    tool.key(3.2, kick_t, kick_C, kick_u, (0.0, -0.7, 0.6), (0.3, -0.6, 0.7), "out")
    tool.key(3.44, kick_t, kick_C + V(0.0, 0.01, 0.01), kick_u, (0.0, -0.7, 0.6), (0.3, -0.6, 0.7), "ease")
    tool.key(3.54, stride_t, stride_C, stride_u, (0.0, -0.6, -0.2), (0.3, -0.6, -0.2), "in")
    tool.key(T_CRACK, hit_t, hit_C, hit_u, (0.05, -0.55, -0.6), (0.2, -0.5, -0.6), "in")
    tool.key(3.8, thru_t, thru_C, thru_u, (0.2, 0.2, 0.9), (0.4, 0.0, 0.9), "out", arc=(0.1, -0.25, 0.0))
    tool.key(4.15, thru_t, thru_C + V(0.0, 0.01, -0.02), thru_u, (0.2, 0.2, 0.9), (0.4, 0.0, 0.9), "ease")
    # the left hand lets go: shading the eyes, tracking the flight, then a fist pump at the plop
    for t, tor, kind in ((4.35, watch_t, "out"), (T_PLOP, watch2_t, "ease"), (5.3, watch2_t, "ease"), (5.9, carry_t, "ease"), (6.3, proud_t, "ease"),
                         (6.55, nod_t, "out"), (7.0, proud_t, "ease")):
        a.t(t, kind, **tor)
    shade = arm_at("L", contact=lm["brow"] + Vector((0.03 * k, -0.04 * k, 0.03 * k)), along=(-0.35, -0.5, 0.05), palm=(0.0, 0.1, -1.0),
                   pole=(0.9, 0.1, -0.2), curl=(0, -4, -6), reach=0.35)
    pump_hi = arm_at("L", w=body_pt(0.24, -0.24, z_chest + 0.18), along=(0.0, -0.3, 0.95), palm=(-0.9, 0.0, 0.0), pole=(0.6, 0.2, -0.8), curl=(90, 80, 40))
    pump_lo = pump_hi.copy(w=pump_hi.w + Vector((-0.02 * k, 0.04 * k, -0.09 * k)))
    a.world("L", 4.35, watch_t, shade, "out").world("L", T_PLOP - 0.05, watch2_t, shade)
    a.world("L", 5.12, watch2_t, pump_hi, "out").world("L", 5.24, watch2_t, pump_lo, "snap").world("L", 5.36, watch2_t, pump_hi, "out")
    a.world("L", 5.48, watch2_t, pump_lo, "snap").arm("L", 6.1, hip_L, "ease").arm("L", 7.0, hip_L)
    for t, tor, C, u, fo, kind in ((4.35, watch_t, thru_C, thru_u, (0.2, 0.2, 0.9), "ease"), (5.5, watch2_t, thru_C, thru_u, (0.2, 0.2, 0.9), "ease"),
                                   (5.9, carry_t, carry_C, carry_u, carry_f, "ease"), (7.0, proud_t, carry_C, carry_u, carry_f, "ease")):
        a.world("R", t, tor, fist("R", C, u, fo, (-0.6, 0.3, -0.8)), kind)
    # feet: a step in for the taps, back, the stance, the kick, the stride, the pivot
    a.foot("R", 0.0).foot("R", 0.22, (-0.02, -0.12, 0), "out", lift=0.04).foot("R", 1.15, (-0.02, -0.12, 0)).foot("R", 1.35, (0, 0, 0), "out", lift=0.04)
    a.foot("R", 2.4).foot("R", 2.6, (-0.10, 0.04, 0), "out", lift=0.03).foot("R", 3.54, (-0.10, 0.04, 0))
    a.foot("R", 3.7, (-0.08, 0.03, 0.04), "out", rot=(40, 0, 30)).foot("R", 5.6, (-0.08, 0.03, 0.04), rot=(40, 0, 30)).foot("R", 6.0, (0, 0, 0), "out", lift=0.03)
    a.foot("L", 0.0).foot("L", 2.45).foot("L", 2.65, (0.12, -0.02, 0), "out", lift=0.03).foot("L", 3.05, (0.12, -0.02, 0))
    a.foot("L", 3.25, (0.06, -0.12, 0.30), "out", rot=(-10, 0, 0)).foot("L", 3.44, (0.06, -0.12, 0.31), rot=(-10, 0, 0))
    a.foot("L", 3.56, (0.16, -0.22, 0), "in").foot("L", 5.7, (0.16, -0.22, 0)).foot("L", 6.1, (0, 0, 0), "out", lift=0.04)
    a.f(0.0, "ease", smile=0.3, lids=0.85).f(0.45, "ease", smile=0.4, lids=0.8, eyes_y=-0.5).f(1.6, "out", smile=0.7, lids=0.7, brows=-0.3, eyes_x=0.8)
    a.f(2.15, "ease", smile=0.9, lids=0.75, eyes_x=-0.5).f(2.6, "ease", stern=0.7, tight=0.6, lids=0.8, brows=-0.5)
    a.f(3.3, "ease", stern=0.9, tight=0.9, lids=0.75, brows=-0.8, puff=0.6).f(T_CRACK, "snap", jaw=0.5, tight=0.3, brows=0.2, lids=1.1)
    a.f(4.35, "out", lids=0.6, smile=0.5, brows=0.5, eyes_x=0.8, eyes_y=0.4).f(T_PLOP, "ease", lids=0.7, smile=0.6, eyes_x=0.9, eyes_y=-0.3)
    a.f(5.15, "snap", smile=1.0, jaw=0.4, lids=1.1, brows=0.8).f(6.3, "ease", smile=0.7, lids=0.85).f(7.0, "ease", smile=0.6, lids=0.9)
    clips["exec_club_batter"] = clip(
        "exec_club_batter", 7.0, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        props={"R": "club"},
        events=[ev(0.45, "tap"), ev(0.95, "tap"), ev(1.6, "call_shot"), ev(3.25, "kick"), ev(3.5, "whoosh"), ev(T_CRACK, "impact"), ev(5.2, "pump")])

    # ---- the cook: stirring the pot with a ladle; the head drops in; a look, a
    #      look at the god, two more stirs, the lid on, two pats
    a = Act(8.6, drag=0.9)
    a.arm_drag = 0.0
    pot = V(0.0, -0.52, 0.55)

    def stir_C(ang, r=0.07, z=0.95):
        return V(0.0 + r * math.cos(ang), -0.47 + r * math.sin(ang), z)
    stir_t = dict(spine=(10, 0, 0), chest=(8, 0, 0), neck=(4, 0, 0), head=(14, 0, 0))
    peer_t = dict(hips=(10, 0, 0), spine=(22, 0, 0), chest=(18, 0, 0), neck=(12, 0, 0), head=(30, 0, 0), hips_loc=(0, 0.0, -0.02))
    up_t = dict(stir_t, neck=(-4, 0, 0), head=(-8, 0, 0))
    glance_t = dict(stir_t, neck=(-4, 0, 0), head=(-10, 0, 4))
    lid_t = dict(hips=(14, 0, 4), hips_loc=(0, 0.03, -0.03), spine=(16, 0, 4), chest=(12, 0, 6), neck=(6, 0, 0), head=(16, 0, 0))
    ladle_u = (0.05, -0.12, -0.99)
    fo_R = (0.3, -0.7, -0.4)
    t = 0.0
    n = 0
    while t < T_PLOP - 0.01:
        tor = stir_t
        if 1.55 < t < 2.2 or T_CRACK - 0.05 < t < T_CRACK + 0.6:
            tor = glance_t
        a.t(t, "ease", **tor)
        a.world("R", t, tor, fist("R", stir_C(n * math.pi / 2), ladle_u, fo_R, (-0.8, 0.4, -0.4)), "ease")
        t += 0.3
        n += 1
    hold_C = stir_C(n * math.pi / 2)
    for t, tor, kind in ((T_PLOP, stir_t, "ease"), (T_PLOP + 0.08, dict(stir_t, chest=(4, 0, 0), head=(6, 0, 0)), "snap"),
                         (5.55, peer_t, "out"), (6.15, peer_t, "ease"), (6.45, up_t, "out"), (6.95, up_t, "ease"), (7.2, stir_t, "ease")):
        a.t(t, kind, **tor)
        a.world("R", t, tor, fist("R", hold_C, ladle_u, fo_R, (-0.8, 0.4, -0.4)), kind)
    for i, t in enumerate((7.35, 7.6, 7.85, 8.1)):
        a.t(t, "ease", **lid_t)
        a.world("R", t, lid_t, fist("R", stir_C((n + i) * math.pi / 1.5, 0.05) + V(0.08, 0.06, 0.02), ladle_u, fo_R, (-0.8, 0.4, -0.4)), "ease")
    a.t(8.6, "ease", **stir_t)
    a.world("R", 8.6, stir_t, fist("R", stir_C(0.0, 0.05), ladle_u, fo_R, (-0.8, 0.4, -0.4)), "ease")
    # the left hand: on the pot's rim, then the lid from beside the pot, onto it, two pats
    rim = arm_at("L", w=V(0.20, -0.36, 0.66), along=(0.2, -0.6, -0.75), palm=(-0.2, -0.3, -0.9), pole=(0.9, 0.3, 0.2), curl=(40, 30, 10))
    lid_side = fist("L", V(0.30, -0.28, 0.62), (0.0, 0.0, -1.0), (0.4, -0.6, 0.0), (0.9, 0.3, 0.0), curl=(70, 60, 30))
    lid_on = fist("L", pot + V(0.0, 0.0, 0.10), (0.0, 0.0, -1.0), (0.3, -0.7, 0.0), (0.9, 0.3, 0.0), curl=(70, 60, 30))
    pat_hi = arm_at("L", w=pot + V(0.05, 0.08, 0.20), along=(-0.1, -0.7, -0.7), palm=(0.0, 0.0, -1.0), pole=(0.9, 0.3, 0.0), curl=(6, 0, -6))
    pat_lo = pat_hi.copy(w=pat_hi.w + Vector((0, 0, -0.06 * k)))
    a.world("L", 0.0, stir_t, rim).world("L", 6.95, up_t, rim).world("L", 7.2, lid_t, lid_side, "out").world("L", 7.6, lid_t, lid_on, "out")
    a.world("L", 7.75, lid_t, pat_hi, "out").world("L", 7.88, lid_t, pat_lo, "snap").world("L", 8.02, lid_t, pat_hi, "out")
    a.world("L", 8.15, lid_t, pat_lo, "snap").world("L", 8.6, stir_t, rim, "ease")
    a.f(0.0, "ease", lids=0.75, smile=0.15).f(1.6, "ease", lids=1.0).f(2.2, "ease", lids=0.75, smile=0.15).f(T_CRACK + 0.05, "snap", lids=1.15, brows=0.3)
    a.f(T_CRACK + 0.6, "ease", lids=0.75).f(T_PLOP + 0.05, "snap", lids=0.05, puff=0.3).f(5.3, "out", lids=1.2, brows=0.5)
    a.f(6.15, "ease", lids=1.1, brows=0.6).f(6.45, "out", lids=0.9, brows=0.0, eyes_y=0.6).f(6.95, "ease", lids=0.9, eyes_y=0.6).f(7.2, "ease", lids=0.75, smile=0.2)
    clips["exec_cook_lid"] = clip(
        "exec_cook_lid", 8.6, a, kind="exec", hold=True, tags=["exec", "cook"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        props={"R": "ladle", "L": "lid"}, props_from={"L": 7.2}, props_until={"L": 7.62},
        stage={"pot": godot(pot / k), "pot_rim": round(0.55, 3)},
        events=[ev(T_PLOP, "plop"), ev(T_PLOP + 0.05, "splash_face"), ev(7.6, "lid"), ev(7.88, "pat"), ev(8.15, "pat")])


# =====================================================================================
# 10. Three-swing beheading: the first swing sticks in the block, the second
#     bounces off, the victim glares; the third pops the head off and it rolls to
#     face the god and blinks; the axe sticks in the block again
# =====================================================================================

T_S1, T_FREE, T_S2, T_S3 = 1.95, 3.4, 5.5, 8.7


def act_axe(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k

    # ---- the victim, kneeling, bent over the block, hands bound behind
    a = Act(11.0, drag=0.7, feet=False, base_pose=square())
    lean = 46
    kneel = both_knees(a, lean=lean)
    block_t = dict(hips=(lean, 0, 0), hips_loc=(0, 0.04, -0.43), spine=(30, 0, 0), chest=(22, 0, 0), neck=(-6, 0, 0), head=(6, 0, 0))
    neck_at = L.chest_to_world(torso_of(a.B, tpose(**block_t)), f.neck)
    print("[court_anims] block: neck at", tuple(round(c / k, 3) for c in neck_at))
    peek = dict(block_t, neck=(0, 0, 10), head=(4, 0, 34))
    jolt = dict(block_t, hips_loc=(0, 0.06, -0.38))
    bonk = dict(block_t, neck=(14, 0, 0), head=(20, 0, 0))
    glare = dict(block_t, spine=(22, 0, 0), chest=(10, 0, 6), neck=(-14, 0, 14), head=(-22, 0, 40))
    sigh_ = dict(glare, chest=(6, 0, 6), neck=(-10, 0, 14))
    settle_ = dict(block_t, hips=(lean, 0, 3))
    slump = dict(block_t, hips=(lean, -16, 0), spine=(30, -10, 0), chest=(22, -14, 0), neck=(6, 0, 0))
    slump_legs = both_knees(a, lean=lean)
    keys = [(0.0, block_t, "ease"), (T_S1 - 0.02, block_t, "ease"), (T_S1 + 0.04, jolt, "snap"), (2.25, block_t, "settle"), (2.6, peek, "out"),
            (3.3, peek, "ease"), (T_FREE + 0.03, dict(peek, hips_loc=(0, 0.06, -0.36)), "snap"), (3.7, block_t, "ease"),
            (T_S2 - 0.02, block_t, "ease"), (T_S2 + 0.05, bonk, "snap"), (5.8, dict(bonk, head=(16, 0, 10)), "ease"), (6.05, dict(bonk, head=(16, 0, -10)), "ease"),
            (6.3, dict(bonk, head=(16, 0, 6)), "ease"), (6.75, glare, "out"), (7.2, glare, "ease"), (7.45, sigh_, "ease"), (7.7, glare, "ease"),
            (8.05, settle_, "out"), (8.3, block_t, "ease"), (T_S3, block_t, "ease"), (T_S3 + 0.05, jolt, "snap"), (9.4, block_t, "settle"),
            (9.55, block_t, "ease"), (10.15, slump, "in"), (10.3, dict(slump, hips=(lean, -18, 0)), "settle"), (11.0, slump, "ease")]
    for t, tor, kind in keys:
        a.t(t, kind, **tor)
    a.legs([(0.0, kneel), (11.0, slump_legs)])
    for s_ in "LR":
        bound = arm_at(s_, w=body_pt(-0.02, 0.15, f.z_hip / k + 0.03), along=(-0.6, 0.3, -0.7), palm=(0.0, 1.0, 0.1), pole=(0.9, 0.6, 0.0),
                       curl=(50, 40, 20), sh=(0, 2, 10))
        a.arm(s_, 0.0, bound).arm(s_, 11.0, bound)
    a.on_top(lambda t: tremble(t, 0.9 * (1.0 - L.clamp01((t - 6.5) / 0.3) + L.clamp01((t - 8.2) / 0.2)) * (1.0 - L.clamp01((t - T_S3) / 0.05)), 1.1, 0.7))
    a.on_top(lambda t: breathe(t, 2.2, 2.0 * L.clamp01((t - 7.2) / 0.2) * (1.0 - L.clamp01((t - 7.8) / 0.2)), 0.25))
    a.f(0.0, "ease", worry=0.8, lids=0.4, tight=0.5).f(T_S1, "snap", lids=0.0, tight=1.0, worry=1.0).f(2.6, "out", lids=1.4, eyes_x=1.0, eyes_y=0.8, brows=1.0, jaw=0.3)
    a.f(3.3, "ease", lids=1.4, eyes_x=1.0, brows=1.0, jaw=0.3).f(T_FREE + 0.03, "snap", lids=1.45, brows=1.0, jaw=0.5).f(3.7, "ease", lids=0.3, worry=0.9, tight=0.6)
    a.f(T_S2, "snap", lids=0.0, tight=1.0).f(5.6, "out", lids=0.5, jaw=0.4, brows=0.7, eyes_x=0.6).f(6.3, "ease", lids=0.6, jaw=0.3, eyes_x=-0.6)
    a.f(6.75, "out", stern=1.0, brows=-1.0, tight=0.8, lids=0.75, eyes_x=0.7, frown=0.6).f(7.45, "ease", stern=1.0, brows=-1.0, lids=0.5, puff=0.6)
    a.f(7.7, "ease", stern=0.8, brows=-0.8, lids=0.7, frown=0.6).f(8.3, "ease", lids=0.0, tight=0.7, worry=0.6)
    clips["exec_block_victim"] = clip(
        "exec_block_victim", 11.0, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.5, blend_out=0.6,
        stage={"neck": godot(neck_at / k), "block_top": round(neck_at.z / k - 0.06, 3)},
        events=[ev(T_S1, "thunk"), ev(T_FREE, "free"), ev(T_S2, "clang"), ev(T_S3, "impact"), ev(T_S3, "split", part="head", bone="neck"),
                ev(T_S3, "geyser", bone="neck", dir=(0.0, 0.6, 0.8)), ev(10.15, "thud")])

    # ---- the headsman, to the victim's left, facing the block. In his frame
    #      (Blender axes, 1.72 m bodies) the neck lies at (0.05, -0.70, z_neck)
    #      and the block's near edge at y -0.52
    zn = neck_at.z / k
    neck = V(0.05, -0.70, zn)
    near = V(0.05, -0.53, zn - 0.08)
    in_block = V(0.05, -0.70, zn - 0.13)
    a = Act(11.0, drag=0.5)
    a.arm_drag = 0.0
    tool = Tool(a, 0.10)
    hip_L = stance_arm("hip", "L")
    shoulder_t = {}
    sh_C, sh_u, sh_f = V(-0.12, -0.16, 1.20), (-0.20, 0.35, 0.92), (0.15, -0.45, 0.85)
    raise_t = dict(spine=(-6, 0, 0), chest=(-12, 0, 0), neck=(-6, 0, 0), head=(-4, 0, 0), hips_loc=(0, 0.02, 0.01))
    up_C, up_u = V(-0.02, 0.02, 1.98), (0.0, 0.62, 0.40)
    huge_t = dict(spine=(-10, 0, 0), chest=(-18, 0, 0), neck=(-8, 0, 0), head=(-4, 0, 0), hips_loc=(0, 0.05, 0.04))
    huge_C, huge_u = V(-0.02, 0.10, 2.04), (0.0, 0.80, 0.10)
    chop_t = dict(hips=(10, 0, 0), hips_loc=(0, -0.04, -0.07), spine=(18, 0, 0), chest=(16, 0, 0), neck=(6, 0, 0), head=(14, 0, 0))

    def at_tip(tip, u):
        u = Vector(u).normalized()
        return tip - u * (0.66 * k), u
    stick_C, stick_u = at_tip(near, (0.0, -0.55, -0.83))
    neck_C, neck_u = at_tip(neck, (0.0, -0.62, -0.78))
    in_C, in_u = at_tip(in_block, (0.0, -0.58, -0.81))
    yank_t = dict(hips=(-4, 0, 0), hips_loc=(0, 0.10, -0.10), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(-4, 0, 0), head=(-6, 0, 0))
    yank2_t = dict(yank_t, hips_loc=(0, 0.13, -0.12), chest=(-16, 0, 0))
    foot_t = dict(hips=(-6, 0, 0), hips_loc=(0, 0.10, -0.02), spine=(-4, 0, 0), chest=(-12, 0, 0))
    fall_t = dict(hips=(-12, 0, 0), hips_loc=(0, 0.26, -0.05), spine=(-10, 0, 0), chest=(-16, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0))
    free_C, free_u = V(-0.05, -0.10, 1.40), (0.0, 0.10, 0.99)
    bounce_t = dict(raise_t, hips_loc=(0, 0.04, 0.0))
    bounce_C, bounce_u = V(-0.02, -0.12, 1.75), (0.0, -0.15, 0.99)
    rest_C, rest_u = V(-0.10, -0.30, 0.92), (0.15, -0.55, -0.82)
    look_t = dict(spine=(8, 0, 0), chest=(6, 0, 0), neck=(10, 0, 0), head=(18, 0, 6))
    edge_C, edge_u = V(-0.02, -0.30, 1.30), (0.10, -0.25, 0.96)
    sorry_t = dict(spine=(0, 0, 0), chest=(-2, 0, -6), neck=(4, 0, -10), head=(8, 4, -14))
    lean_t = dict(spine=(-2, 0, 0), chest=(-8, 0, 0), neck=(-4, 0, 0), head=(-8, 0, -8))
    lean_C = in_C
    tool.key(0.0, shoulder_t, sh_C, sh_u, sh_f, left=False)
    a.arm("L", 0.0, hip_L)
    # spits on the left palm, rubs the hands, then up
    spit = hand_mouth("L").copy(curl=(10, 4, 0))
    a.arm("L", 0.25, spit, "out").arm("L", 0.5, spit)
    tool.key(0.7, shoulder_t, sh_C, sh_u, sh_f, (0.2, -0.6, 0.6), "out")
    tool.key(1.2, raise_t, up_C, up_u, (0.0, 0.3, 0.95), (0.0, 0.3, 0.95), "out")
    tool.key(1.75, huge_t, up_C + V(0, 0.02, 0.02), up_u, (0.0, 0.3, 0.95), (0.0, 0.3, 0.95), "ease")
    # swing 1: sticks in the block short of the neck
    tool.key(T_S1, chop_t, stick_C, stick_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "in")
    tool.key(2.15, chop_t, stick_C, stick_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "ease")
    tool.key(2.45, yank_t, stick_C, stick_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "out")
    tool.key(2.6, chop_t, stick_C, stick_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "ease")
    tool.key(2.85, yank2_t, stick_C, stick_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "out")
    tool.key(3.05, foot_t, stick_C, stick_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "ease")
    tool.key(3.36, yank2_t, stick_C, stick_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "in")
    tool.key(T_FREE + 0.12, fall_t, free_C, free_u, (0.0, 0.2, 0.95), (0.0, 0.2, 0.95), "snap")
    tool.key(3.75, fall_t, free_C + V(0.06, 0.02, 0.05), (0.4, 0.2, 0.9), (0.0, 0.2, 0.95), (0.0, 0.2, 0.95), "ease")
    tool.key(4.05, sorry_t, sh_C, sh_u, sh_f, (0.2, -0.6, 0.6), "ease")
    tool.key(4.6, sorry_t, sh_C, sh_u, sh_f, (0.2, -0.6, 0.6), "ease")
    tool.key(5.0, raise_t, up_C, up_u, (0.0, 0.3, 0.95), (0.0, 0.3, 0.95), "out")
    tool.key(5.3, raise_t, up_C, up_u, (0.0, 0.3, 0.95), (0.0, 0.3, 0.95), "ease")
    # swing 2: CLANG off the neck, the arms ringing
    tool.key(T_S2, chop_t, neck_C, neck_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "in")
    tool.key(T_S2 + 0.18, bounce_t, bounce_C, bounce_u, (0.0, -0.1, 0.99), (0.0, -0.1, 0.99), "back2")
    tool.key(6.15, bounce_t, bounce_C, bounce_u, (0.0, -0.1, 0.99), (0.0, -0.1, 0.99), "ease")
    # the left hand shaken out, the edge looked at, a thumb run along it, a shrug
    tool.key(6.4, look_t, rest_C, rest_u, (0.2, -0.5, -0.8), left=False)
    shake = arm_at("L", w=body_pt(0.26, -0.22, z_chest - 0.10), along=(0.1, -0.4, -0.9), palm=(-0.9, 0.0, 0.0), pole=(0.9, 0.3, -0.3), curl=(0, -6, -10))
    a.world("L", 6.35, look_t, shake, "out")
    for i in range(4):
        sw = 1.0 if i % 2 == 0 else -1.0
        a.world("L", 6.45 + 0.09 * i, look_t, shake.copy(w=shake.w + Vector((0.04 * k * sw, 0, 0.02 * k * sw))), "ease")
    tool.key(6.95, look_t, edge_C, edge_u, (0.1, -0.5, -0.8), left=False)
    blade = edge_C + Vector(edge_u).normalized() * (0.66 * k)
    thumb = arm_at("L", w=blade + V(0.0, 0.05, -0.12), along=(-0.6, 0.0, 0.8), palm=(0.0, -1.0, 0.0), pole=(0.9, 0.2, -0.3), curl=(30, 70, -10))
    a.world("L", 6.95, look_t, thumb.copy(w=thumb.w + V(0.04, 0, -0.02)), "out").world("L", 7.25, look_t, thumb.copy(w=thumb.w + V(-0.05, 0, 0.03)), "ease")
    a.world("L", 7.4, look_t, thumb, "snap")
    shrug_L = arm_at("L", w=body_pt(0.30, -0.26, z_chest - 0.12), along=(0.5, -0.6, 0.3), palm=(0.0, 0.2, 0.98), pole=(0.9, 0.4, -0.2), curl=(0, -10, -10), sh=(0, -16, 0))
    tool.key(7.45, sorry_t, rest_C, rest_u, (0.2, -0.5, -0.8), left=False)
    a.world("L", 7.55, sorry_t, shrug_L, "out").world("L", 7.85, sorry_t, shrug_L)
    # swing 3: the biggest wind-up, up on the toes; the chop; the axe sticks again;
    # a hand rests on it, the other on the hip, a nod to the god
    tool.key(8.1, raise_t, up_C, up_u, (0.0, 0.3, 0.95), (0.0, 0.3, 0.95), "out")
    tool.key(8.5, huge_t, huge_C, huge_u, (0.0, 0.3, 0.95), (0.0, 0.3, 0.95), "ease")
    tool.key(T_S3 - 0.04, chop_t, neck_C + V(0, 0.02, 0.05), neck_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "in")
    tool.key(T_S3 + 0.08, chop_t, in_C, in_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "in")
    tool.key(9.3, chop_t, in_C, in_u, (0.0, -0.4, -0.9), (0.0, -0.4, -0.9), "ease")
    tool.key(9.8, lean_t, lean_C, in_u, (0.1, -0.3, -0.95), left=False)
    a.arm("L", 9.9, hip_L, "ease")
    tool.key(10.3, dict(lean_t, neck=(6, 0, -6), head=(12, 0, -10)), lean_C, in_u, (0.1, -0.3, -0.95), "out", left=False)
    tool.key(11.0, lean_t, lean_C, in_u, (0.1, -0.3, -0.95), left=False)
    a.arm("L", 11.0, hip_L)
    a.on_top(lambda t: shake_arms(t, T_S2 + 0.02, T_S2 + 0.85, 1.0))
    # feet: braced; the left foot up on the block for the yank; two steps back; the toes for the big one
    on_block = (0.02, -0.52, max(0.10, zn - 0.10))
    a.foot("L", 0.0).foot("L", 2.9).foot("L", 3.1, on_block, "out", lift=0.15, rot=(-20, 0, 0)).foot("L", 3.36, on_block, rot=(-20, 0, 0))
    a.foot("L", 3.6, (0.02, 0.12, 0), "in", lift=0.05).foot("L", 4.2, (0.02, 0.12, 0)).foot("L", 4.5, (0, 0, 0), "out", lift=0.03)
    a.foot("R", 0.0).foot("R", T_FREE).foot("R", 3.7, (-0.02, 0.22, 0), "out", lift=0.06).foot("R", 4.2, (-0.02, 0.22, 0)).foot("R", 4.6, (0, 0, 0), "out", lift=0.03)
    for s_ in "LR":
        a.foot(s_, 8.2).foot(s_, 8.5, (0, 0, 0.05), "out", rot=(35, 0, 0)).foot(s_, T_S3 - 0.05, (0, 0, 0.05), rot=(35, 0, 0)).foot(s_, T_S3 + 0.05, (0, 0, 0), "snap")
    a.f(0.0, "ease", stern=0.6, lids=0.8).f(0.35, "ease", puff=0.7, lids=0.6).f(0.6, "ease", stern=0.6, lids=0.8)
    a.f(1.6, "ease", stern=0.9, tight=0.8, brows=-0.7).f(T_S1 + 0.05, "snap", lids=1.3, brows=0.9, jaw=0.3)
    a.f(2.45, "out", tight=1.0, puff=0.8, lids=0.4, frown=0.5).f(2.85, "out", tight=1.0, puff=1.0, lids=0.2, frown=0.7)
    a.f(T_FREE + 0.12, "snap", lids=1.4, brows=1.0, jaw=0.6).f(4.05, "ease", smile=0.5, worry=0.5, lids=0.9, brows=0.4)
    a.f(4.6, "ease", stern=0.8, tight=0.7, brows=-0.6).f(T_S2 + 0.05, "snap", lids=1.4, brows=1.0, jaw=0.5, tight=0.6)
    a.f(6.95, "out", lids=0.6, frown=0.6, brows=-0.3).f(7.4, "snap", lids=0.1, tight=0.9, jaw=0.3).f(7.55, "out", worry=0.6, smile=0.3, brows=0.8, lids=1.0)
    a.f(8.1, "ease", stern=1.0, tight=1.0, brows=-1.0, puff=0.8).f(T_S3 + 0.05, "snap", jaw=0.5, stern=0.6, lids=1.2)
    a.f(9.8, "out", smile=0.8, lids=0.75, brows=0.2).f(11.0, "ease", smile=0.7, lids=0.8)
    clips["exec_axe_headsman"] = clip(
        "exec_axe_headsman", 11.0, a, kind="exec", hold=True, tags=["exec", "executioner"], bodies=ADULTS, blend_in=0.4, blend_out=0.6,
        props={"R": "axe"},
        events=[ev(0.42, "spit"), ev(1.85, "whoosh"), ev(T_S1, "thunk"), ev(2.45, "grunt"), ev(2.85, "grunt"), ev(T_FREE, "free"),
                ev(5.42, "whoosh"), ev(T_S2, "clang"), ev(8.6, "whoosh"), ev(T_S3, "impact"), ev(T_S3 + 0.08, "thunk")])


# =====================================================================================
# 4. Dog dinner: the dogs seize the ankles; down on the face; dragged off clawing
#    at the floor; a last grip on a post, the fingers slipping one by one, a wave
# =====================================================================================

PRONE_FEET = (0.0, 0.52, 0.04)
PRONE_FOOT_ROT = (150, 0, 0)


def prone(a, start=0.0, over=0.0):
    """Lying face down, the feet pulled straight back (the dogs have them); the
    knees turn to point at the floor from `start` over `over` seconds."""
    K0 = dict(a.KNEES)
    down = {s_: Vector((0.15 if s_ == "L" else -0.15, -0.2, -1.0)).normalized() for s_ in "LR"}

    def knees(t):
        u = L.curve("ease", (t - start) / over) if over > 0 else (1.0 if t >= start else 0.0)
        return {s_: K0[s_].lerp(down[s_], u).normalized() for s_ in "LR"}
    a.knee_fn = knees
    return dict(hips=(84, 0, 0), hips_loc=(0, -0.28, -0.78), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(-30, 0, 0), head=(-26, 0, 0))


def act_dogs(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k

    # ---- seized and pulled down
    a = Act(1.2, drag=0.5)
    lying = prone(a, 0.1, 0.45)
    grab_t = dict(hips=(-4, 0, 0), hips_loc=(0, -0.04, 0.0), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0))
    tip_t = dict(hips=(40, 0, 0), hips_loc=(0, -0.26, -0.30), spine=(4, 0, 0), chest=(0, 0, 0), neck=(-20, 0, 0), head=(-20, 0, 0))
    a.t(0.0).t(0.08, "snap", **grab_t).t(0.35, "in", **tip_t).t(0.58, "in", **lying).t(0.68, "settle", **dict(lying, hips_loc=(0, -0.28, -0.77))).t(1.2, "ease", **lying)
    for s_ in "LR":
        a.foot(s_, 0.0).foot(s_, 0.1, (0, 0.18, 0.04), "snap", rot=(60, 0, 0)).foot(s_, 0.58, PRONE_FEET, "in", rot=PRONE_FOOT_ROT).foot(s_, 1.2, PRONE_FEET, rot=PRONE_FOOT_ROT)
        fling = arm_at(s_, w=body_pt(0.30, -0.10, z_chest + 0.25), along=(0.4, -0.3, 0.85), palm=(0.0, -1.0, 0.0), pole=(0.8, 0.4, -0.4), curl=(-6, -10, -10), sh=(0, -12, 0))
        brace = arm_at(s_, w=V(0.22, -0.95, 0.10), along=(0.1, -0.85, -0.5), palm=(0.0, 0.2, -0.98), pole=(0.9, 0.0, 0.3), curl=(0, -6, -10))
        a.rest(s_, 0.0).arm(s_, 0.12, fling, "snap").world(s_, 0.5, lying, brace, "in").world(s_, 1.2, lying, brace)
    a.f(0.0).f(0.08, "snap", lids=1.45, brows=1.0, jaw=0.8, worry=1.0).f(0.58, "ease", lids=0.1, tight=1.0, jaw=0.4).f(0.75, "out", lids=1.4, brows=1.0, jaw=0.9, worry=1.0)
    a.f(1.2, "ease", lids=1.35, brows=1.0, jaw=0.8, worry=1.0)
    clips["exec_dog_down"] = clip("exec_dog_down", 1.2, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.05, blend_out=0.3,
                                  events=[ev(0.0, "grab"), ev(0.6, "thud")])

    # ---- dragged off clawing at the floor (the stage carries them feet first)
    a = Act(0.9, drag=0.4)
    a.loop = True
    lying = prone(a)
    a.t(0.0, "ease", **lying).t(0.45, "ease", **dict(lying, chest=(-12, 0, 6), head=(-28, 0, -6))).t(0.9, "ease", **lying)
    for s_ in "LR":
        a.foot(s_, 0.0, PRONE_FEET, rot=PRONE_FOOT_ROT).foot(s_, 0.9, PRONE_FEET, rot=PRONE_FOOT_ROT)
    for s_, ph in (("L", 0.0), ("R", 0.45)):
        far = arm_at(s_, w=V(0.18, -1.05, 0.10), along=(0.0, -0.8, -0.6), palm=(0.0, 0.2, -0.98), pole=(0.9, 0.0, 0.3), curl=(40, 30, 0))
        near = arm_at(s_, w=V(0.24, -0.70, 0.08), along=(0.1, -0.7, -0.7), palm=(0.0, 0.2, -0.98), pole=(0.9, 0.0, 0.3), curl=(90, 80, 20))
        lift = far.copy(w=far.w + Vector((0, 0.1 * k, 0.12 * k)), curl=(0, -6, -10))
        seq = [(0.0, near), (0.18, lift), (0.32, far), (0.62, near), (0.9, near)]
        for t, key in seq:
            a.world(s_, (t + ph) % 0.9, lying, key, "ease")
    a.f(0.0, "ease", lids=1.4, brows=1.0, jaw=0.9, worry=1.0).f(0.45, "ease", lids=1.35, brows=1.0, jaw=0.7, worry=1.0).f(0.9, "ease", lids=1.4, brows=1.0, jaw=0.9, worry=1.0)
    clips["exec_dog_claw"] = clip("exec_dog_claw", 0.9, a, kind="walk", loop=True, tags=["exec", "victim"], bodies=ADULTS, speed_mps=0.9, moves="back",
                                  blend_in=0.2, blend_out=0.2)

    # ---- a last grip: hands clamped on a post's foot ahead, pulled taut three
    #      times, the fingers slip one by one, a small wave goodbye as they go
    a = Act(2.8, drag=0.5)
    lying = prone(a)
    taut = dict(lying, hips_loc=(0, -0.24, -0.78), chest=(-6, 0, 0))
    a.t(0.0, "ease", **lying)
    for t in (0.45, 0.95, 1.45):
        a.t(t, "snap", **taut).t(t + 0.25, "ease", **lying)
    a.t(2.05, "ease", **lying).t(2.15, "snap", **dict(lying, hips_loc=(0, -0.20, -0.78))).t(2.8, "ease", **lying)
    for s_ in "LR":
        a.foot(s_, 0.0, PRONE_FEET, rot=PRONE_FOOT_ROT).foot(s_, 2.8, PRONE_FEET, rot=PRONE_FOOT_ROT)
        hold_ = fist(s_, V(0.06 if s_ == "L" else -0.06, -1.12, 0.10), (0.0, 0.0, 1.0), (0.0, -1.0, 0.0), (0.9 if s_ == "L" else -0.9, 0.0, 0.3), curl=(96, 88, 46))
        a.world(s_, 0.0, lying, hold_).world(s_, 1.5, lying, hold_)
        for i, t in enumerate((1.6, 1.8, 1.95)):
            c = (96 - 30 * (i + 1), 88 - 30 * (i + 1), 46 - 15 * (i + 1))
            a.world(s_, t, lying, hold_.copy(curl=c), "snap")
        open_ = hold_.copy(w=hold_.w + Vector((0, 0.10 * k, 0.02 * k)), curl=(0, -6, -10))
        a.world(s_, 2.15, lying, open_, "snap")
    wave_k = arm_at("R", w=V(0.20, -0.85, 0.32), along=(0.0, -0.3, 0.95), palm=(0.0, -1.0, 0.0), pole=(0.9, 0.1, -0.6), curl=(0, -6, -8))
    a.world("R", 2.35, lying, wave_k, "out")
    for i in range(3):
        sw = 1.0 if i % 2 == 0 else -1.0
        a.world("R", 2.45 + 0.1 * i, lying, wave_k.copy(w=wave_k.w + Vector((0.04 * k * sw, 0, 0))), "ease")
    a.world("R", 2.8, lying, wave_k)
    a.f(0.0, "ease", tight=1.0, lids=0.4, jaw=0.3, worry=0.8).f(1.5, "ease", tight=1.0, lids=0.3, worry=1.0).f(1.95, "ease", lids=1.4, brows=1.0, worry=1.0, jaw=0.5)
    a.f(2.35, "out", lids=1.0, smile=0.4, worry=0.8, brows=0.8).f(2.8, "ease", lids=1.0, smile=0.4, worry=0.8, brows=0.8)
    clips["exec_dog_grip"] = clip("exec_dog_grip", 2.8, a, kind="exec", hold=True, tags=["exec", "victim"], bodies=ADULTS, blend_in=0.15, blend_out=0.3,
                                  events=[ev(0.45, "tug"), ev(0.95, "tug"), ev(1.45, "tug"), ev(1.6, "slip"), ev(1.8, "slip"), ev(1.95, "slip"), ev(2.15, "let_go")])


# =====================================================================================
# The room, every time: wiping a splattered face, being sick into a pot, covering
# the eyes and peeking (a child too), applauding alone, flinching from the splash,
# wincing at the crunches out of sight
# =====================================================================================

def room(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    lm = landmarks()

    # ---- splattered: a flinch, a frozen beat, both hands slowly down the face, a
    #      look at the palms, a small shake of the head, the hands flicked
    a = Act(3.2, drag=0.8)
    hit = dict(chest=(-6, 0, 0), neck=(-6, 0, 0), head=(-10, 0, 0), hips_loc=(0, 0.02, 0.0))
    still = dict(chest=(-4, 0, 0), neck=(-4, 0, 0), head=(-6, 0, 0))
    palms_t = dict(chest=(6, 0, 0), neck=(8, 0, 0), head=(20, 0, 0))
    a.t(0.0).t(0.06, "snap", **hit).t(0.3, "settle", **still).t(1.0, "ease", **still).t(1.7, "ease", **dict(still, head=(2, 0, 0)))
    a.t(2.0, "out", **palms_t).t(2.45, "ease", **palms_t).t(2.55, "ease", **dict(palms_t, head=(20, 0, 8))).t(2.65, "ease", **dict(palms_t, head=(20, 0, -8)))
    a.t(2.75, "ease", **palms_t).t(3.2, "ease")
    for s_ in "LR":
        top = arm_at(s_, contact=lm["brow"] + Vector((0.035 * k, -0.01 * k, 0.0)), along=(-0.15, 0.05, 0.98), palm=(0.0, 1.0, 0.0), pole=(0.9, 0.0, -0.6),
                     curl=(8, 4, 0), reach=0.42)
        low = arm_at(s_, contact=lm["chin"] + Vector((0.03 * k, -0.01 * k, -0.02 * k)), along=(-0.15, 0.05, 0.98), palm=(0.0, 1.0, 0.0), pole=(0.9, 0.0, -0.6),
                     curl=(8, 4, 0), reach=0.42)
        palm_up = arm_at(s_, w=body_pt(0.11, -0.30, z_chest + 0.04), along=(-0.15, -0.75, 0.45), palm=(0.0, 0.4, 0.92), pole=(0.9, 0.3, -0.3), curl=(16, 10, 0))
        flick = palm_up.copy(w=palm_up.w + Vector((0.08 * k, -0.02 * k, -0.10 * k)), along=Vector((0.3, -0.4, -0.85)), curl=(-10, -12, -12))
        a.rest(s_, 0.0).arm(s_, 0.06, a.rest_arm[s_].copy(sh=(0, -10, 0)), "snap").rest(s_, 1.0)
        a.arm(s_, 1.2, top.copy(arc=(0.04, -0.08, 0.0)), "out").arm(s_, 1.75, low, "ease").arm(s_, 2.0, palm_up, "out").arm(s_, 2.75, palm_up)
        a.arm(s_, 2.85, flick, "snap").arm(s_, 2.95, palm_up, "ease").arm(s_, 3.05, flick, "snap").rest(s_, 3.2, "ease")
    a.f(0.0).f(0.06, "snap", lids=0.0, tight=1.0, puff=0.4).f(0.3, "out", lids=1.25, brows=0.4).f(1.0, "ease", lids=1.25, brows=0.4)
    a.f(1.2, "ease", lids=0.0, tight=0.5).f(1.8, "ease", lids=0.6, tight=0.4).f(2.0, "out", lids=1.3, brows=1.0, eyes_y=-0.9, jaw=0.25)
    a.f(2.75, "ease", lids=1.3, brows=1.0, eyes_y=-0.9, jaw=0.25, frown=0.6).f(3.2, "ease", frown=0.4, worry=0.4)
    clips["room_wipe_face"] = clip("room_wipe_face", 3.2, a, kind="react", tags=["exec", "room", "comic"], groups=UPPER, blend_in=0.05, blend_out=0.5)

    # ---- sick into a pot: the cheeks fill, a hand to the mouth, a turn aside and a
    #      bend, two heaves, up again, the back of the hand across the mouth, a look round
    a = Act(3.6, drag=0.8)
    turn = dict(hips=(0, 0, -20), spine=(8, 0, -12), chest=(10, 0, -16), neck=(6, 0, -8), head=(10, 0, -10))
    bend = dict(hips=(24, 0, -24), hips_loc=(0, 0.06, -0.04), spine=(26, 0, -10), chest=(22, 0, -12), neck=(14, 0, -6), head=(22, 0, -8))
    heave = dict(bend, spine=(32, 0, -10), chest=(30, 0, -12), head=(30, 0, -8))
    upright = dict(chest=(-2, 0, -4), neck=(0, 0, -4), head=(-4, 0, 6))
    a.t(0.0).t(0.25, "snap", chest=(-4, 0, 0), head=(-6, 0, 0)).t(0.55, "ease", **turn).t(0.9, "out", **bend)
    a.t(1.15, "snap", **heave).t(1.4, "ease", **bend).t(1.75, "snap", **heave).t(2.0, "ease", **bend).t(2.5, "out", **upright).t(3.0, "ease", **dict(upright, head=(-4, 0, -14))).t(3.6, "ease")
    a.foot("R", 0.0).foot("R", 0.5, (-0.08, 0.02, 0), "out", lift=0.03).foot("R", 2.6, (-0.08, 0.02, 0)).foot("R", 3.0, (0, 0, 0), "out", lift=0.03)
    cover = hand_mouth("L", cover=True).copy(curl=(16, 8, 4))
    belly = hand_belly("R")
    knee = arm_at("R", w=body_pt(0.18, -0.24, f.z_knee / k + 0.14), along=(0.0, -0.4, -0.9), palm=(0.0, 0.3, -0.95), pole=(0.9, 0.3, 0.0), curl=(20, 14, 6))
    wipe0 = hand_mouth("L").copy(along=Vector((-0.95, -0.2, 0.2)), palm=Vector((0.0, 1.0, 0.0)), curl=(40, 30, 10))
    wipe1 = wipe0.copy(w=wipe0.w + Vector((-0.10 * k, 0.0, 0.0)))
    a.rest("L", 0.0).arm("L", 0.25, cover.copy(arc=(0.04, -0.08, 0)), "snap").arm("L", 0.85, cover).arm("L", 1.1, a.rest_arm["L"].copy(sh=(0, -8, 0)), "ease")
    a.arm("L", 2.1, a.rest_arm["L"]).arm("L", 2.6, wipe0, "out").arm("L", 2.8, wipe1, "ease").rest("L", 3.3, "ease")
    a.rest("R", 0.0).arm("R", 0.35, belly, "out").world("R", 0.95, bend, knee, "ease").world("R", 2.0, bend, knee).rest("R", 2.6, "ease")
    a.on_top(lambda t: {"chest": {"rot": (3 * pulses(t, 1.1, 0.6, 2, 0.8), 0, 0)}, "shoulder.L": {"rot": (0, -6 * pulses(t, 1.1, 0.6, 2, 0.8), 0)},
                        "shoulder.R": {"rot": (0, 6 * pulses(t, 1.1, 0.6, 2, 0.8), 0)}})
    a.f(0.0).f(0.25, "snap", puff=1.0, lids=1.35, brows=0.9).f(0.9, "ease", puff=0.8, lids=0.3, worry=0.8).f(1.15, "snap", jaw=0.9, lids=0.0, tight=1.0)
    a.f(1.4, "ease", jaw=0.3, lids=0.2, tight=0.6).f(1.75, "snap", jaw=0.9, lids=0.0, tight=1.0).f(2.0, "ease", jaw=0.3, lids=0.3)
    a.f(2.6, "ease", lids=0.8, worry=0.6, frown=0.5).f(3.0, "ease", lids=1.0, eyes_x=0.8, worry=0.5, smile=0.15).f(3.6, "ease")
    clips["room_vomit"] = clip("room_vomit", 3.6, a, kind="react", tags=["exec", "room", "comic"], blend_in=0.1, blend_out=0.5,
                               events=[ev(1.15, "retch"), ev(1.75, "retch")])

    # ---- covering the eyes, then a peek through the fingers, and covered again
    for who, s_peek, scale in (("room_cover_eyes_peek", "R", 1.0), ("child_cover_eyes_peek", "R", 1.3)):
        a = Act(3.2, drag=0.6)
        hunch = dict(spine=(4, 0, 0), chest=(6, 0, 0), neck=(6, 0, 0), head=(10, 0, 0), hips_loc=(0, 0.01, -0.02))
        peek_t = dict(hunch, neck=(2, 0, 4 * scale), head=(2, 0, 10 * scale))
        away = dict(hunch, chest=(8, 0, -10 * scale), neck=(6, 0, -12 * scale), head=(12, 0, -24 * scale))
        a.t(0.0).t(0.1, "snap", **hunch).t(1.2, "ease", **hunch).t(1.45, "out", **peek_t).t(1.9, "ease", **peek_t).t(2.0, "snap", **away).t(3.2, "ease", **away)
        for s_ in "LR":
            cov = hand_face(s_).copy(w=hand_face(s_).w + mv(Vector((0.03 * k, 0.0, 0.0)), s_), curl=(10, 6, 0), sh=(0, -10, -4))
            a.rest(s_, 0.0).arm(s_, 0.1, cov.copy(arc=(0.05, -0.1, 0.0)), "snap").arm(s_, 1.2, cov)
            if s_ == s_peek:
                peek = cov.copy(w=cov.w + mv(Vector((0.04 * k, -0.02 * k, -0.04 * k)), s_), curl=(10, -20, 0))
                a.arm(s_, 1.4, peek, "out").arm(s_, 1.9, peek).arm(s_, 2.0, cov, "snap")
            else:
                a.arm(s_, 2.0, cov)
            a.arm(s_, 3.2, cov)
        a.on_top(lambda t: tremble(t, 0.8 * L.clamp01((t - 2.0) / 0.1), 1.2, 0.3))
        a.f(0.0).f(0.1, "snap", lids=0.0, tight=0.9, worry=0.9).f(1.2, "ease", lids=0.0, tight=0.8, worry=0.9).f(1.45, "out", lids=1.45, brows=1.0, jaw=0.4, worry=0.9)
        a.f(1.9, "ease", lids=1.45, brows=1.0, jaw=0.5, worry=1.0).f(2.0, "snap", lids=0.0, tight=1.0, worry=1.0).f(3.2, "ease", lids=0.0, tight=1.0, worry=1.0)
        clips[who] = clip(who, 3.2, a, kind="react", hold=True, tags=["exec", "room", "fear"] + (["child"] if who.startswith("child") else []), groups=UPPER,
                          blend_in=0.05, blend_out=0.6, **({"bodies": ["child"]} if who.startswith("child") else {}))

    # ---- applauding alone: big claps, a glance left and right, slower, slower, the
    #      last clap stops halfway; the hands clasped; the clothes smoothed
    a = Act(3.6, drag=0.7)
    a.t(0.0).t(0.2, "out", chest=(-4, 0, 0), head=(-6, 0, 0)).t(1.1, "ease", chest=(-4, 0, 0), head=(-6, 0, 0))
    a.t(1.35, "ease", chest=(-2, 0, 4), neck=(0, 0, 8), head=(-4, 0, 22)).t(1.65, "ease", chest=(-2, 0, -4), neck=(0, 0, -8), head=(-4, 0, -22))
    a.t(1.95, "ease", chest=(0, 0, 0), head=(2, 0, 0)).t(2.8, "ease", chest=(2, 0, 0), head=(6, 0, 0)).t(3.6, "ease")
    claps = [0.25, 0.45, 0.65, 0.85, 1.05, 1.3, 1.6, 2.0, 2.5]
    for s_ in "LR":
        apart = arm_at(s_, w=body_pt(0.16, -0.30, z_chest - 0.04), along=(-0.3, -0.4, 0.85), palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.3, -0.6), curl=(4, -4, -6))
        meet = arm_at(s_, w=body_pt(0.03, -0.32, z_chest - 0.04), along=(-0.3, -0.4, 0.85), palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.3, -0.6), curl=(4, -4, -6))
        half = arm_at(s_, w=body_pt(0.09, -0.31, z_chest - 0.04), along=(-0.3, -0.4, 0.85), palm=(-0.95, 0.0, 0.0), pole=(0.9, 0.3, -0.6), curl=(4, -4, -6))
        clasp = arm_at(s_, w=body_pt(0.04, -0.24, f.z_waist / k + 0.02), along=(-0.6, -0.3, 0.4), palm=(-0.5, 0.2, -0.8), pole=(0.9, 0.3, -0.3), curl=(40, 30, 10))
        a.rest(s_, 0.0)
        for i, t in enumerate(claps[:-1]):
            a.arm(s_, t - (0.1 if i < 5 else 0.16), apart, "out").arm(s_, t, meet, "in")
        a.arm(s_, 2.35, apart, "out").arm(s_, 2.5, half, "in").arm(s_, 2.9, half).arm(s_, 3.1, clasp, "ease").arm(s_, 3.6, clasp)
    a.f(0.0).f(0.2, "out", smile=1.0, brows=0.8, lids=1.1).f(1.1, "ease", smile=1.0, brows=0.8, lids=1.1).f(1.35, "ease", smile=0.7, eyes_x=1.0, brows=0.5)
    a.f(1.65, "ease", smile=0.5, eyes_x=-1.0, brows=0.6).f(2.0, "ease", smile=0.3, worry=0.4, lids=1.0).f(2.9, "ease", smile=0.1, worry=0.5, tight=0.4)
    a.f(3.6, "ease", tight=0.5, lids=0.8, eyes_y=-0.5)
    clips["room_applaud_alone"] = clip("room_applaud_alone", 3.6, a, kind="react", tags=["exec", "room", "comic"], groups=UPPER, blend_in=0.1, blend_out=0.5,
                                       events=[ev(t, "clap") for t in claps[:-1]])

    # ---- the splash: a jerk back with the forearms up, a beat, the arms lowered
    #      slowly, a look down at the front of the clothes
    a = Act(2.6, drag=0.6)
    back_t = dict(hips_loc=(0, 0.05, 0.0), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(4, 0, 0), head=(6, 0, 6))
    a.t(0.0).t(0.07, "snap", **back_t).t(0.9, "ease", **back_t).t(1.6, "ease", spine=(4, 0, 0), chest=(6, 0, 0), neck=(10, 0, 0), head=(24, 0, 0))
    a.t(2.1, "ease", spine=(4, 0, 0), chest=(6, 0, 0), neck=(10, 0, 0), head=(24, 0, 0)).t(2.6, "ease")
    a.foot("L", 0.0).foot("L", 0.12, (0.0, 0.12, 0), "snap", lift=0.03).foot("L", 2.6, (0.0, 0.12, 0))
    for s_ in "LR":
        shield = arm_at(s_, w=body_pt(0.10, -0.22, f.z_shoulder / k + 0.08), along=(-0.7, -0.2, 0.6), palm=(0.0, -0.9, 0.3), pole=(0.9, 0.0, -0.4),
                        curl=(10, 4, 0), sh=(0, -14, -4))
        lowered = arm_at(s_, w=body_pt(0.20, -0.20, f.z_waist / k + 0.05), along=(0.2, -0.6, -0.75), palm=(-0.2, 0.0, 0.98), pole=(0.9, 0.3, -0.2), curl=(16, 10, 0))
        a.rest(s_, 0.0).arm(s_, 0.07, shield, "snap").arm(s_, 0.9, shield).arm(s_, 1.6, lowered, "ease").arm(s_, 2.1, lowered).rest(s_, 2.6, "ease")
    a.f(0.0).f(0.07, "snap", lids=0.0, tight=1.0, puff=0.3).f(0.9, "ease", lids=0.1, tight=0.9).f(1.3, "ease", lids=0.9, worry=0.6)
    a.f(1.6, "ease", lids=1.3, brows=1.0, eyes_y=-1.0, jaw=0.3, frown=0.6).f(2.1, "ease", lids=1.3, brows=1.0, eyes_y=-1.0, jaw=0.3, frown=0.6).f(2.6, "ease", frown=0.4)
    clips["room_flinch_splash"] = clip("room_flinch_splash", 2.6, a, kind="react", tags=["exec", "room", "comic"], blend_in=0.04, blend_out=0.5)

    # ---- crunching out of sight: a wince at each, the hands over the ears at the second
    a = Act(2.6, drag=0.6)
    crunches = (0.35, 1.0, 1.65)
    wince = dict(spine=(4, 0, 0), chest=(6, 0, 0), neck=(8, 0, 0), head=(10, 0, -6), hips_loc=(0, 0.0, -0.02))
    a.t(0.0)
    for t in crunches:
        a.t(t, "snap", **wince).t(t + 0.35, "ease", **dict(wince, chest=(3, 0, 0), head=(6, 0, -3)))
    a.t(2.6, "ease", **dict(wince, chest=(3, 0, 0), head=(6, 0, -3)))
    for s_ in "LR":
        ear = arm_at(s_, contact=lm["ear"] + Vector((0.01 * k, 0.0, 0.0)), along=(0.0, 0.1, 0.99), palm=(-1.0, 0.0, 0.0), pole=(0.8, -0.5, -0.35), curl=(6, 0, -4), reach=0.40)
        a.rest(s_, 0.0).rest(s_, crunches[0], sh=(0, -10, 0), kind="snap").rest(s_, 0.85).arm(s_, crunches[1], ear.copy(arc=(0.05, -0.05, 0.0)), "snap").arm(s_, 2.6, ear)
    a.f(0.0)
    for t in crunches:
        a.f(t, "snap", lids=0.0, tight=1.0, worry=0.9, frown=0.6).f(t + 0.35, "ease", lids=0.4, tight=0.7, worry=0.8, frown=0.5)
    a.f(2.6, "ease", lids=0.4, tight=0.7, worry=0.8)
    clips["room_wince_crunch"] = clip("room_wince_crunch", 2.6, a, kind="react", hold=True, tags=["exec", "room"], groups=UPPER, blend_in=0.05, blend_out=0.6,
                                      events=[ev(t, "crunch") for t in crunches])
