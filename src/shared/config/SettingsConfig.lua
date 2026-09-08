-- Defaults and legal ranges for every player-facing setting. The server
-- clamps every incoming value to these ranges before saving -- a client
-- could send anything, including garbage, and this is what stops garbage
-- from ever reaching a saved profile.

return {
	Defaults = {
		MasterVolume = 0.8,
		MusicVolume = 0.6,
		SFXVolume = 0.8,
		MouseSensitivity = 1, -- multiplier on Roblox's own default sensitivity
		FOV = 70, -- matches MovementConfig.DefaultFOV
		GraphicsQuality = "Quality",
	},

	Ranges = {
		Volume = { Min = 0, Max = 1 },
		MouseSensitivity = { Min = 0.25, Max = 2.5 },
		FOV = { Min = 60, Max = 100 },
	},

	GraphicsQualityOptions = { "Performance", "Quality" },
}
