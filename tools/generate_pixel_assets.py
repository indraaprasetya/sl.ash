"""Generate crisp hi-bit pixel art sprites for Blade & Aether (Godot 4 sample)."""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SPRITES = ROOT / "assets" / "sprites"


def new_img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def add_outline(img: Image.Image, outline=(12, 14, 22, 255)) -> Image.Image:
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 20:
                        dst[x, y] = outline
                        break
    return out


def pset(draw: ImageDraw.ImageDraw, x: int, y: int, col):
    draw.point((x, y), fill=col)


def rect(draw: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, col):
    draw.rectangle([x0, y0, x1, y1], fill=col)


def draw_player_pose(pose: str) -> Image.Image:
    img = new_img(64, 64)
    d = ImageDraw.Draw(img)

    dark_armor = (36, 40, 56, 255)
    mid_armor = (62, 70, 96, 255)
    hi_armor = (118, 132, 168, 255)
    scarf_dark = (146, 28, 46, 255)
    scarf_mid = (218, 48, 66, 255)
    scarf_hi = (255, 118, 108, 255)
    visor = (102, 240, 255, 255)
    trim = (238, 194, 92, 255)
    cloak = (26, 28, 42, 255)

    if pose == "idle":
        # Flowing scarf tail
        rect(d, 16, 22, 23, 27, scarf_dark)
        rect(d, 13, 25, 20, 31, scarf_mid)
        rect(d, 11, 29, 16, 35, scarf_dark)
        pset(d, 15, 26, scarf_hi)
        # Legs
        rect(d, 26, 42, 30, 58, dark_armor)
        rect(d, 34, 42, 38, 58, dark_armor)
        rect(d, 26, 54, 31, 59, mid_armor)
        rect(d, 34, 54, 39, 59, mid_armor)
        rect(d, 27, 44, 29, 50, hi_armor)
        rect(d, 35, 44, 37, 50, hi_armor)
        # Torso & belt
        rect(d, 25, 25, 39, 43, cloak)
        rect(d, 27, 26, 37, 39, mid_armor)
        rect(d, 29, 27, 35, 33, hi_armor)
        rect(d, 26, 38, 38, 40, trim)
        # Pauldrons
        rect(d, 22, 24, 27, 30, mid_armor)
        rect(d, 37, 24, 42, 30, mid_armor)
        rect(d, 23, 24, 26, 26, hi_armor)
        rect(d, 38, 24, 41, 26, hi_armor)
        # Scarf collar
        rect(d, 24, 21, 39, 25, scarf_mid)
        rect(d, 26, 21, 37, 23, scarf_hi)
        # Hood & Head
        rect(d, 26, 11, 38, 22, dark_armor)
        rect(d, 28, 10, 36, 15, mid_armor)
        rect(d, 30, 11, 35, 13, hi_armor)
        rect(d, 32, 16, 38, 19, visor)
        pset(d, 37, 17, (235, 255, 255, 255))

    elif pose == "run":
        # Long trailing scarf
        rect(d, 8, 20, 22, 25, scarf_mid)
        rect(d, 5, 23, 15, 27, scarf_dark)
        rect(d, 10, 20, 20, 22, scarf_hi)
        # Forward leaning legs
        d.polygon([(27, 40), (33, 40), (22, 58), (17, 57)], fill=dark_armor)
        d.polygon([(34, 40), (40, 40), (48, 56), (43, 58)], fill=mid_armor)
        rect(d, 43, 54, 49, 59, hi_armor)
        # Leaning torso
        d.polygon([(26, 24), (41, 25), (37, 42), (24, 41)], fill=mid_armor)
        rect(d, 27, 36, 38, 39, trim)
        # Collar & Hood
        rect(d, 27, 20, 41, 25, scarf_mid)
        rect(d, 30, 10, 42, 21, dark_armor)
        rect(d, 32, 10, 40, 14, mid_armor)
        rect(d, 36, 15, 42, 18, visor)

    elif pose == "air":
        # Rising scarf
        rect(d, 13, 28, 23, 34, scarf_mid)
        rect(d, 10, 33, 18, 39, scarf_dark)
        # Tucked knee
        rect(d, 25, 38, 31, 50, dark_armor)
        rect(d, 33, 35, 42, 45, mid_armor)
        rect(d, 35, 43, 41, 50, hi_armor)
        # Torso
        rect(d, 25, 22, 39, 39, mid_armor)
        rect(d, 28, 24, 36, 32, hi_armor)
        rect(d, 25, 35, 39, 37, trim)
        # Scarf + Head
        rect(d, 24, 18, 40, 23, scarf_mid)
        rect(d, 27, 8, 39, 19, dark_armor)
        rect(d, 33, 13, 39, 16, visor)

    elif pose == "dash":
        # Horizontal blur body
        rect(d, 6, 26, 24, 31, scarf_mid)
        rect(d, 4, 30, 16, 33, scarf_dark)
        rect(d, 16, 28, 46, 39, cloak)
        rect(d, 22, 26, 44, 36, mid_armor)
        rect(d, 30, 27, 43, 32, hi_armor)
        rect(d, 32, 34, 45, 36, trim)
        # Head forward
        rect(d, 39, 18, 52, 29, dark_armor)
        rect(d, 46, 22, 53, 25, visor)
        rect(d, 25, 24, 42, 28, scarf_hi)

    elif pose == "wallrun":
        # Upright braced against background wall
        rect(d, 16, 24, 24, 31, scarf_dark)
        rect(d, 26, 39, 31, 56, mid_armor)
        rect(d, 35, 34, 40, 50, hi_armor)
        rect(d, 25, 21, 39, 39, mid_armor)
        rect(d, 24, 18, 39, 23, scarf_mid)
        rect(d, 26, 8, 38, 19, dark_armor)
        rect(d, 32, 13, 38, 16, visor)

    elif pose == "idle_0":
        return draw_player_pose("idle")

    elif pose == "idle_1":
        # Breathing down 1px + scarf flutter
        rect(d, 14, 21, 22, 26, scarf_mid)
        rect(d, 10, 24, 18, 30, scarf_dark)
        pset(d, 14, 24, scarf_hi)
        rect(d, 26, 43, 30, 58, dark_armor)
        rect(d, 34, 43, 38, 58, dark_armor)
        rect(d, 26, 54, 31, 59, mid_armor)
        rect(d, 34, 54, 39, 59, mid_armor)
        rect(d, 25, 26, 39, 44, cloak)
        rect(d, 27, 27, 37, 40, mid_armor)
        rect(d, 29, 28, 35, 34, hi_armor)
        rect(d, 26, 39, 38, 41, trim)
        rect(d, 22, 25, 27, 31, mid_armor)
        rect(d, 37, 25, 42, 31, mid_armor)
        rect(d, 24, 22, 39, 26, scarf_mid)
        rect(d, 26, 12, 38, 23, dark_armor)
        rect(d, 28, 11, 36, 16, mid_armor)
        rect(d, 32, 17, 38, 20, visor)

    elif pose == "run_0":
        # Full open sprint stride
        rect(d, 6, 19, 21, 24, scarf_mid)
        rect(d, 3, 22, 13, 26, scarf_dark)
        rect(d, 9, 19, 19, 21, scarf_hi)
        d.polygon([(26, 40), (32, 40), (18, 57), (13, 55)], fill=dark_armor)
        d.polygon([(34, 40), (40, 40), (50, 55), (45, 58)], fill=mid_armor)
        rect(d, 45, 54, 51, 59, hi_armor)
        d.polygon([(26, 23), (41, 24), (37, 41), (24, 40)], fill=mid_armor)
        rect(d, 27, 35, 38, 38, trim)
        rect(d, 37, 25, 44, 31, hi_armor)
        rect(d, 27, 19, 41, 24, scarf_mid)
        rect(d, 30, 9, 42, 20, dark_armor)
        rect(d, 32, 9, 40, 13, mid_armor)
        rect(d, 36, 14, 42, 17, visor)

    elif pose == "run_1":
        # Passing contact frame (slightly higher, compact legs)
        rect(d, 9, 21, 23, 26, scarf_mid)
        rect(d, 6, 25, 16, 29, scarf_dark)
        rect(d, 28, 40, 34, 58, dark_armor)
        rect(d, 28, 54, 35, 59, hi_armor)
        d.polygon([(33, 41), (38, 41), (42, 52), (37, 54)], fill=mid_armor)
        d.polygon([(26, 22), (40, 23), (37, 41), (25, 40)], fill=mid_armor)
        rect(d, 27, 35, 38, 38, trim)
        rect(d, 27, 18, 40, 23, scarf_mid)
        rect(d, 29, 8, 41, 19, dark_armor)
        rect(d, 35, 13, 41, 16, visor)

    elif pose == "run_2":
        # Opposite open stride
        rect(d, 7, 20, 22, 25, scarf_mid)
        rect(d, 4, 24, 14, 28, scarf_dark)
        rect(d, 10, 20, 20, 22, scarf_hi)
        d.polygon([(27, 40), (33, 40), (20, 58), (15, 56)], fill=mid_armor)
        rect(d, 15, 54, 21, 59, hi_armor)
        d.polygon([(34, 40), (40, 40), (47, 57), (42, 58)], fill=dark_armor)
        d.polygon([(26, 23), (41, 24), (37, 41), (24, 40)], fill=mid_armor)
        rect(d, 27, 35, 38, 38, trim)
        rect(d, 23, 25, 29, 31, hi_armor)
        rect(d, 27, 19, 41, 24, scarf_mid)
        rect(d, 30, 9, 42, 20, dark_armor)
        rect(d, 36, 14, 42, 17, visor)

    elif pose == "run_3":
        # Opposite passing rebound
        rect(d, 10, 20, 24, 25, scarf_mid)
        rect(d, 6, 22, 15, 26, scarf_dark)
        rect(d, 31, 40, 37, 58, mid_armor)
        rect(d, 31, 54, 38, 59, hi_armor)
        d.polygon([(25, 42), (30, 42), (24, 52), (20, 50)], fill=dark_armor)
        d.polygon([(26, 22), (40, 23), (37, 41), (25, 40)], fill=mid_armor)
        rect(d, 27, 35, 38, 38, trim)
        rect(d, 27, 18, 40, 23, scarf_mid)
        rect(d, 29, 8, 41, 19, dark_armor)
        rect(d, 35, 13, 41, 16, visor)

    elif pose == "fall":
        # Descending pose with upward billowing scarf & spread cloak
        rect(d, 12, 14, 22, 22, scarf_mid)
        rect(d, 9, 9, 17, 16, scarf_dark)
        rect(d, 18, 28, 25, 44, cloak)
        rect(d, 25, 39, 31, 54, dark_armor)
        rect(d, 34, 40, 41, 55, mid_armor)
        rect(d, 36, 52, 42, 57, hi_armor)
        rect(d, 25, 23, 39, 40, mid_armor)
        rect(d, 26, 36, 38, 38, trim)
        rect(d, 24, 19, 39, 24, scarf_mid)
        rect(d, 27, 9, 39, 20, dark_armor)
        rect(d, 33, 14, 39, 17, visor)

    elif pose == "atk_windup":
        # Coiled back shoulder anticipation stance
        rect(d, 10, 24, 21, 30, scarf_mid)
        rect(d, 6, 28, 15, 34, scarf_dark)
        d.polygon([(22, 41), (28, 41), (22, 58), (16, 58)], fill=dark_armor)
        d.polygon([(31, 41), (37, 41), (42, 58), (36, 58)], fill=mid_armor)
        rect(d, 36, 54, 43, 59, hi_armor)
        # Torso leaned slightly back & coiled
        d.polygon([(21, 24), (35, 25), (34, 42), (22, 41)], fill=mid_armor)
        rect(d, 23, 36, 34, 39, trim)
        rect(d, 18, 22, 25, 29, hi_armor)
        rect(d, 21, 20, 35, 25, scarf_mid)
        rect(d, 22, 10, 34, 21, dark_armor)
        rect(d, 28, 15, 34, 18, visor)

    elif pose == "atk_slash":
        # Explosive forward torque slash lunge
        rect(d, 4, 22, 22, 27, scarf_mid)
        rect(d, 2, 26, 14, 30, scarf_dark)
        rect(d, 8, 22, 20, 24, scarf_hi)
        # Wide anchored lunge legs
        d.polygon([(22, 42), (28, 42), (14, 58), (9, 57)], fill=dark_armor)
        d.polygon([(35, 42), (42, 42), (50, 58), (44, 58)], fill=mid_armor)
        rect(d, 44, 54, 51, 59, hi_armor)
        # Forward driving torso + extended front shoulder
        d.polygon([(26, 24), (44, 26), (39, 43), (24, 42)], fill=mid_armor)
        rect(d, 28, 37, 40, 40, trim)
        rect(d, 40, 25, 49, 31, hi_armor)
        rect(d, 29, 20, 43, 25, scarf_mid)
        rect(d, 33, 11, 45, 21, dark_armor)
        rect(d, 39, 15, 45, 18, visor)

    elif pose == "atk_up":
        # Rising launcher / uppercut stance
        rect(d, 12, 30, 22, 38, scarf_mid)
        rect(d, 9, 36, 17, 44, scarf_dark)
        rect(d, 25, 40, 31, 57, dark_armor)
        rect(d, 34, 38, 40, 55, mid_armor)
        d.polygon([(26, 20), (40, 19), (37, 40), (25, 40)], fill=mid_armor)
        rect(d, 26, 34, 38, 37, trim)
        rect(d, 36, 16, 43, 24, hi_armor)
        rect(d, 26, 16, 40, 21, scarf_mid)
        rect(d, 28, 7, 40, 17, dark_armor)
        rect(d, 34, 11, 40, 14, visor)

    elif pose == "atk_thrust":
        # Low compressed horizontal pierce lunge
        rect(d, 3, 27, 23, 32, scarf_mid)
        rect(d, 2, 31, 14, 35, scarf_dark)
        d.polygon([(20, 44), (27, 44), (12, 58), (8, 57)], fill=dark_armor)
        d.polygon([(36, 43), (44, 43), (52, 58), (46, 58)], fill=mid_armor)
        rect(d, 46, 54, 53, 59, hi_armor)
        d.polygon([(25, 29), (46, 30), (41, 45), (24, 44)], fill=mid_armor)
        rect(d, 27, 40, 41, 43, trim)
        rect(d, 43, 29, 53, 34, hi_armor)
        rect(d, 28, 25, 43, 30, scarf_mid)
        rect(d, 34, 16, 46, 26, dark_armor)
        rect(d, 40, 20, 47, 23, visor)

    elif pose == "parry":
        # Braced upright deflect guard stance
        rect(d, 15, 22, 23, 29, scarf_mid)
        rect(d, 25, 41, 30, 58, dark_armor)
        rect(d, 34, 41, 39, 58, mid_armor)
        rect(d, 25, 23, 39, 42, mid_armor)
        rect(d, 26, 37, 38, 39, trim)
        rect(d, 35, 22, 43, 31, hi_armor)
        rect(d, 25, 19, 39, 24, scarf_mid)
        rect(d, 27, 10, 39, 20, dark_armor)
        rect(d, 33, 14, 39, 17, (255, 232, 110, 255))

    return add_outline(img)


def draw_weapons():
    wdir = SPRITES / "weapons"
    wdir.mkdir(parents=True, exist_ok=True)

    # Greatsword (48x16)
    gs = new_img(48, 16)
    d = ImageDraw.Draw(gs)
    rect(d, 3, 6, 11, 9, (92, 62, 42, 255))
    rect(d, 1, 5, 4, 10, (218, 178, 86, 255))
    rect(d, 11, 2, 14, 13, (218, 178, 86, 255))
    d.polygon([(14, 3), (42, 4), (46, 7), (42, 12), (14, 12)], fill=(54, 58, 76, 255))
    rect(d, 15, 4, 41, 6, (132, 144, 182, 255))
    rect(d, 16, 7, 38, 8, (182, 92, 255, 255))
    add_outline(gs).save(wdir / "greatsword.png")

    # Longsword (36x12)
    ls = new_img(36, 12)
    d = ImageDraw.Draw(ls)
    rect(d, 2, 5, 8, 6, (112, 74, 48, 255))
    rect(d, 8, 2, 10, 9, (226, 186, 94, 255))
    d.polygon([(10, 4), (32, 4), (34, 5), (32, 7), (10, 7)], fill=(182, 198, 224, 255))
    rect(d, 11, 4, 31, 5, (238, 245, 255, 255))
    add_outline(ls).save(wdir / "longsword.png")

    # Katana Crimson (38x10)
    kc = new_img(38, 10)
    d = ImageDraw.Draw(kc)
    rect(d, 2, 5, 9, 6, (164, 34, 48, 255))
    rect(d, 9, 2, 10, 8, (238, 194, 92, 255))
    rect(d, 11, 4, 33, 5, (232, 240, 252, 255))
    rect(d, 11, 3, 31, 4, (192, 46, 62, 255))
    pset(d, 34, 3, (255, 255, 255, 255))
    pset(d, 35, 3, (232, 240, 252, 255))
    add_outline(kc).save(wdir / "katana_crimson.png")

    # Katana Phantom (38x10)
    kp = new_img(38, 10)
    d = ImageDraw.Draw(kp)
    rect(d, 2, 5, 9, 6, (44, 52, 86, 255))
    rect(d, 9, 2, 10, 8, (110, 232, 242, 255))
    rect(d, 11, 4, 33, 5, (194, 250, 255, 255))
    rect(d, 11, 3, 31, 4, (84, 186, 214, 255))
    pset(d, 34, 3, (255, 255, 255, 255))
    pset(d, 35, 3, (194, 250, 255, 255))
    add_outline(kp).save(wdir / "katana_phantom.png")

    # Bow (20x34)
    bw = new_img(20, 34)
    d = ImageDraw.Draw(bw)
    d.line([(6, 2), (14, 8), (16, 17), (14, 26), (6, 31)], fill=(154, 112, 64, 255), width=2)
    rect(d, 14, 13, 17, 20, (86, 218, 236, 255))
    d.line([(6, 3), (6, 30)], fill=(224, 238, 250, 255), width=1)
    add_outline(bw).save(wdir / "bow.png")

    # Dual Pistol (24x16)
    dp = new_img(24, 16)
    d = ImageDraw.Draw(dp)
    # Back gun
    rect(d, 2, 2, 15, 5, (68, 76, 98, 255))
    rect(d, 2, 5, 6, 9, (116, 76, 48, 255))
    # Front gun
    rect(d, 7, 7, 21, 10, (112, 126, 156, 255))
    rect(d, 18, 7, 21, 8, (110, 242, 255, 255))
    rect(d, 7, 10, 11, 14, (148, 92, 54, 255))
    add_outline(dp).save(wdir / "dual_pistol.png")

    # Wand (18x6) - small slender Harry Potter wooden wand
    wd = new_img(18, 6)
    d = ImageDraw.Draw(wd)
    # Carved dark-walnut ergonomic grip handle
    rect(d, 1, 2, 5, 3, (86, 54, 32, 255))
    rect(d, 1, 2, 4, 2, (122, 79, 48, 255))
    # Tiny antique brass collar ring
    rect(d, 5, 2, 5, 3, (216, 171, 84, 255))
    # Tapered wooden shaft -> 1-px slender tip
    rect(d, 6, 2, 10, 3, (104, 67, 41, 255))
    rect(d, 6, 2, 10, 2, (126, 84, 53, 255))
    rect(d, 11, 2, 14, 2, (126, 84, 53, 255))
    # Subtle luminous arcane spark at tip
    pset(d, 15, 2, (165, 245, 255, 255))
    pset(d, 16, 2, (245, 255, 255, 255))
    add_outline(wd).save(wdir / "wand.png")


def draw_enemies():
    edir = SPRITES / "enemies"
    edir.mkdir(parents=True, exist_ok=True)

    # 1. Armored Sentinel (heavy plate + tower shield)
    e1 = new_img(64, 64)
    d = ImageDraw.Draw(e1)
    rect(d, 20, 14, 44, 56, (66, 72, 92, 255))
    rect(d, 22, 16, 40, 38, (96, 104, 130, 255))
    rect(d, 25, 8, 39, 17, (176, 112, 58, 255))
    rect(d, 28, 12, 36, 14, (255, 112, 62, 255))
    # Giant Tower Shield on left
    rect(d, 12, 18, 24, 54, (124, 134, 158, 255))
    rect(d, 14, 22, 22, 50, (78, 84, 108, 255))
    rect(d, 16, 26, 20, 38, (226, 176, 82, 255))
    add_outline(e1).save(edir / "armored_sentinel.png")

    # 2. Agile Duelist (crimson fencer)
    e2 = new_img(64, 64)
    d = ImageDraw.Draw(e2)
    rect(d, 26, 38, 31, 58, (46, 30, 42, 255))
    rect(d, 34, 38, 39, 58, (46, 30, 42, 255))
    rect(d, 25, 21, 39, 39, (156, 38, 56, 255))
    rect(d, 27, 23, 37, 32, (216, 62, 78, 255))
    rect(d, 27, 10, 37, 20, (226, 228, 238, 255))
    rect(d, 25, 14, 33, 16, (255, 212, 78, 255))
    # Rapier
    rect(d, 6, 28, 26, 30, (218, 232, 248, 255))
    add_outline(e2).save(edir / "agile_duelist.png")

    # 3. Barrier Wraith (floating hexagonal runes)
    e3 = new_img(64, 64)
    d = ImageDraw.Draw(e3)
    d.polygon([(32, 10), (44, 24), (40, 52), (24, 52), (20, 24)], fill=(48, 56, 98, 255))
    d.polygon([(32, 14), (40, 26), (36, 46), (28, 46), (24, 26)], fill=(86, 104, 176, 255))
    rect(d, 28, 20, 36, 24, (148, 245, 255, 255))
    # Floating crystal facets
    rect(d, 13, 24, 17, 36, (112, 234, 255, 255))
    rect(d, 47, 24, 51, 36, (112, 234, 255, 255))
    add_outline(e3).save(edir / "barrier_wraith.png")

    # 4. Sky Hawker (aerial hunter + glowing yellow weakpoint core)
    e4 = new_img(64, 64)
    d = ImageDraw.Draw(e4)
    d.polygon([(6, 20), (24, 26), (26, 36), (12, 30)], fill=(76, 88, 118, 255))
    d.polygon([(58, 20), (40, 26), (38, 36), (52, 30)], fill=(76, 88, 118, 255))
    d.polygon([(32, 14), (41, 30), (32, 46), (23, 30)], fill=(122, 136, 176, 255))
    rect(d, 28, 25, 36, 33, (255, 218, 68, 255))
    rect(d, 30, 27, 34, 31, (255, 255, 210, 255))
    add_outline(e4).save(edir / "sky_hawker.png")

    # 5. Blink Stalker (void assassin)
    e5 = new_img(64, 64)
    d = ImageDraw.Draw(e5)
    d.polygon([(22, 24), (42, 24), (46, 56), (18, 56)], fill=(44, 28, 68, 255))
    rect(d, 25, 13, 39, 24, (68, 42, 102, 255))
    rect(d, 27, 17, 30, 19, (242, 92, 255, 255))
    rect(d, 34, 17, 37, 19, (242, 92, 255, 255))
    rect(d, 14, 34, 24, 37, (192, 96, 255, 255))
    rect(d, 40, 34, 50, 37, (192, 96, 255, 255))
    add_outline(e5).save(edir / "blink_stalker.png")

    # 6. Astral Phantom (ethereal robe specter)
    e6 = new_img(64, 64)
    d = ImageDraw.Draw(e6)
    d.polygon([(32, 8), (45, 28), (48, 54), (32, 48), (16, 54), (19, 28)], fill=(64, 144, 192, 210))
    d.polygon([(32, 14), (40, 30), (36, 44), (28, 44), (24, 30)], fill=(138, 224, 255, 230))
    rect(d, 29, 18, 35, 22, (255, 255, 255, 255))
    add_outline(e6).save(edir / "astral_phantom.png")

    # 7. Training Dummy (48x64)
    dm = new_img(48, 64)
    d = ImageDraw.Draw(dm)
    rect(d, 22, 42, 26, 59, (112, 74, 46, 255))
    rect(d, 14, 57, 34, 60, (92, 60, 38, 255))
    rect(d, 16, 22, 32, 44, (188, 152, 96, 255))
    rect(d, 10, 24, 38, 29, (148, 102, 62, 255))
    rect(d, 19, 10, 29, 21, (206, 172, 112, 255))
    rect(d, 21, 29, 27, 35, (218, 64, 64, 255))
    pset(d, 24, 32, (255, 240, 220, 255))
    add_outline(dm).save(edir / "training_dummy.png")


def draw_world():
    wdir = SPRITES / "world"
    wdir.mkdir(parents=True, exist_ok=True)

    # Solid Tile (16x16)
    ts = new_img(16, 16)
    d = ImageDraw.Draw(ts)
    rect(d, 0, 0, 15, 15, (38, 42, 58, 255))
    rect(d, 0, 0, 15, 2, (74, 84, 112, 255))
    rect(d, 0, 14, 15, 15, (22, 24, 34, 255))
    d.line([(0, 8), (15, 8)], fill=(28, 30, 44, 255))
    d.line([(7, 2), (7, 8)], fill=(28, 30, 44, 255))
    d.line([(12, 8), (12, 15)], fill=(28, 30, 44, 255))
    ts.save(wdir / "tile_solid.png")

    # Wall-Run Runic Tile (16x16)
    tw = new_img(16, 16)
    d = ImageDraw.Draw(tw)
    rect(d, 0, 0, 15, 15, (34, 48, 74, 255))
    rect(d, 1, 1, 14, 14, (46, 66, 98, 255))
    rect(d, 3, 3, 12, 12, (34, 48, 74, 255))
    rect(d, 6, 4, 9, 11, (86, 214, 240, 255))
    rect(d, 4, 7, 11, 8, (148, 242, 255, 255))
    tw.save(wdir / "tile_wallrun.png")

    # Shrine (48x64)
    sh = new_img(48, 64)
    d = ImageDraw.Draw(sh)
    rect(d, 8, 52, 40, 61, (64, 72, 96, 255))
    rect(d, 14, 44, 34, 52, (82, 92, 122, 255))
    d.polygon([(18, 44), (20, 20), (24, 12), (28, 20), (30, 44)], fill=(96, 108, 142, 255))
    d.polygon([(24, 6), (29, 14), (24, 24), (19, 14)], fill=(92, 238, 255, 255))
    rect(d, 22, 26, 26, 42, (92, 238, 255, 255))
    add_outline(sh).save(wdir / "shrine.png")

    # Stage Gate (32x80)
    gt = new_img(32, 80)
    d = ImageDraw.Draw(gt)
    rect(d, 2, 4, 29, 79, (46, 42, 68, 255))
    rect(d, 7, 12, 24, 79, (24, 18, 36, 255))
    rect(d, 10, 16, 21, 76, (148, 68, 212, 180))
    rect(d, 14, 18, 17, 74, (230, 148, 255, 220))
    add_outline(gt).save(wdir / "gate.png")


def main():
    pdir = SPRITES / "player"
    pdir.mkdir(parents=True, exist_ok=True)
    poses = (
        "idle",
        "idle_0",
        "idle_1",
        "run",
        "run_0",
        "run_1",
        "run_2",
        "run_3",
        "air",
        "fall",
        "dash",
        "wallrun",
        "atk_windup",
        "atk_slash",
        "atk_up",
        "atk_thrust",
        "parry",
    )
    for pose in poses:
        draw_player_pose(pose).save(pdir / f"player_{pose}.png")
    draw_weapons()
    draw_enemies()
    draw_world()
    print("Generated all pixel art assets successfully.")


if __name__ == "__main__":
    main()
