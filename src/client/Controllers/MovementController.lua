-- Knit controller. Reads the sprint/dash keys and makes movement feel
-- instant -- it predicts locally instead of waiting for a server round trip.
-- The server (MovementService) is still the one deciding whether that
-- prediction was actually allowed to happen (see the file's comments).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MovementConfig = require(ReplicatedStorage.Shared.config.MovementConfig)

local MovementController = Knit.CreateController { Name = "MovementController" }

local SPRINT_KEY = Enum.KeyCode.LeftShift
local DASH_KEY = Enum.KeyCode.Q

local localPlayer = Players.LocalPlayer
local isSprintKeyDown = false
local isDashing = false -- local prediction of the commitment window
local predictedCharges = MovementConfig.DashMaxCharges -- resynced from the server below
local activeFOVTween = nil

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
-- Eases the camera's field of view. A slightly wider FOV while sprinting is
-- a cheap, very effective speed cue -- the world appears to rush past faster
-- without the character actually moving faster.
local function setFOV(target)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if activeFOVTween then
		activeFOVTween:Cancel()
	end
	activeFOVTween = TweenService:Create(
		camera,
		TweenInfo.new(MovementConfig.FOVTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = target }
	)
	activeFOVTween:Play()
end

local function updateSprintPrediction()
	local _, humanoid = getCharacterParts()
	if not humanoid then
		return
	end

	-- Stamina comes from a Player attribute the server republishes; if we're
	-- empty, don't predict a sprint we can't actually have.
	local stamina = localPlayer:GetAttribute("Stamina") or MovementConfig.MaxStamina
	local sprinting = isSprintKeyDown and stamina > 0

	humanoid.WalkSpeed = sprinting and MovementConfig.SprintSpeed or MovementConfig.WalkSpeed
	setFOV(sprinting and MovementConfig.SprintFOV or MovementConfig.DefaultFOV)
end

local function tryDash()
	if isDashing then
		return
	end

	if predictedCharges < 1 then
		return -- our own predicted charge count -- keeps an honest client from spamming the key
	end

	local character, humanoid, rootPart = getCharacterParts()
	if not character or not humanoid or not rootPart then
		return
	end

	predictedCharges -= 1
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

	-- The server is the source of truth for charges. Whenever it publishes a
	-- new count, snap our prediction back to it -- that's the "reconcile"
	-- half of predict-and-reconcile.
	localPlayer:GetAttributeChangedSignal("DashCharges"):Connect(function()
		predictedCharges = localPlayer:GetAttribute("DashCharges") or 0
	end)

	-- If stamina runs dry mid-sprint, drop out of the sprint FOV immediately
	-- rather than waiting for the next key event.
	localPlayer:GetAttributeChangedSignal("Stamina"):Connect(function()
		if isSprintKeyDown then
			updateSprintPrediction()
		end
	end)

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
