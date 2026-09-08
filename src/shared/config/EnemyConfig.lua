-- Enemy tuning. Source of truth: docs/enemies.md.
-- Confirm with Ye before changing any numbers here — see CLAUDE.md.

return {
	-- Not an enemy — the stationary Phase 3 test target in the Haven's
	-- training yard (docs/build-order.md, Phase 3).
	TrainingDummy = {
		DisplayName = "Training Dummy",
		Health = 500, -- high on purpose: it's for testing combos, not for killing
		ResetDelay = 3, -- seconds after being destroyed before it stands back up
		HealthBarOffset = 5, -- studs above the dummy's origin
	},
}
