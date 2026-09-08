-- Knit service. Owns the live enemy registry and drives their AI ticks.
-- The per-enemy behaviour lives in BaseEnemy; this is the thing that creates
-- them, ticks them, cleans them up, and tells the rest of the game when one
-- dies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EnemyConfig = require(ReplicatedStorage.Shared.config.EnemyConfig)
local BaseEnemy = require(script.Parent.Parent.Enemy.BaseEnemy)

local EnemyService = Knit.CreateService {
	Name = "EnemyService",
	Client = {},
}

local liveEnemies = {}
local deathListeners = {}
local enemyFolder

-- TEMPORARY. Phase 4 proper builds the Wilds and spawns enemies there; these
-- two Husks exist so combat has something that fights back before that
-- region is built. The Haven is meant to be a no-combat safe zone
-- (docs/game-overview.md), so these entries should be deleted once the
-- Wilds has its own spawners. Husk is the only enemy actually spawned
-- anywhere right now -- the other four in EnemyConfig are real, tuned data
-- (BaseEnemy would run any of them the moment something calls Spawn() with
-- their name), but nothing does yet, so in practice they have no live
-- behaviour, matching "config entries with no behaviour" for now.
local TEST_SPAWNS = {
	{ enemy = "Husk", position = Vector3.new(75, 1, -118) }, -- training yard, west side
	{ enemy = "Husk", position = Vector3.new(90, 1, -142) }, -- training yard, east side
}

-- Other services register here instead of EnemyService having to know about
-- them. Keeps the dependency arrow pointing one way.
function EnemyService:OnEnemyDied(callback)
	table.insert(deathListeners, callback)
end

function EnemyService:Spawn(enemyName, position)
	local enemy = BaseEnemy.new(enemyName, position, enemyFolder)

	enemy.onDeath = function(deadEnemy, drop)
		for _, listener in ipairs(deathListeners) do
			-- Don't let one bad listener take down the death handling for the rest.
			local ok, err = pcall(listener, deadEnemy, drop)
			if not ok then
				warn("[EnemyService] death listener errored:", err)
			end
		end

		local respawnDelay = EnemyConfig.Defaults.RespawnDelay
		if respawnDelay > 0 then
			task.delay(respawnDelay, function()
				self:Spawn(enemyName, position)
			end)
		end
	end

	table.insert(liveEnemies, enemy)
	return enemy
end

-- Thornlings come in packs (docs/enemies.md).
function EnemyService:SpawnGroup(enemyName, position)
	local config = EnemyConfig.Enemies[enemyName]
	local group = config and config.GroupSize or { 1, 1 }
	local count = math.random(group[1], group[2])

	local spawned = {}
	for i = 1, count do
		local scatter = Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
		table.insert(spawned, self:Spawn(enemyName, position + scatter))
	end
	return spawned
end

function EnemyService:GetLiveEnemies()
	return liveEnemies
end

function EnemyService:KnitInit()
	enemyFolder = Instance.new("Folder")
	enemyFolder.Name = "Enemies"
	enemyFolder.Parent = workspace
end

function EnemyService:KnitStart()
	for _, spawn in ipairs(TEST_SPAWNS) do
		self:Spawn(spawn.enemy, spawn.position)
	end

	-- One shared loop for every enemy, rather than a coroutine each. AI
	-- decisions run at TickRate (about 7x/second), which is far cheaper than
	-- every frame and still feels responsive -- movement itself is smooth
	-- because Humanoid:MoveTo keeps walking between ticks.
	task.spawn(function()
		while true do
			task.wait(EnemyConfig.Defaults.TickRate)

			-- Sweep out anything destroyed since the last tick.
			for i = #liveEnemies, 1, -1 do
				local enemy = liveEnemies[i]
				if not enemy.model or not enemy.model.Parent then
					table.remove(liveEnemies, i)
				end
			end

			-- Wisp auras first, so the buff is in place before anyone swings.
			for _, enemy in ipairs(liveEnemies) do
				if enemy.alive then
					enemy:ApplyBuffAura(liveEnemies)
				end
			end

			for _, enemy in ipairs(liveEnemies) do
				if enemy.alive then
					local ok, err = pcall(function()
						enemy:Update(liveEnemies)
					end)
					if not ok then
						warn("[EnemyService] enemy update errored:", err)
					end
				end
			end
		end
	end)
end

return EnemyService
