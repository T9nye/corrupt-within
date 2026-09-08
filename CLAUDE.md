# Corrupt Within

Roblox open-world action RPG. Solo project by Ye (github.com/T9nye). This file is
context for Claude Code — read it, then read whatever file in `docs/` is relevant
to the task at hand. Don't read all of `docs/` every session.

## Read this first

- I am new to Roblox Studio and to Luau. Explain what code does and why, don't
  just hand me a file. When you introduce a Roblox API I haven't used, say what
  it is in one line.
- The map comes before combat. I'm building environments first on purpose.
- When something in this repo conflicts with what's actually in the Studio place
  file, **the place file wins**. Read the live state instead of trusting a doc.

## Current state

**A complete vertical slice exists**: loading screen → main menu → a
playable Haven with movement, combat, one live enemy, loot, and persistence.
Phases 1–3 are done; 4 and 5 have their reusable framework built but not
their real content (no Wilds, no itemization). Last updated 2026-09-08.

### The map (lives in the place file, not this repo)

The Haven is fully blocked out and detailed: plaza, finished blacksmith,
black market, three outer merchant shells, general merchant stall,
quest/party boards, a shrine, three residential shells, training yard, well,
mine entrance, connective paths with lamp posts, mid-ring clutter, and
**interiors in every building except the blacksmith** (counters/shelving in
the shops, beds/hearths in the houses — see git history for the full list).
Terrain and lighting passes are done — muted palette, overcast Realistic
lighting, low sun, Atmosphere haze, warm PointLights on lamps and the forge.

**Known drift:** `ResidentialShell_3` has been moved in the place file since
it was built — it now sits at (−86, −55) with rotation 0°, not (−83, −115) at
10°. Its interior was built to the live position.

### Code — every system below is Rojo-synced AND verified in a real playtest

| System | Owns | Files |
| --- | --- | --- |
| Movement | Stamina, 3 dash charges (independent regen timers), i-frames, sprint FOV | `MovementService`, `MovementController` |
| HUD | Stamina bar, 3 discrete dash-charge bars | `HUDController` |
| Weapons | Building/equipping the held weapon | `WeaponService` |
| Combat | All damage, hitboxes, combo state | `CombatService`, `CombatController` |
| Enemies | Registry, AI tick loop (patrol/aggro/attack/death) | `EnemyService`, `Enemy/BaseEnemy` |
| Loot | Rarity rolls, item creation | `LootService` |
| Data | ProfileStore profiles: level/XP, weapon levels, corruption mastery, skill points, inventory, cosmetics, settings, region | `DataService` |
| Test target | Training dummy health/reset | `TrainingDummyService` |
| Menu/spawn gate | `CharacterAutoLoads = false`; spawns only on request | `MenuService` |
| Loading + main menu | Real preload progress, profile-loaded gate, PLAY/CUSTOMIZE/SETTINGS | `MenuController` |
| Customize | Real avatar preview, body colour/outfit, persists | `CustomizeController` |
| Settings | Volume/FOV/quality/keybinds, ONE reusable panel | `SettingsController` |
| Shared UI | Buttons/panels/sliders used by all four UI controllers | `client/UI/UIKit` |

**Three architectural decisions worth not re-litigating:**

1. **Services coordinate through character attributes**, not by requiring
   each other — `Attacking`, `Dashing`, `HeavyWindup`, `Invulnerable`,
   `BlocksLight`, `EquippedWeapon`. Keeps Combat/Movement/Enemy/Weapons free
   of the circular Knit dependencies `architecture.md` warns about.
2. **The client predicts, the server rules.** Client sends "light"/"heavy",
   "I want to sprint", "I want to dash" — never a position, target, damage
   figure, or stamina/charge count. The server rebuilds everything from its
   own state and republishes the truth as Player attributes.
3. **`require()` caches modules, so config tables are shared mutable state
   across every script that requires them.** `SettingsController` writes
   `MovementConfig.DefaultFOV` directly and `MovementController`'s existing
   per-frame read of that field just sees the new value — no signal needed.
   Useful; also means nothing stops a bug elsewhere from mutating a config
   table by accident. Nothing does today, but it's worth knowing this is how
   FOV settings actually reach movement code.

### Verified working — actually playtested this session, not just compiled

- Full loading→menu→PLAY flow: real preload progress, profile-loaded gate,
  character-less menu, spawn-on-request, camera handoff.
- Customize: live avatar preview recolors correctly, Confirm persists to the
  profile, and the SAME colours reapply to the real character on next spawn
  (survived a full stop/restart of the server, i.e. a fresh profile load).
- Settings: every slider/toggle persists, is clamped server-side, and (FOV,
  graphics quality) actually takes effect; keybind display matches the real
  bound keys because both read `InputConfig`.
- Dash: burst of 3 refused a 4th; all 3 charges returned together, each
  exactly 3.0s after its OWN spend time (not queued 3/6/9s).
- Combat: light chain deals exactly 10/10/14, heavy 28; Rotbound Brute
  blocks light (0 dmg) and takes heavy (28); an unarmed character is refused
  and deals 0.
- Enemies: two Husks spawn near the training yard and patrol independently;
  killing one doesn't affect the other; enemy attacks respect the dash's
  `Invulnerable` attribute.
- Loot→Data: a live Husk kill produced XP and a correctly-shaped item in the
  killer's profile; the rarity table held to its configured weights across
  10,000 rolls.
- A fresh player spawns at `MaxHealth = 112`, proving `DataService` actually
  loaded a profile and applied `progression.md`'s health formula.

### Stubbed or deliberately incomplete

- `CorruptionConfig.lua` is still an empty table. Phase 6.
- **No itemization system.** `LootService` produces real items
  (`{id, source, rarity, statMultiplier, hasAffix, passiveCorruptionPerSecond}`)
  but there are no item names, types, or equip slots. `passiveCorruptionPerSecond
  = 0.1` for Corrupted gear is an invented rate — no doc specifies one.
- **Corrupt Wisp's corruption-on-contact** is a marked `TODO(Phase 6)` hook.
- **Sword abilities** (Riposte / Corrupt Slash / Severance) have numbers in
  `WeaponConfig` but no implementation.
- **No enemy or player art.** Grey-box boxes built in code; outfit "presets"
  in Customize are colour tints, not armour models — no clothing assets exist.
- **No attack animations.** Swings deal damage with no visual tell.
- **The Wilds does not exist.** Two Husks spawn in the training yard from a
  `TEST_SPAWNS` table in `EnemyService`, explicitly marked TEMPORARY — the
  Haven is meant to be a no-combat safe zone.
- **Mouse sensitivity doesn't do anything live.** `UserGameSettings.MouseSensitivity`
  cannot be written by a normal game script at all (confirmed live, not
  assumed — see below). The value persists; it has no effect yet.

### Six real bugs this session's playtesting caught (none were guessed at)

1. The menu's background camera orbit (`RenderStepped`) was never stopped
   when Customize took the camera, so it fought Customize's framing every
   frame. Fixed with an explicit `MenuController:StopBackgroundCamera()`.
2. Customize's camera sat on the wrong side of the preview rig and showed
   its back — a Roblox character faces -Z by default.
3. `UserGameSettings.MouseSensitivity` is a hard platform write restriction
   ("lacking capability RobloxScript"), not a permissions bug. Real fix
   means replacing Roblox's default camera control scripts entirely.
4. Settings' FOV only wrote `camera.FieldOfView` while `CameraType` was
   already `Custom`, which it never is during the menu — silently never
   applied on spawn until fixed to re-apply when PLAY restores `Custom`.
5. `Player.CharacterAppearanceLoaded` did not fire at all in Play Solo
   testing (confirmed by forcing a respawn and watching for it) — fixed by
   applying cosmetics on both `CharacterAdded` and that event.
6. Recoloring "every BasePart except Accessories" also recoloured the welded
   sword, since `WeaponService` parents it directly onto the character.
   Fixed with an explicit whitelist of real body part names.

### Open questions needing Ye's decision

- **Crafting station** is in `haven-build.md`'s "What's in it" table but was
  never built. Needs a placement decision.
- **`LayoutGuide`** blueprint decal is still on the ground and shows through
  in open areas. Remove, or keep as reference?
- **All `(new)`-marked numbers** in `WeaponConfig`/`EnemyConfig` — hitbox
  sizes, commitment windows, enemy speeds/ranges, XP values, dash regen time
  — are invented, not from docs. Want a real playtest pass with a mouse.
- **Outfit presets are colour tints, not armour** — the most visibly
  unfinished part of Customize, matching the grey-box rule but worth knowing.

### Toolchain

Rokit, Rojo 7.7.0, Wally 0.3.2 installed; `wally install` has been run, so
`Packages/`/`ServerPackages/` exist locally (gitignored — regenerate with
`wally install`). `wally.toml`/`wally.lock` pin Knit 1.7.0 and ProfileStore
1.0.3. Config modules populated: `MovementConfig`, `WeaponConfig`,
`EnemyConfig`, `ProgressionConfig`, `InputConfig`, `SettingsConfig`,
`CosmeticsConfig`, `UIConfig`. `CorruptionConfig` is still an empty stub.

Update this section when the phase changes. It is the only part of this file
that goes stale.

## Docs map

| File | What's in it |
| --- | --- |
| `docs/game-overview.md` | Genre, loop, regions, monetization, MVP scope |
| `docs/corruption.md` | The corruption meter — the game's core hook |
| `docs/combat.md` | Attack chain, the five weapons, sword moveset |
| `docs/enemies.md` | The five starter enemies, Rootmaw dungeon, Hollow Warden |
| `docs/progression.md` | Levels, XP, loot rarity, skill tree, first-pass numbers |
| `docs/architecture.md` | Rojo/Wally/Knit setup, folder layout, code conventions |
| `docs/haven-build.md` | The Last Haven layout, scale, palette, lighting |
| `docs/build-order.md` | The 8-phase plan from setup to playable MVP |

## Toolchain

Rokit (toolchain manager) → Rojo 7 (file sync) → Wally (packages) →
Knit (service framework) → ProfileStore (data persistence).

Common commands:

```bash
rojo serve          # start sync, then connect from the Rojo Studio plugin
rojo build -o build.rbxlx
wally install       # after editing wally.toml
```

## Conventions

- Server code in `src/server`, client in `src/client`, shared in `src/shared`.
- Anything a designer would want to tune (damage, XP curves, corruption rates,
  drop rates) goes in a config ModuleScript under `src/shared/config`, never
  hardcoded in a service.
- Services are Knit services. One service per responsibility. Name them
  `CombatService`, `CorruptionService`, `LootService` — not `Main` or `Handler`.
- Client never decides damage or loot. The client asks; the server rules.

## Things to remember about the Roblox API

- `Lighting.Technology` no longer exists. Use `Lighting.LightingStyle = Enum.LightingStyle.Realistic`.
- Prefer `Task.wait()` over `wait()`, `WaitForChild` over blind indexing.

## What I don't want

- Don't scaffold ten files at once. One system at a time, tested in Studio
  before moving on.
- Don't buy complexity with pay-to-win. Monetization is cosmetics only —
  see `docs/game-overview.md`.
- Don't silently change tuning numbers in `docs/progression.md`. Tell me first.
