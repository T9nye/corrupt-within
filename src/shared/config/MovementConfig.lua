-- Sprint/dash tuning. Nothing here is hardcoded into MovementService or
-- MovementController -- change a number here, not in the code.
return {
	-- Sprint
	WalkSpeed = 16, -- Roblox's default Humanoid.WalkSpeed
	SprintSpeed = 26,
	MaxStamina = 100,
	StaminaDrainPerSecond = 20, -- so a full bar sprints for 5 seconds straight
	StaminaRegenPerSecond = 15,
	StaminaRegenDelay = 1, -- seconds after you stop sprinting before regen kicks back in

	-- Dash
	DashSpeed = 50, -- studs/second during the dash impulse
	DashDuration = 0.2, -- how long the dash's movement impulse lasts
	DashIFrameDuration = 0.2, -- seconds of invulnerability, starting when the dash begins
	DashCommitDuration = 0.35, -- seconds you're "committed" -- can't dash again, and combat will later refuse attacks too

	-- Dash charges. Base is 1, which behaves exactly like a plain cooldown.
	-- docs/progression.md plans extra charges as an Endurance skill-tree node,
	-- so the system tracks charges rather than a single timer.
	DashMaxCharges = 1,
	DashChargeRegenTime = 1.5, -- seconds to regain one spent charge

	-- Camera feedback
	DefaultFOV = 70, -- Roblox's default Camera.FieldOfView
	SprintFOV = 78, -- widened slightly while sprinting -- sells the speed
	FOVTweenTime = 0.25, -- seconds to ease between the two

	-- How often the server republishes stamina to the client for the HUD.
	-- Every frame would be network spam; 10x/second is plenty for a bar.
	StaminaPushInterval = 0.1,
}
