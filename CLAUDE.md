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

**Interiors (2026-09-08).** Every building except the blacksmith now has one,
parented as an `Interior` model inside each building so it can be revised or
deleted wholesale. The shells were already hollow with working doorways, so
nothing needed carving — each gained a ceiling, a hanging lantern with a warm
PointLight, and furniture matched to its trade: black market (counter, purple
vials, cleansing basin — the only purple in town), material trader (ore bins,
timber, sacks), armorer (weapon rack, two armour stands), alchemist (cauldron,
bottle shelves, herb bundles), and three houses (beds, tables, hearths,
chests). The two 48×38 outer merchants were too cavernous for one room, so
each is partitioned into shopfront plus back storage with its own internal
doorway; **A is a provisioner and B a trade post — that identity was my
choice, nothing in the docs assigns it.** Interior lights run
`Shadows = false` deliberately: the lamp part otherwise casts a shadow
straight down over the furniture beneath it.

**Known drift:** `ResidentialShell_3` has been moved in the place file since
it was built — it now sits at (−86, −55) with **rotation 0°**, not (−83, −115)
at 10°. Its interior was built to the live position. RS1 and RS2 still carry
their original off-axis rotation.

### Code (all Rojo-synced, all verified running in a playtest)

| System | Owns | Files |
| --- | --- | --- |
| Movement | Stamina, dash charges, i-frames | `MovementService`, `MovementController` |
| HUD | Stamina bar, dash pips | `HUDController` |
| Combat | All damage, hitboxes, combo state | `CombatService`, `CombatController` |
| Weapons | Building/equipping the held weapon | `WeaponService` |
| Enemies | Registry, AI tick loop | `EnemyService`, `Enemy/BaseEnemy` |
| Loot | Rarity rolls, item creation | `LootService` |
| Data | ProfileStore profiles, XP, levels, settings, cosmetics | `DataService` |
| Test target | Training dummy health/reset | `TrainingDummyService` |
| Menu | Spawn gating (`CharacterAutoLoads=false`) | `MenuService` |
| Loading/Menu UI | Loading screen, main menu, background camera | `MenuController` |
| Customize | Avatar preview, body colour/outfit, saves to profile | `CustomizeController` |
| Settings | Volume/sensitivity/FOV/quality/keybinds, reusable panel | `SettingsController` |

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
- **Loot is wired end to end (2026-09-08).** `LootService` subscribes to
  `EnemyService:OnEnemyDied`, rolls a rarity against
  `ProgressionConfig.EquipmentRarity` (moved there from `EnemyConfig` — rarity
  is a loot/progression concept, not an enemy one), and hands `DataService` a
  real item. Verified with a 10,000-roll statistical check (weights held) and
  a live kill (Husk → item appeared in inventory, XP awarded). **There is no
  itemization system** — items are `{id, source, rarity, statMultiplier,
  hasAffix, passiveCorruptionPerSecond}`, deliberately the simplest thing that
  can hold a rarity. No names, no equip slots, no weapon types. That's the
  next real gap, not a missing feature of LootService itself.
  `passiveCorruptionPerSecond = 0.1` for Corrupted gear is an invented rate —
  no doc specifies one.
- **Corrupt Wisp's corruption-on-contact** is a marked `TODO(Phase 6)` hook.
- **Sword abilities** (Riposte / Corrupt Slash / Severance) have numbers in
  `WeaponConfig` but no implementation. Phase 6+.
- **No enemy art** — grey-box boxes built in code.
- **The sword is a placeholder.** `WeaponService` welds a five-part grey-box
  blade to the right hand on every spawn and stamps `EquippedWeapon` on the
  character; `CombatService` reads that attribute for its stat block and now
  refuses attacks from anyone unarmed. It is welded rather than a Roblox
  `Tool` on purpose — a Tool would sit in the backpack needing a hotbar press,
  and attack input already runs through `CombatController`, not
  `Tool.Activated`. There are still **no attack animations**, so swings do
  damage with no visual tell.
- **The Wilds does not exist.** One Husk spawns in the training yard from a
  `TEST_SPAWNS` table in `EnemyService`, explicitly marked TEMPORARY. Delete
  it when the Wilds gets real spawners — the Haven is meant to be no-combat.

### Loading screen, main menu, Customize, Settings (2026-09-08)

`Players.CharacterAutoLoads = false` (`MenuService`) — no character exists
until PLAY is pressed, which is what makes "no control until they leave the
menu" true by construction rather than something enforced after the fact.
`ReplicatedFirst`'s one job is killing Roblox's default loading screen before
it flashes; `MenuController` builds the real one, gated on BOTH real
`ContentProvider:PreloadAsync` progress over the Haven AND a `ProfileLoaded`
Player attribute from `DataService`. Customize uses
`Players:CreateHumanoidModelFromUserId` to preview the real avatar with no
character needed yet; Settings is one panel (`SettingsController:Open(onClose)`)
callable from anywhere, ready for a future pause menu to reuse verbatim.

**Six real bugs were found by actually playtesting this, not just reading the
code back:**
1. The menu's slow background camera orbit (a `RenderStepped` connection)
   was never stopped when Customize took over the camera, so it fought
   Customize's framing every frame. Needed an explicit `StopBackgroundCamera`.
2. Customize's camera was on the wrong side of the preview rig — showed the
   character's *back*. A Roblox character faces -Z by default; the camera
   needs to be on the -Z side looking back, not +Z.
3. `UserGameSettings.MouseSensitivity` **cannot be written by a normal game
   script at all** ("lacking capability RobloxScript") — a hard platform
   restriction, not a bug to work around. The slider still exists and
   persists to the profile; it does not yet affect the live camera. Actually
   doing that means replacing Roblox's default camera control scripts
   entirely, which is real future work, not a quick fix.
4. The FOV setting only wrote `camera.FieldOfView` while `CameraType` was
   already `Custom` — which it never is during the menu (it's `Scriptable`).
   The saved value silently never applied on spawn until this was fixed to
   re-apply explicitly when PLAY restores `Custom`.
5. `Player.CharacterAppearanceLoaded` **did not fire at all** in Play Solo
   testing (confirmed by forcing a respawn and watching for it) — so an
   appearance-loaded-only cosmetic apply silently never ran. Fixed by
   applying on both `CharacterAdded` and `CharacterAppearanceLoaded`.
6. Applying body colour "to every BasePart except Accessories" also
   recoloured the welded sword, since `WeaponService` parents it directly
   onto the character. Fixed with an explicit whitelist of real body part
   names instead.

None of these were guessed at — each was caught by clicking through the
actual flow in a live playtest and checking real values afterward.

### Open questions needing Ye's decision

- **Crafting station** is in `haven-build.md`'s "What's in it" table but was
  never built. Needs a placement decision.
- **`LayoutGuide`** blueprint decal is still on the ground and now shows
  through in open areas. Remove, or keep as reference?
- **All `(new)`-marked numbers** in `WeaponConfig`/`EnemyConfig` are invented,
  not from docs — hitbox sizes, commitment windows, enemy speeds/ranges, XP
  values. These want a playtest pass.
- **Mouse sensitivity doesn't actually do anything live** (see bug #3 above)
  — it persists to the profile but the slider is currently cosmetic. Real
  fix requires overriding Roblox's default camera control scripts.
- **Outfit "presets" are colour tints, not armour models** — no clothing
  assets exist. Matches the project's grey-box rule but is the most visibly
  unfinished-looking part of Customize.

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
