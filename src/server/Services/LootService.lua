-- Knit service. The only thing in the game that decides what an enemy drops.
--
-- It doesn't know how to hurt anything (that's CombatService/BaseEnemy) and
-- it doesn't know how to save anything (that's DataService) -- it just
-- listens for deaths, rolls a rarity, builds an item, and hands it off. One
-- responsibility, per the convention in docs/architecture.md.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)
local EnemyConfig = require(ReplicatedStorage.Shared.config.EnemyConfig)

local LootService = Knit.CreateService {
	Name = "LootService",
	Client = {},
}

-- Weighted random pick over ProgressionConfig.EquipmentRarity. Each entry's
-- dropWeight is treated as a slice of a number line from 0 to the total of
-- all weights; a single random roll into that line picks one slice.
-- Example with our real weights (60/25/11/3.5/0.5, total 100): a roll of 63
-- lands past Common's 0-60 slice and inside Uncommon's 60-85 slice.
local function rollRarity()
	local total = 0
	for _, entry in ipairs(ProgressionConfig.EquipmentRarity) do
		total += entry.dropWeight
	end

	local roll = math.random() * total
	local running = 0
	for _, entry in ipairs(ProgressionConfig.EquipmentRarity) do
		running += entry.dropWeight
		if roll <= running then
			return entry
		end
	end
	-- Floating point rounding can theoretically leave `roll` a hair past
	-- `total`; fall back to the last entry rather than returning nothing.
	return ProgressionConfig.EquipmentRarity[#ProgressionConfig.EquipmentRarity]
end

-- Builds one dropped item. There's no itemization doc yet (no weapon/armour
-- naming system exists), so this is deliberately the simplest honest thing
-- that can hold a rarity: what it is, how strong it rolled, and whether it's
-- cursed. Real item types and names are a later pass, not invented here.
local function createItem(enemyName)
	local rarityEntry = rollRarity()
	local enemyConfig = EnemyConfig.Enemies[enemyName]

	return {
		id = HttpService:GenerateGUID(false), -- a unique string so two drops are never confused as the same item
		source = enemyConfig and enemyConfig.DisplayName or enemyName,
		rarity = rarityEntry.rarity,
		statMultiplier = rarityEntry.statMultiplier,
		hasAffix = rarityEntry.hasAffix,
		passiveCorruptionPerSecond = rarityEntry.passiveCorruptionPerSecond,
		acquiredAt = os.time(),
	}
end

function LootService:KnitStart()
	local EnemyService = Knit.GetService("EnemyService")
	local DataService = Knit.GetService("DataService")

	EnemyService:OnEnemyDied(function(_enemy, drop)
		local player = drop.killedBy
		if not player then
			return -- died to something else (a hazard, later corruption zones, etc.) -- no credit, no drop
		end

		local item = createItem(drop.enemyName)
		DataService:AddItem(player, item)
	end)
end

return LootService
