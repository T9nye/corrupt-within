-- Knit controller. Turns mouse input into attack requests. It sends no
-- position, no target and no damage -- just "light" or "heavy" -- because
-- CombatService works all of that out from the server's own copy of where
-- your character is standing.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local WeaponConfig = require(ReplicatedStorage.Shared.config.WeaponConfig)

local CombatController = Knit.CreateController { Name = "CombatController" }

local localPlayer = Players.LocalPlayer

-- Heavy is on a key rather than MouseButton2 because right-click is also
-- Roblox's camera-rotate drag -- binding an attack there makes both feel bad.
local HEAVY_KEY = Enum.KeyCode.R

local CombatService

-- Local throttle so held/mashed clicks don't flood the remote. The server
-- enforces the real timing; this just stops us shouting.
local lastRequestClock = -math.huge
local MIN_REQUEST_GAP = 0.1

local function canSendRequest()
	local now = os.clock()
	if now - lastRequestClock < MIN_REQUEST_GAP then
		return false
	end
	lastRequestClock = now
	return true
end

local function requestLight()
	if not canSendRequest() then
		return
	end
	CombatService:RequestLightAttack():andThen(function(result)
		if not result then
			return -- refused: mid-commitment, mid-dash, or no character
		end
		-- Hook for animation/VFX later: result.step is which of the three
		-- chain hits landed, result.hits is how many things it connected with.
	end)
end

local function requestHeavy()
	if not canSendRequest() then
		return
	end
	CombatService:RequestHeavyAttack():andThen(function(result)
		if not result then
			return
		end
		-- result.cancelled is true when a dash interrupted the windup.
	end)
end

function CombatController:KnitStart()
	CombatService = Knit.GetService("CombatService")

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			requestLight()
		elseif input.KeyCode == HEAVY_KEY then
			requestHeavy()
		end
	end)
end

return CombatController
