-- TutorialService: feeds gameplay events from the other services into the pure Tutorial steps
-- (Player Profile `tutorialStep`) and handles the client's Skip. The client shows Tutorial.hint from Sync data.
local RS = game:GetService("ReplicatedStorage")

local Content = require(RS:WaitForChild("Content"))
local Tutorial = require(RS:WaitForChild("Tutorial"))
local PlayerProfile = require(script.Parent:WaitForChild("PlayerProfile"))

local TutorialService = {}

-- remotes: the FishingRemotes folder (adds SkipTutorial, client -> server). syncFn(player) pushes Profile data.
function TutorialService.start(remotes, syncFn)
	local skip = Instance.new("RemoteEvent")
	skip.Name = "SkipTutorial"
	skip.Parent = remotes
	skip.OnServerEvent:Connect(function(player)
		if PlayerProfile.tutorial(player, { kind = "skip" }) then syncFn(player) end
	end)
end

-- kind: "cast" | "landed" | "sold" | "bought" (item = Tackle kind). Callers sync right after, so this does not.
function TutorialService.event(player, kind, item)
	PlayerProfile.tutorial(player, { kind = kind, item = item })
end

-- Species record and kg for the guaranteed first Catch, or nil to roll as usual.
function TutorialService.forcedCatch(player, zone, bait)
	local d = PlayerProfile.get(player)
	if d then return Tutorial.forcedCatch(d, Content, zone, bait) end
	return nil
end

return TutorialService
