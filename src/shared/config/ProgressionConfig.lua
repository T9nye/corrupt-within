-- Levels, XP curve, skill tree shape. Source of truth: docs/progression.md.
-- Confirm with Ye before changing any numbers here — see CLAUDE.md.
--
-- Every figure below is copied from docs/progression.md, not invented.

local ProgressionConfig = {
	MaxLevel = 20, -- "MVP covers levels 1-20"

	-- XP to get from `level` to `level + 1`: 100 * (level ^ 1.5), rounded.
	XPForNextLevel = function(level)
		return math.round(100 * (level ^ 1.5))
	end,

	-- Max health at a given level: 100 + (level * 12)
	HealthForLevel = function(level)
		return 100 + (level * 12)
	end,

	WeaponMaxLevel = 10,
	WeaponDamagePerLevel = 0.04, -- +4% per weapon level

	-- Level gates
	WildsUnlockLevel = 5,
	RootmawIntendedLevel = 12,

	SkillBranches = { "Blade", "Endurance", "Corruption" },
	SkillPointsPerLevel = 1,

	-- Weapons that exist as data. MVP ships the first three
	-- (docs/game-overview.md); Spear and Scythe are post-MVP.
	Weapons = { "Sword", "Greatsword", "DualBlades" },

	-- Persistence rules, from progression.md's "Persistence" section:
	-- "Save on: level up, item gain, region change, and every 60 seconds."
	Save = {
		PeriodicInterval = 60,
		-- (new) floor between saves, so a burst of item pickups doesn't
		-- hammer the DataStore. Requests inside the window are coalesced.
		MinInterval = 7,
	},

	-- Equipment rarity table, straight from progression.md's "Equipment
	-- rarity" section. DropWeight is the % chance out of 100; StatMultiplier
	-- is "+10%" etc expressed as a multiplier on baseline (1.0 = baseline).
	-- HasAffix and PassiveCorruptionPerSecond are the doc's "one bonus affix"
	-- and "passive corruption gain while equipped" notes for Epic/Corrupted.
	-- LootService is the only thing that reads this table -- it's kept here,
	-- not in LootService itself, because loot rarity is progression.md's
	-- domain (see the Docs map in CLAUDE.md), the same reason XP and levels
	-- live in this file rather than in DataService.
	EquipmentRarity = {
		{ rarity = "Common", dropWeight = 60, statMultiplier = 1.00, hasAffix = false, passiveCorruptionPerSecond = 0 },
		{ rarity = "Uncommon", dropWeight = 25, statMultiplier = 1.10, hasAffix = false, passiveCorruptionPerSecond = 0 },
		{ rarity = "Rare", dropWeight = 11, statMultiplier = 1.25, hasAffix = false, passiveCorruptionPerSecond = 0 },
		{ rarity = "Epic", dropWeight = 3.5, statMultiplier = 1.45, hasAffix = true, passiveCorruptionPerSecond = 0 },
		-- "Corrupted rarity is the best gear in the game and it actively
		-- works against you." -- the passive gain is what makes that true.
		-- The RATE (0.1/sec) is invented -- progression.md says the gear has
		-- one, corruption.md never lists an equipment-based rate. Flagging
		-- this one specifically since it's a real gameplay number, not just
		-- a hitbox size: worth a look before anyone actually equips one.
		{ rarity = "Corrupted", dropWeight = 0.5, statMultiplier = 1.70, hasAffix = true, passiveCorruptionPerSecond = 0.1 },
	},
}

return ProgressionConfig
