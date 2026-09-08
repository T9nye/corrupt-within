-- The shared brain every enemy uses. One instance of this class = one live
-- enemy in the world. EnemyService creates them and ticks them; this module
-- doesn't know Knit exists.
--
-- Luau OOP note: `BaseEnemy.__index = BaseEnemy` plus `setmetatable(self, BaseEnemy)`
-- is the standard way to make a "class" here. It means "if you look up a key
-- on this object and don't find it, look on BaseEnemy next" — which is how
-- `enemy:Update()` finds the Update function defined below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyConfig = require(ReplicatedStorage.Shared.config.EnemyConfig)

local BaseEnemy = {}
BaseEnemy.__index = BaseEnemy

local STATE = {
	Patrol = "Patrol",
	Chase = "Chase",
	Attack = "Attack",
	Dead = "Dead",
}

-- Grey-box body. Real art comes later; this exists so the AI has something to
-- push around and something for the player's hitbox to find.
local function buildModel(config, spawnPosition)
	local model = Instance.new("Model")
	model.Name = config.DisplayName

	local bodyHeight = config.BodyHeight
	local hipHeight = bodyHeight / 2

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Material = Enum.Material.SmoothPlastic
	root.Position = spawnPosition + Vector3.new(0, hipHeight + 1, 0)
	root.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.4, bodyHeight, 1.6)
	body.Color = config.BodyColor
	body.Material = Enum.Material.Slate
	body.CFrame = root.CFrame
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Color = config.BodyColor
	head.Material = Enum.Material.Slate
	head.CFrame = root.CFrame * CFrame.new(0, bodyHeight / 2 + 0.7, 0)
	head.Parent = model

	-- WeldConstraint glues two parts together so physics treats them as one
	-- rigid object. Without this the body and head just fall off the root.
	for _, piece in ipairs({ body, head }) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = piece
		weld.Parent = root
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = config.Health
	humanoid.Health = config.Health
	humanoid.WalkSpeed = config.WalkSpeed
	humanoid.HipHeight = hipHeight
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	-- This rig has no Neck joint; without this the Humanoid kills itself.
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	model.PrimaryPart = root

	-- CombatService reads this to decide whether a light attack bounces off.
	if config.BlocksLightAttacks then
		model:SetAttribute("BlocksLight", true)
	end

	return model, humanoid, root
end

function BaseEnemy.new(enemyName, spawnPosition, parent)
	local config = EnemyConfig.Enemies[enemyName]
	assert(config, "Unknown enemy type: " .. tostring(enemyName))

	local self = setmetatable({}, BaseEnemy)

	self.enemyName = enemyName
	self.config = config
	self.spawnPosition = spawnPosition
	self.state = STATE.Patrol
	self.target = nil
	self.patrolGoal = nil
	self.nextPatrolClock = 0
	self.lastAttackClock = -math.huge
	self.damageMultiplier = 1 -- raised by a nearby Corrupt Wisp
	self.alive = true

	self.model, self.humanoid, self.root = buildModel(config, spawnPosition)
	self.model.Parent = parent or workspace

	self.humanoid.Died:Connect(function()
		self:OnDied()
	end)

	return self
end

-- Nearest living player character within a radius, or nil.
function BaseEnemy:FindNearestPlayer(radius)
	local best, bestDistance = nil, radius
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and rootPart and humanoid.Health > 0 then
			local distance = (rootPart.Position - self.root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = player, distance
			end
		end
	end
	return best, bestDistance
end

function BaseEnemy:DistanceToTarget()
	if not self.target then
		return math.huge
	end
	local character = self.target.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return math.huge
	end
	return (rootPart.Position - self.root.Position).Magnitude
end

function BaseEnemy:Patrol()
	local now = os.clock()
	if now < self.nextPatrolClock then
		return
	end

	local radius = self.config.PatrolRadius
	local offset = Vector3.new(
		math.random(-radius, radius),
		0,
		math.random(-radius, radius)
	)
	self.patrolGoal = self.spawnPosition + offset
	self.humanoid:MoveTo(self.patrolGoal)

	local pause = self.config.PatrolPauseRange
	self.nextPatrolClock = now + math.random(pause[1], pause[2])
end

function BaseEnemy:Attack()
	local now = os.clock()
	if now - self.lastAttackClock < self.config.AttackCooldown then
		return
	end
	self.lastAttackClock = now

	local target = self.target
	self.humanoid:MoveTo(self.root.Position) -- stop to swing

	-- Windup first: the telegraph is what makes an attack dodgeable, which is
	-- the whole point of the dash having i-frames.
	task.delay(self.config.AttackWindup, function()
		if not self.alive or not target then
			return
		end

		local character = target.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not rootPart or humanoid.Health <= 0 then
			return
		end

		-- Did they leave during the windup?
		if (rootPart.Position - self.root.Position).Magnitude > self.config.AttackRange * 1.3 then
			return
		end

		-- This is where the dash's i-frames actually pay off. MovementService
		-- sets this attribute for DashIFrameDuration; we honour it here.
		if character:GetAttribute("Invulnerable") then
			return
		end

		humanoid:TakeDamage(self.config.Damage * self.damageMultiplier)

		-- Corrupt Wisp applies corruption on contact (docs/enemies.md).
		-- CorruptionService is Phase 6; this is the hook it plugs into.
		if self.config.CorruptionOnContact then
			-- TODO(Phase 6): CorruptionService:AddCorruption(target, self.config.CorruptionOnContact)
		end
	end)
end

-- Corrupt Wisps buff whatever is standing near them.
function BaseEnemy:ApplyBuffAura(allEnemies)
	if not self.config.BuffRadius then
		return
	end
	for _, other in ipairs(allEnemies) do
		if other ~= self and other.alive then
			local distance = (other.root.Position - self.root.Position).Magnitude
			if distance <= self.config.BuffRadius then
				other.damageMultiplier = math.max(other.damageMultiplier, self.config.BuffDamageMultiplier)
			end
		end
	end
end

function BaseEnemy:Update(allEnemies)
	if not self.alive or not self.root.Parent then
		return
	end

	-- Buffs are reapplied every tick so they lapse when the Wisp dies.
	self.damageMultiplier = 1

	local config = self.config

	if self.state == STATE.Patrol then
		local player, distance = self:FindNearestPlayer(config.AggroRange)
		if player then
			self.target = player
			self.state = STATE.Chase
		else
			self:Patrol()
		end

	elseif self.state == STATE.Chase or self.state == STATE.Attack then
		local distance = self:DistanceToTarget()

		if distance > config.DeaggroRange then
			self.target = nil
			self.state = STATE.Patrol
			self.humanoid:MoveTo(self.spawnPosition)
			return
		end

		local targetRoot = self.target
			and self.target.Character
			and self.target.Character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			self.target = nil
			self.state = STATE.Patrol
			return
		end

		if distance <= config.AttackRange then
			self.state = STATE.Attack
			-- Archers back off if you close on them (docs/enemies.md: "kites").
			if config.Ranged and config.PreferredRange and distance < config.PreferredRange then
				local away = (self.root.Position - targetRoot.Position)
				away = Vector3.new(away.X, 0, away.Z)
				if away.Magnitude > 0 then
					self.humanoid:MoveTo(self.root.Position + away.Unit * 10)
				end
			end
			self:Attack()
		else
			self.state = STATE.Chase
			self.humanoid:MoveTo(targetRoot.Position)
		end
	end
end

function BaseEnemy:OnDied()
	if not self.alive then
		return
	end
	self.alive = false
	self.state = STATE.Dead

	-- No rarity roll here on purpose -- that's LootService's job, not this
	-- module's. BaseEnemy just reports the facts of the kill: who, what, and
	-- where. EnemyService fans this out to whoever subscribed via
	-- OnEnemyDied; LootService and DataService are the two current listeners.
	local drop = {
		enemyName = self.enemyName,
		xp = self.config.XP,
		position = self.root.Position,
		killedBy = self.target,
	}

	if self.onDeath then
		self.onDeath(self, drop)
	end

	task.delay(EnemyConfig.Defaults.CorpseDespawnDelay, function()
		self:Destroy()
	end)
end

function BaseEnemy:Destroy()
	self.alive = false
	if self.model then
		self.model:Destroy()
		self.model = nil
	end
end

BaseEnemy.STATE = STATE

return BaseEnemy
