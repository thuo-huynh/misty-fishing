-- Collection panel: every Species in Content order; caught ones in their Rarity colour, the rest as "???".
-- props = { data: Value(Profile data | nil), open: Value(boolean) }
local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Content = require(RS:WaitForChild("Content"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Children = Fusion.Children

local function name(kind, id) return T(`{kind}_{id}`, nil, Content[kind][id].name) end
local GREY = Color3.fromRGB(110, 110, 110)

return function(scope, props)
	local data = props.data
	return W.Panel(scope, {
		Name = "Collection",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.75, 0),
		BackgroundTransparency = 0,
		Visible = props.open,
		[Children] = {
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(420, 520) },
			W.Label(scope, {
				Size = UDim2.new(1, -56, 0, 36),
				Position = UDim2.fromOffset(12, 4),
				Font = Enum.Font.GothamBlack,
				TextSize = 20,
				Text = scope:Computed(function(use)
					local d, caught = use(data), 0
					for _, f in Content.list.species do
						if d and d.collection[f.id] then caught += 1 end
					end
					return T("Coll_Title", { caught = caught, total = #Content.list.species })
				end),
			}),
			W.Button(scope, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.fromOffset(36, 36),
				Text = "X",
				onClick = function() props.open:set(false) end,
			}),
			scope:New "ScrollingFrame" {
				Size = UDim2.new(1, -16, 1, -50),
				Position = UDim2.fromOffset(8, 46),
				BackgroundTransparency = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 6,
				[Children] = {
					scope:New "UIListLayout" { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder },
					scope:Computed(function(use, scope)
						local d = use(data)
						local rows = {}
						for i, f in Content.list.species do
							local entry = d and d.collection[f.id]
							local rarity = Content.rarities[f.rarity]
							local args = {
								name = name("species", f.id), rarity = name("rarities", f.rarity),
								zone = name("zones", f.zones[1]), count = entry and entry.count, kg = entry and string.format("%.2f", entry.bestKg),
							}
							table.insert(rows, W.Label(scope, {
								LayoutOrder = i,
								Size = UDim2.new(1, -8, 0, 22),
								TextSize = 14,
								TextTruncate = Enum.TextTruncate.AtEnd,
								TextColor3 = if entry then Color3.fromRGB(table.unpack(rarity.color)) else GREY,
								Text = T(if not entry then "Coll_Unknown" elseif f.night then "Coll_CaughtNight" else "Coll_Caught", args),
							}))
						end
						return rows
					end),
				},
			},
		},
	})
end
