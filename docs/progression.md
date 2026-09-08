# Progression

Five parallel systems. They're separate on purpose — a player who's stuck on one
can still make progress on another.

1. **Player level** — health, base stats, region gating.
2. **Weapon level** — per-weapon, earned by using that weapon.
3. **Corruption level** — a long-term mastery track, separate from the in-run meter.
4. **Skill tree** — spent points, respeccable for a fee.
5. **Equipment rarity** — the loot axis.

## Player levels

MVP covers levels 1–20.

- XP to next level: `100 * (level ^ 1.5)`, rounded. Level 2 costs 100, level 10
  costs about 3,160, level 20 about 8,940.
- Health: `100 + (level * 12)`.
- Level 5 opens the Wilds. Level 12 is the intended Rootmaw level. Level 15+ is
  comfortable Hollow Warden.

## Weapon levels

1–10 per weapon. Each level is +4% damage. Levelled by dealing damage with that
weapon, so switching weapons costs you something — but the cost is recoverable,
not permanent.

Upgrading past level 5 requires materials from Rootmaw. That's the hook that
makes the dungeon repeatable.

## Corruption mastery

Separate from the meter. Earned by *surviving* time spent at Consumed or above.
Ranks reduce control-loss chance and unlock corrupted ability variants. This is
how a player who commits to corruption gets rewarded for the risk over time.

## Equipment rarity

| Rarity | Drop weight | Stat roll |
| --- | --- | --- |
| Common | 60% | baseline |
| Uncommon | 25% | +10% |
| Rare | 11% | +25% |
| Epic | 3.5% | +45%, one bonus affix |
| Corrupted | 0.5% | +70%, one affix, passive corruption gain while equipped |

Corrupted rarity is the best gear in the game and it actively works against you.
Keep it that way.

## Skill tree

Three branches, 1 point per level:

- **Blade** — raw combat. Damage, combo extensions, reduced commitment windows.
- **Endurance** — health, dash charges, i-frame duration, corruption resistance.
- **Corruption** — deeper corruption scaling, cheaper corrupted abilities,
  control-loss mitigation.

Twenty points across twenty levels means no one maxes two branches at MVP level
cap. That's intentional — builds should be legible.

## Persistence

ProfileStore. One profile per player containing level, XP, weapon levels,
corruption mastery, skill points, inventory, and cosmetics owned.

Save on: level up, item gain, region change, and every 60 seconds. Always save on
`BindToClose`. Test data loss deliberately before launch — losing a player's
progress once loses the player.

## A note on these numbers

Every figure on this page is a first pass. They exist so there's something to
play, not because they're right. Expect to change most of them after the first
real playtest, and change them in
`src/shared/config/`, not scattered through services.
