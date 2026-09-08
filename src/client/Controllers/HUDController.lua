-- Knit controller. Builds the on-screen HUD in code (no .rbxmx assets to keep
-- in sync) and drives it from the Player attributes MovementService
-- republishes. It reads state -- it never decides state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MovementConfig = require(ReplicatedStorage.Shared.config.MovementConfig)

local HUDController = Knit.CreateController { Name = "HUDController" }

local localPlayer = Players.LocalPlayer

-- Palette: muted greys plus the same warm lantern amber used on the Haven's
-- lamps, per docs/haven-build.md's "no saturated colour except lantern warmth".
local TRACK_COLOR = Color3.fromRGB(28, 28, 32)
local FILL_COLOR = Color3.fromRGB(255, 160, 60)
local FILL_EMPTY_COLOR = Color3.fromRGB(120, 60, 40)
local PIP_FULL_COLOR = Color3.fromRGB(255, 160, 60)
local PIP_EMPTY_COLOR = Color3.fromRGB(60, 60, 66)

local staminaFill
local chargePips = {}

-- UDim2 is Roblox's UI coordinate type: {scale, offset} per axis, where
-- scale is a fraction of the parent and offset is raw pixels. Using scale
-- for position keeps the HUD anchored correctly on any screen size.
local function buildHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false -- survive respawns instead of being rebuilt
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

	local track = Instance.new("Frame")
	track.Name = "StaminaTrack"
	track.Size = UDim2.new(0, 260, 0, 10)
	track.Position = UDim2.new(0.5, 0, 1, -70)
	track.AnchorPoint = Vector2.new(0.5, 0) -- position refers to the frame's own centre-top
	track.BackgroundColor3 = TRACK_COLOR
	track.BorderSizePixel = 0
	track.Parent = screenGui

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 4)
	trackCorner.Parent = track

	staminaFill = Instance.new("Frame")
	staminaFill.Name = "StaminaFill"
	staminaFill.Size = UDim2.new(1, 0, 1, 0)
	staminaFill.BackgroundColor3 = FILL_COLOR
	staminaFill.BorderSizePixel = 0
	staminaFill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = staminaFill

	-- Dash charge bars: one discrete bar per charge, laid out in a row under
	-- the stamina bar. Each is its own little track+fill pair so a
	-- regenerating charge can show partial progress rather than just blinking
	-- from empty to full.
	--
	-- The row is the same total width as the stamina bar and divides itself
	-- between however many charges the config declares, so raising
	-- DashMaxCharges (the Endurance skill node in progression.md) needs no
	-- layout changes here.
	local maxCharges = MovementConfig.DashMaxCharges
	local ROW_WIDTH, PIP_GAP = 260, 4
	local pipWidth = (ROW_WIDTH - PIP_GAP * (maxCharges - 1)) / maxCharges

	local pipRow = Instance.new("Frame")
	pipRow.Name = "DashCharges"
	pipRow.Size = UDim2.new(0, ROW_WIDTH, 0, 8)
	pipRow.Position = UDim2.new(0.5, 0, 1, -56)
	pipRow.AnchorPoint = Vector2.new(0.5, 0)
	pipRow.BackgroundTransparency = 1
	pipRow.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, PIP_GAP)
	layout.Parent = pipRow

	for i = 1, maxCharges do
		local track = Instance.new("Frame")
		track.Name = "Pip" .. i
		track.Size = UDim2.new(0, pipWidth, 1, 0)
		track.BackgroundColor3 = PIP_EMPTY_COLOR
		track.BorderSizePixel = 0
		track.LayoutOrder = i
		track.Parent = pipRow

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(0, 3)
		trackCorner.Parent = track

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = PIP_FULL_COLOR
		fill.BorderSizePixel = 0
		fill.Parent = track

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 3)
		fillCorner.Parent = fill

		chargePips[i] = fill
	end
end

local function updateStamina()
	if not staminaFill then
		return
	end
	local stamina = localPlayer:GetAttribute("Stamina") or MovementConfig.MaxStamina
	local maxStamina = localPlayer:GetAttribute("MaxStamina") or MovementConfig.MaxStamina
	local fraction = math.clamp(stamina / maxStamina, 0, 1)

	-- Tween rather than snap, so the bar reads as draining instead of
	-- stuttering in 10Hz steps (the rate the server republishes at).
	TweenService:Create(
		staminaFill,
		TweenInfo.new(MovementConfig.StaminaPushInterval, Enum.EasingStyle.Linear),
		{
			Size = UDim2.new(fraction, 0, 1, 0),
			BackgroundColor3 = fraction <= 0.001 and FILL_EMPTY_COLOR or FILL_COLOR,
		}
	):Play()
end

-- Regeneration timers, predicted locally purely so the bars can animate.
-- The server owns the authoritative charge *count*; this list only decides
-- how full a partially-regenerated bar looks. Kept sorted ascending, so
-- pendingTimers[1] is always the next charge to come back.
local pendingTimers = {}
local lastKnownCharges = MovementConfig.DashMaxCharges

-- Called whenever the server publishes a new charge count. We diff against
-- what we last saw to work out whether charges were spent or refunded.
local function onChargesChanged()
	local charges = localPlayer:GetAttribute("DashCharges") or MovementConfig.DashMaxCharges
	local delta = charges - lastKnownCharges

	if delta < 0 then
		-- Spent. Each spent charge begins its own regen window. Appending
		-- keeps the list sorted, since a later spend always finishes later.
		for _ = 1, -delta do
			table.insert(pendingTimers, os.clock() + MovementConfig.DashChargeRegenTime)
		end
	elseif delta > 0 then
		-- Refunded. Drop the timers that just matured, from the front.
		for _ = 1, delta do
			table.remove(pendingTimers, 1)
		end
	end

	lastKnownCharges = charges
end

-- Runs every frame. Bars left of the current count are solid; the first
-- empty bar shows the soonest-maturing timer, the next shows the one after
-- that, and so on -- so the row always fills left to right.
local function renderCharges()
	local charges = lastKnownCharges
	local regenTime = MovementConfig.DashChargeRegenTime
	local now = os.clock()

	for i, fill in ipairs(chargePips) do
		if i <= charges then
			fill.Size = UDim2.fromScale(1, 1)
			fill.BackgroundTransparency = 0
		else
			local timer = pendingTimers[i - charges]
			if timer then
				local remaining = math.max(0, timer - now)
				local progress = math.clamp(1 - (remaining / regenTime), 0, 1)
				fill.Size = UDim2.fromScale(progress, 1)
				-- Fade the partial fill slightly so a regenerating bar reads
				-- as "not ready yet" at a glance, not as a short full bar.
				fill.BackgroundTransparency = 0.35
			else
				fill.Size = UDim2.fromScale(0, 1)
			end
		end
	end
end

function HUDController:KnitStart()
	buildHUD()
	updateStamina()

	lastKnownCharges = localPlayer:GetAttribute("DashCharges") or MovementConfig.DashMaxCharges
	renderCharges()

	localPlayer:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
	localPlayer:GetAttributeChangedSignal("MaxStamina"):Connect(updateStamina)
	localPlayer:GetAttributeChangedSignal("DashCharges"):Connect(onChargesChanged)

	-- The bars animate between attribute updates, so they need a per-frame
	-- tick rather than only redrawing when the server tells us something.
	RunService.RenderStepped:Connect(renderCharges)
end

return HUDController
