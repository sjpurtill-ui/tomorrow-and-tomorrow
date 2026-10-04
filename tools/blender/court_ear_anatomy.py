"""Smooth geometric pinna relief for the delivered court figure bodies.

This module needs NumPy only.  Coordinates are head-normalized metres: the chin
is Y=0, crown Y=.282, +Z faces forward and the two ears are mirrored about X=0.
Apply this displacement to each absolute blend-shape position, after local mesh
refinement, and recompute its normals.  It intentionally does not edit a GLB or
know about rigs, clothing, materials, or game state.
"""
import numpy as np


EAR_HEIGHT = .445 * .282


def _smooth(lo, hi, value):
    t = np.clip((value - lo) / (hi - lo), 0., 1.)
    return t * t * (3. - 2. * t)


def _ridge(u, v, start, end, width):
    """Rounded ridge around a short segment in ear-plane coordinates."""
    a, b = np.asarray(start), np.asarray(end)
    direction = b - a
    t = np.clip(((u - a[0]) * direction[0] +
                 (v - a[1]) * direction[1]) / np.dot(direction, direction), 0., 1.)
    distance2 = (u - a[0] - t * direction[0]) ** 2 + (v - a[1] - t * direction[1]) ** 2
    return np.exp(-distance2 / width ** 2)


def ear_displacement(points):
    """Return an N-by-3 displacement without mutating ``points``.

    The broad lateral gate keeps the attachment continuous and avoids folding
    the ear into itself while its centre is recessed.  The main relief axis
    faces both sideways and forward, so the rim and bowl read at the court's
    three-quarter camera angles.  All support ends smoothly inside the ear
    neighbourhood: |X| in (.075, .126), |Y-EAR_HEIGHT| < .043,
    and |Z+.014| < .034.  The rest of the head/body is exactly unchanged.

    These are deliberately shallow physical folds, not a hole through the
    mesh.  A 2--2.5 mm edge spacing resolves them.  The lower helix opens into
    a soft lobe rather than making a concentric oval groove.
    """
    p = np.asarray(points, dtype=np.float64)
    if p.ndim != 2 or p.shape[1] != 3:
        raise ValueError("points must have shape (N, 3)")
    if not np.isfinite(p).all():
        raise ValueError("points must be finite")
    displacement = np.zeros_like(p)
    if not len(p):
        return displacement

    x = np.abs(p[:, 0])
    h = p[:, 1] - EAR_HEIGHT
    depth = p[:, 2] + .014
    support = (_smooth(.075, .094, x) * (1. - _smooth(.105, .126, x)) *
               (1. - _smooth(.030, .043, np.abs(h))) *
               (1. - _smooth(.024, .034, np.abs(depth))))
    active = support > 0.
    if not np.any(active):
        return displacement

    # Ear-plane coordinates: +u is the facial/tragus edge; +v is superior.
    u = depth[active] / .019
    v = h[active] / .028
    radius = np.sqrt((u / .91) ** 2 + (v / .96) ** 2)
    upper = _smooth(-.78, -.34, v)

    # A rolled helix, with a gentler lower edge, surrounds a real concha bowl.
    helix = .0030 * np.exp(-((radius - .84) / .19) ** 2) * (.38 + .62 * upper)
    concha = -.0083 * np.exp(-((u - .12) / .58) ** 4 - ((v + .06) / .63) ** 4)

    # The antihelix has a lower stem and two superior crura.  A smooth bounded
    # union keeps the fork from swelling into another bead at its junction.
    stem = _ridge(u, v, (-.25, -.48), (-.30, .20), .14)
    back_fork = _ridge(u, v, (-.30, .14), (-.53, .53), .15)
    front_fork = _ridge(u, v, (-.30, .14), (.18, .55), .14)
    inner_ridge = .0034 * (1. - (1. - stem) * (1. - back_fork) * (1. - front_fork))

    # The tragus shields the front of the recess; the lobe is round, slightly
    # fuller and lower than the old uniformly oval solid bump.
    tragus = .0036 * np.exp(-((u - .62) / .22) ** 2 - ((v + .17) / .28) ** 2)
    lobe = np.exp(-((u + .02) / .57) ** 2 - ((v + .77) / .29) ** 2)
    relief = helix + concha + inner_ridge + tragus + .0018 * lobe

    # Small silhouette expansion at the upper rim, with forward rotation of
    # the visible face.  The cavity stays closed and the root stays attached.
    fullness = .0017 * np.exp(-((u + .22) / .95) ** 2 - ((v - .30) / .86) ** 2)
    weight = support[active]
    side = np.sign(p[active, 0])
    displacement[active, 0] = side * weight * (fullness + .906307787 * relief)
    displacement[active, 1] = weight * (-.0020 * lobe + .0008 * upper * helix / .0030)
    displacement[active, 2] = weight * (.0015 + .422618262 * relief)
    return displacement
