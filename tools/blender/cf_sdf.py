"""A small signed-distance modeller for the court figures.

Forms are signed distance functions evaluated with numpy on a voxel grid and
joined with a smooth union of a chosen radius (clay melted together, never
lumpy). OpenVDB (bundled with Blender) meshes the zero level set.

A primitive is an object with .aabb() -> (lo, hi) and .eval(P) -> distances,
where P is an (..., 3) array of points. Evaluation is limited to each
primitive's box grown by the blend radius, which keeps the level set exact.
"""
import math
import numpy as np
import bpy
from mathutils import Vector, Quaternion, Matrix

BIG = 1.0e3


def _v(a):
    return np.asarray(tuple(a), dtype=np.float32)


def _rot(q):
    """3x3 rotation (world from local) as numpy, from a mathutils Quaternion or None."""
    if q is None:
        return None
    return np.asarray(q.to_matrix(), dtype=np.float32)


def _to_local(P, c, R):
    Q = P - c
    if R is None:
        return Q
    return Q @ R  # (R^T q) for row vectors


# --- Primitives ----------------------------------------------------------------------

class Sphere:
    def __init__(self, c, r):
        self.c = _v(c)
        self.r = float(r)

    def aabb(self):
        return self.c - self.r, self.c + self.r

    def eval(self, P):
        return np.linalg.norm(P - self.c, axis=-1) - self.r


class Ellipsoid:
    """Approximate (iq) ellipsoid distance; radii along the local axes."""

    def __init__(self, c, radii, rot=None):
        self.c = _v(c)
        self.r = _v(radii)
        self.R = _rot(rot)

    def aabb(self):
        m = float(self.r.max())
        return self.c - m, self.c + m

    def eval(self, P):
        Q = _to_local(P, self.c, self.R)
        k0 = np.linalg.norm(Q / self.r, axis=-1)
        k1 = np.linalg.norm(Q / (self.r * self.r), axis=-1)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


class RoundCone:
    """A tapered capsule from a (radius ra) to b (radius rb). Exact (iq)."""

    def __init__(self, a, b, ra, rb=None):
        self.a = _v(a)
        self.b = _v(b)
        self.ra = float(ra)
        self.rb = float(ra if rb is None else rb)

    def aabb(self):
        m = max(self.ra, self.rb)
        return np.minimum(self.a, self.b) - m, np.maximum(self.a, self.b) + m

    def eval(self, P):
        a, b, r1, r2 = self.a, self.b, self.ra, self.rb
        ba = b - a
        l2 = float(ba @ ba)
        rr = r1 - r2
        a2 = l2 - rr * rr
        il2 = 1.0 / l2
        pa = P - a
        y = pa @ ba
        z = y - l2
        xv = pa * l2 - y[..., None] * ba
        x2 = np.einsum('...i,...i->...', xv, xv)
        y2 = y * y * l2
        z2 = z * z * l2
        k = np.sign(rr) * rr * rr * x2
        out = (np.sqrt(x2 * a2 * il2) + y * rr) * il2 - r1
        c1 = np.sign(z) * a2 * z2 > k
        c2 = np.sign(y) * a2 * y2 < k
        d1 = np.sqrt(x2 + z2) * il2 - r2
        d2 = np.sqrt(x2 + y2) * il2 - r1
        out = np.where(c1, d1, np.where(c2, d2, out))
        return out


def Capsule(a, b, r):
    return RoundCone(a, b, r, r)


class RoundBox:
    def __init__(self, c, half, round_r=0.0, rot=None):
        self.c = _v(c)
        self.h = _v(half)
        self.rr = float(round_r)
        self.R = _rot(rot)

    def aabb(self):
        m = float(np.linalg.norm(self.h)) + self.rr
        return self.c - m, self.c + m

    def eval(self, P):
        Q = np.abs(_to_local(P, self.c, self.R)) - (self.h - self.rr)
        outside = np.linalg.norm(np.maximum(Q, 0.0), axis=-1)
        inside = np.minimum(np.max(Q, axis=-1), 0.0)
        return outside + inside - self.rr


class Loft:
    """A body of stacked ellipses: at height z the section is an ellipse of
    half-width w(z), front depth df(z) and back depth db(z), centred at
    (cx, cy(z)). Profiles are lists of (z, value) pairs, interpolated
    smoothly. Capped at the first and last z with rounded ends."""

    def __init__(self, zs, width, front, back, cy=None, cap_round=0.03):
        self.zs = np.asarray(zs, dtype=np.float32)
        self.w = np.asarray(width, dtype=np.float32)
        self.f = np.asarray(front, dtype=np.float32)
        self.b = np.asarray(back, dtype=np.float32)
        self.cy = np.asarray(cy if cy is not None else [0.0] * len(zs), dtype=np.float32)
        self.cap = cap_round

    def _interp(self, z, vals):
        # monotone cubic-ish: smoothstep between keys
        zs = self.zs
        zc = np.clip(z, zs[0], zs[-1])
        i = np.clip(np.searchsorted(zs, zc) - 1, 0, len(zs) - 2)
        z0 = zs[i]
        z1 = zs[i + 1]
        t = np.clip((zc - z0) / np.maximum(z1 - z0, 1e-6), 0.0, 1.0)
        t = t * t * (3.0 - 2.0 * t)
        return vals[i] * (1.0 - t) + vals[i + 1] * t

    def aabb(self):
        m = float(max(self.w.max(), self.f.max(), self.b.max()))
        cy0, cy1 = float(self.cy.min()), float(self.cy.max())
        return _v((-m, cy0 - m, self.zs[0])), _v((m, cy1 + m, self.zs[-1]))

    def eval(self, P):
        x, y, z = P[..., 0], P[..., 1], P[..., 2]
        w = self._interp(z, self.w)
        cy = self._interp(z, self.cy)
        dy = y - cy
        dep = np.where(dy < 0.0, self._interp(z, self.f), self._interp(z, self.b))
        qx = x / w
        qy = dy / dep
        k0 = np.sqrt(qx * qx + qy * qy)
        k1 = np.sqrt((x / (w * w)) ** 2 + (dy / (dep * dep)) ** 2)
        d2 = k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)
        dz = np.maximum(self.zs[0] - z, z - self.zs[-1])
        # rounded caps
        r = self.cap
        a = np.maximum(d2 + r, 0.0)
        bq = np.maximum(dz + r, 0.0)
        return np.minimum(np.maximum(d2 + r, dz + r), 0.0) + np.sqrt(a * a + bq * bq) - r


class Fn:
    """Any distance function with a box."""

    def __init__(self, lo, hi, fn):
        self.lo = _v(lo)
        self.hi = _v(hi)
        self.fn = fn

    def aabb(self):
        return self.lo, self.hi

    def eval(self, P):
        return self.fn(P)


# --- Blending ------------------------------------------------------------------------

def smin(a, b, k):
    if np.isscalar(k) and k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1.0 - h) + a * h - k * h * (1.0 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


# --- The grid ------------------------------------------------------------------------

class Field:
    def __init__(self, lo, hi, voxel):
        self.voxel = float(voxel)
        self.lo = _v(lo)
        self.n = np.ceil((_v(hi) - self.lo) / self.voxel).astype(int) + 1
        self.d = np.full(tuple(self.n), 0.05, dtype=np.float32)

    def _block(self, lo, hi, grow):
        i0 = np.clip(np.floor((lo - grow - self.lo) / self.voxel).astype(int), 0, self.n - 1)
        i1 = np.clip(np.ceil((hi + grow - self.lo) / self.voxel).astype(int) + 1, 0, self.n)
        if np.any(i1 <= i0):
            return None, None
        sl = tuple(slice(int(a), int(b)) for a, b in zip(i0, i1))
        axes = [self.lo[i] + np.arange(i0[i], i1[i], dtype=np.float32) * self.voxel for i in range(3)]
        X, Y, Z = np.meshgrid(*axes, indexing='ij')
        return sl, np.stack((X, Y, Z), axis=-1)

    def union(self, prim, k=0.0):
        lo, hi = prim.aabb()
        sl, P = self._block(lo, hi, max(k, self.voxel * 2) + 0.004)
        if sl is None:
            return
        self.d[sl] = smin(self.d[sl], prim.eval(P).astype(np.float32), k)

    def subtract(self, prim, k=0.0):
        lo, hi = prim.aabb()
        sl, P = self._block(lo, hi, max(k, self.voxel * 2) + 0.004)
        if sl is None:
            return
        self.d[sl] = smax(self.d[sl], -prim.eval(P).astype(np.float32), k)

    def intersect_fn(self, fn, k=0.0):
        """Keep only where fn(P) <= 0 (whole grid)."""
        P = self.points()
        self.d = smax(self.d, fn(P).astype(np.float32), k)

    def points(self):
        axes = [self.lo[i] + np.arange(self.n[i], dtype=np.float32) * self.voxel for i in range(3)]
        X, Y, Z = np.meshgrid(*axes, indexing='ij')
        return np.stack((X, Y, Z), axis=-1)

    def apply(self, fn):
        """d = fn(d, P) over the whole grid."""
        self.d = fn(self.d, self.points()).astype(np.float32)

    def _orient(self, obj):
        """Normals must point out of the solid: step along them and look."""
        me = obj.data
        if not me.polygons:
            return
        step = max(1, len(me.polygons) // 600)
        votes = 0
        for i in range(0, len(me.polygons), step):
            poly = me.polygons[i]
            c = np.asarray(poly.center[:], dtype=np.float32)
            n = np.asarray(poly.normal[:], dtype=np.float32)
            a = self._at(c + n * self.voxel * 1.2)
            b = self._at(c - n * self.voxel * 1.2)
            votes += 1 if a > b else -1
        if votes < 0:
            me.flip_normals()

    def _at(self, p):
        idx = np.clip(np.round((p - self.lo) / self.voxel).astype(int), 0, self.n - 1)
        return float(self.d[idx[0], idx[1], idx[2]])

    def mesh(self, name, adaptivity=0.0):
        import openvdb as vdb
        band = 0.05
        g = vdb.FloatGrid(band)
        g.copyFromArray(np.clip(self.d, -band, band).astype(np.float32))
        pts, tris, quads = g.convertToPolygons(isovalue=0.0, adaptivity=adaptivity)
        pts = pts.astype(np.float64) * self.voxel + self.lo.astype(np.float64)
        me = bpy.data.meshes.new(name)
        verts = [tuple(p) for p in pts]
        faces = [tuple(int(i) for i in q) for q in quads] + [tuple(int(i) for i in t) for t in tris]
        me.from_pydata(verts, [], faces)
        me.validate()
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        self._orient(obj)
        for poly in me.polygons:
            poly.use_smooth = True
        return obj


def _fix_normals(obj):
    """VDB winding can face inward; make normals point out."""
    me = obj.data
    if not me.polygons:
        return
    c = sum((v.co for v in me.vertices), Vector()) / len(me.vertices)
    score = 0.0
    step = max(1, len(me.polygons) // 400)
    for i in range(0, len(me.polygons), step):
        p = me.polygons[i]
        score += p.normal.dot(p.center - c)
    if score < 0:
        me.flip_normals()


def finish_mesh(obj, target_tris=None, smooth=2):
    """Relax and reduce a field mesh to a game budget."""
    for o in bpy.context.selected_objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if smooth:
        mod = obj.modifiers.new("relax", 'CORRECTIVE_SMOOTH')
        mod.factor = 0.5
        mod.iterations = smooth
        mod.use_only_smooth = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if target_tris:
        tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
        if tris > target_tris:
            mod = obj.modifiers.new("reduce", 'DECIMATE')
            mod.ratio = target_tris / tris
            mod.use_collapse_triangulate = True
            bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.validate(clean_customdata=False)
    bpy.ops.object.shade_smooth()
    return obj


# --- Recipes, folded lofts, chunked evaluation ---------------------------------------

class Recipe:
    """Unions and subtractions recorded, then evaluated anywhere (a field's
    interface, so the same builders fill a grid or describe a function)."""

    def __init__(self, far=0.05):
        self.ops = []
        self.far = far

    def union(self, prim, k=0.0):
        self.ops.append(("u", prim, k))

    def subtract(self, prim, k=0.0):
        self.ops.append(("s", prim, k))

    def eval(self, P):
        d = np.full(P.shape[:-1], self.far, dtype=np.float32)
        for op, prim, k in self.ops:
            lo, hi = prim.aabb()
            g = max(k, 0.0) + 0.01
            inside = np.all((P >= lo - g) & (P <= hi + g), axis=-1)
            if not inside.any():
                continue
            v = prim.eval(P[inside]).astype(np.float32)
            if op == "u":
                d[inside] = smin(d[inside], v, k)
            else:
                d[inside] = smax(d[inside], -v, k)
        return d


class FoldLoft(Loft):
    """A loft whose section ripples into folds: each fold set is
    (count, phase, twist, [(z, amplitude)...]); amplitude is relative."""

    def __init__(self, zs, width, front, back, cy=None, cap_round=0.02, folds=(), seed=0.0):
        super().__init__(zs, width, front, back, cy, cap_round)
        self.folds = folds
        self.seed = seed

    def aabb(self):
        lo, hi = super().aabb()
        grow = 1.0 + max([max(a for _, a in f[3]) for f in self.folds] + [0.0]) * 1.2
        m = float(max(self.w.max(), self.f.max(), self.b.max())) * (grow - 1.0)
        return lo - _v((m, m, 0)), hi + _v((m, m, 0))

    def eval(self, P):
        x, y, z = P[..., 0], P[..., 1], P[..., 2]
        cy = self._interp(z, self.cy)
        th = np.arctan2(x, -(y - cy))
        scale = np.ones_like(z)
        for count, phase, twist, amps in self.folds:
            zs = np.asarray([a for a, _ in amps], dtype=np.float32)
            av = np.asarray([b for _, b in amps], dtype=np.float32)
            amp = np.interp(z, zs, av).astype(np.float32)
            ang = count * th + phase + twist * z
            ripple = np.sin(ang) + 0.35 * np.sin(2.0 * ang + 1.3 + self.seed) + 0.2 * np.sin((count // 2) * th + 2.1 + self.seed)
            scale = scale + amp * ripple / 1.55
        Q = P.copy()
        Q[..., 0] = x / scale
        Q[..., 1] = cy + (y - cy) / scale
        return Loft.eval(self, Q) * np.minimum(scale, 1.0)


def chunked(field, fn, chunk=24, coarse=4, band=None):
    """Fill field.d with fn(P). A coarse pass first finds where the surface
    can be; the fine pass evaluates fn only within `band` of it."""
    nx, ny, nz = field.n
    v = field.voxel
    ax = [field.lo[i] + np.arange(field.n[i], dtype=np.float32) * v for i in range(3)]
    if coarse and coarse > 1:
        cv = v * coarse
        cax = [field.lo[i] + np.arange(int(np.ceil((field.n[i] - 1) / coarse)) + 2, dtype=np.float32) * cv for i in range(3)]
        CX, CY, CZ = np.meshgrid(*cax, indexing='ij')
        cd = fn(np.stack((CX, CY, CZ), axis=-1)).astype(np.float32)
        b = band if band is not None else cv * 2.6
        near_c = np.abs(cd) < b
        # a fine voxel is near when any of its coarse cell corners is
        grow = near_c.copy()
        for axis in range(3):
            g2 = grow.copy()
            sl_a = [slice(None)] * 3
            sl_b = [slice(None)] * 3
            sl_a[axis] = slice(1, None)
            sl_b[axis] = slice(None, -1)
            g2[tuple(sl_a)] |= grow[tuple(sl_b)]
            g2[tuple(sl_b)] |= grow[tuple(sl_a)]
            grow = g2
        ii = [np.minimum(np.arange(field.n[i]) // coarse, cd.shape[i] - 1) for i in range(3)]
        for z0 in range(0, nz, chunk):
            z1 = min(nz, z0 + chunk)
            idx = np.ix_(ii[0], ii[1], ii[2][z0:z1])
            near = grow[idx]
            sign = np.where(cd[idx] < 0, -b, b).astype(np.float32)
            out = sign
            if near.any():
                X, Y, Z = np.meshgrid(ax[0], ax[1], ax[2][z0:z1], indexing='ij')
                P = np.stack((X[near], Y[near], Z[near]), axis=-1)
                out = sign.copy()
                out[near] = fn(P).astype(np.float32)
            field.d[:, :, z0:z1] = out
        return field
    for z0 in range(0, nz, chunk):
        z1 = min(nz, z0 + chunk)
        X, Y, Z = np.meshgrid(ax[0], ax[1], ax[2][z0:z1], indexing='ij')
        P = np.stack((X, Y, Z), axis=-1)
        field.d[:, :, z0:z1] = fn(P).astype(np.float32)
    return field


def mesh_fn(name, fn, lo, hi, voxel, chunk=24):
    """Mesh the zero level set of fn inside a box."""
    fld = Field(lo, hi, voxel)
    chunked(fld, fn, chunk)
    if not (fld.d < 0).any():
        return None
    return fld.mesh(name)
