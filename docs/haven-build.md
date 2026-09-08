# The Last Haven — build doc

The hub town. Safe zone, no combat. This is the part of the game currently under
construction.

> **Coordinates live in the place file, not here.** The Haven is partially built
> already — layout guide, plaza slab, building blocks, finished blacksmith. If
> you need exact Size/Position values, read them out of Studio rather than
> inventing them from this doc. With the Studio MCP connected, dump the
> `Workspace.Haven` tree and work from what's actually there.

## Scale

- **Footprint:** 400×400 studs, walled.
- **Plaza:** 130×130, centred. The plaza is the town's anchor — everything else
  reads as "off the plaza."
- Scaled up from an earlier 320×320 because of sprint. At sprint speed a smaller
  town crosses in a few seconds and stops feeling like a place.

## What's in it

| Spot | Where | Purpose |
| --- | --- | --- |
| Blacksmith | Off the plaza | Weapon upgrades. **Built.** |
| Plaza merchant stall | Inside the plaza | The default, obvious vendor. |
| Outer merchants | Scattered outside the plaza | Reward for wandering. |
| **Black market merchant** | Hidden behind the plaza | Reward for exploring. Corrupted goods, cleansing items. |
| Crafting station | Off the plaza | |
| Quest board | Plaza edge | |
| Mining spot | Town edge | |
| Party board | Plaza | Group forming |
| Main gate | Wall, facing the Wilds | The exit to combat |

The reason for spreading vendors out is that a town where everything sits in one
square is a menu with walls. Players should find things.

## Palette

Dark stone and weathered wood. Muted greens and greys. The only saturated colour
in the Haven is warm lantern light — which makes the purple corruption outside
the walls read as *wrong* by contrast. Keep purple out of the town almost
entirely. Save it for the black market.

## Lighting

- `Lighting.LightingStyle = Enum.LightingStyle.Realistic`
  (`Lighting.Technology` no longer exists — don't use it.)
- Overcast, low sun angle. The world is dying; midday sun undercuts that.
- Warm PointLights on lanterns and the blacksmith forge.
- A little Atmosphere haze for depth. Not so much that the walls disappear.

## Build order and budget

Roughly 30 hours across 9 sessions, first time building. That estimate assumes
learning as you go — it's not slow.

1. Grey-box: walls, plaza slab, building volumes as plain parts
2. Blacksmith detail pass ✅
3. Remaining plaza structures
4. Outer buildings
5. Black market nook
6. Terrain pass — ground, elevation, the approach to the gate
7. Props and clutter (Toolbox is fine here; retexture to the palette)
8. Lighting pass
9. Walk-through pass — sprint it end to end, fix what feels wrong

## On buildings not looking like the concept

The concept image is a rendered illustration; it isn't what any first Studio
build looks like, including from people who do this professionally. What closes
most of that gap isn't modelling skill — it's **detail density and lighting**:
trim pieces, roof overhangs, slight rotation so nothing is perfectly axis-aligned,
and warm light against a cold ambient. A plain box with good trim and good light
reads better than a complex shape under default lighting.

Grey-box the whole town first anyway. Detailing an unfinished layout is wasted
work.
