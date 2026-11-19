-- Loads content/ (mapped to ReplicatedStorage.ContentData) and indexes every record by Content ID.
-- Content.<kind>[id] -> record; Content.list.<kind> -> records in file order; Content.balance -> constants.
local data = script.Parent:WaitForChild("ContentData")
local balance = require(data:WaitForChild("balance"))

local Content = { balance = balance, list = {} }

local function add(kind, list)
	local byId = {}
	for _, r in list do
		assert(not byId[r.id], `Duplicate {kind} id: {r.id}`)
		byId[r.id] = r
	end
	Content[kind], Content.list[kind] = byId, list
end

for _, kind in { "species", "zones", "rods", "lines", "baits" } do
	add(kind, require(data:WaitForChild(kind)))
end
add("rarities", balance.rarities)

return Content
