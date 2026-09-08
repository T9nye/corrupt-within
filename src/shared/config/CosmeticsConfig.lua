-- Cosmetic options available in Customize. Every player owns every entry
-- marked as a starting default -- docs/game-overview.md's monetization is
-- cosmetics sold later; these are just the free baseline so Customize has
-- something to show on a brand-new profile.
--
-- No real armour/clothing assets exist yet, so "outfits" are colour tints
-- on the grey-box body, same as everything else in the project at this
-- stage -- not a placeholder cop-out, just the same grey-box rule
-- docs/haven-build.md applies to buildings applied to the player.

return {
	BodyColors = {
		{ id = "SteelGrey", name = "Steel Grey", color = Color3.fromRGB(120, 124, 132) },
		{ id = "DeepBrown", name = "Deep Brown", color = Color3.fromRGB(92, 64, 44) },
		{ id = "MossGreen", name = "Moss Green", color = Color3.fromRGB(74, 96, 66) },
		{ id = "AshenBlue", name = "Ashen Blue", color = Color3.fromRGB(70, 86, 102) },
		{ id = "BoneWhite", name = "Bone White", color = Color3.fromRGB(198, 190, 172) },
	},

	OutfitPresets = {
		{ id = "Traveler", name = "Traveler", tint = Color3.fromRGB(94, 82, 64) },
		{ id = "Guard", name = "Haven Guard", tint = Color3.fromRGB(70, 70, 76) },
		{ id = "Wanderer", name = "Wanderer", tint = Color3.fromRGB(108, 60, 54) },
	},

	DefaultBodyColor = "SteelGrey",
	DefaultOutfit = "Traveler",
}
