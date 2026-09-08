# Architecture

## Toolchain

| Tool | Job |
| --- | --- |
| **Rokit** | Manages the other tools' versions. Defined in `rokit.toml`. |
| **Rojo 7** | Syncs files on disk into Studio. This is what makes Claude Code useful here. |
| **Wally** | Package manager. Dependencies in `wally.toml`, installed to `Packages/`. |
| **Knit** | Service/controller framework. Server services, client controllers, networking between them. |
| **ProfileStore** | Player data persistence. Session locking, so no duplicated saves. |

## Folder layout

```
corrupt-within/
├── CLAUDE.md
├── docs/
├── rokit.toml
├── wally.toml
├── default.project.json
└── src/
    ├── server/
    │   ├── init.server.lua
    │   └── Services/
    │       ├── CombatService.lua
    │       ├── CorruptionService.lua
    │       ├── DataService.lua
    │       ├── EnemyService.lua
    │       └── LootService.lua
    ├── client/
    │   ├── init.client.lua
    │   └── Controllers/
    │       ├── InputController.lua
    │       ├── CombatController.lua
    │       └── HUDController.lua
    └── shared/
        ├── config/
        │   ├── WeaponConfig.lua
        │   ├── CorruptionConfig.lua
        │   ├── EnemyConfig.lua
        │   └── ProgressionConfig.lua
        └── util/
```

## Working with Rojo

1. `rojo serve` in the repo.
2. In Studio, open the Rojo plugin and Connect.
3. Edit files on disk. They appear in Studio live.

**The map is not in the repo.** Rojo syncs scripts; the Haven and its parts live
in the `.rbxl` place file, built by hand in Studio. Don't try to move the map
into Rojo — that way lies pain. Keep the place file backed up separately.

## Conventions

- **Server authority.** The client requests, the server decides. Damage, loot,
  corruption, currency — all server-side. Assume any client can lie.
- **Config over constants.** Tunable numbers live in `src/shared/config`.
- **One responsibility per service.** If a service name needs "and" to describe
  it, split it.
- **No circular Knit dependencies.** If two services need each other, a third
  thing probably wants to exist.
- **Fail loudly in development.** `assert` on things that should never happen.
  Silent failures in Roblox are very hard to find later.

## Testing

Studio's Play Solo covers most things. Use **Start Server + 2 Players** for
anything touching networking, party logic, or corruption control-loss — bugs
there don't appear in solo play.
