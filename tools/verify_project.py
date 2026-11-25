"""Static integrity verification for Blade & Aether Godot 4.3+ sample."""

import re
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent

EXPECTED_PNGS = {
    "assets/sprites/player/player_idle.png": (64, 64),
    "assets/sprites/player/player_idle_0.png": (64, 64),
    "assets/sprites/player/player_idle_1.png": (64, 64),
    "assets/sprites/player/player_run.png": (64, 64),
    "assets/sprites/player/player_run_0.png": (64, 64),
    "assets/sprites/player/player_run_1.png": (64, 64),
    "assets/sprites/player/player_run_2.png": (64, 64),
    "assets/sprites/player/player_run_3.png": (64, 64),
    "assets/sprites/player/player_air.png": (64, 64),
    "assets/sprites/player/player_fall.png": (64, 64),
    "assets/sprites/player/player_dash.png": (64, 64),
    "assets/sprites/player/player_wallrun.png": (64, 64),
    "assets/sprites/player/player_atk_windup.png": (64, 64),
    "assets/sprites/player/player_atk_slash.png": (64, 64),
    "assets/sprites/player/player_atk_up.png": (64, 64),
    "assets/sprites/player/player_atk_thrust.png": (64, 64),
    "assets/sprites/player/player_parry.png": (64, 64),
    "assets/sprites/weapons/greatsword.png": (48, 16),
    "assets/sprites/weapons/longsword.png": (36, 12),
    "assets/sprites/weapons/katana_crimson.png": (38, 10),
    "assets/sprites/weapons/katana_phantom.png": (38, 10),
    "assets/sprites/weapons/bow.png": (20, 34),
    "assets/sprites/weapons/dual_pistol.png": (24, 16),
    "assets/sprites/weapons/wand.png": (18, 6),
    "assets/sprites/enemies/armored_sentinel.png": (64, 64),
    "assets/sprites/enemies/agile_duelist.png": (64, 64),
    "assets/sprites/enemies/barrier_wraith.png": (64, 64),
    "assets/sprites/enemies/sky_hawker.png": (64, 64),
    "assets/sprites/enemies/blink_stalker.png": (64, 64),
    "assets/sprites/enemies/astral_phantom.png": (64, 64),
    "assets/sprites/enemies/training_dummy.png": (48, 64),
    "assets/sprites/world/tile_solid.png": (16, 16),
    "assets/sprites/world/tile_wallrun.png": (16, 16),
    "assets/sprites/world/shrine.png": (48, 64),
    "assets/sprites/world/gate.png": (32, 80),
}

AUTOLOADS = [
    "scripts/autoload/element_registry.gd",
    "scripts/autoload/weapon_registry.gd",
    "scripts/autoload/hitstop_manager.gd",
    "scripts/autoload/sfx_manager.gd",
    "scripts/autoload/game_state.gd",
]

FORBIDDEN_GODOT3_OR_44 = [
    (re.compile(r"\bKinematicBody2D\b"), "Godot 3 KinematicBody2D"),
    (re.compile(r"\bPoolVector2Array\b"), "Godot 3 PoolVector2Array"),
    (re.compile(r"\byield\s*\("), "Godot 3 yield()"),
    (re.compile(r"\brand_range\s*\("), "Godot 3 rand_range()"),
    (re.compile(r"\.instance\s*\("), "Godot 3 .instance()"),
    (re.compile(r"(?m)^\s*export\s+var\b"), "Godot 3 export var"),
    (re.compile(r"\bDictionary\s*\["), "Godot 4.4-only typed Dictionary[...]"),
    (re.compile(r"\bmove_and_slide\s*\(\s*[^)]+\)"), "Godot 3 move_and_slide(args)"),
]


def check_pngs(errors: list) -> None:
    for rel, expected_size in EXPECTED_PNGS.items():
        p = ROOT / rel
        if not p.exists():
            errors.append(f"Missing PNG: {rel}")
            continue
        with Image.open(p) as im:
            if im.mode != "RGBA" or im.size != expected_size:
                errors.append(f"Invalid PNG {rel}: mode={im.mode}, size={im.size}, expected RGBA {expected_size}")


def check_res_paths(errors: list) -> None:
    res_pat = re.compile(r'["\'](res://[^"\']+)["\']')
    files = [ROOT / "project.godot"] + list(ROOT.rglob("*.tscn")) + list(ROOT.rglob("*.gd"))
    for f in files:
        if not f.is_file() or ".godot" in f.parts:
            continue
        txt = f.read_text(encoding="utf-8")
        for m in res_pat.finditer(txt):
            full_res = m.group(1)
            rel = full_res[len("res://"):]
            if "%s" in rel:
                if "player_%s.png" in rel:
                    for pose in ("idle", "idle_0", "idle_1", "run", "run_0", "run_1", "run_2", "run_3", "air", "fall", "dash", "wallrun", "atk_windup", "atk_slash", "atk_up", "atk_thrust", "parry"):
                        expanded = ROOT / rel.replace("%s", pose)
                        if not expanded.exists():
                            errors.append(f"Broken expanded path in {f.relative_to(ROOT)}: {expanded}")
                elif "enemies/%s.png" in rel:
                    for arch in ("training_dummy", "armored_sentinel", "agile_duelist", "barrier_wraith", "sky_hawker", "blink_stalker", "astral_phantom"):
                        expanded = ROOT / rel.replace("%s", arch)
                        if not expanded.exists():
                            errors.append(f"Broken expanded path in {f.relative_to(ROOT)}: {expanded}")
                continue
            target = ROOT / rel
            if not target.is_file():
                errors.append(f"Broken res:// path in {f.relative_to(ROOT)}: {full_res}")


def check_autoloads(errors: list) -> None:
    for rel in AUTOLOADS:
        p = ROOT / rel
        if not p.exists():
            errors.append(f"Missing autoload script: {rel}")
            continue
        txt = p.read_text(encoding="utf-8")
        if re.search(r"(?m)^\s*class_name\b", txt):
            errors.append(f"Autoload {rel} must NOT declare class_name!")


def check_gdscripts(errors: list) -> None:
    for p in sorted(ROOT.rglob("*.gd")):
        rel = p.relative_to(ROOT)
        lines = p.read_text(encoding="utf-8").splitlines()
        in_multiline = False
        for i, line in enumerate(lines, 1):
            stripped = line.lstrip("\t ")
            if not stripped:
                continue
            indent = line[: len(line) - len(stripped)]
            if " " in indent and not in_multiline:
                # Allow space-aligned continuation only inside parens/dicts if no tabs+spaces mixed,
                # but flag any leading spaces on code lines since rule requires tabs exclusively
                errors.append(f"{rel}:{i}: Space indentation found (use tabs exclusively)")
            if "\t" in indent and " " in indent:
                errors.append(f"{rel}:{i}: Mixed tabs and spaces in indentation")

        full = "\n".join(lines)
        for pat, desc in FORBIDDEN_GODOT3_OR_44:
            if pat.search(full):
                errors.append(f"{rel}: Forbidden pattern ({desc})")

        _check_delimiters(rel, full, errors)


def check_shaders(errors: list) -> None:
    for p in sorted(ROOT.rglob("*.gdshader")):
        rel = p.relative_to(ROOT)
        txt = p.read_text(encoding="utf-8")
        if re.search(r"\bmodulate\b", txt):
            errors.append(f"{rel}: Uses undefined 'modulate' identifier in Godot 4 shader")
        _check_delimiters(rel, txt, errors)


def _check_delimiters(rel: Path, text: str, errors: list) -> None:
    # Strip string literals and comments roughly to verify (), [], {} balance
    cleaned = []
    i = 0
    n = len(text)
    in_str = None
    in_comment = False
    comment_prefix = "#" if rel.suffix == ".gd" else "//"
    while i < n:
        ch = text[i]
        if in_comment:
            if ch == "\n":
                in_comment = False
                cleaned.append(ch)
            i += 1
            continue
        if in_str:
            if ch == "\\" and i + 1 < n:
                i += 2
                continue
            if ch == in_str:
                in_str = None
            i += 1
            continue
        if text.startswith(comment_prefix, i):
            in_comment = True
            i += len(comment_prefix)
            continue
        if ch in ('"', "'"):
            in_str = ch
            i += 1
            continue
        cleaned.append(ch)
        i += 1

    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for ch in cleaned:
        if ch in "([{":
            stack.append(ch)
        elif ch in ")]}":
            if not stack or stack[-1] != pairs[ch]:
                errors.append(f"{rel}: Unbalanced delimiter '{ch}'")
                return
            stack.pop()
    if stack:
        errors.append(f"{rel}: Unclosed delimiters remaining: {stack}")


def main() -> int:
    errors: list = []
    check_pngs(errors)
    check_res_paths(errors)
    check_autoloads(errors)
    check_gdscripts(errors)
    check_shaders(errors)

    gd_count = len(list(ROOT.rglob("*.gd")))
    png_count = len(list(ROOT.rglob("*.png")))
    if errors:
        print(f"VERIFICATION FAILED ({len(errors)} issues):")
        for e in errors:
            print(" -", e)
        return 1
    print(f"VERIFICATION PASSED: {png_count} PNGs, {gd_count} GDScripts, 1 shader, project.godot, main.tscn verified clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
