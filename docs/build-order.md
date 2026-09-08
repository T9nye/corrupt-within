# Build order

Eight phases, setup to playable MVP. Finish each before starting the next. The
temptation is always to jump ahead to combat — the reason not to is that combat
tuned in an empty baseplate has to be retuned once there's a real world.

## Phase 0 — Setup — **not done**

Rokit, Rojo 7, Wally, Knit, ProfileStore, a git repo, config modules stubbed as
code, Rojo syncing into Studio.

This was planned and documented but never actually built — work went straight
into Studio instead, which was the right call for a map-first order. Nothing in
Phase 1 needs it. It has to exist before Phase 2.

## Phase 1 — The Last Haven ← **current**

Build the hub town. No scripting. See `haven-build.md`.

Done when: you can sprint from the gate to the black market and it feels like a
town.

## Phase 2 — Character and movement

Sprint, dash/dodge with i-frames, camera. First real scripting phase. Small
surface area, immediate feedback — a good place to learn Luau.

Done when: moving around the Haven feels good on its own.

## Phase 3 — Combat core

Sword only. Light chain, Heavy, hit detection, damage numbers, a stationary
training dummy in the Haven. Server-authoritative from the first line.

Done when: hitting the dummy feels satisfying with no enemies in the game yet.

## Phase 4 — Enemies and the Wilds

Grey-box The Corrupted Wilds. Implement the five enemies with basic AI —
patrol, aggro, attack, die, drop. Reuse the combat core.

Done when: you can fight your way across the Wilds and back.

## Phase 5 — Progression and data

ProfileStore, XP, levels, loot rolls, inventory, weapon upgrading at the
blacksmith. Now the loop closes.

Done when: you can leave the Haven, kill things, come back, and be stronger.

## Phase 6 — Corruption

The meter, the bands, visuals, control loss, the Scythe's passive. Held until
now deliberately — corruption modifies combat and progression, so both need to
exist and be stable first.

Done when: high corruption is genuinely tempting and genuinely scary.

## Phase 7 — Rootmaw and Hollow Warden

The dungeon, its three chambers, the boss and its three phases. The MVP's
destination.

Done when: a fresh character can go 1 → Warden kill.

## Phase 8 — Polish and ship

Greatsword and Dual Blades, UI pass, sound, cosmetic shop, performance,
multiplayer testing with real people. Then publish.

---

**The rule:** the game should be playable at the end of every phase from 3
onward. Never a state where nothing works because three systems are half-built.
