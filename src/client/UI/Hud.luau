-- HUD, top-left and compact so the water ahead stays clear: Coins, Bag, time of day,
-- one button per Tackle slot (tap cycles to the next usable one), and the Bag and Collection buttons.
-- props = { data: Value(Profile data | nil), keyboard: boolean, onCycle(kind), onBag(), onCollection() }
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Content = require(RS:WaitForChild("Content"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Children = Fusion.Children

local function name(kind, id) return T(`{kind}_{id}`, nil, Content[kind][id].name) end

return function(scope, props)
	local data = props.data
	local hint = function(key) return if props.keyboard then ` ({key})` else "" end

	local clock = scope:Value("")
	table.insert(scope, RunService.Heartbeat:Connect(function()
		local t = Lighting.ClockTime
		local time = string.format("%02d:%02d", math.floor(t), math.floor(t % 1 * 60))
		clock:set(T(if t < 6 or t >= 18 then "Hud_TimeNight" else "Hud_Time", { time = time }))
	end))

	local function text(fn)
		return scope:Computed(function(use)
			local d = use(data)
			return if d then fn(d) else ""
		end)
	end

	return W.Panel(scope, {
		Name = "Hud",
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(210, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = {
			scope:New "UIListLayout" { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder },
			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8),
			},
			W.Label(scope, { LayoutOrder = 1, Text = text(function(d) return T("Hud_Coins", { coins = d.coins }) end) }),
			W.Button(scope, { LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(60, 120, 90), Text = text(function(d)
				return T("Hud_Bag", { count = #d.bag, size = Content.balance.bagSize }) .. hint("V")
			end), onClick = props.onBag }),
			W.Label(scope, { LayoutOrder = 3, Text = clock }),
			W.Button(scope, { LayoutOrder = 4, Text = text(function(d) return T("Hud_Rod", { name = name("rods", d.equipped.rod) }) end),
				onClick = function() props.onCycle("rods") end }),
			W.Button(scope, { LayoutOrder = 5, Text = text(function(d) return T("Hud_Line", { name = name("lines", d.equipped.line) }) end),
				onClick = function() props.onCycle("lines") end }),
			W.Button(scope, { LayoutOrder = 6, Text = text(function(d)
				local id = d.equipped.bait
				local args = { name = name("baits", id), count = d.baits[id] or 0 }
				return T(if Content.baits[id].price > 0 then "Hud_BaitCount" else "Hud_Bait", args) .. hint("B")
			end), onClick = function() props.onCycle("baits") end }),
			W.Button(scope, { LayoutOrder = 7, Text = T("Hud_Collection") .. hint("C"),
				BackgroundColor3 = Color3.fromRGB(200, 150, 40), onClick = props.onCollection }),
		},
	})
end
