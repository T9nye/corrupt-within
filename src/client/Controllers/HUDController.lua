-- Knit controller. Builds the on-screen HUD in code (no .rbxmx assets to keep
-- in sync) and drives it from the Player attributes MovementService
-- republishes. It reads state -- it never decides state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

	-- Dash charge pips, laid out in a row just under the stamina bar. One pip
	-- per charge; DashMaxCharges is 1 today, so this renders a single pip.
	local pipRow = Instance.new("Frame")
	pipRow.Name = "DashCharges"
	pipRow.Size = UDim2.new(0, 260, 0, 8)
	pipRow.Position = UDim2.new(0.5, 0, 1, -56)
	pipRow.AnchorPoint = Vector2.new(0.5, 0)
	pipRow.BackgroundTransparency = 1
	pipRow.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = pipRow

	for i = 1, MovementConfig.DashMaxCharges do
		local pip = Instance.new("Frame")
		pip.Name = "Pip" .. i
		pip.Size = UDim2.new(0, 30, 0, 6)
		pip.BackgroundColor3 = PIP_FULL_COLOR
		pip.BorderSizePixel = 0
		pip.Parent = pipRow

		local pipCorner = Instance.new("UICorner")
		pipCorner.CornerRadius = UDim.new(0, 3)
		pipCorner.Parent = pip

		chargePips[i] = pip
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

local function updateCharges()
	local charges = localPlayer:GetAttribute("DashCharges") or MovementConfig.DashMaxCharges
	for i, pip in ipairs(chargePips) do
		pip.BackgroundColor3 = (i <= charges) and PIP_FULL_COLOR or PIP_EMPTY_COLOR
	end
end

function HUDController:KnitStart()
	buildHUD()
	updateStamina()
	updateCharges()

	localPlayer:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
	localPlayer:GetAttributeChangedSignal("MaxStamina"):Connect(updateStamina)
	localPlayer:GetAttributeChangedSignal("DashCharges"):Connect(updateCharges)
end

return HUDController
