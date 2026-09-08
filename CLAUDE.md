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

**Phase 5 groundwork.** Phases 1–3 are done; 4 and 5 have their reusable
framework built but not their content. Last updated 2026-09-08.

### The map (lives in the place file, not this repo)

The Haven is fully blocked out: plaza, finished blacksmith, black market,
three outer merchant shells, general merchant stall, quest/party boards, a
shrine on the plaza→blacksmith path, three residential shells, training yard,
well, mine entrance, connective paths with lamp posts, and mid-ring clutter.
Terrain and lighting passes are done — muted palette, overcast Realistic
lighting, low sun, Atmosphere haze, warm PointLights on lamps and the forge.

### Code (all Rojo-synced, all verified running in a playtest)

| System | Owns | Files |
| --- | --- | --- |
| Movement | Stamina, dash charges, i-frames | `MovementService`, `MovementController` |
| HUD | Stamina bar, dash pips | `HUDController` |
| Combat | All damage, hitboxes, combo state | `CombatService`, `CombatController` |
| Enemies | Registry, AI tick loop, drops | `EnemyService`, `Enemy/BaseEnemy` |
| Data | ProfileStore profiles, XP, levels | `DataService` |
| Test target | Training dummy health/reset | `TrainingDummyService` |

**Two architectural decisions worth not re-litigating:**

1. **Services coordinate through character attributes**, not by requiring each
   other — `Attacking`, `Dashing`, `HeavyWindup`, `Invulnerable`, `BlocksLight`.
   This is what keeps Combat/Movement/Enemy free of the circular Knit
   dependencies `architecture.md` warns about. Keep using this pattern.
2. **The client predicts, the server rules.** Client sends "light"/"heavy" and
   "I want to sprint" — never a position, target, damage figure or stamina
   value. The server rebuilds everything from its own state.

### Verified working (playtested 2026-09-08, not just compiled)

- Knit starts clean on server and client.
- Light chain deals exactly 10 / 10 / 14, heavy deals 28.
- Rotbound Brute blocks light (0 damage) and takes heavy (28) — as `enemies.md` specifies.
- Husk spawns, patrols, aggros.
- Player spawns with `MaxHealth = 112` — proof `DataService` loaded a profile
  and applied `progression.md`'s `100 + level*12`.
- Stamina/DashCharges replicate to the client as Player attributes.

### Stubbed or deliberately incomplete

- `CorruptionConfig.lua` is still an empty table. Phase 6.
- **Loot**: `BaseEnemy:RollDrop()` rolls a real rarity using
  `progression.md`'s weights, but nothing converts a rarity into an item.
  `LootService` doesn't exist.
- **Corrupt Wisp's corruption-on-contact** is a marked `TODO(Phase 6)` hook.
- **Sword abilities** (Riposte / Corrupt Slash / Severance) have numbers in
  `WeaponConfig` but no implementation. Phase 6+.
- **No enemy art** — grey-box boxes built in code.
- **The Wilds does not exist.** One Husk spawns in the training yard from a
  `TEST_SPAWNS` table in `EnemyService`, explicitly marked TEMPORARY. Delete
  it when the Wilds gets real spawners — the Haven is meant to be no-combat.

### Open questions needing Ye's decision

- **Crafting station** is in `haven-build.md`'s "What's in it" table but was
  never built. Needs a placement decision.
- **`LayoutGuide`** blueprint decal is still on the ground and now shows
  through in open areas. Remove, or keep as reference?
- **All `(new)`-marked numbers** in `WeaponConfig`/`EnemyConfig` are invented,
  not from docs — hitbox sizes, commitment windows, enemy speeds/ranges, XP
  values. These want a playtest pass.

### Toolchain

Rokit, Rojo 7.7.0, Wally 0.3.2 installed; `wally install` has been run, so
`Packages/`/`ServerPackages/` exist locally (gitignored — regenerate with
`wally install`). `wally.toml`/`wally.lock` pin Knit 1.7.0 and ProfileStore
1.0.3. Config modules: `MovementConfig`, `WeaponConfig`, `EnemyConfig`,
`ProgressionConfig` are populated; `CorruptionConfig` is still an empty stub.

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
