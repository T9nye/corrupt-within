# Enemies, dungeon, and boss

All of this lives in The Corrupted Wilds — the MVP combat region.

## The five starter enemies

Each one teaches the player something different. That's the point of having five
instead of one with five skins.

| Enemy | HP | Damage | Teaches |
| --- | --- | --- | --- |
| **Husk** | 60 | 8 | Basic combo timing. Slow, telegraphed, forgiving. The tutorial enemy. |
| **Thornling** | 40 | 6 | Crowd handling. Spawns in groups of 3–4, fast, fragile. |
| **Bloomed Archer** | 50 | 12 | Closing distance. Ranged, kites, punishes standing still. |
| **Rotbound Brute** | 140 | 20 | Patience. Blocks light attacks — must be broken with Heavy or dodged around. |
| **Corrupt Wisp** | 30 | 5 | Priority targeting. Buffs nearby enemies and applies corruption to the player on contact. Kill it first. |

Design rule: a player who understands all five should be able to clear a mixed
group without taking damage. If that's impossible, something is unfair.

## Rootmaw — the dungeon

A tree-root cave system under the Wilds. Three chambers plus a boss arena.

1. **The Descent** — Husks and Thornlings. Wide, safe, teaches the space.
2. **The Snare** — Bloomed Archers on ledges, Thornlings on the floor. Forces
   the player to deal with range while being swarmed.
3. **The Rot Chamber** — one Rotbound Brute, two Corrupt Wisps. The exam.
   Corruption hazard on the floor makes standing still costly.
4. **Arena** — Hollow Warden.

Dungeon runs are repeatable. Loot scales with the party's average level.

## Hollow Warden — the boss

The Wilds boss and the MVP's final content. A hollowed-out tree guardian, roughly
three times player height.

**HP:** 1,200 solo, scaling +60% per additional player.

**Phase 1 (100%–60%)**
- Ground slam — telegraphed 1.2s, cone AoE, 30 damage. Dodge or move out.
- Root sweep — 360° low attack, 22 damage. Jump or dash.
- Summons 2 Thornlings every 25 seconds.

**Phase 2 (60%–25%)**
- Everything from Phase 1, faster.
- Corruption bloom — floods a third of the arena with corruption, +15 to any
  player standing in it. Forces movement and pushes players toward the meter.

**Phase 3 (below 25%)**
- Enrage. Damage +40%, no more summons.
- Desperation grab — if it connects, heavy damage and a large corruption spike.
  Clearly telegraphed. Should be the moment players learn to respect the dodge.

**Drops:** guaranteed weapon upgrade material, chance at a rare weapon, cosmetic
title on first clear.

**Rule:** the Warden should be beatable at the intended level without any
corruption use, and noticeably easier with it. That's the choice the whole game
is built on — offer it, don't force it.
