-- Knit service. Owns every player's saved profile via ProfileStore.
-- Nothing else writes to Profile.Data directly — other services go through
-- the methods on this service, so there's one place where saving is decided.
--
-- ProfileStore gives us *session locking*: only one server can hold a given
-- player's profile at a time. That's what stops the classic duplication bug
-- where a player joins two servers and both write conflicting saves.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)
local SettingsConfig = require(ReplicatedStorage.Shared.config.SettingsConfig)
local CosmeticsConfig = require(ReplicatedStorage.Shared.config.CosmeticsConfig)

local DataService = Knit.CreateService {
	Name = "DataService",
	Client = {},
}

-- The shape of a brand-new player's save. Fields are exactly the seven listed
-- in docs/progression.md's Persistence section.
local PROFILE_TEMPLATE = {
	level = 1,
	xp = 0,

	-- 1-10 per weapon (docs/progression.md)
	weaponLevels = {
		Sword = 1,
		Greatsword = 1,
		DualBlades = 1,
	},

	-- Long-term mastery track, separate from the in-run corruption meter.
	corruptionMastery = {
		rank = 0,
		progress = 0, -- seconds survived at Consumed or above
	},

	skillPoints = {
		unspent = 0,
		spent = {
			Blade = 0,
			Endurance = 0,
			Corruption = 0,
		},
	},

	inventory = {}, -- array of item tables
	cosmetics = {
		-- Every body colour and starting outfit preset is free and
		-- available from the first login -- CosmeticsConfig.BodyColors and
		-- .OutfitPresets are baseline options, not unlocks. `owned` starts
		-- pre-populated with all of them so Customize has a full set to show
		-- immediately; anything added here LATER (a battle pass reward, a
		-- rare drop) is the "owned cosmetics" on top of this baseline.
		owned = (function()
			local ids = {}
			for _, entry in ipairs(CosmeticsConfig.BodyColors) do
				table.insert(ids, entry.id)
			end
			for _, entry in ipairs(CosmeticsConfig.OutfitPresets) do
				table.insert(ids, entry.id)
			end
			return ids
		end)(),
		equipped = {
			bodyColor = CosmeticsConfig.DefaultBodyColor,
			outfit = CosmeticsConfig.DefaultOutfit,
		},
	},

	-- Not in progression.md's list, but "save on region change" implies we
	-- track which region they're in.
	currentRegion = "Haven",

	-- Not in progression.md either -- added for the settings panel. Player
	-- preferences, not progression, but a profile is the only thing that
	-- persists per-player, so it lives here.
	settings = table.clone(SettingsConfig.Defaults),
}

local profiles = {} -- [Player] = Profile
local saveState = {} -- [Player] = { lastSaveClock, dirty }
local playerStore

-- Saving. progression.md asks for a save on level up, item gain and region
-- change, but firing a DataStore write on every single pickup would get us
-- throttled by Roblox. So requests inside MinInterval are coalesced: we mark
-- the profile dirty and the periodic loop flushes it.
local function requestSave(player, force)
	local profile = profiles[player]
	local tracker = saveState[player]
	if not profile or not tracker or not profile:IsActive() then
		return
	end

	local now = os.clock()
	if not force and now - tracker.lastSaveClock < ProgressionConfig.Save.MinInterval then
		tracker.dirty = true
		return
	end

	tracker.lastSaveClock = now
	tracker.dirty = false
	profile:Save()
end

local function onPlayerAdded(player)
	local profile = playerStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			-- Don't keep trying to claim the session if they've already left.
			return player:IsDescendantOf(Players) == false
		end,
	})

	if not profile then
		-- Another server holds the lock. Per ProfileStore's own guidance the
		-- right move is to kick rather than run the player on unsaveable data.
		player:Kick("Couldn't load your save. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId) -- tags the data as belonging to them, for GDPR-style deletion requests
	profile:Reconcile() -- fills in any template fields added since they last played

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		saveState[player] = nil
		if player:IsDescendantOf(Players) then
			player:Kick("Your save session ended. Please rejoin.")
		end
	end)

	if not player:IsDescendantOf(Players) then
		-- They left while we were loading.
		profile:EndSession()
		return
	end

	profiles[player] = profile
	saveState[player] = { lastSaveClock = os.clock(), dirty = false }

	-- LoadingController waits for this before it will advance past the
	-- loading screen. Attributes on a Player replicate to that player's own
	-- client automatically (same mechanism MovementService already uses for
	-- Stamina/DashCharges), so no remote call is needed to announce it.
	player:SetAttribute("ProfileLoaded", true)

	-- Health scales with level (docs/progression.md).
	local function applyLevelStats(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.MaxHealth = ProgressionConfig.HealthForLevel(profile.Data.level)
			humanoid.Health = humanoid.MaxHealth
		end
	end

	if player.Character then
		applyLevelStats(player.Character)
	end
	player.CharacterAdded:Connect(applyLevelStats)
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then
		profile:EndSession() -- ProfileStore performs a final save as part of this
	end
end

-- ---------------------------------------------------------------------
-- Public API for other services. They never touch Profile.Data directly.
-- ---------------------------------------------------------------------

function DataService:GetProfile(player)
	return profiles[player]
end

function DataService:GetData(player)
	local profile = profiles[player]
	return profile and profile.Data or nil
end

function DataService:AddXP(player, amount)
	local data = self:GetData(player)
	if not data or amount <= 0 then
		return
	end

	data.xp += amount
	local levelledUp = false

	-- A single kill can cross more than one level boundary at low levels.
	while data.level < ProgressionConfig.MaxLevel do
		local needed = ProgressionConfig.XPForNextLevel(data.level)
		if data.xp < needed then
			break
		end
		data.xp -= needed
		data.level += 1
		data.skillPoints.unspent += ProgressionConfig.SkillPointsPerLevel
		levelledUp = true
	end

	if levelledUp then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = ProgressionConfig.HealthForLevel(data.level)
			humanoid.Health = humanoid.MaxHealth
		end
		-- progression.md: save on level up.
		requestSave(player, true)
	end

	return levelledUp
end

function DataService:AddItem(player, item)
	local data = self:GetData(player)
	if not data then
		return false
	end
	table.insert(data.inventory, item)
	-- progression.md: save on item gain.
	requestSave(player)
	return true
end

function DataService:AddWeaponXP(player, weaponName, levels)
	local data = self:GetData(player)
	if not data or not data.weaponLevels[weaponName] then
		return
	end
	data.weaponLevels[weaponName] = math.min(
		ProgressionConfig.WeaponMaxLevel,
		data.weaponLevels[weaponName] + levels
	)
	requestSave(player)
end

function DataService:SetRegion(player, regionName)
	local data = self:GetData(player)
	if not data then
		return
	end
	data.currentRegion = regionName
	-- progression.md: save on region change.
	requestSave(player, true)
end

-- ---------------------------------------------------------------------
-- Client-facing reads/writes for Customize and Settings. These ARE on
-- .Client (unlike the methods above) because the menu UI calls them
-- directly across the network -- but every write is validated here, never
-- trusted as-is, per docs/architecture.md's "assume any client can lie".
-- ---------------------------------------------------------------------

function DataService.Client:GetCosmetics(player)
	local data = self.Server:GetData(player)
	return data and data.cosmetics or nil
end

function DataService.Client:SaveCosmetics(player, equipped)
	local data = self.Server:GetData(player)
	if not data or typeof(equipped) ~= "table" then
		return false
	end

	-- Only ever equip something this player actually owns. `owned` always
	-- contains at least the two starting presets, so this can't be emptied
	-- out into "nothing equippable".
	local owned = {}
	for _, id in ipairs(data.cosmetics.owned) do
		owned[id] = true
	end

	if typeof(equipped.bodyColor) == "string" and owned[equipped.bodyColor] then
		data.cosmetics.equipped.bodyColor = equipped.bodyColor
	end
	if typeof(equipped.outfit) == "string" and owned[equipped.outfit] then
		data.cosmetics.equipped.outfit = equipped.outfit
	end

	requestSave(player)
	return true
end

function DataService.Client:GetSettings(player)
	local data = self.Server:GetData(player)
	return data and data.settings or nil
end

function DataService.Client:SaveSettings(player, settings)
	local data = self.Server:GetData(player)
	if not data or typeof(settings) ~= "table" then
		return false
	end

	local ranges = SettingsConfig.Ranges
	local function clamp(value, range, fallback)
		if typeof(value) ~= "number" then
			return fallback
		end
		return math.clamp(value, range.Min, range.Max)
	end

	data.settings.MasterVolume = clamp(settings.MasterVolume, ranges.Volume, data.settings.MasterVolume)
	data.settings.MusicVolume = clamp(settings.MusicVolume, ranges.Volume, data.settings.MusicVolume)
	data.settings.SFXVolume = clamp(settings.SFXVolume, ranges.Volume, data.settings.SFXVolume)
	data.settings.MouseSensitivity = clamp(settings.MouseSensitivity, ranges.MouseSensitivity, data.settings.MouseSensitivity)
	data.settings.FOV = clamp(settings.FOV, ranges.FOV, data.settings.FOV)

	if typeof(settings.GraphicsQuality) == "string" then
		for _, option in ipairs(SettingsConfig.GraphicsQualityOptions) do
			if option == settings.GraphicsQuality then
				data.settings.GraphicsQuality = settings.GraphicsQuality
				break
			end
		end
	end

	requestSave(player)
	return true
end

function DataService:KnitInit()
	-- In Studio, use ProfileStore's built-in mock store so testing never
	-- touches (or needs) live DataStore keys. In a real server, use the real
	-- one. ProfileStore.Mock has an identical API.
	local store = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)
	playerStore = RunService:IsStudio() and store.Mock or store
end

function DataService:KnitStart()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	-- Anyone who joined before this service finished starting.
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	-- Award XP when something dies. This is the subscription hook EnemyService
	-- exposes -- DataService depends on EnemyService, EnemyService knows
	-- nothing about DataService, so there's no cycle.
	local EnemyService = Knit.GetService("EnemyService")
	EnemyService:OnEnemyDied(function(_enemy, drop)
		if drop.killedBy then
			self:AddXP(drop.killedBy, drop.xp)
		end
	end)

	-- progression.md: save every 60 seconds.
	task.spawn(function()
		while true do
			task.wait(ProgressionConfig.Save.PeriodicInterval)
			for player in pairs(profiles) do
				requestSave(player, true)
			end
		end
	end)

	-- Flush coalesced saves promptly rather than waiting for the 60s tick.
	task.spawn(function()
		while true do
			task.wait(ProgressionConfig.Save.MinInterval)
			for player, tracker in pairs(saveState) do
				if tracker.dirty then
					requestSave(player)
				end
			end
		end
	end)

	-- progression.md: "Always save on BindToClose." ProfileStore ends sessions
	-- on shutdown itself, but doing it explicitly means we control the order
	-- and it's obvious to anyone reading that shutdown is handled.
	game:BindToClose(function()
		for _, profile in pairs(profiles) do
			if profile:IsActive() then
				profile:EndSession()
			end
		end
	end)
end

return DataService
