"""Small, static work details for the authored court rooms.

Details stay on existing supports. Writing, paper and bound volumes use the
same capability gates as their existing counterparts; no invented records or
insignia are drawn. The callbacks keep this helper independent of the room kit.
"""
import math


def register(info, name, support, capability, kind):
    group = "gates" if capability == "writing" else "technology_gates"
    names = info[group].setdefault(capability, [])
    if name not in names:
        names.append(name)
    info.setdefault("dressing", {})[name] = {
        "support": support, "capability": capability, "kind": kind,
    }


def volume(b, box, name, at, size=(.28, .065, .22), slot="WEAVE_A", yaw=0):
    """A closed folio: real covers around a slightly recessed page block."""
    x, y, z = at
    w, h, d = size
    box(b, name, (x, y + h / 2, z), (w, h, d), slot, yaw, bevel=0)
    # One visible fore-edge, inset from the binding; low contrast and no giant
    # white rectangular labels on every spine.
    box(b, name, (x, y + h / 2, z + d / 2 - .006),
        (w - .025, h - .02, .012), "PAPER", yaw, bevel=0)


def shelf_records(b, box, info, name, at, width, height, kind):
    x, y, z = at
    contents = name + "_Records"
    for row in range(3):
        floor = y + .0925 + row * (height - .1) / 3
        if kind == "tablet":
            # Three small groups, with their own heights and open shelf space.
            count = max(3, int(width / .23))
            for n in range(count):
                bx = x - width / 2 + .15 + n * (width - .30) / max(1, count - 1)
                h = (.13, .17, .115)[(row + n) % 3]
                box(b, contents, (bx, floor + h / 2, z + .01),
                    (.13 + .015 * (n % 2), h, .14), "TABLET", yaw=.055 * ((n % 3) - 1), bevel=0)
        else:
            # A compact horizontal pile and a varied run of cloth spines.
            pile_x = x - width / 2 + .22
            for layer in range(3):
                volume(b, box, contents, (pile_x + .008 * (layer % 2), floor + layer * .047, z + .015),
                       (.29, .045, .20), "WEAVE_A" if layer % 2 else "WEAVE_B")
            count = max(3, int((width - .48) / .18))
            for n in range(count):
                bx = x - width / 2 + .48 + n * (width - .61) / max(1, count - 1)
                h = (.235, .285, .255, .27)[(n + row) % 4]
                slot = "WEAVE_B" if (n + row) % 4 == 0 else "WEAVE_A"
                box(b, contents, (bx, floor + h / 2, z + .005),
                    (.09 + .015 * (n % 3), h, .18), slot, bevel=0)
                if n % 3 == 1:
                    box(b, contents, (bx, floor + h * .71, z + .101),
                        (.055, .024, .01), "PAPER", bevel=0)
    register(info, contents, name, "writing" if kind == "tablet" else "bound_records", "shelf")


def record(b, box, info, name, at, kind):
    x, y, z = at
    if kind == "book":
        volume(b, box, name, at, (.33, .10, .26))
    elif kind == "paper":
        # Offset sheets have a deliberate handled edge, with abstract strokes
        # only. They are visual paper, never a fabricated factual document.
        for layer in range(3):
            box(b, name, (x + layer * .008, y + .003 + layer * .006, z - layer * .006),
                (.36, .006, .25), "PAPER", yaw=.025 * layer, bevel=0)
        for row in range(3):
            box(b, name, (x - .018, y + .019, z + .065 - row * .04),
                (.19 - .022 * row, .002, .004), "SOOT", bevel=0)
    else:
        box(b, name, (x, y + .026, z), (.29, .052, .21), "TABLET", bevel=0)
        for row in range(3):
            box(b, name, (x - .015, y + .053, z + .052 - row * .038),
                (.17 - row * .025, .002, .005), "CLAY", bevel=0)


def work_clusters(b, box, beam, info, chapter, desks, supports):
    for n, ((x, y, z), support) in enumerate(zip(desks, supports)):
        # Work remains below faces and inside each tabletop. The low front
        # strip is clear of existing lamps, telephones and typing equipment.
        name = "WorkDetail_%d" % n
        front = .22 if support == "SecretaryStation" else .275 if chapter >= 11 else .24
        cx = x + (.15 if chapter < 11 else 0)
        if chapter < 7:
            box(b, name, (cx + .10, y + .021, z + front), (.22, .042, .13), "TABLET", yaw=-.08, bevel=0)
            beam(b, name, (cx - .16, y + .015, z + front - .035),
                 (cx + .02, y + .015, z + front + .035), .008, "WOOD")
            register(info, name, support, "writing", "desktop")
        else:
            # A narrow wooden writing rest with a reed/wood writing tool,
            # progressing to a restrained dark desk tray in later offices.
            material = "WOOD" if chapter < 13 else "SOCKET"
            box(b, name, (cx, y + .012, z + front), (.35, .024, .115), material, bevel=0)
            for dx in (-.165, .165):
                box(b, name, (cx + dx, y + .035, z + front), (.018, .046, .115), material, bevel=0)
            beam(b, name, (cx - .115, y + .032, z + front + .013),
                 (cx + .095, y + .032, z + front - .017), .006, "WOOD" if chapter < 13 else "IRON")
            register(info, name, support, "paper", "desktop")
    if chapter == 15:
        name = "ReceptionFolio"
        volume(b, box, name, (-4.90, .84, -1.75), (.30, .065, .22), "WEAVE_B")
        register(info, name, "ReceptionConsole", "bound_records", "desktop")


def plaque_frame(b, box, at, scale):
    """A plain crafted edge, kept inside the existing institutional panel."""
    x, y, z = at
    w, h = scale, .72 * scale
    frame = .038 * scale
    for side in (-1, 1):
        box(b, "InstitutionAssembly", (x + side * (w / 2 - frame / 2), y, z + .035),
            (frame, h, .022), "WOOD", bevel=0)
        box(b, "InstitutionAssembly", (x, y + side * (h / 2 - frame / 2), z + .035),
            (w - 2 * frame, frame, .022), "WOOD", bevel=0)
