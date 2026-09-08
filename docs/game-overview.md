# Game overview

## What it is

An open-world action RPG on Roblox. 1–10 players per server. Dark fantasy tone,
Roblox proportions, purple corruption as the visual signature.

## Core loop

Explore → Fight → Loot → Upgrade → Unlock new area → Boss → repeat.

Each region is gated behind the previous region's boss. The loop should feel
complete inside 20 minutes of play, and worth repeating for 20 hours.

## The hook

Every player carries a **Corruption meter**. Using corrupted abilities fills it.
Low corruption plays normally. Medium makes you hit harder and start to look
wrong. High makes you very powerful and risks losing control of your character.

This is the thing the game is about. Every other system should either feed the
meter or react to it. Full spec in `corruption.md`.

## Regions

| Region | Role | Notes |
| --- | --- | --- |
| **The Last Haven** | Safe hub town | Upgrade, sell, craft, take quests, mine, form parties. No combat. |
| **The Corrupted Wilds** | First combat region | Forest. Where new players learn the loop. Rootmaw dungeon lives here. |
| **The Sunken City** | Mid-game | Verticality, water, tighter fights. |
| **The Abyss** | Endgame | World bosses. Corruption pressure is highest here. |

Haven has multiple distinct spots so it doesn't feel like one square: a merchant
stall inside the plaza, additional merchants outside it, and a **black market
merchant hidden behind the plaza** for players who explore.

## Monetization

Cosmetics only. Skins, kill effects, emotes, titles, mounts, auras, private
servers, a battle pass.

Nothing that sells power. No directly purchasable top-tier weapons. If a
proposed product would make a paying player stronger than a non-paying player of
the same level, it doesn't ship.

## MVP scope

The smallest version that is actually a game:

- 1 town (The Last Haven)
- 1 forest region (The Corrupted Wilds)
- 5 enemy types
- 1 dungeon (Rootmaw)
- 1 boss (Hollow Warden)
- 3 weapons (Sword, Greatsword, Dual Blades)
- Basic leveling
- Loot drops
- Weapon upgrading

Everything else — Sunken City, Abyss, Spear, Scythe, mounts, battle pass — is
post-MVP. Resist adding to this list.

## Movement

A sprint button and a dash/dodge button. Sprint is why the Haven is scaled to
400×400 studs rather than something tighter; walking speed alone would make it
feel enormous. Dash details to be designed alongside combat.
