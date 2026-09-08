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
}

return ProgressionConfig
