-- Enemy tuning. Source of truth: docs/enemies.md.
-- Confirm with Ye before changing any numbers here — see CLAUDE.md.
--
-- Health and Damage come straight from docs/enemies.md's table. Everything
-- else — speeds, ranges, cooldowns, patrol behaviour, XP, drop weights — is
-- marked (new) and is a first-pass guess with no doc behind it.

local RARITY_WEIGHTS = {
	-- From docs/progression.md's equipment rarity table.
	{ rarity = "Common", weight = 60 },
	{ rarity = "Uncommon", weight = 25 },
	{ rarity = "Rare", weight = 11 },
	{ rarity = "Epic", weight = 3.5 },
	{ rarity = "Corrupted", weight = 0.5 },
}

return {
	RarityWeights = RARITY_WEIGHTS,

	-- Not an enemy — the stationary Phase 3 test target in the Haven's
	-- training yard (docs/build-order.md, Phase 3).
	TrainingDummy = {
		DisplayName = "Training Dummy",
		Health = 500, -- high on purpose: it's for testing combos, not for killing
		ResetDelay = 3, -- seconds after being destroyed before it stands back up
		HealthBarOffset = 5, -- studs above the dummy's origin
	},

	Enemies = {
		Husk = {
			DisplayName = "Husk",
			Teaches = "Basic combo timing",
			Health = 60,
			Damage = 8,
			-- (new) slow and heavily telegraphed — the tutorial enemy
			WalkSpeed = 8,
			AggroRange = 34,
			DeaggroRange = 60,
			AttackRange = 7,
			AttackWindup = 0.9, -- long, readable telegraph
			AttackCooldown = 2.4,
			PatrolRadius = 20,
			PatrolPauseRange = { 2, 5 },
			XP = 15,
			BodyColor = Color3.fromRGB(105, 98, 88),
			BodyHeight = 5,
		},

		Thornling = {
			DisplayName = "Thornling",
			Teaches = "Crowd handling",
			Health = 40,
			Damage = 6,
			-- (new) fast and fragile; docs/enemies.md says these spawn in 3-4s
			WalkSpeed = 17,
			AggroRange = 40,
			DeaggroRange = 70,
			AttackRange = 6,
			AttackWindup = 0.35,
			AttackCooldown = 1.1,
			PatrolRadius = 26,
			PatrolPauseRange = { 1, 3 },
			XP = 10,
			GroupSize = { 3, 4 },
			BodyColor = Color3.fromRGB(88, 104, 72),
			BodyHeight = 3.5,
		},

		BloomedArcher = {
			DisplayName = "Bloomed Archer",
			Teaches = "Closing distance",
			Health = 50,
			Damage = 12,
			-- (new) kites: attacks from range and backs off when crowded
			WalkSpeed = 13,
			AggroRange = 55,
			DeaggroRange = 85,
			AttackRange = 45,
			AttackWindup = 1.0,
			AttackCooldown = 2.6,
			PatrolRadius = 18,
			PatrolPauseRange = { 2, 4 },
			Ranged = true,
			PreferredRange = 30, -- backs away if the player gets closer than this
			XP = 20,
			BodyColor = Color3.fromRGB(120, 96, 116),
			BodyHeight = 4.5,
		},

		RotboundBrute = {
			DisplayName = "Rotbound Brute",
			Teaches = "Patience",
			Health = 140,
			Damage = 20,
			-- (new) heavy and slow; blocking is the whole point of this one
			WalkSpeed = 7,
			AggroRange = 32,
			DeaggroRange = 60,
			AttackRange = 9,
			AttackWindup = 1.3,
			AttackCooldown = 3.2,
			PatrolRadius = 14,
			PatrolPauseRange = { 3, 6 },
			-- docs/enemies.md: "Blocks light attacks — must be broken with
			-- Heavy or dodged around." CombatService reads this off the model.
			BlocksLightAttacks = true,
			XP = 45,
			BodyColor = Color3.fromRGB(78, 70, 62),
			BodyHeight = 7,
		},

		CorruptWisp = {
			DisplayName = "Corrupt Wisp",
			Teaches = "Priority targeting",
			Health = 30,
			Damage = 5,
			-- (new) drifts, buffs its friends, and is meant to die first
			WalkSpeed = 11,
			AggroRange = 45,
			DeaggroRange = 75,
			AttackRange = 5,
			AttackWindup = 0.5,
			AttackCooldown = 1.8,
			PatrolRadius = 22,
			PatrolPauseRange = { 1, 3 },
			-- Buffs nearby enemies (docs/enemies.md)
			BuffRadius = 24,
			BuffDamageMultiplier = 1.25,
			-- Corruption on contact. CorruptionService is Phase 6 and doesn't
			-- exist yet; BaseEnemy has the hook, this is the number for it.
			CorruptionOnContact = 3,
			XP = 25,
			-- The one place purple is allowed, per docs/haven-build.md.
			BodyColor = Color3.fromRGB(128, 84, 160),
			BodyHeight = 3,
		},
	},

	-- (new) Shared behaviour defaults, applied when an enemy doesn't override.
	Defaults = {
		CorpseDespawnDelay = 4,
		RespawnDelay = 12, -- 0 disables respawning for that spawner
		TickRate = 0.15, -- seconds between AI decisions (not every frame — cheaper and plenty responsive)
	},
}
