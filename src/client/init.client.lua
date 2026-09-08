-- Entry point for all client code. Same idea as src/server/init.server.lua:
-- Rojo makes this file the LocalScript under StarterPlayerScripts, and
-- Controllers/ becomes its children.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

for _, child in ipairs(script.Controllers:GetChildren()) do
	if child:IsA("ModuleScript") then
		require(child)
	end
end

Knit.Start():andThen(function()
	print("[Client] Knit started")
end):catch(function(err)
	warn("[Client] Knit failed to start:", err)
end)
