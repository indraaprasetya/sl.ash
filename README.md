# Blade & Aether — Playable Godot 4 2D Hack & Slash Sample

A playable **Godot 4.3+** vertical slice demonstrating fast-paced 2D Hack & Slash combat (*BlazBlue Entropy Effect* + *The Rogue Prince of Persia* flow) inside a non-roguelike **Interconnected Metroidvania** framework with `640×360` pixel art, a heroic articulated 60 FPS `PixelRig`, and 133 unique weapon moves across 6 archetypes (`Greatsword`, `Longsword`, `Katana` single/dual, `Bow`, `Dual Pistol`, and slender wooden `Wand`).

## How to Run
### Option 1: One-Command Launcher (`run.bat`)
From the project root in PowerShell or Command Prompt:
- Play immediately: `.\run.bat`
- Open in Godot Editor: `.\run.bat --editor`

### Option 2: Direct PowerShell Command (WinGet Install)
WinGet installs Godot 4 without adding a `godot` alias to `PATH`. Run from the project root:
```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --path .
```
(Or open Godot 4, import `project.godot`, and press **F5**.)

## Controls (Keyboard / Gamepad)

| Action | Keyboard | Gamepad | Notes |
| :--- | :--- | :--- | :--- |
| Move / Aim | `A / D`, `W / S` | Left Stick / D-Pad | Hold `W` / `S` for directional moves |
| Jump / Wall-Jump | `Space` | `A` / Cross | Variable height, Coyote Time, Jump Buffer |
| Light / Primary Attack | `J` | `X` / Square | 4-hit ground, 3-hit air, `W+J` Launcher, `S+J` Dive (Lv 2+) |
| Heavy / Secondary Attack | `K` | `Y` / Triangle | `K` -> `K` heavy chain, `W+K` / `S+K` directional heavies |
| Signature Art / Ultimate | `U` (`S+U` Ult) | `RT` | Elemental Skill (Lv 3+), Dual Combine (Lv 3+), Ultimate (Lv 5) |
| Dash / Air-Dash | `L` or `Shift` | `B` / Circle | i-frames, hit-confirm cancel, Active Dual Pistol Reload |
| Parry / Deflect | `I` | `LT` | Longsword triggers Elemental Riposte |
| Enemy Vault | `C` | `R3` / Press near enemy | Leap over enemy, micro-stun, reset Air-Dash & Wall-Run |
| Quick-Swap Weapon | `Q` | `RB` | Swaps Slot 1 <-> Slot 2; on hit-confirm triggers **Switch-Attack** |
| Cycle Active Element | `E` | `LB` | Switches between your 2 equipped elements in real time |
| Interact / Prep Shrine / Gate | `F` | `Select` / Back | Open Prep Loadout (Sanctuary only) or pull Shortcut Lever |
| Use Item Pouch | `1` – `4` | — | Uses limited expedition items (`Flask`, `Flux Tonic`, etc.) |
| Debug Hitbox / Slow-Mo | `F9` / `F10` | — | Inspect frame windows, hitboxes, or `0.25×` slow-motion |

## Key Features to Test
1. **Locked Pre-Stage Kit**: Press `F` at the **Sanctuary Shrine** to customize your 2 Weapons, 1 Armor, 2 Combat Mods, 2 Elements, and 4 Pouch Items. Walk right across the **Stage Gate** into *Sunken Bastion*—try pressing `F` or opening prep; the HUD shows `[LOCKED IN STAGE]`.
2. **Non-Duplicate Weapon Drops + Pity**: Defeat the **Armored Sentinel** (drops `gs_obsidian`), **Barrier Wraith** (drops `kt_phantom`), **Sky Hawker** (drops `bw_tempest`), and **Blink Stalker** (drops `dp_viper`). Killing them again converts duplicate drops into **Mastery Shards**.
3. **Dual Katana (Option A)**: Return to Sanctuary after unlocking `Phantom Gale` (or click `[Sample Test] Unlock All` in the Prep Shrine) and equip **Crimson Edge + Phantom Gale** in Slots 1 & 2. Pressing `U` executes **Dual Combine Art** firing both traits and both equipped elements for an instant reaction.
4. **Wall-Run & Shortcut Loop**: Run along the glowing runic **Wall-Run panels** in *Sunken Bastion* and *Astral Spire*, unlock the **Shortcut Lever** in *Astral Spire*, and drop directly back into *Sanctuary*.
5. **Weapon Leveling & 133 Distinct Moves (Lv 1–5)**: Fight enemies to earn Weapon EXP or spend Mastery Shards at the Shrine to unlock Directional Arts (Lv 2), Signature Art (Lv 3), Switch-Attack (Lv 4), and Mastery Ultimate (Lv 5) across 31 archetype-exclusive swing styles and bespoke pixel VFX.

## Development & Verification
- Static project check: `python tools/verify_project.py`
- Regenerate pixel assets: `python tools/generate_pixel_assets.py` (requires Pillow)
