-- Player Profile: loads, session-locks and autosaves each player's data with ProfileStore.
-- All changes go through the named operations below (pure logic in ProfileData).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ProfileStore = require(ServerStorage:WaitForChild("ServerPackages"):WaitForChild("ProfileStore"))
local Content = require(RS:WaitForChild("Content"))
local ProfileData = require(script.Parent:WaitForChild("ProfileData"))

-- New key: the draft's "FishingData_v1" saves are dropped on purpose (no real players yet).
local store = ProfileStore.New("PlayerProfile_v1", ProfileData.new(Content))
local profiles = {} -- [player] = profile

local PlayerProfile = {}

-- Yields. Returns the data, or nil if it could not load (the player is kicked with a message; nothing is overwritten).
function PlayerProfile.load(player)
	local profile = store:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		player:Kick("Could not load your data. Please rejoin.")
		return nil
	end
	profile:AddUserId(player.UserId)
	ProfileData.reconcile(profile.Data, Content)
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data was opened on another server. Please rejoin.")
	end)
	if player.Parent ~= Players then
		profile:EndSession() -- left while loading
		return nil
	end
	profiles[player] = profile
	return profile.Data
end

-- Final save and release of the session lock.
function PlayerProfile.release(player)
	local profile = profiles[player]
	if profile then profile:EndSession() end
end

-- The player's data while their session is active, else nil. Read-only for callers: change it via the operations.
function PlayerProfile.get(player)
	local profile = profiles[player]
	return if profile and profile:IsActive() then profile.Data else nil
end

-- PlayerProfile.<op>(player, ...) = ProfileData.<op>(data, Content, ...); returns nil when the profile is not loaded.
for _, name in { "buy", "equip", "takeBait", "addCatch", "sellBag", "owns", "baitCount" } do
	PlayerProfile[name] = function(player, ...)
		local data = PlayerProfile.get(player)
		if data then return ProfileData[name](data, Content, ...) end
		return nil
	end
end

return PlayerProfile
