-- Knit controller. Reads the sprint/dash keys and makes movement feel
-- instant -- it predicts locally instead of waiting for a server round trip.
-- The server (MovementService) is still the one deciding whether that
-- prediction was actually allowed to happen (see the file's comments).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MovementConfig = require(ReplicatedStorage.Shared.config.MovementConfig)

local MovementController = Knit.CreateController { Name = "MovementController" }

local SPRINT_KEY = Enum.KeyCode.LeftShift
local DASH_KEY = Enum.KeyCode.Q

local localPlayer = Players.LocalPlayer
local isSprintKeyDown = false
local isDashing = false -- local prediction of the commitment window
local lastLocalDashClock = -math.huge

local MovementService -- fetched in KnitStart, once Knit is fully booted

local function getCharacterParts()
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		return nil
	end
	return character, humanoid, rootPart
end

-- Sets WalkSpeed immediately based on what we THINK is true. The server's
-- Heartbeat loop re-asserts the real value every frame regardless, so if
-- we're wrong (say, stamina actually hit 0 a moment ago) it self-corrects
-- within one network round trip -- you'll feel a brief speed change instead
-- of the game silently lying about your stamina.
local function updateSprintPrediction()
	local _, humanoid = getCharacterParts()
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = isSprintKeyDown and MovementConfig.SprintSpeed or MovementConfig.WalkSpeed
end

local function tryDash()
	if isDashing then
		return
	end

	local now = os.clock()
	if now - lastLocalDashClock < MovementConfig.DashCooldown then
		return -- our own predicted cooldown -- keeps an honest client from spamming the key
	end

	local character, humanoid, rootPart = getCharacterParts()
	if not character or not humanoid or not rootPart then
		return
	end

	lastLocalDashClock = now
	isDashing = true
	task.delay(MovementConfig.DashCommitDuration, function()
		isDashing = false
	end)

	-- Dash in whatever direction you're currently holding; if you're not
	-- holding a direction, dash the way you're facing.
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = rootPart.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	-- The actual movement: a LinearVelocity constraint is Roblox's modern way
	-- to shove a physics object in a direction for a short time. We create it
	-- locally and destroy it after DashDuration -- this is the "prediction":
	-- it happens now, before the server has even heard about it.
	local velocity = Instance.new("LinearVelocity")
	velocity.MaxForce = math.huge
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VectorVelocity = direction * MovementConfig.DashSpeed
	velocity.Attachment0 = rootPart:FindFirstChild("RootAttachment")
	velocity.Parent = rootPart

	task.delay(MovementConfig.DashDuration, function()
		velocity:Destroy()
	end)

	-- Ask the server to validate this. We don't wait for the answer before
	-- moving -- that would defeat the point -- but invulnerability only ever
	-- exists if this comes back true. If it comes back false (e.g. our local
	-- cooldown clock drifted from the server's), we still played the movement,
	-- but no i-frames were granted for it.
	MovementService:RequestDash():andThen(function(approved)
		if not approved then
			warn("[MovementController] Dash was not approved by the server")
		end
	end)
end

function MovementController:KnitStart()
	MovementService = Knit.GetService("MovementService")

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return -- ignore key presses that are actually going to a text box, etc.
		end
		if input.KeyCode == SPRINT_KEY then
			isSprintKeyDown = true
			updateSprintPrediction()
			MovementService:SetSprintInput(true)
		elseif input.KeyCode == DASH_KEY then
			tryDash()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		-- Deliberately NOT checking gameProcessedEvent here: if the sprint
		-- key was released while, say, a menu had focus, we still want to
		-- know it's up. Otherwise sprint could get stuck on.
		if input.KeyCode == SPRINT_KEY then
			isSprintKeyDown = false
			updateSprintPrediction()
			MovementService:SetSprintInput(false)
		end
	end)
end

return MovementController
