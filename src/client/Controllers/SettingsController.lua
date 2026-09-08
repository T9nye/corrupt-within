-- Knit controller. THE settings panel -- built once, opened from wherever
-- needs it. MenuController opens it from the main menu today; a future
-- pause-menu controller opens it the exact same way, by calling
-- SettingsController:Open(onClose) with its own onClose. There is only one
-- copy of this UI and one copy of this logic, which is the whole point of
-- writing it as its own controller instead of inlining it into the menu.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local UIConfig = require(ReplicatedStorage.Shared.config.UIConfig)
local SettingsConfig = require(ReplicatedStorage.Shared.config.SettingsConfig)
local InputConfig = require(ReplicatedStorage.Shared.config.InputConfig)
local MovementConfig = require(ReplicatedStorage.Shared.config.MovementConfig)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local SettingsController = Knit.CreateController { Name = "SettingsController" }

local player = Players.LocalPlayer
local DataService

local panel
local current -- the working copy of settings being edited, applied live as sliders move
local onCloseCallback

----------------------------------------------------------------------
-- Applying a setting for real, immediately -- separate from saving it.
-- Sliding a volume bar should be heard (once there's audio) right away;
-- whether it's remembered next session is a different question, answered
-- only when Confirm is pressed.
----------------------------------------------------------------------

local function getOrCreateSoundGroup(name)
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Parent = SoundService
	return group
end

-- No Sound instances exist anywhere in the project yet -- there's no audio
-- content at all at this stage of the build. These SoundGroups are real
-- infrastructure, not a stub: the moment any Sound is parented under one of
-- them, these sliders will control it correctly.
local musicGroup = getOrCreateSoundGroup("Music")
local sfxGroup = getOrCreateSoundGroup("SFX")

local function applyVolumes()
	musicGroup.Volume = current.MasterVolume * current.MusicVolume
	sfxGroup.Volume = current.MasterVolume * current.SFXVolume
end

-- Roblox does NOT allow a normal game script to write
-- UserGameSettings.MouseSensitivity -- only Roblox's own CoreScripts can
-- (a playtest confirmed this: "lacking capability RobloxScript", not a
-- permissions bug on our end, a hard platform restriction). Actually
-- changing sensitivity live would mean replacing the default camera
-- control scripts with our own -- a much bigger feature than this slider.
-- For now the value is honestly just stored and persisted; it does not yet
-- affect the live camera. Flagging this clearly rather than faking it.
local function applySensitivity()
end

local function applyFOV()
	-- MovementConfig is a require()-cached table -- every script that
	-- requires it (MovementController included) shares this exact same
	-- table in memory. Writing DefaultFOV here means MovementController's
	-- existing per-frame read of that field picks up the new value with no
	-- signal or event needed between the two controllers.
	MovementConfig.DefaultFOV = current.FOV
	local camera = Workspace.CurrentCamera
	if camera and camera.CameraType == Enum.CameraType.Custom then
		camera.FieldOfView = current.FOV
	end
end

local function applyGraphicsQuality()
	local lighting = game.Lighting
	local isQuality = current.GraphicsQuality == "Quality"

	local bloom = lighting:FindFirstChild("Bloom")
	local sunRays = lighting:FindFirstChild("SunRays")
	local depthOfField = lighting:FindFirstChild("DepthOfField")
	if bloom then bloom.Enabled = isQuality end
	if sunRays then sunRays.Enabled = isQuality end
	if depthOfField then depthOfField.Enabled = isQuality end

	local atmosphere = lighting:FindFirstChild("Atmosphere")
	if atmosphere then
		atmosphere.Density = isQuality and 0.35 or 0.15
		atmosphere.Haze = isQuality and 1.4 or 0.3
	end
end

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------

local function buildPanel()
	local gui = Knit.GetController("MenuController"):GetGui()

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = gui

	local box = UIKit.panel(root, UDim2.new(0, 560, 0, 560), UDim2.fromScale(0.5, 0.5), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Transparency = 0.02,
	})

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -48, 1, -48)
	inner.Position = UDim2.new(0, 24, 0, 24)
	inner.BackgroundTransparency = 1
	inner.Parent = box

	UIKit.label(inner, "SETTINGS", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), {
		Font = UIConfig.Fonts.Title,
		TextSize = 24,
	})

	local y = 44
	local rowHeight = 34

	local function nextRow()
		local pos = y
		y += rowHeight
		return pos
	end

	UIKit.slider(inner, "Master Volume", UDim2.new(1, 0, 0, rowHeight), UDim2.new(0, 0, 0, nextRow()),
		SettingsConfig.Ranges.Volume.Min, SettingsConfig.Ranges.Volume.Max, current.MasterVolume, function(v)
			current.MasterVolume = v
			applyVolumes()
		end)
	UIKit.slider(inner, "Music Volume", UDim2.new(1, 0, 0, rowHeight), UDim2.new(0, 0, 0, nextRow()),
		SettingsConfig.Ranges.Volume.Min, SettingsConfig.Ranges.Volume.Max, current.MusicVolume, function(v)
			current.MusicVolume = v
			applyVolumes()
		end)
	UIKit.slider(inner, "SFX Volume", UDim2.new(1, 0, 0, rowHeight), UDim2.new(0, 0, 0, nextRow()),
		SettingsConfig.Ranges.Volume.Min, SettingsConfig.Ranges.Volume.Max, current.SFXVolume, function(v)
			current.SFXVolume = v
			applyVolumes()
		end)
	UIKit.slider(inner, "Mouse Sensitivity", UDim2.new(1, 0, 0, rowHeight), UDim2.new(0, 0, 0, nextRow()),
		SettingsConfig.Ranges.MouseSensitivity.Min, SettingsConfig.Ranges.MouseSensitivity.Max, current.MouseSensitivity, function(v)
			current.MouseSensitivity = v
			applySensitivity()
		end)
	UIKit.slider(inner, "Field of View", UDim2.new(1, 0, 0, rowHeight), UDim2.new(0, 0, 0, nextRow()),
		SettingsConfig.Ranges.FOV.Min, SettingsConfig.Ranges.FOV.Max, current.FOV, function(v)
			current.FOV = v
			applyFOV()
		end)

	y += 10
	UIKit.label(inner, "Graphics Quality", UDim2.new(0, 200, 0, 24), UDim2.new(0, 0, 0, nextRow()), {
		Font = UIConfig.Fonts.Bold,
		TextSize = 16,
	})

	local qualityButtons = {}
	for i, option in ipairs(SettingsConfig.GraphicsQualityOptions) do
		local btn = UIKit.button(inner, option, UDim2.new(0, 150, 0, 32), UDim2.new(0, (i - 1) * 160, 0, y), function()
			current.GraphicsQuality = option
			applyGraphicsQuality()
			for id, b in pairs(qualityButtons) do
				b.BackgroundColor3 = (id == option) and UIConfig.Colors.AccentDim or UIConfig.Colors.Panel
			end
		end, {
			Color = (current.GraphicsQuality == option) and UIConfig.Colors.AccentDim or UIConfig.Colors.Panel,
		})
		qualityButtons[option] = btn
	end
	y += 32 + 16

	UIKit.label(inner, "Keybinds", UDim2.new(0, 200, 0, 24), UDim2.new(0, 0, 0, nextRow()), {
		Font = UIConfig.Fonts.Bold,
		TextSize = 16,
	})
	for _, row in ipairs(InputConfig.Display) do
		UIKit.label(inner, row.action, UDim2.new(0, 200, 0, 20), UDim2.new(0, 0, 0, y), {
			Color = UIConfig.Colors.TextSecondary,
			TextSize = 14,
		})
		UIKit.label(inner, row.label, UDim2.new(0, 150, 0, 20), UDim2.new(0, 210, 0, y), {
			TextSize = 14,
		})
		y += 22
	end

	UIKit.button(inner, "BACK", UDim2.new(0, 120, 0, 44), UDim2.new(0, 0, 1, -44), function()
		SettingsController:Close()
	end)
	UIKit.button(inner, "CONFIRM", UDim2.new(0, 130, 0, 44), UDim2.new(1, -130, 1, -44), function()
		DataService:SaveSettings(current):andThen(function()
			SettingsController:Close()
		end)
	end, { Color = UIConfig.Colors.AccentDim, HoverColor = UIConfig.Colors.Accent })

	return root
end

function SettingsController:Open(onClose)
	DataService = DataService or Knit.GetService("DataService")
	onCloseCallback = onClose

	DataService:GetSettings():andThen(function(settings)
		current = table.clone(settings)

		-- Rebuild every time rather than caching the panel: sliders bake
		-- their starting value in when created, and a stale panel would
		-- show whatever was last opened instead of the profile's real,
		-- current values.
		if panel then
			panel:Destroy()
		end
		panel = buildPanel()
		panel.Visible = true

		applyVolumes()
		applySensitivity()
		applyFOV()
		applyGraphicsQuality()
	end)
end

function SettingsController:Close()
	panel.Visible = false
	if onCloseCallback then
		onCloseCallback()
	end
end

return SettingsController
