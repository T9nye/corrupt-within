# Combat

## The chain

Every weapon follows the same five-slot structure:

**Light → Heavy → Ability 1 → Ability 2 → Ultimate**

Same buttons on every weapon. What changes is timing, range, and what the
abilities do. Learning a second weapon should feel like learning a dialect, not
a new language.

## The five weapons

| Weapon | Feel | Trade |
| --- | --- | --- |
| **Sword** | Balanced | The baseline everything else is measured against. |
| **Greatsword** | Slow, heavy | Big damage, big commitment. Attacks can't be cancelled. |
| **Dual Blades** | Fast | Low per-hit damage, high uptime, weak to blocking enemies. |
| **Spear** | Range and control | Pokes, pushes, keeps distance. Rewards spacing. |
| **Scythe** | Corruption-based | Strongest scaling, feeds the meter constantly. See `corruption.md`. |

MVP ships Sword, Greatsword, Dual Blades. Spear and Scythe come later.

## Sword moveset (the reference implementation)

Build this one properly and the other four are variations on it.

- **Light** — 3-hit combo. Damage 10 / 10 / 14. Each hit has a 0.45s window to
  continue the chain; miss it and the combo resets. Final hit has slight
  knockback.
- **Heavy** — 0.6s windup, damage 28, small forward lunge. Cancellable during
  windup only.
- **Ability 1 — Riposte** — short parry window (0.25s). On success, counter for
  35 and stagger the attacker. Cooldown 8s.
- **Ability 2 — Corrupt Slash** — a corrupted ability. Damage 40 in a cone, +6
  corruption. Cooldown 12s.
- **Ultimate — Severance** — 3-hit burst, 90 total, brief invulnerability during
  the animation. +10 corruption. Cooldown 60s, or charges on damage dealt.

## Rules

- Server decides all damage. Client sends "I attacked at time T"; server
  validates range, cooldown, and target.
- Hit detection: hitbox parts or `GetPartBoundsInBox`, not raycasts from the
  camera. Camera raycasts are trivially spoofed.
- Every attack has a **commitment cost** — a window where you can't act. Combat
  without commitment is button mashing.
- i-frames on dash. Dash is the answer to every attack in the game; that's what
  makes the timing matter.
- All damage numbers, windows, and cooldowns go in
  `src/shared/config/WeaponConfig.lua`. Numbers above are first-pass — expect to
  halve or double them after real playtesting.
