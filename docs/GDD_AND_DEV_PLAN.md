# Blade & Aether — Master Development Plan & GDD

## 1. High Concept & Design Pillars
- **Genre**: Fast-paced 2D Action Hack-and-Slash / Interconnected Metroidvania (**Non-Roguelike**).
- **References**:
  - *BlazBlue Entropy Effect*: Crisp fighting-game combat feel, directional launchers/dives, hit-confirm cancels (Dash, Jump, Switch-Attack), hitstop (`2-6f` at `60 FPS`), screen shake, afterimages, elemental combos.
  - *The Rogue Prince of Persia*: Fluid parkour integration—background wall-running, wall-jumping, enemy vaulting for rear openings & movement reset, wall-splat physics.
- **Anti-Stiffness Guarantees**:
  - Hit-confirm universal cancel across all weapon classes (never get animation-locked after landing a hit).
  - Real-time cycling between equipped elements (`E` / `LB`) and 1-button Quick-Swap (`Q` / `RB`) with an immediate **Switch-Attack**.
  - Parkour actions double as combat resets (Enemy Vault refreshes Air-Dash & Wall-Run; shooting Bow/Dual Pistols works seamlessly while airborne or wall-running).

---

## 2. World Structure (Interconnected Metroidvania, Non-Roguelike)
- **Full Target Scale**: 5 interconnected biomes + 1 Sanctuary Hub (`50–65` handcrafted rooms), 4 Metroidvania traversal gates, 5 Bosses, loop shortcuts, and Prep Shrines before major zones/bosses.
- **Sample Vertical Slice Included**:
  1. `room_sanctuary`: Prep Shrine (`[F]`), Training Dummy, Zone Intel, right `StageGate` (locks Deployment Kit), left return ledge from shortcut.
  2. `room_bastion` (Sunken Bastion): Multi-tier arena with Wall-Run shaft, `Armored Sentinel`, `Barrier Wraith`, `Agile Duelist`.
  3. `room_spire` (Astral Spire): Vertical Wall-Run tower, `Sky Hawker`, `Blink Stalker`, `Astral Phantom`, and one-way Shortcut Lever back to `Sanctuary`.
- **Death & Persistence**: Respawning returns player to Sanctuary with full HP & refilled pouch. Unlocked weapons, weapon levels/EXP, Mastery Shards, visited rooms, and opened shortcuts **never reset**.

---

## 3. Tactical Pre-Stage Expedition Lock
Player cannot freely open global Stash or change weapons/EQ mid-stage:
- **Deployment Kit (Editable ONLY in Prep Zones / Shrines)**:
  - **2 Weapon Slots**: Only 2 weapons can be brought into combat.
  - **1 Armor / Cloak**: Defensive profile + elemental/mobility bonus.
  - **2 Combat Mods**: Passive/triggered playstyle modifiers (e.g., Afterimage Dash, Launcher Shockwave, Perfect Dodge Reset, Flux Siphon).
  - **2 Active Elements**: Selected from 5 unlocked elements (`Fire`, `Ice`, `Lightning`, `Wind`, `Void`) for infusion & cross-element reactions.
  - **4-Slot Item Pouch**: Strict per-expedition consumable stack limits (`Healing Flask`, `Flux Tonic`, `Overdrive Oil`, `Stagger Bomb`).
- **Stage Lock Rule**: Crossing `StageGate` locks the Deployment Kit until returning to Sanctuary / Prep Shrine. Key Items & Metroidvania Traversal Abilities live in permanent slots outside the Item Pouch to guarantee zero softlocks.
- **Zone Intel**: Prep UI shows each area's dominant enemy archetypes and recommended counter weapons/elements before deployment.

---

## 4. Weapon Roster, Balance & Dual Katana (Option A)

### Soft-Counter Balance Principle
No enemy has `0` physical/weapon immunity. Any weapon can damage any monster through Elemental Infusion, Parry, and Vaulting; however, counter weapons break enemy defenses **`2.4×–3.0×` faster** and trigger large stagger openings.

| Weapon Type | Scaling (Phys / Elem / Poise) | Core Playstyle | Counter Role (Monster) |
| :--- | :--- | :--- | :--- |
| **Greatsword** | `1.35×` / `0.85×` / `1.60×` | Heavy cleave, hyper-armor, extreme wall-splat knockback | **Armored Sentinel** (Armor Bar) |
| **Longsword** | `1.05×` / `1.00×` / `1.00×` | Balanced duelist, smooth cancel routes, enhanced Parry Riposte | **Agile Duelist** (Parry-Check) |
| **Katana (Single / Dual)** | `0.90×` (`0.62×`/blade) / `1.05×` / `0.65×` | Fastest hit-count, dash-through slashes, Iaido burst | **Barrier Wraith** (10-Hit Shield) |
| **Bow** | `1.00×` (`1.45×` Weakpoint) / `1.15×` / `0.85×` | Charged piercing shots, Kick-Vault aerial shots, weakpoint sniping | **Sky Hawker** (Aerial Weakpoint) |
| **Dual Pistol** | `0.70×` / `1.10×` / `0.40×` | Gun-Fu mobility, Air-Stall, Active Dash-Reload, status pressure | **Blink Stalker** (Teleports + Regen) |
| **Wand** | `0.45×` / `1.85×` / `0.75×` | Elemental Catalyst, Flux bursts, AoE Reaction Detonate | **Astral Phantom** (75% Phys Resist) |

### Dual Katana — Option A (2-Slot Commitment)
- Equipping **two distinct Katanas** in **Slot 1** and **Slot 2** automatically activates **Dual Katana Mode**:
  - Each blade uses `0.62×` per-hit physical scaling (`~1.24×` if full double-flurry lands), disabled hold-guard, and lower poise per hit (`0.50×`).
  - Pressing Swap (`Q` / `RB`) swaps **Main-Hand <-> Off-Hand** via a rapid *Switch-Slash*, switching active Primary Trait & dominant Element mid-combo.
  - **Combine Art (`U` / Special at Lv 3+)**: Executes both Katanas' traits simultaneously (`Primary Trait` + `Secondary Modifier`) and infuses both active elements at once to trigger an immediate self-contained **Elemental Reaction**.

---

## 5. Weapon Leveling (Lv 1–5) & Non-Duplicate Drops
- **Weapon Levels (Lv 1–5)** via Combat EXP or `Mastery Shards` at Shrine:
  - **Lv 1**: Base 3-hit ground combo + 2-hit air combo.
  - **Lv 2**: Directional Arts (`Up + Attack` Launcher, `Down + Attack` Dive/Slam).
  - **Lv 3**: Signature Elemental Art (`U` / `RT`) + Dual Katana Combine Art.
  - **Lv 4**: Switch-Attack (`Q` / `RB` on hit-confirm) + Mobility/Flow bonus.
  - **Lv 5**: Mastery Ultimate (`Down + U`) + Enhanced Elemental Infusion (`1.35×` status & elemental burst).
- **Non-Duplicate Drop & Pity System**:
  - Specific enemy archetypes drop specific unique weapons (`gs_obsidian`, `kt_phantom`, `bw_tempest`, `dp_viper`).
  - Once `weapon_id` exists in `GameState.stash.unlocked_weapons`, its drop weight becomes **`0%`** permanently; subsequent drops convert automatically into **`Mastery Shards`**.
  - **Escalating Pity**: Regular/elite drops start at `35%` in sample (`15%` in full game) and increase by `+35%` (`+15%` full game) per kill without drop—guaranteeing no endless RNG grind.

---

## 6. Elemental Infusion & Cross-Reactions
- **5 Elements**: `Fire` (Burn DoT), `Ice` (Chill -> Freeze/Shatter), `Lightning` (Shock chain), `Wind` (Gale lift/juggle), `Void` (Corrosion -resist & anti-heal).
- **Selected Reactions**:
  - `Fire + Ice` -> **Thermal Shatter** (Massive burst + AoE wave).
  - `Lightning + Wind` -> **Storm Pull** (Vortex draw + multi-shock).
  - `Fire + Lightning` -> **Overload** (Explosive knockback + stagger).
  - `Ice + Wind` -> **Frost Nova** (Wide chill burst).
  - `Void + Any` -> **Astral Implosion** (Armor/Resist shred + stagger reset).

---

## 7. Production Architecture & Phased Roadmap (46 Weeks)
- **Virtual Resolution**: `640×360` (`16×16` tiles, `64×64` sprites, `Nearest` texture filter, `60 Hz` fixed physics).
- **Godot 4 Architecture**:
  - Autoloads: `ElementRegistry`, `WeaponRegistry`, `HitstopManager` (local actor freeze, never pauses `InputBuffer`), `GameState` (Stash vs locked `DeploymentKit`, atomic JSON saves).
  - Data-Driven Combat: `WeaponData` -> `MoveData` resources with explicit frame timings (`startup`, `active`, `recovery`, `cancel_from_frame`).
- **Roadmap**:
  - **Weeks 1–3**: Setup, World Graph & anti-softlock audit.
  - **Weeks 4–8**: Greybox Combat & Parkour Gym (2 starter weapons, 2 elements, `MoveData`, hitstop, wall-run, vault).
  - **Weeks 9–17**: Metroidvania Core & Vertical Slice (Biome 1, all 6 weapon types, Dual Katana, Non-Duplicate Drop + Pity, Prep Shrine lock).
  - **Weeks 18–34**: Whitebox Biomes 2–5 -> Full Art Pass (Aseprite + Normal Maps + 2D Lights).
  - **Weeks 35–42**: Balancing Matrix (6 weapons × 6+ archetypes × 5 bosses), QA & 60 FPS optimization.
  - **Weeks 43–46**: Public Demo (Steam Next Fest), Telemetry tuning, PC Launch.
