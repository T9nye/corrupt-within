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

	-- Dash charges.
	--
	-- Each charge refills on its OWN timer, started the moment that charge is
	-- spent -- they don't queue up behind each other. So bursting all three
	-- back-to-back means all three return together, one RegenTime later,
	-- rather than trickling back over three times as long.
	--
	-- docs/progression.md plans extra charges as an Endurance skill-tree node,
	-- so nothing below assumes the number is 3. Raise DashMaxCharges and the
	-- service, the HUD and the client prediction all follow automatically.
	DashMaxCharges = 3,
	-- Seconds for one spent charge to come back. Chosen, not from a doc: at 3
	-- charges this gives a sustained ceiling of one dash per second, which
	-- keeps dash meaningful as a commitment rather than a movement option.
	DashChargeRegenTime = 3.0,

	-- Camera feedback
	DefaultFOV = 70, -- Roblox's default Camera.FieldOfView
	SprintFOV = 78, -- widened slightly while sprinting -- sells the speed
	FOVTweenTime = 0.25, -- seconds to ease between the two

	-- How often the server republishes stamina to the client for the HUD.
	-- Every frame would be network spam; 10x/second is plenty for a bar.
	StaminaPushInterval = 0.1,
}
