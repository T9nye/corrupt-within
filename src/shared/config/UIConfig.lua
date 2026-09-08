-- Colours and timings shared across the loading screen, main menu,
-- customize and settings panels. One palette so all four read as the same
-- piece of UI rather than four separately-styled screens.

return {
	Colors = {
		Background = Color3.fromRGB(10, 9, 13), -- near-black, slightly cool
		Panel = Color3.fromRGB(22, 20, 26),
		PanelBorder = Color3.fromRGB(40, 36, 46),
		TextPrimary = Color3.fromRGB(230, 226, 232),
		TextSecondary = Color3.fromRGB(150, 144, 158),
		-- The warm lantern amber used everywhere in the Haven itself
		-- (docs/haven-build.md: "the only saturated colour... is warm
		-- lantern light"). Reused here for the same reason: it's already
		-- the game's one accent colour.
		Accent = Color3.fromRGB(255, 160, 60),
		AccentDim = Color3.fromRGB(120, 90, 50),
		-- The corruption purple, otherwise kept out of the Haven entirely
		-- and reserved for the black market. The loading screen is the one
		-- other place it's asked to appear, as the "subtle corruption motif".
		Corruption = Color3.fromRGB(128, 84, 190),
		Success = Color3.fromRGB(120, 190, 110),
		Danger = Color3.fromRGB(200, 90, 80),
	},

	Fonts = {
		Title = Enum.Font.GothamBlack,
		Body = Enum.Font.Gotham,
		Bold = Enum.Font.GothamBold,
	},

	-- Loading screen
	TipRotationInterval = 4.5,
	Tips = {
		"Dash gives you three charges. Burst all three, then wait -- each one refills on its own timer.",
		"Corruption climbs when you use corrupted abilities. Low corruption is safest; high corruption hits harder and risks losing control of your character.",
		"The Haven sheds corruption fast. It's the one place in the world that's actually safe.",
		"Not every merchant is in the plaza. One is hidden behind it, for players who go looking.",
		"Sprinting drains stamina. Let go before you're empty, or you'll be caught recovering.",
		"A Rotbound Brute blocks light attacks. Break its guard with a Heavy, or go around it.",
	},

	-- Fade / transition timings
	FadeTime = 0.4,
	PanelSwitchTime = 0.25,
}
