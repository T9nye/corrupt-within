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
	DashCooldown = 1.5, -- seconds before you can dash again
	DashIFrameDuration = 0.2, -- seconds of invulnerability, starting when the dash begins
	DashCommitDuration = 0.35, -- seconds you're "committed" -- can't dash again, and combat will later refuse attacks too
}
