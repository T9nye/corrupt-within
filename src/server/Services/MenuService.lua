-- Knit service. Owns exactly one thing: when a player's character is
-- allowed to exist. Everything else about "the menu" -- loading, buttons,
-- customize, settings -- is client-side UI with no server opinion. This is
-- the one piece of the menu that HAS to be a server decision, because only
-- the server can create a character.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MenuService = Knit.CreateService {
	Name = "MenuService",
	Client = {},
}

-- Client-callable: fired when the player presses PLAY. Until this is
-- called, the player has no Character at all -- not a frozen one, not a
-- hidden one, none -- which is what makes "no control until they leave the
-- menu" true by construction instead of something we have to keep enforcing.
function MenuService.Client:RequestSpawn(player)
	if not player.Character then
		player:LoadCharacter()
	end
	return true
end

function MenuService:KnitInit()
	-- Must happen before any player finishes joining, so it belongs in
	-- KnitInit (which Knit guarantees finishes, for every service, before
	-- any service's KnitStart runs) rather than KnitStart.
	Players.CharacterAutoLoads = false
end

return MenuService
