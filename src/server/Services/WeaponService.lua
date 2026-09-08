-- Knit service. Builds the grey-box sword and puts it in the player's hand
-- every time they spawn, then records what they're holding as a character
-- attribute so CombatService can look up the right stats.
--
-- Deliberately NOT a Roblox Tool. A Tool would sit in the backpack and need
-- equipping with a hotbar key or a click, and our attack input already runs
-- through CombatController's UserInputService bindings rather than
-- Tool.Activated. Welding straight to the hand means it is simply always
-- equipped, which is what "spawns with a sword" should mean.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local WeaponConfig = require(ReplicatedStorage.Shared.config.WeaponConfig)

local WeaponService = Knit.CreateService {
	Name = "WeaponService",
	Client = {},
}

-- R15 rigs call it "RightHand"; the older R6 rig calls it "Right Arm".
local function findHand(character)
	return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
end

local function buildSword(weaponName)
	local config = WeaponConfig[weaponName]
	local model = config.Model

	local sword = Instance.new("Model")
	sword.Name = weaponName

	-- Grip is the anchor piece everything else is positioned against, and the
	-- part that actually welds to the hand.
	local function piece(name, size, colour, material, offset)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = colour
		part.Material = material
		part.CanCollide = false -- must not shove the player around
		part.Massless = true -- and must not weigh their arm down
		part.Anchored = false -- anchored parts would not follow the character
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = sword
		part:SetAttribute("LocalOffset", offset)
		return part
	end

	local grip = piece("Grip", model.GripSize, model.GripColor, Enum.Material.Fabric, CFrame.new())
	piece("Pommel", model.PommelSize, model.GuardColor, Enum.Material.Metal,
		CFrame.new(0, -model.GripSize.Y / 2 - model.PommelSize.Y / 2, 0))
	piece("Guard", model.GuardSize, model.GuardColor, Enum.Material.Metal,
		CFrame.new(0, model.GripSize.Y / 2 + model.GuardSize.Y / 2, 0))
	piece("Blade", model.BladeSize, model.BladeColor, Enum.Material.Metal,
		CFrame.new(0, model.GripSize.Y / 2 + model.GuardSize.Y + model.BladeSize.Y / 2, 0))
	-- A slightly brighter sliver along the blade so it reads as an edge
	-- rather than a flat slab under the Haven's dim overcast lighting.
	piece("Edge", Vector3.new(model.BladeSize.X * 0.45, model.BladeSize.Y * 0.96, model.BladeSize.Z * 0.25),
		model.EdgeColor, Enum.Material.Metal,
		CFrame.new(0, model.GripSize.Y / 2 + model.GuardSize.Y + model.BladeSize.Y / 2, model.BladeSize.Z * 0.36))

	sword.PrimaryPart = grip
	return sword, grip
end

local function equip(character, weaponName)
	local hand = findHand(character)
	if not hand then
		warn("[WeaponService] no right hand found on", character:GetFullName())
		return
	end

	-- Clear anything left over from a previous life.
	local existing = character:FindFirstChild(weaponName)
	if existing then
		existing:Destroy()
	end

	local sword, grip = buildSword(weaponName)
	local handOffset = WeaponConfig[weaponName].Model.HandOffset

	-- WeldConstraint fixes parts in whatever relative position they're already
	-- in, so everything has to be moved into place FIRST, then welded.
	local gripCFrame = hand.CFrame * handOffset
	for _, part in ipairs(sword:GetChildren()) do
		part.CFrame = gripCFrame * part:GetAttribute("LocalOffset")
	end

	for _, part in ipairs(sword:GetChildren()) do
		if part ~= grip then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = grip
			weld.Part1 = part
			weld.Parent = grip
		end
	end

	local handWeld = Instance.new("WeldConstraint")
	handWeld.Part0 = hand
	handWeld.Part1 = grip
	handWeld.Parent = grip

	sword.Parent = character

	-- This is what CombatService reads to decide which stat block applies.
	character:SetAttribute("EquippedWeapon", weaponName)
end

local function onCharacterAdded(character)
	-- Wait for the rig to finish assembling, or the hand may not exist yet.
	character:WaitForChild("Humanoid", 10)
	if character:FindFirstChild("RightHand") == nil and character:FindFirstChild("Right Arm") == nil then
		character:WaitForChild("RightHand", 10)
	end
	equip(character, WeaponConfig.DefaultWeapon)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

function WeaponService:KnitStart()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return WeaponService
