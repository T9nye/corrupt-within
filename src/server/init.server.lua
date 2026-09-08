-- Entry point for all server code. Rojo maps this whole src/server folder to
-- a Script under ServerScriptService (see default.project.json); because
-- this file is named init.server.lua, Rojo makes IT the script, and
-- everything else in src/server (like Services/) becomes its children.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Requiring a Knit service module is what registers it with Knit -- Knit
-- doesn't scan for services on its own. This loop just means "require every
-- ModuleScript in Services/" so adding a new service later never means
-- editing this file.
for _, child in ipairs(script.Services:GetChildren()) do
	if child:IsA("ModuleScript") then
		require(child)
	end
end

Knit.Start():andThen(function()
	print("[Server] Knit started")
end):catch(function(err)
	warn("[Server] Knit failed to start:", err)
end)
