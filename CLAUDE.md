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

- **Phase:** 1 — building The Last Haven (the hub town) in Studio.
- **Done:** layout guide placed, plaza slab, building blocks blocked out,
  blacksmith finished, lighting switched to Realistic.
- **Next:** remaining Haven buildings, then the terrain and detail pass.
- **Not started:** any gameplay scripting. Phase 2 onward.
- **Toolchain set up.** Rokit, Rojo 7.7.0, and Wally 0.3.2 are installed.
  `wally.toml`/`wally.lock` pin Knit 1.7.0 and ProfileStore 1.0.3.
  `default.project.json` and `src/` exist, with the four `src/shared/config`
  modules stubbed out (empty tables — no real tuning numbers yet). No
  `init.server.lua`/`init.client.lua` or service/controller files yet — that's
  gameplay scripting, still not started.

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
