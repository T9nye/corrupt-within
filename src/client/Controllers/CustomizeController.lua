-- Knit controller. The character customization screen: camera frames a
-- preview of the player's own avatar, body colour and outfit tint are
-- picked live on that preview, and Confirm writes the choice to the
-- profile via DataService so it's still there next time they log in.
--
-- Players:CreateHumanoidModelFromUserId(userId) is a Roblox API built for
-- exactly this -- it returns a rig wearing that player's actual avatar,
-- with no character needing to exist in the world yet. That matters here
-- specifically because MenuService keeps CharacterAutoLoads off until PLAY,
-- so there IS no real character to point a camera at.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local UIConfig = require(ReplicatedStorage.Shared.config.UIConfig)
local CosmeticsConfig = require(ReplicatedStorage.Shared.config.CosmeticsConfig)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local CustomizeController = Knit.CreateController { Name = "CustomizeController" }

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Far above the map, out of the way of everything else. Nothing else is out
-- here, so there's no need to build a dedicated "customize room" in the
-- Haven itself for a screen that's really just a camera and a rig.
local STAGE_POSITION = Vector3.new(0, 500, 0)

local DataService
local panel
local previewRig
local selectedBodyColor, selectedOutfit

-- Explicit whitelist of body part names, covering both current rig types
-- (R15 and the older R6). This -- not "everything except accessories" --
-- is what keeps this function from touching anything else parented to the
-- character. A playtest of the first version (which excluded only
-- Accessories) caught exactly this: WeaponService welds the sword directly
-- onto the character, so "recolor everything" recoloured the blade green
-- along with the player. Naming exactly what counts as "the body" avoids
-- that regardless of what else ever gets attached to a character later.
local TORSO_PART_NAMES = {
	UpperTorso = true, LowerTorso = true, -- R15
	Torso = true, -- R6
}
local BODY_PART_NAMES = {
	Head = true,
	UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
	RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
	RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	Torso = true, ["Left Arm"] = true, ["Right Arm"] = true,
	["Left Leg"] = true, ["Right Leg"] = true,
}

-- Applies the current selections to any rig -- the preview OR the player's
-- real character. Body colour goes on every limb/head part; the outfit
-- tint goes on the torso pieces afterward, so it always wins there.
local function applyCosmetics(rig, bodyColorId, outfitId)
	local bodyColor, outfitTint
	for _, entry in ipairs(CosmeticsConfig.BodyColors) do
		if entry.id == bodyColorId then
			bodyColor = entry.color
		end
	end
	for _, entry in ipairs(CosmeticsConfig.OutfitPresets) do
		if entry.id == outfitId then
			outfitTint = entry.tint
		end
	end

	for _, part in ipairs(rig:GetDescendants()) do
		if part:IsA("BasePart") and BODY_PART_NAMES[part.Name] then
			if TORSO_PART_NAMES[part.Name] and outfitTint then
				part.Color = outfitTint
			elseif bodyColor then
				part.Color = bodyColor
			end
		end
	end
end

local function destroyPreview()
	if previewRig then
		previewRig:Destroy()
		previewRig = nil
	end
end

local function buildPreview()
	destroyPreview()
	previewRig = Players:CreateHumanoidModelFromUserId(player.UserId)
	previewRig.Name = "CustomizePreview"

	for _, part in ipairs(previewRig:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	previewRig:PivotTo(CFrame.new(STAGE_POSITION))
	previewRig.Parent = Workspace

	applyCosmetics(previewRig, selectedBodyColor, selectedOutfit)
end

local function pointCameraAtStage()
	Knit.GetController("MenuController"):StopBackgroundCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	-- An unrotated character faces -Z (its LookVector is (0,0,-1)), so the
	-- camera needs to sit on the -Z side, looking back in the +Z direction,
	-- to see its FRONT. Placing it on +Z instead -- an easy mistake, and
	-- the one caught in this pass's playtest -- shows the character's back.
	local eye = STAGE_POSITION + Vector3.new(0, 2, -9)
	local target = STAGE_POSITION + Vector3.new(0, 2.5, 0)
	camera.CFrame = CFrame.lookAt(eye, target)
end

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------

local function swatchRow(parent, label, y, entries, selectedId, colorKey, onPick)
	UIKit.label(parent, label, UDim2.new(0, 200, 0, 24), UDim2.new(0, 0, 0, y), {
		Font = UIConfig.Fonts.Bold,
		TextSize = 16,
	})

	local swatchButtons = {}
	local size, gap = 40, 10
	for i, entry in ipairs(entries) do
		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.Size = UDim2.new(0, size, 0, size)
		btn.Position = UDim2.new(0, (i - 1) * (size + gap), 0, y + 28)
		btn.BackgroundColor3 = entry[colorKey]
		btn.AutoButtonColor = false
		btn.Parent = parent
		UIKit.corner(btn, 6)
		local outline = UIKit.stroke(btn, entry.id == selectedId and UIConfig.Colors.Accent or UIConfig.Colors.PanelBorder, entry.id == selectedId and 3 or 1)
		swatchButtons[entry.id] = outline

		btn.MouseButton1Click:Connect(function()
			for id, stroke in pairs(swatchButtons) do
				stroke.Color = (id == entry.id) and UIConfig.Colors.Accent or UIConfig.Colors.PanelBorder
				stroke.Thickness = (id == entry.id) and 3 or 1
			end
			onPick(entry.id)
		end)
	end

	return y + 28 + size + 20
end

local function buildPanel()
	local gui = Knit.GetController("MenuController"):GetGui()

	panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.Parent = gui

	local sidebar = UIKit.panel(panel, UDim2.new(0, 300, 0, 480), UDim2.new(0, 40, 0.5, 0), {
		AnchorPoint = Vector2.new(0, 0.5),
		Transparency = 0.05,
	})

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -40, 1, -40)
	inner.Position = UDim2.new(0, 20, 0, 20)
	inner.BackgroundTransparency = 1
	inner.Parent = sidebar

	UIKit.label(inner, "CUSTOMIZE", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), {
		Font = UIConfig.Fonts.Title,
		TextSize = 24,
	})

	local nextY = 50
	nextY = swatchRow(inner, "Body Colour", nextY, CosmeticsConfig.BodyColors, selectedBodyColor, "color", function(id)
		selectedBodyColor = id
		applyCosmetics(previewRig, selectedBodyColor, selectedOutfit)
	end)
	nextY = swatchRow(inner, "Outfit", nextY, CosmeticsConfig.OutfitPresets, selectedOutfit, "tint", function(id)
		selectedOutfit = id
		applyCosmetics(previewRig, selectedBodyColor, selectedOutfit)
	end)

	-- "Owned cosmetics" beyond the baseline set -- empty on a fresh profile
	-- since nothing earns cosmetics yet, but the row exists for when
	-- something does.
	UIKit.label(inner, "Owned Cosmetics", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, nextY), {
		Font = UIConfig.Fonts.Bold,
		TextSize = 16,
	})
	local ownedLabel = UIKit.label(inner, "None yet.", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, nextY + 26), {
		Color = UIConfig.Colors.TextSecondary,
		TextSize = 14,
		Wrapped = true,
	})

	UIKit.button(inner, "BACK", UDim2.new(0, 120, 0, 44), UDim2.new(0, 0, 1, -44), function()
		CustomizeController:Close()
	end)
	UIKit.button(inner, "CONFIRM", UDim2.new(0, 130, 0, 44), UDim2.new(1, -130, 1, -44), function()
		DataService:SaveCosmetics({ bodyColor = selectedBodyColor, outfit = selectedOutfit }):andThen(function()
			CustomizeController:Close()
		end)
	end, { Color = UIConfig.Colors.AccentDim, HoverColor = UIConfig.Colors.Accent })

	return ownedLabel
end

local ownedLabel

function CustomizeController:Open()
	DataService = DataService or Knit.GetService("DataService")

	DataService:GetCosmetics():andThen(function(cosmetics)
		selectedBodyColor = cosmetics.equipped.bodyColor or CosmeticsConfig.DefaultBodyColor
		selectedOutfit = cosmetics.equipped.outfit or CosmeticsConfig.DefaultOutfit

		if not panel then
			ownedLabel = buildPanel()
		end

		-- Anything owned beyond the baseline body colours/outfits.
		local baseline = {}
		for _, e in ipairs(CosmeticsConfig.BodyColors) do baseline[e.id] = true end
		for _, e in ipairs(CosmeticsConfig.OutfitPresets) do baseline[e.id] = true end
		local extra = {}
		for _, id in ipairs(cosmetics.owned) do
			if not baseline[id] then
				table.insert(extra, id)
			end
		end
		ownedLabel.Text = (#extra > 0) and table.concat(extra, ", ") or "None yet."

		buildPreview()
		pointCameraAtStage()
		panel.Visible = true
	end)
end

function CustomizeController:Close()
	panel.Visible = false
	destroyPreview()
	Knit.GetController("MenuController"):SetBackgroundCamera()
	Knit.GetController("MenuController"):ShowMenuPanel()
end

-- Applies whatever's saved in the profile to the player's REAL character,
-- so choosing a body colour in Customize is actually visible once you play,
-- not just in the preview.
--
-- This listens for BOTH CharacterAdded and CharacterAppearanceLoaded,
-- applying the same recolor on each. That redundancy is deliberate, and
-- came from a genuine dead end in this pass's playtest: CharacterAdded
-- fires as soon as the character model exists, but a real player's avatar
-- appearance (body colours, clothing) can keep loading asynchronously
-- afterward and overwrite a too-early recolor -- which is what
-- CharacterAppearanceLoaded exists to signal the end of. The dead end was
-- trusting that signal exclusively: in this Studio Play Solo session it
-- never fired at all (confirmed by forcing a respawn and watching for it),
-- so an appearance-loaded-only listener silently never ran. Applying on
-- CharacterAdded covers exactly that case; re-applying if
-- CharacterAppearanceLoaded also happens to fire covers the late-overwrite
-- case. Running the same idempotent recolor twice costs nothing.
function CustomizeController:KnitStart()
	local function applyToRealCharacter(character)
		local ds = Knit.GetService("DataService")
		ds:GetCosmetics():andThen(function(cosmetics)
			if character.Parent then
				applyCosmetics(character, cosmetics.equipped.bodyColor, cosmetics.equipped.outfit)
			end
		end)
	end

	player.CharacterAdded:Connect(applyToRealCharacter)
	player.CharacterAppearanceLoaded:Connect(applyToRealCharacter)
	if player.Character then
		applyToRealCharacter(player.Character)
	end
end

return CustomizeController
