-- Knit service. Owns stamina and dash cooldowns for every player -- the
-- client is never trusted to report its own stamina or to grant itself
-- i-frames. It only ever *asks*; this service decides.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MovementConfig = require(ReplicatedStorage.Shared.config.MovementConfig)

local MovementService = Knit.CreateService {
	Name = "MovementService",
	Client = {}, -- functions added below become callable from the client
}

-- One entry per connected player, keyed by the Player instance itself.
-- This never touches DataStores -- it's runtime-only, reset every server start.
local state = {}

local function initPlayer(player)
	state[player] = {
		stamina = MovementConfig.MaxStamina,
		wantsSprint = false, -- what the client says it wants
		lastSprintClock = -math.huge, -- os.clock() of the last tick we were actually sprinting
		lastDashClock = -math.huge,
		dashing = false, -- true for the whole commitment window, not just the movement burst
	}
end

local function cleanupPlayer(player)
	state[player] = nil
end

-- Client-callable: the client fires this whenever the sprint key goes down
-- or up. It does NOT set WalkSpeed itself -- it just records intent. The
-- Heartbeat loop below is what actually decides speed and drains stamina,
-- every server frame, so a client can't just claim "I'm sprinting" forever
-- for free.
function MovementService.Client:SetSprintInput(player, wantsSprint)
	local data = state[player]
	if not data or typeof(wantsSprint) ~= "boolean" then
		return
	end
	data.wantsSprint = wantsSprint
end

-- Client-callable: the client asks permission to dash. Returns true if
-- granted. This is the only place cooldowns are checked -- the client also
-- keeps its own local cooldown timer for responsiveness, but that copy is
-- just for feel and is never trusted.
function MovementService.Client:RequestDash(player)
	local data = state[player]
	if not data then
		return false
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	if data.dashing then
		return false -- still inside the commitment window from the last dash
	end

	local now = os.clock()
	if now - data.lastDashClock < MovementConfig.DashCooldown then
		return false -- too soon
	end

	data.lastDashClock = now
	data.dashing = true

	-- These attributes are what future systems (combat, animation) will read.
	-- Invulnerable = true means "don't apply damage to this character right now".
	-- Dashing = true means "this character is committed, refuse new actions".
	character:SetAttribute("Invulnerable", true)
	character:SetAttribute("Dashing", true)

	task.delay(MovementConfig.DashIFrameDuration, function()
		if character.Parent then
			character:SetAttribute("Invulnerable", false)
		end
	end)

	task.delay(MovementConfig.DashCommitDuration, function()
		data.dashing = false
		if character.Parent then
			character:SetAttribute("Dashing", false)
		end
	end)

	return true
end

function MovementService:KnitInit()
	Players.PlayerAdded:Connect(initPlayer)
	Players.PlayerRemoving:Connect(cleanupPlayer)
	-- covers players who joined before this service finished starting
	for _, player in Players:GetPlayers() do
		initPlayer(player)
	end
end

function MovementService:KnitStart()
	RunService.Heartbeat:Connect(function(dt)
		for player, data in pairs(state) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				continue
			end

			local isMoving = humanoid.MoveDirection.Magnitude > 0
			local canSprint = data.wantsSprint and isMoving and not data.dashing and data.stamina > 0

			if canSprint then
				data.stamina = math.max(0, data.stamina - MovementConfig.StaminaDrainPerSecond * dt)
				data.lastSprintClock = os.clock()
				humanoid.WalkSpeed = MovementConfig.SprintSpeed
			else
				humanoid.WalkSpeed = MovementConfig.WalkSpeed
				if os.clock() - data.lastSprintClock >= MovementConfig.StaminaRegenDelay then
					data.stamina = math.min(MovementConfig.MaxStamina, data.stamina + MovementConfig.StaminaRegenPerSecond * dt)
				end
			end
		end
	end)
end

return MovementService
