-- Knit service. Owns all damage. Per docs/combat.md the client only ever says
-- "I swung"; this service decides where the hitbox was, what was inside it,
-- and how much damage that's worth. The client never sends a position or a
-- target, so there's nothing useful for it to lie about.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local WeaponConfig = require(ReplicatedStorage.Shared.config.WeaponConfig)

local CombatService = Knit.CreateService {
	Name = "CombatService",
	Client = {},
}

local state = {}

local function initPlayer(player)
	state[player] = {
		comboIndex = 0, -- 0 = no chain running; 1..3 = last landed light hit
		lastLightClock = -math.huge,
		lastHeavyClock = -math.huge,
		busyUntil = 0, -- os.clock() until which this player can't start anything
	}
end

local function cleanupPlayer(player)
	state[player] = nil
end

-- Reads the "am I locked out right now" flags that MovementService also
-- writes. Using character attributes as the shared channel means these two
-- services never have to require each other -- which is what keeps us out of
-- the circular-dependency trap docs/architecture.md warns about.
local function isBusy(player, data)
	local character = player.Character
	if not character then
		return true
	end
	if character:GetAttribute("Dashing") then
		return true
	end
	if os.clock() < data.busyUntil then
		return true
	end
	return false
end

local function setCommitment(character, data, duration)
	data.busyUntil = os.clock() + duration
	character:SetAttribute("Attacking", true)
	task.delay(duration, function()
		if character.Parent and os.clock() >= data.busyUntil then
			character:SetAttribute("Attacking", false)
		end
	end)
end

-- The actual hit detection. GetPartBoundsInBox asks the engine "which parts
-- are inside this box right now" -- the approach docs/combat.md specifies,
-- because unlike a camera raycast the client has no say in where the box is.
local function applyHitbox(attackerCharacter, hitboxSize, forwardOffset, damage, knockback, knockbackDuration)
	local rootPart = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return {}
	end

	local hitboxCFrame = rootPart.CFrame * CFrame.new(0, 0, -forwardOffset)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attackerCharacter }

	local parts = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

	local hitHumanoids = {}
	local victims = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			-- Skip anything already hit by this same swing, and skip other
			-- players entirely -- there is no PvP in this game, and the Haven
			-- is explicitly a safe zone (docs/game-overview.md).
			if humanoid and not hitHumanoids[humanoid] and not Players:GetPlayerFromCharacter(model) then
				hitHumanoids[humanoid] = true

				if humanoid.Health > 0 then
					humanoid:TakeDamage(damage)
					table.insert(victims, humanoid)

					if knockback and knockback > 0 then
						local victimRoot = model:FindFirstChild("HumanoidRootPart")
						if victimRoot then
							local direction = (victimRoot.Position - rootPart.Position)
							direction = Vector3.new(direction.X, 0, direction.Z)
							if direction.Magnitude > 0 then
								local push = Instance.new("BodyVelocity")
								push.MaxForce = Vector3.new(1e5, 0, 1e5)
								push.Velocity = direction.Unit * knockback
								push.Parent = victimRoot
								task.delay(knockbackDuration, function()
									push:Destroy()
								end)
							end
						end
					end
				end
			end
		end
	end

	return victims
end

-- Briefly shoves the attacker forward. Used for the Heavy's "small forward
-- lunge" in docs/combat.md.
local function lunge(character, speed, duration)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or speed <= 0 then
		return
	end
	local velocity = Instance.new("LinearVelocity")
	velocity.MaxForce = math.huge
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VectorVelocity = rootPart.CFrame.LookVector * speed
	velocity.Attachment0 = rootPart:FindFirstChild("RootAttachment")
	velocity.Parent = rootPart
	task.delay(duration, function()
		velocity:Destroy()
	end)
end

-- Client-callable. Returns the combo step that landed (1-3) and how many
-- things it hit, so the client can play the matching swing. It returns
-- nothing useful if the swing was refused.
function CombatService.Client:RequestLightAttack(player)
	local data = state[player]
	if not data then
		return nil
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	if isBusy(player, data) then
		return nil
	end

	local light = WeaponConfig.Sword.Light
	local now = os.clock()

	-- Advance the chain, or restart it if the window lapsed.
	if now - data.lastLightClock > light.ComboWindow or data.comboIndex >= #light.Damage then
		data.comboIndex = 1
	else
		data.comboIndex += 1
	end
	data.lastLightClock = now

	local step = data.comboIndex
	local isFinalHit = step == #light.Damage

	setCommitment(character, data, light.Commitment[step])

	local victims = applyHitbox(
		character,
		light.HitboxSize,
		light.HitboxForwardOffset,
		light.Damage[step],
		isFinalHit and light.FinalHitKnockback or 0,
		light.KnockbackDuration
	)

	return { step = step, hits = #victims }
end

-- Heavy: 0.6s windup, cancellable during the windup only. Cancellation
-- happens by dashing -- we watch the Dashing attribute rather than exposing a
-- separate "cancel" remote, so the cancel can't be spoofed independently of
-- actually dashing.
function CombatService.Client:RequestHeavyAttack(player)
	local data = state[player]
	if not data then
		return nil
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	if isBusy(player, data) then
		return nil
	end

	local heavy = WeaponConfig.Sword.Heavy
	local now = os.clock()
	if now - data.lastHeavyClock < heavy.Cooldown then
		return nil
	end
	data.lastHeavyClock = now
	data.comboIndex = 0 -- heavy breaks the light chain

	character:SetAttribute("HeavyWindup", true)

	-- Wait out the windup in small slices so a dash can interrupt it.
	local elapsed = 0
	while elapsed < heavy.Windup do
		local step = task.wait()
		elapsed += step
		if not character.Parent then
			return nil
		end
		if character:GetAttribute("Dashing") then
			character:SetAttribute("HeavyWindup", false)
			return { cancelled = true }
		end
	end

	character:SetAttribute("HeavyWindup", false)

	setCommitment(character, data, heavy.Commitment)
	lunge(character, heavy.LungeSpeed, heavy.LungeDuration)

	local victims = applyHitbox(
		character,
		heavy.HitboxSize,
		heavy.HitboxForwardOffset,
		heavy.Damage,
		0,
		0
	)

	return { heavy = true, hits = #victims }
end

function CombatService:KnitInit()
	Players.PlayerAdded:Connect(initPlayer)
	Players.PlayerRemoving:Connect(cleanupPlayer)
	for _, player in Players:GetPlayers() do
		initPlayer(player)
	end
end

return CombatService
