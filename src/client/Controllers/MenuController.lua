-- Knit controller. Owns the loading screen, the main menu, and the shared
-- ScreenGui/camera that Customize and Settings borrow while they're open.
--
-- Roblox concepts used here, if you haven't hit them yet:
--   ContentProvider:PreloadAsync -- asks the engine to fetch a list of
--     assets (textures, meshes, sounds) into memory before you need them,
--     and calls you back once per asset as each one finishes. That per-item
--     callback is what gives us a REAL progress percentage instead of a
--     fake timer.
--   Camera.CameraType = Scriptable -- takes the camera away from Roblox's
--     built-in follow-the-character script and hands full control of its
--     CFrame to our own code. Setting it back to Custom gives control back.

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local UIConfig = require(ReplicatedStorage.Shared.config.UIConfig)
local MovementConfig = require(ReplicatedStorage.Shared.config.MovementConfig)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local MenuController = Knit.CreateController { Name = "MenuController" }

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local MenuService, DataService

local screenGui
local loadingPanel
local menuPanel
local tipLabel, progressFill, progressPercentLabel

local menuCameraConnection
local MENU_CAMERA_ORBIT_SPEED = 0.03 -- radians/second -- slow, so it reads as "ambient", not "spinning"

-- A fixed establishing shot: elevated, near the gate, looking back up the
-- approach toward the plaza. Orbits gently around this focus point.
local MENU_CAMERA_FOCUS = Vector3.new(0, 6, 40)
local MENU_CAMERA_RADIUS = 95
local MENU_CAMERA_HEIGHT = 30

local function pointOnOrbit(angle)
	return MENU_CAMERA_FOCUS + Vector3.new(math.sin(angle) * MENU_CAMERA_RADIUS, MENU_CAMERA_HEIGHT, math.cos(angle) * MENU_CAMERA_RADIUS)
end

-- Puts the camera on the slow orbiting shot used behind the loading screen
-- and the main menu. Customize/Settings call this to hand the shot back
-- when they close; MenuController calls it once at startup.
function MenuController:SetBackgroundCamera()
	if menuCameraConnection then
		menuCameraConnection:Disconnect()
	end
	camera.CameraType = Enum.CameraType.Scriptable

	local angle = 0
	camera.CFrame = CFrame.lookAt(pointOnOrbit(angle), MENU_CAMERA_FOCUS)

	menuCameraConnection = RunService.RenderStepped:Connect(function(dt)
		angle += MENU_CAMERA_ORBIT_SPEED * dt
		camera.CFrame = CFrame.lookAt(pointOnOrbit(angle), MENU_CAMERA_FOCUS)
	end)
end

-- Stops the orbit without starting anything else. Anything that needs the
-- camera for its own purposes (Customize's character-framing shot) calls
-- this first -- without it, the orbit's RenderStepped connection would keep
-- overwriting camera.CFrame every frame regardless of what anyone else set
-- it to, since a Connect()'d function keeps running until disconnected.
function MenuController:StopBackgroundCamera()
	if menuCameraConnection then
		menuCameraConnection:Disconnect()
		menuCameraConnection = nil
	end
end

function MenuController:GetGui()
	return screenGui
end

function MenuController:ShowMenuPanel()
	menuPanel.Visible = true
end

function MenuController:HideMenuPanel()
	menuPanel.Visible = false
end

----------------------------------------------------------------------
-- UI construction
----------------------------------------------------------------------

local function buildLoadingPanel()
	local panel = UIKit.panel(screenGui, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), {
		Color = UIConfig.Colors.Background,
		CornerRadius = 0,
		NoBorder = true,
	})

	-- Subtle corruption motif: a thin purple line that glows faintly rather
	-- than a literal particle effect -- "subtle" per the brief, and it's
	-- cheap to render on every device.
	local motif = Instance.new("Frame")
	motif.Size = UDim2.new(0, 3, 0, 220)
	motif.Position = UDim2.fromScale(0.5, 0.5)
	motif.AnchorPoint = Vector2.new(0.5, 1)
	motif.BackgroundColor3 = UIConfig.Colors.Corruption
	motif.BackgroundTransparency = 0.4
	motif.BorderSizePixel = 0
	motif.Parent = panel
	UIKit.corner(motif, 2)

	UIKit.label(panel, "CORRUPT WITHIN", UDim2.new(0, 700, 0, 60), UDim2.fromScale(0.5, 0.5), {
		AnchorPoint = Vector2.new(0.5, 1),
		Font = UIConfig.Fonts.Title,
		TextSize = 44,
		XAlignment = Enum.TextXAlignment.Center,
	})

	local track, fill = UIKit.progressBar(panel, UDim2.new(0, 480, 0, 10), UDim2.fromScale(0.5, 0.62), {
		AnchorPoint = Vector2.new(0.5, 0),
	})
	progressFill = fill

	progressPercentLabel = UIKit.label(panel, "0%", UDim2.new(0, 480, 0, 20), UDim2.new(0.5, 0, 0.62, 16), {
		AnchorPoint = Vector2.new(0.5, 0),
		XAlignment = Enum.TextXAlignment.Center,
		Color = UIConfig.Colors.TextSecondary,
		TextSize = 14,
	})

	tipLabel = UIKit.label(panel, "", UDim2.new(0, 600, 0, 40), UDim2.new(0.5, 0, 0.72, 0), {
		AnchorPoint = Vector2.new(0.5, 0),
		XAlignment = Enum.TextXAlignment.Center,
		Color = UIConfig.Colors.TextSecondary,
		TextSize = 16,
		Wrapped = true,
	})

	return panel
end

local function buildMenuPanel()
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.Parent = screenGui

	UIKit.label(panel, "CORRUPT WITHIN", UDim2.new(0, 700, 0, 60), UDim2.new(0.5, 0, 0.28, 0), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Font = UIConfig.Fonts.Title,
		TextSize = 44,
		XAlignment = Enum.TextXAlignment.Center,
	})

	-- Three buttons stacked with a fixed pixel gap. Using UDim2's offset
	-- component (the second number in each pair) for the gap, rather than
	-- fighting with scale fractions, is what keeps the spacing between them
	-- constant regardless of screen resolution.
	local buttonWidth, buttonHeight, gap = 320, 56, 16
	local startYScale = 0.52

	local function buttonSlot(index)
		return UDim2.new(0.5, 0, startYScale, index * (buttonHeight + gap))
	end

	local playButton = UIKit.button(panel, "PLAY", UDim2.new(0, buttonWidth, 0, buttonHeight), buttonSlot(0), nil, {
		AnchorPoint = Vector2.new(0.5, 0),
		Color = UIConfig.Colors.AccentDim,
		TextColor = UIConfig.Colors.TextPrimary,
		HoverColor = UIConfig.Colors.Accent,
		TextSize = 24,
	})
	local customizeButton = UIKit.button(panel, "CUSTOMIZE", UDim2.new(0, buttonWidth, 0, buttonHeight), buttonSlot(1), nil, {
		AnchorPoint = Vector2.new(0.5, 0),
	})
	local settingsButton = UIKit.button(panel, "SETTINGS", UDim2.new(0, buttonWidth, 0, buttonHeight), buttonSlot(2), nil, {
		AnchorPoint = Vector2.new(0.5, 0),
	})

	playButton.MouseButton1Click:Connect(function()
		MenuController:OnPlayPressed(playButton)
	end)
	customizeButton.MouseButton1Click:Connect(function()
		MenuController:HideMenuPanel()
		Knit.GetController("CustomizeController"):Open()
	end)
	settingsButton.MouseButton1Click:Connect(function()
		MenuController:HideMenuPanel()
		Knit.GetController("SettingsController"):Open(function()
			MenuController:ShowMenuPanel()
		end)
	end)

	return panel
end

----------------------------------------------------------------------
-- PLAY
----------------------------------------------------------------------

function MenuController:OnPlayPressed(playButton)
	playButton.Active = false -- stop double-clicks while we're spawning

	MenuService:RequestSpawn():andThen(function()
		-- Give the character a moment to actually exist before we fade and
		-- hand back the camera -- LoadCharacter() is not instant.
		if not player.Character then
			player.CharacterAdded:Wait()
		end

		UIKit.fade(screenGui, 1, UIConfig.FadeTime, function()
			screenGui.Enabled = false
			if menuCameraConnection then
				menuCameraConnection:Disconnect()
				menuCameraConnection = nil
			end
			camera.CameraType = Enum.CameraType.Custom
			-- Settings' FOV slider only writes camera.FieldOfView while the
			-- camera is already Custom (a playtest showed why: during the
			-- menu the camera is Scriptable, so that write was silently
			-- skipped and never re-applied once Custom came back). Apply
			-- the saved value now that Custom control is actually restored.
			camera.FieldOfView = MovementConfig.DefaultFOV
		end)
	end)
end

----------------------------------------------------------------------
-- Loading sequence
----------------------------------------------------------------------

local function rotateTips()
	local index = 0
	while loadingPanel.Parent do
		index = (index % #UIConfig.Tips) + 1
		tipLabel.Text = UIConfig.Tips[index]
		task.wait(UIConfig.TipRotationInterval)
	end
end

-- Preloads everything currently in the Haven. Runs on its own thread because
-- PreloadAsync blocks until every asset resolves; `onProgress` is called
-- with a 0-1 fraction as each one finishes.
local function preloadHaven(onProgress)
	local assets = Workspace:GetDescendants()
	local total = math.max(#assets, 1)
	local done = 0

	ContentProvider:PreloadAsync(assets, function()
		done += 1
		onProgress(done / total)
	end)
end

local function waitForProfile()
	if player:GetAttribute("ProfileLoaded") then
		return
	end
	player:GetAttributeChangedSignal("ProfileLoaded"):Wait()
end

local function runIntroSequence()
	task.spawn(rotateTips)

	local preloadDone = false
	local profileDone = false

	-- The bar shows real PreloadAsync progress directly. There's currently
	-- very little to preload (the Haven is almost entirely plain grey-box
	-- parts, no textures/meshes/sounds yet), so today this will jump to
	-- 100% within a frame or two -- that's an honest reflection of the
	-- game's current asset footprint, not a bug in this code.
	task.spawn(function()
		preloadHaven(function(fraction)
			fraction = math.min(fraction, 1)
			progressFill.Size = UDim2.new(fraction, 0, 1, 0)
			progressPercentLabel.Text = string.format("%d%%", math.floor(fraction * 100))
		end)
		preloadDone = true
	end)

	task.spawn(function()
		waitForProfile()
		profileDone = true
	end)

	-- Both gates must clear -- real preload progress AND a confirmed,
	-- loaded profile -- before we're allowed to show the menu.
	while not (preloadDone and profileDone) do
		task.wait(0.1)
	end

	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressPercentLabel.Text = "100%"
	task.wait(0.3) -- let 100% actually be seen for a beat

	UIKit.fade(loadingPanel, 1, UIConfig.PanelSwitchTime, function()
		loadingPanel.Visible = false
		menuPanel.Visible = true
	end)
end

----------------------------------------------------------------------

function MenuController:KnitStart()
	MenuService = Knit.GetService("MenuService")
	DataService = Knit.GetService("DataService")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MenuGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.Parent = player:WaitForChild("PlayerGui")

	self:SetBackgroundCamera()

	loadingPanel = buildLoadingPanel()
	menuPanel = buildMenuPanel()

	runIntroSequence()
end

return MenuController
