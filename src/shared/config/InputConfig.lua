-- Every bound key, in one place. MovementController, CombatController and
-- SettingsController all read from here instead of each hardcoding their
-- own Enum.KeyCode -- so the Settings panel's keybind display can never
-- drift out of sync with what's actually wired up, because there's only
-- one copy of the truth to drift from.

return {
	Sprint = Enum.KeyCode.LeftShift,
	Dash = Enum.KeyCode.Q,
	HeavyAttack = Enum.KeyCode.R,

	-- Rows for the Settings panel's read-only keybind list. LightAttack has
	-- no Enum.KeyCode -- it's a mouse button -- so this is a plain label
	-- rather than trying to force it into the same shape as the others.
	Display = {
		{ action = "Sprint", label = "Left Shift" },
		{ action = "Dash", label = "Q" },
		{ action = "Light Attack", label = "Mouse 1" },
		{ action = "Heavy Attack", label = "R" },
	},
}
