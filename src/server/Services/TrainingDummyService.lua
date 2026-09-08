-- Knit service. Gives the training-yard dummy its behaviour: a health bar,
-- and standing back up after you flatten it.
--
-- The dummy's geometry lives in the place file (the map isn't in Rojo, per
-- docs/architecture.md). This service finds it by CollectionService tag and
-- attaches everything script-shaped, so the place file only has to hold dumb
-- parts plus a Humanoid.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EnemyConfig = require(ReplicatedStorage.Shared.config.EnemyConfig)

local TrainingDummyService = Knit.CreateService {
	Name = "TrainingDummyService",
	Client = {},
}

local DUMMY_TAG = "TrainingDummy"

-- CollectionService is Roblox's tagging system: you mark instances with a
-- string tag, then ask for everything carrying that tag. Better than matching
-- on names, which break the moment something gets renamed or duplicated.

local function buildHealthBar(dummy, config)
	local head = dummy:FindFirstChild("Head") or dummy.PrimaryPart
	if not head then
		return nil
	end

	local existing = head:FindFirstChild("HealthBar")
	if existing then
		existing:Destroy()
	end

	-- A BillboardGui is a piece of UI anchored to a part in the world that
	-- always turns to face the camera.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.new(0, 120, 0, 12)
	billboard.StudsOffset = Vector3.new(0, config.HealthBarOffset, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.Parent = head

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.fromScale(1, 1)
	track.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	track.BorderSizePixel = 0
	track.Parent = billboard

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 3)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(200, 70, 60)
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = fill

	return fill
end

local function setupDummy(dummy)
	local config = EnemyConfig.TrainingDummy
	local humanoid = dummy:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("[TrainingDummyService] tagged dummy has no Humanoid:", dummy:GetFullName())
		return
	end

	humanoid.MaxHealth = config.Health
	humanoid.Health = config.Health
	-- Stop Roblox's default name/health text from drawing over our own bar.
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	-- It's a post. It should not wander off or fall over.
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.BreakJointsOnDeath = false
	-- The dummy is anchored parts, not a jointed rig. Without this a Humanoid
	-- kills itself the moment it notices there's no Neck joint holding the head on.
	humanoid.RequiresNeck = false

	local fill = buildHealthBar(dummy, config)

	humanoid.HealthChanged:Connect(function(health)
		if fill and fill.Parent then
			fill.Size = UDim2.fromScale(math.clamp(health / humanoid.MaxHealth, 0, 1), 1)
		end
	end)

	humanoid.Died:Connect(function()
		task.delay(config.ResetDelay, function()
			if dummy.Parent and humanoid.Parent then
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	end)
end

function TrainingDummyService:KnitStart()
	for _, dummy in ipairs(CollectionService:GetTagged(DUMMY_TAG)) do
		setupDummy(dummy)
	end
	CollectionService:GetInstanceAddedSignal(DUMMY_TAG):Connect(setupDummy)
end

return TrainingDummyService
