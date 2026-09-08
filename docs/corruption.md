# Corruption

The core mechanic. A resource that is also a risk.

## The meter

0–100, per player, server-authoritative. Persists through a play session; decays
in the Haven; does **not** reset on death (dying while high-corruption should
sting).

## Bands

| Band | Range | Effect |
| --- | --- | --- |
| **Clean** | 0–29 | Normal stats. No visual change. |
| **Tainted** | 30–64 | +15% damage. Purple veining on limbs, faint particle trail. |
| **Consumed** | 65–89 | +35% damage, +10% move speed. Heavy visual corruption, eyes glow, screen edges darken. Chance of **losing control**. |
| **Lost** | 90–100 | +60% damage. Control loss is frequent. Hostile NPCs prioritize you. |

## Losing control

At Consumed and above, each corrupted ability use rolls against a control check.
On failure the player briefly loses input — the character attacks on its own for
1–2 seconds, hitting whatever is nearest. **Including party members.**

That last part is the design point: high corruption is a genuine liability in a
group, not just a number. It gives parties something to talk about.

First-pass control-loss chance: 0% below 65, then scaling from 5% at 65 to 40%
at 100. Tune from playtests, not from theory.

## Gaining corruption

- Using a corrupted ability: +4 to +12 depending on the ability.
- Killing a corrupted enemy: +1.
- Standing in corruption zones (Wilds hazards, Abyss ambient): +0.5/sec.
- Equipping the Scythe: passive +0.25/sec while held. The Scythe is the
  corruption weapon; it should feel like a bargain you're making.

## Shedding corruption

- Passive decay outside combat: −1/sec after 8 seconds without dealing or taking damage.
- The Haven: −5/sec. The town is a genuine sanctuary — that's why it's called the Last Haven.
- Cleansing consumables: −25, purchasable, deliberately expensive.
- **Never** an instant free reset. If shedding corruption is cheap, the meter stops mattering.

## Implementation notes

- `CorruptionService` owns the value. Nothing else writes to it.
- Client gets band changes pushed to it and drives visuals/UI from those; the
  client never computes its own corruption.
- Control loss is triggered server-side, then the client is told to disable
  input. Don't trust the client to hand over control voluntarily.
- All the numbers above live in `src/shared/config/CorruptionConfig.lua`.
