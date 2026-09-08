-- ReplicatedFirst is a special container: everything inside it replicates to
-- the client and starts running before almost anything else in the game --
-- before the rest of ReplicatedStorage, before PlayerGui exists, sometimes
-- before the player has even fully joined. That's the only reason this
-- script's one job belongs here instead of in the normal Client script.
--
-- Roblox shows its own generic loading screen automatically the moment a
-- player joins, before any of our code runs. RemoveDefaultLoadingScreen()
-- tells it to stop -- but only takes effect if called before this script
-- yields (waits) for anything, which is why it's the very next line and
-- nothing runs before it.

local ReplicatedFirst = game:GetService("ReplicatedFirst")

ReplicatedFirst:RemoveDefaultLoadingScreen()

-- From here on, the screen is just whatever's already rendered (usually a
-- plain dark backdrop) until MenuController -- a normal Knit controller,
-- started moments later from src/client/init.client.lua once the rest of
-- the game has replicated -- draws the real loading screen. That gap is
-- normally well under a second.
