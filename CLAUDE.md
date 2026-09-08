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

- **Phase:** 2 — Haven blockout is functionally complete; movement (sprint +
  dash) is the first gameplay system, built and wired through Rojo.
- **Done (Haven, in Studio):** plaza, finished blacksmith, black market, three
  outer merchant shells, the plaza's general merchant stall, quest/party
  boards, a shrine (on the plaza-to-blacksmith path, not hidden), three
  residential shells (varied footprint + rotation), a training yard with
  dummies, a well, the mine entrance, connective paths with lamp posts (gate,
  blacksmith, west buildings, training yard), and mid-ring clutter (crates,
  carts, barrels). Terrain pass done — muted ground/terrain palette, gentle
  elevation at the gate approach. Lighting pass done — overcast Realistic,
  low sun angle, Atmosphere haze, warm PointLights on every lamp and the
  forge.
- **Done (code):** Knit bootstrapped for the first time —
  `src/server/init.server.lua` and `src/client/init.client.lua` exist and
  call `Knit.Start()`. First system: `MovementService` (server) owns stamina
  drain/regen and validates dash cooldowns/i-frames; `MovementController`
  (client) predicts sprint speed and dash movement locally for
  responsiveness. Tuning numbers live in the new
  `src/shared/config/MovementConfig.lua`.
- **Haven audit (2026-09-08):** two real bugs found and fixed in the place
  file — `SpawnLocation` was embedded *inside* `PlazaSlab` (players spawned in
  solid stone), and the entire south palisade only had geometry from Y=6 to
  Y=9, leaving a 6-stud gap you could walk straight under along its whole
  length. Added `PalisadeFoundation_West`/`_East` beneath the existing rail
  rather than touching the 100 existing wall parts. **Still open:** the
  crafting station from `haven-build.md`'s "What's in it" table was never
  built — placement needs a decision, see the audit notes.
- **Next:** Haven prop/detail pass (Toolbox clutter, retexturing) and a
  walk-through pass with sprint/dash live; then combat.
- **Not started:** combat, corruption, loot, enemies, data persistence
  (ProfileStore is installed but nothing uses it yet).
- **Toolchain set up.** Rokit, Rojo 7.7.0, and Wally 0.3.2 are installed and
  `wally install` has been run — `Packages/`/`ServerPackages/` exist locally
  (gitignored, regenerate with `wally install`). `wally.toml`/`wally.lock`
  pin Knit 1.7.0 and ProfileStore 1.0.3. `src/shared/config` has
  `WeaponConfig`/`CorruptionConfig`/`EnemyConfig`/`ProgressionConfig` still
  stubbed (empty tables) and `MovementConfig` now populated.

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
